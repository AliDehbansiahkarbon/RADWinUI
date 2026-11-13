unit RADWinUI.Pages;

{
  Pages and navigation. A page is a .xaml file with a <Page x:Class="TContactsPage">
  root and its .pas unit, like a window. XamlCodeGen generates TContactsPageBase
  between TWinUIXamlPage and the user's class. A <Frame> in XAML is a
  TWinUIPageFrame that shows one page at a time:

    ContentFrame.Navigate(TContactsPage);
    ContentFrame.Navigate(TContactPage, Contact);  // a parameter for NavigatedTo
    ContentFrame.GoBack;

  Pages are Delphi objects, not WinRT types, so the frame keeps its own back
  and forward stacks and shows a page by setting Frame.Content, with WinUI's
  navigation transitions. A page that is left is freed and created again when
  the user goes back to it, unless it sets KeepAlive: then the frame keeps that
  instance for as long as the frame lives.
}

interface

{$SCOPEDENUMS ON}

uses
  System.SysUtils,
  System.TypInfo,
  RADWinUI.Interop.Core,
  RADWinUI.Abi,
  RADWinUI.Framework,
  RADWinUI.Xaml;

type
  TWinUINavigationMode = (New, Back, Forward);

  TWinUIPageParameterKind = (None, Text, Integer, Double, Boolean, Obj);

  /// <summary>
  ///   What Navigate hands to the next page: a string, a number, a Boolean or
  ///   any object. The frame does not own an object it is given.
  /// </summary>
  TWinUIPageParameter = record
  strict private
    FKind: TWinUIPageParameterKind;
    FText: string;
    FNumber: Double;
    FObject: TObject;
  public
    class operator Implicit(const AValue: string): TWinUIPageParameter;
    class operator Implicit(AValue: Integer): TWinUIPageParameter;
    class operator Implicit(AValue: Double): TWinUIPageParameter;
    class operator Implicit(AValue: Boolean): TWinUIPageParameter;
    class operator Implicit(AValue: TObject): TWinUIPageParameter;
    function IsEmpty: Boolean;
    function AsString: string;
    function AsInteger: Integer;
    function AsDouble: Double;
    function AsBoolean: Boolean;
    function AsObject: TObject;
    property Kind: TWinUIPageParameterKind read FKind;
  end;

  TWinUIXamlPage = class;
  TWinUIXamlPageClass = class of TWinUIXamlPage;
  TWinUIPageFrame = class;
  TWinUINavigatedEvent = procedure(Sender: TObject) of object;

  TWinUINavigationArgs = record
    Mode: TWinUINavigationMode;
    Parameter: TWinUIPageParameter;
    /// <summary>The page left (in NavigatedTo) or shown next (in NavigatedFrom), nil when there is none.</summary>
    OtherPage: TWinUIXamlPageClass;
  end;

  TWinUINavigatingArgs = record
    Mode: TWinUINavigationMode;
    /// <summary>The page that would be shown next.</summary>
    Target: TWinUIXamlPageClass;
    Parameter: TWinUIPageParameter;
    /// <summary>Set to True to stay on the page.</summary>
    Cancel: Boolean;
    /// <summary>
    ///   Runs this navigation later without asking the page again, for example
    ///   after a MessageDlg the page showed when it set Cancel.
    /// </summary>
    Proceed: TProc;
  end;

  /// <summary>
  ///   Base of a page made of a .xaml file and its .pas unit. The frame creates
  ///   it with Create, shows it and calls the Navigated methods.
  /// </summary>
  {$M+}
  TWinUIXamlPage = class(TWinUIPage)
  strict private
    FFrame: TWinUIPageFrame;
    FKeepAlive: Boolean;
    // After ReplaceXaml: the names are in the namescope of the content it loaded
    FNames: IFrameworkElement;
  private
    procedure SetFrame(AFrame: TWinUIPageFrame);
  protected
    /// <summary>Loads AXaml, a &lt;Page&gt; element, as this page. The generated constructor calls it.</summary>
    constructor CreateFromXaml(const AXaml: string);
    /// <summary>
    ///   Shows the content of AXaml, a &lt;Page&gt; element, in this page (hot reload).
    ///   The page keeps its DataContext, its frame and its own attributes.
    /// </summary>
    procedure ReplaceXaml(const AXaml: string);
    /// <summary>The page is shown. AArgs.Parameter is what Navigate was given.</summary>
    procedure NavigatedTo(const AArgs: TWinUINavigationArgs); virtual;
    /// <summary>The page was left and another one is shown.</summary>
    procedure NavigatedFrom(const AArgs: TWinUINavigationArgs); virtual;
    /// <summary>The frame is about to leave the page. Set AArgs.Cancel to stay.</summary>
    procedure NavigatingFrom(var AArgs: TWinUINavigatingArgs); virtual;
    /// <summary>The published method AName, for event wiring by XamlCodeGen.</summary>
    function PublishedMethod(const AName: string): TMethod;
    /// <summary>A listener that calls the (Sender: TObject) published method AName.</summary>
    function NotifyProc<T>(const AName: string): TWinUIEventProc<T>;
  public
    /// <summary>An empty page. Generated pages load their XAML.</summary>
    constructor Create; reintroduce; virtual;
    destructor Destroy; override;
    /// <summary>The element named AName (x:Name) in the page, wrapped, nil when missing.</summary>
    function FindElement<T: TWinUIObject>(const AName: string): T;
    /// <summary>The frame that shows the page, nil before it is shown.</summary>
    property Frame: TWinUIPageFrame read FFrame;
    /// <summary>
    ///   Set in the constructor: the frame keeps this instance, with its state,
    ///   and shows it again instead of creating a new one.
    /// </summary>
    property KeepAlive: Boolean read FKeepAlive write FKeepAlive;
  end;
  {$M-}

  /// <summary>
  ///   A Frame that navigates between TWinUIXamlPage classes. XamlCodeGen gives
  ///   every &lt;Frame&gt; of a window, page or user control this type.
  /// </summary>
  TWinUIPageFrame = class(TWinUIFrame)
  strict private type
    TEntry = record
      PageClass: TWinUIXamlPageClass;
      Parameter: TWinUIPageParameter;
    end;
  strict private
    FBack, FForward: TArray<TEntry>;
    FCurrentEntry: TEntry;
    FCurrent: TWinUIXamlPage;
    FCache: TArray<TWinUIXamlPage>;
    FTransition: TWinUINavigationThemeTransition;
    FEnterInfo: TWinUIEntranceNavigationTransitionInfo;
    FBackInfo: TWinUISlideNavigationTransitionInfo;
    FOnNavigated: TWinUINavigatedEvent;
    FView: TWinUINavigationView;
    FViewPages: TArray<TWinUIXamlPageClass>;
    FSettingsPage: TWinUIXamlPageClass;
    // A navigation the page just refused, the same request again in this event is not asked twice
    FRefused: TWinUIXamlPageClass;
    FRefusedMode: TWinUINavigationMode;
    function MayLeave(AMode: TWinUINavigationMode; const AEntry: TEntry; const AProceed: TProc): Boolean;
    procedure Show(const AEntry: TEntry; AMode: TWinUINavigationMode);
    procedure FreeLater(APage: TWinUIXamlPage);
    procedure NavigateNow(const AEntry: TEntry);
    procedure GoBackNow;
    procedure GoForwardNow;
    procedure SyncView;
    procedure SyncViewLater;
    procedure ViewItemInvoked(Sender: TObject; E: TWinUINavigationViewItemInvokedEventArgs);
    procedure ViewBackRequested(Sender: TObject; E: TWinUINavigationViewBackRequestedEventArgs);
    procedure ViewSelectionChanged(Sender: TObject; E: TWinUINavigationViewSelectionChangedEventArgs);
  public
    procedure AfterConstruction; override;
    destructor Destroy; override;
    /// <summary>Shows a page of class APage, the current page goes on the back stack.</summary>
    procedure Navigate(APage: TWinUIXamlPageClass); overload;
    procedure Navigate(APage: TWinUIXamlPageClass; const AParameter: TWinUIPageParameter); overload;
    /// <summary>Shows the previous page again. False when there is none or the page stayed.</summary>
    function GoBack: Boolean;
    function GoForward: Boolean;
    function CanGoBack: Boolean;
    function CanGoForward: Boolean;
    /// <summary>The page classes behind the current one, oldest first.</summary>
    function BackStack: TArray<TWinUIXamlPageClass>;
    function ForwardStack: TArray<TWinUIXamlPageClass>;
    procedure ClearBackStack;
    /// <summary>
    ///   Lets ANavView drive the frame: a click on a menu item whose Tag is a page
    ///   class name (Tag="TContactsPage") shows that page, the settings item shows
    ///   ASettingsPage, the back button goes back. After every navigation the
    ///   selection follows the current page and the back button its CanGoBack.
    /// </summary>
    procedure AttachNavigationView(ANavView: TWinUINavigationView; const APages: array of TWinUIXamlPageClass;
      ASettingsPage: TWinUIXamlPageClass = nil);
    property CurrentPage: TWinUIXamlPage read FCurrent;
    /// <summary>After every navigation, once the new page is shown.</summary>
    property OnNavigated: TWinUINavigatedEvent read FOnNavigated write FOnNavigated;
  end;

