program Profile;

// DataContext binding to a Delphi view model: two TextBoxes bound two-way to
// published properties, a computed summary bound one-way, and converters.

uses
  System.SysUtils,
  RADWinUI.Framework,
  RADWinUI.Forms,
  ProfileViewModel in 'ProfileViewModel.pas',
  ProfileWindow.Xaml in 'ProfileWindow.Xaml.pas',
  ProfileWindow in 'ProfileWindow.pas';

begin
  ReportMemoryLeaksOnShutdown := True;
  // {StaticResource Upper} in ProfileWindow.xaml
  TWinUIApp.RegisterConverter('Upper',
    function(const AValue: TWinValue; const AParameter: string): TWinValue
    begin
      Result := UpperCase(AValue.AsString);
    end);
  TWinUIApp.Run(TProfileWindow);
end.