unit OrdersPage;

interface

uses
  System.SysUtils,
  Data.DB,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Pages,
  RADWinUI.Dialogs,
  OrdersPage.Xaml;

type
  TOrdersPage = class(TOrdersPageBase)   // generated from OrdersPage.xaml
  private
    FSearch: string;
    procedure ApplyFilter;
    procedure DataChanged(Sender: TObject; Field: TField);
  protected
    procedure NavigatedTo(const AArgs: TWinUINavigationArgs); override;
    procedure NavigatedFrom(const AArgs: TWinUINavigationArgs); override;
  public
    /// <summary>Shows the orders whose cafe or coffee contains AText, all of them for ''.</summary>
    procedure Search(const AText: string);
  published
    procedure StatusChanged(Sender: TObject; const E: TWinValue);
  end;

implementation

uses
  System.Math,
  RADWinUI.Motion,
  EmberData,
  EmberSettings;

const
  Statuses: array[0..3] of string = ('', 'Open', 'Roasting', 'Shipped');

procedure TOrdersPage.NavigatedTo(const AArgs: TWinUINavigationArgs);
begin
  RoasteryData.OrdersSource.OnDataChange := DataChanged;
  // A search from the title bar, or "new" from the dashboard
  if AArgs.Parameter.Kind = TWinUIPageParameterKind.Text then
  begin
    if AArgs.Parameter.AsString = 'new' then
    begin
      FSearch := '';
      StatusTabs.SelectedIndex := 0;
      ApplyFilter;
      RoasteryData.Orders.Insert;
    end
    else
    begin
      FSearch := AArgs.Parameter.AsString;
      ApplyFilter;
    end;
  end
  else
    ApplyFilter;
  TWinUIMotion.Enter(GridCard, 40, 480, 22);
  TWinUIMotion.Enter(FormCard, 120, 480, 22);
end;

procedure TOrdersPage.NavigatedFrom(const AArgs: TWinUINavigationArgs);
begin
  RoasteryData.OrdersSource.OnDataChange := nil;
  // An order being edited is saved when the page is left
  if RoasteryData.Orders.State in dsEditModes then
    RoasteryData.Orders.Post;
  // The other pages see every order
  RoasteryData.Orders.Filtered := False;
end;

procedure TOrdersPage.Search(const AText: string);
begin
  if AText = FSearch then
    Exit;
  FSearch := AText;
  ApplyFilter;
end;

procedure TOrdersPage.ApplyFilter;
var
  Filter, Pattern, Status: string;
begin
  Status := Statuses[Max(0, StatusTabs.SelectedIndex)];
  Filter := '';
  if Status <> '' then
    Filter := 'Status = ' + QuotedStr(Status);
  if FSearch <> '' then
  begin
    // Upper on both sides: the search ignores case
    Pattern := QuotedStr('%' + UpperCase(FSearch) + '%');
    if Filter <> '' then
      Filter := Filter + ' and ';
    Filter := Filter + Format('(Upper(Customer) like %s or Upper(Coffee) like %s)', [Pattern, Pattern]);
  end;
  RoasteryData.Orders.Filtered := False;
  RoasteryData.Orders.Filter := Filter;
  RoasteryData.Orders.Filtered := Filter <> '';
  DataChanged(nil, nil);
end;

procedure TOrdersPage.DataChanged(Sender: TObject; Field: TField);
var
  Count: Integer;
begin
  Count := RoasteryData.Orders.RecordCount;
  if FSearch <> '' then
    CountText.Text := Format(S('OrdersFoundFormat', '%d orders for "%s"'), [Count, FSearch])
  else
    CountText.Text := Format(S('OrdersCountFormat', '%d orders'), [Count]);
end;

procedure TOrdersPage.StatusChanged(Sender: TObject; const E: TWinValue);
begin
  ApplyFilter;
end;

end.
