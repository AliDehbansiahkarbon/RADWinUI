# Tests

Console and UI Automation test programs, Win64. The scripts in `scripts\` build and run them.

| Folder | What | Run by |
| --- | --- | --- |
| `XamlCodeGen` | generated code of windows, pages and user controls, build-time errors, and that every sample's committed unit is what the generator writes | `Test-Preview.ps1` |
| `Designer` | XAML text edits, the designer model, palette list and icons | `Test-Preview.ps1` |
| `Preview` | preview host, pipe client, menu placement, design-time sample data, every sample `.xaml` in the preview and in one docked host | `Test-Preview.ps1`, `Build-Wizard.ps1` |
| `Wizard` | File > New project and window, built with MSBuild and run | `Test-Wizard.ps1` |
| `Gallery` | the Gallery catalog, themes and navigation | `Test-Gallery.ps1` |
| `Runtime` | the native crash report | `Test-Samples.ps1` |
| `AppServices` | dialogs, filters, `TWinUIApp.Queue` and single instance (`AppServicesTest`) | `Test-Samples.ps1` |
| `Pages` | navigation in a frame inside a NavigationView: parameters, back and forward, KeepAlive, a page that refuses to be left, and a user control used twice | `Test-Samples.ps1` |
| `Windows` | several windows, Close with OnCloseQuery and OnClose, owned and modal windows, ShutdownMode, placement through text and the registry, title bar passthrough | `Test-Samples.ps1` |

`Test-Samples.ps1` drives the samples through UI Automation and checks they close without crashing. UI tests open their windows on a secondary monitor (`RADWINUI_TEST_MONITOR=secondary`) and never take the focus. With `RADWINUI_TEST_MONITOR=offscreen` a window opens outside every monitor instead, for a PC with one screen. Tests that click by screen position need a real monitor.
