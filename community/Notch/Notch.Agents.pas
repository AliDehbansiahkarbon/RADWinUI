unit Notch.Agents;

{ What the AI coding agents on this PC are doing. Claude Code and Codex write
  every session to a JSON-lines transcript, the monitor reads the new lines of
  the recent ones and derives a state per session. Hooks, when installed, send
  exact events through Notch.exe --agent-event into a folder the monitor reads. }

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TAgentKind = (ClaudeCode, Codex);
  TAgentKinds = set of TAgentKind;
  // In order of urgency
  TAgentState = (Idle, Finished, Working, NeedsYou);

  TAgentSession = class
  public
    Kind: TAgentKind;
    FileName: string;
    Id: string;
    Project: string;
    Activity: string;
    TurnStarted: TDateTime;
    LastChange: TDateTime;
    State: TAgentState;
    // What the transcript or the hooks said last
    TurnEnded: Boolean;
    PendingTool: string;
    PendingShell: Boolean;
    Asking: Boolean;
    Hooked: Boolean;
    Offset: Int64;
    /// <summary>"Working, 3 min" or "Finished 20 s ago".</summary>
    function Elapsed(ANow: TDateTime): string;
  end;

  TAgentMonitor = class
  strict private
    FClaudeRoot: string;
    FCodexRoot: string;
    FEventsFolder: string;
    FSessions: TObjectList<TAgentSession>;
    FLastScan: TDateTime;
    FKinds: TAgentKinds;
    function FindSession(const AFileName: string): TAgentSession;
    function AddSession(AKind: TAgentKind; const AFileName: string; ANow: TDateTime): TAgentSession;
    procedure ScanFiles(ANow: TDateTime);
    procedure ReadNew(ASession: TAgentSession; ANow: TDateTime);
    procedure ReadEvents(ANow: TDateTime);
    procedure FeedClaude(ASession: TAgentSession; const ALine: string; ANow: TDateTime);
    procedure FeedCodex(ASession: TAgentSession; const ALine: string; ANow: TDateTime);
  public
    constructor Create(const AClaudeRoot, ACodexRoot, AEventsFolder: string);
    destructor Destroy; override;
    /// <summary>Reads what changed and updates every state. Call it about once a second.</summary>
    procedure Poll(ANow: TDateTime);
    /// <summary>Works one transcript line into ASession. Poll calls it, tests too.</summary>
    procedure FeedLine(ASession: TAgentSession; const ALine: string; ANow: TDateTime);
    /// <summary>Works one hook event (the JSON the agent passed) into the sessions.</summary>
    procedure ApplyEvent(AKind: TAgentKind; const AJson: string; ANow: TDateTime);
    /// <summary>Derives each session's State at ANow and drops sessions quiet for too long.</summary>
    procedure UpdateStates(ANow: TDateTime);
    /// <summary>The sessions of AKinds, most urgent first, then the most recent.</summary>
    function Active(AKinds: TAgentKinds): TArray<TAgentSession>;
    function Session(AKind: TAgentKind; const AFileName: string; ANow: TDateTime): TAgentSession;
    /// <summary>The agents to watch, the others are not read at all.</summary>
    property Kinds: TAgentKinds read FKinds write FKinds;
    property Sessions: TObjectList<TAgentSession> read FSessions;
    property EventsFolder: string read FEventsFolder;
    /// <summary>The agents that have written sessions on this PC.</summary>
    class function Detect(const AClaudeRoot, ACodexRoot: string): TAgentKinds; static;
    class function DefaultClaudeRoot: string; static;
    class function DefaultCodexRoot: string; static;
  end;

const
  AgentIds: array[TAgentKind] of string = ('claude-code', 'codex');
  AgentNames: array[TAgentKind] of string = ('Claude Code', 'Codex');
  AgentHookNames: array[TAgentKind] of string = ('claude', 'codex');
  StateNames: array[TAgentState] of string = ('Idle', 'Finished', 'Working', 'Needs you');
  // Blue idle, green finished, red busy, amber waiting for you
  StateColors: array[TAgentState] of Cardinal = ($FF4C9BFF, $FF3DDC84, $FFFF453A, $FFFFB020);
  AgentLegend = 'Red: working. Amber: needs you. Green: finished. Blue: idle.';
  // A pending tool with no progress for this long is most likely waiting for approval.
  // Shell commands get longer, a build runs for a while.
  NeedsYouSeconds = 5;
  ShellNeedsYouSeconds = 20;
  // Finished stays green until the next activity or ten minutes, then the session is idle for a while
  FinishedSeconds = 10 * 60;
  StaleWorkingSeconds = 180;
  DropSeconds = 15 * 60;

