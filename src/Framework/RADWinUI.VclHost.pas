unit RADWinUI.VclHost;

(*
  TWinUIHost: WinUI content inside a VCL form (XAML Islands, DesktopWindowXamlSource).

  Drop it on a VCL form, write the XAML in Xaml (or name a file in XamlFile), then
  use the elements from code once the content is loaded:

    procedure TMainForm.WinUIHost1Loaded(Sender: TObject);
    begin
      WinUIHost1.DataContext := FCustomer;  // {Binding} in the XAML
      WinUIHost1.FindElement<TWinUITextBox>('NameBox').Text := 'Ada';
    end;

  Events: an attribute such as Click="SaveClick" names a published method of the
  form, procedure(Sender: TObject), and so does a method <x:Name><Event>
  (SaveButtonClick). The events wired this way are listed in EventNames; any
  other event is wired in code on the element (FindElement<T>.On<Event>).

  The first host starts WinUI on the VCL main thread (Windows App SDK bootstrap,
  DispatcherQueue, XAML application, WindowsXamlManager), and the unit's
  finalization shuts it down after the last message. A VCL app with hosts does not
  also call TWinUIApp.Run.

  Built into the IDE package (RADWINUI_DESIGNTIME defined), the control is plain
  VCL and paints a placeholder: no WinUI code runs in the IDE process.
*)

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls
  {$IFNDEF RADWINUI_DESIGNTIME},
  RADWinUI.Interop.Core,
  RADWinUI.Abi,
  RADWinUI.Framework,
  RADWinUI.Xaml
  {$ENDIF};

type
  /// <summary>htAuto: light or dark from the host's Color, so the text stays readable on it.</summary>
  TWinUIHostTheme = (htAuto, htLight, htDark);

  EWinUIHostError = class(Exception);

  TWinUIHost = class(TCustomControl)
  private
    FXaml: TStrings;
    FXamlFile: string;
    FTheme: TWinUIHostTheme;
    FLoadError: string;
    FOnLoaded: TNotifyEvent;
    procedure SetXaml(AValue: TStrings);
    procedure SetXamlFile(const AValue: string);
    procedure SetTheme(AValue: TWinUIHostTheme);
    procedure XamlChanged(Sender: TObject);
    function Summary: string;
    function BackgroundColor: TColor;
    procedure CMColorChanged(var Message: TMessage); message CM_COLORCHANGED;
  {$IFNDEF RADWINUI_DESIGNTIME}
  private type
    TEventLink = record
      Element, Event, Method: string;
      Explicit: Boolean;
    end;
  private
    FSource: IDesktopWindowXamlSource;
    FFrame: IPanel; // around the content: the theme's background, so the content needs none
    FContent: TWinUIFrameworkElement;
    FDataContext: TWinValue;
    FHasDataContext: Boolean;
    FFocusToken: EventRegistrationToken;
    function XamlText: string;
    function PrepareXaml(const AText: string; out ALinks: TArray<TEventLink>): string;
    procedure CreateContent;
    procedure ReleaseContent;
    procedure ApplyTheme;
    procedure ResizeContent;
    procedure WireEvents(const ALinks: TArray<TEventLink>);
    function GetDataContext: TWinValue;
    procedure SetDataContext(const AValue: TWinValue);
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
  protected
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
  {$ENDIF}
  protected
    procedure Loaded; override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// <summary>Loads the content again from Xaml or XamlFile.</summary>
    procedure Reload;
    /// <summary>Why the content did not load (also painted in the control), '' when it did.</summary>
    property LoadError: string read FLoadError;
  {$IFNDEF RADWINUI_DESIGNTIME}
    /// <summary>The element named AName (x:Name), nil when there is none.</summary>
    function FindElement<T: TWinUIObject>(const AName: string): T;
    /// <summary>The root element of the content, nil before it loads.</summary>
    property Content: TWinUIFrameworkElement read FContent;
    /// <summary>Source of the content's {Binding}s, kept when the content loads again.</summary>
    property DataContext: TWinValue read GetDataContext write SetDataContext;
  {$ENDIF}
  published
    /// <summary>The XAML of the content. The default namespaces are added when the root has none.</summary>
    property Xaml: TStrings read FXaml write SetXaml;
    /// <summary>
    ///   A .xaml file that holds the content, in place of Xaml (setting it clears Xaml). A relative
    ///   path is looked for next to the exe, then in the folders above it (the project folder of
    ///   an exe in Win64\Debug).
    /// </summary>
    property XamlFile: string read FXamlFile write SetXamlFile;
    property Theme: TWinUIHostTheme read FTheme write SetTheme default htAuto;
    /// <summary>After the content loaded and its events were wired.</summary>
    property OnLoaded: TNotifyEvent read FOnLoaded write FOnLoaded;
    property Align;
    property AlignWithMargins;
    property Anchors;
    property Color;
    property Constraints;
    property Enabled;
    property Margins;
    property ParentColor;
    property TabOrder;
    property TabStop default True;
    property Visible;
  end;

