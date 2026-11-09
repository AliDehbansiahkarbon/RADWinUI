program PagesTest;

{
  Checks RADWinUI.Pages and user controls made with XamlCodeGen: a frame inside
  a NavigationView navigates between generated pages, with a parameter, back
  and forward, a page that stays alive (KeepAlive), a page that refuses to be
  left until it lets the navigation proceed, the selection of the NavigationView
  and its back button, and a user control used twice on a page, with a
  property set in XAML and an event wired to the page. Pages that are left are
  freed. The window opens where RADWINUI_TEST_MONITOR puts test windows and
  never takes the focus.
}

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.SysUtils,
  RADWinUI.Interop.Core,
  RADWinUI.Abi,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Forms,
  RADWinUI.Pages,
  PagesTestState in 'PagesTestState.pas',
  InfoCard.Xaml in 'InfoCard.Xaml.pas',
  InfoCard in 'InfoCard.pas',
  FirstPage.Xaml in 'FirstPage.Xaml.pas',
  FirstPage in 'FirstPage.pas',
  SecondPage.Xaml in 'SecondPage.Xaml.pas',
  SecondPage in 'SecondPage.pas',
  CachedPage.Xaml in 'CachedPage.Xaml.pas',
  CachedPage in 'CachedPage.pas',
  GuardPage.Xaml in 'GuardPage.Xaml.pas',
  GuardPage in 'GuardPage.pas';

var
  Failures: Integer;

procedure Check(AOk: Boolean; const AWhat: string);
begin
  if AOk then
    Writeln('  [ok] ', AWhat)
  else
  begin
    Writeln('  [failed] ', AWhat);
    Inc(Failures);
  end;
  Flush(Output);
end;

function LastEvent: string;
begin
  if Length(Events) = 0 then
    Result := ''
  else
    Result := Events[High(Events)];
end;

function Names(const AClasses: TArray<TWinUIXamlPageClass>): string;
var
  C: TWinUIXamlPageClass;
begin
  Result := '';
  for C in AClasses do
    Result := Result + C.ClassName + ' ';
  Result := Result.Trim;
end;

type
  TTestWindow = class(TWinUIWindow)
  private
    FTimer: TWinUITimer;
    FStep: Integer;
    FNav: TWinUINavigationView;
    FFrame: TWinUIPageFrame;
    FCached: TCachedPage;
    procedure Step(Sender: TObject);
    function SelectedTag: string;
  public
    constructor Create; override;
    destructor Destroy; override;
    class procedure Failed(Sender: TObject; E: Exception);
  end;

class procedure TTestWindow.Failed(Sender: TObject; E: Exception);
begin
  Writeln('  [failed] ', E.ClassName, ': ', E.Message);
  Flush(Output);
  ExitProcess(1);
end;

constructor TTestWindow.Create;
begin
  inherited;
  Title := 'PagesTest';
  Width := 800;
  Height := 600;
  ShowActivated := False;
  LoadContent(
    '<NavigationView xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="Nav" IsSettingsVisible="False">' +
    '<NavigationView.MenuItems>' +
    '<NavigationViewItem Content="First" Tag="TFirstPage"/>' +
    '<NavigationViewItem Content="Second" Tag="TSecondPage"/>' +
    '</NavigationView.MenuItems>' +
    '<Frame x:Name="PageFrame"/>' +
    '</NavigationView>');
  FNav := FindElement<TWinUINavigationView>('Nav');
  FFrame := FindElement<TWinUIPageFrame>('PageFrame');
  FFrame.AttachNavigationView(FNav, [TFirstPage, TSecondPage]);
  FTimer := TWinUITimer.Create;
  FTimer.Interval := 250;
  FTimer.OnTimer := Step;
  FTimer.Enabled := True;
end;

destructor TTestWindow.Destroy;
begin
  FTimer.Free;
  inherited;
end;

function TTestWindow.SelectedTag: string;
var
  Element: IFrameworkElement;
begin
  if Supports(FNav.SelectedItem.Obj, IFrameworkElement, Element) then
    Result := TWinValue(Element.Tag).AsString
  else
    Result := '';
end;

procedure TTestWindow.Step(Sender: TObject);
var
  First: TFirstPage;
