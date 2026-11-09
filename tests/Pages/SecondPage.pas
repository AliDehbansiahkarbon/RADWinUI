unit SecondPage;

interface

uses
  RADWinUI.Pages,
  SecondPage.Xaml;

type
  TSecondPage = class(TSecondPageBase)
  protected
    procedure NavigatedTo(const AArgs: TWinUINavigationArgs); override;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

implementation

uses
  PagesTestState;

constructor TSecondPage.Create;
begin
  inherited;
  Inc(LivePages);
end;

destructor TSecondPage.Destroy;
begin
  Dec(LivePages);
  inherited;
end;

procedure TSecondPage.NavigatedTo(const AArgs: TWinUINavigationArgs);
begin
  ParameterText.Text := AArgs.Parameter.AsString;
  Note('Second:' + ModeName(AArgs.Mode) + ':' + AArgs.Parameter.AsString);
end;

end.