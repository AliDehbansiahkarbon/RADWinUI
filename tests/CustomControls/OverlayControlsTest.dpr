program OverlayControlsTest;

{
  Checks the Overlay controls (RADWinUI.Controls): NotchPanel expands and
  collapses with its events and animation, GlowTile builds its glow, changes
  colour and fades out by itself, HotKey parses and registers shortcuts,
  MediaSession connects to the media Windows knows about. The window opens where
  RADWINUI_TEST_MONITOR puts test windows.
}

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.SysUtils,
  System.IOUtils,
  RADWinUI.Abi,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Forms,
  RADWinUI.CustomControls,
  RADWinUI.Controls;

type
  TTestWindow = class(TWinUIWindow)
  private
    FTimer: TWinUITimer;
    FStep: Integer;
    FFailures: Integer;
    FExpanded: Integer;
    FCollapsed: Integer;
    FClicks: Integer;
    FMedia: TWinUIMediaSession;
    FSecond: TWinUIWindow;
    FLiveBefore: Integer;
    procedure Check(AOk: Boolean; const AWhat: string);
    procedure Step(Sender: TObject);
    procedure NotchExpanded(Sender: TObject; const E: TWinValue);
    procedure NotchCollapsed(Sender: TObject; const E: TWinValue);
    procedure TileClick(Sender: TObject; const E: TWinValue);
  public
    constructor Create; override;
    destructor Destroy; override;
    class procedure Failed(Sender: TObject; E: Exception);
  end;

const
  ContentXaml =
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:rw="using:RADWinUI.Controls">' +
    '<rw:NotchPanel x:Name="Notch" CollapsedWidth="160" CollapsedHeight="30" ExpandedWidth="360" ' +
    'ExpandedHeight="200" AnimationDuration="200" ExpandOnHover="False">' +
    '<rw:NotchPanel.Pill><TextBlock x:Name="PillText" Text="pill" Foreground="White" /></rw:NotchPanel.Pill>' +
    '<StackPanel Padding="16"><TextBlock Text="panel" Foreground="White" />' +
    '<rw:GlowTile x:Name="Tile" Width="120" Height="80" Background="#202020" CornerRadius="16" ' +
    'GlowBrush="Orange" Pulse="True" /></StackPanel>' +
    '</rw:NotchPanel></Grid>';

/// src\Framework\RADWinUI.Controls.json of the checkout above the exe, '' when not found.
function ControlsJsonPath: string;
var
  Folder: string;
begin
  Folder := ExtractFileDir(ParamStr(0));
  while Folder <> '' do
  begin
    Result := TPath.Combine(Folder, 'src\Framework\RADWinUI.Controls.json');
    if FileExists(Result) then
      Exit;
    if ExtractFileDir(Folder) = Folder then
      Break;
    Folder := ExtractFileDir(Folder);
  end;
  Result := '';
end;

const
  SecondXaml =
    '<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:rw="using:RADWinUI.Controls">' +
    '<rw:NotchPanel><rw:GlowTile Width="80" Height="40" Background="#202020" GlowBrush="Orange" Pulse="True"/>' +
    '</rw:NotchPanel><rw:HotKey Keys="Ctrl+Alt+Shift+F22"/><rw:MediaSession/></StackPanel>';

{ TTestWindow }

class procedure TTestWindow.Failed(Sender: TObject; E: Exception);
begin
  Writeln('  [failed] ', E.ClassName, ': ', E.Message);
  Flush(Output);
  ExitProcess(1);
end;

constructor TTestWindow.Create;
begin
  inherited;
  Title := 'Overlay controls test';
  Width := 480;
  Height := 320;
  Writeln('Overlay controls');
  LoadContent(ContentXaml);
  Check(True, 'XAML with rw:NotchPanel and rw:GlowTile loads');
  FTimer := TWinUITimer.Create;
  FTimer.Interval := 500;
  FTimer.OnTimer := Step;
  FTimer.Enabled := True;
end;

destructor TTestWindow.Destroy;
begin
  FTimer.Free;
  inherited;
  if FFailures > 0 then
    ExitCode := 1;
end;

procedure TTestWindow.Check(AOk: Boolean; const AWhat: string);
begin
  if AOk then
    Writeln('  [ok] ', AWhat)
  else
  begin
    Writeln('  [failed] ', AWhat);
    Inc(FFailures);
  end;
end;

procedure TTestWindow.NotchExpanded(Sender: TObject; const E: TWinValue);
begin
  Inc(FExpanded);
end;

procedure TTestWindow.NotchCollapsed(Sender: TObject; const E: TWinValue);
begin
  Inc(FCollapsed);
end;

procedure TTestWindow.TileClick(Sender: TObject; const E: TWinValue);
begin
  Inc(FClicks);
end;

procedure TTestWindow.Step(Sender: TObject);
var
  Notch: TWinUINotchPanel;
  Tile: TWinUIGlowTile;
  Json: string;
  HotKey: TWinUIHotKey;
  Modifiers, Key: Cardinal;
