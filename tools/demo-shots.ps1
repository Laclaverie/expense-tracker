# Renders the demo walkthrough (docs\13-demo.md) as PNGs from a widget test: the couple's made-up
# data, no window opened. Look at every image before committing it.
#
# Usage: powershell -ExecutionPolicy Bypass -File tools\demo-shots.ps1 [-Out <folder>] [-Locale en|fr]
#   -Out     default docs\images
#   -Locale  default en (the README's language)
param(
  [string]$Out = (Join-Path (Split-Path $PSScriptRoot -Parent) 'docs\images'),
  [ValidateSet('en', 'fr')][string]$Locale = 'en'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
New-Item -ItemType Directory -Force $Out | Out-Null
$env:DEMO_SHOTS_OUT = (Resolve-Path $Out).Path
$env:DEMO_SHOTS_LOCALE = $Locale
Push-Location (Join-Path $root 'apps\desktop')
try {
  flutter test test/demo_shots_test.dart
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
  Pop-Location
  Remove-Item Env:DEMO_SHOTS_OUT, Env:DEMO_SHOTS_LOCALE -ErrorAction SilentlyContinue
}
Write-Host "Images: $Out"
