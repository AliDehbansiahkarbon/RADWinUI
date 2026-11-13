# RADWinUI <img src="docs/images/radwinui-logo.png" alt="RADWinUI logo" width="48" align="top" />

<p align="center">
  <a href="https://www.youtube.com/playlist?list=PLOixRJGvMdjE">
    <img src="docs/images/radwinui-poster.png" alt="RADWinUI: native WinUI 3 apps for Delphi, designed visually in RAD Studio" />
  </a>
</p>

<p align="center">
  Native WinUI 3 applications from Delphi, designed and built inside RAD Studio.
</p>

<p align="center">
  <img src="https://img.shields.io/github/license/AliDehbansiahkarbon/RADWinUI.svg" alt="License" />
  <img src="https://img.shields.io/github/stars/AliDehbansiahkarbon/RADWinUI.svg" alt="Stars" />
  <img src="https://img.shields.io/github/forks/AliDehbansiahkarbon/RADWinUI.svg" alt="Forks" />
  <img src="https://img.shields.io/github/last-commit/AliDehbansiahkarbon/RADWinUI.svg" alt="Last commit" />
</p>

![RADWinUI Gallery in the RAD Studio designer, dark theme](docs/images/ide-gallery-dark.png)

## What It Is

RADWinUI lets you build real WinUI 3 applications with Delphi. You describe the window in XAML, write the logic in Object Pascal, and get a native Win64 executable. There is no .NET and no C#.

The controls are Microsoft's own WinUI 3 controls from the Windows App SDK: the same NavigationView, InfoBar, CalendarView, Mica and Acrylic that Windows 11 apps use. They are not VCL or FMX lookalikes.

RADWinUI works the way a Delphi developer expects. File > New creates the project, a Tool Palette and a visual designer sit in the IDE, the Object Inspector edits properties and events, and F9 runs the app.

## Main Features

- **Real WinUI 3 controls.** 1102 typed Pascal classes (`TWinUIButton`, `TWinUINavigationView`, ...) generated from Microsoft's metadata for Windows App SDK 2.6.5, plus the rest of the SDK for Pascal code: app lifecycle, notifications, file pickers, resources and on-device AI.
- **XAML plus Object Pascal.** Each window is a `.xaml` file and a `.pas` unit. A generated base class gives you one typed field per named control and wires events to your published methods.
- **Checked at build time.** Missing handlers, wrong handler signatures, unknown binding paths and unknown converters stop the build with the file, the line and a fix.
- **Data binding.** `{Binding}` to published properties of your Pascal classes, one-way and two-way, with built-in and custom converters.
- **File > New wizards.** RADWinUI Application creates a ready-to-run project. RADWinUI Window, Page, User Control and Resource File add to it.
- **Pages and navigation.** Pages in a frame, with parameters, back and forward, page transitions and a page that asks before it is left. A NavigationView drives the frame with one call.
- **User controls.** A `.xaml` file with its `.pas` unit, used in other XAML as `<local:Name/>` with its own properties and events.
- **Hot reload.** Edit the XAML while the app runs in Debug: windows, pages and user controls update at once and keep their data. An edit that needs new code says "Rebuild needed" ([docs](docs/HOT-RELOAD.md)).
- **WinUI inside VCL forms.** `TWinUIHost` on the Tool Palette puts WinUI content on an existing VCL form, bound to your data and wired to the form's event handlers, so a VCL application gets a modern screen one panel at a time ([docs](docs/VCL-HOSTING.md)).
- **Several windows.** Tool windows, modal windows with a result, VCL-style `OnCloseQuery` and `OnClose`, full screen, compact overlay, a window that opens where the user left it, and WinUI's TitleBar control or a title bar of your own.
- **App services.** Message and input boxes, file and folder pickers, Windows notifications you can answer, single instance, and the files and links Windows starts your app for.
- **Several languages.** `x:Uid` texts from `.resw` files, one language or many, right to left included, without MSIX.
- **Accessible.** RADWinUI's own controls work with Narrator, NVDA, the keyboard and contrast themes like WinUI's, and the build warns about a button a screen reader cannot name.
- **Visual designer in the IDE.** A Design view next to Code (F12 switches), drag and drop from the Tool Palette, selection, move, copy, paste, delete, undo and redo. The XAML text stays the single source of truth.
- **Tool Palette.** 102 controls in thirteen categories (Standard, Layout, Input, Date and Time, Collections, Navigation, Text and Media, Status, Shapes, Overlay, Tab Bars, Action Buttons, Data Controls), named like VCL (`TWinUIButton`) with their own icons. Overlay, Tab Bars, Action Buttons and Data Controls hold controls written in Delphi: NotchPanel, GlowTile, HotKey, MediaSession, six animated tab bars whose tabs and icons you set in the Object Inspector, six animated buttons such as hold to confirm, a confetti burst and slide to confirm, and seventeen data-aware controls such as a grid, a navigator and edits that bind to a `TDataSource` like the VCL's Data Controls.
- **Object Inspector and Structure view.** Edit WinUI properties and events in the native Object Inspector, see the control tree with icons in the Structure view.
- **Design-time sample data.** `d:` values and sample rows show in the designer, never in the running app.
- **XAML editor.** `.xaml` files open in Design first and get XML colouring in Code.
- **Live preview.** Tools > RADWinUI Preview renders the window in its own process while you type.
- **Modern Windows look.** Light, Dark and Windows themes, Mica and Acrylic backdrops, custom title bars, accent colours.
- **Deployment your way.** A small app (about 1 MB) for PCs with Microsoft's Windows App Runtime, or a self-contained folder with the runtime inside: nothing to install for the end user.
- **Crash reports.** A native crash writes a report and a minidump instead of closing the app silently.
- **Source only, no Python, no signing needed.** One project group per IDE builds everything RADWinUI needs on your machine.

