unit RADWinUI.Motion;

{
  GPU animations for XAML elements, through the Composition visual behind each
  element (ElementCompositionPreview). They run on the compositor thread, so
  they stay smooth while the UI thread works, and cost no timer.

    TWinUIMotion.Enter(Card, 120);           // fade in and slide up after 120 ms
    TWinUIMotion.Drift(Bubble, 0, -40, 9000); // float up and down forever
    TWinUIMotion.Reveal(Chart, 200, 900);    // draw in from left to right

  Elements keep their XAML layout: the animations use the visual's Opacity,
  Translation, Scale, RotationAngleInDegrees and Clip, never its Offset.
}

interface

uses
  RADWinUI.Abi,
  RADWinUI.Framework;

type
  TWinUIMotion = record
  public
    /// <summary>Fades AElement in while it slides up from AFromY pixels below.</summary>
    class procedure Enter(AElement: TWinUIObject; ADelay: Integer = 0; ADuration: Integer = 450;
      AFromY: Single = 18); static;
    /// <summary>Fades AElement out while it slides by AToY pixels.</summary>
    class procedure Leave(AElement: TWinUIObject; ADuration: Integer = 160; AToY: Single = -10); static;
    /// <summary>Stops every motion animation and shows AElement at rest.</summary>
    class procedure Reset(AElement: TWinUIObject); static;
    /// <summary>Hides AElement at once (opacity 0), for elements that enter later.</summary>
    class procedure Hide(AElement: TWinUIObject); static;
    /// <summary>Moves AElement by (ADX, ADY) and back, forever, starting after ADelay.</summary>
    class procedure Drift(AElement: TWinUIObject; ADX, ADY: Single; ADuration: Integer;
      ADelay: Integer = 0); static;
    /// <summary>Turns AElement by ADegrees and back, forever, around its centre.</summary>
    class procedure Sway(AElement: TWinUIObject; ADegrees: Single; ADuration: Integer); static;
    /// <summary>Draws AElement in from left to right with an inset clip.</summary>
    class procedure Reveal(AElement: TWinUIObject; ADelay: Integer = 0; ADuration: Integer = 900); static;
    /// <summary>Grows AElement from nothing, from its left edge or from its bottom edge.</summary>
    class procedure Grow(AElement: TWinUIObject; AVertical: Boolean; ADelay: Integer = 0;
      ADuration: Integer = 600); static;
    /// <summary>Sweeps AElement in: a turn of ADegrees with a fade and a slight zoom.</summary>
    class procedure Sweep(AElement: TWinUIObject; ADegrees: Single = -120; ADelay: Integer = 0;
      ADuration: Integer = 800); static;
    /// <summary>Slides AElement to the translation (AX, AY).</summary>
    class procedure SlideTo(AElement: TWinUIObject; AX, AY: Single; ADuration: Integer = 380); static;
    /// <summary>
    ///   Hero move: AElement starts at offset (ADX, ADY) from its place, scaled by
    ///   (AScaleX, AScaleY) from its top-left corner, and flies to its own place and size.
    /// </summary>
    class procedure Hero(AElement: TWinUIObject; ADX, ADY, AScaleX, AScaleY: Single;
      ADuration: Integer = 480); static;
    /// <summary>Lifts AElement slightly (pointer over) or puts it back.</summary>
    class procedure Lift(AElement: TWinUIObject; AUp: Boolean); static;
    /// <summary>A short pop: scales AElement up and back once.</summary>
    class procedure Pulse(AElement: TWinUIObject; AScale: Single = 1.35); static;
  end;

implementation

uses
  RADWinUI.Interop.Core;

var
  // One easing per process: every window of a WinUI app shares the same compositor.
  EaseOut: ICompositionEasingFunction;
  EaseInOut: ICompositionEasingFunction;
  EaseCompositor: Pointer;

function ElementOf(AElement: TWinUIObject): IUIElement;
begin
  Result := TWinUIObject.IntfOf(AElement, IUIElement) as IUIElement;
end;

function VisualOf(AElement: TWinUIObject): IVisual;
var
  Element: IUIElement;
begin
  Element := ElementOf(AElement);
  ElementCompositionPreview.SetIsTranslationEnabled(Element, True);
  Result := ElementCompositionPreview.GetElementVisual(Element);
end;

procedure ElementSize(AElement: TWinUIObject; out AWidth, AHeight: Single);
var
  Element: IFrameworkElement;
begin
  Element := TWinUIObject.IntfOf(AElement, IFrameworkElement) as IFrameworkElement;
  AWidth := Element.ActualWidth;
  AHeight := Element.ActualHeight;
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

function Vec3(AX, AY, AZ: Single): Vector3;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
end;

function Compositor(const AVisual: IVisual): ICompositor;
begin
  Result := (AVisual as ICompositionObject).Compositor;
  if Pointer(Result) <> EaseCompositor then
  begin
    EaseOut := Result.CreateCubicBezierEasingFunction(Vec2(0.1, 0.9), Vec2(0.2, 1)) as ICompositionEasingFunction;
    EaseInOut := Result.CreateCubicBezierEasingFunction(Vec2(0.45, 0), Vec2(0.55, 1)) as ICompositionEasingFunction;
    EaseCompositor := Pointer(Result);
  end;
