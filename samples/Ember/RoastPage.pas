unit RoastPage;

interface

uses
  System.SysUtils,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Pages,
  RADWinUI.Dialogs,
  RoastPage.Xaml;

type
  TRoastPage = class(TRoastPageBase)   // generated from RoastPage.xaml
  private
    FPhase: Integer;
    procedure RoastChanged(Sender: TObject);
    procedure ShowNumbers;
    procedure ShowPhase;
    procedure Draw;
  protected
    procedure NavigatedTo(const AArgs: TWinUINavigationArgs); override;
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    procedure PlotSizeChanged(Sender: TObject; E: TWinUISizeChangedEventArgs);
    procedure PopOutClick(Sender: TObject);
    procedure QuickStartClick(Sender: TObject);
    procedure DropConfirmed(Sender: TObject; const E: TWinValue);
  end;

implementation

uses
  System.Math,
  RADWinUI.Abi,
  RADWinUI.Motion,
  EmberData,
  EmberSettings,
  RoastSession,
  MainWindow;

const
  MinTemp = 60;
  MaxTemp = 240;
  MaxSeconds = 720;
  LeftPad = 4;
  RightPad = 16;
  TopPad = 10;
  BottomPad = 6;
  QuickCoffee = 'Yirgacheffe';
  QuickKg = 12;

function Point(AX, AY: Double): TWinUIPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function At(ALeft, ATop: Double): TWinUIThickness;
begin
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Right := 0;
  Result.Bottom := 0;
end;

constructor TRoastPage.Create;
begin
  inherited;
  FPhase := -1;
  QuickStartButton.Content := Format(S('QuickStartFormat', 'Roast %d kg of %s'), [QuickKg, QuickCoffee]);
  Roast.Listen(RoastChanged);
end;

destructor TRoastPage.Destroy;
begin
  Roast.Unlisten(RoastChanged);
  inherited;
end;

procedure TRoastPage.NavigatedTo(const AArgs: TWinUINavigationArgs);
begin
  ShowNumbers;
  TWinUIMotion.Enter(TempTile, 40, 460, 20);
  TWinUIMotion.Enter(TimeTile, 100, 460, 20);
  TWinUIMotion.Enter(RorTile, 160, 460, 20);
  TWinUIMotion.Enter(DevTile, 220, 460, 20);
  TWinUIMotion.Enter(ChartCard, 280, 520, 26);
end;

procedure TRoastPage.RoastChanged(Sender: TObject);
begin
  ShowNumbers;
end;

procedure TRoastPage.ShowNumbers;
var
  Idle: Boolean;