## Screenshots

<table>
  <tr>
    <td align="center" width="50%"><img src="docs/images/app-gallery-light.png" alt="RADWinUI Gallery, light theme" /><br /><sub>Gallery app, light theme</sub></td>
    <td align="center" width="50%"><img src="docs/images/app-gallery-dark.png" alt="RADWinUI Gallery, dark theme" /><br /><sub>Gallery app, dark theme</sub></td>
  </tr>
</table>

<table>
  <tr>
    <td align="center" valign="top"><img src="docs/images/app-luma.png" alt="Luma, an Acrylic desktop companion" width="220" /><br /><sub>Luma, Acrylic</sub></td>
    <td align="center" valign="top"><img src="docs/images/tool-palette-light.png" alt="RADWinUI controls in the Tool Palette, light theme" width="230" /><br /><sub>Tool Palette, light</sub></td>
    <td align="center" valign="top"><img src="docs/images/tool-palette-dark.png" alt="RADWinUI categories in the Tool Palette, dark theme" width="200" /><br /><sub>Tool Palette, dark</sub></td>
    <td align="center" valign="top"><img src="docs/images/structure-view-dark.png" alt="The window's control tree with icons in the Structure view" width="220" /><br /><sub>Structure view</sub></td>
  </tr>
</table>

![The designer with the Structure view, Object Inspector and the RADWinUI Tool Palette, light theme](docs/images/ide-gallery-palette-light.png)

![Lucent, an app publishing studio built with RADWinUI](docs/images/app-lucent.png)

![Haven, a savings dashboard built with RADWinUI](docs/images/app-haven.png)

## Supported IDE And Requirements

| Item | Version |
| --- | --- |
| RAD Studio / Delphi | 13 Florence |
| IDE | 64-bit IDE (`bin64\bds.exe`) and classic 32-bit IDE (`bin\bds.exe`) |
| Application platform | Win64 |
| Windows App SDK | 2.6.5 (stable) |
| Windows | 10 version 1809 or later, Windows 11 recommended |

The apps you build need the Windows App Runtime 2.6 (x64) on the end user's PC, unless you deploy them self-contained. WinUI 3 does not run elevated: do not start RAD Studio as administrator.

## Installation

RADWinUI ships as source code. RAD Studio builds everything on your machine, there are no prebuilt binaries to trust or sign.

0. **Get the source, then download the Windows App SDK files. Do not skip this in a clone.** Download a release ZIP and extract it to a new folder, or clone the repository. **In a clone, run this once in the RADWinUI folder before opening anything in RAD Studio:**

   ```text
   powershell -ExecutionPolicy Bypass -File scripts\Get-WindowsAppSDK.ps1
   ```

   Without these files the build stops with *Windows App SDK files are missing*. A release ZIP already contains them. Add `-InstallRuntime` if the Windows App Runtime 2.6 is not installed on your PC.
