unit RADWinUI.Wizard.Registration;

{
  File > New > Other > Delphi Projects > RADWinUI Application, and
  File > New > Other > Delphi Files > RADWinUI Window, Page and User Control.

  Asks for a project name and a parent folder in a dialog drawn with the IDE
  theme (RADWinUI.Wizard.Dialog), writes the project with
  RADWinUI.Wizard.Templates, runs XamlCodeGen once so MainWindow.Xaml.pas
  exists before the first build, and opens the project. Nothing of WinUI
  runs in the IDE: the wizard only writes files and starts XamlCodeGen.exe.
}

interface

procedure Register;

/// <summary>The RADWinUI checkout: RADWINUI_ROOT, or the folder the package was built in.</summary>
function RootFolder: string;
/// <summary>Runs ACommandLine without a window and waits (60 s at most), True when it exits with 0.</summary>
function RunHidden(const ACommandLine: string): Boolean;

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  System.IOUtils,
  Vcl.Graphics,
  ToolsAPI,
  RADWinUI.Wizard.Templates,
  RADWinUI.Wizard.Dialog,
  RADWinUI.Preview.Command;

type
  TRADWinUIWizard = class(TNotifierObject, IOTAWizard, IOTARepositoryWizard, IOTARepositoryWizard60,
    IOTARepositoryWizard80, IOTAProjectWizard)
  public
    { IOTAWizard }
    function GetIDString: string;
    function GetName: string;
    function GetState: TWizardState;
    procedure Execute;
    { IOTARepositoryWizard }
    function GetAuthor: string;
    function GetComment: string;
    function GetPage: string;
    function GetGlyph: THandle;
    { IOTARepositoryWizard60 }
    function GetDesigner: string;
    { IOTARepositoryWizard80 }
    function GetGalleryCategory: IOTAGalleryCategory;
    function GetPersonality: string;
  end;

  /// <summary>File > New > RADWinUI Window, Page or User Control for the active project.</summary>
  TRADWinUIFileWizard = class(TNotifierObject, IOTAWizard, IOTARepositoryWizard, IOTARepositoryWizard60,
    IOTARepositoryWizard80, IOTAFormWizard)
  strict private
    FKind: TWizardFileKind;
  public
    constructor Create(AKind: TWizardFileKind);
    { IOTAWizard }
    function GetIDString: string;
    function GetName: string;
    function GetState: TWizardState;
    procedure Execute;
    { IOTARepositoryWizard }
    function GetAuthor: string;
    function GetComment: string;
    function GetPage: string;
    function GetGlyph: THandle;
    { IOTARepositoryWizard60 }
    function GetDesigner: string;
    { IOTARepositoryWizard80 }
    function GetGalleryCategory: IOTAGalleryCategory;
    function GetPersonality: string;
  end;

/// The RADWinUI checkout: RADWINUI_ROOT, or the folder the package was built in
/// (<root>\build\packages\<platform>\RADWinUIWizard[32].bpl).
function RootFolder: string;
begin
  Result := GetEnvironmentVariable('RADWINUI_ROOT');
  if Result = '' then
    Result := ExpandFileName(TPath.Combine(ExtractFilePath(GetModuleName(HInstance)), '..\..\..'));
  Result := ExcludeTrailingPathDelimiter(Result);
end;

/// Runs ACommandLine without a window and waits, True when it exits with 0.
function RunHidden(const ACommandLine: string): Boolean;
var
  Startup: TStartupInfo;
  Process: TProcessInformation;
  CommandLine: string;
  ExitCode: DWORD;
begin
  Startup := Default(TStartupInfo);
  Startup.cb := SizeOf(Startup);
  CommandLine := ACommandLine; // CreateProcess may write to the buffer
  UniqueString(CommandLine);
  Result := CreateProcess(nil, PChar(CommandLine), nil, nil, False, CREATE_NO_WINDOW, nil, nil,
    Startup, Process);
  if not Result then
    Exit;
  try
    Result := (WaitForSingleObject(Process.hProcess, 60000) = WAIT_OBJECT_0) and
      GetExitCodeProcess(Process.hProcess, ExitCode) and (ExitCode = 0);
  finally
    CloseHandle(Process.hThread);
    CloseHandle(Process.hProcess);
  end;
