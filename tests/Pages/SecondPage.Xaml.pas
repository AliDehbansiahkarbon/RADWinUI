unit SecondPage.Xaml;

{
  TSecondPageBase: base class of the page TSecondPage, generated from SecondPage.xaml
  by RADWinUI XamlCodeGen 0.4 (tools/XamlCodeGen).

  DO NOT EDIT. Change SecondPage.xaml or the published handlers of TSecondPage
  in SecondPage.pas; the build regenerates this unit.

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
  TSecondPageBase = class(TWinUIXamlPage)
  protected
    ParameterText: TWinUITextBlock;  // SecondPage.xaml(5) <TextBlock>
  public
    constructor Create; override;
  end;
  {$M-}

implementation

const
  // SecondPage.xaml(1): the page; event attributes became the
  // wiring below, x:Class, x:DataType and RADWinUI attributes are removed
  PageXaml =
    '<Page xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' + sLineBreak +
    '  <TextBlock x:Name="ParameterText" />' + sLineBreak +
    '</Page>';

constructor TSecondPageBase.Create;
begin
  inherited CreateFromXaml(PageXaml);
  // x:Name elements
  ParameterText := FindElement<TWinUITextBlock>('ParameterText');
end;

end.