const
  /// <summary>The events a XAML attribute or a <x:Name><Event> method can wire.</summary>
  EventNames: array[0..12] of string = ('Click', 'Toggled', 'Checked', 'Unchecked', 'TextChanged',
    'PasswordChanged', 'SelectionChanged', 'ValueChanged', 'ItemClick', 'Loaded', 'Tapped', 'GotFocus',
    'LostFocus');

implementation

uses
  System.UITypes,
  System.StrUtils,
  System.TypInfo,
  System.IOUtils,
  System.RegularExpressions,
  Vcl.Forms,
  Vcl.Themes
  {$IFNDEF RADWINUI_DESIGNTIME},
  RADWinUI.Runtime.Bootstrap,
  RADWinUI.Runtime.Application
  {$ENDIF};

{$IFNDEF RADWINUI_DESIGNTIME}

{ WinUI on the VCL main thread, shared by every host }

type
  TPreTranslate = function(AMsg: PMsg): BOOL; stdcall;
  TWinControlAccess = class(TWinControl); // SelectNext is protected

var
  Started: Boolean;
  Controller: IDispatcherQueueController;
  Manager: IWindowsXamlManager;
  XamlApp: IInspectable;
  PreTranslate: TPreTranslate;
  MessageHook: HHOOK;
  Hosts: TArray<TWinUIHost>;

// WinUI needs its keyboard messages before VCL translates and dispatches them: Tab
// and arrow navigation, access keys, accelerators. A hook keeps Application.OnMessage
// free for the app.
function GetMessageHook(ACode: Integer; AWParam: WPARAM; ALParam: LPARAM): LRESULT; stdcall;
begin
  if (ACode = HC_ACTION) and (AWParam = PM_REMOVE) and (Hosts <> nil) and PreTranslate(PMsg(ALParam)) then
    PMsg(ALParam)^.message := WM_NULL;
  Result := CallNextHookEx(MessageHook, ACode, AWParam, ALParam);
end;

procedure StartWinUI;
var
  Hr: HRESULT;
  App: TWinUIApplication;
  Resources: IResourceDictionary;
  Core: HMODULE;
