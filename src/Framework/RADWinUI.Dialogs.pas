unit RADWinUI.Dialogs;

{
  Message boxes, input boxes and the file and folder pickers, the way the VCL
  offers them, on WinUI's ContentDialog and the Windows App SDK pickers.

    ShowMessage('Saved.');

    MessageDlg('Delete the file?', TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
      procedure(AResult: TModalResult)
      begin
        if AResult = mrYes then
          DeleteFile(FileName);
      end);

    OpenDialog := TWinUIOpenDialog.Create;
    OpenDialog.Filter := 'Text files (*.txt)|*.txt|All files (*.*)|*.*';
    OpenDialog.Execute(
      procedure(AOk: Boolean)
      begin
        if AOk then
          Memo.Text := TFile.ReadAllText(OpenDialog.FileName);
      end);

  WinUI shows dialogs without blocking the UI thread, so the result arrives in
  a callback instead of a function result. The callback always runs on the UI
  thread. Dialogs belong to the active window (TWinUIWindow.Active), and one
  opens after the other when several are requested at once.
}

interface

{$SCOPEDENUMS ON}

uses
  System.SysUtils,
  System.UITypes,
  RADWinUI.Interop.Core,
  RADWinUI.Abi,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Forms;

type
  TWinUIDialogResultProc = reference to procedure(AResult: TModalResult);
  TWinUIInputResultProc = reference to procedure(AOk: Boolean; const AValue: string);
  TWinUIExecuteProc = reference to procedure(AOk: Boolean);

  /// <summary>Base of the file and folder pickers.</summary>
  TWinUICommonDialog = class
  strict private
    FTitle: string;
    FInitialDir: string;
    FRunning: Boolean;
  protected
    function Owner: TWinUIWindow;
    procedure Finish(const AOnResult: TWinUIExecuteProc; AOk: Boolean);
    procedure Start;
    property Running: Boolean read FRunning;
  public
    /// <summary>The caption of the picker window, empty for the Windows default.</summary>
    property Title: string read FTitle write FTitle;
    /// <summary>The folder the picker opens in, empty for the one Windows remembers.</summary>
    property InitialDir: string read FInitialDir write FInitialDir;
  end;

  /// <summary>Picks one file, or several with MultiSelect, like the VCL TOpenDialog.</summary>
  TWinUIOpenDialog = class(TWinUICommonDialog)
  strict private
    FFilter: string;
    FFilterIndex: Integer;
    FMultiSelect: Boolean;
    FFileName: string;
    FFiles: TArray<string>;
  public
    constructor Create;
    /// <summary>
    ///   Shows the picker. AOnResult gets True with FileName and Files set, or
    ///   False when the user cancelled.
    /// </summary>
    procedure Execute(const AOnResult: TWinUIExecuteProc);
    /// <summary>VCL syntax: 'Text files (*.txt)|*.txt;*.log|All files (*.*)|*.*'.</summary>
    property Filter: string read FFilter write FFilter;
    /// <summary>The filter selected first, 1 for the first one.</summary>
    property FilterIndex: Integer read FFilterIndex write FFilterIndex;
    property MultiSelect: Boolean read FMultiSelect write FMultiSelect;
    /// <summary>The picked file, the first one with MultiSelect.</summary>
    property FileName: string read FFileName;
    /// <summary>Every picked file.</summary>
    property Files: TArray<string> read FFiles;
  end;

  /// <summary>Asks where to save a file, like the VCL TSaveDialog.</summary>
  TWinUISaveDialog = class(TWinUICommonDialog)
  strict private
    FFilter: string;
    FFilterIndex: Integer;
    FFileName: string;
    FDefaultExt: string;
    FOverwritePrompt: Boolean;
  public
    constructor Create;
    /// <summary>Shows the picker. AOnResult gets True with FileName set, or False when the user cancelled.</summary>
    procedure Execute(const AOnResult: TWinUIExecuteProc);
    /// <summary>VCL syntax: 'Text files (*.txt)|*.txt|All files (*.*)|*.*'.</summary>
    property Filter: string read FFilter write FFilter;
    property FilterIndex: Integer read FFilterIndex write FFilterIndex;
    /// <summary>The suggested name before Execute, the chosen full path after it.</summary>
    property FileName: string read FFileName write FFileName;
    /// <summary>The extension added when the user types none, such as 'txt'.</summary>
    property DefaultExt: string read FDefaultExt write FDefaultExt;
    /// <summary>True (the default): asks before replacing an existing file.</summary>
    property OverwritePrompt: Boolean read FOverwritePrompt write FOverwritePrompt;
  end;

  /// <summary>Picks a folder.</summary>
  TWinUIFolderDialog = class(TWinUICommonDialog)
  strict private
    FFolder: string;
  public
    /// <summary>Shows the picker. AOnResult gets True with Folder set, or False when the user cancelled.</summary>
    procedure Execute(const AOnResult: TWinUIExecuteProc);
    property Folder: string read FFolder;
  end;

