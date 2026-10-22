unit RADWinUI.Gallery.Catalog;

interface

type
  TControlDemo = record
    Name, Category, Description, Xaml, Pascal: string;
  end;

const
  ControlDemos: array[0..29] of TControlDemo = (
    (Name: 'Button'; Category: 'Basic input';
      Description: 'A native action with a Pascal click handler. Click it to update the footer.';
      Xaml: '<Button x:Name="SampleButton" Content="Click me" Click="ExplorerButtonClick" Style="{StaticResource AccentButtonStyle}"/>';
      Pascal: 'SampleButton.Content := ''Hello from Pascal'';'),
    (Name: 'ToggleButton'; Category: 'Basic input';
      Description: 'A button that keeps its checked state.';
      Xaml: '<ToggleButton x:Name="SampleToggleButton" Content="Keep this selected"/>';
      Pascal: 'SampleToggleButton.IsThreeState := True;'),
    (Name: 'RepeatButton'; Category: 'Basic input';
      Description: 'Hold the pointer down to repeat an action.';
      Xaml: '<RepeatButton x:Name="SampleRepeatButton" Content="Press and hold" Click="ExplorerButtonClick" Delay="400" Interval="100"/>';
      Pascal: '// OnClick repeats while the button is held.'#13#10 +
      'SampleRepeatButton.Interval := 100;'),
    (Name: 'SplitButton'; Category: 'Menus and toolbars';
      Description: 'One primary action with a separate native flyout.';
      Xaml: '<SplitButton x:Name="SampleSplitButton" Content="Export"><SplitButton.Flyout><MenuFlyout><MenuFlyoutItem Text="As image"/><MenuFlyoutItem Text="As document"/></MenuFlyout></SplitButton.Flyout></SplitButton>';
      Pascal: 'SampleSplitButton.Content := ''Export selection'';'),
    (Name: 'HyperlinkButton'; Category: 'Basic input';
      Description: 'A keyboard accessible link with native pointer feedback.';
      Xaml: '<HyperlinkButton x:Name="SampleHyperlinkButton" Content="A native hyperlink" Click="ExplorerButtonClick"/>';
      Pascal: 'SampleHyperlinkButton.Content := ''Read more'';'),
    (Name: 'TextBox'; Category: 'Text';
      Description: 'Plain text editing with native selection and clipboard support.';
      Xaml: '<TextBox x:Name="SampleTextBox" Header="Your idea" PlaceholderText="Type something" Text="Made with Delphi"/>';
      Pascal: 'SampleTextBox.Text := ''Hello, WinUI'';'),
    (Name: 'PasswordBox'; Category: 'Text';
      Description: 'A password field with the native reveal button.';
      Xaml: '<PasswordBox x:Name="SamplePasswordBox" Header="Sample password" PlaceholderText="Enter a sample password"/>';
      Pascal: '// Keep passwords out of logs and status labels.'#13#10 +
      'SamplePasswordBox.Password := '''';'),
    (Name: 'RichEditBox'; Category: 'Text';
      Description: 'Rich text editing and its native editing flyout.';
      Xaml: '<RichEditBox x:Name="SampleRichEditBox" Header="A richer canvas" Height="120" PlaceholderText="Write, select text, then open the editing menu"/>';
      Pascal: 'SampleRichEditBox.IsReadOnly := False;'),
    (Name: 'NumberBox'; Category: 'Basic input';
      Description: 'Typed numeric input, bounds and inline spin buttons.';
      Xaml: '<NumberBox x:Name="SampleNumberBox" Header="Quantity" Value="12" Minimum="0" Maximum="100" SpinButtonPlacementMode="Inline"/>';
      Pascal: 'SampleNumberBox.Value := 42;'),
    (Name: 'Slider'; Category: 'Basic input';
      Description: 'A continuous value with native keyboard and pointer support.';
      Xaml: '<Slider x:Name="SampleSlider" Minimum="0" Maximum="100" Value="64" StepFrequency="1" AutomationProperties.Name="Sample intensity"/>';
      Pascal: 'SampleSlider.Value := 75;'),
    (Name: 'ToggleSwitch'; Category: 'Basic input';
      Description: 'An on/off setting with built-in accessible state.';
      Xaml: '<ToggleSwitch x:Name="SampleToggleSwitch" Header="Notifications" OnContent="Enabled" OffContent="Disabled" IsOn="True"/>';
      Pascal: 'SampleToggleSwitch.IsOn := True;'),
    (Name: 'CheckBox'; Category: 'Basic input';
      Description: 'A native three-state option.';
      Xaml: '<CheckBox x:Name="SampleCheckBox" Content="Include subfolders" IsThreeState="True"/>';
      Pascal: 'SampleCheckBox.IsThreeState := True;'),
    (Name: 'RadioButtons'; Category: 'Basic input';
      Description: 'A mutually exclusive choice with native arrow-key navigation.';
      Xaml: '<RadioButtons x:Name="SampleRadioButtons" Header="Density" SelectedIndex="0"><RadioButton Content="Comfortable"/><RadioButton Content="Compact"/></RadioButtons>';
      Pascal: 'SampleRadioButtons.SelectedIndex := 1;'),
    (Name: 'ComboBox'; Category: 'Basic input';
      Description: 'A compact choice with a native popup.';
      Xaml: '<ComboBox x:Name="SampleComboBox" Header="Workspace" SelectedIndex="0" HorizontalAlignment="Stretch"><ComboBoxItem Content="Design"/><ComboBoxItem Content="Code"/><ComboBoxItem Content="Explore"/></ComboBox>';
      Pascal: 'SampleComboBox.SelectedIndex := 1;'),
    (Name: 'ListBox'; Category: 'Collections';
      Description: 'A simple selection list.';
      Xaml: '<ListBox x:Name="SampleListBox" SelectedIndex="0"><ListBoxItem Content="Create a window"/><ListBoxItem Content="Drop a control"/><ListBoxItem Content="Write Pascal"/></ListBox>';
      Pascal: 'SampleListBox.SelectedIndex := 2;'),
    (Name: 'GridView'; Category: 'Collections';
      Description: 'A native collection that lays items out in a grid.';
      Xaml: '<GridView x:Name="SampleGridView" SelectionMode="Single" Height="160"><GridViewItem><Border Background="{ThemeResource AccentFillColorDefaultBrush}" Padding="20"><TextBlock Text="Design"/></Border></GridViewItem><GridViewItem><Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" Padding="20"><TextBlock Text="Code"/></Border></GridViewItem></GridView>';
      Pascal: 'SampleGridView.SelectedIndex := 0;'),
    (Name: 'Expander'; Category: 'Layout';
      Description: 'Collapsible content with built-in transitions.';
      Xaml: '<Expander x:Name="SampleExpander" Header="Details" HorizontalAlignment="Stretch"><TextBlock Text="Native controls. Object Pascal events." TextWrapping="Wrap"/></Expander>';
      Pascal: 'SampleExpander.IsExpanded := True;'),
    (Name: 'TabView'; Category: 'Navigation';
      Description: 'Document-style tabs.';
      Xaml: '<TabView x:Name="SampleTabView" IsAddTabButtonVisible="False" Height="170"><TabViewItem Header="Design" IsClosable="False"><TextBlock Text="Your XAML surface" Margin="12"/></TabViewItem><TabViewItem Header="Code" IsClosable="False"><TextBlock Text="Your Object Pascal" Margin="12"/></TabViewItem></TabView>';
      Pascal: 'SampleTabView.SelectedIndex := 1;'),
    (Name: 'CalendarDatePicker'; Category: 'Date and time';
      Description: 'Pick a date in the native calendar popup.';
      Xaml: '<CalendarDatePicker x:Name="SampleCalendarDatePicker" Header="Start date" PlaceholderText="Choose a date"/>';
      Pascal: 'SampleCalendarDatePicker.PlaceholderText := ''Choose your date'';'),
    (Name: 'DatePicker'; Category: 'Date and time';
      Description: 'Localized date fields and the native date flyout.';
      Xaml: '<DatePicker x:Name="SampleDatePicker" Header="Date"/>';
      Pascal: 'SampleDatePicker.DayVisible := True;'),
    (Name: 'TimePicker'; Category: 'Date and time';
      Description: 'A native time picker with minute increments.';
      Xaml: '<TimePicker x:Name="SampleTimePicker" Header="Reminder" MinuteIncrement="5"/>';
      Pascal: 'SampleTimePicker.MinuteIncrement := 5;'),
    (Name: 'ProgressBar'; Category: 'Feedback';
      Description: 'Determinate progress using the active Windows accent color.';
      Xaml: '<ProgressBar x:Name="SampleProgressBar" Minimum="0" Maximum="100" Value="65" AutomationProperties.Name="Sample progress"/>';
      Pascal: 'SampleProgressBar.Value := 80;'),
    (Name: 'ProgressRing'; Category: 'Feedback';
      Description: 'An animated native activity indicator.';
      Xaml: '<ProgressRing x:Name="SampleProgressRing" IsActive="True" Width="48" Height="48" HorizontalAlignment="Left" AutomationProperties.Name="Working"/>';
      Pascal: 'SampleProgressRing.IsActive := True;'),
    (Name: 'RatingControl'; Category: 'Basic input';
      Description: 'A native rating with keyboard and pointer input.';
      Xaml: '<RatingControl x:Name="SampleRatingControl" Caption="Rate this idea" Value="4" MaxRating="5"/>';
      Pascal: 'SampleRatingControl.Value := 5;'),
    (Name: 'ColorPicker'; Category: 'Color';
      Description: 'A native spectrum, channel sliders and hex input.';
      Xaml: '<ColorPicker x:Name="SampleColorPicker" Color="#FF0078D4" IsAlphaEnabled="True"/>';
      Pascal: '// Color is the TWinUIColor record (A, R, G, B).'#13#10 +
      'SampleColorPicker.IsAlphaEnabled := True;'),
    (Name: 'InfoBar'; Category: 'Feedback';
      Description: 'Status with native severity colors and a close button.';
      Xaml: '<InfoBar x:Name="SampleInfoBar" IsOpen="True" Severity="Success" Title="Ready" Message="Built with Delphi and WinUI 3." IsClosable="False"/>';
      Pascal: 'SampleInfoBar.Severity := TWinUIInfoBarSeverity.Warning;'),
    (Name: 'MenuBar'; Category: 'Menus and toolbars';
      Description: 'Native menus with keyboard navigation.';
      Xaml: '<MenuBar x:Name="SampleMenuBar"><MenuBarItem Title="File"><MenuFlyoutItem Text="New"/><MenuFlyoutItem Text="Open"/></MenuBarItem><MenuBarItem Title="Help"><MenuFlyoutItem Text="About"/></MenuBarItem></MenuBar>';
      Pascal: '// Handle MenuFlyoutItem.OnClick from Pascal.'#13#10 +
      'SampleMenuBar.IsEnabled := True;'),
    (Name: 'CommandBar'; Category: 'Menus and toolbars';
      Description: 'A native command surface with an overflow menu.';
      Xaml: '<CommandBar x:Name="SampleCommandBar" DefaultLabelPosition="Bottom"><AppBarButton Icon="Save" Label="Save"/><AppBarButton Icon="Edit" Label="Edit"/><CommandBar.SecondaryCommands><AppBarButton Label="More options"/></CommandBar.SecondaryCommands></CommandBar>';
      Pascal: 'SampleCommandBar.IsOpen := True;'),
    (Name: 'PersonPicture'; Category: 'Identity';
      Description: 'An initials avatar that follows the Windows theme.';
      Xaml: '<PersonPicture x:Name="SamplePersonPicture" DisplayName="Delphi Developer" Width="88" Height="88" HorizontalAlignment="Left"/>';
      Pascal: 'SamplePersonPicture.DisplayName := ''Ali'';'),
    (Name: 'TextBlock'; Category: 'Text';
      Description: 'Selectable, wrapping text with native typography.';
      Xaml: '<TextBlock x:Name="SampleTextBlock" Text="A native canvas for your ideas." FontSize="28" FontWeight="SemiBold" TextWrapping="Wrap" IsTextSelectionEnabled="True"/>';
      Pascal: 'SampleTextBlock.Text := ''Think Delphi. Build native.'';'));

function FindControlDemo(const AQuery: string): Integer;

implementation

uses System.SysUtils;

function FindControlDemo(const AQuery: string): Integer;
var
  I: Integer;
  Query: string;
begin
  Result := -1;
  Query := LowerCase(Trim(AQuery));
  if Query = '' then Exit;
  for I := 0 to High(ControlDemos) do
    if SameText(ControlDemos[I].Name, Query) then Exit(I);
  for I := 0 to High(ControlDemos) do
    if LowerCase(ControlDemos[I].Name).Contains(Query) then Exit(I);
end;

end.
