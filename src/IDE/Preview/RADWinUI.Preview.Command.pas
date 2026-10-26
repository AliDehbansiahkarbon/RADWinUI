unit RADWinUI.Preview.Command;

{
  Tools > RADWinUI Preview and Docked Preview, and the Design view of .xaml files.
  The preview host renders the .xaml of the active editor (MainWindow.xaml,
  MainWindow.pas and MainWindow.Xaml.pas all mean MainWindow.xaml), every 150 ms
  this unit sends the editor text when it has changed, unsaved edits included.
  No WinUI code runs in the IDE: this unit reads and writes editor buffers and
  talks to the host over a pipe (RADWinUI.Preview.Client).

  In the Design view a click selects the element in the native Object Inspector
  and the Structure view. Property edits, Tool Palette inserts, drags and deletes
  change the XAML buffer with one undoable replacement each
  (RADWinUI.Designer.XamlEdit.ApplyDesignerEvent), and an event's handler is
  created or found in the window unit. Everything except the buffer, cursor and
  ToolsAPI calls lives in IDE-free units.
}

interface

/// <summary>Adds the menu item, RADWinUI.Wizard.Registration.Register calls it.</summary>
procedure AddPreviewCommand;

implementation

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ActiveX,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.UITypes,
  System.StrUtils,
  System.IniFiles,
  System.JSON,
  Vcl.ActnList,
  Vcl.AppEvnts,
  Vcl.Graphics,
  Vcl.Menus,
  Vcl.ExtCtrls,
  Vcl.Dialogs,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.ComCtrls,
  Vcl.ImgList,
  Vcl.Themes,
  Vcl.Clipbrd,
  ToolsAPI,
  PaletteAPI,
  DesignIntf,
  StructureViewAPI,
  RADWinUI.Wizard.Registration,
  RADWinUI.Wizard.Templates,
  RADWinUI.Preview.Client,
  RADWinUI.Preview.Menu,
  RADWinUI.Designer.XamlEdit,
  RADWinUI.Designer.Model,
  RADWinUI.Designer.PaletteIcons,
  RADWinUI.Designer.Palette,
  RADWinUI.Designer.Structure,
  RADWinUI.Designer.ObjectInspector;

type
  TPreviewCommand = class;

  TDesignPanel = class(TPanel)
  private
    FOnShowingChanged: TNotifyEvent;
    procedure CMShowingChanged(var Message: TMessage); message CM_SHOWINGCHANGED;
  public
    property OnShowingChanged: TNotifyEvent read FOnShowingChanged write FOnShowingChanged;
  published
    property OnKeyDown;
  end;

  TPreviewDock = class(TInterfacedObject, INTACustomDockableForm)
  public
    function GetCaption: string;
    function GetIdentifier: string;
    function GetFrameClass: TCustomFrameClass;
    procedure FrameCreated(AFrame: TCustomFrame);
    function GetMenuActionList: TCustomActionList;
    function GetMenuImageList: TCustomImageList;
    procedure CustomizePopupMenu(PopupMenu: TPopupMenu);
    function GetToolBarActionList: TCustomActionList;
    function GetToolBarImageList: TCustomImageList;
    procedure CustomizeToolBar(ToolBar: TToolBar);
    procedure SaveWindowState(Desktop: TCustomIniFile; const Section: string; IsProject: Boolean);
    procedure LoadWindowState(Desktop: TCustomIniFile; const Section: string);
    function GetEditState: TEditState;
    function EditAction(Action: TEditAction): Boolean;
  end;

  TDesignSubview = class(TInterfacedObject, INTACustomEditorSubView, IOTACustomEditorSubViewStructure)
  strict private
    FCommand: TPreviewCommand;
  public
    constructor Create(ACommand: TPreviewCommand);
    function GetCanCloneView: Boolean;
    function GetCaption: string;
    function GetPriority: Integer;
    function GetViewIdentifier: string;
    procedure Display(const AContext: IInterface; AViewObject: TObject);
    function EditAction(const AContext: IInterface; Action: TEditAction; AViewObject: TObject): Boolean;
    function GetEditState(const AContext: IInterface; AViewObject: TObject): TEditState;
    function Handles(const AContext: IInterface): Boolean;
    procedure Hide(const AContext: IInterface; AViewObject: TObject);
    procedure ViewClosed(const AContext: IInterface; AViewObject: TObject);
    function GetFrameClass: TCustomFrameClass;
    procedure FrameCreated(AFrame: TCustomFrame);
    function GetStructureContext(const AContext: IInterface; AViewObject: TObject): IOTAStructureContext;
    function GetStructureType(const AContext: IInterface; AViewObject: TObject): WideString;
  end;

  TRADWinUIPaletteItem = class(TInterfacedObject, IOTABasePaletteItem270,
    IOTABasePaletteItem280, IOTABasePaletteItem, IOTAPaletteOleDragDropOp,
    INTAPalettePaintIcon, INTAPalettePaintIcon160)
  private
    FCommand: TPreviewCommand;
    FName: string;        // the XAML element the item inserts (Button)
    FDisplayName: string; // what the palette shows (TWinUIButton)
    FRuntimeName: string;
    FIDString: string;
    FHintText: string;
    FHelpName: string;
    FImageIndex: Integer;
    FVisible: Boolean;
    FEnabled: Boolean;
  public
    constructor Create(ACommand: TPreviewCommand; const AName, ARuntimeName, ADisplayName: string);
    // The item paints its icon: the IDE did not show ImageIndex images of the shared
    // collection for these items
    procedure Paint(const Canvas: TCanvas; const X, Y: Integer; const IconSize: TNTAPaintIconSize); overload;
    procedure Paint(const Canvas: TCanvas; const X, Y: Integer; const IconSize: TNTAPaintIconSize;
      Enabled: Boolean); overload;
    function GetCanDelete: Boolean;
    function GetEnabled: Boolean;
    function GetHelpName: string;
    function GetHintText: string;
    function GetIDString: string;
    function GetName: string;
    function GetVisible: Boolean;
    function GetImageIndex: Integer;
    procedure SetEnabled(Value: Boolean);
    procedure SetHelpName(const Value: string);
    procedure SetName(const Value: string);
    procedure SetVisible(const Value: Boolean);
    procedure SetHintText(const Value: string);
    procedure SetImageIndex(const Value: Integer);
    procedure Execute;
    procedure Delete;
    function GetFormatRec: TFormatEtc;
    function QueryGetData(const SourceFormat: TFormatEtc): Boolean;
    function GetData(const SourceFormat: TFormatEtc; out Medium: TStgMedium): Boolean;
  end;

  /// <summary>
  ///   Saves the open .xaml files and their window units before a compile: the pre-build
  ///   XamlCodeGen reads them from disk, not from the editor.
  /// </summary>
  TCompileNotifier = class(TNotifierObject, IOTAIDENotifier, IOTAIDENotifier50)
  public
    procedure FileNotification(NotifyCode: TOTAFileNotification; const FileName: string; var Cancel: Boolean);
    procedure BeforeCompile(const Project: IOTAProject; var Cancel: Boolean); overload;
    procedure AfterCompile(Succeeded: Boolean); overload;
    procedure BeforeCompile(const Project: IOTAProject; IsCodeInsight: Boolean; var Cancel: Boolean); overload;
    procedure AfterCompile(Succeeded: Boolean; IsCodeInsight: Boolean); overload;
  end;

  TDesignerKeyBinding = class(TNotifierObject, IOTAKeyboardBinding)
  private
    FCommand: TPreviewCommand;
    procedure KeyPressed(const Context: IOTAKeyContext; KeyCode: TShortcut;
      var BindingResult: TKeyBindingResult);
  public
    constructor Create(ACommand: TPreviewCommand);
    function GetBindingType: TBindingType;
    function GetDisplayName: string;
    function GetName: string;
    procedure BindKeyboard(const BindingServices: IOTAKeyBindingServices);
  end;

  TWindowSaveNotifier = class(TNotifierObject, IOTAModuleNotifier)
  private
    FCommand: TPreviewCommand;
    FModule: IOTAModule;
    FIndex: Integer;
    FXamlPath, FFileName: string;
  public
    procedure BeforeSave; reintroduce;
    procedure Destroyed; reintroduce;
    procedure ModuleRenamed(const NewName: string);
    function CheckOverwrite: Boolean;
    procedure Detach;
  end;

  /// <summary>Tells the command when the IDE frees the dockable form or the inspector in it.</summary>
  TFreeWatch = class(TComponent)
  private
    FCommand: TPreviewCommand;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(ACommand: TPreviewCommand); reintroduce;
  end;

  TPreviewCommand = class
  strict private
    FAction: TAction;
    FItem: TMenuItem;
    FDockedAction: TAction;
    FDockedItem: TMenuItem;
    FPreviewDock: INTACustomDockableForm;
    FPreviewDockForm: TCustomForm;
    FPreviewSurface: TPanel;
    FDesignSurface: TDesignPanel;
    FDesignSurfaces: TList;
    FDesignView: INTACustomEditorSubView;
    FDesignViewRegistration: Pointer;
    FDesignViewActive: Boolean;
    FParentWindow: HWND;
    FPaletteServices: IOTAPaletteServices;
    FPaletteGroups: TInterfaceList; // one per RADWinUI category
    FPaletteItems: TInterfaceList;
    FPaletteStateActive: Boolean;
    FKeyBinding: Integer;
    FThemeMessage: string;
    FThemePid: DWORD;
    FWatch: TFreeWatch;
    FNotifier: Integer;
    FTimer: TTimer;
    FMenuTimer: TTimer;
    FApplicationEvents: TApplicationEvents;
    FMenuTries: Integer;
    FClient: TPreviewClient;
    FDocked: Boolean;
    FXamlPath: string;
    FInTick: Boolean;
    FIndex: TDesignerTypeIndex;
    FInspector: TNativeObjectInspector;
    FInspectorDirty: Boolean;
    FSelection: TDesignerSelection;
    FSelectionPath: string;
    FDesignRestartPending: Boolean;
    FDesignShownAt: Cardinal;
    FDesignRestarts: Integer;
    FLastClientStatus: string;
    FCodePath, FCodeXaml, FCodePas: string;
    FCodeDue: Cardinal;
    FCodePending: Boolean;
    FStructure: TDesignerStructure;
    FStructureContext: IOTAStructureContext;
    FSaveNotifiers: TInterfaceList;
    FCleaning: Boolean;
    procedure WatchWindow(const APath: string);
    procedure SyncStructure;
    procedure SelectInStructure(ALine, AColumn: Integer);
    procedure SelectStructureElement(AElement: TXamlElement; ADefault: Boolean);
    procedure ClearSelection;
    procedure DeleteSelection;
    function CanDeleteSelection: Boolean;
    procedure UndoDesigner(ARedo: Boolean);
    procedure SyncCode(AImmediate: Boolean = False);
    procedure Selected;
    procedure StructureEvent(const AEvent: string);
    procedure CopySelection;
    procedure PasteSelection;
    procedure DesignKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DesignShowingChanged(Sender: TObject);
    procedure ApplicationMessage(var Msg: TMsg; var Handled: Boolean);
    function BuildShortcut(ACompile: Boolean): Boolean;
    procedure SetPaletteDesignerActive(AActive: Boolean);
    procedure ShowInspector;
    procedure PropertyChange(AName, AValue: string);
    procedure EventHandler(AEvent, AHandler: string);
    procedure EventCleared(AEvent: string);
    function FindXaml: string;
    procedure Execute(Sender: TObject);
    procedure ExecuteDocked(Sender: TObject);
    procedure RunPreview(ADocked: Boolean);
    procedure Update(Sender: TObject);
    procedure AddToMenu(Sender: TObject);
    procedure Tick(Sender: TObject);
    procedure TickOnce;
    procedure SyncTheme;
    procedure Stop;
    procedure ShowXamlCode;
    function ShowPreviewDock: Boolean;
  public
    procedure CompilationFinished;
    procedure CleanupWindow(const APath, ASaving: string);
    procedure DesignFailure(const AOperation, AError: string);
    constructor Create;
    destructor Destroy; override;
    procedure PreviewFrameCreated(AFrame: TCustomFrame);
    procedure DesignFrameCreated(AFrame: TCustomFrame);
    procedure DesignViewDisplayed(const AContext: IInterface; AViewObject: TObject);
    procedure DesignViewClosed(AViewObject: TObject);
    function DesignEditAction(Action: TEditAction): Boolean;
    function DesignEditState: TEditState;
    function StructureForFile(const AFile: string): IOTAStructureContext;
    procedure RegisterPalette;
    procedure UnregisterPalette;
    procedure RemovePaletteGroup(const AID: string);
    procedure SelectPaletteItem(const AName: string);
    function ShowDesignForFile(const AFile: string): Boolean;
    /// <summary>A .xaml window the IDE just opened shows Design first, like a VCL form.</summary>
    procedure OpenInDesign(const AFile: string);
    function ToggleCodeDesignForFile(const AFile: string): Boolean;
    /// <summary>The IDE freed the dockable form or the inspector.</summary>
    procedure Freed(AComponent: TComponent);
  end;

