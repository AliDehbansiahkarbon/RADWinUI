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
    Surface: TWinUIGrid;                                 // MainWindow.xaml(10) <Grid>
    SolidLayer: TWinUIBorder;                            // MainWindow.xaml(16) <Border>
    DragRegion: TWinUIGrid;                              // MainWindow.xaml(20) <Grid>
    ThemeChoice: TWinUIComboBox;                         // MainWindow.xaml(30) <ComboBox>
    Navigation: TWinUINavigationView;                    // MainWindow.xaml(35) <NavigationView>
    SearchBox: TWinUIAutoSuggestBox;                     // MainWindow.xaml(39) <AutoSuggestBox>
    NavHome: TWinUINavigationViewItem;                   // MainWindow.xaml(44) <NavigationViewItem>
    NavExplorer: TWinUINavigationViewItem;               // MainWindow.xaml(45) <NavigationViewItem>
    NavInputs: TWinUINavigationViewItem;                 // MainWindow.xaml(48) <NavigationViewItem>
    NavCollections: TWinUINavigationViewItem;            // MainWindow.xaml(49) <NavigationViewItem>
    NavDates: TWinUINavigationViewItem;                  // MainWindow.xaml(50) <NavigationViewItem>
    NavFeedback: TWinUINavigationViewItem;               // MainWindow.xaml(51) <NavigationViewItem>
    NavLayout: TWinUINavigationViewItem;                 // MainWindow.xaml(52) <NavigationViewItem>
    NavMaterials: TWinUINavigationViewItem;              // MainWindow.xaml(53) <NavigationViewItem>
    NavBinding: TWinUINavigationViewItem;                // MainWindow.xaml(56) <NavigationViewItem>
    PageScroll: TWinUIScrollViewer;                      // MainWindow.xaml(58) <ScrollViewer>
    PageTitle: TWinUITextBlock;                          // MainWindow.xaml(61) <TextBlock>
    PageDescription: TWinUITextBlock;                    // MainWindow.xaml(62) <TextBlock>
    HomePage: TWinUIStackPanel;                          // MainWindow.xaml(66) <StackPanel>
    InputsPage: TWinUIStackPanel;                        // MainWindow.xaml(129) <StackPanel>
    NameEntry: TWinUITextBox;                            // MainWindow.xaml(133) <TextBox>
    GreetingText: TWinUITextBlock;                       // MainWindow.xaml(135) <TextBlock>
    DemoSwitch: TWinUIToggleSwitch;                      // MainWindow.xaml(136) <ToggleSwitch>
    VolumeText: TWinUITextBlock;                         // MainWindow.xaml(147) <TextBlock>
    IntensitySlider: TWinUISlider;                       // MainWindow.xaml(148) <Slider>
    IntensityProgress: TWinUIProgressBar;                // MainWindow.xaml(149) <ProgressBar>
    CollectionsPage: TWinUIStackPanel;                   // MainWindow.xaml(155) <StackPanel>
    NewItemText: TWinUITextBox;                          // MainWindow.xaml(160) <TextBox>
    DemoList: TWinUIListView;                            // MainWindow.xaml(164) <ListView>
    SelectionText: TWinUITextBlock;                      // MainWindow.xaml(165) <TextBlock>
    DatesPage: TWinUIStackPanel;                         // MainWindow.xaml(180) <StackPanel>
    FeedbackPage: TWinUIStackPanel;                      // MainWindow.xaml(194) <StackPanel>
    FeedbackBar: TWinUIInfoBar;                          // MainWindow.xaml(195) <InfoBar>
    ActivitySwitch: TWinUIToggleSwitch;                  // MainWindow.xaml(199) <ToggleSwitch>
    ActivityRing: TWinUIProgressRing;                    // MainWindow.xaml(200) <ProgressRing>
    ActivityProgress: TWinUIProgressBar;                 // MainWindow.xaml(201) <ProgressBar>
    LayoutPage: TWinUIStackPanel;                        // MainWindow.xaml(207) <StackPanel>
    MaterialsPage: TWinUIStackPanel;                     // MainWindow.xaml(224) <StackPanel>
    BackdropChoice: TWinUIComboBox;                      // MainWindow.xaml(227) <ComboBox>
    DemoColorPicker: TWinUIColorPicker;                  // MainWindow.xaml(234) <ColorPicker>
    ColorSwatch: TWinUIBorder;                           // MainWindow.xaml(235) <Border>
    ColorValue: TWinUITextBlock;                         // MainWindow.xaml(236) <TextBlock>
    BindingPage: TWinUIStackPanel;                       // MainWindow.xaml(244) <StackPanel>
    ExplorerPage: TWinUIGrid;                            // MainWindow.xaml(258) <Grid>
    ExplorerFilter: TWinUITextBox;                       // MainWindow.xaml(261) <TextBox>
    ExplorerCount: TWinUITextBlock;                      // MainWindow.xaml(262) <TextBlock>
    ExplorerList: TWinUIListView;                        // MainWindow.xaml(263) <ListView>
    ControlTitle: TWinUITextBlock;                       // MainWindow.xaml(267) <TextBlock>
    ControlCategory: TWinUITextBlock;                    // MainWindow.xaml(268) <TextBlock>
    ControlDescription: TWinUITextBlock;                 // MainWindow.xaml(269) <TextBlock>
    ExplorerSamples: TWinUIStackPanel;                   // MainWindow.xaml(274) <StackPanel>
    SampleButton: TWinUIButton;                          // MainWindow.xaml(275) <Button>
    SampleToggleButton: TWinUIToggleButton;              // MainWindow.xaml(276) <ToggleButton>
    SampleRepeatButton: TWinUIRepeatButton;              // MainWindow.xaml(277) <RepeatButton>
    SampleSplitButton: TWinUISplitButton;                // MainWindow.xaml(278) <SplitButton>
    SampleHyperlinkButton: TWinUIHyperlinkButton;        // MainWindow.xaml(279) <HyperlinkButton>
    SampleTextBox: TWinUITextBox;                        // MainWindow.xaml(280) <TextBox>
    SamplePasswordBox: TWinUIPasswordBox;                // MainWindow.xaml(281) <PasswordBox>
    SampleRichEditBox: TWinUIRichEditBox;                // MainWindow.xaml(282) <RichEditBox>
    SampleNumberBox: TWinUINumberBox;                    // MainWindow.xaml(283) <NumberBox>
    SampleSlider: TWinUISlider;                          // MainWindow.xaml(284) <Slider>
    SampleToggleSwitch: TWinUIToggleSwitch;              // MainWindow.xaml(285) <ToggleSwitch>
    SampleCheckBox: TWinUICheckBox;                      // MainWindow.xaml(286) <CheckBox>
    SampleRadioButtons: TWinUIRadioButtons;              // MainWindow.xaml(287) <RadioButtons>
    SampleComboBox: TWinUIComboBox;                      // MainWindow.xaml(288) <ComboBox>
    SampleListBox: TWinUIListBox;                        // MainWindow.xaml(289) <ListBox>
    SampleGridView: TWinUIGridView;                      // MainWindow.xaml(290) <GridView>
    SampleExpander: TWinUIExpander;                      // MainWindow.xaml(291) <Expander>
    SampleTabView: TWinUITabView;                        // MainWindow.xaml(292) <TabView>
    SampleCalendarDatePicker: TWinUICalendarDatePicker;  // MainWindow.xaml(293) <CalendarDatePicker>
    SampleDatePicker: TWinUIDatePicker;                  // MainWindow.xaml(294) <DatePicker>
    SampleTimePicker: TWinUITimePicker;                  // MainWindow.xaml(295) <TimePicker>
    SampleProgressBar: TWinUIProgressBar;                // MainWindow.xaml(296) <ProgressBar>
    SampleProgressRing: TWinUIProgressRing;              // MainWindow.xaml(297) <ProgressRing>
    SampleRatingControl: TWinUIRatingControl;            // MainWindow.xaml(298) <RatingControl>
    SampleColorPicker: TWinUIColorPicker;                // MainWindow.xaml(299) <ColorPicker>
    SampleInfoBar: TWinUIInfoBar;                        // MainWindow.xaml(300) <InfoBar>
    SampleMenuBar: TWinUIMenuBar;                        // MainWindow.xaml(301) <MenuBar>
    SampleCommandBar: TWinUICommandBar;                  // MainWindow.xaml(302) <CommandBar>
    SamplePersonPicture: TWinUIPersonPicture;            // MainWindow.xaml(303) <PersonPicture>
    SampleTextBlock: TWinUITextBlock;                    // MainWindow.xaml(304) <TextBlock>
    ExplorerEnabled: TWinUIToggleSwitch;                 // MainWindow.xaml(310) <ToggleSwitch>
    ExplorerFlow: TWinUIComboBox;                        // MainWindow.xaml(311) <ComboBox>
    ExplorerValue: TWinUITextBlock;                      // MainWindow.xaml(315) <TextBlock>
    SourcePanel: TWinUIExpander;                         // MainWindow.xaml(321) <Expander>
    XamlSource: TWinUITextBox;                           // MainWindow.xaml(324) <TextBox>
    PascalSource: TWinUITextBox;                         // MainWindow.xaml(326) <TextBox>
    StatusText: TWinUITextBlock;                         // MainWindow.xaml(333) <TextBlock>
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
  // MainWindow.xaml(10): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="Surface" Background="Transparent" RequestedTheme="Default">' + sLineBreak +
    '    <Grid.RowDefinitions>' + sLineBreak +
    '      <RowDefinition Height="48" />' + sLineBreak +
    '      <RowDefinition Height="*" />' + sLineBreak +
    '      <RowDefinition Height="32" />' + sLineBreak +
    '    </Grid.RowDefinitions>' + sLineBreak +
    '    <Border x:Name="SolidLayer" Grid.RowSpan="3" Visibility="Collapsed" Background="{ThemeResource ApplicationPageBackgroundThemeBrush}" />' + sLineBreak +
    '    <Grid ColumnSpacing="24" Margin="20,0,148,0">' + sLineBreak +
    '      <Grid.ColumnDefinitions><ColumnDefinition Width="*" /><ColumnDefinition Width="180" /></Grid.ColumnDefinitions>' + sLineBreak +
    '      <Grid x:Name="DragRegion" Background="Transparent">' + sLineBreak +
    '        <StackPanel Orientation="Horizontal" Spacing="12" VerticalAlignment="Center">' + sLineBreak +
    '          <FontIcon Glyph="" FontFamily="{ThemeResource SymbolThemeFontFamily}" FontSize="18" Foreground="{ThemeResource SystemControlForegroundAccentBrush}" />' + sLineBreak +
    '          <TextBlock Text="RADWinUI Gallery" FontWeight="SemiBold" VerticalAlignment="Center" />' + sLineBreak +
    '          <Border Padding="8,3" CornerRadius="5" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}">' + sLineBreak +
    '            <TextBlock Text="DELPHI + WINUI 3" FontSize="9" CharacterSpacing="80" />' + sLineBreak +
    '          </Border>' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </Grid>' + sLineBreak +
    '      <ComboBox x:Name="ThemeChoice" Grid.Column="1" SelectedIndex="0" VerticalAlignment="Center" HorizontalAlignment="Stretch" AutomationProperties.Name="Appearance">' + sLineBreak +
    '        <ComboBoxItem Content="Windows theme" /><ComboBoxItem Content="Light" /><ComboBoxItem Content="Dark" />' + sLineBreak +
    '      </ComboBox>' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '    <NavigationView x:Name="Navigation" Grid.Row="1" PaneTitle="Explore" OpenPaneLength="240" IsBackButtonVisible="Collapsed" IsSettingsVisible="False" PaneDisplayMode="Auto" Background="Transparent">' + sLineBreak +
    '      <NavigationView.AutoSuggestBox>' + sLineBreak +
    '        <AutoSuggestBox x:Name="SearchBox" PlaceholderText="Find a control or demo" QueryIcon="Find" AutomationProperties.Name="Search demos" />' + sLineBreak +
    '      </NavigationView.AutoSuggestBox>' + sLineBreak +
    '      <NavigationView.MenuItems>' + sLineBreak +
    '        <NavigationViewItem x:Name="NavHome" Content="Overview" Tag="0" Icon="Home" />' + sLineBreak +
    '        <NavigationViewItem x:Name="NavExplorer" Content="Control explorer" Tag="8" Icon="AllApps" />' + sLineBreak +
    '        <NavigationViewItemSeparator />' + sLineBreak +
    '        <NavigationViewItemHeader Content="CONTROL DEMOS" />' + sLineBreak +
    '        <NavigationViewItem x:Name="NavInputs" Content="Basic input" Tag="1" Icon="Edit" />' + sLineBreak +
    '        <NavigationViewItem x:Name="NavCollections" Content="Lists and collections" Tag="2" Icon="List" />' + sLineBreak +
    '        <NavigationViewItem x:Name="NavDates" Content="Date and time" Tag="3" Icon="Calendar" />' + sLineBreak +
    '        <NavigationViewItem x:Name="NavFeedback" Content="Feedback and dialogs" Tag="4" Icon="Message" />' + sLineBreak +
    '        <NavigationViewItem x:Name="NavLayout" Content="Layout and navigation" Tag="5" Icon="AllApps" />' + sLineBreak +
    '        <NavigationViewItem x:Name="NavMaterials" Content="Materials and color" Tag="6" Icon="Highlight" />' + sLineBreak +
    '        <NavigationViewItemSeparator />' + sLineBreak +
    '        <NavigationViewItemHeader Content="MADE WITH DELPHI" />' + sLineBreak +
    '        <NavigationViewItem x:Name="NavBinding" Content="Live Pascal binding" Tag="7" Icon="Sync" />' + sLineBreak +
    '      </NavigationView.MenuItems>' + sLineBreak +
    '      <ScrollViewer x:Name="PageScroll" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">' + sLineBreak +
    '        <StackPanel Spacing="24" Margin="28,20,28,32" MaxWidth="1120" HorizontalAlignment="Stretch">' + sLineBreak +
    '          <StackPanel Spacing="6">' + sLineBreak +
    '            <TextBlock x:Name="PageTitle" Text="A native canvas for your ideas" FontSize="30" FontWeight="SemiBold" TextWrapping="Wrap" />' + sLineBreak +
    '            <TextBlock x:Name="PageDescription" Text="Explore real Windows controls, backed by Object Pascal." Foreground="{ThemeResource TextFillColorSecondaryBrush}" TextWrapping="Wrap" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '' + sLineBreak +
    '          <StackPanel x:Name="HomePage" Spacing="24">' + sLineBreak +
    '            <Border CornerRadius="16" Padding="32">' + sLineBreak +
    '              <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="1,1">' + sLineBreak +
    '                <GradientStop Color="{ThemeResource SystemAccentColorDark2}" Offset="0" />' + sLineBreak +
    '                <GradientStop Color="{ThemeResource SystemAccentColorDark3}" Offset="1" />' + sLineBreak +
    '              </LinearGradientBrush></Border.Background>' + sLineBreak +
    '              <Grid ColumnSpacing="24">' + sLineBreak +
    '                <Grid.ColumnDefinitions><ColumnDefinition Width="*" /><ColumnDefinition Width="160" /></Grid.ColumnDefinitions>' + sLineBreak +
    '                <StackPanel Spacing="16">' + sLineBreak +
    '                  <TextBlock Text="NATIVE WINDOWS. FAMILIAR DELPHI." Foreground="White" Opacity="0.85" FontSize="10" CharacterSpacing="140" />' + sLineBreak +
    '                  <TextBlock Text="Build native.&#10;Think Delphi." FontSize="42" FontWeight="SemiBold" Foreground="White" />' + sLineBreak +
    '                  <TextBlock Text="WinUI 3 controls and materials. XAML layouts. Pascal events and live binding." TextWrapping="Wrap" Foreground="White" Opacity="0.9" MaxWidth="520" HorizontalAlignmen' +
    't="Left" />' + sLineBreak +
    '                  <Button Content="Explore 30 controls" Tag="8" Padding="16,10" x:Name="_rw1" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <Border Grid.Column="1" CornerRadius="28" BorderBrush="#55FFFFFF" BorderThickness="1" Background="#18FFFFFF" Width="140" Height="140" VerticalAlignment="Center">' + sLineBreak +
    '                  <StackPanel Spacing="4" VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{}{ }" Foreground="White" FontFamily="Cascadia Code" FontSize="52" HorizontalAlignment="Center" />' + sLineBreak +
    '                    <TextBlock Text="OBJECT PASCAL" Foreground="White" FontSize="9" CharacterSpacing="100" HorizontalAlignment="Center" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </Border>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <StackPanel Spacing="6">' + sLineBreak +
    '              <TextBlock Text="Find your next building block" FontSize="21" FontWeight="SemiBold" />' + sLineBreak +
    '              <TextBlock Text="30 individual controls. Seven guided demos. Source you can take with you." Foreground="{ThemeResource TextFillColorSecondaryBrush}" TextWrapping="Wrap" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '            <Grid ColumnSpacing="12" RowSpacing="12">' + sLineBreak +
    '              <Grid.ColumnDefinitions><ColumnDefinition Width="*" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>' + sLineBreak +
    '              <Grid.RowDefinitions><RowDefinition /><RowDefinition /><RowDefinition /><RowDefinition /></Grid.RowDefinitions>' + sLineBreak +
    '              <Button Tag="1" HorizontalAlignment="Stretch" HorizontalContentAlignment="Stretch" Padding="20" CornerRadius="12" x:Name="_rw2">' + sLineBreak +
    '                <StackPanel Spacing="8"><FontIcon Glyph="" FontSize="24" HorizontalAlignment="Left" Foreground="{ThemeResource SystemControlForegroundAccentBrush}" />' + sLineBreak +
    '                  <TextBlock Text="Basic input" FontWeight="SemiBold" FontSize="16" /><TextBlock Text="Buttons, text, switches and value controls." TextWrapping="Wrap" Foreground="{ThemeResource TextF' +
    'illColorSecondaryBrush}" /></StackPanel>' + sLineBreak +
    '              </Button>' + sLineBreak +
    '              <Button Grid.Column="1" Tag="2" HorizontalAlignment="Stretch" HorizontalContentAlignment="Stretch" Padding="20" CornerRadius="12" x:Name="_rw3">' + sLineBreak +
    '                <StackPanel Spacing="8"><FontIcon Glyph="" FontSize="24" HorizontalAlignment="Left" Foreground="{ThemeResource SystemControlForegroundAccentBrush}" />' + sLineBreak +
    '                  <TextBlock Text="Lists and collections" FontWeight="SemiBold" FontSize="16" /><TextBlock Text="Build a collection and explore a hierarchy." TextWrapping="Wrap" Foreground="{ThemeReso' +
    'urce TextFillColorSecondaryBrush}" /></StackPanel>' + sLineBreak +
    '              </Button>' + sLineBreak +
    '              <Button Grid.Row="1" Tag="3" HorizontalAlignment="Stretch" HorizontalContentAlignment="Stretch" Padding="20" CornerRadius="12" x:Name="_rw4">' + sLineBreak +
    '                <StackPanel Spacing="8"><FontIcon Glyph="" FontSize="24" HorizontalAlignment="Left" Foreground="{ThemeResource SystemControlForegroundAccentBrush}" />' + sLineBreak +
    '                  <TextBlock Text="Date and time" FontWeight="SemiBold" FontSize="16" /><TextBlock Text="Native calendars and date/time pickers." TextWrapping="Wrap" Foreground="{ThemeResource TextFil' +
    'lColorSecondaryBrush}" /></StackPanel>' + sLineBreak +
    '              </Button>' + sLineBreak +
    '              <Button Grid.Row="1" Grid.Column="1" Tag="4" HorizontalAlignment="Stretch" HorizontalContentAlignment="Stretch" Padding="20" CornerRadius="12" x:Name="_rw5">' + sLineBreak +
    '                <StackPanel Spacing="8"><FontIcon Glyph="" FontSize="24" HorizontalAlignment="Left" Foreground="{ThemeResource SystemControlForegroundAccentBrush}" />' + sLineBreak +
    '                  <TextBlock Text="Feedback and dialogs" FontWeight="SemiBold" FontSize="16" /><TextBlock Text="Info bars, progress and native modal dialogs." TextWrapping="Wrap" Foreground="{ThemeRes' +
    'ource TextFillColorSecondaryBrush}" /></StackPanel>' + sLineBreak +
    '              </Button>' + sLineBreak +
    '              <Button Grid.Row="2" Tag="5" HorizontalAlignment="Stretch" HorizontalContentAlignment="Stretch" Padding="20" CornerRadius="12" x:Name="_rw6">' + sLineBreak +
    '                <StackPanel Spacing="8"><FontIcon Glyph="" FontSize="24" HorizontalAlignment="Left" Foreground="{ThemeResource SystemControlForegroundAccentBrush}" />' + sLineBreak +
    '                  <TextBlock Text="Layout and navigation" FontWeight="SemiBold" FontSize="16" /><TextBlock Text="Grids, tabs and expandable content." TextWrapping="Wrap" Foreground="{ThemeResource Tex' +
    'tFillColorSecondaryBrush}" /></StackPanel>' + sLineBreak +
    '              </Button>' + sLineBreak +
    '              <Button Grid.Row="2" Grid.Column="1" Tag="6" HorizontalAlignment="Stretch" HorizontalContentAlignment="Stretch" Padding="20" CornerRadius="12" x:Name="_rw7">' + sLineBreak +
    '                <StackPanel Spacing="8"><FontIcon Glyph="" FontSize="24" HorizontalAlignment="Left" Foreground="{ThemeResource SystemControlForegroundAccentBrush}" />' + sLineBreak +
    '                  <TextBlock Text="Materials and color" FontWeight="SemiBold" FontSize="16" /><TextBlock Text="Mica, Acrylic and a live color playground." TextWrapping="Wrap" Foreground="{ThemeResourc' +
    'e TextFillColorSecondaryBrush}" /></StackPanel>' + sLineBreak +
    '              </Button>' + sLineBreak +
    '              <Button Grid.Row="3" Grid.ColumnSpan="2" Tag="7" HorizontalAlignment="Stretch" HorizontalContentAlignment="Stretch" Padding="20" CornerRadius="12" x:Name="_rw8">' + sLineBreak +
    '                <StackPanel Spacing="8"><TextBlock Text="Live Pascal binding" FontWeight="SemiBold" FontSize="16" />' + sLineBreak +
    '                  <TextBlock Text="Edit a name, click a button, and watch published Delphi properties update the UI." TextWrapping="Wrap" Foreground="{ThemeResource TextFillColorSecondaryBrush}" /></S' +
    'tackPanel>' + sLineBreak +
    '              </Button>' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '' + sLineBreak +
    '          <StackPanel x:Name="InputsPage" Spacing="16" Visibility="Collapsed">' + sLineBreak +
    '            <Border Padding="24" CornerRadius="12" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}" BorderThickness="1">' + sLineBreak +
    '              <StackPanel Spacing="18">' + sLineBreak +
    '                <TextBlock Text="Make it personal" FontSize="20" FontWeight="SemiBold" />' + sLineBreak +
    '                <TextBox x:Name="NameEntry" Header="Your name" PlaceholderText="Type a name" MaxWidth="420" HorizontalAlignment="Left" />' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12"><Button Content="Say hello" Style="{StaticResource AccentButtonStyle}" x:Name="_rw9" /><CheckBox Content="Remember this device" IsChec' +
    'ked="True" /></StackPanel>' + sLineBreak +
    '                <TextBlock x:Name="GreetingText" Text="A Pascal event is ready for your click." TextWrapping="Wrap" />' + sLineBreak +
    '                <ToggleSwitch x:Name="DemoSwitch" Header="Notifications" OnContent="Enabled" OffContent="Quiet mode" IsOn="True" />' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="18"><RadioButton Content="Comfortable" GroupName="Density" IsChecked="True" /><RadioButton Content="Compact" GroupName="Density" /></Stack' +
    'Panel>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <Border Padding="24" CornerRadius="12" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}" BorderThickness="1">' + sLineBreak +
    '              <StackPanel Spacing="16">' + sLineBreak +
    '                <TextBlock Text="Values and choices" FontSize="20" FontWeight="SemiBold" />' + sLineBreak +
    '                <Grid ColumnSpacing="24"><Grid.ColumnDefinitions><ColumnDefinition Width="*" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>' + sLineBreak +
    '                  <NumberBox Header="Quantity" Value="42" SpinButtonPlacementMode="Inline" Minimum="0" Maximum="100" />' + sLineBreak +
    '                  <ComboBox Grid.Column="1" Header="Preset" SelectedIndex="0" HorizontalAlignment="Stretch"><ComboBoxItem Content="Balanced" /><ComboBoxItem Content="Focused" /><ComboBoxItem Content="' +
    'Expressive" /></ComboBox>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <TextBlock x:Name="VolumeText" Text="Intensity: 64%" />' + sLineBreak +
    '                <Slider x:Name="IntensitySlider" Minimum="0" Maximum="100" Value="64" AutomationProperties.Name="Intensity" />' + sLineBreak +
    '                <ProgressBar x:Name="IntensityProgress" Minimum="0" Maximum="100" Value="64" />' + sLineBreak +
    '                <RatingControl Caption="How does it feel?" Value="4" MaxRating="5" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '' + sLineBreak +
    '          <StackPanel x:Name="CollectionsPage" Spacing="16" Visibility="Collapsed">' + sLineBreak +
    '            <Border Padding="24" CornerRadius="12" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}" BorderThickness="1">' + sLineBreak +
    '              <StackPanel Spacing="16">' + sLineBreak +
    '                <TextBlock Text="A collection owned by Delphi" FontSize="20" FontWeight="SemiBold" />' + sLineBreak +
    '                <Grid ColumnSpacing="8"><Grid.ColumnDefinitions><ColumnDefinition Width="*" /><ColumnDefinition Width="Auto" /><ColumnDefinition Width="Auto" /></Grid.ColumnDefinitions>' + sLineBreak +
    '                  <TextBox x:Name="NewItemText" PlaceholderText="Add your next idea" AutomationProperties.Name="New list item" />' + sLineBreak +
    '                  <Button Grid.Column="1" Content="Add" x:Name="_rw10" />' + sLineBreak +
    '                  <Button Grid.Column="2" Content="Remove selected" x:Name="_rw11" />' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <ListView x:Name="DemoList" SelectionMode="Single" Height="180" />' + sLineBreak +
    '                <TextBlock x:Name="SelectionText" Text="Choose an item to inspect the selection." Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <Border Padding="24" CornerRadius="12" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}" BorderThickness="1">' + sLineBreak +
    '              <StackPanel Spacing="16"><TextBlock Text="A native hierarchy" FontSize="20" FontWeight="SemiBold" />' + sLineBreak +
    '                <TreeView Height="180"><TreeView.RootNodes>' + sLineBreak +
    '                  <TreeViewNode Content="RADWinUI application" IsExpanded="True"><TreeViewNode.Children>' + sLineBreak +
    '                    <TreeViewNode Content="MainWindow.xaml" /><TreeViewNode Content="MainWindow.pas" />' + sLineBreak +
    '                    <TreeViewNode Content="Framework" IsExpanded="True"><TreeViewNode.Children><TreeViewNode Content="Native WinUI controls" /><TreeViewNode Content="Pascal events and binding" /></Tre' +
    'eViewNode.Children></TreeViewNode>' + sLineBreak +
    '                  </TreeViewNode.Children></TreeViewNode>' + sLineBreak +
    '                </TreeView.RootNodes></TreeView>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '' + sLineBreak +
    '          <StackPanel x:Name="DatesPage" Spacing="16" Visibility="Collapsed">' + sLineBreak +
    '            <Border Padding="24" CornerRadius="12" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}" BorderThickness="1">' + sLineBreak +
    '              <StackPanel Spacing="20"><TextBlock Text="Choose a moment" FontSize="20" FontWeight="SemiBold" />' + sLineBreak +
    '                <CalendarDatePicker Header="A date, with a calendar flyout" PlaceholderText="Choose a date" />' + sLineBreak +
    '                <DatePicker Header="Date picker" /><TimePicker Header="Time picker" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <Border Padding="24" CornerRadius="12" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}" BorderThickness="1">' + sLineBreak +
    '              <StackPanel Spacing="16"><TextBlock Text="The calendar, inline" FontSize="20" FontWeight="SemiBold" />' + sLineBreak +
    '                <CalendarView SelectionMode="Single" HorizontalAlignment="Left" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '' + sLineBreak +
    '          <StackPanel x:Name="FeedbackPage" Spacing="16" Visibility="Collapsed">' + sLineBreak +
    '            <InfoBar x:Name="FeedbackBar" IsOpen="True" IsClosable="True" Title="Ready to explore" Message="These are native WinUI controls with Pascal handlers." Severity="Informational" />' + sLineBreak +
    '            <Border Padding="24" CornerRadius="12" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}" BorderThickness="1">' + sLineBreak +
    '              <StackPanel Spacing="20"><TextBlock Text="Clear feedback, familiar behavior" FontSize="20" FontWeight="SemiBold" />' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="8"><Button Content="Success" Tag="success" x:Name="_rw12" /><Button Content="Warning" Tag="warning" x:Name="_rw13" /><Button Content="Open' +
    ' dialog" x:Name="_rw14" /></StackPanel>' + sLineBreak +
    '                <ToggleSwitch x:Name="ActivitySwitch" Header="Background activity" IsOn="True" />' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="16"><ProgressRing x:Name="ActivityRing" IsActive="True" Width="32" Height="32" /><TextBlock Text="A Windows animation, no custom drawing l' +
    'oop." VerticalAlignment="Center" TextWrapping="Wrap" /></StackPanel>' + sLineBreak +
    '                <ProgressBar x:Name="ActivityProgress" IsIndeterminate="True" />' + sLineBreak +
    '                <Button Content="Open a native flyout"><Button.Flyout><Flyout><StackPanel Spacing="12"><TextBlock Text="Content in a native flyout" FontWeight="SemiBold" /><ToggleSwitch Header="An opt' +
    'ion" IsOn="True" /></StackPanel></Flyout></Button.Flyout></Button>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '' + sLineBreak +
    '          <StackPanel x:Name="LayoutPage" Spacing="16" Visibility="Collapsed">' + sLineBreak +
    '            <Border Padding="24" CornerRadius="12" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}" BorderThickness="1">' + sLineBreak +
    '              <StackPanel Spacing="18"><TextBlock Text="Layout comes from XAML" FontSize="20" FontWeight="SemiBold" />' + sLineBreak +
    '                <Grid ColumnSpacing="10" RowSpacing="10"><Grid.ColumnDefinitions><ColumnDefinition Width="2*" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions><Grid.RowDefinitions><RowDefiniti' +
    'on Height="64" /><RowDefinition Height="64" /></Grid.RowDefinitions>' + sLineBreak +
    '                  <Border CornerRadius="8" Background="{ThemeResource AccentFillColorDefaultBrush}"><TextBlock Text="2*" Foreground="{ThemeResource TextOnAccentFillColorPrimaryBrush}" HorizontalAlignm' +
    'ent="Center" VerticalAlignment="Center" FontSize="20" /></Border>' + sLineBreak +
    '                  <Border Grid.Column="1" CornerRadius="8" Background="{ThemeResource CardStrokeColorDefaultBrush}"><TextBlock Text="*" HorizontalAlignment="Center" VerticalAlignment="Center" FontSize' +
    '="20" /></Border>' + sLineBreak +
    '                  <Border Grid.Row="1" Grid.ColumnSpan="2" CornerRadius="8" Background="{ThemeResource CardStrokeColorDefaultBrush}"><TextBlock Text="ColumnSpan = 2" HorizontalAlignment="Center" Verti' +
    'calAlignment="Center" /></Border>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <Expander Header="Expand for a layout tip" HorizontalAlignment="Stretch"><TextBlock Text="Use Grid for rows, columns and remaining space. Use StackPanel for a flowing sequence. The des' +
    'igner writes ordinary XAML." TextWrapping="Wrap" /></Expander>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <TabView IsAddTabButtonVisible="False" Height="200">' + sLineBreak +
    '              <TabViewItem Header="Overview" IsClosable="False"><Border Padding="24"><TextBlock Text="A real WinUI TabView. Switch tabs with the mouse or keyboard." TextWrapping="Wrap" /></Border></Ta' +
    'bViewItem>' + sLineBreak +
    '              <TabViewItem Header="Details" IsClosable="False"><Border Padding="24"><StackPanel Spacing="10"><TextBlock Text="Keep navigation native." FontSize="20" FontWeight="SemiBold" /><TextBlock ' +
    'Text="Tab focus, selected state and theme resources come from WinUI." TextWrapping="Wrap" /></StackPanel></Border></TabViewItem>' + sLineBreak +
    '            </TabView>' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '' + sLineBreak +
    '          <StackPanel x:Name="MaterialsPage" Spacing="16" Visibility="Collapsed">' + sLineBreak +
    '            <Border Padding="24" CornerRadius="12" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}" BorderThickness="1">' + sLineBreak +
    '              <StackPanel Spacing="16"><TextBlock Text="Windows materials, on your desktop" FontSize="20" FontWeight="SemiBold" />' + sLineBreak +
    '                <ComboBox x:Name="BackdropChoice" Header="Window backdrop" SelectedIndex="0" MinWidth="240"><ComboBoxItem Content="Mica" /><ComboBoxItem Content="Mica Alt" /><ComboBoxItem Content="Des' +
    'ktop Acrylic" /><ComboBoxItem Content="Solid surface" /></ComboBox>' + sLineBreak +
    '                <TextBlock Text="The title bar and navigation surface expose the backdrop. Windows can use a solid fallback when inactive, or because of transparency, power or accessibility settings."' +
    ' TextWrapping="Wrap" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <Border Padding="24" CornerRadius="12" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}" BorderThickness="1">' + sLineBreak +
    '              <StackPanel Spacing="16"><TextBlock Text="A live color playground" FontSize="20" FontWeight="SemiBold" />' + sLineBreak +
    '                <Grid ColumnSpacing="24"><Grid.ColumnDefinitions><ColumnDefinition Width="Auto" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>' + sLineBreak +
    '                  <ColorPicker x:Name="DemoColorPicker" Color="#FF206DCA" IsAlphaEnabled="True" IsMoreButtonVisible="False" Width="300" />' + sLineBreak +
    '                  <StackPanel Grid.Column="1" Spacing="12" VerticalAlignment="Center"><Border x:Name="ColorSwatch" Height="140" CornerRadius="16" Background="#FF206DCA" />' + sLineBreak +
    '                    <TextBlock x:Name="ColorValue" Text="#FF206DCA" FontFamily="Cascadia Code" FontSize="18" />' + sLineBreak +
    '                    <TextBlock Text="A ColorChanged event updates a Delphi-owned brush." TextWrapping="Wrap" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '' + sLineBreak +
    '          <StackPanel x:Name="BindingPage" Spacing="16" Visibility="Collapsed">' + sLineBreak +
    '            <Border Padding="24" CornerRadius="12" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}" BorderThickness="1">' + sLineBreak +
    '              <StackPanel Spacing="20"><TextBlock Text="Published properties. Live UI." FontSize="20" FontWeight="SemiBold" />' + sLineBreak +
    '                <TextBox Header="A two-way bound Delphi string" Text="{Binding Name, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" />' + sLineBreak +
    '                <TextBlock Text="{Binding Summary}" TextWrapping="Wrap" FontSize="20" />' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12"><Button Content="Increment" Style="{StaticResource AccentButtonStyle}" x:Name="_rw15" /><Button Content="Reset" x:Name="_rw16" />' + sLineBreak +
    '                  <TextBlock Text="{Binding Count}" FontSize="30" VerticalAlignment="Center" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <ProgressBar Value="{Binding Count}" Maximum="100" />' + sLineBreak +
    '                <TextBlock Text="No polling of the model. Changed(''Name'') and Changed(''Count'') notify the native bindings. The clock in the footer is another published property." TextWrapping="Wrap" F' +
    'oreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '' + sLineBreak +
    '          <Grid x:Name="ExplorerPage" Visibility="Collapsed" ColumnSpacing="20">' + sLineBreak +
    '            <Grid.ColumnDefinitions><ColumnDefinition Width="200" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>' + sLineBreak +
    '            <StackPanel Spacing="10">' + sLineBreak +
    '              <TextBox x:Name="ExplorerFilter" PlaceholderText="Filter controls" AutomationProperties.Name="Filter controls" />' + sLineBreak +
    '              <TextBlock x:Name="ExplorerCount" Text="30 controls" FontSize="12" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '              <ListView x:Name="ExplorerList" Height="440" AutomationProperties.Name="Control catalog" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '            <StackPanel Grid.Column="1" Spacing="16">' + sLineBreak +
    '              <StackPanel Spacing="5">' + sLineBreak +
    '                <TextBlock x:Name="ControlTitle" Text="Button" FontSize="24" FontWeight="SemiBold" />' + sLineBreak +
    '                <TextBlock x:Name="ControlCategory" Text="Basic input" Foreground="{ThemeResource SystemControlForegroundAccentBrush}" />' + sLineBreak +
    '                <TextBlock x:Name="ControlDescription" TextWrapping="Wrap" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Border Padding="20" CornerRadius="12" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}" BorderThickness="1">' + sLineBreak +
    '                <StackPanel Spacing="16">' + sLineBreak +
    '                  <TextBlock Text="LIVE SAMPLE" FontSize="10" CharacterSpacing="100" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                  <StackPanel x:Name="ExplorerSamples" MinHeight="140">' + sLineBreak +
    '                    <StackPanel Tag="Button" Visibility="Collapsed" HorizontalAlignment="Stretch"><Button x:Name="SampleButton" Content="Click me" Style="{StaticResource AccentButtonStyle}" /></StackP' +
    'anel>' + sLineBreak +
    '                    <StackPanel Tag="ToggleButton" Visibility="Collapsed" HorizontalAlignment="Stretch"><ToggleButton x:Name="SampleToggleButton" Content="Keep this selected" /></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="RepeatButton" Visibility="Collapsed" HorizontalAlignment="Stretch"><RepeatButton x:Name="SampleRepeatButton" Content="Press and hold" Delay="400" Interval="100" />' +
    '</StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="SplitButton" Visibility="Collapsed" HorizontalAlignment="Stretch"><SplitButton x:Name="SampleSplitButton" Content="Export"><SplitButton.Flyout><MenuFlyout><MenuFly' +
    'outItem Text="As image" /><MenuFlyoutItem Text="As document" /></MenuFlyout></SplitButton.Flyout></SplitButton></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="HyperlinkButton" Visibility="Collapsed" HorizontalAlignment="Stretch"><HyperlinkButton x:Name="SampleHyperlinkButton" Content="A native hyperlink" /></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="TextBox" Visibility="Collapsed" HorizontalAlignment="Stretch"><TextBox x:Name="SampleTextBox" Header="Your idea" PlaceholderText="Type something" Text="Made with D' +
    'elphi" /></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="PasswordBox" Visibility="Collapsed" HorizontalAlignment="Stretch"><PasswordBox x:Name="SamplePasswordBox" Header="Sample password" PlaceholderText="Enter a sample ' +
    'password" /></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="RichEditBox" Visibility="Collapsed" HorizontalAlignment="Stretch"><RichEditBox x:Name="SampleRichEditBox" Header="A richer canvas" Height="120" PlaceholderText="Wr' +
    'ite, select text, then open the editing menu" /></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="NumberBox" Visibility="Collapsed" HorizontalAlignment="Stretch"><NumberBox x:Name="SampleNumberBox" Header="Quantity" Value="12" Minimum="0" Maximum="100" SpinButt' +
    'onPlacementMode="Inline" /></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="Slider" Visibility="Collapsed" HorizontalAlignment="Stretch"><Slider x:Name="SampleSlider" Minimum="0" Maximum="100" Value="64" StepFrequency="1" AutomationPropert' +
    'ies.Name="Sample intensity" /></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="ToggleSwitch" Visibility="Collapsed" HorizontalAlignment="Stretch"><ToggleSwitch x:Name="SampleToggleSwitch" Header="Notifications" OnContent="Enabled" OffContent=' +
    '"Disabled" IsOn="True" /></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="CheckBox" Visibility="Collapsed" HorizontalAlignment="Stretch"><CheckBox x:Name="SampleCheckBox" Content="Include subfolders" IsThreeState="True" /></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="RadioButtons" Visibility="Collapsed" HorizontalAlignment="Stretch"><RadioButtons x:Name="SampleRadioButtons" Header="Density" SelectedIndex="0"><RadioButton Conten' +
    't="Comfortable" /><RadioButton Content="Compact" /></RadioButtons></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="ComboBox" Visibility="Collapsed" HorizontalAlignment="Stretch"><ComboBox x:Name="SampleComboBox" Header="Workspace" SelectedIndex="0" HorizontalAlignment="Stretch"' +
    '><ComboBoxItem Content="Design" /><ComboBoxItem Content="Code" /><ComboBoxItem Content="Explore" /></ComboBox></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="ListBox" Visibility="Collapsed" HorizontalAlignment="Stretch"><ListBox x:Name="SampleListBox" SelectedIndex="0"><ListBoxItem Content="Create a window" /><ListBoxIt' +
    'em Content="Drop a control" /><ListBoxItem Content="Write Pascal" /></ListBox></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="GridView" Visibility="Collapsed" HorizontalAlignment="Stretch"><GridView x:Name="SampleGridView" SelectionMode="Single" Height="160"><GridViewItem><Border Backgrou' +
    'nd="{ThemeResource AccentFillColorDefaultBrush}" Padding="20"><TextBlock Text="Design" /></Border></GridViewItem><GridViewItem><Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" ' +
    'Padding="20"><TextBlock Text="Code" /></Border></GridViewItem></GridView></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="Expander" Visibility="Collapsed" HorizontalAlignment="Stretch"><Expander x:Name="SampleExpander" Header="Details" HorizontalAlignment="Stretch"><TextBlock Text="Na' +
    'tive controls. Object Pascal events." TextWrapping="Wrap" /></Expander></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="TabView" Visibility="Collapsed" HorizontalAlignment="Stretch"><TabView x:Name="SampleTabView" IsAddTabButtonVisible="False" Height="170"><TabViewItem Header="Desig' +
    'n" IsClosable="False"><TextBlock Text="Your XAML surface" Margin="12" /></TabViewItem><TabViewItem Header="Code" IsClosable="False"><TextBlock Text="Your Object Pascal" Margin="12" /></TabViewItem></T' +
    'abView></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="CalendarDatePicker" Visibility="Collapsed" HorizontalAlignment="Stretch"><CalendarDatePicker x:Name="SampleCalendarDatePicker" Header="Start date" PlaceholderText=' +
    '"Choose a date" /></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="DatePicker" Visibility="Collapsed" HorizontalAlignment="Stretch"><DatePicker x:Name="SampleDatePicker" Header="Date" /></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="TimePicker" Visibility="Collapsed" HorizontalAlignment="Stretch"><TimePicker x:Name="SampleTimePicker" Header="Reminder" MinuteIncrement="5" /></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="ProgressBar" Visibility="Collapsed" HorizontalAlignment="Stretch"><ProgressBar x:Name="SampleProgressBar" Minimum="0" Maximum="100" Value="65" AutomationProperties' +
    '.Name="Sample progress" /></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="ProgressRing" Visibility="Collapsed" HorizontalAlignment="Stretch"><ProgressRing x:Name="SampleProgressRing" IsActive="True" Width="48" Height="48" HorizontalAlign' +
    'ment="Left" AutomationProperties.Name="Working" /></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="RatingControl" Visibility="Collapsed" HorizontalAlignment="Stretch"><RatingControl x:Name="SampleRatingControl" Caption="Rate this idea" Value="4" MaxRating="5" />' +
    '</StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="ColorPicker" Visibility="Collapsed" HorizontalAlignment="Stretch"><ColorPicker x:Name="SampleColorPicker" Color="#FF0078D4" IsAlphaEnabled="True" /></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="InfoBar" Visibility="Collapsed" HorizontalAlignment="Stretch"><InfoBar x:Name="SampleInfoBar" IsOpen="True" Severity="Success" Title="Ready" Message="Built with De' +
    'lphi and WinUI 3." IsClosable="False" /></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="MenuBar" Visibility="Collapsed" HorizontalAlignment="Stretch"><MenuBar x:Name="SampleMenuBar"><MenuBarItem Title="File"><MenuFlyoutItem Text="New" /><MenuFlyoutIte' +
    'm Text="Open" /></MenuBarItem><MenuBarItem Title="Help"><MenuFlyoutItem Text="About" /></MenuBarItem></MenuBar></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="CommandBar" Visibility="Collapsed" HorizontalAlignment="Stretch"><CommandBar x:Name="SampleCommandBar" DefaultLabelPosition="Bottom"><AppBarButton Icon="Save" Labe' +
    'l="Save" /><AppBarButton Icon="Edit" Label="Edit" /><CommandBar.SecondaryCommands><AppBarButton Label="More options" /></CommandBar.SecondaryCommands></CommandBar></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="PersonPicture" Visibility="Collapsed" HorizontalAlignment="Stretch"><PersonPicture x:Name="SamplePersonPicture" DisplayName="Delphi Developer" Width="88" Height="8' +
    '8" HorizontalAlignment="Left" /></StackPanel>' + sLineBreak +
    '                    <StackPanel Tag="TextBlock" Visibility="Collapsed" HorizontalAlignment="Stretch"><TextBlock x:Name="SampleTextBlock" Text="A native canvas for your ideas." FontSize="28" FontWeight' +
    '="SemiBold" TextWrapping="Wrap" IsTextSelectionEnabled="True" /></StackPanel>' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Expander Header="Try the layout" HorizontalAlignment="Stretch" IsExpanded="True">' + sLineBreak +
    '                <StackPanel Spacing="12">' + sLineBreak +
    '                  <ToggleSwitch x:Name="ExplorerEnabled" Header="Enabled" IsOn="True" />' + sLineBreak +
    '                  <ComboBox x:Name="ExplorerFlow" Header="Reading direction" SelectedIndex="0" HorizontalAlignment="Stretch">' + sLineBreak +
    '                    <ComboBoxItem Content="Left to right" /><ComboBoxItem Content="Right to left" />' + sLineBreak +
    '                  </ComboBox>' + sLineBreak +
    '                  <Button Content="Read current value in Pascal" x:Name="_rw17" />' + sLineBreak +
    '                  <TextBlock x:Name="ExplorerValue" Text="Choose a control, interact with it, then read its value." TextWrapping="Wrap" FontSize="12" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Expander>' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '' + sLineBreak +
    '          <Expander x:Name="SourcePanel" Header="View XAML and Pascal" HorizontalAlignment="Stretch" Visibility="Collapsed">' + sLineBreak +
    '            <StackPanel Spacing="16">' + sLineBreak +
    '              <Grid><TextBlock Text="XAML" FontWeight="SemiBold" VerticalAlignment="Center" /><Button Content="Copy XAML" HorizontalAlignment="Right" x:Name="_rw18" /></Grid>' + sLineBreak +
    '              <TextBox x:Name="XamlSource" IsReadOnly="True" AcceptsReturn="True" TextWrapping="NoWrap" FontFamily="Cascadia Code" FontSize="12" Height="150" ScrollViewer.HorizontalScrollBarVisibility' +
    '="Auto" AutomationProperties.Name="XAML example" />' + sLineBreak +
    '              <Grid><TextBlock Text="OBJECT PASCAL" FontWeight="SemiBold" VerticalAlignment="Center" /><Button Content="Copy Pascal" HorizontalAlignment="Right" x:Name="_rw19" /></Grid>' + sLineBreak +
    '              <TextBox x:Name="PascalSource" IsReadOnly="True" AcceptsReturn="True" TextWrapping="NoWrap" FontFamily="Cascadia Code" FontSize="12" Height="180" ScrollViewer.HorizontalScrollBarVisibili' +
    'ty="Auto" AutomationProperties.Name="Pascal example" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Expander>' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </ScrollViewer>' + sLineBreak +
    '    </NavigationView>' + sLineBreak +
    '    <Grid Grid.Row="2" Margin="20,0" ColumnSpacing="16"><Grid.ColumnDefinitions><ColumnDefinition Width="*" /><ColumnDefinition Width="Auto" /></Grid.ColumnDefinitions>' + sLineBreak +
    '      <TextBlock x:Name="StatusText" Text="Native WinUI 3. Object Pascal. Made with RADWinUI." FontSize="11" VerticalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '      <TextBlock Grid.Column="1" Text="{Binding Clock}" FontSize="11" VerticalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '  </Grid>' + sLineBreak;

