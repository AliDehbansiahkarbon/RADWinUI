unit OrderCard;

(* The current order as the WinUI panel binds to it: {Binding Customer} reads
  the published property. The form fills it each time the orders cursor moves. *)

interface

uses
  Data.DB,
  RADWinUI.Binding;

type
  TOrderCard = class(TWinUIBindableObject)
  private
    FOrderNo, FDateText, FCustomer, FCity, FContact: string;
    FCoffee, FOrigin, FNotes, FKgText, FTotalText, FStatus: string;
    FCanRoast, FCanShip: Boolean;
  public
    /// <summary>Reads the current order, and its cafe and coffee by their IDs.</summary>
    procedure Load(AOrders, ACustomers, ACoffees: TDataSet);
  published
    property OrderNo: string read FOrderNo;
    property DateText: string read FDateText;
    property Customer: string read FCustomer;
    property City: string read FCity;
    property Contact: string read FContact;
    property Coffee: string read FCoffee;
    property Origin: string read FOrigin;
    property Notes: string read FNotes;
    property KgText: string read FKgText;
    property TotalText: string read FTotalText;
    property Status: string read FStatus;
    property CanRoast: Boolean read FCanRoast;
    property CanShip: Boolean read FCanShip;
  end;

implementation

uses
  System.SysUtils,
  System.Variants;

procedure TOrderCard.Load(AOrders, ACustomers, ACoffees: TDataSet);

  function Find(ATable: TDataSet; const AID, AField: string): string;
  begin
    Result := VarToStr(ATable.Lookup('ID', AOrders.FieldByName(AID).AsInteger, AField));
  end;

begin
  if AOrders.IsEmpty then
  begin
    FOrderNo := '';
    FCustomer := '';
    FCanRoast := False;
    FCanShip := False;
  end
  else
  begin
    FOrderNo := '#' + AOrders.FieldByName('OrderNo').AsString;
    FDateText := FormatDateTime('dddd, d mmmm', AOrders.FieldByName('OrderDate').AsDateTime);
    FCustomer := AOrders.FieldByName('Customer').AsString;
    FCity := Find(ACustomers, 'CustomerID', 'City');
    FContact := Find(ACustomers, 'CustomerID', 'Contact');
    FCoffee := AOrders.FieldByName('Coffee').AsString;
    FOrigin := Find(ACoffees, 'CoffeeID', 'Origin');
    FNotes := Find(ACoffees, 'CoffeeID', 'Notes');
    FKgText := Format('%.1f kg', [AOrders.FieldByName('Kg').AsFloat]);
    FTotalText := FormatFloat('$#,##0.00', AOrders.FieldByName('Total').AsCurrency);
    FStatus := AOrders.FieldByName('Status').AsString;
    FCanRoast := FStatus = 'Open';
    FCanShip := FStatus <> 'Shipped';
  end;
  // Every binding reads again
  Changed;
end;

end.
