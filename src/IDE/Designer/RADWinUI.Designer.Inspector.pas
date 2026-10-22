unit RADWinUI.Designer.Inspector;

{
  An IDE-free property grid: a VCL panel with the
  selected element's properties and events, like the Object Inspector. The
  IDE packages use the native Object Inspector instead, this panel stays for
  its tests. It knows nothing about the IDE: the owner fills it (ShowElement) and applies what the
  user changes (OnPropertyChange, OnEventHandler), so
  tests\Designer\DesignerModelTest drives it outside the IDE. No WinUI here.

  Properties: Enter applies the typed value and stays on the field, Escape
  puts the applied value back, leaving the grid applies it, and a drop-down
  value (enums, True/False) applies when picked. An empty value removes the
  attribute. Events work like the Object Inspector: the ... button,
  a double click, or a name typed and Enter create the handler or jump to it,
  Enter on an emptied field takes the event off (the attribute only, the
  method stays).
}

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.ComCtrls,
  Vcl.Grids,
  Vcl.ValEdit,
  RADWinUI.Designer.Model;

type
  TDesignerInspector = class(TPanel)
  strict private
    FCaption: TLabel;
    FPages: TPageControl;
    FProps: TValueListEditor;
    FEvents: TValueListEditor;
    FFilling: Boolean;
    FApplied: TStringList; // the value of each property as last applied (or shown)
    FOnPropertyChange: TProc<string, string>;
    FOnEventHandler: TProc<string, string>;
    FOnEventCleared: TProc<string>;
    FEventsShown: TStringList; // each event's handler as shown
    procedure EventsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PropsValidate(Sender: TObject; ACol, ARow: Integer; const AKeyName, AKeyValue: string);
    procedure PropsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PropsSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
    procedure PropsExit(Sender: TObject);
    procedure EventsEditButton(Sender: TObject);
    function NewGrid(ATab: TTabSheet): TValueListEditor;
    function RowName(ARow: Integer): string;
  public
    /// <summary>Creates the panel filling AParent (a frame of the IDE's dockable form, or any window).</summary>
    constructor CreateIn(AParent: TWinControl);
    destructor Destroy; override;
    /// <summary>
    ///   Shows one element: AValue and AHandler return the current text of a
    ///   property or event. Call ApplyPending first while the previous element
    ///   is still the owner's selection.
    /// </summary>
    procedure ShowElement(const ATitle: string; const AProps: TArray<TDesignerProperty>;
      const AValue: TFunc<string, string>; const AEvents: TArray<TDesignerEvent>;
      const AHandler: TFunc<string, string>);
    /// <summary>Applies a value still being typed (before the selection changes or the preview closes).</summary>
    procedure ApplyPending;
    /// <summary>Applies AValue to property AName when it differs from the applied one.</summary>
    procedure CommitProperty(const AName, AValue: string);
    /// <summary>What the ... button of event AName does (tests call it directly).</summary>
    procedure CommitEvent(const AName: string);
    /// <summary>Puts text into the property AName's field as typing does, without applying it (tests).</summary>
    procedure TypeValue(const AName, AValue: string);
    /// <summary>What Enter (VK_RETURN) or Escape (VK_ESCAPE) does in the property grid (tests).</summary>
    procedure PressKey(AKey: Word);
    /// <summary>The value shown for property AName (tests).</summary>
    function PropertyText(const AName: string): string;
    /// <summary>The drop-down values of property AName (tests).</summary>
    function PickList(const AName: string): TArray<string>;
    property OnPropertyChange: TProc<string, string> read FOnPropertyChange write FOnPropertyChange;
    /// <summary>Puts text into event AName's field and presses Enter there (tests).</summary>
    procedure TypeEvent(const AName, AHandler: string);
    /// <summary>(event name, handler name typed or shown, '' for a new one): create it or jump to it.</summary>
    property OnEventHandler: TProc<string, string> read FOnEventHandler write FOnEventHandler;
    /// <summary>The event's field was emptied and Enter pressed: take the event off the element.</summary>
    property OnEventCleared: TProc<string> read FOnEventCleared write FOnEventCleared;
  end;

implementation

