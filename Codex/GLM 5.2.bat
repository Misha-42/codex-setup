@echo off
title Codex - GLM 5.2
echo Starting ZHIPU GLM-5.2 (DashScope)...
echo.
echo Model: ZHIPU/GLM-5.2
echo.

echo Press any key to start Codex...
pause > nul

"C:\Program Files\PowerShell\7\pwsh.exe" -NoExit -Command "codex --model ZHIPU/GLM-5.2"
