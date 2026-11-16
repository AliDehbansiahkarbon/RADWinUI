unit EmberData;

{
  Ember's data: the coffees the roastery sells, the cafes that buy them and
  their orders, in three FireDAC memory tables with a TDataSource each. The
  field definitions are in the .dfm, so the Object Inspector lists them for
  DataField. The records are made when the module is created, with dates
  counted back from today, so the dashboard always looks like this week.
  The VCL "before" app (Ember_VCL) uses this same unit.
}

interface

uses
  System.SysUtils,
  System.Classes,
  Data.DB,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Error,
  FireDAC.DatS,
  FireDAC.Phys.Intf,
  FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  FireDAC.Stan.ExprFuncs;

type
  /// <summary>Kilograms ordered of one coffee, for the dashboard.</summary>
  TCoffeeSales = record
    Name: string;
    Origin: string;
    Kg: Double;
  end;

  TRoasteryData = class(TDataModule)
    Coffees: TFDMemTable;
    CoffeesSource: TDataSource;
    Customers: TFDMemTable;
    CustomersSource: TDataSource;
    Orders: TFDMemTable;
    OrdersSource: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure OrdersNewRecord(DataSet: TDataSet);
    procedure OrdersBeforePost(DataSet: TDataSet);
  private
    FNextOrder: Integer;
    procedure FillCoffees;
    procedure FillCustomers;
    procedure FillOrders;
    procedure SetLabels;
    function Lookup(ATable: TFDMemTable; AID: Integer; const AField: string): Variant;
  public
    /// <summary>
    ///   A cursor of its own on ATable, sorted by AIndex: walking it moves nothing
    ///   the data controls show. A lookup control would move the shared cursor back
    ///   on each Next, and a loop over the table itself would never end. The caller frees it.
    /// </summary>
    function Snapshot(ATable: TFDMemTable; const AIndex: string = ''): TFDMemTable;
    /// <summary>The sum of the orders of one day.</summary>
    function Revenue(ADay: TDate): Currency;
    /// <summary>Orders that are not shipped yet.</summary>
    function OpenOrders: Integer;
    /// <summary>Green coffee in stock, all coffees together.</summary>
    function StockKg: Double;
    /// <summary>The revenue of the last seven days, today last.</summary>
    function WeekRevenue: TArray<Currency>;
    /// <summary>The coffees ordered most in the last 30 days, most first.</summary>
    function TopCoffees(ACount: Integer): TArray<TCoffeeSales>;
    /// <summary>Takes roasted coffee off the stock after a batch.</summary>
    procedure UseStock(const ACoffee: string; AKg: Double);
  end;

var
  RoasteryData: TRoasteryData;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

uses
  System.Math,
  System.Variants;

procedure TRoasteryData.DataModuleCreate(Sender: TObject);
begin
  FillCoffees;
  FillCustomers;
  FillOrders;
  SetLabels;
end;

procedure TRoasteryData.FillCoffees;
begin
  Coffees.CreateDataSet;
  // ID, Name, Origin, Process, Roast, Notes, StockKg, PricePerKg
  Coffees.AppendRecord([1, 'Yirgacheffe', 'Ethiopia', 'Washed', 'Light', 'Jasmine, lemon, black tea', 64.5, 31.00]);
  Coffees.AppendRecord([2, 'Huila', 'Colombia', 'Washed', 'Medium', 'Red apple, caramel, cocoa', 120.0, 24.50]);
  Coffees.AppendRecord([3, 'Cerrado', 'Brazil', 'Natural', 'Dark', 'Hazelnut, chocolate, low acidity', 188.0, 19.00]);
  Coffees.AppendRecord([4, 'Antigua', 'Guatemala', 'Washed', 'Medium', 'Brown sugar, orange, almond', 72.0, 26.00]);
  Coffees.AppendRecord([5, 'Nyeri AA', 'Kenya', 'Washed', 'Light', 'Blackcurrant, grapefruit, juicy', 38.5, 36.00]);
  Coffees.AppendRecord([6, 'Sumatra', 'Indonesia', 'Wet hulled', 'Dark', 'Cedar, dark chocolate, spice', 95.0, 22.00]);
  Coffees.AppendRecord([7, 'Tarrazu', 'Costa Rica', 'Honey', 'Medium', 'Honey, peach, milk chocolate', 54.0, 28.00]);
  Coffees.First;
end;

