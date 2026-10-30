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
    Notch: TWinUINotchPanel;                 // MainWindow.xaml(20) <NotchPanel>
    PillHost: TWinUIGrid;                    // MainWindow.xaml(25) <Grid>
    PillGrid: TWinUIGrid;                    // MainWindow.xaml(26) <Grid>
    PillDot: TWinUIEllipse;                  // MainWindow.xaml(32) <Ellipse>
    PillClock: TWinUITextBlock;              // MainWindow.xaml(33) <TextBlock>
    PillMusic: TWinUIFontIcon;               // MainWindow.xaml(35) <FontIcon>
    PillSide: TWinUIStackPanel;              // MainWindow.xaml(39) <StackPanel>
    PillSideDot: TWinUIEllipse;              // MainWindow.xaml(41) <Ellipse>
    PillHours: TWinUITextBlock;              // MainWindow.xaml(42) <TextBlock>
    PillMinutes: TWinUITextBlock;            // MainWindow.xaml(43) <TextBlock>
    HeaderBar: TWinUIGrid;                   // MainWindow.xaml(57) <Grid>
    ClockLabel: TWinUITextBlock;             // MainWindow.xaml(67) <TextBlock>
    DateLabel: TWinUITextBlock;              // MainWindow.xaml(68) <TextBlock>
    HeaderTools: TWinUIStackPanel;           // MainWindow.xaml(71) <StackPanel>
    HotKeyHint: TWinUITextBlock;             // MainWindow.xaml(72) <TextBlock>
    TransparencySwitch: TWinUIToggleSwitch;  // MainWindow.xaml(75) <ToggleSwitch>
    TransparencySlider: TWinUISlider;        // MainWindow.xaml(77) <Slider>
    EditButton: TWinUIButton;                // MainWindow.xaml(80) <Button>
    EditGlyph: TWinUIFontIcon;               // MainWindow.xaml(82) <FontIcon>
    PinButton: TWinUIButton;                 // MainWindow.xaml(84) <Button>
    PinGlyph: TWinUIFontIcon;                // MainWindow.xaml(86) <FontIcon>
    QuitButton: TWinUIButton;                // MainWindow.xaml(88) <Button>
    WidgetScroller: TWinUIScrollViewer;      // MainWindow.xaml(98) <ScrollViewer>
    WidgetRow: TWinUIStackPanel;             // MainWindow.xaml(101) <StackPanel>
    EditPage: TWinUIGrid;                    // MainWindow.xaml(107) <Grid>
    WidgetListHost: TWinUIBorder;            // MainWindow.xaml(125) <Border>
    AddListHost: TWinUIBorder;               // MainWindow.xaml(128) <Border>
    DetailPanel: TWinUIGrid;                 // MainWindow.xaml(130) <Grid>
    TitleBox: TWinUITextBox;                 // MainWindow.xaml(143) <TextBox>
    DetailHint: TWinUITextBlock;             // MainWindow.xaml(144) <TextBlock>
    ItemListHost: TWinUIBorder;              // MainWindow.xaml(148) <Border>
    EntryForm: TWinUIGrid;                   // MainWindow.xaml(150) <Grid>
    EntryNameBox: TWinUITextBox;             // MainWindow.xaml(156) <TextBox>
    EntryTargetBox: TWinUITextBox;           // MainWindow.xaml(157) <TextBox>
    AddEntryButton: TWinUIButton;            // MainWindow.xaml(159) <Button>
    SearchBox: TWinUITextBox;                // MainWindow.xaml(161) <TextBox>
    AppResults: TWinUIScrollViewer;          // MainWindow.xaml(163) <ScrollViewer>
    AppResultsHost: TWinUIBorder;            // MainWindow.xaml(164) <Border>
    SettingsPage: TWinUIScrollViewer;        // MainWindow.xaml(168) <ScrollViewer>
    SettingsHost: TWinUIBorder;              // MainWindow.xaml(169) <Border>
    ToggleKey: TWinUIHotKey;                 // MainWindow.xaml(176) <HotKey>
    Media: TWinUIMediaSession;               // MainWindow.xaml(177) <MediaSession>
  public
    constructor Create; override;
  end;
  {$M-}

implementation

