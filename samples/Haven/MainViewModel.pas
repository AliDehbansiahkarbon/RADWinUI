unit MainViewModel;

{ The data behind Haven's savings dashboard: the total saved, this week's
  deposits, the countdown to the next auto-save, the auto-save rules and the
  savings goals. Every value the window shows is a published property, so the
  XAML binds to it and follows every change. }

interface

uses
  RADWinUI.Binding;

type
  { One savings goal in the Goals list. }
  TGoal = class(TWinUIBindableObject)
  private
    FTitle, FWhen, FGlyph: string;
    FDone: Boolean;
  public
    constructor Create(const ATitle, AWhen, AGlyph: string; ADone: Boolean);
    procedure Toggle;
  published
    property Title: string read FTitle;
    property When: string read FWhen;
    property Glyph: string read FGlyph;
    property Done: Boolean read FDone;
  end;

  TMainViewModel = class(TWinUIBindableObject)
  private
    FGoals: TWinUIBindableList<TGoal>;
    FDays: array[0..6] of Double;
    FCountdown: Integer;
    FRunning: Boolean;
    FRoundUps, FPaydayBoost, FSmartSweep: Boolean;
    function GetGoalCaption: string;
    function GetTotalText: string;
    function GetWeekText: string;
    function GetCountdownText: string;
    function GetCountdownProgress: Double;
    function GetAutoSaveCaption: string;
    function GetDay(AIndex: Integer): Double;
    procedure SetRoundUps(AValue: Boolean);
    procedure SetPaydayBoost(AValue: Boolean);
    procedure SetSmartSweep(AValue: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    { Marks the goal at AIndex done or open again. }
    procedure ToggleGoal(AIndex: Integer);
    { Adds AAmount to today's deposits. }
    procedure AddMoney(AAmount: Double);
    procedure Start;
    procedure Pause;
    { One second of the countdown while it runs. }
    procedure Tick;
    function DoneCount: Integer;
    property Running: Boolean read FRunning;
  published
    property Goals: TWinUIBindableList<TGoal> read FGoals;
    property GoalCaption: string read GetGoalCaption;
    property TotalText: string read GetTotalText;
    property WeekText: string read GetWeekText;
    property CountdownText: string read GetCountdownText;
    property CountdownProgress: Double read GetCountdownProgress;
    property AutoSaveCaption: string read GetAutoSaveCaption;
    property Day1: Double index 0 read GetDay;
    property Day2: Double index 1 read GetDay;
    property Day3: Double index 2 read GetDay;
    property Day4: Double index 3 read GetDay;
    property Day5: Double index 4 read GetDay;
    property Day6: Double index 5 read GetDay;
    property Day7: Double index 6 read GetDay;
    property RoundUps: Boolean read FRoundUps write SetRoundUps;
    property PaydayBoost: Boolean read FPaydayBoost write SetPaydayBoost;
    property SmartSweep: Boolean read FSmartSweep write SetSmartSweep;
  end;

{ Money as the dashboard shows it, the same on every PC: $10,937 }
function MoneyText(AValue: Double): string;

implementation

uses
  System.SysUtils,
  System.Math;

const
  BarScale = 120;               // pixels of the best day
  CountdownStart = 2 * 60 + 35; // minutes and seconds shown as 02:35
  CountdownFull = 5 * 60;       // the dial is full five minutes before an auto-save
  BaseTotal = 10327;

var
  UsFormat: TFormatSettings;

function MoneyText(AValue: Double): string;
begin
  Result := '$' + FormatFloat('#,##0', AValue, UsFormat);
end;

{ TGoal }

constructor TGoal.Create(const ATitle, AWhen, AGlyph: string; ADone: Boolean);
begin
  inherited Create;
  FTitle := ATitle;
  FWhen := AWhen;
  FGlyph := AGlyph;
  FDone := ADone;
end;

procedure TGoal.Toggle;
begin
  FDone := not FDone;
  Changed('Done');
end;

{ TMainViewModel }

constructor TMainViewModel.Create;
const
  Deposits: array[0..6] of Double = (24, 96, 120, 58, 130, 182, 0);
var
  I: Integer;
begin
  inherited;
  FGoals := TWinUIBindableList<TGoal>.Create;
  FGoals.Add(TGoal.Create('Emergency fund', 'Done Sep 2026', #$EA18, True));
  FGoals.Add(TGoal.Create('New laptop', 'Done Oct 2026', #$E7F8, True));
  FGoals.Add(TGoal.Create('Summer in Lisbon', 'Due Jun 2027', #$E709, False));
  FGoals.Add(TGoal.Create('Home studio', 'Due Mar 2027', #$E8D6, False));
  FGoals.Add(TGoal.Create('Wedding gift', 'Due May 2027', #$EB51, False));
  for I := 0 to High(FDays) do
    FDays[I] := Deposits[I];
  FCountdown := CountdownStart;
  FRoundUps := True;
  FPaydayBoost := True;
end;

destructor TMainViewModel.Destroy;
begin
  FGoals.Free;
  inherited;
end;

function TMainViewModel.DoneCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FGoals.Count - 1 do
    if FGoals[I].Done then
      Inc(Result);
end;

function TMainViewModel.GetGoalCaption: string;
begin
  Result := IntToStr(DoneCount) + '/' + IntToStr(FGoals.Count);
end;

function TMainViewModel.GetTotalText: string;
begin
  Result := MoneyText(BaseTotal + Sum(FDays));
end;

function TMainViewModel.GetWeekText: string;
begin
  Result := MoneyText(Sum(FDays));
end;

function TMainViewModel.GetCountdownText: string;
begin
  Result := Format('%.2d:%.2d', [FCountdown div 60, FCountdown mod 60]);
end;

function TMainViewModel.GetCountdownProgress: Double;
begin
  Result := 100 * (1 - FCountdown / CountdownFull);
end;

function TMainViewModel.GetAutoSaveCaption: string;
begin
  Result := IntToStr(Ord(FRoundUps) + Ord(FPaydayBoost) + Ord(FSmartSweep)) + ' on';
end;

function TMainViewModel.GetDay(AIndex: Integer): Double;
begin
  Result := Max(10, BarScale * FDays[AIndex] / MaxValue(FDays));
end;

procedure TMainViewModel.SetRoundUps(AValue: Boolean);
begin
  FRoundUps := AValue;
  Changed('AutoSaveCaption');
end;

procedure TMainViewModel.SetPaydayBoost(AValue: Boolean);
begin
  FPaydayBoost := AValue;
  Changed('AutoSaveCaption');
end;

procedure TMainViewModel.SetSmartSweep(AValue: Boolean);
begin
  FSmartSweep := AValue;
  Changed('AutoSaveCaption');
end;

procedure TMainViewModel.ToggleGoal(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FGoals.Count) then
    Exit;
  FGoals[AIndex].Toggle;
  Changed('GoalCaption');
end;

procedure TMainViewModel.AddMoney(AAmount: Double);
const
  Days: array[0..6] of string = ('Day1', 'Day2', 'Day3', 'Day4', 'Day5', 'Day6', 'Day7');
var
  Name: string;
begin
  FDays[5] := FDays[5] + AAmount; // today, Friday
  Changed('TotalText');
  Changed('WeekText');
  for Name in Days do
    Changed(Name);
end;

procedure TMainViewModel.Start;
begin
  FRunning := True;
end;

procedure TMainViewModel.Pause;
begin
  FRunning := False;
end;

procedure TMainViewModel.Tick;
begin
  if not FRunning then
    Exit;
  if FCountdown > 0 then
    Dec(FCountdown)
  else
    FCountdown := CountdownFull;
  Changed('CountdownText');
  Changed('CountdownProgress');
end;

initialization
  UsFormat := TFormatSettings.Create('en-US');
  UsFormat.ThousandSeparator := ',';
  UsFormat.DecimalSeparator := '.';
end.
