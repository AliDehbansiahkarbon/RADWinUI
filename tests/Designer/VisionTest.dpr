program VisionTest;

{
  Checks RADWinUI.Designer.Vision, image prompts for Create XAML with AI: the request of
  each provider, their recorded answers and errors, the DPAPI key round trip, the image
  scaling and encoding, and the vision settings. No network calls:

    VisionTest

  scripts\Test-Preview.ps1 runs it.
}

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.JSON,
  System.Net.URLClient,
  Winapi.ActiveX,
  System.Win.Registry,
  Winapi.GDIPAPI,
  Winapi.GDIPOBJ,
  Winapi.GDIPUTIL,
  RADWinUI.Designer.Vision in '..\..\src\IDE\Designer\RADWinUI.Designer.Vision.pas',
  RADWinUI.Designer.Settings in '..\..\src\IDE\Designer\RADWinUI.Designer.Settings.pas';

var
  Failures: Integer;

procedure Check(ACondition: Boolean; const AWhat: string);
begin
  if ACondition then
    Writeln('  [ok] ', AWhat)
  else
  begin
    Writeln('  [failed] ', AWhat);
    Inc(Failures);
  end;
end;

function HeaderValue(const ARequest: TVisionRequest; const AName: string): string;
var
  Pair: TNameValuePair;
begin
  Result := '';
  for Pair in ARequest.Headers do
    if SameText(Pair.Name, AName) then
      Exit(Pair.Value);
end;

function BodyValue(const ARequest: TVisionRequest; const APath: string): string;
var
  Doc: TJSONValue;
begin
  Doc := TJSONObject.ParseJSONValue(ARequest.Body);
  try
    Result := '';
    if Doc <> nil then
      Result := Doc.GetValue<string>(APath, '');
  finally
    Doc.Free;
  end;
end;

procedure CheckRequests;
var
  Request: TVisionRequest;
begin
  Writeln('Requests');
  Request := BuildVisionRequest(vpOpenAI, '', 'sk-test', 'Make it blue', TBytes.Create(1, 2, 250, 255), 'image/png');
  Check(Request.Url = 'https://api.openai.com/v1/chat/completions', 'OpenAI: chat completions');
  Check(HeaderValue(Request, 'Authorization') = 'Bearer sk-test', 'OpenAI: bearer key');
  Check(BodyValue(Request, 'model') = 'gpt-5', 'OpenAI: the default model');
  Check(BodyValue(Request, 'messages[0].content[0].text') = 'Make it blue', 'OpenAI: the prompt');
  Check(BodyValue(Request, 'messages[0].content[1].image_url.url') = 'data:image/png;base64,AQL6/w==',
    'OpenAI: the image as a data URL');
  Check(BodyValue(Request, 'reasoning_effort') = 'low', 'OpenAI: gpt-5 reasons briefly (it took 2 minutes at medium)');
  Request := BuildVisionRequest(vpOpenAI, 'gpt-4o', 'sk-test', 'x', TBytes.Create(1), 'image/png');
  Check(BodyValue(Request, 'reasoning_effort') = '', 'OpenAI: no reasoning effort for a model without reasoning');

  Request := BuildVisionRequest(vpAnthropic, '', 'key', 'Make it blue', TBytes.Create(1, 2, 250, 255), 'image/jpeg');
  Check(Request.Url = 'https://api.anthropic.com/v1/messages', 'Anthropic: messages');
  Check(HeaderValue(Request, 'x-api-key') = 'key', 'Anthropic: x-api-key');
  Check(HeaderValue(Request, 'anthropic-version') <> '', 'Anthropic: version header');
  Check(BodyValue(Request, 'model') = 'claude-opus-5-5', 'Anthropic: the default model');
  Check(BodyValue(Request, 'messages[0].content[0].source.media_type') = 'image/jpeg', 'Anthropic: media type');
  Check(BodyValue(Request, 'messages[0].content[0].source.data') = 'AQL6/w==', 'Anthropic: base64 data');
  Check(BodyValue(Request, 'messages[0].content[1].text') = 'Make it blue', 'Anthropic: the prompt after the image');
  Check(BodyValue(Request, 'fallbacks') = 'default', 'Anthropic: fallback on a decline for current models');
  Request := BuildVisionRequest(vpAnthropic, 'claude-haiku-4-5', 'key', 'x', TBytes.Create(1), 'image/png');
  Check((BodyValue(Request, 'fallbacks') = '') and (HeaderValue(Request, 'anthropic-beta') = ''),
    'Anthropic: no fallback for an older model');

  Request := BuildVisionRequest(vpGemini, 'gemini-x', 'gk', 'Make it blue', TBytes.Create(1, 2, 250, 255), 'image/png');
  Check(Request.Url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-x:generateContent',
    'Gemini: the model in the URL');
  Check(HeaderValue(Request, 'x-goog-api-key') = 'gk', 'Gemini: the key in a header, not the URL');
  Check(BodyValue(Request, 'contents[0].parts[1].inline_data.data') = 'AQL6/w==', 'Gemini: inline data');

  Request := BuildVisionRequest(vpOllama, ' llava ', '', 'Make it blue', TBytes.Create(1, 2, 250, 255), 'image/png');
  Check(Request.Url = 'http://localhost:11434/api/chat', 'Ollama: local chat');
  Check(BodyValue(Request, 'model') = 'llava', 'Ollama: the model trimmed');
  Check(BodyValue(Request, 'messages[0].images[0]') = 'AQL6/w==', 'Ollama: images');
  Check(HeaderValue(Request, 'Authorization') = '', 'Ollama: no key');
