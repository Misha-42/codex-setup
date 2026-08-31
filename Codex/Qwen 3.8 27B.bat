@echo off
title Codex - Qwen 3.8 27B
echo Starting Qwen 3.8 27B (DashScope)...
echo.
echo Model: qwen3.8-27b
echo.

echo Press any key to start Codex...
pause > nul

"C:\Program Files\PowerShell\7\pwsh.exe" -NoExit -Command "codex --model qwen3.8-27b"
