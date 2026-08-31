@echo off
title Codex - DeepSeek Pro
echo Starting DeepSeek Pro (deepseek-v4-pro)...
echo.
echo Model: deepseek-v4-pro
echo.

echo Press any key to start Codex...
pause > nul

"C:\Program Files\PowerShell\7\pwsh.exe" -NoExit -Command "codex --model deepseek-v4-pro"
