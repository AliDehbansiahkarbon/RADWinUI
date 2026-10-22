program CrashReportTest;

{
  Checks the native crash report: a copy of this program started
  with "crash" installs the report and dies of an access violation on a plain
  Win32 thread, where no Delphi handler catches it, the report (.txt) and the
  minidump (.dmp) must exist afterwards. RADWINUI_TEST_MONITOR keeps the message
  box away.
}

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.SysUtils,
  System.IOUtils,
  RADWinUI.Runtime.Crash in '..\..\src\Runtime\RADWinUI.Runtime.Crash.pas';

function Crasher(AParameter: Pointer): DWORD; stdcall;
begin
  PInteger(nil)^ := 1;
  Result := 0;
end;

var
  Thread: THandle;
  ThreadId: DWORD;
  Startup: TStartupInfo;
  Process: TProcessInformation;
  CommandLine, Report: string;
  Code: DWORD;
  Failures: Integer;

procedure Check(AOk: Boolean; const AWhat: string);
begin
  if AOk then
    Writeln('  [ok] ', AWhat)
  else
  begin
    Writeln('  [failed] ', AWhat);
    Inc(Failures);
  end;
end;

begin
  if ParamStr(1) = 'crash' then
  begin
    InstallCrashReport;
    Thread := CreateThread(nil, 0, @Crasher, nil, 0, ThreadId);
    WaitForSingleObject(Thread, INFINITE);
    Exit;
  end;
  Writeln('Native crash report');
  Failures := 0;
  ForceDirectories(CrashFolder);
  for Report in TDirectory.GetFiles(CrashFolder, 'CrashReportTest-*') do
    TFile.Delete(Report);
  SetEnvironmentVariable('RADWINUI_TEST_MONITOR', 'secondary');
  CommandLine := '"' + ParamStr(0) + '" crash';
  UniqueString(CommandLine);
  Startup := Default(TStartupInfo);
  Startup.cb := SizeOf(Startup);
  Win32Check(CreateProcess(nil, PChar(CommandLine), nil, nil, False, 0, nil, nil, Startup, Process));
  WaitForSingleObject(Process.hProcess, 60000);
  GetExitCodeProcess(Process.hProcess, Code);
  CloseHandle(Process.hThread);
  CloseHandle(Process.hProcess);
  Check(Code = $C0000005, Format('the crashing copy ended with an access violation (0x%.8x)', [Code]));
  Report := '';
  for Report in TDirectory.GetFiles(CrashFolder, 'CrashReportTest-*.txt') do
    Break;
  Check((Report <> '') and TFile.ReadAllText(Report).Contains('Exception 0xC0000005 at CrashReportTest.exe+0x'),
    'the report names the exception and the module: ' + Report);
  Check((Report <> '') and FileExists(ChangeFileExt(Report, '.dmp')) and
    (TFile.GetSize(ChangeFileExt(Report, '.dmp')) > 0), 'a minidump was written next to it');
  for Report in TDirectory.GetFiles(CrashFolder, 'CrashReportTest-*') do
    TFile.Delete(Report);
  if Failures = 0 then
    Writeln('Crash report test PASSED')
  else
    Writeln('Crash report test FAILED');
  ExitCode := Ord(Failures > 0);
end.
