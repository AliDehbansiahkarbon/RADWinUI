program ControlsIndex;

{
  Writes src\Framework\RADWinUI.Controls.json: the type index of RADWinUI's
  own controls (RADWinUI.Controls) for XamlCodeGen and the designer.

  Command line: ControlsIndex <output .json>
}

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  RADWinUI.CustomControls,
  RADWinUI.Controls;

begin
  if ParamCount <> 1 then
  begin
    Writeln(ErrOutput, 'usage: ControlsIndex <output .json>');
    ExitCode := 2;
    Exit;
  end;
  // Describing the controls needs no WinRT: DefineType only records names and kinds
  TFile.WriteAllBytes(ParamStr(1), TEncoding.UTF8.GetBytes(TWinUICustomControls.TypeIndexJson));
  Writeln(ParamStr(1), ': ', Length(TWinUICustomControls.Types), ' controls');
end.
