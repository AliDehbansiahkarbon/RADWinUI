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
  RADWinUI.TabBars,
  RADWinUI.Forms;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TMainWindowBase = class(TWinUIWindow)
  protected
    Root: TWinUIGrid;                        // MainWindow.xaml(14) <Grid>
    Glass: TWinUIBorder;                     // MainWindow.xaml(133) <Border>
    VioletSwatch: TWinUIButton;              // MainWindow.xaml(179) <Button>
    SunsetSwatch: TWinUIButton;              // MainWindow.xaml(182) <Button>
    MintSwatch: TWinUIButton;                // MainWindow.xaml(185) <Button>
    AuroraSwatch: TWinUIButton;              // MainWindow.xaml(188) <Button>
    SpeedText: TWinUITextBlock;              // MainWindow.xaml(196) <TextBlock>
    SpeedSlider: TWinUISlider;               // MainWindow.xaml(198) <Slider>
    LabelsSwitch: TWinUIToggleSwitch;        // MainWindow.xaml(203) <ToggleSwitch>
    TourSwitch: TWinUIToggleSwitch;          // MainWindow.xaml(207) <ToggleSwitch>
    GlassText: TWinUITextBlock;              // MainWindow.xaml(212) <TextBlock>
    TransparencySwitch: TWinUIToggleSwitch;  // MainWindow.xaml(215) <ToggleSwitch>
    GlassSlider: TWinUISlider;               // MainWindow.xaml(217) <Slider>
    PillHome: TWinUIStackPanel;              // MainWindow.xaml(255) <StackPanel>
    PillSearch: TWinUIStackPanel;            // MainWindow.xaml(260) <StackPanel>
    PillLikes: TWinUIStackPanel;             // MainWindow.xaml(265) <StackPanel>
    PillProfile: TWinUIStackPanel;           // MainWindow.xaml(270) <StackPanel>
    PillBar: TWinUISlidingPillTabBar;        // MainWindow.xaml(276) <SlidingPillTabBar>
    BulgeListen: TWinUIStackPanel;           // MainWindow.xaml(301) <StackPanel>
    BulgeExplore: TWinUIStackPanel;          // MainWindow.xaml(306) <StackPanel>
    BulgeLibrary: TWinUIStackPanel;          // MainWindow.xaml(311) <StackPanel>
    BulgeMe: TWinUIStackPanel;               // MainWindow.xaml(316) <StackPanel>
    BulgeBar: TWinUILiquidBulgeTabBar;       // MainWindow.xaml(322) <LiquidBulgeTabBar>
    NotchShop: TWinUIStackPanel;             // MainWindow.xaml(347) <StackPanel>
    NotchCart: TWinUIStackPanel;             // MainWindow.xaml(352) <StackPanel>
    NotchSaved: TWinUIStackPanel;            // MainWindow.xaml(357) <StackPanel>
    NotchAccount: TWinUIStackPanel;          // MainWindow.xaml(362) <StackPanel>
    NotchBar: TWinUIFloatingNotchTabBar;     // MainWindow.xaml(368) <FloatingNotchTabBar>
    FillFeed: TWinUIStackPanel;              // MainWindow.xaml(393) <StackPanel>
    FillChat: TWinUIStackPanel;              // MainWindow.xaml(398) <StackPanel>
    FillLikes: TWinUIStackPanel;             // MainWindow.xaml(403) <StackPanel>
    FillProfile: TWinUIStackPanel;           // MainWindow.xaml(408) <StackPanel>
    FillBar: TWinUIIconFillTabBar;           // MainWindow.xaml(414) <IconFillTabBar>
    LabelExplore: TWinUIStackPanel;          // MainWindow.xaml(439) <StackPanel>
    LabelTrips: TWinUIStackPanel;            // MainWindow.xaml(444) <StackPanel>
    LabelSaved: TWinUIStackPanel;            // MainWindow.xaml(449) <StackPanel>
    LabelProfile: TWinUIStackPanel;          // MainWindow.xaml(454) <StackPanel>
    LabelBar: TWinUIExpandingLabelTabBar;    // MainWindow.xaml(460) <ExpandingLabelTabBar>
    BubblePhotos: TWinUIStackPanel;          // MainWindow.xaml(485) <StackPanel>
    BubbleAlbums: TWinUIStackPanel;          // MainWindow.xaml(490) <StackPanel>
    BubbleCamera: TWinUIStackPanel;          // MainWindow.xaml(495) <StackPanel>
    BubbleSettings: TWinUIStackPanel;        // MainWindow.xaml(500) <StackPanel>
    BubbleBar: TWinUIBubbleFloatTabBar;      // MainWindow.xaml(506) <BubbleFloatTabBar>
    StatusDot: TWinUIEllipse;                // MainWindow.xaml(521) <Ellipse>
    StatusText: TWinUITextBlock;             // MainWindow.xaml(522) <TextBlock>
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
  // MainWindow.xaml(14): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:ns2="using:RADWinUI.Controls" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="Root" Background="Transparent' +
    '">' + sLineBreak +
    '    <Grid.Resources>' + sLineBreak +
    '      <ResourceDictionary>' + sLineBreak +
    '        <ResourceDictionary.ThemeDictionaries>' + sLineBreak +
    '          <ResourceDictionary x:Key="Light">' + sLineBreak +
    '            <SolidColorBrush x:Key="PageBrush" Color="#F3F2F7" />' + sLineBreak +
    '            <SolidColorBrush x:Key="CardBrush" Color="#E6FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="CardEdgeBrush" Color="#14000000" />' + sLineBreak +
    '            <SolidColorBrush x:Key="ScreenBrush" Color="#F3F2F8" />' + sLineBreak +
    '            <SolidColorBrush x:Key="DiscBrush" Color="#E6E3F3" />' + sLineBreak +
    '            <SolidColorBrush x:Key="InkBrush" Color="#1B1829" />' + sLineBreak +
    '            <SolidColorBrush x:Key="MutedBrush" Color="#5E5A72" />' + sLineBreak +
    '            <SolidColorBrush x:Key="FaintBrush" Color="#85819A" />' + sLineBreak +
    '            <SolidColorBrush x:Key="PageIconBrush" Color="#4A3CC4" />' + sLineBreak +
    '            <SolidColorBrush x:Key="ChipBrush" Color="#ECEAF4" />' + sLineBreak +
    '            <SolidColorBrush x:Key="BarBrush" Color="#FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="BarEdgeBrush" Color="#E1DEEB" />' + sLineBreak +
    '            <SolidColorBrush x:Key="BarIconBrush" Color="#8A86A0" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SwatchEdgeBrush" Color="#D9D6E4" />' + sLineBreak +
    '            <Color x:Key="GlowColorA">#306C55FF</Color>' + sLineBreak +
    '            <Color x:Key="GlowColorB">#2A3CC8FF</Color>' + sLineBreak +
    '          </ResourceDictionary>' + sLineBreak +
    '          <ResourceDictionary x:Key="Dark">' + sLineBreak +
    '            <SolidColorBrush x:Key="PageBrush" Color="#0E0D15" />' + sLineBreak +
    '            <SolidColorBrush x:Key="CardBrush" Color="#E615131F" />' + sLineBreak +
    '            <SolidColorBrush x:Key="CardEdgeBrush" Color="#25222F" />' + sLineBreak +
    '            <SolidColorBrush x:Key="ScreenBrush" Color="#100E17" />' + sLineBreak +
    '            <SolidColorBrush x:Key="DiscBrush" Color="#221F31" />' + sLineBreak +
    '            <SolidColorBrush x:Key="InkBrush" Color="#FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="MutedBrush" Color="#9A96B0" />' + sLineBreak +
    '            <SolidColorBrush x:Key="FaintBrush" Color="#77738C" />' + sLineBreak +
    '            <SolidColorBrush x:Key="PageIconBrush" Color="#E8E5FA" />' + sLineBreak +
    '            <SolidColorBrush x:Key="ChipBrush" Color="#1F1C2C" />' + sLineBreak +
    '            <SolidColorBrush x:Key="BarBrush" Color="#1B1829" />' + sLineBreak +
    '            <SolidColorBrush x:Key="BarEdgeBrush" Color="#2E2A40" />' + sLineBreak +
    '            <SolidColorBrush x:Key="BarIconBrush" Color="#A7A3BC" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SwatchEdgeBrush" Color="#2E2A3D" />' + sLineBreak +
    '            <Color x:Key="GlowColorA">#486C55FF</Color>' + sLineBreak +
    '            <Color x:Key="GlowColorB">#363CC8FF</Color>' + sLineBreak +
    '          </ResourceDictionary>' + sLineBreak +
    '        </ResourceDictionary.ThemeDictionaries>' + sLineBreak +
    '        <Style x:Key="Card" TargetType="Border">' + sLineBreak +
    '          <Setter Property="Background" Value="{ThemeResource CardBrush}" />' + sLineBreak +
    '          <Setter Property="BorderBrush" Value="{ThemeResource CardEdgeBrush}" />' + sLineBreak +
    '          <Setter Property="BorderThickness" Value="1" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="24" />' + sLineBreak +
    '          <Setter Property="Padding" Value="18,16,18,16" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="Screen" TargetType="Grid">' + sLineBreak +
    '          <Setter Property="Background" Value="{ThemeResource ScreenBrush}" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="16" />' + sLineBreak +
    '          <Setter Property="MinHeight" Value="150" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="Page" TargetType="StackPanel">' + sLineBreak +
    '          <Setter Property="Spacing" Value="6" />' + sLineBreak +
    '          <Setter Property="HorizontalAlignment" Value="Center" />' + sLineBreak +
    '          <Setter Property="VerticalAlignment" Value="Center" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="Disc" TargetType="Border">' + sLineBreak +
    '          <Setter Property="Width" Value="54" />' + sLineBreak +
    '          <Setter Property="Height" Value="54" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="27" />' + sLineBreak +
    '          <Setter Property="Background" Value="{ThemeResource DiscBrush}" />' + sLineBreak +
    '          <Setter Property="HorizontalAlignment" Value="Center" />' + sLineBreak +
    '          <Setter Property="Margin" Value="0,0,0,4" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="PageIcon" TargetType="FontIcon">' + sLineBreak +
    '          <Setter Property="FontSize" Value="24" />' + sLineBreak +
    '          <Setter Property="Foreground" Value="{ThemeResource PageIconBrush}" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="PageTitle" TargetType="TextBlock">' + sLineBreak +
    '          <Setter Property="FontSize" Value="16" />' + sLineBreak +
    '          <Setter Property="FontWeight" Value="SemiBold" />' + sLineBreak +
    '          <Setter Property="Foreground" Value="{ThemeResource InkBrush}" />' + sLineBreak +
    '          <Setter Property="HorizontalAlignment" Value="Center" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="PageText" TargetType="TextBlock">' + sLineBreak +
    '          <Setter Property="FontSize" Value="12.5" />' + sLineBreak +
    '          <Setter Property="Foreground" Value="{ThemeResource MutedBrush}" />' + sLineBreak +
    '          <Setter Property="HorizontalAlignment" Value="Center" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="CardTitle" TargetType="TextBlock">' + sLineBreak +
    '          <Setter Property="FontSize" Value="16" />' + sLineBreak +
    '          <Setter Property="FontWeight" Value="SemiBold" />' + sLineBreak +
    '          <Setter Property="Foreground" Value="{ThemeResource InkBrush}" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="CardClass" TargetType="TextBlock">' + sLineBreak +
    '          <Setter Property="FontFamily" Value="Cascadia Mono, Consolas" />' + sLineBreak +
    '          <Setter Property="FontSize" Value="11.5" />' + sLineBreak +
    '          <Setter Property="Foreground" Value="{ThemeResource FaintBrush}" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="Chip" TargetType="Border">' + sLineBreak +
    '          <Setter Property="Background" Value="{ThemeResource ChipBrush}" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="11" />' + sLineBreak +
    '          <Setter Property="Padding" Value="10,3,10,4" />' + sLineBreak +
    '          <Setter Property="VerticalAlignment" Value="Top" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="ChipText" TargetType="TextBlock">' + sLineBreak +
    '          <Setter Property="FontSize" Value="11.5" />' + sLineBreak +
    '          <Setter Property="Foreground" Value="{ThemeResource MutedBrush}" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="Caption" TargetType="TextBlock">' + sLineBreak +
    '          <Setter Property="FontSize" Value="11" />' + sLineBreak +
    '          <Setter Property="FontWeight" Value="SemiBold" />' + sLineBreak +
    '          <Setter Property="CharacterSpacing" Value="80" />' + sLineBreak +
    '          <Setter Property="Foreground" Value="{ThemeResource FaintBrush}" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="Swatch" TargetType="Button">' + sLineBreak +
    '          <Setter Property="Width" Value="30" />' + sLineBreak +
    '          <Setter Property="Height" Value="30" />' + sLineBreak +
    '          <Setter Property="Padding" Value="0" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="15" />' + sLineBreak +
    '          <Setter Property="BorderThickness" Value="2" />' + sLineBreak +
    '          <Setter Property="BorderBrush" Value="{ThemeResource SwatchEdgeBrush}" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '      </ResourceDictionary>' + sLineBreak +
    '    </Grid.Resources>' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Border x:Name="Glass" Background="{ThemeResource PageBrush}" CornerRadius="8" Opacity="0.65" />' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Ellipse Width="820" Height="820" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="-240,-320,0,0" IsHitTestVisible="False">' + sLineBreak +
    '      <Ellipse.Fill>' + sLineBreak +
    '        <RadialGradientBrush>' + sLineBreak +
    '          <GradientStop Color="{ThemeResource GlowColorA}" Offset="0" />' + sLineBreak +
    '          <GradientStop Color="#006C55FF" Offset="1" />' + sLineBreak +
    '        </RadialGradientBrush>' + sLineBreak +
    '      </Ellipse.Fill>' + sLineBreak +
    '    </Ellipse>' + sLineBreak +
    '    <Ellipse Width="900" Height="900" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,-280,-360" IsHitTestVisible="False">' + sLineBreak +
    '      <Ellipse.Fill>' + sLineBreak +
    '        <RadialGradientBrush>' + sLineBreak +
    '          <GradientStop Color="{ThemeResource GlowColorB}" Offset="0" />' + sLineBreak +
    '          <GradientStop Color="#003CC8FF" Offset="1" />' + sLineBreak +
    '        </RadialGradientBrush>' + sLineBreak +
    '      </Ellipse.Fill>' + sLineBreak +
    '    </Ellipse>' + sLineBreak +
    '' + sLineBreak +
    '    <ScrollViewer>' + sLineBreak +
    '      <Grid Padding="40,40,40,28" RowSpacing="24" MaxWidth="1300">' + sLineBreak +
    '        <Grid.RowDefinitions>' + sLineBreak +
    '          <RowDefinition Height="Auto" />' + sLineBreak +
    '          <RowDefinition Height="Auto" />' + sLineBreak +
    '          <RowDefinition Height="Auto" />' + sLineBreak +
    '        </Grid.RowDefinitions>' + sLineBreak +
    '' + sLineBreak +
    '        ' + sLineBreak +
    '        <Grid ColumnSpacing="24">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <StackPanel Spacing="6" VerticalAlignment="Center">' + sLineBreak +
    '            <Border Style="{StaticResource Chip}" HorizontalAlignment="Left">' + sLineBreak +
    '              <TextBlock Style="{StaticResource ChipText}" Text="RADWinUI  ·  Tool Palette  ·  Tab Bars" />' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <TextBlock Text="Six tab bars, ready to drop in" FontSize="32" FontWeight="SemiBold" Foreground="{ThemeResource InkBrush}" />' + sLineBreak +
    '            <TextBlock Text="Set Items in the Object Inspector, point Pages at your views, and the bar does the rest. Tap any tab." FontSize="14" Foreground="{ThemeResource MutedBrush}" TextWrapping="' +
    'Wrap" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '          <Border Grid.Column="1" Style="{StaticResource Card}" Padding="20,14,20,14" VerticalAlignment="Center">' + sLineBreak +
    '            <StackPanel Orientation="Horizontal" Spacing="26">' + sLineBreak +
    '              <StackPanel Spacing="8">' + sLineBreak +
    '                <TextBlock Style="{StaticResource Caption}" Text="ACCENT" />' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                  <Button x:Name="VioletSwatch" Style="{StaticResource Swatch}" ToolTipService.ToolTip="Violet to cyan" AutomationProperties.Name="Violet">' + sLineBreak +
    '                    <Ellipse Width="22" Height="22"><Ellipse.Fill><LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#6C55FF" Offset="0" /><GradientStop Color="#3CC8FF" Offset="' +
    '1" /></LinearGradientBrush></Ellipse.Fill></Ellipse>' + sLineBreak +
    '                  </Button>' + sLineBreak +
    '                  <Button x:Name="SunsetSwatch" Style="{StaticResource Swatch}" ToolTipService.ToolTip="Sunset" AutomationProperties.Name="Sunset">' + sLineBreak +
    '                    <Ellipse Width="22" Height="22"><Ellipse.Fill><LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#FF5F6D" Offset="0" /><GradientStop Color="#FFC371" Offset="' +
    '1" /></LinearGradientBrush></Ellipse.Fill></Ellipse>' + sLineBreak +
    '                  </Button>' + sLineBreak +
    '                  <Button x:Name="MintSwatch" Style="{StaticResource Swatch}" ToolTipService.ToolTip="Mint" AutomationProperties.Name="Mint">' + sLineBreak +
    '                    <Ellipse Width="22" Height="22"><Ellipse.Fill><LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#11B98E" Offset="0" /><GradientStop Color="#7CF29A" Offset="' +
    '1" /></LinearGradientBrush></Ellipse.Fill></Ellipse>' + sLineBreak +
    '                  </Button>' + sLineBreak +
    '                  <Button x:Name="AuroraSwatch" Style="{StaticResource Swatch}" ToolTipService.ToolTip="Aurora" AutomationProperties.Name="Aurora">' + sLineBreak +
    '                    <Ellipse Width="22" Height="22"><Ellipse.Fill><LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#A23CF5" Offset="0" /><GradientStop Color="#FF6CAB" Offset="' +
    '1" /></LinearGradientBrush></Ellipse.Fill></Ellipse>' + sLineBreak +
    '                  </Button>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <StackPanel Spacing="2">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                  <TextBlock Style="{StaticResource Caption}" Text="SPEED" />' + sLineBreak +
    '                  <TextBlock x:Name="SpeedText" Style="{StaticResource Caption}" Foreground="{ThemeResource MutedBrush}" Text="500 ms" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <Slider x:Name="SpeedSlider" Width="150" Minimum="200" Maximum="1500" StepFrequency="50" Value="500" AutomationProperties.Name="Speed" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <StackPanel Spacing="2">' + sLineBreak +
    '                <TextBlock Style="{StaticResource Caption}" Text="LABELS" />' + sLineBreak +
    '                <ToggleSwitch x:Name="LabelsSwitch" OnContent="" OffContent="" MinWidth="0" AutomationProperties.Name="Labels" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <StackPanel Spacing="2">' + sLineBreak +
    '                <TextBlock Style="{StaticResource Caption}" Text="TOUR" />' + sLineBreak +
    '                <ToggleSwitch x:Name="TourSwitch" OnContent="" OffContent="" MinWidth="0" AutomationProperties.Name="Tour" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <StackPanel Spacing="2">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                  <TextBlock Style="{StaticResource Caption}" Text="TRANSPARENCY" />' + sLineBreak +
    '                  <TextBlock x:Name="GlassText" Style="{StaticResource Caption}" Foreground="{ThemeResource MutedBrush}" Text="35%" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="10">' + sLineBreak +
    '                  <ToggleSwitch x:Name="TransparencySwitch" OnContent="" OffContent="" MinWidth="0" IsOn="True" AutomationProperties.Name="Transparency" />' + sLineBreak +
    '                  <Slider x:Name="GlassSlider" Width="110" Minimum="0" Maximum="90" StepFrequency="5" Value="35" AutomationProperties.Name="Transparency level" VerticalAlignment="Center" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '' + sLineBreak +
    '        ' + sLineBreak +
    '        <Grid Grid.Row="1" ColumnSpacing="20" RowSpacing="20">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition />' + sLineBreak +
    '            <ColumnDefinition />' + sLineBreak +
    '            <ColumnDefinition />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <Grid.RowDefinitions>' + sLineBreak +
    '            <RowDefinition />' + sLineBreak +
    '            <RowDefinition />' + sLineBreak +
    '          </Grid.RowDefinitions>' + sLineBreak +
    '' + sLineBreak +
    '          ' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="0" Style="{StaticResource Card}">' + sLineBreak +
    '            <Grid RowSpacing="14">' + sLineBreak +
    '              <Grid.RowDefinitions>' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="*" />' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '              </Grid.RowDefinitions>' + sLineBreak +
    '              <Grid>' + sLineBreak +
    '                <StackPanel Spacing="1">' + sLineBreak +
    '                  <TextBlock Style="{StaticResource CardTitle}" Text="Sliding Pill" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource CardClass}" Text="TWinUISlidingPillTabBar" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <Border Style="{StaticResource Chip}" HorizontalAlignment="Right">' + sLineBreak +
    '                  <TextBlock Style="{StaticResource ChipText}" Text="Social" />' + sLineBreak +
    '                </Border>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <Grid Grid.Row="1" Style="{StaticResource Screen}">' + sLineBreak +
    '                <StackPanel x:Name="PillHome" Style="{StaticResource Page}">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Good morning" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="Three new posts since yesterday" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <StackPanel x:Name="PillSearch" Style="{StaticResource Page}" Visibility="Collapsed">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Search" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="Find people, places and posts" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <StackPanel x:Name="PillLikes" Style="{StaticResource Page}" Visibility="Collapsed">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Likes" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="128 people liked your photo" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <StackPanel x:Name="PillProfile" Style="{StaticResource Page}" Visibility="Collapsed">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Profile" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="Edit your name and photo" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <ns2:SlidingPillTabBar x:Name="PillBar" AutomationProperties.Name="Social sections" Grid.Row="2" Width="Auto" HorizontalAlignment="Stretch" Background="{ThemeResource BarBrush}" BorderBr' +
    'ush="{ThemeResource BarEdgeBrush}" Foreground="{ThemeResource BarIconBrush}" Items="Home:Home, Search:Search, Likes:Heart, Profile:Contact" Pages="PillHome, PillSearch, PillLikes, PillProfile" />' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '' + sLineBreak +
    '          ' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <Grid RowSpacing="14">' + sLineBreak +
    '              <Grid.RowDefinitions>' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="*" />' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '              </Grid.RowDefinitions>' + sLineBreak +
    '              <Grid>' + sLineBreak +
    '                <StackPanel Spacing="1">' + sLineBreak +
    '                  <TextBlock Style="{StaticResource CardTitle}" Text="Liquid Bulge" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource CardClass}" Text="TWinUILiquidBulgeTabBar" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <Border Style="{StaticResource Chip}" HorizontalAlignment="Right">' + sLineBreak +
    '                  <TextBlock Style="{StaticResource ChipText}" Text="Music" />' + sLineBreak +
    '                </Border>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <Grid Grid.Row="1" Style="{StaticResource Screen}">' + sLineBreak +
    '                <StackPanel x:Name="BulgeListen" Style="{StaticResource Page}">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Now playing" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="Night Drive, 3:42 left" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <StackPanel x:Name="BulgeExplore" Style="{StaticResource Page}" Visibility="Collapsed">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Explore" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="New releases every Friday" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <StackPanel x:Name="BulgeLibrary" Style="{StaticResource Page}" Visibility="Collapsed">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Library" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="24 playlists, 312 songs" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <StackPanel x:Name="BulgeMe" Style="{StaticResource Page}" Visibility="Collapsed">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Your music" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="Listening stats and settings" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <ns2:LiquidBulgeTabBar x:Name="BulgeBar" AutomationProperties.Name="Music sections" Grid.Row="2" Width="Auto" HorizontalAlignment="Stretch" Background="{ThemeResource BarBrush}" BorderBr' +
    'ush="{ThemeResource BarEdgeBrush}" Foreground="{ThemeResource BarIconBrush}" Items="Listen:Music, Explore:Globe, Library:Library, Me:Contact" Pages="BulgeListen, BulgeExplore, BulgeLibrary, BulgeMe" /' +
    '>' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '' + sLineBreak +
    '          ' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="2" Style="{StaticResource Card}">' + sLineBreak +
    '            <Grid RowSpacing="14">' + sLineBreak +
    '              <Grid.RowDefinitions>' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="*" />' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '              </Grid.RowDefinitions>' + sLineBreak +
    '              <Grid>' + sLineBreak +
    '                <StackPanel Spacing="1">' + sLineBreak +
    '                  <TextBlock Style="{StaticResource CardTitle}" Text="Floating Notch" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource CardClass}" Text="TWinUIFloatingNotchTabBar" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <Border Style="{StaticResource Chip}" HorizontalAlignment="Right">' + sLineBreak +
    '                  <TextBlock Style="{StaticResource ChipText}" Text="Shop" />' + sLineBreak +
    '                </Border>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <Grid Grid.Row="1" Style="{StaticResource Screen}">' + sLineBreak +
    '                <StackPanel x:Name="NotchShop" Style="{StaticResource Page}">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Today''s deals" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="Up to 40% off headphones" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <StackPanel x:Name="NotchCart" Style="{StaticResource Page}" Visibility="Collapsed">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Cart" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="Two items, ready to check out" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <StackPanel x:Name="NotchSaved" Style="{StaticResource Page}" Visibility="Collapsed">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Saved" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="Back in stock: the Aurora lamp" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <StackPanel x:Name="NotchAccount" Style="{StaticResource Page}" Visibility="Collapsed">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Account" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="Orders, addresses and payment" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <ns2:FloatingNotchTabBar x:Name="NotchBar" AutomationProperties.Name="Shop sections" Grid.Row="2" Width="Auto" HorizontalAlignment="Stretch" Background="{ThemeResource BarBrush}" BorderB' +
    'rush="{ThemeResource BarEdgeBrush}" Foreground="{ThemeResource BarIconBrush}" Items="Shop:Shop, Cart:Cart, Saved:Heart, Account:Contact" Pages="NotchShop, NotchCart, NotchSaved, NotchAccount" />' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '' + sLineBreak +
    '          ' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="0" Style="{StaticResource Card}">' + sLineBreak +
    '            <Grid RowSpacing="14">' + sLineBreak +
    '              <Grid.RowDefinitions>' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="*" />' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '              </Grid.RowDefinitions>' + sLineBreak +
    '              <Grid>' + sLineBreak +
    '                <StackPanel Spacing="1">' + sLineBreak +
    '                  <TextBlock Style="{StaticResource CardTitle}" Text="Icon Fill" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource CardClass}" Text="TWinUIIconFillTabBar" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <Border Style="{StaticResource Chip}" HorizontalAlignment="Right">' + sLineBreak +
    '                  <TextBlock Style="{StaticResource ChipText}" Text="Chat" />' + sLineBreak +
    '                </Border>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <Grid Grid.Row="1" Style="{StaticResource Screen}">' + sLineBreak +
    '                <StackPanel x:Name="FillFeed" Style="{StaticResource Page}">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Feed" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="Catch up with your friends" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <StackPanel x:Name="FillChat" Style="{StaticResource Page}" Visibility="Collapsed">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Chat" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="Mina: see you at eight?" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <StackPanel x:Name="FillLikes" Style="{StaticResource Page}" Visibility="Collapsed">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Likes" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="Your post got 56 hearts" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <StackPanel x:Name="FillProfile" Style="{StaticResource Page}" Visibility="Collapsed">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Profile" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="1.2k followers" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <ns2:IconFillTabBar x:Name="FillBar" AutomationProperties.Name="Chat sections" Grid.Row="2" Width="Auto" HorizontalAlignment="Stretch" Background="{ThemeResource BarBrush}" BorderBrush="' +
    '{ThemeResource BarEdgeBrush}" Foreground="{ThemeResource BarIconBrush}" Items="Feed:Home, Chat:Chat, Likes:Heart, Profile:Contact" Pages="FillFeed, FillChat, FillLikes, FillProfile" />' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '' + sLineBreak +
    '          ' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <Grid RowSpacing="14">' + sLineBreak +
    '              <Grid.RowDefinitions>' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="*" />' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '              </Grid.RowDefinitions>' + sLineBreak +
    '              <Grid>' + sLineBreak +
    '                <StackPanel Spacing="1">' + sLineBreak +
    '                  <TextBlock Style="{StaticResource CardTitle}" Text="Expanding Label" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource CardClass}" Text="TWinUIExpandingLabelTabBar" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <Border Style="{StaticResource Chip}" HorizontalAlignment="Right">' + sLineBreak +
    '                  <TextBlock Style="{StaticResource ChipText}" Text="Travel" />' + sLineBreak +
    '                </Border>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <Grid Grid.Row="1" Style="{StaticResource Screen}">' + sLineBreak +
    '                <StackPanel x:Name="LabelExplore" Style="{StaticResource Page}">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Explore" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="Weekend ideas near you" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <StackPanel x:Name="LabelTrips" Style="{StaticResource Page}" Visibility="Collapsed">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Trips" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="Lisbon in 12 days" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <StackPanel x:Name="LabelSaved" Style="{StaticResource Page}" Visibility="Collapsed">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Saved" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="Nine places on your list" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <StackPanel x:Name="LabelProfile" Style="{StaticResource Page}" Visibility="Collapsed">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Profile" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="Passport and preferences" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <ns2:ExpandingLabelTabBar x:Name="LabelBar" AutomationProperties.Name="Travel sections" Grid.Row="2" Width="Auto" HorizontalAlignment="Stretch" Background="{ThemeResource BarBrush}" Bord' +
    'erBrush="{ThemeResource BarEdgeBrush}" Foreground="{ThemeResource BarIconBrush}" Items="Explore:Globe, Trips:Airplane, Saved:Star, Profile:Contact" Pages="LabelExplore, LabelTrips, LabelSaved, LabelPr' +
    'ofile" />' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '' + sLineBreak +
    '          ' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="2" Style="{StaticResource Card}">' + sLineBreak +
    '            <Grid RowSpacing="14">' + sLineBreak +
    '              <Grid.RowDefinitions>' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="*" />' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '              </Grid.RowDefinitions>' + sLineBreak +
    '              <Grid>' + sLineBreak +
    '                <StackPanel Spacing="1">' + sLineBreak +
    '                  <TextBlock Style="{StaticResource CardTitle}" Text="Bubble Float" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource CardClass}" Text="TWinUIBubbleFloatTabBar" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <Border Style="{StaticResource Chip}" HorizontalAlignment="Right">' + sLineBreak +
    '                  <TextBlock Style="{StaticResource ChipText}" Text="Photos" />' + sLineBreak +
    '                </Border>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <Grid Grid.Row="1" Style="{StaticResource Screen}">' + sLineBreak +
    '                <StackPanel x:Name="BubblePhotos" Style="{StaticResource Page}">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Photos" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="1,284 photos and videos" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <StackPanel x:Name="BubbleAlbums" Style="{StaticResource Page}" Visibility="Collapsed">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Albums" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="Summer, Family, Screenshots" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <StackPanel x:Name="BubbleCamera" Style="{StaticResource Page}" Visibility="Collapsed">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Camera" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="Tap to take a photo" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <StackPanel x:Name="BubbleSettings" Style="{StaticResource Page}" Visibility="Collapsed">' + sLineBreak +
    '                  <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource PageIcon}" Glyph="" /></Border>' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageTitle}" Text="Settings" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource PageText}" Text="Backup is on" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <ns2:BubbleFloatTabBar x:Name="BubbleBar" AutomationProperties.Name="Photo sections" Grid.Row="2" Width="Auto" HorizontalAlignment="Stretch" Background="{ThemeResource BarBrush}" BorderB' +
    'rush="{ThemeResource BarEdgeBrush}" Foreground="{ThemeResource BarIconBrush}" BubbleCount="9" Items="Photos:Photo, Albums:Folder, Camera:Camera, Settings:Settings" Pages="BubblePhotos, BubbleAlbums, B' +
    'ubbleCamera, BubbleSettings" />' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '' + sLineBreak +
    '        ' + sLineBreak +
    '        <Grid Grid.Row="2" ColumnSpacing="20">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="10" VerticalAlignment="Center">' + sLineBreak +
    '            <Ellipse x:Name="StatusDot" Width="8" Height="8" Fill="#3CC8FF" VerticalAlignment="Center" />' + sLineBreak +
    '            <TextBlock x:Name="StatusText" FontSize="13" Foreground="{ThemeResource MutedBrush}" VerticalAlignment="Center" Text="Tap a tab, or turn on the tour. SelectionChanged reports every change ' +
    'here." />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '          <Border Grid.Column="1" Style="{StaticResource Chip}" Padding="14,6,14,7">' + sLineBreak +
    '            <TextBlock Style="{StaticResource CardClass}" Foreground="{ThemeResource MutedBrush}" Text="&lt;rw:SlidingPillTabBar Items=&quot;Home:Home, Search:Search&quot; Pages=&quot;HomePage, Search' +
    'Page&quot;/&gt;" />' + sLineBreak +
    '          </Border>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </Grid>' + sLineBreak +
    '    </ScrollViewer>' + sLineBreak +
    '  </Grid>' + sLineBreak;
  {$IFDEF DEBUG}
  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild
  XamlShape = 'F:Root:TWinUIGrid;F:Glass:TWinUIBorder;F:VioletSwatch:TWinUIButton;F:SunsetSwatch:TWinUIButton;F:MintSwatch:TWinUIButton;F:AuroraSwatch:TWinUIButton;F:SpeedText:TWinUITextBlock;F:SpeedSlider:TWinUISli' +
    'der;F:LabelsSwitch:TWinUIToggleSwitch;F:TourSwitch:TWinUIToggleSwitch;F:GlassText:TWinUITextBlock;F:TransparencySwitch:TWinUIToggleSwitch;F:GlassSlider:TWinUISlider;F:PillHome:TWinUIStackPanel;F:PillS' +
    'earch:TWinUIStackPanel;F:PillLikes:TWinUIStackPanel;F:PillProfile:TWinUIStackPanel;F:PillBar:TWinUISlidingPillTabBar;F:BulgeListen:TWinUIStackPanel;F:BulgeExplore:TWinUIStackPanel;F:BulgeLibrary:TWinU' +
    'IStackPanel;F:BulgeMe:TWinUIStackPanel;F:BulgeBar:TWinUILiquidBulgeTabBar;F:NotchShop:TWinUIStackPanel;F:NotchCart:TWinUIStackPanel;F:NotchSaved:TWinUIStackPanel;F:NotchAccount:TWinUIStackPanel;F:Notc' +
    'hBar:TWinUIFloatingNotchTabBar;F:FillFeed:TWinUIStackPanel;F:FillChat:TWinUIStackPanel;F:FillLikes:TWinUIStackPanel;F:FillProfile:TWinUIStackPanel;F:FillBar:TWinUIIconFillTabBar;F:LabelExplore:TWinUIS' +
    'tackPanel;F:LabelTrips:TWinUIStackPanel;F:LabelSaved:TWinUIStackPanel;F:LabelProfile:TWinUIStackPanel;F:LabelBar:TWinUIExpandingLabelTabBar;F:BubblePhotos:TWinUIStackPanel;F:BubbleAlbums:TWinUIStackPa' +
    'nel;F:BubbleCamera:TWinUIStackPanel;F:BubbleSettings:TWinUIStackPanel;F:BubbleBar:TWinUIBubbleFloatTabBar;F:StatusDot:TWinUIEllipse;F:StatusText:TWinUITextBlock;E:AuroraSwatch.Click=AuroraClick;E:Bubb' +
    'leBar.SelectionChanged=TabChanged;E:BulgeBar.SelectionChanged=TabChanged;E:FillBar.SelectionChanged=TabChanged;E:GlassSlider.ValueChanged=GlassChanged;E:LabelBar.SelectionChanged=TabChanged;E:LabelsSw' +
    'itch.Toggled=LabelsToggled;E:MintSwatch.Click=MintClick;E:NotchBar.SelectionChanged=TabChanged;E:PillBar.SelectionChanged=TabChanged;E:SpeedSlider.ValueChanged=SpeedChanged;E:SunsetSwatch.Click=Sunset' +
    'Click;E:TourSwitch.Toggled=TourToggled;E:TransparencySwitch.Toggled=TransparencyToggled;E:VioletSwatch.Click=VioletClick';
  {$ENDIF}