end;

procedure Timing(const AAnimation: IInspectable; ADelay, ADuration: Integer);
var
  Frames: IKeyFrameAnimation;
begin
  Frames := AAnimation as IKeyFrameAnimation;
  Frames.Duration := Ms(ADuration);
  if ADelay > 0 then
  begin
    Frames.DelayTime := Ms(ADelay);
    (AAnimation as IKeyFrameAnimation3).DelayBehavior := AnimationDelayBehavior.SetInitialValueBeforeDelay;
  end;
end;

procedure Scalar(const AVisual: IVisual; const AProperty: string; AFrom, ATo: Single;
  ADelay, ADuration: Integer; AForever: Boolean = False);
var
  Animation: IScalarKeyFrameAnimation;
  Ease: ICompositionEasingFunction;
begin
  Animation := Compositor(AVisual).CreateScalarKeyFrameAnimation;
  if AForever then
    Ease := EaseInOut
  else
    Ease := EaseOut;
  Animation.InsertKeyFrame(0, AFrom);
  Animation.InsertKeyFrameWithEasingFunction(1, ATo, Ease);
  Timing(Animation, ADelay, ADuration);
  if AForever then
  begin
    (Animation as IKeyFrameAnimation).IterationBehavior := AnimationIterationBehavior.Forever;
    (Animation as IKeyFrameAnimation2).Direction := Microsoft_UI_Composition_AnimationDirection.Alternate;
  end;
  (AVisual as ICompositionObject).StartAnimation(WinStr(AProperty), Animation as ICompositionAnimation);
end;

{ TWinUIMotion }

class procedure TWinUIMotion.Enter(AElement: TWinUIObject; ADelay, ADuration: Integer; AFromY: Single);
var
  Visual: IVisual;
begin
  Visual := VisualOf(AElement);
  Scalar(Visual, 'Opacity', 0, 1, ADelay, ADuration);
  Scalar(Visual, 'Translation.Y', AFromY, 0, ADelay, ADuration);
end;

class procedure TWinUIMotion.Leave(AElement: TWinUIObject; ADuration: Integer; AToY: Single);
var
  Visual: IVisual;
begin
  Visual := VisualOf(AElement);
  Scalar(Visual, 'Opacity', Visual.Opacity, 0, 0, ADuration);
  Scalar(Visual, 'Translation.Y', 0, AToY, 0, ADuration);
end;

class procedure TWinUIMotion.Reset(AElement: TWinUIObject);
var
  Visual: IVisual;
  Obj: ICompositionObject;
  Name: string;
begin
  Visual := VisualOf(AElement);
  Obj := Visual as ICompositionObject;
  for Name in ['Opacity', 'Translation', 'Scale', 'RotationAngleInDegrees'] do
    Obj.StopAnimation(WinStr(Name));
  Visual.Opacity := 1;
  Visual.Scale := Vec3(1, 1, 1);
  Visual.RotationAngleInDegrees := 0;
  Visual.Clip := nil;
  (Visual as ICompositionObject).Properties.InsertVector3(WinStr('Translation'), Vec3(0, 0, 0));
end;

class procedure TWinUIMotion.Hide(AElement: TWinUIObject);
begin
  VisualOf(AElement).Opacity := 0;
end;

class procedure TWinUIMotion.Drift(AElement: TWinUIObject; ADX, ADY: Single; ADuration, ADelay: Integer);
var
  Visual: IVisual;
begin
  Visual := VisualOf(AElement);
  if ADX <> 0 then
    Scalar(Visual, 'Translation.X', 0, ADX, ADelay, ADuration, True);
  if ADY <> 0 then
    Scalar(Visual, 'Translation.Y', 0, ADY, ADelay, ADuration, True);
end;

class procedure TWinUIMotion.Sway(AElement: TWinUIObject; ADegrees: Single; ADuration: Integer);
var
  Visual: IVisual;
  W, H: Single;
begin
  Visual := VisualOf(AElement);
  ElementSize(AElement, W, H);
  Visual.CenterPoint := Vec3(W / 2, H / 2, 0);
  Scalar(Visual, 'RotationAngleInDegrees', 0, ADegrees, 0, ADuration, True);
end;

class procedure TWinUIMotion.Reveal(AElement: TWinUIObject; ADelay, ADuration: Integer);
var
  Visual: IVisual;
  Clip: IInsetClip;
  Animation: IScalarKeyFrameAnimation;
  W, H: Single;
begin
  Visual := VisualOf(AElement);
  ElementSize(AElement, W, H);
  Clip := Compositor(Visual).CreateInsetClipWithInsets(0, -40, W, -40);
  Visual.Clip := Clip as ICompositionClip;
  Animation := Compositor(Visual).CreateScalarKeyFrameAnimation;
  Animation.InsertKeyFrame(0, W);
  Animation.InsertKeyFrameWithEasingFunction(1, 0, EaseInOut);
  Timing(Animation, ADelay, ADuration);
  (Clip as ICompositionObject).StartAnimation(WinStr('RightInset'), Animation as ICompositionAnimation);
