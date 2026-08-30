@echo off
setlocal
set "PROJECT_DIR=%~dp0."
set "GODOT_EXE=%PROJECT_DIR%\tools\Godot\Godot_v4.7.2-stable_win64.exe"
set "SCENE=res://scenes/reference/SailingReferenceScene.tscn"

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
"%GODOT_EXE%" --path "%PROJECT_DIR%" --resolution 1152x648 "%SCENE%" -- --sailing-reference
set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
    echo.
    echo Sailing Reference Scene exited with code %EXIT_CODE%.
    pause
)
endlocal
