program Quill;

{ A notes app in three languages: file pickers, message boxes, Windows notifications and single-instance activation. }

uses
  Winapi.Windows,
  Winapi.ShellAPI,
  System.SysUtils,
  RADWinUI.Forms,
  QuillWindow.Xaml in 'QuillWindow.Xaml.pas',
  QuillWindow in 'QuillWindow.pas';

var
  Previous: THandle;

begin
  ReportMemoryLeaksOnShutdown := True;
  // Started again in another language: the previous Quill ends first, or it would get this start
  if (ParamCount = 2) and SameText(ParamStr(1), '--after') then
  begin
    Previous := OpenProcess(SYNCHRONIZE, False, StrToIntDef(ParamStr(2), 0));
    if Previous <> 0 then
    begin
      WaitForSingleObject(Previous, 10000);
      CloseHandle(Previous);
    end;
  end;
  // The language picked in Settings, else the Windows language
  TWinUIApp.Language := SavedLanguage;
  // A second start (another .qnote, a quill:// link) goes to the running window
  TWinUIApp.SingleInstance := True;
  TWinUIApp.OnActivated := TQuillWindow.Activated;
  TWinUIApp.Run(TQuillWindow);
  if RestartQuill then
    ShellExecute(0, nil, PChar(ParamStr(0)), PChar('--after ' + IntToStr(GetCurrentProcessId)), nil, SW_SHOWNORMAL);
end.
