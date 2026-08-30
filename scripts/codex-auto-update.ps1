# Auto-update models from DashScope API
# Runs once per day on Codex startup

param(
    [switch]$Force
)

$stateFile = "C:\Users\user\.codex\last-update.json"
$configFile = "C:\Users\user\.codex\config.toml"
$batFolder = "C:\Users\user\Desktop\Codex"
$apiKey = $env:DASHSCOPE_API_KEY
$codexPath = "C:\Users\user\AppData\Local\Programs\OpenAI\Codex\bin\codex.exe"

# Check if already updated today
if (-not $Force -and (Test-Path $stateFile)) {
    $state = Get-Content $stateFile -Raw | ConvertFrom-Json
    $lastUpdate = [DateTime]::Parse($state.lastUpdate)
    $today = Get-Date
    
    if ($lastUpdate.Date -eq $today.Date) {
        Write-Host "Already updated today at $($lastUpdate.ToString('HH:mm'))" -ForegroundColor Gray
        exit 0
    }
}

Write-Host "=== AUTO-UPDATING MODELS ===" -ForegroundColor Cyan
Write-Host ""

# Get models from API
$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri "https://dashscope.aliyuncs.com/compatible-mode/v1/models" -Headers $headers -Method Get -TimeoutSec 30
    $models = $response.data
    
    Write-Host "Fetched $($models.Count) models from API" -ForegroundColor Green
    
    # Group by category
    $categories = @{}
    foreach ($model in $models) {
        $id = $model.id
        if ($id -match '^(qwen|deepseek|glm|ZHIPU|kimi|stepfun|MiniMax)') {
            $cat = $Matches[1]
            if (-not $categories.ContainsKey($cat)) {
                $categories[$cat] = @()
            }
            $categories[$cat] += $id
        }
    }
    
    # Show summary
    Write-Host "`nCategories found:" -ForegroundColor Yellow
    foreach ($cat in $categories.Keys | Sort-Object) {
        Write-Host "  $cat : $($categories[$cat].Count) models" -ForegroundColor Gray
    }
    
    # Create bat files for top models
    Write-Host "`nCreating bat files for top models..." -ForegroundColor Yellow
    
    $topModels = @(
        # Qwen
        "qwen3.8-max",
        "qwen3.8-flash",
        "qwen3.7-max",
        "qwen3.7-plus",
        # DeepSeek
        "deepseek-v4-pro",
        "deepseek-v4-flash",
        "deepseek-r1",
        # GLM
        "ZHIPU/GLM-5.3",
        "ZHIPU/GLM-5.2",
        "ZHIPU/GLM-5.1",
        # Kimi
        "kimi-k3",
        "kimi-k2.7-code"
    )
    
    $created = 0
    foreach ($model in $topModels) {
        $fileName = "$model.bat" -replace '[/\\]', ' '
        $filePath = Join-Path $batFolder $fileName
        
        if (-not (Test-Path $filePath)) {
            $content = @"
@echo off
echo Starting $model (DashScope)...
"$codexPath" --model dashscope/$model
"@
            Set-Content -Path $filePath -Value $content -Encoding ASCII
            Write-Host "  Created: $fileName" -ForegroundColor Green
            $created++
        }
    }
    
    Write-Host "Created $created new bat files" -ForegroundColor Green
    
    # Update state
    $state = @{
        lastUpdate = (Get-Date).ToString("o")
        modelCount = $models.Count
        categories = $categories.Keys.Count
        batFilesCreated = $created
    }
    $state | ConvertTo-Json | Set-Content $stateFile
    
    Write-Host "`n=== UPDATE COMPLETE ===" -ForegroundColor Cyan
    Write-Host "Models: $($models.Count)" -ForegroundColor Gray
    Write-Host "Categories: $($categories.Keys.Count)" -ForegroundColor Gray
    Write-Host "New bat files: $created" -ForegroundColor Gray
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
