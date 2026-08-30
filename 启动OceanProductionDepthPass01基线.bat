@echo off
set "PROJECT=%~dp0"
set "GODOT=%PROJECT%tools\Godot\Godot_v4.7.2-stable_win64.exe"
"%GODOT%" --path "%PROJECT%" --resolution 1152x648 "res://scenes/water/ProductionDepthPass01.tscn" -- --sailing-reference --ocean-depth-baseline
