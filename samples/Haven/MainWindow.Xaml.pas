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
    Surface: TWinUIGrid;                 // MainWindow.xaml(12) <Grid>
    DragRegion: TWinUIGrid;              // MainWindow.xaml(74) <Grid>
    WelcomeText: TWinUITextBlock;        // MainWindow.xaml(128) <TextBlock>
    TotalLabel: TWinUITextBlock;         // MainWindow.xaml(231) <TextBlock>
    AddMoneyButton: TWinUIButton;        // MainWindow.xaml(246) <Button>
    WeekLabel: TWinUITextBlock;          // MainWindow.xaml(251) <TextBlock>
    CountdownLabel: TWinUITextBlock;     // MainWindow.xaml(320) <TextBlock>
    PlayButton: TWinUIButton;            // MainWindow.xaml(327) <Button>
    PauseButton: TWinUIButton;           // MainWindow.xaml(331) <Button>
    RulesExpander: TWinUIExpander;       // MainWindow.xaml(383) <Expander>
    AutoSaveLabel: TWinUITextBlock;      // MainWindow.xaml(388) <TextBlock>
    RoundUpsSwitch: TWinUIToggleSwitch;  // MainWindow.xaml(394) <ToggleSwitch>
    PaydaySwitch: TWinUIToggleSwitch;    // MainWindow.xaml(395) <ToggleSwitch>
    SweepSwitch: TWinUIToggleSwitch;     // MainWindow.xaml(396) <ToggleSwitch>
    GoalCaptionLabel: TWinUITextBlock;   // MainWindow.xaml(540) <TextBlock>
    GoalList: TWinUIListView;            // MainWindow.xaml(543) <ListView>
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
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="Surface">' + sLineBreak +
    '    <Grid.Resources>' + sLineBreak +
    '      <ResourceDictionary>' + sLineBreak +
    '        <ResourceDictionary.ThemeDictionaries>' + sLineBreak +
    '          <ResourceDictionary x:Key="Light">' + sLineBreak +
    '            <LinearGradientBrush x:Key="HavenBackground" StartPoint="0,0" EndPoint="1,1">' + sLineBreak +
    '              <GradientStop Color="#DCDFE5" Offset="0" />' + sLineBreak +
    '              <GradientStop Color="#EEECE6" Offset="0.55" />' + sLineBreak +
    '              <GradientStop Color="#F7EFD2" Offset="1" />' + sLineBreak +
    '            </LinearGradientBrush>' + sLineBreak +
    '            <SolidColorBrush x:Key="PanelBrush" Color="#66FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="CardBrush" Color="#C7FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="InkBrush" Color="#1E1E1E" />' + sLineBreak +
    '            <SolidColorBrush x:Key="OnInkBrush" Color="#FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="OnInkMutedBrush" Color="#99FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="OnInkFaintBrush" Color="#26FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="FaintBrush" Color="#1F000000" />' + sLineBreak +
    '            <SolidColorBrush x:Key="LineBrush" Color="#24000000" />' + sLineBreak +
    '          </ResourceDictionary>' + sLineBreak +
    '          <ResourceDictionary x:Key="Dark">' + sLineBreak +
    '            <LinearGradientBrush x:Key="HavenBackground" StartPoint="0,0" EndPoint="1,1">' + sLineBreak +
    '              <GradientStop Color="#16181C" Offset="0" />' + sLineBreak +
    '              <GradientStop Color="#1E1F22" Offset="0.55" />' + sLineBreak +
    '              <GradientStop Color="{ThemeResource SystemAccentColorDark3}" Offset="1.6" />' + sLineBreak +
    '            </LinearGradientBrush>' + sLineBreak +
    '            <SolidColorBrush x:Key="PanelBrush" Color="#14FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="CardBrush" Color="#E62B2C30" />' + sLineBreak +
    '            <SolidColorBrush x:Key="InkBrush" Color="#F2F2F2" />' + sLineBreak +
    '            <SolidColorBrush x:Key="OnInkBrush" Color="#1E1E1E" />' + sLineBreak +
    '            <SolidColorBrush x:Key="OnInkMutedBrush" Color="#99000000" />' + sLineBreak +
    '            <SolidColorBrush x:Key="OnInkFaintBrush" Color="#1A000000" />' + sLineBreak +
    '            <SolidColorBrush x:Key="FaintBrush" Color="#2EFFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="LineBrush" Color="#2EFFFFFF" />' + sLineBreak +
    '          </ResourceDictionary>' + sLineBreak +
    '        </ResourceDictionary.ThemeDictionaries>' + sLineBreak +
    '        <Style x:Key="Card" TargetType="Border">' + sLineBreak +
    '          <Setter Property="Background" Value="{ThemeResource CardBrush}" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="24" />' + sLineBreak +
    '          <Setter Property="Padding" Value="22,20" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="NavButton" TargetType="Button">' + sLineBreak +
    '          <Setter Property="Padding" Value="14,8" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="18" />' + sLineBreak +
    '          <Setter Property="Background" Value="Transparent" />' + sLineBreak +
    '          <Setter Property="BorderThickness" Value="0" />' + sLineBreak +
    '          <Setter Property="FontSize" Value="13" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="RoundButton" TargetType="Button">' + sLineBreak +
    '          <Setter Property="Width" Value="38" />' + sLineBreak +
    '          <Setter Property="Height" Value="38" />' + sLineBreak +
    '          <Setter Property="Padding" Value="0" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="19" />' + sLineBreak +
    '          <Setter Property="Background" Value="{ThemeResource CardBrush}" />' + sLineBreak +
    '          <Setter Property="BorderThickness" Value="0" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '      </ResourceDictionary>' + sLineBreak +
    '    </Grid.Resources>' + sLineBreak +
    '    <Grid.RowDefinitions>' + sLineBreak +
    '      <RowDefinition Height="32" />' + sLineBreak +
    '      <RowDefinition Height="*" />' + sLineBreak +
    '    </Grid.RowDefinitions>' + sLineBreak +
    '    <Border Grid.RowSpan="2" Background="{ThemeResource HavenBackground}" />' + sLineBreak +
    '    <Grid x:Name="DragRegion" Background="Transparent" />' + sLineBreak +
    '' + sLineBreak +
    '    <Border Grid.Row="1" Margin="24,0,24,24" CornerRadius="32" Background="{ThemeResource PanelBrush}">' + sLineBreak +
    '      <ScrollViewer HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto">' + sLineBreak +
    '        <Grid MinWidth="1180" Padding="28,24,28,28" RowSpacing="20">' + sLineBreak +
    '          <Grid.RowDefinitions>' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '          </Grid.RowDefinitions>' + sLineBreak +
    '' + sLineBreak +
    '          ' + sLineBreak +
    '          <Grid ColumnSpacing="10">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <Border HorizontalAlignment="Left" CornerRadius="22" Padding="18,7" BorderThickness="1" BorderBrush="{ThemeResource InkBrush}">' + sLineBreak +
    '              <TextBlock Text="Haven" FontSize="20" FontFamily="Segoe UI Variable Display" FontWeight="SemiLight" />' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <Border Grid.Column="1" CornerRadius="22" Padding="4" Background="{ThemeResource CardBrush}">' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="2">' + sLineBreak +
    '                <Button Style="{StaticResource NavButton}" Content="Dashboard" Background="{ThemeResource InkBrush}" Foreground="{ThemeResource OnInkBrush}" />' + sLineBreak +
    '                <Button Style="{StaticResource NavButton}" Content="Goals" />' + sLineBreak +
    '                <Button Style="{StaticResource NavButton}" Content="Activity" />' + sLineBreak +
    '                <Button Style="{StaticResource NavButton}" Content="Cards" />' + sLineBreak +
    '                <Button Style="{StaticResource NavButton}" Content="Budget" />' + sLineBreak +
    '                <Button Style="{StaticResource NavButton}" Content="Reports" />' + sLineBreak +
    '                <Button Style="{StaticResource NavButton}" Content="Calendar" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <Button Grid.Column="2" CornerRadius="19" Height="38" Padding="14,0" BorderThickness="0" Background="{ThemeResource CardBrush}">' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="14" />' + sLineBreak +
    '                <TextBlock Text="Settings" FontSize="13" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Button>' + sLineBreak +
    '            <Grid Grid.Column="3">' + sLineBreak +
    '              <Button Style="{StaticResource RoundButton}" ToolTipService.ToolTip="Notifications" AutomationProperties.Name="Notifications">' + sLineBreak +
    '                <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="15" />' + sLineBreak +
    '              </Button>' + sLineBreak +
    '              <Ellipse Width="8" Height="8" Fill="{ThemeResource AccentFillColorDefaultBrush}" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,6,7,0" IsHitTestVisible="False" />' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '            <Button Grid.Column="4" Style="{StaticResource RoundButton}" ToolTipService.ToolTip="Profile" AutomationProperties.Name="Profile">' + sLineBreak +
    '              <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="15" />' + sLineBreak +
    '            </Button>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '' + sLineBreak +
    '          <TextBlock Grid.Row="1" x:Name="WelcomeText" Text="Welcome in, Alex" FontSize="44" FontFamily="Segoe UI Variable Display" FontWeight="Light" />' + sLineBreak +
    '' + sLineBreak +
    '          ' + sLineBreak +
    '          <Grid Grid.Row="2" ColumnSpacing="40">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <Grid ColumnSpacing="6" RowSpacing="6" VerticalAlignment="Bottom">' + sLineBreak +
    '              <Grid.ColumnDefinitions>' + sLineBreak +
    '                <ColumnDefinition Width="15*" />' + sLineBreak +
    '                <ColumnDefinition Width="15*" />' + sLineBreak +
    '                <ColumnDefinition Width="60*" />' + sLineBreak +
    '                <ColumnDefinition Width="12*" />' + sLineBreak +
    '              </Grid.ColumnDefinitions>' + sLineBreak +
    '              <Grid.RowDefinitions>' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="38" />' + sLineBreak +
    '              </Grid.RowDefinitions>' + sLineBreak +
    '              <TextBlock Text="Saved" FontSize="12" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '              <TextBlock Grid.Column="1" Text="Invested" FontSize="12" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '              <TextBlock Grid.Column="2" Text="Planned" FontSize="12" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '              <TextBlock Grid.Column="3" Text="Spent" FontSize="12" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '              <Border Grid.Row="1" CornerRadius="19" Padding="14,0" Background="{ThemeResource InkBrush}">' + sLineBreak +
    '                <TextBlock Text="15%" FontSize="11" VerticalAlignment="Center" Foreground="{ThemeResource OnInkBrush}" />' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Grid.Row="1" Grid.Column="1" CornerRadius="19" Padding="14,0" Background="{ThemeResource AccentFillColorDefaultBrush}">' + sLineBreak +
    '                <TextBlock Text="15%" FontSize="11" VerticalAlignment="Center" Foreground="{ThemeResource TextOnAccentFillColorPrimaryBrush}" />' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Grid.Row="1" Grid.Column="2" CornerRadius="19" Padding="14,0">' + sLineBreak +
    '                <Border.Background>' + sLineBreak +
    '                  <LinearGradientBrush MappingMode="Absolute" StartPoint="0,0" EndPoint="7,7" SpreadMethod="Repeat">' + sLineBreak +
    '                    <GradientStop Color="#00000000" Offset="0" />' + sLineBreak +
    '                    <GradientStop Color="#00000000" Offset="0.55" />' + sLineBreak +
    '                    <GradientStop Color="{ThemeResource TextFillColorTertiary}" Offset="0.55" />' + sLineBreak +
    '                    <GradientStop Color="{ThemeResource TextFillColorTertiary}" Offset="1" />' + sLineBreak +
    '                  </LinearGradientBrush>' + sLineBreak +
    '                </Border.Background>' + sLineBreak +
    '                <Border HorizontalAlignment="Left" VerticalAlignment="Center" CornerRadius="9" Padding="6,1" Background="{ThemeResource CardBrush}">' + sLineBreak +
    '                  <TextBlock Text="60%" FontSize="11" />' + sLineBreak +
    '                </Border>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Grid.Row="1" Grid.Column="3" CornerRadius="19" Padding="14,0" BorderThickness="1" BorderBrush="{ThemeResource TextFillColorSecondaryBrush}">' + sLineBreak +
    '                <TextBlock Text="10%" FontSize="11" VerticalAlignment="Center" />' + sLineBreak +
    '              </Border>' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '            <StackPanel Grid.Column="1" Orientation="Horizontal" Spacing="36">' + sLineBreak +
    '              <StackPanel>' + sLineBreak +
    '                <TextBlock Text="5" FontSize="56" FontFamily="Segoe UI Variable Display" FontWeight="Light" HorizontalAlignment="Right" />' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="6" HorizontalAlignment="Right">' + sLineBreak +
    '                  <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="11" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                  <TextBlock Text="Goals" FontSize="12" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <StackPanel>' + sLineBreak +
    '                <TextBlock Text="56" FontSize="56" FontFamily="Segoe UI Variable Display" FontWeight="Light" HorizontalAlignment="Right" />' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="6" HorizontalAlignment="Right">' + sLineBreak +
    '                  <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="11" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                  <TextBlock Text="Deposits" FontSize="12" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <StackPanel>' + sLineBreak +
    '                <TextBlock Text="203" FontSize="56" FontFamily="Segoe UI Variable Display" FontWeight="Light" HorizontalAlignment="Right" />' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="6" HorizontalAlignment="Right">' + sLineBreak +
    '                  <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="11" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                  <TextBlock Text="Day streak" FontSize="12" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '' + sLineBreak +
    '          ' + sLineBreak +
    '          <Grid Grid.Row="3" ColumnSpacing="16" RowSpacing="16">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <Grid.RowDefinitions>' + sLineBreak +
    '              <RowDefinition Height="270" />' + sLineBreak +
    '              <RowDefinition Height="300" />' + sLineBreak +
    '            </Grid.RowDefinitions>' + sLineBreak +
    '' + sLineBreak +
    '            ' + sLineBreak +
    '            <Border CornerRadius="24" Padding="20">' + sLineBreak +
    '              <Border.Background>' + sLineBreak +
    '                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">' + sLineBreak +
    '                  <GradientStop Color="{ThemeResource SystemAccentColorLight2}" Offset="0" />' + sLineBreak +
    '                  <GradientStop Color="{ThemeResource SystemAccentColor}" Offset="0.7" />' + sLineBreak +
    '                  <GradientStop Color="{ThemeResource SystemAccentColorDark1}" Offset="1" />' + sLineBreak +
    '                </LinearGradientBrush>' + sLineBreak +
    '              </Border.Background>' + sLineBreak +
    '              <Grid>' + sLineBreak +
    '                <PersonPicture DisplayName="Alex Morgan" Width="112" Height="112" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,0,0,40" />' + sLineBreak +
    '                <Grid VerticalAlignment="Bottom">' + sLineBreak +
    '                  <StackPanel>' + sLineBreak +
    '                    <TextBlock Text="Alex Morgan" FontSize="18" Foreground="{ThemeResource TextOnAccentFillColorPrimaryBrush}" />' + sLineBreak +
    '                    <TextBlock Text="Personal saver" FontSize="11" Foreground="{ThemeResource TextOnAccentFillColorSecondaryBrush}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <Border HorizontalAlignment="Right" VerticalAlignment="Center" CornerRadius="18" Padding="14,6" BorderThickness="1" BorderBrush="{ThemeResource TextOnAccentFillColorPrimaryBrush}" Ba' +
    'ckground="#26FFFFFF">' + sLineBreak +
    '                    <TextBlock x:Name="TotalLabel" Text="{Binding TotalText}" FontSize="13" Foreground="{ThemeResource TextOnAccentFillColorPrimaryBrush}" />' + sLineBreak +
    '                  </Border>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '' + sLineBreak +
    '            ' + sLineBreak +
    '            <Border Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '              <Grid RowSpacing="8">' + sLineBreak +
    '                <Grid.RowDefinitions>' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                  <RowDefinition Height="*" />' + sLineBreak +
    '                </Grid.RowDefinitions>' + sLineBreak +
    '                <TextBlock Text="Progress" FontSize="18" />' + sLineBreak +
    '                <Button x:Name="AddMoneyButton" Style="{StaticResource RoundButton}" HorizontalAlignment="Right" Background="{ThemeResource PanelBrush}" ToolTipService.ToolTip="Add $50 today" Automati' +
    'onProperties.Name="Add money">' + sLineBreak +
    '                  <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="12" />' + sLineBreak +
    '                </Button>' + sLineBreak +
    '                <StackPanel Grid.Row="1" Orientation="Horizontal" Spacing="10">' + sLineBreak +
    '                  <TextBlock x:Name="WeekLabel" Text="{Binding WeekText}" FontSize="34" FontFamily="Segoe UI Variable Display" FontWeight="Light" />' + sLineBreak +
    '                  <TextBlock Text="Saved&#10;this week" FontSize="11" VerticalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <Grid Grid.Row="2" ColumnSpacing="6">' + sLineBreak +
    '                  <Grid.ColumnDefinitions>' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                  </Grid.ColumnDefinitions>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Bottom" Spacing="5">' + sLineBreak +
    '                    <Rectangle Width="6" Height="{Binding Day1}" RadiusX="3" RadiusY="3" Fill="{ThemeResource FaintBrush}" />' + sLineBreak +
    '                    <Ellipse Width="6" Height="6" Fill="{ThemeResource FaintBrush}" />' + sLineBreak +
    '                    <TextBlock Text="S" FontSize="11" HorizontalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <StackPanel Grid.Column="1" VerticalAlignment="Bottom" Spacing="5">' + sLineBreak +
    '                    <Rectangle Width="6" Height="{Binding Day2}" RadiusX="3" RadiusY="3" Fill="{ThemeResource InkBrush}" />' + sLineBreak +
    '                    <Ellipse Width="6" Height="6" Fill="{ThemeResource InkBrush}" />' + sLineBreak +
    '                    <TextBlock Text="M" FontSize="11" HorizontalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <StackPanel Grid.Column="2" VerticalAlignment="Bottom" Spacing="5">' + sLineBreak +
    '                    <Rectangle Width="6" Height="{Binding Day3}" RadiusX="3" RadiusY="3" Fill="{ThemeResource InkBrush}" />' + sLineBreak +
    '                    <Ellipse Width="6" Height="6" Fill="{ThemeResource InkBrush}" />' + sLineBreak +
    '                    <TextBlock Text="T" FontSize="11" HorizontalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <StackPanel Grid.Column="3" VerticalAlignment="Bottom" Spacing="5">' + sLineBreak +
    '                    <Rectangle Width="6" Height="{Binding Day4}" RadiusX="3" RadiusY="3" Fill="{ThemeResource InkBrush}" />' + sLineBreak +
    '                    <Ellipse Width="6" Height="6" Fill="{ThemeResource InkBrush}" />' + sLineBreak +
    '                    <TextBlock Text="W" FontSize="11" HorizontalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <StackPanel Grid.Column="4" VerticalAlignment="Bottom" Spacing="5">' + sLineBreak +
    '                    <Rectangle Width="6" Height="{Binding Day5}" RadiusX="3" RadiusY="3" Fill="{ThemeResource InkBrush}" />' + sLineBreak +
    '                    <Ellipse Width="6" Height="6" Fill="{ThemeResource InkBrush}" />' + sLineBreak +
    '                    <TextBlock Text="T" FontSize="11" HorizontalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <StackPanel Grid.Column="5" VerticalAlignment="Bottom" Spacing="5">' + sLineBreak +
    '                    <Border CornerRadius="9" Padding="6,2" HorizontalAlignment="Center" Background="{ThemeResource AccentFillColorDefaultBrush}">' + sLineBreak +
    '                      <TextBlock Text="Today" FontSize="10" Foreground="{ThemeResource TextOnAccentFillColorPrimaryBrush}" />' + sLineBreak +
    '                    </Border>' + sLineBreak +
    '                    <Rectangle Width="6" Height="{Binding Day6}" RadiusX="3" RadiusY="3" Fill="{ThemeResource AccentFillColorDefaultBrush}" />' + sLineBreak +
    '                    <Ellipse Width="6" Height="6" Fill="{ThemeResource AccentFillColorDefaultBrush}" />' + sLineBreak +
    '                    <TextBlock Text="F" FontSize="11" HorizontalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <StackPanel Grid.Column="6" VerticalAlignment="Bottom" Spacing="5">' + sLineBreak +
    '                    <Rectangle Width="6" Height="{Binding Day7}" RadiusX="3" RadiusY="3" Fill="{ThemeResource FaintBrush}" />' + sLineBreak +
    '                    <Ellipse Width="6" Height="6" Fill="{ThemeResource FaintBrush}" />' + sLineBreak +
    '                    <TextBlock Text="S" FontSize="11" HorizontalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '' + sLineBreak +
    '            ' + sLineBreak +
    '            <Border Grid.Column="2" Style="{StaticResource Card}">' + sLineBreak +
    '              <Grid RowSpacing="6">' + sLineBreak +
    '                <Grid.RowDefinitions>' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                  <RowDefinition Height="*" />' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                </Grid.RowDefinitions>' + sLineBreak +
    '                <TextBlock Text="Next auto-save" FontSize="18" />' + sLineBreak +
    '                <Grid Grid.Row="1" Width="150" Height="150">' + sLineBreak +
    '                  <Ellipse Margin="10" Stroke="{ThemeResource TextFillColorTertiaryBrush}" StrokeThickness="8" StrokeDashArray="0.25,1.6" />' + sLineBreak +
    '                  <ProgressRing IsIndeterminate="False" Value="{Binding CountdownProgress}" Maximum="100" Width="150" Height="150" Foreground="{ThemeResource AccentFillColorDefaultBrush}" Background="' +
    'Transparent" />' + sLineBreak +
    '                  <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock x:Name="CountdownLabel" Text="{Binding CountdownText}" FontSize="32" FontFamily="Segoe UI Variable Display" FontWeight="Light" HorizontalAlignment="Center" />' + sLineBreak +
    '                    <TextBlock Text="until payday boost" FontSize="10" HorizontalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <Grid Grid.Row="2">' + sLineBreak +
    '                  <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                    <Button x:Name="PlayButton" Style="{StaticResource RoundButton}" Background="{ThemeResource PanelBrush}" AutomationProperties.Name="Start countdown">' + sLineBreak +
    '                      <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="12" />' + sLineBreak +
    '                    </Button>' + sLineBreak +
    '                    <Button x:Name="PauseButton" Style="{StaticResource RoundButton}" Background="{ThemeResource PanelBrush}" AutomationProperties.Name="Pause countdown">' + sLineBreak +
    '                      <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="12" />' + sLineBreak +
    '                    </Button>' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <Button Style="{StaticResource RoundButton}" HorizontalAlignment="Right" Background="{ThemeResource InkBrush}" ToolTipService.ToolTip="Remind me" AutomationProperties.Name="Remind me' +
    '">' + sLineBreak +
    '                    <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="13" Foreground="{ThemeResource OnInkBrush}" />' + sLineBreak +
    '                  </Button>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '' + sLineBreak +
    '            ' + sLineBreak +
    '            <Border Grid.Column="3" Style="{StaticResource Card}">' + sLineBreak +
    '              <StackPanel Spacing="18">' + sLineBreak +
    '                <Grid>' + sLineBreak +
    '                  <TextBlock Text="Budget used" FontSize="18" />' + sLineBreak +
    '                  <TextBlock Text="18%" FontSize="34" FontFamily="Segoe UI Variable Display" FontWeight="Light" HorizontalAlignment="Right" />' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <Grid ColumnSpacing="4" RowSpacing="6">' + sLineBreak +
    '                  <Grid.ColumnDefinitions>' + sLineBreak +
    '                    <ColumnDefinition Width="30*" />' + sLineBreak +
    '                    <ColumnDefinition Width="25*" />' + sLineBreak +
    '                    <ColumnDefinition Width="12*" />' + sLineBreak +
    '                  </Grid.ColumnDefinitions>' + sLineBreak +
    '                  <Grid.RowDefinitions>' + sLineBreak +
    '                    <RowDefinition Height="Auto" />' + sLineBreak +
    '                    <RowDefinition Height="44" />' + sLineBreak +
    '                  </Grid.RowDefinitions>' + sLineBreak +
    '                  <TextBlock Text="30%" FontSize="11" />' + sLineBreak +
    '                  <Border Grid.Column="1" BorderThickness="1,0,0,0" BorderBrush="{ThemeResource LineBrush}" Padding="6,0,0,0">' + sLineBreak +
    '                    <TextBlock Text="25%" FontSize="11" />' + sLineBreak +
    '                  </Border>' + sLineBreak +
    '                  <Border Grid.Column="2" BorderThickness="1,0,0,0" BorderBrush="{ThemeResource LineBrush}" Padding="6,0,0,0">' + sLineBreak +
    '                    <TextBlock Text="0%" FontSize="11" />' + sLineBreak +
    '                  </Border>' + sLineBreak +
    '                  <Border Grid.Row="1" CornerRadius="12" Padding="12,0" Background="{ThemeResource AccentFillColorDefaultBrush}">' + sLineBreak +
    '                    <TextBlock Text="Bills" FontSize="12" VerticalAlignment="Center" Foreground="{ThemeResource TextOnAccentFillColorPrimaryBrush}" />' + sLineBreak +
    '                  </Border>' + sLineBreak +
    '                  <Border Grid.Row="1" Grid.Column="1" CornerRadius="12" Background="{ThemeResource InkBrush}" />' + sLineBreak +
    '                  <Border Grid.Row="1" Grid.Column="2" CornerRadius="12" Background="{ThemeResource FaintBrush}" />' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <TextBlock Text="Bills, groceries and fun money this month" FontSize="11" TextWrapping="Wrap" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '' + sLineBreak +
    '            ' + sLineBreak +
    '            <Border Grid.Row="1" Style="{StaticResource Card}" Padding="12">' + sLineBreak +
    '              <ScrollViewer VerticalScrollBarVisibility="Auto">' + sLineBreak +
    '                <StackPanel Spacing="6">' + sLineBreak +
    '                  <Expander x:Name="RulesExpander" HorizontalAlignment="Stretch" HorizontalContentAlignment="Stretch">' + sLineBreak +
    '                    <Expander.Header>' + sLineBreak +
    '                      <Grid>' + sLineBreak +
    '                        <TextBlock Text="Auto-save rules" FontSize="13" VerticalAlignment="Center" />' + sLineBreak +
    '                        <Border HorizontalAlignment="Right" CornerRadius="9" Padding="8,2" Background="{ThemeResource AccentFillColorDefaultBrush}">' + sLineBreak +
    '                          <TextBlock x:Name="AutoSaveLabel" Text="{Binding AutoSaveCaption}" FontSize="10" Foreground="{ThemeResource TextOnAccentFillColorPrimaryBrush}" />' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                      </Grid>' + sLineBreak +
    '                    </Expander.Header>' + sLineBreak +
    '                    <StackPanel Spacing="4">' + sLineBreak +
    '                      <ToggleSwitch x:Name="RoundUpsSwitch" Header="Round-ups" IsOn="{Binding RoundUps, Mode=TwoWay}" />' + sLineBreak +
    '                      <ToggleSwitch x:Name="PaydaySwitch" Header="Payday boost" IsOn="{Binding PaydayBoost, Mode=TwoWay}" />' + sLineBreak +
    '                      <ToggleSwitch x:Name="SweepSwitch" Header="Smart sweep" IsOn="{Binding SmartSweep, Mode=TwoWay}" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                  </Expander>' + sLineBreak +
    '                  <Expander HorizontalAlignment="Stretch" HorizontalContentAlignment="Stretch" IsExpanded="True" Header="Linked cards">' + sLineBreak +
    '                    <Grid ColumnSpacing="12">' + sLineBreak +
    '                      <Grid.ColumnDefinitions>' + sLineBreak +
    '                        <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                        <ColumnDefinition Width="*" />' + sLineBreak +
    '                        <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                      </Grid.ColumnDefinitions>' + sLineBreak +
    '                      <Border Width="44" Height="30" CornerRadius="6" Background="{ThemeResource InkBrush}">' + sLineBreak +
    '                        <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="14" Foreground="{ThemeResource OnInkBrush}" />' + sLineBreak +
    '                      </Border>' + sLineBreak +
    '                      <StackPanel Grid.Column="1" VerticalAlignment="Center">' + sLineBreak +
    '                        <TextBlock Text="Visa Debit" FontSize="13" />' + sLineBreak +
    '                        <TextBlock Text="ending 4821" FontSize="11" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                      </StackPanel>' + sLineBreak +
    '                      <FontIcon Grid.Column="2" FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="14" />' + sLineBreak +
    '                    </Grid>' + sLineBreak +
    '                  </Expander>' + sLineBreak +
    '                  <Expander HorizontalAlignment="Stretch" HorizontalContentAlignment="Stretch" Header="Interest summary">' + sLineBreak +
    '                    <TextBlock Text="$38.20 earned this year at 2.4% a year" FontSize="12" TextWrapping="Wrap" />' + sLineBreak +
    '                  </Expander>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </ScrollViewer>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '' + sLineBreak +
    '            ' + sLineBreak +
    '            <Border Grid.Row="1" Grid.Column="1" Grid.ColumnSpan="2" Style="{StaticResource Card}">' + sLineBreak +
    '              <Grid RowSpacing="10">' + sLineBreak +
    '                <Grid.RowDefinitions>' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                  <RowDefinition Height="*" />' + sLineBreak +
    '                </Grid.RowDefinitions>' + sLineBreak +
    '                <Grid>' + sLineBreak +
    '                  <Border HorizontalAlignment="Left" CornerRadius="12" Padding="12,4" Background="{ThemeResource FaintBrush}">' + sLineBreak +
    '                    <TextBlock Text="October" FontSize="11" />' + sLineBreak +
    '                  </Border>' + sLineBreak +
    '                  <TextBlock Text="November 2026" FontSize="14" HorizontalAlignment="Center" VerticalAlignment="Center" />' + sLineBreak +
    '                  <Border HorizontalAlignment="Right" CornerRadius="12" Padding="12,4" Background="{ThemeResource FaintBrush}">' + sLineBreak +
    '                    <TextBlock Text="December" FontSize="11" />' + sLineBreak +
    '                  </Border>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <Grid Grid.Row="1">' + sLineBreak +
    '                  <Grid.ColumnDefinitions>' + sLineBreak +
    '                    <ColumnDefinition Width="70" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                  </Grid.ColumnDefinitions>' + sLineBreak +
    '                  <StackPanel Grid.Column="1" HorizontalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="Mon" FontSize="11" HorizontalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                    <TextBlock Text="23" FontSize="13" HorizontalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <StackPanel Grid.Column="2" HorizontalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="Tue" FontSize="11" HorizontalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                    <TextBlock Text="24" FontSize="13" HorizontalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <StackPanel Grid.Column="3" HorizontalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="Wed" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Center" />' + sLineBreak +
    '                    <TextBlock Text="25" FontSize="13" FontWeight="SemiBold" HorizontalAlignment="Center" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <StackPanel Grid.Column="4" HorizontalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="Thu" FontSize="11" HorizontalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                    <TextBlock Text="26" FontSize="13" HorizontalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <StackPanel Grid.Column="5" HorizontalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="Fri" FontSize="11" HorizontalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                    <TextBlock Text="27" FontSize="13" HorizontalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <StackPanel Grid.Column="6" HorizontalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="Sat" FontSize="11" HorizontalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                    <TextBlock Text="28" FontSize="13" HorizontalAlignment="Center" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <Grid Grid.Row="2">' + sLineBreak +
    '                  <Grid.ColumnDefinitions>' + sLineBreak +
    '                    <ColumnDefinition Width="70" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                  </Grid.ColumnDefinitions>' + sLineBreak +
    '                  <Grid.RowDefinitions>' + sLineBreak +
    '                    <RowDefinition Height="*" />' + sLineBreak +
    '                    <RowDefinition Height="*" />' + sLineBreak +
    '                    <RowDefinition Height="*" />' + sLineBreak +
    '                    <RowDefinition Height="*" />' + sLineBreak +
    '                  </Grid.RowDefinitions>' + sLineBreak +
    '                  <Line Grid.Column="1" Grid.RowSpan="4" X1="0" Y1="0" X2="0" Y2="400" HorizontalAlignment="Center" Stroke="{ThemeResource LineBrush}" StrokeDashArray="3,3" />' + sLineBreak +
    '                  <Line Grid.Column="2" Grid.RowSpan="4" X1="0" Y1="0" X2="0" Y2="400" HorizontalAlignment="Center" Stroke="{ThemeResource LineBrush}" StrokeDashArray="3,3" />' + sLineBreak +
    '                  <Line Grid.Column="3" Grid.RowSpan="4" X1="0" Y1="0" X2="0" Y2="400" HorizontalAlignment="Center" Stroke="{ThemeResource LineBrush}" StrokeDashArray="3,3" />' + sLineBreak +
    '                  <Line Grid.Column="4" Grid.RowSpan="4" X1="0" Y1="0" X2="0" Y2="400" HorizontalAlignment="Center" Stroke="{ThemeResource LineBrush}" StrokeDashArray="3,3" />' + sLineBreak +
    '                  <Line Grid.Column="5" Grid.RowSpan="4" X1="0" Y1="0" X2="0" Y2="400" HorizontalAlignment="Center" Stroke="{ThemeResource LineBrush}" StrokeDashArray="3,3" />' + sLineBreak +
    '                  <Line Grid.Column="6" Grid.RowSpan="4" X1="0" Y1="0" X2="0" Y2="400" HorizontalAlignment="Center" Stroke="{ThemeResource LineBrush}" StrokeDashArray="3,3" />' + sLineBreak +
    '                  <TextBlock Text="8:00 am" FontSize="11" VerticalAlignment="Center" />' + sLineBreak +
    '                  <TextBlock Grid.Row="1" Text="9:00 am" FontSize="11" VerticalAlignment="Center" />' + sLineBreak +
    '                  <TextBlock Grid.Row="2" Text="10:00 am" FontSize="11" VerticalAlignment="Center" />' + sLineBreak +
    '                  <TextBlock Grid.Row="3" Text="11:00 am" FontSize="11" VerticalAlignment="Center" />' + sLineBreak +
    '                  <Border Grid.Row="0" Grid.RowSpan="2" Grid.Column="2" Grid.ColumnSpan="2" VerticalAlignment="Center" Margin="10,0" CornerRadius="12" Padding="12,8" Background="{ThemeResource InkBrus' +
    'h}">' + sLineBreak +
    '                    <Grid>' + sLineBreak +
    '                      <StackPanel Margin="0,0,48,0">' + sLineBreak +
    '                        <TextBlock Text="Payday boost" FontSize="12" Foreground="{ThemeResource OnInkBrush}" />' + sLineBreak +
    '                        <TextBlock Text="Move 10% to goals" FontSize="10" Foreground="{ThemeResource OnInkMutedBrush}" />' + sLineBreak +
    '                      </StackPanel>' + sLineBreak +
    '                      <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center" Spacing="-6">' + sLineBreak +
    '                        <PersonPicture DisplayName="Alex Morgan" Width="24" Height="24" />' + sLineBreak +
    '                        <PersonPicture DisplayName="Sam Lee" Width="24" Height="24" />' + sLineBreak +
    '                      </StackPanel>' + sLineBreak +
    '                    </Grid>' + sLineBreak +
    '                  </Border>' + sLineBreak +
    '                  <Border Grid.Row="2" Grid.RowSpan="2" Grid.Column="4" Grid.ColumnSpan="2" VerticalAlignment="Center" Margin="10,0" CornerRadius="12" Padding="12,8" Background="{ThemeResource PanelBr' +
    'ush}" BorderThickness="1" BorderBrush="{ThemeResource LineBrush}">' + sLineBreak +
    '                    <Grid>' + sLineBreak +
    '                      <StackPanel Margin="0,0,48,0">' + sLineBreak +
    '                        <TextBlock Text="Travel goal check-in" FontSize="12" />' + sLineBreak +
    '                        <TextBlock Text="Review progress" FontSize="10" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                      </StackPanel>' + sLineBreak +
    '                      <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center" Spacing="-6">' + sLineBreak +
    '                        <PersonPicture DisplayName="Alex Morgan" Width="24" Height="24" />' + sLineBreak +
    '                        <PersonPicture DisplayName="Rita Cho" Width="24" Height="24" />' + sLineBreak +
    '                      </StackPanel>' + sLineBreak +
    '                    </Grid>' + sLineBreak +
    '                  </Border>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '' + sLineBreak +
    '            ' + sLineBreak +
    '            <Border Grid.Row="1" Grid.Column="3" CornerRadius="24" Padding="18,18,18,10" Background="{ThemeResource InkBrush}">' + sLineBreak +
    '              <Grid RowSpacing="8">' + sLineBreak +
    '                <Grid.RowDefinitions>' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                  <RowDefinition Height="*" />' + sLineBreak +
    '                </Grid.RowDefinitions>' + sLineBreak +
    '                <Grid>' + sLineBreak +
    '                  <TextBlock Text="Goals" FontSize="18" Foreground="{ThemeResource OnInkBrush}" VerticalAlignment="Center" />' + sLineBreak +
    '                  <TextBlock x:Name="GoalCaptionLabel" Text="{Binding GoalCaption}" FontSize="30" FontFamily="Segoe UI Variable Display" FontWeight="Light" HorizontalAlignment="Right" Foreground="{The' +
    'meResource OnInkBrush}" />' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <ListView x:Name="GoalList" Grid.Row="1" SelectionMode="None" IsItemClickEnabled="True" Margin="-12,0" AutomationProperties.Name="Goals">' + sLineBreak +
    '                  <ListView.ItemTemplate>' + sLineBreak +
    '                    <DataTemplate>' + sLineBreak +
    '                      <Grid ColumnSpacing="10" Padding="0,5">' + sLineBreak +
    '                        <Grid.ColumnDefinitions>' + sLineBreak +
    '                          <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                          <ColumnDefinition Width="*" />' + sLineBreak +
    '                          <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                        </Grid.ColumnDefinitions>' + sLineBreak +
    '                        <Border Width="34" Height="34" CornerRadius="17" Background="{ThemeResource OnInkFaintBrush}">' + sLineBreak +
    '                          <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="{Binding Glyph}" FontSize="13" Foreground="{ThemeResource OnInkBrush}" />' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                        <StackPanel Grid.Column="1" VerticalAlignment="Center">' + sLineBreak +
    '                          <TextBlock Text="{Binding Title}" FontSize="13" TextDecorations="Strikethrough" Foreground="{ThemeResource OnInkMutedBrush}" Visibility="{Binding Done, Converter={StaticResou' +
    'rce BoolToVisibility}}" />' + sLineBreak +
    '                          <TextBlock Text="{Binding Title}" FontSize="13" Foreground="{ThemeResource OnInkBrush}" Visibility="{Binding Done, Converter={StaticResource InverseBoolToVisibility}}" />' + sLineBreak +
    '                          <TextBlock Text="{Binding When}" FontSize="10" Foreground="{ThemeResource OnInkMutedBrush}" />' + sLineBreak +
    '                        </StackPanel>' + sLineBreak +
    '                        <Grid Grid.Column="2" Width="22" Height="22">' + sLineBreak +
    '                          <Ellipse Fill="{ThemeResource AccentFillColorDefaultBrush}" Visibility="{Binding Done, Converter={StaticResource BoolToVisibility}}" />' + sLineBreak +
    '                          <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="11" Foreground="{ThemeResource TextOnAccentFillColorPrimaryBrush}" Visibility="{Binding Done,' +
    ' Converter={StaticResource BoolToVisibility}}" />' + sLineBreak +
    '                          <Ellipse Width="12" Height="12" Fill="{ThemeResource OnInkFaintBrush}" Visibility="{Binding Done, Converter={StaticResource InverseBoolToVisibility}}" />' + sLineBreak +
    '                        </Grid>' + sLineBreak +
    '                      </Grid>' + sLineBreak +
    '                    </DataTemplate>' + sLineBreak +
    '                  </ListView.ItemTemplate>' + sLineBreak +
    '                </ListView>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </ScrollViewer>' + sLineBreak +
    '    </Border>' + sLineBreak +
    '  </Grid>' + sLineBreak;

