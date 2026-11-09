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
    DragRegion: TWinUIGrid;              // QuillWindow.xaml(38) <Grid>
    TitleNote: TWinUITextBlock;          // QuillWindow.xaml(43) <TextBlock>
    NoteList: TWinUIListView;            // QuillWindow.xaml(54) <ListView>
    NewButton: TWinUIButton;             // QuillWindow.xaml(71) <Button>
    ImportButton: TWinUIButton;          // QuillWindow.xaml(74) <Button>
    RemindSoon: TWinUIMenuFlyoutItem;    // QuillWindow.xaml(108) <MenuFlyoutItem>
    RemindMinute: TWinUIMenuFlyoutItem;  // QuillWindow.xaml(109) <MenuFlyoutItem>
    RemindTen: TWinUIMenuFlyoutItem;     // QuillWindow.xaml(110) <MenuFlyoutItem>
    RemindCancel: TWinUIMenuFlyoutItem;  // QuillWindow.xaml(112) <MenuFlyoutItem>
    Editor: TWinUITextBox;               // QuillWindow.xaml(129) <TextBox>
    Status: TWinUITextBlock;             // QuillWindow.xaml(133) <TextBlock>
    SettingsPanel: TWinUIBorder;         // QuillWindow.xaml(137) <Border>
    LaunchInfo: TWinUITextBlock;         // QuillWindow.xaml(144) <TextBlock>
    SettingsResult: TWinUITextBlock;     // QuillWindow.xaml(159) <TextBlock>
  public
    constructor Create; override;
  end;
  {$M-}

implementation

