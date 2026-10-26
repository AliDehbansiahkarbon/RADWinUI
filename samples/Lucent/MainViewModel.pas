unit MainViewModel;

{ Lucent's studio data and its live simulation. Numbers the pages show are
  counters: they glide to a new value instead of jumping, and count up from
  zero when a page appears. Simulate moves the data on, deterministically for
  a given seed, so the smoke test can check exact values with -nosim. }

interface

uses
  RADWinUI.Binding,
  StudioData;

const
  // Counters, in the order of CounterNames
  cProceedsMonth = 0; cDownloads7 = 1; cAppRating = 2; cRatingCount = 3; cSubscribers = 4;
  cAppsLive = 5; cInFlight = 6; cWaiting = 7; cShipped = 8; cWritten = 9; cReplyRate = 10;
  cTrialRate = 11; cDownloads30 = 12; cPageViews = 13; cConversion = 14; cRegions = 15;
  cPending = 16; cPaidYear = 17; cNextPayout = 18; cMembers = 19; cOnline = 20; cRating = 21;
  cPlans = 22;
  CounterCount = 23;

  StageNames: array[0..4] of string = ('In development', 'Beta', 'In store review', 'Ready for release', 'Live');
  MonthNames: array[0..11] of string = ('Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug',
    'Sep', 'Oct');

type
  TCounterKind = (ckMoney, ckCount, ckDecimal, ckPercent, ckCompact);

  TCounter = record
    Kind: TCounterKind;
    Shown, From, Target: Double;
    Start: UInt64;
    Moving: Boolean;
  end;

  TToastEvent = procedure(const AGlyph, ATitle, ABody: string) of object;
  TProcedureEvent = procedure of object;
  TReleaseEvent = procedure(ARelease: TRelease; AFrom, ATo: Integer) of object;

  TMainViewModel = class(TWinUIBindableObject)
  private
    FCounters: array[0..CounterCount - 1] of TCounter;
    FVisible: set of 0..CounterCount - 1;
    FApps: TWinUIBindableList<TStudioApp>;
    FAppView: TWinUIBindableList<TStudioApp>;
    FReleases: TWinUIBindableList<TRelease>;
    FColumns: array[0..4] of TWinUIBindableList<TRelease>;
    FTimeline: TWinUIBindableList<TRelease>;
    FReviews: TWinUIBindableList<TReview>;
    FReviewView: TWinUIBindableList<TReview>;
    FInbox: TWinUIBindableList<TReview>;
    FNotices: TWinUIBindableList<TNotice>;
    FActivity: TWinUIBindableList<TNotice>;
    FStarBars: TWinUIBindableList<TBar>;
    FDetailBars: TWinUIBindableList<TBar>;
    FCancel: TWinUIBindableList<TBar>;
    FSources: TWinUIBindableList<TBar>;
    FFunnel: TWinUIBindableList<TBar>;
    FRegions: TWinUIBindableList<TBar>;
    FCampaigns: TWinUIBindableList<TListRow>;
    FVersions: TWinUIBindableList<TListRow>;
    FIaps: TWinUIBindableList<TListRow>;
    FDetailReviews: TWinUIBindableList<TReview>;
    FCohorts: TWinUIBindableList<TCohort>;
    FPayouts: TWinUIBindableList<TPayout>;
    FMembers: TWinUIBindableList<TMember>;
    FDetail: TStudioApp;
    FSubs, FTrials, FLastYear, FDownloadMonths: array[0..11] of Double;
    FPlans: array[0..2] of Double;
    FShowDownloads: Boolean;
    FReleaseFilter, FAudienceFilter, FStarFilter, FReviewApp, FSort: Integer;
    FSearch: string;
    FLive, FMotion, FHasNews: Boolean;
    FToastGlyph, FToastTitle, FToastBody: string;
    FTicks, FInvites, FNextBuild: Integer;
    FUndoRelease: TRelease;
    FUndoStage: Integer;
    FOnToast: TToastEvent;
    FOnRelease: TReleaseEvent;
    FOnSeries: TProcedureEvent;
    procedure SeedApps;
    procedure SeedBoard;
    procedure SeedReviews;
    procedure SeedAudience;
    procedure SeedGrowth;
    procedure SeedPayouts;
    procedure SeedTeam;
    procedure SetCounter(AIndex: Integer; AValue: Double; AAnimate: Boolean = True);
    function CounterValue(AIndex: Integer): Double;
    function GetCounterText(AIndex: Integer): string;
    function GetFilterText(AIndex: Integer): string;
    function GetAudienceText(AIndex: Integer): string;
    function GetColumnCount(AIndex: Integer): string;
    function GetPlanText(AIndex: Integer): string;
    function GetChartTitle: string;
    function GetChartCaption: string;
    function GetChartTop: string;
    function GetChartMid: string;
    function GetAppRatingCaption: string;
    function GetRatingCountCaption: string;
    function GetRecentRatingText: string;
    function GetSubsCaption: string;
    function GetProceedsDeltaText: string;
    function GetCycleProgress: Double;
    function GetCycleDaysText: string;
    procedure SetLive(AValue: Boolean);
    procedure SetMotion(AValue: Boolean);
    procedure Toast(const AGlyph, ATitle, ABody: string);
    procedure Activity(const AGlyph, AText: string);
    procedure UpdateBoardCounters;
    procedure UpdateRatings;
    procedure UpdateAppShares;
    procedure RebuildBoard;
    procedure RebuildReviews;
    procedure RebuildInbox;
    function Matches(ARelease: TRelease): Boolean;
    function AudienceShare: Double;
    procedure NewReview;
    procedure AdvanceRelease;
  public
    constructor Create;
    destructor Destroy; override;
    { One step of every counter that is gliding; False when none moves. }
    function StepCounters: Boolean;
    { Counts the counters of a page up from zero. Only these glide from now on,
      the others take new values at once, which saves the UI thread work. }
    procedure CountUp(const AIndexes: array of Integer);
    { The live data: called about every 1.5 s. }
    procedure Simulate;
    { Chart series, scaled 0..1 against the chart top. }
    function SeriesPoint(AIndex: Integer): Double;
    function LastYearPoint(AIndex: Integer): Double;
    function SubsPoint(AIndex: Integer): Double;
    function TrialPoint(AIndex: Integer): Double;
    function SubsAt(AIndex: Integer): Double;
    function TrialsAt(AIndex: Integer): Double;
    function DetailPoint(AIndex: Integer): Double;
    function PlanShare(AIndex: Integer): Double;
    { Board }
    procedure MoveRelease(ARelease: TRelease; AStage: Integer);
    procedure NewRelease(AStage: Integer);
    function Undo: Boolean;
    procedure SetReleaseFilter(AApp: Integer);
    { Apps }
    procedure SetSearch(const AText: string);
    procedure SetSort(AKind: Integer);
    procedure OpenDetail(AApp: TStudioApp);
    { Reviews }
    procedure SetStarFilter(AStars: Integer);
    procedure SetReviewApp(AApp: Integer);
    procedure ReplyTo(AReview: TReview);
    { Audience }
    procedure SetAudienceFilter(AApp: Integer);
    { Team }
    procedure Invite;
    procedure ShowDownloads(AValue: Boolean);
    procedure ClearNews;
    function CohortCsv: string;
    function ChartCsv: string;
    function Summary: string;
    property Apps: TWinUIBindableList<TStudioApp> read FApps;
    property AppView: TWinUIBindableList<TStudioApp> read FAppView;
    property Releases: TWinUIBindableList<TRelease> read FReleases;
    property Timeline: TWinUIBindableList<TRelease> read FTimeline;
    property ReviewView: TWinUIBindableList<TReview> read FReviewView;
    property Reviews: TWinUIBindableList<TReview> read FReviews;
    property Inbox: TWinUIBindableList<TReview> read FInbox;
    property Notices: TWinUIBindableList<TNotice> read FNotices;
    property ActivityFeed: TWinUIBindableList<TNotice> read FActivity;
    property StarBars: TWinUIBindableList<TBar> read FStarBars;
    property DetailBars: TWinUIBindableList<TBar> read FDetailBars;
    property CancelReasons: TWinUIBindableList<TBar> read FCancel;
    property Sources: TWinUIBindableList<TBar> read FSources;
    property Funnel: TWinUIBindableList<TBar> read FFunnel;
    property Regions: TWinUIBindableList<TBar> read FRegions;
    property Campaigns: TWinUIBindableList<TListRow> read FCampaigns;
    property Versions: TWinUIBindableList<TListRow> read FVersions;
    property Iaps: TWinUIBindableList<TListRow> read FIaps;
    property DetailReviews: TWinUIBindableList<TReview> read FDetailReviews;
    property Cohorts: TWinUIBindableList<TCohort> read FCohorts;
    property Payouts: TWinUIBindableList<TPayout> read FPayouts;
    property Members: TWinUIBindableList<TMember> read FMembers;
    property ReleaseFilter: Integer read FReleaseFilter;
    property ShowingDownloads: Boolean read FShowDownloads;
    property OnToast: TToastEvent read FOnToast write FOnToast;
    property OnRelease: TReleaseEvent read FOnRelease write FOnRelease;
    property OnSeries: TProcedureEvent read FOnSeries write FOnSeries;
    function Column(AStage: Integer): TWinUIBindableList<TRelease>;
    function Counter(AIndex: Integer): Double;
  published
    property Detail: TStudioApp read FDetail;
    property Live: Boolean read FLive write SetLive;
    property Motion: Boolean read FMotion write SetMotion;
    property HasNews: Boolean read FHasNews;
    property ToastGlyph: string read FToastGlyph;
    property ToastTitle: string read FToastTitle;
    property ToastBody: string read FToastBody;
    property ProceedsMonthText: string index cProceedsMonth read GetCounterText;
    property Downloads7Text: string index cDownloads7 read GetCounterText;
    property AppRatingText: string index cAppRating read GetCounterText;
    property RatingCountText: string index cRatingCount read GetCounterText;
    property SubscribersText: string index cSubscribers read GetCounterText;
    property AppsLiveText: string index cAppsLive read GetCounterText;
    property InFlightText: string index cInFlight read GetCounterText;
    property WaitingText: string index cWaiting read GetCounterText;
    property ShippedText: string index cShipped read GetCounterText;
    property WrittenText: string index cWritten read GetCounterText;
    property ReplyRateText: string index cReplyRate read GetCounterText;
    property TrialRateText: string index cTrialRate read GetCounterText;
    property Downloads30Text: string index cDownloads30 read GetCounterText;
    property PageViewsText: string index cPageViews read GetCounterText;
    property ConversionText: string index cConversion read GetCounterText;
    property RegionsText: string index cRegions read GetCounterText;
    property PendingText: string index cPending read GetCounterText;
    property PaidYearText: string index cPaidYear read GetCounterText;
    property NextPayoutText: string index cNextPayout read GetCounterText;
    property MembersText: string index cMembers read GetCounterText;
    property OnlineText: string index cOnline read GetCounterText;
    property RatingText: string index cRating read GetCounterText;
    property PlansText: string index cPlans read GetCounterText;
    property ProceedsDeltaText: string read GetProceedsDeltaText;
    property AppRatingCaption: string read GetAppRatingCaption;
    property RatingCountCaption: string read GetRatingCountCaption;
    property RecentRatingText: string read GetRecentRatingText;
    property ChartTitle: string read GetChartTitle;
    property ChartCaption: string read GetChartCaption;
    property ChartTop: string read GetChartTop;
    property ChartMid: string read GetChartMid;
    property SubsCaption: string read GetSubsCaption;
    property CycleProgress: Double read GetCycleProgress;
    property CycleDaysText: string read GetCycleDaysText;
    property FilterText0: string index 0 read GetFilterText;
    property FilterText1: string index 1 read GetFilterText;
    property FilterText2: string index 2 read GetFilterText;
    property FilterText3: string index 3 read GetFilterText;
    property FilterText4: string index 4 read GetFilterText;
    property FilterText5: string index 5 read GetFilterText;
    property FilterText6: string index 6 read GetFilterText;
    property AudText0: string index 0 read GetAudienceText;
    property AudText1: string index 1 read GetAudienceText;
    property AudText2: string index 2 read GetAudienceText;
    property AudText3: string index 3 read GetAudienceText;
    property AudText4: string index 4 read GetAudienceText;
    property AudText5: string index 5 read GetAudienceText;
    property AudText6: string index 6 read GetAudienceText;
    property Count0: string index 0 read GetColumnCount;
    property Count1: string index 1 read GetColumnCount;
    property Count2: string index 2 read GetColumnCount;
    property Count3: string index 3 read GetColumnCount;
    property Count4: string index 4 read GetColumnCount;
    property PlanText0: string index 0 read GetPlanText;
    property PlanText1: string index 1 read GetPlanText;
    property PlanText2: string index 2 read GetPlanText;
  end;

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  System.StrUtils,
  System.Math;

