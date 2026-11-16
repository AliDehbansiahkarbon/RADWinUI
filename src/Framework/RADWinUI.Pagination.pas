unit RADWinUI.Pagination;

{
  Ready-made page switchers, on the Tool Palette's Pagination category. In
  XAML they live in xmlns:rw="using:RADWinUI.Controls", like RADWinUI's
  other own controls.

  TWinUIClassicPager     rounded squares, a gradient square slides to the page
  TWinUIPillsPager       round pills with ... for the pages left out
  TWinUIDotsPager        dots, the current one stretches into a gradient bar
  TWinUIBorderedPager    joined cells, a gradient frame slides to the page
  TWinUITrackPager       numbers over a thin track, a gradient bar slides under the page
  TWinUISegmentedPager   a segmented control, a raised pill slides to the page
  TWinUIProgressPager    a progress bar with "3 / 5"
  TWinUIStepsPager       numbered circles on a line, the pages passed stay tinted

  They share TWinUIPager: PageCount, Page (from 1), ShowArrows, the accent
  colours and PageChanged. Left, Right, Home and End move between the pages.

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
  RADWinUI.DrawnControls;

const
  /// <summary>The Tool Palette category of the pagers.</summary>
  PaginationCategory = 'Pagination';

type
  /// <summary>One place in a pager: a page button, or an ellipsis (Page = 0).</summary>
  TWinUIPagerSlot = record
    Page: Integer;
    X, Y, Width, Height: Double;
  end;

  /// <summary>The base of the pagers: the pages, the arrows, the input and the moving indicator. Not registered itself.</summary>
  TWinUIPager = class(TWinUIDrawnControl)
  strict private
    FSettingPage: Boolean;
    FDownSlot: Integer;
    FTexts: TArray<string>;
    procedure ShowPage(APage: Integer);
    function SlotAt(AX, AY: Double): Integer;
  protected
    /// <summary>The places of the pages shown now.</summary>
    FSlots: TArray<TWinUIPagerSlot>;
    /// <summary>The arrows; zero width when there are none.</summary>
    FPrev, FNext: TWinUIPagerSlot;
    /// <summary>Where the indicator is, as a fractional slot index: the leading and the trailing edge.</summary>
    FShown, FShownSpeed, FTrail, FTrailSpeed: Double;
    /// <summary>The slot under the pointer, -2 the back arrow, -3 the forward arrow, -1 none.</summary>
    FHoverSlot: Integer;
    FPopAge: Double;
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultWidth: Double; override;
    class function DefaultHeight: Double; override;
    class function DefaultAccentFrom: TWinUIColor; override;
    class function DefaultAccentTo: TWinUIColor; override;
    class function DefaultPageCount: Integer; virtual;
    class function DefaultShowArrows: Boolean; virtual;
    /// <summary>The most places a style shows, ellipses included. 0: no page buttons (Progress).</summary>
    class function MaxSlots: Integer; virtual;
    /// <summary>The arrow glyphs.</summary>
    class function PrevGlyph: Char; virtual;
    class function NextGlyph: Char; virtual;
    procedure PropertyChanged(AIndex: Integer); override;
    function StyleXaml: string; override;
    /// <summary>XAML below everything: tracks, capsules, lines.</summary>
    function BackXaml: string; virtual;
    /// <summary>XAML of slot AIndex's own shape, below the indicator (named 'S' + index).</summary>
    function SlotXaml(AIndex: Integer): string; virtual;
    /// <summary>XAML of the indicator, between the slot shapes and the numbers.</summary>
    function IndicatorXaml: string; virtual;
    /// <summary>Whether the slots show their page number.</summary>
    function ShowsNumbers: Boolean; virtual;
    /// <summary>The size of one slot and the gap between two.</summary>
    procedure SlotMetrics(out AWidth, AHeight, AGap: Double); virtual;
    /// <summary>Puts the arrows and the slots in FPrev, FNext and FSlots for the current size and page.</summary>
    procedure ArrangeSlots; virtual;
    procedure LayoutControl; override;
    /// <summary>Gives slot AIndex its look: AWeight 1 is the current page, AHover 1 under the pointer.</summary>
    procedure LayoutSlot(AIndex: Integer; AWeight, AHover: Double); virtual;
    /// <summary>Places the indicator between the slots ALow and AHigh (fractional slot indexes).</summary>
    procedure LayoutIndicator(ALow, AHigh: Double); virtual;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
    function PointerDown(AX, AY: Double): Boolean; override;
    procedure PointerUp(AX, AY: Double; AInside: Boolean); override;
    procedure PointerHover(AX, AY: Double); override;
    function KeyPressed(AKey: TWinUIVirtualKey): Boolean; override;
    /// <summary>A click at AX, AY outside the slots and arrows: False ignores it.</summary>
    function ClickElsewhere(AX, AY: Double; ADown: Boolean): Boolean; virtual;
    { For the styles }
    /// <summary>The slot of the current page (its index in FSlots).</summary>
    function CurrentSlot: Integer;
    /// <summary>The left edge of a fractional slot index, between two slots.</summary>
    function SlotLeftAt(APosition: Double): Double;
    function SlotCenterAt(APosition: Double): Double;
    /// <summary>The page numbers to show, 0 for an ellipsis, at most ACount places.</summary>
    function VisiblePages(ACount: Integer): TArray<Integer>;
    { Accessibility: a list of pages, the current one selected }
    function AutomationRole: AutomationControlType; override;
    function AutomationPatterns: TWinUIAutomationPatterns; override;
    function AutomationItemCount: Integer; override;
    function AutomationItemName(AIndex: Integer): string; override;
    function AutomationItemSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean; override;
    function AutomationSelectedIndex: Integer; override;
    procedure AutomationSelect(AIndex: Integer); override;
  public
    procedure NextPage;
    procedure PreviousPage;
  published
    /// <summary>How many pages there are.</summary>
    property PageCount: Integer index 2 read GetInt32 write SetInt32;
    /// <summary>The current page, from 1 to PageCount.</summary>
    property Page: Integer index 3 read GetInt32 write SetInt32;
    /// <summary>The back and forward arrows at the ends.</summary>
    property ShowArrows: Boolean index 4 read GetBoolean write SetBoolean;
    property OnPageChanged: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

  /// <summary>Rounded squares, a gradient square slides and stretches to the page.</summary>
  TWinUIClassicPager = class(TWinUIPager)
  protected
    function SlotXaml(AIndex: Integer): string; override;
    function IndicatorXaml: string; override;
    procedure LayoutSlot(AIndex: Integer; AWeight, AHover: Double); override;
    procedure LayoutIndicator(ALow, AHigh: Double); override;
  end;

  /// <summary>Round pills with an ellipsis for the pages left out; a gradient pill slides to the page.</summary>
  TWinUIPillsPager = class(TWinUIPager)
  protected
    class function DefaultPageCount: Integer; override;
    function SlotXaml(AIndex: Integer): string; override;
    function IndicatorXaml: string; override;
    procedure SlotMetrics(out AWidth, AHeight, AGap: Double); override;
    procedure LayoutSlot(AIndex: Integer; AWeight, AHover: Double); override;
    procedure LayoutIndicator(ALow, AHigh: Double); override;
  end;

  /// <summary>Dots without numbers, the current one stretches into a gradient bar.</summary>
  TWinUIDotsPager = class(TWinUIPager)
  protected
    class function MaxSlots: Integer; override;
    class function PrevGlyph: Char; override;
    class function NextGlyph: Char; override;
    function SlotXaml(AIndex: Integer): string; override;
    function IndicatorXaml: string; override;
    function ShowsNumbers: Boolean; override;
    procedure SlotMetrics(out AWidth, AHeight, AGap: Double); override;
    procedure ArrangeSlots; override;
    procedure LayoutSlot(AIndex: Integer; AWeight, AHover: Double); override;
    procedure LayoutIndicator(ALow, AHigh: Double); override;
  end;

  /// <summary>Joined cells in one frame, a gradient frame slides to the page.</summary>
  TWinUIBorderedPager = class(TWinUIPager)
  protected
    class function PrevGlyph: Char; override;
    class function NextGlyph: Char; override;
    function BackXaml: string; override;
    function SlotXaml(AIndex: Integer): string; override;
    function IndicatorXaml: string; override;
    procedure SlotMetrics(out AWidth, AHeight, AGap: Double); override;
    procedure LayoutControl; override;
    procedure LayoutSlot(AIndex: Integer; AWeight, AHover: Double); override;
    procedure LayoutIndicator(ALow, AHigh: Double); override;
  end;

  /// <summary>Numbers over a thin track, a gradient bar slides under the page.</summary>
  TWinUITrackPager = class(TWinUIPager)
  protected
    function BackXaml: string; override;
    function IndicatorXaml: string; override;
    procedure SlotMetrics(out AWidth, AHeight, AGap: Double); override;
    procedure LayoutControl; override;
    procedure LayoutSlot(AIndex: Integer; AWeight, AHover: Double); override;
    procedure LayoutIndicator(ALow, AHigh: Double); override;
  end;

  /// <summary>A segmented control, a raised pill slides to the page.</summary>
  TWinUISegmentedPager = class(TWinUIPager)
  strict private
    FGlow: TDrawnGlow;
  protected
    function BackXaml: string; override;
    function IndicatorXaml: string; override;
    procedure SlotMetrics(out AWidth, AHeight, AGap: Double); override;
    procedure StyleLoaded; override;
    procedure StyleUnloading; override;
    procedure LayoutControl; override;
    procedure LayoutSlot(AIndex: Integer; AWeight, AHover: Double); override;
    procedure LayoutIndicator(ALow, AHigh: Double); override;
  public
    destructor Destroy; override;
  end;

  /// <summary>A progress bar with the page and the page count, like 3 / 5.</summary>
  TWinUIProgressPager = class(TWinUIPager)
  strict private
    FBarLeft, FBarWidth: Double;
    FCountSize: RADWinUI.Abi.Size;
  protected
    class function MaxSlots: Integer; override;
    function BackXaml: string; override;
    procedure ArrangeSlots; override;
    procedure LayoutControl; override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
    function ClickElsewhere(AX, AY: Double; ADown: Boolean): Boolean; override;
    function AutomationItemSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean; override;
  end;

  /// <summary>Numbered circles on a line: the pages passed stay tinted, the ones ahead are dashed.</summary>
  TWinUIStepsPager = class(TWinUIPager)
  protected
    class function DefaultShowArrows: Boolean; override;
    function BackXaml: string; override;
    function SlotXaml(AIndex: Integer): string; override;
    function IndicatorXaml: string; override;
    procedure SlotMetrics(out AWidth, AHeight, AGap: Double); override;
    procedure LayoutControl; override;
    procedure LayoutSlot(AIndex: Integer; AWeight, AHover: Double); override;
    procedure LayoutIndicator(ALow, AHigh: Double); override;
  end;

implementation

uses
  System.Math;

const
  PageCountIndex = DrawnOwnIndex;
  PageIndex = DrawnOwnIndex + 1;
  ShowArrowsIndex = DrawnOwnIndex + 2;
  PageChangedEvent = 0;
  ArrowWidth = 30;
  ArrowGap = 6;
  PrevSlot = -2;
  NextSlot = -3;

function Weight(APosition: Double; AIndex: Integer): Double;
begin
  Result := Max(0, 1 - Abs(APosition - AIndex));
end;

{ TWinUIPager }

class procedure TWinUIPager.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('PageCount', TWinUIPropertyKind.Int32, IntToStr(DefaultPageCount));
  AType.AddProperty('Page', TWinUIPropertyKind.Int32, '1');
  AType.AddProperty('ShowArrows', TWinUIPropertyKind.Boolean, BoolToStr(DefaultShowArrows, True));
  AType.AddEvent('PageChanged');
end;

class function TWinUIPager.DefaultWidth: Double;
begin
  Result := 340;
end;

class function TWinUIPager.DefaultHeight: Double;
begin
  Result := 44;
end;

class function TWinUIPager.DefaultAccentFrom: TWinUIColor;
begin
  Result := Rgb($7C, $4D, $FF);
end;

class function TWinUIPager.DefaultAccentTo: TWinUIColor;
begin
  Result := Rgb($E1, $4F, $B4);
end;

class function TWinUIPager.DefaultPageCount: Integer;
begin
  Result := 5;
end;

class function TWinUIPager.DefaultShowArrows: Boolean;
begin
  Result := True;
end;

class function TWinUIPager.MaxSlots: Integer;
begin
  Result := 7;
end;

class function TWinUIPager.PrevGlyph: Char;
begin
  Result := ChevronLeftGlyph;
end;

class function TWinUIPager.NextGlyph: Char;
begin
  Result := ChevronRightGlyph;
end;

procedure TWinUIPager.PropertyChanged(AIndex: Integer);
var
  Clamped: Integer;
begin
  inherited;
  case AIndex of
    PageCountIndex, PageIndex:
      begin
        if FSettingPage then
          Exit;
        Clamped := EnsureRange(Page, 1, Max(1, PageCount));
        if Clamped <> Page then
        begin
          FSettingPage := True;
          try
            Page := Clamped;
          finally
            FSettingPage := False;
          end;
        end;
        if AIndex = PageCountIndex then
          Rebuild
        else
        begin
          FPopAge := 0;
          if Built then
            LayoutControl;
          StartRendering;
          AutomationChanged(TWinUIAutomationPattern.Selection);
          Fire(PageChangedEvent);
        end;
      end;
    ShowArrowsIndex:
      Rebuild;
  end;
end;

function TWinUIPager.ShowsNumbers: Boolean;
begin
  Result := True;
end;

function TWinUIPager.BackXaml: string;
begin
  Result := '';
end;

function TWinUIPager.SlotXaml(AIndex: Integer): string;
begin
  Result := '';
end;

function TWinUIPager.IndicatorXaml: string;
begin
  Result := '';
end;

function TWinUIPager.StyleXaml: string;
var
  I: Integer;
  Arrow: string;
begin
  Result := BackXaml;
  for I := 0 to MaxSlots - 1 do
    Result := Result + SlotXaml(I);
  Result := Result + IndicatorXaml;
  if ShowsNumbers then
    for I := 0 to MaxSlots - 1 do
      Result := Result + CenteredTextXaml('T' + IntToStr(I), '', FontSize, 'SemiBold', MutedColor);
  Arrow := ColorHex(MutedColor);
  Result := Result +
    '<Grid x:Name="PrevBox"><Ellipse x:Name="PrevBack" Fill="' + ColorHex(SoftColor) + '" Opacity="0" />' +
    '<FontIcon x:Name="PrevGlyph" Glyph="' + GlyphXml(PrevGlyph) + '" FontSize="13" Foreground="' + Arrow +
    '" HorizontalAlignment="Center" VerticalAlignment="Center" /></Grid>' +
    '<Grid x:Name="NextBox"><Ellipse x:Name="NextBack" Fill="' + ColorHex(SoftColor) + '" Opacity="0" />' +
    '<FontIcon x:Name="NextGlyph" Glyph="' + GlyphXml(NextGlyph) + '" FontSize="13" Foreground="' + Arrow +
    '" HorizontalAlignment="Center" VerticalAlignment="Center" /></Grid>';
  SetLength(FTexts, MaxSlots);
  for I := 0 to High(FTexts) do
    FTexts[I] := '';
end;

procedure TWinUIPager.SlotMetrics(out AWidth, AHeight, AGap: Double);
begin
  AHeight := Max(16, Min(FHeight - 6, 38));
  AWidth := AHeight;
  AGap := 6;
end;

function TWinUIPager.VisiblePages(ACount: Integer): TArray<Integer>;
var
  Count, Current, I, First, Middle: Integer;
begin
  Count := Max(1, PageCount);
  Current := EnsureRange(Page, 1, Count);
  if (Count <= ACount) or (ACount < 5) then
  begin
    SetLength(Result, Min(Count, Max(1, ACount)));
    // Too few places for ellipses: a window that follows the page
    First := EnsureRange(Current - Length(Result) div 2, 1, Count - Length(Result) + 1);
    for I := 0 to High(Result) do
      Result[I] := First + I;
    Exit;
  end;
  // 1 ... window ... Count, the window around the current page
  Middle := ACount - 2;
  if Current <= Middle - 1 then
  begin
    SetLength(Result, ACount);
    for I := 0 to ACount - 3 do
      Result[I] := I + 1;
    Result[ACount - 2] := 0;
    Result[ACount - 1] := Count;
  end
  else if Current >= Count - Middle + 2 then
  begin
    SetLength(Result, ACount);
    Result[0] := 1;
    Result[1] := 0;
    for I := 2 to ACount - 1 do
      Result[I] := Count - (ACount - 1 - I);
  end
  else
  begin
    SetLength(Result, ACount);
    Result[0] := 1;
    Result[1] := 0;
    First := Current - (ACount - 4) div 2;
    for I := 2 to ACount - 3 do
      Result[I] := First + I - 2;
    Result[ACount - 2] := 0;
    Result[ACount - 1] := Count;
  end;
end;

procedure TWinUIPager.ArrangeSlots;
var
  Pages: TArray<Integer>;
  SlotW, SlotH, Gap, Total, Left, Top: Double;
  I: Integer;
  Arrows: Boolean;
begin
  Pages := VisiblePages(MaxSlots);
  SlotMetrics(SlotW, SlotH, Gap);
  Arrows := ShowArrows;
  Total := Length(Pages) * SlotW + Max(0, Length(Pages) - 1) * Gap;
  if Arrows then
    Total := Total + 2 * (ArrowWidth + ArrowGap);
  Left := Max(0, (FWidth - Total) / 2);
  Top := (FHeight - SlotH) / 2;
  FPrev := Default(TWinUIPagerSlot);
  FNext := Default(TWinUIPagerSlot);
  if Arrows then
  begin
    FPrev.X := Left;
    FPrev.Y := (FHeight - ArrowWidth) / 2;
    FPrev.Width := ArrowWidth;
    FPrev.Height := ArrowWidth;
    Left := Left + ArrowWidth + ArrowGap;
  end;
  SetLength(FSlots, Length(Pages));
  for I := 0 to High(Pages) do
  begin
    FSlots[I].Page := Pages[I];
    FSlots[I].X := Left + I * (SlotW + Gap);
    FSlots[I].Y := Top;
    FSlots[I].Width := SlotW;
    FSlots[I].Height := SlotH;
  end;
  if Arrows then
  begin
    FNext.X := Left + Length(Pages) * SlotW + Max(0, Length(Pages) - 1) * Gap + ArrowGap;
    FNext.Y := FPrev.Y;
    FNext.Width := ArrowWidth;
    FNext.Height := ArrowWidth;
  end;
end;

function TWinUIPager.CurrentSlot: Integer;
var
  I: Integer;
begin
  for I := 0 to High(FSlots) do
    if FSlots[I].Page = Page then
      Exit(I);
  Result := 0;
end;

function TWinUIPager.SlotLeftAt(APosition: Double): Double;
var
  Low: Integer;
begin
  if Length(FSlots) = 0 then
    Exit(0);
  APosition := EnsureRange(APosition, 0, High(FSlots));
  Low := Min(Floor(APosition), High(FSlots));
  if Low >= High(FSlots) then
    Result := FSlots[High(FSlots)].X
  else
    Result := Lerp(FSlots[Low].X, FSlots[Low + 1].X, APosition - Low);
end;

function TWinUIPager.SlotCenterAt(APosition: Double): Double;
begin
  if Length(FSlots) = 0 then
    Exit(FWidth / 2);
  Result := SlotLeftAt(APosition) + FSlots[0].Width / 2;
end;

procedure TWinUIPager.LayoutSlot(AIndex: Integer; AWeight, AHover: Double);
begin
end;

procedure TWinUIPager.LayoutIndicator(ALow, AHigh: Double);
begin
end;

procedure TWinUIPager.LayoutControl;
var
  I: Integer;
  Text: string;
  Box: IUIElement;
  Hover: Double;
  procedure Arrow(const APrefix: string; const ASlot: TWinUIPagerSlot; AEnabled: Boolean; AHovered: Boolean);
  var
    Element: IUIElement;
  begin
    Element := UIPart(APrefix + 'Box');
    if ASlot.Width <= 0 then
    begin
      SetOpacity(Element, 0);
      Exit;
    end;
    Resize(Element, ASlot.Width, ASlot.Height);
    Place(Element, ASlot.X, ASlot.Y);
    Resize(Part(APrefix + 'Back'), ASlot.Width, ASlot.Height);
    if AEnabled then
      SetOpacity(Element, 1)
    else
      SetOpacity(Element, 0.35);
    (Part(APrefix + 'Back') as IUIElement).Opacity := Ord(AEnabled and AHovered) * (0.6 + 0.4 * FPress);
  end;
begin
  ArrangeSlots;
  Arrow('Prev', FPrev, Page > 1, FHoverSlot = PrevSlot);
  Arrow('Next', FNext, Page < PageCount, FHoverSlot = NextSlot);
  for I := 0 to MaxSlots - 1 do
  begin
    if ShowsNumbers then
    begin
      Box := UIPart('T' + IntToStr(I) + 'Box');
      if I <= High(FSlots) then
      begin
        if FSlots[I].Page = 0 then
          Text := #$2026
        else
          Text := IntToStr(FSlots[I].Page);
        if Text <> FTexts[I] then
        begin
          FTexts[I] := Text;
          TextPart('T' + IntToStr(I), Text);
        end;
        Resize(Box, FSlots[I].Width, FSlots[I].Height);
        Place(Box, FSlots[I].X, FSlots[I].Y);
        SetOpacity(Box, 1);
      end
      else
        SetOpacity(Box, 0);
    end;
    if I <= High(FSlots) then
    begin
      Hover := Ord((FHoverSlot = I) and (FSlots[I].Page > 0));
      LayoutSlot(I, Weight(FShown, I), Hover);
    end
    else
      SetOpacity(UIPart('S' + IntToStr(I)), 0);
  end;
  if Length(FSlots) > 0 then
    LayoutIndicator(Min(FShown, FTrail), Max(FShown, FTrail));
end;

procedure TWinUIPager.Advance(ASeconds: Double);
var
  Target: Double;
begin
  inherited;
  Target := CurrentSlot;
  if Length(FSlots) = 0 then
  begin
    FShown := Target;
    FTrail := Target;
  end
  else
  begin
    // The front edge springs ahead, the back one follows: the indicator stretches as it moves
    SpringStep(FShown, FShownSpeed, Target, ASeconds, 320, 28);
    SpringStep(FTrail, FTrailSpeed, Target, ASeconds, 150, 22);
  end;
  FPopAge := FPopAge + ASeconds;
end;

function TWinUIPager.StillMoving: Boolean;
var
  Target: Double;
begin
  Target := CurrentSlot;
  Result := inherited or (Abs(FShown - Target) > 0.001) or (Abs(FTrail - Target) > 0.001) or
    (Abs(FShownSpeed) > 0.001) or (Abs(FTrailSpeed) > 0.001) or (FPopAge < 0.5);
end;

function TWinUIPager.SlotAt(AX, AY: Double): Integer;
var
  I: Integer;
  function Inside(const ASlot: TWinUIPagerSlot): Boolean;
  begin
    // A little slack around small targets like dots
    Result := (ASlot.Width > 0) and (AX >= ASlot.X - 4) and (AX <= ASlot.X + ASlot.Width + 4) and
      (AY >= Min(ASlot.Y, FHeight / 2 - 16)) and (AY <= Max(ASlot.Y + ASlot.Height, FHeight / 2 + 16));
  end;
begin
  if Inside(FPrev) then
    Exit(PrevSlot);
  if Inside(FNext) then
    Exit(NextSlot);
  for I := 0 to High(FSlots) do
    if Inside(FSlots[I]) then
      Exit(I);
  Result := -1;
end;

function TWinUIPager.ClickElsewhere(AX, AY: Double; ADown: Boolean): Boolean;
begin
  Result := False;
end;

function TWinUIPager.PointerDown(AX, AY: Double): Boolean;
begin
  FDownSlot := SlotAt(AX, AY);
  if FDownSlot = -1 then
    Exit(ClickElsewhere(AX, AY, True));
  Result := (FDownSlot < 0) or (FSlots[FDownSlot].Page > 0);
end;

procedure TWinUIPager.PointerUp(AX, AY: Double; AInside: Boolean);
var
  Slot: Integer;
begin
  if not AInside then
    Exit;
  Slot := SlotAt(AX, AY);
  if Slot <> FDownSlot then
    Exit;
  if Slot = -1 then
    ClickElsewhere(AX, AY, False)
  else if Slot = PrevSlot then
    PreviousPage
  else if Slot = NextSlot then
    NextPage
  else if FSlots[Slot].Page > 0 then
    ShowPage(FSlots[Slot].Page);
end;

procedure TWinUIPager.PointerHover(AX, AY: Double);
var
  Slot: Integer;
begin
  if (AX < 0) and (AY < 0) then
    Slot := -1
  else
    Slot := SlotAt(AX, AY);
  if Slot <> FHoverSlot then
  begin
    FHoverSlot := Slot;
    if Built then
      LayoutControl;
  end;
end;

function TWinUIPager.KeyPressed(AKey: TWinUIVirtualKey): Boolean;
begin
  Result := True;
  case AKey of
    TWinUIVirtualKey.Left, TWinUIVirtualKey.Up, TWinUIVirtualKey.PageUp:
      PreviousPage;
    TWinUIVirtualKey.Right, TWinUIVirtualKey.Down, TWinUIVirtualKey.PageDown:
      NextPage;
    TWinUIVirtualKey.Home:
      ShowPage(1);
    TWinUIVirtualKey.&End:
      ShowPage(PageCount);
  else
    Result := False;
  end;
end;

procedure TWinUIPager.ShowPage(APage: Integer);
begin
  APage := EnsureRange(APage, 1, Max(1, PageCount));
  if APage <> Page then
    Page := APage;
end;

procedure TWinUIPager.NextPage;
begin
  ShowPage(Page + 1);
end;

procedure TWinUIPager.PreviousPage;
begin
  ShowPage(Page - 1);
end;

function TWinUIPager.AutomationRole: AutomationControlType;
begin
  Result := AutomationControlType.Tab;
end;

function TWinUIPager.AutomationPatterns: TWinUIAutomationPatterns;
begin
  Result := [TWinUIAutomationPattern.Selection];
end;

function TWinUIPager.AutomationItemCount: Integer;
begin
  Result := Max(0, PageCount);
end;

function TWinUIPager.AutomationItemName(AIndex: Integer): string;
begin
  Result := 'Page ' + IntToStr(AIndex + 1);
end;

function TWinUIPager.AutomationItemSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(FSlots) do
    if FSlots[I].Page = AIndex + 1 then
    begin
      ALeft := FSlots[I].X;
      AWidth := FSlots[I].Width;
      Exit(True);
    end;
  ALeft := 0;
  AWidth := 0;
  Result := False;
end;

function TWinUIPager.AutomationSelectedIndex: Integer;
begin
  Result := Page - 1;
end;

procedure TWinUIPager.AutomationSelect(AIndex: Integer);
begin
  ShowPage(AIndex + 1);
end;

{ TWinUIClassicPager }

function TWinUIClassicPager.SlotXaml(AIndex: Integer): string;
begin
  Result := '<Rectangle x:Name="S' + IntToStr(AIndex) + '" RadiusX="9" RadiusY="9" Fill="' +
    ColorHex(SoftColor) + '" />';
end;

function TWinUIClassicPager.IndicatorXaml: string;
begin
  Result := '<Rectangle x:Name="Ind" RadiusX="9" RadiusY="9"><Rectangle.Fill>' +
    GradientXaml(AccentFromColor, AccentToColor, 0, 0, 1, 1) + '</Rectangle.Fill></Rectangle>';
end;

procedure TWinUIClassicPager.LayoutSlot(AIndex: Integer; AWeight, AHover: Double);
var
  Slot: TWinUIPagerSlot;
  Shape: IUIElement;
begin
  Slot := FSlots[AIndex];
  Shape := UIPart('S' + IntToStr(AIndex));
  Resize(Shape, Slot.Width, Slot.Height);
  Place(Shape, Slot.X, Slot.Y);
  SetOpacity(Shape, Ord(Slot.Page > 0));
  FillPart('S' + IntToStr(AIndex), MixColor(SoftColor, MixColor(SoftColor, AccentFromColor, 0.25), AHover));
  Tint('T' + IntToStr(AIndex), MixColor(MutedColor, Rgb($FF, $FF, $FF), AWeight));
end;

procedure TWinUIClassicPager.LayoutIndicator(ALow, AHigh: Double);
var
  Ind: IUIElement;
  Left, Right, Pop: Double;
begin
  Ind := UIPart('Ind');
  Left := SlotLeftAt(ALow);
  Right := SlotLeftAt(AHigh) + FSlots[0].Width;
  Resize(Ind, Right - Left, FSlots[0].Height);
  Place(Ind, Left, FSlots[0].Y);
  Pop := 1 + 0.08 * Sin(Pi * Clamp01(FPopAge / 0.3));
  ScaleAt(Ind, 1, Pop, (Right - Left) / 2, FSlots[0].Height / 2);
end;

{ TWinUIPillsPager }

class function TWinUIPillsPager.DefaultPageCount: Integer;
begin
  Result := 9;
end;

procedure TWinUIPillsPager.SlotMetrics(out AWidth, AHeight, AGap: Double);
begin
  AHeight := Max(16, Min(FHeight - 6, 34));
  AWidth := AHeight;
  AGap := 6;
end;

function TWinUIPillsPager.SlotXaml(AIndex: Integer): string;
begin
  Result := '<Ellipse x:Name="S' + IntToStr(AIndex) + '" Fill="' + ColorHex(SoftColor) + '" />';
end;

function TWinUIPillsPager.IndicatorXaml: string;
begin
  Result := '<Rectangle x:Name="Ind"><Rectangle.Fill>' + GradientXaml(AccentFromColor, AccentToColor, 0, 0, 1, 1) +
    '</Rectangle.Fill></Rectangle>';
end;

procedure TWinUIPillsPager.LayoutSlot(AIndex: Integer; AWeight, AHover: Double);
var
  Slot: TWinUIPagerSlot;
  Shape: IUIElement;
begin
  Slot := FSlots[AIndex];
  Shape := UIPart('S' + IntToStr(AIndex));
  Resize(Shape, Slot.Width, Slot.Height);
  Place(Shape, Slot.X, Slot.Y);
  // The ellipsis stands on its own, a page under the pointer takes a tint of the accent
  SetOpacity(Shape, Ord(Slot.Page > 0));
  FillPart('S' + IntToStr(AIndex), MixColor(SoftColor, WithAlpha(AccentToColor, 1), 0.28 * AHover));
  Tint('T' + IntToStr(AIndex), MixColor(MixColor(MutedColor, AccentToColor, 0.7 * AHover), Rgb($FF, $FF, $FF),
    AWeight));
end;

procedure TWinUIPillsPager.LayoutIndicator(ALow, AHigh: Double);
var
  Ind: IUIElement;
  Left, Right, H: Double;
begin
  Ind := UIPart('Ind');
  H := FSlots[0].Height;
  Left := SlotLeftAt(ALow);
  Right := SlotLeftAt(AHigh) + FSlots[0].Width;
  Resize(Ind, Right - Left, H);
  SetRadius(Ind, H / 2);
  Place(Ind, Left, FSlots[0].Y);
end;

{ TWinUIDotsPager }

class function TWinUIDotsPager.MaxSlots: Integer;
begin
  Result := 12;
end;

class function TWinUIDotsPager.PrevGlyph: Char;
begin
  Result := DoubleLeftGlyph;
end;

class function TWinUIDotsPager.NextGlyph: Char;
begin
  Result := DoubleRightGlyph;
end;

function TWinUIDotsPager.ShowsNumbers: Boolean;
begin
  Result := False;
end;

procedure TWinUIDotsPager.SlotMetrics(out AWidth, AHeight, AGap: Double);
begin
  AWidth := 10;
  AHeight := 10;
  AGap := 10;
end;

procedure TWinUIDotsPager.ArrangeSlots;
var
  I: Integer;
  Extra, Shift: Double;
begin
  inherited;
  // The current dot is a bar three dots wide: the dots after it make room
  Extra := 22;
  for I := 0 to High(FSlots) do
  begin
    Shift := Extra * Clamp01(FShown - I + 1) - Extra / 2;
    FSlots[I].X := FSlots[I].X + Shift;
  end;
  if FPrev.Width > 0 then
    FPrev.X := FPrev.X - Extra / 2;
  if FNext.Width > 0 then
    FNext.X := FNext.X + Extra / 2;
end;

function TWinUIDotsPager.SlotXaml(AIndex: Integer): string;
begin
  Result := '<Ellipse x:Name="S' + IntToStr(AIndex) + '" Fill="' + ColorHex(MixColor(SoftColor, MutedColor, 0.35)) + '" />';
end;

function TWinUIDotsPager.IndicatorXaml: string;
begin
  Result := '<Rectangle x:Name="Ind" RadiusX="5" RadiusY="5"><Rectangle.Fill>' +
    GradientXaml(AccentFromColor, AccentToColor, 0, 0, 1, 0) + '</Rectangle.Fill></Rectangle>';
end;

procedure TWinUIDotsPager.LayoutSlot(AIndex: Integer; AWeight, AHover: Double);
var
  Slot: TWinUIPagerSlot;
  Shape: IUIElement;
  Size: Double;
begin
  Slot := FSlots[AIndex];
  Shape := UIPart('S' + IntToStr(AIndex));
  Size := 10 + 2 * AHover;
  Resize(Shape, Size, Size);
  Place(Shape, Slot.X + (Slot.Width - Size) / 2, Slot.Y + (Slot.Height - Size) / 2);
  SetOpacity(Shape, 1 - AWeight);
  FillPart('S' + IntToStr(AIndex), MixColor(MixColor(SoftColor, MutedColor, 0.35),
    MixColor(AccentToColor, SurfaceColor, 0.45), AHover));
end;

procedure TWinUIDotsPager.LayoutIndicator(ALow, AHigh: Double);
var
  Ind: IUIElement;
  Left, Right: Double;
begin
  Ind := UIPart('Ind');
  Left := SlotLeftAt(ALow);
  Right := SlotLeftAt(AHigh) + FSlots[0].Width + 22 * Clamp01(1 - Abs(AHigh - ALow));
  Resize(Ind, Right - Left, 10);
  Place(Ind, Left, FSlots[0].Y);
end;

{ TWinUIBorderedPager }

class function TWinUIBorderedPager.PrevGlyph: Char;
begin
  Result := ArrowLeftGlyph;
end;

class function TWinUIBorderedPager.NextGlyph: Char;
begin
  Result := ArrowRightGlyph;
end;

procedure TWinUIBorderedPager.SlotMetrics(out AWidth, AHeight, AGap: Double);
begin
  AHeight := Max(16, Min(FHeight - 6, 38));
  AWidth := AHeight;
  AGap := 0;
end;

function TWinUIBorderedPager.BackXaml: string;
begin
  Result := '<Rectangle x:Name="Frame" RadiusX="8" RadiusY="8" StrokeThickness="1" Fill="' + ColorHex(SurfaceColor) +
    '" Stroke="' + ColorHex(LineColor) + '" />';
end;

function TWinUIBorderedPager.SlotXaml(AIndex: Integer): string;
begin
  // The line between this cell and the next
  Result := '<Rectangle x:Name="S' + IntToStr(AIndex) + '" Width="1" Fill="' + ColorHex(LineColor) + '" />';
end;

function TWinUIBorderedPager.IndicatorXaml: string;
begin
  Result := '<Rectangle x:Name="Ind" StrokeThickness="2" RadiusX="2" RadiusY="2"><Rectangle.Stroke>' +
    GradientXaml(AccentFromColor, AccentToColor, 0, 0, 1, 1) + '</Rectangle.Stroke></Rectangle>';
end;

procedure TWinUIBorderedPager.LayoutControl;
var
  Frame: IUIElement;
begin
  inherited;
  Frame := UIPart('Frame');
  if Length(FSlots) = 0 then
    Exit;
  Resize(Frame, FSlots[High(FSlots)].X + FSlots[0].Width - FSlots[0].X, FSlots[0].Height);
  Place(Frame, FSlots[0].X, FSlots[0].Y);
end;

procedure TWinUIBorderedPager.LayoutSlot(AIndex: Integer; AWeight, AHover: Double);
var
  Slot: TWinUIPagerSlot;
  Line: IUIElement;
begin
  Slot := FSlots[AIndex];
  Line := UIPart('S' + IntToStr(AIndex));
  Resize(Line, 1, Slot.Height);
  Place(Line, Slot.X + Slot.Width, Slot.Y);
  SetOpacity(Line, Ord(AIndex < High(FSlots)));
  Tint('T' + IntToStr(AIndex), MixColor(MixColor(MutedColor, TextColor, 0.6 * AHover), TextColor, AWeight));
end;

procedure TWinUIBorderedPager.LayoutIndicator(ALow, AHigh: Double);
var
  Ind: IUIElement;
  Left, Right: Double;
begin
  Ind := UIPart('Ind');
  Left := SlotLeftAt(ALow);
  Right := SlotLeftAt(AHigh) + FSlots[0].Width;
  Resize(Ind, Right - Left, FSlots[0].Height);
  Place(Ind, Left, FSlots[0].Y);
end;

{ TWinUITrackPager }

procedure TWinUITrackPager.SlotMetrics(out AWidth, AHeight, AGap: Double);
begin
  AHeight := Max(16, Min(FHeight - 14, 30));
  AWidth := 38;
  AGap := 6;
end;

function TWinUITrackPager.BackXaml: string;
begin
  Result := '<Rectangle x:Name="Track" Height="3" RadiusX="1.5" RadiusY="1.5" Fill="' + ColorHex(SoftColor) + '" />';
end;

function TWinUITrackPager.IndicatorXaml: string;
begin
  Result := '<Rectangle x:Name="Ind" Height="4" RadiusX="2" RadiusY="2"><Rectangle.Fill>' +
    GradientXaml(AccentFromColor, AccentToColor, 0, 0, 1, 0) + '</Rectangle.Fill></Rectangle>';
end;

procedure TWinUITrackPager.LayoutControl;
var
  Track: IUIElement;
begin
  inherited;
  Track := UIPart('Track');
  if Length(FSlots) = 0 then
    Exit;
  Resize(Track, FSlots[High(FSlots)].X + FSlots[0].Width - FSlots[0].X, 3);
  Place(Track, FSlots[0].X, FSlots[0].Y + FSlots[0].Height + 4);
end;

procedure TWinUITrackPager.LayoutSlot(AIndex: Integer; AWeight, AHover: Double);
begin
  Tint('T' + IntToStr(AIndex), MixColor(MixColor(MutedColor, TextColor, 0.5 * AHover), TextColor, AWeight));
  ScaleAt(UIPart('T' + IntToStr(AIndex) + 'Box'), 1 + 0.12 * AWeight, 1 + 0.12 * AWeight, FSlots[AIndex].Width / 2,
    FSlots[AIndex].Height / 2);
end;

procedure TWinUITrackPager.LayoutIndicator(ALow, AHigh: Double);
var
  Ind: IUIElement;
  Left, Right, Inset: Double;
begin
  Ind := UIPart('Ind');
  Inset := FSlots[0].Width * 0.18;
  Left := SlotLeftAt(ALow) + Inset;
  Right := SlotLeftAt(AHigh) + FSlots[0].Width - Inset;
  Resize(Ind, Right - Left, 4);
  Place(Ind, Left, FSlots[0].Y + FSlots[0].Height + 3.5);
end;

{ TWinUISegmentedPager }

destructor TWinUISegmentedPager.Destroy;
begin
  FreeAndNil(FGlow);
  inherited;
end;

procedure TWinUISegmentedPager.SlotMetrics(out AWidth, AHeight, AGap: Double);
begin
  AHeight := Max(16, Min(FHeight - 14, 30));
  AWidth := 38;
  AGap := 2;
end;

function TWinUISegmentedPager.BackXaml: string;
begin
  Result := '<Rectangle x:Name="Capsule" Fill="' + ColorHex(SoftColor) + '" Stroke="' + ColorHex(LineColor) +
    '" StrokeThickness="1" />';
end;

function TWinUISegmentedPager.IndicatorXaml: string;
begin
  Result := '<Canvas x:Name="Glow" /><Rectangle x:Name="Ind" Fill="' +
    ColorHex(ForSurface(MixColor(SurfaceColor, Rgb($FF, $FF, $FF), 0.16), Rgb($FF, $FF, $FF))) + '" />';
end;

procedure TWinUISegmentedPager.StyleLoaded;
begin
  FGlow := TDrawnGlow.Create(UIPart('Glow'), Part('Ind') as IShape, Rgb(0, 0, 0), 8, 0.18, 1);
end;

procedure TWinUISegmentedPager.StyleUnloading;
begin
  FreeAndNil(FGlow);
end;

procedure TWinUISegmentedPager.LayoutControl;
var
  Capsule: IUIElement;
  H: Double;
begin
  inherited;
  Capsule := UIPart('Capsule');
  if Length(FSlots) = 0 then
    Exit;
  H := FSlots[0].Height + 8;
  Resize(Capsule, FSlots[High(FSlots)].X + FSlots[0].Width - FSlots[0].X + 8, H);
  SetRadius(Capsule, H / 2);
  Place(Capsule, FSlots[0].X - 4, FSlots[0].Y - 4);
end;

procedure TWinUISegmentedPager.LayoutSlot(AIndex: Integer; AWeight, AHover: Double);
begin
  Tint('T' + IntToStr(AIndex), MixColor(MixColor(MutedColor, TextColor, 0.5 * AHover), AccentFromColor, AWeight));
end;

procedure TWinUISegmentedPager.LayoutIndicator(ALow, AHigh: Double);
var
  Ind: IUIElement;
  Left, Right, H: Double;
begin
  Ind := UIPart('Ind');
  H := FSlots[0].Height;
  Left := SlotLeftAt(ALow);
  Right := SlotLeftAt(AHigh) + FSlots[0].Width;
  Resize(Ind, Right - Left, H);
  SetRadius(Ind, H / 2);
  Place(Ind, Left, FSlots[0].Y);
  Place(UIPart('Glow'), Left, FSlots[0].Y);
  if FGlow <> nil then
    FGlow.Resize(Right - Left, H);
end;

{ TWinUIProgressPager }

class function TWinUIProgressPager.MaxSlots: Integer;
begin
  Result := 0;
end;

function TWinUIProgressPager.BackXaml: string;
begin
  Result := '<Rectangle x:Name="Track" Height="8" RadiusX="4" RadiusY="4" Fill="' + ColorHex(SoftColor) + '" />' +
    '<Rectangle x:Name="Fill" Height="8" RadiusX="4" RadiusY="4"><Rectangle.Fill>' +
    GradientXaml(AccentFromColor, AccentToColor, 0, 0, 1, 0) + '</Rectangle.Fill></Rectangle>' +
    '<StackPanel x:Name="Count" Orientation="Horizontal">' +
    '<TextBlock x:Name="CountPage" FontWeight="Bold" FontSize="' + Num(FontSize + 1) + '" Foreground="' +
    ColorHex(AccentFromColor) + '" />' +
    '<TextBlock x:Name="CountRest" FontSize="' + Num(FontSize + 1) + '" Foreground="' + ColorHex(MutedColor) + '" />' +
    '</StackPanel>';
end;

procedure TWinUIProgressPager.ArrangeSlots;
var
  Total, Left: Double;
  Room: Double;
begin
  SetLength(FSlots, 0);
  TextPart('CountPage', IntToStr(Page));
  TextPart('CountRest', ' / ' + IntToStr(Max(1, PageCount)));
  FCountSize := MeasurePart('Count');
  Room := Max(60, FCountSize.Width + 4);
  Total := Min(FWidth, 260);
  Left := Max(0, (FWidth - Total) / 2);
  FPrev := Default(TWinUIPagerSlot);
  FNext := Default(TWinUIPagerSlot);
  if ShowArrows then
  begin
    FPrev.X := Left;
    FPrev.Y := (FHeight - ArrowWidth) / 2;
    FPrev.Width := ArrowWidth;
    FPrev.Height := ArrowWidth;
    FNext := FPrev;
    FNext.X := Left + Total - ArrowWidth;
    FBarLeft := Left + ArrowWidth + ArrowGap + 4;
    FBarWidth := Max(20, Total - 2 * (ArrowWidth + ArrowGap + 4) - Room - 10);
  end
  else
  begin
    FBarLeft := Left;
    FBarWidth := Max(20, Total - Room - 10);
  end;
end;

procedure TWinUIProgressPager.LayoutControl;
var
  Element: IUIElement;
begin
  inherited;
  // FTrail follows the page here (there are no slots): the bar fills smoothly
  Element := UIPart('Track');
  Resize(Element, FBarWidth, 8);
  Place(Element, FBarLeft, FHeight / 2 - 4);
  Element := UIPart('Fill');
  Resize(Element, Max(8, FBarWidth * Clamp01(FTrail)), 8);
  Place(Element, FBarLeft, FHeight / 2 - 4);
  Place(UIPart('Count'), FBarLeft + FBarWidth + 12, (FHeight - FCountSize.Height) / 2);
end;

procedure TWinUIProgressPager.Advance(ASeconds: Double);
begin
  inherited;
  // The bar follows the page with a spring
  SpringStep(FTrail, FTrailSpeed, Clamp01(Page / Max(1, PageCount)), ASeconds, 150, 22);
end;

function TWinUIProgressPager.StillMoving: Boolean;
begin
  Result := (Abs(FPress - Ord(FPressed)) > 0.001) or (Abs(FHover - Ord(FHovered)) > 0.001) or
    (Abs(FTrail - Clamp01(Page / Max(1, PageCount))) > 0.001) or (Abs(FTrailSpeed) > 0.001);
end;

function TWinUIProgressPager.ClickElsewhere(AX, AY: Double; ADown: Boolean): Boolean;
var
  Fraction: Double;
begin
  // A click on the bar goes to the page there
  Result := (AX >= FBarLeft - 6) and (AX <= FBarLeft + FBarWidth + 6);
  if Result and not ADown then
  begin
    Fraction := Clamp01((AX - FBarLeft) / Max(1, FBarWidth));
    Page := EnsureRange(Ceil(Fraction * PageCount), 1, Max(1, PageCount));
  end;
end;

function TWinUIProgressPager.AutomationItemSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean;
begin
  AWidth := FBarWidth / Max(1, PageCount);
  ALeft := FBarLeft + AIndex * AWidth;
  Result := AWidth > 0;
end;

{ TWinUIStepsPager }

class function TWinUIStepsPager.DefaultShowArrows: Boolean;
begin
  Result := False;
end;

procedure TWinUIStepsPager.SlotMetrics(out AWidth, AHeight, AGap: Double);
begin
  AHeight := Max(16, Min(FHeight - 8, 32));
  AWidth := AHeight;
  AGap := 22;
end;

function TWinUIStepsPager.BackXaml: string;
var
  I: Integer;
begin
  Result := '';
  // The line from each step to the next: dashed ahead, solid once passed
  for I := 0 to MaxSlots - 2 do
    Result := Result + '<Line x:Name="D' + IntToStr(I) + '" StrokeThickness="2" StrokeDashArray="2,2" Stroke="' +
      ColorHex(MixColor(SoftColor, MutedColor, 0.5)) + '" />' +
      '<Line x:Name="L' + IntToStr(I) + '" StrokeThickness="2"><Line.Stroke>' +
      GradientXaml(AccentFromColor, AccentToColor, 0, 0, 1, 0) + '</Line.Stroke></Line>';
end;

function TWinUIStepsPager.SlotXaml(AIndex: Integer): string;
begin
  Result := '<Ellipse x:Name="S' + IntToStr(AIndex) + '" StrokeThickness="1.5" StrokeDashArray="2.5,2" />';
end;

function TWinUIStepsPager.IndicatorXaml: string;
begin
  Result := '<Ellipse x:Name="Ind"><Ellipse.Fill>' + GradientXaml(AccentFromColor, AccentToColor, 0, 0, 1, 1) +
    '</Ellipse.Fill></Ellipse>';
end;

procedure TWinUIStepsPager.LayoutControl;
var
  I: Integer;
  Dashed, Solid: IUIElement;
  Line: ILine;
  X1, X2, Y, Passed: Double;
begin
  inherited;
  for I := 0 to MaxSlots - 2 do
  begin
    Dashed := UIPart('D' + IntToStr(I));
    Solid := UIPart('L' + IntToStr(I));
    if I >= High(FSlots) then
    begin
      SetOpacity(Dashed, 0);
      SetOpacity(Solid, 0);
      Continue;
    end;
    X1 := FSlots[I].X + FSlots[I].Width + 3;
    X2 := FSlots[I + 1].X - 3;
    Y := FSlots[I].Y + FSlots[I].Height / 2;
    Line := Dashed as ILine;
    Line.X1 := X1;
    Line.X2 := X2;
    Line.Y1 := Y;
    Line.Y2 := Y;
    SetOpacity(Dashed, 1);
    // The solid line grows as the indicator passes this gap
    Passed := Clamp01(FTrail - I);
    Line := Solid as ILine;
    Line.X1 := X1;
    Line.X2 := X1 + (X2 - X1) * Passed;
    Line.Y1 := Y;
    Line.Y2 := Y;
    SetOpacity(Solid, Ord(Passed > 0.01));
  end;
end;

procedure TWinUIStepsPager.LayoutSlot(AIndex: Integer; AWeight, AHover: Double);
var
  Slot: TWinUIPagerSlot;
  Shape: IUIElement;
  Ellipse: IShape;
  Done: Boolean;
begin
  Slot := FSlots[AIndex];
  Shape := UIPart('S' + IntToStr(AIndex));
  Resize(Shape, Slot.Width, Slot.Height);
  Place(Shape, Slot.X, Slot.Y);
  Ellipse := Shape as IShape;
  Done := (Slot.Page > 0) and (Slot.Page < Page);
  if Done then
  begin
    // A page passed: a soft tint of the accent, no edge
    Ellipse.Fill := NewBrush(MixColor(SurfaceColor, AccentFromColor, 0.22));
    Ellipse.Stroke := nil;
    Tint('T' + IntToStr(AIndex), MixColor(AccentFromColor, Rgb($FF, $FF, $FF), AWeight));
  end
  else
  begin
    Ellipse.Fill := NewBrush(MixColor(SurfaceColor, AccentToColor, 0.12 * AHover));
    Ellipse.Stroke := NewBrush(MixColor(MixColor(SoftColor, MutedColor, 0.6), AccentToColor, AHover));
    Tint('T' + IntToStr(AIndex), MixColor(MutedColor, Rgb($FF, $FF, $FF), AWeight));
  end;
  SetOpacity(Shape, 1);
end;

procedure TWinUIStepsPager.LayoutIndicator(ALow, AHigh: Double);
var
  Ind: IUIElement;
  Size, Pop: Double;
begin
  Ind := UIPart('Ind');
  Size := FSlots[0].Height;
  Resize(Ind, Size, Size);
  Place(Ind, SlotLeftAt(FShown), FSlots[0].Y);
  Pop := 1 + 0.12 * Sin(Pi * Clamp01(FPopAge / 0.35));
  ScaleAt(Ind, Pop, Pop, Size / 2, Size / 2);
end;

initialization
  TWinUICustomControls.Register(TWinUIClassicPager, 'ClassicPager', PaginationCategory);
  TWinUICustomControls.Register(TWinUIPillsPager, 'PillsPager', PaginationCategory);
  TWinUICustomControls.Register(TWinUIDotsPager, 'DotsPager', PaginationCategory);
  TWinUICustomControls.Register(TWinUIBorderedPager, 'BorderedPager', PaginationCategory);
  TWinUICustomControls.Register(TWinUITrackPager, 'TrackPager', PaginationCategory);
  TWinUICustomControls.Register(TWinUISegmentedPager, 'SegmentedPager', PaginationCategory);
  TWinUICustomControls.Register(TWinUIProgressPager, 'ProgressPager', PaginationCategory);
  TWinUICustomControls.Register(TWinUIStepsPager, 'StepsPager', PaginationCategory);

end.
