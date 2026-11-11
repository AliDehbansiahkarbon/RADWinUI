unit QuillWindow.Xaml;

{
  TQuillWindowBase: base class of TQuillWindow, generated from QuillWindow.xaml
  by RADWinUI XamlCodeGen 0.4 (tools/XamlCodeGen).

  DO NOT EDIT. Change QuillWindow.xaml or the published handlers of TQuillWindow
  in QuillWindow.pas; the build regenerates this unit.

  Fields      one per x:Name element, in XAML order
  Create      window settings, content, fields, event wiring
  Comments    name the XAML line each item comes from
}

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Forms;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TQuillWindowBase = class(TWinUIWindow)
  protected
    DragRegion: TWinUIGrid;              // QuillWindow.xaml(39) <Grid>
    TitleRow: TWinUIStackPanel;          // QuillWindow.xaml(40) <StackPanel>
    TitleNote: TWinUITextBlock;          // QuillWindow.xaml(44) <TextBlock>
    NoteList: TWinUIListView;            // QuillWindow.xaml(55) <ListView>
    NewButton: TWinUIButton;             // QuillWindow.xaml(72) <Button>
    ImportButton: TWinUIButton;          // QuillWindow.xaml(75) <Button>
    RemindSoon: TWinUIMenuFlyoutItem;    // QuillWindow.xaml(116) <MenuFlyoutItem>
    RemindMinute: TWinUIMenuFlyoutItem;  // QuillWindow.xaml(117) <MenuFlyoutItem>
    RemindTen: TWinUIMenuFlyoutItem;     // QuillWindow.xaml(118) <MenuFlyoutItem>
    RemindCancel: TWinUIMenuFlyoutItem;  // QuillWindow.xaml(120) <MenuFlyoutItem>
    Editor: TWinUITextBox;               // QuillWindow.xaml(141) <TextBox>
    Status: TWinUITextBlock;             // QuillWindow.xaml(145) <TextBlock>
    SettingsPanel: TWinUIBorder;         // QuillWindow.xaml(149) <Border>
    LanguageBox: TWinUIComboBox;         // QuillWindow.xaml(156) <ComboBox>
    LaunchInfo: TWinUITextBlock;         // QuillWindow.xaml(164) <TextBlock>
    SettingsResult: TWinUITextBlock;     // QuillWindow.xaml(177) <TextBlock>
  public
    constructor Create; override;
  end;
  {$M-}

implementation

