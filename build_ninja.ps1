$ErrorActionPreference = "Stop"

# Setup Emscripten
. ./emsdk/emsdk_env.ps1
$env:PATH = "$PWD/emsdk/upstream/emscripten;$env:PATH"
$env:EMSCRIPTEN = "$PWD/emsdk/upstream/emscripten"

# Add current dir to PATH for ninja.exe
$env:PATH = "$PWD;$env:PATH"

Write-Host "Generating Ninja files..."
cd mame
./3rdparty/genie/bin/windows/genie.exe --target=mame --subtarget=mame --gcc=asmjs --gcc_version=22.0.0 --osd=sdl --NOASM=1 --NOWERROR=1 --build-dir=build --PLATFORM=x64 --USE_QTDEBUG=0 --with-emulator ninja

Write-Host "Building with Ninja..."
Set-Location build/projects/sdl/mame/ninja-asmjs/release
ninja mame
ninja

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build successful!"
} else {
    Write-Host "Build failed!"
}
