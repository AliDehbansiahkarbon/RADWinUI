unit RADWinUI.Designer.ObjectInspector;

{ Native Object Inspector selection for XAML. Each published list is an immutable
  snapshot, retained property editors become read-only when its generation ends.
  Native callbacks queue changes for the designer timer, never navigate or replace
  a selection while the Object Inspector is still enumerating it. }

interface

uses
  System.SysUtils, System.Classes, System.TypInfo,
  ToolsAPI, DesignIntf, PropInspAPI,
  RADWinUI.Designer.Model, RADWinUI.Designer.XamlEdit;

type
  TInspectorEditKind = (ieProperty, ieEvent, ieClearEvent, ieSelect);
  TInspectorEdit = record
    Kind: TInspectorEditKind;
    Name, Value: string;
    Element: TXamlElement;
    Generation: Integer;
  end;

  TInspectorContext = class(TInterfacedObject)
  public
    Generation, Page: Integer;
    ActiveItems: array[0..1] of string;
    ExpandedItems: string;
    ArrangeMode: TInspArrangeMode;
    Refresh: Boolean;
    Pending: TArray<TInspectorEdit>;
    OnProperty, OnEvent: TProc<string, string>;
    OnClearEvent: TProc<string>;
    OnSelect: TProc<TXamlElement, Boolean>;
    procedure Queue(AKind: TInspectorEditKind; const AName, AValue: string);
  end;

  TNativeObjectInspector = class
  private
    FContext: TInspectorContext;
    FKeepContext: IInterface;
    FSelection: IOTAPropInspSelection;
    FServices: IOTAPropInspServices;
    FApplying: Boolean;
    FOnError: TProc<string>;
    procedure ReportError(const AOperation: string; AError: Exception);
  public
    constructor Create(const AProperty, AEvent: TProc<string, string>;
      const AClear: TProc<string>; const ASelect: TProc<TXamlElement, Boolean>;
      const AError: TProc<string>);
    destructor Destroy; override;
    procedure ShowElement(const ATitle: string; const AProps: TArray<TDesignerProperty>;
      const AValue: TFunc<string, string>; const AEvents: TArray<TDesignerEvent>;
      const AHandler: TFunc<string, string>; const AElements: TArray<TXamlElement>;
      ALine, AColumn: Integer);
    procedure ApplyPending;
    procedure Commit;
    procedure Clear;
  end;

implementation

