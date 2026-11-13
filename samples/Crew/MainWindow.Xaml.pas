unit MainWindow.Xaml;

{
  TMainWindowBase: base class of TMainWindow, generated from MainWindow.xaml
  by RADWinUI XamlCodeGen 0.5 (tools/XamlCodeGen).

  DO NOT EDIT. Change MainWindow.xaml or the published handlers of TMainWindow
  in MainWindow.pas; the build regenerates this unit.

  Fields      one per x:Name element, in XAML order
  Create      window settings, content, fields, event wiring
  Comments    name the XAML line each item comes from
}

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Pages,
  RADWinUI.Forms;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TMainWindowBase = class(TWinUIWindow)
  protected
    Nav: TWinUINavigationView;      // MainWindow.xaml(11) <NavigationView>
    ContentFrame: TWinUIPageFrame;  // MainWindow.xaml(21) <Frame>
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
  // MainWindow.xaml(11): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<NavigationView xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="Nav" PaneDisplayMode="Left" IsBackButtonVisible="Visibl' +
    'e" OpenPaneLength="220" PaneTitle="Crew">' + sLineBreak +
    '    <NavigationView.MenuItems>' + sLineBreak +
    '      <NavigationViewItem Content="Home" Tag="THomePage">' + sLineBreak +
    '        <NavigationViewItem.Icon><FontIcon Glyph="" /></NavigationViewItem.Icon>' + sLineBreak +
    '      </NavigationViewItem>' + sLineBreak +
    '      <NavigationViewItem Content="People" Tag="TPeoplePage">' + sLineBreak +
    '        <NavigationViewItem.Icon><FontIcon Glyph="" /></NavigationViewItem.Icon>' + sLineBreak +
    '      </NavigationViewItem>' + sLineBreak +
    '    </NavigationView.MenuItems>' + sLineBreak +
    '    <Frame x:Name="ContentFrame" Padding="32,24,32,24" />' + sLineBreak +
    '  </NavigationView>' + sLineBreak;
  {$IFDEF DEBUG}
  // Hot reload compares it with the edited XAML: the same fields and events reload without a rebuild
  XamlShape = 'F:Nav:TWinUINavigationView;F:ContentFrame:TWinUIPageFrame;';
  {$ENDIF}

constructor TMainWindowBase.Create;
begin
  inherited;
  // MainWindow.xaml(1): <Window> attributes
  Title := 'Crew';
  Width := 1080;
  Height := 720;
  MinWidth := 640;
  MinHeight := 480;
  Backdrop := TWinUIBackdrop.Mica;
  Center;
  LoadContent(ContentXaml);
  WireXaml;
  {$IFDEF DEBUG}
  AddHelper(TXamlHotReload.Watch(Self, 'MainWindow.xaml', XamlShape, ReloadXaml));
  {$ENDIF}
end;

// The x:Name fields and the event wiring of the content, again after a hot reload
procedure TMainWindowBase.WireXaml;
begin
  // x:Name elements
  Nav := FindElement<TWinUINavigationView>('Nav');
  ContentFrame := FindElement<TWinUIPageFrame>('ContentFrame');
end;

{$IFDEF DEBUG}
// Hot reload: MainWindow.xaml edited in the IDE while the app runs
procedure TMainWindowBase.ReloadXaml(const AXaml: string);
begin
  LoadContent(AXaml);
  WireXaml;
end;
{$ENDIF}

end.
