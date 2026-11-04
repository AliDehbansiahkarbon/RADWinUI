unit RADWinUI.TabBars;

{
  Ready-made animated tab bars, on the Tool Palette's Tab Bars category. In
  XAML they live in xmlns:rw="using:RADWinUI.Controls", like RADWinUI's
  other own controls.

  TWinUISlidingPillTabBar      a gradient pill springs to the tapped tab
  TWinUILiquidBulgeTabBar      the bar bulges like liquid under the active tab
  TWinUIFloatingNotchTabBar    a floating ball rides a curved notch
  TWinUIIconFillTabBar         the tapped icon fills with the accent and gets a dot
  TWinUIExpandingLabelTabBar   the active tab grows into a pill with its label
  TWinUIBubbleFloatTabBar      the tapped icon glows and bubbles float up from it

  They share TWinUITabBar: Items (Label:Icon, ...), SelectedIndex, the accent
  colours, Pages, which shows one element per tab, and SelectionChanged.
  Background, BorderBrush, Foreground (the icons of the other tabs),
  CornerRadius and Padding are the usual Control properties.

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
  RADWinUI.TabBarIcons;

const
  /// <summary>The Tool Palette category of the tab bars.</summary>
  TabBarsCategory = 'Tab Bars';

type
  /// <summary>One tab, as the bar shows it.</summary>
  TWinUITabBarItem = record
    Text: string;
    /// <summary>The icon as Items names it: Home, Heart, E80F.</summary>
    Icon: string;
    Glyph: Char;
    FilledGlyph: Char;
  end;

  /// <summary>A soft coloured glow behind a shape, cast by the compositor.</summary>
  TTabBarGlow = class
  strict private
    FSprite: ISpriteVisual;
    FShadow: IDropShadow;
  public
    constructor Create(const AHost: IUIElement; const AShape: IShape; const AColor: TWinUIColor;
      ABlur, AOpacity, AOffsetY: Single);
    procedure Resize(AWidth, AHeight: Double);
    procedure SetOpacity(AValue: Double);
  end;

  /// <summary>
  ///   The base of the tab bars: the tabs, the selection and its animation.
  ///   Each style describes its elements in XAML (StyleXaml) and places them
  ///   every frame (LayoutBar). Not registered itself.
  /// </summary>
  TWinUITabBar = class(TWinUICustomControl)
  strict private
    FHost: IPanel;
    FHostElement: IFrameworkElement;
    FContent: IFrameworkElement;
    FSizeToken: EventRegistrationToken;
    FRenderingToken: EventRegistrationToken;
    FCallbackProps: TArray<IDependencyProperty>;
    FCallbackTokens: TArray<Int64>;
    FStarted: Int64;
    FLastFrame: Int64;
    FSeed: Cardinal;
    procedure TemplateReady;
    procedure HostResized(AWidth, AHeight: Double);
    procedure Watch(const AProp: IDependencyProperty);
    procedure Unwatch;
    procedure Render;
    procedure StopRendering;
    procedure SelectionMoved;
    procedure ShowPages;
    procedure Tap(AX: Double);
    function GetItemCount: Integer;
    function GetItem(AIndex: Integer): TWinUITabBarItem;
  protected
    FItems: TArray<TWinUITabBarItem>;
    /// <summary>The size of the control.</summary>
    FWidth, FHeight: Double;
    /// <summary>The tab the selection animation comes from, and the one it goes to.</summary>
    FFrom, FTo: Integer;
    /// <summary>0 .. 1, the time of the selection animation; 1 when it is over.</summary>
    FTime: Double;
    /// <summary>Where the selection was when it started moving, as a fractional tab index.</summary>
    FStartPos: Double;
    /// <summary>How selected each tab looked when the selection started moving, 0 .. 1.</summary>
    FStartWeights: TArray<Double>;
    /// <summary>The measured size of each tab's label element L0, L1, ... (0 when there is none).</summary>
    FLabelSizes: TArray<RADWinUI.Abi.Size>;
    class procedure DefineType(AType: TWinUICustomType); override;
    /// <summary>Whether ShowLabels is on for a new bar of this style.</summary>
    class function LabelsByDefault: Boolean; virtual;
    /// <summary>Room above the bar for what rises out of it (a bulge, a ball), part of Height.</summary>
    class function DefaultHeadroom: Double; virtual;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure DetachEvents; override;
    { The style }
    /// <summary>XAML of the style's elements, the children of one Canvas.</summary>
    function StyleXaml: string; virtual; abstract;
    /// <summary>The elements of StyleXaml were created: find them with Part.</summary>
    procedure StyleLoaded; virtual;
    /// <summary>Releases what StyleLoaded kept, before the elements are made again.</summary>
    procedure StyleUnloading; virtual;
    /// <summary>Places every element for the current size, FTime and selection.</summary>
    procedure LayoutBar; virtual; abstract;
    /// <summary>Where the selection is shown right now, as a fractional tab index.</summary>
    function ShownPosition: Double; virtual;
    /// <summary>The selection moved to FTo: start what happens once, like bubbles.</summary>
    procedure SelectionStarted; virtual;
    /// <summary>Runs every frame while rendering, ASeconds after the last one.</summary>
    procedure Advance(ASeconds: Double); virtual;
    /// <summary>Something still moves after the selection animation ended.</summary>
    function StillMoving: Boolean; virtual;
    /// <summary>The tab under AX, -1 for none.</summary>
    function HitTest(AX: Double): Integer; virtual;
    { For the styles }
    function Built: Boolean;
    procedure Rebuild;
    procedure MeasureLabels;
    procedure StartRendering;
    function Part(const AName: string): IInspectable;
    function UIPart(const AName: string): IUIElement;
    function ControlIntf: IControl;
    /// <summary>How selected tab AIndex looks at FTime: 0 .. 1, may overshoot a little.</summary>
    function Weight(AIndex: Integer): Double;
    /// <summary>A pseudo-random number in 0 .. 1.</summary>
    function NextRandom: Double;
    function Headroom: Double;
    function BarTop: Double;
    function BarHeight: Double;
    function BarRadius: Double;
    function SlotLeft: Double;
    function SlotWidth: Double;
    function SlotCenter(APosition: Double): Double;
    function IconBox: Double;
    function AccentFromColor: TWinUIColor;
    function AccentToColor: TWinUIColor;
    function ActiveColor(const ADefault: TWinUIColor): TWinUIColor;
    function InactiveColor: TWinUIColor;
    function BarColor: TWinUIColor;
    /// <summary>AOnDark on a dark bar, AOnLight on a light one, so a bar reads well in either theme.</summary>
    function ForBar(const AOnDark, AOnLight: TWinUIColor): TWinUIColor;
    /// <summary>A Grid IconBox square named APrefix + index, its FontIcon named 'G' + APrefix + index.</summary>
    function IconXaml(AIndex: Integer; const APrefix: string; AFilled: Boolean; const AForeground: string = ''): string;
    function LabelXaml(AIndex: Integer; const AName: string; AFontSize: Double; ABold: Boolean): string;
    /// <summary>A Border named Bar, painted with Background, BorderBrush and the corner radius.</summary>
    function BarBorderXaml: string;
    /// <summary>Gives Bar (a Border) the control's brushes.</summary>
    procedure PaintBarBorder;
    /// <summary>A new solid brush as the Foreground of the FontIcon or TextBlock AName.</summary>
    function Tint(const AName: string; const AColor: TWinUIColor): ISolidColorBrush;
  public
    destructor Destroy; override;
    procedure SelectNext;
    procedure SelectPrevious;
    /// <summary>The label of the selected tab, '' when there is none.</summary>
    function SelectedText: string;
    property ItemCount: Integer read GetItemCount;
    property Item[AIndex: Integer]: TWinUITabBarItem read GetItem;
  published
    /// <summary>The tabs: Label:Icon separated by commas, like Home:Home, Likes:Heart.</summary>
    property Items: string index 0 read GetText write SetText;
    property SelectedIndex: Integer index 1 read GetInt32 write SetInt32;
    /// <summary>The first colour of the accent gradient (violet unless set).</summary>
    property AccentFrom: TWinUIBrush index 2 read GetBrush write SetBrush;
    /// <summary>The last colour of the accent gradient (cyan unless set).</summary>
    property AccentTo: TWinUIBrush index 3 read GetBrush write SetBrush;
    /// <summary>The icon and label of the selected tab.</summary>
    property ActiveForeground: TWinUIBrush index 4 read GetBrush write SetBrush;
    property ShowLabels: Boolean index 5 read GetBoolean write SetBoolean;
    property IconSize: Double index 6 read GetDouble write SetDouble;
    /// <summary>Milliseconds the selection takes to move.</summary>
    property AnimationDuration: Integer index 7 read GetInt32 write SetInt32;
    /// <summary>
    ///   Names of elements, one per tab, separated by commas: the selected tab's
    ///   element is shown, the others are collapsed.
    /// </summary>
    property Pages: string index 8 read GetText write SetText;
    property OnSelectionChanged: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

  /// <summary>A violet to cyan pill springs to the tapped tab, stretching as it slides.</summary>
  TWinUISlidingPillTabBar = class(TWinUITabBar)
  strict private
    FPillBox: IUIElement;
    FPill: IFrameworkElement;
    FGlow: TTabBarGlow;
    FTints: TArray<ISolidColorBrush>;
    FLabelTints: TArray<ISolidColorBrush>;
    FLeft, FRight: Double;
  protected
    function StyleXaml: string; override;
    procedure StyleLoaded; override;
    procedure StyleUnloading; override;
    procedure LayoutBar; override;
    function ShownPosition: Double; override;
  public
    destructor Destroy; override;
  end;

  /// <summary>The bar bulges like liquid under the active tab, and the bulge flows over.</summary>
  TWinUILiquidBulgeTabBar = class(TWinUITabBar)
  strict private
    FBar: IPolygon;
    FGlow: TTabBarGlow;
    FPosition: Double;
    function Bump(AX, ACenter, AHalfWidth, AHeight: Double): Double;
  protected
    class function DefaultHeadroom: Double; override;
    function StyleXaml: string; override;
    procedure StyleLoaded; override;
    procedure StyleUnloading; override;
    procedure LayoutBar; override;
    function ShownPosition: Double; override;
  public
    destructor Destroy; override;
  end;

  /// <summary>A floating ball rides a curved notch to the new tab, hopping on the way.</summary>
  TWinUIFloatingNotchTabBar = class(TWinUITabBar)
  strict private
    FBar: IPolygon;
    FBall: IFrameworkElement;
    FBallIcon: IFontIcon;
    FBallGlow: TTabBarGlow;
    FBallGlyph: Char;
    FPosition: Double;
  protected
    class function LabelsByDefault: Boolean; override;
    class function DefaultHeadroom: Double; override;
    function StyleXaml: string; override;
    procedure StyleLoaded; override;
    procedure StyleUnloading; override;
    procedure LayoutBar; override;
    function ShownPosition: Double; override;
  public
    destructor Destroy; override;
  end;

  /// <summary>The tapped icon fills violet to cyan from its centre, pops, and gains a dot.</summary>
  TWinUIIconFillTabBar = class(TWinUITabBar)
  strict private
    FTints: TArray<ISolidColorBrush>;
  protected
    function StyleXaml: string; override;
    procedure StyleLoaded; override;
    procedure StyleUnloading; override;
    procedure LayoutBar; override;
  end;

  /// <summary>The active tab grows into a pill and its label slides out. The others shrink.</summary>
  TWinUIExpandingLabelTabBar = class(TWinUITabBar)
  strict private
    FTints: TArray<ISolidColorBrush>;
    FClips: TArray<IRectangleGeometry>;
    FSlotLefts, FSlotRights: TArray<Double>;
  protected
    class function LabelsByDefault: Boolean; override;
    function StyleXaml: string; override;
    procedure StyleLoaded; override;
    procedure StyleUnloading; override;
    procedure LayoutBar; override;
    function HitTest(AX: Double): Integer; override;
  end;

  /// <summary>The tapped icon lifts and glows while bubbles float up from it and pop.</summary>
  TWinUIBubbleFloatTabBar = class(TWinUITabBar)
  strict private type
    TBubble = record
      X, Y, Delay, Life, Rise, Wobble, Phase, Size, Age: Double;
      Active: Boolean;
    end;
    TSparkle = record
      X, Y, DX, DY, Age, Life: Double;
      Active: Boolean;
    end;
  strict private
    FTints: TArray<ISolidColorBrush>;
    FBubbles: TArray<TBubble>;
    FSparkles: TArray<TSparkle>;
    procedure Pop(const ABubble: TBubble);
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    function StyleXaml: string; override;
    procedure StyleLoaded; override;
    procedure StyleUnloading; override;
    procedure LayoutBar; override;
    procedure SelectionStarted; override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
  published
    /// <summary>How many bubbles rise from the tapped icon, 0 for none.</summary>
    property BubbleCount: Integer index 9 read GetInt32 write SetInt32;
  end;

implementation

uses
  Winapi.Windows,
  System.Math;

const
  // Property indexes of TWinUITabBar
  TabItemsIndex = 0;
  TabSelectedIndexIndex = 1;
  TabAccentFromIndex = 2;
  TabAccentToIndex = 3;
  TabActiveForegroundIndex = 4;
  TabShowLabelsIndex = 5;
  TabIconSizeIndex = 6;
  TabAnimationDurationIndex = 7;
  TabPagesIndex = 8;
  // Its event
  TabSelectionChangedIndex = 0;

  // The size of a new bar, without its headroom
  DefaultBarWidth = 360;
  DefaultBarHeight = 64;
  LabelFontSize = 11;
  // How far an icon moves up when its label shows below it
  LabelLift = 7;

  XamlNamespaces = 'xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"';

  HostTemplate =
    '<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:rw="using:RADWinUI.Controls" ' +
    'TargetType="rw:%s">' +
    // Transparent, so a tap anywhere on the bar reaches the control
    '<Canvas x:Name="PART_Host" Background="Transparent" />' +
    '</ControlTemplate>';

{ Small helpers }

function Clamp01(AValue: Double): Double;
begin
  Result := Max(0, Min(1, AValue));
end;

function Lerp(AFrom, ATo, AProgress: Double): Double;
begin
  Result := AFrom + (ATo - AFrom) * AProgress;
end;

function EaseOutCubic(T: Double): Double;
begin
  T := Clamp01(T);
  Result := 1 - Power(1 - T, 3);
end;

function EaseInOutCubic(T: Double): Double;
begin
  T := Clamp01(T);
  if T < 0.5 then
    Result := 4 * T * T * T
  else
    Result := 1 - Power(-2 * T + 2, 3) / 2;
end;

/// Ease out with an overshoot past 1 that settles, like a spring
function EaseOutBack(T: Double; AOvershoot: Double = 1.4): Double;
var
  C3: Double;
begin
  T := Clamp01(T);
  C3 := AOvershoot + 1;
  Result := 1 + C3 * Power(T - 1, 3) + AOvershoot * Sqr(T - 1);
end;

function Ticks: Int64;
begin
  QueryPerformanceCounter(Result);
end;

function Seconds(AFrom, ATo: Int64): Double;
var
  Frequency: Int64;
begin
  QueryPerformanceFrequency(Frequency);
  Result := (ATo - AFrom) / Frequency;
end;

function Rgb(AR, AG, AB: Byte; AA: Byte = $FF): TWinUIColor;
begin
  Result.A := AA;
  Result.R := AR;
  Result.G := AG;
  Result.B := AB;
end;

function MixColor(const AFrom, ATo: TWinUIColor; AAmount: Double): TWinUIColor;
begin
  AAmount := Clamp01(AAmount);
  Result.A := Round(Lerp(AFrom.A, ATo.A, AAmount));
  Result.R := Round(Lerp(AFrom.R, ATo.R, AAmount));
  Result.G := Round(Lerp(AFrom.G, ATo.G, AAmount));
  Result.B := Round(Lerp(AFrom.B, ATo.B, AAmount));
end;

function WithAlpha(const AColor: TWinUIColor; AAlpha: Double): TWinUIColor;
begin
  Result := AColor;
  Result.A := Round(Clamp01(AAlpha) * AColor.A);
end;

function ColorHex(const AColor: TWinUIColor): string;
begin
  Result := '#' + IntToHex(AColor.A, 2) + IntToHex(AColor.R, 2) + IntToHex(AColor.G, 2) + IntToHex(AColor.B, 2);
end;

function Num(AValue: Double): string;
begin
  Result := FloatToStr(RoundTo(AValue, -2), TFormatSettings.Invariant);
end;

function XmlText(const AText: string): string;
begin
  Result := AText.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;');
end;

function GlyphXml(AGlyph: Char): string;
begin
  Result := '&#x' + IntToHex(Ord(AGlyph), 4) + ';';
end;

/// A two-stop LinearGradientBrush as a XAML property element body
function GradientXaml(const AFrom, ATo: TWinUIColor; AStartX, AStartY, AEndX, AEndY: Double): string;
begin
  Result := '<LinearGradientBrush StartPoint="' + Num(AStartX) + ',' + Num(AStartY) + '" EndPoint="' +
    Num(AEndX) + ',' + Num(AEndY) + '">' +
    '<GradientStop Color="' + ColorHex(AFrom) + '" Offset="0" />' +
    '<GradientStop Color="' + ColorHex(ATo) + '" Offset="1" /></LinearGradientBrush>';
end;

function BrushColor(const ABrush: IInspectable; const ADefault: TWinUIColor): TWinUIColor;
var
  Solid: ISolidColorBrush;
  Gradient: IGradientBrush;
begin
  if Supports(ABrush, ISolidColorBrush, Solid) then
    Result := Solid.Color
  else if Supports(ABrush, IGradientBrush, Gradient) and (Gradient.GradientStops.get_Size > 0) then
    Result := Gradient.GradientStops.GetAt(0).Color
  else
    Result := ADefault;
end;

function Pt(AX, AY: Double): RADWinUI.Abi.Point;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function Vec2(AX, AY: Single): RADWinUI.Abi.Vector2;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function Vec3(AX, AY, AZ: Single): RADWinUI.Abi.Vector3;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
end;

procedure Place(const AElement: IUIElement; AX, AY: Double);
begin
  if AElement = nil then
    Exit;
  RADWinUI.Abi.Canvas.SetLeft(AElement, AX);
  RADWinUI.Abi.Canvas.SetTop(AElement, AY);
end;

procedure Resize(const AElement: IInspectable; AWidth, AHeight: Double);
var
  Element: IFrameworkElement;
begin
  if Supports(AElement, IFrameworkElement, Element) then
  begin
    Element.Width := Max(0, AWidth);
    Element.Height := Max(0, AHeight);
  end;
end;

procedure SetOpacity(const AElement: IUIElement; AValue: Double);
begin
  if AElement = nil then
    Exit;
  AElement.Opacity := Clamp01(AValue);
  if AValue <= 0.001 then
    AElement.Visibility := TWinUIVisibility.Collapsed
  else
    AElement.Visibility := TWinUIVisibility.Visible;
end;

/// Scales AElement around the centre of its ASize square
procedure ScaleAbout(const AElement: IUIElement; AScale, ASize: Double);
begin
  if AElement = nil then
    Exit;
  AElement.CenterPoint := Vec3(ASize / 2, ASize / 2, 0);
  AElement.Scale := Vec3(AScale, AScale, 1);
end;

procedure SetPoints(const APolygon: IPolygon; const APoints: TArray<RADWinUI.Abi.Point>);
var
  Points: IVector_Point;
begin
  if (APolygon = nil) or (Length(APoints) = 0) then
    Exit;
  // A new collection each frame, so the shape always redraws
  Points := RADWinUI.Abi.PointCollection.New;
  Points.ReplaceAll(Length(APoints), @APoints[0]);
  APolygon.Points := Points;
end;

{
  The outline of a bar from ALeft to ARight, ATop to ABottom, with corners of
  ARadius. ATopOffset moves its upper edge: negative values rise above ATop
  (a bulge), positive ones dip below it (a notch). The upper corners follow
  the edge, so a bulge at the end of the bar stays round.
}
function BarOutline(ALeft, ARight, ATop, ABottom, ARadius: Double;
  const ATopOffset: TFunc<Double, Double>): TArray<RADWinUI.Abi.Point>;
const
  CornerSteps = 8;
  EdgeSteps = 96;
var
  Points: TArray<RADWinUI.Abi.Point>;
  Count: Integer;
  I: Integer;
  Angle, X, Level: Double;

  procedure Add(AX, AY: Double);
  begin
    if Count = Length(Points) then
      SetLength(Points, Count * 2 + 16);
    Points[Count] := Pt(AX, AY);
    Inc(Count);
  end;

begin
  Count := 0;
  Points := nil;
  ARadius := Max(0, Min(ARadius, Min((ARight - ALeft) / 2, (ABottom - ATop) / 2)));
  // Upper left corner, from the left side up to the top edge
  Level := ATop + ATopOffset(ALeft + ARadius);
  for I := 0 to CornerSteps do
  begin
    Angle := Pi / 2 * I / CornerSteps;
    Add(ALeft + ARadius - ARadius * Cos(Angle), Level + ARadius - ARadius * Sin(Angle));
  end;
  // The top edge
  for I := 1 to EdgeSteps - 1 do
  begin
    X := Lerp(ALeft + ARadius, ARight - ARadius, I / EdgeSteps);
    Add(X, ATop + ATopOffset(X));
  end;
  // Upper right corner, down to the right side
  Level := ATop + ATopOffset(ARight - ARadius);
  for I := 0 to CornerSteps do
  begin
    Angle := Pi / 2 * I / CornerSteps;
    Add(ARight - ARadius + ARadius * Sin(Angle), Level + ARadius - ARadius * Cos(Angle));
  end;
  // Lower right corner
  for I := 0 to CornerSteps do
  begin
    Angle := Pi / 2 * I / CornerSteps;
    Add(ARight - ARadius + ARadius * Cos(Angle), ABottom - ARadius + ARadius * Sin(Angle));
  end;
  // Lower left corner
  for I := 0 to CornerSteps do
  begin
    Angle := Pi / 2 + Pi / 2 * I / CornerSteps;
    Add(ALeft + ARadius + ARadius * Cos(Angle), ABottom - ARadius + ARadius * Sin(Angle));
  end;
  SetLength(Points, Count);
  Result := Points;
end;

{ TTabBarGlow }

constructor TTabBarGlow.Create(const AHost: IUIElement; const AShape: IShape; const AColor: TWinUIColor;
  ABlur, AOpacity, AOffsetY: Single);
var
  Compositor: ICompositor;
begin
  inherited Create;
  Compositor := (RADWinUI.Abi.ElementCompositionPreview.GetElementVisual(AHost) as ICompositionObject).Compositor;
  FShadow := (Compositor as ICompositor2).CreateDropShadow;
  FShadow.Mask := AShape.GetAlphaMask;
  FShadow.Color := AColor;
  FShadow.BlurRadius := ABlur;
  FShadow.Opacity := AOpacity;
  FShadow.Offset := Vec3(0, AOffsetY, 0);
  FSprite := Compositor.CreateSpriteVisual;
  (FSprite as ISpriteVisual2).Shadow := FShadow as ICompositionShadow;
  RADWinUI.Abi.ElementCompositionPreview.SetElementChildVisual(AHost, FSprite as IVisual);
end;

procedure TTabBarGlow.Resize(AWidth, AHeight: Double);
begin
  (FSprite as IVisual).Size := Vec2(Max(0, AWidth), Max(0, AHeight));
end;

procedure TTabBarGlow.SetOpacity(AValue: Double);
begin
  FShadow.Opacity := Clamp01(AValue);
end;

{ TWinUITabBar }

class procedure TWinUITabBar.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Items', TWinUIPropertyKind.Text, DefaultTabBarItems);
  AType.AddProperty('SelectedIndex', TWinUIPropertyKind.Int32, '0');
  AType.AddProperty('AccentFrom', TWinUIPropertyKind.Brush);
  AType.AddProperty('AccentTo', TWinUIPropertyKind.Brush);
  AType.AddProperty('ActiveForeground', TWinUIPropertyKind.Brush);
  AType.AddProperty('ShowLabels', TWinUIPropertyKind.Boolean, BoolToStr(LabelsByDefault, True));
  AType.AddProperty('IconSize', TWinUIPropertyKind.Double, '20');
  AType.AddProperty('AnimationDuration', TWinUIPropertyKind.Int32, '500');
  AType.AddProperty('Pages', TWinUIPropertyKind.Text);
  AType.AddEvent('SelectionChanged');
  // The Object Inspector edits Items with the tab editor
  AType.SetEditor('Items', 'tabitems');
end;

class function TWinUITabBar.LabelsByDefault: Boolean;
begin
  Result := False;
end;

class function TWinUITabBar.DefaultHeadroom: Double;
begin
  Result := 0;
end;

procedure TWinUITabBar.Initialize;
var
  Control: IControl;
  Element: IFrameworkElement;
  Corners: RADWinUI.Abi.CornerRadius;
  Edge, Inner: RADWinUI.Abi.Thickness;
begin
  UseTemplate(Format(HostTemplate, [CustomType.XamlName]));
  FSeed := Cardinal(Ticks) or 1;
  FTime := 1;
  FFrom := 0;
  FTo := 0;
  // A dark bar with grey icons unless the XAML says otherwise
  Control := ControlIntf;
  Control.Background := RADWinUI.Abi.SolidColorBrush.New(Rgb($1B, $18, $29)) as IBrush;
  Control.BorderBrush := RADWinUI.Abi.SolidColorBrush.New(Rgb($2E, $2A, $40)) as IBrush;
  Control.Foreground := RADWinUI.Abi.SolidColorBrush.New(Rgb($A7, $A3, $BC)) as IBrush;
  Edge.Left := 1;
  Edge.Top := 1;
  Edge.Right := 1;
  Edge.Bottom := 1;
  Control.BorderThickness := Edge;
  Inner.Left := 8;
  Inner.Top := 0;
  Inner.Right := 8;
  Inner.Bottom := 0;
  Control.Padding := Inner;
  Corners.TopLeft := 22;
  Corners.TopRight := 22;
  Corners.BottomRight := 22;
  Corners.BottomLeft := 22;
  Control.CornerRadius := Corners;
  Element := IntfOf(Self, IFrameworkElement) as IFrameworkElement;
  Element.Width := DefaultBarWidth;
  Element.Height := DefaultBarHeight + DefaultHeadroom;
  Loaded.Add(
    procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
    begin
      TemplateReady;
    end);
  Tapped.Add(
    procedure(Sender: TObject; E: TWinUITappedRoutedEventArgs)
    begin
      Tap(E.Intf.GetPosition(IntfOf(Self, IUIElement) as IUIElement).X);
    end);
  KeyDown.Add(
    procedure(Sender: TObject; E: TWinUIKeyRoutedEventArgs)
    begin
      case E.Key of
        TWinUIVirtualKey.Left:
          SelectPrevious;
        TWinUIVirtualKey.Right:
          SelectNext;
        TWinUIVirtualKey.Home:
          if ItemCount > 0 then
            SelectedIndex := 0;
        TWinUIVirtualKey.&End:
          if ItemCount > 0 then
            SelectedIndex := ItemCount - 1;
      else
        Exit;
      end;
      E.Handled := True;
    end);
end;

destructor TWinUITabBar.Destroy;
begin
  StopRendering;
  inherited;
end;

procedure TWinUITabBar.DetachEvents;
begin
  StopRendering;
  if (FHostElement <> nil) and (FSizeToken.Value <> 0) then
    FHostElement.remove_SizeChanged(FSizeToken);
  FSizeToken.Value := 0;
  Unwatch;
  inherited;
end;

function TWinUITabBar.ControlIntf: IControl;
begin
  Result := IntfOf(Self, IControl) as IControl;
end;

procedure TWinUITabBar.Watch(const AProp: IDependencyProperty);
var
  Self_: TWinUITabBar;
begin
  Self_ := Self;
  FCallbackProps := FCallbackProps + [AProp];
  FCallbackTokens := FCallbackTokens + [(IntfOf(Self, IDependencyObject) as IDependencyObject).
    RegisterPropertyChangedCallback(AProp, TDependencyPropertyChangedCallback.Create(
    procedure(ASender: IDependencyObject; ADp: IDependencyProperty)
    begin
      Self_.Rebuild;
    end))];
end;

procedure TWinUITabBar.Unwatch;
var
  I: Integer;
begin
  for I := 0 to High(FCallbackTokens) do
    (IntfOf(Self, IDependencyObject) as IDependencyObject).UnregisterPropertyChangedCallback(
      FCallbackProps[I], FCallbackTokens[I]);
  FCallbackProps := nil;
  FCallbackTokens := nil;
end;

procedure TWinUITabBar.TemplateReady;
var
  Self_: TWinUITabBar;
begin
  if FHost = nil then
  begin
    ApplyTemplate;
    FHostElement := TemplatePart('PART_Host') as IFrameworkElement;
    if FHostElement = nil then
      Exit;
    FHost := FHostElement as IPanel;
    Self_ := Self;
    FSizeToken := FHostElement.add_SizeChanged(TSizeChangedEventHandler.Create(
      procedure(ASender: IInspectable; AE: ISizeChangedEventArgs)
      begin
        Self_.HostResized(AE.NewSize.Width, AE.NewSize.Height);
      end));
    // The usual Control properties paint the bar too
    Watch(RADWinUI.Abi.Control.BackgroundProperty);
    Watch(RADWinUI.Abi.Control.BorderBrushProperty);
    Watch(RADWinUI.Abi.Control.BorderThicknessProperty);
    Watch(RADWinUI.Abi.Control.ForegroundProperty);
    Watch(RADWinUI.Abi.Control.CornerRadiusProperty);
    Watch(RADWinUI.Abi.Control.PaddingProperty);
    FWidth := FHostElement.ActualWidth;
    FHeight := FHostElement.ActualHeight;
    Rebuild;
  end;
  // Named pages may only exist now that the window is loaded
  ShowPages;
end;

procedure TWinUITabBar.HostResized(AWidth, AHeight: Double);
begin
  FWidth := AWidth;
  FHeight := AHeight;
  if Built then
    LayoutBar;
end;

function TWinUITabBar.Built: Boolean;
begin
  Result := FContent <> nil;
end;

procedure TWinUITabBar.Rebuild;
var
  Parsed: TArray<TTabBarItemText>;
  I: Integer;
  Content: IInspectable;
begin
  Parsed := ParseTabBarItems(Items);
  SetLength(FItems, Length(Parsed));
  for I := 0 to High(Parsed) do
  begin
    FItems[I].Text := Parsed[I].Text;
    FItems[I].Icon := Parsed[I].Icon;
    ResolveTabBarIcon(Parsed[I].Icon, FItems[I].Glyph, FItems[I].FilledGlyph);
  end;
  if Length(FItems) = 0 then
    FTo := 0
  else
    FTo := EnsureRange(SelectedIndex, 0, High(FItems));
  // A new set of elements shows the selection where it is, without moving it
  FFrom := FTo;
  FTime := 1;
  FStartPos := FTo;
  SetLength(FStartWeights, Length(FItems));
  for I := 0 to High(FStartWeights) do
    FStartWeights[I] := IfThen(I = FTo, 1, 0);
  if FHost = nil then
    Exit;
  if FContent <> nil then
    StyleUnloading;
  FContent := nil;
  FHost.Children.Clear;
  Content := RADWinUI.Abi.XamlReader.Load(WinStr('<Canvas ' + XamlNamespaces + '>' + StyleXaml + '</Canvas>'));
  FContent := Content as IFrameworkElement;
  // The control takes the taps, wherever they land
  (FContent as IUIElement).IsHitTestVisible := False;
  FHost.Children.Append(FContent as IUIElement);
  StyleLoaded;
  MeasureLabels;
  LayoutBar;
end;

procedure TWinUITabBar.MeasureLabels;
var
  I: Integer;
  Text: IUIElement;
  Big: RADWinUI.Abi.Size;
begin
  Big.Width := 10000;
  Big.Height := 10000;
  SetLength(FLabelSizes, Length(FItems));
  for I := 0 to High(FItems) do
  begin
    FLabelSizes[I].Width := 0;
    FLabelSizes[I].Height := 0;
    Text := UIPart('L' + IntToStr(I));
    if Text <> nil then
    begin
      Text.Measure(Big);
      FLabelSizes[I] := Text.DesiredSize;
    end;
  end;
end;

function TWinUITabBar.Part(const AName: string): IInspectable;
begin
  if FContent = nil then
    Exit(nil);
  Result := FContent.FindName(WinStr(AName));
end;

function TWinUITabBar.UIPart(const AName: string): IUIElement;
begin
  if not Supports(Part(AName), IUIElement, Result) then
    Result := nil;
end;

procedure TWinUITabBar.StyleLoaded;
begin
end;

procedure TWinUITabBar.StyleUnloading;
begin
end;

function TWinUITabBar.ShownPosition: Double;
begin
  Result := Lerp(FStartPos, FTo, EaseInOutCubic(FTime));
end;

procedure TWinUITabBar.SelectionStarted;
begin
end;

procedure TWinUITabBar.Advance(ASeconds: Double);
begin
end;

function TWinUITabBar.StillMoving: Boolean;
begin
  Result := False;
end;

function TWinUITabBar.HitTest(AX: Double): Integer;
begin
  if (Length(FItems) = 0) or (SlotWidth <= 0) then
    Exit(-1);
  Result := EnsureRange(Floor((AX - SlotLeft) / SlotWidth), 0, High(FItems));
end;

function TWinUITabBar.Weight(AIndex: Integer): Double;
var
  Start, Target: Double;
begin
  Target := IfThen(AIndex = FTo, 1, 0);
  if (AIndex >= 0) and (AIndex < Length(FStartWeights)) then
    Start := FStartWeights[AIndex]
  else
    Start := Target;
  if Target > Start then
    Result := Lerp(Start, Target, EaseOutBack(FTime, 1.2))
  else
    Result := Lerp(Start, Target, EaseOutCubic(FTime));
end;

function TWinUITabBar.NextRandom: Double;
begin
  // xorshift: the same look on every run would be dull, the system Random is the app's
  FSeed := FSeed xor (FSeed shl 13);
  FSeed := FSeed xor (FSeed shr 17);
  FSeed := FSeed xor (FSeed shl 5);
  Result := (FSeed and $FFFFFF) / $1000000;
end;

procedure TWinUITabBar.SelectionMoved;
var
  I: Integer;
  Weights: TArray<Double>;
  Target: Integer;
begin
  if Length(FItems) = 0 then
    Target := 0
  else
    Target := EnsureRange(SelectedIndex, 0, High(FItems));
  if not Built then
  begin
    FFrom := Target;
    FTo := Target;
    FStartPos := Target;
    FTime := 1;
    Exit;
  end;
  if Target = FTo then
    Exit;
  // Start from what is shown now, so a tap during the animation turns it around smoothly
  SetLength(Weights, Length(FItems));
  for I := 0 to High(Weights) do
    Weights[I] := Clamp01(Weight(I));
  FStartPos := ShownPosition;
  FStartWeights := Weights;
  FFrom := FTo;
  FTo := Target;
  FTime := 0;
  SelectionStarted;
  StartRendering;
end;

procedure TWinUITabBar.StartRendering;
var
  Self_: TWinUITabBar;
begin
  FStarted := Ticks;
  FLastFrame := FStarted;
  if FRenderingToken.Value <> 0 then
    Exit;
  Self_ := Self;
  // Every frame the compositor draws, until nothing moves any more
  FRenderingToken := RADWinUI.Abi.CompositionTarget.add_Rendering(TEventHandler_Object.Create(
    procedure(ASender: IInspectable; AArgs: IInspectable)
    begin
      Self_.Render;
    end));
end;

procedure TWinUITabBar.StopRendering;
begin
  if FRenderingToken.Value <> 0 then
  begin
    RADWinUI.Abi.CompositionTarget.remove_Rendering(FRenderingToken);
    FRenderingToken.Value := 0;
  end;
end;

procedure TWinUITabBar.Render;
var
  Now: Int64;
begin
  Now := Ticks;
  FTime := Clamp01(Seconds(FStarted, Now) * 1000 / Max(1, AnimationDuration));
  Advance(Min(0.1, Seconds(FLastFrame, Now)));
  FLastFrame := Now;
  if Built then
    LayoutBar;
  if (FTime >= 1) and not StillMoving then
    StopRendering;
end;

procedure TWinUITabBar.ShowPages;
var
  Names: TArray<string>;
  I: Integer;
  Page: IUIElement;
  Me: IFrameworkElement;
begin
  if (FHost = nil) or (Trim(Pages) = '') then
    Exit;
  Me := IntfOf(Self, IFrameworkElement) as IFrameworkElement;
  Names := Pages.Split([',']);
  for I := 0 to High(Names) do
  begin
    if Trim(Names[I]) = '' then
      Continue;
    if not Supports(Me.FindName(WinStr(Trim(Names[I]))), IUIElement, Page) then
      Continue;
    if I = SelectedIndex then
      Page.Visibility := TWinUIVisibility.Visible
    else
      Page.Visibility := TWinUIVisibility.Collapsed;
  end;
end;

procedure TWinUITabBar.Tap(AX: Double);
var
  Index: Integer;
begin
  Index := HitTest(AX);
  if (Index >= 0) and (Index <> SelectedIndex) then
    SelectedIndex := Index;
end;

procedure TWinUITabBar.SelectNext;
begin
  if ItemCount > 0 then
    SelectedIndex := Min(ItemCount - 1, SelectedIndex + 1);
end;

procedure TWinUITabBar.SelectPrevious;
begin
  if ItemCount > 0 then
    SelectedIndex := Max(0, SelectedIndex - 1);
end;

function TWinUITabBar.SelectedText: string;
begin
  if (SelectedIndex >= 0) and (SelectedIndex < Length(FItems)) then
    Result := FItems[SelectedIndex].Text
  else
    Result := '';
end;

function TWinUITabBar.GetItemCount: Integer;
begin
  Result := Length(FItems);
end;

function TWinUITabBar.GetItem(AIndex: Integer): TWinUITabBarItem;
begin
  Result := FItems[AIndex];
end;

procedure TWinUITabBar.PropertyChanged(AIndex: Integer);
begin
  case AIndex of
    TabItemsIndex:
      begin
        Rebuild;
        ShowPages;
      end;
    TabSelectedIndexIndex:
      begin
        SelectionMoved;
        ShowPages;
        Fire(TabSelectionChangedIndex);
      end;
    TabAccentFromIndex, TabAccentToIndex, TabActiveForegroundIndex, TabShowLabelsIndex, TabIconSizeIndex:
      Rebuild;
    TabPagesIndex:
      ShowPages;
  end;
end;

{ Geometry and colours for the styles }

function TWinUITabBar.Headroom: Double;
begin
  Result := Min(DefaultHeadroom, FHeight * 0.4);
end;

function TWinUITabBar.BarTop: Double;
begin
  Result := Headroom;
end;

function TWinUITabBar.BarHeight: Double;
begin
  Result := Max(0, FHeight - Headroom);
end;

function TWinUITabBar.BarRadius: Double;
begin
  Result := Max(0, Min(ControlIntf.CornerRadius.TopLeft, BarHeight / 2));
end;

function TWinUITabBar.SlotLeft: Double;
begin
  Result := ControlIntf.Padding.Left;
end;

function TWinUITabBar.SlotWidth: Double;
var
  Inner: RADWinUI.Abi.Thickness;
begin
  if Length(FItems) = 0 then
    Exit(0);
  Inner := ControlIntf.Padding;
  Result := Max(0, FWidth - Inner.Left - Inner.Right) / Length(FItems);
end;

function TWinUITabBar.SlotCenter(APosition: Double): Double;
begin
  Result := SlotLeft + (APosition + 0.5) * SlotWidth;
end;

function TWinUITabBar.IconBox: Double;
begin
  Result := Max(40, IconSize + 16);
end;

function TWinUITabBar.AccentFromColor: TWinUIColor;
begin
  Result := BrushColor(GetPropValue(TabAccentFromIndex), Rgb($6C, $55, $FF));
end;

function TWinUITabBar.AccentToColor: TWinUIColor;
begin
  Result := BrushColor(GetPropValue(TabAccentToIndex), Rgb($3C, $C8, $FF));
end;

function TWinUITabBar.ActiveColor(const ADefault: TWinUIColor): TWinUIColor;
begin
  Result := BrushColor(GetPropValue(TabActiveForegroundIndex), ADefault);
end;

function TWinUITabBar.InactiveColor: TWinUIColor;
begin
  Result := BrushColor(ControlIntf.Foreground, Rgb($A7, $A3, $BC));
end;

function TWinUITabBar.BarColor: TWinUIColor;
begin
  Result := BrushColor(ControlIntf.Background, Rgb($1B, $18, $29));
end;

function TWinUITabBar.ForBar(const AOnDark, AOnLight: TWinUIColor): TWinUIColor;
var
  Bar: TWinUIColor;
begin
  Bar := BarColor;
  if 0.299 * Bar.R + 0.587 * Bar.G + 0.114 * Bar.B > 150 then
    Result := AOnLight
  else
    Result := AOnDark;
end;

function TWinUITabBar.IconXaml(AIndex: Integer; const APrefix: string; AFilled: Boolean;
  const AForeground: string): string;
var
  Glyph: Char;
begin
  if AFilled then
    Glyph := FItems[AIndex].FilledGlyph
  else
    Glyph := FItems[AIndex].Glyph;
  Result := '<Grid x:Name="' + APrefix + IntToStr(AIndex) + '" Width="' + Num(IconBox) + '" Height="' +
    Num(IconBox) + '"><FontIcon x:Name="G' + APrefix + IntToStr(AIndex) + '" Glyph="' + GlyphXml(Glyph) +
    '" FontSize="' + Num(IconSize) + '" HorizontalAlignment="Center" VerticalAlignment="Center"';
  if AForeground <> '' then
    Result := Result + '><FontIcon.Foreground>' + AForeground + '</FontIcon.Foreground></FontIcon></Grid>'
  else
    Result := Result + ' /></Grid>';
end;

function TWinUITabBar.LabelXaml(AIndex: Integer; const AName: string; AFontSize: Double; ABold: Boolean): string;
begin
  Result := '<TextBlock x:Name="' + AName + '" Text="' + XmlText(FItems[AIndex].Text) + '" FontSize="' +
    Num(AFontSize) + '"';
  if ABold then
    Result := Result + ' FontWeight="SemiBold"';
  Result := Result + ' />';
end;

function TWinUITabBar.BarBorderXaml: string;
begin
  Result := '<Border x:Name="Bar" />';
end;

procedure TWinUITabBar.PaintBarBorder;
var
  Bar: IBorder;
  Control: IControl;
begin
  if not Supports(Part('Bar'), IBorder, Bar) then
    Exit;
  Control := ControlIntf;
  Bar.Background := Control.Background;
  Bar.BorderBrush := Control.BorderBrush;
  Bar.BorderThickness := Control.BorderThickness;
  Bar.CornerRadius := Control.CornerRadius;
end;

function TWinUITabBar.Tint(const AName: string; const AColor: TWinUIColor): ISolidColorBrush;
var
  Target: IInspectable;
  Icon: IIconElement;
  Text: ITextBlock;
begin
  Result := RADWinUI.Abi.SolidColorBrush.New(AColor);
  Target := Part(AName);
  if Supports(Target, IIconElement, Icon) then
    Icon.Foreground := Result as IBrush
  else if Supports(Target, ITextBlock, Text) then
    Text.Foreground := Result as IBrush;
end;

{ TWinUISlidingPillTabBar }

destructor TWinUISlidingPillTabBar.Destroy;
begin
  FreeAndNil(FGlow);
  inherited;
end;

function TWinUISlidingPillTabBar.StyleXaml: string;
var
  I: Integer;
begin
  Result := BarBorderXaml +
    '<Canvas x:Name="PillBox"><Canvas x:Name="PillGlow" />' +
    '<Rectangle x:Name="Pill"><Rectangle.Fill>' + GradientXaml(AccentFromColor, AccentToColor, 0, 0.5, 1, 0.5) +
    '</Rectangle.Fill></Rectangle></Canvas>';
  for I := 0 to High(FItems) do
  begin
    Result := Result + IconXaml(I, 'I', False);
    if ShowLabels then
      Result := Result + LabelXaml(I, 'L' + IntToStr(I), LabelFontSize, True);
  end;
end;

procedure TWinUISlidingPillTabBar.StyleLoaded;
var
  I: Integer;
begin
  PaintBarBorder;
  FPillBox := UIPart('PillBox');
  FPill := Part('Pill') as IFrameworkElement;
  FGlow := TTabBarGlow.Create(UIPart('PillGlow'), FPill as IShape, MixColor(AccentFromColor, AccentToColor, 0.4),
    18, 0.6, 3);
  SetLength(FTints, Length(FItems));
  SetLength(FLabelTints, Length(FItems));
  for I := 0 to High(FItems) do
  begin
    FTints[I] := Tint('GI' + IntToStr(I), InactiveColor);
    if ShowLabels then
      FLabelTints[I] := Tint('L' + IntToStr(I), InactiveColor);
  end;
end;

procedure TWinUISlidingPillTabBar.StyleUnloading;
begin
  FreeAndNil(FGlow);
  FPillBox := nil;
  FPill := nil;
  FTints := nil;
  FLabelTints := nil;
end;

function TWinUISlidingPillTabBar.ShownPosition: Double;
begin
  if SlotWidth <= 0 then
    Exit(FTo);
  Result := ((FLeft + FRight) / 2 - SlotLeft) / SlotWidth - 0.5;
end;

procedure TWinUISlidingPillTabBar.LayoutBar;
var
  Bar: IUIElement;
  PillWidth, PillHeight, FromCenter, ToCenter, Lead, Trail, Center, IconY, Inside: Double;
  Text: IUIElement;
  TextWidth: Double;
  I: Integer;
  Active, Inactive: TWinUIColor;
begin
  Bar := UIPart('Bar');
  Place(Bar, 0, BarTop);
  Resize(Bar, FWidth, BarHeight);
  if Length(FItems) = 0 then
  begin
    SetOpacity(FPillBox, 0);
    Exit;
  end;
  SetOpacity(FPillBox, 1);
  PillHeight := BarHeight * 0.66;
  PillWidth := Max(PillHeight, Min(SlotWidth - 8, PillHeight * 1.45));
  FromCenter := SlotCenter(FStartPos);
  ToCenter := SlotCenter(FTo);
  // The edge in front runs ahead with a spring, the one behind follows: the pill stretches
  Lead := EaseOutBack(FTime / 0.8, 1.2);
  Trail := EaseOutCubic((FTime - 0.15) / 0.85);
  if ToCenter >= FromCenter then
  begin
    FRight := Lerp(FromCenter, ToCenter, Lead) + PillWidth / 2;
    FLeft := Lerp(FromCenter, ToCenter, Trail) - PillWidth / 2;
  end
  else
  begin
    FLeft := Lerp(FromCenter, ToCenter, Lead) - PillWidth / 2;
    FRight := Lerp(FromCenter, ToCenter, Trail) + PillWidth / 2;
  end;
  if FRight - FLeft < PillHeight then
  begin
    Center := (FLeft + FRight) / 2;
    FLeft := Center - PillHeight / 2;
    FRight := Center + PillHeight / 2;
  end;
  Place(FPillBox, FLeft, BarTop + (BarHeight - PillHeight) / 2);
  Resize(FPill, FRight - FLeft, PillHeight);
  (FPill as IRectangle).RadiusX := PillHeight / 2;
  (FPill as IRectangle).RadiusY := PillHeight / 2;
  FGlow.Resize(FRight - FLeft, PillHeight);
  Active := ActiveColor(Rgb($FF, $FF, $FF));
  Inactive := InactiveColor;
  for I := 0 to High(FItems) do
  begin
    Center := SlotCenter(I);
    IconY := BarTop + BarHeight / 2;
    if ShowLabels then
      IconY := IconY - LabelLift;
    Place(UIPart('I' + IntToStr(I)), Center - IconBox / 2, IconY - IconBox / 2);
    // White while the pill is under the icon, with a soft edge
    Inside := Clamp01((Center - FLeft) / 10) * Clamp01((FRight - Center) / 10);
    FTints[I].Color := MixColor(Inactive, Active, Inside);
    if ShowLabels then
    begin
      Text := UIPart('L' + IntToStr(I));
      TextWidth := FLabelSizes[I].Width;
      Place(Text, Center - TextWidth / 2, IconY + IconSize / 2 + 2);
      FLabelTints[I].Color := MixColor(Inactive, Active, Inside);
    end;
  end;
end;

{ TWinUILiquidBulgeTabBar }

class function TWinUILiquidBulgeTabBar.DefaultHeadroom: Double;
begin
  Result := 20;
end;

destructor TWinUILiquidBulgeTabBar.Destroy;
begin
  FreeAndNil(FGlow);
  inherited;
end;

function TWinUILiquidBulgeTabBar.StyleXaml: string;
var
  I: Integer;
begin
  Result := '<Canvas x:Name="BarGlow" />' +
    '<Polygon x:Name="Bar"><Polygon.Fill>' + GradientXaml(AccentFromColor, AccentToColor, 0, 0.5, 1, 0.5) +
    '</Polygon.Fill></Polygon>';
  for I := 0 to High(FItems) do
  begin
    Result := Result + IconXaml(I, 'I', False, '<SolidColorBrush Color="' +
      ColorHex(ActiveColor(Rgb($FF, $FF, $FF))) + '" />');
    if ShowLabels then
      Result := Result + LabelXaml(I, 'L' + IntToStr(I), LabelFontSize, True);
  end;
end;

procedure TWinUILiquidBulgeTabBar.StyleLoaded;
var
  I: Integer;
begin
  FBar := Part('Bar') as IPolygon;
  FGlow := TTabBarGlow.Create(UIPart('BarGlow'), FBar as IShape, MixColor(AccentFromColor, AccentToColor, 0.35),
    24, 0.55, 6);
  if ShowLabels then
    for I := 0 to High(FItems) do
      Tint('L' + IntToStr(I), ActiveColor(Rgb($FF, $FF, $FF)));
  FPosition := FTo;
end;

procedure TWinUILiquidBulgeTabBar.StyleUnloading;
begin
  FreeAndNil(FGlow);
  FBar := nil;
end;

function TWinUILiquidBulgeTabBar.ShownPosition: Double;
begin
  Result := FPosition;
end;

function TWinUILiquidBulgeTabBar.Bump(AX, ACenter, AHalfWidth, AHeight: Double): Double;
var
  U, V: Double;
begin
  // A rounded dome with soft, concave feet: flat in the middle third, smooth at the sides
  if AHalfWidth <= 0 then
    Exit(0);
  U := Abs(AX - ACenter) / AHalfWidth;
  if U >= 1 then
    Exit(0);
  V := Clamp01((1 - U) / 0.65);
  Result := AHeight * V * V * (3 - 2 * V) * (1 - 0.12 * U * U);
end;

procedure TWinUILiquidBulgeTabBar.LayoutBar;
var
  Center, HalfWidth, BumpHeight, Stretch, IconCenter, Lift, IconY, EdgeRoom: Double;
  Text: IUIElement;
  TextWidth: Double;
  I: Integer;
  Self_: TWinUILiquidBulgeTabBar;
begin
  if FBar = nil then
    Exit;
  Self_ := Self;
  FPosition := Lerp(FStartPos, FTo, EaseInOutCubic(FTime));
  // While it travels the bulge spreads out and flattens, like liquid flowing over
  if Abs(FTo - FStartPos) > 0.01 then
    Stretch := Sin(Pi * Clamp01(FTime))
  else
    Stretch := 0;
  Center := SlotCenter(FPosition);
  HalfWidth := Max(SlotWidth, BarHeight) * 0.7 * (1 + 0.45 * Stretch);
  BumpHeight := Headroom * (1 - 0.3 * Stretch);
  // Near the ends the bulge narrows and moves in a little, so it ends before
  // the rounded corner instead of lifting it
  EdgeRoom := Min(Center, FWidth - Center) - BarRadius * 0.6;
  if HalfWidth > EdgeRoom then
  begin
    HalfWidth := Max(EdgeRoom, HalfWidth * 0.8);
    if Center < FWidth / 2 then
      Center := Center + Max(0, HalfWidth - EdgeRoom)
    else
      Center := Center - Max(0, HalfWidth - EdgeRoom);
  end;
  SetPoints(FBar, BarOutline(0, FWidth, BarTop, FHeight, BarRadius,
    function(AX: Double): Double
    begin
      Result := -Self_.Bump(AX, Center, HalfWidth, BumpHeight);
    end));
  FGlow.Resize(FWidth, FHeight);
  for I := 0 to High(FItems) do
  begin
    IconCenter := SlotCenter(I);
    // An icon rides up on the bulge under it
    Lift := Bump(IconCenter, Center, HalfWidth, BumpHeight);
    IconY := BarTop + BarHeight / 2 - Lift * 0.95;
    if ShowLabels then
      IconY := IconY - LabelLift;
    Place(UIPart('I' + IntToStr(I)), IconCenter - IconBox / 2, IconY - IconBox / 2);
    UIPart('I' + IntToStr(I)).Opacity := 0.72 + 0.28 * Clamp01(Lift / Max(1, Headroom * 0.7));
    if ShowLabels then
    begin
      Text := UIPart('L' + IntToStr(I));
      TextWidth := FLabelSizes[I].Width;
      Place(Text, IconCenter - TextWidth / 2, IconY + IconSize / 2 + 2);
      Text.Opacity := UIPart('I' + IntToStr(I)).Opacity;
    end;
  end;
end;

{ TWinUIFloatingNotchTabBar }

class function TWinUIFloatingNotchTabBar.LabelsByDefault: Boolean;
begin
  Result := True;
end;

class function TWinUIFloatingNotchTabBar.DefaultHeadroom: Double;
begin
  Result := 26;
end;

destructor TWinUIFloatingNotchTabBar.Destroy;
begin
  FreeAndNil(FBallGlow);
  inherited;
end;

function TWinUIFloatingNotchTabBar.StyleXaml: string;
var
  I: Integer;
  Active: TWinUIColor;
begin
  Active := ActiveColor(Rgb($FF, $FF, $FF));
  Result := '<Polygon x:Name="Bar" />';
  for I := 0 to High(FItems) do
  begin
    Result := Result + IconXaml(I, 'I', False);
    if ShowLabels then
      Result := Result + LabelXaml(I, 'L' + IntToStr(I), LabelFontSize + 1, True);
  end;
  Result := Result +
    '<Canvas x:Name="BallBox"><Canvas x:Name="BallGlow" />' +
    '<Ellipse x:Name="Ball"><Ellipse.Fill>' + GradientXaml(AccentFromColor, AccentToColor, 0.15, 0, 0.85, 1) +
    '</Ellipse.Fill></Ellipse>' +
    '<Grid x:Name="BallIconBox"><FontIcon x:Name="BallIcon" FontSize="' + Num(IconSize) +
    '" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="' + ColorHex(Active) + '" /></Grid>' +
    '</Canvas>';
end;

procedure TWinUIFloatingNotchTabBar.StyleLoaded;
var
  I: Integer;
  Control: IControl;
begin
  FBar := Part('Bar') as IPolygon;
  Control := ControlIntf;
  (FBar as IShape).Fill := Control.Background;
  (FBar as IShape).Stroke := Control.BorderBrush;
  (FBar as IShape).StrokeThickness := Control.BorderThickness.Top;
  FBall := Part('Ball') as IFrameworkElement;
  FBallIcon := Part('BallIcon') as IFontIcon;
  FBallGlow := TTabBarGlow.Create(UIPart('BallGlow'), FBall as IShape, MixColor(AccentFromColor, AccentToColor, 0.4),
    16, 0.7, 3);
  for I := 0 to High(FItems) do
  begin
    Tint('GI' + IntToStr(I), InactiveColor);
    if ShowLabels then
      Tint('L' + IntToStr(I), MixColor(InactiveColor, ForBar(Rgb($FF, $FF, $FF), Rgb($1B, $18, $29)), 0.55));
  end;
  FBallGlyph := #0;
  FPosition := FTo;
end;

procedure TWinUIFloatingNotchTabBar.StyleUnloading;
begin
  FreeAndNil(FBallGlow);
  FBar := nil;
  FBall := nil;
  FBallIcon := nil;
end;

function TWinUIFloatingNotchTabBar.ShownPosition: Double;
begin
  Result := FPosition;
end;

procedure TWinUIFloatingNotchTabBar.LayoutBar;
var
  Diameter, Radius, Gap, Hop, BallX, BallY, RestY, Squash, NotchRadius, Center, Distance, IconY, Fade: Double;
  Text, Icon: IUIElement;
  TextWidth: Double;
  I: Integer;
  Glyph: Char;
begin
  if FBar = nil then
    Exit;
  Diameter := Min(BarHeight * 0.68, SlotWidth * 0.8);
  Radius := Diameter / 2;
  Gap := Max(3, Diameter * 0.12);
  Hop := Headroom * 0.45;
  FPosition := Lerp(FStartPos, FTo, EaseInOutCubic(FTime));
  BallX := SlotCenter(FPosition);
  // The ball sits just above the bar's edge and hops up while it travels
  RestY := BarTop + Radius * 0.15;
  if Abs(FTo - FStartPos) > 0.01 then
    BallY := RestY - Hop * Sin(Pi * Clamp01(FTime))
  else
    BallY := RestY;
  NotchRadius := Radius + Gap;
  SetPoints(FBar, BarOutline(0.5, FWidth - 0.5, BarTop + 0.5, FHeight - 0.5, BarRadius,
    function(AX: Double): Double
    var
      DX, Circle, Diff, H: Double;
    begin
      // How deep the circle around the ball reaches into the bar, with a smooth
      // shoulder where it meets the edge
      DX := Abs(AX - BallX);
      if DX < NotchRadius then
        Circle := (BallY - BarTop) + Sqrt(Sqr(NotchRadius) - Sqr(DX))
      else
        Circle := (BallY - BarTop) - (DX - NotchRadius) * 3;
      Diff := Abs(Circle);
      H := Max(Gap * 2 - Diff, 0) / (Gap * 2);
      Result := Max(Circle, 0) + H * H * Gap * 2 / 4;
    end));
  // The ball
  Squash := 1 - 0.12 * Sin(Pi * Clamp01(FTime)) * IfThen(Abs(FTo - FStartPos) > 0.01, 1, 0);
  Place(UIPart('BallBox'), BallX - Radius, BallY - Radius);
  Resize(FBall, Diameter, Diameter);
  Resize(Part('BallIconBox'), Diameter, Diameter);
  FBallGlow.Resize(Diameter, Diameter);
  ScaleAbout(UIPart('BallBox'), Squash, Diameter);
  // Its icon changes halfway
  if Length(FItems) > 0 then
  begin
    if FTime < 0.5 then
      Glyph := FItems[EnsureRange(Round(FStartPos), 0, High(FItems))].FilledGlyph
    else
      Glyph := FItems[FTo].FilledGlyph;
    if Glyph <> FBallGlyph then
    begin
      FBallIcon.Glyph := WinStr(Glyph);
      FBallGlyph := Glyph;
    end;
    UIPart('BallBox').Visibility := TWinUIVisibility.Visible;
  end
  else
    UIPart('BallBox').Visibility := TWinUIVisibility.Collapsed;
  for I := 0 to High(FItems) do
  begin
    Center := SlotCenter(I);
    Icon := UIPart('I' + IntToStr(I));
    IconY := BarTop + BarHeight / 2;
    Place(Icon, Center - IconBox / 2, IconY - IconBox / 2);
    // An icon makes room while the ball is over it
    Distance := Abs(Center - BallX);
    SetOpacity(Icon, Clamp01((Distance - Radius * 0.6) / (SlotWidth * 0.45)));
    if ShowLabels then
    begin
      Text := UIPart('L' + IntToStr(I));
      TextWidth := FLabelSizes[I].Width;
      Place(Text, Center - TextWidth / 2, FHeight - BarHeight * 0.36);
      // The new tab's label fades in as the old one fades out
      if I = FTo then
        Fade := Clamp01((FTime - 0.45) / 0.55)
      else if (I = FFrom) and (FTime < 1) then
        Fade := 1 - Clamp01(FTime / 0.4)
      else
        Fade := 0;
      SetOpacity(Text, Fade);
    end;
  end;
end;

{ TWinUIIconFillTabBar }

function TWinUIIconFillTabBar.StyleXaml: string;
var
  I: Integer;
begin
  Result := BarBorderXaml;
  for I := 0 to High(FItems) do
  begin
    Result := Result + IconXaml(I, 'I', False) +
      IconXaml(I, 'F', True, GradientXaml(AccentFromColor, AccentToColor, 0, 0, 1, 1)) +
      '<Rectangle x:Name="D' + IntToStr(I) + '" Height="4" RadiusX="2" RadiusY="2"><Rectangle.Fill>' +
      GradientXaml(AccentFromColor, AccentToColor, 0, 0.5, 1, 0.5) + '</Rectangle.Fill></Rectangle>';
    if ShowLabels then
      Result := Result + LabelXaml(I, 'L' + IntToStr(I), LabelFontSize, True);
  end;
end;

procedure TWinUIIconFillTabBar.StyleLoaded;
var
  I: Integer;
begin
  PaintBarBorder;
  SetLength(FTints, Length(FItems));
  for I := 0 to High(FItems) do
  begin
    Tint('GI' + IntToStr(I), InactiveColor);
    if ShowLabels then
      FTints[I] := Tint('L' + IntToStr(I), InactiveColor);
  end;
end;

procedure TWinUIIconFillTabBar.StyleUnloading;
begin
  FTints := nil;
end;

procedure TWinUIIconFillTabBar.LayoutBar;
var
  Bar, Outline, Fill, Dot, Text: IUIElement;
  I: Integer;
  W, Shown, Center, IconY, DotY, TextWidth, Pop: Double;
begin
  Bar := UIPart('Bar');
  Place(Bar, 0, BarTop);
  Resize(Bar, FWidth, BarHeight);
  for I := 0 to High(FItems) do
  begin
    W := Weight(I);
    Shown := Clamp01(W);
    Center := SlotCenter(I);
    IconY := BarTop + BarHeight / 2 - 3;
    if ShowLabels then
      IconY := IconY - LabelLift + 2;
    Outline := UIPart('I' + IntToStr(I));
    Fill := UIPart('F' + IntToStr(I));
    Place(Outline, Center - IconBox / 2, IconY - IconBox / 2);
    Place(Fill, Center - IconBox / 2, IconY - IconBox / 2);
    // The fill grows from the icon's centre and pops past its size before it settles
    if I = FTo then
      Pop := 1 + 0.22 * Sin(Pi * Clamp01((FTime - 0.25) / 0.75))
    else
      Pop := 1;
    ScaleAbout(Fill, Max(0, W) * Pop, IconBox);
    SetOpacity(Fill, Clamp01(Shown * 2));
    SetOpacity(Outline, 1 - Shown);
    Dot := UIPart('D' + IntToStr(I));
    Resize(Dot, 14 * Max(0, W), 4);
    DotY := IconY + IconSize / 2 + 6;
    if ShowLabels then
    begin
      Text := UIPart('L' + IntToStr(I));
      TextWidth := FLabelSizes[I].Width;
      Place(Text, Center - TextWidth / 2, IconY + IconSize / 2 + 2);
      FTints[I].Color := MixColor(InactiveColor, ActiveColor(MixColor(AccentFromColor, AccentToColor, 0.5)), Shown);
      DotY := IconY + IconSize / 2 + 19;
    end;
    Place(Dot, Center - 7 * Max(0, W), DotY);
    SetOpacity(Dot, Shown);
  end;
end;

{ TWinUIExpandingLabelTabBar }

class function TWinUIExpandingLabelTabBar.LabelsByDefault: Boolean;
begin
  Result := True;
end;

function TWinUIExpandingLabelTabBar.StyleXaml: string;
var
  I: Integer;
  Fill, Edge: TWinUIColor;
begin
  Fill := MixColor(BarColor, AccentFromColor, 0.32);
  Edge := MixColor(MixColor(BarColor, AccentFromColor, 0.45), Rgb($FF, $FF, $FF), 0.18);
  Result := BarBorderXaml;
  for I := 0 to High(FItems) do
  begin
    Result := Result + '<Border x:Name="P' + IntToStr(I) + '" Background="' + ColorHex(Fill) + '" BorderBrush="' +
      ColorHex(Edge) + '" BorderThickness="1" />';
    if ShowLabels then
      Result := Result + '<TextBlock x:Name="L' + IntToStr(I) + '" Text="' + XmlText(FItems[I].Text) +
        '" FontSize="13" FontWeight="SemiBold"><TextBlock.Clip><RectangleGeometry x:Name="C' + IntToStr(I) +
        '" /></TextBlock.Clip></TextBlock>';
    Result := Result + IconXaml(I, 'I', False);
  end;
end;

procedure TWinUIExpandingLabelTabBar.StyleLoaded;
var
  I: Integer;
begin
  PaintBarBorder;
  SetLength(FTints, Length(FItems));
  SetLength(FClips, Length(FItems));
  for I := 0 to High(FItems) do
  begin
    FTints[I] := Tint('GI' + IntToStr(I), InactiveColor);
    if ShowLabels then
    begin
      Tint('L' + IntToStr(I), ActiveColor(ForBar(Rgb($F2, $F0, $FF), MixColor(AccentFromColor, Rgb(0, 0, 0), 0.3))));
      FClips[I] := Part('C' + IntToStr(I)) as IRectangleGeometry;
    end;
  end;
end;

procedure TWinUIExpandingLabelTabBar.StyleUnloading;
begin
  FTints := nil;
  FClips := nil;
end;

function TWinUIExpandingLabelTabBar.HitTest(AX: Double): Integer;
var
  I: Integer;
begin
  for I := 0 to High(FSlotLefts) do
    if (AX >= FSlotLefts[I]) and (AX < FSlotRights[I]) then
      Exit(I);
  Result := inherited HitTest(AX);
end;

procedure TWinUIExpandingLabelTabBar.LayoutBar;
const
  PillGap = 8;
var
  Bar, Pill, Icon, Text: IUIElement;
  I, Count: Integer;
  Weights, Extras: TArray<Double>;
  Inner, TotalExtra, Base, X, SlotW, PillHeight, PillWidth, PillLeft, Top, Reveal: Double;
  Corners: RADWinUI.Abi.CornerRadius;
  Area: RADWinUI.Abi.Rect;
  Padding: RADWinUI.Abi.Thickness;
begin
  Bar := UIPart('Bar');
  Place(Bar, 0, BarTop);
  Resize(Bar, FWidth, BarHeight);
  Count := Length(FItems);
  SetLength(FSlotLefts, Count);
  SetLength(FSlotRights, Count);
  if Count = 0 then
    Exit;
  Padding := ControlIntf.Padding;
  Inner := Max(0, FWidth - Padding.Left - Padding.Right);
  PillHeight := Min(BarHeight * 0.66, 44);
  SetLength(Weights, Count);
  SetLength(Extras, Count);
  TotalExtra := 0;
  for I := 0 to Count - 1 do
  begin
    Weights[I] := Max(0, Weight(I));
    // What the label adds to the pill when the tab is selected
    if ShowLabels and (FLabelSizes[I].Width > 0) then
      Extras[I] := Weights[I] * (FLabelSizes[I].Width + PillGap + 4)
    else
      Extras[I] := 0;
    TotalExtra := TotalExtra + Extras[I];
  end;
  // The other tabs share what is left
  Base := Max(PillHeight, (Inner - TotalExtra) / Count);
  X := Padding.Left;
  Corners.TopLeft := PillHeight / 2;
  Corners.TopRight := PillHeight / 2;
  Corners.BottomRight := PillHeight / 2;
  Corners.BottomLeft := PillHeight / 2;
  Top := BarTop + (BarHeight - PillHeight) / 2;
  for I := 0 to Count - 1 do
  begin
    SlotW := Base + Extras[I];
    FSlotLefts[I] := X;
    FSlotRights[I] := X + SlotW;
    PillWidth := PillHeight + Extras[I];
    PillLeft := X + (SlotW - PillWidth) / 2;
    Pill := UIPart('P' + IntToStr(I));
    Place(Pill, PillLeft, Top);
    Resize(Pill, PillWidth, PillHeight);
    (Pill as IBorder).CornerRadius := Corners;
    SetOpacity(Pill, Clamp01(Weights[I] * 1.6));
    Icon := UIPart('I' + IntToStr(I));
    Place(Icon, PillLeft + PillHeight / 2 - IconBox / 2, Top + PillHeight / 2 - IconBox / 2);
    FTints[I].Color := MixColor(InactiveColor, ActiveColor(ForBar(Rgb($F2, $F0, $FF), MixColor(AccentFromColor, Rgb(0, 0, 0), 0.3))),
      Clamp01(Weights[I]));
    if ShowLabels then
    begin
      Text := UIPart('L' + IntToStr(I));
      Place(Text, PillLeft + PillHeight / 2 + IconSize / 2 + PillGap - 2,
        Top + (PillHeight - FLabelSizes[I].Height) / 2);
      // The label slides out of the icon: the clip opens from the left
      Reveal := Max(0, Extras[I] - PillGap);
      Area.X := 0;
      Area.Y := 0;
      Area.Width := Reveal;
      Area.Height := 100;
      if FClips[I] <> nil then
        FClips[I].Rect := Area;
      SetOpacity(Text, Clamp01((Weights[I] - 0.25) / 0.6));
    end;
    X := X + SlotW;
  end;
end;

{ TWinUIBubbleFloatTabBar }

class procedure TWinUIBubbleFloatTabBar.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('BubbleCount', TWinUIPropertyKind.Int32, '7');
end;

const
  MaxBubbles = 16;
  SparklesPerBubble = 4;

function TWinUIBubbleFloatTabBar.StyleXaml: string;
var
  I: Integer;
  Cyan: TWinUIColor;
begin
  Cyan := AccentToColor;
  Result := BarBorderXaml;
  for I := 0 to High(FItems) do
  begin
    if ShowLabels then
      Result := Result + LabelXaml(I, 'L' + IntToStr(I), LabelFontSize, True);
    Result := Result +
      // The halo behind the icon: a radial fade of the accent
      '<Ellipse x:Name="H' + IntToStr(I) + '" Width="46" Height="46"><Ellipse.Fill><RadialGradientBrush>' +
      '<GradientStop Color="' + ColorHex(WithAlpha(Cyan, 0.55)) + '" Offset="0" />' +
      '<GradientStop Color="' + ColorHex(WithAlpha(Cyan, 0.18)) + '" Offset="0.55" />' +
      '<GradientStop Color="' + ColorHex(WithAlpha(Cyan, 0)) + '" Offset="1" />' +
      '</RadialGradientBrush></Ellipse.Fill></Ellipse>' +
      IconXaml(I, 'I', False) +
      '<Ellipse x:Name="D' + IntToStr(I) + '" Width="5" Height="5" Fill="' + ColorHex(Cyan) + '" />';
  end;
  Result := Result + '<Canvas x:Name="Bubbles">';
  for I := 0 to MaxBubbles - 1 do
    Result := Result + '<Ellipse x:Name="B' + IntToStr(I) + '" Stroke="' + ColorHex(WithAlpha(Cyan, 0.85)) +
      '" StrokeThickness="1.2" Fill="' + ColorHex(WithAlpha(Cyan, 0.12)) + '" Visibility="Collapsed" />';
  for I := 0 to MaxBubbles * SparklesPerBubble - 1 do
    Result := Result + '<Ellipse x:Name="S' + IntToStr(I) + '" Width="2.5" Height="2.5" Fill="' +
      ColorHex(WithAlpha(Cyan, 0.9)) + '" Visibility="Collapsed" />';
  Result := Result + '</Canvas>';
end;

procedure TWinUIBubbleFloatTabBar.StyleLoaded;
var
  I: Integer;
begin
  PaintBarBorder;
  SetLength(FTints, Length(FItems));
  for I := 0 to High(FItems) do
  begin
    FTints[I] := Tint('GI' + IntToStr(I), InactiveColor);
    if ShowLabels then
      Tint('L' + IntToStr(I), InactiveColor);
  end;
  SetLength(FBubbles, MaxBubbles);
  SetLength(FSparkles, MaxBubbles * SparklesPerBubble);
  for I := 0 to High(FBubbles) do
    FBubbles[I].Active := False;
  for I := 0 to High(FSparkles) do
    FSparkles[I].Active := False;
end;

procedure TWinUIBubbleFloatTabBar.StyleUnloading;
begin
  FTints := nil;
  FBubbles := nil;
  FSparkles := nil;
end;

procedure TWinUIBubbleFloatTabBar.SelectionStarted;
var
  I, Started: Integer;
  X, Y: Double;
begin
  if (FTo < 0) or (FTo > High(FItems)) then
    Exit;
  X := SlotCenter(FTo);
  Y := BarTop + BarHeight / 2 - IconSize / 2;
  Started := 0;
  for I := 0 to High(FBubbles) do
  begin
    if Started >= Min(BubbleCount, MaxBubbles) then
      Break;
    if FBubbles[I].Active then
      Continue;
    FBubbles[I].Active := True;
    FBubbles[I].X := X + (NextRandom - 0.5) * 16;
    FBubbles[I].Y := Y;
    FBubbles[I].Delay := NextRandom * 0.25;
    FBubbles[I].Life := 0.7 + NextRandom * 0.45;
    FBubbles[I].Rise := 30 + NextRandom * 26;
    FBubbles[I].Wobble := 3 + NextRandom * 5;
    FBubbles[I].Phase := NextRandom * 2 * Pi;
    FBubbles[I].Size := 5 + NextRandom * 7;
    FBubbles[I].Age := 0;
    Inc(Started);
  end;
end;

procedure TWinUIBubbleFloatTabBar.Pop(const ABubble: TBubble);
var
  I, Added: Integer;
  Angle: Double;
begin
  Added := 0;
  for I := 0 to High(FSparkles) do
  begin
    if Added >= SparklesPerBubble then
      Break;
    if FSparkles[I].Active then
      Continue;
    Angle := (Added + NextRandom * 0.6) * 2 * Pi / SparklesPerBubble;
    FSparkles[I].Active := True;
    FSparkles[I].X := ABubble.X + ABubble.Wobble * Sin(ABubble.Phase + 2 * Pi * 1.5 * ABubble.Life);
    FSparkles[I].Y := ABubble.Y - ABubble.Rise;
    FSparkles[I].DX := Cos(Angle) * (ABubble.Size * 0.5 + 6);
    FSparkles[I].DY := Sin(Angle) * (ABubble.Size * 0.5 + 6);
    FSparkles[I].Age := 0;
    FSparkles[I].Life := 0.22;
    Inc(Added);
  end;
end;

procedure TWinUIBubbleFloatTabBar.Advance(ASeconds: Double);
var
  I: Integer;
begin
  for I := 0 to High(FBubbles) do
    if FBubbles[I].Active then
    begin
      FBubbles[I].Age := FBubbles[I].Age + ASeconds;
      // Rising, then a short pop that scatters a few sparkles
      if FBubbles[I].Age >= FBubbles[I].Delay + FBubbles[I].Life + 0.12 then
        FBubbles[I].Active := False
      else if (FBubbles[I].Age - ASeconds < FBubbles[I].Delay + FBubbles[I].Life) and
        (FBubbles[I].Age >= FBubbles[I].Delay + FBubbles[I].Life) then
        Pop(FBubbles[I]);
    end;
  for I := 0 to High(FSparkles) do
    if FSparkles[I].Active then
    begin
      FSparkles[I].Age := FSparkles[I].Age + ASeconds;
      if FSparkles[I].Age >= FSparkles[I].Life then
        FSparkles[I].Active := False;
    end;
end;

function TWinUIBubbleFloatTabBar.StillMoving: Boolean;
var
  I: Integer;
begin
  for I := 0 to High(FBubbles) do
    if FBubbles[I].Active then
      Exit(True);
  for I := 0 to High(FSparkles) do
    if FSparkles[I].Active then
      Exit(True);
  Result := False;
end;

procedure TWinUIBubbleFloatTabBar.LayoutBar;
var
  Bar, Icon, Halo, Dot, Text, Element: IUIElement;
  I: Integer;
  W, Shown, Center, IconY, Lift, T, Size, Grow, X, Y, TextWidth: Double;
  Active: TWinUIColor;
begin
  Bar := UIPart('Bar');
  Place(Bar, 0, BarTop);
  Resize(Bar, FWidth, BarHeight);
  Active := ActiveColor(ForBar(MixColor(AccentToColor, Rgb($FF, $FF, $FF), 0.75),
    MixColor(MixColor(AccentFromColor, AccentToColor, 0.6), Rgb(0, 0, 0), 0.15)));
  for I := 0 to High(FItems) do
  begin
    W := Weight(I);
    Shown := Clamp01(W);
    Center := SlotCenter(I);
    IconY := BarTop + BarHeight / 2;
    if ShowLabels then
      IconY := IconY - LabelLift;
    // The selected icon lifts a little and glows
    Lift := 4 * W;
    Icon := UIPart('I' + IntToStr(I));
    Place(Icon, Center - IconBox / 2, IconY - Lift - IconBox / 2);
    FTints[I].Color := MixColor(InactiveColor, Active, Shown);
    Halo := UIPart('H' + IntToStr(I));
    Place(Halo, Center - 23, IconY - Lift - 23);
    SetOpacity(Halo, Shown);
    ScaleAbout(Halo, 0.6 + 0.4 * Shown, 46);
    Dot := UIPart('D' + IntToStr(I));
    if ShowLabels then
    begin
      Text := UIPart('L' + IntToStr(I));
      TextWidth := FLabelSizes[I].Width;
      Place(Text, Center - TextWidth / 2, IconY + IconSize / 2 + 2);
      Place(Dot, Center - 2.5, IconY + IconSize / 2 + 18);
    end
    else
      Place(Dot, Center - 2.5, IconY + IconSize / 2 + 7);
    SetOpacity(Dot, Shown);
  end;
  for I := 0 to High(FBubbles) do
  begin
    Element := UIPart('B' + IntToStr(I));
    if (Element = nil) then
      Continue;
    if not FBubbles[I].Active or (FBubbles[I].Age < FBubbles[I].Delay) then
    begin
      SetOpacity(Element, 0);
      Continue;
    end;
    T := (FBubbles[I].Age - FBubbles[I].Delay) / FBubbles[I].Life;
    Size := FBubbles[I].Size;
    if T <= 1 then
    begin
      X := FBubbles[I].X + FBubbles[I].Wobble * Sin(FBubbles[I].Phase + 2 * Pi * 1.5 * T * FBubbles[I].Life);
      Y := FBubbles[I].Y - FBubbles[I].Rise * EaseOutCubic(T);
      Grow := 0.5 + 0.5 * EaseOutCubic(T * 2);
      SetOpacity(Element, Clamp01(T * 6));
    end
    else
    begin
      // The pop: a quick swell as it fades
      X := FBubbles[I].X + FBubbles[I].Wobble * Sin(FBubbles[I].Phase + 2 * Pi * 1.5 * FBubbles[I].Life);
      Y := FBubbles[I].Y - FBubbles[I].Rise;
      Grow := 1 + (T - 1) * FBubbles[I].Life / 0.12 * 0.5;
      SetOpacity(Element, 1 - Clamp01((T - 1) * FBubbles[I].Life / 0.12));
    end;
    Resize(Element, Size, Size);
    Place(Element, X - Size / 2, Y - Size / 2);
    ScaleAbout(Element, Grow, Size);
  end;
  for I := 0 to High(FSparkles) do
  begin
    Element := UIPart('S' + IntToStr(I));
    if Element = nil then
      Continue;
    if not FSparkles[I].Active then
    begin
      SetOpacity(Element, 0);
      Continue;
    end;
    T := Clamp01(FSparkles[I].Age / FSparkles[I].Life);
    Place(Element, FSparkles[I].X + FSparkles[I].DX * EaseOutCubic(T) - 1.25,
      FSparkles[I].Y + FSparkles[I].DY * EaseOutCubic(T) - 1.25);
    SetOpacity(Element, 1 - T);
  end;
end;

initialization
  TWinUICustomControls.Register(TWinUISlidingPillTabBar, 'SlidingPillTabBar', TabBarsCategory);
  TWinUICustomControls.Register(TWinUILiquidBulgeTabBar, 'LiquidBulgeTabBar', TabBarsCategory);
  TWinUICustomControls.Register(TWinUIFloatingNotchTabBar, 'FloatingNotchTabBar', TabBarsCategory);
  TWinUICustomControls.Register(TWinUIIconFillTabBar, 'IconFillTabBar', TabBarsCategory);
  TWinUICustomControls.Register(TWinUIExpandingLabelTabBar, 'ExpandingLabelTabBar', TabBarsCategory);
  TWinUICustomControls.Register(TWinUIBubbleFloatTabBar, 'BubbleFloatTabBar', TabBarsCategory);
end.
