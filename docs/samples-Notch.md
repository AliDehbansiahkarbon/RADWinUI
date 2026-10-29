# Notch

A desk companion made with Delphi and WinUI 3. It sits at the top centre of the screen as a black pill with the time. Rest the pointer on it, or press Ctrl+Alt+N, and it opens into a panel with three glowing tiles:

- **Build** runs a simulated build. The tile glows orange while it runs, turns blue when it is done, and a few seconds later settles back to its quiet green.
- **Now playing** shows the music or video playing on the PC (Spotify, a browser, Media Player) and controls it with previous, play/pause and next.
- **Focus** is a 25 minute timer that pulses purple while it runs and opens the panel when the time is up.

The Transparency switch lets the desktop show through the notch, the pin keeps the panel open and the cross quits. Clicks next to the notch go to the windows below it.

Open `samples\Notch\Notch.dproj` in RAD Studio 13 and run Win64. Or, from the repository root:

```powershell
.\scripts\Build.ps1 -Project samples\Notch\Notch.dpr -Config Release
.\samples\Notch\Win64\Release\Notch.exe
```

## How it is made

- **The window.** `<Window WindowStyle="Overlay" Backdrop="Transparent" Dock="TopCenter" ClickThrough="Background" ShowActivated="False">` makes a frameless, always-on-top window without a background, out of Alt+Tab and the taskbar, that opens without taking the focus. `MainWindow.pas` sets `HitTestElement := Notch`, so only the notch takes the pointer.
- **The notch.** `rw:NotchPanel` grows from the pill (`Pill`) into the panel (its content) with a springy animation and shrinks back when the pointer leaves. Its top edge stays straight against the screen edge.
- **Transparency.** The window has no background of its own, so the switch only changes the notch's `Background` between solid black and a see-through black.
- **The tiles.** Each tile is an `rw:GlowTile`. Setting `GlowBrush` fades the glow to the new colour, `Pulse` makes it breathe and `FadeAfter` lets it fade out by itself.
- **Ctrl+Alt+N** is an `rw:HotKey`, the music an `rw:MediaSession`. Both have no look, their events are wired by name like any other control's (`ToggleKeyPressed`, `MediaChanged`).

All of these come from the Overlay category of the Tool Palette, see [CUSTOM-CONTROLS.md](CUSTOM-CONTROLS.md).

## Automated check

`Notch.exe -smoke-test <result file>` opens the panel through the hotkey handler, runs a build and the focus timer, checks the media session, the pin and the Transparency switch, writes PASS or FAIL to the file and quits. Run it with `RADWINUI_TEST_MONITOR=offscreen` on a PC with one screen.
