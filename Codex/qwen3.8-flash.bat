@echo off
title Codex - Qwen3.8 Flash
echo Starting Qwen3.8 Flash (DashScope)...
echo.
echo Model: qwen3.8-flash
echo.

echo Press any key to start Codex...
pause > nul

"C:\Program Files\PowerShell\7\pwsh.exe" -NoExit -Command "codex --model qwen3.8-flash"
