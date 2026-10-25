program Haven;

{ A glassy savings dashboard: acrylic cards over a warm background, bound to a Delphi view model. }

uses
  RADWinUI.Forms,
  MainViewModel in 'MainViewModel.pas',
  MainWindow.Xaml in 'MainWindow.Xaml.pas',
  MainWindow in 'MainWindow.pas';

begin
  ReportMemoryLeaksOnShutdown := True;
  TWinUIApp.Run(TMainWindow);
end.
