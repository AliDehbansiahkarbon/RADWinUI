unit PeoplePage;

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Binding,
  RADWinUI.Pages,
  CrewData,
  PeoplePage.Xaml;

type
  TPeoplePage = class(TPeoplePageBase)   // generated from PeoplePage.xaml
  private
    FShown: TWinUIBindableList<TPerson>;
    procedure Filter;
  protected
    procedure NavigatedTo(const AArgs: TWinUINavigationArgs); override;
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    procedure SearchChanged(Sender: TObject; E: TWinUITextChangedEventArgs);
    procedure PersonClick(Sender: TObject; E: TWinUIItemClickEventArgs);
  end;

implementation

uses
  System.SysUtils,
  ProfilePage;

constructor TPeoplePage.Create;
begin
  inherited;
  // The frame keeps this page: the search and the scroll position survive a visit to a profile
  KeepAlive := True;
  FShown := TWinUIBindableList<TPerson>.Create(False);
  PeopleList.ItemsSource := FShown;
  Filter;
end;

destructor TPeoplePage.Destroy;
begin
  FShown.Free;
  inherited;
end;

procedure TPeoplePage.NavigatedTo(const AArgs: TWinUINavigationArgs);
begin
  // A name may have changed on the profile page
  Filter;
end;

procedure TPeoplePage.Filter;
var
  I: Integer;
  Text: string;
begin
  Text := Trim(SearchBox.Text);
  FShown.Clear;
  for I := 0 to People.Count - 1 do
    if (Text = '') or People[I].Name.ToLower.Contains(Text.ToLower) or People[I].Role.ToLower.Contains(Text.ToLower) then
      FShown.Add(People[I]);
  if FShown.Count = 1 then
    CountText.Text := '1 person'
  else
    CountText.Text := Format('%d people', [FShown.Count]);
end;

procedure TPeoplePage.SearchChanged(Sender: TObject; E: TWinUITextChangedEventArgs);
begin
  Filter;
end;

procedure TPeoplePage.PersonClick(Sender: TObject; E: TWinUIItemClickEventArgs);
var
  Clicked: IInterface;
  I: Integer;
begin
  // The clicked item is the WinRT object XAML sees, so compare COM identities
  Clicked := E.ClickedItem.Obj as IInterface;
  for I := 0 to FShown.Count - 1 do
    if (FShown.BindableAt(I) as IInterface) = Clicked then
    begin
      Frame.Navigate(TProfilePage, FShown[I]);
      Exit;
    end;
end;

end.