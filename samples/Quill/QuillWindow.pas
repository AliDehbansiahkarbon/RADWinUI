unit QuillWindow;

interface

uses
  System.SysUtils,
  System.UITypes,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Binding,
  RADWinUI.Forms,
  RADWinUI.Dialogs,
  RADWinUI.Notifications,
  RADWinUI.Resources,
  QuillWindow.Xaml;

type
  // Published properties are what {Binding Title} and {Binding Subtitle} read.
  {$M+}
  TQuillNote = class
  private
    FTitle: string;
    function GetSubtitle: string;
  public
    FileName: string;
    Text: string;
    Modified: Boolean;
    // The note Quill shows on its first start, replaced by the first note opened
    IsWelcome: Boolean;
  published
    property Title: string read FTitle write FTitle;
    property Subtitle: string read GetSubtitle;
  end;
  {$M-}

  TQuillWindow = class(TQuillWindowBase)   // generated from QuillWindow.xaml
  private
    FNotes: TWinUIBindableList<TQuillNote>;
    FCurrent: TQuillNote;
    FOpenDialog: TWinUIOpenDialog;
    FSaveDialog: TWinUISaveDialog;
    FFolderDialog: TWinUIFolderDialog;
    FReminder: TWinUITimer;
    FReminderPath: string;
    FReminderAt: TDateTime;
    FCloseConfirmed: Boolean;
    FRestartPending: Boolean;
    FShowingLanguage: Boolean;
    function AddNote(const ATitle, AFileName, AText: string): TQuillNote;
    function NextUntitled: string;
    procedure Select(ANote: TQuillNote);
    procedure ShowCurrent;
    procedure UpdateStatus;
    procedure NoteChanged(ANote: TQuillNote);
    procedure OpenFile(const APath: string);
    procedure WriteNote(ANote: TQuillNote; const APath: string);
    procedure SaveNote(ANote: TQuillNote; AAskName: Boolean; const AThen: TProc);
    procedure ConfirmSave(ANote: TQuillNote; const AThen: TProc);
    procedure RemoveNote(ANote: TQuillNote);
    procedure ConfirmClose(AFrom: Integer);
    procedure WindowCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Remind(ASeconds: Integer);
    procedure ScheduleReminder(const APath: string; ASeconds: Integer);
    procedure ReminderTick(Sender: TObject);
    procedure HandleActivation(const AActivation: TWinUIActivation);
    procedure HandleNotification(const AActivation: TWinUIActivation);
  public
    constructor Create; override;
    destructor Destroy; override;
    class procedure Activated(Sender: TObject; const AActivation: TWinUIActivation);
  published
    procedure NoteListSelectionChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
    procedure EditorChanged(Sender: TObject; E: TWinUITextChangedEventArgs);
    procedure NewClick(Sender: TObject);
    procedure ImportClick(Sender: TObject);
    procedure OpenClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure SaveAsClick(Sender: TObject);
    procedure RenameClick(Sender: TObject);
    procedure CloseNoteClick(Sender: TObject);
    procedure RemindSoonClick(Sender: TObject);
    procedure RemindMinuteClick(Sender: TObject);
    procedure RemindTenClick(Sender: TObject);
    procedure RemindCancelClick(Sender: TObject);
    procedure ExportClick(Sender: TObject);
    procedure SettingsClick(Sender: TObject);
    procedure AboutClick(Sender: TObject);
    procedure RegisterFilesClick(Sender: TObject);
    procedure UnregisterFilesClick(Sender: TObject);
    procedure RegisterLinksClick(Sender: TObject);
    procedure UnregisterLinksClick(Sender: TObject);
    procedure LanguageChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
  end;

/// <summary>The language picked in Settings, '' for the Windows language. Quill.dpr sets it before Run.</summary>
function SavedLanguage: string;

var
  /// <summary>Set when Quill closes to start again in another language.</summary>
  RestartQuill: Boolean;

implementation

uses
  Winapi.Windows,
  System.IOUtils,
  System.Math,
  System.StrUtils,
  System.NetEncoding,
  System.Win.Registry;

