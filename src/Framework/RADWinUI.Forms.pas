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
  /// <summary>Transparent draws nothing behind the content, the desktop shows through.</summary>
  TWinUIBackdrop = (None, Mica, MicaAlt, Acrylic, Transparent);

  /// <summary>
  ///   Overlay: no border or title bar, not resizable, always on top, not in the
  ///   taskbar or Alt+Tab. For notch bars, toasts and other floating panels.
  /// </summary>
  TWinUIWindowStyle = (Normal, Overlay);

  /// <summary>The edge of its display the window stays on, through size, DPI and display changes.</summary>
  TWinUIDock = (None, TopCenter, TopLeft, TopRight, BottomCenter);

  /// <summary>
  ///   Background: only the bounds of HitTestElement take mouse input, clicks
  ///   anywhere else go to the windows below.
  /// </summary>
  TWinUIClickThrough = (None, Background);

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
    FWindowStyle: TWinUIWindowStyle;
    FDock: TWinUIDock;
    FClickThrough: TWinUIClickThrough;
    FShowActivated: Boolean;
    FHitTestElement: TWinUIFrameworkElement;
    FHitTestListener: Integer;
    FHitTestBox: array[0..3] of Integer; // pixels: left, top, right, bottom
    FRegionSet: Boolean;
    FSubclassed: Boolean;
    FDockListener: Integer;
    class var FWindows: TArray<TWinUIWindow>;
    class function IsAlive(AWindow: TWinUIWindow): Boolean; static;
    function Handle: THandle;
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
    procedure SetWindowStyle(AValue: TWinUIWindowStyle);
    procedure SetDock(AValue: TWinUIDock);
    procedure SetClickThrough(AValue: TWinUIClickThrough);
    procedure SetShowActivated(AValue: Boolean);
    procedure SetHitTestElement(AValue: TWinUIFrameworkElement);
    function GetAlwaysOnTop: Boolean;
    procedure SetAlwaysOnTop(AValue: Boolean);
    procedure UpdateFrame;
    procedure UpdateExStyle;
    procedure KeepOnTop;
    procedure ApplyDock;
    procedure UpdateHitTestRegion;
    procedure Subclass;
  protected
    procedure DetachEvents; override;
    /// <summary>
    ///   Called for every Windows message of the window before WinUI sees it.
    ///   Return True with AResult set to handle it, False passes it on.
    /// </summary>
    function HandleMessage(AMsg: Cardinal; AWParam: NativeUInt; ALParam: NativeInt;
      var AResult: NativeInt): Boolean; virtual;
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
    /// <summary>Where Dock puts a window of ASize, AOuter and AWork are its display's bounds and work area.</summary>
    class function DockPosition(ADock: TWinUIDock; const AOuter, AWork: RectInt32;
      const ASize: SizeInt32): PointInt32; static;
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
    /// <summary>Normal, or Overlay for a borderless always-on-top panel outside the taskbar.</summary>
    property WindowStyle: TWinUIWindowStyle read FWindowStyle write SetWindowStyle;
    /// <summary>Keeps the window on an edge of its display, applied on Show and on every change.</summary>
    property Dock: TWinUIDock read FDock write SetDock;
    /// <summary>Background lets clicks outside HitTestElement through to the windows below.</summary>
    property ClickThrough: TWinUIClickThrough read FClickThrough write SetClickThrough;
    /// <summary>
    ///   The element whose bounds take mouse input when ClickThrough is Background,
    ///   followed through layout changes and animations. nil: the whole window.
    /// </summary>
    property HitTestElement: TWinUIFrameworkElement read FHitTestElement write SetHitTestElement;
    /// <summary>
    ///   True (the default): Show and clicks give the window the keyboard focus.
    ///   False: it never takes the focus from the app in use, Activate still does.
    /// </summary>
    property ShowActivated: Boolean read FShowActivated write SetShowActivated;
    property AlwaysOnTop: Boolean read GetAlwaysOnTop write SetAlwaysOnTop;
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
  Winapi.Messages,
  Winapi.MultiMon,
  System.Math,
  System.TypInfo,
  RADWinUI.Binding;

{$R RADWinUI.Icon.res}

var
  SmallIcon, BigIcon: HICON;

