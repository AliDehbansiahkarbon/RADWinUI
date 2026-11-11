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
  System.UITypes,
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

  /// <summary>What closing does to a window, like the VCL caNone, caHide and caFree.</summary>
  TWinUICloseAction = (None, Hide, Free);
  TWinUICloseEvent = procedure(Sender: TObject; var Action: TWinUICloseAction) of object;
  TWinUICloseQueryEvent = procedure(Sender: TObject; var CanClose: Boolean) of object;

  /// <summary>
  ///   Normal, Minimized and Maximized are the usual window states, FullScreen
  ///   fills the display without a frame, CompactOverlay is a small always-on-top
  ///   picture-in-picture window.
  /// </summary>
  TWinUIWindowState = (Normal, Minimized, Maximized, FullScreen, CompactOverlay);

  /// <summary>MainWindow: the app ends when its main window closes. LastWindow: when its last window closes.</summary>
  TWinUIShutdownMode = (MainWindow, LastWindow);

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
    FFrameExtended: Boolean;
    FBlurBehind: Boolean;
    FDarkRoot: Boolean;
    FRootTheme: TWinUIElementTheme;
    FThemedChildren: TArray<TWinUIFrameworkElement>;
    FClassBrush: NativeInt;
    FClassBrushSet: Boolean;
    FSubclassed: Boolean;
    FDockListener: Integer;
    FOnClose: TWinUICloseEvent;
    FOnCloseQuery: TWinUICloseQueryEvent;
    FOwnerWindow: TWinUIWindow;
    FModal: Boolean;
    FModalResult: TModalResult;
    FModalDone: TProc<TModalResult>;
    FClosing: Boolean;
    FMaxWidth: Integer;
    FMaxHeight: Integer;
    FOverlapped: TWinUIAppWindowPresenter;
    FMaximizeOnShow: Boolean;
    FPassthrough: TArray<TWinUIFrameworkElement>;
    FPassthroughListeners: TArray<Integer>;
    class var FWindows: TArray<TWinUIWindow>;
    function CloseAction: TWinUICloseAction;
    procedure EndModal;
    procedure SetOwnerWindow(AValue: TWinUIWindow);
    procedure SetModalResult(AValue: TModalResult);
    function GetLeft: Integer;
    function GetTop: Integer;
    procedure SetLeft(AValue: Integer);
    procedure SetTop(AValue: Integer);
    procedure SetMaxWidth(AValue: Integer);
    procedure SetMaxHeight(AValue: Integer);
    function GetWindowState: TWinUIWindowState;
    procedure SetWindowState(AValue: TWinUIWindowState);
    function GetResizable: Boolean;
    procedure SetResizable(AValue: Boolean);
    function GetMinimizable: Boolean;
    procedure SetMinimizable(AValue: Boolean);
    function GetMaximizable: Boolean;
    procedure SetMaximizable(AValue: Boolean);
    function GetPlacement: string;
    procedure SetPlacement(const AValue: string);
    procedure UpdatePassthrough;
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
    procedure UpdateSeeThroughTheme;
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
    /// <summary>Restores the window when it is minimized and brings it to the front.</summary>
    procedure BringToFront;
    /// <summary>
    ///   Closes the window like the VCL: OnCloseQuery may refuse, OnClose picks
    ///   the action (Free by default, Hide or None). The close button and Alt+F4 do the same.
    /// </summary>
    procedure Close; reintroduce;
    /// <summary>Hides the window, Show brings it back.</summary>
    procedure Hide;
    /// <summary>
    ///   Shows the window as a modal one: its OwnerWindow (the active window when
    ///   none is set) is disabled until it closes, it is centred on it, and
    ///   AOnClose gets ModalResult. The call returns at once, there is no message loop.
    /// </summary>
    procedure ShowModal(const AOnClose: TProc<TModalResult> = nil);
    /// <summary>Centers the window on its OwnerWindow, or on its display when it has none.</summary>
    procedure CenterOnOwner;
    /// <summary>Changes the window's icon in its title bar, the taskbar and Alt+Tab (an .ico file).</summary>
    procedure SetIcon(const AFileName: string);
    /// <summary>
    ///   Makes AElement the title bar: the content goes up into the title bar area
    ///   and AElement is where the window is dragged. Works with WinUI's TitleBar control.
    /// </summary>
    procedure UseTitleBar(AElement: TWinUIUIElement);
    /// <summary>
    ///   Elements in a title bar of your own that take clicks and typing, such as a
    ///   search box: the rest of the title bar keeps dragging the window. Followed
    ///   through layout changes. WinUI's TitleBar control does this by itself.
    /// </summary>
    procedure SetTitleBarPassthrough(const AElements: array of TWinUIFrameworkElement);
    /// <summary>
    ///   Stores Placement under HKEY_CURRENT_USER\Software\&lt;exe name&gt;\Placement,
    ///   in the value AName (the class name when empty).
    /// </summary>
    procedure SavePlacement(const AName: string = '');
    /// <summary>Restores what SavePlacement stored, False when there is nothing.</summary>
    function RestorePlacement(const AName: string = ''): Boolean;
    /// <summary>Every window of the app that is not freed yet, oldest first.</summary>
    class function Windows: TArray<TWinUIWindow>; static;
    /// <summary>
    ///   The window of this app that has the focus, else the one created last,
    ///   nil when no window is open. Dialogs and pickers belong to it.
    /// </summary>
    class function Active: TWinUIWindow; static;
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
    ///   A Transparent backdrop ignores it, the content decides what shows there.
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
    /// <summary>Position of the window's outer frame, in device-independent pixels of its display.</summary>
    property Left: Integer read GetLeft write SetLeft;
    property Top: Integer read GetTop write SetTop;
    /// <summary>The largest client size the user can drag the window to, 0 for no limit.</summary>
    property MaxWidth: Integer read FMaxWidth write SetMaxWidth;
    property MaxHeight: Integer read FMaxHeight write SetMaxHeight;
    property WindowState: TWinUIWindowState read GetWindowState write SetWindowState;
    /// <summary>The user can resize the window, minimize it, maximize it.</summary>
    property Resizable: Boolean read GetResizable write SetResizable;
    property Minimizable: Boolean read GetMinimizable write SetMinimizable;
    property Maximizable: Boolean read GetMaximizable write SetMaximizable;
    /// <summary>
    ///   The window this one belongs to: it stays above it, is minimized with it
    ///   and closes with it. Set before Show.
    /// </summary>
    property OwnerWindow: TWinUIWindow read FOwnerWindow write SetOwnerWindow;
    /// <summary>
    ///   The result of a modal window. Setting it to anything but mrNone closes
    ///   the window, as in the VCL. Closing it otherwise gives mrCancel.
    /// </summary>
    property ModalResult: TModalResult read FModalResult write SetModalResult;
    /// <summary>
    ///   Position, size and state as text, to keep anywhere and set again in a
    ///   later run. A position on a display that is gone puts the window on the nearest one.
    /// </summary>
    property Placement: string read GetPlacement write SetPlacement;
    /// <summary>Before the window closes, set CanClose to False to keep it open.</summary>
    property OnCloseQuery: TWinUICloseQueryEvent read FOnCloseQuery write FOnCloseQuery;
    /// <summary>When the window closes: Action is Free unless the handler picks Hide or None.</summary>
    property OnClose: TWinUICloseEvent read FOnClose write FOnClose;
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

  /// <summary>How the app was started, or reached again while it runs.</summary>
  TWinUIActivationKind = (Launch, &File, Protocol, Notification, Other);

  TWinUIActivation = record
    Kind: TWinUIActivationKind;
    /// <summary>
    ///   Launch: the command line arguments, without the program name.
    ///   Protocol: the whole URI. Notification: the Argument of the
    ///   notification, or of the button that was clicked.
    /// </summary>
    Arguments: string;
    /// <summary>File: the full paths of the files to open.</summary>
    Files: TArray<string>;
    /// <summary>Notification: what the user typed in its text boxes, as Id=Value pairs.</summary>
    Inputs: TArray<string>;
    /// <summary>The value of the text box AId of a notification, empty when there is none.</summary>
    function Input(const AId: string): string;
  end;

  TWinUIActivatedEvent = procedure(Sender: TObject; const AActivation: TWinUIActivation) of object;

  /// <summary>Application that creates and shows a main window class on launch.</summary>
  TWinUIApp = class(TWinUIApplication)
  strict private
    class var FMainWindowClass: TWinUIWindowClass;
    class var FInstance: TWinUIApp;
    class var FOnException: TWinUIExceptionEvent;
    class var FConverterNames: TArray<string>;
    class var FConverters: TArray<IInspectable>;
    class var FSingleInstance: Boolean;
    class var FOnActivated: TWinUIActivatedEvent;
    class var FLaunchActivation: TWinUIActivation;
    class var FMainInstance: IAppInstance;
    class var FActivatedToken: EventRegistrationToken;
    class var FDispatcher: IDispatcherQueue;
    class var FMainWindow: TWinUIWindow;
    class var FShutdownMode: TWinUIShutdownMode;
    procedure AddResource(const AName: string; const AValue: IInspectable);
    class function StartInstance: Boolean; static;
    class procedure CallActivated(const AActivation: TWinUIActivation; ABringToFront: Boolean); static;
  private
    // TWinUIWindow reports its windows: closed (ShutdownMode) and freed (MainWindow)
    class procedure WindowClosed(AWindow: TWinUIWindow); static;
    class procedure WindowGone(AWindow: TWinUIWindow); static;
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
    /// <summary>
    ///   Runs AProc on the UI thread, after the current event, like TThread.Queue.
    ///   Safe to call from any thread, for example from a WinRT completion handler.
    /// </summary>
    class procedure Queue(const AProc: TProc); static;
    /// <summary>Ends the application after the current event, like the VCL Application.Terminate.</summary>
    class procedure Terminate; static;
    /// <summary>
    ///   Raises OnActivated on the UI thread. RADWinUI.Notifications calls it when
    ///   the user clicks a notification while the app runs.
    /// </summary>
    class procedure NotifyActivated(const AActivation: TWinUIActivation); static;
    /// <summary>The activation of a notification click, for NotifyActivated.</summary>
    class function NotificationActivation(const AArgs: IAppNotificationActivatedEventArgs): TWinUIActivation; static;
    /// <summary>
    ///   Makes Windows start this program for files with these extensions
    ///   ('.txt'), shown as ADisplayName in Open with. The app receives them in
    ///   OnActivated, Kind File. For an app installed without MSIX: call it from
    ///   the setup or on first run, and UnregisterFileTypes on uninstall.
    /// </summary>
    class procedure RegisterFileTypes(const AExtensions: array of string; const ADisplayName: string); static;
    class procedure UnregisterFileTypes(const AExtensions: array of string); static;
    /// <summary>
    ///   Makes Windows start this program for links such as myapp://open/42. The
    ///   app receives them in OnActivated, Kind Protocol.
    /// </summary>
    class procedure RegisterProtocol(const AScheme, ADisplayName: string); static;
    class procedure UnregisterProtocol(const AScheme: string); static;
    /// <summary>Like the VCL Application.OnException, Sender is the application.</summary>
    class property OnException: TWinUIExceptionEvent read FOnException write FOnException;
    /// <summary>
    ///   Set before Run: a second start of the program hands its activation (files,
    ///   link, arguments) to the running one, which comes to the front and gets
    ///   OnActivated, and the second process ends without showing a window.
    /// </summary>
    class property SingleInstance: Boolean read FSingleInstance write FSingleInstance;
    /// <summary>
    ///   Raised once after the main window is shown, with how the app was started,
    ///   and again for every later activation: a notification click, or another
    ///   start of a SingleInstance app. Always on the UI thread.
    /// </summary>
    class property OnActivated: TWinUIActivatedEvent read FOnActivated write FOnActivated;
    /// <summary>How the app was started, readable from the main window's constructor on.</summary>
    class property LaunchActivation: TWinUIActivation read FLaunchActivation;
    /// <summary>The window Run created, nil once it is freed.</summary>
    class property MainWindow: TWinUIWindow read FMainWindow;
    /// <summary>MainWindow (the default, as in the VCL) or LastWindow, see TWinUIShutdownMode.</summary>
    class property ShutdownMode: TWinUIShutdownMode read FShutdownMode write FShutdownMode;
    /// <summary>Every window of the app that is not freed yet, oldest first.</summary>
    class function Windows: TArray<TWinUIWindow>; static;
    class function WindowCount: Integer; static;
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

