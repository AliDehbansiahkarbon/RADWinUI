program Gallery;

uses
  RADWinUI.Forms,
  MainViewModel in 'MainViewModel.pas',
  RADWinUI.Gallery.Catalog in 'RADWinUI.Gallery.Catalog.pas',
  MainWindow.Xaml in 'MainWindow.Xaml.pas',
  MainWindow in 'MainWindow.pas';

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  TWinUIApp.Run(TMainWindow);
end.
