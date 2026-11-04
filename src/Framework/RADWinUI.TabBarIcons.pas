unit RADWinUI.TabBarIcons;

{
  The tabs of the tab bars (RADWinUI.TabBars) as text, and the icons they
  can name. No WinUI here, so the IDE's Items editor uses it too.

  Items is one line, tabs separated by commas, each written Label:Icon:

    Home:Home, Search:Search, Likes:Heart, Profile:Contact

  The icon is a name from TabBarIcons (Home, Heart, Settings, ...), or a
  Segoe Fluent Icons code point such as E80F. Two code points E80F/EA8A
  give the outline and the filled glyph. Without ':' the label names the
  icon too: "Home, Search" shows the Home and Search icons.
}

interface

type
  TTabBarIcon = record
    Name: string;
    /// <summary>The outline glyph, as Segoe Fluent Icons draws it.</summary>
    Glyph: Char;
    /// <summary>The filled glyph of the selected tab, Glyph when the font has none.</summary>
    FilledGlyph: Char;
  end;

  TTabBarItemText = record
    Text: string;
    Icon: string;
  end;

const
  /// <summary>The tabs a new tab bar shows.</summary>
  DefaultTabBarItems = 'Home:Home, Search:Search, Likes:Heart, Profile:Contact';

/// <summary>The named icons, in the order the Items editor shows them.</summary>
function TabBarIcons: TArray<TTabBarIcon>;
/// <summary>
///   The glyphs of AIcon: a name or alias from TabBarIcons (any case), a code
///   point (E80F, U+E80F, &amp;#xE80F;) or two of them (E80F/EA8A). False, and the
///   Help glyph, when AIcon is none of these.
/// </summary>
function ResolveTabBarIcon(const AIcon: string; out AGlyph, AFilledGlyph: Char): Boolean;
/// <summary>The tabs of an Items text. Empty entries are skipped.</summary>
function ParseTabBarItems(const AText: string): TArray<TTabBarItemText>;
/// <summary>The Items text of AItems, as ParseTabBarItems reads it back.</summary>
function FormatTabBarItems(const AItems: TArray<TTabBarItemText>): string;

implementation

uses
  System.SysUtils;

type
  TIconEntry = record
    Names: string; // the name first, then aliases, separated by |
    Glyph, Filled: Word;
  end;

const
  HelpGlyph = $E897;
  Icons: array[0..49] of TIconEntry = (
    (Names: 'Home'; Glyph: $E80F; Filled: $EA8A),
    (Names: 'Search|Find'; Glyph: $E721; Filled: $E721),
    (Names: 'Heart|Likes|Love|Favorites'; Glyph: $EB51; Filled: $EB52),
    (Names: 'Contact|Profile|Person|User|Account|Me'; Glyph: $E77B; Filled: $EA8C),
    (Names: 'People|Friends|Group|Contacts'; Glyph: $E716; Filled: $E716),
    (Names: 'Star|Favorite|Rating'; Glyph: $E734; Filled: $E735),
    (Names: 'Settings|Setting|Gear|Options'; Glyph: $E713; Filled: $E713),
    (Names: 'Mail|Email|Inbox'; Glyph: $E715; Filled: $E715),
    (Names: 'Message|Messages'; Glyph: $E8BD; Filled: $E8BD),
    (Names: 'Chat|Comments'; Glyph: $E8F2; Filled: $E8F2),
    (Names: 'Bell|Notifications|Alerts|Ringer'; Glyph: $EA8F; Filled: $EA8F),
    (Names: 'Calendar|Events'; Glyph: $E787; Filled: $E787),
    (Names: 'Clock|Time'; Glyph: $E917; Filled: $E917),
    (Names: 'History|Recent'; Glyph: $E81C; Filled: $E81C),
    (Names: 'Cart|ShoppingCart|Basket'; Glyph: $E7BF; Filled: $E7BF),
    (Names: 'Shop|Store'; Glyph: $E719; Filled: $E719),
    (Names: 'Camera'; Glyph: $E722; Filled: $E722),
    (Names: 'Photo|Photos|Pictures|Gallery'; Glyph: $E91B; Filled: $E91B),
    (Names: 'Video|Videos|Movies'; Glyph: $E714; Filled: $E714),
    (Names: 'Music|Audio|Songs'; Glyph: $E8D6; Filled: $E8D6),
    (Names: 'Microphone|Mic|Record'; Glyph: $E720; Filled: $E720),
    (Names: 'Library|Books'; Glyph: $E8F1; Filled: $E8F1),
    (Names: 'Bookmark|Bookmarks|Saved'; Glyph: $E8A4; Filled: $E8A4),
    (Names: 'Globe|Explore|World|Web'; Glyph: $E774; Filled: $E774),
    (Names: 'Location|MapPin|Map|Places'; Glyph: $E707; Filled: $E707),
    (Names: 'Airplane|Flight|Travel|Trips'; Glyph: $E709; Filled: $E709),
    (Names: 'Add|Plus|New|Create'; Glyph: $E710; Filled: $E710),
    (Names: 'Edit|Write|Compose'; Glyph: $E70F; Filled: $E70F),
    (Names: 'Share'; Glyph: $E72D; Filled: $E72D),
    (Names: 'Folder|Files'; Glyph: $E8B7; Filled: $E8B7),
    (Names: 'Document|Documents|File|Notes'; Glyph: $E8A5; Filled: $E8A5),
    (Names: 'Phone|Call|Calls'; Glyph: $E717; Filled: $E717),
    (Names: 'Game|Games|Play'; Glyph: $E7FC; Filled: $E7FC),
    (Names: 'Apps|AllApps|Dashboard'; Glyph: $E71D; Filled: $E71D),
    (Names: 'Menu|Hamburger'; Glyph: $E700; Filled: $E700),
    (Names: 'Cloud'; Glyph: $E753; Filled: $E753),
    (Names: 'Download|Downloads'; Glyph: $E896; Filled: $E896),
    (Names: 'Upload'; Glyph: $E898; Filled: $E898),
    (Names: 'Like|ThumbsUp'; Glyph: $E8E1; Filled: $E8E1),
    (Names: 'Flag|Report'; Glyph: $E7C1; Filled: $E7C1),
    (Names: 'Info|About'; Glyph: $E946; Filled: $E946),
    (Names: 'Help|Support'; Glyph: $E897; Filled: $E897),
    (Names: 'Lock|Security|Privacy'; Glyph: $E72E; Filled: $E72E),
    (Names: 'Trash|Delete|Bin'; Glyph: $E74D; Filled: $E74D),
    (Names: 'Refresh|Reload'; Glyph: $E72C; Filled: $E72C),
    (Names: 'Sync'; Glyph: $E895; Filled: $E895),
    (Names: 'Filter'; Glyph: $E71C; Filled: $E71C),
    (Names: 'Emoji|Smile|Mood'; Glyph: $E76E; Filled: $E76E),
    (Names: 'Wifi|Network'; Glyph: $E701; Filled: $E701),
    (Names: 'More|Ellipsis'; Glyph: $E712; Filled: $E712));

