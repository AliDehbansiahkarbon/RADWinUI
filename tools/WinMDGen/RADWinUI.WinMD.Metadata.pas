unit RADWinUI.WinMD.Metadata;

(*
  Minimal ECMA-335 metadata reader for Windows Runtime .winmd files.
  Reads the PE container, the metadata heaps and every table into raw column
  values, the accessors decode strings, blobs and coded indexes on demand.
  Higher-level WinRT interpretation lives in RADWinUI.WinMD.Model.
*)

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

const
  // Table ids (ECMA-335 II.22)
  mtModule = 0; mtTypeRef = 1; mtTypeDef = 2; mtFieldPtr = 3; mtField = 4; mtMethodPtr = 5; mtMethodDef = 6;
  mtParamPtr = 7; mtParam = 8; mtInterfaceImpl = 9; mtMemberRef = 10; mtConstant = 11; mtCustomAttribute = 12;
  mtFieldMarshal = 13; mtDeclSecurity = 14; mtClassLayout = 15; mtFieldLayout = 16; mtStandAloneSig = 17;
  mtEventMap = 18; mtEventPtr = 19; mtEvent = 20; mtPropertyMap = 21; mtPropertyPtr = 22; mtProperty = 23;
  mtMethodSemantics = 24; mtMethodImpl = 25; mtModuleRef = 26; mtTypeSpec = 27; mtImplMap = 28; mtFieldRva = 29;
  mtEncLog = 30; mtEncMap = 31; mtAssembly = 32; mtAssemblyProcessor = 33; mtAssemblyOS = 34; mtAssemblyRef = 35;
  mtAssemblyRefProcessor = 36; mtAssemblyRefOS = 37; mtFile = 38; mtExportedType = 39; mtManifestResource = 40;
  mtNestedClass = 41; mtGenericParam = 42; mtMethodSpec = 43; mtGenericParamConstraint = 44;
  mtNone = -1;

  // Coded index kinds
  ciTypeDefOrRef = 0; ciHasConstant = 1; ciHasCustomAttribute = 2; ciHasFieldMarshal = 3; ciHasDeclSecurity = 4;
  ciMemberRefParent = 5; ciHasSemantics = 6; ciMethodDefOrRef = 7; ciMemberForwarded = 8; ciImplementation = 9;
  ciCustomAttributeType = 10; ciResolutionScope = 11; ciTypeOrMethodDef = 12;

type
  EMetadataError = class(Exception);

  /// <summary>A coded index: table and 1-based row, row 0 or table mtNone means null.</summary>
  TCodedIndex = record
    Table, Row: Integer;
    function IsNull: Boolean;
  end;

  TMetadataFile = class
  private type
    TColumn = record
      Kind: Integer;   // 0 u1/u2/u4, 1 string, 2 guid, 3 blob, 4 index, 5 coded index
      Target: Integer; // table of an index, kind of a coded index
      Size: Integer;
    end;
  private
    FPath: string;
    FData: TBytes;
    FSections: TArray<TArray<Cardinal>>; // va, size, rawptr
    FMetadata: Cardinal;
    FStrings, FBlob, FGuid, FTableStream: Cardinal;
    FRowCounts: array[0..63] of Integer;
    FColumns: array[0..63] of TArray<TColumn>;
    FRows: array[0..63] of TArray<Cardinal>; // row-major raw values
    FStringCache: TDictionary<Cardinal, string>;
    function U16(APos: Cardinal): Word; inline;
    function U32(APos: Cardinal): Cardinal; inline;
    function RvaToOffset(ARva: Cardinal): Cardinal;
    procedure ReadPe;
    procedure ReadRoot;
    procedure ReadTables;
  public
    /// <summary>Per-file caches the model builds once (owned by the model).</summary>
    Caches: TDictionary<string, TObject>;
    constructor Create(const APath: string);
    destructor Destroy; override;
    function RowCount(ATable: Integer): Integer;
    /// <summary>Raw column value: a number, a heap index or a 1-based row index.</summary>
    function Num(ATable, ARow, ACol: Integer): Cardinal;
    function Str(ATable, ARow, ACol: Integer): string;
    function Blob(ATable, ARow, ACol: Integer): TBytes;
    function Guid(ATable, ARow, ACol: Integer): TBytes;
    function Coded(ATable, ARow, ACol: Integer): TCodedIndex;
    /// <summary>End (exclusive) of a run-list column such as TypeDef.MethodList.</summary>
    function RangeEnd(ATable, AOwnerTable, AOwnerRow, ACol: Integer): Integer;
    property Path: string read FPath;
  end;

