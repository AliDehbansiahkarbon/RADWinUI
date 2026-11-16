unit EmberSettings;

// What Ember remembers between starts: the language and the theme

interface

const
  // The choices of the Settings page, in their order
  Languages: array[0..3] of string = ('', 'en-US', 'de-DE', 'fa-IR');
  LanguageNames: array[0..3] of string = ('', 'English', 'Deutsch', #$0641#$0627#$0631#$0633#$06CC);

function SavedLanguage: string;
procedure SaveLanguage(const ALanguage: string);
/// <summary>0 follows Windows, 1 is light, 2 is dark.</summary>
function SavedTheme: Integer;
procedure SaveTheme(ATheme: Integer);
/// <summary>A text of Strings\[language]\Resources.resw, ADefault when it is missing.</summary>
function S(const AKey, ADefault: string): string;
/// <summary>Day and month names of the app's language for FormatDateTime, from Resources.resw.</summary>
procedure LocalizeFormats;

var
  /// <summary>Set when the user asked to start again in another language.</summary>
  RestartEmber: Boolean;

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  System.Win.Registry,
  RADWinUI.Resources;

const
  SettingsKey = 'Software\RADWinUI\Ember';

function ReadValue(const AName: string): string;
var
  Registry: TRegistry;
begin
  Result := '';
  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if Registry.OpenKeyReadOnly(SettingsKey) and Registry.ValueExists(AName) then
      Result := Registry.ReadString(AName);
  finally
    Registry.Free;
  end;
end;

procedure WriteValue(const AName, AValue: string);
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if Registry.OpenKey(SettingsKey, True) then
      Registry.WriteString(AName, AValue);
  finally
    Registry.Free;
  end;
end;

function SavedLanguage: string;
begin
  Result := ReadValue('Language');
end;

procedure SaveLanguage(const ALanguage: string);
begin
  WriteValue('Language', ALanguage);
end;

function SavedTheme: Integer;
begin
  Result := Pos(ReadValue('Theme'), 'LD');
end;

procedure SaveTheme(ATheme: Integer);
const
  Codes: array[0..2] of string = ('', 'L', 'D');
begin
  WriteValue('Theme', Codes[ATheme]);
end;

function S(const AKey, ADefault: string): string;
begin
  Result := TWinUIResources.GetString(AKey, ADefault);
end;

// Each key holds the names separated by commas, Sunday or January first.
// A language without the keys keeps the names Windows gives Delphi.
procedure LocalizeFormats;

  procedure Fill(const AKey: string; var ANames: array of string);
  var
    Names: TArray<string>;
    I: Integer;
  begin
    Names := S(AKey, '').Split([',']);
    if Length(Names) = Length(ANames) then
      for I := 0 to High(Names) do
        ANames[I] := Trim(Names[I]);
  end;

begin
  Fill('LongDayNames', FormatSettings.LongDayNames);
  Fill('ShortDayNames', FormatSettings.ShortDayNames);
  Fill('LongMonthNames', FormatSettings.LongMonthNames);
end;

end.
