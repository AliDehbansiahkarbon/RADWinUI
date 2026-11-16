unit RADWinUI.TextFields;

{
  Ready-made text fields, on the Tool Palette's Text Fields category. In
  XAML they live in xmlns:rw="using:RADWinUI.Controls", like RADWinUI's
  other own controls.

  TWinUIOtpCodeField        code boxes fill one by one, then turn mint in a wave
  TWinUICardNumberField     card digits group as you type, then the expiry fields slide in
  TWinUIStrengthMeterField  a four-step meter fills and recolours as the password grows
  TWinUIAutoGrowField       a note field that grows a line at a time with a soft spring
  TWinUITagInputField       each typed word pops into a chip you can remove with x
  TWinUIGhostCompleteField  a gray completion appears; Tab or a click fills it in

  They share TWinUITextField: Header, Text, PlaceholderText, the accent
  colours and TextChanged. The typing happens in real WinUI text boxes, so
  the caret, selection, clipboard, input methods and screen readers work as
  in any TextBox.

  Using this unit registers them.
}

interface

{$SCOPEDENUMS ON}

uses
  System.SysUtils,
  RADWinUI.Interop.Core,
  RADWinUI.Abi,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Forms,
  RADWinUI.CustomControls,
  RADWinUI.DrawnControls;

const
  /// <summary>The Tool Palette category of the text fields.</summary>
  TextFieldsCategory = 'Text Fields';

type
  /// <summary>An input of a text field: a TextBox or a PasswordBox, and its event registrations.</summary>
  TWinUITextFieldInput = record
    Element: IUIElement;
    TextBox: ITextBox;
    PasswordBox: IPasswordBox;
    ChangedToken, GotToken, LostToken, KeyToken: EventRegistrationToken;
  end;

  /// <summary>The base of the text fields: the header, the field box and the inputs. Not registered itself.</summary>
  TWinUITextField = class(TWinUIDrawnControl)
  strict private
    FInputs: TArray<TWinUITextFieldInput>;
    procedure Unhook;
  protected
    /// <summary>Text is being copied between the property and the input, so no echo.</summary>
    FSyncing: Boolean;
    /// <summary>An input has the focus; FFocus follows it, 0 .. 1.</summary>
    FFocused: Boolean;
    FFocus: Double;
    FHeaderSize: RADWinUI.Abi.Size;
    class procedure DefineType(AType: TWinUICustomType); override;
    class function TakesFocus: Boolean; override;
    class function DefaultHeader: string; virtual;
    class function DefaultPlaceholder: string; virtual;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure DetachEvents; override;
    procedure StyleLoaded; override;
    procedure StyleLive; override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
    function PointerDown(AX, AY: Double): Boolean; override;
    { The inputs }
    /// <summary>Creates a TextBox in the live panel. AExtra: more XAML attributes.</summary>
    function NewTextBox(const AName: string; AMultiLine: Boolean; const AExtra: string = ''): ITextBox;
    /// <summary>Creates a PasswordBox in the live panel.</summary>
    function NewPasswordBox(const AName: string): IPasswordBox;
    /// <summary>The first input: Text is its text, a click on the field focuses it.</summary>
    function MainInput: IUIElement;
    function InputText(const AElement: IUIElement): string;
    procedure SetInputText(const AElement: IUIElement; const AText: string);
    /// <summary>Puts the caret of a TextBox at the end.</summary>
    procedure CaretToEnd(const AElement: IUIElement);
    procedure FocusInput(const AElement: IUIElement);
    /// <summary>The text of input AElement changed (typing, paste, code).</summary>
    procedure InputChanged(const AElement: IUIElement); virtual;
    /// <summary>A key goes down in input AElement, before the input sees it. Set AHandled to keep it from the input.</summary>
    procedure InputKey(const AElement: IUIElement; AKey: TWinUIVirtualKey; var AHandled: Boolean); virtual;
    procedure InputFocusChanged; virtual;
    /// <summary>Text was set from code or XAML: show it in the inputs.</summary>
    procedure ApplyText; virtual;
    { The look }
    function HeaderHeight: Double;
    /// <summary>XAML of the header and the field box (Box, a Rectangle).</summary>
    function FieldXaml: string;
    /// <summary>Places the field box, its edge lit by the focus or by AColor (with AAmount).</summary>
    procedure LayoutBox(ALeft, ATop, AWidth, AHeight: Double; const AEdge: TWinUIColor; AEdgeAmount: Double);
    function FieldFill: TWinUIColor;
    function ShiftDown: Boolean;
    function ControlDown: Boolean;
    { Accessibility: the inputs speak for themselves, the header names them }
    function AutomationName: string; override;
  public
    /// <summary>Moves the focus into the field.</summary>
    procedure FocusField;
  published
    /// <summary>The small caption above the field.</summary>
    property Header: string index 2 read GetText write SetText;
    property Text: string index 3 read GetText write SetText;
    property PlaceholderText: string index 4 read GetText write SetText;
    property OnTextChanged: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

  /// <summary>One box per digit: they fill one by one, then turn mint in a wave with "Verified".</summary>
  TWinUIOtpCodeField = class(TWinUITextField)
  strict private
    FVerified: Boolean;
    FFailed: Boolean;
    FStateAge: Double;
    FFill: TArray<Double>;
    function Digits: string;
    function BoxSize: Double;
    function BoxLeft(AIndex: Integer): Double;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultWidth: Double; override;
    class function DefaultHeight: Double; override;
    class function DefaultHeader: string; override;
    class function DefaultAccentFrom: TWinUIColor; override;
    class function DefaultAccentTo: TWinUIColor; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure BuildLive; override;
    function StyleXaml: string; override;
    procedure LayoutControl; override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
    procedure InputChanged(const AElement: IUIElement); override;
    procedure ApplyText; override;
  public
    /// <summary>Shows the code as right (the mint wave and VerifiedText) or wrong (a shake, then empty boxes).</summary>
    procedure Verify(AValid: Boolean);
    procedure Clear;
    property IsVerified: Boolean read FVerified;
  published
    /// <summary>How many digits the code has.</summary>
    property CodeLength: Integer index 5 read GetInt32 write SetInt32;
    /// <summary>The caption under the boxes once verified.</summary>
    property VerifiedText: string index 6 read GetText write SetText;
    /// <summary>A full code is shown as verified at once. Off: call Verify after checking it.</summary>
    property AutoVerify: Boolean index 7 read GetBoolean write SetBoolean;
    /// <summary>Every digit is typed.</summary>
    property OnCompleted: TWinUIWinValueEventHandler index 1 read GetHandler write SetHandler;
  end;

  /// <summary>The card digits group in fours as you type; then they fold to the last four and the expiry and CVC slide in.</summary>
  TWinUICardNumberField = class(TWinUITextField)
  strict private
    FExpiryBox, FCvcBox: IUIElement;
    FFold, FFoldSpeed: Double;
    FFolded: Boolean;
    FLastFour: string;
    FWasComplete: Boolean;
    function NumberDigits: string;
    procedure SetFolded(AFolded: Boolean);
    /// <summary>Raises Completed when the card has just become complete.</summary>
    procedure CheckComplete;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultHeader: string; override;
    class function DefaultPlaceholder: string; override;
    class function DefaultHeight: Double; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure BuildLive; override;
    function StyleXaml: string; override;
    procedure LayoutControl; override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
    function PointerDown(AX, AY: Double): Boolean; override;
    procedure InputChanged(const AElement: IUIElement); override;
    procedure InputKey(const AElement: IUIElement; AKey: TWinUIVirtualKey; var AHandled: Boolean); override;
    procedure ApplyText; override;
  public
    /// <summary>The number, expiry and CVC are all filled in.</summary>
    function IsComplete: Boolean;
  published
    /// <summary>The expiry as MM/YY.</summary>
    property Expiry: string index 5 read GetText write SetText;
    property Cvc: string index 6 read GetText write SetText;
    property OnCompleted: TWinUIWinValueEventHandler index 1 read GetHandler write SetHandler;
  end;

  /// <summary>A password field with a four-step meter that fills and recolours as the password grows.</summary>
  TWinUIStrengthMeterField = class(TWinUITextField)
  strict private
    FScore: Integer;
    FShownScore, FScoreSpeed: Double;
    FLabelAge: Double;
    FLabelText: string;
    function GetScore: Integer;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultHeader: string; override;
    class function DefaultPlaceholder: string; override;
    class function DefaultHeight: Double; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure BuildLive; override;
    procedure StyleLive; override;
    function StyleXaml: string; override;
    procedure LayoutControl; override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
    procedure InputChanged(const AElement: IUIElement); override;
    procedure ApplyText; override;
  public
    /// <summary>0 for none, then 1 Weak, 2 Fair, 3 Good, 4 Strong.</summary>
    class function PasswordScore(const APassword: string): Integer; static;
    function ScoreColor(AScore: Integer): TWinUIColor;
    property Score: Integer read GetScore;
  published
    /// <summary>Shows the password as text, not as dots.</summary>
    property RevealPassword: Boolean index 5 read GetBoolean write SetBoolean;
    /// <summary>The four names of the steps, separated by commas.</summary>
    property ScoreLabels: string index 6 read GetText write SetText;
  end;

  /// <summary>A note field that grows a line at a time with a soft spring, with a send button.</summary>
  TWinUIAutoGrowField = class(TWinUITextField)
  strict private
    FBoxHeight, FBoxSpeed: Double;
    FSendAge: Double;
    FSendDown: Boolean;
    function TargetBoxHeight: Double;
    function LineHeight: Double;
    function SendRect(out ALeft, ATop, ASize: Double): Boolean;
    procedure Send;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultHeader: string; override;
    class function DefaultPlaceholder: string; override;
    class function DefaultHeight: Double; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure BuildLive; override;
    function StyleXaml: string; override;
    procedure LayoutControl; override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
    function PointerDown(AX, AY: Double): Boolean; override;
    procedure PointerUp(AX, AY: Double; AInside: Boolean); override;
    procedure InputChanged(const AElement: IUIElement); override;
    procedure InputKey(const AElement: IUIElement; AKey: TWinUIVirtualKey; var AHandled: Boolean); override;
  published
    /// <summary>The most lines it grows to; then it scrolls.</summary>
    property MaxLines: Integer index 5 read GetInt32 write SetInt32;
    /// <summary>The round send button at the end. Ctrl+Enter sends too.</summary>
    property ShowSendButton: Boolean index 6 read GetBoolean write SetBoolean;
    /// <summary>The send button or Ctrl+Enter: Text is what was sent, the field is empty again after.</summary>
    property OnSubmitted: TWinUIWinValueEventHandler index 1 read GetHandler write SetHandler;
  end;

  /// <summary>Each typed word pops into a chip; x or Backspace removes it.</summary>
  TWinUITagInputField = class(TWinUITextField)
  strict private type
    TChip = record
      Text: string;
      Element: IUIElement;
      Width, Height: Double;
      X, Y, ShownX, ShownY: Double;
      Age: Double;
      Leaving: Boolean;
      LeaveAge: Double;
    end;
  strict private
    FChips: TArray<TChip>;
    FInputX, FInputY, FInputWidth: Double;
    FBoxHeight, FBoxSpeed: Double;
    FArmed: Boolean;
    FSettingTags: Boolean;
    procedure AddChip(const AText: string; AAnimate: Boolean);
    procedure RemoveChip(AIndex: Integer);
    procedure ClearChips;
    procedure ArrangeChips;
    procedure TagsFromChips;
    procedure CommitWord;
    function ChipAt(AX, AY: Double; out AOnClose: Boolean): Integer;
    function BoxTop: Double;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultHeader: string; override;
    class function DefaultPlaceholder: string; override;
    class function DefaultHeight: Double; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure BuildLive; override;
    procedure StyleLive; override;
    function StyleXaml: string; override;
    procedure LayoutControl; override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
    function PointerDown(AX, AY: Double): Boolean; override;
    procedure InputChanged(const AElement: IUIElement); override;
    procedure InputKey(const AElement: IUIElement; AKey: TWinUIVirtualKey; var AHandled: Boolean); override;
  public
    function TagCount: Integer;
  published
    /// <summary>The chips, separated by commas.</summary>
    property Tags: string index 5 read GetText write SetText;
    /// <summary>The most chips; 0 for no limit.</summary>
    property MaxTags: Integer index 6 read GetInt32 write SetInt32;
    property OnTagsChanged: TWinUIWinValueEventHandler index 1 read GetHandler write SetHandler;
  end;

  /// <summary>A gray completion appears after what you type; Tab, Right at the end or a click fills it in.</summary>
  TWinUIGhostCompleteField = class(TWinUITextField)
  strict private
    FSuggestion: string;
    FAccepted: Boolean;
    FAcceptAge: Double;
    FFilling: Boolean;
    FFillText: string;
    FHintSize: RADWinUI.Abi.Size;
    function FindSuggestion(const AText: string): string;
    procedure UpdateGhost;
    procedure Accept;
    function HintLeft: Double;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    class function DefaultHeader: string; override;
    class function DefaultPlaceholder: string; override;
    class function DefaultHeight: Double; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure BuildLive; override;
    procedure StyleLive; override;
    function StyleXaml: string; override;
    procedure StyleLoaded; override;
    procedure LayoutControl; override;
    procedure Advance(ASeconds: Double); override;
    function StillMoving: Boolean; override;
    function PointerDown(AX, AY: Double): Boolean; override;
    procedure InputChanged(const AElement: IUIElement); override;
    procedure InputKey(const AElement: IUIElement; AKey: TWinUIVirtualKey; var AHandled: Boolean); override;
  public
    /// <summary>The completion shown now, '' when there is none.</summary>
    property Suggestion: string read FSuggestion;
  published
    /// <summary>The completions, separated by commas, like gmail.com, outlook.com.</summary>
    property Suggestions: string index 5 read GetText write SetText;
    /// <summary>Completes only what follows this text, like @ for e-mail domains. Empty: the whole text.</summary>
    property CompleteAfter: string index 6 read GetText write SetText;
    /// <summary>The caption while a completion shows.</summary>
    property HintText: string index 7 read GetText write SetText;
    /// <summary>The caption once a completion was taken.</summary>
    property AcceptedText: string index 8 read GetText write SetText;
    property OnAccepted: TWinUIWinValueEventHandler index 1 read GetHandler write SetHandler;
  end;

