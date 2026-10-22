unit ListWindow;

interface

uses
  System.SysUtils,
  RADWinUI.Xaml,
  ListWindow.Xaml;

type
  TListWindow = class(TListWindowBase)   // generated from ListWindow.xaml
  private
    procedure UpdateStatus;
  public
    constructor Create; override;
  published
    procedure AddClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure RemoveClick(Sender: TObject; E: TWinUIRoutedEventArgs);
    procedure FruitsSelectionChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
  end;

implementation

constructor TListWindow.Create;
begin
  inherited;
  UpdateStatus;
end;

procedure TListWindow.UpdateStatus;
begin
  if Fruits.SelectedIndex < 0 then
    Status.Text := Format('%d items, none selected', [Fruits.Items.Count])
  else
    Status.Text := Format('%d items, selected: %s', [Fruits.Items.Count, Fruits.SelectedItem.AsString]);
end;

procedure TListWindow.AddClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  if Trim(NewItem.Text) <> '' then
  begin
    Fruits.Items.Add(Trim(NewItem.Text));
    NewItem.Text := '';
  end;
  UpdateStatus;
end;

procedure TListWindow.RemoveClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  if Fruits.SelectedIndex >= 0 then
    Fruits.Items.Delete(Fruits.SelectedIndex);
  UpdateStatus;
end;

procedure TListWindow.FruitsSelectionChanged(Sender: TObject; E: TWinUISelectionChangedEventArgs);
begin
  UpdateStatus;
end;

end.