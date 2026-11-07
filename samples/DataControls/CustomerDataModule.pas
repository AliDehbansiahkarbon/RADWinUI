unit CustomerDataModule;

{
  The sample's data: customers, their countries and their orders in three
  FireDAC memory tables, each with a TDataSource for the controls to bind
  to. The field definitions are in the .dfm, so the Object Inspector lists
  them for DataField. The records are filled in when the module is created,
  and every customer gets a logo from the Logos folder for the DBImage.
}

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Data.DB,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Error,
  FireDAC.DatS,
  FireDAC.Phys.Intf,
  FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.Client;

type
  TCustomerData = class(TDataModule)
    Countries: TFDMemTable;
    CountriesSource: TDataSource;
    Customers: TFDMemTable;
    CustomersSource: TDataSource;
    Orders: TFDMemTable;
    OrdersSource: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure CustomersNewRecord(DataSet: TDataSet);
    procedure OrdersNewRecord(DataSet: TDataSet);
  private
    FNextCustomer: Integer;
    FNextOrder: Integer;
    procedure FillCountries;
    procedure FillCustomers;
    procedure FillOrders;
    procedure LoadLogos;
    procedure SetLabels;
  end;

var
  CustomerData: TCustomerData;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

procedure TCustomerData.DataModuleCreate(Sender: TObject);
begin
  FillCountries;
  FillCustomers;
  FillOrders;
  SetLabels;
  LoadLogos;
  Customers.First;
end;

procedure TCustomerData.FillCountries;
const
  Names: array[1..8] of string = ('Australia', 'Brazil', 'Canada', 'Germany', 'Japan', 'Norway',
    'Spain', 'United Kingdom');
var
  I: Integer;
begin
  Countries.CreateDataSet;
  for I := Low(Names) to High(Names) do
    Countries.AppendRecord([I, Names[I]]);
  Countries.First;
end;

procedure TCustomerData.FillCustomers;
begin
  Customers.CreateDataSet;
  // ID, Name, City, CountryID, Tier, Balance, Joined, Active, Newsletter, Notes
  Customers.AppendRecord([1, 'Aurora Bakery', 'Toronto', 3, 'Gold', 1840.50, EncodeDate(2019, 4, 12), True, 'Y',
    'Orders every Monday. Prefers delivery before 8 am.']);
  Customers.AppendRecord([2, 'Blue Harbor Books', 'Bergen', 6, 'Silver', 620.00, EncodeDate(2021, 9, 3), True, 'Y',
    'Small shop by the harbour. Pays by bank transfer.']);
  Customers.AppendRecord([3, 'Cedar & Pine Furniture', 'Munich', 4, 'Gold', 5120.75, EncodeDate(2017, 1, 22), True, 'N',
    'Large orders twice a year.']);
  Customers.AppendRecord([4, 'Delta Bikes', 'Melbourne', 1, 'Bronze', 95.20, EncodeDate(2024, 6, 30), True, 'Y',
    '']);
  Customers.AppendRecord([5, 'Ember Tea House', 'Kyoto', 5, 'Silver', 410.00, EncodeDate(2022, 3, 15), False, 'N',
    'Closed for renovation until spring.']);
  Customers.AppendRecord([6, 'Fjord Outdoor', 'Oslo', 6, 'Gold', 2975.00, EncodeDate(2018, 11, 8), True, 'Y',
    'Seasonal: most orders in autumn.']);
  Customers.AppendRecord([7, 'Golden Grain Market', 'Valencia', 7, 'Bronze', 260.40, EncodeDate(2023, 5, 19), True, 'N',
    '']);
  Customers.AppendRecord([8, 'Harbor Light Studio', 'Bristol', 8, 'Silver', 780.00, EncodeDate(2020, 8, 27), True, 'Y',
    'Photography studio. Asks for invoices in PDF.']);
  Customers.AppendRecord([9, 'Indigo Print Co.', 'Sao Paulo', 2, 'Bronze', 150.00, EncodeDate(2025, 2, 4), True, 'N',
    '']);
  Customers.AppendRecord([10, 'Juniper Florist', 'Vancouver', 3, 'Silver', 545.90, EncodeDate(2021, 12, 1), True, 'Y',
    'Fresh flowers on Fridays.']);
  FNextCustomer := 11;