/// <summary>Reads an ECMA-335 compressed unsigned integer at APos and advances it.</summary>
function DecompressUInt(const AData: TBytes; var APos: Integer): Cardinal;

implementation

const
  // Column kinds of the schema
  cNum = 0; cStr = 1; cGuid = 2; cBlob = 3; cIdx = 4; cCoded = 5;

type
  TCodedInfo = record
    Bits: Integer;
    Tables: TArray<Integer>;
  end;

var
  CodedInfo: array[0..12] of TCodedInfo;
  // per table: pairs of (kind, size-or-target), a numeric column carries its byte size
  Schema: array[0..44] of TArray<Integer>;

function TCodedIndex.IsNull: Boolean;
begin
  Result := (Row = 0) or (Table = mtNone);
end;

function DecompressUInt(const AData: TBytes; var APos: Integer): Cardinal;
var
  B0: Byte;
begin
  B0 := AData[APos];
  if B0 and $80 = 0 then
  begin
    Result := B0;
    Inc(APos);
  end
  else if B0 and $C0 = $80 then
  begin
    Result := (Cardinal(B0 and $3F) shl 8) or AData[APos + 1];
    Inc(APos, 2);
  end
  else if B0 and $E0 = $C0 then
  begin
    Result := (Cardinal(B0 and $1F) shl 24) or (Cardinal(AData[APos + 1]) shl 16) or
      (Cardinal(AData[APos + 2]) shl 8) or AData[APos + 3];
    Inc(APos, 4);
  end
  else
    raise EMetadataError.CreateFmt('bad compressed integer at %d', [APos]);
end;

procedure Coded(AKind, ABits: Integer; const ATables: array of Integer);
var
  I: Integer;
begin
  CodedInfo[AKind].Bits := ABits;
  SetLength(CodedInfo[AKind].Tables, Length(ATables));
  for I := 0 to High(ATables) do
    CodedInfo[AKind].Tables[I] := ATables[I];
end;

procedure Table(ATable: Integer; const AColumns: array of Integer);
var
  I: Integer;
begin
  SetLength(Schema[ATable], Length(AColumns));
  for I := 0 to High(AColumns) do
    Schema[ATable][I] := AColumns[I];
end;

procedure InitSchema;
const
  U1 = 1; U2 = 2; U4 = 4;