end;

procedure CheckAnswers;
var
  Text, Error: string;
begin
  Writeln('Answers');
  Check(ParseVisionAnswer(vpOpenAI, 200, '{"choices":[{"message":{"role":"assistant","content":"<Grid/>"}}]}',
    Text, Error) and (Text = '<Grid/>'), 'OpenAI answer');
  Check(not ParseVisionAnswer(vpOpenAI, 401, '{"error":{"message":"Incorrect API key provided"}}', Text, Error) and
    (Error = 'Incorrect API key provided'), 'OpenAI error message');
  Check(ParseVisionAnswer(vpAnthropic, 200, '{"content":[{"type":"thinking","thinking":""},' +
    '{"type":"text","text":"<Grid>"},{"type":"text","text":"</Grid>"}],"stop_reason":"end_turn"}', Text, Error) and
    (Text = '<Grid></Grid>'), 'Anthropic: the text blocks only');
  Check(not ParseVisionAnswer(vpAnthropic, 200, '{"content":[],"stop_reason":"refusal"}', Text, Error) and
    (Error = 'Anthropic declined the request.'), 'Anthropic refusal');
  Check(not ParseVisionAnswer(vpAnthropic, 400, '{"type":"error","error":{"type":"invalid_request_error",' +
    '"message":"image too large"}}', Text, Error) and (Error = 'image too large'), 'Anthropic error');
  Check(ParseVisionAnswer(vpGemini, 200, '{"candidates":[{"content":{"parts":[{"text":"<Grid/>"}]}}]}', Text, Error)
    and (Text = '<Grid/>'), 'Gemini answer');
  Check(ParseVisionAnswer(vpOllama, 200, '{"model":"gemma3","message":{"role":"assistant","content":"<Grid/>"},' +
    '"done":true}', Text, Error) and (Text = '<Grid/>'), 'Ollama answer');
  Check(not ParseVisionAnswer(vpOllama, 404, '{"error":"model \"x\" not found"}', Text, Error) and
    (Error = 'model "x" not found'), 'Ollama error string');
  Check(not ParseVisionAnswer(vpOpenAI, 502, '<html>Bad gateway</html>', Text, Error) and Error.Contains('502'),
    'a non-JSON error page names the HTTP status');
  Check(not ParseVisionAnswer(vpOpenAI, 200, '{"choices":[{"message":{"content":"  "}}]}', Text, Error),
    'an empty answer is a failure');
end;

procedure CheckKey;
var
  Data: TBytes;
