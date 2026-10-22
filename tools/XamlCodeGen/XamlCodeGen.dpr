program XamlCodeGen;

{
  XamlCodeGen.exe: generates <Name>.Xaml.pas from each window .xaml.

    XamlCodeGen.exe <window .xaml files or folders> [--index RADWinUI.Xaml.json]
    XamlCodeGen.exe --ide-request <temporary .json>

  Without --index it finds src\Generated\RADWinUI.Xaml.json above its own folder.
}

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  RADWinUI.CodeGen.Xml in 'RADWinUI.CodeGen.Xml.pas',
  RADWinUI.CodeGen.Bindings in 'RADWinUI.CodeGen.Bindings.pas',
  RADWinUI.CodeGen in 'RADWinUI.CodeGen.pas';

var
  Args: TArray<string>;
  I: Integer;

begin
  SetLength(Args, ParamCount);
  for I := 1 to ParamCount do
    Args[I - 1] := ParamStr(I);
  ExitCode := RunCodeGen(Args, ExtractFilePath(ParamStr(0)));
end.
