unit RADWinUI.WinMD.Model;

(*
  Windows Runtime type model on top of RADWinUI.WinMD.Metadata.
  Loads a set of .winmd files into one type universe keyed by full name,
  decodes signatures and custom attributes, and computes the IIDs of
  parameterized (generic) interface instances.

  Type references are interned: one TTypeRef per distinct reference, so equal
  references are the same object. Key is a printable form of the reference,
  ('named', 'Ns.Name', ()), sorting by it gives
  the order generic instances are named in.
*)

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, RADWinUI.WinMD.Metadata;

const
  // Param flags
  PARAM_IN = $1;
  PARAM_OUT = $2;

type
  EModelError = class(Exception);

  TRefKind = (rkPrim, rkNamed, rkVar, rkSzArray, rkByRef);

  TTypeRef = class
  public
    Kind: TRefKind;
    Name: string;                // prim and named
    Index: Integer;              // var
    Elem: TTypeRef;              // szarray and byref
    Args: TArray<TTypeRef>;      // named generic instances
    Key: string;
    function IsGenericInstance: Boolean;
  end;

  TParam = class
  public
    Name: string;
    TypeRef: TTypeRef;
    Flags: Integer;
    IsByRef: Boolean;
    function IsOut: Boolean;
  end;

  TMethod = class
  public
    Name, AbiName, ReturnName: string;
    ReturnType: TTypeRef; // nil for void
    Params: TObjectList<TParam>;
    Flags: Integer;
    Special, Deprecated: Boolean;
    constructor Create;
    destructor Destroy; override;
  end;

  TProperty = class
  public
    Name, Getter, Setter: string;
    TypeRef: TTypeRef;
  end;

  TEvent = class
  public
    Name, Add, Remove: string;
    TypeRef: TTypeRef;
  end;

  TInterfaceImpl = class
  public
    TypeRef: TTypeRef;
    IsDefault, IsOverridable, IsProtected: Boolean;
  end;

  TFieldDef = record
    Name: string;
    TypeRef: TTypeRef;
  end;

  TEnumValue = record
    Name: string;
    Value: Int64;
  end;

  TComposable = record
    Factory: TTypeRef;
    IsPublic: Boolean;
  end;

  TAttrValue = record
    IsString, IsNull: Boolean;
    S: string;
    I: Int64;
  end;
  TAttrArgs = TArray<TAttrValue>;
  TAttributes = TObjectDictionary<string, TList<TAttrArgs>>;

  TTypeDef = class
  public
    Namespace, Name, Kind: string; // kind: enum, struct, interface, delegate, class, attribute, contract
    MetaFile: TMetadataFile;
    Row: Integer;
    GenericParams: TArray<string>;
    Guid: string; // lower-case 8-4-4-4-12, '' when none
    Base: TTypeRef;
    Interfaces: TObjectList<TInterfaceImpl>;
    Methods: TObjectList<TMethod>;
    Properties: TObjectList<TProperty>;
    Events: TObjectList<TEvent>;
    Fields: TArray<TFieldDef>;
    EnumValues: TArray<TEnumValue>;
    EnumSigned, IsFlags: Boolean;
    ActivatableDefault: Boolean;
    Factories, Statics: TArray<TTypeRef>;
    Composable: TArray<TComposable>;
    IsSealed, IsAbstract, IsStaticClass: Boolean;
    ExclusiveTo: string;
    Attributes: TAttributes;
    constructor Create;
    destructor Destroy; override;
    function FullName: string;
    function DefaultInterface: TTypeRef;
  end;

  TUniverse = class
  private
    FFiles: TObjectList<TMetadataFile>;
    FTypes: TDictionary<string, TTypeDef>;
    FOrder: TObjectList<TTypeDef>;
    FRefs: TObjectDictionary<string, TTypeRef>;
    function Intern(ARef: TTypeRef): TTypeRef;
    function TypeDefOrRefName(AFile: TMetadataFile; const ACi: TCodedIndex): string;
    procedure IndexFile(AFile: TMetadataFile);
    procedure LoadType(T: TTypeDef);
    function CodedType(AFile: TMetadataFile; const ACi: TCodedIndex): TTypeRef;
    function DecodeType(AFile: TMetadataFile; const ASig: TBytes; var APos: Integer; out AVoid: Boolean): TTypeRef;
    function Attributes(AFile: TMetadataFile; ATable, ARow: Integer): TAttributes;
    function DecodeAttributeArgs(AFile: TMetadataFile; const ASig, ABlob: TBytes): TAttrArgs;
  public
    constructor Create(const APaths: TArray<string>);
    destructor Destroy; override;
    function Prim(const AName: string): TTypeRef;
    function Named(const AName: string; const AArgs: TArray<TTypeRef> = nil): TTypeRef;
    function VarRef(AIndex: Integer): TTypeRef;
    function SzArray(AElem: TTypeRef): TTypeRef;
    function ByRef(AInner: TTypeRef): TTypeRef;
    function Get(const AFullName: string): TTypeDef;
    function Find(const AFullName: string): TTypeDef;
    function Signature(ARef: TTypeRef): string;
    /// <summary>IID of an interface or delegate type, generic instances included (lower case).</summary>
    function Iid(ARef: TTypeRef): string;
    /// <summary>Replaces generic parameters (var n) with concrete arguments.</summary>
    function Substitute(ARef: TTypeRef; const AArgs: TArray<TTypeRef>): TTypeRef;
    /// <summary>Types in load order, the first file's definition of each name.</summary>
    property Types: TObjectList<TTypeDef> read FOrder;
  end;

