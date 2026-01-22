# MAME WASM Build Factory - Setup Script
# Initializes Windows environment for MAME WASM compilation

param(
    [switch]$SkipValidation = $false,
    [switch]$Force = $false
)

# Set encoding to UTF-8 to handle special characters correctly
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "`n[*] MAME WASM Build Factory - Setup" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# ============================================================================
# PHASE 1: PREREQUISITES
# ============================================================================

Write-Host "`n[1/5] Checking Prerequisites..." -ForegroundColor Yellow

$prereqs_ok = $true

# Check Git
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "   [-] Git not found. Install from: https://git-scm.com/" -ForegroundColor Red
    $prereqs_ok = $false
} else {
    Write-Host "   [+] Git found" -ForegroundColor Green
}

# Check Python
if (!(Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "   [-] Python not found. Install from: https://www.python.org/" -ForegroundColor Red
    $prereqs_ok = $false
} else {
    Write-Host "   [+] Python found" -ForegroundColor Green
}

if (-not $prereqs_ok -and -not $SkipValidation) {
    Write-Host "`n[-] Setup cannot continue. Please install missing prerequisites." -ForegroundColor Red
    exit 1
}

# ============================================================================
# PHASE 2: EMSCRIPTEN SDK
# ============================================================================

Write-Host "`n[2/5] Setting up Emscripten SDK..." -ForegroundColor Yellow

if ((Test-Path "emsdk") -and -not $Force) {
    Write-Host "   [*] emsdk folder exists (use -Force to reinstall)" -ForegroundColor Cyan
} else {
    Write-Host "   [*] Cloning Emscripten SDK..."
    git clone https://github.com/emscripten-core/emsdk.git
}

Push-Location emsdk
try {
    Write-Host "   [*] Updating emsdk..."
    git pull --quiet
    
    # Clean temp files
    if (Test-Path "unzip_temp") {
        Remove-Item -Path "unzip_temp" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Install with retry for file lock issues
    Write-Host "   [*] Installing latest Emscripten (this takes a few minutes)..."
    $maxRetries = 2
    $attempt = 0
    $installed = $false
    
    while ($attempt -lt $maxRetries -and -not $installed) {
        try {
            ./emsdk.bat install latest 2>$null
            if ($LASTEXITCODE -eq 0) {
                $installed = $true
                Write-Host "   [+] Emscripten installed" -ForegroundColor Green
            } else {
                throw "Install failed with exit code $LASTEXITCODE"
            }
        } catch {
            $attempt++
            if ($attempt -lt $maxRetries) {
                Write-Host "   [!] Retrying (file lock issue)... ($attempt/$maxRetries)" -ForegroundColor Yellow
                Start-Sleep -Seconds 5
            } else {
                Write-Host "   [!] Install had issues, check output." -ForegroundColor Yellow
            }
        }
    }
    
    # Activate
    Write-Host "   [*] Activating Emscripten..."
    ./emsdk.bat activate latest 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   [+] Emscripten activated" -ForegroundColor Green
    } else {
         Write-Host "   [!] Emscripten activation failed." -ForegroundColor Red
    }
    
} finally {
    Pop-Location
}

# ============================================================================
# PHASE 3: BUILD TOOLS
# ============================================================================

Write-Host "`n[3/5] Setting up Build Tools..." -ForegroundColor Yellow

# --- Make ---
Write-Host "   [*] Checking Make..." -ForegroundColor Cyan

$makePath = $null
if (Get-Command make -ErrorAction SilentlyContinue) {
    $makePath = (Get-Command make).Source
    Write-Host "   [+] System Make found" -ForegroundColor Green
} elseif (Get-Command mingw32-make -ErrorAction SilentlyContinue) {
    $makePath = (Get-Command mingw32-make).Source
    Write-Host "   [+] MinGW Make found" -ForegroundColor Green
} elseif (Test-Path "bin/make.exe") {
    $makePath = "$PWD/bin/make.exe"
    Write-Host "   [+] Local Make found" -ForegroundColor Green
} else {
    Write-Host "   [*] Downloading Make from GnuWin32..."
    try {
        New-Item -ItemType Directory -Force -Path "bin" -ErrorAction SilentlyContinue | Out-Null
        
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile('http://gnuwin32.sourceforge.net/downlinks/make-bin-zip.php', 'bin/make-bin.zip')
        $wc.DownloadFile('http://gnuwin32.sourceforge.net/downlinks/make-dep-zip.php', 'bin/make-dep.zip')
        
        # Extract
        $extractPath = (Resolve-Path 'bin').Path
        if (Test-Path 'C:/Program Files/7-Zip/7z.exe') {
            & 'C:/Program Files/7-Zip/7z.exe' x 'bin/make-bin.zip' -o'bin/' -y | Out-Null
            & 'C:/Program Files/7-Zip/7z.exe' x 'bin/make-dep.zip' -o'bin/' -y | Out-Null
        } else {
            $shell = New-Object -ComObject Shell.Application
            $zipBin = $shell.NameSpace((Resolve-Path 'bin/make-bin.zip').Path)
            $zipDep = $shell.NameSpace((Resolve-Path 'bin/make-dep.zip').Path)
            $dest = $shell.NameSpace($extractPath)
            
            $dest.CopyHere($zipBin.Items(), 16)
            $dest.CopyHere($zipDep.Items(), 16)
            
            # Smart wait for extraction
            $timeout = 20
            $timer = 0
            while (-not (Test-Path 'bin/bin/make.exe') -and $timer -lt $timeout) {
                Start-Sleep -Seconds 1
                $timer++
            }
        }
        
        # Organize
        if (Test-Path 'bin/bin/make.exe') {
            Copy-Item 'bin/bin/make.exe' 'bin/make.exe' -Force
            Copy-Item 'bin/bin/libintl3.dll' 'bin/libintl3.dll' -Force -ErrorAction SilentlyContinue
            Copy-Item 'bin/bin/libiconv2.dll' 'bin/libiconv2.dll' -Force -ErrorAction SilentlyContinue
        }
        
        # Cleanup
        Remove-Item 'bin/make-bin.zip', 'bin/make-dep.zip', 'bin/bin' -Force -Recurse -ErrorAction SilentlyContinue
        
        $makePath = "bin/make.exe"
        if (Test-Path $makePath) {
             Write-Host "   [+] Make installed" -ForegroundColor Green
        } else {
             Write-Host "   [!] Make install failed (file not found after extraction)." -ForegroundColor Red
        }
        
    } catch {
        Write-Host "   [!] Make download failed. Build may fail." -ForegroundColor Yellow
        Write-Host "   [!] Error: $_" -ForegroundColor Red
    }
}

# --- Ninja ---
Write-Host "   [*] Checking Ninja..." -ForegroundColor Cyan
if (Get-Command ninja -ErrorAction SilentlyContinue) {
    Write-Host "   [+] System Ninja found" -ForegroundColor Green
} elseif (Test-Path "bin/ninja.exe") {
    Write-Host "   [+] Local Ninja found" -ForegroundColor Green
} else {
    Write-Host "   [*] Downloading Ninja..."
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile('https://github.com/ninja-build/ninja/releases/download/v1.11.1/ninja-win.zip', 'bin/ninja.zip')
        
        # Extract
        $extractPath = (Resolve-Path 'bin').Path
        if (Test-Path 'C:/Program Files/7-Zip/7z.exe') {
            & 'C:/Program Files/7-Zip/7z.exe' x 'bin/ninja.zip' -o'bin/' -y | Out-Null
        } else {
            Expand-Archive -Path 'bin/ninja.zip' -DestinationPath 'bin' -Force
        }
        
        Remove-Item 'bin/ninja.zip' -Force -ErrorAction SilentlyContinue
        
        if (Test-Path "bin/ninja.exe") {
            Write-Host "   [+] Ninja installed" -ForegroundColor Green
        } else {
            Write-Host "   [!] Ninja install failed." -ForegroundColor Red
        }
    } catch {
        Write-Host "   [!] Ninja download failed: $_" -ForegroundColor Red
    }
}

