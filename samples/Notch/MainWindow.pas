unit MainWindow;

interface

uses
  RADWinUI.Forms,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Controls,
  MainWindow.Xaml;

type
  TBuildState = (Idle, Running, Done);

  TMainWindow = class(TMainWindowBase)
  private
    FTimer: TWinUITimer;
    FTicks: Integer;
    FOrange, FBlue, FGreen, FPurple: TWinUISolidColorBrush;
    FSolidNotch, FGlassNotch: TWinUISolidColorBrush;
    FBuildState: TBuildState;
    FBuildStep: Integer;
    FBuildTicks: Integer;
    FFocusLeft: Integer;
    FFocusRunning: Boolean;
    FPinned: Boolean;
    FSmokeStep: Integer;
    function MakeBrush(AColor: Cardinal): TWinUISolidColorBrush;
    procedure TimerTick(Sender: TObject);
    procedure UpdateClock;
    procedure BuildTick;
    procedure SetBuildState(AState: TBuildState);
    procedure UpdateFocus;
    procedure SmokeStep;
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    procedure ToggleKeyPressed(Sender: TObject);
    procedure MediaChanged(Sender: TObject);
    procedure PinButtonClick(Sender: TObject);
    procedure TransparencySwitchToggled(Sender: TObject);
    procedure QuitButtonClick(Sender: TObject);
    procedure BuildButtonClick(Sender: TObject);
    procedure PreviousButtonClick(Sender: TObject);
    procedure PlayButtonClick(Sender: TObject);
    procedure NextButtonClick(Sender: TObject);
    procedure FocusButtonClick(Sender: TObject);
    procedure ResetButtonClick(Sender: TObject);
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils;

const
  FocusSeconds = 25 * 60;
  TickMs = 250;
  // Ticks per build step: four steps of a second each
  StepTicks = 4;
  BuildSteps: array[1..4] of string = ('Restoring packages', 'Compiling 128 units', 'Linking', 'Packaging');
  PlayGlyphText = #$E768;
  PauseGlyphText = #$E769;
  PinGlyphText = #$E718;
  UnpinGlyphText = #$E77A;

constructor TMainWindow.Create;
begin
  inherited;
  // Only the notch takes the pointer, clicks next to it reach the windows below
  HitTestElement := Notch;
  FOrange := MakeBrush($FFFF8A3D);
  FBlue := MakeBrush($FF4C9BFF);
  FGreen := MakeBrush($FF3DDC84);
  FPurple := MakeBrush($FFA77BFF);
  FSolidNotch := MakeBrush($FF000000);
  // Dark enough to read white text over any wallpaper
  FGlassNotch := MakeBrush($B8000000);
  FFocusLeft := FocusSeconds;
  UpdateFocus;
  UpdateClock;
  FTimer := TWinUITimer.Create;
  FTimer.Interval := TickMs;
  FTimer.OnTimer := TimerTick;
  FTimer.Enabled := True;
  if FindCmdLineSwitch('smoke-test') then
  begin
    Notch.HoverDelay := 0;
    Notch.AnimationDuration := 100;
  end;
end;

destructor TMainWindow.Destroy;
begin
  FTimer.Free;
  inherited;
end;

function TMainWindow.MakeBrush(AColor: Cardinal): TWinUISolidColorBrush;
var
  C: TWinUIColor;
begin
  C.A := AColor shr 24;
  C.R := (AColor shr 16) and $FF;
  C.G := (AColor shr 8) and $FF;
  C.B := AColor and $FF;
  Result := TWinUISolidColorBrush.Create(Self);
  Result.Color := C;
end;

procedure TMainWindow.TimerTick(Sender: TObject);
begin
  Inc(FTicks);
  if FTicks mod (1000 div TickMs) = 0 then
  begin
    UpdateClock;
    if FFocusRunning then
    begin
      Dec(FFocusLeft);
      if FFocusLeft <= 0 then
      begin
        FFocusLeft := 0;
        FFocusRunning := False;
        FocusTile.GlowBrush := FGreen;
        FocusTile.Pulse := False;
        FocusTile.FadeAfter := 8;
        FocusButton.Content := 'Start';
        // Time is up: show it
        Notch.Expand;
      end;
      UpdateFocus;
    end;
  end;
  if FBuildState = TBuildState.Running then
    BuildTick;
  if FindCmdLineSwitch('smoke-test') and (FTicks mod 2 = 0) then
    SmokeStep;
