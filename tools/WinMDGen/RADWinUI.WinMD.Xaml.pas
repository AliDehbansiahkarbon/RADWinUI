unit RADWinUI.WinMD.Xaml;

(*
  Wrapper class emitter (the API is described in docs\FRAMEWORK-API.md).

  Writes one Delphi class per runtime class in Microsoft.UI.* (controls,
  event args, windowing, composition), named TWinUI<Name>. The class tree
  mirrors the WinRT one, and each class merges the properties, events and
  simple methods of every public interface its runtime class implements,
  mapped to Delphi types: string for HSTRING, wrapper classes for runtime
  classes, TWinValue for Object, TWinUIList<T> / TWinUIValueList for vectors,
  TWinUI<Name> aliases for enums and structs. Each event has an OnXxx method
  pointer and an Xxx event object for anonymous-method listeners.

  Also writes the type index XamlCodeGen reads instead of the .winmd files.
  Runs after TProjection.Emit, whose names it reuses for the ABI types.
*)

interface

uses
  System.SysUtils, System.Classes, System.Character, System.Generics.Collections,
  RADWinUI.WinMD.Model, RADWinUI.WinMD.Pascal;

type
  /// <summary>How a WinRT type appears in a wrapper and how values convert.</summary>
  TMapping = class
  public
    Kind: string;  // string, value, wrapper, list, valuelist, raw
    PType: string; // Pascal type in the wrapper
    Abi: string;   // ABI interface for wrapper conversions
    VectorIid, ElementIid: string;
    function ToDelphi(const AExpr: string): string;
    function ToAbi(const AExpr: string): string;
    function ParamDecl(const AName: string): string;
    function IsList: Boolean;
  end;

  TEventInfo = record
    EventType, DelegateClass, Params: string;
    Args: TMapping;
  end;

  TPropEntry = record
    Name: string;
    Mp: TMapping;
    Accessor, Getter, Setter: string; // Setter '' when read-only
  end;

  TEventEntry = record
    Name: string;
    Info: TEventInfo;
    Accessor, Add, Remove: string;
  end;

  TParamEntry = record
    Name: string;
    Mp: TMapping;
  end;

  TMethodEntry = record
    Name: string;
    Params: TArray<TParamEntry>;
    Ret: TMapping; // nil for procedures
    Accessor, Abi: string;
    Overload: Boolean;
  end;

  TClassMembers = record
    Props: TArray<TPropEntry>;
    Events: TArray<TEventEntry>;
    Methods: TArray<TMethodEntry>;
    Interfaces: TArray<TTypeDef>;
  end;

  TXamlWrappers = class
  private
    P: TProjection;
    U: TUniverse;
    FMappings: TObjectList<TMapping>;
    FUsedTypes: TStringSet;
    FMembers: TDictionary<string, TClassMembers>;
    procedure Claim(const AName: string);
    function SelectClasses: TArray<TTypeDef>;
    function NewMapping(const AKind, APType: string; const AAbi: string = ''; const AVectorIid: string = '';
      const AElementIid: string = ''): TMapping;
    function AbiType(ARef: TTypeRef): string;
    function Map(ARef: TTypeRef): TMapping;
    function Alias(const AFullName: string): string;
    function EventType(AArgs: TMapping): string;
    function InterfacesOf(T: TTypeDef): TArray<TTypeDef>;
    function ClassMembers(T: TTypeDef): TClassMembers;
    function MethodSig(M: TMethod; out AParams: TArray<TParamEntry>; out ARet: TMapping): Boolean;
    function EventInfo(ARef: TTypeRef; out AInfo: TEventInfo): Boolean;
    function EnumBoxes: TArray<string>;
    function HasDefaultNew(T: TTypeDef): Boolean;
    function IsUIElement(T: TTypeDef): Boolean;
    function PropKind(Mp: TMapping): string;
    function MethodDecl(const AName: string; const AParams: TArray<TParamEntry>; ARet: TMapping): string;
    procedure EmitClass(AOut, AImpl: TStrings; T: TTypeDef; const Mem: TClassMembers);
    function MembersOf(T: TTypeDef): TClassMembers;
  public
    UnitName, Header, AbiUnit: string;
    Classes: TArray<TTypeDef>;
    WrapperNames: TDictionary<string, string>;
    EventTypes: TDictionary<string, string>; // args Pascal type -> method pointer type
    Aliases: TDictionary<string, string>;    // enum or struct full name -> TWinUI alias
    constructor Create(AProjection: TProjection; const AUnitName, AHeader: string);
    destructor Destroy; override;
    function Emit: string;
    /// <summary>The JSON type index for XamlCodeGen. Keep the format stable: regenerating must give identical files.</summary>
    function TypeIndex(out ATypeCount: Integer): string;
  end;

implementation

const
  NamespaceRoot = 'Microsoft.UI';
  Prefix = 'TWinUI';
  FrameworkTypes =
    ',twinuiobject,twinuiobjectclass,twinuiclassparent,twinvalue,twinuivector,twinuilist,twinuivaluelist,' +
    'twinuievent,twinuieventproc,twinuiwindow,twinuiwindowclass,twinuiapp,twinuiapplication,twinuitimer,' +
    'twinuibackdrop,twinuiexceptionevent,twinuiapplicationclass,';
  VectorName = 'Windows.Foundation.Collections.IVector';
  ObservableVectorName = 'Windows.Foundation.Collections.IObservableVector';
  IInspectableIid = '{AF86E2E0-B12D-4C6A-9C5A-D7AA65101E90}';
  // Namespaces XAML's default xmlns maps, in lookup order for duplicate simple names
  XamlNamespaces: array[0..12] of string = ('Microsoft.UI.Xaml.Controls', 'Microsoft.UI.Xaml.Controls.Primitives',
    'Microsoft.UI.Xaml', 'Microsoft.UI.Xaml.Shapes', 'Microsoft.UI.Xaml.Media', 'Microsoft.UI.Xaml.Media.Animation',
    'Microsoft.UI.Xaml.Media.Imaging', 'Microsoft.UI.Xaml.Media.Media3D', 'Microsoft.UI.Xaml.Documents',
    'Microsoft.UI.Xaml.Input', 'Microsoft.UI.Xaml.Data', 'Microsoft.UI.Xaml.Navigation',
    'Microsoft.UI.Xaml.Automation');
  // Names that TObject and TWinUIObject already use, WinRT members with these
  // names are left out of the wrappers (they stay reachable through Intf).
  ReservedMembers =
    ',create,free,destroy,classname,classtype,classinfo,classparent,instancesize,inheritsfrom,methodaddress,' +
    'methodname,fieldaddress,getinterface,getinterfaceentry,getinterfacetable,unitname,unitscope,equals,' +
    'gethashcode,tostring,safecallexception,afterconstruction,beforedestruction,dispatch,defaulthandler,' +
    'newinstance,freeinstance,cleanupinstance,initinstance,disposeof,qualifiedclassname,disposed,owner,' +
    'winrtobject,createfrom,wrap,registerwrapper,intfof,detachevents,wrapowner,addhelper,intf,';

