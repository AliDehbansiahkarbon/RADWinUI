unit GreetWindow.Xaml;

{
  TGreetWindowBase: base class of TGreetWindow, generated from GreetWindow.xaml
  by RADWinUI XamlCodeGen 0.5 (tools/XamlCodeGen).

  DO NOT EDIT. Change GreetWindow.xaml or the published handlers of TGreetWindow
  in GreetWindow.pas; the build regenerates this unit.

  Fields      one per x:Name element, in XAML order
  Create      window settings, content, fields, event wiring
  Comments    name the XAML line each item comes from
}

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Forms;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TGreetWindowBase = class(TWinUIWindow)
  protected
    NameBox: TWinUITextBox;                  // GreetWindow.xaml(8) <TextBox>
    GreetButton: TWinUIButton;               // GreetWindow.xaml(9) <Button>
    Greeting: TWinUITextBlock;               // GreetWindow.xaml(10) <TextBlock>
    TransparencySwitch: TWinUIToggleSwitch;  // GreetWindow.xaml(11) <ToggleSwitch>
    procedure WireXaml;
    {$IFDEF DEBUG}
    procedure ReloadXaml(const AXaml: string);
    {$ENDIF}
  public
    constructor Create; override;
  end;
  {$M-}

implementation

{$IFDEF DEBUG}
uses
  RADWinUI.HotReload;
{$ENDIF}

const
  // GreetWindow.xaml(7): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Spacing="12" Padding="32">' + sLineBreak +
    '        <TextBox x:Name="NameBox" Header="Name" PlaceholderText="Type your name" />' + sLineBreak +
    '        <Button x:Name="GreetButton" Content="Greet" />' + sLineBreak +
    '        <TextBlock x:Name="Greeting" FontSize="24" />' + sLineBreak +
    '        <ToggleSwitch x:Name="TransparencySwitch" Header="Transparency" />' + sLineBreak +
    '    </StackPanel>' + sLineBreak;
  {$IFDEF DEBUG}
  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild
  XamlShape = 'F:NameBox:TWinUITextBox;F:GreetButton:TWinUIButton;F:Greeting:TWinUITextBlock;F:TransparencySwitch:TWinUIToggleSwitch;E:GreetButton.Click=GreetButtonClick;E:NameBox.TextChanged=NameBoxTextChanged';
  {$ENDIF}

constructor TGreetWindowBase.Create;
begin
  inherited;
  // GreetWindow.xaml(1): <Window> attributes
  Title := 'Greeter';
  Width := 480;
  Height := 320;
  MinWidth := 360;
  MinHeight := 240;
  Backdrop := TWinUIBackdrop.Mica;
  Center;
  LoadContent(ContentXaml);
  WireXaml;
  {$IFDEF DEBUG}
  AddHelper(TXamlHotReload.Watch(Self, 'GreetWindow.xaml', XamlShape, ReloadXaml));
  {$ENDIF}
end;

// The x:Name fields and the event wiring of the content, again after a hot reload
procedure TGreetWindowBase.WireXaml;
begin
  // x:Name elements
  NameBox := FindElement<TWinUITextBox>('NameBox');
  GreetButton := FindElement<TWinUIButton>('GreetButton');
  Greeting := FindElement<TWinUITextBlock>('Greeting');
  TransparencySwitch := FindElement<TWinUIToggleSwitch>('TransparencySwitch');
  // Event wiring
  // GreetWindow.xaml(8): NameBoxTextChanged by name
  NameBox.OnTextChanged := TWinUITextChangedEventHandler(PublishedMethod('NameBoxTextChanged'));
  // GreetWindow.xaml(9): GreetButtonClick by name
  GreetButton.OnClick := TWinUIRoutedEventHandler(PublishedMethod('GreetButtonClick'));
end;

{$IFDEF DEBUG}
// Hot reload: GreetWindow.xaml edited in the IDE while the app runs
procedure TGreetWindowBase.ReloadXaml(const AXaml: string);
begin
  LoadContent(AXaml);
  WireXaml;
end;
{$ENDIF}

end.
