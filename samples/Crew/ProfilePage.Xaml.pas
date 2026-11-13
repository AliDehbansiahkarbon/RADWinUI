unit ProfilePage.Xaml;

{
  TProfilePageBase: base class of the page TProfilePage, generated from ProfilePage.xaml
  by RADWinUI XamlCodeGen 0.5 (tools/XamlCodeGen).

  DO NOT EDIT. Change ProfilePage.xaml or the published handlers of TProfilePage
  in ProfilePage.pas; the build regenerates this unit.

  Fields      one per x:Name element, in XAML order
  Create      loads the page, fills the fields, wires the events
  Comments    name the XAML line each item comes from
}

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Pages;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TProfilePageBase = class(TWinUIXamlPage)
  protected
    Picture: TWinUIPersonPicture;  // ProfilePage.xaml(11) <PersonPicture>
    PageTitle: TWinUITextBlock;    // ProfilePage.xaml(13) <TextBlock>
    Subtitle: TWinUITextBlock;     // ProfilePage.xaml(14) <TextBlock>
    NameBox: TWinUITextBox;        // ProfilePage.xaml(17) <TextBox>
    RoleBox: TWinUITextBox;        // ProfilePage.xaml(18) <TextBox>
    EmailBox: TWinUITextBox;       // ProfilePage.xaml(19) <TextBox>
    NotesBox: TWinUITextBox;       // ProfilePage.xaml(20) <TextBox>
    SaveButton: TWinUIButton;      // ProfilePage.xaml(23) <Button>
    Status: TWinUITextBlock;       // ProfilePage.xaml(25) <TextBlock>
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
  // ProfilePage.xaml(1): the page; event attributes became the
  // wiring below, x:Class, x:DataType and RADWinUI attributes are removed
  PageXaml =
    '<Page xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' + sLineBreak +
    '  <ScrollViewer>' + sLineBreak +
    '    <StackPanel Spacing="16" MaxWidth="560" HorizontalAlignment="Left">' + sLineBreak +
    '      <StackPanel Orientation="Horizontal" Spacing="20">' + sLineBreak +
    '        <PersonPicture x:Name="Picture" Width="88" Height="88" />' + sLineBreak +
    '        <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '          <TextBlock x:Name="PageTitle" Style="{StaticResource TitleTextBlockStyle}" />' + sLineBreak +
    '          <TextBlock x:Name="Subtitle" Opacity="0.7" />' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </StackPanel>' + sLineBreak +
    '      <TextBox x:Name="NameBox" Header="Name" AutomationProperties.Name="Name" />' + sLineBreak +
    '      <TextBox x:Name="RoleBox" Header="Role" AutomationProperties.Name="Role" />' + sLineBreak +
    '      <TextBox x:Name="EmailBox" Header="Email" AutomationProperties.Name="Email" />' + sLineBreak +
    '      <TextBox x:Name="NotesBox" Header="Notes" AcceptsReturn="True" TextWrapping="Wrap" MinHeight="96" AutomationProperties.Name="Notes" />' + sLineBreak +
    '      <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '        <Button x:Name="SaveButton" Content="Save" Style="{StaticResource AccentButtonStyle}" IsEnabled="False" />' + sLineBreak +
    '        <TextBlock x:Name="Status" VerticalAlignment="Center" Opacity="0.7" />' + sLineBreak +
    '      </StackPanel>' + sLineBreak +
    '    </StackPanel>' + sLineBreak +
    '  </ScrollViewer>' + sLineBreak +
    '</Page>';
  {$IFDEF DEBUG}
  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild
  XamlShape = 'F:Picture:TWinUIPersonPicture;F:PageTitle:TWinUITextBlock;F:Subtitle:TWinUITextBlock;F:NameBox:TWinUITextBox;F:RoleBox:TWinUITextBox;F:EmailBox:TWinUITextBox;F:NotesBox:TWinUITextBox;F:SaveButton:TWin' +
    'UIButton;F:Status:TWinUITextBlock;E:EmailBox.TextChanged=FieldChanged;E:NameBox.TextChanged=FieldChanged;E:NotesBox.TextChanged=FieldChanged;E:RoleBox.TextChanged=FieldChanged;E:SaveButton.Click=SaveC' +
    'lick';
  {$ENDIF}

constructor TProfilePageBase.Create;
begin
  inherited CreateFromXaml(PageXaml);
  WireXaml;
  {$IFDEF DEBUG}
  AddHelper(TXamlHotReload.Watch(Self, 'ProfilePage.xaml', XamlShape, ReloadXaml));
  {$ENDIF}
end;

// The x:Name fields and the event wiring of the content, again after a hot reload
procedure TProfilePageBase.WireXaml;
begin
  // x:Name elements
  Picture := FindElement<TWinUIPersonPicture>('Picture');
  PageTitle := FindElement<TWinUITextBlock>('PageTitle');
  Subtitle := FindElement<TWinUITextBlock>('Subtitle');
  NameBox := FindElement<TWinUITextBox>('NameBox');
  RoleBox := FindElement<TWinUITextBox>('RoleBox');
  EmailBox := FindElement<TWinUITextBox>('EmailBox');
  NotesBox := FindElement<TWinUITextBox>('NotesBox');
  SaveButton := FindElement<TWinUIButton>('SaveButton');
  Status := FindElement<TWinUITextBlock>('Status');
  // Event wiring
  // ProfilePage.xaml(17): TextChanged="FieldChanged"
  NameBox.OnTextChanged := TWinUITextChangedEventHandler(PublishedMethod('FieldChanged'));
  // ProfilePage.xaml(18): TextChanged="FieldChanged"
  RoleBox.OnTextChanged := TWinUITextChangedEventHandler(PublishedMethod('FieldChanged'));
  // ProfilePage.xaml(19): TextChanged="FieldChanged"
  EmailBox.OnTextChanged := TWinUITextChangedEventHandler(PublishedMethod('FieldChanged'));
  // ProfilePage.xaml(20): TextChanged="FieldChanged"
  NotesBox.OnTextChanged := TWinUITextChangedEventHandler(PublishedMethod('FieldChanged'));
  // ProfilePage.xaml(23): Click="SaveClick"
  SaveButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('SaveClick'));
end;

{$IFDEF DEBUG}
// Hot reload: ProfilePage.xaml edited in the IDE while the app runs
procedure TProfilePageBase.ReloadXaml(const AXaml: string);
begin
  ReplaceXaml(AXaml);
  WireXaml;
end;
{$ENDIF}

end.
