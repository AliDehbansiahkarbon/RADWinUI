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

  A right click selects the element under the pointer like a left click, then
  pushes CONTEXTMENU <x> <y> <hit>: the screen pixel where the IDE shows its
  menu, hit 0 when the click was beside every element. The Menu key and
  Shift+F10 push it for the selected element. Esc pushes SELECTPARENT and
  Ctrl+X CUT, next to COPY, PASTE, DELETEKEY, UNDO and REDO.

  Several elements: Ctrl+click adds or removes one, Ctrl+drag draws a marquee
  that adds the children of the panel under the press it touches, Ctrl+A selects
  the children of the selected element's panel (or of the window's content).
  MULTI <SELECTED fields>;<SELECTED fields>;... reports them, the first is the
  primary one. Ctrl+Arrow moves them all: NUDGEMULTI <line> <column> <left>
  <top>;... and so does a drag that starts on one of them, by the pointer's offset
  (each in its own Grid or Canvas): MOVEMULTI with the same fields. Delete, Copy and Cut act on them in the IDE.

  Ctrl+Arrow moves the selected child of a Grid or Canvas by 1 DIP, with Shift
  by 8: NUDGE <line> <column> <left> <top>, its new place in the parent (the
  IDE writes Canvas.Left/Top, or Margin with Left/Top alignment). The request
  NUDGEKEY <dx> <dy> does the same for keys the IDE received. Dragging and
  moving show alignment guides with siblings and the parent, a drag snaps to
  them unless Alt is held.
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
  A <TitleBar> becomes a Grid that holds its Content, LeftHeader and
  RightHeader: WinUI's TitleBar takes over the drag area of its window and
  crashes in a window docked as a child (its OnApplyTemplate reads a null
  InputActivationListener), the preview's own title bar must stay the preview's.
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
    FTitleBars: TDictionary<string, string>; // key of a TitleBar's placeholder Grid -> its layout XAML
    FSelected: string;
    FSelectedElement: IFrameworkElement;
    FExtra: TList<string>;          // the other selected elements (multi-selection), by key
    FExtraBoxes: TList<IUIElement>; // their outlines on the adorner
    FMarquee: IFrameworkElement;    // the Ctrl+drag rectangle
    FCtrlPress: Boolean;            // the press had Ctrl: a toggle, or a marquee once it moves
    FMarqueeOn: Boolean;
    FNudges: TDictionary<string, TPoint>; // multi nudge: each element's place sent last ...
    FNudgesAt: Cardinal;                  // ... and when
    FInserts: TArray<Integer>;
    // x:Uid -> ' Text="..."' attributes from the default Resources.resw beside the XAML
    FUidTexts: TDictionary<string, string>;
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
    FRightPressed: Boolean; // right button down on the canvas, selected already
    FRightHit: string;      // SELECTED of the right click, NONE beside every element
    FGuideX, FGuideY: TWinUIRectangle; // alignment guides: a vertical and a horizontal line
    FGuideTimer: TWinUITimer;          // hides the guides of keyboard moves
    FSnap: RADWinUI.Abi.Point;         // the snap of the current drag
    FNudgeKey: string;                 // the element of the last keyboard move ...
    FNudgeLeft, FNudgeTop: Integer;    // ... its place sent to the IDE ...
    FNudgeAt: Cardinal;                // ... and when
    FToolDrag: string;      // toolbox item under a pressed pointer
    FPressAt: RADWinUI.Abi.Point;
    FDropMark: TWinUIRectangle;
    FDragTimer: TWinUITimer;
    FMark: RADWinUI.Abi.Rect; // set by DropTarget, in adorner coordinates
    FTargetKind: string;      // set by DropTarget: StackPanel, Grid or Canvas
    FCellOrigin: RADWinUI.Abi.Point; // set by DropTarget: the Grid cell's or Canvas's top-left, content coordinates
    FGrab: RADWinUI.Abi.Point;       // where the pointer holds the dragged element, from its top-left
    // A press on an element of a multi-selection: a drag moves them all (FDragElement under the pointer)
    FMultiDrag: Boolean;
    FDragElement: IFrameworkElement;
    procedure PaletteDropTick(Sender: TObject);
    procedure GrabAt(const APoint: RADWinUI.Abi.Point);
    procedure GrabElement(const APoint: RADWinUI.Abi.Point; const AElement: IFrameworkElement);
    function KeyAt(const APoint: RADWinUI.Abi.Point): string;
    function PressAt(const APoint: RADWinUI.Abi.Point): string;
    function MoveAll(const AFrom, ATo: RADWinUI.Abi.Point): string;
    procedure OffsetOutlines(const AFrom, ATo: RADWinUI.Abi.Point);
    function FreeTarget: Boolean;
    procedure DragTick(Sender: TObject);
    function OverPreview(const APoint: RADWinUI.Abi.Point): Boolean;
    procedure ShowMark(AVisible: Boolean);
    procedure FitPreviewArea;
    procedure Queue(const AEvent: string);
    function ToContent(AScreenX, AScreenY: Integer): RADWinUI.Abi.Point;
    procedure QueueContextMenu(const APoint: RADWinUI.Abi.Point; AHit: Boolean);
    function Nudge(ADX, ADY: Integer): string;
    function ShowGuides(const ATopLeft: RADWinUI.Abi.Point; AWidth, AHeight: Double; const APanel: IFrameworkElement;
      ASnap: Boolean): RADWinUI.Abi.Point;
    procedure HideGuides(Sender: TObject);
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
    procedure ReadUidTexts(const APath: string);
    procedure DecorateTitleBars;
    function SelectFrom(AObject: IDependencyObject): string;
    function SelectAt(const APoint: RADWinUI.Abi.Point): string;
    procedure Select(const AName: string);
    function ElementBox(const AElement: IFrameworkElement): RADWinUI.Abi.Rect;
    procedure KeyedTree(const AObject: IDependencyObject; const AParent: string;
      AParents: TDictionary<string, string>; AOrder: TList<string>);
    function SelectionReply: string;
    procedure SelectKeys(const AKeys: TArray<string>);
    procedure PlaceExtraBoxes;
    function ToggleAt(const APoint: RADWinUI.Abi.Point): string;
    function MarqueeSelect(const AFrom, ATo: RADWinUI.Abi.Point): string;
    function SelectAllChildren: string;
    function NudgeAll(ADX, ADY: Integer; ARestart: Boolean = False): string;
    procedure ShowMarquee(const AFrom, ATo: RADWinUI.Abi.Point);
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
  RADWinUI.Designer.Palette,
  RADWinUI.Designer.Snap;

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

/// The look of the TitleBar whose start tag is at AStart in AXaml: a Grid with the back
/// button glyph, the icon, Title and Subtitle, then Border slots TitleBarLeftHeader,
/// TitleBarContent and TitleBarRightHeader for the children, in the control's columns.
function TitleBarLayout(const AXaml: string; AStart: Integer): string;
var
  Tag: TXamlTag;
  P, Stop, I: Integer;
  Body, Icon, Title, Subtitle, Name, Value: string;
  Back: Boolean;
  M: TMatch;
