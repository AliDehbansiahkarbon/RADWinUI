unit RADWinUI.Designer.PaletteIcons;

{ Small original control pictograms. Render once into the IDE's image collection,
  no WinUI, external font, asset files or image library is needed. }

interface

uses Vcl.Graphics, Vcl.ImageCollection;

function PaletteIcon(ACollection: TImageCollection; const AName: string): Integer;
/// <summary>
///   The icon of AName at ASize pixels: 32-bit premultiplied alpha, cached, owned by this
///   unit. Palette items paint it themselves (INTAPalettePaintIcon).
/// </summary>
function PaletteBitmap(const AName: string; ASize: Integer): TBitmap;
/// <summary>Draws AName's icon at X, Y with alpha, half transparent when not AEnabled.</summary>
procedure DrawPaletteIcon(ACanvas: TCanvas; X, Y, ASize: Integer; const AName: string; AEnabled: Boolean);

implementation

uses
  Winapi.Windows, System.SysUtils, System.StrUtils, System.Types, System.Generics.Collections;

type
  TBitmap = Vcl.Graphics.TBitmap; // not Winapi.Windows.TBitmap

/// The tab bars: a rounded bar with three tabs, and what marks the selected one in each style
procedure DrawTabBar(ACanvas: TCanvas; const AName: string);

  procedure Solid(AShade: Integer);
  begin
    // Lighter shades become more transparent (see RenderIcon)
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := RGB(AShade, 122 + (AShade - 32) * 133 div 223, 216 + (AShade - 32) * 39 div 223);
  end;

  procedure Tab(X: Integer);
  begin
    Solid(32);
    ACanvas.Pen.Width := 1;
    ACanvas.Ellipse(X - 5, 47, X + 5, 57);
  end;

begin
  ACanvas.Pen.Width := 5;
  ACanvas.Pen.Color := RGB(32, 122, 216);
  if AName = 'liquidbulgetabbar' then
  begin
    // The whole bar is the accent, with a bump over the selected tab
    Solid(120);
    ACanvas.Pen.Style := psClear;
    ACanvas.RoundRect(6, 36, 90, 72, 30, 30);
    ACanvas.Ellipse(50, 22, 82, 54);
    ACanvas.Pen.Style := psSolid;
    Tab(22); Tab(44);
    Solid(32);
    ACanvas.Ellipse(61, 31, 71, 41);
    Exit;
  end;
  Solid(215);
  ACanvas.RoundRect(6, 36, 90, 70, 30, 30);
  if AName = 'slidingpilltabbar' then
  begin
    Tab(22); Tab(44);
    Solid(32);
    ACanvas.RoundRect(56, 42, 84, 62, 20, 20);
  end
  else if AName = 'floatingnotchtabbar' then
  begin
    Tab(22); Tab(44);
    Solid(32);
    ACanvas.Pen.Width := 1;
    ACanvas.Ellipse(56, 14, 80, 38);
  end
  else if AName = 'iconfilltabbar' then
  begin
    Tab(22); Tab(44);
    Solid(32);
    ACanvas.Pen.Width := 1;
    ACanvas.Ellipse(62, 43, 76, 57);
    ACanvas.RoundRect(61, 60, 77, 64, 4, 4);
  end
  else if AName = 'expandinglabeltabbar' then
  begin
    Solid(150);
    ACanvas.RoundRect(14, 42, 58, 64, 22, 22);
    Tab(25); Tab(70);
    ACanvas.Pen.Width := 4;
    ACanvas.MoveTo(34, 53); ACanvas.LineTo(50, 53);
  end
  else
  begin
    // Bubble Float: bubbles rise from the selected tab
    Tab(22); Tab(44);
    Solid(32);
    ACanvas.Pen.Width := 1;
    ACanvas.Ellipse(63, 45, 75, 57);
    ACanvas.Brush.Style := bsClear;
    ACanvas.Pen.Width := 3;
    ACanvas.Ellipse(60, 18, 72, 30);
    ACanvas.Ellipse(72, 8, 80, 16);
    ACanvas.Ellipse(56, 4, 62, 10);
  end;
end;

/// The action buttons: what each one shows in the moment it does its thing
procedure DrawActionButton(ACanvas: TCanvas; const AName: string);

  procedure Solid(AShade: Integer);
  begin
    // Lighter shades become more transparent (see RenderIcon)
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := RGB(AShade, 122 + (AShade - 32) * 133 div 223, 216 + (AShade - 32) * 39 div 223);
  end;

