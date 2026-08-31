# Find and restore Codex v0.149.0 backup
Write-Host "Searching for Codex v0.149.0 backup..." -ForegroundColor Yellow
Write-Host ""

# Search for backup file
$backupFile = Get-ChildItem -Path "C:\Users\user" -Filter "codex.exe.v0.149.0.backup" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

if ($backupFile) {
    Write-Host "✓ Found backup at: $($backupFile.FullName)" -ForegroundColor Green
    Write-Host ""

    # Find current codex.exe location
    $codexPath = "C:\Users\user\AppData\Local\Programs\OpenAI\Codex\bin\codex.exe"

    if (Test-Path $codexPath) {
        Write-Host "Current Codex location: $codexPath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Creating backup of v0.151.0..." -ForegroundColor Yellow
        Copy-Item $codexPath "$codexPath.v0.151.0.backup" -Force
        Write-Host "✓ v0.151.0 backed up" -ForegroundColor Green
        Write-Host ""

        Write-Host "Restoring v0.149.0..." -ForegroundColor Yellow
        Copy-Item $backupFile.FullName $codexPath -Force
        Write-Host "✓ v0.149.0 restored successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "You can now run Codex with v0.149.0" -ForegroundColor Green
    } else {
        Write-Host "✗ Codex.exe not found at expected location" -ForegroundColor Red
    }
} else {
    Write-Host "✗ Backup file not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Searching for all Codex executables..." -ForegroundColor Yellow
    Get-ChildItem -Path "C:\Users\user" -Filter "codex*.exe*" -Recurse -ErrorAction SilentlyContinue | Select-Object FullName, Length, LastWriteTime | Format-Table -AutoSize
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
