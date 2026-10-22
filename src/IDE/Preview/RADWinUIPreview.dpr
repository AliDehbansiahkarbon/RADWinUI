program RADWinUIPreview;

{ Live XAML preview host, see RADWinUI.Preview.Host for the command line and pipe protocol. }

uses
  RADWinUI.Forms,
  RADWinUI.Designer.Palette in '..\Designer\RADWinUI.Designer.Palette.pas',
  RADWinUI.Preview.Host in 'RADWinUI.Preview.Host.pas';

begin
  TWinUIApp.Run(TPreviewWindow);
end.
