# MAME WASM Build Factory - Build Script
# Interactive script to compile MAME to WebAssembly

param(
    [string]$Target = "",
    [string]$Subtarget = "",
    [string]$Sources = "",
    [switch]$Help = $false
)

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
$env:PATH = "$PWD/bin;$env:PATH"

# Set MINGW32 for MAME Makefile
# This is required by MAME's Makefile for WebAssembly builds
if (!$env:MINGW32) {
    $env:MINGW32 = "$PWD/bin"
}

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
    # Auto-convert shortcuts
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
if ($Exception -like "n*") {
    $ExceptionFlag = "0"
    Write-Host "  Selected: Disabled (faster)" -ForegroundColor Green
} else {
    $ExceptionFlag = "1"
    Write-Host "  Selected: Enabled (slower, better debugging)" -ForegroundColor Green
}

# ============================================================================
# BUILD CONFIGURATION
# ============================================================================

Write-Host "`n[*] Preparing build..." -ForegroundColor Yellow

cd mame

# Build command
$buildCmd = "make"
$buildCmd += " SUBTARGET=$Subtarget"
if ($Sources) {
    $buildCmd += " SOURCES=$Sources"
}
$buildCmd += " TARGET=$Target PLATFORM=emscripten EMCC_CFLAGS='-Oz' -j 4"
if ($ExceptionFlag -eq "0") {
    $buildCmd += " NOWERROR=1"
}

Write-Host "[+] Build configuration ready" -ForegroundColor Green

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
    
    # Check output files
    $jsFile = "mame/build/emscripten/obj/x64/Release/mame.js"
    $wasmFile = "mame/build/emscripten/obj/x64/Release/mame.wasm"
    
    if ((Test-Path $jsFile) -and (Test-Path $wasmFile)) {
        $jsSize = (Get-Item $jsFile).Length / 1MB
        $wasmSize = (Get-Item $wasmFile).Length / 1MB
        Write-Host "[+] Output files:" -ForegroundColor Green
        Write-Host "    JS:   $jsFile ($([math]::Round($jsSize, 2)) MB)" -ForegroundColor Cyan
        Write-Host "    WASM: $wasmFile ($([math]::Round($wasmSize, 2)) MB)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "[*] Next steps:" -ForegroundColor Yellow
        Write-Host "    1. Place ROM files in ./roms/ directory" -ForegroundColor Cyan
        Write-Host "    2. Run: python server.py" -ForegroundColor Cyan
        Write-Host "    3. Open: http://localhost:8000/test_vanilla.html" -ForegroundColor Cyan
        Write-Host "    4. Load ROM and play!" -ForegroundColor Cyan
    } else {
        Write-Host "[-] Output files not found at expected location" -ForegroundColor Red
    }
} else {
    Write-Host "`n[-] Build failed with status $buildStatus" -ForegroundColor Red
    Write-Host "[-] Check output above for errors" -ForegroundColor Red
    exit 1
}

Write-Host ""
