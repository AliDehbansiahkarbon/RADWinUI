unit RADWinUI.Controls;

{
  RADWinUI's own controls, written in Delphi (RADWinUI.CustomControls) and on
  the Tool Palette's Overlay category. In XAML they live in
  xmlns:rw="using:RADWinUI.Controls".

  TWinUINotchPanel    a pill that grows into a panel on hover or by code
  TWinUIGlowTile      a tile with a coloured glow that can pulse and fade out
  TWinUIHotKey        a system-wide keyboard shortcut
  TWinUIMediaSession  the music or video playing on the PC, with play/pause

  Using this unit registers them.
}

interface

{$SCOPEDENUMS ON}

uses
  Winapi.Messages,
  System.SysUtils,
  RADWinUI.Interop.Core,
  RADWinUI.Abi,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Forms,
  RADWinUI.CustomControls;

type
  /// <summary>
  ///   A pill (Pill content, CollapsedWidth x CollapsedHeight) that grows into a
  ///   panel (Content, ExpandedWidth x ExpandedHeight) when the pointer rests on
  ///   it, and shrinks back when it leaves. Background paints both. Made for
  ///   an Overlay window docked to the top of the screen: SquareTop keeps the
  ///   edge that touches the screen straight.
  /// </summary>
  TWinUINotchPanel = class(TWinUICustomControl)
  strict private
    FChrome: IFrameworkElement;
    FPill: IUIElement;
    FPanel: IFrameworkElement;
    FProgress: Double;
    FFrom: Double;
    FTarget: Double;
    FStarted: Int64;
    FRenderingToken: EventRegistrationToken;
    FHoverTimer: TWinUITimer;
    FCollapseTimer: TWinUITimer;
    FPointerInside: Boolean;
    procedure TemplateReady;
    procedure Render;
    procedure ApplyProgress(AProgress: Double);
    procedure AnimateTo(ATarget: Double);
    procedure StopRendering;
    procedure HoverElapsed(Sender: TObject);
    procedure CollapseElapsed(Sender: TObject);
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure DetachEvents; override;
  public
    destructor Destroy; override;
    procedure Expand;
    procedure Collapse;
    procedure Toggle;
    /// <summary>0 collapsed .. 1 expanded, follows the animation.</summary>
    property Progress: Double read FProgress;
  published
    property IsExpanded: Boolean index 0 read GetBoolean write SetBoolean;
    property CollapsedWidth: Double index 1 read GetDouble write SetDouble;
    property CollapsedHeight: Double index 2 read GetDouble write SetDouble;
    property ExpandedWidth: Double index 3 read GetDouble write SetDouble;
    property ExpandedHeight: Double index 4 read GetDouble write SetDouble;
    /// <summary>Corner radius of the expanded panel. The pill is fully round.</summary>
    property ExpandedCornerRadius: Double index 5 read GetDouble write SetDouble;
    /// <summary>Straight top edge, for a panel that hangs from the top of the screen.</summary>
    property SquareTop: Boolean index 6 read GetBoolean write SetBoolean;
    property ExpandOnHover: Boolean index 7 read GetBoolean write SetBoolean;
    /// <summary>Milliseconds the pointer rests on the pill before it expands.</summary>
    property HoverDelay: Integer index 8 read GetInt32 write SetInt32;
    /// <summary>Milliseconds after the pointer left before the panel collapses.</summary>
    property CollapseDelay: Integer index 9 read GetInt32 write SetInt32;
    /// <summary>Milliseconds the grow and shrink animation takes.</summary>
    property AnimationDuration: Integer index 10 read GetInt32 write SetInt32;
    property OnExpanded: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
    property OnCollapsed: TWinUIWinValueEventHandler index 1 read GetHandler write SetHandler;
  end;

  /// <summary>
  ///   A rounded tile (Background, CornerRadius, Padding, Content) with a soft
  ///   coloured glow around it. Changing GlowBrush fades the glow to the new
  ///   colour, Pulse makes it breathe, FadeAfter lets it fade out by itself.
  ///   The glow is cast by the tile's shape, so it suits opaque backgrounds.
  /// </summary>
  TWinUIGlowTile = class(TWinUICustomControl)
  strict private
    FHost: IUIElement;
    FShape: IFrameworkElement;
    FSprite: ISpriteVisual;
    FShadow: IDropShadow;
    FFadeTimer: TWinUITimer;
    FSizeToken: EventRegistrationToken;
    FShownColor: TWinUIColor;
    FHasColor: Boolean;
    procedure TemplateReady;
    procedure UpdateSize;
    procedure UpdateGlow(AAnimateColor: Boolean);
    procedure FadeElapsed(Sender: TObject);
    function GlowColor: TWinUIColor;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure DetachEvents; override;
  public
    destructor Destroy; override;
  published
    /// <summary>The glow colour: a SolidColorBrush, or a gradient's first stop.</summary>
    property GlowBrush: TWinUIBrush index 0 read GetBrush write SetBrush;
    property IsGlowing: Boolean index 1 read GetBoolean write SetBoolean;
    /// <summary>How far the glow reaches, in pixels.</summary>
    property GlowRadius: Double index 2 read GetDouble write SetDouble;
    property GlowOpacity: Double index 3 read GetDouble write SetDouble;
    /// <summary>The glow breathes slowly while IsGlowing.</summary>
    property Pulse: Boolean index 4 read GetBoolean write SetBoolean;
    /// <summary>Seconds after IsGlowing turns on until the glow fades out by itself, 0 for never.</summary>
    property FadeAfter: Double index 5 read GetDouble write SetDouble;
    property OnClick: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

  /// <summary>
  ///   A system-wide keyboard shortcut such as Ctrl+Alt+T. OnPressed fires while
  ///   any program has the focus. It has no look: put it anywhere in the window.
  ///   Keys is written like a menu shortcut: modifiers Ctrl, Alt, Shift, Win
  ///   joined with + and a key (A..Z, 0..9, F1..F24, Space, Enter, Esc, Tab,
  ///   Up, Down, Left, Right, Home, End, PgUp, PgDn, Ins, Del).
  /// </summary>
  TWinUIHotKey = class(TWinUICustomControl)
  strict private
    FWindow: THandle;
    FRegistered: Boolean;
    procedure WndProc(var AMessage: TMessage);
    procedure UpdateRegistration;
    procedure Unregister;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
  public
    destructor Destroy; override;
    /// <summary>Parses Keys text into RegisterHotKey modifiers and a virtual key, False when it is not valid.</summary>
    class function ParseKeys(const AKeys: string; out AModifiers, AKey: Cardinal): Boolean; static;
    /// <summary>True while Windows holds the shortcut for this control. Another program may own it already.</summary>
    property Registered: Boolean read FRegistered;
  published
    property Keys: string index 0 read GetText write SetText;
    property IsActive: Boolean index 1 read GetBoolean write SetBoolean;
    property OnPressed: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

  /// <summary>
  ///   The media that plays on this PC right now (Spotify, a browser, the Media
  ///   Player app...), as Windows shows it in its volume flyout. Title, Artist,
  ///   AlbumTitle, IsPlaying and HasSession follow the current player and can
  ///   be bound to. PlayPause, Next and Previous control it. It has no look: put
  ///   it anywhere in the window.
  /// </summary>
  TWinUIMediaSession = class(TWinUICustomControl)
  strict private
    FQueue: IDispatcherQueue;
    FAlive: TObject;
    FAliveRef: IInterface;
    FManager: IGlobalSystemMediaTransportControlsSessionManager;
    FSession: IGlobalSystemMediaTransportControlsSession;
    FSessionToken: EventRegistrationToken;
    FMediaToken: EventRegistrationToken;
    FPlaybackToken: EventRegistrationToken;
    procedure Post(const AProc: TProc);
    procedure ManagerReady(const AManager: IGlobalSystemMediaTransportControlsSessionManager);
    procedure AttachSession;
    procedure DetachSession;
    procedure RefreshPlayback;
    procedure RefreshMedia;
    procedure MediaReady(const AProperties: IGlobalSystemMediaTransportControlsSessionMediaProperties);
    function GetConnected: Boolean;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure DetachEvents; override;
  public
    procedure Play;
    procedure Pause;
    procedure PlayPause;
    procedure Next;
    procedure Previous;
    /// <summary>The current session, nil while nothing plays. For what the properties do not cover.</summary>
    property Session: IGlobalSystemMediaTransportControlsSession read FSession;
    /// <summary>True once Windows handed over its media session list, shortly after the control is created.</summary>
    property Connected: Boolean read GetConnected;
  published
    property Title: string index 0 read GetText write SetText;
    property Artist: string index 1 read GetText write SetText;
    property AlbumTitle: string index 2 read GetText write SetText;
    /// <summary>The player's app id, for example Spotify.exe or a Store app id.</summary>
    property SourceApp: string index 3 read GetText write SetText;
    property IsPlaying: Boolean index 4 read GetBoolean write SetBoolean;
    property HasSession: Boolean index 5 read GetBoolean write SetBoolean;
    /// <summary>Fires on the UI thread after the track, the player or the play state changed.</summary>
    property OnChanged: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