begin
  Writeln('Key');
  Data := ProtectText('sk-secret-' + #$00FC);
  Check((Length(Data) > 0) and (TEncoding.ANSI.GetString(Data).IndexOf('sk-secret') < 0), 'the key is encrypted');
  Check(UnprotectText(Data) = 'sk-secret-' + #$00FC, 'and read back');
  Data[High(Data)] := Data[High(Data)] xor $FF;
  Check(UnprotectText(Data) = '', 'damaged data reads as no key');
  Check(ProtectText('') = nil, 'no key, no data');
end;

function SaveTestImage(const AFile: string; AWidth, AHeight: Integer; ANoise: Boolean): Boolean;
var
  Bitmap: TGPBitmap;
  Clsid: TGUID;
  X, Y: Integer;
begin
  Bitmap := TGPBitmap.Create(AWidth, AHeight, PixelFormat32bppARGB);
  try
    for Y := 0 to AHeight - 1 do
      for X := 0 to AWidth - 1 do
        if ANoise then
          Bitmap.SetPixel(X, Y, MakeColor(255, Random(256), Random(256), Random(256)))
        else if X < AWidth div 2 then
          Bitmap.SetPixel(X, Y, MakeColor(255, 0, 120, 215))
        else
          Bitmap.SetPixel(X, Y, MakeColor(0, 0, 0, 0)); // transparent
    GetEncoderClsid('image/png', Clsid);
    Result := Bitmap.Save(AFile, Clsid) = Ok;
  finally
    Bitmap.Free;
  end;
end;

function ImageSize(const AData: TBytes; out AWidth, AHeight: Integer; out ARight: Cardinal): Boolean;
var
  Stream: TBytesStream;
  Bitmap: TGPBitmap;
  Color: TGPColor;
begin
  Stream := TBytesStream.Create(AData);
  Bitmap := TGPBitmap.Create(TStreamAdapter.Create(Stream, soOwned) as IStream);
  try
    Result := Bitmap.GetLastStatus = Ok;
    AWidth := Bitmap.GetWidth;
    AHeight := Bitmap.GetHeight;
    Bitmap.GetPixel(AWidth - 2, AHeight div 2, Color);
    ARight := Color and $FFFFFF;
  finally
    Bitmap.Free;
  end;
end;

procedure CheckImages;
var
  Folder, Mime: string;
  Data: TBytes;
  Width, Height: Integer;
  Right: Cardinal;
  Bitmap: HBITMAP;
begin
  Writeln('Images');
  Folder := TPath.Combine(TPath.GetTempPath, 'RADWinUIVisionTest');
  ForceDirectories(Folder);
  try
    Check(SaveTestImage(TPath.Combine(Folder, 'wide.png'), 3136, 400, False), 'test image written');
    Data := VisionImageFromFile(TPath.Combine(Folder, 'wide.png'), Mime);
    Check((Mime = 'image/png') and ImageSize(Data, Width, Height, Right), 'a PNG comes back as PNG');
    Check((Width = VisionMaxSide) and (Height = 200), Format('scaled to the long side, aspect kept (%dx%d)',
      [Width, Height]));
    Check(Right = $FFFFFF, 'transparent parts are white');
    Check(SaveTestImage(TPath.Combine(Folder, 'small.png'), 300, 200, False), 'small image written');
    Data := VisionImageFromFile(TPath.Combine(Folder, 'small.png'), Mime);
    Check(ImageSize(Data, Width, Height, Right) and (Width = 300) and (Height = 200), 'a small image is not enlarged');
    Check(SaveTestImage(TPath.Combine(Folder, 'noise.png'), 1500, 1200, True), 'noise image written');
    Data := VisionImageFromFile(TPath.Combine(Folder, 'noise.png'), Mime);
    Check((Mime = 'image/jpeg') and (Length(Data) <= VisionMaxBytes),
      Format('a PNG over the limit is sent as JPEG (%d bytes)', [Length(Data)]));
    TFile.WriteAllText(TPath.Combine(Folder, 'broken.png'), 'not an image');
    Check(VisionImageFromFile(TPath.Combine(Folder, 'broken.png'), Mime) = nil, 'a broken file is no image');
    Check(VisionImageFromFile(TPath.Combine(Folder, 'missing.png'), Mime) = nil, 'a missing file is no image');
    Bitmap := CreateBitmap(40, 30, 1, 32, nil);
    try
      Data := VisionImageFromBitmap(Bitmap, Mime);
      Check(ImageSize(Data, Width, Height, Right) and (Width = 40) and (Height = 30), 'a clipboard bitmap');
    finally
      DeleteObject(Bitmap);
    end;
  finally
    TDirectory.Delete(Folder, True);
  end;
end;

procedure CheckSettings;
const
  Key = 'Software\RADWinUI\VisionTest';
var
  Settings: TRADWinUISettings;
  Registry: TRegistry;
begin
  Writeln('Settings');
  try
    Settings := TRADWinUISettings.Load(Key);
    Check(Settings.VisionProvider = vpNone, 'no vision model by default: nothing is sent anywhere');
    Settings.VisionProvider := vpAnthropic;
    Settings.VisionModel := 'claude-sonnet-5-5';
    Settings.Save(Key);
    Settings := TRADWinUISettings.Load(Key);
    Check((Settings.VisionProvider = vpAnthropic) and (Settings.VisionModel = 'claude-sonnet-5-5'),
      'provider and model saved');
    TRADWinUISettings.SetVisionKey(Key, vpAnthropic, 'sk-ant-test');
    TRADWinUISettings.SetVisionKey(Key, vpOpenAI, 'sk-openai');
    Check(TRADWinUISettings.VisionKey(Key, vpAnthropic) = 'sk-ant-test', 'a key per provider');
    Check(TRADWinUISettings.VisionKey(Key, vpOpenAI) = 'sk-openai', 'the other key kept');
    Registry := TRegistry.Create(KEY_READ);
    try
      Registry.RootKey := HKEY_CURRENT_USER;
      Registry.OpenKeyReadOnly(Key);
      Check(Registry.GetDataType('VisionKeyAnthropic') = rdBinary, 'the key is stored as encrypted bytes');
    finally
      Registry.Free;
    end;
    TRADWinUISettings.SetVisionKey(Key, vpAnthropic, '');
    Check(TRADWinUISettings.VisionKey(Key, vpAnthropic) = '', 'an empty key removes it');
  finally
    Registry := TRegistry.Create;
    try
      Registry.RootKey := HKEY_CURRENT_USER;
      Registry.DeleteKey(Key);
    finally
      Registry.Free;
    end;
  end;
end;

begin
  RandSeed := 7;
  CheckRequests;
  CheckAnswers;
  CheckKey;
  CheckImages;
  CheckSettings;
  if Failures = 0 then
    Writeln('All checks passed')
  else
    Writeln(Failures, ' check(s) failed');
  ExitCode := Ord(Failures > 0);
end.
