unit MainWindow;

interface

uses
  System.SysUtils,
  System.Classes,
  RADWinUI.Forms,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Dialogs,
  RADWinUI.Binding,
  MainWindow.Xaml;

type
  // One suggestion of the search box: a cafe or a coffee
  {$M+}
  TSuggestion = class
  private
    FName, FKind, FGlyph: string;
  public
    constructor Create(const AName, AKind, AGlyph: string);
    function ToString: string; override;
  published
    property Name: string read FName;
    property Kind: string read FKind;
    property Glyph: string read FGlyph;
  end;
  {$M-}

  TMainWindow = class(TMainWindowBase)   // TMainWindowBase is generated from MainWindow.xaml
  private
    FMini: TWinUIWindow;
    FSuggestions: TWinUIBindableList<TSuggestion>;
    procedure Search(const AText: string);
    procedure Suggest(const AText: string);
    procedure RoastChanged(Sender: TObject);
    procedure RoastFinished(Sender: TObject);
    procedure HandleActivation(const AActivation: TWinUIActivation);
  public
    constructor Create; override;
    destructor Destroy; override;
    /// <summary>0 follows Windows, 1 is light, 2 is dark.</summary>
    procedure ApplyTheme(ATheme: Integer);
    /// <summary>Opens the small always-on-top roast window, or brings it back.</summary>
    procedure ShowMiniRoaster;
    procedure ShowRoastery;
    class procedure Activated(Sender: TObject; const AActivation: TWinUIActivation);
  published
    procedure RoastBadgeClick(Sender: TObject);
    procedure SearchSubmitted(Sender: TObject; E: TWinUIAutoSuggestBoxQuerySubmittedEventArgs);
    procedure SearchTextChanged(Sender: TObject; E: TWinUIAutoSuggestBoxTextChangedEventArgs);
  end;

var
  Ember: TMainWindow;

implementation

uses
  Data.DB,
  FireDAC.Comp.Client,
  RADWinUI.Notifications,
  RADWinUI.Motion,
  EmberData,
  EmberSettings,
  RoastSession,
  HomePage,
  OrdersPage,
  RoastPage,
  SettingsPage,
  MiniRoastWindow;

constructor TSuggestion.Create(const AName, AKind, AGlyph: string);
begin
  inherited Create;
  FName := AName;
  FKind := AKind;
  FGlyph := AGlyph;
end;

// The text the search box takes when a suggestion is chosen
function TSuggestion.ToString: string;
begin
  Result := FName;
end;

constructor TMainWindow.Create;
begin
  inherited;
  Ember := Self;
  FSuggestions := TWinUIBindableList<TSuggestion>.Create;
  SearchBox.ItemsSource := FSuggestions;
  LocalizeFormats;
  // Menu clicks, the settings item and the back button drive the frame
  ContentFrame.AttachNavigationView(Nav, [THomePage, TOrdersPage, TRoastPage], TSettingsPage);
  ContentFrame.Navigate(THomePage);
  // -light and -dark pick a theme without changing the saved one, for screenshots
  if FindCmdLineSwitch('light') then
    ApplyTheme(1)
  else if FindCmdLineSwitch('dark') then
    ApplyTheme(2)
  else
    ApplyTheme(SavedTheme);
  Roast.Listen(RoastChanged);
  Roast.OnFinished := RoastFinished;
end;

destructor TMainWindow.Destroy;
begin
  Roast.Unlisten(RoastChanged);
  Roast.OnFinished := nil;
  Ember := nil;
  inherited;
  // After inherited: the search box reads the list until the content goes
  FSuggestions.Free;
end;

procedure TMainWindow.ApplyTheme(ATheme: Integer);
const
  Themes: array[0..2] of TWinUIElementTheme = (TWinUIElementTheme.Default, TWinUIElementTheme.Light, TWinUIElementTheme.Dark);
  TitleThemes: array[0..2] of TWinUITitleBarTheme = (TWinUITitleBarTheme.UseDefaultAppMode, TWinUITitleBarTheme.Light,
    TWinUITitleBarTheme.Dark);
begin
  Root.RequestedTheme := Themes[ATheme];
  AppWindow.TitleBar.PreferredTheme := TitleThemes[ATheme];
end;

