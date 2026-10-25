<#
.SYNOPSIS
  Prepares a RADWinUI source release with provenance and checksums.

.DESCRIPTION
  Writes build\release\RADWinUI-<Version> with the layout of the repository,
  so the wizard package finds everything from its own folder:

    (sources)                   every committed file of HEAD (git archive)
    RADWinUI.groupproj          builds bin\XamlCodeGen.exe, the preview host and
                                the IDE package on the user's machine (64-bit IDE)
    RADWinUI32.groupproj        the same for the classic 32-bit IDE
    samples\RADWinUISamples.groupproj
                                the Gallery, Luma and Haven demos
    third_party\WindowsAppSDK\<release>\Microsoft.WindowsAppSDK.Foundation
                                the bootstrap DLL (signed by Microsoft) and its
                                license.txt only
    docs\THIRD-PARTY-NOTICES.md what is redistributed, and under which terms

  No binary of RADWinUI ships: RADWinUI is not code-signed, so
  users build the exe files and the package from source. The script checks that,
  then copies the release to a temporary folder with spaces in its path, hides
  Python and builds the three groups there with MSBuild, as a user's Build All
  does, that copy is deleted afterwards.

  Only the bootstrap DLL is taken from the Windows App SDK packages: it is
  the file the NuGet package places next to an app, which the license lets
  an app redistribute. The .winmd metadata and the rest of the packages stay
  out, scripts\Get-WindowsAppSDK.ps1 fetches them on a machine that needs to
  regenerate the projection.

  It builds into the release folder only. It installs nothing, registers no
  package, writes no registry key and never starts RAD Studio. Commit first:
  the sources come from HEAD, not from the working tree.

  Pass -BdsRoot to use a specific RAD Studio installation without registry
  discovery, the default remains the registered RAD Studio 13 installation.

.EXAMPLE
  .\scripts\Make-Release.ps1 -Version 0.9.0
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidatePattern('^\d+\.\d+\.\d+(-[\w.]+)?$')]
  [string]$Version,
  [string]$BdsRoot
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Release = Join-Path $RepoRoot "build\release\RADWinUI-$Version"
$Commit = (git -C $RepoRoot rev-parse HEAD).Trim()
$LogDir = Join-Path $RepoRoot 'build\logs'
New-Item -ItemType Directory -Force $LogDir | Out-Null
$Sdk = Get-Content (Join-Path $RepoRoot 'build\WindowsAppSDK.json') -Raw | ConvertFrom-Json
$FoundationRel = "third_party\WindowsAppSDK\$($Sdk.release)\Microsoft.WindowsAppSDK.Foundation"
$Foundation = Join-Path $RepoRoot $FoundationRel
$DllRel = 'runtimes\win-x64\native\Microsoft.WindowsAppRuntime.Bootstrap.dll'
if (-not (Test-Path (Join-Path $Foundation $DllRel))) { throw 'Run scripts\Get-WindowsAppSDK.ps1 first' }
if (-not $BdsRoot) { $BdsRoot = (Get-ItemProperty 'HKCU:\Software\Embarcadero\BDS\37.0' -Name RootDir).RootDir }
if (-not $BdsRoot -or -not (Test-Path (Join-Path $BdsRoot 'bin\rsvars.bat'))) { throw "RAD Studio not found at '$BdsRoot'. Pass -BdsRoot <RAD Studio folder>." }
$Bds = $BdsRoot
$Failures = 0
function Check([bool]$Ok, [string]$What) {
  if ($Ok) { Write-Host "  [ok] $What" } else { Write-Host "  [failed] $What" -ForegroundColor Red; $script:Failures++ }
}

if (git -C $RepoRoot status --porcelain) { throw 'Commit source changes before making a release (sources come from HEAD).' }
if (Test-Path $Release) { throw "Release destination already exists: $Release. Choose a new version." }
New-Item -ItemType Directory -Force $Release | Out-Null

Write-Host "Sources of $Commit"
$Zip = Join-Path ([IO.Path]::GetTempPath()) "RADWinUI-$Version-$([guid]::NewGuid()).zip"
git -C $RepoRoot archive --format=zip -o $Zip $Commit
if ($LASTEXITCODE -ne 0) { throw 'git archive failed' }
Expand-Archive $Zip $Release
Remove-Item -LiteralPath $Zip

Write-Host 'Microsoft''s signed redistributable: the bootstrap DLL and its license'
$Target = Join-Path $Release $FoundationRel
New-Item -ItemType Directory -Force (Split-Path (Join-Path $Target $DllRel)) | Out-Null
Copy-Item (Join-Path $Foundation $DllRel) (Join-Path $Target $DllRel)
Copy-Item (Join-Path $Foundation 'license.txt') $Target
Check ((Get-AuthenticodeSignature (Join-Path $Target $DllRel)).Status -eq 'Valid') 'the bootstrap DLL carries Microsoft''s valid signature'

