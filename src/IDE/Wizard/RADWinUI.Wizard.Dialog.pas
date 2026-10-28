unit RADWinUI.Wizard.Dialog;

{
  The dialogs of File > New > RADWinUI Application and RADWinUI Window: one VCL
  form drawn with the IDE theme, so it matches the light and dark IDE styles.
  It shows what is wrong with the values while they are typed, and Create stays
  disabled until they can be used. The folder button opens the Windows folder
  picker. Messages use a task dialog.
}

interface

uses
  System.SysUtils;

type
  /// <summary>Returns '' when the values can be used, else the reason they cannot.</summary>
  TWizardValidator = reference to function(const AName, ALocation: string): string;

/// <summary>
///   Asks for a new application's name and the folder that will contain its
///   project folder. False when cancelled. The folder is remembered for the next time.
/// </summary>
function AskNewProject(var AName, ALocation: string; const AValidate: TWizardValidator): Boolean;
/// <summary>Asks for a new window's unit name. False when cancelled.</summary>
function AskNewWindow(var AUnitName: string; const AValidate: TWizardValidator): Boolean;
/// <summary>A task dialog with a heading and a message, owned by the IDE window.</summary>
procedure ShowWizardMessage(const ATitle, AHeading, AText: string; AWarning: Boolean);
/// <summary>The folder AskNewProject offers first: the last one used, else Documents.</summary>
function LastProjectFolder: string;

implementation

uses
  Winapi.Windows,
  System.Classes,
  System.IOUtils,
  System.Win.Registry,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.Dialogs,
  Vcl.Themes,
  ToolsAPI;

const
  SettingsValue = 'ProjectFolder';

type
  TWizardDialog = class(TForm)
  private
    FIntro: TLabel;
    FNameEdit: TEdit;
    FLocationEdit: TEdit;
    FBrowseButton: TButton;
    FTargetLabel: TLabel;
    FErrorLabel: TLabel;
    FCreateButton: TButton;
    FCancelButton: TButton;
    FValidate: TWizardValidator;
    FTargetCaption: string;
    function Scale(AValue: Integer): Integer;
    function AddLabel(const ACaption: string; ATop: Integer): TLabel;
    function AddEdit(ATop, AWidth: Integer): TEdit;
    procedure BrowseClick(Sender: TObject);
    procedure ValuesChange(Sender: TObject);
    procedure ApplyIdeTheme;
  public
    constructor CreateDialog(const ATitle, AIntro, ANameCaption, ATargetCaption: string;
      AWithLocation: Boolean; const AValidate: TWizardValidator);
  end;

var
  ThemedClassRegistered: Boolean;

function IdeTheming(out ATheming: IOTAIDEThemingServices): Boolean;
begin
  Result := Supports(BorlandIDEServices, IOTAIDEThemingServices, ATheming) and ATheming.IDEThemingEnabled;
end;

function IsDarkColor(AColor: TColor): Boolean;
var
  Rgb: Longint;
begin
  Rgb := ColorToRGB(AColor);
  Result := (GetRValue(Rgb) * 299 + GetGValue(Rgb) * 587 + GetBValue(Rgb) * 114) div 1000 < 128;
end;

function SettingsKey: string;
var
  Services: IOTAServices;
begin
  if Supports(BorlandIDEServices, IOTAServices, Services) then
    Result := Services.GetBaseRegistryKey + '\RADWinUI'
  else
    Result := 'Software\RADWinUI';
end;

function LastProjectFolder: string;
var
  Registry: TRegistry;
begin
  Result := '';
  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if Registry.OpenKeyReadOnly(SettingsKey) and Registry.ValueExists(SettingsValue) then
      Result := Registry.ReadString(SettingsValue);
  finally
    Registry.Free;
  end;
  if (Result = '') or not TDirectory.Exists(Result) then
    Result := TPath.GetDocumentsPath;
end;

procedure SaveProjectFolder(const AFolder: string);
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create(KEY_WRITE);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if Registry.OpenKey(SettingsKey, True) then
      Registry.WriteString(SettingsValue, AFolder);
  finally
    Registry.Free;
  end;
end;

{ TWizardDialog }

constructor TWizardDialog.CreateDialog(const ATitle, AIntro, ANameCaption, ATargetCaption: string;
  AWithLocation: Boolean; const AValidate: TWizardValidator);
var
  Margin, Inner, Top, ButtonWidth, ButtonHeight: Integer;
