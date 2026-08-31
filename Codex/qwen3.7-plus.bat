@echo off
title Codex - Qwen3.7 Plus
echo Starting Qwen3.7 Plus (DashScope)...
echo.
echo Model: qwen3.7-plus
echo.

echo Press any key to start Codex...
pause > nul

"C:\Program Files\PowerShell\7\pwsh.exe" -NoExit -Command "codex --model qwen3.7-plus"