Write-Host 'Checks: a source release'
$Winmd = @(Get-ChildItem $Release -Recurse -Include *.winmd, *.nupkg, *.msix -File)
Check ($Winmd.Count -eq 0) 'no Windows App SDK metadata, packages or MSIX files'
$Binaries = @(Get-ChildItem $Release -Recurse -File -Include *.exe, *.dll, *.bpl, *.dcp, *.dcu, *.bpi, *.lib |
  Where-Object { $_.Name -ne 'Microsoft.WindowsAppRuntime.Bootstrap.dll' })
Check ($Binaries.Count -eq 0) "no prebuilt binaries of RADWinUI, unsigned by policy (found: $(($Binaries | Select-Object -First 3).Name -join ', '))"
# What users build must not need Python
$UsesPython = @(Get-ChildItem $Release -Recurse -File -Include *.dproj, *.groupproj, *.dpk, *.dpr, *.pas |
  Where-Object { $_.FullName -notlike "$Release\tools\*" -and $_.FullName -notlike "$Release\tests\*" } |
  Where-Object { Select-String -LiteralPath $_.FullName -Pattern 'py -3 |python\.exe|xamlcodegen\.py' -Quiet })
Check ($UsesPython.Count -eq 0) "no project or unit runs Python (found: $(($UsesPython | Select-Object -First 3).Name -join ', '))"
Check (Test-Path (Join-Path $Release 'RADWinUI.groupproj')) 'RADWinUI.groupproj (XamlCodeGen, preview host, package of the 64-bit IDE)'
Check (Test-Path (Join-Path $Release 'RADWinUI32.groupproj')) 'RADWinUI32.groupproj (XamlCodeGen, preview host, package of the 32-bit IDE)'
Check (Test-Path (Join-Path $Release 'samples\RADWinUISamples.groupproj')) 'samples\RADWinUISamples.groupproj (Gallery, Luma, Haven)'
Check (Test-Path (Join-Path $Release 'docs\THIRD-PARTY-NOTICES.md')) 'docs\THIRD-PARTY-NOTICES.md'
Check ((Get-Content (Join-Path $Release 'LICENSE') -TotalCount 1) -eq 'MIT License') 'LICENSE: MIT'
Check (Test-Path (Join-Path $Release 'docs\GETTING-STARTED.md')) 'docs\GETTING-STARTED.md'