type
  TDwmMargins = record
    Left, Right, Top, Bottom: Integer;
  end;

function DwmExtendFrameIntoClientArea(AWnd: HWND; const AMargins: TDwmMargins): HRESULT; stdcall;
  external 'dwmapi.dll' name 'DwmExtendFrameIntoClientArea';

const
  GCLP_HBRBACKGROUND = -10;
  DWM_BB_ENABLE = 1;
  DWM_BB_BLURREGION = 2;

type
  TDwmBlurBehind = record
    Flags: DWORD;
    Enable: BOOL;
    BlurRegion: HRGN;
    TransitionOnMaximized: BOOL;
  end;

function DwmEnableBlurBehindWindow(AWnd: HWND; const ABlurBehind: TDwmBlurBehind): HRESULT; stdcall;
  external 'dwmapi.dll' name 'DwmEnableBlurBehindWindow';

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
      // Closed some other way than Close (the app ends, the owner went): a modal caller still gets its answer
      if Me.FModal and (Me.FModalResult = mrNone) then
        Me.FModalResult := mrCancel;
      Me.EndModal;
      TWinUIApp.WindowClosed(Me);
      DispatcherQueue.TryEnqueue(TDispatcherQueueHandler.Create(
        procedure
        begin
          if IsAlive(Me) then
            Me.Free;
        end));
    end));
  // Its overlapped presenter, to come back to after FullScreen or CompactOverlay
  FOverlapped := AppWindow.Presenter;
  // The close button and Alt+F4 follow the rules of Close
  AppWindow.Closing.Add(
    procedure(Sender: TObject; E: TWinUIAppWindowClosingEventArgs)
    begin
      if FClosing then
        Exit;
      case CloseAction of
        TWinUICloseAction.Free:
          FClosing := True; // WinUI goes on closing it
        TWinUICloseAction.Hide:
          begin
            E.Cancel := True;
            Hide;
          end;
      else
        E.Cancel := True;
      end;
    end);
