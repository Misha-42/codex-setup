@echo off
title Codex - Qwen VL Max
echo Starting Qwen VL Max (DashScope)...
echo.
echo Model: qwen-vl-max
echo.

echo Press any key to start Codex...
pause > nul

pwsh -NoExit -Command "codex --model qwen-vl-max"