implementation

uses
  RADWinUI.Runtime.Application;

var
  // Pages left by a frame, freed after the event that left them
  PendingPages: TArray<TWinUIXamlPage>;
  // Frames that exist, for work queued until after the current event
  LiveFrames: TArray<TWinUIPageFrame>;

function IsLiveFrame(AFrame: TWinUIPageFrame): Boolean;
var
  Frame: TWinUIPageFrame;
begin
  for Frame in LiveFrames do
    if Frame = AFrame then
      Exit(True);
  Result := False;
end;

{ TWinUIPageParameter }

class operator TWinUIPageParameter.Implicit(const AValue: string): TWinUIPageParameter;
begin
  Result := Default(TWinUIPageParameter);
  Result.FKind := TWinUIPageParameterKind.Text;
  Result.FText := AValue;
end;

class operator TWinUIPageParameter.Implicit(AValue: Integer): TWinUIPageParameter;
begin
  Result := Default(TWinUIPageParameter);
  Result.FKind := TWinUIPageParameterKind.Integer;
  Result.FNumber := AValue;
end;

class operator TWinUIPageParameter.Implicit(AValue: Double): TWinUIPageParameter;
begin
  Result := Default(TWinUIPageParameter);
  Result.FKind := TWinUIPageParameterKind.Double;
  Result.FNumber := AValue;
