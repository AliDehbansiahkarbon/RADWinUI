unit RADWinUI.ProgressSteps;

{
  Ready-made progress steppers, on the Tool Palette's Progress Steps
  category. In XAML they live in xmlns:rw="using:RADWinUI.Controls", like
  RADWinUI's other own controls.

  TWinUINumberedSteps     numbered circles: the line fills and each done step turns into a check
  TWinUISegmentBarSteps   a bar of one segment per step, "Step 2 of 4" and the percentage roll
  TWinUICheckoutSteps     icons along a dotted path light up in turn
  TWinUIOrderTrackingSteps  a small van drives along the line from stop to stop
  TWinUIBreadcrumbSteps   arrow-shaped breadcrumbs fill with a pointed wipe
  TWinUIRingSteps         a ring of one arc per step, the number in the centre rolls

  They share TWinUIProgressStepsControl: Items (Label:Icon, ...), Step (from
  1, the step the user is on), the accent colours, Next, Back and
  StepChanged. Done steps are the ones before Step; a Step past the last
  one shows every step done. A click on a step goes to it.

  Using this unit registers them.
}

interface

{$SCOPEDENUMS ON}

uses
  System.SysUtils,
  RADWinUI.Interop.Core,
  RADWinUI.Abi,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Forms,
  RADWinUI.CustomControls,
  RADWinUI.TabBarIcons,
  RADWinUI.DrawnControls;

const
  /// <summary>The Tool Palette category of the progress steppers.</summary>
  ProgressStepsCategory = 'Progress Steps';
  /// <summary>The steps a new stepper shows.</summary>
  DefaultStepItems = 'Cart:Cart, Address:Location, Payment:Card, Done:Check';

type
  TWinUIStepItem = record
    Text: string;
    Glyph: Char;
  end;

  /// <summary>The base of the steppers: the steps, the current one and its animation. Not registered itself.</summary>
  TWinUIProgressStepsControl = class(TWinUIDrawnControl)
  strict private
    FSettingStep: Boolean;
    FDownStep: Integer;
    function GetItemCount: Integer;
  protected
    FItems: TArray<TWinUIStepItem>;
    /// <summary>Where the progress is shown, as a fractional step index: 0 is the first step current, Count all done.</summary>
    FShown, FShownSpeed: Double;
    /// <summary>Seconds since Step last changed.</summary>
    FChangeAge: Double;
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultItems: string; virtual;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
    function PointerDown(AX, AY: Double): Boolean; override;
    procedure PointerUp(AX, AY: Double; AInside: Boolean); override;
    function KeyPressed(AKey: TWinUIVirtualKey): Boolean; override;
    /// <summary>The step under AX, AY, -1 for none.</summary>
    function StepAt(AX, AY: Double): Integer; virtual;
    /// <summary>The step's place, for clicks and screen readers.</summary>
    function StepSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean; virtual;
    procedure ParseItems;
    /// <summary>The target of FShown: the index of the current step, Count when all are done.</summary>
    function Target: Double;
    /// <summary>How done step AIndex looks right now, 0 .. 1.</summary>
    function DoneAmount(AIndex: Integer): Double;
    /// <summary>How current step AIndex looks right now, 0 .. 1.</summary>
    function CurrentAmount(AIndex: Integer): Double;
    function Count: Integer;
    { Accessibility: a list of steps, the current one selected }
    function AutomationRole: AutomationControlType; override;
    function AutomationPatterns: TWinUIAutomationPatterns; override;
    function AutomationItemCount: Integer; override;
    function AutomationItemName(AIndex: Integer): string; override;
    function AutomationItemSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean; override;
    function AutomationSelectedIndex: Integer; override;
    procedure AutomationSelect(AIndex: Integer); override;
  public
    /// <summary>Goes to the next step; past the last one every step is done.</summary>
    procedure Next;
    procedure Back;
    /// <summary>Every step is done.</summary>
    function IsComplete: Boolean;
    property ItemCount: Integer read GetItemCount;
  published
    /// <summary>The steps: Label:Icon separated by commas, like Cart:Cart, Payment:Card.</summary>
    property Items: string index 2 read GetText write SetText;
    /// <summary>The step the user is on, from 1. One more than the steps: all done.</summary>
    property Step: Integer index 3 read GetInt32 write SetInt32;
    property OnStepChanged: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

  /// <summary>Numbered circles: the line between them fills and each done step turns into a check.</summary>
  TWinUINumberedSteps = class(TWinUIProgressStepsControl)
  strict private
    function CircleSize: Double;
    function CenterX(AIndex: Integer): Double;
  protected
    class function DefaultHeight: Double; override;
    function StyleXaml: string; override;
    procedure LayoutControl; override;
    function StepAt(AX, AY: Double): Integer; override;
    function StepSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean; override;
  end;

  /// <summary>A bar of one segment per step; "Step 2 of 4" and the percentage roll as it fills.</summary>
  TWinUISegmentBarSteps = class(TWinUIProgressStepsControl)
  strict private
    FHeadSize: RADWinUI.Abi.Size;
    FShownText: string;
    procedure Roll(const APrefix: string; AValue: Double; ATop, ALeft, AHeight: Double);
  protected
    class function DefaultHeight: Double; override;
    function StyleXaml: string; override;
    procedure StyleLoaded; override;
    procedure LayoutControl; override;
    function StepAt(AX, AY: Double): Integer; override;
    function StepSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean; override;
  end;

  /// <summary>Rounded icon tiles along a dotted path: each lights up in turn and gets a check.</summary>
  TWinUICheckoutSteps = class(TWinUIProgressStepsControl)
  strict private
    function TileSize: Double;
    function CenterX(AIndex: Integer): Double;
  protected
    class function DefaultHeight: Double; override;
    class function DefaultAccentFrom: TWinUIColor; override;
    class function DefaultAccentTo: TWinUIColor; override;
    function StyleXaml: string; override;
    procedure LayoutControl; override;
    function StepAt(AX, AY: Double): Integer; override;
    function StepSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean; override;
  end;

  /// <summary>An order's stops on a line: a small van drives from one to the next.</summary>
  TWinUIOrderTrackingSteps = class(TWinUIProgressStepsControl)
  strict private
    FLastShown: Double;
    FSpeed: Double;
    function StopX(AIndex: Double): Double;
    function LineY: Double;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultItems: string; override;
    class function DefaultHeight: Double; override;
    procedure PropertyChanged(AIndex: Integer); override;
    function StyleXaml: string; override;
    procedure LayoutControl; override;
    procedure Advance(ASeconds: Double); override;
    function StepAt(AX, AY: Double): Integer; override;
    function StepSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean; override;
  published
    /// <summary>The heading, like Order #2048.</summary>
    property Title: string index 4 read GetText write SetText;
    /// <summary>The line under it, like Arrives Tue.</summary>
    property Subtitle: string index 5 read GetText write SetText;
  end;

  /// <summary>Arrow-shaped breadcrumbs that fill with a pointed wipe as the steps are done.</summary>
  TWinUIBreadcrumbSteps = class(TWinUIProgressStepsControl)
  strict private
    function CrumbWidth: Double;
    function CrumbPoints(AIndex: Integer; AFill: Double): TArray<RADWinUI.Abi.Point>;
  protected
    class function DefaultHeight: Double; override;
    function StyleXaml: string; override;
    procedure LayoutControl; override;
    function StepAt(AX, AY: Double): Integer; override;
    function StepSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean; override;
  end;

  /// <summary>A ring of one arc per step that fills arc by arc; the number in its centre rolls.</summary>
  TWinUIRingSteps = class(TWinUIProgressStepsControl)
  strict private
    FShownText: string;
    function RingSize: Double;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultWidth: Double; override;
    class function DefaultHeight: Double; override;
    procedure PropertyChanged(AIndex: Integer); override;
    function StyleXaml: string; override;
    procedure LayoutControl; override;
    function StepAt(AX, AY: Double): Integer; override;
  published
    /// <summary>The small heading beside the ring, like CHECKOUT.</summary>
    property Title: string index 4 read GetText write SetText;
    /// <summary>The line under the current step's name; empty shows "Step 2 of 4".</summary>
    property Subtitle: string index 5 read GetText write SetText;
  end;

