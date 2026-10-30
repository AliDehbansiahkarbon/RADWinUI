unit Notch.Details;

{ A normal window with every AI agent session the notch knows of, and the
  usage limits of the agents. Mica, its content up in the title bar, and the
  light or dark look of Windows, which it follows while it is open. }

interface

uses
  System.SysUtils,
  RADWinUI.Forms,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  Notch.Agents,
  Notch.Usage,
  Notch.Widgets;

type
  TAgentDetailsWindow = class(TWinUIWindow)
  strict private
    FFrame: TFragment;
    FBody: TFragment;
    FOld: TFragment;
    FBodyHost: TWinUIBorder;
    FTabs: TWinUISelectorBar;
    FUsageTab: TWinUISelectorBarItem;
    FSessionsXaml: string;
    FUsageXaml: string;
    FShown: string;
    FOnExact: TProc;
    procedure ShowBody;
  public
    constructor Create; override;
    destructor Destroy; override;
    /// <summary>Shows ASessions and AUsage for the agents in AKinds, the window keeps nothing of them.</summary>
    procedure Refresh(const ASessions: TArray<TAgentSession>; const AUsage: TArray<TUsageWindow>; AKinds: TAgentKinds;
      AExact: Boolean; const AExactStatus: string; ANow: TDateTime);
    /// <summary>Shows the usage limits (True) or the sessions.</summary>
    procedure ShowUsage(AValue: Boolean);
    function UsageShown: Boolean;
    /// <summary>The whole content, for a picture of it.</summary>
    function Root: TWinUIFrameworkElement;
    /// <summary>Runs when the link that turns on the exact Claude limits is clicked.</summary>
    property OnExact: TProc read FOnExact write FOnExact;
  end;

implementation

uses
  System.StrUtils;

const
  // The content reaches up into the title bar, the caption buttons keep their corner
  FrameXaml =
    '<Grid' + XamlNs + '><Grid.RowDefinitions><RowDefinition Height="48"/><RowDefinition Height="Auto"/>' +
    '<RowDefinition Height="*"/></Grid.RowDefinitions>' +
    '<Grid x:Name="TitleBar" Background="Transparent" Padding="16,0,140,0" ColumnSpacing="10">' +
    '<Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>' +
    '<Border Width="20" Height="20" CornerRadius="10" Background="{ThemeResource AccentFillColorDefaultBrush}" ' +
    'VerticalAlignment="Center"><FontIcon FontFamily="{ThemeResource SymbolThemeFontFamily}" Glyph="&#xE99A;" ' +
    'FontSize="11" Foreground="{ThemeResource TextOnAccentFillColorPrimaryBrush}"/></Border>' +
    '<TextBlock Grid.Column="1" Text="Notch: AI agents" FontSize="12" VerticalAlignment="Center"/></Grid>' +
    '<SelectorBar x:Name="Tabs" Grid.Row="1" Margin="16,0,16,0">' +
    '<SelectorBarItem x:Name="SessionsTab" Text="Sessions"/>' +
    '<SelectorBarItem x:Name="UsageTab" Text="Usage and limits"/></SelectorBar>' +
    '<ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto"><Border x:Name="Body" Padding="24,12,24,24"/>' +
    '</ScrollViewer></Grid>';
  CardStart = '<Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" ' +
    'BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}" BorderThickness="1" CornerRadius="8" Padding="16,12">';
  Secondary = 'Foreground="{ThemeResource TextFillColorSecondaryBrush}"';

constructor TAgentDetailsWindow.Create;
begin
  inherited;
  Title := 'Notch: AI agents';
  Width := 600;
  Height := 520;
  Backdrop := TWinUIBackdrop.Mica;
  FFrame := TFragment.Create(FrameXaml);
  Content := FFrame.Root;
  ExtendsContentIntoTitleBar := True;
  SetTitleBar(TWinUIUIElement(FFrame.Find('TitleBar', TWinUIUIElement)));
  // The caption buttons follow the light or dark look too
  AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.UseDefaultAppMode;
  FBodyHost := TWinUIBorder(FFrame.Find('Body', TWinUIBorder));
  FTabs := TWinUISelectorBar(FFrame.Find('Tabs', TWinUISelectorBar));
  FUsageTab := TWinUISelectorBarItem(FFrame.Find('UsageTab', TWinUISelectorBarItem));
  FTabs.SelectionChanged.Add(
    procedure(Sender: TObject; E: TWinUISelectorBarSelectionChangedEventArgs)
    begin
      ShowBody;
    end);
  // Chosen here only: a selection in the XAML would win again once the window is loaded
  ShowUsage(False);
end;

destructor TAgentDetailsWindow.Destroy;
begin
  FOld.Free;
  FBody.Free;
  FFrame.Free;
  inherited;
end;

function TAgentDetailsWindow.Root: TWinUIFrameworkElement;
begin
  Result := FFrame.Root;
end;

function TAgentDetailsWindow.UsageShown: Boolean;
begin
  Result := FTabs.SelectedItem = FUsageTab;
end;

procedure TAgentDetailsWindow.ShowUsage(AValue: Boolean);
begin
  if AValue then
    FTabs.SelectedItem := FUsageTab
  else
    FTabs.SelectedItem := TWinUISelectorBarItem(FFrame.Find('SessionsTab', TWinUISelectorBarItem));
  ShowBody;
end;

procedure TAgentDetailsWindow.ShowBody;
var
  Xaml: string;
begin
  if UsageShown then
    Xaml := FUsageXaml
  else
    Xaml := FSessionsXaml;
  // Only when something changed: a new tree every second would reset the scroll position
  if (Xaml = '') or (Xaml = FShown) then
    Exit;
  FShown := Xaml;
  // The piece shown before goes one refresh later, never inside its own event
  FOld.Free;
  FOld := FBody;
  FBody := TFragment.Create(Xaml);
  FBodyHost.Child := FBody.Root;
  if Assigned(FOnExact) then
    FBody.OnClick('ExactLink', FOnExact);
