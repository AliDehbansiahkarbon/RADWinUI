unit Notch.Tests;

{ Checks of the parts of Notch that need no window: the agent monitor fed
  with transcript lines and hook events, installing and removing the hooks,
  and the placement maths. Notch.exe -smoke-test runs them. }

interface

/// <summary>'' when every check passes, otherwise what failed. AFolder is an empty folder to work in.</summary>
function RunUnitTests(const AFolder: string): string;

implementation

uses
  System.SysUtils,
  System.Types,
  System.IOUtils,
  System.DateUtils,
  Notch.Settings,
  Notch.Agents,
  Notch.Usage,
  Notch.Placement;

type
  ECheck = class(Exception);

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise ECheck.Create(AMessage);
end;

function Later(ATime: TDateTime; ASeconds: Integer): TDateTime;
begin
  Result := IncSecond(ATime, ASeconds);
end;

procedure TestClaudeLines(AMonitor: TAgentMonitor; AStart: TDateTime);
const
  Prompt = '{"type":"user","cwd":"C:\\Work\\Demo","message":{"role":"user","content":"Fix the build"}}';
  Edit = '{"type":"assistant","cwd":"C:\\Work\\Demo","message":{"role":"assistant","stop_reason":"tool_use",' +
    '"content":[{"type":"tool_use","id":"t1","name":"Edit","input":{"file_path":"C:\\Work\\Demo\\Main.pas"}}]}}';
  Result_ = '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t1"}]}}';
  Shell = '{"type":"assistant","message":{"role":"assistant","stop_reason":"tool_use","content":[{"type":"tool_use",' +
    '"id":"t2","name":"PowerShell","input":{"command":".\\Build.ps1","description":"Build the project"}}]}}';
  Done = '{"type":"assistant","message":{"role":"assistant","stop_reason":"end_turn","content":[{"type":"text",' +
    '"text":"The build passes now.\nDetails follow."}]}}';
var
  S: TAgentSession;
begin
  S := AMonitor.Session(TAgentKind.ClaudeCode, 'claude-test.jsonl', AStart);
  AMonitor.FeedLine(S, Prompt, AStart);
  AMonitor.UpdateStates(AStart);
  Check((S.State = TAgentState.Working) and (S.Project = 'Demo') and (S.Activity = 'Thinking'),
    'Claude prompt: ' + StateNames[S.State] + ' ' + S.Project + ' ' + S.Activity);
  AMonitor.FeedLine(S, Edit, AStart);
  AMonitor.UpdateStates(Later(AStart, 2));
  Check((S.State = TAgentState.Working) and (S.Activity = 'Editing Main.pas'), 'Claude edit: ' + S.Activity);
  // An edit that does not go on for a while waits for approval
  AMonitor.UpdateStates(Later(AStart, NeedsYouSeconds + 1));
  Check(S.State = TAgentState.NeedsYou, 'Claude pending edit is ' + StateNames[S.State]);
  AMonitor.FeedLine(S, Result_, Later(AStart, 7));
  AMonitor.UpdateStates(Later(AStart, 7));
  Check(S.State = TAgentState.Working, 'Claude after the tool result: ' + StateNames[S.State]);
  // A shell command may run for a while before it counts as waiting
  AMonitor.FeedLine(S, Shell, Later(AStart, 8));
  AMonitor.UpdateStates(Later(AStart, 8 + NeedsYouSeconds + 1));
  Check((S.State = TAgentState.Working) and (S.Activity = 'Build the project'), 'Claude shell: ' + S.Activity);
  AMonitor.UpdateStates(Later(AStart, 8 + ShellNeedsYouSeconds + 1));
  Check(S.State = TAgentState.NeedsYou, 'Claude long shell is ' + StateNames[S.State]);
  AMonitor.FeedLine(S, Result_, Later(AStart, 40));
  AMonitor.FeedLine(S, Done, Later(AStart, 41));
  AMonitor.UpdateStates(Later(AStart, 42));
  Check((S.State = TAgentState.Finished) and (S.Activity = 'The build passes now.'),
    'Claude end of turn: ' + StateNames[S.State] + ' ' + S.Activity);
  AMonitor.UpdateStates(Later(AStart, 41 + FinishedSeconds + 1));
  Check(S.State = TAgentState.Idle, 'Claude a minute later: ' + StateNames[S.State]);
  AMonitor.UpdateStates(Later(AStart, 41 + DropSeconds + 1));
  Check(AMonitor.Sessions.IndexOf(S) < 0, 'A quiet Claude session was not dropped');
end;

