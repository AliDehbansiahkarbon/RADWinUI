unit RADWinUI.WinMD.Pascal;

(*
  Object Pascal ABI projection emitter.

  Writes one unit holding every enum, struct, interface, delegate and generic
  interface instance of the selected namespaces. One unit, because WinRT
  namespaces reference each other in cycles and Delphi units cannot.

  - Interfaces derive from IInspectable, delegates from IUnknown, methods are
    safecall, so failed HRESULTs raise exceptions.
  - Runtime classes appear as their default interface.
  - Types outside the selected namespaces are opaque: interfaces and classes
    become IInspectable, delegates IUnknown. Their enums and structs are
    projected because they are passed by value.
  - Generic instances get a concrete interface each, named after their
    arguments (IVector_UIElement) with the IID computed from the signature.
*)

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, RADWinUI.WinMD.Model;

type
  TStringSet = TDictionary<string, Boolean>;
  TMethodNames = TDictionary<TMethod, string>;

  TSignature = class
  public
    Name, ResultType: string;
    Params, ArgNames, ArgTypes: TStringList;
    Overload: Boolean;
    constructor Create(const AName: string);
    destructor Destroy; override;
    procedure Add(const ADecl, AName, ATypeName: string);
    function ParamText: string;
    function Declaration(const AOwner: string = ''): string;
  end;

  TProjection = class
  private
    FMethodNames: TObjectDictionary<TTypeDef, TMethodNames>;
    FUsedNames: TStringSet;
    FFactorySlots: Integer;
    procedure Select;
    function Known(ARef: TTypeRef): Boolean;
    function ReferencedTypes(T: TTypeDef; const AArgs: TArray<TTypeRef>): TArray<TTypeRef>;
    procedure AssignNames;
    function Mangle(ARef: TTypeRef): string;
    function Qualify(const AName: string; AContext: TStringSet): string;
    function AllValueTypes: TArray<TTypeDef>;
    function OrderedStructs(const AStructs: TArray<TTypeDef>): TArray<TTypeDef>;
    function Unique(const ABase: string): string;
    procedure EmitEnum(AOut: TStrings; T: TTypeDef; AFlagConsts: TStrings);
    procedure EmitStruct(AOut: TStrings; T: TTypeDef);
    procedure EmitInterface(AOut: TStrings; const AName: string; Td: TTypeDef; const AArgs: TArray<TTypeRef>;
      AInstance: TTypeRef);
    function ArgsText(const AArgs: TArray<TTypeRef>): string;
    function Display(ARef: TTypeRef): string;
    procedure EmitDelegateClass(AOut, AImpl: TStrings; const AName: string; Td: TTypeDef;
      const AArgs: TArray<TTypeRef>);
    procedure EmitClassRecord(AOut, AImpl: TStrings; T: TTypeDef);
  public
    U: TUniverse;
    UnitName, Header: string;
    Namespaces: TArray<string>;
    Names: TDictionary<string, string>;      // full name -> Pascal name
    Included: TList<TTypeDef>;               // sorted by full name
    IncludedNames: TStringSet;
    ValueTypes: TStringSet;                  // external enums and structs pulled in
    Instances: TDictionary<TTypeRef, string>;
    Unknown: TStringSet;                     // referenced but not in the loaded metadata
    DelegateClasses: TDictionary<string, string>; // delegate interface name -> Delphi class
    constructor Create(AUniverse: TUniverse; const AUnitName: string; const ANamespaces: TArray<string>;
      const AHeader: string);
    destructor Destroy; override;
    function InScope(const ANamespace: string): Boolean;
    function TypeName(ARef: TTypeRef; AContext: TStringSet = nil): string;
    /// <summary>Pascal names of a type's methods (OverloadAttribute names, made unique).</summary>
    function MethodNames(Td: TTypeDef): TMethodNames;
    function Signature(M: TMethod; const AName: string; const AArgs: TArray<TTypeRef>; AMembers: TStringSet;
      ADropLast: Integer = 0): TSignature;
    function Emit: string;
    function SortedValueTypes: TArray<string>;
  end;

function Escape(const AName: string): string;
function ParamName(const AName: string): string;
function GuidText(const AGuid: string): string;
function StripAmp(const AName: string): string;
/// <summary>The lines of LF text, without an empty piece after a final line break.</summary>
function HeaderLines(const AText: string): TArray<string>;
/// <summary>Sorts strings in ordinal order.</summary>
procedure SortOrdinal(var AItems: TArray<string>);

const
  PrimitivePascalNames: array[0..14] of string = ('Boolean', 'WideChar', 'ShortInt', 'Byte', 'SmallInt', 'Word',
    'Integer', 'Cardinal', 'Int64', 'UInt64', 'Single', 'Double', 'HSTRING', 'IInspectable', 'TGUID');

function PrimitivePascal(const AName: string): string;

implementation

const
  PascalReserved =
    ',and,array,as,asm,begin,case,class,const,constructor,destructor,dispinterface,div,do,downto,else,end,except,' +
    'exports,file,finalization,finally,for,function,goto,if,implementation,in,inherited,initialization,inline,' +
    'interface,is,label,library,mod,nil,not,object,of,or,out,packed,procedure,program,property,raise,record,' +
    'repeat,resourcestring,set,shl,shr,string,then,threadvar,to,try,type,unit,until,uses,var,while,with,xor,' +
    'absolute,abstract,at,default,dispid,dynamic,export,external,far,forward,implements,index,message,name,' +
    'near,nodefault,on,operator,overload,override,read,readonly,reintroduce,register,stored,virtual,write,' +
    'writeonly,helper,sealed,static,strict,private,protected,public,published,automated,reference,unsafe,final,';
  BaseInterfaceMethods = ',queryinterface,addref,release,getiids,getruntimeclassname,gettrustlevel,';
  DelphiTypeNames =
    ',pointer,boolean,widechar,shortint,byte,smallint,word,integer,cardinal,int64,uint64,single,double,hresult,' +
    'tguid,iinspectable,iunknown,iinterface,hstring,tobject,exception,tinterfacedobject,twinrtdelegate,' +
    'iagileobject,iactivationfactory,trustlevel,char,string,variant,currency,extended,nativeint,nativeuint,tdatetime,';
  PrimitiveNames: array[0..14] of string = ('Boolean', 'Char16', 'Int8', 'UInt8', 'Int16', 'UInt16', 'Int32',
    'UInt32', 'Int64', 'UInt64', 'Single', 'Double', 'String', 'Object', 'Guid');
  // Structs with a better native Delphi equivalent of identical layout
  AliasFrom = 'Windows.Foundation.HResult';
  AliasTo = 'HRESULT';

