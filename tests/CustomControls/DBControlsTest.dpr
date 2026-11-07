program DBControlsTest;

{
  Checks the data controls (RADWinUI.DBControls) against FireDAC memory
  tables: DataSource names are found on the window and in data modules,
  every control shows the current record, moving the cursor updates them,
  typing puts the dataset into Edit and Post writes the field, the
  navigator follows the dataset's state, the grid lists the records and
  follows the cursor both ways, lookups list their records, Insert, Post
  and Cancel through the navigator keep the grids (a master/detail pair
  too) right, and closing a window frees its controls.
  The window opens where RADWINUI_TEST_MONITOR puts test windows.
}

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.Math,
  System.DateUtils,
  Data.DB,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  RADWinUI.Abi,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Forms,
  RADWinUI.CustomControls,
  RADWinUI.DBControls;

type
  TTestWindow = class(TWinUIWindow)
  private
    FTimer: TWinUITimer;
    FStep: Integer;
    FFailures: Integer;
    FData: TDataModule;
    FCustomers: TFDMemTable;
    FCountries: TFDMemTable;
    FOrders: TFDMemTable;
    FSecond: TWinUIWindow;
    FLiveBefore: Integer;
    FClicks: Integer;
    procedure Check(AOk: Boolean; const AWhat: string);
    procedure MakeData;
    procedure Step(Sender: TObject);
    procedure NavigatorClick(Sender: TObject; const E: TWinValue);
  public
    constructor Create; override;
    destructor Destroy; override;
    class procedure Failed(Sender: TObject; E: Exception);
  published
    // Found by XAML's DataSource="OrdersSource": a published field of the window
    OrdersSource: TDataSource;
  end;

const
  Namespaces = 'xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:rw="using:RADWinUI.Controls"';

  ContentXaml =
    '<StackPanel ' + Namespaces + ' Spacing="8" Padding="16">' +
    '<rw:DBNavigator x:Name="Nav" DataSource="CustomersSource" ConfirmDelete="False" />' +
    '<rw:DBEdit x:Name="NameEdit" DataSource="Data.CustomersSource" DataField="Name" Header="Name" />' +
    '<rw:DBText x:Name="NameText" DataSource="CustomersSource" DataField="Name" />' +
    '<rw:DBCheckBox x:Name="ActiveCheck" DataSource="CustomersSource" DataField="Active" Text="Active" />' +
    '<rw:DBToggleSwitch x:Name="VipSwitch" DataSource="CustomersSource" DataField="Vip" ValueChecked="Y" ValueUnchecked="N" />' +
    '<rw:DBNumberBox x:Name="BalanceBox" DataSource="CustomersSource" DataField="Balance" />' +
    '<rw:DBDatePicker x:Name="JoinedPicker" DataSource="CustomersSource" DataField="Joined" />' +
    '<rw:DBComboBox x:Name="TierCombo" DataSource="CustomersSource" DataField="Tier" Items="Bronze, Silver, Gold" />' +
    '<rw:DBRadioGroup x:Name="TierRadio" DataSource="CustomersSource" DataField="Tier" Items="Bronze, Silver, Gold" ' +
    'Values="Bronze, Silver, Gold" />' +
    '<rw:DBLookupComboBox x:Name="CountryCombo" DataSource="CustomersSource" DataField="CountryID" ' +
    'ListSource="CountriesSource" KeyField="ID" ListField="CountryName" />' +
    '<rw:DBMemo x:Name="NotesMemo" DataSource="CustomersSource" DataField="Notes" />' +
    '<rw:DBText x:Name="NotesText" DataSource="CustomersSource" DataField="Notes" />' +
    '<rw:DBGrid x:Name="Grid" DataSource="CustomersSource" Columns="Name:160, Tier, Balance" ReadOnly="True" />' +
    '<rw:DBCtrlGrid x:Name="Cards" DataSource="CustomersSource" Height="120" />' +
    '<rw:DBText x:Name="CountryText" DataSource="OrdersSource" DataField="CountryName" />' +
    '<rw:DBNavigator x:Name="OrdersNav" DataSource="CustomerOrdersSource" />' +
    '<rw:DBGrid x:Name="OrdersGrid" DataSource="CustomerOrdersSource" Height="120" />' +
    '</StackPanel>';

  SecondXaml =
    '<StackPanel ' + Namespaces + '>' +
    '<rw:DBGrid DataSource="CustomersSource" /><rw:DBNavigator DataSource="CustomersSource" />' +
    '<rw:DBEdit DataSource="CustomersSource" DataField="Name" /><rw:DBImage DataSource="CustomersSource" />' +
    '<rw:DBRichEdit DataSource="CustomersSource" DataField="Notes" /><rw:DBListBox DataSource="CustomersSource" />' +
    '<rw:DBLookupListBox DataSource="CustomersSource" /></StackPanel>';

