@echo off
title Codex - DeepSeek Coding
echo Starting DeepSeek Coding (deepseek-v4-flash)...
echo.
echo Model: dashscope/deepseek-v4-flash
echo.
echo Press any key to start Codex...
pause > nul
codex -c model_provider=dashscope --model deepseek-v4-flash

