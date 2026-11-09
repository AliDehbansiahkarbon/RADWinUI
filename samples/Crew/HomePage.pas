unit HomePage;

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Pages,
  HomePage.Xaml;

type
  THomePage = class(THomePageBase)   // generated from HomePage.xaml
  protected
    procedure NavigatedTo(const AArgs: TWinUINavigationArgs); override;
  published
    procedure CardOpened(Sender: TObject; const E: TWinValue);
    procedure EveryoneClick(Sender: TObject);
  end;

implementation

uses
  System.SysUtils,
  CrewData,
  PersonCard,
  PeoplePage,
  ProfilePage;

procedure THomePage.NavigatedTo(const AArgs: TWinUINavigationArgs);
begin
  Summary.Text := Format('%d people in the crew. Open a card to see a profile, or find someone on the People page.',
    [People.Count]);
end;

procedure THomePage.CardOpened(Sender: TObject; const E: TWinValue);
var
  Person: TPerson;
begin
  // The person goes to the profile page as the navigation parameter
  Person := FindPerson((Sender as TPersonCard).PersonName);
  if Person <> nil then
    Frame.Navigate(TProfilePage, Person);
end;

procedure THomePage.EveryoneClick(Sender: TObject);
begin
  Frame.Navigate(TPeoplePage);
end;

end.