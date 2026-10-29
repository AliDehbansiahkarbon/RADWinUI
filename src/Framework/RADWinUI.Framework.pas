unit RADWinUI.Framework;

{
  Base of the developer-facing API (docs/FRAMEWORK-API.md).

  TWinUIObject is the base of every generated wrapper in RADWinUI.Xaml: it
  holds one WinRT object, owns other wrappers like a VCL owner does, and keeps
  one wrapper per WinRT object per owner. TWinValue boxes Delphi values for
  Object-typed properties, TWinUIList<T> and TWinUIValueList wrap IVector<T>.
}

interface

uses
  System.SysUtils,
  System.TypInfo,
  RADWinUI.Interop.Core,
  RADWinUI.Abi;

type
  TWinUIObject = class;
  TWinUIObjectClass = class of TWinUIObject;

  // RTTI for published members of descendants (handler wiring, designer)
  {$M+}
  TWinUIObject = class
  strict private
    FObj: IInspectable;
    FIdentity: Pointer;
    FOwner: TWinUIObject;
    // Plain arrays, not System.Generics.Collections: that unit links System.Classes
    // and System.Rtti (about 1.3 MB) into every app.
    FOwned: TArray<TWinUIObject>;
    FHelpers: TArray<TObject>;
    class var FRegistryNames: TArray<string>;
    class var FRegistryIIDs: TArray<TGUID>;
    class var FRegistryClasses: TArray<TWinUIObjectClass>;
    class function FindRegistered(const AName: string): TWinUIObjectClass; static;
    class function FindByInterfaces(const AObj: IInspectable; ADefault: TWinUIObjectClass): TWinUIObjectClass; static;
    function FindOwned(AIdentity: Pointer): TWinUIObject;
    procedure Insert(AObject: TWinUIObject);
    procedure Remove(AObject: TWinUIObject);
  protected
    /// <summary>Removes the WinRT event handlers this wrapper registered. Generated.</summary>
    procedure DetachEvents; virtual;
    /// <summary>Owner for wrappers this object creates: its own owner, or itself.</summary>
    function WrapOwner: TWinUIObject; inline;
    /// <summary>Keeps AHelper alive until this wrapper is destroyed.</summary>
    procedure AddHelper(AHelper: TObject);
  public
    /// <summary>Wraps AObj. AOwner frees the wrapper, nil means the caller frees it.</summary>
    constructor CreateFrom(AOwner: TWinUIObject; const AObj: IInspectable); virtual;
    destructor Destroy; override;

    /// <summary>
    ///   Returns AOwner's wrapper of AObj, or creates one owned by AOwner, of the
    ///   most derived registered class for its runtime class (at least ADefault).
    ///   Returns nil for a nil AObj.
    /// </summary>
    class function Wrap(AOwner: TWinUIObject; const AObj: IInterface;
      ADefault: TWinUIObjectClass): TWinUIObject; static;
    /// <summary>
    ///   Registers the wrapper class of a runtime class and its default interface.
    ///   Generated class constructors call this, so only linked wrappers register.
    /// </summary>
    class procedure RegisterWrapper(const ARuntimeClassName: string; const ADefaultIID: TGUID;
      AClass: TWinUIObjectClass); static;
    /// <summary>AObject's WinRT object queried for AIID, or nil when AObject is nil.</summary>
    class function IntfOf(AObject: TWinUIObject; const AIID: TGUID): IInterface; static;

    property Owner: TWinUIObject read FOwner;
    property WinRTObject: IInspectable read FObj;
  end;
  {$M-}

  /// <summary>
  ///   Answered by the WinRT objects of controls written in Delphi
  ///   (RADWinUI.CustomControls): Wrap returns their Pascal object itself.
  /// </summary>
  IWinUIPascalObject = interface
    ['{6F0C2A55-1E57-4B7C-9D49-6C1A4E8D2F31}']
    function PascalObject: TWinUIObject;
  end;

  TWinUIEventProc<T> = reference to procedure(Sender: TObject; E: T);

  /// <summary>
  ///   Anonymous-method listeners of one WinRT event, next to its OnXxx method
  ///   pointer: Button.Click.Add(procedure(Sender: TObject; E: TWinUIRoutedEventArgs) ...).
  ///   The wrapper owns it, its WinRT handler goes away with the wrapper.
  /// </summary>
  TWinUIEvent<T> = class
  strict private
    FProcs: TArray<TWinUIEventProc<T>>;
    FIds: TArray<Integer>;
    FNextId: Integer;
  public
    /// <summary>Adds a listener, the result identifies it for Remove.</summary>
    function Add(const AProc: TWinUIEventProc<T>): Integer;
    procedure Remove(AId: Integer);
    procedure Clear;
    /// <summary>Calls every listener in the order they were added. Generated code calls this.</summary>
    procedure Invoke(Sender: TObject; const E: T);
  end;

  /// <summary>A Delphi object that XAML sees as a WinRT object (TWinUIBindableList).</summary>
  TWinUIValueSource = class abstract
  protected
    function GetValue: IInspectable; virtual; abstract;
  end;

  /// <summary>A boxed WinRT value for Object-typed properties such as Content and Tag.</summary>
  TWinValue = record
  strict private
    FObj: IInspectable;
  public
    class operator Implicit(const AValue: string): TWinValue;
    class operator Implicit(AValue: Integer): TWinValue;
    class operator Implicit(AValue: Double): TWinValue;
    class operator Implicit(AValue: Boolean): TWinValue;
    class operator Implicit(AValue: TWinUIObject): TWinValue;
    class operator Implicit(AValue: TWinUIValueSource): TWinValue;
    class operator Implicit(const AValue: IInspectable): TWinValue;
    class operator Implicit(const AValue: TWinValue): IInspectable;
    function IsEmpty: Boolean;
    /// <summary>The boxed string, or the object's IStringable text, '' otherwise.</summary>
    function AsString: string;
    function AsInteger: Integer;
    function AsDouble: Double;
    function AsBoolean: Boolean;
    function ToString: string;
    property Obj: IInspectable read FObj;
  end;

  /// <summary>A binding converter step: AParameter is ConverterParameter as text.</summary>
  TWinUIConvertFunc = reference to function(const AValue: TWinValue; const AParameter: string): TWinValue;

  /// <summary>Any WinRT IVector&lt;T&gt, whose elements are interface pointers.</summary>
  TWinUIVector = class
  strict private
    FVector: IInspectable;
    FElementIID: TGUID;
  strict private
    function ElementOf(const AItem: IInspectable): IInspectable;
  protected
    FOwner: TWinUIObject;
    function GetRaw(AIndex: Integer): IInspectable;
    procedure AddRaw(const AItem: IInspectable);
    procedure InsertRaw(AIndex: Integer; const AItem: IInspectable);
    function IndexOfRaw(const AItem: IInspectable): Integer;
  public
    /// <summary>AVector is any interface of the vector object, AVectorIID its IVector&lt;T&gt, IID.</summary>
    constructor Create(AOwner: TWinUIObject; const AVector: IInterface;
      const AVectorIID, AElementIID: TGUID);
    function Count: Integer;
    procedure Delete(AIndex: Integer);
    procedure Clear;
  end;

  /// <summary>IVector of wrapped elements, such as Panel.Children. T is a TWinUIObject class.</summary>
  // class rather than TWinUIObject: generated units use T before declaring it.
  TWinUIList<T: class> = class(TWinUIVector)
  strict private
    function GetItem(AIndex: Integer): T;
  public
    procedure Add(AItem: T);
    procedure Insert(AIndex: Integer; AItem: T);
    function IndexOf(AItem: T): Integer;
    procedure Remove(AItem: T);
    property Items[AIndex: Integer]: T read GetItem; default;
  end;

  /// <summary>IVector&lt;Object&gt;, such as ItemsControl.Items.</summary>
  TWinUIValueList = class(TWinUIVector)
  strict private
    function GetItem(AIndex: Integer): TWinValue;
  public
    procedure Add(const AItem: TWinValue);
    procedure Insert(AIndex: Integer; const AItem: TWinValue);
    property Items[AIndex: Integer]: TWinValue read GetItem; default;
  end;

