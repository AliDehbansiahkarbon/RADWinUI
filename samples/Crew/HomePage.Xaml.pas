unit HomePage.Xaml;

{
  THomePageBase: base class of the page THomePage, generated from HomePage.xaml
  by RADWinUI XamlCodeGen 0.5 (tools/XamlCodeGen).

  DO NOT EDIT. Change HomePage.xaml or the published handlers of THomePage
  in HomePage.pas; the build regenerates this unit.

  Fields      one per x:Name element, in XAML order
  Create      loads the page, fills the fields, wires the events
  Comments    name the XAML line each item comes from
}

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  PersonCard,
  RADWinUI.Pages;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  THomePageBase = class(TWinUIXamlPage)
  protected
    PageTitle: TWinUITextBlock;  // HomePage.xaml(8) <TextBlock>
    Summary: TWinUITextBlock;    // HomePage.xaml(9) <TextBlock>
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
  // HomePage.xaml(1): the page; event attributes became the
  // wiring below, x:Class, x:DataType and RADWinUI attributes are removed
  PageXaml =
    '<Page xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:ns2="using:Crew" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' + sLineBreak +
    '  <ScrollViewer>' + sLineBreak +
    '    <StackPanel Spacing="8" MaxWidth="720" HorizontalAlignment="Left">' + sLineBreak +
    '      <TextBlock x:Name="PageTitle" Text="Home" Style="{StaticResource TitleLargeTextBlockStyle}" />' + sLineBreak +
    '      <TextBlock x:Name="Summary" Opacity="0.7" TextWrapping="Wrap" />' + sLineBreak +
    '      <TextBlock Text="Favourites" Style="{StaticResource SubtitleTextBlockStyle}" Margin="0,20,0,4" />' + sLineBreak +
    '      ' + sLineBreak +
    '      <ns2:PersonCard PersonName="Ada Lovelace" Role="Engineering lead" x:Name="_rw1" />' + sLineBreak +
    '      <ns2:PersonCard PersonName="Grace Hopper" Role="Platform architect" x:Name="_rw2" />' + sLineBreak +
    '      <ns2:PersonCard PersonName="Alan Turing" Role="Research" x:Name="_rw3" />' + sLineBreak +
    '      <HyperlinkButton Content="See everyone" Margin="0,12,0,0" x:Name="_rw4" />' + sLineBreak +
    '    </StackPanel>' + sLineBreak +
    '  </ScrollViewer>' + sLineBreak +
    '</Page>';
  {$IFDEF DEBUG}
  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild
  XamlShape = 'F:PageTitle:TWinUITextBlock;F:Summary:TWinUITextBlock;E:_rw1.Opened=CardOpened;E:_rw2.Opened=CardOpened;E:_rw3.Opened=CardOpened;E:_rw4.Click=EveryoneClick';
  {$ENDIF}

constructor THomePageBase.Create;
begin
  inherited CreateFromXaml(PageXaml);
  WireXaml;
  {$IFDEF DEBUG}
  AddHelper(TXamlHotReload.Watch(Self, 'HomePage.xaml', XamlShape, ReloadXaml));
  {$ENDIF}
end;

// The x:Name fields and the event wiring of the content, again after a hot reload
procedure THomePageBase.WireXaml;
begin
  // x:Name elements
  PageTitle := FindElement<TWinUITextBlock>('PageTitle');
  Summary := FindElement<TWinUITextBlock>('Summary');
  // Event wiring
  // HomePage.xaml(12): Opened="CardOpened"
  FindElement<TPersonCard>('_rw1').OnOpened := TWinUIWinValueEventHandler(PublishedMethod('CardOpened'));
  // HomePage.xaml(13): Opened="CardOpened"
  FindElement<TPersonCard>('_rw2').OnOpened := TWinUIWinValueEventHandler(PublishedMethod('CardOpened'));
  // HomePage.xaml(14): Opened="CardOpened"
  FindElement<TPersonCard>('_rw3').OnOpened := TWinUIWinValueEventHandler(PublishedMethod('CardOpened'));
  // HomePage.xaml(15): Click="EveryoneClick"
  FindElement<TWinUIHyperlinkButton>('_rw4').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('EveryoneClick'));
end;

{$IFDEF DEBUG}
// Hot reload: HomePage.xaml edited in the IDE while the app runs
procedure THomePageBase.ReloadXaml(const AXaml: string);
begin
  ReplaceXaml(AXaml);
  WireXaml;
end;
{$ENDIF}

end.
