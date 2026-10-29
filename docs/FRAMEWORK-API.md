# Framework API

Implemented in `src/Framework` and `src/Generated/RADWinUI.Xaml.pas`, the samples use it and pass `scripts/Test-Samples.ps1` in Debug and Release.

The goal: apps with no raw COM code. App code uses Delphi strings, Delphi objects and Delphi events, `RADWinUI.Abi` stays available underneath but app code does not need it.

## Layers

| Unit | Kind | Content |
| --- | --- | --- |
| `RADWinUI.Abi` | generated | Raw ABI interfaces, `safecall` |
| `RADWinUI.Framework` | hand-written | `TWinUIObject` base, `TWinValue`, `TWinUIEvent<T>`, list classes, `Thickness()` |
| `RADWinUI.Xaml` | generated | One `TWinUI<Name>` wrapper per runtime class in `Microsoft.UI.*`, event handler types, `TWinUI` aliases of enums and structs |
| `RADWinUI.Forms` | hand-written | `TWinUIWindow`, `TWinUIApp`, `TWinUITimer` |

## Wrapper classes

<img src="images/tool-palette-light.png" alt="TWinUI wrapper classes in the Tool Palette" width="260" />

WinMDGen emits a Delphi class per runtime class in `Microsoft.UI.*` (controls, event args, windowing, composition), named `TWinUI` plus the WinRT name: `TWinUIButton`, `TWinUITextBox`, `TWinUIStackPanel`, `TWinUIRoutedEventArgs`. The class tree mirrors the WinRT one, so `TWinUIButton` inherits `TWinUIButtonBase`, `TWinUIContentControl`, `TWinUIControl`, `TWinUIFrameworkElement`, `TWinUIUIElement` and `TWinUIDependencyObject`. Each class merges the properties, events and simple methods of every non-protected, non-overridable interface its runtime class implements. Nothing is hand-written per control.

Two wrappers are renamed to leave the plain names to the framework:

| Runtime class | Generated wrapper | Use instead |
| --- | --- | --- |
| `Microsoft.UI.Xaml.Window` | `TWinUICustomWindow` (like the VCL `TCustomForm`) | `TWinUIWindow`, which derives from it |
| `Microsoft.UI.Xaml.Application` | `TWinUICustomApplication` | `TWinUIApp` |

The generator stops with an error when any other generated name would clash with a framework type.

Type mapping:

| ABI | Wrapper |
| --- | --- |
| `HSTRING` | `string` |
| Runtime class (`IUIElement`) | Wrapper class (`TWinUIUIElement`), the most derived one the program links |
| `Object` (`Content`, `Header`, `Tag`) | `TWinValue` |
| `IVector<T>` of a runtime class (`Children`) | `TWinUIList<TWinUIUIElement>` |
| `IVector<Object>` (`Items`) | `TWinUIValueList` |
| Enum or struct | `TWinUI` alias (`TWinUIOrientation`, `TWinUIThickness`), the same type as in `RADWinUI.Abi` |
| Numbers, Boolean | unchanged |
| Interfaces that are not runtime classes (`ICommand`), delegates, generic instances | raw ABI type |

Every wrapper also exposes the raw object (`Button.WinRTObject`) and its default interface (`Button.Intf`) as an escape hatch.

Only the wrappers a program uses are linked: each registers itself in a class constructor. When an object's own wrapper is not linked (a `StackPanel` in a program that only mentions `TWinUIPanel`), `Wrap` asks the object for its interfaces (`GetIids`) and uses the deepest linked wrapper whose default interface it implements.

## Events

Each WinRT event gives two members:

```pascal
// VCL-style single handler, for the designer and published methods
TWinUIRoutedEventHandler = procedure(Sender: TObject; E: TWinUIRoutedEventArgs) of object;
Button.OnClick := ButtonClick;

// Any number of anonymous-method listeners; Add returns an id for Remove
Id := Button.Click.Add(
  procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
  begin
    Greet('code button');
  end);
Button.Click.Remove(Id);
```

