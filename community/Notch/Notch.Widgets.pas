unit Notch.Widgets;

{ The widgets of the panel. Each one is a piece of XAML made from its settings
  at runtime, and its buttons open what they stand for. }

interface

uses
  System.SysUtils,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  Notch.Settings,
  Notch.Agents;

type
  /// <summary>
  ///   A piece of XAML loaded at runtime. It owns the wrappers of its elements
  ///   (Find), so freeing it frees them all: free it once it left the tree.
  /// </summary>
  TFragment = class
  strict private
    FRoot: TWinUIFrameworkElement;
  public
    constructor Create(const AXaml: string);
    destructor Destroy; override;
    /// <summary>The element named AName (x:Name), nil when there is none.</summary>
    function Find(const AName: string; AClass: TWinUIObjectClass): TWinUIObject;
    /// <summary>Runs AProc when the button, check box or radio button named AName is clicked.</summary>
    procedure OnClick(const AName: string; const AProc: TProc);
    property Root: TWinUIFrameworkElement read FRoot;
  end;

const
  // Root elements of fragments declare the XAML namespaces with this
  XamlNs = ' xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' +
    ' xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"';
  MutedColor = '#8E8E93';
  // Every tile of the upright panel is this wide
  VerticalTileWidth = 300;
  // The upright panel shows four app icons in a row
  VerticalAppColumns = 4;
  KindGlyphs: array[TWidgetKind] of string = ('&#xE71D;', '&#xE99A;', '&#xE7F4;', '&#xE787;', '&#xE71B;',
    '&#xE70B;', '&#xE8D6;', '&#xE916;');
  KindHints: array[TWidgetKind] of string = (
    'Shortcuts to the apps you use most. Pick them from the installed apps, or type the path of any program or file.',
    'What your AI coding agents are doing right now: working, waiting for you, or finished. Tick the agents to watch.',
    'Saved computers open in Remote Desktop. The .rdp files in Documents show up by themselves.',
    'Today and this month. A click opens the calendar of the taskbar, as a click on its clock does.',
    'Web pages, files and folders, opened with their usual app.',
    'A small note, saved as you type.',
    'The music or video playing on the PC, with previous, play/pause and next.',
    'A 25 minute timer that glows while it runs and opens the panel when the time is up.');

/// <summary>Text for a XAML attribute or element.</summary>
function Esc(const AText: string): string;
/// <summary>The width of a widget's tile in the wide panel.</summary>
function WidgetWidth(AWidget: TNotchWidget): Integer;
/// <summary>The height of a widget's tile in the upright panel, where every tile is VerticalTileWidth wide.</summary>
function WidgetHeight(AWidget: TNotchWidget): Integer;
/// <summary>
///   The content of a widget's tile. AIconFolder holds the app icons. AVertical
///   lays it out for the upright panel on a side edge of the screen.
/// </summary>
function WidgetXaml(AWidget: TNotchWidget; const AIconFolder: string; AVertical: Boolean = False): string;
/// <summary>Makes the buttons of a widget built from WidgetXaml open their targets.</summary>
procedure WireWidget(AWidget: TNotchWidget; AFragment: TFragment);
/// <summary>An app icon from the cache, or the first letter of AName in a circle.</summary>
function IconXaml(const AIconFile, AName: string; ASize: Integer; const AXName: string = ''): string;
/// <summary>
///   What a first run shows: a few common apps, the AI agents found on the PC,
///   the calendar, the music and the focus timer.
/// </summary>
procedure AddDefaultWidgets(ASettings: TNotchSettings; AAgents: TAgentKinds);
/// <summary>The agents an AI agents widget watches.</summary>
function WidgetAgents(AWidget: TNotchWidget): TAgentKinds;
/// <summary>The body of an AI agents tile for these sessions, a XAML root of its own.</summary>
function AgentBodyXaml(const ASessions: TArray<TAgentSession>; AKinds: TAgentKinds; ANow: TDateTime): string;
/// <summary>"#FFFF8A3D", the colour of AState for XAML.</summary>
function StateColorXaml(AState: TAgentState): string;

implementation

