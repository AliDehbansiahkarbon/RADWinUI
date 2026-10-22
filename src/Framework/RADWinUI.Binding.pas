unit RADWinUI.Binding;

(*
  {Binding} support for Delphi objects.

    FContacts := TWinUIBindableList<TContact>.Create;   // owns its items
    FContacts.Add(TContact.Create('Ali', 'ali@example.com'));
    ContactList.ItemsSource := FContacts;                // ListView with a DataTemplate
    ...
    Contact.Name := 'New name';
    FContacts.ItemChanged(Contact, 'Name');              // updates {Binding Name}

  XAML reads Delphi objects through ICustomPropertyProvider: {Binding Name}
  becomes a read of the published property Name (classic RTTI from
  System.TypInfo, give item classes {$M+} or derive them from TPersistent).
  TWinUIBindableList<T> appears to XAML as an IBindableObservableVector, so
  ItemsSource follows Add, Insert, Delete and Clear.
*)

interface

uses
  System.SysUtils,
  System.TypInfo,
  RADWinUI.Interop.Core,
  RADWinUI.Abi,
  RADWinUI.Framework;

type
  /// <summary>Lets the framework find the Delphi object behind a bindable WinRT object.</summary>
  IWinUIBindableTarget = interface
    ['{6E0B3F52-8C1A-4D7E-9B55-2F3C9E7A41D0}']
    function Target: TObject;
  end;

  /// <summary>
  ///   A Delphi object as XAML sees it: its published properties are bindable
  ///   ({Binding Name}), and NotifyPropertyChanged updates the bindings.
  ///   Reference-counted, does not own the object.
  /// </summary>
  TWinUIBindable = class(TWinRTDelegate, IInspectable, ICustomPropertyProvider,
    INotifyPropertyChanged, IWinUIBindableTarget)
  strict private
    FTarget: TObject;
    FHandlers: TArray<PropertyChangedEventHandler>;
    FTokens: TArray<Int64>;
    FNextToken: Int64;
  protected
    { IInspectable }
    procedure GetIids(out AIidCount: Cardinal; out AIids: PGUID); safecall;
    function GetRuntimeClassName: HSTRING; safecall;
    function GetTrustLevel: TrustLevel; safecall;
    { ICustomPropertyProvider }
    function GetCustomProperty(AName: HSTRING): ICustomProperty; safecall;
    function GetIndexedProperty(AName: HSTRING; AType: TypeName): ICustomProperty; safecall;
    function GetStringRepresentation: HSTRING; safecall;
    function get_Type: TypeName; safecall;
    { INotifyPropertyChanged }
    function add_PropertyChanged(AHandler: PropertyChangedEventHandler): EventRegistrationToken; safecall;
    procedure remove_PropertyChanged(AToken: EventRegistrationToken); safecall;
    { IWinUIBindableTarget }
    function Target: TObject;
  public
    constructor Create(ATarget: TObject);
    /// <summary>Tells bindings that AName changed, '' means all properties.</summary>
    procedure NotifyPropertyChanged(const AName: string);
    /// <summary>Stops reading the object (it is about to be freed).</summary>
    procedure Detach;
  end;

  /// <summary>
  ///   A list of Delphi objects for ItemsSource. Owns its items unless
  ///   AOwnsObjects is False. XAML follows Add, Insert, Delete and Clear,
  ///   call ItemChanged after changing an item's properties.
  /// </summary>
  /// <summary>
  ///   Base class for objects bound as a DataContext (view models): published
  ///   properties are bindable, including two-way, call Changed after a property
  ///   changes so the bindings update. Converts to TWinValue:
  ///   DataContext := FProfile.
  /// </summary>
  {$M+}
  TWinUIBindableObject = class(TWinUIValueSource)
  strict private
    FBindable: TWinUIBindable;
    FBindableRef: IInspectable;
  protected
    function GetValue: IInspectable; override;
    /// <summary>Updates the bindings of APropertyName, '' means all properties.</summary>
    procedure Changed(const APropertyName: string = '');
  public
    destructor Destroy; override;
  end;
  {$M-}

  /// <summary>
  ///   A binding converter from Delphi functions, for Converter={StaticResource Name},
  ///   register it with TWinUIApp.RegisterConverter.
  /// </summary>
  TWinUIValueConverter = class(TWinRTDelegate, IInspectable, IValueConverter)
  strict private
    FConvert: TWinUIConvertFunc;
    FConvertBack: TWinUIConvertFunc;
  protected
    procedure GetIids(out AIidCount: Cardinal; out AIids: PGUID); safecall;
    function GetRuntimeClassName: HSTRING; safecall;
    function GetTrustLevel: TrustLevel; safecall;
    function Convert(AValue: IInspectable; ATargetType: TypeName; AParameter: IInspectable;
      ALanguage: HSTRING): IInspectable; safecall;
    function ConvertBack(AValue: IInspectable; ATargetType: TypeName; AParameter: IInspectable;
      ALanguage: HSTRING): IInspectable; safecall;
  public
    constructor Create(const AConvert: TWinUIConvertFunc; const AConvertBack: TWinUIConvertFunc = nil);
  end;

  /// <summary>The WinRT side of TWinUIBindableList&lt;T&gt;, not used directly.</summary>
  TWinUIBindableListBase = class(TWinUIValueSource)
  strict private
    FVector: IInspectable;
    FVectorObject: TObject;
  protected
    function GetValue: IInspectable; override;
    function GetCount: Integer; virtual; abstract;
    function GetBindable(AIndex: Integer): IInspectable; virtual; abstract;
    /// <summary>Raises VectorChanged so XAML updates ItemsSource.</summary>
    procedure Changed(AChange: CollectionChange; AIndex: Integer);
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TWinUIBindableList<T: class> = class(TWinUIBindableListBase)
  strict private
    FItems: TArray<T>;
    FBindables: TArray<TWinUIBindable>;
    FBindableRefs: TArray<IInspectable>;
    FOwnsObjects: Boolean;
    function GetItem(AIndex: Integer): T;
    procedure ReleaseItem(AIndex: Integer);
  protected
    function GetCount: Integer; override;
    function GetBindable(AIndex: Integer): IInspectable; override;
  public
    constructor Create(AOwnsObjects: Boolean = True);
    function Add(AItem: T): Integer;
    procedure Insert(AIndex: Integer; AItem: T);
    procedure Delete(AIndex: Integer);
    procedure Clear;
    function IndexOf(AItem: T): Integer;
    /// <summary>Updates the bindings of AItem, APropertyName '' means all of them.</summary>
    procedure ItemChanged(AItem: T; const APropertyName: string = '');
    /// <summary>The WinRT object XAML sees for the item at AIndex.</summary>
    function BindableAt(AIndex: Integer): IInspectable;
    destructor Destroy; override;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: T read GetItem; default;
  end;