// The title bar and the taskbar show the program's MAINICON, like a VCL application.
// A WinUI window would otherwise show a generic icon, so without one ({$R *.res}
// missing) it shows the RADWinUI logo linked above.
procedure SetProgramIcon(AWindow: HWND);
var
  Dpi: Cardinal;
  Module: HMODULE;
  Name: PChar;
begin
  if SmallIcon = 0 then
  begin
    Module := MainInstance;
    Name := 'MAINICON';
    if FindResource(Module, Name, RT_GROUP_ICON) = 0 then
    begin
      Module := HInstance;
      Name := 'RADWINUI_ICON';
    end;
    // shortcut: sized for the DPI of the first window, Windows scales it on other monitors
    Dpi := GetDpiForWindow(AWindow);
    if Dpi = 0 then
      Dpi := 96;
    // Loaded once for every window, Windows frees them when the process ends
    SmallIcon := LoadImage(Module, Name, IMAGE_ICON, GetSystemMetricsForDpi(SM_CXSMICON, Dpi),
      GetSystemMetricsForDpi(SM_CYSMICON, Dpi), LR_DEFAULTCOLOR);
    BigIcon := LoadImage(Module, Name, IMAGE_ICON, GetSystemMetricsForDpi(SM_CXICON, Dpi),
      GetSystemMetricsForDpi(SM_CYICON, Dpi), LR_DEFAULTCOLOR);
  end;
  SendMessage(AWindow, WM_SETICON, ICON_SMALL, LPARAM(SmallIcon));
  SendMessage(AWindow, WM_SETICON, ICON_BIG, LPARAM(BigIcon));
end;

const
  DWMWA_NCRENDERING_POLICY = 2;
  DWMWA_WINDOW_CORNER_PREFERENCE = 33;
  DWMWA_BORDER_COLOR = 34;
  DWMNCRP_USEWINDOWSTYLE = 0;
  DWMNCRP_DISABLED = 1;
  DWMWCP_DEFAULT = 0;
  DWMWCP_DONOTROUND = 1;
  DWMWA_COLOR_DEFAULT = $FFFFFFFF;
  DWMWA_COLOR_NONE = $FFFFFFFE;
  OverlayRemovedStyles = WS_CAPTION or WS_THICKFRAME or WS_SYSMENU or WS_MINIMIZEBOX or WS_MAXIMIZEBOX;

type
  TSubclassProc = function(AWnd: HWND; AMsg: UINT; AWParam: WPARAM; ALParam: LPARAM; AId: UINT_PTR;
    ARefData: DWORD_PTR): LRESULT; stdcall;

function SetWindowSubclass(AWnd: HWND; AProc: TSubclassProc; AId: UINT_PTR; ARefData: DWORD_PTR): BOOL; stdcall;
  external 'comctl32.dll' name 'SetWindowSubclass';
function RemoveWindowSubclass(AWnd: HWND; AProc: TSubclassProc; AId: UINT_PTR): BOOL; stdcall;
  external 'comctl32.dll' name 'RemoveWindowSubclass';
function DefSubclassProc(AWnd: HWND; AMsg: UINT; AWParam: WPARAM; ALParam: LPARAM): LRESULT; stdcall;
  external 'comctl32.dll' name 'DefSubclassProc';
function DwmSetWindowAttribute(AWnd: HWND; AAttribute: DWORD; AValue: Pointer; ASize: DWORD): HRESULT; stdcall;
  external 'dwmapi.dll' name 'DwmSetWindowAttribute';

function WindowSubclassProc(AWnd: HWND; AMsg: UINT; AWParam: WPARAM; ALParam: LPARAM; AId: UINT_PTR;
  ARefData: DWORD_PTR): LRESULT; stdcall;
begin
  Result := 0;
  try
    if TWinUIWindow(Pointer(ARefData)).HandleMessage(AMsg, AWParam, ALParam, Result) then
      Exit;
  except
    on E: Exception do
      TWinUIApp.HandleException(E);
  end;
  Result := DefSubclassProc(AWnd, AMsg, AWParam, ALParam);
end;

{ Transparent backdrop }

