# Changelog

All notable changes to RADWinUI.

## Unreleased (0.9.3)

- New sample: Haven, a glassy savings dashboard with acrylic cards, goal rings and two-way bound toggles.
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