implementation

{$WARN SYMBOL_PLATFORM OFF} // RegisterExpectedMemoryLeak, RADWinUI is Windows only

uses
  Winapi.Windows;

const
  BindableClassName = 'RADWinUI.Bindable';

function NewTypeName(const AName: string; AKind: TypeKind): TypeName;
begin
  Result.&Name := NewHString(AName);
  Result.Kind := AKind;
end;

function Box(AObject: TObject; APropInfo: PPropInfo): IInspectable;
var
  Child: TObject;
begin
  case APropInfo^.PropType^.Kind of
    tkUString, tkLString, tkWString, tkString:
      Result := PropertyValue.CreateString(WinStr(GetStrProp(AObject, APropInfo)));
    tkInteger:
      Result := PropertyValue.CreateInt32(GetOrdProp(AObject, APropInfo));
    tkInt64:
      Result := PropertyValue.CreateInt64(GetInt64Prop(AObject, APropInfo));
    tkFloat:
      Result := PropertyValue.CreateDouble(GetFloatProp(AObject, APropInfo));
    tkEnumeration:
      if GetTypeData(APropInfo^.PropType^)^.BaseType^ = TypeInfo(Boolean) then
        Result := PropertyValue.CreateBoolean(GetOrdProp(AObject, APropInfo) <> 0)
      else
        Result := PropertyValue.CreateString(WinStr(GetEnumProp(AObject, APropInfo)));
    tkClass:
      begin
        Child := GetObjectProp(AObject, APropInfo);
        if Child = nil then
          Result := nil
        else if Child is TWinUIObject then
          Result := TWinUIObject(Child).WinRTObject
        else
          Result := TWinUIBindable.Create(Child);
      end;
  else
    Result := nil;
  end;
