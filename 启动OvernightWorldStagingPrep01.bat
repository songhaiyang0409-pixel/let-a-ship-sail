@echo off
setlocal
set "PROJECT_DIR=%~dp0."
set "GODOT_EXE=%PROJECT_DIR%\tools\Godot\Godot_v4.7.2-stable_win64.exe"
set "SCENE=res://scenes/staging/OvernightWorldStagingPrep01.tscn"

if not exist "%GODOT_EXE%" (
    echo Godot executable was not found:
    echo %GODOT_EXE%
    pause
    exit /b 1
)

cd /d "%PROJECT_DIR%"
"%GODOT_EXE%" --path "%PROJECT_DIR%" --resolution 1152x648 "%SCENE%" -- --sailing-reference --overnight-world-staging-01
set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
    echo.
    echo Overnight staging exited with code %EXIT_CODE%.
    pause
)
endlocal