type
  // Windows.UI.Composition, not in the generated projection: only what the
  // transparent backdrop needs. The vtable order is that of the metadata.
  IWindowsCompositionBrush = IInspectable;

  IWindowsCompositor = interface(IInspectable)
    ['{B403CA50-7F8C-4E83-985F-CC45060036D8}']
    function CreateColorKeyFrameAnimation: IInspectable; safecall;
    function CreateColorBrush: IWindowsCompositionBrush; safecall;
    function CreateColorBrushWithColor(AColor: RADWinUI.Abi.Color): IWindowsCompositionBrush; safecall;
  end;

  TDispatcherQueueOptions = record
    Size: DWORD;
    ThreadType: Integer;    // DQTYPE_THREAD_CURRENT = 2
    ApartmentType: Integer; // DQTAT_COM_NONE = 0
  end;

  // A SystemBackdrop subclass (COM aggregation, as TWinUIApplication does with
  // Application) that gives its target a fully transparent brush: only the XAML
  // content is drawn, the desktop shows through everywhere else.
  TTransparentBackdrop = class(TInterfacedObject, IInterface, IInspectable, ISystemBackdropOverrides)
  strict private
    FInner: IInspectable;
  protected
    function QueryInterface(const IID: TGUID; out Obj): HRESULT; stdcall;
    procedure GetIids(out AIidCount: Cardinal; out AIids: PGUID); safecall;
    function GetRuntimeClassName: HSTRING; safecall;
    function GetTrustLevel: TrustLevel; safecall;
    procedure OnTargetConnected(AConnectedTarget: ICompositionSupportsSystemBackdrop; AXamlRoot: IXamlRoot); safecall;
    procedure OnTargetDisconnected(ADisconnectedTarget: ICompositionSupportsSystemBackdrop); safecall;
    procedure OnDefaultSystemBackdropConfigurationChanged(ATarget: ICompositionSupportsSystemBackdrop;
      AXamlRoot: IXamlRoot); safecall;
  public
    constructor Create;
    destructor Destroy; override;
    function SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HRESULT; override;
  end;

function CreateDispatcherQueueController(AOptions: TDispatcherQueueOptions; out AController: IInspectable): HRESULT;
  stdcall; external 'CoreMessaging.dll' name 'CreateDispatcherQueueController';

var
  SystemBackdropFactoryCache: IInspectable;
  // Windows.UI.Composition needs a Windows.System.DispatcherQueue on the UI
  // thread, WinUI only creates its own Microsoft.UI.Dispatching one.
  SystemQueueController: IInspectable;
  WindowsCompositor: IWindowsCompositor;

function SharedWindowsCompositor: IWindowsCompositor;
var
  Options: TDispatcherQueueOptions;
  Instance: Pointer;
  Obj: IInspectable;
begin
  if WindowsCompositor = nil then
  begin
    if SystemQueueController = nil then
    begin
      Options.Size := SizeOf(Options);
      Options.ThreadType := 2;
      Options.ApartmentType := 0;
      // Fails when the thread already has one, which is just as good
      CreateDispatcherQueueController(Options, SystemQueueController);
    end;
    CheckWinRT(RoActivateInstance(WinStr('Windows.UI.Composition.Compositor'), Instance),
      'Windows.UI.Composition.Compositor');
    Pointer(Obj) := Instance; // takes over the reference RoActivateInstance returned
    WindowsCompositor := Obj as IWindowsCompositor;
  end;
  Result := WindowsCompositor;
end;

constructor TTransparentBackdrop.Create;
var
  Outer: IInspectable;
  Delegating: ISystemBackdrop;
begin
  inherited Create;
  Outer := Self as IInspectable;
  Delegating := ISystemBackdropFactory(GetFactory(SystemBackdrop.RuntimeClassName, ISystemBackdropFactory,
    SystemBackdropFactoryCache)).CreateInstance(Outer, FInner);
  // Delegating forwards AddRef to us, keeping it would be a reference cycle.
  Delegating := nil;
end;

destructor TTransparentBackdrop.Destroy;
begin
  FInner := nil;
  inherited;
end;

function TTransparentBackdrop.QueryInterface(const IID: TGUID; out Obj): HRESULT;
begin
  if GetInterface(IID, Obj) then
    Exit(S_OK);
  if FInner <> nil then
    Exit(FInner.QueryInterface(IID, Obj));
  Pointer(Obj) := nil;
  Result := E_NOINTERFACE;
end;

procedure TTransparentBackdrop.GetIids(out AIidCount: Cardinal; out AIids: PGUID);
begin
  FInner.GetIids(AIidCount, AIids);
end;

