program PreviewDataTest;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows, System.SysUtils, System.IOUtils,
  RADWinUI.Forms, RADWinUI.Framework, RADWinUI.Xaml, RADWinUI.Abi,
  RADWinUI.Interop.Core, RADWinUI.CustomControls, RADWinUI.Runtime.Application,
  // the controls the preview host links (src\IDE\Preview\RADWinUIPreview.dpr)
  RADWinUI.Controls, RADWinUI.TabBars, RADWinUI.ActionButtons, RADWinUI.DBControls,
  RADWinUI.Designer.XamlEdit in '..\..\src\IDE\Designer\RADWinUI.Designer.XamlEdit.pas',
  RADWinUI.Designer.Palette in '..\..\src\IDE\Designer\RADWinUI.Designer.Palette.pas',
  RADWinUI.Designer.Snap in '..\..\src\IDE\Designer\RADWinUI.Designer.Snap.pas',
  RADWinUI.Preview.Host in '..\..\src\IDE\Preview\RADWinUI.Preview.Host.pas';

const
  DataXaml = '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" ' +
    'xmlns:d="http://schemas.microsoft.com/expression/blend/2008" ' +
    'xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="d">' + #13#10 +
    '<StackPanel>' + #13#10 +
    '  <ListView x:Name="People" ItemsSource="{Binding Missing}">' + #13#10 +
    '    <d:ListView.Items><x:String>Alex</x:String><x:String>Bea</x:String></d:ListView.Items>' + #13#10 +
    '    <ListView.ItemTemplate><DataTemplate><TextBlock Text="{Binding Name}" d:Text="{Binding}"/>' +
    '</DataTemplate></ListView.ItemTemplate></ListView>' + #13#10 +
    '  <GridView x:Name="Tiles"><d:GridView.Items><TextBlock x:Name="SampleTile" Text="Preview tile"/>' +
    '</d:GridView.Items></GridView>' + #13#10 +
    '  <ListBox x:Name="Choices"><d:ListBox.Items><x:String>One</x:String></d:ListBox.Items></ListBox>' + #13#10 +
    '  <ComboBox x:Name="Choice" d:SelectedIndex="0"><d:ComboBox.Items><x:String>Two</x:String>' +
    '</d:ComboBox.Items></ComboBox>' + #13#10 +
    '  <Button x:Name="AfterSample" Content="Real control"/>' + #13#10 +
    '</StackPanel></Window>';
  // A page with resources and a user control of the app, which the preview does not have
  PageXaml = '<Page xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:local="using:Crew" x:Class="THomePage">' + #13#10 +
    '<Page.Resources><SolidColorBrush x:Key="Accent" Color="Orange"/></Page.Resources>' + #13#10 +
    '<StackPanel>' + #13#10 +
    '  <local:PersonCard x:Name="AdaCard" PersonName="Ada" Margin="4" Opened="CardOpened"/>' + #13#10 +
    '  <TextBlock x:Name="Caption" Text="Home" Foreground="{StaticResource Accent}"/>' + #13#10 +
    '</StackPanel></Page>';
  TitleBarXaml = '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">' + #13#10 +
    '<TitleBar Title="App" Subtitle="Preview" IsBackButtonVisible="True" Foreground="Red" Margin="4">' + #13#10 +
    '  <TitleBar.IconSource><FontIconSource Glyph="&#xE8D6;"/></TitleBar.IconSource>' + #13#10 +
    '  <TitleBar.Content><TextBox Width="200"/></TitleBar.Content>' + #13#10 +
    '</TitleBar></Grid>';

type
  TDataWindow = class(TPreviewWindow)
  private
    FCheck: TWinUITimer;
    FStep: Integer;
    procedure CheckData(Sender: TObject);
    procedure PreviewEverySample;
  public
    constructor Create; override;
    destructor Destroy; override;
    class procedure Failed(Sender: TObject; E: Exception);
  end;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then raise Exception.Create(AMessage);
  Writeln('[ok] ', AMessage);
end;

function HasText(const AObject: IDependencyObject; const AText: string): Boolean;
var
  Text: ITextBlock;
  I: Integer;
begin
  if Supports(AObject, ITextBlock, Text) and (TakeHString(Text.Text) = AText) then Exit(True);
  for I := 0 to VisualTreeHelper.GetChildrenCount(AObject) - 1 do
    if HasText(VisualTreeHelper.GetChild(AObject, I), AText) then Exit(True);
  Result := False;
end;

class procedure TDataWindow.Failed(Sender: TObject; E: Exception);
begin
  Writeln('FAILED: ', E.ClassName, ': ', E.Message);
  Flush(Output);
  ExitProcess(1);
end;

constructor TDataWindow.Create;
var
  Text, Window: string;
  Elements: TArray<TXamlElement>;
  Element: TXamlElement;
