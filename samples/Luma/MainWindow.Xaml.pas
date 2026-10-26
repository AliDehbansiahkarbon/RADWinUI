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
  RADWinUI.Forms,
  MainViewModel;  // TMainViewModel, the DataContextType

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TMainWindowBase = class(TWinUIWindow)
  strict private
    FViewModel: TMainViewModel;
    procedure SetViewModel(AValue: TMainViewModel);
  protected
    Surface: TWinUIGrid;                     // MainWindow.xaml(12) <Grid>
    DragRegion: TWinUIGrid;                  // MainWindow.xaml(18) <Grid>
    LumaGlyph: TWinUIFontIcon;               // MainWindow.xaml(20) <FontIcon>
    ClockLabel: TWinUITextBlock;             // MainWindow.xaml(30) <TextBlock>
    DateLabel: TWinUITextBlock;              // MainWindow.xaml(41) <TextBlock>
    FocusButton: TWinUIButton;               // MainWindow.xaml(82) <Button>
    PowerGlyph: TWinUIFontIcon;              // MainWindow.xaml(103) <FontIcon>
    MemoryGlyph: TWinUIFontIcon;             // MainWindow.xaml(116) <FontIcon>
    MonthCalendar: TWinUICalendarView;       // MainWindow.xaml(128) <CalendarView>
    ThemeChoice: TWinUIComboBox;             // MainWindow.xaml(141) <ComboBox>
    TransparencySwitch: TWinUIToggleSwitch;  // MainWindow.xaml(147) <ToggleSwitch>
    PinButton: TWinUIToggleButton;           // MainWindow.xaml(148) <ToggleButton>
    PinGlyph: TWinUIFontIcon;                // MainWindow.xaml(150) <FontIcon>
  public
    constructor Create; override;
    /// <summary>
    ///   The TMainViewModel the XAML binds to (MainWindow.xaml(1): DataContextType);
    ///   setting it sets DataContext. The window does not own it.
    /// </summary>
    property ViewModel: TMainViewModel read FViewModel write SetViewModel;
  end;
  {$M-}

implementation