end;

destructor TWinUIWindow.Destroy;
var
  I: Integer;
  W: TWinUIWindow;
begin
  for I := High(FWindows) downto 0 do
    if FWindows[I] = Self then
      Delete(FWindows, I, 1);
  for W in FWindows do
    if W.FOwnerWindow = Self then
      W.FOwnerWindow := nil;
  TWinUIApp.WindowGone(Self);
  if Assigned(CustomXamlOwnerGone) then
    CustomXamlOwnerGone(Self);
  inherited;
end;

class function TWinUIWindow.Active: TWinUIWindow;
var
  W: TWinUIWindow;
  Foreground: HWND;
begin
  Foreground := GetForegroundWindow;
  for W in FWindows do
    if W.Handle = Foreground then
      Exit(W);
  if Length(FWindows) > 0 then
    Result := FWindows[High(FWindows)]
  else
    Result := nil;
end;

procedure TWinUIWindow.BringToFront;
begin
  if IsIconic(Handle) then
    ShowWindow(Handle, SW_RESTORE);
  Activate;
  SetForegroundWindow(Handle);
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
  // The window's own one, also while FullScreen or CompactOverlay shows: its settings wait for it there
  if FOverlapped = nil then
    FOverlapped := AppWindow.Presenter;
  Result := FOverlapped as TWinUIOverlappedPresenter;
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
  // A Transparent window has no backdrop to give up: its content paints what shows
  if FTransparency or (FBackdrop = TWinUIBackdrop.Transparent) then
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
  if FTransparency or (FBackdrop in [TWinUIBackdrop.None, TWinUIBackdrop.Transparent]) then
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
  Frameless, SeeThrough, Blur: Boolean;
  Corner, Border, Policy: DWORD;
  Margins: TDwmMargins;
  BlurBehind: TDwmBlurBehind;
begin
  Frameless := (FWindowStyle = TWinUIWindowStyle.Overlay) or (FBackdrop = TWinUIBackdrop.Transparent);
  SeeThrough := FBackdrop = TWinUIBackdrop.Transparent;
  if Frameless then
  begin
    Corner := DWMWCP_DONOTROUND;
    Border := DWMWA_COLOR_NONE;
  end
  else
  begin
    Corner := DWMWCP_DEFAULT;
    Border := DWMWA_COLOR_DEFAULT;
  end;
  // DWM paints a window's client area black behind the XAML content unless
  // its frame extends over all of it. That needs DWM's non-client rendering.
  if Frameless and not SeeThrough then
    Policy := DWMNCRP_DISABLED
  else
    Policy := DWMNCRP_USEWINDOWSTYLE;
  DwmSetWindowAttribute(Handle, DWMWA_WINDOW_CORNER_PREFERENCE, @Corner, SizeOf(Corner));
  DwmSetWindowAttribute(Handle, DWMWA_BORDER_COLOR, @Border, SizeOf(Border));
  DwmSetWindowAttribute(Handle, DWMWA_NCRENDERING_POLICY, @Policy, SizeOf(Policy));
  // Only undone when this window did it: WinUI manages the frame of the others
  if SeeThrough or FFrameExtended then
  begin
    Margins := Default(TDwmMargins);
    if SeeThrough then
    begin
      Margins.Left := -1;
      Margins.Right := -1;
      Margins.Top := -1;
      Margins.Bottom := -1;
    end;
    DwmExtendFrameIntoClientArea(Handle, Margins);
    FFrameExtended := SeeThrough;
  end;
  // A see-through window that keeps its frame: DWM paints the caption colour
  // (the accent colour, or white or black) behind the content. Blur behind an
  // empty region makes DWM take the content's alpha instead, so the desktop
  // shows through. An overlay has no caption and needs none of this.
  Blur := SeeThrough and (FWindowStyle <> TWinUIWindowStyle.Overlay);
  if Blur or FBlurBehind then
  begin
    BlurBehind := Default(TDwmBlurBehind);
    BlurBehind.Flags := DWM_BB_ENABLE;
    BlurBehind.Enable := Blur;
    if Blur then
    begin
      BlurBehind.Flags := BlurBehind.Flags or DWM_BB_BLURREGION;
      BlurBehind.BlurRegion := CreateRectRgn(-2, -2, -1, -1);
    end;
    DwmEnableBlurBehindWindow(Handle, BlurBehind);
    if BlurBehind.BlurRegion <> 0 then
      DeleteObject(BlurBehind.BlurRegion);
    // Blur behind takes black as see-through, so the window background must be black
    if Blur <> FClassBrushSet then
    begin
      if Blur then
        FClassBrush := SetClassLongPtr(Handle, GCLP_HBRBACKGROUND, LONG_PTR(GetStockObject(BLACK_BRUSH)))
      else
        SetClassLongPtr(Handle, GCLP_HBRBACKGROUND, FClassBrush);
      FClassBrushSet := Blur;
    end;
    InvalidateRect(Handle, nil, True);
    FBlurBehind := Blur;
    Subclass;
  end;
  UpdateSeeThroughTheme;
