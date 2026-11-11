unit AddStationWindow;

interface

uses
  System.SysUtils,
  System.UITypes,
  RADWinUI.Forms,
  RADWinUI.Xaml,
  AddStationWindow.Xaml;

type
  TAddStationWindow = class(TAddStationWindowBase)   // generated from AddStationWindow.xaml
  public
    function StationName: string;
    function Genre: string;
  published
    procedure NameChanged(Sender: TObject);
    procedure AddClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);
  end;

implementation

function TAddStationWindow.StationName: string;
begin
  Result := Trim(NameBox.Text);
end;

function TAddStationWindow.Genre: string;
begin
  Result := GenreBox.SelectedItem.AsString;
end;

procedure TAddStationWindow.NameChanged(Sender: TObject);
begin
  AddButton.IsEnabled := StationName <> '';
end;

procedure TAddStationWindow.AddClick(Sender: TObject);
begin
  // As in the VCL, setting ModalResult closes a modal window
  ModalResult := mrOk;
end;

procedure TAddStationWindow.CancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.