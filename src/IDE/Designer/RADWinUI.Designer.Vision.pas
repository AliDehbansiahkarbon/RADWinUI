unit RADWinUI.Designer.Vision;

{
  Create XAML with AI from an image. The IDE's AI engine (ToolsAPI.AI) takes text only, so
  a prompt with an image goes straight to a vision model the user chose: OpenAI, Anthropic,
  Google Gemini, or Ollama on this PC. Here: the request and answer of each provider, the
  API key kept with Windows DPAPI for the current user, and the image made small enough to
  send. IDE-free: the caller runs SendVisionRequest on a worker thread.
}

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.Net.URLClient;

type
  TVisionProvider = (vpNone, vpOpenAI, vpAnthropic, vpGemini, vpOllama);

  TVisionRequest = record
    Url: string;
    Headers: TNetHeaders;
    Body: string;
  end;

const
  VisionProviderNames: array[TVisionProvider] of string = ('None', 'OpenAI', 'Anthropic', 'Google Gemini',
    'Ollama (on this PC)');
  VisionDefaultModels: array[TVisionProvider] of string = ('', 'gpt-5', 'claude-opus-5-5', 'gemini-2.5-pro',
    'gemma3');
  OllamaUrl = 'http://localhost:11434';
  /// <summary>The long side of a sent image, in pixels: what Anthropic reads best, well within the others.</summary>
  VisionMaxSide = 1568;
  /// <summary>A PNG larger than this is sent as JPEG.</summary>
  VisionMaxBytes = 1024 * 1024;
  /// <summary>Put before the Create XAML with AI prompt when an image goes along.</summary>
  VisionPromptNote =
    'The user attached an image: a screenshot, a mock-up or a sketch of a UI, possibly the current design ' +
    'with marks drawn over it (arrows, circles, notes). Write the XAML so the UI looks like the image and does ' +
    'what the user asks; where the image and the words differ, follow the words.';

/// <summary>The model to use: AModel, or the provider's default when it is empty.</summary>
function VisionModel(AProvider: TVisionProvider; const AModel: string): string;

/// <summary>The HTTP request that sends APrompt and the image (AMimeType: image/png or image/jpeg).</summary>
function BuildVisionRequest(AProvider: TVisionProvider; const AModel, AKey, APrompt: string;
  const AImage: TBytes; const AMimeType: string): TVisionRequest;

/// <summary>The answer text from a provider's response (HTTP AStatus, JSON AResponse), or AError.</summary>
function ParseVisionAnswer(AProvider: TVisionProvider; AStatus: Integer; const AResponse: string;
  out AText, AError: string): Boolean;

/// <summary>Sends the request and waits for the answer: call it on a worker thread.</summary>
function SendVisionRequest(AProvider: TVisionProvider; const AModel, AKey, APrompt: string;
  const AImage: TBytes; const AMimeType: string; out AText, AError: string): Boolean;

/// <summary>AText encrypted with DPAPI for the current Windows user.</summary>
function ProtectText(const AText: string): TBytes;
/// <summary>The text ProtectText encrypted, '' when it cannot be read (another user, damaged).</summary>
function UnprotectText(const AData: TBytes): string;

/// <summary>An image file (PNG, JPEG, BMP, GIF) ready to send, at most VisionMaxSide; nil when unreadable.</summary>
function VisionImageFromFile(const AFile: string; out AMimeType: string): TBytes;
/// <summary>A bitmap (from the clipboard) ready to send; nil when unreadable.</summary>
function VisionImageFromBitmap(ABitmap: HBITMAP; out AMimeType: string): TBytes;

implementation

uses
  System.Math,
  System.StrUtils,
  System.JSON,
  System.NetEncoding,
  System.Net.HttpClient,
  Winapi.ActiveX,
  Winapi.GDIPAPI,
  Winapi.GDIPOBJ,
  Winapi.GDIPUTIL;

function VisionModel(AProvider: TVisionProvider; const AModel: string): string;
begin
  Result := AModel.Trim;
  if Result = '' then
    Result := VisionDefaultModels[AProvider];
end;

function Base64(const AData: TBytes): string;
var
  Encoding: TBase64Encoding;
begin
  Encoding := TBase64Encoding.Create(0); // no line breaks
  try
    Result := Encoding.EncodeBytesToString(AData);
  finally
    Encoding.Free;
  end;
end;

function Header(const AName, AValue: string): TNameValuePair;
begin
  Result := TNameValuePair.Create(AName, AValue);
end;

function BuildVisionRequest(AProvider: TVisionProvider; const AModel, AKey, APrompt: string;
  const AImage: TBytes; const AMimeType: string): TVisionRequest;