function AgentKindOf(const AId: string; out AKind: TAgentKind): Boolean;
/// <summary>What a tool call is doing, in a few words: "Editing MainWindow.pas".</summary>
function DescribeTool(const AName, AInputJson: string): string;

/// <summary>Notch.exe --agent-event claude|codex [json]: stores the event and returns at once.</summary>
procedure SaveAgentEvent(const AFolder: string);

/// <summary>The command line the hooks run.</summary>
function HookCommand(const AExe: string; AKind: TAgentKind): string;
/// <summary>Adds the Notch hooks to a Claude Code settings.json, keeping every other hook. Backs the file up first.</summary>
procedure InstallClaudeHooks(const ASettingsFile, AExe: string);
procedure RemoveClaudeHooks(const ASettingsFile: string);
function ClaudeHooksInstalled(const ASettingsFile: string): Boolean;
/// <summary>Sets notify in a Codex config.toml. Returns '' or why it left the file as it was.</summary>
function InstallCodexNotify(const AConfigFile, AExe: string): string;
procedure RemoveCodexNotify(const AConfigFile: string);
function CodexNotifyInstalled(const AConfigFile: string): Boolean;

implementation

uses
  Winapi.Windows,
  Winapi.ShellAPI,
  System.Classes,
  System.IOUtils,
  System.DateUtils,
  System.StrUtils,
  System.Math,
  System.JSON,
  System.Generics.Defaults;

const
  // A new file is read from this far before its end, longer lines are skipped
  FirstReadBytes = 256 * 1024;
  MaxLineBytes = 512 * 1024;
  ScanSeconds = 5;
  HookEvents: array[0..5] of string = ('UserPromptSubmit', 'PreToolUse', 'PostToolUse', 'Notification', 'Stop',
    'SessionEnd');
  HookMarker = '--agent-event';

function SecondsBetweenTimes(AFrom, ATo: TDateTime): Double;
begin
  Result := (ATo - AFrom) * SecsPerDay;
end;

function Snippet(const AText: string): string;
var
  Lines: TArray<string>;
