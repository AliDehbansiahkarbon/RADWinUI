# Made with RADWinUI

Apps that people built with RADWinUI and share as source. Each one lives in a folder of its own, builds from source with the RADWinUI build events like the samples, and comes with screenshots. Use them, learn from them, build on them.

## The apps

| App | What it is | Author |
| --- | --- | --- |
| [Notch](Notch/README.md) | A desk companion that hangs from an edge of the screen: your apps, live AI agent activity, the calendar, notes, music and a focus timer in a notch that opens on hover or with Ctrl+Alt+N. | Ali Dehbansiahkarbon |

Build them all with `community\Community.groupproj`, after `RADWinUI.groupproj` (or `RADWinUI32.groupproj` in the 32-bit IDE) has built `bin\XamlCodeGen.exe`.

## Share your app

1. Fork the repository and create `community\<AppName>\` for your app.
2. Put the source, a `README.md` and a `screenshots\` folder in it, following the rules below.
3. Add your app to `community\Community.groupproj` and one line to the table above.
4. Open a pull request with the **Community app** template (`.github\PULL_REQUEST_TEMPLATE\community-app.md`) and tick every box of its checklist.

The maintainer reviews every pull request. Nothing is merged, and nothing goes online, before the maintainer approves it. The maintainer may ask for changes, decline an app, or remove one later, for example when it stops building or breaks a rule.

## The rules

### Safe, source only

- **Source code only.** No exe, dll, bpl, dcp, dcu, res, ocx, lib or obj files, no archives (zip, 7z, rar, cab), no installers (msi, msix, setup programs). Everything has to build from what is in the folder.
- **No hidden or harmful behaviour.** No obfuscated code, no scripts that download or start programs, no code that sends data home, no telemetry, ads, crypto mining or anything else the user did not ask for.
- **Network access only when the app is about it** (a weather widget, a feed reader), described in its README, and never with data the user did not choose to send.
- **No credentials or personal data.** No API keys, passwords, tokens, certificates, e-mail addresses or names of other people in the code, the settings or the screenshots.
- **Only content you may share.** Code, icons, images, fonts and sounds must be your own or come with a licence that allows it, named in the README.

### Built on RADWinUI

- The app uses the RADWinUI framework: its windows are `TWinUIWindow` descendants with XAML, its UI is WinUI 3. A VCL or FMX app with one WinUI window added does not count.
- It is a Win64 project with a `.dproj` like the samples: `RADWinUIRoot` found two folders up or through `RADWINUI_ROOT`, the pre-build event that runs `scripts\RADWinUI-PreBuild.cmd`, the post-build event that runs `scripts\RADWinUI-PostBuild.cmd`.
- It builds with `.\scripts\Build.ps1 -Project community\<AppName>\<AppName>.dpr -Config Release` on a clean checkout, without warnings that the app introduces, and closes without a memory leak report.
- It needs no change outside its own folder, except one line in the table above and its entry in `community\Community.groupproj`. If the framework itself needs a change, open a separate pull request for it first.

### Really useful

- A real app that solves a real need: a tool, a widget, a utility, a small game with care in it. Not a hello world, not one of the samples with a new name, not a copy of someone else's app.
- It works on Windows 11 in light and dark mode and keeps its data in a sensible place (for example `%LOCALAPPDATA%\<AppName>`).

### Screenshots are mandatory

- At least one PNG of the real app in `community\<AppName>\screenshots\`, taken from the app as it is in the pull request.
- Light and dark mode when the app supports both.
- No personal data, no other people's windows, nothing that is not part of the app.

### A README for every app

`community\<AppName>\README.md`, in English, with:

- what the app does and who it is for, with the screenshots
- how to build and run it
- the author (your name or GitHub account)
- the licence: MIT, like RADWinUI, unless you state another open-source licence that allows anyone to use and change the app
- third-party notices for anything you did not write yourself

### Style

Follow the conventions of the repository ([CONTRIBUTING.md](../docs/CONTRIBUTING.md)): two-space indentation, CRLF line endings, English names and comments, unit names starting with the app's name.

## Licence

Each app is under the licence stated in its README, MIT unless it says otherwise. The rest of the repository stays under its own [LICENSE](../LICENSE).
