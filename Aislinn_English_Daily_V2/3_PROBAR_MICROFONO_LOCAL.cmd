@echo off
setlocal
set "OUT=%TEMP%\\AislinnMicTest_%RANDOM%%RANDOM%.json"
set "CANCEL=%TEMP%\\AislinnMicCancel_%RANDOM%%RANDOM%.flag"
echo Speak one complete sentence in English, then pause.
echo This test changes NO Windows setting.
"%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0app\\LocalWhisperCapture.ps1" -Root "%~dp0app" -OutputFile "%OUT%" -CancelFile "%CANCEL%" -TimeoutSeconds 14
echo.
if exist "%OUT%" type "%OUT%"
echo.
pause
del /q "%OUT%" 2>nul
del /q "%CANCEL%" 2>nul
endlocal