var
  Command: TPreviewCommand;

/// The host exe of the RADWinUI checkout: Release build, else Debug, '' when not built.
function HostExe: string;
var
  Config: string;
begin
  for Config in ['Release', 'Debug'] do
  begin
    Result := TPath.Combine(RootFolder, 'src\IDE\Preview\Win64\' + Config + '\RADWinUIPreview.exe');
    if FileExists(Result) then
      Exit;
  end;
  Result := '';
end;

/// The .xaml file that AFile belongs to, or ''.
function XamlOf(const AFile: string): string;
begin
  if SameText(ExtractFileExt(AFile), '.xaml') then
    Exit(AFile);
  Result := AFile;
  if SameText(ExtractFileExt(Result), '.pas') then
    Result := ChangeFileExt(Result, '');
  if SameText(ExtractFileExt(Result), '.Xaml') then
    Result := ChangeFileExt(Result, '');
  Result := Result + '.xaml';
  if not FileExists(Result) then
    Result := '';
end;

/// The text of AFile: its editor buffer when it is open (unsaved edits too), else the file.
function SourceText(const AFile: string): string;
var
  Module: IOTAModule;
  Editor: IOTASourceEditor;
  Reader: IOTAEditReader;
  Chunk, Text: UTF8String;
  I, Count, Position: Integer;
begin
  Module := (BorlandIDEServices as IOTAModuleServices).FindModule(AFile);
  if Module <> nil then
    for I := 0 to Module.ModuleFileCount - 1 do
      if Supports(Module.ModuleFileEditors[I], IOTASourceEditor, Editor) and SameText(Editor.FileName, AFile) then
      begin
        Reader := Editor.CreateReader;
        Text := '';
        Position := 0;
        repeat
          SetLength(Chunk, 65536);
          Count := Reader.GetText(Position, PAnsiChar(Chunk), Length(Chunk));
          SetLength(Chunk, Count);
          Text := Text + Chunk;
          Inc(Position, Count);
        until Count = 0;
        Exit(UTF8ToString(Text));
      end;
  if FileExists(AFile) then
    Result := TFile.ReadAllText(AFile)
  else
    Result := '';
end;

/// The source editor of AFile, opening the file when it is not open.
function EditorOf(const AFile: string): IOTASourceEditor;
var
  Module: IOTAModule;
  I: Integer;
begin
  Module := (BorlandIDEServices as IOTAModuleServices).FindModule(AFile);
  if Module = nil then
  begin
    (BorlandIDEServices as IOTAActionServices).OpenFile(AFile);
    Module := (BorlandIDEServices as IOTAModuleServices).FindModule(AFile);
  end;
  if Module <> nil then
    for I := 0 to Module.ModuleFileCount - 1 do
      if Supports(Module.ModuleFileEditors[I], IOTASourceEditor, Result) and SameText(Result.FileName, AFile) then
        Exit;
  raise Exception.Create('Cannot open ' + AFile);
end;

/// Turns the buffer of AFile from AOld into ANew with one undoable replacement.
/// Own both snapshots while generator calls and editor notifications run.
procedure ApplyText(const AFile: string; AOld, ANew: string);
var
  Change: TTextChange;
  Writer: IOTAEditWriter;
  Inserted: UTF8String;
begin
  if AOld = ANew then
    Exit;
  Change := TextChange(AOld, ANew);
  if (Change.Start < 0) or (Change.Length < 0) or
    (Change.Start > Length(AOld)) or (Change.Length > Length(AOld) - Change.Start) then
    raise Exception.Create('Invalid designer edit range; the source was not changed');
  if SourceText(AFile) <> AOld then
    raise Exception.Create('The source changed before the designer edit; please retry');
  // Keep the UTF-8 storage alive until the writer has committed the edit.
  Inserted := UTF8String(Change.Text);
  Writer := EditorOf(AFile).CreateUndoableWriter;
  Writer.CopyTo(Utf8Offset(AOld, Change.Start));
  Writer.DeleteTo(Utf8Offset(AOld, Change.Start + Change.Length));
  Writer.Insert(PAnsiChar(Inserted));
  // Preserve the common suffix too (including handler and unit terminators).
  // All writer positions refer to the original UTF-8 buffer.
  Writer.CopyTo(Utf8Offset(AOld, Length(AOld)));
  Writer := nil; // Commit before navigation or another editor reader is created.
end;

/// Shows AFile with the cursor at ALine, AColumn (1-based characters).
procedure GotoSource(const AFile: string; ALine, AColumn: Integer);
var
  Editor: IOTASourceEditor;
  Buffer: IOTAEditBuffer;
  View: IOTAEditView;
  SourceLines: TStringList;
  CharPos: TOTACharPos;
  EditPos: TOTAEditPos;
begin
  Editor := EditorOf(AFile);
  // Show brings the IDE to the front and takes the focus from the preview: only when
  // the file is not the editor's current one
  Buffer := (BorlandIDEServices as IOTAEditorServices).TopBuffer;
  if (Editor.EditViewCount = 0) or (Buffer = nil) or not SameText(Buffer.FileName, AFile) then
    Editor.Show;
  if Editor.EditViewCount = 0 then
    Exit;
  View := Editor.EditViews[0];
  SourceLines := TStringList.Create;
  try
    SourceLines.Text := SourceText(AFile);
    CharPos.Line := ALine;
    if (ALine > 0) and (ALine <= SourceLines.Count) then
      CharPos.CharIndex := Utf8Offset(SourceLines[ALine - 1], AColumn - 1)
    else
      CharPos.CharIndex := AColumn - 1;
  finally
    SourceLines.Free;
  end;
  View.ConvertPos(False, EditPos, CharPos);
  View.CursorPos := EditPos;
  View.MoveViewToCursor;
  View.Paint;
end;

/// One line in %TEMP%\RADWinUI\ide.log: why the preview did (not) start, what failed.
procedure Log(const AText: string);
var
  Folder: string;
begin
  try
    Folder := TPath.Combine(TPath.GetTempPath, 'RADWinUI');
    ForceDirectories(Folder);
    TFile.AppendAllText(TPath.Combine(Folder, 'ide.log'),
      FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + '  ' + AText + sLineBreak, TEncoding.UTF8);
  except
    // never let logging disturb the IDE
  end;
end;

/// Generate from a snapshot of the IDE buffers, without saving the user's XAML/Pascal.
function GenerateCode(const APath, AXaml, APas: string; out AText, AError: string): Boolean;
var
  Json: TJSONObject;
  RequestFile, CommandLine: string;
  Startup: TStartupInfo;
  Process: TProcessInformation;
  ID: TGUID;
begin
  Result := False;
  AError := '';
  CreateGUID(ID);
  RequestFile := TPath.Combine(TPath.GetTempPath, 'RADWinUI-' + GUIDToString(ID) + '.json');
  try
    Json := TJSONObject.Create;
    try
      Json.AddPair('path', APath);
      Json.AddPair('xaml', AXaml);
      Json.AddPair('pas', APas);
      TFile.WriteAllText(RequestFile, Json.ToJSON, TEncoding.UTF8);
    finally
      Json.Free;
    end;
    if not FileExists(TPath.Combine(RootFolder, 'bin\XamlCodeGen.exe')) then
      raise Exception.Create('bin\XamlCodeGen.exe is missing: open ' + RADWinUIGroup + ' and use Build All');
    CommandLine := '"' + TPath.Combine(RootFolder, 'bin\XamlCodeGen.exe') + '" --ide-request "' + RequestFile + '"';
    UniqueString(CommandLine);
    Startup := Default(TStartupInfo);
    Startup.cb := SizeOf(Startup);
    if not CreateProcess(nil, PChar(CommandLine), nil, nil, False, CREATE_NO_WINDOW,
      nil, nil, Startup, Process) then
      raise Exception.Create('Cannot start XamlCodeGen.exe: ' + SysErrorMessage(GetLastError));
    try
      // Generation runs synchronously and is capped at five seconds, move it to a
      // worker thread if large forms ever make the delay noticeable.
      if WaitForSingleObject(Process.hProcess, 5000) <> WAIT_OBJECT_0 then
      begin
        TerminateProcess(Process.hProcess, 1);
        raise Exception.Create('XamlCodeGen did not finish within five seconds');
      end;
    finally
      CloseHandle(Process.hThread);
      CloseHandle(Process.hProcess);
    end;
    Json := TJSONObject.ParseJSONValue(TFile.ReadAllText(RequestFile)) as TJSONObject;
    try
      Result := (Json <> nil) and (Json.GetValue('text') <> nil);
      if Result then
        AText := Json.GetValue('text').Value
      else if (Json <> nil) and (Json.GetValue('error') <> nil) then
        AError := Json.GetValue('error').Value
      else
        AError := 'XamlCodeGen did not return generated code';
    finally
      Json.Free;
    end;
  except
    on E: Exception do
      AError := E.Message;
  end;
  try
    if FileExists(RequestFile) then
      TFile.Delete(RequestFile);
  except
    // Cleanup must not interrupt the IDE if a timed-out XamlCodeGen process is exiting.
  end;
end;

procedure TPreviewCommand.SyncCode(AImmediate: Boolean);
var
  Xaml, Pas, Generated, Error, GeneratedFile: string;
  Module: IOTAModule;
begin
  if FXamlPath = '' then
    Exit;
  Xaml := SourceText(FXamlPath);
  Pas := SourceText(ChangeFileExt(FXamlPath, '.pas'));
  if (Xaml = '') or (Pas = '') then
    Exit;
  if not SameText(FCodePath, FXamlPath) or (FCodeXaml <> Xaml) or (FCodePas <> Pas) then
  begin
    FCodePath := FXamlPath;
    FCodeXaml := Xaml;
    FCodePas := Pas;
    FCodeDue := GetTickCount + 500;
    FCodePending := True;
  end;
  if not FCodePending or (not AImmediate and (Integer(GetTickCount - FCodeDue) < 0)) then
    Exit;
  FCodePending := False;
  if not GenerateCode(FXamlPath, Xaml, Pas, Generated, Error) then
  begin
    Log('live XamlCodeGen: ' + Error);
    Exit;
  end;
  GeneratedFile := ChangeFileExt(FXamlPath, '.Xaml.pas');
  if SourceText(GeneratedFile) = Generated then
    Exit;
  Module := (BorlandIDEServices as IOTAModuleServices).FindModule(GeneratedFile);
  if Module <> nil then
  begin
    ApplyText(GeneratedFile, SourceText(GeneratedFile), Generated);
    Module.Save(False, True); // generated output only, user buffers stay unsaved
  end
  else
    TFile.WriteAllText(GeneratedFile, Generated, TEncoding.UTF8);
end;

function TPreviewCommand.StructureForFile(const AFile: string): IOTAStructureContext;
begin
  Result := nil;
  if not SameText(ExtractFileExt(AFile), '.xaml') then Exit;
  try
    if FIndex = nil then
      FIndex := TDesignerTypeIndex.Create(TPath.Combine(RootFolder, 'src\Generated\RADWinUI.Xaml.json'));
    if (FStructure = nil) or not SameText(FStructure.Path, AFile) then
    begin
      // This runs inside the IDE's GetStructureContext callback: the IDE replaces
      // the shown context itself, resetting its view here would reenter it
      if FStructure <> nil then FStructure.Detach(False);
      FStructure := TDesignerStructure.Create(AFile, SelectStructureElement, DesignEditAction, DesignEditState);
      FStructureContext := FStructure;
    end;
    FStructure.Provide(SourceText(AFile), FIndex);
  except
    on E: Exception do Log('Structure context failed: ' + E.ClassName + ': ' + E.Message);
  end;
  if (FStructure <> nil) and SameText(FStructure.Path, AFile) then Result := FStructureContext;
end;

procedure TPreviewCommand.SyncStructure;
var
  Xaml: string;
  Element: TXamlElement;
  Found: Boolean;
  Context: IOTAStructureContext;
begin
  if not FDesignViewActive or (FStructure = nil) or not SameText(FStructure.Path, FXamlPath) then Exit;
  try
    Context := FStructureContext; // keep it alive if a queued action changes the active editor
    (Context as TDesignerStructure).DispatchSelection;
    if not FDesignViewActive or (Context <> FStructureContext) then Exit;
    Xaml := SourceText(FXamlPath);
    if not FStructure.Update(Xaml, FIndex) then Exit;
    if (FSelection.Name <> '') and SameText(FSelectionPath, FXamlPath) then
    begin
      Found := False;
      for Element in XamlElements(Xaml) do
        if not Element.DesignOnly and (Element.Name = FSelection.Name) and (Element.Tag = FSelection.Tag) then
        begin
          FSelection.Line := Element.Line;
          FSelection.Column := Element.Column;
          Found := True;
          Break;
        end;
      if not Found then ClearSelection;
    end;
    SelectInStructure(FSelection.Line, FSelection.Column);
  except
    on E: Exception do Log('Structure refresh failed: ' + E.ClassName + ': ' + E.Message);
  end;
end;

procedure TPreviewCommand.SelectInStructure(ALine, AColumn: Integer);
var
  Context: IOTAStructureContext;
begin
  Context := FStructureContext;
  if Context = nil then Exit;
  try
    (Context as TDesignerStructure).Select(ALine, AColumn);
  except
    on E: Exception do Log('Structure selection failed: ' + E.ClassName + ': ' + E.Message);
  end;
end;

procedure TPreviewCommand.SelectStructureElement(AElement: TXamlElement; ADefault: Boolean);
var
  Reply, Event: string;
  Current: TXamlElement;
  Found: Boolean;
begin
  if not FDesignViewActive then Exit;
  if FInspector <> nil then FInspector.Commit;
  Found := False;
  for Current in XamlElements(SourceText(FXamlPath)) do
    if not Current.DesignOnly and (Current.Tag = AElement.Tag) and
      (((AElement.Name <> '') and (Current.Name = AElement.Name)) or
       ((AElement.Name = '') and (Current.Line = AElement.Line) and (Current.Column = AElement.Column))) then
    begin
      AElement := Current;
      Found := True;
      Break;
    end;
  if not Found then Exit;
  FSelection.Line := AElement.Line;
  FSelection.Column := AElement.Column;
  FSelection.Tag := AElement.Tag;
  FSelection.Name := AElement.Name;
  FSelectionPath := FXamlPath;
  if FClient <> nil then
    FClient.Request(Format('SELECTPOS %d %d', [AElement.Line, AElement.Column]), Reply);
  ShowInspector;
  SelectInStructure(FSelection.Line, FSelection.Column);
  if ADefault then
  begin
    Event := FIndex.DefaultEventOf(AElement.Tag);
    if Event <> '' then EventHandler(Event, '');
  end;
end;

{ TWindowSaveNotifier }

procedure TWindowSaveNotifier.BeforeSave;
begin
  if FCommand <> nil then FCommand.CleanupWindow(FXamlPath, FFileName);
end;

procedure TWindowSaveNotifier.Destroyed;
begin
  FIndex := -1;
  FModule := nil;
  FCommand := nil;
end;

procedure TWindowSaveNotifier.ModuleRenamed(const NewName: string);
begin
  FFileName := NewName;
  FXamlPath := ChangeFileExt(NewName, '.xaml');
end;

function TWindowSaveNotifier.CheckOverwrite: Boolean;
begin Result := True; end;

procedure TWindowSaveNotifier.Detach;
begin
  FCommand := nil;
  if (FModule <> nil) and (FIndex >= 0) then FModule.RemoveNotifier(FIndex);
  FIndex := -1;
  FModule := nil;
end;

procedure TPreviewCommand.WatchWindow(const APath: string);
var
  Path: string;
  Module: IOTAModule;
  Observer: TWindowSaveNotifier;
  Intf: IOTAModuleNotifier;
  I: Integer;
  Found: Boolean;
begin
  for Path in [APath, ChangeFileExt(APath, '.pas')] do
  begin
    Module := (BorlandIDEServices as IOTAModuleServices).FindModule(Path);
    if Module = nil then Continue;
    Found := False;
    for I := 0 to FSaveNotifiers.Count - 1 do
      if (FSaveNotifiers[I] as TWindowSaveNotifier).FModule = Module then
      begin
        Found := True;
        Break;
      end;
    if Found then Continue;
    Observer := TWindowSaveNotifier.Create;
    Intf := Observer;
    Observer.FCommand := Self;
    Observer.FModule := Module;
    Observer.FXamlPath := APath;
    Observer.FFileName := Path;
    Observer.FIndex := Module.AddNotifier(Intf);
    FSaveNotifiers.Add(Intf);
  end;
end;

procedure TPreviewCommand.CleanupWindow(const APath, ASaving: string);
var
  Xaml, Pas, UpdatedXaml, UpdatedPas, PasFile, Companion: string;
  Module, SavingModule: IOTAModule;
begin
  if FCleaning then Exit;
  FCleaning := True;
  try
    try
      Xaml := SourceText(APath);
      PasFile := ChangeFileExt(APath, '.pas');
      Pas := SourceText(PasFile);
      if (Xaml = '') or (Pas = '') then Exit;
      if FIndex = nil then
        FIndex := TDesignerTypeIndex.Create(TPath.Combine(RootFolder, 'src\Generated\RADWinUI.Xaml.json'));
      UpdatedXaml := Xaml;
      UpdatedPas := Pas;
      if not CleanupEmptyHandlers(UpdatedXaml, UpdatedPas, FIndex) then Exit;
      // Remove assignments first: a failed Pascal edit leaves an unused method,
      // rather than an assignment to a method that no longer exists.
      ApplyText(APath, Xaml, UpdatedXaml);
      ApplyText(PasFile, Pas, UpdatedPas);
      Log('removed empty event handlers on save: ' + APath);
      if SameText(ASaving, PasFile) then Companion := APath else Companion := PasFile;
      Module := (BorlandIDEServices as IOTAModuleServices).FindModule(Companion);
      SavingModule := (BorlandIDEServices as IOTAModuleServices).FindModule(ASaving);
      if (Module <> nil) and (Module <> SavingModule) and
        (Module.CurrentEditor <> nil) and Module.CurrentEditor.Modified then
        Module.Save(False, True);
    except
      on E: Exception do Log('empty event cleanup: ' + E.ClassName + ': ' + E.Message);
    end;
  finally
    FCleaning := False;
  end;
end;

{ TCompileNotifier }

procedure TCompileNotifier.FileNotification(NotifyCode: TOTAFileNotification; const FileName: string;
  var Cancel: Boolean);
begin
  if (NotifyCode = ofnFileOpened) and SameText(ExtractFileExt(FileName), '.xaml') and (Command <> nil) then
    Command.OpenInDesign(FileName);
end;

procedure TCompileNotifier.BeforeCompile(const Project: IOTAProject; var Cancel: Boolean);
begin
end;

procedure TCompileNotifier.AfterCompile(Succeeded: Boolean);
begin
end;

procedure TCompileNotifier.BeforeCompile(const Project: IOTAProject; IsCodeInsight: Boolean; var Cancel: Boolean);
var
  Modules: IOTAModuleServices;
  Module: IOTAModule;
  I: Integer;
  FileName: string;
begin
  if IsCodeInsight then
    Exit;
  try
    Modules := BorlandIDEServices as IOTAModuleServices;
    for I := 0 to Modules.ModuleCount - 1 do
    begin
      Module := Modules.Modules[I];
      FileName := Module.FileName;
      // A .xaml, or the unit of a window (MainWindow.pas next to MainWindow.xaml)
      if (SameText(ExtractFileExt(FileName), '.xaml') or
        (SameText(ExtractFileExt(FileName), '.pas') and FileExists(ChangeFileExt(FileName, '.xaml')))) and
        (Module.CurrentEditor <> nil) and Module.CurrentEditor.Modified then
      begin
        Log('saving before compile: ' + FileName);
        Module.Save(False, True);
      end;
    end;
  except
    on E: Exception do
      Log('saving before compile failed: ' + E.Message);
  end;
end;

procedure TCompileNotifier.AfterCompile(Succeeded: Boolean; IsCodeInsight: Boolean);
begin
  if not IsCodeInsight and (Command <> nil) then Command.CompilationFinished;
end;

{ TDesignerKeyBinding }

constructor TDesignerKeyBinding.Create(ACommand: TPreviewCommand);
begin
  inherited Create;
  FCommand := ACommand;
end;

function TDesignerKeyBinding.GetBindingType: TBindingType;
begin
  Result := btPartial;
end;

function TDesignerKeyBinding.GetDisplayName: string;
begin
  Result := 'RADWinUI Code/Design';
end;

function TDesignerKeyBinding.GetName: string;
begin
  Result := 'RADWinUI.CodeDesign';
end;

procedure TDesignerKeyBinding.BindKeyboard(const BindingServices: IOTAKeyBindingServices);
begin
  BindingServices.AddKeyBinding([VK_F12], KeyPressed, nil, 0);
end;

procedure TDesignerKeyBinding.KeyPressed(const Context: IOTAKeyContext; KeyCode: TShortcut;
  var BindingResult: TKeyBindingResult);
var
  FileName: string;
begin
  BindingResult := krUnhandled;
  FileName := '';
  if (Context <> nil) and (Context.EditBuffer <> nil) then
    FileName := Context.EditBuffer.FileName;
  if (FCommand <> nil) and FCommand.ToggleCodeDesignForFile(FileName) then
    BindingResult := krHandled;
end;

{ TPreviewDock }

function TPreviewDock.GetCaption: string;
begin
  Result := 'RADWinUI Docked Preview';
end;

function TPreviewDock.GetIdentifier: string;
begin
  Result := 'RADWinUIDockedPreview';
end;

function TPreviewDock.GetFrameClass: TCustomFrameClass;
begin
  Result := TFrame;
end;

procedure TPreviewDock.FrameCreated(AFrame: TCustomFrame);
begin
  if Command <> nil then
    Command.PreviewFrameCreated(AFrame);
end;

function TPreviewDock.GetMenuActionList: TCustomActionList;
begin
  Result := nil;
end;

function TPreviewDock.GetMenuImageList: TCustomImageList;
begin
  Result := nil;
end;

procedure TPreviewDock.CustomizePopupMenu(PopupMenu: TPopupMenu);
begin
end;

function TPreviewDock.GetToolBarActionList: TCustomActionList;
begin
  Result := nil;
end;

function TPreviewDock.GetToolBarImageList: TCustomImageList;
begin
  Result := nil;
end;

procedure TPreviewDock.CustomizeToolBar(ToolBar: TToolBar);
begin
end;

procedure TPreviewDock.SaveWindowState(Desktop: TCustomIniFile; const Section: string; IsProject: Boolean);
begin
end;

procedure TPreviewDock.LoadWindowState(Desktop: TCustomIniFile; const Section: string);
begin
end;

function TPreviewDock.GetEditState: TEditState;
begin
  Result := [];
end;

function TPreviewDock.EditAction(Action: TEditAction): Boolean;
begin
  Result := False;
end;

{ TDesignPanel }

procedure TDesignPanel.CMShowingChanged(var Message: TMessage);
begin
  inherited;
  if not (csDestroying in ComponentState) and Assigned(FOnShowingChanged) then
    FOnShowingChanged(Self);
end;

{ TDesignSubview }

constructor TDesignSubview.Create(ACommand: TPreviewCommand);
begin
  inherited Create;
  FCommand := ACommand;
end;

function TDesignSubview.GetCanCloneView: Boolean;
begin
  Result := False;
end;

function TDesignSubview.GetCaption: string;
begin
  Result := 'Design';
end;

function TDesignSubview.GetPriority: Integer;
begin
  Result := svpHigh;
end;

function TDesignSubview.GetViewIdentifier: string;
begin
  Result := 'RADWinUI.Xaml.Design';
end;

procedure TDesignSubview.Display(const AContext: IInterface; AViewObject: TObject);
begin
  try
    FCommand.DesignViewDisplayed(AContext, AViewObject);
  except
    on E: Exception do FCommand.DesignFailure('Display', E.ClassName + ': ' + E.Message);
  end;
end;

function TDesignSubview.EditAction(const AContext: IInterface; Action: TEditAction; AViewObject: TObject): Boolean;
begin
  Result := (AContext <> nil) and FCommand.DesignEditAction(Action);
end;

function TDesignSubview.GetEditState(const AContext: IInterface; AViewObject: TObject): TEditState;
begin
  Result := [];
  if AContext <> nil then
    Result := FCommand.DesignEditState;
end;

function TDesignSubview.Handles(const AContext: IInterface): Boolean;
var
  Services: IOTAEditorViewServices;
  FileName: string;
begin
  Result := False;
  if AContext = nil then Exit;
  try
    Result := Supports(BorlandIDEServices, IOTAEditorViewServices, Services) and
      Services.ContextToFilename(AContext, FileName) and SameText(ExtractFileExt(FileName), '.xaml');
  except
    on E: Exception do Log('Design context failed: ' + E.ClassName + ': ' + E.Message);
  end;
end;

procedure TDesignSubview.Hide(const AContext: IInterface; AViewObject: TObject);
begin
end;

procedure TDesignSubview.ViewClosed(const AContext: IInterface; AViewObject: TObject);
begin
  try
    FCommand.DesignViewClosed(AViewObject);
  except
    on E: Exception do FCommand.DesignFailure('ViewClosed', E.ClassName + ': ' + E.Message);
  end;
end;

function TDesignSubview.GetFrameClass: TCustomFrameClass;
begin
  Result := TFrame;
end;

procedure TDesignSubview.FrameCreated(AFrame: TCustomFrame);
begin
  try
    FCommand.DesignFrameCreated(AFrame);
  except
    on E: Exception do FCommand.DesignFailure('FrameCreated', E.ClassName + ': ' + E.Message);
  end;
end;

function TDesignSubview.GetStructureContext(const AContext: IInterface; AViewObject: TObject): IOTAStructureContext;
var
  FileName: string;
begin
  Result := nil;
  try
    if (AContext <> nil) and
      (BorlandIDEServices as IOTAEditorViewServices).ContextToFilename(AContext, FileName) then
      Result := FCommand.StructureForFile(FileName);
  except
    on E: Exception do Log('Structure callback failed: ' + E.ClassName + ': ' + E.Message);
  end;
end;

function TDesignSubview.GetStructureType(const AContext: IInterface; AViewObject: TObject): WideString;
begin
  Result := RADWinUIStructureType;
end;

{ TRADWinUIPaletteItem }

constructor TRADWinUIPaletteItem.Create(ACommand: TPreviewCommand; const AName, ARuntimeName, ADisplayName: string);
begin
  inherited Create;
  FCommand := ACommand;
  FName := AName;
  FDisplayName := ADisplayName;
  FRuntimeName := ARuntimeName;
  FIDString := 'RADWinUI.' + ARuntimeName;
  FHintText := ARuntimeName;
  FHelpName := ARuntimeName;
  FImageIndex := 0; // use the IDE's first shared icon, -1 crashed its collection lookup
  FVisible := False;
  FEnabled := True;
end;

function TRADWinUIPaletteItem.GetCanDelete: Boolean;
begin
  Result := False;
end;

function TRADWinUIPaletteItem.GetEnabled: Boolean;
begin
  Result := FEnabled;
end;

function TRADWinUIPaletteItem.GetHelpName: string;
begin
  Result := FHelpName;
end;

function TRADWinUIPaletteItem.GetHintText: string;
begin
  Result := FHintText;
end;

function TRADWinUIPaletteItem.GetIDString: string;
begin
  Result := FIDString;
end;

function TRADWinUIPaletteItem.GetName: string;
begin
  Result := FDisplayName;
end;

function TRADWinUIPaletteItem.GetVisible: Boolean;
begin
  Result := FVisible;
end;

function TRADWinUIPaletteItem.GetImageIndex: Integer;
begin
  Result := FImageIndex;
end;

procedure TRADWinUIPaletteItem.SetEnabled(Value: Boolean);
begin
  FEnabled := Value;
end;

procedure TRADWinUIPaletteItem.SetHelpName(const Value: string);
begin
  FHelpName := Value;
end;

procedure TRADWinUIPaletteItem.SetName(const Value: string);
begin
  FName := Value;
end;

procedure TRADWinUIPaletteItem.SetVisible(const Value: Boolean);
begin
  FVisible := Value;
end;

procedure TRADWinUIPaletteItem.SetHintText(const Value: string);
begin
  FHintText := Value;
end;

procedure TRADWinUIPaletteItem.SetImageIndex(const Value: Integer);
begin
  FImageIndex := Value;
end;

procedure TRADWinUIPaletteItem.Paint(const Canvas: TCanvas; const X, Y: Integer; const IconSize: TNTAPaintIconSize);
begin
  Paint(Canvas, X, Y, IconSize, FEnabled);
end;

procedure TRADWinUIPaletteItem.Paint(const Canvas: TCanvas; const X, Y: Integer; const IconSize: TNTAPaintIconSize;
  Enabled: Boolean);
begin
  try
    DrawPaletteIcon(Canvas, X, Y, cNTAPaintIconSizes[IconSize], FName, Enabled);
  except
    on E: Exception do
      Log('palette icon ' + FName + ': ' + E.Message); // never let painting disturb the palette
  end;
end;

procedure TRADWinUIPaletteItem.Execute;
begin
  if FCommand <> nil then
    FCommand.SelectPaletteItem(FName);
end;

procedure TRADWinUIPaletteItem.Delete;
begin
end;

function TRADWinUIPaletteItem.GetFormatRec: TFormatEtc;
begin
  Result := Default(TFormatEtc);
  Result.cfFormat := CF_UNICODETEXT;
  Result.dwAspect := DVASPECT_CONTENT;
  Result.lindex := -1;
  Result.tymed := TYMED_HGLOBAL;
end;

function TRADWinUIPaletteItem.QueryGetData(const SourceFormat: TFormatEtc): Boolean;
begin
  Result := (SourceFormat.cfFormat = CF_UNICODETEXT) and
    (SourceFormat.dwAspect = DVASPECT_CONTENT) and (SourceFormat.lindex = -1) and
    ((SourceFormat.tymed and TYMED_HGLOBAL) <> 0);
end;

function TRADWinUIPaletteItem.GetData(const SourceFormat: TFormatEtc; out Medium: TStgMedium): Boolean;
var
  Text: string;
  Data: Pointer;
begin
  Medium := Default(TStgMedium);
  Result := QueryGetData(SourceFormat);
  if not Result then
    Exit;
  Text := 'RADWinUI.Component:' + FName;
  Log('palette OLE drag: ' + FName);
  Medium.hGlobal := GlobalAlloc(GMEM_MOVEABLE or GMEM_ZEROINIT, (Length(Text) + 1) * SizeOf(Char));
  if Medium.hGlobal = 0 then
    Exit(False);
  Data := GlobalLock(Medium.hGlobal);
  if Data = nil then
  begin
    GlobalFree(Medium.hGlobal);
    Medium := Default(TStgMedium);
    Exit(False);
  end;
  Move(PChar(Text)^, Data^, Length(Text) * SizeOf(Char));
  GlobalUnlock(Medium.hGlobal);
  Medium.tymed := TYMED_HGLOBAL;
end;

{ TFreeWatch }

constructor TFreeWatch.Create(ACommand: TPreviewCommand);
begin
  inherited Create(nil);
  FCommand := ACommand;
end;

procedure TFreeWatch.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (FCommand <> nil) then
    FCommand.Freed(AComponent);
end;

const
  XamlEditOptionsID = 'RADWinUI.EditOptions.Xaml';

/// .xaml files get the IDE's own XML colouring through a "XAML" file type in the editor
/// options: the user's XML settings stay untouched, and a .xaml mapping the
/// user made to another file type is kept.
procedure RegisterXamlEditOptions;
var
  Services: IOTAEditorServices;
  Current, Xml, Xaml: IOTAEditOptions;
  Created: Boolean;
begin
  try
    if not Supports(BorlandIDEServices, IOTAEditorServices, Services) then
      Exit;
    Current := Services.GetEditOptionsForFile('Window.xaml');
    if (Current <> nil) and (Current.IDString <> cDefEdDefault) and (Current.IDString <> XamlEditOptionsID) then
    begin
      Log('XAML editor colouring: .xaml already uses ' + Current.IDString);
      Exit;
    end;
    Xml := Services.GetEditOptions(cDefEdXML);
    if (Xml = nil) or (Xml.SyntaxHighlighter = nil) then
    begin
      Log('XAML editor colouring: the IDE has no XML highlighter');
      Exit;
    end;
    Created := Services.GetEditOptions(XamlEditOptionsID) = nil;
    Xaml := Services.AddEditOptions(XamlEditOptionsID);
    Xaml.OptionsName := 'XAML';
    Xaml.Extensions := 'xaml';
    Xaml.SyntaxHighlighter := Xml.SyntaxHighlighter;
    if Created then
      Xaml.BlockIndent := Xml.BlockIndent; // later changes in Tools > Options stay the user's
    Log('XAML editor colouring: ' + Xml.SyntaxHighlighter.Name);
  except
    on E: Exception do
      Log('XAML editor colouring failed: ' + E.ClassName + ': ' + E.Message);
  end;
end;

{ TPreviewCommand }

constructor TPreviewCommand.Create;
var
  Keys: IOTAKeyboardServices;
begin
  inherited;
  FSaveNotifiers := TInterfaceList.Create;
  FPaletteItems := TInterfaceList.Create;
  FPaletteGroups := TInterfaceList.Create;
  FDesignSurfaces := TList.Create;
  FKeyBinding := -1;
  FAction := TAction.Create(nil);
  FAction.Caption := 'RADWinUI Preview';
  FAction.Hint := 'Shows the XAML of the active RADWinUI window, live, in its own window';
  FAction.Category := 'Tools';
  FAction.OnExecute := Execute;
  FAction.OnUpdate := Update; // disabled, never hidden, when there is nothing to preview
  FAction.ActionList := (BorlandIDEServices as INTAServices).ActionList;
  FItem := TMenuItem.Create(nil);
  FItem.Action := FAction;
  FDockedAction := TAction.Create(nil);
  FDockedAction.Caption := 'RADWinUI Docked Preview';
  FDockedAction.Hint := 'Shows the active RADWinUI window in a dockable IDE panel';
  FDockedAction.Category := 'Tools';
  FDockedAction.OnExecute := ExecuteDocked;
  FDockedAction.OnUpdate := Update;
  FDockedAction.ActionList := (BorlandIDEServices as INTAServices).ActionList;
  FDockedItem := TMenuItem.Create(nil);
  FDockedItem.Action := FDockedAction;
  FInspector := TNativeObjectInspector.Create(PropertyChange, EventHandler, EventCleared, SelectStructureElement,
    procedure(AError: string)
    begin
      Log('Object Inspector ' + AError);
    end);
  FWatch := TFreeWatch.Create(Self);
  FPreviewDock := TPreviewDock.Create;
  (BorlandIDEServices as INTAServices).RegisterDockableForm(FPreviewDock);
  FNotifier := (BorlandIDEServices as IOTAServices).AddNotifier(TCompileNotifier.Create);
  FTimer := TTimer.Create(nil);
  FTimer.Enabled := False;
  FTimer.Interval := 150; // edits reach the preview within about 150 ms
  FTimer.OnTimer := Tick;
  FApplicationEvents := TApplicationEvents.Create(nil);
  FApplicationEvents.OnMessage := ApplicationMessage;
  // The main menu may not be complete while packages load: retry for a minute
  FMenuTimer := TTimer.Create(nil);
  FMenuTimer.Interval := 1000;
  FMenuTimer.OnTimer := AddToMenu;
  AddToMenu(nil);
  RegisterPalette;
  FDesignView := TDesignSubview.Create(Self);
  FDesignViewRegistration := (BorlandIDEServices as IOTAEditorViewServices).RegisterEditorSubView(FDesignView);
  RegisterXamlEditOptions;
  if Supports(BorlandIDEServices, IOTAKeyboardServices, Keys) then
    FKeyBinding := Keys.AddKeyboardBinding(TDesignerKeyBinding.Create(Self));
end;

procedure TPreviewCommand.AddToMenu(Sender: TObject);
begin
  Inc(FMenuTries);
  FMenuTimer.Enabled := not (InsertIntoToolsMenu((BorlandIDEServices as INTAServices).MainMenu, FDockedItem) and
    InsertIntoToolsMenu((BorlandIDEServices as INTAServices).MainMenu, FItem)) and (FMenuTries < 60);
end;

const
  OldPaletteGroup = 'RADWinUI.Components'; // the single flat category of older versions

/// The IDE's ID of a RADWinUI palette category ('RADWinUI.Palette.DateandTime').
function PaletteGroupID(const ACategory: string): string;
begin
  Result := 'RADWinUI.Palette.' + StringReplace(ACategory, ' ', '', [rfReplaceAll]);
end;

/// The Tool Palette: the curated categories and controls of RADWinUI.Designer.Palette,
/// shown as TWinUI<Name> with their own icons. Names, runtime classes and wrapper
/// names come from RADWinUI.Xaml.json, so a control the metadata lacks is left out.
procedure TPreviewCommand.RegisterPalette;
var
  Json: TJSONValue;
  Entries: TJSONArray;
  Classes: TJSONObject;
  Runtime: TStringList;
  Group: IOTAPaletteGroup;
  Item: IOTABasePaletteItem;
  Entry: TPaletteEntry;
  Category, RuntimeName, Wrapper, Path, Stage: string;
  I: Integer;
begin
  if not Supports(BorlandIDEServices, IOTAPaletteServices, FPaletteServices) then
    Exit;
  Path := TPath.Combine(RootFolder, 'src\Generated\RADWinUI.Xaml.json');
  if not FileExists(Path) then
    Exit;
  Json := TJSONObject.ParseJSONValue(TFile.ReadAllText(Path, TEncoding.UTF8));
  if Json = nil then
    Exit;
  Runtime := TStringList.Create;
  try
    try
      Entries := (Json as TJSONObject).GetValue('palette') as TJSONArray;
      Classes := (Json as TJSONObject).GetValue('classes') as TJSONObject;
      if (Entries = nil) or (Classes = nil) then
        Exit;
      for I := 0 to Entries.Count - 1 do
        Runtime.Values[(Entries.Items[I] as TJSONObject).GetValue<string>('name', '')] :=
          (Entries.Items[I] as TJSONObject).GetValue<string>('runtime', '');
      Stage := 'categories';
      FPaletteServices.BeginUpdate;
      try
        RemovePaletteGroup(OldPaletteGroup); // a desktop or an older package may have kept it
        FPaletteServices.ImageCollection.Images.BeginUpdate;
        try
          Category := '';
          Group := nil;
          for Entry in PaletteEntries do
          begin
            RuntimeName := Runtime.Values[Entry.Name];
            if RuntimeName = '' then
              Continue;
            if Entry.Category <> Category then
            begin
              Category := Entry.Category;
              Stage := Category;
              RemovePaletteGroup(PaletteGroupID(Category));
              Group := FPaletteServices.BaseGroup.AddGroup('RADWinUI ' + Category, PaletteGroupID(Category));
              FPaletteGroups.Add(Group);
              FPaletteServices.ItemAdded(FPaletteServices.BaseGroup, Group as IOTABasePaletteItem);
            end;
            Stage := Entry.Name;
            // The wrapper class Pascal code uses for it (TWinUIButton), like VCL's TButton
            Wrapper := 'TWinUI' + Entry.Name;
            if Classes.GetValue(RuntimeName) is TJSONObject then
              Wrapper := (Classes.GetValue(RuntimeName) as TJSONObject).GetValue<string>('wrapper', Wrapper);
            Item := TRADWinUIPaletteItem.Create(Self, Entry.Name, RuntimeName, Wrapper);
            Item.ImageIndex := PaletteIcon(FPaletteServices.ImageCollection, Entry.Name);
            Group.AddItem(Item);
            FPaletteItems.Add(Item);
            FPaletteServices.ItemAdded(Group, Item);
          end;
        finally
          FPaletteServices.ImageCollection.Images.EndUpdate;
        end;
      finally
        FPaletteServices.EndUpdate;
      end;
      Log(Format('Tool Palette registered %d RADWinUI controls in %d categories',
        [FPaletteItems.Count, FPaletteGroups.Count]));
    except
      on E: Exception do
      begin
        Log('Tool Palette registration failed at ' + Stage + ': ' + E.ClassName + ': ' + E.Message);
        UnregisterPalette;
      end;
    end;
  finally
    Runtime.Free;
    Json.Free;
  end;
end;

/// Removes the palette group with AID and its items, when the IDE has it.
procedure TPreviewCommand.RemovePaletteGroup(const AID: string);
var
  RootItem: IOTABasePaletteItem;
begin
  RootItem := FPaletteServices.BaseGroup.FindItem(AID, False);
  if RootItem <> nil then
  begin
    FPaletteServices.ItemRemoved(FPaletteServices.BaseGroup, RootItem);
    FPaletteServices.BaseGroup.RemoveItem(RootItem.IDString, False);
  end;
end;

procedure TPreviewCommand.UnregisterPalette;
var
  Group: IOTAPaletteGroup;
  Item: IOTABasePaletteItem;
  Category: string;
  I: Integer;
begin
  if FPaletteServices <> nil then
  begin
    try
      SetPaletteDesignerActive(False);
      FPaletteServices.BeginUpdate;
      try
        Item := FPaletteServices.SelectedTool;
        if (Item <> nil) and (FPaletteItems.IndexOf(Item) >= 0) then
          FPaletteServices.SelectedTool := nil;
        for I := 0 to FPaletteItems.Count - 1 do
        begin
          Item := FPaletteItems[I] as IOTABasePaletteItem;
          Group := FPaletteServices.BaseGroup.FindItemGroup(Item.IDString);
          if Group <> nil then
          begin
            FPaletteServices.ItemRemoved(Group, Item);
            Group.RemoveItem(Item.IDString, False);
          end;
        end;
        for Category in PaletteCategories do
          RemovePaletteGroup(PaletteGroupID(Category));
        RemovePaletteGroup(OldPaletteGroup);
        FPaletteServices.Modified;
      finally
        FPaletteServices.EndUpdate;
      end;
    except
      on E: Exception do
        Log('Tool Palette cleanup failed: ' + E.ClassName + ': ' + E.Message);
    end;
  end;
  if FPaletteItems <> nil then
    FPaletteItems.Clear;
  if FPaletteGroups <> nil then
    FPaletteGroups.Clear;
  FPaletteServices := nil;
end;

procedure TPreviewCommand.SetPaletteDesignerActive(AActive: Boolean);
var
  I: Integer;
  Item: IOTABasePaletteItem;
begin
  if (FPaletteServices = nil) or (FPaletteStateActive = AActive) then
    Exit;
  if AActive then
    FPaletteServices.AddPaletteDesignerState('RADWinUI')
  else
    FPaletteServices.RemovePaletteState('RADWinUI');
  FPaletteStateActive := AActive;
  for I := 0 to FPaletteItems.Count - 1 do
  begin
    Item := FPaletteItems[I] as IOTABasePaletteItem;
    Item.Visible := AActive;
  end;
  FPaletteServices.Modified;
end;

procedure TPreviewCommand.SelectPaletteItem(const AName: string);
var
  Reply: string;
begin
  if FDesignViewActive and (FClient <> nil) and FClient.Request('ADD ' + AName, Reply) then
    Log('palette execute ' + AName + ': ' + Reply);
end;

procedure TPreviewCommand.Update(Sender: TObject);
var
  Buffer: IOTAEditBuffer;
begin
  Buffer := (BorlandIDEServices as IOTAEditorServices).TopBuffer;
  FAction.Enabled := (FClient <> nil) or (FXamlPath <> '') or ((Buffer <> nil) and (XamlOf(Buffer.FileName) <> ''));
  FDockedAction.Enabled := FAction.Enabled;
end;

destructor TPreviewCommand.Destroy;
var
  Keys: IOTAKeyboardServices;
  I: Integer;
begin
  FreeAndNil(FApplicationEvents);
  FreeAndNil(FInspector); // detach retained native editors before command teardown
  Stop;
  for I := 0 to FSaveNotifiers.Count - 1 do
    (FSaveNotifiers[I] as TWindowSaveNotifier).Detach;
  FreeAndNil(FSaveNotifiers);
  if FStructure <> nil then FStructure.Detach;
  if (FKeyBinding >= 0) and Supports(BorlandIDEServices, IOTAKeyboardServices, Keys) then
    Keys.RemoveKeyboardBinding(FKeyBinding);
  FKeyBinding := -1;
  UnregisterPalette;
  (BorlandIDEServices as IOTAServices).RemoveNotifier(FNotifier);
  if FDesignViewRegistration <> nil then
    (BorlandIDEServices as IOTAEditorViewServices).UnregisterEditorSubView(FDesignViewRegistration);
  FDesignViewRegistration := nil;
  FDesignView := nil;
  FStructure := nil;
  FStructureContext := nil;
  // Also release frames prepared in the background before this package unloads.
  while (FDesignSurfaces <> nil) and (FDesignSurfaces.Count > 0) do
    TObject(FDesignSurfaces.Last).Free;
  FreeAndNil(FDesignSurfaces);
  FreeAndNil(FPaletteItems);
  FreeAndNil(FPaletteGroups);
  (BorlandIDEServices as INTAServices).UnregisterDockableForm(FPreviewDock);
  FPreviewDock := nil;
  FreeAndNil(FPreviewDockForm);
  FWatch.FCommand := nil;
  FWatch.Free;
  FDockedItem.Free;
  FDockedAction.Free;
  FIndex.Free;
  FMenuTimer.Free;
  FTimer.Free;
  FItem.Free;
  FAction.Free;
  inherited;
end;

procedure TPreviewCommand.Stop;
begin
  if (FInspector <> nil) and (FClient <> nil) then
    FInspector.Commit; // a value still being typed belongs to the element still selected
  if FInspector <> nil then FInspector.Clear;
  FTimer.Enabled := False;
  FreeAndNil(FClient); // closing the pipe ends the host
  FDocked := False;
  FParentWindow := 0;
  FThemeMessage := '';
  FThemePid := 0;
  FLastClientStatus := '';
end;

procedure TPreviewCommand.CompilationFinished;
begin
  if FClient <> nil then FClient.Resume;
end;

procedure TPreviewCommand.SyncTheme;
var
  Background, RGB: TColor;
  Theme, Request, Reply: string;
  Theming: IOTAIDEThemingServices;
  HostPid: DWORD;
begin
  if (FClient = nil) or FClient.Closing or FClient.Closed or FClient.Failed then
    Exit;
  Background := StyleServices.GetStyleColor(scWindow);
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, Theming) then
    Background := Theming.StyleServices.GetStyleColor(scWindow);
  if FDesignSurface <> nil then
    FDesignSurface.Color := Background;
  if FPreviewSurface <> nil then
    FPreviewSurface.Color := Background;
  RGB := ColorToRGB(Background);
  if GetRValue(RGB) * 299 + GetGValue(RGB) * 587 + GetBValue(RGB) * 114 < 128000 then
    Theme := 'Dark'
  else
    Theme := 'Light';
  Request := 'THEME ' + Theme + ' #FF' + IntToHex(GetRValue(RGB), 2) +
    IntToHex(GetGValue(RGB), 2) + IntToHex(GetBValue(RGB), 2);
  HostPid := GetProcessId(FClient.HostProcess);
  if HostPid <> FThemePid then
  begin
    FThemePid := HostPid;
    FThemeMessage := '';
  end;
  if Request = FThemeMessage then
    Exit;
  if FClient.Request(Request, Reply) then
  begin
    FThemeMessage := Request;
    if (Reply <> 'OK') and (Reply <> 'QUEUED') then
      Log('preview theme rejected: ' + Reply);
  end;
