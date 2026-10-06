@echo off
setlocal
where godot >nul 2>nul
if %errorlevel%==0 (
  godot --path "%~dp0"
  exit /b
)
where godot_console >nul 2>nul
if %errorlevel%==0 (
  godot_console --path "%~dp0"
  exit /b
)
echo Godot 4 wurde nicht im PATH gefunden.
echo Oeffne project.godot im Godot Project Manager.
pause
