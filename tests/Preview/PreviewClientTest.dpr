program PreviewClientTest;

{
  Checks TPreviewClient, the IDE end of the live preview, against the real
  host outside the IDE:

    PreviewClientTest <RADWinUIPreview.exe> <window .xaml> [cycles]

  Crash, hang (suspended host), closed by the user, large and malformed XAML,
  memory over many edits on one host, and [cycles] start/edit/close cycles.
  Every host window must stay off the primary monitor and never become the
  foreground window, the test stops at once when one does.
  scripts\Test-Preview.ps1 runs it with RADWINUI_TEST_MONITOR=secondary.
}

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.MultiMon,
  Winapi.TlHelp32,
  Winapi.PsAPI,
  System.SysUtils,
  System.IOUtils,
  RADWinUI.Preview.Client in '..\..\src\IDE\Preview\RADWinUI.Preview.Client.pas';

const
  THREAD_SUSPEND_RESUME = $0002;

function OpenThread(dwDesiredAccess: DWORD; bInheritHandle: BOOL; dwThreadId: DWORD): THandle; stdcall;
  external kernel32;

var
  Failures: Integer;

procedure Check(ACondition: Boolean; const AWhat: string);
begin
  if ACondition then
    Writeln('  [ok] ', AWhat)
  else
  begin
    Writeln('  [failed] ', AWhat);
    Inc(Failures);
  end;
end;

type
  TFind = record
    Pid: DWORD;
    Wnd: HWND;
  end;
  TMonitorFind = record
    WorkArea: TRect;
    Found: Boolean;
  end;

function FindSecondaryMonitor(AMonitor: HMONITOR; ADC: HDC; ARect: PRect; AData: LPARAM): BOOL; stdcall;
var
  Info: TMonitorInfo;
begin
  Result := True;
  Info.cbSize := SizeOf(Info);
  if GetMonitorInfo(AMonitor, @Info) and (Info.dwFlags and MONITORINFOF_PRIMARY = 0) then
  begin
    TMonitorFind(Pointer(AData)^).WorkArea := Info.rcWork;
    TMonitorFind(Pointer(AData)^).Found := True;
    Result := False;
  end;
end;

function FindTopWindow(AWnd: HWND; AParam: LPARAM): BOOL; stdcall;
var
  Pid: DWORD;
  ClassName: array[0..63] of Char;
begin
  GetWindowThreadProcessId(AWnd, Pid);
  GetClassName(AWnd, ClassName, Length(ClassName));
  if (Pid = TFind(Pointer(AParam)^).Pid) and IsWindowVisible(AWnd) and
    (string(ClassName) = 'WinUIDesktopWin32WindowClass') then
  begin
    TFind(Pointer(AParam)^).Wnd := AWnd;
    Exit(False);
  end;
  Result := True;
end;

/// Stops the test at once when the host window is on the primary monitor or has the focus.
procedure GuardMonitor(AClient: TPreviewClient);
var
  Find: TFind;
  Info: TMonitorInfo;
  Why: string;
begin
  Find.Pid := GetProcessId(AClient.HostProcess);
  Find.Wnd := 0;
  if Find.Pid = 0 then
    Exit;
  EnumWindows(@FindTopWindow, LPARAM(@Find));
  if Find.Wnd = 0 then
    Exit;
  Info.cbSize := SizeOf(Info);
  GetMonitorInfo(MonitorFromWindow(Find.Wnd, MONITOR_DEFAULTTONEAREST), @Info);
  Why := '';
  if Info.dwFlags and MONITORINFOF_PRIMARY <> 0 then
    Why := 'a preview window opened on the primary monitor'
  else if GetForegroundWindow = Find.Wnd then
    Why := 'a preview window took the focus';
  if Why <> '' then
  begin
    TerminateProcess(AClient.HostProcess, 1);
    Writeln('  [failed] ', Why, '; stopping');
    Halt(3);
  end;
end;

procedure PumpWindowMessages(AWindow: HWND);
var
  Msg: TMsg;
begin
  while PeekMessage(Msg, AWindow, 0, 0, PM_REMOVE) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;

/// Ticks like the IDE timer until AUntil holds or 20 s pass.
function TickUntil(AClient: TPreviewClient; const APath, AXaml: string; AUntil: TFunc<Boolean>;
  AParentWindow: HWND = 0): Boolean;
var
  Started: Cardinal;