end;

procedure TPreviewCommand.ShowXamlCode;
var
  Editor: IOTASourceEditor;
begin
  if not FileExists(FXamlPath) then
    Exit;
  Log('Design to Code: ' + FXamlPath);
  Editor := EditorOf(FXamlPath);
  Editor.SwitchToView(0);
  // Show after selecting Code: focus leaves the foreign child HWND, without
  // briefly redisplaying Design as Show-before-Switch could do.
  Editor.Show;
end;

function TPreviewCommand.ShowDesignForFile(const AFile: string): Boolean;
var
  Xaml: string;
  Editor: IOTASourceEditor;
  Buffer: IOTAEditBuffer;
  I: Integer;
begin
  Result := False;
  Xaml := XamlOf(AFile);
  if Xaml = '' then
    Exit;
  Editor := EditorOf(Xaml);
  Buffer := (BorlandIDEServices as IOTAEditorServices).TopBuffer;
  if (Buffer = nil) or not SameText(Buffer.FileName, Xaml) then
    Editor.Show;
  for I := 0 to Editor.GetSubViewCount - 1 do
    if Editor.GetSubViewIdentifier(I) = 'RADWinUI.Xaml.Design' then
    begin
      Editor.SwitchToView(I);
      Exit(True);
    end;
end;

