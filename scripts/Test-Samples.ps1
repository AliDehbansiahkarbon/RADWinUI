<#
.SYNOPSIS
  Drives the samples (Counter, Greeter, ListDemo, Contacts, Profile) with UI Automation.

.DESCRIPTION
  Starts each sample from samples\<Name>\Win64\<Config>, performs its
  scenario, checks the visible result, closes the window and checks the
  process exits with code 0 within 15 seconds (a leak report or an error
  dialog would keep it open). Build the samples first with scripts\Build.ps1.
  Exit code 0 when every scenario passes.

.EXAMPLE
  .\scripts\Test-Samples.ps1 -Config Release
#>
[CmdletBinding()]
param(
  [string]$Config = 'Debug',
  # Run only these samples (for example -Only Counter), all when empty
  [string[]]$Only = @()
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
# Test windows open on a secondary monitor without taking the focus (TWinUIWindow.Show),
# the test drives them only through UI Automation patterns, which need no focus.
$env:RADWINUI_TEST_MONITOR = 'secondary'
$RepoRoot = Split-Path -Parent $PSScriptRoot
# Full output of every run, for failures that do not reproduce
$LogFile = Join-Path $RepoRoot "build\logs\Test-Samples-$Config.log"
New-Item -ItemType Directory -Force (Split-Path $LogFile) | Out-Null
Start-Transcript -Path $LogFile -Force | Out-Null
$AE = [Windows.Automation.AutomationElement]
$Scope = [Windows.Automation.TreeScope]::Descendants
$Started = Get-Date

function Wait-For([scriptblock]$Probe, [string]$What) {
  $Deadline = (Get-Date).AddSeconds(15)
  while ((Get-Date) -lt $Deadline) {
    $R = & $Probe
    if ($R) { return $R }
    Start-Sleep -Milliseconds 200
  }
  throw "Timed out waiting for $What"
}

function Find-By($Root, $Property, [string]$Value) {
  $Root.FindFirst($Scope, (New-Object Windows.Automation.PropertyCondition($Property, $Value)))
}

function Get-Id($Win, [string]$Id) { Wait-For { Find-By $Win $AE::AutomationIdProperty $Id } "element '$Id'" }
function Get-Named($Win, [string]$Name) { Wait-For { Find-By $Win $AE::NameProperty $Name } "element named '$Name'" }
function Invoke-Named($Win, [string]$Name) {
  # Name alone can match the button's inner TextBlock first, ask for the button itself
  $Cond = New-Object Windows.Automation.AndCondition(
    (New-Object Windows.Automation.PropertyCondition($AE::NameProperty, $Name)),
    (New-Object Windows.Automation.PropertyCondition($AE::ControlTypeProperty, [Windows.Automation.ControlType]::Button)))
  $Btn = Wait-For { $Win.FindFirst($Scope, $Cond) } "button '$Name'"
  $Btn.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern).Invoke()
}
function Set-Text($Element, [string]$Text) {
  $Pattern = $Element.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern)
  $Pattern.SetValue($Text)
  # Check at once: a different value here means input from outside the test reached the window
  $Actual = $Pattern.Current.Value
  if ($Actual -ne $Text) {
    throw "set '$($Element.Current.AutomationId)' to '$Text' but it holds '$Actual' (input from outside the test?)"
  }
}
function Expect-Name($Win, [string]$Id, [string]$Expected) {
  try {
    $null = Wait-For { (Get-Id $Win $Id).Current.Name -eq $Expected } "$Id = '$Expected'"
  } catch {
    $Actual = try { "'" + (Find-By $Win $AE::AutomationIdProperty $Id).Current.Name + "'" } catch { "unreadable: $_" }
    throw "$_ (actual: $Actual)"
  }
  Write-Host "  [ok] $Id = '$Expected'"
}

function Expect-Value($Win, [string]$Id, [string]$Expected) {
  try {
    $null = Wait-For { (Get-Id $Win $Id).GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern).Current.Value -eq $Expected } "$Id value '$Expected'"
  } catch {
    $Actual = try { "'" + (Find-By $Win $AE::AutomationIdProperty $Id).GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern).Current.Value + "'" } catch { "unreadable: $_" }
    throw "$_ (actual: $Actual)"
  }
  Write-Host "  [ok] $Id value = '$Expected'"
}

