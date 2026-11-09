unit MainWindow;

interface

uses
  RADWinUI.Forms,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  MainWindow.Xaml;

type
  TMainWindow = class(TMainWindowBase)   // generated from MainWindow.xaml
  public
    constructor Create; override;
  end;

implementation

uses
  HomePage,
  PeoplePage,
  SettingsPage;

constructor TMainWindow.Create;
begin
  inherited;
  // Menu clicks, the settings item and the back button drive the frame
  ContentFrame.AttachNavigationView(Nav, [THomePage, TPeoplePage], TSettingsPage);
  ContentFrame.Navigate(THomePage);
end;

end.