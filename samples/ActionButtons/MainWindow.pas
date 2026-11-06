unit MainWindow;

interface

uses
  System.SysUtils,
  RADWinUI.Forms,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.ActionButtons,
  MainWindow.Xaml;

type
  TMainWindow = class(TMainWindowBase)   // TMainWindowBase is generated from MainWindow.xaml
  private
    FButtons: TArray<TWinUIActionButton>;
    FWave: TWinUITimer;
    FWaveStep: Integer;
    FReady: Boolean;
    function MakeBrush(AColor: Cardinal): TWinUISolidColorBrush;
    procedure SetAccent(AButton: TWinUIActionButton; AFrom, ATo: Cardinal);
    procedure SetAllAccents(AFrom, ATo: Cardinal);
    procedure Report(const AText: string);
    procedure WaveTick(Sender: TObject);
    procedure UpdateGlass;
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    procedure HoldConfirmed(Sender: TObject; const E: TWinValue);
    procedure SendClick(Sender: TObject; const E: TWinValue);
    procedure ConfettiClick(Sender: TObject; const E: TWinValue);
    procedure CopyCopied(Sender: TObject; const E: TWinValue);
    procedure ShineClick(Sender: TObject; const E: TWinValue);
    procedure SlideConfirmed(Sender: TObject; const E: TWinValue);
    procedure OriginalClick(Sender: TObject);
    procedure SunsetClick(Sender: TObject);
    procedure MintClick(Sender: TObject);
    procedure OceanClick(Sender: TObject);
    procedure PlayAllClick(Sender: TObject);
    procedure TransparencyToggled(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure GlassChanged(Sender: TObject; E: TWinUIRangeBaseValueChangedEventArgs);
  end;

implementation

constructor TMainWindow.Create;
begin
  inherited;
  FButtons := [HoldButton1, SendButton1, ConfettiButton1, CopyButton1, ShineButton1, SlideButton1];
  // Play all starts one button after the other, so a wave runs across the page
  FWave := TWinUITimer.Create;
  FWave.Interval := 260;
  FWave.OnTimer := WaveTick;
  FReady := True;
  UpdateGlass;
end;

destructor TMainWindow.Destroy;
begin
  FWave.Free;
  inherited;
end;

function TMainWindow.MakeBrush(AColor: Cardinal): TWinUISolidColorBrush;
var
  C: TWinUIColor;
begin
  C.A := $FF;
  C.R := (AColor shr 16) and $FF;
  C.G := (AColor shr 8) and $FF;
  C.B := AColor and $FF;
  Result := TWinUISolidColorBrush.Create(Self);
  Result.Color := C;
end;

procedure TMainWindow.SetAccent(AButton: TWinUIActionButton; AFrom, ATo: Cardinal);
begin
  AButton.AccentFrom := MakeBrush(AFrom);
  AButton.AccentTo := MakeBrush(ATo);
end;

procedure TMainWindow.SetAllAccents(AFrom, ATo: Cardinal);
var
  Button: TWinUIActionButton;
begin
  for Button in FButtons do
    SetAccent(Button, AFrom, ATo);
  StatusDot.Fill := MakeBrush(ATo);
end;

procedure TMainWindow.Report(const AText: string);
begin
  if FReady then
    StatusText.Text := Format('%s  at %s', [AText, FormatDateTime('hh:nn:ss', Now)]);
end;

procedure TMainWindow.HoldConfirmed(Sender: TObject; const E: TWinValue);
begin
  Report('Hold to Confirm: Confirmed');
end;

procedure TMainWindow.SendClick(Sender: TObject; const E: TWinValue);
begin
  Report('Paper Plane: Click, the message is on its way');
end;

procedure TMainWindow.ConfettiClick(Sender: TObject; const E: TWinValue);
begin
  Report(Format('Confetti Burst: Click, %d pieces in the air', [ConfettiButton1.FlyingCount]));
end;

procedure TMainWindow.CopyCopied(Sender: TObject; const E: TWinValue);
begin
  Report(Format('Copy Feedback: Copied, "%s" is on the clipboard', [CopyButton1.Text]));
end;

procedure TMainWindow.ShineClick(Sender: TObject; const E: TWinValue);
begin
  Report('Shine Sweep: Click');
end;

procedure TMainWindow.SlideConfirmed(Sender: TObject; const E: TWinValue);
begin
  Report('Slide to Confirm: Confirmed');
end;

procedure TMainWindow.OriginalClick(Sender: TObject);
begin
  // The colours each button has unless AccentFrom and AccentTo are set
  SetAccent(HoldButton1, $3D6BFF, $4FC3FF);
  SetAccent(SendButton1, $6C55FF, $3CB4FF);
  SetAccent(ConfettiButton1, $7B5CFF, $FF5FA8);
  SetAccent(CopyButton1, $3D6BFF, $5A9BFF);
  SetAccent(ShineButton1, $6A5CFF, $FF5FA0);
  SetAccent(SlideButton1, $6C55FF, $3CB4FF);
  StatusDot.Fill := MakeBrush($FF5FA8);
end;

procedure TMainWindow.SunsetClick(Sender: TObject);
begin
  SetAllAccents($FF5F6D, $FFB347);
end;

procedure TMainWindow.MintClick(Sender: TObject);
begin
  SetAllAccents($11B98E, $5EDC8C);
end;

procedure TMainWindow.OceanClick(Sender: TObject);
begin
  SetAllAccents($2B5CFF, $1FB8E8);
end;

procedure TMainWindow.PlayAllClick(Sender: TObject);
var
  Button: TWinUIActionButton;
begin
  // Every button from its start, also one that is still busy from a click
  for Button in FButtons do
    Button.Reset;
  FWaveStep := 0;
  FWave.Enabled := True;
end;

procedure TMainWindow.WaveTick(Sender: TObject);
begin
  if FWaveStep > High(FButtons) then
  begin
    FWave.Enabled := False;
    Exit;
  end;
  FButtons[FWaveStep].Play;
  Inc(FWaveStep);
end;

// With Transparency on the window has a Transparent backdrop and the page is
// only as opaque as the slider says, so the desktop shows through. Off, the
// window gets Mica and its frame back, under an opaque page.
procedure TMainWindow.UpdateGlass;
begin
  if TransparencySwitch.IsOn then
  begin
    if Backdrop <> TWinUIBackdrop.Transparent then
      Backdrop := TWinUIBackdrop.Transparent;
    Glass.Opacity := 1 - GlassSlider.Value / 100;
  end
  else
  begin
    if Backdrop <> TWinUIBackdrop.Mica then
      Backdrop := TWinUIBackdrop.Mica;
    Glass.Opacity := 1;
  end;
  GlassSlider.IsEnabled := TransparencySwitch.IsOn;
  GlassText.Text := Format('%d%%', [Round(GlassSlider.Value)]);
end;

procedure TMainWindow.TransparencyToggled(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  if FReady then
    UpdateGlass;
end;

procedure TMainWindow.GlassChanged(Sender: TObject; E: TWinUIRangeBaseValueChangedEventArgs);
begin
  if FReady then
    UpdateGlass;
end;

end.
