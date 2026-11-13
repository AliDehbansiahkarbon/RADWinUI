# WinUI inside VCL forms

`TWinUIHost` (unit `RADWinUI.VclHost`) puts WinUI 3 content on a VCL form. Drop it on the form, write XAML in its `Xaml` property, and the area it covers shows real WinUI controls while the rest of the form stays VCL. An existing VCL application gets a modern screen one panel at a time, without a rewrite.

It uses XAML Islands: a `DesktopWindowXamlSource` whose window is a child of the host control.

## Setting it up

1. Add the RADWinUI source folders to the VCL project's search path: `src\Interop`, `src\Generated`, `src\Runtime` and `src\Framework` of your RADWinUI folder.
2. Copy `Microsoft.WindowsAppRuntime.Bootstrap.dll` next to the exe with the RADWinUI post-build step, as the samples do: `call "<RADWinUI>\scripts\RADWinUI-PostBuild.cmd" "$(OUTPUTDIR)"`.
3. Build for Win64. The app needs the Windows App Runtime, like every RADWinUI app ([Deployment](DEPLOYMENT.md)).
4. Drop **TWinUIHost** from the Tool Palette's **RADWinUI** category on the form.

At design time the host is a placeholder that names its content (`<StackPanel>, 12 lines of XAML`). The content shows when the app runs: no WinUI code runs in the IDE.

## Properties

| Member | |
| --- | --- |
| `Xaml` | The XAML of the content. When the root element has no `xmlns`, the WinUI namespaces (default and `x:`) are added. Changing it loads the content again: set the whole text at once (`Xaml.Text := ...`). |
| `XamlFile` | A `.xaml` file that holds the content in place of `Xaml`: setting it clears `Xaml`. The **...** button in the Object Inspector picks the file and stores it relative to the project folder. A relative path is looked for next to the exe, then in the two folders above it (the project folder while the exe runs from `Win64\Debug`): deploy the file next to the exe. |
| `Theme` | `htAuto` (default) picks light or dark from the host's `Color` and paints the content's background in that colour. `htLight` and `htDark` force the theme: the background stays the host's `Color` when it suits the theme, otherwise it is WinUI's own background for it (#F3F3F3 or #202020), so the text is always readable. |
| `OnLoaded` | After the content loaded and its events were wired, the place to reach elements. It runs again after each reload. |
| `Content` | The root element (`TWinUIFrameworkElement`), nil before the content loads. |
| `FindElement<T>(Name)` | The element with that `x:Name` as its wrapper class, nil when there is none: `WinUIHost1.FindElement<TWinUITextBox>('NameBox').Text`. |
| `DataContext` | The source of the content's `{Binding}`s, usually a `TWinUIBindableObject` (`RADWinUI.Binding`). It is kept when the content loads again. |
| `LoadError` | Why the content did not load, `''` when it did. A XAML error does not raise: the host shows the message in red and keeps it here. |
| `Reload` | Loads the content again from `Xaml` or `XamlFile`. |

`Align`, `Anchors`, `Color`, `TabOrder`, `TabStop` and the other usual control properties work as on any VCL control.

## Events

Handlers are published methods of the form, `procedure(Sender: TObject)`, like VCL event handlers:

```xml
<Button Content="Revert" Click="RevertClick"/>
<Button x:Name="SaveButton" Content="Save"/>  <!-- SaveButtonClick, found by its name -->
```

A XAML attribute names the method, or a method named `<x:Name><Event>` is found by itself. These events are wired this way: `Click`, `Toggled`, `Checked`, `Unchecked`, `TextChanged`, `PasswordChanged`, `SelectionChanged`, `ValueChanged`, `ItemClick`, `Loaded`, `Tapped`, `GotFocus` and `LostFocus`. Any other event, or a handler that needs the event's arguments, is wired in code:

```pascal
procedure TMainForm.DetailsHostLoaded(Sender: TObject);
begin
  DetailsHost.FindElement<TWinUICalendarDatePicker>('DueDate').DateChanged.Add(
    procedure(Sender: TObject; E: TWinUICalendarDatePickerDateChangedEventArgs)
    begin
      StatusBar.SimpleText := 'Due date changed';
    end);
end;
```

## Keyboard and focus

Tab moves from the VCL controls into the content (Shift+Tab enters at its last element), through it, and on to the next VCL control in the form's tab order. Keys typed in the content are WinUI's: Enter, Escape and the arrows do not reach the form's default and cancel buttons. `WinUIHost1.SetFocus` moves the focus into the content.

## How it works

The first host starts WinUI on the VCL main thread: the Windows App SDK bootstrap, a `DispatcherQueue`, the XAML application object, `WindowsXamlManager` and WinUI's control styles, in that order. A message hook gives WinUI its keyboard messages before VCL translates them (`ContentPreTranslateMessage`), so `Application.OnMessage` stays free for the app. The unit's finalization closes every island and shuts WinUI down after the last message.

## Limits

- One WinUI start per process, on the main thread: a VCL app with hosts does not also call `TWinUIApp.Run`, and `TWinUIApp`'s converters (`BoolToVisibility` and the others) are not registered.
- A recreated window handle (changing `BorderStyle`, docking the form) loads the content again: element state is lost and `OnLoaded` runs again.
- After the form is deactivated and activated again, the focus returns to the last VCL control, not into the content.
- Line and position numbers in XAML errors count the namespaces the host added to the root element.

The [Customers_VCL sample](samples-Customers_VCL.md) modernizes the details panel of a classic VCL screen.
