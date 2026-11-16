unit SettingsPage;

interface

uses
  System.SysUtils,
  System.UITypes,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Pages,
  RADWinUI.Dialogs,
  SettingsPage.Xaml;

type
  TSettingsPage = class(TSettingsPageBase)   // generated from SettingsPage.xaml
  private
    FShowing: Boolean;
  public
    constructor Create; override;
  published
    procedure ThemeChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
    procedure LanguageChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
    procedure TestNoteClick(Sender: TObject);
  end;

implementation

uses
  System.StrUtils,
  System.Math,
  RADWinUI.Forms,
  RADWinUI.Notifications,
  EmberSettings,
  MainWindow;

constructor TSettingsPage.Create;
var
  I: Integer;
begin
  inherited;
  FShowing := True;
  try
    ThemeBox.SelectedIndex := SavedTheme;
    for I := 0 to High(LanguageNames) do
      if I = 0 then
        LanguageBox.Items.Add(S('LanguageSystem', 'Windows default'))
      else
        LanguageBox.Items.Add(LanguageNames[I]);
    LanguageBox.SelectedIndex := Max(0, IndexStr(SavedLanguage, Languages));
  finally
    FShowing := False;
  end;
end;

procedure TSettingsPage.ThemeChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
begin
  if FShowing or (ThemeBox.SelectedIndex < 0) then
    Exit;
  SaveTheme(ThemeBox.SelectedIndex);
  Ember.ApplyTheme(ThemeBox.SelectedIndex);
end;

// The language takes effect at the next start: Ember offers to start again now
procedure TSettingsPage.LanguageChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
var
  Index: Integer;
  Name: string;
begin
  Index := LanguageBox.SelectedIndex;
  if FShowing or (Index < 0) or (Languages[Index] = SavedLanguage) then
    Exit;
  SaveLanguage(Languages[Index]);
  Name := LanguageNames[Index];
  if Name = '' then
    Name := S('LanguageSystem', 'Windows default');
  MessageDlg(Format(S('RestartFormat', 'Start Ember again in %s now?'), [Name]), mtConfirmation, mbYesNo,
    procedure(AResult: TModalResult)
    begin
      if AResult <> mrYes then
        Exit;
      RestartEmber := True;
      Ember.Close;
    end);
end;

procedure TSettingsPage.TestNoteClick(Sender: TObject);
var
  Note: TWinUINotification;
begin
  Note := TWinUINotification.Create;
  try
    Note.Title := S('TestNoteTitle', 'Ember is ready');
    Note.Text := S('TestNoteText', 'You will see a message like this when a batch is done.');
    Note.Argument := 'show';
    Note.Show;
  finally
    Note.Free;
  end;
end;

end.