begin
  Result := '';
  Lines := AText.Trim.Split([#10]);
  if Length(Lines) > 0 then
    Result := Lines[0].Trim;
  if Length(Result) > 90 then
    Result := Copy(Result, 1, 87) + '...';
end;

function AgentKindOf(const AId: string; out AKind: TAgentKind): Boolean;
var
  Kind: TAgentKind;
begin
  for Kind := Low(TAgentKind) to High(TAgentKind) do
    if SameText(AgentIds[Kind], AId) or SameText(AgentHookNames[Kind], AId) then
    begin
      AKind := Kind;
      Exit(True);
    end;
  Result := False;
end;

function DescribeTool(const AName, AInputJson: string): string;
var
  Input: TJSONValue;
  Text: string;

  function Field(const AKey: string): string;
  begin
    Result := '';
    if Input is TJSONObject then
      Result := Input.GetValue<string>(AKey, '');
  end;

begin
  try
    Input := TJSONObject.ParseJSONValue(AInputJson);
  except
    Input := nil;
  end;
  try
    if MatchStr(AName, ['Bash', 'PowerShell']) then
    begin
      Text := Field('description');
      if Text = '' then
        Text := 'Running ' + Snippet(Field('command'));
      Result := Text;
    end
    else if MatchStr(AName, ['Edit', 'MultiEdit', 'Write', 'NotebookEdit']) then
      Result := 'Editing ' + ExtractFileName(Field('file_path'))
    else if AName = 'Read' then
      Result := 'Reading ' + ExtractFileName(Field('file_path'))
    else if MatchStr(AName, ['Grep', 'Glob']) then
      Result := 'Searching the code'
    else if MatchStr(AName, ['WebFetch', 'WebSearch']) then
      Result := 'Searching the web'
    else if MatchStr(AName, ['Task', 'Agent']) then
      Result := 'Running a subagent'
    else if AName = 'TodoWrite' then
      Result := 'Planning'
    else if MatchStr(AName, ['exec', 'shell', 'local_shell', 'exec_command']) then
      Result := 'Running a command'
    else if AName = 'apply_patch' then
      Result := 'Editing files'
    else
      Result := 'Using ' + AName;
  finally
    Input.Free;
  end;
end;

{ TAgentSession }

function TAgentSession.Elapsed(ANow: TDateTime): string;
var
  Seconds: Int64;
begin
  if State in [TAgentState.Finished, TAgentState.Idle] then
    Seconds := Round(SecondsBetweenTimes(LastChange, ANow))
  else
    Seconds := Round(SecondsBetweenTimes(TurnStarted, ANow));
  Seconds := Max(0, Seconds);
  if Seconds < 60 then
    Result := Format('%d s', [Seconds])
  else if Seconds < 3600 then
    Result := Format('%d min', [Seconds div 60])
  else
    Result := Format('%d h %d min', [Seconds div 3600, Seconds mod 3600 div 60]);
  if State in [TAgentState.Finished, TAgentState.Idle] then
    Result := Result + ' ago';
end;

{ TAgentMonitor }

constructor TAgentMonitor.Create(const AClaudeRoot, ACodexRoot, AEventsFolder: string);
begin
  inherited Create;
  FClaudeRoot := AClaudeRoot;
  FCodexRoot := ACodexRoot;
  FEventsFolder := AEventsFolder;
  FSessions := TObjectList<TAgentSession>.Create;
  FKinds := [TAgentKind.ClaudeCode, TAgentKind.Codex];
end;

destructor TAgentMonitor.Destroy;
begin
  FSessions.Free;
  inherited;
end;

class function TAgentMonitor.DefaultClaudeRoot: string;
begin
  Result := TPath.Combine(GetEnvironmentVariable('USERPROFILE'), '.claude\projects');
end;

class function TAgentMonitor.DefaultCodexRoot: string;
begin
  Result := TPath.Combine(GetEnvironmentVariable('USERPROFILE'), '.codex\sessions');
end;

class function TAgentMonitor.Detect(const AClaudeRoot, ACodexRoot: string): TAgentKinds;
begin
  Result := [];
  if TDirectory.Exists(AClaudeRoot) then
    Include(Result, TAgentKind.ClaudeCode);
  if TDirectory.Exists(ACodexRoot) then
    Include(Result, TAgentKind.Codex);
end;

function TAgentMonitor.FindSession(const AFileName: string): TAgentSession;
var
  S: TAgentSession;
begin
  for S in FSessions do
    if SameText(S.FileName, AFileName) then
      Exit(S);
  Result := nil;
end;

function TAgentMonitor.AddSession(AKind: TAgentKind; const AFileName: string; ANow: TDateTime): TAgentSession;
begin
  Result := TAgentSession.Create;
  FSessions.Add(Result);
  Result.Kind := AKind;
  Result.FileName := AFileName;
  Result.Id := ChangeFileExt(ExtractFileName(AFileName), '');
  Result.Project := '';
  Result.TurnStarted := ANow;
  Result.LastChange := ANow;
  Result.Activity := 'Working';
end;

function TAgentMonitor.Session(AKind: TAgentKind; const AFileName: string; ANow: TDateTime): TAgentSession;
begin
  Result := FindSession(AFileName);
  if Result = nil then
    Result := AddSession(AKind, AFileName, ANow);
end;

procedure TAgentMonitor.ScanFiles(ANow: TDateTime);

  procedure Consider(AKind: TAgentKind; const AFileName: string);
  var
    Session: TAgentSession;
  begin
    if (FindSession(AFileName) <> nil) or (SecondsBetweenTimes(TFile.GetLastWriteTime(AFileName), Now) > DropSeconds) then
      Exit;
    Session := AddSession(AKind, AFileName, ANow);
    // Only what happens from now on, plus enough of the end to know where it stands
    Session.Offset := Max(0, TFile.GetSize(AFileName) - FirstReadBytes);
    Session.LastChange := TFile.GetLastWriteTime(AFileName);
    ReadNew(Session, ANow);
    Session.LastChange := TFile.GetLastWriteTime(AFileName);
  end;

var
  Folder, FileName: string;
  Day: TDateTime;
begin
  FLastScan := ANow;
  if (TAgentKind.ClaudeCode in FKinds) and TDirectory.Exists(FClaudeRoot) then
    for Folder in TDirectory.GetDirectories(FClaudeRoot) do
      for FileName in TDirectory.GetFiles(Folder, '*.jsonl') do
        Consider(TAgentKind.ClaudeCode, FileName);
  if (TAgentKind.Codex in FKinds) and TDirectory.Exists(FCodexRoot) then
    // Codex files its sessions by day: today and yesterday cover a session that runs over midnight
    for Day in [Date, Date - 1] do
    begin
      Folder := TPath.Combine(FCodexRoot, FormatDateTime('yyyy"\"mm"\"dd', Day));
      if TDirectory.Exists(Folder) then
        for FileName in TDirectory.GetFiles(Folder, '*.jsonl') do
          Consider(TAgentKind.Codex, FileName);
    end;
end;

procedure TAgentMonitor.ReadNew(ASession: TAgentSession; ANow: TDateTime);
var
  Stream: TFileStream;
  Size: Int64;
  Bytes: TBytes;
  Start, I: Integer;
  SkipFirst: Boolean;
begin
  if (ASession.FileName = '') or not TFile.Exists(ASession.FileName) then
    Exit;
  Stream := TFileStream.Create(ASession.FileName, fmOpenRead or fmShareDenyNone);
  try
    Size := Stream.Size;
    if Size < ASession.Offset then
      ASession.Offset := 0;
    if Size = ASession.Offset then
      Exit;
    SkipFirst := False;
    // A long silence and then a lot at once: the end is what matters
    if Size - ASession.Offset > 4 * FirstReadBytes then
    begin
      ASession.Offset := Size - FirstReadBytes;
      SkipFirst := True;
    end
    else if ASession.Offset > 0 then
    begin
      // Starts mid-line unless the byte before is a line break
      Stream.Position := ASession.Offset - 1;
      SetLength(Bytes, 1);
      Stream.ReadBuffer(Bytes[0], 1);
      SkipFirst := Bytes[0] <> 10;
    end;
    SetLength(Bytes, Size - ASession.Offset);
    Stream.Position := ASession.Offset;
    Stream.ReadBuffer(Bytes[0], Length(Bytes));
  finally
    Stream.Free;
  end;
  Start := 0;
  for I := 0 to High(Bytes) do
    if Bytes[I] = 10 then
    begin
      if SkipFirst then
        SkipFirst := False
      else if (I - Start > 1) and (I - Start <= MaxLineBytes) then
        FeedLine(ASession, TEncoding.UTF8.GetString(Bytes, Start, I - Start), ANow);
      Start := I + 1;
    end;
  // A line still being written waits for the next read
  Inc(ASession.Offset, Start);
end;

procedure TAgentMonitor.FeedLine(ASession: TAgentSession; const ALine: string; ANow: TDateTime);
begin
  ASession.LastChange := ANow;
  if ASession.Kind = TAgentKind.ClaudeCode then
    FeedClaude(ASession, ALine, ANow)
  else
    FeedCodex(ASession, ALine, ANow);
end;

function ParseObject(const ALine: string): TJSONObject;
var
  Value: TJSONValue;
begin
  try
    Value := TJSONObject.ParseJSONValue(ALine);
  except
    Value := nil;
  end;
  if Value is TJSONObject then
    Result := TJSONObject(Value)
  else
  begin
    Value.Free;
    Result := nil;
  end;
end;

function ProjectOf(const ACwd: string): string;
begin
  Result := ExtractFileName(ExcludeTrailingPathDelimiter(ACwd.Replace('/', '\')));
end;

procedure StartTurn(ASession: TAgentSession; ANow: TDateTime);
begin
  if ASession.TurnEnded then
    ASession.TurnStarted := ANow;
  ASession.TurnEnded := False;
  ASession.Asking := False;
  ASession.PendingTool := '';
end;

procedure TAgentMonitor.FeedClaude(ASession: TAgentSession; const ALine: string; ANow: TDateTime);
var
  Line, Message: TJSONObject;
  Content: TJSONValue;
  Item: TJSONValue;
  Kind, ItemType, Text, Stop: string;
  HasToolUse: Boolean;
begin
  Line := ParseObject(ALine);
  if Line = nil then
    Exit;
  try
    if Line.GetValue<string>('cwd', '') <> '' then
      ASession.Project := ProjectOf(Line.GetValue<string>('cwd', ''));
    Kind := Line.GetValue<string>('type', '');
    if not ((Kind = 'user') or (Kind = 'assistant')) or not (Line.FindValue('message') is TJSONObject) then
      Exit;
    Message := TJSONObject(Line.FindValue('message'));
    Content := Message.FindValue('content');
    if Kind = 'user' then
    begin
      // A prompt starts a turn, a tool result means the tool ran and the model goes on
      if not (Content is TJSONArray) then
      begin
        StartTurn(ASession, ANow);
        ASession.Activity := 'Thinking';
        Exit;
      end;
      for Item in TJSONArray(Content) do
      begin
        ItemType := Item.GetValue<string>('type', '');
        if ItemType = 'tool_result' then
        begin
          ASession.PendingTool := '';
          ASession.Asking := False;
          ASession.TurnEnded := False;
        end
        else if ItemType = 'text' then
        begin
          StartTurn(ASession, ANow);
          ASession.Activity := 'Thinking';
        end;
      end;
      Exit;
    end;
    // assistant
    if ASession.TurnEnded then
      StartTurn(ASession, ANow);
    ASession.Asking := False;
    HasToolUse := False;
    Text := '';
    if Content is TJSONArray then
      for Item in TJSONArray(Content) do
      begin
        ItemType := Item.GetValue<string>('type', '');
        if ItemType = 'tool_use' then
        begin
          HasToolUse := True;
          ASession.PendingTool := Item.GetValue<string>('name', '');
          ASession.PendingShell := MatchStr(ASession.PendingTool, ['Bash', 'PowerShell']);
          if Item.FindValue('input') <> nil then
            ASession.Activity := DescribeTool(ASession.PendingTool, Item.FindValue('input').ToJSON)
          else
            ASession.Activity := DescribeTool(ASession.PendingTool, '{}');
        end
        else if ItemType = 'text' then
          Text := Item.GetValue<string>('text', '')
        else if ItemType = 'thinking' then
          ASession.Activity := 'Thinking';
      end;
    Stop := Message.GetValue<string>('stop_reason', '');
    if (Stop = 'end_turn') and not HasToolUse then
    begin
      ASession.TurnEnded := True;
      ASession.PendingTool := '';
      if Text <> '' then
        ASession.Activity := Snippet(Text)
      else
        ASession.Activity := 'Done';
    end
    else if (Text <> '') and not HasToolUse then
      ASession.Activity := 'Writing: ' + Snippet(Text);
  finally
    Line.Free;
  end;
end;

procedure TAgentMonitor.FeedCodex(ASession: TAgentSession; const ALine: string; ANow: TDateTime);
var
  Line, Payload: TJSONObject;
  Kind, PayloadType, Name: string;
begin
  Line := ParseObject(ALine);
  if Line = nil then
    Exit;
  try
    Kind := Line.GetValue<string>('type', '');
    if not (Line.FindValue('payload') is TJSONObject) then
      Exit;
    Payload := TJSONObject(Line.FindValue('payload'));
    PayloadType := Payload.GetValue<string>('type', '');
    if Payload.GetValue<string>('cwd', '') <> '' then
      ASession.Project := ProjectOf(Payload.GetValue<string>('cwd', ''));
    if Kind = 'event_msg' then
    begin
      if PayloadType = 'task_started' then
      begin
        StartTurn(ASession, ANow);
        ASession.TurnStarted := ANow;
        ASession.Activity := 'Thinking';
      end
      else if PayloadType = 'task_complete' then
      begin
        ASession.TurnEnded := True;
        ASession.PendingTool := '';
        ASession.Asking := False;
        ASession.Activity := Snippet(Payload.GetValue<string>('last_agent_message', ''));
        if ASession.Activity = '' then
          ASession.Activity := 'Done';
      end
      else if PayloadType = 'turn_aborted' then
      begin
        ASession.TurnEnded := True;
        ASession.PendingTool := '';
        ASession.Asking := False;
        ASession.Activity := 'Stopped';
      end
      else if PayloadType.Contains('approval') or PayloadType.Contains('request_user_input') then
      begin
        ASession.Asking := True;
        ASession.Activity := 'Waiting for your approval';
      end
      else if PayloadType = 'agent_message' then
        ASession.Activity := Snippet(Payload.GetValue<string>('message', ''));
    end
    else if Kind = 'response_item' then
    begin
      if MatchStr(PayloadType, ['function_call', 'custom_tool_call', 'local_shell_call']) then
      begin
        Name := Payload.GetValue<string>('name', PayloadType);
        if ASession.TurnEnded then
          StartTurn(ASession, ANow);
        ASession.PendingTool := Name;
        ASession.PendingShell := MatchStr(Name, ['exec', 'shell', 'local_shell', 'exec_command', 'local_shell_call']);
        ASession.Activity := DescribeTool(Name, Payload.GetValue<string>('arguments', '{}'));
        if Name.Contains('request_user_input') or Name.Contains('approval') then
        begin
          ASession.Asking := True;
          ASession.Activity := 'Waiting for your answer';
        end;
      end
      else if PayloadType.EndsWith('_output') then
      begin
        ASession.PendingTool := '';
        ASession.Asking := False;
      end;
    end;
  finally
    Line.Free;
  end;
end;

procedure TAgentMonitor.ApplyEvent(AKind: TAgentKind; const AJson: string; ANow: TDateTime);
var
  Event: TJSONObject;
  S, Candidate: TAgentSession;
  Name, FileName, Id: string;
begin
  Event := ParseObject(AJson);
  if Event = nil then
    Exit;
  try
    S := nil;
    if AKind = TAgentKind.ClaudeCode then
    begin
      FileName := Event.GetValue<string>('transcript_path', '').Replace('/', '\');
      Id := Event.GetValue<string>('session_id', '');
      if FileName = '' then
        FileName := Id;
      S := FindSession(FileName);
      Name := Event.GetValue<string>('hook_event_name', '');
      if Name = 'SessionEnd' then
      begin
        if S <> nil then
          FSessions.Remove(S);
        Exit;
      end;
      if S = nil then
      begin
        S := AddSession(AKind, FileName, ANow);
        if TFile.Exists(FileName) then
          S.Offset := TFile.GetSize(FileName);
      end;
      if Event.GetValue<string>('cwd', '') <> '' then
        S.Project := ProjectOf(Event.GetValue<string>('cwd', ''));
      if Name = 'UserPromptSubmit' then
      begin
        StartTurn(S, ANow);
        S.TurnStarted := ANow;
        S.Activity := 'Thinking';
      end
      else if Name = 'PreToolUse' then
      begin
        S.TurnEnded := False;
        S.Asking := False;
        S.PendingTool := Event.GetValue<string>('tool_name', '');
        if Event.FindValue('tool_input') <> nil then
          S.Activity := DescribeTool(S.PendingTool, Event.FindValue('tool_input').ToJSON);
      end
      else if Name = 'PostToolUse' then
      begin
        S.PendingTool := '';
        S.Asking := False;
      end
      else if Name = 'Notification' then
      begin
        S.Asking := True;
        S.Activity := Snippet(Event.GetValue<string>('message', 'Needs your attention'));
      end
      else if Name = 'Stop' then
      begin
        S.TurnEnded := True;
        S.Asking := False;
        S.PendingTool := '';
        if S.Activity.StartsWith('Writing: ') then
          S.Activity := Copy(S.Activity, 10, MaxInt);
      end;
    end
    else
    begin
      // Codex notify: agent-turn-complete, with the thread id that names its rollout file
      Id := Event.GetValue<string>('thread-id', '');
      for Candidate in FSessions do
        if (Candidate.Kind = TAgentKind.Codex) and (Id <> '') and Candidate.FileName.Contains(Id) then
          S := Candidate;
      if S = nil then
        S := Session(AKind, 'codex:' + Id, ANow);
      if Event.GetValue<string>('cwd', '') <> '' then
        S.Project := ProjectOf(Event.GetValue<string>('cwd', ''));
      if Event.GetValue<string>('type', '') = 'agent-turn-complete' then
      begin
        S.TurnEnded := True;
        S.Asking := False;
        S.PendingTool := '';
        S.Activity := Snippet(Event.GetValue<string>('last-assistant-message', 'Done'));
      end;
    end;
    S.Hooked := True;
    S.LastChange := ANow;
  finally
    Event.Free;
  end;
end;

procedure TAgentMonitor.ReadEvents(ANow: TDateTime);
var
  FileName: string;
  Kind: TAgentKind;
  Files: TArray<string>;
begin
  if not TDirectory.Exists(FEventsFolder) then
    Exit;
  Files := TDirectory.GetFiles(FEventsFolder, '*.json');
  // Names start with the time, so this is the order they happened in
  TArray.Sort<string>(Files);
  for FileName in Files do
  begin
    try
      if AgentKindOf(ExtractFileName(FileName).Split(['-'])[0], Kind) and (Kind in FKinds) then
        ApplyEvent(Kind, TFile.ReadAllText(FileName, TEncoding.UTF8), ANow);
      TFile.Delete(FileName);
    except
      // Still being written: next time
    end;
  end;
end;

procedure TAgentMonitor.UpdateStates(ANow: TDateTime);
var
  I: Integer;
  S: TAgentSession;
  Quiet: Double;
begin
  for I := FSessions.Count - 1 downto 0 do
  begin
    S := FSessions[I];
    Quiet := SecondsBetweenTimes(S.LastChange, ANow);
    if Quiet > DropSeconds then
    begin
      FSessions.Delete(I);
      Continue;
    end;
    if S.Asking then
      S.State := TAgentState.NeedsYou
    else if S.TurnEnded then
    begin
      if Quiet < FinishedSeconds then
        S.State := TAgentState.Finished
      else
        S.State := TAgentState.Idle;
    end
    else if S.PendingTool <> '' then
    begin
      // With hooks the Notification event says it exactly, no guessing
      if not S.Hooked and (Quiet >= IfThen(S.PendingShell, ShellNeedsYouSeconds, NeedsYouSeconds)) then
        S.State := TAgentState.NeedsYou
      else
        S.State := TAgentState.Working;
    end
    else if Quiet < StaleWorkingSeconds then
      S.State := TAgentState.Working
    else
      S.State := TAgentState.Idle;
  end;
end;

procedure TAgentMonitor.Poll(ANow: TDateTime);
var
  S: TAgentSession;
begin
  if SecondsBetweenTimes(FLastScan, ANow) >= ScanSeconds then
    ScanFiles(ANow);
  for S in FSessions do
    if S.Kind in FKinds then
      ReadNew(S, ANow);
  ReadEvents(ANow);
  UpdateStates(ANow);
end;

function TAgentMonitor.Active(AKinds: TAgentKinds): TArray<TAgentSession>;
var
  S: TAgentSession;
  List: TList<TAgentSession>;
begin
  List := TList<TAgentSession>.Create;
  try
    for S in FSessions do
      if S.Kind in AKinds then
        List.Add(S);
    List.Sort(TComparer<TAgentSession>.Construct(
      function(const A, B: TAgentSession): Integer
      begin
        Result := Ord(B.State) - Ord(A.State);
        if Result = 0 then
          Result := CompareValue(B.LastChange, A.LastChange);
      end));
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

{ Hook events }

type
  PArgs = ^TArgs;
  TArgs = array[0..255] of PWideChar;

procedure SaveAgentEvent(const AFolder: string);
var
  Buffer: array[0..65535] of Byte;
  Read: DWORD;
  Bytes: TBytesStream;
  Json, FileName: string;
  Kind: TAgentKind;
  Args: PPWideChar;
  Count: Integer;
begin
  Json := '';
  // ParamStr does not undo the \" escapes of a JSON argument, the shell's own parser does
  Args := CommandLineToArgvW(GetCommandLineW, Count);
  if Args = nil then
    Exit;
  try
    if (Count < 3) or not AgentKindOf(PArgs(Args)^[2], Kind) then
      Exit;
    if Count >= 4 then
      Json := PArgs(Args)^[3];
  finally
    LocalFree(HLOCAL(Args));
  end;
  // Codex passes the event as the last argument, Claude Code on stdin
  if Json = '' then
  begin
    Bytes := TBytesStream.Create;
    try
      while ReadFile(GetStdHandle(STD_INPUT_HANDLE), Buffer, SizeOf(Buffer), Read, nil) and (Read > 0) do
        Bytes.WriteBuffer(Buffer, Read);
      Json := TEncoding.UTF8.GetString(Bytes.Bytes, 0, Bytes.Size);
    finally
      Bytes.Free;
    end;
  end;
  if Json.Trim = '' then
    Exit;
  ForceDirectories(AFolder);
  // Time first, so the folder sorts in the order the events happened
  FileName := TPath.Combine(AFolder, Format('%s-%s-%d.json', [AgentHookNames[Kind], FormatDateTime('yyyymmddhhnnsszzz',
    Now), GetCurrentProcessId]));
  TFile.WriteAllBytes(FileName + '.tmp', TEncoding.UTF8.GetBytes(Json));
  TFile.Move(FileName + '.tmp', FileName);
end;

function HookCommand(const AExe: string; AKind: TAgentKind): string;
begin
  // Forward slashes work for the shells both agents use
  Result := Format('"%s" %s %s', [AExe.Replace('\', '/'), HookMarker, AgentHookNames[AKind]]);
end;

function LoadJsonFile(const AFileName: string): TJSONObject;
begin
  Result := nil;
  if TFile.Exists(AFileName) then
    Result := ParseObject(TFile.ReadAllText(AFileName, TEncoding.UTF8));
  if Result = nil then
  begin
    if TFile.Exists(AFileName) and (TFile.ReadAllText(AFileName).Trim <> '') then
      raise Exception.CreateFmt('%s is not valid JSON, it was left as it is', [AFileName]);
    Result := TJSONObject.Create;
  end;
end;

procedure SaveWithBackup(const AFileName, AText: string);
begin
  if TFile.Exists(AFileName) then
    TFile.Copy(AFileName, AFileName + '.notch-backup', True);
  ForceDirectories(ExtractFileDir(AFileName));
  // No byte order mark: the agents' JSON and TOML readers do not expect one
  TFile.WriteAllBytes(AFileName, TEncoding.UTF8.GetBytes(AText));
end;

function IsNotchHook(AHook: TJSONValue): Boolean;
begin
  Result := AHook.GetValue<string>('command', '').Contains(HookMarker + ' ' + AgentHookNames[TAgentKind.ClaudeCode]);
end;

procedure InstallClaudeHooks(const ASettingsFile, AExe: string);
var
  Root, Hooks, Entry, Hook: TJSONObject;
  Event: string;
  List, Commands: TJSONArray;
  Existing, Command: TJSONValue;
  Found: Boolean;
begin
  Root := LoadJsonFile(ASettingsFile);
  try
    if not (Root.FindValue('hooks') is TJSONObject) then
    begin
      Root.RemovePair('hooks').Free;
      Root.AddPair('hooks', TJSONObject.Create);
    end;
    Hooks := TJSONObject(Root.FindValue('hooks'));
    for Event in HookEvents do
    begin
      if not (Hooks.FindValue(Event) is TJSONArray) then
      begin
        Hooks.RemovePair(Event).Free;
        Hooks.AddPair(Event, TJSONArray.Create);
      end;
      List := TJSONArray(Hooks.FindValue(Event));
      Found := False;
      for Existing in List do
        if Existing.FindValue('hooks') is TJSONArray then
          for Command in TJSONArray(Existing.FindValue('hooks')) do
            Found := Found or IsNotchHook(Command);
      if Found then
        Continue;
      Entry := TJSONObject.Create;
      if MatchStr(Event, ['PreToolUse', 'PostToolUse']) then
        Entry.AddPair('matcher', '*');
      Commands := TJSONArray.Create;
      Hook := TJSONObject.Create;
      Hook.AddPair('type', 'command');
      Hook.AddPair('command', HookCommand(AExe, TAgentKind.ClaudeCode));
      Commands.AddElement(Hook);
      Entry.AddPair('hooks', Commands);
      List.AddElement(Entry);
    end;
    SaveWithBackup(ASettingsFile, Root.Format(2));
  finally
    Root.Free;
  end;
end;

procedure RemoveClaudeHooks(const ASettingsFile: string);
var
  Root, Hooks: TJSONObject;
  Event: string;
  List, Commands: TJSONArray;
  I, J: Integer;
  Changed: Boolean;
begin
  if not TFile.Exists(ASettingsFile) then
    Exit;
  Root := LoadJsonFile(ASettingsFile);
  try
    if not (Root.FindValue('hooks') is TJSONObject) then
      Exit;
    Hooks := TJSONObject(Root.FindValue('hooks'));
    Changed := False;
    for Event in HookEvents do
    begin
      if not (Hooks.FindValue(Event) is TJSONArray) then
        Continue;
      List := TJSONArray(Hooks.FindValue(Event));
      for I := List.Count - 1 downto 0 do
      begin
        if not (List.Items[I].FindValue('hooks') is TJSONArray) then
          Continue;
        Commands := TJSONArray(List.Items[I].FindValue('hooks'));
        for J := Commands.Count - 1 downto 0 do
          if IsNotchHook(Commands.Items[J]) then
          begin
            Commands.Remove(J).Free;
            Changed := True;
          end;
        // Only entries that held nothing but the Notch hook go
        if Commands.Count = 0 then
          List.Remove(I).Free;
      end;
      if List.Count = 0 then
        Hooks.RemovePair(Event).Free;
    end;
    if Hooks.Count = 0 then
      Root.RemovePair('hooks').Free;
    if Changed then
      SaveWithBackup(ASettingsFile, Root.Format(2));
  finally
    Root.Free;
  end;
end;

function ClaudeHooksInstalled(const ASettingsFile: string): Boolean;
begin
  Result := TFile.Exists(ASettingsFile) and TFile.ReadAllText(ASettingsFile).Contains(HookMarker + ' ' +
    AgentHookNames[TAgentKind.ClaudeCode]);
end;

function IsNotifyLine(const ALine: string): Boolean;
begin
  Result := ALine.TrimLeft.StartsWith('notify') and ALine.Contains('=') and
    (ALine.Substring(0, ALine.IndexOf('=')).Trim = 'notify');
end;

function InstallCodexNotify(const AConfigFile, AExe: string): string;
var
  Lines: TStringList;
  Line: string;
begin
  Result := '';
  Lines := TStringList.Create;
  try
    if TFile.Exists(AConfigFile) then
      Lines.Text := TFile.ReadAllText(AConfigFile, TEncoding.UTF8);
    for Line in Lines do
      if IsNotifyLine(Line) then
      begin
        if Line.Contains(HookMarker) then
          Exit
        else
          Exit('Codex runs another notify command already, it was left as it is');
      end;
    // A top-level key has to come before the first [table]
    Lines.Insert(0, Format('notify = ["%s", "%s", "%s"]', [AExe.Replace('\', '/'), HookMarker,
      AgentHookNames[TAgentKind.Codex]]));
    SaveWithBackup(AConfigFile, Lines.Text);
  finally
    Lines.Free;
  end;
end;

procedure RemoveCodexNotify(const AConfigFile: string);
var
  Lines: TStringList;
  I: Integer;
  Changed: Boolean;
begin
  if not TFile.Exists(AConfigFile) then
    Exit;
  Lines := TStringList.Create;
  try
    Lines.Text := TFile.ReadAllText(AConfigFile, TEncoding.UTF8);
    Changed := False;
    for I := Lines.Count - 1 downto 0 do
      if IsNotifyLine(Lines[I]) and Lines[I].Contains(HookMarker) then
      begin
        Lines.Delete(I);
        Changed := True;
      end;
    if Changed then
      SaveWithBackup(AConfigFile, Lines.Text);
  finally
    Lines.Free;
  end;
end;

function CodexNotifyInstalled(const AConfigFile: string): Boolean;
begin
  Result := TFile.Exists(AConfigFile) and TFile.ReadAllText(AConfigFile).Contains(HookMarker);
end;

end.