type
  TXamlProperty = class(TInterfacedObject, IProperty, IProperty70, IProperty80,
    IPropertyKind, IPropertyDescription)
  private
    FContext: TInspectorContext;
    FKeepContext: IInterface;
    FGeneration: Integer;
    FName, FValue, FDescription: string;
    FValues: TArray<string>;
    FEvent: Boolean;
  public
    constructor Create(AContext: TInspectorContext; const AName, AValue, ADescription: string;
      const AValues: TArray<string>; AEvent: Boolean);
    procedure Activate;
    function AllEqual: Boolean;
    function AutoFill: Boolean;
    procedure Edit; overload;
    procedure Edit(const Host: IPropertyHost; DblClick: Boolean); overload;
    function HasInstance(Instance: TPersistent): Boolean;
    function GetAttributes: TPropertyAttributes;
    function GetEditLimit: Integer;
    function GetEditValue(out Value: string): Boolean;
    function GetName: string;
    procedure GetProperties(Proc: TGetPropProc);
    function GetPropInfo: PPropInfo;
    function GetPropType: PTypeInfo;
    function GetValue: string;
    procedure GetValues(Proc: TGetStrProc);
    procedure Revert;
    procedure SetValue(const Value: string);
    function ValueAvailable: Boolean;
    function GetIsDefault: Boolean;
    function GetKind: TTypeKind;
    function GetDescription: string;
  end;

  TInspectorPages = class(TOTAStringsAdapter, IOTAPropInspPages)
  private
    FContext: TInspectorContext;
    FKeepContext: IInterface;
    FGeneration: Integer;
  public
    constructor Create(AContext: TInspectorContext);
    function GetPageIndex: Integer;
    procedure SetPageIndex(const Value: Integer);
  end;

  TInspectorInstances = class(TOTAStringsAdapter, IOTAPropInspInstanceList)
  private
    FContext: TInspectorContext;
    FKeepContext: IInterface;
    FGeneration, FIndex: Integer;
    FElements: TArray<TXamlElement>;
  public
    constructor Create(AContext: TInspectorContext; const AElements: TArray<TXamlElement>;
      ALine, AColumn: Integer);
    function GetActiveName: string;
    function GetActiveValue: string;
    function GetHint: string;
    function GetItemIndex: Integer;
    procedure SetItemIndex(const Value: Integer);
  end;

  TXamlInspectorSelection = class(TInterfacedObject, IOTAPropInspSelection,
    IPropListBoxSelection, IOTAPropInspPages, IOTAPropInspInstanceList)
  private
    FContext: TInspectorContext;
    FKeepContext: IInterface;
    FGeneration: Integer;
    FTitle: string;
    FProperties, FEvents: TArray<IProperty>;
    FPages: IOTAPropInspPages;
    FInstances: IOTAPropInspInstanceList;
    FSubItem: IProperty;
  public
    constructor Create(AContext: TInspectorContext; const ATitle: string;
      const AProps: TArray<TDesignerProperty>; const AValue: TFunc<string, string>;
      const AEvents: TArray<TDesignerEvent>; const AHandler: TFunc<string, string>;
      const AElements: TArray<TXamlElement>; ALine, AColumn: Integer);
    function GetCount: Integer;
    function GetCurrentSubItem: IProperty;
    function GetSubItem(const Index: Integer): IProperty;
    function GetSubItemCount: Integer;
    function GetItem(const Index: Integer): IProperty;
    procedure SetCurrentSubItem(const Value: IProperty);
    function GetActiveItem: string;
    function GetExpandAll: Boolean;
    function GetExpandedItems: string;
    function GetArrangeMode: TInspArrangeMode;
    function GetShowDescriptionPane: Boolean;
    function GetShowHotCommands: Boolean;
    function GetStatusText: string;
    function GetCategories: IOTAPropInspCategories;
    procedure SetActiveItem(const Value: string);
    procedure SetArrangeMode(const Value: TInspArrangeMode);
    procedure SetExpandedItems(const Value: string);
    procedure InvokeHelp(const Item: IProperty);
    function IsExpandable(const Item: IProperty): Boolean;
    procedure HandleActivation(Activating: Boolean);
    property Pages: IOTAPropInspPages read FPages implements IOTAPropInspPages;
    property Instances: IOTAPropInspInstanceList read FInstances implements IOTAPropInspInstanceList;
  end;

procedure TInspectorContext.Queue(AKind: TInspectorEditKind; const AName, AValue: string);
var
  Edit: TInspectorEdit;
begin
  Edit.Kind := AKind;
  Edit.Name := AName;
  Edit.Value := AValue;
  Edit.Generation := Generation;
  Pending := Pending + [Edit];
end;

constructor TXamlProperty.Create(AContext: TInspectorContext;
  const AName, AValue, ADescription: string; const AValues: TArray<string>; AEvent: Boolean);
begin
  inherited Create;
  FContext := AContext;
  FKeepContext := AContext;
  FGeneration := AContext.Generation;
  FName := AName;
  FValue := AValue;
  FDescription := ADescription;
  FValues := AValues;
  FEvent := AEvent;
end;

procedure TXamlProperty.Activate;
begin
end;

function TXamlProperty.AllEqual: Boolean;
begin
  Result := True;
end;

function TXamlProperty.AutoFill: Boolean;
begin
  Result := Length(FValues) > 0;
end;

procedure TXamlProperty.Edit;
var
  I: Integer;
begin
  if not ValueAvailable then Exit;
  if FEvent then
    FContext.Queue(ieEvent, FName, FValue)
  else if Length(FValues) > 0 then
  begin
    for I := 0 to High(FValues) do
      if SameText(FValue, FValues[I]) then
      begin
        SetValue(FValues[(I + 1) mod Length(FValues)]);
        Exit;
      end;
    SetValue(FValues[0]);
  end;
end;

procedure TXamlProperty.Edit(const Host: IPropertyHost; DblClick: Boolean);
begin
  Edit;
end;

function TXamlProperty.HasInstance(Instance: TPersistent): Boolean;
begin
  Result := False;
end;

function TXamlProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueEditable];
  if FEvent then Include(Result, paDialog);
  if Length(FValues) > 0 then Include(Result, paValueList);
  if not ValueAvailable then Include(Result, paReadOnly);
