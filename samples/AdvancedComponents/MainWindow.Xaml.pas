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
  RADWinUI.Pagination,
  RADWinUI.ProgressSteps,
  RADWinUI.SwipeActions,
  RADWinUI.TabBars,
  RADWinUI.TextFields,
  RADWinUI.Forms;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TMainWindowBase = class(TWinUIWindow)
  protected
    Root: TWinUIGrid;                               // MainWindow.xaml(14) <Grid>
    Glass: TWinUIBorder;                            // MainWindow.xaml(114) <Border>
    OriginalSwatch: TWinUIButton;                   // MainWindow.xaml(161) <Button>
    SunsetSwatch: TWinUIButton;                     // MainWindow.xaml(164) <Button>
    MintSwatch: TWinUIButton;                       // MainWindow.xaml(167) <Button>
    OceanSwatch: TWinUIButton;                      // MainWindow.xaml(170) <Button>
    GlassText: TWinUITextBlock;                     // MainWindow.xaml(178) <TextBlock>
    TransparencySwitch: TWinUIToggleSwitch;         // MainWindow.xaml(181) <ToggleSwitch>
    GlassSlider: TWinUISlider;                      // MainWindow.xaml(183) <Slider>
    SectionBar: TWinUISlidingPillTabBar;            // MainWindow.xaml(192) <SlidingPillTabBar>
    FieldsPage: TWinUIStackPanel;                   // MainWindow.xaml(199) <StackPanel>
    OtpField1: TWinUIOtpCodeField;                  // MainWindow.xaml(227) <OtpCodeField>
    CardField1: TWinUICardNumberField;              // MainWindow.xaml(240) <CardNumberField>
    StrengthField1: TWinUIStrengthMeterField;       // MainWindow.xaml(252) <StrengthMeterField>
    GrowField1: TWinUIAutoGrowField;                // MainWindow.xaml(264) <AutoGrowField>
    TagField1: TWinUITagInputField;                 // MainWindow.xaml(277) <TagInputField>
    GhostField1: TWinUIGhostCompleteField;          // MainWindow.xaml(290) <GhostCompleteField>
    SwipePage: TWinUIStackPanel;                    // MainWindow.xaml(300) <StackPanel>
    RefillButton: TWinUIButton;                     // MainWindow.xaml(310) <Button>
    CardStack1: TWinUISwipeCardStack;               // MainWindow.xaml(329) <SwipeCardStack>
    PinList1: TWinUIPinSwipeList;                   // MainWindow.xaml(341) <PinSwipeList>
    PeekList1: TWinUIPeekSwipeList;                 // MainWindow.xaml(353) <PeekSwipeList>
    LiquidList1: TWinUILiquidDeleteList;            // MainWindow.xaml(365) <LiquidDeleteList>
    SnoozeList1: TWinUISnoozeSwipeList;             // MainWindow.xaml(377) <SnoozeSwipeList>
    UndoList1: TWinUIUndoSwipeList;                 // MainWindow.xaml(389) <UndoSwipeList>
    PaginationPage: TWinUIStackPanel;               // MainWindow.xaml(398) <StackPanel>
    ClassicPager1: TWinUIClassicPager;              // MainWindow.xaml(427) <ClassicPager>
    PillsPager1: TWinUIPillsPager;                  // MainWindow.xaml(439) <PillsPager>
    DotsPager1: TWinUIDotsPager;                    // MainWindow.xaml(451) <DotsPager>
    BorderedPager1: TWinUIBorderedPager;            // MainWindow.xaml(463) <BorderedPager>
    TrackPager1: TWinUITrackPager;                  // MainWindow.xaml(475) <TrackPager>
    SegmentedPager1: TWinUISegmentedPager;          // MainWindow.xaml(487) <SegmentedPager>
    ProgressPager1: TWinUIProgressPager;            // MainWindow.xaml(499) <ProgressPager>
    StepsPager1: TWinUIStepsPager;                  // MainWindow.xaml(511) <StepsPager>
    StepsPage: TWinUIStackPanel;                    // MainWindow.xaml(520) <StackPanel>
    BackButton: TWinUIButton;                       // MainWindow.xaml(531) <Button>
    NextButton: TWinUIButton;                       // MainWindow.xaml(532) <Button>
    NumberedSteps1: TWinUINumberedSteps;            // MainWindow.xaml(552) <NumberedSteps>
    SegmentBarSteps1: TWinUISegmentBarSteps;        // MainWindow.xaml(564) <SegmentBarSteps>
    CheckoutSteps1: TWinUICheckoutSteps;            // MainWindow.xaml(576) <CheckoutSteps>
    OrderTrackingSteps1: TWinUIOrderTrackingSteps;  // MainWindow.xaml(588) <OrderTrackingSteps>
    BreadcrumbSteps1: TWinUIBreadcrumbSteps;        // MainWindow.xaml(600) <BreadcrumbSteps>
    RingSteps1: TWinUIRingSteps;                    // MainWindow.xaml(612) <RingSteps>
    TabBarsPage: TWinUIStackPanel;                  // MainWindow.xaml(621) <StackPanel>
    PillBar: TWinUISlidingPillTabBar;               // MainWindow.xaml(649) <SlidingPillTabBar>
    BulgeBar: TWinUILiquidBulgeTabBar;              // MainWindow.xaml(663) <LiquidBulgeTabBar>
    NotchBar: TWinUIFloatingNotchTabBar;            // MainWindow.xaml(677) <FloatingNotchTabBar>
    FillBar: TWinUIIconFillTabBar;                  // MainWindow.xaml(691) <IconFillTabBar>
    LabelBar: TWinUIExpandingLabelTabBar;           // MainWindow.xaml(705) <ExpandingLabelTabBar>
    BubbleBar: TWinUIBubbleFloatTabBar;             // MainWindow.xaml(719) <BubbleFloatTabBar>
    ButtonsPage: TWinUIStackPanel;                  // MainWindow.xaml(730) <StackPanel>
    HoldButton1: TWinUIHoldButton;                  // MainWindow.xaml(758) <HoldButton>
    SendButton1: TWinUISendButton;                  // MainWindow.xaml(772) <SendButton>
    ConfettiButton1: TWinUIConfettiButton;          // MainWindow.xaml(784) <ConfettiButton>
    CopyButton1: TWinUICopyButton;                  // MainWindow.xaml(797) <CopyButton>
    ShineButton1: TWinUIShineButton;                // MainWindow.xaml(811) <ShineButton>
    SlideButton1: TWinUISlideButton;                // MainWindow.xaml(823) <SlideButton>
    StatusDot: TWinUIEllipse;                       // MainWindow.xaml(835) <Ellipse>
    StatusText: TWinUITextBlock;                    // MainWindow.xaml(836) <TextBlock>
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
    '            <SolidColorBrush x:Key="StageBrush" Color="#F3F2F8" />' + sLineBreak +
    '            <SolidColorBrush x:Key="InkBrush" Color="#1B1829" />' + sLineBreak +
    '            <SolidColorBrush x:Key="MutedBrush" Color="#5E5A72" />' + sLineBreak +
    '            <SolidColorBrush x:Key="FaintBrush" Color="#85819A" />' + sLineBreak +
    '            <SolidColorBrush x:Key="ChipBrush" Color="#ECEAF4" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SurfaceBrush" Color="#FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SurfaceEdgeBrush" Color="#DEDBE9" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SurfaceTextBrush" Color="#2A2640" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SurfaceMutedBrush" Color="#6F6B85" />' + sLineBreak +
    '            <SolidColorBrush x:Key="BarBrush" Color="#FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="BarEdgeBrush" Color="#E2DFEC" />' + sLineBreak +
    '            <SolidColorBrush x:Key="BarIconBrush" Color="#8A86A0" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SwatchEdgeBrush" Color="#D9D6E4" />' + sLineBreak +
    '            <Color x:Key="GlowColorA">#307C4DFF</Color>' + sLineBreak +
    '            <Color x:Key="GlowColorB">#2AE14FB4</Color>' + sLineBreak +
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
    '            <SolidColorBrush x:Key="BarBrush" Color="#1D1A2C" />' + sLineBreak +
    '            <SolidColorBrush x:Key="BarEdgeBrush" Color="#2E2A40" />' + sLineBreak +
    '            <SolidColorBrush x:Key="BarIconBrush" Color="#8F8AA8" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SwatchEdgeBrush" Color="#2E2A3D" />' + sLineBreak +
    '            <Color x:Key="GlowColorA">#487C4DFF</Color>' + sLineBreak +
    '            <Color x:Key="GlowColorB">#36E14FB4</Color>' + sLineBreak +
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
    '          <Setter Property="Height" Value="150" />' + sLineBreak +
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
    '          <GradientStop Color="#007C4DFF" Offset="1" />' + sLineBreak +
    '        </RadialGradientBrush>' + sLineBreak +
    '      </Ellipse.Fill>' + sLineBreak +
    '    </Ellipse>' + sLineBreak +
    '    <Ellipse Width="900" Height="900" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,-280,-360" IsHitTestVisible="False">' + sLineBreak +
    '      <Ellipse.Fill>' + sLineBreak +
    '        <RadialGradientBrush>' + sLineBreak +
    '          <GradientStop Color="{ThemeResource GlowColorB}" Offset="0" />' + sLineBreak +
    '          <GradientStop Color="#00E14FB4" Offset="1" />' + sLineBreak +
    '        </RadialGradientBrush>' + sLineBreak +
    '      </Ellipse.Fill>' + sLineBreak +
    '    </Ellipse>' + sLineBreak +
    '' + sLineBreak +
    '    <ScrollViewer>' + sLineBreak +
    '      <Grid Padding="40,40,40,28" RowSpacing="22" MaxWidth="1300">' + sLineBreak +
    '        <Grid.RowDefinitions>' + sLineBreak +
    '          <RowDefinition Height="Auto" />' + sLineBreak +
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
    '              <TextBlock Style="{StaticResource ChipText}" Text="RADWinUI  ·  Tool Palette  ·  38 controls in 6 categories" />' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <TextBlock Text="Advanced Components" FontSize="32" FontWeight="SemiBold" Foreground="{ThemeResource InkBrush}" />' + sLineBreak +
    '            <TextBlock Text="Text fields, swipe actions, pagers, progress steps, tab bars and action buttons. Drop one on a window, set it up in the Object Inspector and handle one event." FontSize="1' +
    '4" Foreground="{ThemeResource MutedBrush}" TextWrapping="Wrap" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '          <Border Grid.Column="1" Style="{StaticResource Card}" Padding="20,14,20,14" VerticalAlignment="Center">' + sLineBreak +
    '            <StackPanel Orientation="Horizontal" Spacing="26">' + sLineBreak +
    '              <StackPanel Spacing="8">' + sLineBreak +
    '                <TextBlock Style="{StaticResource Caption}" Text="ACCENT" />' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                  <Button x:Name="OriginalSwatch" Style="{StaticResource Swatch}" ToolTipService.ToolTip="Each control''s own colours" AutomationProperties.Name="Original">' + sLineBreak +
    '                    <Ellipse Width="22" Height="22"><Ellipse.Fill><LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#7C4DFF" Offset="0" /><GradientStop Color="#E14FB4" Offset="' +
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
    '        <ns2:SlidingPillTabBar x:Name="SectionBar" Grid.Row="1" Width="720" HorizontalAlignment="Center" AutomationProperties.Name="Sections" Background="{ThemeResource BarBrush}" BorderBrush="{ThemeR' +
    'esource BarEdgeBrush}" Foreground="{ThemeResource BarIconBrush}" Items="Fields:Edit, Swipe:Message, Pages:Document, Steps:Check, Tabs:Apps, Buttons:Like" Pages="FieldsPage, SwipePage, PaginationPage, ' +
    'StepsPage, TabBarsPage, ButtonsPage" />' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <StackPanel x:Name="FieldsPage" Grid.Row="2" Spacing="16">' + sLineBreak +
    '        <Grid ColumnSpacing="16">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <StackPanel Spacing="2" VerticalAlignment="Center">' + sLineBreak +
    '            <TextBlock Text="Text Fields" FontSize="20" FontWeight="SemiBold" Foreground="{ThemeResource InkBrush}" />' + sLineBreak +
    '            <TextBlock Text="Six inputs that guide the typing. Each one is a real text box underneath: copy, paste and the keyboard work as usual." FontSize="13" Foreground="{ThemeResource MutedBrush}' +
    '" TextWrapping="Wrap" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '        <Grid ColumnSpacing="20" RowSpacing="20">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition />' + sLineBreak +
    '            <ColumnDefinition />' + sLineBreak +
    '            <ColumnDefinition />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <Grid.RowDefinitions>' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '          </Grid.RowDefinitions>' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="0" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="1  OTP Code" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIOtpCodeField" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}">' + sLineBreak +
    '                <ns2:OtpCodeField x:Name="OtpField1" HorizontalAlignment="Center" VerticalAlignment="Center" CodeLength="4" AutoVerify="False" Header="Enter the code we sent" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Type four digits: each box takes one and the caret moves on. Try 2468 for the mint wave, any other code shakes red." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="2  Card Number" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUICardNumberField" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}">' + sLineBreak +
    '                <ns2:CardNumberField x:Name="CardField1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="290" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="The digits group in fours as you type. With the number complete it folds to its last four and the expiry and CVC slide in." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="2" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="3  Strength Meter" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIStrengthMeterField" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}">' + sLineBreak +
    '                <ns2:StrengthMeterField x:Name="StrengthField1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="290" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Four segments fill and change colour as the password gets stronger: length, mixed case, digits and symbols." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="0" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="4  Auto Grow" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIAutoGrowField" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}">' + sLineBreak +
    '                <ns2:AutoGrowField x:Name="GrowField1" HorizontalAlignment="Center" VerticalAlignment="Top" Margin="0,24,0,0" Width="290" PlaceholderText="Write a message..." />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="The field grows a line at a time up to MaxLines. Ctrl+Enter or the send button raises Submitted." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="5  Tag Input" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUITagInputField" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}">' + sLineBreak +
    '                <ns2:TagInputField x:Name="TagField1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="290" Tags="Delphi, WinUI" PlaceholderText="Add a topic" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Space, comma or Enter turns a word into a chip. Backspace twice or the x removes one." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="2" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="6  Ghost Complete" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIGhostCompleteField" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}">' + sLineBreak +
    '                <ns2:GhostCompleteField x:Name="GhostField1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="290" PlaceholderText="name@" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Type a name and @: the rest of the address shows faintly. Tab or the right arrow takes it." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </StackPanel>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <StackPanel x:Name="SwipePage" Grid.Row="2" Spacing="16" Visibility="Collapsed">' + sLineBreak +
    '        <Grid ColumnSpacing="16">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <StackPanel Spacing="2" VerticalAlignment="Center">' + sLineBreak +
    '            <TextBlock Text="Swipe Actions" FontSize="20" FontWeight="SemiBold" Foreground="{ThemeResource InkBrush}" />' + sLineBreak +
    '            <TextBlock Text="Drag a row or a card with the mouse, a pen or a finger. With the keyboard, Up and Down choose a row and Left or Right swipes it." FontSize="13" Foreground="{ThemeResource ' +
    'MutedBrush}" TextWrapping="Wrap" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '          <Button Grid.Column="1" x:Name="RefillButton" Content="Bring the rows back" CornerRadius="15" Height="30" VerticalAlignment="Center" />' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '        <Grid ColumnSpacing="20" RowSpacing="20">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition />' + sLineBreak +
    '            <ColumnDefinition />' + sLineBreak +
    '            <ColumnDefinition />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <Grid.RowDefinitions>' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '          </Grid.RowDefinitions>' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="0" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="1  Card Swipe" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUISwipeCardStack" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="230">' + sLineBreak +
    '                <ns2:SwipeCardStack x:Name="CardStack1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="300" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Drag the top card: it tilts and a LIKE or NOPE stamp fades in. Let go far enough and it flies off, the next card rises." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="2  Swipe to Pin" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIPinSwipeList" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="230">' + sLineBreak +
    '                <ns2:PinSwipeList x:Name="PinList1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="290" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Swipe a row to the right: the pin pops on and the row jumps to the top. Swipe it again to unpin." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="2" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="3  Peek Hint" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIPeekSwipeList" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="230">' + sLineBreak +
    '                <ns2:PeekSwipeList x:Name="PeekList1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="290" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="A row peeks to the left now and then, to show there is more behind it. Swipe it open and tap Delete." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="0" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="4  Liquid Delete" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUILiquidDeleteList" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="230">' + sLineBreak +
    '                <ns2:LiquidDeleteList x:Name="LiquidList1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="290" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Swipe left: a red blob stretches out of the row, snaps off and pops, and the row goes with it." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="5  Snooze Clock" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUISnoozeSwipeList" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="230">' + sLineBreak +
    '                <ns2:SnoozeSwipeList x:Name="SnoozeList1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="290" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Swipe left to snooze. The clock spins as you drag and the time steps from 1h to 3h to 6 PM." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="2" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="6  Inline Undo" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIUndoSwipeList" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="230">' + sLineBreak +
    '                <ns2:UndoSwipeList x:Name="UndoList1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="290" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Swipe a row away and an Undo strip stays for a moment. Undo slides the row back in." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </StackPanel>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <StackPanel x:Name="PaginationPage" Grid.Row="2" Spacing="16" Visibility="Collapsed">' + sLineBreak +
    '        <Grid ColumnSpacing="16">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <StackPanel Spacing="2" VerticalAlignment="Center">' + sLineBreak +
    '            <TextBlock Text="Pagination" FontSize="20" FontWeight="SemiBold" Foreground="{ThemeResource InkBrush}" />' + sLineBreak +
    '            <TextBlock Text="Eight pagers. Click a page or an arrow, or use the arrow keys, Home and End." FontSize="13" Foreground="{ThemeResource MutedBrush}" TextWrapping="Wrap" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '        <Grid ColumnSpacing="20" RowSpacing="20">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition />' + sLineBreak +
    '            <ColumnDefinition />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <Grid.RowDefinitions>' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '          </Grid.RowDefinitions>' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="0" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="1  Classic" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIClassicPager" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="96">' + sLineBreak +
    '                <ns2:ClassicPager x:Name="ClassicPager1" AutomationProperties.Name="Results pages" HorizontalAlignment="Center" VerticalAlignment="Center" Width="380" PageCount="10" Page="3" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Numbered pages with arrows. Far from the ends, the pages in between fold into an ellipsis." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="2  Pills" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIPillsPager" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="96">' + sLineBreak +
    '                <ns2:PillsPager x:Name="PillsPager1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="380" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Dots that stretch into a pill for the current page. The pill slides with a little lag." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="0" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="3  Dots" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIDotsPager" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="96">' + sLineBreak +
    '                <ns2:DotsPager x:Name="DotsPager1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="380" PageCount="12" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="A row of dots and double arrows. The current dot grows and glows." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="4  Bordered" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIBorderedPager" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="96">' + sLineBreak +
    '                <ns2:BorderedPager x:Name="BorderedPager1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="380" PageCount="8" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="One frame around every page, the current one filled, with arrows at both ends." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="2" Grid.Column="0" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="5  Track" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUITrackPager" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="96">' + sLineBreak +
    '                <ns2:TrackPager x:Name="TrackPager1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="380" PageCount="6" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="A thin track with a thumb that springs from page to page." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="2" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="6  Segmented" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUISegmentedPager" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="96">' + sLineBreak +
    '                <ns2:SegmentedPager x:Name="SegmentedPager1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="380" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="A segmented control: the current segment lights up and glows." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="3" Grid.Column="0" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="7  Progress" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIProgressPager" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="96">' + sLineBreak +
    '                <ns2:ProgressPager x:Name="ProgressPager1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="380" PageCount="12" Page="4" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Page 4 of 12 as a bar between two arrows. Click the bar to jump." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="3" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="8  Steps" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIStepsPager" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="96">' + sLineBreak +
    '                <ns2:StepsPager x:Name="StepsPager1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="380" PageCount="5" Page="2" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Pages as steps on a line: done, current and still to come." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </StackPanel>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <StackPanel x:Name="StepsPage" Grid.Row="2" Spacing="16" Visibility="Collapsed">' + sLineBreak +
    '        <Grid ColumnSpacing="16">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <StackPanel Spacing="2" VerticalAlignment="Center">' + sLineBreak +
    '            <TextBlock Text="Progress Steps" FontSize="20" FontWeight="SemiBold" Foreground="{ThemeResource InkBrush}" />' + sLineBreak +
    '            <TextBlock Text="Six ways to show where the user is in a flow. Click a step, or use Back and Next." FontSize="13" Foreground="{ThemeResource MutedBrush}" TextWrapping="Wrap" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '          <StackPanel Grid.Column="1" Orientation="Horizontal" Spacing="8" VerticalAlignment="Center">' + sLineBreak +
    '            <Button x:Name="BackButton" Content="Back" MinWidth="80" CornerRadius="15" Height="30" />' + sLineBreak +
    '            <Button x:Name="NextButton" Content="Next" MinWidth="80" CornerRadius="15" Height="30" Style="{StaticResource AccentButtonStyle}" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '        <Grid ColumnSpacing="20" RowSpacing="20">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition />' + sLineBreak +
    '            <ColumnDefinition />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <Grid.RowDefinitions>' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '          </Grid.RowDefinitions>' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="0" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="1  Numbered" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUINumberedSteps" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="150">' + sLineBreak +
    '                <ns2:NumberedSteps x:Name="NumberedSteps1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="420" Step="2" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Numbered circles on a line. The line fills to the next step and the number turns into a check." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="2  Segment Bar" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUISegmentBarSteps" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="150">' + sLineBreak +
    '                <ns2:SegmentBarSteps x:Name="SegmentBarSteps1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="420" Step="2" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="One segment per step, filling in turn, and the step number rolls over above it." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="0" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="3  Checkout Icons" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUICheckoutSteps" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="150">' + sLineBreak +
    '                <ns2:CheckoutSteps x:Name="CheckoutSteps1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="420" Step="2" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="An icon per step on a dotted path. A done step gets a check badge." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="4  Order Tracking" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIOrderTrackingSteps" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="150">' + sLineBreak +
    '                <ns2:OrderTrackingSteps x:Name="OrderTrackingSteps1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="420" Step="3" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="A van drives along the road from stop to stop, with the order and its arrival above." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="2" Grid.Column="0" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="5  Breadcrumb Arrows" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIBreadcrumbSteps" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="150">' + sLineBreak +
    '                <ns2:BreadcrumbSteps x:Name="BreadcrumbSteps1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="420" Step="2" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Arrow shaped steps. The colour wipes into the next arrow with a pointed edge." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="2" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="6  Ring" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIRingSteps" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="170">' + sLineBreak +
    '                <ns2:RingSteps x:Name="RingSteps1" HorizontalAlignment="Center" VerticalAlignment="Center" Step="2" Width="300" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="A ring of arcs around the step number, which rolls to the next one." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </StackPanel>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <StackPanel x:Name="TabBarsPage" Grid.Row="2" Spacing="16" Visibility="Collapsed">' + sLineBreak +
    '        <Grid ColumnSpacing="16">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <StackPanel Spacing="2" VerticalAlignment="Center">' + sLineBreak +
    '            <TextBlock Text="Tab Bars" FontSize="20" FontWeight="SemiBold" Foreground="{ThemeResource InkBrush}" />' + sLineBreak +
    '            <TextBlock Text="The six tab bars of the Tab Bars category. A bar can show one page per tab with its Pages property, like the bar above." FontSize="13" Foreground="{ThemeResource MutedBrus' +
    'h}" TextWrapping="Wrap" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '        <Grid ColumnSpacing="20" RowSpacing="20">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition />' + sLineBreak +
    '            <ColumnDefinition />' + sLineBreak +
    '            <ColumnDefinition />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <Grid.RowDefinitions>' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '          </Grid.RowDefinitions>' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="0" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="1  Sliding Pill" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUISlidingPillTabBar" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="150">' + sLineBreak +
    '                <ns2:SlidingPillTabBar x:Name="PillBar" Grid.Row="1" Width="Auto" HorizontalAlignment="Stretch" VerticalAlignment="Bottom" Margin="12" Background="{ThemeResource BarBrush}" BorderBrush' +
    '="{ThemeResource BarEdgeBrush}" Foreground="{ThemeResource BarIconBrush}" Items="Home:Home, Search:Search, Likes:Heart, Profile:Contact" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="A pill slides under the selected tab and stretches on the way." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="2  Liquid Bulge" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUILiquidBulgeTabBar" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="150">' + sLineBreak +
    '                <ns2:LiquidBulgeTabBar x:Name="BulgeBar" Grid.Row="1" Width="Auto" HorizontalAlignment="Stretch" VerticalAlignment="Bottom" Margin="12" Background="{ThemeResource BarBrush}" BorderBrus' +
    'h="{ThemeResource BarEdgeBrush}" Foreground="{ThemeResource BarIconBrush}" Items="Listen:Music, Explore:Globe, Library:Library, Me:Contact" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="The bar bulges up under the selected tab like a drop of liquid." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="2" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="3  Floating Notch" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIFloatingNotchTabBar" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="150">' + sLineBreak +
    '                <ns2:FloatingNotchTabBar x:Name="NotchBar" Grid.Row="1" Width="Auto" HorizontalAlignment="Stretch" VerticalAlignment="Bottom" Margin="12" Background="{ThemeResource BarBrush}" BorderBr' +
    'ush="{ThemeResource BarEdgeBrush}" Foreground="{ThemeResource BarIconBrush}" Items="Shop:Shop, Cart:Cart, Saved:Heart, Account:Contact" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="The selected icon floats in a circle above a notch cut into the bar." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="0" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="4  Icon Fill" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIIconFillTabBar" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="150">' + sLineBreak +
    '                <ns2:IconFillTabBar x:Name="FillBar" Grid.Row="1" Width="Auto" HorizontalAlignment="Stretch" VerticalAlignment="Bottom" Margin="12" Background="{ThemeResource BarBrush}" BorderBrush="{' +
    'ThemeResource BarEdgeBrush}" Foreground="{ThemeResource BarIconBrush}" Items="Feed:Home, Chat:Chat, Likes:Heart, Profile:Contact" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="The selected icon fills in and a dot shows under it." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="5  Expanding Label" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIExpandingLabelTabBar" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="150">' + sLineBreak +
    '                <ns2:ExpandingLabelTabBar x:Name="LabelBar" Grid.Row="1" Width="Auto" HorizontalAlignment="Stretch" VerticalAlignment="Bottom" Margin="12" Background="{ThemeResource BarBrush}" BorderB' +
    'rush="{ThemeResource BarEdgeBrush}" Foreground="{ThemeResource BarIconBrush}" Items="Explore:Globe, Trips:Airplane, Saved:Star, Profile:Contact" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="The selected tab widens to show its label." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="2" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="6  Bubble Float" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIBubbleFloatTabBar" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="150">' + sLineBreak +
    '                <ns2:BubbleFloatTabBar x:Name="BubbleBar" Grid.Row="1" Width="Auto" HorizontalAlignment="Stretch" VerticalAlignment="Bottom" Margin="12" Background="{ThemeResource BarBrush}" BorderBru' +
    'sh="{ThemeResource BarEdgeBrush}" Foreground="{ThemeResource BarIconBrush}" BubbleCount="9" Items="Photos:Photo, Albums:Folder, Camera:Camera, Settings:Settings" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Bubbles rise from the selected tab." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </StackPanel>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <StackPanel x:Name="ButtonsPage" Grid.Row="2" Spacing="16" Visibility="Collapsed">' + sLineBreak +
    '        <Grid ColumnSpacing="16">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <StackPanel Spacing="2" VerticalAlignment="Center">' + sLineBreak +
    '            <TextBlock Text="Action Buttons" FontSize="20" FontWeight="SemiBold" Foreground="{ThemeResource InkBrush}" />' + sLineBreak +
    '            <TextBlock Text="The six buttons of the Action Buttons category." FontSize="13" Foreground="{ThemeResource MutedBrush}" TextWrapping="Wrap" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '        <Grid ColumnSpacing="20" RowSpacing="20">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition />' + sLineBreak +
    '            <ColumnDefinition />' + sLineBreak +
    '            <ColumnDefinition />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '          <Grid.RowDefinitions>' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '          </Grid.RowDefinitions>' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="0" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="1  Hold to Confirm" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIHoldButton" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="176">' + sLineBreak +
    '                <ns2:HoldButton x:Name="HoldButton1" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,12,0,0" Background="{ThemeResource SurfaceBrush}" BorderBrush="{ThemeResource Sur' +
    'faceEdgeBrush}" Foreground="{ThemeResource SurfaceMutedBrush}" Text="Hold to delete" DoneText="Deleted" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Hold it down: a ring fills around the button, then it turns into a check." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="2  Paper Plane" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUISendButton" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="176">' + sLineBreak +
    '                <ns2:SendButton x:Name="SendButton1" HorizontalAlignment="Center" VerticalAlignment="Center" Text="Send" DoneText="Sent!" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="The paper plane flies off with a trail and the label flips to &quot;Sent!&quot;." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="0" Grid.Column="2" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="3  Confetti Burst" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIConfettiButton" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="176">' + sLineBreak +
    '                <ns2:ConfettiButton x:Name="ConfettiButton1" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,40,0,0" Text="Celebrate" ConfettiCount="48" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="A click bursts confetti out of the button. The pieces flutter and fall." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="0" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="4  Copy Feedback" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUICopyButton" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="176">' + sLineBreak +
    '                <ns2:CopyButton x:Name="CopyButton1" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,24,0,0" Background="{ThemeResource SurfaceBrush}" BorderBrush="{ThemeResource Sur' +
    'faceEdgeBrush}" Foreground="{ThemeResource SurfaceTextBrush}" Text="join.app/x7Kq2" DoneText="Copied!" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="A click copies the text and the icon turns into a check." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="5  Shine Sweep" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIShineButton" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="176">' + sLineBreak +
    '                <ns2:ShineButton x:Name="ShineButton1" HorizontalAlignment="Center" VerticalAlignment="Center" Text="Upgrade to Pro" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="A shine sweeps across the button and sparkles twinkle around it." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border Grid.Row="1" Grid.Column="2" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="12">' + sLineBreak +
    '              <StackPanel Spacing="1">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="6  Slide to Confirm" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUISlideButton" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Style="{StaticResource Stage}" Height="176">' + sLineBreak +
    '                <ns2:SlideButton x:Name="SlideButton1" HorizontalAlignment="Center" VerticalAlignment="Center" Background="{ThemeResource SurfaceBrush}" BorderBrush="{ThemeResource SurfaceEdgeBrush}" ' +
    'Foreground="{ThemeResource SurfaceMutedBrush}" Text="Slide to confirm" DoneText="Confirmed" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Style="{StaticResource CardText}" Text="Drag the knob to the end: the track fills and the knob turns into a check." />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </StackPanel>' + sLineBreak +
    '' + sLineBreak +
    '        ' + sLineBreak +
    '        <StackPanel Grid.Row="3" Orientation="Horizontal" Spacing="10" VerticalAlignment="Center">' + sLineBreak +
    '          <Ellipse x:Name="StatusDot" Width="8" Height="8" Fill="#E14FB4" VerticalAlignment="Center" />' + sLineBreak +
    '          <TextBlock x:Name="StatusText" FontSize="13" Foreground="{ThemeResource MutedBrush}" VerticalAlignment="Center" Text="Use any control. Their events report here." />' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </Grid>' + sLineBreak +
    '    </ScrollViewer>' + sLineBreak +
    '  </Grid>' + sLineBreak;
  {$IFDEF DEBUG}
  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild
  XamlShape = 'F:Root:TWinUIGrid;F:Glass:TWinUIBorder;F:OriginalSwatch:TWinUIButton;F:SunsetSwatch:TWinUIButton;F:MintSwatch:TWinUIButton;F:OceanSwatch:TWinUIButton;F:GlassText:TWinUITextBlock;F:TransparencySwitch:T' +
    'WinUIToggleSwitch;F:GlassSlider:TWinUISlider;F:SectionBar:TWinUISlidingPillTabBar;F:FieldsPage:TWinUIStackPanel;F:OtpField1:TWinUIOtpCodeField;F:CardField1:TWinUICardNumberField;F:StrengthField1:TWinU' +
    'IStrengthMeterField;F:GrowField1:TWinUIAutoGrowField;F:TagField1:TWinUITagInputField;F:GhostField1:TWinUIGhostCompleteField;F:SwipePage:TWinUIStackPanel;F:RefillButton:TWinUIButton;F:CardStack1:TWinUI' +
    'SwipeCardStack;F:PinList1:TWinUIPinSwipeList;F:PeekList1:TWinUIPeekSwipeList;F:LiquidList1:TWinUILiquidDeleteList;F:SnoozeList1:TWinUISnoozeSwipeList;F:UndoList1:TWinUIUndoSwipeList;F:PaginationPage:T' +
    'WinUIStackPanel;F:ClassicPager1:TWinUIClassicPager;F:PillsPager1:TWinUIPillsPager;F:DotsPager1:TWinUIDotsPager;F:BorderedPager1:TWinUIBorderedPager;F:TrackPager1:TWinUITrackPager;F:SegmentedPager1:TWi' +
    'nUISegmentedPager;F:ProgressPager1:TWinUIProgressPager;F:StepsPager1:TWinUIStepsPager;F:StepsPage:TWinUIStackPanel;F:BackButton:TWinUIButton;F:NextButton:TWinUIButton;F:NumberedSteps1:TWinUINumberedSt' +
    'eps;F:SegmentBarSteps1:TWinUISegmentBarSteps;F:CheckoutSteps1:TWinUICheckoutSteps;F:OrderTrackingSteps1:TWinUIOrderTrackingSteps;F:BreadcrumbSteps1:TWinUIBreadcrumbSteps;F:RingSteps1:TWinUIRingSteps;F' +
    ':TabBarsPage:TWinUIStackPanel;F:PillBar:TWinUISlidingPillTabBar;F:BulgeBar:TWinUILiquidBulgeTabBar;F:NotchBar:TWinUIFloatingNotchTabBar;F:FillBar:TWinUIIconFillTabBar;F:LabelBar:TWinUIExpandingLabelTa' +
    'bBar;F:BubbleBar:TWinUIBubbleFloatTabBar;F:ButtonsPage:TWinUIStackPanel;F:HoldButton1:TWinUIHoldButton;F:SendButton1:TWinUISendButton;F:ConfettiButton1:TWinUIConfettiButton;F:CopyButton1:TWinUICopyBut' +
    'ton;F:ShineButton1:TWinUIShineButton;F:SlideButton1:TWinUISlideButton;F:StatusDot:TWinUIEllipse;F:StatusText:TWinUITextBlock;E:BackButton.Click=BackClick;E:BorderedPager1.PageChanged=PageChanged;E:Bre' +
    'adcrumbSteps1.StepChanged=StepChanged;E:BubbleBar.SelectionChanged=TabChanged;E:BulgeBar.SelectionChanged=TabChanged;E:CardField1.Completed=CardCompleted;E:CardStack1.Liked=CardLiked;E:CardStack1.Pass' +
    'ed=CardPassed;E:CheckoutSteps1.StepChanged=StepChanged;E:ClassicPager1.PageChanged=PageChanged;E:ConfettiButton1.Click=ButtonDone;E:CopyButton1.Copied=ButtonDone;E:DotsPager1.PageChanged=PageChanged;E' +
    ':FillBar.SelectionChanged=TabChanged;E:GhostField1.Accepted=GhostAccepted;E:GlassSlider.ValueChanged=GlassChanged;E:GrowField1.Submitted=GrowSubmitted;E:HoldButton1.Confirmed=ButtonDone;E:LabelBar.Sel' +
    'ectionChanged=TabChanged;E:LiquidList1.Deleted=RowDeleted;E:MintSwatch.Click=MintClick;E:NextButton.Click=NextClick;E:NotchBar.SelectionChanged=TabChanged;E:NumberedSteps1.StepChanged=StepChanged;E:Oc' +
    'eanSwatch.Click=OceanClick;E:OrderTrackingSteps1.StepChanged=StepChanged;E:OriginalSwatch.Click=OriginalClick;E:OtpField1.Completed=OtpCompleted;E:PeekList1.Deleted=RowDeleted;E:PillBar.SelectionChang' +
    'ed=TabChanged;E:PillsPager1.PageChanged=PageChanged;E:PinList1.Pinned=RowPinned;E:PinList1.Unpinned=RowUnpinned;E:ProgressPager1.PageChanged=PageChanged;E:RefillButton.Click=RefillClick;E:RingSteps1.S' +
    'tepChanged=StepChanged;E:SectionBar.SelectionChanged=SectionChanged;E:SegmentBarSteps1.StepChanged=StepChanged;E:SegmentedPager1.PageChanged=PageChanged;E:SendButton1.Click=ButtonDone;E:ShineButton1.C' +
    'lick=ButtonDone;E:SlideButton1.Confirmed=ButtonDone;E:SnoozeList1.Snoozed=RowSnoozed;E:StepsPager1.PageChanged=PageChanged;E:StrengthField1.TextChanged=StrengthChanged;E:SunsetSwatch.Click=SunsetClick' +
    ';E:TagField1.TagsChanged=TagsChanged;E:TrackPager1.PageChanged=PageChanged;E:TransparencySwitch.Toggled=TransparencyToggled;E:UndoList1.Deleted=RowDeleted;E:UndoList1.Restored=RowRestored';
  {$ENDIF}