end;

class operator TWinUIPageParameter.Implicit(AValue: Boolean): TWinUIPageParameter;
begin
  Result := Default(TWinUIPageParameter);
  Result.FKind := TWinUIPageParameterKind.Boolean;
  Result.FNumber := Ord(AValue);
end;

class operator TWinUIPageParameter.Implicit(AValue: TObject): TWinUIPageParameter;
begin
  Result := Default(TWinUIPageParameter);
  if AValue <> nil then
    Result.FKind := TWinUIPageParameterKind.Obj;
  Result.FObject := AValue;
end;

function TWinUIPageParameter.IsEmpty: Boolean;
begin
  Result := FKind = TWinUIPageParameterKind.None;
end;

function TWinUIPageParameter.AsString: string;
begin
  case FKind of
    TWinUIPageParameterKind.Text: Result := FText;
    TWinUIPageParameterKind.Integer: Result := IntToStr(Trunc(FNumber));
    TWinUIPageParameterKind.Double: Result := FloatToStr(FNumber);
    TWinUIPageParameterKind.Boolean: Result := BoolToStr(FNumber <> 0, True);
    TWinUIPageParameterKind.Obj: Result := FObject.ToString;
  else
    Result := '';
  end;
end;

function TWinUIPageParameter.AsInteger: Integer;
begin
  if FKind = TWinUIPageParameterKind.Text then
    Result := StrToIntDef(FText, 0)
  else
    Result := Trunc(FNumber);
end;

function TWinUIPageParameter.AsDouble: Double;
begin
  if FKind = TWinUIPageParameterKind.Text then
    Result := StrToFloatDef(FText, 0)
  else
    Result := FNumber;
end;

function TWinUIPageParameter.AsBoolean: Boolean;
begin
  if FKind = TWinUIPageParameterKind.Text then
    Result := SameText(FText, 'True')
  else
    Result := FNumber <> 0;
end;

function TWinUIPageParameter.AsObject: TObject;
begin
  Result := FObject;
