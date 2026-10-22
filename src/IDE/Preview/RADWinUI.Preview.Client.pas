unit RADWinUI.Preview.Client;

{
  The IDE end of the live preview, without ToolsAPI so it is
  tested outside the IDE (tests\Preview). It starts RADWinUIPreview.exe
  --pipe <name> [--parent <HWND>], connects, and sends the XAML when it changed. Nothing here
  blocks for long or raises: every pipe wait has a timeout, and a host that
  hangs or crashes is ended and started again. A host that exits with code 0
  was closed by the user: the client then stops (Closed). Preview events arrive
  on a second pipe and are read on a background thread.
}

interface

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.Math;

type
  TPreviewClient = class
  strict private
    FExe: string;
    FPipeName: string;
    FParentWindow: HWND;
    FProcess: TProcessInformation;
    FPipe: THandle;
    FStarted: Cardinal;
    FLastSent: string;
    FStatus: string;
    FCrashes: Integer;
    FClosed: Boolean;
    FFailed: Boolean;
    FEvents: TArray<string>;
    FEventsLock: TRTLCriticalSection;
    FEventReader: TThread;
    FEventStop: THandle;
    FEventBroken: LongInt;
    FTimedOut: Boolean;      // the last Transact failed by timeout (a hang), not a broken pipe
    FClosingSince: Cardinal; // the pipe broke: wait for the host's exit code, not for an answer
    FAsync, FReady: Boolean;
    FRequests: TStringList;
    FRequest: string;
    FIo: TOverlapped;
    FIoStage: (ioIdle, ioWriting, ioReading);
    FWriteBytes, FReadBytes, FReplyBytes: TBytes;
    FIoStarted: Cardinal;
    FLastTick: Cardinal;
    FResumePending: Boolean;
    procedure PumpRequest;
    procedure RequestFailed(ATimeout: Boolean);
    procedure StartHost;
    procedure StopHost(AKill: Boolean);
    procedure StartEventReader;
    procedure StopEventReader;
    function TryConnect: Boolean;
    function Transact(const ARequest: string; out AReply: string): Boolean;
  public
    constructor Create(const AExe: string; AParentWindow: HWND = 0; AAsync: Boolean = False);
    /// <summary>Closes the pipe, which ends the host.</summary>
    destructor Destroy; override;
    /// <summary>
    ///   Call it often (a timer): starts or restarts the host when needed and
    ///   sends AXaml when it differs from what the host shows.
    /// </summary>
    procedure Tick(const APath, AXaml: string);
    /// <summary>
    ///   Sends one request (HIT, TOOL, DRAG or EVENT, see RADWinUI.Preview.Host) when connected.
    ///   False when not connected or the host failed, a failed host is restarted
    ///   by the next ticks, like a failed LOAD. In async mode, True means queued:
    ///   AReply is QUEUED, and later ticks deliver the actual reply through Status.
    /// </summary>
    function Request(const ARequest: string; out AReply: string): Boolean;
    /// <summary>
    ///   The next thing the user did in the preview, oldest first: SELECTED,
    ///   INSERT, MOVE or DELETE (see RADWinUI.Preview.Host). False when none.
    /// </summary>
    function TakeEvent(out AEvent: string): Boolean;
    /// <summary>Shows the preview window in front (restored when minimized).</summary>
    procedure BringToFront;
    /// <summary>The user closed the preview window.</summary>
    property Closed: Boolean read FClosed;
    /// <summary>The host's pipe broke, it is exiting. Start a new client rather than wait.</summary>
    function Closing: Boolean;
    /// <summary>The protocol handshake finished and requests can be sent.</summary>
    function Ready: Boolean;
    /// <summary>An asynchronous request is queued or in flight.</summary>
    function Busy: Boolean;
    /// <summary>Reset paused timeout budgets and restore an embedded surface on its UI thread.</summary>
    procedure Resume;
    /// <summary>The host cannot be started or keeps crashing, Status says why.</summary>
    property Failed: Boolean read FFailed;
    /// <summary>The last answer (OK, ERROR ...) or what went wrong.</summary>
    property Status: string read FStatus;
    /// <summary>The host process, for tests.</summary>
    property HostProcess: THandle read FProcess.hProcess;
  end;

implementation