implementation

uses
  System.Math;

const
  ItemsIndex = DrawnOwnIndex;
  StepIndex = DrawnOwnIndex + 1;
  TitleIndex = DrawnOwnIndex + 2;
  SubtitleIndex = DrawnOwnIndex + 3;
  StepChangedEvent = 0;

{ TWinUIProgressStepsControl }

class procedure TWinUIProgressStepsControl.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Items', TWinUIPropertyKind.Text, DefaultItems);
  AType.AddProperty('Step', TWinUIPropertyKind.Int32, '1');
  AType.SetEditor('Items', 'tabitems');
  AType.AddEvent('StepChanged');
end;

class function TWinUIProgressStepsControl.DefaultItems: string;
begin
  Result := DefaultStepItems;
end;

procedure TWinUIProgressStepsControl.Initialize;
begin
  inherited;
  ParseItems;
end;

procedure TWinUIProgressStepsControl.ParseItems;
var
  Texts: TArray<TTabBarItemText>;
  I: Integer;
  Filled: Char;
begin
  Texts := ParseTabBarItems(Items);
  SetLength(FItems, Length(Texts));
  for I := 0 to High(Texts) do
  begin
    FItems[I].Text := Texts[I].Text;
    if Trim(Texts[I].Icon) = '' then
      FItems[I].Glyph := #0
    else
      ResolveTabBarIcon(Texts[I].Icon, FItems[I].Glyph, Filled);
  end;
end;

function TWinUIProgressStepsControl.GetItemCount: Integer;
begin
  Result := Length(FItems);
end;

function TWinUIProgressStepsControl.Count: Integer;
begin
  Result := Length(FItems);
end;

procedure TWinUIProgressStepsControl.PropertyChanged(AIndex: Integer);
var
  Clamped: Integer;
begin
  inherited;
  case AIndex of
    ItemsIndex:
      begin
        ParseItems;
        FShown := Target;
        Rebuild;
      end;
    StepIndex:
      begin
        if FSettingStep then
          Exit;
        Clamped := EnsureRange(Step, 1, Count + 1);
        if Clamped <> Step then
        begin
          FSettingStep := True;
          try
            Step := Clamped;
          finally
            FSettingStep := False;
          end;
        end;
        FChangeAge := 0;
        StartRendering;
        AutomationChanged(TWinUIAutomationPattern.Selection);
        Fire(StepChangedEvent);
      end;
  end;
end;

function TWinUIProgressStepsControl.Target: Double;
begin
  Result := EnsureRange(Step, 1, Count + 1) - 1;
end;

function TWinUIProgressStepsControl.DoneAmount(AIndex: Integer): Double;
begin
  Result := Clamp01(FShown - AIndex);
end;

function TWinUIProgressStepsControl.CurrentAmount(AIndex: Integer): Double;
begin
  Result := Max(0, 1 - Abs(FShown - AIndex));
end;

procedure TWinUIProgressStepsControl.Advance(ASeconds: Double);
begin
  inherited;
  // Critically damped: the progress never runs past its step
  SpringStep(FShown, FShownSpeed, Target, ASeconds, 70, 2 * Sqrt(70));
  FChangeAge := FChangeAge + ASeconds;
end;

function TWinUIProgressStepsControl.StillMoving: Boolean;
begin
  Result := inherited or (Abs(FShown - Target) > 0.0005) or (Abs(FShownSpeed) > 0.001) or (FChangeAge < 0.8);
end;

function TWinUIProgressStepsControl.StepAt(AX, AY: Double): Integer;
var
  I: Integer;
  Left, Width: Double;
begin
  for I := 0 to Count - 1 do
    if StepSpan(I, Left, Width) and (AX >= Left) and (AX <= Left + Width) then
      Exit(I);
  Result := -1;
end;

function TWinUIProgressStepsControl.StepSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean;
begin
  AWidth := FWidth / Max(1, Count);
  ALeft := AIndex * AWidth;
  Result := Count > 0;
end;

function TWinUIProgressStepsControl.PointerDown(AX, AY: Double): Boolean;
begin
  FDownStep := StepAt(AX, AY);
  Result := FDownStep >= 0;
end;

procedure TWinUIProgressStepsControl.PointerUp(AX, AY: Double; AInside: Boolean);
begin
  if AInside and (StepAt(AX, AY) = FDownStep) and (FDownStep >= 0) then
    Step := FDownStep + 1;
end;

function TWinUIProgressStepsControl.KeyPressed(AKey: TWinUIVirtualKey): Boolean;
begin
  Result := True;
  case AKey of
    TWinUIVirtualKey.Left, TWinUIVirtualKey.Up:
      Back;
    TWinUIVirtualKey.Right, TWinUIVirtualKey.Down:
      Next;
    TWinUIVirtualKey.Home:
      Step := 1;
    TWinUIVirtualKey.&End:
      Step := Count;
  else
    Result := False;
  end;
end;

procedure TWinUIProgressStepsControl.Next;
begin
  if Step <= Count then
    Step := Step + 1;
end;

procedure TWinUIProgressStepsControl.Back;
begin
  if Step > 1 then
    Step := Step - 1;
end;

function TWinUIProgressStepsControl.IsComplete: Boolean;
begin
  Result := Step > Count;
end;

function TWinUIProgressStepsControl.AutomationRole: AutomationControlType;
begin
  Result := AutomationControlType.Tab;
end;

function TWinUIProgressStepsControl.AutomationPatterns: TWinUIAutomationPatterns;
begin
  Result := [TWinUIAutomationPattern.Selection];
end;