const
  CounterNames: array[0..CounterCount - 1] of string = ('ProceedsMonthText', 'Downloads7Text', 'AppRatingText',
    'RatingCountText', 'SubscribersText', 'AppsLiveText', 'InFlightText', 'WaitingText', 'ShippedText', 'WrittenText',
    'ReplyRateText', 'TrialRateText', 'Downloads30Text', 'PageViewsText', 'ConversionText', 'RegionsText', 'PendingText',
    'PaidYearText', 'NextPayoutText', 'MembersText', 'OnlineText', 'RatingText', 'PlansText');
  CounterKinds: array[0..CounterCount - 1] of TCounterKind = (ckMoney, ckCount, ckDecimal, ckCount, ckCount,
    ckCount, ckCount, ckCount, ckCount, ckCount, ckPercent, ckPercent, ckCount, ckCount, ckPercent, ckCount, ckMoney,
    ckMoney, ckMoney, ckCount, ckCount, ckDecimal, ckCompact);
  GlideMs = 900;
  ChartTopProceeds = 125000;
  ChartTopDownloads = 250000;
  ChartTopSubs = 25000;
  BarWidth = 230;
  CycleDay = 20; // days into the 45-day payment cycle

var
  UsFormat: TFormatSettings;

function IndexOfApp(const AApps: TArray<TStudioApp>; AApp: TStudioApp): Integer;
begin
  for Result := 0 to High(AApps) do
    if AApps[Result] = AApp then
      Exit;
  Result := -1;
end;

{ TMainViewModel }

constructor TMainViewModel.Create;
var
  I: Integer;
  Animations: BOOL;
