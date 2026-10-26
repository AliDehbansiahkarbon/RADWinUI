# RADWinUI Gallery

A native WinUI 3 control gallery written in Object Pascal. The layout and
illustrations are original. Microsoft's WinUI Gallery inspired the browsing
workflow, no Gallery source or artwork is bundled.

<p align="center">
  <img src="images/app-gallery-light.png" alt="RADWinUI Gallery, light theme" width="49%" />
  <img src="images/app-gallery-dark.png" alt="RADWinUI Gallery, dark theme" width="49%" />
</p>

Open `samples\Gallery\Gallery.dproj` in RAD Studio 13, select Win64, and build/run. Or, from the
repository root:

```powershell
.\scripts\Build.ps1 -Project samples\Gallery\Gallery.dpr -Config Release
.\samples\Gallery\Win64\Release\Gallery.exe
```

## Control explorer

**Control explorer** contains 30 individual native samples. Filter by control or
category, choose a sample, toggle its enabled state or reading direction, and
read common control values from Pascal. The main navigation search also finds
individual controls. Each selection updates the XAML and Pascal excerpts.

The collection includes buttons, text/password/rich editing, numeric and choice
controls, lists and grids, tabs, calendars, progress, color, native menus/toolbars
and identity. Definitions are in `RADWinUI.Gallery.Catalog.pas`, the live XAML is
in `MainWindow.xaml`. The excerpts are property/handler snippets, not full apps.

## Guided collection

| Category | Examples |
| --- | --- |
| Basic input | Button, TextBox, ToggleSwitch, CheckBox, RadioButton, NumberBox, ComboBox, Slider, ProgressBar, RatingControl. Greeting and intensity changes use Pascal handlers. |
| Lists and collections | Add/remove/select ListView entries and expand a TreeView hierarchy. |
| Date and time | CalendarDatePicker, DatePicker, TimePicker and CalendarView. Native localization and keyboard behavior. |
| Feedback and dialogs | InfoBar severity changes, ProgressRing, indeterminate progress, Flyout and an asynchronous ContentDialog with a Pascal result handler. |
| Layout and navigation | Grid proportions, StackPanel, Expander and TabView. |
| Materials and color | Switch between Mica, Mica Alt, desktop Acrylic and a themed solid surface. ColorPicker updates a Delphi-owned brush and an ARGB label. The Transparency switch in the title bar turns the backdrop off and on on every page. |
| Live Pascal binding | Two-way string binding, a counter, a derived summary and a live footer clock from a typed Delphi view model. |

The navigation search accepts a control name or category, and suggests matching
categories. The appearance selector defaults to Windows settings, Light and Dark
override this window without changing Windows. Each demo category includes short
XAML/Pascal excerpts with Copy buttons. The complete source is in
`MainWindow.xaml`, `MainWindow.pas`, and `MainViewModel.pas`, regenerate the
`MainWindow.Xaml.pas` base through XamlCodeGen rather than editing it.

Windows can replace Mica/Acrylic with a solid fallback when the app is inactive,
transparency is disabled, or power/accessibility policy requires it. See Microsoft's
[system backdrop guidance](https://learn.microsoft.com/en-us/windows/apps/develop/ui/system-backdrops).
Theme resources follow the selected theme, the system setting is inherited when
no application override is set, as described in Microsoft's
[theming guidance](https://learn.microsoft.com/en-us/windows/apps/develop/ui/theming).

## Ideas for later

- Extend the collection toward the public, creatable types in the RADWinUI palette.
- Add favorites, recent demos, accessibility examples, animation, richer data and
  more window and shell scenarios.
- Expand property snippets into complete standalone window examples, with API links.

## Automated check

```powershell
.\scripts\Test-Gallery.ps1
```

This builds the Gallery and a native test. The test loads the real XAML, visits
all 30 live samples, checks source and selection, enabled/RTL options, filters,
Pascal readouts/actions, all guided pages, binding, three themes and four backdrop
choices. It runs on a secondary monitor without UI Automation or injected input,
and the 30 Pascal property excerpts are compiled too.

The test checks native APIs and state. Mouse and keyboard interaction, flyouts,
dialogs and pixel-level layout are still checked by hand.
