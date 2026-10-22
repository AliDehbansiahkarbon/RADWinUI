unit ContactsWindow;

interface

uses
  System.SysUtils,
  RADWinUI.Xaml,
  RADWinUI.Binding,
  ContactsWindow.Xaml;

type
  // Published properties are what {Binding Name} and {Binding Email} read.
  {$M+}
  TContact = class
  private
    FName: string;
    FEmail: string;
  public
    constructor Create(const AName, AEmail: string);
    function ToString: string; override;
  published
    property Name: string read FName write FName;
    property Email: string read FEmail write FEmail;
  end;
  {$M-}

  TContactsWindow = class(TContactsWindowBase)   // generated from ContactsWindow.xaml
  private
    FContacts: TWinUIBindableList<TContact>;
    procedure UpdateStatus;
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    procedure AddClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure RenameClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure RemoveClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure ContactListSelectionChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
  end;

implementation

{ TContact }

constructor TContact.Create(const AName, AEmail: string);
begin
  inherited Create;
  FName := AName;
  FEmail := AEmail;
end;

function TContact.ToString: string;
begin
  Result := FName;
end;

{ TContactsWindow }

constructor TContactsWindow.Create;
begin
  inherited;
  FContacts := TWinUIBindableList<TContact>.Create;
  FContacts.Add(TContact.Create('Ali', 'ali@example.com'));
  FContacts.Add(TContact.Create('Bea', 'bea@example.com'));
  FContacts.Add(TContact.Create('Cyrus', 'cyrus@example.com'));
  ContactList.ItemsSource := FContacts;
  UpdateStatus;
end;

destructor TContactsWindow.Destroy;
begin
  FContacts.Free;
  inherited;
end;

procedure TContactsWindow.UpdateStatus;
var
  Index: Integer;
begin
  Index := ContactList.SelectedIndex;
  if Index < 0 then
    Status.Text := Format('%d contacts, none selected', [FContacts.Count])
  else
    Status.Text := Format('%d contacts, selected: %s', [FContacts.Count, FContacts[Index].Name]);
end;

procedure TContactsWindow.AddClick(Sender: TObject; E: TWinUIRoutedEventArgs);
var
  Name: string;
begin
  Name := Trim(NameBox.Text);
  if Name <> '' then
    FContacts.Add(TContact.Create(Name, LowerCase(Name) + '@example.com'));
  UpdateStatus;
end;

procedure TContactsWindow.RenameClick(Sender: TObject; E: TWinUIRoutedEventArgs);
var
  Contact: TContact;
begin
  if (ContactList.SelectedIndex < 0) or (Trim(NameBox.Text) = '') then
    Exit;
  Contact := FContacts[ContactList.SelectedIndex];
  Contact.Name := Trim(NameBox.Text);
  FContacts.ItemChanged(Contact, 'Name'); // the {Binding Name} TextBlock updates
  UpdateStatus;
end;

procedure TContactsWindow.RemoveClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  if ContactList.SelectedIndex >= 0 then
    FContacts.Delete(ContactList.SelectedIndex);
  UpdateStatus;
end;

procedure TContactsWindow.ContactListSelectionChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
begin
  UpdateStatus;
end;

end.