uses
  Winapi.Windows,
  System.Math,
  System.StrUtils,
  System.DateUtils,
  RADWinUI.Interop.Core,
  RADWinUI.Abi,
  Notch.Shell;

{ TFragment }

constructor TFragment.Create(const AXaml: string);
begin
  inherited Create;
  // No owner: the fragment frees the root, the root frees the rest
  FRoot := TWinUIFrameworkElement(TWinUIObject.Wrap(nil, XamlReader.Load(WinStr(AXaml)), TWinUIFrameworkElement));
end;

destructor TFragment.Destroy;
begin
  FRoot.Free;
  inherited;
end;

function TFragment.Find(const AName: string; AClass: TWinUIObjectClass): TWinUIObject;
begin
  Result := TWinUIObject.Wrap(FRoot, FRoot.FindName(AName).Obj, AClass);
end;

procedure TFragment.OnClick(const AName: string; const AProc: TProc);
var
  Button: TWinUIButtonBase;
begin
  Button := TWinUIButtonBase(Find(AName, TWinUIButtonBase));
  if Button <> nil then
    Button.Click.Add(
      procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
      begin
        AProc;
      end);
end;

{ XAML }

function Esc(const AText: string): string;
begin
  Result := AText.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
    .Replace(#13#10, '&#10;').Replace(#13, '&#10;').Replace(#10, '&#10;');
  // A value in braces would be read as a markup extension, such as a known-folder path
  if Result.StartsWith('{') then
    Result := '{}' + Result;
end;

function FileUri(const APath: string): string;
begin
  Result := 'file:///' + APath.Replace('%', '%25').Replace(' ', '%20').Replace('#', '%23').Replace('\', '/');
end;

function IconXaml(const AIconFile, AName: string; ASize: Integer; const AXName: string): string;
begin
  if (AIconFile <> '') and (AXName <> '') then
    Exit(Format('<Image x:Name="%s" Source="%s" Width="%d" Height="%d"/>', [AXName, Esc(FileUri(AIconFile)),
      ASize, ASize]));
  if AIconFile <> '' then
    Exit(Format('<Image Source="%s" Width="%d" Height="%d"/>', [Esc(FileUri(AIconFile)), ASize, ASize]));
  Result := Format('<Border Width="%0:d" Height="%0:d" CornerRadius="%1:d" Background="#3A3A3C">' +
    '<TextBlock Text="%2:s" FontSize="%3:d" FontWeight="SemiBold" HorizontalAlignment="Center" ' +
    'VerticalAlignment="Center"/></Border>', [ASize, ASize div 2, Esc(UpperCase(Copy(AName.Trim, 1, 1))),
    ASize div 2]);
end;

function GlyphXaml(const AGlyph: string; ASize: Integer): string;
begin
  Result := Format('<FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="%s" FontSize="%d" ' +
    'Width="24"/>', [AGlyph, ASize]);
end;

function TileXaml(AKind: TWidgetKind; const ATitle, ABody: string): string;
begin
  Result := '<Grid RowSpacing="8"' + XamlNs + '><Grid.RowDefinitions><RowDefinition Height="Auto"/>' +
    '<RowDefinition Height="*"/></Grid.RowDefinitions>' +
    // The header is where a tile is dragged to a new place: a background makes all of it take the pointer
    '<StackPanel x:Name="Header" Orientation="Horizontal" Spacing="8" Background="Transparent">' +
    Format('<FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="%s" FontSize="13" Foreground="%s"/>',
      [KindGlyphs[AKind], MutedColor]) +
    Format('<TextBlock Text="%s" FontSize="13" Foreground="%s" TextTrimming="CharacterEllipsis"/>',
      [Esc(ATitle), MutedColor]) +
    '</StackPanel>' + ABody + '</Grid>';
end;

function EmptyXaml(const AText: string): string;
begin
  Result := Format('<TextBlock Grid.Row="1" Text="%s" FontSize="12" Foreground="%s" TextWrapping="Wrap" ' +
    'VerticalAlignment="Center"/>', [Esc(AText), MutedColor]);
end;

function AppColumns(AWidget: TNotchWidget): Integer;
begin
  Result := EnsureRange((AWidget.Items.Count + 1) div 2, 2, 5);
end;

function WidgetWidth(AWidget: TNotchWidget): Integer;
begin
  case AWidget.Kind of
    TWidgetKind.Apps:
      Result := 36 + AppColumns(AWidget) * 64;
    TWidgetKind.Calendar:
      Result := 260;
    TWidgetKind.Agents:
      Result := 250;
    TWidgetKind.Remote, TWidgetKind.Notes:
      Result := 220;
    TWidgetKind.Music:
      Result := 220;
  else
    Result := 196;
  end;
end;

function WidgetHeight(AWidget: TNotchWidget): Integer;
var
  Rows: Integer;
begin
  case AWidget.Kind of
    TWidgetKind.Apps:
      begin
        // Up to three rows of icons, more scroll inside the tile
        Rows := EnsureRange((AWidget.Items.Count + VerticalAppColumns - 1) div VerticalAppColumns, 1, 3);
        Result := 64 + Rows * 72;
      end;
    TWidgetKind.Calendar, TWidgetKind.Music:
      Result := 200;
    TWidgetKind.Remote, TWidgetKind.Links:
      Result := 210;
    TWidgetKind.Agents:
      Result := 180;
  else
    Result := 176;
  end;
end;

function AppsXaml(AWidget: TNotchWidget; const AIconFolder: string; AColumns: Integer): string;
var
  I: Integer;
  Item: TNotchItem;
begin
  if AWidget.Items.Count = 0 then
    Exit(EmptyXaml('No apps yet. The gear above adds some.'));
  Result := Format('<ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto"><VariableSizedWrapGrid ' +
    'Orientation="Horizontal" MaximumRowsOrColumns="%d" ItemWidth="64" ItemHeight="72">', [AColumns]);
  for I := 0 to AWidget.Items.Count - 1 do
  begin
    Item := AWidget.Items[I];
    Result := Result + Format('<Button x:Name="I%d" Width="62" Height="70" Padding="2" Background="Transparent" ' +
      'BorderThickness="0" CornerRadius="12" ToolTipService.ToolTip="%s"><StackPanel Spacing="5">%s' +
      '<TextBlock Text="%1:s" FontSize="11" MaxWidth="58" TextTrimming="CharacterEllipsis" ' +
      'HorizontalAlignment="Center"/></StackPanel></Button>',
      [I, Esc(Item.Name), IconXaml(TargetIcon(Item.Target, AIconFolder), Item.Name, 32, 'Icon' + I.ToString)]);
  end;
  Result := Result + '</VariableSizedWrapGrid></ScrollViewer>';
end;

function RowXaml(const AName, AIcon, ATitle, ADetail: string): string;
begin
  Result := Format('<Button x:Name="%s" HorizontalAlignment="Stretch" HorizontalContentAlignment="Left" ' +
    'Padding="8,5" Background="Transparent" BorderThickness="0" CornerRadius="10">' +
    '<StackPanel Orientation="Horizontal" Spacing="10">%s<StackPanel VerticalAlignment="Center">' +
    '<TextBlock Text="%s" FontSize="13" TextTrimming="CharacterEllipsis"/>', [AName, AIcon, Esc(ATitle)]);
  if ADetail <> '' then
    Result := Result + Format('<TextBlock Text="%s" FontSize="11" Foreground="%s" TextTrimming="CharacterEllipsis"/>',
      [Esc(ADetail), MutedColor]);
  Result := Result + '</StackPanel></StackPanel></Button>';
end;

function ListXaml(const ARows: string): string;
begin
  Result := '<ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto"><StackPanel Spacing="2">' + ARows +
    '</StackPanel></ScrollViewer>';
end;

function RemoteXaml(AWidget: TNotchWidget): string;
var
  I: Integer;
  Files: TArray<string>;
begin
  Files := RdpFiles;
  if AWidget.Items.Count + Length(Files) = 0 then
    Exit(EmptyXaml('No computers yet. The gear above adds some.'));
  Result := '';
  for I := 0 to AWidget.Items.Count - 1 do
    Result := Result + RowXaml('I' + I.ToString, GlyphXaml('&#xE7F4;', 15), AWidget.Items[I].Name,
      AWidget.Items[I].Target);
  for I := 0 to High(Files) do
    Result := Result + RowXaml('R' + I.ToString, GlyphXaml('&#xE8A5;', 15), ChangeFileExt(ExtractFileName(Files[I]),
      ''), 'Saved .rdp file');
  Result := ListXaml(Result);
end;

function LinksXaml(AWidget: TNotchWidget): string;
var
  I: Integer;
  Glyph: string;
begin
  if AWidget.Items.Count = 0 then
    Exit(EmptyXaml('No links yet. The gear above adds some.'));
  Result := '';
  for I := 0 to AWidget.Items.Count - 1 do
  begin
    if AWidget.Items[I].Target.Contains('://') then
      Glyph := '&#xE774;'
    else
      Glyph := '&#xE8B7;';
    Result := Result + RowXaml('I' + I.ToString, GlyphXaml(Glyph, 15), AWidget.Items[I].Name, '');
  end;
  Result := ListXaml(Result);
end;

// 0 for Monday as the user's first day of the week, up to 6 for Sunday
function FirstDayOfWeek: Integer;
var
  Buffer: array[0..1] of Char;
begin
  if GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_IFIRSTDAYOFWEEK, Buffer, Length(Buffer)) > 0 then
    Result := Ord(Buffer[0]) - Ord('0')
  else
    Result := 0;
end;

function CalendarXaml: string;
var
  Today, First: TDateTime;
  FirstDay, Offset, Day, Days, Cell, Column, Row, I: Integer;
begin
  Today := Date;
  First := StartOfTheMonth(Today);
  Days := DaysInMonth(Today);
  FirstDay := FirstDayOfWeek;
  // DayOfTheWeek: Monday 1 .. Sunday 7
  Offset := (DayOfTheWeek(First) - 1 - FirstDay + 7) mod 7;
  Result := '<Button x:Name="Open" Grid.Row="1" Padding="0" Background="Transparent" BorderThickness="0" ' +
    'HorizontalAlignment="Stretch" VerticalAlignment="Stretch" HorizontalContentAlignment="Stretch" ' +
    'VerticalContentAlignment="Stretch" ToolTipService.ToolTip="Open the calendar">' +
    '<Grid ColumnSpacing="12"><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/>' +
    '<ColumnDefinition Width="*"/></Grid.ColumnDefinitions>' +
    Format('<StackPanel VerticalAlignment="Center"><TextBlock Text="%s" FontSize="13" FontWeight="SemiBold" ' +
      'Foreground="#FF5F57"/><TextBlock Text="%s" FontSize="40" FontWeight="SemiBold" Margin="0,-4,0,-2"/>' +
      '<TextBlock Text="%s" FontSize="12" Foreground="%s"/></StackPanel>',
      [Esc(FormatDateTime('dddd', Today)), FormatDateTime('d', Today), Esc(FormatDateTime('mmmm', Today)),
      MutedColor]) +
    '<Grid Grid.Column="1" VerticalAlignment="Center"><Grid.ColumnDefinitions>';
  for I := 1 to 7 do
    Result := Result + '<ColumnDefinition Width="*"/>';
  Result := Result + '</Grid.ColumnDefinitions><Grid.RowDefinitions>';
  for I := 0 to (Offset + Days - 1) div 7 + 1 do
    Result := Result + '<RowDefinition Height="19"/>';
  Result := Result + '</Grid.RowDefinitions>';
  for I := 0 to 6 do
    // FormatSettings.ShortDayNames starts on Sunday
    Result := Result + Format('<TextBlock Grid.Column="%d" Text="%s" FontSize="10" Foreground="%s" ' +
      'HorizontalAlignment="Center"/>', [I, Esc(Copy(FormatSettings.ShortDayNames[(FirstDay + I + 1) mod 7 + 1], 1, 2)),
      MutedColor]);
  for Day := 1 to Days do
  begin
    Cell := Offset + Day - 1;
    Column := Cell mod 7;
    Row := Cell div 7 + 1;
    if Day = DayOf(Today) then
      Result := Result + Format('<Border Grid.Row="%d" Grid.Column="%d" Width="19" Height="18" CornerRadius="9" ' +
        'Background="#FF453A"><TextBlock Text="%d" FontSize="10" FontWeight="SemiBold" HorizontalAlignment="Center" ' +
        'VerticalAlignment="Center"/></Border>', [Row, Column, Day])
    else
      Result := Result + Format('<TextBlock Grid.Row="%d" Grid.Column="%d" Text="%d" FontSize="10" ' +
        'HorizontalAlignment="Center" VerticalAlignment="Center"/>', [Row, Column, Day]);
  end;
  Result := Result + '</Grid></Grid></Button>';
end;

function NotesXaml(AWidget: TNotchWidget): string;
begin
  // The text is set from code: line breaks do not survive a XAML attribute
  Result := '<TextBox x:Name="Note" Grid.Row="1" PlaceholderText="Type a note" ' +
    'AcceptsReturn="True" TextWrapping="Wrap" FontSize="13" CornerRadius="10" ' +
    'ScrollViewer.VerticalScrollBarVisibility="Auto"/>';
end;

const
  MusicXaml =
    '<Grid Grid.Row="1" RowSpacing="8"><Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/>' +
    '</Grid.RowDefinitions>' +
    '<StackPanel VerticalAlignment="Center" Spacing="2">' +
    '<TextBlock x:Name="MusicTitle" Text="Nothing playing" FontSize="16" FontWeight="SemiBold" ' +
    'TextTrimming="CharacterEllipsis"/>' +
    '<TextBlock x:Name="MusicArtist" Text="Start music in any app" FontSize="12" Foreground="#8E8E93" ' +
    'TextTrimming="CharacterEllipsis"/></StackPanel>' +
    '<StackPanel Grid.Row="1" Orientation="Horizontal" Spacing="10" HorizontalAlignment="Center">' +
    '<Button x:Name="PreviousButton" Width="36" Height="36" Padding="0" CornerRadius="18" Background="Transparent" ' +
    'BorderThickness="0"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="&#xE892;" ' +
    'FontSize="14"/></Button>' +
    '<Button x:Name="PlayButton" Width="44" Height="44" Padding="0" CornerRadius="22" Background="White" ' +
    'BorderThickness="0"><FontIcon x:Name="PlayGlyph" FontFamily="{ThemeResource SymbolThemeFontFamily}" ' +
    'Glyph="&#xE768;" FontSize="16" Foreground="Black"/></Button>' +
    '<Button x:Name="NextButton" Width="36" Height="36" Padding="0" CornerRadius="18" Background="Transparent" ' +
    'BorderThickness="0"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="&#xE893;" ' +
    'FontSize="14"/></Button></StackPanel></Grid>';

  FocusXaml =
    '<Grid Grid.Row="1" RowSpacing="8"><Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/>' +
    '</Grid.RowDefinitions>' +
    '<TextBlock x:Name="FocusClock" Text="25:00" FontSize="40" FontWeight="SemiBold" HorizontalAlignment="Center" ' +
    'VerticalAlignment="Center"/>' +
    '<Grid Grid.Row="1" ColumnSpacing="8"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/>' +
    '<ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>' +
    '<Button x:Name="FocusButton" Content="Start" HorizontalAlignment="Stretch" CornerRadius="10" ' +
    'Background="#2C2C2E" BorderThickness="0"/>' +
    '<Button x:Name="ResetButton" Grid.Column="1" Width="36" VerticalAlignment="Stretch" Padding="0" ' +
    'CornerRadius="10" Background="#2C2C2E" BorderThickness="0" ToolTipService.ToolTip="Reset">' +
    '<FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" ' +
    'Glyph="&#xE72C;" FontSize="13"/></Button></Grid></Grid>';

function WidgetXaml(AWidget: TNotchWidget; const AIconFolder: string; AVertical: Boolean): string;
var
  Body: string;
begin
  case AWidget.Kind of
    TWidgetKind.Apps:
      if AVertical then
        Body := AppsXaml(AWidget, AIconFolder, VerticalAppColumns)
      else
        Body := AppsXaml(AWidget, AIconFolder, AppColumns(AWidget));
    TWidgetKind.Agents:
      // Filled from the agent monitor, see AgentBodyXaml. The round button opens the usage limits.
      Body := '<Grid Grid.Row="1"><Border x:Name="AgentBody"/>' +
        '<Button x:Name="UsageButton" Width="28" Height="28" Padding="0" CornerRadius="14" ' +
        'HorizontalAlignment="Right" VerticalAlignment="Bottom" Background="#2C2C2E" BorderThickness="0" ' +
        'ToolTipService.ToolTip="Usage and limits" AutomationProperties.Name="Usage and limits">' +
        '<FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="&#xEC4A;" FontSize="13"/></Button></Grid>';
    TWidgetKind.Remote:
      Body := RemoteXaml(AWidget);
    TWidgetKind.Calendar:
      Body := CalendarXaml;
    TWidgetKind.Links:
      Body := LinksXaml(AWidget);
    TWidgetKind.Notes:
      Body := NotesXaml(AWidget);
    TWidgetKind.Music:
      Body := MusicXaml;
  else
    Body := FocusXaml;
  end;
  Result := TileXaml(AWidget.Kind, AWidget.Title, Body);
end;

{ Opening }

// Each returns a new closure, so every button keeps its own target

function OpenProc(const ATarget: string): TProc;
begin
  Result :=
    procedure
    begin
      OpenTarget(ATarget);
    end;
end;

function RemoteProc(const AAddress: string): TProc;
begin
  Result :=
    procedure
    begin
      OpenRemoteDesktop(AAddress);
    end;
end;

procedure WireWidget(AWidget: TNotchWidget; AFragment: TFragment);
var
  I: Integer;
  Files: TArray<string>;
begin
  for I := 0 to AWidget.Items.Count - 1 do
    case AWidget.Kind of
      TWidgetKind.Apps, TWidgetKind.Links:
        AFragment.OnClick('I' + I.ToString, OpenProc(AWidget.Items[I].Target));
      TWidgetKind.Remote:
        AFragment.OnClick('I' + I.ToString, RemoteProc(AWidget.Items[I].Target));
    end;
  if AWidget.Kind = TWidgetKind.Remote then
  begin
    Files := RdpFiles;
    for I := 0 to High(Files) do
      AFragment.OnClick('R' + I.ToString, RemoteProc(Files[I]));
  end;
  if AWidget.Kind = TWidgetKind.Calendar then
    // The same calendar as a click on the taskbar clock
    AFragment.OnClick('Open', OpenCalendarFlyout);
end;

{ Defaults }

procedure AddDefaultWidgets(ASettings: TNotchSettings; AAgents: TAgentKinds);
const
  CommonApps: array[0..8] of string = ('File Explorer', 'Terminal', 'Settings', 'Microsoft Edge', 'Google Chrome',
    'RAD Studio', 'Visual Studio Code', 'Notepad', 'Calculator');
  MaxApps = 6;
var
  Widget: TNotchWidget;
  Name: string;
  App, Found: TShellApp;
  Agent: TAgentKind;
begin
  Widget := TNotchWidget.Create(TWidgetKind.Apps);
  ASettings.Widgets.Add(Widget);
  for Name in CommonApps do
  begin
    Found := Default(TShellApp);
    for App in InstalledApps do
      // RAD Studio's shortcut carries its version in the name: the last one is the newest
      if SameText(App.Name, Name) or ((Name = 'RAD Studio') and App.Name.StartsWith(Name, True)) then
        Found := App;
    if (Found.Name <> '') and (Widget.Items.Count < MaxApps) then
      Widget.AddItem(Found.Name, Found.ParsingName);
  end;
  Widget := TNotchWidget.Create(TWidgetKind.Agents);
  ASettings.Widgets.Add(Widget);
  for Agent in AAgents do
    Widget.AddItem(AgentNames[Agent], AgentIds[Agent]);
  ASettings.Widgets.Add(TNotchWidget.Create(TWidgetKind.Calendar));
  ASettings.Widgets.Add(TNotchWidget.Create(TWidgetKind.Music));
  ASettings.Widgets.Add(TNotchWidget.Create(TWidgetKind.Focus));
end;

function WidgetAgents(AWidget: TNotchWidget): TAgentKinds;
var
  Item: TNotchItem;
  Kind: TAgentKind;
begin
  Result := [];
  for Item in AWidget.Items do
    if AgentKindOf(Item.Target, Kind) then
      Include(Result, Kind);
end;

function StateColorXaml(AState: TAgentState): string;
begin
  Result := Format('#%.8X', [StateColors[AState]]);
end;

function AgentBodyXaml(const ASessions: TArray<TAgentSession>; AKinds: TAgentKinds; ANow: TDateTime): string;
const
  MaxRows = 3;
var
  S: TAgentSession;
  Watched, Tip: string;
  Kind: TAgentKind;
  I: Integer;
begin
  Watched := '';
  for Kind in AKinds do
    Watched := Watched + IfThen(Watched = '', '', ', ') + AgentNames[Kind];
  Tip := '';
  for S in ASessions do
    Tip := Tip + IfThen(Tip = '', '', #10) + Format('%s, %s: %s. %s (%s)', [AgentNames[S.Kind], S.Project,
      StateNames[S.State], S.Activity, S.Elapsed(ANow)]);
  if Tip = '' then
    Tip := 'No session of ' + IfThen(Watched = '', 'any agent', Watched) + ' in the last 10 minutes';
  Result := Format('<StackPanel VerticalAlignment="Center" Spacing="3" Background="Transparent" ' +
    'ToolTipService.ToolTip="%s"%s>', [Esc(Tip + #10#10 + AgentLegend + #10 + 'Click for all sessions'), XamlNs]);
  if Length(ASessions) = 0 then
  begin
    Result := Result + '<TextBlock Text="All quiet" FontSize="20" FontWeight="SemiBold"/>';
    if Watched = '' then
      Watched := 'No agent picked yet. The gear above picks them.'
    else
      Watched := 'Watching ' + Watched;
    Result := Result + Format('<TextBlock Text="%s" FontSize="12" Foreground="%s" TextWrapping="Wrap"/>',
      [Esc(Watched), MutedColor]);
  end
  else if Length(ASessions) = 1 then
  begin
    S := ASessions[0];
    Result := Result + Format('<TextBlock Text="%0:s" FontSize="22" FontWeight="SemiBold" Foreground="%1:s"/>' +
      '<TextBlock Text="%2:s" FontSize="13" TextTrimming="CharacterEllipsis"/>' +
      '<TextBlock Text="%4:s" FontSize="12" Foreground="%3:s" TextWrapping="Wrap" MaxLines="2" ' +
      'TextTrimming="CharacterEllipsis"/><TextBlock Text="%5:s" FontSize="11" Foreground="%3:s"/>',
      [StateNames[S.State], StateColorXaml(S.State), Esc(AgentNames[S.Kind] + ' - ' + S.Project), MutedColor,
      Esc(S.Activity), Esc(S.Elapsed(ANow))]);
  end
  else
  begin
    for I := 0 to Min(MaxRows, Length(ASessions)) - 1 do
    begin
      S := ASessions[I];
      Result := Result + Format('<Grid ColumnSpacing="8"><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/>' +
        '<ColumnDefinition Width="*"/></Grid.ColumnDefinitions>' +
        '<Ellipse Width="8" Height="8" Fill="%s" VerticalAlignment="Center"/>' +
        '<StackPanel Grid.Column="1"><TextBlock Text="%s" FontSize="13" TextTrimming="CharacterEllipsis"/>' +
        '<TextBlock Text="%s" FontSize="11" Foreground="%s" TextTrimming="CharacterEllipsis"/></StackPanel></Grid>',
        [StateColorXaml(S.State), Esc(S.Project + ' - ' + StateNames[S.State]), Esc(AgentNames[S.Kind] + ': ' +
        S.Activity), MutedColor]);
    end;
    if Length(ASessions) > MaxRows then
      Result := Result + Format('<TextBlock Text="+%d more" FontSize="11" Foreground="%s"/>',
        [Length(ASessions) - MaxRows, MutedColor]);
  end;
  Result := Result + '</StackPanel>';
end;

end.
