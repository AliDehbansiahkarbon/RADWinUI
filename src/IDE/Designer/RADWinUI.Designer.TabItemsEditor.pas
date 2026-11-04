unit RADWinUI.Designer.TabItemsEditor;

{
  The Object Inspector's editor of a tab bar's Items (the '...' button): the
  tabs in a list to add, remove and reorder, each with its label and an icon
  picked from a grid. Built in code, no form file. The text it returns is
  what RADWinUI.TabBarIcons reads: Home:Home, Search:Search, ...
}

interface

/// <summary>Shows the editor for AText. True, and the new text in AText, when the user pressed OK.</summary>
function EditTabItems(var AText: string): Boolean;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Types, System.Math, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids, RADWinUI.TabBarIcons;

const
  GridColumns = 10;
  CellSize = 38;

type
  TTabItemsForm = class(TForm)
  private
    FItems: TArray<TTabBarItemText>;
    FIcons: TArray<TTabBarIcon>;
    FIconFont: string;
    FList: TListBox;
    FTextEdit: TEdit;
    FIconEdit: TEdit;
    FGrid: TDrawGrid;
    FIconName: TLabel;
    FUpdating: Boolean;
    function Button(AParent: TWinControl; const ACaption: string; ALeft, ATop, AWidth: Integer;
      AClick: TNotifyEvent): TButton;
    procedure FillList;
    procedure ShowItem;
    function Current: Integer;
    procedure ListClick(Sender: TObject);
    procedure ListDraw(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure TextChange(Sender: TObject);
    procedure IconChange(Sender: TObject);
    procedure AddClick(Sender: TObject);
    procedure RemoveClick(Sender: TObject);
    procedure UpClick(Sender: TObject);
    procedure DownClick(Sender: TObject);
    procedure GridDraw(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure GridSelect(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure GridMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  public
    constructor CreateFor(const AText: string); reintroduce;
    function Text: string;
  end;

function EditTabItems(var AText: string): Boolean;
var
  Form: TTabItemsForm;
begin
  Form := TTabItemsForm.CreateFor(AText);
  try
    Result := Form.ShowModal = mrOk;
    if Result then
      AText := Form.Text;
  finally
    Form.Free;
  end;
end;

{ TTabItemsForm }

constructor TTabItemsForm.CreateFor(const AText: string);
var
  Panel: TPanel;
  Caption: TLabel;
  OkButton, CancelButton: TButton;
begin
  inherited CreateNew(Application);
  Self.Caption := 'Tabs';
  BorderStyle := bsDialog;
  Position := poMainFormCenter;
  ClientWidth := 640;
  ClientHeight := 420;
  Font.Name := 'Segoe UI';
  Font.Size := 9;
  if Screen.Fonts.IndexOf('Segoe Fluent Icons') >= 0 then
    FIconFont := 'Segoe Fluent Icons'
  else
    FIconFont := 'Segoe MDL2 Assets';
  FIcons := TabBarIcons;
  FItems := ParseTabBarItems(AText);
  if (Trim(AText) = '') and (Length(FItems) = 0) then
    FItems := ParseTabBarItems(DefaultTabBarItems);

  Caption := TLabel.Create(Self);
  Caption.Parent := Self;
  Caption.SetBounds(12, 10, 200, 16);
  Caption.Caption := 'Tabs, from left to right';

  FList := TListBox.Create(Self);
  FList.Parent := Self;
  FList.SetBounds(12, 30, 200, 300);
  FList.Style := lbOwnerDrawFixed;
  FList.ItemHeight := 30;
  FList.OnClick := ListClick;
  FList.OnDrawItem := ListDraw;

  Button(Self, '&Add', 12, 338, 96, AddClick);
  Button(Self, '&Remove', 116, 338, 96, RemoveClick);
  Button(Self, '&Up', 12, 368, 96, UpClick);
  Button(Self, '&Down', 116, 368, 96, DownClick);

  Panel := TPanel.Create(Self);
  Panel.Parent := Self;
  Panel.SetBounds(224, 30, 404, 330);
  Panel.BevelOuter := bvNone;

  Caption := TLabel.Create(Self);
  Caption.Parent := Panel;
  Caption.SetBounds(0, 2, 60, 16);
  Caption.Caption := '&Label';
  FTextEdit := TEdit.Create(Self);
  FTextEdit.Parent := Panel;
  FTextEdit.SetBounds(60, 0, 340, 23);
  FTextEdit.OnChange := TextChange;
  Caption.FocusControl := FTextEdit;

  Caption := TLabel.Create(Self);
  Caption.Parent := Panel;
  Caption.SetBounds(0, 34, 60, 16);
  Caption.Caption := '&Icon';
  FIconEdit := TEdit.Create(Self);
  FIconEdit.Parent := Panel;
  FIconEdit.SetBounds(60, 32, 340, 23);
  FIconEdit.OnChange := IconChange;
  FIconEdit.Hint := 'A name from the grid, or a Segoe Fluent Icons code point such as E80F (E80F/EA8A for outline/filled)';
  FIconEdit.ShowHint := True;
  Caption.FocusControl := FIconEdit;

  FGrid := TDrawGrid.Create(Self);
  FGrid.Parent := Panel;
  FGrid.SetBounds(0, 66, GridColumns * (CellSize + 1) + 22, 236);
  FGrid.FixedCols := 0;
  FGrid.FixedRows := 0;
  FGrid.ColCount := GridColumns;
  FGrid.RowCount := (Length(FIcons) + GridColumns - 1) div GridColumns;
  FGrid.DefaultColWidth := CellSize;
  FGrid.DefaultRowHeight := CellSize;
  FGrid.Options := [goDrawFocusSelected, goThumbTracking];
  FGrid.ScrollBars := ssVertical;
  FGrid.OnDrawCell := GridDraw;
  FGrid.OnSelectCell := GridSelect;
  FGrid.OnMouseMove := GridMove;

  FIconName := TLabel.Create(Self);
  FIconName.Parent := Panel;
  FIconName.SetBounds(0, 308, 400, 16);

  OkButton := Button(Self, 'OK', 452, 384, 84, nil);
  OkButton.ModalResult := mrOk;
  OkButton.Default := True;
  CancelButton := Button(Self, 'Cancel', 544, 384, 84, nil);
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;

  FillList;
  if Length(FItems) > 0 then
    FList.ItemIndex := 0;
  ShowItem;
end;

function TTabItemsForm.Button(AParent: TWinControl; const ACaption: string; ALeft, ATop, AWidth: Integer;
  AClick: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, 26);
  Result.Caption := ACaption;
  Result.OnClick := AClick;
end;

function TTabItemsForm.Text: string;
begin
  Result := FormatTabBarItems(FItems);
end;

function TTabItemsForm.Current: Integer;
begin
  Result := FList.ItemIndex;
  if (Result < 0) or (Result > High(FItems)) then
    Result := -1;
end;

procedure TTabItemsForm.FillList;
var
  Index, I: Integer;
begin
  Index := FList.ItemIndex;
  FList.Items.BeginUpdate;
  try
    FList.Items.Clear;
    for I := 0 to High(FItems) do
      FList.Items.Add(FItems[I].Text);
  finally
    FList.Items.EndUpdate;
  end;
  FList.ItemIndex := Min(Index, FList.Items.Count - 1);
end;

procedure TTabItemsForm.ShowItem;
var
  Index: Integer;
begin
  Index := Current;
  FUpdating := True;
  try
    FTextEdit.Enabled := Index >= 0;
    FIconEdit.Enabled := Index >= 0;
    if Index >= 0 then
    begin
      FTextEdit.Text := FItems[Index].Text;
      FIconEdit.Text := FItems[Index].Icon;
    end
    else
    begin
      FTextEdit.Text := '';
      FIconEdit.Text := '';
    end;
  finally
    FUpdating := False;
  end;
  FGrid.Invalidate;
end;

procedure TTabItemsForm.ListClick(Sender: TObject);
begin
  ShowItem;
end;

procedure TTabItemsForm.ListDraw(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  Canvas: TCanvas;
  Glyph, Filled: Char;
  Area: TRect;
  Line: string;
begin
  Canvas := FList.Canvas;
  Canvas.FillRect(Rect);
  if (Index < 0) or (Index > High(FItems)) then
    Exit;
  ResolveTabBarIcon(FItems[Index].Icon, Glyph, Filled);
  Area := Rect;
  Area.Right := Area.Left + 32;
  Canvas.Font.Name := FIconFont;
  Canvas.Font.Size := 13;
  Canvas.Brush.Style := bsClear;
  Line := Glyph;
  DrawText(Canvas.Handle, PChar(Line), 1, Area, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  Area := Rect;
  Inc(Area.Left, 36);
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 9;
  Line := FItems[Index].Text;
  if Line = '' then
    Line := '(no label)';
  DrawText(Canvas.Handle, PChar(Line), Length(Line), Area, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
  Canvas.Brush.Style := bsSolid;
end;

procedure TTabItemsForm.TextChange(Sender: TObject);
var
  Index: Integer;
begin
  Index := Current;
  if FUpdating or (Index < 0) then
    Exit;
  FItems[Index].Text := FTextEdit.Text;
  FList.Items[Index] := FTextEdit.Text;
  FList.Invalidate;
end;

procedure TTabItemsForm.IconChange(Sender: TObject);
var
  Index: Integer;
begin
  Index := Current;
  if FUpdating or (Index < 0) then
    Exit;
  FItems[Index].Icon := FIconEdit.Text;
  FList.Invalidate;
  FGrid.Invalidate;
end;

procedure TTabItemsForm.AddClick(Sender: TObject);
var
  Item: TTabBarItemText;
begin
  Item.Text := 'Tab ' + IntToStr(Length(FItems) + 1);
  Item.Icon := 'Star';
  FItems := FItems + [Item];
  FillList;
  FList.ItemIndex := High(FItems);
  ShowItem;
  FTextEdit.SetFocus;
  FTextEdit.SelectAll;
end;

procedure TTabItemsForm.RemoveClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := Current;
  if Index < 0 then
    Exit;
  Delete(FItems, Index, 1);
  FillList;
  FList.ItemIndex := Min(Index, High(FItems));
  ShowItem;
end;

procedure TTabItemsForm.UpClick(Sender: TObject);
var
  Index: Integer;
  Item: TTabBarItemText;
begin
  Index := Current;
  if Index <= 0 then
    Exit;
  Item := FItems[Index - 1];
  FItems[Index - 1] := FItems[Index];
  FItems[Index] := Item;
  FillList;
  FList.ItemIndex := Index - 1;
  ShowItem;
end;

procedure TTabItemsForm.DownClick(Sender: TObject);
var
  Index: Integer;
  Item: TTabBarItemText;
begin
  Index := Current;
  if (Index < 0) or (Index >= High(FItems)) then
    Exit;
  Item := FItems[Index + 1];
  FItems[Index + 1] := FItems[Index];
  FItems[Index] := Item;
  FillList;
  FList.ItemIndex := Index + 1;
  ShowItem;
end;

procedure TTabItemsForm.GridDraw(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  Index: Integer;
  Canvas: TCanvas;
  Line: string;
  Glyph, Filled: Char;
  Chosen: Boolean;
begin
  Canvas := FGrid.Canvas;
  Index := ARow * GridColumns + ACol;
  Chosen := False;
  if (Index <= High(FIcons)) and (Current >= 0) and ResolveTabBarIcon(FItems[Current].Icon, Glyph, Filled) then
    Chosen := Glyph = FIcons[Index].Glyph;
  if Chosen then
    Canvas.Brush.Color := clHighlight
  else
    Canvas.Brush.Color := clWindow;
  Canvas.FillRect(Rect);
  if Index > High(FIcons) then
    Exit;
  Canvas.Font.Name := FIconFont;
  Canvas.Font.Size := 14;
  if Chosen then
    Canvas.Font.Color := clHighlightText
  else
    Canvas.Font.Color := clWindowText;
  Line := FIcons[Index].Glyph;
  DrawText(Canvas.Handle, PChar(Line), 1, Rect, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
end;

procedure TTabItemsForm.GridSelect(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
var
  Index: Integer;
begin
  Index := ARow * GridColumns + ACol;
  if (Index > High(FIcons)) or (Current < 0) then
    Exit;
  // Picking an icon writes its name, the label stays
  FIconEdit.Text := FIcons[Index].Name;
end;

procedure TTabItemsForm.GridMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  Col, Row, Index: Integer;
begin
  FGrid.MouseToCell(X, Y, Col, Row);
  Index := Row * GridColumns + Col;
  if (Col >= 0) and (Row >= 0) and (Index <= High(FIcons)) then
    FIconName.Caption := FIcons[Index].Name
  else
    FIconName.Caption := '';
end;

end.