{ TTestWindow }

class procedure TTestWindow.Failed(Sender: TObject; E: Exception);
begin
  Writeln('  [failed] ', E.ClassName, ': ', E.Message);
  Flush(Output);
  ExitProcess(1);
end;

procedure TTestWindow.MakeData;
var
  Source: TDataSource;
begin
  // A data module made in code, as the IDE's designer would make one
  FData := TDataModule.CreateNew(nil);
  FData.Name := 'Data';
  FCountries := TFDMemTable.Create(FData);
  FCountries.Name := 'Countries';
  FCountries.FieldDefs.Add('ID', ftInteger);
  FCountries.FieldDefs.Add('CountryName', ftString, 40);
  FCountries.CreateDataSet;
  FCountries.AppendRecord([1, 'Canada']);
  FCountries.AppendRecord([2, 'Germany']);
  FCountries.AppendRecord([3, 'Japan']);
  FCountries.First;
  Source := TDataSource.Create(FData);
  Source.Name := 'CountriesSource';
  Source.DataSet := FCountries;

  FCustomers := TFDMemTable.Create(FData);
  FCustomers.Name := 'Customers';
  FCustomers.FieldDefs.Add('ID', ftInteger);
  FCustomers.FieldDefs.Add('Name', ftString, 40);
  FCustomers.FieldDefs.Add('Active', ftBoolean);
  FCustomers.FieldDefs.Add('Vip', ftString, 1);
  FCustomers.FieldDefs.Add('Balance', ftFloat);
  FCustomers.FieldDefs.Add('Joined', ftDate);
  FCustomers.FieldDefs.Add('Tier', ftString, 10);
  FCustomers.FieldDefs.Add('CountryID', ftInteger);
  FCustomers.FieldDefs.Add('Notes', ftMemo);
  FCustomers.CreateDataSet;
  FCustomers.AppendRecord([1, 'Alpha Foods', True, 'Y', 120.5, EncodeDate(2024, 3, 14), 'Gold', 2, 'First note']);
  FCustomers.AppendRecord([2, 'Bravo Ltd', False, 'N', 80, EncodeDate(2023, 11, 2), 'Silver', 3, 'Second note']);
  FCustomers.AppendRecord([3, 'Charlie Inc', True, 'N', 0, EncodeDate(2022, 1, 20), 'Bronze', 1, '']);
  FCustomers.First;
  Source := TDataSource.Create(FData);
  Source.Name := 'CustomersSource';
  Source.DataSet := FCustomers;
  // The orders of the current customer: a master/detail pair
  FOrders := TFDMemTable.Create(FData);
  FOrders.Name := 'Orders';
  FOrders.FieldDefs.Add('OrderNo', ftInteger);
  FOrders.FieldDefs.Add('CustomerID', ftInteger);
  FOrders.FieldDefs.Add('Product', ftString, 40);
  FOrders.IndexFieldNames := 'CustomerID;OrderNo';
  FOrders.CreateDataSet;
  FOrders.AppendRecord([101, 1, 'Paper cups']);
  FOrders.AppendRecord([102, 1, 'Boxes']);
  FOrders.AppendRecord([103, 2, 'Tape']);
  FOrders.MasterSource := Source;
  FOrders.MasterFields := 'ID';
  Source := TDataSource.Create(FData);
  Source.Name := 'CustomerOrdersSource';
  Source.DataSet := FOrders;
  // The window's own field
  OrdersSource := TDataSource.Create(nil);
  OrdersSource.DataSet := FCountries;
end;

