unit RADWinUI.CodeGen.Bindings;

(*
  Compile-time {Binding} checks of XamlCodeGen.

  A window declares the class it binds to with DataContextType="TProfile" on
  <Window>, a DataTemplate with x:DataType="TContact". Each {Binding Path} in
  that scope must name a published property of the class (nested paths follow
  property types declared in the same folder), and Mode=TwoWay needs a setter.
  Classes come from the .pas files next to the XAML file.
*)

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.RegularExpressions;

type
  /// <summary>A check failed, the message names the file, line and reason.</summary>
  ECodeGenError = class(Exception);

  TPasProperty = record
    Name, TypeName: string;
    Writable, Published: Boolean;
  end;

  TPasClass = class
  public
    Name, Base, UnitFile, UnitName: string;
    Properties: TDictionary<string, TPasProperty>; // lower name -> property
    constructor Create;
    destructor Destroy; override;
  end;

  /// <summary>Binding arguments: Path, Mode, Converter, ... in the order written.</summary>
  TBinding = TDictionary<string, string>;

  TBindingChecker = class
  private
    FFolder: string;
    FClasses: TObjectDictionary<string, TPasClass>;
    FRegistered: TStringList;
    function PropertyOf(AClass: TPasClass; const AName: string; out AProp: TPasProperty): Boolean;
    function PublishedNames(AClass: TPasClass): string;
  public
    constructor Create(const AFolder: string);
    destructor Destroy; override;
    function Find(const AName: string): TPasClass;
    function RequireClass(const AName, AWhere: string): TPasClass;
    procedure CheckConverter(ABinding: TBinding; AResourceKeys: TStrings; const AWhere: string);
    procedure Check(ABinding: TBinding; const AScope, AWhere: string);
  end;

/// <summary>Markup extension arguments split on commas outside quotes and braces.</summary>
function SplitTop(const AText: string): TArray<string>;
/// <summary>{Binding Name, Mode=TwoWay} -> Path=Name, Mode=TwoWay. Returns nil when not a Binding. The caller frees it.</summary>
function ParseBinding(const AValue: string): TBinding;
/// <summary>Removes //, { } and (* *) comments (keeps {$ directives}).</summary>
function StripComments(const AText: string): string;
/// <summary>Removes leading and trailing whitespace.</summary>
function PyStrip(const AText: string): string;

implementation

uses
  System.IOUtils, System.Character;

const
  BuiltInConverters: array[0..2] of string = ('BoolToVisibility', 'InverseBoolToVisibility', 'Format');

function PyStrip(const AText: string): string;
var
  First, Last: Integer;
begin
  First := 1;
  Last := Length(AText);
  while (First <= Last) and AText[First].IsWhiteSpace do
    Inc(First);
  while (Last >= First) and AText[Last].IsWhiteSpace do
    Dec(Last);
  Result := Copy(AText, First, Last - First + 1);
end;

function StripComments(const AText: string): string;
begin
  Result := TRegEx.Replace(AText, '//[^\n]*|\{(?!\$)[^}]*\}|\(\*.*?\*\)', ' ', [roSingleLine]);
end;

/// The .pas/.dpr files of AFolder, sorted by name in ordinal order.
function SortedFiles(const AFolder: string): TArray<string>;
var
  List: TStringList;
  Path: string;
begin
  List := TStringList.Create;
  try
    for Path in TDirectory.GetFiles(AFolder) do
      List.Add(TPath.GetFileName(Path));
    List.CaseSensitive := True;
    List.UseLocale := False; // ordinal order
    List.Sort;
    Result := List.ToStringArray;
  finally
    List.Free;
  end;
end;

{ TPasClass }

constructor TPasClass.Create;
begin
  inherited;
  Properties := TDictionary<string, TPasProperty>.Create;
end;

destructor TPasClass.Destroy;
begin
  Properties.Free;
  inherited;
end;

function SplitTop(const AText: string): TArray<string>;
var
  Parts: TList<string>;
  Depth, Start, I: Integer;
  Quote, Ch: Char;
  Part: string;
