program AppServicesDemo;

{
  A window to try RADWinUI.Dialogs, RADWinUI.Notifications and the activation
  API of TWinUIApp by hand. Every result and every activation is written to the
  log at the bottom. The app is single instance: opening the test file or the
  rwdemo:// link while it runs brings this window to the front and logs the
  redirected activation.
}

uses
  Winapi.Windows,
  Winapi.ShellAPI,
  System.SysUtils,
  System.UITypes,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Forms,
  RADWinUI.Dialogs,
  RADWinUI.Notifications;

const
  DemoExtension = '.rwdemo';
  DemoScheme = 'rwdemo';

  // One card per service: an icon, a title, a line of explanation and its buttons
  CardStart =
    '<Border CornerRadius="8" Padding="20,16" BorderThickness="1" ' +
    'Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" ' +
    'BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"><StackPanel Spacing="10">';
  CardEnd = '</StackPanel></Border>';
  HeaderStart = '<StackPanel Orientation="Horizontal" Spacing="10"><FontIcon FontSize="18" ' +
    'Foreground="{ThemeResource AccentTextFillColorPrimaryBrush}" Glyph="';
  HeaderEnd = '</StackPanel>';
  NoteStyle = ' TextWrapping="Wrap" Opacity="0.7"';

  Layout =
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' +
    '<Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="200"/></Grid.RowDefinitions>' +
    '<ScrollViewer><StackPanel Spacing="12" Margin="24,20,24,20">' +
    '<StackPanel Spacing="2"><TextBlock Text="App services" Style="{StaticResource TitleTextBlockStyle}"/>' +
    '<TextBlock Text="Every button calls one RADWinUI service. Results and activations go to the log below."' +
    NoteStyle + '/></StackPanel>' +

    CardStart + HeaderStart + '&#xE8BD;"/><TextBlock Text="Dialogs" Style="{StaticResource SubtitleTextBlockStyle}"/>' +
    HeaderEnd +
    '<TextBlock Text="RADWinUI.Dialogs on WinUI ContentDialog. The result arrives in a callback."' + NoteStyle + '/>' +
    '<StackPanel Orientation="Horizontal" Spacing="8">' +
    '<Button x:Name="ShowMessageButton" Content="ShowMessage"/>' +
    '<Button x:Name="YesNoCancelButton" Content="MessageDlg Yes/No/Cancel"/>' +
    '<Button x:Name="ErrorButton" Content="MessageDlg error, OK"/>' +
    '<Button x:Name="InputButton" Content="InputQuery"/>' +
    '<Button x:Name="TwoDialogsButton" Content="Two dialogs at once"/>' +
    '</StackPanel>' + CardEnd +

    CardStart + HeaderStart + '&#xE8E5;"/><TextBlock Text="Pickers" Style="{StaticResource SubtitleTextBlockStyle}"/>' +
    HeaderEnd +
    '<TextBlock Text="The Windows file and folder pickers, with VCL-style filters."' + NoteStyle + '/>' +
    '<StackPanel Orientation="Horizontal" Spacing="8">' +
    '<Button x:Name="OpenButton" Content="Open file"/>' +
    '<Button x:Name="OpenManyButton" Content="Open several files"/>' +
    '<Button x:Name="SaveButton" Content="Save file"/>' +
    '<Button x:Name="FolderButton" Content="Pick folder"/>' +
    '</StackPanel>' + CardEnd +

    CardStart + HeaderStart + '&#xEA8F;"/><TextBlock x:Name="NotificationsHeader" ' +
    'Style="{StaticResource SubtitleTextBlockStyle}"/>' + HeaderEnd +
    '<TextBlock Text="Windows notifications. A click, a button or a typed reply comes back through OnActivated."' +
    NoteStyle + '/>' +
    '<StackPanel Orientation="Horizontal" Spacing="8">' +
    '<Button x:Name="SimpleNotificationButton" Content="Simple notification"/>' +
    '<Button x:Name="RichNotificationButton" Content="Notification with buttons and a text box"/>' +
    '<Button x:Name="RemoveNotificationsButton" Content="Remove all notifications"/>' +
    '</StackPanel>' + CardEnd +

    CardStart + HeaderStart + '&#xE7AC;"/><TextBlock Text="Activation" Style="{StaticResource SubtitleTextBlockStyle}"/>' +
    HeaderEnd +
    '<TextBlock Text="A single-instance app that Windows starts for its own files and links."' + NoteStyle + '/>' +
    '<TextBlock x:Name="LaunchText" TextWrapping="Wrap" IsTextSelectionEnabled="True"/>' +
    '<StackPanel Orientation="Horizontal" Spacing="8">' +
    '<Button x:Name="RegisterFileButton" Content="Register .rwdemo"/>' +
    '<Button x:Name="UnregisterFileButton" Content="Unregister .rwdemo"/>' +
    '<Button x:Name="RegisterProtocolButton" Content="Register rwdemo:"/>' +
    '<Button x:Name="UnregisterProtocolButton" Content="Unregister rwdemo:"/>' +
    '</StackPanel>' +
    '<StackPanel Orientation="Horizontal" Spacing="8">' +
    '<Button x:Name="CreateFileButton" Content="Create test file"/>' +
    '<Button x:Name="OpenFileButton" Content="Open test file via shell"/>' +
    '<Button x:Name="OpenLinkButton" Content="Open rwdemo://hello/42 via shell"/>' +
    '</StackPanel>' + CardEnd +

    '</StackPanel></ScrollViewer>' +
    '<Border Grid.Row="1" BorderThickness="0,1,0,0" BorderBrush="{ThemeResource DividerStrokeColorDefaultBrush}" ' +
    'Background="{ThemeResource LayerFillColorDefaultBrush}">' +
    '<ScrollViewer Padding="24,8,24,8"><TextBlock x:Name="LogText" FontFamily="Consolas" FontSize="12" ' +
    'TextWrapping="Wrap" IsTextSelectionEnabled="True"/></ScrollViewer>' +
    '</Border>' +
    '</Grid>';

