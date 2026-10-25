unit MainWindow;

interface

uses
  RADWinUI.Forms,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  MainViewModel,
  MainWindow.Xaml;

type
  TMainWindow = class(TMainWindowBase)
  private
    FTimer: TWinUITimer;
    FSmokeStep: Integer;
    procedure TimerTick(Sender: TObject);
    procedure SmokeStep;
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    procedure GoalClick(Sender: TObject; E: TWinUIItemClickEventArgs);
    procedure AddMoneyClick(Sender: TObject);
    procedure PlayClick(Sender: TObject);
    procedure PauseClick(Sender: TObject);
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils;

const
  AddAmount = 50;

constructor TMainWindow.Create;
begin
  inherited;
  ViewModel := TMainViewModel.Create;
  GoalList.ItemsSource := ViewModel.Goals;
  SetTitleBar(DragRegion);
  AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.UseDefaultAppMode;
  // -light and -dark pick a theme without changing the Windows setting, for screenshots
  if FindCmdLineSwitch('light') then
  begin
    Surface.RequestedTheme := TWinUIElementTheme.Light;
    AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.Light;
  end
  else if FindCmdLineSwitch('dark') then
  begin
    Surface.RequestedTheme := TWinUIElementTheme.Dark;
    AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.Dark;
  end;
  FTimer := TWinUITimer.Create;
  FTimer.Interval := 1000;
  FTimer.OnTimer := TimerTick;
  FTimer.Enabled := True;
end;

destructor TMainWindow.Destroy;
begin
  FTimer.Free;
  ViewModel.Free;
  inherited;
end;

procedure TMainWindow.TimerTick(Sender: TObject);
begin
  ViewModel.Tick;
  if FindCmdLineSwitch('smoke-test') then
    SmokeStep;
end;

procedure TMainWindow.GoalClick(Sender: TObject; E: TWinUIItemClickEventArgs);
var
  Clicked: IInterface;
  I: Integer;
begin
  // The clicked item is the WinRT object XAML sees, so compare COM identities
  Clicked := E.ClickedItem.Obj as IInterface;
  for I := 0 to ViewModel.Goals.Count - 1 do
    if (ViewModel.Goals.BindableAt(I) as IInterface) = Clicked then
    begin
      ViewModel.ToggleGoal(I);
      Exit;
    end;
end;

procedure TMainWindow.AddMoneyClick(Sender: TObject);
begin
  ViewModel.AddMoney(AddAmount);
end;

procedure TMainWindow.PlayClick(Sender: TObject);
begin
  ViewModel.Start;
end;

procedure TMainWindow.PauseClick(Sender: TObject);
begin
  ViewModel.Pause;
end;

procedure TMainWindow.SmokeStep;
begin
  Inc(FSmokeStep);
  try
    case FSmokeStep of
      1:
        begin
          if (TotalLabel.Text <> '$10,937') or (WeekLabel.Text <> '$610') or (GoalCaptionLabel.Text <> '2/5') or
            (AutoSaveLabel.Text <> '2 on') or (CountdownLabel.Text <> '02:35') then
            raise Exception.Create('Initial bindings show ' + TotalLabel.Text + ' / ' + WeekLabel.Text + ' / ' +
              GoalCaptionLabel.Text + ' / ' + AutoSaveLabel.Text + ' / ' + CountdownLabel.Text);
          ViewModel.ToggleGoal(2);
          AddMoneyClick(nil);
          PlayClick(nil);
          RulesExpander.IsExpanded := True; // the toggles bind once the expander shows them
        end;
      2:
        SweepSwitch.IsOn := True; // two-way: the view model and the "N on" pill follow
      4:
        begin
          if (GoalCaptionLabel.Text <> '3/5') or not ViewModel.Goals[2].Done then
            raise Exception.Create('Toggling a goal did not update the caption: ' + GoalCaptionLabel.Text);
          if (AutoSaveLabel.Text <> '3 on') or not ViewModel.SmartSweep then
            raise Exception.Create('The Smart sweep toggle did not reach the view model: ' + AutoSaveLabel.Text);
          if (TotalLabel.Text <> '$10,987') or (WeekLabel.Text <> '$660') then
            raise Exception.Create('Add money did not update the totals: ' + TotalLabel.Text + ' / ' + WeekLabel.Text);
          if CountdownLabel.Text = '02:35' then
            raise Exception.Create('The countdown did not run');
          TFile.WriteAllText(ParamStr(2), 'PASS: bento dashboard, totals, goal toggle, two-way toggles, add money, countdown');
          Close;
        end;
    end;
  except
    on E: Exception do
    begin
      TFile.WriteAllText(ParamStr(2), 'FAIL: ' + E.Message);
      Close;
    end;
  end;
end;

end.