const
  OverlayCategory = 'Overlay';

implementation

uses
  Winapi.Windows,
  System.Classes,
  System.Math;

const
  NotchTemplate =
    '<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:rw="using:RADWinUI.Controls" ' +
    'TargetType="rw:NotchPanel">' +
    '<Border x:Name="PART_Chrome" Background="{TemplateBinding Background}" ' +
    'BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" ' +
    'HorizontalAlignment="Center" VerticalAlignment="Top">' +
    '<Grid>' +
    '<ContentPresenter x:Name="PART_Pill" Content="{TemplateBinding Pill}" ' +
    'HorizontalContentAlignment="Center" VerticalContentAlignment="Center" />' +
    '<ContentPresenter x:Name="PART_Panel" Content="{TemplateBinding Content}" Padding="{TemplateBinding Padding}" ' +
    'HorizontalAlignment="Left" VerticalAlignment="Top" Opacity="0" Visibility="Collapsed" />' +
    '</Grid></Border></ControlTemplate>';

  GlowTemplate =
    '<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:rw="using:RADWinUI.Controls" ' +
    'TargetType="rw:GlowTile">' +
    '<Grid>' +
    '<Canvas x:Name="PART_GlowHost" />' +
    // the shape that casts the glow, hidden behind the tile
    '<Rectangle x:Name="PART_Shape" Fill="Black" />' +
    '<Border Background="{TemplateBinding Background}" CornerRadius="{TemplateBinding CornerRadius}" ' +
    'BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" ' +
    'Padding="{TemplateBinding Padding}">' +
    '<ContentPresenter Content="{TemplateBinding Content}" ' +
    'HorizontalContentAlignment="{TemplateBinding HorizontalContentAlignment}" ' +
    'VerticalContentAlignment="{TemplateBinding VerticalContentAlignment}" />' +
    '</Border></Grid></ControlTemplate>';

  // NotchPanel property indexes
  NIsExpanded = 0;
  NCollapsedWidth = 1;
  NCollapsedHeight = 2;
  NExpandedWidth = 3;
  NExpandedHeight = 4;
  NExpandedCornerRadius = 5;
  NSquareTop = 6;
  NExpandOnHover = 7;
  NHoverDelay = 8;
  NCollapseDelay = 9;
  NAnimationDuration = 10;
  NPill = 11;
  // NotchPanel events
  NExpanded = 0;
  NCollapsed = 1;

  // GlowTile property indexes
  GGlowBrush = 0;
  GIsGlowing = 1;
  GGlowRadius = 2;
  GGlowOpacity = 3;
  GPulse = 4;
  GFadeAfter = 5;

