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
  RADWinUI.DBControls,
  RADWinUI.Forms;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TMainWindowBase = class(TWinUIWindow)
  protected
    Root: TWinUIGrid;                        // MainWindow.xaml(13) <Grid>
    Glass: TWinUIBorder;                     // MainWindow.xaml(90) <Border>
    GlassText: TWinUITextBlock;              // MainWindow.xaml(136) <TextBlock>
    TransparencySwitch: TWinUIToggleSwitch;  // MainWindow.xaml(139) <ToggleSwitch>
    GlassSlider: TWinUISlider;               // MainWindow.xaml(141) <Slider>
    CustomersNavigator: TWinUIDBNavigator;   // MainWindow.xaml(170) <DBNavigator>
    CustomersGrid: TWinUIDBGrid;             // MainWindow.xaml(172) <DBGrid>
    LogoImage: TWinUIDBImage;                // MainWindow.xaml(184) <DBImage>
    NameText: TWinUIDBText;                  // MainWindow.xaml(186) <DBText>
    CityText: TWinUIDBText;                  // MainWindow.xaml(187) <DBText>
    NameEdit: TWinUIDBEdit;                  // MainWindow.xaml(201) <DBEdit>
    CityEdit: TWinUIDBEdit;                  // MainWindow.xaml(202) <DBEdit>
    CountryCombo: TWinUIDBLookupComboBox;    // MainWindow.xaml(203) <DBLookupComboBox>
    BalanceBox: TWinUIDBNumberBox;           // MainWindow.xaml(205) <DBNumberBox>
    TierRadio: TWinUIDBRadioGroup;           // MainWindow.xaml(206) <DBRadioGroup>
    JoinedPicker: TWinUIDBDatePicker;        // MainWindow.xaml(208) <DBDatePicker>
    ActiveCheck: TWinUIDBCheckBox;           // MainWindow.xaml(209) <DBCheckBox>
    NewsletterSwitch: TWinUIDBToggleSwitch;  // MainWindow.xaml(210) <DBToggleSwitch>
    NotesMemo: TWinUIDBMemo;                 // MainWindow.xaml(213) <DBMemo>
    OrdersNavigator: TWinUIDBNavigator;      // MainWindow.xaml(239) <DBNavigator>
    OrdersGrid: TWinUIDBGrid;                // MainWindow.xaml(243) <DBGrid>
    CustomerTiles: TWinUIDBCtrlGrid;         // MainWindow.xaml(258) <DBCtrlGrid>
    StatusDot: TWinUIEllipse;                // MainWindow.xaml(266) <Ellipse>
    StatusText: TWinUITextBlock;             // MainWindow.xaml(267) <TextBlock>
  public
    constructor Create; override;
  end;
  {$M-}