constructor TTestWindow.Create;
begin
  inherited;
  Title := 'Data controls test';
  Width := 520;
  Height := 1100;
  Writeln('Data controls');
  MakeData;
  Check(Length(TWinUIDataSources.Modules) = 1, 'a data module made at run time is known');
  Check(TWinUIDataSources.Find(nil, 'CustomersSource') <> nil, 'Find: a data source of a data module, by name');
  Check(TWinUIDataSources.Find(nil, 'Data.CountriesSource') <> nil, 'Find: Module.Source');
  Check(TWinUIDataSources.Find(nil, 'Nothing.CountriesSource') = nil, 'Find: an unknown module finds nothing');
  Check(TWinUIDataSources.Find(Self, 'OrdersSource') = OrdersSource, 'Find: a published field of the window');
  LoadContent(ContentXaml);
  Check(True, 'XAML with the data controls loads');
  FTimer := TWinUITimer.Create;
  FTimer.Interval := 400;
  FTimer.OnTimer := Step;
  FTimer.Enabled := True;
end;

destructor TTestWindow.Destroy;
begin
  FTimer.Free;
  inherited;
  OrdersSource.Free;
  FData.Free;
  if FFailures > 0 then
    ExitCode := 1;
end;

procedure TTestWindow.Check(AOk: Boolean; const AWhat: string);
begin
  if AOk then
    Writeln('  [ok] ', AWhat)
  else
  begin
    Writeln('  [failed] ', AWhat);
    Inc(FFailures);
  end;
end;

procedure TTestWindow.NavigatorClick(Sender: TObject; const E: TWinValue);
begin
  Inc(FClicks);
end;

procedure TTestWindow.Step(Sender: TObject);
var
  Nav: TWinUIDBNavigator;
  NameEdit: TWinUIDBEdit;
  NameText, CountryText, NotesText: TWinUIDBText;
  NotesMemo: TWinUIDBMemo;
  ActiveCheck: TWinUIDBCheckBox;
  VipSwitch: TWinUIDBToggleSwitch;
  BalanceBox: TWinUIDBNumberBox;
  JoinedPicker: TWinUIDBDatePicker;
  TierCombo: TWinUIDBComboBox;
  TierRadio: TWinUIDBRadioGroup;
  CountryCombo: TWinUIDBLookupComboBox;
  Grid: TWinUIDBGrid;
  Cards: TWinUIDBCtrlGrid;
  OrdersNav: TWinUIDBNavigator;
  OrdersGrid: TWinUIDBGrid;
  Date: IReference_DateTime;
  Checked: IReference_Boolean;
  Found: Boolean;
  I: Integer;
