<#
.SYNOPSIS
  Regenerates src\Generated\RADWinUI.Abi.pas, RADWinUI.Xaml.pas and RADWinUI.Xaml.json
  from the Windows App SDK metadata.
  Then writes src\Framework\RADWinUI.Controls.json, the type index of RADWinUI's
  own controls (RADWinUI.Controls), with tools\ControlsIndex.

.DESCRIPTION
  Builds tools\WinMDGen (a Delphi console program) into
  build\WinMDGen and runs it over the .winmd files of the packages that
  scripts\Get-WindowsAppSDK.ps1 downloaded, plus the Windows platform metadata
  in C:\Windows\System32\WinMetadata.

.PARAMETER Dcc64
  Full path of dcc64.exe, when the registry lookup picks the wrong version.

.EXAMPLE
  .\scripts\Generate-Projection.ps1
#>
[CmdletBinding()]
param(
  [string]$Dcc64
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Config = Get-Content (Join-Path $RepoRoot 'build\WindowsAppSDK.json') -Raw | ConvertFrom-Json
$Packages = Join-Path $RepoRoot "third_party\WindowsAppSDK\$($Config.release)"
if (-not (Test-Path $Packages)) {
  throw "SDK packages not found. Run scripts\Get-WindowsAppSDK.ps1 first."
}

$Inputs = @(
  (Join-Path $Packages 'Microsoft.WindowsAppSDK.WinUI\metadata'),
  (Join-Path $Packages 'Microsoft.WindowsAppSDK.InteractiveExperiences\metadata\10.0.18362.0'),
  (Join-Path $Packages 'Microsoft.WindowsAppSDK.Foundation\metadata'),
  (Join-Path $Packages 'Microsoft.Web.WebView2\lib'),
  (Join-Path $env:SystemRoot 'System32\WinMetadata')
)
$WinmdArgs = foreach ($Path in $Inputs) {
  if (-not (Test-Path $Path)) { throw "Metadata folder missing: $Path" }
  '--winmd'; $Path
}

function Find-BdsRoot {
  $Roots = foreach ($Hive in 'HKCU:', 'HKLM:', 'HKLM:\SOFTWARE\WOW6432Node') {
    $Key = "$Hive\Software\Embarcadero\BDS"
    if ($Hive -like '*WOW6432Node') { $Key = "$Hive\Embarcadero\BDS" }
    if (Test-Path $Key) {
      Get-ChildItem $Key | ForEach-Object {
        $Root = (Get-ItemProperty $_.PSPath -Name RootDir -ErrorAction SilentlyContinue).RootDir
        if ($Root -and (Test-Path (Join-Path $Root 'bin\dcc64.exe'))) {
          [pscustomobject]@{ Version = [version]$_.PSChildName; Root = $Root }
        }
      }
    }
  }
  $Roots | Sort-Object Version -Descending | Select-Object -First 1
}

if ($Dcc64) {
  $BdsRoot = Split-Path -Parent (Split-Path -Parent $Dcc64)
} else {
  $Bds = Find-BdsRoot
  if (-not $Bds) { throw 'RAD Studio not found. Pass -Dcc64 <path to dcc64.exe>.' }
  $BdsRoot = $Bds.Root
  $Dcc64 = Join-Path $BdsRoot 'bin\dcc64.exe'
}

# Build WinMDGen.exe outside bin\: it is a maintainer tool, not part of a release
$ToolDir = Join-Path $RepoRoot 'build\WinMDGen'
New-Item -ItemType Directory -Force $ToolDir | Out-Null
$Log = & $Dcc64 -B -Q '-NSSystem' "-E$ToolDir" "-NU$ToolDir" "-U$(Join-Path $BdsRoot 'lib\win64\release')" `
  (Join-Path $RepoRoot 'tools\WinMDGen\WinMDGen.dpr')
if ($LASTEXITCODE -ne 0) { $Log | Write-Host; throw 'Building WinMDGen.exe failed' }

& (Join-Path $ToolDir 'WinMDGen.exe') @WinmdArgs --out (Join-Path $RepoRoot 'src\Generated') `
  --sdk "Windows App SDK $($Config.release)"
if ($LASTEXITCODE -ne 0) { throw "WinMDGen failed with exit code $LASTEXITCODE" }

# RADWinUI's own controls describe themselves: build a program that links them and asks
& (Join-Path $PSScriptRoot 'Build.ps1') -Project 'tools\ControlsIndex\ControlsIndex.dpr'
if ($LASTEXITCODE -ne 0) { throw 'Building ControlsIndex.exe failed' }
& (Join-Path $RepoRoot 'tools\ControlsIndex\Win64\Debug\ControlsIndex.exe') `
  (Join-Path $RepoRoot 'src\Framework\RADWinUI.Controls.json')
if ($LASTEXITCODE -ne 0) { throw "ControlsIndex failed with exit code $LASTEXITCODE" }
