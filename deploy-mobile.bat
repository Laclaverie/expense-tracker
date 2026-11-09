@echo off
rem Installe l'application Android sur le telephone. Installs the Android app on the phone (adb, USB or Wi-Fi).
rem   deploy-mobile.bat                               build, then install on every connected phone (USB or Wi-Fi)
rem   deploy-mobile.bat 192.168.1.20:41234            adb connect first (wireless debugging), then build + install
rem   deploy-mobile.bat pair 192.168.1.20:37000 123456   pair once (Android 11+: Developer options ->
rem                                                   Wireless debugging -> Pair device with pairing code), then stop
rem   deploy-mobile.bat nobuild [address]             install the existing dist\Depenses-android.apk, no build
rem install -r keeps the phone's data and pairing. The installed app must have been built on this computer.
setlocal
set "APK=%~dp0dist\Depenses-android.apk"
set "PACKAGE=dev.lasagna.expense_mobile"
set "OUT=%TEMP%\deploy-mobile-%RANDOM%.txt"
set "ADB="
set "NOBUILD="
set "ADDRESS="

rem --- adb ---
for /f "delims=" %%p in ('where adb 2^>nul') do if not defined ADB set "ADB=%%p"
if not defined ADB if defined ANDROID_HOME if exist "%ANDROID_HOME%\platform-tools\adb.exe" set "ADB=%ANDROID_HOME%\platform-tools\adb.exe"
if not defined ADB if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not defined ADB (
  echo adb introuvable : lancez build-mobile.bat ^(ou tools\setup.ps1 -Android^) ou installez Android Studio.
  echo adb not found: run build-mobile.bat ^(or tools\setup.ps1 -Android^) or install Android Studio.
  goto :error
)
"%ADB%" start-server >nul 2>&1

rem --- arguments ---
if /i "%~1"=="pair" goto :pair
if /i "%~1"=="nobuild" (
  set "NOBUILD=1"
  set "ADDRESS=%~2"
) else (
  set "ADDRESS=%~1"
)

if defined ADDRESS (
  echo == Connexion / Connecting to %ADDRESS%...
  "%ADB%" connect %ADDRESS% > "%OUT%" 2>&1
  type "%OUT%"
  findstr /b /c:"connected to" /c:"already connected to" "%OUT%" >nul || (
    echo Connexion impossible : le telephone et l'ordinateur sont-ils sur le meme Wi-Fi, le debogage sans fil est-il actif
    echo et l'adresse est-elle celle affichee sous "Debogage sans fil" ^(pas celle de l'appairage^) ?
    echo Could not connect: same Wi-Fi? Wireless debugging on? Use the address shown under "Wireless debugging"
    echo ^(not the pairing one^). First time: deploy-mobile.bat pair ^<address:port^> ^<code^>.
    goto :error
  )
)

rem --- build ---
if not defined NOBUILD (
  call "%~dp0build-mobile.bat" || goto :error
)
if not exist "%APK%" (
  echo APK introuvable / APK not found: %APK%
  echo Lancez / Run deploy-mobile.bat sans / without nobuild.
  goto :error
)

rem --- devices ---
set "COUNT=0"
set "FAILED="
for /f "skip=1 tokens=1,2" %%a in ('call "%ADB%" devices') do call :device "%%a" "%%b"
if "%COUNT%"=="0" (
  echo.
  echo Aucun telephone pret. USB : Options pour les developpeurs -^> Debogage USB, cable branche, autorisez l'ordinateur.
  echo Wi-Fi : Options pour les developpeurs -^> Debogage sans fil, puis deploy-mobile.bat ^<adresse:port^>.
  echo No phone ready. USB: Developer options -^> USB debugging, cable plugged in, allow this computer.
  echo Wi-Fi: Developer options -^> Wireless debugging, then deploy-mobile.bat ^<address:port^>.
  goto :error
)
if defined FAILED goto :error
del "%OUT%" >nul 2>&1
echo.
echo Termine / Done.
exit /b 0

:device
set "SERIAL=%~1"
set "STATE=%~2"
if "%STATE%"=="unauthorized" (
  echo %SERIAL% : deverrouillez le telephone et acceptez "Autoriser le debogage USB".
  echo %SERIAL%: unlock the phone and accept "Allow USB debugging", then run this again.
  exit /b 0
)
if "%STATE%"=="offline" (
  echo %SERIAL% : hors ligne / offline. Rebranchez le cable ou reactivez le debogage / replug or turn debugging off and on.
  exit /b 0
)
if not "%STATE%"=="device" exit /b 0
set /a COUNT+=1
set "MODEL="
for /f "delims=" %%m in ('call "%ADB%" -s %SERIAL% shell getprop ro.product.model') do set "MODEL=%%m"
echo.
echo == Installation / Installing on %MODEL% (%SERIAL%)...
"%ADB%" -s %SERIAL% install -r "%APK%" > "%OUT%" 2>&1
if errorlevel 1 goto :install_failed
findstr /c:"Failure" "%OUT%" >nul && goto :install_failed
"%ADB%" -s %SERIAL% shell monkey -p %PACKAGE% -c android.intent.category.LAUNCHER 1 >nul 2>&1
echo Installe et lance / Installed and started.
exit /b 0

:install_failed
type "%OUT%"
findstr /c:"INSTALL_FAILED_UPDATE_INCOMPATIBLE" "%OUT%" >nul && (
  echo L'application installee a ete construite sur un autre ordinateur : desinstallez-la sur le telephone, puis appairez a nouveau.
  echo The installed app was built on another computer: uninstall it on the phone, then pair again.
)
echo Echec sur / Failed on %MODEL% (%SERIAL%).
set "FAILED=1"
exit /b 0

:pair
if "%~2"=="" goto :pair_usage
if "%~3"=="" goto :pair_usage
echo == Appairage / Pairing with %~2...
"%ADB%" pair %~2 %~3 > "%OUT%" 2>&1
type "%OUT%"
findstr /b /c:"Successfully paired" "%OUT%" >nul || goto :error
del "%OUT%" >nul 2>&1
echo.
echo Appaire. Ensuite : deploy-mobile.bat ^<adresse:port^> ^(celle de "Debogage sans fil"^).
echo Paired. Next: deploy-mobile.bat ^<address:port^> ^(the one under "Wireless debugging"^).
echo Termine / Done.
exit /b 0

:pair_usage
echo Usage: deploy-mobile.bat pair ^<address:port^> ^<code^>
echo   Telephone / Phone: Options pour les developpeurs / Developer options -^> Debogage sans fil / Wireless debugging
echo   -^> Associer avec un code / Pair device with pairing code.
goto :error

:error
if defined OUT del "%OUT%" >nul 2>&1
echo.
echo Echec (voir les messages ci-dessus). Failed (see messages above).
pause
exit /b 1