implementation

uses
  Winapi.Windows,
  System.Math;

// Winapi.Windows has an RGB of its own that gives a COLORREF: this one gives a XAML colour
function Rgb(AR, AG, AB: Byte; AA: Byte = $FF): TWinUIColor; inline;
begin
  Result := RADWinUI.DrawnControls.Rgb(AR, AG, AB, AA);
end;

const
  HeaderIndex = DrawnOwnIndex;
  TextIndex = DrawnOwnIndex + 1;
  PlaceholderIndex = DrawnOwnIndex + 2;
  OwnIndex = DrawnOwnIndex + 3;
  TextChangedEvent = 0;
  OwnEvent = 1;
  FieldRadius = 10;

  // A TextBox with nothing but its text: the field draws the rest
  InputTemplate =
    '<TextBox.Template><ControlTemplate TargetType="TextBox">' +
    '<ScrollViewer x:Name="ContentElement" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}" ' +
    'HorizontalScrollMode="Auto" HorizontalScrollBarVisibility="Hidden" VerticalScrollMode="Auto" ' +
    'VerticalScrollBarVisibility="Hidden" IsHorizontalRailEnabled="False" IsVerticalRailEnabled="False" ' +
    'ZoomMode="Disabled" IsTabStop="False" AutomationProperties.AccessibilityView="Raw" />' +
    '</ControlTemplate></TextBox.Template>';

  PasswordTemplate =
    '<PasswordBox.Template><ControlTemplate TargetType="PasswordBox">' +
    '<ScrollViewer x:Name="ContentElement" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}" ' +
    'HorizontalScrollMode="Auto" HorizontalScrollBarVisibility="Hidden" VerticalScrollMode="Disabled" ' +
    'VerticalScrollBarVisibility="Disabled" IsHorizontalRailEnabled="False" ZoomMode="Disabled" IsTabStop="False" ' +
    'AutomationProperties.AccessibilityView="Raw" />' +
    '</ControlTemplate></PasswordBox.Template>';

function OnlyDigits(const AText: string): string;
var
  C: Char;
begin
  Result := '';
  for C in AText do
    if CharInSet(C, ['0'..'9']) then
      Result := Result + C;
end;

{ TWinUITextField }

class procedure TWinUITextField.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Header', TWinUIPropertyKind.Text, DefaultHeader);
  AType.AddProperty('Text', TWinUIPropertyKind.Text, '');
  AType.AddProperty('PlaceholderText', TWinUIPropertyKind.Text, DefaultPlaceholder);
  AType.AddEvent('TextChanged');
end;

class function TWinUITextField.TakesFocus: Boolean;
begin
  // The text boxes inside take the focus
  Result := False;
end;

class function TWinUITextField.DefaultHeader: string;
begin
  Result := '';
end;

class function TWinUITextField.DefaultPlaceholder: string;
begin
  Result := '';
end;

procedure TWinUITextField.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    HeaderIndex, PlaceholderIndex:
      Rebuild;
    TextIndex:
      begin
        if not FSyncing then
          ApplyText;
        Fire(TextChangedEvent);
        StartRendering;
      end;
  end;
end;

procedure TWinUITextField.DetachEvents;
begin
  Unhook;
  inherited;
end;

procedure TWinUITextField.Unhook;
var
  I: Integer;
begin
  for I := 0 to High(FInputs) do
  begin
    if FInputs[I].GotToken.Value = 0 then
      Continue;
    if FInputs[I].TextBox <> nil then
      FInputs[I].TextBox.remove_TextChanged(FInputs[I].ChangedToken)
    else if FInputs[I].PasswordBox <> nil then
      FInputs[I].PasswordBox.remove_PasswordChanged(FInputs[I].ChangedToken);
    FInputs[I].Element.remove_GotFocus(FInputs[I].GotToken);
    FInputs[I].Element.remove_LostFocus(FInputs[I].LostToken);
    FInputs[I].Element.remove_PreviewKeyDown(FInputs[I].KeyToken);
  end;
  FInputs := nil;
end;

function TWinUITextField.HeaderHeight: Double;
begin
  if Header = '' then
    Result := 0
  else
    Result := Max(14, FHeaderSize.Height) + 6;
end;

function TWinUITextField.FieldFill: TWinUIColor;
begin
  Result := ForSurface(MixColor(SurfaceColor, Rgb(0, 0, 0), 0.22), MixColor(SurfaceColor, Rgb($F2, $F0, $F7), 0.8));
end;

function TWinUITextField.FieldXaml: string;
begin
  Result := '<TextBlock x:Name="Header" Text="' + XmlText(Header) + '" FontSize="' + Num(FontSize - 3) +
    '" Foreground="' + ColorHex(MutedColor) + '" />' +
    '<Canvas x:Name="BoxGlow" />' +
    '<Rectangle x:Name="Box" RadiusX="' + Num(FieldRadius) + '" RadiusY="' + Num(FieldRadius) + '" Fill="' +
    ColorHex(FieldFill) + '" Stroke="' + ColorHex(LineColor) + '" StrokeThickness="1.5" />';
end;

procedure TWinUITextField.StyleLoaded;
begin
  FHeaderSize := MeasurePart('Header');
  SetOpacity(UIPart('Header'), Ord(Header <> ''));
end;

procedure TWinUITextField.LayoutBox(ALeft, ATop, AWidth, AHeight: Double; const AEdge: TWinUIColor;
  AEdgeAmount: Double);
var
  Box: IUIElement;
  Edge: TWinUIColor;
begin
  Place(UIPart('Header'), ALeft + 2, 0);
  Box := UIPart('Box');
  Resize(Box, AWidth, AHeight);
  Place(Box, ALeft, ATop);
  Edge := MixColor(LineColor, MixColor(AccentFromColor, AccentToColor, 0.35), FFocus);
  StrokePart('Box', MixColor(Edge, AEdge, AEdgeAmount));
end;

function TWinUITextField.NewTextBox(const AName: string; AMultiLine: Boolean; const AExtra: string): ITextBox;
var
  Element: IUIElement;
  Xaml: string;
begin
  Xaml := '<TextBox x:Name="' + AName + '" Padding="0" MinHeight="0" MinWidth="0" BorderThickness="0" ' +
    'Background="Transparent" IsSpellCheckEnabled="False" IsTextPredictionEnabled="False"';
  if AMultiLine then
    Xaml := Xaml + ' AcceptsReturn="True" TextWrapping="Wrap"'
  else
    Xaml := Xaml + ' TextWrapping="NoWrap"';
  Xaml := Xaml + ' ' + AExtra + '>' + InputTemplate + '</TextBox>';
  Element := AddLive(Xaml);
  Result := Element as ITextBox;
  SetLength(FInputs, Length(FInputs) + 1);
  FInputs[High(FInputs)].Element := Element;
  FInputs[High(FInputs)].TextBox := Result;
end;

function TWinUITextField.NewPasswordBox(const AName: string): IPasswordBox;
var
  Element: IUIElement;
begin
  Element := AddLive('<PasswordBox x:Name="' + AName + '" Padding="0" MinHeight="0" MinWidth="0" BorderThickness="0" ' +
    'Background="Transparent">' + PasswordTemplate + '</PasswordBox>');
  Result := Element as IPasswordBox;
  SetLength(FInputs, Length(FInputs) + 1);
  FInputs[High(FInputs)].Element := Element;
  FInputs[High(FInputs)].PasswordBox := Result;
