unit Notch.Usage;

{ How much of their usage limits the AI agents have used. Codex writes its
  limits into its session files (token_count events), so its figures are
  exact. Claude Code writes only the tokens of each answer, so for it the
  notch adds them up per 5-hour block and per week, as an estimate. A thread
  reads the files, they are large.

  Exact Claude limits are an option: then the thread asks the Claude account
  with the login Claude Code keeps on this PC, as Claude Code's /usage does.
  The login's token is read for each request and never kept or written. }

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,
  Notch.Agents;

type
  TUsageWindow = record
    Agent: TAgentKind;
    Title: string;
    // 0..100, or -1 when only a token count is known
    Percent: Double;
    Tokens: Int64;
    // When the window starts again, 0 when unknown
    ResetsAt: TDateTime;
    Estimate: Boolean;
    // When the agent reported these figures, 0 when unknown
    ReportedAt: TDateTime;
    /// <summary>
    ///   The share used at ANow: a window that started again since the agent
    ///   reported it has not been used since, so 0.
    /// </summary>
    function PercentAt(ANow: TDateTime): Double;
    /// <summary>"62 % used, resets in 2 h 10 min" or "1.2M tokens, estimate".</summary>
    function Summary(ANow: TDateTime): string;
  end;

  // A token count of one answer, at the time it was given
  TUsagePoint = record
    Time: TDateTime;
    Tokens: Int64;
  end;

  /// <summary>Fetches the Claude usage JSON with AToken. Replaceable for tests.</summary>
  TClaudeUsageFetch = reference to function(const AToken: string): string;

  TUsageMonitor = class
  strict private
    type
      TReader = class(TThread)
      strict private
        FOwner: TUsageMonitor;
      protected
        procedure Execute; override;
      public
        constructor Create(AOwner: TUsageMonitor);
      end;
      TFileState = class
      public
        Offset: Int64;
        Points: TList<TUsagePoint>;
        Seen: TDictionary<string, Boolean>;
        constructor Create;
        destructor Destroy; override;
      end;
  strict private
    FClaudeRoot: string;
    FCodexRoot: string;
    FLock: TCriticalSection;
    FWindows: TArray<TUsageWindow>;
    FFiles: TObjectDictionary<string, TFileState>;
    FReader: TReader;
    FReady: TEvent;
    FExact: Boolean;
    FExactStatus: string;
    FExactAttempts: Integer;
    FCredentialsFile: string;
    FFetch: TClaudeUsageFetch;
    function GetExact: Boolean;
    procedure SetExact(AValue: Boolean);
    function GetExactStatus: string;
    function ExactWindows: TArray<TUsageWindow>;
    procedure ReadClaudeFile(const AFileName: string; AState: TFileState; AThread: TThread);
  public
    constructor Create(const AClaudeRoot, ACodexRoot: string);
    destructor Destroy; override;
    /// <summary>Reads the files once now and then every minute on a thread of its own.</summary>
    procedure Start;
    /// <summary>One pass over the files, on the calling thread. The thread and the tests use it.</summary>
    procedure Update(AThread: TThread = nil);
    /// <summary>The windows of the last pass, for the agents in AKinds.</summary>
    function Windows(AKinds: TAgentKinds): TArray<TUsageWindow>;
    /// <summary>Waits up to ATimeout ms for the first pass of Start.</summary>
    function WaitReady(ATimeout: Cardinal): Boolean;
    /// <summary>Asks the Claude account for the exact limits. Off by default.</summary>
    property Exact: Boolean read GetExact write SetExact;
    /// <summary>Why the exact limits are not shown, '' when they are or when Exact is off.</summary>
    property ExactStatus: string read GetExactStatus;
    /// <summary>How often the exact limits were asked for, for tests.</summary>
    property ExactAttempts: Integer read FExactAttempts;
    /// <summary>Where Claude Code keeps its login, %USERPROFILE%\.claude\.credentials.json by default.</summary>
    property CredentialsFile: string read FCredentialsFile write FCredentialsFile;
    property Fetch: TClaudeUsageFetch read FFetch write FFetch;
  end;

/// <summary>
///   The access token of Claude Code's login in ACredentialsFile. False with
///   AStatus set when there is none or it has expired: Claude Code renews it,
///   the notch never does.
/// </summary>
function ReadClaudeToken(const ACredentialsFile: string; ANow: TDateTime; out AToken, AStatus: string): Boolean;
/// <summary>The windows of the Claude account's usage JSON: 5 hours, the week and the week per model.</summary>
function ClaudeExactWindows(const AJson: string): TArray<TUsageWindow>;

/// <summary>Usage windows from the token points of Claude Code: the 5-hour block that is running, and the last 7 days.</summary>
function ClaudeWindows(const APoints: TArray<TUsagePoint>; ANow: TDateTime): TArray<TUsageWindow>;
/// <summary>The limits in the last rate_limits line of a Codex session file, [] when it has none.</summary>
function CodexWindows(const ALines: TArray<string>): TArray<TUsageWindow>;

implementation

uses
  System.Net.HttpClient,
  System.Net.URLClient,
  System.IOUtils,
  System.DateUtils,
  System.Math,
  System.JSON,
  System.Generics.Defaults;

const
  BlockHours = 5;
  WeekDays = 7;
  RefreshMs = 60 * 1000;
  TailBytes = 256 * 1024;
  // The most recently written Codex sessions that are searched for its latest limits
  CodexFilesRead = 8;

function FormatTokens(ATokens: Int64): string;
begin
  if ATokens >= 1000000 then
    Result := FormatFloat('0.0', ATokens / 1000000) + 'M'
  else if ATokens >= 1000 then
    Result := FormatFloat('0.#', ATokens / 1000) + 'k'
  else
    Result := ATokens.ToString;
end;

function FormatSpan(ASeconds: Int64): string;
begin
  if ASeconds < 3600 then
    Result := Format('%d min', [Max(1, ASeconds div 60)])
  else if ASeconds < 86400 then
    Result := Format('%d h %d min', [ASeconds div 3600, ASeconds mod 3600 div 60])
  else
    Result := Format('%d days %d h', [ASeconds div 86400, ASeconds mod 86400 div 3600]);
end;

{ TUsageWindow }

function TUsageWindow.PercentAt(ANow: TDateTime): Double;
begin
  Result := Percent;
  if (Percent >= 0) and (ResetsAt > 0) and (ResetsAt <= ANow) then
    Result := 0;
end;

function TUsageWindow.Summary(ANow: TDateTime): string;
begin
  if (Percent >= 0) and (ResetsAt > 0) and (ResetsAt <= ANow) then
    Exit(Format('0 %% used. Reset at %s, no use since', [FormatDateTime('ddd hh:nn', ResetsAt)]));
  if Percent >= 0 then
    Result := Format('%.0f %% used', [Percent])
  else
    Result := FormatTokens(Tokens) + ' tokens';
  if ResetsAt > ANow then
    Result := Result + ', resets in ' + FormatSpan(SecondsBetween(ANow, ResetsAt));
  if Estimate then
    Result := Result + ' (estimate)';
end;

function UsageWindow(AAgent: TAgentKind; const ATitle: string; APercent: Double; ATokens: Int64;
  AResetsAt: TDateTime; AEstimate: Boolean): TUsageWindow;
begin
  Result.Agent := AAgent;
  Result.Title := ATitle;
  Result.Percent := APercent;
  Result.Tokens := ATokens;
  Result.ResetsAt := AResetsAt;
  Result.Estimate := AEstimate;
  Result.ReportedAt := 0;
end;

function ClaudeWindows(const APoints: TArray<TUsagePoint>; ANow: TDateTime): TArray<TUsageWindow>;
var
  Points: TArray<TUsagePoint>;
  Point: TUsagePoint;
  BlockStart: TDateTime;
  Block, Week: Int64;
begin
  Points := Copy(APoints);
  TArray.Sort<TUsagePoint>(Points, TComparer<TUsagePoint>.Construct(
    function(const A, B: TUsagePoint): Integer
    begin
      Result := CompareValue(A.Time, B.Time);
    end));
  // A block starts with the first answer after the last block ended, like the 5-hour limit
  BlockStart := 0;
  Week := 0;
  for Point in Points do
  begin
    if (BlockStart = 0) or (Point.Time >= IncHour(BlockStart, BlockHours)) then
      BlockStart := Point.Time;
    if Point.Time > IncDay(ANow, -WeekDays) then
      Inc(Week, Point.Tokens);
  end;
  Block := 0;
  if (BlockStart > 0) and (ANow < IncHour(BlockStart, BlockHours)) then
    for Point in Points do
      if Point.Time >= BlockStart then
        Inc(Block, Point.Tokens);
  if Block > 0 then
    Result := [UsageWindow(TAgentKind.ClaudeCode, 'Current session (5 hours)', -1, Block,
      IncHour(BlockStart, BlockHours), True)]
  else
    Result := [UsageWindow(TAgentKind.ClaudeCode, 'Current session (5 hours)', -1, 0, 0, True)];
  Result := Result + [UsageWindow(TAgentKind.ClaudeCode, 'Last 7 days', -1, Week, 0, True)];
end;

function CodexWindows(const ALines: TArray<string>): TArray<TUsageWindow>;
var
  I: Integer;
  Line, Limits, Window: TJSONValue;
  Name: string;
  Minutes: Integer;
  Title: string;
begin
  Result := [];
  for I := High(ALines) downto 0 do
  begin
    if not ALines[I].Contains('"rate_limits"') then
      Continue;
    try
      Line := TJSONObject.ParseJSONValue(ALines[I]);
    except
      Line := nil;
    end;
    if Line = nil then
      Continue;
    try
      Limits := Line.FindValue('payload.rate_limits');
      if Limits = nil then
        Continue;
      for Name in ['primary', 'secondary'] do
      begin
        Window := Limits.FindValue(Name);
        if not (Window is TJSONObject) then
          Continue;
        Minutes := Window.GetValue<Integer>('window_minutes', 0);
        if Minutes = BlockHours * 60 then
          Title := 'Current session (5 hours)'
        else if Minutes = WeekDays * 24 * 60 then
          Title := 'This week'
        else
          Title := Format('%d hour window', [Minutes div 60]);
        Result := Result + [UsageWindow(TAgentKind.Codex, Title, Window.GetValue<Double>('used_percent', 0), 0,
          UnixToDateTime(Window.GetValue<Int64>('resets_at', 0), False), False)];
        Result[High(Result)].ReportedAt := ISO8601ToDate(Line.GetValue<string>('timestamp', '1970-01-01T00:00:00Z'),
          False);
      end;
      if Length(Result) > 0 then
        Exit;
    finally
      Line.Free;
    end;
  end;
end;

{ TUsageMonitor.TFileState }

constructor TUsageMonitor.TFileState.Create;
begin
  inherited;
  Points := TList<TUsagePoint>.Create;
  Seen := TDictionary<string, Boolean>.Create;
end;

destructor TUsageMonitor.TFileState.Destroy;
begin
  Seen.Free;
  Points.Free;
  inherited;
end;

{ TUsageMonitor.TReader }

constructor TUsageMonitor.TReader.Create(AOwner: TUsageMonitor);
begin
  FOwner := AOwner;
  inherited Create(False);
end;

procedure TUsageMonitor.TReader.Execute;
var
  Waited: Integer;
begin
  while not Terminated do
  begin
    try
      FOwner.Update(Self);
    except
      // A file that cannot be read now is read on the next pass
    end;
    FOwner.FReady.SetEvent;
    Waited := 0;
    while not Terminated and (Waited < RefreshMs) do
    begin
      Sleep(250);
      Inc(Waited, 250);
    end;
  end;
end;

{ TUsageMonitor }

// The account usage that Claude Code's /usage shows
function FetchClaudeUsage(const AToken: string): string;
var
  Client: THTTPClient;
  Response: IHTTPResponse;
begin
  Client := THTTPClient.Create;
  try
    Client.ConnectionTimeout := 10000;
    Client.ResponseTimeout := 10000;
    Response := Client.Get('https://api.anthropic.com/api/oauth/usage', nil,
      [TNetHeader.Create('Authorization', 'Bearer ' + AToken), TNetHeader.Create('anthropic-beta', 'oauth-2025-04-20')]);
    // The status only: an error never carries the request, so never the token
    if Response.StatusCode <> 200 then
      raise Exception.CreateFmt('The Claude account answered %d', [Response.StatusCode]);
    Result := Response.ContentAsString(TEncoding.UTF8);
  finally
    Client.Free;
  end;
end;

function ReadClaudeToken(const ACredentialsFile: string; ANow: TDateTime; out AToken, AStatus: string): Boolean;
var
  Json: TJSONValue;
  Expires: Int64;
begin
  AToken := '';
  AStatus := 'Exact limits unavailable: no Claude Code login on this PC';
  if not TFile.Exists(ACredentialsFile) then
    Exit(False);
  try
    Json := TJSONObject.ParseJSONValue(TFile.ReadAllText(ACredentialsFile, TEncoding.UTF8));
  except
    Json := nil;
  end;
  if Json = nil then
    Exit(False);
  try
    AToken := Json.GetValue<string>('claudeAiOauth.accessToken', '');
    Expires := Json.GetValue<Int64>('claudeAiOauth.expiresAt', 0);
  finally
    Json.Free;
  end;
  if AToken = '' then
    Exit(False);
  // Milliseconds since 1970, in UTC
  if (Expires > 0) and (Expires < DateTimeToUnix(ANow, False) * 1000) then
  begin
    AToken := '';
    AStatus := 'Open Claude Code to refresh your login';
    Exit(False);
  end;
  AStatus := '';
  Result := True;
end;

function ClaudeExactWindows(const AJson: string): TArray<TUsageWindow>;
const
  Keys: array[0..3] of string = ('five_hour', 'seven_day', 'seven_day_sonnet', 'seven_day_opus');
  Titles: array[0..3] of string = ('Current session (5 hours)', 'This week, all models', 'This week, Sonnet',
    'This week, Opus');
var
  Json, Window: TJSONValue;
  I: Integer;
  ResetsAt: TDateTime;
begin
  Result := [];
  try
    Json := TJSONObject.ParseJSONValue(AJson);
  except
    Json := nil;
  end;
  if Json = nil then
    Exit;
  try
    for I := 0 to High(Keys) do
    begin
      Window := Json.FindValue(Keys[I]);
      if not (Window is TJSONObject) or (Window.FindValue('utilization') = nil) then
        Continue;
      try
        ResetsAt := ISO8601ToDate(Window.GetValue<string>('resets_at', ''), False);
      except
        ResetsAt := 0;
      end;
      Result := Result + [UsageWindow(TAgentKind.ClaudeCode, Titles[I], Window.GetValue<Double>('utilization', 0), 0,
        ResetsAt, False)];
    end;
  finally
    Json.Free;
  end;
end;

constructor TUsageMonitor.Create(const AClaudeRoot, ACodexRoot: string);
begin
  inherited Create;
  FClaudeRoot := AClaudeRoot;
  FCodexRoot := ACodexRoot;
  FCredentialsFile := TPath.Combine(GetEnvironmentVariable('USERPROFILE'), '.claude\.credentials.json');
  FFetch := FetchClaudeUsage;
  FLock := TCriticalSection.Create;
  FFiles := TObjectDictionary<string, TFileState>.Create([doOwnsValues]);
  FReady := TEvent.Create(nil, True, False, '');
end;

destructor TUsageMonitor.Destroy;
begin
  if FReader <> nil then
  begin
    FReader.Terminate;
    FReader.WaitFor;
    FReader.Free;
  end;
  FReady.Free;
  FFiles.Free;
  FLock.Free;
  inherited;
end;

procedure TUsageMonitor.Start;
begin
  if FReader = nil then
    FReader := TReader.Create(Self);
end;

function TUsageMonitor.WaitReady(ATimeout: Cardinal): Boolean;
begin
  Result := FReady.WaitFor(ATimeout) = wrSignaled;
end;

procedure TUsageMonitor.ReadClaudeFile(const AFileName: string; AState: TFileState; AThread: TThread);
var
  Reader: TStreamReader;
  Stream: TFileStream;
  Line, Id: string;
  Json, Usage: TJSONValue;
  Point: TUsagePoint;
begin
  Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    if Stream.Size < AState.Offset then
      AState.Offset := 0;
    Stream.Position := AState.Offset;
    Reader := TStreamReader.Create(Stream, TEncoding.UTF8);
    try
      while not Reader.EndOfStream do
      begin
        if (AThread <> nil) and AThread.CheckTerminated then
          Exit;
        Line := Reader.ReadLine;
        // Only answers carry usage, and each answer is repeated for every part of it
        if not (Line.Contains('"usage"') and Line.Contains('"assistant"')) then
          Continue;
        try
          Json := TJSONObject.ParseJSONValue(Line);
        except
          Json := nil;
        end;
        if Json = nil then
          Continue;
        try
          Usage := Json.FindValue('message.usage');
          Id := Json.GetValue<string>('message.id', '');
          if (Usage = nil) or (Id = '') or AState.Seen.ContainsKey(Id) then
            Continue;
          AState.Seen.Add(Id, True);
          Point.Time := ISO8601ToDate(Json.GetValue<string>('timestamp', DateToISO8601(Now, False)), False);
          // Cache reads are cheap and do not count against the limits the way new tokens do
          Point.Tokens := Usage.GetValue<Int64>('input_tokens', 0) + Usage.GetValue<Int64>('output_tokens', 0) +
            Usage.GetValue<Int64>('cache_creation_input_tokens', 0);
          AState.Points.Add(Point);
        finally
          Json.Free;
        end;
      end;
    finally
      Reader.Free;
    end;
    AState.Offset := Stream.Size;
  finally
    Stream.Free;
  end;
end;

procedure TUsageMonitor.Update(AThread: TThread);
var
  Folder, FileName, Newest: string;
  State: TFileState;
  Points: TList<TUsagePoint>;
  Point: TUsagePoint;
  Since: TDateTime;
  Windows: TArray<TUsageWindow>;
  CodexLimits, Found: TArray<TUsageWindow>;
  Files: TList<string>;
  Day: Integer;
  Text: string;
  Stream: TFileStream;
  Bytes: TBytes;
begin
  Since := IncDay(Now, -WeekDays);
  Windows := [];
  if TDirectory.Exists(FClaudeRoot) then
  begin
    for Folder in TDirectory.GetDirectories(FClaudeRoot) do
      for FileName in TDirectory.GetFiles(Folder, '*.jsonl') do
      begin
        if (AThread <> nil) and AThread.CheckTerminated then
          Exit;
        if TFile.GetLastWriteTime(FileName) < Since then
          Continue;
        if not FFiles.TryGetValue(FileName, State) then
        begin
          State := TFileState.Create;
          FFiles.Add(FileName, State);
        end;
        try
          ReadClaudeFile(FileName, State, AThread);
        except
          // Locked for a moment: read the rest next time
        end;
      end;
    Points := TList<TUsagePoint>.Create;
    try
      for State in FFiles.Values do
        for Point in State.Points do
          if Point.Time > Since then
            Points.Add(Point);
      Windows := ClaudeWindows(Points.ToArray, Now);
    finally
      Points.Free;
    end;
  end;
  // Codex: the newest report of its limits, from the sessions of the last days. Several
  // sessions may run side by side, so the report's own time decides, not the file's
  CodexLimits := [];
  if TDirectory.Exists(FCodexRoot) then
  begin
    Files := TList<string>.Create;
    try
      for Day := 0 to WeekDays do
      begin
        Folder := TPath.Combine(FCodexRoot, FormatDateTime('yyyy"\"mm"\"dd', IncDay(Date, -Day)));
        if TDirectory.Exists(Folder) then
          Files.AddRange(TDirectory.GetFiles(Folder, '*.jsonl'));
      end;
      Files.Sort(TComparer<string>.Construct(
        function(const A, B: string): Integer
        begin
          Result := CompareValue(TFile.GetLastWriteTime(B), TFile.GetLastWriteTime(A));
        end));
      for Newest in Files.ToArray do
      begin
        if Files.IndexOf(Newest) >= CodexFilesRead then
          Break;
        Stream := TFileStream.Create(Newest, fmOpenRead or fmShareDenyNone);
        try
          Stream.Position := Max(0, Stream.Size - TailBytes);
          SetLength(Bytes, Stream.Size - Stream.Position);
          if Length(Bytes) > 0 then
            Stream.ReadBuffer(Bytes[0], Length(Bytes));
        finally
          Stream.Free;
        end;
        Text := TEncoding.UTF8.GetString(Bytes);
        Found := CodexWindows(Text.Split([#10]));
        if (Length(Found) > 0) and ((Length(CodexLimits) = 0) or (Found[0].ReportedAt > CodexLimits[0].ReportedAt)) then
          CodexLimits := Found;
      end;
    finally
      Files.Free;
    end;
  end;
  // Exact Claude limits, when asked for, take the place of the estimate
  Found := ExactWindows;
  if Length(Found) > 0 then
  begin
    Windows := [];
    CodexLimits := CodexLimits + Found;
  end;
  Windows := Windows + CodexLimits;
  FLock.Enter;
  try
    FWindows := Windows;
  finally
    FLock.Leave;
  end;
end;

function TUsageMonitor.GetExact: Boolean;
begin
  FLock.Enter;
  try
    Result := FExact;
  finally
    FLock.Leave;
  end;
end;

procedure TUsageMonitor.SetExact(AValue: Boolean);
begin
  FLock.Enter;
  try
    FExact := AValue;
    if not AValue then
      FExactStatus := '';
  finally
    FLock.Leave;
  end;
end;

function TUsageMonitor.GetExactStatus: string;
begin
  FLock.Enter;
  try
    Result := FExactStatus;
  finally
    FLock.Leave;
  end;
end;

function TUsageMonitor.ExactWindows: TArray<TUsageWindow>;
var
  Token, Status: string;
begin
  Result := [];
  // Off: the login is not even read
  if not Exact then
    Exit;
  Inc(FExactAttempts);
  if ReadClaudeToken(FCredentialsFile, Now, Token, Status) then
    try
      try
        Result := ClaudeExactWindows(FFetch(Token));
      finally
        Token := '';
      end;
      if Length(Result) = 0 then
        Status := 'Exact limits unavailable right now';
    except
      // Offline, refused or changed: the estimate stays, with a short note
      Status := 'Exact limits unavailable right now';
    end;
  FLock.Enter;
  try
    FExactStatus := Status;
  finally
    FLock.Leave;
  end;
end;

function TUsageMonitor.Windows(AKinds: TAgentKinds): TArray<TUsageWindow>;
var
  Window: TUsageWindow;
begin
  Result := [];
  FLock.Enter;
  try
    for Window in FWindows do
      if Window.Agent in AKinds then
        Result := Result + [Window];
  finally
    FLock.Leave;
  end;
end;

end.