begin
  inherited CreateNew(nil);
  FValidate := AValidate;
  FTargetCaption := ATargetCaption;
  Caption := ATitle;
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Position := poMainFormCenter;
  PopupMode := pmAuto;
  KeyPreview := True;
  // A CreateNew form is at 96 DPI (Scale is 1 here): the layout and font are made for 96 DPI,
  // then ScaleForPPI below brings the whole form to the DPI of the IDE window.
  Font.Assign(Screen.MessageFont);
  Font.Height := MulDiv(Screen.MessageFont.Height, Screen.DefaultPixelsPerInch, Screen.PixelsPerInch);
  Margin := Scale(20);
  ButtonWidth := Scale(96);
  ButtonHeight := Scale(30);
  ClientWidth := Scale(520);
  Inner := ClientWidth - 2 * Margin;

  FIntro := AddLabel(AIntro, Margin);
  FIntro.WordWrap := True;
  FIntro.AutoSize := False;
  FIntro.Height := Scale(36);
  Top := FIntro.Top + FIntro.Height + Scale(12);

  AddLabel(ANameCaption, Top);
  FNameEdit := AddEdit(Top + Scale(20), Inner);
  Top := FNameEdit.Top + FNameEdit.Height + Scale(14);

  if AWithLocation then
  begin
    AddLabel('&Location', Top);
    FLocationEdit := AddEdit(Top + Scale(20), Inner - ButtonWidth - Scale(8));
    FBrowseButton := TButton.Create(Self);
    FBrowseButton.Parent := Self;
    FBrowseButton.Caption := '&Browse...';
    FBrowseButton.SetBounds(Margin + Inner - ButtonWidth, FLocationEdit.Top - Scale(1), ButtonWidth,
      FLocationEdit.Height + Scale(2));
    FBrowseButton.OnClick := BrowseClick;
    Top := FLocationEdit.Top + FLocationEdit.Height + Scale(14);
  end;

  FTargetLabel := AddLabel('', Top);
  FTargetLabel.AutoSize := False;
  FTargetLabel.Width := Inner;
  FTargetLabel.EllipsisPosition := epPathEllipsis;
  FTargetLabel.ShowAccelChar := False;
  Top := FTargetLabel.Top + FTargetLabel.Height + Scale(6);

  FErrorLabel := AddLabel('', Top);
  FErrorLabel.AutoSize := False;
  FErrorLabel.WordWrap := True;
  FErrorLabel.ShowAccelChar := False;
  FErrorLabel.Width := Inner;
  FErrorLabel.Height := Scale(36);
  // Its own colour, the theme would draw it like any other label
  FErrorLabel.StyleElements := FErrorLabel.StyleElements - [seFont];
  Top := FErrorLabel.Top + FErrorLabel.Height + Scale(12);

  FCancelButton := TButton.Create(Self);
  FCancelButton.Parent := Self;
  FCancelButton.Caption := 'Cancel';
  FCancelButton.Cancel := True;
  FCancelButton.ModalResult := mrCancel;
  FCancelButton.SetBounds(ClientWidth - Margin - ButtonWidth, Top, ButtonWidth, ButtonHeight);
  FCreateButton := TButton.Create(Self);
  FCreateButton.Parent := Self;
  FCreateButton.Caption := '&Create';
  FCreateButton.Default := True;
  FCreateButton.ModalResult := mrOk;
  FCreateButton.SetBounds(FCancelButton.Left - Scale(8) - ButtonWidth, Top, ButtonWidth, ButtonHeight);
  ClientHeight := Top + ButtonHeight + Margin;
  if Application.MainForm <> nil then
    ScaleForPPI(Application.MainForm.CurrentPPI)
  else
    ScaleForPPI(Screen.PixelsPerInch);

  ApplyIdeTheme;
  if IsDarkColor(Color) then
    FErrorLabel.Font.Color := RGB(255, 153, 164)
  else
    FErrorLabel.Font.Color := RGB(196, 43, 28);
  FNameEdit.OnChange := ValuesChange;
  if FLocationEdit <> nil then
    FLocationEdit.OnChange := ValuesChange;
  ActiveControl := FNameEdit;
end;

function TWizardDialog.Scale(AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, CurrentPPI, 96);
end;

function TWizardDialog.AddLabel(const ACaption: string; ATop: Integer): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := Self;
  Result.Caption := ACaption;
  Result.Left := Scale(20);
  Result.Top := ATop;
  Result.Width := ClientWidth - 2 * Scale(20);
end;

