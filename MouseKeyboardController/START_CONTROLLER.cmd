@echo off
setlocal
cd /d "%~dp0"
title Mouse + Keyboard Controller
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0MouseKeyboardController.ps1"
if errorlevel 1 (
 echo.
 echo The controller could not start. Extract the ZIP before running it.
 pause
)
endlocal
