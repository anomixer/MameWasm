# MAME WASM Build Factory - Build Script
# Interactive script to compile MAME to WebAssembly

param(
    [string]$Target = "mame",
    [string]$Subtarget = "",
    [string]$Sources = "",
    [string]$Debug = "Y",
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
    robby        - Robby Roto
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
    # Resolve 'C:\Program Files\Git\cmd\git.exe' -> 'C:\Program Files\Git\usr\bin'
    $gitRoot = (Get-Item $gitCmd.Source).Directory.Parent.FullName
    $gitUsrBin = Join-Path $gitRoot "usr\bin"
    
    if (Test-Path $gitUsrBin) {
        $env:PATH = "$gitUsrBin;$env:PATH"
        Write-Host "[+] Git Unix tools added to PATH (Detected: $gitUsrBin)" -ForegroundColor Green
    } else {
        # Fallback to standard locations
        $gitPaths = @(
            "C:/Program Files/Git/usr/bin",
            "C:/Program Files (x86)/Git/usr/bin",
            "$ENV:ProgramFiles/Git/usr/bin"
        )
        foreach ($gitPath in $gitPaths) {
            if (Test-Path $gitPath) {
                $env:PATH = "$gitPath;$env:PATH"
                Write-Host "[+] Git Unix tools added to PATH (Standard)" -ForegroundColor Green
                break
            }
        }
    }
}