end;

procedure OpenWindowDesigner(const ADirectory, AUnitName: string);
var
  ActionServices: IOTAActionServices;
  Module: IOTAModule;
  Source: IOTASourceEditor;
  I, ViewIndex: Integer;
  XamlFile: string;
begin
  ActionServices := BorlandIDEServices as IOTAActionServices;
  ActionServices.OpenFile(TPath.Combine(ADirectory, AUnitName + '.pas'));
  XamlFile := TPath.Combine(ADirectory, AUnitName + '.xaml');
  if not ActionServices.OpenFile(XamlFile) then
    Exit;
  Module := (BorlandIDEServices as IOTAModuleServices).FindModule(XamlFile);
  if Module = nil then
    Exit;
  for I := 0 to Module.ModuleFileCount - 1 do
    if Supports(Module.ModuleFileEditors[I], IOTASourceEditor, Source) and
      SameText(Source.FileName, XamlFile) then
    begin
      Source.Show;
      for ViewIndex := 0 to Source.GetSubViewCount - 1 do
        if SameText(Source.GetSubViewIdentifier(ViewIndex), 'RADWinUI.Xaml.Design') then
        begin
          Source.SwitchToView(ViewIndex);
          Exit;
        end;
    end;
end;

{ TRADWinUIWizard }

function TRADWinUIWizard.GetIDString: string;
begin
  Result := 'RADWinUI.Wizard.Application';
end;

function TRADWinUIWizard.GetName: string;
begin
  Result := 'RADWinUI Application';
end;

function TRADWinUIWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

function TRADWinUIWizard.GetAuthor: string;
begin
  Result := 'RADWinUI';
end;

function TRADWinUIWizard.GetComment: string;
begin
  Result := 'A WinUI 3 application for Win64: MainWindow.xaml with its code in MainWindow.pas';
end;

function TRADWinUIWizard.GetPage: string;
begin
  Result := 'Delphi Projects';
end;

function TRADWinUIWizard.GetGlyph: THandle;
begin
  Result := 0;
end;

function TRADWinUIWizard.GetDesigner: string;
begin
  Result := dAny;
end;

function TRADWinUIWizard.GetGalleryCategory: IOTAGalleryCategory;
begin
  Result := (BorlandIDEServices as IOTAGalleryCategoryManager).FindCategory(sCategoryDelphiNew);
end;

function TRADWinUIWizard.GetPersonality: string;
begin
  Result := sDelphiPersonality;
end;

procedure TRADWinUIWizard.Execute;
var
  Project: TWizardProject;
  Name, Parent, Error, DProj: string;
begin
  Project.Root := RootFolder;
  Name := 'WinUIApp1';
  Parent := LastProjectFolder;
  if not AskNewProject(Name, Parent,
    function(const AName, ALocation: string): string
    var
      Candidate: TWizardProject;
    begin
      Candidate := Project;
      Candidate.Name := AName;
      try
        Candidate.Directory := TPath.Combine(ALocation, AName);
      except
        on EArgumentException do
          Exit('The project name must be a Pascal identifier (letters, digits, underscore).');
      end;
      Result := ValidateProject(Candidate);
      if (Result = '') and (ALocation = '') then
        Result := 'Choose a location for the project.'
      else if (Result = '') and not TDirectory.Exists(ALocation) then
        Result := 'The location ' + ALocation + ' does not exist.';
    end) then
    Exit;
  Project.Name := Name;
  Project.Directory := TPath.Combine(Parent, Name);
  Error := ValidateProject(Project);
  if Error <> '' then
  begin
    ShowWizardMessage(GetName, 'The project cannot be created', Error, True);
    Exit;
  end;
  Project.SdkRelease := ReadSdkRelease(Project.Root);
  DProj := WriteProject(Project);
  if not RunHidden(XamlCodeGenCommand(Project)) then
    ShowWizardMessage(GetName, 'XamlCodeGen did not run', 'bin\XamlCodeGen.exe is missing or failed (Build All of ' +
      RADWinUIGroup + ' makes it). The first build will try again to generate MainWindow.Xaml.pas.', True);
  if (BorlandIDEServices as IOTAActionServices).OpenProject(DProj, True) then
    OpenWindowDesigner(Project.Directory, 'MainWindow');