end;

function SystemUsesLightTheme: Boolean;
var
  Key: HKEY;
  Value, Size: DWORD;
begin
  Result := True;
  if RegOpenKeyEx(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize', 0,
    KEY_READ, Key) <> ERROR_SUCCESS then
    Exit;
  Size := SizeOf(Value);
  if RegQueryValueEx(Key, 'AppsUseLightTheme', nil, nil, @Value, @Size) = ERROR_SUCCESS then
    Result := Value <> 0;
  RegCloseKey(Key);
end;

// Under blur behind, the window behind the XAML content is painted white when
// the root element is light, and only a dark root lets the desktop through.
// So the root is kept dark and its children get the theme it would have had.
procedure TWinUIWindow.UpdateSeeThroughTheme;
var
  Root: TWinUIPanel;
  Child: TWinUIUIElement;
  Element: TWinUIFrameworkElement;
  Theme: TWinUIElementTheme;
  I: Integer;
begin
  if not (Content is TWinUIPanel) then
    Exit;
  Root := TWinUIPanel(Content);
  if not FBlurBehind then
  begin
    if FDarkRoot then
    begin
      for Element in FThemedChildren do
        Element.RequestedTheme := TWinUIElementTheme.Default;
      FThemedChildren := nil;
      Root.RequestedTheme := FRootTheme;
      FDarkRoot := False;
    end;
    Exit;
  end;
  if not FDarkRoot then
  begin
    FRootTheme := Root.RequestedTheme;
    Root.RequestedTheme := TWinUIElementTheme.Dark;
    FDarkRoot := True;
  end;
  Theme := FRootTheme;
  if Theme = TWinUIElementTheme.Default then
    if SystemUsesLightTheme then
      Theme := TWinUIElementTheme.Light
    else
      Theme := TWinUIElementTheme.Dark;
  for I := 0 to Root.Children.Count - 1 do
  begin
    Child := Root.Children[I];
    if (Child is TWinUIFrameworkElement) and
      (TWinUIFrameworkElement(Child).RequestedTheme = TWinUIElementTheme.Default) then
      FThemedChildren := FThemedChildren + [TWinUIFrameworkElement(Child)];
  end;
  for Element in FThemedChildren do
    Element.RequestedTheme := Theme;
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
      begin
        if FDock <> TWinUIDock.None then
          DispatcherQueue.TryEnqueue(TDispatcherQueueHandler.Create(
            procedure
            begin
              ApplyDock;
            end));
        // A light or dark theme switch in Windows Settings
        if FDarkRoot and (AMsg = WM_SETTINGCHANGE) then
          DispatcherQueue.TryEnqueue(TDispatcherQueueHandler.Create(
            procedure
            begin
              UpdateSeeThroughTheme;
            end));
      end;
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
  UpdateSeeThroughTheme;
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
  // A maximized window would fill a real display: test windows stay where they are put
  FMaximizeOnShow := False;
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
  if FMaximizeOnShow then
  begin
    FMaximizeOnShow := False;
    Presenter.Maximize;
  end;
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

{ TWinUIWindow: closing, modal windows and owners }

class function TWinUIWindow.Windows: TArray<TWinUIWindow>;
begin
  Result := Copy(FWindows);
end;

// OnCloseQuery, then OnClose: None when the window stays
function TWinUIWindow.CloseAction: TWinUICloseAction;
var
  CanClose: Boolean;
begin
  CanClose := True;
  if Assigned(FOnCloseQuery) then
    FOnCloseQuery(Self, CanClose);
  if not CanClose then
  begin
    FModalResult := mrNone; // as in the VCL, the modal window stays open with no result
    Exit(TWinUICloseAction.None);
  end;
  Result := TWinUICloseAction.Free;
  if Assigned(FOnClose) then
    FOnClose(Self, Result);
  if Result <> TWinUICloseAction.None then
  begin
    if FModal and (FModalResult = mrNone) then
      FModalResult := mrCancel;
    EndModal;
  end;
end;

procedure TWinUIWindow.Close;
begin
  if FClosing then
    Exit;
  case CloseAction of
    TWinUICloseAction.Free:
      begin
        FClosing := True;
        inherited Close;
      end;
    TWinUICloseAction.Hide:
      Hide;
  end;
end;

procedure TWinUIWindow.Hide;
begin
  AppWindow.Hide;
end;

procedure TWinUIWindow.ShowModal(const AOnClose: TProc<TModalResult>);
var
  W, Owner: TWinUIWindow;
  Foreground: HWND;
begin
  if FOwnerWindow = nil then
  begin
    // The window in use: the foreground one, else the main window, else the newest other visible one
    Owner := nil;
    Foreground := GetForegroundWindow;
    for W in FWindows do
      if (W <> Self) and W.AppWindow.IsVisible and (W.Handle = Foreground) then
        Owner := W;
    if (Owner = nil) and (TWinUIApp.MainWindow <> nil) and (TWinUIApp.MainWindow <> Self) and
      TWinUIApp.MainWindow.AppWindow.IsVisible then
      Owner := TWinUIApp.MainWindow;
    if Owner = nil then
      for W in FWindows do
        if (W <> Self) and W.AppWindow.IsVisible then
          Owner := W;
    if Owner <> nil then
      OwnerWindow := Owner;
  end;
  FModal := True;
  FModalResult := mrNone;
  FModalDone := AOnClose;
  if FOwnerWindow <> nil then
    EnableWindow(FOwnerWindow.Handle, False);
  CenterOnOwner;
  Show;
