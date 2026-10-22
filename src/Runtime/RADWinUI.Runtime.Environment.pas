unit RADWinUI.Runtime.Environment;

{
  Process environment checks that WinUI 3 depends on.
  WinUI 3 fails in an elevated process, so apps check this before startup.
}

interface

/// <summary>True when the current process runs elevated (as administrator).</summary>
function IsProcessElevated: Boolean;

/// <summary>Raises an exception with a readable message when the process is elevated.</summary>
procedure EnsureNotElevated;

implementation

uses
  Winapi.Windows,
  System.SysUtils;

type
  // TOKEN_ELEVATION (winnt.h)
  TTokenElevationInfo = record
    TokenIsElevated: DWORD;
  end;

const
  TokenElevationClass = 20; // TOKEN_INFORMATION_CLASS.TokenElevation

// Declared with a DWORD class so values beyond the RTL enum range are passed safely.
function GetTokenInformationRaw(TokenHandle: THandle; TokenInformationClass: DWORD;
  TokenInformation: Pointer; TokenInformationLength: DWORD;
  var ReturnLength: DWORD): BOOL; stdcall; external advapi32 name 'GetTokenInformation';

function IsProcessElevated: Boolean;
var
  Token: THandle;
  Elevation: TTokenElevationInfo;
  ReturnLength: DWORD;
begin
  Result := False;
  if not OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, Token) then
    Exit;
  try
    if GetTokenInformationRaw(Token, TokenElevationClass, @Elevation, SizeOf(Elevation),
      ReturnLength) then
      Result := Elevation.TokenIsElevated <> 0;
  finally
    CloseHandle(Token);
  end;
end;

procedure EnsureNotElevated;
begin
  if IsProcessElevated then
    raise Exception.Create('WinUI 3 cannot run in an elevated process. ' +
      'Start the application (or RAD Studio) without "Run as administrator".');
end;

end.
