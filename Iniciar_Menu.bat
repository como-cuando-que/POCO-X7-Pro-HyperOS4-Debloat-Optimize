@echo off
title HyperOS 4 EEA + EVONIX 4.6.1 - Menu Interactivo (POCO X7 Pro)
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\00_menu_hos4_eea_evonix.ps1"
if errorlevel 1 (
    echo.
    echo Ocurrio un error al ejecutar el menu.
    pause
)
