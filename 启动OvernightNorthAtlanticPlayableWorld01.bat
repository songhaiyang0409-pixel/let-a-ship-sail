@echo off
cd /d "%~dp0"
"%~dp0tools\Godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0" --rendering-method gl_compatibility --resolution 1152x648 res://scenes/staging/OvernightPlayableNorthAtlanticWorld01_Fixed.tscn -- --sailing-reference --overnight-playable-north-atlantic-world-01
