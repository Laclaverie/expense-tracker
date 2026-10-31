@echo off
rem Construit l'application et la lance. Builds the desktop app (release) and starts it.
rem The first time, installs the tools it needs (tools\setup.ps1). To start without building: run-desktop.bat
rem   build-desktop.bat        build + run
rem   build-desktop.bat clean  clean build first (fixes stale icons / build cache)
setlocal
call "%~dp0tools\env.bat" || goto :error
cd /d "%~dp0apps\desktop"

if /i "%~1"=="clean" (
  echo == flutter clean
  call flutter clean || goto :error
)

rem A running copy locks the exe: ask it to close first (data is saved continuously).
tasklist /fi "imagename eq expense_desktop.exe" | find /i "expense_desktop.exe" >nul && (
  echo == Closing the running app...
  taskkill /im expense_desktop.exe >nul 2>nul
  timeout /t 3 /nobreak >nul
)

echo == Building release...
rem Full icon font: incremental builds can drop newly used icons when tree-shaking.
call flutter build windows --release --no-tree-shake-icons || goto :error

echo == Starting app
start "" "build\windows\x64\runner\Release\expense_desktop.exe"
exit /b 0

:error
echo.
echo Build failed (see messages above).
pause
exit /b 1
