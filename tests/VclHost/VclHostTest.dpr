program VclHostTest;

(*
  Checks TWinUIHost (RADWinUI.VclHost) in a VCL app: inline XAML without its
  namespaces, the island parented to the host and following its size,
  FindElement, Click="..." and <x:Name><Event> handlers of the form, {Binding}
  to the DataContext, the automatic theme, load errors shown instead of raised,
  the focus going into the content, a recreated handle, repeated reloads, and the
  shutdown after the last message. The form opens where RADWINUI_TEST_MONITOR
  puts test windows (offscreen by default) and never takes the focus. Exit code 0
  when every check passed.
*)

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.PsAPI,
  System.SysUtils,
  System.Types,
  System.Classes,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  RADWinUI.Interop.Core,
  RADWinUI.Abi,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.VclHost,
  RADWinUI.HotReload,
  System.IOUtils;

var
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
  Flush(Output);
end;

function PrivateBytes: NativeUInt;
var
  Counters: TProcessMemoryCountersEx;
begin
  Counters.cb := SizeOf(Counters);
  GetProcessMemoryInfo(GetCurrentProcess, @Counters, SizeOf(Counters));
  Result := Counters.PrivateUsage;
end;

procedure Press(AButton: TWinUIButton);
var
  Peer: IAutomationPeer;
  Pattern: IInspectable;
begin
  Peer := FrameworkElementAutomationPeer.CreatePeerForElement(TWinUIObject.IntfOf(AButton, IUIElement) as IUIElement);
  Pattern := Peer.GetPattern(PatternInterface.Invoke);
  (Pattern as IInvokeProvider).Invoke;
end;

