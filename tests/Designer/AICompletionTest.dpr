program AICompletionTest;

{
  Checks RADWinUI.Designer.AICompletion, Complete XAML with AI and suggestions
  while typing, with a fake AI engine in place of the IDE's (ToolsAPI.AI) and a
  fake clock, and the XAML comment toggle of RADWinUI.Designer.XamlEdit:

    AICompletionTest

  scripts\Test-Preview.ps1 runs it.
}

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.SysUtils,
  System.IOUtils,
  RADWinUI.Designer.XamlEdit in '..\..\src\IDE\Designer\RADWinUI.Designer.XamlEdit.pas',
  RADWinUI.Designer.PaletteIcons in '..\..\src\IDE\Designer\RADWinUI.Designer.PaletteIcons.pas',
  RADWinUI.Designer.Palette in '..\..\src\IDE\Designer\RADWinUI.Designer.Palette.pas',
  RADWinUI.Designer.Model in '..\..\src\IDE\Designer\RADWinUI.Designer.Model.pas',
  RADWinUI.Designer.AICompletion in '..\..\src\IDE\Designer\RADWinUI.Designer.AICompletion.pas',
  RADWinUI.Designer.Vision in '..\..\src\IDE\Designer\RADWinUI.Designer.Vision.pas',
  RADWinUI.Designer.Settings in '..\..\src\IDE\Designer\RADWinUI.Designer.Settings.pas',
  System.Win.Registry;

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

type
  // Stands in for IOTAAIPlugin.Chat: records the prompt, answers with a fixed text
  TFakeEngine = class
    Prompt, Reply: string;
    function Chat(const AQuestion: string): string;
  end;

function TFakeEngine.Chat(const AQuestion: string): string;
begin
  Prompt := AQuestion;
  Result := Reply;
end;

const
  Window =
    '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"'#13#10 +
    '        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"'#13#10 +
    '        xmlns:local="using:Demo" x:Class="TMainWindow" Title="Demo">'#13#10 +
    '    <StackPanel x:Name="Root">'#13#10 +
    '        <TextBox x:Name="NameBox"/>'#13#10 +
    '        '#13#10 +
    '    </StackPanel>'#13#10 +
    '</Window>'#13#10;

procedure CheckSuggestions;
const
  Before = '<StackPanel>'#13#10'    <Butt';
  After = #13#10'</StackPanel>';
var
  S: TXamlSuggestions;
  Clock: UInt64;
  Text, NewText: string;
  NewCursor: Integer;
  ID1, ID2: TGUID;
