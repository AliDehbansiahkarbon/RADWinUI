unit CachedPage.Xaml;

{
  TCachedPageBase: base class of the page TCachedPage, generated from CachedPage.xaml
  by RADWinUI XamlCodeGen 0.4 (tools/XamlCodeGen).

  DO NOT EDIT. Change CachedPage.xaml or the published handlers of TCachedPage
  in CachedPage.pas; the build regenerates this unit.

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
  TCachedPageBase = class(TWinUIXamlPage)
  protected
    CountText: TWinUITextBlock;  // CachedPage.xaml(5) <TextBlock>
  public
    constructor Create; override;
  end;
  {$M-}

implementation

const
  // CachedPage.xaml(1): the page; event attributes became the
  // wiring below, x:Class, x:DataType and RADWinUI attributes are removed
  PageXaml =
    '<Page xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' + sLineBreak +
    '  <TextBlock x:Name="CountText" />' + sLineBreak +
    '</Page>';

constructor TCachedPageBase.Create;
begin
  inherited CreateFromXaml(PageXaml);
  // x:Name elements
  CountText := FindElement<TWinUITextBlock>('CountText');
end;

end.