begin
  Coded(ciTypeDefOrRef, 2, [mtTypeDef, mtTypeRef, mtTypeSpec]);
  Coded(ciHasConstant, 2, [mtField, mtParam, mtProperty]);
  Coded(ciHasCustomAttribute, 5, [mtMethodDef, mtField, mtTypeRef, mtTypeDef, mtParam, mtInterfaceImpl, mtMemberRef,
    mtModule, mtDeclSecurity, mtProperty, mtEvent, mtStandAloneSig, mtModuleRef, mtTypeSpec, mtAssembly, mtAssemblyRef,
    mtFile, mtExportedType, mtManifestResource, mtGenericParam, mtGenericParamConstraint, mtMethodSpec]);
  Coded(ciHasFieldMarshal, 1, [mtField, mtParam]);
  Coded(ciHasDeclSecurity, 2, [mtTypeDef, mtMethodDef, mtAssembly]);
  Coded(ciMemberRefParent, 3, [mtTypeDef, mtTypeRef, mtModuleRef, mtMethodDef, mtTypeSpec]);
  Coded(ciHasSemantics, 1, [mtEvent, mtProperty]);
  Coded(ciMethodDefOrRef, 1, [mtMethodDef, mtMemberRef]);
  Coded(ciMemberForwarded, 1, [mtField, mtMethodDef]);
  Coded(ciImplementation, 2, [mtFile, mtAssemblyRef, mtExportedType]);
  Coded(ciCustomAttributeType, 3, [mtNone, mtNone, mtMethodDef, mtMemberRef, mtNone]);
  Coded(ciResolutionScope, 2, [mtModule, mtModuleRef, mtAssemblyRef, mtTypeRef]);
  Coded(ciTypeOrMethodDef, 1, [mtTypeDef, mtMethodDef]);

  // (kind, size or target) per column, in table order
  Table(mtModule, [cNum, U2, cStr, 0, cGuid, 0, cGuid, 0, cGuid, 0]);
  Table(mtTypeRef, [cCoded, ciResolutionScope, cStr, 0, cStr, 0]);
  Table(mtTypeDef, [cNum, U4, cStr, 0, cStr, 0, cCoded, ciTypeDefOrRef, cIdx, mtField, cIdx, mtMethodDef]);
  Table(mtFieldPtr, [cIdx, mtField]);
  Table(mtField, [cNum, U2, cStr, 0, cBlob, 0]);
  Table(mtMethodPtr, [cIdx, mtMethodDef]);
  Table(mtMethodDef, [cNum, U4, cNum, U2, cNum, U2, cStr, 0, cBlob, 0, cIdx, mtParam]);
  Table(mtParamPtr, [cIdx, mtParam]);
  Table(mtParam, [cNum, U2, cNum, U2, cStr, 0]);
  Table(mtInterfaceImpl, [cIdx, mtTypeDef, cCoded, ciTypeDefOrRef]);
  Table(mtMemberRef, [cCoded, ciMemberRefParent, cStr, 0, cBlob, 0]);
  Table(mtConstant, [cNum, U1, cNum, U1, cCoded, ciHasConstant, cBlob, 0]);
  Table(mtCustomAttribute, [cCoded, ciHasCustomAttribute, cCoded, ciCustomAttributeType, cBlob, 0]);
  Table(mtFieldMarshal, [cCoded, ciHasFieldMarshal, cBlob, 0]);
  Table(mtDeclSecurity, [cNum, U2, cCoded, ciHasDeclSecurity, cBlob, 0]);
  Table(mtClassLayout, [cNum, U2, cNum, U4, cIdx, mtTypeDef]);
  Table(mtFieldLayout, [cNum, U4, cIdx, mtField]);
  Table(mtStandAloneSig, [cBlob, 0]);
  Table(mtEventMap, [cIdx, mtTypeDef, cIdx, mtEvent]);
  Table(mtEventPtr, [cIdx, mtEvent]);
  Table(mtEvent, [cNum, U2, cStr, 0, cCoded, ciTypeDefOrRef]);
  Table(mtPropertyMap, [cIdx, mtTypeDef, cIdx, mtProperty]);
  Table(mtPropertyPtr, [cIdx, mtProperty]);
  Table(mtProperty, [cNum, U2, cStr, 0, cBlob, 0]);
  Table(mtMethodSemantics, [cNum, U2, cIdx, mtMethodDef, cCoded, ciHasSemantics]);
  Table(mtMethodImpl, [cIdx, mtTypeDef, cCoded, ciMethodDefOrRef, cCoded, ciMethodDefOrRef]);
  Table(mtModuleRef, [cStr, 0]);
  Table(mtTypeSpec, [cBlob, 0]);
  Table(mtImplMap, [cNum, U2, cCoded, ciMemberForwarded, cStr, 0, cIdx, mtModuleRef]);
  Table(mtFieldRva, [cNum, U4, cIdx, mtField]);
  Table(mtEncLog, [cNum, U4, cNum, U4]);
  Table(mtEncMap, [cNum, U4]);
  Table(mtAssembly, [cNum, U4, cNum, U2, cNum, U2, cNum, U2, cNum, U2, cNum, U4, cBlob, 0, cStr, 0, cStr, 0]);
  Table(mtAssemblyProcessor, [cNum, U4]);
  Table(mtAssemblyOS, [cNum, U4, cNum, U4, cNum, U4]);
  Table(mtAssemblyRef, [cNum, U2, cNum, U2, cNum, U2, cNum, U2, cNum, U4, cBlob, 0, cStr, 0, cStr, 0, cBlob, 0]);
  Table(mtAssemblyRefProcessor, [cNum, U4, cIdx, mtAssemblyRef]);
  Table(mtAssemblyRefOS, [cNum, U4, cNum, U4, cNum, U4, cIdx, mtAssemblyRef]);
  Table(mtFile, [cNum, U4, cStr, 0, cBlob, 0]);
  Table(mtExportedType, [cNum, U4, cNum, U4, cStr, 0, cStr, 0, cCoded, ciImplementation]);
  Table(mtManifestResource, [cNum, U4, cNum, U4, cStr, 0, cCoded, ciImplementation]);
  Table(mtNestedClass, [cIdx, mtTypeDef, cIdx, mtTypeDef]);
  Table(mtGenericParam, [cNum, U2, cNum, U2, cCoded, ciTypeOrMethodDef, cStr, 0]);
  Table(mtMethodSpec, [cCoded, ciMethodDefOrRef, cBlob, 0]);
  Table(mtGenericParamConstraint, [cIdx, mtGenericParam, cCoded, ciTypeDefOrRef]);
