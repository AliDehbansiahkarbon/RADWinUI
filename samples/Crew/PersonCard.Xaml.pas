unit PersonCard.Xaml;

{
  TPersonCardBase: base class of the user control TPersonCard, generated from PersonCard.xaml
  by RADWinUI XamlCodeGen 0.4 (tools/XamlCodeGen).

  DO NOT EDIT. Change PersonCard.xaml or the published handlers of TPersonCard
  in PersonCard.pas; the build regenerates this unit.

  Fields      one per x:Name element, in XAML order
  Initialize  loads the content, fills the fields, wires the events
  Register    makes TPersonCard the XAML element <local:PersonCard>
  Comments    name the XAML line each item comes from
}

interface

uses
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.CustomControls;

type
  // Published handlers of the descendant are found by name (MethodAddress)
  {$M+}
  TPersonCardBase = class(TWinUIXamlUserControl)
  protected
    CardButton: TWinUIButton;      // PersonCard.xaml(9) <Button>
    Picture: TWinUIPersonPicture;  // PersonCard.xaml(19) <PersonPicture>
    NameText: TWinUITextBlock;     // PersonCard.xaml(21) <TextBlock>
    RoleText: TWinUITextBlock;     // PersonCard.xaml(22) <TextBlock>
    procedure Initialize; override;
  end;
  {$M-}

implementation

uses
  PersonCard;  // TPersonCard, registered below

const
  // PersonCard.xaml(9): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="CardButton" HorizontalAlignment="Stretch" HorizontalContentAlig' +
    'nment="Left" Padding="16,14" CornerRadius="8" BorderThickness="1" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}">' + sLineBreak +
    '    <Grid ColumnSpacing="14">' + sLineBreak +
    '      <Grid.ColumnDefinitions>' + sLineBreak +
    '        <ColumnDefinition Width="Auto" />' + sLineBreak +
    '        <ColumnDefinition Width="*" />' + sLineBreak +
    '        <ColumnDefinition Width="Auto" />' + sLineBreak +
    '      </Grid.ColumnDefinitions>' + sLineBreak +
    '      <PersonPicture x:Name="Picture" Width="44" Height="44" />' + sLineBreak +
    '      <StackPanel Grid.Column="1" VerticalAlignment="Center">' + sLineBreak +
    '        <TextBlock x:Name="NameText" FontWeight="SemiBold" />' + sLineBreak +
    '        <TextBlock x:Name="RoleText" FontSize="12" Opacity="0.7" />' + sLineBreak +
    '      </StackPanel>' + sLineBreak +
    '      <FontIcon Grid.Column="2" Glyph="" FontSize="12" Opacity="0.6" />' + sLineBreak +
    '    </Grid>' + sLineBreak +
    '  </Button>' + sLineBreak;

procedure TPersonCardBase.Initialize;
begin
  inherited;
  LoadContentXaml(ContentXaml);
  // x:Name elements
  CardButton := FindElement<TWinUIButton>('CardButton');
  Picture := FindElement<TWinUIPersonPicture>('Picture');
  NameText := FindElement<TWinUITextBlock>('NameText');
  RoleText := FindElement<TWinUITextBlock>('RoleText');
  // Event wiring
  // PersonCard.xaml(9): Click="CardClick"
  CardButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('CardClick'));
end;

initialization
  TWinUICustomControls.Register(TPersonCard, 'PersonCard', 'User controls');
end.
