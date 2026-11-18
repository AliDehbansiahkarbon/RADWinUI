unit MiniRoastWindow.Xaml;

{
  TMiniRoastWindowBase: base class of TMiniRoastWindow, generated from MiniRoastWindow.xaml
  by RADWinUI XamlCodeGen 0.5 (tools/XamlCodeGen).

  DO NOT EDIT. Change MiniRoastWindow.xaml or the published handlers of TMiniRoastWindow
  in MiniRoastWindow.pas; the build regenerates this unit.

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
  TMiniRoastWindowBase = class(TWinUIWindow)
  protected
    TitleText: TWinUITextBlock;   // MiniRoastWindow.xaml(18) <TextBlock>
    TempText: TWinUITextBlock;    // MiniRoastWindow.xaml(25) <TextBlock>
    TimeText: TWinUITextBlock;    // MiniRoastWindow.xaml(27) <TextBlock>
    PhaseText: TWinUITextBlock;   // MiniRoastWindow.xaml(28) <TextBlock>
    Progress: TWinUIProgressBar;  // MiniRoastWindow.xaml(31) <ProgressBar>
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
  // MiniRoastWindow.xaml(10): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Padding="18,14,18,16" RowSpacing="6">' + sLineBreak +
    '    <Grid.RowDefinitions>' + sLineBreak +
    '      <RowDefinition Height="Auto" />' + sLineBreak +
    '      <RowDefinition Height="*" />' + sLineBreak +
    '      <RowDefinition Height="Auto" />' + sLineBreak +
    '    </Grid.RowDefinitions>' + sLineBreak +
    '    <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '      <FontIcon Glyph="" FontSize="14" Foreground="{ThemeResource AccentTextFillColorPrimaryBrush}" />' + sLineBreak +
    '      <TextBlock x:Name="TitleText" FontSize="12" Opacity="0.75" TextTrimming="CharacterEllipsis" />' + sLineBreak +
    '    </StackPanel>' + sLineBreak +
    '    <Grid Grid.Row="1" ColumnSpacing="12">' + sLineBreak +
    '      <Grid.ColumnDefinitions>' + sLineBreak +
    '        <ColumnDefinition Width="*" />' + sLineBreak +
    '        <ColumnDefinition Width="Auto" />' + sLineBreak +
    '      </Grid.ColumnDefinitions>' + sLineBreak +
    '      <TextBlock x:Name="TempText" FontSize="46" FontWeight="SemiBold" Foreground="{ThemeResource AccentTextFillColorPrimaryBrush}" VerticalAlignment="Center" />' + sLineBreak +
    '      <StackPanel Grid.Column="1" VerticalAlignment="Center" HorizontalAlignment="Right">' + sLineBreak +
    '        <TextBlock x:Name="TimeText" FontSize="22" FontWeight="SemiBold" HorizontalAlignment="Right" />' + sLineBreak +
    '        <TextBlock x:Name="PhaseText" FontSize="12" Opacity="0.75" HorizontalAlignment="Right" />' + sLineBreak +
    '      </StackPanel>' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '    <ProgressBar x:Name="Progress" Grid.Row="2" Maximum="660" Foreground="{ThemeResource AccentTextFillColorPrimaryBrush}" />' + sLineBreak +
    '  </Grid>' + sLineBreak;
  {$IFDEF DEBUG}
  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild
  XamlShape = 'F:TitleText:TWinUITextBlock;F:TempText:TWinUITextBlock;F:TimeText:TWinUITextBlock;F:PhaseText:TWinUITextBlock;F:Progress:TWinUIProgressBar;';
  {$ENDIF}

constructor TMiniRoastWindowBase.Create;
begin
  inherited;
  // MiniRoastWindow.xaml(1): <Window> attributes
  Title := 'Ember roaster';
  Width := 320;
  Height := 200;
  Backdrop := TWinUIBackdrop.Acrylic;
  WindowState := TWinUIWindowState.CompactOverlay;
  LoadContent(ContentXaml);
  WireXaml;
  {$IFDEF DEBUG}
  AddHelper(TXamlHotReload.Watch(Self, 'MiniRoastWindow.xaml', XamlShape, ReloadXaml));
  {$ENDIF}
end;

// The x:Name fields and the event wiring of the content, again after a hot reload
procedure TMiniRoastWindowBase.WireXaml;
begin
  // x:Name elements
  TitleText := FindElement<TWinUITextBlock>('TitleText');
  TempText := FindElement<TWinUITextBlock>('TempText');
  TimeText := FindElement<TWinUITextBlock>('TimeText');
  PhaseText := FindElement<TWinUITextBlock>('PhaseText');
  Progress := FindElement<TWinUIProgressBar>('Progress');
end;

{$IFDEF DEBUG}
// Hot reload: MiniRoastWindow.xaml edited in the IDE while the app runs
procedure TMiniRoastWindowBase.ReloadXaml(const AXaml: string);
begin
  LoadContent(AXaml);
  WireXaml;
end;
{$ENDIF}

end.