function Clamp01(AValue: Double): Double;
begin
  Result := Max(0, Min(1, AValue));
end;

function Lerp(AFrom, ATo, AProgress: Double): Double;
begin
  Result := AFrom + (ATo - AFrom) * AProgress;
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

function Ms(AValue: Integer): TimeSpan;
begin
  Result.Duration := Int64(AValue) * 10000;
end;

function Vec2(AX, AY: Single): Vector2;
begin
  Result.X := AX;
  Result.Y := AY;
end;

{ TWinUINotchPanel }

class procedure TWinUINotchPanel.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('IsExpanded', TWinUIPropertyKind.Boolean, 'False');
  AType.AddProperty('CollapsedWidth', TWinUIPropertyKind.Double, '180');
  AType.AddProperty('CollapsedHeight', TWinUIPropertyKind.Double, '34');
  AType.AddProperty('ExpandedWidth', TWinUIPropertyKind.Double, '640');
  AType.AddProperty('ExpandedHeight', TWinUIPropertyKind.Double, '260');
  AType.AddProperty('ExpandedCornerRadius', TWinUIPropertyKind.Double, '28');
  AType.AddProperty('SquareTop', TWinUIPropertyKind.Boolean, 'True');
  AType.AddProperty('ExpandOnHover', TWinUIPropertyKind.Boolean, 'True');
  AType.AddProperty('HoverDelay', TWinUIPropertyKind.Int32, '120');
  AType.AddProperty('CollapseDelay', TWinUIPropertyKind.Int32, '450');
  AType.AddProperty('AnimationDuration', TWinUIPropertyKind.Int32, '420');
  AType.AddProperty('Pill', TWinUIPropertyKind.Value);
  AType.AddEvent('Expanded');
  AType.AddEvent('Collapsed');
end;

procedure TWinUINotchPanel.Initialize;
var
  Black: TWinUISolidColorBrush;
  C: TWinUIColor;
begin
  UseTemplate(NotchTemplate);
  // A notch is black unless Background says otherwise
  Black := TWinUISolidColorBrush.Create(Self);
  C.A := $FF;
  C.R := 0;
  C.G := 0;
  C.B := 0;
  Black.Color := C;
  Background := Black;
  HorizontalAlignment := TWinUIHorizontalAlignment.Center;
  VerticalAlignment := TWinUIVerticalAlignment.Top;
  FHoverTimer := TWinUITimer.Create;
  FHoverTimer.OnTimer := HoverElapsed;
  FCollapseTimer := TWinUITimer.Create;
  FCollapseTimer.OnTimer := CollapseElapsed;
  Loaded.Add(
    procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
    begin
      TemplateReady;
    end);
  PointerEntered.Add(
    procedure(Sender: TObject; E: TWinUIPointerRoutedEventArgs)
    begin
      FPointerInside := True;
      FCollapseTimer.Enabled := False;
      if ExpandOnHover and not IsExpanded then
      begin
        FHoverTimer.Interval := Max(1, HoverDelay);
        FHoverTimer.Enabled := True;
      end;
    end);
  PointerExited.Add(
    procedure(Sender: TObject; E: TWinUIPointerRoutedEventArgs)
    begin
      FPointerInside := False;
      FHoverTimer.Enabled := False;
      if ExpandOnHover and IsExpanded then
      begin
        FCollapseTimer.Interval := Max(1, CollapseDelay);
        FCollapseTimer.Enabled := True;
      end;
    end);