function InList(const AList, AName: string): Boolean;
begin
  Result := Pos(',' + AName + ',', AList) > 0;
end;

/// <summary>Pascal types that are not declared in the ABI unit, so never get qualified.</summary>
function Unqualified(const AName: string): Boolean;
var
  S: string;
begin
  for S in PrimitivePascalNames do
    if S = AName then
      Exit(True);
  Result := (AName = 'Pointer') or (AName = 'IUnknown') or (AName = 'IInspectable') or (AName = 'HRESULT');
end;

function AfterLastDot(const AText: string): string;
begin
  Result := AText.Substring(AText.LastIndexOf('.') + 1);
end;

function FindMethod(Td: TTypeDef; const AName: string): TMethod;
var
  M: TMethod;
begin
  for M in Td.Methods do
    if M.Name = AName then
      Exit(M);
  Result := nil;
end;

function SortedKeysByValue(ADict: TDictionary<string, string>): TArray<string>;
var
  I, J: Integer;
  K: string;
begin
  Result := ADict.Keys.ToArray;
  for I := 1 to High(Result) do
  begin
    K := Result[I];
    J := I - 1;
    while (J >= 0) and (CompareStr(ADict[Result[J]], ADict[K]) > 0) do
    begin
      Result[J + 1] := Result[J];
      Dec(J);
    end;
    Result[J + 1] := K;
  end;
end;

function SortedEnumValues(Td: TTypeDef): TArray<TEnumValue>;
var
  I, J: Integer;
  V: TEnumValue;
begin
  Result := Copy(Td.EnumValues);
  for I := 1 to High(Result) do
  begin
    V := Result[I];
    J := I - 1;
    while (J >= 0) and (Result[J].Value > V.Value) do
    begin
      Result[J + 1] := Result[J];
      Dec(J);
    end;
    Result[J + 1] := V;
  end;
end;

{ TMapping }

function TMapping.ToDelphi(const AExpr: string): string;
begin
  if Kind = 'string' then
    Result := 'TakeHString(' + AExpr + ')'
  else if Kind = 'wrapper' then
    Result := PType + '(TWinUIObject.Wrap(WrapOwner, ' + AExpr + ', ' + PType + '))'
  else
    Result := AExpr; // value converts implicitly, raw is unchanged
end;

function TMapping.ToAbi(const AExpr: string): string;
begin
  if Kind = 'string' then
    Result := 'WinStr(' + AExpr + ')'
  else if Kind = 'value' then
    Result := AExpr + '.Obj'
  else if Kind = 'wrapper' then
    Result := Abi + '(TWinUIObject.IntfOf(' + AExpr + ', ' + Abi + '))'
  else
    Result := AExpr;
end;

function TMapping.ParamDecl(const AName: string): string;
begin
  if (Kind = 'string') or (Kind = 'value') then
    Result := 'const ' + AName + ': ' + PType
  else
    Result := AName + ': ' + PType;
end;

function TMapping.IsList: Boolean;
begin
  Result := (Kind = 'list') or (Kind = 'valuelist');
end;

{ TXamlWrappers }

constructor TXamlWrappers.Create(AProjection: TProjection; const AUnitName, AHeader: string);
var
  T: TTypeDef;
  Name: string;
begin
  inherited Create;
  P := AProjection;
  U := P.U;
  UnitName := AUnitName;
  Header := AHeader;
  AbiUnit := P.UnitName;
  FMappings := TObjectList<TMapping>.Create(True);
  FUsedTypes := TStringSet.Create;
  FMembers := TDictionary<string, TClassMembers>.Create;
  WrapperNames := TDictionary<string, string>.Create;
  EventTypes := TDictionary<string, string>.Create;
  Aliases := TDictionary<string, string>.Create;
  for Name in FrameworkTypes.Split([','], TStringSplitOptions.ExcludeEmpty) do
    FUsedTypes.AddOrSetValue(Name, True);
  Classes := SelectClasses;
  for T in Classes do
  begin
    if T.FullName = 'Microsoft.UI.Xaml.Window' then
      Name := 'TWinUICustomWindow' // TWinUIWindow derives from it
    else if T.FullName = 'Microsoft.UI.Xaml.Application' then
      Name := 'TWinUICustomApplication' // TWinUIApplication is the Delphi app
    else
      Name := Prefix + StripAmp(P.Names[T.FullName]);
    WrapperNames.AddOrSetValue(T.FullName, Name);
  end;
  for T in Classes do
    Claim(WrapperNames[T.FullName]);
end;

destructor TXamlWrappers.Destroy;
begin
  Aliases.Free;
  EventTypes.Free;
  WrapperNames.Free;
  FMembers.Free;
  FUsedTypes.Free;
  FMappings.Free;
  inherited;
end;

procedure TXamlWrappers.Claim(const AName: string);
begin
  if FUsedTypes.ContainsKey(AName.ToLower) then
    raise EModelError.CreateFmt('generated type name %s is already taken; add it to the special names', [AName]);
  FUsedTypes.Add(AName.ToLower, True);
end;

function TXamlWrappers.SelectClasses: TArray<TTypeDef>;
var
  Names: TStringSet;
  Depth: TDictionary<string, Integer>;
  Chosen: TArray<TTypeDef>;
  Levels: TArray<Integer>;
  T: TTypeDef;
  I, J, L: Integer;

  function Level(T: TTypeDef): Integer;
  var
    Base: TTypeDef;
  begin
    if not Depth.TryGetValue(T.FullName, Result) then
    begin
      Base := nil;
      if T.Base <> nil then
        Base := U.Find(T.Base.Name);
      if (Base <> nil) and Names.ContainsKey(Base.FullName) then
        Result := Level(Base) + 1
      else
        Result := 0;
      Depth.AddOrSetValue(T.FullName, Result);
    end;
  end;

  function Less(A: TTypeDef; LA: Integer; B: TTypeDef; LB: Integer): Boolean;
  begin
    if LA <> LB then
      Result := LA < LB
    else
      Result := CompareStr(A.FullName, B.FullName) < 0;
  end;