type
  TDemoWindow = class(TWinUIWindow)
  private
    FLog: TWinUITextBlock;
    FOpenDialog: TWinUIOpenDialog;
    FSaveDialog: TWinUISaveDialog;
    FFolderDialog: TWinUIFolderDialog;
    procedure Log(const ALine: string);
    procedure Wire(const AName: string; AHandler: TWinUIRoutedEventHandler);
    procedure ShowMessageClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure YesNoCancelClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure ErrorClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure InputClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure TwoDialogsClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure OpenClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure OpenManyClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure SaveClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure FolderClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure SimpleNotificationClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure RichNotificationClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure RemoveNotificationsClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure RegisterFileClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure UnregisterFileClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure RegisterProtocolClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure UnregisterProtocolClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure CreateFileClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure OpenFileClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure OpenLinkClick(Sender: TObject; E: TWinUIRoutedEventArgs);
  public
    constructor Create; override;
    destructor Destroy; override;
    class procedure Activated(Sender: TObject; const AActivation: TWinUIActivation);
  end;

var
  Demo: TDemoWindow;

function TestFilePath: string;
begin
  Result := GetEnvironmentVariable('TEMP') + '\RADWinUI\hello' + DemoExtension;
end;

function ResultName(AResult: TModalResult): string;
begin
  case AResult of
    mrOk: Result := 'mrOk';
    mrCancel: Result := 'mrCancel';
    mrYes: Result := 'mrYes';
    mrNo: Result := 'mrNo';
    mrNone: Result := 'mrNone';
  else
    Result := IntToStr(AResult);
  end;
end;

function Describe(const AActivation: TWinUIActivation): string;
const
  KindNames: array[TWinUIActivationKind] of string = ('Launch', 'File', 'Protocol', 'Notification', 'Other');
begin
  Result := Format('%s, arguments "%s"', [KindNames[AActivation.Kind], AActivation.Arguments]);
  if Length(AActivation.Files) > 0 then
    Result := Result + ', files: ' + string.Join('; ', AActivation.Files);
  if Length(AActivation.Inputs) > 0 then
    Result := Result + ', inputs: ' + string.Join('; ', AActivation.Inputs);
end;

{ TDemoWindow }