end;

procedure TMainWindow.UpdateClock;
begin
  PillClock.Text := FormatDateTime('hh:nn', Now);
  ClockLabel.Text := PillClock.Text;
  DateLabel.Text := FormatDateTime('dddd, d mmmm', Now);
end;

procedure TMainWindow.ToggleKeyPressed(Sender: TObject);
begin
  Notch.Toggle;
end;

procedure TMainWindow.PinButtonClick(Sender: TObject);
begin
  // Pinned, the panel stays open when the pointer leaves
  FPinned := not FPinned;
  Notch.ExpandOnHover := not FPinned;
  if FPinned then
  begin
    PinGlyph.Glyph := UnpinGlyphText;
    Notch.Expand;
  end
  else
    PinGlyph.Glyph := PinGlyphText;
end;

procedure TMainWindow.TransparencySwitchToggled(Sender: TObject);
begin
  // The window is see-through already, so the notch's own colour decides what shows
  if TransparencySwitch.IsOn then
    Notch.Background := FGlassNotch
  else
    Notch.Background := FSolidNotch;
end;

procedure TMainWindow.QuitButtonClick(Sender: TObject);
begin
  Close;
end;

{ Build }

procedure TMainWindow.BuildButtonClick(Sender: TObject);
begin
  if FBuildState <> TBuildState.Running then
    SetBuildState(TBuildState.Running);
end;

procedure TMainWindow.SetBuildState(AState: TBuildState);
begin
  FBuildState := AState;
  case AState of
    TBuildState.Running:
      begin
        FBuildStep := 1;
        FBuildTicks := 0;
        BuildStatus.Text := 'Building';
        BuildDetail.Text := BuildSteps[1];
        BuildProgress.Value := 0;
        BuildButton.IsEnabled := False;
        BuildTile.FadeAfter := 0;
        BuildTile.GlowBrush := FOrange;
        BuildTile.Pulse := True;
        BuildTile.IsGlowing := True;
        PillDot.Fill := FOrange;
      end;
    TBuildState.Done:
      begin
        BuildStatus.Text := 'Succeeded';
        BuildDetail.Text := FormatDateTime('"Finished at" hh:nn', Now);
        BuildProgress.Value := Length(BuildSteps);
        BuildButton.IsEnabled := True;
        BuildTile.Pulse := False;
        BuildTile.GlowBrush := FBlue;
        // Blue says "just finished", a few seconds later it settles to green
        BuildTile.FadeAfter := 6;
        PillDot.Fill := FBlue;
      end;
  end;
end;

procedure TMainWindow.BuildTick;
begin
  Inc(FBuildTicks);
  if FBuildTicks < StepTicks then
    Exit;
  FBuildTicks := 0;
  BuildProgress.Value := FBuildStep;
  Inc(FBuildStep);
  if FBuildStep > Length(BuildSteps) then
    SetBuildState(TBuildState.Done)
  else
    BuildDetail.Text := BuildSteps[FBuildStep];
end;

{ Music }

procedure TMainWindow.MediaChanged(Sender: TObject);
begin
  if Media.HasSession and (Media.Title <> '') then
  begin
    MusicTitle.Text := Media.Title;
    MusicArtist.Text := Media.Artist;
    MusicSource.Text := ChangeFileExt(ExtractFileName(Media.SourceApp), '');
  end
  else
  begin
    MusicTitle.Text := 'Nothing playing';
    MusicArtist.Text := 'Start music in any app';
    MusicSource.Text := 'Now playing';
  end;
  if Media.IsPlaying then
    PlayGlyph.Glyph := PauseGlyphText
  else
    PlayGlyph.Glyph := PlayGlyphText;
  MusicTile.IsGlowing := Media.IsPlaying;
  MusicTile.Pulse := Media.IsPlaying;
  if Media.IsPlaying then
    PillMusic.Opacity := 1
  else
    PillMusic.Opacity := 0;
