unit QueueWindow;

interface

uses
  RADWinUI.Forms,
  RADWinUI.Xaml,
  StationData,
  QueueWindow.Xaml;

type
  TQueueWindow = class(TQueueWindowBase)   // generated from QueueWindow.xaml
  private
    procedure WindowClose(Sender: TObject; var Action: TWinUICloseAction);
  public
    constructor Create; override;
    /// <summary>Lists the stations after ACurrent.</summary>
    procedure Refresh(ACurrent: TStation);
  end;

implementation

constructor TQueueWindow.Create;
begin
  inherited;
  OnClose := WindowClose;
end;

procedure TQueueWindow.WindowClose(Sender: TObject; var Action: TWinUICloseAction);
begin
  // Like a VCL tool window with caHide: the main window shows it again later
  Action := TWinUICloseAction.Hide;
end;

procedure TQueueWindow.Refresh(ACurrent: TStation);
var
  I, Start: Integer;
begin
  UpNext.Items.Clear;
  Start := Stations.IndexOf(ACurrent);
  for I := 1 to Stations.Count - 1 do
    UpNext.Items.Add(Stations[(Start + I) mod Stations.Count].Name);
end;

end.