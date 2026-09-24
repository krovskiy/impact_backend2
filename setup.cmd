@echo off
setlocal
if /I "%~1"=="db" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup-windows.ps1" -Database
) else if /I "%~1"=="check" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup-windows.ps1" -CheckLessons
) else if /I "%~1"=="run" (
    if "%~2"=="" (
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup-windows.ps1" -Run
    ) else (
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup-windows.ps1" -Run -Port "%~2"
    )
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup-windows.ps1"
)
set "result=%ERRORLEVEL%"
pause
exit /b %result%
