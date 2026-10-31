<#
Drives a desktop app instance started by this script, for visual checks by agents (CLAUDE.md).

  tools\ui-probe.ps1 start -DbDir <scratch folder> [-Width 1400] [-Height 1500] [-Locked]
      Starts the last release build on <DbDir>\expenses.sqlite (the made-up household of packages/demo if missing,
      encrypted with the public demo password, passed as EXPENSES_DB_PASSWORD; -Locked shows the password
      screen instead) and remembers its process in <DbDir>\ui-probe.pid. Refuses the real database folder.
  tools\ui-probe.ps1 click -DbDir <dir> -X <x> -Y <y>
      Left click at client coordinates (the same pixels as in a screenshot).
  tools\ui-probe.ps1 shot -DbDir <dir> -Out <file.png>
      Screenshot of the app's client area (no title bar).
  tools\ui-probe.ps1 stop -DbDir <dir>

Every action only touches the process recorded in <DbDir>: never a window the user opened. Clicks are window
messages (SendMessage), never real mouse moves. Mouse wheel doesn't scroll Flutter: start taller instead
(the screen caps the height). Build first: flutter build windows --release --no-tree-shake-icons in apps\desktop.
#>
param(
  [Parameter(Mandatory, Position = 0)][ValidateSet('start', 'click', 'shot', 'stop')][string]$Action,
  [Parameter(Mandatory)][string]$DbDir,
  [int]$X, [int]$Y, [string]$Out,
  [int]$Width = 1400, [int]$Height = 1500,
  # start: show the password screen instead of opening with the demo password.
  [switch]$Locked
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$DbDir = [IO.Path]::GetFullPath($DbDir)
$pidFile = Join-Path $DbDir 'ui-probe.pid'

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class UiProbe {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr after, string cls, string title);
  [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
  public struct RECT { public int Left, Top, Right, Bottom; }
  public struct POINT { public int X, Y; }
}
"@
[UiProbe]::SetProcessDPIAware() | Out-Null

function Get-Probed {
  if (-not (Test-Path $pidFile)) { throw "No instance started by ui-probe in $DbDir (run: start)." }
  $p = Get-Process -Id ([int](Get-Content $pidFile)) -ErrorAction SilentlyContinue
  if (-not $p -or $p.ProcessName -ne 'expense_desktop') { Remove-Item $pidFile; throw 'The probed instance is gone.' }
  $top = $p.MainWindowHandle
  $view = [UiProbe]::FindWindowEx($top, [IntPtr]::Zero, 'FLUTTERVIEW', [NullString]::Value)
  if ($view -eq [IntPtr]::Zero) { throw 'Flutter view not found (window not ready yet?).' }
  return @{ Process = $p; Top = $top; View = $view }
}

switch ($Action) {
  'start' {
    $real = Join-Path $env:APPDATA 'dev.lasagna'
    if ($DbDir.StartsWith($real, [StringComparison]::OrdinalIgnoreCase)) { throw "Refused: $DbDir is the real database folder." }
    $exe = Join-Path $root 'apps\desktop\build\windows\x64\runner\Release\expense_desktop.exe'
    if (-not (Test-Path $exe)) { throw "No release build: $exe" }
    New-Item -ItemType Directory -Force $DbDir | Out-Null
    $db = Join-Path $DbDir 'expenses.sqlite'
    if (-not (Test-Path $db)) {
      Push-Location (Join-Path $root 'packages\demo')
      try { dart run demo:database $db | Select-Object -Last 1 } finally { Pop-Location }
    }
    $env:EXPENSES_DB_DIR = $DbDir
    # The public demo password (packages/demo/bin/database.dart): scratch databases only.
    if ($Locked) { Remove-Item Env:EXPENSES_DB_PASSWORD -ErrorAction SilentlyContinue }
    elseif (-not $env:EXPENSES_DB_PASSWORD) { $env:EXPENSES_DB_PASSWORD = 'demo database password' }
    $p = Start-Process $exe -PassThru
    Set-Content $pidFile $p.Id
    for ($i = 0; $i -lt 50 -and (Get-Process -Id $p.Id).MainWindowHandle -eq [IntPtr]::Zero; $i++) { Start-Sleep -Milliseconds 200 }
    $w = Get-Probed
    [UiProbe]::SetWindowPos($w.Top, [IntPtr]::Zero, 0, 0, $Width, $Height, 0x0004) | Out-Null
    Start-Sleep -Seconds 2
    $r = New-Object UiProbe+RECT
    [UiProbe]::GetClientRect($w.View, [ref]$r) | Out-Null
    "Started process $($p.Id) on $db; client area $($r.Right) x $($r.Bottom)"
  }
  'click' {
    $w = Get-Probed
    $l = [IntPtr](($Y -shl 16) -bor ($X -band 0xFFFF))
    # Flutter needs the pointer to enter before a press counts.
    [UiProbe]::SendMessage($w.View, 0x0200, [IntPtr]0, $l) | Out-Null  # WM_MOUSEMOVE
    Start-Sleep -Milliseconds 50
    [UiProbe]::SendMessage($w.View, 0x0201, [IntPtr]1, $l) | Out-Null  # WM_LBUTTONDOWN
    Start-Sleep -Milliseconds 50
    [UiProbe]::SendMessage($w.View, 0x0202, [IntPtr]0, $l) | Out-Null  # WM_LBUTTONUP
    Start-Sleep -Milliseconds 800
  }
  'shot' {
    if (-not $Out) { throw 'shot needs -Out <file.png>' }
    $w = Get-Probed
    $wr = New-Object UiProbe+RECT
    [UiProbe]::GetWindowRect($w.Top, [ref]$wr) | Out-Null
    $bmp = New-Object System.Drawing.Bitmap ($wr.Right - $wr.Left), ($wr.Bottom - $wr.Top)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $dc = $g.GetHdc()
    [UiProbe]::PrintWindow($w.Top, $dc, 2) | Out-Null  # PW_RENDERFULLCONTENT
    $g.ReleaseHdc($dc)
    # Crop to the Flutter view so screenshot pixels are click coordinates.
    $origin = New-Object UiProbe+POINT
    [UiProbe]::ClientToScreen($w.View, [ref]$origin) | Out-Null
    $cr = New-Object UiProbe+RECT
    [UiProbe]::GetClientRect($w.View, [ref]$cr) | Out-Null
    $area = New-Object System.Drawing.Rectangle ($origin.X - $wr.Left), ($origin.Y - $wr.Top), $cr.Right, $cr.Bottom
    $bmp.Clone($area, $bmp.PixelFormat).Save([IO.Path]::GetFullPath($Out))
    "Saved $Out ($($cr.Right) x $($cr.Bottom))"
  }
  'stop' {
    $w = Get-Probed
    Stop-Process -Id $w.Process.Id
    Remove-Item $pidFile
    "Stopped process $($w.Process.Id)"
  }
}
