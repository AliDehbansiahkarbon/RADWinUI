<#
.SYNOPSIS
  Assembles the folder an end user gets for a RADWinUI app, and checks it runs on its own.

.DESCRIPTION
  Builds the project in Release (scripts\Build.ps1) and writes <Out> with:
  - <Project>.exe
  - A small app (the default): Microsoft.WindowsAppRuntime.Bootstrap.dll;
    the end user installs the Windows App Runtime once (see docs\DEPLOYMENT.md)
  - -SelfContained: the Windows App Runtime itself (Foundation, InteractiveExperiences
    and WinUI runtime files, WebView2 Core) next to the exe, and a manifest embedded
    in the exe that registers its classes, so nothing needs to be installed
  - THIRD-PARTY-NOTICES.txt, the license terms and README.txt
  All of these are files the Windows App SDK NuGet packages place next to an app,
  redistributable under license section 3.a.i.
  With -Verify (the default) it copies the folder outside the repository,
  runs it there with RADWINUI_ROOT cleared, on a secondary monitor without
  taking the focus, waits for the WinUI window, closes it and checks exit
  code 0, a self-contained app must also load every Windows App SDK module from
  its own folder. It installs, registers and signs nothing. Pass -Dcc64 to select
  a specific RAD Studio compiler without using registry discovery.

.EXAMPLE
  .\scripts\Deploy-App.ps1 -Project samples\Counter\Counter.dpr
  .\scripts\Deploy-App.ps1 -Project samples\Counter\Counter.dpr -SelfContained
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$Project,
  [string]$Dcc64,
  # Default: build\deploy\<project name>
  [string]$Out,
  [bool]$Verify = $true,
  [switch]$SelfContained
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Name = [IO.Path]::GetFileNameWithoutExtension($Project)
if (-not $Out) { $Out = Join-Path $RepoRoot "build\deploy\$Name" }
$Sdk = Get-Content (Join-Path $RepoRoot 'build\WindowsAppSDK.json') -Raw | ConvertFrom-Json
$SdkRoot = Join-Path $RepoRoot "third_party\WindowsAppSDK\$($Sdk.release)"
$Foundation = Join-Path $SdkRoot 'Microsoft.WindowsAppSDK.Foundation'
$Dll = Join-Path $Foundation 'runtimes\win-x64\native\Microsoft.WindowsAppRuntime.Bootstrap.dll'
if (-not (Test-Path $Dll)) { throw "Bootstrap DLL not found: run scripts\Get-WindowsAppSDK.ps1 first ($Dll)" }

# The self-contained payload, as Microsoft.WindowsAppSDK.SelfContained.targets (package
# Microsoft.WindowsAppSDK.Base) binplaces it: runtimes-framework of each component package
$Components = 'Microsoft.WindowsAppSDK.Foundation', 'Microsoft.WindowsAppSDK.InteractiveExperiences', 'Microsoft.WindowsAppSDK.WinUI'
$Payload = foreach ($Component in $Components) {
  $Native = Join-Path $SdkRoot "$Component\runtimes-framework\win-x64\native"
  # A release checkout has only the bootstrap DLL, the default mode does not need the rest
  if (-not (Test-Path -LiteralPath $Native)) { continue }
  Get-ChildItem -LiteralPath $Native -Recurse -File |
    Where-Object { $_.Extension -in '.dll', '.mui', '.png', '.xaml', '.xbf', '.pri' -or $_.Name -in 'RestartAgent.exe', 'map.html' -or $_.Name -like 'workloads*.json' } |
    ForEach-Object { [pscustomobject]@{ Source = $_.FullName; Path = $_.FullName.Substring($Native.Length + 1) } }
}
if ($SelfContained -and -not $Payload) { throw "The Windows App SDK runtime files are missing: run scripts\Get-WindowsAppSDK.ps1 first ($SdkRoot)" }
# WinUI registers WebView2's WinRT component, the WebView2 package places it next to the app
$Payload += [pscustomobject]@{ Source = Join-Path $SdkRoot 'Microsoft.Web.WebView2\runtimes\win-x64\native_uap\Microsoft.Web.WebView2.Core.dll'; Path = 'Microsoft.Web.WebView2.Core.dll' }

