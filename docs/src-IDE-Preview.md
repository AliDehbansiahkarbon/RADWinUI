# Live preview

A separate Win64 process that renders a window's XAML with the real WinUI runtime, so a WinUI crash never affects RAD Studio.

```
.\scripts\Build.ps1 -Project src\IDE\Preview\RADWinUIPreview.dpr -Config Release
src\IDE\Preview\Win64\Release\RADWinUIPreview.exe samples\Counter\MainWindow.xaml
```

- `RADWinUIPreview <file.xaml>` watches the file and reloads when it changes.
- `RADWinUIPreview --pipe <name>` serves `\\.\pipe\<name>` for the IDE: send `LOAD <path>`, a line feed and the XAML text, the answer is `OK` or `ERROR <message>`. `CLOSE`, or disconnecting, ends the host.
- `RADWinUIPreview --pipe <name> --parent <HWND>` reparents the host window into the IDE's dockable preview panel, the host remains a separate process.

The client and host require handshake version 5. Embedded clients send `RESUME`
after a view becomes visible again, the host restores its native child window,
redraw and layout on its own thread, retaining the existing visual tree. The
host also watches parent visibility to recover from IDE debug-desktop changes.
Rebuild the host and IDE package together after protocol changes.

A broken edit keeps the last good view and shows WinUI's error, with the line of the `.xaml` file, in a red bar. There is no view model, so give bound controls sample values with the designer convention:

```xml
<Window ... xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="d">
  <TextBox Text="{Binding Name}" d:Text="Ada Lovelace"/>
```

`d:Text` wins in the preview, the app never sees it (XamlCodeGen removes `d:` attributes). A bound `Text`, `Content`, `Header` or `PlaceholderText` without a `d:` value shows its binding path, such as `{Summary}`. Converters the app registers at run time pass values through.

In RAD Studio, **Tools > RADWinUI Preview** starts the host in its own window. **Tools > RADWinUI Docked Preview** starts the same host as a child window inside a dockable IDE panel. Both preview the active window's `.xaml`, `.pas` or `.Xaml.pas` file, the windowed action remains the default. The IDE package contains only VCL and ToolsAPI code. The pipe end (`RADWinUI.Preview.Client`) has no ToolsAPI code: every wait has a timeout, a crashed or hung host is started again (three failures in a row stop the preview with a message), and disconnecting closes the host. The IDE uses queued overlapped pipe I/O, so it does not wait for renderer replies. A host that does not answer within its active three-second request budget is replaced, long pauses in IDE timer processing reset that budget. `scripts\Build-Wizard.ps1` builds the host with the package, when the package was installed from its `.dproj` instead, the command offers to build the host the first time. It uses the Release build, else the Debug one.

`scripts\Test-Preview.ps1` checks the file and windowed pipe modes with UI Automation on a secondary monitor, then the client against the real host (`tests\Preview`). Docked mode still needs parent-window and IDE validation.