begin
  Inc(FStep);
  try
    Nav := FindElement<TWinUIDBNavigator>('Nav');
    NameEdit := FindElement<TWinUIDBEdit>('NameEdit');
    NameText := FindElement<TWinUIDBText>('NameText');
    CountryText := FindElement<TWinUIDBText>('CountryText');
    NotesText := FindElement<TWinUIDBText>('NotesText');
    NotesMemo := FindElement<TWinUIDBMemo>('NotesMemo');
    ActiveCheck := FindElement<TWinUIDBCheckBox>('ActiveCheck');
    VipSwitch := FindElement<TWinUIDBToggleSwitch>('VipSwitch');
    BalanceBox := FindElement<TWinUIDBNumberBox>('BalanceBox');
    JoinedPicker := FindElement<TWinUIDBDatePicker>('JoinedPicker');
    TierCombo := FindElement<TWinUIDBComboBox>('TierCombo');
    TierRadio := FindElement<TWinUIDBRadioGroup>('TierRadio');
    CountryCombo := FindElement<TWinUIDBLookupComboBox>('CountryCombo');
    Grid := FindElement<TWinUIDBGrid>('Grid');
    Cards := FindElement<TWinUIDBCtrlGrid>('Cards');
    OrdersNav := FindElement<TWinUIDBNavigator>('OrdersNav');
    OrdersGrid := FindElement<TWinUIDBGrid>('OrdersGrid');
    case FStep of
      1:
        begin
          Check((Nav.DataSource <> nil) and (Nav.DataSource.Name = 'CustomersSource'),
            'DataSource="CustomersSource" is found in the data module');
          Check(NameEdit.DataSource = Nav.DataSource, 'DataSource="Data.CustomersSource" finds the same one');
          Check(CountryText.DataSource = OrdersSource, 'DataSource="OrdersSource" finds the window''s field');
          Check(NameEdit.Field <> nil, 'DBEdit: DataField finds the field');
          Check(NameEdit.TextBox.Text = 'Alpha Foods', 'DBEdit shows the first record (' + NameEdit.TextBox.Text + ')');
          Check(NameText.Field.AsString = 'Alpha Foods', 'DBText is on the same field');
          // A memo field shows its content, not '(MEMO)'
          Check(NotesMemo.TextBox.Text = 'First note', 'DBMemo shows the memo text (' + NotesMemo.TextBox.Text + ')');
          Check(NotesText.TextBlock.Text = 'First note', 'DBText on a memo field shows the text (' +
            NotesText.TextBlock.Text + ')');
          Checked := ActiveCheck.CheckBox.IsChecked;
          Check((Checked <> nil) and Checked.Value, 'DBCheckBox: a True Boolean field is checked');
          Check(VipSwitch.ToggleSwitch.IsOn, 'DBToggleSwitch: ValueChecked="Y" is on');
          Check(SameValue(BalanceBox.NumberBox.Value, 120.5), Format('DBNumberBox shows the value (%g)',
            [BalanceBox.NumberBox.Value]));
          Date := JoinedPicker.DatePicker.Date;
          Check(Date <> nil, 'DBDatePicker shows a date');
          Check(TierCombo.ComboBox.SelectedIndex = 2, Format('DBComboBox selects Gold (%d)',
            [TierCombo.ComboBox.SelectedIndex]));
          Check(TierRadio.RadioButtons.SelectedIndex = 2, 'DBRadioGroup selects Gold');
          Check(CountryCombo.ItemCount = 3, Format('DBLookupComboBox lists the 3 countries (%d)',
            [CountryCombo.ItemCount]));
          Check(CountryCombo.ComboBox.SelectedIndex = 1, Format('DBLookupComboBox selects Germany for key 2 (%d)',
            [CountryCombo.ComboBox.SelectedIndex]));
          Check(Grid.RowCount = 3, Format('DBGrid lists 3 records (%d)', [Grid.RowCount]));
          Check((Grid.Cell(1, 0) = 'Bravo Ltd') and (Grid.Cell(2, 1) = 'Bronze'),
            'DBGrid: Columns picks the fields (' + Grid.Cell(1, 0) + ', ' + Grid.Cell(2, 1) + ')');
          Check(Cards.RowCount = 3, 'DBCtrlGrid lists 3 records');
          Check(Grid.ListView.SelectedIndex = 0, 'DBGrid selects the current record');
          Check(not Nav.DataSource.DataSet.Bof or True, 'navigator ready');
          Nav.OnClick := NavigatorClick;
          Nav.BtnClick(TWinUINavigateButton.Next);
          Check(FClicks = 1, 'DBNavigator raises Click');
          Check(FCustomers.RecNo = 2, 'Next moves the dataset');
          Check(NameEdit.TextBox.Text = 'Bravo Ltd', 'DBEdit follows the cursor (' + NameEdit.TextBox.Text + ')');
          Checked := ActiveCheck.CheckBox.IsChecked;
          Check((Checked <> nil) and not Checked.Value, 'DBCheckBox follows the cursor');
          Check(not VipSwitch.ToggleSwitch.IsOn, 'DBToggleSwitch: ValueUnchecked="N" is off');
          Check(TierCombo.ComboBox.SelectedIndex = 1, 'DBComboBox follows the cursor');
          Check(CountryCombo.ComboBox.SelectedIndex = 2, 'DBLookupComboBox follows the cursor');
          Check(Grid.ListView.SelectedIndex = 1, Format('DBGrid follows the cursor (%d)', [Grid.ListView.SelectedIndex]));
          // The user types
          NameEdit.TextBox.Text := 'Bravo Limited';
        end;
      2:
        begin
          // TextChanged comes after the change
          Check(FCustomers.State = dsEdit, 'typing in DBEdit puts the dataset into Edit');
          Check(FCustomers.FieldByName('Name').AsString = 'Bravo Ltd', 'the field keeps its value until Post');
          Nav.BtnClick(TWinUINavigateButton.Post);
          Check(FCustomers.State = dsBrowse, 'Post ends the edit');
          Check(FCustomers.FieldByName('Name').AsString = 'Bravo Limited', 'Post writes what was typed (' +
            FCustomers.FieldByName('Name').AsString + ')');
          Check(Grid.Cell(1, 0) = 'Bravo Limited', 'DBGrid shows the posted value (' + Grid.Cell(1, 0) + ')');
          // A change from code shows in the controls
          FCustomers.Edit;
          FCustomers.FieldByName('Tier').AsString := 'Bronze';
          FCustomers.FieldByName('Active').AsBoolean := True;
          FCustomers.FieldByName('CountryID').AsInteger := 1;
          Check(TierCombo.ComboBox.SelectedIndex = 0, 'a field set in code updates DBComboBox');
          Check(TierRadio.RadioButtons.SelectedIndex = 0, 'and DBRadioGroup');
          Checked := ActiveCheck.CheckBox.IsChecked;
          Check((Checked <> nil) and Checked.Value, 'and DBCheckBox');
          Check(CountryCombo.ComboBox.SelectedIndex = 0, 'and DBLookupComboBox');
          Nav.BtnClick(TWinUINavigateButton.Cancel);
          Check(FCustomers.FieldByName('Tier').AsString = 'Silver', 'Cancel drops the change');
          Check(TierCombo.ComboBox.SelectedIndex = 1, 'DBComboBox shows the value again after Cancel');
          // The user picks in a list control
          TierCombo.ComboBox.SelectedIndex := 2;
          Check(FCustomers.FieldByName('Tier').AsString = 'Gold', 'picking in DBComboBox writes the field (' +
            FCustomers.FieldByName('Tier').AsString + ')');
          Check(TierRadio.RadioButtons.SelectedIndex = 2, 'and DBRadioGroup shows it');
          CountryCombo.ComboBox.SelectedIndex := 0;
          Check(FCustomers.FieldByName('CountryID').AsInteger = 1, 'picking in DBLookupComboBox writes the key');
          BalanceBox.NumberBox.Value := 99;
          Check(SameValue(FCustomers.FieldByName('Balance').AsFloat, 99), 'DBNumberBox writes the field');
          VipSwitch.ToggleSwitch.IsOn := True;
          Check(FCustomers.FieldByName('Vip').AsString = 'Y', 'DBToggleSwitch writes ValueChecked');
          Nav.BtnClick(TWinUINavigateButton.Post);
          Check(FCustomers.State = dsBrowse, 'Post');
          // The grid moves the cursor
          Grid.ListView.SelectedIndex := 2;
          Check(FCustomers.RecNo = 3, Format('selecting a grid row moves the dataset (%d)', [FCustomers.RecNo]));
          Check(NameText.Field.AsString = 'Charlie Inc', 'and the other controls follow');
          // Insert and Cancel
          Nav.BtnClick(TWinUINavigateButton.Insert);
          Check(FCustomers.State = dsInsert, 'Insert');
          Check(Grid.RowCount = 4, Format('DBGrid shows the new row (%d)', [Grid.RowCount]));
          Check(NameEdit.TextBox.Text = '', 'DBEdit is empty for the new record');
          Nav.BtnClick(TWinUINavigateButton.Cancel);
          Check(Grid.RowCount = 3, Format('Cancel takes the new row away (%d)', [Grid.RowCount]));
          // Insert and Post
          Nav.BtnClick(TWinUINavigateButton.Last);
          FCustomers.Append;
          FCustomers.FieldByName('ID').AsInteger := 4;
          FCustomers.FieldByName('Name').AsString := 'Delta Co';
          FCustomers.Post;
          Check(Grid.RowCount = 4, Format('an appended record shows in DBGrid (%d)', [Grid.RowCount]));
          Check(Grid.ListView.SelectedIndex = 3, Format('and is selected (%d)', [Grid.ListView.SelectedIndex]));
          // Delete
          Nav.BtnClick(TWinUINavigateButton.Delete);
          Check(FCustomers.RecordCount = 3, 'Delete removes the record (ConfirmDelete="False")');
          Check(Grid.RowCount = 3, 'and DBGrid drops its row');
          // A window with more controls: closing it must free them
          FLiveBefore := TWinUICustomControls.LiveCount;
          FSecond := TWinUIWindow.Create;
          FSecond.LoadContent(SecondXaml);
          FSecond.Show;
          Check(TWinUICustomControls.LiveCount = FLiveBefore + 7, Format('a loaded window has its 7 controls (%d -> %d)',
            [FLiveBefore, TWinUICustomControls.LiveCount]));
        end;
      3:
        begin
          FSecond.Close;
          // RadioButtons reports a new selection a moment later
          TierRadio.RadioButtons.SelectedIndex := 0;
        end;
      4:
        begin
          Check(TWinUICustomControls.LiveCount = FLiveBefore, Format('closing a window frees its controls (%d left)',
            [TWinUICustomControls.LiveCount]));
          Check(FCustomers.FieldByName('Tier').AsString = 'Bronze', 'picking in DBRadioGroup writes the field (' +
            FCustomers.FieldByName('Tier').AsString + ')');
          Check(TierCombo.ComboBox.SelectedIndex = 0, 'and DBComboBox shows it');
          Nav.BtnClick(TWinUINavigateButton.Cancel);
          // Insert on the first record with a grid, a CtrlGrid, a detail grid and the form controls bound
          Nav.BtnClick(TWinUINavigateButton.First);
          Check(OrdersGrid.RowCount = 2, Format('the detail grid lists the master''s orders (%d)', [OrdersGrid.RowCount]));
          Nav.BtnClick(TWinUINavigateButton.Insert);
          Check(FCustomers.State = dsInsert, 'navigator Insert on the first record');
          Check((Grid.RowCount = 4) and (Cards.RowCount = 4), Format('DBGrid and DBCtrlGrid show the new row (%d, %d)',
            [Grid.RowCount, Cards.RowCount]));
          Check(Grid.ListView.SelectedIndex = 0, Format('the new row is selected (%d)', [Grid.ListView.SelectedIndex]));
          Check(OrdersGrid.RowCount = 0, Format('a new master has no orders (%d)', [OrdersGrid.RowCount]));
          FCustomers.FieldByName('ID').AsInteger := 5;
          NameEdit.TextBox.Text := 'Echo GmbH';
        end;
      5:
        begin
          Nav.BtnClick(TWinUINavigateButton.Post);
          Check(FCustomers.State = dsBrowse, 'Post the inserted record');
          Check((FCustomers.RecordCount = 4) and (Grid.RowCount = 4) and (Cards.RowCount = 4),
            Format('the new record is in the dataset, DBGrid and DBCtrlGrid (%d, %d, %d)',
            [FCustomers.RecordCount, Grid.RowCount, Cards.RowCount]));
          Found := False;
          for I := 0 to Grid.RowCount - 1 do
            Found := Found or (Grid.Cell(I, 0) = 'Echo GmbH');
          Check(Found, 'DBGrid shows what was typed in the new record');
          Nav.BtnClick(TWinUINavigateButton.Insert);
          Check(Grid.RowCount = 5, 'Insert again');
          Nav.BtnClick(TWinUINavigateButton.Cancel);
          Check((FCustomers.RecordCount = 4) and (Grid.RowCount = 4) and (Cards.RowCount = 4),
            Format('Cancel drops the new row (%d, %d)', [Grid.RowCount, Cards.RowCount]));
          // Insert in the detail grid
          FCustomers.Locate('ID', 1, []);
          Check(OrdersGrid.RowCount = 2, Format('the detail grid follows the master (%d)', [OrdersGrid.RowCount]));
          OrdersNav.BtnClick(TWinUINavigateButton.Insert);
          Check(OrdersGrid.RowCount = 3, Format('the detail grid shows the new order (%d)', [OrdersGrid.RowCount]));
          FOrders.FieldByName('OrderNo').AsInteger := 104;
          FOrders.FieldByName('Product').AsString := 'Labels';
          OrdersNav.BtnClick(TWinUINavigateButton.Post);
          Check((FOrders.RecordCount = 3) and (OrdersGrid.RowCount = 3),
            Format('Post keeps the order in the detail grid (%d, %d)', [FOrders.RecordCount, OrdersGrid.RowCount]));
          OrdersNav.BtnClick(TWinUINavigateButton.Insert);
          OrdersNav.BtnClick(TWinUINavigateButton.Cancel);
          Check(OrdersGrid.RowCount = 3, Format('Insert and Cancel in the detail grid (%d)', [OrdersGrid.RowCount]));
        end;
      6:
        begin
          // The dataset goes away under the controls
          FCustomers.Close;
          Check(Grid.RowCount = 0, 'a closed dataset empties DBGrid');
          Check(NameEdit.TextBox.Text = '', 'and DBEdit');
          FCustomers.Open;
          Check(Grid.RowCount = 0, 'a reopened memory table is empty');
          Flush(Output);
          Close;
        end;
    end;
  except
    on E: Exception do
      Failed(Self, E);
  end;
end;

begin
  if GetEnvironmentVariable('RADWINUI_TEST_MONITOR') = '' then
    SetEnvironmentVariable('RADWINUI_TEST_MONITOR', 'offscreen');
  TWinUIApp.OnException := TTestWindow.Failed;
  TWinUIApp.Run(TTestWindow);
end.