procedure TestCodexLines(AMonitor: TAgentMonitor; AStart: TDateTime);
const
  Meta = '{"type":"session_meta","payload":{"id":"abc","cwd":"D:\\Code\\Shop"}}';
  Started = '{"type":"event_msg","payload":{"type":"task_started","turn_id":"t"}}';
  Exec = '{"type":"response_item","payload":{"type":"custom_tool_call","name":"exec","call_id":"c1","input":"ls"}}';
  Output = '{"type":"response_item","payload":{"type":"custom_tool_call_output","call_id":"c1"}}';
  Ask = '{"type":"response_item","payload":{"type":"function_call","name":"request_user_input_async",' +
    '"arguments":"{}","call_id":"c2"}}';
  Complete = '{"type":"event_msg","payload":{"type":"task_complete","last_agent_message":"All tests pass"}}';
var
  S: TAgentSession;
begin
  S := AMonitor.Session(TAgentKind.Codex, 'codex-test.jsonl', AStart);
  AMonitor.FeedLine(S, Meta, AStart);
  AMonitor.FeedLine(S, Started, AStart);
  AMonitor.FeedLine(S, Exec, AStart);
  AMonitor.UpdateStates(Later(AStart, 3));
  Check((S.State = TAgentState.Working) and (S.Project = 'Shop') and (S.Activity = 'Running a command'),
    'Codex exec: ' + StateNames[S.State] + ' ' + S.Project + ' ' + S.Activity);
  AMonitor.UpdateStates(Later(AStart, ShellNeedsYouSeconds + 1));
  Check(S.State = TAgentState.NeedsYou, 'Codex long exec is ' + StateNames[S.State]);
  AMonitor.FeedLine(S, Output, Later(AStart, 30));
  AMonitor.UpdateStates(Later(AStart, 30));
  Check(S.State = TAgentState.Working, 'Codex after output: ' + StateNames[S.State]);
  // A question to the user needs no waiting
  AMonitor.FeedLine(S, Ask, Later(AStart, 31));
  AMonitor.UpdateStates(Later(AStart, 31));
  Check(S.State = TAgentState.NeedsYou, 'Codex asking is ' + StateNames[S.State]);
  AMonitor.FeedLine(S, Complete, Later(AStart, 40));
  AMonitor.UpdateStates(Later(AStart, 41));
  Check((S.State = TAgentState.Finished) and (S.Activity = 'All tests pass'), 'Codex done: ' + S.Activity);
end;

procedure TestHookEvents(AMonitor: TAgentMonitor; AStart: TDateTime);
const
  Base = '{"session_id":"s9","transcript_path":"C:/Users/x/.claude/projects/p/s9.jsonl","cwd":"C:\\Work\\Hooked",';
var
  S: TAgentSession;
begin
  AMonitor.ApplyEvent(TAgentKind.ClaudeCode, Base + '"hook_event_name":"UserPromptSubmit","prompt":"go"}', AStart);
  AMonitor.ApplyEvent(TAgentKind.ClaudeCode, Base + '"hook_event_name":"PreToolUse","tool_name":"Write",' +
    '"tool_input":{"file_path":"C:\\Work\\Hooked\\a.txt"}}', AStart);
  AMonitor.UpdateStates(Later(AStart, 30));
  S := AMonitor.Active([TAgentKind.ClaudeCode])[0];
  // With hooks a slow tool is just slow, the Notification event says when it waits
  Check((S.State = TAgentState.Working) and (S.Project = 'Hooked') and (S.Activity = 'Editing a.txt'),
    'Hooked tool: ' + StateNames[S.State] + ' ' + S.Activity);
  AMonitor.ApplyEvent(TAgentKind.ClaudeCode, Base + '"hook_event_name":"Notification",' +
    '"message":"Claude needs your permission to use Write"}', Later(AStart, 31));
  AMonitor.UpdateStates(Later(AStart, 31));
  Check(S.State = TAgentState.NeedsYou, 'Hooked notification is ' + StateNames[S.State]);
  AMonitor.ApplyEvent(TAgentKind.ClaudeCode, Base + '"hook_event_name":"PostToolUse","tool_name":"Write"}',
    Later(AStart, 32));
  AMonitor.ApplyEvent(TAgentKind.ClaudeCode, Base + '"hook_event_name":"Stop"}', Later(AStart, 33));
  AMonitor.UpdateStates(Later(AStart, 33));
  Check(S.State = TAgentState.Finished, 'Hooked stop is ' + StateNames[S.State]);
  AMonitor.ApplyEvent(TAgentKind.ClaudeCode, Base + '"hook_event_name":"SessionEnd"}', Later(AStart, 34));
  Check(Length(AMonitor.Active([TAgentKind.ClaudeCode])) = 0, 'SessionEnd did not end the session');
  // Later than the Codex session of TestCodexLines, which is idle by then
  AMonitor.ApplyEvent(TAgentKind.Codex, '{"type":"agent-turn-complete","thread-id":"t42","cwd":"D:\\Apps\\Mail",' +
    '"last-assistant-message":"Sent"}', Later(AStart, 120));
  AMonitor.UpdateStates(Later(AStart, 121));
  S := AMonitor.Active([TAgentKind.Codex])[0];
  Check((S.State = TAgentState.Finished) and (S.Project = 'Mail') and (S.Activity = 'Sent'),
    'Codex notify: ' + StateNames[S.State] + ' ' + S.Project + ' ' + S.Activity);
