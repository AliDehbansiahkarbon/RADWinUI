unit OverlayWindow.Xaml;

{
  TOverlayWindowBase: base class of TOverlayWindow, generated from OverlayWindow.xaml
  by RADWinUI XamlCodeGen 0.4 (tools/XamlCodeGen).

  DO NOT EDIT. Change OverlayWindow.xaml or the published handlers of TOverlayWindow
  in OverlayWindow.pas; the build regenerates this unit.

  Fields      one per x:Name element, in XAML order
  Create      window settings, content, fields, event wiring
  Comments    name the XAML line each item comes from
}

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Forms;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TOverlayWindowBase = class(TWinUIWindow)
  protected
    Pill: TWinUIBorder;  // OverlayWindow.xaml(8) <Border>
  public
    constructor Create; override;
  end;
  {$M-}

implementation

const
  // OverlayWindow.xaml(7): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Background="Transparent">' + sLineBreak +
    '        <Border x:Name="Pill" Width="200" Height="60" HorizontalAlignment="Center" VerticalAlignment="Top" Background="#FFFF0000" CornerRadius="30" />' + sLineBreak +
    '    </Grid>' + sLineBreak;

constructor TOverlayWindowBase.Create;
begin
  inherited;
  // OverlayWindow.xaml(1): <Window> attributes
  Title := 'Overlay test';
  WindowStyle := TWinUIWindowStyle.Overlay;
  Width := 400;
  Height := 200;
  Backdrop := TWinUIBackdrop.Transparent;
  Dock := TWinUIDock.TopCenter;
  ClickThrough := TWinUIClickThrough.Background;
  ShowActivated := False;
  LoadContent(ContentXaml);
  // x:Name elements
  Pill := FindElement<TWinUIBorder>('Pill');
end;

end.
