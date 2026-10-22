<#
.SYNOPSIS
  Tests the File > New wizard templates outside the IDE.

.DESCRIPTION
  Builds and runs tests\Wizard\WizardTest.exe, which writes a new project to
  build\wizard-test\HelloWinUI with the wizard's template unit. Then builds
  the generated .dproj with MSBuild like the IDE does (pre-build XamlCodeGen,
  post-build bootstrap DLL copy), and drives the app with UI Automation:
  Increment shows 1, the window closes and the process exits with code 0.

.EXAMPLE
  .\scripts\Test-Wizard.ps1
#>
[CmdletBinding()]
param(
  [ValidateSet('Debug', 'Release')]
  [string]$Config = 'Debug'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
# The app window opens on a secondary monitor without taking the focus (TWinUIWindow.Show)
$env:RADWINUI_TEST_MONITOR = 'secondary'
$RepoRoot = Split-Path -Parent $PSScriptRoot
# A path with spaces, as projects often have
$Out = Join-Path $RepoRoot 'build\wizard-test\Folder With Spaces'
$Name = 'HelloWinUI'
$ProjectDir = Join-Path $Out $Name
$AE = [Windows.Automation.AutomationElement]

function Fail([string]$Message) {
  Write-Host "  [failed] $Message"
  Write-Host 'Wizard test FAILED'
  exit 1
}

# 1. Template unit, outside the IDE
& (Join-Path $PSScriptRoot 'Build.ps1') -Project 'tests\Wizard\WizardTest.dpr' | Out-Null
if ($LASTEXITCODE -ne 0) { Fail 'WizardTest did not build' }
if (Test-Path $ProjectDir) { Remove-Item -Recurse -Force $ProjectDir }
& (Join-Path $RepoRoot 'tests\Wizard\Win64\Debug\WizardTest.exe') $RepoRoot $ProjectDir $Name
if ($LASTEXITCODE -ne 0) { Fail 'WizardTest reported failures' }

$Dll = 'Microsoft.WindowsAppRuntime.Bootstrap.dll'
if (-not (Test-Path (Join-Path $ProjectDir "Win64\Debug\$Dll"))) { Fail 'the new project has no bootstrap DLL in Win64\Debug before its first build' }
Write-Host '  [ok] new project: bootstrap DLL already in Win64\Debug (first Run works without a build)'

# 2. The wizard leaves MainWindow.Xaml.pas to XamlCodeGen (it runs the tool after writing the files)
$XamlUnit = Join-Path $ProjectDir 'MainWindow.Xaml.pas'
if (Test-Path $XamlUnit) { Fail 'WriteProject wrote MainWindow.Xaml.pas, XamlCodeGen generates it' }
Write-Host '  [ok] no hand-written MainWindow.Xaml.pas'

# A user opens the window WizardTest added (RADWinUI Window) from the main window
$MainXaml = Join-Path $ProjectDir 'MainWindow.xaml'
$MainPas = Join-Path $ProjectDir 'MainWindow.pas'
# The template's root is a Grid with placed controls: one more, below Increment
(Get-Content $MainXaml -Raw).Replace('    </Grid>',
  "        <Button x:Name=`"OpenButton`" Content=`"Open second window`" HorizontalAlignment=`"Left`" VerticalAlignment=`"Top`" Margin=`"32,150,0,0`"/>`r`n    </Grid>") |
  Set-Content $MainXaml -NoNewline
$Pas = (Get-Content $MainPas -Raw).Replace("  MainWindow.Xaml;", "  MainWindow.Xaml,`r`n  SecondWindow;")
$Pas = $Pas.Replace("    procedure IncrementButtonClick(Sender: TObject);",
  "    procedure IncrementButtonClick(Sender: TObject);`r`n    procedure OpenButtonClick(Sender: TObject);")
$Pas = $Pas.Replace("end.", "procedure TMainWindow.OpenButtonClick(Sender: TObject);`r`nbegin`r`n  TSecondWindow.Create.Show;`r`nend;`r`n`r`nend.")
Set-Content $MainPas $Pas -NoNewline
# Build events must not depend on macros the IDE and MSBuild expand differently:
# $(PROJECTDIR) ends with a backslash in MSBuild but not in the IDE.
$DProjText = Get-Content (Join-Path $ProjectDir "$Name.dproj") -Raw
if ($DProjText -match '\$\((PROJECTDIR|OUTPUTDIR)\)') { Fail "the .dproj build events use $($($Matches[1])), which differs between the IDE and MSBuild" }
Write-Host '  [ok] build events use $(MSBuildProjectDirectory) and $(DCC_ExeOutput) only'
# The IDE joins event lines with "&&", which would make a copy after an "if" conditional
$Post = [regex]::Match($DProjText, '(?s)<PostBuildEvent><!\[CDATA\[(.*?)\]\]>').Groups[1].Value
if ($Post -match "[\r\n]") { Fail 'the post-build event has more than one line' }
Write-Host '  [ok] post-build event is one line'

# 3. Build the .dproj the way the IDE does
$Bds = (Get-ItemProperty 'HKCU:\Software\Embarcadero\BDS\37.0').RootDir
$Log = Join-Path $RepoRoot "build\logs\$Name-msbuild.log"
cmd /c "`"$(Join-Path $Bds 'bin\rsvars.bat')`" && msbuild `"$ProjectDir\$Name.dproj`" /t:Build /p:Config=$Config /p:Platform=Win64 /nologo /v:minimal" > $Log 2>&1
if ($LASTEXITCODE -ne 0) { Get-Content $Log | Select-Object -Last 20; Fail "MSBuild failed (log: $Log)" }
$Exe = Join-Path $ProjectDir "Win64\$Config\$Name.exe"
if (-not (Test-Path $Exe)) { Fail "no $Exe" }
if (-not (Test-Path (Join-Path $ProjectDir "Win64\$Config\Microsoft.WindowsAppRuntime.Bootstrap.dll"))) { Fail 'post-build did not copy the bootstrap DLL' }
Write-Host "  [ok] MSBuild built $Name.exe, post-build copied the bootstrap DLL"
if (-not (Test-Path $XamlUnit) -or -not (Select-String -Path $XamlUnit -Pattern 'DO NOT EDIT' -Quiet)) { Fail 'pre-build did not generate MainWindow.Xaml.pas' }
Write-Host '  [ok] pre-build generated MainWindow.Xaml.pas with XamlCodeGen'

# 4. Run it
$Proc = Start-Process $Exe -PassThru
$null = $Proc.Handle
try {
  # The WinUI window itself: other top-level elements of the process have no WindowPattern
  $Cond = New-Object Windows.Automation.AndCondition(
    (New-Object Windows.Automation.PropertyCondition($AE::ProcessIdProperty, $Proc.Id)),
    (New-Object Windows.Automation.PropertyCondition($AE::ClassNameProperty, 'WinUIDesktopWin32WindowClass')))
  $Deadline = (Get-Date).AddSeconds(15)
  do { $Win = $AE::RootElement.FindFirst([Windows.Automation.TreeScope]::Children, $Cond); Start-Sleep -Milliseconds 200 } until ($Win -or (Get-Date) -gt $Deadline)
  if (-not $Win) { Fail 'the window did not appear' }
  $Btn = $null; $Text = $null
  $Deadline = (Get-Date).AddSeconds(15)
  do {
    $Btn = $Win.FindFirst([Windows.Automation.TreeScope]::Descendants, (New-Object Windows.Automation.AndCondition(
      (New-Object Windows.Automation.PropertyCondition($AE::NameProperty, 'Increment')),
      (New-Object Windows.Automation.PropertyCondition($AE::ControlTypeProperty, [Windows.Automation.ControlType]::Button)))))
    Start-Sleep -Milliseconds 200
  } until ($Btn -or (Get-Date) -gt $Deadline)
  if (-not $Btn) { Fail 'no Increment button' }
  $Btn.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern).Invoke()
  $Deadline = (Get-Date).AddSeconds(15)
  do {
    $Text = $Win.FindFirst([Windows.Automation.TreeScope]::Descendants,
      (New-Object Windows.Automation.PropertyCondition($AE::AutomationIdProperty, 'CounterText')))
    $Value = if ($Text) { $Text.Current.Name } else { '' }
    Start-Sleep -Milliseconds 200
  } until ($Value -eq 'Count: 1' -or (Get-Date) -gt $Deadline)
  if ($Value -ne 'Count: 1') { Fail "CounterText is '$Value', expected 'Count: 1'" }
  Write-Host "  [ok] Increment -> ViewModel.Count -> CounterText = 'Count: 1' (Binding, Format converter)"

  # The second window: opened from the main window, closed by its own Close button
  $Open = $Win.FindFirst([Windows.Automation.TreeScope]::Descendants, (New-Object Windows.Automation.AndCondition(
    (New-Object Windows.Automation.PropertyCondition($AE::NameProperty, 'Open second window')),
    (New-Object Windows.Automation.PropertyCondition($AE::ControlTypeProperty, [Windows.Automation.ControlType]::Button)))))
  if (-not $Open) { Fail 'no Open second window button' }
  $Open.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern).Invoke()
  $SecondCond = New-Object Windows.Automation.AndCondition($Cond,
    (New-Object Windows.Automation.PropertyCondition($AE::NameProperty, 'SecondWindow')))
  $Deadline = (Get-Date).AddSeconds(15)
  do { $Second = $AE::RootElement.FindFirst([Windows.Automation.TreeScope]::Children, $SecondCond); Start-Sleep -Milliseconds 200 } until ($Second -or (Get-Date) -gt $Deadline)
  if (-not $Second) { Fail 'the second window did not open' }
  $Message = $Second.FindFirst([Windows.Automation.TreeScope]::Descendants,
    (New-Object Windows.Automation.PropertyCondition($AE::AutomationIdProperty, 'Message')))
  if (-not $Message -or $Message.Current.Name -ne 'SecondWindow') { Fail 'the second window does not show its message' }
  Write-Host "  [ok] Open -> SecondWindow shows 'SecondWindow'"
  $Close = $Second.FindFirst([Windows.Automation.TreeScope]::Descendants, (New-Object Windows.Automation.AndCondition(
    (New-Object Windows.Automation.PropertyCondition($AE::NameProperty, 'Close')),
    (New-Object Windows.Automation.PropertyCondition($AE::ControlTypeProperty, [Windows.Automation.ControlType]::Button)))))
  $Close.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern).Invoke()
  $Deadline = (Get-Date).AddSeconds(15)
  do { $Gone = -not $AE::RootElement.FindFirst([Windows.Automation.TreeScope]::Children, $SecondCond); Start-Sleep -Milliseconds 200 } until ($Gone -or (Get-Date) -gt $Deadline)
  if (-not $Gone) { Fail 'the second window did not close' }
  Write-Host '  [ok] Close (CloseButtonClick by name) -> SecondWindow closed'
  $Win.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern).Close()
  if (-not $Proc.WaitForExit(15000)) { Fail 'the app did not exit after its window closed' }
  if ($Proc.ExitCode -ne 0) { Fail "the app exited with code $($Proc.ExitCode)" }
  Write-Host '  [ok] closed, exit code 0'
} finally {
  if (-not $Proc.HasExited) { $Proc.Kill() }
}
# 5. Builds the IDE also does: Compile only, and another exe folder
function Invoke-MSBuild([string]$Arguments) {
  cmd /c "`"$(Join-Path $Bds 'bin\rsvars.bat')`" && msbuild `"$ProjectDir\$Name.dproj`" $Arguments /p:Platform=Win64 /nologo /v:minimal" >> $Log 2>&1
  if ($LASTEXITCODE -ne 0) { Fail "MSBuild $Arguments failed (log: $Log)" }
}
$DebugDll = Join-Path $ProjectDir "Win64\Debug\$Dll"
Remove-Item $DebugDll
Invoke-MSBuild '/t:Make /p:Config=Debug'
if (-not (Test-Path $DebugDll)) { Fail 'Compile (Make) did not run the post-build copy' }
Write-Host '  [ok] Compile (Make) copies the bootstrap DLL'
Invoke-MSBuild '/t:Build /p:Config=Debug "/p:DCC_ExeOutput=.\Custom Out\Bin"'
if (-not (Test-Path (Join-Path $ProjectDir "Custom Out\Bin\$Name.exe")) -or
    -not (Test-Path (Join-Path $ProjectDir "Custom Out\Bin\$Dll"))) { Fail 'another exe folder did not get the exe and the DLL' }
