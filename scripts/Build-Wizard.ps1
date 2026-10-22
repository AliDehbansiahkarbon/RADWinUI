<#
.SYNOPSIS
  Builds the RADWinUI design-time packages for the RAD Studio IDEs.

.DESCRIPTION
  Builds, with MSBuild, the two packages the project groups install:
  packages\RADWinUIWizard.dproj (Win64, the 64-bit IDE, bin64\bds.exe)
  and packages\RADWinUIWizard32.dproj (Win32, the classic IDE, bin\bds.exe).
  Each .bpl goes to build\packages\<platform>. Then builds
  the live preview host its Tools > RADWinUI Preview command starts
  (src\IDE\Preview\Win64\Release\RADWinUIPreview.exe) and runs
  Test-WizardPackage.ps1. It does not install or register anything.

.EXAMPLE
  .\scripts\Build-Wizard.ps1
#>
[CmdletBinding()]
param(
  [ValidateSet('Win32', 'Win64')]
  [string[]]$Platform = @('Win32', 'Win64')
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Bds = (Get-ItemProperty 'HKCU:\Software\Embarcadero\BDS\37.0' -Name RootDir).RootDir
$Failed = $false

foreach ($Target in $Platform) {
  # One package project per IDE: RADWinUIWizard (Win64), RADWinUIWizard32 (Win32)
  $Name = if ($Target -eq 'Win32') { 'RADWinUIWizard32' } else { 'RADWinUIWizard' }
  $Project = Join-Path $RepoRoot "packages\$Name.dproj"
  $Log = Join-Path $RepoRoot "build\logs\$Name-$Target.log"
  New-Item -ItemType Directory -Force -Path (Split-Path $Log) | Out-Null
  Write-Host "Building $Name ($Target)"
  cmd /c "`"$(Join-Path $Bds 'bin\rsvars.bat')`" && msbuild `"$Project`" /t:Build /p:Config=Release /p:Platform=$Target /nologo /v:minimal" > $Log 2>&1
  $Bpl = Join-Path $RepoRoot "build\packages\$Target\$Name.bpl"
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path $Bpl)) {
    $Failed = $true
    Get-Content $Log | Select-String -Pattern 'error|warning' | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }
    Write-Host "FAILED (log: $Log)" -ForegroundColor Red
  } else {
    Write-Host "Built $Bpl" -ForegroundColor Green
  }
}
& (Join-Path $PSScriptRoot 'Build.ps1') -Project 'src\IDE\Preview\RADWinUIPreview.dpr' -Config Release | Out-Null
if ($LASTEXITCODE -ne 0) {
  $Failed = $true
  Write-Host 'FAILED: RADWinUIPreview (log: build\logs\RADWinUIPreview.log)' -ForegroundColor Red
} else {
  Write-Host "Built $(Join-Path $RepoRoot 'src\IDE\Preview\Win64\Release\RADWinUIPreview.exe')" -ForegroundColor Green
}
# Where Tools > RADWinUI Preview goes, on a menu shaped like the IDE's
& (Join-Path $PSScriptRoot 'Build.ps1') -Project 'tests\Preview\PreviewMenuTest.dpr' | Out-Null
& (Join-Path $RepoRoot 'tests\Preview\Win64\Debug\PreviewMenuTest.exe')
if ($LASTEXITCODE -ne 0) { $Failed = $true }
if ($Failed) { exit 1 }
# Checks the IDE would only report on install (duplicate wizard registration)
& (Join-Path $PSScriptRoot 'Test-WizardPackage.ps1')
exit $LASTEXITCODE
