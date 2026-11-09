unit FirstPage.Xaml;

{
  TFirstPageBase: base class of the page TFirstPage, generated from FirstPage.xaml
  by RADWinUI XamlCodeGen 0.4 (tools/XamlCodeGen).

  DO NOT EDIT. Change FirstPage.xaml or the published handlers of TFirstPage
  in FirstPage.pas; the build regenerates this unit.

  Fields      one per x:Name element, in XAML order
  Create      loads the page, fills the fields, wires the events
  Comments    name the XAML line each item comes from
}

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  InfoCard,
  RADWinUI.Pages;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TFirstPageBase = class(TWinUIXamlPage)
  protected
    Caption: TWinUITextBlock;  // FirstPage.xaml(7) <TextBlock>
    CardOne: TInfoCard;        // FirstPage.xaml(8) <InfoCard>
    CardTwo: TInfoCard;        // FirstPage.xaml(9) <InfoCard>
  public
    constructor Create; override;
  end;
  {$M-}

implementation

const
  // FirstPage.xaml(1): the page; event attributes became the
  // wiring below, x:Class, x:DataType and RADWinUI attributes are removed
  PageXaml =
    '<Page xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:ns2="using:PagesTest" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' + sLineBreak +
    '  <StackPanel>' + sLineBreak +
    '    <TextBlock x:Name="Caption" Text="First" />' + sLineBreak +
    '    <ns2:InfoCard x:Name="CardOne" Title="One" />' + sLineBreak +
    '    <ns2:InfoCard x:Name="CardTwo" Title="Two" />' + sLineBreak +
    '  </StackPanel>' + sLineBreak +
    '</Page>';

constructor TFirstPageBase.Create;
begin
  inherited CreateFromXaml(PageXaml);
  // x:Name elements
  Caption := FindElement<TWinUITextBlock>('Caption');
  CardOne := FindElement<TInfoCard>('CardOne');
  CardTwo := FindElement<TInfoCard>('CardTwo');
  // Event wiring
  // FirstPage.xaml(8): Clicked="CardClicked"
  CardOne.OnClicked := TWinUIWinValueEventHandler(PublishedMethod('CardClicked'));
  // FirstPage.xaml(9): Clicked="CardClicked"
  CardTwo.OnClicked := TWinUIWinValueEventHandler(PublishedMethod('CardClicked'));
end;

end.
