program AppServicesTest;

{
  Checks RADWinUI.Dialogs, RADWinUI.Notifications and the activation API of
  TWinUIApp: filter parsing, message and input dialogs (closed with Esc, as
  ContentDialog.Hide does), one dialog after the other, TWinUIApp.Queue from
  another thread, and SingleInstance: a second start hands its arguments to
  the first one and ends. The window opens where RADWINUI_TEST_MONITOR puts
  test windows and never takes the focus. No notification is shown.
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
  RADWinUI.Forms,
  RADWinUI.Dialogs,
  RADWinUI.Notifications;

var
  Failures: Integer;

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

procedure CheckFilters;
var
  Names: TArray<string>;
  Exts: TArray<TArray<string>>;
  Activation: TWinUIActivation;
begin
  ParseFilter('Text files (*.txt)|*.txt;*.log|All files (*.*)|*.*', Names, Exts);
  Check((Length(Names) = 2) and (Names[0] = 'Text files (*.txt)') and (Names[1] = 'All files (*.*)'),
    'filter names');
  Check((Length(Exts) = 2) and (Length(Exts[0]) = 2) and (Exts[0][0] = '.txt') and (Exts[0][1] = '.log') and
    (Length(Exts[1]) = 1) and (Exts[1][0] = '*'), 'filter extensions');
  ParseFilter('', Names, Exts);
  Check(Length(Names) = 0, 'empty filter');
  ParseFilter('Images|png;.jpg', Names, Exts);
  Check((Length(Exts) = 1) and (Exts[0][0] = '.png') and (Exts[0][1] = '.jpg'), 'extensions without *.');
  Activation := Default(TWinUIActivation);
  Activation.Inputs := ['reply=Hello', 'Name=Ali=1'];
  Check((Activation.Input('Reply') = 'Hello') and (Activation.Input('name') = 'Ali=1') and
    (Activation.Input('none') = ''), 'notification inputs by id');
end;

{ Single instance: the test starts itself twice with --single }

function LogPath: string;
begin
  Result := GetEnvironmentVariable('TEMP') + '\RADWinUI\appservices-single.log';
end;

procedure AppendLog(const ALine: string);
var
  F: TextFile;
begin
  ForceDirectories(ExtractFileDir(LogPath));
  AssignFile(F, LogPath);
  if FileExists(LogPath) then
    Append(F)
  else
    Rewrite(F);
  Writeln(F, ALine);
  CloseFile(F);
end;

type
  TSingleWindow = class(TWinUIWindow)
  public
    constructor Create; override;
    class procedure Activated(Sender: TObject; const AActivation: TWinUIActivation);
  end;

var
  SingleCount: Integer;

constructor TSingleWindow.Create;
begin
  inherited;
  Title := 'AppServicesTest single instance';
  Width := 360;
  Height := 200;
  ShowActivated := False;
  Content := TWinUITextBlock.Create(Self);
end;

class procedure TSingleWindow.Activated(Sender: TObject; const AActivation: TWinUIActivation);
begin
  Inc(SingleCount);
  AppendLog(Format('%d|%s', [Ord(AActivation.Kind), AActivation.Arguments]));
  // The first call is this process's own launch, the second the redirected start
  if SingleCount >= 2 then
    TWinUIApp.Terminate;
end;

function RunChild(const AArgs: string; AWait: Boolean; ATimeout: Cardinal; out AExitCode: Cardinal): THandle;
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
  Result := PI.hProcess;
  if AWait then
  begin
    if WaitForSingleObject(PI.hProcess, ATimeout) = WAIT_OBJECT_0 then
      GetExitCodeProcess(PI.hProcess, AExitCode);
  end;
end;

function ReadLines(const APath: string): TArray<string>;
var
  F: TextFile;
  Line: string;
begin
  Result := nil;
  if not FileExists(APath) then
    Exit;
  AssignFile(F, APath);
  Reset(F);
  while not Eof(F) do
  begin
    Readln(F, Line);
    Result := Result + [Line];
  end;
  CloseFile(F);
end;

procedure CheckSingleInstance;
var
  First: THandle;
  Code: Cardinal;
  Lines: TArray<string>;
begin
  DeleteFile(LogPath);
  First := RunChild('--single first', False, 0, Code);
  try
    Sleep(3000); // the first instance registers its key and shows its window
    RunChild('--single "second start"', True, 15000, Code);
    Check(Code = 0, 'second start ends by itself');
    Check(WaitForSingleObject(First, 15000) = WAIT_OBJECT_0, 'first instance got the second start and closed');
    Check(GetExitCodeProcess(First, Code) and (Code = 0), 'first instance ended cleanly');
  finally
    TerminateProcess(First, 1);
    CloseHandle(First);
  end;
  Lines := ReadLines(LogPath);
  Check((Length(Lines) = 2) and (Lines[0] = '0|--single first'),
    'first OnActivated is its own launch: ' + string.Join(' / ', Lines));
  Check((Length(Lines) = 2) and (Lines[1] = '0|--single "second start"'),
    'second OnActivated carries the redirected arguments, without the program name');
end;

{ Dialogs, run inside the test window }

type
  TTestWindow = class(TWinUIWindow)
  private
    FTimer: TWinUITimer;
    FStep: Integer;
    FWait: Integer;
    FLog: TArray<string>;
    procedure Step(Sender: TObject);
    function OpenDialog: IContentDialog;
    function HideDialog: Boolean;
    // The open dialog's text, '' when none is open; hides it
    function HideDialogText: string;
  public
    constructor Create; override;
    destructor Destroy; override;
    class procedure Failed(Sender: TObject; E: Exception);
  end;

class procedure TTestWindow.Failed(Sender: TObject; E: Exception);
begin
  Writeln('  [failed] ', E.ClassName, ': ', E.Message);
  Flush(Output);
  ExitProcess(1);
end;

constructor TTestWindow.Create;
var
  Panel: TWinUIStackPanel;
begin
  inherited;
  Title := 'AppServicesTest';
  Width := 640;
  Height := 480;
  ShowActivated := False;
  Panel := TWinUIStackPanel.Create(Self);
  Content := Panel;
  FTimer := TWinUITimer.Create;
  FTimer.Interval := 300;
  FTimer.OnTimer := Step;
  FTimer.Enabled := True;
end;

destructor TTestWindow.Destroy;
begin
  FTimer.Free;
  inherited;
end;

// The ContentDialog open on this window, nil when none is
function TTestWindow.OpenDialog: IContentDialog;
var
  Popups: IVectorView_Popup;
  I: Integer;
begin
  Result := nil;
  Popups := VisualTreeHelper.GetOpenPopupsForXamlRoot(Content.XamlRoot.Intf);
  for I := 0 to Integer(Popups.Size) - 1 do
    if Supports(Popups.GetAt(I).get_Child, IContentDialog, Result) then
      Exit;
end;

function TTestWindow.HideDialog: Boolean;
var
  Dialog: IContentDialog;
begin
  Dialog := OpenDialog;
  Result := Dialog <> nil;
  if Result then
    Dialog.Hide;
end;

function TTestWindow.HideDialogText: string;
var
  Dialog: IContentDialog;
begin
  Result := '';
  Dialog := OpenDialog;
  if Dialog = nil then
    Exit;
  Result := TWinValue((Dialog as IContentControl).Content).AsString;
  Dialog.Hide;
end;

function UIThreadId: Cardinal;
begin
  Result := MainThreadID;
end;

var
  QueuedOnThread: Cardinal;

function QueueFromThread(AParameter: Pointer): Integer;
begin
  TWinUIApp.Queue(
    procedure
    begin
      QueuedOnThread := GetCurrentThreadId;
    end);
  Result := 0;
end;

procedure TTestWindow.Step(Sender: TObject);
var
  ThreadId: TThreadID;
begin
  Inc(FStep);
  case FStep of
    1:
      begin
        ShowMessage('Hello from ShowMessage',
          procedure
          begin
            FLog := FLog + ['message closed'];
          end);
      end;
    3:
      Check(HideDialog, 'ShowMessage opens a ContentDialog');
    5:
      begin
        Check((Length(FLog) = 1) and (FLog[0] = 'message closed'), 'ShowMessage calls back when closed');
        // Two at once: the second waits for the first
        MessageDlg('Delete it?', TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
          procedure(AResult: TModalResult)
          begin
            FLog := FLog + ['yesno=' + IntToStr(AResult)];
          end);
        MessageDlg('Continue?', TMsgDlgType.mtWarning, [TMsgDlgBtn.mbOK, TMsgDlgBtn.mbCancel],
          procedure(AResult: TModalResult)
          begin
            FLog := FLog + ['okcancel=' + IntToStr(AResult)];
          end);
      end;
    7:
      Check(HideDialog, 'first MessageDlg is open');
    9:
      begin
        Check((Length(FLog) = 2) and (FLog[1] = 'yesno=' + IntToStr(mrNo)), 'Esc on Yes/No gives mrNo');
        Check(HideDialog, 'second MessageDlg opens after the first');
      end;
    11:
      begin
        Check((Length(FLog) = 3) and (FLog[2] = 'okcancel=' + IntToStr(mrCancel)), 'Esc on OK/Cancel gives mrCancel');
        try
          MessageDlg('Too many', TMsgDlgType.mtCustom, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo, TMsgDlgBtn.mbOK,
            TMsgDlgBtn.mbCancel], nil);
          Check(False, 'four buttons are refused');
        except
          on E: EArgumentException do
            Check(True, 'four buttons are refused');
        end;
        InputQuery('Rename', 'New name:', 'old.txt',
          procedure(AOk: Boolean; const AValue: string)
          begin
            FLog := FLog + [Format('input=%s,%s', [BoolToStr(AOk, True), AValue])];
          end);
      end;
    13:
      Check(HideDialog, 'InputQuery opens a ContentDialog');
    15:
      begin
        Check((Length(FLog) = 4) and (FLog[3] = 'input=False,old.txt'), 'cancelled InputQuery gives False and the default');
        CloseHandle(BeginThread(nil, 0, QueueFromThread, nil, 0, ThreadId));
      end;
    17:
      begin
        Check(QueuedOnThread = UIThreadId, 'TWinUIApp.Queue from another thread runs on the UI thread');
        // The VCL names: InputBox gives the default when cancelled, ShowMessageFmt formats
        InputBox('Rename', 'New name:', 'keep.txt',
          procedure(const AValue: string)
          begin
            FLog := FLog + ['box=' + AValue];
          end);
      end;
    19:
      Check(HideDialog, 'InputBox opens a ContentDialog');
    21:
      begin
        Check(FLog[High(FLog)] = 'box=keep.txt', 'cancelled InputBox gives the default');
        ShowMessageFmt('%d notes exported', [3]);
        MessageDlg('Saved.', mtInformation, [mbOK]); // no callback needed
      end;
    23:
      Check(HideDialogText = '3 notes exported', 'ShowMessageFmt shows the formatted text');
    25:
      Check(HideDialog, 'MessageDlg with mtInformation, [mbOK] and no callback');
    27:
      begin
        Check(TWinUIApp.LaunchActivation.Kind = TWinUIActivationKind.Launch, 'LaunchActivation of a normal start');
        Check(TWinUINotification.Supported or True, 'TWinUINotification.Supported answers: ' +
          BoolToStr(TWinUINotification.Supported, True));
        FTimer.Enabled := False;
        if Failures = 0 then
          Writeln('PASSED')
        else
          Writeln(Format('FAILED: %d', [Failures]));
        Flush(Output);
        ExitProcess(Ord(Failures > 0));
      end;
  end;
end;

begin
  if (ParamCount >= 1) and (ParamStr(1) = '--single') then
  begin
    TWinUIApp.SingleInstance := True;
    TWinUIApp.OnActivated := TSingleWindow.Activated;
    TWinUIApp.Run(TSingleWindow);
    Exit;
  end;
  Writeln('AppServicesTest');
  CheckFilters;
  CheckSingleInstance;
  TWinUIApp.OnException := TTestWindow.Failed;
  TWinUIApp.Run(TTestWindow);
end.
