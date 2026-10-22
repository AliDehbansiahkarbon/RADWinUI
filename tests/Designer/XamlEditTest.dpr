program XamlEditTest;

{
  Checks RADWinUI.Designer.XamlEdit. scripts\Test-Preview.ps1 runs it,
  and also uses it to edit a file the preview shows:

    XamlEditTest set <file> <line> <column> <attribute> <value>
    XamlEditTest apply <file> "<INSERT, MOVE or DELETE event of the preview>"
    XamlEditTest palette-xaml <file>   (a window with every Tool Palette control, as inserted)
}

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  RADWinUI.Designer.XamlEdit in '..\..\src\IDE\Designer\RADWinUI.Designer.XamlEdit.pas',
  RADWinUI.Designer.Palette in '..\..\src\IDE\Designer\RADWinUI.Designer.Palette.pas';

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

procedure Same(const AActual, AExpected, AWhat: string);
begin
  Check(AActual = AExpected, AWhat);
  if AActual <> AExpected then
    Writeln('    expected: ', AExpected.Replace(#13#10, '\n'), sLineBreak, '    actual:   ', AActual.Replace(#13#10, '\n'));
end;

const
  NL = #13#10;
  Xaml =
    '<StackPanel Spacing="16">' + NL +                                      // line 1
    '    <!-- the counter -->' + NL +                                       // line 2
    '    <TextBlock x:Name="CounterText" Text=''0'' FontSize="32"/>' + NL + // line 3
    '    <Button x:Name="IncrementButton"' + NL +                           // line 4
    '            Content="Increment"/>' + NL +                              // line 5
    '    <Button>Plain</Button>' + NL +                                     // line 6
    '</StackPanel>';

var
  Value: string;
  Raised: Boolean;
  Entry: TPaletteEntry;
begin
  if (ParamCount = 6) and (ParamStr(1) = 'set') then
  begin
    TFile.WriteAllText(ParamStr(2), SetAttribute(TFile.ReadAllText(ParamStr(2), TEncoding.UTF8),
      StrToInt(ParamStr(3)), StrToInt(ParamStr(4)), ParamStr(5), ParamStr(6)), TEncoding.UTF8);
    Exit;
  end;
  if (ParamCount = 2) and (ParamStr(1) = 'palette-xaml') then
  begin
    // Every curated control as the palette inserts it, in one StackPanel: the
    // preview must load it (Test-Preview.ps1)
    Value := '<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
      'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' + NL;
    for Entry in PaletteEntries do
      Value := Value + '    ' + ToolboxXaml(Entry.Name, 0, 0) + NL;
    TFile.WriteAllText(ParamStr(2), Value + '</StackPanel>', TEncoding.UTF8);
    Exit;
  end;
  if (ParamCount = 3) and (ParamStr(1) = 'apply') then
  begin
    TFile.WriteAllText(ParamStr(2), ApplyDesignerEvent(TFile.ReadAllText(ParamStr(2), TEncoding.UTF8), ParamStr(3)),
      TEncoding.UTF8);
    Exit;
  end;
  Writeln('XAML edit');
  Same(SetAttribute(Xaml, 3, 5, 'FontSize', '40'), Xaml.Replace('FontSize="32"', 'FontSize="40"'),
    'replaces a value in place');
  Same(SetAttribute(Xaml, 3, 5, 'Text', 'It''s'), Xaml.Replace('Text=''0''', 'Text=''It&apos;s'''),
    'keeps the quote style and escapes the value');
  Same(SetAttribute(Xaml, 4, 5, 'Width', '120'),
    Xaml.Replace('Content="Increment"/>', 'Content="Increment"' + NL + '            Width="120"/>'),
    'adds to a multi-line tag on its own aligned line');
  Same(SetAttribute(Xaml, 6, 5, 'Width', 'a<b&"c"'), Xaml.Replace('<Button>Plain', '<Button Width="a&lt;b&amp;&quot;c&quot;">Plain'),
    'adds to a tag without attributes, escaped');
  Same(SetAttribute(Xaml, 1, 1, 'Padding', '8'), Xaml.Replace('Spacing="16">', 'Spacing="16" Padding="8">'),
    'adds after the last attribute on one line');
  Same(RemoveAttribute(Xaml, 3, 5, 'FontSize'), Xaml.Replace(' FontSize="32"', ''), 'removes an attribute');
  Same(RemoveAttribute(Xaml, 4, 5, 'Content'), Xaml.Replace(NL + '            Content="Increment"', ''),
    'removes an attribute on its own line');
  Same(RemoveAttribute(Xaml, 3, 5, 'Missing'), Xaml, 'removing a missing attribute changes nothing');
  Check(GetAttribute(SetAttribute(Xaml, 6, 5, 'Tag', 'a<b&"c"'), 6, 5, 'Tag', Value) and (Value = 'a<b&"c"'),
    'reads back what it wrote');
  Check(not GetAttribute(Xaml, 6, 5, 'Tag', Value), 'a missing attribute reads as False');
  Raised := False;
  try
    SetAttribute(Xaml, 2, 5, 'Width', '1'); // a comment, not a start tag
  except
    on EXamlEdit do
      Raised := True;
  end;
  Check(Raised, 'refuses a position that is not a start tag');
  Raised := False;
  try
    SetAttribute(Xaml, 3, 5, 'Bad Name', '1');
  except
    on EXamlEdit do
      Raised := True;
  end;
  Check(Raised, 'refuses an attribute name that is not a name');

  Writeln('XAML structure edits');
  Same(CopyElement(Xaml, 4, 5), '<Button x:Name="IncrementButton"' + NL +
    '            Content="Increment"/>', 'copy keeps the selected element text');
  Value := PasteElement(Xaml, 4, 5, CopyElement(Xaml, 4, 5));
  Check(Value.Contains('x:Name="IncrementButton1"') and Value.Contains('x:Name="IncrementButton"'),
    'paste keeps the original and assigns a unique name to the clone');
  Value := PasteElement('<Grid><Button x:Name="Button1"/></Grid>', 1, 7,
    '<StackPanel x:Name="Panel1"><Button x:Name="Button1" Click="SharedClick"/></StackPanel>');
  Check(Value.Contains('x:Name="Button2" Click="SharedClick"') and Value.Contains('x:Name="Panel2"'),
    'paste renames descendants, keeps handlers, and permits a Grid root');
  Raised := False;
  try
    PasteElement(Xaml, 1, 1, '<Button/><Button/>');
  except
    on EXamlEdit do Raised := True;
  end;
  Check(Raised, 'paste rejects multiple clipboard roots before changing the source');
  Same(DeleteElement(Xaml, 4, 5), Xaml.Replace('    <Button x:Name="IncrementButton"' + NL + '            Content="Increment"/>' + NL, ''),
    'deletes a multi-line element with its lines');
  Same(DeleteElement(Xaml, 6, 5), Xaml.Replace('    <Button>Plain</Button>' + NL, ''), 'deletes an element with content');
  Same(InsertChild(Xaml, 1, 1, 0, '<A/>'), Xaml.Replace('    <TextBlock', '    <A/>' + NL + '    <TextBlock'),
    'inserts before the first child, on its own line, indented like it');
  Same(InsertChild(Xaml, 1, 1, 99, '<A/>'), Xaml.Replace('Plain</Button>', 'Plain</Button>' + NL + '    <A/>'),
    'appends after the last child');
  Same(InsertChild('<Grid>' + NL + '    <StackPanel Spacing="8"/>' + NL + '</Grid>', 2, 5, 0, '<A/>'),
    '<Grid>' + NL + '    <StackPanel Spacing="8">' + NL + '        <A/>' + NL + '    </StackPanel>' + NL + '</Grid>',
    'opens a self-closing panel');
  Same(InsertChild('<Grid>' + NL + '    <Grid.RowDefinitions><RowDefinition/></Grid.RowDefinitions>' + NL + '</Grid>', 1, 1, 0, '<A/>'),
    '<Grid>' + NL + '    <Grid.RowDefinitions><RowDefinition/></Grid.RowDefinitions>' + NL + '    <A/>' + NL + '</Grid>',
    'property elements are not children');
  Same(MoveElement(Xaml, 6, 5, 1, 1, 0, -1, -1), Xaml.Replace('    <Button>Plain</Button>' + NL, '')
    .Replace('    <TextBlock', '    <Button>Plain</Button>' + NL + '    <TextBlock'), 'moves an element up');
  Same(MoveElement(Xaml, 3, 5, 1, 1, 3, -1, -1), Xaml.Replace('    <TextBlock x:Name="CounterText" Text=''0'' FontSize="32"/>' + NL, '')
    .Replace('Plain</Button>', 'Plain</Button>' + NL + '    <TextBlock x:Name="CounterText" Text=''0'' FontSize="32"/>'),
    'moves an element down (the index counts it in its old place)');
  Same(MoveElement('<Grid>' + NL + '    <Button Content="A"/>' + NL + '</Grid>', 2, 5, 1, 1, 0, 1, 2),
    '<Grid>' + NL + '    <Button Content="A" Grid.Row="1" Grid.Column="2"/>' + NL + '</Grid>', 'a move in a Grid sets Row and Column');
  Same(ApplyDesignerEvent(Xaml, 'INSERT CheckBox 1 1 1 -1 -1'), Xaml.Replace('    <Button x:Name',
    '    <CheckBox Content="CheckBox" x:Name="CheckBox1"/>' + NL + '    <Button x:Name'), 'INSERT puts a toolbox item at its place');
  Same(ApplyDesignerEvent(Xaml, 'DELETE 6 5'), DeleteElement(Xaml, 6, 5), 'DELETE deletes');
  Check(ToolboxXaml('Grid', 1, 0) = '<Grid MinHeight="80" Grid.Row="1"/>', 'a toolbox item in a Grid row');
  Check(ToolboxXaml('AutoSuggestBox', 0, 0) = '<AutoSuggestBox/>', 'a generated palette control gets XAML');
  Raised := False;
  try
    MoveElement(Xaml, 1, 1, 4, 5, 0, -1, -1);
  except
    on EXamlEdit do
      Raised := True;
  end;
  Check(Raised, 'refuses to move an element into itself');

  Writeln('XAML free placement');
  Same(ApplyDesignerEvent('<Grid>' + NL + '    <Button Content="A"/>' + NL + '</Grid>', 'PLACE 2 5 1 1 Grid 0 0 40 24'),
    '<Grid>' + NL + '    <Button Content="A" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="40,24,0,0"/>' + NL + '</Grid>',
    'PLACE in its Grid writes Margin and Left/Top alignment in place');
  Same(ApplyDesignerEvent('<Grid>' + NL + '    <Button Content="A" Grid.Row="1" Margin="1,2,0,0"/>' + NL + '</Grid>',
    'PLACE 2 5 1 1 Grid 0 2 5 6'),
    '<Grid>' + NL + '    <Button Content="A" Margin="5,6,0,0" Grid.Column="2" HorizontalAlignment="Left" VerticalAlignment="Top"/>' + NL + '</Grid>',
    'PLACE in another cell: Grid.Row 0 goes, Grid.Column and Margin change');
  Same(ApplyDesignerEvent('<StackPanel>' + NL + '    <Button Content="A"/>' + NL + '    <Canvas/>' + NL + '</StackPanel>',
    'PLACE 2 5 3 5 Canvas -1 -1 10 20'),
    '<StackPanel>' + NL + '    <Canvas>' + NL + '        <Button Content="A" Canvas.Left="10" Canvas.Top="20"/>' + NL + '    </Canvas>' + NL + '</StackPanel>',
    'PLACE into a Canvas moves the element there with Canvas.Left and Canvas.Top');
  Same(ApplyDesignerEvent('<Grid>' + NL + '</Grid>', 'INSERTAT TextBlock 1 1 Grid 0 0 12 8'),
    '<Grid>' + NL + '    <TextBlock Text="TextBlock" x:Name="TextBlock1" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="12,8,0,0"/>' + NL + '</Grid>',
    'INSERTAT puts a toolbox item where it was dropped');
  if Failures > 0 then
  begin
    Writeln('XAML edit test FAILED (', Failures, ')');
    Halt(1);
  end;
  Writeln('XAML edit test PASSED');
end.
