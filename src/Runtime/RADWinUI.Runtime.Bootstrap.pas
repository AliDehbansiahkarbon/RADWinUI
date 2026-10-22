unit RADWinUI.Runtime.Bootstrap;

{
  Windows App Runtime bootstrapper for unpackaged apps.

  Small app (the Windows App Runtime is installed on the PC): loads
  Microsoft.WindowsAppRuntime.Bootstrap.dll from the
  executable folder and calls MddBootstrapInitialize2 so the process can use the
  Windows App Runtime framework package.
  Self-contained (Deploy-App.ps1 -SelfContained): the runtime DLLs
  sit next to the exe and its manifest registers their classes, Initialize only
  loads Microsoft.WindowsAppRuntime.dll, as the SDK's auto-initializer does. Values below come from WindowsAppSDK-VersionInfo.h
  in the Microsoft.WindowsAppSDK.Runtime 2.5.1 NuGet package.
}

interface

uses
  Winapi.Windows,
  System.SysUtils;

const
  WindowsAppSDKReleaseMajorMinor = $00020005;          // 2.5
  WindowsAppSDKRuntimeVersion: UInt64 = $0002000500010000; // 2.5.1.0
  WindowsAppSDKVersionTag = '';                        // stable channel
  WindowsAppSDKVersionText = '2.5.1';

  BootstrapDllName = 'Microsoft.WindowsAppRuntime.Bootstrap.dll';
  RuntimeDllName = 'Microsoft.WindowsAppRuntime.dll';

  // MddBootstrapInitializeOptions (MddBootstrap.h)
  MddBootstrapInitializeOptions_None = $0000;
  MddBootstrapInitializeOptions_OnError_DebugBreak = $0001;
  MddBootstrapInitializeOptions_OnError_DebugBreak_IfDebuggerAttached = $0002;
  MddBootstrapInitializeOptions_OnError_FailFast = $0004;
  MddBootstrapInitializeOptions_OnNoMatch_ShowUI = $0008;
  MddBootstrapInitializeOptions_OnPackageIdentity_NOOP = $0010;

type
  EWinAppRuntimeError = class(Exception)
  private
    FErrorCode: HRESULT;
  public
    constructor Create(const AMessage: string; AErrorCode: HRESULT);
    property ErrorCode: HRESULT read FErrorCode;
  end;

  /// <summary>Initializes and shuts down the Windows App Runtime for the process.</summary>
  TWinAppRuntime = class sealed
  private
    class var FLibrary: HMODULE;
    class var FInitialized: Boolean;
    class var FFallbackFolder: string;
    class var FSelfContained: Boolean;
  public
    /// <summary>
    ///   Where to load the bootstrap DLL from when it is not next to the exe, the
    ///   File > New wizard sets it in Debug builds to the RADWinUI checkout's copy.
    ///   RADWINUI_ROOT (<root>\third_party\...) is tried after it.
    /// </summary>
    class property FallbackFolder: string read FFallbackFolder write FFallbackFolder;
    /// <summary>Loads the bootstrap DLL and binds the process to Windows App Runtime 2.5.</summary>
    /// <remarks>Raises EWinAppRuntimeError when the DLL or a compatible runtime is missing.</remarks>
    class procedure Initialize(AOptions: Cardinal = MddBootstrapInitializeOptions_OnNoMatch_ShowUI);
    /// <summary>Reverts Initialize. Safe to call when Initialize was not called or failed.</summary>
    class procedure Shutdown;
    class property Initialized: Boolean read FInitialized;
    /// <summary>True when the runtime was loaded from the exe folder instead of the framework package.</summary>
    class property SelfContained: Boolean read FSelfContained;
  end;

implementation

type
  TMddBootstrapInitialize2 = function(MajorMinorVersion: Cardinal; VersionTag: PWideChar;
    MinVersion: UInt64; Options: Cardinal): HRESULT; stdcall;
  TMddBootstrapShutdown = procedure; stdcall;

function LastErrorAsHResult: HRESULT;
var
  Code: DWORD;
