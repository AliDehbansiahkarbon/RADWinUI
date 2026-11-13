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
  System.Win.Registry,
  System.Rtti,
  System.Generics.Collections,
  Vcl.ActnList,
  Vcl.AppEvnts,
  Vcl.Graphics,
  Vcl.Menus,
  Vcl.ExtCtrls,
  Vcl.Dialogs,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.Forms,
  Vcl.ComCtrls,
  Vcl.ImgList,
  Vcl.Themes,
  Vcl.Clipbrd,
  ToolsAPI,
  ToolsAPI.AI,
  ToolsAPI.Editor,
  PaletteAPI,
  DesignIntf,
  StructureViewAPI,
  RADWinUI.Wizard.Registration,
  RADWinUI.Wizard.Templates,
  RADWinUI.Preview.Client,
  RADWinUI.Preview.HotReload,
  RADWinUI.Preview.Menu,
  RADWinUI.Designer.XamlEdit,
  RADWinUI.Designer.Model,
  RADWinUI.Designer.PaletteIcons,
  RADWinUI.Designer.Palette,
  RADWinUI.Designer.Structure,
  RADWinUI.Designer.ObjectInspector,
  RADWinUI.Designer.TabItemsEditor,
  RADWinUI.Designer.Dialogs,
  RADWinUI.Designer.AICompletion,
  RADWinUI.Designer.Settings,
  RADWinUI.Preview.PromptBox;

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
    procedure CompleteKeyPressed(const Context: IOTAKeyContext; KeyCode: TShortcut;
      var BindingResult: TKeyBindingResult);
  public
    constructor Create(ACommand: TPreviewCommand);
    function GetBindingType: TBindingType;
    function GetDisplayName: string;
    function GetName: string;
    procedure BindKeyboard(const BindingServices: IOTAKeyBindingServices);
  end;

  /// <summary>One Complete XAML with AI request to the IDE's AI engine (ToolsAPI.AI).
  /// The answer goes in at the cursor as one undoable edit, unless the XAML changed meanwhile.</summary>
  TXamlAIRequest = class(TNotifierObject, IOTAAIServicesNotifier)
  private
    FPlugin: IOTAAIPlugin;
    FNotifier: Integer;
    FRequest: TGUID;
    FFile, FXaml: string;
    FCursor, FSelEnd: Integer;
    FOnDone: procedure(const AAnswer, AError: string) of object; // set: the prompt bar takes the answer
    procedure Done(const AAnswer, AError: string; const ARequestID: TGUID);
    procedure Detach;
  public
    procedure Answer(const AMessage: string; const ARequestID: TGUID);
    procedure Error(const AMessage: string; const ARequestID: TGUID);
    procedure ModelsLoaded(const AModels: TArray<string>; const ARequestID: TGUID);
    procedure ImageLoaded(const AImage: TStream; const ARequestID: TGUID); overload;
    procedure ImageLoaded(const A64BitImages: TArray<string>; const ARequestID: TGUID); overload;
    procedure ImageURlLoaded(const AImageURls: TArray<string>; const ARequestID: TGUID);
    procedure SpeechLoaded(const ASpeech: TStream; const ARequestID: TGUID);
  end;

  /// <summary>Gets the AI plugin's answers for the suggestions while typing.</summary>
  TXamlSuggestionNotifier = class(TNotifierObject, IOTAAIServicesNotifier)
  public
    procedure Answer(const AMessage: string; const ARequestID: TGUID);
    procedure Error(const AMessage: string; const ARequestID: TGUID);
    procedure ModelsLoaded(const AModels: TArray<string>; const ARequestID: TGUID);
    procedure ImageLoaded(const AImage: TStream; const ARequestID: TGUID); overload;
    procedure ImageLoaded(const A64BitImages: TArray<string>; const ARequestID: TGUID); overload;
    procedure ImageURlLoaded(const AImageURls: TArray<string>; const ARequestID: TGUID);
    procedure SpeechLoaded(const ASpeech: TStream; const ARequestID: TGUID);
  end;

  /// <summary>The code editor's paint and key events the ghost text needs.</summary>
  TXamlEditorEvents = class(TNTACodeEditorNotifier)
  protected
    function AllowedEvents: TCodeEditorEvents; override;
    function AllowedLineStages: TPaintLineStages; override;
  end;

  /// <summary>AI suggestions while typing in .xaml code editors: watches the editor
  /// every 50 ms (reading its text only after a key or a cursor move), asks the AI
  /// plugin after a pause, paints the answer as ghost text, Tab inserts it.
  /// TXamlSuggestions decides; this class talks to the IDE.</summary>
  TXamlSuggestionController = class
  strict private
    FState: TXamlSuggestions;
    FTimer: TTimer;
    FFile: string;
    FKeyed: Boolean;
    FLastPos: TOTAEditPos;
    FGhostPos: TOTAEditPos;
    FEvents: INTACodeEditorEvents;
    FEventsIndex: Integer;
    FPlugin: IOTAAIPlugin;
    FPluginNotifier: Integer;
    FPluginCheckedAt: UInt64;
    FRequestedAt, FKeyAt: UInt64;
    FEnabled: Boolean;
    FStopped: Boolean;
    procedure Tick(Sender: TObject);
    procedure Invalidate;
    procedure ReleasePlugin;
    function Plugin: IOTAAIPlugin;
    procedure AcceptGhost;
    procedure PaintLine(const Rect: TRect; const Stage: TPaintLineStage; const BeforeEvent: Boolean;
      var AllowDefaultPainting: Boolean; const Context: INTACodeEditorPaintContext);
    procedure KeyDown(const Editor: TWinControl; Key: Word; Shift: TShiftState; var Handled: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>An answer or error of the AI plugin, on the main thread.</summary>
    procedure Answer(const AID: TGUID; const AText, AError: string);
    /// <summary>Reads on/off and the delay from the RADWinUI registry key.</summary>
    procedure LoadSettings;
  end;

  /// <summary>
  ///   Hot reload: sends each edited .xaml file of the IDE to the RADWinUI apps built from its
  ///   folder that run in Debug (RADWinUI.HotReload), after a pause or when it is saved.
  /// </summary>
  TXamlHotReloadSender = class
  strict private
    FTimer: TTimer;
    FMode: TRADWinUIHotReload;
    FModeAt, FAppsAt: UInt64;
    FApps: TArray<THotReloadApp>;
    // per file: the last text seen and when it changed; per app and file: the text sent
    FSeen: TDictionary<string, string>;
    FChangedAt: TDictionary<string, UInt64>;
    FSent: TDictionary<string, string>;
    procedure Tick(Sender: TObject);
    function XamlFiles: TArray<string>;
    function TextOf(const AFile: string): string;
    procedure Send(const AFile, AText: string; const AApps: TArray<THotReloadApp>);
  public
    constructor Create;
    destructor Destroy; override;
  end;

  /// <summary>Tools > Options > Third Party > RADWinUI: RADWinUI's IDE settings
  /// (RADWinUI.Designer.Settings), each change saved at once.</summary>
  TRADWinUIOptions = class(TInterfacedObject, INTAAddInOptions)
  strict private
    FSuggestions: TCheckBox;
    FDelay: TEdit;
    FCodeCompletion: TCheckBox;
    FPromptSelection: TCheckBox;
    FHotReload: TComboBox;
    FError: TLabel;
    FLoading: Boolean;
    FLastDelay: Integer; // the pause last saved: an invalid one goes back to it
    procedure Changed(Sender: TObject);
    procedure DelayExit(Sender: TObject);
    function DelayValid: Boolean;
  public
    function GetArea: string;
    function GetCaption: string;
    function GetFrameClass: TCustomFrameClass;
    procedure FrameCreated(AFrame: TCustomFrame);
    procedure DialogClosed(Accepted: Boolean);
    function ValidateContents: Boolean;
    function GetHelpContext: Integer;
    function IncludeInIDEInsight: Boolean;
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
    FCompleteAction: TAction;
    FCompleteItem: TMenuItem;
    FSettingsAction: TAction;
    FSettingsItem: TMenuItem;
    FRootItem: TMenuItem; // Tools > RADWinUI
    FPromptBox: TXamlPromptBox;
    FPromptFile: string;
    FPromptRequest: TXamlAIRequest; // the prompt's request, nil when none is pending
    FOptionsTimer: TTimer;          // selects our page once the Options dialog shows
    FOptionsAskedAt: Cardinal;
    FSuggestions: TXamlSuggestionController;
    FHotReload: TXamlHotReloadSender;
    FEditorOptions: INTAAddInOptions;
    FEditorActions: TActionList; // the code editor's context menu, .xaml files only
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
    FContextMenu: TPopupMenu;
    FContextProperty: string; // the property Edit Text... or Edit Items... of the shown menu edits
    FSplitView: Boolean;      // Split View started the docked preview next to the XAML code
    FPreviewFocused: Boolean; // the Split View designer had the keyboard focus at the last tick
    FNudgeBase, FNudgeText: string; // the XAML before and after the current burst of keyboard moves
    FNudgeLine, FNudgeColumn: Integer;
    FMulti: TArray<TDesignerSelection>; // a multi-selection (Ctrl+click, marquee, Ctrl+A), FSelection is its first
    FNudgeAt: Cardinal;
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
    procedure CutSelection;
    function SelectedIndex(const AElements: TArray<TXamlElement>): Integer;
    procedure SelectParent;
    procedure ReorderSelection(AToFront: Boolean);
    procedure EditSelection(ACommand: Integer);
    procedure ViewSelectionSource;
    function SplitActive: Boolean;
    function Designing: Boolean;
    procedure ToggleSplitView;
    function PreviewHasFocus: Boolean;
    procedure SyncSplitStructure;
    procedure ShowSplitStructure;
    procedure EndSplitStructure;
    function XamlBuffer: IOTAEditBuffer;
    procedure NudgeSelection(const AEvent: string);
    procedure NudgeMulti(const AEvent: string);
    function MultiPositions: TArray<TXamlPosition>;
    function AddContextItem(AParent: TMenuItem; const ACaption: string; ACommand: Integer; AEnabled: Boolean;
      AShortCut: TShortCut = 0): TMenuItem;
    procedure AddControlItems(const AXaml: string; const AElements: TArray<TXamlElement>; AIndex: Integer);
    procedure ShowContextMenu(AX, AY: Integer; AHit: Boolean);
    procedure ContextClick(Sender: TObject);
    procedure DesignKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DesignShowingChanged(Sender: TObject);
    procedure ApplicationMessage(var Msg: TMsg; var Handled: Boolean);
    function IdeShortcut(AKey: TShortCut): Boolean;
    procedure SetPaletteDesignerActive(AActive: Boolean);
    procedure ShowInspector;
    procedure PropertyChange(AName, AValue: string);
    procedure EventHandler(AEvent, AHandler: string);
    procedure EventCleared(AEvent: string);
    function FindXaml: string;
    procedure Execute(Sender: TObject);
    procedure ExecuteDocked(Sender: TObject);
    procedure ExecuteComplete(Sender: TObject);
    procedure EditorActionUpdate(Sender: TObject);
    procedure ExecuteComment(Sender: TObject);
    procedure PromptSubmit(const APrompt: string);
    procedure PromptCancel(Sender: TObject);
    procedure PromptAnswer(const AAnswer, AError: string);
    procedure ClosePrompt;
    procedure ExecuteSettings(Sender: TObject);
    procedure SelectOptionsPage(Sender: TObject);
    function IsCommentKey(AKey: Word): Boolean;
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
    /// <summary>Complete XAML with AI at the cursor of AFile, when it is a .xaml file.</summary>
    function CompleteXaml(const AFile: string): Boolean;
    /// <summary>Ctrl+/: comments the selected lines of a .xaml buffer out, or back in.</summary>
    function ToggleComment(const ABuffer: IOTAEditBuffer): Boolean;
    /// <summary>Ctrl+Alt+Space: the Create XAML with AI bar over the IDE, for a .xaml file.</summary>
    function ShowXamlPrompt(const AFile: string): Boolean;
    /// <summary>The IDE freed the dockable form or the inspector.</summary>
    procedure Freed(AComponent: TComponent);
  end;

var
  Command: TPreviewCommand;
  PendingCompletion: TXamlAIRequest; // the request whose answer is still awaited
  PendingCompletionRef: IOTAAIServicesNotifier;
  Suggestions: TXamlSuggestionController; // nil once the package unloads: queued answers check it

const
  // Commands of the designer's context menu (TMenuItem.Tag)
  cmUndo = 1; cmRedo = 2; cmCut = 3; cmCopy = 4; cmPaste = 5; cmDelete = 6; cmSelectParent = 7; cmFront = 8;
  cmBack = 9; cmViewSource = 10; cmSplit = 11; cmEvent = 12; cmAddRow = 13; cmAddColumn = 14; cmHorizontal = 15;
  cmVertical = 16; cmAddItem = 17; cmEditItems = 18; cmEditText = 19;

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

/// Generate from a snapshot of the IDE buffers, without saving the user's XAML/Pascal. AHotReload
/// also asks for the content the app loads and the shape it compares (AContent, AShape).
function GenerateCode(const APath, AXaml, APas: string; out AText, AError: string; AHotReload: Boolean;
  out AContent, AShape: string): Boolean; overload;
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
      if AHotReload then
        Json.AddPair('hotreload', TJSONTrue.Create);
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
      begin
        AText := Json.GetValue('text').Value;
        AContent := Json.GetValue<string>('content', '');
        AShape := Json.GetValue<string>('shape', '');
      end
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

function GenerateCode(const APath, AXaml, APas: string; out AText, AError: string): Boolean; overload;
var
  Content, Shape: string;
begin
  Result := GenerateCode(APath, AXaml, APas, AText, AError, False, Content, Shape);
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
  if not Designing or (FStructure = nil) or not SameText(FStructure.Path, FXamlPath) then Exit;
  try
    Context := FStructureContext; // keep it alive if a queued action changes the active editor
    (Context as TDesignerStructure).DispatchSelection;
    if not FDesignViewActive or (Context <> FStructureContext) then Exit;
    Xaml := SourceText(FXamlPath);
    FStructure.RegisterImages; // icons nodes built inside an IDE callback could not get
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
  if not Designing then Exit;
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
  // Split View: the code next to the preview follows the selection
  if not FDesignViewActive then
    GotoSource(FXamlPath, AElement.Line, AElement.Column);
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
  BindingServices.AddKeyBinding([ShortCut(VK_SPACE, [ssCtrl, ssAlt])], CompleteKeyPressed, nil, 0);
  // Ctrl+/ is taken in TPreviewCommand.ApplicationMessage: a keyboard binding never received it,
  // the IDE's own Ctrl+/ comes first
end;

procedure TDesignerKeyBinding.CompleteKeyPressed(const Context: IOTAKeyContext; KeyCode: TShortcut;
  var BindingResult: TKeyBindingResult);
begin
  BindingResult := krUnhandled;
  if (FCommand <> nil) and (Context <> nil) and (Context.EditBuffer <> nil) and
    FCommand.ShowXamlPrompt(Context.EditBuffer.FileName) then
    BindingResult := krHandled;
end;

{ TXamlAIRequest }

/// A line in the Messages view and in ide.log.
procedure EditorNote(const AText: string);
var
  Messages: IOTAMessageServices;
begin
  Log(AText);
  if Supports(BorlandIDEServices, IOTAMessageServices, Messages) then
  begin
    Messages.AddTitleMessage('RADWinUI ' + AText);
    Messages.ShowMessageView(nil);
  end;
end;

procedure CompletionNote(const AText: string);
begin
  EditorNote('Complete XAML with AI: ' + AText);
end;

var
  VocabularyIndex: TDesignerTypeIndex; // RADWinUI.Xaml.json for the AI answers, loaded on first use

/// The names AI answers may use in AXaml (AFile): every type, RADWinUI's own controls and
/// the project's user controls, as XAML spells them.
function XamlVocabulary(const AFile, AXaml: string): IXamlVocabulary;
begin
  if VocabularyIndex = nil then
    VocabularyIndex := TDesignerTypeIndex.Create(TPath.Combine(RootFolder, 'src\Generated\RADWinUI.Xaml.json'));
  Result := TIndexVocabulary.Create(VocabularyIndex, ProjectUserControls(AXaml, ExtractFilePath(AFile)));
end;

/// An answer on one line of ide.log.
function LogText(const AText: string): string;
begin
  Result := AText.Replace(#13, '').Replace(#10, '\n');
end;

/// The 0-based UTF-16 index in AText (the buffer's text) of an editor position.
function ViewOffset(const AView: IOTAEditView; const AText: string; AEditPos: TOTAEditPos): Integer;
var
  CharPos: TOTACharPos;
  Bytes: UTF8String;
  Position: Integer;
begin
  AView.ConvertPos(True, AEditPos, CharPos);
  Position := AView.CharPosToPos(CharPos); // a UTF-8 offset in the buffer
  Bytes := UTF8String(AText);
  if Position > Length(Bytes) then
    Position := Length(Bytes);
  if Position < 0 then
    Position := 0;
  Result := Length(UTF8ToString(Copy(Bytes, 1, Position)));
end;

/// The 1-based line and column (characters) of a 0-based UTF-16 index.
procedure LineColumnOf(const AText: string; AIndex: Integer; out ALine, AColumn: Integer);
var
  Before: string;
begin
  Before := AText.Substring(0, AIndex);
  ALine := Length(Before) - Length(Before.Replace(#10, '')) + 1;
  AColumn := Length(Before) - Before.LastIndexOf(#10);
end;

function IsXamlFile(const AFile: string): Boolean;
begin
  Result := SameText(ExtractFileExt(AFile), '.xaml');
end;

function RADWinUIRegistryKey: string;
begin
  Result := (BorlandIDEServices as IOTAServices).GetBaseRegistryKey + '\RADWinUI';
end;

/// The AI plugin for the editor: the one chosen in the IDE's AI options
/// (DefaultAIForEditor), else the first enabled plugin that can chat.
function EditorAIPlugin(out AProblem: string): IOTAAIPlugin;
var
  Registry: TRegistry;
  Name: string;
  I: Integer;
  Plugin: IOTAAIPlugin;

  function Usable(const APlugin: IOTAAIPlugin): Boolean;
  begin
    Result := (APlugin <> nil) and APlugin.Enabled and (afChat in APlugin.AvailableFeatures);
  end;

begin
  Result := nil;
  AProblem := 'No AI engine is enabled. Set up Claude, OpenAI, Gemini or Ollama in the IDE''s AI options ' +
    '(Tools > Options), then press Ctrl+Alt+Space again. Kai does not offer its engine to other packages.';
  if AIEngineService = nil then
    Exit;
  Name := '';
  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if Registry.OpenKeyReadOnly((BorlandIDEServices as IOTAServices).GetBaseRegistryKey + '\AI Engine') and
      Registry.ValueExists('DefaultAIForEditor') and (Registry.GetDataType('DefaultAIForEditor') = rdString) then
      Name := Registry.ReadString('DefaultAIForEditor');
  finally
    Registry.Free;
  end;
  if Name <> '' then
  begin
    Plugin := AIEngineService.GetPluginByName(Name);
    if Usable(Plugin) then
      Exit(Plugin);
  end;
  for I := 0 to AIEngineService.PluginCount - 1 do
  begin
    Plugin := AIEngineService.GetPluginByIndex(I);
    if Usable(Plugin) then
      Exit(Plugin);
  end;
end;

/// Forgets the pending request: its answer, if one still comes, is not inserted.
procedure CancelXamlCompletion;
begin
  if PendingCompletion <> nil then
    PendingCompletion.Detach;
  PendingCompletion := nil;
  PendingCompletionRef := nil;
end;

procedure TXamlAIRequest.Detach;
begin
  if (FPlugin <> nil) and (FNotifier >= 0) and (AIEngineService <> nil) then
    FPlugin.RemoveNotifier(FNotifier);
  FNotifier := -1;
  FPlugin := nil;
end;

procedure TXamlAIRequest.Done(const AAnswer, AError: string; const ARequestID: TGUID);
var
  Keep: IOTAAIServicesNotifier;
  Answered, Problem: string;
  ID: TGUID;
begin
  Keep := Self; // alive until the queued call has run
  Answered := AAnswer;
  Problem := AError;
  ID := ARequestID;
  // Plugins may answer on a worker thread, and removing a notifier while the plugin
  // calls them is not safe: the work runs on the main thread, after this call
  TThread.ForceQueue(nil,
    procedure
    var
      Text, Before, Suggestion: string;
      Ghost: TXamlGhost;
    begin
      if (Keep = nil) or (PendingCompletion <> Self) or not IsEqualGUID(ID, FRequest) then
        Exit;
      CancelXamlCompletion;
      if Assigned(FOnDone) then
      begin
        FOnDone(Answered, Problem);
        Exit;
      end;
      try
        if Problem <> '' then
        begin
          CompletionNote(Problem);
          Exit;
        end;
        Log('Complete XAML with AI answer: ' + LogText(Answered));
        Suggestion := FitXamlSuggestion(FXaml, FCursor, Answered, MaxInt);
        if Suggestion = '' then
        begin
          CompletionNote('no suggestion for this place.');
          Exit;
        end;
        if not CorrectXamlSuggestion(FXaml, FCursor, Suggestion, XamlVocabulary(FFile, FXaml), Ghost) then
        begin
          CompletionNote('the answer was not inserted, it uses names XAML does not know: ' + LogText(Suggestion));
          Exit;
        end;
        if SourceText(FFile) <> FXaml then
        begin
          CompletionNote('the XAML changed while the AI engine answered, press Ctrl+Alt+Space again.');
          Exit;
        end;
        Text := ApplyXamlGhost(FXaml, FCursor, Ghost);
        ApplyText(FFile, FXaml, Text);
        // The cursor goes after the suggestion
        Before := Text.Substring(0, FCursor + Length(Ghost.Text));
        GotoSource(FFile, Length(Before) - Length(Before.Replace(#10, '')) + 1,
          Length(Before) - Before.LastIndexOf(#10));
      except
        on E: Exception do
          CompletionNote(E.Message);
      end;
    end);
end;

procedure TXamlAIRequest.Answer(const AMessage: string; const ARequestID: TGUID);
begin
  Done(AMessage, '', ARequestID);
end;

procedure TXamlAIRequest.Error(const AMessage: string; const ARequestID: TGUID);
begin
  if AMessage = '' then
    Done('', 'the AI engine failed.', ARequestID)
  else
    Done('', AMessage, ARequestID);
end;

procedure TXamlAIRequest.ModelsLoaded(const AModels: TArray<string>; const ARequestID: TGUID);
begin
end;

procedure TXamlAIRequest.ImageLoaded(const AImage: TStream; const ARequestID: TGUID);
begin
end;

procedure TXamlAIRequest.ImageLoaded(const A64BitImages: TArray<string>; const ARequestID: TGUID);
begin
end;

procedure TXamlAIRequest.ImageURlLoaded(const AImageURls: TArray<string>; const ARequestID: TGUID);
begin
end;

procedure TXamlAIRequest.SpeechLoaded(const ASpeech: TStream; const ARequestID: TGUID);
begin
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

{ TXamlSuggestionNotifier }

procedure QueueSuggestionAnswer(const AID: TGUID; const AText, AError: string);
var
  ID: TGUID;
  Text, Error: string;
begin
  ID := AID;
  Text := AText;
  Error := AError;
  // Plugins may answer on a worker thread: the state lives on the main thread
  TThread.ForceQueue(nil,
    procedure
    begin
      if Suggestions <> nil then
        Suggestions.Answer(ID, Text, Error);
    end);
end;

procedure TXamlSuggestionNotifier.Answer(const AMessage: string; const ARequestID: TGUID);
begin
  QueueSuggestionAnswer(ARequestID, AMessage, '');
end;

procedure TXamlSuggestionNotifier.Error(const AMessage: string; const ARequestID: TGUID);
begin
  QueueSuggestionAnswer(ARequestID, '', AMessage + ' ');
end;

procedure TXamlSuggestionNotifier.ModelsLoaded(const AModels: TArray<string>; const ARequestID: TGUID);
begin
end;

procedure TXamlSuggestionNotifier.ImageLoaded(const AImage: TStream; const ARequestID: TGUID);
begin
end;

procedure TXamlSuggestionNotifier.ImageLoaded(const A64BitImages: TArray<string>; const ARequestID: TGUID);
begin
end;

procedure TXamlSuggestionNotifier.ImageURlLoaded(const AImageURls: TArray<string>; const ARequestID: TGUID);
begin
end;

procedure TXamlSuggestionNotifier.SpeechLoaded(const ASpeech: TStream; const ARequestID: TGUID);
begin
end;

{ TXamlEditorEvents }

function TXamlEditorEvents.AllowedEvents: TCodeEditorEvents;
begin
  Result := [cevPaintLineEvents, cevKeyboardEvents];
end;

function TXamlEditorEvents.AllowedLineStages: TPaintLineStages;
begin
  Result := [plsEndPaint];
end;

{ TXamlSuggestionController }

constructor TXamlSuggestionController.Create;
var
  Editors: INTACodeEditorServices;
  Events: TXamlEditorEvents;
begin
  inherited Create;
  FEventsIndex := -1;
  FPluginNotifier := -1;
  FState := TXamlSuggestions.Create(TRADWinUISettings.DefaultDelay);
  LoadSettings;
  if Supports(BorlandIDEServices, INTACodeEditorServices, Editors) then
  begin
    Events := TXamlEditorEvents.Create;
    Events.OnEditorPaintLine := PaintLine;
    Events.OnEditorKeyDown := KeyDown;
    FEvents := Events;
    FEventsIndex := Editors.AddEditorEventsNotifier(FEvents);
  end;
  FTimer := TTimer.Create(nil);
  FTimer.Interval := 50;
  FTimer.OnTimer := Tick;
  Suggestions := Self;
end;

destructor TXamlSuggestionController.Destroy;
var
  Editors: INTACodeEditorServices;
begin
  Suggestions := nil;
  FreeAndNil(FTimer);
  if (FEventsIndex >= 0) and Supports(BorlandIDEServices, INTACodeEditorServices, Editors) then
    Editors.RemoveEditorEventsNotifier(FEventsIndex);
  FEventsIndex := -1;
  if FEvents <> nil then
  begin
    (FEvents as TXamlEditorEvents).OnEditorPaintLine := nil;
    (FEvents as TXamlEditorEvents).OnEditorKeyDown := nil;
  end;
  FEvents := nil;
  ReleasePlugin;
  FState.Free;
  inherited;
end;

procedure TXamlSuggestionController.LoadSettings;
var
  Settings: TRADWinUISettings;
begin
  Settings := TRADWinUISettings.Load(RADWinUIRegistryKey);
  FEnabled := Settings.AISuggestions;
  FState.Delay := Settings.SuggestionDelay;
  if not FEnabled and (FState.Ghost <> '') then
  begin
    FState.Dismiss;
    Invalidate;
  end;
end;

procedure TXamlSuggestionController.ReleasePlugin;
begin
  if (FPlugin <> nil) and (FPluginNotifier >= 0) and (AIEngineService <> nil) then
    FPlugin.RemoveNotifier(FPluginNotifier);
  FPluginNotifier := -1;
  FPlugin := nil;
end;

function TXamlSuggestionController.Plugin: IOTAAIPlugin;
var
  Current: IOTAAIPlugin;
  Problem: string;
begin
  // The IDE's AI options may change: look again every 5 seconds at most
  if GetTickCount64 - FPluginCheckedAt > 5000 then
  begin
    FPluginCheckedAt := GetTickCount64;
    Current := EditorAIPlugin(Problem);
    if Current <> FPlugin then
    begin
      ReleasePlugin;
      FPlugin := Current;
      if FPlugin <> nil then
        FPluginNotifier := FPlugin.AddNotifier(TXamlSuggestionNotifier.Create);
    end;
  end;
  Result := FPlugin;
end;

procedure TXamlSuggestionController.Invalidate;
var
  Editors: INTACodeEditorServices;
begin
  if Supports(BorlandIDEServices, INTACodeEditorServices, Editors) then
    Editors.InvalidateTopEditor;
end;

procedure TXamlSuggestionController.Tick(Sender: TObject);
var
  Editors: INTACodeEditorServices;
  Buffer: IOTAEditBuffer;
  View: IOTAEditView;
  Position: TOTAEditPos;
  Engine: IOTAAIPlugin;
  Text, Prompt: string;
  Started, Took: UInt64;
  ID: TGUID;
  Delay: Cardinal;
begin
  if not FEnabled or FStopped then
    Exit;
  try
    // Only while the IDE's code editor has the keyboard: not in Design, not in other windows
    if not Supports(BorlandIDEServices, INTACodeEditorServices, Editors) or (Screen.ActiveControl = nil) or
      not Editors.IsIDEEditor(Screen.ActiveControl) then
      Exit;
    Buffer := (BorlandIDEServices as IOTAEditorServices).TopBuffer;
    if (Buffer = nil) or not IsXamlFile(Buffer.FileName) or (Buffer.TopView = nil) then
    begin
      if FState.Ghost <> '' then
      begin
        FState.Dismiss;
        Invalidate;
      end;
      Exit;
    end;
    View := Buffer.TopView;
    if not SameText(Buffer.FileName, FFile) then
    begin
      // Another .xaml file: a fresh state, the old ghost text goes
      FFile := Buffer.FileName;
      Delay := FState.Delay;
      FState.Free;
      FState := TXamlSuggestions.Create(Delay);
      FKeyed := True;
      Invalidate;
    end;
    Position := View.CursorPos;
    if FKeyed or (Position.Line <> FLastPos.Line) or (Position.Col <> FLastPos.Col) then
    begin
      FKeyed := False;
      FLastPos := Position;
      Text := SourceText(FFile);
      if FState.Observe(Text, ViewOffset(View, Text, Position), GetTickCount64) then
      begin
        FGhostPos := Position;
        Invalidate;
      end;
    end;
    if not FState.Due(GetTickCount64) then
    begin
      if FState.Ghost <> '' then
        FGhostPos := FLastPos; // a cached answer
      Exit;
    end;
    Engine := Plugin;
    if Engine = nil then
      Exit;
    Prompt := BuildXamlSuggestion(FState.RequestText, FState.RequestCursor,
      ProjectUserControls(FState.RequestText, ExtractFilePath(FFile)));
    FState.Vocabulary := XamlVocabulary(FFile, FState.RequestText);
    Started := GetTickCount64;
    ID := Engine.Chat(Prompt);
    FState.Sent(ID, GetTickCount64);
    Took := GetTickCount64 - Started;
    FRequestedAt := Started;
    Log(Format('AI suggestion asked: %d characters, %d ms after the last key', [Length(Prompt),
      Started - FKeyAt]));
    // Chat is asynchronous by contract (a request ID, the answer through the notifier).
    // A plugin that blocks would make typing slow: then the suggestions stop.
    if Took > 300 then
    begin
      FStopped := True;
      EditorNote(Format('AI suggestions while typing are off until the IDE restarts: %s took %d ms ' +
        'to take a request, which would slow typing down. Ctrl+Alt+Space still works.', [Engine.Name, Took]));
    end;
  except
    on E: Exception do
    begin
      FStopped := True;
      EditorNote('AI suggestions while typing stopped: ' + E.Message);
    end;
  end;
end;

procedure TXamlSuggestionController.Answer(const AID: TGUID; const AText, AError: string);
var
  Buffer: IOTAEditBuffer;
begin
  if AError <> '' then
  begin
    FState.Failed(AID);
    Exit;
  end;
  if not FState.Answered(AID, AText) then
  begin
    if FState.LastAnswer = AText then // this request's answer, not shown: say why in the log
      Log(Format('AI suggestion in %d ms, not shown (stale, or names XAML does not know): ',
        [GetTickCount64 - FRequestedAt]) + LogText(AText));
    Exit;
  end;
  Log(Format('AI suggestion in %d ms: ', [GetTickCount64 - FRequestedAt]) + LogText(AText) + ' -> ' +
    LogText(FState.Ghost));
  Buffer := (BorlandIDEServices as IOTAEditorServices).TopBuffer;
  if (Buffer <> nil) and SameText(Buffer.FileName, FFile) and (Buffer.TopView <> nil) then
    FGhostPos := Buffer.TopView.CursorPos
  else
    FState.Dismiss;
  Invalidate;
end;

procedure TXamlSuggestionController.AcceptGhost;
var
  OldText, NewText: string;
  NewCursor, Line, Column: Integer;
begin
  OldText := FState.Text;
  if not FState.Accept(NewText, NewCursor) then
    Exit;
  try
    ApplyText(FFile, OldText, NewText); // one undoable edit, refused when the text changed
    LineColumnOf(NewText, NewCursor, Line, Column);
    GotoSource(FFile, Line, Column);
  except
    on E: Exception do
      EditorNote('AI suggestion: ' + E.Message);
  end;
  Invalidate;
end;

procedure TXamlSuggestionController.KeyDown(const Editor: TWinControl; Key: Word; Shift: TShiftState;
  var Handled: Boolean);
var
  Editors: INTACodeEditorServices;
  View: IOTAEditView;
begin
  FKeyed := True;
  FKeyAt := GetTickCount64;
  if (FState.Ghost = '') or not Supports(BorlandIDEServices, INTACodeEditorServices, Editors) then
    Exit;
  View := Editors.GetViewForEditor(Editor);
  if (View = nil) or (View.Buffer = nil) or not SameText(View.Buffer.FileName, FFile) then
    Exit;
  if (Key = VK_TAB) and (Shift = []) then
  begin
    Handled := True;
    AcceptGhost;
  end
  else if (Key = VK_ESCAPE) and (Shift = []) then
  begin
    Handled := True;
    FState.Dismiss;
    Invalidate;
  end;
end;

/// The ghost text's colour: halfway between the editor's text and background.
function GhostColor(AText, ABackground: TColor): TColor;
var
  Text, Background: TColor;
begin
  Text := ColorToRGB(AText);
  Background := ColorToRGB(ABackground);
  Result := RGB((GetRValue(Text) + GetRValue(Background)) div 2, (GetGValue(Text) + GetGValue(Background)) div 2,
    (GetBValue(Text) + GetBValue(Background)) div 2);
end;

procedure TXamlSuggestionController.PaintLine(const Rect: TRect; const Stage: TPaintLineStage;
  const BeforeEvent: Boolean; var AllowDefaultPainting: Boolean; const Context: INTACodeEditorPaintContext);
var
  Editors: INTACodeEditorServices;
  Lines: TArray<string>;
  Index: Integer;
  Line: string;
  Cell, Code: TRect;
  Background, Foreground: TColor;
  Canvas: TCanvas;
  Font: TFont;
begin
  // Every line of every editor comes here: leave at once when there is nothing to draw
  if (FState.Ghost = '') or BeforeEvent or (Stage <> plsEndPaint) or (Context = nil) then
    Exit;
  Index := Context.LogicalLineNum - FGhostPos.Line;
  if (Index < 0) or not SameText(Context.FileName, FFile) then
    Exit;
  Lines := FState.Ghost.Replace(#13, '').Split([#10]);
  if Index > High(Lines) then
    Exit;
  try
    if not Supports(BorlandIDEServices, INTACodeEditorServices, Editors) then
      Exit;
    Line := Lines[Index].Replace(#9, StringOfChar(' ', 4));
    Background := Editors.Options.BackgroundColor[atWhiteSpace];
    Foreground := Editors.Options.FontColor[atWhiteSpace];
    if (Background = clDefault) or (Background = clNone) then
      Background := clWindow;
    if (Foreground = clDefault) or (Foreground = clNone) then
      Foreground := clWindowText;
    Canvas := Context.Canvas;
    Font := TFont.Create;
    try
      Editors.Options.GetEditorFont(Font);
      Canvas.Font.Assign(Font);
    finally
      Font.Free;
    end;
    Canvas.Font.Style := [fsItalic];
    Canvas.Font.Color := GhostColor(Foreground, Background);
    if Index = 0 then
    begin
      // After the cursor, on its line
      Cell := Context.EditorState.GetCharacterPosPx(FGhostPos.Col, Context.EditorLineNum);
      Canvas.Brush.Style := bsClear;
      Canvas.TextOut(Cell.Left, Cell.Top, Line);
    end
    else
    begin
      // The next lines of the suggestion cover the lines below until Tab or Esc
      Code := Context.LineState.CodeRect;
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := Background;
      Canvas.FillRect(Code);
      Cell := Context.EditorState.GetCharacterPosPx(1, Context.EditorLineNum);
      Canvas.Brush.Style := bsClear;
      Canvas.TextOut(Cell.Left, Cell.Top, Line);
    end;
  except
    // Painting never fails the editor
  end;
end;

{ TXamlHotReloadSender }

constructor TXamlHotReloadSender.Create;
begin
  inherited;
  FSeen := TDictionary<string, string>.Create;
  FChangedAt := TDictionary<string, UInt64>.Create;
  FSent := TDictionary<string, string>.Create;
  FTimer := TTimer.Create(nil);
  FTimer.Interval := 250;
  FTimer.OnTimer := Tick;
end;

destructor TXamlHotReloadSender.Destroy;
begin
  FreeAndNil(FTimer);
  FSent.Free;
  FChangedAt.Free;
  FSeen.Free;
  inherited;
end;

function TXamlHotReloadSender.XamlFiles: TArray<string>;
var
  Modules: IOTAModuleServices;
  I: Integer;
begin
  Result := nil;
  Modules := BorlandIDEServices as IOTAModuleServices;
  for I := 0 to Modules.ModuleCount - 1 do
    if SameText(ExtractFileExt(Modules.Modules[I].FileName), '.xaml') then
      Result := Result + [Modules.Modules[I].FileName];
end;

function TXamlHotReloadSender.TextOf(const AFile: string): string;
begin
  // While typing: the editor buffer. On save: the file as saved
  if FMode = hrWhileTyping then
    Result := SourceText(AFile)
  else if FileExists(AFile) then
    Result := TFile.ReadAllText(AFile)
  else
    Result := '';
end;

procedure TXamlHotReloadSender.Send(const AFile, AText: string; const AApps: TArray<THotReloadApp>);
var
  Pas, Generated, Error, Content, Shape: string;
  Message: TBytes;
  App: THotReloadApp;
begin
  Content := '';
  Shape := '';
  Error := '';
  // A window, page or user control has its unit: XamlCodeGen gives what the app compares and
  // loads. Any other .xaml (TWinUIHost.XamlFile) goes as it is
  Pas := ChangeFileExt(AFile, '.pas');
  if FileExists(Pas) or ((BorlandIDEServices as IOTAModuleServices).FindModule(Pas) <> nil) then
    GenerateCode(AFile, AText, SourceText(Pas), Generated, Error, True, Content, Shape);
  Message := HotReloadMessage(AFile, Shape, Content, AText, Error);
  for App in AApps do
    if SendHotReload(App.ProcessId, Message) then
    begin
      FSent.AddOrSetValue(IntToStr(App.ProcessId) + '|' + AFile, AText);
      Log(Format('hot reload: %s sent to %s (pid %d)%s', [ExtractFileName(AFile), ExtractFileName(App.ExePath),
        App.ProcessId, IfThen(Error <> '', ', XamlCodeGen: ' + Error, '')]));
    end;
end;

procedure TXamlHotReloadSender.Tick(Sender: TObject);
var
  Ticks: UInt64;
  FileName, Text, Key, Sent: string;
  App: THotReloadApp;
  Apps, Due: TArray<THotReloadApp>;
  Changed: UInt64;
  Known: Boolean;
begin
  Ticks := GetTickCount64;
  try
    if Ticks - FModeAt > 2000 then
    begin
      FMode := TRADWinUISettings.Load(RADWinUIRegistryKey).HotReload;
      FModeAt := Ticks;
    end;
    if FMode = hrOff then
      Exit;
    if Ticks - FAppsAt > 1000 then
    begin
      Apps := HotReloadApps;
      // An app that just started has the XAML it was built with: what is open now is its start
      for App in Apps do
      begin
        Known := False;
        for var Old in FApps do
          if Old.ProcessId = App.ProcessId then
            Known := True;
        if not Known then
          for FileName in XamlFiles do
            if AppUsesFile(App.ExePath, FileName) then
              FSent.AddOrSetValue(IntToStr(App.ProcessId) + '|' + FileName, TextOf(FileName));
      end;
      FApps := Apps;
      FAppsAt := Ticks;
      if FApps = nil then
        FSent.Clear;
    end;
    if FApps = nil then
      Exit;
    for FileName in XamlFiles do
    begin
      Text := TextOf(FileName);
      if not FSeen.TryGetValue(FileName, Sent) or (Sent <> Text) then
      begin
        FSeen.AddOrSetValue(FileName, Text);
        FChangedAt.AddOrSetValue(FileName, Ticks);
        Continue;
      end;
      // The same pause as the preview before a typed change goes out
      if FChangedAt.TryGetValue(FileName, Changed) and (Ticks - Changed < 500) and (FMode = hrWhileTyping) then
        Continue;
      Due := nil;
      for App in FApps do
      begin
        Key := IntToStr(App.ProcessId) + '|' + FileName;
        if AppUsesFile(App.ExePath, FileName) and (not FSent.TryGetValue(Key, Sent) or (Sent <> Text)) then
          Due := Due + [App];
      end;
      if Due <> nil then
        Send(FileName, Text, Due);
    end;
  except
    on E: Exception do
      Log('hot reload: ' + E.Message);
  end;
end;

{ TRADWinUIOptions }

function TRADWinUIOptions.GetArea: string;
begin
  Result := ''; // Third Party
end;

function TRADWinUIOptions.GetCaption: string;
begin
  Result := 'RADWinUI';
end;

function TRADWinUIOptions.GetFrameClass: TCustomFrameClass;
begin
  Result := TFrame; // a plain frame, FrameCreated adds the controls
end;

procedure TRADWinUIOptions.FrameCreated(AFrame: TCustomFrame);
var
  Settings: TRADWinUISettings;
  Heading, Caption, Note: TLabel;
  Theming: IOTAIDEThemingServices;
begin
  Settings := TRADWinUISettings.Load(RADWinUIRegistryKey);
  FLoading := True;
  try
    Heading := TLabel.Create(AFrame);
    Heading.Parent := AFrame;
    Heading.SetBounds(16, 12, 300, 16);
    Heading.Caption := 'XAML editor';
    Heading.Font.Style := [fsBold];
    FSuggestions := TCheckBox.Create(AFrame);
    FSuggestions.Parent := AFrame;
    FSuggestions.SetBounds(24, 38, 460, 20);
    FSuggestions.Caption := 'AI suggestions while typing (ghost text, Tab inserts it)';
    FSuggestions.Checked := Settings.AISuggestions;
    FSuggestions.OnClick := Changed;
    Caption := TLabel.Create(AFrame);
    Caption.Parent := AFrame;
    Caption.SetBounds(44, 68, 200, 16);
    Caption.Caption := 'Ask after a pause of (ms):';
    FDelay := TEdit.Create(AFrame);
    FDelay.Parent := AFrame;
    FDelay.SetBounds(250, 64, 70, 22);
    FDelay.NumbersOnly := True;
    FDelay.Text := IntToStr(Settings.SuggestionDelay);
    FDelay.OnChange := Changed;
    FDelay.OnExit := DelayExit;
    FLastDelay := Settings.SuggestionDelay;
    FError := TLabel.Create(AFrame);
    FError.Parent := AFrame;
    FError.SetBounds(330, 68, 300, 16);
    FError.Caption := Format('Between %d and %d ms', [TRADWinUISettings.MinDelay, TRADWinUISettings.MaxDelay]);
    FError.StyleElements := [];
    FError.Font.Color := RGB(232, 72, 72);
    FError.Transparent := True;
    FError.Visible := False;
    FCodeCompletion := TCheckBox.Create(AFrame);
    FCodeCompletion.Parent := AFrame;
    FCodeCompletion.SetBounds(24, 98, 460, 20);
    FCodeCompletion.Caption := 'Code completion (offline, coming soon)';
    FCodeCompletion.Checked := Settings.CodeCompletion;
    FCodeCompletion.OnClick := Changed;
    FPromptSelection := TCheckBox.Create(AFrame);
    FPromptSelection.Parent := AFrame;
    FPromptSelection.SetBounds(24, 124, 520, 20);
    FPromptSelection.Caption := 'Copy the selected XAML into the prompt (Ctrl+Alt+Space)';
    FPromptSelection.Checked := Settings.PromptWithSelection;
    FPromptSelection.OnClick := Changed;
    Heading := TLabel.Create(AFrame);
    Heading.Parent := AFrame;
    Heading.SetBounds(16, 160, 300, 16);
    Heading.Caption := 'Hot reload';
    Heading.Font.Style := [fsBold];
    Caption := TLabel.Create(AFrame);
    Caption.Parent := AFrame;
    Caption.SetBounds(24, 188, 220, 16);
    Caption.Caption := 'Send edited XAML to the running app:';
    FHotReload := TComboBox.Create(AFrame);
    FHotReload.Parent := AFrame;
    FHotReload.Style := csDropDownList;
    FHotReload.SetBounds(250, 184, 220, 22);
    FHotReload.Items.Add('Off');
    FHotReload.Items.Add('When a .xaml file is saved');
    FHotReload.Items.Add('While typing');
    FHotReload.ItemIndex := Ord(Settings.HotReload);
    FHotReload.OnChange := Changed;
    Note := TLabel.Create(AFrame);
    Note.Parent := AFrame;
    // The width of the page, and with it when the dialog is resized
    Note.AutoSize := False;
    Note.WordWrap := True;
    if AFrame.ClientWidth - 48 > 300 then
      Note.SetBounds(24, 222, AFrame.ClientWidth - 48, 110)
    else
      Note.SetBounds(24, 222, 300, 110);
    Note.Anchors := [akLeft, akTop, akRight];
    Note.Caption := 'Changes are saved at once. The suggestions appear on a line still being typed, such as "<Butt", ' +
      'and come from the AI plugin set up for the editor in the IDE''s AI options. To write a whole UI from a ' +
      'description, right-click and choose Create XAML with AI (Ctrl+Alt+Space). Hot reload updates the windows, ' +
      'pages and user controls of an app that runs in Debug from the project folder: changes to Pascal code, ' +
      'new event handlers or removed x:Name elements still need a rebuild.';
  finally
    FLoading := False;
  end;
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, Theming) then
    Theming.ApplyTheme(AFrame);
end;

procedure TRADWinUIOptions.Changed(Sender: TObject);
var
  Settings: TRADWinUISettings;
  Delay: Integer;
begin
  if FLoading or (FSuggestions = nil) or (FDelay = nil) or (FCodeCompletion = nil) then
    Exit;
  FError.Visible := not DelayValid;
  Settings := TRADWinUISettings.Load(RADWinUIRegistryKey);
  Settings.AISuggestions := FSuggestions.Checked;
  Settings.CodeCompletion := FCodeCompletion.Checked;
  if FPromptSelection <> nil then
    Settings.PromptWithSelection := FPromptSelection.Checked;
  if (FHotReload <> nil) and (FHotReload.ItemIndex >= 0) then
    Settings.HotReload := TRADWinUIHotReload(FHotReload.ItemIndex);
  // A pause still being typed is saved once it is in range
  if TryStrToInt(FDelay.Text, Delay) and (Delay >= TRADWinUISettings.MinDelay) and
    (Delay <= TRADWinUISettings.MaxDelay) then
  begin
    Settings.SuggestionDelay := Delay;
    FLastDelay := Delay;
  end;
  try
    Settings.Save(RADWinUIRegistryKey);
  except
    on E: Exception do
      Log('settings: ' + E.Message);
  end;
  if Suggestions <> nil then
    Suggestions.LoadSettings;
end;

procedure TRADWinUIOptions.DelayExit(Sender: TObject);
begin
  // The IDE closes Options on Save even when ValidateContents is False: the pause is
  // checked when the field is left, and an invalid one goes back to the last saved value
  if DelayValid then
    Exit;
  ShowMessage(Format('The pause is between %d and %d milliseconds.',
    [TRADWinUISettings.MinDelay, TRADWinUISettings.MaxDelay]));
  FDelay.Text := IntToStr(FLastDelay);
  FError.Visible := False;
  if FDelay.CanFocus then
  begin
    FDelay.SetFocus;
    FDelay.SelectAll;
  end;
end;

function TRADWinUIOptions.DelayValid: Boolean;
var
  Delay: Integer;
begin
  Result := (FDelay = nil) or (TryStrToInt(FDelay.Text, Delay) and (Delay >= TRADWinUISettings.MinDelay) and
    (Delay <= TRADWinUISettings.MaxDelay));
end;

function TRADWinUIOptions.ValidateContents: Boolean;
begin
  // False keeps the Options dialog open: the error shows next to the field, no message box
  Result := DelayValid;
  if not Result then
  begin
    FError.Visible := True;
    if FDelay.CanFocus then
    begin
      FDelay.SetFocus;
      FDelay.SelectAll;
    end;
  end;
end;

procedure TRADWinUIOptions.DialogClosed(Accepted: Boolean);
begin
  // Every change was saved when it was made
  FSuggestions := nil; // the IDE frees the frame and its controls
  FDelay := nil;
  FCodeCompletion := nil;
  FPromptSelection := nil;
  FHotReload := nil;
  FError := nil;
end;

function TRADWinUIOptions.GetHelpContext: Integer;
begin
  Result := 0;
end;

function TRADWinUIOptions.IncludeInIDEInsight: Boolean;
begin
  Result := True;
end;

{ TPreviewCommand }

constructor TPreviewCommand.Create;
var
  Keys: IOTAKeyboardServices;
  Options: INTAEnvironmentOptionsServices;
  EditorAction: TAction;
  I: Integer;
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
  FCompleteAction := TAction.Create(nil);
  FCompleteAction.Caption := 'Create XAML with AI...';
  FCompleteAction.Hint := 'Describe a UI and the IDE''s AI engine writes its XAML at the cursor of a .xaml file';
  FCompleteAction.Category := 'Tools';
  FCompleteAction.ShortCut := ShortCut(VK_SPACE, [ssCtrl, ssAlt]);
  FCompleteAction.OnExecute := ExecuteComplete;
  FCompleteAction.OnUpdate := Update;
  FCompleteAction.ActionList := (BorlandIDEServices as INTAServices).ActionList;
  FCompleteItem := TMenuItem.Create(nil);
  FCompleteItem.Action := FCompleteAction;
  FSettingsAction := TAction.Create(nil);
  FSettingsAction.Caption := 'Settings...';
  FSettingsAction.Hint := 'Tools > Options > Third Party > RADWinUI';
  FSettingsAction.Category := 'Tools';
  FSettingsAction.OnExecute := ExecuteSettings;
  FSettingsAction.ActionList := (BorlandIDEServices as INTAServices).ActionList;
  FSettingsItem := TMenuItem.Create(nil);
  FSettingsItem.Action := FSettingsAction;
  // Tools > RADWinUI > Preview, Docked Preview, Create XAML with AI..., Settings...
  FRootItem := TMenuItem.Create(nil);
  FRootItem.Caption := 'RADWinUI';
  FRootItem.Name := 'RADWinUIToolsMenu';
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
  FSuggestions := TXamlSuggestionController.Create;
  FHotReload := TXamlHotReloadSender.Create;
  // Toggle XAML Comment and Create XAML with AI in the code editor's context menu
  FEditorActions := TActionList.Create(nil);
  EditorAction := TAction.Create(FEditorActions);
  EditorAction.Caption := 'Toggle XAML Comment (Ctrl+/)';
  EditorAction.OnExecute := ExecuteComment;
  EditorAction := TAction.Create(FEditorActions);
  EditorAction.Caption := 'Create XAML with AI... (Ctrl+Alt+Space)';
  EditorAction.OnExecute := ExecuteComplete;
  for I := 0 to FEditorActions.ComponentCount - 1 do
  begin
    EditorAction := FEditorActions.Components[I] as TAction;
    EditorAction.Category := 'RADWinUIXaml';
    EditorAction.OnUpdate := EditorActionUpdate;
    EditorAction.ActionList := FEditorActions;
  end;
  (BorlandIDEServices as IOTAEditorServices).GetEditorLocalMenu.RegisterActionList(FEditorActions, 'RADWinUIXaml',
    cEdMenuCatClipboard);
  if Supports(BorlandIDEServices, INTAEnvironmentOptionsServices, Options) then
  begin
    FEditorOptions := TRADWinUIOptions.Create;
    Options.RegisterAddInOptions(FEditorOptions);
  end;
end;

procedure TPreviewCommand.AddToMenu(Sender: TObject);
begin
  Inc(FMenuTries);
  if FRootItem.Count = 0 then
  begin
    FRootItem.Add(FItem);
    FRootItem.Add(FDockedItem);
    FRootItem.Add(FCompleteItem);
    FRootItem.Add(FSettingsItem);
  end;
  FMenuTimer.Enabled := not InsertIntoToolsMenu((BorlandIDEServices as INTAServices).MainMenu, FRootItem) and
    (FMenuTries < 60);
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
/// names come from RADWinUI.Xaml.json, and for RADWinUI's own controls from
/// RADWinUI.Controls.json, so a control the metadata lacks is left out.
procedure TPreviewCommand.RegisterPalette;
var
  Json, Own: TJSONValue;
  Entries: TJSONArray;
  Classes, OwnClasses: TJSONObject;
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
  Own := nil;
  OwnClasses := nil;
  Path := TPath.Combine(RootFolder, 'src\Framework\RADWinUI.Controls.json');
  if FileExists(Path) then
    Own := TJSONObject.ParseJSONValue(TFile.ReadAllText(Path, TEncoding.UTF8));
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
      if Own is TJSONObject then
      begin
        OwnClasses := (Own as TJSONObject).GetValue('classes') as TJSONObject;
        Entries := (Own as TJSONObject).GetValue('palette') as TJSONArray;
        if Entries <> nil then
          for I := 0 to Entries.Count - 1 do
            Runtime.Values[(Entries.Items[I] as TJSONObject).GetValue<string>('name', '')] :=
              (Entries.Items[I] as TJSONObject).GetValue<string>('runtime', '');
      end;
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
              Wrapper := (Classes.GetValue(RuntimeName) as TJSONObject).GetValue<string>('wrapper', Wrapper)
            else if (OwnClasses <> nil) and (OwnClasses.GetValue(RuntimeName) is TJSONObject) then
              Wrapper := (OwnClasses.GetValue(RuntimeName) as TJSONObject).GetValue<string>('wrapper', Wrapper);
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
    Own.Free;
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
  FCompleteAction.Enabled := (Buffer <> nil) and SameText(ExtractFileExt(Buffer.FileName), '.xaml');
end;

procedure TPreviewCommand.ExecuteComplete(Sender: TObject);
var
  Buffer: IOTAEditBuffer;
begin
  Buffer := (BorlandIDEServices as IOTAEditorServices).TopBuffer;
  if Buffer <> nil then
    ShowXamlPrompt(Buffer.FileName);
end;

function TPreviewCommand.ShowXamlPrompt(const AFile: string): Boolean;
var
  Theming: IOTAIDEThemingServices;
  Background, Text, Border: TColor;
  Buffer: IOTAEditBuffer;
begin
  Result := IsXamlFile(AFile);
  if not Result then
    Exit;
  if FPromptBox <> nil then
  begin
    FPromptBox.Show;
    FPromptBox.Memo.SetFocus;
    Exit;
  end;
  Background := clWindow;
  Text := clWindowText;
  Border := clBtnShadow;
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, Theming) and Theming.IDEThemingEnabled then
  begin
    Background := Theming.StyleServices.GetStyleColor(scEdit);
    Text := Theming.StyleServices.GetStyleFontColor(sfEditBoxTextNormal);
    Border := Theming.StyleServices.GetStyleColor(scBorder);
  end;
  FPromptFile := AFile;
  // The accent of a quick prompt bar: a warm orange spark
  FPromptBox := TXamlPromptBox.CreateBox(nil, Background, Text, Border, RGB(217, 119, 87));
  FPromptBox.OnSubmit := PromptSubmit;
  FPromptBox.OnCancel := PromptCancel;
  FPromptBox.ShowOver(Application.MainForm);
  // Lines selected in the editor go into the bar, to describe what to make of them; the answer replaces them
  Buffer := (BorlandIDEServices as IOTAEditorServices).TopBuffer;
  if TRADWinUISettings.Load(RADWinUIRegistryKey).PromptWithSelection and (Buffer <> nil) and
    SameText(Buffer.FileName, AFile) and (Buffer.TopView <> nil) and (Buffer.TopView.Block <> nil) and
    Buffer.TopView.Block.IsValid and (Buffer.TopView.Block.Size > 0) then
  begin
    FPromptBox.Memo.Text := Buffer.TopView.Block.Text.Trim;
    FPromptBox.Memo.SelStart := Length(FPromptBox.Memo.Text);
  end;
end;

procedure TPreviewCommand.ClosePrompt;
begin
  FPromptRequest := nil;
  if FPromptBox <> nil then
  begin
    FPromptBox.OnCancel := nil;
    FPromptBox.Release;
    FPromptBox := nil;
  end;
end;

procedure TPreviewCommand.PromptCancel(Sender: TObject);
begin
  if FPromptRequest <> nil then
    CancelXamlCompletion; // its answer is not inserted
  ClosePrompt;
end;

procedure TPreviewCommand.PromptSubmit(const APrompt: string);
var
  Buffer: IOTAEditBuffer;
  View: IOTAEditView;
  Block: IOTAEditBlock;
  Plugin: IOTAAIPlugin;
  Request: TXamlAIRequest;
  Text, Problem: string;
  Start, Stop: TOTAEditPos;
begin
  Buffer := (BorlandIDEServices as IOTAEditorServices).TopBuffer;
  if (Buffer = nil) or not SameText(Buffer.FileName, FPromptFile) or (Buffer.TopView = nil) then
  begin
    FPromptBox.ShowError('Open ' + ExtractFileName(FPromptFile) + ' in the code editor first.');
    Exit;
  end;
  if APrompt = '' then
  begin
    // An empty bar: complete at the cursor, as before
    ClosePrompt;
    CompleteXaml(Buffer.FileName);
    Exit;
  end;
  Plugin := EditorAIPlugin(Problem);
  if Plugin = nil then
  begin
    FPromptBox.ShowError(Problem);
    Exit;
  end;
  View := Buffer.TopView;
  Text := SourceText(FPromptFile);
  Start := View.CursorPos;
  Stop := Start;
  Block := View.Block;
  if (Block <> nil) and Block.IsValid and (Block.Size > 0) then
  begin
    Start.Line := Block.StartingRow;
    Start.Col := Block.StartingColumn;
    Stop.Line := Block.EndingRow;
    Stop.Col := Block.EndingColumn;
  end;
  CancelXamlCompletion;
  Request := TXamlAIRequest.Create;
  PendingCompletionRef := Request;
  PendingCompletion := Request;
  Request.FFile := FPromptFile;
  Request.FXaml := Text;
  Request.FCursor := ViewOffset(View, Text, Start);
  Request.FSelEnd := ViewOffset(View, Text, Stop);
  Request.FOnDone := PromptAnswer;
  Request.FPlugin := Plugin;
  Request.FNotifier := Plugin.AddNotifier(Request);
  FPromptRequest := Request;
  FPromptBox.SetBusy(True, 'Writing the XAML with ' + Plugin.Name + '... (Esc cancels)');
  Log('Create XAML with AI: ' + LogText(APrompt));
  Request.FRequest := Plugin.Chat(BuildXamlFromDescription(Text, Request.FCursor, APrompt,
    ProjectUserControls(Text, ExtractFilePath(FPromptFile))));
end;

procedure TPreviewCommand.PromptAnswer(const AAnswer, AError: string);
var
  Request: TXamlAIRequest;
  Block, NewText: string;
  Ghost: TXamlGhost;
  Cursor, Line, Column: Integer;
begin
  Request := FPromptRequest;
  FPromptRequest := nil;
  if (Request = nil) or (FPromptBox = nil) then
    Exit; // cancelled
  if AError <> '' then
  begin
    FPromptBox.ShowError(AError);
    Exit;
  end;
  Log('Create XAML with AI answer: ' + LogText(AAnswer));
  Block := CleanXamlCompletion(AAnswer);
  if Block = '' then
  begin
    FPromptBox.ShowError('The AI engine sent no XAML. Describe it differently and press Enter.');
    Exit;
  end;
  // The same checks as the suggestions: known elements, their case corrected
  if not CorrectXamlSuggestion('', 0, Block, XamlVocabulary(Request.FFile, Request.FXaml), Ghost) then
  begin
    FPromptBox.ShowError('The answer uses names XAML does not know. Press Enter to ask again.');
    Exit;
  end;
  try
    if SourceText(Request.FFile) <> Request.FXaml then
    begin
      FPromptBox.ShowError('The file changed meanwhile. Press Enter to ask again.');
      Exit;
    end;
    NewText := PlaceXamlBlock(Request.FXaml, Request.FCursor, Request.FSelEnd, Ghost.Text, Cursor);
    ApplyText(Request.FFile, Request.FXaml, NewText); // one undoable edit
    ClosePrompt;
    LineColumnOf(NewText, Cursor, Line, Column);
    GotoSource(Request.FFile, Line, Column);
    EditorNote('Create XAML with AI: inserted ' + IntToStr(Length(Ghost.Text.Split([#10]))) + ' lines.');
  except
    on E: Exception do
      if FPromptBox <> nil then
        FPromptBox.ShowError(E.Message);
  end;
end;

procedure TPreviewCommand.ExecuteSettings(Sender: TObject);
var
  I: Integer;
  Actions: TCustomActionList;
begin
  // ToolsAPI has no call to open Options at a page, and the IDE keeps no last page: once the
  // dialog shows (a modal loop, so a timer), SelectOptionsPage selects our node in its tree
  if FOptionsTimer = nil then
  begin
    FOptionsTimer := TTimer.Create(nil);
    FOptionsTimer.Interval := 50;
    FOptionsTimer.OnTimer := SelectOptionsPage;
  end;
  FOptionsAskedAt := GetTickCount;
  FOptionsTimer.Enabled := True;
  Actions := (BorlandIDEServices as INTAServices).ActionList;
  for I := 0 to Actions.ActionCount - 1 do
    if SameText(Actions.Actions[I].Name, 'ToolsOptionsCommand') then
    begin
      Actions.Actions[I].Execute;
      Exit;
    end;
  FOptionsTimer.Enabled := False;
end;

/// The Options dialog's page tree is a VirtualTree (a type no package can name): its public
/// methods and properties are reached through RTTI. Selects Third Party > RADWinUI; anything
/// missing leaves the dialog as it opened.
procedure TPreviewCommand.SelectOptionsPage(Sender: TObject);

  function FindTree(AControl: TWinControl): TWinControl;
  var
    I: Integer;
  begin
    if AControl.ClassType.InheritsFrom(TWinControl) and AControl.ClassName.Contains('VirtualStringTree') then
      Exit(AControl);
    for I := 0 to AControl.ControlCount - 1 do
      if AControl.Controls[I] is TWinControl then
      begin
        Result := FindTree(TWinControl(AControl.Controls[I]));
        if Result <> nil then
          Exit;
      end;
    Result := nil;
  end;

var
  Form: TCustomForm;
  Tree: TWinControl;
  Context: TRttiContext;
  TreeType: TRttiType;
  Text: TRttiIndexedProperty;
  Node, Parent, Found: TValue;
  Caption: string;

  function IsNil(const AValue: TValue): Boolean;
  begin
    Result := AValue.IsEmpty or (PPointer(AValue.GetReferenceToRawData)^ = nil);
  end;

  function TextOf(const ANode: TValue): string;
  var
    Column: TValue;
  begin
    // Text[Node, Column]: the column index in its own type (TColumnIndex), -1 for the main column
    TValue.Make(-1, Text.ReadMethod.GetParameters[1].ParamType.Handle, Column);
    Result := Text.GetValue(Pointer(Tree), [ANode, Column]).AsString;
  end;

  // A public method by name: the overload that takes at least AArgs, the rest at their defaults
  // (False for a Boolean, the type's zero otherwise)
  function Call(const AName: string; const AArgs: array of TValue): TValue;
  var
    Method, Best: TRttiMethod;
    Params: TArray<TRttiParameter>;
    Args: TArray<TValue>;
    I: Integer;
  begin
    Best := nil;
    for Method in TreeType.GetMethods(AName) do
      if (Length(Method.GetParameters) >= Length(AArgs)) and
        ((Best = nil) or (Length(Method.GetParameters) < Length(Best.GetParameters))) then
        Best := Method;
    if Best = nil then
      raise Exception.Create(AName + ' not found');
    Params := Best.GetParameters;
    SetLength(Args, Length(Params));
    for I := 0 to High(Params) do
      if I <= High(AArgs) then
        Args[I] := AArgs[I]
      else
        TValue.Make(nil, Params[I].ParamType.Handle, Args[I]);
    Result := Best.Invoke(Tree, Args);
  end;

begin
  if GetTickCount - FOptionsAskedAt > 5000 then
    FOptionsTimer.Enabled := False;
  Form := Screen.ActiveCustomForm;
  if (Form = nil) or (Form.ClassName <> 'TDefaultEnvironmentDialog') then
    Exit;
  FOptionsTimer.Enabled := False;
  try
    Tree := FindTree(Form);
    if Tree = nil then
    begin
      Log('Settings: no page tree in the Options dialog');
      Exit;
    end;
    Context := TRttiContext.Create;
    TreeType := Context.GetType(Tree.ClassType);
    Text := TreeType.GetIndexedProperty('Text');
    // Third Party, a top-level node: opened, then its RADWinUI child
    Node := Call('GetFirst', []);
    Found := TValue.Empty;
    while not IsNil(Node) do
    begin
      Caption := TextOf(Node);
      if SameText(Caption, 'Third Party') then
      begin
        TreeType.GetIndexedProperty('Expanded').SetValue(Pointer(Tree), [Node], True);
        Parent := Node;
        Node := Call('GetFirstChild', [Parent]);
        while not IsNil(Node) do
        begin
          if SameText(TextOf(Node), 'RADWinUI') then
          begin
            Found := Node;
            Break;
          end;
          Node := Call('GetNextSibling', [Node]);
        end;
        Break;
      end;
      Node := Call('GetNextSibling', [Node]);
    end;
    if IsNil(Found) then
    begin
      Log('Settings: Third Party > RADWinUI not found in the Options tree');
      Exit;
    end;
    TreeType.GetIndexedProperty('Selected').SetValue(Pointer(Tree), [Found], True);
    TreeType.GetProperty('FocusedNode').SetValue(Pointer(Tree), Found);
    Call('ScrollIntoView', [Found, True]);
  except
    on E: Exception do
      Log('Settings: the Options page could not be selected: ' + E.ClassName + ': ' + E.Message);
  end;
end;

function TPreviewCommand.IsCommentKey(AKey: Word): Boolean;
var
  Key: TShortCut;
  Shift: TShiftState;
begin
  Shift := [];
  if GetKeyState(VK_CONTROL) < 0 then
    Include(Shift, ssCtrl);
  if GetKeyState(VK_SHIFT) < 0 then
    Include(Shift, ssShift);
  if GetKeyState(VK_MENU) < 0 then
    Include(Shift, ssAlt);
  Key := ShortCut(AKey, Shift);
  // Ctrl+/ on the main keyboard and the keypad, and Ctrl with the key that types "/" in this layout
  Result := (Key = ShortCut(VK_OEM_2, [ssCtrl])) or (Key = ShortCut(VK_DIVIDE, [ssCtrl])) or
    (Key = SlashShortCut(VkKeyScanEx('/', GetKeyboardLayout(0))));
end;

function TPreviewCommand.CompleteXaml(const AFile: string): Boolean;
var
  Buffer: IOTAEditBuffer;
  View: IOTAEditView;
  Plugin: IOTAAIPlugin;
  Request: TXamlAIRequest;
  Text, Problem: string;
  Cursor: Integer;
begin
  Result := IsXamlFile(AFile);
  if not Result then
    Exit;
  Buffer := (BorlandIDEServices as IOTAEditorServices).TopBuffer;
  if (Buffer = nil) or not SameText(Buffer.FileName, AFile) or (Buffer.TopView = nil) then
    Exit;
  Plugin := EditorAIPlugin(Problem);
  if Plugin = nil then
  begin
    ShowMessage(Problem);
    Exit;
  end;
  View := Buffer.TopView;
  Text := SourceText(AFile);
  Cursor := ViewOffset(View, Text, View.CursorPos);
  CancelXamlCompletion; // a new request replaces the one still pending
  Request := TXamlAIRequest.Create;
  PendingCompletionRef := Request;
  PendingCompletion := Request;
  Request.FFile := AFile;
  Request.FXaml := Text;
  Request.FCursor := Cursor;
  Request.FPlugin := Plugin;
  Request.FNotifier := Plugin.AddNotifier(Request);
  Request.FRequest := Plugin.Chat(BuildXamlCompletion(Text, Cursor, ProjectUserControls(Text, ExtractFilePath(AFile))));
  CompletionNote('asked ' + Plugin.Name + ', the answer goes in at the cursor.');
end;

procedure TPreviewCommand.EditorActionUpdate(Sender: TObject);
var
  Buffer: IOTAEditBuffer;
begin
  Buffer := (BorlandIDEServices as IOTAEditorServices).TopBuffer;
  (Sender as TAction).Visible := (Buffer <> nil) and IsXamlFile(Buffer.FileName);
end;

procedure TPreviewCommand.ExecuteComment(Sender: TObject);
begin
  ToggleComment((BorlandIDEServices as IOTAEditorServices).TopBuffer);
end;

function TPreviewCommand.ToggleComment(const ABuffer: IOTAEditBuffer): Boolean;
var
  View: IOTAEditView;
  Block: IOTAEditBlock;
  Cursor, Start, Stop: TOTAEditPos;
  Text, Toggled, Lines: string;
  Skipped: TArray<Integer>;
  Line: Integer;
begin
  Result := (ABuffer <> nil) and IsXamlFile(ABuffer.FileName);
  if not Result then
    Exit;
  View := ABuffer.TopView;
  if View = nil then
    Exit;
  Text := SourceText(ABuffer.FileName);
  Cursor := View.CursorPos;
  Start := Cursor;
  Stop := Cursor;
  Block := View.Block;
  if (Block <> nil) and Block.IsValid and (Block.Size > 0) then
  begin
    Start.Line := Block.StartingRow;
    Start.Col := Block.StartingColumn;
    Stop.Line := Block.EndingRow;
    Stop.Col := Block.EndingColumn;
  end;
  try
    Toggled := ToggleXamlComment(Text, ViewOffset(View, Text, Start), ViewOffset(View, Text, Stop), Skipped);
    if Toggled <> Text then
      ApplyText(ABuffer.FileName, Text, Toggled);
    // The same lines stay selected, the cursor where it was
    if (Block <> nil) and (Start.Line <> Stop.Line) then
    begin
      Start.Col := 1;
      View.CursorPos := Start;
      Block.BeginBlock;
      if Stop.Col > 1 then
      begin
        Stop.Line := Stop.Line + 1; // the selection covers whole lines
        Stop.Col := 1;
      end;
      View.CursorPos := Stop;
      Block.EndBlock;
    end
    else
      View.CursorPos := Cursor;
    View.Paint;
    if Skipped <> nil then
    begin
      MessageBeep(MB_ICONWARNING);
      Lines := '';
      for Line in Skipped do
        Lines := Lines + IntToStr(Line) + ', ';
      EditorNote('Ctrl+/: line ' + Lines.TrimRight([',', ' ']) +
        ' left as it is, a XAML comment cannot hold "--".');
    end;
  except
    on E: Exception do
    begin
      MessageBeep(MB_ICONWARNING);
      EditorNote('Ctrl+/: ' + E.Message);
    end;
  end;
end;

destructor TPreviewCommand.Destroy;
var
  Keys: IOTAKeyboardServices;
  Options: INTAEnvironmentOptionsServices;
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
  CancelXamlCompletion;
  FreeAndNil(FSuggestions);
  FreeAndNil(FHotReload);
  if FEditorActions <> nil then
    (BorlandIDEServices as IOTAEditorServices).GetEditorLocalMenu.UnregisterActionList('RADWinUIXaml');
  FreeAndNil(FEditorActions);
  if (FEditorOptions <> nil) and Supports(BorlandIDEServices, INTAEnvironmentOptionsServices, Options) then
    Options.UnregisterAddInOptions(FEditorOptions);
  FEditorOptions := nil;
  FreeAndNil(FPromptBox);
  FreeAndNil(FOptionsTimer);
  FCompleteItem.Free;
  FCompleteAction.Free;
  FSettingsItem.Free;
  FSettingsAction.Free;
  FDockedItem.Free;
  FContextMenu.Free;
  FDockedAction.Free;
  FIndex.Free;
  FMenuTimer.Free;
  FTimer.Free;
  FItem.Free;
  FAction.Free;
  FRootItem.Free; // after its items
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
        // Only RADWinUI windows, pages and user controls, a resource dictionary or other XAML stays in Code
        Elements := XamlElements(SourceText(AFile));
        if (Length(Elements) > 0) and MatchStr(Elements[0].Tag, ['Window', 'Page', 'UserControl']) and ShowDesignForFile(AFile) then
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

/// Ctrl and Shift as held with F9: F9 runs, Ctrl+F9 compiles, Shift+F9 builds and
/// Ctrl+Shift+F9 runs without debugging (whatever the IDE has bound to them).
function CtrlShift(ACtrl, AShift: Boolean): TShiftState;
begin
  Result := [];
  if ACtrl then Include(Result, ssCtrl);
  if AShift then Include(Result, ssShift);
end;

/// Keys of the design view that go to the IDE's actions: Ctrl combinations and F1..F11, never
/// with Alt and never a modifier key alone.
function IsIdeShortcutKey(AKey: Word; AShift: TShiftState): Boolean;
begin
  // Ctrl+Arrow moves the selected element
  Result := not (ssAlt in AShift) and
    not (AKey in [VK_SHIFT, VK_CONTROL, VK_MENU, VK_LWIN, VK_RWIN, VK_LEFT, VK_UP, VK_RIGHT, VK_DOWN]) and
    ((ssCtrl in AShift) or ((AKey >= VK_F1) and (AKey <= VK_F11)));
end;

procedure TPreviewCommand.ApplicationMessage(var Msg: TMsg; var Handled: Boolean);
var
  Editors: INTACodeEditorServices;
  Control: TWinControl;
  View: IOTAEditView;
begin
  // Ctrl+/ in a .xaml code editor, before the IDE's own Ctrl+/ (which writes Pascal's //)
  if not Handled and (Msg.message = WM_KEYDOWN) and (Application.ModalLevel = 0) and
    (GetKeyState(VK_CONTROL) < 0) and IsCommentKey(Msg.wParam) and
    Supports(BorlandIDEServices, INTACodeEditorServices, Editors) then
  begin
    Control := FindControl(Msg.hwnd);
    if (Control <> nil) and Editors.IsIDEEditor(Control) then
    begin
      View := Editors.GetViewForEditor(Control);
      if (View <> nil) and (View.Buffer <> nil) and IsXamlFile(View.Buffer.FileName) then
      begin
        Handled := True;
        if (Msg.lParam and $40000000) = 0 then // not a key repeat
          ToggleComment(View.Buffer);
      end;
    end;
  end;
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
    (Msg.wParam = VK_F9) and (GetKeyState(VK_MENU) >= 0) then
  begin
    Handled := True;
    if (Msg.lParam and $40000000) = 0 then
      IdeShortcut(ShortCut(VK_F9, CtrlShift(GetKeyState(VK_CONTROL) < 0, GetKeyState(VK_SHIFT) < 0)));
  end;
  // The Design frame itself does not pass shortcuts like Ctrl+S on to the IDE's actions
  if not Handled and FDesignViewActive and (Application.ModalLevel = 0) and (Msg.message = WM_KEYDOWN) and
    ((Msg.lParam and $40000000) = 0) and (FDesignSurface <> nil) and FDesignSurface.HandleAllocated and
    ((Msg.hwnd = FDesignSurface.Handle) or IsChild(FDesignSurface.Handle, Msg.hwnd)) and
    IsIdeShortcutKey(Msg.wParam, KeyDataToShiftState(Msg.lParam)) then
    Handled := IdeShortcut(ShortCut(Msg.wParam, KeyDataToShiftState(Msg.lParam) * [ssCtrl, ssShift]));
end;

/// Runs the IDE action bound to AKey. Edit and Search actions are left out: they would act on
/// the code editor hidden behind the design view.
function TPreviewCommand.IdeShortcut(AKey: TShortCut): Boolean;
var
  Actions: TCustomActionList;
  Action: TCustomAction;
  I: Integer;
begin
  Result := False;
  if Application.ModalLevel <> 0 then Exit;
  Actions := (BorlandIDEServices as INTAServices).ActionList;
  for I := 0 to Actions.ActionCount - 1 do
    if Actions.Actions[I] is TCustomAction then
    begin
      Action := TCustomAction(Actions.Actions[I]);
      if (Action.ShortCut <> AKey) and (Action.SecondaryShortCuts.IndexOfShortCut(AKey) < 0) then Continue;
      if SameText(Action.Category, 'Edit') or SameText(Action.Category, 'Search') then Continue;
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
    ThemedMessageDlg('RADWinUI Preview: no window to show. Open a RADWinUI window (its .xaml or its .pas unit), ' +
      'or a RADWinUI project with a MainWindow.xaml.', mtInformation, [mbOK]);
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
    if ThemedMessageDlg('The preview host is not built yet (Build All of ' + RADWinUIGroup + ' builds it). ' +
      'Build it now (about 10 seconds)?', mtConfirmation,
      [mbYes, mbNo]) <> mrYes then
      Exit;
    if not RunHidden(Format('powershell -NoProfile -ExecutionPolicy Bypass -File "%s" ' +
      '-Project src\IDE\Preview\RADWinUIPreview.dpr -Config Release',
      [TPath.Combine(RootFolder, 'scripts\Build.ps1')])) or (HostExe = '') then
    begin
      ThemedMessageDlg('Building the preview failed. See ' + TPath.Combine(RootFolder, 'build\logs\RADWinUIPreview.log') +
        ', or open ' + RADWinUIGroup + ' and use Build All.', mtError, [mbOK]);
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
  Part: string;
  Parts: TArray<string>;
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
      SyncSplitStructure;
      SyncStructure;
      // An event can navigate to Pascal/Code and hide Design. Input still queued
      // for that hidden surface must not immediately navigate back to XAML.
      while (FClient <> nil) and (not WasDesign or FDesignViewActive) and FClient.TakeEvent(Xaml) do
        if Xaml = 'CODEVIEW' then
          ShowXamlCode
        else if (Xaml = 'RUN') or (Xaml = 'COMPILE') or (Xaml = 'BUILD') or (Xaml = 'RUNNODEBUG') then
        begin
          IdeShortcut(ShortCut(VK_F9, CtrlShift((Xaml = 'COMPILE') or (Xaml = 'RUNNODEBUG'),
            (Xaml = 'BUILD') or (Xaml = 'RUNNODEBUG'))));
          Break; // a build/debug action can change the active desktop and designer
        end
        else if Xaml.StartsWith('SHORTCUT ') then
        begin
          IdeShortcut(StrToIntDef(Copy(Xaml, 10, MaxInt), 0));
          Break; // any IDE action can change the active desktop and designer
        end
        else if Xaml.StartsWith('CONTEXTMENU ') then
        begin
          Parts := Xaml.Split([' ']);
          if Length(Parts) = 4 then
            ShowContextMenu(StrToIntDef(Parts[1], 0), StrToIntDef(Parts[2], 0), Parts[3] = '1');
          Break; // its commands run once the menu closes, they can change the view
        end
        else if Xaml = 'SELECTPARENT' then
          SelectParent
        else if Xaml.StartsWith('NUDGE ') then
          NudgeSelection(Xaml)
        else if Xaml.StartsWith('NUDGEMULTI ') then
          NudgeMulti(Xaml)
        else if Xaml.StartsWith('MULTI ') then
        begin
          if FInspector <> nil then
            FInspector.Commit;
          FMulti := nil;
          for Part in Xaml.Substring(6).Split([';']) do
            if TDesignerSelection.Parse('SELECTED ' + Part, Selection) then
              FMulti := FMulti + [Selection];
          if Length(FMulti) > 0 then
          begin
            FSelection := FMulti[0];
            FSelectionPath := FXamlPath;
            Selected;
            Log(Format('designer: %d elements selected', [Length(FMulti)]));
          end;
        end
        else if Xaml = 'CUT' then
          CutSelection
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
          FMulti := nil;
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
      if FDesignViewActive and (FDesignSurface <> nil) then
        FDesignSurface.Caption := 'RADWinUI renderer stopped: ' + Xaml + '. Switch to Code and back to retry.';
      ThemedMessageDlg('RADWinUI Preview: ' + Xaml, mtWarning, [mbOK]);
    end;
  except
    on E: Exception do
    begin
      // Never let the preview take the IDE down: stop and say why
      Log('preview stopped: ' + E.ClassName + ': ' + E.Message);
      Stop;
      ThemedMessageDlg('RADWinUI Preview stopped: ' + E.Message, mtWarning, [mbOK]);
    end;
  end;
end;

procedure TPreviewCommand.Selected;
begin
  // Moving the code editor while Design is visible can hide/recreate its frame.
  if not FDesignViewActive then
    GotoSource(FXamlPath, FSelection.Line, FSelection.Column);
  // A click in the Split View designer brings its tree back to the Structure view
  if SplitActive then
    ShowSplitStructure;
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
      ThemedMessageDlg('RADWinUI: ' + E.Message, mtWarning, [mbOK]);
  end;
end;

function TPreviewCommand.DesignEditState: TEditState;
begin
  Result := [];
  if not Designing then Exit;
  Include(Result, esCanUndo);
  Include(Result, esCanRedo);
  if (FSelection.Line < 1) or
    not SameText(FSelectionPath, FXamlPath) then
    Exit;
  Include(Result, esCanCopy);
  try
    if CanDeleteSelection then
      Result := Result + [esCanDelete, esCanCut];
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
    eaCut: CutSelection;
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
  FMulti := nil;
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
  Positions, Deletable: TArray<TXamlPosition>;
  Position: TXamlPosition;
begin
  if not (esCanDelete in DesignEditState) then Exit;
  try
    if FInspector <> nil then FInspector.Commit;
    if Length(FMulti) > 1 then
    begin
      // Every selected element, but the window and its required content
      Xaml := SourceText(FXamlPath);
      Positions := MultiPositions;
      Deletable := nil;
      for Position in Positions do
        if CanDeleteElement(Xaml, Position.Line, Position.Column) then
          Deletable := Deletable + [Position];
      if Deletable = nil then Exit;
      ApplyText(FXamlPath, Xaml, DeleteElements(Xaml, Deletable));
      ClearSelection;
      SyncCode(True);
      SyncStructure;
      Exit;
    end;
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
      Exit((Element.ParentIndex >= 0) and not MatchStr(Elements[Element.ParentIndex].Tag, ['Window', 'Page', 'UserControl']));
    end;
end;

/// The editor buffer of the XAML, nil when it has none.
function TPreviewCommand.XamlBuffer: IOTAEditBuffer;
var
  Editor: IOTASourceEditor;
  Iterator: IOTAEditBufferIterator;
  I: Integer;
begin
  Result := nil;
  Editor := EditorOf(FXamlPath);
  if Editor.EditViewCount > 0 then Result := Editor.EditViews[0].Buffer
  else if (BorlandIDEServices as IOTAEditorServices).GetEditBufferIterator(Iterator) then
    for I := 0 to Iterator.Count - 1 do
      if SameText(Iterator.EditBuffers[I].FileName, FXamlPath) then
        Exit(Iterator.EditBuffers[I]);
end;

procedure TPreviewCommand.UndoDesigner(ARedo: Boolean);
var
  Buffer: IOTAEditBuffer;
  Changed: Boolean;
begin
  if not Designing then Exit;
  try
    if FInspector <> nil then FInspector.Commit;
    Buffer := XamlBuffer;
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
    if Length(FMulti) > 1 then
      Clipboard.AsText := CopyElements(SourceText(FXamlPath), MultiPositions)
    else
      Clipboard.AsText := CopyElement(SourceText(FXamlPath), FSelection.Line, FSelection.Column);
  except
    on E: Exception do
      ThemedMessageDlg('RADWinUI Copy: ' + E.Message, mtWarning, [mbOK]);
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
      ThemedMessageDlg('RADWinUI Paste: ' + E.Message, mtWarning, [mbOK]);
  end;
end;

/// Whether the keyboard focus is in the Split View designer, the host's window in the docked panel.
function TPreviewCommand.PreviewHasFocus: Boolean;
var
  Child: HWND;
  Info: TGUIThreadInfo;
begin
  Result := False;
  if (FPreviewSurface = nil) or not FPreviewSurface.HandleAllocated then Exit;
  Child := GetWindow(FPreviewSurface.Handle, GW_CHILD);
  if Child = 0 then Exit;
  Info := Default(TGUIThreadInfo);
  Info.cbSize := SizeOf(Info);
  Result := GetGUIThreadInfo(GetWindowThreadProcessId(Child, nil), Info) and (Info.hwndFocus <> 0) and
    ((Info.hwndFocus = Child) or IsChild(Child, Info.hwndFocus));
end;

/// Split View: the Structure view shows the design tree once the designer has the focus,
/// as it does for Design. The code editor shows what the IDE gives it when it gets the focus back.
procedure TPreviewCommand.SyncSplitStructure;
var
  Focused: Boolean;
begin
  if not FSplitView or FDesignViewActive then Exit;
  // The panel was closed: Split View is over
  if (FPreviewSurface <> nil) and FPreviewSurface.HandleAllocated and (FParentWindow = FPreviewSurface.Handle) and
    ((FPreviewDockForm = nil) or not FPreviewDockForm.Visible) then
  begin
    Log('Split View panel closed: ' + FXamlPath);
    EndSplitStructure;
    Stop;
    Exit;
  end;
  if not SplitActive then Exit;
  Focused := PreviewHasFocus;
  if Focused and not FPreviewFocused then
    ShowSplitStructure;
  FPreviewFocused := Focused;
end;

/// The design tree in the Structure view, for the Split View designer.
procedure TPreviewCommand.ShowSplitStructure;
var
  Context: IOTAStructureContext;
begin
  try
    Context := StructureForFile(FXamlPath);
    if (Context <> nil) and not FStructure.Shown then
    begin
      Log('Split View designer active: Structure shows ' + FXamlPath);
      (BorlandIDEServices as IOTAStructureView).SetStructureContext(Context);
    end;
  except
    on E: Exception do Log('Split View structure failed: ' + E.ClassName + ': ' + E.Message);
  end;
end;

/// Split View ended without Design: the design tree leaves the Structure view.
procedure TPreviewCommand.EndSplitStructure;
begin
  FSplitView := False;
  FPreviewFocused := False;
  try
    if (FStructure <> nil) and FStructure.Shown then
      (BorlandIDEServices as IOTAStructureView).SetStructureContext(nil);
  except
    on E: Exception do Log('Structure reset failed: ' + E.ClassName + ': ' + E.Message);
  end;
end;

/// NUDGE <line> <column> <left> <top>, a Ctrl+Arrow move. The moves of one burst (one element,
/// less than 1.5 s apart, nothing else edited) are one undo step: each takes back the previous one.
procedure TPreviewCommand.NudgeSelection(const AEvent: string);
var
  Parts: TArray<string>;
  Line, Column, Left, Top: Integer;
  Xaml: string;
  Buffer: IOTAEditBuffer;
begin
  Parts := AEvent.Split([' ']);
  if Length(Parts) <> 5 then Exit;
  Line := StrToIntDef(Parts[1], 0);
  Column := StrToIntDef(Parts[2], 0);
  Left := StrToIntDef(Parts[3], 0);
  Top := StrToIntDef(Parts[4], 0);
  try
    Xaml := SourceText(FXamlPath);
    if not CanNudgeElement(Xaml, Line, Column) then Exit;
    if (Xaml = FNudgeText) and (Line = FNudgeLine) and (Column = FNudgeColumn) and
      (GetTickCount - FNudgeAt < 1500) then
    begin
      Buffer := XamlBuffer;
      if (Buffer <> nil) and Buffer.Undo then
        if SourceText(FXamlPath) = FNudgeBase then
          Xaml := FNudgeBase
        else
        begin
          Buffer.Redo; // not the move it should have taken back: this one becomes its own step
          FNudgeBase := Xaml;
        end
      else
        FNudgeBase := Xaml;
    end
    else
      FNudgeBase := Xaml;
    FNudgeText := NudgeElement(Xaml, Line, Column, Left, Top);
    ApplyText(FXamlPath, Xaml, FNudgeText);
    FNudgeLine := Line;
    FNudgeColumn := Column;
    FNudgeAt := GetTickCount;
    FInspectorDirty := True;
  except
    on E: Exception do Log('designer move: ' + E.Message);
  end;
end;

/// The elements of the multi-selection where they are now: found by x:Name, else at their position.
function TPreviewCommand.MultiPositions: TArray<TXamlPosition>;
var
  Elements: TArray<TXamlElement>;
  Element: TXamlElement;
  Item: TDesignerSelection;
begin
  Result := nil;
  Elements := XamlElements(SourceText(FXamlPath));
  for Item in FMulti do
    for Element in Elements do
      if not Element.DesignOnly and (Element.Tag = Item.Tag) and
        (((Item.Name <> '') and (Element.Name = Item.Name)) or
         ((Item.Name = '') and (Element.Line = Item.Line) and (Element.Column = Item.Column))) then
      begin
        Result := Result + [TXamlPosition.Create(Element.Line, Element.Column)];
        Break;
      end;
end;

/// NUDGEMULTI <line> <column> <left> <top>;...: Ctrl+Arrow on a multi-selection, one change. The moves
/// of one burst are one undo step, as for one element.
procedure TPreviewCommand.NudgeMulti(const AEvent: string);
var
  Part, Xaml: string;
  Parts: TArray<string>;
  Moves: TArray<TXamlNudge>;
  Move: TXamlNudge;
  Buffer: IOTAEditBuffer;
begin
  Moves := nil;
  for Part in AEvent.Substring(Length('NUDGEMULTI ')).Split([';']) do
  begin
    Parts := Part.Split([' ']);
    if Length(Parts) <> 4 then Continue;
    Move.Line := StrToIntDef(Parts[0], 0);
    Move.Column := StrToIntDef(Parts[1], 0);
    Move.Left := StrToIntDef(Parts[2], 0);
    Move.Top := StrToIntDef(Parts[3], 0);
    Moves := Moves + [Move];
  end;
  if Moves = nil then Exit;
  try
    Xaml := SourceText(FXamlPath);
    if (Xaml = FNudgeText) and (FNudgeLine = -1) and (GetTickCount - FNudgeAt < 1500) then
    begin
      Buffer := XamlBuffer;
      if (Buffer <> nil) and Buffer.Undo then
        if SourceText(FXamlPath) = FNudgeBase then
          Xaml := FNudgeBase
        else
        begin
          Buffer.Redo; // not the move it should have taken back: this one becomes its own step
          FNudgeBase := Xaml;
        end
      else
        FNudgeBase := Xaml;
    end
    else
      FNudgeBase := Xaml;
    FNudgeText := NudgeElements(Xaml, Moves);
    ApplyText(FXamlPath, Xaml, FNudgeText);
    FNudgeLine := -1; // a multi move
    FNudgeAt := GetTickCount;
    FInspectorDirty := True;
  except
    on E: Exception do Log('designer move: ' + E.Message);
  end;
end;

procedure TPreviewCommand.CutSelection;
var
  State: TEditState;
begin
  State := DesignEditState;
  if not (esCanCopy in State) or not (esCanCut in State) then
    Exit;
  try
    if Length(FMulti) > 1 then
      Clipboard.AsText := CopyElements(SourceText(FXamlPath), MultiPositions)
    else
      Clipboard.AsText := CopyElement(SourceText(FXamlPath), FSelection.Line, FSelection.Column);
  except
    on E: Exception do
    begin
      ThemedMessageDlg('RADWinUI Cut: ' + E.Message, mtWarning, [mbOK]);
      Exit; // nothing goes that is not on the clipboard
    end;
  end;
  DeleteSelection;
end;

/// The index of the selected element in AElements, -1 when nothing of this file is selected.
function TPreviewCommand.SelectedIndex(const AElements: TArray<TXamlElement>): Integer;
begin
  if SameText(FSelectionPath, FXamlPath) and (FSelection.Line > 0) then
    for Result := 0 to High(AElements) do
      if not AElements[Result].DesignOnly and (AElements[Result].Tag = FSelection.Tag) and
        (((FSelection.Name <> '') and (AElements[Result].Name = FSelection.Name)) or
         ((FSelection.Name = '') and (AElements[Result].Line = FSelection.Line) and
          (AElements[Result].Column = FSelection.Column))) then
        Exit;
  Result := -1;
end;

/// The element that contains AElements[AIndex], past property elements such as Grid.RowDefinitions, or -1.
function ParentElement(const AElements: TArray<TXamlElement>; AIndex: Integer): Integer;
begin
  Result := AElements[AIndex].ParentIndex;
  while (Result >= 0) and (AElements[Result].DesignOnly or AElements[Result].Tag.Contains('.')) do
    Result := AElements[Result].ParentIndex;
end;

procedure TPreviewCommand.SelectParent;
var
  Elements: TArray<TXamlElement>;
  I: Integer;
begin
  if not Designing then Exit;
  try
    Elements := XamlElements(SourceText(FXamlPath));
    I := SelectedIndex(Elements);
    if I >= 0 then I := ParentElement(Elements, I);
    if I >= 0 then SelectStructureElement(Elements[I], False);
  except
    on E: EXamlEdit do ; // unfinished XAML has no parents to go to
  end;
end;

procedure TPreviewCommand.ReorderSelection(AToFront: Boolean);
var
  Xaml, Updated: string;
  Elements: TArray<TXamlElement>;
  Parent: TXamlElement;
  I, J, Moved: Integer;
begin
  Xaml := SourceText(FXamlPath);
  Elements := XamlElements(Xaml);
  I := SelectedIndex(Elements);
  if (I < 0) or not CanReorderElement(Xaml, Elements[I].Line, Elements[I].Column, AToFront) then Exit;
  Parent := Elements[Elements[I].ParentIndex];
  Updated := ReorderElement(Xaml, Elements[I].Line, Elements[I].Column, AToFront);
  ApplyText(FXamlPath, Xaml, Updated);
  // The parent did not move, the element is now its first or last child
  Elements := XamlElements(Updated);
  Moved := -1;
  for I := 0 to High(Elements) do
    if (Elements[I].Line = Parent.Line) and (Elements[I].Column = Parent.Column) then
      for J := 0 to High(Elements) do
        if (Elements[J].ParentIndex = I) and not Elements[J].Tag.Contains('.') and ((Moved < 0) or AToFront) then
          Moved := J;
  SyncCode(True);
  // The preview loads the new text before it selects in it
  if FClient <> nil then FClient.Tick(FXamlPath, Updated);
  if Moved >= 0 then SelectStructureElement(Elements[Moved], False);
  SyncStructure;
end;

/// Add Row, Add Column or Add Item on the selected element, one undoable change.
procedure TPreviewCommand.EditSelection(ACommand: Integer);
var
  Xaml, Updated: string;
  Elements: TArray<TXamlElement>;
  I: Integer;
begin
  Xaml := SourceText(FXamlPath);
  Elements := XamlElements(Xaml);
  I := SelectedIndex(Elements);
  if I < 0 then Exit;
  case ACommand of
    cmAddRow: Updated := AddGridTrack(Xaml, Elements[I].Line, Elements[I].Column, False);
    cmAddColumn: Updated := AddGridTrack(Xaml, Elements[I].Line, Elements[I].Column, True);
    cmAddItem: Updated := AddItem(Xaml, Elements[I].Line, Elements[I].Column);
  else
    Exit;
  end;
  ApplyText(FXamlPath, Xaml, Updated);
  SyncCode(True);
  SyncStructure;
  FInspectorDirty := True;
end;

/// The XAML code at the selected element's start tag.
procedure TPreviewCommand.ViewSelectionSource;
var
  Line, Column: Integer;
begin
  if not FileExists(FXamlPath) then Exit;
  Line := 1;
  Column := 1;
  if SameText(FSelectionPath, FXamlPath) and (FSelection.Line > 0) then
  begin
    Line := FSelection.Line;
    Column := FSelection.Column;
  end;
  if FDesignViewActive then ShowXamlCode;
  GotoSource(FXamlPath, Line, Column);
end;

/// The docked preview Split View opened shows the window next to its code.
function TPreviewCommand.SplitActive: Boolean;
begin
  Result := FSplitView and not FDesignViewActive and (FClient <> nil) and FDocked and
    (FPreviewSurface <> nil) and FPreviewSurface.HandleAllocated and (FParentWindow = FPreviewSurface.Handle) and
    (FPreviewDockForm <> nil) and FPreviewDockForm.Visible;
end;

/// The preview edits the XAML: in Design, or in Split View next to the code.
function TPreviewCommand.Designing: Boolean;
begin
  Result := FDesignViewActive or SplitActive;
end;

procedure TPreviewCommand.ToggleSplitView;
var
  Path: string;
begin
  Path := FXamlPath;
  if SplitActive then
  begin
    Log('Split View off: ' + Path);
    FSplitView := False;
    FPreviewFocused := False;
    Stop;
    if (FPreviewDockForm <> nil) and FPreviewDockForm.Visible then
      FPreviewDockForm.Close;
    ShowDesignForFile(Path);
    Exit;
  end;
  if not FDesignViewActive or not FileExists(Path) then Exit;
  Log('Split View on: ' + Path);
  FSplitView := True;
  ShowXamlCode;
  // Once the editor shows Code: the renderer moves from the Design frame to the docked preview
  TThread.ForceQueue(nil,
    procedure
    begin
      if (Command <> Self) or not FSplitView then Exit;
      if FDesignViewActive or not SameText(FindXaml, Path) then
      begin
        FSplitView := False;
        Exit;
      end;
      RunPreview(True);
      if SameText(FSelectionPath, Path) and (FSelection.Line > 0) then
        GotoSource(Path, FSelection.Line, FSelection.Column);
    end);
end;

function TPreviewCommand.AddContextItem(AParent: TMenuItem; const ACaption: string; ACommand: Integer;
  AEnabled: Boolean; AShortCut: TShortCut): TMenuItem;
begin
  Result := TMenuItem.Create(FContextMenu);
  Result.Caption := ACaption;
  Result.Tag := ACommand;
  Result.Enabled := AEnabled;
  Result.ShortCut := AShortCut; // shown only: the keys reach the designer, not this menu
  if ACommand <> 0 then Result.OnClick := ContextClick;
  AParent.Add(Result);
end;

/// Whether AEdit makes a change rather than raising EXamlEdit.
function Applies(const AEdit: TFunc<string>): Boolean;
begin
  try
    AEdit;
    Result := True;
  except
    on EXamlEdit do Result := False;
  end;
end;

/// The group of the right-clicked element's own commands, under its name. Nothing when it has none.
procedure TPreviewCommand.AddControlItems(const AXaml: string; const AElements: TArray<TXamlElement>;
  AIndex: Integer);
var
  Items, Orientation: TMenuItem;
  Element: TXamlElement;
  Event, Handler, Value, Name: string;
  Props: TArray<TDesignerProperty>;
  Prop: TDesignerProperty;
  First, Count, I: Integer;
  HasChildren: Boolean;
begin
  Items := FContextMenu.Items;
  Element := AElements[AIndex];
  First := Items.Count;
  AddContextItem(Items, '-', 0, True);
  AddContextItem(Items, Trim(Element.Tag + ' ' + Element.Name), 0, False);
  Count := Items.Count;
  Event := FIndex.DefaultEventOf(Element.Tag);
  if Event <> '' then
    if GetAttribute(AXaml, Element.Line, Element.Column, Event, Handler) and (Handler <> '') then
      AddContextItem(Items, 'Go to ' + Handler, cmEvent, True)
    else
      AddContextItem(Items, 'Create ' + Event + ' Handler', cmEvent, True);
  if Element.Tag = 'Grid' then
  begin
    AddContextItem(Items, 'Add Row', cmAddRow, Applies(
      function: string
      begin
        Result := AddGridTrack(AXaml, Element.Line, Element.Column, False);
      end));
    AddContextItem(Items, 'Add Column', cmAddColumn, Applies(
      function: string
      begin
        Result := AddGridTrack(AXaml, Element.Line, Element.Column, True);
      end));
  end;
  if Element.Tag = 'StackPanel' then
  begin
    if not GetAttribute(AXaml, Element.Line, Element.Column, 'Orientation', Value) then
      Value := 'Vertical';
    Orientation := AddContextItem(Items, 'Orientation', 0, True);
    AddContextItem(Orientation, 'Horizontal', cmHorizontal, True).Checked := SameText(Value, 'Horizontal');
    AddContextItem(Orientation, 'Vertical', cmVertical, True).Checked := SameText(Value, 'Vertical');
    for I := 0 to Orientation.Count - 1 do
    begin
      Orientation[I].RadioItem := True;
      Orientation[I].GroupIndex := 1;
    end;
  end;
  if ItemTagOf(Element.Tag) <> '' then
    AddContextItem(Items, 'Add ' + ItemTagOf(Element.Tag), cmAddItem, Applies(
      function: string
      begin
        Result := AddItem(AXaml, Element.Line, Element.Column);
      end));
  Props := FIndex.PropertiesOf(Element.Tag);
  for Prop in Props do
    if Prop.Kind = 'tabitems' then
    begin
      FContextProperty := Prop.Name;
      AddContextItem(Items, 'Edit Items...', cmEditItems, True);
    end;
  // Text or Content as an attribute only while the element has no content of its own
  HasChildren := False;
  for I := 0 to High(AElements) do
    if (AElements[I].ParentIndex = AIndex) and not AElements[I].Tag.Contains('.') then
      HasChildren := True;
  for Name in ['Text', 'Content', 'Header', 'Title'] do
    if (FContextProperty = '') and (not HasChildren or (Name = 'Header') or (Name = 'Title')) then
      for Prop in Props do
        if Prop.Name = Name then
        begin
          FContextProperty := Name;
          AddContextItem(Items, 'Edit ' + Name + '...', cmEditText, True);
          Break;
        end;
  if Items.Count = Count then
    while Items.Count > First do
      Items[Items.Count - 1].Free;
end;

procedure TPreviewCommand.ShowContextMenu(AX, AY: Integer; AHit: Boolean);
var
  Xaml: string;
  Elements: TArray<TXamlElement>;
  State: TEditState;
  I: Integer;
  Items: TMenuItem;
begin
  if not Designing or (Application.ModalLevel <> 0) then Exit;
  try
    if FInspector <> nil then FInspector.Commit;
    if FIndex = nil then
      FIndex := TDesignerTypeIndex.Create(TPath.Combine(RootFolder, 'src\Generated\RADWinUI.Xaml.json'));
    Xaml := SourceText(FXamlPath);
    try
      Elements := XamlElements(Xaml);
    except
      on EXamlEdit do Elements := nil; // unfinished XAML: only the commands that need no structure
    end;
    // Beside every element: the window itself
    if not AHit and (Length(Elements) > 0) then
      SelectStructureElement(Elements[0], False);
    I := SelectedIndex(Elements);
    State := DesignEditState;
    if FContextMenu = nil then
    begin
      FContextMenu := TPopupMenu.Create(nil);
      FContextMenu.AutoHotkeys := maManual;
    end;
    FContextMenu.Items.Clear;
    FContextProperty := '';
    Items := FContextMenu.Items;
    AddContextItem(Items, '&Undo', cmUndo, esCanUndo in State, ShortCut(Ord('Z'), [ssCtrl]));
    AddContextItem(Items, '&Redo', cmRedo, esCanRedo in State, ShortCut(Ord('Y'), [ssCtrl]));
    AddContextItem(Items, '-', 0, True);
    AddContextItem(Items, 'Cu&t', cmCut, (esCanCopy in State) and (esCanCut in State), ShortCut(Ord('X'), [ssCtrl]));
    AddContextItem(Items, '&Copy', cmCopy, esCanCopy in State, ShortCut(Ord('C'), [ssCtrl]));
    AddContextItem(Items, '&Paste', cmPaste, esCanPaste in State, ShortCut(Ord('V'), [ssCtrl]));
    AddContextItem(Items, '&Delete', cmDelete, esCanDelete in State, ShortCut(VK_DELETE, []));
    AddContextItem(Items, '-', 0, True);
    AddContextItem(Items, 'Select P&arent', cmSelectParent, (I >= 0) and (ParentElement(Elements, I) >= 0),
      ShortCut(VK_ESCAPE, []));
    AddContextItem(Items, 'Bring to &Front', cmFront, (I >= 0) and
      CanReorderElement(Xaml, Elements[I].Line, Elements[I].Column, True));
    AddContextItem(Items, 'Send to &Back', cmBack, (I >= 0) and
      CanReorderElement(Xaml, Elements[I].Line, Elements[I].Column, False));
    AddContextItem(Items, '-', 0, True);
    AddContextItem(Items, '&View Source', cmViewSource, True, ShortCut(VK_F12, []));
    AddContextItem(Items, '&Split View', cmSplit, True).Checked := SplitActive;
    if I >= 0 then AddControlItems(Xaml, Elements, I);
    FContextMenu.Popup(AX, AY);
  except
    on E: Exception do Log('designer menu: ' + E.ClassName + ': ' + E.Message);
  end;
end;

procedure TPreviewCommand.ContextClick(Sender: TObject);
var
  Xaml, Value: string;
begin
  if not Designing then Exit;
  try
    case (Sender as TMenuItem).Tag of
      cmUndo: UndoDesigner(False);
      cmRedo: UndoDesigner(True);
      cmCut: CutSelection;
      cmCopy: CopySelection;
      cmPaste: PasteSelection;
      cmDelete: DeleteSelection;
      cmSelectParent: SelectParent;
      cmFront: ReorderSelection(True);
      cmBack: ReorderSelection(False);
      cmViewSource: ViewSelectionSource;
      cmSplit: ToggleSplitView;
      cmEvent: EventHandler(FIndex.DefaultEventOf(FSelection.Tag), '');
      cmAddRow, cmAddColumn, cmAddItem: EditSelection((Sender as TMenuItem).Tag);
      cmHorizontal: PropertyChange('Orientation', 'Horizontal');
      cmVertical: PropertyChange('Orientation', 'Vertical');
      cmEditItems, cmEditText:
        begin
          Xaml := SourceText(FXamlPath);
          GetAttribute(Xaml, FSelection.Line, FSelection.Column, AttributeOf(FContextProperty), Value);
          if (Sender as TMenuItem).Tag = cmEditItems then
          begin
            if EditTabItems(Value) then PropertyChange(FContextProperty, Value);
          end
          else if AskText('RADWinUI', FContextProperty + ' of ' + Trim(FSelection.Tag + ' ' + FSelection.Name) + ':',
            Value) then
            PropertyChange(FContextProperty, Value);
        end;
    end;
  except
    on E: Exception do
      ThemedMessageDlg('RADWinUI: ' + E.Message, mtWarning, [mbOK]);
  end;
end;

procedure TPreviewCommand.DesignKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  Reply: string;
  Step, DX, DY: Integer;
begin
  if (Key = VK_F12) and (Shift = []) then
    ShowXamlCode
  else if ((Key = VK_APPS) and (Shift = [])) or ((Key = VK_F10) and (Shift = [ssShift])) then
    ShowContextMenu(FDesignSurface.ClientOrigin.X + 8, FDesignSurface.ClientOrigin.Y + 8, True)
  else if (Key = VK_ESCAPE) and (Shift = []) then
    SelectParent
  else if (Key in [VK_LEFT, VK_UP, VK_RIGHT, VK_DOWN]) and ((Shift = [ssCtrl]) or (Shift = [ssCtrl, ssShift])) then
  begin
    // The host knows where the element is: it sends the NUDGE
    Step := 1;
    if ssShift in Shift then Step := 8;
    DX := 0;
    DY := 0;
    case Key of
      VK_LEFT: DX := -Step;
      VK_RIGHT: DX := Step;
      VK_UP: DY := -Step;
      VK_DOWN: DY := Step;
    end;
    if FClient <> nil then FClient.Request(Format('NUDGEKEY %d %d', [DX, DY]), Reply);
  end
  else if (Key = Ord('X')) and (Shift = [ssCtrl]) then
    CutSelection
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
  else if not IsIdeShortcutKey(Key, Shift) or not IdeShortcut(ShortCut(Key, Shift * [ssCtrl, ssShift])) then
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
  I: Integer;
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
    if FIndex.IsVisual(Element.Tag) or MatchStr(Element.Tag, ['Window', 'Page', 'UserControl']) then Instances := Instances + [Element];
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
  // <Window TitleBar>: a list of the named elements of the window
  if Selection.Tag = 'Window' then
    for I := 0 to High(Props) do
      if Props[I].Name = 'TitleBar' then
      begin
        Props[I].Kind := 'enum:';
        for Element in Elements do
          if (Element.Name <> '') and not Element.DesignOnly and (Element.Tag <> 'Window') then
            Props[I].Kind := Props[I].Kind + Element.Name + '|';
        Props[I].Kind := Props[I].Kind.TrimRight(['|']);
        if Props[I].Kind = 'enum:' then
          Props[I].Kind := 'string';
      end;
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
    ThemedMessageDlg('RADWinUI Docked Preview could not create its IDE panel.', mtError, [mbOK]);
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
    // Design is back: the docked preview Split View opened goes, the renderer moved here
    if FSplitView then
    begin
      FSplitView := False;
      FPreviewFocused := False;
      if (FPreviewDockForm <> nil) and FPreviewDockForm.Visible then
        FPreviewDockForm.Close;
    end;
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
    if FSplitView and not FDesignViewActive then
      EndSplitStructure;
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
    // A multi-selection: the change goes to every selected element (a name stays one element's)
    if (Length(FMulti) > 1) and (AName <> 'Name') then
    begin
      ApplyText(FXamlPath, Xaml, SetAttributeOn(Xaml, MultiPositions, AttributeOf(AName), AValue));
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
      ThemedMessageDlg('RADWinUI: ' + E.Message, mtWarning, [mbOK]);
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
      ThemedMessageDlg('RADWinUI: ' + E.Message, mtWarning, [mbOK]);
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
      ThemedMessageDlg('RADWinUI: ' + E.Message, mtWarning, [mbOK]);
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
  FreeAndNil(VocabularyIndex);

end.
