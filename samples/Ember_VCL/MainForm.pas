unit MainForm;

{ VCL and WinUI on one form: the orders are a VCL TDBGrid and TDBNavigator on
  the same FireDAC data module as the Ember app, and the current order is a
  WinUI card in a TWinUIHost (Panels\OrderCard.xaml) bound to a TOrderCard.
  The card's buttons call published methods of this form. }

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  Data.DB,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  Vcl.Grids,
  Vcl.DBGrids,
  Vcl.DBCtrls,
  RADWinUI.VclHost,
  OrderCard;

type
  TOrdersForm = class(TForm)
    ToolbarPanel: TPanel;
    Navigator: TDBNavigator;
    OrdersGrid: TDBGrid;
    Splitter: TSplitter;
    OrderHost: TWinUIHost;
    StatusBar: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure StartRoastingClick(Sender: TObject);
    procedure ShipClick(Sender: TObject);
  private
    FCard: TOrderCard;
    procedure OrdersChanged(Sender: TObject; Field: TField);
    procedure SetStatus(const AStatus: string);
  end;

var
  OrdersForm: TOrdersForm;

implementation

{$R *.dfm}

uses
  EmberData;

procedure TOrdersForm.FormCreate(Sender: TObject);
begin
  FCard := TOrderCard.Create;
  OrderHost.DataContext := FCard;
  RoasteryData.OrdersSource.OnDataChange := OrdersChanged;
  OrdersChanged(nil, nil);
end;

procedure TOrdersForm.FormDestroy(Sender: TObject);
begin
  RoasteryData.OrdersSource.OnDataChange := nil;
  // The bindings read FCard until the content goes
  OrderHost.XamlFile := '';
  FCard.Free;
end;

procedure TOrdersForm.OrdersChanged(Sender: TObject; Field: TField);
begin
  FCard.Load(RoasteryData.Orders, RoasteryData.Customers, RoasteryData.Coffees);
  StatusBar.SimpleText := Format('%d orders, %d open', [RoasteryData.Orders.RecordCount, RoasteryData.OpenOrders]);
end;

procedure TOrdersForm.SetStatus(const AStatus: string);
var
  Orders: TDataSet;
begin
  Orders := RoasteryData.Orders;
  if Orders.IsEmpty then
    Exit;
  Orders.Edit;
  Orders.FieldByName('Status').AsString := AStatus;
  Orders.Post;
  // The click left the keyboard focus in the WinUI card: give it back to the grid,
  // after the click has ended, so the arrow keys and the wheel move through the orders again
  TThread.ForceQueue(nil,
    procedure
    begin
      if OrdersGrid.CanFocus then
        OrdersGrid.SetFocus;
    end);
end;

procedure TOrdersForm.StartRoastingClick(Sender: TObject);
begin
  SetStatus('Roasting');
end;

procedure TOrdersForm.ShipClick(Sender: TObject);
begin
  SetStatus('Shipped');
end;

end.