begin
  if Started then
    Exit;
  if GetCurrentThreadId <> MainThreadID then
    raise EWinUIHostError.Create('WinUI content is created on the main thread');
  TWinAppRuntime.Initialize;
  Hr := RoInitialize(RO_INIT_SINGLETHREADED);
  if Hr = RPC_E_CHANGED_MODE then
    raise EWinUIHostError.Create('WinUI needs a single-threaded apartment, the main thread is multithreaded (CoInitializeEx)');
  CheckWinRT(Hr, 'RoInitialize');
  Started := True;
  if DispatcherQueue.GetForCurrentThread = nil then
    Controller := DispatcherQueueController.CreateOnCurrentThread;
  // The order matters: the XAML application (it brings the controls' metadata), then
  // the thread's XAML manager, then the control styles. Any other order fails.
  App := TWinUIApplication.Create;
  XamlApp := App as IInspectable;
  Manager := WindowsXamlManager.InitializeForCurrentThread;
  Resources := ResourceDictionary.New;
  Resources.MergedDictionaries.Append(XamlControlsResources.New as IResourceDictionary);
  App.Instance.Resources := Resources;
  Core := GetModuleHandle('Microsoft.UI.Windowing.Core.dll');
  if Core = 0 then
    Core := LoadLibrary('Microsoft.UI.Windowing.Core.dll');
  @PreTranslate := GetProcAddress(Core, 'ContentPreTranslateMessage');
  if Assigned(PreTranslate) then
    MessageHook := SetWindowsHookEx(WH_GETMESSAGE, @GetMessageHook, 0, GetCurrentThreadId);
end;

procedure StopWinUI;
var
  Host: TWinUIHost;
begin
  if not Started then
    Exit;
  // The forms outlive this unit: their islands close now, while XAML still runs
  for Host in Copy(Hosts) do
    Host.ReleaseContent;
  if MessageHook <> 0 then
    UnhookWindowsHookEx(MessageHook);
  if Assigned(CustomXamlTypesRelease) then
    CustomXamlTypesRelease;
  (Manager as IClosable).Close;
  Manager := nil;
  XamlApp := nil;
  if Controller <> nil then
    (Controller as IDispatcherQueueController2).ShutdownQueue;
  Controller := nil;
  ClearFactoryCache;
  PinXamlModules;
  RoUninitialize;
  TWinAppRuntime.Shutdown;
end;

type
  // Delphi has no generic plain procedures
  TNotify = record
    class procedure Hook<T>(AEvent: TWinUIEvent<T>; AHandler: TNotifyEvent); static;
  end;

class procedure TNotify.Hook<T>(AEvent: TWinUIEvent<T>; AHandler: TNotifyEvent);
begin
  AEvent.Add(
    procedure(Sender: TObject; E: T)
    begin
      AHandler(Sender);
    end);
end;

// shortcut: a fixed list of events (RADWinUI.Xaml has no RTTI to find any event by name),
// add a line here when another event is asked for often.
function WireEvent(AElement: TWinUIObject; const AEvent: string; AHandler: TNotifyEvent): Boolean;
begin
  Result := True;
  if (AEvent = 'Click') and (AElement is TWinUIButtonBase) then
    TNotify.Hook<TWinUIRoutedEventArgs>(TWinUIButtonBase(AElement).Click, AHandler)
  else if (AEvent = 'Toggled') and (AElement is TWinUIToggleSwitch) then
    TNotify.Hook<TWinUIRoutedEventArgs>(TWinUIToggleSwitch(AElement).Toggled, AHandler)
  else if (AEvent = 'Checked') and (AElement is TWinUIToggleButton) then
    TNotify.Hook<TWinUIRoutedEventArgs>(TWinUIToggleButton(AElement).Checked, AHandler)
  else if (AEvent = 'Unchecked') and (AElement is TWinUIToggleButton) then
    TNotify.Hook<TWinUIRoutedEventArgs>(TWinUIToggleButton(AElement).Unchecked, AHandler)
  else if (AEvent = 'TextChanged') and (AElement is TWinUITextBox) then
    TNotify.Hook<TWinUITextChangedEventArgs>(TWinUITextBox(AElement).TextChanged, AHandler)
  else if (AEvent = 'PasswordChanged') and (AElement is TWinUIPasswordBox) then
    TNotify.Hook<TWinUIRoutedEventArgs>(TWinUIPasswordBox(AElement).PasswordChanged, AHandler)
  else if (AEvent = 'SelectionChanged') and (AElement is TWinUISelector) then
    TNotify.Hook<TWinUISelectionChangedEventArgs>(TWinUISelector(AElement).SelectionChanged, AHandler)
  else if (AEvent = 'ValueChanged') and (AElement is TWinUIRangeBase) then
    TNotify.Hook<TWinUIRangeBaseValueChangedEventArgs>(TWinUIRangeBase(AElement).ValueChanged, AHandler)
  else if (AEvent = 'ValueChanged') and (AElement is TWinUINumberBox) then
    TNotify.Hook<TWinUINumberBoxValueChangedEventArgs>(TWinUINumberBox(AElement).ValueChanged, AHandler)
  else if (AEvent = 'ItemClick') and (AElement is TWinUIListViewBase) then
    TNotify.Hook<TWinUIItemClickEventArgs>(TWinUIListViewBase(AElement).ItemClick, AHandler)
  else if (AEvent = 'Loaded') and (AElement is TWinUIFrameworkElement) then
    TNotify.Hook<TWinUIRoutedEventArgs>(TWinUIFrameworkElement(AElement).Loaded, AHandler)
  else if (AEvent = 'Tapped') and (AElement is TWinUIUIElement) then
    TNotify.Hook<TWinUITappedRoutedEventArgs>(TWinUIUIElement(AElement).Tapped, AHandler)
  else if (AEvent = 'GotFocus') and (AElement is TWinUIUIElement) then
    TNotify.Hook<TWinUIRoutedEventArgs>(TWinUIUIElement(AElement).GotFocus, AHandler)
  else if (AEvent = 'LostFocus') and (AElement is TWinUIUIElement) then
    TNotify.Hook<TWinUIRoutedEventArgs>(TWinUIUIElement(AElement).LostFocus, AHandler)
  else
    Result := False;
