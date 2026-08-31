@echo off
title Codex - Code Review
echo Starting Code Review (qwen3.8-max)...
echo.
echo Model: qwen3.8-max
echo.

echo Press any key to start Codex...
pause > nul

"C:\Program Files\PowerShell\7\pwsh.exe" -NoExit -Command "codex --model qwen3.8-max"
