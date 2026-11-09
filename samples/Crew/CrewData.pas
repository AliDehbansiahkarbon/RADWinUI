unit CrewData;

// The people Crew shows: one list for the whole app, bound by the People page

interface

uses
  RADWinUI.Binding;

type
  // Published properties are what {Binding Name} and {Binding Role} read
  {$M+}
  TPerson = class
  private
    FName: string;
    FRole: string;
    FEmail: string;
    FNotes: string;
  public
    constructor Create(const AName, ARole, AEmail: string);
    function ToString: string; override;
  published
    property Name: string read FName write FName;
    property Role: string read FRole write FRole;
    property Email: string read FEmail write FEmail;
    property Notes: string read FNotes write FNotes;
  end;
  {$M-}

/// <summary>Everyone in the team, created on first use.</summary>
function People: TWinUIBindableList<TPerson>;
/// <summary>The person with this name, nil when there is none.</summary>
function FindPerson(const AName: string): TPerson;

implementation

uses
  System.SysUtils;

var
  FPeople: TWinUIBindableList<TPerson>;

constructor TPerson.Create(const AName, ARole, AEmail: string);
begin
  inherited Create;
  FName := AName;
  FRole := ARole;
  FEmail := AEmail;
end;

function TPerson.ToString: string;
begin
  Result := FName;
end;

function People: TWinUIBindableList<TPerson>;
begin
  if FPeople = nil then
  begin
    FPeople := TWinUIBindableList<TPerson>.Create;
    FPeople.Add(TPerson.Create('Ada Lovelace', 'Engineering lead', 'ada@crew.example'));
    FPeople.Add(TPerson.Create('Grace Hopper', 'Platform architect', 'grace@crew.example'));
    FPeople.Add(TPerson.Create('Alan Turing', 'Research', 'alan@crew.example'));
    FPeople.Add(TPerson.Create('Katherine Johnson', 'Data science', 'katherine@crew.example'));
    FPeople.Add(TPerson.Create('Margaret Hamilton', 'Quality', 'margaret@crew.example'));
    FPeople.Add(TPerson.Create('Linus Pauling', 'Design', 'linus@crew.example'));
    FPeople.Add(TPerson.Create('Hedy Lamarr', 'Wireless', 'hedy@crew.example'));
    FPeople.Add(TPerson.Create('Dennis Ritchie', 'Systems', 'dennis@crew.example'));
  end;
  Result := FPeople;
end;

function FindPerson(const AName: string): TPerson;
var
  I: Integer;
begin
  for I := 0 to People.Count - 1 do
    if SameText(People[I].Name, AName) then
      Exit(People[I]);
  Result := nil;
end;

initialization

finalization
  FPeople.Free;
end.