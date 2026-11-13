unit RADWinUI.CodeGen;

(*
  XamlCodeGen: generates the Pascal base class of a XAML window.
  tests\XamlCodeGen\XamlCodeGenTest checks it.

  MainWindow.xaml has a <Window x:Class="TMainWindow"> root with one content
  element. MainWindow.Xaml.pas gets TMainWindowBase: it loads the content XAML,
  fills one typed field per x:Name element and wires event handlers to
  published methods of the companion unit MainWindow.pas:

  - event attributes (Click="IncrementButtonClick"), removed from the loaded XAML
    because XamlReader.Load does not accept them;
  - naming convention: a published method <x:Name><Event> (IncrementButtonClick).

  A handler may take (Sender: TObject; E: <args class>) or the short
  (Sender: TObject) form. Element types and events come from
  src\Generated\RADWinUI.Xaml.json, written by WinMDGen, and RADWinUI's own
  controls (xmlns:rw="using:RADWinUI.Controls") from
  src\Framework\RADWinUI.Controls.json.
*)

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON,
  RADWinUI.CodeGen.Xml, RADWinUI.CodeGen.Bindings;

const
  CodeGenVersion = '0.5'; // bump when the generated code changes shape

type
  ECodeGenError = RADWinUI.CodeGen.Bindings.ECodeGenError;

  TEventInfo = record
    Name, Handler, Args: string;
  end;

  /// <summary>Element types and events from RADWinUI.Xaml.json and RADWinUI.Controls.json.</summary>
  TTypeIndex = class
  private
    FJson, FCustomJson: TJSONObject;
    FTypes, FClasses, FCustomTypes: TJSONObject;
    FCustomClasses: TStringList;
    procedure LoadCustom(const APath: string);
    function ClassInfo(const AClass: string): TJSONObject;
    function BaseOf(AInfo: TJSONObject): string;
  public
    constructor Create(const APath: string);
    destructor Destroy; override;
    /// <summary>Runtime class of a XAML element in the default namespace, '' when unknown.</summary>
    function Element(const ATag: string): string;
    /// <summary>Full name of a RADWinUI control (rw:GlowTile), '' when unknown.</summary>
    function CustomElement(const ATag: string): string;
    /// <summary>True for a RADWinUI control written in Delphi.</summary>
    function IsCustom(const AClass: string): Boolean;
    /// <summary>The Pascal unit that declares a RADWinUI control's class.</summary>
    function UnitOf(const AClass: string): string;
    function Wrapper(const AClass: string): string;
    /// <summary>The event AName of AClass or a base class.</summary>
    function Event(const AClass, AName: string; out AInfo: TEventInfo): Boolean;
    /// <summary>All events of AClass and its bases, sorted by name.</summary>
    function Events(const AClass: string): TArray<TEventInfo>;
    /// <summary>True when AClass or a base class has the property AName.</summary>
    function HasProperty(const AClass, AName: string): Boolean;
  end;

  /// <summary>A user control of the project: a .xaml file with a &lt;UserControl x:Class&gt; root.</summary>
  TUserControlInfo = record
    ClassName, UnitName, XamlFile: string;
    Properties, Events, OnEvents: TArray<string>;
  end;

  /// <summary>Generates the unit text of one window. Raises ECodeGenError.</summary>
  TCodeGenerator = class
  private type
    TField = record
      Name, Wrapper, Tag: string;
      Line: Integer;
    end;
    TBindingInfo = record
      Element, Event, Method, Handler, Args, How: string;
      Count, Line: Integer;
      Custom: Boolean;
    end;
    TNamed = record
      Name, ClassName: string;
      Line: Integer;
      // a user control of the project: its events come from its unit, not the type index
      IsUser: Boolean;
      UserEvents: TArray<string>;
    end;
  private
    FXamlPath, FXamlText, FPasText: string;
    FHasTexts: Boolean;
    FIndex: TTypeIndex;
    // 'Window', 'Page' or 'UserControl'
    FRootKind: string;
    FUserControls: TDictionary<string, TUserControlInfo>;
    FOwnProperties: TArray<string>;
    FStem, FUnitName, FClassName, FBaseName, FPasName: string;
    FDataContextType, FViewModelUnit, FTitleBar: string;
    FWindowLine, FContentLine, FAutoNames: Integer;
    FContentXaml: string;
    FFields: TList<TField>;
    FBindings: TList<TBindingInfo>;
    FNamed: TList<TNamed>;
    FAutoWrappers: TDictionary<string, string>;
    FMethods: TDictionary<string, TArray<string>>;
    FWindowProps: TDictionary<string, string>;
    FResourceKeys: TStringList;
    FUnits: TStringList;
    FChecker: TBindingChecker;
    function Where(AElement: TXmlElement): string;
    function WindowValue(const AName, AValue: string): string;
    procedure CheckBindings(AElement: TXmlElement; const AScope: string);
    procedure Walk(AElement: TXmlElement; const AScope: string; AInTemplate: Boolean);
    procedure WalkUserControl(AElement: TXmlElement; const ALocal: string);
    procedure LoadUserControls;
    procedure CheckFieldName(const AName: string);
    function EmitPage(const AXaml: string): string;
    function EmitUserControl(const AXaml: string): string;
    procedure Bind(const AElement, AEvent, AMethod, AHandler, AArgs: string; AExplicit: Boolean; ALine: Integer;
      ACustom: Boolean = False);
    function Emit(const AXaml: string): string;
    function FieldLines: string;
    // ARoot False: the x:Name fields and the wiring of the content (WireXaml, again after a
    // hot reload). True: the wiring of the root element itself, once in the constructor.
    function WiringLines(ARoot: Boolean): string;
    function HotReloadLines(const AReload: string): string;
    function SetContent(const AXaml: string): string;
  public
    /// <summary>
    ///   AXamlText and APasText, with AHasTexts, are editor snapshots (the IDE request),
    ///   otherwise the files are read.
    /// </summary>
    constructor Create(const AXamlPath: string; AIndex: TTypeIndex; const AXamlText: string = '';
      const APasText: string = ''; AHasTexts: Boolean = False);
    destructor Destroy; override;
    function Run: string;
    property GeneratedUnit: string read FUnitName;
    /// <summary>After Run: the XAML the generated unit loads (hot reload sends it to the app).</summary>
    property ContentXaml: string read FContentXaml;
    /// <summary>
    ///   After Run: the x:Name fields (F:Name:Wrapper) and the events (E:Element.Event=Method,
    ///   sorted) separated by semicolons. Hot reload compares the compiled shape with the edited one.
    /// </summary>
    function Shape: string;
  end;

/// <summary>Joins two path parts.</summary>
function JoinPath(const AFolder, AName: string): string;
/// <summary>The default RADWinUI.Xaml.json: src\Generated of the checkout above AFolder.</summary>
function DefaultIndexPath(const AFolder: string): string;
/// <summary>A Pascal string expression for AText, one literal per line, at most 200 characters each.</summary>
function PascalString(const AText: string; const AIndent: string = '    '): string;
/// <summary>Methods (lower name -> parameter declarations) of the published sections of AClassName.</summary>
function PublishedMethods(const APasText, AClassName: string): TDictionary<string, TArray<string>>;
/// <summary>Generates <Name>.Xaml.pas next to AXamlPath (UTF-8 with BOM), returns its path.</summary>
function GenerateFile(const AXamlPath: string; AIndex: TTypeIndex): string;
/// <summary>The XamlCodeGen command line (also --ide-request), returns the exit code.</summary>
function RunCodeGen(const AArgs: TArray<string>; const AExeFolder: string): Integer;
/// <summary>
///   Warnings for the x:Uid of the .xaml files in AFolder against its
///   Strings\en-US\Resources.resw: RW2001 for an x:Uid without a key there, RW2002
///   for a Uid.Property key no x:Uid uses. Nothing when the folder has no Strings.
/// </summary>
function CheckUids(const AFolder: string): TArray<string>;
/// <summary>
///   RW2003 for each button of AXamlPath that a screen reader cannot name: no
///   text in it, no AutomationProperties.Name, no ToolTip and no x:Uid.
/// </summary>
function CheckAccessibleNames(const AXamlPath: string): TArray<string>;

implementation

uses
  System.IOUtils, System.RegularExpressions, System.Character, System.StrUtils, System.Math;

