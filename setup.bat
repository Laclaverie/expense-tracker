@echo off
rem Installe une fois les outils pour construire l'application (Git, outils C++ de Visual Studio,
rem mode developpeur, Flutter). Sans effet s'ils sont deja la. build-desktop.bat le fait aussi tout seul.
rem Installs, once, the tools to build the app. Does nothing if they are there.
setlocal
echo Installation des outils (la premiere fois : 20 a 60 min, Windows demandera une autorisation).
echo Installing the tools (first time: 20 to 60 min, Windows will ask for permission).
echo.
call "%~dp0tools\env.bat" || goto :error
echo.
echo Pret. Double-cliquez sur build-desktop.bat pour construire et lancer l'application.
echo Ready. Double-click build-desktop.bat to build and start the app.
pause
exit /b 0

:error
pause
exit /b 1