- `Sender` is the wrapper object, `E` is a wrapper of the event args (`TWinUIRoutedEventArgs`, `TWinUITextChangedEventArgs`, `TWinUIWindowEventArgs`, ...) with Delphi-typed properties.
- An event args wrapper lives for one call: it is freed when the handlers return, so a handler must not keep `E` or objects reached through it.
- Handler type names follow the args: `RoutedEventArgs` gives `TWinUIRoutedEventHandler`, `WindowEventArgs` gives `TWinUIWindowEventHandler`. Events whose args are `Object` pass a `TWinValue`.
- One WinRT handler per event serves `OnXxx` and all listeners. It is registered on first use and removed in the wrapper's destructor, so a destroyed wrapper is never called.
- A published method named after the element and the event, such as `procedure IncrementButtonClick(Sender: TObject)`, is wired without a `Click` attribute in the XAML.

## Values and boxing

`TWinValue` is a record with implicit conversions:

```pascal
Button.Content := 'Increment';          // boxed with PropertyValue.CreateString
Button.Content := CounterText;          // a wrapper object
Button.Tag := 42;
S := Button.Content.AsString;
```

## Binding to Delphi lists

`ItemsSource` takes a `TWinUIBindableList<T>` (unit `RADWinUI.Binding`), and item templates bind to the published properties of `T`:

```pascal
{$M+}
TContact = class
published
  property Name: string read FName write FName;
  property Email: string read FEmail write FEmail;
end;

FContacts := TWinUIBindableList<TContact>.Create;   // owns its items
FContacts.Add(TContact.Create('Ali', 'ali@example.com'));
ContactList.ItemsSource := FContacts;               // <TextBlock Text="{Binding Name}"/> in the DataTemplate
Contact.Name := 'New name';
FContacts.ItemChanged(Contact, 'Name');             // the bound TextBlock updates
```

