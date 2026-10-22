unit RADWinUI.Runtime.Application;

{
  The Delphi side of Microsoft.UI.Xaml.Application.

  TWinUIApplication is the outer object of a COM aggregate: it creates the
  XAML Application as its inner object, answers IApplicationOverrides and
  IXamlMetadataProvider itself and forwards every other interface to the
  inner object. This is what C# and C++/WinRT do for "class App : Application".

  Usage:

    type
      TMyApp = class(TWinUIApplication)
      protected
        procedure OnLaunched(const AArgs: ILaunchActivatedEventArgs); override;
      end;

    begin
      TMyApp.Run;
    end.
}

interface

uses
  Winapi.Windows,
  System.SysUtils,
  RADWinUI.Interop.Core,
  RADWinUI.Abi;

type
  TWinUIApplication = class;
  TWinUIApplicationClass = class of TWinUIApplication;

  TWinUIApplication = class(TInterfacedObject, IInterface, IInspectable,
    IApplicationOverrides, IXamlMetadataProvider)
  strict private
    FInner: IInspectable;
    FProvider: IXamlMetadataProvider;
    function GetInstance: IApplication;
    function GetProvider: IXamlMetadataProvider;
    procedure MergeControlsResources;
  protected
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HRESULT; stdcall;
    { IInspectable }
    procedure GetIids(out AIidCount: Cardinal; out AIids: PGUID); safecall;
    function GetRuntimeClassName: HSTRING; safecall;
    function GetTrustLevel: TrustLevel; safecall;
    { IApplicationOverrides }
    procedure IApplicationOverrides.OnLaunched = HandleLaunched;
    procedure HandleLaunched(AArgs: ILaunchActivatedEventArgs); safecall;
    { IXamlMetadataProvider }
    function GetXamlType(AType: TypeName): IXamlType; safecall;
    function GetXamlTypeByFullName(AFullName: HSTRING): IXamlType; safecall;
    procedure GetXmlnsDefinitions(out AResultSize: Cardinal; out AResult: Pointer); safecall;

    /// <summary>Override to create and activate the main window.</summary>
    procedure OnLaunched(const AArgs: ILaunchActivatedEventArgs); virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HRESULT; override;

    /// <summary>
    ///   Bootstraps the Windows App Runtime, initializes WinRT on this thread,
    ///   creates the application and runs its message loop until it exits.
    /// </summary>
    class procedure Run;

    /// <summary>The XAML Application object this Delphi object extends.</summary>
    property Instance: IApplication read GetInstance;
  end;

implementation

uses
  RADWinUI.Runtime.Bootstrap,
  RADWinUI.Runtime.Environment,
  RADWinUI.Runtime.Crash;

var
  ApplicationFactoryCache: IInspectable;

/// Keeps the WinUI DLLs loaded until the process ends. RoUninitialize lets
/// COM unload them, Microsoft.UI.Xaml.Controls.dll's static destructors then release
/// objects of the already unloaded Microsoft.ui.xaml.dll: an access violation at every exit.
/// C# and C++/WinRT apps never unload them before the process ends either.
function GetModuleHandleEx(AFlags: DWORD; AName: PChar; out AModule: HMODULE): BOOL; stdcall;
  external kernel32 name 'GetModuleHandleExW';

procedure PinXamlModules;
const
  GET_MODULE_HANDLE_EX_FLAG_PIN = 1;
  Names: array[0..1] of string = ('Microsoft.ui.xaml.dll', 'Microsoft.UI.Xaml.Controls.dll');
var
  Name: string;
  Module: HMODULE;
begin
  for Name in Names do
    GetModuleHandleEx(GET_MODULE_HANDLE_EX_FLAG_PIN, PChar(Name), Module);
end;

{ TWinUIApplication }

constructor TWinUIApplication.Create;
var
  Outer: IInspectable;
  Delegating: IApplication;
begin
  inherited Create;
  // The reference count is 1 until AfterConstruction (TInterfacedObject), so
  // the AddRef/Release pairs the inner object makes on us cannot free us here.
  Outer := Self as IInspectable;
  Delegating := IApplicationFactory(GetFactory(Application.RuntimeClassName,
    IApplicationFactory, ApplicationFactoryCache)).CreateInstance(Outer, FInner);
  // Delegating forwards AddRef to us, keeping it would be a reference cycle.
  Delegating := nil;