/// <summary>Shows AText with an OK button. AOnClose runs when it closes.</summary>
procedure ShowMessage(const AText: string; const AOnClose: TProc = nil);

/// <summary>
///   Shows AText with up to three buttons and passes the button that closed it
///   as mrYes, mrNo, mrOK, mrCancel and so on. Esc gives the result of Cancel,
///   Close, No or Abort, the first one of them in AButtons.
/// </summary>
procedure MessageDlg(const AText: string; ADlgType: TMsgDlgType; AButtons: TMsgDlgButtons;
  const AOnResult: TWinUIDialogResultProc);

/// <summary>Asks for one line of text. AOnResult gets False when the user cancelled.</summary>
procedure InputQuery(const ACaption, APrompt, ADefault: string; const AOnResult: TWinUIInputResultProc);

/// <summary>
///   Splits a VCL filter into its descriptions and extension lists: '*.txt;*.log'
///   becomes '.txt' and '.log', '*.*' becomes '*'. For tests and custom pickers.
/// </summary>
procedure ParseFilter(const AFilter: string; out ANames: TArray<string>; out AExtensions: TArray<TArray<string>>);

resourcestring
  SMsgDlgWarning = 'Warning';
  SMsgDlgError = 'Error';
  SMsgDlgInformation = 'Information';
  SMsgDlgConfirm = 'Confirm';
  SMsgDlgYes = 'Yes';
  SMsgDlgNo = 'No';
  SMsgDlgOK = 'OK';
  SMsgDlgCancel = 'Cancel';
  SMsgDlgAbort = 'Abort';
  SMsgDlgRetry = 'Retry';
  SMsgDlgIgnore = 'Ignore';
  SMsgDlgAll = 'All';
  SMsgDlgNoToAll = 'No to All';
  SMsgDlgYesToAll = 'Yes to All';
  SMsgDlgHelp = 'Help';
  SMsgDlgClose = 'Close';

implementation

type
  // A WinRT IVector<String> the pickers' FileTypeChoices take
  TStringVector = class(TWinRTDelegate, IInspectable, IVector_String, IIterable_String)
  strict private
    FItems: TArray<string>;
  protected
    procedure GetIids(out AIidCount: Cardinal; out AIids: PGUID); safecall;
    function GetRuntimeClassName: HSTRING; safecall;
    function GetTrustLevel: TrustLevel; safecall;
    function GetAt(AIndex: Cardinal): HSTRING; safecall;
    function get_Size: Cardinal; safecall;
    function GetView: IVectorView_String; safecall;
    function IndexOf(AValue: HSTRING; out AIndex: Cardinal): Boolean; safecall;
    procedure SetAt(AIndex: Cardinal; AValue: HSTRING); safecall;
    procedure InsertAt(AIndex: Cardinal; AValue: HSTRING); safecall;
    procedure RemoveAt(AIndex: Cardinal); safecall;
    procedure Append(AValue: HSTRING); safecall;
    procedure RemoveAtEnd; safecall;
    procedure Clear; safecall;
    function GetMany(AStartIndex: Cardinal; AItemsSize: Cardinal; AItems: Pointer): Cardinal; safecall;
    procedure ReplaceAll(AItemsSize: Cardinal; AItems: Pointer); safecall;
    function First: IIterator_String; safecall;
  public
    constructor Create(const AItems: TArray<string>);
    property Items: TArray<string> read FItems;
  end;

  TStringVectorView = class(TWinRTDelegate, IInspectable, IVectorView_String, IIterable_String)
  strict private
    FItems: TArray<string>;
  protected
    procedure GetIids(out AIidCount: Cardinal; out AIids: PGUID); safecall;
    function GetRuntimeClassName: HSTRING; safecall;
    function GetTrustLevel: TrustLevel; safecall;
    function GetAt(AIndex: Cardinal): HSTRING; safecall;
    function get_Size: Cardinal; safecall;
    function IndexOf(AValue: HSTRING; out AIndex: Cardinal): Boolean; safecall;
    function GetMany(AStartIndex: Cardinal; AItemsSize: Cardinal; AItems: Pointer): Cardinal; safecall;
    function First: IIterator_String; safecall;
  public
    constructor Create(const AItems: TArray<string>);
  end;

  TStringIterator = class(TWinRTDelegate, IInspectable, IIterator_String)
  strict private
    FItems: TArray<string>;
    FIndex: Integer;
  protected
    procedure GetIids(out AIidCount: Cardinal; out AIids: PGUID); safecall;
    function GetRuntimeClassName: HSTRING; safecall;
    function GetTrustLevel: TrustLevel; safecall;
    function get_Current: HSTRING; safecall;
    function get_HasCurrent: Boolean; safecall;
    function MoveNext: Boolean; safecall;
    function GetMany(AItemsSize: Cardinal; AItems: Pointer): Cardinal; safecall;
  public
    constructor Create(const AItems: TArray<string>);
  end;

  PHStringArray = ^THStringArray;
  THStringArray = array[0..MaxInt div SizeOf(HSTRING) - 1] of HSTRING;