end;

destructor TWinUINotchPanel.Destroy;
begin
  FHoverTimer.Free;
  FCollapseTimer.Free;
  inherited;
end;

procedure TWinUINotchPanel.DetachEvents;
begin
  StopRendering;
  inherited;
end;

procedure TWinUINotchPanel.TemplateReady;
begin
  ApplyTemplate;
  FChrome := TemplatePart('PART_Chrome') as IFrameworkElement;
  FPill := TemplatePart('PART_Pill') as IUIElement;
  FPanel := TemplatePart('PART_Panel') as IFrameworkElement;
  if IsExpanded then
    FProgress := 1
  else
    FProgress := 0;
  FTarget := FProgress;
  ApplyProgress(FProgress);
end;

procedure TWinUINotchPanel.HoverElapsed(Sender: TObject);
begin
  FHoverTimer.Enabled := False;
  if FPointerInside then
    Expand;
end;

procedure TWinUINotchPanel.CollapseElapsed(Sender: TObject);
begin
  FCollapseTimer.Enabled := False;
  if not FPointerInside then
    Collapse;
end;

procedure TWinUINotchPanel.Expand;
begin
  IsExpanded := True;
end;

procedure TWinUINotchPanel.Collapse;
begin
  IsExpanded := False;
end;

procedure TWinUINotchPanel.Toggle;
begin
  IsExpanded := not IsExpanded;
end;

procedure TWinUINotchPanel.PropertyChanged(AIndex: Integer);
begin
  case AIndex of
    NIsExpanded:
      begin
        if IsExpanded then
        begin
          AnimateTo(1);
          Fire(NExpanded);
        end
        else
        begin
          AnimateTo(0);
          Fire(NCollapsed);
        end;
      end;
    NCollapsedWidth, NCollapsedHeight, NExpandedWidth, NExpandedHeight, NExpandedCornerRadius, NSquareTop:
      ApplyProgress(FProgress);
  end;
end;

procedure TWinUINotchPanel.AnimateTo(ATarget: Double);
var
  Self_: TWinUINotchPanel;
begin
  FFrom := FProgress;
  FTarget := ATarget;
  FStarted := Ticks;
  if FChrome = nil then
  begin
    // Not loaded yet: TemplateReady shows the final state
    FProgress := ATarget;
    Exit;
  end;
  if FRenderingToken.Value <> 0 then
    Exit;
  Self_ := Self;
  // Every frame the compositor draws, until the animation ends
  FRenderingToken := CompositionTarget.add_Rendering(TEventHandler_Object.Create(
    procedure(ASender: IInspectable; AArgs: IInspectable)
    begin
      Self_.Render;
    end));
end;

procedure TWinUINotchPanel.StopRendering;
begin
  if FRenderingToken.Value <> 0 then
  begin
    CompositionTarget.remove_Rendering(FRenderingToken);
    FRenderingToken.Value := 0;
  end;
end;

procedure TWinUINotchPanel.Render;
var
  T, Eased, C1, C3: Double;
begin
  T := Clamp01(Seconds(FStarted, Ticks) * 1000 / Max(1, AnimationDuration));
  if FTarget > FFrom then
  begin
    // ease out with a slight overshoot, like a spring settling
    C1 := 0.7;
    C3 := C1 + 1;
    Eased := 1 + C3 * Power(T - 1, 3) + C1 * Sqr(T - 1);
  end
  else if T < 0.5 then
    Eased := 4 * T * T * T
  else
    Eased := 1 - Power(-2 * T + 2, 3) / 2;
  FProgress := FFrom + (FTarget - FFrom) * Eased;
  ApplyProgress(FProgress);
  if T >= 1 then
  begin
    FProgress := FTarget;
    ApplyProgress(FProgress);
    StopRendering;
  end;
end;

procedure TWinUINotchPanel.ApplyProgress(AProgress: Double);
var
  Size, Shape, PillAlpha, PanelAlpha, Radius: Double;
  Corners: TWinUICornerRadius;
begin
  if FChrome = nil then
    Exit;
  // Size may overshoot a little past 1, the corner and the fades stay in range
  Size := AProgress;
  Shape := Clamp01(AProgress);
  FChrome.Width := Max(0, Lerp(CollapsedWidth, ExpandedWidth, Size));
  FChrome.Height := Max(0, Lerp(CollapsedHeight, ExpandedHeight, Size));
  Radius := Lerp(CollapsedHeight / 2, ExpandedCornerRadius, Shape);
  Corners.BottomLeft := Radius;
  Corners.BottomRight := Radius;
  if SquareTop then
  begin
    Corners.TopLeft := 0;
    Corners.TopRight := 0;
  end
  else
  begin
    Corners.TopLeft := Radius;
    Corners.TopRight := Radius;
  end;
  (FChrome as IBorder).CornerRadius := Corners;
  // The pill fades out first, the panel fades in once there is room for it
  PillAlpha := 1 - Clamp01(Shape / 0.35);
  PanelAlpha := Clamp01((Shape - 0.45) / 0.55);
  FPill.Opacity := PillAlpha;
  if PillAlpha > 0 then
    FPill.Visibility := TWinUIVisibility.Visible
  else
    FPill.Visibility := TWinUIVisibility.Collapsed;
  FPanel.Width := ExpandedWidth;
  FPanel.Height := ExpandedHeight;
  (FPanel as IUIElement).Opacity := PanelAlpha;
  if PanelAlpha > 0 then
    (FPanel as IUIElement).Visibility := TWinUIVisibility.Visible
  else
    (FPanel as IUIElement).Visibility := TWinUIVisibility.Collapsed;
