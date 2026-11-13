program XamlCodeGenTest;

{
  Tests of XamlCodeGen, in process: the generated
  units, the handler and binding checks with their messages, and that every
  sample's committed MainWindow.Xaml.pas is exactly what the generator writes.

    XamlCodeGenTest.exe <RADWinUI root>
}

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.RegularExpressions,
  RADWinUI.CodeGen.Xml in '..\..\tools\XamlCodeGen\RADWinUI.CodeGen.Xml.pas',
  RADWinUI.CodeGen.Bindings in '..\..\tools\XamlCodeGen\RADWinUI.CodeGen.Bindings.pas',
  RADWinUI.CodeGen in '..\..\tools\XamlCodeGen\RADWinUI.CodeGen.pas';

const
  WindowXaml =
    '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' + #10 +
    '    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Class="TMainWindow" Title="It''s">' + #10 +
    '  <StackPanel>' + #10 +
    '    <TextBlock x:Name="CounterText" Text="0"/>' + #10 +
    '    <Button x:Name="IncrementButton" Content="Increment"/>' + #10 +
    '    <Button Content="Reset" Click="{handler}"/>' + #10 +
    '  </StackPanel>' + #10 +
    '</Window>';
  WindowUnit =
    'unit MainWindow;' + #10 + 'interface' + #10 + 'type' + #10 +
    '  TMainWindow = class(TMainWindowBase)' + #10 + '  published' + #10 +
    '    procedure IncrementButtonClick(Sender: TObject);' + #10 +
    '    procedure ResetClick(Sender: TObject; E: {args});' + #10 +
    '  end;' + #10 + 'implementation' + #10 + 'end.';
  BoundXaml =
    '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' + #10 +
    '    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Class="TMainWindow" DataContextType="TModel">' + #10 +
    '  <StackPanel>' + #10 + '{body}' + #10 + '  </StackPanel>' + #10 + '</Window>';
  ModelUnit =
    'unit MainWindowViewModel;' + #10 + 'interface' + #10 + 'type' + #10 + '  {$M+}' + #10 +
    '  TAddress = class' + #10 + '  published' + #10 +
    '    property City: string read FCity write FCity;' + #10 + '  end;' + #10 +
    '  TModel = class(TWinUIBindableObject)' + #10 + '  private' + #10 +
    '    property Secret: string read FSecret;' + #10 + '  published' + #10 +
    '    property Name: string read FName write SetName;' + #10 +
    '    property Summary: string read GetSummary;' + #10 +
    '    property Home: TAddress read FHome;' + #10 + '  end;' + #10 +
    'implementation' + #10 + 'end.';
  PlainWindowUnit =
    'unit MainWindow;' + #10 + 'interface' + #10 + 'uses MainWindow.Xaml;' + #10 + 'type' + #10 +
    '  TMainWindow = class(TMainWindowBase)' + #10 + '  end;' + #10 + 'implementation' + #10 + 'end.';
  ConverterDpr =
    'program App;' + #10 + 'uses RADWinUI.Forms;' + #10 + 'begin' + #10 +
    '  // TWinUIApp.RegisterConverter(''Commented'', nil);' + #10 +
    '  TWinUIApp.RegisterConverter(''Upper'', function(const AValue: TWinValue; const AParameter: string): TWinValue' + #10 +
    '    begin Result := AValue; end);' + #10 + '  TWinUIApp.Run(TMainWindow);' + #10 + 'end.';

var
  Index: TTypeIndex;
  Failures: Integer;

procedure Check(AOk: Boolean; const AWhat: string);
begin
  if AOk then
    Writeln('  [ok] ', AWhat)
  else
  begin
    Writeln('  [failed] ', AWhat);
    Inc(Failures);
  end;
end;

function NewFolder: string;
begin
  Result := TPath.Combine(TPath.GetTempPath, 'XamlCodeGenTest-' + TGUID.NewGuid.ToString);
  ForceDirectories(Result);
end;

procedure Save(const AFolder, AName, AText: string);
begin
  TFile.WriteAllText(TPath.Combine(AFolder, AName), AText, TEncoding.UTF8);
end;

/// Generates the window in AFolder, '' and AError set when the generator refuses it.
function Generate(const AFolder: string; out AError: string): string;
begin
  AError := '';
  try
    Result := TFile.ReadAllText(GenerateFile(TPath.Combine(AFolder, 'MainWindow.xaml'), Index), TEncoding.UTF8);
  except
    on E: ECodeGenError do
    begin
      AError := E.Message;
      Result := '';
    end;
  end;
end;

function GenerateWindow(const AXaml: string; const AArgs: string; out AError: string): string;
var
  Folder: string;
begin
  Folder := NewFolder;
  Save(Folder, 'MainWindow.xaml', AXaml);
  Save(Folder, 'MainWindow.pas', WindowUnit.Replace('{args}', AArgs));
  Result := Generate(Folder, AError);
end;