# An existing -Out is replaced only when it holds nothing but files this script writes (in
# either mode), so a mistyped path (a drive, the checkout, a user folder) is refused, never emptied
$Out = [IO.Path]::GetFullPath($Out)
$OwnFiles = @("$Name.exe", 'Microsoft.WindowsAppRuntime.Bootstrap.dll', 'Microsoft.WindowsAppSDK.LICENSE.txt',
  'Microsoft.Web.WebView2.LICENSE.txt', 'README.txt', 'THIRD-PARTY-NOTICES.txt', 'resources.pri') + @($Payload.Path)
$OwnFolders = @($Payload.Path | ForEach-Object { for ($D = Split-Path $_; $D; $D = Split-Path $D) { $D } } | Sort-Object -Unique)
if (Test-Path -LiteralPath $Out) {
  $Foreign = @(Get-ChildItem -LiteralPath $Out -Recurse -Force | Where-Object {
    $Relative = $_.FullName.Substring($Out.TrimEnd('\').Length + 1)
    if ($_.PSIsContainer) { $OwnFolders -notcontains $Relative } else { $OwnFiles -notcontains $Relative } })
  if ($Foreign.Count -gt 0) {
    throw "Refusing to replace $Out`: it holds files Deploy-App.ps1 did not write ($($Foreign[0].FullName)). Pass an empty or new -Out."
  }
}

& (Join-Path $PSScriptRoot 'Build.ps1') -Project $Project -Config Release -Dcc64 $Dcc64 | Out-Host
if ($LASTEXITCODE -ne 0) { throw "Building $Project failed" }
$Exe = Join-Path (Split-Path (Join-Path $RepoRoot $Project)) "Win64\Release\$Name.exe"

foreach ($File in $OwnFiles) { Remove-Item -LiteralPath (Join-Path $Out $File) -Force -ErrorAction SilentlyContinue }
foreach ($Folder in $OwnFolders | Sort-Object Length -Descending) {
  $Path = Join-Path $Out $Folder
  if ((Test-Path -LiteralPath $Path) -and -not (Get-ChildItem -LiteralPath $Path -Force)) { Remove-Item -LiteralPath $Path }
}
New-Item -ItemType Directory -Force $Out | Out-Null
Copy-Item $Exe $Out
Copy-Item (Join-Path $Foundation 'license.txt') (Join-Path $Out 'Microsoft.WindowsAppSDK.LICENSE.txt')

if ($SelfContained) {
  foreach ($File in $Payload) {
    $Target = Join-Path $Out $File.Path
    New-Item -ItemType Directory -Force (Split-Path $Target) | Out-Null
    Copy-Item -LiteralPath $File.Source $Target
  }
  Copy-Item (Join-Path $SdkRoot 'Microsoft.Web.WebView2\LICENSE.txt') (Join-Path $Out 'Microsoft.Web.WebView2.LICENSE.txt')
  # An unpackaged app's MRT index is resources.pri next to the exe, WinUI's control resources
  # (XamlControlsResources) are looked up there. RADWinUI apps have no PRI resources of their
  # own, so WinUI's index serves as-is.
  # The other component .pri files are not merged in (that needs makepri.exe from the Windows
  # SDK), merge when an app ships its own PRI resources or a component string is found missing
  Copy-Item (Join-Path $Out 'Microsoft.UI.Xaml.Controls.pri') (Join-Path $Out 'resources.pri')

  # Reg-free WinRT: the app manifest names every runtime class and the DLL that implements it,
  # generated from each component's package.appxfragment like GenerateAppManifestFromAppxFragments
  $Ns = @{ m = 'http://schemas.microsoft.com/appx/manifest/foundation/windows10' }
  $Manifest = [Text.StringBuilder]::new()
  [void]$Manifest.AppendLine("<?xml version='1.0' encoding='utf-8' standalone='yes'?>")
  [void]$Manifest.AppendLine("<assembly manifestVersion='1.0' xmlns='urn:schemas-microsoft-com:asm.v1' xmlns:asmv3='urn:schemas-microsoft-com:asm.v3' xmlns:winrtv1='urn:schemas-microsoft-com:winrt.v1'>")
  $Registered = @()
  foreach ($Component in $Components) {
    [xml]$Fragment = Get-Content -Raw (Join-Path $SdkRoot "$Component\runtimes-framework\package.appxfragment")
    foreach ($Server in (Select-Xml -Xml $Fragment -XPath '/m:Fragment/m:Extensions/m:Extension/m:InProcessServer' -Namespace $Ns).Node) {
      $Registered += $Server.Path
      [void]$Manifest.AppendLine("  <asmv3:file name='$($Server.Path)'>")
      foreach ($Class in $Server.ActivatableClass) {
        [void]$Manifest.AppendLine("    <winrtv1:activatableClass name='$($Class.ActivatableClassId)' threadingModel='both'/>")
      }
      [void]$Manifest.AppendLine('  </asmv3:file>')
    }
    foreach ($Stub in (Select-Xml -Xml $Fragment -XPath '/m:Fragment/m:Extensions/m:Extension/m:ProxyStub' -Namespace $Ns).Node) {
      # Like the SDK: push notifications need the Singleton package, which a self-contained app lacks
      if ($Stub.Path -in 'PushNotificationsLongRunningTask.ProxyStub.dll', 'Microsoft.Windows.Widgets.dll') { continue }
      $Registered += $Stub.Path
      [void]$Manifest.AppendLine("  <asmv3:file name='$($Stub.Path)'>")
      [void]$Manifest.AppendLine("    <asmv3:comClass clsid='{$($Stub.ClassId)}'/>")
      foreach ($Interface in $Stub.Interface) {
        [void]$Manifest.AppendLine("    <asmv3:comInterfaceProxyStub name='$($Interface.Name)' iid='{$($Interface.InterfaceId)}'/>")
      }
      [void]$Manifest.AppendLine('  </asmv3:file>')
    }
  }
  [void]$Manifest.AppendLine('</assembly>')
  $Missing = @($Registered | Where-Object { -not (Test-Path -LiteralPath (Join-Path $Out $_)) })
  if ($Missing) { throw "The manifest registers DLLs the folder lacks: $($Missing -join ', ')" }
  if (-not ('RADWinUI.Resources' -as [type])) {
    Add-Type -Namespace RADWinUI -Name Resources -MemberDefinition @'
[DllImport("kernel32", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern IntPtr BeginUpdateResource(string file, bool deleteExisting);
[DllImport("kernel32", SetLastError = true)]
public static extern bool UpdateResource(IntPtr update, IntPtr type, IntPtr name, ushort language, byte[] data, int size);
[DllImport("kernel32", SetLastError = true)]
public static extern bool EndUpdateResource(IntPtr update, bool discard);
'@
  }
  # RT_MANIFEST (24), CREATEPROCESS_MANIFEST_RESOURCE_ID (1), the exe has no manifest of its own
  $Bytes = [Text.Encoding]::UTF8.GetBytes($Manifest.ToString())
  $Update = [RADWinUI.Resources]::BeginUpdateResource((Join-Path $Out "$Name.exe"), $false)
  if ($Update -eq [IntPtr]::Zero -or -not [RADWinUI.Resources]::UpdateResource($Update, 24, 1, 0, $Bytes, $Bytes.Length) -or
      -not [RADWinUI.Resources]::EndUpdateResource($Update, $false)) {
    throw "Embedding the runtime manifest in $Name.exe failed (Win32 error $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))"
  }
  $Requirement = '- Nothing else: the Windows App Runtime is included in this folder.'
  $Keep = "Keep every file and folder next to $Name.exe together."
  $Shipped = "The Windows App Runtime files in this folder (Microsoft.WindowsAppRuntime.dll, Microsoft.UI.*,
Microsoft.ui.xaml*, the language folders and the other runtime DLLs) are part of the Microsoft
Windows App SDK $($Sdk.release) (packages Microsoft.WindowsAppSDK.Foundation $($Sdk.packages.'Microsoft.WindowsAppSDK.Foundation'),
.InteractiveExperiences $($Sdk.packages.'Microsoft.WindowsAppSDK.InteractiveExperiences'), .WinUI $($Sdk.packages.'Microsoft.WindowsAppSDK.WinUI')), (c) Microsoft Corporation"
  $WebView2 = @"


Microsoft.Web.WebView2.Core.dll is part of Microsoft WebView2 $($Sdk.packages.'Microsoft.Web.WebView2'), (c) Microsoft
Corporation, under the BSD-style license included as Microsoft.Web.WebView2.LICENSE.txt.
"@
} else {
  Copy-Item $Dll $Out
  $Requirement = "- Windows App Runtime $($Sdk.release) (x64), version $($Sdk.runtimeVersion) or later in the 2.x line.
  Install it once per machine with Microsoft's installer (WindowsAppRuntimeInstall-x64.exe)
  from https://learn.microsoft.com/windows/apps/windows-app-sdk/downloads
  When it is missing, $Name.exe reports it at start."
  $Keep = "Keep Microsoft.WindowsAppRuntime.Bootstrap.dll next to $Name.exe."
  $Shipped = "Microsoft.WindowsAppRuntime.Bootstrap.dll is part of the Microsoft Windows App SDK
$($Sdk.release) (package Microsoft.WindowsAppSDK.Foundation $($Sdk.packages.'Microsoft.WindowsAppSDK.Foundation')), (c) Microsoft
Corporation"
  $WebView2 = ''
}
[IO.File]::WriteAllText((Join-Path $Out 'README.txt'), @"
$Name

Requirements
- Windows 10 version 1809 or later, 64-bit
$Requirement

$Keep
Do not run $Name.exe as administrator: WinUI 3 does not run elevated.
"@)
[IO.File]::WriteAllText((Join-Path $Out 'THIRD-PARTY-NOTICES.txt'), @"
$Shipped, distributed under the Microsoft Software License Terms for the Windows App
SDK (distributable code, section 3). The full terms are included as
Microsoft.WindowsAppSDK.LICENSE.txt. The application's own license terms must protect this code and
Microsoft at least as much as those terms do (section 3.b).$WebView2
"@)
$Files = @(Get-ChildItem $Out -Recurse -File)
Write-Host "Deployable folder: $Out ($($Files.Count) files, $([math]::Round(($Files | Measure-Object Length -Sum).Sum / 1MB, 1)) MB)" -ForegroundColor Green
Get-ChildItem $Out -File | Select-Object -First 12 | ForEach-Object { Write-Host "  $($_.Name)  $($_.Length) bytes" }

if (-not $Verify) { exit 0 }

# Runs from a folder outside the repository: nothing may come from the checkout.
# A new folder each run: only what this run created is removed afterwards
$Check = Join-Path ([IO.Path]::GetTempPath()) "RADWinUI-deploy-check-$Name-$([guid]::NewGuid().ToString('N'))"
Copy-Item -LiteralPath $Out $Check -Recurse
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
$AE = [Windows.Automation.AutomationElement]
$SavedRoot = $env:RADWINUI_ROOT
$env:RADWINUI_ROOT = ''
$env:RADWINUI_TEST_MONITOR = 'secondary'
try {
  $Proc = Start-Process (Join-Path $Check "$Name.exe") -WorkingDirectory $Check -PassThru
  $null = $Proc.Handle
  $Deadline = (Get-Date).AddSeconds(20)
  do {
    $Win = $AE::RootElement.FindFirst([Windows.Automation.TreeScope]::Children, (New-Object Windows.Automation.AndCondition(
      (New-Object Windows.Automation.PropertyCondition($AE::ProcessIdProperty, $Proc.Id)),
      (New-Object Windows.Automation.PropertyCondition($AE::ClassNameProperty, 'WinUIDesktopWin32WindowClass')))))
    Start-Sleep -Milliseconds 200
  } until ($Win -or $Proc.HasExited -or (Get-Date) -gt $Deadline)
  if (-not $Win) { throw "the deployed $Name.exe did not open its window from $Check" }
  if ($SelfContained) {
    # Proof it does not use an installed Windows App Runtime: each loaded runtime DLL comes from
    # the app folder, and nothing comes from a framework package (WindowsApps)
    $Proc.Refresh()
    $PayloadDlls = @($Payload.Path | Where-Object { $_ -like '*.dll' } | Split-Path -Leaf)
    $Modules = @($Proc.Modules | Where-Object { $PayloadDlls -contains $_.ModuleName })
    $Outside = @($Proc.Modules | Where-Object {
      ($PayloadDlls -contains $_.ModuleName -and -not $_.FileName.StartsWith($Check, [StringComparison]::OrdinalIgnoreCase)) -or
      $_.FileName -like '*\WindowsApps\*' })
    if ($Modules.Count -lt 5 -or $Outside) {
      throw "the self-contained $Name.exe loaded Windows App SDK modules from elsewhere: $(($Outside.FileName) -join ', ')"
    }
    Write-Host "  [ok] all $($Modules.Count) Windows App SDK modules load from the app folder (none from an installed runtime)"
  }
  $Win.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern).Close()
  if (-not $Proc.WaitForExit(15000) -or $Proc.ExitCode -ne 0) { throw "the deployed $Name.exe did not exit cleanly" }
  Write-Host "  [ok] runs from $Check (outside the repository, RADWINUI_ROOT cleared) and exits with code 0"
} finally {
  if ($Proc -and -not $Proc.HasExited) { $Proc.Kill() }
  $env:RADWINUI_ROOT = $SavedRoot
  Remove-Item -LiteralPath $Check -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'Deployment check PASSED'
