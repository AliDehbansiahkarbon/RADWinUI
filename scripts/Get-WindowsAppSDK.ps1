<#
.SYNOPSIS
  Downloads the Windows App SDK NuGet packages RADWinUI builds against.

.DESCRIPTION
  Reads build\WindowsAppSDK.json, downloads each package from nuget.org into
  third_party\WindowsAppSDK\<release>\<package>.

  The packages provide:
    - Foundation: Microsoft.WindowsAppRuntime.Bootstrap.dll and its .winmd files
    - WinUI: Microsoft.UI.Xaml.winmd (input for WinMDGen)
    - InteractiveExperiences: Microsoft.UI.winmd, Microsoft.Foundation.winmd
    - Runtime: version info and the Windows App Runtime MSIX packages

.PARAMETER InstallRuntime
  Also installs the x64 Windows App Runtime MSIX packages for the current user.

.EXAMPLE
  .\scripts\Get-WindowsAppSDK.ps1
  .\scripts\Get-WindowsAppSDK.ps1 -InstallRuntime
#>
[CmdletBinding()]
param(
  [switch]$InstallRuntime
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Config = Get-Content (Join-Path $RepoRoot 'build\WindowsAppSDK.json') -Raw | ConvertFrom-Json
$TargetRoot = Join-Path $RepoRoot "third_party\WindowsAppSDK\$($Config.release)"
New-Item -ItemType Directory -Force -Path $TargetRoot | Out-Null

foreach ($Package in $Config.packages.PSObject.Properties) {
  $Id = $Package.Name
  $Version = $Package.Value
  $Folder = Join-Path $TargetRoot $Id
  if (Test-Path $Folder) {
    Write-Host "$Id $Version already present"
    continue
  }
  $LowerId = $Id.ToLowerInvariant()
  $Url = "https://api.nuget.org/v3-flatcontainer/$LowerId/$Version/$LowerId.$Version.nupkg"
  $Zip = Join-Path $TargetRoot "$Id.$Version.zip"
  Write-Host "Downloading $Id $Version"
  Invoke-WebRequest -Uri $Url -OutFile $Zip -UseBasicParsing
  Expand-Archive -Path $Zip -DestinationPath $Folder -Force
  Remove-Item $Zip
}

if ($InstallRuntime) {
  $MsixDir = Join-Path $TargetRoot 'Microsoft.WindowsAppSDK.Runtime\tools\MSIX\win10-x64'
  # The framework package must be installed before the packages that depend on it.
  $Order = 'Microsoft.WindowsAppRuntime.2.msix',
           'Microsoft.WindowsAppRuntime.Main.2.msix',
           'Microsoft.WindowsAppRuntime.Singleton.2.msix',
           'Microsoft.WindowsAppRuntime.DDLM.2.msix'
  foreach ($Name in $Order) {
    $Path = Join-Path $MsixDir $Name
    if (Test-Path $Path) {
      Write-Host "Installing $Name"
      Add-AppxPackage -Path $Path -ForceUpdateFromAnyVersion
    }
  }
}

Write-Host 'Done.'
