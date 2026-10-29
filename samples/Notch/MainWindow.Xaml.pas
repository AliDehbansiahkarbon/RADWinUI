unit MainWindow.Xaml;

{
  TMainWindowBase: base class of TMainWindow, generated from MainWindow.xaml
  by RADWinUI XamlCodeGen 0.4 (tools/XamlCodeGen).

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
  RADWinUI.Controls,
  RADWinUI.Forms;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TMainWindowBase = class(TWinUIWindow)
  protected
    Notch: TWinUINotchPanel;                 // MainWindow.xaml(17) <NotchPanel>
    PillDot: TWinUIEllipse;                  // MainWindow.xaml(27) <Ellipse>
    PillClock: TWinUITextBlock;              // MainWindow.xaml(28) <TextBlock>
    PillMusic: TWinUIFontIcon;               // MainWindow.xaml(30) <FontIcon>
    ClockLabel: TWinUITextBlock;             // MainWindow.xaml(51) <TextBlock>
    DateLabel: TWinUITextBlock;              // MainWindow.xaml(52) <TextBlock>
    TransparencySwitch: TWinUIToggleSwitch;  // MainWindow.xaml(58) <ToggleSwitch>
    PinButton: TWinUIButton;                 // MainWindow.xaml(60) <Button>
    PinGlyph: TWinUIFontIcon;                // MainWindow.xaml(62) <FontIcon>
    QuitButton: TWinUIButton;                // MainWindow.xaml(64) <Button>
    BuildTile: TWinUIGlowTile;               // MainWindow.xaml(78) <GlowTile>
    BuildStatus: TWinUITextBlock;            // MainWindow.xaml(93) <TextBlock>
    BuildDetail: TWinUITextBlock;            // MainWindow.xaml(94) <TextBlock>
    BuildProgress: TWinUIProgressBar;        // MainWindow.xaml(97) <ProgressBar>
    BuildButton: TWinUIButton;               // MainWindow.xaml(98) <Button>
    MusicTile: TWinUIGlowTile;               // MainWindow.xaml(104) <GlowTile>
    MusicSource: TWinUITextBlock;            // MainWindow.xaml(115) <TextBlock>
    MusicTitle: TWinUITextBlock;             // MainWindow.xaml(119) <TextBlock>
    MusicArtist: TWinUITextBlock;            // MainWindow.xaml(121) <TextBlock>
    PreviousButton: TWinUIButton;            // MainWindow.xaml(125) <Button>
    PlayButton: TWinUIButton;                // MainWindow.xaml(129) <Button>
    PlayGlyph: TWinUIFontIcon;               // MainWindow.xaml(131) <FontIcon>
    NextButton: TWinUIButton;                // MainWindow.xaml(134) <Button>
    FocusTile: TWinUIGlowTile;               // MainWindow.xaml(143) <GlowTile>
    FocusClock: TWinUITextBlock;             // MainWindow.xaml(156) <TextBlock>
    FocusButton: TWinUIButton;               // MainWindow.xaml(163) <Button>
    ResetButton: TWinUIButton;               // MainWindow.xaml(165) <Button>
    ToggleKey: TWinUIHotKey;                 // MainWindow.xaml(176) <HotKey>
    Media: TWinUIMediaSession;               // MainWindow.xaml(177) <MediaSession>
  public
    constructor Create; override;
  end;
  {$M-}

implementation

const
  // MainWindow.xaml(10): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:ns2="using:RADWinUI.Controls" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" RequestedTheme="Dark" Background="Tra' +
    'nsparent">' + sLineBreak +
    '    <Grid.Resources>' + sLineBreak +
    '      <SolidColorBrush x:Key="TileBrush" Color="#161618" />' + sLineBreak +
    '      <SolidColorBrush x:Key="MutedBrush" Color="#8E8E93" />' + sLineBreak +
    '      <SolidColorBrush x:Key="FaintBrush" Color="#2C2C2E" />' + sLineBreak +
    '    </Grid.Resources>' + sLineBreak +
    '' + sLineBreak +
    '    <ns2:NotchPanel x:Name="Notch" CollapsedWidth="220" CollapsedHeight="36" ExpandedWidth="680" ExpandedHeight="276" ExpandedCornerRadius="30" Padding="22,14,22,18" IsExpanded="False">' + sLineBreak +
    '      <ns2:NotchPanel.Pill>' + sLineBreak +
    '        <Grid Width="196" ColumnSpacing="10">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <Ellipse x:Name="PillDot" Width="8" Height="8" Fill="#3DDC84" VerticalAlignment="Center" />' + sLineBreak +
    '          <TextBlock x:Name="PillClock" Grid.Column="1" Text="00:00" FontSize="13" FontWeight="SemiBold" HorizontalAlignment="Center" VerticalAlignment="Center" />' + sLineBreak +
    '          <FontIcon x:Name="PillMusic" Grid.Column="2" FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="12" Foreground="#2EC4B6" Opacity="0" VerticalAlignment="Center" />' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </ns2:NotchPanel.Pill>' + sLineBreak +
    '' + sLineBreak +
    '      <Grid RowSpacing="14">' + sLineBreak +
    '        <Grid.RowDefinitions>' + sLineBreak +
    '          <RowDefinition Height="Auto" />' + sLineBreak +
    '          <RowDefinition Height="*" />' + sLineBreak +
    '        </Grid.RowDefinitions>' + sLineBreak +
    '' + sLineBreak +
    '        ' + sLineBreak +
    '        <Grid ColumnSpacing="8">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="10" VerticalAlignment="Center">' + sLineBreak +
    '            <TextBlock x:Name="ClockLabel" Text="00:00" FontSize="22" FontWeight="SemiBold" />' + sLineBreak +
    '            <TextBlock x:Name="DateLabel" Text="Thursday, 29 October" FontSize="13" Foreground="{StaticResource MutedBrush}" VerticalAlignment="Bottom" Margin="0,0,0,3" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '          <TextBlock Grid.Column="1" Text="Ctrl+Alt+N" FontSize="11" Foreground="{StaticResource MutedBrush}" VerticalAlignment="Center" Margin="0,0,6,0" />' + sLineBreak +
    '          ' + sLineBreak +
    '          <ToggleSwitch x:Name="TransparencySwitch" Grid.Column="2" OnContent="Transparency" OffContent="Transparency" MinWidth="0" FontSize="12" VerticalAlignment="Center" AutomationProperties.Name="' +
    'Transparency" />' + sLineBreak +
    '          <Button x:Name="PinButton" Grid.Column="3" Width="32" Height="32" Padding="0" CornerRadius="16" Background="{StaticResource FaintBrush}" BorderThickness="0" ToolTipService.ToolTip="Keep open' +
    '">' + sLineBreak +
    '            <FontIcon x:Name="PinGlyph" FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="13" />' + sLineBreak +
    '          </Button>' + sLineBreak +
    '          <Button x:Name="QuitButton" Grid.Column="4" Width="32" Height="32" Padding="0" CornerRadius="16" Background="{StaticResource FaintBrush}" BorderThickness="0" ToolTipService.ToolTip="Quit">' + sLineBreak +
    '            <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="12" />' + sLineBreak +
    '          </Button>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '' + sLineBreak +
    '        <Grid Grid.Row="1" ColumnSpacing="14">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '' + sLineBreak +
    '          ' + sLineBreak +
    '          <ns2:GlowTile x:Name="BuildTile" Background="{StaticResource TileBrush}" CornerRadius="20" Padding="16,14" GlowBrush="#3DDC84" GlowRadius="26" GlowOpacity="0.55">' + sLineBreak +
    '            <Grid RowSpacing="8">' + sLineBreak +
    '              <Grid.RowDefinitions>' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="*" />' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '              </Grid.RowDefinitions>' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="13" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '                <TextBlock Text="Build" FontSize="13" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <StackPanel Grid.Row="1" VerticalAlignment="Center" Spacing="2">' + sLineBreak +
    '                <TextBlock x:Name="BuildStatus" Text="Ready" FontSize="20" FontWeight="SemiBold" />' + sLineBreak +
    '                <TextBlock x:Name="BuildDetail" Text="Last build passed" FontSize="12" Foreground="{StaticResource MutedBrush}" TextTrimming="CharacterEllipsis" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <ProgressBar x:Name="BuildProgress" Grid.Row="2" Maximum="4" Value="0" Foreground="#FF8A3D" />' + sLineBreak +
    '              <Button x:Name="BuildButton" Grid.Row="3" Content="Run build" HorizontalAlignment="Stretch" CornerRadius="10" Background="{StaticResource FaintBrush}" BorderThickness="0" />' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '          </ns2:GlowTile>' + sLineBreak +
    '' + sLineBreak +
    '          ' + sLineBreak +
    '          <ns2:GlowTile x:Name="MusicTile" Grid.Column="1" Background="{StaticResource TileBrush}" CornerRadius="20" Padding="16,14" GlowBrush="#2EC4B6" GlowRadius="26" GlowOpacity="0.5" IsGlowing="Fa' +
    'lse">' + sLineBreak +
    '            <Grid RowSpacing="8">' + sLineBreak +
    '              <Grid.RowDefinitions>' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="*" />' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '              </Grid.RowDefinitions>' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="13" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '                <TextBlock x:Name="MusicSource" Text="Now playing" FontSize="13" Foreground="{StaticResource MutedBrush}" TextTrimming="CharacterEllipsis" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <StackPanel Grid.Row="1" VerticalAlignment="Center" Spacing="2">' + sLineBreak +
    '                <TextBlock x:Name="MusicTitle" Text="Nothing playing" FontSize="16" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" />' + sLineBreak +
    '                <TextBlock x:Name="MusicArtist" Text="Start music in any app" FontSize="12" Foreground="{StaticResource MutedBrush}" TextTrimming="CharacterEllipsis" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <StackPanel Grid.Row="2" Orientation="Horizontal" Spacing="10" HorizontalAlignment="Center">' + sLineBreak +
    '                <Button x:Name="PreviousButton" Width="36" Height="36" Padding="0" CornerRadius="18" Background="Transparent" BorderThickness="0">' + sLineBreak +
    '                  <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="14" />' + sLineBreak +
    '                </Button>' + sLineBreak +
    '                <Button x:Name="PlayButton" Width="44" Height="44" Padding="0" CornerRadius="22" Background="White" BorderThickness="0">' + sLineBreak +
    '                  <FontIcon x:Name="PlayGlyph" FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" Foreground="Black" />' + sLineBreak +
    '                </Button>' + sLineBreak +
    '                <Button x:Name="NextButton" Width="36" Height="36" Padding="0" CornerRadius="18" Background="Transparent" BorderThickness="0">' + sLineBreak +
    '                  <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="14" />' + sLineBreak +
    '                </Button>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '          </ns2:GlowTile>' + sLineBreak +
    '' + sLineBreak +
    '          ' + sLineBreak +
    '          <ns2:GlowTile x:Name="FocusTile" Grid.Column="2" Background="{StaticResource TileBrush}" CornerRadius="20" Padding="16,14" GlowBrush="#A77BFF" GlowRadius="26" GlowOpacity="0.6" IsGlowing="Fa' +
    'lse">' + sLineBreak +
    '            <Grid RowSpacing="8">' + sLineBreak +
    '              <Grid.RowDefinitions>' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="*" />' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '              </Grid.RowDefinitions>' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="13" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '                <TextBlock Text="Focus" FontSize="13" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <TextBlock x:Name="FocusClock" Grid.Row="1" Text="25:00" FontSize="40" FontWeight="SemiBold" HorizontalAlignment="Center" VerticalAlignment="Center" />' + sLineBreak +
    '              <Grid Grid.Row="2" ColumnSpacing="8">' + sLineBreak +
    '                <Grid.ColumnDefinitions>' + sLineBreak +
    '                  <ColumnDefinition Width="*" />' + sLineBreak +
    '                  <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                </Grid.ColumnDefinitions>' + sLineBreak +
    '                <Button x:Name="FocusButton" Content="Start" HorizontalAlignment="Stretch" CornerRadius="10" Background="{StaticResource FaintBrush}" BorderThickness="0" />' + sLineBreak +
    '                <Button x:Name="ResetButton" Grid.Column="1" Width="36" Padding="0" CornerRadius="10" Background="{StaticResource FaintBrush}" BorderThickness="0" ToolTipService.ToolTip="Reset">' + sLineBreak +
    '                  <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="13" />' + sLineBreak +
    '                </Button>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '          </ns2:GlowTile>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </Grid>' + sLineBreak +
    '    </ns2:NotchPanel>' + sLineBreak +
    '' + sLineBreak +
    '    <ns2:HotKey x:Name="ToggleKey" Keys="Ctrl+Alt+N" />' + sLineBreak +
    '    <ns2:MediaSession x:Name="Media" />' + sLineBreak +
    '  </Grid>' + sLineBreak;

constructor TMainWindowBase.Create;
begin
  inherited;
  // MainWindow.xaml(1): <Window> attributes
  Title := 'Notch';
  WindowStyle := TWinUIWindowStyle.Overlay;
  Width := 720;
  Height := 300;
  Backdrop := TWinUIBackdrop.Transparent;
  Dock := TWinUIDock.TopCenter;
  ClickThrough := TWinUIClickThrough.Background;
  ShowActivated := False;
  LoadContent(ContentXaml);
  // x:Name elements
  Notch := FindElement<TWinUINotchPanel>('Notch');
  PillDot := FindElement<TWinUIEllipse>('PillDot');
  PillClock := FindElement<TWinUITextBlock>('PillClock');
  PillMusic := FindElement<TWinUIFontIcon>('PillMusic');
  ClockLabel := FindElement<TWinUITextBlock>('ClockLabel');
  DateLabel := FindElement<TWinUITextBlock>('DateLabel');
  TransparencySwitch := FindElement<TWinUIToggleSwitch>('TransparencySwitch');
  PinButton := FindElement<TWinUIButton>('PinButton');
  PinGlyph := FindElement<TWinUIFontIcon>('PinGlyph');
  QuitButton := FindElement<TWinUIButton>('QuitButton');
  BuildTile := FindElement<TWinUIGlowTile>('BuildTile');
  BuildStatus := FindElement<TWinUITextBlock>('BuildStatus');
  BuildDetail := FindElement<TWinUITextBlock>('BuildDetail');
  BuildProgress := FindElement<TWinUIProgressBar>('BuildProgress');
  BuildButton := FindElement<TWinUIButton>('BuildButton');
  MusicTile := FindElement<TWinUIGlowTile>('MusicTile');
  MusicSource := FindElement<TWinUITextBlock>('MusicSource');
  MusicTitle := FindElement<TWinUITextBlock>('MusicTitle');
  MusicArtist := FindElement<TWinUITextBlock>('MusicArtist');
  PreviousButton := FindElement<TWinUIButton>('PreviousButton');
  PlayButton := FindElement<TWinUIButton>('PlayButton');
  PlayGlyph := FindElement<TWinUIFontIcon>('PlayGlyph');
  NextButton := FindElement<TWinUIButton>('NextButton');
  FocusTile := FindElement<TWinUIGlowTile>('FocusTile');
  FocusClock := FindElement<TWinUITextBlock>('FocusClock');
  FocusButton := FindElement<TWinUIButton>('FocusButton');
  ResetButton := FindElement<TWinUIButton>('ResetButton');
  ToggleKey := FindElement<TWinUIHotKey>('ToggleKey');
  Media := FindElement<TWinUIMediaSession>('Media');
  // Event wiring
  // MainWindow.xaml(58): TransparencySwitchToggled by name
  TransparencySwitch.Toggled.Add(NotifyProc<TWinUIRoutedEventArgs>('TransparencySwitchToggled'));
  // MainWindow.xaml(60): PinButtonClick by name
  PinButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('PinButtonClick'));
  // MainWindow.xaml(64): QuitButtonClick by name
  QuitButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('QuitButtonClick'));
  // MainWindow.xaml(98): BuildButtonClick by name
  BuildButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('BuildButtonClick'));
  // MainWindow.xaml(125): PreviousButtonClick by name
  PreviousButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('PreviousButtonClick'));
  // MainWindow.xaml(129): PlayButtonClick by name
  PlayButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('PlayButtonClick'));
  // MainWindow.xaml(134): NextButtonClick by name
  NextButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('NextButtonClick'));
  // MainWindow.xaml(163): FocusButtonClick by name
  FocusButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('FocusButtonClick'));
  // MainWindow.xaml(165): ResetButtonClick by name
  ResetButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ResetButtonClick'));
  // MainWindow.xaml(176): ToggleKeyPressed by name
  ToggleKey.EventByName('Pressed').Add(NotifyProc<TWinValue>('ToggleKeyPressed'));
  // MainWindow.xaml(177): MediaChanged by name
  Media.EventByName('Changed').Add(NotifyProc<TWinValue>('MediaChanged'));
end;

end.
