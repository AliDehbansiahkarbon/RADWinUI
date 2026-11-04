program TabBarsTest;

{
  Checks the tab bars (RADWinUI.TabBars): the Items text and its icons, every
  style loads from XAML, SelectedIndex animates and fires SelectionChanged,
  Pages shows the selected tab's element, a tap selects the tab under it,
  the Sliding Pill paints its pill under the selected tab, Bubble Float's
  bubbles rise and end, and closing a window frees its bars. The window opens
  where RADWINUI_TEST_MONITOR puts test windows.
}

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.SysUtils,
  System.IOUtils,
  RADWinUI.Abi,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Forms,
  RADWinUI.CustomControls,
  RADWinUI.Controls,
  RADWinUI.TabBarIcons,
  RADWinUI.TabBars;

type
  TTestWindow = class(TWinUIWindow)
  private
    FTimer: TWinUITimer;
    FStep: Integer;
    FFailures: Integer;
    FChanges: Integer;
    FSecond: TWinUIWindow;
    FLiveBefore: Integer;
    FPixels: TBytes;
    FPixelWidth: Integer;
    FRendered: Boolean;
    procedure Check(AOk: Boolean; const AWhat: string);
    procedure CheckItems;
    procedure RenderPill;
    function Pixel(AX, AY: Integer): TWinUIColor;
    procedure Step(Sender: TObject);
    procedure PillChanged(Sender: TObject; const E: TWinValue);
  public
    constructor Create; override;
    destructor Destroy; override;
    class procedure Failed(Sender: TObject; E: Exception);
  end;

const
  Namespaces = 'xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:rw="using:RADWinUI.Controls"';

  ContentXaml =
    '<StackPanel ' + Namespaces + ' Spacing="12" Padding="12" Background="#101018">' +
    '<rw:SlidingPillTabBar x:Name="Pill" Width="360" AnimationDuration="200" Pages="PageHome, PageSearch, PageLikes, PageProfile" />' +
    '<rw:LiquidBulgeTabBar x:Name="Bulge" Width="360" SelectedIndex="3" />' +
    '<rw:FloatingNotchTabBar x:Name="Notch" Width="360" Items="Home, Search, Likes:Heart, Me:Contact" />' +
    '<rw:IconFillTabBar x:Name="Fill" Width="360" ShowLabels="True" />' +
    '<rw:ExpandingLabelTabBar x:Name="Expanding" Width="360" SelectedIndex="1" />' +
    '<rw:BubbleFloatTabBar x:Name="Bubble" Width="360" BubbleCount="5" AnimationDuration="200" />' +
    '<Grid><TextBlock x:Name="PageHome" Text="home" /><TextBlock x:Name="PageSearch" Text="search" />' +
    '<TextBlock x:Name="PageLikes" Text="likes" /><TextBlock x:Name="PageProfile" Text="profile" /></Grid>' +
    '</StackPanel>';

  SecondXaml =
    '<StackPanel ' + Namespaces + '>' +
    '<rw:SlidingPillTabBar /><rw:LiquidBulgeTabBar /><rw:FloatingNotchTabBar />' +
    '<rw:IconFillTabBar /><rw:ExpandingLabelTabBar /><rw:BubbleFloatTabBar /></StackPanel>';

/// src\Framework\RADWinUI.Controls.json of the checkout above the exe, '' when not found.
function ControlsJsonPath: string;
var
  Folder: string;
begin
  Folder := ExtractFileDir(ParamStr(0));
  while Folder <> '' do
  begin
    Result := TPath.Combine(Folder, 'src\Framework\RADWinUI.Controls.json');
    if FileExists(Result) then
      Exit;
    if ExtractFileDir(Folder) = Folder then
      Break;
    Folder := ExtractFileDir(Folder);
  end;
  Result := '';
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
  Title := 'Tab bars test';
  Width := 420;
  Height := 640;
  Writeln('Tab bars');
  CheckItems;
  LoadContent(ContentXaml);
  Check(True, 'XAML with all six tab bars loads');
  FTimer := TWinUITimer.Create;
  FTimer.Interval := 500;
  FTimer.OnTimer := Step;
  FTimer.Enabled := True;
end;

destructor TTestWindow.Destroy;
begin
  FTimer.Free;
  inherited;
  if FFailures > 0 then
    ExitCode := 1;
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

procedure TTestWindow.CheckItems;
var
  Items: TArray<TTabBarItemText>;
  Glyph, Filled: Char;