constructor TDemoWindow.Create;
begin
  inherited;
  Demo := Self;
  Title := 'RADWinUI app services demo';
  Width := 980;
  Height := 760;
  Backdrop := TWinUIBackdrop.Mica;
  // An automated run must not take the focus from whoever uses the machine
  ShowActivated := GetEnvironmentVariable('RADWINUI_TEST_MONITOR') = '';
  LoadContent(Layout);
  FLog := FindElement<TWinUITextBlock>('LogText');
  FindElement<TWinUITextBlock>('NotificationsHeader').Text :=
    'Notifications (supported: ' + BoolToStr(TWinUINotification.Supported, True) + ')';
  FindElement<TWinUITextBlock>('LaunchText').Text := 'Started as: ' + Describe(TWinUIApp.LaunchActivation);
  Wire('ShowMessageButton', ShowMessageClick);
  Wire('YesNoCancelButton', YesNoCancelClick);
  Wire('ErrorButton', ErrorClick);
  Wire('InputButton', InputClick);
  Wire('TwoDialogsButton', TwoDialogsClick);
  Wire('OpenButton', OpenClick);
  Wire('OpenManyButton', OpenManyClick);
  Wire('SaveButton', SaveClick);
  Wire('FolderButton', FolderClick);
  Wire('SimpleNotificationButton', SimpleNotificationClick);
  Wire('RichNotificationButton', RichNotificationClick);
  Wire('RemoveNotificationsButton', RemoveNotificationsClick);
  Wire('RegisterFileButton', RegisterFileClick);
  Wire('UnregisterFileButton', UnregisterFileClick);
  Wire('RegisterProtocolButton', RegisterProtocolClick);
  Wire('UnregisterProtocolButton', UnregisterProtocolClick);
  Wire('CreateFileButton', CreateFileClick);
  Wire('OpenFileButton', OpenFileClick);
  Wire('OpenLinkButton', OpenLinkClick);
  FOpenDialog := TWinUIOpenDialog.Create;
  FOpenDialog.Filter := 'Text files (*.txt)|*.txt|Pascal units (*.pas)|*.pas|All files (*.*)|*.*';
  FSaveDialog := TWinUISaveDialog.Create;
  FSaveDialog.Filter := 'Text files (*.txt)|*.txt|All files (*.*)|*.*';
  FSaveDialog.DefaultExt := 'txt';
  FFolderDialog := TWinUIFolderDialog.Create;
end;

destructor TDemoWindow.Destroy;
begin
  Demo := nil;
  FOpenDialog.Free;
  FSaveDialog.Free;
  FFolderDialog.Free;
  inherited;
end;

procedure TDemoWindow.Wire(const AName: string; AHandler: TWinUIRoutedEventHandler);
begin
  FindElement<TWinUIButton>(AName).OnClick := AHandler;
end;

// Newest line first, so it is visible without scrolling
procedure TDemoWindow.Log(const ALine: string);
begin
  FLog.Text := FormatDateTime('hh:nn:ss.zzz', Now) + '  ' + ALine + sLineBreak + FLog.Text;
end;

class procedure TDemoWindow.Activated(Sender: TObject; const AActivation: TWinUIActivation);
begin
  if Demo <> nil then
    Demo.Log('OnActivated: ' + Describe(AActivation));
end;

procedure TDemoWindow.ShowMessageClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  ShowMessage('Hello from ShowMessage.',
    procedure
    begin
      Log('ShowMessage closed');
    end);
end;

procedure TDemoWindow.YesNoCancelClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  MessageDlg('Save the changes before closing?', TMsgDlgType.mtConfirmation,
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo, TMsgDlgBtn.mbCancel],
    procedure(AResult: TModalResult)
    begin
      Log('MessageDlg Yes/No/Cancel: ' + ResultName(AResult));
    end);
end;

procedure TDemoWindow.ErrorClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  MessageDlg('The file could not be read.', TMsgDlgType.mtError, [TMsgDlgBtn.mbOK],
    procedure(AResult: TModalResult)
    begin
      Log('MessageDlg error: ' + ResultName(AResult));
    end);
end;

procedure TDemoWindow.InputClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  InputQuery('Rename', 'New name:', 'notes.txt',
    procedure(AOk: Boolean; const AValue: string)
    begin
      if AOk then
        Log('InputQuery OK: "' + AValue + '"')
      else
        Log('InputQuery cancelled, value "' + AValue + '"');
    end);
end;

procedure TDemoWindow.TwoDialogsClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  MessageDlg('First dialog. The second one opens when this one closes.', TMsgDlgType.mtInformation,
    [TMsgDlgBtn.mbOK],
    procedure(AResult: TModalResult)
    begin
      Log('First dialog: ' + ResultName(AResult));
    end);
  MessageDlg('Second dialog.', TMsgDlgType.mtWarning, [TMsgDlgBtn.mbOK, TMsgDlgBtn.mbCancel],
    procedure(AResult: TModalResult)
    begin
      Log('Second dialog: ' + ResultName(AResult));
    end);
end;

