unit MainWindow.Xaml;

{
  TMainWindowBase: base class of TMainWindow, generated from MainWindow.xaml
  by RADWinUI XamlCodeGen 0.4 (tools/XamlCodeGen).

  DO NOT EDIT. Change MainWindow.xaml or the published handlers of TMainWindow
  in MainWindow.pas; the build regenerates this unit.

  Fields      one per x:Name element, in XAML order
  Create      window settings, content, fields, event wiring
  Comments    name the XAML line each item comes from
}

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Forms,
  MainViewModel;  // TMainViewModel, the DataContextType

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TMainWindowBase = class(TWinUIWindow)
  strict private
    FViewModel: TMainViewModel;
    procedure SetViewModel(AValue: TMainViewModel);
  protected
    Surface: TWinUIGrid;                       // MainWindow.xaml(13) <Grid>
    SolidBase: TWinUIBorder;                   // MainWindow.xaml(290) <Border>
    Orb1: TWinUIEllipse;                       // MainWindow.xaml(294) <Ellipse>
    Orb2: TWinUIEllipse;                       // MainWindow.xaml(295) <Ellipse>
    Ribbon1: TWinUICanvas;                     // MainWindow.xaml(296) <Canvas>
    Ribbon2: TWinUICanvas;                     // MainWindow.xaml(301) <Canvas>
    Ribbon3: TWinUICanvas;                     // MainWindow.xaml(305) <Canvas>
    Bubble1: TWinUIEllipse;                    // MainWindow.xaml(309) <Ellipse>
    Bubble2: TWinUIEllipse;                    // MainWindow.xaml(310) <Ellipse>
    Bubble3: TWinUIEllipse;                    // MainWindow.xaml(311) <Ellipse>
    Bubble4: TWinUIEllipse;                    // MainWindow.xaml(312) <Ellipse>
    Bubble5: TWinUIEllipse;                    // MainWindow.xaml(313) <Ellipse>
    Bubble6: TWinUIEllipse;                    // MainWindow.xaml(314) <Ellipse>
    Bubble7: TWinUIEllipse;                    // MainWindow.xaml(315) <Ellipse>
    Bubble8: TWinUIEllipse;                    // MainWindow.xaml(316) <Ellipse>
    Bubble9: TWinUIEllipse;                    // MainWindow.xaml(317) <Ellipse>
    Bubble10: TWinUIEllipse;                   // MainWindow.xaml(318) <Ellipse>
    Bubble11: TWinUIEllipse;                   // MainWindow.xaml(319) <Ellipse>
    Bubble12: TWinUIEllipse;                   // MainWindow.xaml(320) <Ellipse>
    DragRegion: TWinUIGrid;                    // MainWindow.xaml(325) <Grid>
    NavIndicator: TWinUIBorder;                // MainWindow.xaml(345) <Border>
    NavBar: TWinUIStackPanel;                  // MainWindow.xaml(347) <StackPanel>
    NavOverview: TWinUIButton;                 // MainWindow.xaml(348) <Button>
    NavApps: TWinUIButton;                     // MainWindow.xaml(349) <Button>
    NavReleases: TWinUIButton;                 // MainWindow.xaml(350) <Button>
    NavReviews: TWinUIButton;                  // MainWindow.xaml(351) <Button>
    NavAudience: TWinUIButton;                 // MainWindow.xaml(352) <Button>
    NavGrowth: TWinUIButton;                   // MainWindow.xaml(353) <Button>
    NavPayouts: TWinUIButton;                  // MainWindow.xaml(354) <Button>
    NavTeam: TWinUIButton;                     // MainWindow.xaml(355) <Button>
    InboxButton: TWinUIButton;                 // MainWindow.xaml(361) <Button>
    InboxList: TWinUIItemsControl;             // MainWindow.xaml(368) <ItemsControl>
    BellButton: TWinUIButton;                  // MainWindow.xaml(392) <Button>
    NoticeList: TWinUIItemsControl;            // MainWindow.xaml(398) <ItemsControl>
    BellDot: TWinUIEllipse;                    // MainWindow.xaml(422) <Ellipse>
    AvatarButton: TWinUIButton;                // MainWindow.xaml(425) <Button>
    MenuTheme: TWinUIMenuFlyoutItem;           // MainWindow.xaml(432) <MenuFlyoutItem>
    MenuTeam: TWinUIMenuFlyoutItem;            // MainWindow.xaml(437) <MenuFlyoutItem>
    RailSearch: TWinUIButton;                  // MainWindow.xaml(453) <Button>
    RailNew: TWinUIButton;                     // MainWindow.xaml(456) <Button>
    RailCalendar: TWinUIButton;                // MainWindow.xaml(460) <Button>
    ReleaseCalendar: TWinUICalendarView;       // MainWindow.xaml(466) <CalendarView>
    RailUndo: TWinUIButton;                    // MainWindow.xaml(472) <Button>
    RailShare: TWinUIButton;                   // MainWindow.xaml(475) <Button>
    RailUpload: TWinUIButton;                  // MainWindow.xaml(478) <Button>
    RailSettings: TWinUIButton;                // MainWindow.xaml(482) <Button>
    LiveSwitch: TWinUIToggleSwitch;            // MainWindow.xaml(488) <ToggleSwitch>
    MotionSwitch: TWinUIToggleSwitch;          // MainWindow.xaml(489) <ToggleSwitch>
    TransparencySwitch: TWinUIToggleSwitch;    // MainWindow.xaml(490) <ToggleSwitch>
    RailTheme: TWinUIButton;                   // MainWindow.xaml(495) <Button>
    ThemeGlyph: TWinUIFontIcon;                // MainWindow.xaml(496) <FontIcon>
    LiveButton: TWinUIButton;                  // MainWindow.xaml(500) <Button>
    LivePulse: TWinUIEllipse;                  // MainWindow.xaml(504) <Ellipse>
    PageHost: TWinUIGrid;                      // MainWindow.xaml(510) <Grid>
    PageOverview: TWinUIScrollViewer;          // MainWindow.xaml(513) <ScrollViewer>
    OvTitle: TWinUIStackPanel;                 // MainWindow.xaml(520) <StackPanel>
    OvKpis: TWinUIStackPanel;                  // MainWindow.xaml(524) <StackPanel>
    OvProceedsLabel: TWinUITextBlock;          // MainWindow.xaml(530) <TextBlock>
    ProceedsColumn: TWinUIColumnDefinition;    // MainWindow.xaml(567) <ColumnDefinition>
    RatingsColumn: TWinUIColumnDefinition;     // MainWindow.xaml(568) <ColumnDefinition>
    ProceedsCard: TWinUIBorder;                // MainWindow.xaml(570) <Border>
    ChartTitle: TWinUITextBlock;               // MainWindow.xaml(585) <TextBlock>
    SeriesProceeds: TWinUIToggleButton;        // MainWindow.xaml(590) <ToggleButton>
    SeriesDownloads: TWinUIToggleButton;       // MainWindow.xaml(591) <ToggleButton>
    MenuExportChart: TWinUIMenuFlyoutItem;     // MainWindow.xaml(598) <MenuFlyoutItem>
    MenuLastYear: TWinUIToggleMenuFlyoutItem;  // MainWindow.xaml(599) <ToggleMenuFlyoutItem>
    ExpandButton: TWinUIButton;                // MainWindow.xaml(603) <Button>
    ExpandGlyph: TWinUIFontIcon;               // MainWindow.xaml(605) <FontIcon>
    ProceedsCanvas: TWinUICanvas;              // MainWindow.xaml(622) <Canvas>
    ProceedsArea: TWinUIPolygon;               // MainWindow.xaml(623) <Polygon>
    ProceedsLastYear: TWinUIPolyline;          // MainWindow.xaml(631) <Polyline>
    ProceedsLine: TWinUIPolyline;              // MainWindow.xaml(632) <Polyline>
    ProceedsGlow: TWinUIEllipse;               // MainWindow.xaml(633) <Ellipse>
    ProceedsDot: TWinUIEllipse;                // MainWindow.xaml(634) <Ellipse>
    RatingsCard: TWinUIBorder;                 // MainWindow.xaml(658) <Border>
    StarBarList: TWinUIItemsControl;           // MainWindow.xaml(674) <ItemsControl>
    YourAppsCard: TWinUIBorder;                // MainWindow.xaml(707) <Border>
    AllAppsButton: TWinUIButton;               // MainWindow.xaml(726) <Button>
    OverviewApps: TWinUIGridView;              // MainWindow.xaml(730) <GridView>
    PageApps: TWinUIScrollViewer;              // MainWindow.xaml(780) <ScrollViewer>
    ApTitle: TWinUIStackPanel;                 // MainWindow.xaml(787) <StackPanel>
    ApKpis: TWinUIStackPanel;                  // MainWindow.xaml(791) <StackPanel>
    ApToolbar: TWinUIGrid;                     // MainWindow.xaml(821) <Grid>
    AppSearch: TWinUITextBox;                  // MainWindow.xaml(827) <TextBox>
    SortProceeds: TWinUIToggleButton;          // MainWindow.xaml(831) <ToggleButton>
    SortDownloads: TWinUIToggleButton;         // MainWindow.xaml(832) <ToggleButton>
    SortRating: TWinUIToggleButton;            // MainWindow.xaml(833) <ToggleButton>
    AppGrid: TWinUIGridView;                   // MainWindow.xaml(836) <GridView>
    NoAppsText: TWinUITextBlock;               // MainWindow.xaml(924) <TextBlock>
    PageDetail: TWinUIScrollViewer;            // MainWindow.xaml(929) <ScrollViewer>
    BackButton: TWinUIButton;                  // MainWindow.xaml(937) <Button>
    DeTitle: TWinUIStackPanel;                 // MainWindow.xaml(941) <StackPanel>
    DetailNameLabel: TWinUITextBlock;          // MainWindow.xaml(942) <TextBlock>
    DeKpis: TWinUIStackPanel;                  // MainWindow.xaml(945) <StackPanel>
    DetailHero: TWinUIGrid;                    // MainWindow.xaml(975) <Grid>
    DetailSparkCanvas: TWinUICanvas;           // MainWindow.xaml(1009) <Canvas>
    DetailSpark: TWinUIPolyline;               // MainWindow.xaml(1010) <Polyline>
    DetailTabs: TWinUIStackPanel;              // MainWindow.xaml(1015) <StackPanel>
    DetailTabOverview: TWinUIToggleButton;     // MainWindow.xaml(1016) <ToggleButton>
    DetailTabVersions: TWinUIToggleButton;     // MainWindow.xaml(1017) <ToggleButton>
    DetailTabIap: TWinUIToggleButton;          // MainWindow.xaml(1018) <ToggleButton>
    DetailTabReviews: TWinUIToggleButton;      // MainWindow.xaml(1019) <ToggleButton>
    DetailBody: TWinUIGrid;                    // MainWindow.xaml(1021) <Grid>
    DetailOverview: TWinUIGrid;                // MainWindow.xaml(1022) <Grid>
    DetailCanvas: TWinUICanvas;                // MainWindow.xaml(1041) <Canvas>
    DetailArea: TWinUIPolygon;                 // MainWindow.xaml(1042) <Polygon>
    DetailLine: TWinUIPolyline;                // MainWindow.xaml(1050) <Polyline>
    DetailBars: TWinUIItemsControl;            // MainWindow.xaml(1062) <ItemsControl>
    DetailVersions: TWinUIBorder;              // MainWindow.xaml(1083) <Border>
    VersionList: TWinUIItemsControl;           // MainWindow.xaml(1084) <ItemsControl>
    DetailIap: TWinUIBorder;                   // MainWindow.xaml(1105) <Border>
    IapList: TWinUIItemsControl;               // MainWindow.xaml(1106) <ItemsControl>
    DetailReviews: TWinUIBorder;               // MainWindow.xaml(1127) <Border>
    DetailReviewList: TWinUIItemsControl;      // MainWindow.xaml(1128) <ItemsControl>
    PageReleases: TWinUIScrollViewer;          // MainWindow.xaml(1148) <ScrollViewer>
    ReTitle: TWinUIStackPanel;                 // MainWindow.xaml(1155) <StackPanel>
    ReKpis: TWinUIStackPanel;                  // MainWindow.xaml(1159) <StackPanel>
    InFlightLabel: TWinUITextBlock;            // MainWindow.xaml(1164) <TextBlock>
    ReToolbar: TWinUIGrid;                     // MainWindow.xaml(1189) <Grid>
    NewReleaseButton: TWinUIButton;            // MainWindow.xaml(1204) <Button>
    FilterAll: TWinUIToggleButton;             // MainWindow.xaml(1212) <ToggleButton>
    Filter0: TWinUIToggleButton;               // MainWindow.xaml(1213) <ToggleButton>
    Filter1: TWinUIToggleButton;               // MainWindow.xaml(1214) <ToggleButton>
    Filter2: TWinUIToggleButton;               // MainWindow.xaml(1215) <ToggleButton>
    Filter3: TWinUIToggleButton;               // MainWindow.xaml(1216) <ToggleButton>
    Filter4: TWinUIToggleButton;               // MainWindow.xaml(1217) <ToggleButton>
    Filter5: TWinUIToggleButton;               // MainWindow.xaml(1218) <ToggleButton>
    ViewBoard: TWinUIToggleButton;             // MainWindow.xaml(1222) <ToggleButton>
    ViewTimeline: TWinUIToggleButton;          // MainWindow.xaml(1228) <ToggleButton>
    BoardCard: TWinUIBorder;                   // MainWindow.xaml(1237) <Border>
    Column0: TWinUIListView;                   // MainWindow.xaml(1264) <ListView>
    Column1: TWinUIListView;                   // MainWindow.xaml(1285) <ListView>
    Column2: TWinUIListView;                   // MainWindow.xaml(1306) <ListView>
    Column3: TWinUIListView;                   // MainWindow.xaml(1327) <ListView>
    Column4: TWinUIListView;                   // MainWindow.xaml(1348) <ListView>
    TimelineCard: TWinUIBorder;                // MainWindow.xaml(1359) <Border>
    TimelineList: TWinUIItemsControl;          // MainWindow.xaml(1373) <ItemsControl>
    PageReviews: TWinUIScrollViewer;           // MainWindow.xaml(1410) <ScrollViewer>
    RvTitle: TWinUIStackPanel;                 // MainWindow.xaml(1417) <StackPanel>
    RvKpis: TWinUIStackPanel;                  // MainWindow.xaml(1421) <StackPanel>
    WrittenLabel: TWinUITextBlock;             // MainWindow.xaml(1435) <TextBlock>
    RvSummary: TWinUIBorder;                   // MainWindow.xaml(1456) <Border>
    ReviewBars: TWinUIItemsControl;            // MainWindow.xaml(1463) <ItemsControl>
    RvList: TWinUIStackPanel;                  // MainWindow.xaml(1489) <StackPanel>
    StarsAll: TWinUIToggleButton;              // MainWindow.xaml(1496) <ToggleButton>
    Stars5: TWinUIToggleButton;                // MainWindow.xaml(1497) <ToggleButton>
    Stars4: TWinUIToggleButton;                // MainWindow.xaml(1498) <ToggleButton>
    Stars3: TWinUIToggleButton;                // MainWindow.xaml(1499) <ToggleButton>
    Stars2: TWinUIToggleButton;                // MainWindow.xaml(1500) <ToggleButton>
    Stars1: TWinUIToggleButton;                // MainWindow.xaml(1501) <ToggleButton>
    ReviewAppBox: TWinUIComboBox;              // MainWindow.xaml(1503) <ComboBox>
    ReviewList: TWinUIListView;                // MainWindow.xaml(1506) <ListView>
    PageAudience: TWinUIScrollViewer;          // MainWindow.xaml(1559) <ScrollViewer>
    AuTitle: TWinUIStackPanel;                 // MainWindow.xaml(1566) <StackPanel>
    AuKpis: TWinUIStackPanel;                  // MainWindow.xaml(1570) <StackPanel>
    AuFilters: TWinUIStackPanel;               // MainWindow.xaml(1600) <StackPanel>
    AudAll: TWinUIToggleButton;                // MainWindow.xaml(1601) <ToggleButton>
    Aud0: TWinUIToggleButton;                  // MainWindow.xaml(1602) <ToggleButton>
    Aud1: TWinUIToggleButton;                  // MainWindow.xaml(1603) <ToggleButton>
    Aud2: TWinUIToggleButton;                  // MainWindow.xaml(1604) <ToggleButton>
    Aud3: TWinUIToggleButton;                  // MainWindow.xaml(1605) <ToggleButton>
    Aud4: TWinUIToggleButton;                  // MainWindow.xaml(1606) <ToggleButton>
    Aud5: TWinUIToggleButton;                  // MainWindow.xaml(1607) <ToggleButton>
    SubsCard: TWinUIBorder;                    // MainWindow.xaml(1614) <Border>
    SubsCanvas: TWinUICanvas;                  // MainWindow.xaml(1654) <Canvas>
    SubsArea: TWinUIPolygon;                   // MainWindow.xaml(1655) <Polygon>
    TrialLine: TWinUIPolyline;                 // MainWindow.xaml(1663) <Polyline>
    SubsLine: TWinUIPolyline;                  // MainWindow.xaml(1664) <Polyline>
    SubsHover: TWinUIGrid;                     // MainWindow.xaml(1666) <Grid>
    SubsGuide: TWinUIRectangle;                // MainWindow.xaml(1667) <Rectangle>
    SubsDot: TWinUIEllipse;                    // MainWindow.xaml(1668) <Ellipse>
    TrialDot: TWinUIEllipse;                   // MainWindow.xaml(1670) <Ellipse>
    SubsTip: TWinUIBorder;                     // MainWindow.xaml(1672) <Border>
    TipMonth: TWinUITextBlock;                 // MainWindow.xaml(1675) <TextBlock>
    TipSubs: TWinUITextBlock;                  // MainWindow.xaml(1678) <TextBlock>
    TipTrial: TWinUITextBlock;                 // MainWindow.xaml(1682) <TextBlock>
    PlansCard: TWinUIBorder;                   // MainWindow.xaml(1709) <Border>
    Donut: TWinUIGrid;                         // MainWindow.xaml(1717) <Grid>
    PlanArc0: TWinUIEllipse;                   // MainWindow.xaml(1719) <Ellipse>
    PlanArc1: TWinUIEllipse;                   // MainWindow.xaml(1722) <Ellipse>
    PlanArc2: TWinUIEllipse;                   // MainWindow.xaml(1725) <Ellipse>
    CohortCard: TWinUIBorder;                  // MainWindow.xaml(1764) <Border>
    ExportCsvButton: TWinUIButton;             // MainWindow.xaml(1771) <Button>
    CohortList: TWinUIItemsControl;            // MainWindow.xaml(1792) <ItemsControl>
    CancelCard: TWinUIBorder;                  // MainWindow.xaml(1816) <Border>
    CancelList: TWinUIItemsControl;            // MainWindow.xaml(1824) <ItemsControl>
    PageGrowth: TWinUIScrollViewer;            // MainWindow.xaml(1846) <ScrollViewer>
    GrTitle: TWinUIStackPanel;                 // MainWindow.xaml(1853) <StackPanel>
    GrKpis: TWinUIStackPanel;                  // MainWindow.xaml(1857) <StackPanel>
    SourcesCard: TWinUIBorder;                 // MainWindow.xaml(1892) <Border>
    SourceList: TWinUIItemsControl;            // MainWindow.xaml(1898) <ItemsControl>
    FunnelCard: TWinUIBorder;                  // MainWindow.xaml(1924) <Border>
    FunnelList: TWinUIItemsControl;            // MainWindow.xaml(1930) <ItemsControl>
    RegionsCard: TWinUIBorder;                 // MainWindow.xaml(1958) <Border>
    RegionList: TWinUIItemsControl;            // MainWindow.xaml(1961) <ItemsControl>
    CampaignCard: TWinUIBorder;                // MainWindow.xaml(1985) <Border>
    CampaignList: TWinUIItemsControl;          // MainWindow.xaml(1988) <ItemsControl>
    PagePayouts: TWinUIScrollViewer;           // MainWindow.xaml(2016) <ScrollViewer>
    PaTitle: TWinUIStackPanel;                 // MainWindow.xaml(2023) <StackPanel>
    PaKpis: TWinUIStackPanel;                  // MainWindow.xaml(2027) <StackPanel>
    NextPayoutCard: TWinUIGrid;                // MainWindow.xaml(2054) <Grid>
    NextPayoutLabel: TWinUITextBlock;          // MainWindow.xaml(2076) <TextBlock>
    SplitCard: TWinUIBorder;                   // MainWindow.xaml(2095) <Border>
    SplitList: TWinUIItemsControl;             // MainWindow.xaml(2098) <ItemsControl>
    HistoryCard: TWinUIBorder;                 // MainWindow.xaml(2126) <Border>
    StatementButton: TWinUIButton;             // MainWindow.xaml(2130) <Button>
    PayoutList: TWinUIItemsControl;            // MainWindow.xaml(2154) <ItemsControl>
    AccountRow: TWinUIGrid;                    // MainWindow.xaml(2186) <Grid>
    InstantSwitch: TWinUIToggleSwitch;         // MainWindow.xaml(2207) <ToggleSwitch>
    PageTeam: TWinUIScrollViewer;              // MainWindow.xaml(2240) <ScrollViewer>
    TeTitle: TWinUIStackPanel;                 // MainWindow.xaml(2247) <StackPanel>
    TeKpis: TWinUIStackPanel;                  // MainWindow.xaml(2251) <StackPanel>
    MembersLabel: TWinUITextBlock;             // MainWindow.xaml(2256) <TextBlock>
    InviteButton: TWinUIButton;                // MainWindow.xaml(2279) <Button>
    TeamGrid: TWinUIGridView;                  // MainWindow.xaml(2293) <GridView>
    ActivityCard: TWinUIBorder;                // MainWindow.xaml(2340) <Border>
    ActivityList: TWinUIItemsControl;          // MainWindow.xaml(2349) <ItemsControl>
    Toast: TWinUIBorder;                       // MainWindow.xaml(2379) <Border>
    ToastTitleLabel: TWinUITextBlock;          // MainWindow.xaml(2392) <TextBlock>
  public
    constructor Create; override;
    /// <summary>
    ///   The TMainViewModel the XAML binds to (MainWindow.xaml(1): DataContextType);
    ///   setting it sets DataContext. The window does not own it.
    /// </summary>
    property ViewModel: TMainViewModel read FViewModel write SetViewModel;
  end;
  {$M-}

implementation