const
  // QuillWindow.xaml(12): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' + sLineBreak +
    '    <Grid.Resources>' + sLineBreak +
    '      <ResourceDictionary>' + sLineBreak +
    '        <Style x:Key="ToolButton" TargetType="Button">' + sLineBreak +
    '          <Setter Property="Background" Value="Transparent" />' + sLineBreak +
    '          <Setter Property="BorderThickness" Value="0" />' + sLineBreak +
    '          <Setter Property="Padding" Value="10,6" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="6" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="SectionTitle" TargetType="TextBlock">' + sLineBreak +
    '          <Setter Property="FontSize" Value="12" />' + sLineBreak +
    '          <Setter Property="FontWeight" Value="SemiBold" />' + sLineBreak +
    '          <Setter Property="Opacity" Value="0.7" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '      </ResourceDictionary>' + sLineBreak +
    '    </Grid.Resources>' + sLineBreak +
    '    <Grid.RowDefinitions>' + sLineBreak +
    '      <RowDefinition Height="40" />' + sLineBreak +
    '      <RowDefinition Height="*" />' + sLineBreak +
    '    </Grid.RowDefinitions>' + sLineBreak +
    '    <Grid.ColumnDefinitions>' + sLineBreak +
    '      <ColumnDefinition Width="260" />' + sLineBreak +
    '      <ColumnDefinition Width="*" />' + sLineBreak +
    '      <ColumnDefinition Width="Auto" />' + sLineBreak +
    '    </Grid.ColumnDefinitions>' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Grid x:Name="DragRegion" Grid.ColumnSpan="3" Background="Transparent" />' + sLineBreak +
    '    <StackPanel x:Name="TitleRow" Grid.ColumnSpan="2" Orientation="Horizontal" Spacing="10" Margin="16,0,0,0" VerticalAlignment="Center" IsHitTestVisible="False">' + sLineBreak +
    '      <FontIcon Glyph="" FontSize="16" Foreground="{ThemeResource AccentTextFillColorPrimaryBrush}" />' + sLineBreak +
    '      <TextBlock Text="Quill" FontWeight="SemiBold" />' + sLineBreak +
    '      <TextBlock x:Name="TitleNote" Opacity="0.7" />' + sLineBreak +
    '    </StackPanel>' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Grid Grid.Row="1" Padding="12,4,8,12" RowSpacing="8">' + sLineBreak +
    '      <Grid.RowDefinitions>' + sLineBreak +
    '        <RowDefinition Height="Auto" />' + sLineBreak +
    '        <RowDefinition Height="*" />' + sLineBreak +
    '        <RowDefinition Height="Auto" />' + sLineBreak +
    '      </Grid.RowDefinitions>' + sLineBreak +
    '      <TextBlock x:Uid="NotesHeader" Style="{StaticResource SectionTitle}" Margin="8,0,0,0" />' + sLineBreak +
    '      <ListView x:Name="NoteList" Grid.Row="1" SelectionMode="Single" x:Uid="NoteList">' + sLineBreak +
    '        ' + sLineBreak +
    '        <ListView.ItemTemplate>' + sLineBreak +
    '          <DataTemplate>' + sLineBreak +
    '            <StackPanel Padding="0,8">' + sLineBreak +
    '              <TextBlock Text="{Binding Title}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" />' + sLineBreak +
    '              <TextBlock Text="{Binding Subtitle}" FontSize="12" Opacity="0.65" TextTrimming="CharacterEllipsis" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </DataTemplate>' + sLineBreak +
    '        </ListView.ItemTemplate>' + sLineBreak +
    '      </ListView>' + sLineBreak +
    '      <StackPanel Grid.Row="2" Orientation="Horizontal" Spacing="6">' + sLineBreak +
    '        <Button x:Name="NewButton" x:Uid="NewButton" Style="{StaticResource AccentButtonStyle}">' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="8"><FontIcon Glyph="" FontSize="14" /><TextBlock x:Uid="NewText" /></StackPanel>' + sLineBreak +
    '        </Button>' + sLineBreak +
    '        <Button x:Name="ImportButton" x:Uid="ImportButton">' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="8"><FontIcon Glyph="" FontSize="14" /><TextBlock x:Uid="ImportText" /></StackPanel>' + sLineBreak +
    '        </Button>' + sLineBreak +
    '      </StackPanel>' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Grid Grid.Row="1" Grid.Column="1" Margin="4,4,12,12" RowSpacing="8">' + sLineBreak +
    '      <Grid.RowDefinitions>' + sLineBreak +
    '        <RowDefinition Height="Auto" />' + sLineBreak +
    '        <RowDefinition Height="*" />' + sLineBreak +
    '        <RowDefinition Height="Auto" />' + sLineBreak +
    '      </Grid.RowDefinitions>' + sLineBreak +
    '      <Grid ColumnSpacing="2">' + sLineBreak +
    '        <Grid.ColumnDefinitions>' + sLineBreak +
    '          <ColumnDefinition Width="*" />' + sLineBreak +
    '          <ColumnDefinition Width="Auto" />' + sLineBreak +
    '        </Grid.ColumnDefinitions>' + sLineBreak +
    '        <ScrollViewer HorizontalScrollMode="Auto" HorizontalScrollBarVisibility="Hidden" VerticalScrollMode="Disabled" VerticalScrollBarVisibility="Disabled">' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="2">' + sLineBreak +
    '            <Button x:Uid="OpenButton" Style="{StaticResource ToolButton}" x:Name="_rw1">' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="8"><FontIcon Glyph="" FontSize="14" /><TextBlock x:Uid="OpenText" /></StackPanel>' + sLineBreak +
    '            </Button>' + sLineBreak +
    '            <Button x:Uid="SaveButton" Style="{StaticResource ToolButton}" x:Name="_rw2">' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="8"><FontIcon Glyph="" FontSize="14" /><TextBlock x:Uid="SaveText" /></StackPanel>' + sLineBreak +
    '            </Button>' + sLineBreak +
    '            <Button x:Uid="SaveAsButton" Style="{StaticResource ToolButton}" x:Name="_rw3">' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="8"><FontIcon Glyph="" FontSize="14" /><TextBlock x:Uid="SaveAsText" /></StackPanel>' + sLineBreak +
    '            </Button>' + sLineBreak +
    '            <Button x:Uid="RenameButton" Style="{StaticResource ToolButton}" x:Name="_rw4">' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="8"><FontIcon Glyph="" FontSize="14" /><TextBlock x:Uid="RenameText" /></StackPanel>' + sLineBreak +
    '            </Button>' + sLineBreak +
    '            <Button x:Uid="CloseNoteButton" Style="{StaticResource ToolButton}" x:Name="_rw5">' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="8"><FontIcon Glyph="" FontSize="14" /><TextBlock x:Uid="CloseNoteText" /></StackPanel>' + sLineBreak +
    '            </Button>' + sLineBreak +
    '            <AppBarSeparator />' + sLineBreak +
    '            <Button x:Uid="RemindButton" Style="{StaticResource ToolButton}">' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="8"><FontIcon Glyph="" FontSize="14" /><TextBlock x:Uid="RemindText" /></StackPanel>' + sLineBreak +
    '              <Button.Flyout>' + sLineBreak +
    '                <MenuFlyout Placement="BottomEdgeAlignedLeft">' + sLineBreak +
    '                  <MenuFlyoutItem x:Name="RemindSoon" x:Uid="RemindSoon" />' + sLineBreak +
    '                  <MenuFlyoutItem x:Name="RemindMinute" x:Uid="RemindMinute" />' + sLineBreak +
    '                  <MenuFlyoutItem x:Name="RemindTen" x:Uid="RemindTen" />' + sLineBreak +
    '                  <MenuFlyoutSeparator />' + sLineBreak +
    '                  <MenuFlyoutItem x:Name="RemindCancel" x:Uid="RemindCancel" />' + sLineBreak +
    '                </MenuFlyout>' + sLineBreak +
    '              </Button.Flyout>' + sLineBreak +
    '            </Button>' + sLineBreak +
    '            <Button x:Uid="ExportButton" Style="{StaticResource ToolButton}" x:Name="_rw6">' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="8"><FontIcon Glyph="" FontSize="14" /><TextBlock x:Uid="ExportText" /></StackPanel>' + sLineBreak +
    '            </Button>' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </ScrollViewer>' + sLineBreak +
    '        <StackPanel Grid.Column="1" Orientation="Horizontal" Spacing="2">' + sLineBreak +
    '          <AppBarSeparator />' + sLineBreak +
    '          <Button x:Uid="SettingsButton" Style="{StaticResource ToolButton}" x:Name="_rw7">' + sLineBreak +
    '            <FontIcon Glyph="" FontSize="14" />' + sLineBreak +
    '          </Button>' + sLineBreak +
    '          <Button x:Uid="AboutButton" Style="{StaticResource ToolButton}" x:Name="_rw8">' + sLineBreak +
    '            <FontIcon Glyph="" FontSize="14" />' + sLineBreak +
    '          </Button>' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </Grid>' + sLineBreak +
    '      <Border Grid.Row="1" CornerRadius="8" BorderThickness="1" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}">' + sLineBreak +
    '        <TextBox x:Name="Editor" x:Uid="Editor" AcceptsReturn="True" TextWrapping="Wrap" BorderThickness="0" Background="Transparent" Padding="24,20" FontSize="15" ScrollViewer.VerticalScrollBarVisibi' +
    'lity="Auto" />' + sLineBreak +
    '      </Border>' + sLineBreak +
    '      <TextBlock x:Name="Status" Grid.Row="2" Margin="4,0,0,0" FontSize="12" Opacity="0.7" />' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Border x:Name="SettingsPanel" Grid.Row="1" Grid.Column="2" Width="300" Margin="0,4,12,12" Padding="20" CornerRadius="8" BorderThickness="1" Visibility="Collapsed" Background="{ThemeResource Layer' +
    'FillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}">' + sLineBreak +
    '      <ScrollViewer VerticalScrollBarVisibility="Auto">' + sLineBreak +
    '        <StackPanel Spacing="10">' + sLineBreak +
    '          <TextBlock x:Uid="SettingsTitle" FontSize="20" FontWeight="SemiBold" />' + sLineBreak +
    '          <TextBlock x:Uid="LanguageHeader" Style="{StaticResource SectionTitle}" Margin="0,8,0,0" />' + sLineBreak +
    '          <ComboBox x:Name="LanguageBox" x:Uid="LanguageBox" HorizontalAlignment="Stretch">' + sLineBreak +
    '            <ComboBoxItem x:Uid="LanguageSystem" />' + sLineBreak +
    '            <ComboBoxItem Content="English" />' + sLineBreak +
    '            <ComboBoxItem Content="Deutsch" />' + sLineBreak +
    '            <ComboBoxItem Content="فارسی" />' + sLineBreak +
    '          </ComboBox>' + sLineBreak +
    '          <TextBlock x:Uid="LanguageInfo" TextWrapping="Wrap" Opacity="0.8" />' + sLineBreak +
    '          <TextBlock x:Uid="LaunchHeader" Style="{StaticResource SectionTitle}" Margin="0,8,0,0" />' + sLineBreak +
    '          <TextBlock x:Name="LaunchInfo" TextWrapping="Wrap" IsTextSelectionEnabled="True" />' + sLineBreak +
    '          <TextBlock x:Uid="FilesHeader" Style="{StaticResource SectionTitle}" Margin="0,8,0,0" />' + sLineBreak +
    '          <TextBlock x:Uid="FilesInfo" TextWrapping="Wrap" Opacity="0.8" />' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '            <Button x:Uid="RegisterFiles" x:Name="_rw9" />' + sLineBreak +
    '            <Button x:Uid="UnregisterFiles" x:Name="_rw10" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '          <TextBlock x:Uid="LinksHeader" Style="{StaticResource SectionTitle}" Margin="0,8,0,0" />' + sLineBreak +
    '          <TextBlock x:Uid="LinksInfo" TextWrapping="Wrap" Opacity="0.8" />' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '            <Button x:Uid="RegisterLinks" x:Name="_rw11" />' + sLineBreak +
    '            <Button x:Uid="UnregisterLinks" x:Name="_rw12" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '          <TextBlock x:Name="SettingsResult" TextWrapping="Wrap" Opacity="0.8" Margin="0,8,0,0" />' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </ScrollViewer>' + sLineBreak +
    '    </Border>' + sLineBreak +
    '  </Grid>' + sLineBreak;