procedure TPreviewCommand.OpenInDesign(const AFile: string);
begin
  // Queued: the editor and its Design subview exist only once the open has completed
  TThread.ForceQueue(nil,
    procedure
    var
      Buffer: IOTAEditBuffer;
      Elements: TArray<TXamlElement>;
    begin
      if Command <> Self then
        Exit;
      try
        // Only the file the user is looking at: a restored desktop keeps background tabs as they are
        Buffer := (BorlandIDEServices as IOTAEditorServices).TopBuffer;
        if (Buffer = nil) or not SameText(Buffer.FileName, AFile) then
          Exit;
        // Only RADWinUI windows, a resource dictionary or other XAML stays in Code
        Elements := XamlElements(SourceText(AFile));
        if (Length(Elements) > 0) and (Elements[0].Tag = 'Window') and ShowDesignForFile(AFile) then
          Log('Opened in Design: ' + AFile);
      except
        on E: Exception do
          Log('Open in Design skipped for ' + AFile + ': ' + E.ClassName + ': ' + E.Message);
      end;
    end);
end;

function TPreviewCommand.ToggleCodeDesignForFile(const AFile: string): Boolean;
begin
  Result := FDesignViewActive;
  if Result then
    ShowXamlCode
  else
    Result := ShowDesignForFile(AFile);