begin
  Writeln('Where suggestions appear');
  Check(IsXamlLineIncomplete('    <Butt', 9), 'after "<Butt"');
  Check(IsXamlLineIncomplete('    <Button Cont', 16), 'after "<Button Cont"');
  Check(IsXamlLineIncomplete('    <Button Content="Sa', 23), 'in an unfinished attribute value');
  Check(IsXamlLineIncomplete('    <Button Content="Sa"/>', 23), 'before the closing quote and "/>"');
  Check(not IsXamlLineIncomplete('    ', 4), 'not on an empty line');
  Check(not IsXamlLineIncomplete('    <Button/>', 13), 'not after a complete element');
  Check(not IsXamlLineIncomplete('    <Button/>  <Grid/>', 6), 'not in the middle of finished text');
  Check(not IsXamlLineIncomplete('    <!-- note', 13), 'not in a comment');
  Check(not IsXamlLineIncomplete('    <', 5), 'not after a bare "<"');

  Writeln('Suggestions while typing');
  S := TXamlSuggestions.Create(250);
  try
    Clock := 1000;
    Text := Before + After;
    S.Observe(Text, Length(Before), Clock); // the editor as it was when it came to the front
    Check(not S.Due(Clock + 5000), 'no request before an edit');

    // Typing on an incomplete line: one request after the pause
    Text := Before + 'o' + After;
    S.Observe(Text, Length(Before) + 1, Clock + 10);
    Check(not S.Due(Clock + 200), 'debounce: no request 190 ms after the last key');
    Text := Before + 'on' + After;
    S.Observe(Text, Length(Before) + 2, Clock + 100);
    Check(not S.Due(Clock + 300), 'debounce: each key starts the pause again');
    Check(S.Due(Clock + 350), 'a request 250 ms after the last key');
    Check((S.RequestText = Text) and (S.RequestCursor = Length(Before) + 2), 'the request is for the text at the pause');
    ID1 := TGUID.NewGuid;
    S.Sent(ID1, Clock + 350);
    Check(not S.Due(Clock + 5000), 'one request in flight');
    Check(not S.Answered(TGUID.NewGuid, 'x'), 'an answer to another request is ignored');
    // The answer repeats the typed "<Button" and has a second line: the rest of this line only
    Check(S.Answered(ID1, '<Button Content="Save" Click="SaveClick"/>'#13#10'<Button/>') and
      (S.Ghost = ' Content="Save" Click="SaveClick"/>'), 'the rest of the line, without what it already has');

    // Typing what the ghost text shows consumes it
    Text := Before + 'on C' + After;
    Check(S.Observe(Text, Length(Before) + 4, Clock + 1000) and (S.Ghost = 'ontent="Save" Click="SaveClick"/>'),
      'typing the next characters keeps the rest');
    Check(not S.Due(Clock + 3000), 'typing that matches asks nothing');
    // Deleting back into the suggestion shows it again at once
    Text := Before + 'o' + After;
    Check(S.Observe(Text, Length(Before) + 1, Clock + 1100) and (S.Ghost = 'n Content="Save" Click="SaveClick"/>'),
      'a backspace shows the answer for the line again, without a request');
    Check(not S.Due(Clock + 3000), 'and asks nothing');

    // Tab
    Check(S.Accept(NewText, NewCursor) and (NewText = Before + 'on Content="Save" Click="SaveClick"/>' + After) and
      (NewCursor = Length(Before + 'on Content="Save" Click="SaveClick"/>')), 'Tab inserts the rest, cursor after it');
    Check(S.Ghost = '', 'no ghost text after Tab');
    Check(not S.Observe(NewText, NewCursor, Clock + 1200) and not S.Due(Clock + 5000), 'the accepted text asks nothing');

    // A complete line asks nothing
    S.Observe(NewText + ' ', NewCursor + 1, Clock + 6000);
    Check(not S.Due(Clock + 7000), 'typing after a complete element asks nothing');

    // An answer that comes after the user typed on: shown when the line leads to it
    Text := '<Grid>'#13#10'  <TextBl';
    S.Observe(Text + After, Length(Text), Clock + 8000);
    Check(S.Due(Clock + 8300), 'a request for "<TextBl"');
    ID2 := TGUID.NewGuid;
    S.Sent(ID2, Clock + 8300);
    S.Observe(Text + 'o' + After, Length(Text) + 1, Clock + 8400); // typed on before the answer
    Check(S.Answered(ID2, 'ock Text="Name"/>') and (S.Ghost = 'ck Text="Name"/>'),
      'a late answer still fits the line: shown at once');
    S.Observe(Text + 'ox' + After, Length(Text) + 2, Clock + 8500);
    Check(S.Ghost = '', 'typing something else dismisses it');
    Check(S.Due(Clock + 8800), 'and asks again');
    S.Sent(TGUID.NewGuid, Clock + 8800);
    Check(not S.Due(Clock + 8800 + TXamlSuggestions.Timeout - 1), 'waits for the answer');
    S.Observe(Text + 'oxy' + After, Length(Text) + 3, Clock + 8900);
    Check(S.Due(Clock + 8900 + TXamlSuggestions.Timeout + 1), 'an answer that never comes is given up');

    // Esc and a cursor move dismiss
    S.Observe(Before + 'on' + After, Length(Before) + 2, Clock + 50000);
    Check(S.Ghost = ' Content="Save" Click="SaveClick"/>', 'the same place again: the earlier answer at once');
    S.Dismiss;
    Check(S.Ghost = '', 'Esc dismisses');
    S.Observe(Before + 'o' + After, Length(Before) + 1, Clock + 50100);
    Check(S.Ghost <> '', 'shown again after an edit');
    Check(S.Observe(Before + 'o' + After, Length(Before), Clock + 50200) and (S.Ghost = ''), 'a cursor move dismisses');
    Check(not S.Due(Clock + 60000), 'a cursor move asks nothing');

    // Fitting answers
    Check(FitXamlSuggestion('    ', 4, '    <Grid/>') = '<Grid/>', 'in the indentation, the answer''s indentation goes');
    Check(FitXamlSuggestion('<A', 2, '```xml'#13#10'1'#13#10'2'#13#10'3'#13#10'4'#13#10'5'#13#10'6'#13#10'7'#13#10'8'#13#10'9'#13#10'```') =
      '1'#13#10'2'#13#10'3'#13#10'4'#13#10'5'#13#10'6'#13#10'7'#13#10'8', 'at most 8 lines');
  finally
    S.Free;
  end;
end;

/// Answers as chat models give them, replayed through fitting and the vocabulary check.
procedure CheckAnswers;
var
  Index: TDesignerTypeIndex;
  Vocabulary: IXamlVocabulary;
  S: TXamlSuggestions;
  Ghost: TXamlGhost;
  Text, NewText, Reason: string;
  NewCursor: Integer;
  ID: TGUID;

  // The text with the cursor at '|', the engine's raw answer: what Tab writes, or '' when nothing is offered
  function Replay(const AText, AAnswer: string): string;
  var
    Cursor: Integer;
    Xaml, Suggestion: string;
  begin
    Cursor := AText.IndexOf('|');
    Xaml := AText.Replace('|', '');
    Suggestion := FitXamlSuggestion(Xaml, Cursor, AAnswer);
    if (Suggestion = '') or not CorrectXamlSuggestion(Xaml, Cursor, Suggestion, Vocabulary, Ghost) then
      Exit('');
    Result := ApplyXamlGhost(Xaml, Cursor, Ghost);
  end;

begin
  Writeln('AI answers, checked against the XAML metadata');
  Index := TDesignerTypeIndex.Create(TPath.Combine(ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..'),
    'src\Generated\RADWinUI.Xaml.json'));
  try
    Vocabulary := TIndexVocabulary.Create(Index, ['local:PersonCard']);
    Check(Index.ExactTag('button') = 'Button', 'the metadata spells button as Button');
    Check(Index.ExactTag('rw:sendbutton') = 'rw:SendButton', 'and rw:sendbutton as rw:SendButton');
    Check(Index.ExactMember('Button', 'content') = 'Content', 'and content of a Button as Content');

    // What gpt-5 sent for "remove all controls, keep the tab bar, a focus timer in the search tab"
    // with a screenshot: the whole file. Its xmlns= on the root was taken for an unknown attribute.
    Text := '<Window xmlns:rw="using:RADWinUI.Controls"'#10 +
      '    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"'#10 +
      '    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"'#10 +
      '    xmlns:d="http://schemas.microsoft.com/expression/blend/2008"'#10 +
      '    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"'#10 +
      '    mc:Ignorable="d" x:Class="TMainWindow" Title="RADWinUI Application" Width="480" Height="320"'#10 +
      '    DataContextType="TMainViewModel">'#10 +
      '    <Grid Background="{ThemeResource ApplicationPageBackgroundThemeBrush}" x:Name="Grid1">'#10 +
      '        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>'#10 +
      '        <!-- Tab bar kept -->'#10 +
      '        <rw:SlidingPillTabBar x:Name="SlidingPillTabBar2" Items="Home:Home, Search:Search"/>'#10 +
      '        <Grid Grid.Row="1">'#10 +
      '            <TextBlock x:Name="TimeDisplayText" FontSize="48" Text="25:00"/>'#10 +
      '            <ProgressBar x:Name="TimerProgressBar" Minimum="0" Maximum="1500" Value="0"/>'#10 +
      '            <NumberBox x:Name="MinutesNumberBox" Header="Minutes" Minimum="1" Maximum="180" Value="25"/>'#10 +
      '            <ToggleButton x:Name="StartPauseButton" Content="Start"/>'#10 +
      '            <ToggleSwitch x:Name="AutoStartToggle" Header="Auto-start next session"/>'#10 +
      '        </Grid>'#10 +
      '    </Grid>'#10 +
      '</Window>';
    Check(CorrectXamlSuggestion('', 0, Text, Vocabulary, Ghost, Reason) and (Reason = '') and (Ghost.Text = Text),
      'a whole Window with its xmlns declarations passes the check (' + Reason + ')');
    Check(IsWholeXamlFile('<?xml version="1.0"?>'#13#10'<Window x:Class="TMainWindow" Title="A">'#13#10 +
      '  <StackPanel/>'#13#10'</Window>', Text), 'and is a whole new version of the window');
    Check(not IsWholeXamlFile('<Window x:Class="TOtherWindow"><Grid/></Window>', Text),
      'not for another x:Class');
    Check(not IsWholeXamlFile('<Window x:Class="TMainWindow"><Grid/></Window>', '<Grid><Button/></Grid>'),
      'a block is placed, not taken for the file');
    Check(not IsWholeXamlFile('<Window x:Class="TMainWindow"><Grid/></Window>', '<Window x:Class="TMainWindow">'),
      'a cut-off answer is no whole file');
    Check(not CorrectXamlSuggestion('', 0, '<StackPanel><Buton Content="x"/></StackPanel>', Vocabulary, Ghost, Reason)
      and (Reason = '<Buton>'), 'the error names the unknown element (' + Reason + ')');
    Check(not CorrectXamlSuggestion('', 0, '<Button content2="x"/>', Vocabulary, Ghost, Reason) and
      (Reason = 'content2 on <Button>'), 'and the unknown attribute (' + Reason + ')');

    // What Ali saw: typed "<butt", the answer "<button Content="Button"/>"
    Check(Replay('<StackPanel>'#13#10'    <butt|'#13#10'</StackPanel>', '<button Content="Button"/>') =
      '<StackPanel>'#13#10'    <Button Content="Button"/>'#13#10'</StackPanel>', '"<butt" + Tab writes <Button>, typed part corrected');
    Check(Replay('<StackPanel>'#13#10'    <Button|'#13#10'</StackPanel>',
      '<button Content="More" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="32,540,0,0"/>') =
      '<StackPanel>'#13#10'    <Button Content="More" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="32,540,0,0"/>' +
      #13#10'</StackPanel>', '"<Button" + "<button ..." is not repeated, and stays <Button');
    Check(Replay('<Grid>'#13#10'  <TextBl|'#13#10'</Grid>', 'ock Text="Name"/>') =
      '<Grid>'#13#10'  <TextBlock Text="Name"/>'#13#10'</Grid>', '"<TextBl" + "ock ..." is a TextBlock');
    Check(Replay('<Grid>'#13#10'  <rw:Send|'#13#10'</Grid>', 'Button x:Name="SendButton" Text="Send"/>') =
      '<Grid>'#13#10'  <rw:SendButton x:Name="SendButton" Text="Send"/>'#13#10'</Grid>', '"<rw:Send" + "Button ..." is rw:SendButton');
    Check(Replay('<Grid>'#13#10'  <rw:send|'#13#10'</Grid>', '<rw:sendbutton text="Send"/>') =
      '<Grid>'#13#10'  <rw:SendButton Text="Send"/>'#13#10'</Grid>', 'an rw: control and its property in lower case are corrected');
    Check(Replay('<Grid>'#13#10'  <Butt|'#13#10'</Grid>', 'on content="Save" click="SaveClick"/>') =
      '<Grid>'#13#10'  <Button Content="Save" Click="SaveClick"/>'#13#10'</Grid>', 'attribute and event names are corrected');
    Check(Replay('<Grid>'#13#10'  <Butt|'#13#10'</Grid>', 'on Style="{StaticResource AccentButtonStyle}"/>') <> '',
      'a PascalCase attribute the metadata does not list is kept');
    Check(Replay('<Grid>'#13#10'  |'#13#10'</Grid>', '<buton Content="Save"/>') = '', 'an unknown element is not offered');
    Check(Replay('<Grid>'#13#10'  <Butt|'#13#10'</Grid>', 'on onklick="Save"/>') = '', 'an unknown lower-case attribute is not offered');
    Check(Replay('<Grid>'#13#10'  |'#13#10'</Grid>', '<grid.RowDefinitions><rowdefinition Height="Auto"/></grid.RowDefinitions>') =
      '<Grid>'#13#10'  <Grid.RowDefinitions><RowDefinition Height="Auto"/></Grid.RowDefinitions>'#13#10'</Grid>',
      'property elements and their content are corrected');
    Check(Replay('<Grid>'#13#10'  |'#13#10'</Grid>', '<local:personcard/>') = '<Grid>'#13#10'  <local:PersonCard/>'#13#10'</Grid>',
      'a user control of the project');
    Check(Replay('<Grid>'#13#10'  <Butt|'#13#10'</Grid>', 'on rw:Name="B" Content="OK"/>') = '',
      'an attribute with another prefix than x:, d:, mc: or xmlns: (rw:Name=) is not offered');
    Check(Replay('<Grid>'#13#10'  <TextBox x:Name="A" |'#13#10'</Grid>', 'placeholderText="Name"/>') =
      '<Grid>'#13#10'  <TextBox x:Name="A" PlaceholderText="Name"/>'#13#10'</Grid>', 'an attribute after others in the typed tag');

    // The state machine with the vocabulary: Tab writes the corrected typed part too
    S := TXamlSuggestions.Create(500);
    try
      S.Vocabulary := Vocabulary;
      Text := '<StackPanel>'#13#10'    <butt';
      S.Observe(Copy(Text, 1, Length(Text) - 1) + #13#10'</StackPanel>', Length(Text) - 1, 0);
      S.Observe(Text + #13#10'</StackPanel>', Length(Text), 10);
      Check(S.Due(600), 'a request');
      ID := TGUID.NewGuid;
      S.Sent(ID, 600);
      Check(S.Answered(ID, '<button Content="Save"/>') and (S.Ghost = 'on Content="Save"/>'), 'the ghost text is the rest');
      Check(S.Accept(NewText, NewCursor) and (NewText = '<StackPanel>'#13#10'    <Button Content="Save"/>'#13#10'</StackPanel>'),
        'Tab writes <Button Content="Save"/>');
      Text := Copy(NewText, 1, NewCursor) + #13#10'    <Buto';
      S.Observe(Text + Copy(NewText, NewCursor + 1, MaxInt), Length(Text), 2000);
      Check(S.Due(2600), 'another request');
      ID := TGUID.NewGuid;
      S.Sent(ID, 2600);
      Check(not S.Answered(ID, '<buton/>') and (S.Ghost = ''), 'an answer with an unknown element shows nothing');
    finally
      S.Free;
    end;

    // The prompt
    Text := BuildXamlSuggestion('<Grid>'#13#10'    <Butt'#13#10'</Grid>', 17, ['local:ButtonBar']);
    Check(Text.Contains('The line so far: "<Butt"'), 'the prompt quotes the typed line');
    Check(Text.Contains('case-sensitive') and Text.Contains('never <button>'), 'the prompt says XAML is case-sensitive');
    Check(Text.Contains('"<Butt" -> on Content="Save"'), 'with examples');
    Check(Text.Contains('No Margin or alignment offsets'), 'and no designer positioning');
    Check(Text.Contains('Elements that fit: Button, local:ButtonBar.'), 'only the elements whose names fit "<Butt"');
    Check(Length(Text) < 1500, Format('the prompt is short (%d characters)', [Length(Text)]));
  finally
    Index.Free;
  end;
end;

procedure CheckCreate;
const
  Win =
    '<Window x:Class="TMainWindow">'#13#10 +
    '    <StackPanel x:Name="Root">'#13#10 +
    '        <TextBlock Text="Hi"/>'#13#10 +
    '        '#13#10 +
    '    </StackPanel>'#13#10 +
    '</Window>';
  Form = '<StackPanel Spacing="8">'#10'  <TextBox x:Name="EmailBox" Header="Email"/>'#10'  <Button Content="Sign in"/>'#10'</StackPanel>';
var
  Text: string;
  Cursor, At: Integer;
begin
  Writeln('Create XAML with AI');
  Text := BuildXamlFromDescription(Win, Win.IndexOf('        '#13#10'    </') + 8, 'a login form', nil);
  Check(Text.Contains('The user asks: a login form'), 'the prompt has the description');
  Check(Text.Contains('<Window>') and Text.Contains('Names in use: Root.') and Text.Contains('rw:SendButton'),
    'the root, the names in use and the controls');
  Check(Text.Contains('never with absolute Margin positions') and Text.Contains('no event attributes'),
    'layout and event rules');
  Check(Text.Contains('1. The request only adds UI') and Text.Contains('2. The request removes, moves, restyles') and
    Text.Contains('Copy the root start tag exactly'), 'the two answer forms: a block, or the whole file');
  // gpt-5 wrote <rw:FloatingNotchTabBarItem> children: the prompt now says how the tab bars are written
  Check(Text.Contains('there is no <rw:...Item>') and Text.Contains('rw:FloatingNotchTabBar (a floating ball') and
    Text.Contains('Items="Label:Icon, Label:Icon"') and Text.Contains('Pages="HomePage, SearchPage"'),
    'the RADWinUI controls, how they are written and what they look like');
  Check(Text.Contains('not WinUI''s TabView'), 'and a tab bar is not a TabView');
  Check(Text.Contains('<TextBlock Text="Hi"/>'#13#10'        ' + XamlCursorMarker), 'the file with the cursor');

  // On the empty, indented line: at the cursor, the block's lines indented like it
  At := Win.IndexOf('        '#13#10'    </') + 8;
  Text := PlaceXamlBlock(Win, At, At, Form, Cursor);
  Check(Text.Contains(#13#10'        <StackPanel Spacing="8">'#13#10'          <TextBox x:Name="EmailBox" Header="Email"/>' +
    #13#10'          <Button Content="Sign in"/>'#13#10'        </StackPanel>'#13#10'    </StackPanel>'),
    'at the cursor in the indentation, re-indented, CRLF');
  Check(Copy(Text, Cursor - 12, 13) = '</StackPanel>', 'the cursor after the block');
  // After text on a line that opens an element: below it, one level deeper
  At := Win.IndexOf('<StackPanel x:Name="Root">') + 26;
  Text := PlaceXamlBlock(Win, At, At, '<Button/>', Cursor);
  Check(Text.Contains('<StackPanel x:Name="Root">'#13#10'        <Button/>'#13#10'        <TextBlock'),
    'after an opening tag: its first child');
  At := Win.IndexOf('<TextBlock Text="Hi"/>') + 22;
  Text := PlaceXamlBlock(Win, At, At, '<Button/>', Cursor);
  Check(Text.Contains('<TextBlock Text="Hi"/>'#13#10'        <Button/>'#13#10), 'after an element: below it, same level');
  // A selection is replaced
  At := Win.IndexOf('<TextBlock Text="Hi"/>');
  Text := PlaceXamlBlock(Win, At, At + 22, '<Button/>', Cursor);
  Check(Text.Contains('        <Button/>'#13#10'        '#13#10) and not Text.Contains('TextBlock'), 'a selection is replaced');
  Check(PlaceXamlBlock(Win, 3, 3, ''#13#10'  '#13#10, Cursor) = Win, 'an empty block changes nothing');
  // As ChatGPT sent it: the first line flush, the others indented for its own idea of the file
  At := Win.IndexOf('<TextBlock Text="Hi"/>') + 22;
  Text := PlaceXamlBlock(Win, At, At, '<A/>'#10'            <B/>'#10'            <C/>', Cursor);
  Check(Text.Contains('<TextBlock Text="Hi"/>'#13#10'        <A/>'#13#10'        <B/>'#13#10'        <C/>'#13#10),
    'a first line flush and the others indented: one level, like the line above');
end;

procedure CheckMultiSelection;
const
  Xaml =
    '<Window x:Class="TW">'#13#10 +
    '    <Grid>'#13#10 +
    '        <Button x:Name="A" Content="A"/>'#13#10 +
    '        <Button x:Name="B" Content="B"/>'#13#10 +
    '        <StackPanel>'#13#10 +
    '            <TextBlock Text="C"/>'#13#10 +
    '        </StackPanel>'#13#10 +
    '    </Grid>'#13#10 +
    '</Window>';
var
  Text: string;
  Moves: TArray<TXamlNudge>;
begin
  Writeln('Designer multi-selection');
  Text := DeleteElements(Xaml, [TXamlPosition.Create(3, 9), TXamlPosition.Create(4, 9)]);
  Check(not Text.Contains('Content="A"') and not Text.Contains('Content="B"') and Text.Contains('<StackPanel>'),
    'Delete removes every selected element in one change');
  Text := DeleteElements(Xaml, [TXamlPosition.Create(6, 13), TXamlPosition.Create(5, 9)]);
  Check(not Text.Contains('StackPanel') and not Text.Contains('Text="C"'), 'an element inside another selected one goes with it');
  Text := CopyElements(Xaml, [TXamlPosition.Create(4, 9), TXamlPosition.Create(3, 9)]);
  Check(Text = '<Button x:Name="A" Content="A"/>'#13#10'<Button x:Name="B" Content="B"/>', 'Copy: in document order, one per line');
  Text := PasteElement(Xaml, 5, 9, Text);
  Check(Text.Contains('<StackPanel>') and (Text.IndexOf('Content="A"', Text.IndexOf('<StackPanel>')) > 0) and
    (Text.IndexOf('Content="A"', Text.IndexOf('<StackPanel>')) < Text.IndexOf('Content="B"', Text.IndexOf('<StackPanel>'))),
    'Paste: several elements into a panel, in their order');
  Text := SetAttributeOn(Xaml, [TXamlPosition.Create(3, 9), TXamlPosition.Create(4, 9)], 'IsEnabled', 'False');
  Check((Text.CountChar('=') = Xaml.CountChar('=') + 2) and Text.Contains('Content="A" IsEnabled="False"') and
    Text.Contains('Content="B" IsEnabled="False"'), 'an Object Inspector change goes to every selected element');
  SetLength(Moves, 2);
  Moves[0].Line := 3; Moves[0].Column := 9; Moves[0].Left := 10; Moves[0].Top := 20;
  Moves[1].Line := 4; Moves[1].Column := 9; Moves[1].Left := 30; Moves[1].Top := 40;
  Text := NudgeElements(Xaml, Moves);
  Check(Text.Contains('Margin="10,20,0,0"') and Text.Contains('Margin="30,40,0,0"'), 'Ctrl+Arrow moves every selected element');
end;

procedure CheckSettings;
var
  Key: string;
  Settings: TRADWinUISettings;
  Registry: TRegistry;
begin
  Writeln('Settings');
  // A key of its own under HKEY_CURRENT_USER, removed at the end
  Key := 'Software\RADWinUI-SettingsTest-' + TGUID.NewGuid.ToString;
  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    try
      Settings := TRADWinUISettings.Load(Key);
      Check(Settings.AISuggestions and Settings.CodeCompletion and Settings.PromptWithSelection and
        (Settings.SuggestionDelay = 250), 'no key: the defaults (suggestions on, 250 ms, code completion and selection on)');
      Settings.AISuggestions := False;
      Settings.SuggestionDelay := 700;
      Settings.CodeCompletion := False;
      Settings.PromptWithSelection := False;
      Settings.Save(Key);
      Settings := TRADWinUISettings.Load(Key);
      Check(not Settings.AISuggestions and not Settings.CodeCompletion and not Settings.PromptWithSelection and
        (Settings.SuggestionDelay = 700),
        'saved and loaded again');
      Check(not TRADWinUISettings.CodeCompletionEnabled(Key), 'CodeCompletionEnabled reads the stored value');
      Check(TRADWinUISettings.Defaults.HotReload = hrWhileTyping, 'hot reload is on while typing by default');
      Settings.HotReload := hrOnSave;
      Settings.Save(Key);
      Check(TRADWinUISettings.Load(Key).HotReload = hrOnSave, 'the hot reload choice is saved');
      Registry.OpenKey(Key, False);
      Registry.WriteInteger('XamlHotReload', 7);
      Check(TRADWinUISettings.Load(Key).HotReload = hrWhileTyping, 'an unknown hot reload choice is the default');
      Registry.CloseKey;
      Registry.OpenKey(Key, False);
      Registry.WriteInteger('XamlAISuggestionDelay', 99999);
      Check(TRADWinUISettings.Load(Key).SuggestionDelay = 250, 'a pause out of range is the default');
      // What the first version saved: its default pause of 500 ms, no version
      Registry.DeleteValue('SettingsVersion');
      Registry.WriteInteger('XamlAISuggestionDelay', 500);
      Check(TRADWinUISettings.Load(Key).SuggestionDelay = 250, 'the old default pause becomes the new default');
      Registry.WriteInteger('XamlAISuggestionDelay', 800);
      Check(TRADWinUISettings.Load(Key).SuggestionDelay = 800, 'a pause the user chose is kept');
      Registry.WriteInteger('SettingsVersion', 2);
      Registry.WriteInteger('XamlAISuggestionDelay', 500);
      Check(TRADWinUISettings.Load(Key).SuggestionDelay = 500, 'and 500 ms chosen in this version is kept');
      Registry.WriteString('XamlAISuggestions', 'yes');
      Check(TRADWinUISettings.Load(Key).AISuggestions, 'a value of the wrong type is the default');
      Registry.CloseKey;
    finally
      Registry.DeleteKey(Key);
    end;
  finally
    Registry.Free;
  end;
end;

procedure CheckSlashKey;
var
  Layouts: array[0..63] of HKL;
  I, Count: Integer;
  Lang: Word;
begin
  Writeln('Ctrl+/ on keyboard layouts');
  // VkKeyScanEx('/') results: low byte the key, high byte 1 Shift, 2 Ctrl, 4 Alt
  Check(SlashShortCut($00BF) = $40BF, 'US: Ctrl+VK_OEM_2');
  Check(SlashShortCut($0137) = $6037, 'Turkish Q: "/" is Shift+7, so Ctrl+Shift+7');
  Check(SlashShortCut($06BF) = 0, 'a "/" typed with AltGr gives no shortcut');
  Check(SlashShortCut(-1) = 0, 'a layout without "/" gives none');
  // The layouts this user already has, none loaded by the test
  Count := GetKeyboardLayoutList(Length(Layouts), Layouts[0]);
  for I := 0 to Count - 1 do
  begin
    Lang := LoWord(NativeUInt(Layouts[I]));
    if (Lang = $0409) and (HiWord(NativeUInt(Layouts[I])) = $0409) then
      Check(SlashShortCut(VkKeyScanEx('/', Layouts[I])) = $40BF, 'the installed US layout gives Ctrl+/');
    if Lang = $041F then
      Check(SlashShortCut(VkKeyScanEx('/', Layouts[I])) <> 0,
        Format('the installed Turkish layout %.8x gives a shortcut (%.4x)', [NativeUInt(Layouts[I]),
        SlashShortCut(VkKeyScanEx('/', Layouts[I]))]));
  end;
end;

procedure CheckComments;
const
  Xaml =
    '<StackPanel>'#13#10 +
    '    <TextBox/>'#13#10 +
    '    <Button Content="OK"/>'#13#10 +
    '</StackPanel>';
var
  Text: string;
  At: Integer;
  Skipped: TArray<Integer>;
begin
  Writeln('Ctrl+/ comments');
  At := Xaml.IndexOf('<TextBox') + 3; // the cursor inside the line
  Text := ToggleXamlComment(Xaml, At, At);
  Check(Text = Xaml.Replace('    <TextBox/>', '    <!-- <TextBox/> -->'), 'the cursor''s line, after its indentation');
  Check(ToggleXamlComment(Text, At, At) = Xaml, 'again: uncommented');

  // Several lines: each one is commented, like the Pascal editor
  Text := ToggleXamlComment(Xaml, Xaml.IndexOf('<TextBox'), Xaml.IndexOf('OK'));
  Check(Text = '<StackPanel>'#13#10'    <!-- <TextBox/> -->'#13#10'    <!-- <Button Content="OK"/> -->'#13#10'</StackPanel>',
    'a selection over two lines: each line commented');
  Check(ToggleXamlComment(Text, Text.IndexOf('<!--'), Text.LastIndexOf('-->')) = Xaml, 'and uncommented again');

  // A selection that ends at the start of the next line leaves that line out
  Text := ToggleXamlComment(Xaml, Xaml.IndexOf('    <TextBox'), Xaml.IndexOf('    <Button'));
  Check(Text = Xaml.Replace('    <TextBox/>', '    <!-- <TextBox/> -->'), 'a selection ending at a line start');

  // One comment over several lines: its markers go
  Text := '    <!-- <A/>'#13#10'    <B/> -->';
  Check(ToggleXamlComment(Text, 0, Length(Text)) = '    <A/>'#13#10'    <B/>', 'a comment over two lines, selected');

  // A commented line among others: the others are commented, it stays
  Text := '    <!-- <A/> -->'#13#10'    <B/>';
  Check(ToggleXamlComment(Text, 0, Length(Text)) = '    <!-- <A/> -->'#13#10'    <!-- <B/> -->',
    'a line that is a comment already stays, the others are commented');
  // A double dash cannot go in a comment: that line stays and is reported
  Text := '<A/>'#13#10'<TextBlock Text="a--b"/>'#13#10'<C/>';
  Check((ToggleXamlComment(Text, 0, Length(Text), Skipped) = '<!-- <A/> -->'#13#10'<TextBlock Text="a--b"/>'#13#10'<!-- <C/> -->') and
    (Length(Skipped) = 1) and (Skipped[0] = 2), 'a line with "--" is left as it is and reported (line 2)');
  Check((ToggleXamlComment('<TextBlock Text="a--b"/>', 0, 0, Skipped) = '<TextBlock Text="a--b"/>') and
    (Length(Skipped) = 1), 'a single line with "--" is reported');
  Check(ToggleXamlComment('<A/>'#10'<B/>', 6, 6) = '<A/>'#10'<!-- <B/> -->', 'LF line breaks');
  Check(ToggleXamlComment(Xaml + #13#10'    '#13#10, Length(Xaml) + 4, Length(Xaml) + 4) = Xaml + #13#10'    '#13#10,
    'an empty line is left alone');
end;

var
  Engine: TFakeEngine;
  Cursor: Integer;
  Prompt, Suggestion, Result, Folder: string;
  UserControls: TArray<string>;
begin
  Failures := 0;
  Writeln('Complete XAML with AI');
  Engine := TFakeEngine.Create;
  Folder := TPath.Combine(TPath.GetTempPath, 'RADWinUI-AICompletionTest');
  try
    // The project's user controls: .xaml files with a UserControl root next to the window
    TDirectory.CreateDirectory(Folder);
    TFile.WriteAllText(TPath.Combine(Folder, 'PersonCard.xaml'),
      '<UserControl xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
      'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Class="TPersonCard"><Grid/></UserControl>');
    TFile.WriteAllText(TPath.Combine(Folder, 'MainWindow.xaml'), Window);
    UserControls := ProjectUserControls(Window, Folder);
    Check((Length(UserControls) = 1) and (UserControls[0] = 'local:PersonCard'),
      'the project''s user controls with the root''s using: prefix');
    Check(Length(ProjectUserControls(Window.Replace('xmlns:local="using:Demo" ', ''), Folder)) = 0,
      'no user controls without a using: namespace');

    // The cursor on the empty line, after its indentation
    Cursor := Window.IndexOf('        '#13#10'    </StackPanel>') + 8;
    Prompt := BuildXamlCompletion(Window, Cursor, UserControls);
    Check(Prompt.Contains('<TextBox x:Name="NameBox"/>'#13#10'        ' + XamlCursorMarker + #13#10'    </StackPanel>'),
      'the XAML with the cursor marker at the cursor');
    Check(Prompt.Contains('rw:SlidingPillTabBar') and Prompt.Contains('rw:DBGrid'), 'RADWinUI''s own controls with rw:');
    Check(Prompt.Contains('local:PersonCard'), 'the project''s user controls');
    Check(Prompt.Contains('Names in use: Root, NameBox.'), 'the x:Names in use');
    Check(Prompt.Contains('Reply with only the XAML'), 'the rules');
    Check(BuildXamlCompletion(Window, 9999, nil).Contains('</Window>'#13#10 + XamlCursorMarker),
      'a cursor past the end is the end');
    Check(BuildXamlCompletion('<Window><Grid', 13, nil).Contains('Names in use: (none).'), 'half-typed XAML');

    // The fake engine answers in a fence, as chat models often do
    Engine.Reply := 'Here it is:'#13#10'```xml'#13#10 +
      '<Button x:Name="SaveButton" Content="Save" Click="SaveClick"/>'#13#10'```'#13#10;
    Suggestion := CleanXamlCompletion(Engine.Chat(Prompt));
    Check(Engine.Prompt = Prompt, 'the engine got the prompt');
    Check(Suggestion = '<Button x:Name="SaveButton" Content="Save" Click="SaveClick"/>', 'the code inside the fence');
    Result := InsertXamlCompletion(Window, Cursor, Suggestion);
    Check(Result.Contains('        <TextBox x:Name="NameBox"/>'#13#10 +
      '        <Button x:Name="SaveButton" Content="Save" Click="SaveClick"/>'#13#10'    </StackPanel>'),
      'inserted at the cursor, the rest unchanged');
    Check(Result.Replace('<Button x:Name="SaveButton" Content="Save" Click="SaveClick"/>', '') = Window,
      'nothing else changed');

    Check(CleanXamlCompletion('<TextBlock Text="Hi"/>' + XamlCursorMarker + #13#10#13#10) = '<TextBlock Text="Hi"/>',
      'an echoed marker and trailing lines are dropped');
    Check(CleanXamlCompletion(#13#10'    <Grid/>') = #13#10'    <Grid/>', 'leading indentation is kept');
    Check(CleanXamlCompletion('   '#13#10) = '', 'an empty answer is no suggestion');
    try
      InsertXamlCompletion(Window, Length(Window) + 1, 'x');
      Check(False, 'a cursor outside the XAML is refused');
    except
      on E: EArgumentOutOfRangeException do
        Check(True, 'a cursor outside the XAML is refused');
    end;
  finally
    Engine.Free;
    TDirectory.Delete(Folder, True);
  end;
  CheckSuggestions;
  CheckAnswers;
  CheckComments;
  CheckSlashKey;
  CheckSettings;
  CheckCreate;
  CheckMultiSelection;

  if Failures = 0 then
    Writeln('All checks passed')
  else
    Writeln(Failures, ' check(s) failed');
  ExitCode := Ord(Failures > 0);
end.
