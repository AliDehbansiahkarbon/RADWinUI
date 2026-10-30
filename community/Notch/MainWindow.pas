unit MainWindow;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  RADWinUI.Forms,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Controls,
  MainWindow.Xaml,
  Notch.Settings,
  Notch.Shell,
  Notch.Agents,
  Notch.Usage,
  Notch.Widgets,
  Notch.Details;

type
  // An AI agents tile and the piece of XAML it shows at the moment
  TAgentView = class
  public
    Widget: TNotchWidget;
    Tile: TWinUIGlowTile;
    Host: TWinUIBorder;
    Fragment: TFragment;
    Shown: string;
  end;

  TMainWindow = class(TMainWindowBase)
  private
    FTimer: TWinUITimer;
    FTicks: Integer;
    FGreen, FPurple, FTeal, FTileBrush, FTileGlassBrush: TWinUISolidColorBrush;
    FBackdrop: TFragment;
    FSolidNotch, FGlassNotch: TWinUISolidColorBrush;
    FStateBrushes: array[TAgentState] of TWinUISolidColorBrush;
    FSettings: TNotchSettings;
    FDataFolder: string;
    FIconFolder: string;
    FTestMode: Boolean;
    FDirty: Boolean;
    FDay: Word;
    // The tiles one after the other, in pixels: across the wide panel, down the upright one
    FRowLength: Integer;
    // On the left and right edges the panel stands upright
    FVertical: Boolean;
    FLaidOut: Boolean;
    // The registry key that starts programs with Windows, a test key in the smoke test
    FRunKey: string;
    // Widget tiles of the panel, and pieces of XAML waiting to be freed
    FWidgetFragments: TList<TFragment>;
    FTiles: TList<TWinUIGlowTile>;
    FTileSizes: TArray<Integer>;
    FTrash: TObjectList<TFragment>;
    // A tile being dragged to a new place
    FDragIndex: Integer;
    FDragStart: Double;
    FDragTarget: Integer;
    FDragActive: Boolean;
    // The window being dragged to another edge
    FMovingWindow: Boolean;
    // Keyboard
    FKeyboardOpen: Boolean;
    FPreviousWindow: THandle;
    FPointerOverNote: Boolean;
    // Edit page
    FEditing: Boolean;
    FSelected: Integer;
    FListFragment, FAddFragment, FItemsFragment, FResultsFragment, FSettingsFragment: TFragment;
    FResults: TArray<TShellApp>;
    FHookStatus: string;
    // Elements of the music and focus widgets, nil while they are not in the panel
    FMusicTile, FFocusTile: TWinUIGlowTile;
    FMusicTitle, FMusicArtist, FFocusClock: TWinUITextBlock;
    FPlayGlyph: TWinUIFontIcon;
    FFocusButton: TWinUIButton;
    FFocusLeft: Integer;
    FFocusRunning: Boolean;
    // AI agents
    FAgents: TAgentMonitor;
    FAgentViews: TObjectList<TAgentView>;
    FAgentStates: TDictionary<string, TAgentState>;
    FDetectedAgents: TAgentKinds;
    FClaudeSettingsFile, FCodexConfigFile: string;
    FAlertOpened: Boolean;
    FAlertUntil: TDateTime;
    FDetails: TAgentDetailsWindow;
    FUsage: TUsageMonitor;
    FUsageClicked: TDateTime;
    // Smoke test
    FSmokeStep: Integer;
    FIconShown: Boolean;
    FSnapshotsPending: Integer;
    FSnapshotError: string;
    function MakeBrush(AColor: Cardinal): TWinUISolidColorBrush;
    function TileBrush: TWinUISolidColorBrush;
    function Hwnd: THandle;
    function Scale: Double;
    function WorkAreaWidth: Integer;
    function WorkAreaHeight: Integer;
    function DragPosition(E: TWinUIPointerRoutedEventArgs): Double;
    function Shift(ADistance: Single): TWinUIVector3;
    procedure ApplyOrientation;
    function Selected: TNotchWidget;
    procedure TimerTick(Sender: TObject);
    procedure UpdateClock;
    procedure UpdateSize;
    procedure Changed;
    procedure Later(const AProc: TProc);
    procedure ReplaceFragment(var AFragment: TFragment; AHost: TWinUIBorder; const AXaml: string);
    procedure RebuildWidgets;
    procedure BindMusic(ATile: TWinUIGlowTile; AFragment: TFragment);
    procedure BindFocus(ATile: TWinUIGlowTile; AFragment: TFragment);
    procedure BindNotes(AWidget: TNotchWidget; AFragment: TFragment);
    procedure BindTileDrag(ATile: TWinUIGlowTile; AFragment: TFragment; AIndex: Integer);
    procedure DragTile(ADelta: Double);
    procedure EndTileDrag(ACommit: Boolean);
    procedure ToggleFocus;
    procedure ResetFocus;
    procedure UpdateFocus;
    // Transparency, position and keyboard
    procedure UpdateGlass;
    procedure SetTransparencyLevel(AValue: Integer);
    procedure ApplyEdge;
    procedure PlaceWindow;
    procedure StartWindowDrag;
    procedure SnapToEdge;
    procedure SetEdge(AEdge: TNotchEdge);
    procedure TakeKeyboard;
    procedure OpenWithKeyboard;
    procedure CloseKeyboard(ARestoreFocus: Boolean);
    procedure NotchKeyDown(Sender: TObject; E: TWinUIKeyRoutedEventArgs);
    // AI agents
    function WatchedAgents: TAgentKinds;
    procedure RefreshAgents(ANow: TDateTime);
    procedure NormalizeAgentWidgets;
    procedure AgentTileClick(Sender: TObject; const E: TWinValue);
    procedure ShowDetails(AUsage: Boolean);
    procedure SetExactClaudeLimits(AValue: Boolean);
    procedure DetailsClosed(Sender: TObject; E: TWinUIWindowEventArgs);
    procedure ToggleAgent(AKind: TAgentKind);
    procedure InstallHooks;
    procedure RemoveHooks;
    // Edit page
    procedure SetEditing(AValue: Boolean);
    procedure RebuildEditList;
    procedure RebuildAddList;
    procedure RebuildItems;
    procedure RebuildResults;
    procedure RebuildSettings;
    procedure ShowDetail;
    procedure SelectWidget(AIndex: Integer);
    procedure AddApp(const AName, AParsingName: string);
    procedure DeleteItem(AIndex: Integer);
    function Action(AKind: Char; AIndex: Integer): TProc;
    function AddAppAction(const AApp: TShellApp): TProc;
    procedure Snapshot(const AFileName: string; AElement: TWinUIUIElement = nil);
    procedure SmokeStep;
  protected
    function HandleMessage(AMsg: Cardinal; AWParam: NativeUInt; ALParam: NativeInt;
      var AResult: NativeInt): Boolean; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure AddWidget(AKind: TWidgetKind);
    procedure RemoveWidget(AIndex: Integer);
    procedure MoveWidget(AIndex, ADelta: Integer);
  published
    procedure ToggleKeyPressed(Sender: TObject);
    procedure MediaChanged(Sender: TObject);
    procedure EditButtonClick(Sender: TObject);
    procedure PinButtonClick(Sender: TObject);
    procedure TransparencySwitchToggled(Sender: TObject);
    procedure TransparencySliderValueChanged(Sender: TObject);
    procedure QuitButtonClick(Sender: TObject);
    procedure AddEntryButtonClick(Sender: TObject);
    procedure TitleBoxTextChanged(Sender: TObject);
    procedure SearchBoxTextChanged(Sender: TObject);
    procedure HeaderBarPointerPressed(Sender: TObject);
    procedure PillHostPointerPressed(Sender: TObject);
  end;

implementation

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.MultiMon,
  RADWinUI.Abi,
  System.Types,
  System.Math,
  System.StrUtils,
  System.DateUtils,
  System.IOUtils,
  System.Win.Registry,
  Notch.Placement,
  Notch.Tests;

const
  FocusSeconds = 25 * 60;
  TickMs = 250;
  PanelHeight = 276;
  EditWidth = 920;
  EditHeight = 480;
  // The upright panel and its edit page, against the left or right edge
  EditVerticalWidth = 460;
  EditVerticalHeight = 860;
  EditVerticalListHeight = 330;
  // Header (clock above the tools), spacing and padding of the upright panel
  VerticalChrome = 152;
  MinVerticalHeight = 300;
  MinPanelWidth = 660;
  // Panel padding left and right, and the gap between tiles
  PanelPadding = 44;
  TileGap = 14;
  // The window is a little larger than the panel, see the margins in the XAML
  WindowMarginX = 40;
  WindowMarginY = 24;
  MaxResults = 24;
  // A press moves this far before it counts as a drag
  DragThreshold = 6;
  AlertSeconds = 8;
  PlayGlyphText = #$E768;
  PauseGlyphText = #$E769;
  PinGlyphText = #$E718;
  UnpinGlyphText = #$E77A;
  EditGlyphText = #$E713;
  DoneGlyphText = #$E73E;
  SettingsRow = -1;

function Vis(AVisible: Boolean): TWinUIVisibility;
begin
  if AVisible then
    Result := TWinUIVisibility.Visible
  else
    Result := TWinUIVisibility.Collapsed;
end;

function ToRect(const ARect: RectInt32): TRect;
begin
  Result := TRect.Create(ARect.X, ARect.Y, ARect.X + ARect.Width, ARect.Y + ARect.Height);
end;

function Vec3(AX: Single): TWinUIVector3;
begin
  Result.X := AX;
  Result.Y := 0;
  Result.Z := 0;
end;

constructor TMainWindow.Create;
var
  SettingsFile: string;
  State: TAgentState;
  ClaudeRoot, CodexRoot: string;
begin
  inherited;
  // Only the notch takes the pointer, clicks next to it reach the windows below
  HitTestElement := Notch;
  FTestMode := GetEnvironmentVariable('RADWINUI_TEST_MONITOR') <> '';
  FGreen := MakeBrush($FF3DDC84);
  FPurple := MakeBrush($FFA77BFF);
  FTeal := MakeBrush($FF2EC4B6);
  FTileBrush := MakeBrush($FF161618);
  // With Transparency on the tiles are a light tint over the see-through panel, a little
  // lighter than it, so they stay apart and their text readable
  FTileGlassBrush := MakeBrush($16FFFFFF);
  FSolidNotch := MakeBrush($FF000000);
  FGlassNotch := MakeBrush($B8000000);
  for State := Low(TAgentState) to High(TAgentState) do
    FStateBrushes[State] := MakeBrush(StateColors[State]);
  FWidgetFragments := TList<TFragment>.Create;
  FTiles := TList<TWinUIGlowTile>.Create;
  FTrash := TObjectList<TFragment>.Create;
  FAgentViews := TObjectList<TAgentView>.Create;
  FAgentStates := TDictionary<string, TAgentState>.Create;
  FFocusLeft := FocusSeconds;
  FDragIndex := -1;

  if FindCmdLineSwitch('smoke-test') then
  begin
    // A test never touches the user's settings, nor the agents' own files
    FDataFolder := TPath.Combine(TPath.GetTempPath, 'RADWinUI Notch smoke test');
    if TDirectory.Exists(FDataFolder) then
      TDirectory.Delete(FDataFolder, True);
    ClaudeRoot := TPath.Combine(FDataFolder, 'claude\projects');
    CodexRoot := TPath.Combine(FDataFolder, 'codex\sessions');
    ForceDirectories(ClaudeRoot);
    ForceDirectories(CodexRoot);
    FClaudeSettingsFile := TPath.Combine(FDataFolder, 'claude\settings.json');
    FRunKey := 'Software\RADWinUI Notch Test\Run';
    FCodexConfigFile := TPath.Combine(FDataFolder, 'codex\config.toml');
    Notch.HoverDelay := 0;
    Notch.AnimationDuration := 100;
  end
  else
  begin
    FDataFolder := NotchDataFolder;
    ClaudeRoot := TAgentMonitor.DefaultClaudeRoot;
    CodexRoot := TAgentMonitor.DefaultCodexRoot;
    FClaudeSettingsFile := TPath.Combine(GetEnvironmentVariable('USERPROFILE'), '.claude\settings.json');
    FCodexConfigFile := TPath.Combine(GetEnvironmentVariable('USERPROFILE'), '.codex\config.toml');
    FRunKey := WindowsRunKey;
  end;
  FDetectedAgents := TAgentMonitor.Detect(ClaudeRoot, CodexRoot);
  FAgents := TAgentMonitor.Create(ClaudeRoot, CodexRoot, TPath.Combine(FDataFolder, 'events'));
  FUsage := TUsageMonitor.Create(ClaudeRoot, CodexRoot);
  if FindCmdLineSwitch('smoke-test') then
    // Never the real Claude login in a test
    FUsage.CredentialsFile := TPath.Combine(FDataFolder, 'no-credentials.json');
  FIconFolder := TPath.Combine(FDataFolder, 'icons');
  SettingsFile := TPath.Combine(FDataFolder, 'settings.json');
  FSettings := TNotchSettings.Create(SettingsFile);
  if not FSettings.Load then
  begin
    // A broken file is kept aside rather than overwritten
    if TFile.Exists(SettingsFile) then
      TFile.Copy(SettingsFile, SettingsFile + '.bad', True);
    AddDefaultWidgets(FSettings, FDetectedAgents);
    FDirty := True;
  end;
  NormalizeAgentWidgets;
  FUsage.Exact := FSettings.ExactClaudeLimits;

  TransparencySlider.Value := FSettings.TransparencyLevel;
  TransparencySwitch.IsOn := FSettings.Transparency;
  TransparencySwitchToggled(nil);
  if FSettings.Pinned then
  begin
    PinGlyph.Glyph := UnpinGlyphText;
    Notch.ExpandOnHover := False;
    Notch.IsExpanded := True;
  end;
  Notch.KeyDown.Add(NotchKeyDown);
  Activated.Add(
    procedure(Sender: TObject; E: TWinUIWindowActivatedEventArgs)
    begin
      // Clicking somewhere else ends a keyboard visit
      if (E.WindowActivationState = TWinUIWindowActivationState.Deactivated) and FKeyboardOpen then
        CloseKeyboard(False);
    end);
  ApplyEdge;
  UpdateClock;
  RebuildWidgets;
  RefreshAgents(Now);
  FTimer := TWinUITimer.Create;
  FTimer.Interval := TickMs;
  FTimer.OnTimer := TimerTick;
  FTimer.Enabled := True;