end;

procedure TPreviewCommand.ApplicationMessage(var Msg: TMsg; var Handled: Boolean);
begin
  // OTA keyboard bindings cover source editors. A custom Design frame or an
  // inspector can have focus without an IOTAKeyContext/EditBuffer.
  if not Handled and FDesignViewActive and (Application.ModalLevel = 0) and (Msg.message = WM_KEYDOWN) and
    (Msg.wParam = VK_F12) and (GetKeyState(VK_CONTROL) >= 0) and
    (GetKeyState(VK_SHIFT) >= 0) and (GetKeyState(VK_MENU) >= 0) then
  begin
    Handled := True;
    Log('F12: Design to Code (IDE message)');
    ShowXamlCode;
  end;
  if not Handled and FDesignViewActive and (Application.ModalLevel = 0) and (Msg.message = WM_KEYDOWN) and
    (Msg.wParam = VK_F9) and (GetKeyState(VK_SHIFT) >= 0) and (GetKeyState(VK_MENU) >= 0) then
  begin
    Handled := True;
    if (Msg.lParam and $40000000) = 0 then BuildShortcut(GetKeyState(VK_CONTROL) < 0);
  end;
end;

function TPreviewCommand.BuildShortcut(ACompile: Boolean): Boolean;
var
  Actions: TCustomActionList;
  Action: TCustomAction;
  Key: TShortCut;
  I: Integer;
