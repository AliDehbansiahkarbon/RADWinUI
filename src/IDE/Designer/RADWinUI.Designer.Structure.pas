unit RADWinUI.Designer.Structure;

{ Native RAD Studio Structure view adapter. All nodes describe XAML source,
  no WinUI objects enter the IDE process. Parsing lives in Designer.XamlEdit. }

interface

uses
  Winapi.Windows, Winapi.ActiveX, System.SysUtils, System.Classes,
  ToolsAPI, DesignIntf, StructureViewAPI,
  RADWinUI.Designer.XamlEdit, RADWinUI.Designer.Model, RADWinUI.Designer.Retention;

const
  RADWinUIStructureType = 'RADWinUI.Xaml.Structure';

type
  TStructureDispatch = class(TInterfacedObject, IDispatch)
  public
    function SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult; override;
  protected
    function GetTypeInfoCount(out Count: Integer): HResult; stdcall;
    function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; stdcall;
    function GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount, LocaleID: Integer;
      DispIDs: Pointer): HResult; stdcall;
    function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word;
      var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;
  end;

  TXamlStructureNode = class(TStructureDispatch, IOTAStructureNode, IOTASortableStructureNode)
  private
    FElement: TXamlElement;
    FParent: TXamlStructureNode; // weak, the context detaches nodes before releasing them
    FChildren: TInterfaceList;
    FExpanded, FFocused, FSelected: WordBool;
    FData: IntPtr;
    FImage: Integer;
  public
    constructor Create(const AElement: TXamlElement; AParent: TXamlStructureNode);
    destructor Destroy; override;
    function AddChildNode(const ANode: IOTAStructureNode; Index: Integer = -1): Integer; safecall;
    function Get_Caption: WideString; safecall;
    function Get_ChildCount: Integer; safecall;
    function Get_Child(Index: Integer): IOTAStructureNode; safecall;
    function Get_Expanded: WordBool; safecall;
    procedure Set_Expanded(Value: WordBool); safecall;
    function Get_Focused: WordBool; safecall;
    procedure Set_Focused(Value: WordBool); safecall;
    function Get_Hint: WideString; safecall;
    function Get_ImageIndex: Integer; safecall;
    function Get_Name: WideString; safecall;
    function Get_Parent: IOTAStructureNode; safecall;
    function Get_Selected: WordBool; safecall;
    procedure Set_Selected(Value: WordBool); safecall;
    function Get_StateIndex: Integer; safecall;
    function Get_Data: IntPtr; safecall;
    procedure Set_Data(Value: IntPtr); safecall;
    procedure RemoveChildNode(Index: Integer); safecall;
    function Get_SortByIndex: WordBool; safecall;
    function Get_ItemIndex: Integer; safecall;
  end;

  TDesignerStructure = class(TStructureDispatch, IOTAStructureContext,
    IOTAStructureContextEditActions, IOTAStructureContextKeyHandler)
  private
    FPath, FText: string;
    FRoots: TInterfaceList;
    FNodes: TRetainedNodes;
    FObjects: TArray<TXamlStructureNode>;
    FUpdating: Boolean;
    FPendingNode: IOTAStructureNode;
    FPendingDefault: Boolean;
    FRootsFetched: Boolean;
    FOnSelect: TProc<TXamlElement, Boolean>;
    FOnEdit: TFunc<TEditAction, Boolean>;
    FOnState: TFunc<TEditState>;
    procedure ClearNodes;
    procedure ActivateNode(const Node: IOTAStructureNode; ADefault: Boolean);
  public
    constructor Create(const APath: string; const ASelect: TProc<TXamlElement, Boolean>;
      const AEdit: TFunc<TEditAction, Boolean>; const AState: TFunc<TEditState>);
    destructor Destroy; override;
    /// <summary>
    ///   Rebuilds the nodes from AText. ARegisterImages adds missing control
    ///   icons to the Structure view, never pass it from inside an IDE callback.
    /// </summary>
    function Update(const AText: string; AIndex: TDesignerTypeIndex; ARegisterImages: Boolean = True): Boolean;
    /// <summary>Adds the icons nodes built inside an IDE callback could not get yet.</summary>
    procedure RegisterImages;
    /// <summary>
    ///   For the IDE's GetStructureContext callback: builds the nodes unless the
    ///   Structure view shows this context. The IDE calls back while it
    ///   initializes the shown nodes, rebuilding them there freed the node it
    ///   was reading. A shown context is refreshed by Update from a timer.
    /// </summary>
    procedure Provide(const AText: string; AIndex: TDesignerTypeIndex);
    /// <summary>True when the IDE's Structure view shows this context.</summary>
    function Shown: Boolean;
    procedure DispatchSelection;
    procedure Select(ALine, AColumn: Integer);
    /// <summary>
    ///   Stops callbacks. AResetView also clears the Structure view when it shows
    ///   this context, never pass it from inside an IDE callback.
    /// </summary>
    procedure Detach(AResetView: Boolean = True);
    function Get_ContextIdent: WideString; safecall;
    function Get_StructureType: WideString; safecall;
    function Get_ViewOptions: Integer; safecall;
    function Get_RootNodeCount: Integer; safecall;
    function GetRootStructureNode(Index: Integer): IOTAStructureNode; safecall;
    procedure NodeEdited(const Node: IOTAStructureNode); safecall;
    procedure NodeFocused(const Node: IOTAStructureNode); safecall;
    procedure NodeSelected(const Node: IOTAStructureNode); safecall;
    procedure DefaultNodeAction(const Node: IOTAStructureNode); safecall;
    function SameContext(const AContext: IOTAStructureContext): WordBool; safecall;
    procedure InitPopupMenu(const Node: IOTAStructureNode; const PopupMenu: IOTAStructureNodeMenuItem); safecall;
    procedure AddRootNode(const ANode: IOTAStructureNode; Index: Integer); safecall;
    procedure RemoveRootNode(const ANode: IOTAStructureNode); safecall;
    function EditAction(Action: Integer): WordBool; safecall;
    function GetEditState: Integer; safecall;
    procedure KeyDown(const Node: IOTAStructureNode; KeyState: Integer; var KeyCode: Word); safecall;
    procedure KeyPressed(const Node: IOTAStructureNode; KeyState: Integer; var KeyChar: Word); safecall;
    property Path: string read FPath;
  end;

