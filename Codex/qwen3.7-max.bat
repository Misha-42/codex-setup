@echo off
title Codex - Qwen3.7 Max
echo Starting Qwen3.7 Max (DashScope)...
echo.
echo Model: qwen3.7-max
echo.

echo Press any key to start Codex...
pause > nul

"C:\Program Files\PowerShell\7\pwsh.exe" -NoExit -Command "codex --model qwen3.7-max"