begin
  ACanvas.Pen.Color := RGB(32, 122, 216);
  if AName = 'holdbutton' then
  begin
    // A ring three quarters full around a round button
    Solid(215);
    ACanvas.Pen.Style := psClear;
    ACanvas.Ellipse(20, 20, 77, 77);
    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Width := 8;
    ACanvas.Brush.Style := bsClear;
    ACanvas.Arc(8, 8, 88, 88, 48, 8, 8, 48);
    Solid(32);
    ACanvas.Pen.Width := 1;
    ACanvas.RoundRect(38, 36, 58, 62, 6, 6);
  end
  else if AName = 'sendbutton' then
  begin
    // A pill and the paper plane leaving it
    Solid(215);
    ACanvas.Pen.Style := psClear;
    ACanvas.RoundRect(4, 40, 76, 76, 36, 36);
    Solid(32);
    ACanvas.Polygon([Point(50, 30), Point(92, 12), Point(74, 50), Point(66, 36)]);
    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Width := 4;
    ACanvas.MoveTo(16, 58); ACanvas.LineTo(44, 58);
  end
  else if AName = 'confettibutton' then
  begin
    // A pill with confetti bursting out of its top
    Solid(215);
    ACanvas.Pen.Style := psClear;
    ACanvas.RoundRect(6, 52, 90, 86, 34, 34);
    Solid(32);
    ACanvas.Rectangle(14, 30, 22, 42);
    ACanvas.Ellipse(34, 8, 44, 18);
    ACanvas.Rectangle(52, 22, 64, 30);
    ACanvas.Ellipse(74, 28, 84, 38);
    ACanvas.Rectangle(80, 6, 88, 18);
    ACanvas.Ellipse(8, 8, 16, 16);
    ACanvas.Pen.Style := psSolid;
  end
  else if AName = 'copybutton' then
  begin
    // A field with text and the copy square, now a check
    Solid(215);
    ACanvas.Pen.Style := psClear;
    ACanvas.RoundRect(2, 26, 94, 70, 18, 18);
    Solid(32);
    ACanvas.RoundRect(56, 32, 88, 64, 12, 12);
    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Width := 5;
    ACanvas.MoveTo(12, 48); ACanvas.LineTo(44, 48);
    ACanvas.Pen.Color := clWhite;
    ACanvas.MoveTo(63, 48); ACanvas.LineTo(70, 55); ACanvas.LineTo(81, 41);
  end
  else if AName = 'shinebutton' then
  begin
    // A pill with a diagonal shine and a sparkle beside it
    Solid(120);
    ACanvas.Pen.Style := psClear;
    ACanvas.RoundRect(4, 34, 92, 72, 38, 38);
    ACanvas.Brush.Color := clWhite;
    ACanvas.Polygon([Point(40, 72), Point(54, 34), Point(64, 34), Point(50, 72)]);
    Solid(32);
    ACanvas.Polygon([Point(80, 2), Point(84, 14), Point(96, 18), Point(84, 22), Point(80, 34), Point(76, 22),
      Point(64, 18), Point(76, 14)]);
    ACanvas.Pen.Style := psSolid;
  end
  else
  begin
    // Slide: a track filled behind the knob
    Solid(215);
    ACanvas.Pen.Style := psClear;
    ACanvas.RoundRect(2, 30, 94, 66, 36, 36);
    Solid(120);
    ACanvas.RoundRect(2, 30, 70, 66, 36, 36);
    Solid(32);
    ACanvas.Ellipse(40, 32, 72, 64);
    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Width := 4;
    ACanvas.Pen.Color := clWhite;
    ACanvas.MoveTo(50, 41); ACanvas.LineTo(57, 48); ACanvas.LineTo(50, 55);
    ACanvas.MoveTo(58, 41); ACanvas.LineTo(65, 48); ACanvas.LineTo(58, 55);
  end;
end;

function IsActionButton(const AName: string): Boolean;
begin
  Result := (AName = 'holdbutton') or (AName = 'sendbutton') or (AName = 'confettibutton') or
    (AName = 'copybutton') or (AName = 'shinebutton') or (AName = 'slidebutton');
end;

/// The data controls: the control drawn small at the top left, and a database
/// cylinder at the bottom right, like VCL's Data Controls icons
procedure DrawDataControl(ACanvas: TCanvas; const AName: string);
var
  Name: string;
  I: Integer;