function TTransparentBackdrop.GetRuntimeClassName: HSTRING;
begin
  Result := FInner.GetRuntimeClassName;
end;

function TTransparentBackdrop.GetTrustLevel: TrustLevel;
begin
  Result := FInner.GetTrustLevel;
end;

procedure TTransparentBackdrop.OnTargetConnected(AConnectedTarget: ICompositionSupportsSystemBackdrop;
  AXamlRoot: IXamlRoot);
var
  Clear: RADWinUI.Abi.Color;
begin
  Clear := Default(RADWinUI.Abi.Color);
  AConnectedTarget.SystemBackdrop := SharedWindowsCompositor.CreateColorBrushWithColor(Clear);
end;

procedure TTransparentBackdrop.OnTargetDisconnected(ADisconnectedTarget: ICompositionSupportsSystemBackdrop);
begin
  ADisconnectedTarget.SystemBackdrop := nil;
end;

procedure TTransparentBackdrop.OnDefaultSystemBackdropConfigurationChanged(
  ATarget: ICompositionSupportsSystemBackdrop; AXamlRoot: IXamlRoot);
begin
end;

function TTransparentBackdrop.SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HRESULT;
begin
  // Reported, never a failure HRESULT inside the XAML framework
  if ExceptObject is Exception then
    TWinUIApp.HandleException(Exception(ExceptObject));
  Result := S_OK;
end;

{ TWinUIWindow }

constructor TWinUIWindow.Create;
begin
  inherited CreateFrom(nil, RADWinUI.Abi.Window.New);
  FWindows := FWindows + [Self];
  // WindowId.Value is the HWND of a top-level window (see Scale)
  SetProgramIcon(HWND(AppWindow.Id.Value));
  FTransparency := True;
  FShowActivated := True;
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
  if Assigned(CustomXamlOwnerGone) then
    CustomXamlOwnerGone(Self);
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
  if FSubclassed then
  begin
    RemoveWindowSubclass(Handle, WindowSubclassProc, 1);
    FSubclassed := False;
  end;
  inherited;
end;

function TWinUIWindow.Handle: THandle;
begin
  // WindowId.Value is the HWND of a top-level window (see Scale)
  Result := HWND(AppWindow.Id.Value);
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
    TWinUIBackdrop.Transparent:
      FSystemBackdrop := TWinUISystemBackdrop.CreateFrom(Self, TTransparentBackdrop.Create as IInspectable);
  end;
  FBackdrop := AValue;
  ApplyBackdrop;
  UpdateFrame;
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

procedure TWinUIWindow.SetWindowStyle(AValue: TWinUIWindowStyle);
var
  Overlay: Boolean;
  P: TWinUIOverlappedPresenter;
  Style, NewStyle: NativeInt;
begin
  FWindowStyle := AValue;
  Overlay := AValue = TWinUIWindowStyle.Overlay;
  P := Presenter;
  P.SetBorderAndTitleBar(not Overlay, not Overlay);
  P.IsResizable := not Overlay;
  P.IsMaximizable := not Overlay;
  P.IsMinimizable := not Overlay;
  P.IsAlwaysOnTop := Overlay;
  AppWindow.IsShownInSwitchers := not Overlay;
  // SetBorderAndTitleBar(False, False) hides the frame but keeps WS_CAPTION,
  // so Windows would still treat the top of the window as a title bar.
  Style := GetWindowLongPtr(Handle, GWL_STYLE);
  if Overlay then
  begin
    Subclass;
    NewStyle := (Style and not OverlayRemovedStyles) or WS_POPUP;
  end
  else
    NewStyle := (Style and not WS_POPUP) or WS_OVERLAPPEDWINDOW;
  if NewStyle <> Style then
  begin
    SetWindowLongPtr(Handle, GWL_STYLE, NewStyle);
    SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or
      SWP_NOACTIVATE or SWP_NOOWNERZORDER);
  end;
  UpdateFrame;
end;

function TWinUIWindow.GetAlwaysOnTop: Boolean;
begin
  Result := Presenter.IsAlwaysOnTop;
end;

procedure TWinUIWindow.SetAlwaysOnTop(AValue: Boolean);
begin
  Presenter.IsAlwaysOnTop := AValue;
end;

// Overlay and Transparent windows get no DWM frame: no rounded corners, no
// accent border and no shadow around a window whose shape is its content.
procedure TWinUIWindow.UpdateFrame;
var
  Frameless: Boolean;
  Corner, Border, Policy: DWORD;
