program Notch;

{ A desk companion at the top of the screen: an overlay window with a notch that opens into a build monitor, the music playing on the PC and a focus timer. }

uses
  RADWinUI.Forms,
  MainWindow.Xaml in 'MainWindow.Xaml.pas',
  MainWindow in 'MainWindow.pas';

begin
  ReportMemoryLeaksOnShutdown := True;
  TWinUIApp.Run(TMainWindow);
end.
