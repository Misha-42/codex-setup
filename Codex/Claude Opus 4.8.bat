@echo off
title Codex - Claude Opus 4.8
echo Starting Claude Opus 4.8 (KKToken)...
echo.
echo Model: claude-opus-4-8
echo.

echo Press any key to start Codex...
pause > nul

pwsh -NoExit -Command "codex -c model_provider=kktoken --model claude-opus-4-8"


