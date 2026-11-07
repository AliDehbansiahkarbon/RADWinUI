# Changelog

All notable changes to RADWinUI.

## Unreleased

- New Tool Palette category Data Controls with 17 data-aware controls (unit `RADWinUI.DBControls`, XAML prefix `rw:`) that bind to a Delphi `TDataSource` like the VCL's Data Controls: `TWinUIDBGrid`, `TWinUIDBNavigator`, `TWinUIDBText`, `TWinUIDBEdit`, `TWinUIDBMemo`, `TWinUIDBImage`, `TWinUIDBListBox`, `TWinUIDBComboBox`, `TWinUIDBCheckBox`, `TWinUIDBRadioGroup`, `TWinUIDBLookupListBox`, `TWinUIDBLookupComboBox`, `TWinUIDBRichEdit` and `TWinUIDBCtrlGrid`, plus `TWinUIDBDatePicker`, `TWinUIDBNumberBox` and `TWinUIDBToggleSwitch`. Any dataset works, such as FireDAC or `TClientDataSet`.
- In XAML, `DataSource` is the name of a `TDataSource`: a published field of the window or a component of a data module, also written as `Module.Source`. In code, the `DataSource` property takes the `TDataSource` itself. The Object Inspector offers the data sources and fields it finds in the project's `.dfm` files.
- New sample: Action Buttons, one see-through window that shows all six action buttons, with accent colours, Play all and a transparency slider. It follows the Windows theme.
- New Tool Palette category Action Buttons with six ready-made animated buttons (unit `RADWinUI.ActionButtons`, XAML prefix `rw:`): `TWinUIHoldButton` (hold to confirm), `TWinUISendButton` (a paper plane flies off), `TWinUIConfettiButton` (a confetti burst), `TWinUICopyButton` (copies its text, with a check and a tooltip), `TWinUIShineButton` (a shine sweep with sparkles) and `TWinUISlideButton` (slide to confirm). Each has a `Text`, one event and `Play` to run its effect from code.
- New Tool Palette category Tab Bars with six ready-made animated tab bars (unit `RADWinUI.TabBars`, XAML prefix `rw:`): `TWinUISlidingPillTabBar`, `TWinUILiquidBulgeTabBar`, `TWinUIFloatingNotchTabBar`, `TWinUIIconFillTabBar`, `TWinUIExpandingLabelTabBar` and `TWinUIBubbleFloatTabBar`. Drop one and it shows four tabs right away.
- The tabs are one `Items` text, `Label:Icon` separated by commas. In the Object Inspector its `...` button opens an editor to add, remove and reorder tabs and pick each icon from a grid.
- `Pages` names one element per tab and shows the selected tab's element, so switching pages needs no code. `SelectionChanged` fires for anything else.
- New sample: Tab Bars, one see-through window that shows all six tab bars, with accent colours, speed, labels, a tour and a transparency slider. It follows the Windows theme.
- A `Transparent` backdrop on a window with a normal frame shows the desktop. Windows painted the title bar colour behind it before.
- On a light `Background` the tab bars pick darker colours for the selected tab by themselves.
- Controls written in Delphi can give a property its own Object Inspector editor (`TWinUICustomType.SetEditor`).
- The designer has a context menu: Undo, Redo, Cut, Copy, Paste, Delete, Select Parent, Bring to Front, Send to Back, View Source and Split View, then the commands of the right-clicked control (its default event handler, Add Row and Add Column on a Grid, Orientation on a StackPanel, Add item on TabView, NavigationView, lists, ComboBox, MenuBar, RadioButtons and Pivot, Edit Items... on a tab bar, Edit Text...).
- Split View shows the XAML code and the live designer side by side, the designer in the docked preview panel. Selection and edits follow both ways.
- Ctrl+X cuts and Esc selects the parent in the designer, the Menu key and Shift+F10 open its menu.
- Ctrl+Arrow moves the selected control by one pixel, Ctrl+Shift+Arrow by eight, in a Grid or a Canvas. A row of key presses is one undo step.
- Alignment guides like the VCL designer's: blue lines while a control is dragged or moved with the keys, a drag snaps to them (Alt places it freely).
- In Split View the Structure view shows the design tree while the designer has the focus.
- The designer's dialogs follow the IDE theme: the Edit Text box, the tab items editor, the RADWinUI messages and the File > New messages.

## 1.0.0 (30 Oct 2026)