begin
  Name := Copy(AName, 3, MaxInt);
  ACanvas.Pen.Color := RGB(32, 122, 216);
  ACanvas.Pen.Width := 6;
  ACanvas.Brush.Style := bsClear;
  if (Name = 'grid') then
  begin
    ACanvas.Rectangle(4, 6, 66, 58);
    ACanvas.MoveTo(4, 22); ACanvas.LineTo(66, 22);
    ACanvas.MoveTo(4, 40); ACanvas.LineTo(66, 40);
    ACanvas.MoveTo(28, 6); ACanvas.LineTo(28, 58);
  end
  else if Name = 'ctrlgrid' then
  begin
    ACanvas.RoundRect(4, 6, 32, 30, 8, 8); ACanvas.RoundRect(38, 6, 66, 30, 8, 8);
    ACanvas.RoundRect(4, 36, 32, 60, 8, 8); ACanvas.RoundRect(38, 36, 66, 60, 8, 8);
  end
  else if Name = 'navigator' then
  begin
    // |<  >|
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := RGB(32, 122, 216);
    ACanvas.Pen.Width := 1;
    ACanvas.Rectangle(4, 14, 10, 50);
    ACanvas.Polygon([Point(12, 32), Point(34, 14), Point(34, 50)]);
    ACanvas.Polygon([Point(64, 32), Point(42, 14), Point(42, 50)]);
    ACanvas.Rectangle(66, 14, 72, 50);
  end
  else if Name = 'text' then
  begin
    for I := 0 to 2 do
    begin
      ACanvas.MoveTo(6, 14 + I * 16); ACanvas.LineTo(62 - I * 14, 14 + I * 16);
    end;
  end
  else if (Name = 'edit') or (Name = 'numberbox') then
  begin
    ACanvas.Rectangle(4, 18, 70, 46);
    ACanvas.MoveTo(16, 24); ACanvas.LineTo(16, 40);
    if Name = 'numberbox' then
    begin
      ACanvas.Pen.Width := 4;
      ACanvas.MoveTo(50, 30); ACanvas.LineTo(56, 24); ACanvas.LineTo(62, 30);
      ACanvas.MoveTo(50, 36); ACanvas.LineTo(56, 42); ACanvas.LineTo(62, 36);
    end;
  end
  else if (Name = 'memo') or (Name = 'richedit') then
  begin
    ACanvas.Rectangle(4, 4, 66, 60);
    if Name = 'richedit' then
      ACanvas.Pen.Width := 9;
    ACanvas.MoveTo(14, 18); ACanvas.LineTo(54, 18);
    ACanvas.Pen.Width := 4;
    ACanvas.MoveTo(14, 32); ACanvas.LineTo(54, 32);
    ACanvas.MoveTo(14, 46); ACanvas.LineTo(40, 46);
  end
  else if Name = 'image' then
  begin
    ACanvas.Rectangle(4, 6, 66, 58);
    ACanvas.Pen.Width := 5;
    ACanvas.MoveTo(10, 50); ACanvas.LineTo(28, 30); ACanvas.LineTo(40, 42); ACanvas.LineTo(48, 34);
    ACanvas.LineTo(60, 50);
    ACanvas.Ellipse(44, 14, 56, 26);
  end
  else if (Name = 'listbox') or (Name = 'lookuplistbox') then
  begin
    ACanvas.Rectangle(4, 4, 66, 60);
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := RGB(32, 122, 216);
    ACanvas.Rectangle(10, 24, 60, 36);
    ACanvas.Brush.Style := bsClear;
    ACanvas.Pen.Width := 4;
    ACanvas.MoveTo(14, 14); ACanvas.LineTo(50, 14);
    ACanvas.MoveTo(14, 48); ACanvas.LineTo(44, 48);
  end
  else if (Name = 'combobox') or (Name = 'lookupcombobox') then
  begin
    ACanvas.Rectangle(4, 18, 70, 46);
    ACanvas.MoveTo(46, 28); ACanvas.LineTo(54, 36); ACanvas.LineTo(62, 28);
  end
  else if Name = 'checkbox' then
  begin
    ACanvas.Rectangle(8, 10, 54, 56);
    ACanvas.Pen.Width := 8;
    ACanvas.MoveTo(16, 34); ACanvas.LineTo(28, 46); ACanvas.LineTo(46, 20);
  end
  else if Name = 'radiogroup' then
  begin
    ACanvas.Ellipse(6, 6, 30, 30); ACanvas.Ellipse(6, 36, 30, 60);
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := RGB(32, 122, 216);
    ACanvas.Ellipse(13, 13, 23, 23);
    ACanvas.Pen.Width := 4;
    ACanvas.MoveTo(38, 18); ACanvas.LineTo(66, 18);
    ACanvas.MoveTo(38, 48); ACanvas.LineTo(66, 48);
  end
  else if Name = 'datepicker' then
  begin
    ACanvas.Rectangle(6, 10, 66, 60);
    ACanvas.MoveTo(6, 26); ACanvas.LineTo(66, 26);
    ACanvas.MoveTo(20, 4); ACanvas.LineTo(20, 16);
    ACanvas.MoveTo(52, 4); ACanvas.LineTo(52, 16);
  end
  else if Name = 'toggleswitch' then
  begin
    ACanvas.RoundRect(4, 16, 70, 48, 32, 32);
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := RGB(32, 122, 216);
    ACanvas.Ellipse(42, 22, 62, 42);
  end;
  // The database
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Color := RGB(32, 122, 216);
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := clWhite;
  ACanvas.Rectangle(56, 54, 96, 96);
  ACanvas.Brush.Color := RGB(32, 122, 216);
  ACanvas.Ellipse(60, 80, 94, 94);
  ACanvas.Rectangle(60, 64, 94, 87);
  ACanvas.Pen.Color := clWhite;
  ACanvas.Pen.Width := 3;
  ACanvas.Ellipse(60, 56, 94, 72);
  ACanvas.Brush.Style := bsClear;
  ACanvas.Arc(60, 66, 94, 80, 60, 73, 94, 73);
  ACanvas.Pen.Width := 6;
  ACanvas.Pen.Color := RGB(32, 122, 216);
end;

/// The text fields, swipe actions, pagers and progress steps: the moment each one is known for
function DrawAdvancedControl(ACanvas: TCanvas; const AName: string): Boolean;
var
  I: Integer;

  procedure Solid(AShade: Integer);
  begin
    // Lighter shades become more transparent (see RenderIcon)
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := RGB(AShade, 122 + (AShade - 32) * 133 div 223, 216 + (AShade - 32) * 39 div 223);
  end;

  procedure Pen(AWidth: Integer);
  begin
    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Color := RGB(32, 122, 216);
    ACanvas.Pen.Width := AWidth;
  end;

  procedure NoPen;
  begin
    ACanvas.Pen.Style := psClear;
  end;

  procedure Hollow;
  begin
    ACanvas.Brush.Style := bsClear;
  end;

  procedure Line(X1, Y1, X2, Y2: Integer);
  begin
    ACanvas.MoveTo(X1, Y1);
    ACanvas.LineTo(X2, Y2);
  end;

  procedure Row(ALeft, ATop: Integer);
  begin
    // A list row: avatar and two lines of text, outlined
    Pen(5);
    Hollow;
    ACanvas.RoundRect(ALeft, ATop, ALeft + 76, ATop + 36, 14, 14);
    NoPen;
    Solid(32);
    ACanvas.Ellipse(ALeft + 8, ATop + 9, ALeft + 26, ATop + 27);
    Solid(120);
    ACanvas.Rectangle(ALeft + 32, ATop + 11, ALeft + 64, ATop + 16);
    ACanvas.Rectangle(ALeft + 32, ATop + 21, ALeft + 54, ATop + 26);
  end;