end;

procedure TWinUIWindow.EndModal;
var
  Done: TProc<TModalResult>;
  Owner: TWinUIWindow;
begin
  if not FModal then
    Exit;
  FModal := False;
  Owner := FOwnerWindow;
  if (Owner <> nil) and IsAlive(Owner) then
  begin
    EnableWindow(Owner.Handle, True);
    // A window disabled meanwhile does not get the focus back by itself, test runs leave the focus alone
    if GetEnvironmentVariable('RADWINUI_TEST_MONITOR') = '' then
      SetForegroundWindow(Owner.Handle);
  end;
  Done := FModalDone;
  FModalDone := nil;
  if Assigned(Done) then
    Done(FModalResult);
end;

procedure TWinUIWindow.SetModalResult(AValue: TModalResult);
begin
  FModalResult := AValue;
  if FModal and (AValue <> mrNone) then
    Close;
end;

procedure TWinUIWindow.SetOwnerWindow(AValue: TWinUIWindow);
begin
  if AValue = Self then
    raise EArgumentException.Create('A window cannot own itself');
  FOwnerWindow := AValue;
  // A Windows owner: the window stays above it, is minimized with it and goes with it
  if AValue = nil then
    SetWindowLongPtr(Handle, GWLP_HWNDPARENT, 0)
  else
    SetWindowLongPtr(Handle, GWLP_HWNDPARENT, LONG_PTR(AValue.Handle));
end;

procedure TWinUIWindow.CenterOnOwner;
var
  Outer: RectInt32;
  Size: SizeInt32;
  Pos: PointInt32;
begin
  if (FOwnerWindow = nil) or not IsAlive(FOwnerWindow) then
  begin
    Center;
    Exit;
  end;
  Outer.X := FOwnerWindow.AppWindow.Position.X;
  Outer.Y := FOwnerWindow.AppWindow.Position.Y;
  Outer.Width := FOwnerWindow.AppWindow.Size.Width;
  Outer.Height := FOwnerWindow.AppWindow.Size.Height;
  Size := AppWindow.Size;
  Pos.X := Outer.X + (Outer.Width - Size.Width) div 2;
  Pos.Y := Outer.Y + (Outer.Height - Size.Height) div 2;
  AppWindow.Move(Pos);
end;

{ TWinUIWindow: position, size and state }

function TWinUIWindow.GetLeft: Integer;
begin
  Result := Round(AppWindow.Position.X / Scale);
end;

function TWinUIWindow.GetTop: Integer;
begin
  Result := Round(AppWindow.Position.Y / Scale);
end;

procedure TWinUIWindow.SetLeft(AValue: Integer);
var
  Pos: PointInt32;
begin
  Pos := AppWindow.Position;
  Pos.X := Round(AValue * Scale);
  AppWindow.Move(Pos);
end;

procedure TWinUIWindow.SetTop(AValue: Integer);
var
  Pos: PointInt32;
begin
  Pos := AppWindow.Position;
  Pos.Y := Round(AValue * Scale);
  AppWindow.Move(Pos);
end;

procedure TWinUIWindow.SetMaxWidth(AValue: Integer);
begin
  FMaxWidth := AValue;
  if AValue <= 0 then
    Presenter.PreferredMaximumWidth := nil
  else
    Presenter.PreferredMaximumWidth := PropertyValue.CreateInt32(Round(AValue * Scale)) as IReference_Int32;
end;

procedure TWinUIWindow.SetMaxHeight(AValue: Integer);
begin
  FMaxHeight := AValue;
  if AValue <= 0 then
    Presenter.PreferredMaximumHeight := nil
  else
    Presenter.PreferredMaximumHeight := PropertyValue.CreateInt32(Round(AValue * Scale)) as IReference_Int32;
end;

function TWinUIWindow.GetWindowState: TWinUIWindowState;
begin
  case AppWindow.Presenter.Kind of
    TWinUIAppWindowPresenterKind.FullScreen:
      Result := TWinUIWindowState.FullScreen;
    TWinUIAppWindowPresenterKind.CompactOverlay:
      Result := TWinUIWindowState.CompactOverlay;
  else
    case Presenter.State of
      TWinUIOverlappedPresenterState.Minimized:
        Result := TWinUIWindowState.Minimized;
      TWinUIOverlappedPresenterState.Maximized:
        Result := TWinUIWindowState.Maximized;
    else
      Result := TWinUIWindowState.Normal;
    end;
  end;
end;

procedure TWinUIWindow.SetWindowState(AValue: TWinUIWindowState);
begin
  // Maximize would show the window at once: before Show, Show maximizes it
  FMaximizeOnShow := (AValue = TWinUIWindowState.Maximized) and not AppWindow.IsVisible;
  if FMaximizeOnShow then
    Exit;
  case AValue of
    TWinUIWindowState.FullScreen:
      AppWindow.SetPresenter(TWinUIAppWindowPresenterKind.FullScreen);
    TWinUIWindowState.CompactOverlay:
      AppWindow.SetPresenter(TWinUIAppWindowPresenterKind.CompactOverlay);
  else
    if AppWindow.Presenter.Kind <> TWinUIAppWindowPresenterKind.Overlapped then
      AppWindow.SetPresenter(Presenter);
    case AValue of
      TWinUIWindowState.Minimized:
        Presenter.Minimize;
      TWinUIWindowState.Maximized:
        Presenter.Maximize;
    else
      Presenter.Restore;
    end;
  end;
end;

function TWinUIWindow.GetResizable: Boolean;
begin
  Result := Presenter.IsResizable;
end;

procedure TWinUIWindow.SetResizable(AValue: Boolean);
begin
  Presenter.IsResizable := AValue;
end;

function TWinUIWindow.GetMinimizable: Boolean;
begin
  Result := Presenter.IsMinimizable;
end;

procedure TWinUIWindow.SetMinimizable(AValue: Boolean);
begin
  Presenter.IsMinimizable := AValue;
