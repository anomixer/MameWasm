# MAME WASM Build Factory - Build Script
# Interactive script to compile MAME to WebAssembly

param(
    [string]$Target = "mame",
    [string]$Subtarget = "",
    [string]$Sources = "",
    [string]$Debug = "Y",
    [switch]$NoDebug = $false,
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
    Write-Host "  ldplayer   - LDPLAYER (rare)" -ForegroundColor Gray
    $Target = Read-Host "`nChoose TARGET (default: mame)"
    if (-not $Target) { $Target = "mame" }
}
Write-Host "  Selected: $Target" -ForegroundColor Green

# SUBTARGET
if (-not $Subtarget) {
    Write-Host "`n[SUBTARGET] Available options:" -ForegroundColor Cyan
    Write-Host "  tiny       - Minimal build (RECOMMENDED) ~30-50MB, 10-20 min" -ForegroundColor Yellow
    Write-Host "  mame       - Full MAME (all arcade) ~80-100MB, 1-2 hours" -ForegroundColor Gray
    Write-Host "  mess       - Retro computers & consoles ~60-80MB, 45-60 min" -ForegroundColor Gray
    Write-Host "  arcade     - Arcade games only ~70-90MB, 45-60 min" -ForegroundColor Gray
    Write-Host "  pacmantest - Pac-Man test build ~4MB, 2-5 min (FASTEST)" -ForegroundColor Yellow
    $Subtarget = Read-Host "`nChoose SUBTARGET (default: tiny)"
    if (-not $Subtarget) { $Subtarget = "tiny" }
}
Write-Host "  Selected: $Subtarget" -ForegroundColor Green

# SOURCES
if ($Sources -eq "" -and $PSBoundParameters.ContainsKey('Sources') -eq $false) {
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

# Exception handling / Debug Mode
if ($NoDebug) {
    $Debug = "n"
}

if ($Debug -eq "Y" -and $PSBoundParameters.ContainsKey('Debug') -eq $false -and -not $Subtarget) {
    $Debug = Read-Host "`nEnable exception handling? (Y/n)"
    if (-not $Debug) { $Debug = "Y" }
}

if ($Debug -like "n*") {
    $DisableExceptions = "1"
    $MameDebug = "0"
    Write-Host "  Selected: Exceptions Disabled (faster)" -ForegroundColor Green
} else {
    $DisableExceptions = "0"
    $MameDebug = "0" # Keep MAME internal debugger OFF by default to avoid web UI issues
    Write-Host "  Selected: Exceptions Enabled (stack traces visible)" -ForegroundColor Green
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
if (Get-Command ninja -ErrorAction SilentlyContinue) {
    $useNinja = $true
    Write-Host "[*] Ninja build system detected. Using Ninja to bypass Windows limits." -ForegroundColor Cyan
}

Write-Host "[*] Step 1: Running pre-build generation (layouts, version)..." -ForegroundColor Yellow

# Inject custom targets
if (Test-Path "$PSScriptRoot/custom_targets") {
    $targetDir = "$PWD/scripts/target/mame"
    if (Test-Path $targetDir) {
        Write-Host "   [*] Injecting custom target scripts..." -ForegroundColor Cyan
        Copy-Item "$PSScriptRoot/custom_targets/*.lua" -Destination $targetDir -Force
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
                
                # Patch rule link
                $linkPattern = 'rule link\s+command\s+= cmd /c "(.+?)em\+\+ -o \$out \$all_outputfiles \$walibs  \$libs  \$all_ldflags \$post_build"'
                # Added -s ALLOW_MEMORY_GROWTH=1 to the command
                $linkReplacement = "rule link`n  command         = cmd /c `"`$1em++ -o `$out @`$out.rsp `$all_ldflags -s ALLOW_MEMORY_GROWTH=1 `$post_build`"`n  description     = link `$out`n  rspfile         = `$out.rsp`n  rspfile_content = `$all_outputfiles `$walibs `$libs"
                
                if ($content -match $linkPattern) {
                    $content = $content -replace $linkPattern, $linkReplacement
                }

                # CRITICAL: Remove SDL2_fake which causes wasm-ld errors
                $content = $content -replace '-lSDL2_fake', ''
                
                # CRITICAL: Remove -Werror to prevent warnings from breaking the build
                $content = $content -replace '-Werror', ''

                # CRITICAL: Increase INITIAL_MEMORY for full build
                # MAME full build needs > 68MB initial memory. We set it to 512MB to be safe.
                $content = $content -replace '-s INITIAL_MEMORY=\d+MB', '-s INITIAL_MEMORY=512MB'
                
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
