unit HomePage;

interface

uses
  System.SysUtils,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Binding,
  RADWinUI.Pages,
  RADWinUI.Dialogs,
  HomePage.Xaml;

type
  // One best seller: published properties are what the item template binds to
  {$M+}
  TCoffeeRow = class
  private
    FName: string;
    FOrigin: string;
    FKgText: string;
    FShare: Double;
  published
    property Name: string read FName write FName;
    property Origin: string read FOrigin write FOrigin;
    property KgText: string read FKgText write FKgText;
    /// <summary>Kilograms as a percentage of the best seller's.</summary>
    property Share: Double read FShare write FShare;
  end;

  TOrderRow = class
  private
    FCustomer: string;
    FDetail: string;
    FTotalText: string;
    FStatus: string;
  published
    property Customer: string read FCustomer write FCustomer;
    property Detail: string read FDetail write FDetail;
    property TotalText: string read FTotalText write FTotalText;
    property Status: string read FStatus write FStatus;
  end;
  {$M-}

  THomePage = class(THomePageBase)   // generated from HomePage.xaml
  private
    FTop: TWinUIBindableList<TCoffeeRow>;
    FRecent: TWinUIBindableList<TOrderRow>;
    FCoffees: TArray<string>;
    FShowing: Boolean;
    procedure Fill;
    procedure FillWeek;
    procedure FillLists;
    procedure FillCoffees;
    procedure ShowRoaster;
    procedure Animate;
    procedure RoastChanged(Sender: TObject);
  protected
    procedure NavigatedTo(const AArgs: TWinUINavigationArgs); override;
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    procedure NewOrderClick(Sender: TObject; const E: TWinValue);
    procedure StartRoastConfirmed(Sender: TObject; const E: TWinValue);
    procedure CoffeeChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
    procedure KgChanged(Sender: TObject; E: TWinUIRangeBaseValueChangedEventArgs);
    procedure AllOrdersClick(Sender: TObject);
  end;

implementation

uses
  System.Math,
  System.Variants,
  System.DateUtils,
  Data.DB,
  RADWinUI.Motion,
  EmberData,
  EmberSettings,
  RoastSession,
  OrdersPage,
  RoastPage;

const
  ChartHeight = 170;

function Money(AValue: Currency): string;
begin
  Result := FormatFloat('$#,##0', AValue);
end;

constructor THomePage.Create;
begin
  inherited;
  FTop := TWinUIBindableList<TCoffeeRow>.Create;
  FRecent := TWinUIBindableList<TOrderRow>.Create;
  TopList.ItemsSource := FTop;
  RecentList.ItemsSource := FRecent;
  FillCoffees;
  Roast.Listen(RoastChanged);
end;

destructor THomePage.Destroy;
begin
  Roast.Unlisten(RoastChanged);
  FTop.Free;
  FRecent.Free;
  inherited;
end;

procedure THomePage.NavigatedTo(const AArgs: TWinUINavigationArgs);
begin
  Fill;
  Animate;
end;

procedure THomePage.Fill;
var
  Today, Yesterday: Currency;
begin
  case HourOf(Now) of
    0..11: GreetingText.Text := S('GreetingMorning', 'Good morning');
    12..17: GreetingText.Text := S('GreetingAfternoon', 'Good afternoon');
  else
    GreetingText.Text := S('GreetingEvening', 'Good evening');
  end;
  DateText.Text := FormatDateTime('dddd, d mmmm yyyy', Date);
  Today := RoasteryData.Revenue(Date);
  Yesterday := RoasteryData.Revenue(Date - 1);
  RevenueValue.Text := Money(Today);
  if Yesterday > 0 then
    RevenueDelta.Text := Format(S('DeltaFormat', '%+.0f%% on yesterday'), [(Today - Yesterday) / Yesterday * 100]);
  OpenOrdersValue.Text := IntToStr(RoasteryData.OpenOrders);
  StockValue.Text := Format('%.0f kg', [RoasteryData.StockKg]);
  StockBar.Value := RoasteryData.StockKg;
  ShowRoaster;
  FillWeek;
  FillLists;
end;

