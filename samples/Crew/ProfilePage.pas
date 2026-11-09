unit ProfilePage;

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Pages,
  CrewData,
  ProfilePage.Xaml;

type
  TProfilePage = class(TProfilePageBase)   // generated from ProfilePage.xaml
  private
    FPerson: TPerson;
    function Dirty: Boolean;
    procedure Save;
    procedure ShowPerson;
  protected
    procedure NavigatedTo(const AArgs: TWinUINavigationArgs); override;
    procedure NavigatingFrom(var AArgs: TWinUINavigatingArgs); override;
  published
    procedure FieldChanged(Sender: TObject; E: TWinUITextChangedEventArgs);
    procedure SaveClick(Sender: TObject);
  end;

implementation

uses
  System.SysUtils,
  System.UITypes,
  RADWinUI.Dialogs;

procedure TProfilePage.NavigatedTo(const AArgs: TWinUINavigationArgs);
begin
  // Navigate(TProfilePage, Person) hands the person over
  FPerson := AArgs.Parameter.AsObject as TPerson;
  ShowPerson;
end;

procedure TProfilePage.ShowPerson;
begin
  PageTitle.Text := FPerson.Name;
  Subtitle.Text := FPerson.Role;
  Picture.DisplayName := FPerson.Name;
  NameBox.Text := FPerson.Name;
  RoleBox.Text := FPerson.Role;
  EmailBox.Text := FPerson.Email;
  NotesBox.Text := FPerson.Notes;
  Status.Text := '';
end;

function TProfilePage.Dirty: Boolean;
begin
  // The TextBox turns line breaks into a lone CR, compare like the notes are kept
  Result := (FPerson <> nil) and ((NameBox.Text <> FPerson.Name) or (RoleBox.Text <> FPerson.Role) or
    (EmailBox.Text <> FPerson.Email) or (AdjustLineBreaks(NotesBox.Text) <> FPerson.Notes));
end;

procedure TProfilePage.Save;
begin
  FPerson.Name := Trim(NameBox.Text);
  FPerson.Role := Trim(RoleBox.Text);
  FPerson.Email := Trim(EmailBox.Text);
  FPerson.Notes := AdjustLineBreaks(NotesBox.Text);
  People.ItemChanged(FPerson);
  ShowPerson;
  Status.Text := 'Saved';
  SaveButton.IsEnabled := False;
end;

procedure TProfilePage.FieldChanged(Sender: TObject; E: TWinUITextChangedEventArgs);
begin
  SaveButton.IsEnabled := Dirty;
  if Dirty then
    Status.Text := 'Edited';
end;

procedure TProfilePage.SaveClick(Sender: TObject);
begin
  Save;
end;

procedure TProfilePage.NavigatingFrom(var AArgs: TWinUINavigatingArgs);
var
  Proceed: TProc;
begin
  if not Dirty then
    Exit;
  // Stay for now, ask, and let the navigation go on after Yes or No
  AArgs.Cancel := True;
  Proceed := AArgs.Proceed;
  MessageDlg(Format('Save changes to %s?', [FPerson.Name]), TMsgDlgType.mtConfirmation,
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo, TMsgDlgBtn.mbCancel],
    procedure(AResult: TModalResult)
    begin
      case AResult of
        mrYes:
          begin
            Save;
            Proceed;
          end;
        mrNo:
          begin
            ShowPerson; // the edits are dropped
            Proceed;
          end;
      end;
    end);
end;

end.