const
  // QuillWindow.xaml(11): the content element; event attributes became the
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
    '    <StackPanel Grid.ColumnSpan="2" Orientation="Horizontal" Spacing="10" Margin="16,0,0,0" VerticalAlignment="Center" IsHitTestVisible="False">' + sLineBreak +
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
    '      <TextBlock Text="NOTES" Style="{StaticResource SectionTitle}" Margin="8,0,0,0" />' + sLineBreak +
    '      <ListView x:Name="NoteList" Grid.Row="1" SelectionMode="Single" AutomationProperties.Name="Notes">' + sLineBreak +
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
    '        <Button x:Name="NewButton" Style="{StaticResource AccentButtonStyle}" AutomationProperties.Name="New note">' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="8"><FontIcon Glyph="" FontSize="14" /><TextBlock Text="New note" /></StackPanel>' + sLineBreak +
    '        </Button>' + sLineBreak +
    '        <Button x:Name="ImportButton" AutomationProperties.Name="Import">' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="8"><FontIcon Glyph="" FontSize="14" /><TextBlock Text="Import" /></StackPanel>' + sLineBreak +
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
    '      <StackPanel Orientation="Horizontal" Spacing="2">' + sLineBreak +
    '        <Button Style="{StaticResource ToolButton}" AutomationProperties.Name="Open" ToolTipService.ToolTip="Open" x:Name="_rw1">' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="8"><FontIcon Glyph="" FontSize="14" /><TextBlock Text="Open" /></StackPanel>' + sLineBreak +
    '        </Button>' + sLineBreak +
    '        <Button Style="{StaticResource ToolButton}" AutomationProperties.Name="Save" ToolTipService.ToolTip="Save" x:Name="_rw2">' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="8"><FontIcon Glyph="" FontSize="14" /><TextBlock Text="Save" /></StackPanel>' + sLineBreak +
    '        </Button>' + sLineBreak +
    '        <Button Style="{StaticResource ToolButton}" AutomationProperties.Name="Save as" ToolTipService.ToolTip="Save as" x:Name="_rw3">' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="8"><FontIcon Glyph="" FontSize="14" /><TextBlock Text="Save as" /></StackPanel>' + sLineBreak +
    '        </Button>' + sLineBreak +
    '        <Button Style="{StaticResource ToolButton}" AutomationProperties.Name="Rename" ToolTipService.ToolTip="Rename" x:Name="_rw4">' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="8"><FontIcon Glyph="" FontSize="14" /><TextBlock Text="Rename" /></StackPanel>' + sLineBreak +
    '        </Button>' + sLineBreak +
    '        <Button Style="{StaticResource ToolButton}" AutomationProperties.Name="Close note" ToolTipService.ToolTip="Close note" x:Name="_rw5">' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="8"><FontIcon Glyph="" FontSize="14" /><TextBlock Text="Close" /></StackPanel>' + sLineBreak +
    '        </Button>' + sLineBreak +
    '        <AppBarSeparator />' + sLineBreak +
    '        <Button Style="{StaticResource ToolButton}" AutomationProperties.Name="Remind me" ToolTipService.ToolTip="Remind me">' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="8"><FontIcon Glyph="" FontSize="14" /><TextBlock Text="Remind me" /></StackPanel>' + sLineBreak +
    '          <Button.Flyout>' + sLineBreak +
    '            <MenuFlyout Placement="BottomEdgeAlignedLeft">' + sLineBreak +
    '              <MenuFlyoutItem x:Name="RemindSoon" Text="In 10 seconds" />' + sLineBreak +
    '              <MenuFlyoutItem x:Name="RemindMinute" Text="In 1 minute" />' + sLineBreak +
    '              <MenuFlyoutItem x:Name="RemindTen" Text="In 10 minutes" />' + sLineBreak +
    '              <MenuFlyoutSeparator />' + sLineBreak +
    '              <MenuFlyoutItem x:Name="RemindCancel" Text="Cancel the reminder" />' + sLineBreak +
    '            </MenuFlyout>' + sLineBreak +
    '          </Button.Flyout>' + sLineBreak +
    '        </Button>' + sLineBreak +
    '        <Button Style="{StaticResource ToolButton}" AutomationProperties.Name="Export all" ToolTipService.ToolTip="Export all notes to a folder" x:Name="_rw6">' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="8"><FontIcon Glyph="" FontSize="14" /><TextBlock Text="Export all" /></StackPanel>' + sLineBreak +
    '        </Button>' + sLineBreak +
    '        <AppBarSeparator />' + sLineBreak +
    '        <Button Style="{StaticResource ToolButton}" AutomationProperties.Name="Settings" ToolTipService.ToolTip="Settings" x:Name="_rw7">' + sLineBreak +
    '          <FontIcon Glyph="" FontSize="14" />' + sLineBreak +
    '        </Button>' + sLineBreak +
    '        <Button Style="{StaticResource ToolButton}" AutomationProperties.Name="About" ToolTipService.ToolTip="About Quill" x:Name="_rw8">' + sLineBreak +
    '          <FontIcon Glyph="" FontSize="14" />' + sLineBreak +
    '        </Button>' + sLineBreak +
    '      </StackPanel>' + sLineBreak +
    '      <Border Grid.Row="1" CornerRadius="8" BorderThickness="1" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}">' + sLineBreak +
    '        <TextBox x:Name="Editor" AcceptsReturn="True" TextWrapping="Wrap" BorderThickness="0" Background="Transparent" Padding="24,20" FontSize="15" PlaceholderText="Start writing..." ScrollViewer.Ver' +
    'ticalScrollBarVisibility="Auto" AutomationProperties.Name="Editor" />' + sLineBreak +
    '      </Border>' + sLineBreak +
    '      <TextBlock x:Name="Status" Grid.Row="2" Margin="4,0,0,0" FontSize="12" Opacity="0.7" />' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Border x:Name="SettingsPanel" Grid.Row="1" Grid.Column="2" Width="300" Margin="0,4,12,12" Padding="20" CornerRadius="8" BorderThickness="1" Visibility="Collapsed" Background="{ThemeResource Layer' +
    'FillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}">' + sLineBreak +
    '      <ScrollViewer VerticalScrollBarVisibility="Auto">' + sLineBreak +
    '        <StackPanel Spacing="10">' + sLineBreak +
    '          <TextBlock Text="Settings" FontSize="20" FontWeight="SemiBold" />' + sLineBreak +
    '          <TextBlock Text="HOW QUILL STARTED" Style="{StaticResource SectionTitle}" Margin="0,8,0,0" />' + sLineBreak +
    '          <TextBlock x:Name="LaunchInfo" TextWrapping="Wrap" IsTextSelectionEnabled="True" />' + sLineBreak +
    '          <TextBlock Text="NOTE FILES" Style="{StaticResource SectionTitle}" Margin="0,8,0,0" />' + sLineBreak +
    '          <TextBlock TextWrapping="Wrap" Opacity="0.8" Text="Let Windows open .qnote files with Quill. A file opened while Quill runs goes to this window." />' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '            <Button Content="Register .qnote" x:Name="_rw9" />' + sLineBreak +
    '            <Button Content="Unregister" AutomationProperties.Name="Unregister .qnote" x:Name="_rw10" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '          <TextBlock Text="LINKS" Style="{StaticResource SectionTitle}" Margin="0,8,0,0" />' + sLineBreak +
    '          <TextBlock TextWrapping="Wrap" Opacity="0.8" Text="Let links like quill://new?text=hello create a note. Try one from Win+R after registering." />' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '            <Button Content="Register quill:" x:Name="_rw11" />' + sLineBreak +
    '            <Button Content="Unregister" AutomationProperties.Name="Unregister quill:" x:Name="_rw12" />' + sLineBreak +
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
  LaunchInfo := FindElement<TWinUITextBlock>('LaunchInfo');
  SettingsResult := FindElement<TWinUITextBlock>('SettingsResult');
  // Event wiring
  // QuillWindow.xaml(54): SelectionChanged="NoteListSelectionChanged"
  NoteList.OnSelectionChanged := TWinUISelectionChangedEventHandler(PublishedMethod('NoteListSelectionChanged'));
  // QuillWindow.xaml(71): Click="NewClick"
  NewButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('NewClick'));
  // QuillWindow.xaml(74): Click="ImportClick"
  ImportButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ImportClick'));
  // QuillWindow.xaml(88): Click="OpenClick"
  FindElement<TWinUIButton>('_rw1').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('OpenClick'));
  // QuillWindow.xaml(91): Click="SaveClick"
  FindElement<TWinUIButton>('_rw2').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('SaveClick'));
  // QuillWindow.xaml(94): Click="SaveAsClick"
  FindElement<TWinUIButton>('_rw3').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('SaveAsClick'));
  // QuillWindow.xaml(97): Click="RenameClick"
  FindElement<TWinUIButton>('_rw4').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RenameClick'));
  // QuillWindow.xaml(100): Click="CloseNoteClick"
  FindElement<TWinUIButton>('_rw5').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('CloseNoteClick'));
  // QuillWindow.xaml(108): Click="RemindSoonClick"
  RemindSoon.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RemindSoonClick'));
  // QuillWindow.xaml(109): Click="RemindMinuteClick"
  RemindMinute.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RemindMinuteClick'));
  // QuillWindow.xaml(110): Click="RemindTenClick"
  RemindTen.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RemindTenClick'));
  // QuillWindow.xaml(112): Click="RemindCancelClick"
  RemindCancel.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RemindCancelClick'));
  // QuillWindow.xaml(116): Click="ExportClick"
  FindElement<TWinUIButton>('_rw6').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ExportClick'));
  // QuillWindow.xaml(120): Click="SettingsClick"
  FindElement<TWinUIButton>('_rw7').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('SettingsClick'));
  // QuillWindow.xaml(123): Click="AboutClick"
  FindElement<TWinUIButton>('_rw8').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('AboutClick'));
  // QuillWindow.xaml(129): TextChanged="EditorChanged"
  Editor.OnTextChanged := TWinUITextChangedEventHandler(PublishedMethod('EditorChanged'));
  // QuillWindow.xaml(149): Click="RegisterFilesClick"
  FindElement<TWinUIButton>('_rw9').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RegisterFilesClick'));
  // QuillWindow.xaml(150): Click="UnregisterFilesClick"
  FindElement<TWinUIButton>('_rw10').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('UnregisterFilesClick'));
  // QuillWindow.xaml(156): Click="RegisterLinksClick"
  FindElement<TWinUIButton>('_rw11').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RegisterLinksClick'));
  // QuillWindow.xaml(157): Click="UnregisterLinksClick"
  FindElement<TWinUIButton>('_rw12').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('UnregisterLinksClick'));
end;

end.