end;

procedure TCustomerData.FillOrders;
const
  Products: array[0..7] of string = ('Paper cups, 500', 'Shipping boxes, large', 'Receipt rolls, 50',
    'Gift cards, 100', 'Label printer', 'Packing tape, 24', 'Shelf tags, 200', 'Tote bags, 50');
  Prices: array[0..7] of Currency = (38.00, 64.50, 22.90, 45.00, 189.00, 31.20, 18.40, 72.00);
var
  Customer, I, Product, Quantity: Integer;
  Day: TDateTime;
begin
  // Filled without the master, so every customer's orders go in at once
  Orders.MasterSource := nil;
  Orders.CreateDataSet;
  FNextOrder := 1001;
  Day := EncodeDate(2026, 9, 1);
  for Customer := 1 to 10 do
    for I := 0 to 1 + Customer mod 4 do
    begin
      Product := (Customer * 3 + I * 5) mod Length(Products);
      Quantity := 1 + (Customer + I * 2) mod 5;
      Orders.AppendRecord([FNextOrder, Customer, Day + (Customer * 7 + I * 11) mod 60, Products[Product],
        Quantity, Quantity * Prices[Product], I > 0]);
      Inc(FNextOrder);
    end;
  Orders.MasterSource := CustomersSource;
end;

procedure TCustomerData.SetLabels;
begin
  Customers.FieldByName('Joined').DisplayLabel := 'Customer since';
  Customers.FieldByName('CountryID').DisplayLabel := 'Country';
  Orders.FieldByName('OrderNo').DisplayLabel := 'Order';
  Orders.FieldByName('OrderDate').DisplayLabel := 'Date';
  Orders.FieldByName('Quantity').DisplayLabel := 'Qty';
end;

/// The Logos folder next to the project. The program runs from Win64\Debug
/// or Win64\Release, so it is looked for a few folders up as well.
procedure TCustomerData.LoadLogos;
var
  Folder, FileName: string;
  Level: Integer;
  Logo: TBlobField;
begin
  Folder := ExtractFilePath(ParamStr(0));
  for Level := 0 to 3 do
  begin
    if TDirectory.Exists(TPath.Combine(Folder, 'Logos')) then
      Break;
    Folder := ExtractFilePath(ExcludeTrailingPathDelimiter(Folder));
  end;
  Folder := TPath.Combine(Folder, 'Logos');
  if not TDirectory.Exists(Folder) then
    Exit;
  Logo := Customers.FieldByName('Logo') as TBlobField;
  Customers.DisableControls;
  try
    Customers.First;
    while not Customers.Eof do
    begin
      FileName := TPath.Combine(Folder, Customers.FieldByName('ID').AsString + '.png');
      if TFile.Exists(FileName) then
      begin
        Customers.Edit;
        Logo.LoadFromFile(FileName);
        Customers.Post;
      end;
      Customers.Next;
    end;
  finally
    Customers.EnableControls;
  end;
end;

procedure TCustomerData.CustomersNewRecord(DataSet: TDataSet);
begin
  DataSet.FieldByName('ID').AsInteger := FNextCustomer;
  Inc(FNextCustomer);
  DataSet.FieldByName('Tier').AsString := 'Bronze';
  DataSet.FieldByName('Balance').AsCurrency := 0;
  DataSet.FieldByName('Joined').AsDateTime := Date;
  DataSet.FieldByName('Active').AsBoolean := True;
  DataSet.FieldByName('Newsletter').AsString := 'N';
end;

procedure TCustomerData.OrdersNewRecord(DataSet: TDataSet);
begin
  DataSet.FieldByName('OrderNo').AsInteger := FNextOrder;
  Inc(FNextOrder);
  DataSet.FieldByName('CustomerID').AsInteger := Customers.FieldByName('ID').AsInteger;
  DataSet.FieldByName('OrderDate').AsDateTime := Date;
  DataSet.FieldByName('Quantity').AsInteger := 1;
  DataSet.FieldByName('Total').AsCurrency := 0;
  DataSet.FieldByName('Shipped').AsBoolean := False;
end;

end.
