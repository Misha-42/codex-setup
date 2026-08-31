@echo off
title Codex - DeepSeek V4 Flash
echo Starting DeepSeek V4 Flash (deepseek-v4-flash)...
echo.
echo Model: deepseek-v4-flash
echo.

echo Press any key to start Codex...
pause > nul

"C:\Program Files\PowerShell\7\pwsh.exe" -NoExit -Command "codex --model deepseek-v4-flash"