function InList(const AList, AName: string): Boolean;
begin
  Result := Pos(',' + AName + ',', AList) > 0;
end;

function PrimitivePascal(const AName: string): string;
var
  I: Integer;
begin
  for I := 0 to High(PrimitiveNames) do
    if PrimitiveNames[I] = AName then
      Exit(PrimitivePascalNames[I]);
  raise EModelError.Create('unknown primitive ' + AName);
end;

function Escape(const AName: string): string;
begin
  if InList(PascalReserved, AName.ToLower) then
    Result := '&' + AName
  else
    Result := AName;
end;

function ParamName(const AName: string): string;
begin
  Result := 'A' + AName.Substring(0, 1).ToUpper + AName.Substring(1);
end;

function GuidText(const AGuid: string): string;
begin
  Result := '{' + AGuid.ToUpper + '}';
end;

function StripAmp(const AName: string): string;
begin
  Result := AName;
  while Result.StartsWith('&') do
    Result := Result.Substring(1);
end;

procedure SortOrdinal(var AItems: TArray<string>);
var
  I, J: Integer;
  Item: string;
begin
  for I := 1 to High(AItems) do
  begin
    Item := AItems[I];
    J := I - 1;
    while (J >= 0) and (CompareStr(AItems[J], Item) > 0) do
    begin
      AItems[J + 1] := AItems[J];
      Dec(J);
    end;
    AItems[J + 1] := Item;
  end;
end;

function SimpleName(const AFull: string): string;
begin
  Result := AFull.Substring(AFull.LastIndexOf('.') + 1);
end;

function HeaderLines(const AText: string): TArray<string>;
var
  Text: string;
