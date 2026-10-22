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
  src\Generated\RADWinUI.Xaml.json, written by WinMDGen.
*)

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON,
  RADWinUI.CodeGen.Xml, RADWinUI.CodeGen.Bindings;

const
  CodeGenVersion = '0.4'; // bump when the generated code changes shape

type
  ECodeGenError = RADWinUI.CodeGen.Bindings.ECodeGenError;

  TEventInfo = record
    Name, Handler, Args: string;
  end;

  /// <summary>Element types and events from RADWinUI.Xaml.json.</summary>
  TTypeIndex = class
  private
    FJson: TJSONObject;
    FTypes, FClasses: TJSONObject;
    function ClassInfo(const AClass: string): TJSONObject;
    function BaseOf(AInfo: TJSONObject): string;
  public
    constructor Create(const APath: string);
    destructor Destroy; override;
    /// <summary>Runtime class of a XAML element in the default namespace, '' when unknown.</summary>
    function Element(const ATag: string): string;
    function Wrapper(const AClass: string): string;
    /// <summary>The event AName of AClass or a base class.</summary>
    function Event(const AClass, AName: string; out AInfo: TEventInfo): Boolean;
    /// <summary>All events of AClass and its bases, sorted by name.</summary>
    function Events(const AClass: string): TArray<TEventInfo>;
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
    end;
    TNamed = record
      Name, ClassName: string;
      Line: Integer;
    end;
  private
    FXamlPath, FXamlText, FPasText: string;
    FHasTexts: Boolean;
    FIndex: TTypeIndex;
    FStem, FUnitName, FClassName, FBaseName, FPasName: string;
    FDataContextType, FViewModelUnit: string;
    FWindowLine, FContentLine, FAutoNames: Integer;
    FFields: TList<TField>;
    FBindings: TList<TBindingInfo>;
    FNamed: TList<TNamed>;
    FAutoWrappers: TDictionary<string, string>;
    FMethods: TDictionary<string, TArray<string>>;
    FWindowProps: TDictionary<string, string>;
    FResourceKeys: TStringList;
    FChecker: TBindingChecker;
    function Where(AElement: TXmlElement): string;
    function WindowValue(const AName, AValue: string): string;
    procedure CheckBindings(AElement: TXmlElement; const AScope: string);
    procedure Walk(AElement: TXmlElement; const AScope: string; AInTemplate: Boolean);
    procedure Bind(const AElement, AEvent, AMethod, AHandler, AArgs: string; AExplicit: Boolean; ALine: Integer);
    function Emit(const AXaml: string): string;
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

implementation

uses
  System.IOUtils, System.RegularExpressions, System.Character, System.StrUtils, System.Math;

const
  Presentation = 'http://schemas.microsoft.com/winfx/2006/xaml/presentation';
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
  WindowAttributes: array[0..7] of string = ('Title', 'Width', 'Height', 'MinWidth', 'MinHeight', 'Backdrop',
    'ExtendsContentIntoTitleBar', 'WindowStartupLocation');
  // Members of TWinUIWindow and its ancestors that an x:Name field would hide
  ReservedNames =
    ',title,content,width,height,minwidth,minheight,backdrop,show,close,center,activate,findelement,' +
    'loadcontent,owner,winrtobject,intf,create,destroy,free,appwindow,dispatcherqueue,systembackdrop,visible,' +
    'bounds,datacontext,';
  PascalReserved =
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
end;

destructor TTypeIndex.Destroy;
begin
  FJson.Free;
  inherited;
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
end;