const
  // The IDE uses overlapped I/O advanced by Tick, without waiting for the host.
  // Synchronous mode remains available to standalone protocol callers.
  IoTimeout = 3000;       // ms for one request and its answer
  ClosingTimeout = 5000;  // ms a host may take to exit after its pipe broke
  ConnectTimeout = 20000; // ms from starting the host to its pipe
  MaxCrashes = 3;         // in a row, before giving up

function ReadEventMessage(APipe, AStop: THandle; out AMessage: string): Boolean;
var
  Overlapped: TOverlapped;
  Handles: array[0..1] of THandle;
  Buffer: TBytes;
  Count: DWORD;
  Wait: DWORD;
begin
  Result := False;
  AMessage := '';
  SetLength(Buffer, 65536);
  Overlapped := Default(TOverlapped);
  Overlapped.hEvent := CreateEvent(nil, True, False, nil);
  if Overlapped.hEvent = 0 then
    Exit;
  try
    Handles[0] := AStop;
    Handles[1] := Overlapped.hEvent;
    if not ReadFile(APipe, Buffer[0], Length(Buffer), Count, @Overlapped) then
    begin
      if GetLastError <> ERROR_IO_PENDING then
        Exit;
      Wait := WaitForMultipleObjects(Length(Handles), @Handles[0], False, INFINITE);
      if Wait = WAIT_OBJECT_0 then
      begin
        CancelIo(APipe);
        GetOverlappedResult(APipe, Overlapped, Count, True);
        Exit;
      end;
      if (Wait <> WAIT_OBJECT_0 + 1) or not GetOverlappedResult(APipe, Overlapped, Count, False) then
        Exit;
    end;
    AMessage := TEncoding.UTF8.GetString(Buffer, 0, Count);
    Result := True;
  finally
    CloseHandle(Overlapped.hEvent);
  end;
end;

var
  Counter: Integer;

constructor TPreviewClient.Create(const AExe: string; AParentWindow: HWND; AAsync: Boolean);
begin
  inherited Create;
  InitializeCriticalSection(FEventsLock);
  FExe := AExe;
  FParentWindow := AParentWindow;
  FPipe := INVALID_HANDLE_VALUE;
  FEventStop := 0;
  FAsync := AAsync;
  FRequests := TStringList.Create;
  FIo.hEvent := CreateEvent(nil, True, False, nil);
  if FIo.hEvent = 0 then RaiseLastOSError;
  Inc(Counter);
  FPipeName := Format('RADWinUIPreview-%d-%d', [GetCurrentProcessId, Counter]);
end;

destructor TPreviewClient.Destroy;
begin
  StopHost(False);
  CloseHandle(FIo.hEvent);
  FRequests.Free;
  DeleteCriticalSection(FEventsLock);
  inherited;
end;

procedure TPreviewClient.StartHost;
var
  Startup: TStartupInfo;
  CommandLine: string;
begin
  if (FParentWindow <> 0) and not IsWindow(FParentWindow) then
  begin
    FFailed := True;
    FStatus := 'The docked preview parent window no longer exists';
    Exit;
  end;
  Startup := Default(TStartupInfo);
  Startup.cb := SizeOf(Startup);
  CommandLine := Format('"%s" --pipe %s', [FExe, FPipeName]);
  if FParentWindow <> 0 then
    CommandLine := CommandLine + ' --parent ' + UIntToStr(UInt64(NativeUInt(FParentWindow)));
  UniqueString(CommandLine);
  if not CreateProcess(nil, PChar(CommandLine), nil, nil, False, 0, nil, PChar(ExtractFilePath(FExe)),
    Startup, FProcess) then
  begin
    FFailed := True;
    FStatus := 'Cannot start ' + FExe + ': ' + SysErrorMessage(GetLastError);
    Exit;
  end;
  CloseHandle(FProcess.hThread);
  FProcess.hThread := 0;
  FStarted := GetTickCount;
  FClosingSince := 0;
  InterlockedExchange(FEventBroken, 0);
  FLastSent := '';
  FResumePending := FParentWindow <> 0;
  FStatus := 'Starting the preview';
end;

procedure TPreviewClient.StopHost(AKill: Boolean);
var
  Count: DWORD;
