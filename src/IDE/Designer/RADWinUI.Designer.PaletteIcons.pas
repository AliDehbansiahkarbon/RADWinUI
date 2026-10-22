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
