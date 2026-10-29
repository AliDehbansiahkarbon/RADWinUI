unit OverlayWindow;

interface

uses
  RADWinUI.Forms,
  OverlayWindow.Xaml;

type
  TOverlayWindow = class(TOverlayWindowBase)
  public
    constructor Create; override;
  end;

implementation

constructor TOverlayWindow.Create;
begin
  inherited;
  HitTestElement := Pill;
end;

end.
