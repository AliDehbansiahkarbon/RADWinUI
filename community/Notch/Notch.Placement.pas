unit Notch.Placement;

{ Where the notch window goes: against an edge of a display, at a place along
  that edge, and which edge a window dropped somewhere belongs to. Pixels are
  physical screen pixels, like the display areas Windows reports. }

interface

uses
  System.Types,
  Notch.Settings;

/// <summary>
///   The top-left corner of a window of ASize hanging from AEdge of a display,
///   its centre at AOffset (0..1) along the edge. AOuter is the display,
///   AWork its work area: the top edge is the screen's own, the others stay clear of the taskbar.
/// </summary>
function EdgePosition(AEdge: TNotchEdge; AOffset: Double; const AOuter, AWork: TRect; const ASize: TSize): TPoint;
/// <summary>The edge of AWork nearest to APoint, and where along that edge APoint is (0..1).</summary>
procedure NearestEdge(const APoint: TPoint; const AWork: TRect; out AEdge: TNotchEdge; out AOffset: Double);
/// <summary>
///   Where a dragged tile lands: AIndex moved by ADelta pixels in a row of
///   AWidths with AGap between them. The result is an index for TList.Move.
/// </summary>
function TileDropIndex(const AWidths: TArray<Integer>; AGap, AIndex: Integer; ADelta: Double): Integer;

implementation

uses
  System.Math;

function EdgePosition(AEdge: TNotchEdge; AOffset: Double; const AOuter, AWork: TRect; const ASize: TSize): TPoint;
begin
  case AEdge of
    TNotchEdge.Top, TNotchEdge.Bottom:
      begin
        Result.X := AWork.Left + Round(AOffset * AWork.Width) - ASize.cx div 2;
        Result.X := EnsureRange(Result.X, AWork.Left, Max(AWork.Left, AWork.Right - ASize.cx));
        if AEdge = TNotchEdge.Top then
          Result.Y := AOuter.Top
        else
          Result.Y := AWork.Bottom - ASize.cy;
      end;
  else
    begin
      Result.Y := AWork.Top + Round(AOffset * AWork.Height) - ASize.cy div 2;
      Result.Y := EnsureRange(Result.Y, AWork.Top, Max(AWork.Top, AWork.Bottom - ASize.cy));
      if AEdge = TNotchEdge.Left then
        Result.X := AWork.Left
      else
        Result.X := AWork.Right - ASize.cx;
    end;
  end;
end;

procedure NearestEdge(const APoint: TPoint; const AWork: TRect; out AEdge: TNotchEdge; out AOffset: Double);
var
  Distances: array[TNotchEdge] of Integer;
  Edge: TNotchEdge;
begin
  Distances[TNotchEdge.Top] := Abs(APoint.Y - AWork.Top);
  Distances[TNotchEdge.Bottom] := Abs(AWork.Bottom - APoint.Y);
  Distances[TNotchEdge.Left] := Abs(APoint.X - AWork.Left);
  Distances[TNotchEdge.Right] := Abs(AWork.Right - APoint.X);
  AEdge := TNotchEdge.Top;
  for Edge := Low(TNotchEdge) to High(TNotchEdge) do
    if Distances[Edge] < Distances[AEdge] then
      AEdge := Edge;
  if AEdge in [TNotchEdge.Top, TNotchEdge.Bottom] then
    AOffset := (APoint.X - AWork.Left) / Max(1, AWork.Width)
  else
    AOffset := (APoint.Y - AWork.Top) / Max(1, AWork.Height);
  AOffset := EnsureRange(AOffset, 0.0, 1.0);
end;

function TileDropIndex(const AWidths: TArray<Integer>; AGap, AIndex: Integer; ADelta: Double): Integer;
var
  Left, I: Integer;
  Lefts: TArray<Integer>;
  Center: Double;
begin
  SetLength(Lefts, Length(AWidths));
  Left := 0;
  for I := 0 to High(AWidths) do
  begin
    Lefts[I] := Left;
    Inc(Left, AWidths[I] + AGap);
  end;
  Center := Lefts[AIndex] + AWidths[AIndex] / 2 + ADelta;
  // As many tiles go before it as have their centre left of the dragged one's
  Result := 0;
  for I := 0 to High(AWidths) do
    if (I <> AIndex) and (Lefts[I] + AWidths[I] / 2 < Center) then
      Inc(Result);
end;

end.
