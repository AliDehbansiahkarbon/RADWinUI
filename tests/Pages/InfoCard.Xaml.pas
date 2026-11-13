unit InfoCard.Xaml;

{
  TInfoCardBase: base class of the user control TInfoCard, generated from InfoCard.xaml
  by RADWinUI XamlCodeGen 0.5 (tools/XamlCodeGen).

  DO NOT EDIT. Change InfoCard.xaml or the published handlers of TInfoCard
  in InfoCard.pas; the build regenerates this unit.

  Fields      one per x:Name element, in XAML order
  Initialize  loads the content, fills the fields, wires the events
  Register    makes TInfoCard the XAML element <local:InfoCard>
  Comments    name the XAML line each item comes from
}

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.CustomControls;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TInfoCardBase = class(TWinUIXamlUserControl)
  protected
    TitleText: TWinUITextBlock;  // InfoCard.xaml(7) <TextBlock>
    GoButton: TWinUIButton;      // InfoCard.xaml(8) <Button>
    procedure WireXaml;
    {$IFDEF DEBUG}
    procedure ReloadXaml(const AXaml: string);
    {$ENDIF}
    procedure Initialize; override;
  end;
  {$M-}

implementation

uses
  {$IFDEF DEBUG}
  RADWinUI.HotReload,
  {$ENDIF}
  InfoCard;  // TInfoCard, registered below

const
  // InfoCard.xaml(5): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<Border xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Padding="8">' + sLineBreak +
    '    <StackPanel>' + sLineBreak +
    '      <TextBlock x:Name="TitleText" />' + sLineBreak +
    '      <Button x:Name="GoButton" Content="Go" />' + sLineBreak +
    '    </StackPanel>' + sLineBreak +
    '  </Border>' + sLineBreak;
  {$IFDEF DEBUG}
  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild
  XamlShape = 'F:TitleText:TWinUITextBlock;F:GoButton:TWinUIButton;E:GoButton.Click=GoClick';
  {$ENDIF}

procedure TInfoCardBase.Initialize;
begin
  inherited;
  LoadContentXaml(ContentXaml);
  WireXaml;
  {$IFDEF DEBUG}
  AddHelper(TXamlHotReload.Watch(Self, 'InfoCard.xaml', XamlShape, ReloadXaml));
  {$ENDIF}
end;

// The x:Name fields and the event wiring of the content, again after a hot reload
procedure TInfoCardBase.WireXaml;
begin
  // x:Name elements
  TitleText := FindElement<TWinUITextBlock>('TitleText');
  GoButton := FindElement<TWinUIButton>('GoButton');
  // Event wiring
  // InfoCard.xaml(8): Click="GoClick"
  GoButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('GoClick'));
end;

{$IFDEF DEBUG}
// Hot reload: InfoCard.xaml edited in the IDE while the app runs
procedure TInfoCardBase.ReloadXaml(const AXaml: string);
begin
  LoadContentXaml(AXaml);
  WireXaml;
end;
{$ENDIF}

initialization
  TWinUICustomControls.Register(TInfoCard, 'InfoCard', 'User controls');
end.