begin
  P := AStart;
  Result := '';
  if not NextTag(AXaml, P, Tag) then
    Exit;
  Back := False;
  for I := 0 to Tag.Count - 1 do
  begin
    Name := Tag.AttrName(AXaml, I);
    Value := Tag.AttrValue(AXaml, I);
    if Value.StartsWith('{') then
      Value := '{}' + Value; // a binding shows as its text
    if Name = 'Title' then Title := Value;
    if Name = 'Subtitle' then Subtitle := Value;
    if Name = 'IsBackButtonVisible' then Back := SameText(Value, 'True');
  end;
  Body := '';
  if not Tag.SelfClosing then
  begin
    Stop := Pos('</TitleBar>', AXaml, Tag.Stop);
    if Stop > 0 then
      Body := Copy(AXaml, Tag.Stop + 1, Stop - Tag.Stop - 1);
  end;
  // A font or symbol icon as it is, any other icon source as a generic glyph
  Icon := TRegEx.Match(Body, '<TitleBar\.IconSource>\s*<FontIconSource\s[^>]*?\bGlyph="([^"]*)"').Groups[1].Value;
  if Icon <> '' then
    Icon := '<FontIcon Glyph="' + Icon + '" FontSize="16"/>'
  else
  begin
    Icon := TRegEx.Match(Body, '<TitleBar\.IconSource>\s*<SymbolIconSource\s[^>]*?\bSymbol="([^"]*)"').Groups[1].Value;
    if Icon <> '' then
      Icon := '<SymbolIcon Symbol="' + Icon + '"/>'
    else if Body.Contains('<TitleBar.IconSource>') then
      Icon := '<FontIcon Glyph="&#xE737;" FontSize="16"/>';
  end;
  Result := '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ColumnSpacing="16" ' +
    'Padding="4,0,16,0"><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/>' +
    '<ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>' +
    '<StackPanel Orientation="Horizontal" Spacing="12" VerticalAlignment="Center">';
  if Back then
    Result := Result + '<FontIcon Glyph="&#xE72B;" FontSize="12" Margin="10,0,4,0"/>';
  Result := Result + Icon;
  if Title <> '' then
    Result := Result + '<TextBlock Text="' + Title + '" FontSize="12" VerticalAlignment="Center"/>';
  if Subtitle <> '' then
    Result := Result + '<TextBlock Text="' + Subtitle + '" FontSize="12" Opacity="0.7" VerticalAlignment="Center"/>';
  Result := Result + '</StackPanel>' +
    '<Border x:Name="TitleBarLeftHeader" Grid.Column="1" VerticalAlignment="Center" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"/>' +
    '<Border x:Name="TitleBarContent" Grid.Column="2" VerticalAlignment="Center" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"/>' +
    '<Border x:Name="TitleBarRightHeader" Grid.Column="3" VerticalAlignment="Center" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"/></Grid>';
  // The slot names in the order of the children in the placeholder Grid, then the layout
  Name := '';
  for M in TRegEx.Matches(Body, '<TitleBar\.(Content|LeftHeader|RightHeader)\s*>') do
    Name := Name + 'TitleBar' + M.Groups[1].Value + ',';
  Result := Name + '|' + Result;
end;

function PreviewXaml(const AXaml: string; out AWindow: string): string;
var
  Root: TMatch;
  Tag, Parent: TXamlTag;
  Stack: TArray<Integer>;
  Name, Title, Width, Height, RootName: string;
  P, I, Close, ParentAt: Integer;
  Prop: TMatch;
