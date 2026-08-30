@echo off
setlocal
set "PROJECT=%~dp0"
py -3 "%PROJECT%tools\v2fun_asset_pipeline.py"
if errorlevel 1 (
  echo.
  echo V2FUN asset processing failed.
  pause
  exit /b 1
)
echo.
echo V2FUN asset processing finished.
pause
