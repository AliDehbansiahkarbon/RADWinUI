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
    ThemeBox: TWinUIComboBox;      // SettingsPage.xaml(39) <ComboBox>
    LanguageBox: TWinUIComboBox;   // SettingsPage.xaml(59) <ComboBox>
    TestNoteButton: TWinUIButton;  // SettingsPage.xaml(75) <Button>
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
    '  <Page.Resources>' + sLineBreak +
    '    <Style x:Key="Row" TargetType="Border">' + sLineBreak +
    '      <Setter Property="Background" Value="{ThemeResource CardBackgroundFillColorDefaultBrush}" />' + sLineBreak +
    '      <Setter Property="BorderBrush" Value="{ThemeResource CardStrokeColorDefaultBrush}" />' + sLineBreak +
    '      <Setter Property="BorderThickness" Value="1" />' + sLineBreak +
    '      <Setter Property="CornerRadius" Value="12" />' + sLineBreak +
    '      <Setter Property="Padding" Value="20,14" />' + sLineBreak +
    '    </Style>' + sLineBreak +
    '    <Style x:Key="RowIcon" TargetType="FontIcon">' + sLineBreak +
    '      <Setter Property="FontSize" Value="20" />' + sLineBreak +
    '      <Setter Property="Foreground" Value="#F0652B" />' + sLineBreak +
    '      <Setter Property="VerticalAlignment" Value="Center" />' + sLineBreak +
    '    </Style>' + sLineBreak +
    '  </Page.Resources>' + sLineBreak +
    '' + sLineBreak +
    '  <ScrollViewer>' + sLineBreak +
    '    <StackPanel Spacing="8" MaxWidth="820" HorizontalAlignment="Left" Padding="0,4,0,0">' + sLineBreak +
    '      <TextBlock x:Uid="SettingsTitle" Text="Settings" FontSize="32" FontWeight="SemiBold" Margin="0,0,0,12" />' + sLineBreak +
    '' + sLineBreak +
    '      <Border Style="{StaticResource Row}">' + sLineBreak +
    '        <Grid ColumnSpacing="16">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <FontIcon Style="{StaticResource RowIcon}" Glyph="" />' + sLineBreak +
    '          <StackPanel Grid.Column="1" VerticalAlignment="Center">' + sLineBreak +
    '            <TextBlock x:Uid="ThemeTitle" Text="Theme" FontWeight="SemiBold" />' + sLineBreak +
    '            <TextBlock x:Uid="ThemeText" Text="Light, dark, or the same as Windows" FontSize="12" Opacity="0.7" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '          <ComboBox x:Name="ThemeBox" Grid.Column="2" Width="200" AutomationProperties.Name="Theme">' + sLineBreak +
    '            <ComboBoxItem x:Uid="ThemeSystem" Content="Windows default" />' + sLineBreak +
    '            <ComboBoxItem x:Uid="ThemeLight" Content="Light" />' + sLineBreak +
    '            <ComboBoxItem x:Uid="ThemeDark" Content="Dark" />' + sLineBreak +
    '          </ComboBox>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </Border>' + sLineBreak +
    '' + sLineBreak +
    '      <Border Style="{StaticResource Row}">' + sLineBreak +
    '        <Grid ColumnSpacing="16">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <FontIcon Style="{StaticResource RowIcon}" Glyph="" />' + sLineBreak +
    '          <StackPanel Grid.Column="1" VerticalAlignment="Center">' + sLineBreak +
    '            <TextBlock x:Uid="LanguageTitle" Text="Language" FontWeight="SemiBold" />' + sLineBreak +
    '            <TextBlock x:Uid="LanguageText" Text="Ember starts again in the new language" FontSize="12" Opacity="0.7" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '          <ComboBox x:Name="LanguageBox" Grid.Column="2" Width="200" AutomationProperties.Name="Language" />' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </Border>' + sLineBreak +
    '' + sLineBreak +
    '      <Border Style="{StaticResource Row}">' + sLineBreak +
    '        <Grid ColumnSpacing="16">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <FontIcon Style="{StaticResource RowIcon}" Glyph="" />' + sLineBreak +
    '          <StackPanel Grid.Column="1" VerticalAlignment="Center">' + sLineBreak +
    '            <TextBlock x:Uid="NotifyTitle" Text="Notifications" FontWeight="SemiBold" />' + sLineBreak +
    '            <TextBlock x:Uid="NotifyText" Text="Windows tells you when a batch is ready" FontSize="12" Opacity="0.7" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '          <Button x:Name="TestNoteButton" x:Uid="TestNoteButton" Grid.Column="2" Content="Send a test" />' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </Border>' + sLineBreak +
    '' + sLineBreak +
    '      <Border Style="{StaticResource Row}" Margin="0,16,0,0">' + sLineBreak +
    '        <StackPanel Spacing="6">' + sLineBreak +
    '          <TextBlock x:Uid="AboutTitle" Text="About Ember" FontWeight="SemiBold" />' + sLineBreak +
    '          <TextBlock x:Uid="AboutText" TextWrapping="Wrap" Opacity="0.8" Text="Ember is a RADWinUI sample: a native WinUI 3 app written in Delphi. Its pages are XAML files with Object Pascal units, it' +
    's data is FireDAC, and it ships as a plain Win64 program." />' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </Border>' + sLineBreak +
    '    </StackPanel>' + sLineBreak +
    '  </ScrollViewer>' + sLineBreak +
    '</Page>';
  {$IFDEF DEBUG}
  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild
  XamlShape = 'F:ThemeBox:TWinUIComboBox;F:LanguageBox:TWinUIComboBox;F:TestNoteButton:TWinUIButton;E:LanguageBox.SelectionChanged=LanguageChanged;E:TestNoteButton.Click=TestNoteClick;E:ThemeBox.SelectionChanged=The' +
    'meChanged';
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
  ThemeBox := FindElement<TWinUIComboBox>('ThemeBox');
  LanguageBox := FindElement<TWinUIComboBox>('LanguageBox');
  TestNoteButton := FindElement<TWinUIButton>('TestNoteButton');
  // Event wiring
  // SettingsPage.xaml(39): SelectionChanged="ThemeChanged"
  ThemeBox.OnSelectionChanged := TWinUISelectionChangedEventHandler(PublishedMethod('ThemeChanged'));
  // SettingsPage.xaml(59): SelectionChanged="LanguageChanged"
  LanguageBox.OnSelectionChanged := TWinUISelectionChangedEventHandler(PublishedMethod('LanguageChanged'));
  // SettingsPage.xaml(75): Click="TestNoteClick"
  TestNoteButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('TestNoteClick'));
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