begin
  Frameless := (FWindowStyle = TWinUIWindowStyle.Overlay) or (FBackdrop = TWinUIBackdrop.Transparent);
  if Frameless then
  begin
    Corner := DWMWCP_DONOTROUND;
    Border := DWMWA_COLOR_NONE;
    Policy := DWMNCRP_DISABLED;
  end
  else
  begin
    Corner := DWMWCP_DEFAULT;
    Border := DWMWA_COLOR_DEFAULT;
    Policy := DWMNCRP_USEWINDOWSTYLE;
  end;
  DwmSetWindowAttribute(Handle, DWMWA_WINDOW_CORNER_PREFERENCE, @Corner, SizeOf(Corner));
  DwmSetWindowAttribute(Handle, DWMWA_BORDER_COLOR, @Border, SizeOf(Border));
  DwmSetWindowAttribute(Handle, DWMWA_NCRENDERING_POLICY, @Policy, SizeOf(Policy));
end;

procedure TWinUIWindow.SetShowActivated(AValue: Boolean);
begin
  FShowActivated := AValue;
  UpdateExStyle;
end;

procedure TWinUIWindow.UpdateExStyle;
var
  Style, NewStyle: NativeInt;
begin
  Style := GetWindowLongPtr(Handle, GWL_EXSTYLE);
  if FShowActivated then
    NewStyle := Style and not WS_EX_NOACTIVATE
  else
    NewStyle := Style or WS_EX_NOACTIVATE;
  if NewStyle <> Style then
    SetWindowLongPtr(Handle, GWL_EXSTYLE, NewStyle);
end;

procedure TWinUIWindow.Subclass;
begin
  if not FSubclassed then
    FSubclassed := SetWindowSubclass(Handle, WindowSubclassProc, 1, DWORD_PTR(Self));
end;

function TWinUIWindow.HandleMessage(AMsg: Cardinal; AWParam: NativeUInt; ALParam: NativeInt;
  var AResult: NativeInt): Boolean;
begin
  Result := False;
  case AMsg of
    // WinUI's presenter puts WS_CAPTION back when it updates the frame
    WM_STYLECHANGING:
      if (FWindowStyle = TWinUIWindowStyle.Overlay) and (Integer(AWParam) = GWL_STYLE) then
        PStyleStruct(ALParam).styleNew := (PStyleStruct(ALParam).styleNew and not OverlayRemovedStyles) or WS_POPUP;
    // A resolution, layout or taskbar change moves the edge the window docks to
    WM_DISPLAYCHANGE, WM_SETTINGCHANGE:
      if FDock <> TWinUIDock.None then
        DispatcherQueue.TryEnqueue(TDispatcherQueueHandler.Create(
          procedure
          begin
            ApplyDock;
          end));
  end;
end;

procedure TWinUIWindow.SetDock(AValue: TWinUIDock);
begin
  FDock := AValue;
  if (AValue <> TWinUIDock.None) and (FDockListener = 0) then
  begin
    Subclass;
    // Size and DPI changes: the window keeps its edge
    FDockListener := 1 + AppWindow.Changed.Add(
      procedure(Sender: TObject; E: TWinUIAppWindowChangedEventArgs)
      begin
        if E.DidSizeChange then
          ApplyDock;
      end);
  end;
  ApplyDock;
end;

class function TWinUIWindow.DockPosition(ADock: TWinUIDock; const AOuter, AWork: RectInt32;
  const ASize: SizeInt32): PointInt32;
var
  Area: RectInt32;
begin
  // The top edge of the screen itself, the bottom one above the taskbar
  if ADock = TWinUIDock.BottomCenter then
    Area := AWork
  else
    Area := AOuter;
  case ADock of
    TWinUIDock.TopLeft:
      Result.X := Area.X;
    TWinUIDock.TopRight:
      Result.X := Area.X + Area.Width - ASize.Width;
  else
    Result.X := Area.X + (Area.Width - ASize.Width) div 2;
  end;
  if ADock = TWinUIDock.BottomCenter then
    Result.Y := Area.Y + Area.Height - ASize.Height
  else
    Result.Y := Area.Y;
end;

procedure TWinUIWindow.ApplyDock;
var
  Display: IDisplayArea;
  Pos: PointInt32;