end;

{ TWinUIGlowTile }

class procedure TWinUIGlowTile.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('GlowBrush', TWinUIPropertyKind.Brush);
  AType.AddProperty('IsGlowing', TWinUIPropertyKind.Boolean, 'True');
  AType.AddProperty('GlowRadius', TWinUIPropertyKind.Double, '28');
  AType.AddProperty('GlowOpacity', TWinUIPropertyKind.Double, '0.85');
  AType.AddProperty('Pulse', TWinUIPropertyKind.Boolean, 'False');
  AType.AddProperty('FadeAfter', TWinUIPropertyKind.Double, '0');
  AType.AddEvent('Click');
end;

procedure TWinUIGlowTile.Initialize;
begin
  UseTemplate(GlowTemplate);
  FFadeTimer := TWinUITimer.Create;
  FFadeTimer.OnTimer := FadeElapsed;
  Loaded.Add(
    procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
    begin
      TemplateReady;
    end);
  Tapped.Add(
    procedure(Sender: TObject; E: TWinUITappedRoutedEventArgs)
    begin
      Fire(0);
    end);
end;

destructor TWinUIGlowTile.Destroy;
begin
  FFadeTimer.Free;
  inherited;
end;

procedure TWinUIGlowTile.DetachEvents;
begin
  if (FShape <> nil) and (FSizeToken.Value <> 0) then
    FShape.remove_SizeChanged(FSizeToken);
  FSizeToken.Value := 0;
  inherited;
end;

procedure TWinUIGlowTile.TemplateReady;
var
  Compositor: ICompositor;
  Self_: TWinUIGlowTile;
begin
  if FSprite <> nil then
    Exit;
  ApplyTemplate;
  FHost := TemplatePart('PART_GlowHost') as IUIElement;
  FShape := TemplatePart('PART_Shape') as IFrameworkElement;
  Compositor := (ElementCompositionPreview.GetElementVisual(FHost) as ICompositionObject).Compositor;
  FShadow := (Compositor as ICompositor2).CreateDropShadow;
  FShadow.Mask := (FShape as IShape).GetAlphaMask;
  FSprite := Compositor.CreateSpriteVisual;
  (FSprite as ISpriteVisual2).Shadow := FShadow as ICompositionShadow;
  ElementCompositionPreview.SetElementChildVisual(FHost, FSprite as IVisual);
  Self_ := Self;
  FSizeToken := FShape.add_SizeChanged(TSizeChangedEventHandler.Create(
    procedure(ASender: IInspectable; AE: ISizeChangedEventArgs)
    begin
      Self_.UpdateSize;
    end));
  UpdateSize;
  UpdateGlow(False);
end;

procedure TWinUIGlowTile.UpdateSize;
var
  Radius: Double;
begin
  if FSprite = nil then
    Exit;
  Radius := CornerRadius.TopLeft;
  (FShape as IRectangle).RadiusX := Radius;
  (FShape as IRectangle).RadiusY := Radius;
  (FSprite as IVisual).Size := Vec2(FShape.ActualWidth, FShape.ActualHeight);
end;

function TWinUIGlowTile.GlowColor: TWinUIColor;
var
  Brush: IInspectable;
  Solid: ISolidColorBrush;
  Gradient: IGradientBrush;
begin
  Result := Default(TWinUIColor);
  Brush := GetPropValue(GGlowBrush);
  if Supports(Brush, ISolidColorBrush, Solid) then
    Result := Solid.Color
  else if Supports(Brush, IGradientBrush, Gradient) and (Gradient.GradientStops.get_Size > 0) then
    Result := Gradient.GradientStops.GetAt(0).Color;
end;

procedure TWinUIGlowTile.UpdateGlow(AAnimateColor: Boolean);
var
  Target: Single;
  NewColor: TWinUIColor;
  Compositor: ICompositor;
  Fade: IScalarKeyFrameAnimation;
  Shift: IColorKeyFrameAnimation;
