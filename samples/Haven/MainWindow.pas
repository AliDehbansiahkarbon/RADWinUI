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
    procedure SmokeTick(Sender: TObject);
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    procedure GoalClick(Sender: TObject; E: TWinUIItemClickEventArgs);
    procedure NewGoalClick(Sender: TObject);
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils;

const
  AddAmount = 100;

constructor TMainWindow.Create;
begin
  inherited;
  ViewModel := TMainViewModel.Create;
  GoalGrid.ItemsSource := ViewModel.Goals;
  SetTitleBar(DragRegion);
  AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.Light;
  if FindCmdLineSwitch('smoke-test') then
  begin
    FTimer := TWinUITimer.Create;
    FTimer.Interval := 500;
    FTimer.OnTimer := SmokeTick;
    FTimer.Enabled := True;
  end;
end;

destructor TMainWindow.Destroy;
begin
  FTimer.Free;
  ViewModel.Free;
  inherited;
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
      if ViewModel.Goals[I].IsNewCard then
        ViewModel.AddGoal
      else
        ViewModel.AddMoney(I, AddAmount);
      Exit;
    end;
end;

procedure TMainWindow.NewGoalClick(Sender: TObject);
begin
  ViewModel.AddGoal;
end;

procedure TMainWindow.SmokeTick(Sender: TObject);
begin
  Inc(FSmokeStep);
  try
    case FSmokeStep of
      2:
        begin
          if (TotalLabel.Text <> '$10,937.95') or (AutoSaveLabel.Text <> '2 on') or
            (ProgressLabel.Text <> '45% of $24,300 across 5 goals') or (WelcomeText.Text <> 'Welcome, Alex') then
            raise Exception.Create('Initial bindings show ' + TotalLabel.Text + ' / ' + AutoSaveLabel.Text + ' / ' +
              ProgressLabel.Text + ' / ' + WelcomeText.Text);
          ViewModel.AddMoney(0, AddAmount);
          SweepSwitch.IsOn := True; // two-way: the view model and the "N on" pill follow
          NewGoalClick(nil);
        end;
      4:
        begin
          if (TotalLabel.Text <> '$11,037.95') or (ViewModel.Goals[0].PercentText <> '77%') then
            raise Exception.Create('Add money did not update the total or the goal: ' + TotalLabel.Text);
          if (AutoSaveLabel.Text <> '3 on') or not ViewModel.SmartSweep then
            raise Exception.Create('The Smart sweep toggle did not reach the view model: ' + AutoSaveLabel.Text);
          if (ViewModel.GoalCount <> 6) or not ViewModel.Goals[ViewModel.Goals.Count - 1].IsNewCard then
            raise Exception.Create('New goal was not inserted before the New goal card');
          TFile.WriteAllText(ParamStr(2), 'PASS: glass dashboard, totals, goal rings, add money, two-way toggles, new goal');
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
