unit RADWinUI.Designer.AICompletion;

{
  AI in the XAML code editor, through the IDE's AI engine (ToolsAPI.AI, the plugin
  chosen in the IDE's AI options):

  - Complete XAML with AI (Ctrl+Alt+Space): the prompt and how its answer goes in.
  - Suggestions while typing: TXamlSuggestions decides when to ask, which answers
    are still current, what is shown as ghost text, and what Tab inserts.

  IDE-free, the time comes in as a parameter: RADWinUI.Preview.Command reads the
  editor, sends the requests, paints the ghost text and applies the edits.
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  RADWinUI.Designer.Model;

const
  /// <summary>Marks the cursor in the XAML sent to the engine.</summary>
  XamlCursorMarker = '<<<CURSOR>>>';
  /// <summary>A suggestion while typing has at most this many lines.</summary>
  MaxSuggestionLines = 8;

type
  /// <summary>The names a suggestion may use, as XAML spells them: XAML is
  /// case-sensitive, models often write &lt;button&gt;.</summary>
  IXamlVocabulary = interface
    ['{6C1F0B52-3D7E-4A55-9C2B-8E41A7D3F0C9}']
    /// <summary>ATag as spelled (also prefixed and user controls), '' when unknown.</summary>
    function ExactTag(const ATag: string): string;
    /// <summary>The attribute AName of ATag (spelled) as spelled, '' when the metadata does not list it.</summary>
    function ExactAttribute(const ATag, AName: string): string;
  end;

  /// <summary>The vocabulary of RADWinUI.Xaml.json and RADWinUI.Controls.json (AIndex,
  /// not owned) and the project's user controls (prefix:Name).</summary>
  TIndexVocabulary = class(TInterfacedObject, IXamlVocabulary)
  strict private
    FIndex: TDesignerTypeIndex;
    FUserControls: TArray<string>;
  public
    constructor Create(AIndex: TDesignerTypeIndex; const AUserControls: TArray<string>);
    function ExactTag(const ATag: string): string;
    function ExactAttribute(const ATag, AName: string): string;
  end;

  /// <summary>A suggestion: the text after the cursor, and the start of the tag being
  /// typed with its corrected spelling (same length), which Tab writes too.</summary>
  TXamlGhost = record
    Text: string;
    TypedStart: Integer;
    TypedFix: string;
  end;

  /// <summary>An answer kept for its line: while the user types along it (or deletes back
  /// into it), the rest shows at once, without a new request.</summary>
  TXamlPrediction = record
    Head: string;      // the text before the line
    Line: string;      // the line up to the end of the suggestion, names as XAML spells them
    After: string;     // the text after the cursor when it was asked
  end;

  /// <summary>Suggestions while typing, for one editor at a time. The caller reports
  /// the editor's text and cursor (Observe), asks whether a request is due (Due),
  /// and passes the engine's answer back with its request ID (Answered).</summary>
  TXamlSuggestions = class
  strict private
    FDelay: Cardinal;
    FText: string;
    FCursor: Integer;
    FObserved: Boolean;
    FDue: UInt64;
    FDuePending: Boolean;
    FInFlight: Boolean;
    FSentAt: UInt64;
    FRequestID: TGUID;
    FRequestText: string;
    FRequestCursor: Integer;
    FGhost: string;
    FTypedStart: Integer;
    FTypedFix: string;
    FVocabulary: IXamlVocabulary;
    FLastAnswer: string;
    FPredictions: TList<TXamlPrediction>;
    FEmpty: TDictionary<string, Boolean>; // places the engine had nothing for
    function Key(const AText: string; ACursor: Integer): string;
    procedure Show(const AGhost: TXamlGhost);
    function Predict(const AText: string; ACursor: Integer): Boolean;
  public
    const
      /// <summary>An answer that takes longer is given up, the next pause asks again.</summary>
      Timeout = 20000;
    constructor Create(ADelay: Cardinal);
    destructor Destroy; override;
    /// <summary>The editor's text and cursor (0-based UTF-16) at ANow (ms). Typing that
    /// matches the suggestion consumes it. Another edit dismisses it, shows an earlier
    /// answer for the line that still fits, or else asks again after the delay, and only
    /// on an incomplete line (IsXamlLineIncomplete). A cursor move dismisses it. True
    /// when the ghost text changed.</summary>
    function Observe(const AText: string; ACursor: Integer; ANow: UInt64): Boolean;
    /// <summary>True when a request should go out now for RequestText and RequestCursor.
    /// An answer in the cache is shown instead (Ghost), without a request.</summary>
    function Due(ANow: UInt64): Boolean;
    /// <summary>The request went out with this ID.</summary>
    procedure Sent(const AID: TGUID; ANow: UInt64);
    /// <summary>An answer: True when it is shown. Answers to other IDs or without XAML are
    /// not shown; an answer to a text that changed meanwhile is shown when the line still
    /// leads to it.</summary>
    function Answered(const AID: TGUID; const AAnswer: string): Boolean;
    /// <summary>The request failed: the next pause asks again.</summary>
    procedure Failed(const AID: TGUID);
    /// <summary>Tab: the text with the suggestion inserted and the cursor after it.</summary>
    function Accept(out ANewText: string; out ANewCursor: Integer): Boolean;
    /// <summary>Esc or another editor: no ghost text, no pending request.</summary>
    procedure Dismiss;
    /// <summary>The delay after the last edit before a request, in ms.</summary>
    property Delay: Cardinal read FDelay write FDelay;
    /// <summary>Checks and corrects the names of answers; nil shows them as they come.</summary>
    property Vocabulary: IXamlVocabulary read FVocabulary write FVocabulary;
    /// <summary>The last answer as the engine sent it, for the log.</summary>
    property LastAnswer: string read FLastAnswer;
    /// <summary>The ghost text after the cursor, '' when none is shown.</summary>
    property Ghost: string read FGhost;
    /// <summary>Where the ghost text starts: the observed text and cursor.</summary>
    property Text: string read FText;
    property Cursor: Integer read FCursor;
    property RequestText: string read FRequestText;
    property RequestCursor: Integer read FRequestCursor;
    property InFlight: Boolean read FInFlight;
  end;

/// <summary>Where suggestions appear: the cursor is in a start tag still being typed
/// (after "&lt;Butt", "&lt;Button Cont" or an unfinished attribute value), with at most a
/// quote, "&gt;" or "/&gt;" after it on the line. Not on empty lines, after a complete
/// element, in comments or in the middle of finished text.</summary>
function IsXamlLineIncomplete(const AXaml: string; ACursor: Integer): Boolean;

/// <summary>The user controls of the project a XAML file can use: prefix:Name for
/// each .xaml with a UserControl root in AFolder, when the root of AXaml declares
/// a using: namespace (XAML.md, The project's user controls).</summary>
function ProjectUserControls(const AXaml, AFolder: string): TArray<string>;

/// <summary>The prompt for Complete XAML with AI: the instruction with the controls,
/// the x:Names in use and the rules, then AXaml with the cursor marker at ACursor
/// (0-based UTF-16 index).</summary>
function BuildXamlCompletion(const AXaml: string; ACursor: Integer;
  const AUserControls: TArray<string>): string;

/// <summary>The prompt for a suggestion while typing: short for a fast answer, the
/// line typed so far, the elements whose names fit it, a few lines around the cursor,
/// and an answer that finishes the line.</summary>
function BuildXamlSuggestion(const AXaml: string; ACursor: Integer;
  const AUserControls: TArray<string>): string;

/// <summary>The prompt for Create XAML with AI: the user's description of a UI, the rules,
/// the controls and the file with the cursor marked, for XAML that builds that UI.</summary>
function BuildXamlFromDescription(const AXaml: string; ACursor: Integer; const ADescription: string;
  const AUserControls: TArray<string>): string;

/// <summary>AXaml with ABlock (XAML of any indentation) placed for ASelStart..ASelEnd
/// (0-based, the cursor when equal), re-indented: a selection is replaced; in the
/// indentation of a line it goes at the cursor; after text on a line it goes on a new line
/// below, one level deeper when that line opens an element. ACursor is after the block.</summary>
function PlaceXamlBlock(const AXaml: string; ASelStart, ASelEnd: Integer; const ABlock: string;
  out ACursor: Integer): string;

/// <summary>The XAML to insert from an engine's answer: without code fences, an
/// echoed cursor marker or trailing blank lines.</summary>
function CleanXamlCompletion(const AAnswer: string): string;

/// <summary>A suggestion that fits at ACursor: cleaned, without what the line already
/// has before the cursor (models often repeat it, in any case), at most AMaxLines lines.</summary>
function FitXamlSuggestion(const AXaml: string; ACursor: Integer; const AAnswer: string;
  AMaxLines: Integer = MaxSuggestionLines): string;

/// <summary>Checks the names in the tag being typed before ACursor plus ASuggestion against
/// AVocabulary and corrects their case: AGhost gets the suggestion and the typed part as
/// XAML spells them. False when an element is unknown or an attribute is lower case and
/// unknown: the suggestion is not offered.</summary>
function CorrectXamlSuggestion(const AXaml: string; ACursor: Integer; const ASuggestion: string;
  const AVocabulary: IXamlVocabulary; out AGhost: TXamlGhost): Boolean;

/// <summary>AXaml with AGhost written at ACursor: the typed part corrected and the text inserted.</summary>
function ApplyXamlGhost(const AXaml: string; ACursor: Integer; const AGhost: TXamlGhost): string;

/// <summary>AXaml with ASuggestion inserted at ACursor (0-based UTF-16 index).</summary>
function InsertXamlCompletion(const AXaml: string; ACursor: Integer; const ASuggestion: string): string;

implementation

uses
  System.Math,
  System.IOUtils,
  System.Hash,
  System.RegularExpressions,
  RADWinUI.Designer.XamlEdit,
  RADWinUI.Designer.Palette;

const
  // shortcut: a large file is cut to this many characters around the cursor, send
  // the whole file if engines with small limits turn out not to matter
  MaxInputLength = 24000;
  SuggestionLinesBefore = 8;
  SuggestionLinesAfter = 3;
  MaxPredictions = 32;
  MaxFittingElements = 12;

function RootTagText(const AXaml: string): string;
var
  Match: TMatch;
begin
  // The first element start tag after the prolog and comments
  Match := TRegEx.Match(AXaml, '<[A-Za-z][^>]*>', [roSingleLine]);
  if Match.Success then
    Result := Match.Value
  else
    Result := '';
end;

function ProjectUserControls(const AXaml, AFolder: string): TArray<string>;
var
  Match: TMatch;
  Prefix, FileName: string;
  Elements: TArray<TXamlElement>;
begin
  Result := nil;
  Match := TRegEx.Match(RootTagText(AXaml), 'xmlns:(\w+)="using:(?!RADWinUI\.Controls")[^"]*"');
  if not Match.Success or not TDirectory.Exists(AFolder) then
    Exit;
  Prefix := Match.Groups[1].Value;
  for FileName in TDirectory.GetFiles(AFolder, '*.xaml') do
    try
      Elements := XamlElements(TFile.ReadAllText(FileName));
      if (Length(Elements) > 0) and (Elements[0].Tag = 'UserControl') then
        Result := Result + [Prefix + ':' + TPath.GetFileNameWithoutExtension(FileName)];
    except
      // A file that does not parse is not offered
    end;
end;

function ClampCursor(const AXaml: string; ACursor: Integer): Integer;
begin
  Result := ACursor;
  if Result < 0 then
    Result := 0;
  if Result > Length(AXaml) then
    Result := Length(AXaml);
end;

/// The rules both prompts share: the controls, the names in use and RADWinUI's XAML rules.
function XamlRules(const AXaml: string; const AUserControls: TArray<string>): string;
var
  Entry: TPaletteEntry;
  Element: TXamlElement;
  ControlList, NameList, Control: string;
begin
  ControlList := '';
  for Entry in PaletteEntries do
    if Entry.Prefix <> '' then
      ControlList := ControlList + Entry.Prefix + ':' + Entry.Name + ', '
    else
      ControlList := ControlList + Entry.Name + ', ';
  for Control in AUserControls do
    ControlList := ControlList + Control + ', ';
  ControlList := ControlList.TrimRight([',', ' ']);

  NameList := '';
  try
    for Element in XamlElements(AXaml) do
      if (Element.Name <> '') and (Element.ParentIndex >= 0) then // the root's name is its x:Class
        NameList := NameList + Element.Name + ', ';
  except
    // Half-typed XAML: no names, the engine still sees the text
  end;
  NameList := NameList.TrimRight([',', ' ']);
  if NameList = '' then
    NameList := '(none)';

  Result :=
    'Rules:'#13#10 +
    '- XAML is case-sensitive: element and attribute names are PascalCase WinUI 3 names, written exactly as here: ' +
    '<Button>, <TextBlock>, <StackPanel>, Content, Text, Click. Never <button> or content=.'#13#10 +
    '- Use WinUI 3 controls and these RADWinUI controls: ' + ControlList + '.'#13#10 +
    '- RADWinUI''s own controls use the rw: prefix, declared as xmlns:rw="using:RADWinUI.Controls" on the root.'#13#10 +
    '- An event attribute names a published method of the Delphi unit, for example Click="SaveClick". ' +
    'Do not write code-behind, x:Bind or C#.'#13#10 +
    '- Data binding is {Binding Path} to published properties of DataContextType, or of x:DataType in a DataTemplate.'#13#10 +
    '- Give a new element an x:Name only when code needs it. An x:Name is unique, is not a Pascal keyword ' +
    'and does not hide a window member such as Title, Content or Width. Names in use: ' + NameList + '.'#13#10 +
    '- An icon-only button needs AutomationProperties.Name.'#13#10 +
    '- Let the parent panel lay elements out: no Margin, HorizontalAlignment, VerticalAlignment, Width or Height ' +
    'offsets unless the elements next to the cursor use them the same way.'#13#10 +
    '- Use realistic texts (Content="Save", not Content="Button"), and x:Names in the style of the file.'#13#10 +
    '- A <Window> takes only RADWinUI''s window attributes (Title, Width, Height, Backdrop, TitleBar, ' +
    'WindowState and the like) and one content element.'#13#10;
end;

function BuildXamlCompletion(const AXaml: string; ACursor: Integer;
  const AUserControls: TArray<string>): string;
var
  Start: Integer;
  Input: string;
begin
  ACursor := ClampCursor(AXaml, ACursor);
  Input := Copy(AXaml, 1, ACursor) + XamlCursorMarker + Copy(AXaml, ACursor + 1, MaxInt);
  if Length(Input) > MaxInputLength then
  begin
    Start := ACursor - MaxInputLength div 2;
    if Start < 0 then
      Start := 0;
    if Start + MaxInputLength > Length(Input) then
      Start := Length(Input) - MaxInputLength;
    Input := Input.Substring(Start, MaxInputLength);
  end;

  Result :=
    'You complete XAML in the RAD Studio code editor. The file is a RADWinUI window, page or user control: ' +
    'WinUI 3 XAML for a Delphi app. ' + XamlCursorMarker + ' marks the cursor.'#13#10 +
    'Reply with only the XAML to insert at the cursor: no explanation, no code fences, no text before or after it, ' +
    'and do not repeat XAML that is already in the file. Keep the indentation of the surrounding lines. ' +
    'If nothing fits, reply with nothing.'#13#10 +
    XamlRules(AXaml, AUserControls) + #13#10 +
    'The XAML file:'#13#10 + Input;
end;

function BuildXamlFromDescription(const AXaml: string; ACursor: Integer; const ADescription: string;
  const AUserControls: TArray<string>): string;
var
  Start: Integer;
  Input, Root: string;
  Elements: TArray<TXamlElement>;
begin
  ACursor := ClampCursor(AXaml, ACursor);
  Input := Copy(AXaml, 1, ACursor) + XamlCursorMarker + Copy(AXaml, ACursor + 1, MaxInt);
  if Length(Input) > MaxInputLength then
  begin
    Start := EnsureRange(ACursor - MaxInputLength div 2, 0, Length(Input) - MaxInputLength);
    Input := Input.Substring(Start, MaxInputLength);
  end;
  Root := 'window, page or user control';
  try
    Elements := XamlElements(AXaml);
    if Length(Elements) > 0 then
      Root := '<' + Elements[0].Tag + '>';
  except
    // Half-typed XAML: the generic name
  end;
  Result :=
    'You write XAML in the RAD Studio code editor: the user describes a UI and you write the XAML that builds it. ' +
    'The file is a RADWinUI ' + Root + ': WinUI 3 XAML for a Delphi app. ' + XamlCursorMarker +
    ' marks where your XAML goes; inside a panel it becomes the panel''s children.'#13#10 +
    'The user asks: ' + ADescription.Trim + #13#10 +
    'Reply with only that XAML: no explanation, no code fences, nothing that is already in the file.'#13#10 +
    'Layout: build it with Grid (RowDefinitions, ColumnDefinitions) and StackPanel (Spacing), never with absolute ' +
    'Margin positions. Give interactive elements and inputs an x:Name. Use realistic texts and labels, ' +
    '{ThemeResource ...} brushes for colours, and no event attributes such as Click unless the user asks for them. ' +
    'Write UI elements; resources (brushes, styles) only when the user asks for them.'#13#10 +
    XamlRules(AXaml, AUserControls) + #13#10 +
    'The XAML file:'#13#10 + Input;
end;

function PlaceXamlBlock(const AXaml: string; ASelStart, ASelEnd: Integer; const ABlock: string;
  out ACursor: Integer): string;
var
  LineStart, LineEnd, Common, I, J, At: Integer;
  Before, Line, Indent, Step, NewLine, Body, Previous: string;
  Lines: TArray<string>;
  Kept: TList<string>;

  function Leading(const AText: string): string;
  var
    K: Integer;
  begin
    K := 1;
    while (K <= Length(AText)) and CharInSet(AText[K], [' ', #9]) do
      Inc(K);
    Result := Copy(AText, 1, K - 1);
  end;

  // A line like <StackPanel ...>: what follows it is its content
  function Opens(const AText: string): Boolean;
  var
    T: string;
  begin
    T := AText.Trim;
    Result := T.StartsWith('<') and not T.StartsWith('</') and not T.StartsWith('<!') and T.EndsWith('>') and
      not T.EndsWith('/>') and not T.Contains('</');
  end;

begin
  if ASelEnd < ASelStart then
  begin
    I := ASelStart;
    ASelStart := ASelEnd;
    ASelEnd := I;
  end;
  ASelStart := ClampCursor(AXaml, ASelStart);
  ASelEnd := ClampCursor(AXaml, ASelEnd);
  if AXaml.Contains(#13#10) or (AXaml = '') then
    NewLine := #13#10
  else
    NewLine := #10;
  // The file's indentation step: the first indented line's indentation, else 4 spaces
  Step := '    ';
  for Line in AXaml.Replace(#13, '').Split([#10]) do
    if (Line.Trim <> '') and (Leading(Line) <> '') then
    begin
      Step := Leading(Line);
      Break;
    end;
  // The block without its own common indentation and outer blank lines
  Kept := TList<string>.Create;
  try
    for Line in ABlock.Replace(#13, '').Split([#10]) do
      Kept.Add(Line.TrimRight);
    while (Kept.Count > 0) and (Kept.First.Trim = '') do
      Kept.Delete(0);
    while (Kept.Count > 0) and (Kept.Last.Trim = '') do
      Kept.Delete(Kept.Count - 1);
    Lines := Kept.ToArray;
  finally
    Kept.Free;
  end;
  if Length(Lines) = 0 then
  begin
    ACursor := ASelStart;
    Exit(AXaml);
  end;
  // The common indentation of the lines after the first: answers often start the first
  // line flush and indent the others as in their own idea of the file
  Common := MaxInt;
  for I := 1 to High(Lines) do
    if Lines[I].Trim <> '' then
      Common := Min(Common, Length(Leading(Lines[I])));
  if Common = MaxInt then
    Common := 0;
  Lines[0] := Lines[0].TrimLeft;
  for I := 1 to High(Lines) do
    Lines[I] := Copy(Lines[I], Min(Common, Length(Leading(Lines[I]))) + 1, MaxInt);

  LineStart := AXaml.LastIndexOf(#10, ASelStart - 1) + 1;
  if ASelStart = 0 then
    LineStart := 0;
  LineEnd := AXaml.IndexOf(#10, ASelStart);
  if LineEnd < 0 then
    LineEnd := Length(AXaml);
  if (LineEnd > LineStart) and (AXaml[LineEnd] = #13) then
    Dec(LineEnd);
  Before := Copy(AXaml, LineStart + 1, ASelStart - LineStart);
  Line := Copy(AXaml, LineStart + 1, LineEnd - LineStart);

  if (ASelEnd > ASelStart) or (Before.Trim = '') then
  begin
    // At the cursor, or over the selection
    Indent := Leading(Line);
    if (Line.Trim = '') and (Before = '') then
    begin
      // An empty line at its start: like the line above, deeper when that one opens an element
      J := LineStart - 1;
      Previous := '';
      while (J > 0) and (Previous.Trim = '') do
      begin
        At := AXaml.LastIndexOf(#10, J - 1) + 1;
        if J - 1 < 0 then
          At := 0;
        Previous := Copy(AXaml, At + 1, J - At).TrimRight([#13]);
        J := At - 1;
      end;
      Indent := Leading(Previous);
      if Opens(Previous) then
        Indent := Indent + Step;
      Body := Indent;
    end
    else
      Body := '';
    Body := Body + Lines[0];
    for I := 1 to High(Lines) do
      Body := Body + NewLine + Indent + Lines[I];
    // Text after the cursor on the line goes below the block
    if (ASelEnd = ASelStart) and (Copy(AXaml, ASelEnd + 1, LineEnd - ASelEnd).Trim <> '') then
      Body := Body + NewLine + Indent;
    Result := Copy(AXaml, 1, ASelStart) + Body + Copy(AXaml, ASelEnd + 1, MaxInt);
    ACursor := ASelStart + Length(Body);
  end
  else
  begin
    // After text on the line: on a new line below it
    Indent := Leading(Line);
    if Opens(Line) then
      Indent := Indent + Step;
    Body := '';
    for I := 0 to High(Lines) do
      Body := Body + NewLine + Indent + Lines[I];
    Result := Copy(AXaml, 1, LineEnd) + Body + Copy(AXaml, LineEnd + 1, MaxInt);
    ACursor := LineEnd + Length(Body);
  end;
end;

function IsXamlLineIncomplete(const AXaml: string; ACursor: Integer): Boolean;
var
  LineStart, LineEnd, Open: Integer;
  Before, After: string;
begin
  ACursor := ClampCursor(AXaml, ACursor);
  LineStart := AXaml.LastIndexOf(#10, ACursor - 1) + 1;
  if ACursor = 0 then
    LineStart := 0;
  LineEnd := AXaml.IndexOf(#10, ACursor);
  if LineEnd < 0 then
    LineEnd := Length(AXaml);
  Before := Copy(AXaml, LineStart + 1, ACursor - LineStart);
  After := Copy(AXaml, ACursor + 1, LineEnd - ACursor).Trim;
  Open := Before.LastIndexOf('<');
  Result := (Open >= 0) and (Open > Before.LastIndexOf('>')) and (Before.Trim <> '<') and
    not Before.Substring(Open).StartsWith('<!') and
    ((After = '') or After.StartsWith('"') or After.StartsWith('>') or After.StartsWith('/>'));
end;

/// The palette's and the project's elements whose names start with the tag being typed.
function FittingElements(const ABefore: string; const AUserControls: TArray<string>): string;
var
  Open, Count: Integer;
  Typed, Name: string;
  Entry: TPaletteEntry;
begin
  Result := '';
  Open := ABefore.LastIndexOf('<');
  if Open < 0 then
    Exit;
  Typed := ABefore.Substring(Open + 1);
  if (Typed = '') or Typed.Contains(' ') or Typed.StartsWith('/') then
    Exit; // typing attributes, or a closing tag: the element is known
  Count := 0;
  for Entry in PaletteEntries do
  begin
    if Entry.Prefix <> '' then
      Name := Entry.Prefix + ':' + Entry.Name
    else
      Name := Entry.Name;
    if (Count < MaxFittingElements) and (Name.StartsWith(Typed, True) or Entry.Name.StartsWith(Typed, True)) then
    begin
      Result := Result + Name + ', ';
      Inc(Count);
    end;
  end;
  for Name in AUserControls do
    if (Count < MaxFittingElements) and (Name.StartsWith(Typed, True) or
      Name.Substring(Name.IndexOf(':') + 1).StartsWith(Typed, True)) then
    begin
      Result := Result + Name + ', ';
      Inc(Count);
    end;
  Result := Result.TrimRight([',', ' ']);
end;

function BuildXamlSuggestion(const AXaml: string; ACursor: Integer;
  const AUserControls: TArray<string>): string;
var
  Start, Stop, I, LineStart: Integer;
  Before, Fitting: string;
begin
  ACursor := ClampCursor(AXaml, ACursor);
  // The lines around the cursor: from SuggestionLinesBefore lines above to SuggestionLinesAfter below
  Start := ACursor;
  for I := 1 to SuggestionLinesBefore do
  begin
    Start := AXaml.LastIndexOf(#10, Start - 1);
    if Start < 0 then
      Break;
  end;
  Inc(Start); // after the line break, or 0
  Stop := ACursor;
  for I := 1 to SuggestionLinesAfter do
  begin
    Stop := AXaml.IndexOf(#10, Stop) + 1;
    if Stop <= 0 then
    begin
      Stop := Length(AXaml);
      Break;
    end;
  end;
  if Stop < ACursor then
    Stop := Length(AXaml);

  LineStart := AXaml.LastIndexOf(#10, ACursor - 1) + 1;
  if ACursor = 0 then
    LineStart := 0;
  Before := Copy(AXaml, LineStart + 1, ACursor - LineStart).TrimLeft;
  Fitting := FittingElements(Before, AUserControls);
  // Short on purpose: the answer comes faster
  Result :=
    'Inline XAML completion in RAD Studio (WinUI 3 XAML of a RADWinUI Delphi app). Reply with only the characters ' +
    'that come right after ' + XamlCursorMarker + ' to finish the current line: one line, no explanation, ' +
    'no code fences, nothing that is already before the cursor.'#13#10 +
    'The line so far: "' + Before + '"'#13#10 +
    'XAML is case-sensitive, names are PascalCase: <Button>, <TextBlock>, Content, Click; never <button>. ' +
    'RADWinUI''s own controls are rw:Name. No Margin or alignment offsets. Realistic texts. ' +
    'An event names a Delphi method: Click="SaveClick".'#13#10;
  if Fitting <> '' then
    Result := Result + 'Elements that fit: ' + Fitting + '.'#13#10;
  Result := Result +
    'Examples: "<Butt" -> on Content="Save" Click="SaveClick"/>; "<rw:Send" -> Button Text="Send"/>; ' +
    '"<TextBox x:Name="NameBox" " -> PlaceholderText="Name"/>'#13#10 +
    'Context:'#13#10 +
    Copy(AXaml, Start + 1, ACursor - Start) + XamlCursorMarker + Copy(AXaml, ACursor + 1, Stop - ACursor);
end;

function CleanXamlCompletion(const AAnswer: string): string;
var
  Match: TMatch;
begin
  Result := AAnswer;
  // ```xml ... ```: the code inside the first fence
  Match := TRegEx.Match(Result, '```[A-Za-z]*[ \t]*\r?\n(.*?)\r?\n?```', [roSingleLine]);
  if Match.Success then
    Result := Match.Groups[1].Value;
  Result := Result.Replace(XamlCursorMarker, '');
  // Trailing white space only: leading indentation belongs to the suggestion
  Result := Result.TrimRight;
  // Leading blank lines, the line break before the first text is kept
  while Result.StartsWith(#13#10#13#10) do
    Result := Result.Substring(2);
  while Result.StartsWith(#10#10) do
    Result := Result.Substring(1);
end;

function FitXamlSuggestion(const AXaml: string; ACursor: Integer; const AAnswer: string;
  AMaxLines: Integer): string;
var
  LineStart, Count, I, K: Integer;
  Before, Typed: string;
begin
  Result := CleanXamlCompletion(AAnswer);
  if Result = '' then
    Exit;
  ACursor := ClampCursor(AXaml, ACursor);
  LineStart := AXaml.LastIndexOf(#10, ACursor - 1) + 1;
  if ACursor = 0 then
    LineStart := 0;
  Before := Copy(AXaml, LineStart + 1, ACursor - LineStart);
  Typed := Before.TrimLeft;
  if Typed = '' then
  begin
    // The cursor is in the indentation: the line already has it
    if not Result.StartsWith(#10) and not Result.StartsWith(#13#10) then
      Result := Result.TrimLeft([' ', #9]);
  end
  else
    // The longest end of the typed text the answer starts with, in any case:
    // "<Butt" + "<button/>" is "on/>" (CorrectXamlSuggestion fixes the case)
    for K := Length(Typed) downto 1 do
      if Result.StartsWith(Copy(Typed, Length(Typed) - K + 1, K), True) then
      begin
        Result := Result.Substring(K);
        Break;
      end;
  // At most AMaxLines lines
  Count := 0;
  for I := 1 to Length(Result) do
    if Result[I] = #10 then
    begin
      Inc(Count);
      if Count = AMaxLines then
      begin
        Result := Copy(Result, 1, I - 1).TrimRight;
        Break;
      end;
    end;
end;

function CorrectXamlSuggestion(const AXaml: string; ACursor: Integer; const ASuggestion: string;
  const AVocabulary: IXamlVocabulary; out AGhost: TXamlGhost): Boolean;
var
  LineStart, Open, I, TagEnd: Integer;
  Before, Typed, Fragment, Name, Exact, Owner, Member, Tag: string;
  Tags, Attributes: TMatchCollection;
  Match, Attribute: TMatch;

  // Writes AExact over the name at AIndex (0-based in Fragment): only the case changes
  procedure Fix(AIndex: Integer; const AExact: string);
  begin
    Fragment := Copy(Fragment, 1, AIndex) + AExact + Copy(Fragment, AIndex + Length(AExact) + 1, MaxInt);
  end;

begin
  Result := False;
  AGhost := Default(TXamlGhost);
  ACursor := ClampCursor(AXaml, ACursor);
  // The tag being typed: from its '<' on the cursor's line, when no '>' closed it
  LineStart := AXaml.LastIndexOf(#10, ACursor - 1) + 1;
  if ACursor = 0 then
    LineStart := 0;
  Before := Copy(AXaml, LineStart + 1, ACursor - LineStart);
  Open := Before.LastIndexOf('<');
  if (Open >= 0) and (Before.IndexOf('>', Open) < 0) then
    Typed := Before.Substring(Open)
  else
    Typed := '';
  Fragment := Typed + ASuggestion;

  Tags := TRegEx.Matches(Fragment, '<(/?)([A-Za-z_][\w.:\-]*)');
  for Match in Tags do
  begin
    Name := Match.Groups[2].Value;
    I := Match.Groups[2].Index - 1;
    if Name.StartsWith('x:') or Name.StartsWith('d:') or Name.StartsWith('mc:') then
      Continue;
    if Name.Contains('.') then
    begin
      // A property element: Grid.RowDefinitions, rw:TabBar.Items
      Owner := Name.Substring(0, Name.LastIndexOf('.'));
      Member := Name.Substring(Name.LastIndexOf('.') + 1);
      Exact := AVocabulary.ExactTag(Owner);
      if Exact = '' then
        Exit;
      Fix(I, Exact);
      Exact := AVocabulary.ExactAttribute(Exact, Member);
      if Exact <> '' then
        Fix(I + Length(Owner) + 1, Exact)
      else if (Member = '') or not CharInSet(Member[1], ['A'..'Z']) then
        Exit;
      Continue;
    end;
    Exact := AVocabulary.ExactTag(Name);
    if Exact = '' then
      Exit; // <button> that is no type, <Buton>, an unknown control
    Fix(I, Exact);
  end;

  // Attributes inside each start tag: their case, and no unknown lower-case names
  Tags := TRegEx.Matches(Fragment, '<([A-Za-z_][\w.:\-]*)');
  for Match in Tags do
  begin
    Tag := Match.Groups[1].Value;
    if Tag.Contains('.') then
      Continue;
    TagEnd := Fragment.IndexOf('>', Match.Index - 1);
    if TagEnd < 0 then
      TagEnd := Length(Fragment);
    Attributes := TRegEx.Matches(Copy(Fragment, Match.Index, TagEnd - Match.Index + 1),
      '\s([A-Za-z_][\w.:]*)\s*=');
    for Attribute in Attributes do
    begin
      Name := Attribute.Groups[1].Value;
      I := Match.Index - 1 + Attribute.Groups[1].Index - 1;
      if Name.Contains(':') then
      begin
        // x:Name, d:Text, mc:Ignorable, xmlns:rw; rw:Name= is no attribute
        if not (Name.StartsWith('x:') or Name.StartsWith('d:') or Name.StartsWith('mc:') or
          Name.StartsWith('xmlns:')) then
          Exit;
        Continue;
      end;
      if Name.Contains('.') then
      begin
        // An attached property: Grid.Row, AutomationProperties.Name
        Exact := AVocabulary.ExactTag(Name.Substring(0, Name.IndexOf('.')));
        if Exact <> '' then
          Fix(I, Exact);
        Continue;
      end;
      Exact := AVocabulary.ExactAttribute(Tag, Name);
      if Exact <> '' then
        Fix(I, Exact)
      else if not CharInSet(Name[1], ['A'..'Z']) then
        Exit; // content=, onclick=
    end;
  end;

  AGhost.TypedStart := LineStart + Open;
  if Typed = '' then
    AGhost.TypedStart := ACursor;
  AGhost.TypedFix := Copy(Fragment, 1, Length(Typed));
  AGhost.Text := Copy(Fragment, Length(Typed) + 1, MaxInt);
  Result := AGhost.Text <> '';
end;

function ApplyXamlGhost(const AXaml: string; ACursor: Integer; const AGhost: TXamlGhost): string;
begin
  Result := InsertXamlCompletion(AXaml, ACursor, AGhost.Text);
  if (AGhost.TypedFix <> '') and (AGhost.TypedStart >= 0) and
    (AGhost.TypedStart + Length(AGhost.TypedFix) <= ACursor) and
    SameText(Copy(AXaml, AGhost.TypedStart + 1, Length(AGhost.TypedFix)), AGhost.TypedFix) then
    Result := Copy(Result, 1, AGhost.TypedStart) + AGhost.TypedFix +
      Copy(Result, AGhost.TypedStart + Length(AGhost.TypedFix) + 1, MaxInt);
end;

{ TIndexVocabulary }

constructor TIndexVocabulary.Create(AIndex: TDesignerTypeIndex; const AUserControls: TArray<string>);
begin
  inherited Create;
  FIndex := AIndex;
  FUserControls := AUserControls;
end;

function TIndexVocabulary.ExactTag(const ATag: string): string;
var
  Control: string;
begin
  for Control in FUserControls do
    if SameText(Control, ATag) then
      Exit(Control);
  Result := FIndex.ExactTag(ATag);
end;

function TIndexVocabulary.ExactAttribute(const ATag, AName: string): string;
begin
  Result := FIndex.ExactMember(ATag, AName);
end;

function InsertXamlCompletion(const AXaml: string; ACursor: Integer; const ASuggestion: string): string;
begin
  if (ACursor < 0) or (ACursor > Length(AXaml)) then
    raise EArgumentOutOfRangeException.Create('The cursor is outside the XAML');
  Result := Copy(AXaml, 1, ACursor) + ASuggestion + Copy(AXaml, ACursor + 1, MaxInt);
end;

{ TXamlSuggestions }

constructor TXamlSuggestions.Create(ADelay: Cardinal);
begin
  inherited Create;
  FDelay := ADelay;
  FPredictions := TList<TXamlPrediction>.Create;
  FEmpty := TDictionary<string, Boolean>.Create;
end;

destructor TXamlSuggestions.Destroy;
begin
  FPredictions.Free;
  FEmpty.Free;
  inherited;
end;

function TXamlSuggestions.Key(const AText: string; ACursor: Integer): string;
begin
  Result := THashBobJenkins.GetHashString(AText) + ':' + IntToStr(Length(AText)) + ':' + IntToStr(ACursor);
end;

procedure TXamlSuggestions.Show(const AGhost: TXamlGhost);
begin
  FGhost := AGhost.Text;
  FTypedStart := AGhost.TypedStart;
  FTypedFix := AGhost.TypedFix;
end;

function TXamlSuggestions.Predict(const AText: string; ACursor: Integer): Boolean;
var
  LineStart, I: Integer;
  Before, After, Head: string;
  Prediction: TXamlPrediction;
  Ghost: TXamlGhost;
begin
  Result := False;
  LineStart := AText.LastIndexOf(#10, ACursor - 1) + 1;
  if ACursor = 0 then
    LineStart := 0;
  Before := Copy(AText, LineStart + 1, ACursor - LineStart);
  After := Copy(AText, ACursor + 1, MaxInt);
  Head := Copy(AText, 1, LineStart);
  for I := FPredictions.Count - 1 downto 0 do
  begin
    Prediction := FPredictions[I];
    // The same place, and the line typed so far leads to the predicted line (in any case)
    if (Length(Before) < Length(Prediction.Line)) and (Prediction.After = After) and (Prediction.Head = Head) and
      SameText(Before, Copy(Prediction.Line, 1, Length(Before))) then
    begin
      Ghost.Text := Prediction.Line.Substring(Length(Before));
      Ghost.TypedStart := LineStart;
      Ghost.TypedFix := Copy(Prediction.Line, 1, Length(Before)); // "<butt" is written "<Butt" on Tab
      Show(Ghost);
      Exit(True);
    end;
  end;
end;

function TXamlSuggestions.Observe(const AText: string; ACursor: Integer; ANow: UInt64): Boolean;
var
  Typed: string;
begin
  Result := False;
  if FObserved and (AText = FText) and (ACursor = FCursor) then
    Exit;
  if FObserved and (FGhost <> '') and (ACursor > FCursor) and
    (Length(AText) - Length(FText) = ACursor - FCursor) then
  begin
    // Typed the suggestion's next characters: they leave the ghost text
    Typed := Copy(AText, FCursor + 1, ACursor - FCursor);
    if FGhost.StartsWith(Typed) and
      (AText = Copy(FText, 1, FCursor) + Typed + Copy(FText, FCursor + 1, MaxInt)) then
    begin
      FGhost := FGhost.Substring(Length(Typed));
      FText := AText;
      FCursor := ACursor;
      Exit(True);
    end;
  end;
  Result := FGhost <> '';
  FGhost := '';
  FTypedFix := '';
  if FObserved and (AText = FText) then
    FDuePending := False // the cursor moved: no suggestion until the next edit
  else if FObserved then
  begin
    FDuePending := False;
    if IsXamlLineIncomplete(AText, ACursor) then
      if Predict(AText, ACursor) then
        Result := True // an earlier answer still fits: at once
      else
      begin
        FDuePending := True; // ask after the pause
        FDue := ANow + FDelay;
      end;
  end;
  FObserved := True;
  FText := AText;
  FCursor := ACursor;
end;

function TXamlSuggestions.Due(ANow: UInt64): Boolean;
begin
  Result := False;
  if FInFlight and (ANow - FSentAt > Timeout) then
    FInFlight := False;
  if not FDuePending or FInFlight or (ANow < FDue) then
    Exit;
  FDuePending := False;
  if Predict(FText, FCursor) or FEmpty.ContainsKey(Key(FText, FCursor)) then
    Exit; // answered before
  FRequestText := FText;
  FRequestCursor := FCursor;
  Result := True;
end;

procedure TXamlSuggestions.Sent(const AID: TGUID; ANow: UInt64);
begin
  FInFlight := True;
  FRequestID := AID;
  FSentAt := ANow;
end;

function TXamlSuggestions.Answered(const AID: TGUID; const AAnswer: string): Boolean;
var
  Ghost: TXamlGhost;
  Suggestion: string;
  Prediction: TXamlPrediction;
begin
  Result := False;
  if not FInFlight or (AID <> FRequestID) then
    Exit;
  FInFlight := False;
  FLastAnswer := AAnswer;
  Suggestion := FitXamlSuggestion(FRequestText, FRequestCursor, AAnswer, 1); // the rest of the line
  Ghost := Default(TXamlGhost);
  Ghost.Text := Suggestion;
  Ghost.TypedStart := FRequestCursor;
  // Ghost is the out parameter: the suggestion goes in as its own string
  if (Suggestion <> '') and (FVocabulary <> nil) and
    not CorrectXamlSuggestion(FRequestText, FRequestCursor, Suggestion, FVocabulary, Ghost) then
    Ghost := Default(TXamlGhost); // names XAML does not know: nothing is offered
  if Ghost.Text = '' then
  begin
    if FEmpty.Count >= MaxPredictions then
      FEmpty.Clear;
    FEmpty.AddOrSetValue(Key(FRequestText, FRequestCursor), True);
    Exit;
  end;
  // Kept for the line: the corrected typed part, then the suggestion
  Prediction.Head := Copy(FRequestText, 1, FRequestText.LastIndexOf(#10, FRequestCursor - 1) + 1);
  if FRequestCursor = 0 then
    Prediction.Head := '';
  Prediction.Line := Copy(ApplyXamlGhost(FRequestText, FRequestCursor, Ghost), Length(Prediction.Head) + 1,
    FRequestCursor - Length(Prediction.Head) + Length(Ghost.Text));
  Prediction.After := Copy(FRequestText, FRequestCursor + 1, MaxInt);
  if FPredictions.Count >= MaxPredictions then
    FPredictions.Delete(0);
  FPredictions.Add(Prediction);
  // Typed on meanwhile: shown when the line typed so far still leads to it
  if FGhost <> '' then
    Exit;
  if (FRequestText = FText) and (FRequestCursor = FCursor) then
  begin
    Show(Ghost);
    Exit(True);
  end;
  Result := IsXamlLineIncomplete(FText, FCursor) and Predict(FText, FCursor);
  if Result then
    FDuePending := False;
end;

procedure TXamlSuggestions.Failed(const AID: TGUID);
begin
  if FInFlight and (AID = FRequestID) then
    FInFlight := False;
end;

function TXamlSuggestions.Accept(out ANewText: string; out ANewCursor: Integer): Boolean;
var
  Ghost: TXamlGhost;
begin
  Result := FGhost <> '';
  if not Result then
    Exit;
  Ghost.Text := FGhost;
  Ghost.TypedStart := FTypedStart;
  Ghost.TypedFix := FTypedFix;
  ANewText := ApplyXamlGhost(FText, FCursor, Ghost); // "<butt" + Tab is "<Button ..."
  FTypedFix := '';
  ANewCursor := FCursor + Length(FGhost);
  FGhost := '';
  FDuePending := False;
  FText := ANewText; // the accepted text is not an edit that asks again
  FCursor := ANewCursor;
end;

procedure TXamlSuggestions.Dismiss;
begin
  FGhost := '';
  FTypedFix := '';
  FDuePending := False;
end;

end.