implementation

uses System.Win.ComObj, System.Generics.Collections, Vcl.Graphics, RADWinUI.Designer.PaletteIcons;

var
  StructureImages: TDictionary<string, Integer>;

/// The Structure view image of ATag: the Tool Palette icon, added once per
/// control type at 16, 24 and 32 px so the view picks the size for its DPI.
/// Without ARegister only icons added before are returned: adding one changes the
/// view's image list, which must not happen while the IDE initializes a node.
function StructureImageIndex(const ATag: string; ARegister: Boolean): Integer;
var
  View: IOTAStructureView280;
  Name: string;
  Images: TGraphicArray;
  I: Integer;
begin
  Name := ATag.Substring(ATag.IndexOf(':') + 1); // local:MyControl -> MyControl
  if StructureImages = nil then
    StructureImages := TDictionary<string, Integer>.Create;
  if StructureImages.TryGetValue(Name, Result) then
    Exit;
  Result := -1;
  if not ARegister or not Supports(BorlandIDEServices, IOTAStructureView280, View) then
    Exit;
  SetLength(Images, 3);
  try
    for I := 0 to High(Images) do
    begin
      Images[I] := TBitmap.Create;
      Images[I].Assign(PaletteBitmap(Name, 16 + I * 8));
    end;
    // The view copies the images, as Embarcadero's TreeIntf sprigs rely on
    Result := View.AddImage('RADWinUI.Structure' + Name, Images);
  finally
    for I := 0 to High(Images) do
      Images[I].Free;
  end;
  StructureImages.Add(Name, Result);
end;

function TStructureDispatch.SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult;
begin
  Result := HandleSafeCallException(ExceptObject, ExceptAddr, IDispatch, 'RADWinUI.Structure', '');
end;

function TStructureDispatch.GetTypeInfoCount(out Count: Integer): HResult;
begin
  Count := 0;
  Result := S_OK;
end;

function TStructureDispatch.GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult;
begin
  Pointer(TypeInfo) := nil;
  Result := E_NOTIMPL;
end;

function TStructureDispatch.GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount, LocaleID: Integer;
  DispIDs: Pointer): HResult;
begin
  Result := E_NOTIMPL;
end;

function TStructureDispatch.Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word;
  var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult;
begin
  Result := E_NOTIMPL;
end;

constructor TXamlStructureNode.Create(const AElement: TXamlElement; AParent: TXamlStructureNode);
begin
  inherited Create;
  FElement := AElement;
  FParent := AParent;
  FChildren := TInterfaceList.Create;
  FExpanded := True;
  FImage := -1;
end;

destructor TXamlStructureNode.Destroy;
begin
  FChildren.Free;
  inherited;
