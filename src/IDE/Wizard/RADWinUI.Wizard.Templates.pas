unit RADWinUI.Wizard.Templates;

{
  The files of a new RADWinUI application, as the File > New wizard writes
  them. No ToolsAPI and no WinUI here: the wizard package calls
  WriteProject, and tests/Wizard calls it outside the IDE to build and run the
  result.

    <Name>.dpr            program: TWinUIApp.Run(TMainWindow)
    <Name>.dproj          Win64 only, RADWinUI unit search path, pre-build
                          runs XamlCodeGen, post-build copies the bootstrap DLL
    MainWindow.xaml       the window, edited by the user, DataContextType="TMainViewModel"
    MainWindow.pas        the window class with its handlers, edited by the user
    MainViewModel.pas     the view model the window binds to (typed ViewModel property)
    MainWindow.Xaml.pas   generated from MainWindow.xaml by XamlCodeGen: by the wizard
                          right after writing the files, and before every build
}

interface

uses
  System.SysUtils;

const
  /// <summary>An MSBuild error line for build events that need the downloaded Windows App SDK files.</summary>
  MissingSdkError = 'RADWinUI : error RW1001 : Windows App SDK files are missing. Run scripts\Get-WindowsAppSDK.ps1 once ' +
    '- see docs\GETTING-STARTED.md, step 0.';
  /// <summary>The project group that builds RADWinUI for this IDE.</summary>
  RADWinUIGroup = {$IFDEF CPUX64}'RADWinUI.groupproj'{$ELSE}'RADWinUI32.groupproj'{$ENDIF};

type
  TWizardProject = record
    /// <summary>Program name, a Pascal identifier (also the .dpr and .dproj name).</summary>
    Name: string;
    /// <summary>Folder of the new project, created when missing.</summary>
    Directory: string;
    /// <summary>RADWinUI checkout (src, tools, third_party).</summary>
    Root: string;
    /// <summary>Windows App SDK release folder name under third_party, for example 2.5.1.</summary>
    SdkRelease: string;
  end;

/// <summary>Checks the name and folder, returns '' or the reason they cannot be used.</summary>
function ValidateProject(const AProject: TWizardProject): string;

function ProjectSource(const AProject: TWizardProject): string;
function ProjectFile(const AProject: TWizardProject): string;
function MainWindowXaml: string;
function MainWindowUnit: string;
function MainViewModelUnit: string;
/// <summary>Command line that generates MainWindow.Xaml.pas (also the project's pre-build event).</summary>
function XamlCodeGenCommand(const AProject: TWizardProject): string;

/// <summary>Checks a new window's unit name in ADirectory, returns '' or the reason it cannot be used.</summary>
function ValidateWindow(const ADirectory, AUnitName: string): string;
/// <summary>The XAML of a new window class AClassName.</summary>
function WindowXaml(const AClassName, ATitle: string): string;
/// <summary>The unit AUnitName with the window class AClassName and its Close handler.</summary>
function WindowUnit(const AUnitName, AClassName: string): string;
/// <summary>
///   Writes AUnitName.xaml and AUnitName.pas (class T + AUnitName) in ADirectory,
///   XamlCodeGen generates AUnitName.Xaml.pas from them.
/// </summary>
procedure WriteWindow(const ADirectory, AUnitName: string);
/// <summary>
///   Adds a window to a project's .dpr and .dproj files, for builds outside the
///   IDE (the IDE wizard adds the units through ToolsAPI instead).
/// </summary>
procedure AddWindowToProjectFiles(const ADProjPath, AUnitName: string);

/// <summary>Writes the project files, returns the .dproj path. MainWindow.Xaml.pas comes from XamlCodeGenCommand.</summary>
function WriteProject(const AProject: TWizardProject): string;

/// <summary>The SDK release recorded in Root\build\WindowsAppSDK.json ("release").</summary>
function ReadSdkRelease(const ARoot: string): string;

implementation

uses
  System.IOUtils,
  System.JSON;

const
  CRLF = #13#10;

function Lines(const AText: array of string): string;
var
  S: string;
begin
  Result := '';
  for S in AText do
    Result := Result + S + CRLF;
end;

function XmlEscape(const S: string): string;
begin
  Result := S.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;');
end;

function IsIdentifier(const S: string): Boolean;
var
  I: Integer;