function CopyItems(const AItems: TArray<string>; AStart, ACount: Cardinal; AOut: Pointer): Cardinal;
var
  I: Cardinal;
begin
  Result := 0;
  if AStart >= Cardinal(Length(AItems)) then
    Exit;
  if ACount > Cardinal(Length(AItems)) - AStart then
    ACount := Cardinal(Length(AItems)) - AStart;
  for I := 0 to Integer(ACount) - 1 do
    PHStringArray(AOut)[I] := NewHString(AItems[AStart + I]);
  Result := ACount;
end;

function IndexOfItem(const AItems: TArray<string>; AValue: HSTRING; out AIndex: Cardinal): Boolean;
var
  S: string;
  I: Integer;
begin
  S := HStringToString(AValue);
  for I := 0 to High(AItems) do
    if AItems[I] = S then
    begin
      AIndex := I;
      Exit(True);
    end;
  AIndex := 0;
  Result := False;
end;

{ TStringVector }

constructor TStringVector.Create(const AItems: TArray<string>);
begin
  inherited Create;
  FItems := Copy(AItems);
end;

procedure TStringVector.GetIids(out AIidCount: Cardinal; out AIids: PGUID);
begin
  AIidCount := 0;
  AIids := nil;
end;

function TStringVector.GetRuntimeClassName: HSTRING;
begin
  Result := NewHString('Windows.Foundation.Collections.IVector`1<String>');
end;

function TStringVector.GetTrustLevel: TrustLevel;
begin
  Result := 0;
end;

function TStringVector.GetAt(AIndex: Cardinal): HSTRING;
begin
  if AIndex >= Cardinal(Length(FItems)) then
    raise EArgumentOutOfRangeException.Create('Index out of range');
  Result := NewHString(FItems[AIndex]);
end;

function TStringVector.get_Size: Cardinal;
begin
  Result := Length(FItems);
end;

function TStringVector.GetView: IVectorView_String;
begin
  Result := TStringVectorView.Create(FItems);
end;

function TStringVector.IndexOf(AValue: HSTRING; out AIndex: Cardinal): Boolean;
begin
  Result := IndexOfItem(FItems, AValue, AIndex);
end;

procedure TStringVector.SetAt(AIndex: Cardinal; AValue: HSTRING);
begin
  if AIndex >= Cardinal(Length(FItems)) then
    raise EArgumentOutOfRangeException.Create('Index out of range');
  FItems[AIndex] := HStringToString(AValue);
end;

procedure TStringVector.InsertAt(AIndex: Cardinal; AValue: HSTRING);
begin
  if AIndex > Cardinal(Length(FItems)) then
    raise EArgumentOutOfRangeException.Create('Index out of range');
  Insert(HStringToString(AValue), FItems, AIndex);
end;

procedure TStringVector.RemoveAt(AIndex: Cardinal);
begin
  if AIndex >= Cardinal(Length(FItems)) then
    raise EArgumentOutOfRangeException.Create('Index out of range');
  Delete(FItems, AIndex, 1);
end;

procedure TStringVector.Append(AValue: HSTRING);
begin
  FItems := FItems + [HStringToString(AValue)];
end;

procedure TStringVector.RemoveAtEnd;
begin
  if Length(FItems) > 0 then
    SetLength(FItems, Length(FItems) - 1);
end;

procedure TStringVector.Clear;
begin
  FItems := nil;
end;

function TStringVector.GetMany(AStartIndex, AItemsSize: Cardinal; AItems: Pointer): Cardinal;
begin
  Result := CopyItems(FItems, AStartIndex, AItemsSize, AItems);
end;

procedure TStringVector.ReplaceAll(AItemsSize: Cardinal; AItems: Pointer);
var
  I: Integer;
begin
  SetLength(FItems, AItemsSize);
  for I := 0 to Integer(AItemsSize) - 1 do
    FItems[I] := HStringToString(PHStringArray(AItems)[I]);
end;

function TStringVector.First: IIterator_String;
begin
  Result := TStringIterator.Create(FItems);
end;

{ TStringVectorView }

