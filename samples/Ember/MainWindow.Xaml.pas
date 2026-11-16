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
  RADWinUI.Pages,
  RADWinUI.Forms;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TMainWindowBase = class(TWinUIWindow)
  protected
    Root: TWinUIGrid;                  // MainWindow.xaml(13) <Grid>
    AppTitleBar: TWinUITitleBar;       // MainWindow.xaml(58) <TitleBar>
    SearchBox: TWinUIAutoSuggestBox;   // MainWindow.xaml(64) <AutoSuggestBox>
    Nav: TWinUINavigationView;         // MainWindow.xaml(79) <NavigationView>
    RoastBadge: TWinUIButton;          // MainWindow.xaml(95) <Button>
    BadgeGlow: TWinUIEllipse;          // MainWindow.xaml(103) <Ellipse>
    BadgeTitle: TWinUITextBlock;       // MainWindow.xaml(107) <TextBlock>
    BadgeText: TWinUITextBlock;        // MainWindow.xaml(108) <TextBlock>
    BadgeProgress: TWinUIProgressBar;  // MainWindow.xaml(109) <ProgressBar>
    ContentFrame: TWinUIPageFrame;     // MainWindow.xaml(115) <Frame>
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
  // MainWindow.xaml(13): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="Root">' + sLineBreak +
    '    ' + sLineBreak +
    '    <Grid.Resources>' + sLineBreak +
    '      <ResourceDictionary>' + sLineBreak +
    '        <ResourceDictionary.ThemeDictionaries>' + sLineBreak +
    '          <ResourceDictionary x:Key="Light">' + sLineBreak +
    '            <Color x:Key="SystemAccentColor">#E2572A</Color>' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentFillColorDefaultBrush" Color="#D9532A" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentFillColorSecondaryBrush" Color="#E6D9532A" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentFillColorTertiaryBrush" Color="#CCD9532A" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentTextFillColorPrimaryBrush" Color="#B8431F" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentTextFillColorSecondaryBrush" Color="#A33A1A" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentTextFillColorTertiaryBrush" Color="#C24A22" />' + sLineBreak +
    '            <SolidColorBrush x:Key="NavigationViewSelectionIndicatorForeground" Color="#E2572A" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentButtonBackground" Color="#D9532A" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentButtonBackgroundPointerOver" Color="#E2643A" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentButtonBackgroundPressed" Color="#C24A22" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentButtonForeground" Color="White" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentButtonForegroundPointerOver" Color="White" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentButtonForegroundPressed" Color="White" />' + sLineBreak +
    '          </ResourceDictionary>' + sLineBreak +
    '          <ResourceDictionary x:Key="Dark">' + sLineBreak +
    '            <Color x:Key="SystemAccentColor">#FF8A4C</Color>' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentFillColorDefaultBrush" Color="#FF8A4C" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentFillColorSecondaryBrush" Color="#E6FF8A4C" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentFillColorTertiaryBrush" Color="#CCFF8A4C" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentTextFillColorPrimaryBrush" Color="#FFB07A" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentTextFillColorSecondaryBrush" Color="#FFC29A" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentTextFillColorTertiaryBrush" Color="#FF9E66" />' + sLineBreak +
    '            <SolidColorBrush x:Key="NavigationViewSelectionIndicatorForeground" Color="#FF8A4C" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentButtonBackground" Color="#FF8A4C" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentButtonBackgroundPointerOver" Color="#FF9A62" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentButtonBackgroundPressed" Color="#E8773C" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentButtonForeground" Color="#1A0F0A" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentButtonForegroundPointerOver" Color="#1A0F0A" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AccentButtonForegroundPressed" Color="#1A0F0A" />' + sLineBreak +
    '          </ResourceDictionary>' + sLineBreak +
    '        </ResourceDictionary.ThemeDictionaries>' + sLineBreak +
    '      </ResourceDictionary>' + sLineBreak +
    '    </Grid.Resources>' + sLineBreak +
    '    <Grid.RowDefinitions>' + sLineBreak +
    '      <RowDefinition Height="Auto" />' + sLineBreak +
    '      <RowDefinition Height="*" />' + sLineBreak +
    '    </Grid.RowDefinitions>' + sLineBreak +
    '' + sLineBreak +
    '    <TitleBar x:Name="AppTitleBar" Title="Ember" x:Uid="AppTitleBar" Subtitle="Roastery">' + sLineBreak +
    '      <TitleBar.IconSource>' + sLineBreak +
    '        <FontIconSource Glyph="" Foreground="#FF7A3D" />' + sLineBreak +
    '      </TitleBar.IconSource>' + sLineBreak +
    '      <TitleBar.Content>' + sLineBreak +
    '        ' + sLineBreak +
    '        <AutoSuggestBox x:Name="SearchBox" x:Uid="SearchBox" PlaceholderText="Search orders, cafes or coffees" QueryIcon="Find" Width="380" AutomationProperties.Name="Search">' + sLineBreak +
    '          <AutoSuggestBox.ItemTemplate>' + sLineBreak +
    '            <DataTemplate>' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="10">' + sLineBreak +
    '                <FontIcon Glyph="{Binding Glyph}" FontSize="14" Foreground="#F0652B" />' + sLineBreak +
    '                <TextBlock Text="{Binding Name}" />' + sLineBreak +
    '                <TextBlock Text="{Binding Kind}" Opacity="0.6" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </DataTemplate>' + sLineBreak +
    '          </AutoSuggestBox.ItemTemplate>' + sLineBreak +
    '        </AutoSuggestBox>' + sLineBreak +
    '      </TitleBar.Content>' + sLineBreak +
    '    </TitleBar>' + sLineBreak +
    '' + sLineBreak +
    '    <NavigationView x:Name="Nav" Grid.Row="1" PaneDisplayMode="Left" IsBackButtonVisible="Visible" OpenPaneLength="240" IsSettingsVisible="True">' + sLineBreak +
    '      <NavigationView.MenuItems>' + sLineBreak +
    '        <NavigationViewItem x:Uid="NavDashboard" Content="Dashboard" Tag="THomePage">' + sLineBreak +
    '          <NavigationViewItem.Icon><FontIcon Glyph="" /></NavigationViewItem.Icon>' + sLineBreak +
    '        </NavigationViewItem>' + sLineBreak +
    '        <NavigationViewItem x:Uid="NavOrders" Content="Orders" Tag="TOrdersPage">' + sLineBreak +
    '          <NavigationViewItem.Icon><FontIcon Glyph="" /></NavigationViewItem.Icon>' + sLineBreak +
    '        </NavigationViewItem>' + sLineBreak +
    '        <NavigationViewItem x:Uid="NavRoastery" Content="Roastery" Tag="TRoastPage">' + sLineBreak +
    '          <NavigationViewItem.Icon><FontIcon Glyph="" /></NavigationViewItem.Icon>' + sLineBreak +
    '        </NavigationViewItem>' + sLineBreak +
    '      </NavigationView.MenuItems>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <NavigationView.PaneFooter>' + sLineBreak +
    '        <Button x:Name="RoastBadge" Margin="12,0,12,12" Padding="14,12" HorizontalAlignment="Stretch" HorizontalContentAlignment="Stretch" CornerRadius="12" AutomationProperties.Name="Current roast">' + sLineBreak +
    '          <Grid ColumnSpacing="12">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <Grid Width="36" Height="36">' + sLineBreak +
    '              <Ellipse x:Name="BadgeGlow" Fill="#33FF7A3D" />' + sLineBreak +
    '              <FontIcon Glyph="" FontSize="18" Foreground="#FF7A3D" />' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '            <StackPanel Grid.Column="1" Spacing="2">' + sLineBreak +
    '              <TextBlock x:Name="BadgeTitle" x:Uid="BadgeTitle" Text="Roaster idle" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" />' + sLineBreak +
    '              <TextBlock x:Name="BadgeText" x:Uid="BadgeText" Text="Ready for the next batch" FontSize="12" Opacity="0.7" TextTrimming="CharacterEllipsis" />' + sLineBreak +
    '              <ProgressBar x:Name="BadgeProgress" Maximum="660" Value="0" Margin="0,6,0,0" Foreground="#FF7A3D" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '        </Button>' + sLineBreak +
    '      </NavigationView.PaneFooter>' + sLineBreak +
    '' + sLineBreak +
    '      <Frame x:Name="ContentFrame" Padding="32,12,32,24" />' + sLineBreak +
    '    </NavigationView>' + sLineBreak +
    '  </Grid>' + sLineBreak;
  {$IFDEF DEBUG}
  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild
  XamlShape = 'F:Root:TWinUIGrid;F:AppTitleBar:TWinUITitleBar;F:SearchBox:TWinUIAutoSuggestBox;F:Nav:TWinUINavigationView;F:RoastBadge:TWinUIButton;F:BadgeGlow:TWinUIEllipse;F:BadgeTitle:TWinUITextBlock;F:BadgeText:' +
    'TWinUITextBlock;F:BadgeProgress:TWinUIProgressBar;F:ContentFrame:TWinUIPageFrame;E:RoastBadge.Click=RoastBadgeClick;E:SearchBox.QuerySubmitted=SearchSubmitted;E:SearchBox.TextChanged=SearchTextChanged';
  {$ENDIF}

