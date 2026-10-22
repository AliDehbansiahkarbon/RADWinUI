program DesignerModelTest;

{
  Checks the designer's IDE-free parts: RADWinUI.Designer.Model
  and the property grid form RADWinUI.Designer.Inspector (created, never shown).

    DesignerModelTest <RADWinUI root>

  scripts\Test-Preview.ps1 runs it.
}

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.Imaging.pngimage,
  System.Types,
  RADWinUI.Designer.XamlEdit in '..\..\src\IDE\Designer\RADWinUI.Designer.XamlEdit.pas',
  RADWinUI.Designer.PaletteIcons in '..\..\src\IDE\Designer\RADWinUI.Designer.PaletteIcons.pas',
  RADWinUI.Designer.Palette in '..\..\src\IDE\Designer\RADWinUI.Designer.Palette.pas',
  RADWinUI.Designer.Model in '..\..\src\IDE\Designer\RADWinUI.Designer.Model.pas',
  RADWinUI.Designer.Inspector in '..\..\src\IDE\Designer\RADWinUI.Designer.Inspector.pas';

var
  Failures: Integer;

procedure Check(ACondition: Boolean; const AWhat: string);
begin
  if ACondition then
    Writeln('  [ok] ', AWhat)
  else
  begin
    Writeln('  [failed] ', AWhat);
    Inc(Failures);
  end;
end;

function Names(const AProps: TArray<TDesignerProperty>; ACount: Integer): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to ACount - 1 do
    Result := Result + AProps[I].Name + ' ';
  Result := Result.Trim;
end;

function FindProp(const AProps: TArray<TDesignerProperty>; const AName: string): TDesignerProperty;
var
  Prop: TDesignerProperty;
begin
  for Prop in AProps do
    if Prop.Name = AName then
      Exit(Prop);
  Result := Default(TDesignerProperty);
end;

const
  Pas =
    'unit MainWindow;' + sLineBreak +
    'interface' + sLineBreak +
    'type' + sLineBreak +
    '  TMainWindow = class(TMainWindowBase)' + sLineBreak +
    '  published' + sLineBreak +
    '    procedure ResetClick(Sender: TObject);' + sLineBreak +
    '  end;' + sLineBreak +
    'implementation' + sLineBreak +
    'procedure TMainWindow.ResetClick(Sender: TObject);' + sLineBreak +
    'begin' + sLineBreak +
    'end;' + sLineBreak +
    'end.' + sLineBreak;

var
  Index: TDesignerTypeIndex;
  Props: TArray<TDesignerProperty>;
  Events: TArray<TDesignerEvent>;
  Event: TDesignerEvent;
  Sel: TDesignerSelection;
  Change: TTextChange;
  Old, New, Text, Xaml: string;
  Line: Integer;
  Inspector: TDesignerInspector;
  Host: TForm;
  Json: TJSONObject;
  Known, Seen, Missing, Wrappers, Runtime: string;
  I, Size, X, Y, Ink: Integer;
  Blank: string;
  Sheet, Icon: TBitmap;
  Png: TPngImage;
  Entry: TPaletteEntry;
  Changed, Handled: string;
