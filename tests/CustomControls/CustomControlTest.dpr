program CustomControlTest;

{
  Checks controls written in Delphi (RADWinUI.CustomControls): a test control
  with every property kind and an event, loaded from XAML and created from
  Pascal, with bindings in both directions, a template and the type index.
  The window opens where RADWINUI_TEST_MONITOR puts test windows.
}

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.SysUtils,
  RADWinUI.Abi,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Forms,
  RADWinUI.CustomControls;

type
  TBadgeLevel = (Low, Normal, High);

  TTestBadge = class(TWinUICustomControl)
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
  public
    Changes: TArray<Integer>;
    procedure Tap;
    function Level: TBadgeLevel;
    function TemplatePartForTest(const AName: string): IDependencyObject;
    function GetEventForTest(AIndex: Integer): TWinUIEvent<TWinValue>;
  published
    property Caption: string index 0 read GetText write SetText;
    property Count: Integer index 1 read GetInt32 write SetInt32;
    property Ratio: Double index 2 read GetDouble write SetDouble;
    property Active: Boolean index 3 read GetBoolean write SetBoolean;
    property Fill: TWinUIBrush index 4 read GetBrush write SetBrush;
    property OnTapped: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

  TTestWindow = class(TWinUIWindow)
  private
    FTimer: TWinUITimer;
    FStep: Integer;
    FFailures: Integer;
    FTapped: Integer;
    procedure Check(AOk: Boolean; const AWhat: string);
    procedure Step(Sender: TObject);
    procedure BadgeTapped(Sender: TObject; const E: TWinValue);
  public
    constructor Create; override;
    destructor Destroy; override;
    class procedure Failed(Sender: TObject; E: Exception);
  end;

const
  BadgeTemplate =
    '<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:rw="using:RADWinUI.Controls" ' +
    'TargetType="rw:TestBadge">' +
    '<StackPanel><TextBlock x:Name="PART_Caption" Text="{TemplateBinding Caption}" />' +
    '<ContentPresenter /></StackPanel></ControlTemplate>';

  ContentXaml =
    '<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:rw="using:RADWinUI.Controls">' +
    '<rw:TestBadge x:Name="Badge" Caption="Hi" Count="3" Ratio="0.25" Active="True" Level="High" Fill="Orange">' +
    '<TextBlock x:Name="Inner" Text="inner" /></rw:TestBadge>' +
    '<TextBlock x:Name="Echo" Text="{Binding Caption, ElementName=Badge}" />' +
    '<TextBlock x:Name="Source" Text="from source" />' +
    '<rw:TestBadge x:Name="Bound" Caption="{Binding Text, ElementName=Source}" />' +
    '</StackPanel>';

{ TTestBadge }

class procedure TTestBadge.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Caption', TWinUIPropertyKind.Text);
  AType.AddProperty('Count', TWinUIPropertyKind.Int32, '1');
  AType.AddProperty('Ratio', TWinUIPropertyKind.Double, '0.5');
  AType.AddProperty('Active', TWinUIPropertyKind.Boolean, 'False');
  AType.AddProperty('Fill', TWinUIPropertyKind.Brush);
  AType.AddProperty('Level', TWinUIPropertyKind.Enum, 'Normal', TypeInfo(TBadgeLevel));
  AType.AddEvent('Tapped');
end;

procedure TTestBadge.Initialize;
begin
  UseTemplate(BadgeTemplate);
end;

procedure TTestBadge.PropertyChanged(AIndex: Integer);
begin
  Changes := Changes + [AIndex];
end;

procedure TTestBadge.Tap;
begin
  Fire(0);
end;

function TTestBadge.TemplatePartForTest(const AName: string): IDependencyObject;
begin
  Result := TemplatePart(AName);
end;

function TTestBadge.GetEventForTest(AIndex: Integer): TWinUIEvent<TWinValue>;
begin
  Result := GetEvent(AIndex);
end;

function TTestBadge.Level: TBadgeLevel;
begin
  Result := TBadgeLevel(GetInt32(5));
end;

{ TTestWindow }

class procedure TTestWindow.Failed(Sender: TObject; E: Exception);
begin
  Writeln('  [failed] ', E.ClassName, ': ', E.Message);
  Flush(Output);
  ExitProcess(1);
end;

constructor TTestWindow.Create;
begin
  inherited;
  Title := 'Custom control test';
  Width := 400;
  Height := 300;
  Writeln('Custom controls');
  LoadContent(ContentXaml);
  Check(True, 'XAML with rw: elements loads');
  FTimer := TWinUITimer.Create;
  FTimer.Interval := 300;
  FTimer.OnTimer := Step;
  FTimer.Enabled := True;