begin
  inherited;
  Brushes := TBrushes.Create;
  RandSeed := 2027;
  for I := 0 to CounterCount - 1 do
    FCounters[I].Kind := CounterKinds[I];
  FApps := TWinUIBindableList<TStudioApp>.Create;
  FAppView := TWinUIBindableList<TStudioApp>.Create(False);
  FReleases := TWinUIBindableList<TRelease>.Create;
  for I := 0 to High(FColumns) do
    FColumns[I] := TWinUIBindableList<TRelease>.Create(False);
  FTimeline := TWinUIBindableList<TRelease>.Create(False);
  FReviews := TWinUIBindableList<TReview>.Create;
  FReviewView := TWinUIBindableList<TReview>.Create(False);
  FInbox := TWinUIBindableList<TReview>.Create(False);
  FNotices := TWinUIBindableList<TNotice>.Create;
  FActivity := TWinUIBindableList<TNotice>.Create;
  FStarBars := TWinUIBindableList<TBar>.Create;
  FDetailBars := TWinUIBindableList<TBar>.Create;
  FCancel := TWinUIBindableList<TBar>.Create;
  FSources := TWinUIBindableList<TBar>.Create;
  FFunnel := TWinUIBindableList<TBar>.Create;
  FRegions := TWinUIBindableList<TBar>.Create;
  FCampaigns := TWinUIBindableList<TListRow>.Create;
  FVersions := TWinUIBindableList<TListRow>.Create;
  FIaps := TWinUIBindableList<TListRow>.Create;
  FDetailReviews := TWinUIBindableList<TReview>.Create(False);
  FCohorts := TWinUIBindableList<TCohort>.Create;
  FPayouts := TWinUIBindableList<TPayout>.Create;
  FMembers := TWinUIBindableList<TMember>.Create;
  FReleaseFilter := -1;
  FAudienceFilter := -1;
  FReviewApp := -1;
  FLive := True;
  // Follow the Windows "Animation effects" setting
  Animations := True;
  SystemParametersInfo(SPI_GETCLIENTAREAANIMATION, 0, @Animations, 0);
  FMotion := Animations;
  FNextBuild := 402;
  SeedApps;
  SeedBoard;
  SeedReviews;
  SeedAudience;
  SeedGrowth;
  SeedPayouts;
  SeedTeam;
  FNotices.Add(TNotice.Create(#$E73E, 'Pinpoint 4.0.0 is live', 'Rolled out to every market.', 'Yesterday'));
  FNotices.Add(TNotice.Create(#$E8C7, 'September payout sent', Money(91240) + ' to Northwind Bank.', '2 days ago'));
  FDetail := FApps[0];
  OpenDetail(FApps[0]);
end;

destructor TMainViewModel.Destroy;
var
  I: Integer;
begin
  // Views first: they do not own their items
  FAppView.Free;
  for I := 0 to High(FColumns) do
    FColumns[I].Free;
  FTimeline.Free;
  FReviewView.Free;
  FInbox.Free;
  FDetailReviews.Free;
  FReleases.Free;
  FReviews.Free;
  FNotices.Free;
  FActivity.Free;
  FStarBars.Free;
  FDetailBars.Free;
  FCancel.Free;
  FSources.Free;
  FFunnel.Free;
  FRegions.Free;
  FCampaigns.Free;
  FVersions.Free;
  FIaps.Free;
  FCohorts.Free;
  FPayouts.Free;
  FMembers.Free;
  FApps.Free;
  FreeAndNil(Brushes);
  inherited;
end;

procedure TMainViewModel.SeedApps;
const
  Months: array[0..5, 0..11] of Double = (
    (16200, 18900, 18100, 20400, 22100, 23300, 24600, 26200, 27800, 29900, 36400, 27950),
    (11800, 14600, 13900, 15100, 16400, 16900, 17600, 18800, 19400, 20600, 24300, 20243),
    (8300, 12100, 10800, 11400, 12300, 12900, 13400, 14200, 14900, 15800, 18100, 15412),
    (6100, 8200, 7600, 8300, 8900, 9300, 9800, 10300, 10800, 11600, 13200, 11690),
    (4300, 5900, 5600, 6200, 6800, 7100, 7400, 8100, 8400, 9000, 10600, 9125),
    (1500, 1800, 1900, 1700, 1900, 1700, 2000, 2000, 2000, 2000, 2000, 2000));
  Days: array[0..5, 0..6] of Double = (
    (1480, 1520, 1610, 1390, 1550, 1680, 1420),
    (1310, 1270, 1350, 1190, 1240, 1300, 1150),
    (980, 1040, 1100, 930, 1020, 1080, 990),
    (720, 760, 810, 700, 740, 790, 680),
    (520, 540, 600, 510, 560, 580, 490),
    (300, 320, 340, 310, 330, 350, 360));
  Stars: array[0..5, 1..5] of Double = (
    (5, 3, 7, 20, 65), (4, 3, 8, 22, 63), (9, 5, 10, 21, 55), (6, 4, 9, 24, 57), (5, 3, 9, 25, 58), (3, 2, 6, 19, 70));
var
  A, I: Integer;
begin
  FApps.Add(TStudioApp.Create('Tally', 'Budgets that balance themselves', #$E8C7, 'Finance', 'Freemium', '3.1.2',
    'Version 3.1.2, looked after by Mira Patel', $FF5B7CFA, 4.6, 21408, 44900, -8, 27950, 99.27));
  FApps.Add(TStudioApp.Create('Driftwood', 'Sleep sounds and soft stories', #$E708, 'Health', 'Subscription', '5.0.4',
    'Version 5.0.4, looked after by Jonas Weber', $FF1FA99A, 4.4, 15730, 38100, 5, 20243, 99.61));
  FApps.Add(TStudioApp.Create('Pinpoint', 'Offline trail maps for hikers', #$E707, 'Navigation', 'Paid', '4.0.0',
    'Version 4.0.0, looked after by Sana Okafor', $FFE8902C, 4.2, 12904, 31200, 12, 15412, 98.92));
  FApps.Add(TStudioApp.Create('Brushwork', 'A sketchbook that fits a pocket', #$E70F, 'Graphics', 'Freemium', '2.3.1',
    'Version 2.3.1, looked after by Leo Marchetti', $FFD9507F, 4.3, 9884, 22800, -3, 11690, 99.12));
  FApps.Add(TStudioApp.Create('Ledgerly', 'Invoices for freelancers', #$E8A5, 'Business', 'Subscription', '1.8.1',
    'Version 1.8.1, looked after by Hana Ito', $FF8461E8, 4.5, 6402, 16900, 2, 9125, 99.48));
  FApps.Add(TStudioApp.Create('Chorus', 'Language flashcards that stick', #$E7BE, 'Education', 'Free', '1.0.0',
    'Version 1.0.0, looked after by Ari Rowe', $FF2E9BD6, 4.8, 6700, 9300, 21, 2000, 99.80));
  FApps[5].InReview := True;
  for A := 0 to FApps.Count - 1 do
  begin
    for I := 0 to 11 do
      FApps[A].Months[I] := Months[A, I];
    for I := 0 to 6 do
      FApps[A].Days[I] := Days[A, I];
    for I := 1 to 5 do
      FApps[A].Stars[I] := Stars[A, I];
    FAppView.Add(FApps[A]);
  end;
  for I := 0 to 11 do
  begin
    FLastYear[I] := 0;
    for A := 0 to FApps.Count - 1 do
      FLastYear[I] := FLastYear[I] + Months[A, I];
    FLastYear[I] := FLastYear[I] * (0.62 + 0.012 * I);
    FDownloadMonths[I] := 120000 + I * 7600 + (I mod 3) * 5200;
  end;
  FDownloadMonths[10] := 214000;
  FDownloadMonths[11] := 204282;
  for I := 5 downto 1 do
    FStarBars.Add(TBar.Create(IntToStr(I) + ' ' + #$2605, '', 0));
  for I := 5 downto 1 do
    FDetailBars.Add(TBar.Create(IntToStr(I) + ' ' + #$2605, '', 0));
  SetCounter(cProceedsMonth, 0, False);
  for A := 0 to FApps.Count - 1 do
    SetCounter(cProceedsMonth, CounterValue(cProceedsMonth) + FApps[A].Proceeds, False);
  SetCounter(cDownloads7, 48210, False);
  SetCounter(cAppsLive, 5, False);
  SetCounter(cDownloads30, 204282, False);
  SetCounter(cPlans, 13832, False);
  UpdateRatings;
  UpdateAppShares;
end;

procedure TMainViewModel.SeedBoard;
var
  A: TArray<TStudioApp>;
  I: Integer;
begin
  A := [FApps[0], FApps[1], FApps[2], FApps[3], FApps[4], FApps[5]];
  FReleases.Add(TRelease.Create(A[0], '3.2.0', 'Shared budgets for couples and a calmer onboarding.', 'MP', 401, 0, 3, 0, 0));
  FReleases.Add(TRelease.Create(A[3], '2.4.0', 'Pressure-sensitive brushes and layer groups.', 'LM', 212, 0, 5, 0, 0));
  FReleases.Add(TRelease.Create(A[1], '5.1.0', 'Rain on a tin roof, plus a new bedtime story pack.', 'JW', 733, 1, 2, 1240, 98.6));
  FReleases.Add(TRelease.Create(A[4], '1.8.2', 'Fixes rounding in multi-currency invoices.', 'HI', 145, 1, 1, 310, 99.4));
  FReleases.Add(TRelease.Create(A[2], '4.0.1', 'Faster map downloads and a fix for elevation charts.', 'SO', 518, 2, 1, 860, 99.1));
  FReleases.Add(TRelease.Create(A[5], '1.0.0', 'First release: 12 languages, spaced repetition, streaks.', 'AR', 77, 2, 4, 2100, 98.9));
  FReleases.Add(TRelease.Create(A[0], '3.1.3', 'Bank sync fixes for two regional banks.', 'MP', 388, 3, 1, 1420, 99.5));
  FReleases.Add(TRelease.Create(A[0], '3.1.2', 'Recurring transactions and a new widget.', 'MP', 381, 4, 9, 1610, 99.3));
  FReleases.Add(TRelease.Create(A[1], '5.0.4', 'Smaller download, smoother fades.', 'JW', 726, 4, 12, 1180, 99.6));
  FReleases.Add(TRelease.Create(A[2], '4.0.0', 'All-new offline maps with contour lines.', 'SO', 511, 4, 1, 940, 98.9));
  FReleases.Add(TRelease.Create(A[3], '2.3.1', 'Palette import and a crash fix on export.', 'LM', 207, 4, 16, 520, 99.1));
  for I := 0 to FReleases.Count - 1 do
    FTimeline.Add(FReleases[I]);
  RebuildBoard;
  SetCounter(cShipped, 9, False);
end;

procedure TMainViewModel.SeedReviews;
var
  A: TArray<TStudioApp>;
begin
  A := [FApps[0], FApps[1], FApps[2], FApps[3], FApps[4], FApps[5]];
  FReviews.Add(TReview.Create(A[0], 5, 'Finally a budget app I keep using', 'The weekly check-in is gentle and the widget keeps me honest. Shared budgets would make it perfect.', 'Noor K.', 'today'));
  FReviews.Add(TReview.Create(A[2], 2, 'Map download stalls at 90%', 'Love the contour lines, but large regions never finish downloading on my tablet.', 'Peter V.', 'today'));
  FReviews.Add(TReview.Create(A[1], 5, 'Asleep in ten minutes', 'The rain sounds are the best I have tried, and the timer fades out so softly.', 'Camille D.', 'yesterday'));
  FReviews.Add(TReview.Create(A[3], 4, 'Great brushes', 'Feels natural with a pen. I would love layer groups.', 'Yuki S.', 'yesterday'));
  FReviews.Add(TReview.Create(A[4], 5, 'Saves me hours every month', 'Invoices look professional and reminders go out on their own.', 'Marta L.', '2 days ago'));
  FReviews.Add(TReview.Create(A[0], 3, 'Bank sync is hit and miss', 'My credit union disconnects every few days. Otherwise lovely.', 'Ben A.', '2 days ago'));
  FReviews.Add(TReview.Create(A[5], 5, 'Streaks keep me going', 'Day 41 of Spanish. The spaced repetition actually works.', 'Ola N.', '3 days ago'));
  FReviews.Add(TReview.Create(A[2], 4, 'Perfect on the trail', 'Worked with no signal all weekend. Battery use is fair.', 'Rhys T.', '4 days ago'));
  FReviews.Add(TReview.Create(A[1], 1, 'Subscription renewed without warning', 'Please send a reminder before the yearly plan renews.', 'Sam R.', '5 days ago'));
  FReviews.Add(TReview.Create(A[3], 5, 'My daily sketch habit', 'Simple, fast and beautiful.', 'Ines F.', '6 days ago'));
  FReviews[2].Reply;
  FReviews[4].Reply;
  FReviews[6].Reply;
  FReviews[9].Reply;
  SetCounter(cWritten, 1284, False);
  SetCounter(cReplyRate, 86, False);
  RebuildReviews;
  RebuildInbox;
end;

procedure TMainViewModel.SeedAudience;
const
  Subs: array[0..11] of Double = (15520, 15980, 16210, 16740, 17120, 17650, 18030, 18560, 19210, 19780, 20540, 21113);
  Trials: array[0..11] of Double = (2140, 2610, 2380, 2560, 2810, 2950, 3120, 3360, 3820, 3540, 3910, 3760);
  Cancel: array[0..5] of string = ('Too expensive', 'Not using it enough', 'Switched to another app', 'Missing a feature',
    'Bugs or crashes', 'Something else');
  CancelShare: array[0..5] of Double = (34, 27, 16, 13, 6, 4);
var
  I: Integer;
begin
  for I := 0 to 11 do
  begin
    FSubs[I] := Subs[I];
    FTrials[I] := Trials[I];
  end;
  FPlans[0] := 5943;
  FPlans[1] := 4712;
  FPlans[2] := 3177;
  SetCounter(cSubscribers, Subs[11], False);
  SetCounter(cTrialRate, 44.9, False);
  for I := 0 to 5 do
    FCancel.Add(TBar.Create(Cancel[I], FormatFloat('0', CancelShare[I], UsFormat) + '%', 300 * CancelShare[I] / 34));
  FCohorts.Add(TCohort.Create('May', '2,410', [100, 78, 69, 63, 59, 56]));
  FCohorts.Add(TCohort.Create('June', '2,655', [100, 80, 71, 64, 60]));
  FCohorts.Add(TCohort.Create('July', '3,120', [100, 82, 73, 66]));
  FCohorts.Add(TCohort.Create('August', '2,980', [100, 81, 72]));
  FCohorts.Add(TCohort.Create('September', '3,460', [100, 84]));
  FCohorts.Add(TCohort.Create('October', '3,214', [100]));
end;

procedure TMainViewModel.SeedGrowth;
begin
  FSources.Add(TBar.Create('Store search', '83,750', 380 * 41 / 41, #$E721));
  FSources.Add(TBar.Create('Browse and top charts', '44,940', 380 * 22 / 41, #$E80F));
  FSources.Add(TBar.Create('Web referrals', '30,640', 380 * 15 / 41, #$E774));
  FSources.Add(TBar.Create('Campaigns', '24,510', 380 * 12 / 41, #$E789));
  FSources.Add(TBar.Create('Social', '14,300', 380 * 7 / 41, #$E8F2));
  FSources.Add(TBar.Create('Something else', '6,142', 380 * 3 / 41, #$E712));
  FFunnel.Add(TBar.Create('Impressions', '3.9M', 440));
  FFunnel.Add(TBar.Create('Store page views', '1.24M', 370));
  FFunnel.Add(TBar.Create('Installs', '204K', 290));
  FFunnel.Add(TBar.Create('Trials started', '31.6K', 210));
  FFunnel.Add(TBar.Create('Paying customers', '14.2K', 150));
  FRegions.Add(TBar.Create('United States', '61,280', 300, 'US'));
  FRegions.Add(TBar.Create('Germany', '24,510', 120, 'DE'));
  FRegions.Add(TBar.Create('United Kingdom', '21,930', 107, 'GB'));
  FRegions.Add(TBar.Create('Japan', '18,400', 90, 'JP'));
  FRegions.Add(TBar.Create('Brazil', '14,060', 69, 'BR'));
  FRegions.Add(TBar.Create('India', '12,770', 63, 'IN'));
  FCampaigns.Add(TListRow.Create('Back to school', 'Chorus, 12 markets', '7,420 installs of 10,000', 'Running', 74));
  FCampaigns.Add(TListRow.Create('Sleep better week', 'Driftwood, search ads', '3,180 trials of 5,000', 'Running', 64));
  FCampaigns.Add(TListRow.Create('Trail season', 'Pinpoint, featured story', '12,900 page views of 15,000', 'Running', 86));
  SetCounter(cPageViews, 1240400, False);
  SetCounter(cConversion, 16.5, False);
  SetCounter(cRegions, 64, False);
end;

procedure TMainViewModel.SeedPayouts;
begin
  FPayouts.Add(TPayout.Create('October', 24120, CounterValue(cProceedsMonth) / 0.85, False));
  FPayouts.Add(TPayout.Create('September', 30410, 123060, True));
  FPayouts.Add(TPayout.Create('August', 26880, 104590, True));
  FPayouts.Add(TPayout.Create('July', 25110, 98000, True));
  FPayouts.Add(TPayout.Create('June', 24020, 93650, True));
  FPayouts.Add(TPayout.Create('May', 22790, 88000, True));
  SetCounter(cNextPayout, 74218, False);
  SetCounter(cPending, 12904, False);
  SetCounter(cPaidYear, 716040, False);
end;

procedure TMainViewModel.SeedTeam;
begin
  FMembers.Add(TMember.Create('Ari Rowe', 'Studio owner', 'Admin', 'All apps', $FF2E9BD6, True, 'Online now'));
  FMembers.Add(TMember.Create('Mira Patel', 'iOS and Windows engineer', 'Developer', 'Tally', $FF5B7CFA, True, 'Online now'));
  FMembers.Add(TMember.Create('Jonas Weber', 'Audio designer', 'Developer', 'Driftwood', $FF1FA99A, False, 'Active 2 h ago'));
  FMembers.Add(TMember.Create('Sana Okafor', 'Maps engineer', 'Developer', 'Pinpoint', $FFE8902C, True, 'Online now'));
  FMembers.Add(TMember.Create('Leo Marchetti', 'Product designer', 'Designer', 'Brushwork, Tally', $FFD9507F, True, 'Online now'));
  FMembers.Add(TMember.Create('Hana Ito', 'Engineer', 'Developer', 'Ledgerly', $FF8461E8, False, 'Active yesterday'));
  FMembers.Add(TMember.Create('Theo Lindqvist', 'Marketing', 'Marketing', 'All apps', $FF4F8F6A, True, 'Online now'));
  FMembers.Add(TMember.Create('Priya Nair', 'Finance', 'Finance', 'Payouts', $FFB0763A, False, 'Active 3 d ago'));
  SetCounter(cMembers, 8, False);
  SetCounter(cOnline, 5, False);
  FActivity.Add(TNotice.Create(#$E898, 'Mira uploaded Tally 3.2.0, build 401', '', '12 min ago'));
  FActivity.Add(TNotice.Create(#$E8BD, 'Theo replied to 4 reviews', '', '40 min ago'));
  FActivity.Add(TNotice.Create(#$E73E, 'Sana released Pinpoint 4.0.0', '', 'Yesterday'));
  FActivity.Add(TNotice.Create(#$E8FA, 'Priya joined the studio', '', '3 days ago'));
end;

{ Counters }

procedure TMainViewModel.SetCounter(AIndex: Integer; AValue: Double; AAnimate: Boolean);
begin
  with FCounters[AIndex] do
  begin
    if AAnimate and FMotion and (AIndex in FVisible) then
    begin
      From := Shown;
      Start := GetTickCount64;
      Moving := True;
    end
    else
    begin
      Shown := AValue;
      Moving := False;
    end;
    Target := AValue;
  end;
  if not FCounters[AIndex].Moving then
    Changed(CounterNames[AIndex]);
end;

function TMainViewModel.CounterValue(AIndex: Integer): Double;
begin
  Result := FCounters[AIndex].Target;
end;

function TMainViewModel.Counter(AIndex: Integer): Double;
begin
  Result := FCounters[AIndex].Target;
end;

function TMainViewModel.StepCounters: Boolean;
var
  I: Integer;
  T: Double;
  Now: UInt64;
begin
  Result := False;
  Now := GetTickCount64;
  for I := 0 to CounterCount - 1 do
    with FCounters[I] do
      if Moving then
      begin
        T := Min(1, (Now - Start) / GlideMs);
        T := 1 - Power(1 - T, 3); // ease out
        Shown := From + (Target - From) * T;
        if T >= 1 then
        begin
          Shown := Target;
          Moving := False;
        end
        else
          Result := True;
        Changed(CounterNames[I]);
      end;
end;

procedure TMainViewModel.CountUp(const AIndexes: array of Integer);
var
  I: Integer;
begin
  FVisible := [];
  for I in AIndexes do
    Include(FVisible, I);
  if not FMotion then
    Exit;
  for I in AIndexes do
    with FCounters[I] do
    begin
      Shown := 0;
      From := 0;
      Start := GetTickCount64;
      Moving := True;
    end;
end;

function TMainViewModel.GetCounterText(AIndex: Integer): string;
var
  V: Double;
begin
  V := FCounters[AIndex].Shown;
  case FCounters[AIndex].Kind of
    ckMoney: Result := Money(V);
    ckCount: Result := Count(Round(V));
    ckDecimal: Result := FormatFloat('0.00', V, UsFormat);
    ckPercent: Result := FormatFloat('0.0', V, UsFormat) + '%';
  else
    Result := Compact(V);
  end;
  if AIndex = cReplyRate then
    Result := FormatFloat('0', V, UsFormat) + '%';
end;

{ Captions }

function TMainViewModel.GetProceedsDeltaText: string;
begin
  Result := '+' + FormatFloat('0', 100 * (CounterValue(cProceedsMonth) / 123060 / 0.85 + 0.12 - 1 + 0.28), UsFormat) + '% vs Sept';
end;

function TMainViewModel.GetAppRatingCaption: string;
begin
  Result := 'average from ' + Compact(CounterValue(cRatingCount)) + ' ratings';
end;

function TMainViewModel.GetRatingCountCaption: string;
begin
  Result := Count(CounterValue(cRatingCount)) + ' ratings, ' + IntToStr(FApps.Count) + ' apps';
end;

function TMainViewModel.GetRecentRatingText: string;
begin
  Result := '4.00 from ' + IntToStr(22 + FReviews.Count - 10) + ' written reviews';
end;

function TMainViewModel.GetChartTitle: string;
begin
  if FShowDownloads then
    Result := 'Downloads'
  else
    Result := 'Proceeds';
end;

function TMainViewModel.GetChartCaption: string;
var
  I, Best: Integer;
  Total, Value, BestValue: Double;
begin
  Total := 0;
  Best := 0;
  BestValue := 0;
  for I := 0 to 11 do
  begin
    if FShowDownloads then
      Value := FDownloadMonths[I]
    else
      Value := SeriesPoint(I) * ChartTopProceeds;
    Total := Total + Value;
    if Value > BestValue then
    begin
      BestValue := Value;
      Best := I;
    end;
  end;
  if FShowDownloads then
    Result := Count(Total) + ' downloads in the last 12 months, best month '
  else
    Result := Money(Total) + ' in the last 12 months, best month ';
  case Best of
    10: Result := Result + 'September';
    11: Result := Result + 'October';
  else
    Result := Result + MonthNames[Best];
  end;
end;

function TMainViewModel.GetChartTop: string;
begin
  if FShowDownloads then
    Result := '250K'
  else
    Result := '$125K';
end;

function TMainViewModel.GetChartMid: string;
begin
  if FShowDownloads then
    Result := '125K'
  else
    Result := '$62K';
end;

function TMainViewModel.GetSubsCaption: string;
begin
  Result := Count(Round(SubsAt(11))) + ' paying today';
end;

function TMainViewModel.GetCycleProgress: Double;
begin
  Result := 100 * CycleDay / 45;
end;

function TMainViewModel.GetCycleDaysText: string;
begin
  Result := IntToStr(45 - CycleDay) + ' d';
end;

function TMainViewModel.GetPlanText(AIndex: Integer): string;
begin
  Result := Count(FPlans[AIndex] * AudienceShare) + '    ' + FormatFloat('0', 100 * PlanShare(AIndex), UsFormat) + '%';
end;

function TMainViewModel.GetFilterText(AIndex: Integer): string;
var
  I, N: Integer;
begin
  N := 0;
  for I := 0 to FReleases.Count - 1 do
    if (AIndex = 0) or (FReleases[I].App = FApps[AIndex - 1]) then
      Inc(N);
  if AIndex = 0 then
    Result := 'All ' + IntToStr(N)
  else
    Result := FApps[AIndex - 1].Name + ' ' + IntToStr(N);
end;

function TMainViewModel.GetAudienceText(AIndex: Integer): string;
begin
  if AIndex = 0 then
    Result := 'All apps'
  else
    Result := FApps[AIndex - 1].Name + ' ' + Compact(FSubs[11] * FApps[AIndex - 1].Share / 100);
end;

function TMainViewModel.GetColumnCount(AIndex: Integer): string;
begin
  Result := IntToStr(FColumns[AIndex].Count);
end;

{ Series }

function TMainViewModel.SeriesPoint(AIndex: Integer): Double;
var
  A: Integer;
begin
  if FShowDownloads then
    Exit(FDownloadMonths[AIndex] / ChartTopDownloads);
  Result := 0;
  for A := 0 to FApps.Count - 1 do
    Result := Result + FApps[A].Months[AIndex];
  Result := Result / ChartTopProceeds;
end;

function TMainViewModel.LastYearPoint(AIndex: Integer): Double;
begin
  if FShowDownloads then
    Result := FDownloadMonths[AIndex] * (0.58 + 0.01 * AIndex) / ChartTopDownloads
  else
    Result := FLastYear[AIndex] / ChartTopProceeds;
end;

function TMainViewModel.AudienceShare: Double;
begin
  if FAudienceFilter < 0 then
    Result := 1
  else
    Result := FApps[FAudienceFilter].Share / 100;
end;

function TMainViewModel.SubsAt(AIndex: Integer): Double;
begin
  Result := FSubs[AIndex] * AudienceShare;
end;

function TMainViewModel.TrialsAt(AIndex: Integer): Double;
begin
  Result := FTrials[AIndex] * AudienceShare;
end;

function TMainViewModel.SubsPoint(AIndex: Integer): Double;
begin
  Result := SubsAt(AIndex) / (ChartTopSubs * IfThen(FAudienceFilter < 0, 1, 0.5));
end;

function TMainViewModel.TrialPoint(AIndex: Integer): Double;
begin
  Result := TrialsAt(AIndex) / (ChartTopSubs * IfThen(FAudienceFilter < 0, 1, 0.5));
end;

function TMainViewModel.DetailPoint(AIndex: Integer): Double;
begin
  Result := FDetail.Months[AIndex] / Max(1, MaxValue(FDetail.Months) * 1.15);
end;

function TMainViewModel.PlanShare(AIndex: Integer): Double;
begin
  Result := FPlans[AIndex] / Sum(FPlans);
end;

{ Shared updates }

procedure TMainViewModel.UpdateRatings;
var
  A, S: Integer;
  Total, Weighted, RatingSum: Double;
  Share: array[1..5] of Double;
begin
  Total := 0;
  Weighted := 0;
  RatingSum := 0;
  for S := 1 to 5 do
    Share[S] := 0;
  for A := 0 to FApps.Count - 1 do
  begin
    Total := Total + FApps[A].RatingCount;
    RatingSum := RatingSum + FApps[A].Rating;
    for S := 1 to 5 do
      Share[S] := Share[S] + FApps[A].Stars[S] * FApps[A].RatingCount;
  end;
  for S := 1 to 5 do
  begin
    Share[S] := Share[S] / Total;
    Weighted := Weighted + S * Share[S] / 100;
  end;
  for S := 5 downto 1 do
    FStarBars[5 - S].Update(FormatFloat('0', Share[S], UsFormat) + '%', BarWidth * Share[S] / Share[5]);
  SetCounter(cRatingCount, Total);
  SetCounter(cAppRating, RatingSum / FApps.Count);
  SetCounter(cRating, Weighted);
  Changed('AppRatingCaption');
  Changed('RatingCountCaption');
end;

procedure TMainViewModel.UpdateAppShares;
var
  A: Integer;
  Total, Best: Double;
begin
  Total := 0;
  Best := 0;
  for A := 0 to FApps.Count - 1 do
  begin
    Total := Total + FApps[A].Proceeds;
    Best := Max(Best, FApps[A].Proceeds);
  end;
  for A := 0 to FApps.Count - 1 do
    // Share is the bar width in the payouts split, and the percent of subscribers per app
    FApps[A].Share := 100 * FApps[A].Proceeds / Total;
  Changed('AudText1');
end;

{ Board }

function TMainViewModel.Column(AStage: Integer): TWinUIBindableList<TRelease>;
begin
  Result := FColumns[AStage];
end;

function TMainViewModel.Matches(ARelease: TRelease): Boolean;
begin
  Result := (FReleaseFilter < 0) or (ARelease.App = FApps[FReleaseFilter]);
end;

procedure TMainViewModel.RebuildBoard;
var
  I: Integer;
begin
  for I := 0 to High(FColumns) do
    FColumns[I].Clear;
  FTimeline.Clear;
  for I := 0 to FReleases.Count - 1 do
    if Matches(FReleases[I]) then
    begin
      FColumns[FReleases[I].Stage].Add(FReleases[I]);
      FTimeline.Add(FReleases[I]);
    end;
  UpdateBoardCounters;
end;

procedure TMainViewModel.UpdateBoardCounters;
var
  I, InFlight, Waiting: Integer;
begin
  InFlight := 0;
  Waiting := 0;
  for I := 0 to FReleases.Count - 1 do
  begin
    if FReleases[I].Stage < 4 then
      Inc(InFlight);
    if FReleases[I].Stage = 2 then
      Inc(Waiting);
  end;
  SetCounter(cInFlight, InFlight);
  SetCounter(cWaiting, Waiting);
  for I := 0 to 4 do
    Changed('Count' + IntToStr(I));
  for I := 0 to 6 do
    Changed('FilterText' + IntToStr(I));
end;

procedure TMainViewModel.MoveRelease(ARelease: TRelease; AStage: Integer);
var
  From, I: Integer;
  Old: TRelease;
begin
  From := ARelease.Stage;
  if (AStage = From) or (AStage < 0) or (AStage > 4) then
    Exit;
  FUndoRelease := ARelease;
  FUndoStage := From;
  I := FColumns[From].IndexOf(ARelease);
  if I >= 0 then
    FColumns[From].Delete(I);
  if AStage = 4 then
  begin
    // The new live build replaces the app's current one
    for I := 0 to FReleases.Count - 1 do
    begin
      Old := FReleases[I];
      if (Old <> ARelease) and (Old.App = ARelease.App) and Old.Current then
        Old.Retire;
    end;
    SetCounter(cShipped, CounterValue(cShipped) + 1);
  end;
  ARelease.MoveTo(AStage);
  if Matches(ARelease) then
    FColumns[AStage].Insert(0, ARelease);
  if Assigned(FOnRelease) then
    FOnRelease(ARelease, From, AStage);
  UpdateBoardCounters;
end;

procedure TMainViewModel.NewRelease(AStage: Integer);
var
  App: TStudioApp;
  Release: TRelease;
begin
  if FReleaseFilter >= 0 then
    App := FApps[FReleaseFilter]
  else
    App := FApps[FNextBuild mod FApps.Count];
  Release := TRelease.Create(App, 'next', 'A new build, waiting for its first testers.', 'AR', FNextBuild, AStage, 0, 0, 0);
  Inc(FNextBuild);
  FReleases.Add(Release);
  FColumns[AStage].Insert(0, Release);
  if Matches(Release) then
    FTimeline.Insert(0, Release);
  Activity(#$E898, 'You created ' + Release.Title + ', build ' + IntToStr(FNextBuild - 1));
  UpdateBoardCounters;
end;

function TMainViewModel.Undo: Boolean;
var
  Release: TRelease;
begin
  Result := FUndoRelease <> nil;
  if not Result then
    Exit;
  Release := FUndoRelease;
  MoveRelease(Release, FUndoStage);
  FUndoRelease := nil;
end;

procedure TMainViewModel.SetReleaseFilter(AApp: Integer);
begin
  FReleaseFilter := AApp;
  RebuildBoard;
end;

procedure TMainViewModel.AdvanceRelease;
var
  I, Start: Integer;
  Release: TRelease;
begin
  // The oldest build that is not live moves on
  Start := Random(FReleases.Count);
  for I := 0 to FReleases.Count - 1 do
  begin
    Release := FReleases[(Start + I) mod FReleases.Count];
    if Release.Stage in [1, 2] then
    begin
      MoveRelease(Release, Release.Stage + 1);
      Toast(#$E945, Release.Title + ' moved on', 'Now in ' + StageNames[Release.Stage] + '.');
      Activity(#$E945, Release.Title + ' moved to ' + StageNames[Release.Stage]);
      Exit;
    end;
  end;
end;

{ Apps }

procedure TMainViewModel.SetSearch(const AText: string);
begin
  FSearch := Trim(AText);
  SetSort(FSort);
end;

procedure TMainViewModel.SetSort(AKind: Integer);
var
  Wanted: TArray<TStudioApp>;
  I, J, K: Integer;
  App: TStudioApp;

  function Key(A: TStudioApp): Double;
  begin
    case FSort of
      1: Result := A.Downloads;
      2: Result := A.Rating;
    else
      Result := A.Proceeds;
    end;
  end;

begin
  FSort := AKind;
  Wanted := nil;
  for I := 0 to FApps.Count - 1 do
  begin
    App := FApps[I];
    if (FSearch = '') or ContainsText(App.Name, FSearch) or ContainsText(App.Category, FSearch) or
      ContainsText(App.Tagline, FSearch) then
      Wanted := Wanted + [App];
  end;
  for I := 1 to High(Wanted) do
  begin
    App := Wanted[I];
    J := I - 1;
    while (J >= 0) and (Key(Wanted[J]) < Key(App)) do
    begin
      Wanted[J + 1] := Wanted[J];
      Dec(J);
    end;
    Wanted[J + 1] := App;
  end;
  // Move items instead of rebuilding, so the grid animates every card to its new place
  for I := FAppView.Count - 1 downto 0 do
    if IndexOfApp(Wanted, FAppView[I]) < 0 then
      FAppView.Delete(I);
  for I := 0 to High(Wanted) do
  begin
    K := FAppView.IndexOf(Wanted[I]);
    if K = I then
      Continue;
    if K >= 0 then
      FAppView.Delete(K);
    FAppView.Insert(I, Wanted[I]);
  end;
end;

procedure TMainViewModel.OpenDetail(AApp: TStudioApp);
const
  Iaps: array[0..2] of string = ('Pro, monthly', 'Pro, yearly', 'Lifetime');
  Prices: array[0..2] of string = ('$4.99', '$39.99', '$89.99');
var
  I, S: Integer;
begin
  FDetail := AApp;
  FVersions.Clear;
  for I := 0 to FReleases.Count - 1 do
    if FReleases[I].App = AApp then
      FVersions.Add(TListRow.Create(FReleases[I].Version, FReleases[I].Notes, FReleases[I].BuildText,
        StageNames[FReleases[I].Stage]));
  for I := 1 to 3 do
    FVersions.Add(TListRow.Create('Earlier', 'A release from ' + IntToStr(I * 2 + 1) + ' months ago.',
      IntToStr(I * 2 + 1) + ' months ago', 'Retired'));
  FIaps.Clear;
  for I := 0 to 2 do
    FIaps.Add(TListRow.Create(Iaps[I], Prices[I], Count(Round(AApp.Proceeds / (4 + I * 3))) + ' sold', 'Active'));
  FDetailReviews.Clear;
  for I := 0 to FReviews.Count - 1 do
    if FReviews[I].App = AApp then
      FDetailReviews.Add(FReviews[I]);
  for S := 5 downto 1 do
    FDetailBars[5 - S].Update(FormatFloat('0', AApp.Stars[S], UsFormat) + '%', 200 * AApp.Stars[S] / MaxValue(AApp.Stars));
  Changed('Detail');
end;

{ Reviews }

procedure TMainViewModel.RebuildReviews;
var
  I: Integer;
  R: TReview;
begin
  FReviewView.Clear;
  for I := 0 to FReviews.Count - 1 do
  begin
    R := FReviews[I];
    if ((FStarFilter = 0) or (R.Stars = FStarFilter)) and ((FReviewApp < 0) or (R.App = FApps[FReviewApp])) then
      FReviewView.Add(R);
  end;
end;

procedure TMainViewModel.RebuildInbox;
var
  I: Integer;
begin
  FInbox.Clear;
  for I := 0 to FReviews.Count - 1 do
    if not FReviews[I].Replied and (FInbox.Count < 5) then
      FInbox.Add(FReviews[I]);
end;

procedure TMainViewModel.SetStarFilter(AStars: Integer);
begin
  FStarFilter := AStars;
  RebuildReviews;
end;

procedure TMainViewModel.SetReviewApp(AApp: Integer);
begin
  FReviewApp := AApp;
  RebuildReviews;
end;

procedure TMainViewModel.ReplyTo(AReview: TReview);
begin
  if AReview.Replied then
    Exit;
  AReview.Reply;
  SetCounter(cReplyRate, Min(100, CounterValue(cReplyRate) + 0.4));
  RebuildInbox;
  Activity(#$E97A, 'You replied to ' + AReview.Title);
end;

procedure TMainViewModel.NewReview;
const
  Titles: array[0..5] of string = ('Exactly what I needed', 'Crashes when I rotate', 'Clean and calm',
    'Please add a dark widget', 'Worth every cent', 'Sync takes ages');
  Bodies: array[0..5] of string = ('Set it up in two minutes and it just works.',
    'The app closes when I turn my tablet sideways during playback.', 'No clutter, no nagging, just the essentials.',
    'Love it, but the widget is too bright at night.', 'Paid for the yearly plan after one week of the trial.',
    'Takes a minute to sync after I open it in the morning.');
  StarsFor: array[0..5] of Integer = (5, 2, 5, 4, 5, 3);
  Authors: array[0..5] of string = ('Lena H.', 'Marco B.', 'Aiko T.', 'Grace O.', 'Omar F.', 'Kai W.');
var
  K: Integer;
  App: TStudioApp;
  Review: TReview;
begin
  K := Random(6);
  App := FApps[Random(FApps.Count)];
  Review := TReview.Create(App, StarsFor[K], Titles[K], Bodies[K], Authors[K], 'just now');
  FReviews.Insert(0, Review);
  App.AddRating(StarsFor[K]);
  App.Notify(['StarsText', 'RatingText', 'RatingChip', 'RatingCountText']);
  if ((FStarFilter = 0) or (FStarFilter = Review.Stars)) and ((FReviewApp < 0) or (FApps[FReviewApp] = App)) then
    FReviewView.Insert(0, Review);
  if App = FDetail then
    FDetailReviews.Insert(0, Review);
  RebuildInbox;
  SetCounter(cWritten, CounterValue(cWritten) + 1);
  UpdateRatings;
  FNotices.Insert(0, TNotice.Create(#$E735, 'New ' + IntToStr(Review.Stars) + '-star review for ' + App.Name,
    Review.Title, 'just now'));
  FHasNews := True;
  Changed('HasNews');
  Changed('RecentRatingText');
  Toast(#$E735, 'New review for ' + App.Name, StarText(Review.Stars) + '  ' + Review.Title);
end;

{ Audience }

procedure TMainViewModel.SetAudienceFilter(AApp: Integer);
var
  I: Integer;
begin
  FAudienceFilter := AApp;
  SetCounter(cSubscribers, SubsAt(11));
  SetCounter(cPlans, Sum(FPlans) * AudienceShare);
  Changed('SubsCaption');
  for I := 0 to 2 do
    Changed('PlanText' + IntToStr(I));
  if Assigned(FOnSeries) then
    FOnSeries;
end;

{ Team }

procedure TMainViewModel.Invite;
const
  Names: array[0..3] of string = ('Rosa Delgado', 'Felix Brandt', 'Amara Mensah', 'Nils Berg');
  Roles: array[0..3] of string = ('QA engineer', 'Support lead', 'Android engineer', 'Data analyst');
  Colors: array[0..3] of Cardinal = ($FFC2553D, $FF3D7FC2, $FF7A9B2E, $FF9B2E7A);
var
  K: Integer;
begin
  K := FInvites mod 4;
  Inc(FInvites);
  FMembers.Insert(0, TMember.Create(Names[K], Roles[K], 'Invited', 'Not assigned yet', Colors[K], False, 'Invitation sent just now'));
  SetCounter(cMembers, FMembers.Count);
  Activity(#$E8FA, 'You invited ' + Names[K]);
  Toast(#$E8FA, 'Invitation sent', Names[K] + ' will join as ' + Roles[K] + '.');
end;

{ Misc }

procedure TMainViewModel.ShowDownloads(AValue: Boolean);
begin
  FShowDownloads := AValue;
  Changed('ChartTitle');
  Changed('ChartCaption');
  Changed('ChartTop');
  Changed('ChartMid');
end;

procedure TMainViewModel.ClearNews;
begin
  FHasNews := False;
  Changed('HasNews');
end;

procedure TMainViewModel.SetLive(AValue: Boolean);
begin
  FLive := AValue;
  Changed('Live');
end;

procedure TMainViewModel.SetMotion(AValue: Boolean);
begin
  FMotion := AValue;
  Changed('Motion');
end;

procedure TMainViewModel.Toast(const AGlyph, ATitle, ABody: string);
begin
  FToastGlyph := AGlyph;
  FToastTitle := ATitle;
  FToastBody := ABody;
  Changed('ToastGlyph');
  Changed('ToastTitle');
  Changed('ToastBody');
  if Assigned(FOnToast) then
    FOnToast(AGlyph, ATitle, ABody);
end;

procedure TMainViewModel.Activity(const AGlyph, AText: string);
begin
  FActivity.Insert(0, TNotice.Create(AGlyph, AText, '', 'just now'));
  while FActivity.Count > 7 do
    FActivity.Delete(FActivity.Count - 1);
end;

function TMainViewModel.CohortCsv: string;
var
  I: Integer;
begin
  Result := 'Cohort,Subscribers,Month 1,Month 2,Month 3,Month 4,Month 5,Month 6' + sLineBreak;
  for I := 0 to FCohorts.Count - 1 do
    Result := Result + FCohorts[I].CsvLine + sLineBreak;
end;

function TMainViewModel.ChartCsv: string;
var
  I: Integer;
  Top: Double;
begin
  if FShowDownloads then
    Top := ChartTopDownloads
  else
    Top := ChartTopProceeds;
  Result := 'Month,' + GetChartTitle + ',Same month last year' + sLineBreak;
  for I := 0 to 11 do
    Result := Result + MonthNames[I] + ',' + FormatFloat('0', SeriesPoint(I) * Top, UsFormat) + ',' +
      FormatFloat('0', LastYearPoint(I) * Top, UsFormat) + sLineBreak;
end;

function TMainViewModel.Summary: string;
begin
  Result := 'Lucent studio, October: ' + Money(CounterValue(cProceedsMonth)) + ' proceeds, ' +
    Count(CounterValue(cDownloads7)) + ' downloads in 7 days, ' + Count(CounterValue(cSubscribers)) +
    ' active subscribers, average rating ' + FormatFloat('0.00', CounterValue(cAppRating), UsFormat) + '.';
end;

{ The live data }

procedure TMainViewModel.Simulate;
var
  A, Units: Integer;
  App: TStudioApp;
  Amount, Total: Double;
  Member: TMember;
begin
  Inc(FTicks);
  // Sales: one or two apps sell something every tick
  for A := 0 to Random(2) do
  begin
    App := FApps[Random(FApps.Count - 1)];
    Amount := 40 + Random(220);
    Units := 4 + Random(30);
    App.AddProceeds(Amount);
    App.Notify(['ProceedsText', 'ShareWidth']);
    SetCounter(cProceedsMonth, CounterValue(cProceedsMonth) + Amount);
    SetCounter(cPending, CounterValue(cPending) + Amount * 0.85);
    SetCounter(cNextPayout, CounterValue(cNextPayout) + Amount * 0.85);
    FPayouts[0].Add(Units, Amount);
  end;
  // Downloads, page views and subscribers
  Total := 0;
  for A := 0 to FApps.Count - 1 do
  begin
    Amount := 2 + Random(18);
    FApps[A].AddDownloads(Amount);
    FApps[A].Notify(['DownloadsText', 'Spark7']);
    Total := Total + Amount;
  end;
  FDownloadMonths[11] := FDownloadMonths[11] + Total;
  SetCounter(cDownloads7, CounterValue(cDownloads7) + Total);
  SetCounter(cDownloads30, CounterValue(cDownloads30) + Total);
  SetCounter(cPageViews, CounterValue(cPageViews) + Total * 6 + Random(40));
  FSubs[11] := FSubs[11] + Random(9) - 2;
  FTrials[11] := FTrials[11] + Random(4);
  SetCounter(cSubscribers, SubsAt(11));
  Changed('SubsCaption');
  Changed('ChartCaption');
  Changed('ProceedsDeltaText');
  UpdateAppShares;
  // Now and then something happens
  case FTicks mod 8 of
    3: NewReview;
    6: AdvanceRelease;
  end;
  if FTicks mod 5 = 2 then
  begin
    Member := FMembers[1 + Random(FMembers.Count - 1)];
    if Member.Access <> 'Invited' then
    begin
      if Member.IsOnline then
        Member.SetOnline(False, 'Active just now')
      else
        Member.SetOnline(True, 'Online now');
      SetCounter(cOnline, CounterValue(cOnline) + IfThen(Member.IsOnline, 1, -1));
    end;
  end;
  if FTicks mod 3 = 0 then
    FCampaigns[FTicks div 3 mod 3].SetProgress(Min(100, FCampaigns[FTicks div 3 mod 3].Progress + 1),
      FCampaigns[FTicks div 3 mod 3].Value);
  if Assigned(FOnSeries) then
    FOnSeries;
end;

initialization
  UsFormat := TFormatSettings.Create('en-US');
  UsFormat.ThousandSeparator := ',';
  UsFormat.DecimalSeparator := '.';
end.