end;

procedure TWinUITextField.StyleLive;
var
  I: Integer;
  Self_: TWinUITextField;
  Element: IUIElement;
  Control: IControl;
begin
  Self_ := Self;
  for I := 0 to High(FInputs) do
  begin
    Element := FInputs[I].Element;
    Control := Element as IControl;
    Control.Foreground := NewBrush(TextColor);
    Control.FontSize := FontSize;
    if FInputs[I].TextBox <> nil then
      FInputs[I].TextBox.SelectionHighlightColor := RADWinUI.Abi.SolidColorBrush.New(AccentFromColor)
    else
      FInputs[I].PasswordBox.SelectionHighlightColor := RADWinUI.Abi.SolidColorBrush.New(AccentFromColor);
    Control.IsEnabled := ControlIntf.IsEnabled;
    // The events once, on the first style
    if FInputs[I].GotToken.Value <> 0 then
      Continue;
    if FInputs[I].TextBox <> nil then
      FInputs[I].ChangedToken := FInputs[I].TextBox.add_TextChanged(TTextChangedEventHandler.Create(
        procedure(ASender: IInspectable; AE: ITextChangedEventArgs)
        begin
          Self_.InputChanged(ASender as IUIElement);
          Self_.StartRendering;
        end))
    else
      FInputs[I].ChangedToken := FInputs[I].PasswordBox.add_PasswordChanged(TRoutedEventHandler.Create(
        procedure(ASender: IInspectable; AE: IRoutedEventArgs)
        begin
          Self_.InputChanged(ASender as IUIElement);
          Self_.StartRendering;
        end));
    FInputs[I].GotToken := Element.add_GotFocus(TRoutedEventHandler.Create(
      procedure(ASender: IInspectable; AE: IRoutedEventArgs)
      begin
        Self_.FFocused := True;
        Self_.InputFocusChanged;
        Self_.StartRendering;
      end));
    FInputs[I].LostToken := Element.add_LostFocus(TRoutedEventHandler.Create(
      procedure(ASender: IInspectable; AE: IRoutedEventArgs)
      begin
        Self_.FFocused := False;
        Self_.InputFocusChanged;
        Self_.StartRendering;
      end));
    FInputs[I].KeyToken := Element.add_PreviewKeyDown(TKeyEventHandler.Create(
      procedure(ASender: IInspectable; AE: IKeyRoutedEventArgs)
      var
        Handled: Boolean;
      begin
        Handled := False;
        Self_.InputKey(ASender as IUIElement, AE.Key, Handled);
        if Handled then
          AE.Handled := True;
        Self_.StartRendering;
      end));
  end;
end;

function TWinUITextField.MainInput: IUIElement;
begin
  if Length(FInputs) = 0 then
    Result := nil
  else
    Result := FInputs[0].Element;
end;

function TWinUITextField.InputText(const AElement: IUIElement): string;
var
  Box: ITextBox;
  Password: IPasswordBox;
begin
  if Supports(AElement, ITextBox, Box) then
    Result := TakeHString(Box.Text)
  else if Supports(AElement, IPasswordBox, Password) then
    Result := TakeHString(Password.Password)
  else
    Result := '';
end;

procedure TWinUITextField.SetInputText(const AElement: IUIElement; const AText: string);
var
  Box: ITextBox;
  Password: IPasswordBox;
begin
  if InputText(AElement) = AText then
    Exit;
  if Supports(AElement, ITextBox, Box) then
    Box.Text := WinStr(AText)
  else if Supports(AElement, IPasswordBox, Password) then
    Password.Password := WinStr(AText);
end;

procedure TWinUITextField.CaretToEnd(const AElement: IUIElement);
var
  Box: ITextBox;
begin
  if Supports(AElement, ITextBox, Box) then
  begin
    Box.SelectionStart := Length(InputText(AElement));
    Box.SelectionLength := 0;
  end;
end;

procedure TWinUITextField.FocusInput(const AElement: IUIElement);
begin
  if AElement <> nil then
    AElement.Focus(RADWinUI.Abi.FocusState.Programmatic);
end;

procedure TWinUITextField.FocusField;
begin
  FocusInput(MainInput);
end;

procedure TWinUITextField.InputChanged(const AElement: IUIElement);
begin
  if AElement <> MainInput then
    Exit;
  FSyncing := True;
  try
    Text := InputText(AElement);
  finally
    FSyncing := False;
  end;
end;

procedure TWinUITextField.InputKey(const AElement: IUIElement; AKey: TWinUIVirtualKey; var AHandled: Boolean);
begin
end;

procedure TWinUITextField.InputFocusChanged;
begin
end;

procedure TWinUITextField.ApplyText;
begin
  if MainInput <> nil then
    SetInputText(MainInput, Text);
end;

procedure TWinUITextField.Advance(ASeconds: Double);
begin
  inherited;
  FFocus := Approach(FFocus, Ord(FFocused), ASeconds, 0.18);
end;

function TWinUITextField.StillMoving: Boolean;
begin
  Result := inherited or (Abs(FFocus - Ord(FFocused)) > 0.001);
end;

function TWinUITextField.PointerDown(AX, AY: Double): Boolean;
begin
  // A click on the field but beside the text box still types into it
  FocusField;
  Result := False;
end;

function TWinUITextField.ShiftDown: Boolean;
begin
  Result := GetKeyState(VK_SHIFT) < 0;
end;

function TWinUITextField.ControlDown: Boolean;
begin
  Result := GetKeyState(VK_CONTROL) < 0;
end;

function TWinUITextField.AutomationName: string;
begin
  Result := Header;
  if Result = '' then
    Result := PlaceholderText;
end;

{ TWinUIOtpCodeField }

const
  OtpLengthIndex = OwnIndex;
  OtpVerifiedTextIndex = OwnIndex + 1;
  OtpAutoVerifyIndex = OwnIndex + 2;
  OtpMaxDigits = 10;

class procedure TWinUIOtpCodeField.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('CodeLength', TWinUIPropertyKind.Int32, '6');
  AType.AddProperty('VerifiedText', TWinUIPropertyKind.Text, 'Verified');
  AType.AddProperty('AutoVerify', TWinUIPropertyKind.Boolean, 'True');
  AType.AddEvent('Completed');
end;

class function TWinUIOtpCodeField.DefaultWidth: Double;
begin
  Result := 300;
end;

class function TWinUIOtpCodeField.DefaultHeight: Double;
begin
  Result := 92;
end;

class function TWinUIOtpCodeField.DefaultHeader: string;
begin
  Result := 'Enter the code we sent';
end;

class function TWinUIOtpCodeField.DefaultAccentFrom: TWinUIColor;
begin
  Result := Rgb($7C, $5C, $FF);
end;

class function TWinUIOtpCodeField.DefaultAccentTo: TWinUIColor;
begin
  Result := Rgb($4F, $9C, $FF);
end;

function TWinUIOtpCodeField.Digits: string;
begin
  Result := OnlyDigits(Text);
end;

function TWinUIOtpCodeField.BoxSize: Double;
var
  Count: Integer;
begin
  Count := EnsureRange(CodeLength, 1, OtpMaxDigits);
  Result := Max(18, Min(44, (FWidth - 8 * (Count - 1)) / Count));
end;

function TWinUIOtpCodeField.BoxLeft(AIndex: Integer): Double;
var
  Count: Integer;
  Total: Double;
begin
  Count := EnsureRange(CodeLength, 1, OtpMaxDigits);
  Total := Count * BoxSize + (Count - 1) * 8;
  Result := (FWidth - Total) / 2 + AIndex * (BoxSize + 8);
end;

procedure TWinUIOtpCodeField.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    OtpLengthIndex, OtpVerifiedTextIndex:
      Rebuild;
  end;
end;

procedure TWinUIOtpCodeField.BuildLive;
var
  Box: ITextBox;
begin
  // One invisible TextBox over the boxes takes the typing; the boxes show it
  Box := NewTextBox('Input', False, 'Opacity="0" InputScope="Number"');
  Box.MaxLength := OtpMaxDigits;
end;

function TWinUIOtpCodeField.StyleXaml: string;
var
  I, Count: Integer;
begin
  Count := EnsureRange(CodeLength, 1, OtpMaxDigits);
  Result := '<TextBlock x:Name="Header" Text="' + XmlText(Header) + '" FontSize="' + Num(FontSize - 3) +
    '" Foreground="' + ColorHex(MutedColor) + '" />';
  for I := 0 to Count - 1 do
    Result := Result + '<Rectangle x:Name="B' + IntToStr(I) + '" RadiusX="8" RadiusY="8" StrokeThickness="1.5" />' +
      CenteredTextXaml('D' + IntToStr(I), '', FontSize + 3, 'SemiBold', TextColor);
  Result := Result + '<Rectangle x:Name="Caret" Width="2" RadiusX="1" RadiusY="1" Fill="' + ColorHex(AccentFromColor) + '" />' +
    '<StackPanel x:Name="Verified" Orientation="Horizontal">' +
    '<Grid Width="14" Height="14" Margin="0,0,5,0"><Ellipse Fill="' + ColorHex(SuccessColor) + '" />' +
    '<FontIcon Glyph="' + GlyphXml(CheckGlyph) + '" FontSize="8" Foreground="White" /></Grid>' +
    '<TextBlock x:Name="VerifiedLabel" Text="' + XmlText(VerifiedText) + '" FontSize="' + Num(FontSize - 3) +
    '" FontWeight="SemiBold" Foreground="' + ColorHex(SuccessColor) + '" VerticalAlignment="Center" /></StackPanel>';
  SetLength(FFill, Count);
end;

procedure TWinUIOtpCodeField.ApplyText;
begin
  inherited;
  FVerified := False;
  FFailed := False;
end;

procedure TWinUIOtpCodeField.InputChanged(const AElement: IUIElement);
var
  Typed, Clean: string;
  Count: Integer;
begin
  Count := EnsureRange(CodeLength, 1, OtpMaxDigits);
  Typed := InputText(AElement);
  // Digits only, at most CodeLength: a pasted "482 913" works too
  Clean := OnlyDigits(Typed);
  if Length(Clean) > Count then
    Clean := Clean.Substring(0, Count);
  if Clean <> Typed then
  begin
    SetInputText(AElement, Clean);
    CaretToEnd(AElement);
    Exit;
  end;
  FSyncing := True;
  try
    Text := Clean;
  finally
    FSyncing := False;
  end;
  if FVerified or FFailed then
  begin
    FVerified := False;
    FFailed := False;
  end;
  if Length(Clean) = Count then
  begin
    Fire(OwnEvent);
    if AutoVerify then
      Verify(True);
  end;
end;

procedure TWinUIOtpCodeField.Verify(AValid: Boolean);
begin
  FVerified := AValid;
  FFailed := not AValid;
  FStateAge := 0;
  StartRendering;
end;

