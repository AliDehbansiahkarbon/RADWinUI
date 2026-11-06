unit RADWinUI.Designer.Dialogs;

{
  Dialogs of the designer and the preview command drawn with the IDE theme, so
  they match the light and dark IDE styles like the IDE's own dialogs: a message
  box, a one-line text box, and ThemeForm for the other forms. Outside the IDE,
  or with IDE theming off, they are plain VCL dialogs.
}

interface

uses
  System.UITypes,
  Vcl.Forms;

/// <summary>Draws AForm with the IDE theme. Call it before the form is shown.</summary>
procedure ThemeForm(AForm: TCustomForm);
/// <summary>MessageDlg drawn with the IDE theme, ACaption replaces the default title.</summary>
function ThemedMessageDlg(const AMessage: string; AType: TMsgDlgType; AButtons: TMsgDlgButtons;
  const ACaption: string = ''): Integer;
/// <summary>
///   Asks for one line of text, shown selected. True, and the new text in AValue,
///   when the user pressed OK or Enter.
/// </summary>
function AskText(const ACaption, APrompt: string; var AValue: string): Boolean;

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.Dialogs,
  ToolsAPI;

var
  ThemedClasses: TArray<TClass>; // registered with the IDE theming once each

procedure ThemeForm(AForm: TCustomForm);
var
  Theming: IOTAIDEThemingServices;
  Registered: TClass;
begin
  if not Supports(BorlandIDEServices, IOTAIDEThemingServices, Theming) or not Theming.IDEThemingEnabled then
    Exit;
  for Registered in ThemedClasses do
    if Registered = AForm.ClassType then
    begin
      Theming.ApplyTheme(AForm);
      Exit;
    end;
  Theming.RegisterFormClass(TCustomFormClass(AForm.ClassType));
  ThemedClasses := ThemedClasses + [AForm.ClassType];
  Theming.ApplyTheme(AForm);
end;

function ThemedMessageDlg(const AMessage: string; AType: TMsgDlgType; AButtons: TMsgDlgButtons;
  const ACaption: string): Integer;
var
  Dialog: TForm;
begin
  // A VCL form, not a task dialog: the IDE theme can draw it
  Dialog := CreateMessageDialog(AMessage, AType, AButtons);
  try
    if ACaption <> '' then
      Dialog.Caption := ACaption;
    Dialog.Position := poMainFormCenter;
    ThemeForm(Dialog);
    Result := Dialog.ShowModal;
  finally
    Dialog.Free;
  end;
end;

type
  TTextForm = class(TForm)
  private
    function Scale(AValue: Integer): Integer;
  end;

function TTextForm.Scale(AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, CurrentPPI, 96);
end;

function AskText(const ACaption, APrompt: string; var AValue: string): Boolean;
var
  Form: TTextForm;
  Prompt: TLabel;
  Edit: TEdit;
  OkButton, CancelButton: TButton;
  Margin, ButtonWidth, ButtonHeight: Integer;
begin
  Form := TTextForm.CreateNew(nil);
  try
    Form.Caption := ACaption;
    Form.BorderStyle := bsDialog;
    Form.BorderIcons := [biSystemMenu];
    Form.Position := poMainFormCenter;
    Form.PopupMode := pmAuto;
    // Laid out at 96 DPI, ScaleForPPI below brings it to the DPI of the IDE window
    Form.Font.Assign(Screen.MessageFont);
    Form.Font.Height := MulDiv(Screen.MessageFont.Height, Screen.DefaultPixelsPerInch, Screen.PixelsPerInch);
    Margin := Form.Scale(16);
    ButtonWidth := Form.Scale(88);
    ButtonHeight := Form.Scale(28);
    Form.ClientWidth := Form.Scale(440);

    Prompt := TLabel.Create(Form);
    Prompt.Parent := Form;
    Prompt.Caption := APrompt;
    Prompt.ShowAccelChar := False;
    Prompt.SetBounds(Margin, Margin, Form.ClientWidth - 2 * Margin, Prompt.Height);

    Edit := TEdit.Create(Form);
    Edit.Parent := Form;
    Edit.SetBounds(Margin, Prompt.Top + Prompt.Height + Form.Scale(6), Form.ClientWidth - 2 * Margin, Edit.Height);
    Edit.Text := AValue;
    Prompt.FocusControl := Edit;

    CancelButton := TButton.Create(Form);
    CancelButton.Parent := Form;
    CancelButton.Caption := 'Cancel';
    CancelButton.Cancel := True;
    CancelButton.ModalResult := mrCancel;
    CancelButton.SetBounds(Form.ClientWidth - Margin - ButtonWidth, Edit.Top + Edit.Height + Form.Scale(16),
      ButtonWidth, ButtonHeight);
    OkButton := TButton.Create(Form);
    OkButton.Parent := Form;
    OkButton.Caption := 'OK';
    OkButton.Default := True;
    OkButton.ModalResult := mrOk;
    OkButton.SetBounds(CancelButton.Left - Form.Scale(8) - ButtonWidth, CancelButton.Top, ButtonWidth, ButtonHeight);
    Form.ClientHeight := CancelButton.Top + ButtonHeight + Margin;
    if Application.MainForm <> nil then
      Form.ScaleForPPI(Application.MainForm.CurrentPPI)
    else
      Form.ScaleForPPI(Screen.PixelsPerInch);

    ThemeForm(Form);
    Form.ActiveControl := Edit;
    Edit.SelectAll;
    Result := Form.ShowModal = mrOk;
    if Result then
      AValue := Edit.Text;
  finally
    Form.Free;
  end;
end;

end.