constructor TMainWindowBase.Create;
begin
  inherited;
  // MainWindow.xaml(1): <Window> attributes
  Title := 'Ember';
  Width := 1320;
  Height := 840;
  MinWidth := 1040;
  MinHeight := 700;
  Backdrop := TWinUIBackdrop.Mica;
  Center;
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
  Root := FindElement<TWinUIGrid>('Root');
  AppTitleBar := FindElement<TWinUITitleBar>('AppTitleBar');
  SearchBox := FindElement<TWinUIAutoSuggestBox>('SearchBox');
  Nav := FindElement<TWinUINavigationView>('Nav');
  RoastBadge := FindElement<TWinUIButton>('RoastBadge');
  BadgeGlow := FindElement<TWinUIEllipse>('BadgeGlow');
  BadgeTitle := FindElement<TWinUITextBlock>('BadgeTitle');
  BadgeText := FindElement<TWinUITextBlock>('BadgeText');
  BadgeProgress := FindElement<TWinUIProgressBar>('BadgeProgress');
  ContentFrame := FindElement<TWinUIPageFrame>('ContentFrame');
  // Event wiring
  // MainWindow.xaml(64): QuerySubmitted="SearchSubmitted"
  SearchBox.OnQuerySubmitted := TWinUIAutoSuggestBoxQuerySubmittedEventHandler(PublishedMethod('SearchSubmitted'));
  // MainWindow.xaml(64): TextChanged="SearchTextChanged"
  SearchBox.OnTextChanged := TWinUIAutoSuggestBoxTextChangedEventHandler(PublishedMethod('SearchTextChanged'));
  // MainWindow.xaml(95): Click="RoastBadgeClick"
  RoastBadge.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RoastBadgeClick'));
  // MainWindow.xaml(1): TitleBar="AppTitleBar"
  UseTitleBar(AppTitleBar);
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
