unit Notch.Shell;

{ The apps installed on the PC as the Start menu lists them (the shell's
  AppsFolder, so Store and desktop apps both), their icons, and opening apps,
  web pages, files and remote desktops. }

interface

type
  TShellApp = record
    Name: string;
    // The AppsFolder parsing name: an AUMID for Store apps, a path or known-folder path for desktop apps
    ParsingName: string;
  end;

/// <summary>Every app of the Start menu, sorted by name. Read once, then cached.</summary>
function InstalledApps: TArray<TShellApp>;
/// <summary>The parsing name of the installed app called AName, '' when there is none.</summary>
function FindApp(const AName: string): string;
/// <summary>
///   A PNG of the icon of ATarget (a parsing name or a file), made once and kept
///   in AFolder. '' when the shell has no icon for it.
/// </summary>
function TargetIcon(const ATarget, AFolder: string): string;
/// <summary>Opens an app (parsing name), a URL, a protocol link, a file or a folder.</summary>
function OpenTarget(const ATarget: string; const AParameters: string = ''): Boolean;
/// <summary>Opens a Remote Desktop connection to AAddress.</summary>
procedure OpenRemoteDesktop(const AAddress: string);
/// <summary>The .rdp files saved in Documents.</summary>
function RdpFiles: TArray<string>;
/// <summary>True for a target that is a URL, a protocol link or a path rather than an app.</summary>
function IsPlainTarget(const ATarget: string): Boolean;
const
  // Where Windows looks for the programs a user starts with Windows
  WindowsRunKey = 'Software\Microsoft\Windows\CurrentVersion\Run';
  AutoStartName = 'RADWinUI Notch';

/// <summary>
///   Opens the calendar of the taskbar, as a click on its clock does. Without
///   a clock to find it opens the notification centre (Win+N), which shows
///   the calendar too.
/// </summary>
procedure OpenCalendarFlyout;
/// <summary>True when the taskbar's clock button is there to be clicked. Only looks, never clicks.</summary>
function TaskbarClockFound: Boolean;
/// <summary>True when AKey (under HKEY_CURRENT_USER) starts the notch with Windows.</summary>
function AutoStartEnabled(const AKey: string): Boolean;
/// <summary>Adds or removes the AutoStartName value of AKey, which starts AExe with Windows.</summary>
procedure SetAutoStart(const AKey, AExe: string; AEnabled: Boolean);
/// <summary>Writes premultiplied BGRA pixels, 4 bytes each, row after row, as a PNG file.</summary>
procedure SavePixelsPng(APixels: PByte; AWidth, AHeight: Integer; const AFileName: string);

implementation

uses
  Winapi.Windows,
  Winapi.ActiveX,
  Winapi.ShellAPI,
  Winapi.ShlObj,
  Winapi.Wincodec,
  System.SysUtils,
  System.StrUtils,
  System.IOUtils,
  System.Hash,
  System.Win.Registry,
  System.Variants,
  Winapi.UIAutomation,
  System.Generics.Defaults,
  System.Generics.Collections;

const
  DocumentExtensions: array[0..12] of string = ('.chm', '.hlp', '.txt', '.rtf', '.pdf', '.htm', '.html', '.url', '.md',
    '.doc', '.docx', '.xml', '.ini');

var
  Apps: TArray<TShellApp>;
  AppsRead: Boolean;

function ItemName(const AItem: IShellItem; AKind: DWORD): string;
var
  Name: PWideChar;
begin
  Result := '';
  if Succeeded(AItem.GetDisplayName(AKind, Name)) then
  begin
    Result := Name;
    CoTaskMemFree(Name);
  end;
end;

function InstalledApps: TArray<TShellApp>;
var
  Folder, Item: IShellItem;
  Items: IEnumShellItems;
  App: TShellApp;
  List: TList<TShellApp>;
begin
  if AppsRead then
    Exit(Apps);
  AppsRead := True;
  List := TList<TShellApp>.Create;
  try
    if Succeeded(SHCreateItemFromParsingName('shell:AppsFolder', nil, IShellItem, Folder)) and
      Succeeded(Folder.BindToHandler(nil, BHID_EnumItems, IEnumShellItems, Items)) then
      while Items.Next(1, Item, nil) = S_OK do
      begin
        App.Name := ItemName(Item, SIGDN_NORMALDISPLAY);
        App.ParsingName := ItemName(Item, SIGDN_PARENTRELATIVEPARSING);
        // Uninstallers, folders and documents of desktop apps are in there too
        if (App.Name <> '') and (App.ParsingName <> '') and not App.Name.ToLower.Contains('uninstall') and
          not (IsPlainTarget(App.ParsingName) and TDirectory.Exists(App.ParsingName)) and
          not MatchText(ExtractFileExt(App.ParsingName), DocumentExtensions) then
          List.Add(App);
        Item := nil;
      end;
    List.Sort(TComparer<TShellApp>.Construct(
      function(const A, B: TShellApp): Integer
      begin
        Result := CompareText(A.Name, B.Name);
      end));
    Apps := List.ToArray;
  finally
    List.Free;
  end;
  Result := Apps;