destructor TCodeGenerator.Destroy;
begin
  FChecker.Free;
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
  Name, Value, PasPath, Text: string;
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
    if Root.Tag <> '{' + Presentation + '}Window' then
      raise ECodeGenError.Create(FXamlPath + ': the root element must be <Window>');
    StripDesign(Root);
    FClassName := Root.Get(XClass);
    if (FClassName = '') or not TRegEx.IsMatch(FClassName, '^[A-Za-z_]\w*$') then
      raise ECodeGenError.Create(FXamlPath + ': <Window> needs x:Class with a Pascal class name, ' +
        'for example x:Class="TMainWindow"');
    FBaseName := FClassName + 'Base';
    for I := 0 to Root.AttrCount - 1 do
    begin
      Name := Root.AttrName[I];
      Value := Root.AttrValue[I];
      if Name = 'DataContextType' then // RADWinUI: the class {Binding} paths are checked against
      begin
        if not TRegEx.IsMatch(Value, '^[A-Za-z_]\w*$') then
          raise ECodeGenError.Create(FXamlPath + ': DataContextType must be a Pascal class name');
        FDataContextType := Value;
        Continue;
      end;
      if Name.StartsWith('{') then
      begin
        if Name <> XClass then
          raise ECodeGenError.CreateFmt('%s: unsupported attribute %s on <Window>', [FXamlPath, Name]);
        Continue;
      end;
      if IndexStr(Name, WindowAttributes) < 0 then
        raise ECodeGenError.CreateFmt('%s: <Window> supports %s, not %s',
          [FXamlPath, string.Join(', ', WindowAttributes), Name]);
      FWindowProps.AddOrSetValue(Name, WindowValue(Name, Value));
    end;
    if Root.Count <> 1 then
      raise ECodeGenError.Create(FXamlPath + ': <Window> must have exactly one content element');
    Content := Root[0];
    FWindowLine := Root.Line;
    FContentLine := Content.Line;

    PasPath := JoinPath(DirName(FXamlPath), FStem + '.pas');
    if FHasTexts then
      FMethods := PublishedMethods(FPasText, FClassName)
    else if FileExists(PasPath) then
      FMethods := PublishedMethods(TFile.ReadAllText(PasPath, TEncoding.UTF8), FClassName)
    else
      FMethods := TDictionary<string, TArray<string>>.Create;
    FPasName := BaseName(PasPath);

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
    Walk(Content, FDataContextType, False);
    for Named in FNamed do
      for Info in FIndex.Events(Named.ClassName) do
        if FMethods.ContainsKey((Named.Name + Info.Name).ToLower) then
        begin
          Exists := False;
          for B in FBindings do
            if (B.Element = Named.Name) and (B.Event = Info.Name) then
              Exists := True;
          if not Exists then
            Bind(Named.Name, Info.Name, Named.Name + Info.Name, Info.Handler, Info.Args, False, Named.Line);
        end;
    Result := Emit(ToXml(Content, Registered));
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
  if (AName = 'Width') or (AName = 'Height') or (AName = 'MinWidth') or (AName = 'MinHeight') then
  begin
    if not TRegEx.IsMatch(Value, '^\d{1,5}$') then
      raise ECodeGenError.CreateFmt('%s: <Window %s="%s"> is not valid', [FXamlPath, AName, AValue]);
    Exit(Format('%s := %d;', [AName, StrToInt(Value)]));
  end;
  if AName = 'ExtendsContentIntoTitleBar' then
  begin
    if (Value.ToLower <> 'true') and (Value.ToLower <> 'false') then
      raise ECodeGenError.CreateFmt('%s: <Window %s="%s"> is not valid', [FXamlPath, AName, AValue]);
    Exit(Format('%s := %s;', [AName, Value.Substring(0, 1).ToUpper + Value.Substring(1).ToLower]));
  end;
  if AName = 'Backdrop' then
    Choices := TArray<string>.Create('None', 'Mica', 'MicaAlt', 'Acrylic')
  else
    Choices := TArray<string>.Create('Manual', 'CenterScreen');
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
  if Match = 'CenterScreen' then
    Result := 'Center;'
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
  IsPresentation: Boolean;
  Attrs: TArray<string>;
  Info: TEventInfo;
  Field: TField;
  Named: TNamed;
  I: Integer;
begin
  Tag := AElement.Tag;
  Local := LocalName(Tag);
  IsPresentation := Tag.StartsWith('{' + Presentation + '}');
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
  if IsPresentation and not Local.Contains('.') then // Button.Flyout is a property element
  begin
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
        Bind(Name, Attr, Method, Info.Handler, Info.Args, True, AElement.Line);
      end;
      UserName := AElement.Get(XName);
      if UserName = '' then
        UserName := AElement.Get('Name');
      if (UserName <> '') and not UserName.StartsWith('_rw') then
      begin
        if InList(ReservedNames, UserName.ToLower) or InList(PascalReserved, UserName.ToLower) then
          raise ECodeGenError.CreateFmt('%s: x:Name="%s" would hide a window member; choose another name',
            [FXamlPath, UserName]);
        for Field in FFields do
          if Field.Name.ToLower = UserName.ToLower then
            raise ECodeGenError.CreateFmt('%s: duplicate x:Name="%s"', [FXamlPath, UserName]);
        Field.Name := UserName;
        Field.Wrapper := FIndex.Wrapper(Cls);
        Field.Line := AElement.Line;
        Field.Tag := Local;
        FFields.Add(Field);
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
  ALine: Integer);
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
  if AExplicit then
    B.How := 'attribute'
  else
    B.How := 'name';
  FBindings.Add(B);
end;

function TCodeGenerator.Emit(const AXaml: string): string;
var
  Lines: TStringBuilder;
  Src, VM, Decl, Target, Source, Statement: string;
  Width, I, J: Integer;
  Field: TField;
  Sorted: TArray<TBindingInfo>;
  B: TBindingInfo;
  Settings: TList<string>;

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
    Width := 0;
    for Field in FFields do
      Width := Max(Width, Length('    ' + Field.Name + ': ' + Field.Wrapper + ';'));
    for Field in FFields do
    begin
      Decl := '    ' + Field.Name + ': ' + Field.Wrapper + ';';
      W(Decl.PadRight(Width) + '  // ' + Src + '(' + IntToStr(Field.Line) + ') <' + Field.Tag + '>');
    end;
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
    W('const');
    W('  // ' + Src + '(' + IntToStr(FContentLine) + '): the content element; event attributes became the');
    W('  // wiring below, x:DataType and RADWinUI attributes are removed');
    W('  ContentXaml =');
    W('    ' + PascalString(AXaml) + ';');
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
    if FFields.Count > 0 then
    begin
      W('  // x:Name elements');
      for Field in FFields do
        W('  ' + Field.Name + ' := FindElement<' + Field.Wrapper + '>(''' + Field.Name + ''');');
    end;
    if FBindings.Count > 0 then
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
      else
        W('  ' + Target + '.' + B.Event + '.Add(NotifyProc<' + B.Args + '>(''' + B.Method + '''));');
    end;
    W('end;');
    W('');
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

function RunCodeGen(const AArgs: TArray<string>; const AExeFolder: string): Integer;
var
  IndexPath, Request, Arg, Path, Text: string;
  Args, Paths, Folder: TStringList;
  I: Integer;
  Index: TTypeIndex;
  Json, Response: TJSONObject;
  Generator: TCodeGenerator;
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
