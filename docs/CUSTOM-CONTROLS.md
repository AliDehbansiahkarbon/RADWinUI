# Controls written in Delphi

RADWinUI controls do not have to come from WinUI. A class derived from `TWinUICustomControl` (unit `RADWinUI.CustomControls`) is a real XAML element: XAML creates it, its properties are dependency properties, so bindings, styles and animations work on them, and Pascal sees the same object through `FindElement`.

RADWinUI's own controls are built this way. They are in `RADWinUI.Controls`, `RADWinUI.TabBars`, `RADWinUI.ActionButtons` and `RADWinUI.DBControls`, and on the Tool Palette in the Overlay, Tab Bars, Action Buttons and Data Controls categories.

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

## The tab bars

Six animated tab bars, ready to drop from the Tab Bars category. Each one shows four tabs as soon as it is on the window.

| Control | What it does |
| --- | --- |
| `TWinUISlidingPillTabBar` | A violet to cyan pill springs to the tapped tab, stretching as it slides. |
| `TWinUILiquidBulgeTabBar` | The whole bar is the accent gradient. It bulges like liquid under the active tab, and the bulge flows over to the next one. |
| `TWinUIFloatingNotchTabBar` | A floating ball rides a curved notch in the bar and hops to the new tab. The selected tab's label shows under it. |
| `TWinUIIconFillTabBar` | The tapped icon fills with the accent from its centre, pops, and gets a small bar under it. |
| `TWinUIExpandingLabelTabBar` | The active tab grows into a pill and its label slides out. The other tabs make room. |
| `TWinUIBubbleFloatTabBar` | The tapped icon lifts and glows, and bubbles float up from it and pop. `BubbleCount` says how many. |

```xml
<rw:SlidingPillTabBar x:Name="Tabs" Items="Home:Home, Search:Search, Likes:Heart, Profile:Contact"
                      Pages="HomePage, SearchPage, LikesPage, ProfilePage" SelectionChanged="TabsChanged"/>
```

They all have these properties:

| Property | Meaning |
| --- | --- |
| `Items` | The tabs, `Label:Icon` separated by commas. The icon is a name such as Home, Search, Heart, Contact, Settings, Mail, Chat, Bell, Calendar, Cart, Camera, Music or Star, or a Segoe Fluent Icons code point such as `E80F`. `E80F/EA8A` gives the outline glyph and the one the selected tab shows filled. Without `:` the label names the icon too. In the Object Inspector, the `...` button opens an editor with every named icon. |
| `SelectedIndex` | The selected tab, from 0. Setting it animates the bar and fires `SelectionChanged`. `SelectNext` and `SelectPrevious` move it from code, Left, Right, Home and End from the keyboard. |
| `Pages` | Names of elements, one per tab, separated by commas. The selected tab's element is shown and the others are collapsed. |
| `AccentFrom`, `AccentTo` | The accent gradient, violet to cyan unless set. |
| `ActiveForeground` | The selected tab's icon and label. |
| `ShowLabels` | Labels under the icons. Floating Notch and Expanding Label show them unless set to False. |
| `IconSize`, `AnimationDuration` | Icon size in pixels, and how many milliseconds the selection takes to move. |
| `Background`, `BorderBrush`, `BorderThickness`, `Foreground`, `CornerRadius`, `Padding` | The usual Control properties: the bar, its edge, the icons of the other tabs, its corners and the room at its ends. |

Liquid Bulge and Floating Notch keep some room above the bar for the bulge and the ball, it is part of their `Height`. Bubble Float's bubbles rise above the bar, so leave some space over it.

`SelectedText` is the selected tab's label, `ItemCount` and `Item[Index]` read the tabs.

## The action buttons

Six animated buttons, ready to drop from the Action Buttons category. Each one shows its label as soon as it is on the window, and `Play` runs its effect from code.

| Control | What it does | Own properties | Event |
| --- | --- | --- | --- |
| `TWinUIHoldButton` | A round button. Hold it down and a ring fills around it, then it turns into a check and the caption under it changes to `DoneText`. Let go early and the ring runs back. | `DoneText`, `Icon` (a name such as Delete, or a Segoe Fluent Icons code point), `HoldDuration`, `ResetAfter`, `IsDone`, `Progress` | `Confirmed` |
| `TWinUISendButton` | A gradient pill. A click sends the paper plane off with a trail and the label flips to `DoneText`. | `DoneText`, `ResetAfter`, `IsDone` | `Click` |
| `TWinUIConfettiButton` | A gradient pill. A click bursts confetti out of it, the pieces flutter, turn over and fall. | `ConfettiCount` (up to 120), `FlyingCount` | `Click` |
| `TWinUICopyButton` | A field with a copy icon. A click puts `Text` on the clipboard, the icon turns into a check and a `DoneText` tooltip pops up above it. | `DoneText`, `ResetAfter`, `CopyToClipboard`, `IsDone` | `Copied` |
| `TWinUIShineButton` | A glowing gradient pill. A diagonal shine sweeps across it every `ShineInterval` and when the pointer comes over it, and sparkles twinkle around it. | `ShineInterval` (0 for hover and click only), `Sparkles`, `GlowBrush` | `Click` |
| `TWinUISlideButton` | A track with a knob. Drag the knob to the end: the track fills, the knob turns into a check and the label changes to `DoneText`. Let go before the end and it springs back. | `DoneText`, `ResetAfter`, `Shimmer`, `IsDone`, `Position` | `Confirmed` |