constructor TStringVectorView.Create(const AItems: TArray<string>);
begin
  inherited Create;
  FItems := Copy(AItems);
end;

procedure TStringVectorView.GetIids(out AIidCount: Cardinal; out AIids: PGUID);
begin
  AIidCount := 0;
  AIids := nil;
end;

function TStringVectorView.GetRuntimeClassName: HSTRING;
begin
  Result := NewHString('Windows.Foundation.Collections.IVectorView`1<String>');
end;

function TStringVectorView.GetTrustLevel: TrustLevel;
begin
  Result := 0;
end;

function TStringVectorView.GetAt(AIndex: Cardinal): HSTRING;
begin
  if AIndex >= Cardinal(Length(FItems)) then
    raise EArgumentOutOfRangeException.Create('Index out of range');
  Result := NewHString(FItems[AIndex]);
end;

function TStringVectorView.get_Size: Cardinal;
begin
  Result := Length(FItems);
end;

function TStringVectorView.IndexOf(AValue: HSTRING; out AIndex: Cardinal): Boolean;
begin
  Result := IndexOfItem(FItems, AValue, AIndex);
end;

function TStringVectorView.GetMany(AStartIndex, AItemsSize: Cardinal; AItems: Pointer): Cardinal;
begin
  Result := CopyItems(FItems, AStartIndex, AItemsSize, AItems);
end;

function TStringVectorView.First: IIterator_String;
begin
  Result := TStringIterator.Create(FItems);
end;

{ TStringIterator }

constructor TStringIterator.Create(const AItems: TArray<string>);
begin
  inherited Create;
  FItems := Copy(AItems);
end;

procedure TStringIterator.GetIids(out AIidCount: Cardinal; out AIids: PGUID);
begin
  AIidCount := 0;
  AIids := nil;
end;

function TStringIterator.GetRuntimeClassName: HSTRING;
begin
  Result := NewHString('Windows.Foundation.Collections.IIterator`1<String>');
end;

function TStringIterator.GetTrustLevel: TrustLevel;
begin
  Result := 0;
end;

function TStringIterator.get_Current: HSTRING;
begin
  if FIndex >= Length(FItems) then
    raise EArgumentOutOfRangeException.Create('No current item');
  Result := NewHString(FItems[FIndex]);
end;

function TStringIterator.get_HasCurrent: Boolean;
begin
  Result := FIndex < Length(FItems);
end;

function TStringIterator.MoveNext: Boolean;
begin
  if FIndex < Length(FItems) then
    Inc(FIndex);
  Result := FIndex < Length(FItems);
end;

function TStringIterator.GetMany(AItemsSize: Cardinal; AItems: Pointer): Cardinal;
begin
  Result := CopyItems(FItems, FIndex, AItemsSize, AItems);
  Inc(FIndex, Result);
end;

// The pickers copy the strings and never take a reference, so a TStringVector
// passed inline would keep a reference count of 0 and never be freed. Returned
// as an interface, it is counted and released when the calling routine ends.
function StringVector(const AItems: TArray<string>): IVector_String;
begin
  Result := TStringVector.Create(AItems);
end;

{ Filters }

procedure ParseFilter(const AFilter: string; out ANames: TArray<string>; out AExtensions: TArray<TArray<string>>);
var
  Parts, Patterns: TArray<string>;
  Exts: TArray<string>;
  Pattern, Ext: string;
  I: Integer;
begin
  ANames := nil;
  AExtensions := nil;
  Parts := AFilter.Split(['|']);
  I := 0;
  while I + 1 <= High(Parts) do
  begin
    Exts := nil;
    Patterns := Parts[I + 1].Split([';']);
    for Pattern in Patterns do
    begin
      Ext := Pattern.Trim;
      if (Ext = '') then
        Continue;
      if (Ext = '*.*') or (Ext = '*') then
        Ext := '*'
      else if Ext.StartsWith('*.') then
        Ext := Copy(Ext, 2, MaxInt)
      else if not Ext.StartsWith('.') then
        Ext := '.' + Ext;
      Exts := Exts + [Ext];
    end;
    if Length(Exts) > 0 then
    begin
      ANames := ANames + [Parts[I].Trim];
      AExtensions := AExtensions + [Exts];
    end;
    Inc(I, 2);
  end;
end;

{ TWinUICommonDialog }

function TWinUICommonDialog.Owner: TWinUIWindow;
begin
  Result := TWinUIWindow.Active;
  if Result = nil then
    raise Exception.Create('A picker needs an open window');
end;

procedure TWinUICommonDialog.Start;
begin
  if FRunning then
    raise Exception.Create(ClassName + ' is already open');
  FRunning := True;
end;

