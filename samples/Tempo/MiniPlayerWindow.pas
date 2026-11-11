unit MiniPlayerWindow;

interface

uses
  RADWinUI.Forms,
  RADWinUI.Xaml,
  MiniPlayerWindow.Xaml;

type
  TMiniPlayerWindow = class(TMiniPlayerWindowBase)   // generated from MiniPlayerWindow.xaml
  private
    FPlayer: TWinUIWindow;
  public
    /// <summary>A mini player for the main window APlayer.</summary>
    constructor CreatePlayer(APlayer: TWinUIWindow);
    procedure Refresh;
  published
    procedure PlayClick(Sender: TObject);
  end;

implementation

uses
  MainWindow;

constructor TMiniPlayerWindow.CreatePlayer(APlayer: TWinUIWindow);
begin
  Create;
  FPlayer := APlayer;
  Refresh;
end;

procedure TMiniPlayerWindow.Refresh;
var
  Main: TMainWindow;
begin
  Main := FPlayer as TMainWindow;
  StationName.Text := Main.Current.Name;
  GenreText.Text := Main.Current.Genre;
  if Main.Playing then
    PlayButton.Content := 'Pause'
  else
    PlayButton.Content := 'Play';
end;

procedure TMiniPlayerWindow.PlayClick(Sender: TObject);
begin
  (FPlayer as TMainWindow).TogglePlay;
end;

end.