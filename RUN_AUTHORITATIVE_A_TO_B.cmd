@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\run_authoritative_a_to_b.ps1"
if errorlevel 1 (
  echo.
  echo Launch failed safely. No destructive reset was performed.
  pause
  exit /b 1
)
endlocal
