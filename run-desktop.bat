@echo off
rem Starts the last built desktop app (no build). To rebuild first: build-desktop.bat
setlocal
set "EXE=%~dp0apps\desktop\build\windows\x64\runner\Release\expense_desktop.exe"

tasklist /fi "imagename eq expense_desktop.exe" | find /i "expense_desktop.exe" >nul && (
  echo The app is already running.
  timeout /t 2 /nobreak >nul
  exit /b 0
)

rem Never built on this computer: build it (and install the tools the first time).
if not exist "%EXE%" (
  call "%~dp0build-desktop.bat"
  exit /b
)

start "" "%EXE%"
exit /b 0
