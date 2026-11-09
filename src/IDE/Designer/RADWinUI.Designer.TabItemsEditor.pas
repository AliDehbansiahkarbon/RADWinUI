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
  Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids, Vcl.Themes, RADWinUI.TabBarIcons, RADWinUI.Designer.Dialogs;

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
    FPPI: Integer;
    function S(AValue: Integer): Integer;
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
    ThemeForm(Form);
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
  // Laid out here at the DPI of the IDE window, sizes and font alike
  FPPI := DialogPPI;
  PrepareDialog(Self, FPPI);
  ClientWidth := S(640);
  ClientHeight := S(420);
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
  Caption.SetBounds(S(12), S(10), S(200), S(16));
  Caption.Caption := 'Tabs, from left to right';

  FList := TListBox.Create(Self);
  FList.Parent := Self;
  FList.SetBounds(S(12), S(30), S(200), S(300));
  FList.Style := lbOwnerDrawFixed;
  FList.ItemHeight := S(30);
  FList.OnClick := ListClick;
  FList.OnDrawItem := ListDraw;

  Button(Self, '&Add', S(12), S(338), S(96), AddClick);
  Button(Self, '&Remove', S(116), S(338), S(96), RemoveClick);
  Button(Self, '&Up', S(12), S(368), S(96), UpClick);
  Button(Self, '&Down', S(116), S(368), S(96), DownClick);

  Panel := TPanel.Create(Self);
  Panel.Parent := Self;
  Panel.SetBounds(S(224), S(30), S(412), S(330));
  Panel.BevelOuter := bvNone;

  Caption := TLabel.Create(Self);
  Caption.Parent := Panel;
  Caption.SetBounds(0, S(2), S(60), S(16));
  Caption.Caption := '&Label';
  FTextEdit := TEdit.Create(Self);
  FTextEdit.Parent := Panel;
  FTextEdit.SetBounds(S(60), 0, S(340), FTextEdit.Height);
  FTextEdit.OnChange := TextChange;
  Caption.FocusControl := FTextEdit;

  Caption := TLabel.Create(Self);
  Caption.Parent := Panel;
  Caption.SetBounds(0, S(34), S(60), S(16));
  Caption.Caption := '&Icon';
  FIconEdit := TEdit.Create(Self);
  FIconEdit.Parent := Panel;
  FIconEdit.SetBounds(S(60), S(32), S(340), FIconEdit.Height);
  FIconEdit.OnChange := IconChange;
  FIconEdit.Hint := 'A name from the grid, or a Segoe Fluent Icons code point such as E80F (E80F/EA8A for outline/filled)';
  FIconEdit.ShowHint := True;
  Caption.FocusControl := FIconEdit;

  FGrid := TDrawGrid.Create(Self);
  FGrid.Parent := Panel;
  FGrid.SetBounds(0, S(66), GridColumns * (S(CellSize) + 1) + S(22), S(236));
  FGrid.FixedCols := 0;
  FGrid.FixedRows := 0;
  FGrid.ColCount := GridColumns;
  FGrid.RowCount := (Length(FIcons) + GridColumns - 1) div GridColumns;
  FGrid.DefaultColWidth := S(CellSize);
  FGrid.DefaultRowHeight := S(CellSize);
  FGrid.Options := [goDrawFocusSelected, goThumbTracking];
  FGrid.ScrollBars := ssVertical;
  FGrid.OnDrawCell := GridDraw;
  FGrid.OnSelectCell := GridSelect;
  FGrid.OnMouseMove := GridMove;

  FIconName := TLabel.Create(Self);
  FIconName.Parent := Panel;
  FIconName.SetBounds(0, S(308), S(400), S(16));

  OkButton := Button(Self, 'OK', S(452), S(384), S(84), nil);
  OkButton.ModalResult := mrOk;
  OkButton.Default := True;
  CancelButton := Button(Self, 'Cancel', S(544), S(384), S(84), nil);
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;
  FitDialogFrame(Self, FPPI);

  FillList;
  if Length(FItems) > 0 then
    FList.ItemIndex := 0;
  ShowItem;
end;

function TTabItemsForm.S(AValue: Integer): Integer;
begin
  Result := DialogScale(AValue, FPPI);
end;

function TTabItemsForm.Button(AParent: TWinControl; const ACaption: string; ALeft, ATop, AWidth: Integer;
  AClick: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, S(26));
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
  Area.Right := Area.Left + S(32);
  Canvas.Font.Name := FIconFont;
  Canvas.Font.Height := -MulDiv(13, FPPI, 72);
  Canvas.Brush.Style := bsClear;
  Line := Glyph;
  DrawText(Canvas.Handle, PChar(Line), 1, Area, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  Area := Rect;
  Inc(Area.Left, S(36));
  Canvas.Font.Name := Font.Name;
  Canvas.Font.Height := Font.Height;
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
  // The theme's colours, the system ones would paint a light grid in a dark IDE
  if Chosen then
    Canvas.Brush.Color := StyleServices.GetSystemColor(clHighlight)
  else
    Canvas.Brush.Color := StyleServices.GetSystemColor(clWindow);
  Canvas.FillRect(Rect);
  if Index > High(FIcons) then
    Exit;
  Canvas.Font.Name := FIconFont;
  Canvas.Font.Height := -MulDiv(14, FPPI, 72);
  if Chosen then
    Canvas.Font.Color := StyleServices.GetSystemColor(clHighlightText)
  else
    Canvas.Font.Color := StyleServices.GetSystemColor(clWindowText);
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