uses
  Winapi.Windows;

constructor TDesignerInspector.CreateIn(AParent: TWinControl);
begin
  inherited Create(AParent);
  Parent := AParent; // the tabs need a window handle while they are built
  Align := alClient;
  BevelOuter := bvNone;
  Caption := '';
  FApplied := TStringList.Create;
  FCaption := TLabel.Create(Self);
  FCaption.Parent := Self;
  FCaption.Align := alTop;
  FCaption.Caption := 'Click an element in the RADWinUI Preview';
  FCaption.Margins.SetBounds(6, 6, 6, 6);
  FCaption.AlignWithMargins := True;
  FPages := TPageControl.Create(Self);
  FPages.Parent := Self;
  FPages.Align := alClient;
  FProps := NewGrid(TTabSheet.Create(Self));
  FProps.OnValidate := PropsValidate;
  FProps.OnKeyDown := PropsKeyDown;
  FProps.OnSetEditText := PropsSetEditText;
  FProps.OnExit := PropsExit;
  FEvents := NewGrid(TTabSheet.Create(Self));
  FEvents.OnEditButtonClick := EventsEditButton;
  FEvents.OnDblClick := EventsEditButton;
  FEvents.OnKeyDown := EventsKeyDown;
  FEventsShown := TStringList.Create;
  (FProps.Parent as TTabSheet).Caption := 'Properties';
  (FEvents.Parent as TTabSheet).Caption := 'Events';
end;

destructor TDesignerInspector.Destroy;
begin
  FApplied.Free;
  FEventsShown.Free;
  inherited;
end;

function TDesignerInspector.NewGrid(ATab: TTabSheet): TValueListEditor;
begin
  ATab.PageControl := FPages;
  Result := TValueListEditor.Create(Self);
  Result.Parent := ATab;
  Result.Align := alClient;
  Result.DisplayOptions := [doColumnTitles, doAutoColResize];
  Result.TitleCaptions[0] := 'Name';
  Result.TitleCaptions[1] := 'Value';
  Result.KeyOptions := [];
end;

function TDesignerInspector.RowName(ARow: Integer): string;
begin
  if (ARow >= 1) and (ARow < FProps.RowCount) then
    Result := FProps.Keys[ARow]
  else
    Result := '';
end;

procedure TDesignerInspector.ShowElement(const ATitle: string; const AProps: TArray<TDesignerProperty>;
  const AValue: TFunc<string, string>; const AEvents: TArray<TDesignerEvent>; const AHandler: TFunc<string, string>);
var
  Prop: TDesignerProperty;
  Event: TDesignerEvent;
  Row: Integer;
  Value: string;
begin
  FFilling := True;
  try
    FProps.EditorMode := False;
    FCaption.Caption := ATitle;
    FProps.Strings.Clear;
    FApplied.Clear;
    for Prop in AProps do
    begin
      Value := AValue(Prop.Name);
      FApplied.AddPair(Prop.Name, Value);
      Row := FProps.InsertRow(Prop.Name, Value, True);
      if Prop.Kind = 'bool' then
      begin
        FProps.ItemProps[Row - 1].EditStyle := esPickList;
        FProps.ItemProps[Row - 1].PickList.CommaText := 'True,False';
      end
      else if Prop.Kind.StartsWith('enum:') then
      begin
        FProps.ItemProps[Row - 1].EditStyle := esPickList;
        for Value in Prop.EnumValues do
          FProps.ItemProps[Row - 1].PickList.Add(Value);
      end;
    end;
    FEvents.Strings.Clear;
    FEventsShown.Clear;
    for Event in AEvents do
    begin
      Value := AHandler(Event.Name);
      FEventsShown.AddPair(Event.Name, Value);
      Row := FEvents.InsertRow(Event.Name, Value, True);
      FEvents.ItemProps[Row - 1].EditStyle := esEllipsis;
    end;
  finally
    FFilling := False;
  end;
end;

procedure TDesignerInspector.CommitProperty(const AName, AValue: string);
var
  I: Integer;