function Test-Sample([string]$Name, [scriptblock]$Scenario) {
  if ($Only -and $Name -notin $Only) { return $true }
  Write-Host $Name
  $Exe = Join-Path $RepoRoot "samples\$Name\Win64\$Config\$Name.exe"
  $Proc = Start-Process $Exe -PassThru
  $null = $Proc.Handle # keeps ExitCode readable after exit
  $Win = $null
  $Cond = New-Object Windows.Automation.PropertyCondition($AE::ProcessIdProperty, $Proc.Id)
  try {
    # The WinUI window itself: other top-level elements of the process have no WindowPattern
    $WinCond = New-Object Windows.Automation.AndCondition($Cond,
      (New-Object Windows.Automation.PropertyCondition($AE::ClassNameProperty, 'WinUIDesktopWin32WindowClass')))
    $Win = Wait-For { $AE::RootElement.FindFirst([Windows.Automation.TreeScope]::Children, $WinCond) } "the $Name window"
    & $Scenario $Win
    $Win.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern).Close()
    if (-not $Proc.WaitForExit(15000)) { throw "$Name did not exit after its window closed" }
    if ($Proc.ExitCode -ne 0) { throw "$Name exited with code $($Proc.ExitCode)" }
    Write-Host "  [ok] closed, exit code 0"
    return $true
  } catch {
    Write-Host "  [failed] $Name ($Config): $($_.Exception.GetType().FullName): $_"
    Write-Host ($_.ScriptStackTrace -replace '(?m)^', '    ')
    # Which top-level elements the process has, and which one the test took as its window
    try {
      foreach ($El in $AE::RootElement.FindAll([Windows.Automation.TreeScope]::Children, $Cond)) {
        $Mark = if ($Win -and [Windows.Automation.Automation]::Compare($El, $Win)) { '*' } else { ' ' }
        Write-Host ("    {0} top-level {1} class '{2}' name '{3}' hwnd {4} window pattern {5}" -f $Mark,
          $El.Current.ControlType.ProgrammaticName, $El.Current.ClassName, $El.Current.Name,
          $El.Current.NativeWindowHandle, [bool]($El.GetSupportedPatterns() -contains [Windows.Automation.WindowPattern]::Pattern))
      }
    } catch { Write-Host "    (could not list the process windows: $_)" }
    return $false
  } finally {
    if (-not $Proc.HasExited) { $Proc.Kill() }
  }
}