begin
  Result := (S <> '') and CharInSet(S[1], ['A'..'Z', 'a'..'z', '_']);
  for I := 2 to Length(S) do
    Result := Result and CharInSet(S[I], ['A'..'Z', 'a'..'z', '0'..'9', '_']);
end;

function CodeGenExe(const ARoot: string): string;
begin
  Result := TPath.Combine(ARoot, 'bin\XamlCodeGen.exe');
end;

function ValidateProject(const AProject: TWizardProject): string;
begin
  if not IsIdentifier(AProject.Name) then
    Exit('The project name must be a Pascal identifier (letters, digits, underscore).');
  if SameText(AProject.Name, 'MainWindow') or SameText(AProject.Name, 'MainViewModel') then
    Exit(AProject.Name + ' is the name of a unit of the project; choose another project name.');
  if AProject.Directory = '' then
    Exit('Choose a folder for the project.');
  if FileExists(TPath.Combine(AProject.Directory, AProject.Name + '.dproj')) or
    FileExists(TPath.Combine(AProject.Directory, 'MainWindow.pas')) or
    FileExists(TPath.Combine(AProject.Directory, 'MainViewModel.pas')) then
    Exit('The folder already has a project with these files.');
  if not FileExists(CodeGenExe(AProject.Root)) then
    Exit('RADWinUI at ' + AProject.Root + ' is not built: bin\XamlCodeGen.exe is missing. ' +
      'Open ' + RADWinUIGroup + ' there and use Build All, then try again.');
  Result := '';
end;

function SearchPath(const ARoot: string): string;
begin
  Result := TPath.Combine(ARoot, 'src\Interop') + ';' + TPath.Combine(ARoot, 'src\Generated') + ';' +
    TPath.Combine(ARoot, 'src\Runtime') + ';' + TPath.Combine(ARoot, 'src\Framework');
end;

function BootstrapDll(const AProject: TWizardProject): string;
begin
  Result := TPath.Combine(AProject.Root, 'third_party\WindowsAppSDK\' + AProject.SdkRelease +
    '\Microsoft.WindowsAppSDK.Foundation\runtimes\win-x64\native\Microsoft.WindowsAppRuntime.Bootstrap.dll');
end;

function ReadSdkRelease(const ARoot: string): string;
var
  Json: TJSONValue;
begin
  Json := TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(ARoot, 'build\WindowsAppSDK.json')));
  try
    if (Json = nil) or not Json.TryGetValue<string>('release', Result) then
      raise Exception.Create('build\WindowsAppSDK.json has no "release"');
  finally
    Json.Free;
  end;
end;

