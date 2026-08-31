@echo off
title Codex - Custom Model
echo Starting Custom Model...
echo.
echo Model: %MODEL%
echo.

echo Press any key to start Codex...
pause > nul

"C:\Program Files\PowerShell\7\pwsh.exe" -NoExit -Command "codex --model %MODEL%"