# --- GCC Shim ---
Write-Host "   [*] Checking GCC..." -ForegroundColor Cyan

$binDir = "$PWD/bin"
New-Item -ItemType Directory -Force -Path $binDir -ErrorAction SilentlyContinue | Out-Null

$gccSystemPath = if (Get-Command gcc -ErrorAction SilentlyContinue) { 
    (Get-Command gcc).Source 
} else { 
    $null 
}

$clangPath = "$PWD/emsdk/upstream/bin/clang.exe"

if ($gccSystemPath -and -not (Test-Path "$binDir/gcc.exe")) {
    Write-Host "   [+] System GCC found" -ForegroundColor Green
} elseif (Test-Path $clangPath) {
    Write-Host "   [*] Creating GCC shims from Clang..."
    Copy-Item $clangPath "$binDir/gcc.exe" -Force -ErrorAction SilentlyContinue
    Copy-Item "$PWD/emsdk/upstream/bin/clang++.exe" "$binDir/g++.exe" -Force -ErrorAction SilentlyContinue
    Copy-Item "$PWD/emsdk/upstream/bin/llvm-ar.exe" "$binDir/ar.exe" -Force -ErrorAction SilentlyContinue
    Write-Host "   [+] GCC shims created" -ForegroundColor Green
} else {
    Write-Host "   [!] GCC not found. Emscripten may not be installed yet." -ForegroundColor Yellow
}

# ============================================================================
# PHASE 4: SOURCE CODE
# ============================================================================

Write-Host "`n[4/5] Setting up Source Code..." -ForegroundColor Yellow

# --- MAME ---
if ((Test-Path "mame") -and -not $Force) {
    Write-Host "   [+] MAME source exists" -ForegroundColor Green
} else {
    Write-Host "   [*] Cloning MAME source (depth=1)..."
    git clone --depth 1 https://github.com/mamedev/mame.git
    Write-Host "   [+] MAME source ready" -ForegroundColor Green
}

# --- Emularity ---
if (Test-Path "emularity/loader.js") {
    Write-Host "   [+] Emularity loader found" -ForegroundColor Green
} else {
    Write-Host "   [!] emularity/loader.js not found (optional)" -ForegroundColor Yellow
}

# ============================================================================
# PHASE 5: ROMS
# ============================================================================

Write-Host "`n[5/5] Setting up ROMs..." -ForegroundColor Yellow

if (!(Test-Path "roms")) {
    New-Item -ItemType Directory -Path "roms" | Out-Null
}

$robbyPath = "roms/robby.zip"
if (Test-Path $robbyPath) {
    Write-Host "   [+] robby.zip already exists" -ForegroundColor Green
} else {
    Write-Host "   [*] Downloading robby.zip (Free ROM from mamedev.org)..." -ForegroundColor Cyan
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile('https://www.mamedev.org/roms/robby/robby.zip', $robbyPath)
        Write-Host "   [+] robby.zip downloaded successfully" -ForegroundColor Green
    } catch {
        Write-Host "   [!] Failed to download robby.zip: $_" -ForegroundColor Yellow
    }
}

# ============================================================================
# COMPLETION
# ============================================================================

Write-Host "`n[+] Setup Complete!" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Next: ./build.ps1" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""