end;

{ TRADWinUIFileWizard }

const
  FileWizardIds: array[TWizardFileKind] of string = ('RADWinUI.Wizard.Window', 'RADWinUI.Wizard.Page',
    'RADWinUI.Wizard.UserControl', 'RADWinUI.Wizard.Resource');
  FileWizardNames: array[TWizardFileKind] of string = ('RADWinUI Window', 'RADWinUI Page', 'RADWinUI User Control',
    'RADWinUI Resource File');
  FileWizardDefaults: array[TWizardFileKind] of string = ('SecondWindow', 'DetailsPage', 'InfoCard', 'en-US');

constructor TRADWinUIFileWizard.Create(AKind: TWizardFileKind);
begin
  inherited Create;
  FKind := AKind;
end;

function TRADWinUIFileWizard.GetIDString: string;
begin
  Result := FileWizardIds[FKind];
end;

function TRADWinUIFileWizard.GetName: string;
begin
  Result := FileWizardNames[FKind];
end;

function TRADWinUIFileWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

function TRADWinUIFileWizard.GetAuthor: string;
begin
  Result := 'RADWinUI';
end;

function TRADWinUIFileWizard.GetComment: string;
const
  Comments: array[TWizardFileKind] of string = (
    'Another window for a RADWinUI application: <Name>.xaml with its code in <Name>.pas',
    'A page that a frame shows and navigates to: <Name>.xaml with its code in <Name>.pas',
    'A user control to use in other XAML of the project: <Name>.xaml with its code in <Name>.pas',
    'The texts of the application in one language: Strings\<language>\Resources.resw, for x:Uid and ' +
    'TWinUIResources');
begin
  Result := Comments[FKind];
end;

function TRADWinUIFileWizard.GetPage: string;
begin
  Result := 'Delphi Files';
end;

function TRADWinUIFileWizard.GetGlyph: THandle;
begin
  Result := 0;
end;

function TRADWinUIFileWizard.GetDesigner: string;
begin
  Result := dAny;
end;

function TRADWinUIFileWizard.GetGalleryCategory: IOTAGalleryCategory;
begin
  Result := (BorlandIDEServices as IOTAGalleryCategoryManager).FindCategory(sCategoryDelphiNewFiles);
end;

function TRADWinUIFileWizard.GetPersonality: string;
begin
  Result := sDelphiPersonality;
end;

procedure TRADWinUIFileWizard.Execute;
const
  Texts: array[TWizardFileKind] of string = (
    'Another window for the active project: a .xaml file with its code in a .pas unit, added to the project.',
    'A page for the active project: a .xaml file with a <Page> root and its code in a .pas unit. ' +
    'A frame shows it with Navigate.',
    'A user control for the active project: a .xaml file with a <UserControl> root and its code in a .pas unit. ' +
    'Other XAML of the project uses it as <local:Name/>.',
    'The texts of the active project in one language (en-US, de-DE, fa-IR): Strings\<language>\Resources.resw. ' +
    'XAML shows them through x:Uid, code reads them with TWinUIResources.GetString. A new language starts as a ' +
    'copy of en-US to translate.');
var
  Project: IOTAProject;
  Target: TWizardProject;
  UnitName: string;