constructor TMainWindowBase.Create;
begin
  inherited;
  // MainWindow.xaml(1): <Window> attributes
  Title := 'Advanced Components';
  Width := 1280;
  Height := 940;
  MinWidth := 1060;
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
  GlassText := FindElement<TWinUITextBlock>('GlassText');
  TransparencySwitch := FindElement<TWinUIToggleSwitch>('TransparencySwitch');
  GlassSlider := FindElement<TWinUISlider>('GlassSlider');
  SectionBar := FindElement<TWinUISlidingPillTabBar>('SectionBar');
  FieldsPage := FindElement<TWinUIStackPanel>('FieldsPage');
  OtpField1 := FindElement<TWinUIOtpCodeField>('OtpField1');
  CardField1 := FindElement<TWinUICardNumberField>('CardField1');
  StrengthField1 := FindElement<TWinUIStrengthMeterField>('StrengthField1');
  GrowField1 := FindElement<TWinUIAutoGrowField>('GrowField1');
  TagField1 := FindElement<TWinUITagInputField>('TagField1');
  GhostField1 := FindElement<TWinUIGhostCompleteField>('GhostField1');
  SwipePage := FindElement<TWinUIStackPanel>('SwipePage');
  RefillButton := FindElement<TWinUIButton>('RefillButton');
  CardStack1 := FindElement<TWinUISwipeCardStack>('CardStack1');
  PinList1 := FindElement<TWinUIPinSwipeList>('PinList1');
  PeekList1 := FindElement<TWinUIPeekSwipeList>('PeekList1');
  LiquidList1 := FindElement<TWinUILiquidDeleteList>('LiquidList1');
  SnoozeList1 := FindElement<TWinUISnoozeSwipeList>('SnoozeList1');
  UndoList1 := FindElement<TWinUIUndoSwipeList>('UndoList1');
  PaginationPage := FindElement<TWinUIStackPanel>('PaginationPage');
  ClassicPager1 := FindElement<TWinUIClassicPager>('ClassicPager1');
  PillsPager1 := FindElement<TWinUIPillsPager>('PillsPager1');
  DotsPager1 := FindElement<TWinUIDotsPager>('DotsPager1');
  BorderedPager1 := FindElement<TWinUIBorderedPager>('BorderedPager1');
  TrackPager1 := FindElement<TWinUITrackPager>('TrackPager1');
  SegmentedPager1 := FindElement<TWinUISegmentedPager>('SegmentedPager1');
  ProgressPager1 := FindElement<TWinUIProgressPager>('ProgressPager1');
  StepsPager1 := FindElement<TWinUIStepsPager>('StepsPager1');
  StepsPage := FindElement<TWinUIStackPanel>('StepsPage');
  BackButton := FindElement<TWinUIButton>('BackButton');
  NextButton := FindElement<TWinUIButton>('NextButton');
  NumberedSteps1 := FindElement<TWinUINumberedSteps>('NumberedSteps1');
  SegmentBarSteps1 := FindElement<TWinUISegmentBarSteps>('SegmentBarSteps1');
  CheckoutSteps1 := FindElement<TWinUICheckoutSteps>('CheckoutSteps1');
  OrderTrackingSteps1 := FindElement<TWinUIOrderTrackingSteps>('OrderTrackingSteps1');
  BreadcrumbSteps1 := FindElement<TWinUIBreadcrumbSteps>('BreadcrumbSteps1');
  RingSteps1 := FindElement<TWinUIRingSteps>('RingSteps1');
  TabBarsPage := FindElement<TWinUIStackPanel>('TabBarsPage');
  PillBar := FindElement<TWinUISlidingPillTabBar>('PillBar');
  BulgeBar := FindElement<TWinUILiquidBulgeTabBar>('BulgeBar');
  NotchBar := FindElement<TWinUIFloatingNotchTabBar>('NotchBar');
  FillBar := FindElement<TWinUIIconFillTabBar>('FillBar');
  LabelBar := FindElement<TWinUIExpandingLabelTabBar>('LabelBar');
  BubbleBar := FindElement<TWinUIBubbleFloatTabBar>('BubbleBar');
  ButtonsPage := FindElement<TWinUIStackPanel>('ButtonsPage');
  HoldButton1 := FindElement<TWinUIHoldButton>('HoldButton1');
  SendButton1 := FindElement<TWinUISendButton>('SendButton1');
  ConfettiButton1 := FindElement<TWinUIConfettiButton>('ConfettiButton1');
  CopyButton1 := FindElement<TWinUICopyButton>('CopyButton1');
  ShineButton1 := FindElement<TWinUIShineButton>('ShineButton1');
  SlideButton1 := FindElement<TWinUISlideButton>('SlideButton1');
  StatusDot := FindElement<TWinUIEllipse>('StatusDot');
  StatusText := FindElement<TWinUITextBlock>('StatusText');
  // Event wiring
  // MainWindow.xaml(161): Click="OriginalClick"
  OriginalSwatch.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('OriginalClick'));
  // MainWindow.xaml(164): Click="SunsetClick"
  SunsetSwatch.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('SunsetClick'));
  // MainWindow.xaml(167): Click="MintClick"
  MintSwatch.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('MintClick'));
  // MainWindow.xaml(170): Click="OceanClick"
  OceanSwatch.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('OceanClick'));
  // MainWindow.xaml(181): Toggled="TransparencyToggled"
  TransparencySwitch.OnToggled := TWinUIRoutedEventHandler(PublishedMethod('TransparencyToggled'));
  // MainWindow.xaml(183): ValueChanged="GlassChanged"
  GlassSlider.OnValueChanged := TWinUIRangeBaseValueChangedEventHandler(PublishedMethod('GlassChanged'));
  // MainWindow.xaml(192): SelectionChanged="SectionChanged"
  SectionBar.OnSelectionChanged := TWinUIWinValueEventHandler(PublishedMethod('SectionChanged'));
  // MainWindow.xaml(227): Completed="OtpCompleted"
  OtpField1.OnCompleted := TWinUIWinValueEventHandler(PublishedMethod('OtpCompleted'));
  // MainWindow.xaml(240): Completed="CardCompleted"
  CardField1.OnCompleted := TWinUIWinValueEventHandler(PublishedMethod('CardCompleted'));
  // MainWindow.xaml(252): TextChanged="StrengthChanged"
  StrengthField1.OnTextChanged := TWinUIWinValueEventHandler(PublishedMethod('StrengthChanged'));
  // MainWindow.xaml(264): Submitted="GrowSubmitted"
  GrowField1.OnSubmitted := TWinUIWinValueEventHandler(PublishedMethod('GrowSubmitted'));
  // MainWindow.xaml(277): TagsChanged="TagsChanged"
  TagField1.OnTagsChanged := TWinUIWinValueEventHandler(PublishedMethod('TagsChanged'));
  // MainWindow.xaml(290): Accepted="GhostAccepted"
  GhostField1.OnAccepted := TWinUIWinValueEventHandler(PublishedMethod('GhostAccepted'));
  // MainWindow.xaml(310): Click="RefillClick"
  RefillButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RefillClick'));
  // MainWindow.xaml(329): Liked="CardLiked"
  CardStack1.OnLiked := TWinUIWinValueEventHandler(PublishedMethod('CardLiked'));
  // MainWindow.xaml(329): Passed="CardPassed"
  CardStack1.OnPassed := TWinUIWinValueEventHandler(PublishedMethod('CardPassed'));
  // MainWindow.xaml(341): Pinned="RowPinned"
  PinList1.OnPinned := TWinUIWinValueEventHandler(PublishedMethod('RowPinned'));
  // MainWindow.xaml(341): Unpinned="RowUnpinned"
  PinList1.OnUnpinned := TWinUIWinValueEventHandler(PublishedMethod('RowUnpinned'));
  // MainWindow.xaml(353): Deleted="RowDeleted"
  PeekList1.OnDeleted := TWinUIWinValueEventHandler(PublishedMethod('RowDeleted'));
  // MainWindow.xaml(365): Deleted="RowDeleted"
  LiquidList1.OnDeleted := TWinUIWinValueEventHandler(PublishedMethod('RowDeleted'));
  // MainWindow.xaml(377): Snoozed="RowSnoozed"
  SnoozeList1.OnSnoozed := TWinUIWinValueEventHandler(PublishedMethod('RowSnoozed'));
  // MainWindow.xaml(389): Deleted="RowDeleted"
  UndoList1.OnDeleted := TWinUIWinValueEventHandler(PublishedMethod('RowDeleted'));
  // MainWindow.xaml(389): Restored="RowRestored"
  UndoList1.OnRestored := TWinUIWinValueEventHandler(PublishedMethod('RowRestored'));
  // MainWindow.xaml(427): PageChanged="PageChanged"
  ClassicPager1.OnPageChanged := TWinUIWinValueEventHandler(PublishedMethod('PageChanged'));
  // MainWindow.xaml(439): PageChanged="PageChanged"
  PillsPager1.OnPageChanged := TWinUIWinValueEventHandler(PublishedMethod('PageChanged'));
  // MainWindow.xaml(451): PageChanged="PageChanged"
  DotsPager1.OnPageChanged := TWinUIWinValueEventHandler(PublishedMethod('PageChanged'));
  // MainWindow.xaml(463): PageChanged="PageChanged"
  BorderedPager1.OnPageChanged := TWinUIWinValueEventHandler(PublishedMethod('PageChanged'));
  // MainWindow.xaml(475): PageChanged="PageChanged"
  TrackPager1.OnPageChanged := TWinUIWinValueEventHandler(PublishedMethod('PageChanged'));
  // MainWindow.xaml(487): PageChanged="PageChanged"
  SegmentedPager1.OnPageChanged := TWinUIWinValueEventHandler(PublishedMethod('PageChanged'));
  // MainWindow.xaml(499): PageChanged="PageChanged"
  ProgressPager1.OnPageChanged := TWinUIWinValueEventHandler(PublishedMethod('PageChanged'));
  // MainWindow.xaml(511): PageChanged="PageChanged"
  StepsPager1.OnPageChanged := TWinUIWinValueEventHandler(PublishedMethod('PageChanged'));
  // MainWindow.xaml(531): Click="BackClick"
  BackButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('BackClick'));
  // MainWindow.xaml(532): Click="NextClick"
  NextButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('NextClick'));
  // MainWindow.xaml(552): StepChanged="StepChanged"
  NumberedSteps1.OnStepChanged := TWinUIWinValueEventHandler(PublishedMethod('StepChanged'));
  // MainWindow.xaml(564): StepChanged="StepChanged"
  SegmentBarSteps1.OnStepChanged := TWinUIWinValueEventHandler(PublishedMethod('StepChanged'));
  // MainWindow.xaml(576): StepChanged="StepChanged"
  CheckoutSteps1.OnStepChanged := TWinUIWinValueEventHandler(PublishedMethod('StepChanged'));
  // MainWindow.xaml(588): StepChanged="StepChanged"
  OrderTrackingSteps1.OnStepChanged := TWinUIWinValueEventHandler(PublishedMethod('StepChanged'));
  // MainWindow.xaml(600): StepChanged="StepChanged"
  BreadcrumbSteps1.OnStepChanged := TWinUIWinValueEventHandler(PublishedMethod('StepChanged'));
  // MainWindow.xaml(612): StepChanged="StepChanged"
  RingSteps1.OnStepChanged := TWinUIWinValueEventHandler(PublishedMethod('StepChanged'));
  // MainWindow.xaml(649): SelectionChanged="TabChanged"
  PillBar.OnSelectionChanged := TWinUIWinValueEventHandler(PublishedMethod('TabChanged'));
  // MainWindow.xaml(663): SelectionChanged="TabChanged"
  BulgeBar.OnSelectionChanged := TWinUIWinValueEventHandler(PublishedMethod('TabChanged'));
  // MainWindow.xaml(677): SelectionChanged="TabChanged"
  NotchBar.OnSelectionChanged := TWinUIWinValueEventHandler(PublishedMethod('TabChanged'));
  // MainWindow.xaml(691): SelectionChanged="TabChanged"
  FillBar.OnSelectionChanged := TWinUIWinValueEventHandler(PublishedMethod('TabChanged'));
  // MainWindow.xaml(705): SelectionChanged="TabChanged"
  LabelBar.OnSelectionChanged := TWinUIWinValueEventHandler(PublishedMethod('TabChanged'));
  // MainWindow.xaml(719): SelectionChanged="TabChanged"
  BubbleBar.OnSelectionChanged := TWinUIWinValueEventHandler(PublishedMethod('TabChanged'));
  // MainWindow.xaml(758): Confirmed="ButtonDone"
  HoldButton1.OnConfirmed := TWinUIWinValueEventHandler(PublishedMethod('ButtonDone'));
  // MainWindow.xaml(772): Click="ButtonDone"
  SendButton1.OnClick := TWinUIWinValueEventHandler(PublishedMethod('ButtonDone'));
  // MainWindow.xaml(784): Click="ButtonDone"
  ConfettiButton1.OnClick := TWinUIWinValueEventHandler(PublishedMethod('ButtonDone'));
  // MainWindow.xaml(797): Copied="ButtonDone"
  CopyButton1.OnCopied := TWinUIWinValueEventHandler(PublishedMethod('ButtonDone'));
  // MainWindow.xaml(811): Click="ButtonDone"
  ShineButton1.OnClick := TWinUIWinValueEventHandler(PublishedMethod('ButtonDone'));
  // MainWindow.xaml(823): Confirmed="ButtonDone"
  SlideButton1.OnConfirmed := TWinUIWinValueEventHandler(PublishedMethod('ButtonDone'));
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
