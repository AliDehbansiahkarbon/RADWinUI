unit QueueWindow.Xaml;

{
  TQueueWindowBase: base class of TQueueWindow, generated from QueueWindow.xaml
  by RADWinUI XamlCodeGen 0.4 (tools/XamlCodeGen).

  DO NOT EDIT. Change QueueWindow.xaml or the published handlers of TQueueWindow
  in QueueWindow.pas; the build regenerates this unit.

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
  TQueueWindowBase = class(TWinUIWindow)
  protected
    UpNext: TWinUIListView;  // QueueWindow.xaml(17) <ListView>
  public
    constructor Create; override;
  end;
  {$M-}

implementation

const
  // QueueWindow.xaml(11): the content element; event attributes became the
  // wiring below, x:DataType and RADWinUI attributes are removed
  ContentXaml =
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Padding="16" RowSpacing="8">' + sLineBreak +
    '    <Grid.RowDefinitions>' + sLineBreak +
    '      <RowDefinition Height="Auto" />' + sLineBreak +
    '      <RowDefinition Height="*" />' + sLineBreak +
    '    </Grid.RowDefinitions>' + sLineBreak +
    '    <TextBlock Text="Up next" Style="{StaticResource SubtitleTextBlockStyle}" />' + sLineBreak +
    '    <ListView x:Name="UpNext" Grid.Row="1" SelectionMode="None">' + sLineBreak +
    '      ' + sLineBreak +
    '    </ListView>' + sLineBreak +
    '  </Grid>' + sLineBreak;

constructor TQueueWindowBase.Create;
begin
  inherited;
  // QueueWindow.xaml(1): <Window> attributes
  Title := 'Queue';
  Width := 320;
  Height := 440;
  MinWidth := 260;
  MinHeight := 300;
  Backdrop := TWinUIBackdrop.MicaAlt;
  CenterOnOwner;
  Minimizable := False;
  Maximizable := False;
  LoadContent(ContentXaml);
  // x:Name elements
  UpNext := FindElement<TWinUIListView>('UpNext');
end;

end.
