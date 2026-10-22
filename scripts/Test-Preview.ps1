<#
.SYNOPSIS
  Drives the live preview host (src\IDE\Preview) with UI Automation.

.DESCRIPTION
  Builds RADWinUIPreview (unless -NoBuild) and checks both modes on a
  secondary monitor without taking the focus:
  - file watch: Profile's window XAML renders (DataContextType, bindings and a
    converter registered at run time), a broken edit keeps the last good view
    and shows the error with its line, a fixed edit renders again;
  - pipe: Counter's window XAML (x:Class, a Click attribute) is sent over the
    pipe, broken XAML is answered with ERROR and the line, fixed XAML with OK,
    and the host exits with code 0 when the client disconnects;
  - the IDE client (RADWinUI.Preview.Client): starts the host, restarts it
    after a crash or a hang, stops when the user closes it, ends it when freed;
    large and malformed XAML, memory over 300 edits, and -Cycles cycles.
  Design-time values (d:Text and the like) must show in the preview and be
  absent from a sample's generated unit. Exit code 0 when every check passes.

.EXAMPLE
  .\scripts\Test-Preview.ps1
  .\scripts\Test-Preview.ps1 -Config Release -Cycles 100
  .\scripts\Test-Preview.ps1 -Dcc64 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\dcc64.exe'
#>
[CmdletBinding()]
param(
  [ValidateSet('Debug', 'Release')]
  [string]$Config = 'Debug',
  # Start/edit/close cycles of the client test (use 100 for a long run)
  [int]$Cycles = 1,
  # Full path of dcc64.exe when registry lookup is unavailable or selects the wrong version
  [string]$Dcc64,
  [switch]$NoBuild
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes, System.Core
$env:RADWINUI_TEST_MONITOR = 'secondary'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$AE = [Windows.Automation.AutomationElement]
$Scope = [Windows.Automation.TreeScope]::Descendants
$Exe = Join-Path $RepoRoot "src\IDE\Preview\Win64\$Config\RADWinUIPreview.exe"
$Work = Join-Path $RepoRoot 'build\preview-test'

if (-not $NoBuild) {
  & (Join-Path $PSScriptRoot 'Build.ps1') -Project 'src\IDE\Preview\RADWinUIPreview.dpr' -Config $Config -Dcc64 $Dcc64 | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'Building RADWinUIPreview failed' }
}
New-Item -ItemType Directory -Force $Work | Out-Null

function Wait-For([scriptblock]$Probe, [string]$What) {
  $Deadline = (Get-Date).AddSeconds(15)
  while ((Get-Date) -lt $Deadline) {
    $R = & $Probe
    if ($R) { return $R }
    Start-Sleep -Milliseconds 200
  }
  throw "Timed out waiting for $What"
}
function Find-Id($Win, [string]$Id) {
  $Win.FindFirst($Scope, (New-Object Windows.Automation.PropertyCondition($AE::AutomationIdProperty, $Id)))
}
function Get-Window($Proc) {
  Wait-For { $AE::RootElement.FindFirst([Windows.Automation.TreeScope]::Children, (New-Object Windows.Automation.AndCondition(
    (New-Object Windows.Automation.PropertyCondition($AE::ProcessIdProperty, $Proc.Id)),
    (New-Object Windows.Automation.PropertyCondition($AE::ClassNameProperty, 'WinUIDesktopWin32WindowClass'))))) } 'the preview window'
}
function Ok([string]$What) { Write-Host "  [ok] $What" }

$Good = Get-Content (Join-Path $RepoRoot 'samples\Profile\ProfileWindow.xaml') -Raw
# Line 7 of ProfileWindow.xaml is <StackPanel ...>, an unclosed attribute value breaks it
$Broken = $Good -replace '<StackPanel Spacing="12"', '<StackPanel Spacing="12'
$Fixed = $Good -replace '<TextBox x:Name="NameBox"', '<TextBlock x:Name="AddedText" Text="added"/><TextBox x:Name="NameBox"'