const
  // MainWindow.xaml(12): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="Surface" Background="Transparent">' + sLineBreak +
    '    <Grid.RowDefinitions>' + sLineBreak +
    '      <RowDefinition Height="52" />' + sLineBreak +
    '      <RowDefinition Height="*" />' + sLineBreak +
    '      <RowDefinition Height="52" />' + sLineBreak +
    '    </Grid.RowDefinitions>' + sLineBreak +
    '    <Grid x:Name="DragRegion" Margin="24,0,140,0">' + sLineBreak +
    '      <StackPanel Orientation="Horizontal" Spacing="10" VerticalAlignment="Center">' + sLineBreak +
    '        <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" x:Name="LumaGlyph" Glyph="" FontSize="18" Foreground="{ThemeResource SystemControlForegroundAccentBrush}" />' + sLineBreak +
    '        <TextBlock Text="LUMA" FontSize="13" FontWeight="SemiBold" CharacterSpacing="180" />' + sLineBreak +
    '      </StackPanel>' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '    <ScrollViewer Grid.Row="1" HorizontalScrollBarVisibility="Disabled" VerticalScrollBarVisibility="Auto">' + sLineBreak +
    '      <StackPanel Padding="24,12,24,20" Spacing="20">' + sLineBreak +
    '        <StackPanel Spacing="3">' + sLineBreak +
    '          <TextBlock Text="A little clarity for your day." FontSize="13" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '          <Grid>' + sLineBreak +
    '            <TextBlock x:Name="ClockLabel" Text="{Binding ClockText}" FontFamily="Segoe UI Variable Display" FontSize="76" FontWeight="SemiLight" />' + sLineBreak +
    '            <Border HorizontalAlignment="Right" VerticalAlignment="Center" Padding="10,5" CornerRadius="12" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource' +
    ' CardStrokeColorDefaultBrush}" BorderThickness="1">' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="6">' + sLineBreak +
    '                <Ellipse Width="5" Height="5" Fill="{ThemeResource SystemControlForegroundAccentBrush}" />' + sLineBreak +
    '                <TextBlock Text="LOCAL" FontSize="10" FontWeight="SemiBold" CharacterSpacing="100" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <TextBlock x:Name="DateLabel" Text="{Binding DateText}" FontSize="15" />' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '        <Border Padding="18,14" CornerRadius="16" BorderThickness="1" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}">' + sLineBreak +
    '          <StackPanel Spacing="10">' + sLineBreak +
    '            <Grid>' + sLineBreak +
    '              <TextBlock Text="TODAY" FontSize="10" FontWeight="SemiBold" CharacterSpacing="160" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '              <TextBlock Text="{Binding DayCaption}" HorizontalAlignment="Right" FontSize="11" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '            <ProgressBar Value="{Binding DayProgress}" Maximum="100" Height="3" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Border>' + sLineBreak +
    '        <Border Padding="20" CornerRadius="20" BorderThickness="1" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}">' + sLineBreak +
    '          <Border.Background>' + sLineBreak +
    '            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">' + sLineBreak +
    '              <GradientStop Color="{ThemeResource SystemAccentColor}" Offset="0" />' + sLineBreak +
    '              <GradientStop Color="{ThemeResource SystemAccentColorDark2}" Offset="1" />' + sLineBreak +
    '            </LinearGradientBrush>' + sLineBreak +
    '          </Border.Background>' + sLineBreak +
    '          <StackPanel Spacing="12">' + sLineBreak +
    '            <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '              <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="14" Foreground="White" />' + sLineBreak +
    '              <TextBlock Text="MAKE SPACE TO FOCUS" Foreground="White" FontSize="10" FontWeight="SemiBold" CharacterSpacing="130" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '            <Grid>' + sLineBreak +
    '              <TextBlock Text="{Binding FocusText}" Foreground="White" FontFamily="Segoe UI Variable Display" FontWeight="Light" FontSize="48" />' + sLineBreak +
    '              <TextBlock Text="One thing at a time." Foreground="White" Opacity="0.85" FontSize="11" HorizontalAlignment="Right" VerticalAlignment="Center" />' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '            <ProgressBar Value="{Binding FocusProgress}" Maximum="100" Foreground="White" Background="#30FFFFFF" Height="3" />' + sLineBreak +
    '            <Grid ColumnSpacing="8">' + sLineBreak +
    '              <Grid.ColumnDefinitions>' + sLineBreak +
    '                <ColumnDefinition Width="*" />' + sLineBreak +
    '                <ColumnDefinition Width="Auto" />' + sLineBreak +
    '              </Grid.ColumnDefinitions>' + sLineBreak +
    '              <Button x:Name="FocusButton" Content="{Binding FocusAction}" HorizontalAlignment="Stretch" Foreground="White" Background="#24FFFFFF" BorderBrush="#50FFFFFF" CornerRadius="10" />' + sLineBreak +
    '              <Button Grid.Column="1" ToolTipService.ToolTip="Reset to 25 minutes" AutomationProperties.Name="Reset focus timer" Background="#18FFFFFF" BorderBrush="#40FFFFFF" CornerRadius="10" x:Name' +
    '="_rw1">' + sLineBreak +
    '                <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" Foreground="White" FontSize="14" />' + sLineBreak +
    '              </Button>' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Border>' + sLineBreak +
    '        <Grid ColumnSpacing="12">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <Border Padding="16" CornerRadius="16" BorderThickness="1" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}">' + sLineBreak +
    '            <StackPanel Spacing="10">' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="7">' + sLineBreak +
    '                <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" x:Name="PowerGlyph" Glyph="" FontSize="13" Foreground="{ThemeResource SystemControlForegroundAccentBrush}" />' + sLineBreak +
    '                <TextBlock Text="POWER" FontSize="10" CharacterSpacing="100" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <TextBlock Text="{Binding PowerText}" FontSize="23" FontWeight="SemiBold" />' + sLineBreak +
    '              <TextBlock Text="{Binding PowerCaption}" FontSize="11" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Column="1" Padding="16" CornerRadius="16" BorderThickness="1" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefault' +
    'Brush}">' + sLineBreak +
    '            <StackPanel Spacing="10">' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="7">' + sLineBreak +
    '                <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" x:Name="MemoryGlyph" Glyph="" FontSize="13" Foreground="{ThemeResource SystemControlForegroundAccentBrush}" />' + sLineBreak +
    '                <TextBlock Text="MEMORY" FontSize="10" CharacterSpacing="100" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <TextBlock Text="{Binding MemoryText}" FontSize="23" FontWeight="SemiBold" />' + sLineBreak +
    '              <TextBlock Text="Physical memory in use" FontSize="11" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '        <StackPanel Spacing="10">' + sLineBreak +
    '          <TextBlock Text="A LOOK AHEAD" FontSize="10" FontWeight="SemiBold" CharacterSpacing="150" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '          <CalendarView x:Name="MonthCalendar" HorizontalAlignment="Stretch" Height="360" SelectionMode="Single" IsTodayHighlighted="True" CornerRadius="16" />' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '        <TextBlock Text="Built in Delphi. Brought to life by WinUI 3." FontSize="11" HorizontalAlignment="Center" Foreground="{ThemeResource TextFillColorTertiaryBrush}" />' + sLineBreak +
    '      </StackPanel>' + sLineBreak +
    '    </ScrollViewer>' + sLineBreak +
    '    <Grid Grid.Row="2" Margin="24,0" ColumnSpacing="12">' + sLineBreak +
    '      <Grid.ColumnDefinitions>' + sLineBreak +
    '        <ColumnDefinition Width="*" />' + sLineBreak +
    '        <ColumnDefinition Width="Auto" />' + sLineBreak +
    '        <ColumnDefinition Width="Auto" />' + sLineBreak +
    '      </Grid.ColumnDefinitions>' + sLineBreak +
    '      <ComboBox x:Name="ThemeChoice" SelectedIndex="0" AutomationProperties.Name="Appearance" VerticalAlignment="Center" MinWidth="146">' + sLineBreak +
    '        <ComboBoxItem Content="Windows theme" />' + sLineBreak +
    '        <ComboBoxItem Content="Light" />' + sLineBreak +
    '        <ComboBoxItem Content="Dark" />' + sLineBreak +
    '      </ComboBox>' + sLineBreak +
    '      <ToggleSwitch x:Name="TransparencySwitch" OnContent="Transparency" OffContent="Transparency" MinWidth="0" VerticalAlignment="Center" AutomationProperties.Name="Transparency" Grid.Column="1" />' + sLineBreak +
    '      <ToggleButton x:Name="PinButton" Grid.Column="2" VerticalAlignment="Center" ToolTipService.ToolTip="Keep Luma above other windows" AutomationProperties.Name="Keep on top">' + sLineBreak +
    '        <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" x:Name="PinGlyph" Glyph="" FontSize="14" />' + sLineBreak +
    '      </ToggleButton>' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '  </Grid>' + sLineBreak;