end;

{ TWinUIXamlPage }

constructor TWinUIXamlPage.Create;
begin
  CreateFromXaml('<Page xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"/>');
end;

constructor TWinUIXamlPage.CreateFromXaml(const AXaml: string);
var
  Loaded: IInspectable;
  Previous: TObject;
begin
  // Controls written in Delphi that this XAML creates belong to the page
  Previous := CustomXamlLoadOwner;
  CustomXamlLoadOwner := Self;
  try
    Loaded := XamlReader.Load(WinStr(AXaml));
  finally
    CustomXamlLoadOwner := Previous;
  end;
  if not Supports(Loaded, IPage) then
    raise EArgumentException.CreateFmt('%s: the XAML of a page must have a <Page> root', [ClassName]);
  inherited CreateFrom(nil, Loaded);
end;

destructor TWinUIXamlPage.Destroy;
begin
  if Assigned(CustomXamlOwnerGone) then
    CustomXamlOwnerGone(Self);
  inherited;
end;

procedure TWinUIXamlPage.SetFrame(AFrame: TWinUIPageFrame);
begin
  FFrame := AFrame;
end;

procedure TWinUIXamlPage.NavigatedTo(const AArgs: TWinUINavigationArgs);
begin
end;

procedure TWinUIXamlPage.NavigatedFrom(const AArgs: TWinUINavigationArgs);
begin
end;

procedure TWinUIXamlPage.NavigatingFrom(var AArgs: TWinUINavigatingArgs);
begin
end;

function TWinUIXamlPage.FindElement<T>(const AName: string): T;
var
  Found: IInspectable;
begin
  if FNames <> nil then
    Found := FNames.FindName(WinStr(AName))
  else
    Found := FindName(AName).Obj;
  Result := T(TWinUIObject.Wrap(Self, Found, TWinUIObjectClass(GetTypeData(TypeInfo(T))^.ClassType)));
end;

procedure TWinUIXamlPage.ReplaceXaml(const AXaml: string);
var
  Loaded: IInspectable;
  Previous: TObject;
  Moved: IUIElement;
begin
  Previous := CustomXamlLoadOwner;
  CustomXamlLoadOwner := Self;
  try
    Loaded := XamlReader.Load(WinStr(AXaml));
  finally
    CustomXamlLoadOwner := Previous;
  end;
  if not Supports(Loaded, IPage) then
    raise EArgumentException.CreateFmt('%s: the XAML of a page must have a <Page> root', [ClassName]);
  // The content moves from the page just loaded into this one, which the frame shows
  Moved := (Loaded as IUserControl).Content;
  (Loaded as IUserControl).Content := nil;
  (WinRTObject as IUserControl).Content := Moved;
  Supports(Moved, IFrameworkElement, FNames);
end;

function TWinUIXamlPage.PublishedMethod(const AName: string): TMethod;
begin
  Result.Code := MethodAddress(AName);
  Result.Data := Self;
  if Result.Code = nil then
    raise EInvalidOpException.CreateFmt('%s has no published method %s for its XAML events', [ClassName, AName]);
end;

function TWinUIXamlPage.NotifyProc<T>(const AName: string): TWinUIEventProc<T>;
var
  Method: TMethod;
begin
  Method := PublishedMethod(AName);
  Result :=
    procedure(Sender: TObject; E: T)
    var
      Handler: procedure(Sender: TObject) of object;
    begin
      TMethod(Handler) := Method;
      Handler(Sender);
    end;
end;

{ TWinUIPageFrame }

procedure TWinUIPageFrame.AfterConstruction;
begin
  inherited;
  LiveFrames := LiveFrames + [Self];
end;

destructor TWinUIPageFrame.Destroy;
var
  Page: TWinUIXamlPage;
  I: Integer;
begin
  for I := High(LiveFrames) downto 0 do
    if LiveFrames[I] = Self then
      Delete(LiveFrames, I, 1);
  // The view and its listeners belong to the same window and go with it
  FView := nil;
  if FCurrent <> nil then
    try
      Content := Default(TWinValue);
    except
      // a frame whose XAML is already shut down
    end;
  for I := High(PendingPages) downto 0 do
    if PendingPages[I].Frame = Self then
    begin
      Page := PendingPages[I];
      Delete(PendingPages, I, 1);
      Page.Free;
    end;
  if (FCurrent <> nil) and not FCurrent.KeepAlive then
    FCurrent.Free;
  FCurrent := nil;
  for Page in FCache do
    Page.Free;
  FCache := nil;
  inherited;