procedure TMainWindow.RoastChanged(Sender: TObject);
begin
  case Roast.Phase of
    TRoastPhase.Idle:
      Exit;
    TRoastPhase.Done:
      begin
        BadgeTitle.Text := Format(S('BadgeDoneFormat', 'Batch #%d is ready'), [Roast.BatchNo]);
        BadgeText.Text := Format('%s  %s', [Roast.Coffee, FormatClock(Roast.Seconds)]);
      end;
  else
    BadgeTitle.Text := Format(S('BadgeRoastingFormat', 'Roasting batch #%d'), [Roast.BatchNo]);
    BadgeText.Text := Format('%s  %.0f'#$00B0'C  %s', [Roast.Coffee, Roast.BeanTemp, FormatClock(Roast.Seconds)]);
  end;
  BadgeProgress.Value := Roast.Seconds;
  if Roast.Seconds mod 30 = 0 then
    TWinUIMotion.Pulse(BadgeGlow, 1.3);
end;

// The batch is done: Windows tells about it, also when Ember is behind other windows
procedure TMainWindow.RoastFinished(Sender: TObject);
var
  Note: TWinUINotification;
begin
  RoasteryData.UseStock(Roast.Coffee, Roast.BatchKg);
  Note := TWinUINotification.Create;
  try
    Note.Title := Format(S('NoteTitleFormat', 'Batch #%d is ready'), [Roast.BatchNo]);
    Note.Text := Format(S('NoteTextFormat', '%s, %.1f kg, dropped at %s after %s of development.'),
      [Roast.Coffee, Roast.BatchKg, FormatClock(Roast.Seconds), FormatClock(Roast.DevelopmentSeconds)]);
    Note.Argument := 'show';
    Note.Tag := 'roast';
    Note.AddButton(S('NoteShow', 'Show the roast'), 'show');
    Note.AddButton(S('NoteNext', 'Start the next batch'), 'next');
    Note.Show;
  finally
    Note.Free;
  end;
end;

class procedure TMainWindow.Activated(Sender: TObject; const AActivation: TWinUIActivation);
begin
  if Ember <> nil then
    Ember.HandleActivation(AActivation);
end;

procedure TMainWindow.HandleActivation(const AActivation: TWinUIActivation);
begin
  if AActivation.Kind <> TWinUIActivationKind.Notification then
    Exit;
  ShowRoastery;
  if AActivation.Arguments = 'next' then
    Roast.Start(Roast.Coffee, Roast.BatchKg);
end;

procedure TMainWindow.ShowRoastery;
begin
  if not (ContentFrame.CurrentPage is TRoastPage) then
    ContentFrame.Navigate(TRoastPage);
end;

procedure TMainWindow.ShowMiniRoaster;
var
  W: TWinUIWindow;
begin
  for W in TWinUIApp.Windows do
    if W = FMini then
    begin
      FMini.Show;
      Exit;
    end;
  // No owner: the mini window stays on screen when Ember is minimized
  FMini := TMiniRoastWindow.Create;
  FMini.Show;
end;

procedure TMainWindow.RoastBadgeClick(Sender: TObject);
begin
  ShowRoastery;
end;

// The Orders page filters in place; from another page, Orders opens with the search
procedure TMainWindow.Search(const AText: string);
begin
  if ContentFrame.CurrentPage is TOrdersPage then
    TOrdersPage(ContentFrame.CurrentPage).Search(AText)
  else if AText <> '' then
    ContentFrame.Navigate(TOrdersPage, AText);
end;

// The cafes and coffees whose names contain the text, at most eight
procedure TMainWindow.Suggest(const AText: string);

  procedure AddFrom(ATable: TFDMemTable; const AKind, AGlyph: string);
  var
    Rows: TDataSet;
  begin
    Rows := RoasteryData.Snapshot(ATable, 'Name');
    try
      while not Rows.Eof and (FSuggestions.Count < 8) do
      begin
        if Pos(LowerCase(AText), LowerCase(Rows.FieldByName('Name').AsString)) > 0 then
          FSuggestions.Add(TSuggestion.Create(Rows.FieldByName('Name').AsString, AKind, AGlyph));
        Rows.Next;
      end;
    finally
      Rows.Free;
    end;
  end;

begin
  FSuggestions.Clear;
  if AText = '' then
    Exit;
  AddFrom(RoasteryData.Customers, S('SuggestCafe', 'cafe'), #$E7BF);
  AddFrom(RoasteryData.Coffees, S('SuggestCoffee', 'coffee'), #$EC32);
end;

procedure TMainWindow.SearchTextChanged(Sender: TObject; E: TWinUIAutoSuggestBoxTextChangedEventArgs);
begin
  // Only what the user typed: a chosen suggestion arrives as QuerySubmitted
  if E.Reason <> TWinUIAutoSuggestionBoxTextChangeReason.UserInput then
    Exit;
  Suggest(Trim(SearchBox.Text));
  if ContentFrame.CurrentPage is TOrdersPage then
    Search(Trim(SearchBox.Text));
end;

// Enter, the search button or a chosen suggestion
procedure TMainWindow.SearchSubmitted(Sender: TObject; E: TWinUIAutoSuggestBoxQuerySubmittedEventArgs);
begin
  FSuggestions.Clear;
  Search(Trim(E.QueryText));
end;

end.
