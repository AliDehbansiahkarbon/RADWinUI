unit MainForm;

{ The customer list, toolbar and status bar are the classic VCL screen. The
  details panel is WinUI: DetailsHost.Xaml in MainForm.dfm (edit it in the Object
  Inspector), bound to the selected TCustomer. Save is wired by its name
  (SaveButtonClick), Revert by its Click attribute. }

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  RADWinUI.Xaml,
  RADWinUI.VclHost,
  Customer;

type
  TCustomersForm = class(TForm)
    ToolbarPanel: TPanel;
    NewButton: TButton;
    DeleteButton: TButton;
    CustomerList: TListBox;
    Splitter: TSplitter;
    DetailsHost: TWinUIHost;
    StatusBar: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure CustomerListClick(Sender: TObject);
    procedure NewButtonClick(Sender: TObject);
    procedure DeleteButtonClick(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
    procedure RevertClick(Sender: TObject);
  private
    FCustomers: TObjectList<TCustomer>;
    FEditing: TCustomer; // a copy: the list changes on Save only
    procedure ShowCustomer(AIndex: Integer);
  end;

var
  CustomersForm: TCustomersForm;

implementation

{$R *.dfm}

procedure TCustomersForm.FormCreate(Sender: TObject);
begin
  FCustomers := TObjectList<TCustomer>.Create;
  FCustomers.Add(TCustomer.Create('Ada Lovelace', 'ada@example.com', 5000, True));
  FCustomers.Add(TCustomer.Create('Alan Turing', 'alan@example.com', 2500, False));
  FCustomers.Add(TCustomer.Create('Grace Hopper', 'grace@example.com', 12000, True));
  FEditing := TCustomer.Create('', '', 0, False);
  for var Item in FCustomers do
    CustomerList.Items.Add(Item.Name);
  DetailsHost.DataContext := FEditing;
  CustomerList.ItemIndex := 0;
  ShowCustomer(0);
end;

procedure TCustomersForm.FormDestroy(Sender: TObject);
begin
  // The bindings read FEditing until the content goes
  DetailsHost.Xaml.Clear;
  FEditing.Free;
  FCustomers.Free;
end;

procedure TCustomersForm.ShowCustomer(AIndex: Integer);
begin
  if AIndex >= 0 then
    FEditing.Assign(FCustomers[AIndex])
  else
  begin
    var Empty := TCustomer.Create('', '', 0, False);
    try
      FEditing.Assign(Empty);
    finally
      Empty.Free;
    end;
  end;
  DeleteButton.Enabled := AIndex >= 0;
  StatusBar.SimpleText := Format('%d customers', [FCustomers.Count]);
end;

procedure TCustomersForm.CustomerListClick(Sender: TObject);
begin
  ShowCustomer(CustomerList.ItemIndex);
end;

procedure TCustomersForm.NewButtonClick(Sender: TObject);
begin
  FCustomers.Add(TCustomer.Create('New customer', '', 1000, False));
  CustomerList.Items.Add('New customer');
  CustomerList.ItemIndex := CustomerList.Count - 1;
  ShowCustomer(CustomerList.ItemIndex);
  DetailsHost.SetFocus; // straight into the WinUI panel, at its first field
end;

procedure TCustomersForm.DeleteButtonClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := CustomerList.ItemIndex;
  if Index < 0 then
    Exit;
  FCustomers.Delete(Index);
  CustomerList.Items.Delete(Index);
  CustomerList.ItemIndex := Index - Ord(Index = CustomerList.Count);
  ShowCustomer(CustomerList.ItemIndex);
end;

procedure TCustomersForm.SaveButtonClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := CustomerList.ItemIndex;
  if Index < 0 then
    Exit;
  FCustomers[Index].Assign(FEditing);
  CustomerList.Items[Index] := FEditing.Name;
  CustomerList.ItemIndex := Index;
  StatusBar.SimpleText := 'Saved ' + FEditing.Name;
  DetailsHost.FindElement<TWinUIInfoBar>('SavedBar').IsOpen := True;
end;

procedure TCustomersForm.RevertClick(Sender: TObject);
begin
  ShowCustomer(CustomerList.ItemIndex);
  StatusBar.SimpleText := 'Changes reverted';
end;

end.