constructor TQuillWindowBase.Create;
begin
  inherited;
  // QuillWindow.xaml(1): <Window> attributes
  Title := 'Quill';
  Width := 1100;
  Height := 720;
  MinWidth := 760;
  MinHeight := 480;
  Backdrop := TWinUIBackdrop.Mica;
  ExtendsContentIntoTitleBar := True;
  Center;
  LoadContent(ContentXaml);
  // x:Name elements
  DragRegion := FindElement<TWinUIGrid>('DragRegion');
  TitleRow := FindElement<TWinUIStackPanel>('TitleRow');
  TitleNote := FindElement<TWinUITextBlock>('TitleNote');
  NoteList := FindElement<TWinUIListView>('NoteList');
  NewButton := FindElement<TWinUIButton>('NewButton');
  ImportButton := FindElement<TWinUIButton>('ImportButton');
  RemindSoon := FindElement<TWinUIMenuFlyoutItem>('RemindSoon');
  RemindMinute := FindElement<TWinUIMenuFlyoutItem>('RemindMinute');
  RemindTen := FindElement<TWinUIMenuFlyoutItem>('RemindTen');
  RemindCancel := FindElement<TWinUIMenuFlyoutItem>('RemindCancel');
  Editor := FindElement<TWinUITextBox>('Editor');
  Status := FindElement<TWinUITextBlock>('Status');
  SettingsPanel := FindElement<TWinUIBorder>('SettingsPanel');
  LanguageBox := FindElement<TWinUIComboBox>('LanguageBox');
  LaunchInfo := FindElement<TWinUITextBlock>('LaunchInfo');
  SettingsResult := FindElement<TWinUITextBlock>('SettingsResult');
  // Event wiring
  // QuillWindow.xaml(55): SelectionChanged="NoteListSelectionChanged"
  NoteList.OnSelectionChanged := TWinUISelectionChangedEventHandler(PublishedMethod('NoteListSelectionChanged'));
  // QuillWindow.xaml(72): Click="NewClick"
  NewButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('NewClick'));
  // QuillWindow.xaml(75): Click="ImportClick"
  ImportButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ImportClick'));
  // QuillWindow.xaml(96): Click="OpenClick"
  FindElement<TWinUIButton>('_rw1').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('OpenClick'));
  // QuillWindow.xaml(99): Click="SaveClick"
  FindElement<TWinUIButton>('_rw2').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('SaveClick'));
  // QuillWindow.xaml(102): Click="SaveAsClick"
  FindElement<TWinUIButton>('_rw3').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('SaveAsClick'));
  // QuillWindow.xaml(105): Click="RenameClick"
  FindElement<TWinUIButton>('_rw4').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RenameClick'));
  // QuillWindow.xaml(108): Click="CloseNoteClick"
  FindElement<TWinUIButton>('_rw5').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('CloseNoteClick'));
  // QuillWindow.xaml(116): Click="RemindSoonClick"
  RemindSoon.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RemindSoonClick'));
  // QuillWindow.xaml(117): Click="RemindMinuteClick"
  RemindMinute.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RemindMinuteClick'));
  // QuillWindow.xaml(118): Click="RemindTenClick"
  RemindTen.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RemindTenClick'));
  // QuillWindow.xaml(120): Click="RemindCancelClick"
  RemindCancel.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RemindCancelClick'));
  // QuillWindow.xaml(124): Click="ExportClick"
  FindElement<TWinUIButton>('_rw6').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ExportClick'));
  // QuillWindow.xaml(131): Click="SettingsClick"
  FindElement<TWinUIButton>('_rw7').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('SettingsClick'));
  // QuillWindow.xaml(134): Click="AboutClick"
  FindElement<TWinUIButton>('_rw8').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('AboutClick'));
  // QuillWindow.xaml(141): TextChanged="EditorChanged"
  Editor.OnTextChanged := TWinUITextChangedEventHandler(PublishedMethod('EditorChanged'));
  // QuillWindow.xaml(156): SelectionChanged="LanguageChanged"
  LanguageBox.OnSelectionChanged := TWinUISelectionChangedEventHandler(PublishedMethod('LanguageChanged'));
  // QuillWindow.xaml(168): Click="RegisterFilesClick"
  FindElement<TWinUIButton>('_rw9').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RegisterFilesClick'));
  // QuillWindow.xaml(169): Click="UnregisterFilesClick"
  FindElement<TWinUIButton>('_rw10').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('UnregisterFilesClick'));
  // QuillWindow.xaml(174): Click="RegisterLinksClick"
  FindElement<TWinUIButton>('_rw11').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RegisterLinksClick'));
  // QuillWindow.xaml(175): Click="UnregisterLinksClick"
  FindElement<TWinUIButton>('_rw12').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('UnregisterLinksClick'));
end;

end.
