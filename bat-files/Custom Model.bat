@echo off
title Codex - Custom Model
echo.
echo Available providers:
echo   dashscope/ - DashScope (246 models)
echo   kktoken/ - KKToken (Claude models)
echo   tooken/ - Tooken Club (Claude/GPT models)
echo.
echo Examples:
echo   dashscope/qwen3.8-max
echo   kktoken/claude-opus-5
echo   tooken/gpt-5.6-sol
echo.
set /p MODEL="Enter model (e.g. dashscope/qwen3.8-max): "
if "%MODEL%"=="" goto menu
echo.
echo Starting Codex with %MODEL%...
start cmd /k "C:\Users\user\AppData\Local\Programs\OpenAI\Codex\bin\codex.exe" --model %MODEL%
goto menu

:menu
pause
