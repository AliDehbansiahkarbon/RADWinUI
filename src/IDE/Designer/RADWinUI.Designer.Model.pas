unit RADWinUI.Designer.Model;

{
  What the property grid shows and does, without ToolsAPI or WinUI,
  so tests\Designer\DesignerModelTest checks it outside the IDE:

  - properties and events of a XAML element, from RADWinUI.Xaml.json and, for
    RADWinUI's own controls (rw:GlowTile), RADWinUI.Controls.json;
  - the selection the preview reports (RADWinUI.Preview.Client.TakeEvent);
  - the smallest replacement turning one text into another, so the IDE edits
    its buffer with one undoable change instead of rewriting it;
  - event handlers in the window unit: find one, or add a published method
    and its empty body, the way the Object Inspector does.
}

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TDesignerProperty = record
    Name: string;
    /// <summary>string, object, bool, int, number, brush, text or enum:A|B|... (WinMDGen)</summary>
    Kind: string;
    function EnumValues: TArray<string>;
  end;

  TDesignerEvent = record
    Name: string;
    /// <summary>The handler's args class, for (Sender: TObject; E: ArgsType).</summary>
    ArgsType: string;
  end;

  /// <summary>The element the user selected in the preview.</summary>
  TDesignerSelection = record
    Line, Column: Integer;
    Tag: string;
    /// <summary>x:Name, or '' when the element has none.</summary>
    Name: string;
    /// <summary>'SELECTED 8 9 Button IncrementButton' or 'SELECTED 9 9 Button -', as the preview reports it.</summary>
    class function Parse(const AText: string; out ASelection: TDesignerSelection): Boolean; static;
  end;

  /// <summary>RADWinUI.Xaml.json: XAML tags, their classes, properties and events.</summary>
  TDesignerTypeIndex = class
  strict private
    FTypes: TDictionary<string, string>;
    FBases: TDictionary<string, string>;
    FProps: TObjectDictionary<string, TList<TDesignerProperty>>;
    FEvents: TObjectDictionary<string, TList<TDesignerEvent>>;
    function Chain(const ATag: string): TArray<string>;
    procedure Load(const AJsonFile, APrefix: string);
  public
    /// <summary>
    ///   Reads AJsonFile (src\Generated\RADWinUI.Xaml.json) and, when it exists,
    ///   src\Framework\RADWinUI.Controls.json next to it. Those tags are known with
    ///   and without their rw: prefix.
    /// </summary>
    constructor Create(const AJsonFile: string);
    destructor Destroy; override;
    /// <summary>Settable properties of ATag and its bases: common ones first, then by name.</summary>
    function PropertiesOf(const ATag: string): TArray<TDesignerProperty>;
    /// <summary>Events of ATag and its bases, by name.</summary>
    function EventsOf(const ATag: string): TArray<TDesignerEvent>;
    /// <summary>The event opened by a double click on a designer control.</summary>
    function DefaultEventOf(const ATag: string): string;
    function IsVisual(const ATag: string): Boolean;
  end;

  /// <summary>Replace ALength characters at AStart (0-based) with AText.</summary>
  TTextChange = record
    Start, Length: Integer;
    Text: string;
  end;

/// <summary>The one replacement that turns AOld into ANew (common prefix and suffix kept).</summary>
function TextChange(AOld, ANew: string): TTextChange;
/// <summary>Bytes of the UTF-8 form of the first ACount characters of AText (editor buffer offsets).</summary>
function Utf8Offset(const AText: string; ACount: Integer): Integer;
/// <summary>The x:Class of the <Window> root (TMainWindow), or ''.</summary>
function WindowClass(const AXaml: string): string;
/// <summary>The XAML attribute of property AProperty: x:Name for Name, else AProperty.</summary>
function AttributeOf(const AProperty: string): string;
/// <summary>The 1-based line of 'procedure AClass.AMethod' in APas, or 0.</summary>
function FindHandler(const APas, AClass, AMethod: string): Integer;
/// <summary>
///   APas with a published (Sender: TObject; E: AArgsType) method AMethod in
///   class AClass and its empty body before the final 'end.'. ALine returns the
///   empty line inside the body, for the cursor. Raises when AClass is missing.
/// </summary>
function AddHandler(APas: string; const AClass, AMethod, AArgsType: string; out ALine: Integer): string;
/// <summary>Remove bound, whitespace-only event methods and their XAML assignments.
/// Comments, directives and methods referenced elsewhere in Pascal are preserved.</summary>
function CleanupEmptyHandlers(var AXaml, APas: string; AIndex: TDesignerTypeIndex): Boolean;

