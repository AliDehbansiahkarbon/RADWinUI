unit RADWinUI.Forms;

{
  Windows and the application object of the developer-facing API.

    type
      TMainWindow = class(TWinUIWindow)
      public
        constructor Create; override;
      end;

    begin
      TWinUIApp.Run(TMainWindow);
    end.

  TWinUIWindow owns every wrapper created for its content and is freed by the
  application after it closes. Sizes are device-independent pixels.
}

interface

{$SCOPEDENUMS ON}

uses
  System.SysUtils,
  RADWinUI.Interop.Core,
  RADWinUI.Abi,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Runtime.Application;

type
  TWinUIBackdrop = (None, Mica, MicaAlt, Acrylic);

  // Same as System.Classes.TNotifyEvent (assignment-compatible), declared here so a
  // WinUI app does not link System.Classes and System.Rtti (about 1 MB).
  TNotifyEvent = procedure(Sender: TObject) of object;

  TWinUIWindow = class;
  TWinUIWindowClass = class of TWinUIWindow;

  /// <summary>A XAML event names a handler the window class does not publish.</summary>
  EWinUIBindError = class(Exception);

  TWinUIWindow = class(TWinUICustomWindow)
  strict private
    FBackdrop: TWinUIBackdrop;
    FTransparency: Boolean;
    FSystemBackdrop: TWinUISystemBackdrop;
    FOpaqueBrush: TWinUISolidColorBrush;
    FPlainBackground: TWinUIBrush;
    FThemeHooked: Boolean;
    FMinWidth: Integer;
    FMinHeight: Integer;
    FClosedToken: EventRegistrationToken;
    class var FWindows: TArray<TWinUIWindow>;
    class function IsAlive(AWindow: TWinUIWindow): Boolean; static;
    function Scale: Double;
    function Presenter: TWinUIOverlappedPresenter;
    function GetClientWidth: Integer;
    function GetClientHeight: Integer;
    procedure SetClientWidth(AValue: Integer);
    procedure SetClientHeight(AValue: Integer);
    procedure SetMinWidth(AValue: Integer);
    procedure SetMinHeight(AValue: Integer);
    procedure SetBackdrop(AValue: TWinUIBackdrop);
    procedure SetTransparency(AValue: Boolean);
    procedure ApplyBackdrop;
    procedure UpdateOpaqueFill;
    procedure ExplainTransparency(ASwitch: TWinUIToggleSwitch);
    procedure ResizeClientArea(AWidth, AHeight: Integer);
    function GetDataContext: TWinValue;
    procedure SetDataContext(const AValue: TWinValue);
  protected
    procedure DetachEvents; override;
  public
    /// <summary>Creates the Microsoft.UI.Xaml.Window. Override to build the content.</summary>
    constructor Create; virtual;
    destructor Destroy; override;
    /// <summary>Shows and activates the window.</summary>
    procedure Show; virtual;
    /// <summary>Frees every window still alive. TWinUIApp calls this before WinRT shuts down.</summary>
    class procedure FreeAll;
    /// <summary>Centers the window on the work area of its display.</summary>
    procedure Center;
    /// <summary>The element named AName (x:Name) in the content, wrapped, nil when missing.</summary>
    function FindElement<T: TWinUIObject>(const AName: string): T;
    /// <summary>Loads a XAML string, sets it as the content and returns its root.</summary>
    function LoadContent(const AXaml: string): TWinUIFrameworkElement;
    /// <summary>
    ///   True when Windows draws translucent backdrops right now: Transparency
    ///   effects is on and Energy saver is off. When False, Mica and Acrylic show
    ///   a solid colour whatever the app asks for.
    /// </summary>
    class function SystemTransparency: Boolean; static;
    /// <summary>
    ///   Makes ASwitch turn Transparency on and off, and explains in its tooltip
    ///   when Windows itself has transparency off.
    /// </summary>
    procedure BindTransparencySwitch(ASwitch: TWinUIToggleSwitch);
  protected
    /// <summary>
    ///   The published method AName of this window, for event wiring by
    ///   XamlCodeGen, raises EWinUIBindError when there is none.
    /// </summary>
    function PublishedMethod(const AName: string): TMethod;
    /// <summary>A listener that calls the (Sender: TObject) published method AName.</summary>
    function NotifyProc<T>(const AName: string): TWinUIEventProc<T>;
  public
    property Width: Integer read GetClientWidth write SetClientWidth;
    property Height: Integer read GetClientHeight write SetClientHeight;
    property MinWidth: Integer read FMinWidth write SetMinWidth;
    property MinHeight: Integer read FMinHeight write SetMinHeight;
    property Backdrop: TWinUIBackdrop read FBackdrop write SetBackdrop;
    /// <summary>
    ///   True (the default) shows the Backdrop, False paints the content's root
    ///   panel with the solid page colour of its theme instead. Backdrop keeps its value.
    /// </summary>
    property Transparency: Boolean read FTransparency write SetTransparency;
    /// <summary>
    ///   The DataContext of the content, for {Binding} in the window's XAML:
    ///   DataContext := FViewModel (a TWinUIBindableObject).
    /// </summary>
    property DataContext: TWinValue read GetDataContext write SetDataContext;
  end;

  /// <summary>Repeating timer on the UI thread, like the VCL TTimer. Interval in milliseconds.</summary>
  TWinUITimer = class
  strict private
    FTimer: IDispatcherQueueTimer;
    FToken: EventRegistrationToken;
    FOnTimer: TNotifyEvent;
    function GetInterval: Cardinal;
    procedure SetInterval(AValue: Cardinal);
    function GetEnabled: Boolean;
    procedure SetEnabled(AValue: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    property Interval: Cardinal read GetInterval write SetInterval;
    property Enabled: Boolean read GetEnabled write SetEnabled;
    property OnTimer: TNotifyEvent read FOnTimer write FOnTimer;
  end;

  TWinUIExceptionEvent = procedure(Sender: TObject; E: Exception) of object;

  /// <summary>Application that creates and shows a main window class on launch.</summary>
  TWinUIApp = class(TWinUIApplication)
  strict private
    class var FMainWindowClass: TWinUIWindowClass;
    class var FInstance: TWinUIApp;
    class var FOnException: TWinUIExceptionEvent;
    class var FConverterNames: TArray<string>;
    class var FConverters: TArray<IInspectable>;
    procedure AddResource(const AName: string; const AValue: IInspectable);
  protected
    procedure OnLaunched(const AArgs: ILaunchActivatedEventArgs); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    /// <summary>Runs the application with AMainWindow as its first window.</summary>
    class procedure Run(AMainWindow: TWinUIWindowClass); reintroduce;
    /// <summary>
    ///   Reports an exception that escaped an event handler or a framework
    ///   callback: calls OnException, or shows the message. The app keeps running.
    /// </summary>
    class procedure HandleException(E: Exception); static;
    /// <summary>
    ///   Makes a converter available as {StaticResource AName} in every window's
    ///   XAML: Converter={StaticResource AName}, ConverterParameter=... Call it
    ///   before Run or at any time after. Built in: BoolToVisibility,
    ///   InverseBoolToVisibility, Format (ConverterParameter is a Delphi Format string).
    /// </summary>
    class procedure RegisterConverter(const AName: string; const AConvert: TWinUIConvertFunc;
      const AConvertBack: TWinUIConvertFunc = nil);
    /// <summary>Like the VCL Application.OnException, Sender is the application.</summary>
    class property OnException: TWinUIExceptionEvent read FOnException write FOnException;
  end;

implementation

uses
  Winapi.Windows,
  Winapi.MultiMon,
  System.TypInfo,
  RADWinUI.Binding;

{ TWinUIWindow }

constructor TWinUIWindow.Create;
begin
  inherited CreateFrom(nil, RADWinUI.Abi.Window.New);
  FWindows := FWindows + [Self];
  FTransparency := True;
  // Free the wrapper after Closed has reached every handler (user OnClosed included).
  FClosedToken := Intf.add_Closed(TTypedEventHandler_Object_WindowEventArgs.Create(
    procedure(ASender: IInspectable; AArgs: IWindowEventArgs)
    var
      Me: TWinUIWindow;
    begin
      Me := Self;
      DispatcherQueue.TryEnqueue(TDispatcherQueueHandler.Create(
        procedure
        begin
          if IsAlive(Me) then
            Me.Free;
        end));
    end));
end;

destructor TWinUIWindow.Destroy;
var
  I: Integer;
begin
  for I := High(FWindows) downto 0 do
    if FWindows[I] = Self then
      Delete(FWindows, I, 1);
  inherited;
end;

class function TWinUIWindow.IsAlive(AWindow: TWinUIWindow): Boolean;
var
  W: TWinUIWindow;
begin
  for W in FWindows do
    if W = AWindow then
      Exit(True);
  Result := False;
end;

procedure TWinUIWindow.DetachEvents;
begin
  if FClosedToken.Value <> 0 then
    Intf.remove_Closed(FClosedToken);
  inherited;
end;

function TWinUIWindow.Scale: Double;
var
  Dpi: Cardinal;
begin
  // WindowId.Value is the HWND of a top-level window, use
  // Win32Interop.GetWindowFromWindowId if that ever stops being true.
  Dpi := GetDpiForWindow(HWND(AppWindow.Id.Value));
  if Dpi = 0 then
    Dpi := 96;
  Result := Dpi / 96;
end;

function TWinUIWindow.Presenter: TWinUIOverlappedPresenter;
begin
  Result := AppWindow.Presenter as TWinUIOverlappedPresenter;
end;

function TWinUIWindow.GetClientWidth: Integer;
begin
  Result := Round(AppWindow.ClientSize.Width / Scale);
end;

function TWinUIWindow.GetClientHeight: Integer;
begin
  Result := Round(AppWindow.ClientSize.Height / Scale);
end;

procedure TWinUIWindow.ResizeClientArea(AWidth, AHeight: Integer);
var
  Size: SizeInt32;
begin
  Size.Width := Round(AWidth * Scale);
  Size.Height := Round(AHeight * Scale);
  AppWindow.ResizeClient(Size);
end;

procedure TWinUIWindow.SetClientWidth(AValue: Integer);
begin
  ResizeClientArea(AValue, Height);
end;

procedure TWinUIWindow.SetClientHeight(AValue: Integer);
begin
  ResizeClientArea(Width, AValue);
end;

// Known limit: the minimum size is converted at the current DPI, a move to a
// monitor with another scale keeps the old pixel value until MinWidth/MinHeight are set again.
procedure TWinUIWindow.SetMinWidth(AValue: Integer);
begin
  FMinWidth := AValue;
  Presenter.PreferredMinimumWidth := PropertyValue.CreateInt32(Round(AValue * Scale)) as IReference_Int32;
end;

procedure TWinUIWindow.SetMinHeight(AValue: Integer);
begin
  FMinHeight := AValue;
  Presenter.PreferredMinimumHeight := PropertyValue.CreateInt32(Round(AValue * Scale)) as IReference_Int32;
end;

procedure TWinUIWindow.SetBackdrop(AValue: TWinUIBackdrop);
var
  Mica: TWinUIMicaBackdrop;
begin
  FreeAndNil(FSystemBackdrop);
  case AValue of
    TWinUIBackdrop.Mica, TWinUIBackdrop.MicaAlt:
      begin
        Mica := TWinUIMicaBackdrop.Create(Self);
        if AValue = TWinUIBackdrop.MicaAlt then
          Mica.Kind := MicaKind.BaseAlt;
        FSystemBackdrop := Mica;
      end;
    TWinUIBackdrop.Acrylic:
      FSystemBackdrop := TWinUIDesktopAcrylicBackdrop.Create(Self);
  end;
  FBackdrop := AValue;
  ApplyBackdrop;
end;

procedure TWinUIWindow.SetTransparency(AValue: Boolean);
begin
  if AValue = FTransparency then
    Exit;
  FTransparency := AValue;
  ApplyBackdrop;
end;

procedure TWinUIWindow.ApplyBackdrop;
begin
  if FTransparency then
    SystemBackdrop := FSystemBackdrop
  else
    SystemBackdrop := nil;
  UpdateOpaqueFill;
end;

procedure TWinUIWindow.UpdateOpaqueFill;
const
  // SolidBackgroundFillColorBase, the colour Mica and Acrylic fall back to
  PageColors: array[Boolean] of Cardinal = ($FFF3F3F3, $FF202020);
var
  Root: TWinUIPanel;
  Color: TWinUIColor;
  Dark: Boolean;
begin
  if not (Content is TWinUIPanel) then
    Exit;
  Root := TWinUIPanel(Content);
  if FTransparency or (FBackdrop = TWinUIBackdrop.None) then
  begin
    if FOpaqueBrush <> nil then
      Root.Background := FPlainBackground;
    Exit;
  end;
  if FOpaqueBrush = nil then
  begin
    FPlainBackground := Root.Background;
    FOpaqueBrush := TWinUISolidColorBrush.Create(Self);
  end;
  if not FThemeHooked then
  begin
    // The solid colour follows the content's light or dark theme
    FThemeHooked := True;
    Root.ActualThemeChanged.Add(
      procedure(Sender: TObject; E: TWinValue)
      begin
        UpdateOpaqueFill;
      end);
  end;
  Dark := Root.ActualTheme = TWinUIElementTheme.Dark;
  Color.A := PageColors[Dark] shr 24;
  Color.R := (PageColors[Dark] shr 16) and $FF;
  Color.G := (PageColors[Dark] shr 8) and $FF;
  Color.B := PageColors[Dark] and $FF;
  FOpaqueBrush.Color := Color;
  Root.Background := FOpaqueBrush;
end;

type
  // Windows.UI.ViewManagement.IUISettings4, not in the generated projection
  IUISettings4 = interface(IInspectable)
    ['{52BB3002-919B-4D6B-9B78-8DD66FF4B93B}']
    function get_AdvancedEffectsEnabled: Boolean; safecall;
  end;

class function TWinUIWindow.SystemTransparency: Boolean;
var
  Instance: Pointer;
  Settings: IInspectable;
  Effects: IUISettings4;
  Power: TSystemPowerStatus;
begin
  Result := True;
  // Energy saver: SystemStatusFlag 1. PowerManager.EnergySaverStatus only covers
  // battery saver and reads Disabled on mains power, so it is not used.
  if GetSystemPowerStatus(Power) and (Power.Reserved1 = 1) then
    Exit(False);
  if Succeeded(RoActivateInstance(WinStr('Windows.UI.ViewManagement.UISettings'), Instance)) then
  begin
    Pointer(Settings) := Instance; // takes over the reference RoActivateInstance returned
    if Supports(Settings, IUISettings4, Effects) then
      Result := Effects.get_AdvancedEffectsEnabled;
  end;
end;

procedure TWinUIWindow.ExplainTransparency(ASwitch: TWinUIToggleSwitch);
var
  Tip: string;
begin
  if SystemTransparency then
    Tip := 'Show what is behind the window, blurred'
  else
    Tip := 'Windows has transparency off (Energy saver, or Settings > Personalization > Colors > ' +
      'Transparency effects), so the window stays solid even when this is on';
  ToolTipService.SetToolTip(TWinUIObject.IntfOf(ASwitch, IDependencyObject) as IDependencyObject,
    PropertyValue.CreateString(WinStr(Tip)));
end;

procedure TWinUIWindow.BindTransparencySwitch(ASwitch: TWinUIToggleSwitch);
begin
  ASwitch.IsOn := FTransparency;
  ExplainTransparency(ASwitch);
  ASwitch.Toggled.Add(
    procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
    begin
      Transparency := ASwitch.IsOn;
      ExplainTransparency(ASwitch);
    end);
end;

class procedure TWinUIWindow.FreeAll;
var
  W: TWinUIWindow;
begin
  for W in Copy(FWindows) do
    W.Free;
end;

function TWinUIWindow.GetDataContext: TWinValue;
begin
  if Content is TWinUIFrameworkElement then
    Result := TWinUIFrameworkElement(Content).DataContext
  else
    Result := IInspectable(nil);
end;

procedure TWinUIWindow.SetDataContext(const AValue: TWinValue);
begin
  if not (Content is TWinUIFrameworkElement) then
    raise EWinUIBindError.Create('Set the window Content before its DataContext');
  TWinUIFrameworkElement(Content).DataContext := AValue;
end;

type
  TMonitorSearch = record
    Primary: HMONITOR;
    Secondary: HMONITOR;
  end;
  PMonitorSearch = ^TMonitorSearch;

function CollectMonitor(AMonitor: HMONITOR; ADC: HDC; ARect: PRect; AData: LPARAM): BOOL; stdcall;
var
  Info: TMonitorInfo;
  Search: PMonitorSearch;
begin
  Search := PMonitorSearch(AData);
  Info.cbSize := SizeOf(Info);
  if GetMonitorInfo(AMonitor, @Info) then
    if Info.dwFlags and MONITORINFOF_PRIMARY <> 0 then
      Search.Primary := AMonitor
    else if Search.Secondary = 0 then
      Search.Secondary := AMonitor;
  Result := True;
end;

// UI tests set RADWINUI_TEST_MONITOR=secondary so test windows stay out of the
// user's way: placed on a non-primary monitor and shown without activation.
function TestMonitorWorkArea(out AArea: TRect): Boolean;
var
  Search: TMonitorSearch;
  Info: TMonitorInfo;
  Monitor: HMONITOR;
begin
  // offscreen: far outside every monitor, for runs while someone uses the only monitor
  if SameText(GetEnvironmentVariable('RADWINUI_TEST_MONITOR'), 'offscreen') then
  begin
    AArea.Left := -32000;
    AArea.Top := -32000;
    AArea.Right := AArea.Left + 3840;
    AArea.Bottom := AArea.Top + 2160;
    Exit(True);
  end;
  Result := SameText(GetEnvironmentVariable('RADWINUI_TEST_MONITOR'), 'secondary');
  if not Result then
    Exit;
  Search := Default(TMonitorSearch);
  EnumDisplayMonitors(0, nil, @CollectMonitor, LPARAM(@Search));
  Monitor := Search.Secondary;
  if Monitor = 0 then
    Monitor := Search.Primary; // only one monitor
  Info.cbSize := SizeOf(Info);
  Result := (Monitor <> 0) and GetMonitorInfo(Monitor, @Info);
  if Result then
    AArea := Info.rcWork;
end;

const
  EVENT_SYSTEM_FOREGROUND = $0003;
  WINEVENT_OUTOFCONTEXT = $0000;

type
  TWinEventProc = procedure(AHook: THandle; AEvent: DWORD; AWnd: HWND; AObject, AChild: Longint;
    AThread, ATime: DWORD); stdcall;

function SetWinEventHook(AEventMin, AEventMax: DWORD; AModule: HMODULE; AProc: TWinEventProc;
  AProcess, AThread, AFlags: DWORD): THandle; stdcall; external user32 name 'SetWinEventHook';

var
  // Test mode: the window that had the foreground before the first test window opened
  TestForeground: HWND;
  TestForegroundHook: THandle;

// Test mode: UI Automation Invoke makes WinUI focus the button, and the window's
// input site becomes the foreground window, hand the foreground straight back.
procedure TestModeForegroundChanged(AHook: THandle; AEvent: DWORD; AWnd: HWND; AObject, AChild: Longint;
  AThread, ATime: DWORD); stdcall;
begin
  if IsWindow(TestForeground) then
    SetForegroundWindow(TestForeground);
end;

// The hook runs on its own thread: on the UI thread it would wait until the
// click handler finishes, leaving the test window in front meanwhile.
function TestModeHookThread(AParameter: Pointer): Integer;
var
  Msg: TMsg;
begin
  TestForegroundHook := SetWinEventHook(EVENT_SYSTEM_FOREGROUND, EVENT_SYSTEM_FOREGROUND, 0,
    TestModeForegroundChanged, GetCurrentProcessId, 0, WINEVENT_OUTOFCONTEXT);
  while GetMessage(Msg, 0, 0, 0) do
    DispatchMessage(Msg);
  Result := 0;
end;

procedure TWinUIWindow.Show;
var
  Area: TRect;
  ThreadId: TThreadID;
  Size: SizeInt32;
  Pos: PointInt32;
begin
  if not TestMonitorWorkArea(Area) then
  begin
    Activate;
    Exit;
  end;
  Size := AppWindow.Size;
  Pos.X := Area.Left + (Area.Width - Size.Width) div 2;
  Pos.Y := Area.Top + (Area.Height - Size.Height) div 2;
  AppWindow.Move(Pos);
  if TestForeground = 0 then
  begin
    TestForeground := GetForegroundWindow;
    // Watches foreground changes to windows of this process for the rest of the run
    CloseHandle(BeginThread(nil, 0, TestModeHookThread, nil, 0, ThreadId));
  end;
  AppWindow.Show(False); // visible, but the user's foreground window keeps the focus
end;

procedure TWinUIWindow.Center;
var
  Area: RectInt32;
  Size: SizeInt32;
  Pos: PointInt32;
begin
  Area := DisplayArea.GetFromWindowId(AppWindow.Id, DisplayAreaFallback.Nearest).WorkArea;
  Size := AppWindow.Size;
  Pos.X := Area.X + (Area.Width - Size.Width) div 2;
  Pos.Y := Area.Y + (Area.Height - Size.Height) div 2;
  AppWindow.Move(Pos);
end;

function TWinUIWindow.FindElement<T>(const AName: string): T;
var
  Root: TWinUIUIElement;
begin
  Root := Content;
  if not (Root is TWinUIFrameworkElement) then
    Exit(nil);
  Result := T(TWinUIObject.Wrap(Self, TWinUIFrameworkElement(Root).FindName(AName).Obj,
    TWinUIObjectClass(GetTypeData(TypeInfo(T))^.ClassType)));
end;

function TWinUIWindow.PublishedMethod(const AName: string): TMethod;
begin
  Result.Code := MethodAddress(AName);
  Result.Data := Self;
  if Result.Code = nil then
    raise EWinUIBindError.CreateFmt('%s has no published method %s for its XAML events',
      [ClassName, AName]);
end;

function TWinUIWindow.NotifyProc<T>(const AName: string): TWinUIEventProc<T>;
var
  Handler: TNotifyEvent;
begin
  Handler := TNotifyEvent(PublishedMethod(AName));
  Result :=
    procedure(Sender: TObject; E: T)
    begin
      Handler(Sender);
    end;
end;

function TWinUIWindow.LoadContent(const AXaml: string): TWinUIFrameworkElement;
begin
  Result := TWinUIFrameworkElement(TWinUIObject.Wrap(Self, XamlReader.Load(WinStr(AXaml)), TWinUIFrameworkElement));
  Content := Result;
end;

{ TWinUITimer }

constructor TWinUITimer.Create;
begin
  inherited Create;
  FTimer := RADWinUI.Abi.DispatcherQueue.GetForCurrentThread.CreateTimer;
  FToken := FTimer.add_Tick(TTypedEventHandler_DispatcherQueueTimer_Object.Create(
    procedure(ASender: IDispatcherQueueTimer; AArgs: IInspectable)
    begin
      if Assigned(FOnTimer) then
        FOnTimer(Self);
    end));
end;

destructor TWinUITimer.Destroy;
begin
  if FTimer <> nil then
  begin
    FTimer.Stop;
    FTimer.remove_Tick(FToken);
  end;
  inherited;
end;

function TWinUITimer.GetInterval: Cardinal;
begin
  Result := FTimer.Interval.Duration div 10000;
end;

procedure TWinUITimer.SetInterval(AValue: Cardinal);
var
  Span: TimeSpan;
begin
  Span.Duration := Int64(AValue) * 10000; // 100 ns units
  FTimer.Interval := Span;
end;

function TWinUITimer.GetEnabled: Boolean;
begin
  Result := FTimer.IsRunning;
end;

procedure TWinUITimer.SetEnabled(AValue: Boolean);
begin
  if AValue then
    FTimer.Start
  else
    FTimer.Stop;
end;

{ TWinUIApp }
constructor TWinUIApp.Create;
begin
  inherited;
  FInstance := Self;
end;

function IsTrue(const AValue: TWinValue): Boolean;
var
  PV: IPropertyValue;
begin
  Result := Supports(AValue.Obj, IPropertyValue, PV) and (PV.&Type = PropertyType.Boolean) and PV.GetBoolean;
end;

function VisibilityOf(AVisible: Boolean): TWinValue;
begin
  if AVisible then
    Result := WinUIBox(TWinUIVisibility.Visible)
  else
    Result := WinUIBox(TWinUIVisibility.Collapsed);
end;

procedure TWinUIApp.AddResource(const AName: string; const AValue: IInspectable);
begin
  (Instance.Resources as IMap_Object_Object).Insert(PropertyValue.CreateString(WinStr(AName)), AValue);
end;

class procedure TWinUIApp.RegisterConverter(const AName: string; const AConvert, AConvertBack: TWinUIConvertFunc);
var
  Converter: IInspectable;
begin
  Converter := TWinUIValueConverter.Create(AConvert, AConvertBack);
  FConverterNames := FConverterNames + [AName];
  FConverters := FConverters + [Converter];
  if FInstance <> nil then
    FInstance.AddResource(AName, Converter); // already running: add it now
end;

procedure TWinUIApp.OnLaunched(const AArgs: ILaunchActivatedEventArgs);
var
  I: Integer;
begin
  // Converters first: {StaticResource} resolves while the window XAML loads.
  AddResource('BoolToVisibility', TWinUIValueConverter.Create(
    function(const AValue: TWinValue; const AParameter: string): TWinValue
    begin
      Result := VisibilityOf(IsTrue(AValue));
    end));
  AddResource('InverseBoolToVisibility', TWinUIValueConverter.Create(
    function(const AValue: TWinValue; const AParameter: string): TWinValue
    begin
      Result := VisibilityOf(not IsTrue(AValue));
    end));
  AddResource('Format', TWinUIValueConverter.Create(
    function(const AValue: TWinValue; const AParameter: string): TWinValue
    begin
      if AParameter = '' then
        Result := AValue.AsString
      else
        Result := Format(AParameter, [AValue.AsString]);
    end));
  for I := 0 to High(FConverterNames) do
    AddResource(FConverterNames[I], FConverters[I]);
  try
    FMainWindowClass.Create.Show;
  except
    on E: Exception do
    begin
      // Without its main window the application has nothing to show: report and exit.
      HandleException(E);
      Instance.Exit;
    end;
  end;
end;

procedure ShowException(E: Exception);
begin
  OutputDebugString(PChar(E.ClassName + ': ' + E.Message));
  MessageBox(0, PChar(E.Message), PChar(E.ClassName), MB_OK or MB_ICONERROR);
end;

procedure RouteWinRTException(AException: Exception);
begin
  TWinUIApp.HandleException(AException);
end;

class procedure TWinUIApp.HandleException(E: Exception);
begin
  if not Assigned(FOnException) then
  begin
    ShowException(E);
    Exit;
  end;
  try
    FOnException(FInstance, E);
  except
    on Inner: Exception do
      ShowException(Inner); // an OnException handler that fails must not end the app
  end;
end;

destructor TWinUIApp.Destroy;
begin
  // Windows whose deferred free did not run before the message loop ended.
  TWinUIWindow.FreeAll;
  if FInstance = Self then
    FInstance := nil;
  inherited;
end;

class procedure TWinUIApp.Run(AMainWindow: TWinUIWindowClass);
begin
  FMainWindowClass := AMainWindow;
  WinRTHandleException := RouteWinRTException;
  inherited Run;
end;

end.
