unit OrdersPage.Xaml;

{
  TOrdersPageBase: base class of the page TOrdersPage, generated from OrdersPage.xaml
  by RADWinUI XamlCodeGen 0.5 (tools/XamlCodeGen).

  DO NOT EDIT. Change OrdersPage.xaml or the published handlers of TOrdersPage
  in OrdersPage.pas; the build regenerates this unit.

  Fields      one per x:Name element, in XAML order
  Create      loads the page, fills the fields, wires the events
  Comments    name the XAML line each item comes from
}

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.DBControls,
  RADWinUI.TabBars,
  RADWinUI.Pages;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TOrdersPageBase = class(TWinUIXamlPage)
  protected
    CountText: TWinUITextBlock;             // OrdersPage.xaml(35) <TextBlock>
    StatusTabs: TWinUISlidingPillTabBar;    // OrdersPage.xaml(37) <SlidingPillTabBar>
    GridCard: TWinUIBorder;                 // OrdersPage.xaml(51) <Border>
    OrdersNavigator: TWinUIDBNavigator;     // OrdersPage.xaml(59) <DBNavigator>
    OrdersGrid: TWinUIDBGrid;               // OrdersPage.xaml(63) <DBGrid>
    FormCard: TWinUIBorder;                 // OrdersPage.xaml(69) <Border>
    OrderNoText: TWinUIDBText;              // OrdersPage.xaml(75) <DBText>
    TotalText: TWinUIDBText;                // OrdersPage.xaml(79) <DBText>
    CustomerCombo: TWinUIDBLookupComboBox;  // OrdersPage.xaml(83) <DBLookupComboBox>
    CoffeeCombo: TWinUIDBLookupComboBox;    // OrdersPage.xaml(85) <DBLookupComboBox>
    KgBox: TWinUIDBNumberBox;               // OrdersPage.xaml(92) <DBNumberBox>
    DatePicker: TWinUIDBDatePicker;         // OrdersPage.xaml(93) <DBDatePicker>
    StatusCombo: TWinUIDBComboBox;          // OrdersPage.xaml(95) <DBComboBox>
    NoteMemo: TWinUIDBMemo;                 // OrdersPage.xaml(97) <DBMemo>
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
  // OrdersPage.xaml(1): the page; event attributes became the
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
    '      <Setter Property="Padding" Value="20,16,20,20" />' + sLineBreak +
    '    </Style>' + sLineBreak +
    '  </Page.Resources>' + sLineBreak +
    '' + sLineBreak +
    '  <Grid RowSpacing="18" Padding="0,4,0,0">' + sLineBreak +
    '    <Grid.RowDefinitions>' + sLineBreak +
    '      <RowDefinition Height="Auto" />' + sLineBreak +
    '      <RowDefinition Height="*" />' + sLineBreak +
    '    </Grid.RowDefinitions>' + sLineBreak +
    '' + sLineBreak +
    '    <Grid ColumnSpacing="24">' + sLineBreak +
    '      <Grid.ColumnDefinitions>' + sLineBreak +
    '        <ColumnDefinition Width="*" />' + sLineBreak +
    '        <ColumnDefinition Width="Auto" />' + sLineBreak +
    '      </Grid.ColumnDefinitions>' + sLineBreak +
    '      <StackPanel Spacing="2" VerticalAlignment="Center">' + sLineBreak +
    '        <TextBlock x:Uid="OrdersTitle" Text="Orders" FontSize="32" FontWeight="SemiBold" />' + sLineBreak +
    '        <TextBlock x:Name="CountText" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '      </StackPanel>' + sLineBreak +
    '      <ns2:SlidingPillTabBar x:Name="StatusTabs" x:Uid="StatusTabs" Grid.Column="1" Width="480" VerticalAlignment="Center" AutomationProperties.Name="Order status" Items="All:E8FD, Open:Clock, Roastin' +
    'g:ECAD, Shipped:E73E" ShowLabels="True" AccentFrom="#FFB36B" AccentTo="#E2452B" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush' +
    '}" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '' + sLineBreak +
    '    <Grid Grid.Row="1" ColumnSpacing="16">' + sLineBreak +
    '      <Grid.ColumnDefinitions>' + sLineBreak +
    '        <ColumnDefinition Width="1.9*" />' + sLineBreak +
    '        <ColumnDefinition Width="*" />' + sLineBreak +
    '      </Grid.ColumnDefinitions>' + sLineBreak +
    '' + sLineBreak +
    '      <Border x:Name="GridCard" Style="{StaticResource Card}">' + sLineBreak +
    '        <Grid RowSpacing="12">' + sLineBreak +
    '          <Grid.RowDefinitions>' + sLineBreak +
    '            <RowDefinition Height="Auto" />' + sLineBreak +
    '            <RowDefinition Height="*" />' + sLineBreak +
    '          </Grid.RowDefinitions>' + sLineBreak +
    '          <Grid>' + sLineBreak +
    '            <TextBlock x:Uid="AllOrdersTitle" Text="All orders" FontSize="16" FontWeight="SemiBold" VerticalAlignment="Center" />' + sLineBreak +
    '            <ns2:DBNavigator x:Name="OrdersNavigator" HorizontalAlignment="Right" DataSource="OrdersSource" AutomationProperties.Name="Orders navigator" VisibleButtons="First, Prior, Next, Last, Inser' +
    't, Delete, Post, Cancel" />' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <ns2:DBGrid x:Name="OrdersGrid" Grid.Row="1" DataSource="OrdersSource" ReadOnly="True" Width="Auto" Height="Auto" AutomationProperties.Name="Orders" Columns="OrderNo:62, OrderDate:96, Custom' +
    'er:150, Coffee:100, Total:80, Status:86" />' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </Border>' + sLineBreak +
    '' + sLineBreak +
    '      <Border x:Name="FormCard" Grid.Column="1" Style="{StaticResource Card}">' + sLineBreak +
    '        <ScrollViewer>' + sLineBreak +
    '          <StackPanel Spacing="14">' + sLineBreak +
    '            <Grid>' + sLineBreak +
    '              <StackPanel>' + sLineBreak +
    '                <TextBlock x:Uid="OrderLabel" Text="Order" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                <ns2:DBText x:Name="OrderNoText" DataSource="OrdersSource" DataField="OrderNo" FontSize="24" FontWeight="SemiBold" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <StackPanel HorizontalAlignment="Right">' + sLineBreak +
    '                <TextBlock x:Uid="TotalLabel" Text="Total" HorizontalAlignment="Right" Foreground="{ThemeResource TextFillColorSecondaryBrush}" />' + sLineBreak +
    '                <ns2:DBText x:Name="TotalText" DataSource="OrdersSource" DataField="Total" FontSize="24" FontWeight="SemiBold" Foreground="#F0652B" HorizontalAlignment="Right" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '            <ns2:DBLookupComboBox x:Name="CustomerCombo" x:Uid="CustomerCombo" DataSource="OrdersSource" DataField="CustomerID" ListSource="CustomersSource" KeyField="ID" ListField="Name" Header="Cafe' +
    '" HorizontalAlignment="Stretch" />' + sLineBreak +
    '            <ns2:DBLookupComboBox x:Name="CoffeeCombo" x:Uid="CoffeeCombo" DataSource="OrdersSource" DataField="CoffeeID" ListSource="CoffeesSource" KeyField="ID" ListField="Name" Header="Coffee" Hori' +
    'zontalAlignment="Stretch" />' + sLineBreak +
    '            <Grid ColumnSpacing="14">' + sLineBreak +
    '              <Grid.ColumnDefinitions>' + sLineBreak +
    '                <ColumnDefinition />' + sLineBreak +
    '                <ColumnDefinition />' + sLineBreak +
    '              </Grid.ColumnDefinitions>' + sLineBreak +
    '              <ns2:DBNumberBox x:Name="KgBox" x:Uid="KgBox" DataSource="OrdersSource" DataField="Kg" Header="Kilograms" />' + sLineBreak +
    '              <ns2:DBDatePicker x:Name="DatePicker" x:Uid="DatePicker" Grid.Column="1" DataSource="OrdersSource" DataField="OrderDate" Header="Date" />' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '            <ns2:DBComboBox x:Name="StatusCombo" x:Uid="StatusCombo" DataSource="OrdersSource" DataField="Status" Items="Open, Roasting, Shipped" Header="Status" HorizontalAlignment="Stretch" />' + sLineBreak +
    '            <ns2:DBMemo x:Name="NoteMemo" x:Uid="NoteMemo" DataSource="OrdersSource" DataField="Note" Header="Note" Height="88" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </ScrollViewer>' + sLineBreak +
    '      </Border>' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '  </Grid>' + sLineBreak +
    '</Page>';
  {$IFDEF DEBUG}
  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild
  XamlShape = 'F:CountText:TWinUITextBlock;F:StatusTabs:TWinUISlidingPillTabBar;F:GridCard:TWinUIBorder;F:OrdersNavigator:TWinUIDBNavigator;F:OrdersGrid:TWinUIDBGrid;F:FormCard:TWinUIBorder;F:OrderNoText:TWinUIDBTex' +
    't;F:TotalText:TWinUIDBText;F:CustomerCombo:TWinUIDBLookupComboBox;F:CoffeeCombo:TWinUIDBLookupComboBox;F:KgBox:TWinUIDBNumberBox;F:DatePicker:TWinUIDBDatePicker;F:StatusCombo:TWinUIDBComboBox;F:NoteMe' +
    'mo:TWinUIDBMemo;E:StatusTabs.SelectionChanged=StatusChanged';
  {$ENDIF}

