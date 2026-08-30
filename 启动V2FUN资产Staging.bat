@echo off
cd /d "%~dp0"
"%~dp0tools\Godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0" res://scenes/staging/OvernightWorldStagingPrep01_V2FUN.tscn --v2fun-staging
pause

