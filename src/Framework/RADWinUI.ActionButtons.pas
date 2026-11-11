unit RADWinUI.ActionButtons;

{
  Ready-made animated buttons, on the Tool Palette's Action Buttons category.
  In XAML they live in xmlns:rw="using:RADWinUI.Controls", like RADWinUI's
  other own controls.

  TWinUIHoldButton       hold it down: a ring fills around it, then it turns into a check
  TWinUISendButton       the paper plane flies off with a trail and the label flips to "Sent!"
  TWinUIConfettiButton   a click bursts confetti out of the button, the pieces flutter and fall
  TWinUICopyButton       copies its text, the icon turns into a check and "Copied!" pops up
  TWinUIShineButton      a diagonal shine sweeps across it and sparkles twinkle
  TWinUISlideButton      drag the knob to the end: the track fills and the knob turns into a check

  They share TWinUIActionButton: Text, the accent colours AccentFrom and
  AccentTo, Play (runs the effect from code) and Reset. Background,
  BorderBrush, Foreground, FontSize and CornerRadius are the usual Control
  properties.

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
  /// <summary>The Tool Palette category of the action buttons.</summary>
  ActionButtonsCategory = 'Action Buttons';

type
  /// <summary>A soft coloured glow behind a shape, cast by the compositor.</summary>
  TActionButtonGlow = class
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
  ///   The base of the action buttons: the elements, the input and the
  ///   animation loop. Each button describes its elements in XAML (StyleXaml)
  ///   and places them every frame (LayoutButton). Not registered itself.
  /// </summary>
  TWinUIActionButton = class(TWinUICustomControl)
  strict private
    FHost: IPanel;
    FHostElement: IFrameworkElement;
    FContent: IFrameworkElement;
    FSizeToken: EventRegistrationToken;
    FRenderingToken: EventRegistrationToken;
    FCallbackProps: TArray<IDependencyProperty>;
    FCallbackTokens: TArray<Int64>;
    FLastFrame: Int64;
    FSeed: Cardinal;
    FKeyDown: Boolean;
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
    /// <summary>The pointer or Enter/Space holds the button down.</summary>
    FPressed: Boolean;
    FHovered: Boolean;
    /// <summary>0 .. 1, how pressed the button looks; follows FPressed.</summary>
    FPress: Double;
    /// <summary>0 .. 1, how hovered the button looks; follows FHovered.</summary>
    FHover: Double;
    /// <summary>The window is showing the control.</summary>
    FLoaded: Boolean;
    class procedure DefineType(AType: TWinUICustomType); override;
    /// <summary>Text of a new button.</summary>
    class function DefaultText: string; virtual;
    class function DefaultWidth: Double; virtual;
    class function DefaultHeight: Double; virtual;
    /// <summary>The accent colours unless AccentFrom and AccentTo are set.</summary>
    class function DefaultAccentFrom: TWinUIColor; virtual;
    class function DefaultAccentTo: TWinUIColor; virtual;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure DetachEvents; override;
    { The look }
    /// <summary>XAML of the button's elements, the children of one Canvas.</summary>
    function StyleXaml: string; virtual; abstract;
    /// <summary>The elements of StyleXaml were created: find them with Part.</summary>
    procedure StyleLoaded; virtual;
    /// <summary>Releases what StyleLoaded kept, before the elements are made again.</summary>
    procedure StyleUnloading; virtual;
    /// <summary>Places every element for the current size and state.</summary>
    procedure LayoutButton; virtual; abstract;
    /// <summary>Runs every frame while rendering, ASeconds after the last one. Call inherited.</summary>
    procedure Advance(ASeconds: Double); virtual;
    /// <summary>Something still moves, so rendering goes on. Call inherited.</summary>
    function StillMoving: Boolean; virtual;
    { Input }
    /// <summary>A press at AX, AY. False ignores it (no capture, no press look).</summary>
    function PointerDown(AX, AY: Double): Boolean; virtual;
    /// <summary>The pointer moved while pressed.</summary>
    procedure PointerDrag(AX, AY: Double); virtual;
    /// <summary>The press ended, AInside when the pointer was still over the button.</summary>
    procedure PointerUp(AX, AY: Double; AInside: Boolean); virtual;
    /// <summary>Enter or Space went down (ADown) or up. By default up activates.</summary>
    procedure KeyActivate(ADown: Boolean); virtual;
    /// <summary>A click: runs the button's effect.</summary>
    procedure Activate; virtual;
    { For the buttons }
    function Built: Boolean;
    procedure Rebuild;
    procedure StartRendering;
    function Part(const AName: string): IInspectable;
    function UIPart(const AName: string): IUIElement;
    function ControlIntf: IControl;
    /// <summary>The desired size of the element AName, measured without limits.</summary>
    function MeasurePart(const AName: string): RADWinUI.Abi.Size;
    /// <summary>A pseudo-random number in 0 .. 1.</summary>
    function NextRandom: Double;
    function AccentFromColor: TWinUIColor;
    function AccentToColor: TWinUIColor;
    function ForegroundColor: TWinUIColor;
    function BackgroundColor: TWinUIColor;
    function BorderColor: TWinUIColor;
    /// <summary>AOnDark on a dark Background, AOnLight on a light one.</summary>
    function ForSurface(const AOnDark, AOnLight: TWinUIColor): TWinUIColor;
    function FontSize: Double;
    /// <summary>A new solid brush as the Foreground of the FontIcon or TextBlock AName.</summary>
    function Tint(const AName: string; const AColor: TWinUIColor): ISolidColorBrush;
    { Accessibility: a button that Invoke runs, named by its Text }
    function AutomationRole: AutomationControlType; override;
    function AutomationPatterns: TWinUIAutomationPatterns; override;
    function AutomationName: string; override;
    procedure AutomationInvoke; override;
  public
    destructor Destroy; override;
    /// <summary>Runs the button's effect, as if the user clicked, held or slid it.</summary>
    procedure Play; virtual;
    /// <summary>Back to how the button looks before it is used, without animation.</summary>
    procedure Reset; virtual;
  published
    /// <summary>The label of the button.</summary>
    property Text: string index 0 read GetText write SetText;
    /// <summary>The first colour of the accent gradient.</summary>
    property AccentFrom: TWinUIBrush index 1 read GetBrush write SetBrush;
    /// <summary>The last colour of the accent gradient.</summary>
    property AccentTo: TWinUIBrush index 2 read GetBrush write SetBrush;
  end;

  /// <summary>A round button: hold it down and a ring fills around it, then it turns into a check.</summary>
  TWinUIHoldButton = class(TWinUIActionButton)
  strict private
    FGlow: TActionButtonGlow;
    FHold: Double;
    FDone: Boolean;
    FDoneAge: Double;
    FDoneLook: Double;
    FNeedsRelease: Boolean;
    FCaptionSize, FDoneSize: RADWinUI.Abi.Size;
    procedure Complete;
    function GetIsDone: Boolean;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultText: string; override;
    class function DefaultWidth: Double; override;
    class function DefaultHeight: Double; override;
    class function DefaultAccentFrom: TWinUIColor; override;
    class function DefaultAccentTo: TWinUIColor; override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    function StyleXaml: string; override;
    procedure StyleLoaded; override;
    procedure StyleUnloading; override;
    procedure LayoutButton; override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
    function PointerDown(AX, AY: Double): Boolean; override;
    procedure PointerUp(AX, AY: Double; AInside: Boolean); override;
    procedure KeyActivate(ADown: Boolean); override;
  public
    destructor Destroy; override;
    procedure Play; override;
    procedure Reset; override;
    /// <summary>The hold completed and the check shows.</summary>
    property IsDone: Boolean read GetIsDone;
    /// <summary>0 .. 1, how far the ring has filled.</summary>
    property Progress: Double read FHold;
  published
    /// <summary>The caption once confirmed.</summary>
    property DoneText: string index 3 read GetText write SetText;
    /// <summary>The icon in the circle: a name like Delete, or a Segoe Fluent Icons code point.</summary>
    property Icon: string index 4 read GetText write SetText;
    /// <summary>Milliseconds it must be held.</summary>
    property HoldDuration: Integer index 5 read GetInt32 write SetInt32;
    /// <summary>Milliseconds the check shows before the button is back, 0 to keep it.</summary>
    property ResetAfter: Integer index 6 read GetInt32 write SetInt32;
    property OnConfirmed: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

  /// <summary>A gradient pill whose paper plane flies off with a trail, then the label flips to DoneText.</summary>
  TWinUISendButton = class(TWinUIActionButton)
  strict private
    FGlow: TActionButtonGlow;
    FSendAge: Double;
    FResetAge: Double;
    FTextSize, FDoneSize: RADWinUI.Abi.Size;
    function GetIsDone: Boolean;
    function PlaneAt(AProgress, AStartX, AStartY: Double): RADWinUI.Abi.Point;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultText: string; override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    function StyleXaml: string; override;
    procedure StyleLoaded; override;
    procedure StyleUnloading; override;
    procedure LayoutButton; override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
    procedure Activate; override;
  public
    destructor Destroy; override;
    procedure Reset; override;
    /// <summary>It was sent and shows DoneText.</summary>
    property IsDone: Boolean read GetIsDone;
  published
    property DoneText: string index 3 read GetText write SetText;
    /// <summary>Milliseconds DoneText shows before the button is back, 0 to keep it.</summary>
    property ResetAfter: Integer index 4 read GetInt32 write SetInt32;
    property OnClick: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

  /// <summary>A gradient pill: a click bursts confetti out of it, the pieces flutter and fall.</summary>
  TWinUIConfettiButton = class(TWinUIActionButton)
  strict private type
    TPiece = record
      Active: Boolean;
      X, Y, VX, VY: Double;
      Angle, Spin: Double;
      Flip, FlipSpeed: Double;
      Sway: Double;
      Age, Life: Double;
    end;
  strict private
    FGlow: TActionButtonGlow;
    FPieces: TArray<TPiece>;
    FPopAge: Double;
    FTextSize: RADWinUI.Abi.Size;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultText: string; override;
    class function DefaultAccentFrom: TWinUIColor; override;
    class function DefaultAccentTo: TWinUIColor; override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    function StyleXaml: string; override;
    procedure StyleLoaded; override;
    procedure StyleUnloading; override;
    procedure LayoutButton; override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
    procedure Activate; override;
  public
    destructor Destroy; override;
    procedure Reset; override;
    /// <summary>Pieces of confetti in the air right now.</summary>
    function FlyingCount: Integer;
  published
    /// <summary>How many pieces one click bursts, up to 120.</summary>
    property ConfettiCount: Integer index 3 read GetInt32 write SetInt32;
    property OnClick: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

  /// <summary>A text field with a copy icon: a click copies the text, the icon turns into a check and "Copied!" pops up.</summary>
  TWinUICopyButton = class(TWinUIActionButton)
  strict private
    FDone: Boolean;
    FDoneAge: Double;
    FDoneLook: Double;
    FTipSize: RADWinUI.Abi.Size;
    function GetIsDone: Boolean;
  protected
    /// <summary>Its Text is what it copies: the name says what a click does.</summary>
    function AutomationName: string; override;
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultText: string; override;
    class function DefaultWidth: Double; override;
    class function DefaultHeight: Double; override;
    class function DefaultAccentFrom: TWinUIColor; override;
    class function DefaultAccentTo: TWinUIColor; override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    function StyleXaml: string; override;
    procedure StyleLoaded; override;
    procedure LayoutButton; override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
    procedure Activate; override;
  public
    procedure Reset; override;
    /// <summary>The text was copied and the check shows.</summary>
    property IsDone: Boolean read GetIsDone;
  published
    /// <summary>The tooltip once copied.</summary>
    property DoneText: string index 3 read GetText write SetText;
    /// <summary>Milliseconds the check shows before the button is back, 0 to keep it.</summary>
    property ResetAfter: Integer index 4 read GetInt32 write SetInt32;
    /// <summary>A click puts Text on the clipboard.</summary>
    property CopyToClipboard: Boolean index 5 read GetBoolean write SetBoolean;
    property OnCopied: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

  /// <summary>A glowing gradient pill: a diagonal shine sweeps across it and sparkles twinkle.</summary>
  TWinUIShineButton = class(TWinUIActionButton)
  strict private
    FGlow: TActionButtonGlow;
    FShineAge: Double;
    FNextShine: Double;
    FPopAge: Double;
    FTextSize: RADWinUI.Abi.Size;
    procedure StartShine;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultText: string; override;
    class function DefaultWidth: Double; override;
    class function DefaultAccentFrom: TWinUIColor; override;
    class function DefaultAccentTo: TWinUIColor; override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    function StyleXaml: string; override;
    procedure StyleLoaded; override;
    procedure StyleUnloading; override;
    procedure LayoutButton; override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
    procedure Activate; override;
  public
    destructor Destroy; override;
    procedure Reset; override;
  published
    /// <summary>Milliseconds between two shines, 0 to shine only on hover and click.</summary>
    property ShineInterval: Integer index 3 read GetInt32 write SetInt32;
    /// <summary>Little stars twinkle around the button.</summary>
    property Sparkles: Boolean index 4 read GetBoolean write SetBoolean;
    /// <summary>The colour of the glow around the button (warm gold unless set).</summary>
    property GlowBrush: TWinUIBrush index 5 read GetBrush write SetBrush;
    property OnClick: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

  /// <summary>A track with a knob: drag it to the end, the track fills and the knob turns into a check.</summary>
  TWinUISlideButton = class(TWinUIActionButton)
  strict private
    FGlow: TActionButtonGlow;
    FPosition: Double;
    FGrab: Double;
    FDragging: Boolean;
    FDone: Boolean;
    FDoneAge: Double;
    FDoneLook: Double;
    // A slide that runs by itself: back to the start, to the end (keys, Play) or back after done
    FTweenFrom, FTweenTo, FTweenAge, FTweenTime: Double;
    FTweening: Boolean;
    FTextSize, FDoneSize: RADWinUI.Abi.Size;
    function GetIsDone: Boolean;
    function KnobSize: Double;
    function Travel: Double;
    procedure TweenTo(ATarget, ASeconds: Double);
    procedure Complete;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultText: string; override;
    class function DefaultWidth: Double; override;
    class function DefaultHeight: Double; override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    function StyleXaml: string; override;
    procedure StyleLoaded; override;
    procedure StyleUnloading; override;
    procedure LayoutButton; override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
    function PointerDown(AX, AY: Double): Boolean; override;
    procedure PointerDrag(AX, AY: Double); override;
    procedure PointerUp(AX, AY: Double; AInside: Boolean); override;
    procedure KeyActivate(ADown: Boolean); override;
  public
    destructor Destroy; override;
    procedure Play; override;
    procedure Reset; override;
    /// <summary>The knob reached the end and the check shows.</summary>
    property IsDone: Boolean read GetIsDone;
    /// <summary>0 .. 1, where the knob is on the track.</summary>
    property Position: Double read FPosition;
  published
    /// <summary>The label once confirmed.</summary>
    property DoneText: string index 3 read GetText write SetText;
    /// <summary>Milliseconds the check shows before the knob slides back, 0 to keep it.</summary>
    property ResetAfter: Integer index 4 read GetInt32 write SetInt32;
    /// <summary>A soft light runs over the label while it waits.</summary>
    property Shimmer: Boolean index 5 read GetBoolean write SetBoolean;
    property OnConfirmed: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

/// <summary>Puts AText on the Windows clipboard. False when the clipboard is busy.</summary>
function CopyTextToClipboard(const AText: string): Boolean;

implementation

uses
  Winapi.Windows,
  System.Math;

const
  // Property indexes of TWinUIActionButton
  ButtonTextIndex = 0;
  ButtonAccentFromIndex = 1;
  ButtonAccentToIndex = 2;
  // The first property index of each button
  OwnIndex = 3;

  CheckGlyph = #$E73E;
  CopyGlyph = #$E8C8;
  SendGlyph = #$E724;
  ChevronGlyph = #$E76C;

  XamlNamespaces = 'xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"';

  HostTemplate =
    '<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:rw="using:RADWinUI.Controls" ' +
    'TargetType="rw:%s">' +
    // Transparent, so a press anywhere on the button reaches the control
    '<Canvas x:Name="PART_Host" Background="Transparent" />' +
    '</ControlTemplate>';

{ Small helpers }

function IsActivationKey(AKey: TWinUIVirtualKey): Boolean;
begin
  Result := (AKey = TWinUIVirtualKey.Enter) or (AKey = TWinUIVirtualKey.Space);
end;

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

/// Ease out with an overshoot past 1 that settles, like a spring
function EaseOutBack(T: Double; AOvershoot: Double = 1.4): Double;
var
  C3: Double;
begin
  T := Clamp01(T);
  C3 := AOvershoot + 1;
  Result := 1 + C3 * Power(T - 1, 3) + AOvershoot * Sqr(T - 1);
end;

/// Ease in that first pulls back a little, like a run-up
function EaseInBack(T: Double; AOvershoot: Double = 1.7): Double;
begin
  T := Clamp01(T);
  Result := (AOvershoot + 1) * T * T * T - AOvershoot * T * T;
end;

/// Moves ACurrent towards ATarget, all the way in ASeconds
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

/// A two-stop LinearGradientBrush as a XAML property element body
function GradientXaml(const AFrom, ATo: TWinUIColor; AStartX, AStartY, AEndX, AEndY: Double): string;
begin
  Result := '<LinearGradientBrush StartPoint="' + Num(AStartX) + ',' + Num(AStartY) + '" EndPoint="' +
    Num(AEndX) + ',' + Num(AEndY) + '">' +
    '<GradientStop Color="' + ColorHex(AFrom) + '" Offset="0" />' +
    '<GradientStop Color="' + ColorHex(ATo) + '" Offset="1" /></LinearGradientBrush>';
end;

/// A band of light: transparent, AColor, transparent, moved with SetBand
function BandXaml(const ABase, ALight: TWinUIColor; AStartX, AStartY, AEndX, AEndY: Double): string;
begin
  Result := '<LinearGradientBrush StartPoint="' + Num(AStartX) + ',' + Num(AStartY) + '" EndPoint="' +
    Num(AEndX) + ',' + Num(AEndY) + '">' +
    '<GradientStop Color="' + ColorHex(ABase) + '" Offset="0" />' +
    '<GradientStop Color="' + ColorHex(ABase) + '" Offset="0" />' +
    '<GradientStop Color="' + ColorHex(ALight) + '" Offset="0" />' +
    '<GradientStop Color="' + ColorHex(ABase) + '" Offset="0" />' +
    '<GradientStop Color="' + ColorHex(ABase) + '" Offset="1" /></LinearGradientBrush>';
end;

/// Puts the light of a BandXaml brush at ACenter (may lie outside 0 .. 1), AHalfWidth wide each side
procedure SetBand(const ABrush: IInspectable; ACenter, AHalfWidth: Double);
var
  Gradient: IGradientBrush;
  Stops: IVector_GradientStop;
begin
  if not Supports(ABrush, IGradientBrush, Gradient) then
    Exit;
  Stops := Gradient.GradientStops;
  if Stops.get_Size < 5 then
    Exit;
  // Stops must stay in order, so they are clamped to 0 .. 1 in order
  Stops.GetAt(1).Offset := Clamp01(ACenter - AHalfWidth);
  Stops.GetAt(2).Offset := Clamp01(ACenter);
  Stops.GetAt(3).Offset := Clamp01(ACenter + AHalfWidth);
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

/// Scales AElement around the point ACX, ACY of itself
procedure ScaleAt(const AElement: IUIElement; AScaleX, AScaleY, ACX, ACY: Double);
begin
  if AElement = nil then
    Exit;
  AElement.CenterPoint := Vec3(ACX, ACY, 0);
  AElement.Scale := Vec3(AScaleX, AScaleY, 1);
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

/// The points of an arc around ACX, ACY from the top, clockwise, AFraction of a full turn
function ArcPoints(ACX, ACY, ARadius, AFraction: Double): TArray<RADWinUI.Abi.Point>;
var
  Count, I: Integer;
  Angle: Double;
begin
  AFraction := Clamp01(AFraction);
  Count := Max(2, Ceil(96 * AFraction) + 1);
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
  begin
    Angle := -Pi / 2 + 2 * Pi * AFraction * I / (Count - 1);
    Result[I] := Pt(ACX + ARadius * Cos(Angle), ACY + ARadius * Sin(Angle));
  end;
end;

/// A check mark in an ASize square at ALeft, ATop, drawn AProgress of its way
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

/// A four-pointed star, like a sparkle, around ACX, ACY
function StarPoints(ACX, ACY, ARadius: Double): TArray<RADWinUI.Abi.Point>;
var
  I: Integer;
  Angle, R: Double;
begin
  SetLength(Result, 8);
  for I := 0 to 7 do
  begin
    Angle := -Pi / 2 + I * Pi / 4;
    if Odd(I) then
      R := ARadius * 0.28
    else
      R := ARadius;
    Result[I] := Pt(ACX + R * Cos(Angle), ACY + R * Sin(Angle));
  end;
end;

/// XAML of a TextBlock centred in a Grid, both named: AName and AName + 'Box'
function CenteredTextXaml(const AName, AText: string; AFontSize: Double; const AWeight: string;
  const AColor: TWinUIColor; const AExtra: string = ''): string;
begin
  Result := '<Grid x:Name="' + AName + 'Box"><TextBlock x:Name="' + AName + '" Text="' + XmlText(AText) +
    '" FontSize="' + Num(AFontSize) + '" FontWeight="' + AWeight + '" Foreground="' + ColorHex(AColor) +
    '" HorizontalAlignment="Center" VerticalAlignment="Center" TextLineBounds="Tight"' + AExtra + ' /></Grid>';
end;

var
  ClipboardWindow: HWND;

function CopyTextToClipboard(const AText: string): Boolean;
var
  Data: HGLOBAL;
  Target: Pointer;
  Size: NativeUInt;
  Tries: Integer;
begin
  Result := False;
  // The clipboard needs an owner window, a hidden message-only one does
  if ClipboardWindow = 0 then
    ClipboardWindow := CreateWindowEx(0, 'STATIC', nil, 0, 0, 0, 0, 0, HWND_MESSAGE, 0, HInstance, nil);
  Tries := 0;
  while not OpenClipboard(ClipboardWindow) do
  begin
    Inc(Tries);
    if Tries > 5 then
      Exit;
    Sleep(10);
  end;
  try
    EmptyClipboard;
    Size := (Length(AText) + 1) * SizeOf(Char);
    Data := GlobalAlloc(GMEM_MOVEABLE, Size);
    if Data = 0 then
      Exit;
    Target := GlobalLock(Data);
    Move(PChar(AText)^, Target^, Size);
    GlobalUnlock(Data);
    Result := SetClipboardData(CF_UNICODETEXT, Data) <> 0;
    if not Result then
      GlobalFree(Data);
  finally
    CloseClipboard;
  end;
end;

{ TActionButtonGlow }

constructor TActionButtonGlow.Create(const AHost: IUIElement; const AShape: IShape; const AColor: TWinUIColor;
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

procedure TActionButtonGlow.Resize(AWidth, AHeight: Double);
begin
  (FSprite as IVisual).Size := Vec2(Max(0, AWidth), Max(0, AHeight));
end;

procedure TActionButtonGlow.SetOpacity(AValue: Double);
begin
  FShadow.Opacity := Clamp01(AValue);
end;

procedure TActionButtonGlow.SetColor(const AColor: TWinUIColor);
begin
  FShadow.Color := AColor;
end;

{ TWinUIActionButton }

class procedure TWinUIActionButton.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Text', TWinUIPropertyKind.Text, DefaultText);
  AType.AddProperty('AccentFrom', TWinUIPropertyKind.Brush);
  AType.AddProperty('AccentTo', TWinUIPropertyKind.Brush);
end;

class function TWinUIActionButton.DefaultText: string;
begin
  Result := 'Button';
end;

class function TWinUIActionButton.DefaultWidth: Double;
begin
  Result := 168;
end;

class function TWinUIActionButton.DefaultHeight: Double;
begin
  Result := 48;
end;

class function TWinUIActionButton.DefaultAccentFrom: TWinUIColor;
begin
  Result := Rgb($6C, $55, $FF);
end;

class function TWinUIActionButton.DefaultAccentTo: TWinUIColor;
begin
  Result := Rgb($3C, $B4, $FF);
end;

procedure TWinUIActionButton.Initialize;
var
  Control: IControl;
  Element: IFrameworkElement;
  Corners: RADWinUI.Abi.CornerRadius;
  Edge: RADWinUI.Abi.Thickness;
begin
  UseTemplate(Format(HostTemplate, [CustomType.XamlName]));
  FSeed := Cardinal(Ticks) or 1;
  // A dark surface with white text unless the XAML says otherwise
  Control := ControlIntf;
  Control.Background := RADWinUI.Abi.SolidColorBrush.New(Rgb($1B, $18, $29)) as IBrush;
  Control.BorderBrush := RADWinUI.Abi.SolidColorBrush.New(Rgb($2E, $2A, $40)) as IBrush;
  Control.Foreground := RADWinUI.Abi.SolidColorBrush.New(Rgb($FF, $FF, $FF)) as IBrush;
  Edge.Left := 1;
  Edge.Top := 1;
  Edge.Right := 1;
  Edge.Bottom := 1;
  Control.BorderThickness := Edge;
  Corners.TopLeft := 14;
  Corners.TopRight := 14;
  Corners.BottomRight := 14;
  Corners.BottomLeft := 14;
  Control.CornerRadius := Corners;
  Control.FontSize := 15;
  (Control as IUIElement).IsTabStop := True;
  // The focus ring Windows draws around WinUI's own controls
  (Control as IUIElement).UseSystemFocusVisuals := True;
  Element := IntfOf(Self, IFrameworkElement) as IFrameworkElement;
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
      E.Handled := True;
      StartRendering;
    end);
  PointerMoved.Add(
    procedure(Sender: TObject; E: TWinUIPointerRoutedEventArgs)
    var
      At: RADWinUI.Abi.Point;
    begin
      if not FPressed or FKeyDown then
        Exit;
      At := PointerAt(E);
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
      StartRendering;
    end);
  KeyDown.Add(
    procedure(Sender: TObject; E: TWinUIKeyRoutedEventArgs)
    begin
      if not IsActivationKey(E.Key) or not ControlIntf.IsEnabled then
        Exit;
      E.Handled := True;
      // The key repeats while held: only its first press counts
      if FKeyDown or FPressed then
        Exit;
      FKeyDown := True;
      FPressed := True;
      KeyActivate(True);
      StartRendering;
    end);
  KeyUp.Add(
    procedure(Sender: TObject; E: TWinUIKeyRoutedEventArgs)
    begin
      if not IsActivationKey(E.Key) or not FKeyDown then
        Exit;
      E.Handled := True;
      FKeyDown := False;
      FPressed := False;
      KeyActivate(False);
      StartRendering;
    end);
end;

destructor TWinUIActionButton.Destroy;
begin
  StopRendering;
  inherited;
end;

procedure TWinUIActionButton.DetachEvents;
begin
  StopRendering;
  if (FHostElement <> nil) and (FSizeToken.Value <> 0) then
    FHostElement.remove_SizeChanged(FSizeToken);
  FSizeToken.Value := 0;
  Unwatch;
  inherited;
end;

function TWinUIActionButton.ControlIntf: IControl;
begin
  Result := IntfOf(Self, IControl) as IControl;
end;

function TWinUIActionButton.PointerAt(E: TWinUIPointerRoutedEventArgs): RADWinUI.Abi.Point;
begin
  Result := E.Intf.GetCurrentPoint(IntfOf(Self, IUIElement) as IUIElement).Position;
end;

procedure TWinUIActionButton.Watch(const AProp: IDependencyProperty);
var
  Self_: TWinUIActionButton;
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

procedure TWinUIActionButton.Unwatch;
var
  I: Integer;
begin
  for I := 0 to High(FCallbackTokens) do
    (IntfOf(Self, IDependencyObject) as IDependencyObject).UnregisterPropertyChangedCallback(
      FCallbackProps[I], FCallbackTokens[I]);
  FCallbackProps := nil;
  FCallbackTokens := nil;
end;

procedure TWinUIActionButton.TemplateReady;
var
  Self_: TWinUIActionButton;
begin
  if FHost <> nil then
    Exit;
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
  // The usual Control properties paint the button too
  Watch(RADWinUI.Abi.Control.BackgroundProperty);
  Watch(RADWinUI.Abi.Control.BorderBrushProperty);
  Watch(RADWinUI.Abi.Control.BorderThicknessProperty);
  Watch(RADWinUI.Abi.Control.ForegroundProperty);
  Watch(RADWinUI.Abi.Control.CornerRadiusProperty);
  Watch(RADWinUI.Abi.Control.FontSizeProperty);
  Watch(RADWinUI.Abi.Control.IsEnabledProperty);
  FWidth := FHostElement.ActualWidth;
  FHeight := FHostElement.ActualHeight;
  Rebuild;
end;

procedure TWinUIActionButton.HostResized(AWidth, AHeight: Double);
begin
  FWidth := AWidth;
  FHeight := AHeight;
  if Built then
    LayoutButton;
end;

function TWinUIActionButton.Built: Boolean;
begin
  Result := FContent <> nil;
end;

procedure TWinUIActionButton.Rebuild;
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
  LayoutButton;
  StartRendering;
end;

function TWinUIActionButton.Part(const AName: string): IInspectable;
begin
  if FContent = nil then
    Exit(nil);
  Result := FContent.FindName(WinStr(AName));
end;

function TWinUIActionButton.UIPart(const AName: string): IUIElement;
begin
  if not Supports(Part(AName), IUIElement, Result) then
    Result := nil;
end;

function TWinUIActionButton.MeasurePart(const AName: string): RADWinUI.Abi.Size;
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

procedure TWinUIActionButton.StyleLoaded;
begin
end;

procedure TWinUIActionButton.StyleUnloading;
begin
end;

procedure TWinUIActionButton.Advance(ASeconds: Double);
begin
  FPress := Approach(FPress, Ord(FPressed), ASeconds, 0.12);
  FHover := Approach(FHover, Ord(FHovered), ASeconds, 0.2);
end;

function TWinUIActionButton.StillMoving: Boolean;
begin
  Result := (Abs(FPress - Ord(FPressed)) > 0.001) or (Abs(FHover - Ord(FHovered)) > 0.001);
end;

function TWinUIActionButton.PointerDown(AX, AY: Double): Boolean;
begin
  Result := True;
end;

procedure TWinUIActionButton.PointerDrag(AX, AY: Double);
begin
end;

procedure TWinUIActionButton.PointerUp(AX, AY: Double; AInside: Boolean);
begin
  if AInside then
    Activate;
end;

procedure TWinUIActionButton.KeyActivate(ADown: Boolean);
begin
  if not ADown then
    Activate;
end;

procedure TWinUIActionButton.Activate;
begin
end;

procedure TWinUIActionButton.Play;
begin
  Activate;
  StartRendering;
end;

procedure TWinUIActionButton.Reset;
begin
  FPressed := False;
  FPress := 0;
  if Built then
    LayoutButton;
end;

function TWinUIActionButton.NextRandom: Double;
begin
  // xorshift: the same look on every run would be dull, the system Random is the app's
  FSeed := FSeed xor (FSeed shl 13);
  FSeed := FSeed xor (FSeed shr 17);
  FSeed := FSeed xor (FSeed shl 5);
  Result := (FSeed and $FFFFFF) / $1000000;
end;

procedure TWinUIActionButton.StartRendering;
var
  Self_: TWinUIActionButton;
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

procedure TWinUIActionButton.StopRendering;
begin
  if FRenderingToken.Value <> 0 then
  begin
    RADWinUI.Abi.CompositionTarget.remove_Rendering(FRenderingToken);
    FRenderingToken.Value := 0;
  end;
end;

procedure TWinUIActionButton.Render;
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
    LayoutButton;
  if not StillMoving then
    StopRendering;
end;

procedure TWinUIActionButton.PropertyChanged(AIndex: Integer);
begin
  case AIndex of
    ButtonTextIndex, ButtonAccentFromIndex, ButtonAccentToIndex:
      begin
        Rebuild;
        if AIndex = ButtonTextIndex then
          AutomationNameChanged;
      end;
  end;
end;

// In a contrast theme every colour comes from the theme: its button colours, and its
// highlight colour for the accent

function TWinUIActionButton.AccentFromColor: TWinUIColor;
begin
  if HighContrastOn then
    Exit(SystemColor(COLOR_HIGHLIGHT));
  Result := BrushColor(GetPropValue(ButtonAccentFromIndex), DefaultAccentFrom);
end;

function TWinUIActionButton.AccentToColor: TWinUIColor;
begin
  if HighContrastOn then
    Exit(SystemColor(COLOR_HIGHLIGHT));
  Result := BrushColor(GetPropValue(ButtonAccentToIndex), DefaultAccentTo);
end;

function TWinUIActionButton.ForegroundColor: TWinUIColor;
begin
  if HighContrastOn then
    Exit(SystemColor(COLOR_BTNTEXT));
  Result := BrushColor(ControlIntf.Foreground, Rgb($FF, $FF, $FF));
end;

function TWinUIActionButton.BackgroundColor: TWinUIColor;
begin
  if HighContrastOn then
    Exit(SystemColor(COLOR_BTNFACE));
  Result := BrushColor(ControlIntf.Background, Rgb($1B, $18, $29));
end;

function TWinUIActionButton.BorderColor: TWinUIColor;
begin
  if HighContrastOn then
    Exit(SystemColor(COLOR_BTNTEXT));
  Result := BrushColor(ControlIntf.BorderBrush, Rgb($2E, $2A, $40));
end;

{ Accessibility }

function TWinUIActionButton.AutomationRole: AutomationControlType;
begin
  Result := AutomationControlType.Button;
end;

function TWinUIActionButton.AutomationPatterns: TWinUIAutomationPatterns;
begin
  Result := [TWinUIAutomationPattern.Invoke];
end;

function TWinUIActionButton.AutomationName: string;
begin
  Result := Text;
end;

procedure TWinUIActionButton.AutomationInvoke;
begin
  // What a click, a hold or a slide to the end does
  Play;
end;

function TWinUIActionButton.ForSurface(const AOnDark, AOnLight: TWinUIColor): TWinUIColor;
begin
  if IsLight(BackgroundColor) then
    Result := AOnLight
  else
    Result := AOnDark;
end;

function TWinUIActionButton.FontSize: Double;
begin
  Result := Max(6, ControlIntf.FontSize);
end;

function TWinUIActionButton.Tint(const AName: string; const AColor: TWinUIColor): ISolidColorBrush;
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

{ TWinUIHoldButton }

const
  HoldDoneTextIndex = OwnIndex;
  HoldIconIndex = OwnIndex + 1;
  HoldDurationIndex = OwnIndex + 2;
  HoldResetAfterIndex = OwnIndex + 3;
  // Below the circle
  HoldCaptionRoom = 26;

class procedure TWinUIHoldButton.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('DoneText', TWinUIPropertyKind.Text, 'Deleted');
  AType.AddProperty('Icon', TWinUIPropertyKind.Text, 'Delete');
  AType.AddProperty('HoldDuration', TWinUIPropertyKind.Int32, '1200');
  AType.AddProperty('ResetAfter', TWinUIPropertyKind.Int32, '1600');
  AType.AddEvent('Confirmed');
end;

class function TWinUIHoldButton.DefaultText: string;
begin
  Result := 'Hold to delete';
end;

class function TWinUIHoldButton.DefaultWidth: Double;
begin
  Result := 120;
end;

class function TWinUIHoldButton.DefaultHeight: Double;
begin
  Result := 104;
end;

class function TWinUIHoldButton.DefaultAccentFrom: TWinUIColor;
begin
  Result := Rgb($3D, $6B, $FF);
end;

class function TWinUIHoldButton.DefaultAccentTo: TWinUIColor;
begin
  Result := Rgb($4F, $C3, $FF);
end;

procedure TWinUIHoldButton.Initialize;
begin
  inherited;
  ControlIntf.Foreground := RADWinUI.Abi.SolidColorBrush.New(Rgb($A7, $A3, $BC)) as IBrush;
  ControlIntf.FontSize := 12;
end;

destructor TWinUIHoldButton.Destroy;
begin
  FreeAndNil(FGlow);
  inherited;
end;

function TWinUIHoldButton.GetIsDone: Boolean;
begin
  Result := FDone;
end;

function TWinUIHoldButton.StyleXaml: string;
var
  Glyph, Filled: Char;
  Ring: TWinUIColor;
begin
  ResolveTabBarIcon(Icon, Glyph, Filled);
  Ring := ForSurface(MixColor(BackgroundColor, Rgb($FF, $FF, $FF), 0.1), MixColor(BackgroundColor, Rgb(0, 0, 0), 0.12));
  Result :=
    '<Canvas x:Name="DiscBox"><Canvas x:Name="Glow" />' +
    '<Ellipse x:Name="Track" StrokeThickness="3" Stroke="' + ColorHex(Ring) + '" />' +
    '<Ellipse x:Name="Disc" Fill="' + ColorHex(BackgroundColor) + '" Stroke="' + ColorHex(BorderColor) +
    '" StrokeThickness="1" />' +
    '<Ellipse x:Name="Done"><Ellipse.Fill>' + GradientXaml(AccentFromColor, AccentToColor, 0, 0, 1, 1) +
    '</Ellipse.Fill></Ellipse>' +
    '<Polyline x:Name="Arc" StrokeThickness="3.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round"><Polyline.Stroke>' +
    GradientXaml(AccentFromColor, AccentToColor, 0, 0, 1, 1) + '</Polyline.Stroke></Polyline>' +
    '<Grid x:Name="IconBox"><FontIcon x:Name="IconGlyph" Glyph="' + GlyphXml(Glyph) +
    '" HorizontalAlignment="Center" VerticalAlignment="Center" /></Grid>' +
    '<Polyline x:Name="Check" Stroke="White" StrokeThickness="3" StrokeStartLineCap="Round" ' +
    'StrokeEndLineCap="Round" StrokeLineJoin="Round" /></Canvas>' +
    CenteredTextXaml('Caption', Text, FontSize, 'Normal', ForegroundColor) +
    CenteredTextXaml('DoneCaption', DoneText, FontSize, 'SemiBold',
      ForSurface(MixColor(AccentToColor, Rgb($FF, $FF, $FF), 0.25), AccentFromColor));
end;

procedure TWinUIHoldButton.StyleLoaded;
begin
  FGlow := TActionButtonGlow.Create(UIPart('Glow'), Part('Done') as IShape, MixColor(AccentFromColor, AccentToColor, 0.5),
    22, 0, 2);
  Tint('IconGlyph', ForSurface(Rgb($D8, $D4, $EA), Rgb($4A, $46, $5E)));
  FCaptionSize := MeasurePart('Caption');
  FDoneSize := MeasurePart('DoneCaption');
end;

procedure TWinUIHoldButton.StyleUnloading;
begin
  FreeAndNil(FGlow);
end;

procedure TWinUIHoldButton.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    HoldDoneTextIndex, HoldIconIndex:
      Rebuild;
  end;
end;

procedure TWinUIHoldButton.Complete;
begin
  FHold := 1;
  FDone := True;
  FDoneAge := 0;
  FNeedsRelease := FPressed;
  Fire(0);
  StartRendering;
end;

procedure TWinUIHoldButton.Advance(ASeconds: Double);
begin
  inherited;
  if not FDone then
  begin
    if FPressed and not FNeedsRelease then
    begin
      FHold := FHold + ASeconds * 1000 / Max(100, HoldDuration);
      if FHold >= 1 then
        Complete;
    end
    else
      // Let go too early: the ring runs back
      FHold := Max(0, FHold - ASeconds * 3);
  end
  else
  begin
    FDoneAge := FDoneAge + ASeconds;
    if (ResetAfter > 0) and (FDoneAge >= ResetAfter / 1000) then
    begin
      FDone := False;
      FHold := 0;
    end;
  end;
  FDoneLook := Approach(FDoneLook, Ord(FDone), ASeconds, 0.35);
end;

function TWinUIHoldButton.StillMoving: Boolean;
begin
  Result := inherited or (FPressed and not FNeedsRelease) or (FHold > 0) and not FDone or
    (FDone and (ResetAfter > 0)) or (Abs(FDoneLook - Ord(FDone)) > 0.001) or (FDone and (FDoneAge < 0.6));
end;

function TWinUIHoldButton.PointerDown(AX, AY: Double): Boolean;
begin
  Result := not FDone;
end;

procedure TWinUIHoldButton.PointerUp(AX, AY: Double; AInside: Boolean);
begin
  FNeedsRelease := False;
end;

procedure TWinUIHoldButton.KeyActivate(ADown: Boolean);
begin
  if not ADown then
    FNeedsRelease := False;
end;

procedure TWinUIHoldButton.Play;
begin
  if not FDone then
    Complete;
end;

procedure TWinUIHoldButton.Reset;
begin
  FDone := False;
  FHold := 0;
  FDoneLook := 0;
  FNeedsRelease := FPressed;
  inherited;
end;

procedure TWinUIHoldButton.LayoutButton;
var
  Size, Left, Top, Inner, Look, Pop, IconSize: Double;
  Box, Element: IUIElement;
  Caption: Double;
begin
  Size := Max(16, Min(FWidth, FHeight - HoldCaptionRoom));
  Left := (FWidth - Size) / 2;
  Top := 0;
  Inner := Size - 12;
  Look := FDoneLook;
  Box := UIPart('DiscBox');
  Place(Box, Left, Top);
  // Pressed, the button sinks a little; done, it pops
  Pop := 1 - 0.05 * FPress + 0.06 * Sin(Pi * Clamp01(FDoneAge / 0.35)) * Ord(FDone);
  ScaleAt(Box, Pop, Pop, Size / 2, Size / 2);
  Element := UIPart('Track');
  Resize(Element, Size, Size);
  Place(Element, 0, 0);
  SetOpacity(Element, 1 - 0.6 * Look);
  Element := UIPart('Disc');
  Resize(Element, Inner, Inner);
  Place(Element, 6, 6);
  Element := UIPart('Done');
  Resize(Element, Inner, Inner);
  Place(Element, 6, 6);
  SetOpacity(Element, Look);
  ScaleAt(Element, 0.6 + 0.4 * EaseOutBack(Look), 0.6 + 0.4 * EaseOutBack(Look), Inner / 2, Inner / 2);
  Place(UIPart('Glow'), 6, 6);
  FGlow.Resize(Inner, Inner);
  FGlow.SetOpacity(Max(0.35 * FHold * (1 - Look), 0.75 * Look));
  Element := UIPart('Arc');
  if FHold > 0.002 then
  begin
    SetLinePoints(Element, ArcPoints(Size / 2, Size / 2, (Size - 3) / 2, FHold));
    SetOpacity(Element, 1 - Look * 0.5);
  end
  else
    SetOpacity(Element, 0);
  IconSize := Max(10, Inner * 0.32);
  Element := UIPart('IconBox');
  Resize(Element, Inner, Inner);
  Place(Element, 6, 6);
  (Part('IconGlyph') as IFontIcon).FontSize := IconSize;
  SetOpacity(Element, 1 - Look);
  ScaleAt(Element, 1 - 0.3 * Look, 1 - 0.3 * Look, Inner / 2, Inner / 2);
  Element := UIPart('Check');
  if FDone then
    SetLinePoints(Element, CheckPoints(6 + Inner * 0.2, 6 + Inner * 0.2, Inner * 0.6, (FDoneAge - 0.08) / 0.3))
  else
    SetLinePoints(Element, CheckPoints(6 + Inner * 0.2, 6 + Inner * 0.2, Inner * 0.6, 1));
  SetOpacity(Element, Look);
  // The caption under the circle, crossfading to DoneText
  Caption := Size + 8;
  Element := UIPart('CaptionBox');
  Resize(Element, FWidth, Max(FCaptionSize.Height, 16));
  Place(Element, 0, Caption);
  SetOpacity(Element, 1 - Look);
  Element := UIPart('DoneCaptionBox');
  Resize(Element, FWidth, Max(FDoneSize.Height, 16));
  Place(Element, 0, Caption + 4 * (1 - Look));
  SetOpacity(Element, Look);
end;

{ TWinUISendButton }

const
  SendDoneTextIndex = OwnIndex;
  SendResetAfterIndex = OwnIndex + 1;
  SendFlight = 0.6;
  SendFlipStart = 0.2;
  SendFlip = 0.36;
  SendBack = 0.45;
  SendTrail = 7;

class procedure TWinUISendButton.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('DoneText', TWinUIPropertyKind.Text, 'Sent!');
  AType.AddProperty('ResetAfter', TWinUIPropertyKind.Int32, '1800');
  AType.AddEvent('Click');
end;

class function TWinUISendButton.DefaultText: string;
begin
  Result := 'Send';
end;

procedure TWinUISendButton.Initialize;
begin
  inherited;
  FSendAge := -1;
  FResetAge := -1;
end;

destructor TWinUISendButton.Destroy;
begin
  FreeAndNil(FGlow);
  inherited;
end;

function TWinUISendButton.GetIsDone: Boolean;
begin
  Result := (FSendAge >= 0) and (FResetAge < 0);
end;

function TWinUISendButton.StyleXaml: string;
var
  I: Integer;
begin
  Result :=
    '<Canvas x:Name="PillBox"><Canvas x:Name="Glow" />' +
    '<Rectangle x:Name="Pill"><Rectangle.Fill>' + GradientXaml(AccentFromColor, AccentToColor, 0, 0.5, 1, 0.5) +
    '</Rectangle.Fill></Rectangle>' +
    // The labels flip inside the pill, the clip hides them outside it
    '<Canvas x:Name="Labels"><Canvas.Clip><RectangleGeometry /></Canvas.Clip>' +
    CenteredTextXaml('Label', Text, FontSize, 'SemiBold', ForegroundColor) +
    CenteredTextXaml('DoneLabel', DoneText, FontSize, 'SemiBold', ForegroundColor) + '</Canvas></Canvas>';
  // The trail and the plane fly beyond the pill, so they are outside its box
  for I := 0 to SendTrail - 1 do
    Result := Result + '<Ellipse x:Name="T' + IntToStr(I) + '" Width="3" Height="3" Fill="' +
      ColorHex(ForegroundColor) + '" />';
  Result := Result + '<Grid x:Name="Plane"><FontIcon x:Name="PlaneGlyph" Glyph="' + GlyphXml(SendGlyph) +
    '" Foreground="' + ColorHex(ForegroundColor) + '" HorizontalAlignment="Center" VerticalAlignment="Center" /></Grid>';
end;

procedure TWinUISendButton.StyleLoaded;
begin
  FGlow := TActionButtonGlow.Create(UIPart('Glow'), Part('Pill') as IShape, MixColor(AccentFromColor, AccentToColor, 0.5),
    20, 0.55, 4);
  FTextSize := MeasurePart('Label');
  FDoneSize := MeasurePart('DoneLabel');
end;

procedure TWinUISendButton.StyleUnloading;
begin
  FreeAndNil(FGlow);
end;

procedure TWinUISendButton.PropertyChanged(AIndex: Integer);
begin
  inherited;
  if AIndex = SendDoneTextIndex then
    Rebuild;
end;

procedure TWinUISendButton.Activate;
begin
  if FSendAge >= 0 then
    Exit;
  FSendAge := 0;
  FResetAge := -1;
  Fire(0);
  StartRendering;
end;

procedure TWinUISendButton.Reset;
begin
  FSendAge := -1;
  FResetAge := -1;
  inherited;
end;

procedure TWinUISendButton.Advance(ASeconds: Double);
begin
  inherited;
  if FSendAge < 0 then
    Exit;
  FSendAge := FSendAge + ASeconds;
  if FResetAge >= 0 then
  begin
    FResetAge := FResetAge + ASeconds;
    if FResetAge >= SendBack then
    begin
      FSendAge := -1;
      FResetAge := -1;
    end;
  end
  else if (ResetAfter > 0) and (FSendAge >= SendFlipStart + SendFlip + ResetAfter / 1000) then
    FResetAge := 0;
end;

function TWinUISendButton.StillMoving: Boolean;
begin
  Result := inherited or (FResetAge >= 0) or (FSendAge >= 0) and
    ((ResetAfter > 0) or (FSendAge < Max(SendFlight, SendFlipStart + SendFlip) + 0.05));
end;

function TWinUISendButton.PlaneAt(AProgress, AStartX, AStartY: Double): RADWinUI.Abi.Point;
begin
  // A short run-up backwards, then off to the upper right
  Result := Pt(AStartX + (FWidth - AStartX + 44) * EaseInBack(AProgress, 0.7),
    AStartY - (FHeight + 24) * Power(Clamp01(AProgress), 2.2));
end;

procedure TWinUISendButton.LayoutButton;
var
  Radius, IconSize, Gap, GroupWidth, GroupLeft, PlaneX, PlaneY, Flight, Flip, Back, Shift, Scale: Double;
  Box, Element: IUIElement;
  At: RADWinUI.Abi.Point;
  Bounds: RADWinUI.Abi.Rect;
  I: Integer;
  T: Double;
begin
  Radius := FHeight / 2;
  Box := UIPart('PillBox');
  Place(Box, 0, 0);
  Scale := 1 - 0.04 * FPress;
  ScaleAt(Box, Scale, Scale, FWidth / 2, FHeight / 2);
  Element := UIPart('Pill');
  Resize(Element, FWidth, FHeight);
  SetRadius(Element, Radius);
  FGlow.Resize(FWidth, FHeight);
  FGlow.SetOpacity(0.45 + 0.25 * FHover);
  IconSize := Max(10, FontSize * 1.15);
  Gap := 10;
  GroupWidth := FTextSize.Width + Gap + IconSize;
  GroupLeft := (FWidth - GroupWidth) / 2;
  if FSendAge < 0 then
  begin
    Flight := 0;
    Flip := 0;
    Back := 1;
  end
  else
  begin
    Flight := Clamp01(FSendAge / SendFlight);
    Flip := EaseInOutCubic((FSendAge - SendFlipStart) / SendFlip);
    if FResetAge >= 0 then
      Back := EaseInOutCubic(FResetAge / SendBack)
    else
      Back := 0;
  end;
  Shift := FHeight * 0.55;
  Bounds.X := 0;
  Bounds.Y := 0;
  Bounds.Width := FWidth;
  Bounds.Height := FHeight;
  UIPart('Labels').Clip.Rect := Bounds;
  // The label: up and away as DoneText comes from below, and back the other way
  Element := UIPart('LabelBox');
  Resize(Element, FTextSize.Width + 2, FHeight);
  if FResetAge >= 0 then
  begin
    Place(Element, GroupLeft, Shift * (1 - Back));
    SetOpacity(Element, Back);
  end
  else
  begin
    Place(Element, GroupLeft, -Shift * Flip);
    SetOpacity(Element, 1 - Flip);
  end;
  Element := UIPart('DoneLabelBox');
  Resize(Element, FWidth, FHeight);
  if FResetAge >= 0 then
  begin
    Place(Element, 0, -Shift * Back);
    SetOpacity(Element, 1 - Back);
  end
  else
  begin
    Place(Element, 0, Shift * (1 - Flip));
    SetOpacity(Element, Flip);
  end;
  // The plane, at rest after the label, flying, or gliding back in
  PlaneX := GroupLeft + FTextSize.Width + Gap;
  PlaneY := (FHeight - IconSize) / 2;
  (Part('PlaneGlyph') as IFontIcon).FontSize := IconSize;
  Element := UIPart('Plane');
  Resize(Element, IconSize, IconSize);
  if FSendAge < 0 then
  begin
    Place(Element, PlaneX, PlaneY);
    Element.Rotation := 0;
    SetOpacity(Element, 1);
  end
  else if FResetAge >= 0 then
  begin
    Place(Element, PlaneX - 14 * (1 - Back), PlaneY);
    Element.Rotation := 0;
    SetOpacity(Element, Back);
  end
  else
  begin
    At := PlaneAt(Flight, PlaneX, PlaneY);
    Place(Element, At.X, At.Y);
    Element.CenterPoint := Vec3(IconSize / 2, IconSize / 2, 0);
    Element.Rotation := -18 * EaseInCubic(Flight);
    SetOpacity(Element, 1 - Clamp01((Flight - 0.7) / 0.3));
  end;
  // The trail: dots where the plane just was
  for I := 0 to SendTrail - 1 do
  begin
    Element := UIPart('T' + IntToStr(I));
    T := Flight - (I + 1) * 0.055;
    if (FSendAge < 0) or (FResetAge >= 0) or (T < 0.2) or (Flight >= 1) then
    begin
      SetOpacity(Element, 0);
      Continue;
    end;
    At := PlaneAt(T, PlaneX, PlaneY);
    Place(Element, At.X + IconSize * 0.3, At.Y + IconSize * 0.62);
    SetOpacity(Element, 0.75 * (1 - I / SendTrail) * (1 - Clamp01((Flight - 0.6) / 0.4)));
  end;
end;

{ TWinUIConfettiButton }

const
  ConfettiCountIndex = OwnIndex;
  MaxConfetti = 120;
  ConfettiColors: array[0..6] of Cardinal = ($FFFF5FA8, $FFFFD34E, $FF4FD1FF, $FF8B6CFF, $FF5CF0B0, $FFFF8A4C,
    $FFFFFFFF);

class procedure TWinUIConfettiButton.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('ConfettiCount', TWinUIPropertyKind.Int32, '42');
  AType.AddEvent('Click');
end;

class function TWinUIConfettiButton.DefaultText: string;
begin
  Result := 'Celebrate';
end;

class function TWinUIConfettiButton.DefaultAccentFrom: TWinUIColor;
begin
  Result := Rgb($7B, $5C, $FF);
end;

class function TWinUIConfettiButton.DefaultAccentTo: TWinUIColor;
begin
  Result := Rgb($FF, $5F, $A8);
end;

procedure TWinUIConfettiButton.Initialize;
begin
  inherited;
  FPopAge := -1;
end;

destructor TWinUIConfettiButton.Destroy;
begin
  FreeAndNil(FGlow);
  inherited;
end;

function TWinUIConfettiButton.StyleXaml: string;
var
  I: Integer;
  Color: Cardinal;
begin
  Result :=
    '<Canvas x:Name="PillBox"><Canvas x:Name="Glow" />' +
    '<Rectangle x:Name="Pill"><Rectangle.Fill>' + GradientXaml(AccentFromColor, AccentToColor, 0, 0.5, 1, 0.5) +
    '</Rectangle.Fill></Rectangle>' +
    CenteredTextXaml('Label', Text, FontSize, 'SemiBold', ForegroundColor) + '</Canvas><Canvas x:Name="Pieces">';
  for I := 0 to MaxConfetti - 1 do
  begin
    Color := ConfettiColors[I mod Length(ConfettiColors)];
    // Most pieces are strips, some are dots
    if I mod 4 = 3 then
      Result := Result + '<Ellipse x:Name="C' + IntToStr(I) + '" Width="5" Height="5"'
    else
      Result := Result + '<Rectangle x:Name="C' + IntToStr(I) + '" Width="' + Num(3 + (I mod 3)) + '" Height="' +
        Num(7 + (I mod 2) * 2) + '" RadiusX="1" RadiusY="1"';
    Result := Result + ' Fill="#' + IntToHex(Color, 8) + '" Visibility="Collapsed" />';
  end;
  Result := Result + '</Canvas>';
end;

procedure TWinUIConfettiButton.StyleLoaded;
begin
  FGlow := TActionButtonGlow.Create(UIPart('Glow'), Part('Pill') as IShape, MixColor(AccentFromColor, AccentToColor, 0.5),
    20, 0.5, 4);
  FTextSize := MeasurePart('Label');
  if Length(FPieces) <> MaxConfetti then
    SetLength(FPieces, MaxConfetti);
end;

procedure TWinUIConfettiButton.StyleUnloading;
begin
  FreeAndNil(FGlow);
end;

procedure TWinUIConfettiButton.PropertyChanged(AIndex: Integer);
begin
  inherited;
end;

procedure TWinUIConfettiButton.Activate;
var
  I, Started, Count: Integer;
  Angle, Speed: Double;
begin
  if Length(FPieces) <> MaxConfetti then
    SetLength(FPieces, MaxConfetti);
  FPopAge := 0;
  Count := EnsureRange(ConfettiCount, 0, MaxConfetti);
  Started := 0;
  for I := 0 to High(FPieces) do
  begin
    if Started >= Count then
      Break;
    if FPieces[I].Active then
      Continue;
    // Out of the top of the button, in a fan
    Angle := -Pi / 2 + (NextRandom - 0.5) * Pi * 0.95;
    Speed := 170 + NextRandom * 230;
    FPieces[I].Active := True;
    FPieces[I].X := FWidth / 2 + (NextRandom - 0.5) * FWidth * 0.7;
    FPieces[I].Y := FHeight * (0.2 + NextRandom * 0.3);
    FPieces[I].VX := Cos(Angle) * Speed * 1.15;
    FPieces[I].VY := Sin(Angle) * Speed;
    FPieces[I].Angle := NextRandom * 360;
    FPieces[I].Spin := (NextRandom - 0.5) * 900;
    FPieces[I].Flip := NextRandom * 2 * Pi;
    FPieces[I].FlipSpeed := 6 + NextRandom * 10;
    FPieces[I].Sway := NextRandom * 2 * Pi;
    FPieces[I].Age := 0;
    FPieces[I].Life := 0.95 + NextRandom * 0.6;
    Inc(Started);
  end;
  Fire(0);
  StartRendering;
end;

procedure TWinUIConfettiButton.Reset;
var
  I: Integer;
begin
  for I := 0 to High(FPieces) do
    FPieces[I].Active := False;
  FPopAge := -1;
  inherited;
end;

function TWinUIConfettiButton.FlyingCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(FPieces) do
    if FPieces[I].Active then
      Inc(Result);
end;

procedure TWinUIConfettiButton.Advance(ASeconds: Double);
var
  I: Integer;
  Drag: Double;
begin
  inherited;
  if FPopAge >= 0 then
  begin
    FPopAge := FPopAge + ASeconds;
    if FPopAge > 0.4 then
      FPopAge := -1;
  end;
  Drag := Max(0, 1 - 2.2 * ASeconds);
  for I := 0 to High(FPieces) do
    if FPieces[I].Active then
      with FPieces[I] do
      begin
        Age := Age + ASeconds;
        if Age >= Life then
        begin
          Active := False;
          Continue;
        end;
        // Gravity, air that slows them, and a sway as they flutter down
        VY := Min(VY + 560 * ASeconds, 120);
        VX := VX * Drag;
        X := X + (VX + 26 * Sin(Sway + Age * 7)) * ASeconds;
        Y := Y + VY * ASeconds;
        Angle := Angle + Spin * ASeconds;
        Flip := Flip + FlipSpeed * ASeconds;
      end;
end;

function TWinUIConfettiButton.StillMoving: Boolean;
begin
  Result := inherited or (FPopAge >= 0) or (FlyingCount > 0);
end;

procedure TWinUIConfettiButton.LayoutButton;
var
  Box, Element: IUIElement;
  Scale: Double;
  I: Integer;
begin
  Box := UIPart('PillBox');
  Place(Box, 0, 0);
  Scale := 1 - 0.05 * FPress;
  if FPopAge >= 0 then
    Scale := Scale + 0.07 * Sin(Pi * Clamp01(FPopAge / 0.4));
  ScaleAt(Box, Scale, Scale, FWidth / 2, FHeight / 2);
  Element := UIPart('Pill');
  Resize(Element, FWidth, FHeight);
  SetRadius(Element, FHeight / 2);
  FGlow.Resize(FWidth, FHeight);
  FGlow.SetOpacity(0.4 + 0.3 * FHover + 0.3 * Ord(FPopAge >= 0));
  Element := UIPart('LabelBox');
  Resize(Element, FWidth, FHeight);
  Place(Element, 0, 0);
  for I := 0 to High(FPieces) do
  begin
    Element := UIPart('C' + IntToStr(I));
    if Element = nil then
      Continue;
    if not FPieces[I].Active then
    begin
      if Element.Visibility = TWinUIVisibility.Visible then
        SetOpacity(Element, 0);
      Continue;
    end;
    Place(Element, FPieces[I].X, FPieces[I].Y);
    Element.CenterPoint := Vec3(2, 4, 0);
    Element.Rotation := FPieces[I].Angle;
    // Turning over in the air: it gets thin, then wide again
    Element.Scale := Vec3(0.25 + 0.75 * Abs(Cos(FPieces[I].Flip)), 1, 1);
    SetOpacity(Element, 1 - Clamp01((FPieces[I].Age - FPieces[I].Life + 0.4) / 0.4));
  end;
end;

{ TWinUICopyButton }

function TWinUICopyButton.AutomationName: string;
begin
  Result := 'Copy ' + Text;
end;

const
  CopyDoneTextIndex = OwnIndex;
  CopyResetAfterIndex = OwnIndex + 1;
  CopyToClipboardIndex = OwnIndex + 2;
  CopyMargin = 6;

class procedure TWinUICopyButton.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('DoneText', TWinUIPropertyKind.Text, 'Copied!');
  AType.AddProperty('ResetAfter', TWinUIPropertyKind.Int32, '1600');
  AType.AddProperty('CopyToClipboard', TWinUIPropertyKind.Boolean, 'True');
  AType.AddEvent('Copied');
end;

class function TWinUICopyButton.DefaultText: string;
begin
  Result := 'join.app/x7Kq2';
end;

class function TWinUICopyButton.DefaultWidth: Double;
begin
  Result := 240;
end;

class function TWinUICopyButton.DefaultHeight: Double;
begin
  Result := 50;
end;

class function TWinUICopyButton.DefaultAccentFrom: TWinUIColor;
begin
  Result := Rgb($3D, $6B, $FF);
end;

class function TWinUICopyButton.DefaultAccentTo: TWinUIColor;
begin
  Result := Rgb($5A, $9B, $FF);
end;

procedure TWinUICopyButton.Initialize;
begin
  inherited;
  ControlIntf.Foreground := RADWinUI.Abi.SolidColorBrush.New(Rgb($D8, $D4, $EA)) as IBrush;
  ControlIntf.FontSize := 14;
end;

function TWinUICopyButton.GetIsDone: Boolean;
begin
  Result := FDone;
end;

function TWinUICopyButton.StyleXaml: string;
var
  IconColor, Square: TWinUIColor;
begin
  IconColor := ForSurface(Rgb($C9, $C5, $DC), Rgb($4A, $46, $5E));
  Square := ForSurface(MixColor(BackgroundColor, Rgb($FF, $FF, $FF), 0.07), MixColor(BackgroundColor, Rgb(0, 0, 0), 0.06));
  Result :=
    '<Rectangle x:Name="Field" Fill="' + ColorHex(BackgroundColor) + '" Stroke="' + ColorHex(BorderColor) +
    '" StrokeThickness="1" />' +
    // The selection behind the text while it shows Copied
    '<Rectangle x:Name="Highlight" RadiusX="4" RadiusY="4" Fill="' + ColorHex(WithAlpha(AccentFromColor, 0.38)) + '" />' +
    '<TextBlock x:Name="Value" Text="' + XmlText(Text) + '" FontFamily="Cascadia Mono, Consolas" FontSize="' +
    Num(FontSize) + '" Foreground="' + ColorHex(ForegroundColor) + '" TextTrimming="CharacterEllipsis" />' +
    '<Canvas x:Name="IconBox">' +
    '<Rectangle x:Name="Square" RadiusX="9" RadiusY="9" Fill="' + ColorHex(Square) + '" />' +
    '<Rectangle x:Name="DoneSquare" RadiusX="9" RadiusY="9"><Rectangle.Fill>' +
    GradientXaml(AccentFromColor, AccentToColor, 0, 0, 1, 1) + '</Rectangle.Fill></Rectangle>' +
    '<Grid x:Name="CopyBox"><FontIcon x:Name="CopyGlyph" Glyph="' + GlyphXml(CopyGlyph) + '" Foreground="' +
    ColorHex(IconColor) + '" HorizontalAlignment="Center" VerticalAlignment="Center" /></Grid>' +
    '<Polyline x:Name="Check" Stroke="White" StrokeThickness="2.5" StrokeStartLineCap="Round" ' +
    'StrokeEndLineCap="Round" StrokeLineJoin="Round" /></Canvas>' +
    // The tooltip above the icon
    '<Canvas x:Name="Tip"><Rectangle x:Name="TipBack" RadiusX="9" RadiusY="9" Fill="#FFF7F6FB" />' +
    '<Polygon x:Name="TipArrow" Fill="#FFF7F6FB" />' +
    '<TextBlock x:Name="TipText" Text="' + XmlText(DoneText) + '" FontSize="12" FontWeight="SemiBold" ' +
    'Foreground="#FF16141F" /></Canvas>';
end;

procedure TWinUICopyButton.StyleLoaded;
begin
  FTipSize := MeasurePart('TipText');
end;

procedure TWinUICopyButton.PropertyChanged(AIndex: Integer);
begin
  inherited;
  if AIndex = CopyDoneTextIndex then
    Rebuild;
end;

procedure TWinUICopyButton.Activate;
begin
  if CopyToClipboard then
    CopyTextToClipboard(Text);
  FDone := True;
  FDoneAge := 0;
  Fire(0);
  StartRendering;
end;

procedure TWinUICopyButton.Reset;
begin
  FDone := False;
  FDoneLook := 0;
  inherited;
end;

procedure TWinUICopyButton.Advance(ASeconds: Double);
begin
  inherited;
  if FDone then
  begin
    FDoneAge := FDoneAge + ASeconds;
    if (ResetAfter > 0) and (FDoneAge >= ResetAfter / 1000) then
      FDone := False;
  end;
  FDoneLook := Approach(FDoneLook, Ord(FDone), ASeconds, 0.25);
end;

function TWinUICopyButton.StillMoving: Boolean;
begin
  Result := inherited or (FDone and ((ResetAfter > 0) or (FDoneAge < 0.6))) or (Abs(FDoneLook - Ord(FDone)) > 0.001);
end;

procedure TWinUICopyButton.LayoutButton;
var
  Element, Box: IUIElement;
  Square, SquareLeft, SquareTop, Look, Pop, TextHeight, TipWidth, TipHeight, TipLeft, TipTop, TipScale: Double;
  ValueSize: RADWinUI.Abi.Size;
  Radius: Double;
begin
  Look := FDoneLook;
  Radius := Min(ControlIntf.CornerRadius.TopLeft, FHeight / 2);
  Element := UIPart('Field');
  Resize(Element, FWidth, FHeight);
  SetRadius(Element, Radius);
  Square := Max(16, FHeight - 2 * CopyMargin);
  SquareLeft := FWidth - CopyMargin - Square;
  SquareTop := CopyMargin;
  // The text, trimmed before the icon
  Element := UIPart('Value');
  (Element as IFrameworkElement).MaxWidth := Max(0, SquareLeft - 14 - 10);
  ValueSize := MeasurePart('Value');
  TextHeight := ValueSize.Height;
  Place(Element, 14, (FHeight - TextHeight) / 2);
  Element := UIPart('Highlight');
  Resize(Element, ValueSize.Width + 8, TextHeight + 4);
  Place(Element, 10, (FHeight - TextHeight) / 2 - 2);
  SetOpacity(Element, Look);
  // The icon square: grey copy icon, then the accent with a check
  Box := UIPart('IconBox');
  Place(Box, SquareLeft, SquareTop);
  Pop := 1 - 0.08 * FPress;
  if FDone then
    Pop := Pop + 0.1 * Sin(Pi * Clamp01(FDoneAge / 0.3));
  ScaleAt(Box, Pop, Pop, Square / 2, Square / 2);
  Resize(UIPart('Square'), Square, Square);
  Element := UIPart('DoneSquare');
  Resize(Element, Square, Square);
  SetOpacity(Element, Look);
  Element := UIPart('CopyBox');
  Resize(Element, Square, Square);
  (Part('CopyGlyph') as IFontIcon).FontSize := Max(10, Square * 0.42);
  SetOpacity(Element, 1 - Look);
  ScaleAt(Element, 1 - 0.4 * Look, 1 - 0.4 * Look, Square / 2, Square / 2);
  Element := UIPart('Check');
  if FDone then
    SetLinePoints(Element, CheckPoints(Square * 0.2, Square * 0.2, Square * 0.6, (FDoneAge - 0.05) / 0.25))
  else
    SetLinePoints(Element, CheckPoints(Square * 0.2, Square * 0.2, Square * 0.6, 1));
  SetOpacity(Element, Look);
  // The tooltip pops up above the icon
  TipWidth := FTipSize.Width + 20;
  TipHeight := FTipSize.Height + 10;
  TipLeft := SquareLeft + Square / 2 - TipWidth / 2;
  TipLeft := Min(TipLeft, FWidth - TipWidth + 8);
  TipTop := -TipHeight - 8;
  Element := UIPart('Tip');
  Place(Element, TipLeft, TipTop + 6 * (1 - Look));
  TipScale := 0.7 + 0.3 * EaseOutBack(Look, 1.8);
  ScaleAt(Element, TipScale, TipScale, SquareLeft + Square / 2 - TipLeft, TipHeight + 6);
  SetOpacity(Element, Look);
  Resize(UIPart('TipBack'), TipWidth, TipHeight);
  Place(UIPart('TipText'), 10, 5);
  SetLinePoints(Part('TipArrow'), [Pt(SquareLeft + Square / 2 - TipLeft - 6, TipHeight - 1),
    Pt(SquareLeft + Square / 2 - TipLeft + 6, TipHeight - 1), Pt(SquareLeft + Square / 2 - TipLeft, TipHeight + 6)]);
end;

{ TWinUIShineButton }

const
  ShineIntervalIndex = OwnIndex;
  ShineSparklesIndex = OwnIndex + 1;
  ShineGlowBrushIndex = OwnIndex + 2;
  ShineSweep = 0.85;
  // Where the four twinkling stars sit, relative to the button, and their size
  StarPlaces: array[0..3, 0..2] of Double = ((0.07, -0.08, 5), (0.93, -0.16, 6.5), (0.99, 1.02, 5.5), (0.28, 1.12, 4));

class procedure TWinUIShineButton.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('ShineInterval', TWinUIPropertyKind.Int32, '2600');
  AType.AddProperty('Sparkles', TWinUIPropertyKind.Boolean, 'True');
  AType.AddProperty('GlowBrush', TWinUIPropertyKind.Brush);
  AType.AddEvent('Click');
end;

class function TWinUIShineButton.DefaultText: string;
begin
  Result := 'Upgrade to Pro';
end;

class function TWinUIShineButton.DefaultWidth: Double;
begin
  Result := 200;
end;

class function TWinUIShineButton.DefaultAccentFrom: TWinUIColor;
begin
  Result := Rgb($6A, $5C, $FF);
end;

class function TWinUIShineButton.DefaultAccentTo: TWinUIColor;
begin
  Result := Rgb($FF, $5F, $A0);
end;

procedure TWinUIShineButton.Initialize;
begin
  inherited;
  FShineAge := -1;
  FNextShine := 0.6;
  FPopAge := -1;
end;

destructor TWinUIShineButton.Destroy;
begin
  FreeAndNil(FGlow);
  inherited;
end;

function TWinUIShineButton.StyleXaml: string;
var
  I: Integer;
begin
  Result :=
    '<Canvas x:Name="PillBox"><Canvas x:Name="Glow" />' +
    '<Rectangle x:Name="Pill"><Rectangle.Fill>' + GradientXaml(AccentFromColor, AccentToColor, 0, 0.5, 1, 0.5) +
    '</Rectangle.Fill></Rectangle>' +
    // The shine: a diagonal band of light, the pill's own shape keeps it inside
    '<Rectangle x:Name="Shine"><Rectangle.Fill>' + BandXaml(Rgb($FF, $FF, $FF, 0), Rgb($FF, $FF, $FF, $78), 0, 0, 1, 1) +
    '</Rectangle.Fill></Rectangle>' +
    '<Polygon x:Name="Spark" Fill="#FFFFE8A3" />' +
    '<TextBlock x:Name="Label" Text="' + XmlText(Text) + '" FontSize="' + Num(FontSize) + '" FontWeight="SemiBold" ' +
    'Foreground="' + ColorHex(ForegroundColor) + '" TextLineBounds="Tight" /></Canvas>';
  for I := 0 to High(StarPlaces) do
    if Odd(I) then
      Result := Result + '<Polygon x:Name="S' + IntToStr(I) + '" Fill="#FFFFF4D0" />'
    else
      Result := Result + '<Polygon x:Name="S' + IntToStr(I) + '" Fill="#FFFFFFFF" />';
end;

procedure TWinUIShineButton.StyleLoaded;
begin
  FGlow := TActionButtonGlow.Create(UIPart('Glow'), Part('Pill') as IShape,
    BrushColor(GetPropValue(ShineGlowBrushIndex), Rgb($FF, $C8, $61)), 18, 0.7, 0);
  FTextSize := MeasurePart('Label');
end;

procedure TWinUIShineButton.StyleUnloading;
begin
  FreeAndNil(FGlow);
end;

procedure TWinUIShineButton.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    ShineGlowBrushIndex:
      Rebuild;
    ShineIntervalIndex, ShineSparklesIndex:
      StartRendering;
  end;
end;

procedure TWinUIShineButton.StartShine;
begin
  if FShineAge < 0 then
    FShineAge := 0;
  FNextShine := Max(ShineInterval, 0) / 1000;
  StartRendering;
end;

procedure TWinUIShineButton.Activate;
begin
  FPopAge := 0;
  FShineAge := 0;
  FNextShine := Max(ShineInterval, 0) / 1000;
  Fire(0);
  StartRendering;
end;

procedure TWinUIShineButton.Reset;
begin
  FShineAge := -1;
  FPopAge := -1;
  FNextShine := Max(ShineInterval, 0) / 1000;
  inherited;
end;

procedure TWinUIShineButton.Advance(ASeconds: Double);
var
  WasHovered: Boolean;
begin
  WasHovered := FHover > 0.5;
  inherited;
  if FShineAge >= 0 then
  begin
    FShineAge := FShineAge + ASeconds;
    if FShineAge >= ShineSweep then
      FShineAge := -1;
  end;
  if ShineInterval > 0 then
  begin
    FNextShine := FNextShine - ASeconds;
    if FNextShine <= 0 then
      StartShine;
  end;
  // Hovering starts a shine of its own
  if not WasHovered and (FHover > 0.5) and (FShineAge < 0) then
    StartShine;
  if FPopAge >= 0 then
  begin
    FPopAge := FPopAge + ASeconds;
    if FPopAge >= 0.4 then
      FPopAge := -1;
  end;
end;

function TWinUIShineButton.StillMoving: Boolean;
begin
  Result := inherited or (FShineAge >= 0) or (FPopAge >= 0) or FLoaded and ((ShineInterval > 0) or Sparkles);
end;

procedure TWinUIShineButton.LayoutButton;
var
  Box, Element: IUIElement;
  Scale, Radius, SparkSize, GroupWidth, Left, Twinkle, Phase, Glow: Double;
  I: Integer;
begin
  Radius := FHeight / 2;
  Box := UIPart('PillBox');
  Place(Box, 0, 0);
  Scale := 1 - 0.04 * FPress;
  if FPopAge >= 0 then
    Scale := Scale + 0.06 * Sin(Pi * Clamp01(FPopAge / 0.4));
  ScaleAt(Box, Scale, Scale, FWidth / 2, FHeight / 2);
  Element := UIPart('Pill');
  Resize(Element, FWidth, FHeight);
  SetRadius(Element, Radius);
  Element := UIPart('Shine');
  Resize(Element, FWidth, FHeight);
  SetRadius(Element, Radius);
  if FShineAge >= 0 then
  begin
    SetOpacity(Element, 1);
    SetBand((Element as IShape).Fill, Lerp(-0.25, 1.25, EaseInOutCubic(FShineAge / ShineSweep)), 0.16);
  end
  else
    SetOpacity(Element, 0);
  // The glow breathes softly and grows on hover and click
  Glow := 0.5 + 0.12 * Sin(FClock * 2.2) + 0.25 * FHover + 0.3 * Ord(FPopAge >= 0);
  FGlow.Resize(FWidth, FHeight);
  FGlow.SetOpacity(Glow);
  // The sparkle and the label, centred together
  SparkSize := Max(8, FontSize * 0.95);
  GroupWidth := SparkSize + 8 + FTextSize.Width;
  Left := (FWidth - GroupWidth) / 2;
  Element := UIPart('Spark');
  SetLinePoints(Element, StarPoints(SparkSize / 2, SparkSize / 2, SparkSize / 2));
  Place(Element, Left, (FHeight - SparkSize) / 2);
  ScaleAt(Element, 0.85 + 0.15 * Sin(FClock * 3), 0.85 + 0.15 * Sin(FClock * 3), SparkSize / 2, SparkSize / 2);
  Place(UIPart('Label'), Left + SparkSize + 8, (FHeight - FTextSize.Height) / 2);
  // The twinkling stars around the button, one after another
  for I := 0 to High(StarPlaces) do
  begin
    Element := UIPart('S' + IntToStr(I));
    if not Sparkles then
    begin
      SetOpacity(Element, 0);
      Continue;
    end;
    Phase := Frac(FClock / 1.8 + I * 0.27);
    Twinkle := Max(0, Sin(Pi * Clamp01(Phase / 0.55)));
    if FPopAge >= 0 then
      Twinkle := Max(Twinkle, Sin(Pi * Clamp01(FPopAge / 0.4)));
    // Drawn in its own square, a shape does not show points left of or above itself
    SetLinePoints(Element, StarPoints(StarPlaces[I, 2], StarPlaces[I, 2], StarPlaces[I, 2]));
    Place(Element, FWidth * StarPlaces[I, 0] - StarPlaces[I, 2], FHeight * StarPlaces[I, 1] - StarPlaces[I, 2]);
    Element.CenterPoint := Vec3(StarPlaces[I, 2], StarPlaces[I, 2], 0);
    Element.Scale := Vec3(0.2 + 0.8 * Twinkle, 0.2 + 0.8 * Twinkle, 1);
    Element.Rotation := 45 * Phase;
    SetOpacity(Element, Twinkle);
  end;
end;

{ TWinUISlideButton }

const
  SlideDoneTextIndex = OwnIndex;
  SlideResetAfterIndex = OwnIndex + 1;
  SlideShimmerIndex = OwnIndex + 2;
  SlideInset = 4;
  // Let go past this and the knob goes the rest of the way
  SlideThreshold = 0.85;

class procedure TWinUISlideButton.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('DoneText', TWinUIPropertyKind.Text, 'Confirmed');
  AType.AddProperty('ResetAfter', TWinUIPropertyKind.Int32, '2000');
  AType.AddProperty('Shimmer', TWinUIPropertyKind.Boolean, 'True');
  AType.AddEvent('Confirmed');
end;

class function TWinUISlideButton.DefaultText: string;
begin
  Result := 'Slide to confirm';
end;

class function TWinUISlideButton.DefaultWidth: Double;
begin
  Result := 260;
end;

class function TWinUISlideButton.DefaultHeight: Double;
begin
  Result := 56;
end;

procedure TWinUISlideButton.Initialize;
var
  Corners: RADWinUI.Abi.CornerRadius;
begin
  inherited;
  ControlIntf.Foreground := RADWinUI.Abi.SolidColorBrush.New(Rgb($A7, $A3, $BC)) as IBrush;
  Corners.TopLeft := 28;
  Corners.TopRight := 28;
  Corners.BottomRight := 28;
  Corners.BottomLeft := 28;
  ControlIntf.CornerRadius := Corners;
end;

destructor TWinUISlideButton.Destroy;
begin
  FreeAndNil(FGlow);
  inherited;
end;

function TWinUISlideButton.GetIsDone: Boolean;
begin
  Result := FDone;
end;

function TWinUISlideButton.KnobSize: Double;
begin
  Result := Max(12, FHeight - 2 * SlideInset);
end;

function TWinUISlideButton.Travel: Double;
begin
  Result := Max(1, FWidth - 2 * SlideInset - KnobSize);
end;

function TWinUISlideButton.StyleXaml: string;
var
  Light: TWinUIColor;
begin
  Light := ForSurface(Rgb($FF, $FF, $FF), Rgb($20, $1C, $30));
  Result :=
    '<Rectangle x:Name="Track" Fill="' + ColorHex(BackgroundColor) + '" Stroke="' + ColorHex(BorderColor) +
    '" StrokeThickness="1" />' +
    '<Rectangle x:Name="Fill"><Rectangle.Fill>' + GradientXaml(AccentFromColor, AccentToColor, 0, 0.5, 1, 0.5) +
    '</Rectangle.Fill></Rectangle>' +
    // The label, with a light that runs over it while it waits
    '<TextBlock x:Name="Label" Text="' + XmlText(Text) + '" FontSize="' + Num(FontSize) + '" FontWeight="SemiBold" ' +
    'TextLineBounds="Tight"><TextBlock.Foreground>' + BandXaml(ForegroundColor, Light, 0, 0.5, 1, 0.5) +
    '</TextBlock.Foreground></TextBlock>' +
    CenteredTextXaml('DoneLabel', DoneText, FontSize, 'SemiBold', Rgb($FF, $FF, $FF)) +
    '<Canvas x:Name="KnobBox"><Canvas x:Name="Glow" />' +
    '<Ellipse x:Name="Knob"><Ellipse.Fill>' + GradientXaml(AccentFromColor, MixColor(AccentFromColor, AccentToColor, 0.6),
    0, 0, 1, 1) + '</Ellipse.Fill></Ellipse>' +
    '<Ellipse x:Name="KnobRing" Stroke="#55FFFFFF" StrokeThickness="1.5" />' +
    '<Canvas x:Name="Chevrons">' +
    '<FontIcon x:Name="Chevron1" Glyph="' + GlyphXml(ChevronGlyph) + '" Foreground="White" />' +
    '<FontIcon x:Name="Chevron2" Glyph="' + GlyphXml(ChevronGlyph) + '" Foreground="White" /></Canvas>' +
    '<Polyline x:Name="Check" Stroke="White" StrokeThickness="2.5" StrokeStartLineCap="Round" ' +
    'StrokeEndLineCap="Round" StrokeLineJoin="Round" /></Canvas>';
end;

procedure TWinUISlideButton.StyleLoaded;
begin
  FGlow := TActionButtonGlow.Create(UIPart('Glow'), Part('Knob') as IShape, MixColor(AccentFromColor, AccentToColor, 0.4),
    16, 0.6, 2);
  FTextSize := MeasurePart('Label');
  FDoneSize := MeasurePart('DoneLabel');
end;

procedure TWinUISlideButton.StyleUnloading;
begin
  FreeAndNil(FGlow);
end;

procedure TWinUISlideButton.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    SlideDoneTextIndex:
      Rebuild;
    SlideShimmerIndex:
      StartRendering;
  end;
end;

procedure TWinUISlideButton.TweenTo(ATarget, ASeconds: Double);
begin
  FTweenFrom := FPosition;
  FTweenTo := ATarget;
  FTweenAge := 0;
  FTweenTime := Max(0.05, ASeconds);
  FTweening := True;
  StartRendering;
end;

procedure TWinUISlideButton.Complete;
begin
  FDone := True;
  FDoneAge := 0;
  Fire(0);
  StartRendering;
end;

function TWinUISlideButton.PointerDown(AX, AY: Double): Boolean;
begin
  // Only the knob drags, grabbed where it was pressed so it does not jump
  Result := not FDone and not FTweening and (AX >= SlideInset + FPosition * Travel - 6) and
    (AX <= SlideInset + FPosition * Travel + KnobSize + 6);
  if not Result then
    Exit;
  FGrab := AX - (SlideInset + FPosition * Travel);
  FDragging := True;
end;

procedure TWinUISlideButton.PointerDrag(AX, AY: Double);
begin
  if not FDragging then
    Exit;
  FPosition := Clamp01((AX - FGrab - SlideInset) / Travel);
  if Built then
    LayoutButton;
end;

procedure TWinUISlideButton.PointerUp(AX, AY: Double; AInside: Boolean);
begin
  if not FDragging then
    Exit;
  FDragging := False;
  if FPosition >= SlideThreshold then
    TweenTo(1, 0.18)
  else
    TweenTo(0, 0.45);
end;

procedure TWinUISlideButton.KeyActivate(ADown: Boolean);
begin
  if ADown then
    Play;
end;

procedure TWinUISlideButton.Play;
begin
  if FDone or FTweening or FDragging then
    Exit;
  TweenTo(1, 0.55);
end;

procedure TWinUISlideButton.Reset;
begin
  FDone := False;
  FDoneLook := 0;
  FTweening := False;
  FDragging := False;
  FPosition := 0;
  inherited;
end;

procedure TWinUISlideButton.Advance(ASeconds: Double);
begin
  inherited;
  if FTweening then
  begin
    FTweenAge := FTweenAge + ASeconds;
    if FTweenTo < FTweenFrom then
      // Back with a little spring
      FPosition := Lerp(FTweenFrom, FTweenTo, EaseOutBack(FTweenAge / FTweenTime, 1.1))
    else
      FPosition := Lerp(FTweenFrom, FTweenTo, EaseInOutCubic(FTweenAge / FTweenTime));
    FPosition := Clamp01(FPosition);
    if FTweenAge >= FTweenTime then
    begin
      FTweening := False;
      FPosition := FTweenTo;
      if (FTweenTo >= 1) and not FDone then
        Complete;
    end;
  end;
  if FDone then
  begin
    FDoneAge := FDoneAge + ASeconds;
    if (ResetAfter > 0) and (FDoneAge >= ResetAfter / 1000) then
    begin
      FDone := False;
      TweenTo(0, 0.5);
    end;
  end;
  FDoneLook := Approach(FDoneLook, Ord(FDone), ASeconds, 0.3);
end;

function TWinUISlideButton.StillMoving: Boolean;
begin
  Result := inherited or FTweening or (FDone and ((ResetAfter > 0) or (FDoneAge < 0.6))) or
    (Abs(FDoneLook - Ord(FDone)) > 0.001) or FLoaded and Shimmer and not FDone and (FPosition < 0.01);
end;

procedure TWinUISlideButton.LayoutButton;
var
  Element, Box: IUIElement;
  Knob, Left, Radius, LabelLeft, LabelArea, Look, ChevronSize, Pop: Double;
begin
  Look := FDoneLook;
  Knob := KnobSize;
  Radius := Min(ControlIntf.CornerRadius.TopLeft, FHeight / 2);
  Element := UIPart('Track');
  Resize(Element, FWidth, FHeight);
  SetRadius(Element, Radius);
  Left := SlideInset + FPosition * Travel;
  // The fill follows the knob from the left, and covers the track once done
  Element := UIPart('Fill');
  Resize(Element, Lerp(Left + Knob + SlideInset, FWidth, Look), FHeight);
  SetRadius(Element, Radius);
  SetOpacity(Element, Max(Clamp01(FPosition * 6), Look));
  // The label right of the knob, fading as the knob passes over it
  Element := UIPart('Label');
  LabelArea := FWidth - Knob - 2 * SlideInset;
  LabelLeft := Knob + SlideInset + (LabelArea - FTextSize.Width) / 2;
  Place(Element, LabelLeft, (FHeight - FTextSize.Height) / 2);
  SetOpacity(Element, (1 - Clamp01(FPosition * 1.8)) * (1 - Look));
  if Shimmer and (FPosition < 0.01) and not FDone then
    SetBand((Element as ITextBlock).Foreground, Lerp(-0.3, 1.3, Frac(FClock / 2.2) * 1.4), 0.14)
  else
    SetBand((Element as ITextBlock).Foreground, -1, 0.14);
  Element := UIPart('DoneLabelBox');
  Resize(Element, FWidth - Knob - SlideInset, FHeight);
  Place(Element, 0, 3 * (1 - Look));
  SetOpacity(Element, Look);
  // The knob, its chevrons and the check that replaces them
  Box := UIPart('KnobBox');
  Place(Box, Left, SlideInset);
  Pop := 1 - 0.06 * FPress;
  if FDone then
    Pop := Pop + 0.08 * Sin(Pi * Clamp01(FDoneAge / 0.3));
  ScaleAt(Box, Pop, Pop, Knob / 2, Knob / 2);
  Resize(UIPart('Knob'), Knob, Knob);
  Resize(UIPart('KnobRing'), Knob, Knob);
  FGlow.Resize(Knob, Knob);
  FGlow.SetOpacity(0.5 + 0.3 * FHover + 0.2 * Look);
  ChevronSize := Max(8, Knob * 0.3);
  (Part('Chevron1') as IFontIcon).FontSize := ChevronSize;
  (Part('Chevron2') as IFontIcon).FontSize := ChevronSize;
  Place(UIPart('Chevron1'), Knob / 2 - ChevronSize * 0.78, Knob / 2 - ChevronSize / 2);
  Place(UIPart('Chevron2'), Knob / 2 - ChevronSize * 0.28, Knob / 2 - ChevronSize / 2);
  Element := UIPart('Chevrons');
  SetOpacity(Element, 1 - Look);
  // While waiting, the chevrons nudge to the right
  if not FDone and (FPosition < 0.01) and not FPressed then
    Place(Element, 2.5 * Max(0, Sin(FClock * 4)), 0)
  else
    Place(Element, 0, 0);
  Element := UIPart('Check');
  if FDone then
    SetLinePoints(Element, CheckPoints(Knob * 0.22, Knob * 0.22, Knob * 0.56, (FDoneAge - 0.05) / 0.28))
  else
    SetLinePoints(Element, CheckPoints(Knob * 0.22, Knob * 0.22, Knob * 0.56, 1));
  SetOpacity(Element, Look);
end;

initialization
  TWinUICustomControls.Register(TWinUIHoldButton, 'HoldButton', ActionButtonsCategory);
  TWinUICustomControls.Register(TWinUISendButton, 'SendButton', ActionButtonsCategory);
  TWinUICustomControls.Register(TWinUIConfettiButton, 'ConfettiButton', ActionButtonsCategory);
  TWinUICustomControls.Register(TWinUICopyButton, 'CopyButton', ActionButtonsCategory);
  TWinUICustomControls.Register(TWinUIShineButton, 'ShineButton', ActionButtonsCategory);
  TWinUICustomControls.Register(TWinUISlideButton, 'SlideButton', ActionButtonsCategory);

finalization
  if ClipboardWindow <> 0 then
    DestroyWindow(ClipboardWindow);
end.