end;

destructor TMainWindow.Destroy;
var
  Fragment: TFragment;
  View: TAgentView;
begin
  FTimer.Free;
  if FDetails <> nil then
  begin
    FDetails.OnClosed := nil;
    FDetails.Close;
  end;
  if FDirty then
    try
      FSettings.Save;
    except
      // Closing goes on, the settings of the last few seconds are lost
    end;
  for Fragment in FWidgetFragments do
    Fragment.Free;
  for View in FAgentViews do
    View.Fragment.Free;
  FAgentViews.Free;
  FWidgetFragments.Free;
  FTiles.Free;
  FListFragment.Free;
  FAddFragment.Free;
  FItemsFragment.Free;
  FResultsFragment.Free;
  FSettingsFragment.Free;
  FBackdrop.Free;
  FTrash.Free;
  FAgentStates.Free;
  FUsage.Free;
  FAgents.Free;
  FSettings.Free;
  inherited;
end;

function TMainWindow.MakeBrush(AColor: Cardinal): TWinUISolidColorBrush;
var
  C: TWinUIColor;
begin
  C.A := AColor shr 24;
  C.R := (AColor shr 16) and $FF;
  C.G := (AColor shr 8) and $FF;
  C.B := AColor and $FF;
  Result := TWinUISolidColorBrush.Create(Self);
  Result.Color := C;
end;

function TMainWindow.Hwnd: THandle;
begin
  Result := THandle(AppWindow.Id.Value);
end;

function TMainWindow.Scale: Double;
begin
  Result := GetDpiForWindow(Hwnd) / 96;
end;

function TMainWindow.WorkAreaWidth: Integer;
var
  Info: TMonitorInfo;
begin
  // In effective pixels, like the window's Width
  Info.cbSize := SizeOf(Info);
  if GetMonitorInfo(MonitorFromWindow(Hwnd, MONITOR_DEFAULTTONEAREST), @Info) then
    Result := Round((Info.rcWork.Right - Info.rcWork.Left) / Scale)
  else
    Result := 1280;
end;

function TMainWindow.WorkAreaHeight: Integer;
var
  Info: TMonitorInfo;
begin
  Info.cbSize := SizeOf(Info);
  if GetMonitorInfo(MonitorFromWindow(Hwnd, MONITOR_DEFAULTTONEAREST), @Info) then
    Result := Round((Info.rcWork.Bottom - Info.rcWork.Top) / Scale)
  else
    Result := 800;
end;

procedure TMainWindow.Changed;
begin
  FDirty := True;
end;

procedure TMainWindow.Later(const AProc: TProc);
begin
  // After the current message or event, when it is safe to rebuild or to move the window
  DispatcherQueue.TryEnqueue(TDispatcherQueueHandler.Create(
    procedure
    begin
      AProc;
    end));
end;

procedure TMainWindow.TimerTick(Sender: TObject);
var
  Cursor: TPoint;
  Bounds: TRect;
begin
  Inc(FTicks);
  // Freed here, never inside the click that replaced them
  FTrash.Clear;
  if FDirty then
  begin
    FDirty := False;
    FSettings.Save;
  end;
  if FTicks mod (1000 div TickMs) = 0 then
  begin
    UpdateClock;
    if not FindCmdLineSwitch('smoke-test') then
      RefreshAgents(Now);
    if FFocusRunning then
    begin
      Dec(FFocusLeft);
      if FFocusLeft <= 0 then
      begin
        FFocusLeft := 0;
        FFocusRunning := False;
        if FFocusTile <> nil then
        begin
          FFocusTile.GlowBrush := FGreen;
          FFocusTile.Pulse := False;
          FFocusTile.FadeAfter := 8;
        end;
        // Time is up: show it
        Notch.Expand;
      end;
      UpdateFocus;
    end;
  end;
  // An agent opened the notch for a moment: close it again unless the pointer went there
  if FAlertOpened and (Now > FAlertUntil) then
  begin
    FAlertOpened := False;
    GetCursorPos(Cursor);
    GetWindowRect(Hwnd, Bounds);
    if not FSettings.Pinned and not FEditing and not FKeyboardOpen and not Bounds.Contains(Cursor) then
      Notch.Collapse;
  end;
  if FindCmdLineSwitch('smoke-test') and (FTicks mod 2 = 0) then
    SmokeStep;
end;

procedure TMainWindow.UpdateClock;
begin
  PillClock.Text := FormatDateTime('hh:nn', Now);
  PillHours.Text := FormatDateTime('hh', Now);
  PillMinutes.Text := FormatDateTime('nn', Now);
  ClockLabel.Text := PillClock.Text;
  DateLabel.Text := FormatDateTime('dddd, d mmmm', Now);
  // A new day: the calendar shows it
  if (FDay <> 0) and (FDay <> DayOf(Date)) and not FEditing and FSettings.HasKind(TWidgetKind.Calendar) then
    RebuildWidgets;
  FDay := DayOf(Date);
end;

procedure TMainWindow.UpdateSize;
var
  W, H: Integer;
begin
  if FVertical then
  begin
    // One tile wide, as tall as the tiles up to the screen's height, then the column scrolls
    if FEditing then
    begin
      W := EditVerticalWidth;
      H := EditVerticalHeight;
    end
    else
    begin
      W := VerticalTileWidth + PanelPadding;
      H := Max(VerticalChrome + FRowLength, MinVerticalHeight);
    end;
    H := Min(H, WorkAreaHeight - WindowMarginY - 16);
  end
  else
  begin
    if FEditing then
    begin
      W := EditWidth;
      H := EditHeight;
    end
    else
    begin
      W := FRowLength + PanelPadding;
      H := PanelHeight;
    end;
    // Wider than the screen, the widgets scroll
    W := Min(Max(W, MinPanelWidth), WorkAreaWidth - WindowMarginX);
  end;
  Notch.ExpandedWidth := W;
  Notch.ExpandedHeight := H;
  Width := W + WindowMarginX;
  Height := H + WindowMarginY;
  PlaceWindow;
end;

procedure TMainWindow.ReplaceFragment(var AFragment: TFragment; AHost: TWinUIBorder; const AXaml: string);
var
  Fragment: TFragment;
begin
  // Loaded first: when the XAML fails, the old piece stays where it is
  Fragment := TFragment.Create(AXaml);
  if AFragment <> nil then
    FTrash.Add(AFragment);
  AFragment := Fragment;
  AHost.Child := Fragment.Root;
end;

{ Widgets }

procedure TMainWindow.RebuildWidgets;
var
  Widget: TNotchWidget;
  Fragment: TFragment;
  Tile: TWinUIGlowTile;
  Corners: TWinUICornerRadius;
  View: TAgentView;
  I: Integer;
begin
  WidgetRow.Children.Clear;
  FTrash.AddRange(FWidgetFragments);
  FWidgetFragments.Clear;
  for View in FAgentViews do
    if View.Fragment <> nil then
      FTrash.Add(View.Fragment);
  FAgentViews.Clear;
  FTiles.Clear;
  FMusicTile := nil;
  FMusicTitle := nil;
  FMusicArtist := nil;
  FPlayGlyph := nil;
  FFocusTile := nil;
  FFocusClock := nil;
  FFocusButton := nil;
  FDragIndex := -1;
  Corners.TopLeft := 20;
  Corners.TopRight := 20;
  Corners.BottomRight := 20;
  Corners.BottomLeft := 20;
  FRowLength := 0;
  SetLength(FTileSizes, FSettings.Widgets.Count);
  for I := 0 to FSettings.Widgets.Count - 1 do
  begin
    Widget := FSettings.Widgets[I];
    Fragment := TFragment.Create(WidgetXaml(Widget, FIconFolder, FVertical));
    FWidgetFragments.Add(Fragment);
    WireWidget(Widget, Fragment);
    // Owned by the fragment, so it goes with it
    Tile := TWinUIGlowTile.Create(Fragment.Root);
    Tile.Background := TileBrush;
    Tile.CornerRadius := Corners;
    Tile.Padding := RADWinUI.Framework.Thickness(16, 12, 16, 12);
    if FVertical then
    begin
      Tile.Width := VerticalTileWidth;
      Tile.Height := WidgetHeight(Widget);
      FTileSizes[I] := WidgetHeight(Widget);
    end
    else
    begin
      Tile.Width := WidgetWidth(Widget);
      FTileSizes[I] := WidgetWidth(Widget);
    end;
    Tile.HorizontalContentAlignment := TWinUIHorizontalAlignment.Stretch;
    Tile.VerticalContentAlignment := TWinUIVerticalAlignment.Stretch;
    Tile.GlowRadius := 26;
    Tile.GlowOpacity := 0.55;
    Tile.IsGlowing := False;
    // Tab and the arrow keys stop on each tile, with the system focus frame
    Tile.IsTabStop := True;
    Tile.UseSystemFocusVisuals := True;
    Tile.Content := Fragment.Root;
    WidgetRow.Children.Add(Tile);
    FTiles.Add(Tile);
    BindTileDrag(Tile, Fragment, I);
    case Widget.Kind of
      TWidgetKind.Music:
        BindMusic(Tile, Fragment);
      TWidgetKind.Focus:
        BindFocus(Tile, Fragment);
      TWidgetKind.Notes:
        BindNotes(Widget, Fragment);
      TWidgetKind.Agents:
        begin
          View := TAgentView.Create;
          FAgentViews.Add(View);
          View.Widget := Widget;
          View.Tile := Tile;
          View.Host := TWinUIBorder(Fragment.Find('AgentBody', TWinUIBorder));
          Tile.OnClick := AgentTileClick;
          Fragment.OnClick('UsageButton',
            procedure
            begin
              FUsageClicked := Now;
              ShowDetails(True);
            end);
        end;
    end;
    if FRowLength > 0 then
      Inc(FRowLength, TileGap);
    Inc(FRowLength, FTileSizes[I]);
  end;
  FAgents.Kinds := WatchedAgents;
  UpdateSize;
  MediaChanged(nil);
  UpdateFocus;
  RefreshAgents(Now);
  if FindCmdLineSwitch('smoke-test') and (FWidgetFragments.Count > 0) then
    // The first app icon of the panel, to see that icons from the cache load
    for Fragment in FWidgetFragments do
      if Fragment.Find('Icon0', TWinUIImage) <> nil then
      begin
        TWinUIImage(Fragment.Find('Icon0', TWinUIImage)).ImageOpened.Add(
          procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
          begin
            FIconShown := True;
          end);
        Break;
      end;
end;

{ Dragging a tile to a new place }

procedure TMainWindow.BindTileDrag(ATile: TWinUIGlowTile; AFragment: TFragment; AIndex: Integer);
var
  Header: TWinUIUIElement;
