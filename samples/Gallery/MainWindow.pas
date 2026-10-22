unit MainWindow;

interface

uses
  RADWinUI.Forms, RADWinUI.Framework, RADWinUI.Xaml,
  MainViewModel, MainWindow.Xaml, RADWinUI.Gallery.Catalog;

type
  TMainWindow = class(TMainWindowBase)
  private
    FTimer: TWinUITimer;
    FPages: array[0..8] of TWinUIFrameworkElement;
    FNavItems: array[0..8] of TWinUINavigationViewItem;
    FExplorerMatches: TArray<Integer>;
    FExplorerIndex, FSampleClicks: Integer;
    FFiltering: Boolean;
    FColorBrush: TWinUISolidColorBrush;
    FDialog: TWinUIContentDialog;
    FInitialized, FNavigating, FDialogOpen: Boolean;
    procedure Navigate(AIndex: Integer);
    procedure FilterControls;
    procedure SelectControl(AIndex: Integer);
    procedure ApplyExplorerOptions;
    function FindCategory(const AQuery: string): Integer;
    procedure Tick(Sender: TObject);
    procedure CopySource(const AText: string);
    procedure DialogClosed(Sender: TObject; E: TWinUIContentDialogClosedEventArgs);
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    procedure ExplorerFilterChanged(Sender: TObject; E: TWinUITextChangedEventArgs);
    procedure ExplorerSelectionChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
    procedure ExplorerOptionsChanged(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure ExplorerFlowChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
    procedure ExplorerValueClick(Sender: TObject);
    procedure ExplorerButtonClick(Sender: TObject);
    procedure NavigationChanged(Sender: TObject; E: TWinUINavigationViewSelectionChangedEventArgs);
    procedure CategoryClick(Sender: TObject);
    procedure SearchChanged(Sender: TObject; E: TWinUIAutoSuggestBoxTextChangedEventArgs);
    procedure SearchSubmitted(Sender: TObject; E: TWinUIAutoSuggestBoxQuerySubmittedEventArgs);
    procedure SearchSuggestionChosen(Sender: TObject; E: TWinUIAutoSuggestBoxSuggestionChosenEventArgs);
    procedure ThemeChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
    procedure BackdropChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
    procedure GreetClick(Sender: TObject);
    procedure IntensityChanged(Sender: TObject; E: TWinUIRangeBaseValueChangedEventArgs);
    procedure AddItemClick(Sender: TObject);
    procedure RemoveItemClick(Sender: TObject);
    procedure ListChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
    procedure FeedbackClick(Sender: TObject);
    procedure DialogClick(Sender: TObject);
    procedure ActivityChanged(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure ColorChanged(Sender: TObject; E: TWinUIColorChangedEventArgs);
    procedure IncrementClick(Sender: TObject);
    procedure ResetClick(Sender: TObject);
    procedure CopyXamlClick(Sender: TObject);
    procedure CopyPascalClick(Sender: TObject);
  end;

implementation

uses Winapi.Windows, System.SysUtils;

const
  Titles: array[0..8] of string = ('A native canvas for your ideas', 'Basic input',
    'Lists and collections', 'Date and time', 'Feedback and dialogs',
    'Layout and navigation', 'Materials and color', 'Live Pascal binding', 'Control explorer');
  Descriptions: array[0..8] of string = (
    'Explore real Windows controls, backed by Object Pascal.',
    'Text, choices, values and a familiar Pascal click handler.',
    'Create, select and remove items. Expand a native tree.',
    'Let Windows handle calendar navigation, date formats and time selection.',
    'Communicate state with native information bars, progress and dialogs.',
    'Arrange native controls with Grid, StackPanel, Expander and TabView.',
    'Explore desktop materials and handle color changes in Pascal.',
    'Connect native XAML to published Delphi properties, in both directions.',
    '30 native controls. Live examples, layout options and copyable XAML/Pascal.');
  Keywords: array[0..8] of string = ('overview home introduction',
    'basic input button textbox toggleswitch checkbox radiobutton slider numberbox combobox ratingcontrol progressbar',
    'lists collections listview treeview selection items add remove hierarchy',
    'date time calendar calendardatepicker datepicker timepicker calendarview',
    'feedback infobar progressring progressbar contentdialog flyout notifications',
    'layout navigation grid stackpanel expander tabview tabs',
    'materials color colorpicker mica acrylic backdrop brush theme',
    'live pascal binding two-way viewmodel counter published properties',
    'explorer all controls catalog samples individual reference');
  XamlExamples: array[1..7] of string = (
    '<Button Content="Say hello" Click="GreetClick"/>'#13#10 +
    '<Slider Value="64" ValueChanged="IntensityChanged"/>',
    '<ListView x:Name="DemoList"'#13#10 +
    '          SelectionChanged="ListChanged"/>'#13#10 +
    '<Button Content="Add" Click="AddItemClick"/>',
    '<CalendarDatePicker PlaceholderText="Choose a date"/>'#13#10 +
    '<DatePicker Header="Date picker"/>'#13#10 + '<TimePicker Header="Time picker"/>',
    '<InfoBar x:Name="FeedbackBar" IsOpen="True"'#13#10 +
    '         Severity="Success" Title="Saved"/>'#13#10 +
    '<Button Content="Open dialog" Click="DialogClick"/>',
    '<Grid ColumnSpacing="10">'#13#10 +
    '  <Grid.ColumnDefinitions>'#13#10 +
    '    <ColumnDefinition Width="2*"/>'#13#10 +
    '    <ColumnDefinition Width="*"/>'#13#10 +
    '  </Grid.ColumnDefinitions>'#13#10 + '</Grid>',
    '<Window Backdrop="Mica" ...>'#13#10 +
    '  <Grid Background="Transparent">'#13#10 +
    '    <ColorPicker ColorChanged="ColorChanged"/>'#13#10 +
    '  </Grid>'#13#10 + '</Window>',
    '<Window DataContextType="TMainViewModel" ...>'#13#10 +
    '  <TextBox Text="{Binding Name, Mode=TwoWay,'#13#10 +
    '                   UpdateSourceTrigger=PropertyChanged}"/>'#13#10 +
    '  <TextBlock Text="{Binding Summary}"/>'#13#10 + '</Window>');
  PascalExamples: array[1..7] of string = (
    'procedure TMainWindow.GreetClick(Sender: TObject);'#13#10 +
    'begin'#13#10 + '  GreetingText.Text := ''Hello, '' + NameEntry.Text + ''!'';'#13#10 + 'end;',
    'DemoList.Items.Add(NewItemText.Text);'#13#10 +
    '// Selection is a Delphi value:'#13#10 +
    'SelectionText.Text := DemoList.SelectedItem.AsString;'#13#10 +
    'DemoList.Items.Delete(DemoList.SelectedIndex);',
    '// No date parsing or custom popup is needed.'#13#10 +
    '// These controls provide native localization,'#13#10 +
    '// keyboard navigation and calendar interaction.'#13#10 +
    '// Subscribe to DateChanged or TimeChanged as needed.',
    'FDialog := TWinUIContentDialog.Create(Self);'#13#10 +
    'FDialog.Title := ''A native dialog'';'#13#10 +
    'FDialog.XamlRoot := Surface.XamlRoot;'#13#10 +
    'FDialog.PrimaryButtonText := ''Continue'';'#13#10 +
    'FDialog.CloseButtonText := ''Cancel'';'#13#10 +
    'FDialog.OnClosed := DialogClosed;'#13#10 + 'FDialog.ShowAsync;',
    '// The generated base exposes named XAML controls.'#13#10 +
    '// Set native properties directly from Pascal:'#13#10 +
    'IntensitySlider.Value := 75;'#13#10 +
    'HomePage.Visibility := TWinUIVisibility.Collapsed;'#13#10 +
    'InputsPage.Visibility := TWinUIVisibility.Visible;',
    'Backdrop := TWinUIBackdrop.Acrylic;'#13#10 +
    'Surface.RequestedTheme := TWinUIElementTheme.Default;'#13#10 +#13#10 +
    'procedure TMainWindow.ColorChanged(Sender: TObject;'#13#10 +
    '  E: TWinUIColorChangedEventArgs);'#13#10 +
    'begin'#13#10 + '  FColorBrush.Color := E.NewColor;'#13#10 + 'end;',
    'procedure TMainViewModel.SetName(const AValue: string);'#13#10 +
    'begin'#13#10 + '  FName := AValue;'#13#10 +
    '  Changed(''Name'');'#13#10 + '  Changed(''Summary'');'#13#10 + 'end;'#13#10 +#13#10 +
    '// An ordinary Delphi event updates the bound UI:'#13#10 +
    'ViewModel.Count := ViewModel.Count + 1;');

constructor TMainWindow.Create;
begin
  inherited;
  ViewModel := TMainViewModel.Create;
  SetTitleBar(DragRegion);
  AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.UseDefaultAppMode;
  FPages[0] := HomePage; FPages[1] := InputsPage; FPages[2] := CollectionsPage;
  FPages[3] := DatesPage; FPages[4] := FeedbackPage; FPages[5] := LayoutPage;
  FPages[6] := MaterialsPage; FPages[7] := BindingPage; FPages[8] := ExplorerPage;
  FNavItems[0] := NavHome; FNavItems[1] := NavInputs; FNavItems[2] := NavCollections;
  FNavItems[3] := NavDates; FNavItems[4] := NavFeedback; FNavItems[5] := NavLayout;
  FNavItems[6] := NavMaterials; FNavItems[7] := NavBinding; FNavItems[8] := NavExplorer;
  FColorBrush := TWinUISolidColorBrush.Create(Self);
  FColorBrush.Color := DemoColorPicker.Color;
  ColorSwatch.Background := FColorBrush;
  DemoList.Items.Add('Design a native window');
  DemoList.Items.Add('Write a Pascal event');
  DemoList.Items.Add('Explore Windows materials');
  FExplorerIndex := -1;
  FInitialized := True;
  FilterControls;
  Navigate(0);
  FTimer := TWinUITimer.Create;
  FTimer.Interval := 1000;
  FTimer.OnTimer := Tick;
  FTimer.Enabled := True;
end;

destructor TMainWindow.Destroy;
begin
  FTimer.Free;
  ViewModel.Free;
  inherited;
end;

procedure TMainWindow.Navigate(AIndex: Integer);
var
  I: Integer;
begin
  if not FInitialized or FNavigating or (AIndex < 0) or (AIndex > High(FPages)) then Exit;
  FNavigating := True;
  try
    for I := 0 to High(FPages) do
      if I = AIndex then FPages[I].Visibility := TWinUIVisibility.Visible
      else FPages[I].Visibility := TWinUIVisibility.Collapsed;
    Navigation.SelectedItem := FNavItems[AIndex];
    PageTitle.Text := Titles[AIndex];
    PageDescription.Text := Descriptions[AIndex];
    if AIndex = 0 then SourcePanel.Visibility := TWinUIVisibility.Collapsed
    else
    begin
      SourcePanel.Visibility := TWinUIVisibility.Visible;
      if AIndex = 8 then
      begin
        if FExplorerIndex >= 0 then SelectControl(FExplorerIndex);
      end
      else
      begin
        XamlSource.Text := XamlExamples[AIndex];
        PascalSource.Text := PascalExamples[AIndex];
      end;
    end;
    PageScroll.ScrollToVerticalOffset(0);
    StatusText.Text := 'Native WinUI 3. Object Pascal. Made with RADWinUI.';
  finally
    FNavigating := False;
  end;
end;

procedure TMainWindow.NavigationChanged(Sender: TObject; E: TWinUINavigationViewSelectionChangedEventArgs);
begin
  if E.SelectedItemContainer <> nil then Navigate(StrToIntDef(E.SelectedItemContainer.Tag.AsString, -1));
end;

procedure TMainWindow.CategoryClick(Sender: TObject);
begin
  Navigate(StrToIntDef(TWinUIButton(Sender).Tag.AsString, -1));
end;

function TMainWindow.FindCategory(const AQuery: string): Integer;
var
  Query: string;
  I: Integer;
begin
  Result := -1;
  Query := LowerCase(Trim(AQuery));
  if Query = '' then Exit;
  for I := 0 to High(Titles) do
    if LowerCase(Titles[I]).Contains(Query) or Keywords[I].Contains(Query) then Exit(I);
end;

procedure TMainWindow.SearchChanged(Sender: TObject; E: TWinUIAutoSuggestBoxTextChangedEventArgs);
var
  I: Integer;
  Query: string;
begin
  if not FInitialized or (E.Reason <> TWinUIAutoSuggestionBoxTextChangeReason.UserInput) then Exit;
  Query := LowerCase(Trim(SearchBox.Text));
  SearchBox.Items.Clear;
  for I := 0 to High(ControlDemos) do
    if (Query <> '') and LowerCase(ControlDemos[I].Name).Contains(Query) then
      SearchBox.Items.Add(ControlDemos[I].Name);
  for I := 0 to High(Titles) do
    if (Query = '') or LowerCase(Titles[I]).Contains(Query) or Keywords[I].Contains(Query) then
      SearchBox.Items.Add(Titles[I]);
end;

procedure TMainWindow.SearchSuggestionChosen(Sender: TObject; E: TWinUIAutoSuggestBoxSuggestionChosenEventArgs);
begin
  SearchBox.Text := E.SelectedItem.AsString;
end;

procedure TMainWindow.SearchSubmitted(Sender: TObject; E: TWinUIAutoSuggestBoxQuerySubmittedEventArgs);
var
  Index: Integer;
begin
  Index := FindControlDemo(E.QueryText);
  if Index >= 0 then
  begin
    ExplorerFilter.Text := ControlDemos[Index].Name;
    Navigate(8);
    SelectControl(Index);
  end
  else
  begin
    Index := FindCategory(E.QueryText);
    if Index >= 0 then Navigate(Index)
    else StatusText.Text := 'No demo matches "' + E.QueryText + '".';
  end;
  SearchBox.IsSuggestionListOpen := False;
end;

procedure TMainWindow.ThemeChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
begin
  if not FInitialized then Exit;
  case ThemeChoice.SelectedIndex of
    1: begin Surface.RequestedTheme := TWinUIElementTheme.Light; AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.Light; end;
    2: begin Surface.RequestedTheme := TWinUIElementTheme.Dark; AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.Dark; end;
  else
    Surface.RequestedTheme := TWinUIElementTheme.Default;
    AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.UseDefaultAppMode;
  end;
end;

procedure TMainWindow.BackdropChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
begin
  if not FInitialized then Exit;
  case BackdropChoice.SelectedIndex of
    0: Backdrop := TWinUIBackdrop.Mica;
    1: Backdrop := TWinUIBackdrop.MicaAlt;
    2: Backdrop := TWinUIBackdrop.Acrylic;
    3: Backdrop := TWinUIBackdrop.None;
  end;
  if BackdropChoice.SelectedIndex = 3 then SolidLayer.Visibility := TWinUIVisibility.Visible
  else SolidLayer.Visibility := TWinUIVisibility.Collapsed;
end;

procedure TMainWindow.GreetClick(Sender: TObject);
var
  Name: string;
begin
  Name := Trim(NameEntry.Text);
  if Name = '' then Name := 'Delphi developer';
  GreetingText.Text := 'Hello, ' + Name + '! This event was handled by Object Pascal.';
end;

procedure TMainWindow.IntensityChanged(Sender: TObject; E: TWinUIRangeBaseValueChangedEventArgs);
begin
  if not FInitialized then Exit;
  IntensityProgress.Value := E.NewValue;
  VolumeText.Text := Format('Intensity: %.0f%%', [E.NewValue]);
end;

procedure TMainWindow.AddItemClick(Sender: TObject);
var
  Text: string;
begin
  Text := Trim(NewItemText.Text);
  if Text = '' then Exit;
  DemoList.Items.Add(Text);
  DemoList.SelectedIndex := DemoList.Items.Count - 1;
  NewItemText.Text := '';
end;

procedure TMainWindow.RemoveItemClick(Sender: TObject);
begin
  if DemoList.SelectedIndex >= 0 then DemoList.Items.Delete(DemoList.SelectedIndex);
end;

procedure TMainWindow.ListChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
begin
  if DemoList.SelectedIndex >= 0 then SelectionText.Text := 'Selected: ' + DemoList.SelectedItem.AsString
  else SelectionText.Text := 'Choose an item to inspect the selection.';
end;

procedure TMainWindow.FeedbackClick(Sender: TObject);
begin
  FeedbackBar.IsOpen := True;
  if TWinUIButton(Sender).Tag.AsString = 'success' then
  begin
    FeedbackBar.Severity := TWinUIInfoBarSeverity.Success;
    FeedbackBar.Title := 'Everything is ready';
    FeedbackBar.Message := 'A Pascal handler changed this native InfoBar.';
  end
  else
  begin
    FeedbackBar.Severity := TWinUIInfoBarSeverity.Warning;
    FeedbackBar.Title := 'Something needs your attention';
    FeedbackBar.Message := 'The icon, colors and close button come from WinUI.';
  end;
end;

procedure TMainWindow.DialogClick(Sender: TObject);
begin
  if FDialogOpen then Exit;
  if FDialog = nil then
  begin
    FDialog := TWinUIContentDialog.Create(Self);
    FDialog.Title := 'A native Windows dialog';
    FDialog.Content := 'Created in Object Pascal, hosted by WinUI. Continue to report the result back to Delphi.';
    FDialog.PrimaryButtonText := 'Continue';
    FDialog.CloseButtonText := 'Cancel';
    FDialog.DefaultButton := TWinUIContentDialogButton.Primary;
    FDialog.OnClosed := DialogClosed;
  end;
  FDialog.XamlRoot := Surface.XamlRoot;
  FDialog.RequestedTheme := Surface.RequestedTheme;
  FDialogOpen := True;
  try
    FDialog.ShowAsync;
  except
    FDialogOpen := False;
    raise;
  end;
end;

procedure TMainWindow.DialogClosed(Sender: TObject; E: TWinUIContentDialogClosedEventArgs);
begin
  FDialogOpen := False;
  FeedbackBar.IsOpen := True;
  FeedbackBar.Severity := TWinUIInfoBarSeverity.Informational;
  FeedbackBar.Title := 'Dialog result received';
  if E.Result = TWinUIContentDialogResult.Primary then FeedbackBar.Message := 'Continue was selected.'
  else FeedbackBar.Message := 'The dialog was cancelled.';
end;

procedure TMainWindow.ActivityChanged(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  if not FInitialized then Exit;
  ActivityRing.IsActive := ActivitySwitch.IsOn;
  ActivityProgress.IsIndeterminate := ActivitySwitch.IsOn;
  if not ActivitySwitch.IsOn then ActivityProgress.Value := 100;
end;

procedure TMainWindow.ColorChanged(Sender: TObject; E: TWinUIColorChangedEventArgs);
var
  Color: TWinUIColor;
begin
  if not FInitialized then Exit;
  Color := E.NewColor;
  FColorBrush.Color := Color;
  ColorValue.Text := Format('#%.2x%.2x%.2x%.2x', [Color.A, Color.R, Color.G, Color.B]);
end;

procedure TMainWindow.IncrementClick(Sender: TObject);
begin
  ViewModel.Count := ViewModel.Count + 1;
end;

procedure TMainWindow.ResetClick(Sender: TObject);
begin
  ViewModel.Count := 0;
end;

procedure TMainWindow.FilterControls;
var
  I: Integer;
  Query: string;
begin
  if not FInitialized then Exit;
  FFiltering := True;
  try
    Query := LowerCase(Trim(ExplorerFilter.Text));
    ExplorerList.Items.Clear;
    FExplorerMatches := nil;
    for I := 0 to High(ControlDemos) do
      if (Query = '') or LowerCase(ControlDemos[I].Name).Contains(Query) or
        LowerCase(ControlDemos[I].Category).Contains(Query) then
      begin
        FExplorerMatches := FExplorerMatches + [I];
        ExplorerList.Items.Add(ControlDemos[I].Name);
      end;
    ExplorerCount.Text := Format('%d of %d controls', [Length(FExplorerMatches), Length(ControlDemos)]);
  finally
    FFiltering := False;
  end;
  if Length(FExplorerMatches) > 0 then
  begin
    ExplorerList.SelectedIndex := 0;
    SelectControl(FExplorerMatches[0]);
  end
  else
  begin
    ControlDescription.Text := 'No control matches this filter. Clear the filter to browse all controls.';
    ExplorerSamples.Visibility := TWinUIVisibility.Collapsed;
    FExplorerIndex := -1;
    XamlSource.Text := '';
    PascalSource.Text := '';
  end;
end;

procedure TMainWindow.SelectControl(AIndex: Integer);
var
  I: Integer;
  Demo: TControlDemo;
  Panel: TWinUIFrameworkElement;
begin
  if (AIndex < 0) or (AIndex > High(ControlDemos)) then Exit;
  FExplorerIndex := AIndex;
  Demo := ControlDemos[AIndex];
  ControlTitle.Text := Demo.Name;
  ControlCategory.Text := Demo.Category;
  ControlDescription.Text := Demo.Description;
  ExplorerSamples.Visibility := TWinUIVisibility.Visible;
  for I := 0 to ExplorerSamples.Children.Count - 1 do
  begin
    Panel := ExplorerSamples.Children[I] as TWinUIFrameworkElement;
    if Panel.Tag.AsString = Demo.Name then Panel.Visibility := TWinUIVisibility.Visible
    else Panel.Visibility := TWinUIVisibility.Collapsed;
  end;
  XamlSource.Text := Demo.Xaml;
  PascalSource.Text := Demo.Pascal;
  ExplorerValue.Text := 'Interact with the sample, then read its value in Pascal.';
  ApplyExplorerOptions;
end;

procedure TMainWindow.ApplyExplorerOptions;
var
  I: Integer;
  Panel: TWinUIStackPanel;
  Element: TWinUIUIElement;
begin
  if not FInitialized then Exit;
  for I := 0 to ExplorerSamples.Children.Count - 1 do
  begin
    Panel := ExplorerSamples.Children[I] as TWinUIStackPanel;
    Panel.IsHitTestVisible := ExplorerEnabled.IsOn;
    Element := Panel.Children[0];
    if Element is TWinUIControl then TWinUIControl(Element).IsEnabled := ExplorerEnabled.IsOn;
  end;
  SampleTextBlock.IsTextSelectionEnabled := ExplorerEnabled.IsOn;
  if ExplorerFlow.SelectedIndex = 1 then ExplorerSamples.FlowDirection := TWinUIFlowDirection.RightToLeft
  else ExplorerSamples.FlowDirection := TWinUIFlowDirection.LeftToRight;
end;

procedure TMainWindow.ExplorerFilterChanged(Sender: TObject; E: TWinUITextChangedEventArgs);
begin
  FilterControls;
end;

procedure TMainWindow.ExplorerSelectionChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
begin
  if FFiltering or (ExplorerList.SelectedIndex < 0) or
    (ExplorerList.SelectedIndex >= Length(FExplorerMatches)) then Exit;
  SelectControl(FExplorerMatches[ExplorerList.SelectedIndex]);
end;

procedure TMainWindow.ExplorerOptionsChanged(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  ApplyExplorerOptions;
end;

procedure TMainWindow.ExplorerFlowChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
begin
  ApplyExplorerOptions;
end;

procedure TMainWindow.ExplorerButtonClick(Sender: TObject);
begin
  Inc(FSampleClicks);
  ExplorerValue.Text := Format('Pascal received %d sample clicks.', [FSampleClicks]);
  StatusText.Text := ExplorerValue.Text;
end;

procedure TMainWindow.ExplorerValueClick(Sender: TObject);
var
  Name, Value: string;
begin
  if FExplorerIndex < 0 then Exit;
  Name := ControlDemos[FExplorerIndex].Name;
  if Name = 'TextBox' then Value := SampleTextBox.Text
  else if Name = 'PasswordBox' then Value := 'Password content is kept private.'
  else if Name = 'NumberBox' then Value := FloatToStr(SampleNumberBox.Value)
  else if Name = 'Slider' then Value := FloatToStr(SampleSlider.Value)
  else if Name = 'ToggleSwitch' then Value := BoolToStr(SampleToggleSwitch.IsOn, True)
  else if Name = 'ComboBox' then Value := IntToStr(SampleComboBox.SelectedIndex)
  else if Name = 'ListBox' then Value := IntToStr(SampleListBox.SelectedIndex)
  else if Name = 'GridView' then Value := IntToStr(SampleGridView.SelectedIndex)
  else if Name = 'RadioButtons' then Value := IntToStr(SampleRadioButtons.SelectedIndex)
  else if Name = 'RatingControl' then Value := FloatToStr(SampleRatingControl.Value)
  else if Name = 'TextBlock' then Value := SampleTextBlock.Text
  else Value := Format('%d Pascal sample clicks; enabled: %s', [FSampleClicks, BoolToStr(ExplorerEnabled.IsOn, True)]);
  ExplorerValue.Text := Name + ': ' + Value;
end;

procedure TMainWindow.Tick(Sender: TObject);
begin
  ViewModel.RefreshClock;
end;

procedure TMainWindow.CopySource(const AText: string);
var
  Memory: HGLOBAL;
  Data: Pointer;
  Size: NativeUInt;
  Text: string;
begin
  Text := AText.Replace(#13#10, #10).Replace(#13, #10).Replace(#10, #13#10);
  if not OpenClipboard(HWND(AppWindow.Id.Value)) then
  begin
    StatusText.Text := 'Clipboard is busy. Try Copy again.';
    Exit;
  end;
  Memory := 0;
  try
    Size := (Length(Text) + 1) * SizeOf(Char);
    Memory := GlobalAlloc(GMEM_MOVEABLE, Size);
    if Memory = 0 then RaiseLastOSError;
    Data := GlobalLock(Memory);
    if Data = nil then RaiseLastOSError;
    try
      Move(PChar(Text)^, Data^, Size);
    finally
      GlobalUnlock(Memory);
    end;
    if not EmptyClipboard then RaiseLastOSError;
    if SetClipboardData(CF_UNICODETEXT, Memory) = 0 then RaiseLastOSError;
    Memory := 0; // Windows owns it after SetClipboardData succeeds.
    StatusText.Text := 'Source copied to the clipboard.';
  finally
    if Memory <> 0 then GlobalFree(Memory);
    CloseClipboard;
  end;
end;

procedure TMainWindow.CopyXamlClick(Sender: TObject);
begin
  CopySource(XamlSource.Text);
end;

procedure TMainWindow.CopyPascalClick(Sender: TObject);
begin
  CopySource(PascalSource.Text);
end;

end.