begin
  Project := GetActiveProject;
  if Project = nil then
  begin
    ShowWizardMessage(GetName, 'No project is open', 'Open a RADWinUI application first.', False);
    Exit;
  end;
  Target.Directory := ExtractFileDir(Project.FileName);
  Target.Root := RootFolder;
  if not FileExists(TPath.Combine(Target.Directory, 'MainWindow.xaml')) and
    (Pos('xamlcodegen', LowerCase(TFile.ReadAllText(Project.FileName))) = 0) then
  begin
    ShowWizardMessage(GetName, 'Not a RADWinUI application', 'The active project is not a RADWinUI application.',
      False);
    Exit;
  end;
  UnitName := FileWizardDefaults[FKind];
  if (FKind = fkResource) and FileExists(ResourceFilePath(Target.Directory, UnitName)) then
    UnitName := 'de-DE';
  if not AskNewUnit('New ' + GetName, Texts[FKind], UnitName,
    function(const AName, ALocation: string): string
    begin
      Result := ValidateNewFile(Target.Directory, AName, FKind);
    end) then
    Exit;
  WriteNewFile(Target.Directory, UnitName, FKind);
  if FKind = fkResource then
  begin
    // The post-build step builds resources.pri from every Strings\<language> folder
    Project.AddFile(ResourceFilePath(Target.Directory, UnitName), False);
    (BorlandIDEServices as IOTAActionServices).OpenFile(ResourceFilePath(Target.Directory, UnitName));
    Exit;
  end;
  if not RunHidden(XamlCodeGenCommand(Target)) then
    ShowWizardMessage(GetName, 'XamlCodeGen did not run', 'bin\XamlCodeGen.exe is missing or failed (Build All of ' +
      RADWinUIGroup + ' makes it). The next build will try again to generate ' + UnitName + '.Xaml.pas.', True);
  // The pre-build event already covers every .xaml file of the project folder
  Project.AddFile(TPath.Combine(Target.Directory, UnitName + '.Xaml.pas'), True);
  Project.AddFile(TPath.Combine(Target.Directory, UnitName + '.pas'), True);
  Project.AddFile(TPath.Combine(Target.Directory, UnitName + '.xaml'), False);
  OpenWindowDesigner(Target.Directory, UnitName);
end;

var
  Registered: Boolean;

procedure AddSplashBranding;
var
  Bitmap: TBitmap;
begin
  if SplashScreenServices = nil then Exit;
  Bitmap := TBitmap.Create;
  try
    Bitmap.PixelFormat := pf24bit;
    Bitmap.SetSize(24, 24);
    Bitmap.Canvas.Brush.Color := clFuchsia;
    Bitmap.Canvas.FillRect(Bitmap.Canvas.ClipRect);
    Bitmap.Canvas.Brush.Color := RGB(32, 122, 216);
    Bitmap.Canvas.Pen.Color := Bitmap.Canvas.Brush.Color;
    Bitmap.Canvas.RoundRect(1, 1, 23, 23, 6, 6);
    Bitmap.Canvas.Pen.Color := clWhite;
    Bitmap.Canvas.MoveTo(4, 6);
    Bitmap.Canvas.LineTo(20, 6);
    Bitmap.Canvas.Brush.Style := bsClear;
    Bitmap.Canvas.Font.Name := 'Consolas';
    Bitmap.Canvas.Font.Height := -15;
    Bitmap.Canvas.Font.Style := [fsBold];
    Bitmap.Canvas.Font.Color := clWhite;
    Bitmap.Canvas.TextOut(4, 7, '{}');
    // The IDE copies the bitmap, its lower-left pixel is the transparent key.
    SplashScreenServices.AddPluginBitmap('RADWinUI - Delphi + WinUI 3', Bitmap.Handle, False, 'MIT');
  finally
    Bitmap.Free;
  end;
end;

procedure Register;
begin
  // The IDE calls Register once per unit that exports it, guard anyway, since a second
  // RegisterPackageWizard with the same ID raises "Cannot register Wizard ... twice".
  if Registered then
    Exit;
  Registered := True;
  RegisterPackageWizard(TRADWinUIWizard.Create);
  RegisterPackageWizard(TRADWinUIFileWizard.Create(fkWindow));
  RegisterPackageWizard(TRADWinUIFileWizard.Create(fkPage));
  RegisterPackageWizard(TRADWinUIFileWizard.Create(fkUserControl));
  RegisterPackageWizard(TRADWinUIFileWizard.Create(fkResource));
  AddPreviewCommand;
  try
    AddSplashBranding;
  except
    // Cosmetic startup branding must not prevent the designer from loading.
    on E: Exception do OutputDebugString(PChar('RADWinUI splash: ' + E.Message));
  end;
end;

end.
