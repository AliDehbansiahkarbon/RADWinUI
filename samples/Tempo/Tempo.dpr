program Tempo;

{ A radio player: a title bar of its own, a tool window, a modal window, a compact overlay mini player, full screen and a remembered window placement. }

uses
  RADWinUI.Forms,
  StationData in 'StationData.pas',
  QueueWindow.Xaml in 'QueueWindow.Xaml.pas',
  QueueWindow in 'QueueWindow.pas',
  AddStationWindow.Xaml in 'AddStationWindow.Xaml.pas',
  AddStationWindow in 'AddStationWindow.pas',
  MiniPlayerWindow.Xaml in 'MiniPlayerWindow.Xaml.pas',
  MiniPlayerWindow in 'MiniPlayerWindow.pas',
  MainWindow.Xaml in 'MainWindow.Xaml.pas',
  MainWindow in 'MainWindow.pas';

begin
  ReportMemoryLeaksOnShutdown := True;
  TWinUIApp.Run(TMainWindow);
end.