function Simple(const AHandler: string = 'ResetClick'; const AArgs: string = 'TWinUIRoutedEventArgs'): string;
var
  Error: string;
begin
  Result := GenerateWindow(WindowXaml.Replace('{handler}', AHandler), AArgs, Error);
end;

function SimpleError(const AXaml: string; const AArgs: string = 'TWinUIRoutedEventArgs'): string;
begin
  GenerateWindow(AXaml, AArgs, Result);
end;

function GenerateBound(const ABody: string; AModelInWindow: Boolean; const ADpr: string; out AError: string): string;
var
  Folder: string;
begin
  Folder := NewFolder;
  if ADpr <> '' then
    Save(Folder, 'App.dpr', ADpr);
  Save(Folder, 'MainWindow.xaml', BoundXaml.Replace('{body}', ABody));
  if AModelInWindow then
    Save(Folder, 'MainWindow.pas', ModelUnit.Replace('unit MainWindowViewModel;', 'unit MainWindow;'))
  else
  begin
    Save(Folder, 'MainWindow.pas', PlainWindowUnit);
    Save(Folder, 'MainWindowViewModel.pas', ModelUnit);
  end;
  Result := Generate(Folder, AError);
end;

function BoundError(const ABody: string; AModelInWindow: Boolean = False; const ADpr: string = ''): string;
begin
  GenerateBound(ABody, AModelInWindow, ADpr, Result);
end;

function Bound(const ABody: string; const ADpr: string = ''): string;
var
  Error: string;
begin
  Result := GenerateBound(ABody, False, ADpr, Error);
  if Error <> '' then
    Writeln('    unexpected error: ', Error);
end;

/// The embedded XAML of a generated unit (comments may quote what was removed).
function ContentXaml(const AText: string): string;
var
  Start: Integer;
begin
  // Up to the hot reload shape that follows it in Debug builds
  Start := AText.IndexOf('ContentXaml =');
  Result := AText.Substring(Start, AText.IndexOf('{$IFDEF DEBUG}', Start) - Start);
end;

procedure TestUnits;
var
  Text, Body, Xaml, Error, Content, Template, Folder: string;