begin
  if (AName = '') or FFilling then
    Exit;
  I := FApplied.IndexOfName(AName);
  if (I >= 0) and (FApplied.ValueFromIndex[I] = AValue) then
    Exit;
  if I >= 0 then
    FApplied.ValueFromIndex[I] := AValue
  else
    FApplied.AddPair(AName, AValue);
  if Assigned(FOnPropertyChange) then
    FOnPropertyChange(AName, AValue);
end;

procedure TDesignerInspector.ApplyPending;
begin
  // The grid stores typed text in its cells as it is typed, applying is reading it
  if FProps.Row >= 1 then
    CommitProperty(RowName(FProps.Row), FProps.Cells[1, FProps.Row]);
end;

procedure TDesignerInspector.PropsValidate(Sender: TObject; ACol, ARow: Integer; const AKeyName, AKeyValue: string);
begin
  CommitProperty(AKeyName, AKeyValue); // Tab or a click on another field
end;

procedure TDesignerInspector.PropsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  PressKey(Key);
  if (Key = VK_RETURN) or (Key = VK_ESCAPE) then
    Key := 0;
end;

procedure TDesignerInspector.PressKey(AKey: Word);
var
  Name: string;
begin
  Name := RowName(FProps.Row);
  if Name = '' then
    Exit;
  if AKey = VK_RETURN then
  begin
    ApplyPending; // and stay on the field
    FProps.EditorMode := False;
  end
  else if AKey = VK_ESCAPE then
  begin
    FFilling := True;
    try
      FProps.Cells[1, FProps.Row] := FApplied.Values[Name];
      FProps.EditorMode := False;
    finally
      FFilling := False;
    end;
  end;
end;

procedure TDesignerInspector.PropsSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
var
  Name: string;
begin
  // A drop-down value applies as soon as it is picked, typed text waits for Enter
  Name := RowName(ARow);
  if (Name <> '') and (FProps.ItemProps[ARow - 1].EditStyle = esPickList) and
    (FProps.ItemProps[ARow - 1].PickList.IndexOf(Value) >= 0) then
    CommitProperty(Name, Value);
end;

procedure TDesignerInspector.PropsExit(Sender: TObject);
begin
  ApplyPending; // closing the panel or clicking elsewhere applies what was typed
end;

procedure TDesignerInspector.TypeValue(const AName, AValue: string);
var
  Row: Integer;
begin
  if FProps.FindRow(AName, Row) then
  begin
    FProps.Row := Row;
    FProps.Cells[1, Row] := AValue;
  end;
end;

procedure TDesignerInspector.EventsEditButton(Sender: TObject);
begin
  if FEvents.Row >= 1 then
    CommitEvent(FEvents.Keys[FEvents.Row]);
end;

procedure TDesignerInspector.EventsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  Name, Handler: string;
begin
  if (Key <> VK_RETURN) or (FEvents.Row < 1) then
    Exit;
  Key := 0;
  Name := FEvents.Keys[FEvents.Row];
  Handler := Trim(FEvents.Cells[1, FEvents.Row]);
  FEvents.EditorMode := False;
  if Handler <> '' then
    CommitEvent(Name)
  else if (FEventsShown.Values[Name] <> '') and Assigned(FOnEventCleared) then
    FOnEventCleared(Name);
  FEventsShown.Values[Name] := Handler;
end;

procedure TDesignerInspector.TypeEvent(const AName, AHandler: string);
var
  Row: Integer;
  Key: Word;
begin
  if not FEvents.FindRow(AName, Row) then
    Exit;
  FEvents.Row := Row;
  FEvents.Cells[1, Row] := AHandler;
  Key := VK_RETURN;
  EventsKeyDown(FEvents, Key, []);
end;

procedure TDesignerInspector.CommitEvent(const AName: string);
begin
  if Assigned(FOnEventHandler) then
    FOnEventHandler(AName, FEvents.Values[AName]);
end;

function TDesignerInspector.PropertyText(const AName: string): string;
begin
  Result := FProps.Values[AName];
end;

function TDesignerInspector.PickList(const AName: string): TArray<string>;
var
  Row: Integer;
begin
  Result := nil;
  if FProps.FindRow(AName, Row) then
    Result := FProps.ItemProps[Row - 1].PickList.ToStringArray;
end;

end.