begin
  StopEventReader;
  if (FPipe <> INVALID_HANDLE_VALUE) and (FIoStage <> ioIdle) then
  begin
    CancelIoEx(FPipe, @FIo);
    // Cancellation completes in the kernel, it does not wait for the renderer.
    GetOverlappedResult(FPipe, FIo, Count, True);
  end;
  FIoStage := ioIdle;
  if FRequests <> nil then FRequests.Clear;
  FRequest := '';
  FWriteBytes := nil;
  FReadBytes := nil;
  FReplyBytes := nil;
  FReady := False;
  if FPipe <> INVALID_HANDLE_VALUE then
    CloseHandle(FPipe); // the host exits when its client disconnects
  FPipe := INVALID_HANDLE_VALUE;
  if FProcess.hProcess <> 0 then
  begin
    if AKill then
      TerminateProcess(FProcess.hProcess, 1);
    CloseHandle(FProcess.hProcess);
  end;
  FProcess := Default(TProcessInformation);
end;

procedure TPreviewClient.StartEventReader;
var
  Stop: THandle;
  PipeName: string;
  Started: Cardinal;
begin
  FEventStop := CreateEvent(nil, True, False, nil);
  if FEventStop = 0 then
  begin
    FFailed := True;
    FStatus := 'Cannot create the preview event stop event: ' + SysErrorMessage(GetLastError);
    Exit;
  end;
  Stop := FEventStop;
  PipeName := '\\.\pipe\' + FPipeName + '-events';
  Started := GetTickCount;
  FEventReader := TThread.CreateAnonymousThread(
    procedure
    var
      Pipe: THandle;
      Mode: DWORD;
      Event: string;
      Connected: Boolean;
    begin
      Pipe := INVALID_HANDLE_VALUE;
      Connected := False;
      try
        repeat
          if WaitForSingleObject(Stop, 0) = WAIT_OBJECT_0 then
            Exit;
          Pipe := CreateFile(PChar(PipeName), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, 0);
          if Pipe <> INVALID_HANDLE_VALUE then
            Break;
          if GetTickCount - Started > ConnectTimeout then
          begin
            InterlockedExchange(FEventBroken, 1);
            Exit;
          end;
          if WaitForSingleObject(Stop, 50) = WAIT_OBJECT_0 then
            Exit;
        until False;
        Connected := True;
        Mode := PIPE_READMODE_MESSAGE;
        if not SetNamedPipeHandleState(Pipe, Mode, nil, nil) then
          Exit;
        while ReadEventMessage(Pipe, Stop, Event) do
        begin
          EnterCriticalSection(FEventsLock);
          try
            FEvents := FEvents + [Event];
          finally
            LeaveCriticalSection(FEventsLock);
          end;
        end;
      finally
        if Pipe <> INVALID_HANDLE_VALUE then
          CloseHandle(Pipe);
        if Connected and (WaitForSingleObject(Stop, 0) <> WAIT_OBJECT_0) then
          InterlockedExchange(FEventBroken, 1);
      end;
    end);
  FEventReader.FreeOnTerminate := False;
  FEventReader.Start;
end;

procedure TPreviewClient.StopEventReader;
begin
  if FEventStop <> 0 then
    SetEvent(FEventStop);
  if FEventReader <> nil then
  begin
    FEventReader.WaitFor;
    FEventReader.Free;
    FEventReader := nil;
  end;
  if FEventStop <> 0 then
    CloseHandle(FEventStop);
  FEventStop := 0;
  InterlockedExchange(FEventBroken, 0);
  EnterCriticalSection(FEventsLock);
  try
    FEvents := nil;
  finally
    LeaveCriticalSection(FEventsLock);
  end;
end;

function TPreviewClient.TryConnect: Boolean;
var
  Mode: DWORD;
