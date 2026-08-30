@echo off
set "PROJECT_DIR=E:\让一艘船航行"
set "GODOT_EXE=%PROJECT_DIR%\tools\Godot\Godot_v4.7.2-stable_win64.exe"
start "First Real Island Visual Slice 01" "%GODOT_EXE%" --path "%PROJECT_DIR%" "res://scenes/visual_slices/FirstRealIslandVisualSlice01.tscn" -- --sailing-reference --first-real-island-slice