end;

function TWinUIWindow.GetMaximizable: Boolean;
begin
  Result := Presenter.IsMaximizable;
end;

procedure TWinUIWindow.SetMaximizable(AValue: Boolean);
begin
  Presenter.IsMaximizable := AValue;
end;

// "Normal,left,top,right,bottom" or "Maximized,...": the restored frame in Windows' workspace pixels
function TWinUIWindow.GetPlacement: string;
var
  P: TWindowPlacement;
  State: string;
begin
  P.length := SizeOf(P);
  if not GetWindowPlacement(Handle, @P) then
    Exit('');
  if (P.showCmd = SW_SHOWMAXIMIZED) or FMaximizeOnShow or (WindowState = TWinUIWindowState.Maximized) then
    State := 'Maximized'
  else
    State := 'Normal';
  Result := Format('%s,%d,%d,%d,%d', [State, P.rcNormalPosition.Left, P.rcNormalPosition.Top,
    P.rcNormalPosition.Right, P.rcNormalPosition.Bottom]);
end;

procedure TWinUIWindow.SetPlacement(const AValue: string);
var
  Parts: TArray<string>;
  P: TWindowPlacement;
  R: TRect;
  Maximized: Boolean;
begin
  Parts := AValue.Split([',']);
  if Length(Parts) <> 5 then
    Exit;
  Maximized := SameText(Parts[0], 'Maximized');
  R := TRect.Create(StrToIntDef(Parts[1], 0), StrToIntDef(Parts[2], 0), StrToIntDef(Parts[3], 0),
    StrToIntDef(Parts[4], 0));
  if (R.Width <= 0) or (R.Height <= 0) then
    Exit;
  P.length := SizeOf(P);
  GetWindowPlacement(Handle, @P);
  P.rcNormalPosition := R;
  P.flags := 0;
  // A hidden window stays hidden, Show maximizes it later
  if not AppWindow.IsVisible then
    P.showCmd := SW_HIDE
  else if Maximized then
    P.showCmd := SW_SHOWMAXIMIZED
  else
    P.showCmd := SW_SHOWNORMAL;
  SetWindowPlacement(Handle, @P);
  FMaximizeOnShow := Maximized and not AppWindow.IsVisible;
  // A display that is gone: the window comes back on the nearest one
  if MonitorFromRect(@R, MONITOR_DEFAULTTONULL) = 0 then
    CenterOnOwner;
end;

function RegSetKeyValue(AKey: HKEY; ASubKey, AValueName: PChar; AType: DWORD; AData: Pointer;
  ASize: DWORD): Longint; stdcall; external advapi32 name 'RegSetKeyValueW';
function RegGetValue(AKey: HKEY; ASubKey, AValueName: PChar; AFlags: DWORD; AType: PDWORD; AData: Pointer;
  ASize: PDWORD): Longint; stdcall; external advapi32 name 'RegGetValueW';

function PlacementKey: string;
begin
  Result := 'Software\' + ChangeFileExt(ExtractFileName(ParamStr(0)), '') + '\Placement';
end;

procedure TWinUIWindow.SavePlacement(const AName: string);
var
  Name, Value: string;
begin
  Name := AName;
  if Name = '' then
    Name := ClassName;
  Value := Placement;
  if Value <> '' then
    RegSetKeyValue(HKEY_CURRENT_USER, PChar(PlacementKey), PChar(Name), REG_SZ, PChar(Value),
      (Length(Value) + 1) * SizeOf(Char));
end;

function TWinUIWindow.RestorePlacement(const AName: string): Boolean;
const
  RRF_RT_REG_SZ = $00000002;
var
  Name: string;
  Buffer: array[0..255] of Char;
  Size: DWORD;
begin
  Name := AName;
  if Name = '' then
    Name := ClassName;
  Size := SizeOf(Buffer);
  Result := RegGetValue(HKEY_CURRENT_USER, PChar(PlacementKey), PChar(Name), RRF_RT_REG_SZ, nil, @Buffer,
    @Size) = ERROR_SUCCESS;
  if Result then
    Placement := Buffer;
end;

{ TWinUIWindow: icon and title bar }

procedure TWinUIWindow.SetIcon(const AFileName: string);
begin
  AppWindow.SetIcon(AFileName);
end;

procedure TWinUIWindow.UseTitleBar(AElement: TWinUIUIElement);
begin
  ExtendsContentIntoTitleBar := True;
  SetTitleBar(AElement);
  // The caption buttons follow the app's light or dark theme
  AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.UseDefaultAppMode;
end;

procedure TWinUIWindow.SetTitleBarPassthrough(const AElements: array of TWinUIFrameworkElement);
var
  I: Integer;
begin
  for I := 0 to High(FPassthrough) do
    if FPassthroughListeners[I] <> 0 then
      FPassthrough[I].LayoutUpdated.Remove(FPassthroughListeners[I] - 1);
  SetLength(FPassthrough, Length(AElements));
  SetLength(FPassthroughListeners, Length(AElements));
  for I := 0 to High(AElements) do
  begin
    FPassthrough[I] := AElements[I];
    // Every layout pass: the rectangles follow the element when the window is resized
    FPassthroughListeners[I] := 1 + AElements[I].LayoutUpdated.Add(
      procedure(Sender: TObject; E: TWinValue)
      begin
        UpdatePassthrough;
      end);
  end;
  UpdatePassthrough;
end;

procedure TWinUIWindow.UpdatePassthrough;
var
  Source: IInputNonClientPointerSource;
  Rects: TArray<RectInt32>;
  Element: IFrameworkElement;
  Bounds: RADWinUI.Abi.Rect;
  S: Double;
  I: Integer;
