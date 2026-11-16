unit MainWindow;

interface

uses
  System.SysUtils,
  RADWinUI.Forms,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.CustomControls,
  RADWinUI.DrawnControls,
  RADWinUI.TabBars,
  RADWinUI.ActionButtons,
  RADWinUI.TextFields,
  RADWinUI.SwipeActions,
  RADWinUI.Pagination,
  RADWinUI.ProgressSteps,
  MainWindow.Xaml;

type
  TMainWindow = class(TMainWindowBase)   // TMainWindowBase is generated from MainWindow.xaml
  private
    FDrawn: TArray<TWinUIDrawnControl>;
    FSteps: TArray<TWinUIProgressStepsControl>;
    FLists: TArray<TWinUISwipeList>;
    FBars: TArray<TWinUITabBar>;
    FButtons: TArray<TWinUIActionButton>;
    FRows: TArray<string>;
    FReady: Boolean;
    function MakeBrush(AColor: Cardinal): TWinUISolidColorBrush;
    procedure SetAllAccents(AFrom, ATo: TWinUIBrush);
    procedure Report(const AText: string);
    procedure UpdateGlass;
  public
    constructor Create; override;
  published
    procedure SectionChanged(Sender: TObject; const E: TWinValue);
    { Text fields }
    procedure OtpCompleted(Sender: TObject; const E: TWinValue);
    procedure CardCompleted(Sender: TObject; const E: TWinValue);
    procedure StrengthChanged(Sender: TObject; const E: TWinValue);
    procedure GrowSubmitted(Sender: TObject; const E: TWinValue);
    procedure TagsChanged(Sender: TObject; const E: TWinValue);
    procedure GhostAccepted(Sender: TObject; const E: TWinValue);
    { Swipe actions }
    procedure CardLiked(Sender: TObject; const E: TWinValue);
    procedure CardPassed(Sender: TObject; const E: TWinValue);
    procedure RowPinned(Sender: TObject; const E: TWinValue);
    procedure RowUnpinned(Sender: TObject; const E: TWinValue);
    procedure RowDeleted(Sender: TObject; const E: TWinValue);
    procedure RowSnoozed(Sender: TObject; const E: TWinValue);
    procedure RowRestored(Sender: TObject; const E: TWinValue);
    procedure RefillClick(Sender: TObject);
    { Pagination and progress steps }
    procedure PageChanged(Sender: TObject; const E: TWinValue);
    procedure StepChanged(Sender: TObject; const E: TWinValue);
    procedure BackClick(Sender: TObject);
    procedure NextClick(Sender: TObject);
    { Tab bars and action buttons }
    procedure TabChanged(Sender: TObject; const E: TWinValue);
    procedure ButtonDone(Sender: TObject; const E: TWinValue);
    { The settings at the top }
    procedure OriginalClick(Sender: TObject);
    procedure SunsetClick(Sender: TObject);
    procedure MintClick(Sender: TObject);
    procedure OceanClick(Sender: TObject);
    procedure TransparencyToggled(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure GlassChanged(Sender: TObject; E: TWinUIRangeBaseValueChangedEventArgs);
  end;

implementation

const
  // The code the OTP field takes as right
  RightCode = '2468';

constructor TMainWindow.Create;
var
  List: TWinUISwipeList;
begin
  inherited;
  FDrawn := [OtpField1, CardField1, StrengthField1, GrowField1, TagField1, GhostField1, CardStack1, PinList1, PeekList1,
    LiquidList1, SnoozeList1, UndoList1, ClassicPager1, PillsPager1, DotsPager1, BorderedPager1, TrackPager1,
    SegmentedPager1, ProgressPager1, StepsPager1, NumberedSteps1, SegmentBarSteps1, CheckoutSteps1,
    OrderTrackingSteps1, BreadcrumbSteps1, RingSteps1];
  FSteps := [NumberedSteps1, SegmentBarSteps1, CheckoutSteps1, OrderTrackingSteps1, BreadcrumbSteps1, RingSteps1];
  FLists := [PinList1, PeekList1, LiquidList1, SnoozeList1, UndoList1];
  FBars := [SectionBar, PillBar, BulgeBar, NotchBar, FillBar, LabelBar, BubbleBar];
  FButtons := [HoldButton1, SendButton1, ConfettiButton1, CopyButton1, ShineButton1, SlideButton1];
  // The rows each list starts with, for "Bring the rows back"
  for List in FLists do
    FRows := FRows + [List.Items];
  FReady := True;
  UpdateGlass;
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

procedure TMainWindow.SetAllAccents(AFrom, ATo: TWinUIBrush);
var
  Control: TWinUIDrawnControl;
  Bar: TWinUITabBar;
  Button: TWinUIActionButton;
begin
  // nil gives every control its own colours back
  for Control in FDrawn do
  begin
    Control.AccentFrom := AFrom;
    Control.AccentTo := ATo;
  end;
  for Bar in FBars do
  begin
    Bar.AccentFrom := AFrom;
    Bar.AccentTo := ATo;
  end;
  for Button in FButtons do
  begin
    Button.AccentFrom := AFrom;
    Button.AccentTo := ATo;
  end;
  if ATo <> nil then
    StatusDot.Fill := ATo
  else
    StatusDot.Fill := MakeBrush($E14FB4);
end;

procedure TMainWindow.Report(const AText: string);
begin
  if FReady then
    StatusText.Text := Format('%s  at %s', [AText, FormatDateTime('hh:nn:ss', Now)]);
end;

procedure TMainWindow.SectionChanged(Sender: TObject; const E: TWinValue);
begin
  Report('Section: ' + SectionBar.Item[SectionBar.SelectedIndex].Text);
end;

{ Text fields }

procedure TMainWindow.OtpCompleted(Sender: TObject; const E: TWinValue);
begin
  // A real app would ask its server; this one knows the code
  OtpField1.Verify(OtpField1.Text = RightCode);
  if OtpField1.IsVerified then
    Report('OTP Code: Completed, the code is right')
  else
    Report(Format('OTP Code: Completed, %s is not the code (try %s)', [OtpField1.Text, RightCode]));
end;

procedure TMainWindow.CardCompleted(Sender: TObject; const E: TWinValue);
begin
  Report(Format('Card Number: Completed, card ending %s, expires %s',
    [Copy(CardField1.Text.Replace(' ', ''), 13, 4), CardField1.Expiry]));
end;

procedure TMainWindow.StrengthChanged(Sender: TObject; const E: TWinValue);
const
  Words: array[0..4] of string = ('empty', 'weak', 'fair', 'good', 'strong');
begin
  Report('Strength Meter: the password is ' + Words[StrengthField1.Score]);
end;

procedure TMainWindow.GrowSubmitted(Sender: TObject; const E: TWinValue);
begin
  Report(Format('Auto Grow: Submitted, %d characters', [Length(GrowField1.Text)]));
  GrowField1.Text := '';
end;

procedure TMainWindow.TagsChanged(Sender: TObject; const E: TWinValue);
begin
  Report(Format('Tag Input: %d tags, %s', [TagField1.TagCount, TagField1.Tags]));
end;

procedure TMainWindow.GhostAccepted(Sender: TObject; const E: TWinValue);
begin
  Report('Ghost Complete: Accepted, ' + GhostField1.Text);
end;

{ Swipe actions }

procedure TMainWindow.CardLiked(Sender: TObject; const E: TWinValue);
begin
  Report('Card Swipe: Liked, next up ' + CardStack1.CurrentTitle);
end;

procedure TMainWindow.CardPassed(Sender: TObject; const E: TWinValue);
begin
  Report('Card Swipe: Passed, next up ' + CardStack1.CurrentTitle);
end;

procedure TMainWindow.RowPinned(Sender: TObject; const E: TWinValue);
begin
  Report('Swipe to Pin: Pinned ' + PinList1.ActionName);
end;

procedure TMainWindow.RowUnpinned(Sender: TObject; const E: TWinValue);
begin
  Report('Swipe to Pin: Unpinned ' + PinList1.ActionName);
end;

procedure TMainWindow.RowDeleted(Sender: TObject; const E: TWinValue);
begin
  Report(Format('%s: Deleted %s', [Sender.ClassName.Substring(Length('TWinUI')),
    (Sender as TWinUISwipeList).ActionName]));
end;

procedure TMainWindow.RowSnoozed(Sender: TObject; const E: TWinValue);
begin
  Report(Format('Snooze Clock: Snoozed %s until %s', [SnoozeList1.ActionName,
    SnoozeList1.SnoozeOf(SnoozeList1.ActionIndex)]));
end;

procedure TMainWindow.RowRestored(Sender: TObject; const E: TWinValue);
begin
  Report('Inline Undo: Restored ' + UndoList1.ActionName);
end;

procedure TMainWindow.RefillClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to High(FLists) do
    FLists[I].Items := FRows[I];
  Report('Swipe Actions: every list has its rows back');
end;

{ Pagination and progress steps }

procedure TMainWindow.PageChanged(Sender: TObject; const E: TWinValue);
var
  Pager: TWinUIPager;
begin
  Pager := Sender as TWinUIPager;
  Report(Format('%s: PageChanged, page %d of %d', [Pager.ClassName.Substring(Length('TWinUI')), Pager.Page,
    Pager.PageCount]));
end;

procedure TMainWindow.StepChanged(Sender: TObject; const E: TWinValue);
var
  Steps: TWinUIProgressStepsControl;
begin
  Steps := Sender as TWinUIProgressStepsControl;
  if Steps.IsComplete then
    Report(Steps.ClassName.Substring(Length('TWinUI')) + ': StepChanged, all done')
  else
    Report(Format('%s: StepChanged, step %d of %d', [Steps.ClassName.Substring(Length('TWinUI')), Steps.Step,
      Steps.ItemCount]));
end;

procedure TMainWindow.BackClick(Sender: TObject);
var
  Steps: TWinUIProgressStepsControl;
begin
  for Steps in FSteps do
    Steps.Back;
end;

procedure TMainWindow.NextClick(Sender: TObject);
var
  Steps: TWinUIProgressStepsControl;
begin
  // After the last step every control starts over
  for Steps in FSteps do
    if Steps.IsComplete then
      Steps.Step := 1
    else
      Steps.Next;
end;

{ Tab bars and action buttons }

procedure TMainWindow.TabChanged(Sender: TObject; const E: TWinValue);
var
  Bar: TWinUITabBar;
begin
  Bar := Sender as TWinUITabBar;
  Report(Format('%s: SelectionChanged, %s', [Bar.ClassName.Substring(Length('TWinUI')),
    Bar.Item[Bar.SelectedIndex].Text]));
end;

procedure TMainWindow.ButtonDone(Sender: TObject; const E: TWinValue);
begin
  Report(Sender.ClassName.Substring(Length('TWinUI')) + ': done');
end;

{ The settings at the top }

procedure TMainWindow.OriginalClick(Sender: TObject);
begin
  SetAllAccents(nil, nil);
end;

procedure TMainWindow.SunsetClick(Sender: TObject);
begin
  SetAllAccents(MakeBrush($FF5F6D), MakeBrush($FFB347));
end;

procedure TMainWindow.MintClick(Sender: TObject);
begin
  SetAllAccents(MakeBrush($11B98E), MakeBrush($5EDC8C));
end;

procedure TMainWindow.OceanClick(Sender: TObject);
begin
  SetAllAccents(MakeBrush($2B5CFF), MakeBrush($1FB8E8));
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