$Results = @(
  Test-Sample 'Counter' {
    param($Win)
    1..3 | ForEach-Object { Invoke-Named $Win 'Increment' }
    Expect-Name $Win 'CounterText' '3'
    Invoke-Named $Win 'Reset'
    Expect-Name $Win 'CounterText' '0'
  }
  Test-Sample 'Greeter' {
    param($Win)
    Invoke-Named $Win 'Greet'
    Expect-Name $Win 'Greeting' 'Please type your name.'
    Set-Text (Get-Id $Win 'NameBox') 'Ali'
    Expect-Name $Win 'Greeting' ''
    Invoke-Named $Win 'Greet'
    Expect-Name $Win 'Greeting' 'Hello, Ali!'
  }
  Test-Sample 'ListDemo' {
    param($Win)
    Expect-Name $Win 'Status' '3 items, none selected'
    $Banana = Get-Named (Get-Id $Win 'Fruits') 'Banana'
    $Banana.GetCurrentPattern([Windows.Automation.SelectionItemPattern]::Pattern).Select()
    Expect-Name $Win 'Status' '3 items, selected: Banana'
    Set-Text (Get-Id $Win 'NewItem') 'Date'
    Invoke-Named $Win 'Add'
    Expect-Name $Win 'Status' '4 items, selected: Banana'
    Invoke-Named $Win 'Remove'
    Expect-Name $Win 'Status' '3 items, none selected'
    $null = Get-Named (Get-Id $Win 'Fruits') 'Date'
    Write-Host "  [ok] 'Date' added, 'Banana' removed"
  }

  Test-Sample 'Contacts' {
    param($Win)
    # Text shown through {Binding Name} / {Binding Email} in the item template
    Expect-Name $Win 'Status' '3 contacts, none selected'
    $null = Get-Named $Win 'bea@example.com'
    Write-Host "  [ok] item template shows bound Name and Email"
    Set-Text (Get-Id $Win 'NameBox') 'Dana'
    Invoke-Named $Win 'Add'
    Expect-Name $Win 'Status' '4 contacts, none selected'
    $null = Get-Named $Win 'dana@example.com'
    # Select Bea: walk from her bound TextBlock up to the list item
    $Walker = [Windows.Automation.TreeWalker]::ControlViewWalker
    $Item = Get-Named $Win 'Bea'
    while ($Item.Current.ControlType -ne [Windows.Automation.ControlType]::ListItem) { $Item = $Walker.GetParent($Item) }
    $Item.GetCurrentPattern([Windows.Automation.SelectionItemPattern]::Pattern).Select()
    Expect-Name $Win 'Status' '4 contacts, selected: Bea'
    Set-Text (Get-Id $Win 'NameBox') 'Beatrice'
    Invoke-Named $Win 'Rename'
    $null = Get-Named $Win 'Beatrice'
    Expect-Name $Win 'Status' '4 contacts, selected: Beatrice'
    Write-Host "  [ok] ItemChanged updated the bound Name"
    Invoke-Named $Win 'Remove'
    Expect-Name $Win 'Status' '3 contacts, none selected'
  }
  Test-Sample 'Profile' {
    param($Win)
    Expect-Name $Win 'Summary' 'Ali from Tehran'
    Expect-Value $Win 'NameBox' 'Ali'
    # Converters: Format with ConverterParameter, Upper registered by the app
    Expect-Name $Win 'Greeting' 'Hello, Ali!'
    Expect-Name $Win 'CityUpper' 'TEHRAN'
    # BoolToVisibility: the badge is collapsed (not in the UI tree) until VipBox is checked
    if (Find-By $Win $AE::AutomationIdProperty 'VipBadge') { throw 'VipBadge is visible before VipBox is checked' }
    (Get-Id $Win 'VipBox').GetCurrentPattern([Windows.Automation.TogglePattern]::Pattern).Toggle()
    $null = Get-Id $Win 'VipBadge'
    Write-Host "  [ok] VipBox checked -> VipBadge visible (TwoWay CheckBox, BoolToVisibility)"    # TwoWay binding: typing writes TProfile.Name, whose setter updates Summary
    Set-Text (Get-Id $Win 'NameBox') 'Bea'
    Expect-Name $Win 'Summary' 'Bea from Tehran'
    Expect-Name $Win 'Greeting' 'Hello, Bea!'
    Set-Text (Get-Id $Win 'CityBox') 'Shiraz'
    Expect-Name $Win 'Summary' 'Bea from Shiraz'
    Expect-Name $Win 'CityUpper' 'SHIRAZ'
    # Changes made in code reach the bound TextBoxes
    Invoke-Named $Win 'Reset from code'
    Expect-Value $Win 'NameBox' 'Ali'
    Expect-Value $Win 'CityBox' 'Tehran'
    Expect-Name $Win 'Summary' 'Ali from Tehran'
    $null = Wait-For { -not (Find-By $Win $AE::AutomationIdProperty 'VipBadge') } 'VipBadge collapsed after reset'
    Write-Host "  [ok] reset -> VipBadge collapsed"
  }
)

# Closing a window must not crash the app afterwards (the WinUI DLLs stay
# loaded until the process ends), Windows Error Reporting logs such crashes as event 1000
Write-Host 'Clean exit'
Start-Sleep -Seconds 3
$Crashes = @(Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Id = 1000; StartTime = $Started } -ErrorAction SilentlyContinue |
  Where-Object { $_.Message -like "*$RepoRoot\samples\*" })
if ($Crashes) {
  Write-Host "  [failed] $($Crashes.Count) sample crash(es) after closing: $(($Crashes[0].Message -split "`n")[0..2] -join ' ')"
  $Results += $false
} else {
  Write-Host '  [ok] no sample crashed while closing (Application event log)'
}
Write-Host 'Native crash report'
& (Join-Path $PSScriptRoot 'Build.ps1') -Project 'tests\Runtime\CrashReportTest.dpr' | Out-Null
& (Join-Path $RepoRoot 'tests\Runtime\Win64\Debug\CrashReportTest.exe') | Select-Object -Skip 1
$Results += ($LASTEXITCODE -eq 0)

if ($Results -contains $false) {
  Write-Host "Sample tests FAILED (full log: $LogFile)"
  Stop-Transcript | Out-Null
  exit 1
}
Write-Host 'Sample tests PASSED'
Stop-Transcript | Out-Null
exit 0
