# XamlCodeGen

Generates the Pascal base class of a XAML window. It is a Delphi console tool: `XamlCodeGen.dpr` with `RADWinUI.CodeGen.pas` (the generator), `RADWinUI.CodeGen.Bindings.pas` (binding and converter checks) and `RADWinUI.CodeGen.Xml.pas` (its XML reader and writer). `RADWinUI.groupproj` builds it into `bin\XamlCodeGen.exe`.

```text
bin\XamlCodeGen.exe samples\Counter\MainWindow.xaml     # one window
bin\XamlCodeGen.exe samples\Counter                     # every .xaml in a folder
```

Every project's pre-build event runs it on the project folder, `scripts\Build.ps1` builds it when needed and does the same. The designer calls it with snapshots of the open XAML and Pascal editor buffers: `--ide-request <temporary.json>` reads `path`, `xaml` and `pas` and replaces the file with `text` (the generated Pascal) or `error`. It never writes the user's source files then, the IDE updates the generated unit through its buffer.

| Input | Output |
| --- | --- |
| `MainWindow.xaml`: `<Window x:Class="TMainWindow" Title="...">` with one content element | `MainWindow.Xaml.pas`: `TMainWindowBase = class(TWinUIWindow)` |
| `MainWindow.pas`: `TMainWindow = class(TMainWindowBase)` with published handlers | wiring code in the base constructor |
| `src\Generated\RADWinUI.Xaml.json` (written by WinMDGen) | element types and events |
| `src\Framework\RADWinUI.Controls.json` (written by `tools\ControlsIndex`) | RADWinUI's own `rw:` controls |

- Each `x:Name` element becomes a protected field of its wrapper type (`CounterText: TWinUITextBlock`).
- `Click="ResetClick"` attributes and published methods named `<x:Name><Event>` (`IncrementButtonClick`) are wired to the event. A handler is `(Sender: TObject; E: <args>)` or `(Sender: TObject)`.
- Event attributes are removed from the embedded XAML, because `XamlReader.Load` rejects them, unnamed elements with events get an `_rwN` name.
- `{Binding}` paths are checked against `DataContextType="TName"` on `<Window>` and `x:DataType` on a `DataTemplate`.
- `Converter={StaticResource Name}` must name a built-in converter, one registered with `TWinUIApp.RegisterConverter('Name', ...)` in the project's sources, or an `x:Key` of the XAML, a `Format` parameter needs one `%s`.
- `DataContextType` also gives the base a typed `ViewModel` property.
- Design-time values (`d:` and `mc:` attributes and elements) never reach the app.
- Errors (missing handler, wrong signature, an `x:Name` that hides a window member, an unknown binding path or converter) stop the build with the file, the line and the reason.

The generated unit names its source XAML and the tool version, keeps XAML order and marks each field and wired event with its XAML line. Bump `CodeGenVersion` in `RADWinUI.CodeGen.pas` when the generated code changes shape.

Tests: `tests\XamlCodeGen\XamlCodeGenTest.dpr` (run by `scripts\Test-Preview.ps1`) checks the generated code, every error message, and that each sample's committed `*.Xaml.pas` is exactly what the tool writes.
