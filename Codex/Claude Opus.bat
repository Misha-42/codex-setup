@echo off
title Codex - Claude Opus 5
echo Starting Claude Opus 5 (KKToken)...
echo.
echo Model: claude-opus-5
echo.

echo Press any key to start Codex...
pause > nul

"C:\Program Files\PowerShell\7\pwsh.exe" -NoExit -Command "codex --model claude-opus-5"
