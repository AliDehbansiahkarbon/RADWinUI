program DataControls;

{ The Tool Palette's Data Controls bound to FireDAC memory tables in a data module. }

uses
  RADWinUI.Forms,
  CustomerDataModule in 'CustomerDataModule.pas' {CustomerData: TDataModule},
  MainWindow.Xaml in 'MainWindow.Xaml.pas',
  MainWindow in 'MainWindow.pas';

begin
  ReportMemoryLeaksOnShutdown := True;
  // The data module first, so the window finds its data sources by name
  CustomerData := TCustomerData.Create(nil);
  try
    TWinUIApp.Run(TMainWindow);
  finally
    CustomerData.Free;
  end;
end.
