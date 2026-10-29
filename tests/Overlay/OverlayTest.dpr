program OverlayTest;

{
  Checks the overlay window mode: WindowStyle="Overlay", Backdrop="Transparent",
  Dock, ClickThrough="Background" and ShowActivated="False" from XAML. The
  window opens where RADWINUI_TEST_MONITOR puts test windows. On a real
  monitor it also compares screen pixels with the window hidden and shown:
  the desktop must show through outside the red pill, and clicks must pass
  through there.
}

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.SysUtils,
  RADWinUI.Abi,
  RADWinUI.Forms,
  RADWinUI.Xaml,
  OverlayWindow.Xaml in 'OverlayWindow.Xaml.pas',
  OverlayWindow in 'OverlayWindow.pas';

type
  TOverlayTestWindow = class(TOverlayWindow)
  private
    FTimer: TWinUITimer;
    FStep: Integer;
    FFailures: Integer;
    FForeground: HWND;
    FBehind: array[0..1] of COLORREF;
    procedure Check(AOk: Boolean; const AWhat: string);
    procedure Step(Sender: TObject);
    function Probe(AIndex: Integer): TPoint;
    function OnScreen: Boolean;
    procedure CheckDockMath;
  public
    constructor Create; override;
    destructor Destroy; override;
    class procedure Failed(Sender: TObject; E: Exception);
  end;

class procedure TOverlayTestWindow.Failed(Sender: TObject; E: Exception);
begin
  Writeln('  [failed] ', E.ClassName, ': ', E.Message);
  Flush(Output);
  ExitProcess(1);
end;

constructor TOverlayTestWindow.Create;
begin
  inherited;
  FForeground := GetForegroundWindow;
  FTimer := TWinUITimer.Create;
  FTimer.Interval := 400;
  FTimer.OnTimer := Step;
  FTimer.Enabled := True;
end;

destructor TOverlayTestWindow.Destroy;
begin
  FTimer.Free;
  inherited;
end;

procedure TOverlayTestWindow.Check(AOk: Boolean; const AWhat: string);
begin
  if AOk then
    Writeln('  [ok] ', AWhat)
  else
  begin
    Writeln('  [failed] ', AWhat);
    Inc(FFailures);
  end;
end;

function TOverlayTestWindow.OnScreen: Boolean;
begin
  Result := not SameText(GetEnvironmentVariable('RADWINUI_TEST_MONITOR'), 'offscreen');
end;

// Screen points: 0 is outside the pill (transparent), 1 is the pill's centre
function TOverlayTestWindow.Probe(AIndex: Integer): TPoint;
var
  Bounds: TRect;
  S: Double;
begin
  GetWindowRect(HWND(AppWindow.Id.Value), Bounds);
  S := GetDpiForWindow(HWND(AppWindow.Id.Value)) / 96;
  if AIndex = 0 then
    Result := TPoint.Create(Bounds.Left + Round(20 * S), Bounds.Top + Round(150 * S))
  else
    Result := TPoint.Create(Bounds.Left + Round(200 * S), Bounds.Top + Round(30 * S));
end;

function ScreenPixel(const APoint: TPoint): COLORREF;
var
  DC: HDC;
begin
  DC := GetDC(0);
  try
    Result := GetPixel(DC, APoint.X, APoint.Y);
  finally
    ReleaseDC(0, DC);
  end;
end;

// For a look at the result: the window and 40 pixels around it, as a .bmp in %TEMP%\RADWinUI
procedure SaveScreen(AWnd: HWND);
var
  Bounds: TRect;
  Screen, Mem: HDC;
  Bitmap: HBITMAP;
  Info: TBitmapInfo;
  Header: TBitmapFileHeader;
  Pixels: TBytes;
  Path: string;
  F: THandle;
  Written: DWORD;
