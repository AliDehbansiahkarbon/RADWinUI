<#
.SYNOPSIS
  Builds a RADWinUI Delphi project for Win64 with the command-line compiler.

.DESCRIPTION
  Finds dcc64.exe of the newest RAD Studio installed (or the one given with
  -Dcc64), compiles the project into <project folder>\Win64\<Config> and
  writes the full compiler output to build\logs\<project>.log.

.PARAMETER Project
  The .dpr to build. Defaults to the Counter sample.

.PARAMETER Config
  Debug (default) or Release.

.PARAMETER Dcc64
  Full path of dcc64.exe, when the registry lookup picks the wrong version.

.PARAMETER Run
  Runs the program after a successful build.

.EXAMPLE
  .\scripts\Build.ps1
  .\scripts\Build.ps1 -Run
  .\scripts\Build.ps1 -Project samples\Counter\Counter.dpr -Config Release
#>
[CmdletBinding()]
param(
  [string]$Project = 'samples\Counter\Counter.dpr',
  [ValidateSet('Debug', 'Release')]
  [string]$Config = 'Debug',
  [string]$Dcc64,
  [switch]$Run
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot

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
  Write-Host "Using RAD Studio $($Bds.Version) at $BdsRoot"
}

$ProjectPath = Resolve-Path (Join-Path $RepoRoot $Project)
$ProjectDir = Split-Path -Parent $ProjectPath
$ProjectName = [IO.Path]::GetFileNameWithoutExtension($ProjectPath)
$OutDir = Join-Path $ProjectDir "Win64\$Config"
$DcuDir = Join-Path $OutDir 'dcu'
$LogDir = Join-Path $RepoRoot 'build\logs'
New-Item -ItemType Directory -Force -Path $OutDir, $DcuDir, $LogDir | Out-Null
$Log = Join-Path $LogDir "$ProjectName.log"

$Lib = Join-Path $BdsRoot "lib\win64\$($Config.ToLowerInvariant())"
$LibRelease = Join-Path $BdsRoot 'lib\win64\release'
$Search = @(
  $Lib, $LibRelease,
  (Join-Path $RepoRoot 'src\Interop'),
  (Join-Path $RepoRoot 'src\Generated'),
  (Join-Path $RepoRoot 'src\Runtime'),
  (Join-Path $RepoRoot 'src\Framework')
) -join ';'

$DccArgs = @(
  '-B', '-Q',
  "-E$OutDir", "-NU$DcuDir",
  "-U$Search", "-I$Search", "-R$Search",
  '-NSSystem;Winapi;System.Win',
  '-W-SYMBOL_PLATFORM', '-W-UNIT_PLATFORM'
)
if ($Config -eq 'Debug') {
  $DccArgs += '-$D+', '-$L+', '-$Y+', '-$O-', '-V', '-DDEBUG'
} else {
  $DccArgs += '-$D-', '-$O+', '-DRELEASE'
}
$DccArgs += "$ProjectPath"

# Build bin\XamlCodeGen.exe when it is missing or older than its sources
$CodeGen = Join-Path $RepoRoot 'bin\XamlCodeGen.exe'
$CodeGenSources = @(Get-ChildItem (Join-Path $RepoRoot 'tools\XamlCodeGen\*') -Include *.pas, *.dpr -File)
if (-not (Test-Path $CodeGen) -or @($CodeGenSources | Where-Object { $_.LastWriteTime -gt (Get-Item $CodeGen).LastWriteTime })) {
  $CodeGenDcu = Join-Path $RepoRoot 'build\temp\codegen-dcu'
  New-Item -ItemType Directory -Force (Split-Path $CodeGen), $CodeGenDcu | Out-Null
  & $Dcc64 -B -Q '-NSSystem' "-E$(Split-Path $CodeGen)" "-NU$CodeGenDcu" "-U$LibRelease" `
    (Join-Path $RepoRoot 'tools\XamlCodeGen\XamlCodeGen.dpr') > (Join-Path $LogDir 'XamlCodeGen.log')
  if ($LASTEXITCODE -ne 0) { Write-Host 'Building XamlCodeGen.exe FAILED (log: build\logs\XamlCodeGen.log)' -ForegroundColor Red; exit 1 }
}

# XAML windows: regenerate <Name>.Xaml.pas from each .xaml next to the project
$XamlFiles = @(Get-ChildItem $ProjectDir -Filter *.xaml -File)
if ($XamlFiles) {
  & $CodeGen ($XamlFiles | ForEach-Object FullName)
  if ($LASTEXITCODE -ne 0) { Write-Host 'XamlCodeGen FAILED' -ForegroundColor Red; exit $LASTEXITCODE }
}
Write-Host "Building $ProjectName ($Config, Win64)"
$Started = Get-Date
# From the project folder, like the IDE: 'in' paths in the .dpr are relative to it
Push-Location $ProjectDir
try {
  & $Dcc64 @DccArgs 2>&1 | Tee-Object -FilePath $Log
  $ExitCode = $LASTEXITCODE
} finally {
  Pop-Location
}
$Elapsed = (Get-Date) - $Started
if ($ExitCode -ne 0) {
  Write-Host "Build FAILED after $([int]$Elapsed.TotalSeconds) s. Full output: $Log" -ForegroundColor Red
  exit $ExitCode
}
# WinUI apps load the bootstrap DLL from their own folder
$Release = (Get-Content (Join-Path $RepoRoot 'build\WindowsAppSDK.json') -Raw | ConvertFrom-Json).release
$Bootstrap = Join-Path $RepoRoot "third_party\WindowsAppSDK\$Release\Microsoft.WindowsAppSDK.Foundation\runtimes\win-x64\native\Microsoft.WindowsAppRuntime.Bootstrap.dll"
if ((Test-Path $Bootstrap) -and -not (Test-Path (Join-Path $OutDir 'Microsoft.WindowsAppRuntime.Bootstrap.dll'))) {
  Copy-Item $Bootstrap $OutDir
}
Write-Host "Build succeeded in $([int]$Elapsed.TotalSeconds) s: $OutDir\$ProjectName.exe" -ForegroundColor Green

if ($Run) {
  $Exe = Join-Path $OutDir "$ProjectName.exe"
  & $Exe
  exit $LASTEXITCODE
}
