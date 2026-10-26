unit RADWinUI.Designer.Retention;

{ Keeps the Structure view's nodes alive until the IDE no longer reads them.
  The IDE's tree holds raw node pointers until its deferred rebuild has run,
  so a refresh that freed the previous nodes at once left it reading freed
  memory (an access violation in coreide's TStructureViewForm.InitNode).
  A refresh starts a new generation, older generations go only when the
  caller knows the IDE has moved on (Trim). IDE-free, so
  tests\Designer\DesignerModelTest checks it. }

interface

uses
  System.Classes;

type
  TRetainedNodes = class
  strict private
    FGenerations: TList;
    function Current: TInterfaceList;
  public
    /// <summary>The most generations kept, a safety net if the IDE never rebuilds.</summary>
    const MaxGenerations = 16;
    constructor Create;
    destructor Destroy; override;
    procedure Add(const ANode: IInterface);
    /// <summary>Starts a new generation, the older ones stay alive.</summary>
    procedure Renew;
    /// <summary>Frees every generation but the newest: the IDE reads only its nodes now.</summary>
    procedure Trim;
    /// <summary>Frees every node: the context is going away.</summary>
    procedure Clear;
    function Count: Integer;
    function Generations: Integer;
  end;

implementation

constructor TRetainedNodes.Create;
begin
  inherited;
  FGenerations := TList.Create;
  FGenerations.Add(TInterfaceList.Create);
end;

destructor TRetainedNodes.Destroy;
var
  I: Integer;
begin
  for I := 0 to FGenerations.Count - 1 do
    TInterfaceList(FGenerations[I]).Free;
  FGenerations.Free;
  inherited;
end;

function TRetainedNodes.Current: TInterfaceList;
begin
  Result := TInterfaceList(FGenerations.Last);
end;

procedure TRetainedNodes.Add(const ANode: IInterface);
begin
  Current.Add(ANode);
end;

procedure TRetainedNodes.Renew;
begin
  FGenerations.Add(TInterfaceList.Create);
  while FGenerations.Count > MaxGenerations do
  begin
    TInterfaceList(FGenerations[0]).Free;
    FGenerations.Delete(0);
  end;
end;

procedure TRetainedNodes.Trim;
begin
  while FGenerations.Count > 1 do
  begin
    TInterfaceList(FGenerations[0]).Free;
    FGenerations.Delete(0);
  end;
end;

procedure TRetainedNodes.Clear;
begin
  Trim;
  Current.Clear;
end;

function TRetainedNodes.Count: Integer;
begin
  Result := Current.Count;
end;

function TRetainedNodes.Generations: Integer;
begin
  Result := FGenerations.Count;
end;

end.
