unit FirstPage;

interface

uses
  RADWinUI.Framework,
  RADWinUI.Pages,
  FirstPage.Xaml;

type
  TFirstPage = class(TFirstPageBase)
  protected
    procedure NavigatedTo(const AArgs: TWinUINavigationArgs); override;
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    procedure CardClicked(Sender: TObject; const E: TWinValue);
  end;

implementation

uses
  PagesTestState;

constructor TFirstPage.Create;
begin
  inherited;
  Inc(LivePages);
end;

destructor TFirstPage.Destroy;
begin
  Dec(LivePages);
  inherited;
end;

procedure TFirstPage.NavigatedTo(const AArgs: TWinUINavigationArgs);
begin
  Note('First:' + ModeName(AArgs.Mode));
end;

procedure TFirstPage.CardClicked(Sender: TObject; const E: TWinValue);
begin
  Inc(CardClicks);
end;

end.