end;

procedure TWinUIPageFrame.Navigate(APage: TWinUIXamlPageClass);
begin
  Navigate(APage, Default(TWinUIPageParameter));
end;

procedure TWinUIPageFrame.Navigate(APage: TWinUIXamlPageClass; const AParameter: TWinUIPageParameter);
var
  Entry: TEntry;
begin
  if APage = nil then
    raise EArgumentNilException.Create('Navigate needs a page class');
  Entry.PageClass := APage;
  Entry.Parameter := AParameter;
  if MayLeave(TWinUINavigationMode.New, Entry,
    procedure
    begin
      NavigateNow(Entry);
    end) then
    NavigateNow(Entry);
end;

procedure TWinUIPageFrame.NavigateNow(const AEntry: TEntry);
begin
  if FCurrent <> nil then
    FBack := FBack + [FCurrentEntry];
  FForward := nil;
  Show(AEntry, TWinUINavigationMode.New);
end;

function TWinUIPageFrame.GoBack: Boolean;
begin
  Result := CanGoBack and MayLeave(TWinUINavigationMode.Back, FBack[High(FBack)],
    procedure
    begin
      GoBackNow;
    end);
  if Result then
    GoBackNow;
end;

procedure TWinUIPageFrame.GoBackNow;
var
  Entry: TEntry;
begin
  if not CanGoBack then
    Exit;
  Entry := FBack[High(FBack)];
  SetLength(FBack, Length(FBack) - 1);
  FForward := FForward + [FCurrentEntry];
  Show(Entry, TWinUINavigationMode.Back);
end;

function TWinUIPageFrame.GoForward: Boolean;
begin
  Result := CanGoForward and MayLeave(TWinUINavigationMode.Forward, FForward[High(FForward)],
    procedure
    begin
      GoForwardNow;
    end);
  if Result then
    GoForwardNow;
end;

procedure TWinUIPageFrame.GoForwardNow;
var
  Entry: TEntry;
begin
  if not CanGoForward then
    Exit;
  Entry := FForward[High(FForward)];
  SetLength(FForward, Length(FForward) - 1);
  FBack := FBack + [FCurrentEntry];
  Show(Entry, TWinUINavigationMode.Forward);
end;

function TWinUIPageFrame.CanGoBack: Boolean;
begin
  Result := Length(FBack) > 0;
end;

function TWinUIPageFrame.CanGoForward: Boolean;
begin
  Result := Length(FForward) > 0;
end;

function TWinUIPageFrame.BackStack: TArray<TWinUIXamlPageClass>;
var
  I: Integer;
begin
  SetLength(Result, Length(FBack));
  for I := 0 to High(FBack) do
    Result[I] := FBack[I].PageClass;
end;

function TWinUIPageFrame.ForwardStack: TArray<TWinUIXamlPageClass>;
var
  I: Integer;
begin
  SetLength(Result, Length(FForward));
  for I := 0 to High(FForward) do
    Result[I] := FForward[High(FForward) - I].PageClass;
end;

procedure TWinUIPageFrame.ClearBackStack;
begin
  FBack := nil;
  SyncView;
end;

// Asks the current page. On Cancel, AProceed lets the page finish the navigation later.
function TWinUIPageFrame.MayLeave(AMode: TWinUINavigationMode; const AEntry: TEntry; const AProceed: TProc): Boolean;
var
  Args: TWinUINavigatingArgs;
  Asking: TWinUIXamlPage;
  Me: TWinUIPageFrame;
begin
  if FCurrent = nil then
    Exit(True);
  // NavigationView may report one click twice: the page is asking already
  if (FRefused = AEntry.PageClass) and (FRefusedMode = AMode) then
    Exit(False);
  Asking := FCurrent;
  Me := Self;
  Args.Mode := AMode;
  Args.Target := AEntry.PageClass;
  Args.Parameter := AEntry.Parameter;
  Args.Cancel := False;
  Args.Proceed :=
    procedure
    begin
      // Only while the page that asked is still the one shown
      if Me.FCurrent = Asking then
        AProceed;
    end;
  FCurrent.NavigatingFrom(Args);
  Result := not Args.Cancel;
  if not Result then
  begin
    FRefused := AEntry.PageClass;
    FRefusedMode := AMode;
    SyncViewLater; // the NavigationView selects the clicked item after this event
  end;
