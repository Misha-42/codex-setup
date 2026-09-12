@echo off
title Codex - Code Review
echo Starting Code Review (qwen3.8-max)...
echo.
echo Model: dashscope/qwen3.8-max
echo.
echo Press any key to start Codex...
pause > nul
codex -c model_provider=dashscope --model qwen3.8-max

