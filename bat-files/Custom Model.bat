@echo off
title Codex - Custom Model
echo Starting Custom Model...
echo.
echo Model: %MODEL%
echo.
echo Press any key to start Codex...
pause > nul
"C:\Users\user\AppData\Local\Programs\OpenAI\Codex\bin\codex.exe" --model %MODEL%
