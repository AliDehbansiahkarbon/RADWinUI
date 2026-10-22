unit RADWinUI.Designer.XamlEdit;

{
  Minimal edits of XAML text for the designer. XAML text stays
  the source of truth: the property grid changes one attribute of one start
  tag and leaves every other character as it was (formatting, comments,
  attribute order). Elements are named by the position of their '<' as the
  preview reports it: 1-based line and column, columns in UTF-16 characters.
  No ToolsAPI and no WinUI, tests\Designer\XamlEditTest checks it.

  Structure edits insert, move and delete whole elements: a
  new child goes on its own line with the indentation of its siblings, and
  an element alone on its lines takes those lines with it when it goes.
  ApplyDesignerEvent turns an INSERT, MOVE or DELETE the preview reports
  into one of them, for the IDE and for the tests alike.
}

interface

uses
  System.SysUtils;

type
  EXamlEdit = class(Exception);

  TXamlElement = record
    Tag, Name: string;
    ParentIndex, Line, Column, Start, Stop, TagEnd: Integer;
    DesignOnly: Boolean;
  end;

/// <summary>Source hierarchy, including property elements, positions are UTF-16 and 1-based.</summary>
function XamlElements(const AXaml: string): TArray<TXamlElement>;
/// <summary>The document root and a Window's required content cannot be deleted.</summary>
function CanDeleteElement(const AXaml: string; ALine, ACol: Integer): Boolean;
/// <summary>VCL-style Align derived from native WinUI alignment properties.</summary>
function AlignOf(const AXaml: string; ALine, ACol: Integer): string;
/// <summary>Align a Grid child, writing native Grid tracks and attached properties.</summary>
function SetAlign(AXaml: string; ALine, ACol: Integer; const AAlign: string): string;

/// <summary>
///   AXaml with attribute AName of the start tag at ALine:ACol set to AValue:
///   the value is replaced in place (same quote style), or the attribute is
///   added after the last one (on its own line, aligned, when the tag spans lines).
/// </summary>
function SetAttribute(AXaml: string; ALine, ACol: Integer; const AName, AValue: string): string;
/// <summary>AXaml without attribute AName of the start tag at ALine:ACol (unchanged when absent).</summary>
function RemoveAttribute(AXaml: string; ALine, ACol: Integer; const AName: string): string;
/// <summary>The value of attribute AName of the start tag at ALine:ACol, unescaped, False when absent.</summary>
function GetAttribute(const AXaml: string; ALine, ACol: Integer; const AName: string; out AValue: string): Boolean;

/// <summary>AXaml without the element whose start tag is at ALine:ACol.</summary>
function DeleteElement(AXaml: string; ALine, ACol: Integer): string;
/// <summary>The selected element as clipboard XAML, without changing its content.</summary>
function CopyElement(const AXaml: string; ALine, ACol: Integer): string;
/// <summary>
///   Paste one clipboard element into a selected Grid, StackPanel or Canvas,
///   or after another selected control. Gives named elements fresh unique names.
/// </summary>
function PasteElement(AXaml: string; ALine, ACol: Integer; const ASnippet: string): string;
/// <summary>
///   AXaml with AElement as child number AIndex (0-based, past the end appends)
///   of the panel whose start tag is at APanelLine:APanelCol.
/// </summary>
function InsertChild(AXaml: string; APanelLine, APanelCol, AIndex: Integer; const AElement: string): string;
/// <summary>
///   AXaml with the element at ALine:ACol moved to child AIndex of the panel at
///   APanelLine:APanelCol (AIndex counts the element where it is now). ARow and
///   AColumn set Grid.Row and Grid.Column, -1 removes them (not a Grid).
/// </summary>
function MoveElement(AXaml: string; ALine, ACol, APanelLine, APanelCol, AIndex, ARow, AColumn: Integer): string;
/// <summary>The XAML a toolbox item inserts. Common controls get a starter value, other valid XAML names are empty.</summary>
function ToolboxXaml(const ATag: string; ARow, AColumn: Integer): string;
/// <summary>A unique Pascal-compatible component name, such as Button1.</summary>
function NewElementName(const AXaml, ATag: string): string;
/// <summary>
///   AXaml after one structure event of the preview (RADWinUI.Preview.Host):
///   INSERT <tag> <panel line> <panel column> <index> <row> <column>,
///   MOVE <line> <column> <panel line> <panel column> <index> <row> <column>,
///   DELETE <line> <column>, and free placement:
///   PLACE <line> <column> <panel line> <panel column> Grid|Canvas <row> <column> <left> <top>,
///   INSERTAT <tag> <panel line> <panel column> Grid|Canvas <row> <column> <left> <top>.
///   Raises EXamlEdit for anything else.
/// </summary>
function ApplyDesignerEvent(AXaml: string; const AEvent: string): string;
/// <summary>
///   AXaml with the element at ALine:ACol placed at ALeft, ATop (DIPs) in the
///   panel at APanelLine:APanelCol: in a Grid, Margin with HorizontalAlignment
///   and VerticalAlignment Left/Top in cell ARow, AColumn, in a Canvas,
///   Canvas.Left and Canvas.Top. An element of another panel moves into it.
/// </summary>
function PlaceElement(AXaml: string; ALine, ACol, APanelLine, APanelCol: Integer; const AKind: string;
  ARow, AColumn, ALeft, ATop: Integer): string;

