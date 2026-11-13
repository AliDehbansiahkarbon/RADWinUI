unit RADWinUI.Designer.Settings;

{
  RADWinUI's IDE settings, in HKEY_CURRENT_USER under the IDE's own key
  (Software\Embarcadero\BDS\<version>\RADWinUI), where the wizard keeps its values.
  Tools > Options > Third Party > RADWinUI edits them and saves each change at once.
  The vision API keys are stored encrypted with DPAPI, readable only by the same Windows user.
  IDE-free: the caller passes the key.
}

interface

uses
  RADWinUI.Designer.Vision;

type
  /// <summary>When the IDE sends an edited .xaml file to the app it is running (Debug builds).</summary>
  TRADWinUIHotReload = (hrOff, hrOnSave, hrWhileTyping);

  TRADWinUISettings = record
    /// <summary>AI suggestions while typing in .xaml files (ghost text, Tab inserts).</summary>
    AISuggestions: Boolean;
    /// <summary>The pause after the last key before a suggestion is asked for, in ms.</summary>
    SuggestionDelay: Integer;
    /// <summary>The offline XAML code completion, when it comes: stored now, read by CodeCompletionEnabled.</summary>
    CodeCompletion: Boolean;
    /// <summary>Ctrl+Alt+Space with lines selected puts them in the prompt bar.</summary>
    PromptWithSelection: Boolean;
    /// <summary>Hot reload: off, when a .xaml file is saved, or while typing (the default).</summary>
    HotReload: TRADWinUIHotReload;
    /// <summary>Where Create XAML with AI sends a prompt with an image (none by default: nothing is sent).</summary>
    VisionProvider: TVisionProvider;
    /// <summary>The vision model, '' for the provider's default.</summary>
    VisionModel: string;
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
    /// <summary>The API key of AProvider, decrypted ('' when none). Kept apart from the record so it
    /// is read only where a request is sent.</summary>
    class function VisionKey(const AKey: string; AProvider: TVisionProvider): string; static;
    /// <summary>Stores the API key of AProvider encrypted for the current Windows user; '' removes it.</summary>
    class procedure SetVisionKey(const AKey: string; AProvider: TVisionProvider; const AValue: string); static;
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
  HotReloadValue = 'XamlHotReload';
  VisionProviderValue = 'VisionProvider';
  VisionModelValue = 'VisionModel';
  VisionKeyValue = 'VisionKey'; // + the provider name, binary DPAPI data
  VersionValue = 'SettingsVersion';
  Version = 2;
  OldDefaultDelay = 500; // version 1 saved the default of its time

class function TRADWinUISettings.Defaults: TRADWinUISettings;
begin
  Result.AISuggestions := True;
  Result.SuggestionDelay := DefaultDelay;
  Result.CodeCompletion := True;
  Result.PromptWithSelection := True;
  Result.HotReload := hrWhileTyping;
  Result.VisionProvider := vpNone;
  Result.VisionModel := '';
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
    if ReadInt(HotReloadValue, Value) and (Value >= Ord(Low(TRADWinUIHotReload))) and
      (Value <= Ord(High(TRADWinUIHotReload))) then
      Result.HotReload := TRADWinUIHotReload(Value);
    if ReadInt(VisionProviderValue, Value) and (Value >= Ord(Low(TVisionProvider))) and
      (Value <= Ord(High(TVisionProvider))) then
      Result.VisionProvider := TVisionProvider(Value);
    if Registry.ValueExists(VisionModelValue) and (Registry.GetDataType(VisionModelValue) = rdString) then
      Result.VisionModel := Registry.ReadString(VisionModelValue);
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
    Registry.WriteInteger(HotReloadValue, Ord(HotReload));
    Registry.WriteInteger(VisionProviderValue, Ord(VisionProvider));
    Registry.WriteString(VisionModelValue, VisionModel);
    Registry.WriteInteger(VersionValue, Version);
  finally
    Registry.Free;
  end;
end;

class function TRADWinUISettings.CodeCompletionEnabled(const AKey: string): Boolean;
begin
  Result := Load(AKey).CodeCompletion;
end;

function VisionKeyName(AProvider: TVisionProvider): string;
const
  Names: array[TVisionProvider] of string = ('None', 'OpenAI', 'Anthropic', 'Gemini', 'Ollama');
begin
  Result := VisionKeyValue + Names[AProvider];
end;

class function TRADWinUISettings.VisionKey(const AKey: string; AProvider: TVisionProvider): string;
var
  Registry: TRegistry;
  Data: TBytes;
  Name: string;
begin
  Result := '';
  Name := VisionKeyName(AProvider);
  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if not Registry.OpenKeyReadOnly(AKey) or not Registry.ValueExists(Name) or
      (Registry.GetDataType(Name) <> rdBinary) then
      Exit;
    SetLength(Data, Registry.GetDataSize(Name));
    if Length(Data) > 0 then
      Registry.ReadBinaryData(Name, Data[0], Length(Data));
    Result := UnprotectText(Data);
  finally
    Registry.Free;
  end;
end;

class procedure TRADWinUISettings.SetVisionKey(const AKey: string; AProvider: TVisionProvider; const AValue: string);
var
  Registry: TRegistry;
  Data: TBytes;
begin
  Data := ProtectText(AValue.Trim);
  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if not Registry.OpenKey(AKey, True) then
      raise Exception.Create('Cannot write the RADWinUI settings to HKEY_CURRENT_USER' + AKey);
    if Length(Data) = 0 then
      Registry.DeleteValue(VisionKeyName(AProvider))
    else
      Registry.WriteBinaryData(VisionKeyName(AProvider), Data[0], Length(Data));
  finally
    Registry.Free;
  end;
end;

end.