begin
  Inc(FStep);
  try
    Notch := FindElement<TWinUINotchPanel>('Notch');
    Tile := FindElement<TWinUIGlowTile>('Tile');
    case FStep of
      1:
        begin
          Check(Notch is TWinUINotchPanel, 'FindElement returns the NotchPanel');
          Check(not Notch.IsExpanded and (Notch.Progress = 0), 'starts collapsed');
          Check(Abs(Notch.ActualWidth - 160) < 1, Format('collapsed width 160 (%.1f)', [Notch.ActualWidth]));
          Check(Abs(Notch.ActualHeight - 30) < 1, Format('collapsed height 30 (%.1f)', [Notch.ActualHeight]));
          Check(Notch.Background is TWinUISolidColorBrush, 'black background by default');
          Check(Abs(Notch.ExpandedCornerRadius - 28) < 1E-9, 'default ExpandedCornerRadius');
          Check(Notch.SquareTop, 'default SquareTop');
          FMedia := TWinUIMediaSession.Create(Self);
          // A second window with every Overlay control: closing it must free them
          FLiveBefore := TWinUICustomControls.LiveCount;
          FSecond := TWinUIWindow.Create;
          FSecond.LoadContent(SecondXaml);
          FSecond.Show;
          Check(TWinUICustomControls.LiveCount = FLiveBefore + 4, Format('a loaded window has its 4 controls (%d -> %d)',
            [FLiveBefore, TWinUICustomControls.LiveCount]));
          Notch.OnExpanded := NotchExpanded;
          Notch.OnCollapsed := NotchCollapsed;
          Notch.Expand;
          Check(Notch.IsExpanded and (FExpanded = 1), 'Expand sets IsExpanded and fires Expanded');
        end;
      2:
        begin
          Check(Abs(Notch.Progress - 1) < 1E-9, Format('animation reaches the end (%.3f)', [Notch.Progress]));
          Check(Abs(Notch.ActualWidth - 360) < 1, Format('expanded width 360 (%.1f)', [Notch.ActualWidth]));
          Check(Abs(Notch.ActualHeight - 200) < 1, Format('expanded height 200 (%.1f)', [Notch.ActualHeight]));
          Check(FindElement<TWinUITextBlock>('PillText').ActualWidth >= 0, 'pill content is a named element');
          Check(Tile is TWinUIGlowTile, 'FindElement returns the GlowTile inside the panel');
          Check(Tile.IsGlowing and Tile.Pulse, 'GlowTile properties from XAML');
          Tile.OnClick := TileClick;
          Tile.GlowBrush := TWinUISolidColorBrush.Create(Self);
          Tile.FadeAfter := 0.3;
          Check(Tile.IsGlowing, 'still glowing right after FadeAfter is set');
          Notch.Toggle;
          Check(not Notch.IsExpanded and (FCollapsed = 1), 'Toggle collapses and fires Collapsed');
          FSecond.Close;
        end;
      3:
        begin
          Check(Abs(Notch.Progress) < 1E-9, Format('collapse animation ends at 0 (%.3f)', [Notch.Progress]));
          Check(Abs(Notch.ActualWidth - 160) < 1, Format('back to collapsed width (%.1f)', [Notch.ActualWidth]));
          Check(not Tile.IsGlowing, 'FadeAfter turns the glow off by itself');
          Check(TWinUICustomControls.LiveCount = FLiveBefore, Format('closing a window frees its controls (%d left, ' +
            '%d XAML elements)', [TWinUICustomControls.LiveCount, TWinUICustomControls.HostCount]));
          Json := TWinUICustomControls.TypeIndexJson;
          Check(Json.Contains('"RADWinUI.Controls.NotchPanel"') and Json.Contains('"RADWinUI.Controls.GlowTile"') and
            Json.Contains('"Overlay"'), 'type index lists both controls in Overlay');
          Check((ControlsJsonPath <> '') and (TFile.ReadAllText(ControlsJsonPath, TEncoding.UTF8) = Json),
            'src\Framework\RADWinUI.Controls.json is up to date (tools\ControlsIndex writes it)');
          Check(TWinUIHotKey.ParseKeys('Ctrl+Alt+T', Modifiers, Key) and (Modifiers = MOD_CONTROL or MOD_ALT) and
            (Key = Ord('T')), 'HotKey parses Ctrl+Alt+T');
          Check(TWinUIHotKey.ParseKeys('win + shift + f12', Modifiers, Key) and (Modifiers = MOD_WIN or MOD_SHIFT) and
            (Key = VK_F12), 'HotKey parses lower case with spaces and F keys');
          Check(not TWinUIHotKey.ParseKeys('Ctrl+Foo', Modifiers, Key) and not TWinUIHotKey.ParseKeys('Hyper+A', Modifiers, Key),
            'HotKey rejects unknown keys and modifiers');
          Check(FMedia.Connected, 'MediaSession connects to the Windows media sessions');
          Check(FMedia.HasSession = (FMedia.Session <> nil), Format('MediaSession HasSession follows the session (%s, "%s")',
            [BoolToStr(FMedia.HasSession, True), FMedia.SourceApp]));
          HotKey := TWinUIHotKey.Create(Self);
          HotKey.Keys := 'Ctrl+Alt+Shift+F23';
          Check(HotKey.Registered, 'HotKey registers a free shortcut');
          HotKey.IsActive := False;
          Check(not HotKey.Registered, 'IsActive False releases it');
          Flush(Output);
          Close;
        end;
    end;
  except
    on E: Exception do
      Failed(Self, E);
  end;
end;

begin
  if GetEnvironmentVariable('RADWINUI_TEST_MONITOR') = '' then
    SetEnvironmentVariable('RADWINUI_TEST_MONITOR', 'offscreen');
  TWinUIApp.OnException := TTestWindow.Failed;
  TWinUIApp.Run(TTestWindow);
end.