/// <summary>A Thickness with the same value on all four sides.</summary>
function Thickness(AUniform: Double): RADWinUI.Abi.Thickness; overload;
function Thickness(ALeft, ATop, ARight, ABottom: Double): RADWinUI.Abi.Thickness; overload;

implementation

uses
  Winapi.Windows;

type
  TGUIDArray = array[0..MaxInt div SizeOf(TGUID) - 1] of TGUID;
  PGUIDArray = ^TGUIDArray;

procedure CoTaskMemFree(APtr: Pointer); stdcall; external 'ole32.dll';

type
  // IVector<T> for any interface-typed T: every such instance has this vtable
  // layout, so one declaration serves them all once queried with the instance IID.
  IVectorLayout = interface(IInspectable)
    function GetAt(AIndex: Cardinal): IInspectable; safecall;
    function get_Size: Cardinal; safecall;
    function GetView: IInspectable; safecall;
    function IndexOf(const AValue: IInspectable; out AIndex: Cardinal): Boolean; safecall;
    procedure SetAt(AIndex: Cardinal; const AValue: IInspectable); safecall;
    procedure InsertAt(AIndex: Cardinal; const AValue: IInspectable); safecall;
    procedure RemoveAt(AIndex: Cardinal); safecall;
    procedure Append(const AValue: IInspectable); safecall;
    procedure RemoveAtEnd; safecall;
    procedure Clear; safecall;
  end;