function TWinUIProgressStepsControl.AutomationItemCount: Integer;
begin
  Result := Count;
end;

function TWinUIProgressStepsControl.AutomationItemName(AIndex: Integer): string;
begin
  if (AIndex >= 0) and (AIndex < Count) then
  begin
    Result := FItems[AIndex].Text;
    if AIndex < Step - 1 then
      Result := Result + ', done';
  end
  else
    Result := '';
end;

function TWinUIProgressStepsControl.AutomationItemSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean;
begin
  Result := StepSpan(AIndex, ALeft, AWidth);
end;

function TWinUIProgressStepsControl.AutomationSelectedIndex: Integer;
begin
  Result := Min(Step, Count) - 1;
end;

procedure TWinUIProgressStepsControl.AutomationSelect(AIndex: Integer);
begin
  Step := AIndex + 1;
end;

{ TWinUINumberedSteps }

class function TWinUINumberedSteps.DefaultHeight: Double;
begin
  Result := 64;
end;

function TWinUINumberedSteps.CircleSize: Double;
begin
  Result := Max(18, Min(FHeight - 26, 30));
end;

function TWinUINumberedSteps.CenterX(AIndex: Integer): Double;
var
  Slot: Double;
begin
  Slot := FWidth / Max(1, Count);
  Result := Slot * (AIndex + 0.5);
end;

function TWinUINumberedSteps.StyleXaml: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Count - 2 do
    Result := Result + '<Rectangle x:Name="Track' + IntToStr(I) + '" Height="3" RadiusX="1.5" RadiusY="1.5" Fill="' +
      ColorHex(SoftColor) + '" />' +
      '<Rectangle x:Name="Line' + IntToStr(I) + '" Height="3" RadiusX="1.5" RadiusY="1.5"><Rectangle.Fill>' +
      GradientXaml(AccentFromColor, AccentToColor, 0, 0, 1, 0) + '</Rectangle.Fill></Rectangle>';
  for I := 0 to Count - 1 do
    Result := Result + '<Canvas x:Name="C' + IntToStr(I) + '">' +
      '<Ellipse x:Name="Ring' + IntToStr(I) + '" StrokeThickness="2" Fill="' + ColorHex(SoftColor) + '" Stroke="' +
      ColorHex(LineColor) + '" />' +
      '<Ellipse x:Name="Done' + IntToStr(I) + '"><Ellipse.Fill>' + GradientXaml(AccentFromColor, AccentToColor, 0, 0, 1, 1) +
      '</Ellipse.Fill></Ellipse>' +
      CenteredTextXaml('N' + IntToStr(I), IntToStr(I + 1), FontSize - 1, 'SemiBold', MutedColor) +
      '<Polyline x:Name="Check' + IntToStr(I) + '" Stroke="White" StrokeThickness="2.2" StrokeStartLineCap="Round" ' +
      'StrokeEndLineCap="Round" StrokeLineJoin="Round" /></Canvas>' +
      CenteredTextXaml('Label' + IntToStr(I), FItems[I].Text, FontSize - 2, 'Normal', MutedColor);
end;

procedure TWinUINumberedSteps.LayoutControl;
var
  I: Integer;
  Size, Top, X1, X2, Done, Current, Pop: Double;
  Element: IUIElement;
  Label_: RADWinUI.Abi.Size;
begin
  Size := CircleSize;
  Top := 2;
  for I := 0 to Count - 2 do
  begin
    X1 := CenterX(I) + Size / 2 + 4;
    X2 := CenterX(I + 1) - Size / 2 - 4;
    Element := UIPart('Track' + IntToStr(I));
    Resize(Element, X2 - X1, 3);
    Place(Element, X1, Top + Size / 2 - 1.5);
    Element := UIPart('Line' + IntToStr(I));
    Resize(Element, Max(0, (X2 - X1) * Clamp01(FShown - I)), 3);
    Place(Element, X1, Top + Size / 2 - 1.5);
    SetOpacity(Element, Ord(FShown - I > 0.005));
  end;
  for I := 0 to Count - 1 do
  begin
    Done := DoneAmount(I);
    Current := CurrentAmount(I) * (1 - Done);
    Element := UIPart('C' + IntToStr(I));
    Place(Element, CenterX(I) - Size / 2, Top);
    // A step pops as it is done
    Pop := 1 + 0.14 * Sin(Pi * Done);
    ScaleAt(Element, Pop, Pop, Size / 2, Size / 2);
    Resize(Part('Ring' + IntToStr(I)), Size, Size);
    StrokePart('Ring' + IntToStr(I), MixColor(LineColor, AccentFromColor, Current));
    Element := UIPart('Done' + IntToStr(I));
    Resize(Element, Size, Size);
    SetOpacity(Element, Done);
    Element := UIPart('N' + IntToStr(I) + 'Box');
    Resize(Element, Size, Size);
    SetOpacity(Element, 1 - Done);
    Tint('N' + IntToStr(I), MixColor(MutedColor, TextColor, Current));
    Element := UIPart('Check' + IntToStr(I));
    SetLinePoints(Element, CheckPoints(Size * 0.16, Size * 0.16, Size * 0.68, (Done - 0.3) / 0.7));
    SetOpacity(Element, Ord(Done > 0.3));
    Element := UIPart('Label' + IntToStr(I) + 'Box');
    Label_ := MeasurePart('Label' + IntToStr(I));
    Resize(Element, FWidth / Max(1, Count), Max(14, Label_.Height));
    Place(Element, CenterX(I) - FWidth / Max(1, Count) / 2, Top + Size + 8);
    Tint('Label' + IntToStr(I), MixColor(MutedColor, TextColor, Max(Current, Done)));
  end;
end;

function TWinUINumberedSteps.StepAt(AX, AY: Double): Integer;
begin
  if Count = 0 then
    Exit(-1);
  Result := EnsureRange(Floor(AX / (FWidth / Count)), 0, Count - 1);
end;

function TWinUINumberedSteps.StepSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean;
begin
  AWidth := CircleSize;
  ALeft := CenterX(AIndex) - AWidth / 2;
  Result := Count > 0;
end;

{ TWinUISegmentBarSteps }

class function TWinUISegmentBarSteps.DefaultHeight: Double;
begin
  Result := 64;
end;

function TWinUISegmentBarSteps.StyleXaml: string;
var
  I: Integer;
