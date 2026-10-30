unit RADWinUI.Preview.Host;

{
  The live preview window. It runs in its own process, never in
  RAD Studio, and renders a RADWinUI window .xaml with XamlReader.Load:

    RADWinUIPreview.exe <file.xaml>       watches the file, reloads on change
    RADWinUIPreview.exe --pipe <name>     serves \\.\pipe\<name> for the IDE
    RADWinUIPreview.exe --pipe <name> --parent <HWND>  embeds the host window in an IDE dock

  Pipe protocol, one UTF-8 message each way (message-mode pipe):
    request   LOAD <path>  LF  <xaml text>      reply   OK  or  ERROR <message>
    request   THEME Light|Dark [#AARRGGBB]     reply   OK  or  ERROR <message>
    request   RESUME                          reply   OK, restores the embedded surface
    request   HIT <x> <y>                       reply   SELECTED ...  or  NONE
    request   TOOL <name>                       reply   OK  or  DELETE ...
    request   DRAG <x1> <y1> <x2> <y2>          reply   MOVE ...  or  NONE
    request   EVENT                             reply   OK, pushes a sample event (tests)
    request   CLOSE                             (no reply, the host exits)
  SELECTED <line> <column> <type> <x:Name or ->: the start tag of the element
  the user clicked or the one under screen pixel x, y (HIT, for tests: a real
  click would take the focus). Positions are those of the text sent with LOAD,
  1-based, columns in UTF-16 characters. Events are pushed over
  a second message-mode pipe as they happen.

  Toolbox: the strip above the preview. Pick a control, then
  click where it goes: INSERT <tag> <panel line> <panel column> <index> <row>
  <column> names the StackPanel or Grid under the click, the child position
  and, in a Grid, the row and column (-1 elsewhere). Dragging the selected
  element reports MOVE <line> <column> <panel line> <panel column> <index>
  <row> <column>, the Delete button reports DELETE <line> <column>. In a Grid
  or Canvas the element goes where it is dropped instead:
  PLACE <line> <column> <panel line> <panel column> Grid|Canvas <row> <column>
  <left> <top>, and a toolbox item INSERTAT <tag> ... the same, left and top
  are DIPs from the cell's (or Canvas's) top-left. The host
  never edits the XAML: the IDE applies the event to its buffer
  (RADWinUI.Designer.XamlEdit.ApplyDesignerEvent) and sends the new text.
  TOOL and DRAG do what the buttons and a drag do, for tests, their event
  results are also pushed on the event pipe.
  The host also exits when the client disconnects, so an IDE that dies leaves
  no preview behind, the IDE starts a new host when it needs one.

  A broken update keeps the last good view and shows the error in a red bar.
  The XAML is changed as XamlCodeGen changes it, without moving any text, so
  error line numbers are those of the file: <Window> becomes a Grid with the
  same xmlns, and event attributes, x:Class, x:DataType and DataContextType
  are blanked. Design-time values win: d:Text="Sample" becomes
  Text="Sample" and the element's own Text is blanked (d:Design* and
  d:DataContext stay ignorable). Without a d: value, a bound Text, Content,
  Header or PlaceholderText shows the binding path in braces. Other bindings show nothing (no
  DataContext), converters the app registers at run time pass values through.
  Inline d:ListView.Items (also GridView, ListBox and ComboBox) supplies preview-only
  rows and overrides the parent's ItemsSource attribute. Their source positions
  remain unchanged, clicking a sample row selects the actual owning list.
}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.WinRT,
  Winapi.CommonTypes,
  System.Classes,
  System.SysUtils,
  System.Generics.Collections,
  RADWinUI.Abi,
  RADWinUI.Xaml,
  RADWinUI.Forms;

type
  TPreviewWindow = class(TWinUIWindow)
  strict private
    FErrorBar: TWinUIBorder;
    FErrorText: TWinUITextBlock;
    FShell: TWinUIGrid;
    FDesignerBackground: TWinUISolidColorBrush;
    FHost: TWinUIBorder;
    FTimer: TWinUITimer;
    FWatchPath: string;
    FWatchStamp: string;
    FSize: string;
    FParentWindow: HWND;
    FHostWindow: HWND;
    FParentSize: TPoint;
    FParentVisible: Boolean;
    FDockTimer: TWinUITimer;
    FAdorner: TWinUICanvas;
    FSelectionBox: TWinUIRectangle;
    FSelectionText: TWinUITextBlock;
    FAdornerTimer: TWinUITimer;
    FRoot: IFrameworkElement;
    FElements: TDictionary<string, string>; // x:Name or marker -> 'line column type x:Name'
    FSelected: string;
    FSelectedElement: IFrameworkElement;
    FInserts: TArray<Integer>;
    FMarkers: TArray<string>;
    FEvents: TArray<string>; // pending event-pipe messages, oldest first
    FEventLock: TRTLCriticalSection;
    FEventReady: THandle;
    FEventStop: THandle;
    FEventPipeThread: TThread;
    FTool: string;
    FPaletteText: Winapi.CommonTypes.IAsyncOperation_1__HSTRING;
    FPaletteDeferral: IDragOperationDeferral;
    FPalettePoint: RADWinUI.Abi.Point;
    FPaletteTimer: TWinUITimer;
    FPaletteStarted: Cardinal;
    FPressed: Boolean;      // pointer down on the selected element
    FDragging: Boolean;     // ... and moved: a drag
    FPressReply: string;    // SELECTED of the press, reported on release (not a drag)
    FToolDrag: string;      // toolbox item under a pressed pointer
    FPressAt: RADWinUI.Abi.Point;
    FDropMark: TWinUIRectangle;
    FDragTimer: TWinUITimer;
    FMark: RADWinUI.Abi.Rect; // set by DropTarget, in adorner coordinates
    FTargetKind: string;      // set by DropTarget: StackPanel, Grid or Canvas
    FCellOrigin: RADWinUI.Abi.Point; // set by DropTarget: the Grid cell's or Canvas's top-left, content coordinates
    FGrab: RADWinUI.Abi.Point;       // where the pointer holds the dragged element, from its top-left
    procedure PaletteDropTick(Sender: TObject);
    procedure GrabAt(const APoint: RADWinUI.Abi.Point);
    function FreeTarget: Boolean;
    procedure DragTick(Sender: TObject);
    function OverPreview(const APoint: RADWinUI.Abi.Point): Boolean;
    procedure ShowMark(AVisible: Boolean);
    procedure FitPreviewArea;
    procedure Queue(const AEvent: string);
    function ToContent(AScreenX, AScreenY: Integer): RADWinUI.Abi.Point;
    function DropTarget(const APoint: RADWinUI.Abi.Point; const AMoving: string): string;
    function PlaceAt(const APoint: RADWinUI.Abi.Point): string;
    function MoveTo(const APoint: RADWinUI.Abi.Point): string;
    function UseTool(const AName: string): string;
    function KeyOf(const AElement: IFrameworkElement): string;
    function FindByKey(const AObject: IDependencyObject; const AKey: string): IFrameworkElement;
    function Inside(AObject: IDependencyObject; const AKey: string): Boolean;
    procedure WatchTick(Sender: TObject);
    procedure ResizeDocked(Sender: TObject);
    procedure RestoreDocked;
    procedure AttachToParent(AParent: HWND);
    procedure PlaceAdorner(Sender: TObject);
    function NameElements(const AXaml, AText: string): string;
    function SelectFrom(AObject: IDependencyObject): string;
    function SelectAt(const APoint: RADWinUI.Abi.Point): string;
    procedure Select(const AName: string);
    procedure StartPipe(const AName: string);
    procedure StartEventPipe(const AName: string);
    function TakeQueuedEvent(out AEvent: string): Boolean;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Show; override;
    procedure Close; reintroduce;
    /// <summary>Shows AXaml (the text of APath), returns '' or the error it shows.</summary>
    function Load(const APath, AXaml: string): string;
    /// <summary>Runs one pipe request (LOAD, HIT, TOOL, DRAG, or test EVENT).</summary>
    function Command(const AMessage: string): string;
  end;

/// <summary>
///   AXaml ready for XamlReader.Load, every character in its place. AWindow
///   returns the <Window> Title, Width and Height as 'Title|Width|Height'.
/// </summary>
function PreviewXaml(const AXaml: string; out AWindow: string): string;

implementation

uses
  Winapi.Foundation,
  System.IOUtils,
  System.JSON,
  System.RegularExpressions,
  System.StrUtils,
  System.Character,
  System.Math,
  RADWinUI.Interop.Core,
  RADWinUI.Framework,
  RADWinUI.Designer.Palette;

const
  ToolboxWidth = 180; // DIPs added to the window so the previewed content keeps its <Window> size

  BuiltInConverters: array[0..2] of string = ('BoolToVisibility', 'InverseBoolToVisibility', 'Format');
  TagMarker = '__rw';   // Tag="__rw12" on an element without x:Name
  NameMarker = '__rwn'; // Name="__rwn12" when the element has its own Tag

var
  Events: TDictionary<string, Boolean>;
  UIElementTags: TDictionary<string, Boolean>; // XAML tags of UIElement classes
  Converters: TDictionary<string, Boolean>;
  Preview: TPreviewWindow; // nil once the window is gone (pipe thread checks it)

/// Events and tags of RADWinUI's own controls (RADWinUI.Controls.json): all of them are UIElements.
procedure LoadOwnControls(const APath: string);
var
  Json: TJSONValue;
  Cls, Ev: TJSONPair;
  Names: TJSONObject;
begin
  if not FileExists(APath) then
    Exit;
  Json := TJSONObject.ParseJSONValue(TFile.ReadAllText(APath, TEncoding.UTF8));
  try
    for Cls in (Json as TJSONObject).GetValue<TJSONObject>('classes') do
      if (Cls.JsonValue as TJSONObject).TryGetValue<TJSONObject>('events', Names) then
        for Ev in Names do
          Events.AddOrSetValue(Ev.JsonString.Value, True);
    for Ev in (Json as TJSONObject).GetValue<TJSONObject>('types') do
    begin
      UIElementTags.AddOrSetValue(Ev.JsonString.Value, True);
      UIElementTags.AddOrSetValue('rw:' + Ev.JsonString.Value, True);
    end;
  finally
    Json.Free;
  end;