- Overlay windows: `WindowStyle` Overlay (no frame, always on top, out of Alt+Tab and the taskbar), a `Transparent` backdrop whose window is see-through, `Dock`, `ClickThrough` with `HitTestElement`, and `ShowActivated`, also as `<Window>` attributes.
- Controls written in Delphi: `TWinUICustomControl` (unit `RADWinUI.CustomControls`) makes a Delphi class a XAML element with dependency properties, a template and events.
- New Tool Palette category Overlay with RADWinUI's own controls (unit `RADWinUI.Controls`, XAML prefix `rw:`): `TWinUINotchPanel`, `TWinUIGlowTile`, `TWinUIHotKey` and `TWinUIMediaSession`.
- `TWinUINotchPanel.AttachedEdge` (Top, Bottom, Left, Right): a notch can hang from any screen edge, its pill stands upright on the side edges and the panel opens away from the edge.
- `TWinUIGlowTile` with a see-through `Background` shows what is behind it, the glow stays around its edge. Opaque tiles look as before.
- XamlCodeGen, the designer and the preview know the `rw:` controls. Dropping one declares `xmlns:rw` on the window.
- The projection includes `Windows.Media.Control`, the media sessions of the PC.
- New folder `community`, "Made with RADWinUI": apps that people build with RADWinUI and share as source, with screenshots, under clear rules for safety, usefulness and review. `community\Community.groupproj` builds them, and the release checks that it does.
- Notch, a desk companion that hangs from an edge of the screen, is the first community app. Its panel shows widgets you pick, edit inside the notch and reorder by dragging: installed apps, live Claude Code and Codex activity with usage limits, remote desktops, the calendar, links, notes, the music playing on the PC and a focus timer.
- Windows show the program icon, and new projects get the RAD Studio icon.
- The File > New wizards use themed dialogs, and new projects call the shared build scripts like the samples.
- Structure view fixes: no access violation when a node is clicked, nodes stay until the IDE has rebuilt its tree, and the 32-bit IDE keeps its focus.
- No platform warning for `RegisterExpectedMemoryLeak` when custom controls are compiled.
- Documentation: Overlay windows in the framework API, the Overlay controls and controls written in Delphi in CUSTOM-CONTROLS, and a pull request template for community apps.

## 0.9.3

- Every sample has a `.dproj` and is in `samples\RADWinUISamples.groupproj`. Build events call `scripts\RADWinUI-PreBuild.cmd` and `scripts\RADWinUI-PostBuild.cmd`, and a sample moved out of the repository finds RADWinUI through `RADWINUI_ROOT`.
- Windows have a `Transparency` property, `SystemTransparency` and `BindTransparencySwitch`: Gallery, Luma, Greeter and Lucent have a Transparency switch.
- `Test-Gallery.ps1`, `Test-Luma.ps1` and `Test-Samples.ps1` take `-Monitor offscreen` too.
- New sample: Lucent, an app publishing studio with frosted glass, eight animated pages, live simulated data and a drag-and-drop release board.
- New unit `RADWinUI.Motion`: entrance, exit, drift, reveal, grow, sweep, hero, lift and pulse animations that run on the compositor.
- A published property that returns a view model or a bindable list now passes its own bindable to XAML, so nested `{Binding}` paths follow its changes.
- New sample: Haven, a bento-style savings dashboard that follows the Windows theme and accent colour, with two-way bound toggles and a goals checklist.
- `RADWINUI_TEST_MONITOR=offscreen` runs a test window outside every monitor, for machines with one screen.
- The 32-bit IDE can install RADWinUI: one package per IDE, `RADWinUIWizard` (64-bit IDE) and `RADWinUIWizard32` (32-bit IDE).
- One project group per IDE: `RADWinUI.groupproj` (64-bit IDE) and `RADWinUI32.groupproj` (32-bit IDE), so each shows only its own package.
- Repository cleanup for publishing: the Python XamlCodeGen, the early prototypes and internal notes are gone, the generator's tests are Delphi programs.
- New README, logo, screenshots, CONTRIBUTING and this changelog.
- WinMDGen is a Delphi console program too, so the repository has no Python left, it regenerates `src\Generated` byte for byte as before.

## 0.9.3-rc.5 (21 Oct 2026)

- Source-only releases: `RADWinUI.groupproj` builds the XAML code generator, the preview host and the IDE package on your machine, no unsigned binaries ship.
- `samples\RADWinUISamples.groupproj` builds Gallery and Luma, their pre-build events use `bin\XamlCodeGen.exe`.

## 0.9.3-rc.4 (21 Oct 2026)

- XamlCodeGen is a native Delphi tool, `bin\XamlCodeGen.exe`: no Python needed.
- Apps no longer crash after their window closes: the WinUI DLLs stay loaded until the process ends.
- A native crash writes a report and a minidump to `%LOCALAPPDATA%\RADWinUI\Crashes`.

## 0.9.3-rc.3 (21 Oct 2026)

- Curated Tool Palette: 69 controls in nine categories, `TWinUIButton`-style names, own icons.
- Structure view shows control icons, `.xaml` files open in Design and get XML colouring.
- `Deploy-App.ps1` never deletes folders it did not write and can deploy self-contained, with the Windows App Runtime inside.
- Image cache and event-handler fixes in the Object Inspector, RADWinUI on the splash screen, sample rows at design time.

## 0.9.3-rc.1 and rc.2 (19 Oct 2026)

- Visual designer integrated in the XAML editor: Design view, F12, Tool Palette drag and drop, copy and paste, delete, undo and redo.
- Native Object Inspector with Properties and Events tabs, Structure view, F9 and Ctrl+F9 from Design.
- New samples: Luma and Gallery with 30 controls.
- Release packaging with provenance and checksums.

## 0.9.2 and 0.9.1 (18 Oct 2026)

- Live preview pushes designer events, free placement in Grid and Canvas.
- Docked preview, deployment notes for the Windows App Runtime.
- Second-PC install, build, preview and designer check passed on 0.9.1.

## 0.9.0 (17 Oct 2026)

- First release: projection generator, runtime and framework, XAML with build-time checks and data binding, File > New wizards, live preview and a first designer.