function TWizardDialog.AddEdit(ATop, AWidth: Integer): TEdit;
begin
  Result := TEdit.Create(Self);
  Result.Parent := Self;
  Result.SetBounds(Scale(20), ATop, AWidth, Result.Height);
  // The caption above names the field and moves the focus to it
  if (ControlCount >= 2) and (Controls[ControlCount - 2] is TLabel) then
    TLabel(Controls[ControlCount - 2]).FocusControl := Result;
end;

procedure TWizardDialog.ApplyIdeTheme;
var
  Theming: IOTAIDEThemingServices;
begin
  if not IdeTheming(Theming) then
    Exit;
  if not ThemedClassRegistered then
  begin
    Theming.RegisterFormClass(TCustomFormClass(ClassType));
    ThemedClassRegistered := True;
  end;
  Theming.ApplyTheme(Self);
end;

procedure TWizardDialog.BrowseClick(Sender: TObject);
var
  Picker: TFileOpenDialog;
begin
  Picker := TFileOpenDialog.Create(Self);
  try
    Picker.Title := 'Folder that will contain the project folder';
    Picker.Options := [fdoPickFolders, fdoPathMustExist, fdoForceFileSystem];
    Picker.OkButtonLabel := 'Select Folder';
    if TDirectory.Exists(FLocationEdit.Text) then
      Picker.DefaultFolder := FLocationEdit.Text;
    if Picker.Execute(Handle) then
      FLocationEdit.Text := Picker.FileName;
  finally
    Picker.Free;
  end;
end;

procedure TWizardDialog.ValuesChange(Sender: TObject);
var
  Name, Location, Error: string;
begin
  Name := Trim(FNameEdit.Text);
  if FLocationEdit <> nil then
    Location := Trim(FLocationEdit.Text);
  Error := FValidate(Name, Location);
  if FLocationEdit = nil then
    FTargetLabel.Caption := Format(FTargetCaption, [Name])
  else if (Error = '') or ((Name <> '') and (Location <> '')) then
    FTargetLabel.Caption := Format(FTargetCaption, [IncludeTrailingPathDelimiter(Location) + Name])
  else
    FTargetLabel.Caption := '';
  FErrorLabel.Caption := Error;
  FCreateButton.Enabled := Error = '';
end;

function AskNewProject(var AName, ALocation: string; const AValidate: TWizardValidator): Boolean;
var
  Dialog: TWizardDialog;
begin
  Dialog := TWizardDialog.CreateDialog('New RADWinUI Application',
    'A WinUI 3 application with a main window, its view model and the RADWinUI build steps. ' +
    'The project gets its own folder inside the location.', '&Project name', 'Project folder: %s', True, AValidate);
  try
    Dialog.FNameEdit.Text := AName;
    Dialog.FLocationEdit.Text := ALocation;
    Dialog.FNameEdit.SelectAll;
    Result := Dialog.ShowModal = mrOk;
    if Result then
    begin
      AName := Trim(Dialog.FNameEdit.Text);
      ALocation := ExcludeTrailingPathDelimiter(Trim(Dialog.FLocationEdit.Text));
      SaveProjectFolder(ALocation);
    end;
  finally
    Dialog.Free;
  end;
end;

function AskNewWindow(var AUnitName: string; const AValidate: TWizardValidator): Boolean;
var
  Dialog: TWizardDialog;
begin
  Dialog := TWizardDialog.CreateDialog('New RADWinUI Window',
    'Another window for the active project: a .xaml file with its code in a .pas unit, ' +
    'added to the project.', '&Unit name', 'Files: %0:s.xaml, %0:s.pas, class T%0:s', False, AValidate);
  try
    Dialog.FNameEdit.Text := AUnitName;
    Dialog.FNameEdit.SelectAll;
    Result := Dialog.ShowModal = mrOk;
    if Result then
      AUnitName := Trim(Dialog.FNameEdit.Text);
  finally
    Dialog.Free;
  end;
end;

procedure ShowWizardMessage(const ATitle, AHeading, AText: string; AWarning: Boolean);
var
  Dialog: TTaskDialog;
begin
  Dialog := TTaskDialog.Create(nil);
  try
    Dialog.Caption := ATitle;
    Dialog.Title := AHeading;
    Dialog.Text := AText;
    Dialog.CommonButtons := [tcbOk];
    if AWarning then
      Dialog.MainIcon := tdiWarning
    else
      Dialog.MainIcon := tdiInformation;
    Dialog.Flags := [tfPositionRelativeToWindow, tfAllowDialogCancellation];
    Dialog.Execute(Application.ActiveFormHandle);
  finally
    Dialog.Free;
  end;
end;

end.
