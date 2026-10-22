unit RADWinUI.CodeGen.Xml;

(*
  The XML tree of XamlCodeGen. Its parsing and
  serialization rules are fixed, so a regenerated unit is byte for byte the
  same as before:

  - element and attribute names in Clark notation ({uri}local), attributes in
    document order, xmlns declarations consumed;
  - Text (before the first child) and Tail (after the element), comments and
    processing instructions are dropped, the text around them joins;
  - line ends become LF, whitespace in attribute values becomes a space, entity
    and character references are decoded;
  - ToXml declares the namespaces it uses on the first
    element, sorted by prefix, "<Tag />" when empty, minimal escaping.
*)

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  EXmlError = class(Exception);

  TXmlElement = class
  private
    FChildren: TObjectList<TXmlElement>;
    FNames: TList<string>;
    FValues: TList<string>;
    function GetChild(Index: Integer): TXmlElement;
    function GetCount: Integer;
    function GetAttrCount: Integer;
    function GetAttrName(Index: Integer): string;
    function GetAttrValue(Index: Integer): string;
  public
    Tag: string;   // {uri}local, or local without a namespace
    Text: string;  // before the first child
    Tail: string;  // after the end tag, up to the next sibling or the parent's end tag
    Line: Integer; // line of the start tag (1-based), as expat reports it
    constructor Create(const ATag: string);
    destructor Destroy; override;
    function Has(const AName: string): Boolean;
    function Get(const AName: string; const ADefault: string = ''): string;
    /// <summary>Replaces the value, or appends the attribute at the end.</summary>
    procedure SetAttr(const AName, AValue: string);
    /// <summary>Removes the attribute and returns its value ('' when absent).</summary>
    function Pop(const AName: string): string;
    procedure Add(AChild: TXmlElement);
    /// <summary>Removes and frees the child at Index.</summary>
    procedure Delete(Index: Integer);
    /// <summary>This element and its descendants in document order.</summary>
    function Iter: TArray<TXmlElement>;
    property Children[Index: Integer]: TXmlElement read GetChild; default;
    property Count: Integer read GetCount;
    property AttrCount: Integer read GetAttrCount;
    property AttrName[Index: Integer]: string read GetAttrName;
    property AttrValue[Index: Integer]: string read GetAttrValue;
  end;

  /// <summary>A registered namespace prefix.</summary>
  TXmlPrefix = record
    Uri, Prefix: string;
  end;

/// <summary>Parses AText (an XML document) into its root element. Raises EXmlError.</summary>
function ParseXml(const AText: string): TXmlElement;
/// <summary>The text of an XML file: BOM-aware, UTF-8 without one.</summary>
function ReadXmlFile(const APath: string): string;
/// <summary>AElement and its Tail written as XML text.</summary>
function ToXml(AElement: TXmlElement; const ARegistered: array of TXmlPrefix): string;

implementation

uses
  System.IOUtils, System.Character;

const
  XmlNamespace = 'http://www.w3.org/XML/1998/namespace';

{ TXmlElement }

constructor TXmlElement.Create(const ATag: string);
begin
  inherited Create;
  Tag := ATag;
  FChildren := TObjectList<TXmlElement>.Create(True);
  FNames := TList<string>.Create;
  FValues := TList<string>.Create;
end;

destructor TXmlElement.Destroy;
begin
  FValues.Free;
  FNames.Free;
  FChildren.Free;
  inherited;
end;

function TXmlElement.GetChild(Index: Integer): TXmlElement;
begin
  Result := FChildren[Index];
end;

function TXmlElement.GetCount: Integer;
begin
  Result := FChildren.Count;
end;

function TXmlElement.GetAttrCount: Integer;
begin
  Result := FNames.Count;
end;

function TXmlElement.GetAttrName(Index: Integer): string;
begin
  Result := FNames[Index];
end;

function TXmlElement.GetAttrValue(Index: Integer): string;
begin
  Result := FValues[Index];
end;

function TXmlElement.Has(const AName: string): Boolean;
begin
  Result := FNames.IndexOf(AName) >= 0;
end;

function TXmlElement.Get(const AName, ADefault: string): string;
var
  I: Integer;
begin
  I := FNames.IndexOf(AName);
  if I < 0 then
    Result := ADefault
  else
    Result := FValues[I];
end;

procedure TXmlElement.SetAttr(const AName, AValue: string);
var
  I: Integer;
