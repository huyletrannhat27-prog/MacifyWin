@echo off
title MacifyWin Installer
:: Kiem tra quyen Administrator; neu chua co thi tu dong xin quyen
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Dang yeu cau quyen Administrator...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo Bat dau cai dat MacifyWin...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install.ps1"
pause