var
  Body, Message, Part, Source: TJSONObject;
  Content: TJSONArray;
  Model, Data: string;
begin
  Model := VisionModel(AProvider, AModel);
  Data := Base64(AImage);
  Result.Headers := [Header('Content-Type', 'application/json')];
  Body := TJSONObject.Create;
  try
    case AProvider of
      vpOpenAI:
        begin
          Result.Url := 'https://api.openai.com/v1/chat/completions';
          Result.Headers := Result.Headers + [Header('Authorization', 'Bearer ' + AKey)];
          Content := TJSONArray.Create;
          Content.AddElement(TJSONObject.Create.AddPair('type', 'text').AddPair('text', APrompt));
          Content.AddElement(TJSONObject.Create.AddPair('type', 'image_url').AddPair('image_url',
            TJSONObject.Create.AddPair('url', 'data:' + AMimeType + ';base64,' + Data)));
          Message := TJSONObject.Create.AddPair('role', 'user').AddPair('content', Content);
          Body.AddPair('model', Model).AddPair('messages', TJSONArray.Create(Message));
          // Reasoning models think at medium by default, minutes for one screen: low writes the same XAML faster
          if Model.StartsWith('gpt-5') or ((Length(Model) > 1) and (Model[1] = 'o') and
            CharInSet(Model[2], ['1'..'9'])) then
            Body.AddPair('reasoning_effort', 'low');
        end;
      vpAnthropic:
        begin
          Result.Url := 'https://api.anthropic.com/v1/messages';
          Result.Headers := Result.Headers + [Header('x-api-key', AKey), Header('anthropic-version', '2026-10-21')];
          Source := TJSONObject.Create.AddPair('type', 'base64').AddPair('media_type', AMimeType).AddPair('data', Data);
          Content := TJSONArray.Create;
          Content.AddElement(TJSONObject.Create.AddPair('type', 'image').AddPair('source', Source));
          Content.AddElement(TJSONObject.Create.AddPair('type', 'text').AddPair('text', APrompt));
          Message := TJSONObject.Create.AddPair('role', 'user').AddPair('content', Content);
          Body.AddPair('model', Model).AddPair('max_tokens', TJSONNumber.Create(16000))
            .AddPair('messages', TJSONArray.Create(Message));
          // On a safety decline the current models answer through the provider's fallback instead of stopping
          if MatchText(Model, ['claude-fable-5-2', 'claude-fable-5-1', 'claude-opus-5-5', 'claude-opus-5',
            'claude-sonnet-5-5']) then
          begin
            Result.Headers := Result.Headers + [Header('anthropic-beta', 'server-side-fallback-2026-07-01')];
            Body.AddPair('fallbacks', 'default');
          end;
        end;
      vpGemini:
        begin
          Result.Url := 'https://generativelanguage.googleapis.com/v1beta/models/' +
            TNetEncoding.URL.Encode(Model) + ':generateContent';
          Result.Headers := Result.Headers + [Header('x-goog-api-key', AKey)];
          Content := TJSONArray.Create;
          Content.AddElement(TJSONObject.Create.AddPair('text', APrompt));
          Part := TJSONObject.Create.AddPair('mime_type', AMimeType).AddPair('data', Data);
          Content.AddElement(TJSONObject.Create.AddPair('inline_data', Part));
          Body.AddPair('contents', TJSONArray.Create(TJSONObject.Create.AddPair('parts', Content)));
        end;
      vpOllama:
        begin
          Result.Url := OllamaUrl + '/api/chat';
          Message := TJSONObject.Create.AddPair('role', 'user').AddPair('content', APrompt)
            .AddPair('images', TJSONArray.Create(TJSONString.Create(Data)));
          Body.AddPair('model', Model).AddPair('stream', TJSONBool.Create(False))
            .AddPair('messages', TJSONArray.Create(Message));
        end;
    else
      raise EArgumentException.Create('No vision model is chosen');
    end;
    Result.Body := Body.ToJSON;
  finally
    Body.Free;
  end;
end;

function ParseVisionAnswer(AProvider: TVisionProvider; AStatus: Integer; const AResponse: string;
  out AText, AError: string): Boolean;
var
  Json, Value: TJSONValue;
  Item: TJSONValue;
  Parts: TJSONArray;
  Reason: string;
