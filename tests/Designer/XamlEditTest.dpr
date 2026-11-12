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
  RADWinUI.Designer.Palette in '..\..\src\IDE\Designer\RADWinUI.Designer.Palette.pas',
  RADWinUI.Designer.Snap in '..\..\src\IDE\Designer\RADWinUI.Designer.Snap.pas';

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
  Guide: TSnapGuide;
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
      'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:rw="using:RADWinUI.Controls">' + NL;
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
  Same(SetAttribute('<Window x:Class="TMainWindow" Title="App">' + #10 + '  <Grid/>' + #10 + '</Window>', 1, 1,
    'WindowState', 'Maximized'), '<Window x:Class="TMainWindow" Title="App" WindowState="Maximized">' + #10 + '  <Grid/>' + #10 +
    '</Window>', 'a window attribute is written on the <Window> root');
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
  // A copied multi-selection: several elements, pasted in their order
  Value := PasteElement('<Grid><Button x:Name="Button1"/></Grid>', 1, 1, '<TextBox x:Name="A"/>'#13#10'<CheckBox x:Name="B"/>');
  Check(Value.Contains('<TextBox x:Name="A1"/>') and Value.Contains('<CheckBox x:Name="B1"/>') and
    (Value.IndexOf('TextBox') < Value.IndexOf('CheckBox')), 'paste takes several elements, in their order');
  Raised := False;
  try
    PasteElement(Xaml, 1, 1, '<Button/>text');
  except
    on EXamlEdit do Raised := True;
  end;
  Check(Raised, 'paste rejects text after the elements before changing the source');
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

  Writeln('XAML reorder');
  Value := '<Grid>' + NL + '    <Button x:Name="A"/>' + NL + '    <Button x:Name="B"/>' + NL +
    '    <Button x:Name="C" Grid.Row="1"/>' + NL + '</Grid>';
  Same(ReorderElement(Value, 2, 5, True),
    '<Grid>' + NL + '    <Button x:Name="B"/>' + NL + '    <Button x:Name="C" Grid.Row="1"/>' + NL +
    '    <Button x:Name="A"/>' + NL + '</Grid>', 'Bring to Front makes the element the last child');
  Same(ReorderElement(Value, 4, 5, False),
    '<Grid>' + NL + '    <Button x:Name="C" Grid.Row="1"/>' + NL + '    <Button x:Name="A"/>' + NL +
    '    <Button x:Name="B"/>' + NL + '</Grid>', 'Send to Back makes it the first child, Grid.Row stays');
  Check(not CanReorderElement(Value, 2, 5, False), 'the first child cannot go further back');
  Check(not CanReorderElement(Value, 4, 5, True), 'the last child cannot come further to the front');
  Check(CanReorderElement(Value, 3, 5, True) and CanReorderElement(Value, 3, 5, False), 'a middle child goes both ways');
  Check(not CanReorderElement(Value, 1, 1, True), 'the root has no siblings');
  Check(not CanReorderElement('<Window>' + NL + '<Grid/>' + NL + '</Window>', 2, 1, True),
    'the content of a Window is not reordered');
  Same(ReorderElement(Value, 2, 5, False), Value, 'a move to where it is changes nothing');

  Writeln('XAML grid rows and columns');
  Same(AddGridTrack('<Grid>' + NL + '    <Button/>' + NL + '</Grid>', 1, 1, False),
    '<Grid>' + NL + '    <Grid.RowDefinitions>' + NL + '        <RowDefinition Height="*"/>' + NL +
    '        <RowDefinition Height="*"/>' + NL + '    </Grid.RowDefinitions>' + NL + '    <Button/>' + NL + '</Grid>',
    'the first added row also writes the implicit one');
  Same(AddGridTrack('<Grid>' + NL + '    <Grid.ColumnDefinitions>' + NL + '        <ColumnDefinition Width="Auto"/>' + NL +
    '    </Grid.ColumnDefinitions>' + NL + '</Grid>', 1, 1, True),
    '<Grid>' + NL + '    <Grid.ColumnDefinitions>' + NL + '        <ColumnDefinition Width="Auto"/>' + NL +
    '        <ColumnDefinition Width="*"/>' + NL + '    </Grid.ColumnDefinitions>' + NL + '</Grid>',
    'a column goes after the existing ones');
  Same(AddGridTrack('<Grid/>', 1, 1, True),
    ('<Grid>' + NL + '    <Grid.ColumnDefinitions>' + NL + '        <ColumnDefinition Width="*"/>' + NL +
    '        <ColumnDefinition Width="*"/>' + NL + '    </Grid.ColumnDefinitions>' + NL + '</Grid>').Replace(NL, #10),
    'an empty Grid opens up for its columns (LF, like the one-line source)');
  Raised := False;
  try
    AddGridTrack('<StackPanel/>', 1, 1, False);
  except
    on EXamlEdit do
      Raised := True;
  end;
  Check(Raised, 'only a Grid gets rows');
  Raised := False;
  try
    AddGridTrack('<Grid>' + NL + '    <!-- RADWinUI Align: begin -->' + NL + '    <!-- RADWinUI Align: end -->' + NL +
      '</Grid>', 1, 1, False);
  except
    on EXamlEdit do
      Raised := True;
  end;
  Check(Raised, 'a Grid laid out by Align keeps its rows');

  Writeln('XAML items');
  Check((ItemTagOf('TabView') = 'TabViewItem') and (ItemTagOf('Button') = ''), 'items controls and their items');
  Same(AddItem('<TabView>' + NL + '    <TabViewItem Header="Tab 1"/>' + NL + '</TabView>', 1, 1),
    '<TabView>' + NL + '    <TabViewItem Header="Tab 1"/>' + NL + '    <TabViewItem Header="Tab 2"/>' + NL + '</TabView>',
    'a TabView gets Tab 2 after Tab 1');
  Value := AddItem('<NavigationView>' + NL + '    <Frame/>' + NL + '</NavigationView>', 1, 1);
  Same(Value, '<NavigationView>' + NL + '    <NavigationView.MenuItems>' + NL +
    '        <NavigationViewItem Content="Item 1"/>' + NL + '    </NavigationView.MenuItems>' + NL + '    <Frame/>' + NL +
    '</NavigationView>', 'a NavigationView gets its MenuItems before its page');
  Same(AddItem(Value, 1, 1), '<NavigationView>' + NL + '    <NavigationView.MenuItems>' + NL +
    '        <NavigationViewItem Content="Item 1"/>' + NL + '        <NavigationViewItem Content="Item 2"/>' + NL +
    '    </NavigationView.MenuItems>' + NL + '    <Frame/>' + NL + '</NavigationView>', 'the next item goes into MenuItems');
  Same(AddItem('<ComboBox Width="160"/>', 1, 1),
    ('<ComboBox Width="160">' + NL + '    <ComboBoxItem Content="Item 1"/>' + NL + '</ComboBox>').Replace(NL, #10),
    'an empty ComboBox opens up for its first item');
  Raised := False;
  try
    AddItem('<ListView ItemsSource="{x:Bind Rows}"/>', 1, 1);
  except
    on EXamlEdit do
      Raised := True;
  end;
  Check(Raised, 'items bound to an ItemsSource are not added to');

  Writeln('XAML keyboard moves');
  Same(NudgeElement('<Grid>' + NL + '    <Button Content="A" Grid.Row="1"/>' + NL + '</Grid>', 2, 5, 10, 6),
    '<Grid>' + NL + '    <Button Content="A" Grid.Row="1" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="10,6,0,0"/>' +
    NL + '</Grid>', 'in a Grid: Margin with Left/Top alignment, the row stays');
  Same(NudgeElement('<Grid>' + NL + '    <Button HorizontalAlignment="Left" VerticalAlignment="Top" Margin="10,6,0,0"/>' + NL +
    '</Grid>', 2, 5, 9, 6),
    '<Grid>' + NL + '    <Button HorizontalAlignment="Left" VerticalAlignment="Top" Margin="9,6,0,0"/>' + NL + '</Grid>',
    'a placed element only changes its Margin');
  Same(NudgeElement('<Canvas>' + NL + '    <Button Canvas.Left="4" Canvas.Top="2"/>' + NL + '</Canvas>', 2, 5, 12, 2),
    '<Canvas>' + NL + '    <Button Canvas.Left="12" Canvas.Top="2"/>' + NL + '</Canvas>', 'in a Canvas: Canvas.Left and Canvas.Top');
  Check(not CanNudgeElement('<StackPanel>' + NL + '    <Button/>' + NL + '</StackPanel>', 2, 5),
    'a StackPanel lays its children out');
  Check(not CanNudgeElement('<Window>' + NL + '<Grid/>' + NL + '</Window>', 2, 1), 'the content of a Window stays');
  Check(not CanNudgeElement('<Grid/>', 1, 1), 'the root stays');
  Check(not CanNudgeElement('<Grid>' + NL + '    <!-- RADWinUI Align: begin -->' + NL + '    <!-- RADWinUI Align: end -->' +
    NL + '    <Button/>' + NL + '</Grid>', 4, 5), 'Align lays out its Grid''s children');
  Raised := False;
  try
    NudgeElement('<StackPanel>' + NL + '    <Button/>' + NL + '</StackPanel>', 2, 5, 1, 1);
  except
    on EXamlEdit do
      Raised := True;
  end;
  Check(Raised, 'a move a panel would undo is refused');

  Writeln('Alignment guides');
  Guide := SnapAxis(TSnapRect.Create(10, 10, 50, 20), [TSnapRect.Create(12, 40, 30, 20)], True);
  Check(Guide.Found and (Guide.Delta = 2) and (Guide.At = 12) and (Guide.First = 10) and (Guide.Last = 60),
    'left edges 2 apart: a vertical line at the other''s edge, over both');
  Guide := SnapAxis(TSnapRect.Create(0, 0, 40, 10), [TSnapRect.Create(5, 30, 30, 10)], True);
  Check(Guide.Found and (Guide.Delta = 0) and (Guide.At = 20), 'centres line up where edges are too far');
  Guide := SnapAxis(TSnapRect.Create(0, 50, 10, 10), [TSnapRect.Create(0, 0, 10, 52)], False);
  Check(Guide.Found and (Guide.Delta = 2) and (Guide.At = 52), 'a top edge meets a bottom edge');
  Check(not SnapAxis(TSnapRect.Create(0, 0, 10, 10), [TSnapRect.Create(5, 20, 10, 10)], True).Found,
    'a centre does not meet an edge');
  Check(not SnapAxis(TSnapRect.Create(0, 0, 10, 10), [TSnapRect.Create(100, 100, 10, 10)], True).Found,
    'nothing within the distance, no guide');
  Guide := SnapAxis(TSnapRect.Create(10, 0, 10, 10), [TSnapRect.Create(13, 30, 10, 10), TSnapRect.Create(11, 60, 10, 10)], True);
  Check(Guide.Found and (Guide.Delta = 1), 'the closest of several wins');

  Writeln('RADWinUI controls');
  Check(ToolboxXaml('HotKey', 0, 0) = '<rw:HotKey Keys="Ctrl+Alt+T"/>', 'a RADWinUI control comes with its rw: prefix');
  Same(ApplyDesignerEvent('<Window xmlns="p" x:Class="TMainWindow">' + NL + '<Grid>' + NL + '</Grid>' + NL + '</Window>',
    'INSERT NotchPanel 2 1 0 -1 -1'),
    '<Window xmlns:rw="using:RADWinUI.Controls" xmlns="p" x:Class="TMainWindow">' + NL + '<Grid>' + NL +
    '    <rw:NotchPanel x:Name="NotchPanel1"/>' + NL + '</Grid>' + NL + '</Window>',
    'INSERT of a RADWinUI control declares xmlns:rw on the root, named NotchPanel1');
  Same(EnsureNamespace('<Window xmlns:rw="using:RADWinUI.Controls">', 'rw', 'using:RADWinUI.Controls'),
    '<Window xmlns:rw="using:RADWinUI.Controls">', 'xmlns:rw is declared once');
  Check(PaletteCategoryOf('GlowTile') = 'Overlay', 'GlowTile is in Overlay');
  Check(PaletteCategoryOf('SlideButton') = 'Action Buttons', 'SlideButton is in Action Buttons');
  Check((PaletteCategoryOf('DBGrid') = 'Data Controls') and (PaletteCategoryOf('DBToggleSwitch') = 'Data Controls'),
    'DBGrid and DBToggleSwitch are in Data Controls');
  Check(PaletteXamlTag('DBEdit') = 'rw:DBEdit', 'a data control is written with rw:');
  Check(ToolboxXaml('DBEdit', 0, 0) = '<rw:DBEdit DataSource="" DataField=""/>',
    'a data control comes with DataSource and DataField to fill in');
  Check(ToolboxXaml('SendButton', 0, 0) = '<rw:SendButton Text="Send"/>',
    'an action button comes with its rw: prefix and its label');
  if Failures > 0 then
  begin
    Writeln('XAML edit test FAILED (', Failures, ')');
    Halt(1);
  end;
  Writeln('XAML edit test PASSED');
end.
