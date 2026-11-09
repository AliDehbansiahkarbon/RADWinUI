unit RADWinUI.Designer.Dialogs;

{
  Dialogs of the designer and the preview command drawn with the IDE theme, so
  they match the light and dark IDE styles like the IDE's own dialogs: a message
  box, a one-line text box, and ThemeForm for the other forms. Outside the IDE,
  or with IDE theming off, they are plain VCL dialogs.

  Forms built in code lay themselves out at DialogPPI with PrepareDialog: VCL
  does not scale them afterwards. VCL's scaling of a form built in code, followed
  by the IDE theme, can leave the form, its controls and its font at different
  scales on monitors above 100%.
}

interface

uses
  System.UITypes,
  Vcl.Forms;

/// <summary>
///   The DPI that dialogs are laid out at: the DPI of the monitor that shows the IDE
///   window, where poMainFormCenter places them.
/// </summary>
function DialogPPI: Integer;
/// <summary>
///   Gets a form built in code ready to be laid out at APPI: VCL does not scale it, and
///   its font is the Windows message font at APPI. Call it before creating the controls.
/// </summary>
procedure PrepareDialog(AForm: TCustomForm; APPI: Integer);
/// <summary>
///   Sizes the window of a form laid out with PrepareDialog so that, on the monitor at
///   APPI, its client area is the ClientWidth and ClientHeight the layout set. Call it
///   once the layout is done, before the form is shown.
/// </summary>
procedure FitDialogFrame(AForm: TCustomForm; APPI: Integer);
/// <summary>AValue pixels at 96 DPI, in pixels at APPI.</summary>
function DialogScale(AValue, APPI: Integer): Integer;
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
  System.Types,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.Dialogs,
  ToolsAPI;

type
  TFormAccess = class(TCustomForm);

var
  ThemedClasses: TArray<TClass>; // registered with the IDE theming once each

function DialogPPI: Integer;
begin
  Result := 0;
  if (Application.MainForm <> nil) and Application.MainForm.HandleAllocated then
    Result := GetDpiForWindow(Application.MainForm.Handle);
  if Result <= 0 then
    Result := Screen.PixelsPerInch;
  if Result < Screen.DefaultPixelsPerInch then
    Result := Screen.DefaultPixelsPerInch;
end;

procedure PrepareDialog(AForm: TCustomForm; APPI: Integer);
var
  Form: TFormAccess;
begin
  Form := TFormAccess(AForm);
  Form.Scaled := False;
  // The message font is at the system DPI, which differs from APPI when the IDE window
  // is on a monitor with another scale
  Form.Font.Assign(Screen.MessageFont);
  Form.Font.Height := MulDiv(Screen.MessageFont.Height, APPI, Screen.PixelsPerInch);
end;

procedure FitDialogFrame(AForm: TCustomForm; APPI: Integer);
var
  Params: TCreateParams;
  R: TRect;
begin
  // VCL sizes the window with the frame of the form's own DPI, which stays 96 as the
  // form is not scaled; the frame on a monitor at APPI is thicker
  TFormAccess(AForm).CreateParams(Params);
  R := Rect(0, 0, AForm.ClientWidth, AForm.ClientHeight);
  if AdjustWindowRectExForDpi(R, Params.Style, False, Params.ExStyle, APPI) then
    AForm.SetBounds(AForm.Left, AForm.Top, R.Width, R.Height);
end;

function DialogScale(AValue, APPI: Integer): Integer;
begin
  Result := MulDiv(AValue, APPI, 96);
end;

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
    FPPI: Integer;
    function Scale(AValue: Integer): Integer;
  end;

function TTextForm.Scale(AValue: Integer): Integer;
begin
  Result := DialogScale(AValue, FPPI);
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
    Form.FPPI := DialogPPI;
    PrepareDialog(Form, Form.FPPI);
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
    FitDialogFrame(Form, Form.FPPI);

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
