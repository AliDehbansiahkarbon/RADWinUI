unit RADWinUI.Preview.PromptBox;

{
  The "Create XAML with AI" prompt bar: a rounded, borderless bar centred over the
  IDE (like a quick prompt), with an accent icon, a placeholder, room for several
  lines (Shift+Enter), a busy indicator and an error line. Enter sends, Esc closes
  or cancels, Up and Down recall earlier prompts. The colours come from the caller
  (the IDE theme). No ToolsAPI here: RADWinUI.Preview.Command sends the request.
}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  System.Types,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.Forms;

type
  TPromptSubmitEvent = procedure(const APrompt: string) of object;

  /// <summary>A memo that paints a placeholder while it is empty (EM_SETCUEBANNER is
  /// for single-line edits only).</summary>
  TPromptMemo = class(TMemo)
  strict private
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
  public
    Placeholder: string;
    PlaceholderColor: TColor;
  end;

  TXamlPromptBox = class(TForm)
  strict private
    FIcon: TPaintBox;
    FMemo: TPromptMemo;
    FStatus: TLabel;
    FTimer: TTimer;
    FBusy: Boolean;
    FFrame: Integer;
    FBusyText: string;
    FHistoryIndex: Integer;
    FBorder, FAccent, FDim: TColor;
    FOnSubmit: TPromptSubmitEvent;
    FOnCancel: TNotifyEvent;
    procedure PaintIcon(Sender: TObject);
    procedure MemoChange(Sender: TObject);
    procedure MemoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Spin(Sender: TObject);
    procedure Deactivated(Sender: TObject);
    procedure Arrange;
    function Scaled(AValue: Integer): Integer;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Paint; override;
  public
    /// <summary>Lines the bar grows to before it scrolls.</summary>
    const MaxLines = 6;
    constructor CreateBox(AOwner: TComponent; ABackground, AText, ABorder, AAccent: TColor);
    /// <summary>Shows the bar centred over AOver (the IDE's main window) with the keyboard focus.</summary>
    procedure ShowOver(AOver: TCustomForm);
    /// <summary>Waiting for the answer: the text is read-only and the bar shows a spinner.</summary>
    procedure SetBusy(ABusy: Boolean; const AStatus: string = '');
    /// <summary>An error in the bar itself, the text stays editable.</summary>
    procedure ShowError(const AText: string);
    property Busy: Boolean read FBusy;
    property Memo: TPromptMemo read FMemo;
    property OnSubmit: TPromptSubmitEvent read FOnSubmit write FOnSubmit;
    /// <summary>Esc, or the bar lost the focus while not busy.</summary>
    property OnCancel: TNotifyEvent read FOnCancel write FOnCancel;
  end;

/// <summary>The prompts sent in this IDE session, newest last (Up recalls them).</summary>
function PromptHistory: TStrings;

implementation

uses
  Winapi.Dwmapi,
  Winapi.GDIPAPI,
  Winapi.GDIPOBJ,
  System.Math;

