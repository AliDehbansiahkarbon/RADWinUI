unit RADWinUI.DrawnControls;

{
  The base of RADWinUI's drawn controls: the text fields, swipe actions,
  pagination and progress steps on the Tool Palette. Each control describes
  its elements in XAML (StyleXaml) and places them every frame while
  something moves (LayoutControl), on CompositionTarget.Rendering.

  A control may also keep live elements (BuildLive), such as the text boxes
  of a text field: they stay when the drawn elements are made again for a new
  colour or theme, so typing, the caret and the focus are kept.

  Colours follow the app's theme: with no Background the control paints a
  dark or light surface of its own, and the text follows Foreground.

  The helpers below (easing, colours, points) are for the controls built on
  it. Using this unit registers nothing.
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
  RADWinUI.CustomControls;

type
  /// <summary>A soft coloured glow behind a shape, cast by the compositor.</summary>
  TDrawnGlow = class
  strict private
    FSprite: ISpriteVisual;
    FShadow: IDropShadow;
  public
    constructor Create(const AHost: IUIElement; const AShape: IShape; const AColor: TWinUIColor;
      ABlur, AOpacity, AOffsetY: Single);
    procedure Resize(AWidth, AHeight: Double);
    procedure SetOpacity(AValue: Double);
    procedure SetColor(const AColor: TWinUIColor);
  end;

  /// <summary>
  ///   The base of the drawn controls: the elements, the theme colours, the
  ///   input and the animation loop. Not registered itself.
  /// </summary>
  TWinUIDrawnControl = class(TWinUICustomControl)
  strict private
    FRoot: IFrameworkElement;
    FHost: IPanel;
    FLive: IPanel;
    FContent: IFrameworkElement;
    FSizeToken: EventRegistrationToken;
    FThemeToken: EventRegistrationToken;
    FRenderingToken: EventRegistrationToken;
    FCallbackProps: TArray<IDependencyProperty>;
    FCallbackTokens: TArray<Int64>;
    FLastFrame: Int64;
    FSeed: Cardinal;
    FKeyDown: Boolean;
    FLiveBuilt: Boolean;
    procedure TemplateReady;
    procedure HostResized(AWidth, AHeight: Double);
    procedure Watch(const AProp: IDependencyProperty);
    procedure Unwatch;
    procedure Render;
    procedure StopRendering;
    function PointerAt(E: TWinUIPointerRoutedEventArgs): RADWinUI.Abi.Point;
  protected
    /// <summary>The size of the control.</summary>
    FWidth, FHeight: Double;
    /// <summary>Seconds of animation so far, it only runs while something moves.</summary>
    FClock: Double;
    /// <summary>The pointer or Enter/Space holds the control down.</summary>
    FPressed: Boolean;
    FHovered: Boolean;
    /// <summary>Where the pointer is over the control, while FHovered.</summary>
    FHoverX, FHoverY: Double;
    /// <summary>0 .. 1, how pressed the control looks; follows FPressed.</summary>
    FPress: Double;
    /// <summary>0 .. 1, how hovered the control looks; follows FHovered.</summary>
    FHover: Double;
    /// <summary>The window is showing the control.</summary>
    FLoaded: Boolean;
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultWidth: Double; virtual;
    class function DefaultHeight: Double; virtual;
    /// <summary>The accent colours unless AccentFrom and AccentTo are set.</summary>
    class function DefaultAccentFrom: TWinUIColor; virtual;
    class function DefaultAccentTo: TWinUIColor; virtual;
    /// <summary>The control itself takes the focus (Tab) and keys. False for text fields, whose boxes take it.</summary>
    class function TakesFocus: Boolean; virtual;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure DetachEvents; override;
    { The look }
    /// <summary>XAML of the drawn elements, the children of one Canvas.</summary>
    function StyleXaml: string; virtual; abstract;
    /// <summary>The elements of StyleXaml were created: find them with Part.</summary>
    procedure StyleLoaded; virtual;
    /// <summary>Releases what StyleLoaded kept, before the elements are made again.</summary>
    procedure StyleUnloading; virtual;
    /// <summary>Creates the live elements once, into LivePanel (above the drawn ones).</summary>
    procedure BuildLive; virtual;
    /// <summary>Gives the live elements the current colours, after every rebuild.</summary>
    procedure StyleLive; virtual;
    /// <summary>Places every element for the current size and state.</summary>
    procedure LayoutControl; virtual; abstract;
    /// <summary>Runs every frame while rendering, ASeconds after the last one. Call inherited.</summary>
    procedure Advance(ASeconds: Double); virtual;
    /// <summary>Something still moves, so rendering goes on. Call inherited.</summary>
    function StillMoving: Boolean; virtual;
    { Input }
    /// <summary>A press at AX, AY. False ignores it (no capture, no press look).</summary>
    function PointerDown(AX, AY: Double): Boolean; virtual;
    /// <summary>The pointer moved while pressed.</summary>
    procedure PointerDrag(AX, AY: Double); virtual;
    /// <summary>The press ended, AInside when the pointer was still over the control.</summary>
    procedure PointerUp(AX, AY: Double; AInside: Boolean); virtual;
    /// <summary>The pointer moved over the control without a press.</summary>
    procedure PointerHover(AX, AY: Double); virtual;
    /// <summary>A key went down while the control has the focus. True when it was used.</summary>
    function KeyPressed(AKey: TWinUIVirtualKey): Boolean; virtual;
    { For the controls }
    function Built: Boolean;
    procedure Rebuild;
    procedure StartRendering;
    function Part(const AName: string): IInspectable;
    function UIPart(const AName: string): IUIElement;
    function ControlIntf: IControl;
    function ElementIntf: IFrameworkElement;
    /// <summary>The panel of the live elements, above the drawn ones. nil before the template is applied.</summary>
    function LivePanel: IPanel;
    /// <summary>Loads AXaml (one element with the XAML namespaces added) and adds it to LivePanel.</summary>
    function AddLive(const AXaml: string): IUIElement;
    /// <summary>The desired size of the element AName, measured without limits.</summary>
    function MeasurePart(const AName: string): RADWinUI.Abi.Size;
    /// <summary>A pseudo-random number in 0 .. 1.</summary>
    function NextRandom: Double;
    /// <summary>Sets the height of the control, for controls that grow with their content.</summary>
    procedure SetOwnHeight(AHeight: Double);
    { Colours }
    function AccentFromColor: TWinUIColor;
    function AccentToColor: TWinUIColor;
    function AccentMid: TWinUIColor;
    /// <summary>The surface looks light: a light Background, or the light theme without one.</summary>
    function SurfaceIsLight: Boolean;
    /// <summary>AOnDark on a dark surface, AOnLight on a light one.</summary>
    function ForSurface(const AOnDark, AOnLight: TWinUIColor): TWinUIColor;
    /// <summary>The fill of fields, rows and chips: Background, or the theme's.</summary>
    function SurfaceColor: TWinUIColor;
    /// <summary>A fill a step away from the surface, for tracks and idle chips.</summary>
    function SoftColor: TWinUIColor;
    /// <summary>The edges: BorderBrush, or the theme's.</summary>
    function LineColor: TWinUIColor;
    /// <summary>The text: Foreground, which follows the theme.</summary>
    function TextColor: TWinUIColor;
    /// <summary>Quieter text, for captions and placeholders.</summary>
    function MutedColor: TWinUIColor;
    function SuccessColor: TWinUIColor;
    function DangerColor: TWinUIColor;
    function WarningColor: TWinUIColor;
    function FontSize: Double;
    /// <summary>A new solid brush as the Foreground of the FontIcon or TextBlock AName.</summary>
    function Tint(const AName: string; const AColor: TWinUIColor): ISolidColorBrush;
    /// <summary>Sets the Fill of the shape AName.</summary>
    procedure FillPart(const AName: string; const AColor: TWinUIColor);
    /// <summary>Sets the Stroke of the shape AName.</summary>
    procedure StrokePart(const AName: string; const AColor: TWinUIColor);
    /// <summary>Sets the Text of the TextBlock AName.</summary>
    procedure TextPart(const AName, AText: string);
  public
    destructor Destroy; override;
  published
    /// <summary>The first colour of the accent gradient.</summary>
    property AccentFrom: TWinUIBrush index 0 read GetBrush write SetBrush;
    /// <summary>The last colour of the accent gradient.</summary>
    property AccentTo: TWinUIBrush index 1 read GetBrush write SetBrush;
  end;

const
  /// <summary>The first property index of the controls built on TWinUIDrawnControl.</summary>
  DrawnOwnIndex = 2;

  XamlNamespaces = 'xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"';

  CheckGlyph = #$E73E;
  CloseGlyph = #$E711;
  ChevronLeftGlyph = #$E76B;
  ChevronRightGlyph = #$E76C;
  DoubleLeftGlyph = #$EDD9;
  DoubleRightGlyph = #$EDDA;
  ArrowLeftGlyph = #$E72B;
  ArrowRightGlyph = #$E72A;
  ArrowUpGlyph = #$E74A;
  PinGlyph = #$E718;
  ClockGlyph = #$E917;
  DeleteGlyph = #$E74D;
  HeartGlyph = #$EB52;
  CardGlyph = #$E8C7;

{ Helpers for the drawn controls }

function IsActivationKey(AKey: TWinUIVirtualKey): Boolean;
function Clamp01(AValue: Double): Double;
function Lerp(AFrom, ATo, AProgress: Double): Double;
function EaseOutCubic(T: Double): Double;
function EaseInCubic(T: Double): Double;
function EaseInOutCubic(T: Double): Double;
/// <summary>Ease out with an overshoot past 1 that settles, like a spring.</summary>
function EaseOutBack(T: Double; AOvershoot: Double = 1.4): Double;
/// <summary>Moves ACurrent towards ATarget, all the way in ASeconds.</summary>
function Approach(ACurrent, ATarget, AStep, ASeconds: Double): Double;
/// <summary>Moves ACurrent a part of the way to ATarget, the same speed at any frame rate.</summary>
function Ease(ACurrent, ATarget, AStep, ARate: Double): Double;
/// <summary>A damped spring: moves APosition and AVelocity towards ATarget.</summary>
procedure SpringStep(var APosition, AVelocity: Double; ATarget, AStep: Double; AStiffness: Double = 260;
  ADamping: Double = 22);
function Ticks: Int64;
function Seconds(AFrom, ATo: Int64): Double;
function Rgb(AR, AG, AB: Byte; AA: Byte = $FF): TWinUIColor;
function MixColor(const AFrom, ATo: TWinUIColor; AAmount: Double): TWinUIColor;
function WithAlpha(const AColor: TWinUIColor; AAlpha: Double): TWinUIColor;
function IsLight(const AColor: TWinUIColor): Boolean;
function ColorHex(const AColor: TWinUIColor): string;
function Num(AValue: Double): string;
function XmlText(const AText: string): string;
function GlyphXml(AGlyph: Char): string;
/// <summary>A two-stop LinearGradientBrush as a XAML property element body.</summary>
function GradientXaml(const AFrom, ATo: TWinUIColor; AStartX, AStartY, AEndX, AEndY: Double): string;
function BrushColor(const ABrush: IInspectable; const ADefault: TWinUIColor): TWinUIColor;
function NewBrush(const AColor: TWinUIColor): IBrush;
function Pt(AX, AY: Double): RADWinUI.Abi.Point;
function Vec2(AX, AY: Single): RADWinUI.Abi.Vector2;
function Vec3(AX, AY, AZ: Single): RADWinUI.Abi.Vector3;
procedure Place(const AElement: IUIElement; AX, AY: Double);
procedure Resize(const AElement: IInspectable; AWidth, AHeight: Double);
procedure SetOpacity(const AElement: IUIElement; AValue: Double);
/// <summary>Scales AElement around the point ACX, ACY of itself.</summary>
procedure ScaleAt(const AElement: IUIElement; AScaleX, AScaleY, ACX, ACY: Double);
/// <summary>Turns AElement by ADegrees around the point ACX, ACY of itself.</summary>
procedure RotateAt(const AElement: IUIElement; ADegrees, ACX, ACY: Double);
/// <summary>Moves AElement by AX, AY from where Canvas places it, without layout.</summary>
procedure Shift(const AElement: IUIElement; AX, AY: Double);
procedure SetRadius(const AElement: IInspectable; ARadius: Double);
procedure SetLinePoints(const AElement: IInspectable; const APoints: TArray<RADWinUI.Abi.Point>);
/// <summary>The points of an arc around ACX, ACY from AStart (0 = top, clockwise, 1 = a turn), AFraction long.</summary>
function ArcPoints(ACX, ACY, ARadius, AFraction: Double; AStart: Double = 0): TArray<RADWinUI.Abi.Point>;
/// <summary>A check mark in an ASize square at ALeft, ATop, drawn AProgress of its way.</summary>
function CheckPoints(ALeft, ATop, ASize, AProgress: Double): TArray<RADWinUI.Abi.Point>;
/// <summary>A rounded rectangle as points, for polygons that change shape.</summary>
function RoundRectPoints(ALeft, ATop, AWidth, AHeight, ARadius: Double): TArray<RADWinUI.Abi.Point>;
/// <summary>The XAML of a TextBlock centred in a Grid, both named: AName and AName + 'Box'.</summary>
function CenteredTextXaml(const AName, AText: string; AFontSize: Double; const AWeight: string;
  const AColor: TWinUIColor; const AExtra: string = ''): string;
/// <summary>A colour from a name, the same name always gets the same one: for avatars.</summary>
function NameColor(const AName: string): TWinUIColor;
/// <summary>The first letter of a name, upper case, for avatars.</summary>
function Initial(const AName: string): string;
/// <summary>Splits a list like 'a, b, c' at ASeparator, trimmed, without empty entries.</summary>
function SplitList(const AText: string; ASeparator: Char = ','): TArray<string>;

implementation

uses
  Winapi.Windows,
  System.Math;

const
  // Property indexes of TWinUIDrawnControl
  AccentFromIndex = 0;
  AccentToIndex = 1;

  HostTemplate =
    '<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:rw="using:RADWinUI.Controls" ' +
    'TargetType="rw:%s">' +
    // Transparent, so a press anywhere on the control reaches it
    '<Grid x:Name="PART_Root" Background="Transparent">' +
    '<Canvas x:Name="PART_Host" />' +
    // No background: only the live elements themselves take the input
    '<Canvas x:Name="PART_Live" />' +
    '</Grid></ControlTemplate>';

{ Helpers }

function IsActivationKey(AKey: TWinUIVirtualKey): Boolean;
begin
  Result := (AKey = TWinUIVirtualKey.Enter) or (AKey = TWinUIVirtualKey.Space);
end;

function Clamp01(AValue: Double): Double;
begin
  // NaN (0 / 0 while a control has no size yet) counts as 0: XAML refuses it
  if IsNan(AValue) then
    Exit(0);
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

function EaseInCubic(T: Double): Double;
begin
  T := Clamp01(T);
  Result := T * T * T;
end;

function EaseInOutCubic(T: Double): Double;
begin
  T := Clamp01(T);
  if T < 0.5 then
    Result := 4 * T * T * T
  else
    Result := 1 - Power(-2 * T + 2, 3) / 2;
end;

function EaseOutBack(T: Double; AOvershoot: Double): Double;
var
  C3: Double;
begin
  T := Clamp01(T);
  C3 := AOvershoot + 1;
  Result := 1 + C3 * Power(T - 1, 3) + AOvershoot * Sqr(T - 1);
end;

function Approach(ACurrent, ATarget, AStep, ASeconds: Double): Double;
var
  Delta: Double;
begin
  Delta := AStep / Max(0.001, ASeconds);
  if ACurrent < ATarget then
    Result := Min(ATarget, ACurrent + Delta)
  else
    Result := Max(ATarget, ACurrent - Delta);
end;

function Ease(ACurrent, ATarget, AStep, ARate: Double): Double;
begin
  Result := ATarget + (ACurrent - ATarget) * Exp(-ARate * AStep);
  if Abs(Result - ATarget) < 0.0005 then
    Result := ATarget;
end;

procedure SpringStep(var APosition, AVelocity: Double; ATarget, AStep: Double; AStiffness, ADamping: Double);
var
  I, Steps: Integer;
  H, Force: Double;
begin
  // Small fixed steps keep a stiff spring stable at any frame rate
  Steps := Max(1, Ceil(AStep / 0.004));
  H := AStep / Steps;
  for I := 1 to Steps do
  begin
    Force := AStiffness * (ATarget - APosition) - ADamping * AVelocity;
    AVelocity := AVelocity + Force * H;
    APosition := APosition + AVelocity * H;
  end;
  if (Abs(ATarget - APosition) < 0.0005) and (Abs(AVelocity) < 0.002) then
  begin
    APosition := ATarget;
    AVelocity := 0;
  end;
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

function Rgb(AR, AG, AB: Byte; AA: Byte): TWinUIColor;
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

function IsLight(const AColor: TWinUIColor): Boolean;
begin
  Result := (AColor.A > 100) and (0.299 * AColor.R + 0.587 * AColor.G + 0.114 * AColor.B > 150);
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

function NewBrush(const AColor: TWinUIColor): IBrush;
begin
  Result := RADWinUI.Abi.SolidColorBrush.New(AColor) as IBrush;
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

procedure ScaleAt(const AElement: IUIElement; AScaleX, AScaleY, ACX, ACY: Double);
begin
  if AElement = nil then
    Exit;
  AElement.CenterPoint := Vec3(ACX, ACY, 0);
  AElement.Scale := Vec3(AScaleX, AScaleY, 1);
end;

procedure RotateAt(const AElement: IUIElement; ADegrees, ACX, ACY: Double);
begin
  if AElement = nil then
    Exit;
  AElement.CenterPoint := Vec3(ACX, ACY, 0);
  AElement.Rotation := ADegrees;
end;

procedure Shift(const AElement: IUIElement; AX, AY: Double);
begin
  if AElement = nil then
    Exit;
  AElement.Translation := Vec3(AX, AY, 0);
end;

procedure SetRadius(const AElement: IInspectable; ARadius: Double);
var
  Rect: IRectangle;
begin
  if Supports(AElement, IRectangle, Rect) then
  begin
    Rect.RadiusX := Max(0, ARadius);
    Rect.RadiusY := Max(0, ARadius);
  end;
end;

function NewPoints(const APoints: TArray<RADWinUI.Abi.Point>): IVector_Point;
begin
  // A new collection each frame, so the shape always redraws
  Result := RADWinUI.Abi.PointCollection.New;
  if Length(APoints) > 0 then
    Result.ReplaceAll(Length(APoints), @APoints[0]);
end;

procedure SetLinePoints(const AElement: IInspectable; const APoints: TArray<RADWinUI.Abi.Point>);
var
  Line: IPolyline;
  Polygon: IPolygon;
begin
  if Supports(AElement, IPolyline, Line) then
    Line.Points := NewPoints(APoints)
  else if Supports(AElement, IPolygon, Polygon) then
    Polygon.Points := NewPoints(APoints);
end;

function ArcPoints(ACX, ACY, ARadius, AFraction, AStart: Double): TArray<RADWinUI.Abi.Point>;
var
  Count, I: Integer;
  Angle: Double;
begin
  AFraction := Clamp01(AFraction);
  Count := Max(2, Ceil(96 * AFraction) + 1);
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
  begin
    Angle := -Pi / 2 + 2 * Pi * (AStart + AFraction * I / (Count - 1));
    Result[I] := Pt(ACX + ARadius * Cos(Angle), ACY + ARadius * Sin(Angle));
  end;
end;

function CheckPoints(ALeft, ATop, ASize, AProgress: Double): TArray<RADWinUI.Abi.Point>;
var
  A, B, C: RADWinUI.Abi.Point;
  First, Second, Drawn: Double;
begin
  A := Pt(ALeft + ASize * 0.24, ATop + ASize * 0.53);
  B := Pt(ALeft + ASize * 0.42, ATop + ASize * 0.7);
  C := Pt(ALeft + ASize * 0.77, ATop + ASize * 0.33);
  First := Hypot(B.X - A.X, B.Y - A.Y);
  Second := Hypot(C.X - B.X, C.Y - B.Y);
  Drawn := Clamp01(AProgress) * (First + Second);
  if Drawn <= First then
    Result := [A, Pt(Lerp(A.X, B.X, Drawn / First), Lerp(A.Y, B.Y, Drawn / First))]
  else
    Result := [A, B, Pt(Lerp(B.X, C.X, (Drawn - First) / Second), Lerp(B.Y, C.Y, (Drawn - First) / Second))];
end;

function RoundRectPoints(ALeft, ATop, AWidth, AHeight, ARadius: Double): TArray<RADWinUI.Abi.Point>;
const
  Steps = 6;
var
  Corner, I: Integer;
  CX, CY, Angle: Double;
begin
  ARadius := Max(0, Min(ARadius, Min(AWidth, AHeight) / 2));
  SetLength(Result, 4 * (Steps + 1));
  for Corner := 0 to 3 do
  begin
    case Corner of
      0: begin CX := ALeft + AWidth - ARadius; CY := ATop + ARadius; end;
      1: begin CX := ALeft + AWidth - ARadius; CY := ATop + AHeight - ARadius; end;
      2: begin CX := ALeft + ARadius; CY := ATop + AHeight - ARadius; end;
    else
      CX := ALeft + ARadius;
      CY := ATop + ARadius;
    end;
    for I := 0 to Steps do
    begin
      Angle := -Pi / 2 + Corner * Pi / 2 + (Pi / 2) * I / Steps;
      Result[Corner * (Steps + 1) + I] := Pt(CX + ARadius * Cos(Angle), CY + ARadius * Sin(Angle));
    end;
  end;
end;

function CenteredTextXaml(const AName, AText: string; AFontSize: Double; const AWeight: string;
  const AColor: TWinUIColor; const AExtra: string): string;
begin
  Result := '<Grid x:Name="' + AName + 'Box"><TextBlock x:Name="' + AName + '" Text="' + XmlText(AText) +
    '" FontSize="' + Num(AFontSize) + '" FontWeight="' + AWeight + '" Foreground="' + ColorHex(AColor) +
    '" HorizontalAlignment="Center" VerticalAlignment="Center" TextLineBounds="Tight"' + AExtra + ' /></Grid>';
end;

function NameColor(const AName: string): TWinUIColor;
const
  Palette: array[0..7] of Cardinal = ($3B82F6, $10B981, $8B5CF6, $EC4899, $F59E0B, $14B8A6, $6366F1, $EF4444);
var
  Hash, Value: Cardinal;
  I: Integer;
begin
  Hash := 5381;
  for I := 1 to Length(AName) do
    Hash := Cardinal(UInt64(Hash) * 33) xor Ord(AName[I]);
  Value := Palette[Hash mod Cardinal(Length(Palette))];
  Result := Rgb((Value shr 16) and $FF, (Value shr 8) and $FF, Value and $FF);
end;

function Initial(const AName: string): string;
var
  Name: string;
begin
  Name := Trim(AName);
  if Name = '' then
    Result := '?'
  else
    Result := UpperCase(Name.Substring(0, 1));
end;

function SplitList(const AText: string; ASeparator: Char): TArray<string>;
var
  Part: string;
begin
  Result := nil;
  for Part in AText.Split([ASeparator]) do
    if Trim(Part) <> '' then
      Result := Result + [Trim(Part)];
end;

{ TDrawnGlow }

constructor TDrawnGlow.Create(const AHost: IUIElement; const AShape: IShape; const AColor: TWinUIColor;
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

procedure TDrawnGlow.Resize(AWidth, AHeight: Double);
begin
  (FSprite as IVisual).Size := Vec2(Max(0, AWidth), Max(0, AHeight));
end;

procedure TDrawnGlow.SetOpacity(AValue: Double);
begin
  FShadow.Opacity := Clamp01(AValue);
end;

procedure TDrawnGlow.SetColor(const AColor: TWinUIColor);
begin
  FShadow.Color := AColor;
end;

{ TWinUIDrawnControl }

class procedure TWinUIDrawnControl.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('AccentFrom', TWinUIPropertyKind.Brush);
  AType.AddProperty('AccentTo', TWinUIPropertyKind.Brush);
end;

class function TWinUIDrawnControl.DefaultWidth: Double;
begin
  Result := 320;
end;

class function TWinUIDrawnControl.DefaultHeight: Double;
begin
  Result := 56;
end;

class function TWinUIDrawnControl.DefaultAccentFrom: TWinUIColor;
begin
  Result := Rgb($7C, $5C, $FF);
end;

class function TWinUIDrawnControl.DefaultAccentTo: TWinUIColor;
begin
  Result := Rgb($3C, $C8, $FF);
end;

class function TWinUIDrawnControl.TakesFocus: Boolean;
begin
  Result := True;
end;

procedure TWinUIDrawnControl.Initialize;
var
  Control: IControl;
  Element: IFrameworkElement;
begin
  UseTemplate(Format(HostTemplate, [CustomType.XamlName]));
  FSeed := Cardinal(Ticks) or 1;
  Control := ControlIntf;
  Control.FontSize := 14;
  (Control as IUIElement).IsTabStop := TakesFocus;
  // The focus ring Windows draws around WinUI's own controls
  (Control as IUIElement).UseSystemFocusVisuals := TakesFocus;
  Element := ElementIntf;
  Element.Width := DefaultWidth;
  Element.Height := DefaultHeight;
  Loaded.Add(
    procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
    begin
      FLoaded := True;
      TemplateReady;
      StartRendering;
    end);
  Unloaded.Add(
    procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
    begin
      FLoaded := False;
      FPressed := False;
      StopRendering;
    end);
  PointerPressed.Add(
    procedure(Sender: TObject; E: TWinUIPointerRoutedEventArgs)
    var
      At: RADWinUI.Abi.Point;
    begin
      if FPressed or not ControlIntf.IsEnabled then
        Exit;
      At := PointerAt(E);
      if not PointerDown(At.X, At.Y) then
        Exit;
      FPressed := True;
      (IntfOf(Self, IUIElement) as IUIElement).CapturePointer(E.Intf.Pointer);
      if TakesFocus then
        (IntfOf(Self, IUIElement) as IUIElement).Focus(RADWinUI.Abi.FocusState.Pointer);
      E.Handled := True;
      StartRendering;
    end);
  PointerMoved.Add(
    procedure(Sender: TObject; E: TWinUIPointerRoutedEventArgs)
    var
      At: RADWinUI.Abi.Point;
    begin
      At := PointerAt(E);
      FHoverX := At.X;
      FHoverY := At.Y;
      if not FPressed or FKeyDown then
      begin
        if not FPressed then
          PointerHover(At.X, At.Y);
        StartRendering;
        Exit;
      end;
      PointerDrag(At.X, At.Y);
      StartRendering;
    end);
  PointerReleased.Add(
    procedure(Sender: TObject; E: TWinUIPointerRoutedEventArgs)
    var
      At: RADWinUI.Abi.Point;
    begin
      if not FPressed or FKeyDown then
        Exit;
      At := PointerAt(E);
      // Not pressed any more before the capture goes, so losing it is no second release
      FPressed := False;
      (IntfOf(Self, IUIElement) as IUIElement).ReleasePointerCaptures;
      PointerUp(At.X, At.Y, (At.X >= 0) and (At.Y >= 0) and (At.X <= FWidth) and (At.Y <= FHeight));
      E.Handled := True;
      StartRendering;
    end);
  PointerCaptureLost.Add(
    procedure(Sender: TObject; E: TWinUIPointerRoutedEventArgs)
    begin
      if not FPressed or FKeyDown then
        Exit;
      FPressed := False;
      PointerUp(-1, -1, False);
      StartRendering;
    end);
  PointerEntered.Add(
    procedure(Sender: TObject; E: TWinUIPointerRoutedEventArgs)
    begin
      FHovered := True;
      StartRendering;
    end);
  PointerExited.Add(
    procedure(Sender: TObject; E: TWinUIPointerRoutedEventArgs)
    begin
      FHovered := False;
      FHoverX := -1;
      FHoverY := -1;
      PointerHover(-1, -1);
      StartRendering;
    end);
  KeyDown.Add(
    procedure(Sender: TObject; E: TWinUIKeyRoutedEventArgs)
    begin
      if not ControlIntf.IsEnabled or not TakesFocus then
        Exit;
      if KeyPressed(E.Key) then
      begin
        E.Handled := True;
        StartRendering;
      end;
    end);
end;

destructor TWinUIDrawnControl.Destroy;
begin
  StopRendering;
  inherited;
end;

procedure TWinUIDrawnControl.DetachEvents;
begin
  StopRendering;
  if FRoot <> nil then
  begin
    if FSizeToken.Value <> 0 then
      FRoot.remove_SizeChanged(FSizeToken);
    if FThemeToken.Value <> 0 then
      FRoot.remove_ActualThemeChanged(FThemeToken);
  end;
  FSizeToken.Value := 0;
  FThemeToken.Value := 0;
  Unwatch;
  inherited;
end;

function TWinUIDrawnControl.ControlIntf: IControl;
begin
  Result := IntfOf(Self, IControl) as IControl;
end;

function TWinUIDrawnControl.ElementIntf: IFrameworkElement;
begin
  Result := IntfOf(Self, IFrameworkElement) as IFrameworkElement;
end;

function TWinUIDrawnControl.PointerAt(E: TWinUIPointerRoutedEventArgs): RADWinUI.Abi.Point;
begin
  Result := E.Intf.GetCurrentPoint(IntfOf(Self, IUIElement) as IUIElement).Position;
end;

procedure TWinUIDrawnControl.Watch(const AProp: IDependencyProperty);
var
  Self_: TWinUIDrawnControl;
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

procedure TWinUIDrawnControl.Unwatch;
var
  I: Integer;
begin
  for I := 0 to High(FCallbackTokens) do
    (IntfOf(Self, IDependencyObject) as IDependencyObject).UnregisterPropertyChangedCallback(
      FCallbackProps[I], FCallbackTokens[I]);
  FCallbackProps := nil;
  FCallbackTokens := nil;
end;

procedure TWinUIDrawnControl.TemplateReady;
var
  Self_: TWinUIDrawnControl;
begin
  if FHost <> nil then
    Exit;
  ApplyTemplate;
  FRoot := TemplatePart('PART_Root') as IFrameworkElement;
  if FRoot = nil then
    Exit;
  FHost := TemplatePart('PART_Host') as IPanel;
  FLive := TemplatePart('PART_Live') as IPanel;
  Self_ := Self;
  FSizeToken := FRoot.add_SizeChanged(TSizeChangedEventHandler.Create(
    procedure(ASender: IInspectable; AE: ISizeChangedEventArgs)
    begin
      Self_.HostResized(AE.NewSize.Width, AE.NewSize.Height);
    end));
  // A new theme gives the control its colours again
  FThemeToken := FRoot.add_ActualThemeChanged(TTypedEventHandler_FrameworkElement_Object.Create(
    procedure(ASender: IFrameworkElement; AArgs: IInspectable)
    begin
      Self_.Rebuild;
    end));
  // The usual Control properties paint the control too
  Watch(RADWinUI.Abi.Control.BackgroundProperty);
  Watch(RADWinUI.Abi.Control.BorderBrushProperty);
  Watch(RADWinUI.Abi.Control.ForegroundProperty);
  Watch(RADWinUI.Abi.Control.FontSizeProperty);
  Watch(RADWinUI.Abi.Control.IsEnabledProperty);
  FWidth := FRoot.ActualWidth;
  FHeight := FRoot.ActualHeight;
  if not FLiveBuilt then
  begin
    FLiveBuilt := True;
    BuildLive;
  end;
  Rebuild;
end;

procedure TWinUIDrawnControl.HostResized(AWidth, AHeight: Double);
begin
  FWidth := AWidth;
  FHeight := AHeight;
  if Built then
    LayoutControl;
end;

function TWinUIDrawnControl.Built: Boolean;
begin
  Result := FContent <> nil;
end;

procedure TWinUIDrawnControl.Rebuild;
var
  Content: IInspectable;
begin
  if FHost = nil then
    Exit;
  if FContent <> nil then
    StyleUnloading;
  FContent := nil;
  FHost.Children.Clear;
  Content := RADWinUI.Abi.XamlReader.Load(WinStr('<Canvas ' + XamlNamespaces + '>' + StyleXaml + '</Canvas>'));
  FContent := Content as IFrameworkElement;
  // The control takes the input, wherever it lands
  (FContent as IUIElement).IsHitTestVisible := False;
  if ControlIntf.IsEnabled then
    (FContent as IUIElement).Opacity := 1
  else
    (FContent as IUIElement).Opacity := 0.45;
  FHost.Children.Append(FContent as IUIElement);
  StyleLoaded;
  StyleLive;
  LayoutControl;
  StartRendering;
end;

function TWinUIDrawnControl.Part(const AName: string): IInspectable;
begin
  if FContent = nil then
    Exit(nil);
  Result := FContent.FindName(WinStr(AName));
end;

function TWinUIDrawnControl.UIPart(const AName: string): IUIElement;
begin
  if not Supports(Part(AName), IUIElement, Result) then
    Result := nil;
end;

function TWinUIDrawnControl.LivePanel: IPanel;
begin
  Result := FLive;
end;

function TWinUIDrawnControl.AddLive(const AXaml: string): IUIElement;
var
  Xaml: string;
  Close: Integer;
begin
  Result := nil;
  if FLive = nil then
    Exit;
  // The namespaces go into the first tag
  Xaml := Trim(AXaml);
  Close := Xaml.IndexOfAny([' ', '>', '/']);
  Xaml := Xaml.Substring(0, Close) + ' ' + XamlNamespaces + Xaml.Substring(Close);
  Result := RADWinUI.Abi.XamlReader.Load(WinStr(Xaml)) as IUIElement;
  FLive.Children.Append(Result);
end;

function TWinUIDrawnControl.MeasurePart(const AName: string): RADWinUI.Abi.Size;
var
  Element: IUIElement;
  Big: RADWinUI.Abi.Size;
begin
  Result.Width := 0;
  Result.Height := 0;
  Element := UIPart(AName);
  if Element = nil then
    Exit;
  Big.Width := 10000;
  Big.Height := 10000;
  Element.Measure(Big);
  Result := Element.DesiredSize;
end;

procedure TWinUIDrawnControl.StyleLoaded;
begin
end;

procedure TWinUIDrawnControl.StyleUnloading;
begin
end;

procedure TWinUIDrawnControl.BuildLive;
begin
end;

procedure TWinUIDrawnControl.StyleLive;
begin
end;

procedure TWinUIDrawnControl.Advance(ASeconds: Double);
begin
  FPress := Approach(FPress, Ord(FPressed), ASeconds, 0.12);
  FHover := Approach(FHover, Ord(FHovered), ASeconds, 0.2);
end;

function TWinUIDrawnControl.StillMoving: Boolean;
begin
  Result := (Abs(FPress - Ord(FPressed)) > 0.001) or (Abs(FHover - Ord(FHovered)) > 0.001);
end;

function TWinUIDrawnControl.PointerDown(AX, AY: Double): Boolean;
begin
  Result := False;
end;

procedure TWinUIDrawnControl.PointerDrag(AX, AY: Double);
begin
end;

procedure TWinUIDrawnControl.PointerUp(AX, AY: Double; AInside: Boolean);
begin
end;

procedure TWinUIDrawnControl.PointerHover(AX, AY: Double);
begin
end;

function TWinUIDrawnControl.KeyPressed(AKey: TWinUIVirtualKey): Boolean;
begin
  Result := False;
end;

function TWinUIDrawnControl.NextRandom: Double;
begin
  // xorshift: the same look on every run would be dull, the system Random is the app's
  FSeed := FSeed xor (FSeed shl 13);
  FSeed := FSeed xor (FSeed shr 17);
  FSeed := FSeed xor (FSeed shl 5);
  Result := (FSeed and $FFFFFF) / $1000000;
end;

procedure TWinUIDrawnControl.SetOwnHeight(AHeight: Double);
var
  Element: IFrameworkElement;
begin
  Element := ElementIntf;
  if Abs(Element.Height - AHeight) > 0.25 then
    Element.Height := Max(1, AHeight);
end;

procedure TWinUIDrawnControl.StartRendering;
var
  Self_: TWinUIDrawnControl;
begin
  if (FRenderingToken.Value <> 0) or not FLoaded then
    Exit;
  FLastFrame := Ticks;
  Self_ := Self;
  // Every frame the compositor draws, until nothing moves any more
  FRenderingToken := RADWinUI.Abi.CompositionTarget.add_Rendering(TEventHandler_Object.Create(
    procedure(ASender: IInspectable; AArgs: IInspectable)
    begin
      Self_.Render;
    end));
end;

procedure TWinUIDrawnControl.StopRendering;
begin
  if FRenderingToken.Value <> 0 then
  begin
    RADWinUI.Abi.CompositionTarget.remove_Rendering(FRenderingToken);
    FRenderingToken.Value := 0;
  end;
end;

procedure TWinUIDrawnControl.Render;
var
  Now: Int64;
  Elapsed: Double;
begin
  Now := Ticks;
  Elapsed := Min(0.1, Seconds(FLastFrame, Now));
  FLastFrame := Now;
  FClock := FClock + Elapsed;
  Advance(Elapsed);
  if Built then
    LayoutControl;
  if not StillMoving then
    StopRendering;
end;

procedure TWinUIDrawnControl.PropertyChanged(AIndex: Integer);
begin
  case AIndex of
    AccentFromIndex, AccentToIndex:
      Rebuild;
  end;
end;

{ Colours. In a contrast theme every colour comes from the theme. }

function TWinUIDrawnControl.AccentFromColor: TWinUIColor;
begin
  if HighContrastOn then
    Exit(SystemColor(COLOR_HIGHLIGHT));
  Result := BrushColor(GetPropValue(AccentFromIndex), DefaultAccentFrom);
end;

function TWinUIDrawnControl.AccentToColor: TWinUIColor;
begin
  if HighContrastOn then
    Exit(SystemColor(COLOR_HIGHLIGHT));
  Result := BrushColor(GetPropValue(AccentToIndex), DefaultAccentTo);
end;

function TWinUIDrawnControl.AccentMid: TWinUIColor;
begin
  Result := MixColor(AccentFromColor, AccentToColor, 0.5);
end;

function TWinUIDrawnControl.SurfaceIsLight: Boolean;
var
  Background: TWinUIColor;
begin
  if HighContrastOn then
    Exit(IsLight(SystemColor(COLOR_WINDOW)));
  Background := BrushColor(ControlIntf.Background, Rgb(0, 0, 0, 0));
  if Background.A >= 128 then
    Result := IsLight(Background)
  else
    Result := ElementIntf.ActualTheme = ElementTheme.Light;
end;

function TWinUIDrawnControl.ForSurface(const AOnDark, AOnLight: TWinUIColor): TWinUIColor;
begin
  if SurfaceIsLight then
    Result := AOnLight
  else
    Result := AOnDark;
end;

function TWinUIDrawnControl.SurfaceColor: TWinUIColor;
var
  Background: TWinUIColor;
begin
  if HighContrastOn then
    Exit(SystemColor(COLOR_WINDOW));
  Background := BrushColor(ControlIntf.Background, Rgb(0, 0, 0, 0));
  if Background.A > 0 then
    Result := Background
  else
    Result := ForSurface(Rgb($1D, $1A, $2C), Rgb($FF, $FF, $FF));
end;

function TWinUIDrawnControl.SoftColor: TWinUIColor;
begin
  if HighContrastOn then
    Exit(SystemColor(COLOR_BTNFACE));
  Result := ForSurface(MixColor(SurfaceColor, Rgb($FF, $FF, $FF), 0.07), MixColor(SurfaceColor, Rgb($5A, $4E, $8A), 0.08));
end;

function TWinUIDrawnControl.LineColor: TWinUIColor;
begin
  if HighContrastOn then
    Exit(SystemColor(COLOR_WINDOWTEXT));
  Result := BrushColor(ControlIntf.BorderBrush, ForSurface(Rgb($34, $30, $4A), Rgb($E2, $DF, $EA)));
end;

function TWinUIDrawnControl.TextColor: TWinUIColor;
begin
  if HighContrastOn then
    Exit(SystemColor(COLOR_WINDOWTEXT));
  Result := BrushColor(ControlIntf.Foreground, ForSurface(Rgb($F4, $F2, $FB), Rgb($1D, $1A, $2B)));
  // A Foreground that does not show on the surface (an inherited one) gives way to the theme's
  if IsLight(Result) = SurfaceIsLight then
    Result := ForSurface(Rgb($F4, $F2, $FB), Rgb($1D, $1A, $2B));
end;

function TWinUIDrawnControl.MutedColor: TWinUIColor;
begin
  if HighContrastOn then
    Exit(SystemColor(COLOR_WINDOWTEXT));
  Result := MixColor(TextColor, SurfaceColor, 0.45);
end;

function TWinUIDrawnControl.SuccessColor: TWinUIColor;
begin
  if HighContrastOn then
    Exit(SystemColor(COLOR_HIGHLIGHT));
  Result := ForSurface(Rgb($3D, $DC, $97), Rgb($12, $A1, $66));
end;

function TWinUIDrawnControl.DangerColor: TWinUIColor;
begin
  if HighContrastOn then
    Exit(SystemColor(COLOR_HIGHLIGHT));
  Result := ForSurface(Rgb($FF, $4D, $6A), Rgb($E5, $2B, $4D));
end;

function TWinUIDrawnControl.WarningColor: TWinUIColor;
begin
  if HighContrastOn then
    Exit(SystemColor(COLOR_HIGHLIGHT));
  Result := ForSurface(Rgb($FF, $B5, $3A), Rgb($E0, $8A, $00));
end;

function TWinUIDrawnControl.FontSize: Double;
begin
  Result := Max(6, ControlIntf.FontSize);
end;

function TWinUIDrawnControl.Tint(const AName: string; const AColor: TWinUIColor): ISolidColorBrush;
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

procedure TWinUIDrawnControl.FillPart(const AName: string; const AColor: TWinUIColor);
var
  Shape: IShape;
begin
  if Supports(Part(AName), IShape, Shape) then
    Shape.Fill := NewBrush(AColor);
end;

procedure TWinUIDrawnControl.StrokePart(const AName: string; const AColor: TWinUIColor);
var
  Shape: IShape;
begin
  if Supports(Part(AName), IShape, Shape) then
    Shape.Stroke := NewBrush(AColor);
end;

procedure TWinUIDrawnControl.TextPart(const AName, AText: string);
var
  Text: ITextBlock;
begin
  if Supports(Part(AName), ITextBlock, Text) then
    Text.Text := WinStr(AText);
end;

end.