begin
  GetWindowRect(AWnd, Bounds);
  InflateRect(Bounds, 40, 40);
  Screen := GetDC(0);
  Mem := CreateCompatibleDC(Screen);
  Bitmap := CreateCompatibleBitmap(Screen, Bounds.Width, Bounds.Height);
  SelectObject(Mem, Bitmap);
  BitBlt(Mem, 0, 0, Bounds.Width, Bounds.Height, Screen, Bounds.Left, Bounds.Top, SRCCOPY);
  FillChar(Info, SizeOf(Info), 0);
  Info.bmiHeader.biSize := SizeOf(Info.bmiHeader);
  Info.bmiHeader.biWidth := Bounds.Width;
  Info.bmiHeader.biHeight := Bounds.Height;
  Info.bmiHeader.biPlanes := 1;
  Info.bmiHeader.biBitCount := 32;
  SetLength(Pixels, Bounds.Width * Bounds.Height * 4);
  GetDIBits(Mem, Bitmap, 0, Bounds.Height, Pixels, Info, DIB_RGB_COLORS);
  DeleteDC(Mem);
  ReleaseDC(0, Screen);
  DeleteObject(Bitmap);
  FillChar(Header, SizeOf(Header), 0);
  Header.bfType := $4D42;
  Header.bfOffBits := SizeOf(Header) + SizeOf(Info.bmiHeader);
  Header.bfSize := Header.bfOffBits + Cardinal(Length(Pixels));
  Path := GetEnvironmentVariable('TEMP') + '\RADWinUI';
  ForceDirectories(Path);
  Path := Path + '\overlay-test.bmp';
  F := CreateFile(PChar(Path), GENERIC_WRITE, 0, nil, CREATE_ALWAYS, 0, 0);
  WriteFile(F, Header, SizeOf(Header), Written, nil);
  WriteFile(F, Info.bmiHeader, SizeOf(Info.bmiHeader), Written, nil);
  WriteFile(F, Pixels[0], Length(Pixels), Written, nil);
  CloseHandle(F);
  Writeln('  screen saved to ', Path);
end;

function SameRect(const AActual: TRect; ALeft, ATop, ARight, ABottom: Integer): Boolean;
begin
  // one pixel of rounding at fractional scales
  Result := (Abs(AActual.Left - ALeft) <= 1) and (Abs(AActual.Top - ATop) <= 1) and
    (Abs(AActual.Right - ARight) <= 1) and (Abs(AActual.Bottom - ABottom) <= 1);
end;

procedure TOverlayTestWindow.CheckDockMath;
var
  Outer, Work: RectInt32;
  Size: SizeInt32;
  P: PointInt32;
begin
  Outer.X := 0; Outer.Y := 0; Outer.Width := 1920; Outer.Height := 1080;
  Work := Outer;
  Work.Height := 1032; // taskbar at the bottom
  Size.Width := 400;
  Size.Height := 200;
  P := DockPosition(TWinUIDock.TopCenter, Outer, Work, Size);
  Check((P.X = 760) and (P.Y = 0), 'Dock TopCenter: centred on the top edge of the screen');
  P := DockPosition(TWinUIDock.TopRight, Outer, Work, Size);
  Check((P.X = 1520) and (P.Y = 0), 'Dock TopRight');
  P := DockPosition(TWinUIDock.BottomCenter, Outer, Work, Size);
  Check((P.X = 760) and (P.Y = 832), 'Dock BottomCenter: above the taskbar');
  Outer.X := -2560; Outer.Width := 2560; Outer.Height := 1440;
  P := DockPosition(TWinUIDock.TopLeft, Outer, Outer, Size);
  Check((P.X = -2560) and (P.Y = 0), 'Dock TopLeft on a display left of the primary one');
end;

procedure TOverlayTestWindow.Step(Sender: TObject);
var
  Wnd, Hit: HWND;
  Rgn: HRGN;
  Box: TRect;
  S: Double;
  Pixel: COLORREF;