end;

function TXamlProperty.GetEditLimit: Integer;
begin
  Result := 32767;
end;

function TXamlProperty.GetEditValue(out Value: string): Boolean;
begin
  Value := FValue;
  Result := ValueAvailable;
end;

function TXamlProperty.GetName: string;
begin
  Result := FName;
end;

procedure TXamlProperty.GetProperties(Proc: TGetPropProc);
begin
end;

function TXamlProperty.GetPropInfo: PPropInfo;
begin
  Result := nil; // properties describe XAML attributes, not RTTI on an IDE object
end;

function TXamlProperty.GetPropType: PTypeInfo;
begin
  if FEvent then Result := TypeInfo(TNotifyEvent) else Result := TypeInfo(string);
end;

function TXamlProperty.GetValue: string;
begin
  Result := FValue;
end;

procedure TXamlProperty.GetValues(Proc: TGetStrProc);
var
  Value: string;
begin
  for Value in FValues do Proc(Value);
end;

procedure TXamlProperty.Revert;
begin
  SetValue('');
end;

procedure TXamlProperty.SetValue(const Value: string);
var
  Text: string;
begin
  if not ValueAvailable or (Value = FValue) then Exit;
  Text := Value;
  if FEvent then
  begin
    Text := Trim(Text);
    if (Text <> '') and not IsValidIdent(Text) then
      raise EConvertError.CreateFmt('"%s" is not a method name', [Text]);
    if Text = '' then FContext.Queue(ieClearEvent, FName, '')
    else FContext.Queue(ieEvent, FName, Text);
  end
  else
    FContext.Queue(ieProperty, FName, Text);
  FValue := Text;
end;

function TXamlProperty.ValueAvailable: Boolean;
begin
  Result := FGeneration = FContext.Generation;
end;

function TXamlProperty.GetIsDefault: Boolean;
begin
  Result := FValue = '';
end;

function TXamlProperty.GetKind: TTypeKind;
begin
  Result := GetPropType.Kind;
end;

function TXamlProperty.GetDescription: string;
begin
  Result := FDescription;
end;

constructor TInspectorPages.Create(AContext: TInspectorContext);
var
  Pages: TStringList;
begin
  Pages := TStringList.Create;
  Pages.Add('Properties');
  Pages.Add('Events');
  inherited Create(Pages, True);
  FContext := AContext;
  FKeepContext := AContext;
  FGeneration := AContext.Generation;
end;

function TInspectorPages.GetPageIndex: Integer;
begin
  Result := FContext.Page;
end;

procedure TInspectorPages.SetPageIndex(const Value: Integer);
begin
  if (FGeneration <> FContext.Generation) or (Value < 0) or (Value > 1) or (Value = FContext.Page) then Exit;
  FContext.Page := Value;
  FContext.Refresh := True;
end;

constructor TInspectorInstances.Create(AContext: TInspectorContext;
  const AElements: TArray<TXamlElement>; ALine, AColumn: Integer);
var
  Strings: TStringList;
  I: Integer;
  Name: string;
begin
  Strings := TStringList.Create;
  inherited Create(Strings, True);
  FContext := AContext;
  FKeepContext := AContext;
  FGeneration := AContext.Generation;
  FElements := AElements;
  FIndex := -1;
  for I := 0 to High(FElements) do
  begin
    Name := FElements[I].Name;
    if Name = '' then Name := Format('(%s at %d:%d)', [FElements[I].Tag, FElements[I].Line, FElements[I].Column]);
    Strings.Add(Name + '=' + FElements[I].Tag);
    if (FElements[I].Line = ALine) and (FElements[I].Column = AColumn) then FIndex := I;
  end;
end;

function TInspectorInstances.GetActiveName: string;
begin
  Result := '';
  if FIndex >= 0 then Result := GetName(FIndex);
end;

function TInspectorInstances.GetActiveValue: string;
begin
  Result := '';
  if FIndex >= 0 then Result := GetValueFromIndex(FIndex);
end;

function TInspectorInstances.GetHint: string;
begin
  Result := Trim(GetActiveName + ': ' + GetActiveValue);
end;

function TInspectorInstances.GetItemIndex: Integer;
begin
  Result := FIndex;
end;

