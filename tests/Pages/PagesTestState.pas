unit PagesTestState;

// What the test pages report back to PagesTest.dpr

interface

uses
  System.SysUtils,
  RADWinUI.Pages;

var
  LivePages: Integer;
  Events: TArray<string>;
  CardClicks: Integer;
  PendingProceed: TProc;

procedure Note(const AText: string);
function ModeName(AMode: TWinUINavigationMode): string;

implementation

procedure Note(const AText: string);
begin
  Events := Events + [AText];
end;

function ModeName(AMode: TWinUINavigationMode): string;
const
  Names: array[TWinUINavigationMode] of string = ('New', 'Back', 'Forward');
begin
  Result := Names[AMode];
end;

end.