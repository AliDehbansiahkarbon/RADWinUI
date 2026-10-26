unit MainWindow;

{ Lucent's window: page navigation with staggered entrances, charts drawn in
  Pascal, a hover tooltip, a hero move from an app card to its detail page,
  drag and drop on the release board, and the live data ticking underneath.
  Every animation runs on the compositor through RADWinUI.Motion. }

interface

uses
  RADWinUI.Forms,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Binding,
  StudioData,
  MainViewModel,
  MainWindow.Xaml;

type
  TMainWindow = class(TMainWindowBase)
  private
    FSimTimer, FFrameTimer: TWinUITimer;
    FPage, FNextPage, FDetailFrom: Integer;
    FSwitchAt, FToastUntil: UInt64;
    FDragged: TRelease;
    FHeroFrom: TWinUIRect;
    FHeroApp: TStudioApp;
    FExpanded, FStarted: Boolean;
    FNavWidth: Integer;
    FAppNames: TWinUIBindableList<TBar>;
    FSmokeStep: Integer;
    function PageElement(AIndex: Integer): TWinUIFrameworkElement;
    procedure SwitchPage(AIndex: Integer);
    procedure EnterPage(AIndex: Integer);
    procedure StartBackdrop;
    procedure DrawCharts;
    procedure DrawSeries(ACanvas: TWinUICanvas; ALine: TWinUIPolyline; AArea: TWinUIPolygon; AFirst: Boolean;
      ASecond: TWinUIPolyline);
    procedure DrawDonut;
    procedure DrawSpark;
    procedure FrameTick(Sender: TObject);
    procedure SimTick(Sender: TObject);
    procedure ShowToast(const AGlyph, ATitle, ABody: string);
    procedure ReleaseMoved(ARelease: TRelease; AFrom, ATo: Integer);
    procedure SeriesChanged;
    procedure ApplyTheme(ADark: Boolean);
    procedure OpenApp(AApp: TStudioApp; AFrom: TWinUIListViewBase; const AItem: TWinValue);
    procedure SetBoard(ATimeline: Boolean);
    procedure SmokeStep;
    procedure HoverAt(AX: Double);
    procedure LiftOnHover(AElement: TWinUIUIElement);
    function OutputPath(const AName: string): string;
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    procedure SurfaceLoaded(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure SurfaceSizeChanged(Sender: TObject; E: TWinUISizeChangedEventArgs);
    procedure MotionSwitchToggled(Sender: TObject);
    procedure NavClick(Sender: TObject);
    procedure BellClick(Sender: TObject);
    procedure ThemeClick(Sender: TObject);
    procedure MenuTeamClick(Sender: TObject);
    procedure RailSearchClick(Sender: TObject);
    procedure RailNewClick(Sender: TObject);
    procedure RailUndoClick(Sender: TObject);
    procedure RailShareClick(Sender: TObject);
    procedure RailUploadClick(Sender: TObject);
    procedure LiveClick(Sender: TObject);
    procedure SeriesClick(Sender: TObject);
    procedure ExportChartClick(Sender: TObject);
    procedure LastYearClick(Sender: TObject);
    procedure ExpandClick(Sender: TObject);
    procedure ChartSizeChanged(Sender: TObject; E: TWinUISizeChangedEventArgs);
    procedure AllAppsClick(Sender: TObject);
    procedure AppClick(Sender: TObject; E: TWinUIItemClickEventArgs);
    procedure AppSearchChanged(Sender: TObject; E: TWinUITextChangedEventArgs);
    procedure SortClick(Sender: TObject);
    procedure BackClick(Sender: TObject);
    procedure DetailTabClick(Sender: TObject);
    procedure FilterClick(Sender: TObject);
    procedure ViewClick(Sender: TObject);
    procedure ColumnAddClick(Sender: TObject);
    procedure BoardDragStarting(Sender: TObject; E: TWinUIDragItemsStartingEventArgs);
    procedure BoardDragOver(Sender: TObject; E: TWinUIDragEventArgs);
    procedure BoardDrop(Sender: TObject; E: TWinUIDragEventArgs);
    procedure BoardDragCompleted(Sender: TObject; E: TWinUIDragItemsCompletedEventArgs);
    procedure StarsClick(Sender: TObject);
    procedure ReviewAppChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
    procedure ReviewClick(Sender: TObject; E: TWinUIItemClickEventArgs);
    procedure AudienceFilterClick(Sender: TObject);
    procedure SubsPointerMoved(Sender: TObject; E: TWinUIPointerRoutedEventArgs);
    procedure SubsPointerExited(Sender: TObject; E: TWinUIPointerRoutedEventArgs);
    procedure ExportCsvClick(Sender: TObject);
    procedure StatementClick(Sender: TObject);
    procedure InviteClick(Sender: TObject);
  end;

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  System.IOUtils,
  System.Math,
  RADWinUI.Abi,
  RADWinUI.Motion;

const
  PageCount = 8;
  DetailPage = 8;
  NavWidth = 98;
  LeaveMs = 170;
  ToastMs = 3600;
  ChartPad = 8;

function Point(AX, AY: Double): TWinUIPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function ChartX(AWidth: Double; AIndex: Integer): Double;
begin
  // Points stay clear of the card edge, so the last dot is never cut off
  Result := ChartPad + (AWidth - 2 * ChartPad) * AIndex / 11;
end;

function Margin(ALeft, ATop: Double): TWinUIThickness;
begin
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Right := 0;
  Result.Bottom := 0;
end;

procedure SetChecked(AButton: TWinUIToggleButton; AValue: Boolean);
begin
  AButton.IsChecked := PropertyValue.CreateBoolean(AValue) as IReference_Boolean;
end;

function TagOf(Sender: TObject): Integer;
begin
  Result := StrToIntDef((Sender as TWinUIFrameworkElement).Tag.AsString, 0);
end;

{ TMainWindow }

constructor TMainWindow.Create;
var
  I: Integer;
begin
  inherited;
  ViewModel := TMainViewModel.Create;
  if FindCmdLineSwitch('nosim') then
    ViewModel.Live := False;
  ViewModel.OnToast := ShowToast;
  ViewModel.OnRelease := ReleaseMoved;
  ViewModel.OnSeries := SeriesChanged;
  SetTitleBar(DragRegion);
  AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.UseDefaultAppMode;
  if FindCmdLineSwitch('light') then
    ApplyTheme(False)
  else if FindCmdLineSwitch('dark') then
    ApplyTheme(True);

  OverviewApps.ItemsSource := ViewModel.Apps;
  AppGrid.ItemsSource := ViewModel.AppView;
  StarBarList.ItemsSource := ViewModel.StarBars;
  ReviewBars.ItemsSource := ViewModel.StarBars;
  DetailBars.ItemsSource := ViewModel.DetailBars;
  VersionList.ItemsSource := ViewModel.Versions;
  IapList.ItemsSource := ViewModel.Iaps;
  DetailReviewList.ItemsSource := ViewModel.DetailReviews;
  Column0.ItemsSource := ViewModel.Column(0);
  Column1.ItemsSource := ViewModel.Column(1);
  Column2.ItemsSource := ViewModel.Column(2);
  Column3.ItemsSource := ViewModel.Column(3);
  Column4.ItemsSource := ViewModel.Column(4);
  TimelineList.ItemsSource := ViewModel.Timeline;
  ReviewList.ItemsSource := ViewModel.ReviewView;
  InboxList.ItemsSource := ViewModel.Inbox;
  NoticeList.ItemsSource := ViewModel.Notices;
  CohortList.ItemsSource := ViewModel.Cohorts;
  CancelList.ItemsSource := ViewModel.CancelReasons;
  SourceList.ItemsSource := ViewModel.Sources;
  FunnelList.ItemsSource := ViewModel.Funnel;
  RegionList.ItemsSource := ViewModel.Regions;
  CampaignList.ItemsSource := ViewModel.Campaigns;
  SplitList.ItemsSource := ViewModel.Apps;
  PayoutList.ItemsSource := ViewModel.Payouts;
  TeamGrid.ItemsSource := ViewModel.Members;
  ActivityList.ItemsSource := ViewModel.ActivityFeed;
  FAppNames := TWinUIBindableList<TBar>.Create;
  FAppNames.Add(TBar.Create('All apps', '', 0));
  for I := 0 to ViewModel.Apps.Count - 1 do
    FAppNames.Add(TBar.Create(ViewModel.Apps[I].Name, '', 0));
  ReviewAppBox.DisplayMemberPath := 'Name';
  ReviewAppBox.ItemsSource := FAppNames;
  ReviewAppBox.SelectedIndex := 0;

  FFrameTimer := TWinUITimer.Create;
  FFrameTimer.Interval := 33;
  FFrameTimer.OnTimer := FrameTick;
  FFrameTimer.Enabled := True;
  FSimTimer := TWinUITimer.Create;
  FSimTimer.Interval := 1500;
  FSimTimer.OnTimer := SimTick;
  FSimTimer.Enabled := True;
  FNextPage := -1;
  FNavWidth := NavWidth;
end;

destructor TMainWindow.Destroy;
begin
  FSimTimer.Free;
  FFrameTimer.Free;
  ReviewAppBox.ItemsSource := Default(TWinValue);
  FAppNames.Free;
  ViewModel.Free;
  inherited;
end;

procedure TMainWindow.SurfaceLoaded(Sender: TObject; E: TWinUIRoutedEventArgs);
var
  Value: string;
  Card: TWinUIUIElement;
begin
  if FStarted then
    Exit;
  FStarted := True;
  TWinUIMotion.Hide(Toast);
  if ViewModel.Motion then
    StartBackdrop;
  for Card in TArray<TWinUIUIElement>.Create(ProceedsCard, RatingsCard, YourAppsCard, SubsCard, PlansCard, CohortCard,
    CancelCard, SourcesCard, FunnelCard, RegionsCard, CampaignCard, NextPayoutCard, SplitCard, HistoryCard, ActivityCard,
    RvSummary, DetailHero, LiveButton) do
    LiftOnHover(Card);
  DrawCharts;
  EnterPage(0);
  // -page:N opens another page, for screenshots
  if FindCmdLineSwitch('page', Value) then
    SwitchPage(StrToIntDef(Value, 0));
end;

procedure TMainWindow.SurfaceSizeChanged(Sender: TObject; E: TWinUISizeChangedEventArgs);
var
  Tabs: TArray<TWinUIButton>;
  Tab: TWinUIButton;
  Width, Nav: Integer;
begin
  // Narrow windows get narrower tabs, so the bar never runs into the logo or the inbox
  if Surface.ActualWidth < 1300 then
    Width := 74
  else if Surface.ActualWidth < 1480 then
    Width := 86
  else
    Width := NavWidth;
  if Width = FNavWidth then
    Exit;
  FNavWidth := Width;
  Tabs := [NavOverview, NavApps, NavReleases, NavReviews, NavAudience, NavGrowth, NavPayouts, NavTeam];
  for Tab in Tabs do
    Tab.Width := Width;
  NavIndicator.Width := Width;
  Nav := FPage;
  if Nav = DetailPage then
    Nav := 1;
  TWinUIMotion.SlideTo(NavIndicator, Nav * FNavWidth, 0, 1);
end;

procedure TMainWindow.LiftOnHover(AElement: TWinUIUIElement);
begin
  AElement.PointerEntered.Add(
    procedure(Sender: TObject; E: TWinUIPointerRoutedEventArgs)
    begin
      if ViewModel.Motion then
        TWinUIMotion.Lift(AElement, True);
    end);
  AElement.PointerExited.Add(
    procedure(Sender: TObject; E: TWinUIPointerRoutedEventArgs)
    begin
      if ViewModel.Motion then
        TWinUIMotion.Lift(AElement, False);
    end);
end;

function TMainWindow.OutputPath(const AName: string): string;
begin
  // The smoke test writes next to its report, a person's exports go to Documents
  if FindCmdLineSwitch('smoke-test') then
    Result := TPath.Combine(TPath.GetDirectoryName(ParamStr(2)), AName)
  else
  begin
    Result := TPath.Combine(TPath.GetDocumentsPath, 'Lucent');
    ForceDirectories(Result);
    Result := TPath.Combine(Result, AName);
  end;
end;

{ The backdrop }

procedure TMainWindow.StartBackdrop;
begin
  // Slow, out of step drifts: the eye never sees a loop
  TWinUIMotion.Drift(Ribbon1, 70, -40, 19000);
  TWinUIMotion.Drift(Ribbon2, -90, 30, 23000);
  TWinUIMotion.Drift(Ribbon3, 60, -50, 17000);
  TWinUIMotion.Drift(Orb1, 40, 30, 21000);
  TWinUIMotion.Drift(Orb2, -50, -40, 26000);
  TWinUIMotion.Drift(Bubble1, 18, -60, 9000);
  TWinUIMotion.Drift(Bubble2, -12, -40, 7000, 600);
  TWinUIMotion.Drift(Bubble3, 22, -50, 11000, 1200);
  TWinUIMotion.Drift(Bubble4, -26, -70, 13000, 300);
  TWinUIMotion.Drift(Bubble5, 10, -30, 6000, 900);
  TWinUIMotion.Drift(Bubble6, -8, -36, 8000, 1500);
  TWinUIMotion.Drift(Bubble7, 14, -44, 10000, 400);
  TWinUIMotion.Drift(Bubble8, 12, -38, 9500, 2100);
  TWinUIMotion.Drift(Bubble9, -18, -56, 12000, 700);
  TWinUIMotion.Drift(Bubble10, 9, -28, 7500, 1800);
  TWinUIMotion.Drift(Bubble11, -16, -48, 10500, 1000);
  TWinUIMotion.Drift(Bubble12, 6, -24, 6500, 2400);
end;

procedure TMainWindow.MotionSwitchToggled(Sender: TObject);
var
  Part: TWinUIObject;
begin
  if MotionSwitch.IsOn then
    StartBackdrop
  else
    for Part in TArray<TWinUIObject>.Create(Ribbon1, Ribbon2, Ribbon3, Orb1, Orb2, Bubble1, Bubble2, Bubble3, Bubble4,
      Bubble5, Bubble6, Bubble7, Bubble8, Bubble9, Bubble10, Bubble11, Bubble12) do
      TWinUIMotion.Reset(Part);
end;

{ Pages }

function TMainWindow.PageElement(AIndex: Integer): TWinUIFrameworkElement;
begin
  case AIndex of
    0: Result := PageOverview;
    1: Result := PageApps;
    2: Result := PageReleases;
    3: Result := PageReviews;
    4: Result := PageAudience;
    5: Result := PageGrowth;
    6: Result := PagePayouts;
    7: Result := PageTeam;
  else
    Result := PageDetail;
  end;
end;

procedure TMainWindow.SwitchPage(AIndex: Integer);
var
  Nav: Integer;
begin
  if (AIndex = FPage) and (FNextPage < 0) then
    Exit;
  Nav := AIndex;
  if AIndex = DetailPage then
    Nav := 1;
  TWinUIMotion.SlideTo(NavIndicator, Nav * FNavWidth, 0, 420);
  if not ViewModel.Motion then
  begin
    PageElement(FPage).Visibility := TWinUIVisibility.Collapsed;
    FPage := AIndex;
    PageElement(FPage).Visibility := TWinUIVisibility.Visible;
    EnterPage(FPage);
    Exit;
  end;
  // The old page fades out, the backdrop shows alone for a moment, then the new one enters
  TWinUIMotion.Leave(PageElement(FPage), LeaveMs, -12);
  FNextPage := AIndex;
  FSwitchAt := GetTickCount64 + LeaveMs;
end;

procedure TMainWindow.EnterPage(AIndex: Integer);
var
  Parts: TArray<TWinUIObject>;
  I, Step: Integer;
begin
  TWinUIMotion.Reset(PageElement(AIndex));
  case AIndex of
    0:
      begin
        Parts := [OvTitle, OvKpis, ProceedsCard, RatingsCard, YourAppsCard];
        ViewModel.CountUp([cProceedsMonth, cDownloads7, cAppRating, cRating]);
        OverviewApps.ItemsSource := Default(TWinValue);
        OverviewApps.ItemsSource := ViewModel.Apps;
      end;
    1:
      begin
        Parts := [ApTitle, ApKpis, ApToolbar];
        ViewModel.CountUp([cAppsLive, cRatingCount, cSubscribers]);
        AppGrid.ItemsSource := Default(TWinValue);
        AppGrid.ItemsSource := ViewModel.AppView;
      end;
    2:
      begin
        Parts := [ReTitle, ReKpis, ReToolbar, BoardCard, TimelineCard];
        ViewModel.CountUp([cInFlight, cWaiting, cShipped]);
      end;
    3:
      begin
        Parts := [RvTitle, RvKpis, RvSummary, RvList];
        ViewModel.CountUp([cRating, cWritten, cReplyRate]);
      end;
    4:
      begin
        Parts := [AuTitle, AuKpis, AuFilters, SubsCard, PlansCard, CohortCard, CancelCard];
        ViewModel.CountUp([cSubscribers, cTrialRate, cDownloads30, cPlans]);
      end;
    5:
      begin
        Parts := [GrTitle, GrKpis, SourcesCard, FunnelCard, RegionsCard, CampaignCard];
        ViewModel.CountUp([cPageViews, cConversion, cRegions]);
      end;
    6:
      begin
        Parts := [PaTitle, PaKpis, NextPayoutCard, SplitCard, HistoryCard, AccountRow];
        ViewModel.CountUp([cPending, cPaidYear, cNextPayout]);
      end;
    7:
      begin
        Parts := [TeTitle, TeKpis, TeamGrid, ActivityCard];
        ViewModel.CountUp([cMembers, cOnline]);
      end;
  else
    Parts := [BackButton, DeTitle, DeKpis, DetailTabs, DetailBody];
  end;
  if not ViewModel.Motion then
    Exit;
  Step := 0;
  for I := 0 to High(Parts) do
  begin
    TWinUIMotion.Enter(Parts[I], 40 + Step * 70, 520, 26);
    Inc(Step);
  end;
  case AIndex of
    0: TWinUIMotion.Reveal(ProceedsCanvas, 260, 1100);
    4:
      begin
        TWinUIMotion.Reveal(SubsCanvas, 300, 1100);
        TWinUIMotion.Sweep(Donut, -140, 360, 900);
      end;
    DetailPage: TWinUIMotion.Reveal(DetailCanvas, 420, 900);
  end;
end;

procedure TMainWindow.NavClick(Sender: TObject);
begin
  SwitchPage(TagOf(Sender));
end;

procedure TMainWindow.FrameTick(Sender: TObject);
var
  Old: Integer;
  Hero: TWinUIRect;
  Origin: TWinUIPoint;
begin
  ViewModel.StepCounters;
  if (FNextPage >= 0) and (GetTickCount64 >= FSwitchAt) then
  begin
    Old := FPage;
    FPage := FNextPage;
    FNextPage := -1;
    PageElement(Old).Visibility := TWinUIVisibility.Collapsed;
    PageElement(FPage).Visibility := TWinUIVisibility.Visible;
    EnterPage(FPage);
    if (FPage = DetailPage) and (FHeroApp <> nil) then
    begin
      // The hero card flies from the clicked app card to its place on the detail page
      PageDetail.UpdateLayout;
      Origin := DetailHero.TransformToVisual(nil).TransformPoint(Point(0, 0));
      Hero := FHeroFrom;
      TWinUIMotion.Hero(DetailHero, Hero.X - Origin.X, Hero.Y - Origin.Y,
        Hero.Width / Max(1, DetailHero.ActualWidth), Hero.Height / Max(1, DetailHero.ActualHeight), 560);
      FHeroApp := nil;
    end;
    DrawCharts;
  end;
  if (FToastUntil > 0) and (GetTickCount64 >= FToastUntil) then
  begin
    FToastUntil := 0;
    TWinUIMotion.Leave(Toast, 300, 20);
  end;
  if FindCmdLineSwitch('smoke-test') then
    SmokeStep;
end;

procedure TMainWindow.SimTick(Sender: TObject);
begin
  if not ViewModel.Live then
    Exit;
  ViewModel.Simulate;
  if ViewModel.Motion then
    TWinUIMotion.Pulse(LivePulse, 1.6);
end;

{ Charts }

procedure TMainWindow.DrawSeries(ACanvas: TWinUICanvas; ALine: TWinUIPolyline; AArea: TWinUIPolygon; AFirst: Boolean;
  ASecond: TWinUIPolyline);
var
  W, H, X, Y: Double;
  I: Integer;
  Line, Area, Second: IVector_Point;
begin
  W := ACanvas.ActualWidth;
  H := ACanvas.ActualHeight;
  if (W < 10) or (H < 10) then
    Exit;
  Line := ALine.Points;
  Line.Clear;
  Area := AArea.Points;
  Area.Clear;
  Area.Append(Point(0, H));
  for I := 0 to 11 do
  begin
    X := ChartX(W, I);
    if ACanvas = ProceedsCanvas then
      Y := H * (1 - Min(1, ViewModel.SeriesPoint(I)))
    else if ACanvas = SubsCanvas then
      Y := H * (1 - Min(1, ViewModel.SubsPoint(I)))
    else
      Y := H * (1 - Min(1, ViewModel.DetailPoint(I)));
    Line.Append(Point(X, Y));
    Area.Append(Point(X, Y));
  end;
  Area.Append(Point(W, H));
  if ASecond <> nil then
  begin
    Second := ASecond.Points;
    Second.Clear;
    for I := 0 to 11 do
    begin
      X := ChartX(W, I);
      if ACanvas = ProceedsCanvas then
        Y := H * (1 - Min(1, ViewModel.LastYearPoint(I)))
      else
        Y := H * (1 - Min(1, ViewModel.TrialPoint(I)));
      Second.Append(Point(X, Y));
    end;
  end;
  if AFirst then
  begin
    Y := H * (1 - Min(1, ViewModel.SeriesPoint(11)));
    ProceedsDot.Margin := Margin(ChartX(W, 11) - 5, Y - 5);
    ProceedsGlow.Margin := Margin(ChartX(W, 11) - 11, Y - 11);
  end;
end;

procedure TMainWindow.DrawDonut;
const
  Units = 3.14159265 * (200 - 22) / 22; // the circumference in stroke widths
var
  Arcs: array[0..2] of TWinUIEllipse;
  I: Integer;
  Start, Share: Double;
  Dashes: IVector_Double;
begin
  Arcs[0] := PlanArc0;
  Arcs[1] := PlanArc1;
  Arcs[2] := PlanArc2;
  Start := 0;
  for I := 0 to 2 do
  begin
    Share := ViewModel.PlanShare(I);
    Dashes := Arcs[I].StrokeDashArray;
    Dashes.Clear;
    Dashes.Append(Max(0, Share * Units - 0.12)); // a hairline gap between segments
    Dashes.Append(Units);
    Arcs[I].StrokeDashOffset := -Start * Units;
    Start := Start + Share;
  end;
end;

procedure TMainWindow.DrawSpark;
var
  W, H: Double;
  I: Integer;
  Points: IVector_Point;
begin
  W := 300;
  H := 64;
  Points := DetailSpark.Points;
  Points.Clear;
  for I := 0 to 11 do
    Points.Append(Point(W * I / 11, H * (1 - ViewModel.DetailPoint(I))));
end;

procedure TMainWindow.DrawCharts;
begin
  DrawSeries(ProceedsCanvas, ProceedsLine, ProceedsArea, True, ProceedsLastYear);
  DrawSeries(SubsCanvas, SubsLine, SubsArea, False, TrialLine);
  DrawSeries(DetailCanvas, DetailLine, DetailArea, False, nil);
  DrawDonut;
  DrawSpark;
end;

procedure TMainWindow.SeriesChanged;
begin
  DrawCharts;
end;

procedure TMainWindow.ChartSizeChanged(Sender: TObject; E: TWinUISizeChangedEventArgs);
begin
  DrawCharts;
end;

procedure TMainWindow.SeriesClick(Sender: TObject);
begin
  ViewModel.ShowDownloads(Sender = SeriesDownloads);
  SetChecked(SeriesProceeds, Sender = SeriesProceeds);
  SetChecked(SeriesDownloads, Sender = SeriesDownloads);
  DrawCharts;
  if ViewModel.Motion then
    TWinUIMotion.Reveal(ProceedsCanvas, 0, 900);
end;

procedure TMainWindow.LastYearClick(Sender: TObject);
begin
  if MenuLastYear.IsChecked then
    ProceedsLastYear.Visibility := TWinUIVisibility.Visible
  else
    ProceedsLastYear.Visibility := TWinUIVisibility.Collapsed;
end;

procedure TMainWindow.ExpandClick(Sender: TObject);
begin
  FExpanded := not FExpanded;
  if FExpanded then
  begin
    RatingsCard.Visibility := TWinUIVisibility.Collapsed;
    Grid.SetColumnSpan(TWinUIObject.IntfOf(ProceedsCard, IFrameworkElement) as IFrameworkElement, 2);
    ExpandGlyph.Glyph := #$E73F;
  end
  else
  begin
    Grid.SetColumnSpan(TWinUIObject.IntfOf(ProceedsCard, IFrameworkElement) as IFrameworkElement, 1);
    RatingsCard.Visibility := TWinUIVisibility.Visible;
    ExpandGlyph.Glyph := #$E740;
    if ViewModel.Motion then
      TWinUIMotion.Enter(RatingsCard, 120, 420, 20);
  end;
  if ViewModel.Motion then
    TWinUIMotion.Reveal(ProceedsCanvas, 80, 800);
end;

procedure TMainWindow.ExportChartClick(Sender: TObject);
var
  Path: string;
begin
  Path := OutputPath('Lucent-' + LowerCase(ViewModel.ChartTitle) + '.csv');
  TFile.WriteAllText(Path, ViewModel.ChartCsv);
  ShowToast(#$E896, 'Chart exported', Path);
end;

{ Toast and news }

procedure TMainWindow.ShowToast(const AGlyph, ATitle, ABody: string);
begin
  if not ViewModel.Motion then
    Exit;
  TWinUIMotion.Reset(Toast);
  TWinUIMotion.Enter(Toast, 0, 420, 28);
  FToastUntil := GetTickCount64 + ToastMs;
  if ViewModel.HasNews then
    TWinUIMotion.Pulse(BellDot, 1.8);
end;

procedure TMainWindow.BellClick(Sender: TObject);
begin
  ViewModel.ClearNews;
end;

{ Theme }

procedure TMainWindow.ApplyTheme(ADark: Boolean);
begin
  if ADark then
  begin
    Surface.RequestedTheme := TWinUIElementTheme.Dark;
    AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.Dark;
    ThemeGlyph.Glyph := #$E706; // the sun: switch to light
  end
  else
  begin
    Surface.RequestedTheme := TWinUIElementTheme.Light;
    AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.Light;
    ThemeGlyph.Glyph := #$E708; // the moon: switch to dark
  end;
end;

procedure TMainWindow.ThemeClick(Sender: TObject);
begin
  ApplyTheme(Surface.ActualTheme <> TWinUIElementTheme.Dark);
end;

procedure TMainWindow.MenuTeamClick(Sender: TObject);
begin
  SwitchPage(7);
end;

{ Rail }

procedure TMainWindow.RailSearchClick(Sender: TObject);
begin
  SwitchPage(1);
  AppSearch.Focus(TWinUIFocusState.Programmatic);
end;

procedure TMainWindow.RailNewClick(Sender: TObject);
begin
  ViewModel.NewRelease(0);
  if FPage <> 2 then
    SwitchPage(2);
  ShowToast(#$E710, 'New release started', 'It waits in In development until a build is uploaded.');
end;

procedure TMainWindow.RailUploadClick(Sender: TObject);
begin
  ViewModel.NewRelease(1);
  if FPage <> 2 then
    SwitchPage(2);
  ShowToast(#$E898, 'Build uploaded', 'Sent to beta testers.');
end;

procedure TMainWindow.RailUndoClick(Sender: TObject);
begin
  if ViewModel.Undo then
    ShowToast(#$E7A7, 'Move undone', 'The card is back where it was.')
  else
    ShowToast(#$E7A7, 'Nothing to undo', 'Move a release card first.');
end;

procedure TMainWindow.RailShareClick(Sender: TObject);
var
  Text: string;
  Memory: HGLOBAL;
begin
  Text := ViewModel.Summary;
  if OpenClipboard(0) then
  try
    EmptyClipboard;
    Memory := GlobalAlloc(GMEM_MOVEABLE, (Length(Text) + 1) * SizeOf(Char));
    Move(PChar(Text)^, GlobalLock(Memory)^, (Length(Text) + 1) * SizeOf(Char));
    GlobalUnlock(Memory);
    SetClipboardData(CF_UNICODETEXT, Memory);
  finally
    CloseClipboard;
  end;
  ShowToast(#$E72D, 'Summary copied', 'Paste it into a message or a report.');
end;

procedure TMainWindow.LiveClick(Sender: TObject);
begin
  ViewModel.Live := not ViewModel.Live;
end;

{ Apps }

procedure TMainWindow.AllAppsClick(Sender: TObject);
begin
  SwitchPage(1);
end;

procedure TMainWindow.OpenApp(AApp: TStudioApp; AFrom: TWinUIListViewBase; const AItem: TWinValue);
var
  Container: TWinUIDependencyObject;
  Element: TWinUIFrameworkElement;
  Origin: TWinUIPoint;
begin
  ViewModel.OpenDetail(AApp);
  FHeroApp := nil;
  Container := AFrom.ContainerFromItem(AItem);
  if Container is TWinUIFrameworkElement then
  begin
    Element := TWinUIFrameworkElement(Container);
    Origin := Element.TransformToVisual(nil).TransformPoint(Point(0, 0));
    FHeroFrom.X := Origin.X;
    FHeroFrom.Y := Origin.Y;
    FHeroFrom.Width := Element.ActualWidth;
    FHeroFrom.Height := Element.ActualHeight;
    FHeroApp := AApp;
  end;
  FDetailFrom := FPage;
  SetChecked(DetailTabOverview, True);
  DetailTabClick(DetailTabOverview);
  SwitchPage(DetailPage);
end;

procedure TMainWindow.AppClick(Sender: TObject; E: TWinUIItemClickEventArgs);
var
  Clicked: IInterface;
  I: Integer;
begin
  // The clicked item is the WinRT object XAML sees, so compare COM identities
  Clicked := E.ClickedItem.Obj as IInterface;
  for I := 0 to ViewModel.Apps.Count - 1 do
    if (ViewModel.Apps.BindableAt(I) as IInterface) = Clicked then
    begin
      OpenApp(ViewModel.Apps[I], Sender as TWinUIListViewBase, E.ClickedItem);
      Exit;
    end;
end;

procedure TMainWindow.BackClick(Sender: TObject);
begin
  SwitchPage(FDetailFrom);
end;

procedure TMainWindow.AppSearchChanged(Sender: TObject; E: TWinUITextChangedEventArgs);
begin
  ViewModel.SetSearch(AppSearch.Text);
  if ViewModel.AppView.Count = 0 then
    NoAppsText.Visibility := TWinUIVisibility.Visible
  else
    NoAppsText.Visibility := TWinUIVisibility.Collapsed;
end;

procedure TMainWindow.SortClick(Sender: TObject);
begin
  SetChecked(SortProceeds, Sender = SortProceeds);
  SetChecked(SortDownloads, Sender = SortDownloads);
  SetChecked(SortRating, Sender = SortRating);
  ViewModel.SetSort(TagOf(Sender));
end;

procedure TMainWindow.DetailTabClick(Sender: TObject);
var
  Tab: Integer;
  Panels: array[0..3] of TWinUIFrameworkElement;
  Buttons: array[0..3] of TWinUIToggleButton;
  I: Integer;
begin
  Tab := TagOf(Sender);
  Panels[0] := DetailOverview;
  Panels[1] := DetailVersions;
  Panels[2] := DetailIap;
  Panels[3] := DetailReviews;
  Buttons[0] := DetailTabOverview;
  Buttons[1] := DetailTabVersions;
  Buttons[2] := DetailTabIap;
  Buttons[3] := DetailTabReviews;
  for I := 0 to 3 do
  begin
    SetChecked(Buttons[I], I = Tab);
    if I = Tab then
      Panels[I].Visibility := TWinUIVisibility.Visible
    else
      Panels[I].Visibility := TWinUIVisibility.Collapsed;
  end;
  if ViewModel.Motion and (FPage = DetailPage) then
  begin
    TWinUIMotion.Enter(Panels[Tab], 0, 380, 16);
    if Tab = 0 then
      TWinUIMotion.Reveal(DetailCanvas, 120, 800);
  end;
end;

{ Releases }

procedure TMainWindow.FilterClick(Sender: TObject);
var
  Chips: array[0..6] of TWinUIToggleButton;
  I: Integer;
begin
  Chips[0] := FilterAll;
  Chips[1] := Filter0;
  Chips[2] := Filter1;
  Chips[3] := Filter2;
  Chips[4] := Filter3;
  Chips[5] := Filter4;
  Chips[6] := Filter5;
  for I := 0 to 6 do
    SetChecked(Chips[I], Chips[I] = Sender);
  ViewModel.SetReleaseFilter(TagOf(Sender));
end;

procedure TMainWindow.SetBoard(ATimeline: Boolean);
begin
  SetChecked(ViewBoard, not ATimeline);
  SetChecked(ViewTimeline, ATimeline);
  if ATimeline then
  begin
    BoardCard.Visibility := TWinUIVisibility.Collapsed;
    TimelineCard.Visibility := TWinUIVisibility.Visible;
    TimelineList.ItemsSource := Default(TWinValue);
    TimelineList.ItemsSource := ViewModel.Timeline;
  end
  else
  begin
    TimelineCard.Visibility := TWinUIVisibility.Collapsed;
    BoardCard.Visibility := TWinUIVisibility.Visible;
  end;
  if ViewModel.Motion then
  begin
    TWinUIMotion.Reset(BoardCard);
    TWinUIMotion.Reset(TimelineCard);
    if ATimeline then
      TWinUIMotion.Enter(TimelineCard, 0, 420, 20)
    else
      TWinUIMotion.Enter(BoardCard, 0, 420, 20);
  end;
end;

procedure TMainWindow.ViewClick(Sender: TObject);
begin
  SetBoard(Sender = ViewTimeline);
end;

procedure TMainWindow.ColumnAddClick(Sender: TObject);
begin
  ViewModel.NewRelease(TagOf(Sender));
end;

procedure TMainWindow.BoardDragStarting(Sender: TObject; E: TWinUIDragItemsStartingEventArgs);
var
  Dragged: IInterface;
  I: Integer;
begin
  FDragged := nil;
  if E.Items.Count = 0 then
    Exit;
  Dragged := E.Items[0].Obj as IInterface;
  for I := 0 to ViewModel.Releases.Count - 1 do
    if (ViewModel.Releases.BindableAt(I) as IInterface) = Dragged then
      FDragged := ViewModel.Releases[I];
end;

procedure TMainWindow.BoardDragOver(Sender: TObject; E: TWinUIDragEventArgs);
begin
  if FDragged <> nil then
    E.AcceptedOperation := 2; // DataPackageOperation.Move
end;

procedure TMainWindow.BoardDrop(Sender: TObject; E: TWinUIDragEventArgs);
begin
  if FDragged <> nil then
    ViewModel.MoveRelease(FDragged, TagOf(Sender));
  FDragged := nil;
end;

procedure TMainWindow.BoardDragCompleted(Sender: TObject; E: TWinUIDragItemsCompletedEventArgs);
begin
  FDragged := nil;
end;

procedure TMainWindow.ReleaseMoved(ARelease: TRelease; AFrom, ATo: Integer);
var
  Columns: array[0..4] of TWinUIFrameworkElement;
begin
  if not ViewModel.Motion or (FPage <> 2) then
    Exit;
  Columns[0] := Column0;
  Columns[1] := Column1;
  Columns[2] := Column2;
  Columns[3] := Column3;
  Columns[4] := Column4;
  TWinUIMotion.Pulse(Columns[ATo], 1.02);
end;

{ Reviews }

procedure TMainWindow.StarsClick(Sender: TObject);
var
  Chips: array[0..5] of TWinUIToggleButton;
  I: Integer;
begin
  Chips[0] := StarsAll;
  Chips[1] := Stars5;
  Chips[2] := Stars4;
  Chips[3] := Stars3;
  Chips[4] := Stars2;
  Chips[5] := Stars1;
  for I := 0 to 5 do
    SetChecked(Chips[I], Chips[I] = Sender);
  ViewModel.SetStarFilter(TagOf(Sender));
end;

procedure TMainWindow.ReviewAppChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
begin
  if ViewModel <> nil then
    ViewModel.SetReviewApp(ReviewAppBox.SelectedIndex - 1);
end;

procedure TMainWindow.ReviewClick(Sender: TObject; E: TWinUIItemClickEventArgs);
var
  Clicked: IInterface;
  I: Integer;
begin
  Clicked := E.ClickedItem.Obj as IInterface;
  for I := 0 to ViewModel.Reviews.Count - 1 do
    if (ViewModel.Reviews.BindableAt(I) as IInterface) = Clicked then
    begin
      ViewModel.ReplyTo(ViewModel.Reviews[I]);
      Exit;
    end;
end;

{ Audience }

procedure TMainWindow.AudienceFilterClick(Sender: TObject);
var
  Chips: array[0..6] of TWinUIToggleButton;
  I: Integer;
begin
  Chips[0] := AudAll;
  Chips[1] := Aud0;
  Chips[2] := Aud1;
  Chips[3] := Aud2;
  Chips[4] := Aud3;
  Chips[5] := Aud4;
  Chips[6] := Aud5;
  for I := 0 to 6 do
    SetChecked(Chips[I], Chips[I] = Sender);
  ViewModel.SetAudienceFilter(TagOf(Sender));
  if ViewModel.Motion then
  begin
    TWinUIMotion.Reveal(SubsCanvas, 0, 800);
    TWinUIMotion.Sweep(Donut, -90, 0, 700);
  end;
end;

procedure TMainWindow.SubsPointerMoved(Sender: TObject; E: TWinUIPointerRoutedEventArgs);
begin
  HoverAt(E.GetCurrentPoint(SubsHover).Position.X);
end;

procedure TMainWindow.HoverAt(AX: Double);
var
  W, H, X, Y, TrialY, TipX: Double;
  I: Integer;
begin
  W := SubsHover.ActualWidth;
  H := SubsHover.ActualHeight;
  if W < 10 then
    Exit;
  I := EnsureRange(Round((AX - ChartPad) / (W - 2 * ChartPad) * 11), 0, 11);
  X := ChartX(W, I);
  Y := H * (1 - Min(1, ViewModel.SubsPoint(I)));
  TrialY := H * (1 - Min(1, ViewModel.TrialPoint(I)));
  SubsGuide.Margin := Margin(X, 0);
  SubsDot.Margin := Margin(X - 6, Y - 6);
  TrialDot.Margin := Margin(X - 5, TrialY - 5);
  TipX := X + 16;
  if TipX + 172 > W then
    TipX := X - 184;
  SubsTip.Margin := Margin(TipX, Max(0, Y - 92));
  TipMonth.Text := MonthNames[I];
  TipSubs.Text := Compact(ViewModel.SubsAt(I));
  TipTrial.Text := Compact(ViewModel.TrialsAt(I));
  SubsGuide.Opacity := 1;
  SubsDot.Opacity := 1;
  TrialDot.Opacity := 1;
  SubsTip.Opacity := 1;
end;

procedure TMainWindow.SubsPointerExited(Sender: TObject; E: TWinUIPointerRoutedEventArgs);
begin
  SubsGuide.Opacity := 0;
  SubsDot.Opacity := 0;
  TrialDot.Opacity := 0;
  SubsTip.Opacity := 0;
end;

procedure TMainWindow.ExportCsvClick(Sender: TObject);
var
  Path: string;
begin
  Path := OutputPath('Lucent-retention.csv');
  TFile.WriteAllText(Path, ViewModel.CohortCsv);
  ShowToast(#$E896, 'Retention exported', Path);
end;

{ Payouts and team }

procedure TMainWindow.StatementClick(Sender: TObject);
const
  States: array[Boolean] of string = ('Scheduled', 'Paid');
var
  Path, Text: string;
  I: Integer;
  Payout: TPayout;
begin
  Text := 'Month,Units,Gross,Store fee,Net,Status' + sLineBreak;
  for I := 0 to ViewModel.Payouts.Count - 1 do
  begin
    Payout := ViewModel.Payouts[I];
    Text := Text + Payout.Month + ',"' + Payout.Units + '","' + Payout.Gross + '","' + Payout.Fees + '","' +
      Payout.Net + '",' + States[Payout.Paid] + sLineBreak;
  end;
  Path := OutputPath('Lucent-payouts.csv');
  TFile.WriteAllText(Path, Text);
  ShowToast(#$E896, 'Statement saved', Path);
end;

procedure TMainWindow.InviteClick(Sender: TObject);
begin
  ViewModel.Invite;
end;

{ Smoke test: every page, a detail page, a release move, the chart hover }

procedure TMainWindow.SmokeStep;

  procedure Check(ACondition: Boolean; const AWhat: string);
  begin
    if not ACondition then
      raise Exception.Create(AWhat);
  end;

var
  Release: TRelease;
begin
  Inc(FSmokeStep);
  try
    case FSmokeStep of
      30:
        begin
          Check(OvProceedsLabel.Text = '$86,420', 'Overview proceeds show ' + OvProceedsLabel.Text);
          Check(ViewModel.Column(2).Count = 2, 'In store review holds ' + IntToStr(ViewModel.Column(2).Count));
          SwitchPage(1);
        end;
      50:
        begin
          Check(PageApps.Visibility = TWinUIVisibility.Visible, 'Apps page not shown');
          AppSearch.Text := 'trail';
        end;
      60:
        begin
          Check(ViewModel.AppView.Count = 1, 'Search kept ' + IntToStr(ViewModel.AppView.Count) + ' apps');
          AppSearch.Text := '';
          SortClick(SortRating);
        end;
      70:
        begin
          Check(ViewModel.AppView[0].Name = 'Chorus', 'Rating sort starts with ' + ViewModel.AppView[0].Name);
          OpenApp(ViewModel.Apps[0], AppGrid, TWinValue(ViewModel.Apps.BindableAt(0)));
        end;
      90:
        begin
          Check(PageDetail.Visibility = TWinUIVisibility.Visible, 'Detail page not shown');
          Check(DetailNameLabel.Text = 'Tally', 'Detail shows ' + DetailNameLabel.Text);
          BackClick(nil);
        end;
      110:
        begin
          Check(PageApps.Visibility = TWinUIVisibility.Visible, 'Back did not return to Apps');
          SwitchPage(2);
        end;
      130:
        begin
          Release := ViewModel.Column(2)[0];
          ViewModel.MoveRelease(Release, 3);
          Check(ViewModel.Column(3).IndexOf(Release) = 0, 'The release did not reach Ready for release');
          Check(ViewModel.Column(2).Count = 1, 'In store review still holds ' + IntToStr(ViewModel.Column(2).Count));
          Check(ViewModel.Undo and (ViewModel.Column(2).IndexOf(Release) >= 0), 'Undo did not bring the release back');
          FilterClick(Filter0);
          Check(ViewModel.Column(4).Count = 1, 'Filtering by Tally left ' + IntToStr(ViewModel.Column(4).Count) + ' live builds');
          FilterClick(FilterAll);
          SwitchPage(3);
        end;
      150:
        begin
          StarsClick(Stars5);
          Check(ViewModel.ReviewView.Count = 5, 'Five-star filter kept ' + IntToStr(ViewModel.ReviewView.Count));
          StarsClick(StarsAll);
          SwitchPage(4);
        end;
      170:
        begin
          HoverAt(SubsHover.ActualWidth * 0.7);
          Check((TipMonth.Text = 'Jul') and (TipSubs.Text = '19.2K'), 'Hover shows ' + TipMonth.Text + ' ' + TipSubs.Text);
          SubsPointerExited(nil, nil);
        end;
      190:
        begin
          SwitchPage(5);
        end;
      205:
        SwitchPage(6);
      220:
        SwitchPage(7);
      235:
        begin
          InviteClick(nil);
          Check(ViewModel.Members.Count = 9, 'Invite did not add a member');
          ThemeClick(nil);
          ThemeClick(nil);
          SwitchPage(0);
        end;
      255:
        begin
          Check(PageOverview.Visibility = TWinUIVisibility.Visible, 'Overview not shown again');
          TFile.WriteAllText(ParamStr(2), 'PASS: eight pages, app detail and back, search, sort, board move and undo, ' +
            'filters, chart hover, invite, theme switch');
          Close;
        end;
    end;
  except
    on E: Exception do
    begin
      FFrameTimer.Enabled := False;
      TFile.WriteAllText(ParamStr(2), 'FAIL: ' + E.Message);
      Close;
    end;
  end;
end;

end.