begin
  Source := InputNonClientPointerSource.GetForWindowId(AppWindow.Id);
  S := Scale;
  SetLength(Rects, Length(FPassthrough));
  for I := 0 to High(FPassthrough) do
  begin
    Element := TWinUIObject.IntfOf(FPassthrough[I], IFrameworkElement) as IFrameworkElement;
    Bounds.X := 0;
    Bounds.Y := 0;
    Bounds.Width := Element.ActualWidth;
    Bounds.Height := Element.ActualHeight;
    Bounds := (Element as IUIElement).TransformToVisual(nil).TransformBounds(Bounds);
    Rects[I].X := Floor(Bounds.X * S);
    Rects[I].Y := Floor(Bounds.Y * S);
    Rects[I].Width := Ceil(Bounds.Width * S);
    Rects[I].Height := Ceil(Bounds.Height * S);
  end;
  if Length(Rects) = 0 then
    Source.ClearRegionRects(NonClientRegionKind.Passthrough)
  else
    Source.SetRegionRects(NonClientRegionKind.Passthrough, Length(Rects), @Rects[0]);
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
  FDispatcher := DispatcherQueue.GetForCurrentThread;
  try
    FMainWindow := FMainWindowClass.Create;
    FMainWindow.Show;
  except
    on E: Exception do
    begin
      // Without its main window the application has nothing to show: report and exit.
      HandleException(E);
      Instance.Exit;
      Exit;
    end;
  end;
  // After the main window's own Loaded handlers, like every later activation
  Queue(
    procedure
    begin
      CallActivated(FLaunchActivation, False);
    end);
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
  // The runtime holds the Activated handler until it is removed
  if FMainInstance <> nil then
    FMainInstance.remove_Activated(FActivatedToken);
  FMainInstance := nil;
  FDispatcher := nil;
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
  BeforeApplicationStart := StartInstance;
  inherited Run;
end;

{ Activation }

function TWinUIActivation.Input(const AId: string): string;
var
  Pair: string;
begin
  for Pair in Inputs do
    if SameText(Copy(Pair, 1, Length(AId) + 1), AId + '=') then
      Exit(Copy(Pair, Length(AId) + 2, MaxInt));
  Result := '';
end;

// The command line without the program name, as ParamStr sees it
function CommandLineArguments: string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to ParamCount do
  begin
    if Result <> '' then
      Result := Result + ' ';
    if Pos(' ', ParamStr(I)) > 0 then
      Result := Result + '"' + ParamStr(I) + '"'
    else
      Result := Result + ParamStr(I);
  end;
end;

// An app without package identity gets the whole command line, program name included
function WithoutProgramName(const ACommandLine: string): string;
var
  S, Name: string;
  P: Integer;
begin
  S := TrimLeft(ACommandLine);
  if S.StartsWith('"') then
    P := Pos('"', S, 2)
  else
    P := Pos(' ', S);
  if P = 0 then
    P := Length(S);
  Name := ExtractFileName(Copy(S, 1, P).Trim(['"', ' ']));
  if SameText(ChangeFileExt(Name, ''), ChangeFileExt(ExtractFileName(ParamStr(0)), '')) then
    Result := Trim(Copy(S, P + 1, MaxInt))
  else
    Result := Trim(ACommandLine);
end;

function ActivationOf(const AArgs: IAppActivationArguments): TWinUIActivation;
var
  Launch: Windows_ApplicationModel_Activation_ILaunchActivatedEventArgs;
  FileArgs: IFileActivatedEventArgs;
  ProtocolArgs: IProtocolActivatedEventArgs;
  NotificationArgs: IAppNotificationActivatedEventArgs;
  Files: IVectorView_IStorageItem;
  Item: IStorageItem;
  I: Integer;
begin
  Result := Default(TWinUIActivation);
  Result.Kind := TWinUIActivationKind.Other;
  if AArgs = nil then
  begin
    Result.Kind := TWinUIActivationKind.Launch;
    Result.Arguments := CommandLineArguments;
    Exit;
  end;
  case AArgs.Kind of
    ExtendedActivationKind.Launch:
      begin
        Result.Kind := TWinUIActivationKind.Launch;
        if Supports(AArgs.Data, Windows_ApplicationModel_Activation_ILaunchActivatedEventArgs, Launch) then
          Result.Arguments := WithoutProgramName(TakeHString(Launch.get_Arguments))
        else
          Result.Arguments := CommandLineArguments;
      end;
    ExtendedActivationKind.&File:
      if Supports(AArgs.Data, IFileActivatedEventArgs, FileArgs) then
      begin
        Result.Kind := TWinUIActivationKind.&File;
        Files := FileArgs.get_Files;
        if Files <> nil then
          for I := 0 to Integer(Files.Size) - 1 do
          begin
            Item := Files.GetAt(I);
            if Item <> nil then
              Result.Files := Result.Files + [TakeHString(Item.get_Path)];
          end;
      end;
    ExtendedActivationKind.Protocol:
      if Supports(AArgs.Data, IProtocolActivatedEventArgs, ProtocolArgs) then
      begin
        Result.Kind := TWinUIActivationKind.Protocol;
        if ProtocolArgs.get_Uri <> nil then
          Result.Arguments := TakeHString(ProtocolArgs.get_Uri.get_AbsoluteUri);
      end;
    ExtendedActivationKind.AppNotification:
      if Supports(AArgs.Data, IAppNotificationActivatedEventArgs, NotificationArgs) then
        Result := TWinUIApp.NotificationActivation(NotificationArgs);
  end;
end;

class function TWinUIApp.NotificationActivation(const AArgs: IAppNotificationActivatedEventArgs): TWinUIActivation;
var
  Args2: IAppNotificationActivatedEventArgs2;
  Map: IMap_String_String;
  Pairs: IIterable_IKeyValuePair_String_String;
  It: IIterator_IKeyValuePair_String_String;
  Pair: IKeyValuePair_String_String;
begin
  Result := Default(TWinUIActivation);
  Result.Kind := TWinUIActivationKind.Notification;
  if AArgs = nil then
    Exit;
  // RADWinUI.Notifications stores the Argument under the key "arg"
  Result.Arguments := TakeHString(AArgs.get_Argument);
  if Supports(AArgs, IAppNotificationActivatedEventArgs2, Args2) then
  begin
    Map := Args2.get_Arguments;
    if (Map <> nil) and Map.HasKey(WinStr('arg')) then
      Result.Arguments := TakeHString(Map.Lookup(WinStr('arg')));
  end;
  Map := AArgs.get_UserInput;
  if Supports(Map, IIterable_IKeyValuePair_String_String, Pairs) then
  begin
    It := Pairs.First;
    while It.get_HasCurrent do
    begin
      Pair := It.get_Current;
      Result.Inputs := Result.Inputs + [TakeHString(Pair.get_Key) + '=' + TakeHString(Pair.get_Value)];
      It.MoveNext;
    end;
  end;