begin
  I := FNames.IndexOf(AName);
  if I < 0 then
  begin
    FNames.Add(AName);
    FValues.Add(AValue);
  end
  else
    FValues[I] := AValue;
end;

function TXmlElement.Pop(const AName: string): string;
var
  I: Integer;
begin
  Result := '';
  I := FNames.IndexOf(AName);
  if I >= 0 then
  begin
    Result := FValues[I];
    FNames.Delete(I);
    FValues.Delete(I);
  end;
end;

procedure TXmlElement.Add(AChild: TXmlElement);
begin
  FChildren.Add(AChild);
end;

procedure TXmlElement.Delete(Index: Integer);
begin
  FChildren.Delete(Index);
end;

function TXmlElement.Iter: TArray<TXmlElement>;
var
  List: TList<TXmlElement>;

  procedure Walk(E: TXmlElement);
  var
    I: Integer;
  begin
    List.Add(E);
    for I := 0 to E.Count - 1 do
      Walk(E[I]);
  end;

begin
  List := TList<TXmlElement>.Create;
  try
    Walk(Self);
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

{ Parser }

type
  TXmlParser = class
  private
    S: string;
    P, Line, LineStart: Integer;
    Scopes: TList<TPair<string, string>>; // prefix -> uri, innermost last
    procedure Fail(const AMessage: string; APos: Integer = 0);
    function AtEnd: Boolean; inline;
    function Peek(const AText: string): Boolean;
    procedure Advance(N: Integer = 1);
    procedure SkipSpace;
    function ReadName: string;
    function ReadReference: string;
    procedure SkipUntil(const ATerminator, AError: string);
    procedure SkipMisc;
    function Resolve(const APrefix: string; AStart: Integer): string;
    function ParseElement: TXmlElement;
  public
    constructor Create(const AText: string);
    destructor Destroy; override;
    function Parse: TXmlElement;
  end;

