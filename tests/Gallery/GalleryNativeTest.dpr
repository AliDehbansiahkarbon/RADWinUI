program GalleryNativeTest;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows, System.SysUtils,
  RADWinUI.Forms, RADWinUI.Xaml,
  RADWinUI.Gallery.Catalog in '..\..\samples\Gallery\RADWinUI.Gallery.Catalog.pas',
  MainViewModel in '..\..\samples\Gallery\MainViewModel.pas',
  MainWindow.Xaml in '..\..\samples\Gallery\MainWindow.Xaml.pas',
  MainWindow in '..\..\samples\Gallery\MainWindow.pas';

type
  TGalleryTestWindow = class(TMainWindow)
  private
    FTestTimer: TWinUITimer;
    FStep: Integer;
    procedure Check(ACondition: Boolean; const AMessage: string);
    procedure TestStep(Sender: TObject);
  public
    constructor Create; override;
    destructor Destroy; override;
    class procedure Failed(Sender: TObject; E: Exception);
  end;

procedure TGalleryTestWindow.Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then raise Exception.Create(AMessage);
end;

class procedure TGalleryTestWindow.Failed(Sender: TObject; E: Exception);
begin
  Writeln('FAILED: ', E.ClassName, ': ', E.Message);
  Flush(Output);
  ExitProcess(1);
end;

constructor TGalleryTestWindow.Create;
begin
  inherited;
  FTestTimer := TWinUITimer.Create;
  FTestTimer.Interval := 100;
  FTestTimer.OnTimer := TestStep;
  FTestTimer.Enabled := True;
end;

destructor TGalleryTestWindow.Destroy;
begin
  FTestTimer.Free;
  inherited;
end;

procedure TGalleryTestWindow.TestStep(Sender: TObject);
var
  I, Visible: Integer;
  Panel: TWinUIStackPanel;
  Control: TWinUIUIElement;