begin
  Header := TWinUIUIElement(AFragment.Find('Header', TWinUIUIElement));
  if Header = nil then
    Exit;
  Header.PointerPressed.Add(
    procedure(Sender: TObject; E: TWinUIPointerRoutedEventArgs)
    begin
      FDragIndex := AIndex;
      FDragStart := DragPosition(E);
      FDragActive := False;
      FDragTarget := AIndex;
      Header.CapturePointer(E.Pointer);
      // A tile's header reorders tiles, it never moves the window
      E.Handled := True;
    end);
  Header.PointerMoved.Add(
    procedure(Sender: TObject; E: TWinUIPointerRoutedEventArgs)
    var
      Delta: Double;
    begin
      if FDragIndex <> AIndex then
        Exit;
      Delta := DragPosition(E) - FDragStart;
      if not FDragActive and (Abs(Delta) > DragThreshold) then
      begin
        FDragActive := True;
        ATile.Opacity := 0.85;
      end;
      if FDragActive then
        DragTile(Delta);
    end);
  Header.PointerReleased.Add(
    procedure(Sender: TObject; E: TWinUIPointerRoutedEventArgs)
    begin
      if FDragIndex = AIndex then
      begin
        Header.ReleasePointerCaptures;
        EndTileDrag(True);
      end;
    end);
  Header.PointerCaptureLost.Add(
    procedure(Sender: TObject; E: TWinUIPointerRoutedEventArgs)
    begin
      if FDragIndex = AIndex then
        EndTileDrag(False);
    end);
end;

function TMainWindow.DragPosition(E: TWinUIPointerRoutedEventArgs): Double;
begin
  // Along the row: across the wide panel, down the upright one
  if FVertical then
    Result := E.GetCurrentPoint(WidgetRow).Position.Y
  else
    Result := E.GetCurrentPoint(WidgetRow).Position.X;
end;

function TMainWindow.Shift(ADistance: Single): TWinUIVector3;
begin
  Result := Vec3(0);
  if FVertical then
    Result.Y := ADistance
  else
    Result.X := ADistance;
end;

procedure TMainWindow.DragTile(ADelta: Double);
var
  J: Integer;
  Room: Single;
begin
  FDragTarget := TileDropIndex(FTileSizes, TileGap, FDragIndex, ADelta);
  // The tiles between make room where the dragged one will land
  Room := FTileSizes[FDragIndex] + TileGap;
  for J := 0 to FTiles.Count - 1 do
    if J = FDragIndex then
      FTiles[J].Translation := Shift(ADelta)
    else if (J > FDragIndex) and (J <= FDragTarget) then
      FTiles[J].Translation := Shift(-Room)
    else if (J < FDragIndex) and (J >= FDragTarget) then
      FTiles[J].Translation := Shift(Room)
    else
      FTiles[J].Translation := Shift(0);
end;

procedure TMainWindow.EndTileDrag(ACommit: Boolean);
var
  Index: Integer;
  Tile: TWinUIGlowTile;
begin
  Index := FDragIndex;
  FDragIndex := -1;
  if ACommit and FDragActive and (FDragTarget <> Index) then
  begin
    FDragActive := False;
    FSettings.Widgets.Move(Index, FDragTarget);
    Changed;
    // Not inside the header's own event: the rebuild frees it
    Later(RebuildWidgets);
    Exit;
  end;
  FDragActive := False;
  for Tile in FTiles do
  begin
    Tile.Translation := Vec3(0);
    Tile.Opacity := 1;
  end;
end;

{ Music }

procedure TMainWindow.BindMusic(ATile: TWinUIGlowTile; AFragment: TFragment);
begin
  // The Now playing widget: whatever plays on the PC, as Windows sees it
  ATile.GlowBrush := FTeal;
  FMusicTile := ATile;
  FMusicTitle := TWinUITextBlock(AFragment.Find('MusicTitle', TWinUITextBlock));
  FMusicArtist := TWinUITextBlock(AFragment.Find('MusicArtist', TWinUITextBlock));
  FPlayGlyph := TWinUIFontIcon(AFragment.Find('PlayGlyph', TWinUIFontIcon));
  AFragment.OnClick('PreviousButton',
    procedure
    begin
      Media.Previous;
    end);
  AFragment.OnClick('PlayButton',
    procedure
    begin
      Media.PlayPause;
    end);
  AFragment.OnClick('NextButton',
    procedure
    begin
      Media.Next;
    end);
end;

procedure TMainWindow.MediaChanged(Sender: TObject);
begin
  if Media.IsPlaying then
    PillMusic.Opacity := 1
  else
    PillMusic.Opacity := 0;
  if FMusicTile = nil then
    Exit;
  if Media.HasSession and (Media.Title <> '') then
  begin
    FMusicTitle.Text := Media.Title;
    FMusicArtist.Text := Media.Artist;
    if Media.Artist = '' then
      FMusicArtist.Text := ChangeFileExt(ExtractFileName(Media.SourceApp), '');
  end
  else
  begin
    FMusicTitle.Text := 'Nothing playing';
    FMusicArtist.Text := 'Start music in any app';
  end;
  if Media.IsPlaying then
    FPlayGlyph.Glyph := PauseGlyphText
  else
    FPlayGlyph.Glyph := PlayGlyphText;
  FMusicTile.IsGlowing := Media.IsPlaying;
  FMusicTile.Pulse := Media.IsPlaying;
end;

{ Focus }

procedure TMainWindow.BindFocus(ATile: TWinUIGlowTile; AFragment: TFragment);
begin
  // The timer keeps running while the widget is rebuilt, the new one shows it
  FFocusTile := ATile;
  FFocusClock := TWinUITextBlock(AFragment.Find('FocusClock', TWinUITextBlock));
  FFocusButton := TWinUIButton(AFragment.Find('FocusButton', TWinUIButton));
  ATile.GlowBrush := FPurple;
  if FFocusRunning then
  begin
    ATile.Pulse := True;
    ATile.IsGlowing := True;
  end;
  AFragment.OnClick('FocusButton', ToggleFocus);
  AFragment.OnClick('ResetButton', ResetFocus);
end;

procedure TMainWindow.ToggleFocus;
begin
  if FFocusLeft = 0 then
    FFocusLeft := FocusSeconds;
  FFocusRunning := not FFocusRunning;
  if FFocusTile <> nil then
    if FFocusRunning then
    begin
      FFocusTile.FadeAfter := 0;
      FFocusTile.GlowBrush := FPurple;
      FFocusTile.Pulse := True;
      FFocusTile.IsGlowing := True;
    end
    else
      FFocusTile.Pulse := False;
  UpdateFocus;
end;

procedure TMainWindow.ResetFocus;
begin
  FFocusRunning := False;
  FFocusLeft := FocusSeconds;
  if FFocusTile <> nil then
  begin
    FFocusTile.Pulse := False;
    FFocusTile.IsGlowing := False;
  end;
  UpdateFocus;
end;

procedure TMainWindow.UpdateFocus;
begin
  if FFocusClock = nil then
    Exit;
  FFocusClock.Text := Format('%.2d:%.2d', [FFocusLeft div 60, FFocusLeft mod 60]);
  if FFocusRunning then
    FFocusButton.Content := 'Pause'
  else if (FFocusLeft = FocusSeconds) or (FFocusLeft = 0) then
    FFocusButton.Content := 'Start'
  else
    FFocusButton.Content := 'Resume';
end;

{ Notes }

procedure TMainWindow.BindNotes(AWidget: TNotchWidget; AFragment: TFragment);
var
  Note: TWinUITextBox;