constructor TMainWindowBase.Create;
begin
  inherited;
  // MainWindow.xaml(1): <Window> attributes
  Title := 'Tab Bars';
  Width := 1240;
  Height := 900;
  MinWidth := 1080;
  MinHeight := 720;
  Backdrop := TWinUIBackdrop.Transparent;
  ExtendsContentIntoTitleBar := True;
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
  Glass := FindElement<TWinUIBorder>('Glass');
  VioletSwatch := FindElement<TWinUIButton>('VioletSwatch');
  SunsetSwatch := FindElement<TWinUIButton>('SunsetSwatch');
  MintSwatch := FindElement<TWinUIButton>('MintSwatch');
  AuroraSwatch := FindElement<TWinUIButton>('AuroraSwatch');
  SpeedText := FindElement<TWinUITextBlock>('SpeedText');
  SpeedSlider := FindElement<TWinUISlider>('SpeedSlider');
  LabelsSwitch := FindElement<TWinUIToggleSwitch>('LabelsSwitch');
  TourSwitch := FindElement<TWinUIToggleSwitch>('TourSwitch');
  GlassText := FindElement<TWinUITextBlock>('GlassText');
  TransparencySwitch := FindElement<TWinUIToggleSwitch>('TransparencySwitch');
  GlassSlider := FindElement<TWinUISlider>('GlassSlider');
  PillHome := FindElement<TWinUIStackPanel>('PillHome');
  PillSearch := FindElement<TWinUIStackPanel>('PillSearch');
  PillLikes := FindElement<TWinUIStackPanel>('PillLikes');
  PillProfile := FindElement<TWinUIStackPanel>('PillProfile');
  PillBar := FindElement<TWinUISlidingPillTabBar>('PillBar');
  BulgeListen := FindElement<TWinUIStackPanel>('BulgeListen');
  BulgeExplore := FindElement<TWinUIStackPanel>('BulgeExplore');
  BulgeLibrary := FindElement<TWinUIStackPanel>('BulgeLibrary');
  BulgeMe := FindElement<TWinUIStackPanel>('BulgeMe');
  BulgeBar := FindElement<TWinUILiquidBulgeTabBar>('BulgeBar');
  NotchShop := FindElement<TWinUIStackPanel>('NotchShop');
  NotchCart := FindElement<TWinUIStackPanel>('NotchCart');
  NotchSaved := FindElement<TWinUIStackPanel>('NotchSaved');
  NotchAccount := FindElement<TWinUIStackPanel>('NotchAccount');
  NotchBar := FindElement<TWinUIFloatingNotchTabBar>('NotchBar');
  FillFeed := FindElement<TWinUIStackPanel>('FillFeed');
  FillChat := FindElement<TWinUIStackPanel>('FillChat');
  FillLikes := FindElement<TWinUIStackPanel>('FillLikes');
  FillProfile := FindElement<TWinUIStackPanel>('FillProfile');
  FillBar := FindElement<TWinUIIconFillTabBar>('FillBar');
  LabelExplore := FindElement<TWinUIStackPanel>('LabelExplore');
  LabelTrips := FindElement<TWinUIStackPanel>('LabelTrips');
  LabelSaved := FindElement<TWinUIStackPanel>('LabelSaved');
  LabelProfile := FindElement<TWinUIStackPanel>('LabelProfile');
  LabelBar := FindElement<TWinUIExpandingLabelTabBar>('LabelBar');
  BubblePhotos := FindElement<TWinUIStackPanel>('BubblePhotos');
  BubbleAlbums := FindElement<TWinUIStackPanel>('BubbleAlbums');
  BubbleCamera := FindElement<TWinUIStackPanel>('BubbleCamera');
  BubbleSettings := FindElement<TWinUIStackPanel>('BubbleSettings');
  BubbleBar := FindElement<TWinUIBubbleFloatTabBar>('BubbleBar');
  StatusDot := FindElement<TWinUIEllipse>('StatusDot');
  StatusText := FindElement<TWinUITextBlock>('StatusText');
  // Event wiring
  // MainWindow.xaml(179): Click="VioletClick"
  VioletSwatch.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('VioletClick'));
  // MainWindow.xaml(182): Click="SunsetClick"
  SunsetSwatch.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('SunsetClick'));
  // MainWindow.xaml(185): Click="MintClick"
  MintSwatch.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('MintClick'));
  // MainWindow.xaml(188): Click="AuroraClick"
  AuroraSwatch.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('AuroraClick'));
  // MainWindow.xaml(198): ValueChanged="SpeedChanged"
  SpeedSlider.OnValueChanged := TWinUIRangeBaseValueChangedEventHandler(PublishedMethod('SpeedChanged'));
  // MainWindow.xaml(203): Toggled="LabelsToggled"
  LabelsSwitch.OnToggled := TWinUIRoutedEventHandler(PublishedMethod('LabelsToggled'));
  // MainWindow.xaml(207): Toggled="TourToggled"
  TourSwitch.OnToggled := TWinUIRoutedEventHandler(PublishedMethod('TourToggled'));
  // MainWindow.xaml(215): Toggled="TransparencyToggled"
  TransparencySwitch.OnToggled := TWinUIRoutedEventHandler(PublishedMethod('TransparencyToggled'));
  // MainWindow.xaml(217): ValueChanged="GlassChanged"
  GlassSlider.OnValueChanged := TWinUIRangeBaseValueChangedEventHandler(PublishedMethod('GlassChanged'));
  // MainWindow.xaml(276): SelectionChanged="TabChanged"
  PillBar.OnSelectionChanged := TWinUIWinValueEventHandler(PublishedMethod('TabChanged'));
  // MainWindow.xaml(322): SelectionChanged="TabChanged"
  BulgeBar.OnSelectionChanged := TWinUIWinValueEventHandler(PublishedMethod('TabChanged'));
  // MainWindow.xaml(368): SelectionChanged="TabChanged"
  NotchBar.OnSelectionChanged := TWinUIWinValueEventHandler(PublishedMethod('TabChanged'));
  // MainWindow.xaml(414): SelectionChanged="TabChanged"
  FillBar.OnSelectionChanged := TWinUIWinValueEventHandler(PublishedMethod('TabChanged'));
  // MainWindow.xaml(460): SelectionChanged="TabChanged"
  LabelBar.OnSelectionChanged := TWinUIWinValueEventHandler(PublishedMethod('TabChanged'));
  // MainWindow.xaml(506): SelectionChanged="TabChanged"
  BubbleBar.OnSelectionChanged := TWinUIWinValueEventHandler(PublishedMethod('TabChanged'));
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