begin
  if FShadow = nil then
    Exit;
  Compositor := (FShadow as ICompositionObject).Compositor;
  FShadow.BlurRadius := GlowRadius;
  NewColor := GlowColor;
  if AAnimateColor and FHasColor then
  begin
    Shift := Compositor.CreateColorKeyFrameAnimation;
    Shift.InsertKeyFrame(0, FShownColor);
    Shift.InsertKeyFrame(1, NewColor);
    (Shift as IKeyFrameAnimation).Duration := Ms(450);
    (FShadow as ICompositionObject).StartAnimation(WinStr('Color'), Shift as ICompositionAnimation);
  end
  else
    FShadow.Color := NewColor;
  FShownColor := NewColor;
  FHasColor := True;
  if IsGlowing then
    Target := GlowOpacity
  else
    Target := 0;
  (FShadow as ICompositionObject).StopAnimation(WinStr('Opacity'));
  Fade := Compositor.CreateScalarKeyFrameAnimation;
  if IsGlowing and Pulse then
  begin
    Fade.InsertKeyFrame(0, Target);
    Fade.InsertKeyFrame(0.5, Target * 0.35);
    Fade.InsertKeyFrame(1, Target);
    (Fade as IKeyFrameAnimation).Duration := Ms(1800);
    (Fade as IKeyFrameAnimation).IterationBehavior := AnimationIterationBehavior.Forever;
  end
  else
  begin
    Fade.InsertKeyFrame(1, Target);
    (Fade as IKeyFrameAnimation).Duration := Ms(350);
  end;
  (FShadow as ICompositionObject).StartAnimation(WinStr('Opacity'), Fade as ICompositionAnimation);
end;

procedure TWinUIGlowTile.PropertyChanged(AIndex: Integer);
begin
  case AIndex of
    GGlowBrush:
      UpdateGlow(True);
    GIsGlowing, GFadeAfter:
      begin
        FFadeTimer.Enabled := False;
        if IsGlowing and (FadeAfter > 0) then
        begin
          FFadeTimer.Interval := Round(FadeAfter * 1000);
          FFadeTimer.Enabled := True;
        end;
        UpdateGlow(False);
      end;
    GGlowRadius, GGlowOpacity, GPulse:
      UpdateGlow(False);
  end;
end;

procedure TWinUIGlowTile.FadeElapsed(Sender: TObject);
begin
  FFadeTimer.Enabled := False;
  IsGlowing := False;
end;

{ TWinUIHotKey }

const
  HotKeyId = 1;
  MOD_NOREPEAT = $4000;

class procedure TWinUIHotKey.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Keys', TWinUIPropertyKind.Text);
  AType.AddProperty('IsActive', TWinUIPropertyKind.Boolean, 'True');
  AType.AddEvent('Pressed');
end;

procedure TWinUIHotKey.Initialize;
begin
  Visibility := TWinUIVisibility.Collapsed;
  // A hidden window of our own receives WM_HOTKEY. It lives on the UI thread,
  // so the app's message loop delivers it.
  FWindow := AllocateHWnd(WndProc);
end;

destructor TWinUIHotKey.Destroy;
begin
  Unregister;
  if FWindow <> 0 then
    DeallocateHWnd(FWindow);
  inherited;
end;

class function TWinUIHotKey.ParseKeys(const AKeys: string; out AModifiers, AKey: Cardinal): Boolean;
const
  Named: array[0..14] of record Name: string; Key: Cardinal; end = (
    (Name: 'SPACE'; Key: VK_SPACE), (Name: 'ENTER'; Key: VK_RETURN), (Name: 'ESC'; Key: VK_ESCAPE),
    (Name: 'TAB'; Key: VK_TAB), (Name: 'UP'; Key: VK_UP), (Name: 'DOWN'; Key: VK_DOWN),
    (Name: 'LEFT'; Key: VK_LEFT), (Name: 'RIGHT'; Key: VK_RIGHT), (Name: 'HOME'; Key: VK_HOME),
    (Name: 'END'; Key: VK_END), (Name: 'PGUP'; Key: VK_PRIOR), (Name: 'PGDN'; Key: VK_NEXT),
    (Name: 'INS'; Key: VK_INSERT), (Name: 'DEL'; Key: VK_DELETE), (Name: 'BACKSPACE'; Key: VK_BACK));
var
  Parts: TArray<string>;
  Part: string;
  I, F: Integer;
begin
  AModifiers := 0;
  AKey := 0;
  Parts := AKeys.ToUpper.Replace(' ', '').Split(['+']);
  for I := 0 to High(Parts) do
  begin
    Part := Parts[I];
    if I < High(Parts) then
    begin
      if (Part = 'CTRL') or (Part = 'CONTROL') then
        AModifiers := AModifiers or MOD_CONTROL
      else if Part = 'ALT' then
        AModifiers := AModifiers or MOD_ALT
      else if Part = 'SHIFT' then
        AModifiers := AModifiers or MOD_SHIFT
      else if (Part = 'WIN') or (Part = 'WINDOWS') then
        AModifiers := AModifiers or MOD_WIN
      else
        Exit(False);
    end
    else if (Length(Part) = 1) and CharInSet(Part[1], ['A'..'Z', '0'..'9']) then
      AKey := Ord(Part[1])
    else if (Length(Part) in [2, 3]) and (Part[1] = 'F') and TryStrToInt(Copy(Part, 2), F) and (F in [1..24]) then
      AKey := VK_F1 + Cardinal(F) - 1
    else
      for F := Low(Named) to High(Named) do
        if Named[F].Name = Part then
          AKey := Named[F].Key;
  end;
  Result := AKey <> 0;