function ProjectSource(const AProject: TWizardProject): string;
begin
  Result := Lines([
    'program ' + AProject.Name + ';',
    '',
    '{ A RADWinUI application. The window is MainWindow.xaml with its code in MainWindow.pas. }',
    '',
    'uses',
    '  RADWinUI.Runtime.Bootstrap,',
    '  RADWinUI.Forms,',
    '  MainViewModel in ''MainViewModel.pas'',',
    '  MainWindow.Xaml in ''MainWindow.Xaml.pas'',',
    '  MainWindow in ''MainWindow.pas'';',
    '',
    'begin',
    '  {$IFDEF DEBUG}',
    '  ReportMemoryLeaksOnShutdown := True;',
    '  // When the post-build copy did not run, load the bootstrap DLL from RADWinUI',
    '  TWinAppRuntime.FallbackFolder := ''' + ExtractFileDir(BootstrapDll(AProject)) + ''';',
    '  {$ENDIF}',
    '  TWinUIApp.Run(TMainWindow);',
    'end.']);
end;

function MainWindowXaml: string;
begin
  Result := Lines([
    '<Window',
    '    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"',
    '    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"',
    '    xmlns:d="http://schemas.microsoft.com/expression/blend/2008"',
    '    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"',
    '    mc:Ignorable="d"',
    '    x:Class="TMainWindow"',
    '    Title="RADWinUI Application" Width="480" Height="320"',
    '    WindowStartupLocation="CenterScreen"',
    '    DataContextType="TMainViewModel">',
    '    <!-- A Grid: in the RADWinUI designer, controls go where you drop them (Margin) -->',
    '    <Grid RequestedTheme="Default" Background="{ThemeResource ApplicationPageBackgroundThemeBrush}">',
    '        <!-- {Binding} paths and converters are checked when the project builds;',
    '             d:Text is what Tools > RADWinUI Preview shows (the app ignores it) -->',
    '        <TextBlock x:Name="CounterText" FontSize="32"',
    '                   HorizontalAlignment="Left" VerticalAlignment="Top" Margin="32,32,0,0"',
    '                   Text="{Binding Count, Converter={StaticResource Format}, ConverterParameter=''Count: %s''}"',
    '                   d:Text="Count: 42"/>',
    '        <Button x:Name="IncrementButton" Content="Increment"',
    '                HorizontalAlignment="Left" VerticalAlignment="Top" Margin="32,100,0,0"/>',
    '    </Grid>',
    '</Window>']);
end;

function MainWindowUnit: string;
begin
  Result := Lines([
    'unit MainWindow;',
    '',
    'interface',
    '',
    'uses',
    '  RADWinUI.Xaml,',
    '  MainViewModel,',
    '  MainWindow.Xaml;',
    '',
    'type',
    '  TMainWindow = class(TMainWindowBase)   // TMainWindowBase is generated from MainWindow.xaml',
    '  public',
    '    constructor Create; override;',
    '    destructor Destroy; override;',
    '  published',
    '    // Published methods named <x:Name><Event> are wired automatically;',
    '    // Click="MethodName" in the XAML works too.',
    '    procedure IncrementButtonClick(Sender: TObject);',
    '  end;',
    '',
    'implementation',
    '',
    'constructor TMainWindow.Create;',
    'begin',
    '  inherited;',
    '  AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.UseDefaultAppMode;',
    '  ViewModel := TMainViewModel.Create; // typed by DataContextType; also sets DataContext',
    'end;',
    '',
    'destructor TMainWindow.Destroy;',
    'begin',
    '  ViewModel.Free;',
    '  inherited;',
    'end;',
    '',
    'procedure TMainWindow.IncrementButtonClick(Sender: TObject);',
    'begin',
    '  ViewModel.Count := ViewModel.Count + 1; // the bound TextBlock follows',
    'end;',
    '',
    'end.']);
end;

function MainViewModelUnit: string;
begin
  Result := Lines([
    'unit MainViewModel;',
    '',
    '{ What MainWindow.xaml binds to: published properties; Changed updates the bindings. }',
    '',
    'interface',
    '',
    'uses',
    '  RADWinUI.Binding;',
    '',
    'type',
    '  TMainViewModel = class(TWinUIBindableObject)',
    '  private',
    '    FCount: Integer;',
    '    procedure SetCount(AValue: Integer);',
    '  published',
    '    property Count: Integer read FCount write SetCount;',
    '  end;',
    '',
    'implementation',
    '',
    'procedure TMainViewModel.SetCount(AValue: Integer);',
    'begin',
    '  if FCount = AValue then',
    '    Exit;',
    '  FCount := AValue;',
    '  Changed(''Count'');',
    'end;',
    '',
    'end.']);
end;

function XamlCodeGenCommand(const AProject: TWizardProject): string;
begin
  // A folder argument means every .xaml file in it
  Result := '"' + CodeGenExe(AProject.Root) + '" "' + AProject.Directory + '"';
end;

function ProjectFile(const AProject: TWizardProject): string;
var
  Name, PreBuild, PostBuild: string;
begin
  Name := AProject.Name;
  // Paths from $(MSBuildProjectDirectory), which never ends with a backslash, in the IDE
  // and in MSBuild alike, $(PROJECTDIR) does in one and not in the other. The DLL goes to
  // the project's own exe folder, $(DCC_ExeOutput), created when missing.
  PreBuild := XamlCodeGenCommand(AProject).Replace(AProject.Directory, '$(MSBuildProjectDirectory)');
  // One line: the IDE joins event lines with "&&", which would make the copy part of the if.
  // Without the DLL (the SDK files were never downloaded) the build stops with one clear error.
  PostBuild := '(if not exist "$(MSBuildProjectDirectory)\$(DCC_ExeOutput)" ' +
    'mkdir "$(MSBuildProjectDirectory)\$(DCC_ExeOutput)") & ' +
    '(if exist "' + BootstrapDll(AProject) + '" (copy /Y "' + BootstrapDll(AProject) +
    '" "$(MSBuildProjectDirectory)\$(DCC_ExeOutput)" >nul) else (echo ' + MissingSdkError + ' & exit 1))';
  Result := Lines([
    '<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">',
    '    <PropertyGroup>',
    '        <ProjectGuid>' + TGUID.NewGuid.ToString + '</ProjectGuid>',
    '        <ProjectVersion>20.4</ProjectVersion>',
    '        <FrameworkType>None</FrameworkType>',
    '        <Base>True</Base>',
    '        <Config Condition="''$(Config)''==''''">Debug</Config>',
    '        <Platform Condition="''$(Platform)''==''''">Win64</Platform>',
    '        <ProjectName Condition="''$(ProjectName)''==''''">' + Name + '</ProjectName>',
    '        <TargetedPlatforms>2</TargetedPlatforms>',
    '        <AppType>Application</AppType>',
    '        <MainSource>' + Name + '.dpr</MainSource>',
    '    </PropertyGroup>',
    '    <PropertyGroup Condition="''$(Config)''==''Base'' or ''$(Base)''!=''''">',
    '        <Base>true</Base>',
    '    </PropertyGroup>',
    '    <PropertyGroup Condition="(''$(Platform)''==''Win64'' and ''$(Base)''==''true'') or ''$(Base_Win64)''!=''''">',
    '        <Base_Win64>true</Base_Win64>',
    '        <CfgParent>Base</CfgParent>',
    '        <Base>true</Base>',
    '    </PropertyGroup>',
    '    <PropertyGroup Condition="''$(Config)''==''Debug'' or ''$(Cfg_1)''!=''''">',
    '        <Cfg_1>true</Cfg_1>',
    '        <CfgParent>Base</CfgParent>',
    '        <Base>true</Base>',
    '    </PropertyGroup>',
    '    <PropertyGroup Condition="''$(Config)''==''Release'' or ''$(Cfg_2)''!=''''">',
    '        <Cfg_2>true</Cfg_2>',
    '        <CfgParent>Base</CfgParent>',
    '        <Base>true</Base>',
    '    </PropertyGroup>',
    '    <PropertyGroup Condition="''$(Base)''!=''''">',
    '        <SanitizedProjectName>' + Name + '</SanitizedProjectName>',
    '        <DCC_DcuOutput>.\$(Platform)\$(Config)\dcu</DCC_DcuOutput>',
    '        <DCC_ExeOutput>.\$(Platform)\$(Config)</DCC_ExeOutput>',
    '        <DCC_Namespace>System;Winapi;System.Win;$(DCC_Namespace)</DCC_Namespace>',
    '        <DCC_UnitSearchPath>' + XmlEscape(SearchPath(AProject.Root)) + ';$(DCC_UnitSearchPath)</DCC_UnitSearchPath>',
    '        <DCC_UsePackage></DCC_UsePackage>',
    '        <PreBuildEvent><![CDATA[' + PreBuild + ']]></PreBuildEvent>',
    '        <PreBuildEventIgnoreExitCode>False</PreBuildEventIgnoreExitCode>',
    '        <PostBuildEvent><![CDATA[' + PostBuild + ']]></PostBuildEvent>',
    '        <PostBuildEventIgnoreExitCode>False</PostBuildEventIgnoreExitCode>',
    '    </PropertyGroup>',
    '    <PropertyGroup Condition="''$(Base_Win64)''!=''''">',
    '        <AppDPIAwarenessMode>PerMonitorV2</AppDPIAwarenessMode>',
    '        <Manifest_File>$(BDS)\bin\default_app.manifest</Manifest_File>',
    '    </PropertyGroup>',
    '    <PropertyGroup Condition="''$(Cfg_1)''!=''''">',
    '        <DCC_Define>DEBUG;$(DCC_Define)</DCC_Define>',
    '        <DCC_DebugDCUs>true</DCC_DebugDCUs>',
    '        <DCC_Optimize>false</DCC_Optimize>',
    '        <DCC_GenerateStackFrames>true</DCC_GenerateStackFrames>',
    '        <DCC_DebugInfoInExe>true</DCC_DebugInfoInExe>',
    '    </PropertyGroup>',
    '    <PropertyGroup Condition="''$(Cfg_2)''!=''''">',
    '        <DCC_LocalDebugSymbols>false</DCC_LocalDebugSymbols>',
    '        <DCC_Define>RELEASE;$(DCC_Define)</DCC_Define>',
    '        <DCC_SymbolReferenceInfo>0</DCC_SymbolReferenceInfo>',
    '        <DCC_DebugInformation>0</DCC_DebugInformation>',
    '    </PropertyGroup>',
    '    <ItemGroup>',
    '        <DelphiCompile Include="$(MainSource)">',
    '            <MainSource>MainSource</MainSource>',
    '        </DelphiCompile>',
    '        <DCCReference Include="MainViewModel.pas"/>',
    '        <DCCReference Include="MainWindow.Xaml.pas"/>',
    '        <DCCReference Include="MainWindow.pas"/>',
    '        <None Include="MainWindow.xaml"/>',
    '        <BuildConfiguration Include="Base">',
    '            <Key>Base</Key>',
    '        </BuildConfiguration>',
    '        <BuildConfiguration Include="Debug">',
    '            <Key>Cfg_1</Key>',
    '            <CfgParent>Base</CfgParent>',
    '        </BuildConfiguration>',
    '        <BuildConfiguration Include="Release">',
    '            <Key>Cfg_2</Key>',
    '            <CfgParent>Base</CfgParent>',
    '        </BuildConfiguration>',
    '    </ItemGroup>',
    '    <ProjectExtensions>',
    '        <Borland.Personality>Delphi.Personality.12</Borland.Personality>',
    '        <Borland.ProjectType>Application</Borland.ProjectType>',
    '        <BorlandProject>',
    '            <Delphi.Personality>',
    '                <Source>',
    '                    <Source Name="MainSource">' + Name + '.dpr</Source>',
    '                </Source>',
    '            </Delphi.Personality>',
    '            <Platforms>',
    '                <Platform value="Win64">True</Platform>',
    '            </Platforms>',
    '        </BorlandProject>',
    '        <ProjectFileVersion>12</ProjectFileVersion>',
    '    </ProjectExtensions>',
    '    <Import Project="$(BDS)\Bin\CodeGear.Delphi.Targets" Condition="Exists(''$(BDS)\Bin\CodeGear.Delphi.Targets'')"/>',
    '    <Import Project="$(APPDATA)\Embarcadero\$(BDSAPPDATABASEDIR)\$(PRODUCTVERSION)\UserTools.proj" Condition="Exists(''$(APPDATA)\Embarcadero\$(BDSAPPDATABASEDIR)\$(PRODUCTVERSION)\UserTools.proj'')"/>',
    '</Project>']);
