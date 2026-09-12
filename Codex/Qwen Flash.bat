@echo off
title Codex - Qwen Flash
echo Starting Qwen Flash (qwen3.6-flash)...
echo.
echo Model: qwen3.6-flash
echo.

echo Press any key to start Codex...
pause > nul

pwsh -NoExit -Command "codex --model qwen3.6-flash"

