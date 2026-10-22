unit ContactsWindow.Xaml;

{
  TContactsWindowBase: base class of TContactsWindow, generated from ContactsWindow.xaml
  by RADWinUI XamlCodeGen 0.4 (tools/XamlCodeGen).

  DO NOT EDIT. Change ContactsWindow.xaml or the published handlers of TContactsWindow
  in ContactsWindow.pas; the build regenerates this unit.

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
  TContactsWindowBase = class(TWinUIWindow)
  protected
    ContactList: TWinUIListView;  // ContactsWindow.xaml(10) <ListView>
    NameBox: TWinUITextBox;       // ContactsWindow.xaml(27) <TextBox>
    Status: TWinUITextBlock;      // ContactsWindow.xaml(33) <TextBlock>
  public
    constructor Create; override;
  end;
  {$M-}

implementation

const
  // ContactsWindow.xaml(9): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Spacing="12" Padding="24">' + sLineBreak +
    '        <ListView x:Name="ContactList" Height="300">' + sLineBreak +
    '            ' + sLineBreak +
    '            ' + sLineBreak +
    '            <ListView.ItemTemplate>' + sLineBreak +
    '                <DataTemplate>' + sLineBreak +
    '                    <StackPanel Padding="0,6">' + sLineBreak +
    '                        <TextBlock Text="{Binding Name}" FontSize="16" />' + sLineBreak +
    '                        <TextBlock Text="{Binding Email}" Opacity="0.7" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                </DataTemplate>' + sLineBreak +
    '            </ListView.ItemTemplate>' + sLineBreak +
    '        </ListView>' + sLineBreak +
    '        <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '            <TextBox x:Name="NameBox" PlaceholderText="Name" Width="180" />' + sLineBreak +
    '            <Button Content="Add" x:Name="_rw1" />' + sLineBreak +
    '            <Button Content="Rename" x:Name="_rw2" />' + sLineBreak +
    '            <Button Content="Remove" x:Name="_rw3" />' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '        ' + sLineBreak +
    '        <TextBlock x:Name="Status" />' + sLineBreak +
    '    </StackPanel>' + sLineBreak;

constructor TContactsWindowBase.Create;
begin
  inherited;
  // ContactsWindow.xaml(1): <Window> attributes
  Title := 'Contacts';
  Width := 460;
  Height := 540;
  LoadContent(ContentXaml);
  // x:Name elements
  ContactList := FindElement<TWinUIListView>('ContactList');
  NameBox := FindElement<TWinUITextBox>('NameBox');
  Status := FindElement<TWinUITextBlock>('Status');
  // Event wiring
  // ContactsWindow.xaml(10): ContactListSelectionChanged by name
  ContactList.OnSelectionChanged := TWinUISelectionChangedEventHandler(PublishedMethod('ContactListSelectionChanged'));
  // ContactsWindow.xaml(28): Click="AddClick"
  FindElement<TWinUIButton>('_rw1').OnClick := TWinUIRoutedEventHandler(PublishedMethod('AddClick'));
  // ContactsWindow.xaml(29): Click="RenameClick"
  FindElement<TWinUIButton>('_rw2').OnClick := TWinUIRoutedEventHandler(PublishedMethod('RenameClick'));
  // ContactsWindow.xaml(30): Click="RemoveClick"
  FindElement<TWinUIButton>('_rw3').OnClick := TWinUIRoutedEventHandler(PublishedMethod('RemoveClick'));
end;

end.
