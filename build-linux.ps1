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
            
            # Fix $ to $$ for PowerShell (but keep as $ for ninja)
            # Actually, we need to write the file in a way that keeps $ as literal
            # The issue is PowerShell is processing $ in the file when reading
            
            # Remove SDL2_fake
            $content = $content -replace '-lSDL2_fake', ''
            
            # Remove -Werror
            $content = $content -replace '-Werror', ''
            
            # Increase INITIAL_MEMORY
            $content = $content -replace '-s INITIAL_MEMORY=\d+MB', '-s INITIAL_MEMORY=512MB'
            
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
