@echo off
title Codex - Claude Sonnet 5
echo Starting Claude Sonnet 5 (Tooken)...
echo.
echo Model: claude-sonnet-5
echo.

echo Press any key to start Codex...
pause > nul

pwsh -NoExit -Command "codex -c model_provider=tooken --model claude-sonnet-5"