end;

procedure TWinUIPageFrame.Show(const AEntry: TEntry; AMode: TWinUINavigationMode);
var
  Old, Page, Cached: TWinUIXamlPage;
  OldClass: TWinUIXamlPageClass;
  Args: TWinUINavigationArgs;
  Transitions: IVector_Transition;
begin
  if FTransition = nil then
  begin
    // WinUI's page transitions run when the frame's content changes
    Transitions := (IntfOf(Self, IContentControl) as IContentControl).ContentTransitions;
    if Transitions = nil then
    begin
      Transitions := TransitionCollection.New;
      (IntfOf(Self, IContentControl) as IContentControl).ContentTransitions := Transitions;
    end;
    Transitions.Clear;
    FTransition := TWinUINavigationThemeTransition.Create(Self);
    FEnterInfo := TWinUIEntranceNavigationTransitionInfo.Create(Self);
    FBackInfo := TWinUISlideNavigationTransitionInfo.Create(Self);
    FBackInfo.Effect := TWinUISlideNavigationTransitionEffect.FromLeft;
    Transitions.Append(IntfOf(FTransition, ITransition) as ITransition);
  end;
  if AMode = TWinUINavigationMode.Back then
    FTransition.DefaultNavigationTransitionInfo := FBackInfo
  else
    FTransition.DefaultNavigationTransitionInfo := FEnterInfo;

  Old := FCurrent;
  OldClass := nil;
  if Old <> nil then
    OldClass := TWinUIXamlPageClass(Old.ClassType);
  Page := nil;
  for Cached in FCache do
    if Cached.ClassType = AEntry.PageClass then
      Page := Cached;
  if Page = nil then
  begin
    Page := AEntry.PageClass.Create;
    if Page.KeepAlive then
      FCache := FCache + [Page];
  end;
  Page.SetFrame(Self);
  FCurrent := Page;
  FCurrentEntry := AEntry;
  Content := Page;

  Args.Mode := AMode;
  Args.Parameter := AEntry.Parameter;
  if Old <> nil then
  begin
    Args.OtherPage := AEntry.PageClass;
    Old.NavigatedFrom(Args);
    // Freed after the current event: the old page's own handler may still be running
    if not Old.KeepAlive then
      FreeLater(Old);
  end;
  Args.OtherPage := OldClass;
  Page.NavigatedTo(Args);
  SyncView;
  if Assigned(FOnNavigated) then
    FOnNavigated(Self);
end;

procedure TWinUIPageFrame.FreeLater(APage: TWinUIXamlPage);
var
  Handler: DispatcherQueueHandler;
begin
  // A frame that goes first frees its pending pages itself, so the list is not the frame's
  PendingPages := PendingPages + [APage];
  // In a variable during the call, as every handler given to the Windows App SDK
  Handler := TDispatcherQueueHandler.Create(
    procedure
    var
      I: Integer;
    begin
      for I := 0 to High(PendingPages) do
        if PendingPages[I] = APage then
        begin
          Delete(PendingPages, I, 1);
          APage.Free;
          Exit;
        end;
    end);
  RADWinUI.Abi.DispatcherQueue.GetForCurrentThread.TryEnqueue(Handler);
end;

procedure TWinUIPageFrame.AttachNavigationView(ANavView: TWinUINavigationView;
  const APages: array of TWinUIXamlPageClass; ASettingsPage: TWinUIXamlPageClass);
var
  I: Integer;
begin
  FView := ANavView;
  SetLength(FViewPages, Length(APages));
  for I := 0 to High(APages) do
    FViewPages[I] := APages[I];
  FSettingsPage := ASettingsPage;
  ANavView.ItemInvoked.Add(ViewItemInvoked);
  ANavView.BackRequested.Add(ViewBackRequested);
  ANavView.SelectionChanged.Add(ViewSelectionChanged);
  SyncView;