implementation

uses
  System.Hash;

const
  // Element types (ECMA-335 II.23.1.16)
  ET_VOID = $01; ET_BOOLEAN = $02; ET_CHAR = $03; ET_I1 = $04; ET_U1 = $05; ET_I2 = $06; ET_U2 = $07;
  ET_I4 = $08; ET_U4 = $09; ET_I8 = $0A; ET_U8 = $0B; ET_R4 = $0C; ET_R8 = $0D; ET_STRING = $0E;
  ET_BYREF = $10; ET_VALUETYPE = $11; ET_CLASS = $12; ET_VAR = $13; ET_GENERICINST = $15;
  ET_OBJECT = $1C; ET_SZARRAY = $1D; ET_CMOD_REQD = $1F; ET_CMOD_OPT = $20;
  TD_INTERFACE = $20;
  SEM_SETTER = $1; SEM_GETTER = $2; SEM_ADDON = $8; SEM_REMOVEON = $10;
  // 11f47ad5-7b73-42c0-abae-878b1e16adee, the WinRT parameterized interface namespace, big-endian
  PInterfaceNamespace: array[0..15] of Byte = ($11, $F4, $7A, $D5, $7B, $73, $42, $C0, $AB, $AE, $87, $8B,
    $1E, $16, $AD, $EE);

function PrimitiveName(AEt: Byte): string;
begin
  case AEt of
    ET_BOOLEAN: Result := 'Boolean';
    ET_CHAR: Result := 'Char16';
    ET_I1: Result := 'Int8';
    ET_U1: Result := 'UInt8';
    ET_I2: Result := 'Int16';
    ET_U2: Result := 'UInt16';
    ET_I4: Result := 'Int32';
    ET_U4: Result := 'UInt32';
    ET_I8: Result := 'Int64';
    ET_U8: Result := 'UInt64';
    ET_R4: Result := 'Single';
    ET_R8: Result := 'Double';
  else
    Result := '';
  end;
end;

function PrimitiveSignature(const AName: string): string;
const
  Names: array[0..14] of string = ('Boolean', 'Char16', 'Int8', 'UInt8', 'Int16', 'UInt16', 'Int32', 'UInt32',
    'Int64', 'UInt64', 'Single', 'Double', 'String', 'Object', 'Guid');
  Sigs: array[0..14] of string = ('b1', 'c2', 'i1', 'u1', 'i2', 'u2', 'i4', 'u4', 'i8', 'u8', 'f4', 'f8',
    'string', 'cinterface(IInspectable)', 'g16');
var
  I: Integer;
begin
  for I := 0 to High(Names) do
    if Names[I] = AName then
      Exit(Sigs[I]);
  raise EModelError.Create('no signature for primitive ' + AName);
end;

{ TTypeRef }

function TTypeRef.IsGenericInstance: Boolean;
begin
  Result := (Kind = rkNamed) and (Length(Args) > 0);
end;

{ TParam }

function TParam.IsOut: Boolean;
begin
  Result := Flags and PARAM_OUT <> 0;
end;

{ TMethod }

constructor TMethod.Create;
begin
  inherited;
  Params := TObjectList<TParam>.Create(True);
end;

destructor TMethod.Destroy;
begin
  Params.Free;
  inherited;
end;

{ TTypeDef }

constructor TTypeDef.Create;
begin
  inherited;
  Interfaces := TObjectList<TInterfaceImpl>.Create(True);
  Methods := TObjectList<TMethod>.Create(True);
  Properties := TObjectList<TProperty>.Create(True);
  Events := TObjectList<TEvent>.Create(True);
  EnumSigned := True;
  IsSealed := True;
end;

destructor TTypeDef.Destroy;
begin
  Attributes.Free;
  Events.Free;
  Properties.Free;
  Methods.Free;
  Interfaces.Free;
  inherited;
end;

function TTypeDef.FullName: string;
begin
  Result := Namespace + '.' + Name;
end;

function TTypeDef.DefaultInterface: TTypeRef;
var
  I: TInterfaceImpl;
begin
  for I in Interfaces do
    if I.IsDefault then
      Exit(I.TypeRef);
  Result := nil;
end;

{ Per-file indexes, built once and cached }

type
  TRowList = TList<Integer>;
  TRowIndex = class(TObjectDictionary<Int64, TRowList>)
  public
    constructor Create;
    procedure AddRow(AKey: Int64; ARow: Integer);
    function Rows(AKey: Int64): TArray<Integer>;
  end;

constructor TRowIndex.Create;
begin
  inherited Create([doOwnsValues]);
end;

procedure TRowIndex.AddRow(AKey: Int64; ARow: Integer);
var
  L: TRowList;
begin
  if not TryGetValue(AKey, L) then
  begin
    L := TRowList.Create;
    Add(AKey, L);
  end;
  L.Add(ARow);
end;

function TRowIndex.Rows(AKey: Int64): TArray<Integer>;
var
  L: TRowList;
begin
  if TryGetValue(AKey, L) then
    Result := L.ToArray
  else
    Result := nil;
end;

function Key2(ATable, ARow: Integer): Int64;
begin
  Result := Int64(ATable) shl 32 or Cardinal(ARow);
end;

