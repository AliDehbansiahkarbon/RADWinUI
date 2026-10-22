# Third-party notices

RADWinUI's own code is under the MIT license ([LICENSE](../LICENSE)). This file lists what comes from others, what a RADWinUI release or a RADWinUI app redistributes, and under which terms.

## Microsoft Windows App SDK 2.5.1

Packages `Microsoft.WindowsAppSDK.Foundation` 2.3.12, `.WinUI` 2.3.9, `.InteractiveExperiences` 2.1.9, `.Runtime` 2.5.1, (c) Microsoft Corporation. Microsoft Software License Terms, in `license.txt` of each package, `scripts\Get-WindowsAppSDK.ps1` downloads them from nuget.org.

| What | In the repository | In a release | In an app |
| --- | --- | --- | --- |
| `Microsoft.WindowsAppRuntime.Bootstrap.dll` | no (downloaded) | yes, with `license.txt` | yes, next to the exe |
| `.winmd` metadata | no (downloaded) | no | no |
| `WindowsAppRuntimeInstall-x64.exe` | no (downloaded from Microsoft) | no | optional in an app's own setup, Microsoft's deployment guidance identifies it as redistributable |
| Runtime MSIX packages | no (downloaded) | no | no, end users install the Windows App Runtime from Microsoft |
| Self-contained runtime files (`runtimes-framework\win-x64\native` of Foundation, InteractiveExperiences and WinUI) | no (downloaded) | no | only in a self-contained folder (`Deploy-App.ps1 -SelfContained`), with `license.txt` |
| `src\Generated\*.pas`, `RADWinUI.Xaml.json` | yes | yes | compiled into the exe |

- **Bootstrap DLL.** Section 3.a.i of the license: files the NuGet package places next to an application may be redistributed with it. The bootstrap DLL is such a file (`runtimes\win-x64\native`). Section 3.b: an app that ships it needs license terms that protect the code and Microsoft at least as much as these terms do, and the publisher indemnifies Microsoft for claims about the app.
- **Self-contained runtime.** Section 3.a.i covers files the NuGet packages place next to an application "for both framework package dependent and self-contained deployments". `Deploy-App.ps1 -SelfContained` copies exactly the files `Microsoft.WindowsAppSDK.SelfContained.targets` (package `Microsoft.WindowsAppSDK.Base`) binplaces from the three component packages, plus `Microsoft.WindowsAppSDK.LICENSE.txt` and a `THIRD-PARTY-NOTICES.txt`, section 3.b applies as for the bootstrap DLL. The DLLs stay unmodified and signed by Microsoft, the app's own exe gets the generated manifest.
- **Metadata.** The `.winmd` files are not placed next to an app, so they are not distributable code, the license (section 3, "e") forbids publishing the rest of the software. They stay out of releases. The Pascal units WinMDGen generates from them describe Microsoft's API (names, GUIDs and signatures) and contain no Microsoft code.
- **Windows App Runtime.** Microsoft's current [unpackaged-app deployment guidance](https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/unpackage-winui-app) calls the installer redistributable and directs developers to bundle it with their own installer or setup script. The [runtime download page](https://learn.microsoft.com/en-us/windows/apps/windows-app-sdk/downloads) identifies the standalone installer and the separate redistributable ZIP. An app setup may bundle the unmodified installer for its required architecture and version. RADWinUI's release and `Deploy-App.ps1` output do not include it or the runtime MSIX packages, users can obtain the installer from Microsoft at https://learn.microsoft.com/windows/apps/windows-app-sdk/downloads.

## Microsoft WebView2 1.0.3719.77

`Microsoft.Web.WebView2`, (c) Microsoft Corporation, BSD-style license (`LICENSE.txt` in the package): redistribution in source and binary form is allowed when the copyright notice, the conditions and the disclaimer are kept. WinMDGen reads its metadata. A self-contained app folder includes `Microsoft.Web.WebView2.Core.dll` (`runtimes\win-x64\native_uap`, the file the WebView2 package places next to an app, registered by WinUI's manifest fragment) with the license as `Microsoft.Web.WebView2.LICENSE.txt`, no WebView2 file is in the repository or a release.

## Tools used at build time

- **RAD Studio 13** (Embarcadero license) compiles everything, including RADWinUI's own tools (`bin\XamlCodeGen.exe`), apps contain the Delphi RTL under Embarcadero's redistribution terms.

## Reused code

None. Ideas from mben-dz Delphi WinUI Framework were reviewed, no code reused. No code from the 2022 Embarcadero GetIt WinUI 3 demo.
