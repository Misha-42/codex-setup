# Check if proxy is running on port 1888
Write-Host "Checking if proxy is running on port 1888..." -ForegroundColor Yellow
$proxyPort = netstat -ano | Select-String ":1888"

if ($proxyPort) {
    Write-Host "✓ Proxy is running on port 1888" -ForegroundColor Green
    Write-Host $proxyPort
} else {
    Write-Host "✗ Proxy is NOT running on port 1888" -ForegroundColor Red
    Write-Host ""
    Write-Host "Starting proxy..." -ForegroundColor Yellow

    # Check if proxy file exists
    if (Test-Path "C:\Users\user\dashscope-cache-proxy.cjs") {
        Start-Process "node" -ArgumentList "C:\Users\user\dashscope-cache-proxy.cjs" -WindowStyle Normal
        Start-Sleep -Seconds 2
        Write-Host "✓ Proxy started" -ForegroundColor Green
    } else {
        Write-Host "✗ Proxy file not found at C:\Users\user\dashscope-cache-proxy.cjs" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