end;

function TXamlStructureNode.AddChildNode(const ANode: IOTAStructureNode; Index: Integer): Integer;
begin
  Result := Index;
  if (Index < 0) or (Index >= FChildren.Count) then
    Result := FChildren.Add(ANode)
  else
    FChildren.Insert(Index, ANode);
end;

function TXamlStructureNode.Get_Caption: WideString;
begin
  Result := FElement.Tag;
  if FElement.Name <> '' then Result := FElement.Name + ': ' + FElement.Tag;
end;
function TXamlStructureNode.Get_ChildCount: Integer;
begin Result := FChildren.Count; end;
function TXamlStructureNode.Get_Child(Index: Integer): IOTAStructureNode;
begin Result := FChildren[Index] as IOTAStructureNode; end;
function TXamlStructureNode.Get_Expanded: WordBool;
begin Result := FExpanded; end;
procedure TXamlStructureNode.Set_Expanded(Value: WordBool);
begin FExpanded := Value; end;
function TXamlStructureNode.Get_Focused: WordBool;
begin Result := FFocused; end;
procedure TXamlStructureNode.Set_Focused(Value: WordBool);
begin FFocused := Value; end;
function TXamlStructureNode.Get_Hint: WideString;
begin Result := Format('%s (line %d, column %d)', [FElement.Tag, FElement.Line, FElement.Column]); end;
function TXamlStructureNode.Get_ImageIndex: Integer;
begin Result := FImage; end;
function TXamlStructureNode.Get_Name: WideString;
begin
  Result := FElement.Name;
  if Result = '' then Result := Format('%s@%d:%d', [FElement.Tag, FElement.Line, FElement.Column]);
end;
function TXamlStructureNode.Get_Parent: IOTAStructureNode;
begin
  Result := nil;
  if FParent <> nil then Result := FParent as IOTAStructureNode;
end;
function TXamlStructureNode.Get_Selected: WordBool;
begin Result := FSelected; end;
procedure TXamlStructureNode.Set_Selected(Value: WordBool);
begin FSelected := Value; end;
function TXamlStructureNode.Get_StateIndex: Integer;
begin Result := -1; end;
function TXamlStructureNode.Get_Data: IntPtr;
begin Result := FData; end;
procedure TXamlStructureNode.Set_Data(Value: IntPtr);
begin FData := Value; end;
procedure TXamlStructureNode.RemoveChildNode(Index: Integer);
begin FChildren.Delete(Index); end;
function TXamlStructureNode.Get_SortByIndex: WordBool;
begin Result := True; end;
function TXamlStructureNode.Get_ItemIndex: Integer;
begin Result := FElement.Start; end;

constructor TDesignerStructure.Create(const APath: string; const ASelect: TProc<TXamlElement, Boolean>;
  const AEdit: TFunc<TEditAction, Boolean>; const AState: TFunc<TEditState>);
begin
  inherited Create;
  FPath := APath;
  FText := #0;
  FRoots := TInterfaceList.Create;
  FNodes := TRetainedNodes.Create;
  FOnSelect := ASelect;
  FOnEdit := AEdit;
  FOnState := AState;
end;

procedure TDesignerStructure.ClearNodes;
var
  Node: TXamlStructureNode;
begin
  for Node in FObjects do
    if Node <> nil then
    begin
      Node.FParent := nil;
      // The IDE can retain an old node while rebuilding its virtual tree.
      // Keep its children alive and its ChildCount/Child contract intact.
    end;
  FRoots.Clear;
  // The IDE's tree keeps raw pointers to the shown nodes until its deferred
  // rebuild has fetched the new roots, Update frees them after that (Trim)
  FNodes.Renew;
  FObjects := nil;
end;

destructor TDesignerStructure.Destroy;
begin
  ClearNodes;
  FRoots.Free;
  FNodes.Free; // the IDE no longer holds this context, nothing reads the nodes
  inherited;
end;

procedure TDesignerStructure.Detach(AResetView: Boolean);
begin
  FOnSelect := nil;
  FOnEdit := nil;
  FOnState := nil;
  FPendingNode := nil;
  if AResetView and Shown then
    (BorlandIDEServices as IOTAStructureView).SetStructureContext(nil);
end;

function TDesignerStructure.Shown: Boolean;
var
  View: IOTAStructureView;
  Shows: IOTAStructureContext;
begin
  // By identity, not by pointer: the view may hand back another interface pointer for this context
  Result := Supports(BorlandIDEServices, IOTAStructureView, View);
  if Result then
  begin
    Shows := View.GetStructureContext;
    Result := (Shows <> nil) and ((Shows = (Self as IOTAStructureContext)) or SameContext(Shows));
  end;