const
  // MainWindow.xaml(13): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="Surface">' + sLineBreak +
    '    <Grid.Resources>' + sLineBreak +
    '      <ResourceDictionary>' + sLineBreak +
    '        <ResourceDictionary.ThemeDictionaries>' + sLineBreak +
    '          <ResourceDictionary x:Key="Dark">' + sLineBreak +
    '            ' + sLineBreak +
    '            <LinearGradientBrush x:Key="BackdropBrush" StartPoint="0,0" EndPoint="1,1">' + sLineBreak +
    '              <GradientStop Color="#B80B0B0D" Offset="0" />' + sLineBreak +
    '              <GradientStop Color="#9E15161A" Offset="0.55" />' + sLineBreak +
    '              <GradientStop Color="#B80D0E11" Offset="1" />' + sLineBreak +
    '            </LinearGradientBrush>' + sLineBreak +
    '            <SolidColorBrush x:Key="SolidBaseBrush" Color="#0E0F12" />' + sLineBreak +
    '            <LinearGradientBrush x:Key="RibbonBrush" StartPoint="0,0" EndPoint="1,1">' + sLineBreak +
    '              <GradientStop Color="#00FFFFFF" Offset="0" />' + sLineBreak +
    '              <GradientStop Color="#26FFFFFF" Offset="0.3" />' + sLineBreak +
    '              <GradientStop Color="#0AFFFFFF" Offset="0.55" />' + sLineBreak +
    '              <GradientStop Color="#33FFFFFF" Offset="0.8" />' + sLineBreak +
    '              <GradientStop Color="#05FFFFFF" Offset="1" />' + sLineBreak +
    '            </LinearGradientBrush>' + sLineBreak +
    '            <SolidColorBrush x:Key="RibbonRimBrush" Color="#38FFFFFF" />' + sLineBreak +
    '            <RadialGradientBrush x:Key="BubbleBrush" GradientOrigin="0.32,0.26" Center="0.5,0.5" RadiusX="0.5" RadiusY="0.5">' + sLineBreak +
    '              <GradientStop Color="#66FFFFFF" Offset="0" />' + sLineBreak +
    '              <GradientStop Color="#14FFFFFF" Offset="0.45" />' + sLineBreak +
    '              <GradientStop Color="#08FFFFFF" Offset="0.8" />' + sLineBreak +
    '              <GradientStop Color="#2EFFFFFF" Offset="1" />' + sLineBreak +
    '            </RadialGradientBrush>' + sLineBreak +
    '            <SolidColorBrush x:Key="BubbleRimBrush" Color="#70FFFFFF" />' + sLineBreak +
    '            <AcrylicBrush x:Key="GlassBrush" TintColor="#17181C" TintOpacity="0.32" TintLuminosityOpacity="0.55" FallbackColor="#E61A1B1F" />' + sLineBreak +
    '            <AcrylicBrush x:Key="GlassStrongBrush" TintColor="#1C1D22" TintOpacity="0.5" TintLuminosityOpacity="0.7" FallbackColor="#F21C1D22" />' + sLineBreak +
    '            <LinearGradientBrush x:Key="GlassRimBrush" StartPoint="0,0" EndPoint="0.4,1">' + sLineBreak +
    '              <GradientStop Color="#59FFFFFF" Offset="0" />' + sLineBreak +
    '              <GradientStop Color="#14FFFFFF" Offset="0.45" />' + sLineBreak +
    '              <GradientStop Color="#0AFFFFFF" Offset="0.8" />' + sLineBreak +
    '              <GradientStop Color="#1FFFFFFF" Offset="1" />' + sLineBreak +
    '            </LinearGradientBrush>' + sLineBreak +
    '            <SolidColorBrush x:Key="InnerBrush" Color="#0FFFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="InnerRimBrush" Color="#14FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SelectedPillBrush" Color="#26FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="LineBrush" Color="#1AFFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="MutedBrush" Color="#8CFFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="FaintBrush" Color="#59FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AvatarBrush" Color="#E6F2F3F5" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AvatarTextBrush" Color="#16171A" />' + sLineBreak +
    '            <SolidColorBrush x:Key="GoodBrush" Color="#4ADE9B" />' + sLineBreak +
    '            <SolidColorBrush x:Key="GoodSoftBrush" Color="#264ADE9B" />' + sLineBreak +
    '            <SolidColorBrush x:Key="BadBrush" Color="#FF7A7A" />' + sLineBreak +
    '            <SolidColorBrush x:Key="BadSoftBrush" Color="#26FF7A7A" />' + sLineBreak +
    '            <SolidColorBrush x:Key="WarnBrush" Color="#F6BE55" />' + sLineBreak +
    '            <SolidColorBrush x:Key="WarnSoftBrush" Color="#26F6BE55" />' + sLineBreak +
    '            <SolidColorBrush x:Key="TealBrush" Color="#4FD1C5" />' + sLineBreak +
    '            <SolidColorBrush x:Key="StarBrush" Color="#F6C453" />' + sLineBreak +
    '          </ResourceDictionary>' + sLineBreak +
    '          <ResourceDictionary x:Key="Light">' + sLineBreak +
    '            <LinearGradientBrush x:Key="BackdropBrush" StartPoint="0,0" EndPoint="1,1">' + sLineBreak +
    '              <GradientStop Color="#B8EDEFF3" Offset="0" />' + sLineBreak +
    '              <GradientStop Color="#9EE2E5EA" Offset="0.55" />' + sLineBreak +
    '              <GradientStop Color="#B8F2F3F6" Offset="1" />' + sLineBreak +
    '            </LinearGradientBrush>' + sLineBreak +
    '            <SolidColorBrush x:Key="SolidBaseBrush" Color="#E9EBEF" />' + sLineBreak +
    '            <LinearGradientBrush x:Key="RibbonBrush" StartPoint="0,0" EndPoint="1,1">' + sLineBreak +
    '              <GradientStop Color="#00FFFFFF" Offset="0" />' + sLineBreak +
    '              <GradientStop Color="#B3FFFFFF" Offset="0.3" />' + sLineBreak +
    '              <GradientStop Color="#14000000" Offset="0.55" />' + sLineBreak +
    '              <GradientStop Color="#CCFFFFFF" Offset="0.8" />' + sLineBreak +
    '              <GradientStop Color="#00FFFFFF" Offset="1" />' + sLineBreak +
    '            </LinearGradientBrush>' + sLineBreak +
    '            <SolidColorBrush x:Key="RibbonRimBrush" Color="#E6FFFFFF" />' + sLineBreak +
    '            <RadialGradientBrush x:Key="BubbleBrush" GradientOrigin="0.32,0.26" Center="0.5,0.5" RadiusX="0.5" RadiusY="0.5">' + sLineBreak +
    '              <GradientStop Color="#F2FFFFFF" Offset="0" />' + sLineBreak +
    '              <GradientStop Color="#33FFFFFF" Offset="0.55" />' + sLineBreak +
    '              <GradientStop Color="#14000000" Offset="1" />' + sLineBreak +
    '            </RadialGradientBrush>' + sLineBreak +
    '            <SolidColorBrush x:Key="BubbleRimBrush" Color="#F2FFFFFF" />' + sLineBreak +
    '            <AcrylicBrush x:Key="GlassBrush" TintColor="#FFFFFF" TintOpacity="0.38" TintLuminosityOpacity="0.62" FallbackColor="#EBF7F8FA" />' + sLineBreak +
    '            <AcrylicBrush x:Key="GlassStrongBrush" TintColor="#FFFFFF" TintOpacity="0.55" TintLuminosityOpacity="0.8" FallbackColor="#F5FAFBFC" />' + sLineBreak +
    '            <LinearGradientBrush x:Key="GlassRimBrush" StartPoint="0,0" EndPoint="0.4,1">' + sLineBreak +
    '              <GradientStop Color="#FFFFFFFF" Offset="0" />' + sLineBreak +
    '              <GradientStop Color="#80FFFFFF" Offset="0.45" />' + sLineBreak +
    '              <GradientStop Color="#0F000000" Offset="0.85" />' + sLineBreak +
    '              <GradientStop Color="#1A000000" Offset="1" />' + sLineBreak +
    '            </LinearGradientBrush>' + sLineBreak +
    '            <SolidColorBrush x:Key="InnerBrush" Color="#99FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="InnerRimBrush" Color="#14000000" />' + sLineBreak +
    '            <SolidColorBrush x:Key="SelectedPillBrush" Color="#F2FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="LineBrush" Color="#1A000000" />' + sLineBreak +
    '            <SolidColorBrush x:Key="MutedBrush" Color="#99000000" />' + sLineBreak +
    '            <SolidColorBrush x:Key="FaintBrush" Color="#4D000000" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AvatarBrush" Color="#1E1F23" />' + sLineBreak +
    '            <SolidColorBrush x:Key="AvatarTextBrush" Color="#FFFFFF" />' + sLineBreak +
    '            <SolidColorBrush x:Key="GoodBrush" Color="#178A54" />' + sLineBreak +
    '            <SolidColorBrush x:Key="GoodSoftBrush" Color="#24178A54" />' + sLineBreak +
    '            <SolidColorBrush x:Key="BadBrush" Color="#D23C3C" />' + sLineBreak +
    '            <SolidColorBrush x:Key="BadSoftBrush" Color="#1FD23C3C" />' + sLineBreak +
    '            <SolidColorBrush x:Key="WarnBrush" Color="#B7791F" />' + sLineBreak +
    '            <SolidColorBrush x:Key="WarnSoftBrush" Color="#24B7791F" />' + sLineBreak +
    '            <SolidColorBrush x:Key="TealBrush" Color="#16968A" />' + sLineBreak +
    '            <SolidColorBrush x:Key="StarBrush" Color="#E0A31A" />' + sLineBreak +
    '          </ResourceDictionary>' + sLineBreak +
    '        </ResourceDictionary.ThemeDictionaries>' + sLineBreak +
    '' + sLineBreak +
    '        <Style x:Key="Glass" TargetType="Border">' + sLineBreak +
    '          <Setter Property="Background" Value="{ThemeResource GlassBrush}" />' + sLineBreak +
    '          <Setter Property="BorderBrush" Value="{ThemeResource GlassRimBrush}" />' + sLineBreak +
    '          <Setter Property="BorderThickness" Value="1" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="26" />' + sLineBreak +
    '          <Setter Property="Padding" Value="24,22" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="GlassPill" TargetType="Border">' + sLineBreak +
    '          <Setter Property="Background" Value="{ThemeResource GlassBrush}" />' + sLineBreak +
    '          <Setter Property="BorderBrush" Value="{ThemeResource GlassRimBrush}" />' + sLineBreak +
    '          <Setter Property="BorderThickness" Value="1" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="30" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="Inner" TargetType="Border">' + sLineBreak +
    '          <Setter Property="Background" Value="{ThemeResource InnerBrush}" />' + sLineBreak +
    '          <Setter Property="BorderBrush" Value="{ThemeResource InnerRimBrush}" />' + sLineBreak +
    '          <Setter Property="BorderThickness" Value="1" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="18" />' + sLineBreak +
    '          <Setter Property="Padding" Value="16,14" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="IconDisc" TargetType="Border">' + sLineBreak +
    '          <Setter Property="Width" Value="44" />' + sLineBreak +
    '          <Setter Property="Height" Value="44" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="22" />' + sLineBreak +
    '          <Setter Property="Background" Value="{ThemeResource InnerBrush}" />' + sLineBreak +
    '          <Setter Property="BorderBrush" Value="{ThemeResource InnerRimBrush}" />' + sLineBreak +
    '          <Setter Property="BorderThickness" Value="1" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="Round" TargetType="Button">' + sLineBreak +
    '          <Setter Property="Width" Value="42" />' + sLineBreak +
    '          <Setter Property="Height" Value="42" />' + sLineBreak +
    '          <Setter Property="Padding" Value="0" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="21" />' + sLineBreak +
    '          <Setter Property="Background" Value="Transparent" />' + sLineBreak +
    '          <Setter Property="BorderThickness" Value="0" />' + sLineBreak +
    '          <Setter Property="HorizontalContentAlignment" Value="Center" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="RoundInner" TargetType="Button">' + sLineBreak +
    '          <Setter Property="Width" Value="36" />' + sLineBreak +
    '          <Setter Property="Height" Value="36" />' + sLineBreak +
    '          <Setter Property="Padding" Value="0" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="18" />' + sLineBreak +
    '          <Setter Property="Background" Value="{ThemeResource InnerBrush}" />' + sLineBreak +
    '          <Setter Property="BorderBrush" Value="{ThemeResource InnerRimBrush}" />' + sLineBreak +
    '          <Setter Property="BorderThickness" Value="1" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="NavTab" TargetType="Button">' + sLineBreak +
    '          <Setter Property="Width" Value="98" />' + sLineBreak +
    '          <Setter Property="Height" Value="40" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="20" />' + sLineBreak +
    '          <Setter Property="Background" Value="Transparent" />' + sLineBreak +
    '          <Setter Property="BorderThickness" Value="0" />' + sLineBreak +
    '          <Setter Property="FontSize" Value="13" />' + sLineBreak +
    '          <Setter Property="HorizontalContentAlignment" Value="Center" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="Chip" TargetType="ToggleButton">' + sLineBreak +
    '          <Setter Property="Padding" Value="14,6" />' + sLineBreak +
    '          <Setter Property="MinHeight" Value="32" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="16" />' + sLineBreak +
    '          <Setter Property="FontSize" Value="12" />' + sLineBreak +
    '          <Setter Property="Background" Value="{ThemeResource InnerBrush}" />' + sLineBreak +
    '          <Setter Property="BorderBrush" Value="{ThemeResource InnerRimBrush}" />' + sLineBreak +
    '          <Setter Property="BorderThickness" Value="1" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="Accent" TargetType="Button">' + sLineBreak +
    '          <Setter Property="Padding" Value="18,9" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="20" />' + sLineBreak +
    '          <Setter Property="FontSize" Value="13" />' + sLineBreak +
    '          <Setter Property="Background" Value="{ThemeResource AccentFillColorDefaultBrush}" />' + sLineBreak +
    '          <Setter Property="Foreground" Value="{ThemeResource TextOnAccentFillColorPrimaryBrush}" />' + sLineBreak +
    '          <Setter Property="BorderThickness" Value="0" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="PageFirst" TargetType="TextBlock">' + sLineBreak +
    '          <Setter Property="FontSize" Value="46" />' + sLineBreak +
    '          <Setter Property="FontWeight" Value="Light" />' + sLineBreak +
    '          <Setter Property="FontFamily" Value="Segoe UI Variable Display" />' + sLineBreak +
    '          <Setter Property="Foreground" Value="{ThemeResource MutedBrush}" />' + sLineBreak +
    '          <Setter Property="LineHeight" Value="50" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="PageSecond" TargetType="TextBlock">' + sLineBreak +
    '          <Setter Property="FontSize" Value="46" />' + sLineBreak +
    '          <Setter Property="FontWeight" Value="SemiBold" />' + sLineBreak +
    '          <Setter Property="FontFamily" Value="Segoe UI Variable Display" />' + sLineBreak +
    '          <Setter Property="LineHeight" Value="50" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="CardTitle" TargetType="TextBlock">' + sLineBreak +
    '          <Setter Property="FontSize" Value="18" />' + sLineBreak +
    '          <Setter Property="FontWeight" Value="SemiBold" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="Caption" TargetType="TextBlock">' + sLineBreak +
    '          <Setter Property="FontSize" Value="12" />' + sLineBreak +
    '          <Setter Property="Foreground" Value="{ThemeResource MutedBrush}" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="KpiValue" TargetType="TextBlock">' + sLineBreak +
    '          <Setter Property="FontSize" Value="22" />' + sLineBreak +
    '          <Setter Property="FontWeight" Value="SemiBold" />' + sLineBreak +
    '          <Setter Property="FontFamily" Value="Segoe UI Variable Display" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="Kpi" TargetType="Border">' + sLineBreak +
    '          <Setter Property="Background" Value="{ThemeResource GlassBrush}" />' + sLineBreak +
    '          <Setter Property="BorderBrush" Value="{ThemeResource GlassRimBrush}" />' + sLineBreak +
    '          <Setter Property="BorderThickness" Value="1" />' + sLineBreak +
    '          <Setter Property="CornerRadius" Value="32" />' + sLineBreak +
    '          <Setter Property="Padding" Value="9,9,22,9" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="Bare" TargetType="ListViewItem">' + sLineBreak +
    '          <Setter Property="Padding" Value="0" />' + sLineBreak +
    '          <Setter Property="Margin" Value="0,0,0,10" />' + sLineBreak +
    '          <Setter Property="MinHeight" Value="0" />' + sLineBreak +
    '          <Setter Property="HorizontalContentAlignment" Value="Stretch" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <Style x:Key="BareGrid" TargetType="GridViewItem">' + sLineBreak +
    '          <Setter Property="Padding" Value="0" />' + sLineBreak +
    '          <Setter Property="Margin" Value="0,0,16,16" />' + sLineBreak +
    '        </Style>' + sLineBreak +
    '        <DataTemplate x:Key="ReleaseCard">' + sLineBreak +
    '          <Border Padding="14,12" CornerRadius="18" Background="{ThemeResource GlassBrush}" BorderBrush="{ThemeResource GlassRimBrush}" BorderThickness="1">' + sLineBreak +
    '            <StackPanel Spacing="10">' + sLineBreak +
    '              <Grid ColumnSpacing="10">' + sLineBreak +
    '                <Grid.ColumnDefinitions>' + sLineBreak +
    '                  <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                  <ColumnDefinition Width="*" />' + sLineBreak +
    '                  <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                </Grid.ColumnDefinitions>' + sLineBreak +
    '                <Border Width="34" Height="34" CornerRadius="10" Background="{Binding Tint}">' + sLineBreak +
    '                  <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="{Binding Glyph}" FontSize="14" Foreground="White" />' + sLineBreak +
    '                </Border>' + sLineBreak +
    '                <StackPanel Grid.Column="1" VerticalAlignment="Center">' + sLineBreak +
    '                  <TextBlock Text="{Binding Title}" FontSize="13" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" />' + sLineBreak +
    '                  <TextBlock Text="{Binding BuildText}" FontSize="11" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <FontIcon Grid.Column="2" FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="12" VerticalAlignment="Top" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <TextBlock Text="{Binding Notes}" FontSize="12" TextWrapping="Wrap" MaxLines="2" TextTrimming="CharacterEllipsis" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '              <StackPanel Spacing="5" Visibility="{Binding Tested, Converter={StaticResource BoolToVisibility}}">' + sLineBreak +
    '                <ProgressBar Value="{Binding CrashFree}" Minimum="95" Maximum="100" Foreground="{Binding HealthBrush}" />' + sLineBreak +
    '                <TextBlock Text="{Binding CrashText}" FontSize="11" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Border CornerRadius="9" Padding="8,2" HorizontalAlignment="Left" Background="{ThemeResource InnerBrush}" Visibility="{Binding Tested, Converter={StaticResource InverseBoolToVisibility}}' +
    '">' + sLineBreak +
    '                <TextBlock Text="Not tested yet" FontSize="11" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Grid>' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                  <Border Width="24" Height="24" CornerRadius="12" Background="{ThemeResource AvatarBrush}">' + sLineBreak +
    '                    <TextBlock Text="{Binding Owner}" FontSize="9" FontWeight="SemiBold" Foreground="{ThemeResource AvatarTextBrush}" HorizontalAlignment="Center" VerticalAlignment="Center" />' + sLineBreak +
    '                  </Border>' + sLineBreak +
    '                  <TextBlock Text="{Binding AgeText}" FontSize="11" VerticalAlignment="Center" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <Border HorizontalAlignment="Right" CornerRadius="9" Padding="8,2" Background="{ThemeResource GoodSoftBrush}" Visibility="{Binding Current, Converter={StaticResource BoolToVisibility}}' +
    '">' + sLineBreak +
    '                  <TextBlock Text="Current" FontSize="11" Foreground="{ThemeResource GoodBrush}" />' + sLineBreak +
    '                </Border>' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="5" HorizontalAlignment="Right" VerticalAlignment="Center" Visibility="{Binding Current, Converter={StaticResource InverseBoolToVisibility}' +
    '}">' + sLineBreak +
    '                  <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="11" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                  <TextBlock Text="{Binding TestersText}" FontSize="11" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '        </DataTemplate>' + sLineBreak +
    '      </ResourceDictionary>' + sLineBreak +
    '    </Grid.Resources>' + sLineBreak +
    '    <Grid.RowDefinitions>' + sLineBreak +
    '      <RowDefinition Height="80" />' + sLineBreak +
    '      <RowDefinition Height="*" />' + sLineBreak +
    '    </Grid.RowDefinitions>' + sLineBreak +
    '    <Grid.ColumnDefinitions>' + sLineBreak +
    '      <ColumnDefinition Width="92" />' + sLineBreak +
    '      <ColumnDefinition Width="*" />' + sLineBreak +
    '    </Grid.ColumnDefinitions>' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Grid Grid.RowSpan="2" Grid.ColumnSpan="2" IsHitTestVisible="False">' + sLineBreak +
    '      ' + sLineBreak +
    '      <Border x:Name="SolidBase" Background="{ThemeResource SolidBaseBrush}" Visibility="Collapsed" />' + sLineBreak +
    '      <Border Background="{ThemeResource BackdropBrush}" />' + sLineBreak +
    '      <Viewbox Stretch="UniformToFill">' + sLineBreak +
    '        <Canvas Width="1600" Height="1000">' + sLineBreak +
    '          <Ellipse x:Name="Orb1" Canvas.Left="-260" Canvas.Top="-300" Width="640" Height="640" Fill="{ThemeResource BubbleBrush}" Stroke="{ThemeResource BubbleRimBrush}" StrokeThickness="1" Opacity="0' +
    '.55" />' + sLineBreak +
    '          <Ellipse x:Name="Orb2" Canvas.Left="1180" Canvas.Top="560" Width="720" Height="720" Fill="{ThemeResource BubbleBrush}" Stroke="{ThemeResource BubbleRimBrush}" StrokeThickness="1" Opacity="0.' +
    '45" />' + sLineBreak +
    '          <Canvas x:Name="Ribbon1">' + sLineBreak +
    '            <Path Data="M -300,840 C 160,540 560,1000 920,660 S 1480,150 1960,400" Stroke="{ThemeResource RibbonBrush}" StrokeThickness="200" />' + sLineBreak +
    '            <Path Data="M -300,740 C 160,440 560,900 920,560 S 1480,50 1960,300" Stroke="{ThemeResource RibbonRimBrush}" StrokeThickness="1.4" Opacity="0.8" />' + sLineBreak +
    '            <Path Data="M -300,940 C 160,640 560,1100 920,760 S 1480,250 1960,500" Stroke="{ThemeResource RibbonRimBrush}" StrokeThickness="1" Opacity="0.35" />' + sLineBreak +
    '          </Canvas>' + sLineBreak +
    '          <Canvas x:Name="Ribbon2">' + sLineBreak +
    '            <Path Data="M -260,170 C 260,20 640,430 1080,250 S 1620,-60 1940,110" Stroke="{ThemeResource RibbonBrush}" StrokeThickness="130" />' + sLineBreak +
    '            <Path Data="M -260,105 C 260,-45 640,365 1080,185 S 1620,-125 1940,45" Stroke="{ThemeResource RibbonRimBrush}" StrokeThickness="1.2" Opacity="0.7" />' + sLineBreak +
    '          </Canvas>' + sLineBreak +
    '          <Canvas x:Name="Ribbon3">' + sLineBreak +
    '            <Path Data="M 380,1180 C 680,900 1000,1120 1300,860 S 1700,620 1940,690" Stroke="{ThemeResource RibbonBrush}" StrokeThickness="110" />' + sLineBreak +
    '            <Path Data="M 380,1125 C 680,845 1000,1065 1300,805 S 1700,565 1940,635" Stroke="{ThemeResource RibbonRimBrush}" StrokeThickness="1.2" Opacity="0.7" />' + sLineBreak +
    '          </Canvas>' + sLineBreak +
    '          <Ellipse x:Name="Bubble1" Canvas.Left="210" Canvas.Top="610" Width="86" Height="86" Fill="{ThemeResource BubbleBrush}" Stroke="{ThemeResource BubbleRimBrush}" StrokeThickness="1" />' + sLineBreak +
    '          <Ellipse x:Name="Bubble2" Canvas.Left="520" Canvas.Top="180" Width="34" Height="34" Fill="{ThemeResource BubbleBrush}" Stroke="{ThemeResource BubbleRimBrush}" StrokeThickness="1" />' + sLineBreak +
    '          <Ellipse x:Name="Bubble3" Canvas.Left="880" Canvas.Top="760" Width="58" Height="58" Fill="{ThemeResource BubbleBrush}" Stroke="{ThemeResource BubbleRimBrush}" StrokeThickness="1" />' + sLineBreak +
    '          <Ellipse x:Name="Bubble4" Canvas.Left="1240" Canvas.Top="260" Width="120" Height="120" Fill="{ThemeResource BubbleBrush}" Stroke="{ThemeResource BubbleRimBrush}" StrokeThickness="1" />' + sLineBreak +
    '          <Ellipse x:Name="Bubble5" Canvas.Left="1460" Canvas.Top="120" Width="22" Height="22" Fill="{ThemeResource BubbleBrush}" Stroke="{ThemeResource BubbleRimBrush}" StrokeThickness="1" />' + sLineBreak +
    '          <Ellipse x:Name="Bubble6" Canvas.Left="660" Canvas.Top="470" Width="16" Height="16" Fill="{ThemeResource BubbleBrush}" Stroke="{ThemeResource BubbleRimBrush}" StrokeThickness="1" />' + sLineBreak +
    '          <Ellipse x:Name="Bubble7" Canvas.Left="1080" Canvas.Top="900" Width="40" Height="40" Fill="{ThemeResource BubbleBrush}" Stroke="{ThemeResource BubbleRimBrush}" StrokeThickness="1" />' + sLineBreak +
    '          <Ellipse x:Name="Bubble8" Canvas.Left="90" Canvas.Top="300" Width="26" Height="26" Fill="{ThemeResource BubbleBrush}" Stroke="{ThemeResource BubbleRimBrush}" StrokeThickness="1" />' + sLineBreak +
    '          <Ellipse x:Name="Bubble9" Canvas.Left="1520" Canvas.Top="560" Width="64" Height="64" Fill="{ThemeResource BubbleBrush}" Stroke="{ThemeResource BubbleRimBrush}" StrokeThickness="1" />' + sLineBreak +
    '          <Ellipse x:Name="Bubble10" Canvas.Left="380" Canvas.Top="900" Width="20" Height="20" Fill="{ThemeResource BubbleBrush}" Stroke="{ThemeResource BubbleRimBrush}" StrokeThickness="1" />' + sLineBreak +
    '          <Ellipse x:Name="Bubble11" Canvas.Left="960" Canvas.Top="90" Width="48" Height="48" Fill="{ThemeResource BubbleBrush}" Stroke="{ThemeResource BubbleRimBrush}" StrokeThickness="1" />' + sLineBreak +
    '          <Ellipse x:Name="Bubble12" Canvas.Left="740" Canvas.Top="620" Width="12" Height="12" Fill="{ThemeResource BubbleBrush}" Stroke="{ThemeResource BubbleRimBrush}" StrokeThickness="1" />' + sLineBreak +
    '        </Canvas>' + sLineBreak +
    '      </Viewbox>' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '' + sLineBreak +
    '    <Grid x:Name="DragRegion" Grid.ColumnSpan="2" Background="Transparent" />' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Grid Grid.ColumnSpan="2" Margin="24,14,150,4" ColumnSpacing="16">' + sLineBreak +
    '      <Grid.ColumnDefinitions>' + sLineBreak +
    '        <ColumnDefinition Width="*" />' + sLineBreak +
    '        <ColumnDefinition Width="Auto" />' + sLineBreak +
    '        <ColumnDefinition Width="*" />' + sLineBreak +
    '      </Grid.ColumnDefinitions>' + sLineBreak +
    '      <Border Style="{StaticResource GlassPill}" Padding="6,6,18,6" HorizontalAlignment="Left" VerticalAlignment="Center">' + sLineBreak +
    '        <StackPanel Orientation="Horizontal" Spacing="10">' + sLineBreak +
    '          <Grid Width="34" Height="34">' + sLineBreak +
    '            <Ellipse Fill="{ThemeResource AccentFillColorDefaultBrush}" />' + sLineBreak +
    '            <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" Foreground="{ThemeResource TextOnAccentFillColorPrimaryBrush}" />' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <TextBlock Text="lucent" FontSize="18" FontWeight="SemiBold" FontFamily="Segoe UI Variable Display" VerticalAlignment="Center" />' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </Border>' + sLineBreak +
    '      <Border Grid.Column="1" Style="{StaticResource GlassPill}" Padding="5" VerticalAlignment="Center">' + sLineBreak +
    '        <Grid>' + sLineBreak +
    '          <Border x:Name="NavIndicator" Width="98" Height="40" CornerRadius="20" HorizontalAlignment="Left" Background="{ThemeResource SelectedPillBrush}" BorderBrush="{ThemeResource GlassRimBrush}" B' +
    'orderThickness="1" />' + sLineBreak +
    '          <StackPanel x:Name="NavBar" Orientation="Horizontal">' + sLineBreak +
    '            <Button x:Name="NavOverview" Style="{StaticResource NavTab}" Content="Overview" Tag="0" />' + sLineBreak +
    '            <Button x:Name="NavApps" Style="{StaticResource NavTab}" Content="Apps" Tag="1" />' + sLineBreak +
    '            <Button x:Name="NavReleases" Style="{StaticResource NavTab}" Content="Releases" Tag="2" />' + sLineBreak +
    '            <Button x:Name="NavReviews" Style="{StaticResource NavTab}" Content="Reviews" Tag="3" />' + sLineBreak +
    '            <Button x:Name="NavAudience" Style="{StaticResource NavTab}" Content="Audience" Tag="4" />' + sLineBreak +
    '            <Button x:Name="NavGrowth" Style="{StaticResource NavTab}" Content="Growth" Tag="5" />' + sLineBreak +
    '            <Button x:Name="NavPayouts" Style="{StaticResource NavTab}" Content="Payouts" Tag="6" />' + sLineBreak +
    '            <Button x:Name="NavTeam" Style="{StaticResource NavTab}" Content="Team" Tag="7" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '      </Border>' + sLineBreak +
    '      <Border Grid.Column="2" Style="{StaticResource GlassPill}" Padding="5" HorizontalAlignment="Right" VerticalAlignment="Center">' + sLineBreak +
    '        <StackPanel Orientation="Horizontal" Spacing="4">' + sLineBreak +
    '          <Button x:Name="InboxButton" Style="{StaticResource Round}" ToolTipService.ToolTip="Inbox" AutomationProperties.Name="Inbox">' + sLineBreak +
    '            <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="15" />' + sLineBreak +
    '            <Button.Flyout>' + sLineBreak +
    '              <Flyout Placement="BottomEdgeAlignedRight">' + sLineBreak +
    '                <StackPanel Width="320" Spacing="10">' + sLineBreak +
    '                  <TextBlock Text="Inbox" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                  <TextBlock Text="Reviews waiting for a reply" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <ItemsControl x:Name="InboxList">' + sLineBreak +
    '                    <ItemsControl.ItemTemplate>' + sLineBreak +
    '                      <DataTemplate>' + sLineBreak +
    '                        <Grid Padding="0,8" ColumnSpacing="10">' + sLineBreak +
    '                          <Grid.ColumnDefinitions>' + sLineBreak +
    '                            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                            <ColumnDefinition Width="*" />' + sLineBreak +
    '                          </Grid.ColumnDefinitions>' + sLineBreak +
    '                          <Border Width="30" Height="30" CornerRadius="9" Background="{Binding Tint}">' + sLineBreak +
    '                            <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="{Binding Glyph}" FontSize="13" Foreground="White" />' + sLineBreak +
    '                          </Border>' + sLineBreak +
    '                          <StackPanel Grid.Column="1">' + sLineBreak +
    '                            <TextBlock Text="{Binding Title}" FontSize="13" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" />' + sLineBreak +
    '                            <TextBlock Text="{Binding Meta}" FontSize="11" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                          </StackPanel>' + sLineBreak +
    '                        </Grid>' + sLineBreak +
    '                      </DataTemplate>' + sLineBreak +
    '                    </ItemsControl.ItemTemplate>' + sLineBreak +
    '                  </ItemsControl>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Flyout>' + sLineBreak +
    '            </Button.Flyout>' + sLineBreak +
    '          </Button>' + sLineBreak +
    '          <Grid>' + sLineBreak +
    '            <Button x:Name="BellButton" Style="{StaticResource Round}" ToolTipService.ToolTip="Notifications" AutomationProperties.Name="Notifications">' + sLineBreak +
    '              <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="15" />' + sLineBreak +
    '              <Button.Flyout>' + sLineBreak +
    '                <Flyout Placement="BottomEdgeAlignedRight">' + sLineBreak +
    '                  <StackPanel Width="340" Spacing="10">' + sLineBreak +
    '                    <TextBlock Text="Notifications" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                    <ItemsControl x:Name="NoticeList">' + sLineBreak +
    '                      <ItemsControl.ItemTemplate>' + sLineBreak +
    '                        <DataTemplate>' + sLineBreak +
    '                          <Grid Padding="0,8" ColumnSpacing="12">' + sLineBreak +
    '                            <Grid.ColumnDefinitions>' + sLineBreak +
    '                              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                              <ColumnDefinition Width="*" />' + sLineBreak +
    '                            </Grid.ColumnDefinitions>' + sLineBreak +
    '                            <Border Width="32" Height="32" CornerRadius="16" Background="{ThemeResource InnerBrush}">' + sLineBreak +
    '                              <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="{Binding Glyph}" FontSize="13" />' + sLineBreak +
    '                            </Border>' + sLineBreak +
    '                            <StackPanel Grid.Column="1">' + sLineBreak +
    '                              <TextBlock Text="{Binding Title}" FontSize="13" FontWeight="SemiBold" />' + sLineBreak +
    '                              <TextBlock Text="{Binding Body}" FontSize="12" TextWrapping="Wrap" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                              <TextBlock Text="{Binding Time}" FontSize="11" Foreground="{ThemeResource FaintBrush}" />' + sLineBreak +
    '                            </StackPanel>' + sLineBreak +
    '                          </Grid>' + sLineBreak +
    '                        </DataTemplate>' + sLineBreak +
    '                      </ItemsControl.ItemTemplate>' + sLineBreak +
    '                    </ItemsControl>' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </Flyout>' + sLineBreak +
    '              </Button.Flyout>' + sLineBreak +
    '            </Button>' + sLineBreak +
    '            <Ellipse x:Name="BellDot" Width="9" Height="9" Fill="{ThemeResource BadBrush}" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,8,9,0" IsHitTestVisible="False" Visibility="{Bi' +
    'nding HasNews, Converter={StaticResource BoolToVisibility}}" />' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <Button x:Name="AvatarButton" Width="42" Height="42" Padding="0" CornerRadius="21" BorderThickness="0" Background="{ThemeResource AvatarBrush}" AutomationProperties.Name="Profile">' + sLineBreak +
    '            <TextBlock Text="AR" FontSize="13" FontWeight="SemiBold" Foreground="{ThemeResource AvatarTextBrush}" />' + sLineBreak +
    '            <Button.Flyout>' + sLineBreak +
    '              <MenuFlyout Placement="BottomEdgeAlignedRight">' + sLineBreak +
    '                <MenuFlyoutItem Text="Ari Rowe, studio owner" IsEnabled="False" />' + sLineBreak +
    '                <MenuFlyoutSeparator />' + sLineBreak +
    '                <MenuFlyoutItem x:Name="MenuTheme" Text="Switch light or dark">' + sLineBreak +
    '                  <MenuFlyoutItem.Icon>' + sLineBreak +
    '                    <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" />' + sLineBreak +
    '                  </MenuFlyoutItem.Icon>' + sLineBreak +
    '                </MenuFlyoutItem>' + sLineBreak +
    '                <MenuFlyoutItem x:Name="MenuTeam" Text="Manage team">' + sLineBreak +
    '                  <MenuFlyoutItem.Icon>' + sLineBreak +
    '                    <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" />' + sLineBreak +
    '                  </MenuFlyoutItem.Icon>' + sLineBreak +
    '                </MenuFlyoutItem>' + sLineBreak +
    '              </MenuFlyout>' + sLineBreak +
    '            </Button.Flyout>' + sLineBreak +
    '          </Button>' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </Border>' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Border Grid.Row="1" Style="{StaticResource GlassPill}" Width="58" Padding="7,10" Margin="24,0,0,0" HorizontalAlignment="Left" VerticalAlignment="Center" CornerRadius="29">' + sLineBreak +
    '      <StackPanel Spacing="8">' + sLineBreak +
    '        <Button x:Name="RailSearch" Style="{StaticResource Round}" ToolTipService.ToolTip="Search apps" AutomationProperties.Name="Search apps">' + sLineBreak +
    '          <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="15" />' + sLineBreak +
    '        </Button>' + sLineBreak +
    '        <Button x:Name="RailNew" Style="{StaticResource Round}" Background="{ThemeResource AccentFillColorDefaultBrush}" ToolTipService.ToolTip="New release" AutomationProperties.Name="New release">' + sLineBreak +
    '          <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="15" Foreground="{ThemeResource TextOnAccentFillColorPrimaryBrush}" />' + sLineBreak +
    '        </Button>' + sLineBreak +
    '        <Button x:Name="RailCalendar" Style="{StaticResource Round}" ToolTipService.ToolTip="Release calendar" AutomationProperties.Name="Release calendar">' + sLineBreak +
    '          <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="15" />' + sLineBreak +
    '          <Button.Flyout>' + sLineBreak +
    '            <Flyout Placement="RightEdgeAlignedTop">' + sLineBreak +
    '              <StackPanel Spacing="10">' + sLineBreak +
    '                <TextBlock Text="Release calendar" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                <CalendarView x:Name="ReleaseCalendar" SelectionMode="Single" />' + sLineBreak +
    '                <TextBlock Text="Next store review window: Thursday" Style="{StaticResource Caption}" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Flyout>' + sLineBreak +
    '          </Button.Flyout>' + sLineBreak +
    '        </Button>' + sLineBreak +
    '        <Button x:Name="RailUndo" Style="{StaticResource Round}" ToolTipService.ToolTip="Undo the last move" AutomationProperties.Name="Undo">' + sLineBreak +
    '          <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="15" />' + sLineBreak +
    '        </Button>' + sLineBreak +
    '        <Button x:Name="RailShare" Style="{StaticResource Round}" ToolTipService.ToolTip="Copy a studio summary" AutomationProperties.Name="Share">' + sLineBreak +
    '          <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="15" />' + sLineBreak +
    '        </Button>' + sLineBreak +
    '        <Button x:Name="RailUpload" Style="{StaticResource Round}" ToolTipService.ToolTip="Upload a build" AutomationProperties.Name="Upload a build">' + sLineBreak +
    '          <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="15" />' + sLineBreak +
    '        </Button>' + sLineBreak +
    '        <Rectangle Height="1" Margin="6,4" Fill="{ThemeResource LineBrush}" />' + sLineBreak +
    '        <Button x:Name="RailSettings" Style="{StaticResource Round}" ToolTipService.ToolTip="Settings" AutomationProperties.Name="Settings">' + sLineBreak +
    '          <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="15" />' + sLineBreak +
    '          <Button.Flyout>' + sLineBreak +
    '            <Flyout Placement="RightEdgeAlignedBottom">' + sLineBreak +
    '              <StackPanel Width="260" Spacing="6">' + sLineBreak +
    '                <TextBlock Text="Studio settings" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                <ToggleSwitch x:Name="LiveSwitch" Header="Live data" IsOn="{Binding Live, Mode=TwoWay}" />' + sLineBreak +
    '                <ToggleSwitch x:Name="MotionSwitch" Header="Animations" IsOn="{Binding Motion, Mode=TwoWay}" />' + sLineBreak +
    '                <ToggleSwitch x:Name="TransparencySwitch" Header="Transparency" IsOn="True" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Flyout>' + sLineBreak +
    '          </Button.Flyout>' + sLineBreak +
    '        </Button>' + sLineBreak +
    '        <Button x:Name="RailTheme" Style="{StaticResource Round}" ToolTipService.ToolTip="Light or dark" AutomationProperties.Name="Switch theme">' + sLineBreak +
    '          <FontIcon x:Name="ThemeGlyph" FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="15" />' + sLineBreak +
    '        </Button>' + sLineBreak +
    '      </StackPanel>' + sLineBreak +
    '    </Border>' + sLineBreak +
    '    <Button x:Name="LiveButton" Grid.Row="1" Width="48" Height="48" CornerRadius="24" Padding="0" Margin="29,0,0,22" HorizontalAlignment="Left" VerticalAlignment="Bottom" Background="{ThemeResource Gl' +
    'assBrush}" BorderBrush="{ThemeResource GlassRimBrush}" ToolTipService.ToolTip="Pause or resume live data" AutomationProperties.Name="Live data">' + sLineBreak +
    '      <Grid>' + sLineBreak +
    '        <Ellipse x:Name="LivePulse" Width="12" Height="12" Fill="{ThemeResource GoodBrush}" Visibility="{Binding Live, Converter={StaticResource BoolToVisibility}}" />' + sLineBreak +
    '        <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="13" Visibility="{Binding Live, Converter={StaticResource InverseBoolToVisibility}}" />' + sLineBreak +
    '      </Grid>' + sLineBreak +
    '    </Button>' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Grid x:Name="PageHost" Grid.Row="1" Grid.Column="1">' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <ScrollViewer x:Name="PageOverview" VerticalScrollBarVisibility="Auto" Padding="10,6,30,26">' + sLineBreak +
    '        <StackPanel Spacing="20">' + sLineBreak +
    '          <Grid ColumnSpacing="24">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <StackPanel x:Name="OvTitle" VerticalAlignment="Bottom">' + sLineBreak +
    '              <TextBlock Text="Studio" Style="{StaticResource PageFirst}" />' + sLineBreak +
    '              <TextBlock Text="Overview" Style="{StaticResource PageSecond}" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '            <StackPanel x:Name="OvKpis" Grid.Column="1" Orientation="Horizontal" Spacing="12" VerticalAlignment="Bottom">' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                      <TextBlock x:Name="OvProceedsLabel" Text="{Binding ProceedsMonthText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                      <Border CornerRadius="10" Padding="7,2" Background="{ThemeResource GoodSoftBrush}" VerticalAlignment="Center">' + sLineBreak +
    '                        <TextBlock Text="{Binding ProceedsDeltaText}" FontSize="11" Foreground="{ThemeResource GoodBrush}" />' + sLineBreak +
    '                      </Border>' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                    <TextBlock Text="proceeds this month" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                      <TextBlock Text="{Binding Downloads7Text}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                      <Border CornerRadius="10" Padding="7,2" Background="{ThemeResource BadSoftBrush}" VerticalAlignment="Center">' + sLineBreak +
    '                        <TextBlock Text="-4%" FontSize="11" Foreground="{ThemeResource BadBrush}" />' + sLineBreak +
    '                      </Border>' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                    <TextBlock Text="downloads, last 7 days" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" Foreground="{ThemeResource StarBrush}" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding AppRatingText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="{Binding AppRatingCaption}" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '' + sLineBreak +
    '          <Grid ColumnSpacing="20">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition x:Name="ProceedsColumn" Width="2*" />' + sLineBreak +
    '              <ColumnDefinition x:Name="RatingsColumn" Width="*" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <Border x:Name="ProceedsCard" Style="{StaticResource Glass}" Height="420">' + sLineBreak +
    '              <Grid RowSpacing="14">' + sLineBreak +
    '                <Grid.RowDefinitions>' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                  <RowDefinition Height="*" />' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                </Grid.RowDefinitions>' + sLineBreak +
    '                <Grid ColumnSpacing="10">' + sLineBreak +
    '                  <Grid.ColumnDefinitions>' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                    <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                    <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                  </Grid.ColumnDefinitions>' + sLineBreak +
    '                  <StackPanel>' + sLineBreak +
    '                    <TextBlock x:Name="ChartTitle" Text="{Binding ChartTitle}" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                    <TextBlock Text="{Binding ChartCaption}" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <Border Grid.Column="1" CornerRadius="20" Padding="3" Background="{ThemeResource InnerBrush}" BorderBrush="{ThemeResource InnerRimBrush}" BorderThickness="1" VerticalAlignment="Cente' +
    'r">' + sLineBreak +
    '                    <StackPanel Orientation="Horizontal" Spacing="2">' + sLineBreak +
    '                      <ToggleButton x:Name="SeriesProceeds" Content="Proceeds" Style="{StaticResource Chip}" IsChecked="True" BorderThickness="0" />' + sLineBreak +
    '                      <ToggleButton x:Name="SeriesDownloads" Content="Downloads" Style="{StaticResource Chip}" BorderThickness="0" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                  </Border>' + sLineBreak +
    '                  <Button Grid.Column="2" Style="{StaticResource RoundInner}" VerticalAlignment="Center" AutomationProperties.Name="More">' + sLineBreak +
    '                    <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="13" />' + sLineBreak +
    '                    <Button.Flyout>' + sLineBreak +
    '                      <MenuFlyout>' + sLineBreak +
    '                        <MenuFlyoutItem x:Name="MenuExportChart" Text="Export as CSV" />' + sLineBreak +
    '                        <ToggleMenuFlyoutItem x:Name="MenuLastYear" Text="Show last year" IsChecked="True" />' + sLineBreak +
    '                      </MenuFlyout>' + sLineBreak +
    '                    </Button.Flyout>' + sLineBreak +
    '                  </Button>' + sLineBreak +
    '                  <Button x:Name="ExpandButton" Grid.Column="3" Style="{StaticResource RoundInner}" VerticalAlignment="Center" ToolTipService.ToolTip="Expand" AutomationProperties.Name="Expand chart">' + sLineBreak +
    '                    <FontIcon x:Name="ExpandGlyph" FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="12" />' + sLineBreak +
    '                  </Button>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <Grid Grid.Row="1" ColumnSpacing="10">' + sLineBreak +
    '                  <Grid.ColumnDefinitions>' + sLineBreak +
    '                    <ColumnDefinition Width="46" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                  </Grid.ColumnDefinitions>' + sLineBreak +
    '                  <Grid>' + sLineBreak +
    '                    <TextBlock Text="{Binding ChartTop}" Style="{StaticResource Caption}" VerticalAlignment="Top" Margin="0,-8,0,0" />' + sLineBreak +
    '                    <TextBlock Text="{Binding ChartMid}" Style="{StaticResource Caption}" VerticalAlignment="Center" />' + sLineBreak +
    '                    <TextBlock Text="0" Style="{StaticResource Caption}" VerticalAlignment="Bottom" Margin="0,0,0,-8" />' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                  <Grid Grid.Column="1">' + sLineBreak +
    '                    <Rectangle Height="1" VerticalAlignment="Top" Fill="{ThemeResource LineBrush}" />' + sLineBreak +
    '                    <Rectangle Height="1" VerticalAlignment="Center" Fill="{ThemeResource LineBrush}" />' + sLineBreak +
    '                    <Rectangle Height="1" VerticalAlignment="Bottom" Fill="{ThemeResource LineBrush}" />' + sLineBreak +
    '                    <Canvas x:Name="ProceedsCanvas">' + sLineBreak +
    '                      <Polygon x:Name="ProceedsArea" Opacity="0.9">' + sLineBreak +
    '                        <Polygon.Fill>' + sLineBreak +
    '                          <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">' + sLineBreak +
    '                            <GradientStop Color="{ThemeResource SystemAccentColorLight1}" Offset="0" />' + sLineBreak +
    '                            <GradientStop Color="Transparent" Offset="1" />' + sLineBreak +
    '                          </LinearGradientBrush>' + sLineBreak +
    '                        </Polygon.Fill>' + sLineBreak +
    '                      </Polygon>' + sLineBreak +
    '                      <Polyline x:Name="ProceedsLastYear" Stroke="{ThemeResource FaintBrush}" StrokeThickness="1.6" StrokeDashArray="3,3" />' + sLineBreak +
    '                      <Polyline x:Name="ProceedsLine" Stroke="{ThemeResource AccentFillColorDefaultBrush}" StrokeThickness="2.6" StrokeLineJoin="Round" />' + sLineBreak +
    '                      <Ellipse x:Name="ProceedsGlow" Width="22" Height="22" Fill="{ThemeResource AccentFillColorDefaultBrush}" Opacity="0.3" />' + sLineBreak +
    '                      <Ellipse x:Name="ProceedsDot" Width="10" Height="10" Fill="{ThemeResource AccentFillColorDefaultBrush}" Stroke="White" StrokeThickness="2" />' + sLineBreak +
    '                    </Canvas>' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <Grid Grid.Row="2" Margin="56,0,0,0">' + sLineBreak +
    '                  <Grid.ColumnDefinitions>' + sLineBreak +
    '                    <ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition />' + sLineBreak +
    '                    <ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition />' + sLineBreak +
    '                  </Grid.ColumnDefinitions>' + sLineBreak +
    '                  <TextBlock Grid.Column="0" Text="Nov" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="1" Text="Dec" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="2" Text="Jan" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="3" Text="Feb" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="4" Text="Mar" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="5" Text="Apr" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="6" Text="May" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="7" Text="Jun" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="8" Text="Jul" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="9" Text="Aug" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="10" Text="Sep" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="11" Text="Oct" Style="{StaticResource Caption}" />' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <Border x:Name="RatingsCard" Grid.Column="1" Style="{StaticResource Glass}" Height="420">' + sLineBreak +
    '              <Grid RowSpacing="12">' + sLineBreak +
    '                <Grid.RowDefinitions>' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                  <RowDefinition Height="*" />' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                </Grid.RowDefinitions>' + sLineBreak +
    '                <TextBlock Text="Ratings" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                <StackPanel Grid.Row="1" Spacing="2">' + sLineBreak +
    '                  <StackPanel Orientation="Horizontal" Spacing="14">' + sLineBreak +
    '                    <TextBlock Text="{Binding RatingText}" FontSize="52" FontWeight="SemiBold" FontFamily="Segoe UI Variable Display" />' + sLineBreak +
    '                    <TextBlock Text="★★★★★" FontSize="20" VerticalAlignment="Center" Foreground="{ThemeResource StarBrush}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <TextBlock Text="{Binding RatingCountCaption}" Style="{StaticResource Caption}" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <ItemsControl x:Name="StarBarList" Grid.Row="2" VerticalAlignment="Center">' + sLineBreak +
    '                  <ItemsControl.ItemTemplate>' + sLineBreak +
    '                    <DataTemplate>' + sLineBreak +
    '                      <Grid ColumnSpacing="10" Margin="0,4">' + sLineBreak +
    '                        <Grid.ColumnDefinitions>' + sLineBreak +
    '                          <ColumnDefinition Width="28" />' + sLineBreak +
    '                          <ColumnDefinition Width="*" />' + sLineBreak +
    '                          <ColumnDefinition Width="40" />' + sLineBreak +
    '                        </Grid.ColumnDefinitions>' + sLineBreak +
    '                        <TextBlock Text="{Binding Name}" FontSize="12" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                        <Border Grid.Column="1" Height="8" CornerRadius="4" Background="{ThemeResource InnerBrush}">' + sLineBreak +
    '                          <Border Height="8" CornerRadius="4" HorizontalAlignment="Left" Width="{Binding Size}" Background="{ThemeResource AccentFillColorDefaultBrush}" />' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                        <TextBlock Grid.Column="2" Text="{Binding ValueText}" FontSize="12" HorizontalAlignment="Right" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                      </Grid>' + sLineBreak +
    '                    </DataTemplate>' + sLineBreak +
    '                  </ItemsControl.ItemTemplate>' + sLineBreak +
    '                </ItemsControl>' + sLineBreak +
    '                <Border Grid.Row="3" Style="{StaticResource Inner}">' + sLineBreak +
    '                  <Grid>' + sLineBreak +
    '                    <StackPanel>' + sLineBreak +
    '                      <TextBlock Text="Last 30 days" Style="{StaticResource Caption}" />' + sLineBreak +
    '                      <TextBlock Text="{Binding RecentRatingText}" FontSize="14" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                    <Border HorizontalAlignment="Right" VerticalAlignment="Center" CornerRadius="10" Padding="8,3" Background="{ThemeResource BadSoftBrush}">' + sLineBreak +
    '                      <TextBlock Text="▼ 0.10" FontSize="11" Foreground="{ThemeResource BadBrush}" />' + sLineBreak +
    '                    </Border>' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                </Border>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '' + sLineBreak +
    '          <Border x:Name="YourAppsCard" Style="{StaticResource Glass}">' + sLineBreak +
    '            <Grid RowSpacing="16">' + sLineBreak +
    '              <Grid.RowDefinitions>' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '              </Grid.RowDefinitions>' + sLineBreak +
    '              <Grid ColumnSpacing="10">' + sLineBreak +
    '                <Grid.ColumnDefinitions>' + sLineBreak +
    '                  <ColumnDefinition Width="*" />' + sLineBreak +
    '                  <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                  <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                </Grid.ColumnDefinitions>' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <TextBlock Text="Your apps" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                  <TextBlock Text="October, month to date" Style="{StaticResource Caption}" VerticalAlignment="Center" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <Button Grid.Column="1" Style="{StaticResource RoundInner}" ToolTipService.ToolTip="New release" AutomationProperties.Name="New release" x:Name="_rw1">' + sLineBreak +
    '                  <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="12" />' + sLineBreak +
    '                </Button>' + sLineBreak +
    '                <Button x:Name="AllAppsButton" Grid.Column="2" Style="{StaticResource RoundInner}" ToolTipService.ToolTip="All apps" AutomationProperties.Name="All apps">' + sLineBreak +
    '                  <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="12" />' + sLineBreak +
    '                </Button>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <GridView x:Name="OverviewApps" Grid.Row="1" SelectionMode="None" IsItemClickEnabled="True" ItemContainerStyle="{StaticResource BareGrid}" ScrollViewer.HorizontalScrollMode="Disabled">' + sLineBreak +
    '                <GridView.ItemContainerTransitions>' + sLineBreak +
    '                  <TransitionCollection>' + sLineBreak +
    '                    <EntranceThemeTransition IsStaggeringEnabled="True" FromVerticalOffset="40" />' + sLineBreak +
    '                    <RepositionThemeTransition />' + sLineBreak +
    '                  </TransitionCollection>' + sLineBreak +
    '                </GridView.ItemContainerTransitions>' + sLineBreak +
    '                <GridView.ItemTemplate>' + sLineBreak +
    '                  <DataTemplate>' + sLineBreak +
    '                    <Grid Width="206" Height="132">' + sLineBreak +
    '                      <Border CornerRadius="22" Background="{Binding Tint}" />' + sLineBreak +
    '                      <Border CornerRadius="22" BorderBrush="#40FFFFFF" BorderThickness="1">' + sLineBreak +
    '                        <Border.Background>' + sLineBreak +
    '                          <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">' + sLineBreak +
    '                            <GradientStop Color="#40FFFFFF" Offset="0" />' + sLineBreak +
    '                            <GradientStop Color="#00FFFFFF" Offset="0.5" />' + sLineBreak +
    '                            <GradientStop Color="#33000000" Offset="1" />' + sLineBreak +
    '                          </LinearGradientBrush>' + sLineBreak +
    '                        </Border.Background>' + sLineBreak +
    '                      </Border>' + sLineBreak +
    '                      <Grid Padding="16,14">' + sLineBreak +
    '                        <Grid.RowDefinitions>' + sLineBreak +
    '                          <RowDefinition Height="Auto" />' + sLineBreak +
    '                          <RowDefinition Height="*" />' + sLineBreak +
    '                          <RowDefinition Height="Auto" />' + sLineBreak +
    '                        </Grid.RowDefinitions>' + sLineBreak +
    '                        <Border Width="36" Height="36" CornerRadius="11" Background="#33FFFFFF" HorizontalAlignment="Left">' + sLineBreak +
    '                          <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="{Binding Glyph}" FontSize="16" Foreground="White" />' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                        <Border CornerRadius="10" Padding="7,2" Background="#33000000" HorizontalAlignment="Right" VerticalAlignment="Top">' + sLineBreak +
    '                          <TextBlock Text="{Binding RatingChip}" FontSize="11" Foreground="White" />' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                        <StackPanel Grid.Row="2">' + sLineBreak +
    '                          <TextBlock Text="{Binding Name}" FontSize="15" FontWeight="SemiBold" Foreground="White" />' + sLineBreak +
    '                          <TextBlock Text="{Binding ProceedsText}" FontSize="12" Foreground="#D9FFFFFF" />' + sLineBreak +
    '                        </StackPanel>' + sLineBreak +
    '                        <FontIcon Grid.Row="2" FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="13" Foreground="#CCFFFFFF" HorizontalAlignment="Right" VerticalAlignment="Bottom" ' +
    '/>' + sLineBreak +
    '                      </Grid>' + sLineBreak +
    '                    </Grid>' + sLineBreak +
    '                  </DataTemplate>' + sLineBreak +
    '                </GridView.ItemTemplate>' + sLineBreak +
    '              </GridView>' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </ScrollViewer>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <ScrollViewer x:Name="PageApps" VerticalScrollBarVisibility="Auto" Padding="10,6,30,26" Visibility="Collapsed">' + sLineBreak +
    '        <StackPanel Spacing="20">' + sLineBreak +
    '          <Grid ColumnSpacing="24">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <StackPanel x:Name="ApTitle" VerticalAlignment="Bottom">' + sLineBreak +
    '              <TextBlock Text="Your" Style="{StaticResource PageFirst}" />' + sLineBreak +
    '              <TextBlock Text="Apps" Style="{StaticResource PageSecond}" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '            <StackPanel x:Name="ApKpis" Grid.Column="1" Orientation="Horizontal" Spacing="12" VerticalAlignment="Bottom">' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding AppsLiveText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="apps live" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" Foreground="{ThemeResource StarBrush}" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding RatingCountText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="ratings" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding SubscribersText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="active subscribers" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <Grid x:Name="ApToolbar" ColumnSpacing="12">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <TextBox x:Name="AppSearch" Width="340" CornerRadius="20" Padding="16,9" PlaceholderText="Search apps or categories" Background="{ThemeResource GlassBrush}" BorderBrush="{ThemeResource Gla' +
    'ssRimBrush}" />' + sLineBreak +
    '            <StackPanel Grid.Column="2" Orientation="Horizontal" Spacing="6">' + sLineBreak +
    '              <TextBlock Text="Sort by" Style="{StaticResource Caption}" VerticalAlignment="Center" Margin="0,0,6,0" />' + sLineBreak +
    '              <ToggleButton x:Name="SortProceeds" Content="Proceeds" Style="{StaticResource Chip}" IsChecked="True" Tag="0" />' + sLineBreak +
    '              <ToggleButton x:Name="SortDownloads" Content="Downloads" Style="{StaticResource Chip}" Tag="1" />' + sLineBreak +
    '              <ToggleButton x:Name="SortRating" Content="Rating" Style="{StaticResource Chip}" Tag="2" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <GridView x:Name="AppGrid" SelectionMode="None" IsItemClickEnabled="True" ItemContainerStyle="{StaticResource BareGrid}">' + sLineBreak +
    '            <GridView.ItemContainerTransitions>' + sLineBreak +
    '              <TransitionCollection>' + sLineBreak +
    '                <EntranceThemeTransition IsStaggeringEnabled="True" FromVerticalOffset="60" />' + sLineBreak +
    '                <AddDeleteThemeTransition />' + sLineBreak +
    '                <RepositionThemeTransition />' + sLineBreak +
    '              </TransitionCollection>' + sLineBreak +
    '            </GridView.ItemContainerTransitions>' + sLineBreak +
    '            <GridView.ItemTemplate>' + sLineBreak +
    '              <DataTemplate>' + sLineBreak +
    '                <Border Width="356" Padding="20" CornerRadius="26" Background="{ThemeResource GlassBrush}" BorderBrush="{ThemeResource GlassRimBrush}" BorderThickness="1">' + sLineBreak +
    '                  <StackPanel Spacing="14">' + sLineBreak +
    '                    <Grid ColumnSpacing="12">' + sLineBreak +
    '                      <Grid.ColumnDefinitions>' + sLineBreak +
    '                        <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                        <ColumnDefinition Width="*" />' + sLineBreak +
    '                        <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                      </Grid.ColumnDefinitions>' + sLineBreak +
    '                      <Grid Width="52" Height="52">' + sLineBreak +
    '                        <Border CornerRadius="15" Background="{Binding Tint}" />' + sLineBreak +
    '                        <Border CornerRadius="15">' + sLineBreak +
    '                          <Border.Background>' + sLineBreak +
    '                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">' + sLineBreak +
    '                              <GradientStop Color="#4DFFFFFF" Offset="0" />' + sLineBreak +
    '                              <GradientStop Color="#00FFFFFF" Offset="0.6" />' + sLineBreak +
    '                            </LinearGradientBrush>' + sLineBreak +
    '                          </Border.Background>' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                        <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="{Binding Glyph}" FontSize="22" Foreground="White" />' + sLineBreak +
    '                      </Grid>' + sLineBreak +
    '                      <StackPanel Grid.Column="1" VerticalAlignment="Center">' + sLineBreak +
    '                        <TextBlock Text="{Binding Name}" FontSize="17" FontWeight="SemiBold" />' + sLineBreak +
    '                        <TextBlock Text="{Binding Tagline}" FontSize="12" Foreground="{ThemeResource MutedBrush}" TextTrimming="CharacterEllipsis" />' + sLineBreak +
    '                      </StackPanel>' + sLineBreak +
    '                      <Border Grid.Column="2" CornerRadius="10" Padding="8,3" VerticalAlignment="Top" Background="{ThemeResource InnerBrush}" BorderBrush="{ThemeResource InnerRimBrush}" BorderThicknes' +
    's="1">' + sLineBreak +
    '                        <TextBlock Text="{Binding VersionText}" FontSize="11" />' + sLineBreak +
    '                      </Border>' + sLineBreak +
    '                    </Grid>' + sLineBreak +
    '                    <StackPanel Orientation="Horizontal" Spacing="6">' + sLineBreak +
    '                      <Border CornerRadius="10" Padding="9,3" Background="{ThemeResource InnerBrush}"><TextBlock Text="{Binding Category}" FontSize="11" /></Border>' + sLineBreak +
    '                      <Border CornerRadius="10" Padding="9,3" Background="{ThemeResource InnerBrush}"><TextBlock Text="{Binding Pricing}" FontSize="11" /></Border>' + sLineBreak +
    '                      <Border CornerRadius="10" Padding="9,3" Background="{ThemeResource WarnSoftBrush}" Visibility="{Binding InReview, Converter={StaticResource BoolToVisibility}}">' + sLineBreak +
    '                        <TextBlock Text="In review" FontSize="11" Foreground="{ThemeResource WarnBrush}" />' + sLineBreak +
    '                      </Border>' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                    <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                      <TextBlock Text="{Binding StarsText}" FontSize="14" Foreground="{ThemeResource StarBrush}" />' + sLineBreak +
    '                      <TextBlock Text="{Binding RatingText}" FontSize="13" FontWeight="SemiBold" />' + sLineBreak +
    '                      <TextBlock Text="{Binding RatingCountText}" FontSize="12" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                    <Border CornerRadius="16" Padding="14,12" Background="{ThemeResource InnerBrush}" BorderBrush="{ThemeResource InnerRimBrush}" BorderThickness="1">' + sLineBreak +
    '                      <Grid ColumnSpacing="12">' + sLineBreak +
    '                        <Grid.ColumnDefinitions>' + sLineBreak +
    '                          <ColumnDefinition Width="*" />' + sLineBreak +
    '                          <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                        </Grid.ColumnDefinitions>' + sLineBreak +
    '                        <StackPanel>' + sLineBreak +
    '                          <TextBlock Text="Downloads, 30 days" FontSize="11" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                          <TextBlock Text="{Binding DownloadsText}" FontSize="24" FontWeight="SemiBold" FontFamily="Segoe UI Variable Display" />' + sLineBreak +
    '                          <TextBlock Text="{Binding DeltaText}" FontSize="11" Foreground="{ThemeResource BadBrush}" Visibility="{Binding Falling, Converter={StaticResource BoolToVisibility}}" />' + sLineBreak +
    '                          <TextBlock Text="{Binding DeltaText}" FontSize="11" Foreground="{ThemeResource GoodBrush}" Visibility="{Binding Falling, Converter={StaticResource InverseBoolToVisibility}}" ' +
    '/>' + sLineBreak +
    '                        </StackPanel>' + sLineBreak +
    '                        <StackPanel Grid.Column="1" Orientation="Horizontal" Spacing="5" VerticalAlignment="Bottom" Height="54">' + sLineBreak +
    '                          <Border Width="7" CornerRadius="3.5" VerticalAlignment="Bottom" Height="{Binding Spark1}" Background="{Binding Tint}" Opacity="0.55" />' + sLineBreak +
    '                          <Border Width="7" CornerRadius="3.5" VerticalAlignment="Bottom" Height="{Binding Spark2}" Background="{Binding Tint}" Opacity="0.6" />' + sLineBreak +
    '                          <Border Width="7" CornerRadius="3.5" VerticalAlignment="Bottom" Height="{Binding Spark3}" Background="{Binding Tint}" Opacity="0.65" />' + sLineBreak +
    '                          <Border Width="7" CornerRadius="3.5" VerticalAlignment="Bottom" Height="{Binding Spark4}" Background="{Binding Tint}" Opacity="0.7" />' + sLineBreak +
    '                          <Border Width="7" CornerRadius="3.5" VerticalAlignment="Bottom" Height="{Binding Spark5}" Background="{Binding Tint}" Opacity="0.8" />' + sLineBreak +
    '                          <Border Width="7" CornerRadius="3.5" VerticalAlignment="Bottom" Height="{Binding Spark6}" Background="{Binding Tint}" Opacity="0.9" />' + sLineBreak +
    '                          <Border Width="7" CornerRadius="3.5" VerticalAlignment="Bottom" Height="{Binding Spark7}" Background="{Binding Tint}" />' + sLineBreak +
    '                        </StackPanel>' + sLineBreak +
    '                      </Grid>' + sLineBreak +
    '                    </Border>' + sLineBreak +
    '                    <Grid>' + sLineBreak +
    '                      <StackPanel>' + sLineBreak +
    '                        <TextBlock Text="Proceeds in October" FontSize="11" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                        <TextBlock Text="{Binding ProceedsText}" FontSize="15" FontWeight="SemiBold" />' + sLineBreak +
    '                      </StackPanel>' + sLineBreak +
    '                      <StackPanel HorizontalAlignment="Right">' + sLineBreak +
    '                        <TextBlock Text="Crash-free" FontSize="11" Foreground="{ThemeResource MutedBrush}" HorizontalAlignment="Right" />' + sLineBreak +
    '                        <TextBlock Text="{Binding CrashFreeText}" FontSize="15" FontWeight="SemiBold" HorizontalAlignment="Right" />' + sLineBreak +
    '                      </StackPanel>' + sLineBreak +
    '                    </Grid>' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </Border>' + sLineBreak +
    '              </DataTemplate>' + sLineBreak +
    '            </GridView.ItemTemplate>' + sLineBreak +
    '          </GridView>' + sLineBreak +
    '          <TextBlock x:Name="NoAppsText" Text="No app matches your search." Style="{StaticResource Caption}" Visibility="Collapsed" />' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </ScrollViewer>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <ScrollViewer x:Name="PageDetail" DataContext="{Binding Detail}" VerticalScrollBarVisibility="Auto" Padding="10,6,30,26" Visibility="Collapsed">' + sLineBreak +
    '        <StackPanel Spacing="20">' + sLineBreak +
    '          <Grid ColumnSpacing="24">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <Button x:Name="BackButton" Width="52" Height="52" CornerRadius="26" Padding="0" VerticalAlignment="Bottom" Margin="0,0,0,6" Background="{ThemeResource GlassBrush}" BorderBrush="{ThemeReso' +
    'urce GlassRimBrush}" AutomationProperties.Name="Back to apps">' + sLineBreak +
    '              <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" />' + sLineBreak +
    '            </Button>' + sLineBreak +
    '            <StackPanel x:Name="DeTitle" Grid.Column="1" VerticalAlignment="Bottom">' + sLineBreak +
    '              <TextBlock x:Name="DetailNameLabel" Text="{Binding Name}" Style="{StaticResource PageFirst}" />' + sLineBreak +
    '              <TextBlock Text="App" Style="{StaticResource PageSecond}" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '            <StackPanel x:Name="DeKpis" Grid.Column="2" Orientation="Horizontal" Spacing="12" VerticalAlignment="Bottom">' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding DownloadsText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="downloads, 30 days" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" Foreground="{ThemeResource StarBrush}" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding RatingText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="{Binding RatingCountText}" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding CrashFreeText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="crash-free sessions" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <Grid x:Name="DetailHero" Height="230">' + sLineBreak +
    '            <Border CornerRadius="30" Background="{Binding Tint}" Opacity="0.85" />' + sLineBreak +
    '            <Border CornerRadius="30" BorderBrush="#4DFFFFFF" BorderThickness="1">' + sLineBreak +
    '              <Border.Background>' + sLineBreak +
    '                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">' + sLineBreak +
    '                  <GradientStop Color="#33FFFFFF" Offset="0" />' + sLineBreak +
    '                  <GradientStop Color="#0DFFFFFF" Offset="0.5" />' + sLineBreak +
    '                  <GradientStop Color="#66000000" Offset="1" />' + sLineBreak +
    '                </LinearGradientBrush>' + sLineBreak +
    '              </Border.Background>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <Ellipse Width="320" Height="320" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,-120,-60,0" Fill="#1AFFFFFF" Stroke="#33FFFFFF" />' + sLineBreak +
    '            <Grid Padding="30,26" ColumnSpacing="26">' + sLineBreak +
    '              <Grid.ColumnDefinitions>' + sLineBreak +
    '                <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                <ColumnDefinition Width="*" />' + sLineBreak +
    '                <ColumnDefinition Width="Auto" />' + sLineBreak +
    '              </Grid.ColumnDefinitions>' + sLineBreak +
    '              <Border Width="104" Height="104" CornerRadius="28" Background="#33FFFFFF" BorderBrush="#59FFFFFF" BorderThickness="1" VerticalAlignment="Center">' + sLineBreak +
    '                <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="{Binding Glyph}" FontSize="44" Foreground="White" />' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <StackPanel Grid.Column="1" VerticalAlignment="Center" Spacing="6">' + sLineBreak +
    '                <TextBlock Text="{Binding Name}" FontSize="34" FontWeight="SemiBold" FontFamily="Segoe UI Variable Display" Foreground="White" />' + sLineBreak +
    '                <TextBlock Text="{Binding Tagline}" FontSize="15" Foreground="#E6FFFFFF" />' + sLineBreak +
    '                <TextBlock Text="{Binding Steward}" FontSize="12" Foreground="#B3FFFFFF" />' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="6" Margin="0,6,0,0">' + sLineBreak +
    '                  <Border CornerRadius="11" Padding="10,3" Background="#33FFFFFF"><TextBlock Text="{Binding Category}" FontSize="11" Foreground="White" /></Border>' + sLineBreak +
    '                  <Border CornerRadius="11" Padding="10,3" Background="#33FFFFFF"><TextBlock Text="{Binding Pricing}" FontSize="11" Foreground="White" /></Border>' + sLineBreak +
    '                  <Border CornerRadius="11" Padding="10,3" Background="#33FFFFFF"><TextBlock Text="{Binding RatingChip}" FontSize="11" Foreground="White" /></Border>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <StackPanel Grid.Column="2" VerticalAlignment="Center" Width="300">' + sLineBreak +
    '                <TextBlock Text="Proceeds, 12 months" FontSize="12" Foreground="#CCFFFFFF" />' + sLineBreak +
    '                <TextBlock Text="{Binding Proceeds12Text}" FontSize="34" FontWeight="SemiBold" FontFamily="Segoe UI Variable Display" Foreground="White" />' + sLineBreak +
    '                <Canvas x:Name="DetailSparkCanvas" Height="64" Margin="0,8,0,0">' + sLineBreak +
    '                  <Polyline x:Name="DetailSpark" Stroke="White" StrokeThickness="2.4" StrokeLineJoin="Round" />' + sLineBreak +
    '                </Canvas>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <StackPanel x:Name="DetailTabs" Orientation="Horizontal" Spacing="6">' + sLineBreak +
    '            <ToggleButton x:Name="DetailTabOverview" Content="Overview" Style="{StaticResource Chip}" IsChecked="True" Tag="0" />' + sLineBreak +
    '            <ToggleButton x:Name="DetailTabVersions" Content="Versions" Style="{StaticResource Chip}" Tag="1" />' + sLineBreak +
    '            <ToggleButton x:Name="DetailTabIap" Content="In-app purchases" Style="{StaticResource Chip}" Tag="2" />' + sLineBreak +
    '            <ToggleButton x:Name="DetailTabReviews" Content="Reviews" Style="{StaticResource Chip}" Tag="3" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '          <Grid x:Name="DetailBody">' + sLineBreak +
    '            <Grid x:Name="DetailOverview" ColumnSpacing="20">' + sLineBreak +
    '              <Grid.ColumnDefinitions>' + sLineBreak +
    '                <ColumnDefinition Width="2*" />' + sLineBreak +
    '                <ColumnDefinition Width="*" />' + sLineBreak +
    '              </Grid.ColumnDefinitions>' + sLineBreak +
    '              <Border Style="{StaticResource Glass}" Height="330">' + sLineBreak +
    '                <Grid RowSpacing="12">' + sLineBreak +
    '                  <Grid.RowDefinitions>' + sLineBreak +
    '                    <RowDefinition Height="Auto" />' + sLineBreak +
    '                    <RowDefinition Height="*" />' + sLineBreak +
    '                  </Grid.RowDefinitions>' + sLineBreak +
    '                  <StackPanel>' + sLineBreak +
    '                    <TextBlock Text="Proceeds" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                    <TextBlock Text="{Binding ProceedsCaption}" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <Grid Grid.Row="1">' + sLineBreak +
    '                    <Rectangle Height="1" VerticalAlignment="Top" Fill="{ThemeResource LineBrush}" />' + sLineBreak +
    '                    <Rectangle Height="1" VerticalAlignment="Center" Fill="{ThemeResource LineBrush}" />' + sLineBreak +
    '                    <Rectangle Height="1" VerticalAlignment="Bottom" Fill="{ThemeResource LineBrush}" />' + sLineBreak +
    '                    <Canvas x:Name="DetailCanvas">' + sLineBreak +
    '                      <Polygon x:Name="DetailArea">' + sLineBreak +
    '                        <Polygon.Fill>' + sLineBreak +
    '                          <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">' + sLineBreak +
    '                            <GradientStop Color="{ThemeResource SystemAccentColorLight1}" Offset="0" />' + sLineBreak +
    '                            <GradientStop Color="Transparent" Offset="1" />' + sLineBreak +
    '                          </LinearGradientBrush>' + sLineBreak +
    '                        </Polygon.Fill>' + sLineBreak +
    '                      </Polygon>' + sLineBreak +
    '                      <Polyline x:Name="DetailLine" Stroke="{ThemeResource AccentFillColorDefaultBrush}" StrokeThickness="2.6" StrokeLineJoin="Round" />' + sLineBreak +
    '                    </Canvas>' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Grid.Column="1" Style="{StaticResource Glass}" Height="330">' + sLineBreak +
    '                <StackPanel Spacing="14">' + sLineBreak +
    '                  <TextBlock Text="Ratings" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                  <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                    <TextBlock Text="{Binding RatingText}" FontSize="48" FontWeight="SemiBold" FontFamily="Segoe UI Variable Display" />' + sLineBreak +
    '                    <TextBlock Text="{Binding StarsText}" FontSize="18" VerticalAlignment="Center" Foreground="{ThemeResource StarBrush}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <ItemsControl x:Name="DetailBars">' + sLineBreak +
    '                    <ItemsControl.ItemTemplate>' + sLineBreak +
    '                      <DataTemplate>' + sLineBreak +
    '                        <Grid ColumnSpacing="10" Margin="0,4">' + sLineBreak +
    '                          <Grid.ColumnDefinitions>' + sLineBreak +
    '                            <ColumnDefinition Width="28" />' + sLineBreak +
    '                            <ColumnDefinition Width="*" />' + sLineBreak +
    '                            <ColumnDefinition Width="40" />' + sLineBreak +
    '                          </Grid.ColumnDefinitions>' + sLineBreak +
    '                          <TextBlock Text="{Binding Name}" FontSize="12" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                          <Border Grid.Column="1" Height="8" CornerRadius="4" Background="{ThemeResource InnerBrush}">' + sLineBreak +
    '                            <Border Height="8" CornerRadius="4" HorizontalAlignment="Left" Width="{Binding Size}" Background="{ThemeResource AccentFillColorDefaultBrush}" />' + sLineBreak +
    '                          </Border>' + sLineBreak +
    '                          <TextBlock Grid.Column="2" Text="{Binding ValueText}" FontSize="12" HorizontalAlignment="Right" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                        </Grid>' + sLineBreak +
    '                      </DataTemplate>' + sLineBreak +
    '                    </ItemsControl.ItemTemplate>' + sLineBreak +
    '                  </ItemsControl>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '            <Border x:Name="DetailVersions" Style="{StaticResource Glass}" Visibility="Collapsed">' + sLineBreak +
    '              <ItemsControl x:Name="VersionList">' + sLineBreak +
    '                <ItemsControl.ItemTemplate>' + sLineBreak +
    '                  <DataTemplate>' + sLineBreak +
    '                    <Grid Padding="0,12" ColumnSpacing="16" BorderBrush="{ThemeResource LineBrush}" BorderThickness="0,0,0,1">' + sLineBreak +
    '                      <Grid.ColumnDefinitions>' + sLineBreak +
    '                        <ColumnDefinition Width="120" />' + sLineBreak +
    '                        <ColumnDefinition Width="*" />' + sLineBreak +
    '                        <ColumnDefinition Width="140" />' + sLineBreak +
    '                        <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                      </Grid.ColumnDefinitions>' + sLineBreak +
    '                      <TextBlock Text="{Binding Name}" FontSize="15" FontWeight="SemiBold" />' + sLineBreak +
    '                      <TextBlock Grid.Column="1" Text="{Binding Detail}" FontSize="13" TextWrapping="Wrap" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                      <TextBlock Grid.Column="2" Text="{Binding Value}" FontSize="13" />' + sLineBreak +
    '                      <Border Grid.Column="3" CornerRadius="10" Padding="9,3" Background="{ThemeResource InnerBrush}">' + sLineBreak +
    '                        <TextBlock Text="{Binding Status}" FontSize="11" />' + sLineBreak +
    '                      </Border>' + sLineBreak +
    '                    </Grid>' + sLineBreak +
    '                  </DataTemplate>' + sLineBreak +
    '                </ItemsControl.ItemTemplate>' + sLineBreak +
    '              </ItemsControl>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <Border x:Name="DetailIap" Style="{StaticResource Glass}" Visibility="Collapsed">' + sLineBreak +
    '              <ItemsControl x:Name="IapList">' + sLineBreak +
    '                <ItemsControl.ItemTemplate>' + sLineBreak +
    '                  <DataTemplate>' + sLineBreak +
    '                    <Grid Padding="0,12" ColumnSpacing="16" BorderBrush="{ThemeResource LineBrush}" BorderThickness="0,0,0,1">' + sLineBreak +
    '                      <Grid.ColumnDefinitions>' + sLineBreak +
    '                        <ColumnDefinition Width="*" />' + sLineBreak +
    '                        <ColumnDefinition Width="120" />' + sLineBreak +
    '                        <ColumnDefinition Width="140" />' + sLineBreak +
    '                        <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                      </Grid.ColumnDefinitions>' + sLineBreak +
    '                      <TextBlock Text="{Binding Name}" FontSize="15" FontWeight="SemiBold" />' + sLineBreak +
    '                      <TextBlock Grid.Column="1" Text="{Binding Detail}" FontSize="13" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                      <TextBlock Grid.Column="2" Text="{Binding Value}" FontSize="13" />' + sLineBreak +
    '                      <Border Grid.Column="3" CornerRadius="10" Padding="9,3" Background="{ThemeResource GoodSoftBrush}">' + sLineBreak +
    '                        <TextBlock Text="{Binding Status}" FontSize="11" Foreground="{ThemeResource GoodBrush}" />' + sLineBreak +
    '                      </Border>' + sLineBreak +
    '                    </Grid>' + sLineBreak +
    '                  </DataTemplate>' + sLineBreak +
    '                </ItemsControl.ItemTemplate>' + sLineBreak +
    '              </ItemsControl>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <Border x:Name="DetailReviews" Style="{StaticResource Glass}" Visibility="Collapsed">' + sLineBreak +
    '              <ItemsControl x:Name="DetailReviewList">' + sLineBreak +
    '                <ItemsControl.ItemTemplate>' + sLineBreak +
    '                  <DataTemplate>' + sLineBreak +
    '                    <StackPanel Padding="0,12" Spacing="4" BorderBrush="{ThemeResource LineBrush}" BorderThickness="0,0,0,1">' + sLineBreak +
    '                      <StackPanel Orientation="Horizontal" Spacing="10">' + sLineBreak +
    '                        <TextBlock Text="{Binding StarsText}" FontSize="13" Foreground="{ThemeResource StarBrush}" />' + sLineBreak +
    '                        <TextBlock Text="{Binding Title}" FontSize="14" FontWeight="SemiBold" />' + sLineBreak +
    '                      </StackPanel>' + sLineBreak +
    '                      <TextBlock Text="{Binding Body}" FontSize="13" TextWrapping="Wrap" />' + sLineBreak +
    '                      <TextBlock Text="{Binding Meta}" FontSize="11" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                  </DataTemplate>' + sLineBreak +
    '                </ItemsControl.ItemTemplate>' + sLineBreak +
    '              </ItemsControl>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </ScrollViewer>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <ScrollViewer x:Name="PageReleases" VerticalScrollBarVisibility="Auto" Padding="10,6,30,26" Visibility="Collapsed">' + sLineBreak +
    '        <StackPanel Spacing="20">' + sLineBreak +
    '          <Grid ColumnSpacing="24">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <StackPanel x:Name="ReTitle" VerticalAlignment="Bottom">' + sLineBreak +
    '              <TextBlock Text="Release" Style="{StaticResource PageFirst}" />' + sLineBreak +
    '              <TextBlock Text="Board" Style="{StaticResource PageSecond}" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '            <StackPanel x:Name="ReKpis" Grid.Column="1" Orientation="Horizontal" Spacing="12" VerticalAlignment="Bottom">' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock x:Name="InFlightLabel" Text="{Binding InFlightText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="builds in flight" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding WaitingText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="waiting on store review" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" Foreground="{ThemeResource GoodBrush}" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding ShippedText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="shipped, last 30 days" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <Grid x:Name="ReToolbar" ColumnSpacing="12">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <Grid>' + sLineBreak +
    '              <Border CornerRadius="24" Margin="-6" Opacity="0.55">' + sLineBreak +
    '                <Border.Background>' + sLineBreak +
    '                  <RadialGradientBrush>' + sLineBreak +
    '                    <GradientStop Color="{ThemeResource SystemAccentColor}" Offset="0" />' + sLineBreak +
    '                    <GradientStop Color="Transparent" Offset="1" />' + sLineBreak +
    '                  </RadialGradientBrush>' + sLineBreak +
    '                </Border.Background>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Button x:Name="NewReleaseButton" Style="{StaticResource Accent}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                  <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="12" />' + sLineBreak +
    '                  <TextBlock Text="New release" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Button>' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '            <StackPanel Grid.Column="1" Orientation="Horizontal" Spacing="6" Margin="8,0,0,0">' + sLineBreak +
    '              <ToggleButton x:Name="FilterAll" Content="{Binding FilterText0}" Style="{StaticResource Chip}" IsChecked="True" Tag="-1" />' + sLineBreak +
    '              <ToggleButton x:Name="Filter0" Content="{Binding FilterText1}" Style="{StaticResource Chip}" Tag="0" />' + sLineBreak +
    '              <ToggleButton x:Name="Filter1" Content="{Binding FilterText2}" Style="{StaticResource Chip}" Tag="1" />' + sLineBreak +
    '              <ToggleButton x:Name="Filter2" Content="{Binding FilterText3}" Style="{StaticResource Chip}" Tag="2" />' + sLineBreak +
    '              <ToggleButton x:Name="Filter3" Content="{Binding FilterText4}" Style="{StaticResource Chip}" Tag="3" />' + sLineBreak +
    '              <ToggleButton x:Name="Filter4" Content="{Binding FilterText5}" Style="{StaticResource Chip}" Tag="4" />' + sLineBreak +
    '              <ToggleButton x:Name="Filter5" Content="{Binding FilterText6}" Style="{StaticResource Chip}" Tag="5" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '            <Border Grid.Column="2" CornerRadius="20" Padding="3" Background="{ThemeResource InnerBrush}" BorderBrush="{ThemeResource InnerRimBrush}" BorderThickness="1">' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="2">' + sLineBreak +
    '                <ToggleButton x:Name="ViewBoard" Style="{StaticResource Chip}" IsChecked="True" BorderThickness="0">' + sLineBreak +
    '                  <StackPanel Orientation="Horizontal" Spacing="6">' + sLineBreak +
    '                    <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="12" />' + sLineBreak +
    '                    <TextBlock Text="Board" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </ToggleButton>' + sLineBreak +
    '                <ToggleButton x:Name="ViewTimeline" Style="{StaticResource Chip}" BorderThickness="0">' + sLineBreak +
    '                  <StackPanel Orientation="Horizontal" Spacing="6">' + sLineBreak +
    '                    <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="12" />' + sLineBreak +
    '                    <TextBlock Text="Timeline" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </ToggleButton>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <Border x:Name="BoardCard" Style="{StaticResource Glass}" Padding="20,18">' + sLineBreak +
    '            <Grid RowSpacing="14">' + sLineBreak +
    '              <Grid.RowDefinitions>' + sLineBreak +
    '                <RowDefinition Height="Auto" />' + sLineBreak +
    '                <RowDefinition Height="*" />' + sLineBreak +
    '              </Grid.RowDefinitions>' + sLineBreak +
    '              <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                <TextBlock Text="Board" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                <TextBlock Text="Drag a card to move it" Style="{StaticResource Caption}" VerticalAlignment="Center" />' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '              <Grid Grid.Row="1" ColumnSpacing="14" MinHeight="520">' + sLineBreak +
    '                <Grid.ColumnDefinitions>' + sLineBreak +
    '                  <ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition />' + sLineBreak +
    '                </Grid.ColumnDefinitions>' + sLineBreak +
    '                <Border Style="{StaticResource Inner}" Padding="10,12">' + sLineBreak +
    '                  <Grid RowSpacing="10">' + sLineBreak +
    '                    <Grid.RowDefinitions><RowDefinition Height="Auto" /><RowDefinition Height="*" /></Grid.RowDefinitions>' + sLineBreak +
    '                    <Grid Margin="4,0">' + sLineBreak +
    '                      <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                        <Ellipse Width="8" Height="8" Fill="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                        <TextBlock Text="In development" FontSize="13" FontWeight="SemiBold" />' + sLineBreak +
    '                        <Border CornerRadius="9" Padding="7,1" Background="{ThemeResource InnerBrush}"><TextBlock Text="{Binding Count0}" FontSize="11" /></Border>' + sLineBreak +
    '                      </StackPanel>' + sLineBreak +
    '                      <Button Style="{StaticResource RoundInner}" Width="28" Height="28" HorizontalAlignment="Right" Tag="0" AutomationProperties.Name="Add to In development" x:Name="_rw2">' + sLineBreak +
    '                        <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="10" />' + sLineBreak +
    '                      </Button>' + sLineBreak +
    '                    </Grid>' + sLineBreak +
    '                    <ListView x:Name="Column0" Grid.Row="1" Tag="0" SelectionMode="None" CanDragItems="True" AllowDrop="True" ItemContainerStyle="{StaticResource Bare}" ItemTemplate="{StaticResource R' +
    'eleaseCard}">' + sLineBreak +
    '                      <ListView.ItemContainerTransitions>' + sLineBreak +
    '                        <TransitionCollection><AddDeleteThemeTransition /><RepositionThemeTransition /><EntranceThemeTransition IsStaggeringEnabled="True" /></TransitionCollection>' + sLineBreak +
    '                      </ListView.ItemContainerTransitions>' + sLineBreak +
    '                    </ListView>' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                </Border>' + sLineBreak +
    '                <Border Grid.Column="1" Style="{StaticResource Inner}" Padding="10,12">' + sLineBreak +
    '                  <Grid RowSpacing="10">' + sLineBreak +
    '                    <Grid.RowDefinitions><RowDefinition Height="Auto" /><RowDefinition Height="*" /></Grid.RowDefinitions>' + sLineBreak +
    '                    <Grid Margin="4,0">' + sLineBreak +
    '                      <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                        <Ellipse Width="8" Height="8" Fill="{ThemeResource TealBrush}" />' + sLineBreak +
    '                        <TextBlock Text="Beta" FontSize="13" FontWeight="SemiBold" />' + sLineBreak +
    '                        <Border CornerRadius="9" Padding="7,1" Background="{ThemeResource InnerBrush}"><TextBlock Text="{Binding Count1}" FontSize="11" /></Border>' + sLineBreak +
    '                      </StackPanel>' + sLineBreak +
    '                      <Button Style="{StaticResource RoundInner}" Width="28" Height="28" HorizontalAlignment="Right" Tag="1" AutomationProperties.Name="Add to Beta" x:Name="_rw3">' + sLineBreak +
    '                        <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="10" />' + sLineBreak +
    '                      </Button>' + sLineBreak +
    '                    </Grid>' + sLineBreak +
    '                    <ListView x:Name="Column1" Grid.Row="1" Tag="1" SelectionMode="None" CanDragItems="True" AllowDrop="True" ItemContainerStyle="{StaticResource Bare}" ItemTemplate="{StaticResource R' +
    'eleaseCard}">' + sLineBreak +
    '                      <ListView.ItemContainerTransitions>' + sLineBreak +
    '                        <TransitionCollection><AddDeleteThemeTransition /><RepositionThemeTransition /><EntranceThemeTransition IsStaggeringEnabled="True" /></TransitionCollection>' + sLineBreak +
    '                      </ListView.ItemContainerTransitions>' + sLineBreak +
    '                    </ListView>' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                </Border>' + sLineBreak +
    '                <Border Grid.Column="2" Style="{StaticResource Inner}" Padding="10,12">' + sLineBreak +
    '                  <Grid RowSpacing="10">' + sLineBreak +
    '                    <Grid.RowDefinitions><RowDefinition Height="Auto" /><RowDefinition Height="*" /></Grid.RowDefinitions>' + sLineBreak +
    '                    <Grid Margin="4,0">' + sLineBreak +
    '                      <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                        <Ellipse Width="8" Height="8" Fill="{ThemeResource WarnBrush}" />' + sLineBreak +
    '                        <TextBlock Text="In store review" FontSize="13" FontWeight="SemiBold" />' + sLineBreak +
    '                        <Border CornerRadius="9" Padding="7,1" Background="{ThemeResource InnerBrush}"><TextBlock Text="{Binding Count2}" FontSize="11" /></Border>' + sLineBreak +
    '                      </StackPanel>' + sLineBreak +
    '                      <Button Style="{StaticResource RoundInner}" Width="28" Height="28" HorizontalAlignment="Right" Tag="2" AutomationProperties.Name="Add to In store review" x:Name="_rw4">' + sLineBreak +
    '                        <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="10" />' + sLineBreak +
    '                      </Button>' + sLineBreak +
    '                    </Grid>' + sLineBreak +
    '                    <ListView x:Name="Column2" Grid.Row="1" Tag="2" SelectionMode="None" CanDragItems="True" AllowDrop="True" ItemContainerStyle="{StaticResource Bare}" ItemTemplate="{StaticResource R' +
    'eleaseCard}">' + sLineBreak +
    '                      <ListView.ItemContainerTransitions>' + sLineBreak +
    '                        <TransitionCollection><AddDeleteThemeTransition /><RepositionThemeTransition /><EntranceThemeTransition IsStaggeringEnabled="True" /></TransitionCollection>' + sLineBreak +
    '                      </ListView.ItemContainerTransitions>' + sLineBreak +
    '                    </ListView>' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                </Border>' + sLineBreak +
    '                <Border Grid.Column="3" Style="{StaticResource Inner}" Padding="10,12">' + sLineBreak +
    '                  <Grid RowSpacing="10">' + sLineBreak +
    '                    <Grid.RowDefinitions><RowDefinition Height="Auto" /><RowDefinition Height="*" /></Grid.RowDefinitions>' + sLineBreak +
    '                    <Grid Margin="4,0">' + sLineBreak +
    '                      <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                        <Ellipse Width="8" Height="8" Fill="{ThemeResource AccentFillColorDefaultBrush}" />' + sLineBreak +
    '                        <TextBlock Text="Ready for release" FontSize="13" FontWeight="SemiBold" />' + sLineBreak +
    '                        <Border CornerRadius="9" Padding="7,1" Background="{ThemeResource InnerBrush}"><TextBlock Text="{Binding Count3}" FontSize="11" /></Border>' + sLineBreak +
    '                      </StackPanel>' + sLineBreak +
    '                      <Button Style="{StaticResource RoundInner}" Width="28" Height="28" HorizontalAlignment="Right" Tag="3" AutomationProperties.Name="Add to Ready for release" x:Name="_rw5">' + sLineBreak +
    '                        <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="10" />' + sLineBreak +
    '                      </Button>' + sLineBreak +
    '                    </Grid>' + sLineBreak +
    '                    <ListView x:Name="Column3" Grid.Row="1" Tag="3" SelectionMode="None" CanDragItems="True" AllowDrop="True" ItemContainerStyle="{StaticResource Bare}" ItemTemplate="{StaticResource R' +
    'eleaseCard}">' + sLineBreak +
    '                      <ListView.ItemContainerTransitions>' + sLineBreak +
    '                        <TransitionCollection><AddDeleteThemeTransition /><RepositionThemeTransition /><EntranceThemeTransition IsStaggeringEnabled="True" /></TransitionCollection>' + sLineBreak +
    '                      </ListView.ItemContainerTransitions>' + sLineBreak +
    '                    </ListView>' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                </Border>' + sLineBreak +
    '                <Border Grid.Column="4" Style="{StaticResource Inner}" Padding="10,12">' + sLineBreak +
    '                  <Grid RowSpacing="10">' + sLineBreak +
    '                    <Grid.RowDefinitions><RowDefinition Height="Auto" /><RowDefinition Height="*" /></Grid.RowDefinitions>' + sLineBreak +
    '                    <Grid Margin="4,0">' + sLineBreak +
    '                      <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                        <Ellipse Width="8" Height="8" Fill="{ThemeResource GoodBrush}" />' + sLineBreak +
    '                        <TextBlock Text="Live" FontSize="13" FontWeight="SemiBold" />' + sLineBreak +
    '                        <Border CornerRadius="9" Padding="7,1" Background="{ThemeResource InnerBrush}"><TextBlock Text="{Binding Count4}" FontSize="11" /></Border>' + sLineBreak +
    '                      </StackPanel>' + sLineBreak +
    '                      <Button Style="{StaticResource RoundInner}" Width="28" Height="28" HorizontalAlignment="Right" Tag="4" AutomationProperties.Name="Add to Live" x:Name="_rw6">' + sLineBreak +
    '                        <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="10" />' + sLineBreak +
    '                      </Button>' + sLineBreak +
    '                    </Grid>' + sLineBreak +
    '                    <ListView x:Name="Column4" Grid.Row="1" Tag="4" SelectionMode="None" CanDragItems="True" AllowDrop="True" ItemContainerStyle="{StaticResource Bare}" ItemTemplate="{StaticResource R' +
    'eleaseCard}">' + sLineBreak +
    '                      <ListView.ItemContainerTransitions>' + sLineBreak +
    '                        <TransitionCollection><AddDeleteThemeTransition /><RepositionThemeTransition /><EntranceThemeTransition IsStaggeringEnabled="True" /></TransitionCollection>' + sLineBreak +
    '                      </ListView.ItemContainerTransitions>' + sLineBreak +
    '                    </ListView>' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                </Border>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '          <Border x:Name="TimelineCard" Style="{StaticResource Glass}" Visibility="Collapsed">' + sLineBreak +
    '            <StackPanel Spacing="10">' + sLineBreak +
    '              <Grid Margin="0,0,0,6">' + sLineBreak +
    '                <Grid.ColumnDefinitions>' + sLineBreak +
    '                  <ColumnDefinition Width="260" />' + sLineBreak +
    '                  <ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition />' + sLineBreak +
    '                </Grid.ColumnDefinitions>' + sLineBreak +
    '                <TextBlock Text="Timeline" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                <TextBlock Grid.Column="1" Text="In development" Style="{StaticResource Caption}" HorizontalAlignment="Center" />' + sLineBreak +
    '                <TextBlock Grid.Column="2" Text="Beta" Style="{StaticResource Caption}" HorizontalAlignment="Center" />' + sLineBreak +
    '                <TextBlock Grid.Column="3" Text="In store review" Style="{StaticResource Caption}" HorizontalAlignment="Center" />' + sLineBreak +
    '                <TextBlock Grid.Column="4" Text="Ready" Style="{StaticResource Caption}" HorizontalAlignment="Center" />' + sLineBreak +
    '                <TextBlock Grid.Column="5" Text="Live" Style="{StaticResource Caption}" HorizontalAlignment="Center" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <ItemsControl x:Name="TimelineList">' + sLineBreak +
    '                <ItemsControl.ItemContainerTransitions>' + sLineBreak +
    '                  <TransitionCollection><EntranceThemeTransition IsStaggeringEnabled="True" /><RepositionThemeTransition /></TransitionCollection>' + sLineBreak +
    '                </ItemsControl.ItemContainerTransitions>' + sLineBreak +
    '                <ItemsControl.ItemTemplate>' + sLineBreak +
    '                  <DataTemplate>' + sLineBreak +
    '                    <Grid Height="52">' + sLineBreak +
    '                      <Grid.ColumnDefinitions>' + sLineBreak +
    '                        <ColumnDefinition Width="260" />' + sLineBreak +
    '                        <ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition />' + sLineBreak +
    '                      </Grid.ColumnDefinitions>' + sLineBreak +
    '                      <StackPanel Orientation="Horizontal" Spacing="10">' + sLineBreak +
    '                        <Border Width="32" Height="32" CornerRadius="10" Background="{Binding Tint}">' + sLineBreak +
    '                          <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="{Binding Glyph}" FontSize="14" Foreground="White" />' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                        <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                          <TextBlock Text="{Binding Title}" FontSize="13" FontWeight="SemiBold" />' + sLineBreak +
    '                          <TextBlock Text="{Binding BuildText}" FontSize="11" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                        </StackPanel>' + sLineBreak +
    '                      </StackPanel>' + sLineBreak +
    '                      <Rectangle Grid.Column="1" Grid.ColumnSpan="5" Height="2" Margin="40,0" Fill="{ThemeResource LineBrush}" />' + sLineBreak +
    '                      <Rectangle Grid.Column="1" Grid.ColumnSpan="5" Height="2" Margin="40,0" HorizontalAlignment="Left" Width="{Binding TrackWidth}" Fill="{ThemeResource AccentFillColorDefaultBrush}"' +
    ' />' + sLineBreak +
    '                      <Ellipse Grid.Column="1" Width="14" Height="14" Fill="{ThemeResource AccentFillColorDefaultBrush}" Opacity="{Binding Step0}" />' + sLineBreak +
    '                      <Ellipse Grid.Column="2" Width="14" Height="14" Fill="{ThemeResource AccentFillColorDefaultBrush}" Opacity="{Binding Step1}" />' + sLineBreak +
    '                      <Ellipse Grid.Column="3" Width="14" Height="14" Fill="{ThemeResource AccentFillColorDefaultBrush}" Opacity="{Binding Step2}" />' + sLineBreak +
    '                      <Ellipse Grid.Column="4" Width="14" Height="14" Fill="{ThemeResource AccentFillColorDefaultBrush}" Opacity="{Binding Step3}" />' + sLineBreak +
    '                      <Ellipse Grid.Column="5" Width="14" Height="14" Fill="{ThemeResource GoodBrush}" Opacity="{Binding Step4}" />' + sLineBreak +
    '                    </Grid>' + sLineBreak +
    '                  </DataTemplate>' + sLineBreak +
    '                </ItemsControl.ItemTemplate>' + sLineBreak +
    '              </ItemsControl>' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Border>' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </ScrollViewer>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <ScrollViewer x:Name="PageReviews" VerticalScrollBarVisibility="Auto" Padding="10,6,30,26" Visibility="Collapsed">' + sLineBreak +
    '        <StackPanel Spacing="20">' + sLineBreak +
    '          <Grid ColumnSpacing="24">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <StackPanel x:Name="RvTitle" VerticalAlignment="Bottom">' + sLineBreak +
    '              <TextBlock Text="Ratings and" Style="{StaticResource PageFirst}" />' + sLineBreak +
    '              <TextBlock Text="Reviews" Style="{StaticResource PageSecond}" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '            <StackPanel x:Name="RvKpis" Grid.Column="1" Orientation="Horizontal" Spacing="12" VerticalAlignment="Bottom">' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" Foreground="{ThemeResource StarBrush}" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding RatingText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="average rating" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock x:Name="WrittenLabel" Text="{Binding WrittenText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="written reviews" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding ReplyRateText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="replied to" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <Grid ColumnSpacing="20">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="360" />' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <Border x:Name="RvSummary" Style="{StaticResource Glass}" VerticalAlignment="Top">' + sLineBreak +
    '              <StackPanel Spacing="14">' + sLineBreak +
    '                <TextBlock Text="All apps" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <TextBlock Text="{Binding RatingText}" FontSize="52" FontWeight="SemiBold" FontFamily="Segoe UI Variable Display" />' + sLineBreak +
    '                  <TextBlock Text="★★★★★" FontSize="20" VerticalAlignment="Center" Foreground="{ThemeResource StarBrush}" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <ItemsControl x:Name="ReviewBars">' + sLineBreak +
    '                  <ItemsControl.ItemTemplate>' + sLineBreak +
    '                    <DataTemplate>' + sLineBreak +
    '                      <Grid ColumnSpacing="10" Margin="0,4">' + sLineBreak +
    '                        <Grid.ColumnDefinitions>' + sLineBreak +
    '                          <ColumnDefinition Width="28" />' + sLineBreak +
    '                          <ColumnDefinition Width="*" />' + sLineBreak +
    '                          <ColumnDefinition Width="40" />' + sLineBreak +
    '                        </Grid.ColumnDefinitions>' + sLineBreak +
    '                        <TextBlock Text="{Binding Name}" FontSize="12" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                        <Border Grid.Column="1" Height="8" CornerRadius="4" Background="{ThemeResource InnerBrush}">' + sLineBreak +
    '                          <Border Height="8" CornerRadius="4" HorizontalAlignment="Left" Width="{Binding Size}" Background="{ThemeResource AccentFillColorDefaultBrush}" />' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                        <TextBlock Grid.Column="2" Text="{Binding ValueText}" FontSize="12" HorizontalAlignment="Right" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                      </Grid>' + sLineBreak +
    '                    </DataTemplate>' + sLineBreak +
    '                  </ItemsControl.ItemTemplate>' + sLineBreak +
    '                </ItemsControl>' + sLineBreak +
    '                <Border Style="{StaticResource Inner}">' + sLineBreak +
    '                  <StackPanel Spacing="4">' + sLineBreak +
    '                    <TextBlock Text="Tip" Style="{StaticResource Caption}" />' + sLineBreak +
    '                    <TextBlock Text="Click a review to reply. Replies within a day lift ratings the most." FontSize="13" TextWrapping="Wrap" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </Border>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <StackPanel x:Name="RvList" Grid.Column="1" Spacing="14">' + sLineBreak +
    '              <Grid ColumnSpacing="10">' + sLineBreak +
    '                <Grid.ColumnDefinitions>' + sLineBreak +
    '                  <ColumnDefinition Width="*" />' + sLineBreak +
    '                  <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                </Grid.ColumnDefinitions>' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="6">' + sLineBreak +
    '                  <ToggleButton x:Name="StarsAll" Content="All" Style="{StaticResource Chip}" IsChecked="True" Tag="0" />' + sLineBreak +
    '                  <ToggleButton x:Name="Stars5" Content="5 ★" Style="{StaticResource Chip}" Tag="5" />' + sLineBreak +
    '                  <ToggleButton x:Name="Stars4" Content="4 ★" Style="{StaticResource Chip}" Tag="4" />' + sLineBreak +
    '                  <ToggleButton x:Name="Stars3" Content="3 ★" Style="{StaticResource Chip}" Tag="3" />' + sLineBreak +
    '                  <ToggleButton x:Name="Stars2" Content="2 ★" Style="{StaticResource Chip}" Tag="2" />' + sLineBreak +
    '                  <ToggleButton x:Name="Stars1" Content="1 ★" Style="{StaticResource Chip}" Tag="1" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <ComboBox x:Name="ReviewAppBox" Grid.Column="1" Width="180" CornerRadius="16" Background="{ThemeResource InnerBrush}" BorderBrush="{ThemeResource InnerRimBrush}" />' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <ListView x:Name="ReviewList" SelectionMode="None" IsItemClickEnabled="True" ItemContainerStyle="{StaticResource Bare}">' + sLineBreak +
    '                <ListView.ItemContainerTransitions>' + sLineBreak +
    '                  <TransitionCollection><AddDeleteThemeTransition /><RepositionThemeTransition /><EntranceThemeTransition IsStaggeringEnabled="True" FromVerticalOffset="30" /></TransitionCollection>' + sLineBreak +
    '                </ListView.ItemContainerTransitions>' + sLineBreak +
    '                <ListView.ItemTemplate>' + sLineBreak +
    '                  <DataTemplate>' + sLineBreak +
    '                    <Border Padding="20,16" CornerRadius="22" Background="{ThemeResource GlassBrush}" BorderBrush="{ThemeResource GlassRimBrush}" BorderThickness="1">' + sLineBreak +
    '                      <Grid ColumnSpacing="16">' + sLineBreak +
    '                        <Grid.ColumnDefinitions>' + sLineBreak +
    '                          <ColumnDefinition Width="*" />' + sLineBreak +
    '                          <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                        </Grid.ColumnDefinitions>' + sLineBreak +
    '                        <StackPanel Spacing="6">' + sLineBreak +
    '                          <StackPanel Orientation="Horizontal" Spacing="10">' + sLineBreak +
    '                            <TextBlock Text="{Binding StarsText}" FontSize="14" Foreground="{ThemeResource StarBrush}" />' + sLineBreak +
    '                            <TextBlock Text="{Binding Title}" FontSize="15" FontWeight="SemiBold" />' + sLineBreak +
    '                          </StackPanel>' + sLineBreak +
    '                          <TextBlock Text="{Binding Body}" FontSize="13" TextWrapping="Wrap" />' + sLineBreak +
    '                          <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                            <Border CornerRadius="10" Padding="4,2,9,2" Background="{ThemeResource InnerBrush}">' + sLineBreak +
    '                              <StackPanel Orientation="Horizontal" Spacing="6">' + sLineBreak +
    '                                <Border Width="16" Height="16" CornerRadius="5" Background="{Binding Tint}" />' + sLineBreak +
    '                                <TextBlock Text="{Binding AppName}" FontSize="11" />' + sLineBreak +
    '                              </StackPanel>' + sLineBreak +
    '                            </Border>' + sLineBreak +
    '                            <TextBlock Text="{Binding Meta}" FontSize="11" Foreground="{ThemeResource MutedBrush}" VerticalAlignment="Center" />' + sLineBreak +
    '                          </StackPanel>' + sLineBreak +
    '                          <Border Style="{StaticResource Inner}" Padding="12,8" Visibility="{Binding Replied, Converter={StaticResource BoolToVisibility}}">' + sLineBreak +
    '                            <TextBlock Text="{Binding ReplyText}" FontSize="12" TextWrapping="Wrap" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                          </Border>' + sLineBreak +
    '                        </StackPanel>' + sLineBreak +
    '                        <Border Grid.Column="1" VerticalAlignment="Top" CornerRadius="14" Padding="12,5" Background="{ThemeResource InnerBrush}" BorderBrush="{ThemeResource InnerRimBrush}" BorderThick' +
    'ness="1" Visibility="{Binding Replied, Converter={StaticResource InverseBoolToVisibility}}">' + sLineBreak +
    '                          <StackPanel Orientation="Horizontal" Spacing="6">' + sLineBreak +
    '                            <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="11" />' + sLineBreak +
    '                            <TextBlock Text="Reply" FontSize="12" />' + sLineBreak +
    '                          </StackPanel>' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                        <Border Grid.Column="1" VerticalAlignment="Top" CornerRadius="14" Padding="12,5" Background="{ThemeResource GoodSoftBrush}" Visibility="{Binding Replied, Converter={StaticResou' +
    'rce BoolToVisibility}}">' + sLineBreak +
    '                          <TextBlock Text="Replied" FontSize="12" Foreground="{ThemeResource GoodBrush}" />' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                      </Grid>' + sLineBreak +
    '                    </Border>' + sLineBreak +
    '                  </DataTemplate>' + sLineBreak +
    '                </ListView.ItemTemplate>' + sLineBreak +
    '              </ListView>' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </ScrollViewer>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <ScrollViewer x:Name="PageAudience" VerticalScrollBarVisibility="Auto" Padding="10,6,30,26" Visibility="Collapsed">' + sLineBreak +
    '        <StackPanel Spacing="20">' + sLineBreak +
    '          <Grid ColumnSpacing="24">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <StackPanel x:Name="AuTitle" VerticalAlignment="Bottom">' + sLineBreak +
    '              <TextBlock Text="Your" Style="{StaticResource PageFirst}" />' + sLineBreak +
    '              <TextBlock Text="Audience" Style="{StaticResource PageSecond}" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '            <StackPanel x:Name="AuKpis" Grid.Column="1" Orientation="Horizontal" Spacing="12" VerticalAlignment="Bottom">' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding SubscribersText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="active subscribers" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding TrialRateText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="of trials become paid" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding Downloads30Text}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="downloads, last 30 days" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <StackPanel x:Name="AuFilters" Orientation="Horizontal" Spacing="6">' + sLineBreak +
    '            <ToggleButton x:Name="AudAll" Content="{Binding AudText0}" Style="{StaticResource Chip}" IsChecked="True" Tag="-1" />' + sLineBreak +
    '            <ToggleButton x:Name="Aud0" Content="{Binding AudText1}" Style="{StaticResource Chip}" Tag="0" />' + sLineBreak +
    '            <ToggleButton x:Name="Aud1" Content="{Binding AudText2}" Style="{StaticResource Chip}" Tag="1" />' + sLineBreak +
    '            <ToggleButton x:Name="Aud2" Content="{Binding AudText3}" Style="{StaticResource Chip}" Tag="2" />' + sLineBreak +
    '            <ToggleButton x:Name="Aud3" Content="{Binding AudText4}" Style="{StaticResource Chip}" Tag="3" />' + sLineBreak +
    '            <ToggleButton x:Name="Aud4" Content="{Binding AudText5}" Style="{StaticResource Chip}" Tag="4" />' + sLineBreak +
    '            <ToggleButton x:Name="Aud5" Content="{Binding AudText6}" Style="{StaticResource Chip}" Tag="5" />' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '          <Grid ColumnSpacing="20">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="2*" />' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <Border x:Name="SubsCard" Style="{StaticResource Glass}" Height="420">' + sLineBreak +
    '              <Grid RowSpacing="14">' + sLineBreak +
    '                <Grid.RowDefinitions>' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                  <RowDefinition Height="*" />' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                </Grid.RowDefinitions>' + sLineBreak +
    '                <Grid>' + sLineBreak +
    '                  <StackPanel>' + sLineBreak +
    '                    <TextBlock Text="Active subscribers" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                    <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                      <TextBlock Text="{Binding SubsCaption}" Style="{StaticResource Caption}" />' + sLineBreak +
    '                      <TextBlock Text="▲ 36% in 12 months" FontSize="12" Foreground="{ThemeResource GoodBrush}" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <StackPanel Orientation="Horizontal" Spacing="16" HorizontalAlignment="Right" VerticalAlignment="Top">' + sLineBreak +
    '                    <StackPanel Orientation="Horizontal" Spacing="6">' + sLineBreak +
    '                      <Rectangle Width="18" Height="3" RadiusX="1.5" RadiusY="1.5" Fill="{ThemeResource AccentFillColorDefaultBrush}" VerticalAlignment="Center" />' + sLineBreak +
    '                      <TextBlock Text="Paying subscribers" Style="{StaticResource Caption}" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                    <StackPanel Orientation="Horizontal" Spacing="6">' + sLineBreak +
    '                      <Line X1="0" Y1="0" X2="18" Y2="0" Stroke="{ThemeResource TealBrush}" StrokeThickness="2" StrokeDashArray="2,2" VerticalAlignment="Center" />' + sLineBreak +
    '                      <TextBlock Text="Started a trial" Style="{StaticResource Caption}" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <Grid Grid.Row="1" ColumnSpacing="10">' + sLineBreak +
    '                  <Grid.ColumnDefinitions>' + sLineBreak +
    '                    <ColumnDefinition Width="46" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                  </Grid.ColumnDefinitions>' + sLineBreak +
    '                  <Grid>' + sLineBreak +
    '                    <TextBlock Text="25K" Style="{StaticResource Caption}" VerticalAlignment="Top" Margin="0,-8,0,0" />' + sLineBreak +
    '                    <TextBlock Text="12.5K" Style="{StaticResource Caption}" VerticalAlignment="Center" />' + sLineBreak +
    '                    <TextBlock Text="0" Style="{StaticResource Caption}" VerticalAlignment="Bottom" Margin="0,0,0,-8" />' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                  <Grid Grid.Column="1">' + sLineBreak +
    '                    <Rectangle Height="1" VerticalAlignment="Top" Fill="{ThemeResource LineBrush}" />' + sLineBreak +
    '                    <Rectangle Height="1" VerticalAlignment="Center" Fill="{ThemeResource LineBrush}" />' + sLineBreak +
    '                    <Rectangle Height="1" VerticalAlignment="Bottom" Fill="{ThemeResource LineBrush}" />' + sLineBreak +
    '                    <Canvas x:Name="SubsCanvas">' + sLineBreak +
    '                      <Polygon x:Name="SubsArea">' + sLineBreak +
    '                        <Polygon.Fill>' + sLineBreak +
    '                          <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">' + sLineBreak +
    '                            <GradientStop Color="{ThemeResource SystemAccentColorLight1}" Offset="0" />' + sLineBreak +
    '                            <GradientStop Color="Transparent" Offset="1" />' + sLineBreak +
    '                          </LinearGradientBrush>' + sLineBreak +
    '                        </Polygon.Fill>' + sLineBreak +
    '                      </Polygon>' + sLineBreak +
    '                      <Polyline x:Name="TrialLine" Stroke="{ThemeResource TealBrush}" StrokeThickness="2" StrokeDashArray="2,2" />' + sLineBreak +
    '                      <Polyline x:Name="SubsLine" Stroke="{ThemeResource AccentFillColorDefaultBrush}" StrokeThickness="2.6" StrokeLineJoin="Round" />' + sLineBreak +
    '                    </Canvas>' + sLineBreak +
    '                    <Grid x:Name="SubsHover" Background="Transparent">' + sLineBreak +
    '                      <Rectangle x:Name="SubsGuide" Width="1" HorizontalAlignment="Left" Fill="{ThemeResource FaintBrush}" Opacity="0" IsHitTestVisible="False" />' + sLineBreak +
    '                      <Ellipse x:Name="SubsDot" Width="12" Height="12" HorizontalAlignment="Left" VerticalAlignment="Top" Fill="{ThemeResource AccentFillColorDefaultBrush}" Stroke="White" StrokeThickn' +
    'ess="2" Opacity="0" IsHitTestVisible="False" />' + sLineBreak +
    '                      <Ellipse x:Name="TrialDot" Width="10" Height="10" HorizontalAlignment="Left" VerticalAlignment="Top" Fill="{ThemeResource TealBrush}" Stroke="White" StrokeThickness="2" Opacity="' +
    '0" IsHitTestVisible="False" />' + sLineBreak +
    '                      <Border x:Name="SubsTip" Width="168" HorizontalAlignment="Left" VerticalAlignment="Top" Padding="14,10" CornerRadius="16" Opacity="0" IsHitTestVisible="False" Background="{ThemeR' +
    'esource GlassStrongBrush}" BorderBrush="{ThemeResource GlassRimBrush}" BorderThickness="1">' + sLineBreak +
    '                        <StackPanel Spacing="4">' + sLineBreak +
    '                          <TextBlock x:Name="TipMonth" Text="Jul" FontSize="12" FontWeight="SemiBold" />' + sLineBreak +
    '                          <Grid>' + sLineBreak +
    '                            <TextBlock Text="Subscribers" Style="{StaticResource Caption}" />' + sLineBreak +
    '                            <TextBlock x:Name="TipSubs" Text="19.2K" FontSize="12" HorizontalAlignment="Right" />' + sLineBreak +
    '                          </Grid>' + sLineBreak +
    '                          <Grid>' + sLineBreak +
    '                            <TextBlock Text="Started a trial" Style="{StaticResource Caption}" />' + sLineBreak +
    '                            <TextBlock x:Name="TipTrial" Text="3.8K" FontSize="12" HorizontalAlignment="Right" Foreground="{ThemeResource TealBrush}" />' + sLineBreak +
    '                          </Grid>' + sLineBreak +
    '                        </StackPanel>' + sLineBreak +
    '                      </Border>' + sLineBreak +
    '                    </Grid>' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <Grid Grid.Row="2" Margin="56,0,0,0">' + sLineBreak +
    '                  <Grid.ColumnDefinitions>' + sLineBreak +
    '                    <ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition />' + sLineBreak +
    '                    <ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition />' + sLineBreak +
    '                  </Grid.ColumnDefinitions>' + sLineBreak +
    '                  <TextBlock Grid.Column="0" Text="Nov" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="1" Text="Dec" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="2" Text="Jan" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="3" Text="Feb" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="4" Text="Mar" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="5" Text="Apr" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="6" Text="May" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="7" Text="Jun" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="8" Text="Jul" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="9" Text="Aug" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="10" Text="Sep" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="11" Text="Oct" Style="{StaticResource Caption}" />' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <Border x:Name="PlansCard" Grid.Column="1" Style="{StaticResource Glass}" Height="420">' + sLineBreak +
    '              <Grid RowSpacing="16">' + sLineBreak +
    '                <Grid.RowDefinitions>' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                  <RowDefinition Height="*" />' + sLineBreak +
    '                  <RowDefinition Height="Auto" />' + sLineBreak +
    '                </Grid.RowDefinitions>' + sLineBreak +
    '                <TextBlock Text="Plans" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                <Grid x:Name="Donut" Grid.Row="1" Width="200" Height="200">' + sLineBreak +
    '                  <Ellipse StrokeThickness="22" Stroke="{ThemeResource InnerBrush}" />' + sLineBreak +
    '                  <Ellipse x:Name="PlanArc0" StrokeThickness="22" Stroke="{ThemeResource AccentFillColorDefaultBrush}" RenderTransformOrigin="0.5,0.5">' + sLineBreak +
    '                    <Ellipse.RenderTransform><RotateTransform Angle="-90" /></Ellipse.RenderTransform>' + sLineBreak +
    '                  </Ellipse>' + sLineBreak +
    '                  <Ellipse x:Name="PlanArc1" StrokeThickness="22" Stroke="{ThemeResource TealBrush}" RenderTransformOrigin="0.5,0.5">' + sLineBreak +
    '                    <Ellipse.RenderTransform><RotateTransform Angle="-90" /></Ellipse.RenderTransform>' + sLineBreak +
    '                  </Ellipse>' + sLineBreak +
    '                  <Ellipse x:Name="PlanArc2" StrokeThickness="22" Stroke="{ThemeResource WarnBrush}" RenderTransformOrigin="0.5,0.5">' + sLineBreak +
    '                    <Ellipse.RenderTransform><RotateTransform Angle="-90" /></Ellipse.RenderTransform>' + sLineBreak +
    '                  </Ellipse>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding PlansText}" FontSize="30" FontWeight="SemiBold" FontFamily="Segoe UI Variable Display" HorizontalAlignment="Center" />' + sLineBreak +
    '                    <TextBlock Text="plans sold" Style="{StaticResource Caption}" HorizontalAlignment="Center" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <StackPanel Grid.Row="2" Spacing="8">' + sLineBreak +
    '                  <Grid>' + sLineBreak +
    '                    <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                      <Ellipse Width="9" Height="9" Fill="{ThemeResource AccentFillColorDefaultBrush}" />' + sLineBreak +
    '                      <TextBlock Text="Monthly" FontSize="13" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                    <TextBlock Text="{Binding PlanText0}" FontSize="13" HorizontalAlignment="Right" />' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                  <Grid>' + sLineBreak +
    '                    <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                      <Ellipse Width="9" Height="9" Fill="{ThemeResource TealBrush}" />' + sLineBreak +
    '                      <TextBlock Text="Yearly" FontSize="13" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                    <TextBlock Text="{Binding PlanText1}" FontSize="13" HorizontalAlignment="Right" />' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                  <Grid>' + sLineBreak +
    '                    <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                      <Ellipse Width="9" Height="9" Fill="{ThemeResource WarnBrush}" />' + sLineBreak +
    '                      <TextBlock Text="Lifetime and one-time" FontSize="13" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                    <TextBlock Text="{Binding PlanText2}" FontSize="13" HorizontalAlignment="Right" />' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <Grid ColumnSpacing="20">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="2*" />' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <Border x:Name="CohortCard" Style="{StaticResource Glass}">' + sLineBreak +
    '              <StackPanel Spacing="12">' + sLineBreak +
    '                <Grid>' + sLineBreak +
    '                  <StackPanel>' + sLineBreak +
    '                    <TextBlock Text="Retention by cohort" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                    <TextBlock Text="Share of each month''s new subscribers still paying" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <Button x:Name="ExportCsvButton" HorizontalAlignment="Right" VerticalAlignment="Top" CornerRadius="16" Padding="14,6" Background="{ThemeResource InnerBrush}" BorderBrush="{ThemeResou' +
    'rce InnerRimBrush}">' + sLineBreak +
    '                    <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                      <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="12" />' + sLineBreak +
    '                      <TextBlock Text="Export CSV" FontSize="12" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                  </Button>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <Grid>' + sLineBreak +
    '                  <Grid.ColumnDefinitions>' + sLineBreak +
    '                    <ColumnDefinition Width="110" />' + sLineBreak +
    '                    <ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition />' + sLineBreak +
    '                  </Grid.ColumnDefinitions>' + sLineBreak +
    '                  <TextBlock Text="Cohort" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="1" Text="Month 1" Style="{StaticResource Caption}" HorizontalAlignment="Center" />' + sLineBreak +
    '                  <TextBlock Grid.Column="2" Text="Month 2" Style="{StaticResource Caption}" HorizontalAlignment="Center" />' + sLineBreak +
    '                  <TextBlock Grid.Column="3" Text="Month 3" Style="{StaticResource Caption}" HorizontalAlignment="Center" />' + sLineBreak +
    '                  <TextBlock Grid.Column="4" Text="Month 4" Style="{StaticResource Caption}" HorizontalAlignment="Center" />' + sLineBreak +
    '                  <TextBlock Grid.Column="5" Text="Month 5" Style="{StaticResource Caption}" HorizontalAlignment="Center" />' + sLineBreak +
    '                  <TextBlock Grid.Column="6" Text="Month 6" Style="{StaticResource Caption}" HorizontalAlignment="Center" />' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <ItemsControl x:Name="CohortList">' + sLineBreak +
    '                  <ItemsControl.ItemTemplate>' + sLineBreak +
    '                    <DataTemplate>' + sLineBreak +
    '                      <Grid Height="40" ColumnSpacing="4" Margin="0,0,0,4">' + sLineBreak +
    '                        <Grid.ColumnDefinitions>' + sLineBreak +
    '                          <ColumnDefinition Width="106" />' + sLineBreak +
    '                          <ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition /><ColumnDefinition />' + sLineBreak +
    '                        </Grid.ColumnDefinitions>' + sLineBreak +
    '                        <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                          <TextBlock Text="{Binding Name}" FontSize="13" FontWeight="SemiBold" />' + sLineBreak +
    '                          <TextBlock Text="{Binding SizeText}" FontSize="11" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                        </StackPanel>' + sLineBreak +
    '                        <Grid Grid.Column="1"><Border CornerRadius="8" Background="{ThemeResource AccentFillColorDefaultBrush}" Opacity="{Binding O1}" /><TextBlock Text="{Binding C1}" FontSize="12" Ho' +
    'rizontalAlignment="Center" VerticalAlignment="Center" Foreground="{ThemeResource TextOnAccentFillColorPrimaryBrush}" /></Grid>' + sLineBreak +
    '                        <Grid Grid.Column="2"><Border CornerRadius="8" Background="{ThemeResource AccentFillColorDefaultBrush}" Opacity="{Binding O2}" /><TextBlock Text="{Binding C2}" FontSize="12" Ho' +
    'rizontalAlignment="Center" VerticalAlignment="Center" Foreground="{ThemeResource TextOnAccentFillColorPrimaryBrush}" /></Grid>' + sLineBreak +
    '                        <Grid Grid.Column="3"><Border CornerRadius="8" Background="{ThemeResource AccentFillColorDefaultBrush}" Opacity="{Binding O3}" /><TextBlock Text="{Binding C3}" FontSize="12" Ho' +
    'rizontalAlignment="Center" VerticalAlignment="Center" Foreground="{ThemeResource TextOnAccentFillColorPrimaryBrush}" /></Grid>' + sLineBreak +
    '                        <Grid Grid.Column="4"><Border CornerRadius="8" Background="{ThemeResource AccentFillColorDefaultBrush}" Opacity="{Binding O4}" /><TextBlock Text="{Binding C4}" FontSize="12" Ho' +
    'rizontalAlignment="Center" VerticalAlignment="Center" Foreground="{ThemeResource TextOnAccentFillColorPrimaryBrush}" /></Grid>' + sLineBreak +
    '                        <Grid Grid.Column="5"><Border CornerRadius="8" Background="{ThemeResource AccentFillColorDefaultBrush}" Opacity="{Binding O5}" /><TextBlock Text="{Binding C5}" FontSize="12" Ho' +
    'rizontalAlignment="Center" VerticalAlignment="Center" Foreground="{ThemeResource TextOnAccentFillColorPrimaryBrush}" /></Grid>' + sLineBreak +
    '                        <Grid Grid.Column="6"><Border CornerRadius="8" Background="{ThemeResource AccentFillColorDefaultBrush}" Opacity="{Binding O6}" /><TextBlock Text="{Binding C6}" FontSize="12" Ho' +
    'rizontalAlignment="Center" VerticalAlignment="Center" Foreground="{ThemeResource TextOnAccentFillColorPrimaryBrush}" /></Grid>' + sLineBreak +
    '                      </Grid>' + sLineBreak +
    '                    </DataTemplate>' + sLineBreak +
    '                  </ItemsControl.ItemTemplate>' + sLineBreak +
    '                </ItemsControl>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <Border x:Name="CancelCard" Grid.Column="1" Style="{StaticResource Glass}">' + sLineBreak +
    '              <StackPanel Spacing="12">' + sLineBreak +
    '                <Grid>' + sLineBreak +
    '                  <TextBlock Text="Why they cancel" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                  <Border HorizontalAlignment="Right" CornerRadius="10" Padding="9,3" Background="{ThemeResource InnerBrush}">' + sLineBreak +
    '                    <TextBlock Text="Last 30 days" FontSize="11" />' + sLineBreak +
    '                  </Border>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <ItemsControl x:Name="CancelList">' + sLineBreak +
    '                  <ItemsControl.ItemTemplate>' + sLineBreak +
    '                    <DataTemplate>' + sLineBreak +
    '                      <StackPanel Spacing="6" Margin="0,6">' + sLineBreak +
    '                        <Grid>' + sLineBreak +
    '                          <TextBlock Text="{Binding Name}" FontSize="13" />' + sLineBreak +
    '                          <TextBlock Text="{Binding ValueText}" FontSize="13" HorizontalAlignment="Right" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                        </Grid>' + sLineBreak +
    '                        <Border Height="6" CornerRadius="3" Background="{ThemeResource InnerBrush}">' + sLineBreak +
    '                          <Border Height="6" CornerRadius="3" HorizontalAlignment="Left" Width="{Binding Size}" Background="{ThemeResource BadBrush}" Opacity="0.8" />' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                      </StackPanel>' + sLineBreak +
    '                    </DataTemplate>' + sLineBreak +
    '                  </ItemsControl.ItemTemplate>' + sLineBreak +
    '                </ItemsControl>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </ScrollViewer>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <ScrollViewer x:Name="PageGrowth" VerticalScrollBarVisibility="Auto" Padding="10,6,30,26" Visibility="Collapsed">' + sLineBreak +
    '        <StackPanel Spacing="20">' + sLineBreak +
    '          <Grid ColumnSpacing="24">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <StackPanel x:Name="GrTitle" VerticalAlignment="Bottom">' + sLineBreak +
    '              <TextBlock Text="Store" Style="{StaticResource PageFirst}" />' + sLineBreak +
    '              <TextBlock Text="Growth" Style="{StaticResource PageSecond}" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '            <StackPanel x:Name="GrKpis" Grid.Column="1" Orientation="Horizontal" Spacing="12" VerticalAlignment="Bottom">' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding PageViewsText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="store page views, 30 days" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding ConversionText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="page view to install" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding RegionsText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="countries with installs" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <Grid ColumnSpacing="20">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <Border x:Name="SourcesCard" Style="{StaticResource Glass}">' + sLineBreak +
    '              <StackPanel Spacing="12">' + sLineBreak +
    '                <StackPanel>' + sLineBreak +
    '                  <TextBlock Text="Acquisition sources" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                  <TextBlock Text="Where installs came from, last 30 days" Style="{StaticResource Caption}" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <ItemsControl x:Name="SourceList">' + sLineBreak +
    '                  <ItemsControl.ItemTemplate>' + sLineBreak +
    '                    <DataTemplate>' + sLineBreak +
    '                      <Grid ColumnSpacing="14" Margin="0,7">' + sLineBreak +
    '                        <Grid.ColumnDefinitions>' + sLineBreak +
    '                          <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                          <ColumnDefinition Width="*" />' + sLineBreak +
    '                        </Grid.ColumnDefinitions>' + sLineBreak +
    '                        <Border Width="38" Height="38" CornerRadius="19" Background="{ThemeResource InnerBrush}">' + sLineBreak +
    '                          <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="{Binding Glyph}" FontSize="14" />' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                        <StackPanel Grid.Column="1" Spacing="6" VerticalAlignment="Center">' + sLineBreak +
    '                          <Grid>' + sLineBreak +
    '                            <TextBlock Text="{Binding Name}" FontSize="13" />' + sLineBreak +
    '                            <TextBlock Text="{Binding ValueText}" FontSize="13" HorizontalAlignment="Right" />' + sLineBreak +
    '                          </Grid>' + sLineBreak +
    '                          <Border Height="6" CornerRadius="3" Background="{ThemeResource InnerBrush}">' + sLineBreak +
    '                            <Border Height="6" CornerRadius="3" HorizontalAlignment="Left" Width="{Binding Size}" Background="{ThemeResource AccentFillColorDefaultBrush}" />' + sLineBreak +
    '                          </Border>' + sLineBreak +
    '                        </StackPanel>' + sLineBreak +
    '                      </Grid>' + sLineBreak +
    '                    </DataTemplate>' + sLineBreak +
    '                  </ItemsControl.ItemTemplate>' + sLineBreak +
    '                </ItemsControl>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <Border x:Name="FunnelCard" Grid.Column="1" Style="{StaticResource Glass}">' + sLineBreak +
    '              <StackPanel Spacing="12">' + sLineBreak +
    '                <StackPanel>' + sLineBreak +
    '                  <TextBlock Text="Conversion funnel" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                  <TextBlock Text="From a store impression to a paying customer" Style="{StaticResource Caption}" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '                <ItemsControl x:Name="FunnelList">' + sLineBreak +
    '                  <ItemsControl.ItemTemplate>' + sLineBreak +
    '                    <DataTemplate>' + sLineBreak +
    '                      <Grid Margin="0,5" Height="46">' + sLineBreak +
    '                        <Border CornerRadius="14" HorizontalAlignment="Center" Width="{Binding Size}">' + sLineBreak +
    '                          <Border.Background>' + sLineBreak +
    '                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">' + sLineBreak +
    '                              <GradientStop Color="{ThemeResource SystemAccentColorLight2}" Offset="0" />' + sLineBreak +
    '                              <GradientStop Color="{ThemeResource SystemAccentColor}" Offset="1" />' + sLineBreak +
    '                            </LinearGradientBrush>' + sLineBreak +
    '                          </Border.Background>' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                        <Grid Padding="16,0">' + sLineBreak +
    '                          <TextBlock Text="{Binding Name}" FontSize="13" VerticalAlignment="Center" />' + sLineBreak +
    '                          <TextBlock Text="{Binding ValueText}" FontSize="13" FontWeight="SemiBold" HorizontalAlignment="Right" VerticalAlignment="Center" />' + sLineBreak +
    '                        </Grid>' + sLineBreak +
    '                      </Grid>' + sLineBreak +
    '                    </DataTemplate>' + sLineBreak +
    '                  </ItemsControl.ItemTemplate>' + sLineBreak +
    '                </ItemsControl>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <Grid ColumnSpacing="20">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <Border x:Name="RegionsCard" Style="{StaticResource Glass}">' + sLineBreak +
    '              <StackPanel Spacing="10">' + sLineBreak +
    '                <TextBlock Text="Top regions" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                <ItemsControl x:Name="RegionList">' + sLineBreak +
    '                  <ItemsControl.ItemTemplate>' + sLineBreak +
    '                    <DataTemplate>' + sLineBreak +
    '                      <Grid ColumnSpacing="12" Margin="0,6">' + sLineBreak +
    '                        <Grid.ColumnDefinitions>' + sLineBreak +
    '                          <ColumnDefinition Width="40" />' + sLineBreak +
    '                          <ColumnDefinition Width="140" />' + sLineBreak +
    '                          <ColumnDefinition Width="*" />' + sLineBreak +
    '                          <ColumnDefinition Width="80" />' + sLineBreak +
    '                        </Grid.ColumnDefinitions>' + sLineBreak +
    '                        <Border CornerRadius="8" Padding="0,3" Background="{ThemeResource InnerBrush}">' + sLineBreak +
    '                          <TextBlock Text="{Binding Glyph}" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Center" />' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                        <TextBlock Grid.Column="1" Text="{Binding Name}" FontSize="13" VerticalAlignment="Center" />' + sLineBreak +
    '                        <Border Grid.Column="2" Height="6" CornerRadius="3" Background="{ThemeResource InnerBrush}" VerticalAlignment="Center">' + sLineBreak +
    '                          <Border Height="6" CornerRadius="3" HorizontalAlignment="Left" Width="{Binding Size}" Background="{ThemeResource TealBrush}" />' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                        <TextBlock Grid.Column="3" Text="{Binding ValueText}" FontSize="13" HorizontalAlignment="Right" VerticalAlignment="Center" />' + sLineBreak +
    '                      </Grid>' + sLineBreak +
    '                    </DataTemplate>' + sLineBreak +
    '                  </ItemsControl.ItemTemplate>' + sLineBreak +
    '                </ItemsControl>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <Border x:Name="CampaignCard" Grid.Column="1" Style="{StaticResource Glass}">' + sLineBreak +
    '              <StackPanel Spacing="10">' + sLineBreak +
    '                <TextBlock Text="Campaigns" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                <ItemsControl x:Name="CampaignList">' + sLineBreak +
    '                  <ItemsControl.ItemTemplate>' + sLineBreak +
    '                    <DataTemplate>' + sLineBreak +
    '                      <Border Style="{StaticResource Inner}" Margin="0,0,0,10">' + sLineBreak +
    '                        <StackPanel Spacing="8">' + sLineBreak +
    '                          <Grid>' + sLineBreak +
    '                            <StackPanel>' + sLineBreak +
    '                              <TextBlock Text="{Binding Name}" FontSize="14" FontWeight="SemiBold" />' + sLineBreak +
    '                              <TextBlock Text="{Binding Detail}" FontSize="12" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                            </StackPanel>' + sLineBreak +
    '                            <Border HorizontalAlignment="Right" VerticalAlignment="Top" CornerRadius="10" Padding="9,3" Background="{ThemeResource GoodSoftBrush}">' + sLineBreak +
    '                              <TextBlock Text="{Binding Status}" FontSize="11" Foreground="{ThemeResource GoodBrush}" />' + sLineBreak +
    '                            </Border>' + sLineBreak +
    '                          </Grid>' + sLineBreak +
    '                          <ProgressBar Value="{Binding Progress}" Maximum="100" />' + sLineBreak +
    '                          <TextBlock Text="{Binding Value}" FontSize="12" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                        </StackPanel>' + sLineBreak +
    '                      </Border>' + sLineBreak +
    '                    </DataTemplate>' + sLineBreak +
    '                  </ItemsControl.ItemTemplate>' + sLineBreak +
    '                </ItemsControl>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </ScrollViewer>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <ScrollViewer x:Name="PagePayouts" VerticalScrollBarVisibility="Auto" Padding="10,6,30,26" Visibility="Collapsed">' + sLineBreak +
    '        <StackPanel Spacing="20">' + sLineBreak +
    '          <Grid ColumnSpacing="24">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <StackPanel x:Name="PaTitle" VerticalAlignment="Bottom">' + sLineBreak +
    '              <TextBlock Text="Your" Style="{StaticResource PageFirst}" />' + sLineBreak +
    '              <TextBlock Text="Payouts" Style="{StaticResource PageSecond}" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '            <StackPanel x:Name="PaKpis" Grid.Column="1" Orientation="Horizontal" Spacing="12" VerticalAlignment="Bottom">' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding PendingText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="pending, not yet payable" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding PaidYearText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="paid out this year" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <Grid ColumnSpacing="20">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="2*" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <StackPanel Spacing="20">' + sLineBreak +
    '              <Grid x:Name="NextPayoutCard" Height="300">' + sLineBreak +
    '                <Border CornerRadius="28">' + sLineBreak +
    '                  <Border.Background>' + sLineBreak +
    '                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">' + sLineBreak +
    '                      <GradientStop Color="{ThemeResource SystemAccentColorLight1}" Offset="0" />' + sLineBreak +
    '                      <GradientStop Color="{ThemeResource SystemAccentColor}" Offset="0.6" />' + sLineBreak +
    '                      <GradientStop Color="{ThemeResource SystemAccentColorDark2}" Offset="1" />' + sLineBreak +
    '                    </LinearGradientBrush>' + sLineBreak +
    '                  </Border.Background>' + sLineBreak +
    '                </Border>' + sLineBreak +
    '                <Border CornerRadius="28" BorderBrush="#59FFFFFF" BorderThickness="1">' + sLineBreak +
    '                  <Border.Background>' + sLineBreak +
    '                    <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">' + sLineBreak +
    '                      <GradientStop Color="#33FFFFFF" Offset="0" />' + sLineBreak +
    '                      <GradientStop Color="#00FFFFFF" Offset="0.6" />' + sLineBreak +
    '                    </LinearGradientBrush>' + sLineBreak +
    '                  </Border.Background>' + sLineBreak +
    '                </Border>' + sLineBreak +
    '                <Ellipse Width="260" Height="260" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,-80,-120" Fill="#1AFFFFFF" Stroke="#40FFFFFF" />' + sLineBreak +
    '                <Grid Padding="26,24">' + sLineBreak +
    '                  <StackPanel Spacing="6">' + sLineBreak +
    '                    <TextBlock Text="Next payout" FontSize="14" Foreground="#E6FFFFFF" />' + sLineBreak +
    '                    <TextBlock x:Name="NextPayoutLabel" Text="{Binding NextPayoutText}" FontSize="44" FontWeight="SemiBold" FontFamily="Segoe UI Variable Display" Foreground="White" />' + sLineBreak +
    '                    <TextBlock Text="Sunday 15 November, to Northwind Bank ending 4821" FontSize="12" TextWrapping="Wrap" Foreground="#CCFFFFFF" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                  <Grid HorizontalAlignment="Left" VerticalAlignment="Bottom" ColumnSpacing="14">' + sLineBreak +
    '                    <Grid.ColumnDefinitions>' + sLineBreak +
    '                      <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                      <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                    </Grid.ColumnDefinitions>' + sLineBreak +
    '                    <Grid Width="64" Height="64">' + sLineBreak +
    '                      <ProgressRing IsIndeterminate="False" Value="{Binding CycleProgress}" Maximum="100" Width="64" Height="64" Foreground="White" Background="#33FFFFFF" />' + sLineBreak +
    '                      <TextBlock Text="{Binding CycleDaysText}" FontSize="12" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center" />' + sLineBreak +
    '                    </Grid>' + sLineBreak +
    '                    <StackPanel Grid.Column="1" VerticalAlignment="Center">' + sLineBreak +
    '                      <TextBlock Text="of the payment cycle" FontSize="12" Foreground="#E6FFFFFF" />' + sLineBreak +
    '                      <TextBlock Text="Payouts are sent 45 days after month end" FontSize="11" Foreground="#B3FFFFFF" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '              <Border x:Name="SplitCard" Style="{StaticResource Glass}">' + sLineBreak +
    '                <StackPanel Spacing="10">' + sLineBreak +
    '                  <TextBlock Text="October by app" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                  <ItemsControl x:Name="SplitList">' + sLineBreak +
    '                    <ItemsControl.ItemTemplate>' + sLineBreak +
    '                      <DataTemplate>' + sLineBreak +
    '                        <Grid ColumnSpacing="12" Margin="0,6">' + sLineBreak +
    '                          <Grid.ColumnDefinitions>' + sLineBreak +
    '                            <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                            <ColumnDefinition Width="*" />' + sLineBreak +
    '                          </Grid.ColumnDefinitions>' + sLineBreak +
    '                          <Border Width="30" Height="30" CornerRadius="9" Background="{Binding Tint}">' + sLineBreak +
    '                            <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="{Binding Glyph}" FontSize="13" Foreground="White" />' + sLineBreak +
    '                          </Border>' + sLineBreak +
    '                          <StackPanel Grid.Column="1" Spacing="5">' + sLineBreak +
    '                            <Grid>' + sLineBreak +
    '                              <TextBlock Text="{Binding Name}" FontSize="13" />' + sLineBreak +
    '                              <TextBlock Text="{Binding ProceedsText}" FontSize="13" HorizontalAlignment="Right" />' + sLineBreak +
    '                            </Grid>' + sLineBreak +
    '                            <Border Height="5" CornerRadius="2.5" Background="{ThemeResource InnerBrush}">' + sLineBreak +
    '                              <Border Height="5" CornerRadius="2.5" HorizontalAlignment="Left" Width="{Binding ShareWidth}" Background="{Binding Tint}" />' + sLineBreak +
    '                            </Border>' + sLineBreak +
    '                          </StackPanel>' + sLineBreak +
    '                        </Grid>' + sLineBreak +
    '                      </DataTemplate>' + sLineBreak +
    '                    </ItemsControl.ItemTemplate>' + sLineBreak +
    '                  </ItemsControl>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '            <StackPanel Grid.Column="1" Spacing="20">' + sLineBreak +
    '            <Border x:Name="HistoryCard" Style="{StaticResource Glass}" VerticalAlignment="Top">' + sLineBreak +
    '              <StackPanel Spacing="6">' + sLineBreak +
    '                <Grid Margin="0,0,0,10">' + sLineBreak +
    '                  <TextBlock Text="Payout history" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                  <Button x:Name="StatementButton" HorizontalAlignment="Right" CornerRadius="16" Padding="14,6" Background="{ThemeResource InnerBrush}" BorderBrush="{ThemeResource InnerRimBrush}">' + sLineBreak +
    '                    <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                      <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="12" />' + sLineBreak +
    '                      <TextBlock Text="Statement" FontSize="12" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                  </Button>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <Grid Padding="0,0,0,8" BorderBrush="{ThemeResource LineBrush}" BorderThickness="0,0,0,1">' + sLineBreak +
    '                  <Grid.ColumnDefinitions>' + sLineBreak +
    '                    <ColumnDefinition Width="1.4*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="*" />' + sLineBreak +
    '                    <ColumnDefinition Width="100" />' + sLineBreak +
    '                  </Grid.ColumnDefinitions>' + sLineBreak +
    '                  <TextBlock Text="Month" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  <TextBlock Grid.Column="1" Text="Units" Style="{StaticResource Caption}" HorizontalAlignment="Right" />' + sLineBreak +
    '                  <TextBlock Grid.Column="2" Text="Gross" Style="{StaticResource Caption}" HorizontalAlignment="Right" />' + sLineBreak +
    '                  <TextBlock Grid.Column="3" Text="Store fee" Style="{StaticResource Caption}" HorizontalAlignment="Right" />' + sLineBreak +
    '                  <TextBlock Grid.Column="4" Text="Net" Style="{StaticResource Caption}" HorizontalAlignment="Right" />' + sLineBreak +
    '                  <TextBlock Grid.Column="5" Text="Status" Style="{StaticResource Caption}" HorizontalAlignment="Right" />' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <ItemsControl x:Name="PayoutList">' + sLineBreak +
    '                  <ItemsControl.ItemContainerTransitions>' + sLineBreak +
    '                    <TransitionCollection><EntranceThemeTransition IsStaggeringEnabled="True" /></TransitionCollection>' + sLineBreak +
    '                  </ItemsControl.ItemContainerTransitions>' + sLineBreak +
    '                  <ItemsControl.ItemTemplate>' + sLineBreak +
    '                    <DataTemplate>' + sLineBreak +
    '                      <Grid Padding="0,12" BorderBrush="{ThemeResource LineBrush}" BorderThickness="0,0,0,1">' + sLineBreak +
    '                        <Grid.ColumnDefinitions>' + sLineBreak +
    '                          <ColumnDefinition Width="1.4*" />' + sLineBreak +
    '                          <ColumnDefinition Width="*" />' + sLineBreak +
    '                          <ColumnDefinition Width="*" />' + sLineBreak +
    '                          <ColumnDefinition Width="*" />' + sLineBreak +
    '                          <ColumnDefinition Width="*" />' + sLineBreak +
    '                          <ColumnDefinition Width="100" />' + sLineBreak +
    '                        </Grid.ColumnDefinitions>' + sLineBreak +
    '                        <TextBlock Text="{Binding Month}" FontSize="13" FontWeight="SemiBold" />' + sLineBreak +
    '                        <TextBlock Grid.Column="1" Text="{Binding Units}" FontSize="13" HorizontalAlignment="Right" />' + sLineBreak +
    '                        <TextBlock Grid.Column="2" Text="{Binding Gross}" FontSize="13" HorizontalAlignment="Right" />' + sLineBreak +
    '                        <TextBlock Grid.Column="3" Text="{Binding Fees}" FontSize="13" HorizontalAlignment="Right" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                        <TextBlock Grid.Column="4" Text="{Binding Net}" FontSize="13" FontWeight="SemiBold" HorizontalAlignment="Right" />' + sLineBreak +
    '                        <Border Grid.Column="5" HorizontalAlignment="Right" CornerRadius="10" Padding="9,2" Background="{ThemeResource GoodSoftBrush}" Visibility="{Binding Paid, Converter={StaticResou' +
    'rce BoolToVisibility}}">' + sLineBreak +
    '                          <TextBlock Text="Paid" FontSize="11" Foreground="{ThemeResource GoodBrush}" />' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                        <Border Grid.Column="5" HorizontalAlignment="Right" CornerRadius="10" Padding="9,2" Background="{ThemeResource WarnSoftBrush}" Visibility="{Binding Paid, Converter={StaticResou' +
    'rce InverseBoolToVisibility}}">' + sLineBreak +
    '                          <TextBlock Text="Scheduled" FontSize="11" Foreground="{ThemeResource WarnBrush}" />' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                      </Grid>' + sLineBreak +
    '                    </DataTemplate>' + sLineBreak +
    '                  </ItemsControl.ItemTemplate>' + sLineBreak +
    '                </ItemsControl>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '            <Grid x:Name="AccountRow" ColumnSpacing="20">' + sLineBreak +
    '              <Grid.ColumnDefinitions>' + sLineBreak +
    '                <ColumnDefinition Width="*" />' + sLineBreak +
    '                <ColumnDefinition Width="*" />' + sLineBreak +
    '              </Grid.ColumnDefinitions>' + sLineBreak +
    '              <Border Style="{StaticResource Glass}">' + sLineBreak +
    '                <StackPanel Spacing="12">' + sLineBreak +
    '                  <TextBlock Text="Payout account" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                  <Grid ColumnSpacing="14">' + sLineBreak +
    '                    <Grid.ColumnDefinitions>' + sLineBreak +
    '                      <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                      <ColumnDefinition Width="*" />' + sLineBreak +
    '                    </Grid.ColumnDefinitions>' + sLineBreak +
    '                    <Border Width="58" Height="40" CornerRadius="9" Background="{ThemeResource AvatarBrush}">' + sLineBreak +
    '                      <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="18" Foreground="{ThemeResource AvatarTextBrush}" />' + sLineBreak +
    '                    </Border>' + sLineBreak +
    '                    <StackPanel Grid.Column="1" VerticalAlignment="Center">' + sLineBreak +
    '                      <TextBlock Text="Northwind Bank" FontSize="14" FontWeight="SemiBold" />' + sLineBreak +
    '                      <TextBlock Text="Business account ending 4821, US dollars" Style="{StaticResource Caption}" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                  <ToggleSwitch x:Name="InstantSwitch" Header="Send payouts as soon as they clear" IsOn="True" />' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Grid.Column="1" Style="{StaticResource Glass}">' + sLineBreak +
    '                <StackPanel Spacing="10">' + sLineBreak +
    '                  <TextBlock Text="Tax and compliance" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                  <Grid>' + sLineBreak +
    '                    <TextBlock Text="W-8BEN tax form" FontSize="13" />' + sLineBreak +
    '                    <Border HorizontalAlignment="Right" CornerRadius="10" Padding="9,2" Background="{ThemeResource GoodSoftBrush}">' + sLineBreak +
    '                      <TextBlock Text="Valid until 2028" FontSize="11" Foreground="{ThemeResource GoodBrush}" />' + sLineBreak +
    '                    </Border>' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                  <Grid>' + sLineBreak +
    '                    <TextBlock Text="VAT registration" FontSize="13" />' + sLineBreak +
    '                    <Border HorizontalAlignment="Right" CornerRadius="10" Padding="9,2" Background="{ThemeResource GoodSoftBrush}">' + sLineBreak +
    '                      <TextBlock Text="Verified" FontSize="11" Foreground="{ThemeResource GoodBrush}" />' + sLineBreak +
    '                    </Border>' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                  <Grid>' + sLineBreak +
    '                    <TextBlock Text="Store agreement" FontSize="13" />' + sLineBreak +
    '                    <Border HorizontalAlignment="Right" CornerRadius="10" Padding="9,2" Background="{ThemeResource WarnSoftBrush}">' + sLineBreak +
    '                      <TextBlock Text="Renew in 21 days" FontSize="11" Foreground="{ThemeResource WarnBrush}" />' + sLineBreak +
    '                    </Border>' + sLineBreak +
    '                  </Grid>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '            </Grid>' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </ScrollViewer>' + sLineBreak +
    '' + sLineBreak +
    '      ' + sLineBreak +
    '      <ScrollViewer x:Name="PageTeam" VerticalScrollBarVisibility="Auto" Padding="10,6,30,26" Visibility="Collapsed">' + sLineBreak +
    '        <StackPanel Spacing="20">' + sLineBreak +
    '          <Grid ColumnSpacing="24">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="Auto" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <StackPanel x:Name="TeTitle" VerticalAlignment="Bottom">' + sLineBreak +
    '              <TextBlock Text="Your" Style="{StaticResource PageFirst}" />' + sLineBreak +
    '              <TextBlock Text="Team" Style="{StaticResource PageSecond}" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '            <StackPanel x:Name="TeKpis" Grid.Column="1" Orientation="Horizontal" Spacing="12" VerticalAlignment="Bottom">' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="16" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock x:Name="MembersLabel" Text="{Binding MembersText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="members" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Border Style="{StaticResource Kpi}">' + sLineBreak +
    '                <StackPanel Orientation="Horizontal" Spacing="12">' + sLineBreak +
    '                  <Border Style="{StaticResource IconDisc}"><Ellipse Width="12" Height="12" Fill="{ThemeResource GoodBrush}" /></Border>' + sLineBreak +
    '                  <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '                    <TextBlock Text="{Binding OnlineText}" Style="{StaticResource KpiValue}" />' + sLineBreak +
    '                    <TextBlock Text="online now" Style="{StaticResource Caption}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </StackPanel>' + sLineBreak +
    '              </Border>' + sLineBreak +
    '              <Grid VerticalAlignment="Center">' + sLineBreak +
    '                <Border CornerRadius="24" Margin="-6" Opacity="0.55">' + sLineBreak +
    '                  <Border.Background>' + sLineBreak +
    '                    <RadialGradientBrush>' + sLineBreak +
    '                      <GradientStop Color="{ThemeResource SystemAccentColor}" Offset="0" />' + sLineBreak +
    '                      <GradientStop Color="Transparent" Offset="1" />' + sLineBreak +
    '                    </RadialGradientBrush>' + sLineBreak +
    '                  </Border.Background>' + sLineBreak +
    '                </Border>' + sLineBreak +
    '                <Button x:Name="InviteButton" Style="{StaticResource Accent}">' + sLineBreak +
    '                  <StackPanel Orientation="Horizontal" Spacing="8">' + sLineBreak +
    '                    <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="" FontSize="12" />' + sLineBreak +
    '                    <TextBlock Text="Invite" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </Button>' + sLineBreak +
    '              </Grid>' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '          <Grid ColumnSpacing="20">' + sLineBreak +
    '            <Grid.ColumnDefinitions>' + sLineBreak +
    '              <ColumnDefinition Width="*" />' + sLineBreak +
    '              <ColumnDefinition Width="380" />' + sLineBreak +
    '            </Grid.ColumnDefinitions>' + sLineBreak +
    '            <GridView x:Name="TeamGrid" SelectionMode="None" ItemContainerStyle="{StaticResource BareGrid}">' + sLineBreak +
    '              <GridView.ItemContainerTransitions>' + sLineBreak +
    '                <TransitionCollection>' + sLineBreak +
    '                  <EntranceThemeTransition IsStaggeringEnabled="True" FromVerticalOffset="50" />' + sLineBreak +
    '                  <AddDeleteThemeTransition />' + sLineBreak +
    '                  <RepositionThemeTransition />' + sLineBreak +
    '                </TransitionCollection>' + sLineBreak +
    '              </GridView.ItemContainerTransitions>' + sLineBreak +
    '              <GridView.ItemTemplate>' + sLineBreak +
    '                <DataTemplate>' + sLineBreak +
    '                  <Border Width="268" Padding="20" CornerRadius="26" Background="{ThemeResource GlassBrush}" BorderBrush="{ThemeResource GlassRimBrush}" BorderThickness="1">' + sLineBreak +
    '                    <StackPanel Spacing="12">' + sLineBreak +
    '                      <Grid>' + sLineBreak +
    '                        <Grid Width="60" Height="60" HorizontalAlignment="Left">' + sLineBreak +
    '                          <Ellipse Fill="{Binding Tint}" />' + sLineBreak +
    '                          <Ellipse>' + sLineBreak +
    '                            <Ellipse.Fill>' + sLineBreak +
    '                              <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">' + sLineBreak +
    '                                <GradientStop Color="#4DFFFFFF" Offset="0" />' + sLineBreak +
    '                                <GradientStop Color="#00FFFFFF" Offset="0.6" />' + sLineBreak +
    '                              </LinearGradientBrush>' + sLineBreak +
    '                            </Ellipse.Fill>' + sLineBreak +
    '                          </Ellipse>' + sLineBreak +
    '                          <TextBlock Text="{Binding Initials}" FontSize="19" FontWeight="SemiBold" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center" />' + sLineBreak +
    '                          <Ellipse Width="14" Height="14" HorizontalAlignment="Right" VerticalAlignment="Bottom" Fill="{ThemeResource GoodBrush}" Stroke="{ThemeResource GlassRimBrush}" StrokeThickness' +
    '="2" Visibility="{Binding Online, Converter={StaticResource BoolToVisibility}}" />' + sLineBreak +
    '                        </Grid>' + sLineBreak +
    '                        <Border HorizontalAlignment="Right" VerticalAlignment="Top" CornerRadius="10" Padding="9,3" Background="{ThemeResource InnerBrush}">' + sLineBreak +
    '                          <TextBlock Text="{Binding Access}" FontSize="11" />' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                      </Grid>' + sLineBreak +
    '                      <StackPanel>' + sLineBreak +
    '                        <TextBlock Text="{Binding Name}" FontSize="16" FontWeight="SemiBold" />' + sLineBreak +
    '                        <TextBlock Text="{Binding Role}" FontSize="12" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                      </StackPanel>' + sLineBreak +
    '                      <Border Style="{StaticResource Inner}" Padding="12,8">' + sLineBreak +
    '                        <StackPanel Spacing="2">' + sLineBreak +
    '                          <TextBlock Text="Looks after" FontSize="11" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                          <TextBlock Text="{Binding Apps}" FontSize="12" TextTrimming="CharacterEllipsis" />' + sLineBreak +
    '                        </StackPanel>' + sLineBreak +
    '                      </Border>' + sLineBreak +
    '                      <TextBlock Text="{Binding Status}" FontSize="11" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                    </StackPanel>' + sLineBreak +
    '                  </Border>' + sLineBreak +
    '                </DataTemplate>' + sLineBreak +
    '              </GridView.ItemTemplate>' + sLineBreak +
    '            </GridView>' + sLineBreak +
    '            <Border x:Name="ActivityCard" Grid.Column="1" Style="{StaticResource Glass}" VerticalAlignment="Top">' + sLineBreak +
    '              <StackPanel Spacing="10">' + sLineBreak +
    '                <Grid>' + sLineBreak +
    '                  <TextBlock Text="Activity" Style="{StaticResource CardTitle}" />' + sLineBreak +
    '                  <StackPanel Orientation="Horizontal" Spacing="6" HorizontalAlignment="Right" VerticalAlignment="Center">' + sLineBreak +
    '                    <Ellipse Width="7" Height="7" Fill="{ThemeResource GoodBrush}" />' + sLineBreak +
    '                    <TextBlock Text="Live" FontSize="11" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                  </StackPanel>' + sLineBreak +
    '                </Grid>' + sLineBreak +
    '                <ItemsControl x:Name="ActivityList">' + sLineBreak +
    '                  <ItemsControl.ItemContainerTransitions>' + sLineBreak +
    '                    <TransitionCollection><AddDeleteThemeTransition /><RepositionThemeTransition /></TransitionCollection>' + sLineBreak +
    '                  </ItemsControl.ItemContainerTransitions>' + sLineBreak +
    '                  <ItemsControl.ItemTemplate>' + sLineBreak +
    '                    <DataTemplate>' + sLineBreak +
    '                      <Grid Padding="0,9" ColumnSpacing="12">' + sLineBreak +
    '                        <Grid.ColumnDefinitions>' + sLineBreak +
    '                          <ColumnDefinition Width="Auto" />' + sLineBreak +
    '                          <ColumnDefinition Width="*" />' + sLineBreak +
    '                        </Grid.ColumnDefinitions>' + sLineBreak +
    '                        <Border Width="34" Height="34" CornerRadius="17" Background="{ThemeResource InnerBrush}">' + sLineBreak +
    '                          <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="{Binding Glyph}" FontSize="13" />' + sLineBreak +
    '                        </Border>' + sLineBreak +
    '                        <StackPanel Grid.Column="1">' + sLineBreak +
    '                          <TextBlock Text="{Binding Title}" FontSize="13" TextWrapping="Wrap" />' + sLineBreak +
    '                          <TextBlock Text="{Binding Time}" FontSize="11" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '                        </StackPanel>' + sLineBreak +
    '                      </Grid>' + sLineBreak +
    '                    </DataTemplate>' + sLineBreak +
    '                  </ItemsControl.ItemTemplate>' + sLineBreak +
    '                </ItemsControl>' + sLineBreak +
    '              </StackPanel>' + sLineBreak +
    '            </Border>' + sLineBreak +
    '          </Grid>' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </ScrollViewer>' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '' + sLineBreak +
    '    ' + sLineBreak +
    '    <Border x:Name="Toast" Grid.Row="1" Grid.Column="1" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,30,26" Width="340" Padding="16,12" CornerRadius="20" Background="{ThemeResour' +
    'ce GlassStrongBrush}" BorderBrush="{ThemeResource GlassRimBrush}" BorderThickness="1" IsHitTestVisible="False">' + sLineBreak +
    '      <Grid ColumnSpacing="12">' + sLineBreak +
    '        <Grid.ColumnDefinitions>' + sLineBreak +
    '          <ColumnDefinition Width="Auto" />' + sLineBreak +
    '          <ColumnDefinition Width="*" />' + sLineBreak +
    '        </Grid.ColumnDefinitions>' + sLineBreak +
    '        <Grid Width="36" Height="36">' + sLineBreak +
    '          <Ellipse Fill="{ThemeResource AccentFillColorDefaultBrush}" />' + sLineBreak +
    '          <FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="{Binding ToastGlyph}" FontSize="14" Foreground="{ThemeResource TextOnAccentFillColorPrimaryBrush}" />' + sLineBreak +
    '        </Grid>' + sLineBreak +
    '        <StackPanel Grid.Column="1" VerticalAlignment="Center">' + sLineBreak +
    '          <TextBlock x:Name="ToastTitleLabel" Text="{Binding ToastTitle}" FontSize="13" FontWeight="SemiBold" />' + sLineBreak +
    '          <TextBlock Text="{Binding ToastBody}" FontSize="12" TextWrapping="Wrap" Foreground="{ThemeResource MutedBrush}" />' + sLineBreak +
    '        </StackPanel>' + sLineBreak +
    '      </Grid>' + sLineBreak +
    '    </Border>' + sLineBreak +
    '  </Grid>' + sLineBreak;