constructor TXmlParser.Create(const AText: string);
begin
  inherited Create;
  // XML end-of-line handling: CRLF and lone CR are LF
  S := AText.Replace(#13#10, #10).Replace(#13, #10);
  if (S <> '') and (S[1] = #$FEFF) then
    System.Delete(S, 1, 1);
  P := 1;
  Line := 1;
  LineStart := 1;
  Scopes := TList<TPair<string, string>>.Create;
end;

destructor TXmlParser.Destroy;
begin
  Scopes.Free;
  inherited;
end;

procedure TXmlParser.Fail(const AMessage: string; APos: Integer);
var
  At, L, Start, I: Integer;
begin
  At := APos;
  if At = 0 then
    At := P;
  L := 1;
  Start := 1;
  for I := 1 to At - 1 do
    if (I <= Length(S)) and (S[I] = #10) then
    begin
      Inc(L);
      Start := I + 1;
    end;
  // expat's words and its 0-based column
  raise EXmlError.CreateFmt('%s: line %d, column %d', [AMessage, L, At - Start]);
end;

function TXmlParser.AtEnd: Boolean;
begin
  Result := P > Length(S);
end;

function TXmlParser.Peek(const AText: string): Boolean;
begin
  Result := Copy(S, P, Length(AText)) = AText;
end;

procedure TXmlParser.Advance(N: Integer);
var
  I: Integer;
begin
  for I := 1 to N do
  begin
    if (P <= Length(S)) and (S[P] = #10) then
    begin
      Inc(Line);
      LineStart := P + 1;
    end;
    Inc(P);
  end;
end;

procedure TXmlParser.SkipSpace;
begin
  while not AtEnd and CharInSet(S[P], [' ', #9, #10]) do
    Advance;
end;

function IsNameChar(C: Char; AFirst: Boolean): Boolean;
begin
  Result := CharInSet(C, ['A'..'Z', 'a'..'z', '_', ':']) or (Ord(C) >= $80) or
    (not AFirst and CharInSet(C, ['0'..'9', '.', '-']));
end;

function TXmlParser.ReadName: string;
var
  Start: Integer;
begin
  Start := P;
  if AtEnd or not IsNameChar(S[P], True) then
    Fail('not well-formed (invalid token)');
  while not AtEnd and IsNameChar(S[P], False) do
    Advance;
  Result := Copy(S, Start, P - Start);
end;

function TXmlParser.ReadReference: string;
var
  Start, Code: Integer;
  Name: string;
begin
  Start := P;
  Advance; // &
  while not AtEnd and (S[P] <> ';') and not CharInSet(S[P], [' ', #9, #10, '<', '&']) do
    Advance;
  if AtEnd or (S[P] <> ';') then
    Fail('not well-formed (invalid token)', Start);
  Name := Copy(S, Start + 1, P - Start - 1);
  Advance; // ;
  if Name.StartsWith('#x') then
    Code := StrToIntDef('$' + Copy(Name, 3, MaxInt), -1)
  else if Name.StartsWith('#') then
    Code := StrToIntDef(Copy(Name, 2, MaxInt), -1)
  else if Name = 'amp' then Exit('&')
  else if Name = 'lt' then Exit('<')
  else if Name = 'gt' then Exit('>')
  else if Name = 'quot' then Exit('"')
  else if Name = 'apos' then Exit('''')
  else
  begin
    Fail('undefined entity', Start);
    Code := -1;
  end;
  if (Code <= 0) or (Code > $10FFFF) then
    Fail('reference to invalid character number', Start);
  Result := Char.ConvertFromUtf32(Code);
end;

procedure TXmlParser.SkipUntil(const ATerminator, AError: string);
begin
  while not AtEnd and not Peek(ATerminator) do
    Advance;
  if AtEnd then
    Fail(AError);
  Advance(Length(ATerminator));
end;

/// Whitespace, comments, processing instructions and a DOCTYPE outside the root element.
procedure TXmlParser.SkipMisc;
var
  Depth: Integer;
begin
  while True do
  begin
    SkipSpace;
    if Peek('<?') then
      SkipUntil('?>', 'unclosed token')
    else if Peek('<!--') then
      SkipUntil('-->', 'unclosed token')
    else if Peek('<!DOCTYPE') then
    begin
      Depth := 0;
      while not AtEnd and ((S[P] <> '>') or (Depth > 0)) do
      begin
        if S[P] = '[' then Inc(Depth)
        else if S[P] = ']' then Dec(Depth);
        Advance;
      end;
      if AtEnd then
        Fail('unclosed token');
      Advance;
    end
    else
      Exit;
  end;
end;

function TXmlParser.Resolve(const APrefix: string; AStart: Integer): string;
var
  I: Integer;
begin
  if APrefix = 'xml' then
    Exit(XmlNamespace);
  for I := Scopes.Count - 1 downto 0 do
    if Scopes[I].Key = APrefix then
      Exit(Scopes[I].Value);
  if APrefix <> '' then
    Fail('unbound prefix', AStart);
  Result := '';
end;

function Clark(const AUri, ALocal: string): string;
begin
  if AUri = '' then
    Result := ALocal
  else
    Result := '{' + AUri + '}' + ALocal;
end;

function SplitQName(const AName: string; out APrefix, ALocal: string): Boolean;
var
  I: Integer;
begin
  I := AName.IndexOf(':');
  Result := I >= 0;
  if Result then
  begin
    APrefix := AName.Substring(0, I);
    ALocal := AName.Substring(I + 1);
  end
  else
  begin
    APrefix := '';
    ALocal := AName;
  end;
end;

function TXmlParser.ParseElement: TXmlElement;
var
  Start, StartLine, ValueStart, ScopeCount, I: Integer;
  RawName, Name, Value, Prefix, Local, Uri, EndName: string;
  Quote: Char;
  RawNames, RawValues: TList<string>;
  Child, Last: TXmlElement;
  Data: TStringBuilder;

  procedure Flush;
  begin
    if Last = nil then
      Result.Text := Result.Text + Data.ToString
    else
      Last.Tail := Last.Tail + Data.ToString;
    Data.Clear;
  end;

begin
  Start := P;
  StartLine := Line;
  Advance; // <
  RawName := ReadName;
  RawNames := TList<string>.Create;
  RawValues := TList<string>.Create;
  ScopeCount := Scopes.Count;
  Result := nil;
  try
    try
      // Attributes
      while True do
      begin
        I := P;
        SkipSpace;
        if AtEnd then
          Fail('unclosed token', Start);
        if (S[P] = '>') or Peek('/>') then
          Break;
        if I = P then
          Fail('not well-formed (invalid token)');
        ValueStart := P;
        Name := ReadName;
        SkipSpace;
        if AtEnd or (S[P] <> '=') then
          Fail('not well-formed (invalid token)');
        Advance;
        SkipSpace;
        if AtEnd or not CharInSet(S[P], ['"', '''']) then
          Fail('not well-formed (invalid token)');
        Quote := S[P];
        Advance;
        Value := '';
        while not AtEnd and (S[P] <> Quote) do
        begin
          if S[P] = '&' then
            Value := Value + ReadReference
          else if S[P] = '<' then
            Fail('not well-formed (invalid token)')
          else
          begin
            // attribute-value normalization: literal whitespace becomes a space
            if CharInSet(S[P], [#9, #10]) then
              Value := Value + ' '
            else
              Value := Value + S[P];
            Advance;
          end;
        end;
        if AtEnd then
          Fail('unclosed token', Start);
        Advance; // quote
        if RawNames.IndexOf(Name) >= 0 then
          Fail('duplicate attribute', ValueStart);
        RawNames.Add(Name);
        RawValues.Add(Value);
        if Name = 'xmlns' then
          Scopes.Add(TPair<string, string>.Create('', Value))
        else if Name.StartsWith('xmlns:') then
          Scopes.Add(TPair<string, string>.Create(Name.Substring(6), Value));
      end;
      // Names, now that this element's declarations are in scope
      SplitQName(RawName, Prefix, Local);
      Result := TXmlElement.Create(Clark(Resolve(Prefix, Start), Local));
      Result.Line := StartLine;
      for I := 0 to RawNames.Count - 1 do
      begin
        if (RawNames[I] = 'xmlns') or RawNames[I].StartsWith('xmlns:') then
          Continue;
        if SplitQName(RawNames[I], Prefix, Local) then
          Uri := Resolve(Prefix, Start)
        else
          Uri := ''; // unprefixed attributes have no namespace
        Result.SetAttr(Clark(Uri, Local), RawValues[I]);
      end;
      if Peek('/>') then
      begin
        Advance(2);
        Exit;
      end;
      Advance; // >
      // Content
      Last := nil;
      Data := TStringBuilder.Create;
      try
        while True do
        begin
          if AtEnd then
            Fail('no element found');
          if Peek('</') then
          begin
            Flush;
            I := P;
            Advance(2);
            EndName := ReadName;
            SkipSpace;
            if AtEnd or (S[P] <> '>') or (EndName <> RawName) then
              Fail('mismatched tag', I + 2); // expat points at the end tag's name
            Advance;
            Break;
          end
          else if Peek('<!--') then
            SkipUntil('-->', 'unclosed token')
          else if Peek('<![CDATA[') then
          begin
            Advance(9);
            I := P;
            while not AtEnd and not Peek(']]>') do
              Advance;
            if AtEnd then
              Fail('unclosed CDATA section', I);
            Data.Append(Copy(S, I, P - I));
            Advance(3);
          end
          else if Peek('<?') then
            SkipUntil('?>', 'unclosed token')
          else if S[P] = '<' then
          begin
            Flush;
            Child := ParseElement;
            Result.Add(Child);
            Last := Child;
          end
          else if S[P] = '&' then
            Data.Append(ReadReference)
          else
          begin
            Data.Append(S[P]);
            Advance;
          end;
        end;
      finally
        Data.Free;
      end;
    except
      Result.Free;
      raise;
    end;
  finally
    RawValues.Free;
    RawNames.Free;
    Scopes.Count := ScopeCount; // this element's xmlns declarations go out of scope
  end;
end;

function TXmlParser.Parse: TXmlElement;
begin
  SkipMisc;
  if AtEnd then
    Fail('no element found');
  if S[P] <> '<' then
    Fail('syntax error');
  Result := ParseElement;
  try
    SkipMisc;
    if not AtEnd then
      Fail('junk after document element');
  except
    Result.Free;
    raise;
  end;
end;

function ParseXml(const AText: string): TXmlElement;
var
  Parser: TXmlParser;
begin
  Parser := TXmlParser.Create(AText);
  try
    Result := Parser.Parse;
  finally
    Parser.Free;
  end;
end;

function ReadXmlFile(const APath: string): string;
var
  Bytes: TBytes;
  Encoding: TEncoding;
  Skip: Integer;
begin
  Bytes := TFile.ReadAllBytes(APath);
  Encoding := nil;
  Skip := TEncoding.GetBufferEncoding(Bytes, Encoding, TEncoding.UTF8);
  Result := Encoding.GetString(Bytes, Skip, Length(Bytes) - Skip);
end;

{ Serializer }

function EscapeText(const AText: string): string;
begin
  Result := AText.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;');
end;

function EscapeAttribute(const AText: string): string;
begin
  Result := EscapeText(AText).Replace('"', '&quot;').Replace(#13, '&#13;').Replace(#10, '&#10;')
    .Replace(#9, '&#09;');
end;

function ToXml(AElement: TXmlElement; const ARegistered: array of TXmlPrefix): string;
var
  QNames: TDictionary<string, string>;
  Uris, Prefixes: TList<string>; // the namespaces used, in order of discovery
  Output: TStringBuilder;

  function Known(const AUri: string; out APrefix: string): Boolean;
  var
    I: Integer;
  begin
    for I := High(ARegistered) downto 0 do
      if ARegistered[I].Uri = AUri then
      begin
        APrefix := ARegistered[I].Prefix;
        Exit(True);
      end;
    Result := False;
  end;

  procedure AddQName(const AName: string);
  var
    Close, I: Integer;
    Uri, Local, Prefix: string;
  begin
    if QNames.ContainsKey(AName) then
      Exit;
    if not AName.StartsWith('{') then
    begin
      QNames.Add(AName, AName);
      Exit;
    end;
    Close := AName.LastIndexOf('}');
    Uri := AName.Substring(1, Close - 1);
    Local := AName.Substring(Close + 1);
    I := Uris.IndexOf(Uri);
    if I >= 0 then
      Prefix := Prefixes[I]
    else
    begin
      if not Known(Uri, Prefix) then
        Prefix := 'ns' + IntToStr(Uris.Count);
      if Prefix <> 'xml' then
      begin
        Uris.Add(Uri);
        Prefixes.Add(Prefix);
      end;
    end;
    if Prefix <> '' then
      QNames.Add(AName, Prefix + ':' + Local)
    else
      QNames.Add(AName, Local);
  end;

  procedure Write(E: TXmlElement; ARoot: Boolean);
  var
    I, J: Integer;
    Order: TArray<Integer>;
    Swap: Integer;
  begin
    Output.Append('<').Append(QNames[E.Tag]);
    if ARoot and (Uris.Count > 0) then
    begin
      // sorted on prefix
      SetLength(Order, Uris.Count);
      for I := 0 to High(Order) do
        Order[I] := I;
      for I := 1 to High(Order) do
      begin
        J := I;
        while (J > 0) and (CompareStr(Prefixes[Order[J - 1]], Prefixes[Order[J]]) > 0) do
        begin
          Swap := Order[J];
          Order[J] := Order[J - 1];
          Order[J - 1] := Swap;
          Dec(J);
        end;
      end;
      for I in Order do
        if Prefixes[I] = '' then
          Output.Append(' xmlns="').Append(EscapeAttribute(Uris[I])).Append('"')
        else
          Output.Append(' xmlns:').Append(Prefixes[I]).Append('="').Append(EscapeAttribute(Uris[I])).Append('"');
    end;
    for I := 0 to E.AttrCount - 1 do
      Output.Append(' ').Append(QNames[E.AttrName[I]]).Append('="').Append(EscapeAttribute(E.AttrValue[I])).Append('"');
    if (E.Text <> '') or (E.Count > 0) then
    begin
      Output.Append('>');
      Output.Append(EscapeText(E.Text));
      for I := 0 to E.Count - 1 do
        Write(E[I], False);
      Output.Append('</').Append(QNames[E.Tag]).Append('>');
    end
    else
      Output.Append(' />');
    Output.Append(EscapeText(E.Tail));
  end;

var
  E: TXmlElement;
  I: Integer;
begin
  QNames := TDictionary<string, string>.Create;
  Uris := TList<string>.Create;
  Prefixes := TList<string>.Create;
  Output := TStringBuilder.Create;
  try
    for E in AElement.Iter do
    begin
      AddQName(E.Tag);
      for I := 0 to E.AttrCount - 1 do
        AddQName(E.AttrName[I]);
    end;
    Write(AElement, True);
    Result := Output.ToString;
  finally
    Output.Free;
    Prefixes.Free;
    Uris.Free;
    QNames.Free;
  end;
end;

end.