end;

procedure Unbox(AObject: TObject; APropInfo: PPropInfo; const AValue: IInspectable);
var
  V: TWinValue;
begin
  V := AValue;
  case APropInfo^.PropType^.Kind of
    tkUString, tkLString, tkWString, tkString:
      SetStrProp(AObject, APropInfo, V.AsString);
    tkInteger:
      SetOrdProp(AObject, APropInfo, V.AsInteger);
    tkFloat:
      SetFloatProp(AObject, APropInfo, V.AsDouble);
    tkEnumeration:
      if GetTypeData(APropInfo^.PropType^)^.BaseType^ = TypeInfo(Boolean) then
        SetOrdProp(AObject, APropInfo, Ord(V.AsBoolean))
      else
        SetEnumProp(AObject, APropInfo, V.AsString);
  end;
end;

type
  // One published property of a bindable object
  TBindableProperty = class(TWinRTDelegate, IInspectable, ICustomProperty)
  strict private
    FName: string;
    FInfo: PPropInfo;
    function TargetOf(const ATarget: IInspectable): TObject;
  protected
    procedure GetIids(out AIidCount: Cardinal; out AIids: PGUID); safecall;
    function GetRuntimeClassName: HSTRING; safecall;
    function GetTrustLevel: TrustLevel; safecall;
    function get_Type: TypeName; safecall;
    function get_Name: HSTRING; safecall;
    function GetValue(ATarget: IInspectable): IInspectable; safecall;
    procedure SetValue(ATarget: IInspectable; AValue: IInspectable); safecall;
    function GetIndexedValue(ATarget: IInspectable; AIndex: IInspectable): IInspectable; safecall;
    procedure SetIndexedValue(ATarget: IInspectable; AValue: IInspectable; AIndex: IInspectable); safecall;
    function get_CanWrite: Boolean; safecall;
    function get_CanRead: Boolean; safecall;
  public
    constructor Create(const AName: string; AInfo: PPropInfo);
  end;

  TVectorChangedArgs = class(TWinRTDelegate, IInspectable, IVectorChangedEventArgs)
  strict private
    FChange: CollectionChange;
    FIndex: Cardinal;
  protected
    procedure GetIids(out AIidCount: Cardinal; out AIids: PGUID); safecall;
    function GetRuntimeClassName: HSTRING; safecall;
    function GetTrustLevel: TrustLevel; safecall;
    function get_CollectionChange: CollectionChange; safecall;
    function get_Index: Cardinal; safecall;
  public
    constructor Create(AChange: CollectionChange; AIndex: Cardinal);
  end;

  // The list as XAML sees it. Holds a reference back to the Delphi list
  // through callbacks, Detach cuts it when the list is destroyed.
  TBindableVector = class(TWinRTDelegate, IInspectable, IBindableIterable, IBindableVector,
    IBindableObservableVector)
  strict private
    FGetCount: TFunc<Integer>;
    FGetAt: TFunc<Integer, IInspectable>;
    FHandlers: TArray<BindableVectorChangedEventHandler>;
    FTokens: TArray<Int64>;
    FNextToken: Int64;
  protected
    procedure GetIids(out AIidCount: Cardinal; out AIids: PGUID); safecall;
    function GetRuntimeClassName: HSTRING; safecall;
    function GetTrustLevel: TrustLevel; safecall;
    function First: IBindableIterator; safecall;
    function GetAt(AIndex: Cardinal): IInspectable; safecall;
    function get_Size: Cardinal; safecall;
    function GetView: IBindableVectorView; safecall;
    function IndexOf(AValue: IInspectable; out AIndex: Cardinal): Boolean; safecall;
    procedure SetAt(AIndex: Cardinal; AValue: IInspectable); safecall;
    procedure InsertAt(AIndex: Cardinal; AValue: IInspectable); safecall;
    procedure RemoveAt(AIndex: Cardinal); safecall;
    procedure Append(AValue: IInspectable); safecall;
    procedure RemoveAtEnd; safecall;
    procedure Clear; safecall;
    function add_VectorChanged(AHandler: BindableVectorChangedEventHandler): EventRegistrationToken; safecall;
    procedure remove_VectorChanged(AToken: EventRegistrationToken); safecall;
  public
    constructor Create(const AGetCount: TFunc<Integer>; const AGetAt: TFunc<Integer, IInspectable>);
    procedure Changed(AChange: CollectionChange; AIndex: Integer);
    procedure Detach;
  end;

  TBindableIterator = class(TWinRTDelegate, IInspectable, IBindableIterator)
  strict private
    FVector: IBindableVector;
    FIndex: Cardinal;
  protected
    procedure GetIids(out AIidCount: Cardinal; out AIids: PGUID); safecall;
    function GetRuntimeClassName: HSTRING; safecall;
    function GetTrustLevel: TrustLevel; safecall;
    function get_Current: IInspectable; safecall;
    function get_HasCurrent: Boolean; safecall;
    function MoveNext: Boolean; safecall;
  public
    constructor Create(const AVector: IBindableVector);
  end;

