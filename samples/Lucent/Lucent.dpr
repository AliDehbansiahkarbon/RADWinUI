program Lucent;

{ An app publishing studio: frosted glass over drifting ribbons, eight animated pages and live simulated data. }

uses
  RADWinUI.Forms,
  StudioData in 'StudioData.pas',
  MainViewModel in 'MainViewModel.pas',
  MainWindow.Xaml in 'MainWindow.Xaml.pas',
  MainWindow in 'MainWindow.pas';

begin
  ReportMemoryLeaksOnShutdown := True;
  TWinUIApp.Run(TMainWindow);
end.
