# XAML reference

What a RADWinUI window `.xaml` may contain, what the build checks, and what the preview and designer do with it. The tool is `tools\XamlCodeGen` (details in [tools-XamlCodeGen.md](tools-XamlCodeGen.md)), the build stops on every rule below with the file, the line and the reason.

## A window file

![Gallery's MainWindow.xaml in the Code view](images/xaml-code-view-dark.png)

```xml
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        mc:Ignorable="d"
        x:Class="TMainWindow"
        Title="Counter" Width="480" Height="320" WindowStartupLocation="CenterScreen"
        DataContextType="TMainViewModel">
    <StackPanel Spacing="16" Padding="32">  <!-- exactly one content element -->
        ...
    </StackPanel>
</Window>
```

| Rule | Why |
| --- | --- |
| The root is `<Window>` with `x:Class="TName"` | XamlCodeGen writes `TNameBase` into `<File>.Xaml.pas`, your `TName` in `<File>.pas` inherits it |
| One content element | a WinUI window has one `Content` |
| `<Window>` attributes: `Title`, `Width`, `Height`, `MinWidth`, `MinHeight`, `Backdrop` (None, Mica, MicaAlt, Acrylic), `ExtendsContentIntoTitleBar`, `WindowStartupLocation` (Manual, CenterScreen), `DataContextType` | WinUI's `Window` takes no other XAML attributes, these become `TWinUIWindow` properties |
| `x:Name` must not hide a window member (`Title`, `Content`, `Width`, `Show`, ...) or be a Pascal keyword | each name becomes a field of the base class |
| `x:Name` is unique | same |

## Default window appearance

Give a normal window's root panel a theme resource background:

```xml
<Grid RequestedTheme="Default"
      Background="{ThemeResource ApplicationPageBackgroundThemeBrush}">
    ...
</Grid>
```

This paints the window surface using its current light/dark theme. The new-window
templates also set `AppWindow.TitleBar.PreferredTheme` to
`TWinUITitleBarTheme.UseDefaultAppMode` in Pascal. With no application theme
override, the default comes from Windows. For a Mica/Acrylic window, use
`Background="Transparent"` to expose the backdrop instead, see the Gallery and
Luma samples.

## Events

| Written as | Handler |
| --- | --- |
| `<Button x:Name="OkButton"/>` and a published `OkButtonClick` | wired by name: `<x:Name><Event>` |
| `<Button Click="SaveClick"/>` | the published `SaveClick` must exist when `<File>.pas` is there |

A handler is `(Sender: TObject; E: <args class>)` or `(Sender: TObject)`, the args class is the event's (`TWinUIRoutedEventArgs` for `Click`). Event attributes are removed from the XAML the app loads, because `XamlReader.Load` rejects them.

## Accessing designer controls from Pascal

The **Name** shown in Delphi's Object Inspector is the field name in your window class.
For example, `<ColorPicker x:Name="ColorPicker1"/>` generates a typed
`ColorPicker1: TWinUIColorPicker` field in `MainWindow.Xaml.pas`. Use
`ColorPicker1.Color` inside `TMainWindow` methods, a control named `cp` is accessed
as `cp.Color`. Do not edit the generated unit yourself.

Palette insertions assign unique names such as `Button1` and `ColorPicker1`.
The IDE regenerates the base unit from its current XAML and Pascal buffers after
designer edits, and before navigating to a generated event handler. The build
still regenerates it as usual. Invalid XAML keeps the last generated version,
generation errors are recorded in `%TEMP%\RADWinUI\ide.log`.

Double-click a designer control to create or open its default event: `Click`
for buttons, `ColorChanged` for a color picker, and the corresponding change
event for text, selection and value controls. The Events tab can select any
other event.

Colors are `TWinUIColor` records (from `RADWinUI.Xaml`). For example:

```pascal
procedure TMainWindow.Button1Click(Sender: TObject; E: TWinUIRoutedEventArgs);
var
  Red: TWinUIColor;
begin
  Red.A := 255;
  Red.R := 255;
  Red.G := 0;
  Red.B := 0;
  ColorPicker1.Color := Red;
end;
```

The current generated `TWinUIColorHelper` does not expose a static `FromArgb`
method. Use the color record above.

## Bindings

| Written as | Checked against |
| --- | --- |
| `{Binding Path}` in the window | published properties of `DataContextType` (in its own unit) |
| `{Binding Path}` inside `<DataTemplate x:DataType="TItem">` | published properties of `TItem` |
| `Converter={StaticResource Name}` | built-ins (`BoolToVisibility`, `InverseBoolToVisibility`, `Format`), `TWinUIApp.RegisterConverter('Name', ...)` in the project's sources, or an `x:Key` in the XAML |
| `ConverterParameter` of `Format` | a Delphi format string with one `%s` |

An element that sets its own `DataContext` stops the checks below it. Template content creates no fields and no event wiring.

## Design-time values

`d:<Property>="value"` (with `mc:Ignorable="d"` on the root) is shown by the designer instead of the property's binding or value. XamlCodeGen removes design-time attributes and entire design-time element subtrees before checking fields, bindings and handlers, so the app never sees them. In the designer, a bound `Text`, `Content`, `Header` or `PlaceholderText` without a `d:` value shows its binding path (`{Summary}`).

### Sample rows in lists

Use inline `d:ListView.Items`, `d:GridView.Items`, `d:ListBox.Items` or
`d:ComboBox.Items`. This follows the inline Items pattern in Microsoft's
[design-time data guidance](https://learn.microsoft.com/en-us/visualstudio/xaml-tools/xaml-designtime-data?view=visualstudio).
Keep the usual `xmlns:d`, `xmlns:mc` and `mc:Ignorable="d"` declarations on the root.

```xml
<ListView x:Name="People" ItemsSource="{Binding People}">
    <d:ListView.Items>
        <x:String>Alex Morgan</x:String>
        <x:String>Bea Chen</x:String>
    </d:ListView.Items>
    <ListView.ItemTemplate>
        <DataTemplate>
            <TextBlock Text="{Binding Name}" d:Text="{Binding}"/>
        </DataTemplate>
    </ListView.ItemTemplate>
</ListView>
```

The designer blanks the owning control's `ItemsSource` attribute and loads the
sample Items. A template can use `d:Text="{Binding}"` to show a sample string,
or a literal `d:Text` for another field. Visual items work too. Clicking a sample
row selects its real list, sample descendants are excluded from Structure and
the Object Inspector control selector. Their names and event attributes do not
become Pascal fields or handlers. Source line/column positions remain intact.

Use this with an `ItemsSource` attribute or a list populated by Pascal. Do not
combine it with real inline Items or an `ItemsSource` property element.
`d:ItemsSource` attribute data, WPF `x:Array`, external design-data files and
automatic mock Pascal objects are not supported. See `samples\Contacts` for a
complete example whose preview rows differ from its real application data.

## Preview and designer

### Keyboard and Structure

<img src="images/structure-view-dark.png" alt="The element tree with icons in the Structure view" width="260" />

In Design, **Delete** removes the selected control with one undoable XAML edit.
**Ctrl+Z** undoes the edit, and **Ctrl+Y** or **Ctrl+Shift+Z** redoes it. These
commands use the XAML editor's own history, including property, layout, insertion
and movement edits. The Window and its required root content are protected from
deletion.

RAD Studio's existing **Structure** view shows the Window and its visual control
hierarchy while Design is active. Clicking a tree item selects that control and
its Properties, clicking the designer selects the corresponding tree item.
Double-clicking a tree item opens its default event. Delete and undo/redo also
work with Structure focused. Template and resource contents are omitted from this
visual hierarchy.

### Align

Direct children of a **Grid** expose an **Align** drop-down in Delphi's Object Inspector:

| Value | Layout |
| --- | --- |
| `alNone` | Free positioning with Left/Top alignment |
| `alTop`, `alBottom` | Full-width horizontal strips |
| `alLeft`, `alRight` | Vertical strips between the top and bottom strips |
| `alClient` | Fills the remaining center area |

For example, put a sidebar and an editor in the same Grid. Set the sidebar's
Width to 240 and Align to `alRight`, set the editor's Align to `alClient`.
The sidebar reserves space and the editor fills the rest as the window resizes.
Controls dock from their respective edges in XAML child order.

Align writes normal [WinUI Grid rows and columns](https://learn.microsoft.com/en-us/windows/apps/develop/ui/layout-panels),
with Auto-sized edge tracks and a star-sized center. It resets the selected
control's placement Margin and clears explicit Width/Height on stretched axes.
The generated definitions are marked by `RADWinUI Align` comments in the original
XAML. The compiled app uses the same native layout without a custom panel or
runtime alignment engine. A Grid with custom row/column definitions is preserved,
use a nested Grid for Align in that case. Multiple `alClient` controls share the
center cell, so use a nested layout to arrange them individually.

### Rendering and edits

- The preview loads the same XAML text as the editor, with event attributes, `x:Class`, `x:DataType` and `DataContextType` blanked and `<Window>` turned into a `Grid`, error lines are those of the file.
- Elements without `x:Name` get a `Tag="__rwN"` (or `Name="__rwnN"` when they have their own `Tag`) in the preview only, so a click finds their start tag.
- The designer edits the text: one attribute (property grid), one element inserted, moved or deleted (toolbox click or drag, element drag, Delete). Formatting, comments and attribute order elsewhere stay as they are. Drops go into a `StackPanel` (by position, at the insertion line) or, placed where dropped, into a `Grid` (cell under the point, `Margin` with Left/Top alignment) or a `Canvas` (`Canvas.Left`/`Canvas.Top`). New windows from the wizard have a Grid root.
- Double-clicking an IDE Tool Palette item inserts it immediately near the selected element, or near the surface's top-left when nothing is selected. Palette drags use OLE text data received by the isolated WinUI overlay, following the [Windows drag-and-drop API](https://learn.microsoft.com/en-us/windows/apps/develop/data/drag-and-drop), the IDE still applies the resulting XAML edit.
- Not in the designer: templates and styles, animations, custom controls in the toolbox.
