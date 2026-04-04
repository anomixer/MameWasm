#!/usr/bin/env pwsh
# MAME WASM Build Factory - Build Script (Linux Version)
# Modified for Linux compatibility

param(
    [string]$Target = "mame",
    [string]$Subtarget = "",
    [string]$Sources = "",
    [string]$Debug = "Y",
    [switch]$NoDebug = $false,
    [switch]$UseMake = $false,
    [switch]$Help = $false
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if ($Help) {
    Write-Host @"
MAME WASM Build Factory - Build Script (Linux)

Usage:
    pwsh -File ./build.ps1 -Subtarget pacmantest

"@
    exit 0
}

Write-Host "`n[*] MAME WASM Build Factory (Linux)" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

Write-Host "`n[*] Setting up environment..." -ForegroundColor Yellow

# Check Emscripten
if (!(Test-Path "emsdk/upstream/emscripten/emcc")) {
    Write-Host "[-] Emscripten not found. Run setup.ps1 first." -ForegroundColor Red
    exit 1
}

# Manually set up environment for Linux
$emscriptenBin = "$PWD/emsdk/upstream/emscripten"
$emsdkBin = "$PWD/emsdk"
$env:PATH = "${emscriptenBin}:${emsdkBin}:${env:PATH}"
$env:EMSCRIPTEN = $emscriptenBin
$env:EMSDK = $PWD
$env:EMSCRIPTEN_ROOT = $emscriptenBin

# Verify emcc works
$emccTest = & "$emscriptenBin/emcc" --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[-] Emscripten test failed." -ForegroundColor Red
    exit 1
}
Write-Host "[+] Emscripten: $($emccTest[0])" -ForegroundColor Green

$env:TOOLCHAIN = ""
Write-Host "[+] Environment ready" -ForegroundColor Green

# Default values
if (!$Subtarget) { $Subtarget = "pacmantest" }
Write-Host "  Subtarget: $Subtarget" -ForegroundColor Green

if ($NoDebug) {
    $Debug = "n"
    $DisableExceptions = "1"
    $MameDebug = "0"
} else {
    $DisableExceptions = "0"
    $MameDebug = "0"
}
Write-Host "  Exceptions: $(if($DisableExceptions -eq '1'){'Disabled'}else{'Enabled'})" -ForegroundColor Green

# Determine CPU cores
$cores = (Get-Content /proc/cpuinfo | Measure-Object -Property processor -Maximum).Maximum
if ($cores -gt 1) { $cores-- }
if ($cores -lt 1) { $cores = 1 }
Write-Host "  CPU cores: $cores" -ForegroundColor Green

Write-Host "`n[*] Step 1: Generating layouts..." -ForegroundColor Yellow

$initialDir = $PWD
Push-Location "mame"

