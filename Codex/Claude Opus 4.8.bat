@echo off
title Codex - Claude Opus 4.8
echo Starting Claude Opus 4.8 (KKToken)...
echo.
echo Model: claude-opus-4-8
echo.

echo Press any key to start Codex...
pause > nul

"C:\Program Files\PowerShell\7\pwsh.exe" -NoExit -Command "codex --model claude-opus-4-8"