procedure TWinUIOtpCodeField.Clear;
begin
  FVerified := False;
  FFailed := False;
  Text := '';
end;

procedure TWinUIOtpCodeField.Advance(ASeconds: Double);
var
  I: Integer;
  Typed: string;
begin
  inherited;
  FStateAge := FStateAge + ASeconds;
  Typed := Digits;
  for I := 0 to High(FFill) do
    FFill[I] := Approach(FFill[I], Ord(I < Length(Typed)), ASeconds, 0.16);
  // A wrong code shakes, then the boxes empty
  if FFailed and (FStateAge > 0.65) then
  begin
    FFailed := False;
    Text := '';
  end;
end;

function TWinUIOtpCodeField.StillMoving: Boolean;
var
  I: Integer;
  Typed: string;
begin
  // The caret blinks while the field has the focus
  Result := inherited or FFocused or FFailed or (FVerified and (FStateAge < 1.2));
  Typed := Digits;
  for I := 0 to High(FFill) do
    if Abs(FFill[I] - Ord(I < Length(Typed))) > 0.001 then
      Exit(True);
end;

procedure TWinUIOtpCodeField.LayoutControl;
var
  I, Count, Current: Integer;
  Size, Top, Left, Wave, Lift, Shake, Pop: Double;
  Typed, Digit: string;
  Edge, Fill: TWinUIColor;
  Element: IUIElement;
begin
  Count := EnsureRange(CodeLength, 1, OtpMaxDigits);
  Typed := Digits;
  Size := BoxSize;
  Top := HeaderHeight;
  Place(UIPart('Header'), Max(0, BoxLeft(0)) + 2, 0);
  Current := Min(Length(Typed), Count - 1);
  Shake := 0;
  if FFailed then
    Shake := 7 * Sin(FStateAge * 42) * Max(0, 1 - FStateAge / 0.5);
  for I := 0 to Count - 1 do
  begin
    Left := BoxLeft(I) + Shake;
    // The wave: each box turns mint a little after the one before it, and hops
    Wave := 0;
    Lift := 0;
    if FVerified then
    begin
      Wave := Clamp01((FStateAge - I * 0.07) / 0.22);
      Lift := -5 * Sin(Pi * Wave);
    end;
    if FFailed then
      Edge := DangerColor
    else if I = Current then
      Edge := MixColor(LineColor, AccentFromColor, FFocus * Ord(Length(Typed) < Count))
    else
      Edge := MixColor(LineColor, MixColor(LineColor, AccentFromColor, 0.5), FFill[I]);
    Edge := MixColor(Edge, SuccessColor, Wave);
    Fill := MixColor(FieldFill, MixColor(FieldFill, SuccessColor, 0.16), Wave);
    Element := UIPart('B' + IntToStr(I));
    Resize(Element, Size, Size * 1.12);
    Place(Element, Left, Top + Lift);
    StrokePart('B' + IntToStr(I), Edge);
    FillPart('B' + IntToStr(I), Fill);
    if I < Length(Typed) then
      Digit := Typed[I + 1]
    else
      Digit := '';
    TextPart('D' + IntToStr(I), Digit);
    Tint('D' + IntToStr(I), MixColor(TextColor, SuccessColor, Wave));
    Element := UIPart('D' + IntToStr(I) + 'Box');
    Resize(Element, Size, Size * 1.12);
    Place(Element, Left, Top + Lift);
    // A digit pops in as it is typed
    Pop := 0.6 + 0.4 * EaseOutBack(FFill[I]);
    ScaleAt(Element, Pop, Pop, Size / 2, Size * 0.56);
    Element.Opacity := Clamp01(FFill[I] * 1.4);
  end;
  // The caret blinks in the box being typed
  Element := UIPart('Caret');
  Resize(Element, 2, Size * 0.5);
  Place(Element, BoxLeft(Current) + Size / 2 - 1 + Shake, Top + Size * 0.31);
  SetOpacity(Element, Ord(FFocused and (Length(Typed) < Count)) * Ord(Frac(FClock * 1.1) < 0.6));
  Element := UIPart('Verified');
  Place(Element, BoxLeft(0) + (Count * (Size + 8) - 8) / 2 - MeasurePart('Verified').Width / 2,
    Top + Size * 1.12 + 8 + 4 * (1 - EaseOutCubic((FStateAge - Count * 0.07) / 0.3)));
  SetOpacity(Element, Ord(FVerified) * Clamp01((FStateAge - Count * 0.07) / 0.25));
  // The invisible input covers the boxes, so a click on any of them types
  Element := MainInput;
  if Element <> nil then
  begin
    Place(Element, BoxLeft(0), Top);
    Resize(Element, Count * (Size + 8) - 8, Size * 1.12);
  end;
end;

{ TWinUICardNumberField }

const
  CardExpiryIndex = OwnIndex;
  CardCvcIndex = OwnIndex + 1;
  CardDigits = 16;

class procedure TWinUICardNumberField.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Expiry', TWinUIPropertyKind.Text, '');
  AType.AddProperty('Cvc', TWinUIPropertyKind.Text, '');
  AType.AddEvent('Completed');
end;

class function TWinUICardNumberField.DefaultHeader: string;
begin
  Result := 'Card';
end;

class function TWinUICardNumberField.DefaultPlaceholder: string;
begin
  Result := 'Card number';
end;

class function TWinUICardNumberField.DefaultHeight: Double;
begin
  Result := 66;
end;

function TWinUICardNumberField.NumberDigits: string;
begin
  Result := OnlyDigits(Text);
end;

procedure TWinUICardNumberField.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    CardExpiryIndex:
      if not FSyncing and (FExpiryBox <> nil) then
        SetInputText(FExpiryBox, Expiry);
    CardCvcIndex:
      if not FSyncing and (FCvcBox <> nil) then
        SetInputText(FCvcBox, Cvc);
  end;
  // Completed also follows a card set from code
  if AIndex in [TextIndex, CardExpiryIndex, CardCvcIndex] then
    CheckComplete;
end;

procedure TWinUICardNumberField.CheckComplete;
var
  Complete: Boolean;
begin
  Complete := IsComplete;
  if Complete and not FWasComplete then
  begin
    FWasComplete := True;
    Fire(OwnEvent);
  end
  else if not Complete then
    FWasComplete := False;
end;

procedure TWinUICardNumberField.BuildLive;
begin
  NewTextBox('Number', False, 'InputScope="Number"').MaxLength := CardDigits + 3;
  FExpiryBox := NewTextBox('Expiry', False, 'InputScope="Number"') as IUIElement;
  (FExpiryBox as ITextBox).MaxLength := 5;
  FCvcBox := NewTextBox('Cvc', False, 'InputScope="Number"') as IUIElement;
  (FCvcBox as ITextBox).MaxLength := 4;
end;

function TWinUICardNumberField.StyleXaml: string;
begin
  Result := FieldXaml +
    // The card icon: a small rounded card with a stripe
    '<Canvas x:Name="Card"><Rectangle Width="22" Height="15" RadiusX="3" RadiusY="3" StrokeThickness="1.4" Stroke="' +
    ColorHex(MutedColor) + '" /><Rectangle Canvas.Top="4" Width="22" Height="2.5" Fill="' + ColorHex(MutedColor) +
    '" /><Rectangle Canvas.Left="3.5" Canvas.Top="9.5" Width="6" Height="2" RadiusX="1" RadiusY="1" Fill="' +
    ColorHex(MutedColor) + '" /></Canvas>' +
    '<TextBlock x:Name="NumberHint" Text="' + XmlText(PlaceholderText) + '" FontSize="' + Num(FontSize) +
    '" Foreground="' + ColorHex(MutedColor) + '" />' +
    '<TextBlock x:Name="Masked" FontSize="' + Num(FontSize) + '" Foreground="' + ColorHex(TextColor) + '" />' +
    '<TextBlock x:Name="ExpiryHint" Text="MM/YY" FontSize="' + Num(FontSize) + '" Foreground="' +
    ColorHex(MutedColor) + '" />' +
    '<TextBlock x:Name="CvcHint" Text="CVC" FontSize="' + Num(FontSize) + '" Foreground="' + ColorHex(MutedColor) + '" />' +
    '<Rectangle x:Name="Divider1" Width="1" Fill="' + ColorHex(LineColor) + '" />' +
    '<Rectangle x:Name="Divider2" Width="1" Fill="' + ColorHex(LineColor) + '" />';
end;

procedure TWinUICardNumberField.ApplyText;
var
  Digits, Grouped: string;
  I: Integer;
begin
  Digits := NumberDigits;
  Grouped := '';
  for I := 1 to Length(Digits) do
  begin
    if (I > 1) and ((I - 1) mod 4 = 0) then
      Grouped := Grouped + ' ';
    Grouped := Grouped + Digits[I];
  end;
  if MainInput <> nil then
    SetInputText(MainInput, Grouped);
  SetFolded(Length(Digits) >= CardDigits);
end;

procedure TWinUICardNumberField.SetFolded(AFolded: Boolean);
var
  Digits: string;
