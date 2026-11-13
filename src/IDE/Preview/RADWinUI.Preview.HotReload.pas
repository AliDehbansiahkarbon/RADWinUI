unit RADWinUI.Preview.HotReload;

{
  The IDE's side of hot reload, without the IDE: which running RADWinUI apps
  listen (Debug builds open \\.\pipe\RADWinUI.HotReload.<process id>), which of
  them a .xaml file belongs to, and the message that reaches them. The format is
  the one RADWinUI.HotReload reads: UTF-8, fields separated by #0.
}

interface

uses
  System.SysUtils;

type
  THotReloadApp = record
    ProcessId: Cardinal;
    ExePath: string;
  end;

/// <summary>The apps of this user that listen for hot reload now.</summary>
function HotReloadApps: TArray<THotReloadApp>;
/// <summary>
///   Whether the app at AExePath was built from the folder of AXamlFile: its exe is in
///   that folder or below it (Win64\Debug), so a file of another project never reaches it.
/// </summary>
function AppUsesFile(const AExePath, AXamlFile: string): Boolean;
/// <summary>The bytes RADWinUI.HotReload reads.</summary>
function HotReloadMessage(const AFile, AShape, AContent, ARaw, AError: string): TBytes;
/// <summary>Writes the message to the app's pipe; False when it is not listening any more.</summary>
function SendHotReload(AProcessId: Cardinal; const AMessage: TBytes): Boolean;

implementation

uses
  Winapi.Windows;

const
  PROCESS_QUERY_LIMITED_INFORMATION = $1000;
  Prefix = 'RADWinUI.HotReload.';

function QueryFullProcessImageName(AProcess: THandle; AFlags: DWORD; AName: PChar; var ASize: DWORD): BOOL; stdcall;
  external kernel32 name 'QueryFullProcessImageNameW';

function ExeOf(AProcessId: Cardinal): string;
var
  Process: THandle;
  Name: array[0..MAX_PATH * 2] of Char;
  Size: DWORD;
begin
  Result := '';
  Process := OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, AProcessId);
  if Process = 0 then
    Exit;
  try
    Size := Length(Name);
    if QueryFullProcessImageName(Process, 0, Name, Size) then
      SetString(Result, Name, Size);
  finally
    CloseHandle(Process);
  end;
end;

function HotReloadApps: TArray<THotReloadApp>;
var
  Find: THandle;
  Data: TWin32FindData;
  Name: string;
  App: THotReloadApp;
begin
  Result := nil;
  Find := FindFirstFile('\\.\pipe\*', Data);
  if Find = INVALID_HANDLE_VALUE then
    Exit;
  try
    repeat
      Name := Data.cFileName;
      if Name.StartsWith(Prefix) and TryStrToUInt(Name.Substring(Length(Prefix)), App.ProcessId) then
      begin
        App.ExePath := ExeOf(App.ProcessId);
        if App.ExePath <> '' then
          Result := Result + [App];
      end;
    until not FindNextFile(Find, Data);
  finally
    Winapi.Windows.FindClose(Find);
  end;
end;

function AppUsesFile(const AExePath, AXamlFile: string): Boolean;
var
  Folder: string;
begin
  Folder := IncludeTrailingPathDelimiter(ExtractFileDir(ExpandFileName(AXamlFile)));
  Result := SameText(Copy(ExpandFileName(AExePath), 1, Length(Folder)), Folder);
end;

function HotReloadMessage(const AFile, AShape, AContent, ARaw, AError: string): TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(string.Join(#0, ['RWHR1', ExtractFileName(AFile), AShape, AContent, ARaw, AError]));
end;

function SendHotReload(AProcessId: Cardinal; const AMessage: TBytes): Boolean;
var
  Name: string;
  Pipe: THandle;
  Written: DWORD;
begin
  Name := '\\.\pipe\' + Prefix + IntToStr(AProcessId);
  // The app takes one message at a time: wait briefly when it is reading another one
  Pipe := CreateFile(PChar(Name), GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);
  if (Pipe = INVALID_HANDLE_VALUE) and (GetLastError = ERROR_PIPE_BUSY) and WaitNamedPipe(PChar(Name), 500) then
    Pipe := CreateFile(PChar(Name), GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);
  if Pipe = INVALID_HANDLE_VALUE then
    Exit(False);
  try
    Result := (Length(AMessage) = 0) or (WriteFile(Pipe, AMessage[0], Length(AMessage), Written, nil) and
      (Integer(Written) = Length(AMessage)));
  finally
    CloseHandle(Pipe);
  end;
end;

end.