implementation

uses
  System.Math,
  System.IOUtils,
  System.JSON,
  System.RegularExpressions,
  System.Classes,
  RADWinUI.Designer.XamlEdit,
  System.Generics.Defaults;

const
  // Shown first, in this order, when the element has them
  Common: array[0..22] of string = ('Name', 'Align', 'Text', 'Content', 'Header', 'PlaceholderText', 'IsChecked',
    'IsEnabled', 'Visibility', 'Width', 'Height', 'MinWidth', 'MinHeight', 'Margin', 'Padding',
    'HorizontalAlignment', 'VerticalAlignment', 'Orientation', 'Spacing', 'FontSize', 'Foreground',
    'Background', 'Opacity');

{ TDesignerProperty }

function TDesignerProperty.EnumValues: TArray<string>;
begin
  if Kind.StartsWith('enum:') then
    Result := Kind.Substring(5).Split(['|'])
  else
    Result := nil;
end;

{ TDesignerSelection }

class function TDesignerSelection.Parse(const AText: string; out ASelection: TDesignerSelection): Boolean;
var
  Parts: TArray<string>;
begin
  Parts := AText.Split([' ']);
  Result := (Length(Parts) = 5) and (Parts[0] = 'SELECTED') and TryStrToInt(Parts[1], ASelection.Line) and
    TryStrToInt(Parts[2], ASelection.Column);
  if not Result then
    Exit;
  ASelection.Tag := Parts[3];
  ASelection.Name := Parts[4];
  if ASelection.Name = '-' then
    ASelection.Name := '';
end;

{ TDesignerTypeIndex }

constructor TDesignerTypeIndex.Create(const AJsonFile: string);
var
  Own: string;
begin
  inherited Create;
  FTypes := TDictionary<string, string>.Create;
  FBases := TDictionary<string, string>.Create;
  FProps := TObjectDictionary<string, TList<TDesignerProperty>>.Create([doOwnsValues]);
  FEvents := TObjectDictionary<string, TList<TDesignerEvent>>.Create([doOwnsValues]);
  Load(AJsonFile, '');
  // src\Generated\RADWinUI.Xaml.json -> src\Framework\RADWinUI.Controls.json
  Own := TPath.Combine(ExtractFileDir(ExtractFileDir(TPath.GetFullPath(AJsonFile))), 'Framework\RADWinUI.Controls.json');
  if FileExists(Own) then
    Load(Own, 'rw');
end;

procedure TDesignerTypeIndex.Load(const AJsonFile, APrefix: string);
var
  Json: TJSONObject;
  Pair, Item: TJSONPair;
  Info: TJSONObject;
  Prop: TDesignerProperty;
  Event: TDesignerEvent;
begin
  Json := TJSONObject.ParseJSONValue(TFile.ReadAllText(AJsonFile, TEncoding.UTF8)) as TJSONObject;
  try
    // Pairs are read by name: GetValue<T>('a.b') would read the dots as a path
    for Pair in Json.GetValue('types') as TJSONObject do
    begin
      FTypes.AddOrSetValue(Pair.JsonString.Value, Pair.JsonValue.Value);
      if APrefix <> '' then
        FTypes.AddOrSetValue(APrefix + ':' + Pair.JsonString.Value, Pair.JsonValue.Value);
    end;
    for Pair in Json.GetValue('classes') as TJSONObject do
    begin
      Info := Pair.JsonValue as TJSONObject;
      FBases.Add(Pair.JsonString.Value, Info.GetValue('base').Value);
      FProps.Add(Pair.JsonString.Value, TList<TDesignerProperty>.Create);
      if Info.GetValue('props') is TJSONObject then
        for Item in Info.GetValue('props') as TJSONObject do
        begin
          Prop.Name := Item.JsonString.Value;
          Prop.Kind := Item.JsonValue.Value;
          FProps[Pair.JsonString.Value].Add(Prop);
        end;
      FEvents.Add(Pair.JsonString.Value, TList<TDesignerEvent>.Create);
      for Item in Info.GetValue('events') as TJSONObject do
      begin
        Event.Name := Item.JsonString.Value;
        Event.ArgsType := (Item.JsonValue as TJSONArray).Items[1].Value;
        FEvents[Pair.JsonString.Value].Add(Event);
      end;
    end;
  finally
    Json.Free;
  end;