end;

class procedure TWinUIMotion.Grow(AElement: TWinUIObject; AVertical: Boolean; ADelay, ADuration: Integer);
var
  Visual: IVisual;
  W, H: Single;
begin
  Visual := VisualOf(AElement);
  ElementSize(AElement, W, H);
  if AVertical then
  begin
    Visual.CenterPoint := Vec3(W / 2, H, 0);
    Scalar(Visual, 'Scale.Y', 0, 1, ADelay, ADuration);
  end
  else
  begin
    Visual.CenterPoint := Vec3(0, H / 2, 0);
    Scalar(Visual, 'Scale.X', 0, 1, ADelay, ADuration);
  end;
end;

class procedure TWinUIMotion.Sweep(AElement: TWinUIObject; ADegrees: Single; ADelay, ADuration: Integer);
var
  Visual: IVisual;
  W, H: Single;
begin
  Visual := VisualOf(AElement);
  ElementSize(AElement, W, H);
  Visual.CenterPoint := Vec3(W / 2, H / 2, 0);
  Scalar(Visual, 'RotationAngleInDegrees', ADegrees, 0, ADelay, ADuration);
  Scalar(Visual, 'Opacity', 0, 1, ADelay, ADuration div 2);
  Scalar(Visual, 'Scale.X', 0.85, 1, ADelay, ADuration);
  Scalar(Visual, 'Scale.Y', 0.85, 1, ADelay, ADuration);
end;

class procedure TWinUIMotion.SlideTo(AElement: TWinUIObject; AX, AY: Single; ADuration: Integer);
var
  Visual: IVisual;
  Animation: IVector3KeyFrameAnimation;
begin
  Visual := VisualOf(AElement);
  Animation := Compositor(Visual).CreateVector3KeyFrameAnimation;
  (Animation as IKeyFrameAnimation).InsertExpressionKeyFrame(0, WinStr('this.StartingValue'));
  Animation.InsertKeyFrameWithEasingFunction(1, Vec3(AX, AY, 0), EaseOut);
  Timing(Animation, 0, ADuration);
  (Visual as ICompositionObject).StartAnimation(WinStr('Translation'), Animation as ICompositionAnimation);
end;

class procedure TWinUIMotion.Hero(AElement: TWinUIObject; ADX, ADY, AScaleX, AScaleY: Single; ADuration: Integer);
var
  Visual: IVisual;
begin
  Visual := VisualOf(AElement);
  Visual.CenterPoint := Vec3(0, 0, 0);
  Scalar(Visual, 'Translation.X', ADX, 0, 0, ADuration);
  Scalar(Visual, 'Translation.Y', ADY, 0, 0, ADuration);
  Scalar(Visual, 'Scale.X', AScaleX, 1, 0, ADuration);
  Scalar(Visual, 'Scale.Y', AScaleY, 1, 0, ADuration);
  Scalar(Visual, 'Opacity', 0.4, 1, 0, ADuration div 2);
end;

class procedure TWinUIMotion.Lift(AElement: TWinUIObject; AUp: Boolean);
var
  Visual: IVisual;
  W, H: Single;
begin
  Visual := VisualOf(AElement);
  ElementSize(AElement, W, H);
  Visual.CenterPoint := Vec3(W / 2, H / 2, 0);
  if AUp then
  begin
    Scalar(Visual, 'Translation.Y', 0, -4, 0, 220);
    Scalar(Visual, 'Scale.X', 1, 1.012, 0, 220);
    Scalar(Visual, 'Scale.Y', 1, 1.012, 0, 220);
  end
  else
  begin
    Scalar(Visual, 'Translation.Y', -4, 0, 0, 260);
    Scalar(Visual, 'Scale.X', 1.012, 1, 0, 260);
    Scalar(Visual, 'Scale.Y', 1.012, 1, 0, 260);
  end;
end;

class procedure TWinUIMotion.Pulse(AElement: TWinUIObject; AScale: Single);
var
  Visual: IVisual;
  Animation: IScalarKeyFrameAnimation;
  W, H: Single;
  Name: string;
begin
  Visual := VisualOf(AElement);
  ElementSize(AElement, W, H);
  Visual.CenterPoint := Vec3(W / 2, H / 2, 0);
  for Name in ['Scale.X', 'Scale.Y'] do
  begin
    Animation := Compositor(Visual).CreateScalarKeyFrameAnimation;
    Animation.InsertKeyFrame(0, 1);
    Animation.InsertKeyFrameWithEasingFunction(0.35, AScale, EaseOut);
    Animation.InsertKeyFrameWithEasingFunction(1, 1, EaseInOut);
    Timing(Animation, 0, 520);
    (Visual as ICompositionObject).StartAnimation(WinStr(Name), Animation as ICompositionAnimation);
  end;
end;

end.