begin
  Result := False;
  if Application.ModalLevel <> 0 then Exit;
  if ACompile then Key := ShortCut(VK_F9, [ssCtrl]) else Key := ShortCut(VK_F9, []);
  Actions := (BorlandIDEServices as INTAServices).ActionList;
  for I := 0 to Actions.ActionCount - 1 do
    if Actions.Actions[I] is TCustomAction then
    begin
      Action := TCustomAction(Actions.Actions[I]);
      if (Action.ShortCut <> Key) and (Action.SecondaryShortCuts.IndexOfShortCut(Key) < 0) then Continue;
      Action.Update;
      if not Action.Enabled then Continue;
      if FInspector <> nil then FInspector.Commit;
      Log('Design shortcut: ' + Action.Name);
      Result := Action.Execute;
      Exit;
    end;
end;

/// The .xaml to preview: the active editor's window, else the active project's MainWindow.xaml,
/// else its only .xaml, '' when there is none.
function TPreviewCommand.FindXaml: string;
var
  Buffer: IOTAEditBuffer;
  Project: IOTAProject;
  Files: TArray<string>;
begin
  if FDesignViewActive and FileExists(FXamlPath) then
    Exit(FXamlPath);
  Buffer := (BorlandIDEServices as IOTAEditorServices).TopBuffer;
  if Buffer <> nil then
  begin
    Result := XamlOf(Buffer.FileName);
    if Result <> '' then
      Exit;
  end;
  Result := '';
  Project := GetActiveProject;
  if Project = nil then
    Exit;
  Result := TPath.Combine(ExtractFilePath(Project.FileName), 'MainWindow.xaml');
  if FileExists(Result) then
    Exit;
  Files := TDirectory.GetFiles(ExtractFilePath(Project.FileName), '*.xaml');
  if Length(Files) = 1 then
    Result := Files[0]
  else
    Result := '';
end;

procedure TPreviewCommand.Execute(Sender: TObject);
begin
  RunPreview(False);
end;

procedure TPreviewCommand.ExecuteDocked(Sender: TObject);
begin
  RunPreview(True);
end;

procedure TPreviewCommand.RunPreview(ADocked: Boolean);
var
  Exe, Xaml: string;
  ParentWindow: HWND;
begin
  FDesignRestartPending := False;
  Xaml := FindXaml;
  Log('Tools > RADWinUI ' + IfThen(ADocked, 'Docked Preview: ', 'Preview: ') +
    IfThen(Xaml = '', '(no .xaml found)', Xaml));
  if Xaml = '' then
  begin
    MessageDlg('RADWinUI Preview: no window to show. Open a RADWinUI window (its .xaml or its .pas unit), ' +
      'or a RADWinUI project with a MainWindow.xaml.', mtInformation, [mbOK], 0);
    Exit;
  end;
  FXamlPath := Xaml;
  ParentWindow := 0;
  if ADocked then
    if FDesignViewActive then
    begin
      if FDesignSurface = nil then
        Exit;
      ParentWindow := FDesignSurface.Handle;
    end
    else
    begin
      if not ShowPreviewDock then
        Exit;
      ParentWindow := FPreviewSurface.Handle;
    end;
  if (FClient <> nil) and (FClient.Closing or FClient.Closed or FClient.Failed) then
  begin
    Log('the previous preview is closing: starting a new one');
    Stop;
  end;
  if FClient <> nil then
  begin
    if (FDocked = ADocked) and (FParentWindow = ParentWindow) then
    begin
      if ADocked and not FDesignViewActive then
        ShowPreviewDock
      else if not ADocked then
        FClient.BringToFront;
      Exit;
    end;
    Stop;
  end;
  Exe := HostExe;
  if Exe = '' then
  begin
    // Build All of the RADWinUI group builds the host, when only the package was built, build it on demand
    if MessageDlg('The preview host is not built yet (Build All of ' + RADWinUIGroup + ' builds it). ' +
      'Build it now (about 10 seconds)?', mtConfirmation,
      [mbYes, mbNo], 0) <> mrYes then
      Exit;
    if not RunHidden(Format('powershell -NoProfile -ExecutionPolicy Bypass -File "%s" ' +
      '-Project src\IDE\Preview\RADWinUIPreview.dpr -Config Release',
      [TPath.Combine(RootFolder, 'scripts\Build.ps1')])) or (HostExe = '') then
    begin
      MessageDlg('Building the preview failed. See ' + TPath.Combine(RootFolder, 'build\logs\RADWinUIPreview.log') +
        ', or open ' + RADWinUIGroup + ' and use Build All.', mtError, [mbOK], 0);
      Exit;
    end;
    Exe := HostExe;
  end;
  Log('starting ' + Exe);
  FClient := TPreviewClient.Create(Exe, ParentWindow, True);
  FDocked := ADocked;
  FParentWindow := ParentWindow;
  FTimer.Interval := 25;
  FTimer.Enabled := True;
  Tick(nil);
end;

procedure TPreviewCommand.Tick(Sender: TObject);
var
  Compiler: IOTACompileServices;
begin
  // A message box below runs a modal loop in which this timer fires again, the nested
  // tick could free the client the outer one still uses (access violation on close)
  if FInTick or ((FClient = nil) and not FDesignRestartPending) then
    Exit;
  // Ask the IDE rather than latch a flag that a cancelled build could strand.
  if Supports(BorlandIDEServices, IOTACompileServices, Compiler) and Compiler.IsBackgroundCompileActive then
    Exit;
  FInTick := True;
  try
    // A debug desktop can hide/show the frame without a subview Display callback.
    if FDesignViewActive and (FDesignSurface <> nil) and not FDesignSurface.Showing then
    begin
      FTimer.Enabled := False;
      Exit;
    end;
    // Parent recreation is a normal IDE layout change, not a renderer crash.
    if FDesignViewActive and (FDesignSurface <> nil) and
      (FParentWindow <> FDesignSurface.Handle) and (FClient <> nil) and FDocked then
    begin
      Stop;
      FDesignRestartPending := True;
      Log('Design parent changed; reconnecting renderer');
      FTimer.Enabled := True;
    end;
    if (FClient = nil) and FDesignRestartPending and (FDesignSurface <> nil) and
      FDesignSurface.Showing and Application.Active then
    begin
      FDesignRestartPending := False;
      FDesignViewActive := True;
      SetPaletteDesignerActive(True);
      RunPreview(True);
    end;
    if FClient <> nil then
      TickOnce;
    if (FClient <> nil) and FClient.Ready and not FClient.Busy then
      FTimer.Interval := 150
    else
      FTimer.Interval := 25; // connect promptly while WinUI starts, no busy wait
  finally
    FInTick := False;
  end;
end;

procedure TPreviewCommand.TickOnce;
var
  Buffer: IOTAEditBuffer;
  Xaml: string;
  Selection: TDesignerSelection;
  WasDesign: Boolean;
