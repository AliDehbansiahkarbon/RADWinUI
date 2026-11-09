unit PersonCard;

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.CustomControls,
  PersonCard.Xaml;

type
  /// <summary>
  ///   A user control: &lt;local:PersonCard PersonName="..." Role="..." Opened="..."/&gt;
  ///   in any page or window of the project.
  /// </summary>
  TPersonCard = class(TPersonCardBase)
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure PropertyChanged(AIndex: Integer); override;
  published
    procedure CardClick(Sender: TObject);
    property PersonName: string index 0 read GetText write SetText;
    property Role: string index 1 read GetText write SetText;
    /// <summary>The card was clicked.</summary>
    property OnOpened: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

implementation

uses
  RADWinUI.Interop.Core,
  RADWinUI.Abi;

class procedure TPersonCard.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('PersonName', TWinUIPropertyKind.Text);
  AType.AddProperty('Role', TWinUIPropertyKind.Text);
  AType.AddEvent('Opened');
end;

procedure TPersonCard.PropertyChanged(AIndex: Integer);
begin
  NameText.Text := PersonName;
  RoleText.Text := Role;
  Picture.DisplayName := PersonName;
  // Screen readers and UI tests name the card after its person
  AutomationProperties.SetName(IntfOf(CardButton, IDependencyObject) as IDependencyObject,
    WinStr('Open ' + PersonName));
end;

procedure TPersonCard.CardClick(Sender: TObject);
begin
  Fire(0);
end;

end.