unit RADWinUI.Designer.Palette;

{
  The controls RADWinUI offers to drop, by category, in the order shown.
  One list feeds the IDE Tool Palette and the preview's toolbox
  column, so both match. Like VCL's Standard, Additional, ... categories: the
  everyday controls first, layout panels, then by purpose. Part and template
  types of the metadata (CalendarViewDayItem, ColorSpectrum, *Presenter,
  *Item, Thumb, ...) are left out, they still work when written in XAML.
  Names are the XAML element names the palette inserts (Button, not
  TWinUIButton). No ToolsAPI, VCL or WinUI here.
}

interface

type
  TPaletteEntry = record
    Category: string; // shown as 'RADWinUI ' + Category
    Name: string;     // the XAML element
  end;

/// <summary>Every curated control, category by category, in palette order.</summary>
function PaletteEntries: TArray<TPaletteEntry>;
/// <summary>The categories in palette order.</summary>
function PaletteCategories: TArray<string>;
/// <summary>The category of AName, or '' when it is not on the palette.</summary>
function PaletteCategoryOf(const AName: string): string;

implementation

uses
  System.SysUtils;

const
  Categories: array[0..8] of string = ('Standard', 'Layout', 'Input', 'Date and Time', 'Collections',
    'Navigation', 'Text and Media', 'Status', 'Shapes');
  // One string per category above, same order
  Members: array[0..8] of string = (
    'Button TextBlock TextBox CheckBox RadioButton ComboBox ListBox ToggleSwitch Slider ProgressBar Image ' +
      'HyperlinkButton',
    'Grid StackPanel Canvas Border ScrollViewer RelativePanel Viewbox SplitView Expander',
    'PasswordBox NumberBox AutoSuggestBox RichEditBox RadioButtons ToggleButton RepeatButton DropDownButton ' +
      'SplitButton ToggleSplitButton RatingControl ColorPicker',
    'CalendarDatePicker DatePicker TimePicker CalendarView',
    'ListView GridView TreeView FlipView ItemsView PipsPager',
    'NavigationView TabView BreadcrumbBar SelectorBar CommandBar MenuBar AppBarButton AppBarToggleButton ' +
      'AppBarSeparator Pivot',
    'RichTextBlock PersonPicture FontIcon SymbolIcon MediaPlayerElement WebView2 AnimatedVisualPlayer',
    'ProgressRing InfoBar InfoBadge',
    'Rectangle Ellipse Line Polygon Polyline Path');

function PaletteEntries: TArray<TPaletteEntry>;
var
  I: Integer;
  Name: string;
  Entry: TPaletteEntry;
begin
  Result := nil;
  for I := 0 to High(Categories) do
    for Name in Members[I].Split([' ']) do
    begin
      Entry.Category := Categories[I];
      Entry.Name := Name;
      Result := Result + [Entry];
    end;
end;

function PaletteCategories: TArray<string>;
var
  I: Integer;
begin
  SetLength(Result, Length(Categories));
  for I := 0 to High(Categories) do
    Result[I] := Categories[I];
end;

function PaletteCategoryOf(const AName: string): string;
var
  Entry: TPaletteEntry;
begin
  for Entry in PaletteEntries do
    if SameText(Entry.Name, AName) then
      Exit(Entry.Category);
  Result := '';
end;

end.