{ TWinUIBindable }

constructor TWinUIBindable.Create(ATarget: TObject);
begin
  inherited Create;
  FTarget := ATarget;
end;

procedure TWinUIBindable.Detach;
begin
  FTarget := nil;
end;

function TWinUIBindable.Target: TObject;
begin
  Result := FTarget;
end;

procedure TWinUIBindable.GetIids(out AIidCount: Cardinal; out AIids: PGUID);
begin
  AIidCount := 0;
  AIids := nil;
end;

function TWinUIBindable.GetRuntimeClassName: HSTRING;
begin
  Result := NewHString(BindableClassName);
end;

function TWinUIBindable.GetTrustLevel: TrustLevel;
begin
  Result := 0;
end;

function TWinUIBindable.GetCustomProperty(AName: HSTRING): ICustomProperty;
var
  Name: string;
  Info: PPropInfo;
begin
  Result := nil;
  if FTarget = nil then
    Exit;
  Name := HStringToString(AName);
  Info := GetPropInfo(FTarget, Name);
  if Info <> nil then
    Result := TBindableProperty.Create(Name, Info);
end;

function TWinUIBindable.GetIndexedProperty(AName: HSTRING; AType: TypeName): ICustomProperty;
begin
  Result := nil; // indexers are not bindable
end;

function TWinUIBindable.GetStringRepresentation: HSTRING;
begin
  if FTarget = nil then
    Result := nil
  else
    Result := NewHString(FTarget.ToString);
end;

function TWinUIBindable.get_Type: TypeName;
begin
  if FTarget = nil then
    Result := NewTypeName(BindableClassName, TypeKind.Custom)
  else
    Result := NewTypeName(FTarget.QualifiedClassName, TypeKind.Custom);
end;

function TWinUIBindable.add_PropertyChanged(AHandler: PropertyChangedEventHandler): EventRegistrationToken;
begin
  Inc(FNextToken);
  FHandlers := FHandlers + [AHandler];
  FTokens := FTokens + [FNextToken];
  Result.Value := FNextToken;
end;

procedure TWinUIBindable.remove_PropertyChanged(AToken: EventRegistrationToken);
var
  I: Integer;
begin
  for I := High(FTokens) downto 0 do
    if FTokens[I] = AToken.Value then
    begin
      Delete(FHandlers, I, 1);
      Delete(FTokens, I, 1);
    end;
