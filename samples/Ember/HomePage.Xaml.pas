unit HomePage.Xaml;

{
  THomePageBase: base class of the page THomePage, generated from HomePage.xaml
  by RADWinUI XamlCodeGen 0.5 (tools/XamlCodeGen).

  DO NOT EDIT. Change HomePage.xaml or the published handlers of THomePage
  in HomePage.pas; the build regenerates this unit.

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
  THomePageBase = class(TWinUIXamlPage)
  protected
    GreetingText: TWinUITextBlock;         // HomePage.xaml(86) <TextBlock>
    DateText: TWinUITextBlock;             // HomePage.xaml(87) <TextBlock>
    NewOrderButton: TWinUIShineButton;     // HomePage.xaml(89) <ShineButton>
    KpiRow: TWinUIGrid;                    // HomePage.xaml(94) <Grid>
    RevenueCard: TWinUIBorder;             // HomePage.xaml(101) <Border>
    RevenueValue: TWinUITextBlock;         // HomePage.xaml(105) <TextBlock>
    RevenueDelta: TWinUITextBlock;         // HomePage.xaml(106) <TextBlock>
    OrdersCard: TWinUIBorder;              // HomePage.xaml(109) <Border>
    OpenOrdersValue: TWinUITextBlock;      // HomePage.xaml(113) <TextBlock>
    StockCard: TWinUIBorder;               // HomePage.xaml(117) <Border>
    StockValue: TWinUITextBlock;           // HomePage.xaml(121) <TextBlock>
    StockBar: TWinUIProgressBar;           // HomePage.xaml(122) <ProgressBar>
    BatchCard: TWinUIBorder;               // HomePage.xaml(125) <Border>
    BatchValue: TWinUITextBlock;           // HomePage.xaml(129) <TextBlock>
    BatchHint: TWinUITextBlock;            // HomePage.xaml(130) <TextBlock>
    WeekCard: TWinUIBorder;                // HomePage.xaml(141) <Border>
    WeekTotal: TWinUITextBlock;            // HomePage.xaml(149) <TextBlock>
    Chart: TWinUIGrid;                     // HomePage.xaml(151) <Grid>
    Value0: TWinUITextBlock;               // HomePage.xaml(162) <TextBlock>
    Bar0: TWinUIBorder;                    // HomePage.xaml(163) <Border>
    Day0: TWinUITextBlock;                 // HomePage.xaml(164) <TextBlock>
    Value1: TWinUITextBlock;               // HomePage.xaml(167) <TextBlock>
    Bar1: TWinUIBorder;                    // HomePage.xaml(168) <Border>
    Day1: TWinUITextBlock;                 // HomePage.xaml(169) <TextBlock>
    Value2: TWinUITextBlock;               // HomePage.xaml(172) <TextBlock>
    Bar2: TWinUIBorder;                    // HomePage.xaml(173) <Border>
    Day2: TWinUITextBlock;                 // HomePage.xaml(174) <TextBlock>
    Value3: TWinUITextBlock;               // HomePage.xaml(177) <TextBlock>
    Bar3: TWinUIBorder;                    // HomePage.xaml(178) <Border>
    Day3: TWinUITextBlock;                 // HomePage.xaml(179) <TextBlock>
    Value4: TWinUITextBlock;               // HomePage.xaml(182) <TextBlock>
    Bar4: TWinUIBorder;                    // HomePage.xaml(183) <Border>
    Day4: TWinUITextBlock;                 // HomePage.xaml(184) <TextBlock>
    Value5: TWinUITextBlock;               // HomePage.xaml(187) <TextBlock>
    Bar5: TWinUIBorder;                    // HomePage.xaml(188) <Border>
    Day5: TWinUITextBlock;                 // HomePage.xaml(189) <TextBlock>
    Value6: TWinUITextBlock;               // HomePage.xaml(192) <TextBlock>
    Bar6: TWinUIBorder;                    // HomePage.xaml(193) <Border>
    Day6: TWinUITextBlock;                 // HomePage.xaml(194) <TextBlock>
    RoastCard: TWinUIBorder;               // HomePage.xaml(201) <Border>
    CoffeeBox: TWinUIComboBox;             // HomePage.xaml(225) <ComboBox>
    KgText: TWinUITextBlock;               // HomePage.xaml(230) <TextBlock>
    KgSlider: TWinUISlider;                // HomePage.xaml(232) <Slider>
    CoffeeNotes: TWinUITextBlock;          // HomePage.xaml(234) <TextBlock>
    StartRoastButton: TWinUISlideButton;   // HomePage.xaml(236) <SlideButton>
    TopCard: TWinUIBorder;                 // HomePage.xaml(248) <Border>
    TopList: TWinUIItemsControl;           // HomePage.xaml(251) <ItemsControl>
    RecentCard: TWinUIBorder;              // HomePage.xaml(272) <Border>
    AllOrdersLink: TWinUIHyperlinkButton;  // HomePage.xaml(276) <HyperlinkButton>
    RecentList: TWinUIItemsControl;        // HomePage.xaml(279) <ItemsControl>
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
  // HomePage.xaml(1): the page; event attributes became the
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
    '      <Setter Property="Padding" Value="22,18,22,20" />' + sLineBreak +
    '    </Style>' + sLineBreak +
    '    <Style x:Key="CardTitle" TargetType="TextBlock">' + sLineBreak +
    '      <Setter Property="FontSize" Value="16" />' + sLineBreak +
    '      <Setter Property="FontWeight" Value="SemiBold" />' + sLineBreak +
    '    </Style>' + sLineBreak +
    '    <Style x:Key="Label" TargetType="TextBlock">' + sLineBreak +
    '      <Setter Property="FontSize" Value="13" />' + sLineBreak +
    '      <Setter Property="Foreground" Value="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '    </Style>' + sLineBreak +
    '    <Style x:Key="Value" TargetType="TextBlock">' + sLineBreak +
    '      <Setter Property="FontSize" Value="28" />' + sLineBreak +
    '      <Setter Property="FontWeight" Value="SemiBold" />' + sLineBreak +
    '    </Style>' + sLineBreak +
    '    <Style x:Key="Disc" TargetType="Border">' + sLineBreak +
    '      <Setter Property="Width" Value="40" />' + sLineBreak +
    '      <Setter Property="Height" Value="40" />' + sLineBreak +
    '      <Setter Property="CornerRadius" Value="20" />' + sLineBreak +
    '      <Setter Property="Background" Value="#26FF7A3D" />' + sLineBreak +
    '    </Style>' + sLineBreak +
    '    <Style x:Key="DiscIcon" TargetType="FontIcon">' + sLineBreak +
    '      <Setter Property="FontSize" Value="18" />' + sLineBreak +
    '      <Setter Property="Foreground" Value="#F0652B" />' + sLineBreak +
    '    </Style>' + sLineBreak +
    '    <Style x:Key="Bar" TargetType="Border">' + sLineBreak +
    '      <Setter Property="Width" Value="34" />' + sLineBreak +
    '      <Setter Property="Height" Value="40" />' + sLineBreak +
    '      <Setter Property="CornerRadius" Value="8,8,4,4" />' + sLineBreak +
    '      <Setter Property="Background" Value="#40F0652B" />' + sLineBreak +
    '      <Setter Property="HorizontalAlignment" Value="Center" />' + sLineBreak +
    '    </Style>' + sLineBreak +
    '    <Style x:Key="BarValue" TargetType="TextBlock">' + sLineBreak +
    '      <Setter Property="FontSize" Value="11" />' + sLineBreak +
    '      <Setter Property="HorizontalAlignment" Value="Center" />' + sLineBreak +
    '      <Setter Property="Foreground" Value="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '    </Style>' + sLineBreak +
    '    <Style x:Key="BarDay" TargetType="TextBlock">' + sLineBreak +
    '      <Setter Property="FontSize" Value="12" />' + sLineBreak +
    '      <Setter Property="HorizontalAlignment" Value="Center" />' + sLineBreak +
    '      <Setter Property="Foreground" Value="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '    </Style>' + sLineBreak +
    '    <LinearGradientBrush x:Key="EmberBrush" StartPoint="0,0" EndPoint="1,1">' + sLineBreak +
    '      <GradientStop Color="#FF9A4D" Offset="0" />' + sLineBreak +
    '      <GradientStop Color="#E2452B" Offset="0.6" />' + sLineBreak +
    '      <GradientStop Color="#9E2A1E" Offset="1" />' + sLineBreak +
    '    </LinearGradientBrush>' + sLineBreak +
    '    <LinearGradientBrush x:Key="TodayBarBrush" StartPoint="0,0" EndPoint="0,1">' + sLineBreak +
    '      <GradientStop Color="#FF9A4D" Offset="0" />' + sLineBreak +
    '      <GradientStop Color="#E2452B" Offset="1" />' + sLineBreak +
    '    </LinearGradientBrush>' + sLineBreak +
    '  </Page.Resources>' + sLineBreak +
    '' + sLineBreak +
    '  <ScrollViewer>' + sLineBreak +
    '    <Grid RowSpacing="18" Padding="0,4,0,8" MaxWidth="1240" HorizontalAlignment="Stretch">' + sLineBreak +
    '      <Grid.RowDefinitions>' + sLineBreak +
    '        <RowDefinition Height="Auto" />' + sLineBreak +
    '        <RowDefinition Height="Auto" />' + sLineBreak +
    '        <RowDefinition Height="Auto" />' + sLineBreak +
    '        <RowDefinition Height="Auto" />' + sLineBreak +
    '      </Grid.RowDefinitions>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <Grid ColumnSpacing="16">' + sLineBreak +
    '        <Grid.ColumnDefinitions>' + sLineBreak +
    '          <ColumnDefinition Width="*" />' + sLineBreak +
    '          <ColumnDefinition Width="Auto" />' + sLineBreak +
    '        </Grid.ColumnDefinitions>' + sLineBreak +
    '        <StackPanel Spacing="2" VerticalAlignment="Center">' + sLineBreak +
    '          <TextBlock x:Name="GreetingText" Text="Good morning" FontSize="32" FontWeight="SemiBold" />' + sLineBreak +
    '          <TextBlock x:Name="DateText" Style="{StaticResource Label}" FontSize="14" />' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '        <ns2:ShineButton x:Name="NewOrderButton" x:Uid="NewOrderButton" Grid.Column="1" Text="New order" VerticalAlignment="Center" AccentFrom="#FFB36B" AccentTo="#E2452B" />' + sLineBreak +
    '      </Grid>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <Grid x:Name="KpiRow" Grid.Row="1" ColumnSpacing="16">' + sLineBreak +
    '        <Grid.ColumnDefinitions>' + sLineBreak +
    '          <ColumnDefinition />' + sLineBreak +
    '          <ColumnDefinition />' + sLineBreak +
    '          <ColumnDefinition />' + sLineBreak +
    '          <ColumnDefinition />' + sLineBreak +
    '        </Grid.ColumnDefinitions>' + sLineBreak +
    '        <Border x:Name="RevenueCard" Style="{StaticResource Card}">' + sLineBreak +
    '          <StackPanel Spacing="10">' + sLineBreak +
    '            <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource DiscIcon}" Glyph="" /></Border>' + sLineBreak +
    '            <TextBlock x:Uid="RevenueLabel" Style="{StaticResource Label}" Text="Revenue today" />' + sLineBreak +
    '            <TextBlock x:Name="RevenueValue" Style="{StaticResource Value}" />' + sLineBreak +
    '            <TextBlock x:Name="RevenueDelta" FontSize="12" Foreground="#2E9E5B" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Border>' + sLineBreak +
    '        <Border x:Name="OrdersCard" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '          <StackPanel Spacing="10">' + sLineBreak +
    '            <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource DiscIcon}" Glyph="" /></Border>' + sLineBreak +
    '            <TextBlock x:Uid="OpenOrdersLabel" Style="{StaticResource Label}" Text="Open orders" />' + sLineBreak +
    '            <TextBlock x:Name="OpenOrdersValue" Style="{StaticResource Value}" />' + sLineBreak +
    '            <TextBlock x:Uid="OpenOrdersHint" FontSize="12" Style="{StaticResource Label}" Text="Waiting to be roasted or shipped" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Border>' + sLineBreak +
    '        <Border x:Name="StockCard" Grid.Column="2" Style="{StaticResource Card}">' + sLineBreak +
    '          <StackPanel Spacing="10">' + sLineBreak +
    '            <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource DiscIcon}" Glyph="" /></Border>' + sLineBreak +
    '            <TextBlock x:Uid="StockLabel" Style="{StaticResource Label}" Text="Green coffee in stock" />' + sLineBreak +
    '            <TextBlock x:Name="StockValue" Style="{StaticResource Value}" />' + sLineBreak +
    '            <ProgressBar x:Name="StockBar" Maximum="1000" Value="632" Foreground="#F0652B" Margin="0,6,0,0" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Border>' + sLineBreak +
    '        <Border x:Name="BatchCard" Grid.Column="3" Style="{StaticResource Card}">' + sLineBreak +
    '          <StackPanel Spacing="10">' + sLineBreak +
    '            <Border Style="{StaticResource Disc}"><FontIcon Style="{StaticResource DiscIcon}" Glyph="" /></Border>' + sLineBreak +
    '            <TextBlock x:Uid="BatchLabel" Style="{StaticResource Label}" Text="Roaster" />' + sLineBreak +
    '            <TextBlock x:Name="BatchValue" Style="{StaticResource Value}" />' + sLineBreak +
    '            <TextBlock x:Name="BatchHint" FontSize="12" Style="{StaticResource Label}" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Border>' + sLineBreak +
    '      </Grid>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <Grid Grid.Row="2" ColumnSpacing="16">' + sLineBreak +
    '        <Grid.ColumnDefinitions>' + sLineBreak +
    '          <ColumnDefinition Width="1.55*" />' + sLineBreak +
    '          <ColumnDefinition Width="*" />' + sLineBreak +
    '        </Grid.ColumnDefinitions>' + sLineBreak +
    '        <Border x:Name="WeekCard" Style="{StaticResource Card}">' + sLineBreak +
    '          <Grid RowSpacing="12">' + sLineBreak +
    '            <Grid.RowDefinitions>' + sLineBreak +
    '              <RowDefinition Height="Auto" />' + sLineBreak +
    '              <RowDefinition Height="*" />' + sLineBreak +
    '            </Grid.RowDefinitions>' + sLineBreak +
    '            <Grid>' + sLineBreak +
    '              <TextBlock x:Uid="WeekTitle" Style="{StaticResource CardTitle}" Text="Sales this week" />' + sLineBreak +
    '              <TextBlock x:Name="WeekTotal" HorizontalAlignment="Right" FontWeight="SemiBold" />' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '            <Grid x:Name="Chart" Grid.Row="1" Height="232" Padding="4,0">' + sLineBreak +
    '              <Grid.ColumnDefinitions>' + sLineBreak +
    '                <ColumnDefinition />' + sLineBreak +
    '                <ColumnDefinition />' + sLineBreak +
    '                <ColumnDefinition />' + sLineBreak +
    '                <ColumnDefinition />' + sLineBreak +
    '                <ColumnDefinition />' + sLineBreak +
    '                <ColumnDefinition />' + sLineBreak +
    '                <ColumnDefinition />' + sLineBreak +
    '              </Grid.ColumnDefinitions>' + sLineBreak +
    '              <StackPanel VerticalAlignment="Bottom" Spacing="6">' + sLineBreak +
    '                <TextBlock x:Name="Value0" Style="{StaticResource BarValue}" />' + sLineBreak +
    '                <Border x:Name="Bar0" Style="{StaticResource Bar}" />' + sLineBreak +
    '                <TextBlock x:Name="Day0" Style="{StaticResource BarDay}" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <StackPanel Grid.Column="1" VerticalAlignment="Bottom" Spacing="6">' + sLineBreak +
    '                <TextBlock x:Name="Value1" Style="{StaticResource BarValue}" />' + sLineBreak +
    '                <Border x:Name="Bar1" Style="{StaticResource Bar}" />' + sLineBreak +
    '                <TextBlock x:Name="Day1" Style="{StaticResource BarDay}" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <StackPanel Grid.Column="2" VerticalAlignment="Bottom" Spacing="6">' + sLineBreak +
    '                <TextBlock x:Name="Value2" Style="{StaticResource BarValue}" />' + sLineBreak +
    '                <Border x:Name="Bar2" Style="{StaticResource Bar}" />' + sLineBreak +
    '                <TextBlock x:Name="Day2" Style="{StaticResource BarDay}" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <StackPanel Grid.Column="3" VerticalAlignment="Bottom" Spacing="6">' + sLineBreak +
    '                <TextBlock x:Name="Value3" Style="{StaticResource BarValue}" />' + sLineBreak +
    '                <Border x:Name="Bar3" Style="{StaticResource Bar}" />' + sLineBreak +
    '                <TextBlock x:Name="Day3" Style="{StaticResource BarDay}" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <StackPanel Grid.Column="4" VerticalAlignment="Bottom" Spacing="6">' + sLineBreak +
    '                <TextBlock x:Name="Value4" Style="{StaticResource BarValue}" />' + sLineBreak +
    '                <Border x:Name="Bar4" Style="{StaticResource Bar}" />' + sLineBreak +
    '                <TextBlock x:Name="Day4" Style="{StaticResource BarDay}" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <StackPanel Grid.Column="5" VerticalAlignment="Bottom" Spacing="6">' + sLineBreak +
    '                <TextBlock x:Name="Value5" Style="{StaticResource BarValue}" />' + sLineBreak +
    '                <Border x:Name="Bar5" Style="{StaticResource Bar}" />' + sLineBreak +
    '                <TextBlock x:Name="Day5" Style="{StaticResource BarDay}" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <StackPanel Grid.Column="6" VerticalAlignment="Bottom" Spacing="6">' + sLineBreak +
    '                <TextBlock x:Name="Value6" Style="{StaticResource BarValue}" />' + sLineBreak +
    '                <Border x:Name="Bar6" Style="{StaticResource Bar}" Background="{StaticResource TodayBarBrush}" />' + sLineBreak +
    '                <TextBlock x:Name="Day6" Style="{StaticResource BarDay}" FontWeight="SemiBold" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '        </Border>' + sLineBreak +
    '' + sLineBreak +
    '        ' + sLineBreak +
    '        <Border x:Name="RoastCard" Grid.Column="1" CornerRadius="16" Padding="24,20" Background="{StaticResource EmberBrush}" RequestedTheme="Dark">' + sLineBreak +
    '          <Border.Resources>' + sLineBreak +
    '            <SolidColorBrush x:Key="SliderTrackValueFill" Color="White" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SliderTrackValueFillPointerOver" Color="White" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SliderTrackValueFillPressed" Color="White" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SliderThumbBackground" Color="White" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SliderThumbBackgroundPointerOver" Color="White" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SliderThumbBackgroundPressed" Color="White" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SliderTrackFill" Color="#59FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SliderTrackFillPointerOver" Color="#73FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SliderTrackFillPressed" Color="#73FFFFFF" />' + sLineBreak +
    '          </Border.Resources>' + sLineBreak +
    '          <Grid RowSpacing="14">' + sLineBreak +
    '            <Grid.RowDefinitions>' + sLineBreak +
    '              <RowDefinition Height="Auto" />' + sLineBreak +
    '              <RowDefinition Height="Auto" />' + sLineBreak +
    '              <RowDefinition Height="*" />' + sLineBreak +
    '              <RowDefinition Height="Auto" />' + sLineBreak +
    '            </Grid.RowDefinitions>' + sLineBreak +
    '            <StackPanel Orientation="Horizontal" Spacing="10">' + sLineBreak +
    '              <FontIcon Glyph="" FontSize="20" Foreground="White" />' + sLineBreak +
    '              <TextBlock x:Uid="NextRoastTitle" Text="Next roast" FontSize="18" FontWeight="SemiBold" Foreground="White" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '            <ComboBox x:Name="CoffeeBox" x:Uid="CoffeeBox" Grid.Row="1" Header="Coffee" HorizontalAlignment="Stretch" />' + sLineBreak +
    '            <StackPanel Grid.Row="2" Spacing="4">' + sLineBreak +
    '              <Grid>' + sLineBreak +
    '                <TextBlock x:Uid="BatchSizeLabel" Text="Batch size" Foreground="#E6FFFFFF" />' + sLineBreak +
    '                <TextBlock x:Name="KgText" HorizontalAlignment="Right" FontWeight="SemiBold" Foreground="White" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <Slider x:Name="KgSlider" Minimum="5" Maximum="25" StepFrequency="1" Value="12" AutomationProperties.Name="Batch size" />' + sLineBreak +
    '              <TextBlock x:Name="CoffeeNotes" FontSize="13" Foreground="#D9FFFFFF" TextWrapping="Wrap" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '            <ns2:SlideButton x:Name="StartRoastButton" x:Uid="StartRoastButton" Grid.Row="3" HorizontalAlignment="Stretch" Width="Auto" Text="Slide to start the roast" DoneText="Roasting" AccentFrom="' +
    '#FFC38A" AccentTo="#FF7A3D" />' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '        </Border>' + sLineBreak +
    '      </Grid>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <Grid Grid.Row="3" ColumnSpacing="16">' + sLineBreak +
    '        <Grid.ColumnDefinitions>' + sLineBreak +
    '          <ColumnDefinition />' + sLineBreak +
    '          <ColumnDefinition />' + sLineBreak +
    '        </Grid.ColumnDefinitions>' + sLineBreak +
    '        <Border x:Name="TopCard" Style="{StaticResource Card}">' + sLineBreak +
    '          <StackPanel Spacing="12">' + sLineBreak +
    '            <TextBlock x:Uid="TopTitle" Style="{StaticResource CardTitle}" Text="Best sellers, last 30 days" />' + sLineBreak +
    '            <ItemsControl x:Name="TopList">' + sLineBreak +
    '              <ItemsControl.ItemTemplate>' + sLineBreak +
    '                <DataTemplate>' + sLineBreak +
    '                  <Grid ColumnSpacing="12" Padding="0,6">' + sLineBreak +
    '                    <Grid.ColumnDefinitions>' + sLineBreak +
    '                      <ColumnDefinition Width="150" />' + sLineBreak +
    '                      <ColumnDefinition Width="*" />' + sLineBreak +
    '                      <ColumnDefinition Width="64" />' + sLineBreak +
    '                    </Grid.ColumnDefinitions>' + sLineBreak +
    '                    <StackPanel>' + sLineBreak +
    '                      <TextBlock Text="{Binding Name}" FontWeight="SemiBold" />' + sLineBreak +
    '                      <TextBlock Text="{Binding Origin}" FontSize="12" Opacity="0.65" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                    <ProgressBar Grid.Column="1" Value="{Binding Share}" Maximum="100" Foreground="#F0652B" VerticalAlignment="Center" />' + sLineBreak +
    '                    <TextBlock Grid.Column="2" Text="{Binding KgText}" HorizontalAlignment="Right" VerticalAlignment="Center" />' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                </DataTemplate>' + sLineBreak +
    '              </ItemsControl.ItemTemplate>' + sLineBreak +
    '            </ItemsControl>' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Border>' + sLineBreak +
    '        <Border x:Name="RecentCard" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '          <StackPanel Spacing="12">' + sLineBreak +
    '            <Grid>' + sLineBreak +
    '              <TextBlock x:Uid="RecentTitle" Style="{StaticResource CardTitle}" Text="Newest orders" />' + sLineBreak +
    '              <HyperlinkButton x:Name="AllOrdersLink" x:Uid="AllOrdersLink" Content="All orders" HorizontalAlignment="Right" Padding="4,0" />' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '            <ItemsControl x:Name="RecentList">' + sLineBreak +
    '              <ItemsControl.ItemTemplate>' + sLineBreak +
    '                <DataTemplate>' + sLineBreak +
    '                  <Grid ColumnSpacing="12" Padding="0,6">' + sLineBreak +
    '                    <Grid.ColumnDefinitions>' + sLineBreak +
    '                      <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                      <ColumnDefinition Width="*" />' + sLineBreak +
    '                      <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                    </Grid.ColumnDefinitions>' + sLineBreak +
    '                    <PersonPicture DisplayName="{Binding Customer}" Width="34" Height="34" />' + sLineBreak +
    '                    <StackPanel Grid.Column="1" VerticalAlignment="Center">' + sLineBreak +
    '                      <TextBlock Text="{Binding Customer}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" />' + sLineBreak +
    '                      <TextBlock Text="{Binding Detail}" FontSize="12" Opacity="0.65" TextTrimming="CharacterEllipsis" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                    <StackPanel Grid.Column="2" VerticalAlignment="Center" HorizontalAlignment="Right">' + sLineBreak +
    '                      <TextBlock Text="{Binding TotalText}" FontWeight="SemiBold" HorizontalAlignment="Right" />' + sLineBreak +
    '                      <TextBlock Text="{Binding Status}" FontSize="12" Foreground="#F0652B" HorizontalAlignment="Right" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                </DataTemplate>' + sLineBreak +
    '              </ItemsControl.ItemTemplate>' + sLineBreak +
    '            </ItemsControl>' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Border>' + sLineBreak +
    '      </Grid>' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '  </ScrollViewer>' + sLineBreak +
    '</Page>';
  {$IFDEF DEBUG}
  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild
  XamlShape = 'F:GreetingText:TWinUITextBlock;F:DateText:TWinUITextBlock;F:NewOrderButton:TWinUIShineButton;F:KpiRow:TWinUIGrid;F:RevenueCard:TWinUIBorder;F:RevenueValue:TWinUITextBlock;F:RevenueDelta:TWinUITextBloc' +
    'k;F:OrdersCard:TWinUIBorder;F:OpenOrdersValue:TWinUITextBlock;F:StockCard:TWinUIBorder;F:StockValue:TWinUITextBlock;F:StockBar:TWinUIProgressBar;F:BatchCard:TWinUIBorder;F:BatchValue:TWinUITextBlock;F' +
    ':BatchHint:TWinUITextBlock;F:WeekCard:TWinUIBorder;F:WeekTotal:TWinUITextBlock;F:Chart:TWinUIGrid;F:Value0:TWinUITextBlock;F:Bar0:TWinUIBorder;F:Day0:TWinUITextBlock;F:Value1:TWinUITextBlock;F:Bar1:TW' +
    'inUIBorder;F:Day1:TWinUITextBlock;F:Value2:TWinUITextBlock;F:Bar2:TWinUIBorder;F:Day2:TWinUITextBlock;F:Value3:TWinUITextBlock;F:Bar3:TWinUIBorder;F:Day3:TWinUITextBlock;F:Value4:TWinUITextBlock;F:Bar' +
    '4:TWinUIBorder;F:Day4:TWinUITextBlock;F:Value5:TWinUITextBlock;F:Bar5:TWinUIBorder;F:Day5:TWinUITextBlock;F:Value6:TWinUITextBlock;F:Bar6:TWinUIBorder;F:Day6:TWinUITextBlock;F:RoastCard:TWinUIBorder;F' +
    ':CoffeeBox:TWinUIComboBox;F:KgText:TWinUITextBlock;F:KgSlider:TWinUISlider;F:CoffeeNotes:TWinUITextBlock;F:StartRoastButton:TWinUISlideButton;F:TopCard:TWinUIBorder;F:TopList:TWinUIItemsControl;F:Rece' +
    'ntCard:TWinUIBorder;F:AllOrdersLink:TWinUIHyperlinkButton;F:RecentList:TWinUIItemsControl;E:AllOrdersLink.Click=AllOrdersClick;E:CoffeeBox.SelectionChanged=CoffeeChanged;E:KgSlider.ValueChanged=KgChan' +
    'ged;E:NewOrderButton.Click=NewOrderClick;E:StartRoastButton.Confirmed=StartRoastConfirmed';
  {$ENDIF}

constructor THomePageBase.Create;
begin
  inherited CreateFromXaml(PageXaml);
  WireXaml;
  {$IFDEF DEBUG}
  AddHelper(TXamlHotReload.Watch(Self, 'HomePage.xaml', XamlShape, ReloadXaml));
  {$ENDIF}
end;

// The x:Name fields and the event wiring of the content, again after a hot reload
procedure THomePageBase.WireXaml;
begin
  // x:Name elements
  GreetingText := FindElement<TWinUITextBlock>('GreetingText');
  DateText := FindElement<TWinUITextBlock>('DateText');
  NewOrderButton := FindElement<TWinUIShineButton>('NewOrderButton');
  KpiRow := FindElement<TWinUIGrid>('KpiRow');
  RevenueCard := FindElement<TWinUIBorder>('RevenueCard');
  RevenueValue := FindElement<TWinUITextBlock>('RevenueValue');
  RevenueDelta := FindElement<TWinUITextBlock>('RevenueDelta');
  OrdersCard := FindElement<TWinUIBorder>('OrdersCard');
  OpenOrdersValue := FindElement<TWinUITextBlock>('OpenOrdersValue');
  StockCard := FindElement<TWinUIBorder>('StockCard');
  StockValue := FindElement<TWinUITextBlock>('StockValue');
  StockBar := FindElement<TWinUIProgressBar>('StockBar');
  BatchCard := FindElement<TWinUIBorder>('BatchCard');
  BatchValue := FindElement<TWinUITextBlock>('BatchValue');
  BatchHint := FindElement<TWinUITextBlock>('BatchHint');
  WeekCard := FindElement<TWinUIBorder>('WeekCard');
  WeekTotal := FindElement<TWinUITextBlock>('WeekTotal');
  Chart := FindElement<TWinUIGrid>('Chart');
  Value0 := FindElement<TWinUITextBlock>('Value0');
  Bar0 := FindElement<TWinUIBorder>('Bar0');
  Day0 := FindElement<TWinUITextBlock>('Day0');
  Value1 := FindElement<TWinUITextBlock>('Value1');
  Bar1 := FindElement<TWinUIBorder>('Bar1');
  Day1 := FindElement<TWinUITextBlock>('Day1');
  Value2 := FindElement<TWinUITextBlock>('Value2');
  Bar2 := FindElement<TWinUIBorder>('Bar2');
  Day2 := FindElement<TWinUITextBlock>('Day2');
  Value3 := FindElement<TWinUITextBlock>('Value3');
  Bar3 := FindElement<TWinUIBorder>('Bar3');
  Day3 := FindElement<TWinUITextBlock>('Day3');
  Value4 := FindElement<TWinUITextBlock>('Value4');
  Bar4 := FindElement<TWinUIBorder>('Bar4');
  Day4 := FindElement<TWinUITextBlock>('Day4');
  Value5 := FindElement<TWinUITextBlock>('Value5');
  Bar5 := FindElement<TWinUIBorder>('Bar5');
  Day5 := FindElement<TWinUITextBlock>('Day5');
  Value6 := FindElement<TWinUITextBlock>('Value6');
  Bar6 := FindElement<TWinUIBorder>('Bar6');
  Day6 := FindElement<TWinUITextBlock>('Day6');
  RoastCard := FindElement<TWinUIBorder>('RoastCard');
  CoffeeBox := FindElement<TWinUIComboBox>('CoffeeBox');
  KgText := FindElement<TWinUITextBlock>('KgText');
  KgSlider := FindElement<TWinUISlider>('KgSlider');
  CoffeeNotes := FindElement<TWinUITextBlock>('CoffeeNotes');
  StartRoastButton := FindElement<TWinUISlideButton>('StartRoastButton');
  TopCard := FindElement<TWinUIBorder>('TopCard');
  TopList := FindElement<TWinUIItemsControl>('TopList');
  RecentCard := FindElement<TWinUIBorder>('RecentCard');
  AllOrdersLink := FindElement<TWinUIHyperlinkButton>('AllOrdersLink');
  RecentList := FindElement<TWinUIItemsControl>('RecentList');
  // Event wiring
  // HomePage.xaml(89): Click="NewOrderClick"
  NewOrderButton.OnClick := TWinUIWinValueEventHandler(PublishedMethod('NewOrderClick'));
  // HomePage.xaml(225): SelectionChanged="CoffeeChanged"
  CoffeeBox.OnSelectionChanged := TWinUISelectionChangedEventHandler(PublishedMethod('CoffeeChanged'));
  // HomePage.xaml(232): ValueChanged="KgChanged"
  KgSlider.OnValueChanged := TWinUIRangeBaseValueChangedEventHandler(PublishedMethod('KgChanged'));
  // HomePage.xaml(236): Confirmed="StartRoastConfirmed"
  StartRoastButton.OnConfirmed := TWinUIWinValueEventHandler(PublishedMethod('StartRoastConfirmed'));
  // HomePage.xaml(276): Click="AllOrdersClick"
  AllOrdersLink.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('AllOrdersClick'));
end;

{$IFDEF DEBUG}
// Hot reload: HomePage.xaml edited in the IDE while the app runs
procedure THomePageBase.ReloadXaml(const AXaml: string);
begin
  ReplaceXaml(AXaml);
  WireXaml;
end;
{$ENDIF}

end.
