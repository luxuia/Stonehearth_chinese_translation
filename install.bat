@echo off
rem ============================================================
rem  Stonehearth Simplified Chinese patch installer
rem  Runs tools\install.ps1, which does the actual work.
rem
rem  Usage:  install.bat "<path to Stonehearth folder>"
rem          install.bat          (asks for the folder)
rem ============================================================
setlocal
set "SCRIPT_DIR=%~dp0"

rem Locate Windows PowerShell 5+.
set "PS="
for %%P in (
    "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
    "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
) do if not defined PS if exist %%P set "PS=%%~P"
if not defined PS for %%P in (powershell.exe) do if not defined PS if exist "%%~$PATH:P" set "PS=%%~$PATH:P"

if not defined PS (
    echo [x] PowerShell not found. Windows PowerShell 5 or newer is required.
    pause
    exit /b 1
)

chcp 65001 >nul 2>&1
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%tools\install.ps1" %*
if errorlevel 1 (
    echo.
    echo [x] Installation failed. See the messages above.
    pause
    exit /b 1
)

echo.
pause
exit /b 0
