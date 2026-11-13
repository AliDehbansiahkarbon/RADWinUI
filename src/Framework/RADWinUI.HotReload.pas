unit RADWinUI.HotReload;

(*
  Hot reload for Debug builds: the IDE sends the XAML being edited, and the
  windows, pages and user controls built from that file load it again while
  the app runs, without a rebuild.

  Only Debug builds link this unit: the generated units and TWinUIHost use it
  under {$IFDEF DEBUG}. The first watch opens the named pipe
  \\.\pipe\RADWinUI.HotReload.<process id>, which only the current user (and
  administrators) can write to and remote clients cannot reach.

  A message is UTF-8 text, fields separated by #0:
    RWHR1, file name (MainWindow.xaml), shape, content XAML, raw XAML, error
  The shape and the content come from XamlCodeGen (fields, events, and the
  XAML as the generated unit loads it). The raw XAML is the edited text as it
  is, for TWinUIHost.XamlFile. An error is XamlCodeGen's when the edit does not
  generate.

  A generated class reloads when the compiled x:Name fields are all still
  there with the same types and the events are the same; otherwise it keeps
  its content and says "Rebuild needed". A small bar at the top of the window
  shows the outcome, and OutputDebugString puts it in the IDE's Event Log.
*)

interface

uses
  System.SysUtils,
  RADWinUI.Framework,
  RADWinUI.Xaml;

type
  TXamlReloadProc = procedure(const AXaml: string) of object;

  /// <summary>One watched instance, kept by it (AddHelper) and freed with it.</summary>
  TXamlHotReload = class
  strict private
    FOwner: TObject;
    FFile, FShape: string;
    FRaw: Boolean;
    FReload: TXamlReloadProc;
    class var FWatches: TArray<TXamlHotReload>;
    class var FLastStatus: string;
    class procedure Start; static;
    class function RootOf(AWatch: TXamlHotReload): TWinUIXamlRoot; static;
    class procedure Status(ARoot: TWinUIXamlRoot; AOk: Boolean; const AText: string); static;
  public
    /// <summary>
    ///   A generated window, page or user control: AReload gets the content as
    ///   XamlCodeGen writes it, when the edited XAML has the compiled AShape.
    /// </summary>
    class function Watch(AOwner: TObject; const AFile, AShape: string; AReload: TXamlReloadProc): TXamlHotReload;
    /// <summary>TWinUIHost: AReload gets the edited text as it is.</summary>
    class function WatchRaw(AOwner: TObject; const AFile: string; AReload: TXamlReloadProc): TXamlHotReload;
    destructor Destroy; override;
    /// <summary>What a message from the IDE does, on the UI thread. Tests call it directly.</summary>
    class procedure Apply(const AFile, AShape, AContent, ARaw, AError: string); static;
    /// <summary>
    ///   Why ANew cannot reload a class compiled with ACompiled ('' when it can): a compiled
    ///   x:Name field gone or of another type, or other events.
    /// </summary>
    class function Mismatch(const ACompiled, ANew: string): string; static;
    /// <summary>
    ///   Stops listening and releases the status bar while WinRT still runs: the app's
    ///   shutdown calls it (TWinUIApp.Run, or TWinUIHost's shutdown in a VCL app).
    /// </summary>
    class procedure Shutdown; static;
    /// <summary>
    ///   Whether AXaml loads, without raising: under the debugger an exception would stop the app
    ///   at each typo. AOwner owns the Delphi controls the XAML creates. False sets AError.
    /// </summary>
    class function Loads(AOwner: TObject; const AXaml: string; out AError: string): Boolean; static;
    /// <summary>The pipe of this process.</summary>
    class function PipeName: string; static;
    /// <summary>The text of the bar on the window, '' when it is not shown.</summary>
    class function StatusShown: string; static;
    /// <summary>The last outcome: 'Reloaded ...', 'Rebuild needed: ...' or the XAML error.</summary>
    class property LastStatus: string read FLastStatus;
  end;

implementation

uses
  Winapi.Windows,
  RADWinUI.Interop.Core,
  RADWinUI.Abi,
  RADWinUI.Runtime.Application,
  RADWinUI.Forms;

