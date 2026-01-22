$ErrorActionPreference = "Continue"

$Subtargets = @("tiny", "arcade", "applulator", "mame")
$Sources = @{
    "tiny" = "src/mame/pacman/pacman.cpp"
    "arcade" = "src/mame/pacman/pacman.cpp"
    "applulator" = "src/mame/apple/apple2.cpp"
    "mame" = "src/mame/pacman/pacman.cpp"
}

Write-Host "`n[*] Starting multi-target verification..." -ForegroundColor Cyan

foreach ($sub in $Subtargets) {
    Write-Host "`n========================================================" -ForegroundColor Yellow
    Write-Host " TARGET: mame | SUBTARGET: $sub" -ForegroundColor Yellow
    Write-Host "========================================================" -ForegroundColor Yellow

    # CLEAN
    Write-Host "[*] Cleaning build folder..."
    if (Test-Path "mame/build") { Remove-Item "mame/build" -Recurse -Force }
    Remove-Item "mame/*.js", "mame/*.wasm" -ErrorAction SilentlyContinue

    # BUILD
    $src = $Sources[$sub]
    Write-Host "[*] Executing: ./build.ps1 -Target mame -Subtarget $sub -Sources $src"
    & ./build.ps1 -Target mame -Subtarget $sub -Sources $src

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] $sub build completed!" -ForegroundColor Green
    } else {
        Write-Host "[FAILED] $sub build failed with exit code $LASTEXITCODE" -ForegroundColor Red
        # We continue to next one even if one fails, to collect all errors
    }
}

Write-Host "`n[*] Verification process finished." -ForegroundColor Cyan