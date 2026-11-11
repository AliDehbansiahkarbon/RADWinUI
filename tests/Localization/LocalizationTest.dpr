program LocalizationTest;

{
  Checks the strings of an app in several languages: Strings\<language>\Resources.resw
  next to this program, built into resources.pri by scripts\Build.ps1. x:Uid texts
  in XAML, TWinUIResources.GetString with the fallback to the default language and
  to the default value, TWinUIApp.Language before Run and while the app runs (the
  window's XAML loaded again), right-to-left languages, and the texts of
  RADWinUI.Dialogs from the app's resources. The window opens where
  RADWINUI_TEST_MONITOR puts test windows.
}

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.SysUtils,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Forms,
  RADWinUI.Resources;

const
  ContentXaml =
    '<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' +
    '<TextBlock x:Name="Greeting" x:Uid="Greeting"/>' +
    '<Button x:Name="SaveButton" x:Uid="SaveButton"/>' +
    '<TextBlock x:Name="Fixed" Text="no x:Uid"/>' +
    '</StackPanel>';

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

type
  TTestWindow = class(TWinUIWindow)
  strict private
    FTimer: TWinUITimer;
    FStep: Integer;
    FRoot: TWinUIFrameworkElement;
    procedure Step(Sender: TObject);
    function Text(const AName: string): string;
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
  Width := 480;
  Height := 320;
  FRoot := LoadContent(ContentXaml);
  FTimer := TWinUITimer.Create;
  FTimer.Interval := 200;
  FTimer.OnTimer := Step;
  FTimer.Enabled := True;
end;

destructor TTestWindow.Destroy;
begin
  FTimer.Free;
  inherited;
end;

function TTestWindow.Text(const AName: string): string;
begin
  if AName = 'SaveButton' then
    Result := FindElement<TWinUIButton>(AName).Content.AsString
  else
    Result := FindElement<TWinUITextBlock>(AName).Text;
end;

procedure TTestWindow.Step(Sender: TObject);
begin
  Inc(FStep);
  case FStep of
    1:
      begin
        // Language set before Run: en-US
        Check(TWinUIApp.Language = 'en-US', 'Language set before Run: ' + TWinUIApp.Language);
        Check(Text('Greeting') = 'Hello', 'x:Uid applies Greeting.Text: ' + Text('Greeting'));
        Check(Text('SaveButton') = 'Save', 'x:Uid applies SaveButton.Content: ' + Text('SaveButton'));
        Check(Text('Fixed') = 'no x:Uid', 'an element without x:Uid keeps its text');
        Check(TWinUIResources.GetString('Plain') = 'Plain text', 'GetString reads a plain key');
        Check(TWinUIResources.GetString('Greeting/Text') = 'Hello', 'GetString reads an x:Uid key as Uid/Property');
        Check(TWinUIResources.GetString('NoSuchKey', 'fallback') = 'fallback', 'a missing key gives the default value');
        Check(not TWinUIResources.Has('NoSuchKey') and TWinUIResources.Has('Plain'), 'Has');
        Check(not TWinUIApp.RightToLeft and (FRoot.FlowDirection = TWinUIFlowDirection.LeftToRight),
          'English is left to right');
        // German while the app runs: the strings at once, the window when its XAML loads again
        TWinUIApp.Language := 'de-DE';
        Check(TWinUIResources.GetString('Plain') = 'Einfacher Text', 'GetString follows a new Language at once');
        FRoot := LoadContent(ContentXaml);
      end;
    2:
      begin
        Check(Text('Greeting') = 'Hallo', 'x:Uid in German after the XAML loads again: ' + Text('Greeting'));
        Check(Text('SaveButton') = 'Speichern', 'SaveButton.Content in German: ' + Text('SaveButton'));
        Check(TWinUIResources.GetString('OnlyEnglish') = 'Only in English',
          'a key the language lacks comes from the default language');
        Check(TWinUIResources.GetString('RADWinUI_Cancel', 'Cancel') = 'Abbrechen',
          'RADWinUI.Dialogs texts come from the app''s resources (RADWinUI_Cancel)');
        // Persian: right to left, with the default language's texts where fa-IR has none
        TWinUIApp.Language := 'fa-IR';
        FRoot := LoadContent(ContentXaml);
      end;
    3:
      begin
        Check(TWinUIApp.RightToLeft, 'fa-IR is right to left');
        Check(FRoot.FlowDirection = TWinUIFlowDirection.RightToLeft, 'a right-to-left window lays out from the right');
        Check(Text('Greeting') = #$0633#$0644#$0627#$0645, 'x:Uid in Persian: ' + Text('Greeting'));
        Check(Text('SaveButton') = 'Save', 'a key fa-IR lacks comes from en-US: ' + Text('SaveButton'));
        Check(TWinUIResources.IsRightToLeft('ar-SA') and TWinUIResources.IsRightToLeft('he-IL') and
          not TWinUIResources.IsRightToLeft('de-DE') and not TWinUIResources.IsRightToLeft(''),
          'IsRightToLeft knows Arabic, Hebrew and German');
        // Back to the Windows language
        TWinUIApp.Language := '';
        Check(TWinUIApp.Language <> '', 'Language '''' is the Windows language: ' + TWinUIApp.Language);
        FTimer.Enabled := False;
        Close;
      end;
  end;
end;

begin
  TWinUIApp.OnException := TTestWindow.Failed;
  Writeln('Localization');
  TWinUIApp.Language := 'en-US';
  TWinUIApp.Run(TTestWindow);
  if Failures > 0 then
  begin
    Writeln('Localization test FAILED (', Failures, ')');
    Halt(1);
  end;
  Writeln('Localization test PASSED');
end.