begin
  Code := GetLastError;
  if Code = 0 then
    Result := E_FAIL
  else
    Result := HRESULT($80070000 or (Code and $FFFF));
end;

{ EWinAppRuntimeError }

constructor EWinAppRuntimeError.Create(const AMessage: string; AErrorCode: HRESULT);
begin
  inherited CreateFmt('%s (HRESULT 0x%.8x)', [AMessage, Cardinal(AErrorCode)]);
  FErrorCode := AErrorCode;
end;

{ TWinAppRuntime }

/// The bootstrap DLL folder of the RADWinUI checkout named by RADWINUI_ROOT, or ''.
function RootFolderBootstrap: string;
var
  Root: string;
begin
  Root := GetEnvironmentVariable('RADWINUI_ROOT');
  if Root = '' then
    Exit('');
  Result := IncludeTrailingPathDelimiter(Root) + 'third_party\WindowsAppSDK\' + WindowsAppSDKVersionText +
    '\Microsoft.WindowsAppSDK.Foundation\runtimes\win-x64\native';
end;

class procedure TWinAppRuntime.Initialize(AOptions: Cardinal);
var
  InitializeProc: TMddBootstrapInitialize2;
  VersionTag, Searched, Folder: string;
  HR: HRESULT;
begin
  if FInitialized then
    Exit;

  if FileExists(ExtractFilePath(ParamStr(0)) + RuntimeDllName) then
  begin
    FLibrary := SafeLoadLibrary(ExtractFilePath(ParamStr(0)) + RuntimeDllName);
    if FLibrary = 0 then
      raise EWinAppRuntimeError.Create('The self-contained ' + RuntimeDllName + ' next to the exe could not be loaded',
        LastErrorAsHResult);
    FSelfContained := True;
    FInitialized := True;
    Exit;
  end;

  // Next to the exe (deployment), then the fallbacks (development)
  Searched := '';
  FLibrary := 0;
  for Folder in [ExtractFilePath(ParamStr(0)), FFallbackFolder, RootFolderBootstrap] do
  begin
    if (Folder = '') or (FLibrary <> 0) then
      Continue;
    Searched := Searched + sLineBreak + '  ' + IncludeTrailingPathDelimiter(Folder);
    FLibrary := SafeLoadLibrary(IncludeTrailingPathDelimiter(Folder) + BootstrapDllName);
  end;
  if FLibrary = 0 then
    raise EWinAppRuntimeError.Create(BootstrapDllName + ' was not found in:' + Searched + sLineBreak +
      'Build the project once (its post-build step copies the DLL next to the exe) or set RADWINUI_ROOT',
      LastErrorAsHResult);

  @InitializeProc := GetProcAddress(FLibrary, 'MddBootstrapInitialize2');
  if not Assigned(InitializeProc) then
  begin
    FreeLibrary(FLibrary);
    FLibrary := 0;
    raise EWinAppRuntimeError.Create('MddBootstrapInitialize2 is missing from ' + BootstrapDllName,
      LastErrorAsHResult);
  end;

  VersionTag := WindowsAppSDKVersionTag;
  HR := InitializeProc(WindowsAppSDKReleaseMajorMinor, PWideChar(VersionTag),
    WindowsAppSDKRuntimeVersion, AOptions);
  if Failed(HR) then
  begin
    FreeLibrary(FLibrary);
    FLibrary := 0;
    raise EWinAppRuntimeError.Create('Windows App Runtime ' + WindowsAppSDKVersionText +
      ' could not be initialized. Is the runtime installed?', HR);
  end;

  FInitialized := True;
end;

class procedure TWinAppRuntime.Shutdown;
var
  ShutdownProc: TMddBootstrapShutdown;
begin
  if (FLibrary = 0) or FSelfContained then
    Exit; // the self-contained runtime stays loaded until the process ends, as in the SDK

  if FInitialized then
  begin
    @ShutdownProc := GetProcAddress(FLibrary, 'MddBootstrapShutdown');
    if Assigned(ShutdownProc) then
      ShutdownProc;
    FInitialized := False;
  end;

  FreeLibrary(FLibrary);
  FLibrary := 0;
end;

end.