end;

{ TMetadataFile }

constructor TMetadataFile.Create(const APath: string);
begin
  inherited Create;
  FPath := APath;
  FStringCache := TDictionary<Cardinal, string>.Create;
  Caches := TDictionary<string, TObject>.Create;
  with TFileStream.Create(APath, fmOpenRead or fmShareDenyWrite) do
  try
    SetLength(FData, Size);
    if Size > 0 then
      ReadBuffer(FData[0], Size);
  finally
    Free;
  end;
  ReadPe;
  ReadRoot;
  ReadTables;
end;

destructor TMetadataFile.Destroy;
var
  Cache: TObject;
begin
  for Cache in Caches.Values do
    Cache.Free;
  Caches.Free;
  FStringCache.Free;
  inherited;
end;

function TMetadataFile.U16(APos: Cardinal): Word;
begin
  Result := FData[APos] or (Word(FData[APos + 1]) shl 8);
end;

function TMetadataFile.U32(APos: Cardinal): Cardinal;
begin
  Result := FData[APos] or (Cardinal(FData[APos + 1]) shl 8) or (Cardinal(FData[APos + 2]) shl 16) or
    (Cardinal(FData[APos + 3]) shl 24);
end;

function TMetadataFile.RvaToOffset(ARva: Cardinal): Cardinal;
var
  S: TArray<Cardinal>;
begin
  for S in FSections do
    if (S[0] <= ARva) and (ARva < S[0] + S[1]) then
      Exit(ARva - S[0] + S[2]);
  raise EMetadataError.CreateFmt('%s: RVA $%x outside sections', [FPath, ARva]);
end;

procedure TMetadataFile.ReadPe;
var
  Pe, Coff, Opt, Dirs, Sec, Cli: Cardinal;
  NSections, OptSize, I: Integer;
  VSize, RawSize: Cardinal;
