@echo off
title Codex - DeepSeek Coding
echo Starting DeepSeek Coding (deepseek-v4-flash)...
echo.
echo Model: deepseek-v4-flash
echo.

echo Press any key to start Codex...
pause > nul

pwsh -NoExit -Command "codex --model deepseek-v4-flash"

