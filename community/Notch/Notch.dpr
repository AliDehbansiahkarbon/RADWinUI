program Notch;

{ A desk companion at the edge of the screen: an overlay window with a notch that opens into a panel of widgets the user picks, such as app shortcuts, live AI agent activity, remote desktops, the calendar, notes, the music playing on the PC and a focus timer. }

uses
  System.SysUtils,
  System.IOUtils,
  RADWinUI.Forms,
  Notch.Settings in 'Notch.Settings.pas',
  Notch.Shell in 'Notch.Shell.pas',
  Notch.Agents in 'Notch.Agents.pas',
  Notch.Placement in 'Notch.Placement.pas',
  Notch.Usage in 'Notch.Usage.pas',
  Notch.Widgets in 'Notch.Widgets.pas',
  Notch.Details in 'Notch.Details.pas',
  Notch.Tests in 'Notch.Tests.pas',
  MainWindow.Xaml in 'MainWindow.Xaml.pas',
  MainWindow in 'MainWindow.pas';

begin
  // An AI agent's hook: store its event for the running notch and quit, without starting WinUI
  if SameText(ParamStr(1), '--agent-event') then
  begin
    SaveAgentEvent(TPath.Combine(NotchDataFolder, 'events'));
    Exit;
  end;
  ReportMemoryLeaksOnShutdown := True;
  TWinUIApp.Run(TMainWindow);
end.
