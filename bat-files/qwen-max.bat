@echo off
title Codex - Qwen Max
echo Starting Qwen Max (DashScope)...
echo.
echo Model: dashscope/qwen-max
echo.
echo Press any key to start Codex...
pause > nul
codex -c model_provider=dashscope --model qwen-max

