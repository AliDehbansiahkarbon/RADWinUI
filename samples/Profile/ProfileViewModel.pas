unit ProfileViewModel;

{ The view model of ProfileWindow.xaml (DataContextType="TProfile"): the XAML
  binds to its published properties, and the generated window base has a typed
  ViewModel property for it. }

interface

uses
  RADWinUI.Binding;

type
  TProfile = class(TWinUIBindableObject)
  private
    FName: string;
    FCity: string;
    FIsVip: Boolean;
    procedure SetName(const AValue: string);
    procedure SetCity(const AValue: string);
    procedure SetIsVip(AValue: Boolean);
    function GetSummary: string;
  published
    property Name: string read FName write SetName;       // two-way: NameBox writes it
    property City: string read FCity write SetCity;
    property IsVip: Boolean read FIsVip write SetIsVip;  // two-way: VipBox writes it
    property Summary: string read GetSummary;              // one-way, computed
  end;

implementation

procedure TProfile.SetName(const AValue: string);
begin
  if FName = AValue then
    Exit;
  FName := AValue;
  Changed('Name');
  Changed('Summary');
end;

procedure TProfile.SetCity(const AValue: string);
begin
  if FCity = AValue then
    Exit;
  FCity := AValue;
  Changed('City');
  Changed('Summary');
end;

procedure TProfile.SetIsVip(AValue: Boolean);
begin
  if FIsVip = AValue then
    Exit;
  FIsVip := AValue;
  Changed('IsVip');
end;

function TProfile.GetSummary: string;
begin
  Result := FName + ' from ' + FCity;
end;

end.