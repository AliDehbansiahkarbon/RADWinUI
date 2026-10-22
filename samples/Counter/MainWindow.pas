unit MainWindow;

interface

uses
  System.SysUtils,
  RADWinUI.Xaml,
  MainWindow.Xaml;

type
  TMainWindow = class(TMainWindowBase)   // TMainWindowBase is generated from MainWindow.xaml
  private
    FCounter: Integer;
  published
    // Wired by name: IncrementButton + Click
    procedure IncrementButtonClick(Sender: TObject);
    // Wired by Click="ResetClick" in the XAML
    procedure ResetClick(Sender: TObject; E: TWinUIRoutedEventArgs);
  end;

implementation

procedure TMainWindow.IncrementButtonClick(Sender: TObject);
begin
  Inc(FCounter);
  CounterText.Text := FCounter.ToString;
end;

procedure TMainWindow.ResetClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  FCounter := 0;
  CounterText.Text := '0';
end;

end.