@echo off
rem Verifie tout (format, analyse, tests) comme le fera GitHub sur une demande de fusion.
rem Runs every check a pull request must pass (format, analysis, tests).
setlocal
call "%~dp0tools\env.bat" || goto :end
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\test-all.ps1"
:end
pause