begin
  if FDock = TWinUIDock.None then
    Exit;
  Display := DisplayArea.GetFromWindowId(AppWindow.Id, DisplayAreaFallback.Nearest);
  Pos := DockPosition(FDock, Display.OuterBounds, Display.WorkArea, AppWindow.Size);
  if (Pos.X <> AppWindow.Position.X) or (Pos.Y <> AppWindow.Position.Y) then
    AppWindow.Move(Pos);
end;

procedure TWinUIWindow.SetClickThrough(AValue: TWinUIClickThrough);
begin
  FClickThrough := AValue;
  UpdateHitTestRegion;
end;

procedure TWinUIWindow.SetHitTestElement(AValue: TWinUIFrameworkElement);
begin
  if FHitTestElement = AValue then
    Exit;
  if (FHitTestElement <> nil) and (FHitTestListener <> 0) then
    FHitTestElement.LayoutUpdated.Remove(FHitTestListener - 1);
  FHitTestListener := 0;
  FHitTestElement := AValue;
  if AValue <> nil then
    // Every layout pass, so the region follows size animations frame by frame
    FHitTestListener := 1 + AValue.LayoutUpdated.Add(
      procedure(Sender: TObject; E: TWinValue)
      begin
        UpdateHitTestRegion;
      end);
  UpdateHitTestRegion;
end;

procedure TWinUIWindow.UpdateHitTestRegion;
var
  Element: IFrameworkElement;
  Bounds: RADWinUI.Abi.Rect;
  S: Double;
  Box: array[0..3] of Integer;
begin
  if (FClickThrough = TWinUIClickThrough.None) or (FHitTestElement = nil) then
  begin
    if FRegionSet then
      SetWindowRgn(Handle, 0, True);
    FRegionSet := False;
    Exit;
  end;
  Element := TWinUIObject.IntfOf(FHitTestElement, IFrameworkElement) as IFrameworkElement;
  Bounds.X := 0;
  Bounds.Y := 0;
  Bounds.Width := Element.ActualWidth;
  Bounds.Height := Element.ActualHeight;
  // Raw interfaces: a wrapper per transform would pile up in the window until it closes
  Bounds := (Element as IUIElement).TransformToVisual(nil).TransformBounds(Bounds);
  S := Scale;
  Box[0] := Floor(Bounds.X * S);
  Box[1] := Floor(Bounds.Y * S);
  Box[2] := Ceil((Bounds.X + Bounds.Width) * S);
  Box[3] := Ceil((Bounds.Y + Bounds.Height) * S);
  if FRegionSet and (Box[0] = FHitTestBox[0]) and (Box[1] = FHitTestBox[1]) and (Box[2] = FHitTestBox[2]) and
    (Box[3] = FHitTestBox[3]) then
    Exit;
  FHitTestBox[0] := Box[0];
  FHitTestBox[1] := Box[1];
  FHitTestBox[2] := Box[2];
  FHitTestBox[3] := Box[3];
  FRegionSet := True;
  // The window owns the region from here on
  SetWindowRgn(Handle, CreateRectRgn(Box[0], Box[1], Box[2], Box[3]), True);
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
    ApplyDock;
    if FShowActivated then
      Activate
    else
      AppWindow.Show(False);
    KeepOnTop;
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
  KeepOnTop;
end;

// The presenter's IsAlwaysOnTop does not always reach a window that was hidden
// when it was set (an overlay sets it before Show), so showing confirms it.
procedure TWinUIWindow.KeepOnTop;
begin
  if (FWindowStyle = TWinUIWindowStyle.Overlay) or Presenter.IsAlwaysOnTop then
    SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_NOOWNERZORDER);
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
var
  Loaded: IInspectable;
  Previous: TObject;
begin
  // Controls written in Delphi that this XAML creates belong to this window
  Previous := CustomXamlLoadOwner;
  CustomXamlLoadOwner := Self;
  try
    Loaded := XamlReader.Load(WinStr(AXaml));
  finally
    CustomXamlLoadOwner := Previous;
  end;
  Result := TWinUIFrameworkElement(TWinUIObject.Wrap(Self, Loaded, TWinUIFrameworkElement));
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
  // Before WinRT shuts down, like every other WinRT reference
  WindowsCompositor := nil;
  SystemQueueController := nil;
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