end;

function IsEventName(const AName: string): Boolean;
begin
  Result := MatchStr(AName, EventNames);
end;

{$ENDIF}

// Perceived brightness below the middle: light text reads on it
function IsDark(AColor: TColor): Boolean;
var
  RGB: TColorRef;
begin
  RGB := ColorToRGB(AColor);
  Result := GetRValue(RGB) * 3 + GetGValue(RGB) * 6 + GetBValue(RGB) < 128 * 10;
end;

{ TWinUIHost }

function TWinUIHost.BackgroundColor: TColor;
const
  // WinUI's SolidBackgroundFillColorBase in the light and the dark theme
  LightBackground = TColor($F3F3F3);
  DarkBackground = TColor($202020);
begin
  Result := StyleServices.GetSystemColor(Color);
  // Light or Dark keep the host's colour when it suits the theme, otherwise WinUI's own
  if (FTheme = htLight) and IsDark(Result) then
    Result := LightBackground
  else if (FTheme = htDark) and not IsDark(Result) then
    Result := DarkBackground;
end;

constructor TWinUIHost.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque] - [csSetCaption];
  FXaml := TStringList.Create;
  TStringList(FXaml).OnChange := XamlChanged;
  TabStop := True;
  Width := 320;
  Height := 200;
end;

destructor TWinUIHost.Destroy;
begin
  {$IFNDEF RADWINUI_DESIGNTIME}
  ReleaseContent;
  {$ENDIF}
  FXaml.Free;
  inherited;
end;

procedure TWinUIHost.SetXaml(AValue: TStrings);
begin
  FXaml.Assign(AValue);
end;

procedure TWinUIHost.SetXamlFile(const AValue: string);
begin
  if FXamlFile = AValue then
    Exit;
  FXamlFile := AValue;
  // The file takes over from inline XAML; clearing Xaml loads the content again
  if (AValue <> '') and (FXaml.Count > 0) then
    FXaml.Clear
  else
    XamlChanged(nil);
end;

procedure TWinUIHost.SetTheme(AValue: TWinUIHostTheme);
begin
  if FTheme = AValue then
    Exit;
  FTheme := AValue;
  {$IFNDEF RADWINUI_DESIGNTIME}
  ApplyTheme;
  {$ENDIF}
  Invalidate;
