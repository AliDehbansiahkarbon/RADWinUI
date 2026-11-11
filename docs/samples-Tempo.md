# Tempo

A radio player made with Delphi and WinUI 3, built to show how a RADWinUI app works with several windows and a title bar of its own: a main window with WinUI's TitleBar control, a tool window, a modal dialog window, a compact overlay mini player, full screen, and a window that opens where you left it.

Open `samples\Tempo\Tempo.dproj` in RAD Studio 13 and run Win64. Or, from the repository root:

```powershell
.\scripts\Build.ps1 -Project samples\Tempo\Tempo.dpr -Config Release
.\samples\Tempo\Win64\Release\Tempo.exe
```

## What to try

- **Title bar.** The title bar is part of the window: the Tempo icon, the title and subtitle, a back button and a search box. Drag the window by any empty part of it. Type in the search box: the station list filters while you type, and the search box takes clicks and text like any text box. The caption buttons follow the light and dark theme.
- **Back.** Click a few stations in the list, then click the back button in the title bar: Tempo goes back through the stations you played. It is disabled when there is nothing to go back to.
- **Tool window.** Queue opens a small window that stays above the main window and minimizes with it. Its close button only hides it (`TWinUICloseAction.Hide`). Queue shows it again with the same content.
- **Modal window.** Add station... opens a dialog window centred on the main window. The main window does not react until the dialog closes. Add (enabled once there is a name) adds the station and plays it, Cancel or the close button add nothing. The result arrives in the callback of `ShowModal`.
- **Mini player.** Mini player opens a small compact overlay window that stays above every other window, even a full screen video. Play and Pause work there too.
- **Full screen.** Full screen fills the display without a frame. The same button brings the window back.
- **Placement.** Move or resize the main window, or maximize it, and close Tempo. The next start opens it where it was. If that display is gone, the window opens on the nearest one.

## How it is made

- `MainWindow.xaml` has `TitleBar="AppTitleBar"` on `<Window>`: XamlCodeGen calls `UseTitleBar(AppTitleBar)`, which extends the content into the title bar and makes WinUI's `TitleBar` control the place where the window is dragged. The control keeps its back button and search box clickable by itself.
- `QueueWindow` has `OwnerWindow` set to the main window and an `OnClose` that picks `TWinUICloseAction.Hide`.
- `AddStationWindow` is shown with `ShowModal`. Its buttons set `ModalResult`, which closes it, as in the VCL. Its XAML sets `Resizable="False"`, `Minimizable="False"`, `Maximizable="False"` and `WindowStartupLocation="CenterOwner"`.
- `MiniPlayerWindow.xaml` sets `WindowState="CompactOverlay"`. Full screen is `WindowState := TWinUIWindowState.FullScreen`.
- The main window calls `RestorePlacement` in its constructor and `SavePlacement` in `OnClose`.

## Automated check

`scripts\Test-Samples.ps1` runs Tempo offscreen: it opens and closes the Queue, adds a station through the modal window and uses the back button. It leaves out the mini player and full screen, which would leave the test area, and keeps the placement you saved.
