# MAME WASM Build Factory - Build Script
# Interactive script to compile MAME to WebAssembly

param(
    [string]$Target = "mame",
    [string]$Subtarget = "",
    [string]$Sources = "",
    [string]$Optimization = "Debug",
    [switch]$NoDebug = $false,
    [switch]$UseMake = $false,
    [switch]$Help = $false
)

# Set encoding to UTF-8 to handle special characters correctly
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if ($Help) {
    Write-Host @"
MAME WASM Build Factory - Build Script

Usage:
    ./build.ps1                                    # Interactive mode
    ./build.ps1 -Subtarget tiny                    # Specify subtarget
    ./build.ps1 -Subtarget tiny -Sources pacman    # Specify sources

Common Subtargets:
    tiny         - Minimal build (RECOMMENDED) ~30-50MB
    ample        - AmpleWeb optimized build (Best for Apple/Mac/8-bit) ~45MB
    mame         - Full MAME (all arcade)    ~80-100MB
    mess         - Computers & consoles      ~60-80MB
    arcade       - Arcade games only         ~70-90MB
    pacmantest   - Pac-Man test build        ~4MB (fastest!)

Common Sources:
    pacman       - Pac-Man
    robby        - Robby Roto (ROM included for testing!)
    src/mame/pacman/pacman.cpp                     - Pac-Man (full path)
    src/mame/midway/astrocde.cpp                   - Robby Roto (full path)
    src/mame/midw8080/mw8080bw.cpp                 - Space Invaders (full path)

Examples:
    ./build.ps1 -Subtarget tiny
    ./build.ps1 -Subtarget tiny -Sources pacman
    ./build.ps1 -Subtarget pacmantest
    ./build.ps1 -Subtarget mame

"@
    exit 0
}

Write-Host "`n[*] MAME WASM Build Factory" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan

# ============================================================================
# SETUP
# ============================================================================

Write-Host "`n[*] Setting up environment..." -ForegroundColor Yellow

# Check Emscripten
if (!(Test-Path "emsdk/emsdk_env.ps1")) {
    Write-Host "[-] Emscripten not found. Run setup.ps1 first." -ForegroundColor Red
    exit 1
}

# Activate Emscripten
try {
    . ./emsdk/emsdk_env.ps1
} catch {
    Write-Host "[-] Error loading Emscripten environment script: $_" -ForegroundColor Yellow
}

# Verify emcc is in path
if (!(Get-Command emcc -ErrorAction SilentlyContinue)) {
    Write-Host "[-] Emscripten activation failed. 'emcc' not found in PATH." -ForegroundColor Red
    Write-Host "    HINT: You may need to run this script with Execution Policy Bypass:" -ForegroundColor Yellow
    Write-Host "    PowerShell -ExecutionPolicy Bypass -File ./build.ps1" -ForegroundColor Cyan
    exit 1
}

# Add Emscripten upstream bin to PATH BEFORE local bin
$emscriptenBin = "$PWD/emsdk/upstream/bin"
if (Test-Path $emscriptenBin) {
    $env:PATH = "$emscriptenBin;$env:PATH"
}

# Add local bin directory
$env:PATH = "$PWD/bin;$env:PATH"

# Add Git Unix tools to PATH (Dynamically find Git)
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if ($gitCmd) {
    $gitRoot = (Get-Item $gitCmd.Source).Directory.Parent.FullName
    $gitUsrBin = Join-Path $gitRoot "usr\bin"
    
    if (Test-Path $gitUsrBin) {
        $env:PATH = "$gitUsrBin;$env:PATH"
        Write-Host "[+] Git Unix tools added to PATH (Detected: $gitUsrBin)" -ForegroundColor Green
    }
}

# CRITICAL: Set TOOLCHAIN to empty to prevent MAME from auto-detecting GCC
$env:TOOLCHAIN = ""
$env:EMSCRIPTEN = "$PWD/emsdk/upstream/emscripten"

Write-Host "[+] Environment ready" -ForegroundColor Green

# ============================================================================
# INPUT COLLECTION
# ============================================================================

Write-Host "`n[*] Collecting build parameters..." -ForegroundColor Yellow