end;

procedure TWinUIHost.XamlChanged(Sender: TObject);
begin
  if not (csLoading in ComponentState) then
    Reload;
end;

procedure TWinUIHost.CMColorChanged(var Message: TMessage);
begin
  inherited;
  {$IFNDEF RADWINUI_DESIGNTIME}
  ApplyTheme;
  {$ENDIF}
end;

procedure TWinUIHost.Loaded;
begin
  inherited;
  Reload;
end;

procedure TWinUIHost.Reload;
begin
  {$IFNDEF RADWINUI_DESIGNTIME}
  ReleaseContent;
  if HandleAllocated and not (csDesigning in ComponentState) then
    CreateContent;
  {$ENDIF}
  Invalidate;
end;

function TWinUIHost.Summary: string;
var
  Match: TMatch;
begin
  if Trim(FXaml.Text) <> '' then
  begin
    Match := TRegEx.Match(FXaml.Text, '<([A-Za-z][\w.:]*)');
    if Match.Success then
      Result := '<' + Match.Groups[1].Value + '>, ' + IntToStr(FXaml.Count) + ' lines of XAML'
    else
      Result := IntToStr(FXaml.Count) + ' lines of XAML';
  end
  else if FXamlFile <> '' then
    Result := FXamlFile
  else
    Result := 'Set Xaml or XamlFile';
end;

procedure TWinUIHost.Paint;
var
  R: TRect;
  Text: string;
  Dark: Boolean;
begin
  R := ClientRect;
  Canvas.Brush.Color := BackgroundColor;
  Canvas.FillRect(R);
  Canvas.Font.Assign(Font);
  if FLoadError <> '' then
  begin
    // At run time the island covers the control, only a failed load shows through
    Canvas.Font.Color := clRed;
    Text := 'WinUI content did not load: ' + FLoadError;
    InflateRect(R, -8, -8);
    DrawText(Canvas.Handle, PChar(Text), -1, R, DT_WORDBREAK or DT_NOPREFIX);
    Exit;
  end;
  if not (csDesigning in ComponentState) then
    Exit;
  // Design time: a placeholder, the content shows when the app runs
  Dark := IsDark(Canvas.Brush.Color);
  Canvas.Pen.Style := psDash;
  if Dark then
    Canvas.Pen.Color := clSilver
  else
    Canvas.Pen.Color := clGray;
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(R);
  if Dark then
    Canvas.Font.Color := clWhite
  else
    Canvas.Font.Color := clBlack;
  Canvas.Font.Style := [fsBold];
  Text := 'WinUI content (' + Name + ')';
  InflateRect(R, -8, -8);
  DrawText(Canvas.Handle, PChar(Text), -1, R, DT_CENTER or DT_SINGLELINE or DT_NOPREFIX);
  Canvas.Font.Style := [];
  Inc(R.Top, Canvas.TextHeight('Wg') + 4);
  Text := Summary;
  DrawText(Canvas.Handle, PChar(Text), -1, R, DT_CENTER or DT_WORDBREAK or DT_NOPREFIX or DT_END_ELLIPSIS);
end;

{$IFNDEF RADWINUI_DESIGNTIME}

procedure TWinUIHost.CreateWnd;
begin
  inherited;
  if not (csLoading in ComponentState) and not (csDesigning in ComponentState) then
    CreateContent;
end;

procedure TWinUIHost.DestroyWnd;
begin
  // shortcut: a recreated handle loads the content again (element state is lost, OnLoaded
  // runs again), move the island to a parking window if a handle change ever has to keep it.
  ReleaseContent;
  inherited;
end;

function TWinUIHost.XamlText: string;
var
  Path, Folder: string;
  Level: Integer;
