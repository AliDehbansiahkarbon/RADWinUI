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
  RADWinUI.ActionButtons,
  RADWinUI.Forms;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TMainWindowBase = class(TWinUIWindow)
  protected
    Root: TWinUIGrid;                        // MainWindow.xaml(13) <Grid>
    Glass: TWinUIBorder;                     // MainWindow.xaml(107) <Border>
    OriginalSwatch: TWinUIButton;            // MainWindow.xaml(153) <Button>
    SunsetSwatch: TWinUIButton;              // MainWindow.xaml(156) <Button>
    MintSwatch: TWinUIButton;                // MainWindow.xaml(159) <Button>
    OceanSwatch: TWinUIButton;               // MainWindow.xaml(162) <Button>
    PlayAllButton: TWinUIButton;             // MainWindow.xaml(169) <Button>
    GlassText: TWinUITextBlock;              // MainWindow.xaml(174) <TextBlock>
    TransparencySwitch: TWinUIToggleSwitch;  // MainWindow.xaml(177) <ToggleSwitch>
    GlassSlider: TWinUISlider;               // MainWindow.xaml(179) <Slider>
    HoldButton1: TWinUIHoldButton;           // MainWindow.xaml(207) <HoldButton>
    SendButton1: TWinUISendButton;           // MainWindow.xaml(223) <SendButton>
    ConfettiButton1: TWinUIConfettiButton;   // MainWindow.xaml(238) <ConfettiButton>
    CopyButton1: TWinUICopyButton;           // MainWindow.xaml(253) <CopyButton>
    ShineButton1: TWinUIShineButton;         // MainWindow.xaml(269) <ShineButton>
    SlideButton1: TWinUISlideButton;         // MainWindow.xaml(284) <SlideButton>
    StatusDot: TWinUIEllipse;                // MainWindow.xaml(300) <Ellipse>
    StatusText: TWinUITextBlock;             // MainWindow.xaml(301) <TextBlock>
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
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:ns2="using:RADWinUI.Controls" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="Root" Background="Transparent' +
    '">' + sLineBreak +
    '    <Grid.Resources>' + sLineBreak +
    '      <ResourceDictionary>' + sLineBreak +
    '        <ResourceDictionary.ThemeDictionaries>' + sLineBreak +
    '          <ResourceDictionary x:Key="Light">' + sLineBreak +
    '            <SolidColorBrush x:Key="PageBrush" Color="#F3F2F7" />' + sLineBreak +
    '            <SolidColorBrush x:Key="CardBrush" Color="#E6FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="CardEdgeBrush" Color="#14000000" />' + sLineBreak +
    '            <SolidColorBrush x:Key="StageBrush" Color="#F3F2F8" />' + sLineBreak +
    '            <SolidColorBrush x:Key="InkBrush" Color="#1B1829" />' + sLineBreak +
    '            <SolidColorBrush x:Key="MutedBrush" Color="#5E5A72" />' + sLineBreak +
    '            <SolidColorBrush x:Key="FaintBrush" Color="#85819A" />' + sLineBreak +
    '            <SolidColorBrush x:Key="ChipBrush" Color="#ECEAF4" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SurfaceBrush" Color="#FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SurfaceEdgeBrush" Color="#DEDBE9" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SurfaceTextBrush" Color="#2A2640" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SurfaceMutedBrush" Color="#6F6B85" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SwatchEdgeBrush" Color="#D9D6E4" />' + sLineBreak +
    '            <Color x:Key="GlowColorA">#306C55FF</Color>' + sLineBreak +
    '            <Color x:Key="GlowColorB">#2AFF5FA8</Color>' + sLineBreak +
    '          </ResourceDictionary>' + sLineBreak +
    '          <ResourceDictionary x:Key="Dark">' + sLineBreak +
    '            <SolidColorBrush x:Key="PageBrush" Color="#0E0D15" />' + sLineBreak +
    '            <SolidColorBrush x:Key="CardBrush" Color="#E615131F" />' + sLineBreak +
    '            <SolidColorBrush x:Key="CardEdgeBrush" Color="#25222F" />' + sLineBreak +
    '            <SolidColorBrush x:Key="StageBrush" Color="#100E17" />' + sLineBreak +
    '            <SolidColorBrush x:Key="InkBrush" Color="#FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="MutedBrush" Color="#9A96B0" />' + sLineBreak +
    '            <SolidColorBrush x:Key="FaintBrush" Color="#77738C" />' + sLineBreak +
    '            <SolidColorBrush x:Key="ChipBrush" Color="#1F1C2C" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SurfaceBrush" Color="#1B1829" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SurfaceEdgeBrush" Color="#2E2A40" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SurfaceTextBrush" Color="#D8D4EA" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SurfaceMutedBrush" Color="#A7A3BC" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SwatchEdgeBrush" Color="#2E2A3D" />' + sLineBreak +
    '            <Color x:Key="GlowColorA">#486C55FF</Color>' + sLineBreak +
    '            <Color x:Key="GlowColorB">#36FF5FA8</Color>' + sLineBreak +
    '          </ResourceDictionary>' + sLineBreak +
    '        </ResourceDictionary.ThemeDictionaries>' + sLineBreak +
    '        <Style x:Key="Card" TargetType="Border">' + sLineBreak +
    '          <Setter Property="Background" Value="{ThemeResource CardBrush}" />' + sLineBreak +
    '          <Setter Property="BorderBrush" Value="{ThemeResource CardEdgeBrush}" />' + sLineBreak +
    '          <Setter Property="BorderThickness" Value="1" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="24" />' + sLineBreak +
    '          <Setter Property="Padding" Value="18,16,18,18" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="Stage" TargetType="Grid">' + sLineBreak +
    '          <Setter Property="Background" Value="{ThemeResource StageBrush}" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="16" />' + sLineBreak +
    '          <Setter Property="Height" Value="176" />' + sLineBreak +
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
    '        <Style x:Key="CardText" TargetType="TextBlock">' + sLineBreak +
    '          <Setter Property="FontSize" Value="13" />' + sLineBreak +
    '          <Setter Property="Foreground" Value="{ThemeResource MutedBrush}" />' + sLineBreak +
    '          <Setter Property="TextWrapping" Value="Wrap" />' + sLineBreak +
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
    '          <GradientStop Color="#00FF5FA8" Offset="1" />' + sLineBreak +
    '        </RadialGradientBrush>' + sLineBreak +
    '      </Ellipse.Fill>' + sLineBreak +
    '    </Ellipse>' + sLineBreak +
    '' + sLineBreak +
    '    <ScrollViewer>' + sLineBreak +
    '      <Grid Padding="40,40,40,28" RowSpacing="24" MaxWidth="1240">' + sLineBreak +
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
    '              <TextBlock Style="{StaticResource ChipText}" Text="RADWinUI  ·  Tool Palette  ·  Action Buttons" />' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <TextBlock Text="Six buttons that answer back" FontSize="32" FontWeight="SemiBold" Foreground="{ThemeResource InkBrush}" />' + sLineBreak +
    '            <TextBlock Text="Drop one on a window, set its Text in the Object Inspector and handle one event. Try them all." FontSize="14" Foreground="{ThemeResource MutedBrush}" TextWrapping="Wrap" /' +
    '>' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '          <Border Grid.Column="1" Style="{StaticResource Card}" Padding="20,14,20,14" VerticalAlignment="Center">' + sLineBreak +
    '            <StackPanel Orientation="Horizontal" Spacing="26">' + sLineBreak +
    '              <StackPanel Spacing="8">' + sLineBreak +
    '                <TextBlock Style="{StaticResource Caption}" Text="ACCENT" />' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                  <Button x:Name="OriginalSwatch" Style="{StaticResource Swatch}" ToolTipService.ToolTip="Each button''s own colours" AutomationProperties.Name="Original">' + sLineBreak +
    '                    <Ellipse Width="22" Height="22"><Ellipse.Fill><LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#6C55FF" Offset="0" /><GradientStop Color="#FF5FA8" Offset="' +
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
    '                  <Button x:Name="OceanSwatch" Style="{StaticResource Swatch}" ToolTipService.ToolTip="Ocean" AutomationProperties.Name="Ocean">' + sLineBreak +
    '                    <Ellipse Width="22" Height="22"><Ellipse.Fill><LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#2B5CFF" Offset="0" /><GradientStop Color="#2BD9FF" Offset="' +
    '1" /></LinearGradientBrush></Ellipse.Fill></Ellipse>' + sLineBreak +
    '                  </Button>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <StackPanel Spacing="8">' + sLineBreak +
    '                <TextBlock Style="{StaticResource Caption}" Text="DEMO" />' + sLineBreak +
    '                <Button x:Name="PlayAllButton" Content="Play all" MinWidth="88" CornerRadius="15" Height="30" Padding="14,0,14,0" />' + sLineBreak +
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
    '            <StackPanel Spacing="14">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="1  Hold to Confirm" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIHoldButton" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}">' + sLineBreak +
    '                <ns2:HoldButton x:Name="HoldButton1" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,12,0,0" Background="{ThemeResource SurfaceBrush}" BorderBrush="{ThemeResource Sur' +
    'faceEdgeBrush}" Foreground="{ThemeResource SurfaceMutedBrush}" Text="Hold to delete" DoneText="Deleted" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Hold it down: a ring fills around the button, then it turns into a check. Let go early and the ring runs back." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '' + sLineBreak +
    '          ' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="14">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="2  Paper Plane" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUISendButton" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}">' + sLineBreak +
    '                <ns2:SendButton x:Name="SendButton1" HorizontalAlignment="Center" VerticalAlignment="Center" Text="Send" DoneText="Sent!" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="The paper plane flies off with a trail and the label flips to &quot;Sent!&quot;. It comes back after ResetAfter." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '' + sLineBreak +
    '          ' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="2" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="14">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="3  Confetti Burst" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIConfettiButton" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}">' + sLineBreak +
    '                <ns2:ConfettiButton x:Name="ConfettiButton1" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,40,0,0" Text="Celebrate" ConfettiCount="48" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="A click bursts confetti out of the button. The pieces flutter, turn over and fall." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '' + sLineBreak +
    '          ' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="0" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="14">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="4  Copy Feedback" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUICopyButton" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}">' + sLineBreak +
    '                <ns2:CopyButton x:Name="CopyButton1" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,24,0,0" Background="{ThemeResource SurfaceBrush}" BorderBrush="{ThemeResource Sur' +
    'faceEdgeBrush}" Foreground="{ThemeResource SurfaceTextBrush}" Text="join.app/x7Kq2" DoneText="Copied!" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="A click copies the text to the clipboard. The icon turns into a check and a &quot;Copied!&quot; tooltip pops up." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '' + sLineBreak +
    '          ' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="14">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="5  Shine Sweep" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIShineButton" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}">' + sLineBreak +
    '                <ns2:ShineButton x:Name="ShineButton1" HorizontalAlignment="Center" VerticalAlignment="Center" Text="Upgrade to Pro" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="A diagonal shine sweeps across the button and sparkles twinkle around it. Hover it for one more shine." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '' + sLineBreak +
    '          ' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="2" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="14">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="6  Slide to Confirm" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUISlideButton" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}">' + sLineBreak +
    '                <ns2:SlideButton x:Name="SlideButton1" HorizontalAlignment="Center" VerticalAlignment="Center" Background="{ThemeResource SurfaceBrush}" BorderBrush="{ThemeResource SurfaceEdgeBrush}" ' +
    'Foreground="{ThemeResource SurfaceMutedBrush}" Text="Slide to confirm" DoneText="Confirmed" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Drag the knob to the end: the track fills and the knob turns into a check. Enter or Space slides it too." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
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
    '            <Ellipse x:Name="StatusDot" Width="8" Height="8" Fill="#FF5FA8" VerticalAlignment="Center" />' + sLineBreak +
    '            <TextBlock x:Name="StatusText" FontSize="13" Foreground="{ThemeResource MutedBrush}" VerticalAlignment="Center" Text="Use any button, or press Play all. Their events report here." />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '          <Border Grid.Column="1" Style="{StaticResource Chip}" Padding="14,6,14,7">' + sLineBreak +
    '            <TextBlock Style="{StaticResource CardClass}" Foreground="{ThemeResource MutedBrush}" Text="&lt;rw:SlideButton Text=&quot;Slide to pay&quot; Confirmed=&quot;PayConfirmed&quot;/&gt;" />' + sLineBreak +
    '          </Border>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </Grid>' + sLineBreak +
    '    </ScrollViewer>' + sLineBreak +
    '  </Grid>' + sLineBreak;
  {$IFDEF DEBUG}
  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild
  XamlShape = 'F:Root:TWinUIGrid;F:Glass:TWinUIBorder;F:OriginalSwatch:TWinUIButton;F:SunsetSwatch:TWinUIButton;F:MintSwatch:TWinUIButton;F:OceanSwatch:TWinUIButton;F:PlayAllButton:TWinUIButton;F:GlassText:TWinUITex' +
    'tBlock;F:TransparencySwitch:TWinUIToggleSwitch;F:GlassSlider:TWinUISlider;F:HoldButton1:TWinUIHoldButton;F:SendButton1:TWinUISendButton;F:ConfettiButton1:TWinUIConfettiButton;F:CopyButton1:TWinUICopyB' +
    'utton;F:ShineButton1:TWinUIShineButton;F:SlideButton1:TWinUISlideButton;F:StatusDot:TWinUIEllipse;F:StatusText:TWinUITextBlock;E:ConfettiButton1.Click=ConfettiClick;E:CopyButton1.Copied=CopyCopied;E:G' +
    'lassSlider.ValueChanged=GlassChanged;E:HoldButton1.Confirmed=HoldConfirmed;E:MintSwatch.Click=MintClick;E:OceanSwatch.Click=OceanClick;E:OriginalSwatch.Click=OriginalClick;E:PlayAllButton.Click=PlayAl' +
    'lClick;E:SendButton1.Click=SendClick;E:ShineButton1.Click=ShineClick;E:SlideButton1.Confirmed=SlideConfirmed;E:SunsetSwatch.Click=SunsetClick;E:TransparencySwitch.Toggled=TransparencyToggled';
  {$ENDIF}

