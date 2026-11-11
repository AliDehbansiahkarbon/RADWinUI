unit StationData;

// The radio stations Tempo plays: one list for the whole app

interface

uses
  RADWinUI.Binding;

type
  // Published properties are what {Binding Name} and {Binding Genre} read
  {$M+}
  TStation = class
  private
    FName: string;
    FGenre: string;
  public
    constructor Create(const AName, AGenre: string);
    function ToString: string; override;
  published
    property Name: string read FName write FName;
    property Genre: string read FGenre write FGenre;
  end;
  {$M-}

/// <summary>Every station, created on first use.</summary>
function Stations: TWinUIBindableList<TStation>;

implementation

var
  FStations: TWinUIBindableList<TStation>;

constructor TStation.Create(const AName, AGenre: string);
begin
  inherited Create;
  FName := AName;
  FGenre := AGenre;
end;

function TStation.ToString: string;
begin
  Result := FName;
end;

function Stations: TWinUIBindableList<TStation>;
begin
  if FStations = nil then
  begin
    FStations := TWinUIBindableList<TStation>.Create;
    FStations.Add(TStation.Create('Lo-fi Study', 'Chill'));
    FStations.Add(TStation.Create('Morning Jazz', 'Jazz'));
    FStations.Add(TStation.Create('Synthwave Drive', 'Electronic'));
    FStations.Add(TStation.Create('Classical Focus', 'Classical'));
    FStations.Add(TStation.Create('Indie Garage', 'Rock'));
    FStations.Add(TStation.Create('Rainforest Ambience', 'Ambient'));
  end;
  Result := FStations;
end;

initialization

finalization
  FStations.Free;
end.