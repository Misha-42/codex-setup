@echo off
title Codex - Qwen Image Max
echo Starting Qwen Image Max (DashScope)...
echo.
echo Model: dashscope/qwen-image-max
echo.
echo Press any key to start Codex...
pause > nul
codex -c model_provider=dashscope --model qwen-image-max

