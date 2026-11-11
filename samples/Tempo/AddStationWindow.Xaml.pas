unit AddStationWindow.Xaml;

{
  TAddStationWindowBase: base class of TAddStationWindow, generated from AddStationWindow.xaml
  by RADWinUI XamlCodeGen 0.4 (tools/XamlCodeGen).

  DO NOT EDIT. Change AddStationWindow.xaml or the published handlers of TAddStationWindow
  in AddStationWindow.pas; the build regenerates this unit.

  Fields      one per x:Name element, in XAML order
  Create      window settings, content, fields, event wiring
  Comments    name the XAML line each item comes from
}

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Forms;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TAddStationWindowBase = class(TWinUIWindow)
  protected
    NameBox: TWinUITextBox;      // AddStationWindow.xaml(10) <TextBox>
    GenreBox: TWinUIComboBox;    // AddStationWindow.xaml(12) <ComboBox>
    AddButton: TWinUIButton;     // AddStationWindow.xaml(20) <Button>
    CancelButton: TWinUIButton;  // AddStationWindow.xaml(22) <Button>
  public
    constructor Create; override;
  end;
  {$M-}

implementation

const
  // AddStationWindow.xaml(8): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Padding="24" Spacing="12">' + sLineBreak +
    '    <TextBlock Text="Add a station" Style="{StaticResource SubtitleTextBlockStyle}" />' + sLineBreak +
    '    <TextBox x:Name="NameBox" Header="Name" PlaceholderText="Night Owl" AutomationProperties.Name="Station name" />' + sLineBreak +
    '    <ComboBox x:Name="GenreBox" Header="Genre" SelectedIndex="0" HorizontalAlignment="Stretch">' + sLineBreak +
    '      <x:String>Chill</x:String>' + sLineBreak +
    '      <x:String>Jazz</x:String>' + sLineBreak +
    '      <x:String>Electronic</x:String>' + sLineBreak +
    '      <x:String>Classical</x:String>' + sLineBreak +
    '      <x:String>Rock</x:String>' + sLineBreak +
    '    </ComboBox>' + sLineBreak +
    '    <StackPanel Orientation="Horizontal" Spacing="8" HorizontalAlignment="Right">' + sLineBreak +
    '      <Button x:Name="AddButton" Content="Add" Style="{StaticResource AccentButtonStyle}" IsEnabled="False" />' + sLineBreak +
    '      <Button x:Name="CancelButton" Content="Cancel" />' + sLineBreak +
    '    </StackPanel>' + sLineBreak +
    '  </StackPanel>' + sLineBreak;

constructor TAddStationWindowBase.Create;
begin
  inherited;
  // AddStationWindow.xaml(1): <Window> attributes
  Title := 'Add station';
  Width := 400;
  Height := 300;
  Backdrop := TWinUIBackdrop.MicaAlt;
  CenterOnOwner;
  Resizable := False;
  Minimizable := False;
  Maximizable := False;
  LoadContent(ContentXaml);
  // x:Name elements
  NameBox := FindElement<TWinUITextBox>('NameBox');
  GenreBox := FindElement<TWinUIComboBox>('GenreBox');
  AddButton := FindElement<TWinUIButton>('AddButton');
  CancelButton := FindElement<TWinUIButton>('CancelButton');
  // Event wiring
  // AddStationWindow.xaml(10): TextChanged="NameChanged"
  NameBox.TextChanged.Add(NotifyProc<TWinUITextChangedEventArgs>('NameChanged'));
  // AddStationWindow.xaml(20): Click="AddClick"
  AddButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('AddClick'));
  // AddStationWindow.xaml(22): Click="CancelClick"
  CancelButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('CancelClick'));
end;

end.
