unit MainWindow;

(*
  The window of HotReloadTest and its steps. Each edit of MainWindow.xaml goes
  through XamlCodeGen like the IDE sends it (content and shape), then through
  the window's own hot reload pipe or straight to TXamlHotReload.Apply.
*)

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.JSON,
  RADWinUI.Interop.Core,
  RADWinUI.Abi,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Forms,
  RADWinUI.HotReload,
  RADWinUI.Preview.HotReload,
  MainWindow.Xaml;

type
  TMainWindow = class(TMainWindowBase)
  private
    FTimer: TWinUITimer;
    FStep: Integer;
    FClicks: Integer;
    FXaml, FPas: string;
    FShape: string; // of the first edit, which keeps the compiled fields and events
    procedure Tick(Sender: TObject);
    procedure Press(AButton: TWinUIButton);
    function Generate(const AXaml: string; out AContent, AShape, AError: string): Boolean;
    procedure SendToPipe(const AFile, AShape, AContent, ARaw, AError: string);
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    procedure CountButtonClick(Sender: TObject);
  end;

var
  Failures: Integer;

procedure Check(AOk: Boolean; const AWhat: string);

implementation

procedure Check(AOk: Boolean; const AWhat: string);
begin
  if AOk then
    Writeln('  [ok] ', AWhat)
  else
  begin
    Writeln('  [failed] ', AWhat);
    Inc(Failures);
  end;
  Flush(Output);
end;

var
  DelphiExceptions: Integer;

// Counts Delphi exceptions as they are raised, caught or not: what makes the debugger stop
function CountException(AInfo: PExceptionPointers): Integer; stdcall;
begin
  if AInfo.ExceptionRecord.ExceptionCode = $0EEDFADE then
    Inc(DelphiExceptions);
  Result := 0; // EXCEPTION_CONTINUE_SEARCH
end;

function AddVectoredExceptionHandler(AFirst: Cardinal; AHandler: Pointer): Pointer; stdcall;
  external kernel32;
function RemoveVectoredExceptionHandler(AHandle: Pointer): Cardinal; stdcall; external kernel32;

function SourceFolder: string;
begin
  // tests\HotReload\Win64\Debug\HotReloadTest.exe
  Result := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..'));
end;

constructor TMainWindow.Create;
begin
  inherited;
  ShowActivated := False;
  DataContext := 'kept data';
  FXaml := TFile.ReadAllText(TPath.Combine(SourceFolder, 'MainWindow.xaml'), TEncoding.UTF8);
  FPas := TFile.ReadAllText(TPath.Combine(SourceFolder, 'MainWindow.pas'), TEncoding.UTF8);
  FTimer := TWinUITimer.Create;
  FTimer.Interval := 700;
  FTimer.OnTimer := Tick;
  FTimer.Enabled := True;
end;

destructor TMainWindow.Destroy;
begin
  FTimer.Free;
  inherited;
end;

procedure TMainWindow.CountButtonClick(Sender: TObject);
begin
  Inc(FClicks);
end;

procedure TMainWindow.Press(AButton: TWinUIButton);
begin
  (FrameworkElementAutomationPeer.CreatePeerForElement(TWinUIObject.IntfOf(AButton, IUIElement) as IUIElement)
    .GetPattern(PatternInterface.Invoke) as IInvokeProvider).Invoke;
end;

// What the IDE does with the edited text: XamlCodeGen --ide-request with "hotreload"
function TMainWindow.Generate(const AXaml: string; out AContent, AShape, AError: string): Boolean;
var
  Request, CommandLine: string;
  Json, Answer: TJSONObject;
  Startup: TStartupInfo;
  Process: TProcessInformation;
