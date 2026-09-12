@echo off
title Codex - Qwen Max Longcontext
echo Starting Qwen Max Longcontext (DashScope)...
echo.
echo Model: dashscope/qwen-max-longcontext
echo.
echo Press any key to start Codex...
pause > nul
codex -c model_provider=dashscope --model qwen-max-longcontext