begin
  Digits := NumberDigits;
  if Length(Digits) >= 4 then
    FLastFour := Digits.Substring(Length(Digits) - 4)
  else
    FLastFour := Digits;
  if AFolded = FFolded then
    Exit;
  FFolded := AFolded;
  if Built then
    TextPart('Masked', #$2022#$2022#$2022#$2022' ' + FLastFour);
  if (FExpiryBox <> nil) then
  begin
    FExpiryBox.IsTabStop := AFolded;
    FCvcBox.IsTabStop := AFolded;
  end;
  StartRendering;
end;

procedure TWinUICardNumberField.InputChanged(const AElement: IUIElement);
var
  Typed, Digits, Grouped, Clean: string;
  I: Integer;
  WasFolded: Boolean;
begin
  Typed := InputText(AElement);
  if AElement = MainInput then
  begin
    Digits := OnlyDigits(Typed);
    if Length(Digits) > CardDigits then
      Digits := Digits.Substring(0, CardDigits);
    Grouped := '';
    for I := 1 to Length(Digits) do
    begin
      if (I > 1) and ((I - 1) mod 4 = 0) then
        Grouped := Grouped + ' ';
      Grouped := Grouped + Digits[I];
    end;
    // The digits group in fours as they are typed
    if Grouped <> Typed then
    begin
      SetInputText(AElement, Grouped);
      CaretToEnd(AElement);
      Exit;
    end;
    FSyncing := True;
    try
      Text := Digits;
    finally
      FSyncing := False;
    end;
    WasFolded := FFolded;
    SetFolded(Length(Digits) >= CardDigits);
    if FFolded and not WasFolded then
      FocusInput(FExpiryBox);
  end
  else if AElement = FExpiryBox then
  begin
    // MM/YY: the slash comes by itself
    Clean := OnlyDigits(Typed);
    if Length(Clean) > 4 then
      Clean := Clean.Substring(0, 4);
    if Length(Clean) > 2 then
      Clean := Clean.Substring(0, 2) + '/' + Clean.Substring(2)
    else if (Length(Clean) = 2) and (Length(Typed) > Length(Expiry)) then
      Clean := Clean + '/';
    if Clean <> Typed then
    begin
      SetInputText(AElement, Clean);
      CaretToEnd(AElement);
      Exit;
    end;
    FSyncing := True;
    try
      Expiry := Clean;
    finally
      FSyncing := False;
    end;
    if Length(Clean) = 5 then
      FocusInput(FCvcBox);
  end
  else if AElement = FCvcBox then
  begin
    Clean := OnlyDigits(Typed);
    if Clean <> Typed then
    begin
      SetInputText(AElement, Clean);
      CaretToEnd(AElement);
      Exit;
    end;
    FSyncing := True;
    try
      Cvc := Clean;
    finally
      FSyncing := False;
    end;
  end;
  CheckComplete;
end;

procedure TWinUICardNumberField.InputKey(const AElement: IUIElement; AKey: TWinUIVirtualKey; var AHandled: Boolean);
begin
  // Backspace in an empty expiry goes back to the number
  if (AKey = TWinUIVirtualKey.Back) and (AElement = FExpiryBox) and (InputText(FExpiryBox) = '') then
  begin
    SetFolded(False);
    FocusInput(MainInput);
    CaretToEnd(MainInput);
    AHandled := True;
  end
  else if (AKey = TWinUIVirtualKey.Back) and (AElement = FCvcBox) and (InputText(FCvcBox) = '') then
  begin
    FocusInput(FExpiryBox);
    CaretToEnd(FExpiryBox);
    AHandled := True;
  end;
end;

function TWinUICardNumberField.IsComplete: Boolean;
begin
  Result := (Length(NumberDigits) = CardDigits) and (Length(Expiry) = 5) and (Length(Cvc) >= 3);
end;

function TWinUICardNumberField.PointerDown(AX, AY: Double): Boolean;
begin
  // A click on the folded number opens it again
  if FFolded and (AX < FWidth * 0.42) then
  begin
    SetFolded(False);
    FocusInput(MainInput);
    CaretToEnd(MainInput);
    Exit(False);
  end;
  Result := inherited;
end;

procedure TWinUICardNumberField.Advance(ASeconds: Double);
begin
  inherited;
  SpringStep(FFold, FFoldSpeed, Ord(FFolded), ASeconds, 220, 24);
end;

function TWinUICardNumberField.StillMoving: Boolean;
begin
  Result := inherited or (Abs(FFold - Ord(FFolded)) > 0.001) or (Abs(FFoldSpeed) > 0.001);
end;

procedure TWinUICardNumberField.LayoutControl;
var
  Top, H, Inner, NumberLeft, NumberWidth, FoldedWidth, ExpiryLeft, CvcLeft, SlotWidth, Y, LineH, Slide: Double;
  Fold: Double;
  Element: IUIElement;
begin
  Top := HeaderHeight;
  H := Max(30, FHeight - Top);
  LayoutBox(0, Top, FWidth, H, AccentFromColor, 0);
  Fold := Clamp01(FFold);
  LineH := FontSize * 1.4;
  Y := Top + (H - LineH) / 2;
  Place(UIPart('Card'), 14, Top + (H - 15) / 2);
  NumberLeft := 46;
  Inner := FWidth - NumberLeft - 12;
  // Folded, the number keeps just the room for four dots and "2047"
  FoldedWidth := Min(Inner * 0.32, FontSize * 6.2);
  NumberWidth := Lerp(Inner, FoldedWidth, Fold);
  Element := MainInput;
  if Element <> nil then
  begin
    Place(Element, NumberLeft, Y);
    Resize(Element, Inner, LineH);
    Element.Opacity := 1 - Clamp01(Fold * 2);
    if Fold > 0.5 then
      Element.Visibility := TWinUIVisibility.Collapsed
    else
      Element.Visibility := TWinUIVisibility.Visible;
  end;
  Place(UIPart('NumberHint'), NumberLeft, Y);
  SetOpacity(UIPart('NumberHint'), Ord(Text = '') * (1 - Fold));
  TextPart('Masked', #$2022#$2022#$2022#$2022' ' + FLastFour);
  Place(UIPart('Masked'), NumberLeft, Y);
  SetOpacity(UIPart('Masked'), Clamp01(Fold * 2 - 1));
  // The expiry and CVC slide in from the right
  SlotWidth := (Inner - FoldedWidth) / 2;
  Slide := 40 * (1 - Fold);
  ExpiryLeft := NumberLeft + NumberWidth + 12 + Slide;
  CvcLeft := ExpiryLeft + SlotWidth + Slide * 0.6;
  Place(FExpiryBox, ExpiryLeft, Y);
  Resize(FExpiryBox, Max(10, SlotWidth - 16), LineH);
  SetOpacity(FExpiryBox, Fold);
  Place(FCvcBox, CvcLeft, Y);
  Resize(FCvcBox, Max(10, SlotWidth - 16), LineH);
  SetOpacity(FCvcBox, Fold);
  Place(UIPart('ExpiryHint'), ExpiryLeft, Y);
  SetOpacity(UIPart('ExpiryHint'), Fold * Ord(Expiry = ''));
  Place(UIPart('CvcHint'), CvcLeft, Y);
  SetOpacity(UIPart('CvcHint'), Fold * Ord(Cvc = ''));
  Element := UIPart('Divider1');
  Resize(Element, 1, LineH);
  Place(Element, ExpiryLeft - 8, Y);
  SetOpacity(Element, Fold * 0.8);
  Element := UIPart('Divider2');
  Resize(Element, 1, LineH);
  Place(Element, CvcLeft - 8, Y);
  SetOpacity(Element, Fold * 0.8);
end;

{ TWinUIStrengthMeterField }

const
  StrengthRevealIndex = OwnIndex;
  StrengthLabelsIndex = OwnIndex + 1;

class procedure TWinUIStrengthMeterField.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('RevealPassword', TWinUIPropertyKind.Boolean, 'False');
  AType.AddProperty('ScoreLabels', TWinUIPropertyKind.Text, 'Weak, Fair, Good, Strong');
end;

class function TWinUIStrengthMeterField.DefaultHeader: string;
begin
  Result := 'New password';
end;

class function TWinUIStrengthMeterField.DefaultPlaceholder: string;
begin
  Result := 'At least 8 characters';
end;

class function TWinUIStrengthMeterField.DefaultHeight: Double;
begin
  Result := 90;
end;

class function TWinUIStrengthMeterField.PasswordScore(const APassword: string): Integer;
var
  C: Char;
  Lower, Upper, Digit, Symbol: Boolean;
  Points: Integer;
begin
  if APassword = '' then
    Exit(0);
  Lower := False;
  Upper := False;
  Digit := False;
  Symbol := False;
  for C in APassword do
    if CharInSet(C, ['a'..'z']) then
      Lower := True
    else if CharInSet(C, ['A'..'Z']) then
      Upper := True
    else if CharInSet(C, ['0'..'9']) then
      Digit := True
    else if C > ' ' then
      Symbol := True;
  // Letters of another alphabet count as letters
  Points := 0;
  if Length(APassword) >= 8 then
    Inc(Points);
  if Lower and Upper then
    Inc(Points);
  if Digit then
    Inc(Points);
  if Symbol then
    Inc(Points);
  if Length(APassword) >= 14 then
    Inc(Points);
  if Length(APassword) < 6 then
    Points := Min(Points, 1);
  Result := EnsureRange(Points, 1, 4);
end;

function TWinUIStrengthMeterField.GetScore: Integer;
begin
  Result := FScore;
end;

function TWinUIStrengthMeterField.ScoreColor(AScore: Integer): TWinUIColor;
begin
  case AScore of
    1: Result := DangerColor;
    2: Result := WarningColor;
    3: Result := ForSurface(Rgb($4F, $B8, $FF), Rgb($1E, $88, $E5));
    4: Result := SuccessColor;
  else
    Result := SoftColor;
  end;
end;

procedure TWinUIStrengthMeterField.PropertyChanged(AIndex: Integer);
var
  Password: IPasswordBox;
begin
  inherited;
  case AIndex of
    StrengthRevealIndex:
      if Supports(MainInput, IPasswordBox, Password) then
        if RevealPassword then
          Password.PasswordRevealMode := RADWinUI.Abi.PasswordRevealMode.Visible
        else
          Password.PasswordRevealMode := RADWinUI.Abi.PasswordRevealMode.Hidden;
    StrengthLabelsIndex:
      FLabelText := '';
  end;
end;

procedure TWinUIStrengthMeterField.BuildLive;
begin
  NewPasswordBox('Input');
end;

procedure TWinUIStrengthMeterField.StyleLive;
var
  Password: IPasswordBox;
begin
  inherited;
  if Supports(MainInput, IPasswordBox, Password) then
    if RevealPassword then
      Password.PasswordRevealMode := RADWinUI.Abi.PasswordRevealMode.Visible
    else
      Password.PasswordRevealMode := RADWinUI.Abi.PasswordRevealMode.Hidden;
end;

function TWinUIStrengthMeterField.StyleXaml: string;
var
  I: Integer;
begin
  Result := FieldXaml +
    '<TextBlock x:Name="Hint" Text="' + XmlText(PlaceholderText) + '" FontSize="' + Num(FontSize) + '" Foreground="' +
    ColorHex(MutedColor) + '" />';
  for I := 0 to 3 do
    Result := Result + '<Rectangle x:Name="Seg' + IntToStr(I) + '" Height="4" RadiusX="2" RadiusY="2" Fill="' +
      ColorHex(SoftColor) + '" />' +
      '<Rectangle x:Name="Lit' + IntToStr(I) + '" Height="4" RadiusX="2" RadiusY="2" />';
  Result := Result + '<TextBlock x:Name="Label" FontSize="' + Num(FontSize - 3) + '" FontWeight="SemiBold" />';
  FLabelText := '';
end;

procedure TWinUIStrengthMeterField.ApplyText;
begin
  inherited;
  FScore := PasswordScore(Text);
end;

procedure TWinUIStrengthMeterField.InputChanged(const AElement: IUIElement);
var
  Before: Integer;
begin
  inherited;
  Before := FScore;
  FScore := PasswordScore(Text);
  if FScore <> Before then
    FLabelAge := 0;
end;

procedure TWinUIStrengthMeterField.Advance(ASeconds: Double);
begin
  inherited;
  SpringStep(FShownScore, FScoreSpeed, FScore, ASeconds, 160, 20);
  FLabelAge := FLabelAge + ASeconds;
end;

function TWinUIStrengthMeterField.StillMoving: Boolean;
begin
  Result := inherited or (Abs(FShownScore - FScore) > 0.001) or (Abs(FScoreSpeed) > 0.001) or (FLabelAge < 0.4);
end;

procedure TWinUIStrengthMeterField.LayoutControl;
var
  I: Integer;
  Top, BoxH, LineH, SegTop, SegW, Fill: Double;
  Element: IUIElement;
  Color: TWinUIColor;
  Labels: TArray<string>;
  Name: string;
  LabelSize: RADWinUI.Abi.Size;
begin
  Top := HeaderHeight;
  BoxH := 42;
  LayoutBox(0, Top, FWidth, BoxH, ScoreColor(FScore), 0.55 * Ord(FScore > 0) * (1 - FFocus * 0.4));
  LineH := FontSize * 1.4;
  Element := MainInput;
  if Element <> nil then
  begin
    Place(Element, 14, Top + (BoxH - LineH) / 2);
    Resize(Element, FWidth - 28, LineH);
  end;
  Place(UIPart('Hint'), 14, Top + (BoxH - LineH) / 2);
  SetOpacity(UIPart('Hint'), Ord(Text = ''));
  // Four steps under the field, filled up to the score in its colour
  SegTop := Top + BoxH + 8;
  SegW := (FWidth - 3 * 6) / 4;
  Color := ScoreColor(Max(1, Round(FShownScore)));
  for I := 0 to 3 do
  begin
    Element := UIPart('Seg' + IntToStr(I));
    Resize(Element, SegW, 4);
    Place(Element, I * (SegW + 6), SegTop);
    Fill := Clamp01(FShownScore - I);
    Element := UIPart('Lit' + IntToStr(I));
    Resize(Element, Max(4, SegW * Fill), 4);
    Place(Element, I * (SegW + 6), SegTop);
    SetOpacity(Element, Ord(Fill > 0.02));
    FillPart('Lit' + IntToStr(I), Color);
  end;
  Labels := SplitList(ScoreLabels);
  if (FScore > 0) and (FScore <= Length(Labels)) then
    Name := Labels[FScore - 1]
  else
    Name := '';
  if Name <> FLabelText then
  begin
    FLabelText := Name;
    TextPart('Label', Name);
  end;
  Tint('Label', ScoreColor(FScore));
  LabelSize := MeasurePart('Label');
  Element := UIPart('Label');
  Place(Element, FWidth - LabelSize.Width, SegTop + 9 + 4 * (1 - EaseOutCubic(FLabelAge / 0.3)));
  SetOpacity(Element, Ord(Name <> '') * Clamp01(FLabelAge / 0.2 + 0.3));
end;

{ TWinUIAutoGrowField }

const
  GrowMaxLinesIndex = OwnIndex;
  GrowSendIndex = OwnIndex + 1;
  GrowPadding = 12;

class procedure TWinUIAutoGrowField.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('MaxLines', TWinUIPropertyKind.Int32, '6');
  AType.AddProperty('ShowSendButton', TWinUIPropertyKind.Boolean, 'True');
  AType.AddEvent('Submitted');
end;

class function TWinUIAutoGrowField.DefaultHeader: string;
begin
  Result := '';
end;

class function TWinUIAutoGrowField.DefaultPlaceholder: string;
begin
  Result := 'Add a note...';
end;

class function TWinUIAutoGrowField.DefaultHeight: Double;
begin
  Result := 44;
end;

procedure TWinUIAutoGrowField.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    GrowMaxLinesIndex, GrowSendIndex:
      Rebuild;
  end;
end;

procedure TWinUIAutoGrowField.BuildLive;
begin
  NewTextBox('Input', True);
end;

function TWinUIAutoGrowField.StyleXaml: string;
begin
  Result := FieldXaml +
    '<TextBlock x:Name="Hint" Text="' + XmlText(PlaceholderText) + '" FontSize="' + Num(FontSize) + '" Foreground="' +
    ColorHex(MutedColor) + '" />' +
    '<Grid x:Name="Send"><Ellipse x:Name="SendIdle" Fill="' + ColorHex(SoftColor) + '" />' +
    '<Ellipse x:Name="SendLit"><Ellipse.Fill>' + GradientXaml(AccentFromColor, AccentToColor, 0, 0, 1, 1) +
    '</Ellipse.Fill></Ellipse>' +
    '<FontIcon x:Name="SendGlyph" Glyph="' + GlyphXml(ArrowUpGlyph) + '" FontSize="12" /></Grid>';
end;

function TWinUIAutoGrowField.LineHeight: Double;
begin
  Result := Round(FontSize * 1.33);
end;

function TWinUIAutoGrowField.TargetBoxHeight: Double;
var
  Element: IUIElement;
  Room: RADWinUI.Abi.Size;
  Lines, Width: Double;
begin
  Result := LineHeight + 2 * GrowPadding;
  Element := MainInput;
  if (Element = nil) or (FWidth <= 0) then
    Exit;
  // The text's own height at the input's width, up to MaxLines lines
  Width := FWidth - 2 * GrowPadding - Ord(ShowSendButton) * 36;
  Room.Width := Max(20, Width);
  Room.Height := 100000;
  // The input has no height of its own (LayoutControl sets only its width), so this is its text's height
  Element.Measure(Room);
  Lines := Max(1, Element.DesiredSize.Height / LineHeight);
  Lines := Min(Lines, Max(1, MaxLines));
  Result := Lines * LineHeight + 2 * GrowPadding;
end;

function TWinUIAutoGrowField.SendRect(out ALeft, ATop, ASize: Double): Boolean;
begin
  ASize := 28;
  ALeft := FWidth - ASize - 8;
  ATop := HeaderHeight + FBoxHeight - ASize - 8;
  Result := ShowSendButton;
end;

procedure TWinUIAutoGrowField.Send;
begin
  if Trim(Text) = '' then
    Exit;
  FSendAge := 0;
  Fire(OwnEvent);
  Text := '';
  FocusField;
end;

procedure TWinUIAutoGrowField.InputChanged(const AElement: IUIElement);
begin
  inherited;
  StartRendering;
end;

procedure TWinUIAutoGrowField.InputKey(const AElement: IUIElement; AKey: TWinUIVirtualKey; var AHandled: Boolean);
begin
  if (AKey = TWinUIVirtualKey.Enter) and ControlDown then
  begin
    Send;
    AHandled := True;
  end;
end;

function TWinUIAutoGrowField.PointerDown(AX, AY: Double): Boolean;
var
  Left, Top, Size: Double;
begin
  FSendDown := SendRect(Left, Top, Size) and (AX >= Left - 4) and (AX <= Left + Size + 4) and (AY >= Top - 4) and
    (AY <= Top + Size + 4);
  if FSendDown then
    Exit(True);
  Result := inherited;
end;

procedure TWinUIAutoGrowField.PointerUp(AX, AY: Double; AInside: Boolean);
begin
  if FSendDown and AInside then
    Send;
  FSendDown := False;
end;

procedure TWinUIAutoGrowField.Advance(ASeconds: Double);
begin
  inherited;
  if FBoxHeight <= 0 then
    FBoxHeight := TargetBoxHeight;
  // A soft spring with a little bounce, a line at a time
  SpringStep(FBoxHeight, FBoxSpeed, TargetBoxHeight, ASeconds, 190, 16);
  FSendAge := FSendAge + ASeconds;
end;

function TWinUIAutoGrowField.StillMoving: Boolean;
begin
  Result := inherited or (Abs(FBoxHeight - TargetBoxHeight) > 0.05) or (Abs(FBoxSpeed) > 0.05) or (FSendAge < 0.4);
end;

procedure TWinUIAutoGrowField.LayoutControl;
var
  Top, Left, SendTop, Size, InputWidth, Lit, Pop: Double;
  Element: IUIElement;
begin
  if FBoxHeight <= 0 then
    FBoxHeight := TargetBoxHeight;
  Top := HeaderHeight;
  SetOwnHeight(Top + FBoxHeight);
  LayoutBox(0, Top, FWidth, FBoxHeight, AccentFromColor, 0);
  InputWidth := FWidth - 2 * GrowPadding - Ord(ShowSendButton) * 36;
  Element := MainInput;
  if Element <> nil then
  begin
    Place(Element, GrowPadding, Top + GrowPadding);
    (Element as IFrameworkElement).Width := Max(20, InputWidth);
    (Element as IFrameworkElement).MaxHeight := Max(1, MaxLines) * LineHeight;
  end;
  Place(UIPart('Hint'), GrowPadding, Top + GrowPadding);
  SetOpacity(UIPart('Hint'), Ord(Text = ''));
  Element := UIPart('Send');
  if SendRect(Left, SendTop, Size) then
  begin
    Resize(Element, Size, Size);
    Place(Element, Left, SendTop);
    // Lit once there is something to send, and a hop when it goes
    Lit := Ord(Trim(Text) <> '');
    SetOpacity(UIPart('SendLit'), Lit);
    Tint('SendGlyph', MixColor(MutedColor, Rgb($FF, $FF, $FF), Lit));
    Pop := 1 - 0.08 * FPress * Ord(FSendDown) + 0.12 * Sin(Pi * Clamp01(FSendAge / 0.3));
    ScaleAt(Element, Pop, Pop, Size / 2, Size / 2);
    Shift(UIPart('SendGlyph'), 0, -6 * Sin(Pi * Clamp01(FSendAge / 0.3)));
    SetOpacity(Element, 1);
  end
  else
    SetOpacity(Element, 0);
end;

{ TWinUITagInputField }

const
  TagTagsIndex = OwnIndex;
  TagMaxIndex = OwnIndex + 1;
  ChipGap = 6;
  ChipPad = 8;

class procedure TWinUITagInputField.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Tags', TWinUIPropertyKind.Text, '');
  AType.AddProperty('MaxTags', TWinUIPropertyKind.Int32, '0');
  AType.AddEvent('TagsChanged');
end;

class function TWinUITagInputField.DefaultHeader: string;
begin
  Result := 'Topics';
end;

class function TWinUITagInputField.DefaultPlaceholder: string;
begin
  Result := 'Add a topic...';
end;

class function TWinUITagInputField.DefaultHeight: Double;
begin
  Result := 64;
end;

function TWinUITagInputField.TagCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(FChips) do
    if not FChips[I].Leaving then
      Inc(Result);
end;

function TWinUITagInputField.BoxTop: Double;
begin
  Result := HeaderHeight;
end;

procedure TWinUITagInputField.PropertyChanged(AIndex: Integer);
var
  Tag: string;
begin
  inherited;
  case AIndex of
    TagTagsIndex:
      if not FSettingTags and (LivePanel <> nil) then
      begin
        ClearChips;
        for Tag in SplitList(Tags) do
          AddChip(Tag, False);
        StartRendering;
      end;
  end;
end;

procedure TWinUITagInputField.BuildLive;
begin
  NewTextBox('Input', False);
end;

procedure TWinUITagInputField.StyleLive;
var
  Tag: string;
begin
  inherited;
  // The chips in the current colours
  ClearChips;
  for Tag in SplitList(Tags) do
    AddChip(Tag, False);
end;

function TWinUITagInputField.StyleXaml: string;
begin
  Result := FieldXaml +
    '<TextBlock x:Name="Hint" Text="' + XmlText(PlaceholderText) + '" FontSize="' + Num(FontSize) + '" Foreground="' +
    ColorHex(MutedColor) + '" />';
end;

procedure TWinUITagInputField.AddChip(const AText: string; AAnimate: Boolean);
var
  Chip: TChip;
  Big: RADWinUI.Abi.Size;
  ChipFill, ChipText: TWinUIColor;
begin
  if LivePanel = nil then
    Exit;
  ChipFill := ForSurface(MixColor(SurfaceColor, AccentFromColor, 0.28), MixColor(Rgb($FF, $FF, $FF), AccentFromColor, 0.14));
  ChipText := ForSurface(MixColor(Rgb($FF, $FF, $FF), AccentToColor, 0.15), MixColor(AccentFromColor, Rgb(0, 0, 0), 0.25));
  Chip := Default(TChip);
  Chip.Text := AText;
  // The chips show no input of their own: a click on one reaches the field (x removes it)
  Chip.Element := AddLive('<Grid IsHitTestVisible="False"><Rectangle RadiusX="11" RadiusY="11" Fill="' +
    ColorHex(ChipFill) + '" /><StackPanel Orientation="Horizontal" Margin="' + Num(ChipPad) + ',3,7,3">' +
    '<TextBlock Text="' + XmlText(AText) + '" FontSize="' + Num(FontSize - 2) + '" FontWeight="SemiBold" Foreground="' +
    ColorHex(ChipText) + '" VerticalAlignment="Center" />' +
    '<FontIcon Glyph="' + GlyphXml(CloseGlyph) + '" FontSize="8" Margin="6,1,0,0" Foreground="' +
    ColorHex(WithAlpha(ChipText, 0.75)) + '" VerticalAlignment="Center" /></StackPanel></Grid>');
  Big.Width := 10000;
  Big.Height := 10000;
  Chip.Element.Measure(Big);
  Chip.Width := Chip.Element.DesiredSize.Width;
  Chip.Height := Chip.Element.DesiredSize.Height;
  if AAnimate then
    Chip.Age := 0
  else
    Chip.Age := 1;
  Chip.ShownX := -1;
  FChips := FChips + [Chip];
  ArrangeChips;
end;

procedure TWinUITagInputField.ClearChips;
var
  I: Integer;
  Index: Cardinal;
begin
  for I := 0 to High(FChips) do
    if (FChips[I].Element <> nil) and (LivePanel <> nil) and LivePanel.Children.IndexOf(FChips[I].Element, Index) then
      LivePanel.Children.RemoveAt(Index);
  FChips := nil;
end;

procedure TWinUITagInputField.RemoveChip(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex > High(FChips)) or FChips[AIndex].Leaving then
    Exit;
  FChips[AIndex].Leaving := True;
  FChips[AIndex].LeaveAge := 0;
  FArmed := False;
  TagsFromChips;
  StartRendering;
end;

procedure TWinUITagInputField.TagsFromChips;
var
  I: Integer;
  List: string;
begin
  List := '';
  for I := 0 to High(FChips) do
    if not FChips[I].Leaving then
    begin
      if List <> '' then
        List := List + ', ';
      List := List + FChips[I].Text;
    end;
  FSettingTags := True;
  try
    Tags := List;
  finally
    FSettingTags := False;
  end;
  Fire(OwnEvent);
end;

procedure TWinUITagInputField.CommitWord;
var
  Word: string;
  I: Integer;
begin
  Word := Trim(InputText(MainInput)).Replace(',', '');
  if Word = '' then
    Exit;
  if (MaxTags > 0) and (TagCount >= MaxTags) then
    Exit;
  // The same word twice: the chip that has it nods instead
  for I := 0 to High(FChips) do
    if not FChips[I].Leaving and SameText(FChips[I].Text, Word) then
    begin
      FChips[I].Age := 0.45;
      SetInputText(MainInput, '');
      StartRendering;
      Exit;
    end;
  AddChip(Word, True);
  SetInputText(MainInput, '');
  TagsFromChips;
  StartRendering;
end;

procedure TWinUITagInputField.ArrangeChips;
var
  I: Integer;
  X, Y, RowH, Right, MinInput: Double;
begin
  X := 10;
  Y := 9;
  RowH := Max(FontSize * 1.6, 24);
  Right := FWidth - 10;
  for I := 0 to High(FChips) do
  begin
    if FChips[I].Leaving then
      Continue;
    if (X > 10) and (X + FChips[I].Width > Right) then
    begin
      X := 10;
      Y := Y + RowH + 5;
    end;
    FChips[I].X := X;
    FChips[I].Y := Y + (RowH - FChips[I].Height) / 2;
    if FChips[I].ShownX < 0 then
    begin
      FChips[I].ShownX := FChips[I].X;
      FChips[I].ShownY := FChips[I].Y;
    end;
    X := X + FChips[I].Width + ChipGap;
  end;
  // The input follows the last chip, or starts a new row when there is no room
  MinInput := 70;
  if X + MinInput > Right then
  begin
    X := 10;
    Y := Y + RowH + 5;
  end;
  FInputX := X;
  FInputY := Y + (RowH - FontSize * 1.4) / 2;
  FInputWidth := Right - X;
end;

function TWinUITagInputField.ChipAt(AX, AY: Double; out AOnClose: Boolean): Integer;
var
  I: Integer;
  Top: Double;
begin
  Top := BoxTop;
  AOnClose := False;
  for I := 0 to High(FChips) do
    if not FChips[I].Leaving and (AX >= FChips[I].X) and (AX <= FChips[I].X + FChips[I].Width) and
      (AY >= Top + FChips[I].Y) and (AY <= Top + FChips[I].Y + FChips[I].Height) then
    begin
      AOnClose := AX >= FChips[I].X + FChips[I].Width - 20;
      Exit(I);
    end;
  Result := -1;
end;

function TWinUITagInputField.PointerDown(AX, AY: Double): Boolean;
var
  Index: Integer;
  OnClose: Boolean;
begin
  Index := ChipAt(AX, AY, OnClose);
  if (Index >= 0) and OnClose then
  begin
    RemoveChip(Index);
    FocusField;
    Exit(False);
  end;
  Result := inherited;
end;

procedure TWinUITagInputField.InputChanged(const AElement: IUIElement);
var
  Typed: string;
begin
  Typed := InputText(AElement);
  FArmed := False;
  // A space or a comma after a word makes it a chip
  if (Typed <> '') and CharInSet(Typed[Length(Typed)], [' ', ',']) then
  begin
    if Trim(Typed.Replace(',', '')) = '' then
      SetInputText(AElement, '')
    else
      CommitWord;
    Exit;
  end;
  inherited;
end;

procedure TWinUITagInputField.InputKey(const AElement: IUIElement; AKey: TWinUIVirtualKey; var AHandled: Boolean);
var
  Last, I: Integer;
begin
  if AKey = TWinUIVirtualKey.Enter then
  begin
    CommitWord;
    AHandled := True;
  end
  else if (AKey = TWinUIVirtualKey.Back) and (InputText(AElement) = '') then
  begin
    // Backspace in an empty input marks the last chip, a second one removes it
    Last := -1;
    for I := High(FChips) downto 0 do
      if not FChips[I].Leaving then
      begin
        Last := I;
        Break;
      end;
    if Last < 0 then
      Exit;
    if FArmed then
      RemoveChip(Last)
    else
      FArmed := True;
    AHandled := True;
  end
  else
    FArmed := False;
end;

procedure TWinUITagInputField.Advance(ASeconds: Double);
var
  I: Integer;
  Kept: TArray<TChip>;
  Index: Cardinal;
begin
  inherited;
  ArrangeChips;
  Kept := nil;
  for I := 0 to High(FChips) do
  begin
    FChips[I].Age := FChips[I].Age + ASeconds;
    FChips[I].ShownX := Ease(FChips[I].ShownX, FChips[I].X, ASeconds, 16);
    FChips[I].ShownY := Ease(FChips[I].ShownY, FChips[I].Y, ASeconds, 16);
    if FChips[I].Leaving then
    begin
      FChips[I].LeaveAge := FChips[I].LeaveAge + ASeconds;
      if FChips[I].LeaveAge > 0.22 then
      begin
        if LivePanel.Children.IndexOf(FChips[I].Element, Index) then
          LivePanel.Children.RemoveAt(Index);
        Continue;
      end;
    end;
    Kept := Kept + [FChips[I]];
  end;
  FChips := Kept;
  if FBoxHeight <= 0 then
    FBoxHeight := Max(40, FInputY + FontSize * 1.4 + 10);
  SpringStep(FBoxHeight, FBoxSpeed, Max(40, FInputY + FontSize * 1.4 + 10), ASeconds, 200, 20);
end;

function TWinUITagInputField.StillMoving: Boolean;
var
  I: Integer;
begin
  Result := inherited or (Abs(FBoxSpeed) > 0.05) or (Abs(FBoxHeight - Max(40, FInputY + FontSize * 1.4 + 10)) > 0.1);
  for I := 0 to High(FChips) do
    if (FChips[I].Age < 0.8) or FChips[I].Leaving or (Abs(FChips[I].ShownX - FChips[I].X) > 0.1) or
      (Abs(FChips[I].ShownY - FChips[I].Y) > 0.1) then
      Exit(True);
end;

procedure TWinUITagInputField.LayoutControl;
var
  I: Integer;
  Top, Pop, Fade: Double;
  Element: IUIElement;
begin
  ArrangeChips;
  if FBoxHeight <= 0 then
    FBoxHeight := Max(40, FInputY + FontSize * 1.4 + 10);
  Top := BoxTop;
  SetOwnHeight(Top + FBoxHeight);
  LayoutBox(0, Top, FWidth, FBoxHeight, AccentFromColor, 0);
  for I := 0 to High(FChips) do
  begin
    Element := FChips[I].Element;
    Place(Element, FChips[I].ShownX, Top + FChips[I].ShownY);
    // A new chip pops in, a removed one shrinks away, the last one blinks when Backspace marks it
    if FChips[I].Leaving then
    begin
      Pop := 1 - 0.4 * EaseOutCubic(FChips[I].LeaveAge / 0.22);
      Fade := 1 - Clamp01(FChips[I].LeaveAge / 0.22);
    end
    else
    begin
      Pop := 0.55 + 0.45 * EaseOutBack(FChips[I].Age / 0.32, 2);
      if (FChips[I].Age > 0.45) and (FChips[I].Age < 0.75) then
        Pop := 1 + 0.08 * Sin(Pi * (FChips[I].Age - 0.45) / 0.3);
      Fade := Clamp01(FChips[I].Age / 0.12);
    end;
    ScaleAt(Element, Pop, Pop, FChips[I].Width / 2, FChips[I].Height / 2);
    Element.Opacity := Fade;
    if FArmed and (I = High(FChips)) then
      Element.Opacity := Fade * (0.55 + 0.45 * Ord(Frac(FClock * 2) < 0.5));
  end;
  Element := MainInput;
  if Element <> nil then
  begin
    Place(Element, FInputX, Top + FInputY);
    Resize(Element, Max(20, FInputWidth), FontSize * 1.4);
  end;
  Place(UIPart('Hint'), FInputX, Top + FInputY);
  SetOpacity(UIPart('Hint'), Ord((Text = '') and (TagCount = 0)));
  if FArmed then
    StartRendering;
end;

{ TWinUIGhostCompleteField }

const
  GhostSuggestionsIndex = OwnIndex;
  GhostAfterIndex = OwnIndex + 1;
  GhostHintIndex = OwnIndex + 2;
  GhostAcceptedIndex = OwnIndex + 3;
  GhostBoxHeight = 42;

class procedure TWinUIGhostCompleteField.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Suggestions', TWinUIPropertyKind.Text, 'gmail.com, outlook.com, mail.com, icloud.com, yahoo.com');
  AType.AddProperty('CompleteAfter', TWinUIPropertyKind.Text, '@');
  AType.AddProperty('HintText', TWinUIPropertyKind.Text, 'Press Tab to accept');
  AType.AddProperty('AcceptedText', TWinUIPropertyKind.Text, 'Filled in for you');
  AType.AddEvent('Accepted');
end;

class function TWinUIGhostCompleteField.DefaultHeader: string;
begin
  Result := 'Email';
end;

class function TWinUIGhostCompleteField.DefaultPlaceholder: string;
begin
  Result := 'you@example.com';
end;

class function TWinUIGhostCompleteField.DefaultHeight: Double;
begin
  Result := 86;
end;

procedure TWinUIGhostCompleteField.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    GhostSuggestionsIndex, GhostAfterIndex:
      UpdateGhost;
    GhostHintIndex, GhostAcceptedIndex:
      Rebuild;
  end;
end;

procedure TWinUIGhostCompleteField.BuildLive;
begin
  NewTextBox('Input', False, 'InputScope="EmailSmtpAddress"');
end;

procedure TWinUIGhostCompleteField.StyleLive;
begin
  inherited;
  UpdateGhost;
end;

function TWinUIGhostCompleteField.StyleXaml: string;
begin
  Result := FieldXaml +
    '<TextBlock x:Name="Hint" Text="' + XmlText(PlaceholderText) + '" FontSize="' + Num(FontSize) + '" Foreground="' +
    ColorHex(MutedColor) + '" />' +
    // The completion: the typed part invisible, so the gray rest starts where the text ends
    '<StackPanel x:Name="Ghost" Orientation="Horizontal">' +
    '<TextBlock x:Name="GhostTyped" FontSize="' + Num(FontSize) + '" Foreground="Transparent" />' +
    '<TextBlock x:Name="GhostRest" FontSize="' + Num(FontSize) + '" Foreground="' + ColorHex(MutedColor) + '" /></StackPanel>' +
    '<Grid x:Name="Key"><Rectangle x:Name="KeyBack" RadiusX="5" RadiusY="5" StrokeThickness="1" Fill="' +
    ColorHex(SoftColor) + '" Stroke="' + ColorHex(LineColor) + '" />' +
    '<TextBlock Text="Tab" FontSize="' + Num(FontSize - 4) + '" FontWeight="SemiBold" Foreground="' + ColorHex(MutedColor) +
    '" Margin="7,2" HorizontalAlignment="Center" VerticalAlignment="Center" /></Grid>' +
    '<Grid x:Name="Done" Width="18" Height="18"><Ellipse Fill="' + ColorHex(SuccessColor) + '" />' +
    '<Polyline x:Name="DoneCheck" Stroke="White" StrokeThickness="1.8" StrokeStartLineCap="Round" ' +
    'StrokeEndLineCap="Round" StrokeLineJoin="Round" /></Grid>' +
    '<TextBlock x:Name="Caption" FontSize="' + Num(FontSize - 4) + '" />';
end;

procedure TWinUIGhostCompleteField.StyleLoaded;
begin
  inherited;
  FHintSize := MeasurePart('Key');
end;

function TWinUIGhostCompleteField.FindSuggestion(const AText: string): string;
var
  Tail, Candidate: string;
  At: Integer;
begin
  Result := '';
  if AText = '' then
    Exit;
  if CompleteAfter <> '' then
  begin
    At := AText.LastIndexOf(CompleteAfter);
    if At < 0 then
      Exit;
    Tail := AText.Substring(At + Length(CompleteAfter));
  end
  else
    Tail := AText;
  // The first completion that starts with what was typed and is longer
  for Candidate in SplitList(Suggestions) do
    if (Length(Candidate) > Length(Tail)) and Candidate.StartsWith(Tail, True) then
      Exit(Candidate.Substring(Length(Tail)));
end;

procedure TWinUIGhostCompleteField.UpdateGhost;
var
  Typed: string;
begin
  Typed := Text;
  if FFilling then
    Exit;
  FSuggestion := FindSuggestion(Typed);
  if not Built then
    Exit;
  TextPart('GhostTyped', Typed);
  TextPart('GhostRest', FSuggestion);
  StartRendering;
end;

procedure TWinUIGhostCompleteField.Accept;
begin
  if (FSuggestion = '') or FFilling then
    Exit;
  // The gray completion turns to text colour first, then becomes the text
  FFilling := True;
  FFillText := Text + FSuggestion;
  FAcceptAge := 0;
  StartRendering;
end;

procedure TWinUIGhostCompleteField.InputChanged(const AElement: IUIElement);
begin
  inherited;
  if not FFilling then
    FAccepted := False;
  UpdateGhost;
end;

procedure TWinUIGhostCompleteField.InputKey(const AElement: IUIElement; AKey: TWinUIVirtualKey; var AHandled: Boolean);
var
  Box: ITextBox;
begin
  if FSuggestion = '' then
    Exit;
  if AKey = TWinUIVirtualKey.Tab then
  begin
    Accept;
    AHandled := True;
  end
  else if (AKey = TWinUIVirtualKey.Right) and Supports(AElement, ITextBox, Box) and
    (Box.SelectionStart = Length(Text)) then
  begin
    Accept;
    AHandled := True;
  end
  else if AKey = TWinUIVirtualKey.Escape then
  begin
    FSuggestion := '';
    TextPart('GhostRest', '');
    AHandled := True;
  end;
end;

function TWinUIGhostCompleteField.HintLeft: Double;
begin
  Result := FWidth - FHintSize.Width - 10;
end;

function TWinUIGhostCompleteField.PointerDown(AX, AY: Double): Boolean;
begin
  // The Tab key on the right takes the completion too
  if (FSuggestion <> '') and (AX >= HintLeft - 6) then
  begin
    Accept;
    FocusField;
    Exit(False);
  end;
  Result := inherited;
end;

procedure TWinUIGhostCompleteField.Advance(ASeconds: Double);
begin
  inherited;
  FAcceptAge := FAcceptAge + ASeconds;
  if FFilling and (FAcceptAge >= 0.2) then
  begin
    FFilling := False;
    FAccepted := True;
    FSuggestion := '';
    Text := FFillText;
    CaretToEnd(MainInput);
    FAccepted := True;
    FAcceptAge := 0;
    UpdateGhost;
    Fire(OwnEvent);
  end;
end;

function TWinUIGhostCompleteField.StillMoving: Boolean;
begin
  Result := inherited or FFilling or (FAcceptAge < 0.5);
end;

procedure TWinUIGhostCompleteField.LayoutControl;
var
  Top, LineH, Y, Right, Caption: Double;
  Element: IUIElement;
  Fill: Double;
  CaptionText: string;
  Edge: TWinUIColor;
begin
  Top := HeaderHeight;
  if FAccepted then
    Edge := SuccessColor
  else
    Edge := AccentFromColor;
  LayoutBox(0, Top, FWidth, GhostBoxHeight, Edge, Ord(FAccepted));
  LineH := FontSize * 1.4;
  Y := Top + (GhostBoxHeight - LineH) / 2;
  Right := FWidth - 12;
  if (FSuggestion <> '') or FFilling then
    Right := HintLeft - 6
  else if FAccepted then
    Right := FWidth - 36;
  Element := MainInput;
  if Element <> nil then
  begin
    Place(Element, 14, Y);
    Resize(Element, Max(20, Right - 14), LineH);
  end;
  Place(UIPart('Hint'), 14, Y);
  SetOpacity(UIPart('Hint'), Ord(Text = ''));
  Element := UIPart('Ghost');
  Place(Element, 14, Y);
  SetOpacity(Element, Ord((FSuggestion <> '') or FFilling));
  // While it fills in, the gray turns to the text colour
  if FFilling then
    Fill := Clamp01(FAcceptAge / 0.18)
  else
    Fill := 0;
  Tint('GhostRest', MixColor(MutedColor, TextColor, Fill));
  Element := UIPart('Key');
  Place(Element, HintLeft, Top + (GhostBoxHeight - FHintSize.Height) / 2);
  SetOpacity(Element, Ord(FSuggestion <> '') * (1 - Fill));
  Element := UIPart('Done');
  Place(Element, FWidth - 30, Top + (GhostBoxHeight - 18) / 2);
  SetOpacity(Element, Ord(FAccepted));
  ScaleAt(Element, EaseOutBack(FAcceptAge / 0.3), EaseOutBack(FAcceptAge / 0.3), 9, 9);
  SetLinePoints(Part('DoneCheck'), CheckPoints(1, 1, 16, FAcceptAge / 0.3));
  // The caption under the field: how to take it, or that it was taken
  if FAccepted then
  begin
    CaptionText := AcceptedText;
    Tint('Caption', SuccessColor);
  end
  else
  begin
    CaptionText := HintText;
    Tint('Caption', MutedColor);
  end;
  TextPart('Caption', CaptionText);
  Element := UIPart('Caption');
  Caption := Top + GhostBoxHeight + 5;
  Place(Element, 4, Caption);
  SetOpacity(Element, Ord(FAccepted or (FSuggestion <> '')));
end;

initialization
  TWinUICustomControls.Register(TWinUIOtpCodeField, 'OtpCodeField', TextFieldsCategory);
  TWinUICustomControls.Register(TWinUICardNumberField, 'CardNumberField', TextFieldsCategory);
  TWinUICustomControls.Register(TWinUIStrengthMeterField, 'StrengthMeterField', TextFieldsCategory);
  TWinUICustomControls.Register(TWinUIAutoGrowField, 'AutoGrowField', TextFieldsCategory);
  TWinUICustomControls.Register(TWinUITagInputField, 'TagInputField', TextFieldsCategory);
  TWinUICustomControls.Register(TWinUIGhostCompleteField, 'GhostCompleteField', TextFieldsCategory);

end.