begin
  AText := '';
  AError := '';
  Json := TJSONObject.ParseJSONValue(AResponse);
  try
    if not (Json is TJSONObject) then
    begin
      if AStatus = 200 then
        AError := 'The vision model sent an answer that is not JSON.'
      else
        AError := Format('The vision model failed (HTTP %d).', [AStatus]);
      Exit(False);
    end;
    // Errors: {"error": {"message": ...}} (OpenAI, Anthropic, Gemini), {"error": "..."} (Ollama)
    Value := Json.FindValue('error.message');
    if Value = nil then
    begin
      Value := Json.FindValue('error');
      if not (Value is TJSONString) then
        Value := nil;
    end;
    if (Value <> nil) or (AStatus <> 200) then
    begin
      if Value <> nil then
        AError := Value.Value
      else
        AError := Format('The vision model failed (HTTP %d).', [AStatus]);
      Exit(False);
    end;
    case AProvider of
      vpOpenAI:
        if Json.TryGetValue<string>('choices[0].message.content', Reason) then
          AText := Reason;
      vpAnthropic:
        begin
          if Json.TryGetValue<string>('stop_reason', Reason) and (Reason = 'refusal') then
          begin
            AError := 'Anthropic declined the request.';
            Exit(False);
          end;
          if Json.TryGetValue<TJSONArray>('content', Parts) then
            for Item in Parts do
              if (Item.GetValue<string>('type', '') = 'text') then
                AText := AText + Item.GetValue<string>('text', '');
        end;
      vpGemini:
        if Json.TryGetValue<TJSONArray>('candidates[0].content.parts', Parts) then
          for Item in Parts do
            AText := AText + Item.GetValue<string>('text', '');
      vpOllama:
        if Json.TryGetValue<string>('message.content', Reason) then
          AText := Reason;
    end;
    Result := AText.Trim <> '';
    if not Result then
      AError := 'The vision model sent no text.';
  finally
    Json.Free;
  end;
end;

function SendVisionRequest(AProvider: TVisionProvider; const AModel, AKey, APrompt: string;
  const AImage: TBytes; const AMimeType: string; out AText, AError: string): Boolean;
var
  Request: TVisionRequest;
  Client: THTTPClient;
  Body: TStringStream;
  Response: IHTTPResponse;
begin
  Result := False;
  AText := '';
  try
    Request := BuildVisionRequest(AProvider, AModel, AKey, APrompt, AImage, AMimeType);
    Client := THTTPClient.Create;
    Body := TStringStream.Create(Request.Body, TEncoding.UTF8);
    try
      Client.ConnectionTimeout := 15000;
      Client.ResponseTimeout := 300000; // a model may think for minutes over a large design
      Response := Client.Post(Request.Url, Body, nil, Request.Headers);
      Result := ParseVisionAnswer(AProvider, Response.StatusCode, Response.ContentAsString(TEncoding.UTF8),
        AText, AError);
    finally
      Body.Free;
      Client.Free;
    end;
  except
    on E: ENetHTTPClientException do
      if AProvider = vpOllama then
        AError := 'Ollama does not answer at ' + OllamaUrl + '. Start Ollama and pull a vision model (ollama pull ' +
          VisionDefaultModels[vpOllama] + ').'
      else
        AError := 'The vision model could not be reached: ' + E.Message;
    on E: Exception do
      AError := E.Message;
  end;
end;

{ DPAPI }

type
  TDataBlob = record
    cbData: DWORD;
    pbData: PByte;
  end;
  PDataBlob = ^TDataBlob;

const
  CRYPTPROTECT_UI_FORBIDDEN = 1;
  Entropy: AnsiString = 'RADWinUI vision key';

function CryptProtectData(pDataIn: PDataBlob; szDataDescr: PWideChar; pOptionalEntropy: PDataBlob;
  pvReserved, pPromptStruct: Pointer; dwFlags: DWORD; pDataOut: PDataBlob): BOOL; stdcall;
  external 'crypt32.dll';
function CryptUnprotectData(pDataIn: PDataBlob; ppszDataDescr: PPWideChar; pOptionalEntropy: PDataBlob;
  pvReserved, pPromptStruct: Pointer; dwFlags: DWORD; pDataOut: PDataBlob): BOOL; stdcall;
  external 'crypt32.dll';

function EntropyBlob: TDataBlob;
begin
  Result.cbData := Length(Entropy);
  Result.pbData := PByte(PAnsiChar(Entropy));
end;

function ProtectText(const AText: string): TBytes;
var
  Plain: TBytes;
  InBlob, OutBlob, Extra: TDataBlob;
begin
  Result := nil;
  if AText = '' then
    Exit;
  Plain := TEncoding.UTF8.GetBytes(AText);
  InBlob.cbData := Length(Plain);
  InBlob.pbData := @Plain[0];
  Extra := EntropyBlob;
  if not CryptProtectData(@InBlob, nil, @Extra, nil, nil, CRYPTPROTECT_UI_FORBIDDEN, @OutBlob) then
    RaiseLastOSError;
  try
    SetLength(Result, OutBlob.cbData);
    Move(OutBlob.pbData^, Result[0], OutBlob.cbData);
  finally
    LocalFree(HLOCAL(OutBlob.pbData));
  end;