begin
  Result := FXaml.Text;
  if (Trim(Result) <> '') or (FXamlFile = '') then
    Exit;
  Path := FXamlFile;
  if TPath.IsRelativePath(Path) then
  begin
    // Next to the exe for a deployed app, the project folder while it runs from Win64\Debug
    Folder := ExtractFileDir(ParamStr(0));
    for Level := 0 to 2 do
    begin
      Path := TPath.Combine(Folder, FXamlFile);
      if FileExists(Path) then
        Break;
      Folder := ExtractFileDir(Folder);
    end;
    if not FileExists(Path) then
      raise EWinUIHostError.CreateFmt('XamlFile %s was not found next to the exe or in the two folders above it',
        [FXamlFile]);
  end;
  Result := TFile.ReadAllText(Path, TEncoding.UTF8);
end;

function TWinUIHost.PrepareXaml(const AText: string; out ALinks: TArray<TEventLink>): string;
const
  Presentation = 'http://schemas.microsoft.com/winfx/2006/xaml/presentation';
  XamlNs = 'http://schemas.microsoft.com/winfx/2006/xaml';
var
  Tags, Attrs: TMatchCollection;
  Tag, Attr: TMatch;
  Output, Rebuilt, ElementName, Name, Value, Method: string;
  Last, Generated, I: Integer;
  Link: TEventLink;
  Names: TArray<string>;
  IsRoot: Boolean;
begin
  ALinks := nil;
  Names := nil;
  Output := '';
  Last := 1;
  Generated := 0;
  IsRoot := True;
  // shortcut: start tags are found with a regular expression, enough for XAML written by hand
  // (no '>' inside attribute values); parse with an XML reader if that ever bites.
  Tags := TRegEx.Matches(AText, '<([A-Za-z_][\w.:-]*)((?:\s+[\w.:-]+\s*=\s*(?:"[^"]*"|''[^'']*''))*)\s*(/?)>');
  for Tag in Tags do
  begin
    Rebuilt := '';
    ElementName := '';
    Attrs := TRegEx.Matches(Tag.Groups[2].Value, '\s+([\w.:-]+)\s*=\s*(["''])(.*?)\2');
    for Attr in Attrs do
    begin
      Name := Attr.Groups[1].Value;
      Value := Attr.Groups[3].Value;
      if (Name = 'x:Name') or (Name = 'Name') then
        ElementName := Value;
      if IsEventName(Name) and IsValidIdent(Value) then
      begin
        Link.Element := '';
        Link.Event := Name;
        Link.Method := Value;
        Link.Explicit := True;
        ALinks := ALinks + [Link];
      end
      else
        Rebuilt := Rebuilt + Attr.Value;
    end;
    // Explicit events of an unnamed element: it gets a name to be found by after the load
    I := Length(ALinks) - 1;
    if (I >= 0) and (ALinks[I].Element = '') then
    begin
      if ElementName = '' then
      begin
        Inc(Generated);
        ElementName := '_rwHost' + IntToStr(Generated);
        Rebuilt := Rebuilt + ' x:Name="' + ElementName + '"';
      end;
      while (I >= 0) and (ALinks[I].Element = '') do
      begin
        ALinks[I].Element := ElementName;
        Dec(I);
      end;
    end;
    if ElementName <> '' then
      Names := Names + [ElementName];
    if IsRoot then
    begin
      // Inline XAML may leave out the namespaces
      if not Rebuilt.Contains('xmlns=') then
        Rebuilt := ' xmlns="' + Presentation + '"' + Rebuilt;
      if not Rebuilt.Contains('xmlns:x=') then
        Rebuilt := ' xmlns:x="' + XamlNs + '"' + Rebuilt;
      IsRoot := False;
    end;
    Output := Output + Copy(AText, Last, Tag.Index - Last) + '<' + Tag.Groups[1].Value + Rebuilt +
      IfThen(Tag.Groups[3].Value = '/', ' />', '>');
    Last := Tag.Index + Tag.Length;
  end;
  Result := Output + Copy(AText, Last, MaxInt);
  // The naming convention: <x:Name><Event> methods of the form
  if Owner <> nil then
    for Name in Names do
      for Value in EventNames do
      begin
        Method := Name + Value;
        if Owner.MethodAddress(Method) = nil then
          Continue;
        Link.Element := Name;
        Link.Event := Value;
        Link.Method := Method;
        Link.Explicit := False;
        ALinks := ALinks + [Link];
      end;