procedure TInspectorInstances.SetItemIndex(const Value: Integer);
var
  Edit: TInspectorEdit;
begin
  if (FGeneration <> FContext.Generation) or (Value < 0) or (Value > High(FElements)) or (Value = FIndex) then Exit;
  FIndex := Value;
  Edit.Kind := ieSelect;
  Edit.Element := FElements[Value];
  Edit.Generation := FGeneration;
  FContext.Pending := FContext.Pending + [Edit];
end;

constructor TXamlInspectorSelection.Create(AContext: TInspectorContext; const ATitle: string;
  const AProps: TArray<TDesignerProperty>; const AValue: TFunc<string, string>;
  const AEvents: TArray<TDesignerEvent>; const AHandler: TFunc<string, string>;
  const AElements: TArray<TXamlElement>; ALine, AColumn: Integer);
var
  Prop: TDesignerProperty;
  Event: TDesignerEvent;
  I: Integer;
  Values: TArray<string>;
begin
  inherited Create;
  FContext := AContext;
  FKeepContext := AContext;
  FGeneration := AContext.Generation;
  FTitle := ATitle;
  FPages := TInspectorPages.Create(AContext);
  FInstances := TInspectorInstances.Create(AContext, AElements, ALine, AColumn);
  SetLength(FProperties, Length(AProps));
  for I := 0 to High(AProps) do
  begin
    Prop := AProps[I];
    Values := Prop.EnumValues;
    if Prop.Kind = 'bool' then Values := ['True', 'False'];
    FProperties[I] := TXamlProperty.Create(AContext, Prop.Name, AValue(Prop.Name),
      Prop.Kind + ' XAML attribute. Clear the value to use its default.', Values, False);
  end;
  SetLength(FEvents, Length(AEvents));
  for I := 0 to High(AEvents) do
  begin
    Event := AEvents[I];
    FEvents[I] := TXamlProperty.Create(AContext, Event.Name, AHandler(Event.Name),
      '(Sender: TObject; E: ' + Event.ArgsType + '). Double-click to create or open the handler.', nil, True);
  end;
end;

function TXamlInspectorSelection.GetCount: Integer;
begin
  if FContext.Page = 1 then Result := Length(FEvents) else Result := Length(FProperties);
end;

function TXamlInspectorSelection.GetCurrentSubItem: IProperty;
begin
  Result := FSubItem;
end;

function TXamlInspectorSelection.GetSubItem(const Index: Integer): IProperty;
begin
  Result := nil;
end;

function TXamlInspectorSelection.GetSubItemCount: Integer;
begin
  Result := 0;
end;

function TXamlInspectorSelection.GetItem(const Index: Integer): IProperty;
begin
  Result := nil;
  if (Index < 0) or (Index >= GetCount) then Exit;
  if FContext.Page = 1 then Result := FEvents[Index] else Result := FProperties[Index];
end;

procedure TXamlInspectorSelection.SetCurrentSubItem(const Value: IProperty);
begin
  FSubItem := Value;
end;

function TXamlInspectorSelection.GetActiveItem: string;
begin
  Result := FContext.ActiveItems[FContext.Page];
end;

function TXamlInspectorSelection.GetExpandAll: Boolean;
begin
  Result := False;
end;

function TXamlInspectorSelection.GetExpandedItems: string;
begin
  Result := FContext.ExpandedItems;
end;

function TXamlInspectorSelection.GetArrangeMode: TInspArrangeMode;
begin
  Result := FContext.ArrangeMode;
end;

function TXamlInspectorSelection.GetShowDescriptionPane: Boolean;
begin
  Result := True;
end;

function TXamlInspectorSelection.GetShowHotCommands: Boolean;
begin
  Result := False;
end;

function TXamlInspectorSelection.GetStatusText: string;
begin
  Result := FTitle;
end;

function TXamlInspectorSelection.GetCategories: IOTAPropInspCategories;
begin
  Result := nil;
end;

procedure TXamlInspectorSelection.SetActiveItem(const Value: string);
begin
  if FGeneration = FContext.Generation then FContext.ActiveItems[FContext.Page] := Value;
end;

procedure TXamlInspectorSelection.SetArrangeMode(const Value: TInspArrangeMode);
begin
  if FGeneration = FContext.Generation then FContext.ArrangeMode := Value;
end;