end;

function ValidateWindow(const ADirectory, AUnitName: string): string;
begin
  if not IsIdentifier(AUnitName) then
    Exit('The window unit name must be a Pascal identifier (letters, digits, underscore).');
  if FileExists(TPath.Combine(ADirectory, AUnitName + '.pas')) or
    FileExists(TPath.Combine(ADirectory, AUnitName + '.xaml')) then
    Exit('The project folder already has ' + AUnitName + '.pas or ' + AUnitName + '.xaml.');
  Result := '';
end;

function WindowXaml(const AClassName, ATitle: string): string;
begin
  Result := Lines([
    '<Window',
    '    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"',
    '    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"',
    '    x:Class="' + AClassName + '"',
    '    Title="' + XmlEscape(ATitle) + '" Width="400" Height="240"',
    '    WindowStartupLocation="CenterScreen">',
    '    <Grid RequestedTheme="Default" Background="{ThemeResource ApplicationPageBackgroundThemeBrush}">',
    '        <TextBlock x:Name="Message" Text="' + XmlEscape(ATitle) + '" FontSize="24"',
    '                   HorizontalAlignment="Left" VerticalAlignment="Top" Margin="32,32,0,0"/>',
    '        <Button x:Name="CloseButton" Content="Close"',
    '                HorizontalAlignment="Left" VerticalAlignment="Top" Margin="32,88,0,0"/>',
    '    </Grid>',
    '</Window>']);