begin
  Chosen := nil;
  for T in P.Included do
    if (T.Kind = 'class') and (Length(T.GenericParams) = 0) and (T.DefaultInterface <> nil) and
      ((T.Namespace = NamespaceRoot) or T.Namespace.StartsWith(NamespaceRoot + '.')) and
      not T.DefaultInterface.IsGenericInstance then
      Chosen := Chosen + [T];
  Names := TStringSet.Create;
  Depth := TDictionary<string, Integer>.Create;
  try
    for T in Chosen do
      Names.AddOrSetValue(T.FullName, True);
    SetLength(Levels, Length(Chosen));
    for I := 0 to High(Chosen) do
      Levels[I] := Level(Chosen[I]);
    for I := 1 to High(Chosen) do
    begin
      T := Chosen[I];
      L := Levels[I];
      J := I - 1;
      while (J >= 0) and Less(T, L, Chosen[J], Levels[J]) do
      begin
        Chosen[J + 1] := Chosen[J];
        Levels[J + 1] := Levels[J];
        Dec(J);
      end;
      Chosen[J + 1] := T;
      Levels[J + 1] := L;
    end;
  finally
    Depth.Free;
    Names.Free;
  end;
  Result := Chosen;
end;

function TXamlWrappers.NewMapping(const AKind, APType, AAbi, AVectorIid, AElementIid: string): TMapping;
begin
  Result := TMapping.Create;
  FMappings.Add(Result);
  Result.Kind := AKind;
  Result.PType := APType;
  Result.Abi := AAbi;
  Result.VectorIid := AVectorIid;
  Result.ElementIid := AElementIid;
end;

function TXamlWrappers.AbiType(ARef: TTypeRef): string;
begin
  Result := P.TypeName(ARef);
  if not Unqualified(Result) then
    Result := AbiUnit + '.' + Result;
end;

function TXamlWrappers.Map(ARef: TTypeRef): TMapping;
var
  Td, Etd: TTypeDef;
  Vector, Elem: TTypeRef;
  VectorIid: string;
begin
  Result := nil;
  if (ARef = nil) or (ARef.Kind in [rkSzArray, rkByRef, rkVar]) then
    Exit;
  if ARef.Kind = rkPrim then
  begin
    if ARef.Name = 'String' then
      Exit(NewMapping('string', 'string'));
    if ARef.Name = 'Object' then
      Exit(NewMapping('value', 'TWinValue'));
    Exit(NewMapping('raw', AbiType(ARef)));
  end;
  if P.Unknown.ContainsKey(ARef.Name) then
    Exit;
  Td := U.Find(ARef.Name);
  if Td = nil then
    Exit;
  if (Length(ARef.Args) = 0) and ((Td.Kind = 'enum') or (Td.Kind = 'struct')) and
    not Unqualified(P.TypeName(ARef)) then
    Exit(NewMapping('raw', Alias(Td.FullName)));
  if (Length(ARef.Args) = 0) and WrapperNames.ContainsKey(Td.FullName) then
    Exit(NewMapping('wrapper', WrapperNames[Td.FullName], AbiType(Td.DefaultInterface)));
  if Length(ARef.Args) > 0 then
    Vector := ARef
  else if Td.Kind = 'class' then
    Vector := Td.DefaultInterface
  else
    Vector := nil;
  if (Vector <> nil) and (Vector.Kind = rkNamed) and
    ((Vector.Name = VectorName) or (Vector.Name = ObservableVectorName)) and (Length(Vector.Args) = 1) then
  begin
    Elem := Vector.Args[0];
    VectorIid := GuidText(U.Iid(U.Named(VectorName, Vector.Args)));
    if Elem = U.Prim('Object') then
      Exit(NewMapping('valuelist', 'TWinUIValueList', '', VectorIid, IInspectableIid));
    if (Elem.Kind = rkNamed) and (Length(Elem.Args) = 0) and WrapperNames.ContainsKey(Elem.Name) then
    begin
      Etd := U.Get(Elem.Name);
      Exit(NewMapping('list', 'TWinUIList<' + WrapperNames[Elem.Name] + '>', '', VectorIid,
        GuidText(U.Iid(Etd.DefaultInterface))));
    end;
  end;
  if P.TypeName(ARef) = 'Pointer' then
    Exit;
  Result := NewMapping('raw', AbiType(ARef));
end;

function TXamlWrappers.Alias(const AFullName: string): string;
var
  Base: string;
  N: Integer;
begin
  if not Aliases.TryGetValue(AFullName, Result) then
  begin
    Base := Prefix + StripAmp(P.Names[AFullName]);
    Result := Base;
    N := 2;
    while FUsedTypes.ContainsKey(Result.ToLower) do
    begin
      Result := Base + IntToStr(N);
      Inc(N);
    end;
    Claim(Result);
    Aliases.Add(AFullName, Result);
  end;
end;

function TXamlWrappers.EventType(AArgs: TMapping): string;
var
  Key, Bare: string;
  N: Integer;
begin
  Key := AArgs.PType;
  if not EventTypes.TryGetValue(Key, Result) then
  begin
    Bare := StripAmp(AfterLastDot(Key));
    if Bare.StartsWith(Prefix) then
      Bare := Bare.Substring(Length(Prefix))
    else if (Bare.Length > 1) and (Bare.Chars[0] = 'I') and Bare.Chars[1].IsUpper then
      Bare := Bare.Substring(1)
    else if Bare.StartsWith('T') and (Bare.Length > 1) and Bare.Chars[1].IsUpper then
      Bare := Bare.Substring(1); // TWinValue
    if Bare.EndsWith('Args') then
      Bare := Bare.Substring(0, Bare.Length - 4);
    if not Bare.EndsWith('Event') then
      Bare := Bare + 'Event';
    Bare := Bare + 'Handler'; // as the WinRT delegates, TWinUIRoutedEvent is a wrapper class
    Result := Prefix + Bare;
    N := 2;
    while FUsedTypes.ContainsKey(Result.ToLower) do
    begin
      Result := Prefix + Bare + IntToStr(N);
      Inc(N);
    end;
    Claim(Result);
    EventTypes.Add(Key, Result);
  end;
end;

function TXamlWrappers.InterfacesOf(T: TTypeDef): TArray<TTypeDef>;
var
  Impl: TInterfaceImpl;
  Td: TTypeDef;
  Pass: Integer;
begin
  Result := nil;
  // the default interface first, the rest in metadata order
  for Pass := 0 to 1 do
    for Impl in T.Interfaces do
    begin
      if Impl.IsDefault <> (Pass = 0) then
        Continue;
      if Impl.IsOverridable or Impl.IsProtected or (Length(Impl.TypeRef.Args) > 0) then
        Continue;
      Td := U.Find(Impl.TypeRef.Name);
      if (Td <> nil) and P.IncludedNames.ContainsKey(Td.FullName) and (Td.Kind = 'interface') then
        Result := Result + [Td];
    end;
