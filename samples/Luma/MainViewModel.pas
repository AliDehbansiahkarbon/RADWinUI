unit MainViewModel;

interface

uses
  RADWinUI.Binding;

type
  TMainViewModel = class(TWinUIBindableObject)
  private
    FClockText, FDateText, FDayCaption, FFocusText, FFocusAction: string;
    FPowerText, FPowerCaption, FMemoryText: string;
    FDayProgress, FFocusProgress: Double;
    FRemaining: UInt64;
    FDeadline: UInt64;
    FRunning: Boolean;
  public
    constructor Create;
    procedure Refresh;
    procedure ToggleFocus;
    procedure ResetFocus;
    property Running: Boolean read FRunning;
  published
    property ClockText: string read FClockText;
    property DateText: string read FDateText;
    property DayCaption: string read FDayCaption;
    property DayProgress: Double read FDayProgress;
    property FocusText: string read FFocusText;
    property FocusAction: string read FFocusAction;
    property FocusProgress: Double read FFocusProgress;
    property PowerText: string read FPowerText;
    property PowerCaption: string read FPowerCaption;
    property MemoryText: string read FMemoryText;
  end;

implementation

uses
  Winapi.Windows,
  System.SysUtils;

const
  FocusDuration = 25 * 60 * 1000;

constructor TMainViewModel.Create;
begin
  inherited;
  FRemaining := FocusDuration;
  Refresh;
end;

procedure TMainViewModel.Refresh;
var
  Current: TDateTime;
  Power: TSystemPowerStatus;
  Memory: TMemoryStatusEx;
  Ticks, Seconds: UInt64;
begin
  Current := Now;
  FClockText := FormatDateTime('hh:nn', Current);
  FDateText := FormatDateTime('dddd, d mmmm yyyy', Current);
  FDayProgress := Frac(Current) * 100;
  FDayCaption := Format('%d%% of the day', [Trunc(FDayProgress)]);
  if FRunning then
  begin
    Ticks := GetTickCount64;
    if Ticks >= FDeadline then
    begin
      FRemaining := 0;
      FRunning := False;
    end
    else
      FRemaining := FDeadline - Ticks;
  end;
  Seconds := (FRemaining + 999) div 1000;
  FFocusText := Format('%.2d:%.2d', [Seconds div 60, Seconds mod 60]);
  FFocusProgress := 100 * (1 - FRemaining / FocusDuration);
  if FRunning then FFocusAction := 'Pause focus'
  else if FRemaining = 0 then FFocusAction := 'Start another session'
  else if FRemaining < FocusDuration then FFocusAction := 'Resume focus'
  else FFocusAction := 'Start focus';
  if GetSystemPowerStatus(Power) then
  begin
    if (Power.BatteryFlag and 128 <> 0) or (Power.BatteryLifePercent = 255) then
      FPowerText := 'Plugged in'
    else
      FPowerText := IntToStr(Power.BatteryLifePercent) + '%';
    if Power.ACLineStatus = 1 then FPowerCaption := 'Connected to power'
    else FPowerCaption := 'On battery';
  end
  else
  begin
    FPowerText := 'Unavailable';
    FPowerCaption := 'No power reading';
  end;
  Memory.dwLength := SizeOf(Memory);
  if GlobalMemoryStatusEx(Memory) then FMemoryText := IntToStr(Memory.dwMemoryLoad) + '%'
  else FMemoryText := '--';
  Changed('ClockText');
  Changed('DateText');
  Changed('DayCaption');
  Changed('DayProgress');
  Changed('FocusText');
  Changed('FocusAction');
  Changed('FocusProgress');
  Changed('PowerText');
  Changed('PowerCaption');
  Changed('MemoryText');
end;

procedure TMainViewModel.ToggleFocus;
begin
  if FRunning then
  begin
    Refresh;
    FRunning := False;
  end
  else
  begin
    if FRemaining = 0 then FRemaining := FocusDuration;
    FDeadline := GetTickCount64 + FRemaining;
    FRunning := True;
  end;
  Refresh;
end;

procedure TMainViewModel.ResetFocus;
begin
  FRunning := False;
  FRemaining := FocusDuration;
  Refresh;
end;

end.