constructor TMainWindowBase.Create;
begin
  inherited;
  // MainWindow.xaml(1): <Window> attributes
  Title := 'Lucent - app publishing studio';
  Width := 1640;
  Height := 1020;
  MinWidth := 1180;
  MinHeight := 720;
  Backdrop := TWinUIBackdrop.Acrylic;
  ExtendsContentIntoTitleBar := True;
  Center;
  LoadContent(ContentXaml);
  // x:Name elements
  Surface := FindElement<TWinUIGrid>('Surface');
  SolidBase := FindElement<TWinUIBorder>('SolidBase');
  Orb1 := FindElement<TWinUIEllipse>('Orb1');
  Orb2 := FindElement<TWinUIEllipse>('Orb2');
  Ribbon1 := FindElement<TWinUICanvas>('Ribbon1');
  Ribbon2 := FindElement<TWinUICanvas>('Ribbon2');
  Ribbon3 := FindElement<TWinUICanvas>('Ribbon3');
  Bubble1 := FindElement<TWinUIEllipse>('Bubble1');
  Bubble2 := FindElement<TWinUIEllipse>('Bubble2');
  Bubble3 := FindElement<TWinUIEllipse>('Bubble3');
  Bubble4 := FindElement<TWinUIEllipse>('Bubble4');
  Bubble5 := FindElement<TWinUIEllipse>('Bubble5');
  Bubble6 := FindElement<TWinUIEllipse>('Bubble6');
  Bubble7 := FindElement<TWinUIEllipse>('Bubble7');
  Bubble8 := FindElement<TWinUIEllipse>('Bubble8');
  Bubble9 := FindElement<TWinUIEllipse>('Bubble9');
  Bubble10 := FindElement<TWinUIEllipse>('Bubble10');
  Bubble11 := FindElement<TWinUIEllipse>('Bubble11');
  Bubble12 := FindElement<TWinUIEllipse>('Bubble12');
  DragRegion := FindElement<TWinUIGrid>('DragRegion');
  NavIndicator := FindElement<TWinUIBorder>('NavIndicator');
  NavBar := FindElement<TWinUIStackPanel>('NavBar');
  NavOverview := FindElement<TWinUIButton>('NavOverview');
  NavApps := FindElement<TWinUIButton>('NavApps');
  NavReleases := FindElement<TWinUIButton>('NavReleases');
  NavReviews := FindElement<TWinUIButton>('NavReviews');
  NavAudience := FindElement<TWinUIButton>('NavAudience');
  NavGrowth := FindElement<TWinUIButton>('NavGrowth');
  NavPayouts := FindElement<TWinUIButton>('NavPayouts');
  NavTeam := FindElement<TWinUIButton>('NavTeam');
  InboxButton := FindElement<TWinUIButton>('InboxButton');
  InboxList := FindElement<TWinUIItemsControl>('InboxList');
  BellButton := FindElement<TWinUIButton>('BellButton');
  NoticeList := FindElement<TWinUIItemsControl>('NoticeList');
  BellDot := FindElement<TWinUIEllipse>('BellDot');
  AvatarButton := FindElement<TWinUIButton>('AvatarButton');
  MenuTheme := FindElement<TWinUIMenuFlyoutItem>('MenuTheme');
  MenuTeam := FindElement<TWinUIMenuFlyoutItem>('MenuTeam');
  RailSearch := FindElement<TWinUIButton>('RailSearch');
  RailNew := FindElement<TWinUIButton>('RailNew');
  RailCalendar := FindElement<TWinUIButton>('RailCalendar');
  ReleaseCalendar := FindElement<TWinUICalendarView>('ReleaseCalendar');
  RailUndo := FindElement<TWinUIButton>('RailUndo');
  RailShare := FindElement<TWinUIButton>('RailShare');
  RailUpload := FindElement<TWinUIButton>('RailUpload');
  RailSettings := FindElement<TWinUIButton>('RailSettings');
  LiveSwitch := FindElement<TWinUIToggleSwitch>('LiveSwitch');
  MotionSwitch := FindElement<TWinUIToggleSwitch>('MotionSwitch');
  TransparencySwitch := FindElement<TWinUIToggleSwitch>('TransparencySwitch');
  RailTheme := FindElement<TWinUIButton>('RailTheme');
  ThemeGlyph := FindElement<TWinUIFontIcon>('ThemeGlyph');
  LiveButton := FindElement<TWinUIButton>('LiveButton');
  LivePulse := FindElement<TWinUIEllipse>('LivePulse');
  PageHost := FindElement<TWinUIGrid>('PageHost');
  PageOverview := FindElement<TWinUIScrollViewer>('PageOverview');
  OvTitle := FindElement<TWinUIStackPanel>('OvTitle');
  OvKpis := FindElement<TWinUIStackPanel>('OvKpis');
  OvProceedsLabel := FindElement<TWinUITextBlock>('OvProceedsLabel');
  ProceedsColumn := FindElement<TWinUIColumnDefinition>('ProceedsColumn');
  RatingsColumn := FindElement<TWinUIColumnDefinition>('RatingsColumn');
  ProceedsCard := FindElement<TWinUIBorder>('ProceedsCard');
  ChartTitle := FindElement<TWinUITextBlock>('ChartTitle');
  SeriesProceeds := FindElement<TWinUIToggleButton>('SeriesProceeds');
  SeriesDownloads := FindElement<TWinUIToggleButton>('SeriesDownloads');
  MenuExportChart := FindElement<TWinUIMenuFlyoutItem>('MenuExportChart');
  MenuLastYear := FindElement<TWinUIToggleMenuFlyoutItem>('MenuLastYear');
  ExpandButton := FindElement<TWinUIButton>('ExpandButton');
  ExpandGlyph := FindElement<TWinUIFontIcon>('ExpandGlyph');
  ProceedsCanvas := FindElement<TWinUICanvas>('ProceedsCanvas');
  ProceedsArea := FindElement<TWinUIPolygon>('ProceedsArea');
  ProceedsLastYear := FindElement<TWinUIPolyline>('ProceedsLastYear');
  ProceedsLine := FindElement<TWinUIPolyline>('ProceedsLine');
  ProceedsGlow := FindElement<TWinUIEllipse>('ProceedsGlow');
  ProceedsDot := FindElement<TWinUIEllipse>('ProceedsDot');
  RatingsCard := FindElement<TWinUIBorder>('RatingsCard');
  StarBarList := FindElement<TWinUIItemsControl>('StarBarList');
  YourAppsCard := FindElement<TWinUIBorder>('YourAppsCard');
  AllAppsButton := FindElement<TWinUIButton>('AllAppsButton');
  OverviewApps := FindElement<TWinUIGridView>('OverviewApps');
  PageApps := FindElement<TWinUIScrollViewer>('PageApps');
  ApTitle := FindElement<TWinUIStackPanel>('ApTitle');
  ApKpis := FindElement<TWinUIStackPanel>('ApKpis');
  ApToolbar := FindElement<TWinUIGrid>('ApToolbar');
  AppSearch := FindElement<TWinUITextBox>('AppSearch');
  SortProceeds := FindElement<TWinUIToggleButton>('SortProceeds');
  SortDownloads := FindElement<TWinUIToggleButton>('SortDownloads');
  SortRating := FindElement<TWinUIToggleButton>('SortRating');
  AppGrid := FindElement<TWinUIGridView>('AppGrid');
  NoAppsText := FindElement<TWinUITextBlock>('NoAppsText');
  PageDetail := FindElement<TWinUIScrollViewer>('PageDetail');
  BackButton := FindElement<TWinUIButton>('BackButton');
  DeTitle := FindElement<TWinUIStackPanel>('DeTitle');
  DetailNameLabel := FindElement<TWinUITextBlock>('DetailNameLabel');
  DeKpis := FindElement<TWinUIStackPanel>('DeKpis');
  DetailHero := FindElement<TWinUIGrid>('DetailHero');
  DetailSparkCanvas := FindElement<TWinUICanvas>('DetailSparkCanvas');
  DetailSpark := FindElement<TWinUIPolyline>('DetailSpark');
  DetailTabs := FindElement<TWinUIStackPanel>('DetailTabs');
  DetailTabOverview := FindElement<TWinUIToggleButton>('DetailTabOverview');
  DetailTabVersions := FindElement<TWinUIToggleButton>('DetailTabVersions');
  DetailTabIap := FindElement<TWinUIToggleButton>('DetailTabIap');
  DetailTabReviews := FindElement<TWinUIToggleButton>('DetailTabReviews');
  DetailBody := FindElement<TWinUIGrid>('DetailBody');
  DetailOverview := FindElement<TWinUIGrid>('DetailOverview');
  DetailCanvas := FindElement<TWinUICanvas>('DetailCanvas');
  DetailArea := FindElement<TWinUIPolygon>('DetailArea');
  DetailLine := FindElement<TWinUIPolyline>('DetailLine');
  DetailBars := FindElement<TWinUIItemsControl>('DetailBars');
  DetailVersions := FindElement<TWinUIBorder>('DetailVersions');
  VersionList := FindElement<TWinUIItemsControl>('VersionList');
  DetailIap := FindElement<TWinUIBorder>('DetailIap');
  IapList := FindElement<TWinUIItemsControl>('IapList');
  DetailReviews := FindElement<TWinUIBorder>('DetailReviews');
  DetailReviewList := FindElement<TWinUIItemsControl>('DetailReviewList');
  PageReleases := FindElement<TWinUIScrollViewer>('PageReleases');
  ReTitle := FindElement<TWinUIStackPanel>('ReTitle');
  ReKpis := FindElement<TWinUIStackPanel>('ReKpis');
  InFlightLabel := FindElement<TWinUITextBlock>('InFlightLabel');
  ReToolbar := FindElement<TWinUIGrid>('ReToolbar');
  NewReleaseButton := FindElement<TWinUIButton>('NewReleaseButton');
  FilterAll := FindElement<TWinUIToggleButton>('FilterAll');
  Filter0 := FindElement<TWinUIToggleButton>('Filter0');
  Filter1 := FindElement<TWinUIToggleButton>('Filter1');
  Filter2 := FindElement<TWinUIToggleButton>('Filter2');
  Filter3 := FindElement<TWinUIToggleButton>('Filter3');
  Filter4 := FindElement<TWinUIToggleButton>('Filter4');
  Filter5 := FindElement<TWinUIToggleButton>('Filter5');
  ViewBoard := FindElement<TWinUIToggleButton>('ViewBoard');
  ViewTimeline := FindElement<TWinUIToggleButton>('ViewTimeline');
  BoardCard := FindElement<TWinUIBorder>('BoardCard');
  Column0 := FindElement<TWinUIListView>('Column0');
  Column1 := FindElement<TWinUIListView>('Column1');
  Column2 := FindElement<TWinUIListView>('Column2');
  Column3 := FindElement<TWinUIListView>('Column3');
  Column4 := FindElement<TWinUIListView>('Column4');
  TimelineCard := FindElement<TWinUIBorder>('TimelineCard');
  TimelineList := FindElement<TWinUIItemsControl>('TimelineList');
  PageReviews := FindElement<TWinUIScrollViewer>('PageReviews');
  RvTitle := FindElement<TWinUIStackPanel>('RvTitle');
  RvKpis := FindElement<TWinUIStackPanel>('RvKpis');
  WrittenLabel := FindElement<TWinUITextBlock>('WrittenLabel');
  RvSummary := FindElement<TWinUIBorder>('RvSummary');
  ReviewBars := FindElement<TWinUIItemsControl>('ReviewBars');
  RvList := FindElement<TWinUIStackPanel>('RvList');
  StarsAll := FindElement<TWinUIToggleButton>('StarsAll');
  Stars5 := FindElement<TWinUIToggleButton>('Stars5');
  Stars4 := FindElement<TWinUIToggleButton>('Stars4');
  Stars3 := FindElement<TWinUIToggleButton>('Stars3');
  Stars2 := FindElement<TWinUIToggleButton>('Stars2');
  Stars1 := FindElement<TWinUIToggleButton>('Stars1');
  ReviewAppBox := FindElement<TWinUIComboBox>('ReviewAppBox');
  ReviewList := FindElement<TWinUIListView>('ReviewList');
  PageAudience := FindElement<TWinUIScrollViewer>('PageAudience');
  AuTitle := FindElement<TWinUIStackPanel>('AuTitle');
  AuKpis := FindElement<TWinUIStackPanel>('AuKpis');
  AuFilters := FindElement<TWinUIStackPanel>('AuFilters');
  AudAll := FindElement<TWinUIToggleButton>('AudAll');
  Aud0 := FindElement<TWinUIToggleButton>('Aud0');
  Aud1 := FindElement<TWinUIToggleButton>('Aud1');
  Aud2 := FindElement<TWinUIToggleButton>('Aud2');
  Aud3 := FindElement<TWinUIToggleButton>('Aud3');
  Aud4 := FindElement<TWinUIToggleButton>('Aud4');
  Aud5 := FindElement<TWinUIToggleButton>('Aud5');
  SubsCard := FindElement<TWinUIBorder>('SubsCard');
  SubsCanvas := FindElement<TWinUICanvas>('SubsCanvas');
  SubsArea := FindElement<TWinUIPolygon>('SubsArea');
  TrialLine := FindElement<TWinUIPolyline>('TrialLine');
  SubsLine := FindElement<TWinUIPolyline>('SubsLine');
  SubsHover := FindElement<TWinUIGrid>('SubsHover');
  SubsGuide := FindElement<TWinUIRectangle>('SubsGuide');
  SubsDot := FindElement<TWinUIEllipse>('SubsDot');
  TrialDot := FindElement<TWinUIEllipse>('TrialDot');
  SubsTip := FindElement<TWinUIBorder>('SubsTip');
  TipMonth := FindElement<TWinUITextBlock>('TipMonth');
  TipSubs := FindElement<TWinUITextBlock>('TipSubs');
  TipTrial := FindElement<TWinUITextBlock>('TipTrial');
  PlansCard := FindElement<TWinUIBorder>('PlansCard');
  Donut := FindElement<TWinUIGrid>('Donut');
  PlanArc0 := FindElement<TWinUIEllipse>('PlanArc0');
  PlanArc1 := FindElement<TWinUIEllipse>('PlanArc1');
  PlanArc2 := FindElement<TWinUIEllipse>('PlanArc2');
  CohortCard := FindElement<TWinUIBorder>('CohortCard');
  ExportCsvButton := FindElement<TWinUIButton>('ExportCsvButton');
  CohortList := FindElement<TWinUIItemsControl>('CohortList');
  CancelCard := FindElement<TWinUIBorder>('CancelCard');
  CancelList := FindElement<TWinUIItemsControl>('CancelList');
  PageGrowth := FindElement<TWinUIScrollViewer>('PageGrowth');
  GrTitle := FindElement<TWinUIStackPanel>('GrTitle');
  GrKpis := FindElement<TWinUIStackPanel>('GrKpis');
  SourcesCard := FindElement<TWinUIBorder>('SourcesCard');
  SourceList := FindElement<TWinUIItemsControl>('SourceList');
  FunnelCard := FindElement<TWinUIBorder>('FunnelCard');
  FunnelList := FindElement<TWinUIItemsControl>('FunnelList');
  RegionsCard := FindElement<TWinUIBorder>('RegionsCard');
  RegionList := FindElement<TWinUIItemsControl>('RegionList');
  CampaignCard := FindElement<TWinUIBorder>('CampaignCard');
  CampaignList := FindElement<TWinUIItemsControl>('CampaignList');
  PagePayouts := FindElement<TWinUIScrollViewer>('PagePayouts');
  PaTitle := FindElement<TWinUIStackPanel>('PaTitle');
  PaKpis := FindElement<TWinUIStackPanel>('PaKpis');
  NextPayoutCard := FindElement<TWinUIGrid>('NextPayoutCard');
  NextPayoutLabel := FindElement<TWinUITextBlock>('NextPayoutLabel');
  SplitCard := FindElement<TWinUIBorder>('SplitCard');
  SplitList := FindElement<TWinUIItemsControl>('SplitList');
  HistoryCard := FindElement<TWinUIBorder>('HistoryCard');
  StatementButton := FindElement<TWinUIButton>('StatementButton');
  PayoutList := FindElement<TWinUIItemsControl>('PayoutList');
  AccountRow := FindElement<TWinUIGrid>('AccountRow');
  InstantSwitch := FindElement<TWinUIToggleSwitch>('InstantSwitch');
  PageTeam := FindElement<TWinUIScrollViewer>('PageTeam');
  TeTitle := FindElement<TWinUIStackPanel>('TeTitle');
  TeKpis := FindElement<TWinUIStackPanel>('TeKpis');
  MembersLabel := FindElement<TWinUITextBlock>('MembersLabel');
  InviteButton := FindElement<TWinUIButton>('InviteButton');
  TeamGrid := FindElement<TWinUIGridView>('TeamGrid');
  ActivityCard := FindElement<TWinUIBorder>('ActivityCard');
  ActivityList := FindElement<TWinUIItemsControl>('ActivityList');
  Toast := FindElement<TWinUIBorder>('Toast');
  ToastTitleLabel := FindElement<TWinUITextBlock>('ToastTitleLabel');
  // Event wiring
  // MainWindow.xaml(13): SizeChanged="SurfaceSizeChanged"
  Surface.OnSizeChanged := TWinUISizeChangedEventHandler(PublishedMethod('SurfaceSizeChanged'));
  // MainWindow.xaml(13): SurfaceLoaded by name
  Surface.OnLoaded := TWinUIRoutedEventHandler(PublishedMethod('SurfaceLoaded'));
  // MainWindow.xaml(348): Click="NavClick"
  NavOverview.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('NavClick'));
  // MainWindow.xaml(349): Click="NavClick"
  NavApps.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('NavClick'));
  // MainWindow.xaml(350): Click="NavClick"
  NavReleases.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('NavClick'));
  // MainWindow.xaml(351): Click="NavClick"
  NavReviews.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('NavClick'));
  // MainWindow.xaml(352): Click="NavClick"
  NavAudience.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('NavClick'));
  // MainWindow.xaml(353): Click="NavClick"
  NavGrowth.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('NavClick'));
  // MainWindow.xaml(354): Click="NavClick"
  NavPayouts.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('NavClick'));
  // MainWindow.xaml(355): Click="NavClick"
  NavTeam.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('NavClick'));
  // MainWindow.xaml(392): Click="BellClick"
  BellButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('BellClick'));
  // MainWindow.xaml(432): Click="ThemeClick"
  MenuTheme.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ThemeClick'));
  // MainWindow.xaml(437): Click="MenuTeamClick"
  MenuTeam.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('MenuTeamClick'));
  // MainWindow.xaml(453): Click="RailSearchClick"
  RailSearch.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RailSearchClick'));
  // MainWindow.xaml(456): Click="RailNewClick"
  RailNew.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RailNewClick'));
  // MainWindow.xaml(472): Click="RailUndoClick"
  RailUndo.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RailUndoClick'));
  // MainWindow.xaml(475): Click="RailShareClick"
  RailShare.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RailShareClick'));
  // MainWindow.xaml(478): Click="RailUploadClick"
  RailUpload.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RailUploadClick'));
  // MainWindow.xaml(489): MotionSwitchToggled by name
  MotionSwitch.Toggled.Add(NotifyProc<TWinUIRoutedEventArgs>('MotionSwitchToggled'));
  // MainWindow.xaml(490): TransparencySwitchToggled by name
  TransparencySwitch.Toggled.Add(NotifyProc<TWinUIRoutedEventArgs>('TransparencySwitchToggled'));
  // MainWindow.xaml(495): Click="ThemeClick"
  RailTheme.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ThemeClick'));
  // MainWindow.xaml(500): Click="LiveClick"
  LiveButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('LiveClick'));
  // MainWindow.xaml(590): Click="SeriesClick"
  SeriesProceeds.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('SeriesClick'));
  // MainWindow.xaml(591): Click="SeriesClick"
  SeriesDownloads.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('SeriesClick'));
  // MainWindow.xaml(598): Click="ExportChartClick"
  MenuExportChart.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ExportChartClick'));
  // MainWindow.xaml(599): Click="LastYearClick"
  MenuLastYear.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('LastYearClick'));
  // MainWindow.xaml(603): Click="ExpandClick"
  ExpandButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ExpandClick'));
  // MainWindow.xaml(622): SizeChanged="ChartSizeChanged"
  ProceedsCanvas.OnSizeChanged := TWinUISizeChangedEventHandler(PublishedMethod('ChartSizeChanged'));
  // MainWindow.xaml(723): Click="RailNewClick"
  FindElement<TWinUIButton>('_rw1').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RailNewClick'));
  // MainWindow.xaml(726): Click="AllAppsClick"
  AllAppsButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('AllAppsClick'));
  // MainWindow.xaml(730): ItemClick="AppClick"
  OverviewApps.OnItemClick := TWinUIItemClickEventHandler(PublishedMethod('AppClick'));
  // MainWindow.xaml(827): TextChanged="AppSearchChanged"
  AppSearch.OnTextChanged := TWinUITextChangedEventHandler(PublishedMethod('AppSearchChanged'));
  // MainWindow.xaml(831): Click="SortClick"
  SortProceeds.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('SortClick'));
  // MainWindow.xaml(832): Click="SortClick"
  SortDownloads.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('SortClick'));
  // MainWindow.xaml(833): Click="SortClick"
  SortRating.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('SortClick'));
  // MainWindow.xaml(836): ItemClick="AppClick"
  AppGrid.OnItemClick := TWinUIItemClickEventHandler(PublishedMethod('AppClick'));
  // MainWindow.xaml(937): Click="BackClick"
  BackButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('BackClick'));
  // MainWindow.xaml(1016): Click="DetailTabClick"
  DetailTabOverview.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('DetailTabClick'));
  // MainWindow.xaml(1017): Click="DetailTabClick"
  DetailTabVersions.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('DetailTabClick'));
  // MainWindow.xaml(1018): Click="DetailTabClick"
  DetailTabIap.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('DetailTabClick'));
  // MainWindow.xaml(1019): Click="DetailTabClick"
  DetailTabReviews.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('DetailTabClick'));
  // MainWindow.xaml(1041): SizeChanged="ChartSizeChanged"
  DetailCanvas.OnSizeChanged := TWinUISizeChangedEventHandler(PublishedMethod('ChartSizeChanged'));
  // MainWindow.xaml(1204): Click="RailNewClick"
  NewReleaseButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('RailNewClick'));
  // MainWindow.xaml(1212): Click="FilterClick"
  FilterAll.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('FilterClick'));
  // MainWindow.xaml(1213): Click="FilterClick"
  Filter0.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('FilterClick'));
  // MainWindow.xaml(1214): Click="FilterClick"
  Filter1.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('FilterClick'));
  // MainWindow.xaml(1215): Click="FilterClick"
  Filter2.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('FilterClick'));
  // MainWindow.xaml(1216): Click="FilterClick"
  Filter3.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('FilterClick'));
  // MainWindow.xaml(1217): Click="FilterClick"
  Filter4.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('FilterClick'));
  // MainWindow.xaml(1218): Click="FilterClick"
  Filter5.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('FilterClick'));
  // MainWindow.xaml(1222): Click="ViewClick"
  ViewBoard.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ViewClick'));
  // MainWindow.xaml(1228): Click="ViewClick"
  ViewTimeline.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ViewClick'));
  // MainWindow.xaml(1260): Click="ColumnAddClick"
  FindElement<TWinUIButton>('_rw2').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ColumnAddClick'));
  // MainWindow.xaml(1264): DragItemsCompleted="BoardDragCompleted"
  Column0.OnDragItemsCompleted := TWinUIDragItemsCompletedEventHandler(PublishedMethod('BoardDragCompleted'));
  // MainWindow.xaml(1264): DragItemsStarting="BoardDragStarting"
  Column0.OnDragItemsStarting := TWinUIDragItemsStartingEventHandler(PublishedMethod('BoardDragStarting'));
  // MainWindow.xaml(1264): DragOver="BoardDragOver"
  Column0.OnDragOver := TWinUIDragEventHandler(PublishedMethod('BoardDragOver'));
  // MainWindow.xaml(1264): Drop="BoardDrop"
  Column0.OnDrop := TWinUIDragEventHandler(PublishedMethod('BoardDrop'));
  // MainWindow.xaml(1281): Click="ColumnAddClick"
  FindElement<TWinUIButton>('_rw3').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ColumnAddClick'));
  // MainWindow.xaml(1285): DragItemsCompleted="BoardDragCompleted"
  Column1.OnDragItemsCompleted := TWinUIDragItemsCompletedEventHandler(PublishedMethod('BoardDragCompleted'));
  // MainWindow.xaml(1285): DragItemsStarting="BoardDragStarting"
  Column1.OnDragItemsStarting := TWinUIDragItemsStartingEventHandler(PublishedMethod('BoardDragStarting'));
  // MainWindow.xaml(1285): DragOver="BoardDragOver"
  Column1.OnDragOver := TWinUIDragEventHandler(PublishedMethod('BoardDragOver'));
  // MainWindow.xaml(1285): Drop="BoardDrop"
  Column1.OnDrop := TWinUIDragEventHandler(PublishedMethod('BoardDrop'));
  // MainWindow.xaml(1302): Click="ColumnAddClick"
  FindElement<TWinUIButton>('_rw4').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ColumnAddClick'));
  // MainWindow.xaml(1306): DragItemsCompleted="BoardDragCompleted"
  Column2.OnDragItemsCompleted := TWinUIDragItemsCompletedEventHandler(PublishedMethod('BoardDragCompleted'));
  // MainWindow.xaml(1306): DragItemsStarting="BoardDragStarting"
  Column2.OnDragItemsStarting := TWinUIDragItemsStartingEventHandler(PublishedMethod('BoardDragStarting'));
  // MainWindow.xaml(1306): DragOver="BoardDragOver"
  Column2.OnDragOver := TWinUIDragEventHandler(PublishedMethod('BoardDragOver'));
  // MainWindow.xaml(1306): Drop="BoardDrop"
  Column2.OnDrop := TWinUIDragEventHandler(PublishedMethod('BoardDrop'));
  // MainWindow.xaml(1323): Click="ColumnAddClick"
  FindElement<TWinUIButton>('_rw5').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ColumnAddClick'));
  // MainWindow.xaml(1327): DragItemsCompleted="BoardDragCompleted"
  Column3.OnDragItemsCompleted := TWinUIDragItemsCompletedEventHandler(PublishedMethod('BoardDragCompleted'));
  // MainWindow.xaml(1327): DragItemsStarting="BoardDragStarting"
  Column3.OnDragItemsStarting := TWinUIDragItemsStartingEventHandler(PublishedMethod('BoardDragStarting'));
  // MainWindow.xaml(1327): DragOver="BoardDragOver"
  Column3.OnDragOver := TWinUIDragEventHandler(PublishedMethod('BoardDragOver'));
  // MainWindow.xaml(1327): Drop="BoardDrop"
  Column3.OnDrop := TWinUIDragEventHandler(PublishedMethod('BoardDrop'));
  // MainWindow.xaml(1344): Click="ColumnAddClick"
  FindElement<TWinUIButton>('_rw6').Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ColumnAddClick'));
  // MainWindow.xaml(1348): DragItemsCompleted="BoardDragCompleted"
  Column4.OnDragItemsCompleted := TWinUIDragItemsCompletedEventHandler(PublishedMethod('BoardDragCompleted'));
  // MainWindow.xaml(1348): DragItemsStarting="BoardDragStarting"
  Column4.OnDragItemsStarting := TWinUIDragItemsStartingEventHandler(PublishedMethod('BoardDragStarting'));
  // MainWindow.xaml(1348): DragOver="BoardDragOver"
  Column4.OnDragOver := TWinUIDragEventHandler(PublishedMethod('BoardDragOver'));
  // MainWindow.xaml(1348): Drop="BoardDrop"
  Column4.OnDrop := TWinUIDragEventHandler(PublishedMethod('BoardDrop'));
  // MainWindow.xaml(1496): Click="StarsClick"
  StarsAll.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('StarsClick'));
  // MainWindow.xaml(1497): Click="StarsClick"
  Stars5.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('StarsClick'));
  // MainWindow.xaml(1498): Click="StarsClick"
  Stars4.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('StarsClick'));
  // MainWindow.xaml(1499): Click="StarsClick"
  Stars3.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('StarsClick'));
  // MainWindow.xaml(1500): Click="StarsClick"
  Stars2.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('StarsClick'));
  // MainWindow.xaml(1501): Click="StarsClick"
  Stars1.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('StarsClick'));
  // MainWindow.xaml(1503): SelectionChanged="ReviewAppChanged"
  ReviewAppBox.OnSelectionChanged := TWinUISelectionChangedEventHandler(PublishedMethod('ReviewAppChanged'));
  // MainWindow.xaml(1506): ItemClick="ReviewClick"
  ReviewList.OnItemClick := TWinUIItemClickEventHandler(PublishedMethod('ReviewClick'));
  // MainWindow.xaml(1601): Click="AudienceFilterClick"
  AudAll.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('AudienceFilterClick'));
  // MainWindow.xaml(1602): Click="AudienceFilterClick"
  Aud0.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('AudienceFilterClick'));
  // MainWindow.xaml(1603): Click="AudienceFilterClick"
  Aud1.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('AudienceFilterClick'));
  // MainWindow.xaml(1604): Click="AudienceFilterClick"
  Aud2.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('AudienceFilterClick'));
  // MainWindow.xaml(1605): Click="AudienceFilterClick"
  Aud3.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('AudienceFilterClick'));
  // MainWindow.xaml(1606): Click="AudienceFilterClick"
  Aud4.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('AudienceFilterClick'));
  // MainWindow.xaml(1607): Click="AudienceFilterClick"
  Aud5.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('AudienceFilterClick'));
  // MainWindow.xaml(1654): SizeChanged="ChartSizeChanged"
  SubsCanvas.OnSizeChanged := TWinUISizeChangedEventHandler(PublishedMethod('ChartSizeChanged'));
  // MainWindow.xaml(1666): PointerExited="SubsPointerExited"
  SubsHover.OnPointerExited := TWinUIPointerRoutedEventHandler(PublishedMethod('SubsPointerExited'));
  // MainWindow.xaml(1666): PointerMoved="SubsPointerMoved"
  SubsHover.OnPointerMoved := TWinUIPointerRoutedEventHandler(PublishedMethod('SubsPointerMoved'));
  // MainWindow.xaml(1771): Click="ExportCsvClick"
  ExportCsvButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('ExportCsvClick'));
  // MainWindow.xaml(2130): Click="StatementClick"
  StatementButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('StatementClick'));
  // MainWindow.xaml(2279): Click="InviteClick"
  InviteButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('InviteClick'));
end;

procedure TMainWindowBase.SetViewModel(AValue: TMainViewModel);
begin
  FViewModel := AValue;
  DataContext := AValue;
end;

end.