end;

destructor TTestWindow.Destroy;
begin
  FTimer.Free;
  inherited;
end;

procedure TTestWindow.Check(AOk: Boolean; const AWhat: string);
begin
  if AOk then
    Writeln('  [ok] ', AWhat)
  else
  begin
    Writeln('  [failed] ', AWhat);
    Inc(FFailures);
  end;
end;

procedure TTestWindow.BadgeTapped(Sender: TObject; const E: TWinValue);
begin
  Inc(FTapped);
end;

procedure TTestWindow.Step(Sender: TObject);
var
  Badge, Bound, Made: TTestBadge;
  Again: TWinUIObject;
  Panel: TWinUIStackPanel;
  Part: TWinUITextBlock;
  Json: string;
  Brush: TWinUIBrush;
begin
  Inc(FStep);
  try
    Badge := FindElement<TTestBadge>('Badge');
    Bound := FindElement<TTestBadge>('Bound');
    case FStep of
      1:
        begin
          Check(Badge is TTestBadge, 'FindElement returns the Pascal control');
          Check(FindElement<TWinUIContentControl>('Badge') = Badge, 'the same object for every wrapper class');
          Check(Badge.Caption = 'Hi', 'string property from XAML');
          Check(Badge.Count = 3, 'Int32 property from XAML');
          Check(Abs(Badge.Ratio - 0.25) < 1E-9, 'Double property from XAML');
          Check(Badge.Active, 'Boolean property from XAML');
          Check(Badge.Level = TBadgeLevel.High, 'enumeration property from XAML');
          Brush := Badge.Fill;
          Check((Brush is TWinUISolidColorBrush) and (TWinUISolidColorBrush(Brush).Color.R = $FF) and
            (TWinUISolidColorBrush(Brush).Color.G = $A5), 'Brush property from XAML (Orange)');
          Check(Badge.Content.Obj <> nil, 'content element');
          Check(Bound.Count = 1, 'default value of an unset property');
          Check(Bound.Caption = 'from source', 'binding into a custom property');
          Check(FindElement<TWinUITextBlock>('Echo').Text = 'Hi', 'binding from a custom property');
          Part := TWinUITextBlock(TWinUIObject.Wrap(Badge, Badge.TemplatePartForTest('PART_Caption'),
            TWinUITextBlock));
          Check((Part <> nil) and (Part.Text = 'Hi'), 'TemplateBinding in the control''s template');
          Badge.Changes := nil;
          Badge.Caption := 'Changed';
          Check((Length(Badge.Changes) = 1) and (Badge.Changes[0] = 0), 'PropertyChanged on a Pascal set');
        end;
      2:
        begin
          Check(FindElement<TWinUITextBlock>('Echo').Text = 'Changed', 'binding follows a Pascal set');
          Badge.OnTapped := BadgeTapped;
          Badge.GetEventForTest(0).Add(
            procedure(Sender: TObject; E: TWinValue)
            begin
              Inc(FTapped, 10);
            end);
          Badge.Tap;
          Check(FTapped = 11, 'event: OnTapped and listener');
          Made := TTestBadge.Create(Self);
          Made.Caption := 'made';
          Panel := Content as TWinUIStackPanel;
          (TWinUIObject.IntfOf(Panel, IPanel) as IPanel).Children.Append(
            TWinUIObject.IntfOf(Made, IUIElement) as IUIElement);
          Again := Panel.Children[Panel.Children.Count - 1];
          Check(Again = Made, 'created from Pascal, found again as the same object');
          Json := TWinUICustomControls.TypeIndexJson;
          Check(Json.Contains('"RADWinUI.Controls.TestBadge"') and Json.Contains('"Level": "enum:Low|Normal|High"') and
            Json.Contains('"Tapped": ["TWinUIWinValueEventHandler", "TWinValue"]'), 'type index JSON');
          Flush(Output);
          Close;
        end;
    end;
  except
    on E: Exception do
      Failed(Self, E);
  end;
end;

begin
  if GetEnvironmentVariable('RADWINUI_TEST_MONITOR') = '' then
    SetEnvironmentVariable('RADWINUI_TEST_MONITOR', 'offscreen');
  TWinUICustomControls.Register(TTestBadge, 'TestBadge', 'Test');
  TWinUIApp.OnException := TTestWindow.Failed;
  TWinUIApp.Run(TTestWindow);
end.