function Identity(const AObj: IInterface): Pointer;
var
  Unk: IUnknown;
begin
  // COM identity: the IUnknown pointer of an object is the same for every interface.
  if Supports(AObj, IUnknown, Unk) then
    Result := Pointer(Unk)
  else
    Result := nil;
end;

{ TWinUIObject }

constructor TWinUIObject.CreateFrom(AOwner: TWinUIObject; const AObj: IInspectable);
begin
  inherited Create;
  if AObj = nil then
    raise EArgumentNilException.CreateFmt('%s needs a WinRT object', [ClassName]);
  FObj := AObj;
  FIdentity := Identity(AObj);
  if AOwner <> nil then
    AOwner.Insert(Self);
end;

destructor TWinUIObject.Destroy;
var
  Child: TWinUIObject;
  Helper: TObject;
begin
  // Children remove themselves from FOwned while they are freed, iterate a copy.
  for Child in Copy(FOwned) do
    Child.Free;
  try
    DetachEvents;
  except
    // a WinRT object that is already shut down must not stop the destruction
  end;
  for Helper in FHelpers do
    Helper.Free;
  if FOwner <> nil then
    FOwner.Remove(Self);
  FObj := nil;
  inherited;
end;

procedure TWinUIObject.DetachEvents;
begin
end;

procedure TWinUIObject.Insert(AObject: TWinUIObject);
begin
  FOwned := FOwned + [AObject];
  AObject.FOwner := Self;
end;

procedure TWinUIObject.Remove(AObject: TWinUIObject);
var
  I: Integer;
begin
  for I := High(FOwned) downto 0 do
    if FOwned[I] = AObject then
    begin
      Delete(FOwned, I, 1);
      Break;
    end;
  AObject.FOwner := nil;
end;

function TWinUIObject.FindOwned(AIdentity: Pointer): TWinUIObject;
var
  I: Integer;
begin
  // A linear scan, newest first: fine for hundreds of elements per window,
  // switch to a hash map if windows with thousands of wrapped elements show up.
  for I := High(FOwned) downto 0 do
    if FOwned[I].FIdentity = AIdentity then
      Exit(FOwned[I]);
  Result := nil;
end;

function TWinUIObject.WrapOwner: TWinUIObject;
begin
  if FOwner <> nil then
    Result := FOwner
  else
    Result := Self;
end;

procedure TWinUIObject.AddHelper(AHelper: TObject);
begin
  FHelpers := FHelpers + [AHelper];
end;

class procedure TWinUIObject.RegisterWrapper(const ARuntimeClassName: string;
  const ADefaultIID: TGUID; AClass: TWinUIObjectClass);
begin
  FRegistryNames := FRegistryNames + [ARuntimeClassName];
  FRegistryIIDs := FRegistryIIDs + [ADefaultIID];
  FRegistryClasses := FRegistryClasses + [AClass];
end;

class function TWinUIObject.FindRegistered(const AName: string): TWinUIObjectClass;
var
  I: Integer;
begin
  // Only the wrapper classes a program links are registered, usually a few dozen.
  for I := 0 to High(FRegistryNames) do
    if FRegistryNames[I] = AName then
      Exit(FRegistryClasses[I]);
  Result := nil;
end;

class function TWinUIObject.FindByInterfaces(const AObj: IInspectable;
  ADefault: TWinUIObjectClass): TWinUIObjectClass;
var
  Count, I, J: Integer;
  Iids: PGUID;
  List: PGUIDArray;
begin
  // The object implements the default interface of every runtime class it derives
  // from, the deepest linked wrapper among those is the most derived one.
  Result := ADefault;
  AObj.GetIids(Cardinal(Count), Iids);
  try
    List := PGUIDArray(Iids);
    for I := 0 to Count - 1 do
      for J := 0 to High(FRegistryIIDs) do
        if (FRegistryIIDs[J] = List[I]) and FRegistryClasses[J].InheritsFrom(Result) then
          Result := FRegistryClasses[J];
  finally
    CoTaskMemFree(Iids);
  end;