begin
  WasDesign := FDesignViewActive;
  try
    if not FDesignViewActive then
    begin
      Buffer := (BorlandIDEServices as IOTAEditorServices).TopBuffer;
      if Buffer <> nil then
      begin
        Xaml := XamlOf(Buffer.FileName);
        if Xaml <> '' then
          FXamlPath := Xaml;
      end;
    end;
    FClient.Tick(FXamlPath, SourceText(FXamlPath));
    if FLastClientStatus <> FClient.Status then
    begin
      FLastClientStatus := FClient.Status;
      if FLastClientStatus.StartsWith('ERROR') or FLastClientStatus.Contains('did not answer') then
        Log('preview status: ' + FLastClientStatus);
    end;
    if FClient.Ready then
    begin
      SyncTheme;
      if FDesignViewActive and (FDesignShownAt <> 0) and not FClient.Busy then
      begin
        Log(Format('Design synchronized in %d ms (pid %d)',
          [GetTickCount - FDesignShownAt, GetProcessId(FClient.HostProcess)]));
        FDesignShownAt := 0;
      end;
      if not FClient.Busy then SyncCode;
      try
        if FInspector <> nil then FInspector.ApplyPending;
        if FInspectorDirty and FDesignViewActive then
        begin
          FInspectorDirty := False;
          ShowInspector;
        end;
      except
        on E: Exception do Log('Object Inspector update failed: ' + E.ClassName + ': ' + E.Message);
      end;
      SyncStructure;
      // An event can navigate to Pascal/Code and hide Design. Input still queued
      // for that hidden surface must not immediately navigate back to XAML.
      while (FClient <> nil) and (not WasDesign or FDesignViewActive) and FClient.TakeEvent(Xaml) do
        if Xaml = 'CODEVIEW' then
          ShowXamlCode
        else if (Xaml = 'RUN') or (Xaml = 'COMPILE') then
        begin
          BuildShortcut(Xaml = 'COMPILE');
          Break; // a build/debug action can change the active desktop and designer
        end
        else if Xaml = 'COPY' then
          CopySelection
        else if Xaml = 'PASTE' then
          PasteSelection
        else if Xaml = 'DELETEKEY' then
          DeleteSelection
        else if Xaml = 'UNDO' then
          UndoDesigner(False)
        else if Xaml = 'REDO' then
          UndoDesigner(True)
        else if Xaml.StartsWith('DEFAULT ') and TDesignerSelection.Parse(Xaml.Substring(8), Selection) then
        begin
          if FInspector <> nil then
            FInspector.Commit;
          FSelection := Selection;
          FSelectionPath := FXamlPath;
          ShowInspector;
          Xaml := FIndex.DefaultEventOf(FSelection.Tag);
          if Xaml <> '' then
            EventHandler(Xaml, '');
        end
        else if TDesignerSelection.Parse(Xaml, Selection) then
        begin
          if FInspector <> nil then
            FInspector.Commit; // to the element selected until now
          FSelection := Selection;
          FSelectionPath := FXamlPath;
          Selected;
        end
        else
          StructureEvent(Xaml);
    end;
    if FClient = nil then
      Exit
    else if FClient.Closed then
    begin
      FDesignRestartPending := FDesignViewActive and (FDesignSurface <> nil) and
        (FParentWindow = FDesignSurface.Handle) and FileExists(FXamlPath);
      if FDesignRestartPending then
      begin
        Inc(FDesignRestarts);
        FDesignRestartPending := FDesignRestarts <= 2;
        if not FDesignRestartPending then
        begin
          Log('Design renderer repeatedly closed; automatic restart stopped');
          FDesignSurface.Caption := 'RADWinUI renderer repeatedly closed. Switch to Code and back to retry.';
        end;
      end;
      Stop;
      FTimer.Enabled := FDesignRestartPending;
    end
    else if FClient.Failed then
    begin
      Xaml := FClient.Status;
      Log('preview failed: ' + Xaml);
      Stop;
      MessageDlg('RADWinUI Preview: ' + Xaml, mtWarning, [mbOK], 0);
    end;
  except
    on E: Exception do
    begin
      // Never let the preview take the IDE down: stop and say why
      Log('preview stopped: ' + E.ClassName + ': ' + E.Message);
      Stop;
      MessageDlg('RADWinUI Preview stopped: ' + E.Message, mtWarning, [mbOK], 0);
    end;
  end;
end;

procedure TPreviewCommand.Selected;
begin
  // Moving the code editor while Design is visible can hide/recreate its frame.
  if not FDesignViewActive then
    GotoSource(FXamlPath, FSelection.Line, FSelection.Column);
  ShowInspector;
  SelectInStructure(FSelection.Line, FSelection.Column);
end;

/// INSERT, MOVE or DELETE from the preview: one undoable change of the XAML buffer.
procedure TPreviewCommand.StructureEvent(const AEvent: string);
var
  Xaml: string;
  Parts: TArray<string>;
begin
  try
    Xaml := SourceText(FXamlPath);
    Parts := AEvent.Split([' ']);
    if (Length(Parts) = 3) and (Parts[0] = 'DELETE') and
      not CanDeleteElement(Xaml, Parts[1].ToInteger, Parts[2].ToInteger) then Exit;
    ApplyText(FXamlPath, Xaml, ApplyDesignerEvent(Xaml, AEvent));
    SyncCode(True);
    if AEvent.StartsWith('DELETE') then ClearSelection
    else FInspectorDirty := True;
  except
    on E: Exception do
      MessageDlg('RADWinUI: ' + E.Message, mtWarning, [mbOK], 0);
  end;
end;

function TPreviewCommand.DesignEditState: TEditState;
begin
  Result := [];
  if not FDesignViewActive then Exit;
  Include(Result, esCanUndo);
  Include(Result, esCanRedo);
  if (FSelection.Line < 1) or
    not SameText(FSelectionPath, FXamlPath) then
    Exit;
  Include(Result, esCanCopy);
  try
    if CanDeleteSelection then
      Include(Result, esCanDelete);
  except
    on EXamlEdit do ; // incomplete XAML is not deletable
  end;
  if Clipboard.HasFormat(CF_UNICODETEXT) or Clipboard.HasFormat(CF_TEXT) then
    Include(Result, esCanPaste);
end;

function TPreviewCommand.DesignEditAction(Action: TEditAction): Boolean;
begin
  Result := True;
  case Action of
    eaUndo: UndoDesigner(False);
    eaRedo: UndoDesigner(True);
    eaDelete: DeleteSelection;
    eaCopy: CopySelection;
    eaPaste: PasteSelection;
  else
    Result := False;
  end;
end;

procedure TPreviewCommand.ClearSelection;
var
  Reply: string;
begin
  if FInspector <> nil then FInspector.Commit;
  FSelection := Default(TDesignerSelection);
  FSelectionPath := '';
  FInspectorDirty := True;
  if FInspector <> nil then
    FInspector.Clear;
  SelectInStructure(0, 0);
  if FClient <> nil then FClient.Request('SELECTPOS 0 0', Reply);
end;

procedure TPreviewCommand.DeleteSelection;
var
  Xaml: string;
begin
  if not (esCanDelete in DesignEditState) then Exit;
  try
    if FInspector <> nil then FInspector.Commit;
    if not CanDeleteSelection then Exit;
    Xaml := SourceText(FXamlPath);
    ApplyText(FXamlPath, Xaml, DeleteElement(Xaml, FSelection.Line, FSelection.Column));
    ClearSelection;
    SyncCode(True);
    SyncStructure;
  except
    on E: Exception do Log('designer delete: ' + E.Message);
  end;
end;

function TPreviewCommand.CanDeleteSelection: Boolean;
var
  Elements: TArray<TXamlElement>;
  Element: TXamlElement;
begin
  Result := False;
  if not SameText(FSelectionPath, FXamlPath) then Exit;
  Elements := XamlElements(SourceText(FXamlPath));
  for Element in Elements do
    if not Element.DesignOnly and (Element.Tag = FSelection.Tag) and
      (((FSelection.Name <> '') and (Element.Name = FSelection.Name)) or
       ((FSelection.Name = '') and (Element.Line = FSelection.Line) and (Element.Column = FSelection.Column))) then
    begin
      FSelection.Line := Element.Line;
      FSelection.Column := Element.Column;
      Exit((Element.ParentIndex >= 0) and (Elements[Element.ParentIndex].Tag <> 'Window'));
    end;
end;

procedure TPreviewCommand.UndoDesigner(ARedo: Boolean);
var
  Editor: IOTASourceEditor;
  Buffer: IOTAEditBuffer;
  Iterator: IOTAEditBufferIterator;
  I: Integer;
  Changed: Boolean;
begin
  if not FDesignViewActive then Exit;
  try
    if FInspector <> nil then FInspector.Commit;
    Editor := EditorOf(FXamlPath);
    if Editor.EditViewCount > 0 then Buffer := Editor.EditViews[0].Buffer
    else if (BorlandIDEServices as IOTAEditorServices).GetEditBufferIterator(Iterator) then
      for I := 0 to Iterator.Count - 1 do
        if SameText(Iterator.EditBuffers[I].FileName, FXamlPath) then
        begin
          Buffer := Iterator.EditBuffers[I];
          Break;
        end;
    if Buffer = nil then Exit;
    if ARedo then Changed := Buffer.Redo else Changed := Buffer.Undo;
    if Changed then
    begin
      ClearSelection;
      SyncCode(True);
      SyncStructure;
    end;
  except
    on E: Exception do Log('designer undo/redo: ' + E.Message);
  end;
end;

procedure TPreviewCommand.CopySelection;
begin
  if not (esCanCopy in DesignEditState) then
    Exit;
  try
    Clipboard.AsText := CopyElement(SourceText(FXamlPath), FSelection.Line, FSelection.Column);
  except
    on E: Exception do
      MessageDlg('RADWinUI Copy: ' + E.Message, mtWarning, [mbOK], 0);
  end;
end;

procedure TPreviewCommand.PasteSelection;
var
  Xaml: string;
begin
  if not (esCanPaste in DesignEditState) then
    Exit;
  try
    Xaml := SourceText(FXamlPath);
    ApplyText(FXamlPath, Xaml, PasteElement(Xaml, FSelection.Line, FSelection.Column,
      Clipboard.AsText));
    SyncCode(True);
  except
    on E: Exception do
      MessageDlg('RADWinUI Paste: ' + E.Message, mtWarning, [mbOK], 0);
  end;
end;

procedure TPreviewCommand.DesignKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_F12) and (Shift = []) then
    ShowXamlCode
  else if (Key = VK_F9) and ((Shift = []) or (Shift = [ssCtrl])) then
    BuildShortcut(ssCtrl in Shift)
  else if (Key = Ord('C')) and (Shift = [ssCtrl]) then
    CopySelection
  else if (Key = Ord('V')) and (Shift = [ssCtrl]) then
    PasteSelection
  else if (Key = VK_DELETE) and (Shift = []) then
    DeleteSelection
  else if (Key = Ord('Z')) and (Shift = [ssCtrl]) then
    UndoDesigner(False)
  else if ((Key = Ord('Y')) and (Shift = [ssCtrl])) or
    ((Key = Ord('Z')) and (Shift = [ssCtrl, ssShift])) then
    UndoDesigner(True)
  else
    Exit;
  Key := 0;
end;

procedure TPreviewCommand.ShowInspector;
var
  Xaml, Pas, Cls: string;
  Elements, Instances: TArray<TXamlElement>;
  Element: TXamlElement;
  Selection: TDesignerSelection;
  Props: TArray<TDesignerProperty>;
  Prop: TDesignerProperty;
  CanAlign, Found, WasDesign: Boolean;
begin
  if FInspector = nil then Exit;
  WasDesign := FDesignViewActive;
  FInspector.Commit;
  if WasDesign and not FDesignViewActive then Exit;
  if FIndex = nil then
    FIndex := TDesignerTypeIndex.Create(TPath.Combine(RootFolder, 'src\Generated\RADWinUI.Xaml.json'));
  Xaml := SourceText(FXamlPath);
  Pas := SourceText(ChangeFileExt(FXamlPath, '.pas'));
  Cls := WindowClass(Xaml);
  Elements := XamlElements(Xaml);
  if Length(Elements) = 0 then
  begin
    FInspector.Clear;
    Exit;
  end;
  CanAlign := False;
  Found := False;
  for Element in Elements do
  begin
    if Element.DesignOnly then Continue;
    if FIndex.IsVisual(Element.Tag) or (Element.Tag = 'Window') then Instances := Instances + [Element];
    if SameText(FSelectionPath, FXamlPath) and (Element.Tag = FSelection.Tag) and
      (((FSelection.Name <> '') and (Element.Name = FSelection.Name)) or
       ((FSelection.Name = '') and (Element.Line = FSelection.Line) and (Element.Column = FSelection.Column))) then
    begin
      FSelection.Line := Element.Line;
      FSelection.Column := Element.Column;
      CanAlign := (Element.ParentIndex >= 0) and (Elements[Element.ParentIndex].Tag = 'Grid');
      Found := True;
    end;
  end;
  if not Found then
  begin
    FSelection.Line := Elements[0].Line;
    FSelection.Column := Elements[0].Column;
    FSelection.Tag := Elements[0].Tag;
    FSelection.Name := Elements[0].Name;
    FSelectionPath := FXamlPath;
  end;
  Selection := FSelection; // getters belong to this snapshot, not the next mouse selection
  for Prop in FIndex.PropertiesOf(Selection.Tag) do
    if (Prop.Name <> 'Align') or CanAlign then Props := Props + [Prop];
  FInspector.ShowElement(Trim(Selection.Tag + ' ' + Selection.Name), Props,
    function(AName: string): string
    begin
      if AName = 'Align' then Result := AlignOf(Xaml, Selection.Line, Selection.Column)
      else GetAttribute(Xaml, Selection.Line, Selection.Column, AttributeOf(AName), Result);
    end,
    FIndex.EventsOf(Selection.Tag),
    function(AName: string): string
    begin
      if not GetAttribute(Xaml, Selection.Line, Selection.Column, AName, Result) and (Selection.Name <> '') and
        (FindHandler(Pas, Cls, Selection.Name + AName) > 0) then
        Result := Selection.Name + AName;
    end, Instances, Selection.Line, Selection.Column);
