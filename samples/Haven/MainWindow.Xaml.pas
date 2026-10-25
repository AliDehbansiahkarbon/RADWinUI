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
    DragRegion: TWinUIGrid;              // MainWindow.xaml(98) <Grid>
    WelcomeText: TWinUITextBlock;        // MainWindow.xaml(110) <TextBlock>
    AskBox: TWinUITextBox;               // MainWindow.xaml(129) <TextBox>
    NewGoalButton: TWinUIButton;         // MainWindow.xaml(190) <Button>
    TotalLabel: TWinUITextBlock;         // MainWindow.xaml(215) <TextBlock>
    ProgressLabel: TWinUITextBlock;      // MainWindow.xaml(225) <TextBlock>
    CurrentMonthBar: TWinUIBorder;       // MainWindow.xaml(244) <Border>
    AutoSaveLabel: TWinUITextBlock;      // MainWindow.xaml(272) <TextBlock>
    RoundUpsSwitch: TWinUIToggleSwitch;  // MainWindow.xaml(288) <ToggleSwitch>
    PaydaySwitch: TWinUIToggleSwitch;    // MainWindow.xaml(304) <ToggleSwitch>
    SweepSwitch: TWinUIToggleSwitch;     // MainWindow.xaml(320) <ToggleSwitch>
    GoalGrid: TWinUIGridView;            // MainWindow.xaml(328) <GridView>
    QuickAddButton: TWinUIButton;        // MainWindow.xaml(396) <Button>
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
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="Surface" RequestedTheme="Light" Background="#C9AE93">' + sLineBreak +
    '    <Grid.Resources>' + sLineBreak +
    '      <AcrylicBrush x:Key="GlassBrush" TintColor="#FFF8F0" TintOpacity="0.08" TintLuminosityOpacity="0.32" FallbackColor="#D9EFE4D8" />' + sLineBreak +
    '      <AcrylicBrush x:Key="GlassStrongBrush" TintColor="#FFFFFF" TintOpacity="0.20" TintLuminosityOpacity="0.55" FallbackColor="#E6F7F1EA" />' + sLineBreak +
    '      <SolidColorBrush x:Key="GlassBorderBrush" Color="#8CFFFFFF" />' + sLineBreak +
    '      <SolidColorBrush x:Key="CoralBrush" Color="#F26B4F" />' + sLineBreak +
    '      <SolidColorBrush x:Key="InkBrush" Color="#2B2622" />' + sLineBreak +
    '      <SolidColorBrush x:Key="MutedBrush" Color="#7A6F66" />' + sLineBreak +
    '      <SolidColorBrush x:Key="ToggleSwitchFillOn" Color="#F26B4F" />' + sLineBreak +
    '      <SolidColorBrush x:Key="ToggleSwitchFillOnPointerOver" Color="#F47E65" />' + sLineBreak +
    '      <SolidColorBrush x:Key="ToggleSwitchFillOnPressed" Color="#D95A40" />' + sLineBreak +
    '      <Style x:Key="GlassCard" TargetType="Border">' + sLineBreak +
    '        <Setter Property="Background" Value="{StaticResource GlassBrush}" />' + sLineBreak +
    '        <Setter Property="BorderBrush" Value="{StaticResource GlassBorderBrush}" />' + sLineBreak +
    '        <Setter Property="BorderThickness" Value="1" />' + sLineBreak +
    '        <Setter Property="CornerRadius" Value="26" />' + sLineBreak +
    '      </Style>' + sLineBreak +
    '      <Style x:Key="RailButton" TargetType="Button">' + sLineBreak +
    '        <Setter Property="Width" Value="44" />' + sLineBreak +
    '        <Setter Property="Height" Value="44" />' + sLineBreak +
    '        <Setter Property="Padding" Value="0" />' + sLineBreak +
    '        <Setter Property="CornerRadius" Value="22" />' + sLineBreak +
    '        <Setter Property="Background" Value="Transparent" />' + sLineBreak +
    '        <Setter Property="BorderThickness" Value="0" />' + sLineBreak +
    '        <Setter Property="Foreground" Value="{StaticResource InkBrush}" />' + sLineBreak +
    '      </Style>' + sLineBreak +
    '      <Style x:Key="TabButton" TargetType="Button">' + sLineBreak +
    '        <Setter Property="Padding" Value="16,8" />' + sLineBreak +
    '        <Setter Property="CornerRadius" Value="18" />' + sLineBreak +
    '        <Setter Property="Background" Value="Transparent" />' + sLineBreak +
    '        <Setter Property="BorderThickness" Value="0" />' + sLineBreak +
    '        <Setter Property="FontSize" Value="13" />' + sLineBreak +
    '        <Setter Property="Foreground" Value="{StaticResource InkBrush}" />' + sLineBreak +
    '      </Style>' + sLineBreak +
    '    </Grid.Resources>' + sLineBreak +
    '    <Grid.RowDefinitions>' + sLineBreak +
    '      <RowDefinition Height="36" />' + sLineBreak +
    '      <RowDefinition Height="Auto" />' + sLineBreak +
    '      <RowDefinition Height="*" />' + sLineBreak +
    '      <RowDefinition Height="Auto" />' + sLineBreak +
    '    </Grid.RowDefinitions>' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Grid Grid.RowSpan="4" IsHitTestVisible="False">' + sLineBreak +
    '      <Ellipse Width="900" Height="700" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="-220,-180,0,0">' + sLineBreak +
    '        <Ellipse.Fill>' + sLineBreak +
    '          <RadialGradientBrush>' + sLineBreak +
    '            <GradientStop Color="#F0E0965F" Offset="0" />' + sLineBreak +
    '            <GradientStop Color="#00E0965F" Offset="1" />' + sLineBreak +
    '          </RadialGradientBrush>' + sLineBreak +
    '        </Ellipse.Fill>' + sLineBreak +
    '      </Ellipse>' + sLineBreak +
    '      <Ellipse Width="1000" Height="820" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,-120,-260,0">' + sLineBreak +
    '        <Ellipse.Fill>' + sLineBreak +
    '          <RadialGradientBrush>' + sLineBreak +
    '            <GradientStop Color="#E8B07A4E" Offset="0" />' + sLineBreak +
    '            <GradientStop Color="#00B07A4E" Offset="1" />' + sLineBreak +
    '          </RadialGradientBrush>' + sLineBreak +
    '        </Ellipse.Fill>' + sLineBreak +
    '      </Ellipse>' + sLineBreak +
    '      <Ellipse Width="1100" Height="760" HorizontalAlignment="Center" VerticalAlignment="Bottom" Margin="0,0,0,-300">' + sLineBreak +
    '        <Ellipse.Fill>' + sLineBreak +
    '          <RadialGradientBrush>' + sLineBreak +
    '            <GradientStop Color="#D8F6E7D2" Offset="0" />' + sLineBreak +
    '            <GradientStop Color="#00F6E7D2" Offset="1" />' + sLineBreak +
    '          </RadialGradientBrush>' + sLineBreak +
    '        </Ellipse.Fill>' + sLineBreak +
    '      </Ellipse>' + sLineBreak +
    '      <Ellipse Width="620" Height="620" HorizontalAlignment="Left" VerticalAlignment="Bottom" Margin="80,0,0,-160">' + sLineBreak +
    '        <Ellipse.Fill>' + sLineBreak +
    '          <RadialGradientBrush>' + sLineBreak +
    '            <GradientStop Color="#D86E4630" Offset="0" />' + sLineBreak +
    '            <GradientStop Color="#006E4630" Offset="1" />' + sLineBreak +
    '          </RadialGradientBrush>' + sLineBreak +
    '        </Ellipse.Fill>' + sLineBreak +
    '      </Ellipse>' + sLineBreak +
    '      <Ellipse Width="520" Height="520" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,120,40">' + sLineBreak +
    '        <Ellipse.Fill>' + sLineBreak +
    '          <RadialGradientBrush>' + sLineBreak +
    '            <GradientStop Color="#B0E2795A" Offset="0" />' + sLineBreak +
    '            <GradientStop Color="#00E2795A" Offset="1" />' + sLineBreak +
    '          </RadialGradientBrush>' + sLineBreak +
    '        </Ellipse.Fill>' + sLineBreak +
    '      </Ellipse>' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '' + sLineBreak +
    '    <Grid x:Name="DragRegion" Background="Transparent" />' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Border Grid.Row="1" Style="{StaticResource GlassCard}" CornerRadius="30" Margin="28,0,28,0" Padding="10,8">' + sLineBreak +
    '      <Grid ColumnSpacing="16">' + sLineBreak +
    '        <Grid.ColumnDefinitions>' + sLineBreak +
    '          <ColumnDefinition Width="Auto" />' + sLineBreak +
    '          <ColumnDefinition Width="*" />' + sLineBreak +
    '          <ColumnDefinition Width="Auto" />' + sLineBreak +
    '        </Grid.ColumnDefinitions>' + sLineBreak +
    '        <StackPanel Orientation="Horizontal" Spacing="12" VerticalAlignment="Center">' + sLineBreak +
    '          <PersonPicture DisplayName="{Binding UserName}" Width="40" Height="40" />' + sLineBreak +
    '          <TextBlock x:Name="WelcomeText" Text="{Binding UserName, Converter={StaticResource Format}, ConverterParameter=''Welcome, %s''}" FontSize="15" FontWeight="SemiBold" VerticalAlignment="Center" ' +
    'Foreground="{StaticResource InkBrush}" />' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '        <Border Grid.Column="1" MaxWidth="560" HorizontalAlignment="Center" CornerRadius="22" Padding="12,0,6,0" Background="{StaticResource GlassStrongBrush}" BorderBrush="{StaticResource GlassBorder' +
    'Brush}" BorderThickness="1">' + sLineBreak +
    '          <Grid ColumnSpacing="10">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <Ellipse Width="20" Height="20" VerticalAlignment="Center">' + sLineBreak +
    '              <Ellipse.Fill>' + sLineBreak +
    '                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">' + sLineBreak +
    '                  <GradientStop Color="#7B8CFF" Offset="0" />' + sLineBreak +
    '                  <GradientStop Color="#C56CF0" Offset="0.5" />' + sLineBreak +
    '                  <GradientStop Color="#F26B4F" Offset="1" />' + sLineBreak +
    '                </LinearGradientBrush>' + sLineBreak +
    '              </Ellipse.Fill>' + sLineBreak +
    '            </Ellipse>' + sLineBreak +
    '            <TextBox x:Name="AskBox" Grid.Column="1" MinWidth="380" BorderThickness="0" Background="Transparent" PlaceholderText="Ask anything, e.g. move $250 to Travel" VerticalAlignment="Center" Aut' +
    'omationProperties.Name="Ask Haven" />' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '        </Border>' + sLineBreak +
    '        <Grid Grid.Column="2">' + sLineBreak +
    '          <Button Width="40" Height="40" CornerRadius="20" Padding="0" Background="White" BorderThickness="0" ToolTipService.ToolTip="Notifications" AutomationProperties.Name="Notifications">' + sLineBreak +
    '            <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" Foreground="{StaticResource InkBrush}" />' + sLineBreak +
    '          </Button>' + sLineBreak +
    '          <Ellipse Width="9" Height="9" Fill="{StaticResource CoralBrush}" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,6,7,0" IsHitTestVisible="False" />' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </Grid>' + sLineBreak +
    '    </Border>' + sLineBreak +
    '' + sLineBreak +
    '    <Grid Grid.Row="2" Margin="20,20,28,16" ColumnSpacing="18">' + sLineBreak +
    '      <Grid.ColumnDefinitions>' + sLineBreak +
    '        <ColumnDefinition Width="Auto" />' + sLineBreak +
    '        <ColumnDefinition Width="*" />' + sLineBreak +
    '      </Grid.ColumnDefinitions>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <Border Style="{StaticResource GlassCard}" CornerRadius="32" Padding="8,12" VerticalAlignment="Center">' + sLineBreak +
    '        <StackPanel Spacing="8">' + sLineBreak +
    '          <Button Style="{StaticResource RailButton}" ToolTipService.ToolTip="Home" AutomationProperties.Name="Home">' + sLineBreak +
    '            <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" />' + sLineBreak +
    '          </Button>' + sLineBreak +
    '          <Button Style="{StaticResource RailButton}" ToolTipService.ToolTip="Activity" AutomationProperties.Name="Activity">' + sLineBreak +
    '            <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" />' + sLineBreak +
    '          </Button>' + sLineBreak +
    '          <Button Style="{StaticResource RailButton}" Background="White" ToolTipService.ToolTip="Savings" AutomationProperties.Name="Savings">' + sLineBreak +
    '            <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" />' + sLineBreak +
    '          </Button>' + sLineBreak +
    '          <Button Style="{StaticResource RailButton}" ToolTipService.ToolTip="Schedule" AutomationProperties.Name="Schedule">' + sLineBreak +
    '            <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" />' + sLineBreak +
    '          </Button>' + sLineBreak +
    '          <Button Style="{StaticResource RailButton}" ToolTipService.ToolTip="Reports" AutomationProperties.Name="Reports">' + sLineBreak +
    '            <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" />' + sLineBreak +
    '          </Button>' + sLineBreak +
    '          <Button Style="{StaticResource RailButton}" ToolTipService.ToolTip="Video call" AutomationProperties.Name="Video call">' + sLineBreak +
    '            <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" />' + sLineBreak +
    '          </Button>' + sLineBreak +
    '          <Button Style="{StaticResource RailButton}" ToolTipService.ToolTip="Settings" AutomationProperties.Name="Settings">' + sLineBreak +
    '            <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" />' + sLineBreak +
    '          </Button>' + sLineBreak +
    '          <Button Style="{StaticResource RailButton}" ToolTipService.ToolTip="More" AutomationProperties.Name="More">' + sLineBreak +
    '            <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="12" />' + sLineBreak +
    '          </Button>' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </Border>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <Border Grid.Column="1" Style="{StaticResource GlassCard}" CornerRadius="34">' + sLineBreak +
    '        <ScrollViewer HorizontalScrollBarVisibility="Disabled" VerticalScrollBarVisibility="Auto">' + sLineBreak +
    '          <StackPanel Padding="40,32,40,32" Spacing="24">' + sLineBreak +
    '            <Grid>' + sLineBreak +
    '              <StackPanel Spacing="6">' + sLineBreak +
    '                <TextBlock Text="Savings &amp; Goals" FontSize="34" FontWeight="SemiBold" Foreground="{StaticResource InkBrush}" />' + sLineBreak +
    '                <TextBlock Text="Set money aside for the things that matter and watch it grow." FontSize="14" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Button x:Name="NewGoalButton" HorizontalAlignment="Right" VerticalAlignment="Top" CornerRadius="20" Padding="16,9" Background="{StaticResource GlassStrongBrush}" BorderBrush="{StaticRes' +
    'ource GlassBorderBrush}" AutomationProperties.Name="New goal">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                  <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="12" />' + sLineBreak +
    '                  <TextBlock Text="New goal" FontSize="13" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Button>' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '' + sLineBreak +
    '            <Grid ColumnSpacing="20">' + sLineBreak +
    '              <Grid.ColumnDefinitions>' + sLineBreak +
    '                <ColumnDefinition Width="2*" />' + sLineBreak +
    '                <ColumnDefinition Width="*" MinWidth="300" />' + sLineBreak +
    '              </Grid.ColumnDefinitions>' + sLineBreak +
    '' + sLineBreak +
    '              ' + sLineBreak +
    '              <Border Style="{StaticResource GlassCard}" Padding="26,22">' + sLineBreak +
    '                <Grid ColumnSpacing="28">' + sLineBreak +
    '                  <Grid.ColumnDefinitions>' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                  </Grid.ColumnDefinitions>' + sLineBreak +
    '                  <StackPanel Spacing="8" VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="Total saved" FontSize="13" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '                    <TextBlock x:Name="TotalLabel" Text="{Binding TotalText}" FontSize="40" FontWeight="SemiBold" FontFamily="Segoe UI Variable Display" Foreground="{StaticResource InkBrush}" />' + sLineBreak +
    '                    <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                      <Border Background="#2629A36A" CornerRadius="9" Padding="7,2">' + sLineBreak +
    '                        <TextBlock Text="+2%" FontSize="11" FontWeight="SemiBold" Foreground="#1F7A4D" />' + sLineBreak +
    '                      </Border>' + sLineBreak +
    '                      <TextBlock Text="more than last quarter" FontSize="12" Foreground="{StaticResource MutedBrush}" VerticalAlignment="Center" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                    <ProgressBar Value="{Binding TotalProgress}" Maximum="100" Height="6" Margin="0,18,0,0" Foreground="{StaticResource CoralBrush}" Background="#40FFFFFF" CornerRadius="3" />' + sLineBreak +
    '                    <TextBlock x:Name="ProgressLabel" Text="{Binding ProgressCaption}" FontSize="12" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <StackPanel Grid.Column="1" Spacing="10">' + sLineBreak +
    '                    <TextBlock Text="Monthly contributions" FontSize="13" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '                    <Grid Height="160" ColumnSpacing="14">' + sLineBreak +
    '                      <Grid.ColumnDefinitions>' + sLineBreak +
    '                        <ColumnDefinition Width="*" />' + sLineBreak +
    '                        <ColumnDefinition Width="*" />' + sLineBreak +
    '                        <ColumnDefinition Width="*" />' + sLineBreak +
    '                        <ColumnDefinition Width="*" />' + sLineBreak +
    '                        <ColumnDefinition Width="*" />' + sLineBreak +
    '                        <ColumnDefinition Width="*" />' + sLineBreak +
    '                      </Grid.ColumnDefinitions>' + sLineBreak +
    '                      <Border Height="{Binding Bar1}" VerticalAlignment="Bottom" CornerRadius="10" Background="#B3FFFFFF" BorderBrush="#E6FFFFFF" BorderThickness="1" />' + sLineBreak +
    '                      <Border Grid.Column="1" Height="{Binding Bar2}" VerticalAlignment="Bottom" CornerRadius="10" Background="#B3FFFFFF" BorderBrush="#E6FFFFFF" BorderThickness="1" />' + sLineBreak +
    '                      <Border Grid.Column="2" Height="{Binding Bar3}" VerticalAlignment="Bottom" CornerRadius="10" Background="#B3FFFFFF" BorderBrush="#E6FFFFFF" BorderThickness="1" />' + sLineBreak +
    '                      <Border Grid.Column="3" Height="{Binding Bar4}" VerticalAlignment="Bottom" CornerRadius="10" Background="#B3FFFFFF" BorderBrush="#E6FFFFFF" BorderThickness="1" />' + sLineBreak +
    '                      <Border Grid.Column="4" Height="{Binding Bar5}" VerticalAlignment="Bottom" CornerRadius="10" Background="#B3FFFFFF" BorderBrush="#E6FFFFFF" BorderThickness="1" />' + sLineBreak +
    '                      <Border Grid.Column="5" x:Name="CurrentMonthBar" Height="{Binding Bar6}" VerticalAlignment="Bottom" CornerRadius="10" Background="{StaticResource CoralBrush}" Opacity="0.85" />' + sLineBreak +
    '                    </Grid>' + sLineBreak +
    '                    <Grid ColumnSpacing="14">' + sLineBreak +
    '                      <Grid.ColumnDefinitions>' + sLineBreak +
    '                        <ColumnDefinition Width="*" />' + sLineBreak +
    '                        <ColumnDefinition Width="*" />' + sLineBreak +
    '                        <ColumnDefinition Width="*" />' + sLineBreak +
    '                        <ColumnDefinition Width="*" />' + sLineBreak +
    '                        <ColumnDefinition Width="*" />' + sLineBreak +
    '                        <ColumnDefinition Width="*" />' + sLineBreak +
    '                      </Grid.ColumnDefinitions>' + sLineBreak +
    '                      <TextBlock Text="Nov" FontSize="11" HorizontalAlignment="Center" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '                      <TextBlock Grid.Column="1" Text="Dec" FontSize="11" HorizontalAlignment="Center" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '                      <TextBlock Grid.Column="2" Text="Jan" FontSize="11" HorizontalAlignment="Center" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '                      <TextBlock Grid.Column="3" Text="Feb" FontSize="11" HorizontalAlignment="Center" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '                      <TextBlock Grid.Column="4" Text="Mar" FontSize="11" HorizontalAlignment="Center" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '                      <TextBlock Grid.Column="5" Text="Apr" FontSize="11" HorizontalAlignment="Center" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '                    </Grid>' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '' + sLineBreak +
    '              ' + sLineBreak +
    '              <Border Grid.Column="1" Style="{StaticResource GlassCard}" Padding="22,20">' + sLineBreak +
    '                <StackPanel Spacing="14">' + sLineBreak +
    '                  <Grid>' + sLineBreak +
    '                    <TextBlock Text="Auto-save" FontSize="17" FontWeight="SemiBold" Foreground="{StaticResource InkBrush}" />' + sLineBreak +
    '                    <Border HorizontalAlignment="Right" Background="#2629A36A" CornerRadius="10" Padding="9,3">' + sLineBreak +
    '                      <TextBlock x:Name="AutoSaveLabel" Text="{Binding AutoSaveCaption}" FontSize="11" FontWeight="SemiBold" Foreground="#1F7A4D" />' + sLineBreak +
    '                    </Border>' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                  <Grid ColumnSpacing="12">' + sLineBreak +
    '                    <Grid.ColumnDefinitions>' + sLineBreak +
    '                      <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                      <ColumnDefinition Width="*" />' + sLineBreak +
    '                      <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                    </Grid.ColumnDefinitions>' + sLineBreak +
    '                    <Border Width="38" Height="38" CornerRadius="12" Background="#99FFFFFF">' + sLineBreak +
    '                      <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="15" Foreground="{StaticResource InkBrush}" />' + sLineBreak +
    '                    </Border>' + sLineBreak +
    '                    <StackPanel Grid.Column="1" VerticalAlignment="Center">' + sLineBreak +
    '                      <TextBlock Text="Round-ups" FontSize="13" FontWeight="SemiBold" Foreground="{StaticResource InkBrush}" />' + sLineBreak +
    '                      <TextBlock Text="Round every card payment up to the next dollar" FontSize="11" TextWrapping="Wrap" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                    <ToggleSwitch x:Name="RoundUpsSwitch" Grid.Column="2" IsOn="{Binding RoundUps, Mode=TwoWay}" OnContent="" OffContent="" MinWidth="0" AutomationProperties.Name="Round-ups" />' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                  <Grid ColumnSpacing="12">' + sLineBreak +
    '                    <Grid.ColumnDefinitions>' + sLineBreak +
    '                      <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                      <ColumnDefinition Width="*" />' + sLineBreak +
    '                      <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                    </Grid.ColumnDefinitions>' + sLineBreak +
    '                    <Border Width="38" Height="38" CornerRadius="12" Background="#99FFFFFF">' + sLineBreak +
    '                      <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="15" Foreground="{StaticResource InkBrush}" />' + sLineBreak +
    '                    </Border>' + sLineBreak +
    '                    <StackPanel Grid.Column="1" VerticalAlignment="Center">' + sLineBreak +
    '                      <TextBlock Text="Payday boost" FontSize="13" FontWeight="SemiBold" Foreground="{StaticResource InkBrush}" />' + sLineBreak +
    '                      <TextBlock Text="Move 10% of every salary into your goals" FontSize="11" TextWrapping="Wrap" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                    <ToggleSwitch x:Name="PaydaySwitch" Grid.Column="2" IsOn="{Binding PaydayBoost, Mode=TwoWay}" OnContent="" OffContent="" MinWidth="0" AutomationProperties.Name="Payday boost" />' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                  <Grid ColumnSpacing="12">' + sLineBreak +
    '                    <Grid.ColumnDefinitions>' + sLineBreak +
    '                      <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                      <ColumnDefinition Width="*" />' + sLineBreak +
    '                      <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                    </Grid.ColumnDefinitions>' + sLineBreak +
    '                    <Border Width="38" Height="38" CornerRadius="12" Background="#99FFFFFF">' + sLineBreak +
    '                      <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="15" Foreground="{StaticResource InkBrush}" />' + sLineBreak +
    '                    </Border>' + sLineBreak +
    '                    <StackPanel Grid.Column="1" VerticalAlignment="Center">' + sLineBreak +
    '                      <TextBlock Text="Smart sweep" FontSize="13" FontWeight="SemiBold" Foreground="{StaticResource InkBrush}" />' + sLineBreak +
    '                      <TextBlock Text="Sweep what is left at the end of the month" FontSize="11" TextWrapping="Wrap" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                    <ToggleSwitch x:Name="SweepSwitch" Grid.Column="2" IsOn="{Binding SmartSweep, Mode=TwoWay}" OnContent="" OffContent="" MinWidth="0" AutomationProperties.Name="Smart sweep" />' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '' + sLineBreak +
    '            ' + sLineBreak +
    '            <GridView x:Name="GoalGrid" SelectionMode="None" IsItemClickEnabled="True" Padding="0" AutomationProperties.Name="Goals">' + sLineBreak +
    '              <GridView.ItemTemplate>' + sLineBreak +
    '                <DataTemplate>' + sLineBreak +
    '                  <Grid Width="176" Height="276">' + sLineBreak +
    '                    <Border Style="{StaticResource GlassCard}" CornerRadius="24" Padding="16" Visibility="{Binding IsNewCard, Converter={StaticResource InverseBoolToVisibility}}">' + sLineBreak +
    '                      <Grid RowSpacing="10">' + sLineBreak +
    '                        <Grid.RowDefinitions>' + sLineBreak +
    '                          <RowDefinition Height="Auto" />' + sLineBreak +
    '                          <RowDefinition Height="*" />' + sLineBreak +
    '                          <RowDefinition Height="Auto" />' + sLineBreak +
    '                          <RowDefinition Height="Auto" />' + sLineBreak +
    '                        </Grid.RowDefinitions>' + sLineBreak +
    '                        <Grid>' + sLineBreak +
    '                          <Border Width="34" Height="34" CornerRadius="11" Background="#99FFFFFF" HorizontalAlignment="Left">' + sLineBreak +
    '                            <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="{Binding Glyph}" FontSize="14" Foreground="{StaticResource CoralBrush}" />' + sLineBreak +
    '                          </Border>' + sLineBreak +
    '                          <Border HorizontalAlignment="Right" VerticalAlignment="Center" CornerRadius="9" Padding="8,2" Background="#99FFFFFF">' + sLineBreak +
    '                            <TextBlock Text="{Binding DueText}" FontSize="10" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '                          </Border>' + sLineBreak +
    '                        </Grid>' + sLineBreak +
    '                        <Grid Grid.Row="1" Width="100" Height="100">' + sLineBreak +
    '                          <ProgressRing IsIndeterminate="False" Value="{Binding Percent}" Maximum="100" Width="100" Height="100" Foreground="{StaticResource CoralBrush}" Background="#66FFFFFF" />' + sLineBreak +
    '                          <TextBlock Text="{Binding PercentText}" FontSize="20" FontWeight="SemiBold" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="{StaticResource InkBrush}" />' + sLineBreak +
    '                        </Grid>' + sLineBreak +
    '                        <StackPanel Grid.Row="2" Spacing="2">' + sLineBreak +
    '                          <TextBlock Text="{Binding Name}" FontSize="13" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" Foreground="{StaticResource InkBrush}" />' + sLineBreak +
    '                          <TextBlock Text="{Binding AmountText}" FontSize="11" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '                        </StackPanel>' + sLineBreak +
    '                        <Border Grid.Row="3" CornerRadius="16" Padding="0,7" Background="#CCFFFFFF">' + sLineBreak +
    '                          <StackPanel Orientation="Horizontal" Spacing="6" HorizontalAlignment="Center">' + sLineBreak +
    '                            <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="10" Foreground="{StaticResource InkBrush}" />' + sLineBreak +
    '                            <TextBlock Text="Add money" FontSize="12" Foreground="{StaticResource InkBrush}" />' + sLineBreak +
    '                          </StackPanel>' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                      </Grid>' + sLineBreak +
    '                    </Border>' + sLineBreak +
    '                    <Grid Visibility="{Binding IsNewCard, Converter={StaticResource BoolToVisibility}}">' + sLineBreak +
    '                      <Rectangle RadiusX="24" RadiusY="24" Stroke="#B3FFFFFF" StrokeThickness="1.5" StrokeDashArray="5,4" Fill="#1AFFFFFF" />' + sLineBreak +
    '                      <StackPanel Spacing="10" HorizontalAlignment="Center" VerticalAlignment="Center">' + sLineBreak +
    '                        <Border Width="52" Height="52" CornerRadius="26" Background="#CCFFFFFF" HorizontalAlignment="Center">' + sLineBreak +
    '                          <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="18" Foreground="{StaticResource InkBrush}" />' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                        <TextBlock Text="New goal" FontSize="13" FontWeight="SemiBold" HorizontalAlignment="Center" Foreground="{StaticResource InkBrush}" />' + sLineBreak +
    '                        <TextBlock Text="Start saving for something new" FontSize="11" HorizontalAlignment="Center" Foreground="{StaticResource MutedBrush}" />' + sLineBreak +
    '                      </StackPanel>' + sLineBreak +
    '                    </Grid>' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                </DataTemplate>' + sLineBreak +
    '              </GridView.ItemTemplate>' + sLineBreak +
    '            </GridView>' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </ScrollViewer>' + sLineBreak +
    '      </Border>' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Border Grid.Row="3" Style="{StaticResource GlassCard}" CornerRadius="28" Padding="10,6" Margin="0,0,0,20" HorizontalAlignment="Center">' + sLineBreak +
    '      <StackPanel Orientation="Horizontal" Spacing="4">' + sLineBreak +
    '        <Button Style="{StaticResource TabButton}" Content="Overview" />' + sLineBreak +
    '        <Button Style="{StaticResource TabButton}" Content="Activity" />' + sLineBreak +
    '        <Button Style="{StaticResource TabButton}" Content="Manage" Background="#B3FFFFFF" />' + sLineBreak +
    '        <Button Style="{StaticResource TabButton}" Content="Program" />' + sLineBreak +
    '        <Button Style="{StaticResource TabButton}" Content="Account" />' + sLineBreak +
    '        <Button Style="{StaticResource TabButton}" Content="Reports" />' + sLineBreak +
    '        <Button x:Name="QuickAddButton" Width="40" Height="40" CornerRadius="20" Padding="0" Margin="8,0,0,0" Background="White" BorderThickness="0" ToolTipService.ToolTip="New goal" AutomationPropert' +
    'ies.Name="Add a goal">' + sLineBreak +
    '          <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="14" Foreground="{StaticResource InkBrush}" />' + sLineBreak +
    '        </Button>' + sLineBreak +
    '      </StackPanel>' + sLineBreak +
    '    </Border>' + sLineBreak +
    '  </Grid>' + sLineBreak;