end;

procedure TWinUIBindable.NotifyPropertyChanged(const AName: string);
var
  Args: IPropertyChangedEventArgs;
  Handler: PropertyChangedEventHandler;
begin
  if FHandlers = nil then
    Exit;
  Args := PropertyChangedEventArgs.New(WinStr(AName));
  for Handler in Copy(FHandlers) do
    Handler.Invoke(Self as IInspectable, Args);
end;

{ TBindableProperty }

constructor TBindableProperty.Create(const AName: string; AInfo: PPropInfo);
begin
  inherited Create;
  FName := AName;
  FInfo := AInfo;
end;

function TBindableProperty.TargetOf(const ATarget: IInspectable): TObject;
var
  B: IWinUIBindableTarget;
begin
  if Supports(ATarget, IWinUIBindableTarget, B) then
    Result := B.Target
  else
    Result := nil;
end;

procedure TBindableProperty.GetIids(out AIidCount: Cardinal; out AIids: PGUID);
begin
  AIidCount := 0;
  AIids := nil;
end;

function TBindableProperty.GetRuntimeClassName: HSTRING;
begin
  Result := NewHString('RADWinUI.BindableProperty');
end;

function TBindableProperty.GetTrustLevel: TrustLevel;
begin
  Result := 0;
end;

function TBindableProperty.get_Type: TypeName;
begin
  Result := NewTypeName('Object', TypeKind.Primitive);
end;

function TBindableProperty.get_Name: HSTRING;
begin
  Result := NewHString(FName);
end;

function TBindableProperty.GetValue(ATarget: IInspectable): IInspectable;
var
  Obj: TObject;
begin
  Obj := TargetOf(ATarget);
  if Obj = nil then
    Result := nil
  else
    Result := Box(Obj, FInfo);
end;

procedure TBindableProperty.SetValue(ATarget: IInspectable; AValue: IInspectable);
var
  Obj: TObject;
begin
  Obj := TargetOf(ATarget);
  if (Obj <> nil) and (FInfo^.SetProc <> nil) then
    Unbox(Obj, FInfo, AValue);
end;

function TBindableProperty.GetIndexedValue(ATarget: IInspectable; AIndex: IInspectable): IInspectable;
begin
  Result := nil;
end;

procedure TBindableProperty.SetIndexedValue(ATarget: IInspectable; AValue: IInspectable; AIndex: IInspectable);
begin
end;

function TBindableProperty.get_CanWrite: Boolean;
begin
  Result := FInfo^.SetProc <> nil;
end;

function TBindableProperty.get_CanRead: Boolean;
begin
  Result := FInfo^.GetProc <> nil;
end;

{ TVectorChangedArgs }

constructor TVectorChangedArgs.Create(AChange: CollectionChange; AIndex: Cardinal);
begin
  inherited Create;
  FChange := AChange;
  FIndex := AIndex;
end;

procedure TVectorChangedArgs.GetIids(out AIidCount: Cardinal; out AIids: PGUID);
begin
  AIidCount := 0;
  AIids := nil;
end;

function TVectorChangedArgs.GetRuntimeClassName: HSTRING;
begin
  Result := NewHString('RADWinUI.VectorChangedEventArgs');
end;

function TVectorChangedArgs.GetTrustLevel: TrustLevel;
begin
  Result := 0;
end;

function TVectorChangedArgs.get_CollectionChange: CollectionChange;
begin
  Result := FChange;
end;

function TVectorChangedArgs.get_Index: Cardinal;
begin
  Result := FIndex;
end;

{ TBindableVector }

constructor TBindableVector.Create(const AGetCount: TFunc<Integer>; const AGetAt: TFunc<Integer, IInspectable>);
begin
  inherited Create;
  FGetCount := AGetCount;
  FGetAt := AGetAt;
end;

procedure TBindableVector.Detach;
begin
  FGetCount := nil;
  FGetAt := nil;
  FHandlers := nil;
  FTokens := nil;