begin
  inherited;
  Text := PreviewXaml(DataXaml, Window);
  Check(Window = '||', 'omitted Window title and dimensions keep their defaults');
  Check((Length(Text) = Length(DataXaml)) and not Text.Contains('ItemsSource='),
    'preview preserves offsets and replaces the runtime ItemsSource');
  Elements := XamlElements(DataXaml);
  Check(Elements[High(Elements)].Tag = 'Button', 'source parser retains the following real control');
  Check(not Elements[High(Elements)].DesignOnly, 'real controls remain selectable');
  for Element in Elements do
    if Element.Name = 'SampleTile' then
      Check(Element.DesignOnly, 'sample descendants are marked design-only');
  Text := PreviewXaml(PageXaml, Window);
  Check((Length(Text) = Length(PageXaml)) and Text.Contains('<Grid.Resources>') and not Text.Contains('<Page'),
    'a <Page> previews as a Grid, its resources too, without moving any text');
  Text := PreviewXaml(TitleBarXaml, Window);
  Check((Length(Text) = Length(TitleBarXaml)) and not Text.Contains('TitleBar') and not Text.Contains('Foreground') and
    Text.Contains('Margin="4"') and Text.Contains('<TextBox'),
    'a <TitleBar> previews as a Grid around its content, without moving any text');
  Check(Load('', DataXaml) = '', 'the actual preview host loads all four sample collections');
  FCheck := TWinUITimer.Create;
  FCheck.Interval := 300;
  FCheck.OnTimer := CheckData;
  FCheck.Enabled := True;
end;

destructor TDataWindow.Destroy;
begin
  FCheck.Free;
  inherited;
end;

// Every .xaml of the samples and community apps loads in the preview host, as the designer shows it
procedure TDataWindow.PreviewEverySample;
var
  Root, Path, Error: string;
  Started: Cardinal;
  Count, Failed: Integer;
begin
  Failed := 0;
  Root := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..\');
  Count := 0;
  for Path in TDirectory.GetFiles(Root + 'samples', '*.xaml', TSearchOption.soAllDirectories) +
    TDirectory.GetFiles(Root + 'community', '*.xaml', TSearchOption.soAllDirectories) do
  begin
    if Path.Contains('\Win64\') then
      Continue;
    Started := GetTickCount;
    Error := Load(Path, TFile.ReadAllText(Path, TEncoding.UTF8));
    // Templates are applied by layout: a control that fails there (TitleBar did) fails here
    FindElement<TWinUIBorder>('PreviewHost').UpdateLayout;
    if Path.EndsWith('Tempo\MainWindow.xaml') then
      Check(HasText(TWinUIObject.IntfOf(FindElement<TWinUIBorder>('PreviewHost').Child, IDependencyObject) as
        IDependencyObject, 'Radio'), 'Tempo''s TitleBar shows its title and subtitle in the preview');
    if Error = '' then
      Writeln(Format('[ok] previews %s in %d ms', [ExtractRelativePath(Root, Path), GetTickCount - Started]))
    else
    begin
      Writeln('[failed] ', Error);
      Inc(Failed);
    end;
    Flush(Output);
    Inc(Count);
  end;
  Check((Count > 20) and (Failed = 0), Format('%d sample files previewed, %d failed', [Count, Failed]));
end;

procedure TDataWindow.CheckData(Sender: TObject);
var
  Root: TWinUIFrameworkElement;
  People: TWinUIListView;
  Element: TXamlElement;
  Error: string;
begin
  FCheck.Enabled := False;
  Inc(FStep);
  if FStep = 2 then
  begin
    // The placeholder's template is applied by the first layout pass
    Root := FindElement<TWinUIBorder>('PreviewHost').Child as TWinUIFrameworkElement;
    Check(HasText(TWinUIObject.IntfOf(Root, IDependencyObject) as IDependencyObject, 'PersonCard') and
      HasText(TWinUIObject.IntfOf(Root, IDependencyObject) as IDependencyObject, 'Home'),
      'the user control shows as a labelled placeholder, the rest of the page as written');
    PreviewEverySample;
    Writeln('Preview data test PASSED');
    Flush(Output);
    Close;
    Exit;
  end;
  Root := FindElement<TWinUIBorder>('PreviewHost').Child as TWinUIFrameworkElement;
  People := TWinUIObject.Wrap(Self, Root.FindName('People').Obj, TWinUIListView) as TWinUIListView;
  Check((People.Items.Count = 2) and (People.Items[1].AsString = 'Bea'), 'native list contains the sample strings');
  Check(HasText(TWinUIObject.IntfOf(Root, IDependencyObject) as IDependencyObject, 'Alex'),
    'item templates bind to sample strings with d:Text');
  Check((TWinUIObject.Wrap(Self, Root.FindName('Tiles').Obj, TWinUIGridView) as TWinUIGridView).Items.Count = 1,
    'native GridView contains a visual sample');
  Check((TWinUIObject.Wrap(Self, Root.FindName('Choices').Obj, TWinUIListBox) as TWinUIListBox).Items.Count = 1,
    'native ListBox contains a sample');
  Check((TWinUIObject.Wrap(Self, Root.FindName('Choice').Obj, TWinUIComboBox) as TWinUIComboBox).SelectedItem.AsString = 'Two',
    'native ComboBox displays its design-time selection');
  for Element in XamlElements(DataXaml) do
    if Element.Name = 'SampleTile' then
      Check(Command(Format('SELECTPOS %d %d', [Element.Line, Element.Column])) = 'NONE',
        'sample tiles are excluded from the designer selection map')
    else if Element.Name = 'AfterSample' then
      Check(Command(Format('SELECTPOS %d %d', [Element.Line, Element.Column])) =
        Format('SELECTED %d %d Button AfterSample', [Element.Line, Element.Column]),
        'selection after sample data keeps source coordinates');
  Error := Load('', PageXaml);
  Check(Error = '', 'a page with a user control of the app loads in the preview ' + Error);
  FCheck.Enabled := True;
end;

begin
  CustomXamlDesignTime := True; // as in the preview host
  TWinUIApp.OnException := TDataWindow.Failed;
  try
    TWinUIApp.Run(TDataWindow);
  except
    on E: Exception do TDataWindow.Failed(nil, E);
  end;
end.