end;

// Like the agents write them: UTF-8 without a byte order mark
procedure WriteText(const AFileName, AText: string; AAppend: Boolean = False);
var
  Bytes: TBytes;
begin
  Bytes := TEncoding.UTF8.GetBytes(AText);
  if AAppend then
    Bytes := TFile.ReadAllBytes(AFileName) + Bytes;
  TFile.WriteAllBytes(AFileName, Bytes);
end;

procedure TestFiles(const AFolder: string);
var
  Monitor: TAgentMonitor;
  ClaudeRoot, CodexRoot, Events, FileName: string;
  Sessions: TArray<TAgentSession>;
begin
  ClaudeRoot := TPath.Combine(AFolder, 'claude');
  CodexRoot := TPath.Combine(AFolder, 'codex');
  Events := TPath.Combine(AFolder, 'events');
  ForceDirectories(TPath.Combine(ClaudeRoot, 'C--Work-Files'));
  ForceDirectories(Events);
  Check(TAgentMonitor.Detect(ClaudeRoot, CodexRoot) = [TAgentKind.ClaudeCode], 'Agent detection');
  FileName := TPath.Combine(ClaudeRoot, 'C--Work-Files\one.jsonl');
  // The last line is still being written: it must wait for its line break
  WriteText(FileName, '{"type":"user","cwd":"C:\\Work\\Files","message":{"content":"hi"}}' + #10 +
    '{"type":"assistant","message":{"stop_reason":"end_turn","content":[{"type":"text","text":"Hel');
  WriteText(TPath.Combine(Events, 'codex-20260101000000000-1.json'),
    '{"type":"agent-turn-complete","thread-id":"z","cwd":"D:\\Mail","last-assistant-message":"Sent"}');
  Monitor := TAgentMonitor.Create(ClaudeRoot, CodexRoot, Events);
  try
    Monitor.Poll(Now);
    Sessions := Monitor.Active([TAgentKind.ClaudeCode]);
    Check((Length(Sessions) = 1) and (Sessions[0].Project = 'Files') and (Sessions[0].State = TAgentState.Working),
      'A transcript file on disk was not picked up');
    Check(Length(Monitor.Active([TAgentKind.Codex])) = 1, 'An event file was not read');
    Check(Length(TDirectory.GetFiles(Events)) = 0, 'An event file was not removed after reading');
    WriteText(FileName, 'lo"}]}}' + #10, True);
    Monitor.Poll(Now);
    Check((Sessions[0].State = TAgentState.Finished) and (Sessions[0].Activity = 'Hello'),
      'The rest of a line was not read: ' + StateNames[Sessions[0].State] + ' ' + Sessions[0].Activity);
  finally
    Monitor.Free;
  end;
end;

procedure TestHooksInstall(const AFolder: string);
const
  // Someone else's hook, which has to survive
  Existing = '{"model":"x","hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"other start"}]}],' +
    '"Stop":[{"hooks":[{"type":"command","command":"other stop"}]}]}}';
  Exe = 'C:\Apps\Notch\Notch.exe';
var
  Settings, Config, Text: string;
begin
  Settings := TPath.Combine(AFolder, 'settings.json');
  WriteText(Settings, Existing);
  InstallClaudeHooks(Settings, Exe);
  InstallClaudeHooks(Settings, Exe);
  Text := TFile.ReadAllText(Settings);
  Check(ClaudeHooksInstalled(Settings), 'Claude hooks not installed');
  Check(Text.Contains('other start') and Text.Contains('other stop') and Text.Contains('"model"'),
    'Installing the hooks lost other settings');
  Check(Length(Text.Split(['--agent-event claude'])) - 1 = 6, 'Installing twice did not keep one hook per event');
  Check(TFile.Exists(Settings + '.notch-backup'), 'No backup of the Claude settings');
  Check(TFile.ReadAllBytes(Settings)[0] = Ord('{'), 'The Claude settings got a byte order mark');
  RemoveClaudeHooks(Settings);
  Text := TFile.ReadAllText(Settings);
  Check(not ClaudeHooksInstalled(Settings) and Text.Contains('other start') and Text.Contains('other stop'),
    'Removing the hooks removed too much or too little');
  Config := TPath.Combine(AFolder, 'config.toml');
  WriteText(Config, 'model = "gpt"' + sLineBreak + '[profiles.fast]' + sLineBreak + 'model = "mini"' +
    sLineBreak);
  Check(InstallCodexNotify(Config, Exe) = '', 'Codex notify not installed');
  Text := TFile.ReadAllText(Config);
  Check(Text.StartsWith('notify = ["C:/Apps/Notch/Notch.exe", "--agent-event", "codex"]') and
    Text.Contains('[profiles.fast]'), 'Codex notify is not a top-level key: ' + Text);
  RemoveCodexNotify(Config);
  Check(not CodexNotifyInstalled(Config) and TFile.ReadAllText(Config).Contains('model = "mini"'),
    'Removing Codex notify');
  WriteText(Config, 'notify = ["other"]' + sLineBreak);
  Check(InstallCodexNotify(Config, Exe) <> '', 'Another notify command was replaced');
end;

procedure TestPlacement;
var
  Work, Outer: TRect;
  P: TPoint;
  Edge: TNotchEdge;
  Offset: Double;
begin
  Outer := TRect.Create(0, 0, 1920, 1080);
  Work := TRect.Create(0, 0, 1920, 1032);
  P := EdgePosition(TNotchEdge.Top, 0.5, Outer, Work, TSize.Create(800, 300));
  Check((P.X = 560) and (P.Y = 0), Format('Top centre at %d,%d', [P.X, P.Y]));
  P := EdgePosition(TNotchEdge.Bottom, 0.5, Outer, Work, TSize.Create(800, 300));
  Check(P.Y = 1032 - 300, 'Bottom stays above the taskbar');
  P := EdgePosition(TNotchEdge.Right, 0, Outer, Work, TSize.Create(300, 800));
  Check((P.X = 1620) and (P.Y = 0), 'Right edge, kept on the screen');
  NearestEdge(TPoint.Create(30, 500), Work, Edge, Offset);
  Check((Edge = TNotchEdge.Left) and (Abs(Offset - 500 / 1032) < 0.001), 'Dropped near the left edge');
  NearestEdge(TPoint.Create(960, 1020), Work, Edge, Offset);
  Check((Edge = TNotchEdge.Bottom) and (Abs(Offset - 0.5) < 0.001), 'Dropped near the bottom');
  Check(TileDropIndex([200, 100, 300], 10, 0, 0) = 0, 'Tile not moved');
  Check(TileDropIndex([200, 100, 300], 10, 0, 170) = 1, 'Tile moved past one');
  Check(TileDropIndex([200, 100, 300], 10, 0, 500) = 2, 'Tile moved to the end');
  Check(TileDropIndex([200, 100, 300], 10, 2, -400) = 0, 'Tile moved to the front');
end;

function Point(ATime: TDateTime; ATokens: Int64): TUsagePoint;
begin
  Result.Time := ATime;
  Result.Tokens := ATokens;
end;

procedure TestExactClaude(const AFolder: string);
const
  Answer = '{"five_hour":{"utilization":37.0,"resets_at":"2026-10-30T15:00:00Z"},' +
    '"seven_day":{"utilization":12.5,"resets_at":"2026-11-02T09:00:00Z"},"seven_day_opus":null,' +
    '"extra_usage":{"is_enabled":false}}';
var
  Windows: TArray<TUsageWindow>;
  Token, Status, Credentials: string;
  Monitor: TUsageMonitor;
  Fetched: Integer;
  Window: TUsageWindow;
  Exact: Boolean;
begin
  Windows := ClaudeExactWindows(Answer);
  Check((Length(Windows) = 2) and (Windows[0].Percent = 37) and (Windows[1].Percent = 12.5) and
    not Windows[0].Estimate and (Windows[0].ResetsAt > 0), 'Exact Claude usage JSON');
  Check(Length(ClaudeExactWindows('not json')) = 0, 'A broken answer gives no windows');
  Credentials := TPath.Combine(AFolder, 'credentials.json');
  WriteText(Credentials, '{"claudeAiOauth":{"accessToken":"test-token","expiresAt":1000}}');
  Check(not ReadClaudeToken(Credentials, Now, Token, Status) and (Token = '') and Status.Contains('refresh'),
    'An expired login is not used');
  WriteText(Credentials, '{"claudeAiOauth":{"accessToken":"test-token","expiresAt":' +
    IntToStr((DateTimeToUnix(Now, False) + 3600) * 1000) + '}}');
  Check(ReadClaudeToken(Credentials, Now, Token, Status) and (Token = 'test-token'), 'A valid login');
  Monitor := TUsageMonitor.Create(TPath.Combine(AFolder, 'none'), TPath.Combine(AFolder, 'none'));
  try
    Monitor.CredentialsFile := Credentials;
    Fetched := 0;
    Monitor.Fetch :=
      function(const AToken: string): string
      begin
        Inc(Fetched);
        if AToken <> 'test-token' then
          raise Exception.Create('wrong token');
        Result := Answer;
      end;
    // Off: no login read, no request
    Monitor.Update;
    Check((Monitor.ExactAttempts = 0) and (Fetched = 0), 'Exact limits off still asked');
    Monitor.Exact := True;
    Monitor.Update;
    Windows := Monitor.Windows([TAgentKind.ClaudeCode]);
    Check((Fetched = 1) and (Length(Windows) = 2) and not Windows[0].Estimate and (Monitor.ExactStatus = ''),
      'Exact limits on');
    Monitor.Fetch :=
      function(const AToken: string): string
      begin
        raise Exception.Create('offline');
      end;
    Monitor.Update;
    Exact := False;
    for Window in Monitor.Windows([TAgentKind.ClaudeCode]) do
      Exact := Exact or not Window.Estimate;
    Check(not Exact and Monitor.ExactStatus.Contains('unavailable'), 'A failed request falls back to the estimate');
  finally
    Monitor.Free;
  end;
end;

procedure TestUsage(AStart: TDateTime);
var
  Windows: TArray<TUsageWindow>;
begin
  // Two answers in one block, then one six hours later starts a new block
  Windows := ClaudeWindows([Point(AStart, 100), Point(IncHour(AStart, 1), 200), Point(IncHour(AStart, 6), 50)],
    IncMinute(IncHour(AStart, 6), 30));
  Check((Windows[0].Tokens = 50) and (Windows[1].Tokens = 350), 'Claude blocks: ' + Windows[0].Tokens.ToString +
    ' / ' + Windows[1].Tokens.ToString);
  Check(Windows[0].Summary(IncMinute(IncHour(AStart, 6), 30)) = '50 tokens, resets in 4 h 30 min (estimate)',
    'Claude block summary: ' + Windows[0].Summary(IncMinute(IncHour(AStart, 6), 30)));
  // Long after the last answer no block runs
  Windows := ClaudeWindows([Point(AStart, 100)], IncHour(AStart, 8));
  Check((Windows[0].Tokens = 0) and (Windows[1].Tokens = 100), 'Claude without a running block');
  Windows := CodexWindows(['{"type":"event_msg","payload":{"type":"token_count","rate_limits":{"primary":' +
    '{"used_percent":100.0,"window_minutes":300,"resets_at":1000}}}}', 'other line']);
  // Reported full, but the window started again since: nothing used in it now
  Check((Length(Windows) = 1) and (Windows[0].Percent = 100) and (Windows[0].PercentAt(Now) = 0) and
    (Windows[0].Title = 'Current session (5 hours)') and Windows[0].Summary(Now).Contains('no use since'),
    'Codex limits after a reset: ' + Windows[0].Summary(Now));
end;

function RunUnitTests(const AFolder: string): string;
var
  Monitor: TAgentMonitor;
  Start: TDateTime;
begin
  Result := '';
  try
    ForceDirectories(AFolder);
    // No folders to read: only what the tests feed in
    Monitor := TAgentMonitor.Create(TPath.Combine(AFolder, 'none'), TPath.Combine(AFolder, 'none'),
      TPath.Combine(AFolder, 'none'));
    try
      Start := EncodeDateTime(2026, 10, 30, 9, 0, 0, 0);
      TestClaudeLines(Monitor, Start);
      TestCodexLines(Monitor, Start);
      TestHookEvents(Monitor, Start);
      TestUsage(Start);
    finally
      Monitor.Free;
    end;
    TestFiles(TPath.Combine(AFolder, 'files'));
    TestExactClaude(AFolder);
    TestHooksInstall(AFolder);
    TestPlacement;
  except
    on E: Exception do
      Result := E.Message;
  end;
end;

end.
