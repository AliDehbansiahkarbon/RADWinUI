unit RADWinUI.SwipeActions;

{
  Ready-made swipe actions, on the Tool Palette's Swipe Actions category. In
  XAML they live in xmlns:rw="using:RADWinUI.Controls", like RADWinUI's
  other own controls.

  TWinUISwipeCardStack     drag the top card: it tilts, a LIKE or NOPE stamp fades in, the next rises
  TWinUIPinSwipeList       swipe a row right to pin it: the pin pops on and the row jumps to the top
  TWinUIPeekSwipeList      a row peeks left twice to hint at the delete action hiding behind it
  TWinUILiquidDeleteList   swipe left: a red goo blob stretches out, snaps off and pops away
  TWinUISnoozeSwipeList    swipe left to snooze: the clock spins as you drag, 1h, 3h, 6 PM
  TWinUIUndoSwipeList      a deleted row leaves an Undo strip; Undo slides the row back

  The lists share TWinUISwipeList: Items (rows like Leo Cruz|Sent the files|9:12,
  separated by semicolons), the accent colours and the row the last event is
  about (ActionIndex, ActionName). Drag with the mouse, a pen or a finger;
  with the keyboard, Up and Down choose a row and Left or Right swipes it.

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
  /// <summary>The Tool Palette category of the swipe actions.</summary>
  SwipeActionsCategory = 'Swipe Actions';
  /// <summary>The rows a new list shows.</summary>
  DefaultSwipeRows = 'Leo Cruz|Sent the files|9:12; Ava Stone|Lunch tomorrow?|8:30; Mia Park|See you at 7?|9:41';

type
  /// <summary>One row of a swipe list and its animation.</summary>
  TWinUISwipeRow = record
    Name, Subtitle, Time: string;
    /// <summary>How far the row is dragged or sprung: negative to the left.</summary>
    Offset, Speed: Double;
    /// <summary>Where the row sits (animated) and how much of its height it takes, 0 .. 1.</summary>
    ShownY, Presence: Double;
    Pinned: Boolean;
    PinAge: Double;
    Snooze: string;
    SnoozeAge: Double;
    /// <summary>The row is going away: it collapses, then it is removed.</summary>
    Removing: Boolean;
    /// <summary>Open on its action (Peek), or gone and waiting for Undo (Undo).</summary>
    Open: Boolean;
    StateAge: Double;
  end;

  /// <summary>The base of the swipe lists: the rows, the dragging and the springs. Not registered itself.</summary>
  TWinUISwipeList = class(TWinUIDrawnControl)
  strict private
    FDragRow: Integer;
    FDownX, FDownY, FDownOffset: Double;
    FDragged: Boolean;
    FFocusRow: Integer;
    FSettingItems: Boolean;
    procedure ParseRows;
    function RowAt(AY: Double): Integer;
  protected
    FRows: TArray<TWinUISwipeRow>;
    FActionIndex: Integer;
    FActionName: string;
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultWidth: Double; override;
    class function DefaultHeight: Double; override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    function StyleXaml: string; override;
    procedure LayoutControl; override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
    function PointerDown(AX, AY: Double): Boolean; override;
    procedure PointerDrag(AX, AY: Double); override;
    procedure PointerUp(AX, AY: Double; AInside: Boolean); override;
    function KeyPressed(AKey: TWinUIVirtualKey): Boolean; override;
    { The style }
    /// <summary>XAML behind row AIndex: what its swipe reveals.</summary>
    function BehindXaml(AIndex: Integer): string; virtual;
    /// <summary>XAML on top of row AIndex's card: badges.</summary>
    function BadgeXaml(AIndex: Integer): string; virtual;
    /// <summary>XAML above the rows, like a hint.</summary>
    function OverXaml: string; virtual;
    /// <summary>Where a row may be dragged: -1 left only, 1 right only.</summary>
    function SwipeDirection: Integer; virtual;
    /// <summary>How far a swipe must go to act.</summary>
    function Threshold: Double; virtual;
    /// <summary>Where a released row springs to when it does not act: 0, or open on its action.</summary>
    function RestOffset(AIndex: Integer): Double; virtual;
    /// <summary>The row was let go at AOffset: act or spring back.</summary>
    procedure Released(AIndex: Integer; AOffset: Double); virtual;
    /// <summary>A click on row AIndex without a drag, at AX, AY inside the row. True when it did something.</summary>
    function Tapped(AIndex: Integer; AX, AY: Double): Boolean; virtual;
    /// <summary>Places what belongs to row AIndex beside its card, at ATop.</summary>
    procedure LayoutRow(AIndex: Integer; ATop: Double); virtual;
    procedure AdvanceRow(AIndex: Integer; ASeconds: Double); virtual;
    function RowMoving(AIndex: Integer): Boolean; virtual;
    procedure LayoutOver; virtual;
    { For the styles }
    function RowHeight: Double;
    function RowGap: Double;
    /// <summary>The row's slot: where it sits once everything settles.</summary>
    function RowTarget(AIndex: Integer): Double;
    /// <summary>Starts removing row AIndex: it collapses and Fire(AEvent) follows once it is gone.</summary>
    procedure RemoveRow(AIndex: Integer);
    procedure SetAction(AIndex: Integer);
    procedure FireAction(AIndex, AEvent: Integer);
    /// <summary>Items written back from the rows, after one was removed or moved.</summary>
    procedure StoreItems;
    function RowCount: Integer;
    { Accessibility: a list; Invoke does the swipe of the focused row }
    function AutomationRole: AutomationControlType; override;
    function AutomationName: string; override;
  public
    /// <summary>The row the last event is about.</summary>
    property ActionIndex: Integer read FActionIndex;
    property ActionName: string read FActionName;
    /// <summary>Swipes row AIndex as far as its action goes, from code.</summary>
    procedure SwipeRow(AIndex: Integer); virtual;
    function RowName(AIndex: Integer): string;
  published
    /// <summary>The rows: Name|Line|Time, separated by semicolons.</summary>
    property Items: string index 2 read GetText write SetText;
  end;

  /// <summary>Swipe a row right to pin it: the pin pops on and the row jumps to the top.</summary>
  TWinUIPinSwipeList = class(TWinUISwipeList)
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultAccentFrom: TWinUIColor; override;
    class function DefaultAccentTo: TWinUIColor; override;
    function BehindXaml(AIndex: Integer): string; override;
    function BadgeXaml(AIndex: Integer): string; override;
    function SwipeDirection: Integer; override;
    procedure Released(AIndex: Integer; AOffset: Double); override;
    procedure LayoutRow(AIndex: Integer; ATop: Double); override;
  public
    procedure SwipeRow(AIndex: Integer); override;
  published
    property OnPinned: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
    property OnUnpinned: TWinUIWinValueEventHandler index 1 read GetHandler write SetHandler;
  end;

  /// <summary>A row peeks left twice to hint at the delete action behind it; swipe it open and tap Delete.</summary>
  TWinUIPeekSwipeList = class(TWinUISwipeList)
  strict private
    FHintAge: Double;
    FHinting: Boolean;
    function HintRow: Integer;
    function PeekOffset: Double;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    function BehindXaml(AIndex: Integer): string; override;
    function OverXaml: string; override;
    function SwipeDirection: Integer; override;
    function RestOffset(AIndex: Integer): Double; override;
    procedure Released(AIndex: Integer; AOffset: Double); override;
    function Tapped(AIndex: Integer; AX, AY: Double): Boolean; override;
    procedure LayoutRow(AIndex: Integer; ATop: Double); override;
    procedure LayoutOver; override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
  public
    /// <summary>Plays the peek now.</summary>
    procedure Hint;
    procedure SwipeRow(AIndex: Integer); override;
  published
    /// <summary>The row that peeks, from 0.</summary>
    property HintIndex: Integer index 3 read GetInt32 write SetInt32;
    /// <summary>Milliseconds between two peeks; 0 peeks once after loading.</summary>
    property HintInterval: Integer index 4 read GetInt32 write SetInt32;
    property HintText: string index 5 read GetText write SetText;
    property ActionText: string index 6 read GetText write SetText;
    property OnDeleted: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

  /// <summary>Swipe left: a red goo blob stretches out of the row, snaps off and pops away with the row.</summary>
  TWinUILiquidDeleteList = class(TWinUISwipeList)
  strict private type
    TDrop = record
      X, Y, VX, VY, Age: Double;
    end;
  strict private
    FDrops: TArray<TDrop>;
    FPopRow: Integer;
    FPopAge, FPopX, FPopY, FPopRadius: Double;
    function BlobRadius(AOffset: Double): Double;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    function BehindXaml(AIndex: Integer): string; override;
    function OverXaml: string; override;
    function SwipeDirection: Integer; override;
    function Threshold: Double; override;
    procedure Released(AIndex: Integer; AOffset: Double); override;
    procedure LayoutRow(AIndex: Integer; ATop: Double); override;
    procedure LayoutOver; override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
  public
    procedure SwipeRow(AIndex: Integer); override;
  published
    property OnDeleted: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

  /// <summary>Swipe left to snooze: the clock spins as you drag and the time steps 1h, 3h, 6 PM.</summary>
  TWinUISnoozeSwipeList = class(TWinUISwipeList)
  strict private
    function OptionAt(AOffset: Double): Integer;
    function Options: TArray<string>;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    function BehindXaml(AIndex: Integer): string; override;
    function BadgeXaml(AIndex: Integer): string; override;
    function SwipeDirection: Integer; override;
    function Threshold: Double; override;
    procedure Released(AIndex: Integer; AOffset: Double); override;
    procedure LayoutRow(AIndex: Integer; ATop: Double); override;
  public
    procedure SwipeRow(AIndex: Integer); override;
    /// <summary>The snooze time of row AIndex, '' when it is not snoozed.</summary>
    function SnoozeOf(AIndex: Integer): string;
  published
    /// <summary>The snooze times as the drag gets longer, separated by commas.</summary>
    property SnoozeOptions: string index 3 read GetText write SetText;
    property OnSnoozed: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

  /// <summary>Swipe a row away and an Undo strip stays for a moment; Undo slides the row back.</summary>
  TWinUIUndoSwipeList = class(TWinUISwipeList)
  strict private
    function UndoRect(AIndex: Integer; out ALeft, AWidth: Double): Boolean;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    function BehindXaml(AIndex: Integer): string; override;
    function SwipeDirection: Integer; override;
    procedure Released(AIndex: Integer; AOffset: Double); override;
    function Tapped(AIndex: Integer; AX, AY: Double): Boolean; override;
    procedure LayoutRow(AIndex: Integer; ATop: Double); override;
    procedure AdvanceRow(AIndex: Integer; ASeconds: Double); override;
    function RowMoving(AIndex: Integer): Boolean; override;
  public
    procedure SwipeRow(AIndex: Integer); override;
    /// <summary>Brings back the row that waits for Undo.</summary>
    procedure Undo(AIndex: Integer);
  published
    property UndoText: string index 3 read GetText write SetText;
    /// <summary>Milliseconds the Undo strip stays.</summary>
    property UndoDuration: Integer index 4 read GetInt32 write SetInt32;
    /// <summary>The row is gone for good: Undo was not used.</summary>
    property OnDeleted: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
    property OnRestored: TWinUIWinValueEventHandler index 1 read GetHandler write SetHandler;
  end;

  /// <summary>A stack of cards: drag the top one, it tilts and a LIKE or NOPE stamp fades in; the next one rises.</summary>
  TWinUISwipeCardStack = class(TWinUIDrawnControl)
  strict private type
    TCard = record
      Title, Subtitle: string;
      Glyph: Char;
    end;
  strict private
    FCards: TArray<TCard>;
    FTop: Integer;
    FDragX, FDragY, FSpeedX, FSpeedY: Double;
    FDownX, FDownY: Double;
    FDragging: Boolean;
    FFlying: Boolean;
    FFlyDirection: Integer;
    FFlyAge: Double;
    FRise, FRiseSpeed: Double;
    FButtonDown: Integer;
    FButtonPop: array[0..1] of Double;
    procedure ParseCards;
    procedure Fly(ADirection: Integer);
    procedure Settle;
    function CardRect(out ALeft, ATop, AWidth, AHeight: Double): Boolean;
    function ButtonAt(AX, AY: Double): Integer;
    function ButtonCenter(AIndex: Integer; out AX, AY: Double): Boolean;
    function CardAt(ADepth: Integer): Integer;
    function GetCurrentTitle: string;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultWidth: Double; override;
    class function DefaultHeight: Double; override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    function StyleXaml: string; override;
    procedure LayoutControl; override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
    function PointerDown(AX, AY: Double): Boolean; override;
    procedure PointerDrag(AX, AY: Double); override;
    procedure PointerUp(AX, AY: Double; AInside: Boolean); override;
    function KeyPressed(AKey: TWinUIVirtualKey): Boolean; override;
    function AutomationRole: AutomationControlType; override;
    function AutomationName: string; override;
  public
    /// <summary>Sends the top card right, as a like.</summary>
    procedure Like;
    /// <summary>Sends the top card left.</summary>
    procedure Pass;
    /// <summary>The index of the top card in Items.</summary>
    property CurrentIndex: Integer read FTop;
    property CurrentTitle: string read GetCurrentTitle;
  published
    /// <summary>The cards: Title|Line|Icon, separated by semicolons.</summary>
    property Items: string index 2 read GetText write SetText;
    /// <summary>After the last card the first comes again.</summary>
    property Loop: Boolean index 3 read GetBoolean write SetBoolean;
    property LikeText: string index 4 read GetText write SetText;
    property PassText: string index 5 read GetText write SetText;
    /// <summary>The round buttons beside the card.</summary>
    property ShowButtons: Boolean index 6 read GetBoolean write SetBoolean;
    property OnLiked: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
    property OnPassed: TWinUIWinValueEventHandler index 1 read GetHandler write SetHandler;
  end;

implementation

uses
  System.Math,
  System.StrUtils;

const
  ItemsIndex = DrawnOwnIndex;
  OwnIndex = DrawnOwnIndex + 1;
  DragSlop = 5;

{ TWinUISwipeList }

class procedure TWinUISwipeList.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Items', TWinUIPropertyKind.Text, DefaultSwipeRows);
end;

class function TWinUISwipeList.DefaultWidth: Double;
begin
  Result := 320;
end;

class function TWinUISwipeList.DefaultHeight: Double;
begin
  Result := 168;
end;

procedure TWinUISwipeList.Initialize;
begin
  inherited;
  FDragRow := -1;
  FFocusRow := 0;
  FActionIndex := -1;
  ParseRows;
end;

procedure TWinUISwipeList.ParseRows;
var
  Entry: string;
  Fields: TArray<string>;
  Row: TWinUISwipeRow;
begin
  FRows := nil;
  for Entry in SplitList(Items, ';') do
  begin
    Fields := Entry.Split(['|']);
    Row := Default(TWinUISwipeRow);
    Row.Name := Trim(Fields[0]);
    if Length(Fields) > 1 then
      Row.Subtitle := Trim(Fields[1]);
    if Length(Fields) > 2 then
      Row.Time := Trim(Fields[2]);
    Row.Presence := 1;
    Row.ShownY := -1;
    Row.PinAge := 1;
    Row.SnoozeAge := 1;
    FRows := FRows + [Row];
  end;
end;

procedure TWinUISwipeList.StoreItems;
var
  I: Integer;
  List: string;
begin
  List := '';
  for I := 0 to High(FRows) do
    if not FRows[I].Removing then
    begin
      if List <> '' then
        List := List + '; ';
      List := List + FRows[I].Name + '|' + FRows[I].Subtitle + '|' + FRows[I].Time;
    end;
  FSettingItems := True;
  try
    Items := List;
  finally
    FSettingItems := False;
  end;
end;

procedure TWinUISwipeList.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    ItemsIndex:
      if not FSettingItems then
      begin
        ParseRows;
        Rebuild;
      end;
  end;
end;

function TWinUISwipeList.RowCount: Integer;
begin
  Result := Length(FRows);
end;

function TWinUISwipeList.RowName(AIndex: Integer): string;
begin
  if (AIndex >= 0) and (AIndex <= High(FRows)) then
    Result := FRows[AIndex].Name
  else
    Result := '';
end;

function TWinUISwipeList.RowHeight: Double;
begin
  Result := Max(36, Round(FontSize * 3.4));
end;

function TWinUISwipeList.RowGap: Double;
begin
  Result := 6;
end;

function TWinUISwipeList.RowTarget(AIndex: Integer): Double;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to AIndex - 1 do
    Result := Result + (RowHeight + RowGap) * FRows[I].Presence;
end;

function TWinUISwipeList.BehindXaml(AIndex: Integer): string;
begin
  Result := '';
end;

function TWinUISwipeList.BadgeXaml(AIndex: Integer): string;
begin
  Result := '';
end;

function TWinUISwipeList.OverXaml: string;
begin
  Result := '';
end;

function TWinUISwipeList.StyleXaml: string;
var
  I: Integer;
  Card, Avatar: TWinUIColor;
  Id: string;
begin
  Result := '';
  Card := ForSurface(MixColor(SurfaceColor, Rgb($FF, $FF, $FF), 0.05), Rgb($FF, $FF, $FF));
  for I := 0 to High(FRows) do
  begin
    Id := IntToStr(I);
    Avatar := NameColor(FRows[I].Name);
    Result := Result + '<Canvas x:Name="Slot' + Id + '">' + BehindXaml(I) +
      '<Canvas x:Name="Row' + Id + '">' +
      '<Rectangle x:Name="Card' + Id + '" RadiusX="12" RadiusY="12" Fill="' + ColorHex(Card) + '" Stroke="' +
      ColorHex(LineColor) + '" StrokeThickness="1" />' +
      '<Grid x:Name="Avatar' + Id + '" Width="30" Height="30"><Ellipse><Ellipse.Fill>' +
      GradientXaml(MixColor(Avatar, Rgb($FF, $FF, $FF), 0.15), MixColor(Avatar, Rgb(0, 0, 0), 0.1), 0, 0, 1, 1) +
      '</Ellipse.Fill></Ellipse><TextBlock Text="' + XmlText(Initial(FRows[I].Name)) + '" FontSize="' +
      Num(FontSize - 1) + '" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center" ' +
      'VerticalAlignment="Center" /></Grid>' +
      '<TextBlock x:Name="Name' + Id + '" Text="' + XmlText(FRows[I].Name) + '" FontSize="' + Num(FontSize - 1) +
      '" FontWeight="SemiBold" Foreground="' + ColorHex(TextColor) + '" TextTrimming="CharacterEllipsis" />' +
      '<TextBlock x:Name="Sub' + Id + '" Text="' + XmlText(FRows[I].Subtitle) + '" FontSize="' + Num(FontSize - 3) +
      '" Foreground="' + ColorHex(MutedColor) + '" TextTrimming="CharacterEllipsis" />' +
      '<TextBlock x:Name="Time' + Id + '" Text="' + XmlText(FRows[I].Time) + '" FontSize="' + Num(FontSize - 4) +
      '" Foreground="' + ColorHex(MutedColor) + '" />' + BadgeXaml(I) + '</Canvas></Canvas>';
  end;
  Result := Result + OverXaml;
end;

procedure TWinUISwipeList.SetAction(AIndex: Integer);
begin
  FActionIndex := AIndex;
  FActionName := RowName(AIndex);
end;

procedure TWinUISwipeList.FireAction(AIndex, AEvent: Integer);
begin
  SetAction(AIndex);
  Fire(AEvent);
end;

procedure TWinUISwipeList.RemoveRow(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex > High(FRows)) then
    Exit;
  FRows[AIndex].Removing := True;
  FRows[AIndex].StateAge := 0;
  StartRendering;
end;

function TWinUISwipeList.SwipeDirection: Integer;
begin
  Result := -1;
end;

function TWinUISwipeList.Threshold: Double;
begin
  Result := 76;
end;

function TWinUISwipeList.RestOffset(AIndex: Integer): Double;
begin
  Result := 0;
end;

procedure TWinUISwipeList.Released(AIndex: Integer; AOffset: Double);
begin
end;

function TWinUISwipeList.Tapped(AIndex: Integer; AX, AY: Double): Boolean;
begin
  Result := False;
end;

procedure TWinUISwipeList.LayoutRow(AIndex: Integer; ATop: Double);
begin
end;

procedure TWinUISwipeList.LayoutOver;
begin
end;

procedure TWinUISwipeList.SwipeRow(AIndex: Integer);
begin
end;

procedure TWinUISwipeList.AdvanceRow(AIndex: Integer; ASeconds: Double);
begin
  if (AIndex = FDragRow) and FDragged then
    Exit;
  SpringStep(FRows[AIndex].Offset, FRows[AIndex].Speed, RestOffset(AIndex), ASeconds, 260, 24);
end;

function TWinUISwipeList.RowMoving(AIndex: Integer): Boolean;
begin
  Result := (Abs(FRows[AIndex].Offset - RestOffset(AIndex)) > 0.05) or (Abs(FRows[AIndex].Speed) > 0.05);
end;

procedure TWinUISwipeList.Advance(ASeconds: Double);
var
  I: Integer;
  Removed: Boolean;
  Kept: TArray<TWinUISwipeRow>;
begin
  inherited;
  Removed := False;
  for I := 0 to High(FRows) do
  begin
    AdvanceRow(I, ASeconds);
    FRows[I].PinAge := FRows[I].PinAge + ASeconds;
    FRows[I].SnoozeAge := FRows[I].SnoozeAge + ASeconds;
    FRows[I].StateAge := FRows[I].StateAge + ASeconds;
    if FRows[I].Removing then
    begin
      FRows[I].Presence := Max(0, FRows[I].Presence - ASeconds / 0.25);
      if FRows[I].Presence <= 0 then
        Removed := True;
    end;
  end;
  // The rows move to their slots with a little spring
  for I := 0 to High(FRows) do
    if FRows[I].ShownY < 0 then
      FRows[I].ShownY := RowTarget(I)
    else
      FRows[I].ShownY := Ease(FRows[I].ShownY, RowTarget(I), ASeconds, 14);
  if Removed then
  begin
    Kept := nil;
    for I := 0 to High(FRows) do
      if not (FRows[I].Removing and (FRows[I].Presence <= 0)) then
        Kept := Kept + [FRows[I]];
    FRows := Kept;
    FDragRow := -1;
    FFocusRow := EnsureRange(FFocusRow, 0, Max(0, High(FRows)));
    StoreItems;
    Rebuild;
  end;
end;

function TWinUISwipeList.StillMoving: Boolean;
var
  I: Integer;
begin
  Result := inherited;
  if Result then
    Exit;
  for I := 0 to High(FRows) do
    if RowMoving(I) or FRows[I].Removing or (Abs(FRows[I].ShownY - RowTarget(I)) > 0.1) or (FRows[I].PinAge < 0.6) or
      (FRows[I].SnoozeAge < 0.6) then
      Exit(True);
end;

procedure TWinUISwipeList.LayoutControl;
var
  I: Integer;
  Top, H, NameH: Double;
  Slot, Row: IUIElement;
  Id: string;
  Size: RADWinUI.Abi.Size;
begin
  H := RowHeight;
  for I := 0 to High(FRows) do
  begin
    Id := IntToStr(I);
    Top := FRows[I].ShownY;
    if Top < 0 then
      Top := RowTarget(I);
    Slot := UIPart('Slot' + Id);
    Place(Slot, 0, Top);
    // A removed row fades and shrinks as it collapses
    Slot.Opacity := FRows[I].Presence;
    ScaleAt(Slot, 1, Max(0.01, FRows[I].Presence), FWidth / 2, H / 2);
    Row := UIPart('Row' + Id);
    Shift(Row, FRows[I].Offset, 0);
    Resize(Part('Card' + Id), FWidth, H);
    Place(UIPart('Avatar' + Id), 12, (H - 30) / 2);
    Size := MeasurePart('Name' + Id);
    NameH := Size.Height;
    Size := MeasurePart('Sub' + Id);
    Place(UIPart('Name' + Id), 52, (H - NameH - Size.Height - 1) / 2);
    Place(UIPart('Sub' + Id), 52, (H - NameH - Size.Height - 1) / 2 + NameH + 1);
    (Part('Name' + Id) as IFrameworkElement).MaxWidth := Max(20, FWidth - 52 - 70);
    (Part('Sub' + Id) as IFrameworkElement).MaxWidth := Max(20, FWidth - 52 - 70);
    Size := MeasurePart('Time' + Id);
    Place(UIPart('Time' + Id), FWidth - 12 - Size.Width, (H - NameH - Size.Height - 1) / 2 + 1);
    // The keyboard's row has a ring
    if FFocusRow = I then
      StrokePart('Card' + Id, MixColor(LineColor, AccentFromColor, 0.6 * Ord((ControlIntf as IUIElement).FocusState =
        RADWinUI.Abi.FocusState.Keyboard)))
    else
      StrokePart('Card' + Id, LineColor);
    LayoutRow(I, Top);
  end;
  LayoutOver;
end;

function TWinUISwipeList.RowAt(AY: Double): Integer;
var
  I: Integer;
  Top: Double;
begin
  for I := 0 to High(FRows) do
  begin
    if FRows[I].Removing then
      Continue;
    Top := FRows[I].ShownY;
    if (AY >= Top) and (AY <= Top + RowHeight) then
      Exit(I);
  end;
  Result := -1;
end;

function TWinUISwipeList.PointerDown(AX, AY: Double): Boolean;
begin
  FDragRow := RowAt(AY);
  FDragged := False;
  if FDragRow < 0 then
    Exit(False);
  FFocusRow := FDragRow;
  FDownX := AX;
  FDownY := AY;
  FDownOffset := FRows[FDragRow].Offset;
  Result := True;
end;

procedure TWinUISwipeList.PointerDrag(AX, AY: Double);
var
  Offset, Allowed: Double;
begin
  if (FDragRow < 0) or (FDragRow > High(FRows)) then
    Exit;
  if not FDragged and (Abs(AX - FDownX) < DragSlop) then
    Exit;
  FDragged := True;
  Offset := FDownOffset + AX - FDownX;
  // The wrong way the row barely moves, like a rubber band
  if Sign(Offset) <> SwipeDirection then
    Offset := Offset * 0.15;
  Allowed := FWidth * 0.85;
  Offset := EnsureRange(Offset, -Allowed, Allowed);
  FRows[FDragRow].Offset := Offset;
  FRows[FDragRow].Speed := 0;
end;

procedure TWinUISwipeList.PointerUp(AX, AY: Double; AInside: Boolean);
var
  Row: Integer;
begin
  Row := FDragRow;
  FDragRow := -1;
  if (Row < 0) or (Row > High(FRows)) then
    Exit;
  if FDragged then
    Released(Row, FRows[Row].Offset)
  else if AInside then
    Tapped(Row, AX - FRows[Row].Offset, AY - FRows[Row].ShownY);
  FDragged := False;
end;

function TWinUISwipeList.KeyPressed(AKey: TWinUIVirtualKey): Boolean;
begin
  Result := True;
  case AKey of
    TWinUIVirtualKey.Up:
      FFocusRow := Max(0, FFocusRow - 1);
    TWinUIVirtualKey.Down:
      FFocusRow := Min(High(FRows), FFocusRow + 1);
    TWinUIVirtualKey.Left, TWinUIVirtualKey.Right, TWinUIVirtualKey.Enter, TWinUIVirtualKey.Delete:
      if (FFocusRow >= 0) and (FFocusRow <= High(FRows)) then
        SwipeRow(FFocusRow);
  else
    Result := False;
  end;
  if Built then
    LayoutControl;
end;

function TWinUISwipeList.AutomationRole: AutomationControlType;
begin
  Result := AutomationControlType.List;
end;

function TWinUISwipeList.AutomationName: string;
begin
  Result := IntToStr(RowCount) + ' rows';
end;

{ TWinUIPinSwipeList }

class procedure TWinUIPinSwipeList.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddEvent('Pinned');
  AType.AddEvent('Unpinned');
end;

class function TWinUIPinSwipeList.DefaultAccentFrom: TWinUIColor;
begin
  Result := Rgb($F5, $A6, $23);
end;

class function TWinUIPinSwipeList.DefaultAccentTo: TWinUIColor;
begin
  Result := Rgb($FF, $D1, $4A);
end;

function TWinUIPinSwipeList.SwipeDirection: Integer;
begin
  Result := 1;
end;

function TWinUIPinSwipeList.BehindXaml(AIndex: Integer): string;
begin
  Result := '<Rectangle x:Name="Act' + IntToStr(AIndex) + '" RadiusX="12" RadiusY="12"><Rectangle.Fill>' +
    GradientXaml(AccentFromColor, AccentToColor, 0, 0, 1, 0) + '</Rectangle.Fill></Rectangle>' +
    '<FontIcon x:Name="ActIcon' + IntToStr(AIndex) + '" Glyph="' + GlyphXml(PinGlyph) + '" FontSize="16" Foreground="White" />';
end;

function TWinUIPinSwipeList.BadgeXaml(AIndex: Integer): string;
begin
  Result := '<FontIcon x:Name="Pin' + IntToStr(AIndex) + '" Glyph="' + GlyphXml(Char($E842)) + '" FontSize="11" Foreground="' +
    ColorHex(AccentFromColor) + '" />';
end;

procedure TWinUIPinSwipeList.Released(AIndex: Integer; AOffset: Double);
var
  Row: TWinUISwipeRow;
  I, Target: Integer;
begin
  if AOffset < Threshold then
    Exit;
  // The row turns pinned (or unpinned) and moves to the top, above the other pinned rows
  Row := FRows[AIndex];
  Row.Pinned := not Row.Pinned;
  Row.PinAge := 0;
  Delete(FRows, AIndex, 1);
  Target := 0;
  if not Row.Pinned then
    for I := 0 to High(FRows) do
      if FRows[I].Pinned then
        Target := I + 1;
  Insert(Row, FRows, Target);
  StoreItems;
  Rebuild;
  if Row.Pinned then
    FireAction(Target, 0)
  else
    FireAction(Target, 1);
  StartRendering;
end;

procedure TWinUIPinSwipeList.SwipeRow(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex > High(FRows)) then
    Exit;
  FRows[AIndex].Offset := Threshold + 10;
  Released(AIndex, Threshold + 10);
end;

procedure TWinUIPinSwipeList.LayoutRow(AIndex: Integer; ATop: Double);
var
  Id: string;
  H, Reveal, Pop: Double;
  Act, Icon, Pin: IUIElement;
  Time: RADWinUI.Abi.Size;
begin
  Id := IntToStr(AIndex);
  H := RowHeight;
  Reveal := Max(0, FRows[AIndex].Offset);
  Act := UIPart('Act' + Id);
  Resize(Act, Max(1, Reveal + 14), H);
  SetOpacity(Act, Ord(Reveal > 0.5));
  // The pin grows and tips over as the swipe reaches the threshold
  Icon := UIPart('ActIcon' + Id);
  Place(Icon, Max(8, Reveal / 2 - 8), (H - 16) / 2);
  SetOpacity(Icon, Clamp01(Reveal / 30));
  ScaleAt(Icon, 0.7 + 0.5 * Clamp01(Reveal / Threshold), 0.7 + 0.5 * Clamp01(Reveal / Threshold), 8, 8);
  Pin := UIPart('Pin' + Id);
  Time := MeasurePart('Time' + Id);
  Place(Pin, FWidth - 12 - 7, (H - Time.Height) / 2 + Time.Height - 2);
  if FRows[AIndex].Pinned then
  begin
    Pop := EaseOutBack(FRows[AIndex].PinAge / 0.35, 2.2);
    SetOpacity(Pin, 1);
    ScaleAt(Pin, Pop, Pop, 6, 6);
    RotateAt(Pin, -30 * (1 - Clamp01(FRows[AIndex].PinAge / 0.35)), 6, 6);
  end
  else
    SetOpacity(Pin, 0);
end;

{ TWinUIPeekSwipeList }

const
  PeekHintIndexIndex = OwnIndex;
  PeekIntervalIndex = OwnIndex + 1;
  PeekHintTextIndex = OwnIndex + 2;
  PeekActionTextIndex = OwnIndex + 3;
  PeekActionWidth = 76;

class procedure TWinUIPeekSwipeList.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('HintIndex', TWinUIPropertyKind.Int32, '1');
  AType.AddProperty('HintInterval', TWinUIPropertyKind.Int32, '5000');
  AType.AddProperty('HintText', TWinUIPropertyKind.Text, 'Swipe for options');
  AType.AddProperty('ActionText', TWinUIPropertyKind.Text, 'Delete');
  AType.AddEvent('Deleted');
end;

procedure TWinUIPeekSwipeList.Initialize;
begin
  inherited;
  // The first peek comes soon after the list shows
  FHinting := True;
end;

procedure TWinUIPeekSwipeList.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    PeekHintTextIndex, PeekActionTextIndex:
      Rebuild;
    PeekHintIndexIndex, PeekIntervalIndex:
      Hint;
  end;
end;

function TWinUIPeekSwipeList.SwipeDirection: Integer;
begin
  Result := -1;
end;

function TWinUIPeekSwipeList.HintRow: Integer;
begin
  Result := EnsureRange(HintIndex, 0, Max(0, High(FRows)));
end;

procedure TWinUIPeekSwipeList.Hint;
begin
  FHinting := True;
  FHintAge := 0;
  StartRendering;
end;

function TWinUIPeekSwipeList.PeekOffset: Double;
var
  T: Double;
begin
  // Two nudges to the left, the second a little smaller
  Result := 0;
  if not FHinting then
    Exit;
  T := FHintAge - 0.6;
  if (T > 0) and (T < 0.5) then
    Result := -34 * Sin(Pi * T / 0.5)
  else if (T >= 0.62) and (T < 1.07) then
    Result := -24 * Sin(Pi * (T - 0.62) / 0.45);
end;

function TWinUIPeekSwipeList.BehindXaml(AIndex: Integer): string;
begin
  Result := '<Rectangle x:Name="Act' + IntToStr(AIndex) + '" RadiusX="12" RadiusY="12" Fill="' + ColorHex(DangerColor) +
    '" />' + '<StackPanel x:Name="ActLabel' + IntToStr(AIndex) + '" Orientation="Vertical">' +
    '<FontIcon Glyph="' + GlyphXml(DeleteGlyph) + '" FontSize="14" Foreground="White" />' +
    '<TextBlock Text="' + XmlText(ActionText) + '" FontSize="' + Num(FontSize - 4) +
    '" FontWeight="SemiBold" Foreground="White" Margin="0,2,0,0" HorizontalAlignment="Center" /></StackPanel>' +
    // The edge that glows while the row peeks
    '<Rectangle x:Name="Edge' + IntToStr(AIndex) + '" RadiusX="12" RadiusY="12" StrokeThickness="1.5" Stroke="' +
    ColorHex(DangerColor) + '" />' +
    '<FontIcon x:Name="Chevron' + IntToStr(AIndex) + '" Glyph="' + GlyphXml(ChevronLeftGlyph) + '" FontSize="11" Foreground="' +
    ColorHex(MutedColor) + '" />';
end;

function TWinUIPeekSwipeList.OverXaml: string;
begin
  Result := '<Grid x:Name="Tip"><Rectangle x:Name="TipBack" Fill="' +
    ColorHex(ForSurface(MixColor(SurfaceColor, AccentFromColor, 0.45), MixColor(Rgb($FF, $FF, $FF), AccentFromColor, 0.85))) +
    '" /><StackPanel Orientation="Horizontal" Margin="10,4"><FontIcon Glyph="' + GlyphXml(ArrowLeftGlyph) +
    '" FontSize="9" Foreground="White" Margin="0,0,5,0" /><TextBlock Text="' + XmlText(HintText) + '" FontSize="' +
    Num(FontSize - 4) + '" Foreground="White" /></StackPanel></Grid>';
end;

function TWinUIPeekSwipeList.RestOffset(AIndex: Integer): Double;
begin
  if FRows[AIndex].Open then
    Result := -PeekActionWidth
  else if AIndex = HintRow then
    Result := PeekOffset
  else
    Result := 0;
end;

procedure TWinUIPeekSwipeList.Released(AIndex: Integer; AOffset: Double);
var
  I: Integer;
begin
  // Past half the button it snaps open; any other open row closes
  for I := 0 to High(FRows) do
    FRows[I].Open := False;
  FRows[AIndex].Open := AOffset < -PeekActionWidth / 2;
  if AOffset < -FWidth * 0.6 then
  begin
    RemoveRow(AIndex);
    FireAction(AIndex, 0);
  end;
  FHinting := False;
  StartRendering;
end;

function TWinUIPeekSwipeList.Tapped(AIndex: Integer; AX, AY: Double): Boolean;
var
  I: Integer;
begin
  // The open action: AX is in the row's own coordinates, past its right edge
  if FRows[AIndex].Open and (AX > FWidth) then
  begin
    RemoveRow(AIndex);
    FireAction(AIndex, 0);
    Exit(True);
  end;
  for I := 0 to High(FRows) do
    FRows[I].Open := False;
  Result := False;
  StartRendering;
end;

procedure TWinUIPeekSwipeList.SwipeRow(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex > High(FRows)) then
    Exit;
  if FRows[AIndex].Open then
  begin
    RemoveRow(AIndex);
    FireAction(AIndex, 0);
  end
  else
    Released(AIndex, -PeekActionWidth);
end;

procedure TWinUIPeekSwipeList.Advance(ASeconds: Double);
begin
  inherited;
  if not Built then
    Exit;
  FHintAge := FHintAge + ASeconds;
  if FHinting and (FHintAge > 1.6) then
    FHinting := False;
  // The peek again after a while, as long as nobody opened a row
  if not FHinting and (HintInterval > 0) and (FHintAge > HintInterval / 1000) then
    Hint;
end;

function TWinUIPeekSwipeList.StillMoving: Boolean;
begin
  Result := inherited or FHinting or (FHintAge < 0.6) or (HintInterval > 0);
end;

procedure TWinUIPeekSwipeList.LayoutRow(AIndex: Integer; ATop: Double);
var
  Id: string;
  H, Reveal, Glow: Double;
  Act, Element: IUIElement;
  Size: RADWinUI.Abi.Size;
begin
  Id := IntToStr(AIndex);
  H := RowHeight;
  Reveal := Max(0, -FRows[AIndex].Offset);
  Act := UIPart('Act' + Id);
  Resize(Act, Max(1, Reveal + 14), H);
  Place(Act, FWidth - Reveal - 14, 0);
  SetOpacity(Act, Ord(Reveal > 0.5));
  Element := UIPart('ActLabel' + Id);
  Size := MeasurePart('ActLabel' + Id);
  Place(Element, FWidth - Reveal / 2 - Size.Width / 2, (H - Size.Height) / 2);
  SetOpacity(Element, Clamp01((Reveal - 20) / 30));
  // While peeking: a red edge on the row and a chevron outside it
  Glow := Ord((AIndex = HintRow) and FHinting) * Clamp01(Reveal / 12);
  Element := UIPart('Edge' + Id);
  Resize(Element, FWidth, H);
  Shift(Element, FRows[AIndex].Offset, 0);
  SetOpacity(Element, Glow * 0.9);
  Element := UIPart('Chevron' + Id);
  Place(Element, FWidth - 13, (H - 11) / 2);
  SetOpacity(Element, Ord((AIndex = HintRow) and FHinting and (FHintAge > 0.4)));
end;

procedure TWinUIPeekSwipeList.LayoutOver;
var
  Tip: IUIElement;
  Size: RADWinUI.Abi.Size;
  Row: Integer;
  Show: Double;
begin
  Tip := UIPart('Tip');
  if Length(FRows) = 0 then
  begin
    SetOpacity(Tip, 0);
    Exit;
  end;
  Row := HintRow;
  Size := MeasurePart('Tip');
  Resize(Part('TipBack'), Size.Width, Size.Height);
  SetRadius(Part('TipBack'), Size.Height / 2);
  // The hint shows under the row while it peeks
  Show := Ord(FHinting) * Clamp01((FHintAge - 0.3) / 0.2) * Clamp01((1.6 - FHintAge) / 0.25);
  Place(Tip, FWidth * 0.38 - Size.Width / 2, FRows[Row].ShownY + RowHeight - Size.Height / 2 + 4 * (1 - Show));
  SetOpacity(Tip, Show);
end;

{ TWinUILiquidDeleteList }

class procedure TWinUILiquidDeleteList.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddEvent('Deleted');
end;

function TWinUILiquidDeleteList.SwipeDirection: Integer;
begin
  Result := -1;
end;

function TWinUILiquidDeleteList.Threshold: Double;
begin
  Result := 110;
end;

function TWinUILiquidDeleteList.BlobRadius(AOffset: Double): Double;
begin
  Result := Min(RowHeight * 0.42, Max(0, -AOffset) * 0.22);
end;

function TWinUILiquidDeleteList.BehindXaml(AIndex: Integer): string;
begin
  Result := '<Polygon x:Name="Goo' + IntToStr(AIndex) + '" Fill="' + ColorHex(DangerColor) + '" />' +
    '<FontIcon x:Name="GooIcon' + IntToStr(AIndex) + '" Glyph="' + GlyphXml(DeleteGlyph) + '" FontSize="13" Foreground="White" />';
end;

function TWinUILiquidDeleteList.OverXaml: string;
var
  I: Integer;
begin
  Result := '<Ellipse x:Name="Pop" StrokeThickness="2" Stroke="' + ColorHex(DangerColor) + '" />';
  for I := 0 to 7 do
    Result := Result + '<Ellipse x:Name="Drop' + IntToStr(I) + '" Fill="' + ColorHex(DangerColor) + '" />';
end;

procedure TWinUILiquidDeleteList.Released(AIndex: Integer; AOffset: Double);
var
  I: Integer;
  Radius, Angle, Speed: Double;
begin
  if AOffset > -Threshold then
    Exit;
  // The blob snaps off and pops into droplets; the row slides out and collapses
  Radius := BlobRadius(AOffset);
  FPopRow := AIndex;
  FPopAge := 0;
  FPopRadius := Radius;
  FPopX := FWidth + AOffset / 2;
  FPopY := FRows[AIndex].ShownY + RowHeight / 2;
  SetLength(FDrops, 8);
  for I := 0 to 7 do
  begin
    Angle := 2 * Pi * I / 8 + NextRandom * 0.5;
    Speed := 90 + 80 * NextRandom;
    FDrops[I].X := FPopX + Cos(Angle) * Radius * 0.6;
    FDrops[I].Y := FPopY + Sin(Angle) * Radius * 0.6;
    FDrops[I].VX := Cos(Angle) * Speed;
    FDrops[I].VY := Sin(Angle) * Speed - 40;
    FDrops[I].Age := 0;
  end;
  FRows[AIndex].Open := True;
  RemoveRow(AIndex);
  FireAction(AIndex, 0);
end;

procedure TWinUILiquidDeleteList.SwipeRow(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex > High(FRows)) then
    Exit;
  FRows[AIndex].Offset := -Threshold - 10;
  Released(AIndex, -Threshold - 10);
end;

procedure TWinUILiquidDeleteList.Advance(ASeconds: Double);
var
  I: Integer;
begin
  // A row that went keeps sliding out to the left while it collapses
  for I := 0 to High(FRows) do
    if FRows[I].Removing and FRows[I].Open then
      FRows[I].Offset := FRows[I].Offset - ASeconds * 900;
  inherited;
  FPopAge := FPopAge + ASeconds;
  for I := 0 to High(FDrops) do
  begin
    FDrops[I].Age := FDrops[I].Age + ASeconds;
    FDrops[I].X := FDrops[I].X + FDrops[I].VX * ASeconds;
    FDrops[I].Y := FDrops[I].Y + FDrops[I].VY * ASeconds;
    FDrops[I].VY := FDrops[I].VY + 420 * ASeconds;
  end;
end;

function TWinUILiquidDeleteList.StillMoving: Boolean;
begin
  Result := inherited or (FPopAge < 0.6);
end;

procedure TWinUILiquidDeleteList.LayoutRow(AIndex: Integer; ATop: Double);
var
  Id: string;
  H, Offset, Radius, Edge, CX, CY, Neck, T, X, Y, Dip: Double;
  Points: TArray<RADWinUI.Abi.Point>;
  I: Integer;
  Goo, Icon: IUIElement;
begin
  Id := IntToStr(AIndex);
  H := RowHeight;
  Offset := FRows[AIndex].Offset;
  Goo := UIPart('Goo' + Id);
  Icon := UIPart('GooIcon' + Id);
  Radius := BlobRadius(Offset);
  if (Radius < 1) or (FRows[AIndex].Removing and FRows[AIndex].Open) then
  begin
    SetOpacity(Goo, 0);
    SetOpacity(Icon, 0);
    Exit;
  end;
  // The blob sits in the gap the row leaves; a neck joins it to the row's edge, thinner as it stretches
  Edge := FWidth + Offset;
  CX := FWidth + Offset / 2 + Radius * 0.3;
  CY := H / 2;
  Neck := Max(1.5, H * 0.32 * (1 - Clamp01(-Offset / Threshold) * 0.8));
  Points := nil;
  // The top of the neck, from the row's edge to the blob, dipping toward the middle
  for I := 0 to 8 do
  begin
    T := I / 8;
    X := Lerp(Edge - 6, CX, T);
    Dip := Sin(Pi * T) * Neck * 0.55;
    Y := Lerp(CY - Neck, CY - Radius * 0.55, T) + Dip;
    Points := Points + [Pt(X, Y)];
  end;
  // Around the blob from its top to its bottom, over its far side
  for I := 0 to 20 do
  begin
    T := -Pi / 2 - 0.9 + (Pi + 1.8) * I / 20;
    Points := Points + [Pt(CX + Radius * Cos(-T + Pi), CY - Radius * Sin(-T + Pi))];
  end;
  for I := 8 downto 0 do
  begin
    T := I / 8;
    X := Lerp(Edge - 6, CX, T);
    Dip := Sin(Pi * T) * Neck * 0.55;
    Y := Lerp(CY + Neck, CY + Radius * 0.55, T) - Dip;
    Points := Points + [Pt(X, Y)];
  end;
  SetLinePoints(Goo, Points);
  SetOpacity(Goo, 1);
  Place(Icon, CX - 6.5, CY - 6.5);
  SetOpacity(Icon, Clamp01((Radius - 9) / 5));
end;

procedure TWinUILiquidDeleteList.LayoutOver;
var
  I: Integer;
  Ring, Drop: IUIElement;
  Size, T: Double;
begin
  Ring := UIPart('Pop');
  T := Clamp01(FPopAge / 0.35);
  if FPopAge < 0.35 then
  begin
    Size := FPopRadius * 2 * (1 + 1.2 * EaseOutCubic(T));
    Resize(Ring, Size, Size);
    Place(Ring, FPopX - Size / 2, FPopY - Size / 2);
    SetOpacity(Ring, 1 - T);
  end
  else
    SetOpacity(Ring, 0);
  for I := 0 to 7 do
  begin
    Drop := UIPart('Drop' + IntToStr(I));
    if (I <= High(FDrops)) and (FDrops[I].Age < 0.55) then
    begin
      Size := 6 * (1 - FDrops[I].Age / 0.55) + 1;
      Resize(Drop, Size, Size);
      Place(Drop, FDrops[I].X - Size / 2, FDrops[I].Y - Size / 2);
      SetOpacity(Drop, 1 - FDrops[I].Age / 0.55);
    end
    else
      SetOpacity(Drop, 0);
  end;
end;

{ TWinUISnoozeSwipeList }

const
  SnoozeOptionsIndex = OwnIndex;
  SnoozeTravel = 190;

class procedure TWinUISnoozeSwipeList.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('SnoozeOptions', TWinUIPropertyKind.Text, '1h, 3h, 6 PM');
  AType.AddEvent('Snoozed');
end;

function TWinUISnoozeSwipeList.SwipeDirection: Integer;
begin
  Result := -1;
end;

function TWinUISnoozeSwipeList.Threshold: Double;
begin
  Result := 64;
end;

function TWinUISnoozeSwipeList.Options: TArray<string>;
begin
  Result := SplitList(SnoozeOptions);
  if Length(Result) = 0 then
    Result := ['1h'];
end;

function TWinUISnoozeSwipeList.OptionAt(AOffset: Double): Integer;
var
  Count: Integer;
  Travel: Double;
begin
  // The farther the drag, the later the snooze
  Count := Length(Options);
  Travel := Max(0, -AOffset - Threshold);
  Result := EnsureRange(Floor(Travel / Max(1, (SnoozeTravel - Threshold) / Count)), 0, Count - 1);
end;

function TWinUISnoozeSwipeList.SnoozeOf(AIndex: Integer): string;
begin
  if (AIndex >= 0) and (AIndex <= High(FRows)) then
    Result := FRows[AIndex].Snooze
  else
    Result := '';
end;

function TWinUISnoozeSwipeList.BehindXaml(AIndex: Integer): string;
var
  Id: string;
begin
  Id := IntToStr(AIndex);
  // A clock drawn with two hands that spin with the drag
  Result := '<Rectangle x:Name="Act' + Id + '" RadiusX="12" RadiusY="12"><Rectangle.Fill>' +
    GradientXaml(WarningColor, MixColor(WarningColor, Rgb($FF, $5A, $00), 0.3), 0, 0, 1, 0) + '</Rectangle.Fill></Rectangle>' +
    '<Canvas x:Name="Clock' + Id + '" Width="22" Height="22"><Ellipse Width="22" Height="22" Stroke="White" StrokeThickness="2" />' +
    '<Line x:Name="Hour' + Id + '" X1="11" Y1="11" StrokeThickness="2" Stroke="White" StrokeEndLineCap="Round" />' +
    '<Line x:Name="Minute' + Id + '" X1="11" Y1="11" StrokeThickness="1.6" Stroke="White" StrokeEndLineCap="Round" /></Canvas>' +
    '<TextBlock x:Name="When' + Id + '" FontSize="' + Num(FontSize - 2) + '" FontWeight="Bold" Foreground="White" />';
end;

function TWinUISnoozeSwipeList.BadgeXaml(AIndex: Integer): string;
begin
  Result := '<StackPanel x:Name="Snoozed' + IntToStr(AIndex) + '" Orientation="Horizontal">' +
    '<FontIcon Glyph="' + GlyphXml(ClockGlyph) + '" FontSize="10" Foreground="' + ColorHex(WarningColor) +
    '" Margin="0,0,3,0" /><TextBlock x:Name="SnoozedText' + IntToStr(AIndex) + '" Text="' +
    XmlText(FRows[AIndex].Snooze) + '" FontSize="' + Num(FontSize - 4) + '" FontWeight="Bold" Foreground="' +
    ColorHex(WarningColor) + '" /></StackPanel>';
end;

procedure TWinUISnoozeSwipeList.Released(AIndex: Integer; AOffset: Double);
begin
  if AOffset > -Threshold then
    Exit;
  FRows[AIndex].Snooze := Options[OptionAt(AOffset)];
  FRows[AIndex].SnoozeAge := 0;
  TextPart('SnoozedText' + IntToStr(AIndex), FRows[AIndex].Snooze);
  FireAction(AIndex, 0);
  StartRendering;
end;

procedure TWinUISnoozeSwipeList.SwipeRow(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex > High(FRows)) then
    Exit;
  // From the keyboard each swipe takes the next time
  FRows[AIndex].Snooze := Options[(IndexStr(FRows[AIndex].Snooze, Options) + 1) mod Length(Options)];
  FRows[AIndex].SnoozeAge := 0;
  FRows[AIndex].Offset := -Threshold;
  TextPart('SnoozedText' + IntToStr(AIndex), FRows[AIndex].Snooze);
  FireAction(AIndex, 0);
  StartRendering;
end;

procedure TWinUISnoozeSwipeList.LayoutRow(AIndex: Integer; ATop: Double);
var
  Id: string;
  H, Reveal, Turn, Pop: Double;
  Act, Clock, When, Badge, Time: IUIElement;
  Hand: ILine;
  Size: RADWinUI.Abi.Size;
begin
  Id := IntToStr(AIndex);
  H := RowHeight;
  Reveal := Max(0, -FRows[AIndex].Offset);
  Act := UIPart('Act' + Id);
  Resize(Act, Max(1, Reveal + 14), H);
  Place(Act, FWidth - Reveal - 14, 0);
  SetOpacity(Act, Ord(Reveal > 0.5));
  // The hands turn as the row is dragged: the minute hand fast, the hour hand slow
  Turn := Reveal / 40;
  Hand := Part('Minute' + Id) as ILine;
  Hand.X2 := 11 + 7 * Sin(Turn * 2 * Pi);
  Hand.Y2 := 11 - 7 * Cos(Turn * 2 * Pi);
  Hand := Part('Hour' + Id) as ILine;
  Hand.X2 := 11 + 4.5 * Sin(Turn * Pi / 3 + Pi / 3);
  Hand.Y2 := 11 - 4.5 * Cos(Turn * Pi / 3 + Pi / 3);
  Clock := UIPart('Clock' + Id);
  When := UIPart('When' + Id);
  TextPart('When' + Id, Options[OptionAt(-Reveal)]);
  Size := MeasurePart('When' + Id);
  Place(Clock, FWidth - Reveal / 2 - (22 + 6 + Size.Width) / 2, (H - 22) / 2);
  Place(When, FWidth - Reveal / 2 - (22 + 6 + Size.Width) / 2 + 28, (H - Size.Height) / 2);
  SetOpacity(Clock, Clamp01((Reveal - 16) / 24));
  SetOpacity(When, Clamp01((Reveal - Threshold + 12) / 16));
  // A snoozed row shows its time in amber where the time was, with a pop
  Badge := UIPart('Snoozed' + Id);
  Time := UIPart('Time' + Id);
  if FRows[AIndex].Snooze <> '' then
  begin
    Size := MeasurePart('Snoozed' + Id);
    Place(Badge, FWidth - 12 - Size.Width, (H - Size.Height) / 2 + 8);
    Pop := EaseOutBack(FRows[AIndex].SnoozeAge / 0.35, 2);
    SetOpacity(Badge, 1);
    ScaleAt(Badge, Pop, Pop, Size.Width / 2, Size.Height / 2);
  end
  else
    SetOpacity(Badge, 0);
end;

{ TWinUIUndoSwipeList }

const
  UndoTextIndex = OwnIndex;
  UndoDurationIndex = OwnIndex + 1;

class procedure TWinUIUndoSwipeList.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('UndoText', TWinUIPropertyKind.Text, 'Conversation deleted');
  AType.AddProperty('UndoDuration', TWinUIPropertyKind.Int32, '4000');
  AType.AddEvent('Deleted');
  AType.AddEvent('Restored');
end;

function TWinUIUndoSwipeList.SwipeDirection: Integer;
begin
  Result := -1;
end;

function TWinUIUndoSwipeList.BehindXaml(AIndex: Integer): string;
var
  Id: string;
begin
  Id := IntToStr(AIndex);
  Result := '<Rectangle x:Name="Act' + Id + '" RadiusX="12" RadiusY="12" Fill="' + ColorHex(DangerColor) + '" />' +
    '<FontIcon x:Name="ActIcon' + Id + '" Glyph="' + GlyphXml(DeleteGlyph) + '" FontSize="15" Foreground="White" />' +
    // The strip that stays where the row was
    '<Canvas x:Name="Strip' + Id + '"><Rectangle x:Name="StripBack' + Id + '" RadiusX="12" RadiusY="12" Fill="' +
    ColorHex(ForSurface(MixColor(SurfaceColor, AccentFromColor, 0.2), MixColor(Rgb($FF, $FF, $FF), AccentFromColor, 0.1))) +
    '" />' + '<TextBlock x:Name="StripText' + Id + '" Text="' + XmlText(UndoText) + '" FontSize="' + Num(FontSize - 2) +
    '" Foreground="' + ColorHex(TextColor) + '" />' +
    '<Rectangle x:Name="Count' + Id + '" Height="3" RadiusX="1.5" RadiusY="1.5"><Rectangle.Fill>' +
    GradientXaml(AccentFromColor, AccentToColor, 0, 0, 1, 0) + '</Rectangle.Fill></Rectangle>' +
    '<Grid x:Name="Undo' + Id + '"><Ellipse x:Name="UndoRing' + Id + '" StrokeThickness="2" Stroke="' +
    ColorHex(MixColor(AccentToColor, Rgb($FF, $FF, $FF), 0.3)) + '" Fill="' + ColorHex(SurfaceColor) + '" />' +
    '<TextBlock Text="Undo" FontSize="' + Num(FontSize - 3) + '" FontWeight="Bold" Foreground="' + ColorHex(AccentToColor) +
    '" HorizontalAlignment="Center" VerticalAlignment="Center" /></Grid></Canvas>';
end;

function TWinUIUndoSwipeList.UndoRect(AIndex: Integer; out ALeft, AWidth: Double): Boolean;
begin
  AWidth := RowHeight - 6;
  ALeft := FWidth - AWidth - 3;
  Result := FRows[AIndex].Open;
end;

procedure TWinUIUndoSwipeList.Released(AIndex: Integer; AOffset: Double);
begin
  if AOffset > -Threshold then
    Exit;
  // The row slides away and the strip takes its place
  FRows[AIndex].Open := True;
  FRows[AIndex].StateAge := 0;
  SetAction(AIndex);
  StartRendering;
end;

procedure TWinUIUndoSwipeList.SwipeRow(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex > High(FRows)) then
    Exit;
  if FRows[AIndex].Open then
    Undo(AIndex)
  else
    Released(AIndex, -Threshold - 1);
end;

procedure TWinUIUndoSwipeList.Undo(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex > High(FRows)) or not FRows[AIndex].Open then
    Exit;
  FRows[AIndex].Open := False;
  FRows[AIndex].StateAge := 0;
  // It comes back from the left
  FRows[AIndex].Offset := -FWidth;
  FRows[AIndex].Speed := 0;
  FireAction(AIndex, 1);
  StartRendering;
end;

function TWinUIUndoSwipeList.Tapped(AIndex: Integer; AX, AY: Double): Boolean;
var
  Left, Width: Double;
begin
  // AX here counts from the row as it is drawn: the row is off to the left, the strip is not
  AX := AX + FRows[AIndex].Offset;
  Result := UndoRect(AIndex, Left, Width) and (AX >= Left - 6);
  if Result then
    Undo(AIndex);
end;

procedure TWinUIUndoSwipeList.AdvanceRow(AIndex: Integer; ASeconds: Double);
begin
  if FRows[AIndex].Open then
  begin
    // Off to the left while the strip waits; once the time is up, the row goes for good
    FRows[AIndex].Offset := Max(-FWidth - 20, FRows[AIndex].Offset - ASeconds * 1400);
    if not FRows[AIndex].Removing and (FRows[AIndex].StateAge > Max(500, UndoDuration) / 1000) then
    begin
      RemoveRow(AIndex);
      FireAction(AIndex, 0);
    end;
    Exit;
  end;
  inherited;
end;

function TWinUIUndoSwipeList.RowMoving(AIndex: Integer): Boolean;
begin
  Result := FRows[AIndex].Open or inherited;
end;

procedure TWinUIUndoSwipeList.LayoutRow(AIndex: Integer; ATop: Double);
var
  Id: string;
  H, Reveal, Show, Left, Width: Double;
  Act, Icon, Strip, Element: IUIElement;
  Size: RADWinUI.Abi.Size;
  Ring: IUIElement;
begin
  Id := IntToStr(AIndex);
  H := RowHeight;
  Reveal := Max(0, -FRows[AIndex].Offset);
  Act := UIPart('Act' + Id);
  Icon := UIPart('ActIcon' + Id);
  Strip := UIPart('Strip' + Id);
  // The strip fades in as the row leaves and out as it comes back
  if FRows[AIndex].Open then
    Show := Clamp01(FRows[AIndex].StateAge / 0.2)
  else
    Show := 0;
  Resize(Act, Max(1, Reveal + 14), H);
  Place(Act, FWidth - Reveal - 14, 0);
  SetOpacity(Act, Ord(Reveal > 0.5) * (1 - Show));
  Place(Icon, FWidth - Min(Reveal, 80) / 2 - 7.5, (H - 15) / 2);
  SetOpacity(Icon, Clamp01((Reveal - 20) / 20) * (1 - Show));
  SetOpacity(Strip, Show);
  if Show <= 0 then
    Exit;
  Resize(Part('StripBack' + Id), FWidth, H);
  Size := MeasurePart('StripText' + Id);
  Place(UIPart('StripText' + Id), 14, (H - Size.Height) / 2 - 2);
  // The time left runs out along the bottom of the strip
  Element := UIPart('Count' + Id);
  Width := (FWidth - 28 - H) * (1 - Clamp01(FRows[AIndex].StateAge / (Max(500, UndoDuration) / 1000)));
  Resize(Element, Max(1, Width), 3);
  Place(Element, 14, H - 9);
  if UndoRect(AIndex, Left, Width) then
  begin
    Ring := UIPart('Undo' + Id);
    Resize(Ring, Width, Width);
    Resize(Part('UndoRing' + Id), Width, Width);
    Place(Ring, Left, 3);
  end;
end;

{ TWinUISwipeCardStack }

const
  CardItemsIndex = DrawnOwnIndex;
  CardLoopIndex = DrawnOwnIndex + 1;
  CardLikeIndex = DrawnOwnIndex + 2;
  CardPassIndex = DrawnOwnIndex + 3;
  CardButtonsIndex = DrawnOwnIndex + 4;
  CardDepth = 3;
  CardThreshold = 90;
  DefaultCards = 'Flower Shop|1 km away|Heart; Coffee Lab|300 m away|Shop; Vinyl Corner|2 km away|Music; ' +
    'Sky Tours|5 km away|Airplane; Photo Walk|800 m away|Camera';

class procedure TWinUISwipeCardStack.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Items', TWinUIPropertyKind.Text, DefaultCards);
  AType.AddProperty('Loop', TWinUIPropertyKind.Boolean, 'True');
  AType.AddProperty('LikeText', TWinUIPropertyKind.Text, 'LIKE');
  AType.AddProperty('PassText', TWinUIPropertyKind.Text, 'NOPE');
  AType.AddProperty('ShowButtons', TWinUIPropertyKind.Boolean, 'True');
  AType.AddEvent('Liked');
  AType.AddEvent('Passed');
end;

class function TWinUISwipeCardStack.DefaultWidth: Double;
begin
  Result := 320;
end;

class function TWinUISwipeCardStack.DefaultHeight: Double;
begin
  Result := 190;
end;

procedure TWinUISwipeCardStack.Initialize;
begin
  inherited;
  FButtonDown := -1;
  FRise := 1;
  ParseCards;
end;

procedure TWinUISwipeCardStack.ParseCards;
var
  Entry: string;
  Fields: TArray<string>;
  Card: TCard;
  Filled: Char;
begin
  FCards := nil;
  for Entry in SplitList(Items, ';') do
  begin
    Fields := Entry.Split(['|']);
    Card := Default(TCard);
    Card.Title := Trim(Fields[0]);
    if Length(Fields) > 1 then
      Card.Subtitle := Trim(Fields[1]);
    if Length(Fields) > 2 then
      ResolveTabBarIcon(Fields[2], Card.Glyph, Filled)
    else
      ResolveTabBarIcon('Star', Card.Glyph, Filled);
    FCards := FCards + [Card];
  end;
  FTop := 0;
end;

procedure TWinUISwipeCardStack.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    CardItemsIndex:
      begin
        ParseCards;
        Rebuild;
      end;
    CardLikeIndex, CardPassIndex, CardButtonsIndex, CardLoopIndex:
      Rebuild;
  end;
end;

function TWinUISwipeCardStack.CardAt(ADepth: Integer): Integer;
begin
  // The card ADepth below the top one, -1 when the stack has run out
  if Length(FCards) = 0 then
    Exit(-1);
  Result := FTop + ADepth;
  if Loop then
    Result := Result mod Length(FCards)
  else if Result > High(FCards) then
    Result := -1;
end;

function TWinUISwipeCardStack.GetCurrentTitle: string;
begin
  if CardAt(0) >= 0 then
    Result := FCards[CardAt(0)].Title
  else
    Result := '';
end;

function TWinUISwipeCardStack.StyleXaml: string;
var
  D: Integer;
  Id: string;
  Button: TWinUIColor;
begin
  Result := '';
  // The cards back to front; their art and text are set as they move up the stack
  for D := CardDepth - 1 downto 0 do
  begin
    Id := IntToStr(D);
    Result := Result + '<Canvas x:Name="C' + Id + '">' +
      '<Rectangle x:Name="Art' + Id + '" RadiusX="16" RadiusY="16" />' +
      '<Ellipse x:Name="Sun' + Id + '" Fill="#33FFFFFF" />' +
      '<Grid x:Name="IconBox' + Id + '"><FontIcon x:Name="Icon' + Id + '" FontSize="40" Foreground="White" ' +
      'HorizontalAlignment="Center" VerticalAlignment="Center" /></Grid>' +
      '<Rectangle x:Name="Shade' + Id + '" RadiusX="16" RadiusY="16"><Rectangle.Fill>' +
      '<LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#00000000" Offset="0.45" />' +
      '<GradientStop Color="#B0000000" Offset="1" /></LinearGradientBrush></Rectangle.Fill></Rectangle>' +
      '<TextBlock x:Name="Title' + Id + '" FontSize="' + Num(FontSize - 1) + '" FontWeight="Bold" Foreground="White" />' +
      '<TextBlock x:Name="Sub' + Id + '" FontSize="' + Num(FontSize - 4) + '" Foreground="#D0FFFFFF" />' +
      '</Canvas>';
  end;
  Result := Result +
    // The stamps on the top card
    '<Grid x:Name="LikeStamp"><Rectangle x:Name="LikeRect" RadiusX="6" RadiusY="6" StrokeThickness="2.5" Stroke="' +
    ColorHex(SuccessColor) + '" /><TextBlock Text="' + XmlText(LikeText) + '" FontSize="' + Num(FontSize + 2) +
    '" FontWeight="Black" Foreground="' + ColorHex(SuccessColor) + '" Margin="8,2" /></Grid>' +
    '<Grid x:Name="PassStamp"><Rectangle x:Name="PassRect" RadiusX="6" RadiusY="6" StrokeThickness="2.5" Stroke="' +
    ColorHex(DangerColor) + '" /><TextBlock Text="' + XmlText(PassText) + '" FontSize="' + Num(FontSize + 2) +
    '" FontWeight="Black" Foreground="' + ColorHex(DangerColor) + '" Margin="8,2" /></Grid>' +
    CenteredTextXaml('Empty', 'No more cards', FontSize - 1, 'SemiBold', MutedColor);
  Button := ForSurface(MixColor(SurfaceColor, Rgb($FF, $FF, $FF), 0.08), Rgb($FF, $FF, $FF));
  Result := Result +
    '<Grid x:Name="PassButton"><Ellipse x:Name="PassDisc" Fill="' + ColorHex(Button) + '" Stroke="' + ColorHex(LineColor) +
    '" StrokeThickness="1" /><FontIcon Glyph="' + GlyphXml(CloseGlyph) + '" FontSize="13" Foreground="' +
    ColorHex(DangerColor) + '" /></Grid>' +
    '<Grid x:Name="LikeButton"><Ellipse x:Name="LikeDisc" Fill="' + ColorHex(Button) + '" Stroke="' + ColorHex(LineColor) +
    '" StrokeThickness="1" /><FontIcon Glyph="' + GlyphXml(HeartGlyph) + '" FontSize="14" Foreground="' +
    ColorHex(SuccessColor) + '" /></Grid>';
end;

function TWinUISwipeCardStack.CardRect(out ALeft, ATop, AWidth, AHeight: Double): Boolean;
begin
  AHeight := Max(40, FHeight - 22);
  AWidth := Min(AHeight * 1.05, FWidth - Ord(ShowButtons) * 110);
  ALeft := (FWidth - AWidth) / 2;
  ATop := 4;
  Result := AWidth > 20;
end;

function TWinUISwipeCardStack.ButtonCenter(AIndex: Integer; out AX, AY: Double): Boolean;
var
  Left, Top, Width, Height: Double;
begin
  CardRect(Left, Top, Width, Height);
  AY := Top + Height / 2;
  if AIndex = 0 then
    AX := Left - 34
  else
    AX := Left + Width + 34;
  Result := ShowButtons;
end;

function TWinUISwipeCardStack.ButtonAt(AX, AY: Double): Integer;
var
  I: Integer;
  X, Y: Double;
begin
  for I := 0 to 1 do
    if ButtonCenter(I, X, Y) and (Hypot(AX - X, AY - Y) <= 24) then
      Exit(I);
  Result := -1;
end;

procedure TWinUISwipeCardStack.Fly(ADirection: Integer);
begin
  if FFlying or (CardAt(0) < 0) then
    Exit;
  FFlying := True;
  FFlyDirection := ADirection;
  FFlyAge := 0;
  if FSpeedX * ADirection < 900 then
    FSpeedX := ADirection * 900;
  if ADirection > 0 then
    FButtonPop[1] := 1
  else
    FButtonPop[0] := 1;
  StartRendering;
end;

procedure TWinUISwipeCardStack.Settle;
begin
  // The flown card leaves the stack: the next one is on top
  FFlying := False;
  FDragX := 0;
  FDragY := 0;
  FSpeedX := 0;
  FSpeedY := 0;
  Inc(FTop);
  if Loop and (Length(FCards) > 0) then
    FTop := FTop mod Length(FCards);
  FRise := 0;
  FRiseSpeed := 0;
  if FFlyDirection > 0 then
    Fire(0)
  else
    Fire(1);
end;

procedure TWinUISwipeCardStack.Like;
begin
  Fly(1);
end;

procedure TWinUISwipeCardStack.Pass;
begin
  Fly(-1);
end;

function TWinUISwipeCardStack.PointerDown(AX, AY: Double): Boolean;
var
  Left, Top, Width, Height: Double;
begin
  FButtonDown := ButtonAt(AX, AY);
  if FButtonDown >= 0 then
    Exit(True);
  if FFlying or (CardAt(0) < 0) or not CardRect(Left, Top, Width, Height) then
    Exit(False);
  Result := (AX >= Left) and (AX <= Left + Width) and (AY >= Top) and (AY <= Top + Height);
  if Result then
  begin
    FDragging := True;
    FDownX := AX - FDragX;
    FDownY := AY - FDragY;
  end;
end;

procedure TWinUISwipeCardStack.PointerDrag(AX, AY: Double);
var
  X, Y: Double;
begin
  if not FDragging then
    Exit;
  X := AX - FDownX;
  Y := (AY - FDownY) * 0.4;
  FSpeedX := (X - FDragX) * 60;
  FSpeedY := (Y - FDragY) * 60;
  FDragX := X;
  FDragY := Y;
end;

procedure TWinUISwipeCardStack.PointerUp(AX, AY: Double; AInside: Boolean);
begin
  if FButtonDown >= 0 then
  begin
    if AInside and (ButtonAt(AX, AY) = FButtonDown) then
      if FButtonDown = 1 then
        Like
      else
        Pass;
    FButtonDown := -1;
    Exit;
  end;
  if not FDragging then
    Exit;
  FDragging := False;
  if FDragX > CardThreshold then
    Fly(1)
  else if FDragX < -CardThreshold then
    Fly(-1);
end;

function TWinUISwipeCardStack.KeyPressed(AKey: TWinUIVirtualKey): Boolean;
begin
  Result := True;
  case AKey of
    TWinUIVirtualKey.Right:
      Like;
    TWinUIVirtualKey.Left:
      Pass;
  else
    Result := False;
  end;
end;

procedure TWinUISwipeCardStack.Advance(ASeconds: Double);
var
  I: Integer;
begin
  inherited;
  if FFlying then
  begin
    FFlyAge := FFlyAge + ASeconds;
    FDragX := FDragX + FSpeedX * ASeconds;
    FDragY := FDragY + FSpeedY * ASeconds + 120 * ASeconds;
    if (FFlyAge > 0.45) or (Abs(FDragX) > FWidth) then
      Settle;
  end
  else if not FDragging then
  begin
    // Let go too early: the card springs back to the middle
    SpringStep(FDragX, FSpeedX, 0, ASeconds, 240, 20);
    SpringStep(FDragY, FSpeedY, 0, ASeconds, 240, 20);
  end;
  SpringStep(FRise, FRiseSpeed, 1, ASeconds, 200, 18);
  for I := 0 to 1 do
    FButtonPop[I] := Max(0, FButtonPop[I] - ASeconds / 0.3);
end;

function TWinUISwipeCardStack.StillMoving: Boolean;
begin
  Result := inherited or FFlying or FDragging or (Abs(FDragX) > 0.1) or (Abs(FDragY) > 0.1) or (Abs(FSpeedX) > 0.1) or
    (Abs(FRise - 1) > 0.001) or (Abs(FRiseSpeed) > 0.001) or (FButtonPop[0] > 0) or (FButtonPop[1] > 0);
end;

procedure TWinUISwipeCardStack.LayoutControl;
const
  Arts: array[0..5, 0..1] of Cardinal = (($2E7D5B, $1B4D3E), ($8E5A3C, $4A2C1E), ($5B3FA8, $2B1E5E),
    ($2F6FB5, $163A66), ($B5476A, $5E1E36), ($2D8C8C, $134848));
var
  D, Index, Shown: Integer;
  Left, Top, Width, Height, Scale, Lift, Angle, Like, Pass, X, Y, Pop: Double;
  Card, Element: IUIElement;
  Id: string;
  From, To_: TWinUIColor;
  Art: IShape;
  Size: RADWinUI.Abi.Size;
begin
  if not CardRect(Left, Top, Width, Height) then
    Exit;
  Shown := 0;
  for D := 0 to CardDepth - 1 do
  begin
    Id := IntToStr(D);
    Card := UIPart('C' + Id);
    Index := CardAt(D);
    if Index < 0 then
    begin
      SetOpacity(Card, 0);
      Continue;
    end;
    Inc(Shown);
    // The cards below sit smaller and lower; as the top one goes they rise one step
    Lift := D - (1 - FRise);
    if D = 0 then
      Lift := 0;
    Scale := 1 - 0.06 * Max(0, Lift);
    Place(Card, Left, Top + 9 * Max(0, Lift));
    Resize(Part('Art' + Id), Width, Height);
    Resize(Part('Shade' + Id), Width, Height);
    Art := Part('Art' + Id) as IShape;
    From := Rgb((Arts[Index mod 6, 0] shr 16) and $FF, (Arts[Index mod 6, 0] shr 8) and $FF, Arts[Index mod 6, 0] and $FF);
    To_ := Rgb((Arts[Index mod 6, 1] shr 16) and $FF, (Arts[Index mod 6, 1] shr 8) and $FF, Arts[Index mod 6, 1] and $FF);
    Art.Fill := RADWinUI.Abi.SolidColorBrush.New(MixColor(From, To_, 0.35)) as IBrush;
    Element := UIPart('Sun' + Id);
    Resize(Element, Width * 0.7, Width * 0.7);
    Place(Element, Width * 0.45, -Width * 0.18);
    Resize(UIPart('IconBox' + Id), Width, Height * 0.7);
    (Part('Icon' + Id) as IFontIcon).Glyph := WinStr(FCards[Index].Glyph);
    TextPart('Title' + Id, FCards[Index].Title);
    TextPart('Sub' + Id, FCards[Index].Subtitle);
    Size := MeasurePart('Sub' + Id);
    Place(UIPart('Sub' + Id), 12, Height - 10 - Size.Height);
    Place(UIPart('Title' + Id), 12, Height - 12 - Size.Height - MeasurePart('Title' + Id).Height);
    if D = 0 then
    begin
      // The top card follows the drag and tilts with it
      Angle := FDragX * 0.08;
      Card.CenterPoint := Vec3(Width / 2, Height * 1.2, 0);
      Card.Rotation := Angle;
      Card.Scale := Vec3(1, 1, 1);
      Card.Translation := Vec3(FDragX, FDragY, 0);
      Card.Opacity := 1 - Ord(FFlying) * Clamp01((FFlyAge - 0.2) / 0.25);
    end
    else
    begin
      Card.Rotation := 0;
      Card.Translation := Vec3(0, 0, 0);
      ScaleAt(Card, Scale, Scale, Width / 2, Height);
      Card.Opacity := 1 - 0.25 * Max(0, Lift);
    end;
  end;
  // The stamps fade in with the drag, LIKE on the left of the card when it goes right
  Like := Clamp01(FDragX / CardThreshold);
  Pass := Clamp01(-FDragX / CardThreshold);
  Element := UIPart('LikeStamp');
  Size := MeasurePart('LikeStamp');
  Resize(Part('LikeRect'), Size.Width, Size.Height);
  Place(Element, Left + 14, Top + 16);
  Element.CenterPoint := Vec3(Size.Width / 2, Size.Height / 2, 0);
  Element.Rotation := -14 + FDragX * 0.08;
  Element.Translation := Vec3(FDragX, FDragY, 0);
  SetOpacity(Element, Like);
  Element := UIPart('PassStamp');
  Size := MeasurePart('PassStamp');
  Resize(Part('PassRect'), Size.Width, Size.Height);
  Place(Element, Left + Width - 14 - Size.Width, Top + 16);
  Element.CenterPoint := Vec3(Size.Width / 2, Size.Height / 2, 0);
  Element.Rotation := 14 + FDragX * 0.08;
  Element.Translation := Vec3(FDragX, FDragY, 0);
  SetOpacity(Element, Pass);
  Element := UIPart('EmptyBox');
  Resize(Element, Width, Height);
  Place(Element, Left, Top);
  SetOpacity(Element, Ord(Shown = 0));
  // The buttons grow with the drag towards them and pop when used
  if ButtonCenter(0, X, Y) then
  begin
    Element := UIPart('PassButton');
    Resize(Element, 44, 44);
    Resize(Part('PassDisc'), 44, 44);
    Place(Element, X - 22, Y - 22);
    Pop := 1 + 0.15 * Pass + 0.2 * Sin(Pi * (1 - FButtonPop[0])) * Ord(FButtonPop[0] > 0) -
      0.08 * FPress * Ord(FButtonDown = 0);
    ScaleAt(Element, Pop, Pop, 22, 22);
    SetOpacity(Element, 1);
    StrokePart('PassDisc', MixColor(LineColor, DangerColor, Pass));
    Element := UIPart('LikeButton');
    ButtonCenter(1, X, Y);
    Resize(Element, 44, 44);
    Resize(Part('LikeDisc'), 44, 44);
    Place(Element, X - 22, Y - 22);
    Pop := 1 + 0.15 * Like + 0.2 * Sin(Pi * (1 - FButtonPop[1])) * Ord(FButtonPop[1] > 0) -
      0.08 * FPress * Ord(FButtonDown = 1);
    ScaleAt(Element, Pop, Pop, 22, 22);
    SetOpacity(Element, 1);
    StrokePart('LikeDisc', MixColor(LineColor, SuccessColor, Like));
  end
  else
  begin
    SetOpacity(UIPart('PassButton'), 0);
    SetOpacity(UIPart('LikeButton'), 0);
  end;
end;

function TWinUISwipeCardStack.AutomationRole: AutomationControlType;
begin
  Result := AutomationControlType.Group;
end;

function TWinUISwipeCardStack.AutomationName: string;
begin
  Result := CurrentTitle;
end;

initialization
  TWinUICustomControls.Register(TWinUISwipeCardStack, 'SwipeCardStack', SwipeActionsCategory);
  TWinUICustomControls.Register(TWinUIPinSwipeList, 'PinSwipeList', SwipeActionsCategory);
  TWinUICustomControls.Register(TWinUIPeekSwipeList, 'PeekSwipeList', SwipeActionsCategory);
  TWinUICustomControls.Register(TWinUILiquidDeleteList, 'LiquidDeleteList', SwipeActionsCategory);
  TWinUICustomControls.Register(TWinUISnoozeSwipeList, 'SnoozeSwipeList', SwipeActionsCategory);
  TWinUICustomControls.Register(TWinUIUndoSwipeList, 'UndoSwipeList', SwipeActionsCategory);

end.