begin
  Request := TPath.Combine(TPath.GetTempPath, 'RADWinUI-HotReloadTest.json');
  Json := TJSONObject.Create;
  try
    Json.AddPair('path', TPath.Combine(SourceFolder, 'MainWindow.xaml'));
    Json.AddPair('xaml', AXaml);
    Json.AddPair('pas', FPas);
    Json.AddPair('hotreload', TJSONTrue.Create);
    TFile.WriteAllText(Request, Json.ToJSON, TEncoding.UTF8);
  finally
    Json.Free;
  end;
  CommandLine := '"' + TPath.Combine(SourceFolder, '..\..\bin\XamlCodeGen.exe') + '" --ide-request "' + Request + '"';
  UniqueString(CommandLine);
  Startup := Default(TStartupInfo);
  Startup.cb := SizeOf(Startup);
  if not CreateProcess(nil, PChar(CommandLine), nil, nil, False, CREATE_NO_WINDOW, nil, nil, Startup, Process) then
    raise Exception.Create('Cannot start XamlCodeGen.exe');
  WaitForSingleObject(Process.hProcess, 10000);
  CloseHandle(Process.hThread);
  CloseHandle(Process.hProcess);
  Answer := TJSONObject.ParseJSONValue(TFile.ReadAllText(Request, TEncoding.UTF8)) as TJSONObject;
  try
    AContent := Answer.GetValue<string>('content', '');
    AShape := Answer.GetValue<string>('shape', '');
    AError := Answer.GetValue<string>('error', '');
    Result := AError = '';
  finally
    Answer.Free;
  end;
  TFile.Delete(Request);
end;

// What the IDE does: find the app among the listening ones, check the file is of its project, send
procedure TMainWindow.SendToPipe(const AFile, AShape, AContent, ARaw, AError: string);
var
  App, Me: THotReloadApp;
  Xaml: string;
begin
  Me := Default(THotReloadApp);
  for App in HotReloadApps do
    if App.ProcessId = GetCurrentProcessId then
      Me := App;
  Check(SameText(Me.ExePath, ParamStr(0)), 'the IDE finds the app on ' + TXamlHotReload.PipeName);
  Xaml := TPath.Combine(SourceFolder, AFile);
  Check(AppUsesFile(Me.ExePath, Xaml) and not AppUsesFile(Me.ExePath, 'C:\Elsewhere\MainWindow.xaml'),
    'only a .xaml of the app''s project folder goes to it');
  Check(SendHotReload(Me.ProcessId, HotReloadMessage(Xaml, AShape, AContent, ARaw, AError)), 'the message is sent');
end;

procedure TMainWindow.Tick(Sender: TObject);
var
  Content, Shape, Error, Edited: string;
  OldCaption: TWinUITextBlock;
  Handler: Pointer;
