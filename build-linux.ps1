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
$emccCmd = Get-Command emcc -ErrorAction SilentlyContinue
if ($emccCmd) {
    Write-Host "[+] Emscripten found in PATH" -ForegroundColor Green
    $emccPath = $emccCmd.Source
    $emscriptenBin = Split-Path $emccPath
    if ($env:EMSDK) {
        $emsdkBin = $env:EMSDK
    } else {
        $emsdkBin = Split-Path (Split-Path $emscriptenBin)
    }
} elseif (Test-Path "emsdk/upstream/emscripten/emcc") {
    $emscriptenBin = "$PWD/emsdk/upstream/emscripten"
    $emsdkBin = "$PWD/emsdk"
    $env:PATH = "${emscriptenBin}:${emsdkBin}:${env:PATH}"
} else {
    Write-Host "[-] Emscripten not found. Run setup.ps1 first or ensure emcc is in PATH." -ForegroundColor Red
    exit 1
}

$env:EMSCRIPTEN = $emscriptenBin
$env:EMSDK = $emsdkBin
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

# ============================================================================
# INPUT COLLECTION
# ============================================================================

Write-Host "`n[*] Collecting build parameters..." -ForegroundColor Yellow

# TARGET
if (-not $Target -and $PSBoundParameters.ContainsKey('Target') -eq $false) {
    Write-Host "`n[TARGET] Available options:" -ForegroundColor Cyan
    Write-Host "  mame       - Standard MAME (default, recommended)" -ForegroundColor Gray
    Write-Host "  mess       - Retro computers & consoles" -ForegroundColor Gray
    $Target = Read-Host "`nChoose TARGET (default: mame)"
    if (-not $Target) { $Target = "mame" }
}
Write-Host "  Selected: $Target" -ForegroundColor Green

# SUBTARGET
if (-not $Subtarget -and $PSBoundParameters.ContainsKey('Subtarget') -eq $false) {
    Write-Host "`n[SUBTARGET] Available options:" -ForegroundColor Cyan
    Write-Host "  tiny       - Minimal build (RECOMMENDED) ~30-50MB" -ForegroundColor Yellow
    Write-Host "  ample      - AmpleWeb optimized build (Best for Apple/Mac/8-bit) ~45MB" -ForegroundColor Cyan
    if ($Target -eq "mame") {
        Write-Host "  mame       - Full MAME (all arcade) ~80-100MB" -ForegroundColor Gray
        Write-Host "  arcade     - Arcade games only ~70-90MB" -ForegroundColor Gray
    } elseif ($Target -eq "mess") {
        Write-Host "  mess       - Full MESS (all computers/consoles) ~60-80MB" -ForegroundColor Gray
    }
    Write-Host "  pacmantest - Pac-Man test build ~4MB (FASTEST)" -ForegroundColor Yellow
    $Subtarget = Read-Host "`nChoose SUBTARGET (default: tiny)"
    if (-not $Subtarget) { $Subtarget = "tiny" }
}
Write-Host "  Selected: $Subtarget" -ForegroundColor Green

# SOURCES
if ($Sources -eq "" -and $PSBoundParameters.ContainsKey('Sources') -eq $false -and $PSBoundParameters.ContainsKey('Subtarget') -eq $false) {
    Write-Host "`n[SOURCES] Available options:" -ForegroundColor Cyan
    Write-Host "  (leave empty)              - All drivers in SUBTARGET" -ForegroundColor Gray
    Write-Host "  pacman                     - Pac-Man" -ForegroundColor Gray
    Write-Host "  robby                      - Robby Roto" -ForegroundColor Gray
    Write-Host "  src/mame/umc/supracan.cpp  - Super A'Can" -ForegroundColor Gray
    $Sources = Read-Host "`nChoose SOURCES (press Enter for all)"
}

if ($Sources) {
    if ($Sources -eq "pacman") {
        $Sources = "src/mame/pacman/pacman.cpp"
    } elseif ($Sources -eq "robby") {
        $Sources = "src/mame/midway/astrocde.cpp"
    }
    Write-Host "  Selected: $Sources" -ForegroundColor Green
} else {
    Write-Host "  Selected: (all drivers)" -ForegroundColor Green
}