procedure TWinUICommonDialog.Finish(const AOnResult: TWinUIExecuteProc; AOk: Boolean);
begin
  // Completion handlers may run on another thread, the result goes to the UI thread
  TWinUIApp.Queue(
    procedure
    begin
      FRunning := False;
      if Assigned(AOnResult) then
        AOnResult(AOk);
    end);
end;

{ TWinUIOpenDialog }

constructor TWinUIOpenDialog.Create;
begin
  inherited Create;
  FFilterIndex := 1;
end;

procedure TWinUIOpenDialog.Execute(const AOnResult: TWinUIExecuteProc);
var
  Picker: Microsoft_Windows_Storage_Pickers_IFileOpenPicker;
  Picker2: Microsoft_Windows_Storage_Pickers_IFileOpenPicker2;
  Names: TArray<string>;
  Exts: TArray<TArray<string>>;
  Ext: string;
  I: Integer;
  Self_: TWinUIOpenDialog;
  MultiDone: AsyncOperationCompletedHandler_IVectorView_PickFileResult;
  SingleDone: AsyncOperationCompletedHandler_PickFileResult;
begin
  Start;
  try
    Picker := Microsoft_Windows_Storage_Pickers_FileOpenPicker.New(Owner.AppWindow.Id);
    ParseFilter(FFilter, Names, Exts);
    if Supports(Picker, Microsoft_Windows_Storage_Pickers_IFileOpenPicker2, Picker2) then
    begin
      if Title <> '' then
        Picker2.put_Title(WinStr(Title));
      if InitialDir <> '' then
        Picker2.put_SuggestedFolder(WinStr(InitialDir));
    end;
    if (Length(Names) > 1) and (Picker2 <> nil) then
    begin
      // Several filters: the user picks one from the file type list
      for I := 0 to High(Names) do
        Picker2.get_FileTypeChoices.Insert(WinStr(Names[I]), StringVector(Exts[I]));
      if (FFilterIndex >= 1) and (FFilterIndex <= Length(Names)) then
        Picker2.put_InitialFileTypeIndex(FFilterIndex - 1);
    end
    else if Length(Names) > 0 then
    begin
      for Ext in Exts[0] do
        Picker.get_FileTypeFilter.Append(WinStr(Ext));
    end
    else
      Picker.get_FileTypeFilter.Append(WinStr('*'));
    Self_ := Self;
    // The handlers sit in variables during the call: passed inline, their reference
    // count is 0 and the picker's QueryInterface and Release would free them
    if FMultiSelect then
    begin
      MultiDone := TAsyncOperationCompletedHandler_IVectorView_PickFileResult.Create(
        procedure(AInfo: IAsyncOperation_IVectorView_PickFileResult; AStatus: AsyncStatus)
        var
          Results: IVectorView_PickFileResult;
          Files: TArray<string>;
          J: Integer;
        begin
          Files := nil;
          if AStatus = AsyncStatus.Completed then
          begin
            Results := AInfo.GetResults;
            if Results <> nil then
              for J := 0 to Integer(Results.Size) - 1 do
                Files := Files + [TakeHString(Results.GetAt(J).get_Path)];
          end;
          Self_.FFiles := Files;
          if Length(Files) > 0 then
            Self_.FFileName := Files[0];
          Self_.Finish(AOnResult, Length(Files) > 0);
        end);
      Picker.PickMultipleFilesAsync.Completed := MultiDone;
    end
    else
    begin
      SingleDone := TAsyncOperationCompletedHandler_PickFileResult.Create(
        procedure(AInfo: IAsyncOperation_PickFileResult; AStatus: AsyncStatus)
        var
          Result_: IPickFileResult;
        begin
          Result_ := nil;
          if AStatus = AsyncStatus.Completed then
            Result_ := AInfo.GetResults;
          if Result_ <> nil then
          begin
            Self_.FFileName := TakeHString(Result_.get_Path);
            Self_.FFiles := [Self_.FFileName];
          end;
          Self_.Finish(AOnResult, Result_ <> nil);
        end);
      Picker.PickSingleFileAsync.Completed := SingleDone;
    end;
  except
    Finish(nil, False);
    raise;
  end;
end;

{ TWinUISaveDialog }

constructor TWinUISaveDialog.Create;
begin
  inherited Create;
  FFilterIndex := 1;
  FOverwritePrompt := True;
end;

procedure TWinUISaveDialog.Execute(const AOnResult: TWinUIExecuteProc);
var
  Picker: Microsoft_Windows_Storage_Pickers_IFileSavePicker;
  Picker2: Microsoft_Windows_Storage_Pickers_IFileSavePicker2;
  Names: TArray<string>;
  Exts: TArray<TArray<string>>;
  I: Integer;
  Self_: TWinUISaveDialog;
  Ext: string;
  Done: AsyncOperationCompletedHandler_PickFileResult;
