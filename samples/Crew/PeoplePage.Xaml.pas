unit PeoplePage.Xaml;

{
  TPeoplePageBase: base class of the page TPeoplePage, generated from PeoplePage.xaml
  by RADWinUI XamlCodeGen 0.4 (tools/XamlCodeGen).

  DO NOT EDIT. Change PeoplePage.xaml or the published handlers of TPeoplePage
  in PeoplePage.pas; the build regenerates this unit.

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
  TPeoplePageBase = class(TWinUIXamlPage)
  protected
    PageTitle: TWinUITextBlock;  // PeoplePage.xaml(14) <TextBlock>
    SearchBox: TWinUITextBox;    // PeoplePage.xaml(16) <TextBox>
    CountText: TWinUITextBlock;  // PeoplePage.xaml(18) <TextBlock>
    PeopleList: TWinUIListView;  // PeoplePage.xaml(20) <ListView>
  public
    constructor Create; override;
  end;
  {$M-}

implementation

const
  // PeoplePage.xaml(1): the page; event attributes became the
  // wiring below, x:Class, x:DataType and RADWinUI attributes are removed
  PageXaml =
    '<Page xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' + sLineBreak +
    '  <Grid RowSpacing="12" MaxWidth="720" HorizontalAlignment="Left">' + sLineBreak +
    '    <Grid.RowDefinitions>' + sLineBreak +
    '      <RowDefinition Height="Auto" />' + sLineBreak +
    '      <RowDefinition Height="Auto" />' + sLineBreak +
    '      <RowDefinition Height="*" />' + sLineBreak +
    '    </Grid.RowDefinitions>' + sLineBreak +
    '    <TextBlock x:Name="PageTitle" Text="People" Style="{StaticResource TitleLargeTextBlockStyle}" />' + sLineBreak +
    '    <StackPanel Grid.Row="1" Spacing="4">' + sLineBreak +
    '      <TextBox x:Name="SearchBox" PlaceholderText="Search by name or role" Width="360" HorizontalAlignment="Left" AutomationProperties.Name="Search people" />' + sLineBreak +
    '      <TextBlock x:Name="CountText" FontSize="12" Opacity="0.7" />' + sLineBreak +
    '    </StackPanel>' + sLineBreak +
    '    <ListView x:Name="PeopleList" Grid.Row="2" IsItemClickEnabled="True" SelectionMode="None">' + sLineBreak +
    '      ' + sLineBreak +
    '      <ListView.ItemTemplate>' + sLineBreak +
    '        <DataTemplate>' + sLineBreak +
    '          <StackPanel Orientation="Horizontal" Spacing="12" Padding="0,8">' + sLineBreak +
    '            <PersonPicture DisplayName="{Binding Name}" Width="36" Height="36" />' + sLineBreak +
    '            <StackPanel VerticalAlignment="Center">' + sLineBreak +
    '              <TextBlock Text="{Binding Name}" FontWeight="SemiBold" />' + sLineBreak +
    '              <TextBlock Text="{Binding Role}" FontSize="12" Opacity="0.7" />' + sLineBreak +
    '            </StackPanel>' + sLineBreak +
    '          </StackPanel>' + sLineBreak +
    '        </DataTemplate>' + sLineBreak +
    '      </ListView.ItemTemplate>' + sLineBreak +
    '    </ListView>' + sLineBreak +
    '  </Grid>' + sLineBreak +
    '</Page>';

constructor TPeoplePageBase.Create;
begin
  inherited CreateFromXaml(PageXaml);
  // x:Name elements
  PageTitle := FindElement<TWinUITextBlock>('PageTitle');
  SearchBox := FindElement<TWinUITextBox>('SearchBox');
  CountText := FindElement<TWinUITextBlock>('CountText');
  PeopleList := FindElement<TWinUIListView>('PeopleList');
  // Event wiring
  // PeoplePage.xaml(16): TextChanged="SearchChanged"
  SearchBox.OnTextChanged := TWinUITextChangedEventHandler(PublishedMethod('SearchChanged'));
  // PeoplePage.xaml(20): ItemClick="PersonClick"
  PeopleList.OnItemClick := TWinUIItemClickEventHandler(PublishedMethod('PersonClick'));
end;

end.