constructor TMainWindowBase.Create;
begin
  inherited;
  // MainWindow.xaml(1): <Window> attributes
  Title := 'RADWinUI Gallery';
  Width := 1180;
  Height := 840;
  MinWidth := 900;
  MinHeight := 640;
  Backdrop := TWinUIBackdrop.Mica;
  ExtendsContentIntoTitleBar := True;
  Center;
  LoadContent(ContentXaml);
  // x:Name elements
  Surface := FindElement<TWinUIGrid>('Surface');
  SolidLayer := FindElement<TWinUIBorder>('SolidLayer');
  DragRegion := FindElement<TWinUIGrid>('DragRegion');
  ThemeChoice := FindElement<TWinUIComboBox>('ThemeChoice');
  Navigation := FindElement<TWinUINavigationView>('Navigation');
  SearchBox := FindElement<TWinUIAutoSuggestBox>('SearchBox');
  NavHome := FindElement<TWinUINavigationViewItem>('NavHome');
  NavExplorer := FindElement<TWinUINavigationViewItem>('NavExplorer');
  NavInputs := FindElement<TWinUINavigationViewItem>('NavInputs');
  NavCollections := FindElement<TWinUINavigationViewItem>('NavCollections');
  NavDates := FindElement<TWinUINavigationViewItem>('NavDates');
  NavFeedback := FindElement<TWinUINavigationViewItem>('NavFeedback');
  NavLayout := FindElement<TWinUINavigationViewItem>('NavLayout');
  NavMaterials := FindElement<TWinUINavigationViewItem>('NavMaterials');
  NavBinding := FindElement<TWinUINavigationViewItem>('NavBinding');
  PageScroll := FindElement<TWinUIScrollViewer>('PageScroll');
  PageTitle := FindElement<TWinUITextBlock>('PageTitle');
  PageDescription := FindElement<TWinUITextBlock>('PageDescription');
  HomePage := FindElement<TWinUIStackPanel>('HomePage');
  InputsPage := FindElement<TWinUIStackPanel>('InputsPage');
  NameEntry := FindElement<TWinUITextBox>('NameEntry');
  GreetingText := FindElement<TWinUITextBlock>('GreetingText');
  DemoSwitch := FindElement<TWinUIToggleSwitch>('DemoSwitch');
  VolumeText := FindElement<TWinUITextBlock>('VolumeText');
  IntensitySlider := FindElement<TWinUISlider>('IntensitySlider');
  IntensityProgress := FindElement<TWinUIProgressBar>('IntensityProgress');
  CollectionsPage := FindElement<TWinUIStackPanel>('CollectionsPage');
  NewItemText := FindElement<TWinUITextBox>('NewItemText');
  DemoList := FindElement<TWinUIListView>('DemoList');
  SelectionText := FindElement<TWinUITextBlock>('SelectionText');
  DatesPage := FindElement<TWinUIStackPanel>('DatesPage');
  FeedbackPage := FindElement<TWinUIStackPanel>('FeedbackPage');
  FeedbackBar := FindElement<TWinUIInfoBar>('FeedbackBar');
  ActivitySwitch := FindElement<TWinUIToggleSwitch>('ActivitySwitch');
  ActivityRing := FindElement<TWinUIProgressRing>('ActivityRing');
  ActivityProgress := FindElement<TWinUIProgressBar>('ActivityProgress');
  LayoutPage := FindElement<TWinUIStackPanel>('LayoutPage');
  MaterialsPage := FindElement<TWinUIStackPanel>('MaterialsPage');
  BackdropChoice := FindElement<TWinUIComboBox>('BackdropChoice');
  DemoColorPicker := FindElement<TWinUIColorPicker>('DemoColorPicker');
  ColorSwatch := FindElement<TWinUIBorder>('ColorSwatch');
  ColorValue := FindElement<TWinUITextBlock>('ColorValue');
  BindingPage := FindElement<TWinUIStackPanel>('BindingPage');
  ExplorerPage := FindElement<TWinUIGrid>('ExplorerPage');
  ExplorerFilter := FindElement<TWinUITextBox>('ExplorerFilter');
  ExplorerCount := FindElement<TWinUITextBlock>('ExplorerCount');
  ExplorerList := FindElement<TWinUIListView>('ExplorerList');
  ControlTitle := FindElement<TWinUITextBlock>('ControlTitle');
  ControlCategory := FindElement<TWinUITextBlock>('ControlCategory');
  ControlDescription := FindElement<TWinUITextBlock>('ControlDescription');
  ExplorerSamples := FindElement<TWinUIStackPanel>('ExplorerSamples');
  SampleButton := FindElement<TWinUIButton>('SampleButton');
  SampleToggleButton := FindElement<TWinUIToggleButton>('SampleToggleButton');
  SampleRepeatButton := FindElement<TWinUIRepeatButton>('SampleRepeatButton');
  SampleSplitButton := FindElement<TWinUISplitButton>('SampleSplitButton');
  SampleHyperlinkButton := FindElement<TWinUIHyperlinkButton>('SampleHyperlinkButton');
  SampleTextBox := FindElement<TWinUITextBox>('SampleTextBox');
  SamplePasswordBox := FindElement<TWinUIPasswordBox>('SamplePasswordBox');
  SampleRichEditBox := FindElement<TWinUIRichEditBox>('SampleRichEditBox');
  SampleNumberBox := FindElement<TWinUINumberBox>('SampleNumberBox');
  SampleSlider := FindElement<TWinUISlider>('SampleSlider');
  SampleToggleSwitch := FindElement<TWinUIToggleSwitch>('SampleToggleSwitch');
  SampleCheckBox := FindElement<TWinUICheckBox>('SampleCheckBox');
  SampleRadioButtons := FindElement<TWinUIRadioButtons>('SampleRadioButtons');
  SampleComboBox := FindElement<TWinUIComboBox>('SampleComboBox');
  SampleListBox := FindElement<TWinUIListBox>('SampleListBox');
  SampleGridView := FindElement<TWinUIGridView>('SampleGridView');
  SampleExpander := FindElement<TWinUIExpander>('SampleExpander');
  SampleTabView := FindElement<TWinUITabView>('SampleTabView');
  SampleCalendarDatePicker := FindElement<TWinUICalendarDatePicker>('SampleCalendarDatePicker');
  SampleDatePicker := FindElement<TWinUIDatePicker>('SampleDatePicker');
  SampleTimePicker := FindElement<TWinUITimePicker>('SampleTimePicker');
  SampleProgressBar := FindElement<TWinUIProgressBar>('SampleProgressBar');
  SampleProgressRing := FindElement<TWinUIProgressRing>('SampleProgressRing');
  SampleRatingControl := FindElement<TWinUIRatingControl>('SampleRatingControl');
  SampleColorPicker := FindElement<TWinUIColorPicker>('SampleColorPicker');
  SampleInfoBar := FindElement<TWinUIInfoBar>('SampleInfoBar');
  SampleMenuBar := FindElement<TWinUIMenuBar>('SampleMenuBar');
  SampleCommandBar := FindElement<TWinUICommandBar>('SampleCommandBar');
  SamplePersonPicture := FindElement<TWinUIPersonPicture>('SamplePersonPicture');
  SampleTextBlock := FindElement<TWinUITextBlock>('SampleTextBlock');
  ExplorerEnabled := FindElement<TWinUIToggleSwitch>('ExplorerEnabled');
  ExplorerFlow := FindElement<TWinUIComboBox>('ExplorerFlow');
  ExplorerValue := FindElement<TWinUITextBlock>('ExplorerValue');
  SourcePanel := FindElement<TWinUIExpander>('SourcePanel');
  XamlSource := FindElement<TWinUITextBox>('XamlSource');
  PascalSource := FindElement<TWinUITextBox>('PascalSource');
  StatusText := FindElement<TWinUITextBlock>('StatusText');
  // Event wiring
  // MainWindow.xaml(30): SelectionChanged="ThemeChanged"
  ThemeChoice.OnSelectionChanged := TWinUISelectionChangedEventHandler(PublishedMethod('ThemeChanged'));
  // MainWindow.xaml(35): SelectionChanged="NavigationChanged"
  Navigation.OnSelectionChanged := TWinUINavigationViewSelectionChangedEventHandler(PublishedMethod('NavigationChanged'));
  // MainWindow.xaml(39): QuerySubmitted="SearchSubmitted"
  SearchBox.OnQuerySubmitted := TWinUIAutoSuggestBoxQuerySubmittedEventHandler(PublishedMethod('SearchSubmitted'));
  // MainWindow.xaml(39): SuggestionChosen="SearchSuggestionChosen"
  SearchBox.OnSuggestionChosen := TWinUIAutoSuggestBoxSuggestionChosenEventHandler(PublishedMethod('SearchSuggestionChosen'));
  // MainWindow.xaml(39): TextChanged="SearchChanged"
  SearchBox.OnTextChanged := TWinUIAutoSuggestBoxTextChangedEventHandler(PublishedMethod('SearchChanged'));
  // MainWindow.xaml(79): Click="CategoryClick"
  FindElement<TWinUIButton>('_rw1').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('CategoryClick'));
  // MainWindow.xaml(98): Click="CategoryClick"
  FindElement<TWinUIButton>('_rw2').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('CategoryClick'));
  // MainWindow.xaml(102): Click="CategoryClick"
  FindElement<TWinUIButton>('_rw3').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('CategoryClick'));
  // MainWindow.xaml(106): Click="CategoryClick"
  FindElement<TWinUIButton>('_rw4').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('CategoryClick'));
  // MainWindow.xaml(110): Click="CategoryClick"
  FindElement<TWinUIButton>('_rw5').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('CategoryClick'));
  // MainWindow.xaml(114): Click="CategoryClick"
  FindElement<TWinUIButton>('_rw6').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('CategoryClick'));
  // MainWindow.xaml(118): Click="CategoryClick"
  FindElement<TWinUIButton>('_rw7').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('CategoryClick'));
  // MainWindow.xaml(122): Click="CategoryClick"
  FindElement<TWinUIButton>('_rw8').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('CategoryClick'));
  // MainWindow.xaml(134): Click="GreetClick"
  FindElement<TWinUIButton>('_rw9').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('GreetClick'));
  // MainWindow.xaml(148): ValueChanged="IntensityChanged"
  IntensitySlider.OnValueChanged := TWinUIRangeBaseValueChangedEventHandler(PublishedMethod('IntensityChanged'));
  // MainWindow.xaml(161): Click="AddItemClick"
  FindElement<TWinUIButton>('_rw10').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('AddItemClick'));
  // MainWindow.xaml(162): Click="RemoveItemClick"
  FindElement<TWinUIButton>('_rw11').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RemoveItemClick'));
  // MainWindow.xaml(164): SelectionChanged="ListChanged"
  DemoList.OnSelectionChanged := TWinUISelectionChangedEventHandler(PublishedMethod('ListChanged'));
  // MainWindow.xaml(198): Click="FeedbackClick"
  FindElement<TWinUIButton>('_rw12').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('FeedbackClick'));
  // MainWindow.xaml(198): Click="FeedbackClick"
  FindElement<TWinUIButton>('_rw13').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('FeedbackClick'));
  // MainWindow.xaml(198): Click="DialogClick"
  FindElement<TWinUIButton>('_rw14').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('DialogClick'));
  // MainWindow.xaml(199): Toggled="ActivityChanged"
  ActivitySwitch.OnToggled := TWinUIRoutedEventHandler(PublishedMethod('ActivityChanged'));
  // MainWindow.xaml(227): SelectionChanged="BackdropChanged"
  BackdropChoice.OnSelectionChanged := TWinUISelectionChangedEventHandler(PublishedMethod('BackdropChanged'));
  // MainWindow.xaml(234): ColorChanged="ColorChanged"
  DemoColorPicker.OnColorChanged := TWinUIColorChangedEventHandler(PublishedMethod('ColorChanged'));
  // MainWindow.xaml(249): Click="IncrementClick"
  FindElement<TWinUIButton>('_rw15').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('IncrementClick'));
  // MainWindow.xaml(249): Click="ResetClick"
  FindElement<TWinUIButton>('_rw16').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ResetClick'));
  // MainWindow.xaml(261): TextChanged="ExplorerFilterChanged"
  ExplorerFilter.OnTextChanged := TWinUITextChangedEventHandler(PublishedMethod('ExplorerFilterChanged'));
  // MainWindow.xaml(263): SelectionChanged="ExplorerSelectionChanged"
  ExplorerList.OnSelectionChanged := TWinUISelectionChangedEventHandler(PublishedMethod('ExplorerSelectionChanged'));
  // MainWindow.xaml(275): Click="ExplorerButtonClick"
  SampleButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ExplorerButtonClick'));
  // MainWindow.xaml(277): Click="ExplorerButtonClick"
  SampleRepeatButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ExplorerButtonClick'));
  // MainWindow.xaml(279): Click="ExplorerButtonClick"
  SampleHyperlinkButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ExplorerButtonClick'));
  // MainWindow.xaml(310): Toggled="ExplorerOptionsChanged"
  ExplorerEnabled.OnToggled := TWinUIRoutedEventHandler(PublishedMethod('ExplorerOptionsChanged'));
  // MainWindow.xaml(311): SelectionChanged="ExplorerFlowChanged"
  ExplorerFlow.OnSelectionChanged := TWinUISelectionChangedEventHandler(PublishedMethod('ExplorerFlowChanged'));
  // MainWindow.xaml(314): Click="ExplorerValueClick"
  FindElement<TWinUIButton>('_rw17').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ExplorerValueClick'));
  // MainWindow.xaml(323): Click="CopyXamlClick"
  FindElement<TWinUIButton>('_rw18').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('CopyXamlClick'));
  // MainWindow.xaml(325): Click="CopyPascalClick"
  FindElement<TWinUIButton>('_rw19').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('CopyPascalClick'));
end;

procedure TMainWindowBase.SetViewModel(AValue: TMainViewModel);
begin
  FViewModel := AValue;
  DataContext := AValue;
end;

end.
