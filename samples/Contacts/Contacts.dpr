program Contacts;

// A ListView bound to a Delphi list: ItemsSource is a TWinUIBindableList<TContact>,
// and the item template binds Name and Email.

uses
  RADWinUI.Forms,
  ContactsWindow.Xaml in 'ContactsWindow.Xaml.pas',
  ContactsWindow in 'ContactsWindow.pas';

begin
  ReportMemoryLeaksOnShutdown := True;
  TWinUIApp.Run(TContactsWindow);
end.