@echo off
title Codex - Claude Sonnet 5
echo Starting Claude Sonnet 5 (Tooken)...
echo.
echo Model: claude-sonnet-5
echo.

echo Press any key to start Codex...
pause > nul

"C:\Program Files\PowerShell\7\pwsh.exe" -NoExit -Command "codex --model claude-sonnet-5"
