# Tests

Console and UI Automation test programs, Win64. The scripts in `scripts\` build and run them.

| Folder | What | Run by |
| --- | --- | --- |
| `XamlCodeGen` | generated code, build-time errors, and that every sample's committed unit is what the generator writes | `Test-Preview.ps1` |
| `Designer` | XAML text edits, the designer model, palette list and icons | `Test-Preview.ps1` |
| `Preview` | preview host, pipe client, menu placement, design-time sample data | `Test-Preview.ps1`, `Build-Wizard.ps1` |
| `Wizard` | File > New project and window, built with MSBuild and run | `Test-Wizard.ps1` |
| `Gallery` | the Gallery catalog, themes and navigation | `Test-Gallery.ps1` |
| `Runtime` | the native crash report | `Test-Samples.ps1` |

`Test-Samples.ps1` drives the samples through UI Automation and checks they close without crashing. UI tests open their windows on a secondary monitor (`RADWINUI_TEST_MONITOR=secondary`) and never take the focus.
