[CmdletBinding()]
param(
  [ValidateSet('Debug', 'Release')]
  [string]$Config = 'Release',
  [string]$Dcc64,
  [switch]$NoBuild,
  # secondary: another monitor without the focus, offscreen: outside every monitor
  [ValidateSet('secondary', 'offscreen')]
  [string]$Monitor = 'secondary'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not $NoBuild) {
  & (Join-Path $PSScriptRoot 'Build.ps1') -Project samples\Lucent\Lucent.dpr -Config $Config -Dcc64 $Dcc64
  if ($LASTEXITCODE -ne 0) { throw 'Lucent build failed' }
}
$env:RADWINUI_TEST_MONITOR = $Monitor
$LogDir = Join-Path $RepoRoot 'build\logs'
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$Report = Join-Path $LogDir "Lucent-smoke-$PID.txt"
$Exe = Join-Path $RepoRoot "samples\Lucent\Win64\$Config\Lucent.exe"
$Proc = Start-Process $Exe -ArgumentList '-smoke-test', ('"' + $Report + '"'), '-nosim' -WindowStyle Hidden -PassThru
$null = $Proc.Handle
try {
  if (-not $Proc.WaitForExit(60000)) { throw 'Lucent smoke test timed out' }
  if ($Proc.ExitCode -ne 0) { throw "Lucent exited with $($Proc.ExitCode)" }
  $Result = [IO.File]::ReadAllText($Report)
  if (-not $Result.StartsWith('PASS:')) { throw $Result }
  Write-Host $Result
} finally {
  if (-not $Proc.HasExited) { $Proc.Kill() }
}
