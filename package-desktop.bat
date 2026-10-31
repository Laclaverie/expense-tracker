@echo off
rem Builds the desktop app and packages it as dist\Depenses-windows.zip to share.
rem The zip holds the program only: your data (in %APPDATA%) is never included.
setlocal
call "%~dp0tools\env.bat" || goto :error
cd /d "%~dp0"

echo == Building release...
pushd apps\desktop
call flutter build windows --release --no-tree-shake-icons || (popd & goto :error)
popd

set "OUT=%~dp0dist\Depenses"
if exist "%~dp0dist" rmdir /s /q "%~dp0dist"
mkdir "%OUT%"
robocopy "apps\desktop\build\windows\x64\runner\Release" "%OUT%" /e /njh /njs /ndl /nfl >nul
if errorlevel 8 goto :error

rem Visual C++ runtime next to the exe, for PCs without it (app-local deployment).
for %%f in (msvcp140.dll vcruntime140.dll vcruntime140_1.dll) do (
  if exist "%SystemRoot%\System32\%%f" copy /y "%SystemRoot%\System32\%%f" "%OUT%" >nul
)
copy /y "apps\desktop\packaging\LISEZMOI.txt" "%OUT%" >nul

echo == Zipping...
powershell -NoProfile -Command "Compress-Archive -Path '%OUT%' -DestinationPath '%~dp0dist\Depenses-windows.zip' -Force" || goto :error
echo.
echo Ready to share: %~dp0dist\Depenses-windows.zip
exit /b 0

:error
echo.
echo Packaging failed (see messages above).
pause
exit /b 1