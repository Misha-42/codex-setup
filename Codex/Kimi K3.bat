@echo off
title Codex - Kimi K3
echo Starting Kimi K3 (DashScope)...
echo.
echo Model: kimi-k3
echo.

echo Press any key to start Codex...
pause > nul

"C:\Program Files\PowerShell\7\pwsh.exe" -NoExit -Command "codex --model kimi-k3"
