program WindowsTest;

{
  Checks the window API of RADWinUI.Forms: several windows at once, Close with
  OnCloseQuery and OnClose (Hide, Free, None), an owned tool window, a modal
  window that disables its owner and reports ModalResult, ShutdownMode, the
  placement round trip through text and the registry, the presenter switches,
  and title bar passthrough regions. A second copy of the test runs with
  ShutdownMode MainWindow. Windows open where RADWINUI_TEST_MONITOR puts test
  windows, never take the focus, and nothing goes full screen.
}

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.SysUtils,
  System.UITypes,
  RADWinUI.Interop.Core,
  RADWinUI.Abi,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Forms;

var
  Failures: Integer;
  Log: TArray<string>;

procedure Check(AOk: Boolean; const AWhat: string);
begin
  if AOk then
    Writeln('  [ok] ', AWhat)
  else
  begin
    Writeln('  [failed] ', AWhat);
    Inc(Failures);
  end;
  Flush(Output);
end;

function Alive(AWindow: TWinUIWindow): Boolean;
var
  W: TWinUIWindow;
begin
  for W in TWinUIApp.Windows do
    if W = AWindow then
      Exit(True);
  Result := False;
end;

procedure CoTaskMemFree(APtr: Pointer); stdcall; external 'ole32.dll';
function RegDeleteTree(AKey: HKEY; ASubKey: PChar): Longint; stdcall; external advapi32 name 'RegDeleteTreeW';

type
  TPlainWindow = class(TWinUIWindow)
  public
    NextAction: TWinUICloseAction;
    Refuse: Boolean;
    constructor Create; override;
    procedure DoClose(Sender: TObject; var Action: TWinUICloseAction);
    procedure DoCloseQuery(Sender: TObject; var CanClose: Boolean);
  end;

  TMainTestWindow = class(TWinUIWindow)
  private
    FTimer: TWinUITimer;
    FStep: Integer;
    FTool, FDialog, FHidden, FOther: TPlainWindow;
    procedure Step(Sender: TObject);
  public
    constructor Create; override;
    destructor Destroy; override;
    class procedure Failed(Sender: TObject; E: Exception);
  end;

constructor TPlainWindow.Create;
begin
  inherited;
  Width := 320;
  Height := 200;
  ShowActivated := False;
  NextAction := TWinUICloseAction.Free;
  LoadContent('<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"><Grid.RowDefinitions><RowDefinition Height="40"/>' +
    '<RowDefinition/></Grid.RowDefinitions><Grid x:Name="Bar"><TextBox x:Name="Search" Width="120" ' +
    'HorizontalAlignment="Center"/></Grid></Grid>');
  OnClose := DoClose;
  OnCloseQuery := DoCloseQuery;
end;

procedure TPlainWindow.DoClose(Sender: TObject; var Action: TWinUICloseAction);
begin
  Action := NextAction;
  Log := Log + [Title + ':close'];
end;

procedure TPlainWindow.DoCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not Refuse;
end;

type
  // Run by the main test once LastWindow kept the app alive: closes the last window
  TCloser = class
    class procedure Tick(Sender: TObject);
  end;

var
  CloserTimer: TWinUITimer;
  MainModeOther: TPlainWindow;

class procedure TMainTestWindow.Failed(Sender: TObject; E: Exception);
begin
  Writeln('  [failed] ', E.ClassName, ': ', E.Message);
  Flush(Output);
  ExitProcess(1);
end;

constructor TMainTestWindow.Create;
begin
  inherited;
  Title := 'WindowsTest';
  Width := 480;
  Height := 320;
  ShowActivated := False;
  LoadContent('<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"/>');
  FTimer := TWinUITimer.Create;
  FTimer.Interval := 250;
  FTimer.OnTimer := Step;
  FTimer.Enabled := True;
end;

destructor TMainTestWindow.Destroy;
begin
  FTimer.Free;
  inherited;
end;

function PassthroughCount(AWindow: TWinUIWindow; out AFirst: RectInt32): Integer;
var
  Count: Cardinal;
  Rects: Pointer;
begin
  InputNonClientPointerSource.GetForWindowId(AWindow.AppWindow.Id).GetRegionRects(NonClientRegionKind.Passthrough,
    Count, Rects);
  Result := Count;
  if Count > 0 then
    AFirst := PRectInt32(Rects)^;
  CoTaskMemFree(Rects);
end;

procedure TMainTestWindow.Step(Sender: TObject);
var
  First: RectInt32;
  Hidden: TPlainWindow;