end;

destructor TDesignerTypeIndex.Destroy;
begin
  FTypes.Free;
  FBases.Free;
  FProps.Free;
  FEvents.Free;
  inherited;
end;

function TDesignerTypeIndex.Chain(const ATag: string): TArray<string>;
var
  Cls: string;
begin
  Result := nil;
  if not FTypes.TryGetValue(ATag, Cls) then
    Exit;
  while (Cls <> '') and FBases.ContainsKey(Cls) do
  begin
    Result := Result + [Cls];
    Cls := FBases[Cls];
  end;
end;

function TDesignerTypeIndex.PropertiesOf(const ATag: string): TArray<TDesignerProperty>;
var
  Cls, Name: string;
  Prop: TDesignerProperty;
  Seen: TDictionary<string, TDesignerProperty>;
  Rest: TList<TDesignerProperty>;
begin
  Result := nil;
  Seen := TDictionary<string, TDesignerProperty>.Create;
  Rest := TList<TDesignerProperty>.Create;
  try
    for Cls in Chain(ATag) do
      for Prop in FProps[Cls] do
        if not Seen.ContainsKey(Prop.Name) then
          Seen.Add(Prop.Name, Prop);
    if Seen.ContainsKey('HorizontalAlignment') and Seen.ContainsKey('VerticalAlignment') then
    begin
      Prop.Name := 'Align';
      Prop.Kind := 'enum:alNone|alTop|alBottom|alLeft|alRight|alClient';
      Seen.Add(Prop.Name, Prop);
    end;
    for Name in Common do
      if Seen.TryGetValue(Name, Prop) then
      begin
        Result := Result + [Prop];
        Seen.Remove(Name);
      end;
    Rest.AddRange(Seen.Values);
    Rest.Sort(TComparer<TDesignerProperty>.Construct(
      function(const A, B: TDesignerProperty): Integer
      begin
        Result := CompareText(A.Name, B.Name);
      end));
    Result := Result + Rest.ToArray;
  finally
    Rest.Free;
    Seen.Free;
  end;
end;

function TDesignerTypeIndex.EventsOf(const ATag: string): TArray<TDesignerEvent>;
var
  Cls: string;
  Event: TDesignerEvent;
  List: TList<TDesignerEvent>;
  Seen: TDictionary<string, Boolean>;
begin
  List := TList<TDesignerEvent>.Create;
  Seen := TDictionary<string, Boolean>.Create;
  try
    for Cls in Chain(ATag) do
      for Event in FEvents[Cls] do
        if not Seen.ContainsKey(Event.Name) then
        begin
          Seen.Add(Event.Name, True);
          List.Add(Event);
        end;
    List.Sort(TComparer<TDesignerEvent>.Construct(
      function(const A, B: TDesignerEvent): Integer
      begin
        Result := CompareText(A.Name, B.Name);
      end));
    Result := List.ToArray;
  finally
    Seen.Free;
    List.Free;
  end;
end;

function TDesignerTypeIndex.IsVisual(const ATag: string): Boolean;
var
  Cls: string;
begin
  if ATag = 'Window' then
    Exit(True);
  for Cls in Chain(ATag) do
    if Cls = 'Microsoft.UI.Xaml.UIElement' then
      Exit(True);
  Result := False;
end;

function TDesignerTypeIndex.DefaultEventOf(const ATag: string): string;
var
  Preferred: string;
  Event: TDesignerEvent;
  Events: TArray<TDesignerEvent>;
begin
  Events := EventsOf(ATag);
  for Preferred in ['Click', 'SelectionChanged', 'TextChanged', 'ColorChanged',
    'ValueChanged', 'Toggled', 'DateChanged', 'TimeChanged', 'DoubleTapped'] do
    for Event in Events do
      if Event.Name = Preferred then
        Exit(Preferred);
  Result := '';