procedure TRoasteryData.FillCustomers;
begin
  Customers.CreateDataSet;
  // ID, Name, City, Contact, Email, Tier
  Customers.AppendRecord([1, 'Aurora Caf'#$E9, 'Toronto', 'Maya Chen', 'maya@aurora.example', 'Gold']);
  Customers.AppendRecord([2, 'Blue Door Coffee', 'Lisbon', 'Jo'#$E3'o Silva', 'joao@bluedoor.example', 'Silver']);
  Customers.AppendRecord([3, 'Copper Kettle', 'Munich', 'Lena Huber', 'lena@copperkettle.example', 'Gold']);
  Customers.AppendRecord([4, 'Dune Espresso Bar', 'Dubai', 'Omar Haddad', 'omar@dune.example', 'Silver']);
  Customers.AppendRecord([5, 'Fika House', 'Stockholm', 'Elin Berg', 'elin@fika.example', 'Bronze']);
  Customers.AppendRecord([6, 'Harbor Roast', 'Sydney', 'Jack Wilson', 'jack@harbor.example', 'Gold']);
  Customers.AppendRecord([7, 'Kissa Tanaka', 'Osaka', 'Yui Tanaka', 'yui@kissa.example', 'Silver']);
  Customers.AppendRecord([8, 'Mesa Verde', 'Mexico City', 'Diego Ramos', 'diego@mesaverde.example', 'Bronze']);
  Customers.AppendRecord([9, 'Saffron Cup', 'Tehran', 'Sara Ahmadi', 'sara@saffron.example', 'Gold']);
  Customers.AppendRecord([10, 'The Daily Grind', 'Austin', 'Chris Miller', 'chris@dailygrind.example', 'Bronze']);
  Customers.First;
end;

procedure TRoasteryData.FillOrders;
const
  Statuses: array[0..2] of string = ('Open', 'Roasting', 'Shipped');
var
  I, Customer, Coffee, Age: Integer;
  Kg: Double;
  Status: string;
begin
  Orders.CreateDataSet;
  FNextOrder := 2401;
  // About three orders a day over the last three weeks, newer ones still open
  for I := 0 to 62 do
  begin
    Age := 20 - I div 3;
    Customer := 1 + (I * 7 + I div 5) mod 10;
    Coffee := 1 + (I * 3 + I div 4) mod 7;
    Kg := 2.5 * (1 + (I * 5 + Customer) mod 8);
    if Age > 3 then
      Status := Statuses[2]
    else if Age > 1 then
      Status := Statuses[(I mod 2) + 1]
    else
      Status := Statuses[I mod 2];
    Orders.AppendRecord([FNextOrder, Date - Age, Customer, Lookup(Customers, Customer, 'Name'), Coffee,
      Lookup(Coffees, Coffee, 'Name'), Kg, Kg * Lookup(Coffees, Coffee, 'PricePerKg'), Status]);
    Inc(FNextOrder);
  end;
  Orders.First;
end;

procedure TRoasteryData.SetLabels;
begin
  Orders.FieldByName('OrderNo').DisplayLabel := 'Order';
  Orders.FieldByName('OrderDate').DisplayLabel := 'Date';
  Orders.FieldByName('CustomerID').DisplayLabel := 'Customer';
  Orders.FieldByName('CoffeeID').DisplayLabel := 'Coffee';
  (Orders.FieldByName('Kg') as TFloatField).DisplayFormat := '0.0';
  Coffees.FieldByName('StockKg').DisplayLabel := 'Stock (kg)';
  Coffees.FieldByName('PricePerKg').DisplayLabel := 'Price per kg';
  (Coffees.FieldByName('StockKg') as TFloatField).DisplayFormat := '0.0';
end;

function TRoasteryData.Lookup(ATable: TFDMemTable; AID: Integer; const AField: string): Variant;
begin
  Result := ATable.Lookup('ID', AID, AField);
  if VarIsNull(Result) then
    Result := '';
end;

procedure TRoasteryData.OrdersNewRecord(DataSet: TDataSet);
begin
  DataSet.FieldByName('OrderNo').AsInteger := FNextOrder;
  Inc(FNextOrder);
  DataSet.FieldByName('OrderDate').AsDateTime := Date;
  DataSet.FieldByName('CustomerID').AsInteger := Customers.FieldByName('ID').AsInteger;
  DataSet.FieldByName('CoffeeID').AsInteger := Coffees.FieldByName('ID').AsInteger;
  DataSet.FieldByName('Kg').AsFloat := 5;
  DataSet.FieldByName('Status').AsString := 'Open';
end;

// The names and the total always follow the IDs and the weight
procedure TRoasteryData.OrdersBeforePost(DataSet: TDataSet);
var
  CoffeeID: Integer;
  Price: Variant;
begin
  CoffeeID := DataSet.FieldByName('CoffeeID').AsInteger;
  DataSet.FieldByName('Customer').AsString := Lookup(Customers, DataSet.FieldByName('CustomerID').AsInteger, 'Name');
  DataSet.FieldByName('Coffee').AsString := Lookup(Coffees, CoffeeID, 'Name');
  Price := Coffees.Lookup('ID', CoffeeID, 'PricePerKg');
  if not VarIsNull(Price) then
    DataSet.FieldByName('Total').AsCurrency := DataSet.FieldByName('Kg').AsFloat * Price;
end;

function TRoasteryData.Snapshot(ATable: TFDMemTable; const AIndex: string): TFDMemTable;
begin
  Result := TFDMemTable.Create(nil);
  try
    Result.CloneCursor(ATable);
    Result.IndexFieldNames := AIndex;
    Result.First;
  except
    Result.Free;
    raise;
  end;
end;

function TRoasteryData.Revenue(ADay: TDate): Currency;
var
  Clone: TFDMemTable;
begin
  Result := 0;
  Clone := Snapshot(Orders);
  try
    while not Clone.Eof do
    begin
      if Trunc(Clone.FieldByName('OrderDate').AsDateTime) = Trunc(ADay) then
        Result := Result + Clone.FieldByName('Total').AsCurrency;
      Clone.Next;
    end;
  finally
    Clone.Free;
  end;
end;

function TRoasteryData.OpenOrders: Integer;
var
  Clone: TFDMemTable;
begin
  Result := 0;
  Clone := Snapshot(Orders);
  try
    while not Clone.Eof do
    begin
      if Clone.FieldByName('Status').AsString <> 'Shipped' then
        Inc(Result);
      Clone.Next;
    end;
  finally
    Clone.Free;
  end;
end;

function TRoasteryData.StockKg: Double;
var
  Clone: TFDMemTable;
begin
  Result := 0;
  Clone := Snapshot(Coffees);
  try
    while not Clone.Eof do
    begin
      Result := Result + Clone.FieldByName('StockKg').AsFloat;
      Clone.Next;
    end;
  finally
    Clone.Free;
  end;
end;

function TRoasteryData.WeekRevenue: TArray<Currency>;
var
  I: Integer;
begin
  SetLength(Result, 7);
  for I := 0 to 6 do
    Result[I] := Revenue(Date - 6 + I);
end;

function TRoasteryData.TopCoffees(ACount: Integer): TArray<TCoffeeSales>;
var
  Clone: TFDMemTable;
  Sales: TArray<TCoffeeSales>;
  I, J: Integer;
  Name: string;
  Swap: TCoffeeSales;
begin
  Sales := nil;
  Clone := Snapshot(Orders);
  try
    while not Clone.Eof do
    begin
      if Clone.FieldByName('OrderDate').AsDateTime >= Date - 30 then
      begin
        Name := Clone.FieldByName('Coffee').AsString;
        J := -1;
        for I := 0 to High(Sales) do
          if Sales[I].Name = Name then
            J := I;
        if J < 0 then
        begin
          J := Length(Sales);
          SetLength(Sales, J + 1);
          Sales[J].Name := Name;
          Sales[J].Origin := VarToStr(Coffees.Lookup('Name', Name, 'Origin'));
          Sales[J].Kg := 0;
        end;
        Sales[J].Kg := Sales[J].Kg + Clone.FieldByName('Kg').AsFloat;
      end;
      Clone.Next;
    end;
  finally
    Clone.Free;
  end;
  for I := 0 to High(Sales) - 1 do
    for J := I + 1 to High(Sales) do
      if Sales[J].Kg > Sales[I].Kg then
      begin
        Swap := Sales[I];
        Sales[I] := Sales[J];
        Sales[J] := Swap;
      end;
  Result := Copy(Sales, 0, Min(ACount, Length(Sales)));
end;

procedure TRoasteryData.UseStock(const ACoffee: string; AKg: Double);
var
  Clone: TFDMemTable;
begin
  Clone := Snapshot(Coffees);
  try
    if Clone.Locate('Name', ACoffee, []) then
    begin
      Clone.Edit;
      Clone.FieldByName('StockKg').AsFloat := Max(0, Clone.FieldByName('StockKg').AsFloat - AKg);
      Clone.Post;
    end;
  finally
    Clone.Free;
  end;
end;

end.