# Exception handling / Debug Mode
if ($NoDebug) {
    $Debug = "n"
}

if ($Debug -eq "Y" -and $PSBoundParameters.ContainsKey('Debug') -eq $false -and $PSBoundParameters.ContainsKey('Subtarget') -eq $false) {
    Write-Host "`n[OPTIMIZATION] Choose mode:" -ForegroundColor Cyan
    Write-Host "  1. Debug/Development (Exceptions Enabled, -O3)" -ForegroundColor Gray
    Write-Host "  2. Production (Exceptions Disabled, -Oz, LTO, Smallest file)" -ForegroundColor Yellow
    $mode = Read-Host "`nChoose mode (1 or 2, default: 1)"
    if ($mode -eq "2") {
        $Debug = "n"
        $Production = $true
    } else {
        $Debug = "Y"
        $Production = $false
    }
}

if ($Debug -like "n*") {
    $DisableExceptions = "1"
    $MameDebug = "0"
    Write-Host "  Selected: Exceptions Disabled (faster)" -ForegroundColor Green
} else {
    $DisableExceptions = "0"
    $MameDebug = "0"
    Write-Host "  Selected: Exceptions Enabled (stack traces visible)" -ForegroundColor Green
}

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

    # Patch scripts/genie.lua for SDL2 compatibility on MAME 0.289+
    $genieLuaPath = Join-Path $PWD "scripts/genie.lua"
    if (Test-Path $genieLuaPath) {
        $genieContent = Get-Content $genieLuaPath -Raw
        $genieContent = $genieContent.Replace('"-s USE_SDL_TTF=3"', '"-s USE_SDL=2",`n`t`t"-s USE_SDL_TTF=2"')
        $genieContent = $genieContent.Replace('"-s USE_SDL=3"', '"-s USE_SDL=2"')
        Set-Content -Path $genieLuaPath -Value $genieContent -NoNewline
        Write-Host "   [*] Patched scripts/genie.lua for SDL2 compatibility." -ForegroundColor Green
    }

    # Patch msxdos2.cpp for PAGE_SIZE macro collision on Emscripten/Linux
    $msxdos2Path = Join-Path $PWD "src/devices/bus/msx/cart/msxdos2.cpp"
    if (Test-Path $msxdos2Path) {
        $msxContent = Get-Content $msxdos2Path -Raw
        if ($msxContent -notmatch "#undef PAGE_SIZE") {
            $msxContent = $msxContent.Replace('#include "bus/generic/slot.h"', "#include `"bus/generic/slot.h`"`n#ifdef PAGE_SIZE`n#undef PAGE_SIZE`n#endif")
            Set-Content -Path $msxdos2Path -Value $msxContent -NoNewline
            Write-Host "   [*] Patched msxdos2.cpp for PAGE_SIZE macro collision." -ForegroundColor Green
        }
    }

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
            
            # CRITICAL: Fix @echo commands in Linux shell
            $content = $content.Replace('@echo ', 'echo ')
            
            # Patch rule ar (Linux style - no cmd /c)
            $arPattern = 'rule ar\s+command\s+= (.+?)emar \$flags \$out \$in \$libs'
            $arReplacement = "rule ar`n  command         = `$1emar `$flags `$out @`$out.rsp`n  description     = ar `$out`n  rspfile         = `$out.rsp`n  rspfile_content = `$in `$libs"
            if ($content -match $arPattern) {
                $content = $content -replace $arPattern, $arReplacement
            }
            
            # Patch rule cxx (Linux style - no cmd /c)
            $cxxPattern = 'rule cxx\s+command\s+= (.+?)em\+\+ \$defines \$includes \$flags -MD -MT \$out -MF \$out.d -c \$in -o \$out'
            $cxxOpt = ""
            if ($Production) {
                $cxxOpt = "-msimd128 -fno-rtti -fno-stack-protector -fno-asynchronous-unwind-tables -fomit-frame-pointer -finline-functions"
            }
            $cxxReplacement = "rule cxx`n  command         = `$1em++ `$defines `$includes `$flags $cxxOpt -MD -MT `$out -MF `$out.d -c `$in -o `$out"
            if ($content -match $cxxPattern) {
                $content = $content -replace $cxxPattern, $cxxReplacement
            }
            
            # Patch link rule (Linux style - no cmd /c)
            $linkPattern = 'rule link\s+command\s+= (.+?)em\+\+ -o \$out \$all_outputfiles \$walibs\s+\$libs\s+\$all_ldflags \$post_build'
            
            # Aggressive Optimization
            $optFlags = "-O3"
            if ($Production) {
                $optFlags = "-Oz -flto"
            } elseif ($Subtarget -eq "ample") {
                $optFlags += " -flto"
            }
            
            $memFlags = "-s ALLOW_MEMORY_GROWTH=1 -s INITIAL_MEMORY=1073741824 -s MAXIMUM_MEMORY=4294967296"
            $exceptionFlags = if ($Production) { "-s DISABLE_EXCEPTION_CATCHING=1" } else { "-s DISABLE_EXCEPTION_CATCHING=0" }

            $linkReplacement = "rule link`n  command         = `$1em++ $optFlags $memFlags $exceptionFlags -o `$out @`$out.rsp `$all_ldflags `$post_build`n  description     = link `$out`n  rspfile         = `$out.rsp`n  rspfile_content = `$all_outputfiles `$walibs `$libs"
            
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
            
            # CRITICAL: Fix duplicate rules between dasm.ninja and optional.ninja
            # optional.ninja duplicates some rules that also exist in dasm.ninja:
            # - tms57002.hxx (generated header)
            # - vaxdasm.o (VAX disassembler)
            # - xtensa_helper.o (Xtensa CPU helper)
            # We remove these from optional.ninja, keeping dasm.ninja's versions
            if ($file.Name -eq 'optional.ninja') {
                $lines = $content -split "`n"
                $newLines = @()
                $skipBlock = $false
                $duplicatePatterns = @(
                    'tms57002\.hxx:',
                    'vaxdasm\.o:',
                    'xtensa_helper\.o:'
                )
                foreach ($line in $lines) {
                    $isDuplicate = $false
                    foreach ($pattern in $duplicatePatterns) {
                        if ($line -match "^build .+$pattern") {
                            $isDuplicate = $true
                            break
                        }
                    }
                    if ($isDuplicate) {
                        $skipBlock = $true
                        continue
                    } elseif ($skipBlock) {
                        if ($line -match '^build ' -or $line -match '^# FILE:') {
                            $skipBlock = $false
                            $newLines += $line
                        }
                        continue
                    } else {
                        $newLines += $line
                    }
                }
                $content = ($newLines -join "`n").TrimEnd() + "`n"
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
    
    # CRITICAL: Pre-warm emscripten cache to prevent parallel build race conditions
    $emccPath = "$emscriptenBin/emcc"
    if (Test-Path $emccPath) {
        Write-Host "[*] Pre-warming emscripten cache (this may take 2-3 minutes)..." -ForegroundColor Yellow
        $tempFile = [System.IO.Path]::GetTempFileName() + ".cpp"
        @"
#include <list>
#include <algorithm>
#include <string>
#include <vector>
int main() { return 0; }
"@ | Set-Content $tempFile
        & $emccPath $tempFile -o "$tempFile.js" -std=c++20 -s USE_SDL=2 -s USE_SDL_TTF=2 -s USE_FREETYPE=2 -s EXCEPTION_CATCHING_ALLOWED="['test']" 2>&1 | Out-Null
        Remove-Item $tempFile, "$tempFile.js", "$tempFile.wasm" -ErrorAction SilentlyContinue
        
        $tempFile2 = [System.IO.Path]::GetTempFileName() + ".cpp"
        "int main() { return 0; }" | Set-Content $tempFile2
        & $emccPath $tempFile2 -o "$tempFile2.js" -std=c++20 2>&1 | Out-Null
        Remove-Item $tempFile2, "$tempFile2.js", "$tempFile2.wasm" -ErrorAction SilentlyContinue
        
        # Lock emscripten cache
        $cacheDir = "$emscriptenBin/cache"
        if (Test-Path $cacheDir) {
            Write-Host "[*] Locking emscripten cache (read-only)..." -ForegroundColor Yellow
            Get-ChildItem $cacheDir -Recurse -File | ForEach-Object { $_.IsReadOnly = $true }
            Write-Host "[+] Emscripten cache locked." -ForegroundColor Green
        }
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