begin
  Inc(FStep);
  try
    Wnd := HWND(AppWindow.Id.Value);
    case FStep of
      1:
        begin
          Writeln('Overlay window');
          S := GetDpiForWindow(Wnd) / 96;
          Check(GetWindowLong(Wnd, GWL_STYLE) and WS_CAPTION = 0,
            Format('Overlay: no title bar or border (style %.8x)', [GetWindowLong(Wnd, GWL_STYLE)]));
          Check(GetWindowLong(Wnd, GWL_EXSTYLE) and WS_EX_TOPMOST <> 0, 'Overlay: always on top');
          Check(not AppWindow.IsShownInSwitchers, 'Overlay: not in the taskbar or Alt+Tab');
          Check(GetWindowLong(Wnd, GWL_EXSTYLE) and WS_EX_NOACTIVATE <> 0, 'ShowActivated False: WS_EX_NOACTIVATE');
          Check(GetForegroundWindow <> Wnd, 'Show did not take the foreground');
          Rgn := CreateRectRgn(0, 0, 0, 0);
          try
            Check(GetWindowRgn(Wnd, Rgn) = SIMPLEREGION, 'ClickThrough: the window has a region');
            GetRgnBox(Rgn, Box);
          finally
            DeleteObject(Rgn);
          end;
          Check(SameRect(Box, Round(100 * S), 0, Round(300 * S), Round(60 * S)),
            Format('ClickThrough: the region is the pill (%d,%d,%d,%d)', [Box.Left, Box.Top, Box.Right, Box.Bottom]));
          CheckDockMath;
          if OnScreen then
            AppWindow.Hide;
        end;
      2:
        if OnScreen then
        begin
          Check(not IsWindowVisible(Wnd), 'hidden to read the desktop behind it');
          FBehind[0] := ScreenPixel(Probe(0));
          FBehind[1] := ScreenPixel(Probe(1));
          AppWindow.Show(False);
        end;
      3:
        ; // the compositor needs a moment to draw the shown window
      4:
        begin
          if OnScreen then
          begin
            Check(IsWindowVisible(Wnd), 'shown again');
            SaveScreen(Wnd);
            Pixel := ScreenPixel(Probe(0));
            Check(Pixel = FBehind[0], Format('Transparent: the desktop shows outside the pill (%.6x, behind %.6x)',
              [Pixel, FBehind[0]]));
            Pixel := ScreenPixel(Probe(1));
            Check(Pixel = RGB(255, 0, 0), Format('Transparent: the pill is drawn (%.6x)', [Pixel]));
            Hit := WindowFromPoint(Probe(0));
            Check(GetAncestor(Hit, GA_ROOT) <> Wnd, 'ClickThrough: a click outside the pill goes to the window below');
            Hit := WindowFromPoint(Probe(1));
            Check(GetAncestor(Hit, GA_ROOT) = Wnd, 'ClickThrough: a click on the pill reaches the window');
          end
          else
            Writeln('  [skipped] screen pixels and click-through (RADWINUI_TEST_MONITOR=offscreen)');
          ClickThrough := TWinUIClickThrough.None;
          Rgn := CreateRectRgn(0, 0, 0, 0);
          try
            Check(GetWindowRgn(Wnd, Rgn) = ERROR, 'ClickThrough None: the region is gone');
          finally
            DeleteObject(Rgn);
          end;
          WindowStyle := TWinUIWindowStyle.Normal;
          Check(GetWindowLong(Wnd, GWL_STYLE) and WS_CAPTION <> 0, 'Normal again: title bar back');
          Check(AppWindow.IsShownInSwitchers, 'Normal again: in the taskbar');
          Flush(Output);
          if FFailures > 0 then
            ExitProcess(1);
          ExitProcess(0);
        end;
    end;
  except
    on E: Exception do
      Failed(Self, E);
  end;
end;

begin
  if GetEnvironmentVariable('RADWINUI_TEST_MONITOR') = '' then
    SetEnvironmentVariable('RADWINUI_TEST_MONITOR', 'secondary');
  TWinUIApp.OnException := TOverlayTestWindow.Failed;
  TWinUIApp.Run(TOverlayTestWindow);
end.