end;

function CoWaitForMultipleObjects(AFlags, ATimeout: DWORD; AHandleCount: ULONG; AHandles: PHandle;
  out AIndex: DWORD): HRESULT; stdcall; external 'ole32.dll';

class function TWinUIApp.StartInstance: Boolean;
var
  Args: IAppActivationArguments;
  Redirect: IAsyncAction;
  Activated: EventHandler_AppActivationArguments;
  Completed: AsyncActionCompletedHandler;
  Done: THandle;
  Index: DWORD;
begin
  Result := True;
  Args := AppInstance.GetCurrent.GetActivatedEventArgs;
  FLaunchActivation := ActivationOf(Args);
  if not FSingleInstance then
    Exit;
  FMainInstance := AppInstance.FindOrRegisterForKey(WinStr('main'));
  if FMainInstance.get_IsCurrent then
  begin
    // Later starts arrive on a thread pool thread, OnActivated runs on the UI thread.
    // The handler sits in a variable during the call: passed inline, its reference
    // count is 0 and the runtime's QueryInterface and Release would free it.
    Activated := TEventHandler_AppActivationArguments.Create(
      procedure(ASender: IInspectable; AArgs: IAppActivationArguments)
      var
        Activation: TWinUIActivation;
      begin
        Activation := ActivationOf(AArgs);
        Queue(
          procedure
          begin
            CallActivated(Activation, True);
          end);
      end);
    FActivatedToken := FMainInstance.add_Activated(Activated);
    Exit;
  end;
  // Another instance runs: let it come to the front, hand it this start and end.
  AllowSetForegroundWindow(FMainInstance.get_ProcessId);
  Done := CreateEvent(nil, True, False, nil);
  try
    Redirect := FMainInstance.RedirectActivationToAsync(Args);
    // In a variable for the same reason as Activated above
    Completed := TAsyncActionCompletedHandler.Create(
      procedure(AInfo: IAsyncAction; AStatus: AsyncStatus)
      begin
        SetEvent(Done);
      end);
    Redirect.Completed := Completed;
    // Pumps COM calls while it waits, the redirect needs them on this STA thread
    CoWaitForMultipleObjects(0, 10000, 1, @Done, Index);
  finally
    CloseHandle(Done);
  end;
  Redirect := nil;
  FMainInstance := nil;
  Result := False;
end;

class procedure TWinUIApp.Queue(const AProc: TProc);
begin
  if FDispatcher = nil then
    raise EWinUIBindError.Create('TWinUIApp.Queue needs the running application');
  FDispatcher.TryEnqueue(TDispatcherQueueHandler.Create(
    procedure
    begin
      try
        AProc;
      except
        on E: Exception do
          HandleException(E);
      end;
    end));
end;

class procedure TWinUIApp.Terminate;
begin
  if FInstance <> nil then
    FInstance.Instance.Exit;
end;

class procedure TWinUIApp.WindowClosed(AWindow: TWinUIWindow);
begin
  // LastWindow is WinUI's own rule: the app ends when its last window has closed
  if (AWindow = FMainWindow) and (FShutdownMode = TWinUIShutdownMode.MainWindow) then
    Terminate;
end;

class procedure TWinUIApp.WindowGone(AWindow: TWinUIWindow);
begin
  if AWindow = FMainWindow then
    FMainWindow := nil;
end;

class function TWinUIApp.Windows: TArray<TWinUIWindow>;
begin
  Result := TWinUIWindow.Windows;
end;

class function TWinUIApp.WindowCount: Integer;
begin
  Result := Length(TWinUIWindow.Windows);
end;

class procedure TWinUIApp.CallActivated(const AActivation: TWinUIActivation; ABringToFront: Boolean);
var
  Main: TWinUIWindow;
begin
  if ABringToFront then
  begin
    Main := TWinUIWindow.Active;
    if Main <> nil then
      Main.BringToFront;
  end;
  if Assigned(FOnActivated) then
    FOnActivated(FInstance, AActivation);
end;

class procedure TWinUIApp.NotifyActivated(const AActivation: TWinUIActivation);
var
  Activation: TWinUIActivation;
begin
  Activation := AActivation;
  Queue(
    procedure
    begin
      CallActivated(Activation, True);
    end);
end;

function WinStrings(const AValues: array of string): TArray<TWinString>;
var
  I: Integer;
begin
  SetLength(Result, Length(AValues));
  for I := 0 to High(AValues) do
    Result[I] := AValues[I];
end;

class procedure TWinUIApp.RegisterFileTypes(const AExtensions: array of string; const ADisplayName: string);
var
  Types, Verbs: TArray<TWinString>;
begin
  if Length(AExtensions) = 0 then
    Exit;
  // TWinString holds one HSTRING, so the array is the HSTRING array WinRT expects
  Types := WinStrings(AExtensions);
  Verbs := WinStrings(['open']);
  ActivationRegistrationManager.RegisterForFileTypeActivation(Length(Types), @Types[0],
    WinStr(ParamStr(0) + ',0'), WinStr(ADisplayName), Length(Verbs), @Verbs[0], WinStr(ParamStr(0)));
end;

class procedure TWinUIApp.UnregisterFileTypes(const AExtensions: array of string);
var
  Types: TArray<TWinString>;
begin
  if Length(AExtensions) = 0 then
    Exit;
  Types := WinStrings(AExtensions);
  ActivationRegistrationManager.UnregisterForFileTypeActivation(Length(Types), @Types[0], WinStr(ParamStr(0)));
end;

class procedure TWinUIApp.RegisterProtocol(const AScheme, ADisplayName: string);
begin
  ActivationRegistrationManager.RegisterForProtocolActivation(WinStr(AScheme), WinStr(ParamStr(0) + ',0'),
    WinStr(ADisplayName), WinStr(ParamStr(0)));
end;

class procedure TWinUIApp.UnregisterProtocol(const AScheme: string);
begin
  ActivationRegistrationManager.UnregisterForProtocolActivation(WinStr(AScheme), WinStr(ParamStr(0)));
end;

end.
