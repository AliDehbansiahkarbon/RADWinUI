unit RADWinUI.Resources;

{
  Strings of an app in several languages, the WinUI way: Strings\<language>\Resources.resw
  in the project folder, built into resources.pri next to the exe (scripts\Make-Pri.ps1, run
  by the post-build step). XAML applies x:Uid from it by itself, code reads it here.
}

interface

type
  /// <summary>
  ///   The app's strings in the current language (TWinUIApp.Language), from the
  ///   Resources.resw files built into resources.pri.
  /// </summary>
  TWinUIResources = class
  strict private
    class var FLoaded: Boolean;
    class var FLoader: IInterface;
  public
    /// <summary>
    ///   The string AKey ("Greeting"; "Title/Text" for the Title.Text key an
    ///   x:Uid uses) in the current language, else in the default one. ADefault
    ///   when the app has no resources.pri or no such key.
    /// </summary>
    class function GetString(const AKey: string; const ADefault: string = ''): string; static;
    /// <summary>True when the app's resources have AKey.</summary>
    class function Has(const AKey: string): Boolean; static;
    /// <summary>Forgets the strings read so far: TWinUIApp.Language calls it.</summary>
    class procedure Reset; static;
    /// <summary>True when ALanguage ('fa-IR', 'ar', 'he') is written right to left.</summary>
    class function IsRightToLeft(const ALanguage: string): Boolean; static;
  end;

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  RADWinUI.Interop.Core,
  RADWinUI.Abi;

const
  LOCALE_IREADINGLAYOUT = $70;

class function TWinUIResources.GetString(const AKey, ADefault: string): string;
begin
  if not FLoaded then
  begin
    FLoaded := True;
    try
      // ResourceLoader reads resources.pri next to the exe, an app without one has no strings
      if FileExists(ExtractFilePath(ParamStr(0)) + 'resources.pri') then
        FLoader := ResourceLoader.New;
    except
      FLoader := nil;
    end;
  end;
  Result := '';
  if FLoader <> nil then
    try
      Result := TakeHString((FLoader as IResourceLoader).GetString(WinStr(AKey)));
    except
      Result := ''; // no such key
    end;
  if Result = '' then
    Result := ADefault;
end;

class function TWinUIResources.Has(const AKey: string): Boolean;
begin
  Result := GetString(AKey) <> '';
end;

class procedure TWinUIResources.Reset;
begin
  FLoader := nil;
  FLoaded := False;
end;

class function TWinUIResources.IsRightToLeft(const ALanguage: string): Boolean;
var
  Layout: array[0..7] of Char;
begin
  // 1 is right to left in Windows' reading layout of the language
  Result := (ALanguage <> '') and (GetLocaleInfoEx(PChar(ALanguage), LOCALE_IREADINGLAYOUT, Layout,
    Length(Layout)) > 0) and (Layout[0] = '1');
end;

end.
