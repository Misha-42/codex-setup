@echo off
title Codex - DeepSeek Pro
echo Starting DeepSeek Pro (deepseek-v4-pro)...
echo.
echo Model: dashscope/deepseek-v4-pro
echo.
echo Press any key to start Codex...
pause > nul
codex -c model_provider=dashscope --model deepseek-v4-pro

