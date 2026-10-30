unit Notch.Settings;

{ What the notch shows: the widgets in their order with their items, and the
  window options. Stored as JSON in %LOCALAPPDATA%\RADWinUI Notch\settings.json. }

interface

uses
  System.Generics.Collections;

type
  TWidgetKind = (Apps, Agents, Remote, Calendar, Links, Notes, Music, Focus);
  // The screen edge the notch hangs from
  TNotchEdge = (Top, Bottom, Left, Right);

  TNotchItem = class
  public
    Name: string;
    // An AppsFolder parsing name, a URL, a path or a host address, depending on the widget
    Target: string;
    constructor Create(const AName, ATarget: string);
  end;

  TNotchWidget = class
  public
    Kind: TWidgetKind;
    Title: string;
    // The text of a Notes widget
    Text: string;
    Items: TObjectList<TNotchItem>;
    constructor Create(AKind: TWidgetKind; const ATitle: string = '');
    destructor Destroy; override;
    procedure AddItem(const AName, ATarget: string);
  end;

  TNotchSettings = class
  strict private
    FFileName: string;
  public
    Widgets: TObjectList<TNotchWidget>;
    Transparency: Boolean;
    // How see-through the notch is with Transparency on, in percent
    TransparencyLevel: Integer;
    Pinned: Boolean;
    // Ctrl+Alt+N gives the notch the keyboard
    Keyboard: Boolean;
    // The notch opens when an agent finishes or needs an answer
    AgentAlerts: Boolean;
    // Ask the Claude account for the exact limits, with the login of Claude Code
    ExactClaudeLimits: Boolean;
    Edge: TNotchEdge;
    // Where along the edge the notch's centre is, 0..1
    EdgeOffset: Double;
    // A point on the display the notch is on, MonitorSet False for the primary display
    MonitorSet: Boolean;
    MonitorX, MonitorY: Integer;
    procedure ResetPosition;
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    /// <summary>False when the file is missing or unreadable, the settings are then empty.</summary>
    function Load: Boolean;
    procedure Save;
    /// <summary>Moves widget AIndex by ADelta places, within the list.</summary>
    procedure MoveWidget(AIndex, ADelta: Integer);
    function HasKind(AKind: TWidgetKind): Boolean;
    property FileName: string read FFileName;
  end;

/// <summary>
///   %LOCALAPPDATA%\RADWinUI Notch, where the settings, the icon cache and the
///   agent events live. The NOTCH_DATA environment variable points it elsewhere.
/// </summary>
function NotchDataFolder: string;

const
  KindNames: array[TWidgetKind] of string = ('apps', 'agents', 'remote', 'calendar', 'links', 'notes', 'music', 'focus');
  EdgeNames: array[TNotchEdge] of string = ('top', 'bottom', 'left', 'right');
  KindTitles: array[TWidgetKind] of string = ('Apps', 'AI agents', 'Remote desktop', 'Calendar', 'Links', 'Notes',
    'Now playing', 'Focus');

implementation

uses
  System.SysUtils,
  System.Math,
  System.IOUtils,
  System.JSON;

function NotchDataFolder: string;
begin
  Result := GetEnvironmentVariable('NOTCH_DATA');
  if Result = '' then
    Result := TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'), 'RADWinUI Notch');
end;

{ TNotchItem }

constructor TNotchItem.Create(const AName, ATarget: string);
begin
  inherited Create;
  Name := AName;
  Target := ATarget;
end;

{ TNotchWidget }

constructor TNotchWidget.Create(AKind: TWidgetKind; const ATitle: string);
begin
  inherited Create;
  Kind := AKind;
  Title := ATitle;
  if Title = '' then
    Title := KindTitles[AKind];
  Items := TObjectList<TNotchItem>.Create;
end;

destructor TNotchWidget.Destroy;
begin
  Items.Free;
  inherited;
end;

procedure TNotchWidget.AddItem(const AName, ATarget: string);
begin
  Items.Add(TNotchItem.Create(AName, ATarget));
end;

{ TNotchSettings }