procedure TDemoWindow.OpenClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  FOpenDialog.MultiSelect := False;
  FOpenDialog.Title := 'Open a file';
  FOpenDialog.Execute(
    procedure(AOk: Boolean)
    begin
      if AOk then
        Log('Open file: ' + FOpenDialog.FileName)
      else
        Log('Open file cancelled');
    end);
end;

procedure TDemoWindow.OpenManyClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  FOpenDialog.MultiSelect := True;
  FOpenDialog.Title := 'Open several files';
  FOpenDialog.Execute(
    procedure(AOk: Boolean)
    begin
      if AOk then
        Log(Format('Open several files: %d picked: %s', [Length(FOpenDialog.Files),
          string.Join('; ', FOpenDialog.Files)]))
      else
        Log('Open several files cancelled');
    end);
end;

procedure TDemoWindow.SaveClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  FSaveDialog.FileName := 'notes.txt';
  FSaveDialog.Execute(
    procedure(AOk: Boolean)
    begin
      if AOk then
        Log('Save file: ' + FSaveDialog.FileName)
      else
        Log('Save file cancelled');
    end);
end;

procedure TDemoWindow.FolderClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  FFolderDialog.Execute(
    procedure(AOk: Boolean)
    begin
      if AOk then
        Log('Pick folder: ' + FFolderDialog.Folder)
      else
        Log('Pick folder cancelled');
    end);
end;

procedure TDemoWindow.SimpleNotificationClick(Sender: TObject; E: TWinUIRoutedEventArgs);
var
  N: TWinUINotification;
begin
  N := TWinUINotification.Create;
  try
    N.Title := 'RADWinUI demo';
    N.Text := 'A simple notification. Click it to see OnActivated.';
    N.Argument := 'simple';
    N.Show;
  finally
    N.Free;
  end;
  Log('Simple notification shown');
end;

procedure TDemoWindow.RichNotificationClick(Sender: TObject; E: TWinUIRoutedEventArgs);
var
  N: TWinUINotification;
begin
  N := TWinUINotification.Create;
  try
    N.Title := 'New message';
    N.Text := 'Type a reply, then click Like or Open.';
    N.Argument := 'message';
    N.AddTextBox('reply', 'Reply');
    N.AddButton('Like', 'like');
    N.AddButton('Open', 'open');
    N.Show;
  finally
    N.Free;
  end;
  Log('Notification with buttons shown');
end;

procedure TDemoWindow.RemoveNotificationsClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  TWinUINotification.RemoveAll;
  Log('Removed all notifications');
end;

procedure TDemoWindow.RegisterFileClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  TWinUIApp.RegisterFileTypes([DemoExtension], 'RADWinUI demo file');
  Log('Registered ' + DemoExtension);
end;

procedure TDemoWindow.UnregisterFileClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  TWinUIApp.UnregisterFileTypes([DemoExtension]);
  Log('Unregistered ' + DemoExtension);
end;

procedure TDemoWindow.RegisterProtocolClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  TWinUIApp.RegisterProtocol(DemoScheme, 'RADWinUI demo link');
  Log('Registered ' + DemoScheme + ':');
end;

procedure TDemoWindow.UnregisterProtocolClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  TWinUIApp.UnregisterProtocol(DemoScheme);
  Log('Unregistered ' + DemoScheme + ':');
end;

procedure TDemoWindow.CreateFileClick(Sender: TObject; E: TWinUIRoutedEventArgs);
var
  F: TextFile;
begin
  ForceDirectories(ExtractFileDir(TestFilePath));
  AssignFile(F, TestFilePath);
  Rewrite(F);
  Writeln(F, 'Hello from the RADWinUI app services demo.');
  CloseFile(F);
  Log('Created ' + TestFilePath);
end;

procedure TDemoWindow.OpenFileClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  if not FileExists(TestFilePath) then
    Log('Create the test file first')
  else
  begin
    ShellExecute(0, 'open', PChar(TestFilePath), nil, nil, SW_SHOWNORMAL);
    Log('Asked the shell to open ' + TestFilePath);
  end;
end;

procedure TDemoWindow.OpenLinkClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  ShellExecute(0, 'open', 'rwdemo://hello/42', nil, nil, SW_SHOWNORMAL);
  Log('Asked the shell to open rwdemo://hello/42');
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  TWinUIApp.SingleInstance := True;
  TWinUIApp.OnActivated := TDemoWindow.Activated;
  TWinUIApp.Run(TDemoWindow);
end.
