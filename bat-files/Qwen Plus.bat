@echo off
title Codex - Qwen Plus
echo Starting Qwen Plus (qwen3.7-plus)...
echo.
echo Model: dashscope/qwen3.7-plus
echo.
echo Press any key to start Codex...
pause > nul
codex -c model_provider=dashscope --model qwen3.7-plus