begin
  Start;
  try
    Picker := Microsoft_Windows_Storage_Pickers_FileSavePicker.New(Owner.AppWindow.Id);
    ParseFilter(FFilter, Names, Exts);
    Ext := FDefaultExt;
    if (Ext <> '') and not Ext.StartsWith('.') then
      Ext := '.' + Ext;
    if (Length(Names) = 0) and (Ext <> '') then
    begin
      Names := [Ext];
      Exts := [[Ext]];
    end;
    for I := 0 to High(Names) do
      Picker.get_FileTypeChoices.Insert(WinStr(Names[I]), StringVector(Exts[I]));
    if Ext <> '' then
      Picker.put_DefaultFileExtension(WinStr(Ext));
    if FFileName <> '' then
      Picker.put_SuggestedFileName(WinStr(ExtractFileName(FFileName)));
    if Supports(Picker, Microsoft_Windows_Storage_Pickers_IFileSavePicker2, Picker2) then
    begin
      if Title <> '' then
        Picker2.put_Title(WinStr(Title));
      if InitialDir <> '' then
        Picker2.put_SuggestedStartFolder(WinStr(InitialDir));
      if (FFilterIndex >= 1) and (FFilterIndex <= Length(Names)) then
        Picker2.put_InitialFileTypeIndex(FFilterIndex - 1);
      Picker2.put_ShowOverwritePrompt(FOverwritePrompt);
    end;
    if (InitialDir <> '') then
      Picker.put_SuggestedFolder(WinStr(InitialDir));
    Self_ := Self;
    // In a variable during the call, as in TWinUIOpenDialog.Execute
    Done := TAsyncOperationCompletedHandler_PickFileResult.Create(
      procedure(AInfo: IAsyncOperation_PickFileResult; AStatus: AsyncStatus)
      var
        Result_: IPickFileResult;
      begin
        Result_ := nil;
        if AStatus = AsyncStatus.Completed then
          Result_ := AInfo.GetResults;
        if Result_ <> nil then
          Self_.FFileName := TakeHString(Result_.get_Path);
        Self_.Finish(AOnResult, Result_ <> nil);
      end);
    Picker.PickSaveFileAsync.Completed := Done;
  except
    Finish(nil, False);
    raise;
  end;
end;

{ TWinUIFolderDialog }

procedure TWinUIFolderDialog.Execute(const AOnResult: TWinUIExecuteProc);
var
  Picker: Microsoft_Windows_Storage_Pickers_IFolderPicker;
  Picker2: Microsoft_Windows_Storage_Pickers_IFolderPicker2;
  Self_: TWinUIFolderDialog;
  Done: AsyncOperationCompletedHandler_PickFolderResult;
begin
  Start;
  try
    Picker := Microsoft_Windows_Storage_Pickers_FolderPicker.New(Owner.AppWindow.Id);
    if Supports(Picker, Microsoft_Windows_Storage_Pickers_IFolderPicker2, Picker2) then
    begin
      if Title <> '' then
        Picker2.put_Title(WinStr(Title));
      if InitialDir <> '' then
        Picker2.put_SuggestedFolder(WinStr(InitialDir));
    end;
    Self_ := Self;
    // In a variable during the call, as in TWinUIOpenDialog.Execute
    Done := TAsyncOperationCompletedHandler_PickFolderResult.Create(
      procedure(AInfo: IAsyncOperation_PickFolderResult; AStatus: AsyncStatus)
      var
        Result_: IPickFolderResult;
      begin
        Result_ := nil;
        if AStatus = AsyncStatus.Completed then
          Result_ := AInfo.GetResults;
        if Result_ <> nil then
          Self_.FFolder := TakeHString(Result_.get_Path);
        Self_.Finish(AOnResult, Result_ <> nil);
      end);
    Picker.PickSingleFolderAsync.Completed := Done;
  except
    Finish(nil, False);
    raise;
  end;
end;

{ Message dialogs }

var
  // ContentDialog allows one open dialog per window: the rest wait here
  DialogOpen: Boolean;
  DialogQueue: TArray<TProc>;

procedure ShowNextDialog;
var
  Next: TProc;
begin
  if DialogOpen or (Length(DialogQueue) = 0) then
    Exit;
  Next := DialogQueue[0];
  Delete(DialogQueue, 0, 1);
  DialogOpen := True;
  try
    Next;
  except
    DialogOpen := False;
    raise;
  end;
end;

