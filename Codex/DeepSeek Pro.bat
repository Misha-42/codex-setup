@echo off
title Codex - DeepSeek Pro
echo Starting DeepSeek Pro (deepseek-v4-pro)...
echo.
echo Model: deepseek-v4-pro
echo.

echo Press any key to start Codex...
pause > nul

pwsh -NoExit -Command "codex --model deepseek-v4-pro"

