@echo off
title Codex - DeepSeek R1
echo Starting DeepSeek R1 (deepseek-r1)...
echo.
echo Model: deepseek-r1
echo.

echo Press any key to start Codex...
pause > nul

pwsh -NoExit -Command "codex --model deepseek-r1"

