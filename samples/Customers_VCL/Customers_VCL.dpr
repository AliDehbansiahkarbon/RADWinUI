program Customers_VCL;

{ A classic VCL screen with one panel modernized: the customer list, toolbar and
  status bar stay VCL, the details panel is WinUI in a TWinUIHost (MainForm.dfm). }

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {CustomersForm},
  Customer in 'Customer.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TCustomersForm, CustomersForm);
  Application.Run;
end.
