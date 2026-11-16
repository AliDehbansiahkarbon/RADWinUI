program AdvancedComponents;

{ RADWinUI's advanced controls on one page: the Text Fields, Swipe Actions,
  Pagination and Progress Steps categories of the Tool Palette, with the Tab
  Bars and the Action Buttons. }

uses
  RADWinUI.Forms,
  MainWindow.Xaml in 'MainWindow.Xaml.pas',
  MainWindow in 'MainWindow.pas';

begin
  ReportMemoryLeaksOnShutdown := True;
  TWinUIApp.Run(TMainWindow);
end.
