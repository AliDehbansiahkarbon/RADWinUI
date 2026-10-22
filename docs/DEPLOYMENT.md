# Deploying a RADWinUI app

You do not need any script to ship a RADWinUI app. It is an ordinary Win64 exe: build it in RAD Studio, sign it with your own certificate and ship it with one Microsoft DLL beside it (a small app), as described in [the usual Delphi way](#the-usual-delphi-way). The PowerShell script in [the second part](#using-the-powershell-script) is optional: it automates the same steps, checks the result, and can also build a self-contained folder.

A RADWinUI app ships in one of two ways:

| | Small app | Self-contained app |
| --- | --- | --- |
| What you ship | `<App>.exe` and `Microsoft.WindowsAppRuntime.Bootstrap.dll`, about 1 MB | the exe with the Windows App Runtime in its folder, about 55 MB |
| What the user installs | Microsoft's free Windows App Runtime 2.5 x64, once per PC, like the VC++ runtime or WebView2 | nothing: copy the folder and run |
| Runtime updates | Windows keeps the installed runtime up to date | only when you ship a new build |
| Choose it when | your users can install a prerequisite, or your setup installs it for them | you want no prerequisite, offline installs or a portable folder |

The small app is what Microsoft calls a *framework-dependent* deployment. The script below builds the
self-contained one with `-SelfContained`.

Either way, nothing else is needed: no .NET, no Delphi packages (the RTL is linked in), no registration, no administrator rights for the app itself. The XAML is compiled into the exe, so no `.xaml` file ships.

## The usual Delphi way

1. **Build.** Open your project in RAD Studio, choose the **Release** configuration and the **Windows 64-bit** platform, then Project > Build. The exe is in `Win64\Release` of the project folder.
2. **Collect the files.** Put these two files in a new folder:
   - `<App>.exe` from `Win64\Release`;
   - `Microsoft.WindowsAppRuntime.Bootstrap.dll`. Projects made with File > New > RADWinUI Application copy it next to the exe on every build. Otherwise take it from the RADWinUI folder: `third_party\WindowsAppSDK\2.5.1\Microsoft.WindowsAppSDK.Foundation\runtimes\win-x64\native\`.

   Add the images, data files or other assets your own code loads, in the same relative places as during development.
3. **Add the license terms.** The bootstrap DLL is Microsoft's distributable code: ship Microsoft's license with it (`license.txt` in the same `Microsoft.WindowsAppSDK.Foundation` folder, for example as `Microsoft.WindowsAppSDK.LICENSE.txt`) and see [Licenses](#licenses).
4. **Sign the exe** with your code-signing certificate:

   ```text
   signtool sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /f MyCertificate.pfx /p <password> <App>.exe
   ```

   Use your certificate authority's timestamp server, or `/a` or `/n "<subject>"` for a certificate in the Windows certificate store. Do not re-sign `Microsoft.WindowsAppRuntime.Bootstrap.dll`: Microsoft has signed it.
5. **Ship** the folder as a ZIP or inside your setup (Inno Setup, InstallAware, MSI and so on), and sign the setup too.
6. **Tell your users about the Windows App Runtime.** They install it once per machine with `WindowsAppRuntimeInstall-x64.exe` from Microsoft's [Windows App SDK downloads](https://learn.microsoft.com/windows/apps/windows-app-sdk/downloads) page (pick the 2.5 runtime). Your setup may also run that installer for them, see [The Windows App Runtime](#the-windows-app-runtime).

To test, copy the folder to a PC without RAD Studio and start the exe. A Release build looks for the bootstrap DLL only next to the exe, Debug builds made by the wizard also try the RADWinUI folder, which an end user does not have.

A self-contained app, which carries the runtime itself, needs about 210 runtime files and a manifest generated from the SDK packages. That layout is easiest with the script below (`-SelfContained`).

## Using the PowerShell script

`scripts\Deploy-App.ps1` builds the project and writes a ready-to-ship folder: a small app by default, a self-contained app with `-SelfContained`.

```text
.\scripts\Deploy-App.ps1 -Project samples\Counter\Counter.dpr
```

1. Builds the project in Release.
2. Writes `build\deploy\Counter`: `Counter.exe`, `Microsoft.WindowsAppRuntime.Bootstrap.dll`, `README.txt` (requirements for the end user), `THIRD-PARTY-NOTICES.txt` and the full `Microsoft.WindowsAppSDK.LICENSE.txt` terms.
3. Copies that folder to a temporary folder outside the repository, clears `RADWINUI_ROOT`, starts the exe there (on a secondary monitor, without taking the focus), waits for its WinUI window, closes it and checks exit code 0.

Pass `-Out <folder>` for another destination (new, empty, or an earlier output of the script: it refuses a folder holding other files), `-Verify $false` to skip the run.
Pass `-Dcc64 <path-to-dcc64.exe>` to select a specific RAD Studio compiler without registry discovery.

Then sign the exe as in step 4 above, and zip the folder or put its files in your setup.

### Self-contained app

```text
.\scripts\Deploy-App.ps1 -Project samples\Counter\Counter.dpr -SelfContained
```

The folder then holds the Windows App Runtime next to the exe instead of the bootstrap DLL, about 55 MB and 210 files, so the end user installs nothing:

- the runtime files the Windows App SDK NuGet packages place next to a self-contained app (`runtimes-framework\win-x64\native` of `Foundation`, `InteractiveExperiences` and `WinUI`: DLLs, `.pri`, language `.mui` folders, `Microsoft.UI.Xaml\Assets`), and `Microsoft.Web.WebView2.Core.dll`;
- a manifest embedded in the exe that registers every runtime class (reg-free WinRT), generated from each package's `package.appxfragment` the way the SDK's `Microsoft.WindowsAppSDK.SelfContained.targets` does it;
- `resources.pri`, a copy of WinUI's `Microsoft.UI.Xaml.Controls.pri`: an unpackaged app's resource index, where WinUI finds its control styles.

At start the app finds `Microsoft.WindowsAppRuntime.dll` next to the exe, loads it and skips the bootstrapper. The check run also asserts that every runtime DLL the app loads comes from its folder and none from an installed runtime (`WindowsApps`).

Trade-offs: no prerequisite, works offline and without the Microsoft Store, but each app carries its own runtime copy (no Windows updates of it, ship a new build for a runtime fix). Push notifications and other features that need the runtime's Singleton package do not work self-contained, as in Microsoft's own self-contained mode. Embedding the manifest changes the exe, so sign it after `Deploy-App.ps1`.

## The Windows App Runtime

End users install it with `WindowsAppRuntimeInstall-x64.exe` from Microsoft's Windows App SDK downloads page: https://learn.microsoft.com/windows/apps/windows-app-sdk/downloads (pick the 2.5 runtime). It installs per machine and is updated by Windows. Without it, the app stops at start with `EWinAppRuntimeError` and the reason from `MddBootstrapInitialize2`, catch it in the `.dpr` to show your own message or start the installer.

Microsoft's deployment guidance calls this `.exe` a redistributable and directs unpackaged apps to bundle it with their own installer or setup script. Your setup may therefore include the unmodified Microsoft installer for the required runtime version and architecture. The folder produced by `Deploy-App.ps1` leaves it as a separate prerequisite, RADWinUI does not bundle the runtime MSIX packages.

Check on a machine (PowerShell, no administrator rights needed):

```text
Get-AppxPackage Microsoft.WindowsAppRuntime.2* | Select-Object Name, Version, Architecture
```

## Licenses

- The bootstrap DLL is distributable code of the Windows App SDK (license section 3.a.i). Your app's license must protect it and Microsoft at least as much as Microsoft's terms (section 3.b). `THIRD-PARTY-NOTICES.txt` in the script's folder says so.
- The self-contained runtime files are distributable code under the same section 3.a.i, which names both framework-dependent and self-contained deployments, the same section 3.b obligations apply. `Microsoft.Web.WebView2.Core.dll` is under the WebView2 BSD-style license, copied as `Microsoft.Web.WebView2.LICENSE.txt`.
- RADWinUI does not redistribute the runtime MSIX packages, the end user gets them from Microsoft.
- If your setup bundles the runtime installer, keep Microsoft's installer and its license information with the setup.

## Not covered yet

- ARM64 builds.

## Framework release candidates

This part is for RADWinUI maintainers, not for app deployment.

```powershell
.\scripts\Make-Release.ps1 -Version 0.9.3-rc.5 -BdsRoot 'C:\Program Files (x86)\Embarcadero\Studio\37.0'
```

Commit all sources first. The script refuses a dirty tree or an existing version
folder. It archives that commit and adds Microsoft's signed bootstrap DLL with its
license, no binary of RADWinUI ships. It then builds the project groups from a copy
in a path with spaces, without Python, as a user's Build All does.
It installs nothing and leaves the installed packages alone.

`release-info.json` records the commit, SDK, compiler and build time.
`SHA256SUMS.txt` covers the release files, the sibling ZIP has its own `.sha256`.
Keep the folder's layout when installing so the wizard can locate its sources.

A successful run shows that the source release builds. Installing it in the IDE and
running apps is checked separately on a second PC. Releases are not code-signed.