const
  BaseWidth = 640;
  LinePad = 14;
  IconSize = 24;
  // Braille dots, as escapes: the source stays ASCII
  SpinFrames: array[0..7] of string = (#$280B, #$2819, #$2839, #$2838, #$283C, #$2834, #$2826, #$2827);
  MaxHistory = 20;

var
  History: TStringList;

function PromptHistory: TStrings;
begin
  if History = nil then
    History := TStringList.Create;
  Result := History;
end;

function Blend(A, B: TColor; AWeight: Integer): TColor;
var
  X, Y: TColor;
begin
  X := ColorToRGB(A);
  Y := ColorToRGB(B);
  Result := RGB((GetRValue(X) * AWeight + GetRValue(Y) * (100 - AWeight)) div 100,
    (GetGValue(X) * AWeight + GetGValue(Y) * (100 - AWeight)) div 100,
    (GetBValue(X) * AWeight + GetBValue(Y) * (100 - AWeight)) div 100);
end;

{ TPromptMemo }

procedure TPromptMemo.WMPaint(var Message: TWMPaint);
var
  Canvas: TControlCanvas;
begin
  inherited;
  if (GetTextLen = 0) and (Placeholder <> '') then
  begin
    Canvas := TControlCanvas.Create;
    try
      Canvas.Control := Self;
      Canvas.Font.Assign(Font);
      Canvas.Font.Color := PlaceholderColor;
      Canvas.Brush.Style := bsClear;
      Canvas.TextOut(2, 0, Placeholder);
    finally
      Canvas.Free;
    end;
  end;
end;

{ TXamlPromptBox }

constructor TXamlPromptBox.CreateBox(AOwner: TComponent; ABackground, AText, ABorder, AAccent: TColor);
begin
  inherited CreateNew(AOwner);
  BorderStyle := bsNone;
  StyleElements := [];
  Color := ABackground;
  DoubleBuffered := True;
  KeyPreview := False;
  FBorder := ABorder;
  FAccent := AAccent;
  FDim := Blend(AText, ABackground, 55);
  Font.Name := 'Segoe UI';
  Font.Size := 11;
  Font.Color := AText;
  FHistoryIndex := -1;

  FIcon := TPaintBox.Create(Self);
  FIcon.Parent := Self;
  FIcon.OnPaint := PaintIcon;

  FMemo := TPromptMemo.Create(Self);
  FMemo.Parent := Self;
  FMemo.BorderStyle := bsNone;
  FMemo.StyleElements := [];
  FMemo.Color := ABackground;
  FMemo.Font.Assign(Font);
  FMemo.WordWrap := True;
  FMemo.WantReturns := True;
  FMemo.ScrollBars := ssNone;
  FMemo.OnChange := MemoChange;
  FMemo.OnKeyDown := MemoKeyDown;
  FMemo.Placeholder := 'Describe the UI you want...  (Enter sends, Shift+Enter for a new line, Esc closes)';
  FMemo.PlaceholderColor := FDim;

  FStatus := TLabel.Create(Self);
  FStatus.Parent := Self;
  FStatus.StyleElements := [];
  FStatus.Transparent := True;
  FStatus.Font.Assign(Font);
  FStatus.Font.Size := 9;
  FStatus.Font.Color := FDim;
  FStatus.AutoSize := False;
  FStatus.EllipsisPosition := epEndEllipsis;

  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 90;
  FTimer.OnTimer := Spin;

  OnDeactivate := Deactivated;
end;

procedure TXamlPromptBox.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.WindowClass.style := Params.WindowClass.style or CS_DROPSHADOW;
end;

function TXamlPromptBox.Scaled(AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, CurrentPPI, 96);
end;

procedure TXamlPromptBox.Arrange;
var
  Lines, LineHeight, TextLeft, TextWidth, StatusHeight: Integer;
begin
  Canvas.Font.Assign(FMemo.Font);
  LineHeight := Canvas.TextHeight('Ag');
  Lines := EnsureRange(SendMessage(FMemo.Handle, EM_GETLINECOUNT, 0, 0), 1, MaxLines);
  StatusHeight := 0;
  if FStatus.Caption <> '' then
    StatusHeight := Scaled(18);
  ClientHeight := Scaled(LinePad) * 2 + LineHeight * Lines + StatusHeight;
  TextLeft := Scaled(LinePad + IconSize + 12);
  TextWidth := ClientWidth - TextLeft - Scaled(LinePad);
  FIcon.SetBounds(Scaled(LinePad), Scaled(LinePad) + (LineHeight - Scaled(IconSize)) div 2, Scaled(IconSize),
    Scaled(IconSize));
  FMemo.SetBounds(TextLeft, Scaled(LinePad), TextWidth, LineHeight * Lines);
  // No scroll bar (it would not follow the IDE theme): the memo scrolls to the caret by itself
  FStatus.SetBounds(TextLeft, Scaled(LinePad) + LineHeight * Lines + Scaled(2), TextWidth, Scaled(16));
  Invalidate;
end;

procedure TXamlPromptBox.ShowOver(AOver: TCustomForm);
const
  DWMWA_WINDOW_CORNER_PREFERENCE = 33;
  DWMWCP_ROUND = 2;
var
  Corner: Integer;
  Area: TRect;
begin
  if AOver <> nil then
  begin
    PopupMode := pmExplicit;
    PopupParent := AOver;
    Area := AOver.BoundsRect;
  end
  else
    Area := Screen.WorkAreaRect;
  ClientWidth := Min(Scaled(BaseWidth), Area.Width - Scaled(40));
  HandleNeeded;
  Corner := DWMWCP_ROUND; // Windows 11: rounded corners and the system shadow
  DwmSetWindowAttribute(Handle, DWMWA_WINDOW_CORNER_PREFERENCE, @Corner, SizeOf(Corner));
  Arrange;
  Left := Area.Left + (Area.Width - Width) div 2;
  Top := Area.Top + (Area.Height - Height) div 2;
  Show;
  FMemo.SetFocus;
end;

procedure TXamlPromptBox.Paint;
begin
  inherited;
  Canvas.Pen.Color := FBorder;
  Canvas.Brush.Style := bsClear;
  Canvas.RoundRect(0, 0, ClientWidth, ClientHeight, Scaled(16), Scaled(16));
end;

/// The RADWinUI logo (docs\images\radwinui-logo.svg) drawn with GDI+ at any size: the tile
/// from Delphi red to Windows blue, a window with its title bar and caption buttons, and braces.
procedure DrawLogo(ACanvas: TCanvas; const ARect: TRect);
var
  G: TGPGraphics;
  S: Single;
  Path, Brace: TGPGraphicsPath;
  Fill: TGPLinearGradientBrush;
  Colors: array[0..2] of TGPColor;
  Stops: array[0..2] of Single;
  White: TGPPen;
  Dot: TGPSolidBrush;

  function X(AValue: Single): Single;
  begin
    Result := ARect.Left + AValue * S;
  end;

  function Y(AValue: Single): Single;
  begin
    Result := ARect.Top + AValue * S;
  end;

  procedure RoundRect(APath: TGPGraphicsPath; ALeft, ATop, AWidth, AHeight, ARadius: Single);
  var
    D: Single;
  begin
    D := ARadius * 2;
    APath.AddArc(X(ALeft), Y(ATop), D * S, D * S, 180, 90);
    APath.AddArc(X(ALeft + AWidth - D), Y(ATop), D * S, D * S, 270, 90);
    APath.AddArc(X(ALeft + AWidth - D), Y(ATop + AHeight - D), D * S, D * S, 0, 90);
    APath.AddArc(X(ALeft), Y(ATop + AHeight - D), D * S, D * S, 90, 90);
    APath.CloseFigure;
  end;

  // One brace: the SVG's path, AMirror for the closing one
  procedure AddBrace(APath: TGPGraphicsPath; AMirror: Boolean);
  const
    // M222 222 C196 222 190 236 190 254 L190 272 C190 284 182 292 168 292 C182 292 190 300 190 312
    // L190 330 C190 348 196 360 222 360
    P: array[0..15] of Single = (222, 222, 196, 222, 190, 236, 190, 254, 190, 272, 190, 284, 182, 292, 168, 292);
    Q: array[0..15] of Single = (168, 292, 182, 292, 190, 300, 190, 312, 190, 330, 190, 348, 196, 360, 222, 360);
  var
    M: Single;

    function MX(AValue: Single): Single;
    begin
      if AMirror then
        Result := X(512 - AValue)
      else
        Result := X(AValue);
    end;

  begin
    M := 0;
    APath.StartFigure;
    APath.AddBezier(MX(P[0]), Y(P[1]), MX(P[2]), Y(P[3]), MX(P[4]), Y(P[5]), MX(P[6]), Y(P[7]));
    APath.AddLine(MX(P[6]), Y(P[7]), MX(P[8]), Y(P[9]));
    APath.AddBezier(MX(P[8]), Y(P[9]), MX(P[10]), Y(P[11]), MX(P[12]), Y(P[13]), MX(P[14]), Y(P[15]) + M);
    APath.AddBezier(MX(Q[0]), Y(Q[1]), MX(Q[2]), Y(Q[3]), MX(Q[4]), Y(Q[5]), MX(Q[6]), Y(Q[7]));
    APath.AddLine(MX(Q[6]), Y(Q[7]), MX(Q[8]), Y(Q[9]));
    APath.AddBezier(MX(Q[8]), Y(Q[9]), MX(Q[10]), Y(Q[11]), MX(Q[12]), Y(Q[13]), MX(Q[14]), Y(Q[15]));
  end;

begin
  S := ARect.Width / 512;
  G := TGPGraphics.Create(ACanvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    G.SetPixelOffsetMode(PixelOffsetModeHighQuality);
    // The tile
    Path := TGPGraphicsPath.Create;
    try
      RoundRect(Path, 16, 16, 480, 480, 108);
      Fill := TGPLinearGradientBrush.Create(MakePoint(X(16), Y(16)), MakePoint(X(496), Y(496)),
        MakeColor(255, $E5, $32, $2D), MakeColor(255, $0A, $6C, $D6));
      try
        Colors[0] := MakeColor(255, $E5, $32, $2D);
        Colors[1] := MakeColor(255, $8A, $3F, $A8);
        Colors[2] := MakeColor(255, $0A, $6C, $D6);
        Stops[0] := 0;
        Stops[1] := 0.55;
        Stops[2] := 1;
        Fill.SetInterpolationColors(@Colors[0], @Stops[0], 3);
        G.FillPath(Fill, Path);
      finally
        Fill.Free;
      end;
    finally
      Path.Free;
    end;
    // The window: frame, title bar line and caption buttons
    White := TGPPen.Create(MakeColor(255, 255, 255, 255), 22 * S);
    Dot := TGPSolidBrush.Create(MakeColor(255, 255, 255, 255));
    Path := TGPGraphicsPath.Create;
    Brace := TGPGraphicsPath.Create;
    try
      RoundRect(Path, 96, 120, 320, 272, 34);
      G.DrawPath(White, Path);
      White.SetWidth(18 * S);
      G.DrawLine(White, X(107), Y(188), X(405), Y(188));
      G.FillEllipse(Dot, X(306), Y(144), 20 * S, 20 * S);
      G.FillEllipse(Dot, X(342), Y(144), 20 * S, 20 * S);
      // The braces
      White.SetStartCap(LineCapRound);
      White.SetEndCap(LineCapRound);
      White.SetLineJoin(LineJoinRound);
      AddBrace(Brace, False);
      AddBrace(Brace, True);
      G.DrawPath(White, Brace);
    finally
      Brace.Free;
      Path.Free;
      Dot.Free;
      White.Free;
    end;
  finally
    G.Free;
  end;
end;

procedure TXamlPromptBox.PaintIcon(Sender: TObject);
var
  Box: TPaintBox;
begin
  // The RADWinUI logo
  Box := Sender as TPaintBox;
  Box.Canvas.Brush.Color := Color;
  Box.Canvas.FillRect(Box.ClientRect);
  DrawLogo(Box.Canvas, Box.ClientRect);
end;

procedure TXamlPromptBox.MemoChange(Sender: TObject);
begin
  FMemo.Invalidate; // the placeholder goes or comes back
  if FStatus.Caption <> '' then
    FStatus.Caption := '';
  Arrange;
end;

procedure TXamlPromptBox.MemoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  Text: string;
  Line: Integer;
begin
  case Key of
    VK_ESCAPE:
      begin
        Key := 0;
        if Assigned(FOnCancel) then
          FOnCancel(Self);
      end;
    VK_RETURN:
      if not (ssShift in Shift) then
      begin
        Key := 0;
        if FBusy then
          Exit;
        Text := Trim(FMemo.Text); // TCaption has no string helper
        if Text <> '' then
        begin
          if PromptHistory.IndexOf(Text) >= 0 then
            PromptHistory.Delete(PromptHistory.IndexOf(Text));
          PromptHistory.Add(Text);
          while PromptHistory.Count > MaxHistory do
            PromptHistory.Delete(0);
        end;
        FHistoryIndex := -1;
        if Assigned(FOnSubmit) then
          FOnSubmit(Text);
      end;
    VK_UP, VK_DOWN:
      begin
        // On the first (Up) or last (Down) line: the earlier prompts
        Line := SendMessage(FMemo.Handle, EM_LINEFROMCHAR, WPARAM(-1), 0);
        if FBusy or (PromptHistory.Count = 0) or ((Key = VK_UP) and (Line > 0)) or
          ((Key = VK_DOWN) and (Line < SendMessage(FMemo.Handle, EM_GETLINECOUNT, 0, 0) - 1)) then
          Exit;
        if Key = VK_UP then
        begin
          if FHistoryIndex < 0 then
            FHistoryIndex := PromptHistory.Count;
          FHistoryIndex := Max(0, FHistoryIndex - 1);
        end
        else if FHistoryIndex >= 0 then
          Inc(FHistoryIndex);
        Key := 0;
        if (FHistoryIndex >= 0) and (FHistoryIndex < PromptHistory.Count) then
          FMemo.Text := PromptHistory[FHistoryIndex]
        else
        begin
          FHistoryIndex := -1;
          FMemo.Text := '';
        end;
        FMemo.SelStart := Length(FMemo.Text);
      end;
  end;
end;

procedure TXamlPromptBox.SetBusy(ABusy: Boolean; const AStatus: string);
begin
  FBusy := ABusy;
  FMemo.ReadOnly := ABusy;
  FTimer.Enabled := ABusy;
  FStatus.Font.Color := FDim;
  FBusyText := AStatus;
  FStatus.Caption := AStatus;
  if ABusy then
    Spin(nil);
  Arrange;
end;

procedure TXamlPromptBox.ShowError(const AText: string);
begin
  SetBusy(False);
  FStatus.Font.Color := Blend(clRed, Font.Color, 60);
  FStatus.Caption := AText;
  Arrange;
  if FMemo.CanFocus then
    FMemo.SetFocus;
end;

procedure TXamlPromptBox.Spin(Sender: TObject);
begin
  FFrame := (FFrame + 1) mod Length(SpinFrames);
  FStatus.Caption := SpinFrames[FFrame] + ' ' + FBusyText;
end;

procedure TXamlPromptBox.Deactivated(Sender: TObject);
begin
  // A click elsewhere closes the bar, unless it is waiting for the answer
  if not FBusy and Assigned(FOnCancel) then
    FOnCancel(Self);
end;

initialization

finalization
  FreeAndNil(History);

end.