begin
  Inc(FStep);
  try
    case FStep of
      1:
        begin
          Check(Caption.Text = 'Before', 'the compiled XAML is shown');
          Check(Bound.Text = 'kept data', '{Binding} shows the DataContext');
          // An edit that keeps the fields and the events: a new text and a new element
          Edited := FXaml.Replace('Text="Before"', 'Text="After"').Replace('<Button x:Name="CountButton"',
            '<TextBlock x:Name="Extra" Text="added"/>' + sLineBreak + '        <Button x:Name="CountButton"');
          Check(Generate(Edited, Content, Shape, Error), 'XamlCodeGen returns content and shape (' + Error + ')');
          Check(Shape.Contains('F:Caption:TWinUITextBlock') and Shape.Contains('E:CountButton.Click=CountButtonClick'),
            'the shape lists the fields and the events: ' + Shape);
          FShape := Shape;
          SendToPipe('MainWindow.xaml', Shape, Content, Edited, '');
        end;
      2:
        begin
          Check(TXamlHotReload.LastStatus = 'Reloaded MainWindow.xaml', 'the pipe message reloads the window (' +
            TXamlHotReload.LastStatus + ')');
          Check(TXamlHotReload.StatusShown = 'Hot reload: Reloaded MainWindow.xaml', 'the bar shows the reload: ' +
            TXamlHotReload.StatusShown);
          Check(Caption.Text = 'After', 'the field points to the new element');
          Check(FindElement<TWinUITextBlock>('Extra') <> nil, 'a new element is there');
          Check(Bound.Text = 'kept data', 'the DataContext is kept');
          Press(CountButton);
          Check(FClicks = 1, 'the events are wired again');
          // A XAML error: the window keeps what it shows
          OldCaption := Caption;
          DelphiExceptions := 0;
          Handler := AddVectoredExceptionHandler(1, @CountException);
          TXamlHotReload.Apply('MainWindow.xaml', FShape, '<StackPanel xmlns="http://schemas.microsoft.com/winfx/' +
            '2006/xaml/presentation"><NoSuchControl/></StackPanel>', '', '');
          RemoveVectoredExceptionHandler(Handler);
          Check(TXamlHotReload.LastStatus.Contains('NoSuchControl'), 'a XAML error is shown: ' +
            TXamlHotReload.LastStatus);
          Check(DelphiExceptions = 0, Format('a XAML error raises no exception the debugger would stop on (%d)',
            [DelphiExceptions]));
          Check((Caption = OldCaption) and (Caption.Text = 'After'), 'the last good content stays');
          Check(TXamlHotReload.StatusShown.Contains('NoSuchControl'), 'the bar shows the error');
          // XamlCodeGen's own error, such as an unknown handler
          TXamlHotReload.Apply('MainWindow.xaml', '', '', '', 'MainWindow.xaml(9): Click="Nope" has no published method');
          Check(TXamlHotReload.LastStatus.Contains('no published method'), 'a XamlCodeGen error is shown');
          TXamlHotReload.Apply('MainWindow.xaml', '', '', '', 'D:\Some\Folder\MainWindow.xaml(3): not well-formed');
          Check(TXamlHotReload.StatusShown = 'Hot reload: MainWindow.xaml(3): not well-formed',
            'the bar names the file without its folder: ' + TXamlHotReload.StatusShown);
          // A field the code uses is gone: rebuild needed
          Edited := FXaml.Replace('<TextBlock x:Name="Caption" Text="Before"/>', '');
          Generate(Edited, Content, Shape, Error);
          TXamlHotReload.Apply('MainWindow.xaml', Shape, Content, Edited, '');
          Check(TXamlHotReload.LastStatus.StartsWith('Rebuild needed: x:Name Caption'), 'a removed x:Name needs a rebuild: ' +
            TXamlHotReload.LastStatus);
          Check(Caption.Text = 'After', 'and the window keeps its content');
          // Another handler: rebuild needed
          Edited := FXaml.Replace('<Button x:Name="CountButton"', '<Button Click="CountButtonClick" Content="Second"/>' +
            sLineBreak + '        <Button x:Name="CountButton"');
          Generate(Edited, Content, Shape, Error);
          TXamlHotReload.Apply('MainWindow.xaml', Shape, Content, Edited, '');
          Check(TXamlHotReload.LastStatus = 'Rebuild needed: the events changed (handlers and the elements they are on)',
            'new event wiring needs a rebuild');
          TXamlHotReload.Apply('Other.xaml', Shape, Content, Edited, '');
          Check(Caption.Text = 'After', 'another file changes nothing here');
          Check(TXamlHotReload.Mismatch('F:A:TWinUIButton;E:A.Click=X', 'F:A:TWinUIButton;F:B:TWinUITextBlock;E:A.Click=X') = '',
            'a new x:Name alone reloads');
          Check(TXamlHotReload.Mismatch('F:A:TWinUIButton', 'F:A:TWinUITextBox').Contains('another type'),
            'a field of another type needs a rebuild');
        end;
      3:
        begin
          FTimer.Enabled := False;
          Close;
        end;
    end;
  except
    on E: Exception do
    begin
      Check(False, Format('step %d raised %s: %s', [FStep, E.ClassName, E.Message]));
      FTimer.Enabled := False;
      Close;
    end;
  end;
end;

end.