end;

procedure TWinUIHost.WireEvents(const ALinks: TArray<TEventLink>);
var
  Link: TEventLink;
  Element: TWinUIObject;
  Handler: TMethod;
begin
  for Link in ALinks do
  begin
    Handler.Data := Owner;
    Handler.Code := nil;
    if Owner <> nil then
      Handler.Code := Owner.MethodAddress(Link.Method);
    if Handler.Code = nil then
      raise EWinUIHostError.CreateFmt('%s="%s": %s has no published method %s', [Link.Event, Link.Method,
        IfThen(Owner <> nil, Owner.ClassName, Name), Link.Method]);
    Element := TWinUIObject.Wrap(FContent, FContent.FindName(Link.Element).Obj, TWinUIObject);
    if ((Element = nil) or not WireEvent(Element, Link.Event, TNotifyEvent(Handler))) and Link.Explicit then
      raise EWinUIHostError.CreateFmt('%s="%s": the element cannot raise %s from XAML here, wire it in code ' +
        '(FindElement<T>(''%s'').On%s)', [Link.Event, Link.Method, Link.Event, Link.Element, Link.Event]);
  end;
end;

procedure TWinUIHost.CreateContent;
var
  Links: TArray<TEventLink>;
  Text: string;
  Id: WindowId;
  Loaded: IInspectable;
  Previous: TObject;
begin
  FLoadError := '';
  try
    Text := XamlText;
    if Trim(Text) = '' then
      Exit;
    Text := PrepareXaml(Text, Links);
    StartWinUI;
    FSource := DesktopWindowXamlSource.New;
    Id.Value := UInt64(Handle);
    FSource.Initialize(Id);
    // Controls written in Delphi that this XAML creates belong to this host
    Previous := CustomXamlLoadOwner;
    CustomXamlLoadOwner := Self;
    try
      Loaded := XamlReader.Load(WinStr(Text));
    finally
      CustomXamlLoadOwner := Previous;
    end;
    FContent := TWinUIFrameworkElement(TWinUIObject.Wrap(nil, Loaded, TWinUIFrameworkElement));
    FFrame := Grid.New as IPanel;
    FFrame.Children.Append(Loaded as IUIElement);
    FSource.Content := FFrame as IUIElement;
    FFocusToken := FSource.add_TakeFocusRequested(
      TTypedEventHandler_DesktopWindowXamlSource_DesktopWindowXamlSourceTakeFocusRequestedEventArgs.Create(
      procedure(ASender: IDesktopWindowXamlSource; AArgs: IDesktopWindowXamlSourceTakeFocusRequestedEventArgs)
      var
        Form: TCustomForm;
      begin
        // Tab past the last element (First: the next entry comes in at the top), or Shift+Tab
        // before the first: the focus goes on to the form's next or previous control
        Form := GetParentForm(Self);
        if Form <> nil then
          TWinControlAccess(Form).SelectNext(Self, AArgs.Request.Reason <> XamlSourceFocusNavigationReason.Last, True);
      end));
    Hosts := Hosts + [Self];
    ApplyTheme;
    if FHasDataContext then
      FContent.DataContext := FDataContext;
    WireEvents(Links);
    ResizeContent;
    (FSource.SiteBridge as IDesktopSiteBridge).Show;
  except
    on E: Exception do
    begin
      ReleaseContent;
      FLoadError := E.Message;
      Invalidate;
      Exit;
    end;
  end;
  if Assigned(FOnLoaded) then
    FOnLoaded(Self);
end;

procedure TWinUIHost.ReleaseContent;
var
  I: Integer;