begin
  try
    if FStep = 0 then
    begin
      Check(ExplorerList.Items.Count = Length(ControlDemos), 'catalog count');
      Check(ExplorerSamples.Children.Count = Length(ControlDemos), 'live sample count');
      Navigation.SelectedItem := NavExplorer;
      Check(PageTitle.Text = 'Control explorer', 'explorer navigation');
      Writeln('[ok] full Gallery XAML loads and control explorer opens');
    end;
    if FStep <= High(ControlDemos) then
    begin
      ExplorerList.SelectedIndex := FStep;
      ExplorerSelectionChanged(Self, nil);
      Check(ControlTitle.Text = ControlDemos[FStep].Name, 'control selection');
      Check(XamlSource.Text = ControlDemos[FStep].Xaml, 'XAML source');
      // WinUI TextBox canonicalizes CRLF input to CR in its Text getter.
      Check(PascalSource.Text = ControlDemos[FStep].Pascal.Replace(#13#10, #13), 'Pascal source');
      Visible := 0;
      for I := 0 to ExplorerSamples.Children.Count - 1 do
      begin
        Panel := ExplorerSamples.Children[I] as TWinUIStackPanel;
        if Panel.Visibility = TWinUIVisibility.Visible then
        begin
          Inc(Visible);
          Check(Panel.Tag.AsString = ControlDemos[FStep].Name, 'live sample identity');
          Control := Panel.Children[0];
          ExplorerEnabled.IsOn := False;
          ExplorerOptionsChanged(Self, nil);
          if Control is TWinUIControl then Check(not TWinUIControl(Control).IsEnabled, 'disabled sample');
          ExplorerEnabled.IsOn := True;
          ExplorerOptionsChanged(Self, nil);
          ExplorerFlow.SelectedIndex := 1;
          ExplorerFlowChanged(Self, nil);
          Check(ExplorerSamples.FlowDirection = TWinUIFlowDirection.RightToLeft, 'RTL sample');
          ExplorerFlow.SelectedIndex := 0;
          ExplorerFlowChanged(Self, nil);
        end;
      end;
      Check(Visible = 1, 'one live sample visible');
      Writeln('[ok] ', ControlDemos[FStep].Name, ': selection, source, enabled and RTL');
    end
    else
    begin
      ExplorerFilter.Text := 'TextBox';
      ExplorerFilterChanged(Self, nil);
      Check((ExplorerList.Items.Count = 1) and (ControlTitle.Text = 'TextBox'), 'name filtering');
      SampleTextBox.Text := 'Native Delphi test';
      ExplorerValueClick(Self);
      Check(ExplorerValue.Text.Contains('Native Delphi test'), 'Pascal text readout');
      ExplorerButtonClick(Self);
      Check(ExplorerValue.Text.Contains('1 sample clicks'), 'Pascal action');
      ExplorerFilter.Text := 'no-control-matches-this';
      ExplorerFilterChanged(Self, nil);
      Check((ExplorerList.Items.Count = 0) and (ExplorerSamples.Visibility = TWinUIVisibility.Collapsed), 'empty filter');
      ExplorerFilter.Text := '';
      ExplorerFilterChanged(Self, nil);
      Check(ExplorerList.Items.Count = Length(ControlDemos), 'reset filter');
      ThemeChoice.SelectedIndex := 1; ThemeChanged(Self, nil);
      Check(Surface.RequestedTheme = TWinUIElementTheme.Light, 'light theme');
      ThemeChoice.SelectedIndex := 2; ThemeChanged(Self, nil);
      Check(Surface.RequestedTheme = TWinUIElementTheme.Dark, 'dark theme');
      ThemeChoice.SelectedIndex := 0; ThemeChanged(Self, nil);
      Check(Surface.RequestedTheme = TWinUIElementTheme.Default, 'Windows theme');
      for I := 0 to 3 do
      begin
        BackdropChoice.SelectedIndex := I;
        BackdropChanged(Self, nil);
      end;
      Check(Backdrop = TWinUIBackdrop.None, 'solid fallback');
      Navigation.SelectedItem := NavInputs;
      Check(InputsPage.Visibility = TWinUIVisibility.Visible, 'input page');
      Navigation.SelectedItem := NavCollections;
      Check(CollectionsPage.Visibility = TWinUIVisibility.Visible, 'collection page');
      Navigation.SelectedItem := NavDates;
      Check(DatesPage.Visibility = TWinUIVisibility.Visible, 'dates page');
      Navigation.SelectedItem := NavFeedback;
      Check(FeedbackPage.Visibility = TWinUIVisibility.Visible, 'feedback page');
      Navigation.SelectedItem := NavLayout;
      Check(LayoutPage.Visibility = TWinUIVisibility.Visible, 'layout page');
      Navigation.SelectedItem := NavMaterials;
      Check(MaterialsPage.Visibility = TWinUIVisibility.Visible, 'materials page');
      Navigation.SelectedItem := NavBinding;
      Check(BindingPage.Visibility = TWinUIVisibility.Visible, 'binding page');
      IncrementClick(Self);
      Check(ViewModel.Count = 1, 'Pascal binding');
      Navigation.SelectedItem := NavHome;
      Check(HomePage.Visibility = TWinUIVisibility.Visible, 'overview page');
      Writeln('[ok] filters, Pascal readout/action, themes, four backdrops, all pages and binding');
      Writeln('Gallery native test PASSED (no mouse/keyboard automation)');
      Flush(Output);
      FTestTimer.Enabled := False;
      Close;
    end;
    Inc(FStep);
  except
    on E: Exception do Failed(Self, E);
  end;
end;

begin
  TWinUIApp.OnException := TGalleryTestWindow.Failed;
  try
    TWinUIApp.Run(TGalleryTestWindow);
  except
    on E: Exception do TGalleryTestWindow.Failed(nil, E);
  end;
end.
