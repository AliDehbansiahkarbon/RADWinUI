unit MainViewModel;

interface

uses RADWinUI.Binding;

type
  TMainViewModel = class(TWinUIBindableObject)
  private
    FName, FClock: string;
    FCount: Integer;
    procedure SetName(const AValue: string);
    procedure SetCount(AValue: Integer);
    function GetSummary: string;
  public
    constructor Create;
    procedure RefreshClock;
  published
    property Name: string read FName write SetName;
    property Count: Integer read FCount write SetCount;
    property Summary: string read GetSummary;
    property Clock: string read FClock;
  end;

implementation

uses System.SysUtils;

constructor TMainViewModel.Create;
begin
  inherited;
  FName := 'Delphi developer';
  RefreshClock;
end;

procedure TMainViewModel.SetName(const AValue: string);
begin
  if FName = AValue then Exit;
  FName := AValue;
  Changed('Name');
  Changed('Summary');
end;

procedure TMainViewModel.SetCount(AValue: Integer);
begin
  if FCount = AValue then Exit;
  FCount := AValue;
  Changed('Count');
  Changed('Summary');
end;

function TMainViewModel.GetSummary: string;
begin
  Result := Format('Hello, %s. Pascal has received %d clicks.', [FName, FCount]);
end;

procedure TMainViewModel.RefreshClock;
begin
  FClock := FormatDateTime('ddd, d mmm yyyy  hh:nn:ss', Now);
  Changed('Clock');
end;

end.
