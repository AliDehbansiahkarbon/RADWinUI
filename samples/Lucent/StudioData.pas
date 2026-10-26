unit StudioData;

{ The items Lucent shows: apps, releases, reviews, team members, payouts and
  chart rows. Each is a bindable object, its published properties are what the
  XAML templates bind to. All names and numbers are made up. }

interface

uses
  RADWinUI.Binding,
  RADWinUI.Xaml;

type
  { Solid brushes for the app colours, shared by every item that shows them. }
  TBrushes = class
  strict private
    FColors: TArray<Cardinal>;
    FBrushes: TArray<TWinUISolidColorBrush>;
  public
    destructor Destroy; override;
    { $AARRGGBB }
    function Get(AColor: Cardinal): TWinUISolidColorBrush;
  end;

  TStudioApp = class(TWinUIBindableObject)
  private
    FName, FTagline, FGlyph, FCategory, FPricing, FVersion, FSteward: string;
    FColor: Cardinal;
    FRating: Double;
    FRatingCount: Integer;
    FDownloads, FDownloadsDelta: Double;
    FProceeds, FCrashFree: Double;
    FInReview: Boolean;
    FShare: Double;
    function GetTint: TWinUISolidColorBrush;
    function GetVersionText: string;
    function GetStarsText: string;
    function GetRatingText: string;
    function GetRatingChip: string;
    function GetRatingCountText: string;
    function GetDownloadsText: string;
    function GetDeltaText: string;
    function GetFalling: Boolean;
    function GetProceedsText: string;
    function GetCrashFreeText: string;
    function GetProceeds12Text: string;
    function GetProceedsCaption: string;
    function GetSpark(AIndex: Integer): Double;
    function GetShareWidth: Double;
  public
    Months: array[0..11] of Double; // proceeds, November to October
    Days: array[0..6] of Double;    // downloads, the last seven days
    Stars: array[1..5] of Double;   // share of ratings per star
    constructor Create(const AName, ATagline, AGlyph, ACategory, APricing, AVersion, ASteward: string;
      AColor: Cardinal; ARating: Double; ARatingCount: Integer; ADownloads, ADelta, AProceeds, ACrashFree: Double);
    { Updates the bindings of the named properties. }
    procedure Notify(const ANames: array of string);
    procedure AddProceeds(AValue: Double);
    procedure AddDownloads(AValue: Double);
    procedure AddRating(AStars: Integer);
    function Proceeds12: Double;
    property Color: Cardinal read FColor;
    property Rating: Double read FRating;
    property Proceeds: Double read FProceeds;
    property Downloads: Double read FDownloads;
    property RatingCount: Integer read FRatingCount write FRatingCount;
    property Share: Double read FShare write FShare;
  published
    property Name: string read FName;
    property Tagline: string read FTagline;
    property Glyph: string read FGlyph;
    property Category: string read FCategory;
    property Pricing: string read FPricing;
    property Steward: string read FSteward;
    property InReview: Boolean read FInReview write FInReview;
    property Tint: TWinUISolidColorBrush read GetTint;
    property VersionText: string read GetVersionText;
    property StarsText: string read GetStarsText;
    property RatingText: string read GetRatingText;
    property RatingChip: string read GetRatingChip;
    property RatingCountText: string read GetRatingCountText;
    property DownloadsText: string read GetDownloadsText;
    property DeltaText: string read GetDeltaText;
    property Falling: Boolean read GetFalling;
    property ProceedsText: string read GetProceedsText;
    property CrashFreeText: string read GetCrashFreeText;
    property Proceeds12Text: string read GetProceeds12Text;
    property ProceedsCaption: string read GetProceedsCaption;
    property ShareWidth: Double read GetShareWidth;
    property Spark1: Double index 0 read GetSpark;
    property Spark2: Double index 1 read GetSpark;
    property Spark3: Double index 2 read GetSpark;
    property Spark4: Double index 3 read GetSpark;
    property Spark5: Double index 4 read GetSpark;
    property Spark6: Double index 5 read GetSpark;
    property Spark7: Double index 6 read GetSpark;
  end;

  { A build on the release board. Stage 0 is In development, 4 is Live. }
  TRelease = class(TWinUIBindableObject)
  private
    FApp: TStudioApp;
    FVersion, FNotes, FOwner: string;
    FBuild, FTesters, FAge, FStage: Integer;
    FCrashFree: Double;
    FCurrent: Boolean;
    function GetTint: TWinUISolidColorBrush;
    function GetGlyph: string;
    function GetTitle: string;
    function GetBuildText: string;
    function GetTested: Boolean;
    function GetHealthBrush: TWinUISolidColorBrush;
    function GetCrashText: string;
    function GetAgeText: string;
    function GetTestersText: string;
    function GetTrackWidth: Double;
    function GetStep(AIndex: Integer): Double;
  public
    constructor Create(AApp: TStudioApp; const AVersion, ANotes, AOwner: string; ABuild, AStage, AAge, ATesters: Integer;
      ACrashFree: Double);
    { Moves the build to AStage, Live makes it the app's current version. }
    procedure MoveTo(AStage: Integer);
    { No longer the app's live version. }
    procedure Retire;
    property App: TStudioApp read FApp;
    property Stage: Integer read FStage;
    property Version: string read FVersion;
  published
    property Tint: TWinUISolidColorBrush read GetTint;
    property Glyph: string read GetGlyph;
    property Title: string read GetTitle;
    property BuildText: string read GetBuildText;
    property Notes: string read FNotes;
    property Tested: Boolean read GetTested;
    property CrashFree: Double read FCrashFree;
    property HealthBrush: TWinUISolidColorBrush read GetHealthBrush;
    property CrashText: string read GetCrashText;
    property Owner: string read FOwner;
    property AgeText: string read GetAgeText;
    property Current: Boolean read FCurrent;
    property TestersText: string read GetTestersText;
    property TrackWidth: Double read GetTrackWidth;
    property Step0: Double index 0 read GetStep;
    property Step1: Double index 1 read GetStep;
    property Step2: Double index 2 read GetStep;
    property Step3: Double index 3 read GetStep;
    property Step4: Double index 4 read GetStep;
  end;

  TReview = class(TWinUIBindableObject)
  private
    FApp: TStudioApp;
    FStars: Integer;
    FTitle, FBody, FAuthor, FWhen, FReplyText: string;
    FReplied: Boolean;
    function GetTint: TWinUISolidColorBrush;
    function GetGlyph: string;
    function GetAppName: string;
    function GetStarsText: string;
    function GetMeta: string;
  public
    constructor Create(AApp: TStudioApp; AStars: Integer; const ATitle, ABody, AAuthor, AWhen: string);
    procedure Reply;
    property App: TStudioApp read FApp;
    property Stars: Integer read FStars;
  published
    property Tint: TWinUISolidColorBrush read GetTint;
    property Glyph: string read GetGlyph;
    property AppName: string read GetAppName;
    property StarsText: string read GetStarsText;
    property Title: string read FTitle;
    property Body: string read FBody;
    property Meta: string read GetMeta;
    property Replied: Boolean read FReplied;
    property ReplyText: string read FReplyText;
  end;

  { A row with a name, a value and a bar of Size pixels. }
  TBar = class(TWinUIBindableObject)
  private
    FName, FValueText, FGlyph: string;
    FSize: Double;
  public
    constructor Create(const AName, AValueText: string; ASize: Double; const AGlyph: string = '');
    procedure Update(const AValueText: string; ASize: Double);
  published
    property Name: string read FName;
    property ValueText: string read FValueText;
    property Size: Double read FSize;
    property Glyph: string read FGlyph;
  end;

  { A table row: versions, in-app purchases, campaigns. }
  TListRow = class(TWinUIBindableObject)
  private
    FName, FDetail, FValue, FStatus: string;
    FProgress: Double;
  public
    constructor Create(const AName, ADetail, AValue, AStatus: string; AProgress: Double = 0);
    procedure SetProgress(AValue: Double; const AText: string);
  published
    property Name: string read FName;
    property Detail: string read FDetail;
    property Value: string read FValue;
    property Status: string read FStatus;
    property Progress: Double read FProgress;
  end;

  TNotice = class(TWinUIBindableObject)
  private
    FGlyph, FTitle, FBody, FTime: string;
  public
    constructor Create(const AGlyph, ATitle, ABody, ATime: string);
  published
    property Glyph: string read FGlyph;
    property Title: string read FTitle;
    property Body: string read FBody;
    property Time: string read FTime;
  end;

  TCohort = class(TWinUIBindableObject)
  private
    FName, FSizeText: string;
    FValues: array[0..5] of Double; // -1 for months not reached yet
    function GetCell(AIndex: Integer): string;
    function GetOpacity(AIndex: Integer): Double;
  public
    constructor Create(const AName, ASizeText: string; const AValues: array of Double);
    function CsvLine: string;
  published
    property Name: string read FName;
    property SizeText: string read FSizeText;
    property C1: string index 0 read GetCell;
    property C2: string index 1 read GetCell;
    property C3: string index 2 read GetCell;
    property C4: string index 3 read GetCell;
    property C5: string index 4 read GetCell;
    property C6: string index 5 read GetCell;
    property O1: Double index 0 read GetOpacity;
    property O2: Double index 1 read GetOpacity;
    property O3: Double index 2 read GetOpacity;
    property O4: Double index 3 read GetOpacity;
    property O5: Double index 4 read GetOpacity;
    property O6: Double index 5 read GetOpacity;
  end;

  TPayout = class(TWinUIBindableObject)
  private
    FMonth: string;
    FUnits: Integer;
    FGross: Double;
    FPaid: Boolean;
    function GetUnits: string;
    function GetGross: string;
    function GetFees: string;
    function GetNet: string;
  public
    constructor Create(const AMonth: string; AUnits: Integer; AGross: Double; APaid: Boolean);
    procedure Add(AUnits: Integer; AGross: Double);
    function NetValue: Double;
  published
    property Month: string read FMonth;
    property Units: string read GetUnits;
    property Gross: string read GetGross;
    property Fees: string read GetFees;
    property Net: string read GetNet;
    property Paid: Boolean read FPaid;
  end;

  TMember = class(TWinUIBindableObject)
  private
    FName, FRole, FAccess, FApps, FStatus: string;
    FColor: Cardinal;
    FOnline: Boolean;
    function GetTint: TWinUISolidColorBrush;
    function GetInitials: string;
  public
    constructor Create(const AName, ARole, AAccess, AApps: string; AColor: Cardinal; AOnline: Boolean; const AStatus: string);
    procedure SetOnline(AValue: Boolean; const AStatus: string);
    property IsOnline: Boolean read FOnline;
  published
    property Name: string read FName;
    property Role: string read FRole;
    property Access: string read FAccess;
    property Apps: string read FApps;
    property Status: string read FStatus;
    property Online: Boolean read FOnline;
    property Tint: TWinUISolidColorBrush read GetTint;
    property Initials: string read GetInitials;
  end;

var
  Brushes: TBrushes;

{ $10,937 }
function Money(AValue: Double): string;
{ 44.9K, 1.2M }
function Compact(AValue: Double): string;
{ 12,408 }
function Count(AValue: Double): string;
{ ★★★★☆ }
function StarText(ARating: Double): string;

implementation

uses
  System.SysUtils,
  System.Math;

var
  UsFormat: TFormatSettings;

function Money(AValue: Double): string;
begin
  Result := '$' + FormatFloat('#,##0', AValue, UsFormat);
end;

function Compact(AValue: Double): string;
begin
  if Abs(AValue) >= 1000000 then
    Result := FormatFloat('0.0#', AValue / 1000000, UsFormat) + 'M'
  else if Abs(AValue) >= 1000 then
    Result := FormatFloat('0.0', AValue / 1000, UsFormat) + 'K'
  else
    Result := FormatFloat('0', AValue, UsFormat);
end;

function Count(AValue: Double): string;
begin
  Result := FormatFloat('#,##0', AValue, UsFormat);
end;

function StarText(ARating: Double): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to 5 do
    if I <= Round(ARating) then
      Result := Result + #$2605
    else
      Result := Result + #$2606;
end;

function ColorOf(AValue: Cardinal): TWinUIColor;
begin
  Result.A := AValue shr 24;
  Result.R := (AValue shr 16) and $FF;
  Result.G := (AValue shr 8) and $FF;
  Result.B := AValue and $FF;
end;

{ TBrushes }

destructor TBrushes.Destroy;
var
  Brush: TWinUISolidColorBrush;
begin
  for Brush in FBrushes do
    Brush.Free;
  inherited;
end;

function TBrushes.Get(AColor: Cardinal): TWinUISolidColorBrush;
var
  I: Integer;
begin
  for I := 0 to High(FColors) do
    if FColors[I] = AColor then
      Exit(FBrushes[I]);
  Result := TWinUISolidColorBrush.Create(nil);
  Result.Color := ColorOf(AColor);
  FColors := FColors + [AColor];
  FBrushes := FBrushes + [Result];
end;

{ TStudioApp }

constructor TStudioApp.Create(const AName, ATagline, AGlyph, ACategory, APricing, AVersion, ASteward: string;
  AColor: Cardinal; ARating: Double; ARatingCount: Integer; ADownloads, ADelta, AProceeds, ACrashFree: Double);
begin
  inherited Create;
  FName := AName;
  FTagline := ATagline;
  FGlyph := AGlyph;
  FCategory := ACategory;
  FPricing := APricing;
  FVersion := AVersion;
  FSteward := ASteward;
  FColor := AColor;
  FRating := ARating;
  FRatingCount := ARatingCount;
  FDownloads := ADownloads;
  FDownloadsDelta := ADelta;
  FProceeds := AProceeds;
  FCrashFree := ACrashFree;
end;

procedure TStudioApp.Notify(const ANames: array of string);
var
  Name: string;
begin
  for Name in ANames do
    Changed(Name);
end;

procedure TStudioApp.AddProceeds(AValue: Double);
begin
  FProceeds := FProceeds + AValue;
  Months[11] := Months[11] + AValue;
end;

procedure TStudioApp.AddDownloads(AValue: Double);
begin
  FDownloads := FDownloads + AValue;
  Days[6] := Days[6] + AValue;
end;

procedure TStudioApp.AddRating(AStars: Integer);
begin
  FRating := (FRating * FRatingCount + AStars) / (FRatingCount + 1);
  Inc(FRatingCount);
end;

function TStudioApp.Proceeds12: Double;
begin
  Result := Sum(Months);
end;

function TStudioApp.GetTint: TWinUISolidColorBrush;
begin
  Result := Brushes.Get(FColor);
end;

function TStudioApp.GetVersionText: string;
begin
  Result := 'v' + FVersion;
end;

function TStudioApp.GetStarsText: string;
begin
  Result := StarText(FRating);
end;

function TStudioApp.GetRatingText: string;
begin
  Result := FormatFloat('0.0', FRating, UsFormat);
end;

function TStudioApp.GetRatingChip: string;
begin
  Result := #$2605' ' + GetRatingText;
end;

function TStudioApp.GetRatingCountText: string;
begin
  Result := '(' + Count(FRatingCount) + ')';
end;

function TStudioApp.GetDownloadsText: string;
begin
  Result := Compact(FDownloads);
end;

function TStudioApp.GetDeltaText: string;
begin
  if FDownloadsDelta < 0 then
    Result := #$25BC' ' + FormatFloat('0', -FDownloadsDelta, UsFormat) + '% this week'
  else
    Result := #$25B2' ' + FormatFloat('0', FDownloadsDelta, UsFormat) + '% this week';
end;

function TStudioApp.GetFalling: Boolean;
begin
  Result := FDownloadsDelta < 0;
end;

function TStudioApp.GetProceedsText: string;
begin
  Result := Money(FProceeds);
end;

function TStudioApp.GetCrashFreeText: string;
begin
  Result := FormatFloat('0.00', FCrashFree, UsFormat) + '%';
end;

function TStudioApp.GetProceeds12Text: string;
begin
  Result := '$' + Compact(Proceeds12);
end;

function TStudioApp.GetProceedsCaption: string;
begin
  Result := Money(Proceeds12) + ' in the last 12 months';
end;

function TStudioApp.GetSpark(AIndex: Integer): Double;
var
  Low, High: Double;
begin
  // Stretch the week between its quietest and busiest day, so the bars show the rhythm
  Low := MinValue(Days) * 0.8;
  High := Max(Low + 1, MaxValue(Days));
  Result := 8 + 46 * (Days[AIndex] - Low) / (High - Low);
end;

function TStudioApp.GetShareWidth: Double;
begin
  // The payouts split: the best seller's bar is about 380 px wide
  Result := 12 * FShare;
end;

{ TRelease }

constructor TRelease.Create(AApp: TStudioApp; const AVersion, ANotes, AOwner: string;
  ABuild, AStage, AAge, ATesters: Integer; ACrashFree: Double);
begin
  inherited Create;
  FApp := AApp;
  FVersion := AVersion;
  FNotes := ANotes;
  FOwner := AOwner;
  FBuild := ABuild;
  FStage := AStage;
  FAge := AAge;
  FTesters := ATesters;
  FCrashFree := ACrashFree;
  FCurrent := AStage = 4;
end;

procedure TRelease.MoveTo(AStage: Integer);
begin
  FStage := AStage;
  FAge := 0;
  // A build gets its first crash-free figure once testers have it
  if (AStage >= 1) and (FCrashFree = 0) then
  begin
    FCrashFree := 98.4 + Random * 1.4;
    FTesters := 120 + Random(900);
  end;
  FCurrent := AStage = 4;
  Changed;
end;

procedure TRelease.Retire;
begin
  FCurrent := False;
  Changed;
end;

function TRelease.GetTint: TWinUISolidColorBrush;
begin
  Result := FApp.Tint;
end;

function TRelease.GetGlyph: string;
begin
  Result := FApp.Glyph;
end;

function TRelease.GetTitle: string;
begin
  Result := FApp.Name + ' ' + FVersion;
end;

function TRelease.GetBuildText: string;
begin
  Result := 'Build ' + IntToStr(FBuild);
end;

function TRelease.GetTested: Boolean;
begin
  Result := FCrashFree > 0;
end;

function TRelease.GetHealthBrush: TWinUISolidColorBrush;
begin
  if FCrashFree >= 99 then
    Result := Brushes.Get($FF3FC98A)
  else
    Result := Brushes.Get($FFF2B648);
end;

function TRelease.GetCrashText: string;
begin
  Result := FormatFloat('0.0', FCrashFree, UsFormat) + '% crash-free';
end;

function TRelease.GetAgeText: string;
begin
  if FAge = 0 then
    Result := 'just now'
  else
    Result := IntToStr(FAge) + ' d ago';
end;

function TRelease.GetTestersText: string;
begin
  Result := Count(FTesters);
end;

function TRelease.GetTrackWidth: Double;
begin
  // The timeline track: five equal steps, measured in the template's width
  Result := FStage * 150;
end;

function TRelease.GetStep(AIndex: Integer): Double;
begin
  if AIndex <= FStage then
    Result := 1
  else
    Result := 0.18;
end;

{ TReview }

constructor TReview.Create(AApp: TStudioApp; AStars: Integer; const ATitle, ABody, AAuthor, AWhen: string);
begin
  inherited Create;
  FApp := AApp;
  FStars := AStars;
  FTitle := ATitle;
  FBody := ABody;
  FAuthor := AAuthor;
  FWhen := AWhen;
end;

procedure TReview.Reply;
begin
  if FReplied then
    Exit;
  FReplied := True;
  if FStars >= 4 then
    FReplyText := 'You replied: Thank you, that means a lot to the team!'
  else
    FReplyText := 'You replied: Sorry about this, a fix is in the next build. Thanks for telling us.';
  Changed;
end;

function TReview.GetTint: TWinUISolidColorBrush;
begin
  Result := FApp.Tint;
end;

function TReview.GetGlyph: string;
begin
  Result := FApp.Glyph;
end;

function TReview.GetAppName: string;
begin
  Result := FApp.Name;
end;

function TReview.GetStarsText: string;
begin
  Result := StarText(FStars);
end;

function TReview.GetMeta: string;
begin
  Result := FAuthor + ', ' + FWhen;
end;

{ TBar }

constructor TBar.Create(const AName, AValueText: string; ASize: Double; const AGlyph: string);
begin
  inherited Create;
  FName := AName;
  FValueText := AValueText;
  FSize := ASize;
  FGlyph := AGlyph;
end;

procedure TBar.Update(const AValueText: string; ASize: Double);
begin
  FValueText := AValueText;
  FSize := ASize;
  Changed;
end;

{ TListRow }

constructor TListRow.Create(const AName, ADetail, AValue, AStatus: string; AProgress: Double);
begin
  inherited Create;
  FName := AName;
  FDetail := ADetail;
  FValue := AValue;
  FStatus := AStatus;
  FProgress := AProgress;
end;

procedure TListRow.SetProgress(AValue: Double; const AText: string);
begin
  FProgress := AValue;
  FValue := AText;
  Changed;
end;

{ TNotice }

constructor TNotice.Create(const AGlyph, ATitle, ABody, ATime: string);
begin
  inherited Create;
  FGlyph := AGlyph;
  FTitle := ATitle;
  FBody := ABody;
  FTime := ATime;
end;

{ TCohort }

constructor TCohort.Create(const AName, ASizeText: string; const AValues: array of Double);
var
  I: Integer;
begin
  inherited Create;
  FName := AName;
  FSizeText := ASizeText;
  for I := 0 to High(FValues) do
    if I <= High(AValues) then
      FValues[I] := AValues[I]
    else
      FValues[I] := -1;
end;

function TCohort.GetCell(AIndex: Integer): string;
begin
  if FValues[AIndex] < 0 then
    Result := ''
  else
    Result := FormatFloat('0', FValues[AIndex], UsFormat) + '%';
end;

function TCohort.GetOpacity(AIndex: Integer): Double;
begin
  if FValues[AIndex] < 0 then
    Result := 0
  else
    Result := 0.25 + 0.75 * Sqr(FValues[AIndex] / 100);
end;

function TCohort.CsvLine: string;
var
  I: Integer;
begin
  Result := FName + ',' + StringReplace(FSizeText, ',', '', [rfReplaceAll]);
  for I := 0 to High(FValues) do
    if FValues[I] < 0 then
      Result := Result + ','
    else
      Result := Result + ',' + FormatFloat('0', FValues[I], UsFormat);
end;

{ TPayout }

const
  StoreFee = 0.15;

constructor TPayout.Create(const AMonth: string; AUnits: Integer; AGross: Double; APaid: Boolean);
begin
  inherited Create;
  FMonth := AMonth;
  FUnits := AUnits;
  FGross := AGross;
  FPaid := APaid;
end;

procedure TPayout.Add(AUnits: Integer; AGross: Double);
begin
  Inc(FUnits, AUnits);
  FGross := FGross + AGross;
  Changed;
end;

function TPayout.NetValue: Double;
begin
  Result := FGross * (1 - StoreFee);
end;

function TPayout.GetUnits: string;
begin
  Result := Count(FUnits);
end;

function TPayout.GetGross: string;
begin
  Result := Money(FGross);
end;

function TPayout.GetFees: string;
begin
  Result := '-' + Money(FGross * StoreFee);
end;

function TPayout.GetNet: string;
begin
  Result := Money(NetValue);
end;

{ TMember }

constructor TMember.Create(const AName, ARole, AAccess, AApps: string; AColor: Cardinal; AOnline: Boolean;
  const AStatus: string);
begin
  inherited Create;
  FName := AName;
  FRole := ARole;
  FAccess := AAccess;
  FApps := AApps;
  FColor := AColor;
  FOnline := AOnline;
  FStatus := AStatus;
end;

procedure TMember.SetOnline(AValue: Boolean; const AStatus: string);
begin
  FOnline := AValue;
  FStatus := AStatus;
  Changed;
end;

function TMember.GetTint: TWinUISolidColorBrush;
begin
  Result := Brushes.Get(FColor);
end;

function TMember.GetInitials: string;
var
  Space: Integer;
begin
  Space := Pos(' ', FName);
  Result := Copy(FName, 1, 1);
  if Space > 0 then
    Result := Result + Copy(FName, Space + 1, 1);
end;

initialization
  UsFormat := TFormatSettings.Create('en-US');
  UsFormat.ThousandSeparator := ',';
  UsFormat.DecimalSeparator := '.';
end.
