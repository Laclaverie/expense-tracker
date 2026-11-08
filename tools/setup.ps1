# Installs what building the desktop app needs, once, then does nothing on later runs:
#   1. Git                                   (winget)
#   2. Visual Studio 2022 Build Tools, C++    (winget; Flutter builds Windows apps with it)
#   3. Windows developer mode                 (symlinks, needed by Flutter plugins)
#   4. Flutter, version in .flutter-version   (cloned into %LOCALAPPDATA%\expense-tracker\flutter,
#                                              added to the user's PATH)
# Steps 2 and 3 ask for administrator rights (a Windows prompt appears).
# With -Android (off by default, for building apps/mobile; build-mobile.bat passes it), also:
#   5. JDK 17 (winget) and the Android SDK in %LOCALAPPDATA%\Android\Sdk: command-line tools, platform-tools,
#      platform 35, build-tools 35.0.0, licenses accepted, `flutter config --android-sdk`. The NDK is fetched
#      by Gradle on the first build.
#
# Usage: setup.bat (double-click), or
#   powershell -ExecutionPolicy Bypass -File tools\setup.ps1 [-DryRun]
#   -DryRun  only says what is missing and what would be installed.
#   -Android also set up what building the Android app needs (step 5).
param([switch]$DryRun, [switch]$Android)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$version = (Get-Content (Join-Path $root '.flutter-version') -Raw).Trim()
$flutterDir = Join-Path $env:LOCALAPPDATA 'expense-tracker\flutter'
$flutterBin = Join-Path $flutterDir 'bin'

function Step($fr, $en) { Write-Host "== $fr / $en" -ForegroundColor Cyan }
function Has($command) { [bool](Get-Command $command -ErrorAction SilentlyContinue) }
function Reload-Path {
  $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
    [Environment]::GetEnvironmentVariable('Path', 'User')
}
function Winget([string[]]$arguments) {
  if (-not (Has winget)) {
    throw "winget est absent : installez « Programme d'installation d'application » depuis le Microsoft Store. / " +
      "winget is missing: install 'App Installer' from the Microsoft Store."
  }
  & winget install -e --source winget --accept-package-agreements --accept-source-agreements @arguments
  if ($LASTEXITCODE -ne 0) { throw "winget install $($arguments[1]) failed ($LASTEXITCODE)" }
}

$missing = @()

# 1. Git ------------------------------------------------------------------------------------------
if (-not (Has git)) {
  $missing += 'Git'
  if (-not $DryRun) {
    Step 'Installation de Git' 'Installing Git'
    Winget @('--id', 'Git.Git', '--silent')
    Reload-Path
  }
}

# 2. Visual Studio Build Tools with the C++ workload ---------------------------------------------
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$hasCpp = (Test-Path $vswhere) -and
  [bool](& $vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath)