# TARGET
if (-not $Target) {
    Write-Host "`n[TARGET] Available options:" -ForegroundColor Cyan
    Write-Host "  mame       - Standard MAME (default, recommended)" -ForegroundColor Gray
    Write-Host "  mess       - Retro computers & consoles" -ForegroundColor Gray
    Write-Host "  ldplayer   - LDPLAYER (rare)" -ForegroundColor Gray
    $Target = Read-Host "`nChoose TARGET (default: mame)"
    if (-not $Target) { $Target = "mame" }
}
Write-Host "  Selected: $Target" -ForegroundColor Green

# SUBTARGET
if (-not $Subtarget) {
    Write-Host "`n[SUBTARGET] Available options:" -ForegroundColor Cyan
    Write-Host "  tiny       - Minimal build (RECOMMENDED) ~30-50MB, 10-20 min" -ForegroundColor Yellow
    Write-Host "  ample      - AmpleWeb optimized build (Best for Apple/Mac/8-bit) ~45MB" -ForegroundColor Cyan
    if ($Target -eq "mame") {
        Write-Host "  mame       - Full MAME (all arcade) ~80-100MB, 1-2 hours" -ForegroundColor Gray
        Write-Host "  arcade     - Arcade games only ~70-90MB, 45-60 min" -ForegroundColor Gray
    } elseif ($Target -eq "mess") {
        Write-Host "  mess       - Full MESS (all computers/consoles) ~60-80MB, 45-60 min" -ForegroundColor Gray
    }
    Write-Host "  pacmantest - Pac-Man test build ~4MB, 2-5 min (FASTEST)" -ForegroundColor Yellow
    $Subtarget = Read-Host "`nChoose SUBTARGET (default: tiny)"
    if (-not $Subtarget) { $Subtarget = "tiny" }
}
Write-Host "  Selected: $Subtarget" -ForegroundColor Green