```xml
<rw:HoldButton x:Name="DeleteButton" Text="Hold to delete" DoneText="Deleted" Confirmed="DeleteConfirmed"/>
<rw:CopyButton x:Name="InviteLink" Text="join.app/x7Kq2" Copied="LinkCopied"/>
```

They all have these properties:

| Property | Meaning |
| --- | --- |
| `Text` | The label. The Copy button copies it, the Hold button shows it under the circle. |
| `AccentFrom`, `AccentTo` | The accent gradient. Each button has its own unless set: violet to cyan, violet to pink or blue. |
| `ResetAfter` | Milliseconds the done look stays before the button is back, 0 keeps it until `Reset`. Hold, Send, Copy and Slide have it. |
| `Background`, `BorderBrush`, `Foreground`, `FontSize`, `CornerRadius` | The usual Control properties: the surface of the Hold, Copy and Slide buttons, its edge, the text, and the corners of the Copy field. On a light `Background` the icons pick darker colours by themselves. |

Enter and Space work like a click, or like holding for the Hold button. The Slide button slides by itself on Enter or Space. `Play` runs a button's effect from code and `Reset` puts it back without animation. The confetti, the plane and the Copy tooltip go beyond the button's edges, so leave some space around them.

## The data controls

Seventeen data-aware controls in the Data Controls category. They work like the VCL's Data Controls: each one is bound to a `TDataSource` of `Data.DB`, shows the current record and writes the user's changes back. Any dataset works, such as FireDAC or `TClientDataSet`.

```xml
<rw:DBNavigator DataSource="CustomersSource" VisibleButtons="First, Prior, Next, Last, Post, Cancel"/>
<rw:DBGrid DataSource="CustomersSource" Columns="Name:180, City, Balance:110" Height="300"/>
<rw:DBEdit DataSource="CustomersSource" DataField="Name" Header="Name"/>
<rw:DBLookupComboBox DataSource="CustomersSource" DataField="CountryID"
                     ListSource="CountriesSource" KeyField="ID" ListField="CountryName" Header="Country"/>
```

`DataSource` in XAML is the name of a `TDataSource`. The control looks for it first among the published fields and properties of the window, then among the components of every data module the program has created, oldest first. `Module.Source` names the data module too. Create the data module before the window, so the window finds its data sources. `TWinUIDataSources.AddModule` lets the controls look into other owners of data components as well. In Pascal, the `DataSource` property takes the `TDataSource` itself, as in the VCL, and wins over the name in XAML:

```pascal
NameEdit.DataSource := CustomerData.CustomersSource;
```

They all have these properties:

| Property | Meaning |
| --- | --- |
| `DataSource` | The name of the `TDataSource`. |
| `DataField` | The field the control shows and edits. The grids and the navigator have none. |
| `ReadOnly` | The user cannot change the value. A field or dataset that cannot be changed makes the control read-only as well. |

Editing works like the VCL. Typing in a control or picking a value puts the dataset into Edit. The value goes into the field when the control loses the focus, and the record is written on `Post`. In a DBEdit, Enter writes the field and Esc puts the field's value back. A DBMemo takes Enter for a new line. The navigator's Post and Cancel buttons post or cancel the record, and moving to another row of a grid posts it. Errors of the dataset, such as a failed validation, are reported like other errors.