begin
  Parts := TList<string>.Create;
  try
    Depth := 0;
    Quote := #0;
    Start := 1;
    for I := 1 to Length(AText) do
    begin
      Ch := AText[I];
      if Quote <> #0 then
      begin
        if Ch = Quote then
          Quote := #0;
      end
      else if CharInSet(Ch, ['''', '"']) then
        Quote := Ch
      else if Ch = '{' then
        Inc(Depth)
      else if Ch = '}' then
        Dec(Depth)
      else if (Ch = ',') and (Depth = 0) then
      begin
        Parts.Add(PyStrip(Copy(AText, Start, I - Start)));
        Start := I + 1;
      end;
    end;
    Parts.Add(PyStrip(Copy(AText, Start, MaxInt)));
    for Part in Parts.ToArray do
      if Part = '' then
        Parts.Remove(Part);
    Result := Parts.ToArray;
  finally
    Parts.Free;
  end;
end;

function ParseBinding(const AValue: string): TBinding;
var
  S, Inner, Part, Key: string;
  M: TMatch;
  Parts: TArray<string>;
  I, Eq: Integer;
begin
  Result := nil;
  S := PyStrip(AValue);
  if not (S.StartsWith('{') and S.EndsWith('}')) then
    Exit;
  Inner := PyStrip(Copy(S, 2, Length(S) - 2));
  M := TRegEx.Match(Inner, '^Binding\b');
  if not M.Success then
    Exit;
  Result := TBinding.Create;
  Parts := SplitTop(Copy(Inner, M.Length + 1, MaxInt));
  for I := 0 to High(Parts) do
  begin
    Part := Parts[I];
    Eq := Part.IndexOf('=');
    if Eq >= 0 then
      Key := Part.Substring(0, Eq);
    if (Eq >= 0) and TRegEx.IsMatch(Key, '^\s*\w+\s*$') then
      Result.AddOrSetValue(PyStrip(Key), PyStrip(Part.Substring(Eq + 1)))
    else if I = 0 then
      Result.AddOrSetValue('Path', Part);
  end;
end;

{ TBindingChecker }

constructor TBindingChecker.Create(const AFolder: string);
var
  FileName, Text, UnitName, Lower, Visibility: string;
  M, VM, PM: TMatch;
  Cls: TPasClass;
  Body, Segment: string;
  Pos, Stop: Integer;
  Prop: TPasProperty;
  Marks: TList<TMatch>;
  I: Integer;
begin
  inherited Create;
  FFolder := AFolder;
  FClasses := TObjectDictionary<string, TPasClass>.Create([doOwnsValues]);
  FRegistered := TStringList.Create;
  FRegistered.CaseSensitive := True;
  for FileName in SortedFiles(AFolder) do
  begin
    Lower := FileName.ToLower;
    if (Lower.EndsWith('.pas') and not Lower.EndsWith('.xaml.pas')) or Lower.EndsWith('.dpr') then
    begin
      Text := StripComments(TFile.ReadAllText(TPath.Combine(AFolder, FileName), TEncoding.UTF8));
      for M in TRegEx.Matches(Text, 'RegisterConverter\s*\(\s*''([^'']+)''', [roIgnoreCase]) do
        FRegistered.Add(M.Groups[1].Value);
    end;
    if not Lower.EndsWith('.pas') or Lower.EndsWith('.xaml.pas') then
      Continue;
    Text := StripComments(TFile.ReadAllText(TPath.Combine(AFolder, FileName), TEncoding.UTF8));
    M := TRegEx.Match(Text, '\bunit\s+([\w.]+)\s*;', [roIgnoreCase]);
    if M.Success then
      UnitName := M.Groups[1].Value
    else
      UnitName := TPath.GetFileNameWithoutExtension(FileName);
    for M in TRegEx.Matches(Text,
      '\b(\w+)\s*=\s*class\b(?!\s*(?:of\b|;))(?:\s*\(\s*([\w.]+)[^)]*\))?(.*?)\bend\s*;',
      [roIgnoreCase, roSingleLine]) do
    begin
      Cls := TPasClass.Create;
      Cls.Name := M.Groups[1].Value;
      Cls.Base := '';
      if (M.Groups.Count > 2) and M.Groups[2].Success then
        Cls.Base := M.Groups[2].Value.Substring(M.Groups[2].Value.LastIndexOf('.') + 1);
      Cls.UnitFile := FileName;
      Cls.UnitName := UnitName;
      // a class's default section, with {$M+} or a TPersistent base
      Visibility := 'published';
      Body := M.Groups[3].Value;
      Pos := 0;
      Marks := TList<TMatch>.Create;
      try
        for VM in TRegEx.Matches(Body, '\b(strict\s+private|strict\s+protected|private|protected|public|published)\b',
          [roIgnoreCase]) do
          Marks.Add(VM);
        for I := 0 to Marks.Count do
        begin
          if I < Marks.Count then
            Stop := Marks[I].Index - 1
          else
            Stop := Length(Body);
          Segment := Copy(Body, Pos + 1, Stop - Pos);
          for PM in TRegEx.Matches(Segment,
            '\bproperty\s+(\w+)\s*:\s*([\w.<>, ]+?)\s+read\s+\w+(\s+write\s+\w+)?', [roIgnoreCase]) do
          begin
            Prop.Name := PM.Groups[1].Value;
            Prop.TypeName := PyStrip(PM.Groups[2].Value);
            Prop.Writable := (PM.Groups.Count > 3) and PM.Groups[3].Success;
            Prop.Published := Visibility = 'published';
            Cls.Properties.AddOrSetValue(Prop.Name.ToLower, Prop);
          end;
          if I < Marks.Count then
          begin
            Visibility := TRegEx.Replace(Marks[I].Groups[1].Value.ToLower, '\s+', ' ');
            Pos := Marks[I].Index - 1 + Marks[I].Length;
          end;
        end;
      finally
        Marks.Free;
      end;
      FClasses.AddOrSetValue(Cls.Name.ToLower, Cls);
    end;
  end;
end;

destructor TBindingChecker.Destroy;
begin
  FRegistered.Free;
  FClasses.Free;
  inherited;
end;

function TBindingChecker.Find(const AName: string): TPasClass;
begin
  if not FClasses.TryGetValue(AName.ToLower, Result) then
    Result := nil;
end;

function TBindingChecker.RequireClass(const AName, AWhere: string): TPasClass;
begin
  Result := Find(AName);
  if Result = nil then
    raise ECodeGenError.CreateFmt('%s: class %s is not declared in the .pas files of %s',
      [AWhere, AName, TPath.GetFileName(ExcludeTrailingPathDelimiter(TPath.GetFullPath(FFolder)))]);
end;

function TBindingChecker.PropertyOf(AClass: TPasClass; const AName: string; out AProp: TPasProperty): Boolean;
var
  Seen: TStringList;
begin
  Result := False;
  Seen := TStringList.Create;
  try
    while (AClass <> nil) and (Seen.IndexOf(AClass.Name.ToLower) < 0) do
    begin
      Seen.Add(AClass.Name.ToLower);
      if AClass.Properties.TryGetValue(AName.ToLower, AProp) then
        Exit(True);
      if AClass.Base <> '' then
        AClass := Find(AClass.Base)
      else
        AClass := nil;
    end;
  finally
    Seen.Free;
  end;
end;

function TBindingChecker.PublishedNames(AClass: TPasClass): string;
var
  Seen, Names: TStringList;
  Prop: TPasProperty;
  Sorted: TArray<string>;
  Item: string;
  I, J: Integer;
begin
  Seen := TStringList.Create;
  Names := TStringList.Create;
  try
    Names.CaseSensitive := True;
    while (AClass <> nil) and (Seen.IndexOf(AClass.Name.ToLower) < 0) do
    begin
      Seen.Add(AClass.Name.ToLower);
      for Prop in AClass.Properties.Values do
        if Prop.Published and (Names.IndexOf(Prop.Name) < 0) then
          Names.Add(Prop.Name);
      if AClass.Base <> '' then
        AClass := Find(AClass.Base)
      else
        AClass := nil;
    end;
    // a stable, case-insensitive sort
    Sorted := Names.ToStringArray;
    for I := 1 to High(Sorted) do
    begin
      Item := Sorted[I];
      J := I - 1;
      while (J >= 0) and (CompareStr(Sorted[J].ToLower, Item.ToLower) > 0) do
      begin
        Sorted[J + 1] := Sorted[J];
        Dec(J);
      end;
      Sorted[J + 1] := Item;
    end;
    Result := string.Join(', ', Sorted);
    if Result = '' then
      Result := 'none';
  finally
    Names.Free;
    Seen.Free;
  end;
end;

function FormatProblem(const AParameter: string): string;
var
  Specs: TList<TMatch>;
  M: TMatch;
begin
  Specs := TList<TMatch>.Create;
  try
    for M in TRegEx.Matches(AParameter, '%(%|(?:\d+:)?-?(?:\d+|\*)?(?:\.(?:\d+|\*))?([a-zA-Z]))') do
      if M.Groups[1].Value <> '%' then
        Specs.Add(M);
    if Specs.Count <> 1 then
      Exit(Format('needs exactly one format specifier such as %%s, found %d', [Specs.Count]));
    if Specs[0].Groups[2].Value.ToLower <> 's' then
      Exit('gets the value as a string, so use %s, not %' + Specs[0].Groups[2].Value);
    Result := '';
  finally
    Specs.Free;
  end;
end;

procedure TBindingChecker.CheckConverter(ABinding: TBinding; AResourceKeys: TStrings; const AWhere: string);
var
  Converter, Name, Parameter, Problem, Registered: string;
  M: TMatch;
  Known: Boolean;
  Sorted: TStringList;
begin
  if not ABinding.TryGetValue('Converter', Converter) then
    Exit;
  M := TRegEx.Match(PyStrip(Converter), '^\{\s*StaticResource\s+(?:ResourceKey\s*=\s*)?([\w.]+)\s*\}$');
  if not M.Success then
    Exit; // other markup (for example {x:Bind}) is not checked
  Name := M.Groups[1].Value;
  Known := (Name = BuiltInConverters[0]) or (Name = BuiltInConverters[1]) or (Name = BuiltInConverters[2]) or
    (FRegistered.IndexOf(Name) >= 0) or (AResourceKeys.IndexOf(Name) >= 0);
  if not Known then
  begin
    Sorted := TStringList.Create;
    try
      Sorted.CaseSensitive := True;
      Sorted.UseLocale := False;
      Sorted.Duplicates := dupIgnore;
      Sorted.Sorted := True;
      Sorted.AddStrings(FRegistered);
      Registered := string.Join(', ', Sorted.ToStringArray);
    finally
      Sorted.Free;
    end;
    if Registered = '' then
      Registered := 'none';
    raise ECodeGenError.CreateFmt('%s: Converter={StaticResource %s}: no converter %s (built in: %s; ' +
      'registered with TWinUIApp.RegisterConverter: %s)',
      [AWhere, Name, Name, string.Join(', ', BuiltInConverters), Registered]);
  end;
  if (Name = 'Format') and (FRegistered.IndexOf(Name) < 0) and (AResourceKeys.IndexOf(Name) < 0) and
    ABinding.TryGetValue('ConverterParameter', Parameter) then
  begin
    Parameter := PyStrip(Parameter);
    if (Length(Parameter) >= 2) and (Parameter[1] = Parameter[Length(Parameter)]) and
      CharInSet(Parameter[1], ['''', '"']) then
      Parameter := Copy(Parameter, 2, Length(Parameter) - 2);
    Problem := FormatProblem(Parameter);
    if Problem <> '' then
      raise ECodeGenError.CreateFmt('%s: ConverterParameter=''%s'' for Format %s', [AWhere, Parameter, Problem]);
  end;
end;

procedure TBindingChecker.Check(ABinding: TBinding; const AScope, AWhere: string);
var
  Path, Text, Segment, Hint, Mode: string;
  Cls: TPasClass;
  Prop: TPasProperty;
  HasProp, Found: Boolean;
begin
  if ABinding.ContainsKey('ElementName') or ABinding.ContainsKey('Source') or ABinding.ContainsKey('RelativeSource') then
    Exit; // the path is relative to another source
  if not ABinding.TryGetValue('Path', Path) then
    Path := '';
  Path := PyStrip(Path);
  while (Path <> '') and CharInSet(Path[1], ['''', '"']) do
    Delete(Path, 1, 1);
  while (Path <> '') and CharInSet(Path[Length(Path)], ['''', '"']) do
    Delete(Path, Length(Path), 1);
  if (Path = '') or (Path = '.') then
    Exit;
  Cls := RequireClass(AScope, AWhere);
  Text := '{Binding ' + Path + '}';
  HasProp := False;
  for Segment in Path.Split(['.']) do
  begin
    if not TRegEx.IsMatch(Segment, '^\w+$') then
      Exit; // indexers and attached properties are not checked
    if Cls = nil then
      Exit; // the previous property's type is not a class of this folder
    Found := PropertyOf(Cls, Segment, Prop);
    if not Found or not Prop.Published then
    begin
      Hint := '';
      if Found then
        Hint := '; ' + Prop.Name + ' is not published';
      raise ECodeGenError.CreateFmt('%s: %s: %s has no published property %s%s (published: %s)',
        [AWhere, Text, Cls.Name, Segment, Hint, PublishedNames(Cls)]);
    end;
    HasProp := True;
    Cls := Find(Prop.TypeName);
  end;
  if ABinding.TryGetValue('Mode', Mode) and (Mode.ToLower = 'twoway') and HasProp and not Prop.Writable then
    raise ECodeGenError.CreateFmt('%s: %s: Mode=TwoWay needs a setter, but %s is read-only', [AWhere, Text, Prop.Name]);
end;

end.
