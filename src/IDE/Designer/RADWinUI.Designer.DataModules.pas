unit RADWinUI.Designer.DataModules;

{
  What the Object Inspector offers for the data controls' DataSource and
  DataField: the TDataSource components and the fields of their datasets,
  read from the text .dfm files of data modules (and forms). Persistent
  fields and FieldDefs count, fields a query only makes when it opens do
  not. No ToolsAPI or VCL here.
}

interface

/// <summary>The names of the TDataSource components in the .dfm files of AFolders, sorted.</summary>
function DataSourceNames(const AFolders: TArray<string>): TArray<string>;
/// <summary>
///   The field names of the dataset of the data source ASource ("Source" or
///   "Module.Source") in the .dfm files of AFolders, in their order.
/// </summary>
function DataFieldNames(const AFolders: TArray<string>; const ASource: string): TArray<string>;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections;

type
  TDfmObject = record
    Module, Name, ClassName, DataSet: string;
    Fields: TArray<string>;
  end;

function Unquote(const AText: string): string;
begin
  Result := Trim(AText);
  if (Length(Result) >= 2) and (Result[1] = '''') and (Result[Length(Result)] = '''') then
    Result := Copy(Result, 2, Length(Result) - 2).Replace('''''', '''');
end;

/// Every object of every .dfm in AFolders, with the properties the data controls need
function ReadObjects(const AFolders: TArray<string>): TArray<TDfmObject>;
var
  Folder, FileName, Line, Text, Module: string;
  Lines: TStringList;
  Stack: TStack<Integer>;
  Item: TDfmObject;
  Colon, Current, I, Collections: Integer;
  InFieldDefs: Boolean;
  Seen: TArray<string>;
begin
  Result := nil;
  Seen := nil;
  Lines := TStringList.Create;
  Stack := TStack<Integer>.Create;
  try
    for Folder in AFolders do
    begin
      if (Folder = '') or not TDirectory.Exists(Folder) then
        Continue;
      for FileName in TDirectory.GetFiles(Folder, '*.dfm') do
      begin
        if TArray.IndexOf<string>(Seen, LowerCase(FileName)) >= 0 then
          Continue;
        Seen := Seen + [LowerCase(FileName)];
        try
          Lines.LoadFromFile(FileName);
        except
          Continue; // a binary .dfm, or one that is open elsewhere
        end;
        Stack.Clear;
        Module := '';
        InFieldDefs := False;
        Collections := 0;
        for I := 0 to Lines.Count - 1 do
        begin
          Line := Trim(Lines[I]);
          if Collections > 0 then
          begin
            // Inside a collection (FieldDefs, IndexDefs, Columns, ...): its
            // items end with "end" too, so they are not objects
            if Line.EndsWith('= <') then
              Inc(Collections)
            else if Line.EndsWith('>') then
            begin
              Dec(Collections);
              if Collections = 0 then
                InFieldDefs := False;
            end;
            if InFieldDefs and (Collections = 1) and Line.StartsWith('Name = ') and (Stack.Count > 0) then
              Result[Stack.Peek].Fields := Result[Stack.Peek].Fields + [Unquote(Copy(Line, 8, MaxInt).TrimRight(['>']))];
          end
          else if Line.StartsWith('object ') or Line.StartsWith('inherited ') or Line.StartsWith('inline ') then
          begin
            Text := Copy(Line, Pos(' ', Line) + 1, MaxInt);
            Colon := Pos(':', Text);
            Item := Default(TDfmObject);
            if Colon > 0 then
            begin
              Item.Name := Trim(Copy(Text, 1, Colon - 1));
              Item.ClassName := Trim(Copy(Text, Colon + 1, MaxInt));
            end
            else
              Item.ClassName := Text;
            if Stack.Count = 0 then
              Module := Item.Name;
            Item.Module := Module;
            Result := Result + [Item];
            Stack.Push(High(Result));
          end
          else if Line = 'end' then
          begin
            if Stack.Count > 0 then
              Stack.Pop;
          end
          else if Stack.Count > 0 then
          begin
            Current := Stack.Peek;
            if Line.EndsWith('= <') then
            begin
              Collections := 1;
              InFieldDefs := Line.StartsWith('FieldDefs ');
            end
            else if Line.StartsWith('DataSet = ') then
              Result[Current].DataSet := Trim(Copy(Line, 11, MaxInt))
            else if Line.StartsWith('FieldName = ') and (Stack.Count >= 2) and
              Result[Current].ClassName.EndsWith('Field') then
            begin
              // A persistent field: a child object of its dataset
              Stack.Pop;
              Result[Stack.Peek].Fields := Result[Stack.Peek].Fields + [Unquote(Copy(Line, 13, MaxInt))];
              Stack.Push(Current);
            end;
          end;
        end;
      end;
    end;
  finally
    Stack.Free;
    Lines.Free;
  end;
end;

function IsDataSource(const AItem: TDfmObject): Boolean;
begin
  Result := SameText(AItem.ClassName, 'TDataSource');
end;

function DataSourceNames(const AFolders: TArray<string>): TArray<string>;
var
  Item: TDfmObject;
  List: TStringList;
begin
  List := TStringList.Create;
  try
    List.Sorted := True;
    List.Duplicates := dupIgnore;
    List.CaseSensitive := False;
    for Item in ReadObjects(AFolders) do
      if IsDataSource(Item) and (Item.Name <> '') then
        List.Add(Item.Name);
    Result := List.ToStringArray;
  finally
    List.Free;
  end;
end;

function DataFieldNames(const AFolders: TArray<string>; const ASource: string): TArray<string>;
var
  Items: TArray<TDfmObject>;
  Item, Source: TDfmObject;
  ModuleName, SourceName, DataSetName, DataSetModule: string;
  Dot: Integer;
  Found: Boolean;
begin
  Result := nil;
  SourceName := Trim(ASource);
  ModuleName := '';
  Dot := Pos('.', SourceName);
  if Dot > 0 then
  begin
    ModuleName := Copy(SourceName, 1, Dot - 1);
    SourceName := Copy(SourceName, Dot + 1, MaxInt);
  end;
  if SourceName = '' then
    Exit;
  Items := ReadObjects(AFolders);
  Found := False;
  for Item in Items do
    if IsDataSource(Item) and SameText(Item.Name, SourceName) and
      ((ModuleName = '') or SameText(Item.Module, ModuleName)) then
    begin
      Source := Item;
      Found := True;
      Break;
    end;
  if not Found or (Source.DataSet = '') then
    Exit;
  // DataSet = Customers, or Module.Customers for a dataset of another module
  DataSetName := Source.DataSet;
  DataSetModule := Source.Module;
  Dot := Pos('.', DataSetName);
  if Dot > 0 then
  begin
    DataSetModule := Copy(DataSetName, 1, Dot - 1);
    DataSetName := Copy(DataSetName, Dot + 1, MaxInt);
  end;
  for Item in Items do
    if SameText(Item.Name, DataSetName) and SameText(Item.Module, DataSetModule) then
      Exit(Item.Fields);
end;

end.
