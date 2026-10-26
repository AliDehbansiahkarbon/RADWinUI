<#
.SYNOPSIS
  Builds Gallery and runs its native control checks without mouse or UI Automation.
#>
[CmdletBinding()]
param(
  [string]$Dcc64,
  [switch]$NoBuild,
  # secondary: another monitor without the focus, offscreen: outside every monitor
  [ValidateSet('secondary', 'offscreen')]
  [string]$Monitor = 'secondary'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Logs = Join-Path $RepoRoot 'build\logs'
New-Item -ItemType Directory -Force $Logs | Out-Null
if (-not $NoBuild) {
  foreach ($Project in 'samples\Gallery\Gallery.dpr', 'tests\Gallery\GalleryNativeTest.dpr') {
    & (Join-Path $PSScriptRoot 'Build.ps1') -Project $Project -Config Release -Dcc64 $Dcc64
    if ($LASTEXITCODE -ne 0) { throw "Build failed: $Project" }
  }
}
$Exe = Join-Path $RepoRoot 'tests\Gallery\Win64\Release\GalleryNativeTest.exe'
$SavedMonitor = $env:RADWINUI_TEST_MONITOR
$Log = Join-Path $Logs 'GalleryNativeTest.log'
$Process = $null
try {
  $env:RADWINUI_TEST_MONITOR = $Monitor
  $Process = Start-Process -FilePath $Exe -WorkingDirectory (Split-Path $Exe) -WindowStyle Hidden `
    -RedirectStandardOutput $Log -RedirectStandardError (Join-Path $Logs 'GalleryNativeTest.err') -PassThru
  $null = $Process.Handle # without it ExitCode stays empty after the process ends
  if (-not $Process.WaitForExit(20000)) { throw 'Gallery native test exceeded 20 seconds' }
  $Output = Get-Content $Log -Raw
  Write-Host $Output
  if (($Process.ExitCode -ne 0) -or -not $Output.Contains('Gallery native test PASSED')) {
    throw "Gallery native test failed (exit $($Process.ExitCode)), see $Log"
  }
} finally {
  if ($Process -and -not $Process.HasExited) { $Process.Kill() }
  if ($Process) { $Process.Dispose() }
  $env:RADWINUI_TEST_MONITOR = $SavedMonitor
}