| Control | Like | Own properties |
| --- | --- | --- |
| `TWinUIDBGrid` | `TDBGrid` | `Columns`: the fields and their widths, `Field:Width, Field`, empty for every visible field. `ReadOnly` (False): the cells can be edited unless it is set. `SortOnHeaderClick` (True): a click on a header sorts datasets that have `IndexFieldNames`, such as FireDAC and `TClientDataSet`, and a second click sorts FireDAC down. `RowHeight` (36). |
| `TWinUIDBNavigator` | `TDBNavigator` | `VisibleButtons`: the buttons shown, separated by commas, from First, Prior, Next, Last, Insert, Delete, Edit, Post, Cancel and Refresh, empty for all. `ConfirmDelete` (True): Delete asks first in a flyout. The `Click` event, `ClickedButton` tells which button. `BtnClick` does what a button does from code. |
| `TWinUIDBText` | `TDBText` | `WordWrap` (False). |
| `TWinUIDBEdit` | `TDBEdit` | `Header`, `PlaceholderText`. |
| `TWinUIDBMemo` | `TDBMemo` | `Header`, `PlaceholderText`. Several lines of text. |
| `TWinUIDBImage` | `TDBImage` | `Stretch` (Uniform): None, Fill, Uniform or UniformToFill. Shows a PNG, JPEG, BMP or GIF from a BLOB field. `LoadFromFile` puts a picture into the field from code. |
| `TWinUIDBListBox` | `TDBListBox` | `Items`: the choices, separated by commas. |
| `TWinUIDBComboBox` | `TDBComboBox` | `Items`, `Header`, `PlaceholderText`, `IsEditable` (False): the user can also type a value that is not in `Items`. |
| `TWinUIDBCheckBox` | `TDBCheckBox` | `Text`, `ValueChecked` (True), `ValueUnchecked` (False). Several values can be separated by `;`, such as `Yes;Y`, and the first one is written. |
| `TWinUIDBRadioGroup` | `TDBRadioGroup` | `Items`, `Values`: the value written for each item, separated by commas, the item's text when there are none. `Header`, `Columns` (1). |
| `TWinUIDBLookupListBox` | `TDBLookupListBox` | `ListSource`, `KeyField`, `ListField`. |
| `TWinUIDBLookupComboBox` | `TDBLookupComboBox` | `ListSource`, `KeyField`, `ListField`, `Header`, `PlaceholderText`. |
| `TWinUIDBRichEdit` | `TDBRichEdit` | `Header`, `PlainText` (False): writes plain text instead of RTF. |
| `TWinUIDBCtrlGrid` | `TDBCtrlGrid` | `ItemTemplate`: a `DataTemplate` for one record, whose bindings name fields, such as `{Binding Name}`. `Tiles` (False): puts the records side by side. `ReadOnly` (False). |
| `TWinUIDBDatePicker` | WinUI's CalendarDatePicker | `Header`, `PlaceholderText`. |
| `TWinUIDBNumberBox` | WinUI's NumberBox | `Header`, `PlaceholderText`, `SpinButtons` (True). |
| `TWinUIDBToggleSwitch` | WinUI's ToggleSwitch | `Header`, `ValueChecked` (True), `ValueUnchecked` (False), as on the check box. |

The lookups take their choices from the records of `ListSource`, a data source named like `DataSource`. They show `ListField` and write `KeyField` into `DataField`.

```xml
<rw:DBCtrlGrid DataSource="CustomersSource" Tiles="True" ItemTemplate="{StaticResource CustomerTile}" Height="160"/>
```

In the Object Inspector, `DataSource` and `ListSource` list the data sources, and `DataField`, `KeyField` and `ListField` list the fields of their datasets. The lists come from the `.dfm` files of the project's data modules and forms, so persistent fields and `FieldDefs` are there, but fields a query only makes when it opens are not. Any name can be typed. The Design view has no data: there each control shows its field names as placeholders.

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
- `SetEditor(Name, 'tabitems')` gives a `Text` property the tab editor of the Object Inspector, as the tab bars' `Items` have it.
- `Initialize` runs once, before XAML sets any property. `UseTemplate` gives the control its look, `TemplatePart` finds a named element of the template once it is loaded.
- `Fire(Index)` raises an event: its `On` handler first, then the listeners added with `EventByName(Name).Add`.
- `Create(Owner)` makes one from Pascal. Add it to a panel's `Children` like any other element.

The type index XamlCodeGen and the designer read is `src\Framework\RADWinUI.Controls.json`. `scripts\Generate-Projection.ps1` writes it with `tools\ControlsIndex`, and `tests\CustomControls\OverlayControlsTest` fails when it is out of date. Controls of your own units work in XAML that you load yourself (`LoadContent`). Window `.xaml` files, which XamlCodeGen checks, and the Tool Palette know RADWinUI's own controls only for now.

## How it works

Each element is a COM aggregate, the way C# and C++/WinRT build one: a Delphi outer object around WinUI's `ContentControl`. The application's `IXamlMetadataProvider` answers XAML's questions about `RADWinUI.Controls.*` types with the registered descriptions, and the dependency properties are registered with `DependencyProperty.Register` the first time a type is used.

Tests: `tests\CustomControls\CustomControlTest` (every property kind, bindings both ways, template, events, creation from Pascal), `tests\CustomControls\OverlayControlsTest` (the Overlay controls), `tests\CustomControls\TabBarsTest` (the tab bars), `tests\CustomControls\ActionButtonsTest` (the action buttons) and `tests\CustomControls\DBControlsTest` (the data controls).