begin
  Writeln('Generated units');
  Text := Simple;
  Check(Text.Contains('CounterText: TWinUITextBlock;') and Text.Contains('IncrementButton: TWinUIButton;'),
    'one typed field per x:Name element');
  Check(Text.Contains('Title := ''It''''s'';'), 'Window Title becomes a quoted Pascal string');
  Check(Text.Contains('IncrementButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>(''IncrementButtonClick''));'),
    'a published <x:Name><Event> method is wired by name (short form)');
  Check(Text.Contains('FindElement<TWinUIButton>(''_rw1'').OnClick := TWinUIRoutedEventHandler(PublishedMethod(''ResetClick''));'),
    'an event attribute on an unnamed element gets an _rwN name and is wired');
  Check(not ContentXaml(Text).Contains('Click="ResetClick"'), 'event attributes are removed from the loaded XAML');
  // Hot reload: the fields and the wiring in WireXaml, ReloadXaml and the shape in Debug builds only
  Check(Text.Contains('procedure TMainWindowBase.WireXaml;') and Text.Contains('  LoadContent(ContentXaml);' + #13#10 +
    '  WireXaml;') and (Text.IndexOf('IncrementButton :=') > Text.IndexOf('procedure TMainWindowBase.WireXaml;')),
    'the constructor loads the content and calls WireXaml, which fills the fields and wires the events');
  Check(Text.Contains('{$IFDEF DEBUG}' + #13#10 + '    procedure ReloadXaml(const AXaml: string);') and
    Text.Contains('  AddHelper(TXamlHotReload.Watch(Self, ''MainWindow.xaml'', XamlShape, ReloadXaml));') and
    Text.Contains('{$IFDEF DEBUG}' + #13#10 + 'uses' + #13#10 + '  RADWinUI.HotReload;'),
    'Debug builds watch the .xaml for hot reload');
  Check(Text.Contains('XamlShape = ''F:CounterText:TWinUITextBlock;F:IncrementButton:TWinUIButton;' +
    'E:IncrementButton.Click=IncrementButtonClick;E:_rw1.Click=ResetClick'';'),
    'the shape lists the fields, then the events sorted');

  Xaml := WindowXaml.Replace('{handler}', 'ResetClick').Replace('Text="0"', 'Text="Gr'#$FC#$DF'e '#$65E5#$672C#$8A9E' &#xE8A9;"');
  Folder := NewFolder;
  Save(Folder, 'MainWindow.xaml', Xaml);
  Save(Folder, 'MainWindow.pas', WindowUnit.Replace('{args}', 'TWinUIRoutedEventArgs'));
  Text := Generate(Folder, Error);
  Check(TFile.ReadAllBytes(TPath.Combine(Folder, 'MainWindow.Xaml.pas'))[0] = $EF, 'the unit is UTF-8 with a BOM');
  Check(ContentXaml(Text).Contains('Gr'#$FC#$DF'e '#$65E5#$672C#$8A9E' '#$E8A9), 'Unicode text and character references survive');

  Xaml := WindowXaml.Replace('Title="It''s"', 'Title="T" Width="480" Height="320" MinWidth="360" ' +
    'Backdrop="mica" WindowStartupLocation="CenterScreen"');
  Text := GenerateWindow(Xaml.Replace('{handler}', 'ResetClick'), 'TWinUIRoutedEventArgs', Error);
  Body := Text.Substring(Text.IndexOf('inherited;'));
  Check(Body.Contains('Width := 480;') and Body.Contains('Height := 320;') and Body.Contains('MinWidth := 360;') and
    Body.Contains('Backdrop := TWinUIBackdrop.Mica;') and Body.Contains('Center;'), 'Window attributes become settings');
  Check(Body.IndexOf('Height := 320;') < Body.IndexOf('Center;'), 'size first, then centre');
  Check(SimpleError(Xaml.Replace('Width="480"', 'Width="wide"').Replace('{handler}', 'ResetClick')).Contains('not valid'),
    'an invalid Window attribute value is refused');

  Error := SimpleError(WindowXaml.Replace('{handler}', 'NoSuchClick'));
  Check(Error.Contains('Click="NoSuchClick" has no published method NoSuchClick in TMainWindow') and
    Error.Contains('"procedure NoSuchClick(Sender: TObject; E: TWinUIRoutedEventArgs);"') and
    Error.Contains('remove Click="NoSuchClick" from the XAML') and Error.Contains('MainWindow.xaml(6)'),
    'a missing handler says how to fix it, with the line');
  Check(SimpleError(WindowXaml.Replace('{handler}', 'ResetClick'), 'TWinUIWindowEventArgs').Contains('must be'),
    'a handler with the wrong argument type is refused');
  Check(SimpleError(WindowXaml.Replace('x:Name="CounterText"', 'x:Name="Title"').Replace('{handler}', 'ResetClick')).Contains('would hide'),
    'an x:Name that hides a window member is refused');

  Xaml := WindowXaml.Replace('{handler}', 'ResetClick').Replace('x:Class="TMainWindow"',
    'xmlns:d="http://schemas.microsoft.com/expression/blend/2008" ' +
    'xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="d" x:Class="TMainWindow"')
    .Replace('Text="0"/>', 'Text="0" d:Text="42"/>');
  Content := ContentXaml(GenerateWindow(Xaml, 'TWinUIRoutedEventArgs', Error));
  Check(not Content.Contains('42') and not Content.Contains('Ignorable') and not Content.Contains('blend'),
    'design-time values are removed');

  Xaml := WindowXaml.Replace('{handler}', 'ResetClick').Replace('x:Class="TMainWindow"',
    'xmlns:d="http://schemas.microsoft.com/expression/blend/2008" x:Class="TMainWindow"').Replace('  </StackPanel>',
    #10'    <ListView x:Name="People">'#10'      <d:ListView.Items>'#10 +
    '        <Button x:Name="CounterText" Click="NotARealHandler" Content="Preview only"/>'#10 +
    '        <d:Button x:Name="Title" Content="Nested preview only"/>'#10'      </d:ListView.Items>'#10'    </ListView>'#10 +
    '    <TextBlock x:Name="AfterSample">Real<d:Run Text="Preview span"/> control</TextBlock>'#10'  </StackPanel>');
  Text := GenerateWindow(Xaml, 'TWinUIRoutedEventArgs', Error);
  Check(Text.Contains('People: TWinUIListView;') and Text.Contains('AfterSample: TWinUITextBlock;') and
    ContentXaml(Text).Contains('Real control</TextBlock>') and not Text.Contains('Preview only') and
    not Text.Contains('Nested preview only') and not Text.Contains('Preview span') and not Text.Contains('NotARealHandler'),
    'design-time elements are removed before validation; their tail text stays');

  Xaml := WindowXaml.Replace('{handler}', 'ResetClick').Replace('  </StackPanel>',
    '    <ListView x:Name="People"><ListView.ItemTemplate><DataTemplate>' +
    '<TextBlock x:Name="PersonName" Text="{Binding Name}"/></DataTemplate></ListView.ItemTemplate></ListView>'#10'  </StackPanel>');
  Text := GenerateWindow(Xaml, 'TWinUIRoutedEventArgs', Error);
  Check(Text.Contains('People: TWinUIListView;') and not Text.Contains('PersonName:') and Text.Contains('{Binding Name}'),
    'template content is not a window field');

  Text := Simple;
  Check(Text = Simple, 'the output is stable (no timestamps or set ordering)');
  Check(Text.Contains('DO NOT EDIT') and Text.Contains('XamlCodeGen ' + CodeGenVersion) and
    TRegEx.IsMatch(Text, 'CounterText: TWinUITextBlock;\s+// MainWindow\.xaml\(4\) <TextBlock>') and
    Text.Contains('// MainWindow.xaml(5): IncrementButtonClick by name') and
    Text.Contains('// MainWindow.xaml(6): Click="ResetClick"') and
    (Text.IndexOf('IncrementButtonClick by name') < Text.IndexOf('Click="ResetClick"')),
    'the unit names its XAML lines and keeps XAML order');

  Template := '    <ListView><ListView.ItemTemplate><DataTemplate x:DataType="TAddress">' +
    '<TextBlock Text="{Binding {path}}"/></DataTemplate></ListView.ItemTemplate></ListView>';
  Check(not ContentXaml(Bound(Template.Replace('{path}', 'City'))).Contains('x:DataType'),
    'x:DataType is checked and removed from the loaded XAML');
  Check(BoundError(Template.Replace('{path}', 'Name')).Contains('TAddress has no published property Name'),
    'a template binding is checked against x:DataType');
end;

procedure TestBindings;
var
  Text, Error, Folder: string;
begin
  Writeln('Bindings and converters');
  Text := Bound('    <TextBox Text="{Binding Name, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}"/>'#10 +
    '    <TextBlock Text="{Binding Home.City, Converter={StaticResource Format}, ConverterParameter=''In %s, ok''}"/>'#10 +
    '    <TextBlock Text="{Binding Text, ElementName=Other}"/>');
  Check(Text.Contains('{Binding Name, Mode=TwoWay') and not ContentXaml(Text).Contains('DataContextType'),
    'valid paths pass; DataContextType is not loaded');
  Check(Bound('    <TextBlock Text="{Binding Name, Converter={StaticResource Upper}}"/>'#10 +
    '    <TextBlock Text="{Binding Name, Converter={StaticResource Format}, ConverterParameter=''%s (100%%)''}"/>'#10 +
    '    <TextBlock Visibility="{Binding Name, Converter={StaticResource BoolToVisibility}}"/>', ConverterDpr) <> '',
    'built-in and registered converters are known');
  Error := BoundError('    <TextBlock Text="{Binding Name, Converter={StaticResource Lower}}"/>', False, ConverterDpr);
  Check(Error.Contains('MainWindow.xaml(4): Converter={StaticResource Lower}: no converter Lower (built in: ' +
    'BoolToVisibility, InverseBoolToVisibility, Format; registered with TWinUIApp.RegisterConverter: Upper)'),
    'an unknown converter lists the known ones');
  Check(BoundError('    <TextBlock Text="{Binding Name, Converter={StaticResource Commented}}"/>', False, ConverterDpr)
    .Contains('no converter Commented'), 'a commented-out registration does not count');
  Check(SimpleError(WindowXaml.Replace('{handler}', 'ResetClick').Replace('<TextBlock x:Name="CounterText" Text="0"/>',
    '<TextBlock x:Name="CounterText" Text="{Binding Count, Converter={StaticResource Missing}}"/>')).Contains('no converter Missing'),
    'converters are checked without a DataContextType too');
  Check(Bound('    <StackPanel.Resources><x:String x:Key="Mine">m</x:String></StackPanel.Resources>'#10 +
    '    <TextBlock Text="{Binding Name, Converter={StaticResource Mine}}"/>') <> '', 'an x:Key of the XAML counts as a converter');
  Check(BoundError('    <TextBlock Text="{Binding Name, Converter={StaticResource Format}, ConverterParameter=''Count: %d''}"/>')
    .Contains('use %s, not %d'), 'Format needs %s');
  Check(BoundError('    <TextBlock Text="{Binding Name, Converter={StaticResource Format}, ConverterParameter=''%s and %s''}"/>')
    .Contains('found 2'), 'Format needs exactly one specifier');
  Text := Bound('    <TextBlock Text="{Binding Name}"/>');
  Check(Text.Contains('  MainWindowViewModel;  // TModel, the DataContextType') and
    Text.Contains('property ViewModel: TModel read FViewModel write SetViewModel;') and Text.Contains('  DataContext := AValue;'),
    'DataContextType gives a typed ViewModel property');
  Check(BoundError('    <TextBlock Text="{Binding Name}"/>', True).Contains('move TModel to its own unit'),
    'a view model in the window unit is refused');
  Check(BoundError('    <TextBlock Text="{Binding Nmae}"/>').Contains('MainWindow.xaml(4): {Binding Nmae}: TModel has no ' +
    'published property Nmae (published: Home, Name, Summary)'), 'an unknown path names the line and the properties');
  Check(BoundError('    <TextBlock Text="{Binding Home.Street}"/>').Contains('TAddress has no published property Street'),
    'nested paths follow property types');
  Check(BoundError('    <TextBlock Text="{Binding Path=Secret}"/>').Contains('Secret is not published'),
    'a non-published property is refused');
  Check(BoundError('    <TextBox Text="{Binding Summary, Mode=TwoWay}"/>').Contains('Mode=TwoWay needs a setter, but Summary is read-only'),
    'TwoWay needs a setter');
  Folder := NewFolder;
  Save(Folder, 'MainWindow.xaml', BoundXaml.Replace('TModel', 'TMissing').Replace('{body}', ''));
  Save(Folder, 'MainWindow.pas', ModelUnit);
  Generate(Folder, Error);
  Check(Error.Contains('class TMissing is not declared'), 'an unknown DataContextType is refused');
end;

/// RADWinUI's own controls (rw:) from src\Framework\RADWinUI.Controls.json.
procedure TestCustomControls;
const
  CustomXaml =
    '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' + #10 +
    '    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:rw="using:RADWinUI.Controls"' + #10 +
    '    x:Class="TMainWindow" WindowStyle="Overlay" Backdrop="Transparent" Dock="TopCenter">' + #10 +
    '  <Grid>' + #10 +
    '    <rw:NotchPanel x:Name="Notch" Expanded="NotchOpened">' + #10 +
    '      <rw:GlowTile x:Name="BuildTile" Click="BuildClick"/>' + #10 +
    '    </rw:NotchPanel>' + #10 +
    '    <rw:HotKey Keys="Ctrl+Alt+T" Pressed="HotKeyPressed"/>' + #10 +
    '  </Grid>' + #10 +
    '</Window>';
  CustomUnit =
    'unit MainWindow;' + #10 + 'interface' + #10 + 'type' + #10 +
    '  TMainWindow = class(TMainWindowBase)' + #10 + '  published' + #10 +
    '    procedure NotchOpened(Sender: TObject; const E: TWinValue);' + #10 +
    '    procedure BuildClick(Sender: TObject);' + #10 +
    '    procedure HotKeyPressed(Sender: TObject; const E: TWinValue);' + #10 +
    '  end;' + #10 + 'implementation' + #10 + 'end.';
var
  Folder, Text, Error: string;
begin
  Writeln('RADWinUI controls');
  Folder := NewFolder;
  Save(Folder, 'MainWindow.xaml', CustomXaml);
  Save(Folder, 'MainWindow.pas', CustomUnit);
  Text := Generate(Folder, Error);
  if Error <> '' then
    Writeln('    unexpected error: ', Error);
  Check(Text.Contains('Notch: TWinUINotchPanel;') and Text.Contains('BuildTile: TWinUIGlowTile;'),
    'rw: elements get typed fields');
  Check(Text.Contains('  RADWinUI.Controls,'), 'the controls'' unit is added to the uses clause');
  Check(Text.Contains('Notch.OnExpanded := TWinUIWinValueEventHandler(PublishedMethod(''NotchOpened''));'),
    'a custom event with the full handler');
  Check(Text.Contains('BuildTile.EventByName(''Click'').Add(NotifyProc<TWinValue>(''BuildClick''));'),
    'a custom event with the short handler');
  Check(Text.Contains('FindElement<TWinUIHotKey>(''_rw1'').OnPressed := TWinUIWinValueEventHandler(PublishedMethod(''HotKeyPressed''));'),
    'a custom event on an element without x:Name');
  Check(Text.Contains('WindowStyle := TWinUIWindowStyle.Overlay;') and Text.Contains('Backdrop := TWinUIBackdrop.Transparent;') and
    Text.Contains('Dock := TWinUIDock.TopCenter;'), 'overlay window attributes');
  Check(ContentXaml(Text).Contains('using:RADWinUI.Controls') and ContentXaml(Text).Contains('NotchPanel') and
    not ContentXaml(Text).Contains('Pressed='), 'the loaded XAML keeps rw: and loses the event attributes');
  Save(Folder, 'MainWindow.xaml', CustomXaml.Replace('rw:HotKey', 'rw:Nope'));
  Generate(Folder, Error);
  Check(Error.Contains('MainWindow.xaml(8): <rw:Nope> is not a RADWinUI control'), 'an unknown rw: element is refused');
end;

/// Window attributes for placement, state and the title bar.
procedure TestWindowAttributes;
const
  TitledXaml =
    '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' + #10 +
    '    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Class="TMainWindow" TitleBar="AppTitleBar"' + #10 +
    '    WindowState="Maximized" MaxWidth="1600" MaxHeight="900" Resizable="False" Minimizable="false"' + #10 +
    '    Maximizable="False" AlwaysOnTop="True" WindowStartupLocation="CenterOwner">' + #10 +
    '  <Grid>' + #10 +
    '    <TitleBar x:Name="AppTitleBar" Title="App"/>' + #10 +
    '  </Grid>' + #10 +
    '</Window>';
var
  Text: string;
begin
  Writeln('Window attributes');
  Text := SimpleError(TitledXaml);
  if Text <> '' then
    Writeln('    unexpected error: ', Text);
  Text := GenerateWindow(TitledXaml, 'TWinUIRoutedEventArgs', Text);
  Check(Text.Contains('WindowState := TWinUIWindowState.Maximized;') and Text.Contains('MaxWidth := 1600;') and
    Text.Contains('MaxHeight := 900;') and Text.Contains('Resizable := False;') and Text.Contains('Minimizable := False;') and
    Text.Contains('Maximizable := False;') and Text.Contains('AlwaysOnTop := True;') and Text.Contains('CenterOnOwner;'),
    'placement and state attributes become settings');
  Check(Text.Contains('AppTitleBar: TWinUITitleBar;') and Text.Contains('UseTitleBar(AppTitleBar);') and
    (Text.IndexOf('UseTitleBar(AppTitleBar);') > Text.IndexOf('AppTitleBar := FindElement')),
    'TitleBar names the title bar element, used once its field is set');
  Check(SimpleError(TitledXaml.Replace('TitleBar="AppTitleBar"', 'TitleBar="Nope"')).Contains(
    '<Window TitleBar="Nope">: no element has x:Name="Nope"'), 'TitleBar must name an element of the window');
  Check(SimpleError(TitledXaml.Replace('WindowState="Maximized"', 'WindowState="Huge"')).Contains(
    '<Window WindowState> must be one of Normal, Minimized, Maximized, FullScreen, CompactOverlay'),
    'an unknown WindowState is refused');
end;

/// <Page> and <UserControl> roots, user controls used from other XAML, and <Frame>.
procedure TestPagesAndUserControls;
const
  PageXaml =
    '<Page xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' + #10 +
    '    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:local="using:MyApp"' + #10 +
    '    x:Class="TContactsPage" Background="Transparent" Loaded="PageLoaded">' + #10 +
    '  <StackPanel>' + #10 +
    '    <local:ContactCard x:Name="Card" Title="Ada" Margin="4" Clicked="CardClicked"/>' + #10 +
    '    <local:ContactCard Title="Bob" Clicked="OtherClicked"/>' + #10 +
    '    <Frame x:Name="Details"/>' + #10 +
    '  </StackPanel>' + #10 +
    '</Page>';
  PageUnit =
    'unit ContactsPage;' + #10 + 'interface' + #10 + 'type' + #10 +
    '  TContactsPage = class(TContactsPageBase)' + #10 + '  published' + #10 +
    '    procedure PageLoaded(Sender: TObject; E: TWinUIRoutedEventArgs);' + #10 +
    '    procedure CardClicked(Sender: TObject; const E: TWinValue);' + #10 +
    '    procedure OtherClicked(Sender: TObject);' + #10 +
    '  end;' + #10 + 'implementation' + #10 + 'end.';
  CardXaml =
    '<UserControl xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' + #10 +
    '    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Class="TContactCard">' + #10 +
    '  <Border>' + #10 +
    '    <Button x:Name="OpenButton" Content="Open" Click="OpenClick"/>' + #10 +
    '  </Border>' + #10 +
    '</UserControl>';
  CardUnit =
    'unit ContactCard;' + #10 + 'interface' + #10 + 'type' + #10 +
    '  TContactCard = class(TContactCardBase)' + #10 + '  protected' + #10 +
    '    class procedure DefineType(AType: TWinUICustomType); override;' + #10 + '  published' + #10 +
    '    procedure OpenClick(Sender: TObject);' + #10 +
    '    property Title: string index 0 read GetText write SetText;' + #10 +
    '    property OnClicked: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;' + #10 +
    '  end;' + #10 + 'implementation' + #10 +
    'class procedure TContactCard.DefineType(AType: TWinUICustomType);' + #10 + 'begin' + #10 +
    '  inherited;' + #10 + '  AType.AddProperty(''Title'', TWinUIPropertyKind.Text);' + #10 +
    '  AType.AddEvent(''Clicked'');' + #10 + 'end;' + #10 + 'end.';
var
  Folder, Text, Error, Xaml: string;

  function Gen(const AName: string): string;
  begin
    Error := '';
    try
      Result := TFile.ReadAllText(GenerateFile(TPath.Combine(Folder, AName), Index), TEncoding.UTF8);
    except
      on E: ECodeGenError do
      begin
        Error := E.Message;
        Result := '';
      end;
    end;
  end;

begin
  Writeln('Pages and user controls');
  Folder := NewFolder;
  Save(Folder, 'ContactsPage.xaml', PageXaml);
  Save(Folder, 'ContactsPage.pas', PageUnit);
  Save(Folder, 'ContactCard.xaml', CardXaml);
  Save(Folder, 'ContactCard.pas', CardUnit);
  Text := Gen('ContactsPage.xaml');
  if Error <> '' then
    Writeln('    unexpected error: ', Error);
  Check(Text.Contains('TContactsPageBase = class(TWinUIXamlPage)') and Text.Contains('constructor Create; override;') and
    Text.Contains('inherited CreateFromXaml(PageXaml);'), 'a <Page> root gives a TWinUIXamlPage base');
  Check(Text.Contains('Card: TContactCard;') and Text.Contains('  ContactCard,') and Text.Contains('  RADWinUI.Pages;'),
    'a user control element gets a field of its class and its unit');
  Check(Text.Contains('Details: TWinUIPageFrame;'), 'a <Frame> is a TWinUIPageFrame');
  Check(Text.IndexOf('Self.OnLoaded :=') < Text.IndexOf('procedure TContactsPageBase.WireXaml;'),
    'a page''s own events are wired once, in the constructor, not again after a hot reload');
  Check(Text.Contains('Self.OnLoaded := TWinUIRoutedEventHandler(PublishedMethod(''PageLoaded''));'),
    'an event attribute of the page itself is wired to the page');
  Check(Text.Contains('Card.OnClicked := TWinUIWinValueEventHandler(PublishedMethod(''CardClicked''));') and
    Text.Contains('FindElement<TContactCard>(''_rw1'').EventByName(''Clicked'').Add(NotifyProc<TWinValue>(''OtherClicked''));'),
    'user control events, full and short handler');
  Xaml := Text.Substring(Text.IndexOf('PageXaml ='), Text.IndexOf('{$IFDEF DEBUG}', Text.IndexOf('PageXaml =')) -
    Text.IndexOf('PageXaml ='));
  Check(not Xaml.Contains('x:Class') and Xaml.Contains('Background="Transparent"') and not Xaml.Contains('Loaded='),
    'the page XAML keeps its attributes but not x:Class or event attributes');

  Text := Gen('ContactCard.xaml');
  if Error <> '' then
    Writeln('    unexpected error: ', Error);
  Check(Text.Contains('TContactCardBase = class(TWinUIXamlUserControl)') and Text.Contains('procedure Initialize; override;') and
    Text.Contains('LoadContentXaml(ContentXaml);'), 'a <UserControl> root gives a TWinUIXamlUserControl base');
  Check(Text.Contains('TWinUICustomControls.Register(TContactCard, ''ContactCard'', ''User controls'');') and
    Text.Contains('  RADWinUI.HotReload,' + #13#10 + '  {$ENDIF}' + #13#10 + '  ContactCard;'),
    'the generated unit registers the user control');
  Check(Text.Contains('OpenButton: TWinUIButton;') and
    Text.Contains('OpenButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>(''OpenClick''));'),
    'fields and events inside a user control');

  Save(Folder, 'ContactsPage.xaml', PageXaml.Replace('local:ContactCard Title="Bob"', 'local:Nope Title="Bob"'));
  Gen('ContactsPage.xaml');
  Check(Error.Contains('ContactsPage.xaml(6): <Nope> is not a user control of this project'), 'an unknown user control is refused');
  Save(Folder, 'ContactsPage.xaml', PageXaml.Replace('Title="Ada"', 'Titel="Ada"'));
  Gen('ContactsPage.xaml');
  Check(Error.Contains('TContactCard has no property or event Titel') and Error.Contains('Title'),
    'an unknown property of a user control is refused, with the known ones');
  Save(Folder, 'ContactCard.pas', CardUnit.Replace('    property OnClicked: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;' + #10, ''));
  Save(Folder, 'ContactsPage.xaml', PageXaml);
  Gen('ContactsPage.xaml');
  Check(Error.Contains('needs "property OnClicked: TWinUIWinValueEventHandler'), 'a full handler needs the OnName property');
  Save(Folder, 'ContactCard.pas', CardUnit);
  Save(Folder, 'ContactCard.xaml', CardXaml.Replace('x:Class="TContactCard"', 'x:Class="TContactCard" Width="200"'));
  Gen('ContactCard.xaml');
  Check(Error.Contains('<UserControl> takes no attributes besides x:Class, set Width on its content element'),
    'attributes on <UserControl> are refused');
  Save(Folder, 'ContactCard.xaml', CardXaml.Replace('<Border>', '<Border xmlns:local="using:MyApp"><local:ContactCard/>'));
  Gen('ContactCard.xaml');
  Check(Error.Contains('the user control TContactCard cannot contain itself'), 'a user control cannot contain itself');
  Save(Folder, 'ContactCard.xaml', CardXaml.Replace('x:Name="OpenButton"', 'x:Name="Title"'));
  Gen('ContactCard.xaml');
  Check(Error.Contains('x:Name="Title" would hide a member of TContactCard'), 'an x:Name that hides a user control property is refused');
end;

/// Every sample's committed MainWindow.Xaml.pas is exactly what the generator writes now.
procedure TestUids;
const
  Xaml =
    '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' + #10 +
    '    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Class="TMainWindow">' + #10 +
    '  <StackPanel>' + #10 +
    '    <TextBlock x:Uid="Greeting"/>' + #10 +
    '    <Button x:Uid="Forgotten"/>' + #10 +
    '  </StackPanel>' + #10 +
    '</Window>';
  Resw =
    '<root>' + #10 +
    '  <data name="Greeting.Text" xml:space="preserve"><value>Hello</value></data>' + #10 +
    '  <data name="Leftover.Text" xml:space="preserve"><value>Old</value></data>' + #10 +
    '  <data name="Plain" xml:space="preserve"><value>For GetString</value></data>' + #10 +
    '</root>';
var
  Folder: string;
  Warnings: TArray<string>;
begin
  Writeln('x:Uid and Resources.resw');
  Folder := NewFolder;
  Save(Folder, 'MainWindow.xaml', Xaml);
  Check(Length(CheckUids(Folder)) = 0, 'a folder without Strings has no x:Uid warnings');
  ForceDirectories(TPath.Combine(Folder, 'Strings\en-US'));
  Save(Folder, 'Strings\en-US\Resources.resw', Resw);
  Warnings := CheckUids(Folder);
  Check(Length(Warnings) = 2, Format('two warnings (%d)', [Length(Warnings)]));
  Check((Length(Warnings) > 1) and Warnings[1].EndsWith('Resources.resw(3): warning RW2002: "Leftover.Text" belongs ' +
    'to no x:Uid of the XAML files in this folder'), 'RW2002 for a key no x:Uid uses, with its line');
  Check((Length(Warnings) > 0) and Warnings[0].Contains('MainWindow.xaml(5): warning RW2001: x:Uid "Forgotten" has no ' +
    'Forgotten.<Property> key'), 'RW2001 for an x:Uid without a key, with its line');
  TDirectory.Delete(Folder, True);
end;

procedure TestAccessibleNames;
const
  Xaml =
    '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' + #10 +
    '    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Class="TMainWindow">' + #10 +
    '  <StackPanel>' + #10 +
    '    <Button><FontIcon Glyph="&#xE713;"/></Button>' + #10 +
    '    <Button AutomationProperties.Name="Settings"><FontIcon Glyph="&#xE713;"/></Button>' + #10 +
    '    <Button ToolTipService.ToolTip="Settings"><FontIcon Glyph="&#xE713;"/></Button>' + #10 +
    '    <Button x:Uid="SettingsButton"><FontIcon Glyph="&#xE713;"/></Button>' + #10 +
    '    <Button Content="Save"/>' + #10 +
    '    <Button><StackPanel><FontIcon Glyph="&#xE74E;"/><TextBlock x:Name="Caption"/></StackPanel></Button>' + #10 +
    '    <AppBarButton Icon="Add"/>' + #10 +
    '  </StackPanel>' + #10 +
    '</Window>';
var
  Folder: string;
  Warnings: TArray<string>;
begin
  Writeln('Accessible names');
  Folder := NewFolder;
  Save(Folder, 'MainWindow.xaml', Xaml);
  Warnings := CheckAccessibleNames(TPath.Combine(Folder, 'MainWindow.xaml'));
  Check(Length(Warnings) = 2, Format('two buttons without a name (%d)', [Length(Warnings)]));
  Check((Length(Warnings) > 0) and Warnings[0].Contains('MainWindow.xaml(4): warning RW2003: this Button shows no text'),
    'RW2003 for an icon-only Button, with its line');
  Check((Length(Warnings) > 1) and Warnings[1].Contains('(10): warning RW2003: this AppBarButton'),
    'RW2003 for an AppBarButton without Label');
  TDirectory.Delete(Folder, True);
end;

procedure TestSamples(const ARoot: string);
var
  Sample, Copy, Committed: string;
  Files: TArray<string>;
begin
  Writeln('Samples');
  for Sample in TDirectory.GetDirectories(TPath.Combine(ARoot, 'samples')) do
  begin
    Files := TDirectory.GetFiles(Sample, '*.xaml');
    if Length(Files) = 0 then
      Continue;
    Copy := NewFolder;
    for Committed in TDirectory.GetFiles(Sample) do
      if not Committed.EndsWith('.Xaml.pas', True) and (Committed.EndsWith('.xaml', True) or Committed.EndsWith('.pas', True) or
        Committed.EndsWith('.dpr', True)) then
        TFile.Copy(Committed, TPath.Combine(Copy, TPath.GetFileName(Committed)));
    for Committed in Files do
      Check(TFile.ReadAllText(GenerateFile(TPath.Combine(Copy, TPath.GetFileName(Committed)), Index), TEncoding.UTF8) =
        TFile.ReadAllText(ChangeFileExt(Committed, '.Xaml.pas'), TEncoding.UTF8),
        TPath.GetFileName(Sample) + '\' + ChangeFileExt(TPath.GetFileName(Committed), '.Xaml.pas') +
        ' is what the generator writes');
  end;
end;

begin
  Failures := 0;
  Index := TTypeIndex.Create(TPath.Combine(ParamStr(1), 'src\Generated\RADWinUI.Xaml.json'));
  try
    TestUnits;
    TestBindings;
    TestCustomControls;
    TestPagesAndUserControls;
    TestWindowAttributes;
    TestUids;
    TestAccessibleNames;
    TestSamples(ParamStr(1));
  finally
    Index.Free;
  end;
  if Failures = 0 then
    Writeln('XamlCodeGen test PASSED')
  else
    Writeln('XamlCodeGen test FAILED (', Failures, ')');
  ExitCode := Ord(Failures > 0);
end.