begin
  Result := True;
  if AName = 'otpcodefield' then
  begin
    // Four code boxes, two filled in
    for I := 0 to 3 do
    begin
      Pen(5);
      Hollow;
      if I = 2 then
        ACanvas.Pen.Width := 7;
      ACanvas.RoundRect(4 + I * 23, 30, 22 + I * 23, 66, 8, 8);
      if I < 2 then
      begin
        NoPen;
        Solid(32);
        ACanvas.Ellipse(8 + I * 23, 43, 18 + I * 23, 53);
      end;
    end;
  end
  else if AName = 'cardnumberfield' then
  begin
    // A card with its chip and number
    NoPen;
    Solid(120);
    ACanvas.RoundRect(4, 18, 92, 78, 16, 16);
    Solid(32);
    ACanvas.RoundRect(14, 30, 34, 46, 6, 6);
    for I := 0 to 3 do
      ACanvas.Rectangle(14 + I * 19, 58, 28 + I * 19, 64);
  end
  else if AName = 'strengthmeterfield' then
  begin
    // A password field and the strength bars under it
    Pen(5);
    Hollow;
    ACanvas.RoundRect(4, 18, 92, 54, 14, 14);
    NoPen;
    Solid(32);
    for I := 0 to 4 do
      ACanvas.Ellipse(14 + I * 13, 31, 23 + I * 13, 40);
    for I := 0 to 3 do
    begin
      if I < 3 then
        Solid(32)
      else
        Solid(190);
      ACanvas.RoundRect(4 + I * 23, 64, 22 + I * 23, 74, 6, 6);
    end;
  end
  else if AName = 'autogrowfield' then
  begin
    // A tall field with three lines and the send button
    Pen(5);
    Hollow;
    ACanvas.RoundRect(4, 10, 92, 86, 18, 18);
    NoPen;
    Solid(120);
    ACanvas.Rectangle(16, 24, 70, 30);
    ACanvas.Rectangle(16, 38, 64, 44);
    ACanvas.Rectangle(16, 52, 48, 58);
    Solid(32);
    ACanvas.Ellipse(58, 54, 84, 80);
  end
  else if AName = 'taginputfield' then
  begin
    // A field with two chips and the caret
    Pen(5);
    Hollow;
    ACanvas.RoundRect(2, 26, 94, 70, 16, 16);
    NoPen;
    Solid(32);
    ACanvas.RoundRect(10, 36, 42, 60, 22, 22);
    Solid(120);
    ACanvas.RoundRect(46, 36, 76, 60, 22, 22);
    Pen(4);
    Line(84, 36, 84, 60);
  end
  else if AName = 'ghostcompletefield' then
  begin
    // Typed text and its completion, fainter, in a field
    Pen(5);
    Hollow;
    ACanvas.RoundRect(2, 28, 94, 68, 16, 16);
    NoPen;
    Solid(32);
    ACanvas.Rectangle(12, 44, 44, 52);
    Solid(185);
    ACanvas.Rectangle(48, 44, 84, 52);
    Pen(3);
    Line(46, 38, 46, 58);
  end
  else if AName = 'swipecardstack' then
  begin
    // Two cards, the top one tilting away with a heart
    NoPen;
    Solid(170);
    ACanvas.RoundRect(14, 16, 66, 86, 14, 14);
    Solid(32);
    ACanvas.Polygon([Point(40, 18), Point(86, 6), Point(94, 72), Point(48, 84)]);
    ACanvas.Brush.Color := clWhite;
    ACanvas.Ellipse(56, 34, 70, 48);
    ACanvas.Ellipse(68, 31, 82, 45);
    ACanvas.Polygon([Point(57, 44), Point(81, 40), Point(72, 60)]);
  end
  else if AName = 'pinswipelist' then
  begin
    // A row pulled right, the pin behind it
    NoPen;
    Solid(150);
    ACanvas.RoundRect(2, 30, 40, 66, 14, 14);
    Solid(32);
    ACanvas.Ellipse(12, 38, 26, 52);
    ACanvas.Polygon([Point(15, 50), Point(23, 50), Point(19, 60)]);
    Row(18, 30);
  end
  else if AName = 'peekswipelist' then
  begin
    // A row nudged left, the action peeking out and an arrow
    NoPen;
    Solid(120);
    ACanvas.RoundRect(58, 40, 94, 76, 14, 14);
    Row(4, 40);
    Pen(5);
    Line(30, 18, 62, 18);
    Line(30, 18, 40, 10);
    Line(30, 18, 40, 26);
  end
  else if AName = 'liquiddeletelist' then
  begin
    // A row and the goo blob stretching off its edge
    Row(0, 30);
    NoPen;
    Solid(32);
    ACanvas.Polygon([Point(74, 40), Point(84, 44), Point(84, 52), Point(74, 56)]);
    ACanvas.Ellipse(78, 34, 96, 62);
  end
  else if AName = 'snoozeswipelist' then
  begin
    // A row pulled left and the clock behind it
    NoPen;
    Solid(150);
    ACanvas.RoundRect(52, 30, 94, 66, 14, 14);
    Pen(4);
    ACanvas.Brush.Color := clWhite;
    ACanvas.Ellipse(62, 36, 86, 60);
    Line(74, 48, 74, 40);
    Line(74, 48, 80, 52);
    Row(-22, 30);
  end
  else if AName = 'undoswipelist' then
  begin
    // The strip a deleted row leaves, with the undo arrow
    Pen(5);
    ACanvas.Pen.Style := psDot;
    ACanvas.Pen.Width := 1;
    Hollow;
    ACanvas.RoundRect(2, 28, 94, 68, 14, 14);
    Pen(6);
    ACanvas.Arc(40, 32, 76, 64, 40, 48, 70, 34);
    NoPen;
    Solid(32);
    ACanvas.Polygon([Point(34, 44), Point(50, 44), Point(42, 58)]);
  end
  else if AName = 'classicpager' then
  begin
    // Three page boxes, the middle one current, and the arrows
    Pen(5);
    Hollow;
    ACanvas.RoundRect(8, 32, 32, 64, 8, 8);
    ACanvas.RoundRect(64, 32, 88, 64, 8, 8);
    NoPen;
    Solid(32);
    ACanvas.RoundRect(36, 32, 60, 64, 8, 8);
  end
  else if AName = 'pillspager' then
  begin
    // Dots and the stretched pill of the current page
    NoPen;
    Solid(120);
    ACanvas.Ellipse(4, 40, 20, 56);
    ACanvas.Ellipse(76, 40, 92, 56);
    Solid(32);
    ACanvas.RoundRect(24, 40, 72, 56, 16, 16);
  end
  else if AName = 'dotspager' then
  begin
    NoPen;
    Solid(150);
    for I := 0 to 4 do
      if I <> 2 then
        ACanvas.Ellipse(6 + I * 18, 42, 18 + I * 18, 54);
    Solid(32);
    ACanvas.Ellipse(38, 36, 58, 56);
  end
  else if AName = 'borderedpager' then
  begin
    // One frame around the pages, the current one filled
    Pen(5);
    Hollow;
    ACanvas.RoundRect(4, 30, 92, 66, 10, 10);
    Line(33, 30, 33, 66);
    Line(63, 30, 63, 66);
    NoPen;
    Solid(32);
    ACanvas.Rectangle(35, 32, 62, 65);
  end
  else if AName = 'trackpager' then
  begin
    NoPen;
    Solid(190);
    ACanvas.RoundRect(4, 42, 92, 54, 12, 12);
    Solid(32);
    ACanvas.RoundRect(30, 38, 62, 58, 20, 20);
  end
  else if AName = 'segmentedpager' then
  begin
    NoPen;
    Solid(190);
    ACanvas.RoundRect(2, 32, 94, 64, 16, 16);
    Solid(32);
    ACanvas.RoundRect(34, 36, 62, 60, 12, 12);
  end
  else if AName = 'progresspager' then
  begin
    // The progress bar between two arrows
    NoPen;
    Solid(190);
    ACanvas.RoundRect(22, 42, 74, 54, 12, 12);
    Solid(32);
    ACanvas.RoundRect(22, 42, 54, 54, 12, 12);
    ACanvas.Polygon([Point(4, 48), Point(16, 38), Point(16, 58)]);
    ACanvas.Polygon([Point(92, 48), Point(80, 38), Point(80, 58)]);
  end
  else if AName = 'stepspager' then
  begin
    Pen(4);
    Line(14, 48, 82, 48);
    NoPen;
    Solid(32);
    ACanvas.Ellipse(4, 38, 24, 58);
    ACanvas.Ellipse(38, 38, 58, 58);
    Pen(4);
    ACanvas.Brush.Color := clWhite;
    ACanvas.Ellipse(72, 38, 92, 58);
  end
  else if AName = 'numberedsteps' then
  begin
    // Two steps done, one to go
    Pen(6);
    Line(14, 48, 46, 48);
    ACanvas.Pen.Color := RGB(190, 220, 245);
    Line(46, 48, 82, 48);
    NoPen;
    Solid(32);
    ACanvas.Ellipse(2, 36, 26, 60);
    ACanvas.Ellipse(36, 36, 60, 60);
    Pen(5);
    ACanvas.Brush.Color := clWhite;
    ACanvas.Ellipse(70, 36, 94, 60);
  end
  else if AName = 'segmentbarsteps' then
  begin
    NoPen;
    for I := 0 to 3 do
    begin
      if I < 2 then
        Solid(32)
      else
        Solid(190);
      ACanvas.RoundRect(2 + I * 24, 42, 22 + I * 24, 54, 10, 10);
    end;
  end
  else if AName = 'checkoutsteps' then
  begin
    // A check badge, a dotted path, the next step
    Pen(4);
    ACanvas.Pen.Style := psDot;
    ACanvas.Pen.Width := 1;
    Line(30, 48, 66, 48);
    NoPen;
    Solid(32);
    ACanvas.Ellipse(4, 30, 40, 66);
    Pen(5);
    ACanvas.Pen.Color := clWhite;
    Line(13, 48, 20, 55);
    Line(20, 55, 31, 41);
    Pen(5);
    ACanvas.Brush.Color := clWhite;
    ACanvas.Ellipse(64, 34, 92, 62);
  end
  else if AName = 'ordertrackingsteps' then
  begin
    // The van on its road
    Pen(5);
    Line(2, 80, 94, 80);
    NoPen;
    Solid(32);
    ACanvas.RoundRect(6, 30, 58, 66, 8, 8);
    ACanvas.Polygon([Point(58, 40), Point(78, 40), Point(90, 54), Point(90, 66), Point(58, 66)]);
    ACanvas.Brush.Color := clWhite;
    ACanvas.Ellipse(16, 58, 32, 74);
    ACanvas.Ellipse(64, 58, 80, 74);
    Solid(32);
    ACanvas.Ellipse(20, 62, 28, 70);
    ACanvas.Ellipse(68, 62, 76, 70);
  end
  else if AName = 'breadcrumbsteps' then
  begin
    // Arrow shaped steps, two done
    NoPen;
    Solid(32);
    ACanvas.Polygon([Point(2, 32), Point(30, 32), Point(42, 48), Point(30, 64), Point(2, 64)]);
    ACanvas.Polygon([Point(34, 32), Point(58, 32), Point(70, 48), Point(58, 64), Point(34, 64), Point(46, 48)]);
    Solid(190);
    ACanvas.Polygon([Point(62, 32), Point(94, 32), Point(94, 64), Point(62, 64), Point(74, 48)]);
  end
  else if AName = 'ringsteps' then
  begin
    // A ring three quarters round, the number in the middle
    Pen(10);
    ACanvas.Pen.Color := RGB(190, 220, 245);
    Hollow;
    ACanvas.Ellipse(12, 12, 84, 84);
    Pen(10);
    ACanvas.Arc(12, 12, 84, 84, 12, 48, 48, 12);
    NoPen;
    Solid(32);
    ACanvas.Rectangle(43, 34, 53, 62);
  end
  else
    Result := False;
