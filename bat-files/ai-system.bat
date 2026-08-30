@echo off
chcp 65001 >nul
title DashScope Intelligent System

:menu
cls
echo.
echo  ╔════════════════════════════════════════════════════════════╗
echo  ║           DASHSCOPE INTELLIGENT SYSTEM                     ║
echo  ╠════════════════════════════════════════════════════════════╣
echo  ║  [1] Codex (smart mode)                                    ║
echo  ║  [2] Dashboard                                             ║
echo  ║  [3] Quick task                                            ║
echo  ║  [4] System status                                         ║
echo  ║  [5] Optimize (reset quotas)                               ║
echo  ║  [6] Auto-mode (fully automatic)                           ║
echo  ║  [0] Exit                                                  ║
echo  ╚════════════════════════════════════════════════════════════╝
echo.
set /p choice="Select: "

if "%choice%"=="1" goto codex
if "%choice%"=="2" goto dashboard
if "%choice%"=="3" goto quicktask
if "%choice%"=="4" goto status
if "%choice%"=="5" goto optimize
if "%choice%"=="6" goto auto
if "%choice%"=="0" exit
goto menu

:codex
echo.
echo Starting Codex with intelligent model selection...
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\codex-ds.ps1"
pause
goto menu

:dashboard
echo.
echo Starting dashboard...
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\dashboard.ps1"
pause
goto menu

:quicktask
echo.
set /p task="Enter task: "
if "%task%"=="" goto menu
echo.
echo Running: %task%
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\codex-ds.ps1" "%task%"
pause
goto menu

:status
echo.
echo System status...
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\codex-ds.ps1" -Status
pause
goto menu

:optimize
echo.
echo Optimizing system (reset quotas)...
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\codex-ds.ps1" -Reset
pause
goto menu

:auto
echo.
echo Starting fully automatic mode...
echo The system will:
echo   1. Detect best model automatically
echo   2. Rotate when quota exhausted
echo   3. Protect expensive models
echo   4. Track usage and optimize
echo.
echo Press any key to start auto-mode (Ctrl+C to cancel)
pause >nul
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\codex-ds.ps1"
pause
goto menu
