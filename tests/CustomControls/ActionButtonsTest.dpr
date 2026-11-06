program ActionButtonsTest;

{
  Checks the action buttons (RADWinUI.ActionButtons): every button loads
  from XAML with its defaults, Play runs each effect and raises its event,
  Hold and Slide end on a check, Send and Copy come back after ResetAfter,
  Copy puts its text on the clipboard, Confetti's pieces fly and land,
  the Send pill paints its gradient, and closing a window frees its buttons.
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
  RADWinUI.ActionButtons;

type
  TTestWindow = class(TWinUIWindow)
  private
    FTimer: TWinUITimer;
    FStep: Integer;
    FFailures: Integer;
    FEvents: string;
    FSecond: TWinUIWindow;
    FLiveBefore: Integer;
    FPixels: TBytes;
    FPixelWidth: Integer;
    FRendered: Boolean;
    procedure Check(AOk: Boolean; const AWhat: string);
    procedure RenderSend;
    function Pixel(AX, AY: Integer): TWinUIColor;
    procedure Step(Sender: TObject);
    procedure HoldConfirmed(Sender: TObject; const E: TWinValue);
    procedure SendClick(Sender: TObject; const E: TWinValue);
    procedure ConfettiClick(Sender: TObject; const E: TWinValue);
    procedure Copied(Sender: TObject; const E: TWinValue);
    procedure ShineClick(Sender: TObject; const E: TWinValue);
    procedure SlideConfirmed(Sender: TObject; const E: TWinValue);
  public
    constructor Create; override;
    destructor Destroy; override;
    class procedure Failed(Sender: TObject; E: Exception);
  end;

const
  Namespaces = 'xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:rw="using:RADWinUI.Controls"';

  ContentXaml =
    '<StackPanel ' + Namespaces + ' Spacing="16" Padding="40" Background="#101018">' +
    '<rw:HoldButton x:Name="Hold" ResetAfter="0" />' +
    '<rw:SendButton x:Name="Send" ResetAfter="300" />' +
    '<rw:ConfettiButton x:Name="Confetti" ConfettiCount="30" />' +
    '<rw:CopyButton x:Name="Copy" Text="radwinui.dev/abc" ResetAfter="400" />' +
    '<rw:ShineButton x:Name="Shine" Width="220" ShineInterval="0" />' +
    '<rw:SlideButton x:Name="Slide" ResetAfter="0" DoneText="Done" />' +
    '</StackPanel>';

  SecondXaml =
    '<StackPanel ' + Namespaces + '>' +
    '<rw:HoldButton /><rw:SendButton /><rw:ConfettiButton />' +
    '<rw:CopyButton /><rw:ShineButton /><rw:SlideButton /></StackPanel>';

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

function ClipboardText: string;
var
  Data: THandle;
begin
  Result := '';
  if not OpenClipboard(0) then
    Exit;
  try
    Data := GetClipboardData(CF_UNICODETEXT);
    if Data <> 0 then
    begin
      Result := PChar(GlobalLock(Data));
      GlobalUnlock(Data);
    end;
  finally
    CloseClipboard;
  end;
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
  Title := 'Action buttons test';
  Width := 420;
  Height := 760;
  Writeln('Action buttons');
  LoadContent(ContentXaml);
  Check(True, 'XAML with all six action buttons loads');
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

procedure TTestWindow.HoldConfirmed(Sender: TObject; const E: TWinValue);
begin
  FEvents := FEvents + 'hold ';
end;

procedure TTestWindow.SendClick(Sender: TObject; const E: TWinValue);
begin
  FEvents := FEvents + 'send ';
end;

procedure TTestWindow.ConfettiClick(Sender: TObject; const E: TWinValue);
begin
  FEvents := FEvents + 'confetti ';
end;

procedure TTestWindow.Copied(Sender: TObject; const E: TWinValue);
begin
  FEvents := FEvents + 'copy ';
end;

procedure TTestWindow.ShineClick(Sender: TObject; const E: TWinValue);
begin
  FEvents := FEvents + 'shine ';
end;

procedure TTestWindow.SlideConfirmed(Sender: TObject; const E: TWinValue);
begin
  FEvents := FEvents + 'slide ';
end;

type
  // Windows.Storage.Streams.IBufferByteAccess: the bytes of a WinRT buffer
  IBufferByteAccess = interface(IUnknown)
    ['{905A0FEF-BC53-11DF-8C49-001E4FC686DA}']
    function Buffer(out AValue: PByte): HRESULT; stdcall;
  end;

const
  SendWidth = 168;

procedure TTestWindow.RenderSend;
var
  Target: TWinUIRenderTargetBitmap;
begin
  Target := TWinUIRenderTargetBitmap.Create(Self);
  Target.RenderAsync(FindElement<TWinUISendButton>('Send')).Completed := TAsyncActionCompletedHandler.Create(
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

// A pixel of the picture, AX and AY in effective pixels of the button
function TTestWindow.Pixel(AX, AY: Integer): TWinUIColor;
var
  Scale: Double;
  Offset: Integer;
begin
  Scale := FPixelWidth / SendWidth;
  Offset := (Round(AY * Scale) * FPixelWidth + Round(AX * Scale)) * 4;
  // Blue, green, red, alpha
  Result.B := FPixels[Offset];
  Result.G := FPixels[Offset + 1];
  Result.R := FPixels[Offset + 2];
  Result.A := FPixels[Offset + 3];
end;

procedure TTestWindow.Step(Sender: TObject);
var
  Hold: TWinUIHoldButton;
  Send: TWinUISendButton;
  Confetti: TWinUIConfettiButton;
  Copy: TWinUICopyButton;
  Shine: TWinUIShineButton;
  Slide: TWinUISlideButton;
  Json: string;
  Left, Right: TWinUIColor;
begin
  Inc(FStep);
  try
    Hold := FindElement<TWinUIHoldButton>('Hold');
    Send := FindElement<TWinUISendButton>('Send');
    Confetti := FindElement<TWinUIConfettiButton>('Confetti');
    Copy := FindElement<TWinUICopyButton>('Copy');
    Shine := FindElement<TWinUIShineButton>('Shine');
    Slide := FindElement<TWinUISlideButton>('Slide');
    case FStep of
      1:
        begin
          Check((Hold <> nil) and (Send <> nil) and (Confetti <> nil) and (Copy <> nil) and (Shine <> nil) and
            (Slide <> nil), 'FindElement returns each action button');
          Check((Hold.Text = 'Hold to delete') and (Hold.DoneText = 'Deleted') and (Hold.Icon = 'Delete') and
            (Hold.HoldDuration = 1200), 'Hold: default texts, icon and duration');
          Check((Send.Text = 'Send') and (Send.DoneText = 'Sent!') and (Send.ResetAfter = 300),
            'Send: default texts, ResetAfter from XAML');
          Check((Confetti.Text = 'Celebrate') and (Confetti.ConfettiCount = 30), 'Confetti: default text, count from XAML');
          Check((Copy.Text = 'radwinui.dev/abc') and (Copy.DoneText = 'Copied!') and Copy.CopyToClipboard,
            'Copy: text from XAML, default tooltip');
          Check((Shine.Text = 'Upgrade to Pro') and Shine.Sparkles and (Shine.ShineInterval = 0),
            'Shine: default text and sparkles, interval from XAML');
          Check((Slide.Text = 'Slide to confirm') and (Slide.DoneText = 'Done') and Slide.Shimmer,
            'Slide: default text, DoneText from XAML');
          Check((Abs(Hold.ActualWidth - 120) < 1) and (Abs(Hold.ActualHeight - 104) < 1),
            Format('Hold has its default size (%.0f x %.0f)', [Hold.ActualWidth, Hold.ActualHeight]));
          Check((Abs(Shine.ActualWidth - 220) < 1) and (Abs(Slide.ActualWidth - 260) < 1),
            Format('XAML width and default width (%.0f, %.0f)', [Shine.ActualWidth, Slide.ActualWidth]));
          Check(not Hold.IsDone and not Send.IsDone and not Copy.IsDone and not Slide.IsDone,
            'nothing is done before it is used');
          Hold.OnConfirmed := HoldConfirmed;
          Send.OnClick := SendClick;
          Confetti.OnClick := ConfettiClick;
          Copy.OnCopied := Copied;
          Shine.OnClick := ShineClick;
          Slide.OnConfirmed := SlideConfirmed;
          Hold.Play;
          Send.Play;
          Confetti.Play;
          Copy.Play;
          Shine.Play;
          Slide.Play;
          Check(FEvents = 'hold send confetti copy shine ', 'Play raises each event at once (' + FEvents.Trim +
            '), Slide only at the end of its slide');
          Check(Hold.IsDone and (Hold.Progress = 1), 'Hold: Play completes the hold');
          Check(Send.IsDone, 'Send: sent');
          Check(Confetti.FlyingCount = 30, Format('Confetti: ConfettiCount pieces fly (%d)', [Confetti.FlyingCount]));
          Check(Copy.IsDone and (ClipboardText = 'radwinui.dev/abc'), 'Copy: the text is on the clipboard');
          Check(not Slide.IsDone, 'Slide: still sliding');
          // A second Play while it is still sending does nothing
          Send.Play;
          // A new window with every button: closing it must free them
          FLiveBefore := TWinUICustomControls.LiveCount;
          FSecond := TWinUIWindow.Create;
          FSecond.LoadContent(SecondXaml);
          FSecond.Show;
          Check(TWinUICustomControls.LiveCount = FLiveBefore + 6, Format('a loaded window has its 6 buttons (%d -> %d)',
            [FLiveBefore, TWinUICustomControls.LiveCount]));
        end;
      2:
        begin
          // About 500 ms after Play
          Check(Hold.IsDone, 'Hold: ResetAfter 0 keeps the check');
          FSecond.Close;
        end;
      3:
        begin
          // About 1 s after Play
          Check(Slide.IsDone and (Abs(Slide.Position - 1) < 0.001) and FEvents.EndsWith('slide '),
            Format('Slide: the knob reached the end and Confirmed fired (%.3f, %s)', [Slide.Position, FEvents.Trim]));
          Check(Length(FEvents.Trim.Split([' '])) = 6, 'a second Play while sending is ignored (' + FEvents.Trim + ')');
          Check(not Send.IsDone, 'Send: back after ResetAfter');
          Check(not Copy.IsDone, 'Copy: back after ResetAfter');
          Check(Confetti.FlyingCount > 0, Format('Confetti: pieces still falling after 1 s (%d)', [Confetti.FlyingCount]));
          Check(TWinUICustomControls.LiveCount = FLiveBefore, Format('closing a window frees its buttons (%d left, ' +
            '%d XAML elements)', [TWinUICustomControls.LiveCount, TWinUICustomControls.HostCount]));
          Json := TWinUICustomControls.TypeIndexJson;
          Check(Json.Contains('"RADWinUI.Controls.SlideButton"') and Json.Contains('"Action Buttons"') and
            Json.Contains('"unit": "RADWinUI.ActionButtons"') and Json.Contains('"wrapper": "TWinUIHoldButton"'),
            'type index lists the action buttons, their unit and wrappers');
          Check((ControlsJsonPath <> '') and (TFile.ReadAllText(ControlsJsonPath, TEncoding.UTF8) = Json),
            'src\Framework\RADWinUI.Controls.json is up to date (tools\ControlsIndex writes it)');
          Hold.Reset;
          Slide.Reset;
          Check(not Hold.IsDone and (Hold.Progress = 0), 'Hold: Reset');
          Check(not Slide.IsDone and (Slide.Position = 0), 'Slide: Reset');
          Copy.CopyToClipboard := False;
          Copy.Text := 'not copied';
          Copy.Play;
          Check(ClipboardText = 'radwinui.dev/abc', 'Copy: CopyToClipboard False leaves the clipboard alone');
          Hold.Text := 'Hold';
          Hold.Icon := 'E74D';
          Slide.Shimmer := False;
          Shine.Sparkles := False;
          Shine.AccentTo := TWinUISolidColorBrush.Create(Self);
        end;
      5:
        // About 2.5 s after Play
        Check(Confetti.FlyingCount = 0, Format('Confetti: every piece has landed (%d)', [Confetti.FlyingCount]));
      6:
        RenderSend;
      8:
        begin
          Check(FRendered, 'the Send button renders');
          if FRendered then
          begin
            // Left and right end of the pill: violet, then the blue end of the gradient
            Left := Pixel(14, 24);
            Right := Pixel(SendWidth - 14, 24);
            Check((Left.B > 150) and (Left.R > Left.G), Format('the pill starts violet (%d,%d,%d)',
              [Left.R, Left.G, Left.B]));
            Check((Right.B > 150) and (Right.G > Left.G), Format('and ends blue (%d,%d,%d)', [Right.R, Right.G, Right.B]));
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