end;

/// ARelative (a file under src\ of RADWinUI) for this exe: next to a preview host built in
/// src\IDE\Preview\Win64\<Config>, in RADWINUI_ROOT, or in the first folder above the exe that has
/// it, for a test or tool built elsewhere in the repository. '' when none has it.
function SourceFile(const ARelative: string): string;
var
  Dir, Parent: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..\' + ARelative);
  if FileExists(Result) then
    Exit;
  if GetEnvironmentVariable('RADWINUI_ROOT') <> '' then
  begin
    Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('RADWINUI_ROOT')) + 'src\' + ARelative;
    if FileExists(Result) then
      Exit;
  end;
  Dir := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  repeat
    Result := Dir + '\src\' + ARelative;
    if FileExists(Result) then
      Exit;
    Parent := ExtractFileDir(Dir);
    if Parent = Dir then
      Break;
    Dir := Parent;
  until Dir = '';
  Result := '';
end;

/// Event names of every XAML class, from RADWinUI.Xaml.json (WinMDGen) and RADWinUI.Controls.json.
procedure LoadEvents;
var
  Path: string;
  Json: TJSONValue;
  Cls, Ev: TJSONPair;
  Names: TJSONObject;
begin
  Events := TDictionary<string, Boolean>.Create;
  UIElementTags := TDictionary<string, Boolean>.Create;
  Path := SourceFile('Generated\RADWinUI.Xaml.json');
  if Path = '' then
    Exit; // event attributes then fail to load, with WinUI's message
  Json := TJSONObject.ParseJSONValue(TFile.ReadAllText(Path, TEncoding.UTF8));
  try
    for Cls in (Json as TJSONObject).GetValue<TJSONObject>('classes') do
      if (Cls.JsonValue as TJSONObject).TryGetValue<TJSONObject>('events', Names) then
        for Ev in Names do
          Events.AddOrSetValue(Ev.JsonString.Value, True);
    for Ev in (Json as TJSONObject).GetValue<TJSONObject>('types') do
    begin
      Path := Ev.JsonValue.Value;
      while (Path <> '') and (Path <> 'Microsoft.UI.Xaml.UIElement') do
        // GetValue(name) looks the key up as is, GetValue<T> would read its dots as a path
        if (Json as TJSONObject).GetValue<TJSONObject>('classes').GetValue(Path) is TJSONObject then
          Path := ((Json as TJSONObject).GetValue<TJSONObject>('classes').GetValue(Path) as TJSONObject)
            .GetValue<string>('base', '')
        else
          Path := '';
      if Path <> '' then
        UIElementTags.Add(Ev.JsonString.Value, True);
    end;
  finally
    Json.Free;
  end;
  LoadOwnControls(SourceFile('Framework\RADWinUI.Controls.json'));
end;

/// S with every character but line breaks turned into a space.
function Blank(const S: string): string;
var
  I: Integer;