begin
  if (Length(FData) < 2) or (FData[0] <> Ord('M')) or (FData[1] <> Ord('Z')) then
    raise EMetadataError.Create(FPath + ': not a PE file');
  Pe := U32($3C);
  if U32(Pe) <> $00004550 then
    raise EMetadataError.Create(FPath + ': missing PE signature');
  Coff := Pe + 4;
  NSections := U16(Coff + 2);
  OptSize := U16(Coff + 16);
  Opt := Coff + 20;
  if U16(Opt) = $10B then
    Dirs := Opt + 96
  else
    Dirs := Opt + 112;
  Sec := Opt + Cardinal(OptSize);
  SetLength(FSections, NSections);
  for I := 0 to NSections - 1 do
  begin
    VSize := U32(Sec + Cardinal(I) * 40 + 8);
    RawSize := U32(Sec + Cardinal(I) * 40 + 16);
    if RawSize > VSize then
      VSize := RawSize;
    FSections[I] := [U32(Sec + Cardinal(I) * 40 + 12), VSize, U32(Sec + Cardinal(I) * 40 + 20)];
  end;
  Cli := RvaToOffset(U32(Dirs + 14 * 8));
  FMetadata := RvaToOffset(U32(Cli + 8));
end;

procedure TMetadataFile.ReadRoot;
var
  Pos, Off, NameEnd: Cardinal;
  VLen, NStreams, I: Integer;
  Name: string;
begin
  if U32(FMetadata) <> $424A5342 then
    raise EMetadataError.Create(FPath + ': bad metadata signature');
  VLen := U32(FMetadata + 12);
  Pos := FMetadata + 16 + Cardinal(VLen);
  NStreams := U16(Pos + 2);
  Inc(Pos, 4);
  FGuid := 0;
  for I := 1 to NStreams do
  begin
    Off := U32(Pos);
    Inc(Pos, 8);
    NameEnd := Pos;
    while FData[NameEnd] <> 0 do
      Inc(NameEnd);
    Name := TEncoding.ASCII.GetString(FData, Pos, NameEnd - Pos);
    Pos := (NameEnd + 4) and not Cardinal(3);
    if (Name = '#~') or (Name = '#-') then
      FTableStream := FMetadata + Off
    else if Name = '#Strings' then
      FStrings := FMetadata + Off
    else if Name = '#Blob' then
      FBlob := FMetadata + Off
    else if Name = '#GUID' then
      FGuid := FMetadata + Off;
  end;
end;

procedure TMetadataFile.ReadTables;
var
  Pos: Cardinal;
  HeapSizes: Byte;
  Valid: UInt64;
  T, C, R, Kind, StrSize, GuidSize, BlobSize: Integer;
  Cols: TArray<TColumn>;
  Values: TArray<Cardinal>;
  Raw: Cardinal;
  B: Integer;

  function CodedSize(AKind: Integer): Integer;
  var
    Limit, Tbl: Integer;
  begin
    Limit := 1 shl (16 - CodedInfo[AKind].Bits);
    for Tbl in CodedInfo[AKind].Tables do
      if (Tbl <> mtNone) and (FRowCounts[Tbl] >= Limit) then
        Exit(4);
    Result := 2;
  end;

