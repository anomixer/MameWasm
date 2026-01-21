# MAME WASM Build Factory - Build Script
# Interactive script to compile MAME to WebAssembly

param(
    [string]$Target = "",
    [string]$Subtarget = "",
    [string]$Sources = "",
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
. ./emsdk/emsdk_env.ps1

# Verify emcc is in path
if (!(Get-Command emcc -ErrorAction SilentlyContinue)) {
    Write-Host "[-] Emscripten activation failed. 'emcc' not found in PATH." -ForegroundColor Red
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

# Exception handling
Write-Host "`n[EXCEPTIONS] Debug mode:" -ForegroundColor Cyan
Write-Host "  Y - Enable exceptions (slower, better debugging)" -ForegroundColor Gray
Write-Host "  n - Disable exceptions (faster compilation)" -ForegroundColor Gray
$Exception = Read-Host "`nEnable exception handling? (default: Y)"

# Fix Logic: 
# If User says 'n' (Disable), we want DISABLE_EXCEPTION_CATCHING=1 (True, Disable it)
# If User says 'Y' (Enable), we want DISABLE_EXCEPTION_CATCHING=0 (False, Don't disable it)

if ($Exception -like "n*") {
    $DisableExceptions = "1"
    Write-Host "  Selected: Disabled (faster)" -ForegroundColor Green
} else {
    $DisableExceptions = "0"
    Write-Host "  Selected: Enabled (slower, better debugging)" -ForegroundColor Green
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

# Build command for Emscripten WebAssembly compilation
# Key points:
# 1. emmake wrapper ensures Emscripten environment is used
# 2. Target 'asmjs' triggers MAME's specific Emscripten/WASM build logic
# 3. OVERRIDE_CC/OVERRIDE_CXX forces emcc/em++
$buildCmd = "emmake make asmjs"
$buildCmd += " TARGET=$Target"
$buildCmd += " SUBTARGET=$Subtarget"
if ($Sources) {
    $buildCmd += " SOURCES=$Sources"
}
# CROSS_BUILD=1 is implied by asmjs target in some MAME versions, but good to be explicit if needed.
# However, 'asmjs' target usually handles toolchain setup.
$buildCmd += " OVERRIDE_CC=emcc.bat OVERRIDE_CXX=em++.bat"
$buildCmd += " -j $cores NOWERROR=1"
$buildCmd += " DISABLE_EXCEPTION_CATCHING=$DisableExceptions"

Write-Host "[+] Build configuration ready" -ForegroundColor Green
Write-Host "[*] Command: $buildCmd" -ForegroundColor DarkGray

# ============================================================================
# BUILD EXECUTION
# ============================================================================

Write-Host "`n[*] Starting MAME compilation..." -ForegroundColor Yellow
Write-Host "[*] This may take 5 minutes to 2 hours depending on SUBTARGET" -ForegroundColor Cyan
Write-Host ""

# Run build
Invoke-Expression $buildCmd
$buildStatus = $LASTEXITCODE

cd ..

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