end;

procedure TMainWindow.PreviousButtonClick(Sender: TObject);
begin
  Media.Previous;
end;

procedure TMainWindow.PlayButtonClick(Sender: TObject);
begin
  Media.PlayPause;
end;

procedure TMainWindow.NextButtonClick(Sender: TObject);
begin
  Media.Next;
end;

{ Focus }

procedure TMainWindow.FocusButtonClick(Sender: TObject);
begin
  if FFocusLeft = 0 then
    FFocusLeft := FocusSeconds;
  FFocusRunning := not FFocusRunning;
  if FFocusRunning then
  begin
    FocusButton.Content := 'Pause';
    FocusTile.FadeAfter := 0;
    FocusTile.GlowBrush := FPurple;
    FocusTile.Pulse := True;
    FocusTile.IsGlowing := True;
  end
  else
  begin
    FocusButton.Content := 'Resume';
    FocusTile.Pulse := False;
  end;
  UpdateFocus;
end;

procedure TMainWindow.ResetButtonClick(Sender: TObject);
begin
  FFocusRunning := False;
  FFocusLeft := FocusSeconds;
  FocusButton.Content := 'Start';
  FocusTile.Pulse := False;
  FocusTile.IsGlowing := False;
  UpdateFocus;
end;

procedure TMainWindow.UpdateFocus;
begin
  FocusClock.Text := Format('%.2d:%.2d', [FFocusLeft div 60, FFocusLeft mod 60]);
end;

{ Smoke test: Notch.exe -smoke-test <result file> }

procedure TMainWindow.SmokeStep;
begin
  Inc(FSmokeStep);
  try
    case FSmokeStep of
      1:
        begin
          if Notch.IsExpanded or (Notch.ActualWidth > 221) then
            raise Exception.Create('The notch does not start as a pill');
          if PillClock.Text <> FormatDateTime('hh:nn', Now) then
            raise Exception.Create('The pill shows ' + PillClock.Text);
          ToggleKeyPressed(nil);
        end;
      3:
        begin
          if not Notch.IsExpanded or (Abs(Notch.ActualWidth - 680) > 1) then
            raise Exception.Create(Format('The hotkey did not open the panel (%.0f wide)', [Notch.ActualWidth]));
          BuildButtonClick(nil);
          FocusButtonClick(nil);
          if (BuildStatus.Text <> 'Building') or not BuildTile.Pulse then
            raise Exception.Create('The build did not start');
        end;
      5:
        begin
          if not FFocusRunning or (FocusClock.Text = '25:00') then
            raise Exception.Create('The focus timer does not run: ' + FocusClock.Text);
          ResetButtonClick(nil);
          if FocusClock.Text <> '25:00' then
            raise Exception.Create('Reset did not reset the timer');
        end;
      14:
        begin
          if (FBuildState <> TBuildState.Done) or (BuildStatus.Text <> 'Succeeded') then
            raise Exception.Create('The build did not finish: ' + BuildStatus.Text + ' / ' + BuildDetail.Text);
          if not Media.Connected then
            raise Exception.Create('The media session did not connect');
          PinButtonClick(nil);
          if Notch.ExpandOnHover then
            raise Exception.Create('Pin did not keep the panel open');
          TransparencySwitch.IsOn := True;
          if (Notch.Background as TWinUISolidColorBrush).Color.A = 255 then
            raise Exception.Create('Transparency did not make the notch see-through');
          TransparencySwitch.IsOn := False;
          if (Notch.Background as TWinUISolidColorBrush).Color.A <> 255 then
            raise Exception.Create('Transparency off did not make the notch solid again');
          TFile.WriteAllText(ParamStr(2), 'PASS: pill, hotkey, panel, build, focus timer, media session, pin, transparency');
          Close;
        end;
    end;
  except
    on E: Exception do
    begin
      TFile.WriteAllText(ParamStr(2), 'FAIL: ' + E.Message);
      Close;
    end;
  end;
end;

end.
