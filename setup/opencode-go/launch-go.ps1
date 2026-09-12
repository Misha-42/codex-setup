# launch-go.ps1 — запуск Claude Code через OpenCode Go (профиль A++).
# Изолированный профиль: C:\Users\user\.claude-go. Глобальный ~/.claude НЕ затрагивается.
# Прокси добавляет ключ OpenCode Go и заголовок x-opencode-session.
$ErrorActionPreference = 'Stop'
$ProfileDir = $PSScriptRoot
$ProxyScript = Join-Path $ProfileDir 'opencode-go-proxy.cjs'
$ProxyPort = 1889

function Test-Port([int]$port) {
    try {
        $c = New-Object System.Net.Sockets.TcpClient
        $iar = $c.BeginConnect('127.0.0.1', $port, $null, $null)
        if (-not $iar.AsyncWaitHandle.WaitOne(1000)) { $c.Close(); return $false }
        $c.EndConnect($iar); $c.Close(); return $true
    } catch { return $false }
}

if (-not (Test-Port $ProxyPort)) {
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Host 'node не найден — прокси не запустить.' -ForegroundColor Red
        Read-Host 'Enter для выхода'
        exit 1
    }
    Start-Process -FilePath 'node' -ArgumentList $ProxyScript -WindowStyle Hidden
    $deadline = [DateTime]::Now.AddSeconds(8)
    while (-not (Test-Port $ProxyPort) -and [DateTime]::Now -lt $deadline) { Start-Sleep -Milliseconds 300 }
}

if (-not (Test-Port $ProxyPort)) {
    Write-Host "Прокси не поднялся на 127.0.0.1:$ProxyPort" -ForegroundColor Red
    Read-Host 'Enter для выхода'
    exit 1
}

$env:CLAUDE_CONFIG_DIR = $ProfileDir
$env:ANTHROPIC_BASE_URL = "http://127.0.0.1:$ProxyPort"
$env:ANTHROPIC_AUTH_TOKEN = 'opencode-go-proxy'
$env:CLAUDE_CODE_EFFORT_LEVEL = 'low'

# --setting-sources user: не даём project-настройкам из <cwd>/.claude/settings.json
# (например C:\Users\user\.claude\settings.json = DashScope) перебить профиль Go.
# --permission-mode: задаём явно, иначе сессия стартует в режиме auto и классификатор
# auto-режима режет рутинные действия (подтверждено 2026-09-12). Флаг надёжнее ключа
# permissions.defaultMode в settings.json, который не всегда успевает примениться.
claude --model deepseek-v4.1-flash --effort low --setting-sources user --permission-mode bypassPermissions @args
