@echo off
setlocal
cd /d "%~dp0"
start "Port-to-Port V02" "%~dp0tools\Godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0" "res://scenes/water/overnight_v02/PortToPortSlice02.tscn"
endlocal
