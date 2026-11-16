unit RoastSession;

{
  The roast that runs in the roaster: a simulated batch whose bean
  temperature follows a real roast curve. Twelve minutes of roasting pass in
  about forty seconds, so a whole batch fits in a demo. The Roastery page,
  the mini window and the main window all listen to the same session.
}

interface

uses
  System.SysUtils,
  System.Classes,
  RADWinUI.Forms;

type
  TRoastPhase = (Idle, Drying, Maillard, Development, Done);

  TRoastSession = class
  private
    FTimer: TWinUITimer;
    FListeners: TArray<TNotifyEvent>;
    FCoffee: string;
    FBatchNo: Integer;
    FBatchKg: Double;
    FSeconds: Integer;
    FTimes: TArray<Integer>;
    FTemps: TArray<Double>;
    FFirstCrack: Integer;
    FOnFinished: TNotifyEvent;
    function GetRunning: Boolean;
    function GetBeanTemp: Double;
    function GetPhase: TRoastPhase;
    procedure Tick(Sender: TObject);
    procedure Changed;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Charges the roaster with a new batch and starts it.</summary>
    procedure Start(const ACoffee: string; AKg: Double);
    /// <summary>Drops the beans now: the batch is done.</summary>
    procedure Drop;
    procedure Listen(AEvent: TNotifyEvent);
    procedure Unlisten(AEvent: TNotifyEvent);
    /// <summary>The bean temperature after ASeconds of roasting, in C.</summary>
    class function CurveAt(ASeconds: Integer): Double; static;
    property Running: Boolean read GetRunning;
    property Coffee: string read FCoffee;
    property BatchNo: Integer read FBatchNo;
    property BatchKg: Double read FBatchKg;
    property Seconds: Integer read FSeconds;
    property BeanTemp: Double read GetBeanTemp;
    property Phase: TRoastPhase read GetPhase;
    /// <summary>Degrees per minute over the last 30 seconds.</summary>
    function RateOfRise: Double;
    /// <summary>Seconds since first crack, 0 before it.</summary>
    function DevelopmentSeconds: Integer;
    property FirstCrack: Integer read FFirstCrack;
    property Times: TArray<Integer> read FTimes;
    property Temps: TArray<Double> read FTemps;
    property OnFinished: TNotifyEvent read FOnFinished write FOnFinished;
  end;

const
  DropSeconds = 660;     // 11:00, a medium roast
  FirstCrackTemp = 196;  // C
  MaillardTemp = 150;    // C
  StepSeconds = 5;       // roast seconds per tick

/// <summary>The session of the app, created on first use.</summary>
function Roast: TRoastSession;

/// <summary>"8:05" for 485 seconds.</summary>
function FormatClock(ASeconds: Integer): string;

implementation

uses
  System.Math;

var
  FRoast: TRoastSession;

function Roast: TRoastSession;
begin
  if FRoast = nil then
    FRoast := TRoastSession.Create;
  Result := FRoast;
end;

function FormatClock(ASeconds: Integer): string;
begin
  Result := Format('%d:%.2d', [ASeconds div 60, ASeconds mod 60]);
end;

constructor TRoastSession.Create;
begin
  inherited;
  FBatchNo := 41;
  FTimer := TWinUITimer.Create;
  FTimer.Interval := 300;  // 132 ticks of 300 ms: a batch takes about 40 seconds
  FTimer.OnTimer := Tick;
end;

destructor TRoastSession.Destroy;
begin
  FTimer.Free;
  inherited;
end;

// Charge at 200 C, the turning point near 90 C after a minute and a half,
// then a rise that slows down, as on a real drum roaster
class function TRoastSession.CurveAt(ASeconds: Integer): Double;
const
  Charge = 200;
  Turn = 90;
  TurnAt = 90;
begin
  if ASeconds <= TurnAt then
    Result := Turn + (Charge - Turn) * Power(1 - ASeconds / TurnAt, 2.2)
  else
    Result := Turn + 135 * (1 - Exp(-(ASeconds - TurnAt) / 260));
end;

procedure TRoastSession.Start(const ACoffee: string; AKg: Double);
begin
  Inc(FBatchNo);
  FCoffee := ACoffee;
  FBatchKg := AKg;
  FSeconds := 0;
  FFirstCrack := 0;
  FTimes := [0];
  FTemps := [CurveAt(0)];
  FTimer.Enabled := True;
  Changed;
end;

procedure TRoastSession.Drop;
begin
  if not Running then
    Exit;
  FTimer.Enabled := False;
  Changed;
  if Assigned(FOnFinished) then
    FOnFinished(Self);
end;

procedure TRoastSession.Tick(Sender: TObject);
var
  Temp: Double;
begin
  Inc(FSeconds, StepSeconds);
  // A little noise, like a real probe
  Temp := CurveAt(FSeconds) + Sin(FSeconds / 7) * 0.6;
  FTimes := FTimes + [FSeconds];
  FTemps := FTemps + [Temp];
  if (FFirstCrack = 0) and (Temp >= FirstCrackTemp) then
    FFirstCrack := FSeconds;
  if FSeconds >= DropSeconds then
    Drop
  else
    Changed;
end;

function TRoastSession.GetRunning: Boolean;
begin
  Result := FTimer.Enabled;
end;

function TRoastSession.GetBeanTemp: Double;
begin
  if Length(FTemps) = 0 then
    Result := 0
  else
    Result := FTemps[High(FTemps)];
end;

function TRoastSession.GetPhase: TRoastPhase;
begin
  if Length(FTemps) = 0 then
    Result := TRoastPhase.Idle
  else if not Running then
    Result := TRoastPhase.Done
  else if FFirstCrack > 0 then
    Result := TRoastPhase.Development
  else if (FSeconds > 90) and (BeanTemp >= MaillardTemp) then
    Result := TRoastPhase.Maillard
  else
    Result := TRoastPhase.Drying;
end;

function TRoastSession.RateOfRise: Double;
var
  Back: Integer;
begin
  Back := 30 div StepSeconds;
  if Length(FTemps) <= Back then
    Result := 0
  else
    Result := (FTemps[High(FTemps)] - FTemps[High(FTemps) - Back]) * 2;
end;

function TRoastSession.DevelopmentSeconds: Integer;
begin
  if FFirstCrack = 0 then
    Result := 0
  else
    Result := FSeconds - FFirstCrack;
end;

procedure TRoastSession.Listen(AEvent: TNotifyEvent);
begin
  FListeners := FListeners + [AEvent];
end;

procedure TRoastSession.Unlisten(AEvent: TNotifyEvent);
var
  I: Integer;
begin
  for I := High(FListeners) downto 0 do
    if (TMethod(FListeners[I]).Code = TMethod(AEvent).Code) and (TMethod(FListeners[I]).Data = TMethod(AEvent).Data) then
      Delete(FListeners, I, 1);
end;

procedure TRoastSession.Changed;
var
  Listener: TNotifyEvent;
begin
  for Listener in Copy(FListeners) do
    Listener(Self);
end;

initialization

finalization
  FRoast.Free;
end.