end;

class function TWinUIObject.Wrap(AOwner: TWinUIObject; const AObj: IInterface;
  ADefault: TWinUIObjectClass): TWinUIObject;
var
  Insp: IInspectable;
  Cls, Found: TWinUIObjectClass;
  Name: string;
  Pascal: IWinUIPascalObject;
begin
  if AObj = nil then
    Exit(nil);
  // A control written in Delphi has one Pascal object, whoever asks
  if Supports(AObj, IWinUIPascalObject, Pascal) then
  begin
    Result := Pascal.PascalObject;
    if Result is ADefault then
      Exit;
  end;
  if AOwner <> nil then
  begin
    Result := AOwner.FindOwned(Identity(AObj));
    if Result is ADefault then
      Exit;
  end;
  Insp := AObj as IInspectable;
  // The most derived wrapper the program links: wrapper classes register only
  // when linked, so an unlinked runtime class falls back to its nearest linked base.
  Name := TakeHString(Insp.GetRuntimeClassName);
  Found := FindRegistered(Name);
  if (Found <> nil) and Found.InheritsFrom(ADefault) then
    Cls := Found
  else
    Cls := FindByInterfaces(Insp, ADefault);
  Result := Cls.CreateFrom(AOwner, Insp);
end;

class function TWinUIObject.IntfOf(AObject: TWinUIObject; const AIID: TGUID): IInterface;
begin
  if AObject = nil then
    Exit(nil);
  if not Supports(AObject.FObj, AIID, Result) then
    raise EIntfCastError.CreateFmt('%s does not support %s', [AObject.ClassName, GUIDToString(AIID)]);
end;

{ TWinValue }

class operator TWinValue.Implicit(const AValue: string): TWinValue;
begin
  Result.FObj := PropertyValue.CreateString(WinStr(AValue));
end;

class operator TWinValue.Implicit(AValue: Integer): TWinValue;
begin
  Result.FObj := PropertyValue.CreateInt32(AValue);
end;

class operator TWinValue.Implicit(AValue: Double): TWinValue;
begin
  Result.FObj := PropertyValue.CreateDouble(AValue);
end;

class operator TWinValue.Implicit(AValue: Boolean): TWinValue;
begin
  Result.FObj := PropertyValue.CreateBoolean(AValue);
end;

class operator TWinValue.Implicit(AValue: TWinUIObject): TWinValue;
begin
  if AValue = nil then
    Result.FObj := nil
  else
    Result.FObj := AValue.WinRTObject;
end;

class operator TWinValue.Implicit(AValue: TWinUIValueSource): TWinValue;
begin
  if AValue = nil then
    Result.FObj := nil
  else
    Result.FObj := AValue.GetValue;
end;

class operator TWinValue.Implicit(const AValue: IInspectable): TWinValue;
begin
  Result.FObj := AValue;
end;

class operator TWinValue.Implicit(const AValue: TWinValue): IInspectable;
begin
  Result := AValue.FObj;
end;

function TWinValue.IsEmpty: Boolean;
begin
  Result := FObj = nil;
end;

function TWinValue.AsString: string;
var
  PV: IPropertyValue;
  S: IStringable;
begin
  if Supports(FObj, IPropertyValue, PV) then
    case PV.&Type of
      PropertyType.&String: Exit(TakeHString(PV.GetString));
      PropertyType.Int32: Exit(PV.GetInt32.ToString);
      PropertyType.Double: Exit(PV.GetDouble.ToString);
      PropertyType.Boolean: Exit(BoolToStr(PV.GetBoolean, True));
    end;
  if Supports(FObj, IStringable, S) then
    Exit(TakeHString(S.ToString));
  Result := '';
end;

function TWinValue.AsInteger: Integer;
begin
  Result := (FObj as IPropertyValue).GetInt32;
end;

function TWinValue.AsDouble: Double;
begin
  Result := (FObj as IPropertyValue).GetDouble;
end;

function TWinValue.AsBoolean: Boolean;
begin
  Result := (FObj as IPropertyValue).GetBoolean;
end;

function TWinValue.ToString: string;
begin
  Result := AsString;
end;

{ TWinUIEvent<T> }

function TWinUIEvent<T>.Add(const AProc: TWinUIEventProc<T>): Integer;
begin
  Inc(FNextId);
  Result := FNextId;
  FProcs := FProcs + [AProc];
  FIds := FIds + [Result];
end;

