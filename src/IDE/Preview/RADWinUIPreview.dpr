program RADWinUIPreview;

{ Live XAML preview host, see RADWinUI.Preview.Host for the command line and pipe protocol. }

uses
  RADWinUI.Forms,
  RADWinUI.Controls, // XAML of the window may use RADWinUI's own controls (rw:)
  RADWinUI.TabBars,
  RADWinUI.ActionButtons,
  RADWinUI.Designer.Palette in '..\Designer\RADWinUI.Designer.Palette.pas',
  RADWinUI.Designer.Snap in '..\Designer\RADWinUI.Designer.Snap.pas',
  RADWinUI.Preview.Host in 'RADWinUI.Preview.Host.pas';

begin
  TWinUIApp.Run(TPreviewWindow);
end.