end;

procedure DrawControl(ACanvas: TCanvas; const AName: string);
var
  Name, Letters: string;
  I: Integer;
  Area: TRect;

  procedure Line(X1, Y1, X2, Y2: Integer);
  begin
    ACanvas.MoveTo(X1 * 4, Y1 * 4);
    ACanvas.LineTo(X2 * 4, Y2 * 4);
  end;

  procedure Box(X1, Y1, X2, Y2: Integer);
  begin
    ACanvas.Rectangle(X1 * 4, Y1 * 4, X2 * 4, Y2 * 4);
  end;

  procedure Circle(X1, Y1, X2, Y2: Integer);
  begin
    ACanvas.Ellipse(X1 * 4, Y1 * 4, X2 * 4, Y2 * 4);
  end;

begin
  Name := LowerCase(AName);
  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Color := RGB(32, 122, 216);
  ACanvas.Pen.Width := 6;
  if (Name = 'textblock') or (Name = 'richtextblock') then
  begin
    // A label, like VCL's TLabel: text without a box
    ACanvas.Font.Name := 'Segoe UI';
    ACanvas.Font.Height := -44;
    ACanvas.Font.Style := [fsBold];
    ACanvas.Font.Color := RGB(32, 122, 216);
    Area := Rect(0, 8, 96, 88);
    DrawText(ACanvas.Handle, 'Abc', 3, Area, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    if Name = 'richtextblock' then
    begin
      Line(4, 20, 20, 20);
    end;
  end
  else if ContainsText(Name, 'hyperlink') then
  begin
    ACanvas.Font.Name := 'Segoe UI';
    ACanvas.Font.Height := -40;
    ACanvas.Font.Style := [fsUnderline];
    ACanvas.Font.Color := RGB(32, 122, 216);
    Area := Rect(0, 4, 96, 84);
    DrawText(ACanvas.Handle, 'link', 4, Area, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  end
  else if Name = 'richeditbox' then
  begin
    Box(2, 3, 22, 21); Line(5, 7, 19, 7); Line(5, 11, 19, 11); Line(5, 15, 14, 15); Line(16, 14, 16, 18);
  end
  else if Name = 'flipview' then
  begin
    Box(5, 4, 19, 20); Line(3, 9, 1, 12); Line(1, 12, 3, 15); Line(21, 9, 23, 12); Line(23, 12, 21, 15);
  end
  else if Name = 'breadcrumbbar' then
  begin
    Line(2, 12, 6, 12); Line(8, 9, 10, 12); Line(10, 12, 8, 15); Line(12, 12, 15, 12);
    Line(17, 9, 19, 12); Line(19, 12, 17, 15); Line(21, 12, 22, 12);
  end
  else if Name = 'selectorbar' then
  begin
    Line(2, 10, 7, 10); Line(9, 10, 15, 10); Line(17, 10, 22, 10); Line(9, 15, 15, 15);
  end
  else if Name = 'radiobuttons' then
  begin
    Circle(3, 3, 11, 11); Circle(5, 5, 9, 9); Circle(3, 13, 11, 21); Line(14, 7, 21, 7); Line(14, 17, 21, 17);
  end
  else if Name = 'splitbutton' then
  begin
    Box(2, 6, 22, 18); Line(16, 6, 16, 18); Line(18, 11, 19, 13); Line(19, 13, 20, 11); Line(5, 12, 13, 12);
  end
  else if Name = 'fonticon' then
  begin
    Box(3, 3, 21, 21); Line(8, 18, 12, 6); Line(12, 6, 16, 18); Line(9, 14, 15, 14);
  end
  else if Name = 'symbolicon' then
  begin
    Circle(3, 3, 21, 21); Line(12, 6, 12, 18); Line(6, 12, 18, 12);
  end
  else if Name = 'line' then
    Line(4, 19, 20, 5)
  else if Name = 'polygon' then
  begin
    Line(12, 3, 21, 20); Line(21, 20, 3, 20); Line(3, 20, 12, 3);
  end
  else if Name = 'path' then
  begin
    ACanvas.Arc(12, 20, 84, 92, 84, 56, 12, 56); Line(3, 14, 3, 14);
  end
  else if Name = 'infobar' then
  begin
    Box(2, 6, 22, 18); Circle(4, 9, 10, 15); Line(7, 11, 7, 13); Line(12, 12, 20, 12);
  end
  else if Name = 'infobadge' then
  begin
    Circle(6, 6, 18, 18); Line(12, 9, 12, 13); Circle(11, 15, 13, 17);
  end
  else if Name = 'ratingcontrol' then
  begin
    Line(12, 3, 15, 10); Line(15, 10, 22, 10); Line(22, 10, 16, 14); Line(16, 14, 18, 21);
    Line(18, 21, 12, 17); Line(12, 17, 6, 21); Line(6, 21, 8, 14); Line(8, 14, 2, 10);
    Line(2, 10, 9, 10); Line(9, 10, 12, 3);
  end
  else if Name = 'webview2' then
  begin
    Circle(3, 3, 21, 21); Line(3, 12, 21, 12); ACanvas.Ellipse(36, 12, 60, 84);
  end
  else if Name = 'expander' then
  begin
    Box(2, 3, 22, 9); Line(16, 5, 18, 7); Line(18, 7, 20, 5); Box(2, 11, 22, 21);
  end
  else if Name = 'personpicture' then
  begin
    Circle(3, 3, 21, 21); Circle(9, 7, 15, 13); Line(7, 18, 12, 15); Line(12, 15, 17, 18);
  end
  else if Name = 'relativepanel' then
  begin
    Box(3, 3, 21, 21); Box(5, 5, 11, 11); Box(13, 13, 19, 19); Line(11, 8, 16, 8); Line(16, 8, 16, 13);
  end
  else if Name = 'viewbox' then
  begin
    Box(3, 3, 21, 21); Line(6, 6, 10, 10); Line(18, 18, 14, 14); Line(6, 6, 6, 9); Line(6, 6, 9, 6);
    Line(18, 18, 18, 15); Line(18, 18, 15, 18);
  end
  else if Name = 'window' then
  begin
    // The Structure view root: a window with a title bar and caption buttons
    Box(2, 3, 22, 21); Line(2, 8, 22, 8); Line(15, 5, 16, 5); Line(18, 5, 19, 5);
  end
  else if Name = 'notchpanel' then
  begin
    // The screen's top edge with a pill hanging from it
    Line(2, 4, 22, 4); ACanvas.RoundRect(28, 16, 68, 40, 24, 24); Box(4, 12, 20, 21);
  end
  else if Name = 'glowtile' then
  begin
    // A tile and its glow
    ACanvas.RoundRect(24, 24, 72, 72, 16, 16); ACanvas.Pen.Width := 2; ACanvas.RoundRect(10, 10, 86, 86, 28, 28);
  end
  else if Name = 'hotkey' then
  begin
    // Two key caps: Ctrl + a letter
    ACanvas.RoundRect(8, 28, 44, 68, 10, 10); ACanvas.RoundRect(52, 28, 88, 68, 10, 10);
  end
  else if Name = 'mediasession' then
  begin
    // Play and pause
    Line(4, 7, 4, 17); Line(4, 7, 11, 12); Line(4, 17, 11, 12); Line(15, 7, 15, 17); Line(19, 7, 19, 17);
  end
  else if DrawAdvancedControl(ACanvas, Name) then
    // Drawn above
  else if Name.StartsWith('db') then
    DrawDataControl(ACanvas, Name)
  else if Name.EndsWith('tabbar') then
    DrawTabBar(ACanvas, Name)
  else if IsActionButton(Name) then
    DrawActionButton(ACanvas, Name)
  else if Name = 'pipspager' then
  begin
    Circle(3, 10, 7, 14); Circle(10, 10, 14, 14); Circle(17, 10, 21, 14);
  end
  else if ContainsText(Name, 'calendar') or ContainsText(Name, 'date') then
  begin
    Box(3, 5, 21, 21); Line(3, 10, 21, 10);
    Line(7, 2, 7, 8); Line(17, 2, 17, 8);
    Box(7, 13, 10, 16); Box(14, 13, 17, 16);
  end
  else if ContainsText(Name, 'time') then
  begin
    Circle(3, 3, 21, 21); Line(12, 6, 12, 12); Line(12, 12, 17, 15);
  end
  else if ContainsText(Name, 'color') then
  begin
    Circle(3, 3, 21, 21); Circle(7, 6, 10, 9); Circle(14, 6, 17, 9);
    Circle(6, 13, 9, 16); Line(13, 17, 19, 17);
  end
  else if ContainsText(Name, 'toggle') then
  begin
    ACanvas.RoundRect(8, 24, 88, 72, 48, 48); Circle(5, 8, 13, 16);
  end
  else if ContainsText(Name, 'check') then
  begin
    Box(4, 4, 20, 20); Line(7, 12, 11, 16); Line(11, 16, 18, 8);
  end
  else if ContainsText(Name, 'radio') then
  begin
    Circle(3, 3, 21, 21); Circle(8, 8, 16, 16);
  end
  else if ContainsText(Name, 'combo') or ContainsText(Name, 'dropdown') then
  begin
    Box(2, 6, 22, 18); Line(5, 12, 12, 12); Line(16, 10, 18, 13); Line(18, 13, 20, 10);
  end
  else if ContainsText(Name, 'number') then
  begin
    Box(2, 4, 22, 20); Line(16, 4, 16, 20); Line(16, 12, 22, 12);
    Line(18, 8, 20, 8); Line(19, 7, 19, 9); Line(18, 16, 20, 16); Line(8, 8, 8, 17);
  end
  else if ContainsText(Name, 'text') or ContainsText(Name, 'password') or ContainsText(Name, 'suggest') then
  begin
    Box(2, 5, 22, 19); Line(6, 9, 14, 9); Line(6, 14, 12, 14); Line(18, 8, 18, 16);
  end
  else if ContainsText(Name, 'tree') then
  begin
    Line(5, 4, 5, 19); Line(5, 8, 11, 8); Line(5, 17, 11, 17);
    Box(12, 5, 21, 11); Box(12, 14, 21, 20);
  end
  else if ContainsText(Name, 'list') or ContainsText(Name, 'items') or ContainsText(Name, 'repeater') then
  begin
    for I := 0 to 2 do begin Box(3, 4 + I * 6, 6, 7 + I * 6); Line(10, 6 + I * 6, 21, 6 + I * 6); end;
  end
  else if ContainsText(Name, 'grid') or ContainsText(Name, 'wrap') then
  begin
    Box(3, 3, 21, 21); Line(3, 10, 21, 10); Line(10, 3, 10, 21);
  end
  else if ContainsText(Name, 'stack') or ContainsText(Name, 'panel') or (Name = 'canvas') then
  begin
    Box(3, 3, 21, 21); Box(6, 6, 18, 10); Box(6, 14, 18, 18);
  end
  else if ContainsText(Name, 'image') or ContainsText(Name, 'bitmap') or ContainsText(Name, 'icon') then
  begin
    Box(2, 4, 22, 20); Circle(6, 7, 10, 11); Line(4, 18, 13, 11); Line(13, 11, 21, 18);
  end
  else if ContainsText(Name, 'slider') or ContainsText(Name, 'scroll') then
  begin
    Line(3, 12, 21, 12); Box(8, 7, 13, 17); Line(3, 8, 3, 16); Line(21, 8, 21, 16);
  end
  else if ContainsText(Name, 'progress') then
  begin
    if ContainsText(Name, 'ring') then begin Circle(3, 3, 21, 21); Line(12, 3, 12, 8); end
    else begin Box(2, 8, 22, 16); Box(5, 10, 13, 14); end;
  end
  else if ContainsText(Name, 'media') or ContainsText(Name, 'player') then
  begin
    Box(2, 4, 22, 20); Line(9, 8, 16, 12); Line(16, 12, 9, 16); Line(9, 16, 9, 8);
  end
  else if ContainsText(Name, 'navigation') or ContainsText(Name, 'splitview') then
  begin
    Box(2, 3, 22, 21); Line(9, 3, 9, 21); Line(4, 7, 7, 7); Line(4, 11, 7, 11); Line(4, 15, 7, 15);
  end
  else if ContainsText(Name, 'menu') or ContainsText(Name, 'command') or ContainsText(Name, 'appbar') then
  begin
    Box(3, 3, 21, 21); Line(6, 7, 18, 7); Line(6, 12, 18, 12); Line(6, 17, 15, 17);
  end
  else if ContainsText(Name, 'tab') or ContainsText(Name, 'pivot') then
  begin
    Box(2, 7, 22, 21); Box(3, 3, 10, 7); Line(12, 4, 20, 4);
  end
  else if ContainsText(Name, 'ellipse') then Circle(3, 5, 21, 19)
  else if ContainsText(Name, 'rectangle') or ContainsText(Name, 'border') then Box(3, 4, 21, 20)
  else if ContainsText(Name, 'line') or ContainsText(Name, 'path') or ContainsText(Name, 'polygon') then
  begin Line(3, 18, 8, 6); Line(8, 6, 15, 16); Line(15, 16, 21, 3); end
  else if ContainsText(Name, 'button') then
  begin
    ACanvas.RoundRect(8, 24, 88, 72, 12, 12); Line(7, 12, 17, 12);
  end
  else
  begin
    // Less common controls retain a readable type-specific monogram.
    Letters := UpperCase(Copy(AName, 1, 2));
    ACanvas.Font.Name := 'Segoe UI';
    ACanvas.Font.Height := -46;
    ACanvas.Font.Style := [fsBold];
    ACanvas.Font.Color := RGB(32, 122, 216);
    Area := Rect(0, 0, 96, 96);
    DrawText(ACanvas.Handle, PChar(Letters), Length(Letters), Area, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  end;
end;

var
  Cache: TObjectDictionary<string, TBitmap>;

/// AName drawn at ASize: rendered at 96 px on white, scaled with halftone, then the white
/// coverage turned into premultiplied alpha, so strokes have no fringe on dark palettes.
function RenderIcon(const AName: string; ASize: Integer): TBitmap;
var
  Source: TBitmap;
  X, Y, Alpha, Red: Integer;
  Pixel: PCardinal;
begin
  Source := TBitmap.Create;
  Result := TBitmap.Create;
  try
    Source.PixelFormat := pf32bit;
    Source.SetSize(96, 96);
    Source.Canvas.Brush.Color := clWhite;
    Source.Canvas.FillRect(Rect(0, 0, 96, 96));
    DrawControl(Source.Canvas, AName);
    Result.PixelFormat := pf32bit;
    Result.SetSize(ASize, ASize);
    SetStretchBltMode(Result.Canvas.Handle, HALFTONE);
    SetBrushOrgEx(Result.Canvas.Handle, 0, 0, nil);
    StretchBlt(Result.Canvas.Handle, 0, 0, ASize, ASize, Source.Canvas.Handle, 0, 0, 96, 96, SRCCOPY);
    for Y := 0 to ASize - 1 do
      for X := 0 to ASize - 1 do
      begin
        Pixel := PCardinal(PByte(Result.ScanLine[Y]) + X * 4);
        Red := (Pixel^ shr 16) and $FF;
        Alpha := (255 - Red) * 255 div (255 - 32);
        if Alpha > 255 then Alpha := 255;
        if Alpha < 0 then Alpha := 0;
        Pixel^ := Cardinal(Alpha) shl 24 or Cardinal(32 * Alpha div 255) shl 16 or
          Cardinal(122 * Alpha div 255) shl 8 or Cardinal(216 * Alpha div 255);
      end;
    Result.AlphaFormat := afPremultiplied;
  except
    Result.Free;
    raise;
  end;
  Source.Free;
end;

function PaletteBitmap(const AName: string; ASize: Integer): TBitmap;
var
  Key: string;
begin
  if Cache = nil then
    Cache := TObjectDictionary<string, TBitmap>.Create([doOwnsValues]);
  Key := AName + '|' + IntToStr(ASize);
  if not Cache.TryGetValue(Key, Result) then
  begin
    Result := RenderIcon(AName, ASize);
    Cache.Add(Key, Result);
  end;
end;

procedure DrawPaletteIcon(ACanvas: TCanvas; X, Y, ASize: Integer; const AName: string; AEnabled: Boolean);
var
  Bitmap: TBitmap;
  Blend: TBlendFunction;
begin
  if ASize <= 0 then
    Exit;
  Bitmap := PaletteBitmap(AName, ASize);
  Blend.BlendOp := AC_SRC_OVER;
  Blend.BlendFlags := 0;
  Blend.SourceConstantAlpha := 255;
  if not AEnabled then
    Blend.SourceConstantAlpha := 110;
  Blend.AlphaFormat := AC_SRC_ALPHA;
  Winapi.Windows.AlphaBlend(ACanvas.Handle, X, Y, ASize, ASize, Bitmap.Canvas.Handle, 0, 0, ASize, ASize, Blend);
end;

function PaletteIcon(ACollection: TImageCollection; const AName: string): Integer;
var
  Item: TImageCollectionItem;
  Name: string;
  Size: Integer;
begin
  Name := 'RADWinUI.v4\' + AName;
  Result := ACollection.GetIndexByName(Name);
  if Result >= 0 then Exit;
  // Collection insertion notifies the IDE before VCL initializes SourceImages.
  // Build off-collection so its image-cache timer only sees complete items.
  Item := TImageCollectionItem.Create(nil);
  try
    Item.Name := Name;
    for Size in [16, 24, 32, 48] do
      Item.SourceImages.Add.Image.Assign(PaletteBitmap(AName, Size));
    Item.Collection := ACollection.Images;
    Result := Item.Index;
    Item := nil; // The IDE collection now owns the complete item.
  finally
    Item.Free;
  end;
end;

initialization

finalization
  Cache.Free;

end.
