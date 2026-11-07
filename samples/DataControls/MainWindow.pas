unit MainWindow;

interface

uses
  System.SysUtils,
  System.TypInfo,
  Data.DB,
  RADWinUI.Forms,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  CustomerDataModule,
  MainWindow.Xaml;

type
  TMainWindow = class(TMainWindowBase)   // TMainWindowBase is generated from MainWindow.xaml
  private
    FReady: Boolean;
    procedure DataChanged(Sender: TObject; Field: TField);
    procedure StateChanged(Sender: TObject);
    procedure UpdateStatus;
    procedure UpdateGlass;
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    procedure TransparencyToggled(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure GlassChanged(Sender: TObject; E: TWinUIRangeBaseValueChangedEventArgs);
  end;

implementation

/// "Browse" for dsBrowse
function StateName(AState: TDataSetState): string;
begin
  Result := Copy(GetEnumName(TypeInfo(TDataSetState), Ord(AState)), 3, MaxInt);
end;

constructor TMainWindow.Create;
begin
  inherited;
  // The controls need nothing from code. The status line listens to the
  // same data sources, to show what the controls do to the data sets.
  CustomerData.CustomersSource.OnDataChange := DataChanged;
  CustomerData.CustomersSource.OnStateChange := StateChanged;
  CustomerData.OrdersSource.OnDataChange := DataChanged;
  CustomerData.OrdersSource.OnStateChange := StateChanged;
  FReady := True;
  UpdateStatus;
  UpdateGlass;
end;

destructor TMainWindow.Destroy;
begin
  CustomerData.CustomersSource.OnDataChange := nil;
  CustomerData.CustomersSource.OnStateChange := nil;
  CustomerData.OrdersSource.OnDataChange := nil;
  CustomerData.OrdersSource.OnStateChange := nil;
  inherited;
end;

procedure TMainWindow.DataChanged(Sender: TObject; Field: TField);
begin
  UpdateStatus;
end;

procedure TMainWindow.StateChanged(Sender: TObject);
begin
  UpdateStatus;
end;

procedure TMainWindow.UpdateStatus;
var
  Customers, Orders: TDataSet;
begin
  if not FReady then
    Exit;
  Customers := CustomerData.Customers;
  Orders := CustomerData.Orders;
  StatusText.Text := Format('Customers: record %d of %d, %s.   Orders of %s: %d, %s.',
    [Customers.RecNo, Customers.RecordCount, StateName(Customers.State),
     Customers.FieldByName('Name').AsString, Orders.RecordCount, StateName(Orders.State)]);
end;

// With Transparency on the window has a Transparent backdrop and the page is
// only as opaque as the slider says, so the desktop shows through. Off, the
// window gets Mica and its frame back, under an opaque page.
procedure TMainWindow.UpdateGlass;
begin
  if TransparencySwitch.IsOn then
  begin
    if Backdrop <> TWinUIBackdrop.Transparent then
      Backdrop := TWinUIBackdrop.Transparent;
    Glass.Opacity := 1 - GlassSlider.Value / 100;
  end
  else
  begin
    if Backdrop <> TWinUIBackdrop.Mica then
      Backdrop := TWinUIBackdrop.Mica;
    Glass.Opacity := 1;
  end;
  GlassSlider.IsEnabled := TransparencySwitch.IsOn;
  GlassText.Text := Format('%d%%', [Round(GlassSlider.Value)]);
end;

procedure TMainWindow.TransparencyToggled(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  if FReady then
    UpdateGlass;
end;

procedure TMainWindow.GlassChanged(Sender: TObject; E: TWinUIRangeBaseValueChangedEventArgs);
begin
  if FReady then
    UpdateGlass;
end;

end.
