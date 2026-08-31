# Kill all Codex processes and restore v0.149.0
Write-Host "Stopping all Codex processes..." -ForegroundColor Yellow
Get-Process -Name "codex*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
Write-Host "✓ All Codex processes stopped" -ForegroundColor Green
Write-Host ""

Write-Host "Searching for Codex v0.149.0 backup..." -ForegroundColor Yellow
$backupFile = "C:\Users\user\.codex\packages\standalone\releases\0.139.0-x86_64-pc-windows-msvc\bin\codex.exe.v0.149.0.backup"

if (Test-Path $backupFile) {
    Write-Host "✓ Found backup at: $backupFile" -ForegroundColor Green
    Write-Host ""

    $codexPath = "C:\Users\user\AppData\Local\Programs\OpenAI\Codex\bin\codex.exe"

    if (Test-Path $codexPath) {
        Write-Host "Current Codex location: $codexPath" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "Creating backup of v0.151.0..." -ForegroundColor Yellow
        Copy-Item $codexPath "$codexPath.v0.151.0.backup" -Force
        Write-Host "✓ v0.151.0 backed up" -ForegroundColor Green
        Write-Host ""

        Write-Host "Restoring v0.149.0..." -ForegroundColor Yellow
        Copy-Item $backupFile $codexPath -Force
        Write-Host "✓ v0.149.0 restored successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "You can now run Codex with v0.149.0" -ForegroundColor Green
    } else {
        Write-Host "✗ Codex.exe not found at expected location" -ForegroundColor Red
    }
} else {
    Write-Host "✗ Backup file not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