end;

procedure TDesignerStructure.Provide(const AText: string; AIndex: TDesignerTypeIndex);
begin
  if not Shown then
    Update(AText, AIndex, False);
end;

procedure TDesignerStructure.RegisterImages;
var
  Node: TXamlStructureNode;
  Added: Boolean;
  View: IOTAStructureView;
begin
  if FUpdating then Exit;
  Added := False;
  for Node in FObjects do
    if Node.FImage < 0 then
    begin
      Node.FImage := StructureImageIndex(Node.FElement.Tag, True);
      Added := Added or (Node.FImage >= 0);
    end;
  if Added and Shown and Supports(BorlandIDEServices, IOTAStructureView, View) then
    View.StructureChanged(True);
end;

function TDesignerStructure.Update(const AText: string; AIndex: TDesignerTypeIndex; ARegisterImages: Boolean): Boolean;
var
  Elements: TArray<TXamlElement>;
  Map: TArray<TXamlStructureNode>;
  Hidden: TArray<Boolean>;
  I, ParentIndex, NodeCount: Integer;
  Node, Parent: TXamlStructureNode;
  View: IOTAStructureView;
begin
  Result := False;
  if FUpdating or (AText = FText) then Exit;
  try
    Elements := XamlElements(AText);
  except
    on EXamlEdit do Exit; // keep the previous hierarchy while the user types
  end;
  SetLength(Map, Length(Elements));
  SetLength(Hidden, Length(Elements));
  if not Shown or not Supports(BorlandIDEServices, IOTAStructureView, View) then
    View := nil;
  FUpdating := True;
  try
    if View <> nil then View.BeginUpdate;
    try
      FPendingNode := nil;
      // Older nodes go once the IDE has fetched the newest roots, or when it does not show this context
      if (View = nil) or FRootsFetched then
        FNodes.Trim;
      ClearNodes;
      SetLength(FObjects, Length(Elements));
      NodeCount := 0;
      for I := 0 to High(Elements) do
      begin
        ParentIndex := Elements[I].ParentIndex;
        Hidden[I] := Elements[I].DesignOnly or Elements[I].Tag.EndsWith('Template') or Elements[I].Tag.EndsWith('.Resources') or
          (Elements[I].Tag = 'Style') or ((ParentIndex >= 0) and Hidden[ParentIndex]);
        if Hidden[I] or not AIndex.IsVisual(Elements[I].Tag) then Continue;
        Parent := nil;
        while ParentIndex >= 0 do
        begin
          Parent := Map[ParentIndex];
          if Parent <> nil then Break;
          ParentIndex := Elements[ParentIndex].ParentIndex;
        end;
        Node := TXamlStructureNode.Create(Elements[I], Parent);
        Node.FImage := StructureImageIndex(Elements[I].Tag, ARegisterImages);
        FNodes.Add(Node as IOTAStructureNode);
        FObjects[NodeCount] := Node;
        Inc(NodeCount);
        Map[I] := Node;
        if Parent = nil then FRoots.Add(Node as IOTAStructureNode)
        else Parent.AddChildNode(Node as IOTAStructureNode);
      end;
      SetLength(FObjects, NodeCount);
      FRootsFetched := False;
      if View <> nil then View.StructureChanged(True);
    finally
      if View <> nil then View.EndUpdate;
    end;
    FText := AText; // retry after a failed native refresh, even if the text is unchanged
    Result := True;
  finally
    FUpdating := False;
  end;
end;

procedure TDesignerStructure.Select(ALine, AColumn: Integer);
var
  Node: TXamlStructureNode;
  View: IOTAStructureView;
begin
  if FUpdating or not Shown or not Supports(BorlandIDEServices, IOTAStructureView, View) then Exit;
  FUpdating := True;
  try
    View.ClearSelection;
    for Node in FObjects do
      if (Node.FElement.Line = ALine) and (Node.FElement.Column = AColumn) then
      begin
        View.SelectNode(Node as IOTAStructureNode);
        View.FocusNode(Node as IOTAStructureNode);
        Break;
      end;
  finally
    FUpdating := False;
  end;
end;

procedure TDesignerStructure.ActivateNode(const Node: IOTAStructureNode; ADefault: Boolean);
var
  Item: TXamlStructureNode;
