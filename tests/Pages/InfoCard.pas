unit InfoCard;

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.CustomControls,
  InfoCard.Xaml;

type
  TInfoCard = class(TInfoCardBase)
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure PropertyChanged(AIndex: Integer); override;
  public
    /// <summary>What a click on its button does, for the test.</summary>
    procedure Click;
    function ShownTitle: string;
  published
    procedure GoClick(Sender: TObject);
    property Title: string index 0 read GetText write SetText;
    property OnClicked: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

implementation

class procedure TInfoCard.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Title', TWinUIPropertyKind.Text);
  AType.AddEvent('Clicked');
end;

procedure TInfoCard.PropertyChanged(AIndex: Integer);
begin
  TitleText.Text := Title;
end;

procedure TInfoCard.Click;
begin
  GoClick(GoButton);
end;

function TInfoCard.ShownTitle: string;
begin
  Result := TitleText.Text;
end;

procedure TInfoCard.GoClick(Sender: TObject);
begin
  Fire(0);
end;

end.