end;

function UnprotectText(const AData: TBytes): string;
var
  Plain: TBytes;
  InBlob, OutBlob, Extra: TDataBlob;
begin
  Result := '';
  if Length(AData) = 0 then
    Exit;
  InBlob.cbData := Length(AData);
  InBlob.pbData := @AData[0];
  Extra := EntropyBlob;
  if not CryptUnprotectData(@InBlob, nil, @Extra, nil, nil, CRYPTPROTECT_UI_FORBIDDEN, @OutBlob) then
    Exit;
  try
    SetLength(Plain, OutBlob.cbData);
    if OutBlob.cbData > 0 then
      Move(OutBlob.pbData^, Plain[0], OutBlob.cbData);
    Result := TEncoding.UTF8.GetString(Plain);
  finally
    LocalFree(HLOCAL(OutBlob.pbData));
  end;
end;

{ Images }

function Encode(AImage: TGPBitmap; const AFormat: string; AQuality: Integer): TBytes;
var
  Clsid: TGUID;
  Stream: TBytesStream;
  Params: TEncoderParameters;
  Quality: ULONG;
  Status: TStatus;
begin
  Result := nil;
  if GetEncoderClsid(AFormat, Clsid) < 0 then
    Exit;
  Stream := TBytesStream.Create;
  try
    if AQuality > 0 then
    begin
      Quality := AQuality;
      Params.Count := 1;
      Params.Parameter[0].Guid := EncoderQuality;
      Params.Parameter[0].Type_ := EncoderParameterValueTypeLong;
      Params.Parameter[0].NumberOfValues := 1;
      Params.Parameter[0].Value := @Quality;
      Status := AImage.Save(TStreamAdapter.Create(Stream) as IStream, Clsid, @Params);
    end
    else
      Status := AImage.Save(TStreamAdapter.Create(Stream) as IStream, Clsid);
    if Status = Ok then
      Result := Copy(Stream.Bytes, 0, Stream.Size);
  finally
    Stream.Free;
  end;
end;

/// The image at most VisionMaxSide on its long side, as PNG, or as JPEG when the PNG is too large
function Prepare(ASource: TGPBitmap; out AMimeType: string): TBytes;
var
  Width, Height, Quality: Integer;
  Scale: Double;
  Target: TGPBitmap;
  Graphics: TGPGraphics;
begin
  Result := nil;
  AMimeType := '';
  if (ASource = nil) or (ASource.GetLastStatus <> Ok) or (ASource.GetWidth = 0) or (ASource.GetHeight = 0) then
    Exit;
  Scale := Min(1, VisionMaxSide / Max(ASource.GetWidth, ASource.GetHeight));
  Width := Max(1, Round(ASource.GetWidth * Scale));
  Height := Max(1, Round(ASource.GetHeight * Scale));
  Target := TGPBitmap.Create(Width, Height, PixelFormat24bppRGB);
  try
    Graphics := TGPGraphics.Create(Target);
    try
      Graphics.Clear(MakeColor(255, 255, 255, 255)); // transparent parts on white
      Graphics.SetInterpolationMode(InterpolationModeHighQualityBicubic);
      Graphics.SetPixelOffsetMode(PixelOffsetModeHighQuality);
      Graphics.DrawImage(ASource, 0, 0, Width, Height);
    finally
      Graphics.Free;
    end;
    Result := Encode(Target, 'image/png', 0);
    AMimeType := 'image/png';
    // A photo-like image: JPEG, lower quality until it fits (noise may not, the providers take up to 5 MB)
    for Quality in [85, 70, 50] do
      if Length(Result) > VisionMaxBytes then
      begin
        Result := Encode(Target, 'image/jpeg', Quality);
        AMimeType := 'image/jpeg';
      end;
    if Result = nil then
      AMimeType := '';
  finally
    Target.Free;
  end;
end;

function VisionImageFromFile(const AFile: string; out AMimeType: string): TBytes;
var
  Source: TGPBitmap;
begin
  AMimeType := '';
  if not FileExists(AFile) then
    Exit(nil);
  Source := TGPBitmap.Create(AFile);
  try
    Result := Prepare(Source, AMimeType);
  finally
    Source.Free;
  end;
end;

function VisionImageFromBitmap(ABitmap: HBITMAP; out AMimeType: string): TBytes;
var
  Source: TGPBitmap;
begin
  AMimeType := '';
  if ABitmap = 0 then
    Exit(nil);
  Source := TGPBitmap.Create(ABitmap, 0);
  try
    Result := Prepare(Source, AMimeType);
  finally
    Source.Free;
  end;
end;

end.