end;

function TagOf(const AItem: IInspectable): string;
var
  Element: IFrameworkElement;
begin
  if Supports(AItem, IFrameworkElement, Element) then
    Result := TWinValue(Element.Tag).AsString
  else
    Result := '';
end;

procedure TWinUIPageFrame.ViewItemInvoked(Sender: TObject; E: TWinUINavigationViewItemInvokedEventArgs);
var
  Name: string;
  Page: TWinUIXamlPageClass;
begin
  if E.IsSettingsInvoked then
  begin
    if (FSettingsPage <> nil) and ((FCurrent = nil) or (FCurrent.ClassType <> FSettingsPage)) then
      Navigate(FSettingsPage);
    Exit;
  end;
  if E.InvokedItemContainer = nil then
    Exit;
  Name := TagOf(E.InvokedItemContainer.WinRTObject);
  for Page in FViewPages do
    if SameText(Page.ClassName, Name) then
    begin
      if (FCurrent = nil) or (FCurrent.ClassType <> Page) then
        Navigate(Page);
      Exit;
    end;
end;

procedure TWinUIPageFrame.ViewBackRequested(Sender: TObject; E: TWinUINavigationViewBackRequestedEventArgs);
begin
  GoBack;
end;

procedure TWinUIPageFrame.ViewSelectionChanged(Sender: TObject; E: TWinUINavigationViewSelectionChangedEventArgs);
var
  Name: string;
begin
  if (FView = nil) or (FCurrent = nil) then
    Exit;
  // The item of another page is selected: a click the current page refused, the selection goes back
  Name := TagOf(FView.SelectedItem.Obj);
  if (Name <> '') and not SameText(Name, FCurrent.ClassName) then
    SyncViewLater;
end;
procedure TWinUIPageFrame.SyncView;
var
  Name: string;
  Found: IInspectable;
  View: INavigationView;

  // Finds the item of the current page in AItems and the items nested in them,
  // expanding its parents, and unselects every other item: after a refused click
  // NavigationView can leave the clicked item looking selected (IsSelected)
  // although SelectedItem went back
  function Walk(const AItems: IVector_Object): Boolean;
  var
    I: Integer;
    Item: IInspectable;
    Parent: INavigationViewItem2;
    Base: INavigationViewItemBase2;
  begin
    Result := False;
    if AItems = nil then
      Exit;
    for I := 0 to Integer(AItems.Size) - 1 do
    begin
      Item := AItems.GetAt(I);
      if (Found = nil) and (Name <> '') and SameText(TagOf(Item), Name) then
      begin
        Found := Item;
        Result := True;
      end
      else if Supports(Item, INavigationViewItemBase2, Base) and Base.IsSelected then
        Base.IsSelected := False;
      if Supports(Item, INavigationViewItem2, Parent) and Walk(Parent.MenuItems) then
      begin
        Parent.IsExpanded := True;
        Result := True;
      end;
    end;
  end;

begin
  if FView = nil then
    Exit;
  FView.IsBackEnabled := CanGoBack;
  if FCurrent = nil then
    Exit;
  if (FSettingsPage <> nil) and (FCurrent.ClassType = FSettingsPage) then
  begin
    FView.SelectedItem := FView.SettingsItem;
    Exit;
  end;
  Name := FCurrent.ClassName;
  Found := nil;
  View := IntfOf(FView, INavigationView) as INavigationView;
  Walk(View.MenuItems);
  Walk(View.FooterMenuItems);
  if Found <> nil then
    FView.SelectedItem := Found
  else
    // A page without a menu item, such as a details page: no item is selected
    FView.SelectedItem := Default(TWinValue);
end;

procedure TWinUIPageFrame.SyncViewLater;
var
  Me: TWinUIPageFrame;
  Handler: DispatcherQueueHandler;
begin
  SyncView;
  Me := Self;
  Handler := TDispatcherQueueHandler.Create(
    procedure
    begin
      // The frame may be gone with its window by then
      if IsLiveFrame(Me) then
      begin
        Me.FRefused := nil;
        Me.SyncView;
      end;
    end);
  RADWinUI.Abi.DispatcherQueue.GetForCurrentThread.TryEnqueue(Handler);
end;

end.
