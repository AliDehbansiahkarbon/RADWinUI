unit CachedPage;

interface

uses
  RADWinUI.Pages,
  CachedPage.Xaml;

type
  TCachedPage = class(TCachedPageBase)
  public
    Count: Integer;
    constructor Create; override;
    destructor Destroy; override;
  end;

implementation

uses
  PagesTestState;

constructor TCachedPage.Create;
begin
  inherited;
  KeepAlive := True;
  Inc(LivePages);
end;

destructor TCachedPage.Destroy;
begin
  Dec(LivePages);
  inherited;
end;

end.