begin
  Started := GetTickCount;
  repeat
    if AParentWindow <> 0 then
      PumpWindowMessages(AParentWindow);
    AClient.Tick(APath, AXaml);
    GuardMonitor(AClient);
    if AUntil then
      Exit(True);
    Sleep(100);
  until GetTickCount - Started > 20000;
  Result := False;
end;

/// Suspends every thread of AProcess: a host that hangs.
procedure Suspend(AProcess: THandle);
var
  Snapshot, Thread: THandle;
  Entry: TThreadEntry32;
  Pid: DWORD;
begin
  Pid := GetProcessId(AProcess);
  Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
  try
    Entry.dwSize := SizeOf(Entry);
    if Thread32First(Snapshot, Entry) then
      repeat
        if Entry.th32OwnerProcessID = Pid then
        begin
          Thread := OpenThread(THREAD_SUSPEND_RESUME, False, Entry.th32ThreadID);
          if Thread <> 0 then
          begin
            SuspendThread(Thread);
            CloseHandle(Thread);
          end;
        end;
      until not Thread32Next(Snapshot, Entry);
  finally
    CloseHandle(Snapshot);
  end;
end;

function PrivateMB(AProcess: THandle): Integer;
var
  Counters: TProcessMemoryCountersEx;
begin
  Counters.cb := SizeOf(Counters);
  GetProcessMemoryInfo(AProcess, @Counters, SizeOf(Counters));
  Result := Counters.PrivateUsage div (1024 * 1024);
end;

procedure TestDockedPreview(const AExe, APath, AXaml: string);
var
  Monitor: TMonitorFind;
  Parent, Docked: HWND;
  Client: TPreviewClient;
  ParentRect, ChildRect, HostRect: TRect;
  Style: NativeInt;
  Pid: DWORD;
  Started, ExitCode: Cardinal;
  Host: THandle;
  Reply: string;
