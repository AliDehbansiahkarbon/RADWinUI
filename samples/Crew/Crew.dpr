program Crew;

{ A team directory: a NavigationView with pages, a page parameter, a page that stays alive, a page that asks before it is left, and a user control used several times. }

uses
  RADWinUI.Forms,
  CrewData in 'CrewData.pas',
  PersonCard.Xaml in 'PersonCard.Xaml.pas',
  PersonCard in 'PersonCard.pas',
  HomePage.Xaml in 'HomePage.Xaml.pas',
  HomePage in 'HomePage.pas',
  PeoplePage.Xaml in 'PeoplePage.Xaml.pas',
  PeoplePage in 'PeoplePage.pas',
  ProfilePage.Xaml in 'ProfilePage.Xaml.pas',
  ProfilePage in 'ProfilePage.pas',
  SettingsPage.Xaml in 'SettingsPage.Xaml.pas',
  SettingsPage in 'SettingsPage.pas',
  MainWindow.Xaml in 'MainWindow.Xaml.pas',
  MainWindow in 'MainWindow.pas';

begin
  ReportMemoryLeaksOnShutdown := True;
  TWinUIApp.Run(TMainWindow);
end.