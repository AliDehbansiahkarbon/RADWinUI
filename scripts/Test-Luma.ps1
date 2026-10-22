[CmdletBinding()]
param(
  [ValidateSet('Debug', 'Release')]
  [string]$Config = 'Release',
  [string]$Dcc64,
  [switch]$NoBuild
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not $NoBuild) {
  & (Join-Path $PSScriptRoot 'Build.ps1') -Project samples\Luma\Luma.dpr -Config $Config -Dcc64 $Dcc64
  if ($LASTEXITCODE -ne 0) { throw 'Luma build failed' }
}
$env:RADWINUI_TEST_MONITOR = 'secondary'
$LogDir = Join-Path $RepoRoot 'build\logs'
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$Report = Join-Path $LogDir "Luma-smoke-$PID.txt"
$Exe = Join-Path $RepoRoot "samples\Luma\Win64\$Config\Luma.exe"
$Proc = Start-Process $Exe -ArgumentList '-smoke-test', ('"' + $Report + '"') -WindowStyle Hidden -PassThru
$null = $Proc.Handle
try {
  if (-not $Proc.WaitForExit(15000)) { throw 'Luma smoke test timed out' }
  if ($Proc.ExitCode -ne 0) { throw "Luma exited with $($Proc.ExitCode)" }
  $Result = [IO.File]::ReadAllText($Report)
  if (-not $Result.StartsWith('PASS:')) { throw $Result }
  Write-Host $Result
} finally {
  if (-not $Proc.HasExited) { $Proc.Kill() }
}