begin
  Result := '<TextBlock x:Name="Head" FontSize="' + Num(FontSize + 2) + '" FontWeight="Bold" Foreground="' +
    ColorHex(TextColor) + '" Text="Step 8" />' +
    '<Canvas x:Name="StepBox"><Canvas.Clip><RectangleGeometry x:Name="StepClip" /></Canvas.Clip>' +
    '<TextBlock x:Name="StepRoll0" FontSize="' + Num(FontSize + 2) + '" FontWeight="Bold" Foreground="' +
    ColorHex(TextColor) + '" /><TextBlock x:Name="StepRoll1" FontSize="' + Num(FontSize + 2) +
    '" FontWeight="Bold" Foreground="' + ColorHex(TextColor) + '" /></Canvas>' +
    '<TextBlock x:Name="Of" FontSize="' + Num(FontSize + 2) + '" FontWeight="Bold" Foreground="' + ColorHex(TextColor) +
    '" />' +
    '<TextBlock x:Name="Name" FontSize="' + Num(FontSize - 1) + '" Foreground="' + ColorHex(MutedColor) + '" />' +
    '<Canvas x:Name="PctBox"><Canvas.Clip><RectangleGeometry x:Name="PctClip" /></Canvas.Clip>' +
    '<TextBlock x:Name="PctRoll0" FontSize="' + Num(FontSize - 3) + '" Foreground="' + ColorHex(MutedColor) + '" />' +
    '<TextBlock x:Name="PctRoll1" FontSize="' + Num(FontSize - 3) + '" Foreground="' + ColorHex(MutedColor) + '" />' +
    '</Canvas>';
  for I := 0 to Count - 1 do
    Result := Result + '<Rectangle x:Name="Seg' + IntToStr(I) + '" Fill="' + ColorHex(SoftColor) + '" />' +
      '<Rectangle x:Name="Fill' + IntToStr(I) + '"><Rectangle.Fill>' +
      GradientXaml(MixColor(AccentFromColor, AccentToColor, I / Max(1, Count)),
        MixColor(AccentFromColor, AccentToColor, (I + 1) / Max(1, Count)), 0, 0, 1, 0) + '</Rectangle.Fill></Rectangle>';
end;

procedure TWinUISegmentBarSteps.StyleLoaded;
begin
  // The size of the bold line, for the rolling digits
  FHeadSize := MeasurePart('Head');
  FShownText := '';
end;

procedure TWinUISegmentBarSteps.Roll(const APrefix: string; AValue: Double; ATop, ALeft, AHeight: Double);
var
  Low: Integer;
  Frac: Double;
  First, Second: IUIElement;
begin
  Low := Floor(AValue + 0.0001);
  Frac := Clamp01(AValue - Low);
  TextPart(APrefix + '0', IntToStr(Low));
  TextPart(APrefix + '1', IntToStr(Low + 1));
  First := UIPart(APrefix + '0');
  Second := UIPart(APrefix + '1');
  Place(First, 0, -Frac * AHeight);
  Place(Second, 0, (1 - Frac) * AHeight);
  SetOpacity(Second, Ord(Frac > 0.001));
end;

procedure TWinUISegmentBarSteps.LayoutControl;
var
  I, Shown: Integer;
  Gap, SegW, Left, BarTop, Fill, LineH, Percent, Space: Double;
  Element: IUIElement;
  Clip: IRectangleGeometry;
  Box: RADWinUI.Abi.Rect;
  StepSize, NameSize, PctSize: RADWinUI.Abi.Size;
  Text: string;
begin
  if Count = 0 then
    Exit;
  LineH := Max(12, FHeadSize.Height);
  // "Step" then the rolling step number, then "of 4", a space apart (a text's own spaces at its ends are not measured)
  Shown := Min(Step, Count);
  Text := 'of ' + IntToStr(Count);
  if Text <> FShownText then
  begin
    FShownText := Text;
    TextPart('Head', 'Step');
    TextPart('Of', Text);
  end;
  Space := LineH * 0.24;
  StepSize := MeasurePart('Head');
  Place(UIPart('Head'), 0, 0);
  Roll('StepRoll', Min(FShown, Count - 1) + 1, 0, 0, LineH);
  Element := UIPart('StepBox');
  Place(Element, StepSize.Width + Space, 0);
  Resize(Element, LineH * 0.5 * Length(IntToStr(Count)) + 1, LineH);
  Clip := Part('StepClip') as IRectangleGeometry;
  Box.X := 0;
  Box.Y := 0;
  Box.Width := LineH * 0.5 * Length(IntToStr(Count)) + 1;
  Box.Height := LineH;
  Clip.Rect := Box;
  Place(UIPart('Of'), StepSize.Width + Space + Box.Width + Space, 0);
  // The current step's name on the right
  if Step > Count then
    TextPart('Name', FItems[Count - 1].Text)
  else
    TextPart('Name', FItems[Shown - 1].Text);
  NameSize := MeasurePart('Name');
  Place(UIPart('Name'), FWidth - NameSize.Width, (LineH - NameSize.Height) / 2);
  // The segments
  Gap := 6;
  BarTop := LineH + 10;
  SegW := (FWidth - Gap * (Count - 1)) / Count;
  for I := 0 to Count - 1 do
  begin
    Left := I * (SegW + Gap);
    Element := UIPart('Seg' + IntToStr(I));
    Resize(Element, SegW, 6);
    SetRadius(Element, 3);
    Place(Element, Left, BarTop);
    // A segment fills as its step is reached, the current one too
    Fill := Clamp01(FShown + 1 - I);
    Element := UIPart('Fill' + IntToStr(I));
    Resize(Element, Max(6, SegW * Fill), 6);
    SetRadius(Element, 3);
    Place(Element, Left, BarTop);
    SetOpacity(Element, Ord(Fill > 0.01));
  end;
  // The percentage rolls with the fill
  Percent := 100 * Clamp01((FShown + 1) / Count);
  PctSize := MeasurePart('PctRoll0');
  Roll('PctRoll', Percent, 0, 0, Max(10, PctSize.Height));
  Element := UIPart('PctBox');
  Place(Element, 0, BarTop + 12);
  Resize(Element, 140, Max(10, PctSize.Height));
  Clip := Part('PctClip') as IRectangleGeometry;
  Box.Width := 140;
  Box.Height := Max(10, PctSize.Height);
  Clip.Rect := Box;
  TextPart('PctRoll0', IntToStr(Floor(Percent + 0.0001)) + '% complete');
  TextPart('PctRoll1', IntToStr(Floor(Percent + 0.0001) + 1) + '% complete');
end;

function TWinUISegmentBarSteps.StepAt(AX, AY: Double): Integer;
begin
  if Count = 0 then
    Exit(-1);
  Result := EnsureRange(Floor(AX / (FWidth / Count)), 0, Count - 1);
end;

function TWinUISegmentBarSteps.StepSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean;
begin
  AWidth := FWidth / Max(1, Count);
  ALeft := AIndex * AWidth;
  Result := Count > 0;
end;

{ TWinUICheckoutSteps }

class function TWinUICheckoutSteps.DefaultHeight: Double;
begin
  Result := 72;
end;

class function TWinUICheckoutSteps.DefaultAccentFrom: TWinUIColor;
begin
  Result := Rgb($3D, $6B, $FF);
end;

class function TWinUICheckoutSteps.DefaultAccentTo: TWinUIColor;
begin
  Result := Rgb($4F, $C3, $FF);
end;

function TWinUICheckoutSteps.TileSize: Double;
begin
  Result := Max(24, Min(FHeight - 26, 42));