end;

procedure TBindableVector.GetIids(out AIidCount: Cardinal; out AIids: PGUID);
begin
  AIidCount := 0;
  AIids := nil;
end;

function TBindableVector.GetRuntimeClassName: HSTRING;
begin
  Result := NewHString('RADWinUI.BindableList');
end;

function TBindableVector.GetTrustLevel: TrustLevel;
begin
  Result := 0;
end;

function TBindableVector.First: IBindableIterator;
begin
  Result := TBindableIterator.Create(Self);
end;

function TBindableVector.get_Size: Cardinal;
begin
  if Assigned(FGetCount) then
    Result := FGetCount()
  else
    Result := 0;
end;

function TBindableVector.GetAt(AIndex: Cardinal): IInspectable;
begin
  if AIndex >= get_Size then
    raise EWinRTError.CreateMsg(E_BOUNDS, 'Index out of range');
  Result := FGetAt(AIndex);
end;

function TBindableVector.GetView: IBindableVectorView;
begin
  Result := nil; // not used by ItemsSource
end;

function TBindableVector.IndexOf(AValue: IInspectable; out AIndex: Cardinal): Boolean;
var
  I: Integer;
  Unk, Item: IUnknown;
begin
  AIndex := 0;
  Unk := AValue as IUnknown;
  for I := 0 to Integer(get_Size) - 1 do
  begin
    Item := FGetAt(I) as IUnknown;
    if Item = Unk then
    begin
      AIndex := I;
      Exit(True);
    end;
  end;
  Result := False;
end;

// XAML only reads ItemsSource, the Delphi list is changed from Delphi code.
procedure TBindableVector.SetAt(AIndex: Cardinal; AValue: IInspectable);
begin
  raise EWinRTError.CreateMsg(E_NOTIMPL, 'The list is read-only for XAML');
end;

procedure TBindableVector.InsertAt(AIndex: Cardinal; AValue: IInspectable);
begin
  raise EWinRTError.CreateMsg(E_NOTIMPL, 'The list is read-only for XAML');
end;

procedure TBindableVector.RemoveAt(AIndex: Cardinal);
begin
  raise EWinRTError.CreateMsg(E_NOTIMPL, 'The list is read-only for XAML');
end;

procedure TBindableVector.Append(AValue: IInspectable);
begin
  raise EWinRTError.CreateMsg(E_NOTIMPL, 'The list is read-only for XAML');
end;

procedure TBindableVector.RemoveAtEnd;
begin
  raise EWinRTError.CreateMsg(E_NOTIMPL, 'The list is read-only for XAML');
end;

procedure TBindableVector.Clear;
begin
  raise EWinRTError.CreateMsg(E_NOTIMPL, 'The list is read-only for XAML');
end;

function TBindableVector.add_VectorChanged(AHandler: BindableVectorChangedEventHandler): EventRegistrationToken;
begin
  Inc(FNextToken);
  FHandlers := FHandlers + [AHandler];
  FTokens := FTokens + [FNextToken];
  Result.Value := FNextToken;
end;

procedure TBindableVector.remove_VectorChanged(AToken: EventRegistrationToken);
var
  I: Integer;
begin
  for I := High(FTokens) downto 0 do
    if FTokens[I] = AToken.Value then
    begin
      Delete(FHandlers, I, 1);
      Delete(FTokens, I, 1);
    end;
end;

procedure TBindableVector.Changed(AChange: CollectionChange; AIndex: Integer);
var
  Args: IInspectable;
  Handler: BindableVectorChangedEventHandler;
begin
  if FHandlers = nil then
    Exit;
  Args := TVectorChangedArgs.Create(AChange, AIndex);
  for Handler in Copy(FHandlers) do
    Handler.Invoke(Self, Args);
end;

{ TBindableIterator }

constructor TBindableIterator.Create(const AVector: IBindableVector);
begin
  inherited Create;
  FVector := AVector;
end;

