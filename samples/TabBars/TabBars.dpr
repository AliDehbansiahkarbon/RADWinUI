program TabBars;

{ The six tab bars of the Tool Palette's Tab Bars category on one page. }

uses
  RADWinUI.Forms,
  MainWindow.Xaml in 'MainWindow.Xaml.pas',
  MainWindow in 'MainWindow.pas';

begin
  ReportMemoryLeaksOnShutdown := True;
  TWinUIApp.Run(TMainWindow);
end.
