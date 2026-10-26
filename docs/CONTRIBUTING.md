# Contributing

Thank you for helping. RADWinUI is a Delphi project, contributions are code, tests, documentation, samples and good bug reports.

## Reporting a problem

Open an issue with:

- your RAD Studio version, the IDE you use (32-bit or 64-bit) and your Windows version;
- what you did, what you expected and what happened;
- the `.xaml` file and the window unit if it is about a window;
- `%TEMP%\RADWinUI\ide.log` for IDE problems, or the newest report in `%LOCALAPPDATA%\RADWinUI\Crashes` if an app closed unexpectedly.

## Building and testing

1. Run `scripts\Get-WindowsAppSDK.ps1` once in a clone.
2. Open `RADWinUI.groupproj` (64-bit IDE) or `RADWinUI32.groupproj` (32-bit IDE) and use Build All, or run `scripts\Build-Wizard.ps1`.
3. Run the tests that cover your change (PowerShell, from the repository folder):

```text
.\scripts\Test-Preview.ps1 -Config Release   # preview host, designer edits, XamlCodeGen
.\scripts\Test-Samples.ps1 -Config Release   # the samples, through UI Automation
.\scripts\Test-Wizard.ps1                    # File > New project built with MSBuild and run
.\scripts\Test-Gallery.ps1                   # Gallery
.\scripts\Test-Luma.ps1                      # Luma
.\scripts\Test-Haven.ps1                     # Haven
.\scripts\Test-Lucent.ps1                    # Lucent
```

UI tests open their windows on a secondary monitor when there is one and never take the focus.

## Rules for code

- English for code, comments, docs and commit messages.
- Unit prefix `RADWinUI.`, two-space indentation, CRLF line endings.
- No WinUI code inside the RAD Studio process: the designer and preview run in their own process.
- XAML text is the single source of truth, the designer edits it in small, undoable changes.
- Framework units use classic RTTI (`System.TypInfo`), not `System.Rtti` or `System.Generics.Collections`, to keep apps small.
- Never edit `src\Generated` by hand: change the generator and regenerate.
- Every bug fix gets a regression test where it can.

## Pull requests

Keep a pull request to one topic, describe what it changes and how you tested it, and include the tests you ran.

By contributing you agree that your contribution is released under the MIT License of this repository.
