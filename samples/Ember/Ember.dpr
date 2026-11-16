program Ember;

{ A coffee roastery's app: a dashboard, FireDAC orders in data-aware controls,
  a live roast curve, a mini window, Windows notifications and three languages. }

uses
  Winapi.Windows,
  Winapi.ShellAPI,
  System.SysUtils,
  RADWinUI.Forms,
  EmberData in 'EmberData.pas' {RoasteryData: TDataModule},
  EmberSettings in 'EmberSettings.pas',
  RoastSession in 'RoastSession.pas',
  HomePage.Xaml in 'HomePage.Xaml.pas',
  HomePage in 'HomePage.pas',
  OrdersPage.Xaml in 'OrdersPage.Xaml.pas',
  OrdersPage in 'OrdersPage.pas',
  RoastPage.Xaml in 'RoastPage.Xaml.pas',
  RoastPage in 'RoastPage.pas',
  SettingsPage.Xaml in 'SettingsPage.Xaml.pas',
  SettingsPage in 'SettingsPage.pas',
  MiniRoastWindow.Xaml in 'MiniRoastWindow.Xaml.pas',
  MiniRoastWindow in 'MiniRoastWindow.pas',
  MainWindow.Xaml in 'MainWindow.Xaml.pas',
  MainWindow in 'MainWindow.pas';

var
  Previous: THandle;
  Language: string;
  I: Integer;

begin
  ReportMemoryLeaksOnShutdown := True;
  // Started again in another language: the previous Ember ends first, or it would get this start
  if (ParamCount = 2) and SameText(ParamStr(1), '--after') then
  begin
    Previous := OpenProcess(SYNCHRONIZE, False, StrToIntDef(ParamStr(2), 0));
    if Previous <> 0 then
    begin
      WaitForSingleObject(Previous, 10000);
      CloseHandle(Previous);
    end;
  end;
  // The language picked in Settings, or --lang=de-DE for a quick look
  Language := SavedLanguage;
  for I := 1 to ParamCount do
    if ParamStr(I).StartsWith('--lang=', True) then
      Language := Copy(ParamStr(I), 8, MaxInt);
  TWinUIApp.Language := Language;
  // A click on a notification goes to the running Ember
  TWinUIApp.SingleInstance := True;
  TWinUIApp.OnActivated := TMainWindow.Activated;
  // The data module first, so the pages find its data sources by name
  RoasteryData := TRoasteryData.Create(nil);
  try
    TWinUIApp.Run(TMainWindow);
  finally
    RoasteryData.Free;
  end;
  if RestartEmber then
    ShellExecute(0, nil, PChar(ParamStr(0)), PChar('--after ' + IntToStr(GetCurrentProcessId)), nil, SW_SHOWNORMAL);
end.
