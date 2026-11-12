unit RADWinUI.Designer.Settings;

{
  RADWinUI's IDE settings, in HKEY_CURRENT_USER under the IDE's own key
  (Software\Embarcadero\BDS\<version>\RADWinUI), where the wizard keeps its values.
  Tools > Options > Third Party > RADWinUI edits them and saves each change at once.
  IDE-free: the caller passes the key.
}

interface

type
  TRADWinUISettings = record
    /// <summary>AI suggestions while typing in .xaml files (ghost text, Tab inserts).</summary>
    AISuggestions: Boolean;
    /// <summary>The pause after the last key before a suggestion is asked for, in ms.</summary>
    SuggestionDelay: Integer;
    /// <summary>The offline XAML code completion, when it comes: stored now, read by CodeCompletionEnabled.</summary>
    CodeCompletion: Boolean;
    /// <summary>Ctrl+Alt+Space with lines selected puts them in the prompt bar.</summary>
    PromptWithSelection: Boolean;
    const
      DefaultDelay = 250;
      MinDelay = 100;
      MaxDelay = 5000;
    class function Defaults: TRADWinUISettings; static;
    /// <summary>The settings under HKEY_CURRENT_USER\AKey; a missing or invalid value is its default.</summary>
    class function Load(const AKey: string): TRADWinUISettings; static;
    /// <summary>Writes every value to HKEY_CURRENT_USER\AKey.</summary>
    procedure Save(const AKey: string);
    /// <summary>Whether the offline XAML code completion is on: the one place that feature reads.</summary>
    class function CodeCompletionEnabled(const AKey: string): Boolean; static;
  end;

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  System.Win.Registry;

const
  AISuggestionsValue = 'XamlAISuggestions';
  DelayValue = 'XamlAISuggestionDelay';
  CodeCompletionValue = 'XamlCodeCompletion';
  PromptWithSelectionValue = 'XamlPromptWithSelection';
  VersionValue = 'SettingsVersion';
  Version = 2;
  OldDefaultDelay = 500; // version 1 saved the default of its time

class function TRADWinUISettings.Defaults: TRADWinUISettings;
begin
  Result.AISuggestions := True;
  Result.SuggestionDelay := DefaultDelay;
  Result.CodeCompletion := True;
  Result.PromptWithSelection := True;
end;

class function TRADWinUISettings.Load(const AKey: string): TRADWinUISettings;
var
  Registry: TRegistry;

  function ReadInt(const AName: string; var AValue: Integer): Boolean;
  begin
    Result := Registry.ValueExists(AName) and (Registry.GetDataType(AName) = rdInteger);
    if Result then
      AValue := Registry.ReadInteger(AName);
  end;

var
  Value, Saved: Integer;
begin
  Result := Defaults;
  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if not Registry.OpenKeyReadOnly(AKey) then
      Exit;
    Saved := 1;
    ReadInt(VersionValue, Saved);
    Value := 0;
    if ReadInt(AISuggestionsValue, Value) then
      Result.AISuggestions := Value <> 0;
    if ReadInt(CodeCompletionValue, Value) then
      Result.CodeCompletion := Value <> 0;
    if ReadInt(PromptWithSelectionValue, Value) then
      Result.PromptWithSelection := Value <> 0;
    if ReadInt(DelayValue, Value) and (Value >= MinDelay) and (Value <= MaxDelay) and
      not ((Saved < 2) and (Value = OldDefaultDelay)) then
      Result.SuggestionDelay := Value;
  finally
    Registry.Free;
  end;
end;

procedure TRADWinUISettings.Save(const AKey: string);
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if not Registry.OpenKey(AKey, True) then
      raise Exception.Create('Cannot write the RADWinUI settings to HKEY_CURRENT_USER\' + AKey);
    Registry.WriteInteger(AISuggestionsValue, Ord(AISuggestions));
    Registry.WriteInteger(DelayValue, SuggestionDelay);
    Registry.WriteInteger(CodeCompletionValue, Ord(CodeCompletion));
    Registry.WriteInteger(PromptWithSelectionValue, Ord(PromptWithSelection));
    Registry.WriteInteger(VersionValue, Version);
  finally
    Registry.Free;
  end;
end;

class function TRADWinUISettings.CodeCompletionEnabled(const AKey: string): Boolean;
begin
  Result := Load(AKey).CodeCompletion;
end;

end.
