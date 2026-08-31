@echo off
title Codex - Qwen Max Longcontext
echo Starting Qwen Max Longcontext (DashScope)...
echo.
echo Model: qwen-max-longcontext
echo.

echo Press any key to start Codex...
pause > nul

"C:\Program Files\PowerShell\7\pwsh.exe" -NoExit -Command "codex --model qwen-max-longcontext"