begin
  Text := AText.Replace(#13#10, #10);
  if Text.EndsWith(#10) then
    Text := Text.Substring(0, Text.Length - 1);
  if Text = '' then
    Exit(nil);
  Result := Text.Split([#10]);
end;

function JoinLines(AItems: TStrings; const ASep: string): string;
begin
  Result := string.Join(ASep, AItems.ToStringArray);
end;

{ TSignature }

constructor TSignature.Create(const AName: string);
begin
  inherited Create;
  Name := AName;
  Params := TStringList.Create;
  ArgNames := TStringList.Create;
  ArgTypes := TStringList.Create;
end;

destructor TSignature.Destroy;
begin
  ArgTypes.Free;
  ArgNames.Free;
  Params.Free;
  inherited;
end;

procedure TSignature.Add(const ADecl, AName, ATypeName: string);
begin
  Params.Add(ADecl);
  ArgNames.Add(AName);
  ArgTypes.Add(ATypeName.ToLower);
end;

function TSignature.ParamText: string;
begin
  if Params.Count > 0 then
    Result := '(' + JoinLines(Params, '; ') + ')'
  else
    Result := '';
end;

function TSignature.Declaration(const AOwner: string): string;
var
  N: string;
begin
  if AOwner <> '' then
    N := AOwner + '.' + Name
  else
    N := Name;
  if ResultType <> '' then
    Result := 'function ' + N + ParamText + ': ' + ResultType
  else
    Result := 'procedure ' + N + ParamText;
end;

{ TProjection }

constructor TProjection.Create(AUniverse: TUniverse; const AUnitName: string; const ANamespaces: TArray<string>;
  const AHeader: string);
begin
  inherited Create;
  U := AUniverse;
  UnitName := AUnitName;
  Namespaces := ANamespaces;
  Header := AHeader;
  Names := TDictionary<string, string>.Create;
  Included := TList<TTypeDef>.Create;
  IncludedNames := TStringSet.Create;
  ValueTypes := TStringSet.Create;
  Instances := TDictionary<TTypeRef, string>.Create;
  Unknown := TStringSet.Create;
  DelegateClasses := TDictionary<string, string>.Create;
  FMethodNames := TObjectDictionary<TTypeDef, TMethodNames>.Create([doOwnsValues]);
  FUsedNames := TStringSet.Create;
  Select;
end;

destructor TProjection.Destroy;
begin
  FUsedNames.Free;
  FMethodNames.Free;
  DelegateClasses.Free;
  Unknown.Free;
  Instances.Free;
  ValueTypes.Free;
  IncludedNames.Free;
  Included.Free;
  Names.Free;
  inherited;
end;

function TProjection.InScope(const ANamespace: string): Boolean;
var
  N: string;
begin
  for N in Namespaces do
    if (ANamespace = N) or ANamespace.StartsWith(N + '.') then
      Exit(True);
  Result := False;
end;

function TProjection.SortedValueTypes: TArray<string>;
begin
  Result := ValueTypes.Keys.ToArray;
  SortOrdinal(Result);
end;

procedure TProjection.Select;
var
  T, Td: TTypeDef;
  Arr: TArray<TTypeDef>;
  I, J: Integer;
  Work: TList<TTypeRef>;
  Seen: TDictionary<TTypeRef, Boolean>;
  Ref, A: TTypeRef;
  Impl: TInterfaceImpl;
  F: TFieldDef;
begin
  for T in U.Types do
  begin
    if (T.Kind = 'attribute') or (T.Kind = 'contract') then
      Continue;
    if InScope(T.Namespace) then
      Included.Add(T);
  end;
  // sorted by full name
  Arr := Included.ToArray;
  for I := 1 to High(Arr) do
  begin
    T := Arr[I];
    J := I - 1;
    while (J >= 0) and (CompareStr(Arr[J].FullName, T.FullName) > 0) do
    begin
      Arr[J + 1] := Arr[J];
      Dec(J);
    end;
    Arr[J + 1] := T;
  end;
  Included.Clear;
  Included.AddRange(Arr);
  for T in Included do
    IncludedNames.AddOrSetValue(T.FullName, True);

  // Generic instances and external value types, to closure
  Work := TList<TTypeRef>.Create;
  Seen := TDictionary<TTypeRef, Boolean>.Create;
  try
    for T in Included do
      if Length(T.GenericParams) = 0 then
        Work.AddRange(ReferencedTypes(T, nil));
    while Work.Count > 0 do
    begin
      Ref := Work.Last;
      Work.Delete(Work.Count - 1);
      if Seen.ContainsKey(Ref) then
        Continue;
      Seen.Add(Ref, True);
      if Ref.Kind in [rkSzArray, rkByRef] then
      begin
        Work.Add(Ref.Elem);
        Continue;
      end;
      if Ref.Kind <> rkNamed then
        Continue;
      Td := U.Find(Ref.Name);
      if Td = nil then
      begin
        Unknown.AddOrSetValue(Ref.Name, True);
        Continue;
      end;
      if Length(Ref.Args) > 0 then
      begin
        for A in Ref.Args do
          Work.Add(A);
        if IncludedNames.ContainsKey(Td.FullName) and Known(Ref) then
        begin
          Instances.AddOrSetValue(Ref, '');
          Work.AddRange(ReferencedTypes(Td, Ref.Args));
          for Impl in Td.Interfaces do
            Work.Add(U.Substitute(Impl.TypeRef, Ref.Args));
        end;
        Continue;
      end;
      if ((Td.Kind = 'enum') or (Td.Kind = 'struct')) and not IncludedNames.ContainsKey(Td.FullName) then
      begin
        ValueTypes.AddOrSetValue(Td.FullName, True);
        for F in Td.Fields do
          Work.Add(F.TypeRef);
      end
      else if Td.Kind = 'struct' then
        for F in Td.Fields do
          Work.Add(F.TypeRef);
    end;
  finally
    Seen.Free;
    Work.Free;
  end;
  AssignNames;
end;

function TProjection.Known(ARef: TTypeRef): Boolean;
var
  A: TTypeRef;
begin
  if ARef.Kind in [rkSzArray, rkByRef] then
    Exit(Known(ARef.Elem));
  if ARef.Kind <> rkNamed then
    Exit(True);
  if U.Find(ARef.Name) = nil then
    Exit(False);
  for A in ARef.Args do
    if not Known(A) then
      Exit(False);
  Result := True;
end;

function TProjection.ReferencedTypes(T: TTypeDef; const AArgs: TArray<TTypeRef>): TArray<TTypeRef>;
var
  L: TList<TTypeRef>;
  M: TMethod;
  P: TParam;
  I: TInterfaceImpl;
  F: TFieldDef;
begin
  L := TList<TTypeRef>.Create;
  try
    for M in T.Methods do
    begin
      if M.ReturnType <> nil then
        L.Add(U.Substitute(M.ReturnType, AArgs));
      for P in M.Params do
        L.Add(U.Substitute(P.TypeRef, AArgs));
    end;
    for I in T.Interfaces do
      L.Add(U.Substitute(I.TypeRef, AArgs));
    for F in T.Fields do
      L.Add(F.TypeRef);
    if T.Base <> nil then
      L.Add(T.Base);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

procedure TProjection.AssignNames;
var
  Candidates: TObjectDictionary<string, TStringList>;
  Order: TStringList;
  AllNamed: TArray<string>;
  Full, Simple, Keep, Base, Name: string;
  Fulls: TStringList;
  Preferred: TArray<string>;
  Used: TStringSet;
  Refs: TArray<TTypeRef>;
  Ref: TTypeRef;
  T: TTypeDef;
  I, J, N: Integer;
begin
  Candidates := TObjectDictionary<string, TStringList>.Create([doOwnsValues]);
  Order := TStringList.Create;
  try
    AllNamed := nil;
    for T in Included do
      AllNamed := AllNamed + [T.FullName];
    AllNamed := AllNamed + SortedValueTypes;
    for Full in AllNamed do
    begin
      Simple := SimpleName(Full).ToLower;
      if not Candidates.TryGetValue(Simple, Fulls) then
      begin
        Fulls := TStringList.Create;
        Candidates.Add(Simple, Fulls);
        Order.Add(Simple);
      end;
      Fulls.Add(Full);
    end;
    for Simple in Order do
    begin
      Fulls := Candidates[Simple];
      if (Fulls.Count = 1) and not InList(DelphiTypeNames, Simple) then
      begin
        Names.AddOrSetValue(Fulls[0], Escape(SimpleName(Fulls[0])));
        Continue;
      end;
      // Collision: the type from a selected namespace keeps the plain name when it is
      // the only one, every other gets a namespace prefix.
      Preferred := nil;
      for Full in Fulls do
        if IncludedNames.ContainsKey(Full) then
          Preferred := Preferred + [Full];
      Keep := '';
      if (Length(Preferred) = 1) and not InList(DelphiTypeNames, Simple) then
        Keep := Preferred[0];
      for Full in Fulls do
        if Full = Keep then
          Names.AddOrSetValue(Full, Escape(SimpleName(Full)))
        else
          Names.AddOrSetValue(Full, Full.Replace('.', '_'));
    end;
  finally
    Order.Free;
    Candidates.Free;
  end;
  if Names.ContainsKey(AliasFrom) then
    Names[AliasFrom] := AliasTo;
  Used := TStringSet.Create;
  try
    for Name in Names.Values do
      Used.AddOrSetValue(Name.ToLower, True);
    // instances in the order of their printed form
    Refs := Instances.Keys.ToArray;
    for I := 1 to High(Refs) do
    begin
      Ref := Refs[I];
      J := I - 1;
      while (J >= 0) and (CompareStr(Refs[J].Key, Ref.Key) > 0) do
      begin
        Refs[J + 1] := Refs[J];
        Dec(J);
      end;
      Refs[J + 1] := Ref;
    end;
    for Ref in Refs do
    begin
      Base := Mangle(Ref);
      Name := Base;
      N := 2;
      while Used.ContainsKey(Name.ToLower) do
      begin
        Name := Base + IntToStr(N);
        Inc(N);
      end;
      Used.AddOrSetValue(Name.ToLower, True);
      Instances[Ref] := Name;
    end;
  finally
    Used.Free;
  end;
end;

function TProjection.Mangle(ARef: TTypeRef): string;
var
  Parts: TArray<string>;
  I: Integer;
begin
  if ARef.Kind = rkPrim then
    Exit(ARef.Name);
  if ARef.Kind = rkSzArray then
    Exit('Array_' + Mangle(ARef.Elem));
  if Length(ARef.Args) = 0 then
    Exit(SimpleName(ARef.Name));
  SetLength(Parts, Length(ARef.Args));
  for I := 0 to High(Parts) do
    Parts[I] := Mangle(ARef.Args[I]);
  Result := SimpleName(ARef.Name) + '_' + string.Join('_', Parts);
end;

function TProjection.TypeName(ARef: TTypeRef; AContext: TStringSet): string;
var
  Td: TTypeDef;
  Name: string;
begin
  case ARef.Kind of
    rkPrim: Exit(PrimitivePascal(ARef.Name));
    rkSzArray: Exit('Pointer');
    rkNamed: ;
  else
    raise EModelError.Create('unexpected type ' + ARef.Key);
  end;
  if Unknown.ContainsKey(ARef.Name) then
    Exit('Pointer'); // metadata not loaded, keeps the vtable slot and ABI size
  if Length(ARef.Args) > 0 then
  begin
    if not Instances.TryGetValue(ARef, Name) then
      Exit('IInspectable');
    Exit(Qualify(Name, AContext));
  end;
  Td := U.Get(ARef.Name);
  if (Td.Kind = 'enum') or (Td.Kind = 'struct') then
    Exit(Qualify(Names[Td.FullName], AContext));
  if not IncludedNames.ContainsKey(Td.FullName) then
  begin
    if Td.Kind = 'delegate' then
      Exit('IUnknown');
    Exit('IInspectable');
  end;
  if Td.Kind = 'class' then
  begin
    if Td.DefaultInterface = nil then
      Exit('IInspectable');
    Exit(TypeName(Td.DefaultInterface, AContext));
  end;
  Result := Qualify(Names[Td.FullName], AContext);
end;

function TProjection.Qualify(const AName: string; AContext: TStringSet): string;
begin
  if (AContext <> nil) and (AContext.Count > 0) and AContext.ContainsKey(StripAmp(AName.ToLower)) then
    Result := UnitName + '.' + StripAmp(AName)
  else
    Result := AName;
end;

function TProjection.AllValueTypes: TArray<TTypeDef>;
var
  T: TTypeDef;
  Name: string;
begin
  Result := nil;
  for T in Included do
    if (T.Kind = 'enum') or (T.Kind = 'struct') then
      Result := Result + [T];
  for Name in SortedValueTypes do
    Result := Result + [U.Get(Name)];
end;

function TProjection.OrderedStructs(const AStructs: TArray<TTypeDef>): TArray<TTypeDef>;
var
  ByName: TDictionary<string, TTypeDef>;
  Done: TStringSet;
  Ordered: TList<TTypeDef>;
  Sorted: TArray<TTypeDef>;
  T: TTypeDef;
  I, J: Integer;

  procedure Visit(T: TTypeDef);
  var
    F: TFieldDef;
    S: TTypeDef;
  begin
    if Done.ContainsKey(T.FullName) then
      Exit;
    Done.Add(T.FullName, True);
    for F in T.Fields do
      if (F.TypeRef.Kind = rkNamed) and ByName.TryGetValue(F.TypeRef.Name, S) then
        Visit(S);
    Ordered.Add(T);
  end;

begin
  ByName := TDictionary<string, TTypeDef>.Create;
  Done := TStringSet.Create;
  Ordered := TList<TTypeDef>.Create;
  try
    for T in AStructs do
      ByName.AddOrSetValue(T.FullName, T);
    Sorted := Copy(AStructs);
    for I := 1 to High(Sorted) do
    begin
      T := Sorted[I];
      J := I - 1;
      while (J >= 0) and (CompareStr(Sorted[J].FullName, T.FullName) > 0) do
      begin
        Sorted[J + 1] := Sorted[J];
        Dec(J);
      end;
      Sorted[J + 1] := T;
    end;
    for T in Sorted do
      Visit(T);
    Result := Ordered.ToArray;
  finally
    Ordered.Free;
    Done.Free;
    ByName.Free;
  end;
end;

function TProjection.Unique(const ABase: string): string;
var
  N: Integer;
begin
  Result := ABase;
  N := 2;
  while FUsedNames.ContainsKey(Result.ToLower) do
  begin
    Result := ABase + IntToStr(N);
    Inc(N);
  end;
  FUsedNames.AddOrSetValue(Result.ToLower, True);
end;

function TProjection.Emit: string;
var
  Out_, Impl, FlagConsts: TStringList;
  Line, Name: string;
  Enums, Structs, Ifaces, Classes, ValueTypesList: TArray<TTypeDef>;
  InstanceRefs: TArray<TTypeRef>;
  T, Td: TTypeDef;
  Ref: TTypeRef;
  I, J: Integer;
begin
  Out_ := TStringList.Create;
  Impl := TStringList.Create;
  FlagConsts := TStringList.Create;
  try
    Out_.Add('unit ' + UnitName + ';');
    Out_.Add('');
    Out_.Add('{');
    for Line in HeaderLines(Header) do
      Out_.Add(('  ' + Line).TrimRight);
    Out_.Add('}');
    Out_.Add('');
    Out_.Add('{$MINENUMSIZE 4}');
    Out_.Add('{$SCOPEDENUMS ON}');
    Out_.Add('{$WARN SYMBOL_DEPRECATED OFF}');
    Out_.Add('');
    Out_.Add('interface');
    Out_.Add('');
    Out_.Add('uses');
    Out_.Add('  RADWinUI.Interop.Core;');
    Out_.Add('');

    ValueTypesList := AllValueTypes;
    Enums := nil;
    Structs := nil;
    for T in ValueTypesList do
      if T.Kind = 'enum' then
        Enums := Enums + [T]
      else if T.Kind = 'struct' then
        Structs := Structs + [T];
    Structs := OrderedStructs(Structs);
    Ifaces := nil;
    Classes := nil;
    for T in Included do
    begin
      if ((T.Kind = 'interface') or (T.Kind = 'delegate')) and (Length(T.GenericParams) = 0) then
        Ifaces := Ifaces + [T];
      if T.Kind = 'class' then
        Classes := Classes + [T];
    end;
    // instances sorted by their Pascal name
    InstanceRefs := Instances.Keys.ToArray;
    for I := 1 to High(InstanceRefs) do
    begin
      Ref := InstanceRefs[I];
      J := I - 1;
      while (J >= 0) and (CompareStr(Instances[InstanceRefs[J]], Instances[Ref]) > 0) do
      begin
        InstanceRefs[J + 1] := InstanceRefs[J];
        Dec(J);
      end;
      InstanceRefs[J + 1] := Ref;
    end;

    for Name in Names.Values do
      FUsedNames.AddOrSetValue(StripAmp(Name.ToLower), True);
    for Name in Instances.Values do
      FUsedNames.AddOrSetValue(Name.ToLower, True);
    FFactorySlots := 0;

    Out_.Add('type');
    Out_.Add('  // Forward declarations');
    for T in Ifaces do
      Out_.Add('  ' + Names[T.FullName] + ' = interface;');
    for Ref in InstanceRefs do
      Out_.Add('  ' + Instances[Ref] + ' = interface;');
    Out_.Add('');
    Out_.Add('  // Enumerations');
    for T in Enums do
      EmitEnum(Out_, T, FlagConsts);
    Out_.Add('  // Structures');
    for T in Structs do
      if T.FullName <> AliasFrom then
        EmitStruct(Out_, T);
    Out_.Add('  // Interfaces and delegates');
    for T in Ifaces do
      EmitInterface(Out_, Names[T.FullName], T, nil, nil);
    Out_.Add('  // Generic interface instances');
    for Ref in InstanceRefs do
    begin
      Td := U.Get(Ref.Name);
      EmitInterface(Out_, Instances[Ref], Td, Ref.Args, Ref);
    end;
    Out_.Add('  // Delphi implementations of delegates');
    for T in Ifaces do
      if T.Kind = 'delegate' then
        EmitDelegateClass(Out_, Impl, Names[T.FullName], T, nil);
    for Ref in InstanceRefs do
    begin
      Td := U.Get(Ref.Name);
      if Td.Kind = 'delegate' then
        EmitDelegateClass(Out_, Impl, Instances[Ref], Td, Ref.Args);
    end;
    Out_.Add('  // Runtime classes: activation and static members');
    for T in Classes do
      EmitClassRecord(Out_, Impl, T);

    if FlagConsts.Count > 0 then
    begin
      Out_.Add('const');
      Out_.Add('  // Flag values');
      Out_.AddStrings(FlagConsts);
      Out_.Add('');
    end;
    Out_.Add('implementation');
    Out_.Add('');
    if FFactorySlots > 0 then
    begin
      Out_.Add('var');
      Out_.Add(Format('  FactoryCache: array[0..%d] of IInspectable;', [FFactorySlots - 1]));
      Out_.Add('');
    end;
    Out_.AddStrings(Impl);
    Out_.Add('end.');
    Out_.Add('');
    Result := JoinLines(Out_, #13#10);
  finally
    FlagConsts.Free;
    Impl.Free;
    Out_.Free;
  end;
end;

procedure TProjection.EmitEnum(AOut: TStrings; T: TTypeDef; AFlagConsts: TStrings);
var
  Name, Bare, BaseType, Literal: string;
  Overflow: Boolean;
  V: TEnumValue;
  Values: TArray<TEnumValue>;
  Lines: TStringList;
  I, J: Integer;
begin
  Name := Names[T.FullName];
  Bare := StripAmp(Name);
  AOut.Add('  // ' + T.FullName);
  Overflow := False;
  for V in T.EnumValues do
    if V.Value > $7FFFFFFF then
      Overflow := True;
  if T.IsFlags or Overflow or (Length(T.EnumValues) = 0) then
  begin
    if T.EnumSigned then
      BaseType := 'Integer'
    else
      BaseType := 'Cardinal';
    AOut.Add('  ' + Name + ' = type ' + BaseType + ';');
    for V in T.EnumValues do
    begin
      if not T.EnumSigned then
        Literal := '$' + IntToHex(V.Value, 8).ToUpper
      else
        Literal := IntToStr(V.Value);
      AFlagConsts.Add('  ' + Bare + '_' + V.Name + ' = ' + Bare + '(' + Literal + ');');
    end;
    AOut.Add('');
    Exit;
  end;
  AOut.Add('  ' + Name + ' = (');
  Values := Copy(T.EnumValues);
  for I := 1 to High(Values) do // stable sort by value
  begin
    V := Values[I];
    J := I - 1;
    while (J >= 0) and (Values[J].Value > V.Value) do
    begin
      Values[J + 1] := Values[J];
      Dec(J);
    end;
    Values[J + 1] := V;
  end;
  Lines := TStringList.Create;
  try
    for V in Values do
      Lines.Add('    ' + Escape(V.Name) + ' = ' + IntToStr(V.Value));
    AOut.Add(JoinLines(Lines, ','#13#10));
  finally
    Lines.Free;
  end;
  AOut.Add('  );');
  AOut.Add('  P' + Bare + ' = ^' + Bare + ';');
  AOut.Add('');
end;

procedure TProjection.EmitStruct(AOut: TStrings; T: TTypeDef);
var
  Name, Bare: string;
  Members: TStringSet;
  F: TFieldDef;
begin
  Name := Names[T.FullName];
  Bare := StripAmp(Name);
  AOut.Add('  // ' + T.FullName);
  AOut.Add('  ' + Name + ' = record');
  Members := TStringSet.Create;
  try
    for F in T.Fields do
      Members.AddOrSetValue(F.Name.ToLower, True);
    for F in T.Fields do
      AOut.Add('    ' + Escape(F.Name) + ': ' + TypeName(F.TypeRef, Members) + ';');
  finally
    Members.Free;
  end;
  AOut.Add('  end;');
  AOut.Add('  P' + Bare + ' = ^' + Bare + ';');
  AOut.Add('');
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

procedure TProjection.EmitInterface(AOut: TStrings; const AName: string; Td: TTypeDef;
  const AArgs: TArray<TTypeRef>; AInstance: TTypeRef);
var
  BaseType, Iid, Line, PType: string;
  MNames: TMethodNames;
  Members, MethodNameSet: TStringSet;
  M, G, S: TMethod;
  P: TProperty;
  Sig: TSignature;
begin
  if Td.Kind = 'delegate' then
    BaseType := 'IUnknown'
  else
    BaseType := 'IInspectable';
  if AInstance <> nil then
    Iid := U.Iid(AInstance)
  else
    Iid := Td.Guid;
  AOut.Add('  // ' + Td.FullName + ArgsText(AArgs));
  AOut.Add('  ' + AName + ' = interface(' + BaseType + ')');
  AOut.Add('  [''' + GuidText(Iid) + ''']');
  MNames := MethodNames(Td);
  Members := TStringSet.Create;
  MethodNameSet := TStringSet.Create;
  try
    for Line in MNames.Values do
    begin
      Members.AddOrSetValue(StripAmp(Line.ToLower), True);
      MethodNameSet.AddOrSetValue(StripAmp(Line.ToLower), True);
    end;
    for P in Td.Properties do
      Members.AddOrSetValue(P.Name.ToLower, True);
    for M in Td.Methods do
    begin
      Sig := Signature(M, MNames[M], AArgs, Members);
      try
        AOut.Add('    ' + Sig.Declaration + '; safecall;');
      finally
        Sig.Free;
      end;
    end;
    for P in Td.Properties do
    begin
      if MethodNameSet.ContainsKey(P.Name.ToLower) then
        Continue;
      G := FindMethod(Td, P.Getter);
      if (G = nil) or (G.Params.Count > 0) or (G.ReturnType = nil) or (G.ReturnType.Kind = rkSzArray) then
        Continue;
      PType := TypeName(U.Substitute(G.ReturnType, AArgs), Members);
      Line := '    property ' + Escape(P.Name) + ': ' + PType + ' read ' + MNames[G];
      S := FindMethod(Td, P.Setter);
      if (S <> nil) and (S.Params.Count = 1) and (S.Params[0].TypeRef.Kind <> rkSzArray) then
        Line := Line + ' write ' + MNames[S];
      AOut.Add(Line + ';');
    end;
  finally
    MethodNameSet.Free;
    Members.Free;
  end;
  AOut.Add('  end;');
  AOut.Add('');
end;

function TProjection.ArgsText(const AArgs: TArray<TTypeRef>): string;
var
  Parts: TArray<string>;
  I: Integer;
begin
  if Length(AArgs) = 0 then
    Exit('');
  SetLength(Parts, Length(AArgs));
  for I := 0 to High(Parts) do
    Parts[I] := Display(AArgs[I]);
  Result := '<' + string.Join(', ', Parts) + '>';
end;

function TProjection.Display(ARef: TTypeRef): string;
begin
  if ARef.Kind = rkPrim then
    Exit(ARef.Name);
  if ARef.Kind = rkSzArray then
    Exit(Display(ARef.Elem) + '[]');
  Result := ARef.Name;
  if Length(ARef.Args) > 0 then
    Result := Result + ArgsText(ARef.Args);
end;

function TProjection.MethodNames(Td: TTypeDef): TMethodNames;
var
  Used: TStringSet;
  M: TMethod;
  N, Base: string;
  K: Integer;
begin
  if FMethodNames.TryGetValue(Td, Result) then
    Exit;
  Result := TMethodNames.Create;
  FMethodNames.Add(Td, Result);
  Used := TStringSet.Create;
  try
    for M in Td.Methods do
    begin
      N := M.AbiName;
      if InList(BaseInterfaceMethods, N.ToLower) then
        N := N + '_';
      Base := N;
      K := 2;
      while Used.ContainsKey(N.ToLower) do
      begin
        N := Base + IntToStr(K);
        Inc(K);
      end;
      Used.AddOrSetValue(N.ToLower, True);
      Result.Add(M, Escape(N));
    end;
  finally
    Used.Free;
  end;
end;

function TProjection.Signature(M: TMethod; const AName: string; const AArgs: TArray<TTypeRef>;
  AMembers: TStringSet; ADropLast: Integer): TSignature;
var
  Used: TStringSet;
  I: Integer;
  P: TParam;
  PT, Ret: TTypeRef;
  N, Size, TN: string;

  function PName(const ARaw: string): string;
  var
    Base: string;
    K: Integer;
  begin
    Result := ParamName(ARaw);
    Base := Result;
    K := 2;
    while Used.ContainsKey(Result.ToLower) do
    begin
      Result := Base + IntToStr(K);
      Inc(K);
    end;
    Used.AddOrSetValue(Result.ToLower, True);
  end;

begin
  Result := TSignature.Create(AName);
  Used := TStringSet.Create;
  try
    for I := 0 to M.Params.Count - 1 - ADropLast do
    begin
      P := M.Params[I];
      PT := U.Substitute(P.TypeRef, AArgs);
      N := PName(P.Name);
      if PT.Kind = rkSzArray then
      begin
        Size := PName(P.Name + 'Size');
        if P.IsOut and P.IsByRef then // ReceiveArray
        begin
          Result.Add('out ' + Size + ': Cardinal', Size, 'Cardinal');
          Result.Add('out ' + N + ': Pointer', N, 'Pointer');
        end
        else // PassArray or FillArray
        begin
          Result.Add(Size + ': Cardinal', Size, 'Cardinal');
          Result.Add(N + ': Pointer', N, 'Pointer');
        end;
        Continue;
      end;
      TN := TypeName(PT, AMembers);
      if P.IsOut then
        Result.Add('out ' + N + ': ' + TN, N, TN)
      else if P.IsByRef then
        Result.Add('var ' + N + ': ' + TN, N, TN)
      else
        Result.Add(N + ': ' + TN, N, TN);
    end;
    Ret := U.Substitute(M.ReturnType, AArgs);
    if (Ret <> nil) and (Ret.Kind = rkSzArray) then
    begin
      Size := PName(M.ReturnName + 'Size');
      N := PName(M.ReturnName);
      Result.Add('out ' + Size + ': Cardinal', Size, 'Cardinal');
      Result.Add('out ' + N + ': Pointer', N, 'Pointer');
      Ret := nil;
    end;
    if Ret <> nil then
      Result.ResultType := TypeName(Ret, AMembers);
  finally
    Used.Free;
  end;
end;

procedure TProjection.EmitDelegateClass(AOut, AImpl: TStrings; const AName: string; Td: TTypeDef;
  const AArgs: TArray<TTypeRef>);
var
  Invoke: TMethod;
  Bare, Proc, Cls, Params, Call: string;
  Ctx: TStringSet;
  Sig: TSignature;
begin
  Invoke := FindMethod(Td, 'Invoke');
  if Invoke = nil then
    Exit;
  Bare := StripAmp(AName);
  Proc := Unique(Bare + 'Proc');
  Cls := Unique('T' + Bare);
  DelegateClasses.AddOrSetValue(Bare, Cls);
  Ctx := TStringSet.Create;
  Ctx.Add('invoke', True);
  Sig := Signature(Invoke, 'Invoke', AArgs, Ctx);
  try
    Params := Sig.ParamText;
    if Sig.ResultType <> '' then
      AOut.Add('  ' + Proc + ' = reference to function' + Params + ': ' + Sig.ResultType + ';')
    else
      AOut.Add('  ' + Proc + ' = reference to procedure' + Params + ';');
    AOut.Add('  ' + Cls + ' = class(TWinRTDelegate, ' + AName + ')');
    AOut.Add('  strict private');
    AOut.Add('    FProc: ' + Proc + ';');
    AOut.Add('  public');
    AOut.Add('    constructor Create(const AProc: ' + Proc + ');');
    AOut.Add('    ' + Sig.Declaration + '; safecall;');
    AOut.Add('  end;');
    AOut.Add('');
    AImpl.Add('{ ' + Cls + ' }');
    AImpl.Add('');
    AImpl.Add('constructor ' + Cls + '.Create(const AProc: ' + Proc + ');');
    AImpl.Add('begin');
    AImpl.Add('  inherited Create;');
    AImpl.Add('  FProc := AProc;');
    AImpl.Add('end;');
    AImpl.Add('');
    AImpl.Add(Sig.Declaration(Cls) + ';');
    AImpl.Add('begin');
    if Sig.ArgNames.Count > 0 then
      Call := 'FProc(' + JoinLines(Sig.ArgNames, ', ') + ')'
    else
      Call := 'FProc()';
    if Sig.ResultType <> '' then
      AImpl.Add('  Result := ' + Call + ';')
    else
      AImpl.Add('  ' + Call + ';');
    AImpl.Add('end;');
    AImpl.Add('');
  finally
    Sig.Free;
    Ctx.Free;
  end;
end;

type
  TMemberEntry = class
  public
    Sig: TSignature;
    Body: string;
    Locals: TArray<string>;
    destructor Destroy; override;
  end;

destructor TMemberEntry.Destroy;
begin
  Sig.Free;
  inherited;
end;

procedure TProjection.EmitClassRecord(AOut, AImpl: TStrings; T: TTypeDef);
var
  Name, Bare, DefaultType, Line: string;
  Members: TObjectList<TMemberEntry>;
  Props: TStringList;
  Scope: TStringSet;
  Refs: TArray<TTypeRef>;
  Ref: TTypeRef;
  Ftd: TTypeDef;
  N: string;
  P: TProperty;
  C: TComposable;
  Entry: TMemberEntry;
  ByName: TObjectDictionary<string, TList<TMemberEntry>>;
  ByNameOrder: TStringList;
  Group: TList<TMemberEntry>;
  SeenKeys: TStringSet;
  Key, Base, Local: string;
  K: Integer;

  procedure AddMember(ASig: TSignature; const ABody: string; const ALocals: TArray<string> = nil);
  var
    E: TMemberEntry;
  begin
    E := TMemberEntry.Create;
    E.Sig := ASig;
    E.Body := ABody;
    E.Locals := ALocals;
    Members.Add(E);
  end;

  procedure FactoryMembers(AIfaceRef: TTypeRef; AComposable, AIsFactory: Boolean);
  var
    Ftd: TTypeDef;
    FType, Fetch, MName, Call, Body: string;
    Slot: Integer;
    MNames: TMethodNames;
    M, G, S: TMethod;
    Sig: TSignature;
    CallArgs: TArray<string>;
    MethodNameSet: TStringSet;
    P: TProperty;
    Line, V: string;
  begin
    Ftd := U.Find(AIfaceRef.Name);
    if (Ftd = nil) or not IncludedNames.ContainsKey(Ftd.FullName) then
      Exit;
    FType := TypeName(AIfaceRef, Scope);
    Slot := FFactorySlots;
    Inc(FFactorySlots);
    Fetch := Format('%s(GetFactory(RuntimeClassName, %s, FactoryCache[%d]))', [FType, FType, Slot]);
    MNames := MethodNames(Ftd);
    for M in Ftd.Methods do
    begin
      MName := MNames[M];
      if AComposable then
      begin
        Sig := Signature(M, 'New', nil, Scope, 2);
        CallArgs := Sig.ArgNames.ToStringArray + ['nil', 'LInner'];
        AddMember(Sig, '  Result := ' + Fetch + '.' + MNames[M] + '(' + string.Join(', ', CallArgs) + ');',
          ['LInner: IInspectable;']);
        Continue;
      end;
      if AIsFactory then
        MName := 'New';
      Sig := Signature(M, MName, nil, Scope);
      Call := Fetch + '.' + MNames[M];
      if Sig.ArgNames.Count > 0 then
        Call := Call + '(' + JoinLines(Sig.ArgNames, ', ') + ')';
      if Sig.ResultType <> '' then
        Body := '  Result := ' + Call + ';'
      else
        Body := '  ' + Call + ';';
      AddMember(Sig, Body);
    end;
    if not AComposable and not AIsFactory then
    begin
      MethodNameSet := TStringSet.Create;
      try
        for V in MNames.Values do
          MethodNameSet.AddOrSetValue(StripAmp(V.ToLower), True);
        for P in Ftd.Properties do
        begin
          if MethodNameSet.ContainsKey(P.Name.ToLower) then
            Continue;
          G := FindMethod(Ftd, P.Getter);
          if (G = nil) or (G.Params.Count > 0) or (G.ReturnType = nil) or (G.ReturnType.Kind = rkSzArray) then
            Continue;
          Line := '    class property ' + Escape(P.Name) + ': ' + TypeName(G.ReturnType, Scope) + ' read ' + MNames[G];
          S := FindMethod(Ftd, P.Setter);
          if (S <> nil) and (S.Params.Count = 1) and (S.Params[0].TypeRef.Kind <> rkSzArray) then
            Line := Line + ' write ' + MNames[S];
          Props.Add(Line + ';');
        end;
      finally
        MethodNameSet.Free;
      end;
    end;
  end;

var
  Sig: TSignature;
begin
  Name := Names[T.FullName];
  Bare := StripAmp(Name);
  Members := TObjectList<TMemberEntry>.Create(True);
  Props := TStringList.Create;
  Scope := TStringSet.Create;
  ByName := TObjectDictionary<string, TList<TMemberEntry>>.Create([doOwnsValues]);
  ByNameOrder := TStringList.Create;
  try
    // Names declared in the record, type references that collide get qualified
    Scope.Add('new', True);
    Scope.Add('runtimeclassname', True);
    Refs := Copy(T.Factories);
    for C in T.Composable do
      Refs := Refs + [C.Factory];
    Refs := Refs + T.Statics;
    for Ref in Refs do
    begin
      Ftd := U.Find(Ref.Name);
      if Ftd <> nil then
      begin
        for N in MethodNames(Ftd).Values do
          Scope.AddOrSetValue(StripAmp(N.ToLower), True);
        for P in Ftd.Properties do
          Scope.AddOrSetValue(P.Name.ToLower, True);
      end;
    end;
    DefaultType := '';
    if T.DefaultInterface <> nil then
      DefaultType := TypeName(T.DefaultInterface, Scope);

    if T.ActivatableDefault and (DefaultType <> '') then
    begin
      Sig := TSignature.Create('New');
      Sig.ResultType := DefaultType;
      AddMember(Sig, Format('  Result := %s(ActivateInstance(RuntimeClassName, %s));', [DefaultType, DefaultType]));
    end;
    for Ref in T.Factories do
      FactoryMembers(Ref, False, True);
    for C in T.Composable do
      if C.IsPublic then
        FactoryMembers(C.Factory, True, False);
    for Ref in T.Statics do
      FactoryMembers(Ref, False, False);

    // Overloads: same name gets `overload`, identical parameter lists get a suffix
    for Entry in Members do
    begin
      Key := Entry.Sig.Name.ToLower;
      if not ByName.TryGetValue(Key, Group) then
      begin
        Group := TList<TMemberEntry>.Create;
        ByName.Add(Key, Group);
        ByNameOrder.Add(Key);
      end;
      Group.Add(Entry);
    end;
    for Key in ByNameOrder do
    begin
      Group := ByName[Key];
      SeenKeys := TStringSet.Create;
      try
        for Entry in Group do
        begin
          Line := string.Join(#0, Entry.Sig.ArgTypes.ToStringArray);
          if SeenKeys.ContainsKey(Line) then
          begin
            Base := Entry.Sig.Name;
            K := 2;
            while ByName.ContainsKey((Base + IntToStr(K)).ToLower) do
              Inc(K);
            Entry.Sig.Name := Base + IntToStr(K);
          end;
          SeenKeys.AddOrSetValue(Line, True);
          if Group.Count > 1 then
            Entry.Sig.Overload := True;
        end;
      finally
        SeenKeys.Free;
      end;
    end;

    AOut.Add('  // ' + T.FullName);
    AOut.Add('  ' + Name + ' = record');
    AOut.Add('  public const');
    AOut.Add('    RuntimeClassName = ''' + T.FullName + ''';');
    if (Members.Count > 0) or (Props.Count > 0) then
      AOut.Add('  public');
    for Entry in Members do
      if Entry.Sig.Overload then
        AOut.Add('    class ' + Entry.Sig.Declaration + '; overload; static;')
      else
        AOut.Add('    class ' + Entry.Sig.Declaration + '; static;');
    AOut.AddStrings(Props);
    AOut.Add('  end;');
    AOut.Add('');

    if Members.Count = 0 then
      Exit;
    AImpl.Add('{ ' + Bare + ' }');
    AImpl.Add('');
    for Entry in Members do
    begin
      AImpl.Add('class ' + Entry.Sig.Declaration(Bare) + ';');
      if Length(Entry.Locals) > 0 then
      begin
        AImpl.Add('var');
        for Local in Entry.Locals do
          AImpl.Add('  ' + Local);
      end;
      AImpl.Add('begin');
      AImpl.Add(Entry.Body);
      AImpl.Add('end;');
      AImpl.Add('');
    end;
  finally
    ByNameOrder.Free;
    ByName.Free;
    Scope.Free;
    Props.Free;
    Members.Free;
  end;
end;

end.
