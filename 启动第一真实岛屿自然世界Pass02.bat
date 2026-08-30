@echo off
setlocal
cd /d "%~dp0"
"%~dp0tools\Godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0" "res://scenes/visual_slices/FirstRealIslandVisualSlice01.tscn" -- --sailing-reference --natural-only
endlocal
