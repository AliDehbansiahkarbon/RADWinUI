unit MainViewModel;

{ The data behind Haven's dashboard: savings goals, monthly contributions and
  the auto-save rules. Every number the window shows is a published property,
  so the XAML binds to it and follows every change. }

interface

uses
  RADWinUI.Binding;

type
  { One savings goal card. The last card of the list is the "New goal" card. }
  TGoal = class(TWinUIBindableObject)
  private
    FName, FGlyph, FDueText: string;
    FSaved, FTarget: Double;
    FIsNewCard: Boolean;
    function GetPercent: Double;
    function GetPercentText: string;
    function GetAmountText: string;
  public
    constructor Create(const AName, AGlyph, ADueText: string; ASaved, ATarget: Double);
    constructor CreateNewCard;
    procedure AddMoney(AAmount: Double);
    property Saved: Double read FSaved;
    property Target: Double read FTarget;
  published
    property Name: string read FName;
    property Glyph: string read FGlyph;
    property DueText: string read FDueText;
    property Percent: Double read GetPercent;
    property PercentText: string read GetPercentText;
    property AmountText: string read GetAmountText;
    property IsNewCard: Boolean read FIsNewCard;
  end;

  TMainViewModel = class(TWinUIBindableObject)
  private
    FGoals: TWinUIBindableList<TGoal>;
    FMonths: array[0..5] of Double;
    FRoundUps, FPaydayBoost, FSmartSweep: Boolean;
    FUserName: string;
    function GetTotalText: string;
    function GetTotalProgress: Double;
    function GetProgressCaption: string;
    function GetAutoSaveCaption: string;
    function GetBar(AIndex: Integer): Double;
    procedure SetRoundUps(AValue: Boolean);
    procedure SetPaydayBoost(AValue: Boolean);
    procedure SetSmartSweep(AValue: Boolean);
    procedure TotalsChanged;
  public
    constructor Create;
    destructor Destroy; override;
    { Adds AAmount to the goal at AIndex and to this month's contribution. }
    procedure AddMoney(AIndex: Integer; AAmount: Double);
    { Adds a new, empty goal before the "New goal" card and returns its index. }
    function AddGoal: Integer;
    function GoalCount: Integer;
  published
    property UserName: string read FUserName;
    property Goals: TWinUIBindableList<TGoal> read FGoals;
    property TotalText: string read GetTotalText;
    property TotalProgress: Double read GetTotalProgress;
    property ProgressCaption: string read GetProgressCaption;
    property AutoSaveCaption: string read GetAutoSaveCaption;
    property Bar1: Double index 0 read GetBar;
    property Bar2: Double index 1 read GetBar;
    property Bar3: Double index 2 read GetBar;
    property Bar4: Double index 3 read GetBar;
    property Bar5: Double index 4 read GetBar;
    property Bar6: Double index 5 read GetBar;
    property RoundUps: Boolean read FRoundUps write SetRoundUps;
    property PaydayBoost: Boolean read FPaydayBoost write SetPaydayBoost;
    property SmartSweep: Boolean read FSmartSweep write SetSmartSweep;
  end;

{ Money as the dashboard shows it, the same on every PC: $10,937.95 }
function MoneyText(AValue: Double; ADecimals: Integer = 2): string;

implementation

uses
  System.SysUtils,
  System.Math;

const
  BarScale = 130; // pixels of the tallest monthly bar
  NewGoalTarget = 1000;

var
  UsFormat: TFormatSettings;

function MoneyText(AValue: Double; ADecimals: Integer): string;
begin
  if ADecimals > 0 then
    Result := '$' + FormatFloat('#,##0.' + StringOfChar('0', ADecimals), AValue, UsFormat)
  else
    Result := '$' + FormatFloat('#,##0', AValue, UsFormat);
end;

{ TGoal }

constructor TGoal.Create(const AName, AGlyph, ADueText: string; ASaved, ATarget: Double);
begin
  inherited Create;
  FName := AName;
  FGlyph := AGlyph;
  FDueText := ADueText;
  FSaved := ASaved;
  FTarget := ATarget;
end;

constructor TGoal.CreateNewCard;
begin
  inherited Create;
  FName := 'New goal';
  FGlyph := #$E710;
  FIsNewCard := True;
end;

function TGoal.GetPercent: Double;
begin
  if FTarget <= 0 then
    Result := 0
  else
    Result := Min(100, 100 * FSaved / FTarget);
end;

function TGoal.GetPercentText: string;
begin
  Result := IntToStr(Round(GetPercent)) + '%';
end;

function TGoal.GetAmountText: string;
begin
  Result := MoneyText(FSaved, 0) + ' of ' + MoneyText(FTarget, 0);
end;

procedure TGoal.AddMoney(AAmount: Double);
begin
  FSaved := Min(FTarget, FSaved + AAmount);
  Changed('Percent');
  Changed('PercentText');
  Changed('AmountText');
end;

{ TMainViewModel }

constructor TMainViewModel.Create;
const
  Contributions: array[0..5] of Double = (420, 610, 380, 720, 560, 840);
var
  I: Integer;
begin
  inherited;
  FUserName := 'Alex';
  FGoals := TWinUIBindableList<TGoal>.Create;
  FGoals.Add(TGoal.Create('Summer in Lisbon', #$E709, 'Jun 2026', 2220, 3000));
  FGoals.Add(TGoal.Create('New laptop', #$E7F8, 'Aug 2026', 1536, 2400));
  FGoals.Add(TGoal.Create('Emergency fund', #$EA18, 'Dec 2026', 4860, 10000));
  FGoals.Add(TGoal.Create('Home studio', #$E8D6, 'Mar 2027', 1180, 4200));
  FGoals.Add(TGoal.Create('Wedding gift', #$EB51, 'May 2027', 1141.95, 4700));
  FGoals.Add(TGoal.CreateNewCard);
  for I := 0 to High(FMonths) do
    FMonths[I] := Contributions[I];
  FRoundUps := True;
  FPaydayBoost := True;
end;

destructor TMainViewModel.Destroy;
begin
  FGoals.Free;
  inherited;
end;

function TMainViewModel.GoalCount: Integer;
begin
  Result := FGoals.Count - 1;
end;

function TMainViewModel.GetTotalText: string;
var
  I: Integer;
  Total: Double;
begin
  Total := 0;
  for I := 0 to GoalCount - 1 do
    Total := Total + FGoals[I].Saved;
  Result := MoneyText(Total);
end;

function TMainViewModel.GetTotalProgress: Double;
var
  I: Integer;
  Saved, Target: Double;
begin
  Saved := 0;
  Target := 0;
  for I := 0 to GoalCount - 1 do
  begin
    Saved := Saved + FGoals[I].Saved;
    Target := Target + FGoals[I].Target;
  end;
  if Target <= 0 then
    Result := 0
  else
    Result := 100 * Saved / Target;
end;

function TMainViewModel.GetProgressCaption: string;
var
  I: Integer;
  Target: Double;
begin
  Target := 0;
  for I := 0 to GoalCount - 1 do
    Target := Target + FGoals[I].Target;
  Result := Format('%d%% of %s across %d goals', [Round(GetTotalProgress), MoneyText(Target, 0), GoalCount]);
end;

function TMainViewModel.GetAutoSaveCaption: string;
begin
  Result := IntToStr(Ord(FRoundUps) + Ord(FPaydayBoost) + Ord(FSmartSweep)) + ' on';
end;

function TMainViewModel.GetBar(AIndex: Integer): Double;
begin
  Result := Max(12, BarScale * FMonths[AIndex] / MaxValue(FMonths));
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

procedure TMainViewModel.TotalsChanged;
const
  Bars: array[0..5] of string = ('Bar1', 'Bar2', 'Bar3', 'Bar4', 'Bar5', 'Bar6');
var
  Name: string;
begin
  Changed('TotalText');
  Changed('TotalProgress');
  Changed('ProgressCaption');
  for Name in Bars do
    Changed(Name);
end;

procedure TMainViewModel.AddMoney(AIndex: Integer; AAmount: Double);
begin
  if (AIndex < 0) or (AIndex >= GoalCount) then
    Exit;
  FGoals[AIndex].AddMoney(AAmount);
  FMonths[High(FMonths)] := FMonths[High(FMonths)] + AAmount;
  TotalsChanged;
end;

function TMainViewModel.AddGoal: Integer;
begin
  Result := GoalCount;
  FGoals.Insert(Result, TGoal.Create('Goal ' + IntToStr(Result + 1), #$E734, 'No date', 0, NewGoalTarget));
  TotalsChanged;
end;

initialization
  UsFormat := TFormatSettings.Create('en-US');
  UsFormat.ThousandSeparator := ',';
  UsFormat.DecimalSeparator := '.';
end.
