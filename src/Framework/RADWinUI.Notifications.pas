unit RADWinUI.Notifications;

{
  Windows notifications (toasts) with text, an image, buttons and text boxes.

    Note := TWinUINotification.Create;
    try
      Note.Title := 'Backup finished';
      Note.Text := '12 files were copied.';
      Note.Argument := 'open-backup';
      Note.AddButton('Open folder', 'open-folder');
      Note.Show;
    finally
      Note.Free;
    end;

  A click on the notification or one of its buttons reaches
  TWinUIApp.OnActivated with Kind Notification and the Argument. When the app
  is not running, Windows starts it and the click is its LaunchActivation.
  Works for apps with and without MSIX packaging.
}

interface

uses
  System.SysUtils,
  RADWinUI.Interop.Core,
  RADWinUI.Abi,
  RADWinUI.Runtime.Application,
  RADWinUI.Forms;

type
  TWinUINotification = class
  strict private
    FTitle: string;
    FText: string;
    FArgument: string;
    FImage: string;
    FHeroImage: string;
    FTag: string;
    FGroup: string;
    FButtons: TArray<string>;
    FButtonArguments: TArray<string>;
    FInputs: TArray<string>;
    FInputPlaceholders: TArray<string>;
    FSilent: Boolean;
  public
    /// <summary>Adds a button. A click reports AArgument in TWinUIApp.OnActivated. At most five.</summary>
    procedure AddButton(const ACaption, AArgument: string);
    /// <summary>
    ///   Adds a text box. Its value is in TWinUIActivation.Input(AId) when a button
    ///   is clicked. At most five.
    /// </summary>
    procedure AddTextBox(const AId, APlaceholder: string);
    /// <summary>Shows the notification. Raises when Windows has notifications off for the app.</summary>
    procedure Show;
    /// <summary>False when this PC cannot show the app's notifications, such as in a service.</summary>
    class function Supported: Boolean; static;
    /// <summary>Removes every notification of the app from the notification center.</summary>
    class procedure RemoveAll; static;
    /// <summary>Removes the notifications shown with this Tag.</summary>
    class procedure RemoveByTag(const ATag: string); static;
    /// <summary>The first line, in bold.</summary>
    property Title: string read FTitle write FTitle;
    /// <summary>The text below the title, up to two more lines separated by #10.</summary>
    property Text: string read FText write FText;
    /// <summary>Reported in TWinUIApp.OnActivated when the notification itself is clicked.</summary>
    property Argument: string read FArgument write FArgument;
    /// <summary>A small square picture beside the text, a full path or an https URL.</summary>
    property Image: string read FImage write FImage;
    /// <summary>A wide picture above the text, a full path or an https URL.</summary>
    property HeroImage: string read FHeroImage write FHeroImage;
    /// <summary>Identifies the notification for RemoveByTag. A new one with the same Tag replaces it.</summary>
    property Tag: string read FTag write FTag;
    property Group: string read FGroup write FGroup;
    /// <summary>True: no sound.</summary>
    property Silent: Boolean read FSilent write FSilent;
  end;

implementation

var
  Registered: Boolean;
  InvokedToken: EventRegistrationToken;

// A click arrives on a thread pool thread: TWinUIApp.NotifyActivated takes it to the UI thread.
procedure EnsureRegistered;
var
  Invoked: TypedEventHandler_AppNotificationManager_AppNotificationActivatedEventArgs;
begin
  if Registered then
    Exit;
  // In a variable during the call: passed inline, its reference count is 0 and the
  // runtime's QueryInterface and Release would free it
  Invoked := TTypedEventHandler_AppNotificationManager_AppNotificationActivatedEventArgs.Create(
    procedure(ASender: IAppNotificationManager; AArgs: IAppNotificationActivatedEventArgs)
    begin
      TWinUIApp.NotifyActivated(TWinUIApp.NotificationActivation(AArgs));
    end);
  InvokedToken := AppNotificationManager.Default.add_NotificationInvoked(Invoked);
  // Registers this exe as the target of clicks, an app without MSIX gets a COM server for it
  AppNotificationManager.Default.&Register;
  Registered := True;
end;

function UriOf(const APathOrUrl: string): IUriRuntimeClass;
var
  S: string;
begin
  S := APathOrUrl;
  if not (S.StartsWith('http://', True) or S.StartsWith('https://', True) or S.StartsWith('file:', True) or
    S.StartsWith('ms-appx:', True)) then
    S := 'file:///' + ExpandFileName(S).Replace('\', '/');
  Result := Uri.New(WinStr(S));
end;

{ TWinUINotification }

procedure TWinUINotification.AddButton(const ACaption, AArgument: string);
begin
  FButtons := FButtons + [ACaption];
  FButtonArguments := FButtonArguments + [AArgument];
end;

procedure TWinUINotification.AddTextBox(const AId, APlaceholder: string);
begin
  FInputs := FInputs + [AId];
  FInputPlaceholders := FInputPlaceholders + [APlaceholder];
end;

procedure TWinUINotification.Show;
var
  Builder: IAppNotificationBuilder;
  Button: IAppNotificationButton;
  Line: string;
  I: Integer;
begin
  EnsureRegistered;
  Builder := AppNotificationBuilder.New;
  if FArgument <> '' then
    Builder.AddArgument(WinStr('arg'), WinStr(FArgument));
  if FTitle <> '' then
    Builder.AddText(WinStr(FTitle));
  for Line in FText.Split([#10]) do
    if Line.Trim <> '' then
      Builder.AddText(WinStr(Line.TrimRight([#13])));
  if FImage <> '' then
    Builder.SetAppLogoOverride(UriOf(FImage));
  if FHeroImage <> '' then
    Builder.SetHeroImage(UriOf(FHeroImage));
  for I := 0 to High(FInputs) do
    Builder.AddTextBox2(WinStr(FInputs[I]), WinStr(FInputPlaceholders[I]), WinStr(''));
  for I := 0 to High(FButtons) do
  begin
    Button := AppNotificationButton.New(WinStr(FButtons[I]));
    Button.AddArgument(WinStr('arg'), WinStr(FButtonArguments[I]));
    Builder.AddButton(Button);
  end;
  if FTag <> '' then
    Builder.SetTag(WinStr(FTag));
  if FGroup <> '' then
    Builder.SetGroup(WinStr(FGroup));
  if FSilent then
    Builder.MuteAudio;
  AppNotificationManager.Default.Show(Builder.BuildNotification);
end;

class function TWinUINotification.Supported: Boolean;
begin
  try
    Result := AppNotificationManager.IsSupported;
  except
    Result := False;
  end;
end;

class procedure TWinUINotification.RemoveAll;
begin
  AppNotificationManager.Default.RemoveAllAsync;
end;

class procedure TWinUINotification.RemoveByTag(const ATag: string);
begin
  AppNotificationManager.Default.RemoveByTagAsync(WinStr(ATag));
end;

procedure Unregister;
begin
  if not Registered then
    Exit;
  Registered := False;
  AppNotificationManager.Default.remove_NotificationInvoked(InvokedToken);
  // This process stops receiving clicks, Windows starts the app again for later ones
  AppNotificationManager.Default.Unregister;
end;

initialization
  // Before the app reads its activation: a click on a notification while the app
  // was closed then starts it with Kind Notification
  OnApplicationStart(EnsureRegistered);
  OnApplicationShutdown(Unregister);
end.
