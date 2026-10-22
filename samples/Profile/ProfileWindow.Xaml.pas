unit ProfileWindow.Xaml;

{
  TProfileWindowBase: base class of TProfileWindow, generated from ProfileWindow.xaml
  by RADWinUI XamlCodeGen 0.4 (tools/XamlCodeGen).

  DO NOT EDIT. Change ProfileWindow.xaml or the published handlers of TProfileWindow
  in ProfileWindow.pas; the build regenerates this unit.

  Fields      one per x:Name element, in XAML order
  Create      window settings, content, fields, event wiring
  Comments    name the XAML line each item comes from
}

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Forms,
  ProfileViewModel;  // TProfile, the DataContextType

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TProfileWindowBase = class(TWinUIWindow)
  strict private
    FViewModel: TProfile;
    procedure SetViewModel(AValue: TProfile);
  protected
    NameBox: TWinUITextBox;      // ProfileWindow.xaml(12) <TextBox>
    CityBox: TWinUITextBox;      // ProfileWindow.xaml(14) <TextBox>
    VipBox: TWinUICheckBox;      // ProfileWindow.xaml(16) <CheckBox>
    Summary: TWinUITextBlock;    // ProfileWindow.xaml(17) <TextBlock>
    Greeting: TWinUITextBlock;   // ProfileWindow.xaml(19) <TextBlock>
    CityUpper: TWinUITextBlock;  // ProfileWindow.xaml(20) <TextBlock>
    VipBadge: TWinUITextBlock;   // ProfileWindow.xaml(21) <TextBlock>
  public
    constructor Create; override;
    /// <summary>
    ///   The TProfile the XAML binds to (ProfileWindow.xaml(1): DataContextType);
    ///   setting it sets DataContext. The window does not own it.
    /// </summary>
    property ViewModel: TProfile read FViewModel write SetViewModel;
  end;
  {$M-}

implementation

const
  // ProfileWindow.xaml(10): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Spacing="12" Padding="24">' + sLineBreak +
    '        ' + sLineBreak +
    '        <TextBox x:Name="NameBox" Header="Name" Text="{Binding Name, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" />' + sLineBreak +
    '        <TextBox x:Name="CityBox" Header="City" Text="{Binding City, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" />' + sLineBreak +
    '        <CheckBox x:Name="VipBox" Content="VIP" IsChecked="{Binding IsVip, Mode=TwoWay}" />' + sLineBreak +
    '        <TextBlock x:Name="Summary" Text="{Binding Summary}" FontSize="20" />' + sLineBreak +
    '        ' + sLineBreak +
    '        <TextBlock x:Name="Greeting" Text="{Binding Name, Converter={StaticResource Format}, ConverterParameter=''Hello, %s!''}" />' + sLineBreak +
    '        <TextBlock x:Name="CityUpper" Text="{Binding City, Converter={StaticResource Upper}}" />' + sLineBreak +
    '        <TextBlock x:Name="VipBadge" Text="VIP customer" Visibility="{Binding IsVip, Converter={StaticResource BoolToVisibility}}" />' + sLineBreak +
    '        <Button Content="Reset from code" x:Name="_rw1" />' + sLineBreak +
    '    </StackPanel>' + sLineBreak;

constructor TProfileWindowBase.Create;
begin
  inherited;
  // ProfileWindow.xaml(1): <Window> attributes
  Title := 'Profile';
  Width := 420;
  Height := 460;
  LoadContent(ContentXaml);
  // x:Name elements
  NameBox := FindElement<TWinUITextBox>('NameBox');
  CityBox := FindElement<TWinUITextBox>('CityBox');
  VipBox := FindElement<TWinUICheckBox>('VipBox');
  Summary := FindElement<TWinUITextBlock>('Summary');
  Greeting := FindElement<TWinUITextBlock>('Greeting');
  CityUpper := FindElement<TWinUITextBlock>('CityUpper');
  VipBadge := FindElement<TWinUITextBlock>('VipBadge');
  // Event wiring
  // ProfileWindow.xaml(23): Click="ResetClick"
  FindElement<TWinUIButton>('_rw1').OnClick := TWinUIRoutedEventHandler(PublishedMethod('ResetClick'));
end;

procedure TProfileWindowBase.SetViewModel(AValue: TProfile);
begin
  FViewModel := AValue;
  DataContext := AValue;
end;

end.
