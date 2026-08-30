@echo off
setlocal
cd /d "%~dp0"
set "PROJECT_DIR=%CD%"
set "SCENE=%PROJECT_DIR%\scenes\staging\port_b_arrival_integration_02\PortBArrivalIntegration02.tscn"
"%PROJECT_DIR%\tools\Godot\Godot_v4.7.2-stable_win64.exe" --path "%PROJECT_DIR%" --resolution 1152x648 --rendering-method gl_compatibility "%SCENE%"
endlocal