end;

function TWinUICheckoutSteps.CenterX(AIndex: Integer): Double;
var
  Slot: Double;
begin
  Slot := FWidth / Max(1, Count);
  Result := Slot * (AIndex + 0.5);
end;

const
  DotsPerGap = 5;

function TWinUICheckoutSteps.StyleXaml: string;
var
  I, D: Integer;
  Glyph: Char;
begin
  Result := '';
  for I := 0 to Count - 2 do
    for D := 0 to DotsPerGap - 1 do
      Result := Result + '<Ellipse x:Name="Dot' + IntToStr(I) + '_' + IntToStr(D) + '" Width="4" Height="4" />';
  for I := 0 to Count - 1 do
  begin
    Glyph := FItems[I].Glyph;
    if Glyph = #0 then
      Glyph := CheckGlyph;
    Result := Result + '<Grid x:Name="T' + IntToStr(I) + '">' +
      '<Rectangle x:Name="Tile' + IntToStr(I) + '" RadiusX="12" RadiusY="12" StrokeThickness="1.5" Fill="' +
      ColorHex(SoftColor) + '" Stroke="' + ColorHex(LineColor) + '" />' +
      '<Rectangle x:Name="Lit' + IntToStr(I) + '" RadiusX="12" RadiusY="12"><Rectangle.Fill>' +
      GradientXaml(AccentFromColor, MixColor(AccentFromColor, AccentToColor, 0.6), 0, 0, 1, 1) +
      '</Rectangle.Fill></Rectangle>' +
      '<FontIcon x:Name="G' + IntToStr(I) + '" Glyph="' + GlyphXml(Glyph) + '" FontSize="17" ' +
      'HorizontalAlignment="Center" VerticalAlignment="Center" /></Grid>' +
      // The check badge at the corner
      '<Canvas x:Name="Badge' + IntToStr(I) + '"><Ellipse x:Name="BadgeDisc' + IntToStr(I) + '" Width="15" Height="15" Fill="' +
      ColorHex(SuccessColor) + '" Stroke="' + ColorHex(SurfaceColor) + '" StrokeThickness="1.5" />' +
      '<Polyline x:Name="BadgeCheck' + IntToStr(I) + '" Stroke="White" StrokeThickness="1.6" StrokeStartLineCap="Round" ' +
      'StrokeEndLineCap="Round" StrokeLineJoin="Round" /></Canvas>' +
      CenteredTextXaml('Label' + IntToStr(I), FItems[I].Text, FontSize - 2, 'Normal', MutedColor);
  end;
end;

procedure TWinUICheckoutSteps.LayoutControl;
var
  I, D: Integer;
  Size, Top, X1, X2, Done, Current, Lit, Pop, At: Double;
  Element: IUIElement;
  LabelSize: RADWinUI.Abi.Size;
begin
  Size := TileSize;
  Top := 4;
  for I := 0 to Count - 2 do
  begin
    X1 := CenterX(I) + Size / 2 + 6;
    X2 := CenterX(I + 1) - Size / 2 - 6;
    for D := 0 to DotsPerGap - 1 do
    begin
      At := (D + 0.5) / DotsPerGap;
      Element := UIPart('Dot' + IntToStr(I) + '_' + IntToStr(D));
      Place(Element, X1 + (X2 - X1) * At - 2, Top + Size / 2 - 2);
      // The dots light up one by one as the progress passes them
      FillPart('Dot' + IntToStr(I) + '_' + IntToStr(D), MixColor(MixColor(SoftColor, MutedColor, 0.4), AccentToColor,
        Clamp01((FShown - I - At) * 6)));
    end;
  end;
  for I := 0 to Count - 1 do
  begin
    Done := DoneAmount(I);
    Current := CurrentAmount(I) * (1 - Done);
    Lit := Done;
    Element := UIPart('T' + IntToStr(I));
    Resize(Element, Size, Size);
    Place(Element, CenterX(I) - Size / 2, Top);
    Pop := 1 + 0.1 * Sin(Pi * Done);
    ScaleAt(Element, Pop, Pop, Size / 2, Size / 2);
    StrokePart('Tile' + IntToStr(I), MixColor(LineColor, AccentToColor, Current));
    SetOpacity(UIPart('Lit' + IntToStr(I)), Lit);
    Tint('G' + IntToStr(I), MixColor(MixColor(MutedColor, TextColor, Current), Rgb($FF, $FF, $FF), Lit));
    // The badge pops in once the step is done
    Element := UIPart('Badge' + IntToStr(I));
    Place(Element, CenterX(I) + Size / 2 - 10, Top - 5);
    SetOpacity(Element, Ord(Done > 0.5));
    ScaleAt(Element, EaseOutBack(Clamp01((Done - 0.5) * 2)), EaseOutBack(Clamp01((Done - 0.5) * 2)), 7.5, 7.5);
    SetLinePoints(Part('BadgeCheck' + IntToStr(I)), CheckPoints(1.5, 1.5, 12, 1));
    Element := UIPart('Label' + IntToStr(I) + 'Box');
    LabelSize := MeasurePart('Label' + IntToStr(I));
    Resize(Element, FWidth / Max(1, Count), Max(14, LabelSize.Height));
    Place(Element, CenterX(I) - FWidth / Max(1, Count) / 2, Top + Size + 9);
    Tint('Label' + IntToStr(I), MixColor(MutedColor, TextColor, Max(Current, Done)));
  end;
end;

function TWinUICheckoutSteps.StepAt(AX, AY: Double): Integer;
begin
  if Count = 0 then
    Exit(-1);
  Result := EnsureRange(Floor(AX / (FWidth / Count)), 0, Count - 1);
end;

function TWinUICheckoutSteps.StepSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean;
begin
  AWidth := TileSize;
  ALeft := CenterX(AIndex) - AWidth / 2;
  Result := Count > 0;
end;

{ TWinUIOrderTrackingSteps }

class procedure TWinUIOrderTrackingSteps.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Title', TWinUIPropertyKind.Text, 'Order #2048');
  AType.AddProperty('Subtitle', TWinUIPropertyKind.Text, 'Arrives Tue');
end;

class function TWinUIOrderTrackingSteps.DefaultItems: string;
begin
  Result := 'Ordered:Package, Packed:Package, Shipped:Package, Delivered:Home';
end;

class function TWinUIOrderTrackingSteps.DefaultHeight: Double;
begin
  Result := 116;
end;

procedure TWinUIOrderTrackingSteps.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    TitleIndex, SubtitleIndex:
      Rebuild;
  end;
end;

function TWinUIOrderTrackingSteps.LineY: Double;
begin
  Result := FHeight - 30;
end;

function TWinUIOrderTrackingSteps.StopX(AIndex: Double): Double;
var
  Inset: Double;
begin
  Inset := 18;
  if Count <= 1 then
    Exit(FWidth / 2);
  Result := Inset + (FWidth - 2 * Inset) * AIndex / (Count - 1);