end;

function WindowUnit(const AUnitName, AClassName: string): string;
begin
  Result := Lines([
    'unit ' + AUnitName + ';',
    '',
    'interface',
    '',
    'uses',
    '  RADWinUI.Xaml,',
    '  ' + AUnitName + '.Xaml;',
    '',
    'type',
    '  ' + AClassName + ' = class(' + AClassName + 'Base)   // generated from ' + AUnitName + '.xaml',
    '  public',
    '    constructor Create; override;',
    '  published',
    '    procedure CloseButtonClick(Sender: TObject);',
    '  end;',
    '',
    'implementation',
    '',
    'constructor ' + AClassName + '.Create;',
    'begin',
    '  inherited;',
    '  AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.UseDefaultAppMode;',
    'end;',
    '',
    'procedure ' + AClassName + '.CloseButtonClick(Sender: TObject);',
    'begin',
    '  Close;',
    'end;',
    '',
    'end.']);
end;

procedure WriteWindow(const ADirectory, AUnitName: string);
var
  Error: string;
  Utf8: TEncoding;
begin
  Error := ValidateWindow(ADirectory, AUnitName);
  if Error <> '' then
    raise EArgumentException.Create(Error);
  Utf8 := TUTF8Encoding.Create(False);
  try
    TFile.WriteAllText(TPath.Combine(ADirectory, AUnitName + '.xaml'), WindowXaml('T' + AUnitName, AUnitName), Utf8);
    TFile.WriteAllText(TPath.Combine(ADirectory, AUnitName + '.pas'), WindowUnit(AUnitName, 'T' + AUnitName), Utf8);
  finally
    Utf8.Free;
  end;
