unit MainWindow;

interface

uses
  System.SysUtils,
  System.UITypes,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Binding,
  RADWinUI.Forms,
  StationData,
  MainWindow.Xaml;

type
  TMainWindow = class(TMainWindowBase)   // generated from MainWindow.xaml
  private
    FShown: TWinUIBindableList<TStation>;
    FCurrent: TStation;
    FHistory: TArray<TStation>;
    FPlaying: Boolean;
    FTimer: TWinUITimer;
    FQueue: TWinUIWindow;
    FMini: TWinUIWindow;
    procedure Filter;
    procedure Play(AStation: TStation; ARemember: Boolean);
    procedure UpdateNowPlaying;
    procedure Tick(Sender: TObject);
    procedure WindowClose(Sender: TObject; var Action: TWinUICloseAction);
    function IsOpen(AWindow: TWinUIWindow): Boolean;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure TogglePlay;
    property Current: TStation read FCurrent;
    property Playing: Boolean read FPlaying;
  published
    procedure SearchChanged(Sender: TObject);
    procedure StationClick(Sender: TObject; E: TWinUIItemClickEventArgs);
    procedure TitleBarBackRequested(Sender: TObject);
    procedure PlayClick(Sender: TObject);
    procedure QueueClick(Sender: TObject);
    procedure MiniClick(Sender: TObject);
    procedure FullScreenClick(Sender: TObject);
    procedure AddClick(Sender: TObject);
  end;

implementation

uses
  QueueWindow,
  AddStationWindow,
  MiniPlayerWindow;

constructor TMainWindow.Create;
begin
  inherited;
  FShown := TWinUIBindableList<TStation>.Create(False);
  StationList.ItemsSource := FShown;
  Filter;
  FTimer := TWinUITimer.Create;
  FTimer.Interval := 500;
  FTimer.OnTimer := Tick;
  // Where the window was last time: position, size and maximized
  RestorePlacement;
  OnClose := WindowClose;
  Play(Stations[0], False);
end;

destructor TMainWindow.Destroy;
begin
  FTimer.Free;
  FShown.Free;
  inherited;
end;

procedure TMainWindow.WindowClose(Sender: TObject; var Action: TWinUICloseAction);
begin
  if WindowState = TWinUIWindowState.FullScreen then
    WindowState := TWinUIWindowState.Normal;
  SavePlacement;
end;

function TMainWindow.IsOpen(AWindow: TWinUIWindow): Boolean;
var
  W: TWinUIWindow;
begin
  for W in TWinUIApp.Windows do
    if W = AWindow then
      Exit(True);
  Result := False;
end;

procedure TMainWindow.Filter;
var
  I: Integer;
  Text: string;
begin
  Text := Trim(SearchBox.Text).ToLower;
  FShown.Clear;
  for I := 0 to Stations.Count - 1 do
    if (Text = '') or Stations[I].Name.ToLower.Contains(Text) or Stations[I].Genre.ToLower.Contains(Text) then
      FShown.Add(Stations[I]);
  if FShown.Count = 1 then
    CountText.Text := '1 station'
  else
    CountText.Text := Format('%d stations', [FShown.Count]);
end;

procedure TMainWindow.Play(AStation: TStation; ARemember: Boolean);
begin
  if (FCurrent <> nil) and ARemember and (AStation <> FCurrent) then
    FHistory := FHistory + [FCurrent];
  FCurrent := AStation;
  Progress.Value := 0;
  UpdateNowPlaying;
end;

procedure TMainWindow.UpdateNowPlaying;
begin
  StationName.Text := FCurrent.Name;
  GenreText.Text := FCurrent.Genre;
  if FPlaying then
    PlayButton.Content := 'Pause'
  else
    PlayButton.Content := 'Play';
  // The title bar's back button goes back through the stations played before
  AppTitleBar.IsBackButtonEnabled := Length(FHistory) > 0;
  Title := 'Tempo - ' + FCurrent.Name;
  if IsOpen(FMini) then
    (FMini as TMiniPlayerWindow).Refresh;
  if IsOpen(FQueue) then
    (FQueue as TQueueWindow).Refresh(FCurrent);
end;

procedure TMainWindow.TogglePlay;
begin
  FPlaying := not FPlaying;
  FTimer.Enabled := FPlaying;
  UpdateNowPlaying;
end;

procedure TMainWindow.Tick(Sender: TObject);
begin
  if Progress.Value >= 100 then
    Progress.Value := 0
  else
    Progress.Value := Progress.Value + 2;
end;

procedure TMainWindow.SearchChanged(Sender: TObject);
begin
  Filter;
end;

procedure TMainWindow.StationClick(Sender: TObject; E: TWinUIItemClickEventArgs);
var
  Clicked: IInterface;
  I: Integer;
begin
  // The clicked item is the WinRT object XAML sees, so compare COM identities
  Clicked := E.ClickedItem.Obj as IInterface;
  for I := 0 to FShown.Count - 1 do
    if (FShown.BindableAt(I) as IInterface) = Clicked then
    begin
      Play(FShown[I], True);
      Exit;
    end;
end;

procedure TMainWindow.TitleBarBackRequested(Sender: TObject);
var
  Previous: TStation;
begin
  if Length(FHistory) = 0 then
    Exit;
  Previous := FHistory[High(FHistory)];
  SetLength(FHistory, Length(FHistory) - 1);
  Play(Previous, False);
end;

procedure TMainWindow.PlayClick(Sender: TObject);
begin
  TogglePlay;
end;

procedure TMainWindow.QueueClick(Sender: TObject);
begin
  // A tool window: it belongs to this window, closing it only hides it
  if not IsOpen(FQueue) then
  begin
    FQueue := TQueueWindow.Create;
    FQueue.OwnerWindow := Self;
  end;
  (FQueue as TQueueWindow).Refresh(FCurrent);
  FQueue.Show;
end;

procedure TMainWindow.MiniClick(Sender: TObject);
begin
  if not IsOpen(FMini) then
    FMini := TMiniPlayerWindow.CreatePlayer(Self);
  FMini.Show;
end;

procedure TMainWindow.FullScreenClick(Sender: TObject);
begin
  if WindowState = TWinUIWindowState.FullScreen then
  begin
    WindowState := TWinUIWindowState.Normal;
    FullScreenButton.Content := 'Full screen';
  end
  else
  begin
    WindowState := TWinUIWindowState.FullScreen;
    FullScreenButton.Content := 'Exit full screen';
  end;
end;

procedure TMainWindow.AddClick(Sender: TObject);
var
  Dialog: TAddStationWindow;
begin
  // A modal window: this one is disabled until it closes, the answer comes in the callback
  Dialog := TAddStationWindow.Create;
  Dialog.OwnerWindow := Self;
  Dialog.ShowModal(
    procedure(AResult: TModalResult)
    var
      Station: TStation;
    begin
      if AResult <> mrOk then
      begin
        Status.Text := 'No station added';
        Exit;
      end;
      Station := TStation.Create(Dialog.StationName, Dialog.Genre);
      Stations.Add(Station);
      Filter;
      Play(Station, True);
      Status.Text := 'Added ' + Station.Name;
    end);
end;

end.
