@echo off
rem Starts the app on made-up data, the same every time (docs\13-demo.md).
rem   demo.bat              the couple
rem   demo.bat freelancer   the freelancer
rem Builds a fresh demo database in %LOCALAPPDATA%\expense-tracker\demo\<persona> (never your own
rem database), opens that folder (the card exports to drop on the Import page) and starts the app on it.
setlocal
set "EXE=%~dp0apps\desktop\build\windows\x64\runner\Release\expense_desktop.exe"
set "PERSONA=%~1"
if "%PERSONA%"=="" set "PERSONA=couple"

rem Only known personas: the name becomes a folder that is deleted below.
if /i not "%PERSONA%"=="couple" if /i not "%PERSONA%"=="freelancer" (
  echo Persona inconnu / Unknown persona: %PERSONA%  -  couple, freelancer
  exit /b 64
)

rem A running app would stay on screen with your own data: the demo needs its own window.
rem Windows' own find: Git's find, first on some PATHs, fails and the check would let the demo start.
tasklist /nh /fi "imagename eq expense_desktop.exe" | "%SystemRoot%\System32\find.exe" /i "expense_desktop.exe" >nul && (
  echo Fermez l'application d'abord : la demo ouvre sa propre fenetre.
  echo Close the app first: the demo opens its own copy.
  exit /b 1
)

if not exist "%EXE%" (
  echo Lancez build-desktop.bat une premiere fois. / Run build-desktop.bat once first.
  exit /b 1
)

call "%~dp0tools\env.bat" || exit /b 1

set "DIR=%LOCALAPPDATA%\expense-tracker\demo\%PERSONA%"
if exist "%DIR%" rmdir /s /q "%DIR%"
mkdir "%DIR%" || exit /b 1

pushd "%~dp0packages\demo"
call dart run demo:showcase "%DIR%" --persona %PERSONA%
set "RESULT=%ERRORLEVEL%"
popd
if not "%RESULT%"=="0" exit /b %RESULT%

start "" explorer "%DIR%"
set "EXPENSES_DB_DIR=%DIR%"
set "EXPENSES_DB_PASSWORD=demo database password"
set "EXPENSES_TODAY=2026-10-24"
start "" "%EXE%"
exit /b 0