Write-Host 'Preview: file watch'
$File = Join-Path $Work 'ProfileWindow.xaml'
[IO.File]::WriteAllText($File, $Good)
$Proc = Start-Process $Exe -ArgumentList "`"$File`"" -PassThru
$null = $Proc.Handle
try {
  $Win = Get-Window $Proc
  $null = Wait-For { Find-Id $Win 'NameBox' } 'NameBox'
  if (Find-Id $Win 'PreviewError') { throw "error shown for good XAML: $((Find-Id $Win 'PreviewError').Current.Name)" }
  Ok 'renders the window XAML (DataContextType, bindings, run-time converter)'
  # Design-time values: d: values win, other bound text shows its path
  $Name = (Find-Id $Win 'NameBox').GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern).Current.Value
  $Vip = (Find-Id $Win 'VipBox').GetCurrentPattern([Windows.Automation.TogglePattern]::Pattern).Current.ToggleState
  $Greeting = (Find-Id $Win 'Greeting').Current.Name
  $Summary = (Find-Id $Win 'Summary').Current.Name
  if ($Name -ne 'Ada Lovelace' -or "$Vip" -ne 'On' -or $Greeting -ne 'Hello, Ada Lovelace!' -or $Summary -ne '{Summary}') {
    throw "design-time values: NameBox '$Name', VipBox $Vip, Greeting '$Greeting', Summary '$Summary'"
  }
  Ok "design-time values show (NameBox '$Name', VipBox $Vip, Greeting '$Greeting'), Summary shows '$Summary'"
  [IO.File]::WriteAllText($File, $Broken)
  $Err = Wait-For { Find-Id $Win 'PreviewError' } 'the error bar'
  if ($Err.Current.Name -notmatch 'Line: ?\d+') { throw "the error has no line: $($Err.Current.Name)" }
  if (-not (Find-Id $Win 'NameBox')) { throw 'the last good view is gone' }
  Ok "broken XAML keeps the last good view and shows: $($Err.Current.Name)"
  [IO.File]::WriteAllText($File, $Fixed)
  $null = Wait-For { Find-Id $Win 'AddedText' } 'the fixed view'
  $null = Wait-For { -not (Find-Id $Win 'PreviewError') } 'the error bar to go'
  Ok 'fixed XAML renders and the error bar goes'
  $Win.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern).Close()
  if (-not $Proc.WaitForExit(15000) -or $Proc.ExitCode -ne 0) { throw 'the preview did not exit cleanly' }
  Ok 'closes with exit code 0'
} finally {
  if (-not $Proc.HasExited) { $Proc.Kill() }
}

Write-Host 'Preview: pipe'
$Counter = Get-Content (Join-Path $RepoRoot 'samples\Counter\MainWindow.xaml') -Raw
$Pipe = "RADWinUIPreviewTest-$PID"
$Proc = Start-Process $Exe -ArgumentList '--pipe', $Pipe -PassThru
$null = $Proc.Handle
$Client = New-Object IO.Pipes.NamedPipeClientStream('.', $Pipe, [IO.Pipes.PipeDirection]::InOut)
try {
  $Client.Connect(15000)
  $Client.ReadMode = [IO.Pipes.PipeTransmissionMode]::Message
  function Send([string]$Path, [string]$Xaml) { Request "LOAD $Path`n$Xaml" }
  function Request([string]$Text) {
    $Bytes = [Text.Encoding]::UTF8.GetBytes($Text)
    $Client.Write($Bytes, 0, $Bytes.Length)
    $Buffer = New-Object byte[] 65536
    $Reply = ''
    do {
      $N = $Client.Read($Buffer, 0, $Buffer.Length)
      $Reply += [Text.Encoding]::UTF8.GetString($Buffer, 0, $N)
    } until ($Client.IsMessageComplete)
    $Reply
  }
  $R = Send 'C:\Demo\MainWindow.xaml' $Counter
  if ($R -ne 'OK') { throw "LOAD answered: $R" }
  $Win = Get-Window $Proc
  $null = Wait-For { Find-Id $Win 'IncrementButton' } 'IncrementButton'
  Ok 'LOAD renders the XAML and answers OK'
  $R = Send 'C:\Demo\MainWindow.xaml' ($Counter -replace '</StackPanel>', '</StackPanl>')
  if ($R -notmatch '^ERROR MainWindow\.xaml: .*Line: ?10') { throw "broken XAML answered: $R" }
  if (-not (Find-Id $Win 'IncrementButton')) { throw 'the last good view is gone' }
  Ok "broken XAML answers $R"
  $R = Send 'C:\Demo\MainWindow.xaml' ($Counter -replace 'Content="Reset"', 'x:Name="ResetButton" Content="Reset"')
  if ($R -ne 'OK') { throw "fixed XAML answered: $R" }
  $null = Wait-For { Find-Id $Win 'ResetButton' } 'ResetButton'
  $null = Wait-For { -not (Find-Id $Win 'PreviewError') } 'the error bar to go'
  Ok 'fixed XAML answers OK and renders'
  $Client.Dispose()
  if (-not $Proc.WaitForExit(15000) -or $Proc.ExitCode -ne 0) { throw 'the host did not exit cleanly when the client disconnected' }
  Ok 'the host exits with code 0 when the client disconnects'
} finally {
  $Client.Dispose()
  if (-not $Proc.HasExited) { $Proc.Kill() }
}
Write-Host 'Designer: selection and property edit'
if (-not $NoBuild) {
  & (Join-Path $PSScriptRoot 'Build.ps1') -Project 'tests\Designer\XamlEditTest.dpr' -Dcc64 $Dcc64 | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'Building XamlEditTest failed' }
}
$XamlEdit = Join-Path $RepoRoot 'tests\Designer\Win64\Debug\XamlEditTest.exe'
& $XamlEdit
if ($LASTEXITCODE -ne 0) { throw 'XamlEditTest failed' }
if (-not $NoBuild) {
  & (Join-Path $PSScriptRoot 'Build.ps1') -Project 'tests\Designer\DesignerModelTest.dpr' -Dcc64 $Dcc64 | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'Building DesignerModelTest failed' }
}
& (Join-Path $RepoRoot 'tests\Designer\Win64\Debug\DesignerModelTest.exe') $RepoRoot
if ($LASTEXITCODE -ne 0) { throw 'DesignerModelTest failed' }
# UI Automation rectangles in physical pixels, as HIT expects
Add-Type -Namespace RADWinUITest -Name Dpi -MemberDefinition ('[DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr c);' +
  '[DllImport("user32.dll")] public static extern uint GetDpiForWindow(IntPtr h);')