Write-Host '  [ok] another exe folder (with spaces) gets the exe and the bootstrap DLL'

# 6. No DLL next to the exe: the Debug build loads it from the RADWinUI checkout
Invoke-MSBuild '/t:Build /p:Config=Debug'
Remove-Item $DebugDll
$Proc = Start-Process $Exe -PassThru
$null = $Proc.Handle
try {
  $Deadline = (Get-Date).AddSeconds(15)
  $FallbackCond = New-Object Windows.Automation.AndCondition(
    (New-Object Windows.Automation.PropertyCondition($AE::ProcessIdProperty, $Proc.Id)),
    (New-Object Windows.Automation.PropertyCondition($AE::ClassNameProperty, 'WinUIDesktopWin32WindowClass')))
  do { $Win = $AE::RootElement.FindFirst([Windows.Automation.TreeScope]::Children, $FallbackCond)
    Start-Sleep -Milliseconds 200 } until ($Win -or $Proc.HasExited -or (Get-Date) -gt $Deadline)
  if (-not $Win) { Fail 'without the DLL next to the exe, the app did not start (fallback folder)' }
  $Win.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern).Close()
  if (-not $Proc.WaitForExit(15000) -or $Proc.ExitCode -ne 0) { Fail 'the app did not exit cleanly (fallback run)' }
  Write-Host '  [ok] DLL missing next to the exe: Debug build starts from the fallback folder'
} finally {
  if (-not $Proc.HasExited) { $Proc.Kill() }
}
Write-Host 'Wizard test PASSED'
exit 0