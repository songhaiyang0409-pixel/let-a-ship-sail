@echo off
setlocal
pushd "%~dp0"
set "PROJECT_DIR=%CD%"
set "GODOT_EXE=%PROJECT_DIR%\tools\Godot\Godot_v4.7.2-stable_win64.exe"
set "SCENE=res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01/TerraPlayableNorthAtlanticShowcaseSlice01.tscn"
if not exist "%GODOT_EXE%" (
  echo Godot executable not found.
  pause
  popd
  exit /b 1
)
"%GODOT_EXE%" --path "%PROJECT_DIR%" --rendering-method gl_compatibility --resolution 1152x648 "%SCENE%"
popd
endlocal