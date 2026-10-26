unit RADWinUI.Designer.Retention;

{ Keeps the Structure view's nodes alive one refresh longer. The IDE's tree
  holds raw node pointers until its deferred rebuild has run, so a refresh
  that freed the previous nodes at once left it reading freed memory (an
  access violation in coreide's TStructureViewForm.InitNode). IDE-free, so
  tests\Designer\DesignerModelTest checks it. }

interface

uses
  System.Classes;

type
  TRetainedNodes = class
  strict private
    FCurrent, FPrevious: TInterfaceList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const ANode: IInterface);
    /// <summary>Frees the generation before the current one, the current one is kept for one more refresh.</summary>
    procedure Renew;
    /// <summary>Frees every node: the context is going away.</summary>
    procedure Clear;
    function Count: Integer;
  end;

implementation

constructor TRetainedNodes.Create;
begin
  inherited;
  FCurrent := TInterfaceList.Create;
  FPrevious := TInterfaceList.Create;
end;

destructor TRetainedNodes.Destroy;
begin
  Clear;
  FCurrent.Free;
  FPrevious.Free;
  inherited;
end;

procedure TRetainedNodes.Add(const ANode: IInterface);
begin
  FCurrent.Add(ANode);
end;

procedure TRetainedNodes.Renew;
var
  Swap: TInterfaceList;
begin
  FPrevious.Clear;
  Swap := FPrevious;
  FPrevious := FCurrent;
  FCurrent := Swap;
end;

procedure TRetainedNodes.Clear;
begin
  FCurrent.Clear;
  FPrevious.Clear;
end;

function TRetainedNodes.Count: Integer;
begin
  Result := FCurrent.Count;
end;

end.