procedure THomePage.ShowRoaster;
begin
  case Roast.Phase of
    TRoastPhase.Idle:
      begin
        BatchValue.Text := S('RoasterIdle', 'Idle');
        BatchHint.Text := S('RoasterIdleHint', 'Ready for the next batch');
      end;
    TRoastPhase.Done:
      begin
        BatchValue.Text := S('RoasterIdle', 'Idle');
        BatchHint.Text := Format(S('LastBatchFormat', 'Last batch: #%d %s'), [Roast.BatchNo, Roast.Coffee]);
      end;
  else
    BatchValue.Text := Format('%.0f'#$00B0'C', [Roast.BeanTemp]);
    BatchHint.Text := Format(S('RoastingHintFormat', 'Batch #%d, %s'), [Roast.BatchNo, FormatClock(Roast.Seconds)]);
  end;
end;

procedure THomePage.RoastChanged(Sender: TObject);
begin
  ShowRoaster;
end;

procedure THomePage.FillWeek;
var
  Week: TArray<Currency>;
  Bars: array[0..6] of TWinUIBorder;
  Values, Days: array[0..6] of TWinUITextBlock;
  Top, Total: Currency;
  I: Integer;
begin
  Bars[0] := Bar0; Bars[1] := Bar1; Bars[2] := Bar2; Bars[3] := Bar3; Bars[4] := Bar4; Bars[5] := Bar5; Bars[6] := Bar6;
  Values[0] := Value0; Values[1] := Value1; Values[2] := Value2; Values[3] := Value3; Values[4] := Value4;
  Values[5] := Value5; Values[6] := Value6;
  Days[0] := Day0; Days[1] := Day1; Days[2] := Day2; Days[3] := Day3; Days[4] := Day4; Days[5] := Day5; Days[6] := Day6;
  Week := RoasteryData.WeekRevenue;
  Top := 1;
  Total := 0;
  for I := 0 to 6 do
  begin
    Top := Max(Top, Week[I]);
    Total := Total + Week[I];
  end;
  for I := 0 to 6 do
  begin
    Bars[I].Height := Max(8, ChartHeight * Week[I] / Top);
    Values[I].Text := Money(Week[I]);
    if I = 6 then
      Days[I].Text := S('Today', 'Today')
    else
      Days[I].Text := FormatDateTime('ddd', Date - 6 + I);
  end;
  WeekTotal.Text := Money(Total);
end;

procedure THomePage.FillLists;
var
  Sales: TArray<TCoffeeSales>;
  Row: TCoffeeRow;
  Order: TOrderRow;
  Orders: TDataSet;
  I: Integer;
begin
  FTop.Clear;
  Sales := RoasteryData.TopCoffees(5);
  for I := 0 to High(Sales) do
  begin
    Row := TCoffeeRow.Create;
    Row.Name := Sales[I].Name;
    Row.Origin := Sales[I].Origin;
    Row.KgText := Format('%.0f kg', [Sales[I].Kg]);
    Row.Share := 100 * Sales[I].Kg / Sales[0].Kg;
    FTop.Add(Row);
  end;
  // The orders are sorted newest first, the first five are the newest
  FRecent.Clear;
  Orders := RoasteryData.Snapshot(RoasteryData.Orders, 'OrderNo:D');
  try
    while not Orders.Eof and (FRecent.Count < 5) do
    begin
      Order := TOrderRow.Create;
      Order.Customer := Orders.FieldByName('Customer').AsString;
      Order.Detail := Format('#%d  %s, %.1f kg', [Orders.FieldByName('OrderNo').AsInteger,
        Orders.FieldByName('Coffee').AsString, Orders.FieldByName('Kg').AsFloat]);
      Order.TotalText := Money(Orders.FieldByName('Total').AsCurrency);
      Order.Status := S('Status' + Orders.FieldByName('Status').AsString, Orders.FieldByName('Status').AsString);
      FRecent.Add(Order);
      Orders.Next;
    end;
  finally
    Orders.Free;
  end;
end;

procedure THomePage.FillCoffees;
var
  Coffees: TDataSet;
begin
  FShowing := True;
  Coffees := RoasteryData.Snapshot(RoasteryData.Coffees, 'Name');
  try
    while not Coffees.Eof do
    begin
      FCoffees := FCoffees + [Coffees.FieldByName('Name').AsString];
      CoffeeBox.Items.Add(Format('%s, %s', [Coffees.FieldByName('Name').AsString, Coffees.FieldByName('Origin').AsString]));
      Coffees.Next;
    end;
    CoffeeBox.SelectedIndex := 0;
  finally
    Coffees.Free;
    FShowing := False;
  end;
  CoffeeChanged(nil, nil);
  KgChanged(nil, nil);
end;

procedure THomePage.Animate;
var
  Parts, Bars: TArray<TWinUIObject>;
  I: Integer;
begin
  Parts := [RevenueCard, OrdersCard, StockCard, BatchCard, WeekCard, RoastCard, TopCard, RecentCard];
  for I := 0 to High(Parts) do
    TWinUIMotion.Enter(Parts[I], 40 + I * 60, 480, 22);
  Bars := [Bar0, Bar1, Bar2, Bar3, Bar4, Bar5, Bar6];
  for I := 0 to High(Bars) do
    TWinUIMotion.Grow(Bars[I], True, 380 + I * 70, 650);
end;

procedure THomePage.CoffeeChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
var
  Index: Integer;
begin
  Index := CoffeeBox.SelectedIndex;
  if FShowing or (Index < 0) or (Index > High(FCoffees)) then
    Exit;
  CoffeeNotes.Text := VarToStrDef(RoasteryData.Coffees.Lookup('Name', FCoffees[Index], 'Notes'), '');
end;

procedure THomePage.KgChanged(Sender: TObject; E: TWinUIRangeBaseValueChangedEventArgs);
begin
  KgText.Text := Format('%.0f kg', [KgSlider.Value]);
end;

procedure THomePage.StartRoastConfirmed(Sender: TObject; const E: TWinValue);
begin
  if CoffeeBox.SelectedIndex < 0 then
    Exit;
  Roast.Start(FCoffees[CoffeeBox.SelectedIndex], KgSlider.Value);
  Frame.Navigate(TRoastPage);
end;

procedure THomePage.NewOrderClick(Sender: TObject; const E: TWinValue);
begin
  Frame.Navigate(TOrdersPage, 'new');
end;

procedure THomePage.AllOrdersClick(Sender: TObject);
begin
  Frame.Navigate(TOrdersPage);
end;

end.
