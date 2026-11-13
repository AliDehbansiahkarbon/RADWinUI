<#
.SYNOPSIS
  Drives the samples (Counter, Greeter, ListDemo, Contacts, Profile, Customers_VCL...) with UI Automation.

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
  [string[]]$Only = @(),
  # secondary: another monitor without the focus, offscreen: outside every monitor
  [ValidateSet('secondary', 'offscreen')]
  [string]$Monitor = 'secondary'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
# Test windows open on a secondary monitor without taking the focus (TWinUIWindow.Show),
# the test drives them only through UI Automation patterns, which need no focus.
$env:RADWINUI_TEST_MONITOR = $Monitor
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
# A NavigationView item or another list item with this name: selecting it is a click
function Select-Named($Win, [string]$Name) {
  $Cond = New-Object Windows.Automation.AndCondition(
    (New-Object Windows.Automation.PropertyCondition($AE::NameProperty, $Name)),
    (New-Object Windows.Automation.PropertyCondition($AE::ControlTypeProperty, [Windows.Automation.ControlType]::ListItem)))
  $Item = Wait-For { $Win.FindFirst($Scope, $Cond) } "item '$Name'"
  $Item.GetCurrentPattern([Windows.Automation.SelectionItemPattern]::Pattern).Select()
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

# Accessibility: RADWinUI's own controls as a screen reader sees them
function Expect-Control($Element, $Type, [string]$Name) {
  if ($Element.Current.ControlType -ne $Type -or $Element.Current.Name -ne $Name) {
    throw "$($Element.Current.AutomationId) is $($Element.Current.ControlType.ProgrammaticName) '$($Element.Current.Name)', not $($Type.ProgrammaticName) '$Name'"
  }
}
function Get-Children($Element, $Type) {
  @($Element.FindAll([Windows.Automation.TreeScope]::Children,
    (New-Object Windows.Automation.PropertyCondition($AE::ControlTypeProperty, $Type))))
}

# A VCL app shows its main form itself (TWinUIWindow.Show does it for WinUI windows):
# started hidden (the first ShowWindow takes the startup value), then put where the
# test windows go and shown without activation
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class HiddenStart {
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
  struct STARTUPINFO { public int cb; public string reserved, desktop, title; public int x, y, w, h, xChars, yChars, fill, flags; public short show, reserved2; public IntPtr reserved3, input, output, error; }
  [StructLayout(LayoutKind.Sequential)]
  struct PROCESS_INFORMATION { public IntPtr process, thread; public int processId, threadId; }
  [DllImport("kernel32", CharSet = CharSet.Unicode, SetLastError = true)]
  static extern bool CreateProcess(string app, string cmd, IntPtr pa, IntPtr ta, bool inherit, int flags, IntPtr env, string dir, ref STARTUPINFO si, out PROCESS_INFORMATION pi);
  [DllImport("kernel32")] static extern bool CloseHandle(IntPtr h);
  [DllImport("user32")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, int flags);
  [DllImport("user32")] public static extern bool ShowWindow(IntPtr h, int cmd);
  [DllImport("user32")] static extern bool PostMessage(IntPtr h, int msg, IntPtr w, IntPtr l);
  public static void Click(IntPtr button) { PostMessage(button, 0xF5, IntPtr.Zero, IntPtr.Zero); } // BM_CLICK
  delegate bool EnumProc(IntPtr h, IntPtr data);
  [DllImport("user32")] static extern bool EnumWindows(EnumProc proc, IntPtr data);
  [DllImport("user32")] static extern int GetWindowThreadProcessId(IntPtr h, out int pid);
  [DllImport("user32", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr h, System.Text.StringBuilder name, int size);
  // A top-level window of the process with that class, visible or not; zero when there is none yet
  public static IntPtr Find(int processId, string className) {
    IntPtr found = IntPtr.Zero;
    EnumWindows((h, data) => {
      int pid; GetWindowThreadProcessId(h, out pid);
      var name = new System.Text.StringBuilder(256); GetClassName(h, name, 256);
      if (pid == processId && name.ToString() == className) { found = h; return false; }
      return true;
    }, IntPtr.Zero);
    return found;
  }
  public static int Start(string exe) {
    var si = new STARTUPINFO(); si.cb = Marshal.SizeOf(si); si.flags = 1; si.show = 0; // STARTF_USESHOWWINDOW, SW_HIDE
    PROCESS_INFORMATION pi;
    if (!CreateProcess(exe, null, IntPtr.Zero, IntPtr.Zero, false, 0, IntPtr.Zero, System.IO.Path.GetDirectoryName(exe), ref si, out pi))
      throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
    CloseHandle(pi.thread); CloseHandle(pi.process);
    return pi.processId;
  }
}
'@
function Show-InTestArea([IntPtr]$H) {
  Add-Type -AssemblyName System.Windows.Forms
  $Area = if ($Monitor -eq 'offscreen') { New-Object Drawing.Rectangle(-32000, -32000, 3840, 2160) }
    else { ([Windows.Forms.Screen]::AllScreens | Sort-Object Primary | Select-Object -First 1).WorkingArea }
  # SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE, then SW_SHOWNOACTIVATE
  $null = [HiddenStart]::SetWindowPos($H, [IntPtr]::Zero, $Area.X + 40, $Area.Y + 200, 0, 0, 0x15)
  $null = [HiddenStart]::ShowWindow($H, 4)
}

function Test-Sample([string]$Name, [scriptblock]$Scenario, [string]$VclForm) {
  if ($Only -and $Name -notin $Only) { return $true }
  Write-Host $Name
  $Exe = Join-Path $RepoRoot "samples\$Name\Win64\$Config\$Name.exe"
  $Proc = if ($VclForm) { Get-Process -Id ([HiddenStart]::Start($Exe)) } else { Start-Process $Exe -PassThru }
  $null = $Proc.Handle # keeps ExitCode readable after exit
  $Win = $null
  $Cond = New-Object Windows.Automation.PropertyCondition($AE::ProcessIdProperty, $Proc.Id)
  try {
    # The WinUI window itself, or the VCL form: other top-level elements of the process have no WindowPattern
    $Class = if ($VclForm) { $VclForm } else { 'WinUIDesktopWin32WindowClass' }
    $WinCond = New-Object Windows.Automation.AndCondition($Cond,
      (New-Object Windows.Automation.PropertyCondition($AE::ClassNameProperty, $Class)))
    if ($VclForm) {
      # Hidden windows are not in the UI Automation tree: find the form by its window class
      $Hwnd = Wait-For { $H = [HiddenStart]::Find($Proc.Id, $VclForm); if ($H -ne [IntPtr]::Zero) { $H } } "the $Name form"
      Show-InTestArea $Hwnd
    }
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

# Tempo remembers its window placement: keep the user's own, the offscreen run saves another
$TempoPlacement = (Get-ItemProperty 'HKCU:\Software\Tempo\Placement' -ErrorAction SilentlyContinue).TMainWindow
# Quill checks its English texts: run it in English, and give back the language picked in its Settings
$QuillLanguage = (Get-ItemProperty 'HKCU:\Software\Quill' -ErrorAction SilentlyContinue).Language
if (-not (Test-Path 'HKCU:\Software\Quill')) { New-Item 'HKCU:\Software\Quill' | Out-Null }
Set-ItemProperty 'HKCU:\Software\Quill' -Name Language -Value 'en-US'
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
  Test-Sample 'Quill' {
    param($Win)
    # Editing marks the note, closing it asks through MessageDlg. No picker or notification opens.
    Expect-Name $Win 'TitleNote' 'Welcome'
    Set-Text (Get-Id $Win 'Editor') 'Hello from Quill'
    Expect-Name $Win 'Status' '3 words - Edited'
    Expect-Name $Win 'TitleNote' 'Welcome *'
    Invoke-Named $Win 'Close note'
    $null = Get-Named $Win 'Save changes to "Welcome"?'
    Invoke-Named $Win 'No'
    Expect-Name $Win 'TitleNote' 'Untitled'
    Expect-Name $Win 'Status' '0 words - Not saved'
    Invoke-Named $Win 'New note'
    Expect-Name $Win 'TitleNote' 'Untitled 2'
    Write-Host "  [ok] edit, Save changes? -> No, new note"
  }
  Test-Sample 'AppServicesDemo' {
    param($Win)
    # Only the in-window dialogs: no picker, notification or registration
    Expect-Name $Win 'LaunchText' 'Started as: Launch, arguments ""'
    Invoke-Named $Win 'MessageDlg error, OK'
    $null = Get-Named $Win 'The file could not be read.'
    Invoke-Named $Win 'OK'
    $null = Wait-For { (Get-Id $Win 'LogText').Current.Name -like '*MessageDlg error: mrOk*' } 'the logged result'
    Write-Host "  [ok] MessageDlg result logged"
  }
  Test-Sample 'Crew' {
    param($Win)
    # Pages, a parameter, a page that asks before it is left, a KeepAlive page and a user control
    Expect-Name $Win 'PageTitle' 'Home'
    Invoke-Named $Win 'Open Ada Lovelace'
    Expect-Name $Win 'PageTitle' 'Ada Lovelace'
    Set-Text (Get-Id $Win 'RoleBox') 'Chief engineer'
    Expect-Name $Win 'Status' 'Edited'
    Invoke-Named $Win 'Back'
    $null = Get-Named $Win 'Save changes to Ada Lovelace?'
    Invoke-Named $Win 'Cancel'
    Expect-Name $Win 'PageTitle' 'Ada Lovelace'
    Invoke-Named $Win 'Back'
    $null = Get-Named $Win 'Save changes to Ada Lovelace?'
    Invoke-Named $Win 'No'
    Expect-Name $Win 'PageTitle' 'Home'
    Write-Host "  [ok] card -> profile with the person, Save changes? Cancel stays, No leaves"
    # A menu click the profile refuses: the profile stays and People must not stay highlighted
    Invoke-Named $Win 'Open Ada Lovelace'
    Set-Text (Get-Id $Win 'RoleBox') 'Chief engineer'
    Select-Named $Win 'People'
    $null = Get-Named $Win 'Save changes to Ada Lovelace?'
    Invoke-Named $Win 'Cancel'
    Expect-Name $Win 'PageTitle' 'Ada Lovelace'
    $People = Get-Named $Win 'People'
    $null = Wait-For { -not $People.GetCurrentPattern([Windows.Automation.SelectionItemPattern]::Pattern).Current.IsSelected } 'People not selected'
    Invoke-Named $Win 'Back'
    $null = Get-Named $Win 'Save changes to Ada Lovelace?'
    Invoke-Named $Win 'No'
    Expect-Name $Win 'PageTitle' 'Home'
    Write-Host "  [ok] a menu click the profile refuses leaves no menu item selected"
    Select-Named $Win 'People'
    Expect-Name $Win 'PageTitle' 'People'
    Set-Text (Get-Id $Win 'SearchBox') 'grace'
    Expect-Name $Win 'CountText' '1 person'
    Select-Named $Win 'Home'
    Expect-Name $Win 'PageTitle' 'Home'
    Select-Named $Win 'People'
    Expect-Value $Win 'SearchBox' 'grace'
    Write-Host "  [ok] NavigationView items navigate, the KeepAlive page keeps its search"
  }
  Test-Sample 'TabBars' {
    param($Win)
    # A tab bar is a Tab control with one TabItem per tab, each tab selectable through UI Automation
    $CT = [Windows.Automation.ControlType]
    $Bar = Get-Id $Win 'PillBar'
    Expect-Control $Bar $CT::Tab 'Social sections'
    if (-not $Bar.Current.IsKeyboardFocusable) { throw 'the tab bar is not a tab stop' }
    $Tabs = Get-Children $Bar $CT::TabItem
    $Names = ($Tabs | ForEach-Object { $_.Current.Name }) -join ','
    if ($Names -ne 'Home,Search,Likes,Profile') { throw "tabs: $Names" }
    if ($Tabs[1].Current.BoundingRectangle.Left -le $Tabs[0].Current.BoundingRectangle.Left -or
        $Tabs[0].Current.BoundingRectangle.Width -le 0) { throw 'the tabs have no place of their own in the bar' }
    $Tabs[2].GetCurrentPattern([Windows.Automation.SelectionItemPattern]::Pattern).Select()
    $null = Wait-For { $Tabs[2].GetCurrentPattern([Windows.Automation.SelectionItemPattern]::Pattern).Current.IsSelected } 'Likes selected'
    $Selected = $Bar.GetCurrentPattern([Windows.Automation.SelectionPattern]::Pattern).Current.GetSelection()
    if ($Selected.Count -ne 1 -or $Selected[0].Current.Name -ne 'Likes') { throw 'the Selection pattern does not report Likes' }
    Write-Host "  [ok] PillBar: Tab 'Social sections', TabItems $Names, Likes selected through UI Automation"
  }
  Test-Sample 'ActionButtons' {
    param($Win)
    # The action buttons are buttons: named by their text, a tab stop, Invoke does what a click does
    $CT = [Windows.Automation.ControlType]
    $Send = Get-Id $Win 'SendButton1'
    Expect-Control $Send $CT::Button 'Send'
    if (-not $Send.Current.IsKeyboardFocusable) { throw 'Send is not a tab stop' }
    Expect-Control (Get-Id $Win 'CopyButton1') $CT::Button 'Copy join.app/x7Kq2'
    $Send.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern).Invoke()
    $null = Wait-For { (Get-Id $Win 'StatusText').Current.Name -like 'Paper Plane: Click*' } 'the Send click through Invoke'
    Write-Host "  [ok] Send and Copy are named buttons, Invoke sends"
  }
  Test-Sample 'DataControls' {
    param($Win)
    # The navigator is a toolbar of named buttons, a grid is a named group around its rows
    $CT = [Windows.Automation.ControlType]
    $Navigator = Get-Id $Win 'CustomersNavigator'
    Expect-Control $Navigator $CT::ToolBar 'Customers navigator'
    $Names = (Get-Children $Navigator $CT::Button | ForEach-Object { $_.Current.Name }) -join ','
    if ($Names -notlike 'First record,Prior record,Next record,Last record*') { throw "navigator buttons: $Names" }
    Expect-Control (Get-Id $Win 'CustomersGrid') $CT::Group 'Customers'
    Write-Host "  [ok] Customers navigator: $Names"
  }
  Test-Sample 'Tempo' {
    param($Win)
    # Owned windows appear under their owner. No compact overlay or full screen: they would leave the test area.
    function Owned([string]$Name) {
      $Cond = New-Object Windows.Automation.AndCondition(
        (New-Object Windows.Automation.PropertyCondition($AE::NameProperty, $Name)),
        (New-Object Windows.Automation.PropertyCondition($AE::ControlTypeProperty, [Windows.Automation.ControlType]::Window)))
      Wait-For { $Win.FindFirst([Windows.Automation.TreeScope]::Children, $Cond) } "the $Name window"
    }
    Expect-Name $Win 'StationName' 'Lo-fi Study'
    Invoke-Named $Win 'Queue'
    $Queue = Owned 'Queue'
    $Queue.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern).Close()
    Write-Host "  [ok] the Queue tool window opens as an owned window and hides when closed"
    Invoke-Named $Win 'Add station...'
    $Dialog = Owned 'Add station'
    Set-Text (Get-Id $Dialog 'NameBox') 'Night Owl'
    Invoke-Named $Dialog 'Add'
    Expect-Name $Win 'Status' 'Added Night Owl'
    Expect-Name $Win 'StationName' 'Night Owl'
    Write-Host "  [ok] the modal Add station window returns its result"
    Invoke-Named $Win 'Back'
    Expect-Name $Win 'StationName' 'Lo-fi Study'
    Write-Host "  [ok] the title bar's back button goes back"
  }
  Test-Sample 'Customers_VCL' -VclForm 'TCustomersForm' {
    param($Win)
    # The WinUI details panel inside the VCL form, bound to the selected customer
    Expect-Value $Win 'NameBox' 'Ada Lovelace'
    Set-Text (Get-Id $Win 'NameBox') 'Ada King'
    Invoke-Named $Win 'Save'
    $null = Get-Named $Win 'Saved Ada King'
    Write-Host "  [ok] Save (SaveButtonClick) takes the two-way bound name to the VCL status bar"
    Set-Text (Get-Id $Win 'EmailBox') 'changed@example.com'
    Invoke-Named $Win 'Revert'
    Expect-Value $Win 'EmailBox' 'ada@example.com'
    # A VCL TButton is a plain pane for UI Automation: click it through its window
    [HiddenStart]::Click([IntPtr](Get-Named $Win 'New').Current.NativeWindowHandle)
    Expect-Value $Win 'NameBox' 'New customer'
    Write-Host "  [ok] the VCL New button shows the new customer in the WinUI panel"
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
Write-Host 'Dialogs, notifications and activation'
& (Join-Path $PSScriptRoot 'Build.ps1') -Project 'tests\AppServices\AppServicesTest.dpr' | Out-Null
& (Join-Path $RepoRoot 'tests\AppServices\Win64\Debug\AppServicesTest.exe') | Select-Object -Skip 1
$Results += ($LASTEXITCODE -eq 0)
if ($TempoPlacement) { Set-ItemProperty 'HKCU:\Software\Tempo\Placement' -Name TMainWindow -Value $TempoPlacement }
else { Remove-Item 'HKCU:\Software\Tempo' -Recurse -ErrorAction SilentlyContinue }
if ($null -ne $QuillLanguage) { Set-ItemProperty 'HKCU:\Software\Quill' -Name Language -Value $QuillLanguage }
else { Remove-ItemProperty 'HKCU:\Software\Quill' -Name Language -ErrorAction SilentlyContinue }
Write-Host 'Pages, navigation and user controls'
& (Join-Path $PSScriptRoot 'Build.ps1') -Project 'tests\Pages\PagesTest.dpr' | Out-Null
& (Join-Path $RepoRoot 'tests\Pages\Win64\Debug\PagesTest.exe') | Select-Object -Skip 1
$Results += ($LASTEXITCODE -eq 0)
Write-Host 'Windows and title bar'
& (Join-Path $PSScriptRoot 'Build.ps1') -Project 'tests\Windows\WindowsTest.dpr' | Out-Null
& (Join-Path $RepoRoot 'tests\Windows\Win64\Debug\WindowsTest.exe') | Select-Object -Skip 1
$Results += ($LASTEXITCODE -eq 0)
Write-Host 'Overlay controls and their automation peers'
& (Join-Path $PSScriptRoot 'Build.ps1') -Project 'tests\CustomControls\OverlayControlsTest.dpr' | Out-Null
& (Join-Path $RepoRoot 'tests\CustomControls\Win64\Debug\OverlayControlsTest.exe')
$Results += ($LASTEXITCODE -eq 0)
Write-Host 'WinUI inside VCL forms'
& (Join-Path $PSScriptRoot 'Build.ps1') -Project 'tests\VclHost\VclHostTest.dpr' | Out-Null
& (Join-Path $RepoRoot 'tests\VclHost\Win64\Debug\VclHostTest.exe') | Select-Object -Skip 1
$Results += ($LASTEXITCODE -eq 0)
Write-Host 'Hot reload'
& (Join-Path $PSScriptRoot 'Build.ps1') -Project 'tests\HotReload\HotReloadTest.dpr' | Out-Null
& (Join-Path $RepoRoot 'tests\HotReload\Win64\Debug\HotReloadTest.exe') | Select-Object -Skip 1
$Results += ($LASTEXITCODE -eq 0)
# Debug builds listen for the IDE, Release builds have no pipe and no hot reload code
& (Join-Path $PSScriptRoot 'Build.ps1') -Project 'samples\Counter\Counter.dpr' -Config Release | Out-Null
$Pipe = [Text.Encoding]::Unicode.GetBytes('RADWinUI.HotReload.') # the pipe name's prefix
function Test-HasPipe([string]$Exe) {
  $Text = [Text.Encoding]::Unicode.GetString([IO.File]::ReadAllBytes($Exe))
  return $Text.Contains([Text.Encoding]::Unicode.GetString($Pipe))
}
$DebugHas = Test-HasPipe (Join-Path $RepoRoot 'samples\Counter\Win64\Debug\Counter.exe')
$ReleaseHas = Test-HasPipe (Join-Path $RepoRoot 'samples\Counter\Win64\Release\Counter.exe')
if ($DebugHas -and -not $ReleaseHas) { Write-Host '  [ok] Counter Debug has the hot reload pipe, Counter Release has none' }
else { Write-Host "  [failed] hot reload pipe in Counter: Debug $DebugHas, Release $ReleaseHas"; $Results += $false }
Write-Host 'Localization'
& (Join-Path $PSScriptRoot 'Build.ps1') -Project 'tests\Localization\LocalizationTest.dpr' | Out-Null
& (Join-Path $RepoRoot 'tests\Localization\Win64\Debug\LocalizationTest.exe') | Select-Object -Skip 1
$Results += ($LASTEXITCODE -eq 0)

if ($Results -contains $false) {
  Write-Host "Sample tests FAILED (full log: $LogFile)"
  Stop-Transcript | Out-Null
  exit 1
}
Write-Host 'Sample tests PASSED'
Stop-Transcript | Out-Null
exit 0