procedure TXamlInspectorSelection.SetExpandedItems(const Value: string);
begin
  if FGeneration = FContext.Generation then FContext.ExpandedItems := Value;
end;

procedure TXamlInspectorSelection.InvokeHelp(const Item: IProperty);
begin
end;

function TXamlInspectorSelection.IsExpandable(const Item: IProperty): Boolean;
begin
  Result := False;
end;

procedure TXamlInspectorSelection.HandleActivation(Activating: Boolean);
begin
end;

constructor TNativeObjectInspector.Create(const AProperty, AEvent: TProc<string, string>;
  const AClear: TProc<string>; const ASelect: TProc<TXamlElement, Boolean>;
  const AError: TProc<string>);
begin
  inherited Create;
  FOnError := AError;
  FContext := TInspectorContext.Create;
  FKeepContext := FContext;
  FContext.ArrangeMode := iamByName;
  FContext.OnProperty := AProperty;
  FContext.OnEvent := AEvent;
  FContext.OnClearEvent := AClear;
  FContext.OnSelect := ASelect;
  if not Supports(BorlandIDEServices, IOTAPropInspServices, FServices) then
    raise Exception.Create('The IDE does not provide Object Inspector services');
end;

destructor TNativeObjectInspector.Destroy;
begin
  // Sever callbacks first: the IDE can retain selection/property interfaces.
  FContext.OnProperty := nil;
  FContext.OnEvent := nil;
  FContext.OnClearEvent := nil;
  FContext.OnSelect := nil;
  FContext.Pending := nil;
  Clear;
  FOnError := nil;
  inherited;
end;

procedure TNativeObjectInspector.ReportError(const AOperation: string; AError: Exception);
begin
  if Assigned(FOnError) then FOnError(AOperation + ': ' + AError.ClassName + ': ' + AError.Message);
end;

procedure TNativeObjectInspector.ShowElement(const ATitle: string;
  const AProps: TArray<TDesignerProperty>; const AValue: TFunc<string, string>;
  const AEvents: TArray<TDesignerEvent>; const AHandler: TFunc<string, string>;
  const AElements: TArray<TXamlElement>; ALine, AColumn: Integer);
begin
  try
    Inc(FContext.Generation);
    FSelection := TXamlInspectorSelection.Create(FContext, ATitle, AProps, AValue,
      AEvents, AHandler, AElements, ALine, AColumn);
    FServices.Selection := FSelection;
    FContext.Refresh := False;
  except
    on E: Exception do ReportError('publish selection', E);
  end;
end;

procedure TNativeObjectInspector.ApplyPending;
var
  Pending: TArray<TInspectorEdit>;
  Edit: TInspectorEdit;
begin
  if FApplying then Exit;
  FApplying := True;
  try
    Pending := FContext.Pending;
    FContext.Pending := nil;
    for Edit in Pending do
    begin
      if Edit.Generation <> FContext.Generation then Continue;
      case Edit.Kind of
        ieProperty: if Assigned(FContext.OnProperty) then FContext.OnProperty(Edit.Name, Edit.Value);
        ieEvent: if Assigned(FContext.OnEvent) then FContext.OnEvent(Edit.Name, Edit.Value);
        ieClearEvent: if Assigned(FContext.OnClearEvent) then FContext.OnClearEvent(Edit.Name);
        ieSelect: if Assigned(FContext.OnSelect) then FContext.OnSelect(Edit.Element, False);
      end;
    end;
    try
      if FContext.Refresh and (FSelection <> nil) and (FServices.Selection = FSelection) then
      begin
        FServices.Modified;
        FContext.Refresh := False;
      end;
    except
      on E: Exception do ReportError('refresh', E);
    end;
  finally
    FApplying := False;
  end;
end;

procedure TNativeObjectInspector.Commit;
begin
  if FApplying then Exit;
  try
    if (FSelection <> nil) and (FServices.Selection = FSelection) then FServices.UpdateState;
  except
    on E: Exception do ReportError('save state', E);
  end;
  ApplyPending;
end;

procedure TNativeObjectInspector.Clear;
begin
  Inc(FContext.Generation);
  FContext.Pending := nil;
  try
    if (FSelection <> nil) and (FServices.Selection = FSelection) then
      FServices.Selection := nil;
  except
    on E: Exception do ReportError('clear selection', E);
  end;
  FSelection := nil;
end;

end.
