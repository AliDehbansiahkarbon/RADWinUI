unit MainWindow.Xaml;

{
  TMainWindowBase: base class of TMainWindow, generated from MainWindow.xaml
  by RADWinUI XamlCodeGen 0.4 (tools/XamlCodeGen).

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
  public
    constructor Create; override;
  end;
  {$M-}

implementation

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
  // x:Name elements
  Nav := FindElement<TWinUINavigationView>('Nav');
  ContentFrame := FindElement<TWinUIPageFrame>('ContentFrame');
end;

end.