const
  NoteExtension = '.qnote';
  LinkScheme = 'quill';
  SnoozeSeconds = 5 * 60;
  SettingsKey = 'Software\Quill';
  // The choices of the Language box, in its order
  Languages: array[0..3] of string = ('', 'en-US', 'de-DE', 'fa-IR');
  LanguageNames: array[0..3] of string = ('', 'English', 'Deutsch', #$0641#$0627#$0631#$0633#$06CC);

var
  Quill: TQuillWindow;

// A text of Strings\<language>\Resources.resw in Quill's language
function S(const AKey: string): string;
begin
  Result := TWinUIResources.GetString(AKey, AKey);
end;

function SavedLanguage: string;
var
  Registry: TRegistry;
begin
  Result := '';
  Registry := TRegistry.Create(KEY_READ);
  try
    if Registry.OpenKeyReadOnly(SettingsKey) and Registry.ValueExists('Language') then
      Result := Registry.ReadString('Language');
  finally
    Registry.Free;
  end;
end;

procedure SaveLanguage(const ALanguage: string);
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create;
  try
    if Registry.OpenKey(SettingsKey, True) then
      Registry.WriteString('Language', ALanguage);
  finally
    Registry.Free;
  end;
end;

function WordCount(const AText: string): Integer;
var
  C: Char;
  InWord: Boolean;
begin
  Result := 0;
  InWord := False;
  for C in AText do
    if C <= ' ' then
      InWord := False
    else if not InWord then
    begin
      InWord := True;
      Inc(Result);
    end;
end;

function Describe(const AActivation: TWinUIActivation): string;
const
  KindNames: array[TWinUIActivationKind] of string = ('KindLaunch', 'KindFile', 'KindProtocol', 'KindNotification',
    'KindOther');
begin
  Result := S(KindNames[AActivation.Kind]);
  if AActivation.Arguments <> '' then
    Result := Result + ': ' + AActivation.Arguments;
  if Length(AActivation.Files) > 0 then
    Result := Result + ': ' + string.Join(', ', AActivation.Files);
end;

// The value of AName in the query of a link such as quill://new?text=hello
function QueryValue(const AUri, AName: string): string;
var
  Pair: string;
  P: Integer;
begin
  Result := '';
  P := Pos('?', AUri);
  if P = 0 then
    Exit;
  for Pair in Copy(AUri, P + 1, MaxInt).Split(['&']) do
    if SameText(Copy(Pair, 1, Length(AName) + 1), AName + '=') then
      Exit(TNetEncoding.URL.Decode(Copy(Pair, Length(AName) + 2, MaxInt)));
end;

{ TQuillNote }

function TQuillNote.GetSubtitle: string;
begin
  if FileName = '' then
    Result := S('NotSavedYet')
  else
    Result := ExtractFileDir(FileName);
  if Modified then
    Result := Format(S('EditedFormat'), [Result]);
end;

{ TQuillWindow }

constructor TQuillWindow.Create;
var
  Welcome: TQuillNote;
begin
  inherited;
  Quill := Self;
  SetTitleBar(DragRegion);
  AppWindow.TitleBar.PreferredTheme := TWinUITitleBarTheme.UseDefaultAppMode;
  // Right to left, the title starts at the right edge, where Windows keeps the caption buttons
  if TWinUIApp.RightToLeft then
    TitleRow.Loaded.Add(
      procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
      var
        Inset: TWinUIThickness;
      begin
        Inset := TitleRow.Margin;
        Inset.Left := 16 + AppWindow.TitleBar.RightInset / TitleRow.XamlRoot.RasterizationScale;
        TitleRow.Margin := Inset;
      end);
  OnCloseQuery := WindowCloseQuery;
  FNotes := TWinUIBindableList<TQuillNote>.Create;
  NoteList.ItemsSource := FNotes;
  FOpenDialog := TWinUIOpenDialog.Create;
  FOpenDialog.Filter := S('NoteFilter');
  FSaveDialog := TWinUISaveDialog.Create;
  FSaveDialog.Filter := S('NoteFilter');
  FSaveDialog.DefaultExt := NoteExtension;
  FFolderDialog := TWinUIFolderDialog.Create;
  FFolderDialog.Title := S('ExportTitle');
  FReminder := TWinUITimer.Create;
  FReminder.OnTimer := ReminderTick;
  LaunchInfo.Text := Describe(TWinUIApp.LaunchActivation);
  FShowingLanguage := True;
  LanguageBox.SelectedIndex := Max(0, IndexStr(SavedLanguage, Languages));
  FShowingLanguage := False;
  Welcome := AddNote(S('WelcomeTitle'), '', S('WelcomeText'));
  Welcome.IsWelcome := True;
  Select(Welcome);
end;

destructor TQuillWindow.Destroy;
begin
  Quill := nil;
  FReminder.Free;
  FOpenDialog.Free;
  FSaveDialog.Free;
  FFolderDialog.Free;
  FNotes.Free;
  inherited;
end;

function TQuillWindow.AddNote(const ATitle, AFileName, AText: string): TQuillNote;
begin
  // An untouched welcome note makes way for the first real one
  if (FNotes.Count = 1) and FNotes[0].IsWelcome and not FNotes[0].Modified then
  begin
    FCurrent := nil;
    FNotes.Delete(0);
  end;
  Result := TQuillNote.Create;
  Result.Title := ATitle;
  Result.FileName := AFileName;
  Result.Text := AdjustLineBreaks(AText);
  FNotes.Add(Result);
end;

function TQuillWindow.NextUntitled: string;
var
  N, I: Integer;
  Taken: Boolean;
begin
  N := 1;
  repeat
    if N = 1 then
      Result := S('Untitled')
    else
      Result := Format(S('UntitledFormat'), [N]);
    Taken := False;
    for I := 0 to FNotes.Count - 1 do
      Taken := Taken or SameText(FNotes[I].Title, Result);
    Inc(N);
  until not Taken;
end;

procedure TQuillWindow.Select(ANote: TQuillNote);
begin
  FCurrent := ANote;
  NoteList.SelectedIndex := FNotes.IndexOf(ANote);
  ShowCurrent;
end;

procedure TQuillWindow.ShowCurrent;
begin
  if FCurrent = nil then
    Exit;
  // EditorChanged sees the same text and leaves the note unmodified
  Editor.Text := FCurrent.Text;
  UpdateStatus;
end;

procedure TQuillWindow.UpdateStatus;
var
  State, Name: string;
begin
  if FCurrent = nil then
    Exit;
  if FCurrent.Modified then
    State := S('StateEdited')
  else if FCurrent.FileName <> '' then
    State := S('StateSaved')
  else
    State := S('StateNotSaved');
  Status.Text := Format(S('StatusFormat'), [WordCount(FCurrent.Text), State]);
  if FReminder.Enabled then
    Status.Text := Status.Text + Format(S('ReminderAtFormat'), [FormatDateTime('hh:nn:ss', FReminderAt)]);
  Name := FCurrent.Title;
  if FCurrent.Modified then
    Name := Name + ' *';
  TitleNote.Text := Name;
  Title := 'Quill - ' + Name;
end;

procedure TQuillWindow.NoteChanged(ANote: TQuillNote);
begin
  FNotes.ItemChanged(ANote);
  if ANote = FCurrent then
    UpdateStatus;
end;

procedure TQuillWindow.NoteListSelectionChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
var
  Index: Integer;
begin
  Index := NoteList.SelectedIndex;
  if (Index >= 0) and (FNotes[Index] <> FCurrent) then
  begin
    FCurrent := FNotes[Index];
    ShowCurrent;
  end;
end;

procedure TQuillWindow.EditorChanged(Sender: TObject; E: TWinUITextChangedEventArgs);
var
  Text: string;
begin
  if FCurrent = nil then
    Exit;
  // The TextBox turns line breaks into a lone CR, notes keep CRLF like the files
  Text := AdjustLineBreaks(Editor.Text);
  if Text = FCurrent.Text then
    Exit;
  FCurrent.Text := Text;
  if not FCurrent.Modified then
  begin
    FCurrent.Modified := True;
    NoteChanged(FCurrent);
  end
  else
    UpdateStatus;
end;

{ Files }

procedure TQuillWindow.OpenFile(const APath: string);
var
  I: Integer;
  Note: TQuillNote;
begin
  for I := 0 to FNotes.Count - 1 do
    if SameText(FNotes[I].FileName, APath) then
    begin
      Select(FNotes[I]);
      Exit;
    end;
  if not FileExists(APath) then
  begin
    MessageDlg(Format(S('NotFoundFormat'), [APath]), mtError, [mbOK]);
    Exit;
  end;
  Note := AddNote(ChangeFileExt(ExtractFileName(APath), ''), APath, TFile.ReadAllText(APath, TEncoding.UTF8));
  Select(Note);
end;

procedure TQuillWindow.WriteNote(ANote: TQuillNote; const APath: string);
begin
  TFile.WriteAllText(APath, ANote.Text, TEncoding.UTF8);
  ANote.FileName := APath;
  ANote.Title := ChangeFileExt(ExtractFileName(APath), '');
  ANote.Modified := False;
  ANote.IsWelcome := False;
  NoteChanged(ANote);
end;

// Saves ANote, asking for a name when it has none or AAskName is set. AThen runs once it is saved.
procedure TQuillWindow.SaveNote(ANote: TQuillNote; AAskName: Boolean; const AThen: TProc);
begin
  if (ANote.FileName <> '') and not AAskName then
  begin
    WriteNote(ANote, ANote.FileName);
    if Assigned(AThen) then
      AThen;
    Exit;
  end;
  FSaveDialog.Title := Format(S('SaveTitleFormat'), [ANote.Title]);
  FSaveDialog.FileName := ANote.Title + NoteExtension;
  if ANote.FileName <> '' then
    FSaveDialog.InitialDir := ExtractFileDir(ANote.FileName);
  FSaveDialog.Execute(
    procedure(AOk: Boolean)
    begin
      if not AOk then
        Exit;
      WriteNote(ANote, FSaveDialog.FileName);
      if Assigned(AThen) then
        AThen;
    end);
end;

// Asks whether to save an edited note. AThen runs after Yes (once saved) or No, not after Cancel.
procedure TQuillWindow.ConfirmSave(ANote: TQuillNote; const AThen: TProc);
begin
  if not ANote.Modified then
  begin
    AThen;
    Exit;
  end;
  Select(ANote);
  MessageDlg(Format(S('SaveChangesFormat'), [ANote.Title]), mtConfirmation, mbYesNoCancel,
    procedure(AResult: TModalResult)
    begin
      case AResult of
        mrYes: SaveNote(ANote, False, AThen);
        mrNo: AThen;
        mrCancel: FRestartPending := False; // Quill stays, in its language
      end;
    end);
end;

procedure TQuillWindow.RemoveNote(ANote: TQuillNote);
var
  Index: Integer;
begin
  Index := FNotes.IndexOf(ANote);
  if Index < 0 then
    Exit;
  FCurrent := nil;
  FNotes.Delete(Index);
  if FNotes.Count = 0 then
    AddNote(NextUntitled, '', '');
  if Index >= FNotes.Count then
    Index := FNotes.Count - 1;
  Select(FNotes[Index]);
end;

procedure TQuillWindow.NewClick(Sender: TObject);
begin
  Select(AddNote(NextUntitled, '', ''));
  Editor.Focus(TWinUIFocusState.Programmatic);
end;

procedure TQuillWindow.OpenClick(Sender: TObject);
begin
  FOpenDialog.Title := S('OpenTitle');
  FOpenDialog.MultiSelect := False;
  FOpenDialog.Execute(
    procedure(AOk: Boolean)
    begin
      if AOk then
        OpenFile(FOpenDialog.FileName);
    end);
end;

procedure TQuillWindow.ImportClick(Sender: TObject);
begin
  FOpenDialog.Title := S('ImportTitle');
  FOpenDialog.MultiSelect := True;
  FOpenDialog.Execute(
    procedure(AOk: Boolean)
    var
      Path: string;
    begin
      if AOk then
        for Path in FOpenDialog.Files do
          OpenFile(Path);
    end);
end;

procedure TQuillWindow.SaveClick(Sender: TObject);
begin
  if FCurrent <> nil then
    SaveNote(FCurrent, False, nil);
end;

procedure TQuillWindow.SaveAsClick(Sender: TObject);
begin
  if FCurrent <> nil then
    SaveNote(FCurrent, True, nil);
end;

procedure TQuillWindow.RenameClick(Sender: TObject);
var
  Note: TQuillNote;
begin
  Note := FCurrent;
  if Note = nil then
    Exit;
  InputQuery(S('RenameTitle'), S('RenamePrompt'), Note.Title,
    procedure(AOk: Boolean; const AValue: string)
    var
      Name, NewPath: string;
    begin
      Name := Trim(AValue);
      if not AOk or (Name = '') or (Name = Note.Title) then
        Exit;
      // A saved note is renamed on disk too
      if Note.FileName <> '' then
      begin
        NewPath := TPath.Combine(ExtractFileDir(Note.FileName), Name + ExtractFileExt(Note.FileName));
        if FileExists(NewPath) or not RenameFile(Note.FileName, NewPath) then
        begin
          MessageDlg(Format(S('RenameFailedFormat'), [ExtractFileName(NewPath)]),
            mtError, [mbOK]);
          Exit;
        end;
        if SameText(FReminderPath, Note.FileName) then
          FReminderPath := NewPath;
        Note.FileName := NewPath;
      end;
      Note.Title := Name;
      Note.IsWelcome := False;
      NoteChanged(Note);
    end);
end;

procedure TQuillWindow.CloseNoteClick(Sender: TObject);
var
  Note: TQuillNote;
begin
  Note := FCurrent;
  if Note <> nil then
    ConfirmSave(Note,
      procedure
      begin
        RemoveNote(Note);
      end);
end;

procedure TQuillWindow.ExportClick(Sender: TObject);
begin
  FFolderDialog.Execute(
    procedure(AOk: Boolean)
    var
      I: Integer;
    begin
      if not AOk then
        Exit;
      for I := 0 to FNotes.Count - 1 do
        TFile.WriteAllText(TPath.Combine(FFolderDialog.Folder, FNotes[I].Title + NoteExtension), FNotes[I].Text,
          TEncoding.UTF8);
      ShowMessage(Format(S('ExportedFormat'), [FNotes.Count, FFolderDialog.Folder]));
    end);
end;

{ Closing }

procedure TQuillWindow.WindowCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  I: Integer;
begin
  if not FCloseConfirmed then
    for I := 0 to FNotes.Count - 1 do
      if FNotes[I].Modified then
      begin
        // The window stays open while Quill asks about each edited note
        CanClose := False;
        ConfirmClose(0);
        Exit;
      end;
  RestartQuill := FRestartPending;
end;

procedure TQuillWindow.ConfirmClose(AFrom: Integer);
var
  I: Integer;
begin
  for I := AFrom to FNotes.Count - 1 do
    if FNotes[I].Modified then
    begin
      ConfirmSave(FNotes[I],
        procedure
        begin
          ConfirmClose(I + 1);
        end);
      Exit;
    end;
  FCloseConfirmed := True;
  Close;
end;

{ Reminders }

procedure TQuillWindow.Remind(ASeconds: Integer);
var
  Note: TQuillNote;
begin
  Note := FCurrent;
  if Note = nil then
    Exit;
  // The notification opens the note from its file, even after Quill was closed
  if Note.FileName <> '' then
    ScheduleReminder(Note.FileName, ASeconds)
  else
    MessageDlg(Format(S('SaveFirstFormat'), [Note.Title]),
      mtConfirmation, mbYesNo,
      procedure(AResult: TModalResult)
      begin
        if AResult = mrYes then
          SaveNote(Note, False,
            procedure
            begin
              ScheduleReminder(Note.FileName, ASeconds);
            end);
      end);
end;

procedure TQuillWindow.ScheduleReminder(const APath: string; ASeconds: Integer);
begin
  FReminder.Enabled := False;
  FReminderPath := APath;
  FReminderAt := Now + ASeconds / SecsPerDay;
  FReminder.Interval := ASeconds * 1000;
  FReminder.Enabled := True;
  UpdateStatus;
end;

procedure TQuillWindow.ReminderTick(Sender: TObject);
var
  N: TWinUINotification;
  Name, FirstLine: string;
  Lines: TArray<string>;
begin
  FReminder.Enabled := False;
  UpdateStatus;
  if not FileExists(FReminderPath) then
    Exit;
  Name := ChangeFileExt(ExtractFileName(FReminderPath), '');
  Lines := TFile.ReadAllText(FReminderPath, TEncoding.UTF8).Trim.Split([#13#10, #10]);
  if Length(Lines) > 0 then
    FirstLine := Lines[0];
  N := TWinUINotification.Create;
  try
    N.Title := Format(S('ReminderTitleFormat'), [Name]);
    N.Text := FirstLine;
    N.Argument := 'open|' + FReminderPath;
    N.Tag := 'reminder';
    N.AddTextBox('line', S('ReminderLine'));
    N.AddButton(S('ReminderOpen'), 'open|' + FReminderPath);
    N.AddButton(S('ReminderSnooze'), 'snooze|' + FReminderPath);
    N.Show;
  finally
    N.Free;
  end;
end;

procedure TQuillWindow.RemindSoonClick(Sender: TObject);
begin
  Remind(10);
end;

procedure TQuillWindow.RemindMinuteClick(Sender: TObject);
begin
  Remind(60);
end;

procedure TQuillWindow.RemindTenClick(Sender: TObject);
begin
  Remind(10 * 60);
end;

procedure TQuillWindow.RemindCancelClick(Sender: TObject);
begin
  FReminder.Enabled := False;
  UpdateStatus;
end;

{ Activation }

class procedure TQuillWindow.Activated(Sender: TObject; const AActivation: TWinUIActivation);
begin
  if Quill <> nil then
    Quill.HandleActivation(AActivation);
end;

procedure TQuillWindow.HandleActivation(const AActivation: TWinUIActivation);
var
  Path, Uri: string;
  Note: TQuillNote;
begin
  case AActivation.Kind of
    TWinUIActivationKind.Launch:
      begin
        // shortcut: one file on the command line, enough for "Open with" and drag onto the exe
        Path := AnsiDequotedStr(Trim(AActivation.Arguments), '"');
        if (Path <> '') and not Path.StartsWith('-') and FileExists(Path) then
          OpenFile(Path);
      end;
    TWinUIActivationKind.&File:
      for Path in AActivation.Files do
        OpenFile(Path);
    TWinUIActivationKind.Protocol:
      begin
        Uri := AActivation.Arguments;
        if Uri.StartsWith(LinkScheme + '://new', True) then
        begin
          Note := AddNote(NextUntitled, '', QueryValue(Uri, 'text'));
          Note.Modified := Note.Text <> '';
          Select(Note);
        end;
      end;
    TWinUIActivationKind.Notification:
      HandleNotification(AActivation);
  end;
end;

// Arguments are "open|<path>" or "snooze|<path>", and the text box "line" adds a line to the note
procedure TQuillWindow.HandleNotification(const AActivation: TWinUIActivation);
var
  Action, Path, Line: string;
  P: Integer;
begin
  P := Pos('|', AActivation.Arguments);
  if P = 0 then
    Exit;
  Action := Copy(AActivation.Arguments, 1, P - 1);
  Path := Copy(AActivation.Arguments, P + 1, MaxInt);
  OpenFile(Path);
  Line := Trim(AActivation.Input('line'));
  if (Line <> '') and (FCurrent <> nil) and SameText(FCurrent.FileName, Path) then
  begin
    FCurrent.Text := FCurrent.Text.TrimRight + sLineBreak + Line;
    FCurrent.Modified := True;
    NoteChanged(FCurrent);
    ShowCurrent;
  end;
  if Action = 'snooze' then
    ScheduleReminder(Path, SnoozeSeconds);
end;

{ Settings and About }

procedure TQuillWindow.SettingsClick(Sender: TObject);
begin
  if SettingsPanel.Visibility = TWinUIVisibility.Visible then
    SettingsPanel.Visibility := TWinUIVisibility.Collapsed
  else
    SettingsPanel.Visibility := TWinUIVisibility.Visible;
end;

procedure TQuillWindow.AboutClick(Sender: TObject);
begin
  ShowMessage(AdjustLineBreaks(S('AboutText')));
end;

procedure TQuillWindow.RegisterFilesClick(Sender: TObject);
begin
  TWinUIApp.RegisterFileTypes([NoteExtension], S('FileTypeName'));
  SettingsResult.Text := S('FilesRegistered');
end;

procedure TQuillWindow.UnregisterFilesClick(Sender: TObject);
begin
  TWinUIApp.UnregisterFileTypes([NoteExtension]);
  SettingsResult.Text := S('FilesUnregistered');
end;

procedure TQuillWindow.RegisterLinksClick(Sender: TObject);
begin
  TWinUIApp.RegisterProtocol(LinkScheme, S('LinkName'));
  SettingsResult.Text := S('LinksRegistered');
end;

procedure TQuillWindow.UnregisterLinksClick(Sender: TObject);
begin
  TWinUIApp.UnregisterProtocol(LinkScheme);
  SettingsResult.Text := S('LinksUnregistered');
end;

// The language takes effect at the next start: Quill offers to start again now
procedure TQuillWindow.LanguageChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
var
  Index: Integer;
  Name: string;
begin
  Index := LanguageBox.SelectedIndex;
  if FShowingLanguage or (Index < 0) or (Languages[Index] = SavedLanguage) then
    Exit;
  SaveLanguage(Languages[Index]);
  Name := LanguageNames[Index];
  if Name = '' then
    Name := S('LanguageSystem/Content');
  MessageDlg(Format(S('RestartFormat'), [Name]), mtConfirmation, mbYesNo,
    procedure(AResult: TModalResult)
    begin
      if AResult <> mrYes then
        Exit;
      FRestartPending := True;
      Close;
    end);
end;

end.
