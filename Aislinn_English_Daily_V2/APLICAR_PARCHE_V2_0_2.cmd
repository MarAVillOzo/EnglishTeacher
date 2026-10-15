@echo off
setlocal
cd /d "%~dp0"
if not exist "app\AislinnEnglish.ps1" (
  echo ERROR: Place this patch in the ROOT of your Aislinn English Daily V2.0/V2.0.1 folder.
  echo It must be next to the app folder.
  pause
  exit /b 1
)
if not exist "patch\AislinnEnglish.ps1" (
  echo ERROR: Patch file missing.
  pause
  exit /b 1
)

powershell.exe -NoProfile -Command "$e=$null;$t=$null;[System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path '.\patch\AislinnEnglish.ps1'),[ref]$t,[ref]$e)|Out-Null;if($e.Count){$e|ForEach-Object{Write-Host $_.Message -ForegroundColor Red};exit 2}else{Write-Host 'PowerShell syntax: OK' -ForegroundColor Green}"
if errorlevel 1 (
  echo Patch NOT applied.
  pause
  exit /b 1
)

if not exist "app\AislinnEnglish.ps1.before_v2_0_2.bak" copy /y "app\AislinnEnglish.ps1" "app\AislinnEnglish.ps1.before_v2_0_2.bak" >nul
copy /y "patch\AislinnEnglish.ps1" "app\AislinnEnglish.ps1" >nul
if errorlevel 1 (
  echo ERROR copying patch.
  pause
  exit /b 1
)
echo.
echo PATCH V2.0.2 APPLIED SUCCESSFULLY.
echo Open Aislinn with 1_EJECUTAR_PORTABLE.cmd and verify the title says V2.0.2.
pause
