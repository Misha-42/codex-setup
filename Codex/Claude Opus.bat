@echo off
title Codex - Claude Opus 5
echo Starting Claude Opus 5 (KKToken)...
echo.
echo Model: claude-opus-5
echo.

echo Press any key to start Codex...
pause > nul

pwsh -NoExit -Command "codex -c model_provider=kktoken --model claude-opus-5"