begin
  Idle := Roast.Phase = TRoastPhase.Idle;
  EmptyState.Visibility := TWinUIVisibility(Ord(not Idle));
  Plot.Visibility := TWinUIVisibility(Ord(Idle));
  DropButton.IsEnabled := Roast.Running;
  if Idle then
  begin
    BatchText.Text := S('NoBatch', 'No batch in the roaster');
    TempText.Text := '-';
    TimeText.Text := '-';
    RorText.Text := '-';
    DevText.Text := '-';
  end
  else
  begin
    BatchText.Text := Format(S('BatchFormat', 'Batch #%d  -  %s, %.0f kg'), [Roast.BatchNo, Roast.Coffee, Roast.BatchKg]);
    TempText.Text := Format('%.0f'#$00B0'C', [Roast.BeanTemp]);
    TimeText.Text := FormatClock(Roast.Seconds);
    // Before the turning point the beans still cool down: roasters show no rate yet
    if Roast.Seconds <= 90 then
      RorText.Text := '-'
    else
      RorText.Text := Format('%.1f'#$00B0'/min', [Roast.RateOfRise]);
    DevText.Text := FormatClock(Roast.DevelopmentSeconds);
  end;
  ShowPhase;
  Draw;
end;

// The chip of the current phase is lit, the ones before it are done
procedure TRoastPage.ShowPhase;
var
  Chips, Lights: TArray<TWinUIFrameworkElement>;
  Phase, I: Integer;
begin
  Phase := Ord(Roast.Phase) - 1;
  if Phase = FPhase then
    Exit;
  FPhase := Phase;
  Chips := [DryingChip, MaillardChip, DevelopmentChip, DoneChip];
  Lights := [DryingLit, MaillardLit, DevelopmentLit, DoneLit];
  for I := 0 to High(Chips) do
  begin
    if I = Phase then
    begin
      Lights[I].Opacity := 1;
      TWinUIMotion.Pulse(Chips[I], 1.12);
    end
    else
      Lights[I].Opacity := 0;
    if I < Phase then
      Chips[I].Opacity := 0.5
    else
      Chips[I].Opacity := 1;
  end;
end;

procedure TRoastPage.Draw;
var
  W, H: Double;
  Times: TArray<Integer>;
  Temps: TArray<Double>;
  I: Integer;
  Points: IVector_Point;

  function X(ASeconds: Double): Double;
  begin
    Result := LeftPad + (W - LeftPad - RightPad) * ASeconds / MaxSeconds;
  end;

  function Y(ATemp: Double): Double;
  begin
    Result := TopPad + (H - TopPad - BottomPad) * (1 - (ATemp - MinTemp) / (MaxTemp - MinTemp));
  end;

  procedure Level(ALine: TWinUIPolyline; ALabel: TWinUITextBlock; ATemp: Double);
  var
    P: IVector_Point;
  begin
    P := ALine.Points;
    P.Clear;
    P.Append(Point(X(0), Y(ATemp)));
    P.Append(Point(X(MaxSeconds), Y(ATemp)));
    ALabel.Margin := At(X(0) + 6, Y(ATemp) - 18);
  end;

begin
  W := Plot.ActualWidth;
  H := Plot.ActualHeight;
  if (W < 20) or (H < 20) then
    Exit;
  Level(Grid100, Label100, 100);
  Level(Grid150, Label150, MaillardTemp);
  Level(Grid200, Label200, 200);
  Times := Roast.Times;
  Temps := Roast.Temps;
  Points := Curve.Points;
  Points.Clear;
  for I := 0 to High(Times) do
    Points.Append(Point(X(Times[I]), Y(Temps[I])));
  if Length(Times) > 0 then
  begin
    Dot.Visibility := TWinUIVisibility.Visible;
    Glow.Visibility := TWinUIVisibility.Visible;
    Dot.Margin := At(X(Times[High(Times)]) - 6, Y(Temps[High(Temps)]) - 6);
    Glow.Margin := At(X(Times[High(Times)]) - 13, Y(Temps[High(Temps)]) - 13);
  end
  else
  begin
    Dot.Visibility := TWinUIVisibility.Collapsed;
    Glow.Visibility := TWinUIVisibility.Collapsed;
  end;
  // First crack: a line where it happened
  Points := CrackLine.Points;
  Points.Clear;
  if Roast.FirstCrack > 0 then
  begin
    Points.Append(Point(X(Roast.FirstCrack), Y(MaxTemp)));
    Points.Append(Point(X(Roast.FirstCrack), Y(MinTemp)));
    CrackLabel.Margin := At(X(Roast.FirstCrack) + 6, Y(MaxTemp));
    CrackLabel.Visibility := TWinUIVisibility.Visible;
  end
  else
    CrackLabel.Visibility := TWinUIVisibility.Collapsed;
end;

procedure TRoastPage.PlotSizeChanged(Sender: TObject; E: TWinUISizeChangedEventArgs);
begin
  Draw;
end;

procedure TRoastPage.PopOutClick(Sender: TObject);
begin
  Ember.ShowMiniRoaster;
end;

procedure TRoastPage.QuickStartClick(Sender: TObject);
begin
  Roast.Start(QuickCoffee, QuickKg);
end;

procedure TRoastPage.DropConfirmed(Sender: TObject; const E: TWinValue);
begin
  Roast.Drop;
end;

end.