const
  Presentation = 'http://schemas.microsoft.com/winfx/2006/xaml/presentation';
  CustomNamespace = 'using:RADWinUI.Controls';
  XamlNs = 'http://schemas.microsoft.com/winfx/2006/xaml';
  XClass = '{' + XamlNs + '}Class';
  XName = '{' + XamlNs + '}Name';
  XKey = '{' + XamlNs + '}Key';
  XDataType = '{' + XamlNs + '}DataType';
  // Design-time namespaces (d:Text="Sample", mc:Ignorable="d"): only the preview uses them
  DesignNamespaces: array[0..1] of string = ('{http://schemas.microsoft.com/expression/blend/2008}',
    '{http://schemas.openxmlformats.org/markup-compatibility/2006}');
  // <Window> attributes: Title is WinUI's, the rest are RADWinUI properties of TWinUIWindow
  // (WinUI's Window cannot set them in XAML). Applied in this order.
  WindowAttributes: array[0..19] of string = ('Title', 'WindowStyle', 'Width', 'Height', 'MinWidth', 'MinHeight',
    'MaxWidth', 'MaxHeight', 'Backdrop', 'ExtendsContentIntoTitleBar', 'WindowStartupLocation', 'Dock', 'ClickThrough',
    'ShowActivated', 'AlwaysOnTop', 'Resizable', 'Minimizable', 'Maximizable', 'WindowState', 'TitleBar');
  // Members of TWinUIWindow and its ancestors that an x:Name field would hide
  ReservedNames =
    ',title,content,width,height,minwidth,minheight,backdrop,show,close,center,activate,findelement,' +
    'loadcontent,owner,winrtobject,intf,create,destroy,free,appwindow,dispatcherqueue,systembackdrop,visible,' +
    'bounds,datacontext,windowstyle,dock,clickthrough,hittestelement,showactivated,alwaysontop,';
  PageReservedNames =
    ',frame,keepalive,navigatedto,navigatedfrom,navigatingfrom,findelement,publishedmethod,notifyproc,viewmodel,' +
    'content,background,padding,margin,tag,width,height,visibility,opacity,datacontext,name,parent,create,' +
    'destroy,free,owner,winrtobject,intf,foreground,fontsize,isenabled,';
  UserControlReservedNames =
    ',initialize,loadcontentxaml,findelement,publishedmethod,notifyproc,fire,customtype,eventbyname,ownerwindow,' +
    'content,background,padding,margin,tag,width,height,visibility,opacity,datacontext,name,parent,create,' +
    'destroy,free,owner,winrtobject,intf,foreground,fontsize,isenabled,';  PascalReserved =
    ',and,array,as,asm,begin,case,class,const,constructor,destructor,div,do,downto,else,end,except,exports,' +
    'file,finalization,finally,for,function,goto,if,implementation,in,inherited,initialization,inline,' +
    'interface,is,label,library,mod,nil,not,object,of,or,out,packed,procedure,program,property,raise,record,' +
    'repeat,resourcestring,set,shl,shr,string,then,threadvar,to,try,type,unit,until,uses,var,while,with,xor,';
  // Namespace prefixes: the well-known ones, then the two XamlCodeGen registers
  Registered: array[0..8] of TXmlPrefix = (
    (Uri: 'http://www.w3.org/XML/1998/namespace'; Prefix: 'xml'),
    (Uri: 'http://www.w3.org/1999/xhtml'; Prefix: 'html'),
    (Uri: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'; Prefix: 'rdf'),
    (Uri: 'http://schemas.xmlsoap.org/wsdl/'; Prefix: 'wsdl'),
    (Uri: 'http://www.w3.org/2001/XMLSchema'; Prefix: 'xs'),
    (Uri: 'http://www.w3.org/2001/XMLSchema-instance'; Prefix: 'xsi'),
    (Uri: 'http://purl.org/dc/elements/1.1/'; Prefix: 'dc'),
    (Uri: Presentation; Prefix: ''),
    (Uri: XamlNs; Prefix: 'x'));

function JoinPath(const AFolder, AName: string): string;
begin
  if AFolder = '' then
    Result := AName
  else if CharInSet(AFolder[Length(AFolder)], ['\', '/']) then
    Result := AFolder + AName
  else
    Result := AFolder + '\' + AName;
end;

/// The folder part of a path.
function DirName(const APath: string): string;
var
  I: Integer;
begin
  I := APath.LastDelimiter('\/');
  if I < 0 then
    Exit('');
  Result := APath.Substring(0, I);
  // keep a root ("C:\"), strip other trailing separators
  while (Result.Length > 1) and CharInSet(Result[Result.Length], ['\', '/']) and
    not ((Result.Length = 3) and (Result[2] = ':')) do
    Result := Result.Substring(0, Result.Length - 1);
  if (Result.Length = 2) and (Result[2] = ':') then
    Result := Result + APath[3];
end;

function BaseName(const APath: string): string;
begin
  Result := APath.Substring(APath.LastDelimiter('\/') + 1);
end;

function DefaultIndexPath(const AFolder: string): string;
var
  Folder: string;
begin
  Folder := ExcludeTrailingPathDelimiter(TPath.GetFullPath(AFolder));
  while Folder <> '' do
  begin
    Result := TPath.Combine(Folder, 'src\Generated\RADWinUI.Xaml.json');
    if FileExists(Result) then
      Exit;
    if ExtractFileDir(Folder) = Folder then
      Break;
    Folder := ExtractFileDir(Folder);
  end;
  Result := TPath.Combine(AFolder, '..\src\Generated\RADWinUI.Xaml.json');
end;

// The XAML name of a user control: its class name without the T (TContactCard -> ContactCard)
function XamlNameOf(const AClassName: string): string;
begin
  if (AClassName.Length > 1) and (AClassName[1] = 'T') then
    Result := AClassName.Substring(1)
  else
    Result := AClassName;
end;
function UserProperties(const APasText: string): TArray<string>; forward;

function InList(const AList, AName: string): Boolean;
begin
  Result := Pos(',' + AName + ',', AList) > 0;
end;

/// Splits at LF: n separators give n + 1 parts, empty ones included.
function SplitLines(const AText: string): TArray<string>;
var
  List: TList<string>;
  Start, I: Integer;
begin
  List := TList<string>.Create;
  try
    Start := 1;
    for I := 1 to Length(AText) do
      if AText[I] = #10 then
      begin
        List.Add(Copy(AText, Start, I - Start));
        Start := I + 1;
      end;
    List.Add(Copy(AText, Start, MaxInt));
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function PascalString(const AText, AIndent: string): string;
var
  Parts: TList<string>;
  Lines: TArray<string>;
  Line, Chunk, Literal: string;
  I, P, Count, Start: Integer;
  Chunks: TList<string>;
begin
  Parts := TList<string>.Create;
  Chunks := TList<string>.Create;
  try
    Lines := SplitLines(AText.Replace(#13#10, #10));
    for I := 0 to High(Lines) do
    begin
      Line := Lines[I];
      // 200 code points per literal
      Chunks.Clear;
      P := 1;
      while P <= Length(Line) do
      begin
        Start := P;
        Count := 0;
        while (P <= Length(Line)) and (Count < 200) do
        begin
          if Line[P].IsHighSurrogate and (P < Length(Line)) then
            Inc(P, 2)
          else
            Inc(P);
          Inc(Count);
        end;
        Chunks.Add(Copy(Line, Start, P - Start));
      end;
      if Chunks.Count = 0 then
        Chunks.Add('');
      for P := 0 to Chunks.Count - 1 do
      begin
        Chunk := Chunks[P];
        Literal := '''' + Chunk.Replace('''', '''''') + '''';
        if (P = Chunks.Count - 1) and (I < High(Lines)) then
          Literal := Literal + ' + sLineBreak';
        Parts.Add(Literal);
      end;
    end;
    for I := Parts.Count - 1 downto 0 do
      if Parts[I] = '''''' then
        Parts.Delete(I);
    if Parts.Count = 0 then
      Parts.Add('''''');
    Result := string.Join(' +'#13#10 + AIndent, Parts.ToArray);
  finally
    Chunks.Free;
    Parts.Free;
  end;
end;

function PublishedMethods(const APasText, AClassName: string): TDictionary<string, TArray<string>>;
var
  M, Section, PM: TMatch;
  Body, Param: string;
  Params: TList<string>;
begin
  Result := TDictionary<string, TArray<string>>.Create;
  M := TRegEx.Match(APasText, '\b' + TRegEx.Escape(AClassName) + '\s*=\s*class\b(.*?)\bend\s*;',
    [roIgnoreCase, roSingleLine]);
  if not M.Success then
    Exit;
  Body := TRegEx.Replace(M.Groups[1].Value, '//[^\n]*|\{[^}]*\}|\(\*.*?\*\)', '', [roSingleLine]);
  // Only the published section(s): from 'published' to the next visibility keyword
  Params := TList<string>.Create;
  try
    for Section in TRegEx.Matches(Body,
      '\bpublished\b(.*?)(?=\b(?:private|protected|public|strict|published)\b|\z)', [roIgnoreCase, roSingleLine]) do
      for PM in TRegEx.Matches(Section.Groups[1].Value, '\bprocedure\s+(\w+)\s*(?:\(([^)]*)\))?\s*;', [roIgnoreCase]) do
      begin
        Params.Clear;
        if (PM.Groups.Count > 2) and PM.Groups[2].Success then
          for Param in PM.Groups[2].Value.Split([';']) do
            if PyStrip(Param) <> '' then
              Params.Add(PyStrip(Param));
        Result.AddOrSetValue(PM.Groups[1].Value.ToLower, Params.ToArray);
      end;
  finally
    Params.Free;
  end;
end;

function ParamType(const ADecl: string): string;
var
  I: Integer;
begin
  I := ADecl.IndexOf(':');
  if I < 0 then
    Result := ''
  else
    Result := PyStrip(ADecl.Substring(I + 1)).ToLower;
end;

{ TTypeIndex }

constructor TTypeIndex.Create(const APath: string);
begin
  inherited Create;
  FJson := TJSONObject.ParseJSONValue(TFile.ReadAllText(APath, TEncoding.UTF8)) as TJSONObject;
  if FJson = nil then
    raise ECodeGenError.Create(APath + ': not a JSON object');
  FTypes := FJson.GetValue('types') as TJSONObject;
  FClasses := FJson.GetValue('classes') as TJSONObject;
  FCustomClasses := TStringList.Create;
  FCustomClasses.CaseSensitive := True;
  // src\Generated\RADWinUI.Xaml.json -> src\Framework\RADWinUI.Controls.json
  LoadCustom(TPath.Combine(ExtractFileDir(ExtractFileDir(TPath.GetFullPath(APath))),
    'Framework\RADWinUI.Controls.json'));
end;

destructor TTypeIndex.Destroy;
begin
  FCustomClasses.Free;
  FCustomJson.Free;
  FJson.Free;
  inherited;
end;

procedure TTypeIndex.LoadCustom(const APath: string);
var
  Classes: TJSONObject;
  Pair: TJSONPair;
begin
  if not FileExists(APath) then
    Exit;
  FCustomJson := TJSONObject.ParseJSONValue(TFile.ReadAllText(APath, TEncoding.UTF8)) as TJSONObject;
  if FCustomJson = nil then
    raise ECodeGenError.Create(APath + ': not a JSON object');
  FCustomTypes := FCustomJson.GetValue('types') as TJSONObject;
  Classes := FCustomJson.GetValue('classes') as TJSONObject;
  for Pair in Classes do
  begin
    FClasses.AddPair(Pair.JsonString.Value, Pair.JsonValue.Clone as TJSONValue);
    FCustomClasses.Add(Pair.JsonString.Value);
  end;
end;

function TTypeIndex.CustomElement(const ATag: string): string;
var
  Value: TJSONValue;
begin
  Result := '';
  if FCustomTypes = nil then
    Exit;
  Value := FCustomTypes.GetValue(ATag);
  if Value <> nil then
    Result := Value.Value;
end;

function TTypeIndex.IsCustom(const AClass: string): Boolean;
begin
  Result := FCustomClasses.IndexOf(AClass) >= 0;
end;

function TTypeIndex.UnitOf(const AClass: string): string;
var
  Value: TJSONValue;
begin
  Value := ClassInfo(AClass).GetValue('unit');
  if Value = nil then
    Result := ''
  else
    Result := Value.Value;
end;

function TTypeIndex.ClassInfo(const AClass: string): TJSONObject;
begin
  Result := FClasses.GetValue(AClass) as TJSONObject;
  if Result = nil then
    raise ECodeGenError.Create('RADWinUI.Xaml.json has no class ' + AClass);
end;

function TTypeIndex.BaseOf(AInfo: TJSONObject): string;
var
  Base: TJSONValue;
begin
  Base := AInfo.GetValue('base');
  if (Base = nil) or (Base is TJSONNull) then
    Result := ''
  else
    Result := Base.Value;
end;

function TTypeIndex.Element(const ATag: string): string;
var
  Value: TJSONValue;
begin
  Value := FTypes.GetValue(ATag);
  if Value = nil then
    Result := ''
  else
    Result := Value.Value;
end;

function TTypeIndex.Wrapper(const AClass: string): string;
begin
  Result := ClassInfo(AClass).GetValue('wrapper').Value;
end;

function TTypeIndex.Event(const AClass, AName: string; out AInfo: TEventInfo): Boolean;
var
  Cls: string;
  Info: TJSONObject;
  Ev: TJSONArray;
begin
  Cls := AClass;
  while Cls <> '' do
  begin
    Info := ClassInfo(Cls);
    Ev := (Info.GetValue('events') as TJSONObject).GetValue(AName) as TJSONArray;
    if Ev <> nil then
    begin
      AInfo.Name := AName;
      AInfo.Handler := Ev.Items[0].Value;
      AInfo.Args := Ev.Items[1].Value;
      Exit(True);
    end;
    Cls := BaseOf(Info);
  end;
  Result := False;
end;

function TTypeIndex.Events(const AClass: string): TArray<TEventInfo>;
var
  Cls: string;
  Info: TJSONObject;
  Pair: TJSONPair;
  List: TList<TEventInfo>;
  Seen: TStringList;
  Item: TEventInfo;
  I, J: Integer;
begin
  List := TList<TEventInfo>.Create;
  Seen := TStringList.Create;
  try
    Seen.CaseSensitive := True;
    Cls := AClass;
    while Cls <> '' do
    begin
      Info := ClassInfo(Cls);
      for Pair in Info.GetValue('events') as TJSONObject do
        if Seen.IndexOf(Pair.JsonString.Value) < 0 then // the most derived class wins
        begin
          Seen.Add(Pair.JsonString.Value);
          Item.Name := Pair.JsonString.Value;
          Item.Handler := (Pair.JsonValue as TJSONArray).Items[0].Value;
          Item.Args := (Pair.JsonValue as TJSONArray).Items[1].Value;
          List.Add(Item);
        end;
      Cls := BaseOf(Info);
    end;
    Result := List.ToArray;
    // sorted by name, ordinal
    for I := 1 to High(Result) do
    begin
      Item := Result[I];
      J := I - 1;
      while (J >= 0) and (CompareStr(Result[J].Name, Item.Name) > 0) do
      begin
        Result[J + 1] := Result[J];
        Dec(J);
      end;
      Result[J + 1] := Item;
    end;
  finally
    Seen.Free;
    List.Free;
  end;
end;

function TTypeIndex.HasProperty(const AClass, AName: string): Boolean;
var
  Cls: string;
  Info: TJSONObject;
  Props: TJSONValue;
begin
  Cls := AClass;
  while Cls <> '' do
  begin
    Info := ClassInfo(Cls);
    Props := Info.GetValue('props');
    if (Props is TJSONObject) and (TJSONObject(Props).GetValue(AName) <> nil) then
      Exit(True);
    Cls := BaseOf(Info);
  end;
  Result := False;
end;

{ TCodeGenerator }

constructor TCodeGenerator.Create(const AXamlPath: string; AIndex: TTypeIndex; const AXamlText, APasText: string;
  AHasTexts: Boolean);
begin
  inherited Create;
  FXamlPath := AXamlPath;
  FIndex := AIndex;
  FXamlText := AXamlText;
  FPasText := APasText;
  FHasTexts := AHasTexts;
  FStem := TPath.GetFileNameWithoutExtension(BaseName(AXamlPath));
  FUnitName := FStem + '.Xaml';
  FFields := TList<TField>.Create;
  FBindings := TList<TBindingInfo>.Create;
  FNamed := TList<TNamed>.Create;
  FAutoWrappers := TDictionary<string, string>.Create;
  FWindowProps := TDictionary<string, string>.Create;
  FResourceKeys := TStringList.Create;
  FResourceKeys.CaseSensitive := True;
  FUnits := TStringList.Create;
  FUnits.Sorted := True;
  FUnits.Duplicates := dupIgnore;
  FUserControls := TDictionary<string, TUserControlInfo>.Create;
end;

destructor TCodeGenerator.Destroy;
begin
  FUserControls.Free;
  FChecker.Free;
  FUnits.Free;
  FResourceKeys.Free;
  FWindowProps.Free;
  FMethods.Free;
  FAutoWrappers.Free;
  FNamed.Free;
  FBindings.Free;
  FFields.Free;
  inherited;
end;

function TCodeGenerator.Where(AElement: TXmlElement): string;
begin
  Result := Format('%s(%d)', [FXamlPath, AElement.Line]);
end;

function IsDesign(const AName: string): Boolean;
begin
  Result := AName.StartsWith(DesignNamespaces[0]) or AName.StartsWith(DesignNamespaces[1]);
end;

/// The app never loads design-time values: d:/mc: elements (their tail text stays) and attributes go.
procedure StripDesign(AElement: TXmlElement);
var
  I: Integer;
  Previous, Child: TXmlElement;
begin
  Previous := nil;
  I := 0;
  while I < AElement.Count do
  begin
    Child := AElement[I];
    if IsDesign(Child.Tag) then
    begin
      if Child.Tail <> '' then
        if Previous = nil then
          AElement.Text := AElement.Text + Child.Tail
        else
          Previous.Tail := Previous.Tail + Child.Tail;
      AElement.Delete(I);
    end
    else
    begin
      Previous := Child;
      Inc(I);
    end;
  end;
  for I := AElement.AttrCount - 1 downto 0 do
    if IsDesign(AElement.AttrName[I]) then
      AElement.Pop(AElement.AttrName[I]);
  for I := 0 to AElement.Count - 1 do
    StripDesign(AElement[I]);
end;

function LocalName(const ATag: string): string;
var
  I: Integer;
begin
  I := ATag.IndexOf('}');
  if I < 0 then
    Result := ATag
  else
    Result := ATag.Substring(I + 1);
end;

function TCodeGenerator.Run: string;
var
  Root, Content, Element: TXmlElement;
  Name, Value, PasPath, Text, PasText: string;
  RootEvents, AttrNames: TArray<string>;
  I: Integer;
  VM: TPasClass;
  Named: TNamed;
  Info: TEventInfo;
  Exists: Boolean;
  B: TBindingInfo;
begin
  try
    if FHasTexts then
      Text := FXamlText
    else
      Text := ReadXmlFile(FXamlPath);
    Root := ParseXml(Text);
  except
    on E: EXmlError do
      raise ECodeGenError.Create(FXamlPath + ': ' + E.Message);
  end;
  try
    if Root.Tag = '{' + Presentation + '}Window' then
      FRootKind := 'Window'
    else if Root.Tag = '{' + Presentation + '}Page' then
      FRootKind := 'Page'
    else if Root.Tag = '{' + Presentation + '}UserControl' then
      FRootKind := 'UserControl'
    else
      raise ECodeGenError.Create(FXamlPath + ': the root element must be <Window>, <Page> or <UserControl>');
    StripDesign(Root);
    FClassName := Root.Get(XClass);
    if (FClassName = '') or not TRegEx.IsMatch(FClassName, '^[A-Za-z_]\w*$') then
      if FRootKind = 'Window' then
        raise ECodeGenError.Create(FXamlPath + ': <Window> needs x:Class with a Pascal class name, ' +
          'for example x:Class="TMainWindow"')
      else
        raise ECodeGenError.CreateFmt('%s: <%s> needs x:Class with a Pascal class name, for example x:Class="%s"',
          [FXamlPath, FRootKind, IfThen(FRootKind = 'Page', 'TContactsPage', 'TContactCard')]);
    FBaseName := FClassName + 'Base';
    FWindowLine := Root.Line;
    RootEvents := nil;
    // a snapshot: page events are removed from the root while the loop runs
    SetLength(AttrNames, Root.AttrCount);
    for I := 0 to Root.AttrCount - 1 do
      AttrNames[I] := Root.AttrName[I];
    for Name in AttrNames do
    begin
      Value := Root.Get(Name);
      if Name = 'DataContextType' then // RADWinUI: the class {Binding} paths are checked against
      begin
        if FRootKind = 'UserControl' then
          raise ECodeGenError.Create(FXamlPath + ': <UserControl> takes no DataContextType, ' +
            'it binds to the DataContext of the place that uses it');
        if not TRegEx.IsMatch(Value, '^[A-Za-z_]\w*$') then
          raise ECodeGenError.Create(FXamlPath + ': DataContextType must be a Pascal class name');
        FDataContextType := Value;
        Root.Pop(Name);
        Continue;
      end;
      if Name.StartsWith('{') then
      begin
        if Name <> XClass then
          raise ECodeGenError.CreateFmt('%s: unsupported attribute %s on <%s>', [FXamlPath, Name, FRootKind]);
        Continue;
      end;
      if FRootKind = 'Window' then
      begin
        if IndexStr(Name, WindowAttributes) < 0 then
          raise ECodeGenError.CreateFmt('%s: <Window> supports %s, not %s',
            [FXamlPath, string.Join(', ', WindowAttributes), Name]);
        FWindowProps.AddOrSetValue(Name, WindowValue(Name, Value));
      end
      else if FRootKind = 'UserControl' then
        raise ECodeGenError.CreateFmt('%s: <UserControl> takes no attributes besides x:Class, ' +
          'set %s on its content element', [FXamlPath, Name])
      else if FIndex.Event('Microsoft.UI.Xaml.Controls.Page', Name, Info) then
      begin
        // An event of the page itself: wired to the page object below, removed from the XAML
        RootEvents := RootEvents + [Name + '=' + Root.Pop(Name)];
      end;
    end;
    Root.Pop(XClass);
    if FRootKind = 'Page' then
      // The whole page is loaded, it may hold resources and one content element
      Content := Root
    else
    begin
      if Root.Count <> 1 then
        raise ECodeGenError.CreateFmt('%s: <%s> must have exactly one content element', [FXamlPath, FRootKind]);
      Content := Root[0];
    end;
    FContentLine := Content.Line;

    PasPath := JoinPath(DirName(FXamlPath), FStem + '.pas');
    if FHasTexts then
      PasText := FPasText
    else if FileExists(PasPath) then
      PasText := TFile.ReadAllText(PasPath, TEncoding.UTF8)
    else
      PasText := '';
    FMethods := PublishedMethods(PasText, FClassName);
    FPasName := BaseName(PasPath);
    if FRootKind = 'UserControl' then
      FOwnProperties := UserProperties(PasText);
    LoadUserControls;

    FChecker := TBindingChecker.Create(ExtractFileDir(TPath.GetFullPath(FXamlPath)));
    if FDataContextType <> '' then
    begin
      VM := FChecker.RequireClass(FDataContextType, Where(Root));
      // The generated base declares `property ViewModel: TName`, so it uses the
      // unit of TName, that cannot be the window unit, which uses the base.
      if VM.UnitName.ToLower = FStem.ToLower then
        raise ECodeGenError.CreateFmt('%s: DataContextType %s is declared in %s, which uses the generated base; ' +
          'move %s to its own unit (for example %sViewModel.pas)',
          [Where(Root), VM.Name, VM.UnitFile, VM.Name, FStem]);
      FDataContextType := VM.Name;
      FViewModelUnit := VM.UnitName;
    end;
    // x:Key resources declared in the XAML count as converters too
    for Element in Root.Iter do
      if Element.Get(XKey) <> '' then
        FResourceKeys.Add(Element.Get(XKey));
    for Text in RootEvents do
    begin
      Name := Text.Substring(0, Text.IndexOf('='));
      FIndex.Event('Microsoft.UI.Xaml.Controls.Page', Name, Info);
      Bind('Self', Name, Text.Substring(Text.IndexOf('=') + 1), Info.Handler, Info.Args, True, Root.Line);
    end;
    if FRootKind = 'Page' then
      // the page element itself is no field: walk its children
      for I := 0 to Root.Count - 1 do
        Walk(Root[I], FDataContextType, False)
    else
      Walk(Content, FDataContextType, False);
    for Named in FNamed do
      if Named.IsUser then
      begin
        for Text in Named.UserEvents do
          if FMethods.ContainsKey((Named.Name + Text).ToLower) then
          begin
            Exists := False;
            for B in FBindings do
              if (B.Element = Named.Name) and (B.Event = Text) then
                Exists := True;
            if not Exists then
              Bind(Named.Name, Text, Named.Name + Text, 'TWinUIWinValueEventHandler', 'TWinValue', False,
                Named.Line, True);
          end;
      end
      else
        for Info in FIndex.Events(Named.ClassName) do
          if FMethods.ContainsKey((Named.Name + Info.Name).ToLower) then
          begin
            Exists := False;
            for B in FBindings do
              if (B.Element = Named.Name) and (B.Event = Info.Name) then
                Exists := True;
            if not Exists then
              Bind(Named.Name, Info.Name, Named.Name + Info.Name, Info.Handler, Info.Args, False, Named.Line,
                FIndex.IsCustom(Named.ClassName));
          end;
    if FTitleBar <> '' then
    begin
      Exists := False;
      for Named in FNamed do
        Exists := Exists or (Named.Name = FTitleBar);
      if not Exists then
        raise ECodeGenError.CreateFmt('%s: <Window TitleBar="%s">: no element has x:Name="%s"',
          [FXamlPath, FTitleBar, FTitleBar]);
    end;
    if FRootKind = 'Page' then
      Result := EmitPage(SetContent(ToXml(Content, Registered)))
    else if FRootKind = 'UserControl' then
      Result := EmitUserControl(SetContent(ToXml(Content, Registered)))
    else
    Result := Emit(SetContent(ToXml(Content, Registered)));
  finally
    Root.Free;
  end;
end;

function TCodeGenerator.WindowValue(const AName, AValue: string): string;
var
  Value, Match, Choice: string;
  Choices: TArray<string>;
begin
  Value := PyStrip(AValue);
  if AName = 'Title' then
    Exit(AName + ' := ' + PascalString(AValue) + ';');
  if AName = 'TitleBar' then
  begin
    if not TRegEx.IsMatch(Value, '^[A-Za-z_]\w*$') then
      raise ECodeGenError.CreateFmt('%s: <Window TitleBar="%s"> must name an element (its x:Name)', [FXamlPath, AValue]);
    FTitleBar := Value;
    Exit('');
  end;
  if (AName = 'Width') or (AName = 'Height') or (AName = 'MinWidth') or (AName = 'MinHeight') or (AName = 'MaxWidth') or
    (AName = 'MaxHeight') then
  begin
    if not TRegEx.IsMatch(Value, '^\d{1,5}$') then
      raise ECodeGenError.CreateFmt('%s: <Window %s="%s"> is not valid', [FXamlPath, AName, AValue]);
    Exit(Format('%s := %d;', [AName, StrToInt(Value)]));
  end;
  if (AName = 'ExtendsContentIntoTitleBar') or (AName = 'ShowActivated') or (AName = 'AlwaysOnTop') or
    (AName = 'Resizable') or (AName = 'Minimizable') or (AName = 'Maximizable') then
  begin
    if (Value.ToLower <> 'true') and (Value.ToLower <> 'false') then
      raise ECodeGenError.CreateFmt('%s: <Window %s="%s"> is not valid', [FXamlPath, AName, AValue]);
    Exit(Format('%s := %s;', [AName, Value.Substring(0, 1).ToUpper + Value.Substring(1).ToLower]));
  end;
  if AName = 'Backdrop' then
    Choices := TArray<string>.Create('None', 'Mica', 'MicaAlt', 'Acrylic', 'Transparent')
  else if AName = 'WindowStyle' then
    Choices := TArray<string>.Create('Normal', 'Overlay')
  else if AName = 'Dock' then
    Choices := TArray<string>.Create('None', 'TopCenter', 'TopLeft', 'TopRight', 'BottomCenter')
  else if AName = 'ClickThrough' then
    Choices := TArray<string>.Create('None', 'Background')
  else if AName = 'WindowState' then
    Choices := TArray<string>.Create('Normal', 'Minimized', 'Maximized', 'FullScreen', 'CompactOverlay')
  else
    Choices := TArray<string>.Create('Manual', 'CenterScreen', 'CenterOwner');
  Match := '';
  for Choice in Choices do
    if Choice.ToLower = Value.ToLower then
    begin
      Match := Choice;
      Break;
    end;
  if Match = '' then
    raise ECodeGenError.CreateFmt('%s: <Window %s> must be one of %s', [FXamlPath, AName, string.Join(', ', Choices)]);
  if AName = 'Backdrop' then
    Exit('Backdrop := TWinUIBackdrop.' + Match + ';');
  if AName = 'WindowStyle' then
    Exit('WindowStyle := TWinUIWindowStyle.' + Match + ';');
  if AName = 'Dock' then
    Exit('Dock := TWinUIDock.' + Match + ';');
  if AName = 'ClickThrough' then
    Exit('ClickThrough := TWinUIClickThrough.' + Match + ';');
  if AName = 'WindowState' then
    Exit('WindowState := TWinUIWindowState.' + Match + ';');
  if Match = 'CenterScreen' then
    Result := 'Center;'
  else if Match = 'CenterOwner' then
    Result := 'CenterOnOwner;'
  else
    Result := '';
end;

procedure TCodeGenerator.CheckBindings(AElement: TXmlElement; const AScope: string);
var
  I: Integer;
  Binding: TBinding;
begin
  for I := 0 to AElement.AttrCount - 1 do
  begin
    Binding := ParseBinding(AElement.AttrValue[I]);
    if Binding = nil then
      Continue;
    try
      FChecker.CheckConverter(Binding, FResourceKeys, Where(AElement));
      if AScope <> '' then
        FChecker.Check(Binding, AScope, Where(AElement));
    finally
      Binding.Free;
    end;
  end;
end;

procedure TCodeGenerator.Walk(AElement: TXmlElement; const AScope: string; AInTemplate: Boolean);
var
  Tag, Local, Cls, Name, UserName, DataType, Attr, Method, Scope: string;
  IsPresentation, IsCustom: Boolean;
  Attrs: TArray<string>;
  Info: TEventInfo;
  Field: TField;
  Named: TNamed;
  I: Integer;
begin
  Tag := AElement.Tag;
  Local := LocalName(Tag);
  IsPresentation := Tag.StartsWith('{' + Presentation + '}');
  IsCustom := Tag.StartsWith('{' + CustomNamespace + '}');
  if IsPresentation and Local.EndsWith('Template') then
  begin
    // Template content is instantiated per item: no window fields or events,
    // its bindings are checked against x:DataType when the template declares one.
    DataType := AElement.Pop(XDataType);
    if DataType <> '' then
      FChecker.RequireClass(DataType, Where(AElement));
    for I := 0 to AElement.Count - 1 do
      Walk(AElement[I], DataType, True);
    Exit;
  end;
  CheckBindings(AElement, AScope);
  Scope := AScope;
  if AElement.Has('DataContext') then
    Scope := ''; // descendants bind to another object
  if AInTemplate then
  begin
    for I := 0 to AElement.Count - 1 do
      Walk(AElement[I], Scope, True);
    Exit;
  end;
  // <local:ContactCard>: a user control of the project, in any using: namespace
  if Tag.StartsWith('{using:') and not IsCustom and not Local.Contains('.') then
  begin
    WalkUserControl(AElement, Local);
    for I := 0 to AElement.Count - 1 do
      Walk(AElement[I], Scope, False);
    Exit;
  end;
  if (IsPresentation or IsCustom) and not Local.Contains('.') then // Button.Flyout is a property element
  begin
    if IsCustom then
    begin
      Cls := FIndex.CustomElement(Local);
      if Cls = '' then
        raise ECodeGenError.CreateFmt('%s: <rw:%s> is not a RADWinUI control (see src\Framework\RADWinUI.Controls.json)',
          [Where(AElement), Local]);
      FUnits.Add(FIndex.UnitOf(Cls));
    end
    else
      Cls := FIndex.Element(Local);
    Name := AElement.Get(XName);
    if Name = '' then
      Name := AElement.Get('Name');
    if Cls <> '' then
    begin
      SetLength(Attrs, AElement.AttrCount);
      for I := 0 to AElement.AttrCount - 1 do
        Attrs[I] := AElement.AttrName[I];
      for Attr in Attrs do
      begin
        if Attr.StartsWith('{') or Attr.Contains('.') then
          Continue;
        if not FIndex.Event(Cls, Attr, Info) then
          Continue;
        Method := AElement.Pop(Attr);
        if Name = '' then
        begin
          Inc(FAutoNames);
          Name := '_rw' + IntToStr(FAutoNames);
          AElement.SetAttr(XName, Name);
          FAutoWrappers.AddOrSetValue(Name, FIndex.Wrapper(Cls));
        end;
        Bind(Name, Attr, Method, Info.Handler, Info.Args, True, AElement.Line, FIndex.IsCustom(Cls));
      end;
      UserName := AElement.Get(XName);
      if UserName = '' then
        UserName := AElement.Get('Name');
      if (UserName <> '') and not UserName.StartsWith('_rw') then
      begin
        CheckFieldName(UserName);
        Field.Name := UserName;
        Field.Wrapper := FIndex.Wrapper(Cls);
        if Cls = 'Microsoft.UI.Xaml.Controls.Frame' then
        begin
          // A frame navigates between the project's pages (RADWinUI.Pages)
          Field.Wrapper := 'TWinUIPageFrame';
          FUnits.Add('RADWinUI.Pages');
        end;
        Field.Line := AElement.Line;
        Field.Tag := Local;
        FFields.Add(Field);
        Named := Default(TNamed);
        Named.Name := UserName;
        Named.ClassName := Cls;
        Named.Line := AElement.Line;
        FNamed.Add(Named);
      end;
    end;
  end;
  for I := 0 to AElement.Count - 1 do
    Walk(AElement[I], Scope, False);
end;

procedure TCodeGenerator.Bind(const AElement, AEvent, AMethod, AHandler, AArgs: string; AExplicit: Boolean;
  ALine: Integer; ACustom: Boolean);
var
  Params: TArray<string>;
  HasParams: Boolean;
  B: TBindingInfo;
  Count: Integer;
  T: string;
begin
  HasParams := FMethods.TryGetValue(AMethod.ToLower, Params);
  if not HasParams and AExplicit and (FMethods.Count > 0) then
    // Say how to fix it: the designer may have added the attribute
    // and the method may be missing, unsaved or deleted since
    raise ECodeGenError.CreateFmt('%s(%d): %s="%s" has no published method %s in %s (%s). Add ' +
      '"procedure %s(Sender: TObject; E: %s);" to the published section of %s (RADWinUI Properties, ' +
      'Events tab, ... does it) and save %s, or remove %s="%s" from the XAML',
      [FXamlPath, ALine, AEvent, AMethod, AMethod, FClassName, FPasName, AMethod, AArgs, FClassName, FPasName,
       AEvent, AMethod]);
  if HasParams then
    Count := Length(Params)
  else
    Count := 2; // no companion unit to check: wire the full signature
  if (Count = 2) and HasParams then
  begin
    T := ParamType(Params[1]);
    if (T <> AArgs.ToLower) and (T <> '') then
      raise ECodeGenError.CreateFmt('%s: %s must be (Sender: TObject; E: %s) or (Sender: TObject) for %s',
        [FXamlPath, AMethod, AArgs, AEvent]);
  end;
  if (Count <> 1) and (Count <> 2) then
    raise ECodeGenError.CreateFmt('%s: %s must be (Sender: TObject; E: %s) or (Sender: TObject) for %s',
      [FXamlPath, AMethod, AArgs, AEvent]);
  B.Element := AElement;
  B.Event := AEvent;
  B.Method := AMethod;
  B.Handler := AHandler;
  B.Args := AArgs;
  B.Count := Count;
  B.Line := ALine;
  B.Custom := ACustom;
  if AExplicit then
    B.How := 'attribute'
  else
    B.How := 'name';
  FBindings.Add(B);
end;

// Names that the regular expression's first group finds in APasText, in order, without duplicates
function NamesIn(const APasText, APattern: string): TArray<string>;
var
  M: TMatch;
  Text: string;
begin
  Result := nil;
  Text := TRegEx.Replace(APasText, '//[^\n]*|\{[^}]*\}|\(\*.*?\*\)', '', [roSingleLine]);
  for M in TRegEx.Matches(Text, APattern, [roIgnoreCase]) do
    if IndexText(M.Groups[1].Value, Result) < 0 then
      Result := Result + [M.Groups[1].Value];
end;

function UserProperties(const APasText: string): TArray<string>;
begin
  Result := NamesIn(APasText, 'AddProperty\(\s*''(\w+)''');
end;

procedure TCodeGenerator.LoadUserControls;
var
  Folder, Path, Text, PasPath, PasText: string;
  M: TMatch;
  Info: TUserControlInfo;
begin
  Folder := DirName(FXamlPath);
  if Folder = '' then
    Folder := '.';
  if not TDirectory.Exists(Folder) then
    Exit;
  for Path in TDirectory.GetFiles(Folder, '*.xaml') do
  begin
    if FHasTexts and SameText(TPath.GetFullPath(Path), TPath.GetFullPath(FXamlPath)) then
      Text := FXamlText
    else
      Text := ReadXmlFile(Path);
    M := TRegEx.Match(Text, '^\s*(?:<\?[^>]*>\s*)?(?:<!--.*?-->\s*)*<UserControl\b[^>]*?\sx:Class\s*=\s*"([A-Za-z_]\w*)"',
      [roSingleLine]);
    if not M.Success then
      Continue;
    Info := Default(TUserControlInfo);
    Info.ClassName := M.Groups[1].Value;
    Info.UnitName := TPath.GetFileNameWithoutExtension(Path);
    Info.XamlFile := TPath.GetFullPath(Path);
    PasPath := TPath.ChangeExtension(Path, '.pas');
    if FHasTexts and SameText(Info.XamlFile, TPath.GetFullPath(FXamlPath)) then
      PasText := FPasText
    else if FileExists(PasPath) then
      PasText := TFile.ReadAllText(PasPath, TEncoding.UTF8)
    else
      PasText := '';
    Info.Properties := UserProperties(PasText);
    Info.Events := NamesIn(PasText, 'AddEvent\(\s*''(\w+)''');
    Info.OnEvents := NamesIn(PasText, '\bproperty\s+On(\w+)\s*:');
    FUserControls.AddOrSetValue(XamlNameOf(Info.ClassName), Info);
  end;
end;

procedure TCodeGenerator.CheckFieldName(const AName: string);
var
  Field: TField;
  Reserved: string;
begin
  if FRootKind = 'Window' then
  begin
    if InList(ReservedNames, AName.ToLower) or InList(PascalReserved, AName.ToLower) then
      raise ECodeGenError.CreateFmt('%s: x:Name="%s" would hide a window member; choose another name',
        [FXamlPath, AName]);
  end
  else
  begin
    if FRootKind = 'Page' then
      Reserved := PageReservedNames
    else
      Reserved := UserControlReservedNames;
    if InList(Reserved, AName.ToLower) or InList(PascalReserved, AName.ToLower) or
      (IndexText(AName, FOwnProperties) >= 0) then
      raise ECodeGenError.CreateFmt('%s: x:Name="%s" would hide a member of %s; choose another name',
        [FXamlPath, AName, FClassName]);
  end;
  for Field in FFields do
    if Field.Name.ToLower = AName.ToLower then
      raise ECodeGenError.CreateFmt('%s: duplicate x:Name="%s"', [FXamlPath, AName]);
end;

procedure TCodeGenerator.WalkUserControl(AElement: TXmlElement; const ALocal: string);
const
  BaseClass = 'Microsoft.UI.Xaml.Controls.ContentControl';
var
  UC: TUserControlInfo;
  Name, Attr, Method: string;
  Attrs: TArray<string>;
  I: Integer;
  Info: TEventInfo;
  Field: TField;
  Named: TNamed;
  Auto: Boolean;
begin
  if not FUserControls.TryGetValue(ALocal, UC) then
    raise ECodeGenError.CreateFmt('%s: <%s> is not a user control of this project: no .xaml file next to %s ' +
      'has <UserControl x:Class="T%s">', [Where(AElement), ALocal, BaseName(FXamlPath), ALocal]);
  if SameText(UC.XamlFile, TPath.GetFullPath(FXamlPath)) then
    raise ECodeGenError.CreateFmt('%s: the user control %s cannot contain itself', [Where(AElement), UC.ClassName]);
  FUnits.Add(UC.UnitName);
  Name := AElement.Get(XName);
  if Name = '' then
    Name := AElement.Get('Name');
  Auto := False;
  SetLength(Attrs, AElement.AttrCount);
  for I := 0 to AElement.AttrCount - 1 do
    Attrs[I] := AElement.AttrName[I];
  for Attr in Attrs do
  begin
    if Attr.StartsWith('{') or Attr.Contains('.') then
      Continue;
    if (IndexText(Attr, UC.Properties) >= 0) or FIndex.HasProperty(BaseClass, Attr) then
      Continue;
    if (IndexText(Attr, UC.Events) < 0) and not FIndex.Event(BaseClass, Attr, Info) then
      raise ECodeGenError.CreateFmt('%s: %s has no property or event %s (its own properties: %s; events: %s)',
        [Where(AElement), UC.ClassName, Attr, string.Join(', ', UC.Properties), string.Join(', ', UC.Events)]);
    Method := AElement.Pop(Attr);
    if Name = '' then
    begin
      Inc(FAutoNames);
      Name := '_rw' + IntToStr(FAutoNames);
      AElement.SetAttr(XName, Name);
      FAutoWrappers.AddOrSetValue(Name, UC.ClassName);
      Auto := True;
    end;
    if IndexText(Attr, UC.Events) >= 0 then
    begin
      Bind(Name, Attr, Method, 'TWinUIWinValueEventHandler', 'TWinValue', True, AElement.Line, True);
      if (FBindings.Last.Count = 2) and (IndexText(Attr, UC.OnEvents) < 0) then
        raise ECodeGenError.CreateFmt('%s: %s="%s" with (Sender: TObject; const E: TWinValue) needs ' +
          '"property On%s: TWinUIWinValueEventHandler index N read GetHandler write SetHandler;" in the published ' +
          'section of %s, or the short form %s(Sender: TObject)',
          [Where(AElement), Attr, Method, Attr, UC.ClassName, Method]);
    end
    else
      Bind(Name, Attr, Method, Info.Handler, Info.Args, True, AElement.Line);
  end;
  if (Name <> '') and not Auto and not Name.StartsWith('_rw') then
  begin
    CheckFieldName(Name);
    Field.Name := Name;
    Field.Wrapper := UC.ClassName;
    Field.Line := AElement.Line;
    Field.Tag := ALocal;
    FFields.Add(Field);
    Named := Default(TNamed);
    Named.Name := Name;
    Named.ClassName := UC.ClassName;
    Named.Line := AElement.Line;
    Named.IsUser := True;
    Named.UserEvents := UC.Events;
    FNamed.Add(Named);
  end;
end;

function TCodeGenerator.EmitPage(const AXaml: string): string;
var
  Lines: TStringBuilder;
  Src, VM, U: string;

  procedure W(const AText: string);
  begin
    Lines.Append(AText).Append(#13#10);
  end;

begin
  Src := BaseName(FXamlPath);
  VM := '';
  if FViewModelUnit <> '' then
    VM := FDataContextType;
  Lines := TStringBuilder.Create;
  try
    W('unit ' + FUnitName + ';');
    W('');
    W('{');
    W('  ' + FBaseName + ': base class of the page ' + FClassName + ', generated from ' + Src);
    W('  by RADWinUI XamlCodeGen ' + CodeGenVersion + ' (tools/XamlCodeGen).');
    W('');
    W('  DO NOT EDIT. Change ' + Src + ' or the published handlers of ' + FClassName);
    W('  in ' + FPasName + '; the build regenerates this unit.');
    W('');
    W('  Fields      one per x:Name element, in XAML order');
    W('  Create      loads the page, fills the fields, wires the events');
    W('  Comments    name the XAML line each item comes from');
    W('}');
    W('');
    W('interface');
    W('');
    W('uses');
    W('  RADWinUI.Framework,');
    W('  RADWinUI.Xaml,');
    for U in FUnits do
      if (U <> '') and (U <> 'RADWinUI.Pages') then
        W('  ' + U + ',');
    if FViewModelUnit <> '' then
    begin
      W('  RADWinUI.Pages,');
      W('  ' + FViewModelUnit + ';  // ' + FDataContextType + ', the DataContextType');
    end
    else
      W('  RADWinUI.Pages;');
    W('');
    W('type');
    W('  // Published handlers of the descendant are found by name (MethodAddress)');
    W('  {$M+}');
    W('  ' + FBaseName + ' = class(TWinUIXamlPage)');
    if VM <> '' then
    begin
      W('  strict private');
      W('    FViewModel: ' + VM + ';');
      W('    procedure SetViewModel(AValue: ' + VM + ');');
    end;
    W('  protected');
    Lines.Append(FieldLines);
    W('    procedure WireXaml;');
    W('    {$IFDEF DEBUG}');
    W('    procedure ReloadXaml(const AXaml: string);');
    W('    {$ENDIF}');
    W('  public');
    W('    constructor Create; override;');
    if VM <> '' then
    begin
      W('    /// <summary>');
      W('    ///   The ' + VM + ' the XAML binds to (' + Src + '(' + IntToStr(FWindowLine) + '): DataContextType);');
      W('    ///   setting it sets DataContext. The page does not own it.');
      W('    /// </summary>');
      W('    property ViewModel: ' + VM + ' read FViewModel write SetViewModel;');
    end;
    W('  end;');
    W('  {$M-}');
    W('');
    W('implementation');
    W('');
    W('{$IFDEF DEBUG}');
    W('uses');
    W('  RADWinUI.HotReload;');
    W('{$ENDIF}');
    W('');
    W('const');
    W('  // ' + Src + '(' + IntToStr(FContentLine) + '): the page; event attributes became the');
    W('  // wiring below, x:Class, x:DataType and RADWinUI attributes are removed');
    W('  PageXaml =');
    W('    ' + PascalString(AXaml) + ';');
    W('  {$IFDEF DEBUG}');
    W('  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild');
    W('  XamlShape = ' + PascalString(Shape) + ';');
    W('  {$ENDIF}');
    W('');
    W('constructor ' + FBaseName + '.Create;');
    W('begin');
    W('  inherited CreateFromXaml(PageXaml);');
    W('  WireXaml;');
    Lines.Append(WiringLines(True));
    W('  {$IFDEF DEBUG}');
    W('  AddHelper(TXamlHotReload.Watch(Self, ''' + Src + ''', XamlShape, ReloadXaml));');
    W('  {$ENDIF}');
    W('end;');
    W('');
    W('// The x:Name fields and the event wiring of the content, again after a hot reload');
    W('procedure ' + FBaseName + '.WireXaml;');
    W('begin');
    Lines.Append(WiringLines(False));
    W('end;');
    W('');
    Lines.Append(HotReloadLines('ReplaceXaml'));
    if VM <> '' then
    begin
      W('procedure ' + FBaseName + '.SetViewModel(AValue: ' + VM + ');');
      W('begin');
      W('  FViewModel := AValue;');
      W('  DataContext := AValue;');
      W('end;');
      W('');
    end;
    W('end.');
    Result := Lines.ToString;
  finally
    Lines.Free;
  end;
end;

function TCodeGenerator.EmitUserControl(const AXaml: string): string;
var
  Lines: TStringBuilder;
  Src, U: string;

  procedure W(const AText: string);
  begin
    Lines.Append(AText).Append(#13#10);
  end;

begin
  Src := BaseName(FXamlPath);
  Lines := TStringBuilder.Create;
  try
    W('unit ' + FUnitName + ';');
    W('');
    W('{');
    W('  ' + FBaseName + ': base class of the user control ' + FClassName + ', generated from ' + Src);
    W('  by RADWinUI XamlCodeGen ' + CodeGenVersion + ' (tools/XamlCodeGen).');
    W('');
    W('  DO NOT EDIT. Change ' + Src + ' or the published handlers of ' + FClassName);
    W('  in ' + FPasName + '; the build regenerates this unit.');
    W('');
    W('  Fields      one per x:Name element, in XAML order');
    W('  Initialize  loads the content, fills the fields, wires the events');
    W('  Register    makes ' + FClassName + ' the XAML element <local:' + XamlNameOf(FClassName) + '>');
    W('  Comments    name the XAML line each item comes from');
    W('}');
    W('');
    W('interface');
    W('');
    W('uses');
    W('  RADWinUI.Framework,');
    W('  RADWinUI.Xaml,');
    for U in FUnits do
      if (U <> '') and (U <> 'RADWinUI.CustomControls') then
        W('  ' + U + ',');
    W('  RADWinUI.CustomControls;');
    W('');
    W('type');
    W('  // Published handlers of the descendant are found by name (MethodAddress)');
    W('  {$M+}');
    W('  ' + FBaseName + ' = class(TWinUIXamlUserControl)');
    W('  protected');
    Lines.Append(FieldLines);
    W('    procedure WireXaml;');
    W('    {$IFDEF DEBUG}');
    W('    procedure ReloadXaml(const AXaml: string);');
    W('    {$ENDIF}');
    W('    procedure Initialize; override;');
    W('  end;');
    W('  {$M-}');
    W('');
    W('implementation');
    W('');
    W('uses');
    W('  {$IFDEF DEBUG}');
    W('  RADWinUI.HotReload,');
    W('  {$ENDIF}');
    W('  ' + FStem + ';  // ' + FClassName + ', registered below');
    W('');
    W('const');
    W('  // ' + Src + '(' + IntToStr(FContentLine) + '): the content element; event attributes became the');
    W('  // wiring below, x:DataType and RADWinUI attributes are removed');
    W('  ContentXaml =');
    W('    ' + PascalString(AXaml) + ';');
    W('  {$IFDEF DEBUG}');
    W('  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild');
    W('  XamlShape = ' + PascalString(Shape) + ';');
    W('  {$ENDIF}');
    W('');
    W('procedure ' + FBaseName + '.Initialize;');
    W('begin');
    W('  inherited;');
    W('  LoadContentXaml(ContentXaml);');
    W('  WireXaml;');
    Lines.Append(WiringLines(True));
    W('  {$IFDEF DEBUG}');
    W('  AddHelper(TXamlHotReload.Watch(Self, ''' + Src + ''', XamlShape, ReloadXaml));');
    W('  {$ENDIF}');
    W('end;');
    W('');
    W('// The x:Name fields and the event wiring of the content, again after a hot reload');
    W('procedure ' + FBaseName + '.WireXaml;');
    W('begin');
    Lines.Append(WiringLines(False));
    W('end;');
    W('');
    Lines.Append(HotReloadLines('LoadContentXaml'));
    W('initialization');
    W('  TWinUICustomControls.Register(' + FClassName + ', ''' + XamlNameOf(FClassName) + ''', ''User controls'');');
    W('end.');
    Result := Lines.ToString;
  finally
    Lines.Free;
  end;
end;
function TCodeGenerator.FieldLines: string;
var
  Lines: TStringBuilder;
  Src, Decl: string;
  Width: Integer;
  Field: TField;
begin
  Src := BaseName(FXamlPath);
  Lines := TStringBuilder.Create;
  try
    Width := 0;
    for Field in FFields do
      Width := Max(Width, Length('    ' + Field.Name + ': ' + Field.Wrapper + ';'));
    for Field in FFields do
    begin
      Decl := '    ' + Field.Name + ': ' + Field.Wrapper + ';';
      Lines.Append(Decl.PadRight(Width) + '  // ' + Src + '(' + IntToStr(Field.Line) + ') <' + Field.Tag + '>')
        .Append(#13#10);
    end;
    Result := Lines.ToString;
  finally
    Lines.Free;
  end;
end;

function TCodeGenerator.SetContent(const AXaml: string): string;
begin
  FContentXaml := AXaml;
  Result := AXaml;
end;

function TCodeGenerator.Shape: string;
var
  Field: TField;
  B: TBindingInfo;
  Events: TStringList;
begin
  Result := '';
  for Field in FFields do
    Result := Result + 'F:' + Field.Name + ':' + Field.Wrapper + ';';
  Events := TStringList.Create;
  try
    Events.CaseSensitive := True;
    Events.UseLocale := False;
    for B in FBindings do
      Events.Add('E:' + B.Element + '.' + B.Event + '=' + B.Method);
    Events.Sort;
    Result := Result + string.Join(';', Events.ToStringArray);
  finally
    Events.Free;
  end;
end;

// Debug builds only: the method hot reload calls, and the watch the constructor registers
function TCodeGenerator.HotReloadLines(const AReload: string): string;
var
  Src: string;
begin
  Src := BaseName(FXamlPath);
  Result :=
    '{$IFDEF DEBUG}' + #13#10 +
    '// Hot reload: ' + Src + ' edited in the IDE while the app runs' + #13#10 +
    'procedure ' + FBaseName + '.ReloadXaml(const AXaml: string);' + #13#10 +
    'begin' + #13#10 +
    '  ' + AReload + '(AXaml);' + #13#10 +
    '  WireXaml;' + #13#10 +
    'end;' + #13#10 +
    '{$ENDIF}' + #13#10 +
    #13#10;
end;

// The x:Name fields and the event wiring of the generated constructor (or Initialize)
function TCodeGenerator.WiringLines(ARoot: Boolean): string;
var
  Lines: TStringBuilder;
  Src, Target, Source: string;
  I, J: Integer;
  Field: TField;
  Sorted: TArray<TBindingInfo>;
  B: TBindingInfo;

  procedure W(const AText: string);
  begin
    Lines.Append(AText).Append(#13#10);
  end;

  function Before(const A, B: TBindingInfo): Boolean;
  begin
    // sorted by line, attribute wiring before name wiring, then event in lower case
    if A.Line <> B.Line then
      Exit(A.Line < B.Line);
    if (A.How = 'attribute') <> (B.How = 'attribute') then
      Exit(A.How = 'attribute');
    Result := CompareStr(A.Event.ToLower, B.Event.ToLower) < 0;
  end;

begin
  Src := BaseName(FXamlPath);
  Lines := TStringBuilder.Create;
  try
    if not ARoot and (FFields.Count > 0) then
    begin
      W('  // x:Name elements');
      for Field in FFields do
        W('  ' + Field.Name + ' := FindElement<' + Field.Wrapper + '>(''' + Field.Name + ''');');
    end;
    J := 0;
    for B in FBindings do
      if (B.Element = 'Self') = ARoot then
        Inc(J);
    if J > 0 then
      W('  // Event wiring');
    // a stable insertion sort
    Sorted := FBindings.ToArray;
    for I := 1 to High(Sorted) do
    begin
      B := Sorted[I];
      J := I - 1;
      while (J >= 0) and Before(B, Sorted[J]) do
      begin
        Sorted[J + 1] := Sorted[J];
        Dec(J);
      end;
      Sorted[J + 1] := B;
    end;
    for B in Sorted do
    begin
      if (B.Element = 'Self') <> ARoot then
        Continue;
      Target := B.Element;
      if FAutoWrappers.ContainsKey(B.Element) then
        Target := 'FindElement<' + FAutoWrappers[B.Element] + '>(''' + B.Element + ''')';
      if B.How = 'attribute' then
        Source := B.Event + '="' + B.Method + '"'
      else
        Source := B.Method + ' by name';
      W('  // ' + Src + '(' + IntToStr(B.Line) + '): ' + Source);
      if B.Count = 2 then
        W('  ' + Target + '.On' + B.Event + ' := ' + B.Handler + '(PublishedMethod(''' + B.Method + '''));')
      else if B.Custom then
        // a custom control has no typed property per event
        W('  ' + Target + '.EventByName(''' + B.Event + ''').Add(NotifyProc<' + B.Args + '>(''' + B.Method + '''));')
      else
        W('  ' + Target + '.' + B.Event + '.Add(NotifyProc<' + B.Args + '>(''' + B.Method + '''));');
    end;
    Result := Lines.ToString;
  finally
    Lines.Free;
  end;
end;
function TCodeGenerator.Emit(const AXaml: string): string;
var
  Lines: TStringBuilder;
  Src, VM, Statement: string;
  Settings: TList<string>;

  procedure W(const AText: string);
  begin
    Lines.Append(AText).Append(#13#10);
  end;


begin
  Src := BaseName(FXamlPath);
  Lines := TStringBuilder.Create;
  Settings := TList<string>.Create;
  try
    W('unit ' + FUnitName + ';');
    W('');
    W('{');
    W('  ' + FBaseName + ': base class of ' + FClassName + ', generated from ' + Src);
    W('  by RADWinUI XamlCodeGen ' + CodeGenVersion + ' (tools/XamlCodeGen).');
    W('');
    W('  DO NOT EDIT. Change ' + Src + ' or the published handlers of ' + FClassName);
    W('  in ' + FPasName + '; the build regenerates this unit.');
    W('');
    W('  Fields      one per x:Name element, in XAML order');
    W('  Create      window settings, content, fields, event wiring');
    W('  Comments    name the XAML line each item comes from');
    W('}');
    W('');
    W('interface');
    W('');
    W('uses');
    W('  RADWinUI.Framework,');
    W('  RADWinUI.Xaml,');
    for Statement in FUnits do
      if Statement <> '' then
        W('  ' + Statement + ',');
    if FViewModelUnit <> '' then
    begin
      W('  RADWinUI.Forms,');
      W('  ' + FViewModelUnit + ';  // ' + FDataContextType + ', the DataContextType');
    end
    else
      W('  RADWinUI.Forms;');
    W('');
    W('type');
    W('  // Published handlers of the descendant are found by name (MethodAddress)');
    W('  {$M+}');
    W('  ' + FBaseName + ' = class(TWinUIWindow)');
    VM := '';
    if FViewModelUnit <> '' then
      VM := FDataContextType;
    if VM <> '' then
    begin
      W('  strict private');
      W('    FViewModel: ' + VM + ';');
      W('    procedure SetViewModel(AValue: ' + VM + ');');
    end;
    W('  protected');
    Lines.Append(FieldLines);
    W('    procedure WireXaml;');
    W('    {$IFDEF DEBUG}');
    W('    procedure ReloadXaml(const AXaml: string);');
    W('    {$ENDIF}');

    W('  public');
    W('    constructor Create; override;');
    if VM <> '' then
    begin
      W('    /// <summary>');
      W('    ///   The ' + VM + ' the XAML binds to (' + Src + '(' + IntToStr(FWindowLine) + '): DataContextType);');
      W('    ///   setting it sets DataContext. The window does not own it.');
      W('    /// </summary>');
      W('    property ViewModel: ' + VM + ' read FViewModel write SetViewModel;');
    end;
    W('  end;');
    W('  {$M-}');
    W('');
    W('implementation');
    W('');
    W('{$IFDEF DEBUG}');
    W('uses');
    W('  RADWinUI.HotReload;');
    W('{$ENDIF}');
    W('');
    W('const');
    W('  // ' + Src + '(' + IntToStr(FContentLine) + '): the content element; event attributes became the');
    W('  // wiring below, x:DataType and RADWinUI attributes are removed');
    W('  ContentXaml =');
    W('    ' + PascalString(AXaml) + ';');
    W('  {$IFDEF DEBUG}');
    W('  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild');
    W('  XamlShape = ' + PascalString(Shape) + ';');
    W('  {$ENDIF}');
    W('');
    W('constructor ' + FBaseName + '.Create;');
    W('begin');
    W('  inherited;');
    for Statement in WindowAttributes do
      if FWindowProps.ContainsKey(Statement) and (FWindowProps[Statement] <> '') then
        Settings.Add(FWindowProps[Statement]);
    if Settings.Count > 0 then
    begin
      W('  // ' + Src + '(' + IntToStr(FWindowLine) + '): <Window> attributes');
      for Statement in Settings do
        W('  ' + Statement);
    end;
    W('  LoadContent(ContentXaml);');
    W('  WireXaml;');
    Lines.Append(WiringLines(True));
    W('  {$IFDEF DEBUG}');
    W('  AddHelper(TXamlHotReload.Watch(Self, ''' + Src + ''', XamlShape, ReloadXaml));');
    W('  {$ENDIF}');
    W('end;');
    W('');
    W('// The x:Name fields and the event wiring of the content, again after a hot reload');
    W('procedure ' + FBaseName + '.WireXaml;');
    W('begin');
    Lines.Append(WiringLines(False));
    if FTitleBar <> '' then
    begin
      W('  // ' + Src + '(' + IntToStr(FWindowLine) + '): TitleBar="' + FTitleBar + '"');
      W('  UseTitleBar(' + FTitleBar + ');');
    end;
    W('end;');
    W('');
    Lines.Append(HotReloadLines('LoadContent'));
    if VM <> '' then
    begin
      W('procedure ' + FBaseName + '.SetViewModel(AValue: ' + VM + ');');
      W('begin');
      W('  FViewModel := AValue;');
      W('  DataContext := AValue;');
      W('end;');
      W('');
    end;
    W('end.');
    // lines joined with CRLF: the text ends with one line break
    Result := Lines.ToString;
  finally
    Settings.Free;
    Lines.Free;
  end;
end;

function GenerateFile(const AXamlPath: string; AIndex: TTypeIndex): string;
var
  Generator: TCodeGenerator;
  Text: string;
  Bytes: TBytes;
begin
  Generator := TCodeGenerator.Create(AXamlPath, AIndex);
  try
    Text := Generator.Run;
    Result := JoinPath(DirName(AXamlPath), Generator.GeneratedUnit + '.pas');
  finally
    Generator.Free;
  end;
  Bytes := TEncoding.UTF8.GetPreamble + TEncoding.UTF8.GetBytes(Text);
  TFile.WriteAllBytes(Result, Bytes);
end;


function CheckAccessibleNames(const AXamlPath: string): TArray<string>;
const
  Buttons: array[0..8] of string = ('Button', 'AppBarButton', 'AppBarToggleButton', 'ToggleButton', 'RepeatButton',
    'HyperlinkButton', 'DropDownButton', 'SplitButton', 'ToggleSplitButton');
  // Attributes and property elements that give a button its name
  Naming: array[0..6] of string = ('Content', 'Label', 'AutomationProperties.Name', 'AutomationProperties.LabeledBy',
    'ToolTipService.ToolTip', 'Text', '{' + XamlNs + '}Uid');
var
  Root, Element, Inner: TXmlElement;
  Name, Local: string;
  Named: Boolean;
  I: Integer;
begin
  Result := [];
  Root := ParseXml(ReadXmlFile(AXamlPath));
  try
    for Element in Root.Iter do
    begin
      Local := Element.Tag;
      if not Local.StartsWith('{' + Presentation + '}') then
        Continue;
      Local := Local.Substring(Length(Presentation) + 2);
      if IndexStr(Local, Buttons) < 0 then
        Continue;
      Named := Trim(Element.Text) <> '';
      for Inner in Element.Iter do
      begin
        for I := 0 to Inner.AttrCount - 1 do
        begin
          Name := Inner.AttrName[I];
          if (IndexStr(Name, Naming) >= 0) and (Trim(Inner.AttrValue[I]) <> '') then
            Named := True;
        end;
        // <ToolTipService.ToolTip>, and text inside the button: a TextBlock is text, also one the code fills
        Named := Named or Inner.Tag.EndsWith('ToolTipService.ToolTip') or Inner.Tag.EndsWith('}TextBlock') or
          Inner.Tag.EndsWith('}Run') or
          ((Inner <> Element) and (Trim(Inner.Text) <> ''));
      end;
      if not Named then
        Result := Result + [Format('%s(%d): warning RW2003: this %s shows no text and has no AutomationProperties.Name, ' +
          'ToolTip or x:Uid: a screen reader cannot say what it does', [AXamlPath, Element.Line, Local])];
    end;
  finally
    Root.Free;
  end;
end;

function CheckUids(const AFolder: string): TArray<string>;
const
  DefaultResw = 'Strings\en-US\Resources.resw';
var
  Resw, Xaml, Text, XamlText, Key, Uid: string;
  Found: Boolean;
  Keys, Uids: TDictionary<string, Integer>; // key or x:Uid -> line
  M: TMatch;
  Dot: Integer;

  function LineAt(const AText: string; AIndex: Integer): Integer;
  var
    I: Integer;
  begin
    Result := 1;
    for I := 1 to AIndex - 1 do
      if AText[I] = #10 then
        Inc(Result);
  end;

begin
  Result := [];
  Resw := TPath.Combine(AFolder, DefaultResw);
  if not TDirectory.Exists(TPath.Combine(AFolder, 'Strings')) then
    Exit;
  Keys := TDictionary<string, Integer>.Create;
  Uids := TDictionary<string, Integer>.Create;
  try
    if FileExists(Resw) then
    begin
      Text := TFile.ReadAllText(Resw, TEncoding.UTF8);
      for M in TRegEx.Matches(Text, '<data\s+name="([^"]+)"') do
        Keys.AddOrSetValue(M.Groups[1].Value, LineAt(Text, M.Index));
    end;
    for Xaml in TDirectory.GetFiles(AFolder, '*.xaml') do
    begin
      XamlText := TFile.ReadAllText(Xaml, TEncoding.UTF8);
      for M in TRegEx.Matches(XamlText, '\bx:Uid\s*=\s*"([^"]+)"') do
      begin
        Uid := M.Groups[1].Value;
        Uids.AddOrSetValue(Uid, 0);
        Found := False;
        for Key in Keys.Keys do
          Found := Found or Key.StartsWith(Uid + '.');
        if not Found then
          Result := Result + [Format('%s(%d): warning RW2001: x:Uid "%s" has no %s.<Property> key in %s',
            [Xaml, LineAt(XamlText, M.Index), Uid, Uid, DefaultResw])];
      end;
    end;
    // Uid.Property keys belong to an x:Uid, plain keys are for TWinUIResources.GetString
    for Key in Keys.Keys do
    begin
      Dot := Pos('.', Key);
      if (Dot > 1) and not Uids.ContainsKey(Copy(Key, 1, Dot - 1)) then
        Result := Result + [Format('%s(%d): warning RW2002: "%s" belongs to no x:Uid of the XAML files in this folder',
          [Resw, Keys[Key], Key])];
    end;
  finally
    Uids.Free;
    Keys.Free;
  end;
  TArray.Sort<string>(Result);
end;

function RunCodeGen(const AArgs: TArray<string>; const AExeFolder: string): Integer;
var
  IndexPath, Request, Arg, Path, Text: string;
  Args, Paths, Folder: TStringList;
  I: Integer;
  Index: TTypeIndex;
  Json, Response: TJSONObject;
  Generator: TCodeGenerator;
  Folders: TArray<string>;
  Warning: string;
begin
  IndexPath := '';
  Request := '';
  Args := TStringList.Create;
  Paths := TStringList.Create;
  try
    I := 0;
    while I <= High(AArgs) do
    begin
      Arg := AArgs[I];
      if (Arg = '--index') or (Arg = '--ide-request') then
      begin
        if I = High(AArgs) then
        begin
          Writeln(ErrOutput, 'xamlcodegen: error: argument ' + Arg + ': expected one argument');
          Exit(2);
        end;
        Inc(I);
        if Arg = '--index' then
          IndexPath := AArgs[I]
        else
          Request := AArgs[I];
      end
      else if Arg.StartsWith('--index=') then
        IndexPath := Arg.Substring(8)
      else if Arg.StartsWith('--ide-request=') then
        Request := Arg.Substring(14)
      else
        Args.Add(Arg);
      Inc(I);
    end;
    if IndexPath = '' then
      IndexPath := DefaultIndexPath(AExeFolder);
    if Request <> '' then
    begin
      // The IDE owns the buffers. Only this temporary JSON file is written here,
      // the IDE applies the returned Pascal to its generated unit/buffer.
      Response := TJSONObject.Create;
      try
        try
          Json := TJSONObject.ParseJSONValue(TFile.ReadAllText(Request, TEncoding.UTF8)) as TJSONObject;
          try
            if Json = nil then
              raise ECodeGenError.Create(Request + ': not a JSON object');
            Index := TTypeIndex.Create(IndexPath);
            try
              Generator := TCodeGenerator.Create(Json.GetValue('path').Value, Index, Json.GetValue('xaml').Value,
                Json.GetValue('pas').Value, True);
              try
                Response.AddPair('text', Generator.Run);
                // Hot reload: what the running app loads, and what it compares with its compiled code
                if Json.GetValue('hotreload') <> nil then
                begin
                  Response.AddPair('content', Generator.ContentXaml);
                  Response.AddPair('shape', Generator.Shape);
                end;
              finally
                Generator.Free;
              end;
            finally
              Index.Free;
            end;
          finally
            Json.Free;
          end;
        except
          on E: Exception do
            Response.AddPair('error', E.Message);
        end;
        TFile.WriteAllText(Request, Response.ToJSON, TEncoding.UTF8);
        if Response.GetValue('text') <> nil then
          Result := 0
        else
          Result := 1;
      finally
        Response.Free;
      end;
      Exit;
    end;
    if Args.Count = 0 then
    begin
      Writeln(ErrOutput, 'usage: xamlcodegen [-h] [--index INDEX] [xaml ...]');
      Writeln(ErrOutput, 'xamlcodegen: error: provide a XAML file or folder');
      Exit(2);
    end;
    // a folder means every .xaml file in it (IDE pre-build event)
    Folder := TStringList.Create;
    try
      Folder.CaseSensitive := True;
      Folder.UseLocale := False;
      for Path in Args do
        if TDirectory.Exists(Path) then
        begin
          Folder.Clear;
          for Text in TDirectory.GetFiles(Path) do
            if TPath.GetFileName(Text).ToLower.EndsWith('.xaml') then
              Folder.Add(JoinPath(Path, TPath.GetFileName(Text)));
          Folder.Sort;
          Paths.AddStrings(Folder);
        end
        else
          Paths.Add(Path);
    finally
      Folder.Free;
    end;
    try
      Index := TTypeIndex.Create(IndexPath);
      try
        for Path in Paths do
          Writeln(GenerateFile(Path, Index));
      finally
        Index.Free;
      end;
      // Warnings only: the app builds, the text stays what the XAML says
      Folders := [];
      for Path in Paths do
        if IndexText(ExtractFileDir(TPath.GetFullPath(Path)), Folders) < 0 then
          Folders := Folders + [ExtractFileDir(TPath.GetFullPath(Path))];
      for Text in Folders do
        for Warning in CheckUids(Text) do
          Writeln(Warning);
      for Path in Paths do
        for Warning in CheckAccessibleNames(Path) do
          Writeln(Warning);
    except
      on E: Exception do
      begin
        Writeln(ErrOutput, 'error: ' + E.Message);
        Exit(1);
      end;
    end;
    Result := 0;
  finally
    Paths.Free;
    Args.Free;
  end;
end;

end.