end;

procedure TWinUIHotKey.Unregister;
begin
  if FRegistered then
    UnregisterHotKey(FWindow, HotKeyId);
  FRegistered := False;
end;

procedure TWinUIHotKey.UpdateRegistration;
var
  Modifiers, Key: Cardinal;
begin
  Unregister;
  if (FWindow = 0) or not IsActive or not ParseKeys(Keys, Modifiers, Key) then
    Exit;
  FRegistered := RegisterHotKey(FWindow, HotKeyId, Modifiers or MOD_NOREPEAT, Key);
end;

procedure TWinUIHotKey.PropertyChanged(AIndex: Integer);
begin
  UpdateRegistration;
end;

procedure TWinUIHotKey.WndProc(var AMessage: TMessage);
begin
  if (AMessage.Msg = WM_HOTKEY) and (AMessage.WParam = HotKeyId) then
    Fire(0)
  else
    AMessage.Result := DefWindowProc(FWindow, AMessage.Msg, AMessage.WParam, AMessage.LParam);
end;

{ TWinUIMediaSession }

type
  // Lets callbacks from other threads see whether the control still exists
  TAliveFlag = class(TInterfacedObject)
  public
    Alive: Boolean;
  end;

class procedure TWinUIMediaSession.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Title', TWinUIPropertyKind.Text);
  AType.AddProperty('Artist', TWinUIPropertyKind.Text);
  AType.AddProperty('AlbumTitle', TWinUIPropertyKind.Text);
  AType.AddProperty('SourceApp', TWinUIPropertyKind.Text);
  AType.AddProperty('IsPlaying', TWinUIPropertyKind.Boolean, 'False');
  AType.AddProperty('HasSession', TWinUIPropertyKind.Boolean, 'False');
  AType.AddEvent('Changed');
end;

procedure TWinUIMediaSession.Initialize;
var
  Flag: TAliveFlag;
  Op: IAsyncOperation_GlobalSystemMediaTransportControlsSessionManager;
  Me: TWinUIMediaSession;
begin
  Visibility := TWinUIVisibility.Collapsed;
  FQueue := (IntfOf(Self, IDependencyObject) as IDependencyObject).DispatcherQueue;
  Flag := TAliveFlag.Create;
  Flag.Alive := True;
  FAlive := Flag;
  FAliveRef := Flag;
  Me := Self;
  Op := GlobalSystemMediaTransportControlsSessionManager.RequestAsync;
  Op.Completed := TAsyncOperationCompletedHandler_GlobalSystemMediaTransportControlsSessionManager.Create(
    procedure(AAsyncInfo: IAsyncOperation_GlobalSystemMediaTransportControlsSessionManager; AAsyncStatus: AsyncStatus)
    var
      Manager: IGlobalSystemMediaTransportControlsSessionManager;
    begin
      if AAsyncStatus <> AsyncStatus.Completed then
        Exit;
      Manager := AAsyncInfo.GetResults;
      Me.Post(
        procedure
        begin
          Me.ManagerReady(Manager);
        end);
    end);
end;

procedure TWinUIMediaSession.DetachEvents;
begin
  if FAlive <> nil then
    TAliveFlag(FAlive).Alive := False;
  DetachSession;
  if (FManager <> nil) and (FSessionToken.Value <> 0) then
    FManager.remove_CurrentSessionChanged(FSessionToken);
  FSessionToken.Value := 0;
  FManager := nil;
  inherited;
end;

// Media callbacks come on other threads. Post runs AProc on the UI thread,
// unless the control is gone by then.
procedure TWinUIMediaSession.Post(const AProc: TProc);
var
  Flag: TAliveFlag;
  Ref: IInterface;
begin
  Flag := TAliveFlag(FAlive);
  Ref := FAliveRef;
  if (FQueue = nil) or (Flag = nil) then
    Exit;
  FQueue.TryEnqueue(TDispatcherQueueHandler.Create(
    procedure
    begin
      // Ref keeps the flag alive as long as this call is queued
      if (Ref <> nil) and Flag.Alive then
        AProc;
    end));
end;

procedure TWinUIMediaSession.ManagerReady(const AManager: IGlobalSystemMediaTransportControlsSessionManager);
var
  Me: TWinUIMediaSession;
begin
  FManager := AManager;
  if FManager = nil then
    Exit;
  Me := Self;
  FSessionToken := FManager.add_CurrentSessionChanged(
    TTypedEventHandler_GlobalSystemMediaTransportControlsSessionManager_CurrentSessionChangedEventArgs.Create(
    procedure(ASender: IGlobalSystemMediaTransportControlsSessionManager; AArgs: ICurrentSessionChangedEventArgs)
    begin
      Me.Post(Me.AttachSession);
    end));
  AttachSession;
end;