Write-Host 'Builds from source as a user does: Build All of each group, Python off the PATH, a path with spaces'
$Try = Join-Path ([IO.Path]::GetTempPath()) "RADWinUI release check $([guid]::NewGuid().ToString('N'))"
$TryRoot = Join-Path $Try "RADWinUI-$Version"
New-Item -ItemType Directory -Force $Try | Out-Null
Copy-Item -LiteralPath $Release $TryRoot -Recurse
$SavedPath = $env:PATH
$env:PATH = (($env:PATH -split ';') | Where-Object { $_ -and $_ -notmatch 'Python|WindowsApps' }) -join ';'
try {
  Check (-not (Get-Command py, python -ErrorAction SilentlyContinue)) 'Python is not reachable during the check'
  $RsVars = Join-Path $Bds 'bin\rsvars.bat'
  # Like Build All: no platform is passed, every project builds its own.
  # Each IDE's group builds its package and not the other one.
  foreach ($Group in @(@('RADWinUI', 'Win64\RADWinUIWizard.bpl', 'Win32\RADWinUIWizard32.bpl', '64-bit IDE'),
                       @('RADWinUI32', 'Win32\RADWinUIWizard32.bpl', 'Win64\RADWinUIWizard.bpl', '32-bit IDE'))) {
    Remove-Item "$TryRoot\build\packages" -Recurse -Force -ErrorAction SilentlyContinue
    $Log = Join-Path $LogDir "Release-$($Group[0]).log"
    cmd /c "`"$RsVars`" && msbuild `"$TryRoot\$($Group[0]).groupproj`" /t:Build /p:Config=Release /nologo /v:minimal" > $Log 2>&1
    Check (($LASTEXITCODE -eq 0) -and (Test-Path "$TryRoot\build\packages\$($Group[1])") -and
      -not (Test-Path "$TryRoot\build\packages\$($Group[2])")) `
      "$($Group[0]).groupproj builds $(Split-Path $Group[1] -Leaf) for the $($Group[3]) and no other package (log: $Log)"
  }
  # Both packages for the export check below
  $Log = Join-Path $LogDir 'Release-RADWinUI-again.log'
  cmd /c "`"$RsVars`" && msbuild `"$TryRoot\RADWinUI.groupproj`" /t:Build /p:Config=Release /nologo /v:minimal" > $Log 2>&1

  Check ((Test-Path "$TryRoot\bin\XamlCodeGen.exe") -and (Test-Path "$TryRoot\src\IDE\Preview\Win64\Release\RADWinUIPreview.exe") -and
    (Test-Path "$TryRoot\src\IDE\Preview\Win64\Release\Microsoft.WindowsAppRuntime.Bootstrap.dll")) `
    'the group puts bin\XamlCodeGen.exe and the preview host (with the bootstrap DLL) where the package finds them'
  $Tdump = Join-Path $Bds 'bin\tdump.exe'
  foreach ($Bpl in 'Win32\RADWinUIWizard32.bpl', 'Win64\RADWinUIWizard.bpl') {
    $Exports = & $Tdump -ee "$TryRoot\build\packages\$Bpl" 2>&1 | Select-String -Pattern "8RegisterEv'|::Register\(\)'"
    Check (@($Exports).Count -eq 1) "$Bpl exports one Register"
  }
  foreach ($Demo in 'Gallery', 'Luma', 'Haven') {
    Remove-Item "$TryRoot\samples\$Demo\MainWindow.Xaml.pas"
  }
  $Log = Join-Path $LogDir 'Release-samples.log'
  cmd /c "`"$RsVars`" && msbuild `"$TryRoot\samples\RADWinUISamples.groupproj`" /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" > $Log 2>&1
  foreach ($Demo in 'Gallery', 'Luma', 'Haven') {
    Check (($LASTEXITCODE -eq 0) -and (Test-Path "$TryRoot\samples\$Demo\MainWindow.Xaml.pas") -and
      (Test-Path "$TryRoot\samples\$Demo\Win64\Release\$Demo.exe")) "$Demo builds; its pre-build event regenerated MainWindow.Xaml.pas (log: $Log)"
  }
} finally {
  $env:PATH = $SavedPath
  Remove-Item -LiteralPath $Try -Recurse -Force -ErrorAction SilentlyContinue
}
$Size = (Get-ChildItem $Release -Recurse -File | Measure-Object Length -Sum).Sum / 1MB
Write-Host ("Release folder: {0} ({1:N1} MB)" -f $Release, $Size) -ForegroundColor Green

Write-Host @"

RADWinUI is MIT licensed (LICENSE); the release is not code-signed.

Install in RAD Studio 13 (nothing above was installed or registered; no Python needed):
  1. Install the Windows App Runtime $($Sdk.release) x64 (Microsoft's WindowsAppRuntimeInstall-x64.exe).
  2. Start RAD Studio without administrator rights. Uninstall an older RADWinUI package first.
  3. File > Open Project: $Release\RADWinUI.groupproj in the 64-bit IDE, RADWinUI32.groupproj in the 32-bit IDE
  4. Right-click the project group > Build All.
  5. Right-click the package (RADWinUIWizard.bpl or RADWinUIWizard32.bpl) > Install.
  6. File > New > Other > Delphi Projects > RADWinUI Application, F9. The demos: samples\RADWinUISamples.groupproj.
  Guide: $Release\docs\GETTING-STARTED.md
"@
if ($Failures -gt 0) { Write-Host "Release FAILED ($Failures)" -ForegroundColor Red; exit 1 }
[ordered]@{
  version = $Version
  commit = $Commit
  builtAtUtc = [DateTime]::UtcNow.ToString('o')
  windowsAppSdk = $Sdk.release
  runtimeVersion = $Sdk.runtimeVersion
  compiler = (Get-Item (Join-Path $Bds 'bin\dcc64.exe')).VersionInfo.FileVersion
  platforms = @('Win32 design package', 'Win64 design package', 'Win64 applications')
  contents = 'sources; RADWinUI.groupproj (64-bit IDE) or RADWinUI32.groupproj (32-bit IDE) builds XamlCodeGen.exe, the preview host and the package'
  signed = $false
  validation = 'Source release built end to end (each IDE group and the samples group) from a path with spaces without Python. IDE and clean-machine acceptance are separate.'
} | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $Release 'release-info.json') -Encoding UTF8
$Sums = Get-ChildItem $Release -Recurse -File | Sort-Object FullName | ForEach-Object {
  $Relative = $_.FullName.Substring($Release.Length + 1).Replace('\', '/')
  "$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant())  $Relative"
}
$Sums | Set-Content (Join-Path $Release 'SHA256SUMS.txt') -Encoding UTF8
$Bundle = "$Release.zip"
if (Test-Path -LiteralPath $Bundle) { throw "Bundle already exists: $Bundle" }
Compress-Archive -LiteralPath $Release -DestinationPath $Bundle -CompressionLevel Optimal
"$((Get-FileHash -LiteralPath $Bundle -Algorithm SHA256).Hash.ToLowerInvariant())  $([IO.Path]::GetFileName($Bundle))" |
  Set-Content "$Bundle.sha256" -Encoding ASCII
Write-Host "Archive and checksums: $Bundle"
Write-Host 'Release PASSED'
exit 0