constructor TMainWindowBase.Create;
begin
  inherited;
  // MainWindow.xaml(1): <Window> attributes
  Title := 'Luma - your day, at a glance';
  Width := 420;
  Height := 1040;
  MinWidth := 390;
  MinHeight := 620;
  Backdrop := TWinUIBackdrop.Acrylic;
  ExtendsContentIntoTitleBar := True;
  LoadContent(ContentXaml);
  // x:Name elements
  Surface := FindElement<TWinUIGrid>('Surface');
  DragRegion := FindElement<TWinUIGrid>('DragRegion');
  LumaGlyph := FindElement<TWinUIFontIcon>('LumaGlyph');
  ClockLabel := FindElement<TWinUITextBlock>('ClockLabel');
  DateLabel := FindElement<TWinUITextBlock>('DateLabel');
  FocusButton := FindElement<TWinUIButton>('FocusButton');
  PowerGlyph := FindElement<TWinUIFontIcon>('PowerGlyph');
  MemoryGlyph := FindElement<TWinUIFontIcon>('MemoryGlyph');
  MonthCalendar := FindElement<TWinUICalendarView>('MonthCalendar');
  ThemeChoice := FindElement<TWinUIComboBox>('ThemeChoice');
  TransparencySwitch := FindElement<TWinUIToggleSwitch>('TransparencySwitch');
  PinButton := FindElement<TWinUIToggleButton>('PinButton');
  PinGlyph := FindElement<TWinUIFontIcon>('PinGlyph');
  // Event wiring
  // MainWindow.xaml(82): Click="FocusClick"
  FocusButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('FocusClick'));
  // MainWindow.xaml(85): Click="ResetClick"
  FindElement<TWinUIButton>('_rw1').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ResetClick'));
  // MainWindow.xaml(141): SelectionChanged="ThemeChanged"
  ThemeChoice.OnSelectionChanged := TWinUISelectionChangedEventHandler(PublishedMethod('ThemeChanged'));
  // MainWindow.xaml(148): Click="PinClick"
  PinButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('PinClick'));
end;

procedure TMainWindowBase.SetViewModel(AValue: TMainViewModel);
begin
  FViewModel := AValue;
  DataContext := AValue;
end;

end.
