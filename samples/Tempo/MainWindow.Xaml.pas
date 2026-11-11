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
  RADWinUI.Forms;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TMainWindowBase = class(TWinUIWindow)
  protected
    AppTitleBar: TWinUITitleBar;      // MainWindow.xaml(16) <TitleBar>
    SearchBox: TWinUIAutoSuggestBox;  // MainWindow.xaml(22) <AutoSuggestBox>
    CountText: TWinUITextBlock;       // MainWindow.xaml(38) <TextBlock>
    StationList: TWinUIListView;      // MainWindow.xaml(39) <ListView>
    AddButton: TWinUIButton;          // MainWindow.xaml(53) <Button>
    StationName: TWinUITextBlock;     // MainWindow.xaml(62) <TextBlock>
    GenreText: TWinUITextBlock;       // MainWindow.xaml(64) <TextBlock>
    Progress: TWinUIProgressBar;      // MainWindow.xaml(65) <ProgressBar>
    PlayButton: TWinUIButton;         // MainWindow.xaml(67) <Button>
    QueueButton: TWinUIButton;        // MainWindow.xaml(69) <Button>
    MiniButton: TWinUIButton;         // MainWindow.xaml(70) <Button>
    FullScreenButton: TWinUIButton;   // MainWindow.xaml(71) <Button>
    Status: TWinUITextBlock;          // MainWindow.xaml(73) <TextBlock>
  public
    constructor Create; override;
  end;
  {$M-}

implementation

const
  // MainWindow.xaml(11): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' + sLineBreak +
    '    <Grid.RowDefinitions>' + sLineBreak +
    '      <RowDefinition Height="Auto" />' + sLineBreak +
    '      <RowDefinition Height="*" />' + sLineBreak +
    '    </Grid.RowDefinitions>' + sLineBreak +
    '    <TitleBar x:Name="AppTitleBar" Title="Tempo" Subtitle="Radio" IsBackButtonVisible="True" IsBackButtonEnabled="False">' + sLineBreak +
    '      <TitleBar.IconSource>' + sLineBreak +
    '        <FontIconSource Glyph="" />' + sLineBreak +
    '      </TitleBar.IconSource>' + sLineBreak +
    '      <TitleBar.Content>' + sLineBreak +
    '        <AutoSuggestBox x:Name="SearchBox" PlaceholderText="Search stations" QueryIcon="Find" Width="320" AutomationProperties.Name="Search stations" />' + sLineBreak +
    '      </TitleBar.Content>' + sLineBreak +
    '    </TitleBar>' + sLineBreak +
    '' + sLineBreak +
    '    <Grid Grid.Row="1" Padding="24,8,24,24" ColumnSpacing="24">' + sLineBreak +
    '      <Grid.ColumnDefinitions>' + sLineBreak +
    '        <ColumnDefinition Width="320" />' + sLineBreak +
    '        <ColumnDefinition Width="*" />' + sLineBreak +
    '      </Grid.ColumnDefinitions>' + sLineBreak +
    '      <Grid RowSpacing="8">' + sLineBreak +
    '        <Grid.RowDefinitions>' + sLineBreak +
    '          <RowDefinition Height="Auto" />' + sLineBreak +
    '          <RowDefinition Height="*" />' + sLineBreak +
    '          <RowDefinition Height="Auto" />' + sLineBreak +
    '        </Grid.RowDefinitions>' + sLineBreak +
    '        <TextBlock x:Name="CountText" Style="{StaticResource BodyStrongTextBlockStyle}" />' + sLineBreak +
    '        <ListView x:Name="StationList" Grid.Row="1" AutomationProperties.Name="Stations" IsItemClickEnabled="True" SelectionMode="None">' + sLineBreak +
    '          ' + sLineBreak +
    '          <ListView.ItemTemplate>' + sLineBreak +
    '            <DataTemplate>' + sLineBreak +
    '              <StackPanel Padding="0,8">' + sLineBreak +
    '                <TextBlock Text="{Binding Name}" FontWeight="SemiBold" />' + sLineBreak +
    '                <TextBlock Text="{Binding Genre}" FontSize="12" Opacity="0.7" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </DataTemplate>' + sLineBreak +
    '          </ListView.ItemTemplate>' + sLineBreak +
    '        </ListView>' + sLineBreak +
    '        <Button x:Name="AddButton" Grid.Row="2" Content="Add station..." HorizontalAlignment="Stretch" />' + sLineBreak +
    '      </Grid>' + sLineBreak +
    '' + sLineBreak +
    '      <Border Grid.Column="1" CornerRadius="12" Padding="32" BorderThickness="1" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrus' +
    'h}">' + sLineBreak +
    '        <StackPanel Spacing="16" VerticalAlignment="Center">' + sLineBreak +
    '          <FontIcon Glyph="" FontSize="64" Foreground="{ThemeResource AccentTextFillColorPrimaryBrush}" />' + sLineBreak +
    '          <TextBlock Text="NOW PLAYING" HorizontalAlignment="Center" FontSize="12" Opacity="0.6" />' + sLineBreak +
    '          <TextBlock x:Name="StationName" HorizontalAlignment="Center" Style="{StaticResource TitleTextBlockStyle}" />' + sLineBreak +
    '          <TextBlock x:Name="GenreText" HorizontalAlignment="Center" Opacity="0.7" />' + sLineBreak +
    '          <ProgressBar x:Name="Progress" Maximum="100" Width="360" />' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="8" HorizontalAlignment="Center">' + sLineBreak +
    '            <Button x:Name="PlayButton" Content="Play" Style="{StaticResource AccentButtonStyle}" MinWidth="96" />' + sLineBreak +
    '            <Button x:Name="QueueButton" Content="Queue" />' + sLineBreak +
    '            <Button x:Name="MiniButton" Content="Mini player" />' + sLineBreak +
    '            <Button x:Name="FullScreenButton" Content="Full screen" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '          <TextBlock x:Name="Status" HorizontalAlignment="Center" FontSize="12" Opacity="0.6" />' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </Border>' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '  </Grid>' + sLineBreak;