1. Start RAD Studio without administrator rights. If an older RADWinUI package is installed, remove it first (Component > Install Packages).
2. File > Open Project, in the RADWinUI folder, the group for your IDE:
   - `RADWinUI.groupproj` in the 64-bit IDE
   - `RADWinUI32.groupproj` in the classic 32-bit IDE
3. Right-click the project group > **Build All**. It builds the XAML code generator (`bin\XamlCodeGen.exe`), the preview and designer host, and the IDE package.
4. Right-click the package (`RADWinUIWizard.bpl` or `RADWinUIWizard32.bpl`) > **Install**.

The full guide is in [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md).

## Quick Start

1. File > New > Other > Delphi Projects > **RADWinUI Application**. Give it a name and a folder.
2. `MainWindow.xaml` opens in the designer. Drop controls from the RADWinUI categories of the Tool Palette.
3. Select a control and set its properties and events in the Object Inspector. Double-click an event to write its handler.
4. Press **F9**.

```delphi
type
  TMainWindow = class(TMainWindowBase)   // TMainWindowBase is generated from MainWindow.xaml
  published
    procedure IncrementButtonClick(Sender: TObject);
  end;

procedure TMainWindow.IncrementButtonClick(Sender: TObject);
begin
  CounterText.Text := (StrToInt(CounterText.Text) + 1).ToString;
end;
```

```xml
<StackPanel Spacing="16" Padding="32">
    <TextBlock x:Name="CounterText" Text="0" FontSize="32"/>
    <Button x:Name="IncrementButton" Content="Increment"/>
</StackPanel>
```

## How To Use

**Design the window.** The `.xaml` editor has Code and Design views. Design shows the real WinUI rendering, hosted in its own process so the IDE stays stable. Drag controls from the Tool Palette, move them, and use Delete, Ctrl+C, Ctrl+V, Ctrl+Z and Ctrl+Y. Every change is a small, undoable edit of the XAML text.

![The designer, Tool Palette, Object Inspector and Structure view, light theme](docs/images/ide-gallery-light.png)

**Edit properties and events.** The Object Inspector shows the WinUI properties of the selected control on the Properties tab and its events on the Events tab. Double-clicking an event adds the handler to your unit.

**Navigate with the Structure view.** It shows the control tree with the same icons as the Tool Palette. Selecting a node selects the control.

**Bind data.** Set `DataContextType="TMainViewModel"` on the window and bind with `{Binding Name}`. Properties of a `TWinUIBindableObject` notify the UI when they change. The build checks every binding path.

![Luma: a desktop companion built with RADWinUI](docs/images/ide-luma-light.png)

**Preview live.** Tools > RADWinUI Preview (or Docked Preview) renders the XAML you type, with design-time sample data.

More: [XAML reference](docs/XAML.md), [Framework API](docs/FRAMEWORK-API.md), [Object Inspector](docs/OBJECT-INSPECTOR.md).

## Samples

Open `samples\RADWinUISamples.groupproj`, Build All, and run:

