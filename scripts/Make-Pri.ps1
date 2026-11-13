<#
.SYNOPSIS
  Builds the resources.pri of a RADWinUI app from its Strings\<language>\*.resw files.

.DESCRIPTION
  An unpackaged WinUI app finds its strings in resources.pri next to the exe: XAML
  applies x:Uid from it, and TWinUIResources.GetString reads it. This script indexes
  <ProjectDir>\Strings with makepri.exe of the Windows SDK into <OutDir>\resources.pri,
  every language in that one file (makepri's default configuration would put each
  language in a resource pack of its own, which an unpackaged app never loads).
  -Merge adds other .pri files, as Deploy-App.ps1 does with WinUI's own for a
  self-contained app. Without a Strings folder it does nothing. Without the Windows
  SDK it warns and the app keeps the texts written in its XAML.

.EXAMPLE
  .\scripts\Make-Pri.ps1 -ProjectDir samples\Quill -OutDir samples\Quill\Win64\Debug
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$ProjectDir,
  [Parameter(Mandatory)]
  [string]$OutDir,
  [string[]]$Merge = @(),
  [string]$DefaultLanguage = 'en-US'
)

$ErrorActionPreference = 'Stop'
$ProjectDir = [IO.Path]::GetFullPath($ProjectDir)
$OutDir = [IO.Path]::GetFullPath($OutDir)
$Strings = Join-Path $ProjectDir 'Strings'
if (-not (Get-ChildItem $Strings -Recurse -Filter *.resw -ErrorAction SilentlyContinue)) { exit 0 }

function Find-MakePri([string]$Bin) {
  Get-ChildItem (Join-Path $Bin '*\x64\makepri.exe') -ErrorAction SilentlyContinue |
    Where-Object { $_.Directory.Parent.Name -match '^\d+(\.\d+)+$' } |
    Sort-Object { [version]$_.Directory.Parent.Name } | Select-Object -Last 1
}
# The BuildTools package Get-WindowsAppSDK.ps1 downloads, else an installed Windows SDK
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Sdk = Get-Content (Join-Path $RepoRoot 'build\WindowsAppSDK.json') -Raw | ConvertFrom-Json
$MakePri = Find-MakePri (Join-Path $RepoRoot "third_party\WindowsAppSDK\$($Sdk.release)\Microsoft.Windows.SDK.BuildTools\bin")
$Kits = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots' -ErrorAction SilentlyContinue).KitsRoot10
if (-not $MakePri -and $Kits) { $MakePri = Find-MakePri (Join-Path $Kits 'bin') }
if (-not $MakePri) {
  Write-Host 'RADWinUI : warning RW1004 : makepri.exe was not found, resources.pri was not built: the app shows the texts written in its XAML. Run scripts\Get-WindowsAppSDK.ps1 once, or install the Windows SDK.'
  exit 0
}

# Index a copy: the project folder holds much more than strings
$Work = Join-Path ([IO.Path]::GetTempPath()) ("RADWinUI-pri-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $Work | Out-Null
try {
  Copy-Item $Strings (Join-Path $Work 'Strings') -Recurse
  foreach ($Pri in $Merge) { Copy-Item $Pri $Work }
  $Config = Join-Path $Work 'priconfig.xml'
  @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<resources targetOsVersion="10.0.0" majorVersion="1">
  <index root="\" startIndexAt="\">
    <default>
      <qualifier name="Language" value="$DefaultLanguage"/>
    </default>
    <indexer-config type="folder" foldernameAsQualifier="true" filenameAsQualifier="true" qualifierDelimiter="."/>
    <indexer-config type="resw" convertDotsToSlashes="true" initialPath=""/>
    <indexer-config type="PRI"/>
  </index>
</resources>
"@ | Set-Content $Config -Encoding utf8
  New-Item -ItemType Directory -Force $OutDir | Out-Null
  $Output = & $MakePri.FullName new /pr $Work /cf $Config /of (Join-Path $OutDir 'resources.pri') /in (Split-Path $ProjectDir -Leaf) /o 2>&1
  if ($LASTEXITCODE -ne 0) {
    $Output | Out-Host
    Write-Host "$PSCommandPath : error RW1005 : makepri.exe could not build resources.pri from $Strings"
    exit 1
  }
} finally {
  Remove-Item $Work -Recurse -Force -ErrorAction SilentlyContinue
}