$null = [RADWinUITest.Dpi]::SetThreadDpiAwarenessContext([IntPtr]-4)
$Edited = Join-Path $Work 'MainWindow.xaml'
[IO.File]::WriteAllText($Edited, $Counter)
$Proc = Start-Process $Exe -ArgumentList '--pipe', "$Pipe-d" -PassThru
$null = $Proc.Handle
$Client = New-Object IO.Pipes.NamedPipeClientStream('.', "$Pipe-d", [IO.Pipes.PipeDirection]::InOut)
$EventClient = New-Object IO.Pipes.NamedPipeClientStream('.', "$Pipe-d-events", [IO.Pipes.PipeDirection]::InOut)
try {
  $Client.Connect(15000)
  $Client.ReadMode = [IO.Pipes.PipeTransmissionMode]::Message
  $EventClient.Connect(15000)
  $EventClient.ReadMode = [IO.Pipes.PipeTransmissionMode]::Message
  if ((Send $Edited $Counter) -ne 'OK') { throw 'LOAD failed' }
  function Read-Event {
    $Buffer = New-Object byte[] 65536
    $Reply = ''
    do {
      $Read = $EventClient.ReadAsync($Buffer, 0, $Buffer.Length)
      if (-not $Read.Wait(5000)) { throw 'timed out waiting for a pushed event' }
      $N = $Read.Result
      $Reply += [Text.Encoding]::UTF8.GetString($Buffer, 0, $N)
    } until ($EventClient.IsMessageComplete)
    $Reply
  }
  function Hit-At([int]$X, [int]$Y) {
    $Reply = Request "HIT $X $Y"
    $Pushed = Read-Event
    if ($Pushed -ne $Reply) { throw "HIT replied $Reply but pushed $Pushed" }
    $Reply
  }
  $Win = Get-Window $Proc
  function Hit($Element) {
    $R = $Element.Current.BoundingRectangle
    Hit-At ([int]($R.X + $R.Width / 2)) ([int]($R.Y + $R.Height / 2))
  }
  $Button = Wait-For { Find-Id $Win 'IncrementButton' } 'IncrementButton'
  $R = Hit $Button
  if ($R -ne 'SELECTED 8 9 Button IncrementButton') { throw "HIT on IncrementButton answered: $R" }
  $Status = (Find-Id $Win 'PreviewSelection').Current.Name
  if ($Status -ne 'Button IncrementButton  (line 8, column 9)') { throw "selection status: $Status" }
  Ok "a hit selects the element and names its start tag: $R"
  $Reset = Wait-For { $Win.FindFirst($Scope, (New-Object Windows.Automation.PropertyCondition($AE::NameProperty, 'Reset'))) } 'Reset'
  $R = Hit $Reset
  if ($R -ne 'SELECTED 9 9 Button -') { throw "HIT on the unnamed Reset button answered: $R" }
  Ok "an element without x:Name is found by its position: $R"
  $R = Hit $Button
  & $XamlEdit set $Edited 8 9 Content Plus
  $Text = [IO.File]::ReadAllText($Edited)
  if ($Text -notmatch '<Button x:Name="IncrementButton" Content="Plus"/>') { throw "the edit changed more than the attribute: $Text" }
  if ((Send $Edited $Text) -ne 'OK') { throw 'LOAD of the edited XAML failed' }
  $null = Wait-For { $Win.FindFirst($Scope, (New-Object Windows.Automation.PropertyCondition($AE::NameProperty, 'Plus'))) } 'the button showing Plus'
  $Status = (Find-Id $Win 'PreviewSelection').Current.Name
  if ($Status -ne 'Button IncrementButton  (line 8, column 9)') { throw "selection after the edit: $Status" }
  Ok 'a property edit changes one attribute, re-renders, and the selection stays'
  if ((Request 'NOPE') -notlike 'ERROR unknown request*') { throw 'an unknown request did not answer ERROR' }
  Ok 'an unknown request answers ERROR and the host keeps running'

  # Toolbox, drag and delete: the host reports, XamlEditTest applies like the IDE does
  function Apply([string]$Event) {
    & $XamlEdit apply $Edited $Event
    if ($LASTEXITCODE -ne 0) { throw "applying $Event failed" }
    $T = [IO.File]::ReadAllText($Edited)
    if ((Send $Edited $T) -ne 'OK') { throw "LOAD after $Event failed" }
    $T
  }
  function Find-Type($Type, [string]$Name) {
    $Cond = New-Object Windows.Automation.AndCondition(
      (New-Object Windows.Automation.PropertyCondition($AE::ControlTypeProperty, [Windows.Automation.ControlType]::$Type)),
      (New-Object Windows.Automation.PropertyCondition($AE::NameProperty, $Name)))
    $Win.FindFirst($Scope, $Cond)
  }
  if ((Request 'TOOL CheckBox') -ne 'OK') { throw 'TOOL did not answer OK' }
  if ((Request 'TOOL') -ne 'OK' -or (Request 'TOOL CheckBox') -ne 'OK') { throw 'resetting and reselecting a palette tool failed' }
  $R = (Wait-For { Find-Id $Win 'IncrementButton' } 'IncrementButton').Current.BoundingRectangle
  $Event = Hit-At ([int]($R.X + $R.Width / 2)) ([int]($R.Y + $R.Height - 3))
  if ($Event -ne 'INSERT CheckBox 6 5 2 -1 -1') { throw "placing a CheckBox below IncrementButton answered: $Event" }
  $Text = Apply $Event
  $Box = Wait-For { Find-Type CheckBox 'CheckBox' } 'the inserted CheckBox'
  $ResetY = (Wait-For { Find-Type Button 'Reset' } 'Reset').Current.BoundingRectangle.Y
  if (-not ($Box.Current.BoundingRectangle.Y -gt $R.Y -and $Box.Current.BoundingRectangle.Y -lt $ResetY)) { throw 'the CheckBox is not between Plus and Reset' }
  if ($Text -notmatch '(?m)^        <Button x:Name="IncrementButton" Content="Plus"/>\r?\n        <CheckBox Content="CheckBox" x:Name="CheckBox1"/>\r?\n        <Button Content="Reset"') { throw "insert layout: $Text" }
  Ok "toolbox: $Event puts the CheckBox on its own line between Plus and Reset"

  $Reset = Find-Type Button 'Reset'
  $Top = (Find-Id $Win 'CounterText').Current.BoundingRectangle
  $RR = $Reset.Current.BoundingRectangle
  $Event = Request "DRAG $([int]($RR.X + $RR.Width / 2)) $([int]($RR.Y + $RR.Height / 2)) $([int]($Top.X + 5)) $([int]($Top.Y + 3))"
  $Pushed = Read-Event
  if ($Pushed -ne $Event) { throw "DRAG replied $Event but pushed $Pushed" }
  if ($Event -ne 'MOVE 10 9 6 5 0 -1 -1') { throw "dragging Reset to the top answered: $Event" }
  $null = Apply $Event
  $null = Wait-For { $RB = Find-Type Button 'Reset'; $RB -and $RB.Current.BoundingRectangle.Y -lt (Find-Id $Win 'CounterText').Current.BoundingRectangle.Y } 'Reset above CounterText'
  Ok "drag: $Event moves Reset to the top of the StackPanel"

  $B = (Find-Type CheckBox 'CheckBox').Current.BoundingRectangle
  $null = Hit-At ([int]($B.X + 10)) ([int]($B.Y + $B.Height / 2))
  $Event = Request 'TOOL Delete'
  $Pushed = Read-Event
  if ($Pushed -ne $Event) { throw "TOOL Delete replied $Event but pushed $Pushed" }
  if ($Event -notmatch '^DELETE \d+ 9$') { throw "Delete answered: $Event" }
  $Text = Apply $Event
  $null = Wait-For { -not (Find-Type CheckBox 'CheckBox') } 'the CheckBox to go'
  if ($Text -match 'CheckBox') { throw 'the CheckBox is still in the XAML' }
  Ok "delete: $Event removes the selected CheckBox with its line"

  $Grid = "<Grid xmlns=`"http://schemas.microsoft.com/winfx/2006/xaml/presentation`" xmlns:x=`"http://schemas.microsoft.com/winfx/2006/xaml`">`n" +
    "    <Grid.RowDefinitions><RowDefinition Height=`"60`"/><RowDefinition Height=`"60`"/></Grid.RowDefinitions>`n" +
    "    <Grid.ColumnDefinitions><ColumnDefinition Width=`"150`"/><ColumnDefinition Width=`"150`"/></Grid.ColumnDefinitions>`n" +
    "    <TextBlock Text=`"Cell`" Width=`"150`" Height=`"60`"/>`n</Grid>"
  [IO.File]::WriteAllText($Edited, $Grid)
  if ((Send $Edited $Grid) -ne 'OK') { throw 'LOAD of the Grid failed' }
  $C = (Wait-For { $Cell = Find-Type Text 'Cell'; if ($Cell -and $Cell.Current.BoundingRectangle.Width -gt 0) { $Cell } } 'the Cell text').Current.BoundingRectangle
  $null = Request 'TOOL Button'
  $Event = Hit-At ([int]($C.X + $C.Width + 12)) ([int]($C.Y + $C.Height + 12))
  # 12 physical pixels past the cell corner, answered in DIPs: 12 at 100 %, 9 or 10 at 125 % (plus rect rounding)
  $Want = 12 * 96 / [RADWinUITest.Dpi]::GetDpiForWindow([IntPtr]$Win.Current.NativeWindowHandle)
  if ($Event -notmatch '^INSERTAT Button 1 1 Grid 1 1 (\d+) (\d+)$' -or
    [Math]::Abs([int]$Matches[1] - $Want) -gt 1.5 -or [Math]::Abs([int]$Matches[2] - $Want) -gt 1.5) {
    throw "placing a Button in row 1, column 1 answered: $Event (expected offsets near $Want)"
  }
  $Text = Apply $Event
  if ($Text -notmatch '<Button Content="Button" x:Name="Button1" Grid.Row="1" Grid.Column="1" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="\d+,\d+,0,0"/>') { throw "Grid insert: $Text" }
  # Not the toolbox's own Button button (AutomationId Tool_Button)
  $NB = (Wait-For { $Win.FindAll($Scope, (New-Object Windows.Automation.PropertyCondition($AE::NameProperty, 'Button'))) |
    Where-Object { $_.Current.ControlType -eq [Windows.Automation.ControlType]::Button -and $_.Current.AutomationId -ne 'Tool_Button' } |
    Select-Object -First 1 } 'the new Button').Current.BoundingRectangle
  if ($NB.X -lt $C.X + $C.Width -or $NB.Y -lt $C.Y + $C.Height) { throw 'the Button is not in row 1, column 1' }
  Ok "toolbox in a Grid: $Event lands in row 1, column 1, where it was dropped"
  # Free placement: dragging in a Grid writes Margin, the outline follows
  $Event = Request "DRAG $([int]($NB.X + 5)) $([int]($NB.Y + 5)) $([int]($NB.X + 5 + $C.Width * 0.2)) $([int]($NB.Y + 5 + $C.Height * 0.25))"
  $Pushed = Read-Event
  if ($Pushed -ne $Event) { throw "DRAG replied $Event but pushed $Pushed" }
  if ($Event -notmatch '^PLACE 5 5 1 1 Grid 1 1 (\d+) (\d+)$' -or [int]$Matches[1] -lt 35 -or [int]$Matches[1] -gt 45 -or [int]$Matches[2] -lt 20 -or [int]$Matches[2] -gt 30) {
    throw "dragging the Button by 30, 15 DIPs answered: $Event"
  }
  $Text = Apply $Event
  if ($Text -notmatch "Margin=`"$($Matches[1]),$($Matches[2]),0,0`"") { throw "free move: $Text" }
  $Moved = (Wait-For { $Win.FindAll($Scope, (New-Object Windows.Automation.PropertyCondition($AE::NameProperty, 'Button'))) |
    Where-Object { $_.Current.AutomationId -ne 'ToolText_Button' } | Select-Object -First 1 } 'the moved Button').Current.BoundingRectangle
  if ([Math]::Abs(($Moved.X - $NB.X) - $C.Width * 0.2) -gt 6) { throw "the Button moved $($Moved.X - $NB.X) px, not $($C.Width * 0.2)" }
  Ok "free move in a Grid: $Event writes the new Margin and the Button follows"
  if ((Request 'TOOL AutoSuggestBox') -ne 'OK') { throw 'a generated palette control was not accepted' }
  $Event = Hit-At ([int]($C.X + 20)) ([int]($C.Y + 20))
  if ($Event -notmatch '^INSERTAT AutoSuggestBox ') { throw "generated palette control answered: $Event" }
  $Text = Apply $Event
  if ($Text -notmatch '<AutoSuggestBox\b') { throw 'the generated palette control was not inserted' }
  Ok 'generated palette control inserts and its XAML renders'
  # Every Tool Palette control, as the palette inserts it, loads in the preview
  $PaletteXaml = Join-Path $Work 'Palette.xaml'
  & $XamlEdit palette-xaml $PaletteXaml
  $R = Send $PaletteXaml ([IO.File]::ReadAllText($PaletteXaml))
  if ($R -ne 'OK') { throw "the Tool Palette controls do not all load: $R" }
  Ok 'every Tool Palette control loads in the preview as inserted'
  $Client.Dispose()
  if (-not $Proc.WaitForExit(15000) -or $Proc.ExitCode -ne 0) { throw 'the host did not exit cleanly' }
} finally {
  $Client.Dispose()
  $EventClient.Dispose()
  if (-not $Proc.HasExited) { $Proc.Kill() }
}

Write-Host 'Preview: IDE client (tests\Preview\PreviewClientTest)'
if (-not $NoBuild) {
  & (Join-Path $PSScriptRoot 'Build.ps1') -Project 'tests\Preview\PreviewClientTest.dpr' -Dcc64 $Dcc64 | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'Building PreviewClientTest failed' }
}
& (Join-Path $RepoRoot 'tests\Preview\Win64\Debug\PreviewClientTest.exe') $Exe (Join-Path $RepoRoot 'samples\Counter\MainWindow.xaml') $Cycles
if ($LASTEXITCODE -ne 0) { throw 'PreviewClientTest failed' }
Write-Host 'Preview: native design-time sample collections'
if (-not $NoBuild) {
  & (Join-Path $PSScriptRoot 'Build.ps1') -Project 'tests\Preview\PreviewDataTest.dpr' -Config $Config -Dcc64 $Dcc64 | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'Building PreviewDataTest failed' }
}
$DataLog = Join-Path $Work 'PreviewDataTest.log'
$SavedRoot = $env:RADWINUI_ROOT
$DataProcess = $null
try {
  $env:RADWINUI_ROOT = $RepoRoot
  $DataProcess = Start-Process -FilePath (Join-Path $RepoRoot "tests\Preview\Win64\$Config\PreviewDataTest.exe") `
    -WindowStyle Hidden -RedirectStandardOutput $DataLog -RedirectStandardError (Join-Path $Work 'PreviewDataTest.err') -PassThru
  $null = $DataProcess.Handle # without it ExitCode stays empty after the process ends
  if (-not $DataProcess.WaitForExit(15000)) { throw 'PreviewDataTest exceeded 15 seconds' }
  $DataOutput = Get-Content $DataLog -Raw
  Write-Host $DataOutput
  if (($DataProcess.ExitCode -ne 0) -or -not $DataOutput.Contains('Preview data test PASSED')) {
    throw 'PreviewDataTest failed'
  }
} finally {
  if ($DataProcess -and -not $DataProcess.HasExited) { $DataProcess.Kill() }
  if ($DataProcess) { $DataProcess.Dispose() }
  $env:RADWINUI_ROOT = $SavedRoot
}
Write-Host 'Preview: app builds ignore design-time values'
& (Join-Path $PSScriptRoot 'Build.ps1') -Project 'samples\Profile\Profile.dpr' -Config $Config -Dcc64 $Dcc64 | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Building Profile failed' }
$Generated = Get-Content (Join-Path $RepoRoot 'samples\Profile\ProfileWindow.Xaml.pas') -Raw
if ($Generated -match 'Ada Lovelace|d:Text|Ignorable') { throw 'ProfileWindow.Xaml.pas still has design-time values' }
Ok 'Profile builds, its generated unit has no d: values (run Test-Samples.ps1 -Only Profile, Contacts for the app itself)'
Write-Host 'XamlCodeGen'
if (-not $NoBuild) {
  & (Join-Path $PSScriptRoot 'Build.ps1') -Project 'tests\XamlCodeGen\XamlCodeGenTest.dpr' -Dcc64 $Dcc64 | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'Building XamlCodeGenTest failed' }
}
& (Join-Path $RepoRoot 'tests\XamlCodeGen\Win64\Debug\XamlCodeGenTest.exe') $RepoRoot | Select-Object -Last 1
if ($LASTEXITCODE -ne 0) { throw 'XamlCodeGenTest failed (tests\XamlCodeGen)' }
Write-Host 'Preview test PASSED'
