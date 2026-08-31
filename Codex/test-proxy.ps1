# Test proxy connection
$headers = @{
    "Authorization" = "Bearer $env:DASHSCOPE_API_KEY"
    "Content-Type" = "application/json"
}

$body = @{
    model = "deepseek-v4-pro"
    messages = @(
        @{
            role = "user"
            content = "Hello, test"
        }
    )
} | ConvertTo-Json

Write-Host "Testing proxy at http://127.0.0.1:1888..." -ForegroundColor Yellow
Write-Host "API Key: $env:DASHSCOPE_API_KEY" -ForegroundColor Cyan
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri "http://127.0.0.1:1888/v1/chat/completions" -Method Post -Headers $headers -Body $body -TimeoutSec 30
    Write-Host "✓ Proxy is working!" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 10
} catch {
    Write-Host "✗ Proxy test failed!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
