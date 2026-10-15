@echo off
setlocal
set "OUT=%TEMP%\\AislinnLocalMicSetup_%RANDOM%%RANDOM%.json"
echo Preparing PRIVATE local microphone engine.
echo No administrator rights. No Windows speech packs. No audio setting changes.
"%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0app\\PrepareLocalSpeech.ps1" -Root "%~dp0app" -ResultFile "%OUT%"
if exist "%OUT%" type "%OUT%"
echo.
pause
endlocal
