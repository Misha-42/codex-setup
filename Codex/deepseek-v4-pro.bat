@echo off
title Codex - DeepSeek V4 Pro
echo Starting DeepSeek V4 Pro (deepseek-v4-pro)...
echo.
echo Model: deepseek-v4-pro
echo.

echo Press any key to start Codex...
pause > nul

"C:\Program Files\PowerShell\7\pwsh.exe" -NoExit -Command "codex --model deepseek-v4-pro"