# SOURCES
if ($Sources -eq "" -and $PSBoundParameters.ContainsKey('Sources') -eq $false -and $PSBoundParameters.ContainsKey('Subtarget') -eq $false) {
    Write-Host "`n[SOURCES] Available options:" -ForegroundColor Cyan
    Write-Host "  (leave empty)              - All drivers in SUBTARGET" -ForegroundColor Gray
    Write-Host "  pacman                     - Pac-Man (auto-convert to full path)" -ForegroundColor Gray
    Write-Host "  robby                      - Robby Roto (ROM included!)" -ForegroundColor Gray
    Write-Host "  src/mame/pacman/pacman.cpp - Pac-Man (full path)" -ForegroundColor Gray
    Write-Host "  file1.cpp,file2.cpp        - Multiple drivers (comma-separated)" -ForegroundColor Gray
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

# Optimization Mode
if ($Optimization -eq "Production" -or $NoDebug) {
    $DebugMode = "n"
    $Production = $true
} elseif ($Optimization -eq "Debug") {
    # If Subtarget is specified, default to Production for speed, unless interactive
    if ($PSBoundParameters.ContainsKey('Subtarget')) {
        $DebugMode = "n"
        $Production = $true
    } else {
        Write-Host "`n[OPTIMIZATION] Choose mode:" -ForegroundColor Cyan
        Write-Host "  1. Debug/Development (Exceptions Enabled, -O3)" -ForegroundColor Gray
        Write-Host "  2. Production (Exceptions Disabled, -O3, LTO, SIMD, FASTEST!)" -ForegroundColor Yellow
        $mode = Read-Host "`nChoose mode (1 or 2, default: 2)"
        if ($mode -eq "1") {
            $DebugMode = "Y"
            $Production = $false
        } else {
            $DebugMode = "n"
            $Production = $true
        }
    }
}

if ($DebugMode -eq "n") {
    $DisableExceptions = "1"
    $MameDebug = "0"
    Write-Host "  Selected: Production / High Speed (Exceptions Disabled, LTO, SIMD)" -ForegroundColor Green
} else {
    $DisableExceptions = "0"
    $MameDebug = "0" 
    Write-Host "  Selected: Debug / Compatibility (Exceptions Enabled)" -ForegroundColor Yellow
}

# ============================================================================
# BUILD CONFIGURATION
# ============================================================================

Write-Host "`n[*] Preparing build..." -ForegroundColor Yellow

# Determine CPU cores for -j flag
$cores = 1
if ($env:NUMBER_OF_PROCESSORS) {
    $cores = [int]$env:NUMBER_OF_PROCESSORS
    if ($cores -gt 1) { $cores-- }
}

# Check for Ninja
$useNinja = $false
if ((Get-Command ninja -ErrorAction SilentlyContinue) -and -not $UseMake) {
    $useNinja = $true
    Write-Host "[*] Ninja build system detected. Using Ninja to bypass Windows limits." -ForegroundColor Cyan
} elseif ($UseMake) {
    Write-Host "[*] Forced Make build system (skipping Ninja)." -ForegroundColor Yellow
}

Write-Host "[*] Step 1: Running pre-build generation (layouts, version)..." -ForegroundColor Yellow

# Inject custom targets
if (Test-Path "$PSScriptRoot/custom_targets") {
    $targetDir = "$PSScriptRoot/mame/scripts/target/mame"
    if (Test-Path $targetDir) {
        Write-Host "   [*] Injecting custom target scripts..." -ForegroundColor Cyan
        Copy-Item "$PSScriptRoot/custom_targets/*.lua" -Destination $targetDir -Force
    }
    # Also copy .lst files to filter drivlist.cpp
    $lstDir = "$PSScriptRoot/mame/src/mame"
    if (Test-Path $lstDir) {
        Copy-Item "$PSScriptRoot/custom_targets/*.lst" -Destination $lstDir -Force -ErrorAction SilentlyContinue
    }
}

$initialDir = $PSScriptRoot
Push-Location "mame"

try {
    # Generate layouts and version files
    $preBuildCmd = "make generate TARGET=$Target SUBTARGET=$Subtarget IGNORE_GIT=1 DEBUG=$MameDebug"
    Write-Host "[*] Command: $preBuildCmd" -ForegroundColor DarkGray
    Invoke-Expression $preBuildCmd

    if ($LASTEXITCODE -ne 0) {
        Write-Host "[-] Pre-build generation failed." -ForegroundColor Red
        exit 1
    }

    # Step 2: Generate Project Files
    if ($useNinja) {
        Write-Host "[*] Step 2: Generating Ninja project files (Direct Genie invocation)..." -ForegroundColor Yellow
        
        # Patch scripts/genie.lua for SDL2 compatibility on MAME 0.289+
        $genieLuaPath = Join-Path $PWD "scripts/genie.lua"
        if (Test-Path $genieLuaPath) {
            $genieContent = Get-Content $genieLuaPath -Raw
            $genieContent = $genieContent.Replace("-s USE_SDL_TTF=3", "-s USE_SDL=2`n`t`t-s USE_SDL_TTF=2")
            $genieContent = $genieContent.Replace("-s USE_SDL=3", "-s USE_SDL=2")
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

        $genieExe = "$PWD/3rdparty/genie/bin/windows/genie.exe"
        if (-not (Test-Path $genieExe)) {
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
        
        # Only apply --SOURCES if NOT using our custom test targets
        if ($Sources -and $Subtarget -notin @("pacmantest", "pacem")) {
            $genieArgs += "--SOURCES=$Sources"
            Write-Host "[+] Applying specific SOURCES='$Sources' to project generation." -ForegroundColor Green
        }

        $proc = Start-Process -FilePath $genieExe -ArgumentList $genieArgs -NoNewWindow -PassThru -Wait
        if ($proc.ExitCode -ne 0) {
            Write-Host "[-] Genie project generation failed." -ForegroundColor Red
            exit 1
        }

        # Step 3: Post-process Ninja files to fix long command lines on Windows
        Write-Host "[*] Step 3: Patching Ninja files for Windows command length limits..." -ForegroundColor Yellow
        $solName = if ($Target -eq $Subtarget) { $Target } else { "$Target$Subtarget" }
        $ninjaPath = "build/projects/sdl/$solName/ninja-asmjs/release"
        
        if (Test-Path $ninjaPath) {
            $files = Get-ChildItem -Path $ninjaPath -Filter "*.ninja"
            foreach ($file in $files) {
                # Read content
                $content = [System.IO.File]::ReadAllText($file.FullName)
                
                # Patch rule ar
                # We use -replace with a regex that captures the tool path
                $arPattern = 'rule ar\s+command\s+= cmd /c "(.+?)emar \$flags \$out \$in \$libs"'
                $arReplacement = "rule ar`n  command         = cmd /c `"`$1emar `$flags `$out @`$out.rsp`"`n  description     = ar `$out`n  rspfile         = `$out.rsp`n  rspfile_content = `$in `$libs"
                
                if ($content -match $arPattern) {
                    $content = $content -replace $arPattern, $arReplacement
                }
                
                # Patch rule cxx
                $cxxPattern = 'rule cxx\s+command\s+= cmd /c "(.+?)em\+\+ \$defines \$includes \$flags -MD -MT \$out -MF \$out.d -c \$in -o \$out"'
                $cxxOpt = ""
                if ($Production) {
                    $cxxOpt = "-msimd128 -fno-rtti -fno-stack-protector -fno-asynchronous-unwind-tables -fomit-frame-pointer -finline-functions"
                }
                $cxxReplacement = "rule cxx`n  command         = cmd /c `"`$1em++ `$defines `$includes `$flags $cxxOpt -MD -MT `$out -MF `$out.d -c `$in -o `$out`""
                
                if ($content -match $cxxPattern) {
                    $content = $content -replace $cxxPattern, $cxxReplacement
                }

                # Patch rule link
                $linkPattern = 'rule link\s+command\s+= cmd /c "(.+?)em\+\+ -o \$out \$all_outputfiles \$walibs  \$libs  \$all_ldflags \$post_build"'
                
                # Optimization Flags
                $optFlags = "-O3"
                if ($Production) {
                    $optFlags += " -flto -msimd128 -fno-rtti -fno-stack-protector -fomit-frame-pointer -s MALLOC=emmalloc"
                } elseif ($Subtarget -eq "ample") {
                    $optFlags += " -flto" 
                }
                
                $memFlags = "-s ALLOW_MEMORY_GROWTH=1 -s INITIAL_MEMORY=1073741824 -s MAXIMUM_MEMORY=4294967296"
                $exceptionFlags = "-s DISABLE_EXCEPTION_CATCHING=0" 

                $linkReplacement = "rule link`n  command         = cmd /c `"`$1em++ $optFlags $memFlags $exceptionFlags -o `$out @`$out.rsp `$all_ldflags `$post_build`"`n  description     = link `$out`n  rspfile         = `$out.rsp`n  rspfile_content = `$all_outputfiles `$walibs `$libs"
                
                if ($content -match $linkPattern) {
                    $content = $content -replace $linkPattern, $linkReplacement
                }

                # CRITICAL: Replace $(EMSCRIPTEN) with absolute path for Windows CMD
                # Ninja passes the command to cmd /c, which needs the actual path
                # NOTE: Use .Replace() because PowerShell interprets $( as subexpression
                $content = $content.Replace('$(EMSCRIPTEN)', "$PSScriptRoot\emsdk\upstream\emscripten")
                
                # CRITICAL: Escape $(2) as $$(2) for ninja (used by mcs96make.py commands)
                # Ninja interprets $(...) as variable expansion, needs $$ for literal $
                $content = $content.Replace('$(2)', '$$(2)')
                
                # CRITICAL: Remove SDL2_fake which causes wasm-ld errors
                $content = $content -replace '-lSDL2_fake', ''
                
                # CRITICAL: Remove -Werror to prevent warnings from breaking the build
                $content = $content -replace '-Werror', ''

                # CRITICAL: Increase INITIAL_MEMORY for full build
                # MAME full build needs > 68MB initial memory. We set it to 512MB to be safe.
                $content = $content -replace '-s INITIAL_MEMORY=\d+MB', '-s INITIAL_MEMORY=512MB'
                
                # CRITICAL: Fix duplicate empty.o rule in precompile.ninja
                # This file conflicts with emu.ninja which also builds empty.o
                if ($file.Name -eq 'precompile.ninja') {
                    # Remove everything after the rules section - the build rules conflict with emu.ninja
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
                # Match any variation of escaped ERRNO_CODES and normalize to $$ERRNO_CODES (ninja needs $$ for literal $)
                $content = $content -replace 'DEFAULT_LIBRARY_FUNCS_TO_INCLUDE="?\[''[^'']*ERRNO_CODES[^'']*''\]"?', 'DEFAULT_LIBRARY_FUNCS_TO_INCLUDE=[''$$ERRNO_CODES'']'
                
                # CRITICAL: Add SDLMAME_EMSCRIPTEN define to osd_sdl.ninja and ocore_sdl.ninja to skip fontconfig include and llvm.clear_cache
                if ($file.Name -eq 'osd_sdl.ninja' -or $file.Name -eq 'ocore_sdl.ninja') {
                    $content = $content -replace '(-DNDEBUG -DCRLF=2 -DLSB_FIRST)', '$1 -DSDLMAME_EMSCRIPTEN'
                }
                
                # CRITICAL: Replace python3 with emsdk python.exe for Windows compatibility
                # Windows Store python3.exe is a stub that doesn't work with MAME's python scripts
                # Dynamically find the emsdk python path from the emsdk directory
                $mameRoot = (Get-Item $PSScriptRoot).Parent.FullName
                $emsdkPythonDir = Get-ChildItem "$mameRoot\emsdk\python" -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
                if ($emsdkPythonDir -and (Test-Path "$($emsdkPythonDir.FullName)\python.exe")) {
                    $emsdkPython = "$($emsdkPythonDir.FullName)\python.exe"
                    $content = $content -replace 'python3 ', "$emsdkPython "
                }
                
                # Write back with UTF8 no BOM
                $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
                [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBom)
            }
            Write-Host "   [+] Patched $(($files).Count) ninja files with correct encoding." -ForegroundColor Green
        }
    }

    # ============================================================================
    # BUILD EXECUTION
    # ============================================================================

    if ($useNinja) {
        Write-Host "`n[*] Starting Ninja build..." -ForegroundColor Yellow
        
        $mameRoot = (Get-Item $PSScriptRoot).Parent.FullName
        $solName = if ($Target -eq $Subtarget) { $Target } else { "$Target$Subtarget" }
        $expectedNinjaDir = "build/projects/sdl/$solName/ninja-asmjs/release"
        
        if (-not (Test-Path $expectedNinjaDir)) {
             $ninjaFiles = Get-ChildItem -Path "build" -Recurse -Filter "build.ninja"
             $ninjaFile = $ninjaFiles | Where-Object { $_.Directory.Name -match "release" } | Select-Object -First 1
             if ($ninjaFile) { $ninjaDir = $ninjaFile.Directory.FullName }
        } else {
             $ninjaDir = (Get-Item $expectedNinjaDir).FullName
        }
        
        if ($ninjaDir) {
            Write-Host "   [+] build.ninja found at: $ninjaDir" -ForegroundColor Green
            
            # CRITICAL: Pre-warm emscripten cache to prevent
            # "file has been modified during compilation" errors during parallel builds
            # Note: On Windows, full MAME builds may still fail due to emscripten cache race conditions.
            # For full builds, use WSL/Linux instead (see README.md for instructions).
            $emccPath = "$mameRoot\emsdk\upstream\emscripten\emcc.bat"
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
                
                # Make the emscripten cache read-only to prevent parallel build race conditions
                $cacheDir = "$mameRoot\emsdk\upstream\emscripten\cache"
                Write-Host "[*] Locking emscripten cache (read-only)..." -ForegroundColor Yellow
                Get-ChildItem $cacheDir -Recurse -File | ForEach-Object { $_.IsReadOnly = $true }
                Write-Host "[+] Emscripten cache warmed and locked successfully." -ForegroundColor Green
            }
            
            $ninjaCmd = "emmake ninja -j $cores -C `"$ninjaDir`""
            Write-Host "[*] Ninja Command: $ninjaCmd" -ForegroundColor DarkGray
            Invoke-Expression $ninjaCmd
            $buildStatus = $LASTEXITCODE
        } else {
            Write-Host "[-] Error: build.ninja not found." -ForegroundColor Red
            $buildStatus = 1
        }
    } else {
        Write-Host "`n[*] Starting Make build..." -ForegroundColor Yellow
        $makeCmd = "emmake make asmjs TARGET=$Target SUBTARGET=$Subtarget"
        if ($Sources) { $makeCmd += " SOURCES=$Sources" }
        $makeCmd += " OVERRIDE_CC=emcc.bat OVERRIDE_CXX=em++.bat IGNORE_GIT=1"
        $makeCmd += " -j $cores NOWERROR=1 DISABLE_EXCEPTION_CATCHING=$DisableExceptions CLANG_VERSION=22.0.0 DEBUG=$MameDebug"
        
        # LDFLAGS for all builds to ensure stability
        $makeCmd += ' LDFLAGS="-s ALLOW_MEMORY_GROWTH=1 -s INITIAL_MEMORY=536870912 -s MAXIMUM_MEMORY=4GB"'

        Invoke-Expression $makeCmd
        $buildStatus = $LASTEXITCODE
    }

} finally {
    Set-Location $initialDir
}

# ============================================================================
# COMPLETION
# ============================================================================

if ($buildStatus -eq 0) {
    Write-Host "`n[+] Build successful!" -ForegroundColor Green
    
    # Try multiple naming conventions
    $possibleNames = @(
        "$Target$Subtarget",           # mametiny
        "${Target}_${Subtarget}",      # mame_tiny
        $Subtarget                     # tiny
    )
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
                $wasmPath = $jsPath -replace "\.js$", ".wasm"
                $found = $true
                break
            }
        }
        if ($found) { break }
    }
    
    if ($found) {
        # Fix JS syntax error (backtick corruption)
        if (Test-Path $jsPath) {
            Write-Host "[*] Patching JS file for syntax errors..." -ForegroundColor Yellow
            $txt = [System.IO.File]::ReadAllText($jsPath)
            
            # Use Single Quotes to prevent variable expansion
            $bad1 = '_`$ERRNO_CODES'
            $bad2 = '_\\$ERRNO_CODES' # Handle double backslash case
            $good = '_$ERRNO_CODES'
            
            if ($txt.Contains($bad1)) { 
                $txt = $txt.Replace($bad1, $good)
                Write-Host "   [+] Fixed backtick corruption in $jsPath" -ForegroundColor Green
            }
            
            if ($txt.Contains($bad2)) {
                $txt = $txt.Replace($bad2, $good)
                Write-Host "   [+] Fixed double-slash corruption in $jsPath" -ForegroundColor Green
            }
            
            # Also fix the double-replace mess if it occurs
            $bad_mess = '_$ERRNO_CODES$ERRNO_CODES'
            if ($txt.Contains($bad_mess)) {
                $txt = $txt.Replace($bad_mess, $good)
                Write-Host "   [+] Fixed duplicate symbol in $jsPath" -ForegroundColor Green
            }
            
            [System.IO.File]::WriteAllText($jsPath, $txt)
        }

        $jsSize = (Get-Item $jsPath).Length / 1MB
        $wasmSize = if (Test-Path $wasmPath) { (Get-Item $wasmPath).Length / 1MB } else { 0 }
        Write-Host "[+] Output JS:   $jsPath ($([math]::Round($jsSize, 2)) MB)" -ForegroundColor Green
        Write-Host "[+] Output WASM: $wasmPath ($([math]::Round($wasmSize, 2)) MB)" -ForegroundColor Green
        
        # Copy to root for testing
        Write-Host "`n[*] Copying artifacts to project root for testing..." -ForegroundColor Yellow
        $copiedCount = 0
        Copy-Item $jsPath "$PSScriptRoot/$($name).js" -Force
        $copiedCount++
        
        if (Test-Path $wasmPath) {
            Copy-Item $wasmPath "$PSScriptRoot/$($name).wasm" -Force
            $copiedCount++
            Write-Host "   [+] Copied JS & WASM to $PSScriptRoot" -ForegroundColor Green
        } else {
            Write-Host "   [+] Copied JS to $PSScriptRoot" -ForegroundColor Green
        }
        
    } else {
        Write-Host "[-] Could not find expected output file. Checked: $($possibleNames -join ', ')" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n[-] Build failed." -ForegroundColor Red
    exit 1
}
