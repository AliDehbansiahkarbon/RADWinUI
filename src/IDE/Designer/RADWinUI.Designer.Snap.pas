unit RADWinUI.Designer.Snap;

{
  Alignment guides of the designer, like the VCL form designer's blue lines:
  where an element being moved lines up with a sibling or its parent. Plain
  geometry in DIPs, no WinUI: the preview host measures the elements and
  draws the lines, tests\Designer\XamlEditTest checks the math.
}

interface

type
  TSnapRect = record
    Left, Top, Width, Height: Double;
    class function Create(ALeft, ATop, AWidth, AHeight: Double): TSnapRect; static;
  end;

  /// <summary>One guide line: AMoving lines up after a move by Delta along the axis.</summary>
  TSnapGuide = record
    Found: Boolean;
    /// <summary>The move that lines the edges up, along the axis.</summary>
    Delta: Double;
    /// <summary>Where the line is: an x for a vertical line, a y for a horizontal one.</summary>
    At: Double;
    /// <summary>The line's ends across the axis, over both elements.</summary>
    First, Last: Double;
  end;

const
  /// <summary>How close edges must be to show a guide and snap, in DIPs.</summary>
  SnapDistance = 4;

/// <summary>
///   The closest guide for AMoving among AOthers within ADistance: AVertical
///   compares left edges, centres and right edges (a vertical line), else
///   top edges, middles and bottom edges. Edges meet edges, centres meet centres.
/// </summary>
function SnapAxis(const AMoving: TSnapRect; const AOthers: TArray<TSnapRect>; AVertical: Boolean;
  ADistance: Double = SnapDistance): TSnapGuide;

implementation

uses
  System.Math;

class function TSnapRect.Create(ALeft, ATop, AWidth, AHeight: Double): TSnapRect;
begin
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := AWidth;
  Result.Height := AHeight;
end;

/// Start, centre and end of ARect along the axis.
procedure Lines(const ARect: TSnapRect; AVertical: Boolean; out AStart, ACentre, AEnd: Double);
begin
  if AVertical then
  begin
    AStart := ARect.Left;
    AEnd := ARect.Left + ARect.Width;
  end
  else
  begin
    AStart := ARect.Top;
    AEnd := ARect.Top + ARect.Height;
  end;
  ACentre := (AStart + AEnd) / 2;
end;

function SnapAxis(const AMoving: TSnapRect; const AOthers: TArray<TSnapRect>; AVertical: Boolean;
  ADistance: Double): TSnapGuide;
var
  Other: TSnapRect;
  Mine, Theirs: array[0..2] of Double;
  I, J: Integer;
  Delta: Double;
begin
  Result := Default(TSnapGuide);
  Lines(AMoving, AVertical, Mine[0], Mine[1], Mine[2]);
  for Other in AOthers do
  begin
    Lines(Other, AVertical, Theirs[0], Theirs[1], Theirs[2]);
    for I := 0 to 2 do
      for J := 0 to 2 do
      begin
        if (I = 1) <> (J = 1) then
          Continue;
        Delta := Theirs[J] - Mine[I];
        if (Abs(Delta) > ADistance) or (Result.Found and (Abs(Delta) >= Abs(Result.Delta))) then
          Continue;
        Result.Found := True;
        Result.Delta := Delta;
        Result.At := Theirs[J];
        if AVertical then
        begin
          Result.First := Min(AMoving.Top, Other.Top);
          Result.Last := Max(AMoving.Top + AMoving.Height, Other.Top + Other.Height);
        end
        else
        begin
          Result.First := Min(AMoving.Left, Other.Left);
          Result.Last := Max(AMoving.Left + AMoving.Width, Other.Left + Other.Width);
        end;
      end;
  end;
end;

end.
