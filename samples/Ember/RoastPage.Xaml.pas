unit RoastPage.Xaml;

{
  TRoastPageBase: base class of the page TRoastPage, generated from RoastPage.xaml
  by RADWinUI XamlCodeGen 0.5 (tools/XamlCodeGen).

  DO NOT EDIT. Change RoastPage.xaml or the published handlers of TRoastPage
  in RoastPage.pas; the build regenerates this unit.

  Fields      one per x:Name element, in XAML order
  Create      loads the page, fills the fields, wires the events
  Comments    name the XAML line each item comes from
}

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.ActionButtons,
  RADWinUI.Pages;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TRoastPageBase = class(TWinUIXamlPage)
  protected
    BatchText: TWinUITextBlock;      // RoastPage.xaml(70) <TextBlock>
    PopOutButton: TWinUIButton;      // RoastPage.xaml(72) <Button>
    DropButton: TWinUIHoldButton;    // RoastPage.xaml(79) <HoldButton>
    TempTile: TWinUIBorder;          // RoastPage.xaml(94) <Border>
    TempText: TWinUITextBlock;       // RoastPage.xaml(99) <TextBlock>
    TimeTile: TWinUIBorder;          // RoastPage.xaml(103) <Border>
    TimeText: TWinUITextBlock;       // RoastPage.xaml(108) <TextBlock>
    RorTile: TWinUIBorder;           // RoastPage.xaml(112) <Border>
    RorText: TWinUITextBlock;        // RoastPage.xaml(117) <TextBlock>
    DevTile: TWinUIBorder;           // RoastPage.xaml(121) <Border>
    DevText: TWinUITextBlock;        // RoastPage.xaml(126) <TextBlock>
    ChartCard: TWinUIBorder;         // RoastPage.xaml(133) <Border>
    DryingChip: TWinUIGrid;          // RoastPage.xaml(140) <Grid>
    DryingLit: TWinUIBorder;         // RoastPage.xaml(141) <Border>
    MaillardChip: TWinUIGrid;        // RoastPage.xaml(144) <Grid>
    MaillardLit: TWinUIBorder;       // RoastPage.xaml(145) <Border>
    DevelopmentChip: TWinUIGrid;     // RoastPage.xaml(148) <Grid>
    DevelopmentLit: TWinUIBorder;    // RoastPage.xaml(149) <Border>
    DoneChip: TWinUIGrid;            // RoastPage.xaml(152) <Grid>
    DoneLit: TWinUIBorder;           // RoastPage.xaml(153) <Border>
    Plot: TWinUICanvas;              // RoastPage.xaml(158) <Canvas>
    Grid100: TWinUIPolyline;         // RoastPage.xaml(159) <Polyline>
    Grid150: TWinUIPolyline;         // RoastPage.xaml(160) <Polyline>
    Grid200: TWinUIPolyline;         // RoastPage.xaml(161) <Polyline>
    CrackLine: TWinUIPolyline;       // RoastPage.xaml(162) <Polyline>
    Label100: TWinUITextBlock;       // RoastPage.xaml(163) <TextBlock>
    Label150: TWinUITextBlock;       // RoastPage.xaml(164) <TextBlock>
    Label200: TWinUITextBlock;       // RoastPage.xaml(165) <TextBlock>
    CrackLabel: TWinUITextBlock;     // RoastPage.xaml(166) <TextBlock>
    Curve: TWinUIPolyline;           // RoastPage.xaml(168) <Polyline>
    Glow: TWinUIEllipse;             // RoastPage.xaml(169) <Ellipse>
    Dot: TWinUIEllipse;              // RoastPage.xaml(170) <Ellipse>
    EmptyState: TWinUIStackPanel;    // RoastPage.xaml(173) <StackPanel>
    QuickStartButton: TWinUIButton;  // RoastPage.xaml(178) <Button>
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
  // RoastPage.xaml(1): the page; event attributes became the
  // wiring below, x:Class, x:DataType and RADWinUI attributes are removed
  PageXaml =
    '<Page xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:ns2="using:RADWinUI.Controls" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' + sLineBreak +
    '  ' + sLineBreak +
    '  <Page.Resources>' + sLineBreak +
    '    <Style x:Key="Card" TargetType="Border">' + sLineBreak +
    '      <Setter Property="Background" Value="{ThemeResource CardBackgroundFillColorDefaultBrush}" />' + sLineBreak +
    '      <Setter Property="BorderBrush" Value="{ThemeResource CardStrokeColorDefaultBrush}" />' + sLineBreak +
    '      <Setter Property="BorderThickness" Value="1" />' + sLineBreak +
    '      <Setter Property="CornerRadius" Value="16" />' + sLineBreak +
    '      <Setter Property="Padding" Value="20,16,20,18" />' + sLineBreak +
    '    </Style>' + sLineBreak +
    '    <Style x:Key="Label" TargetType="TextBlock">' + sLineBreak +
    '      <Setter Property="FontSize" Value="13" />' + sLineBreak +
    '      <Setter Property="Foreground" Value="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '    </Style>' + sLineBreak +
    '    <Style x:Key="Big" TargetType="TextBlock">' + sLineBreak +
    '      <Setter Property="FontSize" Value="34" />' + sLineBreak +
    '      <Setter Property="FontWeight" Value="SemiBold" />' + sLineBreak +
    '    </Style>' + sLineBreak +
    '    <Style x:Key="TileIcon" TargetType="FontIcon">' + sLineBreak +
    '      <Setter Property="FontSize" Value="18" />' + sLineBreak +
    '      <Setter Property="Foreground" Value="#F0652B" />' + sLineBreak +
    '      <Setter Property="HorizontalAlignment" Value="Right" />' + sLineBreak +
    '      <Setter Property="VerticalAlignment" Value="Top" />' + sLineBreak +
    '    </Style>' + sLineBreak +
    '    <Style x:Key="Phase" TargetType="Border">' + sLineBreak +
    '      <Setter Property="CornerRadius" Value="14" />' + sLineBreak +
    '      <Setter Property="Padding" Value="14,5,14,6" />' + sLineBreak +
    '      <Setter Property="Background" Value="{ThemeResource SubtleFillColorSecondaryBrush}" />' + sLineBreak +
    '    </Style>' + sLineBreak +
    '    <Style x:Key="PhaseLit" TargetType="Border">' + sLineBreak +
    '      <Setter Property="CornerRadius" Value="14" />' + sLineBreak +
    '      <Setter Property="Background" Value="#F0652B" />' + sLineBreak +
    '    </Style>' + sLineBreak +
    '    <Style x:Key="AxisText" TargetType="TextBlock">' + sLineBreak +
    '      <Setter Property="FontSize" Value="11" />' + sLineBreak +
    '      <Setter Property="Foreground" Value="{ThemeResource TextFillColorTertiaryBrush}" />' + sLineBreak +
    '    </Style>' + sLineBreak +
    '    <LinearGradientBrush x:Key="CurveBrush" StartPoint="0,0" EndPoint="1,0">' + sLineBreak +
    '      <GradientStop Color="#FFB36B" Offset="0" />' + sLineBreak +
    '      <GradientStop Color="#F0652B" Offset="0.55" />' + sLineBreak +
    '      <GradientStop Color="#B7301E" Offset="1" />' + sLineBreak +
    '    </LinearGradientBrush>' + sLineBreak +
    '  </Page.Resources>' + sLineBreak +
    '' + sLineBreak +
    '  <Grid RowSpacing="16" Padding="0,4,0,0">' + sLineBreak +
    '    <Grid.RowDefinitions>' + sLineBreak +
    '      <RowDefinition Height="Auto" />' + sLineBreak +
    '      <RowDefinition Height="Auto" />' + sLineBreak +
    '      <RowDefinition Height="*" />' + sLineBreak +
    '    </Grid.RowDefinitions>' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Grid ColumnSpacing="12">' + sLineBreak +
    '      <Grid.ColumnDefinitions>' + sLineBreak +
    '        <ColumnDefinition Width="*" />' + sLineBreak +
    '        <ColumnDefinition Width="Auto" />' + sLineBreak +
    '        <ColumnDefinition Width="Auto" />' + sLineBreak +
    '      </Grid.ColumnDefinitions>' + sLineBreak +
    '      <StackPanel Spacing="2" VerticalAlignment="Center">' + sLineBreak +
    '        <TextBlock x:Uid="RoasteryTitle" Text="Roastery" FontSize="32" FontWeight="SemiBold" />' + sLineBreak +
    '        <TextBlock x:Name="BatchText" Style="{StaticResource Label}" FontSize="14" />' + sLineBreak +
    '      </StackPanel>' + sLineBreak +
    '      <Button x:Name="PopOutButton" Grid.Column="1" VerticalAlignment="Center" AutomationProperties.Name="Mini roaster">' + sLineBreak +
    '        <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '          <FontIcon Glyph="" FontSize="14" />' + sLineBreak +
    '          <TextBlock x:Uid="PopOutText" Text="Mini roaster" />' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </Button>' + sLineBreak +
    '      <ns2:HoldButton x:Name="DropButton" x:Uid="DropButton" Grid.Column="2" VerticalAlignment="Center" Text="Hold to drop" DoneText="Dropped" Icon="E896" HoldDuration="1000" AccentFrom="#FFB36B" Acce' +
    'ntTo="#E2452B" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Grid Grid.Row="1" ColumnSpacing="16">' + sLineBreak +
    '      <Grid.ColumnDefinitions>' + sLineBreak +
    '        <ColumnDefinition />' + sLineBreak +
    '        <ColumnDefinition />' + sLineBreak +
    '        <ColumnDefinition />' + sLineBreak +
    '        <ColumnDefinition />' + sLineBreak +
    '      </Grid.ColumnDefinitions>' + sLineBreak +
    '      <Border x:Name="TempTile" Style="{StaticResource Card}">' + sLineBreak +
    '        <Grid>' + sLineBreak +
    '          <FontIcon Style="{StaticResource TileIcon}" Glyph="" />' + sLineBreak +
    '          <StackPanel Spacing="4">' + sLineBreak +
    '            <TextBlock x:Uid="BeanTempLabel" Style="{StaticResource Label}" Text="Bean temperature" />' + sLineBreak +
    '            <TextBlock x:Name="TempText" Style="{StaticResource Big}" Foreground="#F0652B" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </Border>' + sLineBreak +
    '      <Border x:Name="TimeTile" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '        <Grid>' + sLineBreak +
    '          <FontIcon Style="{StaticResource TileIcon}" Glyph="" />' + sLineBreak +
    '          <StackPanel Spacing="4">' + sLineBreak +
    '            <TextBlock x:Uid="RoastTimeLabel" Style="{StaticResource Label}" Text="Roast time" />' + sLineBreak +
    '            <TextBlock x:Name="TimeText" Style="{StaticResource Big}" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </Border>' + sLineBreak +
    '      <Border x:Name="RorTile" Grid.Column="2" Style="{StaticResource Card}">' + sLineBreak +
    '        <Grid>' + sLineBreak +
    '          <FontIcon Style="{StaticResource TileIcon}" Glyph="" />' + sLineBreak +
    '          <StackPanel Spacing="4">' + sLineBreak +
    '            <TextBlock x:Uid="RorLabel" Style="{StaticResource Label}" Text="Rate of rise" />' + sLineBreak +
    '            <TextBlock x:Name="RorText" Style="{StaticResource Big}" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </Border>' + sLineBreak +
    '      <Border x:Name="DevTile" Grid.Column="3" Style="{StaticResource Card}">' + sLineBreak +
    '        <Grid>' + sLineBreak +
    '          <FontIcon Style="{StaticResource TileIcon}" Glyph="" />' + sLineBreak +
    '          <StackPanel Spacing="4">' + sLineBreak +
    '            <TextBlock x:Uid="DevLabel" Style="{StaticResource Label}" Text="Development" />' + sLineBreak +
    '            <TextBlock x:Name="DevText" Style="{StaticResource Big}" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </Border>' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Border x:Name="ChartCard" Grid.Row="2" Style="{StaticResource Card}">' + sLineBreak +
    '      <Grid RowSpacing="14">' + sLineBreak +
    '        <Grid.RowDefinitions>' + sLineBreak +
    '          <RowDefinition Height="Auto" />' + sLineBreak +
    '          <RowDefinition Height="*" />' + sLineBreak +
    '        </Grid.RowDefinitions>' + sLineBreak +
    '        <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '          <Grid x:Name="DryingChip">' + sLineBreak +
    '            <Border x:Name="DryingLit" Style="{StaticResource PhaseLit}" Opacity="0" />' + sLineBreak +
    '            <Border Style="{StaticResource Phase}"><TextBlock x:Uid="PhaseDrying" Text="Drying" /></Border>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <Grid x:Name="MaillardChip">' + sLineBreak +
    '            <Border x:Name="MaillardLit" Style="{StaticResource PhaseLit}" Opacity="0" />' + sLineBreak +
    '            <Border Style="{StaticResource Phase}"><TextBlock x:Uid="PhaseMaillard" Text="Maillard" /></Border>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <Grid x:Name="DevelopmentChip">' + sLineBreak +
    '            <Border x:Name="DevelopmentLit" Style="{StaticResource PhaseLit}" Opacity="0" />' + sLineBreak +
    '            <Border Style="{StaticResource Phase}"><TextBlock x:Uid="PhaseDevelopment" Text="Development" /></Border>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <Grid x:Name="DoneChip">' + sLineBreak +
    '            <Border x:Name="DoneLit" Style="{StaticResource PhaseLit}" Opacity="0" />' + sLineBreak +
    '            <Border Style="{StaticResource Phase}"><TextBlock x:Uid="PhaseDone" Text="Done" /></Border>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '        <Grid Grid.Row="1">' + sLineBreak +
    '          <Canvas x:Name="Plot">' + sLineBreak +
    '            <Polyline x:Name="Grid100" Stroke="{ThemeResource DividerStrokeColorDefaultBrush}" StrokeThickness="1" />' + sLineBreak +
    '            <Polyline x:Name="Grid150" Stroke="{ThemeResource DividerStrokeColorDefaultBrush}" StrokeThickness="1" StrokeDashArray="4,4" />' + sLineBreak +
    '            <Polyline x:Name="Grid200" Stroke="{ThemeResource DividerStrokeColorDefaultBrush}" StrokeThickness="1" />' + sLineBreak +
    '            <Polyline x:Name="CrackLine" Stroke="#80F0652B" StrokeThickness="1.5" StrokeDashArray="3,3" />' + sLineBreak +
    '            <TextBlock x:Name="Label100" Style="{StaticResource AxisText}" Text="100°" />' + sLineBreak +
    '            <TextBlock x:Name="Label150" Style="{StaticResource AxisText}" Text="150°  Maillard" />' + sLineBreak +
    '            <TextBlock x:Name="Label200" Style="{StaticResource AxisText}" Text="200°" />' + sLineBreak +
    '            <TextBlock x:Name="CrackLabel" x:Uid="CrackLabel" Style="{StaticResource AxisText}" Foreground="#F0652B" Text="First crack" Visibility="Collapsed" />' + sLineBreak +
    '            <Polyline x:Name="Curve" Stroke="{StaticResource CurveBrush}" StrokeThickness="3.5" StrokeLineJoin="Round" />' + sLineBreak +
    '            <Ellipse x:Name="Glow" Width="26" Height="26" Fill="#40F0652B" Visibility="Collapsed" />' + sLineBreak +
    '            <Ellipse x:Name="Dot" Width="12" Height="12" Fill="#F0652B" Stroke="White" StrokeThickness="2" Visibility="Collapsed" />' + sLineBreak +
    '          </Canvas>' + sLineBreak +
    '          ' + sLineBreak +
    '          <StackPanel x:Name="EmptyState" HorizontalAlignment="Center" VerticalAlignment="Center" Spacing="12">' + sLineBreak +
    '            <FontIcon Glyph="" FontSize="48" Foreground="#F0652B" HorizontalAlignment="Center" />' + sLineBreak +
    '            <TextBlock x:Uid="EmptyTitle" Text="The roaster is ready" FontSize="20" FontWeight="SemiBold" HorizontalAlignment="Center" />' + sLineBreak +
    '            <TextBlock x:Uid="EmptyText" Text="Start a batch here or from the dashboard, and watch the curve grow." Style="{StaticResource Label}" HorizontalAlignment="Center" />' + sLineBreak +
    '            <Button x:Name="QuickStartButton" Style="{StaticResource AccentButtonStyle}" HorizontalAlignment="Center" AutomationProperties.Name="Start a batch" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </Grid>' + sLineBreak +
    '    </Border>' + sLineBreak +
    '  </Grid>' + sLineBreak +
    '</Page>';
  {$IFDEF DEBUG}
  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild
  XamlShape = 'F:BatchText:TWinUITextBlock;F:PopOutButton:TWinUIButton;F:DropButton:TWinUIHoldButton;F:TempTile:TWinUIBorder;F:TempText:TWinUITextBlock;F:TimeTile:TWinUIBorder;F:TimeText:TWinUITextBlock;F:RorTile:TW' +
    'inUIBorder;F:RorText:TWinUITextBlock;F:DevTile:TWinUIBorder;F:DevText:TWinUITextBlock;F:ChartCard:TWinUIBorder;F:DryingChip:TWinUIGrid;F:DryingLit:TWinUIBorder;F:MaillardChip:TWinUIGrid;F:MaillardLit:' +
    'TWinUIBorder;F:DevelopmentChip:TWinUIGrid;F:DevelopmentLit:TWinUIBorder;F:DoneChip:TWinUIGrid;F:DoneLit:TWinUIBorder;F:Plot:TWinUICanvas;F:Grid100:TWinUIPolyline;F:Grid150:TWinUIPolyline;F:Grid200:TWi' +
    'nUIPolyline;F:CrackLine:TWinUIPolyline;F:Label100:TWinUITextBlock;F:Label150:TWinUITextBlock;F:Label200:TWinUITextBlock;F:CrackLabel:TWinUITextBlock;F:Curve:TWinUIPolyline;F:Glow:TWinUIEllipse;F:Dot:T' +
    'WinUIEllipse;F:EmptyState:TWinUIStackPanel;F:QuickStartButton:TWinUIButton;E:DropButton.Confirmed=DropConfirmed;E:Plot.SizeChanged=PlotSizeChanged;E:PopOutButton.Click=PopOutClick;E:QuickStartButton.C' +
    'lick=QuickStartClick';
  {$ENDIF}