type
  TTestForm = class(TForm)
    Edit: TEdit;
    Host: TWinUIHost;
    Broken: TWinUIHost;
    Timer: TTimer;
  private
    FStep: Integer;
    FLoadedCount: Integer;
    FSaveClicks: Integer;
    FResetClicks: Integer;
    FMemory: NativeUInt;
    FFile: string;
    procedure Tick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
  published
    procedure HostLoaded(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure ResetButtonClick(Sender: TObject);
  end;

constructor TTestForm.Create(AOwner: TComponent);
var
  Area: TRect;
begin
  inherited CreateNew(AOwner);
  Caption := 'TWinUIHost test';
  Area := System.Types.Rect(-32000, -32000, -31000, -31000);
  if SameText(GetEnvironmentVariable('RADWINUI_TEST_MONITOR'), 'secondary') and (Screen.MonitorCount > 1) then
    if Screen.Monitors[0].Primary then
      Area := Screen.Monitors[1].WorkareaRect
    else
      Area := Screen.Monitors[0].WorkareaRect;
  SetBounds(Area.Left + 40, Area.Top + 40, 560, 480);
  Edit := TEdit.Create(Self);
  Edit.Parent := Self;
  Edit.Align := alTop;
  Host := TWinUIHost.Create(Self);
  Host.Name := 'Host';
  Host.Parent := Self;
  Host.Align := alTop;
  Host.Height := 260;
  Host.Color := clWhite;
  Host.OnLoaded := HostLoaded;
  // No namespaces: the host adds them. An unnamed button with Click="...", a named one
  // wired by its method name, a binding to the DataContext
  Host.Xaml.Text :=
    '<StackPanel Padding="12" Spacing="8">' +
    '  <TextBox x:Name="NameBox" PlaceholderText="Name"/>' +
    '  <TextBlock x:Name="Greeting" Text="{Binding}"/>' +
    '  <Button Content="Save" Click="SaveClick"/>' +
    '  <Button x:Name="ResetButton" Content="Reset"/>' +
    '</StackPanel>';
  Broken := TWinUIHost.Create(Self);
  Broken.Parent := Self;
  Broken.Align := alTop;
  Broken.Height := 60;
  Timer := TTimer.Create(Self);
  Timer.Interval := 500;
  Timer.OnTimer := Tick;
end;

procedure TTestForm.HostLoaded(Sender: TObject);
begin
  Inc(FLoadedCount);
end;

procedure TTestForm.SaveClick(Sender: TObject);
begin
  Inc(FSaveClicks);
end;

procedure TTestForm.ResetButtonClick(Sender: TObject);
begin
  Inc(FResetClicks);
end;

procedure TTestForm.Tick(Sender: TObject);
var
  Bridge: HWND;
  R: TRect;
  Box: TWinUITextBox;
  I: Integer;
begin
  Inc(FStep);
  try
    case FStep of
      1:
        begin
          Check(Host.LoadError = '', 'inline XAML without namespaces loads (' + Host.LoadError + ')');
          Check(Host.Content <> nil, 'Content is the root element');
          Check(FLoadedCount = 1, Format('OnLoaded ran once (%d)', [FLoadedCount]));
          Bridge := GetWindow(Host.Handle, GW_CHILD);
          Check(Bridge <> 0, 'the island window is a child of the host');
          GetWindowRect(Bridge, R);
          Check((R.Width = Host.ClientWidth) and (R.Height = Host.ClientHeight),
            Format('the island has the host''s size (%dx%d)', [R.Width, R.Height]));
          Host.Height := Host.Height + 40;
          Box := Host.FindElement<TWinUITextBox>('NameBox');
          Check(Box <> nil, 'FindElement finds an x:Name');
          Box.Text := 'Ada';
          Check(Host.FindElement<TWinUITextBox>('NameBox').Text = 'Ada', 'the element is usable from Delphi');
          Check(Host.FindElement<TWinUITextBox>('Missing') = nil, 'FindElement returns nil for an unknown name');
          Check(Host.FindElement<TWinUIButton>('_rwHost1') <> nil, 'an unnamed element with an event gets a name');
          Host.DataContext := 'Hello from the form';
          Press(Host.FindElement<TWinUIButton>('_rwHost1'));
          Press(Host.FindElement<TWinUIButton>('ResetButton'));
          // Errors are shown in the control, the form still opens
          Broken.Xaml.Text := '<StackPanel><NoSuchControl/></StackPanel>';
        end;
      2:
        begin
          GetWindowRect(GetWindow(Host.Handle, GW_CHILD), R);
          Check(R.Height = Host.ClientHeight, Format('the island follows a resize (%d)', [R.Height]));
          Check(FSaveClicks = 1, Format('Click="SaveClick" calls the form''s method (%d)', [FSaveClicks]));
          Check(FResetClicks = 1, Format('ResetButtonClick is wired by its name (%d)', [FResetClicks]));
          Check(Host.FindElement<TWinUITextBlock>('Greeting').Text = 'Hello from the form',
            '{Binding} shows the DataContext');
          Check(Broken.LoadError <> '', 'a XAML error is kept in LoadError: ' + Broken.LoadError);
          Broken.Xaml.Text := '<StackPanel><Slider Click="SaveClick"/></StackPanel>';
          Check(Pos('wire it in code', Broken.LoadError) > 0, 'an event the host cannot wire says so: ' +
            Broken.LoadError);
          Broken.Xaml.Text := '<Button Click="NoSuchMethod"/>';
          Check(Pos('no published method NoSuchMethod', Broken.LoadError) > 0, 'a missing handler is named: ' +
            Broken.LoadError);
          Check(Host.Content.ActualTheme = TWinUIElementTheme.Light, 'a white host gets the light theme');
          Host.Color := clBlack;
          Check(Host.Content.ActualTheme = TWinUIElementTheme.Dark, 'a black host gets the dark theme');
          Host.Theme := htLight;
          Check(Host.Content.ActualTheme = TWinUIElementTheme.Light, 'Theme htLight wins over the colour');
          Host.Color := clWhite;
          Host.Theme := htDark;
          Check(Host.Content.ActualTheme = TWinUIElementTheme.Dark, 'Theme htDark on a white host gets the dark theme');
          Host.Theme := htAuto;
          Edit.HandleNeeded;
          Winapi.Windows.SetFocus(Edit.Handle);
          Winapi.Windows.SetFocus(Host.Handle);
        end;
      3:
        begin
          Check(IsChild(Host.Handle, GetFocus), 'focusing the host moves the focus into the content');
          Host.Perform(CM_RECREATEWND, 0, 0);
        end;
      4:
        begin
          // XamlFile, and the IDE's edits of it in a Debug build (hot reload)
          FFile := TPath.Combine(TPath.GetTempPath, 'VclHostTest-' + IntToStr(GetCurrentProcessId) + '.xaml');
          TFile.WriteAllText(FFile, '<TextBlock x:Name="FromFile" Text="file"/>', TEncoding.UTF8);
          Broken.XamlFile := FFile;
          Check((Broken.LoadError = '') and (Broken.FindElement<TWinUITextBlock>('FromFile').Text = 'file'),
            'XamlFile loads the file (' + Broken.LoadError + ')');
          TXamlHotReload.Apply(ExtractFileName(FFile), '', '', '<TextBlock x:Name="FromFile" Text="edited"/>', '');
          Check(Broken.FindElement<TWinUITextBlock>('FromFile').Text = 'edited', 'hot reload sends the edited file to the host');
          TFile.Delete(FFile);
          Check((Host.Content <> nil) and (FLoadedCount = 2), Format('a recreated handle loads the content again ' +
            '(OnLoaded %d)', [FLoadedCount]));
          Check(Host.FindElement<TWinUITextBlock>('Greeting').Text = 'Hello from the form',
            'the DataContext is kept across a reload');
          FMemory := PrivateBytes;
          for I := 1 to 20 do
            Host.Reload;
          Check(PrivateBytes - FMemory < 20 * 1024 * 1024, Format('twenty reloads: %d KB more',
            [Integer(PrivateBytes - FMemory) div 1024]));
          Check(FLoadedCount = 22, Format('OnLoaded after each reload (%d)', [FLoadedCount]));
        end;
      5:
        begin
          Timer.Enabled := False;
          Close;
        end;
    end;
  except
    on E: Exception do
    begin
      Check(False, Format('step %d raised %s: %s', [FStep, E.ClassName, E.Message]));
      Timer.Enabled := False;
      Close;
    end;
  end;
end;

var
  Form: TTestForm;
begin
  Writeln('TWinUIHost');
  Vcl.Forms.Application.Initialize;
  Vcl.Forms.Application.ShowMainForm := False;
  Vcl.Forms.Application.CreateForm(TTestForm, Form);
  ShowWindow(Form.Handle, SW_SHOWNOACTIVATE);
  Form.Visible := True;
  Form.Timer.Enabled := True;
  Vcl.Forms.Application.Run;
  Writeln(Format('%d failure(s)', [Failures]));
  ExitCode := Ord(Failures > 0);
end.
