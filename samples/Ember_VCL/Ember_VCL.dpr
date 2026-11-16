program Ember_VCL;

{ VCL and WinUI together: Ember's orders in a VCL form on the same FireDAC data
  module as the Ember sample, with the current order as a WinUI card in a TWinUIHost. }

uses
  Vcl.Forms,
  EmberData in '..\Ember\EmberData.pas' {RoasteryData: TDataModule},
  OrderCard in 'OrderCard.pas',
  MainForm in 'MainForm.pas' {OrdersForm};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  // The data module first: the form's controls find RoasteryData.OrdersSource
  Application.CreateForm(TRoasteryData, RoasteryData);
  Application.CreateForm(TOrdersForm, OrdersForm);
  Application.Run;
end.