begin
  Writeln('Docked preview');
  Host := 0;
  Docked := 0;
  if SetThreadDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2) = nil then
  begin
    Check(False, 'sets per-monitor DPI awareness for the dock parent');
    Exit;
  end;
  FillChar(Monitor, SizeOf(Monitor), 0);
  EnumDisplayMonitors(0, nil, @FindSecondaryMonitor, LPARAM(@Monitor));
  if not Monitor.Found then
  begin
    Check(False, 'a secondary monitor is available for the docked host');
    Exit;
  end;
  // Use a non-activating parent on the secondary monitor, like the UI test harness.
  Parent := CreateWindowEx(WS_EX_NOACTIVATE or WS_EX_TOOLWINDOW, 'STATIC', 'RADWinUI dock test',
    WS_POPUP or WS_VISIBLE, Monitor.WorkArea.Left + 24, Monitor.WorkArea.Top + 24, 700, 500,
    0, 0, HInstance, nil);
  if Parent = 0 then
  begin
    Check(False, 'creates a test dock parent: ' + SysErrorMessage(GetLastError));
    Exit;
  end;
  ShowWindow(Parent, SW_SHOWNOACTIVATE);
  Client := nil;
  try
    Client := TPreviewClient.Create(AExe, Parent);
    Client.Tick(APath, AXaml);
    if (Client.HostProcess <> 0) and not DuplicateHandle(GetCurrentProcess, Client.HostProcess,
      GetCurrentProcess, @Host, 0, False, DUPLICATE_SAME_ACCESS) then
    begin
      Writeln('  cannot duplicate process handle: ', GetLastError);
      Check(False, 'captures the docked host process handle');
    end;
    Started := GetTickCount;
    repeat
      PumpWindowMessages(Parent);
      Client.Tick(APath, AXaml);
      if (Client.Status = 'OK') or Client.Closed or Client.Failed then
        Break;
      Sleep(100);
    until GetTickCount - Started >= 20000;
    Check(Client.Status = 'OK', 'starts the host in the dock parent (' + Client.Status + ')');
    if Client.Status <> 'OK' then
    begin
      if (Host <> 0) and GetExitCodeProcess(Host, ExitCode) then
        Writeln('  host exit code: ', ExitCode);
      Exit;
    end;
    Started := GetTickCount;
    repeat
      Docked := FindWindowEx(Parent, 0, 'WinUIDesktopWin32WindowClass', nil);
      if Docked <> 0 then
        Break;
      Sleep(20);
    until GetTickCount - Started >= 5000;
    Pid := 0;
    if Docked <> 0 then
      GetWindowThreadProcessId(Docked, Pid);
    Check((Docked <> 0) and (GetParent(Docked) = Parent) and (Pid = GetProcessId(Client.HostProcess)),
      'the host is a child of the dock parent');
    if Docked <> 0 then
    begin
      Style := GetWindowLongPtr(Docked, GWL_STYLE);
      Check(((Style and WS_CHILD) <> 0) and ((Style and WS_POPUP) = 0), 'the host has child-window styles');
      Started := GetTickCount;
      repeat
        PumpWindowMessages(Parent);
        GetClientRect(Parent, ParentRect);
        GetClientRect(Docked, ChildRect);
        if ((ChildRect.Right - ChildRect.Left) = (ParentRect.Right - ParentRect.Left)) and
          ((ChildRect.Bottom - ChildRect.Top) = (ParentRect.Bottom - ParentRect.Top)) then
          Break;
        Sleep(20);
      until GetTickCount - Started >= 3000;
      Check(((ChildRect.Right - ChildRect.Left) = (ParentRect.Right - ParentRect.Left)) and
        ((ChildRect.Bottom - ChildRect.Top) = (ParentRect.Bottom - ParentRect.Top)),
        'the host fills the initial dock area');
      if ((ChildRect.Right - ChildRect.Left) <> (ParentRect.Right - ParentRect.Left)) or
        ((ChildRect.Bottom - ChildRect.Top) <> (ParentRect.Bottom - ParentRect.Top)) then
        Writeln(Format('  parent %dx%d, host %dx%d', [ParentRect.Right - ParentRect.Left,
          ParentRect.Bottom - ParentRect.Top, ChildRect.Right - ChildRect.Left, ChildRect.Bottom - ChildRect.Top]));

      // HIT uses the same screen-to-content conversion as the click drag timer.
      GetWindowRect(Docked, HostRect);
      Reply := '';
      Check(Client.Request(Format('HIT %d %d', [HostRect.Left + 200, HostRect.Top + 100]), Reply) and
        ((Reply = 'NONE') or Reply.StartsWith('SELECTED ')) and
        (WaitForSingleObject(Host, 0) = WAIT_TIMEOUT),
        'hit-testing a reparented host answers without an access violation (' + Reply + ')');

      Reply := '';
      Check(Client.Request('THEME Dark #FF202020', Reply) and (Reply = 'OK'),
        'the reparented host accepts the IDE dark theme (' + Reply + ')');
      Check(Client.Request('THEME Light #FFF0F0F0', Reply) and (Reply = 'OK'),
        'the reparented host can return to the IDE light theme (' + Reply + ')');
      Check(Client.Request('LOAD ' + APath + #10 +
        '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"/>', Reply) and
        (Reply = 'OK') and Client.Request('TOOL CalendarDatePicker', Reply) and (Reply = 'OK') and
        Client.Request(Format('HIT %d %d', [HostRect.Left + 200, HostRect.Top + 100]), Reply) and
        Reply.StartsWith('INSERTAT CalendarDatePicker '),
        'a palette tool dropped on the embedded host reports an insertion (' + Reply + ')');

      Check(SetWindowPos(Parent, 0, 0, 0, 640, 420, SWP_NOMOVE or SWP_NOZORDER or SWP_NOACTIVATE),
        'resizes the test dock parent');
      Started := GetTickCount;
      repeat
        PumpWindowMessages(Parent);
        GetClientRect(Parent, ParentRect);
        GetClientRect(Docked, ChildRect);
        if ((ChildRect.Right - ChildRect.Left) = (ParentRect.Right - ParentRect.Left)) and
          ((ChildRect.Bottom - ChildRect.Top) = (ParentRect.Bottom - ParentRect.Top)) then
          Break;
        Sleep(20);
      until GetTickCount - Started >= 3000;
      Check(((ChildRect.Right - ChildRect.Left) = (ParentRect.Right - ParentRect.Left)) and
        ((ChildRect.Bottom - ChildRect.Top) = (ParentRect.Bottom - ParentRect.Top)),
        'the host follows the dock area resize');
    end;

  finally
    Client.Free;
    if Host <> 0 then
    begin
      if WaitForSingleObject(Host, 5000) = WAIT_OBJECT_0 then
        Check(True, 'the docked host exits when its client closes')
      else
      begin
        Writeln('  host window still exists: ', BoolToStr(IsWindow(Docked), True));
        TerminateProcess(Host, 1);
        Check(False, 'the docked host exits when its client closes');
      end;
      CloseHandle(Host);
    end;
    DestroyWindow(Parent);
  end;
