@echo off
setlocal
cd /d "%~dp0"
if /I "%~1"=="install" goto install
if /I "%~1"=="redis" goto redis
if /I "%~1"=="db" (
    echo H2 starts inside Java automatically. Run: setup.cmd run
    exit /b 0
)
if /I "%~1"=="run" goto run
if "%~1"=="" goto check
if /I "%~1"=="check" goto check
echo Use setup.cmd [run [port]^|check^|db^|install^|redis].
exit /b 1
:run
if "%~2"=="" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup-windows.ps1" -Run
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup-windows.ps1" -Run -Port "%~2"
)
exit /b %ERRORLEVEL%
:check
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup-windows.ps1" -CheckLessons
exit /b %ERRORLEVEL%
:install
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup-windows.ps1"
exit /b %ERRORLEVEL%
:redis
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup-windows.ps1" -Redis
exit /b %ERRORLEVEL%
