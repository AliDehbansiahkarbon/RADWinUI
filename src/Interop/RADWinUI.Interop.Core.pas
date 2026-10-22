unit RADWinUI.Interop.Core;

{
  Hand-written WinRT core interop from combase.dll.

  The generated projection (src/Generated/RADWinUI.Abi.pas) builds on these
  declarations. Kept independent of the RTL's Winapi.WinRT so the projection
  controls its own types and does not depend on the installed RTL version.
}

interface

uses
  Winapi.Windows,
  System.SysUtils;

type
  HSTRING = type Pointer;
  PHSTRING = ^HSTRING;
  TrustLevel = type Integer;

  IInspectable = interface(IUnknown)
    ['{AF86E2E0-B12D-4C6A-9C5A-D7AA65101E90}']
    procedure GetIids(out AIidCount: Cardinal; out AIids: PGUID); safecall;
    function GetRuntimeClassName: HSTRING; safecall;
    function GetTrustLevel: TrustLevel; safecall;
  end;

  /// <summary>Marks a COM object as free-threaded, so WinRT never marshals it.</summary>
  PIInspectable = ^IInspectable;

  IAgileObject = interface(IUnknown)
    ['{94EA2B94-E9CC-49E0-C0FF-EE64CA8F5B90}']
  end;

  IActivationFactory = interface(IInspectable)
    ['{00000035-0000-0000-C000-000000000046}']
    function ActivateInstance: IInspectable; safecall;
  end;

  /// <summary>Raised when a WinRT call returns a failing HRESULT.</summary>
  EWinRTError = class(Exception)
  private
    FErrorCode: HRESULT;
  public
    constructor Create(const AContext: string; AErrorCode: HRESULT);
    /// <summary>AMessage is the WinRT error text, the HRESULT is appended.</summary>
    constructor CreateMsg(AErrorCode: HRESULT; const AMessage: string);
    property ErrorCode: HRESULT read FErrorCode;
  end;

  /// <summary>
  ///   An HSTRING owned by a managed record: created from a Delphi string,
  ///   deleted when the record goes out of scope. Converts implicitly to
  ///   HSTRING for passing to projected methods.
  /// </summary>
  TWinString = record
  strict private
    FHandle: HSTRING;
  public
    class operator Initialize(out ADest: TWinString);
    class operator Finalize(var ADest: TWinString);
    class operator Assign(var ADest: TWinString; const [ref] ASource: TWinString);
    class operator Implicit(const AValue: string): TWinString;
    class operator Implicit(const AValue: TWinString): HSTRING;
    class operator Implicit(const AValue: TWinString): string;
    function ToString: string;
    property Handle: HSTRING read FHandle;
  end;

  /// <summary>
  ///   Base class for Delphi implementations of WinRT delegates. Agile, and an
  ///   exception raised in a handler goes to WinRTHandleException instead of
  ///   returning a failure HRESULT into the XAML framework.
  /// </summary>
  TWinRTDelegate = class(TInterfacedObject, IAgileObject)
  public
    function SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HRESULT; override;
  end;

  TWinRTExceptionHandler = procedure(AException: Exception);

const
  RO_INIT_SINGLETHREADED = 0;
  RO_INIT_MULTITHREADED = 1;
  E_BOUNDS = HRESULT($8000000B);

var
  /// <summary>Called for exceptions escaping a delegate. Defaults to a message box.</summary>
  WinRTHandleException: TWinRTExceptionHandler;

function RoInitialize(AInitType: Integer): HRESULT; stdcall;
  external 'combase.dll' name 'RoInitialize';
procedure RoUninitialize; stdcall;
  external 'combase.dll' name 'RoUninitialize';
function RoGetActivationFactory(AActivatableClassId: HSTRING; const AIID: TGUID;
  out AFactory: Pointer): HRESULT; stdcall;
  external 'combase.dll' name 'RoGetActivationFactory';
function RoActivateInstance(AActivatableClassId: HSTRING; out AInstance: Pointer): HRESULT; stdcall;
  external 'combase.dll' name 'RoActivateInstance';
function WindowsCreateString(ASourceString: PWideChar; ALength: Cardinal;
  out AString: HSTRING): HRESULT; stdcall;
  external 'combase.dll' name 'WindowsCreateString';
function WindowsDeleteString(AString: HSTRING): HRESULT; stdcall;
  external 'combase.dll' name 'WindowsDeleteString';
function WindowsDuplicateString(AString: HSTRING; out ANewString: HSTRING): HRESULT; stdcall;
  external 'combase.dll' name 'WindowsDuplicateString';
function WindowsGetStringRawBuffer(AString: HSTRING; ALength: PCardinal): PWideChar; stdcall;
  external 'combase.dll' name 'WindowsGetStringRawBuffer';