- **[Gallery](docs/samples-Gallery.md):** 30 controls in seven guided demos, search, themes, Mica and Acrylic, XAML and Pascal source, and live Pascal binding.
- **[Luma](docs/samples-Luma.md):** an Acrylic desktop companion with a live clock, battery and memory readings, a focus timer and a calendar.
- **[Lucent](docs/samples-Lucent.md):** an app publishing studio in frosted glass over drifting ribbons: eight animated pages, live simulated data, a drag-and-drop release board, charts with a hover tooltip and a hero move to each app's page.
- **[Haven](docs/samples-Haven.md):** a bento-style savings dashboard that follows the Windows theme and accent colour, with a weekly chart, a countdown dial, a calendar and a goals checklist, all bound to a Delphi view model.
- **[Tab Bars](docs/samples-TabBars.md):** one window that shows all six animated tab bars of the Tool Palette, each on a card of its own, with live accent colours, speed and labels, and a tour that taps through them all.
- **[Action Buttons](docs/samples-ActionButtons.md):** the six animated buttons of the Tool Palette on one see-through page: hold to confirm, a paper plane, a confetti burst, copy feedback, a shine sweep and slide to confirm, with accent colours and a Play all wave.
- **[Data Controls](docs/samples-DataControls.md):** customers and their orders in a FireDAC data module, shown and edited with the data-aware controls of the Tool Palette: a grid with a navigator, a form for the current customer, the orders as a master/detail grid and every customer as a tile.
- **[Quill](docs/samples-Quill.md):** a notes app that uses the app services: open, save and folder pickers, "Save changes?" and rename dialogs, reminders as Windows notifications you can answer, and one running Quill that Windows starts for `.qnote` files and `quill://` links. In English, German and Persian (right to left).
- **[Crew](docs/samples-Crew.md):** a team directory in a NavigationView: four pages, the person handed to the profile page as a parameter, a People page that keeps its search, a profile that asks before it is left with unsaved changes, and a person card user control used three times.
- **[Tempo](docs/samples-Tempo.md):** a radio player with several windows: WinUI's TitleBar with a search box and a back button, a tool window, a modal dialog window with a result, a compact overlay mini player, full screen, and a window that opens where you left it.
- **[Customers_VCL](docs/samples-Customers_VCL.md):** a classic VCL screen whose details panel is WinUI in a `TWinUIHost`, bound two-way to the selected customer.
- **[AppServicesDemo](docs/samples-AppServicesDemo.md):** one button for each dialog, picker, notification and activation service, with a log of every result, to try them one at a time.

Smaller samples (Counter, Greeter, ListDemo, Contacts, Profile) show one topic each. They are in the same group, or build one with `scripts\Build.ps1 -Project samples\Counter\Counter.dpr`.

## Made with RADWinUI

Apps that people build with RADWinUI and share as source, with screenshots, are in [community](community/README.md). Build them with `community\Community.groupproj`.

- **[Notch](community/Notch/README.md)** by Ali Dehbansiahkarbon: a desk companion that hangs from an edge of the screen as a black pill with the time and opens into a panel of widgets you pick: your apps, live Claude Code and Codex activity, remote desktops, the calendar, links, notes, the music playing on the PC and a focus timer. Ctrl+Alt+N, or a shortcut you pick, opens it.

