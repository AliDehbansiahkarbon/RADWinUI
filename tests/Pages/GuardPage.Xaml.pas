unit GuardPage.Xaml;

{
  TGuardPageBase: base class of the page TGuardPage, generated from GuardPage.xaml
  by RADWinUI XamlCodeGen 0.4 (tools/XamlCodeGen).

  DO NOT EDIT. Change GuardPage.xaml or the published handlers of TGuardPage
  in GuardPage.pas; the build regenerates this unit.

  Fields      one per x:Name element, in XAML order
  Create      loads the page, fills the fields, wires the events
  Comments    name the XAML line each item comes from
}

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Pages;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TGuardPageBase = class(TWinUIXamlPage)
  protected
    Editor: TWinUITextBox;  // GuardPage.xaml(5) <TextBox>
  public
    constructor Create; override;
  end;
  {$M-}

implementation

const
  // GuardPage.xaml(1): the page; event attributes became the
  // wiring below, x:Class, x:DataType and RADWinUI attributes are removed
  PageXaml =
    '<Page xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' + sLineBreak +
    '  <TextBox x:Name="Editor" />' + sLineBreak +
    '</Page>';

constructor TGuardPageBase.Create;
begin
  inherited CreateFromXaml(PageXaml);
  // x:Name elements
  Editor := FindElement<TWinUITextBox>('Editor');
end;

end.