try {
    $preBuildCmd = "make generate TARGET=$Target SUBTARGET=$Subtarget IGNORE_GIT=1 DEBUG=$MameDebug"
    Write-Host "[*] Command: $preBuildCmd" -ForegroundColor DarkGray
    Invoke-Expression $preBuildCmd

    if ($LASTEXITCODE -ne 0) {
        Write-Host "[-] Pre-build generation failed." -ForegroundColor Red
        exit 1
    }

    Write-Host "`n[*] Step 2: Generating Ninja project files..." -ForegroundColor Yellow
    
    # Use Linux genie
    $genieExe = "$PWD/3rdparty/genie/bin/linux/genie"
    if (!(Test-Path $genieExe)) {
        Write-Host "[-] Genie not found at $genieExe." -ForegroundColor Red
        exit 1
    }

    $genieArgs = @(
        "--file=scripts/genie.lua",
        "--build-dir=build",
        "--osd=sdl",
        "--targetos=asmjs",
        "--gcc=asmjs",
        "--gcc_version=22.0.0",
        "--target=$Target",
        "--subtarget=$Subtarget",
        "--PLATFORM=x64",
        "--with-emulator",
        "ninja"
    )

    if ($Sources -and $Subtarget -notin @("pacmantest", "pacem")) {
        $genieArgs += "--SOURCES=$Sources"
    }

    Write-Host "[*] Running genie..." -ForegroundColor DarkGray
    & $genieExe $genieArgs

    if ($LASTEXITCODE -ne 0) {
        Write-Host "[-] Genie project generation failed." -ForegroundColor Red
        exit 1
    }

    Write-Host "`n[*] Step 3: Patching Ninja files..." -ForegroundColor Yellow
    
    $solName = if ($Target -eq $Subtarget) { $Target } else { "$Target$Subtarget" }
    $ninjaPath = "build/projects/sdl/$solName/ninja-asmjs/release"
    
    if (Test-Path $ninjaPath) {
        $files = Get-ChildItem -Path $ninjaPath -Filter "*.ninja"
        foreach ($file in $files) {
            $content = [System.IO.File]::ReadAllText($file.FullName)
            
            # CRITICAL: Replace $(EMSCRIPTEN) with absolute path for Linux bash
            $content = $content.Replace('$(EMSCRIPTEN)', $emscriptenBin)
            
            # CRITICAL: Escape $(2) as $$(2) for ninja (used by mcs96make.py commands)
            $content = $content.Replace('$(2)', '$$(2)')
            
            # CRITICAL: Patch link rule to add DISABLE_EXCEPTION_CATCHING=0
            $linkPattern = 'rule link\s+command\s+= cmd /c "(.+?)em\+\+ -o \$out \$all_outputfiles \$walibs  \$libs  \$all_ldflags \$post_build"'
            $linkReplacement = "rule link`n  command         = cmd /c `"`$1em++ -O3 -s ALLOW_MEMORY_GROWTH=1 -s INITIAL_MEMORY=536870912 -s DISABLE_EXCEPTION_CATCHING=0 -o `$out @`$out.rsp `$all_ldflags `$post_build`"`n  description     = link `$out`n  rspfile         = `$out.rsp`n  rspfile_content = `$all_outputfiles `$walibs `$libs"
            
            if ($content -match $linkPattern) {
                $content = $content -replace $linkPattern, $linkReplacement
            }
            
            # Remove SDL2_fake
            $content = $content -replace '-lSDL2_fake', ''
            
            # Remove -Werror
            $content = $content -replace '-Werror', ''
            
            # Increase INITIAL_MEMORY
            $content = $content -replace '-s INITIAL_MEMORY=\d+MB', '-s INITIAL_MEMORY=512MB'
            
            # CRITICAL: Fix duplicate empty.o rule in precompile.ninja
            if ($file.Name -eq 'precompile.ninja') {
                $lines = $content -split "`n"
                $ruleLines = @()
                foreach ($line in $lines) {
                    if ($line -match '^# custom build rules' -or $line -match '^# build files' -or $line -match '^# FILE:' -or $line -match '^build ' -or $line -match '^  flags' -or $line -match '^  includes' -or $line -match '^  defines' -or $line -match '^  all_outputfiles') {
                        continue
                    }
                    $ruleLines += $line
                }
                $content = ($ruleLines -join "`n").TrimEnd() + "`n"
            }
            
            # CRITICAL: Fix ERRNO_CODES escaping that causes JS syntax errors
            $content = $content -replace 'DEFAULT_LIBRARY_FUNCS_TO_INCLUDE="?\[''[^'']*ERRNO_CODES[^'']*''\]"?', 'DEFAULT_LIBRARY_FUNCS_TO_INCLUDE=[''$$ERRNO_CODES'']'
            
            # CRITICAL: Add SDLMAME_EMSCRIPTEN define to osd_sdl.ninja and ocore_sdl.ninja
            if ($file.Name -eq 'osd_sdl.ninja' -or $file.Name -eq 'ocore_sdl.ninja') {
                $content = $content -replace '(-DNDEBUG -DCRLF=2 -DLSB_FIRST)', '$1 -DSDLMAME_EMSCRIPTEN'
            }
            
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBom)
        }
        Write-Host "   [+] Patched $($files.Count) ninja files" -ForegroundColor Green
    }

    Write-Host "`n[*] Step 4: Building with Ninja..." -ForegroundColor Yellow
    
    # Use bash to run ninja, not PowerShell, to avoid $ interpretation issues
    $ninjaCmd = "bash -c 'emmake ninja -j $cores -C `"$ninjaPath`"'"
    Write-Host "[*] Command: $ninjaCmd" -ForegroundColor DarkGray
    Invoke-Expression $ninjaCmd
    $buildStatus = $LASTEXITCODE

} finally {
    Set-Location $initialDir
}

if ($buildStatus -eq 0) {
    Write-Host "`n[+] Build successful!" -ForegroundColor Green
    
    $possibleNames = @("$Target$Subtarget", "${Target}_${Subtarget}", $Subtarget)
    if ($Sources) { $possibleNames += $Subtarget }

    $found = $false
    foreach ($name in $possibleNames) {
        $jsSearchPaths = @(
            "$PWD/mame/$name.js",
            "$PWD/mame/build/asmjs/bin/$name.js"
        )
        foreach ($path in $jsSearchPaths) {
            if (Test-Path $path) {
                $jsPath = $path
                $wasmPath = $path -replace "\.js$", ".wasm"
                $found = $true
                break
            }
        }
        if ($found) { break }
    }
    
    if ($found) {
        $jsSize = (Get-Item $jsPath).Length / 1MB
        $wasmSize = if (Test-Path $wasmPath) { (Get-Item $wasmPath).Length / 1MB } else { 0 }
        Write-Host "[+] Output JS:   $jsPath ($([math]::Round($jsSize, 2)) MB)" -ForegroundColor Green
        Write-Host "[+] Output WASM: $wasmPath ($([math]::Round($wasmSize, 2)) MB)" -ForegroundColor Green
        
        Write-Host "`n[*] Copying to project root..." -ForegroundColor Yellow
        Copy-Item $jsPath "$PSScriptRoot/$($name).js" -Force
        if (Test-Path $wasmPath) {
            Copy-Item $wasmPath "$PSScriptRoot/$($name).wasm" -Force
        }
        Write-Host "   [+] Done!" -ForegroundColor Green
    }
} else {
    Write-Host "`n[-] Build failed." -ForegroundColor Red
    exit 1
}
