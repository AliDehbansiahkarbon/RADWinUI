<#
.SYNOPSIS
  Checks the wizard packages for problems the IDE only reports on install.

.DESCRIPTION
  No IDE needed. Fails when:
  - the package name is the name of a unit it contains, or a contained unit name
    is the namespace of another (the IDE would call one Register twice:
    "Cannot register Wizard ..., twice");
  - more or less than one contained unit declares Register;
  - two wizards return the same GetIDString;
  - Register passes the same wizard class to RegisterPackageWizard twice;
  - a built .bpl in build\packages exports more than one Register;
  - the two packages (RADWinUIWizard for the 64-bit IDE, RADWinUIWizard32 for the
    32-bit one) do not contain the same units.
  Build-Wizard.ps1 runs it after building.

.EXAMPLE
  .\scripts\Test-WizardPackage.ps1
#>
[CmdletBinding()]
param(
  # Folder with the .dpk (default packages), unit paths in it are relative to it
  [string]$Dir,
  [string]$BdsRoot
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not $Dir) { $Dir = Join-Path $RepoRoot 'packages' }
$Failures = 0

function Check([bool]$Ok, [string]$What) {
  if ($Ok) { Write-Host "  [ok] $What" } else { Write-Host "  [failed] $What"; $script:Failures++ }
}

Write-Host 'Wizard packages'
$AllUnits = @{}
foreach ($Dpk in Get-ChildItem $Dir -Filter *.dpk) {
# Without comments: they may mention 'contains' or 'package'
$DpkText = (Get-Content $Dpk.FullName -Raw) -replace '(?s)\{[^$][^}]*\}|\(\*.*?\*\)|//[^\r\n]*', ' '
$Package = [regex]::Match($DpkText, '(?im)^\s*package\s+([\w.]+)\s*;').Groups[1].Value
$Contains = [regex]::Match($DpkText, '(?is)\bcontains\b(.*?);').Groups[1].Value
$Units = [regex]::Matches($Contains, "([\w.]+)\s+in\s+'([^']+)'") | ForEach-Object {
  [pscustomobject]@{ Name = $_.Groups[1].Value; File = Join-Path $Dir $_.Groups[2].Value }
}
Check ($Units.Count -gt 0) "$($Dpk.Name): package $Package contains $($Units.Count) units"
Check (-not ($Units | Where-Object { $_.Name -eq $Package })) "the package name $Package is not the name of a contained unit"
$Nested = foreach ($A in $Units) { foreach ($B in $Units) { if ($B.Name -like "$($A.Name).*") { "$($A.Name) / $($B.Name)" } } }
Check (-not $Nested) "no contained unit name is the namespace of another ($($Nested -join ', '))"

# Register and wizard IDs, from the sources
$Ids = @{}
$RegisteringUnits = @()
$Registered = @()
foreach ($U in $Units) {
  $Text = Get-Content $U.File -Raw
  $Interface = ($Text -split '(?im)^\s*implementation\s*$')[0]
  if ($Interface -match '(?im)^\s*procedure\s+Register\s*;') { $RegisteringUnits += $U.Name }
  foreach ($M in [regex]::Matches($Text, "(?is)function\s+(\w+)\.GetIDString\s*:\s*string\s*;\s*begin\s*Result\s*:=\s*'([^']+)'")) {
    $Ids[$M.Groups[1].Value] = $M.Groups[2].Value
  }
  $Body = [regex]::Match($Text, '(?is)procedure\s+Register\s*;\s*begin(.*?)\bend\s*;').Groups[1].Value
  $Registered += [regex]::Matches($Body, 'RegisterPackageWizard\s*\(\s*(\w+)\.Create') | ForEach-Object { $_.Groups[1].Value }
}
Check ($RegisteringUnits.Count -eq 1) "exactly one unit declares Register ($($RegisteringUnits -join ', '))"
$IdValues = @($Ids.Values)
Check ($IdValues.Count -eq @($IdValues | Sort-Object -Unique).Count) "wizard IDs are unique ($(($Ids.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '))"
Check ($Registered.Count -eq @($Registered | Sort-Object -Unique).Count) "Register registers each wizard class once ($($Registered -join ', '))"
Check (-not ($Registered | Where-Object { -not $Ids.ContainsKey($_) })) 'every registered wizard has a GetIDString'
$AllUnits[$Package] = ($Units | ForEach-Object { "$($_.Name)=$($_.File)" }) -join ';'

# Built packages: one Register export each
if (-not $BdsRoot) { $BdsRoot = (Get-ItemProperty 'HKCU:\Software\Embarcadero\BDS\37.0' -Name RootDir).RootDir }
$Tdump = Join-Path $BdsRoot 'bin\tdump.exe'
foreach ($Bpl in Get-ChildItem (Join-Path $RepoRoot 'build\packages') -Recurse -Filter "$Package.bpl" -ErrorAction SilentlyContinue) {
  $Exports = & $Tdump -ee $Bpl.FullName 2>&1 | Select-String -Pattern "8RegisterEv'|::Register\(\)'" | ForEach-Object { $_.Line.Trim() }
  Check (@($Exports).Count -eq 1) "$($Bpl.Directory.Name)\$($Bpl.Name) exports one Register"
}
}
Check ($AllUnits.Count -eq 2) "two packages, one per IDE ($($AllUnits.Keys -join ', '))"
Check (@($AllUnits.Values | Sort-Object -Unique).Count -eq 1) 'both packages contain the same units from the same files'

if ($Failures -gt 0) {
  Write-Host "Wizard package check FAILED ($Failures)"
  exit 1
}
Write-Host 'Wizard package check PASSED'
exit 0
