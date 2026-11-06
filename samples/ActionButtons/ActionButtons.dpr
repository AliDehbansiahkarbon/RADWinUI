program ActionButtons;

{ The six buttons of the Tool Palette's Action Buttons category on one page. }

uses
  RADWinUI.Forms,
  MainWindow.Xaml in 'MainWindow.Xaml.pas',
  MainWindow in 'MainWindow.pas';

begin
  ReportMemoryLeaksOnShutdown := True;
  TWinUIApp.Run(TMainWindow);
end.
