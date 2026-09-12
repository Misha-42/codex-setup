@echo off
title Codex - Qwen Plus
echo Starting Qwen Plus (qwen3.7-plus)...
echo.
echo Model: qwen3.7-plus
echo.

echo Press any key to start Codex...
pause > nul

pwsh -NoExit -Command "codex --model qwen3.7-plus"

