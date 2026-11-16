unit MiniRoastWindow;

interface

uses
  System.SysUtils,
  RADWinUI.Forms,
  RADWinUI.Xaml,
  MiniRoastWindow.Xaml;

type
  TMiniRoastWindow = class(TMiniRoastWindowBase)   // generated from MiniRoastWindow.xaml
  private
    procedure RoastChanged(Sender: TObject);
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

implementation

uses
  EmberSettings,
  RoastSession;

constructor TMiniRoastWindow.Create;
begin
  inherited;
  Title := S('MiniTitle', 'Ember roaster');
  // The compact overlay presenter picks its own size: a small one suits a gauge
  Width := 340;
  Height := 190;
  Roast.Listen(RoastChanged);
  RoastChanged(nil);
end;

destructor TMiniRoastWindow.Destroy;
begin
  Roast.Unlisten(RoastChanged);
  inherited;
end;

procedure TMiniRoastWindow.RoastChanged(Sender: TObject);
const
  PhaseKeys: array[TRoastPhase] of string = ('PhaseIdle', 'PhaseDrying/Text', 'PhaseMaillard/Text',
    'PhaseDevelopment/Text', 'PhaseDone/Text');
  PhaseNames: array[TRoastPhase] of string = ('Ready', 'Drying', 'Maillard', 'Development', 'Done');
begin
  if Roast.Phase = TRoastPhase.Idle then
  begin
    TitleText.Text := S('NoBatch', 'No batch in the roaster');
    TempText.Text := '-';
    TimeText.Text := '';
  end
  else
  begin
    TitleText.Text := Format('#%d  %s', [Roast.BatchNo, Roast.Coffee]);
    TempText.Text := Format('%.0f'#$00B0, [Roast.BeanTemp]);
    TimeText.Text := FormatClock(Roast.Seconds);
  end;
  PhaseText.Text := S(PhaseKeys[Roast.Phase], PhaseNames[Roast.Phase]);
  Progress.Value := Roast.Seconds;
end;

end.
