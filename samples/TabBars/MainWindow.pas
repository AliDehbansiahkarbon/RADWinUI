unit MainWindow;

interface

uses
  System.SysUtils,
  RADWinUI.Forms,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.TabBars,
  MainWindow.Xaml;

type
  TMainWindow = class(TMainWindowBase)   // TMainWindowBase is generated from MainWindow.xaml
  private
    FBars: TArray<TWinUITabBar>;
    FTour: TWinUITimer;
    FTourStep: Integer;
    FReady: Boolean;
    function MakeBrush(AColor: Cardinal): TWinUISolidColorBrush;
    procedure SetAccent(AFrom, ATo: Cardinal);
    procedure TourTick(Sender: TObject);
    procedure UpdateGlass;
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    // Every bar's SelectionChanged="TabChanged"
    procedure TabChanged(Sender: TObject; const E: TWinValue);
    procedure VioletClick(Sender: TObject);
    procedure SunsetClick(Sender: TObject);
    procedure MintClick(Sender: TObject);
    procedure AuroraClick(Sender: TObject);
    procedure SpeedChanged(Sender: TObject; E: TWinUIRangeBaseValueChangedEventArgs);
    procedure LabelsToggled(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure TourToggled(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure TransparencyToggled(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure GlassChanged(Sender: TObject; E: TWinUIRangeBaseValueChangedEventArgs);
  end;

implementation

function StyleName(ABar: TObject): string;
begin
  if ABar is TWinUISlidingPillTabBar then
    Result := 'Sliding Pill'
  else if ABar is TWinUILiquidBulgeTabBar then
    Result := 'Liquid Bulge'
  else if ABar is TWinUIFloatingNotchTabBar then
    Result := 'Floating Notch'
  else if ABar is TWinUIIconFillTabBar then
    Result := 'Icon Fill'
  else if ABar is TWinUIExpandingLabelTabBar then
    Result := 'Expanding Label'
  else
    Result := 'Bubble Float';
end;

constructor TMainWindow.Create;
begin
  inherited;
  FBars := [PillBar, BulgeBar, NotchBar, FillBar, LabelBar, BubbleBar];
  // The tour taps the next tab of one bar after the other, so a wave runs across the page
  FTour := TWinUITimer.Create;
  FTour.Interval := 320;
  FTour.OnTimer := TourTick;
  FReady := True;
  UpdateGlass;
end;

destructor TMainWindow.Destroy;
begin
  FTour.Free;
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

procedure TMainWindow.SetAccent(AFrom, ATo: Cardinal);
var
  Bar: TWinUITabBar;
  FromBrush, ToBrush: TWinUISolidColorBrush;
begin
  FromBrush := MakeBrush(AFrom);
  ToBrush := MakeBrush(ATo);
  for Bar in FBars do
  begin
    Bar.AccentFrom := FromBrush;
    Bar.AccentTo := ToBrush;
  end;
  StatusDot.Fill := ToBrush;
end;

procedure TMainWindow.TabChanged(Sender: TObject; const E: TWinValue);
begin
  if FReady then
    StatusText.Text := Format('%s: %s', [StyleName(Sender), (Sender as TWinUITabBar).SelectedText]);
end;

procedure TMainWindow.VioletClick(Sender: TObject);
begin
  SetAccent($6C55FF, $3CC8FF);
end;

procedure TMainWindow.SunsetClick(Sender: TObject);
begin
  SetAccent($FF5F6D, $FFC371);
end;

procedure TMainWindow.MintClick(Sender: TObject);
begin
  SetAccent($11B98E, $7CF29A);
end;

procedure TMainWindow.AuroraClick(Sender: TObject);
begin
  SetAccent($A23CF5, $FF6CAB);
end;

procedure TMainWindow.SpeedChanged(Sender: TObject; E: TWinUIRangeBaseValueChangedEventArgs);
var
  Bar: TWinUITabBar;
begin
  if not FReady then
    Exit;
  for Bar in FBars do
    Bar.AnimationDuration := Round(E.NewValue);
  SpeedText.Text := Format('%d ms', [Round(E.NewValue)]);
end;

procedure TMainWindow.LabelsToggled(Sender: TObject; E: TWinUIRoutedEventArgs);
var
  Bar: TWinUITabBar;
begin
  if not FReady then
    Exit;
  // Floating Notch and Expanding Label always show their labels
  for Bar in FBars do
    Bar.ShowLabels := LabelsSwitch.IsOn or (Bar is TWinUIFloatingNotchTabBar) or (Bar is TWinUIExpandingLabelTabBar);
end;

procedure TMainWindow.TourToggled(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  if FReady then
    FTour.Enabled := TourSwitch.IsOn;
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

procedure TMainWindow.TourTick(Sender: TObject);
var
  Bar: TWinUITabBar;
begin
  Bar := FBars[FTourStep mod Length(FBars)];
  Inc(FTourStep);
  if Bar.ItemCount > 0 then
    Bar.SelectedIndex := (Bar.SelectedIndex + 1) mod Bar.ItemCount;
end;

end.