constructor TMainWindowBase.Create;
begin
  inherited;
  // MainWindow.xaml(1): <Window> attributes
  Title := 'Haven - savings dashboard';
  Width := 1440;
  Height := 940;
  MinWidth := 900;
  MinHeight := 640;
  ExtendsContentIntoTitleBar := True;
  Center;
  LoadContent(ContentXaml);
  // x:Name elements
  Surface := FindElement<TWinUIGrid>('Surface');
  DragRegion := FindElement<TWinUIGrid>('DragRegion');
  WelcomeText := FindElement<TWinUITextBlock>('WelcomeText');
  TotalLabel := FindElement<TWinUITextBlock>('TotalLabel');
  AddMoneyButton := FindElement<TWinUIButton>('AddMoneyButton');
  WeekLabel := FindElement<TWinUITextBlock>('WeekLabel');
  CountdownLabel := FindElement<TWinUITextBlock>('CountdownLabel');
  PlayButton := FindElement<TWinUIButton>('PlayButton');
  PauseButton := FindElement<TWinUIButton>('PauseButton');
  RulesExpander := FindElement<TWinUIExpander>('RulesExpander');
  AutoSaveLabel := FindElement<TWinUITextBlock>('AutoSaveLabel');
  RoundUpsSwitch := FindElement<TWinUIToggleSwitch>('RoundUpsSwitch');
  PaydaySwitch := FindElement<TWinUIToggleSwitch>('PaydaySwitch');
  SweepSwitch := FindElement<TWinUIToggleSwitch>('SweepSwitch');
  GoalCaptionLabel := FindElement<TWinUITextBlock>('GoalCaptionLabel');
  GoalList := FindElement<TWinUIListView>('GoalList');
  // Event wiring
  // MainWindow.xaml(246): Click="AddMoneyClick"
  AddMoneyButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('AddMoneyClick'));
  // MainWindow.xaml(327): Click="PlayClick"
  PlayButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('PlayClick'));
  // MainWindow.xaml(331): Click="PauseClick"
  PauseButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('PauseClick'));
  // MainWindow.xaml(543): ItemClick="GoalClick"
  GoalList.OnItemClick := TWinUIItemClickEventHandler(PublishedMethod('GoalClick'));
end;

procedure TMainWindowBase.SetViewModel(AValue: TMainViewModel);
begin
  FViewModel := AValue;
  DataContext := AValue;
end;

end.