begin
  Inc(FStep);
  case FStep of
    1:
      begin
        FFrame.Navigate(TFirstPage);
        Check((FFrame.CurrentPage is TFirstPage) and (LastEvent = 'First:New'), 'Navigate shows the page, NavigatedTo New');
        Check(not FFrame.CanGoBack and not FNav.IsBackEnabled, 'nothing to go back to, back button disabled');
      end;
    2:
      begin
        First := FFrame.CurrentPage as TFirstPage;
        Check((First.FindElement<TInfoCard>('CardOne') <> nil) and
          (First.FindElement<TInfoCard>('CardOne').Title = 'One') and
          (First.FindElement<TInfoCard>('CardTwo').ShownTitle = 'Two'),
          'a user control used twice, its XAML property reaches its own content');
        First.FindElement<TInfoCard>('CardOne').Click;
        First.FindElement<TInfoCard>('CardTwo').Click;
        Check(CardClicks = 2, 'the user control event is wired to the page handler');
        Check(SelectedTag = 'TFirstPage', 'the NavigationView selects the current page');
        FFrame.Navigate(TSecondPage, 'hello');
        Check(LastEvent = 'Second:New:hello', 'the parameter reaches NavigatedTo');
        Check((Names(FFrame.BackStack) = 'TFirstPage') and FNav.IsBackEnabled, 'back stack and back button');
      end;
    3:
      begin
        Check(LivePages = 1, 'the page that was left is freed');
        Check(SelectedTag = 'TSecondPage', 'the selection follows navigation');
        FFrame.GoBack;
        Check((FFrame.CurrentPage is TFirstPage) and (LastEvent = 'First:Back'), 'GoBack creates the page again, Back');
        Check(FFrame.CanGoForward and not FFrame.CanGoBack, 'forward stack after GoBack');
        Check(SelectedTag = 'TFirstPage', 'the selection follows GoBack');
      end;
    4:
      begin
        FFrame.GoForward;
        Check(LastEvent = 'Second:Forward:hello', 'GoForward keeps the parameter');
        FFrame.Navigate(TCachedPage);
        FCached := FFrame.CurrentPage as TCachedPage;
        FCached.Count := 5;
        FFrame.Navigate(TFirstPage);
        Check(not FFrame.CanGoForward, 'Navigate clears the forward stack');
      end;
    5:
      begin
        FFrame.Navigate(TCachedPage);
        Check((FFrame.CurrentPage = FCached) and (FCached.Count = 5), 'a KeepAlive page comes back with its state');
        FFrame.Navigate(TGuardPage);
        Check(SelectedTag = '', 'a page without a menu item leaves no item selected');
        (FFrame.CurrentPage as TGuardPage).Dirty := True;
        FFrame.Navigate(TFirstPage);
        Check((FFrame.CurrentPage is TGuardPage) and (LastEvent = 'Guard:cancelled'), 'NavigatingFrom can cancel');
        Check(Names(FFrame.BackStack) = 'TFirstPage TSecondPage TCachedPage TFirstPage TCachedPage',
          'a cancelled navigation leaves the back stack alone: ' + Names(FFrame.BackStack));
        FFrame.GoBack;
        Check(FFrame.CurrentPage is TGuardPage, 'GoBack is cancelled too');
        PendingProceed;
        Check((FFrame.CurrentPage is TCachedPage), 'Proceed runs the cancelled navigation without asking again');
      end;
    6:
      begin
        PendingProceed; // the guard page is gone: nothing happens
        Check(FFrame.CurrentPage is TCachedPage, 'Proceed does nothing once its page is no longer shown');
        Check(LivePages = 1, 'only the KeepAlive page is alive: ' + IntToStr(LivePages));
        FFrame.ClearBackStack;
        Check(not FFrame.CanGoBack and not FNav.IsBackEnabled, 'ClearBackStack');
        FTimer.Enabled := False;
        Close;
      end;
  end;
end;

begin
  ReportMemoryLeaksOnShutdown := GetEnvironmentVariable('RADWINUI_TEST_MONITOR') = '';
  Writeln('PagesTest');
  TWinUIApp.OnException := TTestWindow.Failed;
  TWinUIApp.Run(TTestWindow);
  Check(LivePages = 0, 'the frame frees its pages with the window');
  if Failures = 0 then
    Writeln('PASSED')
  else
    Writeln(Format('FAILED: %d', [Failures]));
  ExitCode := Ord(Failures > 0);
end.
