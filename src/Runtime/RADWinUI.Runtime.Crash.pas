unit RADWinUI.Runtime.Crash;

{
  Native crash report. An exception nothing handles, typically an
  access violation inside a WinUI DLL, used to end the app without a word. Now it
  writes <app>-<time>.txt (exception, module and offset) and <app>-<time>.dmp
  (a minidump for a debugger) under %LOCALAPPDATA%\RADWinUI\Crashes, tells the
  user where they are, and lets Windows Error Reporting finish as before.

  Delphi exceptions in event handlers never get here: they go to
  TWinUIApp.OnException. A fail-fast termination (__fastfail) bypasses every
  filter, Windows Error Reporting still records it in the Application event log.
  With RADWINUI_TEST_MONITOR set (automated tests) no message box blocks the run.
}

interface

/// <summary>Installs the report for the process, called by TWinUIApplication.Run.</summary>
procedure InstallCrashReport;
/// <summary>The folder reports are written to.</summary>
function CrashFolder: string;

implementation

uses
  Winapi.Windows,
  System.SysUtils;

type
  // MINIDUMP_EXCEPTION_INFORMATION, declared with pack(4) in dbghelp.h
  TMiniDumpExceptionInformation = packed record
    ThreadId: DWORD;
    ExceptionPointers: PExceptionPointers;
    ClientPointers: BOOL;
  end;

  TMiniDumpWriteDump = function(AProcess: THandle; AProcessId: DWORD; AFile: THandle; ADumpType: DWORD;
    AException: Pointer; AUserStream, ACallback: Pointer): BOOL; stdcall;

  TExceptionFilter = function(AInfo: PExceptionPointers): Longint; stdcall;

var
  Previous: TExceptionFilter;
  Reporting: Integer;

function CrashFolder: string;
begin
  Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('LOCALAPPDATA')) + 'RADWinUI\Crashes';
end;

/// The module containing AAddress and the offset into it.
function ModuleOf(AAddress: Pointer; out AOffset: NativeUInt): string;
var
  Info: TMemoryBasicInformation;
  Name: array[0..MAX_PATH] of Char;
begin
  Result := '?';
  AOffset := NativeUInt(AAddress);
  if VirtualQuery(AAddress, Info, SizeOf(Info)) = SizeOf(Info) then
  begin
    AOffset := NativeUInt(AAddress) - NativeUInt(Info.AllocationBase);
    if GetModuleFileName(HMODULE(Info.AllocationBase), Name, Length(Name)) > 0 then
      Result := ExtractFileName(Name);
  end;
end;

procedure WriteDump(const APath: string; AInfo: PExceptionPointers);
var
  Library_: HMODULE;
  Write: TMiniDumpWriteDump;
  F: THandle;
  ExceptionInfo: TMiniDumpExceptionInformation;
begin
  Library_ := LoadLibrary('dbghelp.dll');
  if Library_ = 0 then
    Exit;
  @Write := GetProcAddress(Library_, 'MiniDumpWriteDump');
  if not Assigned(Write) then
    Exit;
  F := CreateFile(PChar(APath), GENERIC_WRITE, 0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if F = INVALID_HANDLE_VALUE then
    Exit;
  try
    ExceptionInfo.ThreadId := GetCurrentThreadId;
    ExceptionInfo.ExceptionPointers := AInfo;
    ExceptionInfo.ClientPointers := False;
    Write(GetCurrentProcess, GetCurrentProcessId, F, 0 { MiniDumpNormal }, @ExceptionInfo, nil, nil);
  finally
    CloseHandle(F);
  end;
end;

/// UTF-8 text through the Win32 API only: the heap or the RTL may be damaged.
procedure SaveText(const APath, AText: string);
var
  F: THandle;
  Bytes: TBytes;
  Written: DWORD;
begin
  F := CreateFile(PChar(APath), GENERIC_WRITE, 0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if F = INVALID_HANDLE_VALUE then
    Exit;
  try
    Bytes := TEncoding.UTF8.GetBytes(AText);
    if Length(Bytes) > 0 then
      WriteFile(F, Bytes[0], Length(Bytes), Written, nil);
  finally
    CloseHandle(F);
  end;
end;

function CrashFilter(AInfo: PExceptionPointers): Longint; stdcall;
var
  App, Stamp, Base, Module, Text: string;
  Offset: NativeUInt;
  Address: Pointer;
  Code: DWORD;
begin
  if InterlockedIncrement(Reporting) = 1 then
  try
    App := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
    Stamp := FormatDateTime('yyyymmdd-hhnnss', Now);
    ForceDirectories(CrashFolder);
    Base := IncludeTrailingPathDelimiter(CrashFolder) + App + '-' + Stamp;
    Code := AInfo.ExceptionRecord.ExceptionCode;
    Address := AInfo.ExceptionRecord.ExceptionAddress;
    Module := ModuleOf(Address, Offset);
    Text := Format('%s stopped unexpectedly.' + sLineBreak + sLineBreak +
      'Exception 0x%.8x at %s+0x%x (thread %d), %s' + sLineBreak +
      'Executable: %s' + sLineBreak + 'Windows %d.%d build %d' + sLineBreak + 'Minidump: %s.dmp',
      [App, Code, Module, Offset, GetCurrentThreadId, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), ParamStr(0),
       Win32MajorVersion, Win32MinorVersion, Win32BuildNumber, Base]);
    SaveText(Base + '.txt', Text);
    WriteDump(Base + '.dmp', AInfo);
    if GetEnvironmentVariable('RADWINUI_TEST_MONITOR') = '' then
      MessageBox(0, PChar(Text + sLineBreak + sLineBreak + 'The report is in ' + CrashFolder + '.'),
        PChar(App), MB_ICONERROR or MB_OK or MB_TASKMODAL);
  except
    // reporting must never hide the original crash
  end;
  if Assigned(Previous) then
    Result := Previous(AInfo)
  else
    Result := 0; // EXCEPTION_CONTINUE_SEARCH: Windows Error Reporting takes over
end;

procedure InstallCrashReport;
begin
  Previous := TExceptionFilter(SetUnhandledExceptionFilter(@CrashFilter));
end;

end.
