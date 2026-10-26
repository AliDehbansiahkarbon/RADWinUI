unit GreetWindow;

interface

uses
  System.SysUtils,
  RADWinUI.Xaml,
  GreetWindow.Xaml;

type
  TGreetWindow = class(TGreetWindowBase)   // generated from GreetWindow.xaml
  public
    constructor Create; override;
  published
    procedure GreetButtonClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure NameBoxTextChanged(Sender: TObject; E: TWinUITextChangedEventArgs);
  end;

implementation

constructor TGreetWindow.Create;
begin
  inherited;
  BindTransparencySwitch(TransparencySwitch); // Mica on or off
end;

procedure TGreetWindow.GreetButtonClick(Sender: TObject; E: TWinUIRoutedEventArgs);
var
  Name: string;
begin
  Name := Trim(NameBox.Text);
  if Name = '' then
    Greeting.Text := 'Please type your name.'
  else
    Greeting.Text := 'Hello, ' + Name + '!';
end;

procedure TGreetWindow.NameBoxTextChanged(Sender: TObject; E: TWinUITextChangedEventArgs);
begin
  Greeting.Text := ''; // the old greeting no longer matches the name
end;

end.