begin
  Inc(FStep);
  case FStep of
    1:
      begin
        Check(TWinUIApp.MainWindow = Self, 'TWinUIApp.MainWindow is the window Run created');
        FTool := TPlainWindow.Create;
        FTool.Title := 'Tool';
        FTool.OwnerWindow := Self;
        FTool.Show;
        Check(TWinUIApp.WindowCount = 2, 'a second window opens next to the main window');
        Check(HWND(GetWindowLongPtr(HWND(FTool.AppWindow.Id.Value), GWLP_HWNDPARENT)) = HWND(AppWindow.Id.Value),
          'OwnerWindow makes Windows keep the tool window above its owner');
      end;
    2:
      begin
        FTool.NextAction := TWinUICloseAction.Hide;
        FTool.Close;
        Check(Alive(FTool) and not FTool.AppWindow.IsVisible, 'OnClose Hide hides the window and keeps it');
        FTool.Show;
        FTool.Refuse := True;
        FTool.Close;
        Check(Alive(FTool) and FTool.AppWindow.IsVisible, 'OnCloseQuery keeps the window open');
        FTool.Refuse := False;
        FTool.NextAction := TWinUICloseAction.None;
        FTool.Close;
        Check(FTool.AppWindow.IsVisible, 'OnClose None keeps the window open');
        FTool.NextAction := TWinUICloseAction.Free;
        FTool.Close;
      end;
    3:
      begin
        Check(not Alive(FTool) and (TWinUIApp.WindowCount = 1), 'OnClose Free closes and frees the window');
        FTool := nil;
        FDialog := TPlainWindow.Create;
        FDialog.Title := 'Dialog';
        FDialog.ShowModal(
          procedure(AResult: TModalResult)
          begin
            Log := Log + ['modal:' + IntToStr(AResult)];
          end);
        Check(FDialog.OwnerWindow = Self, 'a modal window without an owner belongs to the window in use');
        Check(not IsWindowEnabled(HWND(AppWindow.Id.Value)), 'the owner is disabled while the modal window is open');
        FDialog.ModalResult := mrOk;
        Check(IsWindowEnabled(HWND(AppWindow.Id.Value)), 'the owner is enabled again when the modal window closes');
        Check((Length(Log) > 0) and (Log[High(Log)] = 'modal:' + IntToStr(mrOk)),
          'setting ModalResult closes the modal window and reports the result');
      end;
    4:
      begin
        Check(not Alive(FDialog), 'the modal window is freed after it closed');
        FDialog := TPlainWindow.Create;
        FDialog.Title := 'Dialog2';
        FDialog.ShowModal(
          procedure(AResult: TModalResult)
          begin
            Log := Log + ['modal2:' + IntToStr(AResult)];
          end);
        FDialog.Close;
        Check(Log[High(Log)] = 'modal2:' + IntToStr(mrCancel), 'closing a modal window without a result gives mrCancel');
        // Placement on a window that is never shown, so nothing comes on the screen
        Hidden := TPlainWindow.Create;
        FHidden := Hidden;
        Hidden.Placement := 'Normal,100,120,700,520';
        Check(Hidden.Placement = 'Normal,100,120,700,520', 'Placement round trip: ' + Hidden.Placement);
        Hidden.WindowState := TWinUIWindowState.Maximized;
        Check(not Hidden.AppWindow.IsVisible and Hidden.Placement.StartsWith('Maximized,'),
          'Maximized before Show waits for Show and is part of the placement');
        Hidden.SavePlacement('WindowsTestHidden');
        Hidden.Placement := 'Normal,50,60,450,360';
        Check(Hidden.RestorePlacement('WindowsTestHidden') and (Hidden.Placement = 'Maximized,100,120,700,520'),
          'SavePlacement and RestorePlacement through the registry');
        RegDeleteTree(HKEY_CURRENT_USER, PChar('Software\WindowsTest'));
        Hidden.Resizable := False;
        Hidden.Maximizable := False;
        Hidden.Minimizable := False;
        Hidden.MaxWidth := 800;
        Check(not Hidden.Resizable and not Hidden.Maximizable and not Hidden.Minimizable and (Hidden.MaxWidth = 800),
          'Resizable, Minimizable, Maximizable and MaxWidth');
        // Full screen and the compact overlay (Tempo's mini player), on the window that is never
        // shown: the presenter changes, nothing comes on the screen, and back to Normal the
        // window's own settings are still there
        Hidden.WindowState := TWinUIWindowState.FullScreen;
        Check((Hidden.AppWindow.Presenter.Kind = TWinUIAppWindowPresenterKind.FullScreen) and
          (Hidden.WindowState = TWinUIWindowState.FullScreen) and not Hidden.AppWindow.IsVisible,
          'WindowState FullScreen uses the full screen presenter');
        Hidden.WindowState := TWinUIWindowState.CompactOverlay;
        Check((Hidden.AppWindow.Presenter.Kind = TWinUIAppWindowPresenterKind.CompactOverlay) and
          (Hidden.WindowState = TWinUIWindowState.CompactOverlay) and not Hidden.AppWindow.IsVisible,
          'WindowState CompactOverlay uses the compact overlay presenter, as Tempo''s mini player');
        Hidden.WindowState := TWinUIWindowState.Normal;
        Check((Hidden.AppWindow.Presenter.Kind = TWinUIAppWindowPresenterKind.Overlapped) and not Hidden.Resizable and
          not Hidden.AppWindow.IsVisible, 'back to Normal: the overlapped presenter with its settings, still hidden');
      end;
    5:
      begin
        // Title bar of its own: the search box takes clicks, the rest drags the window
        FOther := TPlainWindow.Create;
        FOther.Title := 'Other';
        FOther.UseTitleBar(FOther.FindElement<TWinUIFrameworkElement>('Bar'));
        FOther.Show;
        FOther.SetTitleBarPassthrough([FOther.FindElement<TWinUIFrameworkElement>('Search')]);
        Check(FOther.ExtendsContentIntoTitleBar, 'UseTitleBar extends the content into the title bar');
      end;
    6:
      begin
        Check((PassthroughCount(FOther, First) = 1) and (First.Width > 0) and (First.Height > 0),
          'SetTitleBarPassthrough gives the search box a passthrough region');
        FOther.SetTitleBarPassthrough([]);
        Check(PassthroughCount(FOther, First) = 0, 'an empty list removes it');
        Check(FOther.WindowState = TWinUIWindowState.Normal, 'WindowState of a normal window');
        FHidden.Free; // never shown: freed by the caller like any object
        FHidden := nil;
        // LastWindow: closing the main window leaves the other one running
        TWinUIApp.ShutdownMode := TWinUIShutdownMode.LastWindow;
        FTimer.Enabled := False;
        CloserTimer := TWinUITimer.Create;
        CloserTimer.Interval := 800;
        CloserTimer.OnTimer := TCloser.Tick;
        CloserTimer.Enabled := True;
        Close;
      end;
  end;