procedure TBindableIterator.GetIids(out AIidCount: Cardinal; out AIids: PGUID);
begin
  AIidCount := 0;
  AIids := nil;
end;

function TBindableIterator.GetRuntimeClassName: HSTRING;
begin
  Result := NewHString('RADWinUI.BindableIterator');
end;

function TBindableIterator.GetTrustLevel: TrustLevel;
begin
  Result := 0;
end;

function TBindableIterator.get_Current: IInspectable;
begin
  Result := FVector.GetAt(FIndex);
end;

function TBindableIterator.get_HasCurrent: Boolean;
begin
  Result := FIndex < FVector.Size;
end;

function TBindableIterator.MoveNext: Boolean;
begin
  if FIndex < FVector.Size then
    Inc(FIndex);
  Result := FIndex < FVector.Size;
end;

{ TWinUIValueConverter }

procedure ExpectLifetimeOfApp(const AIntf: IInterface);
begin
  if AIntf <> nil then
    RegisterExpectedMemoryLeak(AIntf as TObject);
end;

constructor TWinUIValueConverter.Create(const AConvert, AConvertBack: TWinUIConvertFunc);
begin
  inherited Create;
  FConvert := AConvert;
  FConvertBack := AConvertBack;
  // A converter lives in the application resources, which WinUI releases when it
  // tears down, possibly after Delphi's leak check at exit: not a leak.
  RegisterExpectedMemoryLeak(Self);
  ExpectLifetimeOfApp(IInterface(PPointer(@FConvert)^));
  ExpectLifetimeOfApp(IInterface(PPointer(@FConvertBack)^));
end;

procedure TWinUIValueConverter.GetIids(out AIidCount: Cardinal; out AIids: PGUID);
begin
  AIidCount := 0;
  AIids := nil;
end;

function TWinUIValueConverter.GetRuntimeClassName: HSTRING;
begin
  Result := NewHString('RADWinUI.ValueConverter');
end;

function TWinUIValueConverter.GetTrustLevel: TrustLevel;
begin
  Result := 0;
end;

function TWinUIValueConverter.Convert(AValue: IInspectable; ATargetType: TypeName;
  AParameter: IInspectable; ALanguage: HSTRING): IInspectable;
begin
  Result := FConvert(TWinValue(AValue), TWinValue(AParameter).AsString).Obj;
end;

function TWinUIValueConverter.ConvertBack(AValue: IInspectable; ATargetType: TypeName;
  AParameter: IInspectable; ALanguage: HSTRING): IInspectable;
begin
  if not Assigned(FConvertBack) then
    raise EWinRTError.CreateMsg(E_NOTIMPL, 'The converter has no ConvertBack');
  Result := FConvertBack(TWinValue(AValue), TWinValue(AParameter).AsString).Obj;
end;

{ TWinUIBindableObject }

destructor TWinUIBindableObject.Destroy;
begin
  // XAML may still hold the binding object: it reads nothing from now on.
  if FBindable <> nil then
    FBindable.Detach;
  inherited;
end;

function TWinUIBindableObject.GetValue: IInspectable;
begin
  // One binding object per Delphi object, so XAML's change handlers stay attached.
  if FBindable = nil then
  begin
    FBindable := TWinUIBindable.Create(Self);
    FBindableRef := FBindable;
  end;
  Result := FBindableRef;
end;

procedure TWinUIBindableObject.Changed(const APropertyName: string);
begin
  if FBindable <> nil then
    FBindable.NotifyPropertyChanged(APropertyName);
end;

{ TWinUIBindableListBase }

constructor TWinUIBindableListBase.Create;
var
  Vector: TBindableVector;
begin
  inherited Create;
  Vector := TBindableVector.Create(
    function: Integer
    begin
      Result := GetCount;
    end,
    function(AIndex: Integer): IInspectable
    begin
      Result := GetBindable(AIndex);
    end);
  FVectorObject := Vector;
  FVector := Vector; // keeps it alive, XAML holds its own references
end;