begin
  Items := ParseTabBarItems(DefaultTabBarItems);
  Check((Length(Items) = 4) and (Items[2].Text = 'Likes') and (Items[2].Icon = 'Heart'),
    'Items text: four tabs, Label:Icon');
  Items := ParseTabBarItems(' Home , , Search:Find,Me:E77B/EA8C ');
  Check((Length(Items) = 3) and (Items[0].Icon = 'Home') and (Items[1].Icon = 'Find') and (Items[2].Text = 'Me'),
    'Items text: spaces and empty entries, a label alone names its icon');
  Check(FormatTabBarItems(Items) = 'Home:Home, Search:Find, Me:E77B/EA8C', 'Items text reads back the same');
  Check(ResolveTabBarIcon('heart', Glyph, Filled) and (Glyph = #$EB51) and (Filled = #$EB52),
    'icon names ignore case and have a filled glyph');
  Check(ResolveTabBarIcon('Profile', Glyph, Filled) and (Glyph = #$E77B), 'icon aliases: Profile is Contact');
  Check(ResolveTabBarIcon('&#xE80F;', Glyph, Filled) and (Glyph = #$E80F) and (Filled = #$E80F),
    'icon code points as XAML writes them');
  Check(ResolveTabBarIcon('E77B/EA8C', Glyph, Filled) and (Glyph = #$E77B) and (Filled = #$EA8C),
    'two code points give outline and filled glyph');
  Check(not ResolveTabBarIcon('Nothing', Glyph, Filled) and (Glyph = #$E897), 'an unknown icon shows Help');
  Check(not ResolveTabBarIcon('Cafe', Glyph, Filled), 'a short hex word is no code point');
  Check(Length(TabBarIcons) >= 40, Format('%d named icons', [Length(TabBarIcons)]));
end;

procedure TTestWindow.PillChanged(Sender: TObject; const E: TWinValue);
begin
  Inc(FChanges);
end;

type
  // Windows.Storage.Streams.IBufferByteAccess: the bytes of a WinRT buffer
  IBufferByteAccess = interface(IUnknown)
    ['{905A0FEF-BC53-11DF-8C49-001E4FC686DA}']
    function Buffer(out AValue: PByte): HRESULT; stdcall;
  end;

const
  PillWidth = 360;

procedure TTestWindow.RenderPill;
var
  Target: TWinUIRenderTargetBitmap;
begin
  Target := TWinUIRenderTargetBitmap.Create(Self);
  Target.RenderAsync(FindElement<TWinUISlidingPillTabBar>('Pill')).Completed := TAsyncActionCompletedHandler.Create(
    procedure(AAction: IAsyncAction; AStatus: AsyncStatus)
    var
      Width, Height: Integer;
    begin
      if AStatus <> AsyncStatus.Completed then
        Exit;
      Width := Target.PixelWidth;
      Height := Target.PixelHeight;
      Target.GetPixelsAsync.Completed := TAsyncOperationCompletedHandler_IBuffer.Create(
        procedure(AOperation: IAsyncOperation_IBuffer; AStatus: AsyncStatus)
        var
          Bytes: PByte;
        begin
          if (AStatus = AsyncStatus.Completed) and
            Succeeded((AOperation.GetResults as IBufferByteAccess).Buffer(Bytes)) then
          begin
            SetLength(FPixels, Width * Height * 4);
            Move(Bytes^, FPixels[0], Length(FPixels));
            FPixelWidth := Width;
            FRendered := True;
          end;
        end);
    end);
end;

// A pixel of the picture, AX and AY in effective pixels of the bar
function TTestWindow.Pixel(AX, AY: Integer): TWinUIColor;
var
  Scale: Double;
  Offset: Integer;
begin
  Scale := FPixelWidth / PillWidth;
  Offset := (Round(AY * Scale) * FPixelWidth + Round(AX * Scale)) * 4;
  // Blue, green, red, alpha
  Result.B := FPixels[Offset];
  Result.G := FPixels[Offset + 1];
  Result.R := FPixels[Offset + 2];
  Result.A := FPixels[Offset + 3];
end;

procedure TTestWindow.Step(Sender: TObject);
var
  Pill: TWinUISlidingPillTabBar;
  Bulge: TWinUILiquidBulgeTabBar;
  Notch: TWinUIFloatingNotchTabBar;
  Fill: TWinUIIconFillTabBar;
  Expanding: TWinUIExpandingLabelTabBar;
  Bubble: TWinUIBubbleFloatTabBar;
  Json: string;
  Slot, Bar: TWinUIColor;
  SlotWidth: Double;
begin
  Inc(FStep);
  try
    Pill := FindElement<TWinUISlidingPillTabBar>('Pill');
    Bulge := FindElement<TWinUILiquidBulgeTabBar>('Bulge');
    Notch := FindElement<TWinUIFloatingNotchTabBar>('Notch');
    Fill := FindElement<TWinUIIconFillTabBar>('Fill');
    Expanding := FindElement<TWinUIExpandingLabelTabBar>('Expanding');
    Bubble := FindElement<TWinUIBubbleFloatTabBar>('Bubble');
    case FStep of
      1:
        begin
          Check((Pill <> nil) and (Bulge <> nil) and (Notch <> nil) and (Fill <> nil) and (Expanding <> nil) and
            (Bubble <> nil), 'FindElement returns each tab bar');
          Check((Pill.ItemCount = 4) and (Pill.Item[3].Text = 'Profile') and (Pill.Item[3].Glyph = #$E77B),
            'the default Items: four tabs with their glyphs');
          Check(Pill.SelectedText = 'Home', 'SelectedIndex 0 by default');
          Check((Notch.ItemCount = 4) and (Notch.Item[3].Text = 'Me') and (Notch.Item[0].Glyph = #$E80F),
            'Items from XAML');
          Check(Notch.ShowLabels and Expanding.ShowLabels and not Pill.ShowLabels and Fill.ShowLabels,
            'ShowLabels defaults by style, XAML overrides it');
          Check(Abs(Bulge.ActualHeight - 84) < 1, Format('Liquid Bulge has room above the bar (%.1f)',
            [Bulge.ActualHeight]));
          Check(Abs(Pill.ActualWidth - 360) < 1, Format('XAML width (%.1f)', [Pill.ActualWidth]));
          Check(Bulge.SelectedIndex = 3, 'SelectedIndex from XAML');
          Check(FindElement<TWinUITextBlock>('PageHome').Visibility = TWinUIVisibility.Visible,
            'Pages shows the selected tab''s element');
          Check(FindElement<TWinUITextBlock>('PageSearch').Visibility = TWinUIVisibility.Collapsed,
            'Pages collapses the others');
          Pill.OnSelectionChanged := PillChanged;
          Pill.SelectedIndex := 2;
          Check((FChanges = 1) and (Pill.SelectedText = 'Likes'), 'SelectedIndex fires SelectionChanged');
          Check(FindElement<TWinUITextBlock>('PageLikes').Visibility = TWinUIVisibility.Visible,
            'Pages follows the selection');
          Bulge.SelectedIndex := 0;
          Notch.SelectedIndex := 2;
          Fill.SelectedIndex := 1;
          Expanding.SelectedIndex := 3;
          Bubble.SelectedIndex := 2;
          // A new window with every style: closing it must free them
          FLiveBefore := TWinUICustomControls.LiveCount;
          FSecond := TWinUIWindow.Create;
          FSecond.LoadContent(SecondXaml);
          FSecond.Show;
          Check(TWinUICustomControls.LiveCount = FLiveBefore + 6, Format('a loaded window has its 6 bars (%d -> %d)',
            [FLiveBefore, TWinUICustomControls.LiveCount]));
        end;
      2:
        begin
          // Mid way through the bubbles, after every selection animation
          Check(Bubble.SelectedText = 'Likes', 'Bubble Float selected Likes');
          Pill.SelectNext;
          Check(Pill.SelectedIndex = 3, 'SelectNext');
          Pill.SelectNext;
          Check(Pill.SelectedIndex = 3, 'SelectNext stays on the last tab');
          Pill.SelectPrevious;
          Pill.SelectPrevious;
          // 2, then 3, 2 and 1: setting the same index again is no change
          Check((Pill.SelectedIndex = 1) and (FChanges = 4), Format('SelectPrevious, one change each (index %d, %d changes)',
            [Pill.SelectedIndex, FChanges]));
          Pill.Items := 'One:Home, Two:Star, Three:Settings';
          Check((Pill.ItemCount = 3) and (Pill.Item[1].FilledGlyph = #$E735), 'new Items rebuild the bar');
          Fill.Items := '';
          Check(Fill.ItemCount = 0, 'a bar without tabs');
          Fill.Items := DefaultTabBarItems;
          Expanding.ShowLabels := False;
          Expanding.ShowLabels := True;
          Bubble.AccentTo := TWinUISolidColorBrush.Create(Self);
          FSecond.Close;
        end;
      3:
        begin
          Check(TWinUICustomControls.LiveCount = FLiveBefore, Format('closing a window frees its bars (%d left, ' +
            '%d XAML elements)', [TWinUICustomControls.LiveCount, TWinUICustomControls.HostCount]));
          Json := TWinUICustomControls.TypeIndexJson;
          Check(Json.Contains('"RADWinUI.Controls.SlidingPillTabBar"') and Json.Contains('"Tab Bars"') and
            Json.Contains('"Items": "tabitems"') and Json.Contains('"unit": "RADWinUI.TabBars"'),
            'type index lists the tab bars, their unit and the tab editor');
          Check((ControlsJsonPath <> '') and (TFile.ReadAllText(ControlsJsonPath, TEncoding.UTF8) = Json),
            'src\Framework\RADWinUI.Controls.json is up to date (tools\ControlsIndex writes it)');
          Pill.SelectedIndex := 2;
        end;
      4:
        RenderPill;
      6:
        begin
          Check(FRendered, 'the Sliding Pill renders');
          if FRendered then
          begin
            SlotWidth := (PillWidth - 16) / 3;
            // Tab 2 of three, just left of its icon: the pill. Tab 0 at the same height: the bar
            Slot := Pixel(Round(8 + 2.5 * SlotWidth - 22), 32);
            Bar := Pixel(Round(8 + 0.5 * SlotWidth - 22), 32);
            Check((Slot.B > 150) and (Slot.B > Slot.R), Format('the pill sits under the selected tab (%d,%d,%d)',
              [Slot.R, Slot.G, Slot.B]));
            Check((Bar.R < 60) and (Bar.G < 60) and (Bar.B < 70), Format('the bar is dark elsewhere (%d,%d,%d)',
              [Bar.R, Bar.G, Bar.B]));
          end;
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
  TWinUIApp.OnException := TTestWindow.Failed;
  TWinUIApp.Run(TTestWindow);
end.