implementation

uses
  System.Classes,
  System.StrUtils,
  System.Math,
  System.RegularExpressions;

const
  AttributePattern = '(\s+)([\w.:]+)(\s*=\s*)("[^"]*"|''[^'']*'')';

/// 1-based index of the character at ALine:ACol.
function IndexOf(const AXaml: string; ALine, ACol: Integer): Integer;
var
  Line: Integer;
begin
  Result := 1;
  Line := 1;
  while (Line < ALine) and (Result <= Length(AXaml)) do
  begin
    if AXaml[Result] = #10 then
      Inc(Line);
    Inc(Result);
  end;
  Result := Result + ACol - 1;
end;

/// The start tag at ALine:ACol.
function TagAt(const AXaml: string; ALine, ACol: Integer): TMatch;
var
  Start: Integer;
begin
  Start := IndexOf(AXaml, ALine, ACol);
  if (Start < 1) or (Start > Length(AXaml)) or (AXaml[Start] <> '<') then
    raise EXamlEdit.CreateFmt('No start tag at line %d, column %d', [ALine, ACol]);
  Result := TRegEx.Match(AXaml.Substring(Start - 1), '^<[A-Za-z_][\w:.]*(?:' + AttributePattern + ')*\s*/?>');
  if not Result.Success then
    raise EXamlEdit.CreateFmt('No well-formed start tag at line %d, column %d', [ALine, ACol]);
end;