end;

function TWinUIOrderTrackingSteps.StyleXaml: string;
var
  I: Integer;
  Body, Cab, Window: string;
begin
  Body := ColorHex(MixColor(AccentFromColor, AccentToColor, 0.35));
  Cab := ColorHex(MixColor(AccentFromColor, AccentToColor, 0.65));
  Window := ColorHex(ForSurface(Rgb($DC, $E6, $FF), Rgb($E8, $EE, $FF)));
  Result :=
    '<TextBlock x:Name="Title" Text="' + XmlText(Title) + '" FontSize="' + Num(FontSize) + '" FontWeight="Bold" Foreground="' +
    ColorHex(TextColor) + '" />' +
    '<TextBlock x:Name="Subtitle" Text="' + XmlText(Subtitle) + '" FontSize="' + Num(FontSize - 3) + '" Foreground="' +
    ColorHex(MutedColor) + '" />' +
    // The status badge: the current stop's name
    '<Grid x:Name="Badge"><Rectangle x:Name="BadgeBack" Fill="' + ColorHex(SoftColor) + '" />' +
    '<TextBlock x:Name="BadgeText" FontSize="' + Num(FontSize - 3) + '" FontWeight="SemiBold" Foreground="' +
    ColorHex(MutedColor) + '" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="10,3" /></Grid>' +
    '<Rectangle x:Name="Track" Height="3" RadiusX="1.5" RadiusY="1.5" Fill="' + ColorHex(SoftColor) + '" />' +
    '<Rectangle x:Name="Line" Height="3" RadiusX="1.5" RadiusY="1.5"><Rectangle.Fill>' +
    GradientXaml(AccentFromColor, AccentToColor, 0, 0, 1, 0) + '</Rectangle.Fill></Rectangle>';
  for I := 0 to Count - 1 do
    Result := Result + '<Ellipse x:Name="Stop' + IntToStr(I) + '" Width="11" Height="11" StrokeThickness="2.5" />' +
      CenteredTextXaml('Label' + IntToStr(I), FItems[I].Text, FontSize - 3, 'Normal', MutedColor);
  // The van, drawn: a box, a cab with a window, two wheels and speed lines behind it
  Result := Result +
    '<Canvas x:Name="Van">' +
    '<Line x:Name="Speed0" X1="0" Y1="9" X2="12" Y2="9" StrokeThickness="2" StrokeStartLineCap="Round" ' +
    'StrokeEndLineCap="Round" Stroke="' + ColorHex(MutedColor) + '" />' +
    '<Line x:Name="Speed1" X1="4" Y1="15" X2="14" Y2="15" StrokeThickness="2" StrokeStartLineCap="Round" ' +
    'StrokeEndLineCap="Round" Stroke="' + ColorHex(MutedColor) + '" />' +
    '<Line x:Name="Speed2" X1="2" Y1="21" X2="10" Y2="21" StrokeThickness="2" StrokeStartLineCap="Round" ' +
    'StrokeEndLineCap="Round" Stroke="' + ColorHex(MutedColor) + '" />' +
    '<Rectangle Canvas.Left="16" Canvas.Top="2" Width="24" Height="20" RadiusX="3" RadiusY="3" Fill="' + Body + '" />' +
    '<Path Canvas.Left="39" Canvas.Top="7" Fill="' + Cab + '" Data="M0,0 L8,0 L14,7 L14,15 L0,15 Z" />' +
    '<Path Canvas.Left="41" Canvas.Top="9" Fill="' + Window + '" Data="M0,0 L5.5,0 L9.5,5 L0,5 Z" />' +
    '<Ellipse Canvas.Left="20" Canvas.Top="18" Width="9" Height="9" Fill="' + ColorHex(TextColor) + '" Stroke="' +
    ColorHex(SurfaceColor) + '" StrokeThickness="2" />' +
    '<Ellipse Canvas.Left="40" Canvas.Top="18" Width="9" Height="9" Fill="' + ColorHex(TextColor) + '" Stroke="' +
    ColorHex(SurfaceColor) + '" StrokeThickness="2" />' +
    '</Canvas>';
end;

procedure TWinUIOrderTrackingSteps.Advance(ASeconds: Double);
begin
  FLastShown := FShown;
  inherited;
  if ASeconds > 0 then
    FSpeed := Ease(FSpeed, Abs(FShown - FLastShown) / ASeconds, ASeconds, 12);
end;

procedure TWinUIOrderTrackingSteps.LayoutControl;
var
  I, Current: Integer;
  Y, VanX, Moving, Bob: Double;
  Element: IUIElement;
  Stop: IShape;
  Size, BadgeSize: RADWinUI.Abi.Size;
  Name: string;
begin
  if Count = 0 then
    Exit;
  Y := LineY;
  Place(UIPart('Title'), 0, 0);
  Size := MeasurePart('Title');
  Place(UIPart('Subtitle'), 0, Size.Height + 2);
  // The badge: the stop reached, accent once delivered
  Current := Min(Step, Count) - 1;
  if Step > Count then
    Name := FItems[Count - 1].Text
  else
    Name := FItems[Current].Text;
  TextPart('BadgeText', Name);
  BadgeSize := MeasurePart('Badge');
  Element := UIPart('Badge');
  Place(Element, FWidth - BadgeSize.Width, 0);
  Resize(Part('BadgeBack'), BadgeSize.Width, BadgeSize.Height);
  SetRadius(Part('BadgeBack'), BadgeSize.Height / 2);
  FillPart('BadgeBack', MixColor(SoftColor, MixColor(SurfaceColor, SuccessColor, 0.22), Ord(Step >= Count)));
  Tint('BadgeText', MixColor(MutedColor, SuccessColor, Ord(Step >= Count)));
  Element := UIPart('Track');
  Resize(Element, StopX(Count - 1) - StopX(0), 3);
  Place(Element, StopX(0), Y - 1.5);
  // The van drives to the current stop (to the last one when all are done)
  VanX := StopX(Min(FShown, Count - 1));
  Element := UIPart('Line');
  Resize(Element, Max(0, VanX - StopX(0)), 3);
  Place(Element, StopX(0), Y - 1.5);
  for I := 0 to Count - 1 do
  begin
    Element := UIPart('Stop' + IntToStr(I));
    Stop := Element as IShape;
    Place(Element, StopX(I) - 5.5, Y - 5.5);
    if StopX(I) <= VanX + 1 then
    begin
      Stop.Fill := NewBrush(SurfaceColor);
      Stop.Stroke := NewBrush(MixColor(AccentFromColor, AccentToColor, I / Max(1, Count - 1)));
    end
    else
    begin
      Stop.Fill := NewBrush(SurfaceColor);
      Stop.Stroke := NewBrush(MixColor(SoftColor, MutedColor, 0.5));
    end;
    Element := UIPart('Label' + IntToStr(I) + 'Box');
    Size := MeasurePart('Label' + IntToStr(I));
    Resize(Element, 90, Max(12, Size.Height));
    Place(Element, EnsureRange(StopX(I) - 45, -12, FWidth - 78), Y + 11);
    Tint('Label' + IntToStr(I), MixColor(MutedColor, TextColor, Ord(StopX(I) <= VanX + 1)));
  end;
  // The van sits on the line, its front at the stop; while it drives it bobs and speed lines show
  Moving := Clamp01(FSpeed * 2.5);
  Bob := -1.2 * Abs(Sin(FClock * 22)) * Moving;
  Element := UIPart('Van');
  Place(Element, VanX - 52, Y - 34 + Bob);
  for I := 0 to 2 do
    SetOpacity(UIPart('Speed' + IntToStr(I)), Moving * (0.5 + 0.5 * Sin(FClock * 18 + I * 2)));
