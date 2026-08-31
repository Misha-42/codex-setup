@echo off
REM Helper script to find Codex CLI executable
REM Sets CODEX variable with the path to codex.exe

set "CODEX="

REM Check WindowsApps
for /d %%i in ("C:\Program Files\WindowsApps\OpenAI.Codex*") do (
    if exist "%%i\app\resources\codex.exe" (
        set "CODEX=%%i\app\resources\codex.exe"
        exit /b 0
    )
)

REM Check old path
set "CODEX_PATH=C:\Users\user\AppData\Local\Programs\OpenAI\Codex\bin\codex.exe"
if exist "%CODEX_PATH%" (
    set "CODEX=%CODEX_PATH%"
    exit /b 0
)

REM Check system PATH
where codex >nul 2>&1
if not errorlevel 1 (
    set "CODEX=codex"
    exit /b 0
)

REM Not found
exit /b 1