destructor TWinUIBindableListBase.Destroy;
begin
  // XAML may still hold the vector: make it an empty list that no longer calls back.
  TBindableVector(FVectorObject).Detach;
  inherited;
end;

function TWinUIBindableListBase.GetValue: IInspectable;
begin
  Result := FVector;
end;

procedure TWinUIBindableListBase.Changed(AChange: CollectionChange; AIndex: Integer);
begin
  TBindableVector(FVectorObject).Changed(AChange, AIndex);
end;

{ TWinUIBindableList<T> }

constructor TWinUIBindableList<T>.Create(AOwnsObjects: Boolean);
begin
  inherited Create;
  FOwnsObjects := AOwnsObjects;
end;

destructor TWinUIBindableList<T>.Destroy;
var
  I: Integer;
begin
  for I := High(FItems) downto 0 do
    ReleaseItem(I);
  inherited;
end;

function TWinUIBindableList<T>.GetBindable(AIndex: Integer): IInspectable;
begin
  Result := BindableAt(AIndex);
end;

function TWinUIBindableList<T>.GetCount: Integer;
begin
  Result := Length(FItems);
end;

function TWinUIBindableList<T>.GetItem(AIndex: Integer): T;
begin
  Result := FItems[AIndex];
end;

function TWinUIBindableList<T>.BindableAt(AIndex: Integer): IInspectable;
begin
  // A TWinUIBindableObject item notifies through its own binding object
  if TObject(FItems[AIndex]) is TWinUIBindableObject then
    Exit(TWinUIBindableObject(TObject(FItems[AIndex])).GetValue);
  if FBindableRefs[AIndex] = nil then
  begin
    FBindables[AIndex] := TWinUIBindable.Create(FItems[AIndex]);
    FBindableRefs[AIndex] := FBindables[AIndex];
  end;
  Result := FBindableRefs[AIndex];
end;

procedure TWinUIBindableList<T>.ReleaseItem(AIndex: Integer);
begin
  if FBindables[AIndex] <> nil then
    FBindables[AIndex].Detach;
  if FOwnsObjects then
    FItems[AIndex].Free;
end;

function TWinUIBindableList<T>.Add(AItem: T): Integer;
begin
  Result := Length(FItems);
  Insert(Result, AItem);
end;

procedure TWinUIBindableList<T>.Insert(AIndex: Integer; AItem: T);
begin
  System.Insert(AItem, FItems, AIndex);
  System.Insert(TWinUIBindable(nil), FBindables, AIndex);
  System.Insert(IInspectable(nil), FBindableRefs, AIndex);
  Changed(CollectionChange.ItemInserted, AIndex);
end;

procedure TWinUIBindableList<T>.Delete(AIndex: Integer);
begin
  ReleaseItem(AIndex);
  System.Delete(FItems, AIndex, 1);
  System.Delete(FBindables, AIndex, 1);
  System.Delete(FBindableRefs, AIndex, 1);
  Changed(CollectionChange.ItemRemoved, AIndex);
end;

procedure TWinUIBindableList<T>.Clear;
var
  I: Integer;
begin
  for I := High(FItems) downto 0 do
    ReleaseItem(I);
  FItems := nil;
  FBindables := nil;
  FBindableRefs := nil;
  Changed(CollectionChange.Reset, 0);
end;

function TWinUIBindableList<T>.IndexOf(AItem: T): Integer;
var
  I: Integer;
begin
  for I := 0 to High(FItems) do
    if TObject(FItems[I]) = TObject(AItem) then
      Exit(I);
  Result := -1;
end;

procedure TWinUIBindableList<T>.ItemChanged(AItem: T; const APropertyName: string);
var
  Index: Integer;
begin
  if TObject(AItem) is TWinUIBindableObject then
  begin
    TWinUIBindableObject(TObject(AItem)).Changed(APropertyName);
    Exit;
  end;
  Index := IndexOf(AItem);
  if (Index >= 0) and (FBindables[Index] <> nil) then
    FBindables[Index].NotifyPropertyChanged(APropertyName);
end;

end.
