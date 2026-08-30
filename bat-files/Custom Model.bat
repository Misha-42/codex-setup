@echo off
title Codex - Custom Model
echo Starting Codex with custom model...
echo.
echo Usage: codex.bat --model MODEL_NAME
echo Example: codex.bat --model dashscope/qwen3.8-max
echo.
echo Press any key to start Codex...
pause > nul
"C:\Users\user\AppData\Local\Programs\OpenAI\Codex\bin\codex.exe" --model %MODEL%
