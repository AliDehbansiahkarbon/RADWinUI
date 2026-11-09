unit SettingsPage;

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Pages,
  SettingsPage.Xaml;

type
  TSettingsPage = class(TSettingsPageBase)   // generated from SettingsPage.xaml
  private
    procedure ShowHistory;
  protected
    procedure NavigatedTo(const AArgs: TWinUINavigationArgs); override;
  published
    procedure ClearClick(Sender: TObject);
  end;

implementation

uses
  System.SysUtils;

procedure TSettingsPage.NavigatedTo(const AArgs: TWinUINavigationArgs);
begin
  ShowHistory;
end;

procedure TSettingsPage.ShowHistory;
var
  Names: TArray<string>;
  PageClass: TWinUIXamlPageClass;
begin
  Names := nil;
  for PageClass in Frame.BackStack do
    Names := Names + [PageClass.ClassName.Substring(1).Replace('Page', '')];
  case Length(Names) of
    0: HistoryText.Text := 'No pages behind this one.';
    1: HistoryText.Text := '1 page behind this one: ' + Names[0] + '.';
  else
    HistoryText.Text := Format('%d pages behind this one: %s.', [Length(Names), string.Join(', ', Names)]);
  end;
  ClearButton.IsEnabled := Frame.CanGoBack;
end;

procedure TSettingsPage.ClearClick(Sender: TObject);
begin
  Frame.ClearBackStack;
  ShowHistory;
end;

end.