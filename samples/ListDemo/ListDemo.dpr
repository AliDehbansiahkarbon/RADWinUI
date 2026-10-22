program ListDemo;

{ A ListView described in ListWindow.xaml: add from a TextBox, remove the selection, show the selected item. }

uses
  RADWinUI.Forms,
  ListWindow.Xaml in 'ListWindow.Xaml.pas',
  ListWindow in 'ListWindow.pas';

begin
  ReportMemoryLeaksOnShutdown := True;
  TWinUIApp.Run(TListWindow);
end.