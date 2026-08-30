@echo off
setlocal
set "PROJECT_DIR=%~dp0."
set "GODOT_EXE=%PROJECT_DIR%\tools\Godot\Godot_v4.7.2-stable_win64.exe"
set "SCENE=res://scenes/water/overnight_v03/PortToPortSlice03.tscn"

if not exist "%GODOT_EXE%" (
    echo Godot executable was not found:
    echo %GODOT_EXE%
    pause
    exit /b 1
)
if not exist "%PROJECT_DIR%\project.godot" (
    echo project.godot was not found:
    echo %PROJECT_DIR%\project.godot
    pause
    exit /b 1
)

cd /d "%PROJECT_DIR%"
"%GODOT_EXE%" --path "%PROJECT_DIR%" "%SCENE%"
set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
    echo.
    echo Port-to-Port V03 exited with code %EXIT_CODE%.
    pause
)
endlocal
