unit MainWindow.Xaml;

{
  TMainWindowBase: base class of TMainWindow, generated from MainWindow.xaml
  by RADWinUI XamlCodeGen 0.5 (tools/XamlCodeGen).

  DO NOT EDIT. Change MainWindow.xaml or the published handlers of TMainWindow
  in MainWindow.pas; the build regenerates this unit.

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
  TMainWindowBase = class(TWinUIWindow)
  protected
    CounterText: TWinUITextBlock;   // MainWindow.xaml(7) <TextBlock>
    IncrementButton: TWinUIButton;  // MainWindow.xaml(8) <Button>
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
  // MainWindow.xaml(6): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Spacing="16" Padding="32">' + sLineBreak +
    '        <TextBlock x:Name="CounterText" Text="0" FontSize="32" />' + sLineBreak +
    '        <Button x:Name="IncrementButton" Content="Increment" />' + sLineBreak +
    '        <Button Content="Reset" x:Name="_rw1" />' + sLineBreak +
    '    </StackPanel>' + sLineBreak;
  {$IFDEF DEBUG}
  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild
  XamlShape = 'F:CounterText:TWinUITextBlock;F:IncrementButton:TWinUIButton;E:IncrementButton.Click=IncrementButtonClick;E:_rw1.Click=ResetClick';
  {$ENDIF}

constructor TMainWindowBase.Create;
begin
  inherited;
  // MainWindow.xaml(1): <Window> attributes
  Title := 'Counter';
  Width := 360;
  Height := 280;
  LoadContent(ContentXaml);
  WireXaml;
  {$IFDEF DEBUG}
  AddHelper(TXamlHotReload.Watch(Self, 'MainWindow.xaml', XamlShape, ReloadXaml));
  {$ENDIF}
end;

// The x:Name fields and the event wiring of the content, again after a hot reload
procedure TMainWindowBase.WireXaml;
begin
  // x:Name elements
  CounterText := FindElement<TWinUITextBlock>('CounterText');
  IncrementButton := FindElement<TWinUIButton>('IncrementButton');
  // Event wiring
  // MainWindow.xaml(8): IncrementButtonClick by name
  IncrementButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('IncrementButtonClick'));
  // MainWindow.xaml(9): Click="ResetClick"
  FindElement<TWinUIButton>('_rw1').OnClick := TWinUIRoutedEventHandler(PublishedMethod('ResetClick'));
end;

{$IFDEF DEBUG}
// Hot reload: MainWindow.xaml edited in the IDE while the app runs
procedure TMainWindowBase.ReloadXaml(const AXaml: string);
begin
  LoadContent(AXaml);
  WireXaml;
end;
{$ENDIF}

end.