/// <summary>Raises EWinRTError when AResult is a failure code.</summary>
procedure CheckWinRT(AResult: HRESULT; const AContext: string);

/// <summary>
///   Wraps a Delphi string as an HSTRING that lives until the calling routine
///   ends: Window.Title := WinStr('Hello');
/// </summary>
function WinStr(const AValue: string): TWinString;

/// <summary>
///   A new HSTRING owned by whoever receives it: for results of WinRT methods
///   implemented in Delphi (GetRuntimeClassName, string properties).
/// </summary>
function NewHString(const AValue: string): HSTRING;

/// <summary>Copies an HSTRING into a Delphi string, the HSTRING stays owned by the caller.</summary>
function HStringToString(AHandle: HSTRING): string;

/// <summary>Copies an HSTRING returned by a projected method into a Delphi string and deletes it.</summary>
function TakeHString(AHandle: HSTRING): string;

/// <summary>Returns the activation factory of a runtime class, queried for AIID.</summary>
function GetActivationFactory(const AClassName: string; const AIID: TGUID): IInspectable;

/// <summary>
///   Like GetActivationFactory, but caches the factory in ACache. Generated
///   code uses this, ClearFactoryCache releases every cached factory.
/// </summary>
function GetFactory(const AClassName: string; const AIID: TGUID;
  var ACache: IInspectable): IInspectable;

/// <summary>Releases all factories cached by GetFactory. Call before RoUninitialize.</summary>
procedure ClearFactoryCache;

/// <summary>Activates a runtime class with its default constructor and queries AIID.</summary>
function ActivateInstance(const AClassName: string; const AIID: TGUID): IInspectable;

implementation

{ EWinRTError }

constructor EWinRTError.Create(const AContext: string; AErrorCode: HRESULT);
begin
  inherited CreateFmt('%s failed (HRESULT 0x%.8x): %s',
    [AContext, Cardinal(AErrorCode), SysErrorMessage(Cardinal(AErrorCode))]);
  FErrorCode := AErrorCode;
end;

constructor EWinRTError.CreateMsg(AErrorCode: HRESULT; const AMessage: string);
begin
  inherited CreateFmt('%s (HRESULT 0x%.8x)', [AMessage, Cardinal(AErrorCode)]);
  FErrorCode := AErrorCode;
end;

procedure CheckWinRT(AResult: HRESULT; const AContext: string);
begin
  if Failed(AResult) then
    raise EWinRTError.Create(AContext, AResult);
end;

function WinStr(const AValue: string): TWinString;
begin
  Result := AValue;
end;

function NewHString(const AValue: string): HSTRING;
begin
  Result := nil;
  if AValue <> '' then
    CheckWinRT(WindowsCreateString(PWideChar(AValue), Length(AValue), Result), 'WindowsCreateString');
end;

function HStringToString(AHandle: HSTRING): string;
var
  Len: Cardinal;
  Buffer: PWideChar;
begin
  if AHandle = nil then
    Exit('');
  Buffer := WindowsGetStringRawBuffer(AHandle, @Len);
  SetString(Result, Buffer, Len);
end;

function TakeHString(AHandle: HSTRING): string;
begin
  Result := HStringToString(AHandle);
  if AHandle <> nil then
    WindowsDeleteString(AHandle);
end;

{ TWinString }

class operator TWinString.Initialize(out ADest: TWinString);
begin
  ADest.FHandle := nil;
end;

class operator TWinString.Finalize(var ADest: TWinString);
begin
  if ADest.FHandle <> nil then
  begin
    WindowsDeleteString(ADest.FHandle);
    ADest.FHandle := nil;
  end;
end;

class operator TWinString.Assign(var ADest: TWinString; const [ref] ASource: TWinString);
var
  Copy: HSTRING;
begin
  if ADest.FHandle = ASource.FHandle then
    Exit;
  Copy := nil;
  if ASource.FHandle <> nil then
    CheckWinRT(WindowsDuplicateString(ASource.FHandle, Copy), 'WindowsDuplicateString');
  if ADest.FHandle <> nil then
    WindowsDeleteString(ADest.FHandle);
  ADest.FHandle := Copy;
end;

class operator TWinString.Implicit(const AValue: string): TWinString;
begin
  // Result is a managed record the caller may reuse, release what it held.
  if Result.FHandle <> nil then
  begin
    WindowsDeleteString(Result.FHandle);
    Result.FHandle := nil;
  end;
  if AValue <> '' then
    CheckWinRT(WindowsCreateString(PWideChar(AValue), Length(AValue), Result.FHandle),
      'WindowsCreateString');
end;

class operator TWinString.Implicit(const AValue: TWinString): HSTRING;
begin
  Result := AValue.FHandle;
end;