implementation

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
    '            <SolidColorBrush x:Key="PageBrush" Color="#F2F5F8" />' + sLineBreak +
    '            <SolidColorBrush x:Key="CardBrush" Color="#E6FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="CardEdgeBrush" Color="#14000000" />' + sLineBreak +
    '            <SolidColorBrush x:Key="InkBrush" Color="#16202B" />' + sLineBreak +
    '            <SolidColorBrush x:Key="MutedBrush" Color="#566473" />' + sLineBreak +
    '            <SolidColorBrush x:Key="FaintBrush" Color="#7F8C99" />' + sLineBreak +
    '            <SolidColorBrush x:Key="ChipBrush" Color="#E6ECF2" />' + sLineBreak +
    '            <SolidColorBrush x:Key="TileBrush" Color="#F6F8FB" />' + sLineBreak +
    '            <Color x:Key="GlowColorA">#2C1F8FFF</Color>' + sLineBreak +
    '            <Color x:Key="GlowColorB">#2422C3A6</Color>' + sLineBreak +
    '          </ResourceDictionary>' + sLineBreak +
    '          <ResourceDictionary x:Key="Dark">' + sLineBreak +
    '            <SolidColorBrush x:Key="PageBrush" Color="#0D1117" />' + sLineBreak +
    '            <SolidColorBrush x:Key="CardBrush" Color="#E6141A22" />' + sLineBreak +
    '            <SolidColorBrush x:Key="CardEdgeBrush" Color="#232B36" />' + sLineBreak +
    '            <SolidColorBrush x:Key="InkBrush" Color="#FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="MutedBrush" Color="#97A3B2" />' + sLineBreak +
    '            <SolidColorBrush x:Key="FaintBrush" Color="#728090" />' + sLineBreak +
    '            <SolidColorBrush x:Key="ChipBrush" Color="#1C2430" />' + sLineBreak +
    '            <SolidColorBrush x:Key="TileBrush" Color="#18202A" />' + sLineBreak +
    '            <Color x:Key="GlowColorA">#441F8FFF</Color>' + sLineBreak +
    '            <Color x:Key="GlowColorB">#3022C3A6</Color>' + sLineBreak +
    '          </ResourceDictionary>' + sLineBreak +
    '        </ResourceDictionary.ThemeDictionaries>' + sLineBreak +
    '        <Style x:Key="Card" TargetType="Border">' + sLineBreak +
    '          <Setter Property="Background" Value="{ThemeResource CardBrush}" />' + sLineBreak +
    '          <Setter Property="BorderBrush" Value="{ThemeResource CardEdgeBrush}" />' + sLineBreak +
    '          <Setter Property="BorderThickness" Value="1" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="20" />' + sLineBreak +
    '          <Setter Property="Padding" Value="20,16,20,20" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="CardTitle" TargetType="TextBlock">' + sLineBreak +
    '          <Setter Property="FontSize" Value="16" />' + sLineBreak +
    '          <Setter Property="FontWeight" Value="SemiBold" />' + sLineBreak +
    '          <Setter Property="Foreground" Value="{ThemeResource InkBrush}" />' + sLineBreak +
    '          <Setter Property="VerticalAlignment" Value="Center" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="CardClass" TargetType="TextBlock">' + sLineBreak +
    '          <Setter Property="FontFamily" Value="Cascadia Mono, Consolas" />' + sLineBreak +
    '          <Setter Property="FontSize" Value="11.5" />' + sLineBreak +
    '          <Setter Property="Foreground" Value="{ThemeResource FaintBrush}" />' + sLineBreak +
    '          <Setter Property="VerticalAlignment" Value="Center" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="Chip" TargetType="Border">' + sLineBreak +
    '          <Setter Property="Background" Value="{ThemeResource ChipBrush}" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="11" />' + sLineBreak +
    '          <Setter Property="Padding" Value="10,3,10,4" />' + sLineBreak +
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
    '        ' + sLineBreak +
    '        <DataTemplate x:Key="CustomerTile">' + sLineBreak +
    '          <Border Width="190" Padding="14,10,14,12" CornerRadius="12" Background="{ThemeResource TileBrush}">' + sLineBreak +
    '            <StackPanel Spacing="2">' + sLineBreak +
    '              <TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" />' + sLineBreak +
    '              <TextBlock Text="{Binding City}" FontSize="12" Opacity="0.7" />' + sLineBreak +
    '              <TextBlock Text="{Binding Tier}" FontSize="12" Opacity="0.7" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '        </DataTemplate>' + sLineBreak +
    '      </ResourceDictionary>' + sLineBreak +
    '    </Grid.Resources>' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Border x:Name="Glass" Background="{ThemeResource PageBrush}" CornerRadius="8" Opacity="0.65" />' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Ellipse Width="820" Height="820" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="-260,-340,0,0" IsHitTestVisible="False">' + sLineBreak +
    '      <Ellipse.Fill>' + sLineBreak +
    '        <RadialGradientBrush>' + sLineBreak +
    '          <GradientStop Color="{ThemeResource GlowColorA}" Offset="0" />' + sLineBreak +
    '          <GradientStop Color="#001F8FFF" Offset="1" />' + sLineBreak +
    '        </RadialGradientBrush>' + sLineBreak +
    '      </Ellipse.Fill>' + sLineBreak +
    '    </Ellipse>' + sLineBreak +
    '    <Ellipse Width="900" Height="900" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,-300,-380" IsHitTestVisible="False">' + sLineBreak +
    '      <Ellipse.Fill>' + sLineBreak +
    '        <RadialGradientBrush>' + sLineBreak +
    '          <GradientStop Color="{ThemeResource GlowColorB}" Offset="0" />' + sLineBreak +
    '          <GradientStop Color="#0022C3A6" Offset="1" />' + sLineBreak +
    '        </RadialGradientBrush>' + sLineBreak +
    '      </Ellipse.Fill>' + sLineBreak +
    '    </Ellipse>' + sLineBreak +
    '' + sLineBreak +
    '    <ScrollViewer>' + sLineBreak +
    '      <Grid Padding="36,28,36,16" RowSpacing="20" MaxWidth="1320">' + sLineBreak +
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
    '              <TextBlock Style="{StaticResource ChipText}" Text="RADWinUI  ·  Tool Palette  ·  Data Controls" />' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <TextBlock Text="Customers and their orders" FontSize="32" FontWeight="SemiBold" Foreground="{ThemeResource InkBrush}" />' + sLineBreak +
    '            <TextBlock Text="Every control on this page is bound with DataSource and DataField, the Delphi way. The data is three FireDAC memory tables in a data module." FontSize="14" Foreground="{Th' +
    'emeResource MutedBrush}" TextWrapping="Wrap" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '          <Border Grid.Column="1" Style="{StaticResource Card}" Padding="20,14,20,14" VerticalAlignment="Center">' + sLineBreak +
    '            <StackPanel Spacing="2">' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                <TextBlock Style="{StaticResource Caption}" Text="TRANSPARENCY" />' + sLineBreak +
    '                <TextBlock x:Name="GlassText" Style="{StaticResource Caption}" Foreground="{ThemeResource MutedBrush}" Text="35%" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="10">' + sLineBreak +
    '                <ToggleSwitch x:Name="TransparencySwitch" OnContent="" OffContent="" MinWidth="0" IsOn="True" AutomationProperties.Name="Transparency" />' + sLineBreak +
    '                <Slider x:Name="GlassSlider" Width="110" Minimum="0" Maximum="90" StepFrequency="5" Value="35" AutomationProperties.Name="Transparency level" VerticalAlignment="Center" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '' + sLineBreak +
    '        ' + sLineBreak +
    '        <Grid Grid.Row="1" ColumnSpacing="20">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition Width="1.25*" />' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '' + sLineBreak +
    '          <Border Style="{StaticResource Card}">' + sLineBreak +
    '            <Grid RowSpacing="12">' + sLineBreak +
    '              <Grid.RowDefinitions>' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="*" />' + sLineBreak +
    '              </Grid.RowDefinitions>' + sLineBreak +
    '              <Grid ColumnSpacing="12">' + sLineBreak +
    '                <Grid.ColumnDefinitions>' + sLineBreak +
    '                  <ColumnDefinition Width="*" />' + sLineBreak +
    '                  <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                </Grid.ColumnDefinitions>' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="10">' + sLineBreak +
    '                  <TextBlock Style="{StaticResource CardTitle}" Text="Customers" />' + sLineBreak +
    '                  <TextBlock Style="{StaticResource CardClass}" Text="TWinUIDBGrid  ·  TWinUIDBNavigator" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <ns2:DBNavigator x:Name="CustomersNavigator" AutomationProperties.Name="Customers navigator" Grid.Column="1" DataSource="CustomersSource" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <ns2:DBGrid x:Name="CustomersGrid" AutomationProperties.Name="Customers" Grid.Row="1" DataSource="CustomersSource" ReadOnly="True" Width="Auto" Height="452" Columns="Name:180, City:120, ' +
    'Tier:80, Balance:110, Joined:150" />' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '' + sLineBreak +
    '          <Border Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <StackPanel Spacing="14">' + sLineBreak +
    '              <Grid ColumnSpacing="14">' + sLineBreak +
    '                <Grid.ColumnDefinitions>' + sLineBreak +
    '                  <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                  <ColumnDefinition Width="*" />' + sLineBreak +
    '                </Grid.ColumnDefinitions>' + sLineBreak +
    '                <ns2:DBImage x:Name="LogoImage" DataSource="CustomersSource" DataField="Logo" Width="56" Height="56" Stretch="Uniform" />' + sLineBreak +
    '                <StackPanel Grid.Column="1" VerticalAlignment="Center" Spacing="2">' + sLineBreak +
    '                  <ns2:DBText x:Name="NameText" DataSource="CustomersSource" DataField="Name" FontSize="20" FontWeight="SemiBold" />' + sLineBreak +
    '                  <ns2:DBText x:Name="CityText" DataSource="CustomersSource" DataField="City" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <Grid ColumnSpacing="14" RowSpacing="12">' + sLineBreak +
    '                <Grid.ColumnDefinitions>' + sLineBreak +
    '                  <ColumnDefinition />' + sLineBreak +
    '                  <ColumnDefinition />' + sLineBreak +
    '                </Grid.ColumnDefinitions>' + sLineBreak +
    '                <Grid.RowDefinitions>' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                </Grid.RowDefinitions>' + sLineBreak +
    '                <ns2:DBEdit x:Name="NameEdit" DataSource="CustomersSource" DataField="Name" Header="Name" />' + sLineBreak +
    '                <ns2:DBEdit x:Name="CityEdit" Grid.Column="1" DataSource="CustomersSource" DataField="City" Header="City" />' + sLineBreak +
    '                <ns2:DBLookupComboBox x:Name="CountryCombo" Grid.Row="1" DataSource="CustomersSource" DataField="CountryID" ListSource="CountriesSource" KeyField="ID" ListField="CountryName" Header="C' +
    'ountry" />' + sLineBreak +
    '                <ns2:DBNumberBox x:Name="BalanceBox" Grid.Row="1" Grid.Column="1" DataSource="CustomersSource" DataField="Balance" Header="Balance" />' + sLineBreak +
    '                <ns2:DBRadioGroup x:Name="TierRadio" Grid.Row="2" DataSource="CustomersSource" DataField="Tier" Items="Bronze, Silver, Gold" Columns="3" Header="Tier" />' + sLineBreak +
    '                <ns2:DBDatePicker x:Name="JoinedPicker" Grid.Row="2" Grid.Column="1" DataSource="CustomersSource" DataField="Joined" Header="Customer since" />' + sLineBreak +
    '                <ns2:DBCheckBox x:Name="ActiveCheck" Grid.Row="3" DataSource="CustomersSource" DataField="Active" Text="Active customer" />' + sLineBreak +
    '                <ns2:DBToggleSwitch x:Name="NewsletterSwitch" Grid.Row="3" Grid.Column="1" DataSource="CustomersSource" DataField="Newsletter" ValueChecked="Y" ValueUnchecked="N" Header="Newsletter" /' +
    '>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <ns2:DBMemo x:Name="NotesMemo" DataSource="CustomersSource" DataField="Notes" Header="Notes" Height="72" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '' + sLineBreak +
    '        ' + sLineBreak +
    '        <Grid Grid.Row="2" ColumnSpacing="20">' + sLineBreak +
    '          <Grid.ColumnDefinitions>' + sLineBreak +
    '            <ColumnDefinition Width="1.25*" />' + sLineBreak +
    '            <ColumnDefinition Width="*" />' + sLineBreak +
    '          </Grid.ColumnDefinitions>' + sLineBreak +
    '' + sLineBreak +
    '          <Border Style="{StaticResource Card}">' + sLineBreak +
    '            <Grid RowSpacing="12">' + sLineBreak +
    '              <Grid.RowDefinitions>' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="*" />' + sLineBreak +
    '              </Grid.RowDefinitions>' + sLineBreak +
    '              <Grid ColumnSpacing="12">' + sLineBreak +
    '                <Grid.ColumnDefinitions>' + sLineBreak +
    '                  <ColumnDefinition Width="*" />' + sLineBreak +
    '                  <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                </Grid.ColumnDefinitions>' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="10">' + sLineBreak +
    '                  <TextBlock Style="{StaticResource CardTitle}" Text="Orders of this customer" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <ns2:DBNavigator x:Name="OrdersNavigator" AutomationProperties.Name="Orders navigator" Grid.Column="1" DataSource="OrdersSource" VisibleButtons="First, Prior, Next, Last, Insert, Delet' +
    'e, Post, Cancel" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              ' + sLineBreak +
    '              <ns2:DBGrid x:Name="OrdersGrid" AutomationProperties.Name="Orders" Grid.Row="1" DataSource="OrdersSource" SortOnHeaderClick="False" Width="Auto" Height="180" Columns="OrderNo:80, OrderDa' +
    'te:110, Product:200, Quantity:60, Total:100, Shipped:80" />' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '' + sLineBreak +
    '          <Border Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '            <Grid RowSpacing="12">' + sLineBreak +
    '              <Grid.RowDefinitions>' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="*" />' + sLineBreak +
    '              </Grid.RowDefinitions>' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="10">' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardTitle}" Text="All customers" />' + sLineBreak +
    '                <TextBlock Style="{StaticResource CardClass}" Text="TWinUIDBCtrlGrid" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <ns2:DBCtrlGrid x:Name="CustomerTiles" AutomationProperties.Name="Customer tiles" Grid.Row="1" DataSource="CustomersSource" Tiles="True" ReadOnly="True" ItemTemplate="{StaticResource Cus' +
    'tomerTile}" Width="Auto" Height="158" />' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '' + sLineBreak +
    '        ' + sLineBreak +
    '        <StackPanel Grid.Row="3" Orientation="Horizontal" Spacing="10">' + sLineBreak +
    '          <Ellipse x:Name="StatusDot" Width="8" Height="8" Fill="#22C3A6" VerticalAlignment="Center" />' + sLineBreak +
    '          <TextBlock x:Name="StatusText" FontSize="13" Foreground="{ThemeResource MutedBrush}" Text="Ready" />' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </Grid>' + sLineBreak +
    '    </ScrollViewer>' + sLineBreak +
    '  </Grid>' + sLineBreak;

