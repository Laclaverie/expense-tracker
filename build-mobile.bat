@echo off
rem Construit l'application Android. Builds the Android app (release APK) as dist\Depenses-android.apk.
rem The first time, installs the Android tools it needs (tools\setup.ps1 -Android: Java, Android SDK, several GB).
rem Copy the apk to the phone and open it (allow installing from this source). Your data is never included.
setlocal
call "%~dp0tools\env.bat" || goto :error
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\setup.ps1" -Android || goto :error
cd /d "%~dp0apps\mobile"

echo == Building release...
rem Full icon font, as for the desktop build.
rem arm64 only: every recent phone; one ABI keeps the APK near 28 MB (three ABIs: 75 MB).
call flutter build apk --release --no-tree-shake-icons --target-platform android-arm64 || goto :error

if not exist "%~dp0dist" mkdir "%~dp0dist"
copy /y "build\app\outputs\flutter-apk\app-release.apk" "%~dp0dist\Depenses-android.apk" >nul || goto :error
echo.
echo Ready: %~dp0dist\Depenses-android.apk
exit /b 0

:error
echo.
echo Build failed (see messages above).
pause
exit /b 1