begin
  if ParamCount <> 1 then
  begin
    Writeln('usage: DesignerModelTest <RADWinUI root>');
    Halt(2);
  end;
  Writeln('Designer model');
  Index := TDesignerTypeIndex.Create(TPath.Combine(ParamStr(1), 'src\Generated\RADWinUI.Xaml.json'));
  try
    Props := Index.PropertiesOf('Button');
    Check(Names(Props, 5) = 'Name Align Content IsEnabled Visibility', 'Button: common properties first (' + Names(Props, 5) + ')');
    Check(FindProp(Props, 'HorizontalAlignment').Kind = 'enum:Left|Center|Right|Stretch', 'an enum carries its values');
    Check(FindProp(Props, 'IsEnabled').Kind = 'bool', 'a Boolean is bool');
    Check(FindProp(Props, 'Background').Kind = 'brush', 'a Brush is brush');
    Check(Length(Index.PropertiesOf('NoSuchTag')) = 0, 'an unknown tag has no properties');
    Events := Index.EventsOf('Button');
    Handled := '';
    for Event in Events do
      if Event.Name = 'Click' then
        Handled := Event.ArgsType;
    Check(Handled = 'TWinUIRoutedEventArgs', 'Button: Click with TWinUIRoutedEventArgs, inherited events too (' +
      IntToStr(Length(Events)) + ')');
  finally
    Index.Free;
  end;

  Check(TDesignerSelection.Parse('SELECTED 8 9 Button IncrementButton', Sel) and (Sel.Line = 8) and (Sel.Column = 9) and
    (Sel.Tag = 'Button') and (Sel.Name = 'IncrementButton'), 'parses a selection');
  Check(TDesignerSelection.Parse('SELECTED 9 9 Button -', Sel) and (Sel.Name = ''), 'an unnamed element has no name');
  Check(not TDesignerSelection.Parse('NONE', Sel), 'rejects anything else');

  Old := '<Button Content="Increment"/>';
  New := '<Button Content="Plus"/>';
  Change := TextChange(Old, New);
  Check((Change.Start = 17) and (Change.Length = 9) and (Change.Text = 'Plus'), 'one replacement covers an edit');
  Check(Old.Remove(Change.Start, Change.Length).Insert(Change.Start, Change.Text) = New, 'applying it gives the new text');
  Change := TextChange('aXa', 'aXXa');
  Check('aXa'.Remove(Change.Start, Change.Length).Insert(Change.Start, Change.Text) = 'aXXa', 'an insertion of a repeated character');
  Check(Utf8Offset('Gr'#$FC#$DF'e x', 6) = 8, 'editor offsets count UTF-8 bytes');
  Check(WindowClass('<Window xmlns="x"' + sLineBreak + '  x:Class="TMainWindow" Title="T">') = 'TMainWindow', 'reads x:Class');
  Check(AttributeOf('Name') = 'x:Name', 'Name is written as x:Name');

  Check(FindHandler(Pas, 'TMainWindow', 'ResetClick') = 9, 'finds an existing handler''s line');
  Check(FindHandler(Pas, 'TMainWindow', 'IncrementButtonClick') = 0, 'a missing handler is 0');
  Text := AddHandler(Pas, 'TMainWindow', 'IncrementButtonClick', 'TWinUIRoutedEventArgs', Line);
  Check(Text.Contains('  published' + sLineBreak + '    procedure IncrementButtonClick(Sender: TObject; E: TWinUIRoutedEventArgs);'),
    'declares the handler in the published section');
  Check(FindHandler(Text, 'TMainWindow', 'IncrementButtonClick') = Line - 2, 'adds its body; the cursor goes inside');
  Check(Text.TrimRight.EndsWith('end;' + sLineBreak + sLineBreak + 'end.'), 'before the final end.');
  Text := AddHandler(Pas.Replace('  published' + sLineBreak + '    procedure ResetClick(Sender: TObject);' + sLineBreak, ''),
    'TMainWindow', 'OkClick', 'TWinUIRoutedEventArgs', Line);
  Check(Text.Contains('  published' + sLineBreak + '    procedure OkClick(Sender: TObject; E: TWinUIRoutedEventArgs);' +
    sLineBreak + '  end;'), 'adds a published section when there is none');
  Old := TFile.ReadAllText(TPath.Combine(ParamStr(1), 'samples\Gallery\MainWindow.pas'));
  New := Old;
  Text := AddHandler(Old, 'TMainWindow', 'GalleryRegressionClick', 'TWinUIRoutedEventArgs', Line);
  Check(Old = New, 'large handler generation preserves its input snapshot');
  Change := TextChange(Old, Text);
  Check(Old = New, 'large diff preserves its input snapshot');
  New := Old.Remove(Change.Start, Change.Length).Insert(Change.Start, Change.Text);
  Check(New = Text, 'large Gallery handler edit reconstructs the complete unit');
  Check(Text.Contains('  CopySource(PascalSource.Text);' + sLineBreak + 'end;'),
    'large Gallery handler generation preserves the last nonempty body');

  Writeln('Tool Palette list');
  Json := TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(ParamStr(1), 'src\Generated\RADWinUI.Xaml.json'),
    TEncoding.UTF8)) as TJSONObject;
  try
    Known := '|';
    Wrappers := '';
    for I := 0 to (Json.GetValue('palette') as TJSONArray).Count - 1 do
    begin
      Known := Known + ((Json.GetValue('palette') as TJSONArray).Items[I] as TJSONObject).GetValue('name').Value + '|';
      // The palette shows TWinUI<Name>: it must be the wrapper class Pascal code uses
      Runtime := ((Json.GetValue('palette') as TJSONArray).Items[I] as TJSONObject).GetValue('runtime').Value;
      if (PaletteCategoryOf(((Json.GetValue('palette') as TJSONArray).Items[I] as TJSONObject).GetValue('name').Value) <> '') and
        ((Json.GetValue('classes') as TJSONObject).GetValue(Runtime) is TJSONObject) and
        (((Json.GetValue('classes') as TJSONObject).GetValue(Runtime) as TJSONObject).GetValue('wrapper').Value <>
        'TWinUI' + ((Json.GetValue('palette') as TJSONArray).Items[I] as TJSONObject).GetValue('name').Value) then
        Wrappers := Wrappers + Runtime + ' ';
    end;
    Check(Wrappers = '', 'every palette name TWinUI<Name> is its wrapper class (' + Wrappers.Trim + ')');
  finally
    Json.Free;
  end;
  Missing := '';
  Seen := '|';
  for Entry in PaletteEntries do
  begin
    if not Known.Contains('|' + Entry.Name + '|') then
      Missing := Missing + Entry.Name + ' ';
    Check(not Seen.Contains('|' + Entry.Name + '|'), Entry.Name + ' is on the palette once');
    Seen := Seen + Entry.Name + '|';
  end;
  Check(Missing = '', 'every curated control is a creatable control of the metadata (' + Missing.Trim + ')');
  Check(Length(PaletteEntries) >= 60, Format('%d controls in %d categories', [Length(PaletteEntries),
    Length(PaletteCategories)]));
  Check((PaletteCategories[0] = 'Standard') and (PaletteEntries[0].Name = 'Button'), 'Standard comes first, Button first in it');
  Check((PaletteCategoryOf('CalendarViewDayItem') = '') and (PaletteCategoryOf('ColorSpectrum') = '') and
    (PaletteCategoryOf('AppBarElementContainer') = '') and (PaletteCategoryOf('BreadcrumbBarItem') = ''),
    'part and template types are not on the palette');
  Check(PaletteCategoryOf('Grid') = 'Layout', 'Grid is in Layout');

  // Every curated control has a visible icon at the palette's sizes, a contact sheet
  // (build\logs\palette-icons.png) shows them for review on a dark background
  Blank := '';
  Sheet := TBitmap.Create;
  try
    Sheet.PixelFormat := pf32bit;
    Sheet.SetSize(8 * 150, ((Length(PaletteEntries) + 7) div 8) * 60);
    Sheet.Canvas.Brush.Color := RGB(37, 37, 38);
    Sheet.Canvas.FillRect(Rect(0, 0, Sheet.Width, Sheet.Height));
    Sheet.Canvas.Font.Color := RGB(220, 220, 220);
    Sheet.Canvas.Font.Height := -11;
    I := 0;
    for Entry in PaletteEntries do
    begin
      for Size in [16, 24, 32] do
      begin
        Icon := PaletteBitmap(Entry.Name, Size);
        Ink := 0;
        for Y := 0 to Size - 1 do
          for X := 0 to Size - 1 do
            if (PCardinal(PByte(Icon.ScanLine[Y]) + X * 4)^ shr 24) > 64 then
              Inc(Ink);
        if (Ink < Size div 2) and not Blank.Contains(Entry.Name) then
          Blank := Blank + Entry.Name + ' ';
      end;
      DrawPaletteIcon(Sheet.Canvas, (I mod 8) * 150 + 59, (I div 8) * 60 + 4, 32, Entry.Name, True);
      Sheet.Canvas.Brush.Style := bsClear;
      Sheet.Canvas.TextOut((I mod 8) * 150 + 4, (I div 8) * 60 + 40, 'TWinUI' + Entry.Name);
      Inc(I);
    end;
    Png := TPngImage.Create;
    try
      Png.Assign(Sheet);
      ForceDirectories(TPath.Combine(ParamStr(1), 'build\logs'));
      Png.SaveToFile(TPath.Combine(ParamStr(1), 'build\logs\palette-icons.png'));
    finally
      Png.Free;
    end;
  finally
    Sheet.Free;
  end;
  Check(Blank = '', 'every palette control has a visible icon at 16, 24 and 32 px (' + Blank.Trim + ')');
  // The Structure view's root node uses the same source
  Icon := PaletteBitmap('Window', 16);
  Ink := 0;
  for Y := 0 to 15 do
    for X := 0 to 15 do
      if (PCardinal(PByte(Icon.ScanLine[Y]) + X * 4)^ shr 24) > 64 then
        Inc(Ink);
  Check(Ink >= 8, 'the Structure view root (Window) has a visible icon');

  Writeln('Property grid');
  Index := TDesignerTypeIndex.Create(TPath.Combine(ParamStr(1), 'src\Generated\RADWinUI.Xaml.json'));
  try
    Old := Pas.Replace('begin' + sLineBreak + 'end;', 'begin' + sLineBreak +
      '  CopySource(PascalSource.Text);' + sLineBreak + 'end;');
    Text := AddHandler(Old, 'TMainWindow', 'Button1Click', 'TWinUIRoutedEventArgs', Line);
    Xaml := '<Window x:Class="TMainWindow"><Grid><Button x:Name="Button1" Click="Button1Click"/></Grid></Window>';
    Check(CleanupEmptyHandlers(Xaml, Text, Index), 'save removes an empty last event handler');
    Check(Text = Old, 'save preserves the previous handler and final unit terminator exactly');
    Check(not Xaml.Contains('Click="Button1Click"'), 'save removes the empty handler assignment');
    Text := AddHandler(Old, 'TMainWindow', 'Button1Click', 'TWinUIRoutedEventArgs', Line);
    Text := Text.Replace('begin' + sLineBreak + sLineBreak + 'end;',
      'begin' + sLineBreak + '  DoSomething;' + sLineBreak + 'end;');
    New := Text;
    Xaml := '<Window x:Class="TMainWindow"><Grid><Button x:Name="Button1" Click="Button1Click"/></Grid></Window>';
    Check(not CleanupEmptyHandlers(Xaml, Text, Index), 'save keeps a populated last event handler');
    Check((Text = New) and Xaml.Contains('Click="Button1Click"'),
      'save preserves the populated method and its assignment exactly');
  finally
    Index.Free;
  end;
  Index := TDesignerTypeIndex.Create(TPath.Combine(ParamStr(1), 'src\Generated\RADWinUI.Xaml.json'));
  Host := TForm.CreateNew(nil); // never shown: the panel needs a parent window
  Inspector := TDesignerInspector.CreateIn(Host);
  try
    Inspector.ShowElement('Button IncrementButton', Index.PropertiesOf('Button'),
      function(AName: string): string
      begin
        if AName = 'Content' then
          Result := 'Increment'
        else
          Result := '';
      end,
      Index.EventsOf('Button'),
      function(AName: string): string
      begin
        Result := '';
      end);
    Check(Inspector.PropertyText('Content') = 'Increment', 'shows the current values');
    Check(string.Join(',', Inspector.PickList('HorizontalAlignment')) = 'Left,Center,Right,Stretch', 'an enum drops down its values');
    Check(string.Join(',', Inspector.PickList('IsEnabled')) = 'True,False', 'a Boolean drops down True and False');
    Inspector.OnPropertyChange :=
      procedure(AName, AValue: string)
      begin
        Changed := AName + '=' + AValue;
      end;
    Inspector.OnEventHandler :=
      procedure(AName, AHandler: string)
      begin
        Handled := AName + '/' + AHandler;
      end;
    Inspector.CommitProperty('Content', 'Plus');
    Check(Changed = 'Content=Plus', 'an edit reaches the owner');
    Changed := '';
    Inspector.TypeValue('Content', 'Typed');
    Check(Changed = '', 'typing alone applies nothing');
    Inspector.PressKey(VK_RETURN);
    Check(Changed = 'Content=Typed', 'Enter applies the typed value (' + Changed + ')');
    Changed := '';
    Inspector.PressKey(VK_RETURN);
    Check(Changed = '', 'Enter again applies nothing new');
    Inspector.TypeValue('Content', 'Oops');
    Inspector.PressKey(VK_ESCAPE);
    Check((Changed = '') and (Inspector.PropertyText('Content') = 'Typed'), 'Escape puts the applied value back (' +
      Inspector.PropertyText('Content') + ')');
    Inspector.TypeValue('Width', '120');
    Inspector.ApplyPending;
    Check(Changed = 'Width=120', 'leaving the grid (or a new selection) applies what was typed (' + Changed + ')');
    Inspector.CommitEvent('Click');
    Check(Handled = 'Click/', 'the ... of an event reaches the owner');
    Handled := '';
    Inspector.TypeEvent('Click', 'OkClick');
    Check(Handled = 'Click/OkClick', 'a handler name typed and Enter create or find that handler (' + Handled + ')');
    Inspector.OnEventCleared :=
      procedure(AName: string)
      begin
        Handled := 'cleared ' + AName;
      end;
    Inspector.TypeEvent('Click', '');
    Check(Handled = 'cleared Click', 'an emptied event and Enter take the event off (' + Handled + ')');
    Handled := '';
    Inspector.TypeEvent('Tapped', '');
    Check(Handled = '', 'Enter on an event that had no handler does nothing');
  finally
    Host.Free;
    Index.Free;
  end;

  if Failures > 0 then
  begin
    Writeln('Designer model test FAILED (', Failures, ')');
    Halt(1);
  end;
  Writeln('Designer model test PASSED');
end.