end;

function SessionsXaml(const ASessions: TArray<TAgentSession>; ANow: TDateTime): string;
var
  S: TAgentSession;
begin
  Result := '<StackPanel Spacing="8"' + XamlNs + '>';
  if Length(ASessions) = 0 then
    Result := Result + Format('<TextBlock Text="No agent session in the last %d minutes." %s Margin="0,8,0,0"/>',
      [DropSeconds div 60, Secondary]);
  for S in ASessions do
    Result := Result + CardStart + Format('<Grid ColumnSpacing="12"><Grid.ColumnDefinitions>' +
      '<ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/>' +
      '</Grid.ColumnDefinitions>' +
      '<Ellipse Width="10" Height="10" Fill="%s" VerticalAlignment="Top" Margin="0,6,0,0"/>' +
      '<StackPanel Grid.Column="1" Spacing="2"><TextBlock Text="%s" FontSize="15" FontWeight="SemiBold" ' +
      'TextTrimming="CharacterEllipsis"/><TextBlock Text="%s" TextWrapping="Wrap"/>' +
      '<TextBlock Text="%s" FontSize="12" %s/></StackPanel>' +
      '<TextBlock Grid.Column="2" Text="%s" FontSize="12" FontWeight="SemiBold" Foreground="%0:s"/></Grid></Border>',
      [StateColorXaml(S.State), Esc(S.Project), Esc(S.Activity), Esc(AgentNames[S.Kind] + ', ' + S.Elapsed(ANow)),
      Secondary, StateNames[S.State]]);
  Result := Result + Format('<TextBlock Text="%s" FontSize="12" %s Margin="0,8,0,0"/></StackPanel>',
    [AgentLegend, Secondary]);
end;

function UsageXaml(const AUsage: TArray<TUsageWindow>; AKinds: TAgentKinds; AExact: Boolean;
  const AExactStatus: string; ANow: TDateTime): string;
var
  Kind: TAgentKind;
  Window: TUsageWindow;
  Found, Estimate: Boolean;
begin
  Result := '<StackPanel Spacing="12"' + XamlNs + '>';
  if AKinds = [] then
    Result := Result + Format('<TextBlock Text="No agent is watched. Tick some in the AI agents widget." %s/>',
      [Secondary]);
  for Kind in AKinds do
  begin
    Result := Result + CardStart + Format('<StackPanel Spacing="10"><TextBlock Text="%s" FontSize="15" ' +
      'FontWeight="SemiBold"/>', [AgentNames[Kind]]);
    Estimate := True;
    for Window in AUsage do
      if (Window.Agent = Kind) and not Window.Estimate then
        Estimate := False;
    if (Kind = TAgentKind.ClaudeCode) and Estimate then
      Result := Result + Format('<TextBlock Text="Tokens used on this PC (estimate), not your plan''s limit" ' +
        'FontSize="12" FontWeight="SemiBold" %s/>', [Secondary])
    else if Kind = TAgentKind.ClaudeCode then
      Result := Result + Format('<TextBlock Text="Your plan''s limits, from your Claude account" FontSize="12" ' +
        'FontWeight="SemiBold" %s/>', [Secondary]);
    Found := False;
    for Window in AUsage do
      if Window.Agent = Kind then
      begin
        Found := True;
        Result := Result + Format('<StackPanel Spacing="4"><TextBlock Text="%s"/>', [Esc(Window.Title)]);
        if Window.Percent >= 0 then
          Result := Result + Format('<ProgressBar Maximum="100" Value="%s"/>',
            [FormatFloat('0.#', Window.PercentAt(ANow), TFormatSettings.Invariant)]);
        Result := Result + Format('<TextBlock Text="%s" FontSize="12" %s/></StackPanel>',
          [Esc(Window.Summary(ANow)), Secondary]);
      end;
    if not Found then
      Result := Result + Format('<TextBlock Text="Reading the session files..." FontSize="12" %s/>', [Secondary]);
    if (Kind = TAgentKind.ClaudeCode) and Estimate then
    begin
      Result := Result + Format('<TextBlock Text="Claude Code writes only the tokens of each answer, so this adds ' +
        'up the new input and output tokens on this PC, without cache reads." FontSize="12" TextWrapping="Wrap" ' +
        '%s/>', [Secondary]);
      if AExact and (AExactStatus <> '') then
        Result := Result + Format('<TextBlock Text="%s" FontSize="12" TextWrapping="Wrap" %s/>', [Esc(AExactStatus),
          Secondary])
      else if not AExact then
        Result := Result + '<HyperlinkButton x:Name="ExactLink" Padding="0" Content="Show exact limits (uses your ' +
          'Claude Code login on this PC)"/>';
    end
    else if Kind = TAgentKind.Codex then
      Result := Result + Format('<TextBlock Text="As Codex reported them in its latest session." FontSize="12" ' +
        'TextWrapping="Wrap" %s/>', [Secondary]);
    Result := Result + '</StackPanel></Border>';
  end;
  Result := Result + '</StackPanel>';
end;

procedure TAgentDetailsWindow.Refresh(const ASessions: TArray<TAgentSession>; const AUsage: TArray<TUsageWindow>;
  AKinds: TAgentKinds; AExact: Boolean; const AExactStatus: string; ANow: TDateTime);
begin
  FSessionsXaml := SessionsXaml(ASessions, ANow);
  FUsageXaml := UsageXaml(AUsage, AKinds, AExact, AExactStatus, ANow);
  ShowBody;
end;

end.