function TabBarIcons: TArray<TTabBarIcon>;
var
  I: Integer;
begin
  SetLength(Result, Length(Icons));
  for I := 0 to High(Icons) do
  begin
    Result[I].Name := Icons[I].Names.Split(['|'])[0];
    Result[I].Glyph := Char(Icons[I].Glyph);
    Result[I].FilledGlyph := Char(Icons[I].Filled);
  end;
end;

function CodePoint(AText: string; out AGlyph: Char): Boolean;
var
  Value: Integer;
begin
  AText := Trim(AText);
  if AText.StartsWith('&#x', True) and AText.EndsWith(';') then
    AText := AText.Substring(3, AText.Length - 4)
  else if AText.StartsWith('U+', True) or AText.StartsWith('0x', True) then
    AText := AText.Substring(2);
  // Four or five hex digits: E80F, F0E2; a name like Add or Bed is no code point
  Result := ((AText.Length = 4) or (AText.Length = 5)) and TryStrToInt('$' + AText, Value) and (Value >= $E000) and
    (Value <= $F8FF);
  if Result then
    AGlyph := Char(Value);
end;

function ResolveTabBarIcon(const AIcon: string; out AGlyph, AFilledGlyph: Char): Boolean;
var
  Icon, Name: string;
  Parts: TArray<string>;
  I: Integer;
begin
  Icon := Trim(AIcon);
  for I := 0 to High(Icons) do
    for Name in Icons[I].Names.Split(['|']) do
      if SameText(Name, Icon) then
      begin
        AGlyph := Char(Icons[I].Glyph);
        AFilledGlyph := Char(Icons[I].Filled);
        Exit(True);
      end;
  Parts := Icon.Split(['/']);
  if (Length(Parts) >= 1) and (Length(Parts) <= 2) and CodePoint(Parts[0], AGlyph) then
  begin
    AFilledGlyph := AGlyph;
    Result := (Length(Parts) = 1) or CodePoint(Parts[1], AFilledGlyph);
    if Result then
      Exit;
  end;
  AGlyph := Char(HelpGlyph);
  AFilledGlyph := AGlyph;
  Result := False;
end;

function ParseTabBarItems(const AText: string): TArray<TTabBarItemText>;
var
  Part: string;
  Item: TTabBarItemText;
  Colon: Integer;
begin
  Result := nil;
  for Part in AText.Split([',']) do
  begin
    if Trim(Part) = '' then
      Continue;
    Colon := Part.IndexOf(':');
    if Colon < 0 then
    begin
      Item.Text := Trim(Part);
      Item.Icon := Item.Text;
    end
    else
    begin
      Item.Text := Trim(Part.Substring(0, Colon));
      Item.Icon := Trim(Part.Substring(Colon + 1));
    end;
    Result := Result + [Item];
  end;
end;

function FormatTabBarItems(const AItems: TArray<TTabBarItemText>): string;
var
  Item: TTabBarItemText;
  Text, Icon: string;
begin
  Result := '';
  for Item in AItems do
  begin
    // Commas and colons would split the text differently when read back
    Text := Trim(Item.Text.Replace(',', ' ').Replace(':', ' '));
    Icon := Trim(Item.Icon.Replace(',', ' ').Replace(':', ' '));
    if (Text = '') and (Icon = '') then
      Continue;
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + Text + ':' + Icon;
  end;
end;

end.