constructor TMainWindowBase.Create;
begin
  inherited;
  // MainWindow.xaml(1): <Window> attributes
  Title := 'Haven - savings and goals';
  Width := 1360;
  Height := 900;
  MinWidth := 980;
  MinHeight := 680;
  ExtendsContentIntoTitleBar := True;
  Center;
  LoadContent(ContentXaml);
  // x:Name elements
  Surface := FindElement<TWinUIGrid>('Surface');
  DragRegion := FindElement<TWinUIGrid>('DragRegion');
  WelcomeText := FindElement<TWinUITextBlock>('WelcomeText');
  AskBox := FindElement<TWinUITextBox>('AskBox');
  NewGoalButton := FindElement<TWinUIButton>('NewGoalButton');
  TotalLabel := FindElement<TWinUITextBlock>('TotalLabel');
  ProgressLabel := FindElement<TWinUITextBlock>('ProgressLabel');
  CurrentMonthBar := FindElement<TWinUIBorder>('CurrentMonthBar');
  AutoSaveLabel := FindElement<TWinUITextBlock>('AutoSaveLabel');
  RoundUpsSwitch := FindElement<TWinUIToggleSwitch>('RoundUpsSwitch');
  PaydaySwitch := FindElement<TWinUIToggleSwitch>('PaydaySwitch');
  SweepSwitch := FindElement<TWinUIToggleSwitch>('SweepSwitch');
  GoalGrid := FindElement<TWinUIGridView>('GoalGrid');
  QuickAddButton := FindElement<TWinUIButton>('QuickAddButton');
  // Event wiring
  // MainWindow.xaml(190): Click="NewGoalClick"
  NewGoalButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('NewGoalClick'));
  // MainWindow.xaml(328): ItemClick="GoalClick"
  GoalGrid.OnItemClick := TWinUIItemClickEventHandler(PublishedMethod('GoalClick'));
  // MainWindow.xaml(396): Click="NewGoalClick"
  QuickAddButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('NewGoalClick'));
end;

procedure TMainWindowBase.SetViewModel(AValue: TMainViewModel);
begin
  FViewModel := AValue;
  DataContext := AValue;
end;

end.
