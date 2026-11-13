unit Customer;

(* One customer as the WinUI details panel binds to it: {Binding Name} reads the
  published property, a two-way binding writes it back while the user types. *)

interface

uses
  RADWinUI.Binding;

type
  TCustomer = class(TWinUIBindableObject)
  private
    FName, FEmail: string;
    FCreditLimit: Double;
    FNewsletter: Boolean;
    procedure SetName(const AValue: string);
    procedure SetEmail(const AValue: string);
    procedure SetCreditLimit(AValue: Double);
    procedure SetNewsletter(AValue: Boolean);
  public
    constructor Create(const AName, AEmail: string; ACreditLimit: Double; ANewsletter: Boolean);
    procedure Assign(ASource: TCustomer);
  published
    property Name: string read FName write SetName;
    property Email: string read FEmail write SetEmail;
    property CreditLimit: Double read FCreditLimit write SetCreditLimit;
    property Newsletter: Boolean read FNewsletter write SetNewsletter;
  end;

implementation

constructor TCustomer.Create(const AName, AEmail: string; ACreditLimit: Double; ANewsletter: Boolean);
begin
  inherited Create;
  FName := AName;
  FEmail := AEmail;
  FCreditLimit := ACreditLimit;
  FNewsletter := ANewsletter;
end;

procedure TCustomer.Assign(ASource: TCustomer);
begin
  FName := ASource.Name;
  FEmail := ASource.Email;
  FCreditLimit := ASource.CreditLimit;
  FNewsletter := ASource.Newsletter;
  Changed;
end;

procedure TCustomer.SetName(const AValue: string);
begin
  if FName = AValue then
    Exit;
  FName := AValue;
  Changed('Name');
end;

procedure TCustomer.SetEmail(const AValue: string);
begin
  if FEmail = AValue then
    Exit;
  FEmail := AValue;
  Changed('Email');
end;

procedure TCustomer.SetCreditLimit(AValue: Double);
begin
  if FCreditLimit = AValue then
    Exit;
  FCreditLimit := AValue;
  Changed('CreditLimit');
end;

procedure TCustomer.SetNewsletter(AValue: Boolean);
begin
  if FNewsletter = AValue then
    Exit;
  FNewsletter := AValue;
  Changed('Newsletter');
end;

end.
