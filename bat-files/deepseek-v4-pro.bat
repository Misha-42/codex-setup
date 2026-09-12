@echo off
title Codex - DeepSeek V4 Pro
echo Starting DeepSeek V4 Pro (deepseek-v4-pro)...
echo.
echo Model: dashscope/deepseek-v4-pro
echo.
echo Press any key to start Codex...
pause > nul
codex -c model_provider=dashscope --model deepseek-v4-pro