end;

function FindApp(const AName: string): string;
var
  App: TShellApp;
begin
  for App in InstalledApps do
    if SameText(App.Name, AName) then
      Exit(App.ParsingName);
  Result := '';
end;

function IsPlainTarget(const ATarget: string): Boolean;
begin
  // C:\..., \\server\..., https://..., mailto:, shell:...
  Result := ATarget.Contains(':') or ATarget.StartsWith('\\');
  // AUMIDs of Store apps have no colon, known-folder paths start with a GUID
  if ATarget.StartsWith('{') then
    Result := False;
end;

function ShellPath(const ATarget: string): string;
begin
  if IsPlainTarget(ATarget) then
    Result := ATarget
  else
    Result := 'shell:AppsFolder\' + ATarget;
end;

// System.Win.ComObj has OleCheck, but using it changes how every safecall error is reported
procedure Check(AResult: HRESULT);
begin
  if Failed(AResult) then
    raise EOSError.CreateFmt('Saving an icon failed (%.8x)', [AResult]);
end;

procedure SaveSourcePng(const AFactory: IWICImagingFactory; const ASource: IWICBitmapSource;
  const AFileName: string);
var
  Stream: IWICStream;
  Encoder: IWICBitmapEncoder;
  Frame: IWICBitmapFrameEncode;
  Options: IPropertyBag2;
  Format: WICPixelFormatGUID;
  Width, Height: UINT;
begin
  Check(ASource.GetSize(Width, Height));
  Check(AFactory.CreateStream(Stream));
  Check(Stream.InitializeFromFilename(PChar(AFileName), GENERIC_WRITE));
  Check(AFactory.CreateEncoder(GUID_ContainerFormatPng, GUID_NULL, Encoder));
  Check(Encoder.Initialize(Stream, WICBitmapEncoderNoCache));
  Options := nil;
  Check(Encoder.CreateNewFrame(Frame, Options));
  Check(Frame.Initialize(nil));
  Check(Frame.SetSize(Width, Height));
  // The encoder picks the closest format it supports and converts in WriteSource
  Format := GUID_WICPixelFormat32bppBGRA;
  Check(Frame.SetPixelFormat(Format));
  Check(Frame.WriteSource(ASource, nil));
  Check(Frame.Commit);
  Check(Encoder.Commit);
end;

function ImagingFactory: IWICImagingFactory;
begin
  Check(CoCreateInstance(CLSID_WICImagingFactory, nil, CLSCTX_INPROC_SERVER, IWICImagingFactory, Result));
end;

procedure SavePng(ABitmap: HBITMAP; const AFileName: string);
var
  Factory: IWICImagingFactory;
  Bitmap: IWICBitmap;
begin
  Factory := ImagingFactory;
  Check(Factory.CreateBitmapFromHBITMAP(ABitmap, 0, WICBitmapUsePremultipliedAlpha, Bitmap));
  SaveSourcePng(Factory, Bitmap, AFileName);
end;

procedure SavePixelsPng(APixels: PByte; AWidth, AHeight: Integer; const AFileName: string);
var
  Factory: IWICImagingFactory;
  Bitmap: IWICBitmap;
begin
  Factory := ImagingFactory;
  Check(Factory.CreateBitmapFromMemory(AWidth, AHeight, GUID_WICPixelFormat32bppPBGRA, AWidth * 4,
    AWidth * AHeight * 4, APixels, Bitmap));
  SaveSourcePng(Factory, Bitmap, AFileName);
end;

function TargetIcon(const ATarget, AFolder: string): string;
const
  IconSize = 48;
var
  Item: IShellItemImageFactory;
  Size: TSize;
  Bitmap: HBITMAP;