// Shows ADialog on the active window, calls AOnClosed with its result and frees it.
procedure RunDialog(ADialog: TWinUIContentDialog; const AOnClosed: TProc<TWinUIContentDialogResult>);
begin
  DialogQueue := DialogQueue + [
    procedure
    var
      Window: TWinUIWindow;
    begin
      Window := TWinUIWindow.Active;
      if (Window = nil) or (Window.Content = nil) then
      begin
        ADialog.Free;
        raise Exception.Create('A dialog needs an open window');
      end;
      ADialog.XamlRoot := Window.Content.XamlRoot;
      if Window.Content is TWinUIFrameworkElement then
        ADialog.RequestedTheme := TWinUIFrameworkElement(Window.Content).ActualTheme;
      ADialog.Closed.Add(
        procedure(Sender: TObject; E: TWinUIContentDialogClosedEventArgs)
        var
          Result_: TWinUIContentDialogResult;
        begin
          Result_ := E.Result;
          // Free the dialog and open the next one after Closed has finished
          TWinUIApp.Queue(
            procedure
            begin
              ADialog.Free;
              DialogOpen := False;
              try
                AOnClosed(Result_);
              finally
                ShowNextDialog;
              end;
            end);
        end);
      ADialog.ShowAsync;
    end];
  ShowNextDialog;
end;

function NewDialog(const ATitle: string): TWinUIContentDialog;
begin
  Result := TWinUIContentDialog.Create(nil);
  if ATitle <> '' then
    Result.Title := ATitle;
end;

procedure ShowMessage(const AText: string; const AOnClose: TProc);
var
  Dialog: TWinUIContentDialog;
begin
  Dialog := NewDialog('');
  Dialog.Content := AText;
  Dialog.CloseButtonText := SMsgDlgOK;
  Dialog.DefaultButton := TWinUIContentDialogButton.Close;
  RunDialog(Dialog,
    procedure(AResult: TWinUIContentDialogResult)
    begin
      if Assigned(AOnClose) then
        AOnClose;
    end);
end;

function ButtonCaption(AButton: TMsgDlgBtn): string;
begin
  case AButton of
    TMsgDlgBtn.mbYes: Result := SMsgDlgYes;
    TMsgDlgBtn.mbNo: Result := SMsgDlgNo;
    TMsgDlgBtn.mbOK: Result := SMsgDlgOK;
    TMsgDlgBtn.mbCancel: Result := SMsgDlgCancel;
    TMsgDlgBtn.mbAbort: Result := SMsgDlgAbort;
    TMsgDlgBtn.mbRetry: Result := SMsgDlgRetry;
    TMsgDlgBtn.mbIgnore: Result := SMsgDlgIgnore;
    TMsgDlgBtn.mbAll: Result := SMsgDlgAll;
    TMsgDlgBtn.mbNoToAll: Result := SMsgDlgNoToAll;
    TMsgDlgBtn.mbYesToAll: Result := SMsgDlgYesToAll;
    TMsgDlgBtn.mbHelp: Result := SMsgDlgHelp;
    TMsgDlgBtn.mbClose: Result := SMsgDlgClose;
  else
    Result := '';
  end;
end;

function ButtonResult(AButton: TMsgDlgBtn): TModalResult;
begin
  case AButton of
    TMsgDlgBtn.mbYes: Result := mrYes;
    TMsgDlgBtn.mbNo: Result := mrNo;
    TMsgDlgBtn.mbOK: Result := mrOk;
    TMsgDlgBtn.mbCancel: Result := mrCancel;
    TMsgDlgBtn.mbAbort: Result := mrAbort;
    TMsgDlgBtn.mbRetry: Result := mrRetry;
    TMsgDlgBtn.mbIgnore: Result := mrIgnore;
    TMsgDlgBtn.mbAll: Result := mrAll;
    TMsgDlgBtn.mbNoToAll: Result := mrNoToAll;
    TMsgDlgBtn.mbYesToAll: Result := mrYesToAll;
    TMsgDlgBtn.mbHelp: Result := mrHelp;
    TMsgDlgBtn.mbClose: Result := mrClose;
  else
    Result := mrNone;
  end;
end;

function DialogTitle(ADlgType: TMsgDlgType): string;
begin
  case ADlgType of
    TMsgDlgType.mtWarning: Result := SMsgDlgWarning;
    TMsgDlgType.mtError: Result := SMsgDlgError;
    TMsgDlgType.mtInformation: Result := SMsgDlgInformation;
    TMsgDlgType.mtConfirmation: Result := SMsgDlgConfirm;
  else
    Result := '';
  end;
end;

procedure MessageDlg(const AText: string; ADlgType: TMsgDlgType; AButtons: TMsgDlgButtons;
  const AOnResult: TWinUIDialogResultProc);
