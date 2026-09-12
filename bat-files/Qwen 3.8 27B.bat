@echo off
title Codex - Qwen 3.8 27B
echo Starting Qwen 3.8 27B (DashScope)...
echo.
echo Model: dashscope/qwen3.8-27b
echo.
echo Press any key to start Codex...
pause > nul
codex -c model_provider=dashscope --model qwen3.8-27b

