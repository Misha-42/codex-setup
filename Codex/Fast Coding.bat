@echo off
title Codex - Fast Coding
echo Starting Fast Coding (qwen3-coder-flash)...
echo.
echo Model: qwen3-coder-flash
echo.

echo Press any key to start Codex...
pause > nul

pwsh -NoExit -Command "codex --model qwen3-coder-flash"

