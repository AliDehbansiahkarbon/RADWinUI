program AdvancedControlsTest;

{
  Checks the text fields (RADWinUI.TextFields), swipe actions
  (RADWinUI.SwipeActions), pagers (RADWinUI.Pagination) and progress steps
  (RADWinUI.ProgressSteps): every control loads from XAML with its defaults,
  pages and steps clamp and raise their events, the fields format, score and
  complete what is typed, each swipe does its action from code and raises its
  event, the card stack likes and passes, closing a window frees the
  controls, and the type index lists them all.
  The window opens where RADWINUI_TEST_MONITOR puts test windows.
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
  RADWinUI.TabBars,
  RADWinUI.ActionButtons,
  RADWinUI.DBControls,
  RADWinUI.TextFields,
  RADWinUI.SwipeActions,
  RADWinUI.Pagination,
  RADWinUI.ProgressSteps;

type
  TTestWindow = class(TWinUIWindow)
  private
    FTimer: TWinUITimer;
    FStep: Integer;
    FFailures: Integer;
    FEvents: string;
    FSecond: TWinUIWindow;
    FLiveBefore: Integer;
    procedure Check(AOk: Boolean; const AWhat: string);
    procedure Step(Sender: TObject);
    procedure Note(Sender: TObject; const E: TWinValue);
    function Occurrences(const AName: string): Integer;
  public
    constructor Create; override;
    destructor Destroy; override;
    class procedure Failed(Sender: TObject; E: Exception);
  end;

const
  Namespaces = 'xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:rw="using:RADWinUI.Controls"';

  ContentXaml =
    '<ScrollViewer ' + Namespaces + ' Background="#101018"><StackPanel Spacing="12" Padding="24">' +
    // Text fields
    '<rw:OtpCodeField x:Name="Otp" CodeLength="4" />' +
    '<rw:CardNumberField x:Name="Card" />' +
    '<rw:StrengthMeterField x:Name="Strength" />' +
    '<rw:AutoGrowField x:Name="Grow" />' +
    '<rw:TagInputField x:Name="Tags" Tags="delphi, winui" MaxTags="3" />' +
    '<rw:GhostCompleteField x:Name="Ghost" />' +
    // Swipe actions
    '<rw:SwipeCardStack x:Name="Stack" Items="One|a|Heart; Two|b|Star; Three|c|Home" Loop="False" />' +
    '<rw:PinSwipeList x:Name="Pin" />' +
    '<rw:PeekSwipeList x:Name="Peek" HintInterval="0" />' +
    '<rw:LiquidDeleteList x:Name="Liquid" />' +
    '<rw:SnoozeSwipeList x:Name="Snooze" />' +
    '<rw:UndoSwipeList x:Name="Undo" UndoDuration="600" />' +
    // Pagination
    '<rw:ClassicPager x:Name="Classic" PageCount="10" Page="3" />' +
    '<rw:PillsPager x:Name="Pills" />' +
    '<rw:DotsPager x:Name="Dots" /><rw:BorderedPager x:Name="Bordered" /><rw:TrackPager x:Name="Track" />' +
    '<rw:SegmentedPager x:Name="Segmented" /><rw:ProgressPager x:Name="Progress" />' +
    '<rw:StepsPager x:Name="StepsPager" ShowArrows="False" />' +
    // Progress steps
    '<rw:NumberedSteps x:Name="Numbered" Step="2" />' +
    '<rw:SegmentBarSteps x:Name="Segments" /><rw:CheckoutSteps x:Name="Checkout" />' +
    '<rw:OrderTrackingSteps x:Name="Order" /><rw:BreadcrumbSteps x:Name="Crumbs" />' +
    '<rw:RingSteps x:Name="Ring" Items="One, Two, Three" />' +
    '</StackPanel></ScrollViewer>';

  // One of each, in a window of its own: closing it must free them
  SecondXaml =
    '<StackPanel ' + Namespaces + '>' +
    '<rw:OtpCodeField /><rw:CardNumberField /><rw:StrengthMeterField /><rw:AutoGrowField /><rw:TagInputField />' +
    '<rw:GhostCompleteField /><rw:SwipeCardStack /><rw:PinSwipeList /><rw:PeekSwipeList /><rw:LiquidDeleteList />' +
    '<rw:SnoozeSwipeList /><rw:UndoSwipeList /><rw:ClassicPager /><rw:PillsPager /><rw:DotsPager />' +
    '<rw:BorderedPager /><rw:TrackPager /><rw:SegmentedPager /><rw:ProgressPager /><rw:StepsPager />' +
    '<rw:NumberedSteps /><rw:SegmentBarSteps /><rw:CheckoutSteps /><rw:OrderTrackingSteps />' +
    '<rw:BreadcrumbSteps /><rw:RingSteps /></StackPanel>';
  SecondCount = 26;

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
  Title := 'Advanced controls test';
  Width := 480;
  Height := 900;
  Writeln('Text fields, swipe actions, pagination and progress steps');
  LoadContent(ContentXaml);
  Check(True, 'XAML with all 26 controls loads');
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

procedure TTestWindow.Note(Sender: TObject; const E: TWinValue);
begin
  // Every event lands here: the class says which control raised it
  FEvents := FEvents + Sender.ClassName.Substring(Length('TWinUI')) + ' ';
end;

function TTestWindow.Occurrences(const AName: string): Integer;
var
  Name: string;
begin
  Result := 0;
  for Name in FEvents.Trim.Split([' ']) do
    if Name = AName then
      Inc(Result);
end;

procedure TTestWindow.Step(Sender: TObject);
var
  Otp: TWinUIOtpCodeField;
  Card: TWinUICardNumberField;
  Strength: TWinUIStrengthMeterField;
  Grow: TWinUIAutoGrowField;
  Tags: TWinUITagInputField;
  Ghost: TWinUIGhostCompleteField;
  Stack: TWinUISwipeCardStack;
  Pin: TWinUIPinSwipeList;
  Peek: TWinUIPeekSwipeList;
  Liquid: TWinUILiquidDeleteList;
  Snooze: TWinUISnoozeSwipeList;
  Undo: TWinUIUndoSwipeList;
  Classic: TWinUIClassicPager;
  Pills: TWinUIPillsPager;
  StepsPager: TWinUIStepsPager;
  Numbered: TWinUINumberedSteps;
  Order: TWinUIOrderTrackingSteps;
  Ring: TWinUIRingSteps;
  Json: string;
begin
  Inc(FStep);
  try
    Otp := FindElement<TWinUIOtpCodeField>('Otp');
    Card := FindElement<TWinUICardNumberField>('Card');
    Strength := FindElement<TWinUIStrengthMeterField>('Strength');
    Grow := FindElement<TWinUIAutoGrowField>('Grow');
    Tags := FindElement<TWinUITagInputField>('Tags');
    Ghost := FindElement<TWinUIGhostCompleteField>('Ghost');
    Stack := FindElement<TWinUISwipeCardStack>('Stack');
    Pin := FindElement<TWinUIPinSwipeList>('Pin');
    Peek := FindElement<TWinUIPeekSwipeList>('Peek');
    Liquid := FindElement<TWinUILiquidDeleteList>('Liquid');
    Snooze := FindElement<TWinUISnoozeSwipeList>('Snooze');
    Undo := FindElement<TWinUIUndoSwipeList>('Undo');
    Classic := FindElement<TWinUIClassicPager>('Classic');
    Pills := FindElement<TWinUIPillsPager>('Pills');
    StepsPager := FindElement<TWinUIStepsPager>('StepsPager');
    Numbered := FindElement<TWinUINumberedSteps>('Numbered');
    Order := FindElement<TWinUIOrderTrackingSteps>('Order');
    Ring := FindElement<TWinUIRingSteps>('Ring');
    case FStep of
      1:
        begin
          Check((Otp <> nil) and (Card <> nil) and (Strength <> nil) and (Grow <> nil) and (Tags <> nil) and
            (Ghost <> nil), 'FindElement returns each text field');
          Check((Stack <> nil) and (Pin <> nil) and (Peek <> nil) and (Liquid <> nil) and (Snooze <> nil) and
            (Undo <> nil), 'FindElement returns each swipe action');
          Check((Classic <> nil) and (Pills <> nil) and (StepsPager <> nil) and (Numbered <> nil) and (Order <> nil) and
            (Ring <> nil), 'FindElement returns the pagers and progress steps');
          // Defaults and XAML values
          Check((Otp.CodeLength = 4) and Otp.AutoVerify and (Otp.Header = 'Enter the code we sent'),
            'OTP: CodeLength from XAML, default header and AutoVerify');
          Check((Card.Header = 'Card') and (Strength.Header = 'New password') and (Tags.Header = 'Topics') and
            (Ghost.Header = 'Email'), 'text fields: default headers');
          Check((Grow.MaxLines = 6) and Grow.ShowSendButton, 'Auto Grow: default MaxLines and send button');
          Check(Tags.TagCount = 2, Format('Tag Input: two tags from XAML (%d)', [Tags.TagCount]));
          Check((Classic.PageCount = 10) and (Classic.Page = 3) and Classic.ShowArrows,
            'Classic pager: PageCount and Page from XAML');
          Check((Pills.PageCount = 9) and (Pills.Page = 1), 'Pills pager: nine pages by default');
          Check(not StepsPager.ShowArrows, 'Steps pager: ShowArrows from XAML');
          Check((Numbered.Step = 2) and (Numbered.ItemCount = 4), 'Numbered steps: Step from XAML, four default steps');
          Check((Order.Title = 'Order #2048') and (Order.ItemCount = 4), 'Order tracking: default title and stops');
          Check(Ring.ItemCount = 3, 'Ring steps: Items from XAML');
          Check((Pin.RowName(0) = 'Leo Cruz') and (Pin.RowName(2) = 'Mia Park'), 'swipe list: default rows');
          Check(Stack.CurrentTitle = 'One', 'card stack: the first card is on top');
          Check((Abs(Pin.ActualWidth - 320) < 1) and (Abs(Classic.ActualHeight) > 1),
            Format('swipe list has its default width (%.0f)', [Pin.ActualWidth]));
          // Clamping: the page and step stay in range
          Classic.Page := 99;
          Check(Classic.Page = 10, 'Page clamps to PageCount');
          Classic.Page := 0;
          Check(Classic.Page = 1, 'Page clamps to 1');
          Numbered.Step := 99;
          Check((Numbered.Step = 5) and Numbered.IsComplete, 'Step clamps to all done (Count + 1)');
          Numbered.Step := 2;
          Check(not Numbered.IsComplete, 'Step 2 is not complete');
          // Events
          Classic.OnPageChanged := Note;
          Numbered.OnStepChanged := Note;
          Classic.NextPage;
          Classic.NextPage;
          Classic.PreviousPage;
          Check(Classic.Page = 2, Format('NextPage twice and PreviousPage (%d)', [Classic.Page]));
          Numbered.Next;
          Numbered.Back;
          Numbered.Back;
          Numbered.Back;
          Check(Numbered.Step = 1, 'Back stops at the first step');
          Check(FEvents = 'ClassicPager ClassicPager ClassicPager NumberedSteps NumberedSteps NumberedSteps ',
            'PageChanged and StepChanged fire once per change (' + FEvents.Trim + ')');
          FEvents := '';
          // The password score
          Check((TWinUIStrengthMeterField.PasswordScore('') = 0) and
            (TWinUIStrengthMeterField.PasswordScore('abc') = 1) and
            (TWinUIStrengthMeterField.PasswordScore('Coffee2026!roast') = 4),
            'PasswordScore: empty 0, short 1, long and mixed 4');
          // Typing from code
          Otp.OnCompleted := Note;
          Card.OnCompleted := Note;
          Ghost.OnAccepted := Note;
          Otp.Text := '1234';
          Card.Text := '4242424242424242';
          Card.Expiry := '12/28';
          Card.Cvc := '123';
          Strength.Text := 'Coffee2026!roast';
          Ghost.Text := 'ali@gm';
          Tags.Tags := 'one, two, three';
          // Swipes from code
          Pin.OnPinned := Note;
          Peek.OnDeleted := Note;
          Liquid.OnDeleted := Note;
          Snooze.OnSnoozed := Note;
          Undo.OnDeleted := Note;
          Undo.OnRestored := Note;
          Stack.OnLiked := Note;
          Stack.OnPassed := Note;
          Pin.SwipeRow(2);
          Check((Pin.ActionName = 'Mia Park') and (Pin.RowName(0) = 'Mia Park') and
            Pin.Items.StartsWith('Mia Park|'), 'Pin: the pinned row jumps to the top (' + Pin.Items + ')');
          Snooze.SwipeRow(0);
          Snooze.SwipeRow(0);
          Check(Snooze.SnoozeOf(0) = '3h', 'Snooze: each swipe from code takes the next time (' + Snooze.SnoozeOf(0) + ')');
          Liquid.SwipeRow(0);
          Peek.SwipeRow(1);
          Peek.SwipeRow(1);
          Undo.SwipeRow(0);
          Undo.Undo(0);
          Undo.SwipeRow(1);
          Stack.Like;
          // A new window with one of each control: closing it must free them
          FLiveBefore := TWinUICustomControls.LiveCount;
          FSecond := TWinUIWindow.Create;
          FSecond.LoadContent(SecondXaml);
          FSecond.Show;
          Check(TWinUICustomControls.LiveCount = FLiveBefore + SecondCount,
            Format('a loaded window has its %d controls (%d -> %d)', [SecondCount, FLiveBefore,
            TWinUICustomControls.LiveCount]));
        end;
      2:
        begin
          // About 500 ms later: the text boxes and the springs had their time
          Check(Otp.IsVerified, 'OTP: AutoVerify checks a full code');
          Check(Card.IsComplete, 'Card: number, expiry and CVC are complete');
          Check(Strength.Score = 4, Format('Strength: the score follows the text (%d)', [Strength.Score]));
          Check(Ghost.Suggestion = 'ail.com', 'Ghost: suggests the rest of gmail.com (' + Ghost.Suggestion + ')');
          Check(Tags.TagCount = 3, Format('Tag Input: Tags from code make the chips (%d)', [Tags.TagCount]));
          Check(Stack.CurrentTitle = 'Two', 'card stack: after Like the next card is on top (' + Stack.CurrentTitle + ')');
          Stack.Pass;
          FSecond.Close;
        end;
      4:
        begin
          // About 1.5 s after the swipes: removed rows are gone, the Undo time is up
          Check(Liquid.Items.StartsWith('Ava Stone|') and (Liquid.RowName(2) = ''),
            'Liquid Delete: the row popped away (' + Liquid.Items + ')');
          Check(Peek.RowName(1) = 'Mia Park', 'Peek: the second swipe deletes the open row');
          Check((Undo.RowName(0) = 'Leo Cruz') and (Undo.RowName(1) = 'Mia Park'),
            'Undo: Undo brings the row back, the other one is gone after UndoDuration');
          Check(Stack.CurrentTitle = 'Three', 'card stack: after Pass the third card is on top');
          // The timed events come in any order: count them
          Check((Occurrences('OtpCodeField') = 1) and (Occurrences('CardNumberField') = 1) and
            (Occurrences('PinSwipeList') = 1) and (Occurrences('SnoozeSwipeList') = 2) and
            (Occurrences('LiquidDeleteList') = 1) and (Occurrences('PeekSwipeList') = 1) and
            (Occurrences('UndoSwipeList') = 2) and (Occurrences('SwipeCardStack') = 2),
            'each control raised its events (' + FEvents.Trim + ')');
          Check(TWinUICustomControls.LiveCount = FLiveBefore, Format('closing a window frees its controls (%d left)',
            [TWinUICustomControls.LiveCount]));
          Json := TWinUICustomControls.TypeIndexJson;
          Check(Json.Contains('"RADWinUI.Controls.OtpCodeField"') and Json.Contains('"Text Fields"') and
            Json.Contains('"Swipe Actions"') and Json.Contains('"Pagination"') and Json.Contains('"Progress Steps"') and
            Json.Contains('"unit": "RADWinUI.SwipeActions"') and Json.Contains('"wrapper": "TWinUIRingSteps"'),
            'type index lists the new controls, their units and wrappers');
          Check((ControlsJsonPath <> '') and (TFile.ReadAllText(ControlsJsonPath, TEncoding.UTF8) = Json),
            'src\Framework\RADWinUI.Controls.json is up to date (tools\ControlsIndex writes it)');
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