function Escape(const AValue: string; AQuote: Char): string;
begin
  Result := AValue.Replace('&', '&amp;').Replace('<', '&lt;');
  if AQuote = '"' then
    Result := Result.Replace('"', '&quot;')
  else
    Result := Result.Replace('''', '&apos;');
end;

function Unescape(const AValue: string): string;
begin
  Result := AValue.Replace('&lt;', '<').Replace('&gt;', '>').Replace('&quot;', '"').Replace('&apos;', '''')
    .Replace('&amp;', '&');
end;

/// The attribute AName in ATag, False when absent.
function FindAttribute(const ATag, AName: string; out AMatch: TMatch): Boolean;
var
  Matches: TMatchCollection;
  I: Integer;
begin
  Matches := TRegEx.Matches(ATag, AttributePattern);
  for I := 0 to Matches.Count - 1 do
    if Matches[I].Groups[2].Value = AName then
    begin
      AMatch := Matches[I];
      Exit(True);
    end;
  Result := False;
end;

function SetAttribute(AXaml: string; ALine, ACol: Integer; const AName, AValue: string): string;
var
  Tag, Last: TMatch;
  Matches: TMatchCollection;
  Start, At, I: Integer;
  Text, Indent: string;
  Quote: Char;
begin
  if not TRegEx.IsMatch(AName, '^[A-Za-z_][\w.:]*$') then
    raise EXamlEdit.CreateFmt('"%s" is not an attribute name', [AName]);
  Tag := TagAt(AXaml, ALine, ACol);
  Start := IndexOf(AXaml, ALine, ACol);
  Text := Tag.Value;
  if FindAttribute(Text, AName, Last) then
  begin
    Quote := Last.Groups[4].Value[1];
    Text := Text.Substring(0, Last.Groups[4].Index - 1) + Quote + Escape(AValue, Quote) + Quote +
      Text.Substring(Last.Groups[4].Index - 1 + Last.Groups[4].Length);
  end
  else
  begin
    // After the last attribute (or the tag name), in the tag's own layout
    At := TRegEx.Match(Text, '^<[A-Za-z_][\w:.]*').Length;
    Indent := ' ';
    Matches := TRegEx.Matches(Text, AttributePattern);
    for I := 0 to Matches.Count - 1 do
    begin
      At := Matches[I].Index - 1 + Matches[I].Length;
      if Matches[I].Groups[1].Value.Contains(#10) then
        Indent := Matches[I].Groups[1].Value;
    end;
    Text := Text.Substring(0, At) + Indent + AName + '="' + Escape(AValue, '"') + '"' + Text.Substring(At);
  end;
  Result := AXaml.Substring(0, Start - 1) + Text + AXaml.Substring(Start - 1 + Tag.Length);
end;

function RemoveAttribute(AXaml: string; ALine, ACol: Integer; const AName: string): string;
var
  Tag, Attribute: TMatch;
  Start: Integer;
  Text: string;
begin
  Tag := TagAt(AXaml, ALine, ACol);
  Start := IndexOf(AXaml, ALine, ACol);
  if not FindAttribute(Tag.Value, AName, Attribute) then
    Exit(AXaml);
  Text := Tag.Value.Remove(Attribute.Index - 1, Attribute.Length);
  Result := AXaml.Substring(0, Start - 1) + Text + AXaml.Substring(Start - 1 + Tag.Length);
end;

function GetAttribute(const AXaml: string; ALine, ACol: Integer; const AName: string; out AValue: string): Boolean;
var
  Attribute: TMatch;
begin
  Result := FindAttribute(TagAt(AXaml, ALine, ACol).Value, AName, Attribute);
  if Result then
    AValue := Unescape(Attribute.Groups[4].Value.Substring(1, Attribute.Groups[4].Length - 2))
  else
    AValue := '';
end;

const
  TagPattern = '<!--.*?-->|<(/?)([A-Za-z_][\w:.]*)(?:\s+[\w.:]+\s*=\s*(?:"[^"]*"|''[^'']*''))*\s*(/?)>';

type
  TRange = record
    Start, Stop: Integer; // 1-based, Stop is just after the element
  end;

function XamlElements(const AXaml: string): TArray<TXamlElement>;
var
  Match, Attribute: TMatch;
  Matches: TMatchCollection;
  Stack: TArray<Integer>;
  Element: TXamlElement;
  At, Line, Col, N: Integer;
begin
  Result := nil;
  At := 1;
  Line := 1;
  Col := 1;
  N := 0;
  Matches := TRegEx.Matches(AXaml, '<!\[CDATA\[.*?\]\]>|<\?.*?\?>|' + TagPattern, [roSingleLine]);
  SetLength(Result, Matches.Count);
  for Match in Matches do
  begin
    while At < Match.Index do
    begin
      if AXaml[At] = #10 then
      begin
        Inc(Line);
        Col := 1;
      end
      else
        Inc(Col);
      Inc(At);
    end;
    if Match.Value.StartsWith('<!') or Match.Value.StartsWith('<?') then
      Continue;
    if Match.Groups[1].Value = '/' then
    begin
      if (Length(Stack) = 0) or (Result[Stack[High(Stack)]].Tag <> Match.Groups[2].Value) then
        raise EXamlEdit.Create('Mismatched XAML end tag');
      Result[Stack[High(Stack)]].Stop := Match.Index + Match.Length;
      SetLength(Stack, Length(Stack) - 1);
      Continue;
    end;
    Element := Default(TXamlElement);
    Element.Tag := Match.Groups[2].Value;
    Element.ParentIndex := -1;
    if Length(Stack) > 0 then
      Element.ParentIndex := Stack[High(Stack)];
    Element.DesignOnly := Element.Tag.StartsWith('d:') or
      ((Element.ParentIndex >= 0) and Result[Element.ParentIndex].DesignOnly);
    Element.Line := Line;
    Element.Column := Col;
    Element.Start := Match.Index;
    Element.TagEnd := Match.Index + Match.Length;
    Element.Stop := Element.TagEnd;
    if FindAttribute(Match.Value, 'x:Name', Attribute) or FindAttribute(Match.Value, 'Name', Attribute) or
      ((Element.Tag = 'Window') and FindAttribute(Match.Value, 'x:Class', Attribute)) then
      Element.Name := Unescape(Attribute.Groups[4].Value.Substring(1, Attribute.Groups[4].Length - 2));
    Result[N] := Element;
    if Match.Groups[3].Value <> '/' then
      Stack := Stack + [N];
    Inc(N);
  end;
  if Length(Stack) <> 0 then
    raise EXamlEdit.Create('The XAML has an unfinished element');
  SetLength(Result, N);
end;

function CanDeleteElement(const AXaml: string; ALine, ACol: Integer): Boolean;
var
  Elements: TArray<TXamlElement>;
  Element: TXamlElement;
begin
  Elements := XamlElements(AXaml);
  for Element in Elements do
    if (Element.Line = ALine) and (Element.Column = ACol) then
      Exit((Element.ParentIndex >= 0) and (Elements[Element.ParentIndex].Tag <> 'Window'));
  Result := False;
end;

function AlignOf(const AXaml: string; ALine, ACol: Integer): string;
var
  H, V: string;
begin
  Result := 'alNone';
  GetAttribute(AXaml, ALine, ACol, 'HorizontalAlignment', H);
  GetAttribute(AXaml, ALine, ACol, 'VerticalAlignment', V);
  if (H = '') and (V = '') then
    Exit;
  if H = '' then H := 'Stretch';
  if V = '' then V := 'Stretch';
  if H = 'Stretch' then
  begin
    if V = 'Top' then Result := 'alTop'
    else if V = 'Bottom' then Result := 'alBottom'
    else if V = 'Stretch' then Result := 'alClient';
  end
  else if V = 'Stretch' then
  begin
    if H = 'Left' then Result := 'alLeft'
    else if H = 'Right' then Result := 'alRight';
  end;
end;

/// The element whose start tag begins at AStart.
function ElementAt(const AXaml: string; AStart: Integer): TRange;
var
  M: TMatch;
  Depth: Integer;
begin
  if (AStart < 1) or (AStart > Length(AXaml)) or (AXaml[AStart] <> '<') then
    raise EXamlEdit.Create('No element there');
  Depth := 0;
  for M in TRegEx.Matches(AXaml.Substring(AStart - 1), TagPattern, [roSingleLine]) do
  begin
    if M.Value.StartsWith('<!--') then
      Continue;
    if M.Groups[1].Value = '/' then
      Dec(Depth)
    else if M.Groups[3].Value <> '/' then
      Inc(Depth);
    if Depth = 0 then
    begin
      Result.Start := AStart;
      Result.Stop := AStart + M.Index - 1 + M.Length;
      Exit;
    end;
  end;
  raise EXamlEdit.Create('The element has no end tag');
end;

/// The child elements of the element at APanel (property elements such as
/// Grid.RowDefinitions do not count), AContentEnd returns the '<' of its end tag,
/// or 0 when the panel is self-closing.
function ChildrenOf(const AXaml: string; APanel: Integer; out AContentEnd: Integer): TArray<TRange>;
var
  Panel, Child: TRange;
  M: TMatch;
  At: Integer;
begin
  Result := nil;
  Panel := ElementAt(AXaml, APanel);
  M := TRegEx.Match(AXaml.Substring(APanel - 1), TagPattern, [roSingleLine]);
  if M.Groups[3].Value = '/' then
  begin
    AContentEnd := 0;
    Exit;
  end;
  AContentEnd := AXaml.LastIndexOf('<', Panel.Stop - 2) + 1; // 0-based search from the '>'
  At := APanel + M.Length;
  while At < AContentEnd do
  begin
    M := TRegEx.Match(AXaml.Substring(At - 1), TagPattern, [roSingleLine]);
    if not M.Success or (At + M.Index - 1 >= AContentEnd) then
      Break;
    At := At + M.Index - 1;
    if M.Value.StartsWith('<!--') then
    begin
      Inc(At, M.Length);
      Continue;
    end;
    Child := ElementAt(AXaml, At);
    if not M.Groups[2].Value.Contains('.') then
      Result := Result + [Child];
    At := Child.Stop;
  end;
end;

function LineStart(const AXaml: string; AIndex: Integer): Integer;
begin
  Result := AIndex;
  while (Result > 1) and (AXaml[Result - 1] <> #10) do
    Dec(Result);
end;

/// The white space between the start of its line and AIndex ('' when there is other text).
function IndentAt(const AXaml: string; AIndex: Integer): string;
begin
  Result := Copy(AXaml, LineStart(AXaml, AIndex), AIndex - LineStart(AXaml, AIndex));
  if Result.Trim <> '' then
    Result := '';
end;

/// Nothing but white space before AIndex on its line.
function OwnLine(const AXaml: string; AIndex: Integer): Boolean;
begin
  Result := Copy(AXaml, LineStart(AXaml, AIndex), AIndex - LineStart(AXaml, AIndex)).Trim = '';
end;

function LineBreak(const AXaml: string): string;
begin
  if AXaml.Contains(#13#10) then
    Result := #13#10
  else
    Result := #10;
end;

function SetAlign(AXaml: string; ALine, ACol: Integer; const AAlign: string): string;
const
  GridAttributes: array[0..3] of string = ('Grid.Row', 'Grid.Column', 'Grid.RowSpan', 'Grid.ColumnSpan');
var
  Elements: TArray<TXamlElement>;
  Children: TArray<Integer>;
  Modes: TArray<string>;
  Parent, Child: TXamlElement;
  Block: TMatch;
  I, J, ParentIndex, TopCount, BottomCount, LeftCount, RightCount: Integer;
  TopAt, BottomAt, LeftAt, RightAt, Row, Col, ColSpan: Integer;
  H, V, NL, Indent, Layout: string;
  HasDock: Boolean;
begin
  if not MatchStr(AAlign, ['alNone', 'alTop', 'alBottom', 'alLeft', 'alRight', 'alClient']) then
    raise EXamlEdit.Create('Unknown Align value: ' + AAlign);
  Elements := XamlElements(AXaml);
  ParentIndex := -1;
  for Child in Elements do
    if (Child.Line = ALine) and (Child.Column = ACol) then
      ParentIndex := Child.ParentIndex;
  if (ParentIndex < 0) or (Elements[ParentIndex].Tag <> 'Grid') then
    raise EXamlEdit.Create('Align requires a direct child of a Grid. Put the control in a Grid first.');
  Parent := Elements[ParentIndex];
  Block := TRegEx.Match(AXaml.Substring(Parent.TagEnd - 1),
    '^\s*<!-- RADWinUI Align: begin -->.*?<!-- RADWinUI Align: end -->', [roSingleLine]);
  if not Block.Success then
    for Child in Elements do
      if (Child.ParentIndex = ParentIndex) and MatchStr(Child.Tag, ['Grid.RowDefinitions', 'Grid.ColumnDefinitions']) then
        raise EXamlEdit.Create('This Grid already has custom rows or columns. Use a nested Grid for Align.');

  H := 'Stretch';
  V := 'Stretch';
  if AAlign = 'alTop' then V := 'Top'
  else if AAlign = 'alBottom' then V := 'Bottom'
  else if AAlign = 'alLeft' then H := 'Left'
  else if AAlign = 'alRight' then H := 'Right'
  else if AAlign = 'alNone' then
  begin
    H := 'Left';
    V := 'Top';
  end;
  Result := SetAttribute(AXaml, ALine, ACol, 'HorizontalAlignment', H);
  Result := SetAttribute(Result, ALine, ACol, 'VerticalAlignment', V);
  if H = 'Stretch' then Result := RemoveAttribute(Result, ALine, ACol, 'Width');
  if V = 'Stretch' then Result := RemoveAttribute(Result, ALine, ACol, 'Height');
  Result := RemoveAttribute(Result, ALine, ACol, 'Canvas.Left');
  Result := RemoveAttribute(Result, ALine, ACol, 'Canvas.Top');
  Result := SetAttribute(Result, ALine, ACol, 'Margin', '0');

  Elements := XamlElements(Result);
  TopCount := 0;
  BottomCount := 0;
  LeftCount := 0;
  RightCount := 0;
  HasDock := False;
  for I := 0 to High(Elements) do
    if (Elements[I].ParentIndex = ParentIndex) and not Elements[I].Tag.Contains('.') then
    begin
      Children := Children + [I];
      Modes := Modes + [AlignOf(Result, Elements[I].Line, Elements[I].Column)];
      if Modes[High(Modes)] <> 'alNone' then HasDock := True;
      if Modes[High(Modes)] = 'alTop' then Inc(TopCount);
      if Modes[High(Modes)] = 'alBottom' then Inc(BottomCount);
      if Modes[High(Modes)] = 'alLeft' then Inc(LeftCount);
      if Modes[High(Modes)] = 'alRight' then Inc(RightCount);
    end;
  // Compute positions in source order, then edit backwards so source positions stay valid.
  TopAt := TopCount;
  BottomAt := BottomCount;
  LeftAt := LeftCount;
  RightAt := RightCount;
  for I := High(Children) downto 0 do
  begin
    Child := Elements[Children[I]];
    Row := TopCount;
    Col := LeftCount;
    ColSpan := 1;
    if Modes[I] = 'alTop' then
    begin
      Dec(TopAt);
      Row := TopAt;
      Col := 0;
      ColSpan := LeftCount + RightCount + 1;
    end
    else if Modes[I] = 'alBottom' then
    begin
      Dec(BottomAt);
      Row := TopCount + BottomCount - BottomAt;
      Col := 0;
      ColSpan := LeftCount + RightCount + 1;
    end
    else if Modes[I] = 'alLeft' then
    begin
      Dec(LeftAt);
      Col := LeftAt;
    end
    else if Modes[I] = 'alRight' then
    begin
      Dec(RightAt);
      Col := LeftCount + RightCount - RightAt;
    end;
    for J := 0 to 3 do
      Result := RemoveAttribute(Result, Child.Line, Child.Column,
        GridAttributes[J]);
    if HasDock then
    begin
      Result := SetAttribute(Result, Child.Line, Child.Column, 'Grid.Row', IntToStr(Row));
      Result := SetAttribute(Result, Child.Line, Child.Column, 'Grid.Column', IntToStr(Col));
      if ColSpan > 1 then Result := SetAttribute(Result, Child.Line, Child.Column, 'Grid.ColumnSpan', IntToStr(ColSpan));
    end;
  end;
  if Block.Success then
    Result := Result.Remove(Parent.TagEnd - 1, Block.Length);
  if not HasDock then
    Exit;
  NL := LineBreak(Result);
  Indent := IndentAt(Result, Parent.Start) + '    ';
  Layout := NL + Indent + '<!-- RADWinUI Align: begin -->' + NL + Indent + '<Grid.RowDefinitions>';
  for I := 0 to TopCount + BottomCount do
  begin
    V := 'Auto';
    if I = TopCount then V := '*';
    Layout := Layout + NL + Indent + '    <RowDefinition Height="' + V + '"/>';
  end;
  Layout := Layout + NL + Indent + '</Grid.RowDefinitions>' + NL + Indent + '<Grid.ColumnDefinitions>';
  for I := 0 to LeftCount + RightCount do
  begin
    H := 'Auto';
    if I = LeftCount then H := '*';
    Layout := Layout + NL + Indent + '    <ColumnDefinition Width="' + H + '"/>';
  end;
  Layout := Layout + NL + Indent + '</Grid.ColumnDefinitions>' + NL + Indent + '<!-- RADWinUI Align: end -->';
  Result := Result.Insert(Parent.TagEnd - 1, Layout);
end;

/// AXaml without ARange, an element alone on its lines takes the lines along.
function RemoveRange(AXaml: string; ARange: TRange; out ARemovedFrom, ARemovedCount: Integer): string;
var
  First, Last: Integer;
begin
  First := ARange.Start;
  Last := ARange.Stop; // first character kept after the element
  if (Copy(AXaml, LineStart(AXaml, First), First - LineStart(AXaml, First)).Trim = '') then
  begin
    Last := ARange.Stop;
    while (Last <= Length(AXaml)) and CharInSet(AXaml[Last], [' ', #9, #13]) do
      Inc(Last);
    if (Last > Length(AXaml)) or (AXaml[Last] = #10) then
    begin
      First := LineStart(AXaml, First);
      if Last <= Length(AXaml) then
        Inc(Last);
    end
    else
      Last := ARange.Stop;
  end;
  ARemovedFrom := First;
  ARemovedCount := Last - First;
  Result := AXaml.Remove(First - 1, ARemovedCount);
end;

function InsertChildAt(AXaml: string; APanel, AIndex: Integer; const AElement: string): string;
var
  Children: TArray<TRange>;
  ContentEnd, At, TagEnd: Integer;
  Indent, NL, Tag: string;
  M: TMatch;
begin
  NL := LineBreak(AXaml);
  Children := ChildrenOf(AXaml, APanel, ContentEnd);
  if ContentEnd = 0 then
  begin
    // <StackPanel .../> becomes <StackPanel ...> child </StackPanel>
    M := TRegEx.Match(AXaml.Substring(APanel - 1), TagPattern, [roSingleLine]);
    Tag := M.Groups[2].Value;
    TagEnd := APanel + M.Length - 1; // the '>'
    At := TagEnd - 1;                 // the '/'
    while (At > APanel) and CharInSet(AXaml[At - 1], [' ', #9, #13, #10]) do
      Dec(At);
    Indent := IndentAt(AXaml, APanel);
    Exit(AXaml.Substring(0, At - 1) + '>' + NL + Indent + '    ' + AElement + NL + Indent + '</' + Tag + '>' +
      AXaml.Substring(TagEnd));
  end;
  if (AIndex >= 0) and (AIndex < Length(Children)) then
  begin
    At := Children[AIndex].Start;
    if OwnLine(AXaml, At) then
      Exit(AXaml.Insert(LineStart(AXaml, At) - 1, IndentAt(AXaml, At) + AElement + NL));
    Exit(AXaml.Insert(At - 1, AElement));
  end;
  if Children <> nil then
  begin
    At := Children[High(Children)].Stop;
    if not OwnLine(AXaml, Children[High(Children)].Start) then
      Exit(AXaml.Insert(At - 1, AElement));
    Exit(AXaml.Insert(At - 1, NL + IndentAt(AXaml, Children[High(Children)].Start) + AElement));
  end;
  // No children yet: before the end tag, one level deeper than the panel
  if OwnLine(AXaml, ContentEnd) then
    Exit(AXaml.Insert(LineStart(AXaml, ContentEnd) - 1, IndentAt(AXaml, APanel) + '    ' + AElement + NL));
  Result := AXaml.Insert(ContentEnd - 1, AElement);
end;

function DeleteElement(AXaml: string; ALine, ACol: Integer): string;
var
  From, Count: Integer;
begin
  Result := RemoveRange(AXaml, ElementAt(AXaml, IndexOf(AXaml, ALine, ACol)), From, Count);
end;

function CopyElement(const AXaml: string; ALine, ACol: Integer): string;
var
  Element: TRange;
begin
  TagAt(AXaml, ALine, ACol);
  Element := ElementAt(AXaml, IndexOf(AXaml, ALine, ACol));
  Result := Copy(AXaml, Element.Start, Element.Stop - Element.Start);
end;

function IsNameAttribute(const AName: string): Boolean;
begin
  Result := (AName = 'x:Name') or (AName = 'Name');
end;

procedure CollectNames(const AXaml: string; ANames: TStrings);
var
  Element, Attribute: TMatch;
  Quoted: string;
begin
  for Element in TRegEx.Matches(AXaml, TagPattern, [roSingleLine]) do
    if Element.Value.StartsWith('<!--') or (Element.Groups[1].Value = '/') then
      Continue
    else
      for Attribute in TRegEx.Matches(Element.Value, AttributePattern) do
        if IsNameAttribute(Attribute.Groups[2].Value) then
        begin
          Quoted := Attribute.Groups[4].Value;
          ANames.Add(Unescape(Quoted.Substring(1, Quoted.Length - 2)));
        end;
end;

function FreshName(const AName: string; ANames: TStrings): string;
var
  At, N: Integer;
  Base: string;
begin
  At := Length(AName);
  while (At > 0) and CharInSet(AName[At], ['0'..'9']) do
    Dec(At);
  Base := Copy(AName, 1, At);
  if At = Length(AName) then
    N := 1
  else
    N := StrToIntDef(Copy(AName, At + 1, MaxInt), 0) + 1;
  repeat
    Result := Base + IntToStr(N);
    Inc(N);
  until ANames.IndexOf(Result) < 0;
  ANames.Add(Result);
end;

function NewElementName(const AXaml, ATag: string): string;
var
  Names: TStringList;
begin
  Names := TStringList.Create;
  try
    Names.CaseSensitive := False;
    CollectNames(AXaml, Names);
    Result := FreshName(ATag, Names);
  finally
    Names.Free;
  end;
end;

function NamedToolboxXaml(const AXaml, ATag: string; ARow, AColumn: Integer): string;
begin
  Result := SetAttribute(ToolboxXaml(ATag, ARow, AColumn), 1, 1, 'x:Name', NewElementName(AXaml, ATag));
end;

function WithFreshNames(const AXaml, ASnippet: string): string;
var
  Names: TStringList;
  Element, Attribute: TMatch;
  Quoted, Replacement: string;
  At, Shift: Integer;
begin
  Names := TStringList.Create;
  try
    Names.Sorted := True;
    Names.CaseSensitive := False;
    Names.Duplicates := dupIgnore;
    CollectNames(AXaml, Names);
    Result := ASnippet;
    Shift := 0;
    for Element in TRegEx.Matches(ASnippet, TagPattern, [roSingleLine]) do
      if not Element.Value.StartsWith('<!--') and (Element.Groups[1].Value <> '/') then
        for Attribute in TRegEx.Matches(Element.Value, AttributePattern) do
          if IsNameAttribute(Attribute.Groups[2].Value) then
          begin
            Quoted := Attribute.Groups[4].Value;
            Replacement := Quoted[1] + FreshName(Unescape(Quoted.Substring(1, Quoted.Length - 2)), Names) + Quoted[1];
            At := Element.Index + Attribute.Groups[4].Index - 2 + Shift;
            Result := Result.Remove(At, Quoted.Length).Insert(At, Replacement);
            Inc(Shift, Replacement.Length - Quoted.Length);
          end;
  finally
    Names.Free;
  end;
end;

function PasteElement(AXaml: string; ALine, ACol: Integer; const ASnippet: string): string;
var
  At, ContentEnd: Integer;
  Target, Pasted: TRange;
  Snippet, Tag: string;
  Root: TMatch;
  Child: TRange;
begin
  Snippet := ASnippet.Trim;
  if (Snippet = '') or (Snippet[1] <> '<') then
    raise EXamlEdit.Create('The clipboard does not contain a XAML element');
  TagAt(Snippet, 1, 1);
  Pasted := ElementAt(Snippet, 1);
  if Pasted.Stop <> Length(Snippet) + 1 then
    raise EXamlEdit.Create('Paste one XAML element at a time');
  Snippet := WithFreshNames(AXaml, Snippet);
  At := IndexOf(AXaml, ALine, ACol);
  Tag := TagAt(AXaml, ALine, ACol).Value;
  if TRegEx.IsMatch(Tag, '^<(Grid|StackPanel|Canvas)(\s|/?>)') then
    Exit(InsertChildAt(AXaml, At, MaxInt, Snippet));
  Root := TRegEx.Match(AXaml, TagPattern, [roSingleLine]);
  while Root.Success and Root.Value.StartsWith('<!--') do
    Root := Root.NextMatch;
  if Root.Success and (Root.Groups[2].Value = 'Window') then
  begin
    if At = Root.Index then
      raise EXamlEdit.Create('Select a panel to paste into');
    for Child in ChildrenOf(AXaml, Root.Index, ContentEnd) do
      if Child.Start = At then
        raise EXamlEdit.Create('Select a panel to paste into');
  end;
  Target := ElementAt(AXaml, At);
  if OwnLine(AXaml, At) then
    Snippet := LineBreak(AXaml) + IndentAt(AXaml, At) + Snippet;
  Result := AXaml.Insert(Target.Stop - 1, Snippet);
end;

function InsertChild(AXaml: string; APanelLine, APanelCol, AIndex: Integer; const AElement: string): string;
begin
  Result := InsertChildAt(AXaml, IndexOf(AXaml, APanelLine, APanelCol), AIndex, AElement);
end;

function MoveElement(AXaml: string; ALine, ACol, APanelLine, APanelCol, AIndex, ARow, AColumn: Integer): string;
var
  Element: TRange;
  Panel, From, Count, I, ContentEnd: Integer;
  Snippet: string;
  Children: TArray<TRange>;
begin
  Element := ElementAt(AXaml, IndexOf(AXaml, ALine, ACol));
  Panel := IndexOf(AXaml, APanelLine, APanelCol);
  if (Panel >= Element.Start) and (Panel < Element.Stop) then
    raise EXamlEdit.Create('An element cannot move into itself');
  Snippet := Copy(AXaml, Element.Start, Element.Stop - Element.Start);
  if ARow < 0 then
    Snippet := RemoveAttribute(RemoveAttribute(Snippet, 1, 1, 'Grid.Row'), 1, 1, 'Grid.Column')
  else
  begin
    Snippet := SetAttribute(Snippet, 1, 1, 'Grid.Row', IntToStr(ARow));
    Snippet := SetAttribute(Snippet, 1, 1, 'Grid.Column', IntToStr(AColumn));
  end;
  // AIndex counts the element in its old place, when that place is this panel
  Children := ChildrenOf(AXaml, Panel, ContentEnd);
  for I := 0 to High(Children) do
    if (Children[I].Start = Element.Start) and (I < AIndex) then
      Dec(AIndex);
  Result := RemoveRange(AXaml, Element, From, Count);
  if Panel > From then
    Dec(Panel, Count);
  Result := InsertChildAt(Result, Panel, AIndex, Snippet);
end;

function ToolboxXaml(const ATag: string; ARow, AColumn: Integer): string;
begin
  if ATag = 'Button' then
    Result := '<Button Content="Button"'
  else if ATag = 'TextBlock' then
    Result := '<TextBlock Text="TextBlock"'
  else if ATag = 'TextBox' then
    Result := '<TextBox PlaceholderText="TextBox"'
  else if ATag = 'CheckBox' then
    Result := '<CheckBox Content="CheckBox"'
  else if ATag = 'ComboBox' then
    Result := '<ComboBox Width="160"'
  else if ATag = 'ListView' then
    Result := '<ListView Height="120"'
  else if ATag = 'Image' then
    Result := '<Image Width="64" Height="64"'
  else if ATag = 'StackPanel' then
    Result := '<StackPanel Spacing="8" MinHeight="40"'
  else if ATag = 'Grid' then
    Result := '<Grid MinHeight="80"'
  else if TRegEx.IsMatch(ATag, '^[A-Za-z_][A-Za-z0-9_.-]*$') then
    Result := '<' + ATag
  else
    raise EXamlEdit.CreateFmt('%s is not a valid XAML element name', [ATag]);
  if ARow > 0 then
    Result := Result + ' Grid.Row="' + IntToStr(ARow) + '"';
  if AColumn > 0 then
    Result := Result + ' Grid.Column="' + IntToStr(AColumn) + '"';
  Result := Result + '/>';
end;

/// ASnippet (one element, its start tag at 1:1) positioned as PlaceElement describes.
function Positioned(ASnippet: string; const AKind: string; ARow, AColumn, ALeft, ATop: Integer): string;
begin
  Result := ASnippet;
  if AKind = 'Canvas' then
  begin
    Result := SetAttribute(Result, 1, 1, 'Canvas.Left', IntToStr(ALeft));
    Result := SetAttribute(Result, 1, 1, 'Canvas.Top', IntToStr(ATop));
    Exit;
  end;
  if AKind <> 'Grid' then
    raise EXamlEdit.CreateFmt('%s is not a Grid or a Canvas', [AKind]);
  if ARow > 0 then
    Result := SetAttribute(Result, 1, 1, 'Grid.Row', IntToStr(ARow))
  else
    Result := RemoveAttribute(Result, 1, 1, 'Grid.Row');
  if AColumn > 0 then
    Result := SetAttribute(Result, 1, 1, 'Grid.Column', IntToStr(AColumn))
  else
    Result := RemoveAttribute(Result, 1, 1, 'Grid.Column');
  Result := SetAttribute(Result, 1, 1, 'HorizontalAlignment', 'Left');
  Result := SetAttribute(Result, 1, 1, 'VerticalAlignment', 'Top');
  Result := SetAttribute(Result, 1, 1, 'Margin', Format('%d,%d,0,0', [Max(ALeft, 0), Max(ATop, 0)]));
end;

function PlaceElement(AXaml: string; ALine, ACol, APanelLine, APanelCol: Integer; const AKind: string;
  ARow, AColumn, ALeft, ATop: Integer): string;
var
  Element: TRange;
  Panel, ContentEnd, From, Count: Integer;
  Snippet: string;
  Children: TArray<TRange>;
  Child: TRange;
  InPanel: Boolean;
begin
  Element := ElementAt(AXaml, IndexOf(AXaml, ALine, ACol));
  Panel := IndexOf(AXaml, APanelLine, APanelCol);
  if (Panel >= Element.Start) and (Panel < Element.Stop) then
    raise EXamlEdit.Create('An element cannot move into itself');
  Snippet := Positioned(Copy(AXaml, Element.Start, Element.Stop - Element.Start), AKind, ARow, AColumn, ALeft, ATop);
  InPanel := False;
  Children := ChildrenOf(AXaml, Panel, ContentEnd);
  for Child in Children do
    InPanel := InPanel or (Child.Start = Element.Start);
  if InPanel then
    // Same panel: only the start tag's attributes change, in place
    Exit(AXaml.Substring(0, Element.Start - 1) + Snippet + AXaml.Substring(Element.Stop - 1));
  Result := RemoveRange(AXaml, Element, From, Count);
  if Panel > From then
    Dec(Panel, Count);
  Result := InsertChildAt(Result, Panel, MaxInt, Snippet);
end;

function ApplyDesignerEvent(AXaml: string; const AEvent: string): string;
var
  P: TArray<string>;
begin
  P := AEvent.Split([' ']);
  if (Length(P) = 10) and (P[0] = 'PLACE') then
    Exit(PlaceElement(AXaml, P[1].ToInteger, P[2].ToInteger, P[3].ToInteger, P[4].ToInteger, P[5],
      P[6].ToInteger, P[7].ToInteger, P[8].ToInteger, P[9].ToInteger));
  if (Length(P) = 9) and (P[0] = 'INSERTAT') then
    Exit(InsertChild(AXaml, P[2].ToInteger, P[3].ToInteger, MaxInt,
      Positioned(NamedToolboxXaml(AXaml, P[1], 0, 0), P[4], P[5].ToInteger, P[6].ToInteger, P[7].ToInteger, P[8].ToInteger)));
  if (Length(P) = 7) and (P[0] = 'INSERT') then
    Result := InsertChild(AXaml, P[2].ToInteger, P[3].ToInteger, P[4].ToInteger,
      NamedToolboxXaml(AXaml, P[1], P[5].ToInteger, P[6].ToInteger))
  else if (Length(P) = 8) and (P[0] = 'MOVE') then
    Result := MoveElement(AXaml, P[1].ToInteger, P[2].ToInteger, P[3].ToInteger, P[4].ToInteger, P[5].ToInteger,
      P[6].ToInteger, P[7].ToInteger)
  else if (Length(P) = 3) and (P[0] = 'DELETE') then
    Result := DeleteElement(AXaml, P[1].ToInteger, P[2].ToInteger)
  else
    raise EXamlEdit.Create('Not a designer event: ' + AEvent);
end;

end.