class operator TWinString.Implicit(const AValue: TWinString): string;
begin
  Result := HStringToString(AValue.FHandle);
end;

function TWinString.ToString: string;
begin
  Result := HStringToString(FHandle);
end;

{ TWinRTDelegate }

function TWinRTDelegate.SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HRESULT;
begin
  if (ExceptObject is Exception) and Assigned(WinRTHandleException) then
    WinRTHandleException(Exception(ExceptObject));
  Result := S_OK;
end;

procedure DefaultHandleException(AException: Exception);
begin
  OutputDebugString(PChar(AException.ClassName + ': ' + AException.Message));
  MessageBox(0, PChar(AException.Message), PChar(AException.ClassName), MB_OK or MB_ICONERROR);
end;

{ Errors of safecall methods }

type
  IRestrictedErrorInfo = interface(IUnknown)
    ['{82BA7092-4C88-427D-A7BC-16DD93FEB67E}']
    function GetErrorDetails(out ADescription: WideString; out AError: HRESULT;
      out ARestrictedDescription: WideString; out ACapabilitySid: WideString): HRESULT; stdcall;
    function GetReference(out AReference: WideString): HRESULT; stdcall;
  end;

function GetRestrictedErrorInfo(out AInfo: IRestrictedErrorInfo): HRESULT; stdcall;
  external 'combase.dll' name 'GetRestrictedErrorInfo';

// SafeCallErrorProc: a failing safecall raises EWinRTError with the message
// the WinRT object reported (for example the XAML parse error and position).
procedure WinRTSafeCallError(AErrorCode: HRESULT; AErrorAddr: Pointer);
var
  Info: IRestrictedErrorInfo;
  Description, Restricted, Sid: WideString;
  Code: HRESULT;
  Msg: string;
begin
  Msg := '';
  if (GetRestrictedErrorInfo(Info) = S_OK) and (Info <> nil) and
    Succeeded(Info.GetErrorDetails(Description, Code, Restricted, Sid)) and (Code = AErrorCode) then
  begin
    Msg := Trim(string(Restricted));
    if Msg = '' then
      Msg := Trim(string(Description));
  end;
  if Msg = '' then
    Msg := SysErrorMessage(Cardinal(AErrorCode));
  raise EWinRTError.CreateMsg(AErrorCode, Msg) at AErrorAddr;
end;

{ Activation }

function GetActivationFactory(const AClassName: string; const AIID: TGUID): IInspectable;
var
  ClassId: TWinString;
  Factory: Pointer;
begin
  ClassId := AClassName;
  Factory := nil;
  CheckWinRT(RoGetActivationFactory(ClassId, AIID, Factory),
    'RoGetActivationFactory(' + AClassName + ')');
  Pointer(Result) := Factory; // already AddRef'd by RoGetActivationFactory
end;

var
  FactoryCacheLock: TRTLCriticalSection;
  FactoryCacheSlots: array of PIInspectable;

function GetFactory(const AClassName: string; const AIID: TGUID;
  var ACache: IInspectable): IInspectable;
begin
  if Pointer(ACache) <> nil then
    Exit(ACache);
  Result := GetActivationFactory(AClassName, AIID);
  EnterCriticalSection(FactoryCacheLock);
  try
    if Pointer(ACache) = nil then
    begin
      ACache := Result;
      SetLength(FactoryCacheSlots, Length(FactoryCacheSlots) + 1);
      FactoryCacheSlots[High(FactoryCacheSlots)] := PIInspectable(@ACache);
    end;
  finally
    LeaveCriticalSection(FactoryCacheLock);
  end;
end;

procedure ClearFactoryCache;
var
  Slot: PIInspectable;
begin
  EnterCriticalSection(FactoryCacheLock);
  try
    for Slot in FactoryCacheSlots do
      Slot^ := nil;
    FactoryCacheSlots := nil;
  finally
    LeaveCriticalSection(FactoryCacheLock);
  end;
end;

function ActivateInstance(const AClassName: string; const AIID: TGUID): IInspectable;
var
  ClassId: TWinString;
  Instance: Pointer;
  Inspectable: IInspectable;
  Obj: Pointer;
begin
  ClassId := AClassName;
  Instance := nil;
  CheckWinRT(RoActivateInstance(ClassId, Instance), 'RoActivateInstance(' + AClassName + ')');
  Pointer(Inspectable) := Instance;
  CheckWinRT(Inspectable.QueryInterface(AIID, Obj), 'QueryInterface(' + AClassName + ')');
  Pointer(Result) := Obj;
end;

initialization
  InitializeCriticalSection(FactoryCacheLock);
  WinRTHandleException := DefaultHandleException;
  SafeCallErrorProc := @WinRTSafeCallError;

finalization
  DeleteCriticalSection(FactoryCacheLock);

end.
