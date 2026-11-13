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
    Caption: TWinUITextBlock;   // MainWindow.xaml(7) <TextBlock>
    Bound: TWinUITextBlock;     // MainWindow.xaml(8) <TextBlock>
    CountButton: TWinUIButton;  // MainWindow.xaml(9) <Button>
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
    '<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Padding="16" Spacing="8">' + sLineBreak +
    '        <TextBlock x:Name="Caption" Text="Before" />' + sLineBreak +
    '        <TextBlock x:Name="Bound" Text="{Binding}" />' + sLineBreak +
    '        <Button x:Name="CountButton" Content="Count" />' + sLineBreak +
    '    </StackPanel>' + sLineBreak;
  {$IFDEF DEBUG}
  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild
  XamlShape = 'F:Caption:TWinUITextBlock;F:Bound:TWinUITextBlock;F:CountButton:TWinUIButton;E:CountButton.Click=CountButtonClick';
  {$ENDIF}

constructor TMainWindowBase.Create;
begin
  inherited;
  // MainWindow.xaml(1): <Window> attributes
  Title := 'HotReloadTest';
  Width := 480;
  Height := 320;
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
  Caption := FindElement<TWinUITextBlock>('Caption');
  Bound := FindElement<TWinUITextBlock>('Bound');
  CountButton := FindElement<TWinUIButton>('CountButton');
  // Event wiring
  // MainWindow.xaml(9): CountButtonClick by name
  CountButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('CountButtonClick'));
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
