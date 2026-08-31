@echo off
title Codex - Qwen3.6 Max Preview
echo Starting Qwen3.6 Max Preview (DashScope)...
echo.
echo Model: qwen3.6-max-preview
echo.

echo Press any key to start Codex...
pause > nul

"C:\Program Files\PowerShell\7\pwsh.exe" -NoExit -Command "codex --model qwen3.6-max-preview"