end;

function TWinUIOrderTrackingSteps.StepAt(AX, AY: Double): Integer;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if Abs(AX - StopX(I)) <= Max(14, (FWidth / Max(1, Count)) / 2) then
      Exit(I);
  Result := -1;
end;

function TWinUIOrderTrackingSteps.StepSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean;
begin
  AWidth := 28;
  ALeft := StopX(AIndex) - 14;
  Result := Count > 0;
end;

{ TWinUIBreadcrumbSteps }

class function TWinUIBreadcrumbSteps.DefaultHeight: Double;
begin
  Result := 36;
end;

function TWinUIBreadcrumbSteps.CrumbWidth: Double;
begin
  Result := (FWidth + 10 * (Count - 1)) / Max(1, Count);
end;

function TWinUIBreadcrumbSteps.CrumbPoints(AIndex: Integer; AFill: Double): TArray<RADWinUI.Abi.Point>;
var
  Left, Right, Tip, H, Notch, FillRight: Double;
begin
  // An arrow: a notch on its left (not on the first), a point on its right (not on the last)
  H := FHeight;
  Tip := Min(12, H * 0.38);
  Left := AIndex * (CrumbWidth - 10);
  Right := Left + CrumbWidth;
  if AIndex = 0 then
    Notch := 0
  else
    Notch := Tip;
  if AIndex = Count - 1 then
    Tip := 0;
  // The fill wipes in from the left with the same point
  FillRight := Left + (Right - Left + Tip) * Clamp01(AFill) - Tip;
  if AFill >= 1 then
    FillRight := Right - Tip;
  Result := [Pt(Left, 0), Pt(FillRight, 0), Pt(FillRight + Tip, H / 2), Pt(FillRight, H), Pt(Left, H),
    Pt(Left + Notch, H / 2)];
end;

function TWinUIBreadcrumbSteps.StyleXaml: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Count - 1 do
    Result := Result + '<Polygon x:Name="Back' + IntToStr(I) + '" Fill="' + ColorHex(SoftColor) + '" Stroke="' +
      ColorHex(LineColor) + '" StrokeThickness="1" />' +
      '<Polygon x:Name="Fill' + IntToStr(I) + '"><Polygon.Fill>' +
      GradientXaml(MixColor(AccentFromColor, AccentToColor, I / Max(1, Count)),
        MixColor(AccentFromColor, AccentToColor, (I + 1) / Max(1, Count)), 0, 0, 1, 0) + '</Polygon.Fill></Polygon>' +
      '<StackPanel x:Name="L' + IntToStr(I) + '" Orientation="Horizontal">' +
      '<FontIcon x:Name="Tick' + IntToStr(I) + '" Glyph="' + GlyphXml(CheckGlyph) + '" FontSize="' + Num(FontSize - 3) +
      '" Margin="0,0,5,0" VerticalAlignment="Center" />' +
      '<TextBlock x:Name="Text' + IntToStr(I) + '" Text="' + XmlText(FItems[I].Text) + '" FontSize="' +
      Num(FontSize - 2) + '" FontWeight="SemiBold" VerticalAlignment="Center" /></StackPanel>';
end;

procedure TWinUIBreadcrumbSteps.LayoutControl;
var
  I: Integer;
  Fill, Done, Left, Tip: Double;
  Element: IUIElement;
  Size: RADWinUI.Abi.Size;
  Color: TWinUIColor;
begin
  Tip := Min(12, FHeight * 0.38);
  for I := 0 to Count - 1 do
  begin
    Done := DoneAmount(I);
    // The current crumb is filled too: it is where the user is
    Fill := Clamp01(FShown + 1 - I);
    SetLinePoints(Part('Back' + IntToStr(I)), CrumbPoints(I, 1));
    Element := UIPart('Fill' + IntToStr(I));
    SetLinePoints(Element, CrumbPoints(I, Fill));
    SetOpacity(Element, Ord(Fill > 0.01) * (0.55 + 0.45 * Max(Done, Ord(Fill >= 1))));
    Color := MixColor(MutedColor, Rgb($FF, $FF, $FF), Clamp01(Fill * 1.5));
    Tint('Text' + IntToStr(I), Color);
    Tint('Tick' + IntToStr(I), Color);
    Element := UIPart('Tick' + IntToStr(I));
    SetOpacity(Element, Done);
    Element := UIPart('L' + IntToStr(I));
    Size := MeasurePart('L' + IntToStr(I));
    Left := I * (CrumbWidth - 10);
    if I > 0 then
      Left := Left + Tip / 2;
    Place(Element, Left + (CrumbWidth - Tip - Size.Width) / 2 + 2, (FHeight - Size.Height) / 2);
  end;
end;

function TWinUIBreadcrumbSteps.StepAt(AX, AY: Double): Integer;
begin
  if Count = 0 then
    Exit(-1);
  Result := EnsureRange(Floor(AX / Max(1, CrumbWidth - 10)), 0, Count - 1);
end;

function TWinUIBreadcrumbSteps.StepSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean;
begin
  AWidth := CrumbWidth;
  ALeft := AIndex * (CrumbWidth - 10);
  Result := Count > 0;
end;

{ TWinUIRingSteps }

class procedure TWinUIRingSteps.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Title', TWinUIPropertyKind.Text, 'CHECKOUT');
  AType.AddProperty('Subtitle', TWinUIPropertyKind.Text, '');
end;

class function TWinUIRingSteps.DefaultWidth: Double;
begin
  Result := 300;
end;

class function TWinUIRingSteps.DefaultHeight: Double;
begin
  Result := 120;
end;

procedure TWinUIRingSteps.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    TitleIndex, SubtitleIndex:
      Rebuild;
  end;
end;

function TWinUIRingSteps.RingSize: Double;
begin
  Result := Max(40, Min(FHeight, FWidth * 0.45));
end;

