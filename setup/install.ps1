# Установка Claude Code + DashScope на новом ПК
# Запуск:  pwsh -File .\setup\install.ps1
$ErrorActionPreference = "Stop"

$claudeDir = Join-Path $env:USERPROFILE ".claude"
$claudeJson = Join-Path $env:USERPROFILE ".claude.json"
$src = Join-Path $PSScriptRoot "settings.json"

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  Write-Output "Claude Code не найден — ставлю через npm..."
  npm install -g @anthropic-ai/claude-code
}

New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null

if (Test-Path (Join-Path $claudeDir "settings.json")) {
  Copy-Item (Join-Path $claudeDir "settings.json") (Join-Path $claudeDir "settings.json.bak") -Force
  Write-Output "Старый settings.json сохранён как settings.json.bak"
}
Copy-Item $src (Join-Path $claudeDir "settings.json") -Force
Write-Output "settings.json установлен (ключ + модели DashScope)"

if (Test-Path $claudeJson) {
  $j = Get-Content $claudeJson -Raw | ConvertFrom-Json
} else {
  $j = [PSCustomObject]@{}
}
$j | Add-Member -NotePropertyName hasCompletedOnboarding -NotePropertyValue $true -Force
$j | ConvertTo-Json -Depth 100 | Set-Content $claudeJson -Encoding UTF8
Write-Output "hasCompletedOnboarding=true прописан в .claude.json"

# Субагенты: Claude Code и opencode
$repoAgents = Join-Path $PSScriptRoot "..\agents"
$ccAgentsSrc = Join-Path $repoAgents "claude-code"
$ocAgentsSrc = Join-Path $repoAgents "opencode"

if (Test-Path $ccAgentsSrc) {
  $ccAgentsDst = Join-Path $claudeDir "agents"
  New-Item -ItemType Directory -Path $ccAgentsDst -Force | Out-Null
  Copy-Item (Join-Path $ccAgentsSrc "*.md") $ccAgentsDst -Force
  Write-Output "Субагенты Claude Code установлены в $ccAgentsDst"
}

if (Test-Path $ocAgentsSrc) {
  $ocAgentsDst = Join-Path $env:USERPROFILE ".config\opencode\agent"
  New-Item -ItemType Directory -Path $ocAgentsDst -Force | Out-Null
  Copy-Item (Join-Path $ocAgentsSrc "*.md") $ocAgentsDst -Force
  Write-Output "Субагенты opencode установлены в $ocAgentsDst"
}

Write-Output ""
Write-Output "Готово. Открой НОВЫЙ терминал и запусти: claude"