constructor TMainWindowBase.Create;
begin
  inherited;
  // MainWindow.xaml(1): <Window> attributes
  Title := 'Tempo';
  Width := 1000;
  Height := 660;
  MinWidth := 720;
  MinHeight := 460;
  Backdrop := TWinUIBackdrop.Mica;
  Center;
  LoadContent(ContentXaml);
  // x:Name elements
  AppTitleBar := FindElement<TWinUITitleBar>('AppTitleBar');
  SearchBox := FindElement<TWinUIAutoSuggestBox>('SearchBox');
  CountText := FindElement<TWinUITextBlock>('CountText');
  StationList := FindElement<TWinUIListView>('StationList');
  AddButton := FindElement<TWinUIButton>('AddButton');
  StationName := FindElement<TWinUITextBlock>('StationName');
  GenreText := FindElement<TWinUITextBlock>('GenreText');
  Progress := FindElement<TWinUIProgressBar>('Progress');
  PlayButton := FindElement<TWinUIButton>('PlayButton');
  QueueButton := FindElement<TWinUIButton>('QueueButton');
  MiniButton := FindElement<TWinUIButton>('MiniButton');
  FullScreenButton := FindElement<TWinUIButton>('FullScreenButton');
  Status := FindElement<TWinUITextBlock>('Status');
  // Event wiring
  // MainWindow.xaml(16): BackRequested="TitleBarBackRequested"
  AppTitleBar.BackRequested.Add(NotifyProc<TWinValue>('TitleBarBackRequested'));
  // MainWindow.xaml(22): TextChanged="SearchChanged"
  SearchBox.TextChanged.Add(NotifyProc<TWinUIAutoSuggestBoxTextChangedEventArgs>('SearchChanged'));
  // MainWindow.xaml(39): ItemClick="StationClick"
  StationList.OnItemClick := TWinUIItemClickEventHandler(PublishedMethod('StationClick'));
  // MainWindow.xaml(53): Click="AddClick"
  AddButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('AddClick'));
  // MainWindow.xaml(67): Click="PlayClick"
  PlayButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('PlayClick'));
  // MainWindow.xaml(69): Click="QueueClick"
  QueueButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('QueueClick'));
  // MainWindow.xaml(70): Click="MiniClick"
  MiniButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('MiniClick'));
  // MainWindow.xaml(71): Click="FullScreenClick"
  FullScreenButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('FullScreenClick'));
  // MainWindow.xaml(1): TitleBar="AppTitleBar"
  UseTitleBar(AppTitleBar);
end;

end.