constructor TMainWindowBase.Create;
begin
  inherited;
  // MainWindow.xaml(1): <Window> attributes
  Title := 'Data Controls';
  Width := 1280;
  Height := 1010;
  MinWidth := 1100;
  MinHeight := 800;
  Backdrop := TWinUIBackdrop.Transparent;
  ExtendsContentIntoTitleBar := True;
  Center;
  LoadContent(ContentXaml);
  // x:Name elements
  Root := FindElement<TWinUIGrid>('Root');
  Glass := FindElement<TWinUIBorder>('Glass');
  GlassText := FindElement<TWinUITextBlock>('GlassText');
  TransparencySwitch := FindElement<TWinUIToggleSwitch>('TransparencySwitch');
  GlassSlider := FindElement<TWinUISlider>('GlassSlider');
  CustomersNavigator := FindElement<TWinUIDBNavigator>('CustomersNavigator');
  CustomersGrid := FindElement<TWinUIDBGrid>('CustomersGrid');
  LogoImage := FindElement<TWinUIDBImage>('LogoImage');
  NameText := FindElement<TWinUIDBText>('NameText');
  CityText := FindElement<TWinUIDBText>('CityText');
  NameEdit := FindElement<TWinUIDBEdit>('NameEdit');
  CityEdit := FindElement<TWinUIDBEdit>('CityEdit');
  CountryCombo := FindElement<TWinUIDBLookupComboBox>('CountryCombo');
  BalanceBox := FindElement<TWinUIDBNumberBox>('BalanceBox');
  TierRadio := FindElement<TWinUIDBRadioGroup>('TierRadio');
  JoinedPicker := FindElement<TWinUIDBDatePicker>('JoinedPicker');
  ActiveCheck := FindElement<TWinUIDBCheckBox>('ActiveCheck');
  NewsletterSwitch := FindElement<TWinUIDBToggleSwitch>('NewsletterSwitch');
  NotesMemo := FindElement<TWinUIDBMemo>('NotesMemo');
  OrdersNavigator := FindElement<TWinUIDBNavigator>('OrdersNavigator');
  OrdersGrid := FindElement<TWinUIDBGrid>('OrdersGrid');
  CustomerTiles := FindElement<TWinUIDBCtrlGrid>('CustomerTiles');
  StatusDot := FindElement<TWinUIEllipse>('StatusDot');
  StatusText := FindElement<TWinUITextBlock>('StatusText');
  // Event wiring
  // MainWindow.xaml(139): Toggled="TransparencyToggled"
  TransparencySwitch.OnToggled := TWinUIRoutedEventHandler(PublishedMethod('TransparencyToggled'));
  // MainWindow.xaml(141): ValueChanged="GlassChanged"
  GlassSlider.OnValueChanged := TWinUIRangeBaseValueChangedEventHandler(PublishedMethod('GlassChanged'));
end;

end.
