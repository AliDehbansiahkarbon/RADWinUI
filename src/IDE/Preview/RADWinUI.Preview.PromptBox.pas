unit RADWinUI.Preview.PromptBox;

{
  The "Create XAML with AI" prompt bar: a rounded, borderless bar centred over the
  IDE (like a quick prompt), with an accent icon, a placeholder, room for several
  lines (Shift+Enter), a busy indicator and an error line. Enter sends, Esc closes
  or cancels, Up and Down recall earlier prompts. An image can go along: pasted (Ctrl+V),
  dropped as a file, or the design captured (Capture); it shows as a thumbnail with an x
  that removes it. The colours come from the caller (the IDE theme). No ToolsAPI here:
  RADWinUI.Preview.Command sends the request.
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
  Vcl.Forms,
  Winapi.GDIPOBJ;

type
  TPromptSubmitEvent = procedure(const APrompt: string) of object;

  /// <summary>A memo that paints a placeholder while it is empty (EM_SETCUEBANNER is
  /// for single-line edits only), and hands pasted images and dropped files to the bar.</summary>
  TPromptMemo = class(TMemo)
  strict private
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMPaste(var Message: TMessage); message WM_PASTE;
    procedure WMDropFiles(var Message: TWMDropFiles); message WM_DROPFILES;
  protected
    procedure CreateWnd; override;
  public
    Placeholder: string;
    PlaceholderColor: TColor;
    /// <summary>Ctrl+V: True when it took the clipboard as an image, the text is not pasted then.</summary>
    OnPasteImage: TFunc<Boolean>;
    OnDropFile: TProc<string>;
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
    FOnCapture: TNotifyEvent;
    FOnApplyAnyway: TNotifyEvent;
    FNotice: string;
    FCapture: TLabel;
    FChip: TPaintBox;
    FImage: TBytes;
    FImageMime: string;
    FThumb: TGPBitmap;
    FRemoveRect: TRect;
    procedure PaintIcon(Sender: TObject);
    procedure PaintChip(Sender: TObject);
    procedure ChipMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure CaptureClick(Sender: TObject);
    function PasteImage: Boolean;
    procedure DropFile(AFile: string);
    procedure WMDropFiles(var Message: TWMDropFiles); message WM_DROPFILES;
    procedure MemoChange(Sender: TObject);
    procedure MemoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MemoKeyPress(Sender: TObject; var Key: Char);
    procedure ShowNotice;
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
    /// <summary>A lasting note under the text, such as missing AI setup: shown whenever no
    /// progress or error is, '' removes it.</summary>
    procedure SetNotice(const AText: string);
    /// <summary>The image sent with the prompt (from RADWinUI.Designer.Vision), replacing any before.</summary>
    procedure SetImage(const AData: TBytes; const AMimeType: string);
    procedure ClearImage;
    /// <summary>Loads an image file (PNG, JPEG, BMP, GIF) into the bar, or shows why not.</summary>
    procedure LoadImageFile(const AFile: string);
    function HasImage: Boolean;
    destructor Destroy; override;
    property Image: TBytes read FImage;
    property ImageMimeType: string read FImageMime;
    property Busy: Boolean read FBusy;
    property Memo: TPromptMemo read FMemo;
    property OnSubmit: TPromptSubmitEvent read FOnSubmit write FOnSubmit;
    /// <summary>Esc, or the bar lost the focus while not busy.</summary>
    property OnCancel: TNotifyEvent read FOnCancel write FOnCancel;
    /// <summary>The Capture link: the caller asks the designer for its picture and calls SetImage.</summary>
    property OnCapture: TNotifyEvent read FOnCapture write FOnCapture;
    /// <summary>Ctrl+Enter: apply the last answer although it failed the check.</summary>
    property OnApplyAnyway: TNotifyEvent read FOnApplyAnyway write FOnApplyAnyway;
  end;

/// <summary>The prompts sent in this IDE session, newest last (Up recalls them).</summary>
function PromptHistory: TStrings;

implementation

uses
  Winapi.Dwmapi,
  Winapi.GDIPAPI,
  Winapi.ShellAPI,
  Winapi.ActiveX,
  System.Math,
  System.StrUtils,
  Vcl.Clipbrd,
  RADWinUI.Designer.Vision;

const
  BaseWidth = 640;
  LinePad = 14;
  IconSize = 24;
  ChipHeight = 56;
  ImageFiles: array[0..4] of string = ('.png', '.jpg', '.jpeg', '.bmp', '.gif');
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

procedure TPromptMemo.CreateWnd;
begin
  inherited;
  DragAcceptFiles(Handle, True);
end;

procedure TPromptMemo.WMPaste(var Message: TMessage);
begin
  if Assigned(OnPasteImage) and OnPasteImage() then
    Exit;
  inherited;
end;

function DroppedFile(ADrop: HDROP): string;
var
  Name: array[0..MAX_PATH] of Char;
begin
  Result := '';
  if DragQueryFile(ADrop, 0, Name, Length(Name)) > 0 then
    Result := Name;
end;

procedure TPromptMemo.WMDropFiles(var Message: TWMDropFiles);
var
  Name: string;
begin
  Name := DroppedFile(Message.Drop);
  DragFinish(Message.Drop);
  Message.Result := 0;
  if (Name <> '') and Assigned(OnDropFile) then
    OnDropFile(Name);
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
  FMemo.OnKeyPress := MemoKeyPress;
  FMemo.Placeholder := 'Describe the UI you want, paste or drop an image...  (Enter sends, Esc closes)';
  FMemo.PlaceholderColor := FDim;
  FMemo.OnPasteImage := PasteImage;
  FMemo.OnDropFile := DropFile;

  FCapture := TLabel.Create(Self);
  FCapture.Parent := Self;
  FCapture.StyleElements := [];
  FCapture.Transparent := True;
  FCapture.Font.Assign(Font);
  FCapture.Font.Size := 9;
  FCapture.Font.Color := FDim;
  FCapture.Caption := 'Capture';
  FCapture.Cursor := crHandPoint;
  FCapture.Hint := 'Send the designer''s picture of this file with the prompt. You can also paste an image ' +
    '(Ctrl+V) or drop an image file here.';
  FCapture.ShowHint := True;
  FCapture.OnClick := CaptureClick;

  FChip := TPaintBox.Create(Self);
  FChip.Parent := Self;
  FChip.Visible := False;
  FChip.OnPaint := PaintChip;
  FChip.OnMouseDown := ChipMouseDown;

  FStatus := TLabel.Create(Self);
  FStatus.Parent := Self;
  FStatus.StyleElements := [];
  FStatus.Transparent := True;
  FStatus.Font.Assign(Font);
  FStatus.Font.Size := 9;
  FStatus.Font.Color := FDim;
  FStatus.AutoSize := False;
  FStatus.WordWrap := True; // a setup notice takes two or three lines

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
  Lines, LineHeight, TextLeft, TextWidth, StatusHeight, ChipSpace: Integer;
  Area: TRect;
begin
  Canvas.Font.Assign(FMemo.Font);
  LineHeight := Canvas.TextHeight('Ag');
  Lines := EnsureRange(SendMessage(FMemo.Handle, EM_GETLINECOUNT, 0, 0), 1, MaxLines);
  StatusHeight := 0;
  if FStatus.Caption <> '' then
  begin
    Canvas.Font.Assign(FStatus.Font);
    Area := Rect(0, 0, ClientWidth - Scaled(LinePad + IconSize + 12) - Scaled(LinePad), 0);
    DrawText(Canvas.Handle, PChar(FStatus.Caption), -1, Area, DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX);
    StatusHeight := Max(Scaled(16), Area.Height) + Scaled(2);
    Canvas.Font.Assign(FMemo.Font);
  end;
  ChipSpace := 0;
  if HasImage then
    ChipSpace := Scaled(ChipHeight + 8);
  ClientHeight := Scaled(LinePad) * 2 + LineHeight * Lines + ChipSpace + StatusHeight;
  TextLeft := Scaled(LinePad + IconSize + 12);
  // Capture on the right of the first line, the text to its left
  FCapture.Left := ClientWidth - Scaled(LinePad) - FCapture.Width;
  FCapture.Top := Scaled(LinePad) + (LineHeight - FCapture.Height) div 2;
  TextWidth := FCapture.Left - Scaled(12) - TextLeft;
  FChip.Visible := HasImage;
  FChip.SetBounds(TextLeft, Scaled(LinePad) + LineHeight * Lines + Scaled(8), ClientWidth - TextLeft - Scaled(LinePad),
    Scaled(ChipHeight));
  FIcon.SetBounds(Scaled(LinePad), Scaled(LinePad) + (LineHeight - Scaled(IconSize)) div 2, Scaled(IconSize),
    Scaled(IconSize));
  FMemo.SetBounds(TextLeft, Scaled(LinePad), TextWidth, LineHeight * Lines);
  // No scroll bar (it would not follow the IDE theme): the memo scrolls to the caret by itself
  FStatus.SetBounds(TextLeft, Scaled(LinePad) + LineHeight * Lines + ChipSpace + Scaled(2),
    ClientWidth - TextLeft - Scaled(LinePad), Max(Scaled(16), StatusHeight));
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
  DragAcceptFiles(Handle, True);
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
  if not FBusy then
    ShowNotice; // typing clears an error, a setup notice stays
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
      if ssCtrl in Shift then
      begin
        Key := 0;
        if not FBusy and Assigned(FOnApplyAnyway) then
          FOnApplyAnyway(Self);
      end
      else if not (ssShift in Shift) then
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

procedure TXamlPromptBox.MemoKeyPress(Sender: TObject; var Key: Char);
begin
  // The line break of Enter (it sends) and Ctrl+Enter (apply anyway): only Shift+Enter adds a line.
  // Typed after an error, it cleared the error before it could be read.
  if (Key = #10) or ((Key = #13) and (GetKeyState(VK_SHIFT) >= 0)) then
    Key := #0;
end;

procedure TXamlPromptBox.SetNotice(const AText: string);
begin
  FNotice := AText;
  if not FBusy then
  begin
    ShowNotice;
    Arrange;
  end;
end;

procedure TXamlPromptBox.ShowNotice;
begin
  FStatus.Font.Color := Blend(RGB(232, 168, 56), Font.Color, 75);
  FStatus.Caption := FNotice;
end;

procedure TXamlPromptBox.SetBusy(ABusy: Boolean; const AStatus: string);
begin
  FBusy := ABusy;
  FMemo.ReadOnly := ABusy;
  FCapture.Enabled := not ABusy;
  FTimer.Enabled := ABusy;
  FStatus.Font.Color := FDim;
  FBusyText := AStatus;
  FStatus.Caption := AStatus;
  if ABusy then
    Spin(nil)
  else if AStatus = '' then
    ShowNotice;
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
var
  Process: DWORD;
begin
  // A click elsewhere in the IDE closes the bar, unless it is waiting for the answer. Another
  // app keeps it open: the user may be fetching an image there to paste or drop.
  Process := 0;
  GetWindowThreadProcessId(GetForegroundWindow, Process);
  if (Process <> 0) and (Process <> GetCurrentProcessId) then
    Exit;
  if not FBusy and Assigned(FOnCancel) then
    FOnCancel(Self);
end;

destructor TXamlPromptBox.Destroy;
begin
  FreeAndNil(FThumb);
  inherited;
end;

function TXamlPromptBox.HasImage: Boolean;
begin
  Result := Length(FImage) > 0;
end;

procedure TXamlPromptBox.SetImage(const AData: TBytes; const AMimeType: string);
var
  Stream: TBytesStream;
begin
  FreeAndNil(FThumb);
  FImage := AData;
  FImageMime := AMimeType;
  if HasImage then
  begin
    Stream := TBytesStream.Create(Copy(AData));
    FThumb := TGPBitmap.Create(TStreamAdapter.Create(Stream, soOwned) as IStream);
  end;
  if not FBusy then
    ShowNotice;
  Arrange;
  FChip.Invalidate;
end;

procedure TXamlPromptBox.ClearImage;
begin
  SetImage(nil, '');
end;

procedure TXamlPromptBox.LoadImageFile(const AFile: string);
var
  Data: TBytes;
  Mime: string;
begin
  Data := nil;
  if MatchText(ExtractFileExt(AFile), ImageFiles) then
    Data := VisionImageFromFile(AFile, Mime);
  if Data = nil then
    ShowError('That file is not an image the bar can read (PNG, JPEG, BMP or GIF).')
  else
    SetImage(Data, Mime);
end;

procedure TXamlPromptBox.DropFile(AFile: string);
begin
  if not FBusy then
    LoadImageFile(AFile);
end;

procedure TXamlPromptBox.WMDropFiles(var Message: TWMDropFiles);
var
  Name: string;
begin
  Name := DroppedFile(Message.Drop);
  DragFinish(Message.Drop);
  Message.Result := 0;
  if Name <> '' then
    DropFile(Name);
end;

function TXamlPromptBox.PasteImage: Boolean;
var
  Data: TBytes;
  Mime, Name: string;
  Handle: THandle;
begin
  // Text wins: an app that copies both (a spreadsheet, a web page) pastes its text as before
  Result := not FBusy and not Clipboard.HasFormat(CF_UNICODETEXT) and not Clipboard.HasFormat(CF_TEXT) and
    (Clipboard.HasFormat(CF_BITMAP) or Clipboard.HasFormat(CF_HDROP));
  if not Result then
    Exit;
  Data := nil;
  Name := '';
  Clipboard.Open;
  try
    if Clipboard.HasFormat(CF_BITMAP) then
      Data := VisionImageFromBitmap(GetClipboardData(CF_BITMAP), Mime)
    else
    begin
      Handle := GetClipboardData(CF_HDROP);
      if Handle <> 0 then
        Name := DroppedFile(HDROP(Handle)); // a file copied in Explorer
    end;
  finally
    Clipboard.Close;
  end;
  if Name <> '' then
    LoadImageFile(Name)
  else if Data = nil then
    ShowError('The image on the clipboard could not be read.')
  else
    SetImage(Data, Mime);
end;

procedure TXamlPromptBox.CaptureClick(Sender: TObject);
begin
  if not FBusy and Assigned(FOnCapture) then
    FOnCapture(Self);
end;

procedure TXamlPromptBox.PaintChip(Sender: TObject);
var
  Box: TPaintBox;
  G: TGPGraphics;
  Thumb, Badge: TRect;
  Scale: Double;
  Pen: TGPPen;
  Fill: TGPSolidBrush;
  C: TColor;
  M: Integer;
begin
  Box := Sender as TPaintBox;
  Box.Canvas.Brush.Color := Color;
  Box.Canvas.FillRect(Box.ClientRect);
  if FThumb = nil then
    Exit;
  // The thumbnail at the chip's height, at most four times as wide
  Scale := Min(Box.Height / Max(1, FThumb.GetHeight), Box.Height * 4 / Max(1, FThumb.GetWidth));
  Thumb := Rect(0, 0, Max(8, Round(FThumb.GetWidth * Scale)), Max(8, Round(FThumb.GetHeight * Scale)));
  Thumb.Offset(0, (Box.Height - Thumb.Height) div 2);
  G := TGPGraphics.Create(Box.Canvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    G.SetInterpolationMode(InterpolationModeHighQualityBicubic);
    G.DrawImage(FThumb, Thumb.Left, Thumb.Top, Thumb.Width, Thumb.Height);
    C := ColorToRGB(FBorder);
    Pen := TGPPen.Create(MakeColor(255, GetRValue(C), GetGValue(C), GetBValue(C)), 1);
    try
      G.DrawRectangle(Pen, Thumb.Left, Thumb.Top, Thumb.Width - 1, Thumb.Height - 1);
    finally
      Pen.Free;
    end;
    // The x that removes it, on the top right corner
    M := Scaled(18);
    Badge := Rect(Thumb.Right - M - Scaled(3), Thumb.Top + Scaled(3), Thumb.Right - Scaled(3),
      Thumb.Top + Scaled(3) + M);
    FRemoveRect := Badge;
    Fill := TGPSolidBrush.Create(MakeColor(200, 32, 32, 32));
    Pen := TGPPen.Create(MakeColor(255, 255, 255, 255), Scaled(2) * 0.8);
    try
      G.FillEllipse(Fill, Badge.Left, Badge.Top, M, M);
      G.DrawLine(Pen, Badge.Left + M * 0.32, Badge.Top + M * 0.32, Badge.Left + M * 0.68, Badge.Top + M * 0.68);
      G.DrawLine(Pen, Badge.Left + M * 0.68, Badge.Top + M * 0.32, Badge.Left + M * 0.32, Badge.Top + M * 0.68);
    finally
      Pen.Free;
      Fill.Free;
    end;
  finally
    G.Free;
  end;
  Box.Canvas.Font.Assign(FStatus.Font);
  Box.Canvas.Font.Color := FDim;
  Box.Canvas.Brush.Style := bsClear;
  Box.Canvas.TextOut(Thumb.Right + Scaled(10), (Box.Height - Box.Canvas.TextHeight('Ag')) div 2,
    Format('Image, %d x %d, goes with the prompt', [FThumb.GetWidth, FThumb.GetHeight]));
end;

procedure TXamlPromptBox.ChipMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) and not FBusy and FRemoveRect.Contains(Point(X, Y)) then
  begin
    ClearImage;
    if FMemo.CanFocus then
      FMemo.SetFocus;
  end;
end;

initialization

finalization
  FreeAndNil(History);

end.
