## Community app

<!-- For an app in community/<AppName>/. The rules are in community/README.md. -->

**App:** <!-- name -->
**Author:** <!-- your name or GitHub account -->
**What it does:** <!-- one or two sentences -->

### Checklist

Safe, source only
- [ ] Only source files: no exe, dll, bpl, dcp, dcu, res, ocx, lib or obj files, no archives, no installers
- [ ] No obfuscated code, no scripts that download or start programs, no telemetry, ads or crypto mining
- [ ] Network access only if the app is about it, and described in its README
- [ ] No credentials, keys, tokens or personal data, also not in the screenshots
- [ ] Every icon, image, font, sound and piece of code is my own or licensed for sharing, named in the README

Built on RADWinUI
- [ ] The app uses the RADWinUI framework (TWinUIWindow, XAML, WinUI 3)
- [ ] Win64 `.dproj` with `RADWinUIRoot` / `RADWINUI_ROOT` and the RADWinUI pre-build and post-build events, like the samples
- [ ] `.\scripts\Build.ps1 -Project community\<AppName>\<AppName>.dpr -Config Release` builds on a clean checkout
- [ ] It closes without a memory leak report
- [ ] Nothing changed outside `community\<AppName>\`, except its line in `community\README.md` and its entry in `community\Community.groupproj`

Useful and complete
- [ ] A real, useful app, not a hello world or a copy of a sample
- [ ] Works on Windows 11, in light and dark mode
- [ ] At least one PNG screenshot of the real app in `community\<AppName>\screenshots\` (light and dark when supported)
- [ ] `community\<AppName>\README.md` in English: what it does, the screenshots, how to build, the author, the licence (MIT unless stated), third-party notices

### How I tested it

<!-- Windows version, RAD Studio version, what you tried -->

The maintainer reviews every community app and approves it before it is merged.