begin
  for I := High(Hosts) downto 0 do
    if Hosts[I] = Self then
      Delete(Hosts, I, 1);
  // The wrappers first: they remove their event handlers from the elements
  FreeAndNil(FContent);
  if Assigned(CustomXamlOwnerGone) then
    CustomXamlOwnerGone(Self);
  if FSource <> nil then
  begin
    // Not registered when the XAML failed to load
    if FFocusToken.Value <> 0 then
      FSource.remove_TakeFocusRequested(FFocusToken);
    FFocusToken.Value := 0;
    (FSource as IClosable).Close;
    FSource := nil;
  end;
  FFrame := nil;
end;

procedure TWinUIHost.ApplyTheme;
var
  Back: TColorRef;
  Fill: RADWinUI.Abi.Color;
begin
  Invalidate;
  if FFrame = nil then
    Exit;
  // The frame paints the background the theme's text reads on, the content inherits the theme
  Back := ColorToRGB(BackgroundColor);
  if IsDark(Back) then
    (FFrame as IFrameworkElement).RequestedTheme := ElementTheme.Dark
  else
    (FFrame as IFrameworkElement).RequestedTheme := ElementTheme.Light;
  Fill.A := 255;
  Fill.R := GetRValue(Back);
  Fill.G := GetGValue(Back);
  Fill.B := GetBValue(Back);
  FFrame.Background := SolidColorBrush.New(Fill) as IBrush;
end;

procedure TWinUIHost.ResizeContent;
var
  Area: RectInt32;
begin
  if FSource = nil then
    Exit;
  Area.X := 0;
  Area.Y := 0;
  Area.Width := ClientWidth;
  Area.Height := ClientHeight;
  (FSource.SiteBridge as IDesktopSiteBridge).MoveAndResize(Area);
end;

function TWinUIHost.GetDataContext: TWinValue;
begin
  if FContent <> nil then
    Result := FContent.DataContext
  else
    Result := FDataContext;
end;

procedure TWinUIHost.SetDataContext(const AValue: TWinValue);
begin
  FDataContext := AValue;
  FHasDataContext := True;
  if FContent <> nil then
    FContent.DataContext := AValue;
end;

function TWinUIHost.FindElement<T>(const AName: string): T;
begin
  if FContent = nil then
    Exit(nil);
  Result := T(TWinUIObject.Wrap(FContent, FContent.FindName(AName).Obj,
    TWinUIObjectClass(GetTypeData(TypeInfo(T))^.ClassType)));
end;

procedure TWinUIHost.WMSetFocus(var Message: TWMSetFocus);
var
  Reason: XamlSourceFocusNavigationReason;
begin
  inherited;
  if FSource = nil then
    Exit;
  // Tabbed in: the first element, or the last with Shift+Tab; otherwise where it was
  if GetKeyState(VK_TAB) < 0 then
    if GetKeyState(VK_SHIFT) < 0 then
      Reason := XamlSourceFocusNavigationReason.Last
    else
      Reason := XamlSourceFocusNavigationReason.First
  else
    Reason := XamlSourceFocusNavigationReason.Restore;
  if not FSource.NavigateFocus(XamlSourceFocusNavigationRequest.New(Reason)).WasFocusMoved and
    (Reason = XamlSourceFocusNavigationReason.Restore) then
    FSource.NavigateFocus(XamlSourceFocusNavigationRequest.New(XamlSourceFocusNavigationReason.First));
end;

procedure TWinUIHost.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  // Tab, arrows, Enter and Escape typed in the content are WinUI's, not the form's
  Message.Result := DLGC_WANTALLKEYS or DLGC_WANTARROWS or DLGC_WANTTAB or DLGC_WANTCHARS;
end;

procedure TWinUIHost.WMSize(var Message: TWMSize);
begin
  inherited;
  ResizeContent;
end;

initialization

finalization
  StopWinUI;

{$ENDIF}

end.
