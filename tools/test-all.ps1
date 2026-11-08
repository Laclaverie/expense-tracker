# Runs every check a pull request must pass: formatting, analysis and tests of every package and of the
# desktop app. Used by test-all.bat (double-click) and by GitHub Actions (.github/workflows/ci.yml).
# Exit code 0 = everything passed.
#
# Usage: powershell -ExecutionPolicy Bypass -File tools\test-all.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$failed = @()

function Check([string]$name, [string]$dir, [scriptblock]$command) {
  Write-Host "== $name" -ForegroundColor Cyan
  Push-Location (Join-Path $root $dir)
  try {
    & $command
    if ($LASTEXITCODE -ne 0) { $script:failed += $name }
  } finally {
    Pop-Location
  }
}

Check 'pub get' '.' { dart pub get }
Check 'format' '.' { dart format --set-exit-if-changed -l 120 --output=none packages apps/desktop/lib apps/desktop/test apps/mobile/lib apps/mobile/test }
foreach ($package in 'core', 'pdf_words', 'banks', 'storage', 'demo') {
  Check "$package analyze" "packages/$package" { dart analyze --fatal-infos }
  Check "$package test" "packages/$package" { dart test }
}
Check 'desktop analyze' 'apps/desktop' { flutter analyze --fatal-infos }
Check 'desktop test' 'apps/desktop' { flutter test }
Check 'mobile analyze' 'apps/mobile' { flutter analyze --fatal-infos }
Check 'mobile test' 'apps/mobile' { flutter test }

if ($failed.Count -gt 0) {
  Write-Host ('FAILED: ' + ($failed -join ', ')) -ForegroundColor Red
  exit 1
}
Write-Host 'All checks passed.' -ForegroundColor Green