begin
  if FUpdating or not Assigned(FOnSelect) then Exit;
  for Item in FObjects do
    if (Item as IOTAStructureNode) = Node then
    begin
      // Focus/selection callbacks run inside the IDE's tree rebuild/activation.
      // Docking Properties or navigating to code here can reenter that rebuild.
      if FPendingNode <> Node then FPendingDefault := False;
      FPendingNode := Node;
      FPendingDefault := FPendingDefault or ADefault;
      Break;
    end;
end;

procedure TDesignerStructure.DispatchSelection;
var
  Pending: IOTAStructureNode;
  Item: TXamlStructureNode;
  Default: Boolean;
begin
  if FUpdating or (FPendingNode = nil) or not Assigned(FOnSelect) then Exit;
  Pending := FPendingNode;
  Default := FPendingDefault;
  FPendingNode := nil;
  FPendingDefault := False;
  for Item in FObjects do
    if (Item as IOTAStructureNode) = Pending then
    begin
      FUpdating := True;
      try
        FOnSelect(Item.FElement, Default);
      finally
        FUpdating := False;
      end;
      Break;
    end;
end;

function TDesignerStructure.Get_ContextIdent: WideString;
begin Result := FPath; end;
function TDesignerStructure.Get_StructureType: WideString;
begin Result := RADWinUIStructureType; end;
function TDesignerStructure.Get_ViewOptions: Integer;
begin Result := 0; end;
function TDesignerStructure.Get_RootNodeCount: Integer;
begin Result := FRoots.Count; end;
function TDesignerStructure.GetRootStructureNode(Index: Integer): IOTAStructureNode;
begin
  FRootsFetched := True; // the IDE rebuilds its tree from these roots
  Result := FRoots[Index] as IOTAStructureNode;
end;
procedure TDesignerStructure.NodeEdited(const Node: IOTAStructureNode);
begin end;
procedure TDesignerStructure.NodeFocused(const Node: IOTAStructureNode);
begin ActivateNode(Node, False); end;
procedure TDesignerStructure.NodeSelected(const Node: IOTAStructureNode);
begin ActivateNode(Node, False); end;
procedure TDesignerStructure.DefaultNodeAction(const Node: IOTAStructureNode);
begin ActivateNode(Node, True); end;
function TDesignerStructure.SameContext(const AContext: IOTAStructureContext): WordBool;
begin
  Result := (AContext <> nil) and (AContext.StructureType = RADWinUIStructureType) and
    SameText(AContext.ContextIdent, FPath);
end;
procedure TDesignerStructure.InitPopupMenu(const Node: IOTAStructureNode;
  const PopupMenu: IOTAStructureNodeMenuItem);
begin end;
procedure TDesignerStructure.AddRootNode(const ANode: IOTAStructureNode; Index: Integer);
begin
  if (Index < 0) or (Index >= FRoots.Count) then FRoots.Add(ANode)
  else FRoots.Insert(Index, ANode);
end;
procedure TDesignerStructure.RemoveRootNode(const ANode: IOTAStructureNode);
begin FRoots.Remove(ANode); end;
function TDesignerStructure.EditAction(Action: Integer): WordBool;
begin
  Result := Assigned(FOnEdit) and (Action >= Ord(Low(TEditAction))) and
    (Action <= Ord(High(TEditAction))) and FOnEdit(TEditAction(Action));
end;
function TDesignerStructure.GetEditState: Integer;
var
  State: TEditState;
  Flag: TEditStates;
begin
  Result := 0;
  if not Assigned(FOnState) then Exit;
  State := FOnState();
  for Flag := Low(TEditStates) to High(TEditStates) do
    if Flag in State then Result := Result or (1 shl Ord(Flag));
end;
procedure TDesignerStructure.KeyDown(const Node: IOTAStructureNode; KeyState: Integer; var KeyCode: Word);
begin
  if (KeyCode = VK_DELETE) and (GetKeyState(VK_CONTROL) >= 0) then EditAction(Ord(eaDelete))
  else if (KeyCode = Ord('Z')) and (GetKeyState(VK_CONTROL) < 0) then
  begin
    if GetKeyState(VK_SHIFT) < 0 then EditAction(Ord(eaRedo)) else EditAction(Ord(eaUndo));
  end
  else if (KeyCode = Ord('Y')) and (GetKeyState(VK_CONTROL) < 0) then EditAction(Ord(eaRedo))
  else Exit;
  KeyCode := 0;
end;
procedure TDesignerStructure.KeyPressed(const Node: IOTAStructureNode; KeyState: Integer; var KeyChar: Word);
begin end;

initialization

finalization
  StructureImages.Free;

end.