function FileIndex(AFile: TMetadataFile; const AName: string): TRowIndex;
var
  Obj: TObject;
  R: Integer;
  Ci: TCodedIndex;
begin
  if AFile.Caches.TryGetValue(AName, Obj) then
    Exit(TRowIndex(Obj));
  Result := TRowIndex.Create;
  AFile.Caches.Add(AName, Result);
  if AName = 'gp' then
    for R := 1 to AFile.RowCount(mtGenericParam) do
    begin
      Ci := AFile.Coded(mtGenericParam, R, 2);
      if Ci.Table = mtTypeDef then
        Result.AddRow(Ci.Row, R);
    end
  else if AName = 'const' then
  begin
    for R := 1 to AFile.RowCount(mtConstant) do
    begin
      Ci := AFile.Coded(mtConstant, R, 2);
      if Ci.Table = mtField then
      begin
        Result.Remove(Ci.Row); // the last constant of a field wins
        Result.AddRow(Ci.Row, R);
      end;
    end;
  end
  else if AName = 'impl' then
    for R := 1 to AFile.RowCount(mtInterfaceImpl) do
      Result.AddRow(AFile.Num(mtInterfaceImpl, R, 0), R)
  else if AName = 'sem' then
    for R := 1 to AFile.RowCount(mtMethodSemantics) do
    begin
      Ci := AFile.Coded(mtMethodSemantics, R, 2);
      Result.AddRow(Key2(Ci.Table, Ci.Row), R);
    end
  else if AName = 'semmethods' then
    for R := 1 to AFile.RowCount(mtMethodSemantics) do
      Result.AddRow(AFile.Num(mtMethodSemantics, R, 1), R)
  else if AName = 'pmap' then
    for R := 1 to AFile.RowCount(mtPropertyMap) do
      Result.AddRow(AFile.Num(mtPropertyMap, R, 0), R)
  else if AName = 'emap' then
    for R := 1 to AFile.RowCount(mtEventMap) do
      Result.AddRow(AFile.Num(mtEventMap, R, 0), R)
  else if AName = 'attr' then
    for R := 1 to AFile.RowCount(mtCustomAttribute) do
    begin
      Ci := AFile.Coded(mtCustomAttribute, R, 0);
      Result.AddRow(Key2(Ci.Table, Ci.Row), R);
    end
  else if AName = 'nested' then
    for R := 1 to AFile.RowCount(mtNestedClass) do
      Result.AddRow(AFile.Num(mtNestedClass, R, 0), R);
end;

{ TUniverse }

constructor TUniverse.Create(const APaths: TArray<string>);
var
  Path: string;
  F: TMetadataFile;
  T: TTypeDef;
  Snapshot: TArray<TTypeDef>;
begin
  inherited Create;
  FFiles := TObjectList<TMetadataFile>.Create(True);
  FTypes := TDictionary<string, TTypeDef>.Create;
  FOrder := TObjectList<TTypeDef>.Create(True);
  FRefs := TObjectDictionary<string, TTypeRef>.Create([doOwnsValues]);
  for Path in APaths do
    FFiles.Add(TMetadataFile.Create(Path));
  for F in FFiles do
    IndexFile(F);
  Snapshot := FOrder.ToArray;
  for T in Snapshot do
    try
      LoadType(T);
    except
      on E: Exception do
        raise EModelError.CreateFmt('%s (%s): %s', [T.FullName, T.MetaFile.Path, E.Message]);
    end;
end;

destructor TUniverse.Destroy;
begin
  FRefs.Free;
  FOrder.Free;
  FTypes.Free;
  FFiles.Free;
  inherited;
end;

function TUniverse.Intern(ARef: TTypeRef): TTypeRef;
var
  Parts: TArray<string>;
  I: Integer;
