program HotReloadTest;

(*
  Checks hot reload (RADWinUI.HotReload) in a Debug build: a generated window
  reloads an edit of its .xaml that XamlCodeGen turned into content and shape,
  through its named pipe, keeps its DataContext and wires its fields and events
  again. A XAML error and a XamlCodeGen error keep the last good content, a
  removed x:Name or other event wiring says "Rebuild needed". The window opens
  where RADWINUI_TEST_MONITOR puts test windows and never takes the focus.
*)

{$APPTYPE CONSOLE}

uses
  RADWinUI.Forms,
  RADWinUI.Preview.HotReload in '..\..\src\IDE\Preview\RADWinUI.Preview.HotReload.pas',
  MainWindow.Xaml in 'MainWindow.Xaml.pas',
  MainWindow in 'MainWindow.pas';

begin
  Writeln('Hot reload');
  TWinUIApp.Run(TMainWindow);
  if Failures = 0 then
    Writeln('Hot reload test PASSED')
  else
    Writeln(Failures, ' failure(s)');
  ExitCode := Ord(Failures > 0);
end.
