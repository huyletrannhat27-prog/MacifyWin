@echo off
setlocal
title MacifyWin Installer
cd /d "%~dp0"

set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PS_EXE%" (
    echo [LOI] Khong tim thay Windows PowerShell tai: %PS_EXE%
    pause
    exit /b 1
)

:: Kiem tra quyen Administrator; neu chua co thi tu dong xin quyen
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Dang yeu cau quyen Administrator...
    "%PS_EXE%" -NoProfile -Command "Start-Process -FilePath '%~f0' -WorkingDirectory '%~dp0' -Verb RunAs"
    if %errorlevel% neq 0 (
        echo [LOI] Khong the mo voi quyen Administrator. Hay chuot phai vao install.bat va chon 'Run as administrator'.
        pause
    )
    exit /b
)

if not exist "%~dp0scripts\install.ps1" (
    echo [LOI] Khong tim thay file: %~dp0scripts\install.ps1
    pause
    exit /b 1
)

echo Bat dau cai dat MacifyWin...
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install.ps1"
echo.
pause