begin
  Result := AXaml;
  AWindow := '||';
  Root := TRegEx.Match(Result, '<(Window|Page|UserControl)\b[^>]*>');
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
    RootName := Root.Groups[1].Value;
    // <Window>, <Page> and <UserControl> all become a Grid, padded to the same length
    Overwrite(Result, Root.Index + 1, 'Grid'.PadRight(RootName.Length));
    Close := Result.LastIndexOf('</' + RootName);
    if Close >= 0 then
      Overwrite(Result, Close + 1, '</' + 'Grid'.PadRight(RootName.Length));
    // and so do their property elements: <Page.Resources> is <Grid.Resources>
    for Prop in TRegEx.Matches(Copy(Result, 1, MaxInt), '</?' + RootName + '(\.\w+)') do
      Overwrite(Result, Prop.Groups[1].Index - RootName.Length,
        'Grid' + Prop.Groups[1].Value + StringOfChar(' ', RootName.Length - 4));
  end;  P := 1;
  while NextTag(Result, P, Tag) do
  begin
    if Tag.Name.StartsWith('TitleBar.') then
    begin
      // The headers and the content become children of the placeholder Grid, other parts go
      Name := Tag.Name.Substring(9);
      if MatchStr(Name, ['Content', 'LeftHeader', 'RightHeader']) then
        Overwrite(Result, Tag.Start, Blank(Copy(Result, Tag.Start, Tag.Stop - Tag.Start + 1)))
      else if not Tag.IsEnd and not Tag.SelfClosing then
      begin
        Close := Pos('</' + Tag.Name, Result, Tag.Stop);
        if Close = 0 then
          Continue; // WinUI reports the missing end tag
        Close := Pos('>', Result, Close);
        Overwrite(Result, Tag.Start, Blank(Copy(Result, Tag.Start, Close - Tag.Start + 1)));
        P := Close + 1;
      end
      else
        Overwrite(Result, Tag.Start, Blank(Copy(Result, Tag.Start, Tag.Stop - Tag.Start + 1)));
      Continue;
    end;
    if Tag.Name = 'TitleBar' then
    begin
      Overwrite(Result, Tag.Start + 1 + Ord(Tag.IsEnd), 'Grid    ');
      if not Tag.IsEnd then
      begin
        PreviewTag(Result, Tag);
        for I := 0 to Tag.Count - 1 do
        begin
          Name := Tag.AttrName(Result, I);
          if not Name.Contains('.') and not Name.Contains(':') and not MatchStr(Name, ['', 'Name', 'Tag',
            'Margin', 'Padding', 'Width', 'Height', 'MinWidth', 'MinHeight', 'MaxWidth', 'MaxHeight',
            'HorizontalAlignment', 'VerticalAlignment', 'Visibility', 'Background', 'Opacity']) then
            Overwrite(Result, Tag.Attributes[I].Start,
              Blank(Copy(Result, Tag.Attributes[I].Start, Tag.Attributes[I].Length)));
        end;
        if not Tag.SelfClosing then Stack := Stack + [Tag.Start];
      end
      else if Length(Stack) > 0 then
        SetLength(Stack, Length(Stack) - 1);
      Continue;
    end;
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
    '<Rectangle x:Name="DropMark" Visibility="Collapsed" Fill="#C00078D4" RadiusX="2" RadiusY="2"/>' +
    '<Rectangle x:Name="GuideX" Visibility="Collapsed" Width="1" Fill="#FF0078D4"/>' +
    '<Rectangle x:Name="GuideY" Visibility="Collapsed" Height="1" Fill="#FF0078D4"/></Canvas>' +
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
  FExtra := TList<string>.Create;
  FExtraBoxes := TList<IUIElement>.Create;
  FNudges := TDictionary<string, TPoint>.Create;
  FTitleBars := TDictionary<string, string>.Create;
  FUidTexts := TDictionary<string, string>.Create;
  FAdornerTimer := TWinUITimer.Create;
  FAdornerTimer.Interval := 200; // follows layout changes of the selected element
  FAdornerTimer.OnTimer := PlaceAdorner;
  FDropMark := FindElement<TWinUIRectangle>('DropMark');
  FGuideX := FindElement<TWinUIRectangle>('GuideX');
  FGuideY := FindElement<TWinUIRectangle>('GuideY');
  FGuideTimer := TWinUITimer.Create;
  FGuideTimer.Interval := 1000;
  FGuideTimer.OnTimer := HideGuides;
  (TWinUIObject.IntfOf(FShell, IUIElement) as IUIElement).add_PreviewKeyDown(TKeyEventHandler.Create(
    procedure(ASender: IInspectable; AArgs: IKeyRoutedEventArgs)
    var
      Key: Integer;
      At: RADWinUI.Abi.Point;
    begin
      if (Ord(AArgs.Key) = VK_F9) and (GetAsyncKeyState(VK_MENU) >= 0) then
      begin
        if not AArgs.KeyStatus.WasKeyDown then
          if GetAsyncKeyState(VK_SHIFT) < 0 then
          begin
            if GetAsyncKeyState(VK_CONTROL) < 0 then Queue('RUNNODEBUG') else Queue('BUILD');
          end
          else if GetAsyncKeyState(VK_CONTROL) < 0 then Queue('COMPILE') else Queue('RUN');
        AArgs.Handled := True;
        Exit;
      end;
      if AArgs.Key = RADWinUI.Abi.VirtualKey.F12 then
      begin
        Queue('CODEVIEW');
        AArgs.Handled := True;
        Exit;
      end;
      if (Ord(AArgs.Key) = VK_DELETE) and (GetAsyncKeyState(VK_CONTROL) >= 0) and (FSelected <> '') then
      begin
        Queue('DELETEKEY');
        AArgs.Handled := True;
        Exit;
      end;
      if (Ord(AArgs.Key) = VK_ESCAPE) and (FSelected <> '') and (GetAsyncKeyState(VK_CONTROL) >= 0) and
        (GetAsyncKeyState(VK_SHIFT) >= 0) and (GetAsyncKeyState(VK_MENU) >= 0) then
      begin
        if not AArgs.KeyStatus.WasKeyDown then
          Queue('SELECTPARENT');
        AArgs.Handled := True;
        Exit;
      end;
      // The context menu from the keyboard, at the selected element
      if ((Ord(AArgs.Key) = VK_APPS) or ((Ord(AArgs.Key) = VK_F10) and (GetAsyncKeyState(VK_SHIFT) < 0))) and
        (GetAsyncKeyState(VK_CONTROL) >= 0) and (GetAsyncKeyState(VK_MENU) >= 0) then
      begin
        if not AArgs.KeyStatus.WasKeyDown then
        begin
          At.X := 8;
          At.Y := 8;
          if (FSelected <> '') and (FSelectedElement <> nil) then
            At := (FSelectedElement as IUIElement).TransformToVisual(nil).TransformPoint(At);
          QueueContextMenu(At, FSelected <> '');
        end;
        AArgs.Handled := True;
        Exit;
      end;
      // Ctrl+A: the children of the selected element's panel, or of the window's content
      if (AArgs.Key = RADWinUI.Abi.VirtualKey.A) and (GetAsyncKeyState(VK_CONTROL) < 0) and
        (GetAsyncKeyState(VK_MENU) >= 0) and (GetAsyncKeyState(VK_SHIFT) >= 0) then
      begin
        if not AArgs.KeyStatus.WasKeyDown then
          Queue(SelectAllChildren);
        AArgs.Handled := True;
        Exit;
      end;
      // Ctrl+Arrow moves the selected element, before the arrows could go to the IDE
      if (GetAsyncKeyState(VK_CONTROL) < 0) and (GetAsyncKeyState(VK_MENU) >= 0) and
        (Ord(AArgs.Key) in [VK_LEFT, VK_UP, VK_RIGHT, VK_DOWN]) then
      begin
        Key := IfThen(GetAsyncKeyState(VK_SHIFT) < 0, 8, 1);
        if FExtra.Count > 0 then
        begin
          case Ord(AArgs.Key) of
            VK_LEFT: Queue(NudgeAll(-Key, 0));
            VK_RIGHT: Queue(NudgeAll(Key, 0));
            VK_UP: Queue(NudgeAll(0, -Key));
            VK_DOWN: Queue(NudgeAll(0, Key));
          end;
          AArgs.Handled := True;
          Exit;
        end;
        case Ord(AArgs.Key) of
          VK_LEFT: Queue(Nudge(-Key, 0));
          VK_RIGHT: Queue(Nudge(Key, 0));
          VK_UP: Queue(Nudge(0, -Key));
          VK_DOWN: Queue(Nudge(0, Key));
        end;
        AArgs.Handled := True;
        Exit;
      end;
      if GetAsyncKeyState(VK_CONTROL) < 0 then
      begin
        AArgs.Handled := True;
        if AArgs.Key = RADWinUI.Abi.VirtualKey.C then
          Queue('COPY')
        else if AArgs.Key = RADWinUI.Abi.VirtualKey.X then
          Queue('CUT')
        else if AArgs.Key = RADWinUI.Abi.VirtualKey.V then
          Queue('PASTE')
        else if AArgs.Key = RADWinUI.Abi.VirtualKey.Z then
        begin
          if GetAsyncKeyState(VK_SHIFT) < 0 then Queue('REDO') else Queue('UNDO');
        end
        else if AArgs.Key = RADWinUI.Abi.VirtualKey.Y then
          Queue('REDO')
        else
          AArgs.Handled := False;
        if AArgs.Handled then Exit;
      end;
      // Any other Ctrl combination or F1..F11 runs the IDE action bound to it, Ctrl+S saves
      Key := Ord(AArgs.Key);
      if (GetAsyncKeyState(VK_MENU) >= 0) and
        not (Key in [VK_SHIFT, VK_CONTROL, VK_MENU, VK_LWIN, VK_RWIN]) and
        ((GetAsyncKeyState(VK_CONTROL) < 0) or ((Key >= VK_F1) and (Key <= VK_F11))) then
      begin
        if not AArgs.KeyStatus.WasKeyDown then
        begin
          if GetAsyncKeyState(VK_SHIFT) < 0 then Inc(Key, $2000);
          if GetAsyncKeyState(VK_CONTROL) < 0 then Inc(Key, $4000);
          Queue('SHORTCUT ' + IntToStr(Key));
        end;
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
      FRightPressed := AArgs.GetCurrentPoint(nil).Properties.IsRightButtonPressed;
      if FRightPressed then
      begin
        // Selects at once, the menu follows on release (RightTapped). A picked tool stays picked.
        FRightHit := SelectAt(FPressAt);
        Queue(FRightHit);
      end
      else if FTool <> '' then
      begin
        Queue(PlaceAt(FPressAt));
        ShowMark(False);
      end
      else if GetAsyncKeyState(VK_CONTROL) < 0 then
      begin
        // Ctrl: a click toggles the element, a drag draws a marquee (DragTick)
        FCtrlPress := True;
        FMarqueeOn := False;
        FPressed := True;
        FDragging := False;
        FDragTimer.Enabled := True;
      end
      else
      begin
        FPressReply := PressAt(FPressAt);
        FSnap := Default(RADWinUI.Abi.Point);
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
  // The release of a right click, or a press and hold with touch or pen
  (TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement).add_RightTapped(TRightTappedEventHandler.Create(
    procedure(ASender: IInspectable; AArgs: IRightTappedRoutedEventArgs)
    begin
      if not FRightPressed then
      begin
        // Touch and pen started as a left press: no drag, select here
        FDragTimer.Enabled := False;
        FPressed := False;
        FDragging := False;
        FPressReply := '';
        ShowMark(False);
        FRightHit := SelectAt(AArgs.GetPosition(nil));
        Queue(FRightHit);
      end;
      FRightPressed := False;
      QueueContextMenu(AArgs.GetPosition(nil), FRightHit <> 'NONE');
      AArgs.Handled := True;
    end));
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
  FExtra.Free;
  FExtraBoxes.Free;
  FNudges.Free;
  FTitleBars.Free;
  FUidTexts.Free;
  inherited;
end;

function TPreviewWindow.Load(const APath, AXaml: string): string;
var
  Text, Window, Caption, Kept: string;
  Parts, Keys: TArray<string>;
  Element: IUIElement;
begin
  Result := '';
  try
    AddMissingConverters(AXaml);
    ReadUidTexts(APath);
    Text := NameElements(AXaml, PreviewXaml(AXaml, Window));
    if not Supports(RADWinUI.Abi.XamlReader.Load(WinStr(Text)), IUIElement, Element) then
      raise Exception.Create('The root must be a UI element (a panel or a control)');
    (TWinUIObject.IntfOf(FHost, IBorder) as IBorder).Child := Element;
    Supports(Element, IFrameworkElement, FRoot);
    DecorateTitleBars;
    // The same elements after an edit (a multi-selection too), those that still exist
    Keys := nil;
    for Kept in [FSelected] + FExtra.ToArray do
      if (Kept <> '') and FElements.ContainsKey(Kept) then
        Keys := Keys + [Kept];
    SelectKeys(Keys);
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


/// The texts of Strings\en-US\Resources.resw beside APath, by x:Uid, ready to insert:
/// Uid.Property keys with a plain property name, as Property="value" separated by #1.
procedure TPreviewWindow.ReadUidTexts(const APath: string);
var
  Resw, Value, Uid, Prop, Attribute: string;
  M: TMatch;
  Dot: Integer;
begin
  FUidTexts.Clear;
  if APath = '' then
    Exit;
  Resw := TPath.Combine(ExtractFilePath(APath), 'Strings\en-US\Resources.resw');
  if not FileExists(Resw) then
    Exit;
  for M in TRegEx.Matches(TFile.ReadAllText(Resw, TEncoding.UTF8),
    '<data\s+name="([^".]+)\.(\w+)"[^>]*>\s*<value>(.*?)</value>', [roSingleLine]) do
  begin
    Uid := M.Groups[1].Value;
    Prop := M.Groups[2].Value;
    // Still XML text: only quotes and line breaks need escaping, a line break would move every line below
    Value := M.Groups[3].Value.Replace('"', '&quot;').Replace(#13#10, '&#10;').Replace(#10, '&#10;').Replace(#13, '');
    Attribute := Prop + '="' + Value + '"';
    if FUidTexts.ContainsKey(Uid) then
      FUidTexts[Uid] := FUidTexts[Uid] + #1 + Attribute
    else
      FUidTexts.Add(Uid, Attribute);
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
  FTitleBars.Clear;
  Line := 1;
  Column := 1;
  Position := 1;
  Depth := 0;
  Count := 0;
  // The first start tag is the Grid that was <Window>, <Page> or <UserControl>
  Skip := Ord(TRegEx.IsMatch(AXaml, '^\s*(<\?[^>]*>\s*)?(<!--.*?-->\s*)*<(Window|Page|UserControl)\b', [roSingleLine]));
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
      // An x:Uid element shows the default language's texts it has no attribute for
      I := Tag.Find(AText, 'x:Uid');
      if (I >= 0) and FUidTexts.TryGetValue(Tag.AttrValue(AText, I), Marker) then
      begin
        for UserName in Marker.Split([#1], TStringSplitOptions.ExcludeEmpty) do
          if Tag.Find(AText, UserName.Substring(0, UserName.IndexOf('='))) < 0 then
          begin
            FInserts := FInserts + [Tag.Start + 1 + Length(Tag.Name)];
            FMarkers := FMarkers + [' ' + UserName];
          end;
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
      // The Grid that stands in for a TitleBar is the TitleBar for the IDE
      if (Tag.Name = 'Grid') and (Copy(AXaml, Tag.Start + 1, 8) = 'TitleBar') then
      begin
        Tag.Name := 'TitleBar';
        FTitleBars.AddOrSetValue(Key, TitleBarLayout(AXaml, Tag.Start));
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

/// Gives the Grid that stands in for each TitleBar the control's look (TitleBarLayout),
/// with its headers and content in their columns. Hits on the look select the TitleBar.
procedure TPreviewWindow.DecorateTitleBars;
var
  Pair: TPair<string, string>;
  Bar, Layout: IFrameworkElement;
  Children: IVector_UIElement;
  Kids: TArray<IUIElement>;
  Slots: TArray<string>;
  Slot: string;
  I, Split: Integer;
begin
  for Pair in FTitleBars do
  begin
    Bar := FindByKey(FRoot as IDependencyObject, Pair.Key);
    Split := Pair.Value.IndexOf('|');
    if (Bar = nil) or not Supports(Bar, IPanel) or not Supports(RADWinUI.Abi.XamlReader.Load(
      WinStr(Pair.Value.Substring(Split + 1))), IFrameworkElement, Layout) then
      Continue;
    Slots := Pair.Value.Substring(0, Split).Split([','], TStringSplitOptions.ExcludeEmpty);
    Children := (Bar as IPanel).Children;
    SetLength(Kids, Children.Size);
    for I := 0 to High(Kids) do
      Kids[I] := Children.GetAt(I);
    Children.Clear;
    for I := 0 to High(Kids) do
    begin
      Slot := 'TitleBarContent'; // a child without a property element is the Content
      if I < Length(Slots) then
        Slot := Slots[I];
      (Layout.FindName(WinStr(Slot)) as IBorder).Child := Kids[I];
    end;
    Children.Append(Layout as IUIElement);
    if Bar.MinHeight = 0 then
      Bar.MinHeight := IfThen(Length(Kids) > 0, 48, 32); // the control's tall and normal heights
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
  Box: IUIElement;
begin
  // A plain selection ends a multi-selection
  FExtra.Clear;
  for Box in FExtraBoxes do
    Box.Visibility := RADWinUI.Abi.Visibility.Collapsed;
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
  PlaceExtraBoxes;
end;

/// AElement's bounds on the adorner canvas.
function TPreviewWindow.ElementBox(const AElement: IFrameworkElement): RADWinUI.Abi.Rect;
var
  Origin: RADWinUI.Abi.Point;
begin
  Origin.X := 0;
  Origin.Y := 0;
  Origin := (AElement as IUIElement).TransformToVisual(TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement)
    .TransformPoint(Origin);
  Result.X := Origin.X;
  Result.Y := Origin.Y;
  Result.Width := AElement.ActualWidth;
  Result.Height := AElement.ActualHeight;
end;

/// Every element with a start tag under AObject: its nearest such ancestor (AParents) and
/// document order (AOrder).
procedure TPreviewWindow.KeyedTree(const AObject: IDependencyObject; const AParent: string;
  AParents: TDictionary<string, string>; AOrder: TList<string>);
var
  Element: IFrameworkElement;
  Key, Parent: string;
  I: Integer;
begin
  Parent := AParent;
  if Supports(AObject, IFrameworkElement, Element) then
  begin
    Key := KeyOf(Element);
    if FElements.ContainsKey(Key) and not AParents.ContainsKey(Key) then
    begin
      AParents.Add(Key, AParent);
      AOrder.Add(Key);
      Parent := Key;
    end;
  end;
  for I := 0 to VisualTreeHelper.GetChildrenCount(AObject) - 1 do
    KeyedTree(VisualTreeHelper.GetChild(AObject, I), Parent, AParents, AOrder);
end;

/// SELECTED for one element, MULTI for several (the primary first), NONE for none.
function TPreviewWindow.SelectionReply: string;
var
  Key: string;
begin
  if FSelected = '' then
    Exit('NONE');
  if FExtra.Count = 0 then
    Exit('SELECTED ' + FElements[FSelected]);
  Result := 'MULTI ' + FElements[FSelected];
  for Key in FExtra do
    Result := Result + ';' + FElements[Key];
end;

/// Selects AKeys, the first one primary.
procedure TPreviewWindow.SelectKeys(const AKeys: TArray<string>);
var
  I: Integer;
begin
  if Length(AKeys) = 0 then
  begin
    Select('');
    Exit;
  end;
  Select(AKeys[0]);
  for I := 1 to High(AKeys) do
    if (AKeys[I] <> AKeys[0]) and not FExtra.Contains(AKeys[I]) then
      FExtra.Add(AKeys[I]);
  if FExtra.Count > 0 then
    FSelectionText.Text := Format('%d elements selected', [FExtra.Count + 1]);
  PlaceAdorner(nil);
end;

/// One outline per extra selected element, made as needed.
procedure TPreviewWindow.PlaceExtraBoxes;
var
  I: Integer;
  Element: IFrameworkElement;
  Bounds: RADWinUI.Abi.Rect;
  Box: IUIElement;
begin
  if FRoot = nil then
    Exit;
  while FExtraBoxes.Count < FExtra.Count do
  begin
    Box := RADWinUI.Abi.XamlReader.Load(WinStr('<Rectangle xmlns="http://schemas.microsoft.com/winfx/2006/xaml/' +
      'presentation" Stroke="#FF0078D4" StrokeThickness="2" StrokeDashArray="3,2" IsHitTestVisible="False"/>'))
      as IUIElement;
    (TWinUIObject.IntfOf(FAdorner, IPanel) as IPanel).Children.Append(Box);
    FExtraBoxes.Add(Box);
  end;
  for I := 0 to FExtraBoxes.Count - 1 do
  begin
    Box := FExtraBoxes[I];
    Element := nil;
    if I < FExtra.Count then
      Element := FindByKey(FRoot as IDependencyObject, FExtra[I]);
    if Element = nil then
    begin
      Box.Visibility := RADWinUI.Abi.Visibility.Collapsed;
      Continue;
    end;
    Bounds := ElementBox(Element);
    Canvas.SetLeft(Box, Bounds.X);
    Canvas.SetTop(Box, Bounds.Y);
    (Box as IFrameworkElement).Width := Bounds.Width;
    (Box as IFrameworkElement).Height := Bounds.Height;
    Box.Visibility := RADWinUI.Abi.Visibility.Visible;
  end;
end;

function IndexIn(const AKeys: TArray<string>; const AKey: string): Integer;
begin
  for Result := 0 to High(AKeys) do
    if AKeys[Result] = AKey then
      Exit;
  Result := -1;
end;

/// Ctrl+click: the element at APoint joins the selection, or leaves it.
function TPreviewWindow.ToggleAt(const APoint: RADWinUI.Abi.Point): string;
var
  Keys: TArray<string>;
  Hit, Previous: string;
  Extra: TArray<string>;
begin
  Previous := FSelected;
  Extra := FExtra.ToArray;
  Hit := SelectAt(APoint); // selects it alone: the earlier selection is in Previous and Extra
  if Hit = 'NONE' then
  begin
    SelectKeys([Previous] + Extra);
    Exit(SelectionReply);
  end;
  Hit := FSelected;
  Keys := [];
  if Previous <> '' then
    Keys := [Previous] + Extra;
  if IndexIn(Keys, Hit) >= 0 then
    Delete(Keys, IndexIn(Keys, Hit), 1)
  else
    Keys := Keys + [Hit];
  SelectKeys(Keys);
  Result := SelectionReply;
end;

/// The marquee from AFrom to ATo (content coordinates) on the adorner.
procedure TPreviewWindow.ShowMarquee(const AFrom, ATo: RADWinUI.Abi.Point);
var
  Inverse: IGeneralTransform;
  A, B: RADWinUI.Abi.Point;
begin
  if FMarquee = nil then
  begin
    FMarquee := RADWinUI.Abi.XamlReader.Load(WinStr('<Rectangle xmlns="http://schemas.microsoft.com/winfx/2006/xaml/' +
      'presentation" Stroke="#FF0078D4" StrokeThickness="1" StrokeDashArray="4,3" Fill="#180078D4" ' +
      'IsHitTestVisible="False"/>')) as IFrameworkElement;
    (TWinUIObject.IntfOf(FAdorner, IPanel) as IPanel).Children.Append(FMarquee as IUIElement);
  end;
  Inverse := (TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement).TransformToVisual(nil).Inverse;
  A := Inverse.TransformPoint(AFrom);
  B := Inverse.TransformPoint(ATo);
  Canvas.SetLeft(FMarquee as IUIElement, Min(A.X, B.X));
  Canvas.SetTop(FMarquee as IUIElement, Min(A.Y, B.Y));
  FMarquee.Width := Abs(B.X - A.X);
  FMarquee.Height := Abs(B.Y - A.Y);
  (FMarquee as IUIElement).Visibility := RADWinUI.Abi.Visibility.Visible;
end;

/// Ctrl+drag: the children of the panel under the press that the marquee touches join the selection.
function TPreviewWindow.MarqueeSelect(const AFrom, ATo: RADWinUI.Abi.Point): string;
var
  Parents: TDictionary<string, string>;
  Order: TList<string>;
  Keys: TArray<string>;
  Previous, Container, Key: string;
  Extra: TArray<string>;
  Inverse: IGeneralTransform;
  A, B: RADWinUI.Abi.Point;
  Area, Bounds: RADWinUI.Abi.Rect;
  Element: IFrameworkElement;
  HasChildren: Boolean;
begin
  Result := 'NONE';
  if FRoot = nil then
    Exit;
  Previous := FSelected;
  Extra := FExtra.ToArray;
  Inverse := (TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement).TransformToVisual(nil).Inverse;
  A := Inverse.TransformPoint(AFrom);
  B := Inverse.TransformPoint(ATo);
  Area.X := Min(A.X, B.X);
  Area.Y := Min(A.Y, B.Y);
  Area.Width := Abs(B.X - A.X);
  Area.Height := Abs(B.Y - A.Y);
  Parents := TDictionary<string, string>.Create;
  Order := TList<string>.Create;
  try
    KeyedTree(FRoot as IDependencyObject, '', Parents, Order);
    // The panel under the press: the element there when it has children, else its parent
    if SelectAt(AFrom) = 'NONE' then
      Container := ''
    else
    begin
      Container := FSelected;
      HasChildren := False;
      for Key in Order do
        if Parents[Key] = Container then
          HasChildren := True;
      if not HasChildren then
        Container := Parents[Container];
    end;
    // The selection so far, without the marquee's panel: a panel and its children are not selected together
    Keys := [];
    for Key in [Previous] + Extra do
      if (Key <> '') and (Key <> Container) then
        Keys := Keys + [Key];
    for Key in Order do
      if (Parents[Key] = Container) and (Container <> '') then
      begin
        Element := FindByKey(FRoot as IDependencyObject, Key);
        if Element = nil then
          Continue;
        Bounds := ElementBox(Element);
        // Touching: the rectangles overlap
        if (Bounds.X <= Area.X + Area.Width) and (Bounds.X + Bounds.Width >= Area.X) and
          (Bounds.Y <= Area.Y + Area.Height) and (Bounds.Y + Bounds.Height >= Area.Y) and
          (IndexIn(Keys, Key) < 0) then
          Keys := Keys + [Key];
      end;
  finally
    Order.Free;
    Parents.Free;
  end;
  SelectKeys(Keys);
  Result := SelectionReply;
end;

/// Ctrl+A: the children of the selected element's panel, else of the window's content.
function TPreviewWindow.SelectAllChildren: string;
var
  Parents: TDictionary<string, string>;
  Order: TList<string>;
  Keys: TArray<string>;
  Container, Key, Only: string;
  Count: Integer;
begin
  Result := 'NONE';
  if FRoot = nil then
    Exit;
  Parents := TDictionary<string, string>.Create;
  Order := TList<string>.Create;
  try
    KeyedTree(FRoot as IDependencyObject, '', Parents, Order);
    if Order.Count = 0 then
      Exit;
    if (FSelected <> '') and Parents.ContainsKey(FSelected) and (Parents[FSelected] <> '') then
      Container := Parents[FSelected]
    else
    begin
      // From the root down while there is a single child: the window's content panel
      Container := Order[0];
      repeat
        Count := 0;
        Only := '';
        for Key in Order do
          if Parents[Key] = Container then
          begin
            Inc(Count);
            Only := Key;
          end;
        if Count = 1 then
          Container := Only;
      until Count <> 1;
    end;
    Keys := [];
    for Key in Order do
      if Parents[Key] = Container then
        Keys := Keys + [Key];
  finally
    Order.Free;
    Parents.Free;
  end;
  SelectKeys(Keys);
  Result := SelectionReply;
end;

/// NUDGEMULTI for a keyboard move of every selected element of a Grid or Canvas by ADX, ADY DIPs.
function TPreviewWindow.NudgeAll(ADX, ADY: Integer; ARestart: Boolean): string;
var
  Key, Kind: string;
  Keys: TArray<string>;
  Element, Panel: IFrameworkElement;
  Origin: RADWinUI.Abi.Point;
  Slot: RADWinUI.Abi.Rect;
  Place: TPoint;
  Parts: TArray<string>;
  Fresh: Boolean;
begin
  Result := 'NONE';
  if (FSelected = '') or (FRoot = nil) then
    Exit;
  // Repeated keys build on the places sent last: the preview shows a move once the IDE has written it
  Fresh := ARestart or (GetTickCount - FNudgesAt >= 1000);
  if Fresh then
    FNudges.Clear;
  FNudgesAt := GetTickCount;
  Keys := [FSelected] + FExtra.ToArray;
  Result := '';
  for Key in Keys do
  begin
    Element := FindByKey(FRoot as IDependencyObject, Key);
    if (Element = nil) or
      not Supports(VisualTreeHelper.GetParent(Element as IDependencyObject), IFrameworkElement, Panel) or
      not FElements.ContainsKey(KeyOf(Panel)) then
      Continue;
    Kind := FElements[KeyOf(Panel)].Split([' '])[2];
    if (Kind <> 'Grid') and (Kind <> 'Canvas') then
      Continue;
    if not FNudges.TryGetValue(Key, Place) then
    begin
      Origin.X := 0;
      Origin.Y := 0;
      Origin := (Element as IUIElement).TransformToVisual(Panel as IUIElement).TransformPoint(Origin);
      if Kind = 'Canvas' then
        Place := TPoint.Create(Round(Origin.X - Element.Margin.Left), Round(Origin.Y - Element.Margin.Top))
      else
      begin
        Slot := LayoutInformation.GetLayoutSlot(Element);
        Place := TPoint.Create(Round(Origin.X - Slot.X), Round(Origin.Y - Slot.Y));
      end;
    end;
    Place.Offset(ADX, ADY);
    FNudges.AddOrSetValue(Key, Place);
    Parts := FElements[Key].Split([' ']);
    if Result <> '' then
      Result := Result + ';';
    Result := Result + Format('%s %s %d %d', [Parts[0], Parts[1], Place.X, Place.Y]);
  end;
  if Result = '' then
    Result := 'NONE'
  else
    Result := 'NUDGEMULTI ' + Result;
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
  else if Request.StartsWith('NUDGEKEY ') then
  begin
    Parts := Request.Split([' ']);
    if Length(Parts) <> 3 then Exit('ERROR invalid move');
    Queue(Nudge(StrToIntDef(Parts[1], 0), StrToIntDef(Parts[2], 0)));
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
    if PressAt(At) = 'NONE' then
      Exit('NONE');
    if FMultiDrag then
      Result := MoveAll(At, ToContent(StrToIntDef(Parts[3], 0), StrToIntDef(Parts[4], 0)))
    else
      Result := MoveTo(ToContent(StrToIntDef(Parts[3], 0), StrToIntDef(Parts[4], 0)));
    FMultiDrag := False;
    FDragElement := nil;
    Queue(Result);
  end
  else if Request.StartsWith('TOGGLE ') then
  begin
    // A Ctrl+click at a screen pixel, as tests send it
    Parts := Request.Split([' ']);
    Result := ToggleAt(ToContent(StrToIntDef(Parts[1], 0), StrToIntDef(Parts[2], 0)));
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

/// CONTEXTMENU at APoint (content coordinates) in screen pixels, AHit False when no element is there.
procedure TPreviewWindow.QueueContextMenu(const APoint: RADWinUI.Abi.Point; AHit: Boolean);
var
  Pixel: TPoint;
  Scale: Double;
  WindowHandle: HWND;
begin
  WindowHandle := FHostWindow;
  if WindowHandle = 0 then
    WindowHandle := HWND(AppWindow.Id.Value);
  Scale := GetDpiForWindow(WindowHandle) / 96;
  Pixel := TPoint.Create(Round(APoint.X * Scale), Round(APoint.Y * Scale));
  ClientToScreen(WindowHandle, Pixel);
  Queue(Format('CONTEXTMENU %d %d %d', [Pixel.X, Pixel.Y, Ord(AHit)]));
end;

/// NUDGE for a keyboard move of the selected element by ADX, ADY DIPs, NONE when its parent lays it out.
function TPreviewWindow.Nudge(ADX, ADY: Integer): string;
var
  Panel: IFrameworkElement;
  Slot: RADWinUI.Abi.Rect;
  Origin, TopLeft: RADWinUI.Abi.Point;
  Kind: string;
  Parts: TArray<string>;
  Left, Top, ActualLeft, ActualTop: Integer;
begin
  Result := 'NONE';
  if (FSelected = '') or (FRoot = nil) then
    Exit;
  if FSelectedElement = nil then
    FSelectedElement := FindByKey(FRoot as IDependencyObject, FSelected);
  if (FSelectedElement = nil) or
    not Supports(VisualTreeHelper.GetParent(FSelectedElement as IDependencyObject), IFrameworkElement, Panel) or
    not FElements.ContainsKey(KeyOf(Panel)) then
    Exit;
  Kind := FElements[KeyOf(Panel)].Split([' '])[2];
  if (Kind <> 'Grid') and (Kind <> 'Canvas') then
    Exit;
  // Where it is now in its parent: Canvas.Left/Top in a Canvas, the Margin's left and top in a Grid cell
  Origin.X := 0;
  Origin.Y := 0;
  Origin := (FSelectedElement as IUIElement).TransformToVisual(Panel as IUIElement).TransformPoint(Origin);
  if Kind = 'Canvas' then
  begin
    ActualLeft := Round(Origin.X - FSelectedElement.Margin.Left);
    ActualTop := Round(Origin.Y - FSelectedElement.Margin.Top);
  end
  else
  begin
    Slot := LayoutInformation.GetLayoutSlot(FSelectedElement);
    ActualLeft := Round(Origin.X - Slot.X);
    ActualTop := Round(Origin.Y - Slot.Y);
  end;
  // Repeated keys build on the place sent last: the preview shows a move once the IDE has written it
  if (FNudgeKey = FSelected) and (GetTickCount - FNudgeAt < 1000) then
  begin
    Left := FNudgeLeft + ADX;
    Top := FNudgeTop + ADY;
  end
  else
  begin
    Left := ActualLeft + ADX;
    Top := ActualTop + ADY;
  end;
  FNudgeKey := FSelected;
  FNudgeLeft := Left;
  FNudgeTop := Top;
  FNudgeAt := GetTickCount;
  // The guides where it goes, without snapping: the keys move it exactly
  TopLeft.X := 0;
  TopLeft.Y := 0;
  TopLeft := (FSelectedElement as IUIElement).TransformToVisual(nil).TransformPoint(TopLeft);
  TopLeft.X := TopLeft.X + Left - ActualLeft;
  TopLeft.Y := TopLeft.Y + Top - ActualTop;
  ShowGuides(TopLeft, FSelectedElement.ActualWidth, FSelectedElement.ActualHeight, Panel, False);
  FGuideTimer.Enabled := False;
  FGuideTimer.Enabled := True;
  Parts := FElements[FSelected].Split([' ']);
  Result := Format('NUDGE %s %s %d %d', [Parts[0], Parts[1], Left, Top]);
end;

/// Shows the guides of the selected element at ATopLeft (content coordinates) with the other
/// children of APanel and the panel itself. With ASnap, returns the move that lines it up
/// and shows the lines it snaps to, else shows only the lines it is exactly on.
function TPreviewWindow.ShowGuides(const ATopLeft: RADWinUI.Abi.Point; AWidth, AHeight: Double;
  const APanel: IFrameworkElement; ASnap: Boolean): RADWinUI.Abi.Point;

  procedure Place(AGuide: TWinUIRectangle; const AFound: TSnapGuide; AVertical: Boolean);
  var
    From, Upto: RADWinUI.Abi.Point;
    Line: IUIElement;
  begin
    if not AFound.Found or (not ASnap and (Abs(AFound.Delta) >= 0.5)) then
    begin
      AGuide.Visibility := TWinUIVisibility.Collapsed;
      Exit;
    end;
    if AVertical then
    begin
      From.X := AFound.At;
      From.Y := AFound.First;
      Upto.X := AFound.At;
      Upto.Y := AFound.Last;
    end
    else
    begin
      From.X := AFound.First;
      From.Y := AFound.At;
      Upto.X := AFound.Last;
      Upto.Y := AFound.At;
    end;
    From := (TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement).TransformToVisual(nil).Inverse.TransformPoint(From);
    Upto := (TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement).TransformToVisual(nil).Inverse.TransformPoint(Upto);
    Line := TWinUIObject.IntfOf(AGuide, IUIElement) as IUIElement;
    Canvas.SetLeft(Line, From.X);
    Canvas.SetTop(Line, From.Y);
    if AVertical then
      AGuide.Height := Max(Upto.Y - From.Y, 1)
    else
      AGuide.Width := Max(Upto.X - From.X, 1);
    AGuide.Visibility := TWinUIVisibility.Visible;
  end;

var
  Others: TArray<TSnapRect>;
  Children: IVector_UIElement;
  Child: IUIElement;
  Origin: RADWinUI.Abi.Point;
  Moving: TSnapRect;
  GuideX, GuideY: TSnapGuide;
  I: Integer;
begin
  Result := Default(RADWinUI.Abi.Point);
  if APanel = nil then
  begin
    HideGuides(nil);
    Exit;
  end;
  Origin := Default(RADWinUI.Abi.Point);
  Origin := (APanel as IUIElement).TransformToVisual(nil).TransformPoint(Origin);
  Others := [TSnapRect.Create(Origin.X, Origin.Y, APanel.ActualWidth, APanel.ActualHeight)];
  if Supports(APanel, IPanel) then
  begin
    Children := (APanel as IPanel).Children;
    for I := 0 to Integer(Children.Size) - 1 do
    begin
      Child := Children.GetAt(I);
      if (Child.Visibility <> RADWinUI.Abi.Visibility.Visible) or
        ((FSelectedElement <> nil) and ((Child as IUnknown) = (FSelectedElement as IUnknown))) then
        Continue;
      Origin := Default(RADWinUI.Abi.Point);
      Origin := Child.TransformToVisual(nil).TransformPoint(Origin);
      Others := Others + [TSnapRect.Create(Origin.X, Origin.Y, (Child as IFrameworkElement).ActualWidth,
        (Child as IFrameworkElement).ActualHeight)];
    end;
  end;
  Moving := TSnapRect.Create(ATopLeft.X, ATopLeft.Y, AWidth, AHeight);
  GuideX := SnapAxis(Moving, Others, True);
  GuideY := SnapAxis(Moving, Others, False);
  if ASnap and GuideX.Found then
    Result.X := GuideX.Delta;
  if ASnap and GuideY.Found then
    Result.Y := GuideY.Delta;
  Place(FGuideX, GuideX, True);
  Place(FGuideY, GuideY, False);
end;

procedure TPreviewWindow.HideGuides(Sender: TObject);
begin
  FGuideTimer.Enabled := False;
  FGuideX.Visibility := TWinUIVisibility.Collapsed;
  FGuideY.Visibility := TWinUIVisibility.Collapsed;
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
  Target: string;
  Panel: IFrameworkElement;
begin
  GetCursorPos(Cursor);
  At := ToContent(Cursor.X, Cursor.Y);
  if FCtrlPress then
  begin
    if GetAsyncKeyState(VK_LBUTTON) < 0 then
    begin
      if Abs(At.X - FPressAt.X) + Abs(At.Y - FPressAt.Y) > 8 then
        FMarqueeOn := True;
      if FMarqueeOn then
        ShowMarquee(FPressAt, At);
      Exit;
    end;
    FDragTimer.Enabled := False;
    FCtrlPress := False;
    FPressed := False;
    if FMarquee <> nil then
      (FMarquee as IUIElement).Visibility := RADWinUI.Abi.Visibility.Collapsed;
    if FMarqueeOn then
      Queue(MarqueeSelect(FPressAt, At))
    else
      Queue(ToggleAt(FPressAt));
    FMarqueeOn := False;
    Exit;
  end;
  if GetAsyncKeyState(VK_LBUTTON) < 0 then
  begin
    if FMultiDrag and (FDragElement <> nil) then
    begin
      if Abs(At.X - FPressAt.X) + Abs(At.Y - FPressAt.Y) > 8 then
        FDragging := True;
      if FDragging then
      begin
        // The whole selection follows the pointer, lined up by the element under it
        FSnap := Default(RADWinUI.Abi.Point);
        if Supports(VisualTreeHelper.GetParent(FDragElement as IDependencyObject), IFrameworkElement, Panel) then
        begin
          Origin.X := At.X - FGrab.X;
          Origin.Y := At.Y - FGrab.Y;
          FSnap := ShowGuides(Origin, FDragElement.ActualWidth, FDragElement.ActualHeight, Panel,
            GetAsyncKeyState(VK_MENU) >= 0);
        end;
        Origin.X := At.X + FSnap.X;
        Origin.Y := At.Y + FSnap.Y;
        OffsetOutlines(FPressAt, Origin);
      end;
      Exit;
    end;
    if FSelected <> '' then
    begin
      if Abs(At.X - FPressAt.X) + Abs(At.Y - FPressAt.Y) > 8 then
        FDragging := True;
      if FDragging then
      begin
        Target := DropTarget(At, FSelected);
        if (Target <> '') and FreeTarget and (FSelectedElement <> nil) then
        begin
          // In a Grid or Canvas the element goes where it is dropped: its outline follows the pointer,
          // lined up with a sibling or the panel when it comes close (not while Alt is held)
          Origin.X := At.X - FGrab.X;
          Origin.Y := At.Y - FGrab.Y;
          FSnap := ShowGuides(Origin, FSelectedElement.ActualWidth, FSelectedElement.ActualHeight,
            FindByKey(FRoot as IDependencyObject, Target.Split(['|'])[0]), GetAsyncKeyState(VK_MENU) >= 0);
          Origin.X := Origin.X + FSnap.X;
          Origin.Y := Origin.Y + FSnap.Y;
          Origin := (TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement).TransformToVisual(nil).Inverse
            .TransformPoint(Origin);
          FMark.X := Origin.X;
          FMark.Y := Origin.Y;
          FMark.Width := Max(FSelectedElement.ActualWidth, 3);
          FMark.Height := Max(FSelectedElement.ActualHeight, 3);
          ShowMark(True);
        end
        else
        begin
          FSnap := Default(RADWinUI.Abi.Point);
          HideGuides(nil);
          ShowMark(Target <> '');
        end;
      end;
    end;
    Exit;
  end;
  FDragTimer.Enabled := False;
  HideGuides(nil);
  if FMultiDrag then
  begin
    OffsetOutlines(FPressAt, FPressAt);
    if FDragging then
    begin
      At.X := At.X + FSnap.X;
      At.Y := At.Y + FSnap.Y;
      Queue(MoveAll(FPressAt, At));
    end
    else
      // A click on one of the selected elements selects it alone
      Queue(SelectAt(FPressAt));
  end
  else if FDragging then
  begin
    At.X := At.X + FSnap.X;
    At.Y := At.Y + FSnap.Y;
    Queue(MoveTo(At));
  end
  else
    Queue(FPressReply);
  FPressReply := '';
  FPressed := False;
  FDragging := False;
  FMultiDrag := False;
  FDragElement := nil;
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
begin
  FGrab.X := 0;
  FGrab.Y := 0;
  if (FSelected = '') or (FRoot = nil) then
    Exit;
  if FSelectedElement = nil then
    FSelectedElement := FindByKey(FRoot as IDependencyObject, FSelected);
  GrabElement(APoint, FSelectedElement);
end;

/// Remembers where APoint holds AElement, from its top-left.
procedure TPreviewWindow.GrabElement(const APoint: RADWinUI.Abi.Point; const AElement: IFrameworkElement);
var
  TopLeft: RADWinUI.Abi.Point;
begin
  FGrab.X := 0;
  FGrab.Y := 0;
  if AElement = nil then
    Exit;
  TopLeft.X := 0;
  TopLeft.Y := 0;
  TopLeft := (AElement as IUIElement).TransformToVisual(nil).TransformPoint(TopLeft);
  FGrab.X := APoint.X - TopLeft.X;
  FGrab.Y := APoint.Y - TopLeft.Y;
end;

/// The key of the topmost designable element at APoint, '' when there is none. Selects nothing.
function TPreviewWindow.KeyAt(const APoint: RADWinUI.Abi.Point): string;
var
  Hits: IIterator_UIElement;
  Hit: IDependencyObject;
  Element: IFrameworkElement;
begin
  Result := '';
  Hits := VisualTreeHelper.FindAllElementsInHostCoordinatesPoint(APoint,
    TWinUIObject.IntfOf(FHost, IUIElement) as IUIElement, True).First;
  if not Hits.HasCurrent then
    Exit;
  Hit := Hits.Current as IDependencyObject;
  while Hit <> nil do
  begin
    if Supports(Hit, IFrameworkElement, Element) and FElements.ContainsKey(KeyOf(Element)) then
      Exit(KeyOf(Element));
    Hit := VisualTreeHelper.GetParent(Hit);
  end;
end;

/// A press without Ctrl: on an element of a multi-selection it keeps the selection, for a drag
/// of them all (FMultiDrag), otherwise it selects the element under the pointer.
function TPreviewWindow.PressAt(const APoint: RADWinUI.Abi.Point): string;
var
  Key: string;
begin
  FMultiDrag := False;
  FDragElement := nil;
  Key := KeyAt(APoint);
  if (FExtra.Count > 0) and (Key <> '') and ((Key = FSelected) or FExtra.Contains(Key)) and (FRoot <> nil) then
  begin
    FDragElement := FindByKey(FRoot as IDependencyObject, Key);
    if FDragElement <> nil then
    begin
      FMultiDrag := True;
      GrabElement(APoint, FDragElement);
      Exit(SelectionReply);
    end;
  end;
  Result := SelectAt(APoint);
  GrabAt(APoint);
end;

/// The drop of a multi-selection drag from AFrom to ATo (content coordinates): every selected
/// element of a Grid or Canvas moves by that offset in its own panel, as one NUDGEMULTI edit.
/// They stay in their panels: a drop over another container moves none of them into it.
function TPreviewWindow.MoveAll(const AFrom, ATo: RADWinUI.Abi.Point): string;
var
  Panel: IUIElement;
  ToPanel: IGeneralTransform;
  From, Upto: RADWinUI.Abi.Point;
begin
  Result := 'NONE';
  if (FDragElement = nil) or
    not Supports(VisualTreeHelper.GetParent(FDragElement as IDependencyObject), IUIElement, Panel) then
    Exit;
  // The offset in the panel's own units: a zoomed preview scales the pointer's
  ToPanel := Panel.TransformToVisual(nil).Inverse;
  From := ToPanel.TransformPoint(AFrom);
  Upto := ToPanel.TransformPoint(ATo);
  if (Round(Upto.X - From.X) = 0) and (Round(Upto.Y - From.Y) = 0) then
    Exit(SelectionReply);
  Result := NudgeAll(Round(Upto.X - From.X), Round(Upto.Y - From.Y), True);
  // A drag is one change of its own, not part of a burst of Ctrl+Arrow moves
  if Result.StartsWith('NUDGEMULTI ') then
    Result := 'MOVEMULTI ' + Result.Substring(Length('NUDGEMULTI '));
end;

/// The outlines of the selection shown moved by the pointer's offset from AFrom to ATo while it
/// drags them (AFrom = ATo puts them back).
procedure TPreviewWindow.OffsetOutlines(const AFrom, ATo: RADWinUI.Abi.Point);
var
  ToAdorner: IGeneralTransform;
  From, Upto: RADWinUI.Abi.Point;
  Shift: ITranslateTransform;
  Box: IUIElement;
begin
  ToAdorner := (TWinUIObject.IntfOf(FAdorner, IUIElement) as IUIElement).TransformToVisual(nil).Inverse;
  From := ToAdorner.TransformPoint(AFrom);
  Upto := ToAdorner.TransformPoint(ATo);
  Shift := TranslateTransform.New;
  Shift.X := Upto.X - From.X;
  Shift.Y := Upto.Y - From.Y;
  (TWinUIObject.IntfOf(FSelectionBox, IUIElement) as IUIElement).RenderTransform := Shift as ITransform;
  for Box in FExtraBoxes do
    Box.RenderTransform := Shift as ITransform;
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
