unit ProfileWindow;

interface

uses
  RADWinUI.Xaml,
  ProfileViewModel,
  ProfileWindow.Xaml;

type
  TProfileWindow = class(TProfileWindowBase)   // generated from ProfileWindow.xaml
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    procedure ResetClick(Sender: TObject; E: TWinUIRoutedEventArgs);
  end;

implementation

constructor TProfileWindow.Create;
begin
  inherited;
  // ViewModel (typed TProfile, from DataContextType) also sets DataContext
  ViewModel := TProfile.Create;
  ViewModel.Name := 'Ali';
  ViewModel.City := 'Tehran';
end;

destructor TProfileWindow.Destroy;
begin
  ViewModel.Free; // the window does not own its view model
  inherited;
end;

procedure TProfileWindow.ResetClick(Sender: TObject; E: TWinUIRoutedEventArgs);
begin
  // Code changes the model, the bound TextBoxes and the summary follow.
  ViewModel.Name := 'Ali';
  ViewModel.City := 'Tehran';
  ViewModel.IsVip := False;
end;

end.