function TWinUIRingSteps.StyleXaml: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Count - 1 do
    Result := Result + '<Polyline x:Name="Arc' + IntToStr(I) + '" StrokeThickness="9" StrokeStartLineCap="Round" ' +
      'StrokeEndLineCap="Round" Stroke="' + ColorHex(SoftColor) + '" />' +
      '<Polyline x:Name="Fill' + IntToStr(I) + '" StrokeThickness="9" StrokeStartLineCap="Round" StrokeEndLineCap="Round" ' +
      'Stroke="' + ColorHex(MixColor(AccentFromColor, AccentToColor, I / Max(1, Count - 1))) + '" />';
  Result := Result +
    '<Canvas x:Name="NumBox"><Canvas.Clip><RectangleGeometry x:Name="NumClip" /></Canvas.Clip>' +
    CenteredTextXaml('Num0', '', FontSize * 2.2, 'Bold', TextColor) +
    CenteredTextXaml('Num1', '', FontSize * 2.2, 'Bold', TextColor) + '</Canvas>' +
    CenteredTextXaml('Of', '', FontSize - 4, 'Normal', MutedColor) +
    '<TextBlock x:Name="Title" Text="' + XmlText(UpperCase(Title)) + '" FontSize="' + Num(FontSize - 4) +
    '" FontWeight="SemiBold" CharacterSpacing="80" Foreground="' + ColorHex(MutedColor) + '" />' +
    '<TextBlock x:Name="Name" FontSize="' + Num(FontSize + 8) + '" FontWeight="Bold" Foreground="' +
    ColorHex(TextColor) + '" />' +
    '<TextBlock x:Name="Sub" FontSize="' + Num(FontSize - 3) + '" Foreground="' + ColorHex(MutedColor) + '" />';
  FShownText := '';
end;

procedure TWinUIRingSteps.LayoutControl;
var
  I, Low, Current: Integer;
  Size, CX, CY, Radius, Gap, Span, Fill, NumH, Frac, Right, Shown: Double;
  Element: IUIElement;
  Clip: IRectangleGeometry;
  Box: RADWinUI.Abi.Rect;
  TitleSize, NameSize, SubSize: RADWinUI.Abi.Size;
  Name, Sub: string;
begin
  if Count = 0 then
    Exit;
  Size := RingSize;
  CX := Size / 2;
  CY := FHeight / 2;
  Radius := Size / 2 - 6;
  // Each step an arc, with a gap between two
  Gap := 0.045;
  Span := 1 / Count;
  for I := 0 to Count - 1 do
  begin
    SetLinePoints(Part('Arc' + IntToStr(I)), ArcPoints(CX, CY, Radius, Span - Gap, I * Span + Gap / 2));
    Fill := Clamp01(FShown + 1 - I);
    Element := UIPart('Fill' + IntToStr(I));
    if Fill > 0.01 then
    begin
      SetLinePoints(Element, ArcPoints(CX, CY, Radius, (Span - Gap) * Fill, I * Span + Gap / 2));
      SetOpacity(Element, 1);
    end
    else
      SetOpacity(Element, 0);
  end;
  // The number in the centre rolls up as the steps go by
  Shown := Min(FShown, Count - 1) + 1;
  Low := Floor(Shown + 0.0001);
  Frac := Clamp01(Shown - Low);
  NumH := FontSize * 2.9;
  Element := UIPart('NumBox');
  Resize(Element, Size, NumH);
  Place(Element, 0, CY - NumH / 2 - 6);
  Clip := Part('NumClip') as IRectangleGeometry;
  Box.X := 0;
  Box.Y := 0;
  Box.Width := Size;
  Box.Height := NumH;
  Clip.Rect := Box;
  TextPart('Num0', IntToStr(Low));
  TextPart('Num1', IntToStr(Low + 1));
  Resize(UIPart('Num0Box'), Size, NumH);
  Resize(UIPart('Num1Box'), Size, NumH);
  Place(UIPart('Num0Box'), 0, -Frac * NumH);
  Place(UIPart('Num1Box'), 0, (1 - Frac) * NumH);
  SetOpacity(UIPart('Num1Box'), Ord(Frac > 0.001));
  TextPart('Of', 'of ' + IntToStr(Count));
  Element := UIPart('OfBox');
  Resize(Element, Size, 14);
  Place(Element, 0, CY + NumH / 2 - 8);
  // Beside the ring: the title, the current step's name and a line under it
  Current := Min(Step, Count) - 1;
  Name := FItems[Current].Text;
  if Subtitle <> '' then
    Sub := Subtitle
  else if Step > Count then
    Sub := 'All set'
  else
    Sub := 'Step ' + IntToStr(Step) + ' of ' + IntToStr(Count);
  if Name + '|' + Sub <> FShownText then
  begin
    FShownText := Name + '|' + Sub;
    TextPart('Name', Name);
    TextPart('Sub', Sub);
    FChangeAge := Min(FChangeAge, 0);
  end;
  TitleSize := MeasurePart('Title');
  NameSize := MeasurePart('Name');
  SubSize := MeasurePart('Sub');
  Right := Size + 22;
  Place(UIPart('Title'), Right, CY - (TitleSize.Height + NameSize.Height + SubSize.Height + 4) / 2);
  // The name slides up into place when it changes
  Element := UIPart('Name');
  Place(Element, Right, CY - (TitleSize.Height + NameSize.Height + SubSize.Height + 4) / 2 + TitleSize.Height + 2 +
    8 * (1 - EaseOutCubic(FChangeAge / 0.35)));
  Element.Opacity := Clamp01(FChangeAge / 0.25);
  Place(UIPart('Sub'), Right, CY - (TitleSize.Height + NameSize.Height + SubSize.Height + 4) / 2 + TitleSize.Height +
    NameSize.Height + 4);
end;

function TWinUIRingSteps.StepAt(AX, AY: Double): Integer;
var
  Size, Angle: Double;
begin
  // A click on the ring goes to the step of that arc
  Size := RingSize;
  if (Count = 0) or (Hypot(AX - Size / 2, AY - FHeight / 2) > Size / 2 + 4) then
    Exit(-1);
  Angle := ArcTan2(AY - FHeight / 2, AX - Size / 2) + Pi / 2;
  if Angle < 0 then
    Angle := Angle + 2 * Pi;
  Result := EnsureRange(Floor(Angle / (2 * Pi) * Count), 0, Count - 1);
end;

initialization
  TWinUICustomControls.Register(TWinUINumberedSteps, 'NumberedSteps', ProgressStepsCategory);
  TWinUICustomControls.Register(TWinUISegmentBarSteps, 'SegmentBarSteps', ProgressStepsCategory);
  TWinUICustomControls.Register(TWinUICheckoutSteps, 'CheckoutSteps', ProgressStepsCategory);
  TWinUICustomControls.Register(TWinUIOrderTrackingSteps, 'OrderTrackingSteps', ProgressStepsCategory);
  TWinUICustomControls.Register(TWinUIBreadcrumbSteps, 'BreadcrumbSteps', ProgressStepsCategory);
  TWinUICustomControls.Register(TWinUIRingSteps, 'RingSteps', ProgressStepsCategory);

end.