end;

var
  Exe, Path, Good, Broken, Large, Xmlns: string;
  Client: TPreviewClient;
  Ticks: Cardinal;
  Host: THandle;
  I, Cycles, Memory300: Integer;
  Find: TFind;
  Events, Event: string;
  Started, EventTicks: Cardinal;
  Reply: string;
  Memory50: Integer = 0;
begin
  if not (ParamCount in [2, 3]) then
  begin
    Writeln('usage: PreviewClientTest <RADWinUIPreview.exe> <window .xaml> [cycles|--docked-only]');
    Halt(2);
  end;
  Exe := ExpandFileName(ParamStr(1));
  Path := ExpandFileName(ParamStr(2));
  Cycles := StrToIntDef(ParamStr(3), 0);
  Good := TFile.ReadAllText(Path, TEncoding.UTF8);
  Broken := Good.Replace('</StackPanel>', '</StackPanl>');
  Xmlns := 'xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"';
  Writeln('Preview client');
  if SameText(ParamStr(3), '--docked-only') then
  begin
    TestDockedPreview(Exe, Path, Good);
    if Failures > 0 then
      Halt(1);
    Writeln('Docked preview test PASSED');
    Halt(0);
  end;
  Client := TPreviewClient.Create(Exe);
  try
    Check(TickUntil(Client, Path, Good, function: Boolean begin Result := Client.Status = 'OK' end),
      'starts the host and shows the XAML (' + Client.Status + ')');
    Check(Client.Request('HELLO', Reply) and (Reply = 'RADWINUI-DESIGNER 6'),
      'the running host supports the current IDE designer protocol');
    Started := GetTickCount;
    if Client.Request('EVENT', Reply) and (Reply = 'OK') then
    begin
      repeat
        if Client.TakeEvent(Event) then
          Break;
        Sleep(1);
      until GetTickCount - Started >= 1000;
    end
    else
      Event := '';
    EventTicks := GetTickCount - Started;
    Check((Event = 'SELECTED 1 1 TextBlock Test') and (EventTicks < 150),
      Format('a pushed event arrives in %d ms: %s', [EventTicks, Event]));
    Check(TickUntil(Client, Path, Broken, function: Boolean begin Result := Client.Status.StartsWith('ERROR') end),
      'broken XAML: ' + Client.Status);
    TerminateProcess(Client.HostProcess, 3); // a crash
    Check(TickUntil(Client, Path, Good, function: Boolean begin Result := Client.Status = 'OK' end),
      'restarts a crashed host and shows the XAML again (' + Client.Status + ')');
    Check(not Client.Failed and not Client.Closed, 'one crash is not a failure');
    // One tick with nothing new must not wait on the host
    Ticks := GetTickCount;
    Client.Tick(Path, Good);
    Check(GetTickCount - Ticks < 100, 'a tick without changes returns at once');

    // A hung host: the tick gives up after the 3 s timeout and the host is replaced
    Suspend(Client.HostProcess);
    Ticks := GetTickCount;
    Client.Tick(Path, Good + ' ');
    Ticks := GetTickCount - Ticks;
    Check((Ticks >= 2500) and (Ticks < 4500), Format('a hung host blocks one tick for %d ms (3 s timeout): %s',
      [Ticks, Client.Status]));
    Check(TickUntil(Client, Path, Good, function: Boolean begin Result := Client.Status = 'OK' end),
      'a hung host is replaced and shows the XAML again');

    // Large and malformed XAML
    Large := '<ScrollViewer ' + Xmlns + '><StackPanel>';
    for I := 1 to 3000 do
      Large := Large + Format('<TextBlock Text="Line %d of a large window, with some text to make it longer"/>', [I]);
    Large := Large + '</StackPanel></ScrollViewer>';
    Ticks := GetTickCount;
    Check(TickUntil(Client, Path, Large, function: Boolean begin Result := Client.Status = 'OK' end),
      Format('%d KB of XAML (3000 elements) renders in %d ms', [Length(Large) div 1024, GetTickCount - Ticks]));
    Check(TickUntil(Client, Path, 'this is not XML <<<', function: Boolean begin Result := Client.Status.StartsWith('ERROR') end),
      'text that is not XML: ' + Client.Status);
    Check(TickUntil(Client, Path, '<ResourceDictionary ' + Xmlns + '/>',
      function: Boolean begin Result := Client.Status.StartsWith('ERROR') end),
      'a root that is not an element: ' + Client.Status);
    Check(TickUntil(Client, Path, '<TextBlock ' + Xmlns + ' Text="Grüße ✓ 日本語"/>',
      function: Boolean begin Result := Client.Status = 'OK' end), 'non-ASCII text renders');
    Check(not Client.Failed, 'malformed XAML never stops the preview');

    // Memory over many edits on one host
    for I := 1 to 300 do
    begin
      Client.Tick(Path, Good.Replace('Text="0"', Format('Text="%d"', [I])));
      if I = 50 then
        Memory50 := PrivateMB(Client.HostProcess);
    end;
    GuardMonitor(Client);
    Memory300 := PrivateMB(Client.HostProcess);
    Check((Client.Status = 'OK') and (Memory300 - Memory50 < 40),
      Format('300 edits on one host: %d MB after 50, %d MB after 300 (%s)', [Memory50, Memory300, Client.Status]));

    TerminateProcess(Client.HostProcess, 0); // what closing the window does
    WaitForSingleObject(Client.HostProcess, 5000);
    Check(TickUntil(Client, Path, Good, function: Boolean begin Result := Client.Closed end),
      'a host that exits with 0 means closed by the user (' + Client.Status + ')');
  finally
    Client.Free;
  end;

  // Start, edit, close: Destroy ends the host (the pipe closes)
  if Cycles = 0 then
    Cycles := 1;
  Ticks := GetTickCount;
  for I := 1 to Cycles do
  begin
    Client := TPreviewClient.Create(Exe);
    try
      if not TickUntil(Client, Path, Good, function: Boolean begin Result := Client.Status = 'OK' end) or
        not TickUntil(Client, Path, Broken, function: Boolean begin Result := Client.Status.StartsWith('ERROR') end) or
        not TickUntil(Client, Path, Good, function: Boolean begin Result := Client.Status = 'OK' end) then
      begin
        Check(False, Format('cycle %d: %s', [I, Client.Status]));
        Break;
      end;
      DuplicateHandle(GetCurrentProcess, Client.HostProcess, GetCurrentProcess, @Host, SYNCHRONIZE, False, 0);
    finally
      Client.Free;
    end;
    if WaitForSingleObject(Host, 10000) <> WAIT_OBJECT_0 then
    begin
      Check(False, Format('cycle %d: freeing the client did not end its host', [I]));
      Break;
    end;
    CloseHandle(Host);
    if I = Cycles then
      Check(True, Format('%d start/edit/close cycles, every host ended (%d ms each)',
        [Cycles, (GetTickCount - Ticks) div Cardinal(Cycles)]));
  end;
  // Closing the preview window (as a user does): the client ends Closed, and nothing of the
  // shutdown, such as an ERROR answer, comes out as an event
  Client := TPreviewClient.Create(Exe);
  try
    Check(TickUntil(Client, Path, Good, function: Boolean begin Result := Client.Status = 'OK' end),
      'a client for the close test');
    Find.Pid := GetProcessId(Client.HostProcess);
    Find.Wnd := 0;
    EnumWindows(@FindTopWindow, LPARAM(@Find));
    PostMessage(Find.Wnd, WM_CLOSE, 0, 0); // what the title bar's X does
    Events := '';
    Started := GetTickCount;
    repeat
      Client.Tick(Path, Good);
      while Client.TakeEvent(Event) do
        Events := Events + Event + ' ';
      Sleep(20);
    until Client.Closed or Client.Failed or (GetTickCount - Started > 20000);
    Check(Client.Closed and not Client.Failed, 'closing the preview window ends the client as Closed (' + Client.Status + ')');
    Check(Events = '', 'the shutdown reports no events (' + Events.Trim + ')');
  finally
    Client.Free;
  end;
  TestDockedPreview(Exe, Path, Good);
  if Failures > 0 then
  begin
    Writeln('Preview client test FAILED (', Failures, ')');
    Halt(1);
  end;
  Writeln('Preview client test PASSED');
end.