constructor TMainWindowBase.Create;
begin
  inherited;
  // MainWindow.xaml(1): <Window> attributes
  Title := 'Action Buttons';
  Width := 1180;
  Height := 880;
  MinWidth := 1000;
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
  OriginalSwatch := FindElement<TWinUIButton>('OriginalSwatch');
  SunsetSwatch := FindElement<TWinUIButton>('SunsetSwatch');
  MintSwatch := FindElement<TWinUIButton>('MintSwatch');
  OceanSwatch := FindElement<TWinUIButton>('OceanSwatch');
  PlayAllButton := FindElement<TWinUIButton>('PlayAllButton');
  GlassText := FindElement<TWinUITextBlock>('GlassText');
  TransparencySwitch := FindElement<TWinUIToggleSwitch>('TransparencySwitch');
  GlassSlider := FindElement<TWinUISlider>('GlassSlider');
  HoldButton1 := FindElement<TWinUIHoldButton>('HoldButton1');
  SendButton1 := FindElement<TWinUISendButton>('SendButton1');
  ConfettiButton1 := FindElement<TWinUIConfettiButton>('ConfettiButton1');
  CopyButton1 := FindElement<TWinUICopyButton>('CopyButton1');
  ShineButton1 := FindElement<TWinUIShineButton>('ShineButton1');
  SlideButton1 := FindElement<TWinUISlideButton>('SlideButton1');
  StatusDot := FindElement<TWinUIEllipse>('StatusDot');
  StatusText := FindElement<TWinUITextBlock>('StatusText');
  // Event wiring
  // MainWindow.xaml(153): Click="OriginalClick"
  OriginalSwatch.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('OriginalClick'));
  // MainWindow.xaml(156): Click="SunsetClick"
  SunsetSwatch.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('SunsetClick'));
  // MainWindow.xaml(159): Click="MintClick"
  MintSwatch.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('MintClick'));
  // MainWindow.xaml(162): Click="OceanClick"
  OceanSwatch.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('OceanClick'));
  // MainWindow.xaml(169): Click="PlayAllClick"
  PlayAllButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('PlayAllClick'));
  // MainWindow.xaml(177): Toggled="TransparencyToggled"
  TransparencySwitch.OnToggled := TWinUIRoutedEventHandler(PublishedMethod('TransparencyToggled'));
  // MainWindow.xaml(179): ValueChanged="GlassChanged"
  GlassSlider.OnValueChanged := TWinUIRangeBaseValueChangedEventHandler(PublishedMethod('GlassChanged'));
  // MainWindow.xaml(207): Confirmed="HoldConfirmed"
  HoldButton1.OnConfirmed := TWinUIWinValueEventHandler(PublishedMethod('HoldConfirmed'));
  // MainWindow.xaml(223): Click="SendClick"
  SendButton1.OnClick := TWinUIWinValueEventHandler(PublishedMethod('SendClick'));
  // MainWindow.xaml(238): Click="ConfettiClick"
  ConfettiButton1.OnClick := TWinUIWinValueEventHandler(PublishedMethod('ConfettiClick'));
  // MainWindow.xaml(253): Copied="CopyCopied"
  CopyButton1.OnCopied := TWinUIWinValueEventHandler(PublishedMethod('CopyCopied'));
  // MainWindow.xaml(269): Click="ShineClick"
  ShineButton1.OnClick := TWinUIWinValueEventHandler(PublishedMethod('ShineClick'));
  // MainWindow.xaml(284): Confirmed="SlideConfirmed"
  SlideButton1.OnConfirmed := TWinUIWinValueEventHandler(PublishedMethod('SlideConfirmed'));
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