# CRITICAL: Set TOOLCHAIN to empty to prevent MAME from auto-detecting GCC
# MAME's scripts/toolchain.lua will default to system compiler if TOOLCHAIN is set
# By leaving it empty, emmake's CC/CXX overrides will work
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
if ($Sources -eq "") {
    Write-Host "`n[SOURCES] Available options:" -ForegroundColor Cyan
    Write-Host "  (leave empty)              - All drivers in SUBTARGET" -ForegroundColor Gray
    Write-Host "  pacman                     - Pac-Man (auto-convert to full path)" -ForegroundColor Gray
    Write-Host "  robby                      - Robby Roto (auto-convert to full path)" -ForegroundColor Gray
    Write-Host "  src/mame/pacman/pacman.cpp - Pac-Man (full path)" -ForegroundColor Gray
    Write-Host "  src/mame/midway/astrocde.cpp - Robby Roto (full path)" -ForegroundColor Gray
    Write-Host "  src/mame/midw8080/mw8080bw.cpp - Space Invaders (full path)" -ForegroundColor Gray
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
# Default to "Y" if not specified to prevent hanging in automation
if ($Debug -eq "" -and -not $Subtarget) {
    Write-Host "`n[DEBUG] Exception handling mode:" -ForegroundColor Cyan
    Write-Host "  Y - Enable exceptions (slower, better debugging - DEFAULT)" -ForegroundColor Gray
    Write-Host "  n - Disable exceptions (faster compilation)" -ForegroundColor Gray
    $Debug = Read-Host "`nEnable exception handling? (Y/n)"
    if (-not $Debug) { $Debug = "Y" }
}

if ($Debug -like "n*") {
    $DisableExceptions = "1"
    Write-Host "  Selected: Exceptions Disabled (faster)" -ForegroundColor Green
} else {
    $DisableExceptions = "0"
    Write-Host "  Selected: Exceptions Enabled (slower, better debugging)" -ForegroundColor Green
}

# ============================================================================
# BUILD CONFIGURATION
# ============================================================================

Write-Host "`n[*] Preparing build..." -ForegroundColor Yellow

cd mame

# Determine CPU cores for -j flag (Default to processors - 1, min 1)
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

# Build command for Emscripten WebAssembly compilation
# Key points:
# 1. emmake wrapper ensures Emscripten environment is used
# 2. Target 'asmjs' triggers MAME's specific Emscripten/WASM build logic
# 3. OVERRIDE_CC/OVERRIDE_CXX forces emcc/em++

# Step 1: Generate Prerequisites (Layouts, Version, etc.)
# We run 'make generate' to handle layouts and version.cpp. 
# This is safe and doesn't trigger the build or the buggy Ninja generation in Makefile.
Write-Host "[*] Step 1: Running pre-build generation (layouts, version)..." -ForegroundColor Yellow

$initialDir = $PSScriptRoot
# Use Push-Location to safely enter 'mame' dir
Push-Location "mame"

try {
    $preBuildCmd = "make generate TARGET=$Target SUBTARGET=$Subtarget IGNORE_GIT=1"
    Write-Host "[*] Command: $preBuildCmd" -ForegroundColor DarkGray
    Invoke-Expression $preBuildCmd

    if ($LASTEXITCODE -ne 0) {
        Write-Host "[-] Pre-build generation failed." -ForegroundColor Red
        exit 1
    }

    # Step 2: Generate Project Files
    if ($useNinja) {
        Write-Host "[*] Step 2: Generating Ninja project files (Direct Genie invocation)..." -ForegroundColor Yellow
        
        # Locate Genie (relative to 'mame' dir)
        $genieExe = "$PWD/3rdparty/genie/bin/windows/genie.exe"
        if (-not (Test-Path $genieExe)) {
            Write-Host "[-] Genie not found at $genieExe. 'make generate' should have built it." -ForegroundColor Red
            exit 1
        }

        # Construct Genie Command
        # We bypass the makefile to avoid environment variable truncation issues on Windows.
        $genieArgs = @(
            "--file=scripts/genie.lua",
            "--build-dir=build",
            "--osd=sdl",
            "--targetos=asmjs",
            "--gcc=asmjs",
            "--gcc_version=22.0.0", # Hardcoded safe version for Clang (Emscripten uses recent Clang)
            "--target=$Target",
            "--subtarget=$Subtarget",
            "--PLATFORM=x64", # Required by toolchain.lua
            "ninja"
        )
        
        if ($Sources) {
            # Genie doesn't standardly support SOURCES, but MAME's scripts might handle it or we ignore it for project gen.
            # If we ignore it, we build everything in that subtarget.
            Write-Host "[!] Note: specific SOURCES='$Sources' not applied to project generation. Full subtarget will be built." -ForegroundColor Yellow
        }

        # Execute Genie
        $proc = Start-Process -FilePath $genieExe -ArgumentList $genieArgs -NoNewWindow -PassThru -Wait
        
        if ($proc.ExitCode -ne 0) {
            Write-Host "[-] Genie project generation failed." -ForegroundColor Red
            exit 1
        }
    } else {
        # Fallback to Make (Step 2 merged with Build)
        Write-Host "[*] Step 2: Configuring for Make build..." -ForegroundColor Yellow
        # Nothing specific needed, standard make command handles generation + build
    }

    # ============================================================================
    # BUILD EXECUTION
    # ============================================================================

    if ($useNinja) {
        Write-Host "`n[*] Starting Ninja build..." -ForegroundColor Yellow
        
        # Find build.ninja - Prioritize RELEASE configuration
        $ninjaFiles = Get-ChildItem -Path "build" -Recurse -Filter "build.ninja"
        $ninjaFile = $ninjaFiles | Where-Object { $_.Directory.Name -match "release" } | Select-Object -First 1
        
        # Fallback if release not found
        if (-not $ninjaFile) {
             $ninjaFile = $ninjaFiles | Select-Object -First 1
        }
        
        if ($ninjaFile) {
            $ninjaDir = $ninjaFile.Directory.FullName
            Write-Host "   [+] build.ninja found at: $ninjaDir" -ForegroundColor Green
            
            # We invoke 'emmake ninja' here. 'emmake' sets up the environment variables for compilation.
            $ninjaCmd = "emmake ninja -j $cores -C `"$ninjaDir`""
            
            # If SOURCES is provided, we can try to filter at the Ninja level if Ninja supports it, 
            # but MAME's Ninja structure might be complex. 
            # For now, we build the default target in the ninja file.
            
            Write-Host "[*] Ninja Command: $ninjaCmd" -ForegroundColor DarkGray
            Invoke-Expression $ninjaCmd
            $buildStatus = $LASTEXITCODE
        } else {
            Write-Host "[-] Error: build.ninja not found after Genie generation." -ForegroundColor Red
            $buildStatus = 1
        }

    } else {
        # Legacy Make Build
        Write-Host "`n[*] Starting Make build..." -ForegroundColor Yellow
        $makeCmd = "emmake make asmjs TARGET=$Target SUBTARGET=$Subtarget"
        if ($Sources) { $makeCmd += " SOURCES=$Sources" }
        $makeCmd += " OVERRIDE_CC=emcc.bat OVERRIDE_CXX=em++.bat IGNORE_GIT=1"
        $makeCmd += " -j $cores NOWERROR=1 DISABLE_EXCEPTION_CATCHING=$DisableExceptions"
        
        # LDFLAGS for large builds
        if ($Subtarget -in @("mame", "mess", "arcade", "applulator")) {
            $makeCmd += ' LDFLAGS="-s ALLOW_MEMORY_GROWTH=1 -s INITIAL_MEMORY=536870912 -s MAXIMUM_MEMORY=4GB"'
        }
        
        Write-Host "[*] Make Command: $makeCmd" -ForegroundColor DarkGray
        Invoke-Expression $makeCmd
        $buildStatus = $LASTEXITCODE
    }

} finally {
    # Always return to the original directory
    if ($initialDir) {
        Set-Location $initialDir
    } else {
        Pop-Location
    }
}

# ============================================================================
# COMPLETION
# ============================================================================

if ($buildStatus -eq 0) {
    Write-Host "`n[+] Build successful!" -ForegroundColor Green
    Write-Host "==========================" -ForegroundColor Green
    
    # Smart File Detection (Search for newest JS file in build folder)
    $jsFile = Get-ChildItem -Path "mame" -Recurse -Filter "*.js" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    if ($jsFile) {
        $jsPath = $jsFile.FullName
        # Assuming wasm is next to it
        $wasmPath = $jsPath -replace "\.js$", ".wasm"
        
        $jsSize = $jsFile.Length / 1MB
        
        Write-Host "[+] Output files found:" -ForegroundColor Green
        Write-Host "    JS:   $jsPath ($([math]::Round($jsSize, 2)) MB)" -ForegroundColor Cyan
        
        if (Test-Path $wasmPath) {
            $wasmSize = (Get-Item $wasmPath).Length / 1MB
            Write-Host "    WASM: $wasmPath ($([math]::Round($wasmSize, 2)) MB)" -ForegroundColor Cyan
        } else {
            Write-Host "    WASM: Not found (expected at $wasmPath)" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "[*] Next steps:" -ForegroundColor Yellow
        Write-Host "    1. Place ROM files in ./roms/ directory" -ForegroundColor Cyan
        Write-Host "    2. Run: python server.py" -ForegroundColor Cyan
        Write-Host "    3. Open: http://localhost:8000/test_vanilla.html" -ForegroundColor Cyan
        Write-Host "    4. Load ROM and play!" -ForegroundColor Cyan
    } else {
        Write-Host "[-] Build reported success, but no .js output file found in mame/ directory." -ForegroundColor Yellow
        Write-Host "    Check mame/build/ folder manually." -ForegroundColor Yellow
    }
} else {
    Write-Host "`n[-] Build failed with status $buildStatus" -ForegroundColor Red
    Write-Host "[-] Check output above for errors" -ForegroundColor Red
    exit 1
}

Write-Host ""