begin
  Pos := FTableStream;
  HeapSizes := FData[Pos + 6];
  Valid := UInt64(U32(Pos + 8)) or (UInt64(U32(Pos + 12)) shl 32);
  Inc(Pos, 24);
  for T := 0 to 63 do
    if (Valid shr T) and 1 = 1 then
    begin
      FRowCounts[T] := U32(Pos);
      Inc(Pos, 4);
    end
    else
      FRowCounts[T] := 0;
  if HeapSizes and $40 <> 0 then
    Inc(Pos, 4);
  StrSize := 2 + 2 * Ord(HeapSizes and $01 <> 0);
  GuidSize := 2 + 2 * Ord(HeapSizes and $02 <> 0);
  BlobSize := 2 + 2 * Ord(HeapSizes and $04 <> 0);
  for T := 0 to 63 do
  begin
    if FRowCounts[T] = 0 then
      Continue;
    if (T > High(Schema)) or (Length(Schema[T]) = 0) then
      raise EMetadataError.CreateFmt('%s: unsupported table $%x', [FPath, T]);
    SetLength(Cols, Length(Schema[T]) div 2);
    for C := 0 to High(Cols) do
    begin
      Kind := Schema[T][C * 2];
      Cols[C].Kind := Kind;
      Cols[C].Target := Schema[T][C * 2 + 1];
      case Kind of
        cNum: Cols[C].Size := Cols[C].Target;
        cStr: Cols[C].Size := StrSize;
        cGuid: Cols[C].Size := GuidSize;
        cBlob: Cols[C].Size := BlobSize;
        cIdx: Cols[C].Size := 2 + 2 * Ord(FRowCounts[Cols[C].Target] >= $10000);
        cCoded: Cols[C].Size := CodedSize(Cols[C].Target);
      end;
    end;
    FColumns[T] := Copy(Cols);
    SetLength(Values, FRowCounts[T] * Length(Cols));
    for R := 0 to FRowCounts[T] - 1 do
      for C := 0 to High(Cols) do
      begin
        Raw := 0;
        for B := Cols[C].Size - 1 downto 0 do
          Raw := (Raw shl 8) or FData[Pos + Cardinal(B)];
        Inc(Pos, Cols[C].Size);
        Values[R * Length(Cols) + C] := Raw;
      end;
    FRows[T] := Values;
    Values := nil;
  end;
end;

function TMetadataFile.RowCount(ATable: Integer): Integer;
begin
  Result := FRowCounts[ATable];
end;

function TMetadataFile.Num(ATable, ARow, ACol: Integer): Cardinal;
begin
  Result := FRows[ATable][(ARow - 1) * Length(FColumns[ATable]) + ACol];
end;

function TMetadataFile.Str(ATable, ARow, ACol: Integer): string;
var
  Index, Start, Stop: Cardinal;
begin
  Index := Num(ATable, ARow, ACol);
  if not FStringCache.TryGetValue(Index, Result) then
  begin
    Start := FStrings + Index;
    Stop := Start;
    while FData[Stop] <> 0 do
      Inc(Stop);
    Result := TEncoding.UTF8.GetString(FData, Start, Stop - Start);
    FStringCache.Add(Index, Result);
  end;
end;

function TMetadataFile.Blob(ATable, ARow, ACol: Integer): TBytes;
var
  Pos: Integer;
  Len: Cardinal;
begin
  Pos := FBlob + Num(ATable, ARow, ACol);
  Len := DecompressUInt(FData, Pos);
  Result := Copy(FData, Pos, Len);
end;

function TMetadataFile.Guid(ATable, ARow, ACol: Integer): TBytes;
var
  Index: Cardinal;
begin
  Index := Num(ATable, ARow, ACol);
  if Index = 0 then
  begin
    SetLength(Result, 16);
    FillChar(Result[0], 16, 0);
  end
  else
    Result := Copy(FData, FGuid + (Index - 1) * 16, 16);
end;

function TMetadataFile.Coded(ATable, ARow, ACol: Integer): TCodedIndex;
var
  Raw: Cardinal;
  Info: TCodedInfo;
  Tag: Integer;
begin
  Raw := Num(ATable, ARow, ACol);
  Info := CodedInfo[FColumns[ATable][ACol].Target];
  Tag := Raw and ((1 shl Info.Bits) - 1);
  if Tag < Length(Info.Tables) then
    Result.Table := Info.Tables[Tag]
  else
    Result.Table := mtNone;
  Result.Row := Raw shr Info.Bits;
end;

function TMetadataFile.RangeEnd(ATable, AOwnerTable, AOwnerRow, ACol: Integer): Integer;
begin
  if AOwnerRow < FRowCounts[AOwnerTable] then
    Result := Num(AOwnerTable, AOwnerRow + 1, ACol)
  else
    Result := FRowCounts[ATable] + 1;
end;

initialization
  InitSchema;

end.