const
  // The order the buttons appear in, left to right
  Order: array[0..11] of TMsgDlgBtn = (TMsgDlgBtn.mbYes, TMsgDlgBtn.mbYesToAll, TMsgDlgBtn.mbOK,
    TMsgDlgBtn.mbAll, TMsgDlgBtn.mbRetry, TMsgDlgBtn.mbIgnore, TMsgDlgBtn.mbNo, TMsgDlgBtn.mbNoToAll,
    TMsgDlgBtn.mbHelp, TMsgDlgBtn.mbAbort, TMsgDlgBtn.mbCancel, TMsgDlgBtn.mbClose);
  // Esc closes the dialog with the first of these
  EscapeOrder: array[0..3] of TMsgDlgBtn = (TMsgDlgBtn.mbCancel, TMsgDlgBtn.mbClose, TMsgDlgBtn.mbNo,
    TMsgDlgBtn.mbAbort);
var
  Buttons: TArray<TMsgDlgBtn>;
  B, CloseButton: TMsgDlgBtn;
  HasClose: Boolean;
  Primary, Secondary, Close: TModalResult;
  Dialog: TWinUIContentDialog;
begin
  if AButtons = [] then
    AButtons := [TMsgDlgBtn.mbOK];
  HasClose := False;
  CloseButton := TMsgDlgBtn.mbCancel;
  for B in EscapeOrder do
    if B in AButtons then
    begin
      CloseButton := B;
      HasClose := True;
      Break;
    end;
  Buttons := nil;
  for B in Order do
    if (B in AButtons) and not (HasClose and (B = CloseButton)) then
      Buttons := Buttons + [B];
  if Length(Buttons) + Ord(HasClose) > 3 then
    raise EArgumentException.Create('A WinUI dialog has at most three buttons');
  Dialog := NewDialog(DialogTitle(ADlgType));
  Dialog.Content := AText;
  Primary := mrNone;
  Secondary := mrNone;
  Close := mrCancel;
  if Length(Buttons) > 0 then
  begin
    Dialog.PrimaryButtonText := ButtonCaption(Buttons[0]);
    Primary := ButtonResult(Buttons[0]);
    Dialog.DefaultButton := TWinUIContentDialogButton.Primary;
  end;
  if Length(Buttons) > 1 then
  begin
    Dialog.SecondaryButtonText := ButtonCaption(Buttons[1]);
    Secondary := ButtonResult(Buttons[1]);
  end;
  if HasClose then
  begin
    Dialog.CloseButtonText := ButtonCaption(CloseButton);
    Close := ButtonResult(CloseButton);
  end;
  RunDialog(Dialog,
    procedure(AResult: TWinUIContentDialogResult)
    begin
      if not Assigned(AOnResult) then
        Exit;
      case AResult of
        TWinUIContentDialogResult.Primary: AOnResult(Primary);
        TWinUIContentDialogResult.Secondary: AOnResult(Secondary);
      else
        AOnResult(Close);
      end;
    end);
end;

procedure InputQuery(const ACaption, APrompt, ADefault: string; const AOnResult: TWinUIInputResultProc);
var
  Dialog: TWinUIContentDialog;
  Panel: TWinUIStackPanel;
  Prompt: TWinUITextBlock;
  Edit: TWinUITextBox;
  Value: string;
begin
  Dialog := NewDialog(ACaption);
  Panel := TWinUIStackPanel.Create(Dialog);
  Panel.Spacing := 8;
  if APrompt <> '' then
  begin
    Prompt := TWinUITextBlock.Create(Dialog);
    Prompt.Text := APrompt;
    Prompt.TextWrapping := TWinUITextWrapping.Wrap;
    Panel.Children.Add(Prompt);
  end;
  Edit := TWinUITextBox.Create(Dialog);
  Edit.Text := ADefault;
  Panel.Children.Add(Edit);
  Dialog.Content := Panel;
  Dialog.PrimaryButtonText := SMsgDlgOK;
  Dialog.CloseButtonText := SMsgDlgCancel;
  Dialog.DefaultButton := TWinUIContentDialogButton.Primary;
  Dialog.Opened.Add(
    procedure(Sender: TObject; E: TWinUIContentDialogOpenedEventArgs)
    begin
      Edit.SelectAll;
      Edit.Focus(TWinUIFocusState.Programmatic);
    end);
  // The text box belongs to the dialog: read it while closing, the dialog is freed after Closed
  Value := ADefault;
  Dialog.Closing.Add(
    procedure(Sender: TObject; E: TWinUIContentDialogClosingEventArgs)
    begin
      Value := Edit.Text;
    end);
  RunDialog(Dialog,
    procedure(AResult: TWinUIContentDialogResult)
    begin
      if Assigned(AOnResult) then
        if AResult = TWinUIContentDialogResult.Primary then
          AOnResult(True, Value)
        else
          AOnResult(False, ADefault);
    end);
end;

end.
