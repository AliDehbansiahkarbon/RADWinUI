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
| `VclHost` | `TWinUIHost` on a VCL form: inline XAML, the island's parent and size, FindElement, Click and naming-convention handlers, `{Binding}`, theme, load errors, focus, a recreated handle, reloads and shutdown | `Test-Samples.ps1` |
| `Windows` | several windows, Close with OnCloseQuery and OnClose, owned and modal windows, ShutdownMode, placement through text and the registry, title bar passthrough | `Test-Samples.ps1` |
| `CustomControls` | RADWinUI's own controls; `OverlayControlsTest` also checks the automation peers of the NotchPanel and the GlowTile | `Test-Samples.ps1` (Overlay), by hand (the others) |
| `Localization` | `x:Uid` texts from `resources.pri`, `TWinUIResources.GetString` with its fallbacks, `TWinUIApp.Language` before and after `Run`, right to left, the dialog texts | `Test-Samples.ps1` |

`Test-Samples.ps1` drives the samples through UI Automation and checks they close without crashing. In TabBars, ActionButtons and DataControls it also checks what a screen reader sees: a tab bar is a named `Tab` whose tabs are selectable `TabItem`s, an action button is a named button that Invoke clicks, the DBNavigator is a toolbar of named buttons. UI tests open their windows on a secondary monitor (`RADWINUI_TEST_MONITOR=secondary`) and never take the focus. With `RADWINUI_TEST_MONITOR=offscreen` a window opens outside every monitor instead, for a PC with one screen. Tests that click by screen position need a real monitor.
