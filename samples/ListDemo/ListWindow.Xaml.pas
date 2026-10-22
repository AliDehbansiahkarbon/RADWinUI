unit ListWindow.Xaml;

{
  TListWindowBase: base class of TListWindow, generated from ListWindow.xaml
  by RADWinUI XamlCodeGen 0.4 (tools/XamlCodeGen).

  DO NOT EDIT. Change ListWindow.xaml or the published handlers of TListWindow
  in ListWindow.pas; the build regenerates this unit.

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
  TListWindowBase = class(TWinUIWindow)
  protected
    Fruits: TWinUIListView;   // ListWindow.xaml(7) <ListView>
    NewItem: TWinUITextBox;   // ListWindow.xaml(13) <TextBox>
    Status: TWinUITextBlock;  // ListWindow.xaml(17) <TextBlock>
  public
    constructor Create; override;
  end;
  {$M-}

implementation

const
  // ListWindow.xaml(6): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Spacing="12" Padding="24">' + sLineBreak +
    '        <ListView x:Name="Fruits" Height="300">' + sLineBreak +
    '            <x:String>Apple</x:String>' + sLineBreak +
    '            <x:String>Banana</x:String>' + sLineBreak +
    '            <x:String>Cherry</x:String>' + sLineBreak +
    '        </ListView>' + sLineBreak +
    '        <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '            <TextBox x:Name="NewItem" PlaceholderText="New item" Width="200" />' + sLineBreak +
    '            <Button Content="Add" x:Name="_rw1" />' + sLineBreak +
    '            <Button Content="Remove" x:Name="_rw2" />' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '        <TextBlock x:Name="Status" />' + sLineBreak +
    '    </StackPanel>' + sLineBreak;

constructor TListWindowBase.Create;
begin
  inherited;
  // ListWindow.xaml(1): <Window> attributes
  Title := 'List demo';
  Width := 420;
  Height := 520;
  LoadContent(ContentXaml);
  // x:Name elements
  Fruits := FindElement<TWinUIListView>('Fruits');
  NewItem := FindElement<TWinUITextBox>('NewItem');
  Status := FindElement<TWinUITextBlock>('Status');
  // Event wiring
  // ListWindow.xaml(7): FruitsSelectionChanged by name
  Fruits.OnSelectionChanged := TWinUISelectionChangedEventHandler(PublishedMethod('FruitsSelectionChanged'));
  // ListWindow.xaml(14): Click="AddClick"
  FindElement<TWinUIButton>('_rw1').OnClick := TWinUIRoutedEventHandler(PublishedMethod('AddClick'));
  // ListWindow.xaml(15): Click="RemoveClick"
  FindElement<TWinUIButton>('_rw2').OnClick := TWinUIRoutedEventHandler(PublishedMethod('RemoveClick'));
end;

end.
