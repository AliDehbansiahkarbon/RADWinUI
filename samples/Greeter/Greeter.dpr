program Greeter;

{ A form described in GreetWindow.xaml: TextBox, Button and TextBlock, Mica backdrop, centered. }

uses
  RADWinUI.Forms,
  GreetWindow.Xaml in 'GreetWindow.Xaml.pas',
  GreetWindow in 'GreetWindow.pas';

begin
  ReportMemoryLeaksOnShutdown := True;
  TWinUIApp.Run(TGreetWindow);
end.