constructor TOrdersPageBase.Create;
begin
  inherited CreateFromXaml(PageXaml);
  WireXaml;
  {$IFDEF DEBUG}
  AddHelper(TXamlHotReload.Watch(Self, 'OrdersPage.xaml', XamlShape, ReloadXaml));
  {$ENDIF}
end;

// The x:Name fields and the event wiring of the content, again after a hot reload
procedure TOrdersPageBase.WireXaml;
begin
  // x:Name elements
  CountText := FindElement<TWinUITextBlock>('CountText');
  StatusTabs := FindElement<TWinUISlidingPillTabBar>('StatusTabs');
  GridCard := FindElement<TWinUIBorder>('GridCard');
  OrdersNavigator := FindElement<TWinUIDBNavigator>('OrdersNavigator');
  OrdersGrid := FindElement<TWinUIDBGrid>('OrdersGrid');
  FormCard := FindElement<TWinUIBorder>('FormCard');
  OrderNoText := FindElement<TWinUIDBText>('OrderNoText');
  TotalText := FindElement<TWinUIDBText>('TotalText');
  CustomerCombo := FindElement<TWinUIDBLookupComboBox>('CustomerCombo');
  CoffeeCombo := FindElement<TWinUIDBLookupComboBox>('CoffeeCombo');
  KgBox := FindElement<TWinUIDBNumberBox>('KgBox');
  DatePicker := FindElement<TWinUIDBDatePicker>('DatePicker');
  StatusCombo := FindElement<TWinUIDBComboBox>('StatusCombo');
  NoteMemo := FindElement<TWinUIDBMemo>('NoteMemo');
  // Event wiring
  // OrdersPage.xaml(37): SelectionChanged="StatusChanged"
  StatusTabs.OnSelectionChanged := TWinUIWinValueEventHandler(PublishedMethod('StatusChanged'));
end;

{$IFDEF DEBUG}
// Hot reload: OrdersPage.xaml edited in the IDE while the app runs
procedure TOrdersPageBase.ReloadXaml(const AXaml: string);
begin
  ReplaceXaml(AXaml);
  WireXaml;
end;
{$ENDIF}

end.
