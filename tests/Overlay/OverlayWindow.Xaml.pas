unit OverlayWindow.Xaml;

{
  TOverlayWindowBase: base class of TOverlayWindow, generated from OverlayWindow.xaml
  by RADWinUI XamlCodeGen 0.5 (tools/XamlCodeGen).

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
    procedure WireXaml;
    {$IFDEF DEBUG}
    procedure ReloadXaml(const AXaml: string);
    {$ENDIF}
  public
    constructor Create; override;
  end;
  {$M-}

implementation

{$IFDEF DEBUG}
uses
  RADWinUI.HotReload;
{$ENDIF}

const
  // OverlayWindow.xaml(7): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Background="Transparent">' + sLineBreak +
    '        <Border x:Name="Pill" Width="200" Height="60" HorizontalAlignment="Center" VerticalAlignment="Top" Background="#FFFF0000" CornerRadius="30" />' + sLineBreak +
    '    </Grid>' + sLineBreak;
  {$IFDEF DEBUG}
  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild
  XamlShape = 'F:Pill:TWinUIBorder;';
  {$ENDIF}

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
  WireXaml;
  {$IFDEF DEBUG}
  AddHelper(TXamlHotReload.Watch(Self, 'OverlayWindow.xaml', XamlShape, ReloadXaml));
  {$ENDIF}
end;

// The x:Name fields and the event wiring of the content, again after a hot reload
procedure TOverlayWindowBase.WireXaml;
begin
  // x:Name elements
  Pill := FindElement<TWinUIBorder>('Pill');
end;

{$IFDEF DEBUG}
// Hot reload: OverlayWindow.xaml edited in the IDE while the app runs
procedure TOverlayWindowBase.ReloadXaml(const AXaml: string);
begin
  LoadContent(AXaml);
  WireXaml;
end;
{$ENDIF}

end.
