# Prints the bin folder of a Flutter install whose version is the one in .flutter-version, or nothing.
# Looks at every Flutter on PATH (not only the first: a machine may have an older one ahead of it), then at
# the project's own copy (%LOCALAPPDATA%\expense-tracker\flutter). Used by tools\env.bat and tools\setup.ps1.

$root = Split-Path $PSScriptRoot -Parent
$version = (Get-Content (Join-Path $root '.flutter-version') -Raw).Trim()

# Version of a Flutter install from its bin folder (written by its first run), or $null.
function Flutter-Version($bin) {
  $file = Join-Path $bin 'cache\flutter.version.json'
  if (Test-Path $file) { (Get-Content $file -Raw | ConvertFrom-Json).frameworkVersion }
}

$bins = @(Get-Command flutter.bat -All -ErrorAction SilentlyContinue | ForEach-Object { Split-Path $_.Source })
$bins += Join-Path $env:LOCALAPPDATA 'expense-tracker\flutter\bin'
foreach ($bin in $bins | Select-Object -Unique) {
  if ((Test-Path (Join-Path $bin 'flutter.bat')) -and (Flutter-Version $bin) -eq $version) {
    $bin
    exit 0
  }
}