- The list belongs to Delphi code (free it in the window destructor), XAML follows `Add`, `Insert`, `Delete` and `Clear`, and cannot change it.
- Bindable properties are published `string`, integer, `Int64`, floating point, `Boolean` and enumeration properties, and objects (bound the same way, or a wrapper's WinRT object).

### DataContext and two-way binding

```pascal
TProfile = class(TWinUIBindableObject)      // a view model
published
  property Name: string read FName write SetName;   // SetName stores the value, then Changed('Name') and Changed('Summary')
  property Summary: string read GetSummary;
end;

ViewModel := TProfile.Create;              // generated from DataContextType="TProfile"; sets DataContext
```

```xml
<TextBox Text="{Binding Name, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}"/>
<TextBlock Text="{Binding Summary}"/>
```

- Typing in the TextBox calls the `Name` setter, `Changed` updates every binding of the named property.
- With `DataContextType="TProfile"` on `<Window>`, the generated base has `property ViewModel: TProfile`, declare `TProfile` in its own unit. Without it, assign `DataContext := FProfile` yourself.
- The window code frees its view model (`ViewModel.Free` in the destructor), bindings stop reading it once it is freed.
- Items of a `TWinUIBindableList<T>` that derive from `TWinUIBindableObject` can call `Changed` themselves instead of `ItemChanged`.
- A published property that returns another `TWinUIBindableObject` or a `TWinUIBindableList<T>` hands XAML that object's own bindable, so `DataContext="{Binding Detail}"` on a panel follows the nested view model's `Changed` calls too.

### Converters

```xml
<TextBlock Text="{Binding Name, Converter={StaticResource Format}, ConverterParameter='Hello, %s!'}"/>
<TextBlock Text="VIP" Visibility="{Binding IsVip, Converter={StaticResource BoolToVisibility}}"/>
<TextBlock Text="{Binding City, Converter={StaticResource Upper}}"/>
```

```pascal
// in the .dpr, before Run
TWinUIApp.RegisterConverter('Upper',
  function(const AValue: TWinValue; const AParameter: string): TWinValue
  begin
    Result := UpperCase(AValue.AsString);
  end);
```

- Built in: `BoolToVisibility`, `InverseBoolToVisibility`, `Format` (`ConverterParameter` is a Delphi `Format` string with one `%s`).
- A converter gets the bound value as `TWinValue` and `ConverterParameter` as text, a third argument to `RegisterConverter` converts back for two-way bindings.
- Return enum values with `WinUIBox(TWinUIVisibility.Collapsed)`.
- The build checks converter names (built in, registered with `RegisterConverter('Name', ...)` in the project's sources, or an `x:Key` in the XAML) and the `Format` parameter (one `%s`).

### Binding checks at build time

```xml
<Window x:Class="TProfileWindow" DataContextType="TProfile" ...>
    <TextBlock Text="{Binding Sumary}"/>   <!-- build error -->
```

```text
ProfileWindow.xaml(13): {Binding Sumary}: TProfile has no published property Sumary (published: City, IsVip, Name, Summary)
```

- Declare the type with `DataContextType` on `<Window>` and `x:DataType` on a `DataTemplate`, undeclared scopes are not checked.
- Paths may be nested (`Home.City`) through classes declared in the project's `.pas` files, `Mode=TwoWay` on a read-only property is an error too.

## Lifetime rules

1. A wrapper holds one strong reference to its WinRT object. The XAML tree holds the WinRT objects, never the wrappers.
2. Wrappers have an owner, as in the VCL: `TWinUIButton.Create(Window)`. The owner frees what it owns, `Owner = nil` means the caller frees it.
3. Wrapping an existing object (`FindElement`, `Children[I]`, `Window.Content`) returns the owner's existing wrapper of that object, or creates one owned by the same owner. One object, one wrapper per owner, so `Sender = MyButton` works.
4. A window owns every wrapper created for its content and frees them when it is destroyed. The application frees a window after its `Closed` event (like `caFree`).
5. Event args wrappers are freed after each event call (see Events).

## Errors

A failing HRESULT from any `safecall` raises `EWinRTError` with the HRESULT and the WinRT error message (`GetRestrictedErrorInfo`). An exception escaping a handler goes to `TWinUIApp.OnException` (Sender is the application, default: a message box) and the app keeps running. If the main window cannot be created, the exception is reported and the app exits.

## Windows and the application

```pascal
TWinUIWindow = class(TWinUICustomWindow)
public
  constructor Create; virtual;
  procedure Show;                          // Activate
  procedure Center;                        // on the work area of its display
  function FindElement<T: TWinUIObject>(const AName: string): T;
  function LoadContent(const AXaml: string): TWinUIFrameworkElement;
  property Title: string;                  // from TWinUICustomWindow
  property Content: TWinUIUIElement;       // from TWinUICustomWindow
  property Width, Height: Integer;         // client size in effective pixels
  property MinWidth, MinHeight: Integer;
  property Backdrop: TWinUIBackdrop;       // None, Mica, MicaAlt, Acrylic, Transparent
  property Transparency: Boolean;          // False: the root panel gets a solid theme colour instead of the backdrop
  class function SystemTransparency: Boolean; // False while Energy saver is on or Transparency effects is off
  procedure BindTransparencySwitch(ASwitch: TWinUIToggleSwitch); // a ready-made on/off switch with an honest tooltip
  property OnClosed: TWinUIWindowEventHandler;
end;

begin
  TWinUIApp.Run(TMainWindow);   // bootstrap, DPI awareness, Application.Start, create and show the window
end.
```

Mica and Acrylic show a solid colour whenever Windows turns transparency off (Energy saver, or Transparency effects off in Settings > Personalization > Colors) and while the window is inactive. An app cannot override that, `SystemTransparency` tells whether Windows allows it right now.

`TWinUITimer` is a repeating UI-thread timer like the VCL `TTimer` (`Interval` in milliseconds, `Enabled`, `OnTimer`).

### Overlay windows

A window can float over the desktop like a notch or a widget: no frame, no title bar, always on top and out of Alt+Tab and the taskbar.

```pascal
WindowStyle := TWinUIWindowStyle.Overlay;     // Normal or Overlay
Backdrop := TWinUIBackdrop.Transparent;       // only the content is drawn, the desktop shows through
Dock := TWinUIDock.TopCenter;                 // None, TopCenter, TopLeft, TopRight, BottomCenter of the work area
ClickThrough := TWinUIClickThrough.Background; // clicks outside HitTestElement reach the windows below
HitTestElement := Notch;                      // the part of the content that takes the pointer
ShowActivated := False;                       // Show does not take the focus from the active program
AlwaysOnTop := True;                          // Overlay sets it, a normal window can use it too
```

- All of them can be written as `<Window>` attributes too, except `HitTestElement` and `AlwaysOnTop`.
- `Dock` places the window again when the display settings change.
- With `ClickThrough`, the window's input region follows `HitTestElement`'s bounds as it grows and shrinks, so the transparent rest of the window never blocks a click.
- `Handle` is the window's HWND, and descendants can override `HandleMessage` to see its window messages.

The Overlay category of the Tool Palette has the controls such a window usually needs: a notch panel, glowing tiles, a global hotkey and the media playing on the PC. They are described in [CUSTOM-CONTROLS.md](CUSTOM-CONTROLS.md).

## Animations (RADWinUI.Motion)

`TWinUIMotion` animates any element through the Composition visual behind it. The animations run on the compositor thread, stay smooth while the UI thread works, and need no timer:

```pascal
TWinUIMotion.Enter(Card, 120);              // fade in and slide up, 120 ms from now
TWinUIMotion.Leave(Page);                   // fade out and slide away
TWinUIMotion.Drift(Bubble, 0, -40, 9000);   // float back and forth forever
TWinUIMotion.Reveal(ChartCanvas, 200, 900); // draw in from left to right
TWinUIMotion.Grow(Bar, False);              // grow from the left edge
TWinUIMotion.Sweep(Donut);                  // turn in with a fade
TWinUIMotion.SlideTo(Indicator, 196, 0);    // move to a new place
TWinUIMotion.Hero(Hero, DX, DY, SX, SY);    // fly from another element's place and size
TWinUIMotion.Lift(Card, True);              // a hover lift, False puts it back
TWinUIMotion.Pulse(Dot);                    // a short pop
TWinUIMotion.Reset(Card);                   // stop and show the element at rest
```

- Durations and delays are in milliseconds.
- Elements keep their XAML layout: the animations use the visual's `Opacity`, `Translation`, `Scale`, `RotationAngleInDegrees` and `Clip`. Do not combine them with the element's own `Opacity`, `Translation` or `Scale` properties.
- Sizes come from `ActualWidth` and `ActualHeight`, so start size-dependent animations (`Reveal`, `Grow`, `Sweep`, `Lift`) once the element has a layout, for example from a `Loaded` handler.
- The Lucent sample uses all of them.

## Samples

### Counter

```pascal
type
  // Generated by XamlCodeGen from MainWindow.xaml (shortened)
  TMainWindowBase = class(TWinUIWindow)
  protected
    CounterText: TWinUITextBlock;
    IncrementButton: TWinUIButton;
  public
    constructor Create; override;     // loads the XAML, wraps the x:Name elements
  end;

  TMainWindow = class(TMainWindowBase)
  private
    FCounter: Integer;
  published
    procedure IncrementButtonClick(Sender: TObject; E: TWinUIRoutedEventArgs);
  end;

procedure TMainWindow.IncrementButtonClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  Inc(FCounter);
  CounterText.Text := FCounter.ToString;
end;
```

### Form in code (samples/Greeter)

```pascal
  Panel := TWinUIStackPanel.Create(Self);
  Panel.Spacing := 12;
  Panel.Padding := Thickness(32);
  FNameBox := TWinUITextBox.Create(Self);
  FNameBox.PlaceholderText := 'Type your name';
  FNameBox.TextChanged.Add(
    procedure(Sender: TObject; E: TWinUITextChangedEventArgs)
    begin
      FGreeting.Text := '';
    end);
  FGreetButton := TWinUIButton.Create(Self);
  FGreetButton.Content := 'Greet';
  FGreetButton.OnClick := GreetClick;
  Panel.Children.Add(FNameBox);
  Panel.Children.Add(FGreetButton);
  Content := Panel;
```

### List (samples/ListDemo)

```pascal
  FList := TWinUIListView.Create(Self);
  for S in ['Apple', 'Banana', 'Cherry'] do
    FList.Items.Add(S);
  FList.OnSelectionChanged := ListSelectionChanged;

procedure TListWindow.ListSelectionChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
begin
  FStatus.Text := 'Selected: ' + FList.SelectedItem.AsString;
end;
```

## Trade-offs

- Generated wrappers cover every class at once and follow SDK updates by regenerating, the price is one large generated unit (about 110k lines, 1102 classes) and names taken from WinRT. Hand-written helpers (`Center`, `Backdrop`) exist only where the WinRT API is awkward.
- Class wrappers instead of records give `Sender: TObject`, owner-based lifetime and published-method wiring, at the cost of one Delphi object per wrapped element and per event call for the args.
- Linking only used wrappers keeps a Release sample near 500 KB.