begin
  FPipe := CreateFile(PChar('\\.\pipe\' + FPipeName), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING,
    FILE_FLAG_OVERLAPPED, 0);
  Result := FPipe <> INVALID_HANDLE_VALUE;
  if Result then
  begin
    Mode := PIPE_READMODE_MESSAGE;
    SetNamedPipeHandleState(FPipe, Mode, nil, nil);
  end;
end;

/// Overlapped write, then read of one message, each within IoTimeout.
function TPreviewClient.Transact(const ARequest: string; out AReply: string): Boolean;
var
  Overlapped: TOverlapped;

  /// Waits for the operation AOk started, False on failure or timeout. AMore: the message continues.
  function Complete(AOk: Boolean; out ACount: DWORD; out AMore: Boolean): Boolean;
  var
    Error: DWORD;
  begin
    if not AOk then
    begin
      Error := GetLastError;
      if Error = ERROR_IO_PENDING then
      begin
        if WaitForSingleObject(Overlapped.hEvent, IoTimeout) <> WAIT_OBJECT_0 then
        begin
          CancelIo(FPipe);
          FTimedOut := True;
          Exit(False);
        end;
      end
      else if Error <> ERROR_MORE_DATA then
        Exit(False);
    end;
    AMore := not GetOverlappedResult(FPipe, Overlapped, ACount, False);
    Result := not AMore or (GetLastError = ERROR_MORE_DATA);
  end;

var
  Bytes, Buffer, Data: TBytes;
  Count: DWORD;
  More: Boolean;
begin
  Result := False;
  AReply := '';
  FTimedOut := False;
  Overlapped := Default(TOverlapped);
  Overlapped.hEvent := CreateEvent(nil, True, False, nil);
  try
    Bytes := TEncoding.UTF8.GetBytes(ARequest);
    if not Complete(WriteFile(FPipe, Bytes[0], Length(Bytes), Count, @Overlapped), Count, More) then
      Exit;
    SetLength(Buffer, 65536);
    Data := nil;
    repeat
      ResetEvent(Overlapped.hEvent);
      if not Complete(ReadFile(FPipe, Buffer[0], Length(Buffer), Count, @Overlapped), Count, More) then
        Exit;
      Data := Data + Copy(Buffer, 0, Count);
    until not More;
    AReply := TEncoding.UTF8.GetString(Data);
    Result := True;
  finally
    CloseHandle(Overlapped.hEvent);
  end;
end;

procedure TPreviewClient.Tick(const APath, AXaml: string);
var
  ExitCode: DWORD;
  Reply: string;
  Now: Cardinal;
begin
  if FClosed or FFailed then
    Exit;
  Now := GetTickCount;
  // Compilation/debugging can stop IDE timers without stopping the renderer.
  // Do not count an unobserved timer gap as a failed pipe request.
  if (FLastTick <> 0) and (Now - FLastTick > IoTimeout) then Resume;
  FLastTick := Now;
  if FProcess.hProcess = 0 then
  begin
    StartHost;
    if FFailed then
      Exit;
  end;
  if WaitForSingleObject(FProcess.hProcess, 0) = WAIT_OBJECT_0 then
  begin
    GetExitCodeProcess(FProcess.hProcess, ExitCode);
    StopHost(False);
    if ExitCode = 0 then
    begin
      FClosed := True;
      FStatus := 'The preview was closed';
      Exit;
    end;
    Inc(FCrashes);
    if FCrashes >= MaxCrashes then
    begin
      FFailed := True;
      FStatus := Format('The preview stopped %d times in a row (last exit code %d)', [FCrashes, ExitCode]);
    end;
    Exit; // the next tick starts it again
  end;
  if FClosingSince <> 0 then
  begin
    // Still running after its pipe broke: it is closing slowly, end it (no restart)
    if GetTickCount - FClosingSince > ClosingTimeout then
    begin
      StopHost(True);
      FClosed := True;
      FStatus := 'The preview was closed';
    end;
    Exit;
  end;
  if (InterlockedCompareExchange(FEventBroken, 0, 0) <> 0) and (FPipe <> INVALID_HANDLE_VALUE) then
  begin
    RequestFailed(False);
    Exit;
  end;
  if FPipe = INVALID_HANDLE_VALUE then
  begin
    if TryConnect then
    begin
      if FAsync then
      begin
        FRequests.Add('HELLO');
        PumpRequest;
        Exit;
      end;
      if not Request('HELLO', Reply) then
        Exit;
      if Reply <> 'RADWINUI-DESIGNER 6' then
      begin
        StopHost(False);
        FFailed := True;
        FStatus := 'The preview host is outdated. Close its preview windows and rebuild ' +
          'src\IDE\Preview\RADWinUIPreview.dpr, then reopen Design.';
        Exit;
      end;
      StartEventReader;
      if FFailed then
        Exit;
      FReady := True;
    end
    else
    begin
      if GetTickCount - FStarted > ConnectTimeout then
      begin
        StopHost(True);
        FFailed := True;
        FStatus := 'The preview did not start within ' + IntToStr(ConnectTimeout div 1000) + ' s';
      end;
      Exit;
    end;
  end;
  if FAsync then
  begin
    PumpRequest;
    if not Ready then Exit;
  end;
  if (AXaml <> '') and (APath + #0 + AXaml <> FLastSent) then
  begin
    if not Request('LOAD ' + APath + #10 + AXaml, Reply) then
      Exit;
    FLastSent := APath + #0 + AXaml;
    FStatus := Reply;
  end;
  if FResumePending and Request('RESUME', Reply) then FResumePending := False;
  if FAsync then PumpRequest;
end;

/// Progress overlapped I/O without waiting on the IDE thread. The embedded WinUI
/// thread can synchronously message its VCL parent while servicing a request.
procedure TPreviewClient.PumpRequest;
var
  Count, Error: DWORD;
  Steps: Integer;
  More: Boolean;
  Reply, Request: string;

  procedure ResetIo;
  var
    Event: THandle;
  begin
    Event := FIo.hEvent;
    FIo := Default(TOverlapped);
    FIo.hEvent := Event;
    ResetEvent(Event);
  end;

  function StartRead: Boolean;
  begin
    ResetIo;
    FIoStage := ioReading;
    Result := ReadFile(FPipe, FReadBytes[0], Length(FReadBytes), Count, @FIo);
    if not Result then
    begin
      Error := GetLastError;
      Result := (Error = ERROR_IO_PENDING) or (Error = ERROR_MORE_DATA);
    end;
    if not Result then RequestFailed(False);
  end;

begin
  if (FPipe = INVALID_HANDLE_VALUE) or FClosed or FFailed or Closing then Exit;
  // Bound work per timer tick, including replies spanning multiple pipe messages.
  for Steps := 1 to 8 do
  begin
    if FIoStage = ioIdle then
    begin
      if FRequests.Count = 0 then Exit;
      FRequest := FRequests[0];
      FRequests.Delete(0);
      FWriteBytes := TEncoding.UTF8.GetBytes(FRequest);
      FReplyBytes := nil;
      SetLength(FReadBytes, 65536);
      FIoStarted := GetTickCount;
      ResetIo;
      FIoStage := ioWriting;
      if not WriteFile(FPipe, FWriteBytes[0], Length(FWriteBytes), Count, @FIo) and
        (GetLastError <> ERROR_IO_PENDING) then
      begin
        RequestFailed(False);
        Exit;
      end;
    end;
    Error := ERROR_SUCCESS;
    if not GetOverlappedResult(FPipe, FIo, Count, False) then
    begin
      Error := GetLastError;
      if Error = ERROR_IO_INCOMPLETE then
      begin
        if GetTickCount - FIoStarted > IoTimeout then RequestFailed(True);
        Exit;
      end;
      if (FIoStage <> ioReading) or (Error <> ERROR_MORE_DATA) then
      begin
        RequestFailed(False);
        Exit;
      end;
    end;
    if FIoStage = ioWriting then
    begin
      if not StartRead then Exit;
      Continue;
    end;
    More := Error = ERROR_MORE_DATA;
    FReplyBytes := FReplyBytes + Copy(FReadBytes, 0, Count);
    if More then
    begin
      if not StartRead then Exit;
      Continue;
    end;
    Reply := TEncoding.UTF8.GetString(FReplyBytes);
    Request := FRequest;
    FRequest := '';
    FIoStage := ioIdle;
    FWriteBytes := nil;
    FReadBytes := nil;
    FReplyBytes := nil;
    if Request.StartsWith('LOAD ') and not Reply.StartsWith('ERROR') then
      FCrashes := 0;
    if Request = 'HELLO' then
    begin
      if Reply <> 'RADWINUI-DESIGNER 6' then
      begin
        StopHost(False);
        FFailed := True;
        FStatus := 'The preview host is outdated. Rebuild src\IDE\Preview\RADWinUIPreview.dpr.';
        Exit;
      end;
      StartEventReader;
      FReady := not FFailed;
    end
    else
      FStatus := Reply;
  end;
end;

procedure TPreviewClient.RequestFailed(ATimeout: Boolean);
var
  Count: DWORD;
begin
  FReady := False;
  if ATimeout then
  begin
    StopHost(True);
    Inc(FCrashes);
    FStatus := 'The preview did not answer; restarting it';
    if FCrashes >= MaxCrashes then FFailed := True;
  end
  else
  begin
    if FIoStage <> ioIdle then
    begin
      CancelIoEx(FPipe, @FIo);
      GetOverlappedResult(FPipe, FIo, Count, True);
      FIoStage := ioIdle;
    end;
    CloseHandle(FPipe);
    FPipe := INVALID_HANDLE_VALUE;
    FRequests.Clear;
    FClosingSince := Max(GetTickCount, 1);
    FStatus := 'The preview is closing';
  end;
end;

function TPreviewClient.Request(const ARequest: string; out AReply: string): Boolean;
var
  I: Integer;
  Prefix: string;
begin
  if FAsync then
  begin
    Result := Ready;
    AReply := '';
    if not Result then Exit;
    // Keep the newest pending source/theme/selection, preserve discrete ADD commands.
    Prefix := ARequest.Substring(0, ARequest.IndexOf(' ') + 1);
    if ARequest = 'RESUME' then Prefix := ARequest;
    if (Prefix = 'LOAD ') or (Prefix = 'THEME ') or (Prefix = 'SELECTPOS ') or (Prefix = 'RESUME') then
      for I := FRequests.Count - 1 downto 0 do
        if FRequests[I].StartsWith(Prefix) then FRequests.Delete(I);
    FRequests.Add(ARequest);
    AReply := 'QUEUED';
    Exit;
  end;
  Result := (FPipe <> INVALID_HANDLE_VALUE) and Transact(ARequest, AReply);
  if Result then
    FCrashes := 0
  else if FPipe <> INVALID_HANDLE_VALUE then
  begin
    if not FTimedOut then
    begin
      // A broken pipe: the user closed the window (the host exits with 0) or the host
      // crashed. The next ticks read its exit code without blocking the IDE.
      CloseHandle(FPipe);
      FPipe := INVALID_HANDLE_VALUE;
      FClosingSince := Max(GetTickCount, 1);
      FStatus := 'The preview is closing';
      Exit;
    end;
    // A host that does not answer is ended, the next ticks start a new one
    StopHost(True);
    Inc(FCrashes);
    FStatus := 'The preview did not answer; restarting it';
    if FCrashes >= MaxCrashes then
      FFailed := True;
  end;
end;

function TPreviewClient.Closing: Boolean;
begin
  Result := FClosingSince <> 0;
end;

function TPreviewClient.Ready: Boolean;
begin
  Result := FReady and (FPipe <> INVALID_HANDLE_VALUE) and not FClosed and not FFailed and not Closing;
end;

function TPreviewClient.Busy: Boolean;
begin
  Result := FAsync and ((FIoStage <> ioIdle) or (FRequests.Count > 0));
end;

procedure TPreviewClient.Resume;
begin
  if Busy then FIoStarted := GetTickCount;
  if not Ready then FStarted := GetTickCount;
  FLastTick := GetTickCount;
  FResumePending := FParentWindow <> 0;
end;

type
  TFindWindow = record
    Pid: DWORD;
    Wnd: HWND;
  end;

function FindHostWindow(AWnd: HWND; AParam: LPARAM): BOOL; stdcall;
var
  Pid: DWORD;
begin
  GetWindowThreadProcessId(AWnd, Pid);
  Result := True;
  if (Pid = TFindWindow(Pointer(AParam)^).Pid) and IsWindowVisible(AWnd) and (GetWindow(AWnd, GW_OWNER) = 0) then
  begin
    TFindWindow(Pointer(AParam)^).Wnd := AWnd;
    Result := False;
  end;
end;

procedure TPreviewClient.BringToFront;
var
  Find: TFindWindow;
begin
  if FProcess.hProcess = 0 then
    Exit;
  Find.Pid := GetProcessId(FProcess.hProcess);
  Find.Wnd := 0;
  EnumWindows(@FindHostWindow, LPARAM(@Find));
  if Find.Wnd = 0 then
    Exit;
  if IsIconic(Find.Wnd) then
    ShowWindow(Find.Wnd, SW_RESTORE);
  SetForegroundWindow(Find.Wnd);
end;

function TPreviewClient.TakeEvent(out AEvent: string): Boolean;
begin
  EnterCriticalSection(FEventsLock);
  try
    Result := FEvents <> nil;
    if Result then
    begin
      AEvent := FEvents[0];
      Delete(FEvents, 0, 1);
    end;
  finally
    LeaveCriticalSection(FEventsLock);
  end;
end;

end.
