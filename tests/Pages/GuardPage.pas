unit GuardPage;

interface

uses
  RADWinUI.Pages,
  GuardPage.Xaml;

type
  TGuardPage = class(TGuardPageBase)
  protected
    procedure NavigatingFrom(var AArgs: TWinUINavigatingArgs); override;
  public
    Dirty: Boolean;
    constructor Create; override;
    destructor Destroy; override;
  end;

implementation

uses
  PagesTestState;

constructor TGuardPage.Create;
begin
  inherited;
  Inc(LivePages);
end;

destructor TGuardPage.Destroy;
begin
  Dec(LivePages);
  inherited;
end;

procedure TGuardPage.NavigatingFrom(var AArgs: TWinUINavigatingArgs);
begin
  // A real page would ask with MessageDlg here and call Proceed on Yes
  if Dirty then
  begin
    AArgs.Cancel := True;
    PendingProceed := AArgs.Proceed;
    Note('Guard:cancelled');
  end;
end;

end.