constructor TRoastPageBase.Create;
begin
  inherited CreateFromXaml(PageXaml);
  WireXaml;
  {$IFDEF DEBUG}
  AddHelper(TXamlHotReload.Watch(Self, 'RoastPage.xaml', XamlShape, ReloadXaml));
  {$ENDIF}
end;

// The x:Name fields and the event wiring of the content, again after a hot reload
procedure TRoastPageBase.WireXaml;
begin
  // x:Name elements
  BatchText := FindElement<TWinUITextBlock>('BatchText');
  PopOutButton := FindElement<TWinUIButton>('PopOutButton');
  DropButton := FindElement<TWinUIHoldButton>('DropButton');
  TempTile := FindElement<TWinUIBorder>('TempTile');
  TempText := FindElement<TWinUITextBlock>('TempText');
  TimeTile := FindElement<TWinUIBorder>('TimeTile');
  TimeText := FindElement<TWinUITextBlock>('TimeText');
  RorTile := FindElement<TWinUIBorder>('RorTile');
  RorText := FindElement<TWinUITextBlock>('RorText');
  DevTile := FindElement<TWinUIBorder>('DevTile');
  DevText := FindElement<TWinUITextBlock>('DevText');
  ChartCard := FindElement<TWinUIBorder>('ChartCard');
  DryingChip := FindElement<TWinUIGrid>('DryingChip');
  DryingLit := FindElement<TWinUIBorder>('DryingLit');
  MaillardChip := FindElement<TWinUIGrid>('MaillardChip');
  MaillardLit := FindElement<TWinUIBorder>('MaillardLit');
  DevelopmentChip := FindElement<TWinUIGrid>('DevelopmentChip');
  DevelopmentLit := FindElement<TWinUIBorder>('DevelopmentLit');
  DoneChip := FindElement<TWinUIGrid>('DoneChip');
  DoneLit := FindElement<TWinUIBorder>('DoneLit');
  Plot := FindElement<TWinUICanvas>('Plot');
  Grid100 := FindElement<TWinUIPolyline>('Grid100');
  Grid150 := FindElement<TWinUIPolyline>('Grid150');
  Grid200 := FindElement<TWinUIPolyline>('Grid200');
  CrackLine := FindElement<TWinUIPolyline>('CrackLine');
  Label100 := FindElement<TWinUITextBlock>('Label100');
  Label150 := FindElement<TWinUITextBlock>('Label150');
  Label200 := FindElement<TWinUITextBlock>('Label200');
  CrackLabel := FindElement<TWinUITextBlock>('CrackLabel');
  Curve := FindElement<TWinUIPolyline>('Curve');
  Glow := FindElement<TWinUIEllipse>('Glow');
  Dot := FindElement<TWinUIEllipse>('Dot');
  EmptyState := FindElement<TWinUIStackPanel>('EmptyState');
  QuickStartButton := FindElement<TWinUIButton>('QuickStartButton');
  // Event wiring
  // RoastPage.xaml(72): Click="PopOutClick"
  PopOutButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('PopOutClick'));
  // RoastPage.xaml(79): Confirmed="DropConfirmed"
  DropButton.OnConfirmed := TWinUIWinValueEventHandler(PublishedMethod('DropConfirmed'));
  // RoastPage.xaml(158): SizeChanged="PlotSizeChanged"
  Plot.OnSizeChanged := TWinUISizeChangedEventHandler(PublishedMethod('PlotSizeChanged'));
  // RoastPage.xaml(178): Click="QuickStartClick"
  QuickStartButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('QuickStartClick'));
end;

{$IFDEF DEBUG}
// Hot reload: RoastPage.xaml edited in the IDE while the app runs
procedure TRoastPageBase.ReloadXaml(const AXaml: string);
begin
  ReplaceXaml(AXaml);
  WireXaml;
end;
{$ENDIF}

end.
