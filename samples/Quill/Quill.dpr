program Quill;

{ A notes app: file pickers, message boxes, Windows notifications and single-instance activation. }

uses
  RADWinUI.Forms,
  QuillWindow.Xaml in 'QuillWindow.Xaml.pas',
  QuillWindow in 'QuillWindow.pas';

begin
  ReportMemoryLeaksOnShutdown := True;
  // A second start (another .qnote, a quill:// link) goes to the running window
  TWinUIApp.SingleInstance := True;
  TWinUIApp.OnActivated := TQuillWindow.Activated;
  TWinUIApp.Run(TQuillWindow);
end.