end;

function TextChange(AOld, ANew: string): TTextChange;
var
  Prefix, Suffix, Max: Integer;
begin
  Prefix := 0;
  Max := Min(Length(AOld), Length(ANew));
  while (Prefix < Max) and (AOld[Prefix + 1] = ANew[Prefix + 1]) do
    Inc(Prefix);
  Suffix := 0;
  while (Suffix < Max - Prefix) and (AOld[Length(AOld) - Suffix] = ANew[Length(ANew) - Suffix]) do
    Inc(Suffix);
  Result.Start := Prefix;
  Result.Length := Length(AOld) - Prefix - Suffix;
  Result.Text := Copy(ANew, Prefix + 1, Length(ANew) - Prefix - Suffix);
end;

function Utf8Offset(const AText: string; ACount: Integer): Integer;
begin
  Result := TEncoding.UTF8.GetByteCount(Copy(AText, 1, ACount));
end;

function AttributeOf(const AProperty: string): string;
begin
  if AProperty = 'Name' then
    Result := 'x:Name'
  else
    Result := AProperty;
end;

function WindowClass(const AXaml: string): string;
begin
  Result := TRegEx.Match(AXaml, '<Window\b[^>]*?\sx:Class\s*=\s*"([A-Za-z_]\w*)"').Groups[1].Value;
end;

/// 1-based line of the character at 0-based AIndex.
function LineAt(const AText: string; AIndex: Integer): Integer;
var
  I: Integer;
begin
  Result := 1;
  for I := 1 to AIndex do
    if AText[I] = #10 then
      Inc(Result);
end;

function FindHandler(const APas, AClass, AMethod: string): Integer;
var
  M: TMatch;
begin
  M := TRegEx.Match(APas, '^\s*procedure\s+' + AClass + '\.' + AMethod + '\s*[(;]',
    [roIgnoreCase, roMultiLine]);
  if M.Success then
    Result := LineAt(APas, M.Index - 1 + M.Length - Length(M.Value.TrimLeft))
  else
    Result := 0;
end;

function AddHandler(APas: string; const AClass, AMethod, AArgsType: string; out ALine: Integer): string;
var
  Decl, Published, Final: TMatch;
  Signature, Body: string;
  At: Integer;
