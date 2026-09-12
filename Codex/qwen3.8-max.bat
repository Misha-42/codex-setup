@echo off
title Codex - Qwen3.8 Max
echo Starting Qwen3.8 Max (DashScope)...
echo.
echo Model: qwen3.8-max
echo.

echo Press any key to start Codex...
pause > nul

pwsh -NoExit -Command "codex --model qwen3.8-max"