procedure TWinUIMediaSession.DetachSession;
begin
  if FSession <> nil then
  begin
    if FMediaToken.Value <> 0 then
      FSession.remove_MediaPropertiesChanged(FMediaToken);
    if FPlaybackToken.Value <> 0 then
      FSession.remove_PlaybackInfoChanged(FPlaybackToken);
  end;
  FMediaToken.Value := 0;
  FPlaybackToken.Value := 0;
  FSession := nil;
end;

procedure TWinUIMediaSession.AttachSession;
var
  Me: TWinUIMediaSession;
begin
  DetachSession;
  if FManager <> nil then
    FSession := FManager.GetCurrentSession;
  HasSession := FSession <> nil;
  if FSession = nil then
  begin
    Title := '';
    Artist := '';
    AlbumTitle := '';
    SourceApp := '';
    IsPlaying := False;
    Fire(0);
    Exit;
  end;
  SourceApp := TakeHString(FSession.SourceAppUserModelId);
  Me := Self;
  FMediaToken := FSession.add_MediaPropertiesChanged(
    TTypedEventHandler_GlobalSystemMediaTransportControlsSession_MediaPropertiesChangedEventArgs.Create(
    procedure(ASender: IGlobalSystemMediaTransportControlsSession; AArgs: IMediaPropertiesChangedEventArgs)
    begin
      Me.Post(Me.RefreshMedia);
    end));
  FPlaybackToken := FSession.add_PlaybackInfoChanged(
    TTypedEventHandler_GlobalSystemMediaTransportControlsSession_PlaybackInfoChangedEventArgs.Create(
    procedure(ASender: IGlobalSystemMediaTransportControlsSession; AArgs: IPlaybackInfoChangedEventArgs)
    begin
      Me.Post(Me.RefreshPlayback);
    end));
  RefreshPlayback;
  RefreshMedia;
end;

procedure TWinUIMediaSession.RefreshPlayback;
var
  Info: IGlobalSystemMediaTransportControlsSessionPlaybackInfo;
  Playing: Boolean;
begin
  if FSession = nil then
    Exit;
  Info := FSession.GetPlaybackInfo;
  Playing := (Info <> nil) and (Info.PlaybackStatus = GlobalSystemMediaTransportControlsSessionPlaybackStatus.Playing);
  if Playing <> IsPlaying then
  begin
    IsPlaying := Playing;
    Fire(0);
  end;
end;

procedure TWinUIMediaSession.RefreshMedia;
var
  Session: IGlobalSystemMediaTransportControlsSession;
  Op: IAsyncOperation_GlobalSystemMediaTransportControlsSessionMediaProperties;
  Me: TWinUIMediaSession;
begin
  Session := FSession;
  if Session = nil then
    Exit;
  Me := Self;
  Op := Session.TryGetMediaPropertiesAsync;
  Op.Completed := TAsyncOperationCompletedHandler_GlobalSystemMediaTransportControlsSessionMediaProperties.Create(
    procedure(AAsyncInfo: IAsyncOperation_GlobalSystemMediaTransportControlsSessionMediaProperties; AAsyncStatus: AsyncStatus)
    var
      Properties: IGlobalSystemMediaTransportControlsSessionMediaProperties;
    begin
      if AAsyncStatus <> AsyncStatus.Completed then
        Exit;
      Properties := AAsyncInfo.GetResults;
      Me.Post(
        procedure
        begin
          // A newer session may have taken over meanwhile
          if Me.Session = Session then
            Me.MediaReady(Properties);
        end);
    end);
end;

procedure TWinUIMediaSession.MediaReady(const AProperties: IGlobalSystemMediaTransportControlsSessionMediaProperties);
begin
  if AProperties = nil then
    Exit;
  Title := TakeHString(AProperties.Title);
  Artist := TakeHString(AProperties.Artist);
  AlbumTitle := TakeHString(AProperties.AlbumTitle);
  Fire(0);
end;

function TWinUIMediaSession.GetConnected: Boolean;
begin
  Result := FManager <> nil;
end;

procedure TWinUIMediaSession.Play;
begin
  if FSession <> nil then
    FSession.TryPlayAsync;
end;

procedure TWinUIMediaSession.Pause;
begin
  if FSession <> nil then
    FSession.TryPauseAsync;
end;

procedure TWinUIMediaSession.PlayPause;
begin
  if FSession <> nil then
    FSession.TryTogglePlayPauseAsync;
end;

procedure TWinUIMediaSession.Next;
begin
  if FSession <> nil then
    FSession.TrySkipNextAsync;
end;

procedure TWinUIMediaSession.Previous;
begin
  if FSession <> nil then
    FSession.TrySkipPreviousAsync;
end;

initialization
  TWinUICustomControls.Register(TWinUINotchPanel, 'NotchPanel', OverlayCategory);
  TWinUICustomControls.Register(TWinUIGlowTile, 'GlowTile', OverlayCategory);
  TWinUICustomControls.Register(TWinUIHotKey, 'HotKey', OverlayCategory);
  TWinUICustomControls.Register(TWinUIMediaSession, 'MediaSession', OverlayCategory);
end.