end;

destructor TWinUIApplication.Destroy;
begin
  FProvider := nil;
  FInner := nil;
  inherited;
end;

function TWinUIApplication.QueryInterface(const IID: TGUID; out Obj): HRESULT;
begin
  if GetInterface(IID, Obj) then
    Exit(S_OK);
  if FInner <> nil then
    Exit(FInner.QueryInterface(IID, Obj));
  Pointer(Obj) := nil;
  Result := E_NOINTERFACE;
end;

procedure TWinUIApplication.GetIids(out AIidCount: Cardinal; out AIids: PGUID);
begin
  FInner.GetIids(AIidCount, AIids);
end;

function TWinUIApplication.GetRuntimeClassName: HSTRING;
begin
  Result := FInner.GetRuntimeClassName;
end;

function TWinUIApplication.GetTrustLevel: TrustLevel;
begin
  Result := FInner.GetTrustLevel;
end;

function TWinUIApplication.GetInstance: IApplication;
begin
  Result := FInner as IApplication;
end;

function TWinUIApplication.GetProvider: IXamlMetadataProvider;
begin
  if FProvider = nil then
    FProvider := XamlControlsXamlMetaDataProvider.New;
  Result := FProvider;
end;

procedure TWinUIApplication.MergeControlsResources;
var
  App: IApplication;
  Resources: IResourceDictionary;
begin
  App := Instance;
  Resources := App.Resources;
  if Resources = nil then
  begin
    Resources := ResourceDictionary.New;
    App.Resources := Resources;
  end;
  Resources.MergedDictionaries.Append(XamlControlsResources.New as IResourceDictionary);
end;

procedure TWinUIApplication.HandleLaunched(AArgs: ILaunchActivatedEventArgs);
begin
  MergeControlsResources;
  OnLaunched(AArgs);
end;

procedure TWinUIApplication.OnLaunched(const AArgs: ILaunchActivatedEventArgs);
begin
end;

function TWinUIApplication.GetXamlType(AType: TypeName): IXamlType;
begin
  Result := GetProvider.GetXamlType(AType);
end;

function TWinUIApplication.GetXamlTypeByFullName(AFullName: HSTRING): IXamlType;
begin
  Result := GetProvider.GetXamlTypeByFullName(AFullName);
end;

procedure TWinUIApplication.GetXmlnsDefinitions(out AResultSize: Cardinal; out AResult: Pointer);
begin
  GetProvider.GetXmlnsDefinitions(AResultSize, AResult);
end;

function TWinUIApplication.SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HRESULT;
begin
  // An exception in OnLaunched or a metadata call must not turn into a
  // failure HRESULT inside the XAML framework, which would end the process.
  if (ExceptObject is Exception) and Assigned(WinRTHandleException) then
    WinRTHandleException(Exception(ExceptObject));
  Result := S_OK;
end;

class procedure TWinUIApplication.Run;
var
  AppClass: TWinUIApplicationClass;
  App: IInspectable;
begin
  AppClass := Self;
  // Per-monitor v2, as the WinUI templates' manifest declares: without it the
  // window is bitmap-stretched (blurry) above 100% scaling. Fails harmlessly when
  // the exe's manifest already set the awareness.
  SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
  InstallCrashReport; // a native crash leaves a report instead of a silent exit
  EnsureNotElevated;
  TWinAppRuntime.Initialize;
  try
    CheckWinRT(RoInitialize(RO_INIT_SINGLETHREADED), 'RoInitialize');
    try
      try
        Application.Start(TApplicationInitializationCallback.Create(
          procedure(AP: IApplicationInitializationCallbackParams)
          begin
            App := AppClass.Create as IInspectable;
          end));
      finally
        App := nil;
        ClearFactoryCache;
      end;
    finally
      PinXamlModules;
      RoUninitialize;
    end;
  finally
    TWinAppRuntime.Shutdown;
  end;
end;

end.