type
  // XamlReader's statics with a plain HRESULT (IXamlReaderStatics, whose Load is safecall)
  IXamlReaderCheck = interface(IInspectable)
    ['{82A4CD9E-435E-5AEB-8C4F-300CECE45CAE}']
    function Load(AXaml: HSTRING; out AResult: IInspectable): HRESULT; stdcall;
  end;

const
  Magic = 'RWHR1';
  PIPE_REJECT_REMOTE_CLIENTS = 8;

var
  ReaderCache: IInspectable;
  Queue: IDispatcherQueue;
  Started: Boolean;
  Stopping: Boolean;
  StatusPopup: TWinUIPopup;
  StatusBorder: TWinUIFrameworkElement;
  StatusText: TWinUITextBlock;
  StatusTimer: TWinUITimer;
  StatusRoot: TObject;

type
  TStatusHide = class
    class procedure Tick(Sender: TObject);
  end;

class procedure TStatusHide.Tick(Sender: TObject);
begin
  StatusTimer.Enabled := False;
  if StatusPopup <> nil then
    StatusPopup.IsOpen := False;
end;

procedure Received(const AText: string);
var
  Parts: TArray<string>;
begin
  Parts := AText.Split([#0]);
  if (Length(Parts) < 6) or (Parts[0] <> Magic) then
    Exit;
  Queue.TryEnqueue(TDispatcherQueueHandler.Create(
    procedure
    begin
      try
        TXamlHotReload.Apply(Parts[1], Parts[2], Parts[3], Parts[4], Parts[5]);
      except
        on E: Exception do
          OutputDebugString(PChar('RADWinUI hot reload: ' + E.Message));
      end;
    end));
end;

// One client at a time: the IDE connects, writes a message and closes
function Listen(AParameter: Pointer): Integer;
var
  Pipe: THandle;
  Buffer: array[0..65535] of Byte;
  Read: DWORD;
  Bytes: TBytes;
  Size: Integer;
begin
  Result := 0;
  while not Stopping do
  begin
    Pipe := CreateNamedPipe(PChar(TXamlHotReload.PipeName), PIPE_ACCESS_INBOUND,
      PIPE_TYPE_BYTE or PIPE_READMODE_BYTE or PIPE_WAIT or PIPE_REJECT_REMOTE_CLIENTS, 1, 0, 1 shl 20, 0, nil);
    if Pipe = INVALID_HANDLE_VALUE then
      Exit;
    try
      if not ConnectNamedPipe(Pipe, nil) and (GetLastError <> ERROR_PIPE_CONNECTED) then
        Continue;
      Bytes := nil;
      while ReadFile(Pipe, Buffer, SizeOf(Buffer), Read, nil) and (Read > 0) do
      begin
        Size := Length(Bytes);
        SetLength(Bytes, Size + Integer(Read));
        Move(Buffer, Bytes[Size], Read);
      end;
      if not Stopping and (Bytes <> nil) then
        Received(TEncoding.UTF8.GetString(Bytes));
      DisconnectNamedPipe(Pipe);
    finally
      CloseHandle(Pipe);
    end;
  end;
end;

{ TXamlHotReload }

class function TXamlHotReload.PipeName: string;
begin
  Result := '\\.\pipe\RADWinUI.HotReload.' + IntToStr(GetCurrentProcessId);
end;

class procedure TXamlHotReload.Start;
var
  ThreadId: TThreadID;
begin
  if Started then
    Exit;
  Started := True;
  // Messages arrive on the pipe's thread, the XAML is reloaded on this (the UI) thread
  Queue := DispatcherQueue.GetForCurrentThread;
  CloseHandle(BeginThread(nil, 0, Listen, nil, 0, ThreadId));
  OnApplicationShutdown(Shutdown);
end;

class function TXamlHotReload.Watch(AOwner: TObject; const AFile, AShape: string;
  AReload: TXamlReloadProc): TXamlHotReload;
begin
  Start;
  Result := TXamlHotReload.Create;
  Result.FOwner := AOwner;
  Result.FFile := ExtractFileName(AFile);
  Result.FShape := AShape;
  Result.FReload := AReload;
  FWatches := FWatches + [Result];
end;

class function TXamlHotReload.WatchRaw(AOwner: TObject; const AFile: string;
  AReload: TXamlReloadProc): TXamlHotReload;
begin
  Result := Watch(AOwner, AFile, '', AReload);
  Result.FRaw := True;
end;

destructor TXamlHotReload.Destroy;
var
  I: Integer;
begin
  for I := High(FWatches) downto 0 do
    if FWatches[I] = Self then
      Delete(FWatches, I, 1);
  // The bar on a window that goes away closes with it
  if StatusRoot = FOwner then
  begin
    StatusRoot := nil;
    if StatusPopup <> nil then
      try
        StatusPopup.IsOpen := False;
      except
        on E: Exception do
          OutputDebugString(PChar('RADWinUI hot reload bar: ' + E.Message));
      end;
  end;
  inherited;
end;

function SplitShape(const AShape: string): TArray<string>;
begin
  Result := AShape.Split([';'], TStringSplitOptions.ExcludeEmpty);
end;

class function TXamlHotReload.Mismatch(const ACompiled, ANew: string): string;
var
  Item, Kind: string;
  Compiled, Edited: TArray<string>;
  CompiledEvents, EditedEvents: string;
  Found: Boolean;
  Other: string;
begin
  Compiled := SplitShape(ACompiled);
  Edited := SplitShape(ANew);
  CompiledEvents := '';
  EditedEvents := '';
  for Item in Compiled do
  begin
    Kind := Item.Substring(0, 2);
    if Kind = 'E:' then
      CompiledEvents := CompiledEvents + Item + ';'
    else if Kind = 'F:' then
    begin
      // A field the compiled code uses must still be there, with the same type
      Found := False;
      for Other in Edited do
        if Other = Item then
          Found := True;
      if not Found then
        Exit(Format('x:Name %s (%s) is gone or has another type', [Item.Substring(2).Split([':'])[0],
          Item.Substring(2).Split([':'])[1]]));
    end;
  end;
  for Item in Edited do
    if Item.StartsWith('E:') then
      EditedEvents := EditedEvents + Item + ';';
  // The wiring is compiled code: the same handlers on the same elements, nothing more
  if CompiledEvents <> EditedEvents then
    Exit('the events changed (handlers and the elements they are on)');
  Result := '';
end;

class function TXamlHotReload.Loads(AOwner: TObject; const AXaml: string; out AError: string): Boolean;
var
  Reader: IXamlReaderCheck;
  Loaded: IInspectable;
  Previous: TObject;
  Hr: HRESULT;
begin
  Reader := IXamlReaderCheck(GetFactory(XamlReader.RuntimeClassName, IXamlReaderCheck, ReaderCache));
  Previous := CustomXamlLoadOwner;
  CustomXamlLoadOwner := AOwner;
  try
    Hr := Reader.Load(WinStr(AXaml), Loaded);
  finally
    CustomXamlLoadOwner := Previous;
  end;
  Result := Succeeded(Hr);
  if Result then
    AError := ''
  else
    AError := WinRTErrorMessage(Hr);
end;

class function TXamlHotReload.RootOf(AWatch: TXamlHotReload): TWinUIXamlRoot;
var
  Element: TWinUIUIElement;
begin
  Element := nil;
  if AWatch.FOwner is TWinUIWindow then
    Element := TWinUIWindow(AWatch.FOwner).Content
  else if AWatch.FOwner is TWinUIUIElement then
    Element := TWinUIUIElement(AWatch.FOwner);
  if Element = nil then
    Exit(nil);
  Result := Element.XamlRoot;
end;

class function TXamlHotReload.StatusShown: string;
begin
  if (StatusPopup <> nil) and StatusPopup.IsOpen then
    Result := StatusText.Text
  else
    Result := '';
end;

// A bar at the top of the window the change is in. ARoot is taken before the reload: new
// content has no XamlRoot until its first layout pass
class procedure TXamlHotReload.Status(ARoot: TWinUIXamlRoot; AOk: Boolean; const AText: string);
var
  Loaded: IInspectable;
  Width: Double;
begin
  FLastStatus := AText;
  OutputDebugString(PChar('RADWinUI hot reload: ' + AText));
  if ARoot = nil then
    Exit;
  try
    if StatusPopup = nil then
    begin
      StatusPopup := TWinUIPopup.Create(nil);
      Loaded := XamlReader.Load(WinStr(
        '<Border xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" CornerRadius="6" Padding="12,6" ' +
        'Background="#E6202020" BorderBrush="#40FFFFFF" BorderThickness="1">' +
        '<TextBlock Foreground="White" FontSize="12" TextWrapping="Wrap"/></Border>'));
      StatusBorder := TWinUIFrameworkElement(TWinUIObject.Wrap(StatusPopup, Loaded, TWinUIFrameworkElement));
      StatusPopup.Child := StatusBorder;
      StatusText := TWinUITextBlock(TWinUIObject.Wrap(StatusPopup, (Loaded as IBorder).Child, TWinUITextBlock));
      StatusTimer := TWinUITimer.Create;
      StatusTimer.Interval := 1800;
      StatusTimer.OnTimer := TStatusHide.Tick;
    end;
    StatusPopup.IsOpen := False;
    // A popup takes its XamlRoot once per window: set it only for another window
    if (StatusPopup.XamlRoot = nil) or
      ((StatusPopup.XamlRoot.WinRTObject as IInterface) <> (ARoot.WinRTObject as IInterface)) then
      StatusPopup.XamlRoot := ARoot;
    Width := ARoot.Size.Width - 24;
    if Width < 160 then
      Width := 160;
    StatusBorder.MaxWidth := Width;
    StatusText.Text := 'Hot reload: ' + AText;
    StatusPopup.HorizontalOffset := 12;
    StatusPopup.VerticalOffset := 12;
    StatusPopup.IsOpen := True;
    // A success goes away by itself, a problem stays until the next reload
    StatusTimer.Enabled := False;
    if AOk then
      StatusTimer.Enabled := True;
  except
    // The bar is a convenience: the reload and LastStatus stand without it
    on E: Exception do
      OutputDebugString(PChar('RADWinUI hot reload bar: ' + E.Message));
  end;
end;

class procedure TXamlHotReload.Apply(const AFile, AShape, AContent, ARaw, AError: string);
var
  Watch: TXamlHotReload;
  Reason: string;
  Root: TWinUIXamlRoot;
begin
  for Watch in Copy(FWatches) do
  begin
    if not SameText(Watch.FFile, ExtractFileName(AFile)) then
      Continue;
    Root := RootOf(Watch);
    if Root <> nil then
      StatusRoot := Watch.FOwner;
    if Watch.FRaw then
    begin
      // TWinUIHost shows its own errors in the control
      Watch.FReload(ARaw);
      FLastStatus := 'Reloaded ' + Watch.FFile;
      OutputDebugString(PChar('RADWinUI hot reload: ' + FLastStatus));
      Continue;
    end;
    if AError <> '' then
    begin
      // XamlCodeGen names the file with its folder: the file name is enough on the bar
      if Pos(Watch.FFile, AError) > 1 then
        Status(Root, False, Copy(AError, Pos(Watch.FFile, AError), MaxInt))
      else
        Status(Root, False, AError);
      Continue;
    end;
    Reason := Mismatch(Watch.FShape, AShape);
    if Reason <> '' then
    begin
      Status(Root, False, 'Rebuild needed: ' + Reason);
      Continue;
    end;
    // Checked first: a XAML error must not raise, the debugger would stop on it
    if not Loads(Watch.FOwner, AContent, Reason) then
    begin
      Status(Root, False, Reason);
      Continue;
    end;
    try
      Watch.FReload(AContent);
      Status(Root, True, 'Reloaded ' + Watch.FFile);
    except
      // The XAML did not load: the window keeps what it showed
      on E: Exception do
        Status(Root, False, E.Message);
    end;
  end;
end;

class procedure TXamlHotReload.Shutdown;
var
  Client: THandle;
begin
  FreeAndNil(StatusTimer);
  FreeAndNil(StatusPopup);
  StatusText := nil;
  StatusBorder := nil;
  Queue := nil;
  ReaderCache := nil;
  if not Started or Stopping then
    Exit;
  Stopping := True;
  // Wakes the listener from ConnectNamedPipe so its thread ends with the process
  Client := CreateFile(PChar(TXamlHotReload.PipeName), GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);
  if Client <> INVALID_HANDLE_VALUE then
    CloseHandle(Client);
end;

initialization

finalization
  TXamlHotReload.Shutdown;

end.
