@echo off
title Codex - GPT-5.6 Luna
echo Starting GPT-5.6 Luna (Tooken)...
echo.
echo Model: gpt-5.6-luna
echo.

echo Press any key to start Codex...
pause > nul

pwsh -NoExit -Command "codex -c model_provider=tooken --model gpt-5.6-luna"


