program Haven;

{ A bento-style savings dashboard that follows the Windows theme and accent colour, bound to a Delphi view model. }

uses
  RADWinUI.Forms,
  MainViewModel in 'MainViewModel.pas',
  MainWindow.Xaml in 'MainWindow.Xaml.pas',
  MainWindow in 'MainWindow.pas';

begin
  ReportMemoryLeaksOnShutdown := True;
  TWinUIApp.Run(TMainWindow);
end.