end;

function TXamlWrappers.ClassMembers(T: TTypeDef): TClassMembers;
var
  Used: TStringSet;
  Itd: TTypeDef;
  MNames: TMethodNames;
  Accessor, PName, Key: string;
  Prop: TProperty;
  Ev: TEvent;
  G, S, Add, Rem, M: TMethod;
  Mp: TMapping;
  PE: TPropEntry;
  EE: TEventEntry;
  ME: TMethodEntry;
  Info: TEventInfo;
  Candidates, Kept: TArray<TMethodEntry>;
  Keys: TArray<string>;
  Params: TArray<TParamEntry>;
  Ret: TMapping;
  I, J, Count: Integer;
  Dup: Boolean;

  function IsUsed(const AName: string): Boolean;
  begin
    Result := Used.ContainsKey(AName.ToLower) or InList(ReservedMembers, AName.ToLower);
  end;

  function ParamKey(const AParams: TArray<TParamEntry>): string;
  var
    Parts: TArray<string>;
    K: Integer;
  begin
    SetLength(Parts, Length(AParams));
    for K := 0 to High(AParams) do
      Parts[K] := AParams[K].Mp.PType.ToLower;
    Result := string.Join(#0, Parts);
  end;

begin
  Result := Default(TClassMembers);
  Candidates := nil;
  Used := TStringSet.Create;
  try
    for Itd in InterfacesOf(T) do
    begin
      MNames := P.MethodNames(Itd);
      Accessor := '_' + StripAmp(P.Names[Itd.FullName]);
      for Prop in Itd.Properties do
      begin
        G := FindMethod(Itd, Prop.Getter);
        if (G = nil) or (G.Params.Count > 0) or IsUsed(Prop.Name) then
          Continue;
        Mp := Map(G.ReturnType);
        if Mp = nil then
          Continue;
        S := FindMethod(Itd, Prop.Setter);
        if (S <> nil) and ((S.Params.Count <> 1) or Mp.IsList) then
          S := nil;
        Used.AddOrSetValue(Prop.Name.ToLower, True);
        PE.Name := Prop.Name;
        PE.Mp := Mp;
        PE.Accessor := Accessor;
        PE.Getter := MNames[G];
        if S <> nil then
          PE.Setter := MNames[S]
        else
          PE.Setter := '';
        Result.Props := Result.Props + [PE];
      end;
      for Ev in Itd.Events do
      begin
        PName := 'On' + Ev.Name;
        if IsUsed(PName) or IsUsed(Ev.Name) then
          Continue;
        if not EventInfo(Ev.TypeRef, Info) then
          Continue;
        Add := FindMethod(Itd, Ev.Add);
        Rem := FindMethod(Itd, Ev.Remove);
        if (Add = nil) or (Rem = nil) then
          Continue;
        Used.AddOrSetValue(PName.ToLower, True);
        Used.AddOrSetValue(Ev.Name.ToLower, True);
        EE.Name := Ev.Name;
        EE.Info := Info;
        EE.Accessor := Accessor;
        EE.Add := MNames[Add];
        EE.Remove := MNames[Rem];
        Result.Events := Result.Events + [EE];
      end;
      for M in Itd.Methods do
      begin
        if M.Special or InList(ReservedMembers, M.Name.ToLower) then
          Continue;
        if not MethodSig(M, Params, Ret) then
          Continue;
        ME.Name := M.Name;
        ME.Params := Params;
        ME.Ret := Ret;
        ME.Accessor := Accessor;
        ME.Abi := MNames[M];
        ME.Overload := False;
        Candidates := Candidates + [ME];
      end;
    end;
    // Methods may not reuse a property or event name, overloads need distinct parameters
    Kept := nil;
    Keys := nil;
    for ME in Candidates do
    begin
      if Used.ContainsKey(ME.Name.ToLower) then
        Continue;
      Key := ME.Name.ToLower + #1 + ParamKey(ME.Params);
      Dup := False;
      for J := 0 to High(Keys) do
        if Keys[J] = Key then
          Dup := True;
      if Dup then
        Continue;
      Keys := Keys + [Key];
      Kept := Kept + [ME];
    end;
    for I := 0 to High(Kept) do
    begin
      Count := 0;
      for J := 0 to High(Kept) do
        if Kept[J].Name.ToLower = Kept[I].Name.ToLower then
          Inc(Count);
      Kept[I].Overload := Count > 1;
    end;
    Result.Methods := Kept;
    Result.Interfaces := InterfacesOf(T);
  finally
    Used.Free;
  end;
end;

function TXamlWrappers.MethodSig(M: TMethod; out AParams: TArray<TParamEntry>; out ARet: TMapping): Boolean;
var
  Prm: TParam;
  Mp: TMapping;
  E: TParamEntry;
begin
  AParams := nil;
  ARet := nil;
  for Prm in M.Params do
  begin
    if Prm.IsOut or Prm.IsByRef then
      Exit(False);
    Mp := Map(Prm.TypeRef);
    if (Mp = nil) or Mp.IsList then
      Exit(False);
    E.Name := Prm.Name;
    E.Mp := Mp;
    AParams := AParams + [E];
  end;
  if M.ReturnType <> nil then
  begin
    ARet := Map(M.ReturnType);
    if (ARet = nil) or ARet.IsList then
      Exit(False);
  end;
  Result := True;
end;

function TXamlWrappers.EventInfo(ARef: TTypeRef; out AInfo: TEventInfo): Boolean;
var
  Td: TTypeDef;
  IName, Cls: string;
  Invoke: TMethod;
  Prm: TParam;
  Pt: TTypeRef;
  Types: TArray<string>;
  Args: TMapping;
begin
  Result := False;
  AInfo := Default(TEventInfo);
  Td := U.Find(ARef.Name);
  if (Td = nil) or (Td.Kind <> 'delegate') then
    Exit;
  IName := '';
  if Length(ARef.Args) > 0 then
    P.Instances.TryGetValue(ARef, IName)
  else
    P.Names.TryGetValue(Td.FullName, IName);
  Cls := '';
  P.DelegateClasses.TryGetValue(StripAmp(IName), Cls);
  Invoke := FindMethod(Td, 'Invoke');
  if (Cls = '') or (Invoke = nil) or (Invoke.ReturnType <> nil) or (Invoke.Params.Count <> 2) then
    Exit;
  Types := nil;
  for Prm in Invoke.Params do
  begin
    Pt := U.Substitute(Prm.TypeRef, ARef.Args);
    if Prm.IsOut or Prm.IsByRef or not (Pt.Kind in [rkNamed, rkPrim]) or
      ((Pt.Kind = rkPrim) and (Pt.Name <> 'Object')) then
      Exit;
    if (Pt.Kind = rkNamed) and (P.TypeName(Pt) = 'Pointer') then
      Exit;
    Types := Types + [AbiType(Pt)];
  end;
  Args := Map(U.Substitute(Invoke.Params[1].TypeRef, ARef.Args));
  if (Args = nil) or not ((Args.Kind = 'wrapper') or (Args.Kind = 'value') or (Args.Kind = 'raw')) then
    Exit;
  AInfo.EventType := EventType(Args);
  AInfo.DelegateClass := AbiUnit + '.' + Cls;
  AInfo.Params := 'ASender: ' + Types[0] + '; AArgs: ' + Types[1];
  AInfo.Args := Args;
  Result := True;
end;

function TXamlWrappers.EnumBoxes: TArray<string>;
var
  Full: string;
  Td: TTypeDef;
  V: TEnumValue;
  Skip: Boolean;
begin
  Result := nil;
  for Full in SortedKeysByValue(Aliases) do
  begin
    Td := U.Get(Full);
    Skip := (Td.Kind <> 'enum') or Td.IsFlags or (Length(Td.EnumValues) = 0);
    for V in Td.EnumValues do
      if V.Value > $7FFFFFFF then
        Skip := True;
    if not Skip then
      Result := Result + [Aliases[Full]];
  end;
end;

function TXamlWrappers.HasDefaultNew(T: TTypeDef): Boolean;
var
  C: TComposable;
  Ftd: TTypeDef;
  M: TMethod;
begin
  if T.ActivatableDefault then
    Exit(True);
  for C in T.Composable do
  begin
    Ftd := U.Find(C.Factory.Name);
    if C.IsPublic and (Ftd <> nil) and P.IncludedNames.ContainsKey(Ftd.FullName) then
      for M in Ftd.Methods do
        if M.Params.Count = 2 then
          Exit(True);
  end;
  Result := False;
end;

function TXamlWrappers.IsUIElement(T: TTypeDef): Boolean;
var
  Seen: TStringSet;
begin
  Result := False;
  Seen := TStringSet.Create;
  try
    while not Seen.ContainsKey(T.FullName) do
    begin
      if T.FullName = 'Microsoft.UI.Xaml.UIElement' then
        Exit(True);
      Seen.Add(T.FullName, True);
      if T.Base = nil then
        Exit(False);
      T := U.Find(T.Base.Name);
      if T = nil then
        Exit(False);
    end;
  finally
    Seen.Free;
  end;
end;

function TXamlWrappers.PropKind(Mp: TMapping): string;
var
  Bare, Full, F: string;
  Td: TTypeDef;
  Parts: TArray<string>;
  V: TEnumValue;
begin
  Result := '';
  if Mp.Kind = 'string' then
    Exit('string');
  if Mp.Kind = 'value' then
    Exit('object');
  if Mp.Kind = 'wrapper' then
  begin
    if Mp.PType = 'TWinUIBrush' then
      Exit('brush');
    if Mp.PType = 'TWinUIFontFamily' then
      Exit('text');
    Exit;
  end;
  if Mp.Kind <> 'raw' then
    Exit;
  Bare := AfterLastDot(Mp.PType);
  if Bare = 'Boolean' then
    Exit('bool');
  if InList(',Integer,Cardinal,Int64,UInt64,Byte,SmallInt,Word,', Bare) then
    Exit('int');
  if (Bare = 'Double') or (Bare = 'Single') then
    Exit('number');
  Full := '';
  for F in Aliases.Keys do
    if Aliases[F] = Mp.PType then
      Full := F;
  Td := nil;
  if Full <> '' then
    Td := U.Find(Full);
  if (Td <> nil) and (Td.Kind = 'enum') and not Td.IsFlags and (Length(Td.EnumValues) > 0) then
  begin
    Parts := nil;
    for V in SortedEnumValues(Td) do
      Parts := Parts + [V.Name];
    Exit('enum:' + string.Join('|', Parts));
  end;
  if (Full <> '') and InList(',Thickness,CornerRadius,GridLength,', AfterLastDot(Full)) then
    Exit('text');
end;

function TXamlWrappers.MembersOf(T: TTypeDef): TClassMembers;
begin
  if not FMembers.TryGetValue(T.FullName, Result) then
  begin
    Result := ClassMembers(T);
    FMembers.Add(T.FullName, Result);
  end;
end;

{ JSON with sorted keys, one value per line and no indentation }

function JsonStr(const S: string): string;
var
  C: Char;
begin
  Result := '"';
  for C in S do
    case C of
      '"': Result := Result + '\"';
      '\': Result := Result + '\\';
      #8: Result := Result + '\b';
      #9: Result := Result + '\t';
      #10: Result := Result + '\n';
      #12: Result := Result + '\f';
      #13: Result := Result + '\r';
    else
      if (Ord(C) < $20) or (Ord(C) > $7F) then
        Result := Result + '\u' + IntToHex(Ord(C), 4).ToLower
      else
        Result := Result + C;
    end;
  Result := Result + '"';
end;

/// <summary>Object of already-encoded values, empty objects print as {}.</summary>
function JsonObject(AItems: TDictionary<string, string>): string;
var
  Keys: TArray<string>;
  Parts: TArray<string>;
  I: Integer;
begin
  if AItems.Count = 0 then
    Exit('{}');
  Keys := AItems.Keys.ToArray;
  SortOrdinal(Keys);
  SetLength(Parts, Length(Keys));
  for I := 0 to High(Keys) do
    Parts[I] := JsonStr(Keys[I]) + ': ' + AItems[Keys[I]];
  Result := '{'#10 + string.Join(','#10, Parts) + #10'}';
end;

function JsonArray(const AItems: TArray<string>): string;
begin
  if Length(AItems) = 0 then
    Exit('[]');
  Result := '['#10 + string.Join(','#10, AItems) + #10']';
end;

function TXamlWrappers.TypeIndex(out ATypeCount: Integer): string;
var
  Types, Classes_, Events, Props, Item, Root: TDictionary<string, string>;
  Ns, Kind: string;
  T: TTypeDef;
  Mem: TClassMembers;
  E: TEventEntry;
  PE: TPropEntry;
  Palette: TArray<string>;
  I, J: Integer;
  PalT: TArray<TTypeDef>;
  Cat: TArray<string>;
  Pt: TTypeDef;
  Pc: string;

  function Less(I1, I2: Integer): Boolean;
  var
    C: Integer;
  begin
    C := CompareStr(Cat[I1], Cat[I2]);
    if C = 0 then
      C := CompareStr(PalT[I1].Name, PalT[I2].Name);
    if C = 0 then
      C := CompareStr(PalT[I1].FullName, PalT[I2].FullName);
    Result := C < 0;
  end;

begin
  Types := TDictionary<string, string>.Create;
  Classes_ := TDictionary<string, string>.Create;
  Events := TDictionary<string, string>.Create;
  Props := TDictionary<string, string>.Create;
  Item := TDictionary<string, string>.Create;
  Root := TDictionary<string, string>.Create;
  try
    for Ns in XamlNamespaces do
      for T in Classes do
        if (T.Namespace = Ns) and not Types.ContainsKey(T.Name) then
          Types.Add(T.Name, JsonStr(T.FullName));
    ATypeCount := Types.Count;
    for T in Classes do
    begin
      Mem := MembersOf(T);
      Events.Clear;
      for E in Mem.Events do
        Events.AddOrSetValue(E.Name, '['#10 + JsonStr(E.Info.EventType) + ','#10 + JsonStr(E.Info.Args.PType) +
          #10']');
      // Settable properties a property grid can edit as XAML text
      Props.Clear;
      for PE in Mem.Props do
        if PE.Setter <> '' then
        begin
          Kind := PropKind(PE.Mp);
          if Kind <> '' then
            Props.AddOrSetValue(PE.Name, JsonStr(Kind));
        end;
      Item.Clear;
      if (T.Base <> nil) and WrapperNames.ContainsKey(T.Base.Name) then
        Item.Add('base', JsonStr(T.Base.Name))
      else
        Item.Add('base', JsonStr(''));
      Item.Add('events', JsonObject(Events));
      Item.Add('props', JsonObject(Props));
      Item.Add('wrapper', JsonStr(WrapperNames[T.FullName]));
      Classes_.AddOrSetValue(T.FullName, JsonObject(Item));
    end;
    PalT := nil;
    Cat := nil;
    for T in Classes do
      if (T.Namespace.StartsWith('Microsoft.UI.Xaml.Controls') or (T.Namespace = 'Microsoft.UI.Xaml.Shapes')) and
        not T.IsAbstract and IsUIElement(T) and HasDefaultNew(T) then
      begin
        PalT := PalT + [T];
        if T.Namespace = 'Microsoft.UI.Xaml.Shapes' then
          Cat := Cat + ['Shapes']
        else
          Cat := Cat + ['Controls'];
      end;
    for I := 1 to High(PalT) do // stable insertion sort by (category, name, runtime)
    begin
      J := I;
      while (J > 0) and Less(J, J - 1) do
      begin
        Pt := PalT[J]; PalT[J] := PalT[J - 1]; PalT[J - 1] := Pt;
        Pc := Cat[J]; Cat[J] := Cat[J - 1]; Cat[J - 1] := Pc;
        Dec(J);
      end;
    end;
    Palette := nil;
    for I := 0 to High(PalT) do
    begin
      Item.Clear;
      Item.Add('category', JsonStr(Cat[I]));
      Item.Add('name', JsonStr(PalT[I].Name));
      Item.Add('runtime', JsonStr(PalT[I].FullName));
      Palette := Palette + [JsonObject(Item)];
    end;
    Root.Add('types', JsonObject(Types));
    Root.Add('classes', JsonObject(Classes_));
    Root.Add('palette', JsonArray(Palette));
    Result := JsonObject(Root) + #10;
  finally
    Root.Free;
    Item.Free;
    Props.Free;
    Events.Free;
    Classes_.Free;
    Types.Free;
  end;
end;

{ Emission }

function TXamlWrappers.MethodDecl(const AName: string; const AParams: TArray<TParamEntry>; ARet: TMapping): string;
var
  Parts: TArray<string>;
  I: Integer;
  Decl: string;
begin
  SetLength(Parts, Length(AParams));
  for I := 0 to High(AParams) do
    Parts[I] := AParams[I].Mp.ParamDecl(ParamName(AParams[I].Name));
  Decl := string.Join('; ', Parts);
  if Decl <> '' then
    Decl := '(' + Decl + ')';
  if ARet <> nil then
    Result := 'function ' + AName + Decl + ': ' + ARet.PType
  else
    Result := 'procedure ' + AName + Decl;
end;

function TXamlWrappers.Emit: string;
var
  Out_, Impl: TStringList;
  Line, Name, Args, Full, Const_: string;
  T: TTypeDef;
  Boxes: TArray<string>;
begin
  Out_ := TStringList.Create;
  Impl := TStringList.Create;
  try
    Out_.Add('unit ' + UnitName + ';');
    Out_.Add('');
    Out_.Add('{');
    for Line in HeaderLines(Header) do
      Out_.Add(('  ' + Line).TrimRight);
    Out_.Add('}');
    Out_.Add('');
    Out_.Add('{$WARN SYMBOL_DEPRECATED OFF}');
    Out_.Add('// No extended RTTI: it would keep every member of every linked wrapper in the exe.');
    Out_.Add('{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}');
    Out_.Add('');
    Out_.Add('interface');
    Out_.Add('');
    Out_.Add('uses');
    Out_.Add('  RADWinUI.Interop.Core,');
    Out_.Add('  ' + AbiUnit + ',');
    Out_.Add('  RADWinUI.Framework;');
    Out_.Add('');
    Out_.Add('type');
    Out_.Add('  // Forward declarations');
    for T in Classes do
      Out_.Add('  ' + WrapperNames[T.FullName] + ' = class;');
    Out_.Add('');
    for T in Classes do
      MembersOf(T);
    Out_.Add('  // Event method pointers');
    for Args in SortedKeysByValue(EventTypes) do
    begin
      if Args.StartsWith(Prefix) then
        Const_ := ''
      else
        Const_ := 'const ';
      Out_.Add('  ' + EventTypes[Args] + ' = procedure(Sender: TObject; ' + Const_ + 'E: ' + Args + ') of object;');
    end;
    Out_.Add('');
    Out_.Add('  // Enumerations and structures, so app code needs no RADWinUI.Abi');
    for Full in SortedKeysByValue(Aliases) do
      Out_.Add('  ' + Aliases[Full] + ' = ' + AbiUnit + '.' + P.Names[Full] + ';');
    Out_.Add('');
    Out_.Add('  // Wrapper classes');
    for T in Classes do
      EmitClass(Out_, Impl, T, MembersOf(T));
    Boxes := EnumBoxes;
    if Length(Boxes) > 0 then
    begin
      Out_.Add('// Box an enumeration value for TWinValue (converter results, Tag): XAML');
      Out_.Add('// converts the boxed Int32 to the enum type of the target property.');
      for Name in Boxes do
        Out_.Add('function WinUIBox(AValue: ' + Name + '): TWinValue; overload; inline;');
      Out_.Add('');
      for Name in Boxes do
      begin
        Impl.Add('function WinUIBox(AValue: ' + Name + '): TWinValue;');
        Impl.Add('begin');
        Impl.Add('  Result := Ord(AValue);');
        Impl.Add('end;');
        Impl.Add('');
      end;
    end;
    Out_.Add('implementation');
    Out_.Add('');
    Out_.Add('uses');
    Out_.Add('  System.SysUtils;');
    Out_.Add('');
    Out_.AddStrings(Impl);
    Out_.Add('end.');
    Out_.Add('');
    Result := string.Join(#13#10, Out_.ToStringArray);
  finally
    Impl.Free;
    Out_.Free;
  end;
end;

procedure TXamlWrappers.EmitClass(AOut, AImpl: TStrings; T: TTypeDef; const Mem: TClassMembers);
var
  Cls, Base, Default_, Token, Bare, IType, Line, Ctor, Rec, Call: string;
  BaseTd, Itd: TTypeDef;
  PE: TPropEntry;
  EE: TEventEntry;
  ME: TMethodEntry;
  CallArgs: TArray<string>;
  I: Integer;
begin
  Cls := WrapperNames[T.FullName];
  BaseTd := nil;
  if T.Base <> nil then
    BaseTd := U.Find(T.Base.Name);
  Base := 'TWinUIObject';
  if BaseTd <> nil then
    WrapperNames.TryGetValue(BaseTd.FullName, Base);
  Default_ := AbiType(T.DefaultInterface);
  Token := AbiUnit + '.' + P.Names['Windows.Foundation.EventRegistrationToken'];

  AOut.Add('  // ' + T.FullName);
  AOut.Add('  ' + Cls + ' = class(' + Base + ')');
  AOut.Add('  strict private');
  for Itd in Mem.Interfaces do
    AOut.Add('    F_' + StripAmp(P.Names[Itd.FullName]) + ': ' + AbiUnit + '.' + P.Names[Itd.FullName] + ';');
  for PE in Mem.Props do
    if PE.Mp.IsList then
      AOut.Add('    F_' + PE.Name + ': ' + PE.Mp.PType + ';');
  for EE in Mem.Events do
  begin
    AOut.Add('    F_On' + EE.Name + ': ' + EE.Info.EventType + ';');
    AOut.Add('    F_' + EE.Name + ': TWinUIEvent<' + EE.Info.Args.PType + '>;');
    AOut.Add('    F_' + EE.Name + 'Token: ' + Token + ';');
  end;
  for PE in Mem.Props do
  begin
    AOut.Add('    function _Get' + PE.Name + ': ' + PE.Mp.PType + ';');
    if PE.Setter <> '' then
      AOut.Add('    procedure _Set' + PE.Name + '(' + PE.Mp.ParamDecl('AValue') + ');');
  end;
  for EE in Mem.Events do
  begin
    AOut.Add('    procedure _SetOn' + EE.Name + '(const AValue: ' + EE.Info.EventType + ');');
    AOut.Add('    function _Get' + EE.Name + ': TWinUIEvent<' + EE.Info.Args.PType + '>;');
    AOut.Add('    procedure _Hook' + EE.Name + ';');
  end;
  AOut.Add('    class constructor _Register;');
  AOut.Add('  strict protected');
  for Itd in Mem.Interfaces do
    AOut.Add('    function _' + StripAmp(P.Names[Itd.FullName]) + ': ' + AbiUnit + '.' + P.Names[Itd.FullName] + ';');
  if Length(Mem.Events) > 0 then
  begin
    AOut.Add('  protected');
    AOut.Add('    procedure DetachEvents; override;');
  end;
  AOut.Add('  public');
  AOut.Add('    constructor Create(AOwner: TWinUIObject);');
  AOut.Add('    function Intf: ' + Default_ + ';');
  for ME in Mem.Methods do
    if ME.Overload then
      AOut.Add('    ' + MethodDecl(Escape(ME.Name), ME.Params, ME.Ret) + '; overload;')
    else
      AOut.Add('    ' + MethodDecl(Escape(ME.Name), ME.Params, ME.Ret) + ';');
  for PE in Mem.Props do
  begin
    Line := '    property ' + Escape(PE.Name) + ': ' + PE.Mp.PType + ' read _Get' + PE.Name;
    if PE.Setter <> '' then
      Line := Line + ' write _Set' + PE.Name;
    AOut.Add(Line + ';');
  end;
  for EE in Mem.Events do
  begin
    AOut.Add('    property On' + EE.Name + ': ' + EE.Info.EventType + ' read F_On' + EE.Name + ' write _SetOn' +
      EE.Name + ';');
    AOut.Add('    property ' + Escape(EE.Name) + ': TWinUIEvent<' + EE.Info.Args.PType + '> read _Get' + EE.Name + ';');
  end;
  AOut.Add('  end;');
  AOut.Add('');

  // Implementation
  AImpl.Add('{ ' + Cls + ' }');
  AImpl.Add('');
  AImpl.Add('class constructor ' + Cls + '._Register;');
  AImpl.Add('begin');
  AImpl.Add('  TWinUIObject.RegisterWrapper(''' + T.FullName + ''', ' + Default_ + ', ' + Cls + ');');
  AImpl.Add('end;');
  AImpl.Add('');
  AImpl.Add('constructor ' + Cls + '.Create(AOwner: TWinUIObject);');
  AImpl.Add('begin');
  if HasDefaultNew(T) then
  begin
    Rec := AbiUnit + '.' + P.Names[T.FullName];
    AImpl.Add('  inherited CreateFrom(AOwner, ' + Rec + '.New);');
  end
  else
    AImpl.Add('  raise ENotSupportedException.Create(''' + T.FullName + ' has no default constructor'');');
  AImpl.Add('end;');
  AImpl.Add('');
  AImpl.Add('function ' + Cls + '.Intf: ' + Default_ + ';');
  AImpl.Add('begin');
  AImpl.Add('  Result := WinRTObject as ' + Default_ + ';');
  AImpl.Add('end;');
  AImpl.Add('');
  for Itd in Mem.Interfaces do
  begin
    Bare := StripAmp(P.Names[Itd.FullName]);
    IType := AbiUnit + '.' + P.Names[Itd.FullName];
    AImpl.Add('function ' + Cls + '._' + Bare + ': ' + IType + ';');
    AImpl.Add('begin');
    AImpl.Add('  if F_' + Bare + ' = nil then');
    AImpl.Add('    F_' + Bare + ' := WinRTObject as ' + IType + ';');
    AImpl.Add('  Result := F_' + Bare + ';');
    AImpl.Add('end;');
    AImpl.Add('');
  end;
  for PE in Mem.Props do
  begin
    AImpl.Add('function ' + Cls + '._Get' + PE.Name + ': ' + PE.Mp.PType + ';');
    AImpl.Add('begin');
    if PE.Mp.IsList then
    begin
      if PE.Mp.Kind = 'valuelist' then
        Ctor := 'TWinUIValueList'
      else
        Ctor := PE.Mp.PType;
      Ctor := Ctor + '.Create(WrapOwner, ' + PE.Accessor + '.' + PE.Getter + ', StringToGUID(''' +
        PE.Mp.VectorIid + '''), StringToGUID(''' + PE.Mp.ElementIid + '''))';
      AImpl.Add('  if F_' + PE.Name + ' = nil then');
      AImpl.Add('  begin');
      AImpl.Add('    F_' + PE.Name + ' := ' + Ctor + ';');
      AImpl.Add('    AddHelper(F_' + PE.Name + ');');
      AImpl.Add('  end;');
      AImpl.Add('  Result := F_' + PE.Name + ';');
    end
    else
      AImpl.Add('  Result := ' + PE.Mp.ToDelphi(PE.Accessor + '.' + PE.Getter) + ';');
    AImpl.Add('end;');
    AImpl.Add('');
    if PE.Setter <> '' then
    begin
      AImpl.Add('procedure ' + Cls + '._Set' + PE.Name + '(' + PE.Mp.ParamDecl('AValue') + ');');
      AImpl.Add('begin');
      AImpl.Add('  ' + PE.Accessor + '.' + PE.Setter + '(' + PE.Mp.ToAbi('AValue') + ');');
      AImpl.Add('end;');
      AImpl.Add('');
    end;
  end;
  for EE in Mem.Events do
  begin
    // One WinRT handler per event serves OnXxx and every Xxx.Add listener
    AImpl.Add('procedure ' + Cls + '._Hook' + EE.Name + ';');
    AImpl.Add('begin');
    AImpl.Add('  if F_' + EE.Name + 'Token.Value <> 0 then');
    AImpl.Add('    Exit;');
    AImpl.Add('  F_' + EE.Name + 'Token := ' + EE.Accessor + '.' + EE.Add + '(' + EE.Info.DelegateClass + '.Create(');
    AImpl.Add('    procedure(' + EE.Info.Params + ')');
    if EE.Info.Args.Kind = 'wrapper' then
    begin
      AImpl.Add('    var');
      AImpl.Add('      E: ' + EE.Info.Args.PType + ';');
      AImpl.Add('    begin');
      AImpl.Add('      // Args wrappers live for one call; handlers must not keep them');
      AImpl.Add('      E := ' + EE.Info.Args.PType + '(TWinUIObject.Wrap(nil, AArgs, ' + EE.Info.Args.PType + '));');
      AImpl.Add('      try');
      AImpl.Add('        if Assigned(F_On' + EE.Name + ') then');
      AImpl.Add('          F_On' + EE.Name + '(Self, E);');
      AImpl.Add('        if F_' + EE.Name + ' <> nil then');
      AImpl.Add('          F_' + EE.Name + '.Invoke(Self, E);');
      AImpl.Add('      finally');
      AImpl.Add('        E.Free;');
      AImpl.Add('      end;');
      AImpl.Add('    end));');
    end
    else
    begin
      AImpl.Add('    begin');
      AImpl.Add('      if Assigned(F_On' + EE.Name + ') then');
      AImpl.Add('        F_On' + EE.Name + '(Self, AArgs);');
      AImpl.Add('      if F_' + EE.Name + ' <> nil then');
      AImpl.Add('        F_' + EE.Name + '.Invoke(Self, AArgs);');
      AImpl.Add('    end));');
    end;
    AImpl.Add('end;');
    AImpl.Add('');
    AImpl.Add('procedure ' + Cls + '._SetOn' + EE.Name + '(const AValue: ' + EE.Info.EventType + ');');
    AImpl.Add('begin');
    AImpl.Add('  F_On' + EE.Name + ' := AValue;');
    AImpl.Add('  if Assigned(AValue) then');
    AImpl.Add('    _Hook' + EE.Name + ';');
    AImpl.Add('end;');
    AImpl.Add('');
    AImpl.Add('function ' + Cls + '._Get' + EE.Name + ': TWinUIEvent<' + EE.Info.Args.PType + '>;');
    AImpl.Add('begin');
    AImpl.Add('  if F_' + EE.Name + ' = nil then');
    AImpl.Add('  begin');
    AImpl.Add('    F_' + EE.Name + ' := TWinUIEvent<' + EE.Info.Args.PType + '>.Create;');
    AImpl.Add('    AddHelper(F_' + EE.Name + ');');
    AImpl.Add('    _Hook' + EE.Name + ';');
    AImpl.Add('  end;');
    AImpl.Add('  Result := F_' + EE.Name + ';');
    AImpl.Add('end;');
    AImpl.Add('');
  end;
  if Length(Mem.Events) > 0 then
  begin
    AImpl.Add('procedure ' + Cls + '.DetachEvents;');
    AImpl.Add('begin');
    for EE in Mem.Events do
    begin
      AImpl.Add('  if F_' + EE.Name + 'Token.Value <> 0 then');
      AImpl.Add('    ' + EE.Accessor + '.' + EE.Remove + '(F_' + EE.Name + 'Token);');
    end;
    AImpl.Add('  inherited;');
    AImpl.Add('end;');
    AImpl.Add('');
  end;
  for ME in Mem.Methods do
  begin
    AImpl.Add(MethodDecl(Cls + '.' + Escape(ME.Name), ME.Params, ME.Ret) + ';');
    AImpl.Add('begin');
    SetLength(CallArgs, Length(ME.Params));
    for I := 0 to High(ME.Params) do
      CallArgs[I] := ME.Params[I].Mp.ToAbi(ParamName(ME.Params[I].Name));
    Call := ME.Accessor + '.' + ME.Abi;
    if Length(CallArgs) > 0 then
      Call := Call + '(' + string.Join(', ', CallArgs) + ')';
    if ME.Ret <> nil then
      AImpl.Add('  Result := ' + ME.Ret.ToDelphi(Call) + ';')
    else
      AImpl.Add('  ' + Call + ';');
    AImpl.Add('end;');
    AImpl.Add('');
  end;
end;

end.
