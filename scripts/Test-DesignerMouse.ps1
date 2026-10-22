<#
.SYNOPSIS
  Drives the designer with the real mouse: select, toolbox click and drag, element drag.

.DESCRIPTION
  MOVES THE MOUSE AND CLICKS. Run it only when nobody uses the PC. The
  preview host opens on a secondary monitor, the script presses and drags
  with SendInput-style mouse events, then reads what the host
  reports (POLL) and checks it:
  - a click selects, reported on release;
  - toolbox click, then a click in empty space at the end of a StackPanel;
  - dragging a toolbox item into an empty horizontal StackPanel;
  - dragging a toolbox item into row 1, column 1 of a Grid without background;
  - dragging an element above another one, with the drop mark visible
    mid-drag (a screenshot is saved to build\logs\designer-drag.png).
  Exit code 0 when every check passes.

.EXAMPLE
  .\scripts\Test-DesignerMouse.ps1
#>
[CmdletBinding()]
param([string]$Config = 'Release')

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes, System.Core, System.Drawing
Add-Type -Namespace RADWinUITest -Name Mouse -MemberDefinition @'
[DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr c);
[DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
[DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, IntPtr e);
'@
$null = [RADWinUITest.Mouse]::SetThreadDpiAwarenessContext([IntPtr]-4)
$env:RADWINUI_TEST_MONITOR = 'secondary'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$AE = [Windows.Automation.AutomationElement]
$Scope = [Windows.Automation.TreeScope]::Descendants
$Exe = Join-Path $RepoRoot "src\IDE\Preview\Win64\$Config\RADWinUIPreview.exe"
$Failures = 0
function Check([bool]$Ok, [string]$What) {
  if ($Ok) { Write-Host "  [ok] $What" } else { Write-Host "  [failed] $What" -ForegroundColor Red; $script:Failures++ }
}

$Xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        x:Class="TMainWindow" Title="Mouse" Width="480" Height="420">
    <StackPanel Spacing="16" Padding="32">
        <TextBlock x:Name="CounterText" Text="0" FontSize="32"/>
        <Button x:Name="IncrementButton" Content="Increment"/>
        <StackPanel x:Name="Inner" Orientation="Horizontal" Spacing="8" MinHeight="40"/>
        <Grid x:Name="Cells" Height="80">
            <Grid.RowDefinitions><RowDefinition/><RowDefinition/></Grid.RowDefinitions>
            <Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions>
        </Grid>
    </StackPanel>
</Window>
'@

$Pipe = "RADWinUIMouse-$PID"
$Proc = Start-Process $Exe -ArgumentList '--pipe', $Pipe -PassThru
$Client = New-Object IO.Pipes.NamedPipeClientStream('.', $Pipe, [IO.Pipes.PipeDirection]::InOut)
function Request([string]$Text) {
  $B = [Text.Encoding]::UTF8.GetBytes($Text); $Client.Write($B, 0, $B.Length)
  $Buf = New-Object byte[] 65536; $R = ''
  do { $N = $Client.Read($Buf, 0, $Buf.Length); $R += [Text.Encoding]::UTF8.GetString($Buf, 0, $N) } until ($Client.IsMessageComplete)
  $R
}
function Events { $All = @(); while (($E = Request 'POLL') -ne 'NONE') { $All += $E }; $All -join ' | ' }
function Id([string]$Id) { $Win.FindFirst($Scope, (New-Object Windows.Automation.PropertyCondition($AE::AutomationIdProperty, $Id))) }
function Rect([string]$Id) { (Id $Id).Current.BoundingRectangle }
function MoveTo($X, $Y) { [void][RADWinUITest.Mouse]::SetCursorPos([int]$X, [int]$Y); Start-Sleep -Milliseconds 25 }
function Press { [RADWinUITest.Mouse]::mouse_event(2, 0, 0, 0, [IntPtr]::Zero); Start-Sleep -Milliseconds 60 }
function Release { [RADWinUITest.Mouse]::mouse_event(4, 0, 0, 0, [IntPtr]::Zero); Start-Sleep -Milliseconds 300 }
function Click($X, $Y) { MoveTo $X $Y; Start-Sleep -Milliseconds 100; Press; Release }
function Drag($X1, $Y1, $X2, $Y2, [string]$Shot) {
  MoveTo $X1 $Y1; Start-Sleep -Milliseconds 100; Press
  foreach ($I in 1..15) { MoveTo ($X1 + ($X2 - $X1) * $I / 15) ($Y1 + ($Y2 - $Y1) * $I / 15) }
  Start-Sleep -Milliseconds 200
  if ($Shot) {
    $W = $Win.Current.BoundingRectangle
    $Bmp = New-Object Drawing.Bitmap ([int]$W.Width), ([int]$W.Height)
    $G = [Drawing.Graphics]::FromImage($Bmp); $G.CopyFromScreen([int]$W.X, [int]$W.Y, 0, 0, $Bmp.Size)
    $Bmp.Save($Shot); $G.Dispose(); $Bmp.Dispose()
  }
  Release
}

try {
  $Client.Connect(15000); $Client.ReadMode = [IO.Pipes.PipeTransmissionMode]::Message
  if ((Request "LOAD C:\Mouse\MainWindow.xaml`n$Xaml") -ne 'OK') { throw 'LOAD failed' }
  $Deadline = (Get-Date).AddSeconds(15)
  do { Start-Sleep -Milliseconds 200; $Win = $AE::RootElement.FindFirst([Windows.Automation.TreeScope]::Children,
      (New-Object Windows.Automation.PropertyCondition($AE::ProcessIdProperty, $Proc.Id))) } until ($Win -or (Get-Date) -gt $Deadline)
  Start-Sleep -Milliseconds 800
  Write-Host 'Designer with the real mouse'

  $B = Rect 'IncrementButton'
  Click ($B.X + $B.Width / 2) ($B.Y + $B.Height / 2)
  $E = Events
  Check ($E -eq 'SELECTED 6 9 Button IncrementButton') "click selects, reported on release: $E"

  $T = Rect 'ToolText_CheckBox'
  Click ($T.X + $T.Width / 2) ($T.Y + $T.Height / 2)
  $Grid = Rect 'PreviewSelection'   # status line, just below the content
  $C = (Id 'CounterText').Current.BoundingRectangle
  Click ($C.X + 40) ($Grid.Y - 30)
  $E = Events
  Check ($E -eq 'INSERT CheckBox 4 5 4 -1 -1') "toolbox click, then a click in empty space at the end of the StackPanel: $E"

  $T = Rect 'ToolText_TextBox'
  $Inner = (Id 'IncrementButton').Current.BoundingRectangle
  Drag ($T.X + $T.Width / 2) ($T.Y + $T.Height / 2) ($Inner.X + 30) ($Inner.Y + $Inner.Height + 16 + 20) ''
  $E = Events
  Check ($E -eq 'INSERT TextBox 7 9 0 -1 -1') "toolbox drag into the empty horizontal StackPanel: $E"

  $T = Rect 'ToolText_Button'
  $Cells = $Inner.Y + $Inner.Height + 16 + 40 + 16   # Grid top: below the button, the 40 px StackPanel and the spacing
  Drag ($T.X + $T.Width / 2) ($T.Y + $T.Height / 2) ($C.X + $C.Width * 0.75) ($Cells + 60) ''
  $E = Events
  Check ($E -match '^INSERTAT Button 8 9 Grid 1 1 \d+ \d+$') "toolbox drag into row 1, column 1 of a Grid without background: $E"

  $Shot = Join-Path $RepoRoot 'build\logs\designer-drag.png'
  $B = Rect 'IncrementButton'
  Click ($B.X + $B.Width / 2) ($B.Y + $B.Height / 2)
  $null = Events
  Drag ($B.X + $B.Width / 2) ($B.Y + $B.Height / 2) ($C.X + 20) ($C.Y + 4) $Shot
  $E = Events
  Check ($E -eq 'SELECTED 6 9 Button IncrementButton | MOVE 6 9 4 5 0 -1 -1' -or $E -eq 'MOVE 6 9 4 5 0 -1 -1') "drag moves the button above CounterText: $E"
  Write-Host "  drop mark mid-drag: $Shot"
} finally {
  $Client.Dispose()
  Start-Sleep -Milliseconds 500
  if (-not $Proc.HasExited) { $Proc.Kill() }
}
if ($Failures -gt 0) { Write-Host "Designer mouse test FAILED ($Failures)"; exit 1 }
Write-Host 'Designer mouse test PASSED'
