# Framework

Developer-facing API on top of the generated projection: `TWinUIApplication`, `TWinUIWindow`, control wrappers with Pascal properties, events as method pointers, WinRT errors as Delphi exceptions, and `{Binding}` support.

The API is described in [docs/FRAMEWORK-API.md](FRAMEWORK-API.md). `RADWinUI.Pages` has pages (`TWinUIXamlPage`) and the frame that navigates between them (`TWinUIPageFrame`), `RADWinUI.Dialogs` the message boxes and pickers, `RADWinUI.Notifications` Windows notifications, `RADWinUI.Resources` the app's texts in several languages. `RADWinUI.CustomControls` lets Delphi classes be XAML elements, `RADWinUI.Controls` holds RADWinUI's own controls built that way, `RADWinUI.TabBars` the six animated tab bars, `RADWinUI.ActionButtons` the six animated buttons and `RADWinUI.DBControls` the seventeen data-aware controls, see [docs/CUSTOM-CONTROLS.md](CUSTOM-CONTROLS.md).
