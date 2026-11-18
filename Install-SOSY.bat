@echo off
title SOSY 1.0 Installer

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-SOSY.ps1"

if errorlevel 1 (
    echo.
    echo The SOSY installer encountered an error.
    pause
)