end;

class procedure TCloser.Tick(Sender: TObject);
var
  W: TWinUIWindow;
begin
  CloserTimer.Enabled := False;
  Check(TWinUIApp.MainWindow = nil, 'the main window is freed after it closed');
  Check(TWinUIApp.WindowCount = 1, 'with ShutdownMode LastWindow the app runs on with its other window');
  for W in TWinUIApp.Windows do
    W.Close;
end;

type
  TMainModeWindow = class(TWinUIWindow)
  private
    FTimer: TWinUITimer;
    procedure Step(Sender: TObject);
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

constructor TMainModeWindow.Create;
begin
  inherited;
  ShowActivated := False;
  LoadContent('<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"/>');
  FTimer := TWinUITimer.Create;
  FTimer.Interval := 300;
  FTimer.OnTimer := Step;
  FTimer.Enabled := True;
end;

destructor TMainModeWindow.Destroy;
begin
  FTimer.Free;
  inherited;
end;

procedure TMainModeWindow.Step(Sender: TObject);
begin
  FTimer.Enabled := False;
  MainModeOther := TPlainWindow.Create;
  MainModeOther.Show;
  // ShutdownMode MainWindow (the default): the app ends with this window, the other one goes too
  Close;
end;

function RunChild(const AArgs: string; ATimeout: Cardinal; out AExitCode: Cardinal): Boolean;
var
  SI: TStartupInfo;
  PI: TProcessInformation;
  CommandLine: string;
begin
  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  CommandLine := '"' + ParamStr(0) + '" ' + AArgs;
  UniqueString(CommandLine);
  AExitCode := Cardinal(-1);
  if not CreateProcess(nil, PChar(CommandLine), nil, nil, False, 0, nil, nil, SI, PI) then
    RaiseLastOSError;
  CloseHandle(PI.hThread);
  Result := WaitForSingleObject(PI.hProcess, ATimeout) = WAIT_OBJECT_0;
  if Result then
    GetExitCodeProcess(PI.hProcess, AExitCode)
  else
    TerminateProcess(PI.hProcess, 1);
  CloseHandle(PI.hProcess);
end;

var
  Code: Cardinal;

begin
  ReportMemoryLeaksOnShutdown := GetEnvironmentVariable('RADWINUI_TEST_MONITOR') = '';
  if ParamStr(1) = '--main-mode' then
  begin
    TWinUIApp.Run(TMainModeWindow);
    Exit;
  end;
  Writeln('WindowsTest');
  TWinUIApp.OnException := TMainTestWindow.Failed;
  try
    TWinUIApp.Run(TMainTestWindow);
  finally
    CloserTimer.Free;
  end;
  Check(TWinUIApp.WindowCount = 0, 'every window is freed when the app ends');
  Check(RunChild('--main-mode', 20000, Code) and (Code = 0),
    'with ShutdownMode MainWindow, closing the main window ends the app while another window is open');
  if Failures = 0 then
    Writeln('PASSED')
  else
    Writeln(Format('FAILED: %d', [Failures]));
  ExitCode := Ord(Failures > 0);
end.
