@echo off
title Codex - Qwen Max
echo Starting Qwen Max (DashScope)...
echo.
echo Model: qwen-max
echo.

echo Press any key to start Codex...
pause > nul

pwsh -NoExit -Command "codex --model qwen-max"

