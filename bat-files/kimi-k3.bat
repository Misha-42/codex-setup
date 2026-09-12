@echo off
title Codex - Kimi K3
echo Starting Kimi K3 (DashScope)...
echo.
echo Model: dashscope/kimi-k3
echo.
echo Press any key to start Codex...
pause > nul
codex -c model_provider=dashscope --model kimi-k3