end;

function TPreviewCommand.ShowPreviewDock: Boolean;
begin
  if FPreviewDockForm = nil then
  begin
    FPreviewDockForm := (BorlandIDEServices as INTAServices).CreateDockableForm(FPreviewDock);
    if FPreviewDockForm <> nil then
      FPreviewDockForm.FreeNotification(FWatch);
  end;
  Result := (FPreviewDockForm <> nil) and (FPreviewSurface <> nil);
  if Result then
    FPreviewDockForm.Show
  else
    MessageDlg('RADWinUI Docked Preview could not create its IDE panel.', mtError, [mbOK], 0);
end;

procedure TPreviewCommand.PreviewFrameCreated(AFrame: TCustomFrame);
begin
  FPreviewDockForm := GetParentForm(AFrame);
  if FPreviewDockForm <> nil then
    FPreviewDockForm.FreeNotification(FWatch);
  FPreviewSurface := TPanel.Create(AFrame);
  FPreviewSurface.Parent := AFrame;
  FPreviewSurface.Align := alClient;
  FPreviewSurface.BevelOuter := bvNone;
  FPreviewSurface.Caption := '';
  FPreviewSurface.FreeNotification(FWatch);
end;

procedure TPreviewCommand.DesignFrameCreated(AFrame: TCustomFrame);
var
  Surface: TDesignPanel;
begin
  if AFrame.FindComponent('RADWinUIDesignSurface') <> nil then
    Exit;
  // Frames can be prepared in the background. Only Display chooses the active one.
  Surface := TDesignPanel.Create(AFrame);
  Surface.Name := 'RADWinUIDesignSurface';
  Surface.Parent := AFrame;
  Surface.Align := alClient;
  Surface.BevelOuter := bvNone;
  Surface.Caption := '';
  Surface.TabStop := True;
  Surface.OnKeyDown := DesignKeyDown;
  Surface.OnShowingChanged := DesignShowingChanged;
  Surface.FreeNotification(FWatch);
  FDesignSurfaces.Add(Surface);
end;

procedure TPreviewCommand.DesignShowingChanged(Sender: TObject);
begin
  if not FDesignViewActive or (Sender <> FDesignSurface) then Exit;
  if FDesignSurface.Showing then
  begin
    Log('Design surface shown; resuming: ' + FXamlPath);
    FInspectorDirty := True;
    FDesignShownAt := GetTickCount;
    if FClient <> nil then FClient.Resume;
    FDesignRestartPending := FClient = nil;
    FTimer.Interval := 25;
    FTimer.Enabled := True;
  end
  else if FDocked and FDesignSurface.HandleAllocated and
    (FParentWindow = FDesignSurface.Handle) then
  begin
    Log('Design surface hidden; pausing: ' + FXamlPath);
    FTimer.Enabled := False;
  end;
end;

procedure TPreviewCommand.DesignViewDisplayed(const AContext: IInterface; AViewObject: TObject);
var
  FileName, Event: string;
  Surface: TDesignPanel;
begin
  if AContext <> nil then
  begin
    if not (AViewObject is TCustomFrame) or
      not (BorlandIDEServices as IOTAEditorViewServices).ContextToFilename(AContext, FileName) then
      Exit;
    DesignFrameCreated(TCustomFrame(AViewObject));
    Surface := TCustomFrame(AViewObject).FindComponent('RADWinUIDesignSurface') as TDesignPanel;
    if (FClient <> nil) and (not FDocked or (FParentWindow <> Surface.Handle)) then
      Stop;
    // Ignore input left over from the previous display before changing its source.
    if FClient <> nil then
    begin
      FClient.Resume;
      while FClient.TakeEvent(Event) do;
    end;
    FDesignSurface := Surface;
    Surface.Caption := '';
    if not FDesignViewActive then FDesignRestarts := 0;
    FDesignViewActive := True;
    if not SameText(FXamlPath, FileName) then
      FSelectionPath := '';
    FXamlPath := FileName;
    FInspectorDirty := True;
    WatchWindow(FileName);
    FDesignShownAt := GetTickCount;
    Log('Design displayed: ' + FileName + ' (parent ' + UIntToStr(Surface.Handle) +
      ', ' + IfThen(FClient <> nil, 'reuse renderer', 'start renderer') + ')');
    SetPaletteDesignerActive(True);
    // Start after the IDE finishes showing/parenting the frame, not in its callback.
    FDesignRestartPending := FClient = nil;
    FTimer.Interval := 25;
    FTimer.Enabled := True;
  end
  else if (FDesignSurface <> nil) and (FDesignSurface.Parent = AViewObject) then
  begin
    Log('Design hidden: ' + FXamlPath);
    if (FInspector <> nil) and (FClient <> nil) then
      FInspector.Commit;
    FDesignViewActive := False;
    if FInspector <> nil then FInspector.Clear;
    FDesignShownAt := 0;
    SetPaletteDesignerActive(False);
    FDesignRestartPending := False;
    // Code/Design shares a frame. Keep its child renderer and unchanged visual tree,
    // stop polling while hidden. ViewClosed/Freed still release it with the frame.
    FTimer.Enabled := (FClient <> nil) and (not FDocked or (FParentWindow <> FDesignSurface.Handle));
  end;
end;

procedure TPreviewCommand.DesignFailure(const AOperation, AError: string);
begin
  // OTA callbacks must not let a COM error escape into the IDE's editor switch.
  Log('Design ' + AOperation + ' failed: ' + AError);
  FDesignRestartPending := False;
  FTimer.Enabled := False;
  FreeAndNil(FClient);
  FDocked := False;
  FParentWindow := 0;
  if FDesignSurface <> nil then
    FDesignSurface.Caption := 'RADWinUI Design stopped: ' + AError + '. See %TEMP%\RADWinUI\ide.log';
end;

procedure TPreviewCommand.DesignViewClosed(AViewObject: TObject);
begin
  DesignViewDisplayed(nil, AViewObject);
  if (FDesignSurface <> nil) and (FDesignSurface.Parent = AViewObject) then
  begin
    if FDocked and (FClient <> nil) and (FParentWindow = FDesignSurface.Handle) then
      Stop;
    FDesignSurface := nil;
  end;
end;

procedure TPreviewCommand.Freed(AComponent: TComponent);
begin
  if FDesignSurfaces <> nil then
    FDesignSurfaces.Remove(AComponent);
  if AComponent = FDesignSurface then
  begin
    FDesignSurface := nil;
    FDesignViewActive := False;
    SetPaletteDesignerActive(False);
    FDesignRestartPending := False;
    if FDocked and (FClient <> nil) then
      Stop;
    FTimer.Enabled := FClient <> nil;
  end;
  if (AComponent = FPreviewSurface) or (AComponent = FPreviewDockForm) then
  begin
    if AComponent = FPreviewSurface then
    begin
      FPreviewSurface := nil;
      FPreviewDockForm := nil;
    end;
    if AComponent = FPreviewDockForm then
      FPreviewDockForm := nil;
    if FDocked and (FClient <> nil) then
      Stop;
  end;
end;

procedure TPreviewCommand.PropertyChange(AName, AValue: string);
var
  Xaml, Updated, Name: string;
  Element: TXamlElement;
begin
  try
    Xaml := SourceText(FXamlPath);
    if AName = 'Align' then
    begin
      if AValue = '' then AValue := 'alNone';
      Name := FSelection.Name;
      Updated := Xaml;
      if Name = '' then
      begin
        Name := NewElementName(Xaml, FSelection.Tag);
        Updated := SetAttribute(Updated, FSelection.Line, FSelection.Column, 'x:Name', Name);
      end;
      Updated := SetAlign(Updated, FSelection.Line, FSelection.Column, AValue);
      ApplyText(FXamlPath, Xaml, Updated);
      FSelection.Name := Name;
      for Element in XamlElements(Updated) do
        if not Element.DesignOnly and (Element.Name = Name) and (Element.Tag = FSelection.Tag) then
        begin
          FSelection.Line := Element.Line;
          FSelection.Column := Element.Column;
          Break;
        end;
      SyncCode(True);
      SyncStructure;
      FInspectorDirty := True;
      Exit;
    end;
    if AValue = '' then
      ApplyText(FXamlPath, Xaml, RemoveAttribute(Xaml, FSelection.Line, FSelection.Column, AttributeOf(AName)))
    else
      ApplyText(FXamlPath, Xaml, SetAttribute(Xaml, FSelection.Line, FSelection.Column, AttributeOf(AName), AValue));
    if AName = 'Name' then
    begin
      FSelection.Name := AValue;
      SyncCode(True);
    end;
    FInspectorDirty := True;
  except
    on E: Exception do
      MessageDlg('RADWinUI: ' + E.Message, mtWarning, [mbOK], 0);
  end;
end;

procedure TPreviewCommand.EventHandler(AEvent, AHandler: string);
var
  Xaml, PasFile, Pas, Cls, Args, Current, NewPas: string;
  Event: TDesignerEvent;
  Line: Integer;
begin
  try
    if FInspector <> nil then
      FInspector.Commit;
    Xaml := SourceText(FXamlPath);
    PasFile := ChangeFileExt(FXamlPath, '.pas');
    EditorOf(PasFile);
    WatchWindow(FXamlPath);
    Pas := SourceText(PasFile);
    Cls := WindowClass(Xaml);
    if FIndex = nil then
      FIndex := TDesignerTypeIndex.Create(TPath.Combine(RootFolder, 'src\Generated\RADWinUI.Xaml.json'));
    Args := '';
    for Event in FIndex.EventsOf(FSelection.Tag) do
      if Event.Name = AEvent then
        Args := Event.ArgsType;
    if Args = '' then
      raise Exception.CreateFmt('%s has no %s event', [FSelection.Tag, AEvent]);
    if FSelection.Name = '' then
    begin
      FSelection.Name := NewElementName(Xaml, FSelection.Tag);
      Xaml := SetAttribute(Xaml, FSelection.Line, FSelection.Column, 'x:Name', FSelection.Name);
    end;
    if AHandler = '' then
      if not GetAttribute(Xaml, FSelection.Line, FSelection.Column, AEvent, AHandler) or (AHandler = '') then
        AHandler := FSelection.Name + AEvent;
    if not IsValidIdent(AHandler) then
      raise Exception.CreateFmt('"%s" is not a method name', [AHandler]);
    // The method first, then the attribute: the XAML never names a method that is not there
    Line := FindHandler(Pas, Cls, AHandler);
    if Line = 0 then
    begin
      NewPas := AddHandler(Pas, Cls, AHandler, Args, Line);
      ApplyText(PasFile, Pas, NewPas);
    end;
    // Keep the assignment explicit, including a newly assigned component name.
    Current := SourceText(FXamlPath);
    ApplyText(FXamlPath, Current, SetAttribute(Xaml, FSelection.Line, FSelection.Column, AEvent, AHandler));
    SyncCode(True);
    GotoSource(PasFile, Line, 3);
  except
    on E: Exception do
    begin
      Log('event handler: ' + E.ClassName + ': ' + E.Message);
      MessageDlg('RADWinUI: ' + E.Message, mtWarning, [mbOK], 0);
    end;
  end;
end;

/// The event's field was emptied: the attribute goes, the method stays (like the Object Inspector).
procedure TPreviewCommand.EventCleared(AEvent: string);
var
  Xaml: string;
begin
  try
    Xaml := SourceText(FXamlPath);
    ApplyText(FXamlPath, Xaml, RemoveAttribute(Xaml, FSelection.Line, FSelection.Column, AEvent));
    FInspectorDirty := True;
  except
    on E: Exception do
      MessageDlg('RADWinUI: ' + E.Message, mtWarning, [mbOK], 0);
  end;
end;

procedure AddPreviewCommand;
begin
  if Command = nil then
    Command := TPreviewCommand.Create;
end;

initialization

finalization
  FreeAndNil(Command);

end.
