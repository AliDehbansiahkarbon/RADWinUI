unit SettingsPage.Xaml;

{
  TSettingsPageBase: base class of the page TSettingsPage, generated from SettingsPage.xaml
  by RADWinUI XamlCodeGen 0.5 (tools/XamlCodeGen).

  DO NOT EDIT. Change SettingsPage.xaml or the published handlers of TSettingsPage
  in SettingsPage.pas; the build regenerates this unit.

  Fields      one per x:Name element, in XAML order
  Create      loads the page, fills the fields, wires the events
  Comments    name the XAML line each item comes from
}

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Pages;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TSettingsPageBase = class(TWinUIXamlPage)
  protected
    PageTitle: TWinUITextBlock;    // SettingsPage.xaml(9) <TextBlock>
    HistoryText: TWinUITextBlock;  // SettingsPage.xaml(11) <TextBlock>
    ClearButton: TWinUIButton;     // SettingsPage.xaml(12) <Button>
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
  // SettingsPage.xaml(1): the page; event attributes became the
  // wiring below, x:Class, x:DataType and RADWinUI attributes are removed
  PageXaml =
    '<Page xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' + sLineBreak +
    '  <StackPanel Spacing="12" MaxWidth="560" HorizontalAlignment="Left">' + sLineBreak +
    '    <TextBlock x:Name="PageTitle" Text="Settings" Style="{StaticResource TitleLargeTextBlockStyle}" />' + sLineBreak +
    '    <TextBlock Text="History" Style="{StaticResource SubtitleTextBlockStyle}" Margin="0,12,0,0" />' + sLineBreak +
    '    <TextBlock x:Name="HistoryText" TextWrapping="Wrap" />' + sLineBreak +
    '    <Button x:Name="ClearButton" Content="Clear history" />' + sLineBreak +
    '    <TextBlock Text="About" Style="{StaticResource SubtitleTextBlockStyle}" Margin="0,12,0,0" />' + sLineBreak +
    '    <TextBlock TextWrapping="Wrap" Opacity="0.8" Text="Crew is a RADWinUI sample. Each page is a .xaml file with its .pas unit, the cards on the Home page are one user control used three times, and th' +
    'e frame keeps the back stack for the back button." />' + sLineBreak +
    '  </StackPanel>' + sLineBreak +
    '</Page>';
  {$IFDEF DEBUG}
  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild
  XamlShape = 'F:PageTitle:TWinUITextBlock;F:HistoryText:TWinUITextBlock;F:ClearButton:TWinUIButton;E:ClearButton.Click=ClearClick';
  {$ENDIF}

constructor TSettingsPageBase.Create;
begin
  inherited CreateFromXaml(PageXaml);
  WireXaml;
  {$IFDEF DEBUG}
  AddHelper(TXamlHotReload.Watch(Self, 'SettingsPage.xaml', XamlShape, ReloadXaml));
  {$ENDIF}
end;

// The x:Name fields and the event wiring of the content, again after a hot reload
procedure TSettingsPageBase.WireXaml;
begin
  // x:Name elements
  PageTitle := FindElement<TWinUITextBlock>('PageTitle');
  HistoryText := FindElement<TWinUITextBlock>('HistoryText');
  ClearButton := FindElement<TWinUIButton>('ClearButton');
  // Event wiring
  // SettingsPage.xaml(12): Click="ClearClick"
  ClearButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ClearClick'));
end;

{$IFDEF DEBUG}
// Hot reload: SettingsPage.xaml edited in the IDE while the app runs
procedure TSettingsPageBase.ReloadXaml(const AXaml: string);
begin
  ReplaceXaml(AXaml);
  WireXaml;
end;
{$ENDIF}

end.