const
  // MainWindow.xaml(13): the content element; event attributes became the
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
    '        ' + sLineBreak +
    '        <Grid x:Name="PillHost" Background="Transparent">' + sLineBreak +
    '          <Grid x:Name="PillGrid" Width="196" ColumnSpacing="10">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <Ellipse x:Name="PillDot" Width="8" Height="8" Fill="#3DDC84" VerticalAlignment="Center" />' + sLineBreak +
    '            <TextBlock x:Name="PillClock" Grid.Column="1" Text="00:00" FontSize="13" FontWeight="SemiBold" HorizontalAlignment="Center" VerticalAlignment="Center" />' + sLineBreak +
    '            <FontIcon x:Name="PillMusic" Grid.Column="2" FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="12" Foreground="#2EC4B6" Opacity="0" VerticalAlignment="Center" />' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          ' + sLineBreak +
    '          <StackPanel x:Name="PillSide" Visibility="Collapsed" Spacing="4" HorizontalAlignment="Center" VerticalAlignment="Center">' + sLineBreak +
    '            <Ellipse x:Name="PillSideDot" Width="8" Height="8" Fill="#3DDC84" HorizontalAlignment="Center" />' + sLineBreak +
    '            <TextBlock x:Name="PillHours" Text="00" FontSize="13" FontWeight="SemiBold" HorizontalAlignment="Center" />' + sLineBreak +
    '            <TextBlock x:Name="PillMinutes" Text="00" FontSize="13" FontWeight="SemiBold" HorizontalAlignment="Center" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </ns2:NotchPanel.Pill>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <Grid RowSpacing="14" XYFocusKeyboardNavigation="Enabled">' + sLineBreak +
    '        <Grid.RowDefinitions>' + sLineBreak +
    '          <RowDefinition Height="Auto" />' + sLineBreak +
    '          <RowDefinition Height="*" />' + sLineBreak +
    '        </Grid.RowDefinitions>' + sLineBreak +
    '' + sLineBreak +
    '        ' + sLineBreak +
    '        <Grid x:Name="HeaderBar" ColumnSpacing="8" RowSpacing="10" Background="Transparent">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <Grid.RowDefinitions>' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '          </Grid.RowDefinitions>' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="10" VerticalAlignment="Center">' + sLineBreak +
    '            <TextBlock x:Name="ClockLabel" Text="00:00" FontSize="22" FontWeight="SemiBold" />' + sLineBreak +
    '            <TextBlock x:Name="DateLabel" Text="Thursday, 29 October" FontSize="13" Foreground="{StaticResource MutedBrush}" VerticalAlignment="Bottom" Margin="0,0,0,3" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '          <StackPanel x:Name="HeaderTools" Grid.Column="1" Orientation="Horizontal" Spacing="8" VerticalAlignment="Center">' + sLineBreak +
    '            <TextBlock x:Name="HotKeyHint" Text="Ctrl+Alt+N" FontSize="11" Foreground="{StaticResource MutedBrush}" VerticalAlignment="Center" Margin="0,0,6,0" />' + sLineBreak +
    '            ' + sLineBreak +
    '            <ToggleSwitch x:Name="TransparencySwitch" OnContent="Transparency" OffContent="Transparency" MinWidth="0" FontSize="12" VerticalAlignment="Center" AutomationProperties.Name="Transparency" ' +
    '/>' + sLineBreak +
    '            <Slider x:Name="TransparencySlider" Width="96" Minimum="10" Maximum="90" StepFrequency="1" VerticalAlignment="Center" Visibility="Collapsed" ToolTipService.ToolTip="How see-through" Automa' +
    'tionProperties.Name="Transparency level" />' + sLineBreak +
    '            <Button x:Name="EditButton" Width="32" Height="32" Padding="0" CornerRadius="16" Background="{StaticResource FaintBrush}" BorderThickness="0" ToolTipService.ToolTip="Edit widgets">' + sLineBreak +
    '              <FontIcon x:Name="EditGlyph" FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="13" />' + sLineBreak +
    '            </Button>' + sLineBreak +
    '            <Button x:Name="PinButton" Width="32" Height="32" Padding="0" CornerRadius="16" Background="{StaticResource FaintBrush}" BorderThickness="0" ToolTipService.ToolTip="Keep open">' + sLineBreak +
    '              <FontIcon x:Name="PinGlyph" FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="13" />' + sLineBreak +
    '            </Button>' + sLineBreak +
    '            <Button x:Name="QuitButton" Width="32" Height="32" Padding="0" CornerRadius="16" Background="{StaticResource FaintBrush}" BorderThickness="0" ToolTipService.ToolTip="Quit">' + sLineBreak +
    '              <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="12" />' + sLineBreak +
    '            </Button>' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '' + sLineBreak +
    '        <Grid Grid.Row="1">' + sLineBreak +
    '          ' + sLineBreak +
    '          <ScrollViewer x:Name="WidgetScroller" Margin="-22,-8,-22,-18" HorizontalScrollMode="Auto" HorizontalScrollBarVisibility="Auto" VerticalScrollMode="Disabled" VerticalScrollBarVisibility="Disa' +
    'bled">' + sLineBreak +
    '            <StackPanel x:Name="WidgetRow" Orientation="Horizontal" Spacing="14" Margin="22,8,22,18" XYFocusKeyboardNavigation="Enabled" />' + sLineBreak +
    '          </ScrollViewer>' + sLineBreak +
    '' + sLineBreak +
    '          ' + sLineBreak +
    '          ' + sLineBreak +
    '          <Grid x:Name="EditPage" Visibility="Collapsed" ColumnSpacing="20">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="270" />' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <Grid.RowDefinitions>' + sLineBreak +
    '              <RowDefinition Height="*" />' + sLineBreak +
    '              <RowDefinition Height="0" />' + sLineBreak +
    '            </Grid.RowDefinitions>' + sLineBreak +
    '            <Grid RowSpacing="8">' + sLineBreak +
    '              <Grid.RowDefinitions>' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="*" />' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '              </Grid.RowDefinitions>' + sLineBreak +
    '              <TextBlock Text="Widgets" FontSize="13" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '              <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">' + sLineBreak +
    '                <Border x:Name="WidgetListHost" />' + sLineBreak +
    '              </ScrollViewer>' + sLineBreak +
    '              <TextBlock Grid.Row="2" Text="Add a widget" FontSize="13" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '              <Border x:Name="AddListHost" Grid.Row="3" />' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '            <Grid x:Name="DetailPanel" Grid.Column="1" RowSpacing="10">' + sLineBreak +
    '              <Grid.RowDefinitions>' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="*" />' + sLineBreak +
    '              </Grid.RowDefinitions>' + sLineBreak +
    '              <Grid ColumnSpacing="12">' + sLineBreak +
    '                <Grid.ColumnDefinitions>' + sLineBreak +
    '                  <ColumnDefinition Width="220" />' + sLineBreak +
    '                  <ColumnDefinition Width="*" />' + sLineBreak +
    '                </Grid.ColumnDefinitions>' + sLineBreak +
    '                <TextBox x:Name="TitleBox" PlaceholderText="Name of the widget" AutomationProperties.Name="Name of the widget" />' + sLineBreak +
    '                <TextBlock x:Name="DetailHint" Grid.Column="1" FontSize="12" Foreground="{StaticResource MutedBrush}" TextWrapping="Wrap" VerticalAlignment="Center" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <ScrollViewer Grid.Row="1" MaxHeight="92" VerticalScrollBarVisibility="Auto">' + sLineBreak +
    '                <Border x:Name="ItemListHost" />' + sLineBreak +
    '              </ScrollViewer>' + sLineBreak +
    '              <Grid x:Name="EntryForm" Grid.Row="2" ColumnSpacing="8">' + sLineBreak +
    '                <Grid.ColumnDefinitions>' + sLineBreak +
    '                  <ColumnDefinition Width="*" />' + sLineBreak +
    '                  <ColumnDefinition Width="2*" />' + sLineBreak +
    '                  <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                </Grid.ColumnDefinitions>' + sLineBreak +
    '                <TextBox x:Name="EntryNameBox" PlaceholderText="Name" AutomationProperties.Name="Name" />' + sLineBreak +
    '                <TextBox x:Name="EntryTargetBox" Grid.Column="1" PlaceholderText="Address" AutomationProperties.Name="Address" />' + sLineBreak +
    '                <Button x:Name="AddEntryButton" Grid.Column="2" Content="Add" CornerRadius="8" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBox x:Name="SearchBox" Grid.Row="3" PlaceholderText="Search installed apps" AutomationProperties.Name="Search installed apps" />' + sLineBreak +
    '              <ScrollViewer x:Name="AppResults" Grid.Row="4" VerticalScrollBarVisibility="Auto">' + sLineBreak +
    '                <Border x:Name="AppResultsHost" />' + sLineBreak +
    '              </ScrollViewer>' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '            ' + sLineBreak +
    '            <ScrollViewer x:Name="SettingsPage" Grid.Column="1" Visibility="Collapsed" VerticalScrollBarVisibility="Auto">' + sLineBreak +
    '              <Border x:Name="SettingsHost" />' + sLineBreak +
    '            </ScrollViewer>' + sLineBreak +
    '          </Grid>' + sLineBreak +
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
  ClickThrough := TWinUIClickThrough.Background;
  ShowActivated := False;
  LoadContent(ContentXaml);
  // x:Name elements
  Notch := FindElement<TWinUINotchPanel>('Notch');
  PillHost := FindElement<TWinUIGrid>('PillHost');
  PillGrid := FindElement<TWinUIGrid>('PillGrid');
  PillDot := FindElement<TWinUIEllipse>('PillDot');
  PillClock := FindElement<TWinUITextBlock>('PillClock');
  PillMusic := FindElement<TWinUIFontIcon>('PillMusic');
  PillSide := FindElement<TWinUIStackPanel>('PillSide');
  PillSideDot := FindElement<TWinUIEllipse>('PillSideDot');
  PillHours := FindElement<TWinUITextBlock>('PillHours');
  PillMinutes := FindElement<TWinUITextBlock>('PillMinutes');
  HeaderBar := FindElement<TWinUIGrid>('HeaderBar');
  ClockLabel := FindElement<TWinUITextBlock>('ClockLabel');
  DateLabel := FindElement<TWinUITextBlock>('DateLabel');
  HeaderTools := FindElement<TWinUIStackPanel>('HeaderTools');
  HotKeyHint := FindElement<TWinUITextBlock>('HotKeyHint');
  TransparencySwitch := FindElement<TWinUIToggleSwitch>('TransparencySwitch');
  TransparencySlider := FindElement<TWinUISlider>('TransparencySlider');
  EditButton := FindElement<TWinUIButton>('EditButton');
  EditGlyph := FindElement<TWinUIFontIcon>('EditGlyph');
  PinButton := FindElement<TWinUIButton>('PinButton');
  PinGlyph := FindElement<TWinUIFontIcon>('PinGlyph');
  QuitButton := FindElement<TWinUIButton>('QuitButton');
  WidgetScroller := FindElement<TWinUIScrollViewer>('WidgetScroller');
  WidgetRow := FindElement<TWinUIStackPanel>('WidgetRow');
  EditPage := FindElement<TWinUIGrid>('EditPage');
  WidgetListHost := FindElement<TWinUIBorder>('WidgetListHost');
  AddListHost := FindElement<TWinUIBorder>('AddListHost');
  DetailPanel := FindElement<TWinUIGrid>('DetailPanel');
  TitleBox := FindElement<TWinUITextBox>('TitleBox');
  DetailHint := FindElement<TWinUITextBlock>('DetailHint');
  ItemListHost := FindElement<TWinUIBorder>('ItemListHost');
  EntryForm := FindElement<TWinUIGrid>('EntryForm');
  EntryNameBox := FindElement<TWinUITextBox>('EntryNameBox');
  EntryTargetBox := FindElement<TWinUITextBox>('EntryTargetBox');
  AddEntryButton := FindElement<TWinUIButton>('AddEntryButton');
  SearchBox := FindElement<TWinUITextBox>('SearchBox');
  AppResults := FindElement<TWinUIScrollViewer>('AppResults');
  AppResultsHost := FindElement<TWinUIBorder>('AppResultsHost');
  SettingsPage := FindElement<TWinUIScrollViewer>('SettingsPage');
  SettingsHost := FindElement<TWinUIBorder>('SettingsHost');
  ToggleKey := FindElement<TWinUIHotKey>('ToggleKey');
  Media := FindElement<TWinUIMediaSession>('Media');
  // Event wiring
  // MainWindow.xaml(25): PillHostPointerPressed by name
  PillHost.PointerPressed.Add(NotifyProc<TWinUIPointerRoutedEventArgs>('PillHostPointerPressed'));
  // MainWindow.xaml(57): HeaderBarPointerPressed by name
  HeaderBar.PointerPressed.Add(NotifyProc<TWinUIPointerRoutedEventArgs>('HeaderBarPointerPressed'));
  // MainWindow.xaml(75): TransparencySwitchToggled by name
  TransparencySwitch.Toggled.Add(NotifyProc<TWinUIRoutedEventArgs>('TransparencySwitchToggled'));
  // MainWindow.xaml(77): TransparencySliderValueChanged by name
  TransparencySlider.ValueChanged.Add(NotifyProc<TWinUIRangeBaseValueChangedEventArgs>('TransparencySliderValueChanged'));
  // MainWindow.xaml(80): EditButtonClick by name
  EditButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('EditButtonClick'));
  // MainWindow.xaml(84): PinButtonClick by name
  PinButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('PinButtonClick'));
  // MainWindow.xaml(88): QuitButtonClick by name
  QuitButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('QuitButtonClick'));
  // MainWindow.xaml(143): TitleBoxTextChanged by name
  TitleBox.TextChanged.Add(NotifyProc<TWinUITextChangedEventArgs>('TitleBoxTextChanged'));
  // MainWindow.xaml(159): AddEntryButtonClick by name
  AddEntryButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('AddEntryButtonClick'));
  // MainWindow.xaml(161): SearchBoxTextChanged by name
  SearchBox.TextChanged.Add(NotifyProc<TWinUITextChangedEventArgs>('SearchBoxTextChanged'));
  // MainWindow.xaml(176): ToggleKeyPressed by name
  ToggleKey.EventByName('Pressed').Add(NotifyProc<TWinValue>('ToggleKeyPressed'));
  // MainWindow.xaml(177): MediaChanged by name
  Media.EventByName('Changed').Add(NotifyProc<TWinValue>('MediaChanged'));
end;

end.
