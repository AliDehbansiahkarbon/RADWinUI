program WizardTest;

{
  Checks the File > New wizard templates outside the IDE:
  validation rules, then writes a project with WriteProject.

    WizardTest <RADWinUI root> <output folder> <project name>

  scripts\Test-Wizard.ps1 builds and runs the written project.
}

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  RADWinUI.Wizard.Templates in '..\..\src\IDE\Wizard\RADWinUI.Wizard.Templates.pas';

var
  Failures: Integer;

procedure Check(ACondition: Boolean; const AWhat: string);
begin
  if ACondition then
    Writeln('  [ok] ', AWhat)
  else
  begin
    Writeln('  [failed] ', AWhat);
    Inc(Failures);
  end;
end;

var
  P, Bad: TWizardProject;
  DProj: string;
begin
  if ParamCount <> 3 then
  begin
    Writeln('usage: WizardTest <RADWinUI root> <output folder> <project name>');
    Halt(2);
  end;
  P.Root := ExpandFileName(ParamStr(1));
  P.Directory := ExpandFileName(ParamStr(2));
  P.Name := ParamStr(3);
  P.SdkRelease := ReadSdkRelease(P.Root);
  Writeln('Wizard templates');

  Bad := P;
  Bad.Name := '1st App';
  Check(ValidateProject(Bad) <> '', 'rejects a name that is not an identifier');
  Bad.Name := 'MainWindow';
  Check(ValidateProject(Bad) <> '', 'rejects MainWindow as project name');
  Bad := P;
  Bad.Root := TPath.Combine(P.Directory, 'nowhere');
  Check(ValidateProject(Bad) <> '', 'rejects a folder without RADWinUI');
  Check(ValidateProject(P) = '', 'accepts ' + P.Name + ' in an empty folder');

  DProj := WriteProject(P);
  Check(FileExists(DProj), 'writes ' + ExtractFileName(DProj));
  Check(FileExists(TPath.Combine(P.Directory, P.Name + '.dpr')), 'writes the .dpr');
  Check(Pos('<Platform value="Win64">True</Platform>', TFile.ReadAllText(DProj)) > 0, '.dproj targets Win64');
  Check(Pos('scripts\RADWinUI-PreBuild.cmd', TFile.ReadAllText(DProj)) > 0, '.dproj runs XamlCodeGen before building');
  Check(Pos('scripts\RADWinUI-PostBuild.cmd', TFile.ReadAllText(DProj)) > 0, '.dproj copies the bootstrap DLL after building');
  Check(Pos('py -3', TFile.ReadAllText(DProj)) = 0, '.dproj needs no Python');
  Check(ValidateProject(P) <> '', 'refuses to overwrite the written project');

  // RADWinUI Window: a second window added to the project
  Check(ValidateWindow(P.Directory, 'Second Window') <> '', 'window: rejects a name that is not an identifier');
  Check(ValidateWindow(P.Directory, 'MainWindow') <> '', 'window: rejects an existing unit');
  WriteWindow(P.Directory, 'SecondWindow');
  Check(FileExists(TPath.Combine(P.Directory, 'SecondWindow.xaml')) and
    FileExists(TPath.Combine(P.Directory, 'SecondWindow.pas')), 'window: writes SecondWindow.xaml and .pas');
  AddWindowToProjectFiles(DProj, 'SecondWindow');
  Check(Pos('SecondWindow in ''SecondWindow.pas''', TFile.ReadAllText(ChangeFileExt(DProj, '.dpr'))) > 0,
    'window: added to the .dpr uses clause');
  Check(Pos('<DCCReference Include="SecondWindow.Xaml.pas"/>', TFile.ReadAllText(DProj)) > 0,
    'window: added to the .dproj');

  if Failures > 0 then
  begin
    Writeln('Result: FAIL (', Failures, ')');
    Halt(1);
  end;
  Writeln('Result: PASS');
end.