@echo off
rem Used by the .bat files at the repository root (call "%~dp0tools\env.bat").
rem Makes sure the build tools are installed (first use: tools\setup.ps1 installs them),
rem then puts Flutter on PATH for the calling script. Sets ERRORLEVEL 1 on failure.
rem No parentheses inside echo lines of ( ) blocks: cmd would end the block there.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
if errorlevel 1 goto :failed

rem The pinned version first, even when another Flutter comes earlier on PATH.
set "PINNED_FLUTTER="
for /f "usebackq delims=" %%d in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0find-flutter.ps1"`) do set "PINNED_FLUTTER=%%d"
if defined PINNED_FLUTTER goto :pinned

where flutter >nul 2>nul && exit /b 0
if exist "%LOCALAPPDATA%\expense-tracker\flutter\bin\flutter.bat" goto :local
echo Flutter introuvable. / Flutter not found.
exit /b 1

:pinned
set "PATH=%PINNED_FLUTTER%;%PATH%"
exit /b 0

:local
set "PATH=%LOCALAPPDATA%\expense-tracker\flutter\bin;%PATH%"
exit /b 0

:failed
echo.
echo L'installation des outils a echoue, voir ci-dessus. / Installing the tools failed, see above.
exit /b 1