constructor TNotchSettings.Create(const AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
  Widgets := TObjectList<TNotchWidget>.Create;
  TransparencyLevel := 28;
  AgentAlerts := True;
  ResetPosition;
end;

procedure TNotchSettings.ResetPosition;
begin
  Edge := TNotchEdge.Top;
  EdgeOffset := 0.5;
  MonitorSet := False;
end;

destructor TNotchSettings.Destroy;
begin
  Widgets.Free;
  inherited;
end;

function TNotchSettings.HasKind(AKind: TWidgetKind): Boolean;
var
  W: TNotchWidget;
begin
  for W in Widgets do
    if W.Kind = AKind then
      Exit(True);
  Result := False;
end;

procedure TNotchSettings.MoveWidget(AIndex, ADelta: Integer);
var
  Target: Integer;
begin
  Target := AIndex + ADelta;
  if (AIndex >= 0) and (AIndex < Widgets.Count) and (Target >= 0) and (Target < Widgets.Count) then
    Widgets.Move(AIndex, Target);
end;

function TNotchSettings.Load: Boolean;
var
  Root: TJSONValue;
  WidgetValue, ItemValue: TJSONValue;
  Kind: TWidgetKind;
  KindName: string;
  Widget: TNotchWidget;
  Known: Boolean;
  E: TNotchEdge;
begin
  Widgets.Clear;
  if not TFile.Exists(FFileName) then
    Exit(False);
  try
    Root := TJSONObject.ParseJSONValue(TFile.ReadAllText(FFileName, TEncoding.UTF8));
  except
    Root := nil;
  end;
  if not (Root is TJSONObject) then
  begin
    Root.Free;
    Exit(False);
  end;
  try
    try
      Transparency := Root.GetValue<Boolean>('transparency', False);
      TransparencyLevel := EnsureRange(Root.GetValue<Integer>('transparencyLevel', 28), 0, 100);
      Pinned := Root.GetValue<Boolean>('pinned', False);
      Keyboard := Root.GetValue<Boolean>('keyboard', False);
      AgentAlerts := Root.GetValue<Boolean>('agentAlerts', True);
      ExactClaudeLimits := Root.GetValue<Boolean>('exactClaudeLimits', False);
      for E := Low(TNotchEdge) to High(TNotchEdge) do
        if SameText(EdgeNames[E], Root.GetValue<string>('edge', 'top')) then
          Edge := E;
      EdgeOffset := EnsureRange(Root.GetValue<Double>('edgeOffset', 0.5), 0, 1);
      MonitorSet := Root.FindValue('monitorX') <> nil;
      MonitorX := Root.GetValue<Integer>('monitorX', 0);
      MonitorY := Root.GetValue<Integer>('monitorY', 0);
      if Root.FindValue('widgets') is TJSONArray then
        for WidgetValue in TJSONArray(Root.FindValue('widgets')) do
        begin
          KindName := WidgetValue.GetValue<string>('kind', '');
          Known := False;
          for Kind := Low(TWidgetKind) to High(TWidgetKind) do
            if SameText(KindNames[Kind], KindName) then
            begin
              Known := True;
              Break;
            end;
          // A widget of a newer version is left out rather than guessed
          if not Known then
            Continue;
          Widget := TNotchWidget.Create(Kind, WidgetValue.GetValue<string>('title', ''));
          Widgets.Add(Widget);
          Widget.Text := WidgetValue.GetValue<string>('text', '');
          if WidgetValue.FindValue('items') is TJSONArray then
            for ItemValue in TJSONArray(WidgetValue.FindValue('items')) do
              Widget.AddItem(ItemValue.GetValue<string>('name', ''), ItemValue.GetValue<string>('target', ''));
        end;
      Result := True;
    except
      // A file edited by hand into another shape counts as unreadable
      Widgets.Clear;
      Result := False;
    end;
  finally
    Root.Free;
  end;
end;

procedure TNotchSettings.Save;
var
  Root, WidgetObject, ItemObject: TJSONObject;
  WidgetArray, ItemArray: TJSONArray;
  Widget: TNotchWidget;
  Item: TNotchItem;
  Temp: string;
begin
  Root := TJSONObject.Create;
  try
    Root.AddPair('version', TJSONNumber.Create(1));
    Root.AddPair('transparency', TJSONBool.Create(Transparency));
    Root.AddPair('transparencyLevel', TJSONNumber.Create(TransparencyLevel));
    Root.AddPair('pinned', TJSONBool.Create(Pinned));
    Root.AddPair('keyboard', TJSONBool.Create(Keyboard));
    Root.AddPair('agentAlerts', TJSONBool.Create(AgentAlerts));
    Root.AddPair('exactClaudeLimits', TJSONBool.Create(ExactClaudeLimits));
    Root.AddPair('edge', EdgeNames[Edge]);
    Root.AddPair('edgeOffset', TJSONNumber.Create(EdgeOffset));
    if MonitorSet then
    begin
      Root.AddPair('monitorX', TJSONNumber.Create(MonitorX));
      Root.AddPair('monitorY', TJSONNumber.Create(MonitorY));
    end;
    WidgetArray := TJSONArray.Create;
    Root.AddPair('widgets', WidgetArray);
    for Widget in Widgets do
    begin
      WidgetObject := TJSONObject.Create;
      WidgetArray.AddElement(WidgetObject);
      WidgetObject.AddPair('kind', KindNames[Widget.Kind]);
      WidgetObject.AddPair('title', Widget.Title);
      if Widget.Kind = TWidgetKind.Notes then
        WidgetObject.AddPair('text', Widget.Text);
      ItemArray := TJSONArray.Create;
      WidgetObject.AddPair('items', ItemArray);
      for Item in Widget.Items do
      begin
        ItemObject := TJSONObject.Create;
        ItemArray.AddElement(ItemObject);
        ItemObject.AddPair('name', Item.Name);
        ItemObject.AddPair('target', Item.Target);
      end;
    end;
    ForceDirectories(ExtractFileDir(FFileName));
    // Written next to it first, so a crash halfway never leaves a broken file
    Temp := FFileName + '.tmp';
    TFile.WriteAllText(Temp, Root.Format(2), TEncoding.UTF8);
    if TFile.Exists(FFileName) then
      TFile.Delete(FFileName);
    TFile.Move(Temp, FFileName);
  finally
    Root.Free;
  end;
end;

end.