begin
  case ARef.Kind of
    rkPrim: ARef.Key := '(''prim'', ''' + ARef.Name + ''', ())';
    rkVar: ARef.Key := '(''var'', ' + IntToStr(ARef.Index) + ', ())';
    rkSzArray: ARef.Key := '(''szarray'', ' + ARef.Elem.Key + ', ())';
    rkByRef: ARef.Key := '(''byref'', ' + ARef.Elem.Key + ', ())';
    rkNamed:
      begin
        SetLength(Parts, Length(ARef.Args));
        for I := 0 to High(Parts) do
          Parts[I] := ARef.Args[I].Key;
        if Length(Parts) = 0 then
          ARef.Key := '(''named'', ''' + ARef.Name + ''', ())'
        else if Length(Parts) = 1 then
          ARef.Key := '(''named'', ''' + ARef.Name + ''', (' + Parts[0] + ',))'
        else
          ARef.Key := '(''named'', ''' + ARef.Name + ''', (' + string.Join(', ', Parts) + '))';
      end;
  end;
  if FRefs.TryGetValue(ARef.Key, Result) then
    ARef.Free
  else
  begin
    FRefs.Add(ARef.Key, ARef);
    Result := ARef;
  end;
end;

function TUniverse.Prim(const AName: string): TTypeRef;
begin
  Result := TTypeRef.Create;
  Result.Kind := rkPrim;
  Result.Name := AName;
  Result := Intern(Result);
end;

function TUniverse.Named(const AName: string; const AArgs: TArray<TTypeRef>): TTypeRef;
begin
  Result := TTypeRef.Create;
  Result.Kind := rkNamed;
  Result.Name := AName;
  Result.Args := AArgs;
  Result := Intern(Result);
end;

function TUniverse.VarRef(AIndex: Integer): TTypeRef;
begin
  Result := TTypeRef.Create;
  Result.Kind := rkVar;
  Result.Index := AIndex;
  Result := Intern(Result);
end;

function TUniverse.SzArray(AElem: TTypeRef): TTypeRef;
begin
  Result := TTypeRef.Create;
  Result.Kind := rkSzArray;
  Result.Elem := AElem;
  Result := Intern(Result);
end;

function TUniverse.ByRef(AInner: TTypeRef): TTypeRef;
begin
  Result := TTypeRef.Create;
  Result.Kind := rkByRef;
  Result.Elem := AInner;
  Result := Intern(Result);
end;

function TUniverse.TypeDefOrRefName(AFile: TMetadataFile; const ACi: TCodedIndex): string;
var
  Name: string;
  I: Integer;
begin
  if ACi.IsNull then
    Exit('');
  if ACi.Table = mtTypeDef then
    Name := AFile.Str(mtTypeDef, ACi.Row, 2) + '.' + AFile.Str(mtTypeDef, ACi.Row, 1)
  else if ACi.Table = mtTypeRef then
    Name := AFile.Str(mtTypeRef, ACi.Row, 2) + '.' + AFile.Str(mtTypeRef, ACi.Row, 1)
  else
    raise EModelError.Create('TypeSpec has no simple name');
  I := Name.IndexOf('`');
  if I >= 0 then
    Name := Name.Substring(0, I);
  Result := Name;
end;

procedure TUniverse.IndexFile(AFile: TMetadataFile);
var
  Nested: TRowIndex;
  R: Integer;
  Name, Base: string;
  T: TTypeDef;
begin
  Nested := FileIndex(AFile, 'nested');
  for R := 1 to AFile.RowCount(mtTypeDef) do
  begin
    Name := AFile.Str(mtTypeDef, R, 1);
    if (Name = '<Module>') or Nested.ContainsKey(R) then
      Continue;
    if Name.IndexOf('`') >= 0 then
      Name := Name.Substring(0, Name.IndexOf('`'));
    T := TTypeDef.Create;
    T.Namespace := AFile.Str(mtTypeDef, R, 2);
    T.Name := Name;
    T.MetaFile := AFile;
    T.Row := R;
    if AFile.Num(mtTypeDef, R, 0) and TD_INTERFACE <> 0 then
      T.Kind := 'interface'
    else
    begin
      Base := TypeDefOrRefName(AFile, AFile.Coded(mtTypeDef, R, 3));
      if Base = 'System.Enum' then T.Kind := 'enum'
      else if Base = 'System.ValueType' then T.Kind := 'struct'
      else if Base = 'System.MulticastDelegate' then T.Kind := 'delegate'
      else if Base = 'System.Attribute' then T.Kind := 'attribute'
      else T.Kind := 'class';
    end;
    if FTypes.ContainsKey(T.FullName) then
    begin
      T.Free; // first file wins, duplicates across contracts are identical
      Continue;
    end;
    FTypes.Add(T.FullName, T);
    FOrder.Add(T);
  end;
end;

function HasAttr(T: TAttributes; const AName: string): Boolean;
begin
  Result := T.ContainsKey(AName);
end;

function AttrList(T: TAttributes; const AName: string): TArray<TAttrArgs>;
var
  L: TList<TAttrArgs>;
begin
  if T.TryGetValue(AName, L) then
    Result := L.ToArray
  else
    Result := nil;
end;

procedure TUniverse.LoadType(T: TTypeDef);
var
  F: TMetadataFile;
  R, FStart, FEnd, Fi, MStart, MEnd, Mi, PStart, PEnd, Pi, Ii, Pidx, Eidx, Ei, Pos, K, N: Integer;
  Gp: TArray<Integer>;
  Guid: TArray<TAttrArgs>;
  A: TAttrArgs;
  FType: TTypeRef;
  Void: Boolean;
  Sig, ValueBlob: TBytes;
  Consts, Impls, SemByAssoc, SemByMethod, PMaps, EMaps: TRowIndex;
  ConstRows: TArray<Integer>;
  Field: TFieldDef;
  EnumValue: TEnumValue;
  Impl: TInterfaceImpl;
  IAttrs, MAttrs: TAttributes;
  M: TMethod;
  P: TParam;
  Ret, PT: TTypeRef;
  PTypes: TArray<TTypeRef>;
  Count: Cardinal;
  MethodNames: TDictionary<Integer, string>;
  Prop: TProperty;
  Ev: TEvent;
  S, Sem: Integer;
  Comp: TComposable;
  Overload: TArray<TAttrArgs>;
begin
  F := T.MetaFile;
  R := T.Row;
  T.Attributes := Attributes(F, mtTypeDef, R);
  if HasAttr(T.Attributes, 'Windows.Foundation.Metadata.ApiContractAttribute') then
    T.Kind := 'contract';
  // generic parameters, by number
  Gp := FileIndex(F, 'gp').Rows(R);
  for K := 1 to High(Gp) do // insertion sort on Number
  begin
    N := Gp[K];
    Pos := K - 1;
    while (Pos >= 0) and (F.Num(mtGenericParam, Gp[Pos], 0) > F.Num(mtGenericParam, N, 0)) do
    begin
      Gp[Pos + 1] := Gp[Pos];
      Dec(Pos);
    end;
    Gp[Pos + 1] := N;
  end;
  SetLength(T.GenericParams, Length(Gp));
  for K := 0 to High(Gp) do
    T.GenericParams[K] := F.Str(mtGenericParam, Gp[K], 3);
  Guid := AttrList(T.Attributes, 'Windows.Foundation.Metadata.GuidAttribute');
  if Length(Guid) > 0 then
  begin
    A := Guid[0];
    T.Guid := Format('%.8x-%.4x-%.4x-%.2x%.2x-%.2x%.2x%.2x%.2x%.2x%.2x',
      [Cardinal(A[0].I), Word(A[1].I), Word(A[2].I), Byte(A[3].I), Byte(A[4].I), Byte(A[5].I), Byte(A[6].I),
       Byte(A[7].I), Byte(A[8].I), Byte(A[9].I), Byte(A[10].I)]).ToLower;
  end;
  Guid := AttrList(T.Attributes, 'Windows.Foundation.Metadata.ExclusiveToAttribute');
  if Length(Guid) > 0 then
    T.ExclusiveTo := Guid[0][0].S;
  if (T.Kind = 'contract') or (T.Kind = 'attribute') then
    Exit;

  // Fields
  FStart := F.Num(mtTypeDef, R, 4);
  FEnd := F.RangeEnd(mtField, mtTypeDef, R, 4);
  Consts := FileIndex(F, 'const');
  for Fi := FStart to FEnd - 1 do
  begin
    Sig := F.Blob(mtField, Fi, 2);
    Pos := 1;
    FType := DecodeType(F, Sig, Pos, Void);
    if T.Kind = 'enum' then
    begin
      if F.Str(mtField, Fi, 1) = 'value__' then
      begin
        T.EnumSigned := FType = Prim('Int32');
        Continue;
      end;
      ConstRows := Consts.Rows(Fi);
      ValueBlob := F.Blob(mtConstant, ConstRows[0], 3);
      EnumValue.Name := F.Str(mtField, Fi, 1);
      if F.Num(mtConstant, ConstRows[0], 0) = ET_I4 then
        EnumValue.Value := PInteger(@ValueBlob[0])^
      else
        EnumValue.Value := PCardinal(@ValueBlob[0])^;
      T.EnumValues := T.EnumValues + [EnumValue];
    end
    else if T.Kind = 'struct' then
    begin
      Field.Name := F.Str(mtField, Fi, 1);
      Field.TypeRef := FType;
      T.Fields := T.Fields + [Field];
    end;
  end;
  T.IsFlags := HasAttr(T.Attributes, 'System.FlagsAttribute');

  // Base class and interfaces
  if T.Kind = 'class' then
  begin
    if not F.Coded(mtTypeDef, R, 3).IsNull and
      (TypeDefOrRefName(F, F.Coded(mtTypeDef, R, 3)) <> 'System.Object') then
      T.Base := Named(TypeDefOrRefName(F, F.Coded(mtTypeDef, R, 3)));
    T.IsSealed := F.Num(mtTypeDef, R, 0) and $100 <> 0;
    T.IsAbstract := F.Num(mtTypeDef, R, 0) and $80 <> 0;
  end;
  Impls := FileIndex(F, 'impl');
  for Ii in Impls.Rows(R) do
  begin
    Impl := TInterfaceImpl.Create;
    Impl.TypeRef := CodedType(F, F.Coded(mtInterfaceImpl, Ii, 1));
    IAttrs := Attributes(F, mtInterfaceImpl, Ii);
    try
      Impl.IsDefault := HasAttr(IAttrs, 'Windows.Foundation.Metadata.DefaultAttribute');
      Impl.IsOverridable := HasAttr(IAttrs, 'Windows.Foundation.Metadata.OverridableAttribute');
      Impl.IsProtected := HasAttr(IAttrs, 'Windows.Foundation.Metadata.ProtectedAttribute');
    finally
      IAttrs.Free;
    end;
    T.Interfaces.Add(Impl);
  end;

  // Methods
  MStart := F.Num(mtTypeDef, R, 5);
  MEnd := F.RangeEnd(mtMethodDef, mtTypeDef, R, 5);
  SemByMethod := FileIndex(F, 'semmethods');
  SemByAssoc := FileIndex(F, 'sem');
  MethodNames := TDictionary<Integer, string>.Create;
  try
    for Mi := MStart to MEnd - 1 do
      MethodNames.AddOrSetValue(Mi, F.Str(mtMethodDef, Mi, 3));
    for Mi := MStart to MEnd - 1 do
    begin
      if (T.Kind = 'delegate') and (F.Str(mtMethodDef, Mi, 3) <> 'Invoke') then
        Continue;
      if T.Kind = 'class' then
        Continue; // members of classes come from their interfaces
      Sig := F.Blob(mtMethodDef, Mi, 4);
      Pos := 1;
      if Sig[0] and $10 <> 0 then
        DecompressUInt(Sig, Pos);
      Count := DecompressUInt(Sig, Pos);
      Ret := DecodeType(F, Sig, Pos, Void);
      SetLength(PTypes, Count);
      for K := 0 to Integer(Count) - 1 do
        PTypes[K] := DecodeType(F, Sig, Pos, Void);
      M := TMethod.Create;
      M.Name := F.Str(mtMethodDef, Mi, 3);
      M.ReturnType := Ret;
      M.ReturnName := 'result';
      M.Flags := F.Num(mtMethodDef, Mi, 2);
      PStart := F.Num(mtMethodDef, Mi, 5);
      PEnd := F.RangeEnd(mtParam, mtMethodDef, Mi, 5);
      K := 0;
      for Pi := PStart to PEnd - 1 do
      begin
        if F.Num(mtParam, Pi, 1) = 0 then
        begin
          M.ReturnName := F.Str(mtParam, Pi, 2);
          Continue;
        end;
        PT := PTypes[K];
        Inc(K);
        P := TParam.Create;
        P.Name := F.Str(mtParam, Pi, 2);
        P.Flags := F.Num(mtParam, Pi, 0);
        P.IsByRef := PT.Kind = rkByRef;
        if P.IsByRef then
          PT := PT.Elem;
        P.TypeRef := PT;
        M.Params.Add(P);
      end;
      MAttrs := Attributes(F, mtMethodDef, Mi);
      try
        Overload := AttrList(MAttrs, 'Windows.Foundation.Metadata.OverloadAttribute');
        if Length(Overload) > 0 then
          M.AbiName := Overload[0][0].S
        else
          M.AbiName := M.Name;
        M.Deprecated := HasAttr(MAttrs, 'Windows.Foundation.Metadata.DeprecatedAttribute');
      finally
        MAttrs.Free;
      end;
      M.Special := SemByMethod.ContainsKey(Mi);
      T.Methods.Add(M);
    end;

    // Properties and events
    PMaps := FileIndex(F, 'pmap');
    for Pidx in PMaps.Rows(R) do
      for Pi := F.Num(mtPropertyMap, Pidx, 1) to F.RangeEnd(mtProperty, mtPropertyMap, Pidx, 1) - 1 do
      begin
        Sig := F.Blob(mtProperty, Pi, 2);
        Pos := 1;
        DecompressUInt(Sig, Pos);
        Prop := TProperty.Create;
        Prop.Name := F.Str(mtProperty, Pi, 1);
        Prop.TypeRef := DecodeType(F, Sig, Pos, Void);
        for S in SemByAssoc.Rows(Key2(mtProperty, Pi)) do
        begin
          Sem := F.Num(mtMethodSemantics, S, 0);
          if Sem and SEM_GETTER <> 0 then
            MethodNames.TryGetValue(F.Num(mtMethodSemantics, S, 1), Prop.Getter)
          else if Sem and SEM_SETTER <> 0 then
            MethodNames.TryGetValue(F.Num(mtMethodSemantics, S, 1), Prop.Setter);
        end;
        T.Properties.Add(Prop);
      end;
    EMaps := FileIndex(F, 'emap');
    for Eidx in EMaps.Rows(R) do
      for Ei := F.Num(mtEventMap, Eidx, 1) to F.RangeEnd(mtEvent, mtEventMap, Eidx, 1) - 1 do
      begin
        Ev := TEvent.Create;
        Ev.Name := F.Str(mtEvent, Ei, 1);
        Ev.TypeRef := CodedType(F, F.Coded(mtEvent, Ei, 2));
        for S in SemByAssoc.Rows(Key2(mtEvent, Ei)) do
        begin
          Sem := F.Num(mtMethodSemantics, S, 0);
          if Sem and SEM_ADDON <> 0 then
            MethodNames.TryGetValue(F.Num(mtMethodSemantics, S, 1), Ev.Add)
          else if Sem and SEM_REMOVEON <> 0 then
            MethodNames.TryGetValue(F.Num(mtMethodSemantics, S, 1), Ev.Remove);
        end;
        T.Events.Add(Ev);
      end;
  finally
    MethodNames.Free;
  end;

  // Activation
  if T.Kind = 'class' then
  begin
    for A in AttrList(T.Attributes, 'Windows.Foundation.Metadata.ActivatableAttribute') do
      if A[0].IsString then
        T.Factories := T.Factories + [Named(A[0].S)]
      else
        T.ActivatableDefault := True;
    for A in AttrList(T.Attributes, 'Windows.Foundation.Metadata.StaticAttribute') do
      T.Statics := T.Statics + [Named(A[0].S)];
    for A in AttrList(T.Attributes, 'Windows.Foundation.Metadata.ComposableAttribute') do
    begin
      Comp.Factory := Named(A[0].S);
      Comp.IsPublic := (not A[1].IsString) and (A[1].I = 2);
      T.Composable := T.Composable + [Comp];
    end;
    T.IsStaticClass := T.Interfaces.Count = 0;
  end;
end;

function TUniverse.CodedType(AFile: TMetadataFile; const ACi: TCodedIndex): TTypeRef;
var
  Sig: TBytes;
  Pos: Integer;
  Void: Boolean;
begin
  if ACi.Table = mtTypeSpec then
  begin
    Sig := AFile.Blob(mtTypeSpec, ACi.Row, 0);
    Pos := 0;
    Exit(DecodeType(AFile, Sig, Pos, Void));
  end;
  Result := Named(TypeDefOrRefName(AFile, ACi));
end;

function TUniverse.DecodeType(AFile: TMetadataFile; const ASig: TBytes; var APos: Integer; out AVoid: Boolean): TTypeRef;
var
  Et: Byte;
  CodedValue, Count, I: Cardinal;
  Ci: TCodedIndex;
  Name: string;
  Gen, Inner: TTypeRef;
  Args: TArray<TTypeRef>;
  V: Boolean;
begin
  AVoid := False;
  Et := ASig[APos];
  Inc(APos);
  while (Et = ET_CMOD_REQD) or (Et = ET_CMOD_OPT) do
  begin
    DecompressUInt(ASig, APos);
    Et := ASig[APos];
    Inc(APos);
  end;
  Name := PrimitiveName(Et);
  if Name <> '' then
    Exit(Prim(Name));
  case Et of
    ET_STRING: Exit(Prim('String'));
    ET_OBJECT: Exit(Prim('Object'));
    ET_VALUETYPE, ET_CLASS:
      begin
        CodedValue := DecompressUInt(ASig, APos);
        case CodedValue and 3 of
          0: Ci.Table := mtTypeDef;
          1: Ci.Table := mtTypeRef;
          2: Ci.Table := mtTypeSpec;
        else
          raise EModelError.Create('bad TypeDefOrRef in a signature');
        end;
        Ci.Row := CodedValue shr 2;
        Name := TypeDefOrRefName(AFile, Ci);
        if Name = 'System.Guid' then
          Exit(Prim('Guid'));
        Exit(Named(Name));
      end;
    ET_GENERICINST:
      begin
        Gen := DecodeType(AFile, ASig, APos, V);
        Count := DecompressUInt(ASig, APos);
        SetLength(Args, Count);
        for I := 1 to Count do
          Args[I - 1] := DecodeType(AFile, ASig, APos, V);
        Exit(Named(Gen.Name, Args));
      end;
    ET_VAR:
      Exit(VarRef(DecompressUInt(ASig, APos)));
    ET_SZARRAY:
      begin
        Inner := DecodeType(AFile, ASig, APos, V);
        Exit(SzArray(Inner));
      end;
    ET_BYREF:
      begin
        Inner := DecodeType(AFile, ASig, APos, V);
        Exit(ByRef(Inner));
      end;
    ET_VOID:
      begin
        AVoid := True;
        Exit(nil);
      end;
  end;
  raise EModelError.CreateFmt('unsupported element type $%x', [Et]);
end;

function TUniverse.Attributes(AFile: TMetadataFile; ATable, ARow: Integer): TAttributes;
var
  Ca, Owner, I: Integer;
  Ctor: TCodedIndex;
  Name: string;
  Sig: TBytes;
  Args: TAttrArgs;
  L: TList<TAttrArgs>;
begin
  Result := TAttributes.Create([doOwnsValues]);
  for Ca in FileIndex(AFile, 'attr').Rows(Key2(ATable, ARow)) do
  begin
    Ctor := AFile.Coded(mtCustomAttribute, Ca, 1);
    if Ctor.Table = mtMemberRef then
    begin
      Name := TypeDefOrRefName(AFile, AFile.Coded(mtMemberRef, Ctor.Row, 0));
      Sig := AFile.Blob(mtMemberRef, Ctor.Row, 2);
    end
    else
    begin
      Owner := 0;
      for I := AFile.RowCount(mtTypeDef) downto 1 do
        if AFile.Num(mtTypeDef, I, 5) <= Cardinal(Ctor.Row) then
        begin
          Owner := I;
          Break;
        end;
      Name := AFile.Str(mtTypeDef, Owner, 2) + '.' + AFile.Str(mtTypeDef, Owner, 1);
      Sig := AFile.Blob(mtMethodDef, Ctor.Row, 4);
    end;
    try
      Args := DecodeAttributeArgs(AFile, Sig, AFile.Blob(mtCustomAttribute, Ca, 2));
    except
      on EModelError do Args := nil;
      on ERangeError do Args := nil;
    end;
    if not Result.TryGetValue(Name, L) then
    begin
      L := TList<TAttrArgs>.Create;
      Result.Add(Name, L);
    end;
    L.Add(Args);
  end;
end;

function TUniverse.DecodeAttributeArgs(AFile: TMetadataFile; const ASig, ABlob: TBytes): TAttrArgs;
var
  Pos, BPos, Size: Integer;
  Count, N, I: Cardinal;
  PTypes: TArray<TTypeRef>;
  P: TTypeRef;
  Void: Boolean;
  V: TAttrValue;
begin
  {$RANGECHECKS ON}
  Pos := 1;
  Count := DecompressUInt(ASig, Pos);
  DecodeType(AFile, ASig, Pos, Void); // void
  SetLength(PTypes, Count);
  for I := 1 to Count do
    PTypes[I - 1] := DecodeType(AFile, ASig, Pos, Void);
  BPos := 2; // prolog 0x0001
  Result := nil;
  for P in PTypes do
  begin
    V := Default(TAttrValue);
    if (P = Prim('String')) or (P = Named('System.Type')) then
    begin
      if ABlob[BPos] = $FF then
      begin
        V.IsNull := True;
        Inc(BPos);
      end
      else
      begin
        N := DecompressUInt(ABlob, BPos);
        if BPos + Integer(N) > Length(ABlob) then
          raise EModelError.Create('attribute string past the blob');
        V.IsString := True;
        V.S := TEncoding.UTF8.GetString(ABlob, BPos, N);
        Inc(BPos, N);
      end;
    end
    else if P.Kind = rkPrim then
    begin
      if P.Name = 'Boolean' then Size := 1
      else if (P.Name = 'UInt8') or (P.Name = 'Int8') then Size := 1
      else if (P.Name = 'UInt16') or (P.Name = 'Int16') then Size := 2
      else if (P.Name = 'UInt32') or (P.Name = 'Int32') then Size := 4
      else if (P.Name = 'UInt64') or (P.Name = 'Int64') then Size := 8
      else raise EModelError.Create('unsupported attribute argument');
      if BPos + Size > Length(ABlob) then
        raise EModelError.Create('attribute value past the blob');
      if P.Name = 'Boolean' then V.I := Ord(ABlob[BPos] <> 0)
      else if P.Name = 'UInt8' then V.I := ABlob[BPos]
      else if P.Name = 'Int8' then V.I := ShortInt(ABlob[BPos])
      else if P.Name = 'UInt16' then V.I := PWord(@ABlob[BPos])^
      else if P.Name = 'Int16' then V.I := PSmallInt(@ABlob[BPos])^
      else if P.Name = 'UInt32' then V.I := PCardinal(@ABlob[BPos])^
      else if P.Name = 'Int32' then V.I := PInteger(@ABlob[BPos])^
      else V.I := PInt64(@ABlob[BPos])^;
      Inc(BPos, Size);
    end
    else if P.Kind = rkNamed then
    begin
      // enum argument, WinRT metadata enums are 32-bit
      if BPos + 4 > Length(ABlob) then
        raise EModelError.Create('attribute value past the blob');
      V.I := PInteger(@ABlob[BPos])^;
      Inc(BPos, 4);
    end
    else
      raise EModelError.Create('unsupported attribute argument');
    Result := Result + [V];
  end;
end;

function TUniverse.Get(const AFullName: string): TTypeDef;
begin
  if not FTypes.TryGetValue(AFullName, Result) then
    raise EModelError.CreateFmt('type %s not found in the loaded metadata', [AFullName]);
end;

function TUniverse.Find(const AFullName: string): TTypeDef;
begin
  if not FTypes.TryGetValue(AFullName, Result) then
    Result := nil;
end;

function TUniverse.Signature(ARef: TTypeRef): string;
var
  Td: TTypeDef;
  Parts: TArray<string>;
  I: Integer;
begin
  if ARef.Kind = rkPrim then
    Exit(PrimitiveSignature(ARef.Name));
  if ARef.Kind <> rkNamed then
    raise EModelError.Create('no signature for ' + ARef.Key);
  Td := Get(ARef.Name);
  if Length(ARef.Args) > 0 then
  begin
    SetLength(Parts, Length(ARef.Args));
    for I := 0 to High(Parts) do
      Parts[I] := Signature(ARef.Args[I]);
    Exit('pinterface({' + Td.Guid + '};' + string.Join(';', Parts) + ')');
  end;
  if Td.Kind = 'interface' then
    Exit('{' + Td.Guid + '}');
  if Td.Kind = 'delegate' then
    Exit('delegate({' + Td.Guid + '})');
  if Td.Kind = 'class' then
    Exit('rc(' + Td.FullName + ';' + Signature(Td.DefaultInterface) + ')');
  if Td.Kind = 'enum' then
  begin
    if Td.EnumSigned then
      Exit('enum(' + Td.FullName + ';i4)');
    Exit('enum(' + Td.FullName + ';u4)');
  end;
  if Td.Kind = 'struct' then
  begin
    SetLength(Parts, Length(Td.Fields));
    for I := 0 to High(Parts) do
      Parts[I] := Signature(Td.Fields[I].TypeRef);
    Exit('struct(' + Td.FullName + ';' + string.Join(';', Parts) + ')');
  end;
  raise EModelError.CreateFmt('no signature for %s %s', [Td.Kind, ARef.Name]);
end;

function TUniverse.Iid(ARef: TTypeRef): string;
var
  Td: TTypeDef;
  Data, Hash: TBytes;
  SHA: THashSHA1;
  Hex: string;
  I: Integer;
begin
  Td := Get(ARef.Name);
  if Length(ARef.Args) = 0 then
    Exit(Td.Guid);
  SetLength(Data, 16);
  Move(PInterfaceNamespace[0], Data[0], 16);
  Data := Data + TEncoding.UTF8.GetBytes(Signature(ARef));
  SHA := THashSHA1.Create;
  SHA.Update(Data);
  Hash := SHA.HashAsBytes;
  Hash[6] := (Hash[6] and $0F) or $50;
  Hash[8] := (Hash[8] and $3F) or $80;
  Hex := '';
  for I := 0 to 15 do
    Hex := Hex + IntToHex(Hash[I], 2).ToLower;
  Result := Hex.Substring(0, 8) + '-' + Hex.Substring(8, 4) + '-' + Hex.Substring(12, 4) + '-' +
    Hex.Substring(16, 4) + '-' + Hex.Substring(20, 12);
end;

function TUniverse.Substitute(ARef: TTypeRef; const AArgs: TArray<TTypeRef>): TTypeRef;
var
  Args: TArray<TTypeRef>;
  I: Integer;
begin
  if ARef = nil then
    Exit(nil);
  case ARef.Kind of
    rkVar: Exit(AArgs[ARef.Index]);
    rkSzArray: Exit(SzArray(Substitute(ARef.Elem, AArgs)));
    rkByRef: Exit(ByRef(Substitute(ARef.Elem, AArgs)));
    rkNamed:
      if Length(ARef.Args) > 0 then
      begin
        SetLength(Args, Length(ARef.Args));
        for I := 0 to High(Args) do
          Args[I] := Substitute(ARef.Args[I], AArgs);
        Exit(Named(ARef.Name, Args));
      end;
  end;
  Result := ARef;
end;

end.