begin
  Signature := '(Sender: TObject; E: ' + AArgsType + ');';
  // The class declaration, up to its 'end;'
  Decl := TRegEx.Match(APas, '\b' + AClass + '\s*=\s*class\b(?:\([^)]*\))?(.*?)^\s*end\s*;',
    [roIgnoreCase, roSingleLine, roMultiLine]);
  if not Decl.Success then
    raise Exception.CreateFmt('Class %s not found in the unit', [AClass]);
  Published := TRegEx.Match(Decl.Groups[1].Value, '^(\s*)published\b[^\r\n]*\r?\n', [roIgnoreCase, roMultiLine]);
  if Published.Success then
  begin
    // First line of the published section
    At := Decl.Groups[1].Index - 1 + Published.Index - 1 + Published.Length;
    Result := APas.Insert(At, Published.Groups[1].Value.Replace(#13, '').Replace(#10, '') + '  procedure ' +
      AMethod + Signature + sLineBreak);
  end
  else
  begin
    // A new published section just before the class's 'end;'
    At := Decl.Index - 1 + Decl.Length;
    while (At > 0) and (APas[At] <> #10) do
      Dec(At);
    Result := APas.Insert(At, '  published' + sLineBreak + '    procedure ' + AMethod + Signature + sLineBreak);
  end;
  Final := TRegEx.Match(Result, '^end\s*\.', [roIgnoreCase, roMultiLine]);
  if not Final.Success then
    raise Exception.Create('The unit has no final ''end.''');
  Body := 'procedure ' + AClass + '.' + AMethod + Signature + sLineBreak + 'begin' + sLineBreak + sLineBreak +
    'end;' + sLineBreak + sLineBreak;
  Result := Result.Insert(Final.Index - 1, Body);
  ALine := LineAt(Result, Final.Index - 1) + 2;
end;

function CleanupEmptyHandlers(var AXaml, APas: string; AIndex: TDesignerTypeIndex): Boolean;
var
  Elements: TArray<TXamlElement>;
  Element: TXamlElement;
  Event: TDesignerEvent;
  Methods, Names, Removed: TStringList;
  Cls, Name, Candidate, UpdatedXaml, UpdatedPas: string;
  Decl, MethodDecl, Body, Match: TMatch;
  I, At: Integer;
begin
  Result := False;
  Cls := WindowClass(AXaml);
  if Cls = '' then Exit;
  Elements := XamlElements(AXaml);
  Methods := TStringList.Create;
  Names := TStringList.Create;
  Removed := TStringList.Create;
  try
    Methods.Sorted := True;
    Methods.Duplicates := dupIgnore;
    for Match in TRegEx.Matches(APas, '^[ \t]*procedure\s+' + TRegEx.Escape(Cls) +
      '\.([A-Za-z_]\w*)\b', [roIgnoreCase, roMultiLine]) do
      Methods.Add(Match.Groups[1].Value);
    if Methods.Count = 0 then Exit;
    Names.Sorted := True;
    Names.Duplicates := dupIgnore;
    Removed.Sorted := True;
    for Element in Elements do
    begin
      if Element.DesignOnly then Continue;
      for Event in AIndex.EventsOf(Element.Tag) do
      begin
        Name := '';
        if not GetAttribute(AXaml, Element.Line, Element.Column, Event.Name, Name) and
          (Element.Name <> '') then Name := Element.Name + Event.Name;
        if IsValidIdent(Name) and (Methods.IndexOf(Name) >= 0) then Names.Add(Name);
      end;
    end;
    UpdatedPas := APas;
    for Name in Names do
    begin
      Decl := TRegEx.Match(UpdatedPas, '\b' + TRegEx.Escape(Cls) +
        '\s*=\s*class\b(?:\([^)]*\))?(.*?)^\s*end\s*;',
        [roIgnoreCase, roSingleLine, roMultiLine]);
      if not Decl.Success then Continue;
      MethodDecl := TRegEx.Match(Decl.Groups[1].Value, '^[ \t]*procedure\s+' +
        TRegEx.Escape(Name) + '\s*\([^)]*\)\s*;[ \t]*\r?\n', [roIgnoreCase, roMultiLine]);
      Body := TRegEx.Match(UpdatedPas, '^[ \t]*procedure\s+' + TRegEx.Escape(Cls) + '\.' +
        TRegEx.Escape(Name) + '\s*\([^)]*\)\s*;\s*begin\s*end\s*;[ \t]*(?:\r?\n){0,2}',
        [roIgnoreCase, roMultiLine]);
      if not MethodDecl.Success or not Body.Success then Continue;
      At := Decl.Groups[1].Index - 1 + MethodDecl.Index - 1;
      if Body.Index - 1 <= At then Continue;
      Candidate := UpdatedPas.Remove(Body.Index - 1, Body.Length).Remove(At, MethodDecl.Length);
      // An empty event can still be used explicitly in application code.
      if TRegEx.IsMatch(Candidate, '\b' + TRegEx.Escape(Name) + '\b', [roIgnoreCase]) then Continue;
      UpdatedPas := Candidate;
      Removed.Add(Name);
    end;
    if Removed.Count = 0 then Exit;
    UpdatedXaml := AXaml;
    // Work backwards so removing multiline attributes preserves earlier positions.
    for I := High(Elements) downto 0 do
    begin
      if Elements[I].DesignOnly then Continue;
      for Event in AIndex.EventsOf(Elements[I].Tag) do
        if GetAttribute(UpdatedXaml, Elements[I].Line, Elements[I].Column, Event.Name, Name) and
          (Removed.IndexOf(Name) >= 0) then
          UpdatedXaml := RemoveAttribute(UpdatedXaml, Elements[I].Line, Elements[I].Column, Event.Name);
    end;
    AXaml := UpdatedXaml;
    APas := UpdatedPas;
    Result := True;
  finally
    Removed.Free;
    Names.Free;
    Methods.Free;
  end;
end;

end.