begin
  Result := S;
  for I := 1 to Length(Result) do
    if not CharInSet(Result[I], [#10, #13]) then
      Result[I] := ' ';
end;

procedure Overwrite(var S: string; AIndex: Integer; const AText: string);
begin
  Move(PChar(AText)^, S[AIndex], Length(AText) * SizeOf(Char));
end;

const
  // Bound properties that show {Path} in the preview when there is no d: value
  Placeholders: array[0..3] of string = ('Text', 'Content', 'Header', 'PlaceholderText');

type
  /// One attribute of a start tag, indexes are 1-based in the scanned text.
  TXamlAttribute = record
    Start, Length: Integer;          // from the white space before the name to the closing quote
    NameStart, NameLength: Integer;
    ValueStart, ValueLength: Integer; // the value with its quotes
  end;

  /// One tag found by NextTag.
  TXamlTag = record
    Start, Stop: Integer; // '<' and '>'
    Name: string;
    IsEnd, SelfClosing: Boolean;
    Attributes: TArray<TXamlAttribute>;
    Count: Integer;
    function AttrName(const S: string; I: Integer): string;
    function AttrValue(const S: string; I: Integer): string; // without quotes
    function Find(const S, AName: string): Integer;           // -1 when absent
  end;

function TXamlTag.AttrName(const S: string; I: Integer): string;
begin
  Result := Copy(S, Attributes[I].NameStart, Attributes[I].NameLength);
end;

function TXamlTag.AttrValue(const S: string; I: Integer): string;
begin
  Result := Copy(S, Attributes[I].ValueStart + 1, Attributes[I].ValueLength - 2);
end;

function TXamlTag.Find(const S, AName: string): Integer;
begin
  for Result := 0 to Count - 1 do
    if AttrName(S, Result) = AName then
      Exit;
  Result := -1;
end;

function IsNameChar(C: Char): Boolean; inline;
begin
  Result := C.IsLetterOrDigit or (C = '_') or (C = ':') or (C = '.') or (C = '-');
end;

function IsSpace(C: Char): Boolean; inline;
begin
  Result := (C = ' ') or (C = #9) or (C = #10) or (C = #13);
end;

/// The next start or end tag at or after P (skipping comments and <? ?>, <! >),
/// False at the end. A hand-written scanner: regular expressions with a match
/// object per tag and attribute took about 100 ms for 3,000 elements.
function NextTag(const S: string; var P: Integer; var ATag: TXamlTag): Boolean;
var
  I, J, Len: Integer;
  Quote: Char;
  Ok: Boolean;
begin
  Len := Length(S);
  while True do
  begin
    P := Pos('<', S, P);
    if (P = 0) or (P >= Len) then
      Exit(False);
    if (S[P + 1] = '!') or (S[P + 1] = '?') then
    begin
      if Copy(S, P, 4) = '<!--' then
        I := Pos('-->', S, P + 4)
      else
        I := Pos('>', S, P + 1);
      if I = 0 then
        Exit(False);
      P := I + 1;
      Continue;
    end;
    I := P + 1;
    ATag.IsEnd := S[I] = '/';
    if ATag.IsEnd then
      Inc(I);
    if (I > Len) or not (S[I].IsLetter or (S[I] = '_')) then
    begin
      Inc(P);
      Continue;
    end;
    J := I;
    while (J <= Len) and IsNameChar(S[J]) do
      Inc(J);
    ATag.Name := Copy(S, I, J - I);
    ATag.Count := 0;
    Ok := True;
    while True do
    begin
      I := J;
      while (J <= Len) and IsSpace(S[J]) do
        Inc(J);
      if (J > Len) or (S[J] = '/') or (S[J] = '>') then
        Break;
      if (J = I) or not IsNameChar(S[J]) then
      begin
        Ok := False;
        Break;
      end;
      if ATag.Count = Length(ATag.Attributes) then
        SetLength(ATag.Attributes, ATag.Count * 2 + 4);
      ATag.Attributes[ATag.Count].Start := I;
      ATag.Attributes[ATag.Count].NameStart := J;
      while (J <= Len) and IsNameChar(S[J]) do
        Inc(J);
      ATag.Attributes[ATag.Count].NameLength := J - ATag.Attributes[ATag.Count].NameStart;
      while (J <= Len) and IsSpace(S[J]) do
        Inc(J);
      if (J > Len) or (S[J] <> '=') then
      begin
        Ok := False;
        Break;
      end;
      Inc(J);
      while (J <= Len) and IsSpace(S[J]) do
        Inc(J);
      if (J > Len) or ((S[J] <> '"') and (S[J] <> '''')) then
      begin
        Ok := False;
        Break;
      end;
      Quote := S[J];
      ATag.Attributes[ATag.Count].ValueStart := J;
      J := Pos(Quote, S, J + 1);
      if J = 0 then
        Exit(False);
      Inc(J);
      ATag.Attributes[ATag.Count].ValueLength := J - ATag.Attributes[ATag.Count].ValueStart;
      ATag.Attributes[ATag.Count].Length := J - I;
      Inc(ATag.Count);
    end;
    if Ok and (J <= Len) then
    begin
      ATag.SelfClosing := S[J] = '/';
      if ATag.SelfClosing then
        Inc(J);
      if (J <= Len) and (S[J] = '>') then
      begin
        ATag.Start := P;
        ATag.Stop := J;
        P := J + 1;
        Exit(True);
      end;
    end;
    Inc(P); // not a well-formed tag: WinUI reports it
  end;
end;

function IsIdentifier(const S: string): Boolean;
var
  I: Integer;
begin
  Result := (S <> '') and (S[1].IsLetter or (S[1] = '_'));
  for I := 2 to Length(S) do
    Result := Result and (S[I].IsLetterOrDigit or (S[I] = '_'));
end;

/// One start tag of S, changed in place: see the unit comment.
procedure PreviewTag(var S: string; const ATag: TXamlTag);
var
  I: Integer;
  Name, Value, Path, Design: string;
  A: TXamlAttribute;
begin
  Design := '|';
  for I := 0 to ATag.Count - 1 do
  begin
    Name := ATag.AttrName(S, I);
    if Name.StartsWith('d:') then
      Design := Design + Name.Substring(2) + '|';
  end;
  for I := 0 to ATag.Count - 1 do
  begin
    A := ATag.Attributes[I];
    Name := ATag.AttrName(S, I);
    if Name.StartsWith('d:') then
    begin
      // d:Text="Sample" becomes Text="Sample", d:DesignWidth and the like stay ignorable
      if not Name.StartsWith('d:Design') and not Name.StartsWith('d:DataContext') then
        Overwrite(S, A.NameStart, '  ');
      Continue;
    end;
    if (Name = 'x:Class') or (Name = 'x:DataType') or (Name = 'DataContextType') or
      Design.Contains('|' + Name + '|') or (Events.ContainsKey(Name) and IsIdentifier(ATag.AttrValue(S, I))) then
      Overwrite(S, A.Start, Blank(Copy(S, A.Start, A.Length)))
    else if MatchText(Name, Placeholders) then
    begin
      Value := ATag.AttrValue(S, I);
      if not Value.StartsWith('{Binding') then
        Continue;
      Path := TRegEx.Match(Value, '^\{Binding\s*(?:Path\s*=\s*)?([\w.]+)').Groups[1].Value;
      if Path <> '' then
        Overwrite(S, A.ValueStart, (S[A.ValueStart] + '{}{' + Path + '}' + S[A.ValueStart]).PadRight(A.ValueLength));
    end;
  end;
end;

function PreviewXaml(const AXaml: string; out AWindow: string): string;
var
  Root: TMatch;
  Tag, Parent: TXamlTag;
  Stack: TArray<Integer>;
  Name, Title, Width, Height: string;
  P, I, Close, ParentAt: Integer;
begin
  Result := AXaml;
  AWindow := '||';
  Root := TRegEx.Match(Result, '<Window\b[^>]*>');
  if Root.Success then
  begin
    // The root tag keeps only its xmlns declarations and mc:Ignorable
    P := Root.Index;
    if NextTag(Result, P, Tag) and (Tag.Start = Root.Index) then
      for I := 0 to Tag.Count - 1 do
      begin
        Name := Tag.AttrName(Result, I);
        if Name = 'Title' then Title := Tag.AttrValue(Result, I);
        if Name = 'Width' then Width := Tag.AttrValue(Result, I);
        if Name = 'Height' then Height := Tag.AttrValue(Result, I);
        if not Name.StartsWith('xmlns') and (Name <> 'mc:Ignorable') then
          Overwrite(Result, Tag.Attributes[I].Start, Blank(Copy(Result, Tag.Attributes[I].Start, Tag.Attributes[I].Length)));
      end;
    AWindow := Title + '|' + Width + '|' + Height;
    Overwrite(Result, Root.Index + 1, 'Grid  ');
    Close := Result.LastIndexOf('</Window');
    if Close >= 0 then
      Overwrite(Result, Close + 1, '</Grid  ');
  end;
  P := 1;
  while NextTag(Result, P, Tag) do
  begin
    if Tag.Name.StartsWith('d:') and Tag.Name.EndsWith('.Items') then
    begin
      // Move the d: prefix into trailing whitespace, preserving every offset.
      Overwrite(Result, Tag.Start + 1 + Ord(Tag.IsEnd), Tag.Name.Substring(2) + '  ');
      if not Tag.IsEnd and (Length(Stack) > 0) then
      begin
        ParentAt := Stack[High(Stack)];
        if NextTag(AXaml, ParentAt, Parent) and (Tag.Name = 'd:' + Parent.Name + '.Items') then
          for I := 0 to Parent.Count - 1 do
            if MatchStr(Parent.AttrName(AXaml, I), ['ItemsSource', 'd:ItemsSource']) then
              Overwrite(Result, Parent.Attributes[I].Start,
                Blank(Copy(Result, Parent.Attributes[I].Start, Parent.Attributes[I].Length)));
      end;
    end;
    if Tag.IsEnd then
    begin
      if Length(Stack) > 0 then SetLength(Stack, Length(Stack) - 1);
    end
    else
    begin
      PreviewTag(Result, Tag);
      if not Tag.SelfClosing then Stack := Stack + [Tag.Start];
    end;
  end;
end;

/// Pass-through converters for {StaticResource} names the app registers at run time.
procedure AddMissingConverters(const AXaml: string);
var
  M: TMatch;
begin
  for M in TRegEx.Matches(AXaml, 'Converter\s*=\s*\{StaticResource\s+(\w+)\s*\}') do
    if not Converters.ContainsKey(M.Groups[1].Value) then
    begin
      Converters.Add(M.Groups[1].Value, True);
      TWinUIApp.RegisterConverter(M.Groups[1].Value,
        function(const AValue: TWinValue; const AParameter: string): TWinValue
        begin
          Result := AValue;
        end);
    end;
end;

/// The toolbox column: the Tool Palette's categories and controls (RADWinUI.Designer.Palette),
/// then Delete. Items are Borders, not Buttons: Buttons keep the pointer, and an item
/// must be draggable onto the preview.
function ToolItems: string;
var
  Entry: TPaletteEntry;
  Category: string;
begin
  Result := '';
  Category := '';
  for Entry in PaletteEntries do
  begin
    if Entry.Category <> Category then
    begin
      Category := Entry.Category;
      Result := Result + '<TextBlock Text="' + Category + '" FontSize="11" Opacity="0.65" Margin="6,10,0,2"/>';
    end;
    Result := Result + '<Border x:Name="Tool_' + Entry.Name + '" Padding="8,2" CornerRadius="4" Background="Transparent">' +
      '<TextBlock AutomationProperties.AutomationId="ToolText_' + Entry.Name + '" Text="TWinUI' + Entry.Name +
      '" FontSize="13" TextTrimming="CharacterEllipsis"/></Border>';
  end;
  Result := Result + '<Border x:Name="Tool_Delete" Padding="10,4" CornerRadius="4" Margin="0,12,0,0" Background="Transparent">' +
    '<TextBlock AutomationProperties.AutomationId="ToolText_Delete" Text="Delete"/></Border>';
end;

function ShellXaml: string;
begin
  Result :=
    '<Grid x:Name="PreviewShell" xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' +
    '<Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition/><RowDefinition Height="Auto"/></Grid.RowDefinitions>' +
    '<Grid.ColumnDefinitions><ColumnDefinition Width="180"/><ColumnDefinition/></Grid.ColumnDefinitions>' +
    '<Border x:Name="ErrorBar" Grid.ColumnSpan="2" Visibility="Collapsed" Background="#FFC42B1C" Padding="12,8">' +
    '<TextBlock x:Name="ErrorText" AutomationProperties.AutomationId="PreviewError" ' +
    'Foreground="White" TextWrapping="Wrap" IsTextSelectionEnabled="True"/></Border>' +
    '<ScrollViewer x:Name="ToolboxScroll" Grid.Row="1" VerticalScrollBarVisibility="Auto" ' +
    'Background="{ThemeResource LayerFillColorDefaultBrush}">' +
    '<StackPanel x:Name="Toolbox" Padding="4" Spacing="2" Background="Transparent">' + ToolItems + '</StackPanel></ScrollViewer>' +
    // The previewed content scrolls when it is bigger than the window, and fills it when smaller
    '<ScrollViewer x:Name="PreviewScroll" Grid.Row="1" Grid.Column="1" HorizontalScrollBarVisibility="Auto" ' +
    'VerticalScrollBarVisibility="Auto"><Grid x:Name="PreviewArea">' +
    '<Border x:Name="PreviewHost"/>' +
    '<Canvas x:Name="Adorner" Background="Transparent">' +
    '<Rectangle x:Name="SelectionBox" Visibility="Collapsed" Stroke="#FF0078D4" StrokeThickness="2"/>' +
    '<Rectangle x:Name="DropMark" Visibility="Collapsed" Fill="#C00078D4" RadiusX="2" RadiusY="2"/></Canvas>' +
    '</Grid></ScrollViewer>' +
    '<TextBlock x:Name="SelectionText" AutomationProperties.AutomationId="PreviewSelection" Grid.Row="2" ' +
    'Grid.ColumnSpan="2" Margin="8,4" Opacity="0.7" Text="Click an element to select it"/></Grid>';
end;

{ TPreviewWindow }

constructor TPreviewWindow.Create;
var
  ParentValue: UInt64;
begin
  inherited;
  InitializeCriticalSection(FEventLock);
  FEventReady := 0;
  FEventStop := 0;
  Title := 'RADWinUI Preview';
  Width := 640;
  Height := 480;
  LoadContent(ShellXaml);
  FShell := FindElement<TWinUIGrid>('PreviewShell');
  FErrorBar := FindElement<TWinUIBorder>('ErrorBar');
  FErrorText := FindElement<TWinUITextBlock>('ErrorText');
  FHost := FindElement<TWinUIBorder>('PreviewHost');
  FAdorner := FindElement<TWinUICanvas>('Adorner');
  (TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement).IsTabStop := True;
  FSelectionBox := FindElement<TWinUIRectangle>('SelectionBox');
  FSelectionText := FindElement<TWinUITextBlock>('SelectionText');
  FElements := TDictionary<string, string>.Create;
  FAdornerTimer := TWinUITimer.Create;
  FAdornerTimer.Interval := 200; // follows layout changes of the selected element
  FAdornerTimer.OnTimer := PlaceAdorner;
  FDropMark := FindElement<TWinUIRectangle>('DropMark');
  (TWinUIObject.IntfOf(FShell, IUIElement) as IUIElement).add_PreviewKeyDown(TKeyEventHandler.Create(
    procedure(ASender: IInspectable; AArgs: IKeyRoutedEventArgs)
    begin
      if (Ord(AArgs.Key) = VK_F9) and (GetAsyncKeyState(VK_SHIFT) >= 0) and
        (GetAsyncKeyState(VK_MENU) >= 0) then
      begin
        if not AArgs.KeyStatus.WasKeyDown then
          if GetAsyncKeyState(VK_CONTROL) < 0 then Queue('COMPILE') else Queue('RUN');
        AArgs.Handled := True;
        Exit;
      end;
      if AArgs.Key = RADWinUI.Abi.VirtualKey.F12 then
      begin
        Queue('CODEVIEW');
        AArgs.Handled := True;
      end;
      if (Ord(AArgs.Key) = VK_DELETE) and (GetAsyncKeyState(VK_CONTROL) >= 0) and (FSelected <> '') then
      begin
        Queue('DELETEKEY');
        AArgs.Handled := True;
      end;
      if GetAsyncKeyState(VK_CONTROL) < 0 then
      begin
        if AArgs.Key = RADWinUI.Abi.VirtualKey.C then
          Queue('COPY')
        else if AArgs.Key = RADWinUI.Abi.VirtualKey.V then
          Queue('PASTE')
        else if AArgs.Key = RADWinUI.Abi.VirtualKey.Z then
        begin
          if GetAsyncKeyState(VK_SHIFT) < 0 then Queue('REDO') else Queue('UNDO');
        end
        else if AArgs.Key = RADWinUI.Abi.VirtualKey.Y then
          Queue('REDO')
        else
          Exit;
        AArgs.Handled := True;
      end;
    end));
  // The transparent adorner canvas lies over the preview and takes every click, so the
  // previewed controls never react (no button presses, no text box focus): design mode.
  // A press selects, the selection is reported on release, after a drag the move is.
  (TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement).add_PointerPressed(TPointerEventHandler.Create(
    procedure(ASender: IInspectable; AArgs: IPointerRoutedEventArgs)
    begin
      (TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement).Focus(RADWinUI.Abi.FocusState.Pointer);
      FPressAt := AArgs.GetCurrentPoint(nil).Position;
      if FTool <> '' then
      begin
        Queue(PlaceAt(FPressAt));
        ShowMark(False);
      end
      else
      begin
        FPressReply := SelectAt(FPressAt);
        GrabAt(FPressAt);
        FPressed := True;
        FDragging := False;
        // The drag follows the cursor itself: WinUI took the pointer capture away from
        // the canvas a few moves into a real drag
        FDragTimer.Enabled := True;
      end;
      AArgs.Handled := True;
    end));
  (TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement).add_PointerMoved(TPointerEventHandler.Create(
    procedure(ASender: IInspectable; AArgs: IPointerRoutedEventArgs)
    begin
      if (FTool <> '') and not FPressed then
        ShowMark(DropTarget(AArgs.GetCurrentPoint(nil).Position, '') <> '');
    end));
  (TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement).add_PointerExited(TPointerEventHandler.Create(
    procedure(ASender: IInspectable; AArgs: IPointerRoutedEventArgs)
    begin
      if not FPressed then
        ShowMark(False);
    end));
  FDragTimer := TWinUITimer.Create;
  FDragTimer.Interval := 15;
  FDragTimer.OnTimer := DragTick;
  (TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement).add_DoubleTapped(TDoubleTappedEventHandler.Create(
    procedure(ASender: IInspectable; AArgs: IDoubleTappedRoutedEventArgs)
    var
      Selection: string;
    begin
      FDragTimer.Enabled := False;
      FPressed := False;
      FDragging := False;
      ShowMark(False);
      Selection := SelectAt(AArgs.GetPosition(nil));
      if Selection <> 'NONE' then
        Queue('DEFAULT ' + Selection);
      AArgs.Handled := True;
    end));
  // The native WinUI target receives OLE palette drags across the process boundary.
  FAdorner.AllowDrop := True;
  (TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement).add_DragOver(TDragEventHandler.Create(
    procedure(ASender: IInspectable; AArgs: IDragEventArgs)
    var
      Data: Winapi.CommonTypes.IDataPackageView;
      TextFormat: TWinString;
    begin
      TextFormat := 'Text';
      AArgs.AcceptedOperation := 0;
      ShowMark(False);
      if Supports(AArgs.DataView, Winapi.CommonTypes.IDataPackageView, Data) and
        Data.Contains(Winapi.WinRT.HSTRING(TextFormat.Handle)) and (DropTarget(AArgs.GetPosition(nil), '') <> '') then
      begin
        AArgs.AcceptedOperation := 1; // Windows DataPackageOperation.Copy
        ShowMark(True);
      end;
      AArgs.Handled := True;
    end));
  (TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement).add_DragLeave(TDragEventHandler.Create(
    procedure(ASender: IInspectable; AArgs: IDragEventArgs)
    begin
      ShowMark(False);
      AArgs.Handled := True;
    end));
  FPaletteTimer := TWinUITimer.Create;
  FPaletteTimer.Interval := 15;
  FPaletteTimer.OnTimer := PaletteDropTick;
  (TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement).add_Drop(TDragEventHandler.Create(
    procedure(ASender: IInspectable; AArgs: IDragEventArgs)
    var
      Data: Winapi.CommonTypes.IDataPackageView;
      TextFormat: TWinString;
    begin
      ShowMark(False);
      TextFormat := 'Text';
      if (FPaletteText = nil) and Supports(AArgs.DataView, Winapi.CommonTypes.IDataPackageView, Data) and
        Data.Contains(Winapi.WinRT.HSTRING(TextFormat.Handle)) then
      begin
        FPalettePoint := AArgs.GetPosition(nil);
        FPaletteText := Data.GetTextAsync;
        FPaletteDeferral := AArgs.GetDeferral;
        FPaletteStarted := GetTickCount;
        FPaletteTimer.Enabled := True;
        AArgs.AcceptedOperation := 1;
      end;
      AArgs.Handled := True;
    end));
  // Toolbox: click an item, then click in the preview, or drag the item onto the preview
  (TWinUIObject.IntfOf(FindElement<TWinUIStackPanel>('Toolbox'), IUIElement) as IUIElement).add_PointerPressed(
    TPointerEventHandler.Create(
      procedure(ASender: IInspectable; AArgs: IPointerRoutedEventArgs)
      var
        Obj: IDependencyObject;
        Name: string;
      begin
        FToolDrag := '';
        Supports((AArgs as IRoutedEventArgs).OriginalSource, IDependencyObject, Obj);
        while (Obj <> nil) and (FToolDrag = '') do
        begin
          if Supports(Obj, IFrameworkElement) then
          begin
            Name := TakeHString((Obj as IFrameworkElement).get_Name);
            if Name.StartsWith('Tool_') then
              FToolDrag := Name.Substring(5);
          end;
          Obj := VisualTreeHelper.GetParent(Obj);
        end;
        if FToolDrag <> '' then
          (ASender as IUIElement).CapturePointer(AArgs.Pointer);
        AArgs.Handled := True;
      end));
  (TWinUIObject.IntfOf(FindElement<TWinUIStackPanel>('Toolbox'), IUIElement) as IUIElement).add_PointerMoved(
    TPointerEventHandler.Create(
      procedure(ASender: IInspectable; AArgs: IPointerRoutedEventArgs)
      var
        At: RADWinUI.Abi.Point;
      begin
        if (FToolDrag = '') or (FToolDrag = 'Delete') then
          Exit;
        At := AArgs.GetCurrentPoint(nil).Position;
        ShowMark(OverPreview(At) and (DropTarget(At, '') <> ''));
      end));
  (TWinUIObject.IntfOf(FindElement<TWinUIStackPanel>('Toolbox'), IUIElement) as IUIElement).add_PointerReleased(
    TPointerEventHandler.Create(
      procedure(ASender: IInspectable; AArgs: IPointerRoutedEventArgs)
      var
        At: RADWinUI.Abi.Point;
      begin
        At := AArgs.GetCurrentPoint(nil).Position;
        if FToolDrag <> '' then
          if OverPreview(At) and (FToolDrag <> 'Delete') then
          begin
            FTool := FToolDrag;  // dropped on the preview
            Queue(PlaceAt(At));
          end
          else
            Queue(UseTool(FToolDrag)); // a click: pick it, then click in the preview
        FToolDrag := '';
        ShowMark(False);
        (ASender as IUIElement).ReleasePointerCaptures;
        AArgs.Handled := True;
      end));
  FindElement<TWinUIScrollViewer>('PreviewScroll').SizeChanged.Add(
    procedure(Sender: TObject; E: TWinUISizeChangedEventArgs)
    begin
      FitPreviewArea;
    end);
  Preview := Self;
  if (ParamCount = 2) and SameText(ParamStr(1), '--pipe') then
    StartPipe(ParamStr(2))
  else if (ParamCount = 4) and SameText(ParamStr(1), '--pipe') and SameText(ParamStr(3), '--parent') then
  begin
    if TryStrToUInt64(ParamStr(4), ParentValue) and (ParentValue <> 0) then
    begin
      AttachToParent(HWND(NativeUInt(ParentValue)));
      StartPipe(ParamStr(2));
    end
    else
      Load('', '<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Margin="24" ' +
        'Text="Invalid preview parent window handle"/>');
  end
  else if ParamCount = 1 then
  begin
    FWatchPath := ExpandFileName(ParamStr(1));
    FTimer := TWinUITimer.Create;
    FTimer.Interval := 250;
    FTimer.OnTimer := WatchTick;
    WatchTick(nil);
    FTimer.Enabled := True;
  end
  else
    Load('', '<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Margin="24" ' +
      'Text="Usage: RADWinUIPreview &lt;file.xaml&gt;  or  RADWinUIPreview --pipe &lt;name&gt;"/>');
end;

procedure TPreviewWindow.AttachToParent(AParent: HWND);
var
  WindowHandle: HWND;
  Style: NativeInt;
  Error: Cardinal;
  Hidden: TWinUIGridLength;
begin
  if not IsWindow(AParent) then
    raise EArgumentException.Create('The docked preview parent is not a window');
  // The IDE Tool Palette and Properties panel replace these standalone host controls.
  FindElement<TWinUIScrollViewer>('ToolboxScroll').Visibility := TWinUIVisibility.Collapsed;
  FSelectionText.Visibility := TWinUIVisibility.Collapsed;
  Hidden.Value := 0;
  Hidden.GridUnitType := RADWinUI.Abi.GridUnitType.Pixel;
  FShell.ColumnDefinitions[0].Width := Hidden;
  WindowHandle := HWND(AppWindow.Id.Value);
  FHostWindow := WindowHandle;
  SetLastError(ERROR_SUCCESS);
  Style := GetWindowLongPtr(WindowHandle, GWL_STYLE);
  if (Style = 0) and (GetLastError <> ERROR_SUCCESS) then
    RaiseLastOSError;
  SetLastError(ERROR_SUCCESS);
  if (SetWindowLongPtr(WindowHandle, GWL_STYLE,
    (Style and not (WS_POPUP or WS_CAPTION or WS_THICKFRAME or WS_SYSMENU or WS_MINIMIZEBOX or WS_MAXIMIZEBOX or
      WS_VISIBLE)) or WS_CHILD) = 0) and (GetLastError <> ERROR_SUCCESS) then
    RaiseLastOSError;
  SetLastError(ERROR_SUCCESS);
  if (SetParent(WindowHandle, AParent) = 0) and (GetLastError <> ERROR_SUCCESS) then
  begin
    Error := GetLastError;
    SetWindowLongPtr(WindowHandle, GWL_STYLE, Style);
    raise EOSError.CreateFmt('Cannot dock the preview window: %s', [SysErrorMessage(Error)]);
  end;
  FParentWindow := AParent;
  FParentVisible := IsWindowVisible(AParent);
  if not SetWindowPos(WindowHandle, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or
    SWP_NOACTIVATE or SWP_FRAMECHANGED) then
    RaiseLastOSError;
  ResizeDocked(nil);
  FDockTimer := TWinUITimer.Create;
  FDockTimer.Interval := 100;
  FDockTimer.OnTimer := ResizeDocked;
  FDockTimer.Enabled := True;
end;

procedure TPreviewWindow.ResizeDocked(Sender: TObject);
var
  Area: TRect;
  WindowHandle: HWND;
  Width, Height: Integer;
begin
  if FParentWindow = 0 then
    Exit;
  if not IsWindow(FParentWindow) or not IsWindow(FHostWindow) then
  begin
    if FDockTimer <> nil then
      FDockTimer.Enabled := False;
    Close;
    Exit;
  end;
  if not IsWindowVisible(FParentWindow) then
  begin
    FParentVisible := False;
    Exit;
  end;
  if not FParentVisible then
  begin
    RestoreDocked;
    Exit;
  end;
  if not GetClientRect(FParentWindow, Area) then
    Exit;
  Width := Area.Right - Area.Left;
  Height := Area.Bottom - Area.Top;
  if (Width <= 0) or (Height <= 0) or ((Width = FParentSize.X) and (Height = FParentSize.Y)) then
    Exit;
  WindowHandle := FHostWindow;
  if not SetWindowPos(WindowHandle, 0, 0, 0, Width, Height, SWP_NOZORDER or SWP_NOACTIVATE) then
    RaiseLastOSError;
  FParentSize.X := Width;
  FParentSize.Y := Height;
end;

procedure TPreviewWindow.RestoreDocked;
begin
  if (FParentWindow = 0) or not IsWindowVisible(FParentWindow) then Exit;
  if not IsWindow(FHostWindow) then
  begin
    Close;
    Exit;
  end;
  // Restore on the WinUI thread, after the IDE has shown/reparented its frame.
  // Keep the loaded visual tree: F12 must not parse the same XAML again.
  FParentVisible := True;
  FParentSize := Default(TPoint);
  SendMessage(FHostWindow, WM_SETREDRAW, 1, 0);
  ResizeDocked(nil);
  ShowWindow(FHostWindow, SW_SHOWNA);
  FShell.InvalidateMeasure;
  FShell.UpdateLayout;
  RedrawWindow(FHostWindow, nil, 0, RDW_INVALIDATE or RDW_ALLCHILDREN);
end;

procedure TPreviewWindow.Show;
begin
  if FParentWindow = 0 then
    inherited Show
  else
  begin
    ResizeDocked(nil);
    ShowWindow(FHostWindow, SW_SHOWNA);
  end;
end;

procedure TPreviewWindow.Close;
begin
  if FParentWindow = 0 then
    inherited Close
  else
  begin
    // WinUI's Window.Close blocks for a reparented child window, the host is disposable.
    ExitProcess(0);
  end;
end;

destructor TPreviewWindow.Destroy;
begin
  Preview := nil;
  if FEventStop <> 0 then
    SetEvent(FEventStop);
  if FEventPipeThread <> nil then
  begin
    FEventPipeThread.WaitFor;
    FEventPipeThread.Free;
  end;
  if FEventReady <> 0 then
    CloseHandle(FEventReady);
  if FEventStop <> 0 then
    CloseHandle(FEventStop);
  DeleteCriticalSection(FEventLock);
  FDockTimer.Free;
  FTimer.Free;
  FAdornerTimer.Free;
  FDragTimer.Free;
  FPaletteTimer.Free;
  if FPaletteDeferral <> nil then
    FPaletteDeferral.Complete;
  FElements.Free;
  inherited;
end;

function TPreviewWindow.Load(const APath, AXaml: string): string;
var
  Text, Window, Caption: string;
  Parts: TArray<string>;
  Element: IUIElement;
begin
  Result := '';
  try
    AddMissingConverters(AXaml);
    Text := NameElements(AXaml, PreviewXaml(AXaml, Window));
    if not Supports(RADWinUI.Abi.XamlReader.Load(WinStr(Text)), IUIElement, Element) then
      raise Exception.Create('The root must be a UI element (a panel or a control)');
    (TWinUIObject.IntfOf(FHost, IBorder) as IBorder).Child := Element;
    Supports(Element, IFrameworkElement, FRoot);
    Select(FSelected); // the same element after an edit, when it still exists
    FErrorBar.Visibility := TWinUIVisibility.Collapsed;
    Parts := Window.Split(['|']);
    Caption := ExtractFileName(APath);
    if Parts[0] <> '' then
      Caption := Parts[0] + ' - ' + Caption;
    Title := 'RADWinUI Preview: ' + Caption;
    if (Parts[1] + 'x' + Parts[2] <> FSize) and (Parts[1] <> '') and (Parts[2] <> '') then
    begin
      FSize := Parts[1] + 'x' + Parts[2];
      if FParentWindow = 0 then
      begin
        Width := StrToInt(Parts[1]) + ToolboxWidth;
        Height := StrToInt(Parts[2]) + 28; // the status line
      end;
    end;
  except
    on E: Exception do
    begin
      Result := StringReplace(Trim(E.Message), sLineBreak, ' ', [rfReplaceAll]);
      if APath <> '' then
        Result := ExtractFileName(APath) + ': ' + Result;
      FErrorText.Text := Result;
      FErrorBar.Visibility := TWinUIVisibility.Visible;
    end;
  end;
end;

/// AText with a marker on every UI element without x:Name, so a click finds its
/// start tag, fills FElements (key: x:Name or marker). The marker is a Tag:
/// WinUI loads 3,000 generated Names about 50 ms slower than 3,000 Tags. It
/// is a Name when the element has its own Tag. Markers only add characters
/// within a line, so error lines stay those of AXaml.
function TPreviewWindow.NameElements(const AXaml, AText: string): string;
var
  Tag: TXamlTag;
  Key, UserName, Marker: string;
  Line, Column, Position, P, Depth, Count, Skip, I: Integer;
  Builder: TStringBuilder;
begin
  FElements.Clear;
  Line := 1;
  Column := 1;
  Position := 1;
  Depth := 0;
  Count := 0;
  // The first start tag is the Grid that was <Window>
  Skip := Ord(TRegEx.IsMatch(AXaml, '^\s*(<\?[^>]*>\s*)?(<!--.*?-->\s*)*<Window\b', [roSingleLine]));
  Builder := TStringBuilder.Create(Length(AText) + 4096);
  try
    P := 1;
    while NextTag(AText, P, Tag) do
    begin
      while Position < Tag.Start do
      begin
        if AText[Position] = #10 then
        begin
          Inc(Line);
          Column := 1;
        end
        else
          Inc(Column);
        Inc(Position);
      end;
      if (Tag.Name.EndsWith('Template') and not Tag.Name.Contains('.')) or
        (Copy(AXaml, Tag.Start + 1 + Ord(Tag.IsEnd), 2) = 'd:') then
      begin
        if Tag.IsEnd then
          Dec(Depth)
        else if not Tag.SelfClosing then
          Inc(Depth);
        Continue;
      end;
      if Tag.IsEnd then
        Continue;
      if Skip > 0 then
      begin
        Dec(Skip);
        Continue;
      end;
      if (Depth > 0) or not UIElementTags.ContainsKey(Tag.Name) then
        Continue;
      UserName := '';
      for I := 0 to Tag.Count - 1 do
        if (Tag.AttrName(AText, I) = 'x:Name') or (Tag.AttrName(AText, I) = 'Name') then
          UserName := Tag.AttrValue(AText, I);
      Key := UserName;
      if Key = '' then
      begin
        Inc(Count);
        if Tag.Find(AText, 'Tag') < 0 then
        begin
          Key := TagMarker + IntToStr(Count);
          Marker := ' Tag="' + Key + '"';
        end
        else
        begin
          Key := NameMarker + IntToStr(Count);
          Marker := ' Name="' + Key + '"';
        end;
        // Inserted right after the tag name
        I := Tag.Start + 1 + Length(Tag.Name);
        UserName := '-';
        FInserts := FInserts + [I];
        FMarkers := FMarkers + [Marker];
      end;
      FElements.AddOrSetValue(Key, Format('%d %d %s %s', [Line, Column, Tag.Name, UserName]));
    end;
    // One pass: inserting into the text one marker at a time copies it once per marker
    Position := 1;
    for I := 0 to High(FInserts) do
    begin
      Builder.Append(AText, Position - 1, FInserts[I] - Position).Append(FMarkers[I]);
      Position := FInserts[I];
    end;
    Builder.Append(AText, Position - 1, Length(AText) - Position + 1);
    Result := Builder.ToString;
  finally
    Builder.Free;
    FInserts := nil;
    FMarkers := nil;
  end;
end;

/// The FElements key of AElement: its Name when known, else its Tag marker.
function TPreviewWindow.KeyOf(const AElement: IFrameworkElement): string;
begin
  Result := TakeHString(AElement.get_Name);
  if not FElements.ContainsKey(Result) then
    Result := TWinValue(AElement.Tag).AsString;
end;

/// The SELECTED reply for the nearest element at or above AObject that has a start tag.
function TPreviewWindow.SelectFrom(AObject: IDependencyObject): string;
var
  Element: IFrameworkElement;
  Key: string;
begin
  while AObject <> nil do
  begin
    if Supports(AObject, IFrameworkElement, Element) then
    begin
      Key := KeyOf(Element);
      if FElements.ContainsKey(Key) then
      begin
        Select(Key);
        FSelectedElement := Element;
        Exit('SELECTED ' + FElements[Key]);
      end;
    end;
    AObject := VisualTreeHelper.GetParent(AObject);
  end;
  Result := 'NONE';
end;

/// The element with key AKey under AObject (Tag markers are not in the name scope).
function TPreviewWindow.FindByKey(const AObject: IDependencyObject; const AKey: string): IFrameworkElement;
var
  I: Integer;
begin
  if Supports(AObject, IFrameworkElement, Result) and (KeyOf(Result) = AKey) then
    Exit;
  for I := 0 to VisualTreeHelper.GetChildrenCount(AObject) - 1 do
  begin
    Result := FindByKey(VisualTreeHelper.GetChild(AObject, I), AKey);
    if Result <> nil then
      Exit;
  end;
  Result := nil;
end;

/// Selects the topmost element at APoint (window content coordinates, DIPs).
function TPreviewWindow.SelectAt(const APoint: RADWinUI.Abi.Point): string;
var
  Hits: IIterator_UIElement;
begin
  // All elements, not only hit-testable ones: panels without a background count too
  Hits := VisualTreeHelper.FindAllElementsInHostCoordinatesPoint(APoint,
    TWinUIObject.IntfOf(FHost, IUIElement) as IUIElement, True).First;
  if Hits.HasCurrent then
    Result := SelectFrom(Hits.Current as IDependencyObject)
  else
    Result := 'NONE';
end;

procedure TPreviewWindow.Select(const AName: string);
var
  Parts: TArray<string>;
begin
  if (AName = '') or not FElements.ContainsKey(AName) then
  begin
    FSelected := '';
    FSelectedElement := nil;
    FSelectionBox.Visibility := TWinUIVisibility.Collapsed;
    FSelectionText.Text := 'Click an element to select it';
    FAdornerTimer.Enabled := False;
    Exit;
  end;
  FSelected := AName;
  FSelectedElement := nil; // PlaceAdorner finds it once the content has its visual tree
  Parts := FElements[AName].Split([' ']);
  if Parts[3] = '-' then
    FSelectionText.Text := Format('%s  (line %s, column %s)', [Parts[2], Parts[0], Parts[1]])
  else
    FSelectionText.Text := Format('%s %s  (line %s, column %s)', [Parts[2], Parts[3], Parts[0], Parts[1]]);
  FSelectionBox.Visibility := TWinUIVisibility.Visible;
  PlaceAdorner(nil);
  FAdornerTimer.Enabled := True;
end;

procedure TPreviewWindow.PlaceAdorner(Sender: TObject);
var
  Element: IFrameworkElement;
  Box: IUIElement;
  Origin: RADWinUI.Abi.Point;
begin
  if (FRoot = nil) or (FSelected = '') then
    Exit;
  if FSelectedElement = nil then
    FSelectedElement := FindByKey(FRoot as IDependencyObject, FSelected);
  Element := FSelectedElement;
  if Element = nil then
    Exit;
  Box := TWinUIObject.IntfOf(FSelectionBox, IUIElement) as IUIElement;
  Origin.X := 0;
  Origin.Y := 0;
  Origin := (Element as IUIElement).TransformToVisual(TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement)
    .TransformPoint(Origin);
  Canvas.SetLeft(Box, Origin.X);
  Canvas.SetTop(Box, Origin.Y);
  FSelectionBox.Width := Element.ActualWidth;
  FSelectionBox.Height := Element.ActualHeight;
end;

function TPreviewWindow.Command(const AMessage: string): string;
var
  Line: Integer;
  Request: string;
  Parts: TArray<string>;
  At: RADWinUI.Abi.Point;
  ThemeColor: UInt64;
  Color: TWinUIColor;
  Pair: TPair<string, string>;
  Position: TArray<string>;
begin
  Line := AMessage.IndexOf(#10);
  if Line < 0 then
    Request := AMessage
  else
    Request := AMessage.Substring(0, Line).TrimRight;
  if Request = 'HELLO' then
    Result := 'RADWINUI-DESIGNER 6'
  else if Request = 'RESUME' then
  begin
    RestoreDocked;
    Result := 'OK';
  end
  else if Request.StartsWith('SELECTPOS ') then
  begin
    Parts := Request.Split([' ']);
    if Length(Parts) <> 3 then Exit('ERROR invalid selection');
    for Pair in FElements do
    begin
      Position := Pair.Value.Split([' ']);
      if (Position[0] = Parts[1]) and (Position[1] = Parts[2]) then
      begin
        Select(Pair.Key);
        Exit('SELECTED ' + Pair.Value);
      end;
    end;
    Select('');
    Result := 'NONE';
  end
  else if Request.StartsWith('LOAD ') then
  begin
    Result := Load(Request.Substring(5), AMessage.Substring(Line + 1));
    if Result = '' then
      Result := 'OK'
    else
      Result := 'ERROR ' + Result;
  end
  else if Request.StartsWith('THEME ') then
  begin
    Parts := Request.Split([' ']);
    if (Length(Parts) < 2) or (Length(Parts) > 3) or
      not (SameText(Parts[1], 'Light') or SameText(Parts[1], 'Dark')) then
      Exit('ERROR invalid theme');
    if Length(Parts) = 3 then
    begin
      if (Length(Parts[2]) <> 9) or (Parts[2][1] <> '#') or
        not TryStrToUInt64('$' + Copy(Parts[2], 2, 8), ThemeColor) then
        Exit('ERROR invalid theme color');
      Color.A := Byte(ThemeColor shr 24);
      Color.R := Byte(ThemeColor shr 16);
      Color.G := Byte(ThemeColor shr 8);
      Color.B := Byte(ThemeColor);
      if FDesignerBackground = nil then
      begin
        FDesignerBackground := TWinUISolidColorBrush.Create(Self);
        FShell.Background := FDesignerBackground;
      end;
      FDesignerBackground.Color := Color;
    end;
    if SameText(Parts[1], 'Dark') then
      FShell.RequestedTheme := TWinUIElementTheme.Dark
    else
      FShell.RequestedTheme := TWinUIElementTheme.Light;
    Result := 'OK';
  end
  else if Request = 'EVENT' then
  begin
    Queue('SELECTED 1 1 TextBlock Test');
    Result := 'OK';
  end
  else if Request.StartsWith('HIT ') then
  begin
    Parts := Request.Split([' ']);
    At := ToContent(StrToIntDef(Parts[1], 0), StrToIntDef(Parts[2], 0));
    if FTool <> '' then
      Result := PlaceAt(At)
    else
      Result := SelectAt(At);
    Queue(Result);
  end
  else if Request.StartsWith('ADD ') then
  begin
    UseTool('');
    UseTool(Request.Substring(4));
    if FTool = '' then
      Exit('ERROR unknown component');
    At.X := 0;
    At.Y := 0;
    if FSelectedElement <> nil then
      At := (FSelectedElement as IUIElement).TransformToVisual(nil).TransformPoint(At)
    else
      At := (TWinUIObject.IntfOf(FHost, IUIElement) as IUIElement).TransformToVisual(nil).TransformPoint(At);
    At.X := At.X + 24;
    At.Y := At.Y + 24;
    Result := PlaceAt(At);
    Queue(Result);
  end
  else if (Request = 'TOOL') or Request.StartsWith('TOOL ') then
  begin
    if Request = 'TOOL' then
      Result := UseTool('')
    else
      Result := UseTool(Request.Substring(5));
    Queue(Result);
  end
  else if Request.StartsWith('DRAG ') then
  begin
    Parts := Request.Split([' ']);
    At := ToContent(StrToIntDef(Parts[1], 0), StrToIntDef(Parts[2], 0));
    if SelectAt(At) = 'NONE' then
      Exit('NONE');
    GrabAt(At);
    Result := MoveTo(ToContent(StrToIntDef(Parts[3], 0), StrToIntDef(Parts[4], 0)));
    Queue(Result);
  end
  else
    Result := 'ERROR unknown request ' + Request;
end;

procedure TPreviewWindow.Queue(const AEvent: string);
begin
  if (AEvent <> '') and (AEvent <> 'NONE') and (AEvent <> 'OK') then
  begin
    EnterCriticalSection(FEventLock);
    try
      FEvents := FEvents + [AEvent];
      if FEventReady <> 0 then
        SetEvent(FEventReady);
    finally
      LeaveCriticalSection(FEventLock);
    end;
  end;
end;

function TPreviewWindow.TakeQueuedEvent(out AEvent: string): Boolean;
begin
  EnterCriticalSection(FEventLock);
  try
    Result := FEvents <> nil;
    if Result then
    begin
      AEvent := FEvents[0];
      Delete(FEvents, 0, 1);
      if FEvents = nil then
        ResetEvent(FEventReady);
    end;
  finally
    LeaveCriticalSection(FEventLock);
  end;
end;

/// A screen pixel as window content coordinates (DIPs).
function TPreviewWindow.ToContent(AScreenX, AScreenY: Integer): RADWinUI.Abi.Point;
var
  Pixel: TPoint;
  Scale: Double;
  WindowHandle: HWND;
begin
  Pixel := TPoint.Create(AScreenX, AScreenY);
  // AppWindow may become unavailable after SetParent, FHostWindow was saved before docking.
  WindowHandle := FHostWindow;
  if WindowHandle = 0 then
    WindowHandle := HWND(AppWindow.Id.Value);
  ScreenToClient(WindowHandle, Pixel);
  Scale := GetDpiForWindow(WindowHandle) / 96;
  Result.X := Pixel.X / Scale;
  Result.Y := Pixel.Y / Scale;
end;

/// The content fills the visible area when smaller (star rows keep working) and scrolls when bigger.
procedure TPreviewWindow.FitPreviewArea;
var
  Scroll: TWinUIScrollViewer;
  Area: TWinUIGrid;
begin
  Scroll := FindElement<TWinUIScrollViewer>('PreviewScroll');
  Area := FindElement<TWinUIGrid>('PreviewArea');
  Area.MinWidth := Scroll.ViewportWidth;
  Area.MinHeight := Scroll.ViewportHeight;
end;

/// While the button is down after a press on the canvas: past 8 DIPs it is a drag and the
/// drop mark follows, on release, the move (or the selection of the press) is reported.
procedure TPreviewWindow.DragTick(Sender: TObject);
var
  Cursor: TPoint;
  At, Origin: RADWinUI.Abi.Point;
begin
  GetCursorPos(Cursor);
  At := ToContent(Cursor.X, Cursor.Y);
  if GetAsyncKeyState(VK_LBUTTON) < 0 then
  begin
    if FSelected <> '' then
    begin
      if Abs(At.X - FPressAt.X) + Abs(At.Y - FPressAt.Y) > 8 then
        FDragging := True;
      if FDragging then
        if (DropTarget(At, FSelected) <> '') and FreeTarget and (FSelectedElement <> nil) then
        begin
          // In a Grid or Canvas the element goes where it is dropped: its outline follows the pointer
          Origin.X := At.X - FGrab.X;
          Origin.Y := At.Y - FGrab.Y;
          Origin := (TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement).TransformToVisual(nil).Inverse
            .TransformPoint(Origin);
          FMark.X := Origin.X;
          FMark.Y := Origin.Y;
          FMark.Width := Max(FSelectedElement.ActualWidth, 3);
          FMark.Height := Max(FSelectedElement.ActualHeight, 3);
          ShowMark(True);
        end
        else
          ShowMark(DropTarget(At, FSelected) <> '');
    end;
    Exit;
  end;
  FDragTimer.Enabled := False;
  if FDragging then
    Queue(MoveTo(At))
  else
    Queue(FPressReply);
  FPressReply := '';
  FPressed := False;
  FDragging := False;
  ShowMark(False);
end;

/// Whether APoint (content coordinates) is over the previewed content.
function TPreviewWindow.OverPreview(const APoint: RADWinUI.Abi.Point): Boolean;
begin
  Result := VisualTreeHelper.FindAllElementsInHostCoordinatesPoint(APoint,
    TWinUIObject.IntfOf(FHost, IUIElement) as IUIElement, True).First.HasCurrent;
end;

/// The drop mark at FMark (set by the last DropTarget), or hidden.
procedure TPreviewWindow.ShowMark(AVisible: Boolean);
var
  Mark: IUIElement;
begin
  if not AVisible then
  begin
    FDropMark.Visibility := TWinUIVisibility.Collapsed;
    Exit;
  end;
  Mark := TWinUIObject.IntfOf(FDropMark, IUIElement) as IUIElement;
  Canvas.SetLeft(Mark, FMark.X);
  Canvas.SetTop(Mark, FMark.Y);
  FDropMark.Width := FMark.Width;
  FDropMark.Height := FMark.Height;
  FDropMark.Visibility := TWinUIVisibility.Visible;
end;

procedure TPreviewWindow.PaletteDropTick(Sender: TObject);
var
  Info: Winapi.Foundation.IAsyncInfo;
  Text, Tag: string;
begin
  try
    Info := FPaletteText as Winapi.Foundation.IAsyncInfo;
    if Info.Status = Winapi.CommonTypes.AsyncStatus.Started then
    begin
      if GetTickCount - FPaletteStarted < 3000 then
        Exit;
      Info.Cancel;
    end;
    FPaletteTimer.Enabled := False;
    if Info.Status = Winapi.CommonTypes.AsyncStatus.Completed then
    begin
      Text := TakeHString(RADWinUI.Interop.Core.HSTRING(FPaletteText.GetResults));
      if Text.StartsWith('RADWinUI.Component:') then
      begin
        Tag := Text.Substring(Length('RADWinUI.Component:'));
        if UIElementTags.ContainsKey(Tag) then
        begin
          UseTool('');
          UseTool(Tag);
          Queue(PlaceAt(FPalettePoint));
        end;
      end;
    end;
  except
    // Bad or expired external drag data must not break the renderer.
    FPaletteTimer.Enabled := False;
  end;
  if not FPaletteTimer.Enabled then
  begin
    FPaletteText := nil;
    if FPaletteDeferral <> nil then
      FPaletteDeferral.Complete;
    FPaletteDeferral := nil;
  end;
end;

/// A toolbox button: pick a control to place (again: put it back), or delete the selection.
function TPreviewWindow.UseTool(const AName: string): string;
var
  Parts: TArray<string>;
begin
  Result := 'OK';
  if AName = 'Delete' then
  begin
    if FSelected = '' then
      Exit;
    Parts := FElements[FSelected].Split([' ']);
    Result := Format('DELETE %s %s', [Parts[0], Parts[1]]);
    Select('');
    Exit;
  end;
  if (AName = FTool) or not (UIElementTags.ContainsKey(AName) or (PaletteCategoryOf(AName) <> '')) then
    FTool := ''
  else
    FTool := AName;
  if FTool <> '' then
    FSelectionText.Text := 'Click where the ' + FTool + ' goes (in a StackPanel or a Grid)'
  else
    Select(FSelected);
end;

/// 'panel key|index|row|column' for a drop at APoint: the StackPanel or Grid
/// under it that has a start tag (never AMoving or one inside it), or ''.
function TPreviewWindow.DropTarget(const APoint: RADWinUI.Abi.Point; const AMoving: string): string;
var
  Hits: IIterator_UIElement;
  Obj: IDependencyObject;
  Element: IFrameworkElement;
  Key, Tag, Found: string;
  Panel: IUIElement;
  Children: IVector_UIElement;
  Child: IUIElement;
  Local, Origin, MarkAt, MarkSize: RADWinUI.Abi.Point;
  I, Index, Row, Column: Integer;
  Edge, Size: Double;
  Horizontal: Boolean;
  Grid: IGrid;
begin
  Result := '';
  Hits := VisualTreeHelper.FindAllElementsInHostCoordinatesPoint(APoint,
    TWinUIObject.IntfOf(FHost, IUIElement) as IUIElement, True).First;
  if not Hits.HasCurrent then
    Obj := FRoot as IDependencyObject
  else
    Obj := Hits.Current as IDependencyObject;
  Found := '';
  while (Obj <> nil) and (Found = '') do
  begin
    if Supports(Obj, IFrameworkElement, Element) then
    begin
      Key := KeyOf(Element);
      if Key = AMoving then
        Found := '' // the moved element and what is inside it are no target
      else if FElements.ContainsKey(Key) then
      begin
        Tag := FElements[Key].Split([' '])[2];
        if MatchStr(Tag, ['StackPanel', 'Grid', 'Canvas']) and not Inside(Obj, AMoving) then
          Found := Key;
      end;
    end;
    if Found = '' then
      Obj := VisualTreeHelper.GetParent(Obj);
  end;
  if Found = '' then
    Exit;
  Panel := Obj as IUIElement;
  Local := Panel.TransformToVisual(nil).Inverse.TransformPoint(APoint);
  Children := (Obj as IPanel).Children;
  Index := Children.Size;
  Row := -1;
  Column := -1;
  MarkAt.X := 0;
  MarkAt.Y := 0;
  MarkSize.X := (Obj as IFrameworkElement).ActualWidth;
  MarkSize.Y := 3;
  FTargetKind := FElements[Found].Split([' '])[2];
  if FTargetKind = 'Canvas' then
  begin
    // Canvas: anywhere in it, the mark covers it
    MarkSize.Y := (Obj as IFrameworkElement).ActualHeight;
  end
  else if Supports(Obj, IGrid, Grid) then
  begin
    // Grid: appended, in the row and column under the point, the mark covers the cell.
    // Cells start inside the border and the padding.
    Row := 0;
    Edge := Grid.BorderThickness.Top + Grid.Padding.Top;
    MarkAt.X := Grid.BorderThickness.Left + Grid.Padding.Left;
    MarkAt.Y := Edge;
    MarkSize.Y := (Obj as IFrameworkElement).ActualHeight;
    for I := 0 to Integer(Grid.RowDefinitions.Size) - 1 do
    begin
      if (I = 0) or (Local.Y >= Edge) then
      begin
        Row := I;
        MarkAt.Y := Edge;
        MarkSize.Y := Grid.RowDefinitions.GetAt(I).ActualHeight;
      end;
      Edge := Edge + Grid.RowDefinitions.GetAt(I).ActualHeight;
    end;
    Column := 0;
    Edge := Grid.BorderThickness.Left + Grid.Padding.Left;
    for I := 0 to Integer(Grid.ColumnDefinitions.Size) - 1 do
    begin
      if (I = 0) or (Local.X >= Edge) then
      begin
        Column := I;
        MarkAt.X := Edge;
        MarkSize.X := Grid.ColumnDefinitions.GetAt(I).ActualWidth;
      end;
      Edge := Edge + Grid.ColumnDefinitions.GetAt(I).ActualWidth;
    end;
  end
  else
  begin
    // StackPanel: before the first child whose middle is past the point
    Horizontal := (Obj as IStackPanel).Orientation = RADWinUI.Abi.Orientation.Horizontal;
    if Horizontal then
    begin
      MarkSize.X := 3;
      MarkSize.Y := (Obj as IFrameworkElement).ActualHeight;
    end;
    for I := Integer(Children.Size) - 1 downto 0 do
    begin
      Child := Children.GetAt(I);
      Origin.X := 0;
      Origin.Y := 0;
      Origin := Child.TransformToVisual(Panel).TransformPoint(Origin);
      if Horizontal then
      begin
        Edge := Origin.X;
        Size := (Child as IFrameworkElement).ActualWidth;
        if Local.X < Edge + Size / 2 then
          Index := I;
      end
      else
      begin
        Edge := Origin.Y;
        Size := (Child as IFrameworkElement).ActualHeight;
        if Local.Y < Edge + Size / 2 then
          Index := I;
      end;
      // The mark: a bar before child Index, or after the last child
      if (I = Index) or ((Index = Integer(Children.Size)) and (I = Integer(Children.Size) - 1)) then
        if Horizontal then
          MarkAt.X := IfThen(I = Index, Origin.X - 2, Origin.X + Size + 1)
        else
          MarkAt.Y := IfThen(I = Index, Origin.Y - 2, Origin.Y + Size + 1);
    end;
  end;
  FCellOrigin := Panel.TransformToVisual(nil).TransformPoint(MarkAt);
  MarkAt := Panel.TransformToVisual(TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement).TransformPoint(MarkAt);
  FMark.X := MarkAt.X;
  FMark.Y := MarkAt.Y;
  FMark.Width := Max(MarkSize.X, 3);
  FMark.Height := Max(MarkSize.Y, 3);
  Result := Format('%s|%d|%d|%d', [Found, Index, Row, Column]);
end;

/// Whether AObject is (inside) the element with key AKey.
function TPreviewWindow.Inside(AObject: IDependencyObject; const AKey: string): Boolean;
var
  Element: IFrameworkElement;
begin
  Result := False;
  if AKey = '' then
    Exit;
  while AObject <> nil do
  begin
    if Supports(AObject, IFrameworkElement, Element) and (KeyOf(Element) = AKey) then
      Exit(True);
    AObject := VisualTreeHelper.GetParent(AObject);
  end;
end;

function TPreviewWindow.PlaceAt(const APoint: RADWinUI.Abi.Point): string;
var
  Target, Panel: TArray<string>;
begin
  Result := 'NONE';
  Target := DropTarget(APoint, '').Split(['|']);
  if Length(Target) <> 4 then
    Exit;
  Panel := FElements[Target[0]].Split([' ']);
  if FreeTarget then
    Result := Format('INSERTAT %s %s %s %s %s %s %d %d', [FTool, Panel[0], Panel[1], FTargetKind, Target[2], Target[3],
      Round(APoint.X - FCellOrigin.X), Round(APoint.Y - FCellOrigin.Y)])
  else
    Result := Format('INSERT %s %s %s %s %s %s', [FTool, Panel[0], Panel[1], Target[1], Target[2], Target[3]]);
  FTool := '';
end;

function TPreviewWindow.MoveTo(const APoint: RADWinUI.Abi.Point): string;
var
  Target, Panel, Element: TArray<string>;
begin
  Result := 'NONE';
  if FSelected = '' then
    Exit;
  Target := DropTarget(APoint, FSelected).Split(['|']);
  if Length(Target) <> 4 then
    Exit;
  Panel := FElements[Target[0]].Split([' ']);
  Element := FElements[FSelected].Split([' ']);
  if FreeTarget then
    Result := Format('PLACE %s %s %s %s %s %s %s %d %d', [Element[0], Element[1], Panel[0], Panel[1], FTargetKind,
      Target[2], Target[3], Round(APoint.X - FGrab.X - FCellOrigin.X), Round(APoint.Y - FGrab.Y - FCellOrigin.Y)])
  else
    Result := Format('MOVE %s %s %s %s %s %s %s', [Element[0], Element[1], Panel[0], Panel[1], Target[1], Target[2],
      Target[3]]);
end;

function TPreviewWindow.FreeTarget: Boolean;
begin
  Result := (FTargetKind = 'Grid') or (FTargetKind = 'Canvas');
end;

/// Remembers where APoint holds the selected element, for free placement.
procedure TPreviewWindow.GrabAt(const APoint: RADWinUI.Abi.Point);
var
  TopLeft: RADWinUI.Abi.Point;
begin
  FGrab.X := 0;
  FGrab.Y := 0;
  if (FSelected = '') or (FRoot = nil) then
    Exit;
  if FSelectedElement = nil then
    FSelectedElement := FindByKey(FRoot as IDependencyObject, FSelected);
  if FSelectedElement = nil then
    Exit;
  TopLeft.X := 0;
  TopLeft.Y := 0;
  TopLeft := (FSelectedElement as IUIElement).TransformToVisual(nil).TransformPoint(TopLeft);
  FGrab.X := APoint.X - TopLeft.X;
  FGrab.Y := APoint.Y - TopLeft.Y;
end;

procedure TPreviewWindow.WatchTick(Sender: TObject);
var
  Stamp, Xaml: string;
begin
  if FileExists(FWatchPath) then
    Stamp := DateTimeToStr(TFile.GetLastWriteTime(FWatchPath)) + '/' + IntToStr(TFile.GetSize(FWatchPath))
  else
    Stamp := 'missing';
  if Stamp = FWatchStamp then
    Exit;
  try
    Xaml := TFile.ReadAllText(FWatchPath, TEncoding.UTF8);
  except
    on E: Exception do
    begin
      if Stamp = 'missing' then
      begin
        FWatchStamp := Stamp;
        Load(FWatchPath, '<missing/>');
      end;
      Exit; // being written: try again on the next tick
    end;
  end;
  FWatchStamp := Stamp;
  Load(FWatchPath, Xaml);
end;

/// Reads one pipe message, '' when the client is gone.
function ReadMessage(APipe: THandle): string;
var
  Buffer: TBytes;
  Data: TBytes;
  Count: DWORD;
  Ok: Boolean;
begin
  SetLength(Buffer, 65536);
  Data := nil;
  repeat
    Ok := ReadFile(APipe, Buffer[0], Length(Buffer), Count, nil);
    if not Ok and (GetLastError <> ERROR_MORE_DATA) then
      Exit('');
    Data := Data + Copy(Buffer, 0, Count);
  until Ok;
  Result := TEncoding.UTF8.GetString(Data);
end;

function CompletePipeIo(APipe, AStop, AReady: THandle; var AOverlapped: TOverlapped): Boolean;
var
  Handles: array[0..1] of THandle;
  Count: DWORD;
begin
  Handles[0] := AStop;
  Handles[1] := AReady;
  case WaitForMultipleObjects(Length(Handles), @Handles[0], False, INFINITE) of
    WAIT_OBJECT_0:
      begin
        CancelIo(APipe);
        GetOverlappedResult(APipe, AOverlapped, Count, True);
        Result := False;
      end;
    WAIT_OBJECT_0 + 1:
      Result := GetOverlappedResult(APipe, AOverlapped, Count, False);
  else
    Result := False;
  end;
end;

procedure TPreviewWindow.StartEventPipe(const AName: string);
var
  Pipe: THandle;
begin
  FEventReady := CreateEvent(nil, True, False, nil);
  FEventStop := CreateEvent(nil, True, False, nil);
  if (FEventReady = 0) or (FEventStop = 0) then
    raise EWinRTError.CreateMsg(HResultFromWin32(GetLastError), 'Cannot create preview event synchronization');
  Pipe := CreateNamedPipe(PChar('\\.\pipe\' + AName + '-events'),
    PIPE_ACCESS_DUPLEX or FILE_FLAG_OVERLAPPED,
    PIPE_TYPE_MESSAGE or PIPE_READMODE_MESSAGE or PIPE_WAIT, 1, 65536, 65536, 0, nil);
  if Pipe = INVALID_HANDLE_VALUE then
    raise EWinRTError.CreateMsg(HResultFromWin32(GetLastError), 'Cannot create the preview event pipe ' + AName);
  FEventPipeThread := TThread.CreateAnonymousThread(
    procedure
    var
      Overlapped: TOverlapped;
      Handles: array[0..1] of THandle;
      Bytes: TBytes;
      Written: DWORD;
      Event: string;
      Error: DWORD;
      Connected: Boolean;
    begin
      try
        Overlapped := Default(TOverlapped);
        Overlapped.hEvent := CreateEvent(nil, True, False, nil);
        if Overlapped.hEvent = 0 then
          Exit;
        try
          if not ConnectNamedPipe(Pipe, @Overlapped) then
          begin
            Error := GetLastError;
            if Error = ERROR_IO_PENDING then
              Connected := CompletePipeIo(Pipe, FEventStop, Overlapped.hEvent, Overlapped)
            else
              Connected := Error = ERROR_PIPE_CONNECTED;
          end
          else
            Connected := True;
          if not Connected then
            Exit;
          Handles[0] := FEventStop;
          Handles[1] := FEventReady;
          repeat
            case WaitForMultipleObjects(Length(Handles), @Handles[0], False, INFINITE) of
              WAIT_OBJECT_0: Break;
              WAIT_OBJECT_0 + 1:
                begin
                  if not TakeQueuedEvent(Event) then
                    Continue;
                  Bytes := TEncoding.UTF8.GetBytes(Event);
                  ResetEvent(Overlapped.hEvent);
                  if not WriteFile(Pipe, Bytes[0], Length(Bytes), Written, @Overlapped) then
                  begin
                    Error := GetLastError;
                    if (Error <> ERROR_IO_PENDING) or
                      not CompletePipeIo(Pipe, FEventStop, Overlapped.hEvent, Overlapped) then
                      Break;
                  end;
                end;
            else
              Break;
            end;
          until False;
        finally
          CloseHandle(Overlapped.hEvent);
        end;
      finally
        CloseHandle(Pipe);
      end;
    end);
  FEventPipeThread.FreeOnTerminate := False;
  FEventPipeThread.Start;
end;

procedure TPreviewWindow.StartPipe(const AName: string);
var
  Pipe: THandle;
  Queue: IDispatcherQueue;
begin
  StartEventPipe(AName);
  Pipe := CreateNamedPipe(PChar('\\.\pipe\' + AName), PIPE_ACCESS_DUPLEX,
    PIPE_TYPE_MESSAGE or PIPE_READMODE_MESSAGE or PIPE_WAIT, 1, 65536, 65536, 0, nil);
  if Pipe = INVALID_HANDLE_VALUE then
    raise EWinRTError.CreateMsg(HResultFromWin32(GetLastError), 'Cannot create the preview pipe ' + AName);
  Queue := RADWinUI.Abi.DispatcherQueue.GetForCurrentThread;
  TThread.CreateAnonymousThread(
    procedure
    var
      Msg, Reply: string;
      Done: THandle;
      Bytes: TBytes;
      Written: DWORD;
    begin
      Done := CreateEvent(nil, False, False, nil);
      try
        if ConnectNamedPipe(Pipe, nil) or (GetLastError = ERROR_PIPE_CONNECTED) then
          repeat
            Msg := ReadMessage(Pipe);
            if (Msg = '') or (Msg = 'CLOSE') then
              Break; // CLOSE or a closed pipe: the host exits
            Reply := 'ERROR the preview did not answer';
            Queue.TryEnqueue(TDispatcherQueueHandler.Create(
              procedure
              begin
                try
                  if Preview <> nil then
                    Reply := Preview.Command(Msg)
                  else
                    Reply := ''; // the window is closing: no answer, the pipe closes
                except
                  on E: Exception do
                    Reply := 'ERROR ' + E.Message;
                end;
                SetEvent(Done);
              end));
            WaitForSingleObject(Done, 10000);
            if Reply = '' then
              Break;
            Bytes := TEncoding.UTF8.GetBytes(Reply);
            if not WriteFile(Pipe, Bytes[0], Length(Bytes), Written, nil) then
              Break;
          until False;
      finally
        CloseHandle(Done);
        CloseHandle(Pipe);
        Queue.TryEnqueue(TDispatcherQueueHandler.Create(
          procedure
          begin
            if Preview <> nil then
              Preview.Close;
          end));
      end;
    end).Start;
end;

var
  Name: string;

initialization
  LoadEvents;
  Converters := TDictionary<string, Boolean>.Create;
  for Name in BuiltInConverters do
    Converters.Add(Name, True);

finalization
  Events.Free;
  UIElementTags.Free;
  Converters.Free;

end.
