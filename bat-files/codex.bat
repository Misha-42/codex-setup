@echo off
chcp 65001 >nul
where wt >nul 2>nul
if %errorlevel%==0 (
  start "" wt pwsh -NoProfile -ExecutionPolicy Bypass -Command "& 'C:\Users\user\codex-ds.ps1'"
  exit /b
)
pwsh -NoProfile -ExecutionPolicy Bypass -Command "& 'C:\Users\user\codex-ds.ps1'"
pause
