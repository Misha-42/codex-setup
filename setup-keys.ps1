# Setup API Keys for Codex
# Run this script to set up your own API keys

Write-Host "=== SETUP API KEYS ==="
Write-Host ""

# Ask for DashScope key
$dashscopeKey = Read-Host "Enter DashScope API Key (or press Enter to skip)"
if ($dashscopeKey) {
    [Environment]::SetEnvironmentVariable("DASHSCOPE_API_KEY", $dashscopeKey, "User")
    $env:DASHSCOPE_API_KEY = $dashscopeKey
    Write-Host "DASHSCOPE_API_KEY set!" -ForegroundColor Green
} else {
    Write-Host "Skipping DashScope key" -ForegroundColor Yellow
}

# Ask for KKToken key
$kktokenKey = Read-Host "Enter KKToken API Key (or press Enter to skip)"
if ($kktokenKey) {
    [Environment]::SetEnvironmentVariable("KKTOKEN_API_KEY", $kktokenKey, "User")
    $env:KKTOKEN_API_KEY = $kktokenKey
    Write-Host "KKTOKEN_API_KEY set!" -ForegroundColor Green
} else {
    Write-Host "Skipping KKToken key" -ForegroundColor Yellow
}

# Ask for Tooken key
$tookenKey = Read-Host "Enter Tooken Club API Key (or press Enter to skip)"
if ($tookenKey) {
    [Environment]::SetEnvironmentVariable("TOOKEN_API_KEY", $tookenKey, "User")
    $env:TOOKEN_API_KEY = $tookenKey
    Write-Host "TOOKEN_API_KEY set!" -ForegroundColor Green
} else {
    Write-Host "Skipping Tooken key" -ForegroundColor Yellow
}

Write-Host "`n=== KEYS SETUP COMPLETE ===" -ForegroundColor Cyan
Write-Host "Keys are set for current session and will persist after restart." -ForegroundColor Gray