begin
  Note := TWinUITextBox(AFragment.Find('Note', TWinUITextBox));
  // A text box breaks lines at a carriage return
  Note.Text := AWidget.Text.Replace(#13#10, #13).Replace(#10, #13);
  Note.TextChanged.Add(
    procedure(Sender: TObject; E: TWinUITextChangedEventArgs)
    begin
      AWidget.Text := Note.Text;
      Changed;
    end);
  // The window never takes the focus by itself, a click into the note gives it the keyboard
  Note.PointerEntered.Add(
    procedure(Sender: TObject; E: TWinUIPointerRoutedEventArgs)
    begin
      FPointerOverNote := True;
      ShowActivated := True;
    end);
  Note.PointerExited.Add(
    procedure(Sender: TObject; E: TWinUIPointerRoutedEventArgs)
    begin
      FPointerOverNote := False;
      ShowActivated := FEditing or FKeyboardOpen;
    end);
  Note.GotFocus.Add(
    procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
    begin
      TakeKeyboard;
    end);
end;

{ Transparency }

function TMainWindow.TileBrush: TWinUISolidColorBrush;
begin
  if TransparencySwitch.IsOn then
    Result := FTileGlassBrush
  else
    Result := FTileBrush;
end;

procedure TMainWindow.UpdateGlass;
var
  C: TWinUIColor;
  Tile: TWinUIGlowTile;
begin
  // A brush of its own: the glow tile sees the change and keeps its glow outside
  for Tile in FTiles do
    Tile.Background := TileBrush;
  C := FGlassNotch.Color;
  C.A := Round(255 * (100 - FSettings.TransparencyLevel) / 100);
  FGlassNotch.Color := C;
  TransparencySlider.Visibility := Vis(TransparencySwitch.IsOn);
end;

procedure TMainWindow.SetTransparencyLevel(AValue: Integer);
begin
  AValue := EnsureRange(AValue, 10, 90);
  if AValue <> FSettings.TransparencyLevel then
  begin
    FSettings.TransparencyLevel := AValue;
    Changed;
  end;
  if Round(TransparencySlider.Value) <> AValue then
    TransparencySlider.Value := AValue;
  UpdateGlass;
end;

procedure TMainWindow.TransparencySliderValueChanged(Sender: TObject);
begin
  SetTransparencyLevel(Round(TransparencySlider.Value));
end;

procedure TMainWindow.TransparencySwitchToggled(Sender: TObject);
begin
  // The window is see-through already, so the notch's own colour decides what shows
  if TransparencySwitch.IsOn then
    Notch.Background := FGlassNotch
  else
    Notch.Background := FSolidNotch;
  if FSettings.Transparency <> TransparencySwitch.IsOn then
  begin
    FSettings.Transparency := TransparencySwitch.IsOn;
    Changed;
  end;
  UpdateGlass;
end;

{ Position }

procedure TMainWindow.ApplyEdge;
var
  Side: Boolean;
begin
  Notch.AttachedEdge := TWinUINotchEdge(Ord(FSettings.Edge));
  Side := FSettings.Edge in [TNotchEdge.Left, TNotchEdge.Right];
  PillGrid.Visibility := Vis(not Side);
  PillSide.Visibility := Vis(Side);
  if FLaidOut and (Side = FVertical) then
    Exit;
  FVertical := Side;
  ApplyOrientation;
  // The tiles have other sizes and the Apps grid other columns: built again, sized again
  if FLaidOut then
  begin
    if FEditing then
      UpdateSize
    else
      RebuildWidgets;
  end;
  FLaidOut := True;
end;

function GridLengthOf(AValue: Double; AUnit: GridUnitType): TWinUIGridLength;
begin
  Result.Value := AValue;
  Result.GridUnitType := AUnit;
end;

procedure PlaceInGrid(AElement: TWinUIFrameworkElement; ARow, AColumn: Integer);
var
  Element: IFrameworkElement;
begin
  Element := TWinUIObject.IntfOf(AElement, IFrameworkElement) as IFrameworkElement;
  Grid.SetRow(Element, ARow);
  Grid.SetColumn(Element, AColumn);
end;

procedure TMainWindow.ApplyOrientation;
const
  Orientations: array[Boolean] of TWinUIOrientation = (TWinUIOrientation.Horizontal, TWinUIOrientation.Vertical);
  Labels: array[Boolean] of string = ('Transparency', '');
begin
  // The tiles: a row that scrolls sideways, or a column that scrolls down
  WidgetRow.Orientation := Orientations[FVertical];
  if FVertical then
  begin
    WidgetScroller.HorizontalScrollMode := TWinUIScrollMode.Disabled;
    WidgetScroller.HorizontalScrollBarVisibility := TWinUIScrollBarVisibility.Disabled;
    WidgetScroller.VerticalScrollMode := TWinUIScrollMode.Auto;
    WidgetScroller.VerticalScrollBarVisibility := TWinUIScrollBarVisibility.Auto;
  end
  else
  begin
    WidgetScroller.VerticalScrollMode := TWinUIScrollMode.Disabled;
    WidgetScroller.VerticalScrollBarVisibility := TWinUIScrollBarVisibility.Disabled;
    WidgetScroller.HorizontalScrollMode := TWinUIScrollMode.Auto;
    WidgetScroller.HorizontalScrollBarVisibility := TWinUIScrollBarVisibility.Auto;
  end;
  // The header: the tools go under the clock, without the hotkey hint and the switch's label
  if FVertical then
    PlaceInGrid(HeaderTools, 1, 0)
  else
    PlaceInGrid(HeaderTools, 0, 1);
  HotKeyHint.Visibility := Vis(not FVertical);
  TransparencySwitch.OnContent := Labels[FVertical];
  TransparencySwitch.OffContent := Labels[FVertical];
  // The edit page: the widget list above the details instead of beside them
  if FVertical then
  begin
    EditPage.ColumnDefinitions[0].Width := GridLengthOf(1, GridUnitType.Star);
    EditPage.ColumnDefinitions[1].Width := GridLengthOf(0, GridUnitType.Pixel);
    EditPage.RowDefinitions[0].Height := GridLengthOf(EditVerticalListHeight, GridUnitType.Pixel);
    EditPage.RowDefinitions[1].Height := GridLengthOf(1, GridUnitType.Star);
    EditPage.ColumnSpacing := 0;
    EditPage.RowSpacing := 14;
    PlaceInGrid(DetailPanel, 1, 0);
    PlaceInGrid(SettingsPage, 1, 0);
  end
  else
  begin
    EditPage.ColumnDefinitions[0].Width := GridLengthOf(270, GridUnitType.Pixel);
    EditPage.ColumnDefinitions[1].Width := GridLengthOf(1, GridUnitType.Star);
    EditPage.RowDefinitions[0].Height := GridLengthOf(1, GridUnitType.Star);
    EditPage.RowDefinitions[1].Height := GridLengthOf(0, GridUnitType.Pixel);
    EditPage.ColumnSpacing := 20;
    EditPage.RowSpacing := 0;
    PlaceInGrid(DetailPanel, 0, 1);
    PlaceInGrid(SettingsPage, 0, 1);
  end;
end;

procedure TMainWindow.PlaceWindow;
var
  Display: IDisplayArea;
  Point: PointInt32;
  Pos: TPoint;
begin
  // Test windows keep the place Show gave them, out of the user's way
  if FTestMode then
    Exit;
  if FSettings.MonitorSet then
  begin
    Point.X := FSettings.MonitorX;
    Point.Y := FSettings.MonitorY;
    // A display that is gone falls back to the primary one
    Display := DisplayArea.GetFromPoint(Point, DisplayAreaFallback.Primary);
  end
  else
    Display := DisplayArea.Primary;
  Pos := EdgePosition(FSettings.Edge, FSettings.EdgeOffset, ToRect(Display.OuterBounds), ToRect(Display.WorkArea),
    TSize.Create(AppWindow.Size.Width, AppWindow.Size.Height));
  Point.X := Pos.X;
  Point.Y := Pos.Y;
  AppWindow.Move(Point);
end;

procedure TMainWindow.StartWindowDrag;
begin
  if FTestMode then
    Exit;
  FMovingWindow := True;
  // The window's own move loop, as if its title bar had been pressed
  ReleaseCapture;
  PostMessage(Hwnd, WM_SYSCOMMAND, SC_MOVE or HTCAPTION, 0);
end;

procedure TMainWindow.HeaderBarPointerPressed(Sender: TObject);
begin
  StartWindowDrag;
end;

procedure TMainWindow.PillHostPointerPressed(Sender: TObject);
begin
  StartWindowDrag;
end;

procedure TMainWindow.SnapToEdge;
var
  Pos: PointInt32;
  Size: SizeInt32;
  Center: TPoint;
  Display: IDisplayArea;
  Work: TRect;
  Edge: TNotchEdge;
  Offset: Double;
  Point: PointInt32;
  NotchW, NotchH: Integer;
begin
  Pos := AppWindow.Position;
  Size := AppWindow.Size;
  NotchW := Round(Notch.ActualWidth * Scale);
  NotchH := Round(Notch.ActualHeight * Scale);
  // Where the notch itself was dropped, it sits against one side of the window
  case FSettings.Edge of
    TNotchEdge.Top:
      Center := TPoint.Create(Pos.X + Size.Width div 2, Pos.Y + NotchH div 2);
    TNotchEdge.Bottom:
      Center := TPoint.Create(Pos.X + Size.Width div 2, Pos.Y + Size.Height - NotchH div 2);
    TNotchEdge.Left:
      Center := TPoint.Create(Pos.X + NotchW div 2, Pos.Y + Size.Height div 2);
  else
    Center := TPoint.Create(Pos.X + Size.Width - NotchW div 2, Pos.Y + Size.Height div 2);
  end;
  Point.X := Center.X;
  Point.Y := Center.Y;
  Display := DisplayArea.GetFromPoint(Point, DisplayAreaFallback.Nearest);
  Work := ToRect(Display.WorkArea);
  NearestEdge(Center, Work, Edge, Offset);
  FSettings.Edge := Edge;
  FSettings.EdgeOffset := Offset;
  FSettings.MonitorSet := True;
  FSettings.MonitorX := Work.CenterPoint.X;
  FSettings.MonitorY := Work.CenterPoint.Y;
  Changed;
  ApplyEdge;
  UpdateSize;
end;

procedure TMainWindow.SetEdge(AEdge: TNotchEdge);
begin
  FSettings.Edge := AEdge;
  FSettings.EdgeOffset := 0.5;
  Changed;
  ApplyEdge;
  UpdateSize;
end;

function TMainWindow.HandleMessage(AMsg: Cardinal; AWParam: NativeUInt; ALParam: NativeInt;
  var AResult: NativeInt): Boolean;
begin
  Result := inherited;
  case AMsg of
    WM_EXITSIZEMOVE:
      if FMovingWindow then
      begin
        FMovingWindow := False;
        Later(SnapToEdge);
      end;
    WM_DISPLAYCHANGE, WM_SETTINGCHANGE:
      // A resolution, layout or taskbar change moves the edge the notch hangs from
      Later(UpdateSize);
    WM_MOUSEACTIVATE:
      if FEditing or FPointerOverNote or FKeyboardOpen then
        Later(TakeKeyboard);
  end;
end;

{ Keyboard }

procedure TMainWindow.TakeKeyboard;
begin
  // The hotkey or the click gave this process the right to come to the front
  if FTestMode then
    Exit;
  Activate;
  SetForegroundWindow(Hwnd);
end;

procedure TMainWindow.OpenWithKeyboard;
begin
  FPreviousWindow := GetForegroundWindow;
  FKeyboardOpen := True;
  ShowActivated := True;
  // While it has the keyboard, the pointer leaving does not close it
  Notch.ExpandOnHover := False;
  Notch.Expand;
  TakeKeyboard;
  Later(
    procedure
    begin
      if FKeyboardOpen and (FTiles.Count > 0) and not FEditing then
        FTiles[0].Focus(TWinUIFocusState.Keyboard);
    end);
end;

procedure TMainWindow.CloseKeyboard(ARestoreFocus: Boolean);
begin
  if not FKeyboardOpen then
    Exit;
  FKeyboardOpen := False;
  ShowActivated := FEditing;
  Notch.ExpandOnHover := not FSettings.Pinned and not FEditing;
  if not FSettings.Pinned and not FEditing then
    Notch.Collapse;
  if ARestoreFocus and not FTestMode and IsWindow(FPreviousWindow) then
    SetForegroundWindow(FPreviousWindow);
end;

procedure TMainWindow.NotchKeyDown(Sender: TObject; E: TWinUIKeyRoutedEventArgs);
begin
  if E.Key <> TWinUIVirtualKey.Escape then
    Exit;
  E.Handled := True;
  if FEditing then
    SetEditing(False)
  else
    CloseKeyboard(True);
end;

procedure TMainWindow.ToggleKeyPressed(Sender: TObject);
begin
  if not FSettings.Keyboard then
    Notch.Toggle
  else if FKeyboardOpen then
    CloseKeyboard(True)
  else
    OpenWithKeyboard;
end;

{ Header }

procedure TMainWindow.PinButtonClick(Sender: TObject);
begin
  // Pinned, the panel stays open when the pointer leaves
  FSettings.Pinned := not FSettings.Pinned;
  Changed;
  Notch.ExpandOnHover := not FSettings.Pinned and not FEditing and not FKeyboardOpen;
  if FSettings.Pinned then
  begin
    PinGlyph.Glyph := UnpinGlyphText;
    Notch.Expand;
  end
  else
    PinGlyph.Glyph := PinGlyphText;
end;

procedure TMainWindow.QuitButtonClick(Sender: TObject);
begin
  Close;
end;

{ AI agents }

function TMainWindow.WatchedAgents: TAgentKinds;
var
  Widget: TNotchWidget;
begin
  Result := [];
  for Widget in FSettings.Widgets do
    if Widget.Kind = TWidgetKind.Agents then
      Result := Result + WidgetAgents(Widget);
end;

procedure TMainWindow.NormalizeAgentWidgets;
var
  Widget: TNotchWidget;
  I: Integer;
  Kind, Agent: TAgentKind;
begin
  // The AI agents widget of the first Notch held web links, now it holds the agents it watches
  for Widget in FSettings.Widgets do
    if Widget.Kind = TWidgetKind.Agents then
    begin
      for I := Widget.Items.Count - 1 downto 0 do
        if not AgentKindOf(Widget.Items[I].Target, Kind) then
        begin
          Widget.Items.Delete(I);
          Changed;
        end;
      if Widget.Items.Count = 0 then
        for Agent in FDetectedAgents do
        begin
          Widget.AddItem(AgentNames[Agent], AgentIds[Agent]);
          Changed;
        end;
    end;
end;

procedure TMainWindow.RefreshAgents(ANow: TDateTime);
var
  View: TAgentView;
  Sessions: TArray<TAgentSession>;
  S: TAgentSession;
  Urgent, Worst: TAgentState;
  Xaml: string;
  Previous: TAgentState;
  Alert: Boolean;
  States: TDictionary<string, TAgentState>;
begin
  if FAgentViews.Count = 0 then
  begin
    PillDot.Fill := FGreen;
    PillSideDot.Fill := FGreen;
    Exit;
  end;
  FAgents.Poll(ANow);
  Worst := TAgentState.Idle;
  for View in FAgentViews do
  begin
    Sessions := FAgents.Active(WidgetAgents(View.Widget));
    Urgent := TAgentState.Idle;
    if Length(Sessions) > 0 then
      Urgent := Sessions[0].State;
    Worst := TAgentState(Max(Ord(Worst), Ord(Urgent)));
    Xaml := AgentBodyXaml(Sessions, WidgetAgents(View.Widget), ANow);
    if (Xaml <> View.Shown) and (View.Host <> nil) then
    begin
      View.Shown := Xaml;
      ReplaceFragment(View.Fragment, View.Host, Xaml);
    end;
    // Orange and red breathe, blue says "just finished" and fades to the quiet green
    View.Tile.GlowBrush := FStateBrushes[Urgent];
    View.Tile.IsGlowing := Urgent <> TAgentState.Idle;
    View.Tile.Pulse := Urgent in [TAgentState.Working, TAgentState.NeedsYou];
  end;
  PillDot.Fill := FStateBrushes[Worst];
  PillSideDot.Fill := FStateBrushes[Worst];
  // Open the notch once when a session turns to "needs you" or "finished"
  Alert := False;
  States := TDictionary<string, TAgentState>.Create;
  try
    for S in FAgents.Active(FAgents.Kinds) do
    begin
      States.AddOrSetValue(S.FileName, S.State);
      if (S.State in [TAgentState.NeedsYou, TAgentState.Finished]) and FAgentStates.TryGetValue(S.FileName,
        Previous) and (Previous <> S.State) then
        Alert := True;
    end;
  except
    States.Free;
    raise;
  end;
  FAgentStates.Free;
  FAgentStates := States;
  if Alert and FSettings.AgentAlerts and not Notch.IsExpanded then
  begin
    Notch.Expand;
    FAlertOpened := True;
    FAlertUntil := IncSecond(Now, AlertSeconds);
  end;
  if FDetails <> nil then
    FDetails.Refresh(FAgents.Active(FAgents.Kinds), FUsage.Windows(FAgents.Kinds), FAgents.Kinds, FUsage.Exact,
      FUsage.ExactStatus, ANow);
end;

procedure TMainWindow.AgentTileClick(Sender: TObject; const E: TWinValue);
begin
  // The usage button is in the tile too: its click is not a click on the tile
  if (FDragIndex < 0) and (MilliSecondsBetween(Now, FUsageClicked) > 500) then
    ShowDetails(False);
end;

procedure TMainWindow.ShowDetails(AUsage: Boolean);
begin
  // The usage files are large: they are read once someone wants to see them
  if not FindCmdLineSwitch('smoke-test') then
    FUsage.Start;
  if FDetails = nil then
  begin
    FDetails := TAgentDetailsWindow.Create;
    FDetails.OnClosed := DetailsClosed;
    FDetails.OnExact :=
      procedure
      begin
        SetExactClaudeLimits(True);
      end;
    FDetails.Refresh(FAgents.Active(FAgents.Kinds), FUsage.Windows(FAgents.Kinds), FAgents.Kinds, FUsage.Exact,
      FUsage.ExactStatus, Now);
    FDetails.ShowUsage(AUsage);
    FDetails.Show;
  end
  else
  begin
    FDetails.ShowUsage(AUsage);
    if not FTestMode then
      FDetails.Activate;
  end;
end;

procedure TMainWindow.SetExactClaudeLimits(AValue: Boolean);
begin
  FSettings.ExactClaudeLimits := AValue;
  Changed;
  FUsage.Exact := AValue;
end;

procedure TMainWindow.DetailsClosed(Sender: TObject; E: TWinUIWindowEventArgs);
begin
  FDetails := nil;
end;

procedure TMainWindow.ToggleAgent(AKind: TAgentKind);
var
  I: Integer;
  Kind: TAgentKind;
begin
  if (Selected = nil) or (Selected.Kind <> TWidgetKind.Agents) then
    Exit;
  for I := Selected.Items.Count - 1 downto 0 do
    if AgentKindOf(Selected.Items[I].Target, Kind) and (Kind = AKind) then
    begin
      Selected.Items.Delete(I);
      Changed;
      Exit;
    end;
  Selected.AddItem(AgentNames[AKind], AgentIds[AKind]);
  Changed;
end;

procedure TMainWindow.InstallHooks;
var
  Notes: string;
begin
  Notes := '';
  try
    if TAgentKind.ClaudeCode in FDetectedAgents then
      InstallClaudeHooks(FClaudeSettingsFile, ParamStr(0));
    if TAgentKind.Codex in FDetectedAgents then
      Notes := InstallCodexNotify(FCodexConfigFile, ParamStr(0));
    FHookStatus := 'Installed. Agents started from now on report to the notch.';
    if Notes <> '' then
      FHookStatus := FHookStatus + ' ' + Notes + '.';
  except
    on E: Exception do
      FHookStatus := E.Message;
  end;
  RebuildSettings;
end;

procedure TMainWindow.RemoveHooks;
begin
  try
    RemoveClaudeHooks(FClaudeSettingsFile);
    RemoveCodexNotify(FCodexConfigFile);
    FHookStatus := 'Removed. The notch reads the agents'' transcripts again.';
  except
    on E: Exception do
      FHookStatus := E.Message;
  end;
  RebuildSettings;
end;

{ Edit page }

procedure TMainWindow.EditButtonClick(Sender: TObject);
begin
  SetEditing(not FEditing);
end;

procedure TMainWindow.SetEditing(AValue: Boolean);
begin
  FEditing := AValue;
  // Its text boxes need the keyboard: while editing, a click gives the window the focus
  ShowActivated := AValue or FKeyboardOpen;
  WidgetScroller.Visibility := Vis(not AValue);
  EditPage.Visibility := Vis(AValue);
  Notch.ExpandOnHover := not AValue and not FSettings.Pinned and not FKeyboardOpen;
  if AValue then
  begin
    EditGlyph.Glyph := DoneGlyphText;
    FSelected := Min(FSelected, FSettings.Widgets.Count - 1);
    RebuildEditList;
    RebuildAddList;
    ShowDetail;
    Notch.Expand;
    TakeKeyboard;
  end
  else
  begin
    EditGlyph.Glyph := EditGlyphText;
    RebuildWidgets;
  end;
  UpdateSize;
end;

function TMainWindow.Selected: TNotchWidget;
begin
  if (FSelected >= 0) and (FSelected < FSettings.Widgets.Count) then
    Result := FSettings.Widgets[FSelected]
  else
    Result := nil;
end;

function SmallButtonXaml(const AName: string; AColumn: Integer; const AGlyph, ATip: string;
  AEnabled: Boolean): string;
begin
  // A button that does not apply is hidden but keeps its place, so the rows line up
  Result := Format('<Button x:Name="%0:s" Grid.Column="%1:d" Width="30" Height="30" Padding="0" CornerRadius="8" ' +
    'Background="Transparent" BorderThickness="0" IsEnabled="%2:s" Opacity="%3:d" ToolTipService.ToolTip="%4:s" ' +
    'AutomationProperties.Name="%4:s"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="%5:s" ' +
    'FontSize="11"/></Button>', [AName, AColumn, BoolToStr(AEnabled, True), Ord(AEnabled), ATip, AGlyph]);
end;

procedure TMainWindow.RebuildEditList;
var
  Xaml, Index: string;
  I: Integer;
  Widget: TNotchWidget;
begin
  // The notch's own settings come first, then the widgets
  Xaml := '<StackPanel Spacing="2"' + XamlNs + '>' + Format('<Button x:Name="SN" HorizontalAlignment="Stretch" ' +
    'HorizontalContentAlignment="Left" Padding="8,5" CornerRadius="8" Background="%s" BorderThickness="0">' +
    '<StackPanel Orientation="Horizontal" Spacing="10"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" ' +
    'Glyph="&#xE713;" FontSize="13"/><TextBlock Text="Notch settings" FontSize="13"/></StackPanel></Button>',
    [IfThen(FSelected = SettingsRow, '#2C2C2E', 'Transparent')]);
  for I := 0 to FSettings.Widgets.Count - 1 do
  begin
    Widget := FSettings.Widgets[I];
    Index := I.ToString;
    Xaml := Xaml + Format('<Grid CornerRadius="8" Background="%s"><Grid.ColumnDefinitions>' +
      '<ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/>' +
      '<ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>' +
      '<Button x:Name="S%s" HorizontalAlignment="Stretch" HorizontalContentAlignment="Left" Padding="8,5" ' +
      'Background="Transparent" BorderThickness="0"><StackPanel Orientation="Horizontal" Spacing="10">' +
      '<FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="%s" FontSize="13"/>' +
      '<TextBlock Text="%s" FontSize="13" TextTrimming="CharacterEllipsis" MaxWidth="150"/></StackPanel></Button>',
      [IfThen(I = FSelected, '#2C2C2E', 'Transparent'), Index, KindGlyphs[Widget.Kind], Esc(Widget.Title)]) +
      SmallButtonXaml('L' + Index, 1, '&#xE76B;', 'Move left', I > 0) +
      SmallButtonXaml('R' + Index, 2, '&#xE76C;', 'Move right', I < FSettings.Widgets.Count - 1) +
      SmallButtonXaml('X' + Index, 3, '&#xE711;', 'Remove', True) + '</Grid>';
  end;
  if FSettings.Widgets.Count = 0 then
    Xaml := Xaml + Format('<TextBlock Text="No widgets. Add one below." FontSize="12" Foreground="%s"/>',
      [MutedColor]);
  ReplaceFragment(FListFragment, WidgetListHost, Xaml + '</StackPanel>');
  FListFragment.OnClick('SN', Action('S', SettingsRow));
  for I := 0 to FSettings.Widgets.Count - 1 do
  begin
    Index := I.ToString;
    FListFragment.OnClick('S' + Index, Action('S', I));
    FListFragment.OnClick('L' + Index, Action('L', I));
    FListFragment.OnClick('R' + Index, Action('R', I));
    FListFragment.OnClick('X' + Index, Action('X', I));
  end;
end;

function TMainWindow.Action(AKind: Char; AIndex: Integer): TProc;
begin
  // One closure per button, each with its own index
  Result :=
    procedure
    begin
      case AKind of
        'S':
          SelectWidget(AIndex);
        'L':
          MoveWidget(AIndex, -1);
        'R':
          MoveWidget(AIndex, 1);
        'X':
          RemoveWidget(AIndex);
        'A':
          AddWidget(TWidgetKind(AIndex));
        'D':
          DeleteItem(AIndex);
        'K':
          begin
            ToggleAgent(TAgentKind(AIndex));
            Later(RebuildItems);
          end;
        'E':
          begin
            SetEdge(TNotchEdge(AIndex));
            Later(RebuildSettings);
          end;
        'P':
          begin
            FSettings.ResetPosition;
            SetEdge(TNotchEdge.Top);
            Later(RebuildSettings);
          end;
        'B':
          begin
            FSettings.Keyboard := not FSettings.Keyboard;
            Changed;
          end;
        'N':
          begin
            FSettings.AgentAlerts := not FSettings.AgentAlerts;
            Changed;
          end;
        'W':
          begin
            try
              SetAutoStart(FRunKey, ParamStr(0), not AutoStartEnabled(FRunKey));
            except
              on E: Exception do
                FHookStatus := E.Message;
            end;
            Later(RebuildSettings);
          end;
        'C':
          SetExactClaudeLimits(not FSettings.ExactClaudeLimits);
        'I':
          Later(InstallHooks);
        'U':
          Later(RemoveHooks);
      end;
    end;
end;

procedure TMainWindow.RebuildAddList;
var
  Xaml: string;
  Kind: TWidgetKind;
begin
  Xaml := '<VariableSizedWrapGrid Orientation="Horizontal" ItemWidth="134" ItemHeight="38"' + XamlNs + '>';
  for Kind := Low(TWidgetKind) to High(TWidgetKind) do
    // One music and one focus widget are enough, the others can be there many times
    if not ((Kind in [TWidgetKind.Music, TWidgetKind.Focus]) and FSettings.HasKind(Kind)) then
      Xaml := Xaml + Format('<Button x:Name="A%d" Width="130" Height="34" Padding="8,0" CornerRadius="8" ' +
        'HorizontalContentAlignment="Left" Background="#2C2C2E" BorderThickness="0"><StackPanel ' +
        'Orientation="Horizontal" Spacing="8"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" ' +
        'Glyph="%s" FontSize="12"/><TextBlock Text="%s" FontSize="12"/></StackPanel></Button>',
        [Ord(Kind), KindGlyphs[Kind], Esc(KindTitles[Kind])]);
  ReplaceFragment(FAddFragment, AddListHost, Xaml + '</VariableSizedWrapGrid>');
  for Kind := Low(TWidgetKind) to High(TWidgetKind) do
    FAddFragment.OnClick('A' + Ord(Kind).ToString, Action('A', Ord(Kind)));
end;

procedure TMainWindow.ShowDetail;
var
  Widget: TNotchWidget;
  HasItems: Boolean;
begin
  DetailPanel.Visibility := Vis(FSelected <> SettingsRow);
  SettingsPage.Visibility := Vis(FSelected = SettingsRow);
  if FSelected = SettingsRow then
  begin
    RebuildSettings;
    Exit;
  end;
  Widget := Selected;
  TitleBox.IsEnabled := Widget <> nil;
  if Widget = nil then
  begin
    TitleBox.Text := '';
    DetailHint.Text := 'Pick a widget on the left, or add one.';
    HasItems := False;
  end
  else
  begin
    TitleBox.Text := Widget.Title;
    DetailHint.Text := KindHints[Widget.Kind];
    HasItems := Widget.Kind in [TWidgetKind.Apps, TWidgetKind.Remote, TWidgetKind.Links];
    case Widget.Kind of
      TWidgetKind.Apps:
        EntryTargetBox.PlaceholderText := 'Or the path of any program or file';
      TWidgetKind.Remote:
        EntryTargetBox.PlaceholderText := 'Computer name or IP address';
      TWidgetKind.Links:
        EntryTargetBox.PlaceholderText := 'Web address, file or folder';
    end;
  end;
  EntryForm.Visibility := Vis(HasItems);
  SearchBox.Visibility := Vis(HasItems and (Widget.Kind = TWidgetKind.Apps));
  AppResults.Visibility := SearchBox.Visibility;
  RebuildItems;
  if SearchBox.Visibility = TWinUIVisibility.Visible then
    RebuildResults;
end;

procedure TMainWindow.RebuildItems;
var
  Widget: TNotchWidget;
  Xaml, Icon: string;
  I: Integer;
  Item: TNotchItem;
  Kind: TAgentKind;
begin
  Widget := Selected;
  Xaml := '<StackPanel Spacing="2"' + XamlNs + '>';
  if (Widget <> nil) and (Widget.Kind = TWidgetKind.Agents) then
  begin
    // The agents to watch: the ones found on the PC can be ticked
    for Kind := Low(TAgentKind) to High(TAgentKind) do
      Xaml := Xaml + Format('<CheckBox x:Name="K%d" Content="%s" IsChecked="%s" IsEnabled="%s"/>', [Ord(Kind),
        Esc(AgentNames[Kind] + IfThen(Kind in FDetectedAgents, '', ' (not found on this PC)')),
        BoolToStr(Kind in WidgetAgents(Widget), True), BoolToStr(Kind in FDetectedAgents, True)]);
    ReplaceFragment(FItemsFragment, ItemListHost, Xaml + '</StackPanel>');
    for Kind := Low(TAgentKind) to High(TAgentKind) do
      FItemsFragment.OnClick('K' + Ord(Kind).ToString, Action('K', Ord(Kind)));
    Exit;
  end;
  if Widget <> nil then
    for I := 0 to Widget.Items.Count - 1 do
    begin
      Item := Widget.Items[I];
      if Widget.Kind = TWidgetKind.Apps then
        Icon := IconXaml(TargetIcon(Item.Target, FIconFolder), Item.Name, 20)
      else
        Icon := '';
      Xaml := Xaml + Format('<Grid ColumnSpacing="8"><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/>' +
        '<ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>%s' +
        '<StackPanel Grid.Column="1" Orientation="Horizontal" Spacing="10" VerticalAlignment="Center">' +
        '<TextBlock Text="%s" FontSize="13"/><TextBlock Text="%s" FontSize="11" Foreground="%s" ' +
        'TextTrimming="CharacterEllipsis" MaxWidth="320" VerticalAlignment="Center"/></StackPanel>' +
        '<Button x:Name="D%d" Grid.Column="2" Width="28" Height="28" Padding="0" CornerRadius="8" ' +
        'Background="Transparent" BorderThickness="0" ToolTipService.ToolTip="Remove" ' +
        'AutomationProperties.Name="Remove %1:s"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" ' +
        'Glyph="&#xE711;" FontSize="10"/></Button></Grid>',
        [Icon, Esc(Item.Name), Esc(Item.Target), MutedColor, I]);
    end;
  ReplaceFragment(FItemsFragment, ItemListHost, Xaml + '</StackPanel>');
  if Widget <> nil then
    for I := 0 to Widget.Items.Count - 1 do
      FItemsFragment.OnClick('D' + I.ToString, Action('D', I));
end;

procedure TMainWindow.RebuildResults;
var
  Widget: TNotchWidget;
  App: TShellApp;
  Query, Xaml: string;
  Item: TNotchItem;
  Added: Boolean;
  I: Integer;
begin
  Widget := Selected;
  if Widget = nil then
    Exit;
  Query := Trim(SearchBox.Text);
  FResults := [];
  for App in InstalledApps do
  begin
    if Length(FResults) = MaxResults then
      Break;
    Added := False;
    for Item in Widget.Items do
      Added := Added or SameText(Item.Target, App.ParsingName);
    if not Added and ((Query = '') or ContainsText(App.Name, Query)) then
      FResults := FResults + [App];
  end;
  Xaml := '<VariableSizedWrapGrid Orientation="Horizontal" ItemWidth="78" ItemHeight="78"' + XamlNs + '>';
  for I := 0 to High(FResults) do
    Xaml := Xaml + Format('<Button x:Name="P%d" Width="74" Height="74" Padding="2" Background="Transparent" ' +
      'BorderThickness="0" CornerRadius="12" ToolTipService.ToolTip="Add %s"><StackPanel Spacing="5">%s' +
      '<TextBlock Text="%1:s" FontSize="11" MaxWidth="70" TextTrimming="CharacterEllipsis" ' +
      'HorizontalAlignment="Center"/></StackPanel></Button>',
      [I, Esc(FResults[I].Name), IconXaml(TargetIcon(FResults[I].ParsingName, FIconFolder), FResults[I].Name, 32)]);
  if Length(FResults) = 0 then
    Xaml := Xaml + Format('<TextBlock Text="No app matches." FontSize="12" Foreground="%s"/>', [MutedColor]);
  ReplaceFragment(FResultsFragment, AppResultsHost, Xaml + '</VariableSizedWrapGrid>');
  for I := 0 to High(FResults) do
    FResultsFragment.OnClick('P' + I.ToString, AddAppAction(FResults[I]));
end;

procedure TMainWindow.RebuildSettings;
const
  EdgeTitles: array[TNotchEdge] of string = ('Top', 'Bottom', 'Left', 'Right');
var
  Xaml, Hooks: string;
  Edge: TNotchEdge;
  Level: TWinUISlider;
begin
  if ClaudeHooksInstalled(FClaudeSettingsFile) or CodexNotifyInstalled(FCodexConfigFile) then
    Hooks := 'Installed: the agents tell the notch exactly when they work, wait for you or finish.'
  else
    Hooks := 'Not installed: the notch reads the agents'' transcripts, and guesses "needs you" from a tool ' +
      'that waits a few seconds.';
  if FHookStatus <> '' then
    Hooks := FHookStatus;
  Xaml := Format('<StackPanel Spacing="16"%s>' +
    '<StackPanel Spacing="2"><TextBlock Text="Transparency" FontSize="13" Foreground="%1:s"/>' +
    '<Slider x:Name="Level" Minimum="10" Maximum="90" StepFrequency="1" Value="%2:d" Width="280" ' +
    'HorizontalAlignment="Left" AutomationProperties.Name="Transparency level"/>' +
    '<TextBlock Text="How see-through the notch is when Transparency is on." FontSize="12" Foreground="%1:s"/>' +
    '</StackPanel>' +
    '<CheckBox x:Name="KeyboardBox" IsChecked="%3:s" Content="Keyboard: Ctrl+Alt+N gives the notch the keyboard, ' +
    'Tab and the arrow keys move between tiles, Esc gives the keyboard back"/>' +
    '<CheckBox x:Name="AlertsBox" IsChecked="%4:s" Content="Open the notch when an AI agent finishes or needs me"/>' +
    '<CheckBox x:Name="StartBox" IsChecked="%5:s" Content="Start with Windows"/>' +
    '<CheckBox x:Name="ExactBox" IsChecked="%6:s" Content="Show exact Claude limits (uses your Claude Code login ' +
    'on this PC)"/>' +
    '<StackPanel Spacing="6"><TextBlock Text="Position" FontSize="13" Foreground="%1:s"/>' +
    '<StackPanel Orientation="Horizontal" Spacing="4">', [XamlNs, MutedColor, FSettings.TransparencyLevel,
    BoolToStr(FSettings.Keyboard, True), BoolToStr(FSettings.AgentAlerts, True),
    // What the registry says, also when the entry was removed somewhere else
    BoolToStr(AutoStartEnabled(FRunKey), True), BoolToStr(FSettings.ExactClaudeLimits, True)]);
  for Edge := Low(TNotchEdge) to High(TNotchEdge) do
    Xaml := Xaml + Format('<RadioButton x:Name="E%d" GroupName="Edge" Content="%s" IsChecked="%s" MinWidth="80"/>',
      [Ord(Edge), EdgeTitles[Edge], BoolToStr(Edge = FSettings.Edge, True)]);
  Xaml := Xaml + Format('<Button x:Name="ResetPosition" Content="Reset position" CornerRadius="8"/></StackPanel>' +
    '<TextBlock Text="Or drag the notch by its pill or its header to any edge of any screen." FontSize="12" ' +
    'Foreground="%s"/></StackPanel>' +
    '<StackPanel Spacing="6"><TextBlock Text="Exact AI agent events" FontSize="13" Foreground="%0:s"/>' +
    '<TextBlock Text="%s" FontSize="12" TextWrapping="Wrap"/>' +
    '<TextBlock Text="Installing adds hooks to %s and %s, with a backup of each. Other hooks stay." FontSize="12" ' +
    'Foreground="%0:s" TextWrapping="Wrap"/>' +
    '<StackPanel Orientation="Horizontal" Spacing="8"><Button x:Name="InstallHooks" Content="Install hooks" ' +
    'CornerRadius="8"/><Button x:Name="RemoveHooks" Content="Remove hooks" CornerRadius="8"/></StackPanel>' +
    '</StackPanel></StackPanel>', [MutedColor, Esc(Hooks), Esc(FClaudeSettingsFile), Esc(FCodexConfigFile)]);
  ReplaceFragment(FSettingsFragment, SettingsHost, Xaml);
  Level := TWinUISlider(FSettingsFragment.Find('Level', TWinUISlider));
  Level.ValueChanged.Add(
    procedure(Sender: TObject; E: TWinUIRangeBaseValueChangedEventArgs)
    begin
      SetTransparencyLevel(Round(Level.Value));
    end);
  FSettingsFragment.OnClick('KeyboardBox', Action('B', 0));
  FSettingsFragment.OnClick('AlertsBox', Action('N', 0));
  FSettingsFragment.OnClick('StartBox', Action('W', 0));
  FSettingsFragment.OnClick('ExactBox', Action('C', 0));
  for Edge := Low(TNotchEdge) to High(TNotchEdge) do
    FSettingsFragment.OnClick('E' + Ord(Edge).ToString, Action('E', Ord(Edge)));
  FSettingsFragment.OnClick('ResetPosition', Action('P', 0));
  FSettingsFragment.OnClick('InstallHooks', Action('I', 0));
  FSettingsFragment.OnClick('RemoveHooks', Action('U', 0));
end;

function TMainWindow.AddAppAction(const AApp: TShellApp): TProc;
begin
  Result :=
    procedure
    begin
      AddApp(AApp.Name, AApp.ParsingName);
    end;
end;

procedure TMainWindow.SelectWidget(AIndex: Integer);
begin
  FSelected := AIndex;
  RebuildEditList;
  ShowDetail;
end;

procedure TMainWindow.AddWidget(AKind: TWidgetKind);
var
  Agent: TAgentKind;
begin
  FSettings.Widgets.Add(TNotchWidget.Create(AKind));
  if AKind = TWidgetKind.Agents then
    for Agent in FDetectedAgents do
      FSettings.Widgets.Last.AddItem(AgentNames[Agent], AgentIds[Agent]);
  Changed;
  RebuildAddList;
  SelectWidget(FSettings.Widgets.Count - 1);
end;

procedure TMainWindow.RemoveWidget(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FSettings.Widgets.Count) then
    Exit;
  FSettings.Widgets.Delete(AIndex);
  Changed;
  RebuildAddList;
  SelectWidget(Min(FSelected, FSettings.Widgets.Count - 1));
end;

procedure TMainWindow.MoveWidget(AIndex, ADelta: Integer);
begin
  FSettings.MoveWidget(AIndex, ADelta);
  Changed;
  if FSelected = AIndex then
    FSelected := EnsureRange(AIndex + ADelta, 0, FSettings.Widgets.Count - 1);
  RebuildEditList;
end;

procedure TMainWindow.AddApp(const AName, AParsingName: string);
begin
  if Selected = nil then
    Exit;
  Selected.AddItem(AName, AParsingName);
  Changed;
  RebuildItems;
  RebuildResults;
end;

procedure TMainWindow.DeleteItem(AIndex: Integer);
begin
  if (Selected = nil) or (AIndex >= Selected.Items.Count) then
    Exit;
  Selected.Items.Delete(AIndex);
  Changed;
  RebuildItems;
  if Selected.Kind = TWidgetKind.Apps then
    RebuildResults;
end;

procedure TMainWindow.AddEntryButtonClick(Sender: TObject);
var
  Name, Target: string;
begin
  Name := Trim(EntryNameBox.Text);
  Target := Trim(EntryTargetBox.Text);
  if (Selected = nil) or (Target = '') then
    Exit;
  // example.com is a web page, not an app
  if (Selected.Kind = TWidgetKind.Links) and not IsPlainTarget(Target) then
    Target := 'https://' + Target;
  if Name = '' then
    if Selected.Kind = TWidgetKind.Apps then
      Name := ChangeFileExt(ExtractFileName(Target), '')
    else
      Name := Target;
  Selected.AddItem(Name, Target);
  Changed;
  EntryNameBox.Text := '';
  EntryTargetBox.Text := '';
  RebuildItems;
end;

procedure TMainWindow.TitleBoxTextChanged(Sender: TObject);
begin
  if (Selected = nil) or (Selected.Title = TitleBox.Text) then
    Exit;
  Selected.Title := TitleBox.Text;
  Changed;
  RebuildEditList;
end;

procedure TMainWindow.SearchBoxTextChanged(Sender: TObject);
begin
  RebuildResults;
end;

{ Smoke test: Notch.exe -smoke-test <result file> }

type
  // Windows.Storage.Streams.IBufferByteAccess: the bytes of a WinRT buffer
  IBufferByteAccess = interface(IUnknown)
    ['{905A0FEF-BC53-11DF-8C49-001E4FC686DA}']
    function Buffer(out AValue: PByte): HRESULT; stdcall;
  end;

// A picture of the notch next to the result file, to see the look without a window on the screen
procedure TMainWindow.Snapshot(const AFileName: string; AElement: TWinUIUIElement);
var
  Target: TWinUIRenderTargetBitmap;
begin
  if AElement = nil then
    AElement := Notch;
  Inc(FSnapshotsPending);
  Target := TWinUIRenderTargetBitmap.Create(Self);
  Target.RenderAsync(AElement).Completed := TAsyncActionCompletedHandler.Create(
    procedure(AAction: IAsyncAction; AStatus: AsyncStatus)
    var
      Width, Height: Integer;
    begin
      if AStatus <> AsyncStatus.Completed then
      begin
        FSnapshotError := 'The notch did not render';
        Dec(FSnapshotsPending);
        Exit;
      end;
      Width := Target.PixelWidth;
      Height := Target.PixelHeight;
      Target.GetPixelsAsync.Completed := TAsyncOperationCompletedHandler_IBuffer.Create(
        procedure(AOperation: IAsyncOperation_IBuffer; AStatus: AsyncStatus)
        var
          Bytes: PByte;
        begin
          try
            if (AStatus = AsyncStatus.Completed) and
              Succeeded((AOperation.GetResults as IBufferByteAccess).Buffer(Bytes)) then
              SavePixelsPng(Bytes, Width, Height, AFileName);
          except
            on E: Exception do
              FSnapshotError := E.Message;
          end;
          Dec(FSnapshotsPending);
        end);
    end);
end;

// Runs Notch.exe --agent-event like an agent's hook would, with its data in AFolder
function RunAgentEvent(const AFolder, AArguments: string): Boolean;
var
  Startup: TStartupInfo;
  Process: TProcessInformation;
  CommandLine: string;
begin
  SetEnvironmentVariable('NOTCH_DATA', PChar(AFolder));
  try
    Startup := Default(TStartupInfo);
    Startup.cb := SizeOf(Startup);
    CommandLine := '"' + ParamStr(0) + '" ' + AArguments;
    UniqueString(CommandLine);
    Result := CreateProcess(nil, PChar(CommandLine), nil, nil, False, CREATE_NO_WINDOW, nil, nil, Startup, Process);
    if Result then
    begin
      Result := WaitForSingleObject(Process.hProcess, 10000) = WAIT_OBJECT_0;
      CloseHandle(Process.hProcess);
      CloseHandle(Process.hThread);
    end;
  finally
    SetEnvironmentVariable('NOTCH_DATA', nil);
  end;
end;

procedure TMainWindow.SmokeStep;

  procedure Check(ACondition: Boolean; const AMessage: string);
  begin
    if not ACondition then
      raise Exception.Create(AMessage);
  end;

  function Kinds(ASettings: TNotchSettings): string;
  var
    Widget: TNotchWidget;
  begin
    Result := '';
    for Widget in ASettings.Widgets do
      Result := Result + KindNames[Widget.Kind] + ' ';
    Result := Trim(Result);
  end;

  // One object can have a wrapper per owner: compare the objects themselves
  function SameObject(A, B: TWinUIObject): Boolean;
  begin
    Result := (A <> nil) and (B <> nil) and ((A.WinRTObject as IUnknown) = (B.WinRTObject as IUnknown));
  end;

  function NotchAlpha: Byte;
  begin
    Result := (Notch.Background as TWinUISolidColorBrush).Color.A;
  end;

var
  Reloaded: TNotchSettings;
  Count: Integer;
  Bad, Failure, Transcript: string;
  View: TAgentView;
  Registry: TRegistry;
begin
  Inc(FSmokeStep);
  try
    case FSmokeStep of
      1:
        begin
          Failure := RunUnitTests(TPath.Combine(FDataFolder, 'unit'));
          Check(Failure = '', 'Unit test: ' + Failure);
          Check(not Notch.IsExpanded and (Notch.ActualWidth <= 221), 'The notch does not start as a pill');
          Check(PillClock.Text = FormatDateTime('hh:nn', Now), 'The pill shows ' + PillClock.Text);
          Check(Length(InstalledApps) > 0, 'No installed apps found in the AppsFolder');
          Check(Kinds(FSettings) = 'apps agents calendar music focus', 'Default widgets: ' + Kinds(FSettings));
          Check(FSettings.Widgets[0].Items.Count > 0, 'The default Apps widget found no common app');
          Check(WatchedAgents = [TAgentKind.ClaudeCode, TAgentKind.Codex], 'The agents widget does not watch both');
          Check(WidgetRow.Children.Count = 5, Format('%d tiles for 5 widgets', [WidgetRow.Children.Count]));
          Check(TFile.Exists(FSettings.FileName), 'The default settings were not saved');
          ToggleKeyPressed(nil);
        end;
      3:
        begin
          Check(Notch.IsExpanded and (Abs(Notch.ActualWidth - Notch.ExpandedWidth) <= 1),
            Format('The hotkey did not open the panel (%.0f wide)', [Notch.ActualWidth]));
          Check(Notch.ExpandedWidth = Min(Max(FRowLength + PanelPadding, MinPanelWidth), WorkAreaWidth - WindowMarginX),
            'The panel width does not follow the widgets');
          Check(Width = Round(Notch.ExpandedWidth) + WindowMarginX, 'The window does not fit the panel');
          // A Claude Code session that asks for an edit: working, then waiting for approval
          Transcript := TPath.Combine(FDataFolder, 'claude\projects\C--Work-Demo\session.jsonl');
          ForceDirectories(ExtractFileDir(Transcript));
          TFile.WriteAllBytes(Transcript, TEncoding.UTF8.GetBytes(
            '{"type":"user","cwd":"C:\\Work\\Demo","message":{"role":"user","content":"Fix it"}}' + #10 +
            '{"type":"assistant","message":{"role":"assistant","stop_reason":"tool_use","content":[{"type":' +
            '"tool_use","name":"Edit","input":{"file_path":"C:\\Work\\Demo\\Main.pas"}}]}}' + #10));
          FAgents.Poll(IncSecond(Now, 10));
          RefreshAgents(Now);
          View := FAgentViews[0];
          Check(View.Shown.Contains('Working') and View.Shown.Contains('Demo') and View.Shown.Contains('Editing Main.pas'),
            'The agents tile does not show the working session');
          Check(View.Tile.Pulse and (PillDot.Fill = FStateBrushes[TAgentState.Working]), 'Working does not glow orange');
          RefreshAgents(IncSecond(Now, NeedsYouSeconds + 1));
          Check(View.Shown.Contains('Needs you') and (PillDot.Fill = FStateBrushes[TAgentState.NeedsYou]),
            'A waiting session does not show "Needs you" in red');
          // A hook event through Notch.exe --agent-event, as Codex sends it
          Check(RunAgentEvent(FDataFolder, '--agent-event codex "{\"type\":\"agent-turn-complete\",' +
            '\"thread-id\":\"x1\",\"cwd\":\"D:\\\\Apps\\\\Mail\",\"last-assistant-message\":\"Sent\"}"'),
            'Notch.exe --agent-event did not run');
          RefreshAgents(Now);
          Check(View.Shown.Contains('Mail') and (Length(TDirectory.GetFiles(FAgents.EventsFolder)) = 0),
            'The agent event from the command line did not arrive');
          ToggleFocus;
          // Edit mode: add, move and remove widgets, add items
          EditButtonClick(nil);
          Check((EditPage.Visibility = TWinUIVisibility.Visible) and ShowActivated and not Notch.ExpandOnHover,
            'Edit mode did not open');
          AddWidget(TWidgetKind.Notes);
          Check(FSelected = 5, 'The new widget is not selected');
          MoveWidget(5, -1);
          RemoveWidget(2);
          AddWidget(TWidgetKind.Remote);
          EntryNameBox.Text := 'Build server';
          EntryTargetBox.Text := 'build01';
          AddEntryButtonClick(nil);
          Check(Kinds(FSettings) = 'apps agents music notes focus remote', 'Widgets after editing: ' + Kinds(FSettings));
          Check((Selected.Items.Count = 1) and (Selected.Items[0].Target = 'build01'), 'The host was not added');
          SelectWidget(1);
          Count := FSettings.Widgets[1].Items.Count;
          Action('K', Ord(TAgentKind.Codex))();
          Check(WidgetAgents(FSettings.Widgets[1]) = [TAgentKind.ClaudeCode], 'Unticking Codex');
          Action('K', Ord(TAgentKind.Codex))();
          Check(FSettings.Widgets[1].Items.Count = Count, 'Ticking Codex again');
          SelectWidget(0);
          Count := Selected.Items.Count;
          SearchBox.Text := '';
          RebuildResults;
          Check(Length(FResults) > 0, 'The app picker shows no apps');
          AddApp(FResults[0].Name, FResults[0].ParsingName);
          Check(Selected.Items.Count = Count + 1, 'The picked app was not added');
          Check(Length(TDirectory.GetFiles(FIconFolder, '*.png')) > 0, 'No app icon was written');
          SelectWidget(SettingsRow);
          Check((SettingsPage.Visibility = TWinUIVisibility.Visible) and (FSettingsFragment <> nil) and
            (FSettingsFragment.Find('InstallHooks', TWinUIButton) <> nil), 'The settings page did not open');
        end;
      4:
        Snapshot(ChangeFileExt(ParamStr(2), '-settings.png'));
      5:
        begin
          Check(FFocusRunning, 'The focus timer does not run');
          Check(Notch.ExpandedHeight = EditHeight, 'The edit page did not make the panel taller');
          EditButtonClick(nil);
          Check(not FEditing and not ShowActivated and Notch.ExpandOnHover, 'Edit mode did not close');
          Check(WidgetRow.Children.Count = 6, Format('%d tiles for 6 widgets', [WidgetRow.Children.Count]));
          Check((FFocusClock <> nil) and (FFocusClock.Text <> '25:00'), 'The rebuilt focus widget lost the timer');
          ResetFocus;
          Check(FFocusClock.Text = '25:00', 'Reset did not reset the timer');
          // Drag the first tile past the second one
          FDragIndex := 0;
          FDragActive := True;
          DragTile(FTileSizes[0] + TileGap + FTileSizes[1] / 2 + 1);
          Check((FDragTarget = 1) and (Round(FTiles[1].Translation.X) = -(FTileSizes[0] + TileGap)),
            'The tile next to a dragged one does not make room');
          EndTileDrag(True);
          Check(Kinds(FSettings) = 'agents apps music notes focus remote', 'Dragging a tile: ' + Kinds(FSettings));
          FSettings.Widgets[3].Text := 'First line'#13#10'Second "line" & more';
          FSettings.Save;
          Reloaded := TNotchSettings.Create(FSettings.FileName);
          try
            Check(Reloaded.Load, 'The saved settings do not load');
            Check(Kinds(Reloaded) = Kinds(FSettings), 'Reloaded widgets: ' + Kinds(Reloaded));
            Check(Reloaded.Widgets[1].Items.Count = FSettings.Widgets[1].Items.Count, 'Reloaded apps differ');
            Check(Reloaded.Widgets[3].Text = FSettings.Widgets[3].Text, 'The note did not survive a reload');
            Check(Reloaded.Widgets[5].Items[0].Name = 'Build server', 'The host did not survive a reload');
          finally
            Reloaded.Free;
          end;
          Bad := TPath.Combine(FDataFolder, 'broken.json');
          TFile.WriteAllText(Bad, '{"widgets": [ {"kind": ');
          Reloaded := TNotchSettings.Create(Bad);
          try
            Check(not Reloaded.Load and (Reloaded.Widgets.Count = 0), 'A broken settings file was not refused');
          finally
            Reloaded.Free;
          end;
        end;
      7:
        begin
          Check(WidgetRow.Children.Count = 6, 'The panel was not rebuilt after the drag');
          Snapshot(ChangeFileExt(ParamStr(2), '-panel.png'));
        end;
      8, 12, 16, 19, 22, 26, 29:
        // Rendering takes its time: wait for the pictures
        if FSnapshotsPending > 0 then
          Dec(FSmokeStep);
      9:
        begin
          Check(FSnapshotError = '', 'Snapshot: ' + FSnapshotError);
          Check(FIconShown, 'The app icons of the panel did not load');
          Check(Media.Connected, 'The media session did not connect');
          PinButtonClick(nil);
          Check(not Notch.ExpandOnHover and FSettings.Pinned, 'Pin did not keep the panel open');
          PinButtonClick(nil);
          // Transparency and its level
          TransparencySwitch.IsOn := True;
          Check((NotchAlpha < 255) and (TransparencySlider.Visibility = TWinUIVisibility.Visible),
            'Transparency did not make the notch see-through');
          SetTransparencyLevel(50);
          Check((NotchAlpha = 128) and (FSettings.TransparencyLevel = 50), Format('Level 50 gives alpha %d',
            [NotchAlpha]));
          TransparencySwitch.IsOn := False;
          Check(NotchAlpha = 255, 'Transparency off did not make the notch solid again');
          // Keyboard: the hotkey keeps the panel open until Esc
          FSettings.Keyboard := True;
          ToggleKeyPressed(nil);
          Check(FKeyboardOpen and ShowActivated and not Notch.ExpandOnHover and Notch.IsExpanded,
            'The hotkey did not give the notch the keyboard');
          CloseKeyboard(True);
          Check(not FKeyboardOpen and not ShowActivated and Notch.ExpandOnHover, 'Esc did not end the keyboard visit');
          FSettings.Keyboard := False;
          // The left edge: the panel stands upright, one tile wide
          SetEdge(TNotchEdge.Left);
          Check((Notch.AttachedEdge = TWinUINotchEdge.Left) and (PillSide.Visibility = TWinUIVisibility.Visible) and
            (Notch.HorizontalAlignment = TWinUIHorizontalAlignment.Left), 'The left edge was not applied');
          Check(FVertical and (WidgetRow.Orientation = TWinUIOrientation.Vertical) and
            (Grid.GetRow(TWinUIObject.IntfOf(HeaderTools, IFrameworkElement) as IFrameworkElement) = 1),
            'The panel did not turn upright');
          Check((Notch.ExpandedWidth = VerticalTileWidth + PanelPadding) and
            (Notch.ExpandedHeight = Min(Max(VerticalChrome + FRowLength, MinVerticalHeight),
            WorkAreaHeight - WindowMarginY - 16)), Format('Upright panel %.0f x %.0f',
            [Notch.ExpandedWidth, Notch.ExpandedHeight]));
          Check((FTiles[0].Width = VerticalTileWidth) and (FTiles[0].Height = FTileSizes[0]) and
            (FTileSizes[0] = WidgetHeight(FSettings.Widgets[0])), 'The tiles are not one column');
          Check(Width = Round(Notch.ExpandedWidth) + WindowMarginX, 'The window does not fit the upright panel');
          Notch.Expand;
        end;
      11:
        begin
          Check(Notch.IsExpanded and (Abs(Notch.ActualWidth - Notch.ExpandedWidth) <= 1),
            Format('The upright panel is %.0f wide', [Notch.ActualWidth]));
          // A tile dragged down past the next one
          FDragIndex := 0;
          FDragActive := True;
          DragTile(FTileSizes[0] + TileGap + FTileSizes[1] / 2 + 1);
          Check((FDragTarget = 1) and (Round(FTiles[1].Translation.Y) = -(FTileSizes[0] + TileGap)) and
            (Round(FTiles[1].Translation.X) = 0), 'Dragging down the upright column');
          EndTileDrag(False);
          // The edit page: list above the details
          SetEditing(True);
          Check((Notch.ExpandedWidth = EditVerticalWidth) and
            (Grid.GetRow(TWinUIObject.IntfOf(DetailPanel, IFrameworkElement) as IFrameworkElement) = 1),
            'The edit page did not stand upright');
          SetEditing(False);
          Check(Notch.ExpandedWidth = VerticalTileWidth + PanelPadding, 'Leaving the upright edit page');
          Snapshot(ChangeFileExt(ParamStr(2), '-vertical.png'));
        end;
      13:
        Notch.Collapse;
      15:
        begin
          Check(FSnapshotError = '', 'Snapshot: ' + FSnapshotError);
          Check(not Notch.IsExpanded and (Notch.ActualWidth <= 37) and (Notch.ActualHeight >= 219),
            Format('The pill on the left edge is %.0f x %.0f', [Notch.ActualWidth, Notch.ActualHeight]));
          Snapshot(ChangeFileExt(ParamStr(2), '-left.png'));
        end;
      17:
        begin
          Check(FSnapshotError = '', 'Snapshot: ' + FSnapshotError);
          // From side to side it stays upright, back on top it is wide again with no sizes left over
          SetEdge(TNotchEdge.Right);
          Check(FVertical and (Notch.HorizontalAlignment = TWinUIHorizontalAlignment.Right), 'The right edge');
          SetEdge(TNotchEdge.Top);
          Check(not FVertical and (WidgetRow.Orientation = TWinUIOrientation.Horizontal) and
            (Notch.ExpandedHeight = PanelHeight) and (FTiles[0].Width = WidgetWidth(FSettings.Widgets[0])) and
            IsNan(FTiles[0].Height) and (Grid.GetColumn(TWinUIObject.IntfOf(HeaderTools, IFrameworkElement) as
            IFrameworkElement) = 1), 'Back on the top edge the panel is not wide again');
          SetEdge(TNotchEdge.Bottom);
          Check(not FVertical and (Notch.VerticalAlignment = TWinUIVerticalAlignment.Bottom), 'The bottom edge');
          SetEdge(TNotchEdge.Top);
          // Start with Windows, on a test key
          SetAutoStart(FRunKey, ParamStr(0), True);
          Check(AutoStartEnabled(FRunKey), 'Start with Windows was not turned on');
          SetAutoStart(FRunKey, ParamStr(0), False);
          Check(not AutoStartEnabled(FRunKey), 'Start with Windows was not turned off');
          Registry := TRegistry.Create;
          try
            Registry.RootKey := HKEY_CURRENT_USER;
            Registry.DeleteKey('Software\RADWinUI Notch Test');
          finally
            Registry.Free;
          end;
          // The calendar tile's click finds the taskbar clock. The test only looks, it never clicks
          Check(TaskbarClockFound, 'The clock of the taskbar was not found');
          // Usage: Codex reports its limits, Claude Code's tokens are added up
          Transcript := TPath.Combine(FDataFolder, 'codex\sessions\' + FormatDateTime('yyyy"\"mm"\"dd', Date) +
            '\rollout-test.jsonl');
          ForceDirectories(ExtractFileDir(Transcript));
          TFile.WriteAllBytes(Transcript, TEncoding.UTF8.GetBytes('{"timestamp":"' + DateToISO8601(Now, False) +
            '","type":"event_msg","payload":{"type":' +
            '"token_count","rate_limits":{"primary":{"used_percent":42.0,"window_minutes":300,"resets_at":' +
            IntToStr(DateTimeToUnix(IncHour(Now, 2), False)) + '},"secondary":{"used_percent":7.5,' +
            '"window_minutes":10080,"resets_at":' + IntToStr(DateTimeToUnix(IncDay(Now, 3), False)) + '}}}}' + #10));
          // Written later but reported earlier: the report's own time decides
          Sleep(20);
          TFile.WriteAllBytes(TPath.Combine(ExtractFileDir(Transcript), 'rollout-older.jsonl'), TEncoding.UTF8.GetBytes(
            '{"timestamp":"' + DateToISO8601(IncHour(Now, -1), False) + '","type":"event_msg","payload":{"type":' +
            '"token_count","rate_limits":{"primary":{"used_percent":99.0,"window_minutes":300,"resets_at":' +
            IntToStr(DateTimeToUnix(IncHour(Now, 2), False)) + '}}}}' + #10));
          Transcript := TPath.Combine(FDataFolder, 'claude\projects\C--Work-Demo\usage.jsonl');
          TFile.WriteAllBytes(Transcript, TEncoding.UTF8.GetBytes(Format(
            '{"type":"assistant","timestamp":"%0:s","message":{"id":"m1","usage":{"input_tokens":1000,' +
            '"output_tokens":500,"cache_read_input_tokens":90000}}}' + #10 +
            '{"type":"assistant","timestamp":"%0:s","message":{"id":"m1","usage":{"input_tokens":1000,' +
            '"output_tokens":500}}}' + #10, [DateToISO8601(IncMinute(Now, -30), False)])));
          FUsage.Update;
          Check(Length(FUsage.Windows([TAgentKind.Codex])) = 2, 'The Codex limits were not read');
          Check(FUsage.Windows([TAgentKind.Codex])[0].Summary(Now).StartsWith('42 % used, resets in 1 h'),
            'Codex usage: ' + FUsage.Windows([TAgentKind.Codex])[0].Summary(Now));
          Check((FUsage.Windows([TAgentKind.ClaudeCode])[0].Tokens = 1500) and
            FUsage.Windows([TAgentKind.ClaudeCode])[0].Estimate, 'Claude usage: ' +
            FUsage.Windows([TAgentKind.ClaudeCode])[0].Summary(Now));
          // The usage button opens the details window on its usage page
          ShowDetails(True);
          Check((FDetails <> nil) and FDetails.UsageShown, 'The usage page did not open');
          FDetails.Root.RequestedTheme := TWinUIElementTheme.Light;
          // Mica does not show in a picture: a plain page colour behind it
          TWinUIGrid(FDetails.Root).Background := MakeBrush($FFF3F3F3);
        end;
      18:
        begin
          Check(FDetails.UsageShown, 'The usage page did not stay open once the window was loaded');
          Snapshot(ChangeFileExt(ParamStr(2), '-details-light.png'), FDetails.Root);
        end;
      20:
        begin
          FDetails.ShowUsage(False);
          FDetails.Root.RequestedTheme := TWinUIElementTheme.Dark;
          TWinUIGrid(FDetails.Root).Background := MakeBrush($FF202020);
        end;
      21:
        Snapshot(ChangeFileExt(ParamStr(2), '-details-dark.png'), FDetails.Root);
      23:
        begin
          Check(FSnapshotError = '', 'Snapshot: ' + FSnapshotError);
          Check(not FDetails.UsageShown, 'The sessions page did not come back');
          FDetails.Close;
          // See-through tiles over a busy background, for the pictures
          FBackdrop := TFragment.Create('<Grid' + XamlNs + '><Grid.Background><LinearGradientBrush StartPoint="0,0" ' +
            'EndPoint="1,1"><GradientStop Color="#FF1E63E9" Offset="0"/><GradientStop Color="#FFF5A623" ' +
            'Offset="0.45"/><GradientStop Color="#FFF2F5FF" Offset="0.7"/><GradientStop Color="#FF2BB673" ' +
            'Offset="1"/></LinearGradientBrush></Grid.Background>' +
            '<TextBlock Text="Busy wallpaper behind the notch" FontSize="40" Foreground="#80000000" ' +
            'HorizontalAlignment="Center" VerticalAlignment="Center"/></Grid>');
          TWinUIPanel(Content).Children.Insert(0, FBackdrop.Root);
          TransparencySwitch.IsOn := True;
          SetTransparencyLevel(40);
          Notch.Expand;
        end;
      24:
        begin
          Check((SameObject(FTiles[0].Background, FTileGlassBrush)) and (FTileGlassBrush.Color.A < 255),
            'With Transparency on the tiles are not see-through');
        end;
      25:
        Snapshot(ChangeFileExt(ParamStr(2), '-glass.png'), Content);
      27:
        SetEdge(TNotchEdge.Left);
      28:
        begin
          Check(SameObject(FTiles[0].Background, FTileGlassBrush), 'The upright tiles are not see-through');
          Snapshot(ChangeFileExt(ParamStr(2), '-glass-vertical.png'), Content);
        end;
      30:
        begin
          Check(FSnapshotError = '', 'Snapshot: ' + FSnapshotError);
          SetEdge(TNotchEdge.Top);
          TransparencySwitch.IsOn := False;
          Check(SameObject(FTiles[0].Background, FTileBrush), 'With Transparency off the tiles are not solid again');
          TWinUIPanel(Content).Children.Remove(FBackdrop.Root);
          TFile.WriteAllText(ParamStr(2), Format('PASS: unit tests (agents, hooks, placement, usage), pill, default ' +
            'widgets, %d installed apps, hotkey, panel size, agents tile (working, needs you, --agent-event), ' +
            'edit mode (add, move, remove widgets and items, agents to watch, app picker, icons, settings page), ' +
            'tile drag, settings save and reload, broken settings, focus timer, media session, pin, transparency ' +
            'level, keyboard, upright panel on the left (sizes, drag, edit page), right, bottom and back to top, ' +
            'start with Windows, taskbar clock, usage limits, details window light and dark, see-through tiles',
            [Length(InstalledApps)]));
          Close;
        end;
    end;
  except
    on E: Exception do
    begin
      TFile.WriteAllText(ParamStr(2), Format('FAIL at step %d: %s (%s)', [FSmokeStep, E.Message, E.ClassName]));
      Close;
    end;
  end;
end;

end.