end;

procedure AddWindowToProjectFiles(const ADProjPath, AUnitName: string);
const
  Anchor = '        <BuildConfiguration Include="Base">';
var
  Dpr, DProj, Units: string;
  UsesEnd: Integer;
  Utf8: TEncoding;
begin
  Utf8 := TUTF8Encoding.Create(False);
  try
    // .dpr: append the two units to the uses clause
    Dpr := TFile.ReadAllText(ChangeFileExt(ADProjPath, '.dpr'));
    UsesEnd := Pos(';', Dpr, Pos('uses', Dpr));
    if (Pos('uses', Dpr) = 0) or (UsesEnd = 0) then
      raise Exception.Create('No uses clause in ' + ChangeFileExt(ADProjPath, '.dpr'));
    Units := ',' + CRLF + '  ' + AUnitName + '.Xaml in ''' + AUnitName + '.Xaml.pas'',' + CRLF +
      '  ' + AUnitName + ' in ''' + AUnitName + '.pas''';
    Insert(Units, Dpr, UsesEnd);
    TFile.WriteAllText(ChangeFileExt(ADProjPath, '.dpr'), Dpr, Utf8);
    // .dproj: the units and the XAML file
    DProj := TFile.ReadAllText(ADProjPath);
    if Pos(Anchor, DProj) = 0 then
      raise Exception.Create('Unexpected .dproj layout: ' + ADProjPath);
    DProj := DProj.Replace(Anchor,
      '        <DCCReference Include="' + AUnitName + '.Xaml.pas"/>' + CRLF +
      '        <DCCReference Include="' + AUnitName + '.pas"/>' + CRLF +
      '        <None Include="' + AUnitName + '.xaml"/>' + CRLF + Anchor);
    TFile.WriteAllText(ADProjPath, DProj, Utf8);
  finally
    Utf8.Free;
  end;
end;

function WriteProject(const AProject: TWizardProject): string;
var
  Error: string;
  Utf8: TEncoding;
  Config: string;
begin
  Error := ValidateProject(AProject);
  if Error <> '' then
    raise EArgumentException.Create(Error);
  ForceDirectories(AProject.Directory);
  Utf8 := TUTF8Encoding.Create(False); // no BOM, like the files the samples use
  try
    TFile.WriteAllText(TPath.Combine(AProject.Directory, AProject.Name + '.dpr'), ProjectSource(AProject), Utf8);
    TFile.WriteAllText(TPath.Combine(AProject.Directory, 'MainWindow.xaml'), MainWindowXaml, Utf8);
    TFile.WriteAllText(TPath.Combine(AProject.Directory, 'MainWindow.pas'), MainWindowUnit, Utf8);
    TFile.WriteAllText(TPath.Combine(AProject.Directory, 'MainViewModel.pas'), MainViewModelUnit, Utf8);
    Result := TPath.Combine(AProject.Directory, AProject.Name + '.dproj');
    TFile.WriteAllText(Result, ProjectFile(AProject), Utf8);
    // The exe folders get the bootstrap DLL now, so a first Run works even when the IDE
    // does not run the post-build event (an up-to-date target).
    for Config in ['Debug', 'Release'] do
      if FileExists(BootstrapDll(AProject)) then
      begin
        ForceDirectories(TPath.Combine(AProject.Directory, 'Win64\' + Config));
        TFile.Copy(BootstrapDll(AProject), TPath.Combine(AProject.Directory,
          'Win64\' + Config + '\Microsoft.WindowsAppRuntime.Bootstrap.dll'), True);
      end;
  finally
    Utf8.Free;
  end;
end;

end.