begin
  if ATarget = '' then
    Exit('');
  Result := TPath.Combine(AFolder, THashBobJenkins.GetHashString(LowerCase(ATarget)) + '.png');
  if TFile.Exists(Result) then
    Exit;
  if ATarget.StartsWith('http', True) or not Succeeded(SHCreateItemFromParsingName(PChar(ShellPath(ATarget)), nil,
    IShellItemImageFactory, Item)) then
    Exit('');
  Size.cx := IconSize;
  Size.cy := IconSize;
  Bitmap := 0;
  if not Succeeded(Item.GetImage(Size, SIIGBF_ICONONLY or SIIGBF_BIGGERSIZEOK, Bitmap)) then
    Exit('');
  try
    ForceDirectories(AFolder);
    try
      SavePng(Bitmap, Result);
    except
      // A half-written file would be taken for the icon next time
      DeleteFile(Result);
      Result := '';
    end;
  finally
    DeleteObject(Bitmap);
  end;
end;

function OpenTarget(const ATarget, AParameters: string): Boolean;
begin
  Result := (ATarget <> '') and (ShellExecute(0, nil, PChar(ShellPath(ATarget)), PChar(AParameters), nil,
    SW_SHOWNORMAL) > 32);
end;

procedure OpenRemoteDesktop(const AAddress: string);
begin
  if AAddress.EndsWith('.rdp', True) then
    OpenTarget(AAddress)
  else
    ShellExecute(0, nil, 'mstsc.exe', PChar('/v:' + AAddress.QuotedString('"')), nil, SW_SHOWNORMAL);
end;

function RdpFiles: TArray<string>;
var
  Documents: string;
begin
  Result := [];
  Documents := TPath.GetDocumentsPath;
  if TDirectory.Exists(Documents) then
    Result := TDirectory.GetFiles(Documents, '*.rdp');
end;

// The clock of the taskbar: a system tray button of its own class, whatever the language
function TaskbarClock: IUIAutomationElement;
var
  Automation: IUIAutomation;
  Tray: IUIAutomationElement;
  Condition: IUIAutomationCondition;
  Taskbar: HWND;
begin
  Result := nil;
  Taskbar := FindWindow('Shell_TrayWnd', nil);
  if (Taskbar = 0) or Failed(CoCreateInstance(CLSID_CUIAutomation, nil, CLSCTX_INPROC_SERVER, IUIAutomation,
    Automation)) then
    Exit;
  if Succeeded(Automation.ElementFromHandle(Taskbar, Tray)) and (Tray <> nil) and
    Succeeded(Automation.CreatePropertyCondition(UIA_ClassNamePropertyId, 'SystemTray.OmniButton', Condition)) then
    if Failed(Tray.FindFirst(TreeScope_Descendants, Condition, Result)) then
      Result := nil;
end;

function TaskbarClockFound: Boolean;
begin
  Result := TaskbarClock <> nil;
end;

procedure OpenCalendarFlyout;
var
  Clock: IUIAutomationElement;
  Pattern: IUnknown;
  Inputs: array[0..3] of TInput;
begin
  Clock := TaskbarClock;
  if (Clock <> nil) and Succeeded(Clock.GetCurrentPattern(UIA_InvokePatternId, Pattern)) and (Pattern <> nil) and
    Succeeded((Pattern as IUIAutomationInvokePattern).Invoke) then
    Exit;
  FillChar(Inputs, SizeOf(Inputs), 0);
  Inputs[0].Itype := INPUT_KEYBOARD;
  Inputs[0].ki.wVk := VK_LWIN;
  Inputs[1].Itype := INPUT_KEYBOARD;
  Inputs[1].ki.wVk := Ord('N');
  Inputs[2] := Inputs[1];
  Inputs[2].ki.dwFlags := KEYEVENTF_KEYUP;
  Inputs[3] := Inputs[0];
  Inputs[3].ki.dwFlags := KEYEVENTF_KEYUP;
  SendInput(Length(Inputs), Inputs[0], SizeOf(TInput));
end;

function AutoStartEnabled(const AKey: string): Boolean;
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    Result := Registry.OpenKeyReadOnly(AKey) and Registry.ValueExists(AutoStartName);
  finally
    Registry.Free;
  end;
end;

procedure SetAutoStart(const AKey, AExe: string; AEnabled: Boolean);
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if AEnabled then
    begin
      if not Registry.OpenKey(AKey, True) then
        raise Exception.Create('Windows did not let the notch start with it');
      // Quoted, a path with spaces is one program
      Registry.WriteString(AutoStartName, '"' + AExe + '"');
    end
    else if Registry.OpenKey(AKey, False) and Registry.ValueExists(AutoStartName) then
      Registry.DeleteValue(AutoStartName);
  finally
    Registry.Free;
  end;
end;

end.
