unit MiniPlayerWindow.Xaml;

{
  TMiniPlayerWindowBase: base class of TMiniPlayerWindow, generated from MiniPlayerWindow.xaml
  by RADWinUI XamlCodeGen 0.4 (tools/XamlCodeGen).

  DO NOT EDIT. Change MiniPlayerWindow.xaml or the published handlers of TMiniPlayerWindow
  in MiniPlayerWindow.pas; the build regenerates this unit.

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
  TMiniPlayerWindowBase = class(TWinUIWindow)
  protected
    StationName: TWinUITextBlock;  // MiniPlayerWindow.xaml(16) <TextBlock>
    GenreText: TWinUITextBlock;    // MiniPlayerWindow.xaml(18) <TextBlock>
    PlayButton: TWinUIButton;      // MiniPlayerWindow.xaml(20) <Button>
  public
    constructor Create; override;
  end;
  {$M-}

implementation

const
  // MiniPlayerWindow.xaml(10): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Padding="16" RowSpacing="8">' + sLineBreak +
    '    <Grid.RowDefinitions>' + sLineBreak +
    '      <RowDefinition Height="*" />' + sLineBreak +
    '      <RowDefinition Height="Auto" />' + sLineBreak +
    '    </Grid.RowDefinitions>' + sLineBreak +
    '    <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '      <TextBlock x:Name="StationName" Style="{StaticResource SubtitleTextBlockStyle}" TextTrimming="CharacterEllipsis" />' + sLineBreak +
    '      <TextBlock x:Name="GenreText" Opacity="0.7" />' + sLineBreak +
    '    </StackPanel>' + sLineBreak +
    '    <Button x:Name="PlayButton" Grid.Row="1" Content="Play" HorizontalAlignment="Stretch" />' + sLineBreak +
    '  </Grid>' + sLineBreak;

constructor TMiniPlayerWindowBase.Create;
begin
  inherited;
  // MiniPlayerWindow.xaml(1): <Window> attributes
  Title := 'Tempo mini player';
  Width := 320;
  Height := 180;
  Backdrop := TWinUIBackdrop.Acrylic;
  WindowState := TWinUIWindowState.CompactOverlay;
  LoadContent(ContentXaml);
  // x:Name elements
  StationName := FindElement<TWinUITextBlock>('StationName');
  GenreText := FindElement<TWinUITextBlock>('GenreText');
  PlayButton := FindElement<TWinUIButton>('PlayButton');
  // Event wiring
  // MiniPlayerWindow.xaml(20): Click="PlayClick"
  PlayButton.Click.Add(NotifyProc<TWinUIRoutedEventArgs>('PlayClick'));
end;

end.