procedure TWinUIEvent<T>.Remove(AId: Integer);
var
  I: Integer;
begin
  for I := High(FIds) downto 0 do
    if FIds[I] = AId then
    begin
      Delete(FProcs, I, 1);
      Delete(FIds, I, 1);
    end;
end;

procedure TWinUIEvent<T>.Clear;
begin
  FProcs := nil;
  FIds := nil;
end;

procedure TWinUIEvent<T>.Invoke(Sender: TObject; const E: T);
var
  Proc: TWinUIEventProc<T>;
begin
  // A listener may add or remove listeners, call the ones present at the start.
  for Proc in Copy(FProcs) do
    Proc(Sender, E);
end;

{ TWinUIVector }

constructor TWinUIVector.Create(AOwner: TWinUIObject; const AVector: IInterface;
  const AVectorIID, AElementIID: TGUID);
var
  P: Pointer;
begin
  inherited Create;
  FOwner := AOwner;
  FElementIID := AElementIID;
  CheckWinRT(AVector.QueryInterface(AVectorIID, P), 'QueryInterface(IVector)');
  Pointer(FVector) := P; // already AddRef'd by QueryInterface
end;

function TWinUIVector.Count: Integer;
begin
  Result := IVectorLayout(FVector).get_Size;
end;

function TWinUIVector.GetRaw(AIndex: Integer): IInspectable;
begin
  Result := IVectorLayout(FVector).GetAt(AIndex);
end;

function TWinUIVector.ElementOf(const AItem: IInspectable): IInspectable;
var
  P: Pointer;
begin
  // The vector expects a pointer of the element interface, not just any interface
  // of the object, hold it as IInspectable, whose layout every WinRT interface shares.
  CheckWinRT(AItem.QueryInterface(FElementIID, P), 'QueryInterface(element)');
  Pointer(Result) := P; // already AddRef'd by QueryInterface
end;

procedure TWinUIVector.AddRaw(const AItem: IInspectable);
begin
  IVectorLayout(FVector).Append(ElementOf(AItem));
end;

procedure TWinUIVector.InsertRaw(AIndex: Integer; const AItem: IInspectable);
begin
  IVectorLayout(FVector).InsertAt(AIndex, ElementOf(AItem));
end;

function TWinUIVector.IndexOfRaw(const AItem: IInspectable): Integer;
var
  Index: Cardinal;
begin
  if IVectorLayout(FVector).IndexOf(ElementOf(AItem), Index) then
    Result := Index
  else
    Result := -1;
end;

procedure TWinUIVector.Delete(AIndex: Integer);
begin
  IVectorLayout(FVector).RemoveAt(AIndex);
end;

procedure TWinUIVector.Clear;
begin
  IVectorLayout(FVector).Clear;
end;

{ TWinUIList<T> }

function TWinUIList<T>.GetItem(AIndex: Integer): T;
begin
  Result := T(TWinUIObject.Wrap(FOwner, GetRaw(AIndex),
    TWinUIObjectClass(GetTypeData(TypeInfo(T))^.ClassType)));
end;

procedure TWinUIList<T>.Add(AItem: T);
begin
  AddRaw(TWinUIObject(AItem).WinRTObject);
end;

procedure TWinUIList<T>.Insert(AIndex: Integer; AItem: T);
begin
  InsertRaw(AIndex, TWinUIObject(AItem).WinRTObject);
end;

function TWinUIList<T>.IndexOf(AItem: T): Integer;
begin
  Result := IndexOfRaw(TWinUIObject(AItem).WinRTObject);
end;

procedure TWinUIList<T>.Remove(AItem: T);
var
  Index: Integer;
begin
  Index := IndexOf(AItem);
  if Index >= 0 then
    Delete(Index);
end;

{ TWinUIValueList }

function TWinUIValueList.GetItem(AIndex: Integer): TWinValue;
begin
  Result := GetRaw(AIndex);
end;

procedure TWinUIValueList.Add(const AItem: TWinValue);
begin
  AddRaw(AItem.Obj);
end;

procedure TWinUIValueList.Insert(AIndex: Integer; const AItem: TWinValue);
begin
  InsertRaw(AIndex, AItem.Obj);
end;

function Thickness(AUniform: Double): RADWinUI.Abi.Thickness;
begin
  Result := Thickness(AUniform, AUniform, AUniform, AUniform);
end;

function Thickness(ALeft, ATop, ARight, ABottom: Double): RADWinUI.Abi.Thickness;
begin
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Right := ARight;
  Result.Bottom := ABottom;
end;

end.
