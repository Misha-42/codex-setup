@echo off
title Codex - DeepSeek Pro (with Proxy Check)
echo Starting DeepSeek Pro (deepseek-v4-pro)...
echo.
echo Model: deepseek-v4-pro
echo.

echo Checking proxy status...
netstat -ano | findstr ":1888" >nul 2>&1
if errorlevel 1 (
    echo Proxy is NOT running. Starting proxy...
    start "DashScope Proxy" node "C:\Users\user\dashscope-cache-proxy.cjs"
    timeout /t 3 /nobreak >nul
    echo Proxy started.
) else (
    echo Proxy is already running.
)

echo.
echo Press any key to start Codex...
pause > nul

"C:\Program Files\PowerShell\7\pwsh.exe" -NoExit -Command "codex --model deepseek-v4-pro"
