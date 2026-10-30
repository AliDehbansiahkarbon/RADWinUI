# Controls written in Delphi

RADWinUI controls do not have to come from WinUI. A class derived from `TWinUICustomControl` (unit `RADWinUI.CustomControls`) is a real XAML element: XAML creates it, its properties are dependency properties, so bindings, styles and animations work on them, and Pascal sees the same object through `FindElement`.

RADWinUI's own controls are built this way. They are in `RADWinUI.Controls` and on the Tool Palette in the Overlay category.

## Using them in XAML

Declare the `rw:` namespace once on `<Window>`. The designer adds it when you drop one of these controls.

```xml
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:rw="using:RADWinUI.Controls"
        x:Class="TMainWindow" WindowStyle="Overlay" Backdrop="Transparent" Dock="TopCenter"
        ClickThrough="Background" ShowActivated="False" Width="720" Height="320">
    <Grid>
        <rw:NotchPanel x:Name="Notch" ExpandedWidth="640" ExpandedHeight="260" Expanded="NotchExpanded">
            <rw:NotchPanel.Pill>
                <TextBlock Text="12:30" Foreground="White"/>
            </rw:NotchPanel.Pill>
            <rw:GlowTile x:Name="BuildTile" Background="#1C1C1E" CornerRadius="16" GlowBrush="Orange" Pulse="True"/>
        </rw:NotchPanel>
        <rw:HotKey Keys="Ctrl+Alt+T" Pressed="HotKeyPressed"/>
        <rw:MediaSession x:Name="Media"/>
    </Grid>
</Window>
```

XamlCodeGen gives every named element a typed field (`Notch: TWinUINotchPanel`) and adds `RADWinUI.Controls` to the generated unit's uses clause. Their events take `(Sender: TObject; const E: TWinValue)` or `(Sender: TObject)`.

## The Overlay controls

| Control | What it does | Properties | Events |
| --- | --- | --- | --- |
| `TWinUINotchPanel` | A pill that grows into a panel when the pointer rests on it, and shrinks back when it leaves. `Pill` is the pill's content, `Content` the panel's. `Expand`, `Collapse` and `Toggle` do it from code. | `IsExpanded`, `CollapsedWidth`, `CollapsedHeight`, `ExpandedWidth`, `ExpandedHeight`, `ExpandedCornerRadius`, `SquareTop`, `AttachedEdge` (Top, Bottom, Left, Right), `ExpandOnHover`, `HoverDelay`, `CollapseDelay`, `AnimationDuration`, `Pill` | `Expanded`, `Collapsed` |
| `TWinUIGlowTile` | A rounded tile with a coloured glow. A new `GlowBrush` fades the glow to the new colour, `Pulse` makes it breathe, `FadeAfter` lets it fade out by itself. A see-through `Background` (a solid colour with alpha below 255) shows what is behind the tile, the glow then stays around its edge. | `GlowBrush`, `IsGlowing`, `GlowRadius`, `GlowOpacity`, `Pulse`, `FadeAfter` | `Click` |
| `TWinUIHotKey` | A system-wide keyboard shortcut, written like `Ctrl+Alt+T`. It fires while any program has the focus. `Registered` is False when another program owns the shortcut already. | `Keys`, `IsActive` | `Pressed` |
| `TWinUIMediaSession` | The music or video playing on the PC (Spotify, a browser, Media Player), as the Windows volume flyout shows it. `Play`, `Pause`, `PlayPause`, `Next` and `Previous` control it. | `Title`, `Artist`, `AlbumTitle`, `SourceApp`, `IsPlaying`, `HasSession` | `Changed` |

`TWinUIHotKey` and `TWinUIMediaSession` have no look. They stay collapsed wherever you put them.

The overlay window itself is a set of `TWinUIWindow` properties, described in [FRAMEWORK-API.md](FRAMEWORK-API.md#overlay-windows).

## Writing your own

```pascal
uses
  RADWinUI.CustomControls;

type
  TBadge = class(TWinUICustomControl)
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
  published
    property Caption: string index 0 read GetText write SetText;
    property Count: Integer index 1 read GetInt32 write SetInt32;
    property OnTapped: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

class procedure TBadge.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Caption', TWinUIPropertyKind.Text);
  AType.AddProperty('Count', TWinUIPropertyKind.Int32, '0');
  AType.AddEvent('Tapped');
end;

procedure TBadge.Initialize;
begin
  UseTemplate(
    '<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:rw="using:RADWinUI.Controls" TargetType="rw:Badge">' +
    '<TextBlock Text="{TemplateBinding Caption}"/></ControlTemplate>');
end;

procedure TBadge.PropertyChanged(AIndex: Integer);
begin
  // a property changed, from XAML, a binding or Pascal
end;

initialization
  TWinUICustomControls.Register(TBadge, 'Badge', 'My controls');
end.
```

- `DefineType` lists the properties and events. The property index of each published property is its position in that list, the event index its position among the events.
- Property kinds: `Boolean`, `Int32`, `Double`, `Text`, `Brush`, `Value` (any object, like `Content`) and `Enum` (a Delphi enumeration, XAML writes its names).
- `Initialize` runs once, before XAML sets any property. `UseTemplate` gives the control its look, `TemplatePart` finds a named element of the template once it is loaded.
- `Fire(Index)` raises an event: its `On` handler first, then the listeners added with `EventByName(Name).Add`.
- `Create(Owner)` makes one from Pascal. Add it to a panel's `Children` like any other element.

The type index XamlCodeGen and the designer read is `src\Framework\RADWinUI.Controls.json`. `scripts\Generate-Projection.ps1` writes it with `tools\ControlsIndex`, and `tests\CustomControls\OverlayControlsTest` fails when it is out of date. Controls of your own units work in XAML that you load yourself (`LoadContent`). Window `.xaml` files, which XamlCodeGen checks, and the Tool Palette know RADWinUI's own controls only for now.

## How it works

Each element is a COM aggregate, the way C# and C++/WinRT build one: a Delphi outer object around WinUI's `ContentControl`. The application's `IXamlMetadataProvider` answers XAML's questions about `RADWinUI.Controls.*` types with the registered descriptions, and the dependency properties are registered with `DependencyProperty.Register` the first time a type is used.

Tests: `tests\CustomControls\CustomControlTest` (every property kind, bindings both ways, template, events, creation from Pascal) and `tests\CustomControls\OverlayControlsTest` (the Overlay controls).
