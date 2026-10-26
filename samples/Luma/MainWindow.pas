unit MainWindow;

interface

uses
  RADWinUI.Forms,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  MainViewModel,
  MainWindow.Xaml;

type
  TMainWindow = class(TMainWindowBase)
  private
    FTimer: TWinUITimer;
    FSmokeStep: Integer;
    procedure Tick(Sender: TObject);
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Show; override;
  published
    procedure FocusClick(Sender: TObject);
    procedure ResetClick(Sender: TObject);
    procedure ThemeChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
    procedure PinClick(Sender: TObject);
  end;

implementation

uses
  Winapi.Windows,
  Winapi.MultiMon,
  System.Math,
  System.SysUtils,
  System.IOUtils;

constructor TMainWindow.Create;
begin
  inherited;
  ViewModel := TMainViewModel.Create;
  SetTitleBar(DragRegion);
  AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.UseDefaultAppMode;
  BindTransparencySwitch(TransparencySwitch);
  with AppWindow.Presenter as TWinUIOverlappedPresenter do
    IsMaximizable := False;
  FTimer := TWinUITimer.Create;
  FTimer.Interval := 1000;
  FTimer.OnTimer := Tick;
  FTimer.Enabled := True;
end;

destructor TMainWindow.Destroy;
begin
  FTimer.Free;
  ViewModel.Free;
  inherited;
end;

procedure TMainWindow.Show;
var
  Info: TMonitorInfo;
  Bounds: TRect;
  Handle: HWND;
begin
  inherited;
  // The framework owns secondary-monitor placement in test mode.
  if GetEnvironmentVariable('RADWINUI_TEST_MONITOR') <> '' then Exit;
  Handle := HWND(AppWindow.Id.Value);
  Info.cbSize := SizeOf(Info);
  if GetMonitorInfo(MonitorFromWindow(Handle, MONITOR_DEFAULTTONEAREST), @Info) and GetWindowRect(Handle, Bounds) then
    SetWindowPos(Handle, 0, Info.rcWork.Right - (Bounds.Right - Bounds.Left) - 20,
      Info.rcWork.Top + 20, Bounds.Right - Bounds.Left,
      Min(Bounds.Bottom - Bounds.Top, Info.rcWork.Bottom - Info.rcWork.Top - 40),
      SWP_NOZORDER or SWP_NOACTIVATE);
end;

procedure TMainWindow.FocusClick(Sender: TObject);
begin
  ViewModel.ToggleFocus;
end;

procedure TMainWindow.ResetClick(Sender: TObject);
begin
  ViewModel.ResetFocus;
end;

procedure TMainWindow.ThemeChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
begin
  case ThemeChoice.SelectedIndex of
    1:
      begin
        Surface.RequestedTheme := TWinUIElementTheme.Light;
        AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.Light;
      end;
    2:
      begin
        Surface.RequestedTheme := TWinUIElementTheme.Dark;
        AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.Dark;
      end;
  else
    Surface.RequestedTheme := TWinUIElementTheme.Default;
    AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.UseDefaultAppMode;
  end;
end;

procedure TMainWindow.PinClick(Sender: TObject);
begin
  (AppWindow.Presenter as TWinUIOverlappedPresenter).IsAlwaysOnTop := not
    (AppWindow.Presenter as TWinUIOverlappedPresenter).IsAlwaysOnTop;
end;

procedure TMainWindow.Tick(Sender: TObject);
begin
  ViewModel.Refresh;
  if not FindCmdLineSwitch('smoke-test') then Exit;
  Inc(FSmokeStep);
  try
    case FSmokeStep of
      1:
        begin
          Surface.RequestedTheme := TWinUIElementTheme.Dark;
          FocusClick(nil);
        end;
      4:
        begin
          if (Surface.ActualTheme <> TWinUIElementTheme.Dark) or not ViewModel.Running or
            (FocusButton.Content.AsString <> 'Pause focus') or (ViewModel.FocusProgress <= 0) then
            raise Exception.Create('Dark theme or focus binding failed');
          if not Transparency or (SystemBackdrop = nil) or not TransparencySwitch.IsOn then
            raise Exception.Create('Transparency is not on at start');
          Surface.RequestedTheme := TWinUIElementTheme.Light;
          ResetClick(nil);
          TransparencySwitch.IsOn := False; // the window turns opaque
        end;
      8:
        begin
          if (Surface.ActualTheme <> TWinUIElementTheme.Light) or ViewModel.Running or
            (ClockLabel.Text <> ViewModel.ClockText) or (ViewModel.MemoryText = '--') or
            (FocusButton.Content.AsString <> 'Start focus') or (LumaGlyph.Glyph <> #$E8A9) or
            (PowerGlyph.Glyph <> #$E83E) or (MemoryGlyph.Glyph <> #$E950) or (PinGlyph.Glyph <> #$E718) then
            raise Exception.Create('Light theme, clock, reset binding or Unicode glyph failed');
          if Transparency or (SystemBackdrop <> nil) or not (Surface.Background is TWinUISolidColorBrush) or
            (TWinUISolidColorBrush(Surface.Background).Color.R <> $F3) then
            raise Exception.Create('Turning transparency off did not give a solid light background');
          TransparencySwitch.IsOn := True;
        end;
      10:
        begin
          if not Transparency or (SystemBackdrop = nil) or (Surface.Background is TWinUISolidColorBrush) and
            (TWinUISolidColorBrush(Surface.Background).Color.A = $FF) then
            raise Exception.Create('Turning transparency back on did not restore the Acrylic backdrop');
          TFile.WriteAllText(ParamStr(2), 'PASS: Acrylic window, Unicode glyphs, clock/date, system readings, focus binding, ' +
            'dark/light themes, transparency switch');
          Close;
        end;
    end;
  except
    on E: Exception do
    begin
      TFile.WriteAllText(ParamStr(2), 'FAIL: ' + E.Message);
      Close;
    end;
  end;
end;

end.