Made something with RADWinUI? The [rules for sharing an app](community/README.md#share-your-app) explain how to send it in.

## Deployment

`scripts\Deploy-App.ps1` writes the folder you give to end users and checks that it runs outside the repository:

```text
.\scripts\Deploy-App.ps1 -Project samples\Counter\Counter.dpr                  # small app, about 1 MB
.\scripts\Deploy-App.ps1 -Project samples\Counter\Counter.dpr -SelfContained   # runtime included, about 55 MB
```

A small app needs Microsoft's free Windows App Runtime 2.6 installed once per PC, like the VC++ runtime or WebView2. A self-contained app needs nothing: copy the folder and run. See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for licensing, signing and setup notes.

## Notes And Limitations

- Applications are Win64 only. The IDE package works in both the 32-bit and the 64-bit IDE.
- RADWinUI targets RAD Studio 13 Florence and Windows App SDK 2.6.5.
- Apps ship as a plain folder: a small app, or a self-contained one.
- RADWinUI is not code-signed. Sign your own applications with your certificate.
- Push notifications and other Windows App SDK features that need the runtime's Singleton package do not work self-contained.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `error RW1001 : Windows App SDK files are missing`, or a post-build `copy` error in RADWinUIPreview | Run `powershell -ExecutionPolicy Bypass -File scripts\Get-WindowsAppSDK.ps1` once in the RADWinUI folder (step 0), then Build All again. |
| `RADWinUI : error RW1002 : RADWinUI was not found` | The project is outside the RADWinUI folder. Set `RADWINUI_ROOT` to the RADWinUI folder, then build again. |
| No Install on the package | Open the group of your IDE: `RADWinUI.groupproj` in the 64-bit IDE, `RADWinUI32.groupproj` in the classic 32-bit IDE. |
| `XamlCodeGen did not run`, or a build stops at its pre-build event | Open the group of your IDE and use Build All: it makes `bin\XamlCodeGen.exe`. |
| The app exits at start with a runtime error | Install the Windows App Runtime 2.6 (x64), or deploy self-contained. |
| Nothing happens when the app starts from the IDE | Start RAD Studio without administrator rights. |
| An app closed unexpectedly | Look in `%LOCALAPPDATA%\RADWinUI\Crashes` for its report. |

More in [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md#troubleshooting).

## Videos

<!--
  To add a video: copy a <td> cell, change the video id in its link (https://youtu.be/<id>) and in
  its thumbnail (https://img.youtube.com/vi/<id>/maxresdefault.jpg, or hqdefault.jpg when YouTube
  has no maxres one), then the title and the length. The new cell takes the place of the first
  empty <td>, and after three cells a new <tr> row starts, filled up with empty cells.
-->
<table>
  <tr>
    <td align="center" width="33%" valign="top">
      <a href="https://youtu.be/ryEtWZgUxhg"><img src="docs/images/video-thumbnail.png" alt="RADWinUI announcement" width="100%" /></a><br />
      <b>Announcement</b> <sub>3:43</sub>
    </td>
    <td align="center" width="33%" valign="top">
      <a href="https://youtu.be/HxK9vPN2y_M"><img src="https://img.youtube.com/vi/HxK9vPN2y_M/maxresdefault.jpg" alt="RADWinUI promo" width="100%" /></a><br />
      <b>Promo</b> <sub>2:22</sub>
    </td>
    <td align="center" width="33%" valign="top">
      <a href="https://youtu.be/yM245jFXGjs"><img src="https://img.youtube.com/vi/yM245jFXGjs/maxresdefault.jpg" alt="RADWinUI Tab Bars" width="100%" /></a><br />
      <b>Tab Bars</b> <sub>0:30</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="33%" valign="top">
      <a href="https://youtu.be/U2NFHvaGtqE"><img src="https://img.youtube.com/vi/U2NFHvaGtqE/maxresdefault.jpg" alt="RADWinUI Action Buttons" width="100%" /></a><br />
      <b>Action Buttons</b> <sub>0:48</sub>
    </td>
    <td align="center" width="33%" valign="top">
      <a href="https://youtu.be/qU1OHQKxSKM"><img src="https://img.youtube.com/vi/qU1OHQKxSKM/maxresdefault.jpg" alt="RADWinUI Data Controls" width="100%" /></a><br />
      <b>Data Controls</b> <sub>0:52</sub>
    </td>
    <td width="33%"></td>
  </tr>
</table>

<p align="center"><a href="https://www.youtube.com/playlist?list=PLOixRJGvMdjE">Watch all on YouTube</a></p>

## Contributing

Issues and pull requests are welcome. Please read [CONTRIBUTING.md](docs/CONTRIBUTING.md). Apps made with RADWinUI go into [community](community/README.md), under the rules there. When you report a problem, include:

- your RAD Studio version and IDE (32-bit or 64-bit) and your Windows version;
- the steps to reproduce it, and the `.xaml` file if it is about a window;
- the RADWinUI log (`%TEMP%\RADWinUI\ide.log`) or the crash report from `%LOCALAPPDATA%\RADWinUI\Crashes`.

## Documents

- [Getting started](docs/GETTING-STARTED.md): from install to a deployed app
- [XAML reference](docs/XAML.md): what a window `.xaml` may contain and what the build checks
- [Framework API](docs/FRAMEWORK-API.md): the Pascal classes an app uses
- [Deployment](docs/DEPLOYMENT.md): shipping a small app or a self-contained one
- [Architecture](docs/ARCHITECTURE.md): the parts and how they fit together
- [Changelog](docs/CHANGELOG.md)

## License

RADWinUI is released under the MIT License. See [LICENSE](LICENSE). The Windows App SDK files that a release or an app redistributes are covered by Microsoft's terms: see [THIRD-PARTY-NOTICES.md](docs/THIRD-PARTY-NOTICES.md).

## Support

If RADWinUI helps you, please star the repository.

For direct support, email adehban@gmail.com.

---

<p align="center">
  <img src="https://i0.wp.com/blogs.embarcadero.com/wp-content/uploads/2022/11/dlogonew-5582740.png?resize=254%2C242&ssl=1" alt="Delphi">
</p>

<h5 align="center">
Made with :heart: in Delphi
</h5>