if (-not $hasCpp) {
  $missing += 'Visual Studio Build Tools (C++)'
  if (-not $DryRun) {
    Step 'Installation des outils C++ de Visual Studio (10-30 min, plusieurs Go)' `
      'Installing Visual Studio C++ build tools (10-30 min, several GB)'
    Winget @('--id', 'Microsoft.VisualStudio.2022.BuildTools', '--override',
      '--passive --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended')
  }
}

# 3. Developer mode (Flutter plugins are linked with symlinks) ------------------------------------
$devKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
$devMode = (Get-ItemProperty $devKey -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
if ($devMode -ne 1) {
  $missing += 'Windows developer mode'
  if (-not $DryRun) {
    Step 'Activation du mode développeur de Windows' 'Turning on Windows developer mode'
    Start-Process reg.exe -Verb RunAs -Wait -ArgumentList @(
      'add', 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock',
      '/t', 'REG_DWORD', '/f', '/v', 'AllowDevelopmentWithoutDevLicense', '/d', '1')
  }
}

# 4. Flutter ---------------------------------------------------------------------------------------
# Version of a Flutter install from its bin folder (written by its first run), or $null.
function Flutter-Version($bin) {
  $file = Join-Path $bin 'cache\flutter.version.json'
  if (Test-Path $file) { (Get-Content $file -Raw | ConvertFrom-Json).frameworkVersion }
}
$ownFlutter = Test-Path (Join-Path $flutterBin 'flutter.bat')
if ($ownFlutter -and (& git -C $flutterDir describe --tags --exact-match 2>$null) -ne $version) {
  # .flutter-version changed since this copy was installed: move it to the pinned version.
  $missing += "Flutter $version"
  if (-not $DryRun) {
    Step "Mise à jour de Flutter vers $version" "Updating Flutter to $version"
    & git -C $flutterDir fetch --depth 1 origin tag $version
    if ($LASTEXITCODE -ne 0) { throw 'git fetch flutter failed' }
    & git -C $flutterDir checkout --quiet $version
    if ($LASTEXITCODE -ne 0) { throw 'git checkout flutter failed' }
    & (Join-Path $flutterBin 'flutter.bat') precache --windows
  }
} elseif (-not $ownFlutter -and (Has flutter)) {
  # Someone's own Flutter, on PATH: never changed here, only flagged when it isn't the pinned version.
  $other = Flutter-Version (Split-Path (Get-Command flutter).Source)
  if ($other -and $other -ne $version) {
    Write-Warning ("Flutter $other est sur le PATH, le projet utilise $version : la construction peut échouer. / " +
      "Flutter $other is on PATH, the project uses ${version}: building may fail.")
  }
}
if (-not (Has flutter) -and -not $ownFlutter) {
  $missing += "Flutter $version"
  if (-not $DryRun) {
    Step "Téléchargement de Flutter $version (environ 1 Go)" "Downloading Flutter $version (about 1 GB)"
    New-Item -ItemType Directory -Force (Split-Path $flutterDir) | Out-Null
    & git clone --depth 1 --branch $version https://github.com/flutter/flutter.git $flutterDir
    if ($LASTEXITCODE -ne 0) { throw 'git clone flutter failed' }
  }
}
if (-not $DryRun -and -not (Has flutter) -and (Test-Path (Join-Path $flutterBin 'flutter.bat'))) {
  # Persist for terminals and coding agents opened later, and for this run.
  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  if (-not ($userPath -split ';' -contains $flutterBin)) {
    [Environment]::SetEnvironmentVariable('Path', ($userPath.TrimEnd(';') + ';' + $flutterBin), 'User')
  }
  $env:Path = "$flutterBin;$env:Path"
  Step 'Préparation de Flutter (premier lancement)' 'Preparing Flutter (first run)'
  & flutter --disable-analytics | Out-Null
  & flutter config --enable-windows-desktop | Out-Null
  & flutter precache --windows
}

# 5. Android toolchain (only with -Android) --------------------------------------------------------
if ($Android) {
  $sdkDir = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
  $sdkManager = Join-Path $sdkDir 'cmdline-tools\latest\bin\sdkmanager.bat'

  # The JDK home: JAVA_HOME, else the one on PATH, else a Microsoft OpenJDK 17 under Program Files.
  function Find-Jdk {
    if ($env:JAVA_HOME -and (Test-Path (Join-Path $env:JAVA_HOME 'bin\javac.exe'))) { return $env:JAVA_HOME }
    $javac = Get-Command javac -ErrorAction SilentlyContinue
    if ($javac) { return Split-Path (Split-Path $javac.Source -Parent) -Parent }
    $found = Get-ChildItem 'C:\Program Files\Microsoft\jdk-17*\bin\javac.exe' -ErrorAction SilentlyContinue |
      Select-Object -First 1
    if ($found) { return Split-Path (Split-Path $found.FullName -Parent) -Parent }
  }
  $jdk = Find-Jdk
  if (-not $jdk) {
    $missing += 'JDK 17'
    if (-not $DryRun) {
      Step 'Installation de Java (JDK 17)' 'Installing Java (JDK 17)'
      Winget @('--id', 'Microsoft.OpenJDK.17', '--silent')
      Reload-Path
      $jdk = Find-Jdk
    }
  }
  if ($jdk -and -not $DryRun) {
    # sdkmanager and Gradle need java: this process now, later shells through the user's environment.
    $env:JAVA_HOME = $jdk
    $env:Path = "$jdk\bin;$env:Path"
    if ([Environment]::GetEnvironmentVariable('JAVA_HOME', 'User') -ne $jdk) {
      [Environment]::SetEnvironmentVariable('JAVA_HOME', $jdk, 'User')
    }
  }

  if (-not (Test-Path $sdkManager)) {
    $missing += 'Android command-line tools'
    if (-not $DryRun) {
      Step 'Téléchargement des outils Android en ligne de commande' 'Downloading the Android command-line tools'
      $zip = Join-Path ([IO.Path]::GetTempPath()) 'android-cmdline-tools.zip'
      $tmp = Join-Path ([IO.Path]::GetTempPath()) 'android-cmdline-tools'
      Invoke-WebRequest 'https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip' -OutFile $zip
      if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
      Expand-Archive $zip $tmp
      # A partial earlier download would make Move-Item nest the new folder inside it.
      $latest = Join-Path $sdkDir 'cmdline-tools\latest'
      if (Test-Path $latest) { Remove-Item $latest -Recurse -Force }
      # The tools must sit in cmdline-tools\latest\ for sdkmanager to find the SDK root.
      New-Item -ItemType Directory -Force (Join-Path $sdkDir 'cmdline-tools') | Out-Null
      Move-Item (Join-Path $tmp 'cmdline-tools') $latest
      Remove-Item $zip, $tmp -Recurse -Force
    }
  }

  $packages = @('platform-tools', 'platforms;android-35', 'build-tools;35.0.0')
  $absent = $packages | Where-Object { -not (Test-Path (Join-Path $sdkDir ($_ -replace ';', '\'))) }
  if ($absent) { $missing += 'Android SDK packages' }
  if (-not $DryRun -and (Test-Path $sdkManager)) {
    # Licenses first: sdkmanager asks for them before installing and cannot do so unattended otherwise.
    Step 'Licences Android' 'Android licenses'
    1..30 | ForEach-Object { 'y' } | & $sdkManager "--sdk_root=$sdkDir" --licenses | Out-Null
    if ($absent) {
      Step 'Installation du SDK Android (plusieurs Go)' 'Installing the Android SDK (several GB)'
      & $sdkManager "--sdk_root=$sdkDir" @packages
      if ($LASTEXITCODE -ne 0) { throw 'sdkmanager install failed' }
    }
    # Pointing Flutter at the SDK is idempotent. Flutter may not be on PATH yet: use the copy step 4 installed.
    $flutterCmd = if (Has flutter) { 'flutter' } else { Join-Path $flutterBin 'flutter.bat' }
    if (Has $flutterCmd) { & $flutterCmd config --android-sdk $sdkDir | Out-Null }
  }
}

if ($DryRun) {
  if ($missing.Count -eq 0) { Write-Host 'OK: rien à installer / nothing to install' }
  else { Write-Host ('À installer / to install: ' + ($missing -join ', ')) }
  exit 0
}
if ($missing.Count -gt 0) { Step 'Outils prêts' 'Tools ready' }
