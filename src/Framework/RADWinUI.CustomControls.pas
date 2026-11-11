unit RADWinUI.CustomControls;

{
  Controls written in Delphi that XAML uses like its own elements.

    <Window ... xmlns:rw="using:RADWinUI.Controls">
      <rw:GlowTile x:Name="BuildTile" GlowBrush="Orange" Glowing="True" />

  A custom control derives from TWinUICustomControl (a ContentControl),
  describes its XAML properties and events in DefineType and is registered
  once with TWinUICustomControls.Register. Its properties are dependency
  properties, so bindings, styles and animations work on them. A component
  without a look (a hotkey, a media session) is a custom control too, it just
  stays collapsed.

  Behind each element is a COM aggregate, as C# and C++/WinRT build one for
  "class GlowTile : ContentControl": the outer object (TWinUIControlHost)
  creates the WinUI ContentControl as its inner object and owns the Pascal
  control. TWinUIApplication asks this unit first for XAML type names, so
  XamlReader creates and fills the elements like built-in ones.
}

interface

{$SCOPEDENUMS ON}

uses
  System.SysUtils,
  System.TypInfo,
  RADWinUI.Interop.Core,
  RADWinUI.Abi,
  RADWinUI.Framework,
  RADWinUI.Xaml;

const
  /// <summary>The XAML namespace of every registered control: xmlns:rw="using:RADWinUI.Controls".</summary>
  CustomControlsNamespace = 'RADWinUI.Controls';

type
  /// <summary>The type of a custom control property, as XAML and the Object Inspector see it.</summary>
  TWinUIPropertyKind = (Boolean, Int32, Double, Text, Brush, Value, Enum);

  TWinUICustomProperty = record
    Name: string;
    Kind: TWinUIPropertyKind;
    EnumType: PTypeInfo;
    /// <summary>The default as XAML text: 'True', '0.5', 'Working'. '' for no default.</summary>
    DefaultText: string;
    /// <summary>
    ///   How the Object Inspector edits it, '' for the usual way. The type index
    ///   writes it in place of the kind: 'tabitems' opens the tab editor.
    /// </summary>
    Editor: string;
    Prop: IDependencyProperty;
  end;

  {$M+} // descendants publish their XAML properties and events
  TWinUICustomControl = class;
  TWinUICustomControlClass = class of TWinUICustomControl;

  /// <summary>One registered control: its XAML name, properties and events.</summary>
  TWinUICustomType = class
  strict private
    FXamlName: string;
    FControlClass: TWinUICustomControlClass;
    FProperties: TArray<TWinUICustomProperty>;
    FEvents: TArray<string>;
    FCategory: string;
    FXamlType: IXamlType;
    FRegistered: Boolean;
    function GetFullName: string;
    function GetProperty(AIndex: Integer): TWinUICustomProperty;
  public
    constructor Create(AClass: TWinUICustomControlClass; const AXamlName, ACategory: string);
    /// <summary>Adds a property. Call from DefineType, in the order of the property indexes.</summary>
    procedure AddProperty(const AName: string; AKind: TWinUIPropertyKind; const ADefault: string = '';
      AEnumType: PTypeInfo = nil);
    /// <summary>Adds an event, raised as OnName / Name.Add like WinUI's own events.</summary>
    procedure AddEvent(const AName: string);
    /// <summary>Gives the property AName a special editor in the Object Inspector, like 'tabitems'.</summary>
    procedure SetEditor(const AName, AEditor: string);
    /// <summary>The index of the property AName, -1 when there is none.</summary>
    function IndexOf(const AName: string): Integer;
    /// <summary>The index of the property whose dependency property is AProp, -1 when there is none.</summary>
    function IndexOfProp(const AProp: IDependencyProperty): Integer;
    /// <summary>Registers the dependency properties with WinUI, once, on first use.</summary>
    procedure EnsureRegistered;
    /// <summary>The XAML type that XamlReader uses.</summary>
    function XamlType: IXamlType;
    function PropertyCount: Integer;
    property XamlName: string read FXamlName;
    property FullName: string read GetFullName;
    property Category: string read FCategory;
    property ControlClass: TWinUICustomControlClass read FControlClass;
    property Properties[AIndex: Integer]: TWinUICustomProperty read GetProperty;
    property Events: TArray<string> read FEvents;
  end;

  /// <summary>
  ///   Base of every custom control. Descendants override DefineType, and
  ///   publish one property per AddProperty (index = order) over the typed
  ///   accessors below, and one OnName event per AddEvent.
  /// </summary>
  /// <summary>What a custom control offers UI Automation (screen readers), see AutomationPatterns.</summary>
  TWinUIAutomationPattern = (Invoke, Toggle, ExpandCollapse, Selection);
  TWinUIAutomationPatterns = set of TWinUIAutomationPattern;

  TWinUICustomControl = class(TWinUIContentControl)
  strict private
    FHost: TObject;
    FHostRef: IInspectable;
    FEvents: TArray<TWinUIEvent<TWinValue>>;
    FHandlers: TArray<TWinUIWinValueEventHandler>;
    FInitialized: Boolean;
    procedure Attach(AHost: TObject);
  private
    procedure HostPropertyChanged(AIndex: Integer);
  protected
    /// <summary>Describes the XAML properties and events. Call inherited first.</summary>
    class procedure DefineType(AType: TWinUICustomType); virtual;
    /// <summary>Called once after creation, before XAML sets any property.</summary>
    procedure Initialize; virtual;
    /// <summary>Called after the property with index AIndex changed, from XAML, a binding or Pascal.</summary>
    procedure PropertyChanged(AIndex: Integer); virtual;
    function CustomType: TWinUICustomType;
    function GetPropValue(AIndex: Integer): IInspectable;
    procedure SetPropValue(AIndex: Integer; const AValue: IInspectable);
    function GetBoolean(AIndex: Integer): Boolean;
    procedure SetBoolean(AIndex: Integer; AValue: Boolean);
    function GetInt32(AIndex: Integer): Integer;
    procedure SetInt32(AIndex: Integer; AValue: Integer);
    function GetDouble(AIndex: Integer): Double;
    procedure SetDouble(AIndex: Integer; AValue: Double);
    function GetText(AIndex: Integer): string;
    procedure SetText(AIndex: Integer; const AValue: string);
    function GetBrush(AIndex: Integer): TWinUIBrush;
    procedure SetBrush(AIndex: Integer; AValue: TWinUIBrush);
    /// <summary>The listeners of the event with index AIndex (AddEvent order).</summary>
    function GetEvent(AIndex: Integer): TWinUIEvent<TWinValue>;
    function GetHandler(AIndex: Integer): TWinUIWinValueEventHandler;
    procedure SetHandler(AIndex: Integer; const AValue: TWinUIWinValueEventHandler);
    /// <summary>Raises the event with index AIndex: its OnName handler, then its listeners.</summary>
    procedure Fire(AIndex: Integer);
    /// <summary>Sets the look from a ControlTemplate in XAML, loaded once per class.</summary>
    procedure UseTemplate(const AXaml: string);
    /// <summary>A named element of the template (x:Name), nil before the template is applied.</summary>
    function TemplatePart(const AName: string): IDependencyObject;
    { Accessibility: what screen readers and UI Automation see. A control with a role
      other than Custom, or with patterns, gets an automation peer of its own. }
    /// <summary>The role: Button, Tab, Group... Custom (the default) gives the control no peer of its own.</summary>
    function AutomationRole: AutomationControlType; virtual;
    function AutomationPatterns: TWinUIAutomationPatterns; virtual;
    /// <summary>The name when AutomationProperties.Name is not set, such as the control's text.</summary>
    function AutomationName: string; virtual;
    /// <summary>Invoke: what a click does.</summary>
    procedure AutomationInvoke; virtual;
    /// <summary>Toggle: the state and the toggle.</summary>
    function AutomationToggleState: ToggleState; virtual;
    procedure AutomationToggle; virtual;
    /// <summary>ExpandCollapse: whether the control is expanded, and expanding or collapsing it.</summary>
    function AutomationExpanded: Boolean; virtual;
    procedure AutomationExpand(AExpand: Boolean); virtual;
    /// <summary>Selection: the items (tabs), their names, where they are and the selected one.</summary>
    function AutomationItemCount: Integer; virtual;
    function AutomationItemName(AIndex: Integer): string; virtual;
    /// <summary>The item's horizontal place in the control, in DIPs. False: the whole control.</summary>
    function AutomationItemSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean; virtual;
    function AutomationSelectedIndex: Integer; virtual;
    procedure AutomationSelect(AIndex: Integer); virtual;
    /// <summary>Tells screen readers the state of APattern changed: call it after a toggle, an expand or a selection.</summary>
    procedure AutomationChanged(APattern: TWinUIAutomationPattern);
    /// <summary>Tells screen readers the name changed.</summary>
    procedure AutomationNameChanged;
  public
    /// <summary>Creates the control from Pascal. XAML creates it through its registered type.</summary>
    constructor Create(AOwner: TWinUIObject);
    /// <summary>Used by the XAML type: wraps a host's inner object.</summary>
    constructor CreateHosted(AHost: TObject);
    destructor Destroy; override;
    /// <summary>The listeners of the event AName (XAML wiring of the short handler form).</summary>
    function EventByName(const AName: string): TWinUIEvent<TWinValue>;
    /// <summary>
    ///   The window whose XAML created the control, or the last owner of one
    ///   created in Pascal. nil when there is none.
    /// </summary>
    function OwnerWindow: TObject;
  end;

  /// <summary>
  ///   Base of a user control made of a .xaml file and its .pas unit, like a
  ///   window. XamlCodeGen generates the class between it and the user's class,
  ///   which loads the content, fills the x:Name fields and registers the control,
  ///   so other XAML uses it as &lt;local:ContactCard/&gt; with any using: namespace.
  /// </summary>
  TWinUIXamlUserControl = class(TWinUICustomControl)
  protected
    procedure Initialize; override;
    /// <summary>Loads AXaml as the content. The generated Initialize calls it.</summary>
    procedure LoadContentXaml(const AXaml: string);
    /// <summary>The published method AName, for event wiring by XamlCodeGen.</summary>
    function PublishedMethod(const AName: string): TMethod;
    /// <summary>A listener that calls the (Sender: TObject) published method AName.</summary>
    function NotifyProc<T>(const AName: string): TWinUIEventProc<T>;
  public
    /// <summary>The element named AName (x:Name) in the content, wrapped, nil when missing.</summary>
    function FindElement<T: TWinUIObject>(const AName: string): T;
  end;
  {$M-}

  TWinUICustomControls = class
  public
    /// <summary>
    ///   Makes AClass available in XAML as &lt;rw:AXamlName&gt; and on the Tool
    ///   Palette in ACategory. Call from the initialization of the control's unit.
    /// </summary>
    class procedure Register(AClass: TWinUICustomControlClass; const AXamlName, ACategory: string); static;
    /// <summary>The registered type with this full name (RADWinUI.Controls.GlowTile), or nil.</summary>
    class function Find(const AFullName: string): TWinUICustomType; static;
    /// <summary>The registered type of AClass, or nil.</summary>
    class function FindClass(AClass: TClass): TWinUICustomType; static;
    class function Types: TArray<TWinUICustomType>; static;
    /// <summary>Pascal objects of registered controls that exist right now, for leak checks in tests.</summary>
    class function LiveCount: Integer; static;
    /// <summary>Their XAML elements (hosts) that exist right now, XAML may keep one after its control is gone.</summary>
    class function HostCount: Integer; static;
    /// <summary>
    ///   The type index of the registered controls in the RADWinUI.Xaml.json format, for
    ///   XamlCodeGen and the designer (src\Framework\RADWinUI.Controls.json).
    /// </summary>
    class function TypeIndexJson: string; static;
  end;

/// <summary>
///   True while Windows shows a contrast theme (Settings > Accessibility >
///   Contrast themes): RADWinUI's own controls then paint with its colours.
/// </summary>
function HighContrastOn: Boolean;
/// <summary>A colour of the contrast theme: COLOR_WINDOW, COLOR_WINDOWTEXT, COLOR_HIGHLIGHT, COLOR_BTNFACE...</summary>
function SystemColor(AIndex: Integer): Color;

implementation

{$WARN SYMBOL_PLATFORM OFF} // RegisterExpectedMemoryLeak, RADWinUI is Windows only

uses
  Winapi.Windows,
  Winapi.ActiveX,
  RADWinUI.Runtime.Application;

type
  /// <summary>
  ///   The outer object of a custom control's COM aggregate. XAML holds it. It
  ///   answers IWinUIPascalObject itself and forwards every other interface
  ///   to the inner ContentControl.
  /// </summary>
  TWinUIControlHost = class(TInterfacedObject, IInterface, IInspectable, IWinUIPascalObject, IUIElementOverrides)
  private
    FInner: IInspectable;
    // The automation peer XAML asked for, not counted (the element keeps it)
    FPeer: TObject;
    FType: TWinUICustomType;
    FControl: TWinUICustomControl;
    FOwnsControl: Boolean;
    // The window whose LoadContent created it, nil when it came from elsewhere
    FOwnerWindow: TObject;
    procedure ReleaseControl;
  protected
    function QueryInterface(const IID: TGUID; out Obj): HRESULT; stdcall;
    procedure GetIids(out AIidCount: Cardinal; out AIids: PGUID); safecall;
    function GetRuntimeClassName: HSTRING; safecall;
    function GetTrustLevel: TrustLevel; safecall;
    function PascalObject: TWinUIObject;
    { IUIElementOverrides: the base's, apart from the automation peer }
    function OnCreateAutomationPeer: IAutomationPeer; safecall;
    procedure OnDisconnectVisualChildren; safecall;
    function FindSubElementsForTouchTargeting(APoint: RADWinUI.Abi.Point;
      ABoundingRect: RADWinUI.Abi.Rect): IIterable_IIterable_Point; safecall;
    function GetChildrenInTabFocusOrder: IIterable_DependencyObject; safecall;
    procedure OnKeyboardAcceleratorInvoked(AArgs: IKeyboardAcceleratorInvokedEventArgs); safecall;
    procedure OnProcessKeyboardAccelerators(AArgs: IProcessKeyboardAcceleratorEventArgs); safecall;
    procedure OnBringIntoViewRequested(AE: IBringIntoViewRequestedEventArgs); safecall;
    procedure PopulatePropertyInfoOverride(APropertyName: HSTRING; AAnimationPropertyInfo: IAnimationPropertyInfo); safecall;
  public
    constructor Create(AType: TWinUICustomType);
    destructor Destroy; override;
  end;

  /// <summary>IInspectable for the XAML type info objects below.</summary>
  TXamlInfoObject = class(TInterfacedObject, IInspectable)
  protected
    procedure GetIids(out AIidCount: Cardinal; out AIids: PGUID); safecall;
    function GetRuntimeClassName: HSTRING; safecall;
    function GetTrustLevel: TrustLevel; safecall;
  end;

  TCustomXamlType = class(TXamlInfoObject, IXamlType)
  strict private
    FType: TWinUICustomType;
    FMembers: TArray<IXamlMember>;
    function Base: IXamlType;
  protected
    function get_BaseType: IXamlType; safecall;
    function get_ContentProperty: IXamlMember; safecall;
    function get_FullName: HSTRING; safecall;
    function get_IsArray: Boolean; safecall;
    function get_IsCollection: Boolean; safecall;
    function get_IsConstructible: Boolean; safecall;
    function get_IsDictionary: Boolean; safecall;
    function get_IsMarkupExtension: Boolean; safecall;
    function get_IsBindable: Boolean; safecall;
    function get_ItemType: IXamlType; safecall;
    function get_KeyType: IXamlType; safecall;
    function get_BoxedType: IXamlType; safecall;
    function get_UnderlyingType: TypeName; safecall;
    function ActivateInstance: IInspectable; safecall;
    function CreateFromString(AValue: HSTRING): IInspectable; safecall;
    function GetMember(AName: HSTRING): IXamlMember; safecall;
    procedure AddToVector(AInstance: IInspectable; AValue: IInspectable); safecall;
    procedure AddToMap(AInstance: IInspectable; AKey: IInspectable; AValue: IInspectable); safecall;
    procedure RunInitializer; safecall;
  public
    constructor Create(AType: TWinUICustomType);
  end;

  TCustomXamlMember = class(TXamlInfoObject, IXamlMember)
  strict private
    FOwner: TWinUICustomType;
    FIndex: Integer;
  protected
    function get_IsAttachable: Boolean; safecall;
    function get_IsDependencyProperty: Boolean; safecall;
    function get_IsReadOnly: Boolean; safecall;
    function get_Name: HSTRING; safecall;
    function get_TargetType: IXamlType; safecall;
    function get_Type: IXamlType; safecall;
    function GetValue(AInstance: IInspectable): IInspectable; safecall;
    procedure SetValue(AInstance: IInspectable; AValue: IInspectable); safecall;
  public
    constructor Create(AOwner: TWinUICustomType; AIndex: Integer);
  end;

  /// <summary>
  ///   A type XAML converts by itself (Boolean, Double, String, ...). Only names
  ///   the type, like the system types C++/WinRT generates for XAML type info.
  /// </summary>
  TSimpleXamlType = class(TXamlInfoObject, IXamlType)
  strict private
    FFullName: string;
    FKind: TypeKind;
  protected
    function get_BaseType: IXamlType; safecall;
    function get_ContentProperty: IXamlMember; safecall;
    function get_FullName: HSTRING; safecall;
    function get_IsArray: Boolean; safecall;
    function get_IsCollection: Boolean; safecall;
    function get_IsConstructible: Boolean; safecall;
    function get_IsDictionary: Boolean; safecall;
    function get_IsMarkupExtension: Boolean; safecall;
    function get_IsBindable: Boolean; safecall;
    function get_ItemType: IXamlType; safecall;
    function get_KeyType: IXamlType; safecall;
    function get_BoxedType: IXamlType; safecall;
    function get_UnderlyingType: TypeName; safecall;
    function ActivateInstance: IInspectable; safecall;
    function CreateFromString(AValue: HSTRING): IInspectable; safecall;
    function GetMember(AName: HSTRING): IXamlMember; safecall;
    procedure AddToVector(AInstance: IInspectable; AValue: IInspectable); safecall;
    procedure AddToMap(AInstance: IInspectable; AKey: IInspectable; AValue: IInspectable); safecall;
    procedure RunInitializer; safecall;
  public
    constructor Create(const AFullName: string; AKind: TypeKind);
  end;

  /// <summary>
  ///   In the designer and the preview, which run without the app's code: an
  ///   element of an app namespace (&lt;local:ContactCard&gt;) shows as a labelled
  ///   frame. ContentControl's members (Margin, Width, Grid.Row) work, the user
  ///   control's own attributes are accepted and ignored.
  /// </summary>
  TPlaceholderXamlType = class(TXamlInfoObject, IXamlType)
  strict private
    FFullName: string;
    FBase: IXamlType;
  protected
    function get_BaseType: IXamlType; safecall;
    function get_ContentProperty: IXamlMember; safecall;
    function get_FullName: HSTRING; safecall;
    function get_IsArray: Boolean; safecall;
    function get_IsCollection: Boolean; safecall;
    function get_IsConstructible: Boolean; safecall;
    function get_IsDictionary: Boolean; safecall;
    function get_IsMarkupExtension: Boolean; safecall;
    function get_IsBindable: Boolean; safecall;
    function get_ItemType: IXamlType; safecall;
    function get_KeyType: IXamlType; safecall;
    function get_BoxedType: IXamlType; safecall;
    function get_UnderlyingType: TypeName; safecall;
    function ActivateInstance: IInspectable; safecall;
    function CreateFromString(AValue: HSTRING): IInspectable; safecall;
    function GetMember(AName: HSTRING): IXamlMember; safecall;
    procedure AddToVector(AInstance: IInspectable; AValue: IInspectable); safecall;
    procedure AddToMap(AInstance: IInspectable; AKey: IInspectable; AValue: IInspectable); safecall;
    procedure RunInitializer; safecall;
  public
    constructor Create(const AFullName: string);
  end;

  /// <summary>An attribute of a placeholder that only XAML's parser sees.</summary>
  TPlaceholderXamlMember = class(TXamlInfoObject, IXamlMember)
  strict private
    FName: string;
    FOwner: IXamlType;
  protected
    function get_IsAttachable: Boolean; safecall;
    function get_IsDependencyProperty: Boolean; safecall;
    function get_IsReadOnly: Boolean; safecall;
    function get_Name: HSTRING; safecall;
    function get_TargetType: IXamlType; safecall;
    function get_Type: IXamlType; safecall;
    function GetValue(AInstance: IInspectable): IInspectable; safecall;
    procedure SetValue(AInstance: IInspectable; AValue: IInspectable); safecall;
  public
    constructor Create(const AOwner: IXamlType; const AName: string);
  end;

var
  Registry: TArray<TWinUICustomType>;
  Placeholders: TArray<IXamlType>;
  PlaceholderNames: TArray<string>;
  // Every host that exists, so the controls of a closed window and those left
  // at shutdown are freed
  Hosts: TArray<TWinUIControlHost>;
  ContentControlFactoryCache: IInspectable;
  // WinUI's own metadata, for the ContentControl base of every custom type
  ControlsProvider: IXamlMetadataProvider;
  Templates: TArray<IInspectable>;
  TemplateClasses: TArray<TClass>;

function HighContrastOn: Boolean;
var
  Info: THighContrast;
begin
  Info.cbSize := SizeOf(Info);
  Result := SystemParametersInfo(SPI_GETHIGHCONTRAST, SizeOf(Info), @Info, 0) and
    (Info.dwFlags and HCF_HIGHCONTRASTON <> 0);
end;

function SystemColor(AIndex: Integer): Color;
var
  Value: COLORREF;
begin
  Value := GetSysColor(AIndex);
  Result.A := $FF;
  Result.R := GetRValue(Value);
  Result.G := GetGValue(Value);
  Result.B := GetBValue(Value);
end;

function SameObject(const A, B: IInterface): Boolean;
var
  UA, UB: IInterface;
begin
  // COM identity: the IUnknown each object answers
  if (A = nil) or (B = nil) then
    Exit(Pointer(A) = Pointer(B));
  A.QueryInterface(IInterface, UA);
  B.QueryInterface(IInterface, UB);
  Result := Pointer(UA) = Pointer(UB);
end;

function BaseXamlType(const AFullName: string): IXamlType;
begin
  if ControlsProvider = nil then
    ControlsProvider := XamlControlsXamlMetaDataProvider.New;
  Result := ControlsProvider.GetXamlTypeByFullName(WinStr(AFullName));
end;

function EnumNames(AInfo: PTypeInfo): string;
var
  Data: PTypeData;
  I: Integer;
begin
  Data := GetTypeData(AInfo);
  Result := '';
  for I := Data.MinValue to Data.MaxValue do
  begin
    if I > Data.MinValue then
      Result := Result + '|';
    Result := Result + GetEnumName(AInfo, I);
  end;
end;

function PropertyTypeName(const AProp: TWinUICustomProperty): string;
const
  Names: array[TWinUIPropertyKind] of string = ('Boolean', 'Int32', 'Double', 'String',
    'Microsoft.UI.Xaml.Media.Brush', 'Object', 'Int32');
begin
  Result := Names[AProp.Kind];
end;

function MemberXamlType(const AProp: TWinUICustomProperty): IXamlType;
begin
  case AProp.Kind of
    TWinUIPropertyKind.Brush:
      Result := BaseXamlType('Microsoft.UI.Xaml.Media.Brush');
    // XAML hands enumeration names over as text, SetValue looks them up
    TWinUIPropertyKind.Enum:
      Result := TSimpleXamlType.Create('String', TypeKind.Primitive);
  else
    Result := TSimpleXamlType.Create(PropertyTypeName(AProp), TypeKind.Primitive);
  end;
end;

function InvariantFloat(const AText: string): Double;
var
  Settings: TFormatSettings;
begin
  Settings := TFormatSettings.Invariant;
  Result := StrToFloat(AText, Settings);
end;

function DefaultValue(const AProp: TWinUICustomProperty): IInspectable;
begin
  Result := nil;
  case AProp.Kind of
    TWinUIPropertyKind.Boolean:
      Result := PropertyValue.CreateBoolean(SameText(AProp.DefaultText, 'True'));
    TWinUIPropertyKind.Int32:
      Result := PropertyValue.CreateInt32(StrToIntDef(AProp.DefaultText, 0));
    TWinUIPropertyKind.Double:
      if AProp.DefaultText = '' then
        Result := PropertyValue.CreateDouble(0)
      else
        Result := PropertyValue.CreateDouble(InvariantFloat(AProp.DefaultText));
    TWinUIPropertyKind.Text:
      Result := PropertyValue.CreateString(WinStr(AProp.DefaultText));
    TWinUIPropertyKind.Enum:
      if AProp.DefaultText = '' then
        Result := PropertyValue.CreateInt32(0)
      else
        Result := PropertyValue.CreateInt32(GetEnumValue(AProp.EnumType, AProp.DefaultText));
  end;
end;

function UnboxDouble(const AValue: IInspectable): Double;
var
  PV: IPropertyValue;
begin
  if Supports(AValue, IPropertyValue, PV) then
    case PV.&Type of
      PropertyType.Double:
        Exit(PV.GetDouble);
      PropertyType.Single:
        Exit(PV.GetSingle);
      PropertyType.Int32:
        Exit(PV.GetInt32);
    end;
  Result := 0;
end;

{ TWinUICustomType }

constructor TWinUICustomType.Create(AClass: TWinUICustomControlClass; const AXamlName, ACategory: string);
begin
  inherited Create;
  FControlClass := AClass;
  FXamlName := AXamlName;
  FCategory := ACategory;
end;

function TWinUICustomType.GetFullName: string;
begin
  Result := CustomControlsNamespace + '.' + FXamlName;
end;

function TWinUICustomType.GetProperty(AIndex: Integer): TWinUICustomProperty;
begin
  Result := FProperties[AIndex];
end;

function TWinUICustomType.PropertyCount: Integer;
begin
  Result := Length(FProperties);
end;

procedure TWinUICustomType.AddProperty(const AName: string; AKind: TWinUIPropertyKind; const ADefault: string;
  AEnumType: PTypeInfo);
var
  Prop: TWinUICustomProperty;
begin
  if (AKind = TWinUIPropertyKind.Enum) and ((AEnumType = nil) or (AEnumType.Kind <> tkEnumeration)) then
    raise EArgumentException.CreateFmt('%s.%s: an Enum property needs the enumeration type', [FXamlName, AName]);
  Prop := Default(TWinUICustomProperty);
  Prop.Name := AName;
  Prop.Kind := AKind;
  Prop.DefaultText := ADefault;
  Prop.EnumType := AEnumType;
  FProperties := FProperties + [Prop];
end;

procedure TWinUICustomType.AddEvent(const AName: string);
begin
  FEvents := FEvents + [AName];
end;

procedure TWinUICustomType.SetEditor(const AName, AEditor: string);
var
  Index: Integer;
begin
  Index := IndexOf(AName);
  if Index < 0 then
    raise EArgumentException.CreateFmt('%s has no property %s', [FXamlName, AName]);
  FProperties[Index].Editor := AEditor;
end;

function TWinUICustomType.IndexOf(const AName: string): Integer;
begin
  for Result := 0 to High(FProperties) do
    if SameText(FProperties[Result].Name, AName) then
      Exit;
  Result := -1;
end;

function TWinUICustomType.IndexOfProp(const AProp: IDependencyProperty): Integer;
begin
  for Result := 0 to High(FProperties) do
    if SameObject(FProperties[Result].Prop, AProp) then
      Exit;
  Result := -1;
end;

procedure TWinUICustomType.EnsureRegistered;
var
  I: Integer;
  Owner, PropType: TypeName;
  Callback: PropertyChangedCallback;
  OwnerName, PropName: TWinString;
begin
  if FRegistered then
    Exit;
  FRegistered := True;
  // One callback for every property: it finds the control and the property
  Callback := TPropertyChangedCallback.Create(
    procedure(AD: IDependencyObject; AE: IDependencyPropertyChangedEventArgs)
    var
      Pascal: IWinUIPascalObject;
      Control: TObject;
      Index: Integer;
    begin
      if not Supports(AD, IWinUIPascalObject, Pascal) then
        Exit;
      Control := Pascal.PascalObject;
      if not (Control is TWinUICustomControl) then
        Exit;
      Index := TWinUICustomControl(Control).CustomType.IndexOfProp(AE.&Property);
      if Index >= 0 then
        TWinUICustomControl(Control).HostPropertyChanged(Index);
    end);
  OwnerName := WinStr(FullName);
  Owner.&Name := OwnerName;
  Owner.Kind := TypeKind.Custom;
  for I := 0 to High(FProperties) do
  begin
    PropName := WinStr(PropertyTypeName(FProperties[I]));
    PropType.&Name := PropName;
    if FProperties[I].Kind = TWinUIPropertyKind.Brush then
      PropType.Kind := TypeKind.Metadata
    else
      PropType.Kind := TypeKind.Primitive;
    FProperties[I].Prop := DependencyProperty.&Register(WinStr(FProperties[I].Name), PropType, Owner,
      PropertyMetadata.CreateWithDefaultValueAndCallback(DefaultValue(FProperties[I]), Callback));
  end;
end;

function TWinUICustomType.XamlType: IXamlType;
begin
  if FXamlType = nil then
    FXamlType := TCustomXamlType.Create(Self);
  Result := FXamlType;
end;

{ TWinUIControlHost }

constructor TWinUIControlHost.Create(AType: TWinUICustomType);
var
  Outer: IInspectable;
  Delegating: IContentControl;
begin
  inherited Create;
  FType := AType;
  Hosts := Hosts + [Self];
  AType.EnsureRegistered;
  // The reference count is 1 until AfterConstruction (TInterfacedObject), so
  // the AddRef/Release pairs the inner object makes on us cannot free us here.
  Outer := Self as IInspectable;
  Delegating := IContentControlFactory(GetFactory(ContentControl.RuntimeClassName, IContentControlFactory,
    ContentControlFactoryCache)).CreateInstance(Outer, FInner);
  // Delegating forwards AddRef to us, keeping it would be a reference cycle.
  Delegating := nil;
end;

destructor TWinUIControlHost.Destroy;
var
  Control: TWinUICustomControl;
  I: Integer;
begin
  for I := High(Hosts) downto 0 do
    if Hosts[I] = Self then
      Delete(Hosts, I, 1);
  // Freeing the control queries the inner object, whose AddRef/Release come
  // back here: keep the count above zero so that cannot destroy us twice.
  Inc(FRefCount);
  try
    Control := FControl;
    FControl := nil;
    if FOwnsControl and (Control <> nil) then
      Control.Free;
  finally
    Dec(FRefCount);
  end;
  FInner := nil;
  inherited;
end;

/// The Pascal control's cached interfaces of the element hold this host, and the
/// host owns the control: a cycle that XAML alone never breaks. Freeing the
/// control when its window goes (or at shutdown) breaks it, after that XAML's
/// own references decide when the host goes.
procedure TWinUIControlHost.ReleaseControl;
var
  Keep: IInspectable;
  Control: TWinUICustomControl;
begin
  if not FOwnsControl or (FControl = nil) then
    Exit;
  // The last cached interface of the control may be the last reference: the
  // host must outlive the control's destructor
  Keep := Self as IInspectable;
  Control := FControl;
  FControl := nil;
  FOwnerWindow := nil;
  Control.Free;
  Keep := nil;
end;

/// Frees the controls that AOwner's XAML created, every remaining one when AOwner is nil.
procedure ReleaseHostedControls(AOwner: TObject);
var
  Host: TWinUIControlHost;
  Pending: TArray<TWinUIControlHost>;
  I: Integer;
begin
  Pending := nil;
  for Host in Hosts do
    if (AOwner = nil) or (Host.FOwnerWindow = AOwner) then
      Pending := Pending + [Host];
  for I := 0 to High(Pending) do
    // An earlier control's destructor may have freed a later host already
    for Host in Hosts do
      if Host = Pending[I] then
      begin
        Host.ReleaseControl;
        Break;
      end;
end;

{ Automation peers }

type
  /// <summary>
  ///   Delphi's half of an automation peer composed over WinUI's
  ///   FrameworkElementAutomationPeer (the aggregation the controls themselves
  ///   use): every IAutomationPeerOverrides method goes to the base, unless a
  ///   descendant overrides it.
  /// </summary>
  TComposedPeer = class(TInterfacedObject, IInspectable, IAutomationPeerOverrides)
  protected
    FInner: IInspectable;
    function QueryInterface(const IID: TGUID; out Obj): HRESULT; stdcall;
    procedure GetIids(out AIidCount: Cardinal; out AIids: PGUID); safecall;
    function GetRuntimeClassName: HSTRING; safecall;
    function GetTrustLevel: TrustLevel; safecall;
    /// <summary>The base class's own implementation (the inner object's).</summary>
    function Base: IAutomationPeerOverrides;
    function Provider(const APeer: IAutomationPeer): IIRawElementProviderSimple;
    { IAutomationPeerOverrides }
    function GetPatternCore(APatternInterface: PatternInterface): IInspectable; virtual; safecall;
    function GetAcceleratorKeyCore: HSTRING; safecall;
    function GetAccessKeyCore: HSTRING; safecall;
    function GetAutomationControlTypeCore: AutomationControlType; virtual; safecall;
    function GetAutomationIdCore: HSTRING; virtual; safecall;
    function GetBoundingRectangleCore: RADWinUI.Abi.Rect; virtual; safecall;
    function GetChildrenCore: IVector_AutomationPeer; virtual; safecall;
    function NavigateCore(ADirection: AutomationNavigationDirection): IInspectable; safecall;
    function GetClassNameCore: HSTRING; virtual; safecall;
    function GetClickablePointCore: RADWinUI.Abi.Point; safecall;
    function GetHelpTextCore: HSTRING; safecall;
    function GetItemStatusCore: HSTRING; safecall;
    function GetItemTypeCore: HSTRING; safecall;
    function GetLabeledByCore: IAutomationPeer; safecall;
    function GetLocalizedControlTypeCore: HSTRING; safecall;
    function GetNameCore: HSTRING; virtual; safecall;
    function GetOrientationCore: AutomationOrientation; safecall;
    function HasKeyboardFocusCore: Boolean; safecall;
    function IsContentElementCore: Boolean; safecall;
    function IsControlElementCore: Boolean; virtual; safecall;
    function IsEnabledCore: Boolean; safecall;
    function IsKeyboardFocusableCore: Boolean; virtual; safecall;
    function IsOffscreenCore: Boolean; safecall;
    function IsPasswordCore: Boolean; safecall;
    function IsRequiredForFormCore: Boolean; safecall;
    procedure SetFocusCore; safecall;
    function GetPeerFromPointCore(APoint: RADWinUI.Abi.Point): IAutomationPeer; safecall;
    function GetElementFromPointCore(APointInWindowCoordinates: RADWinUI.Abi.Point): IInspectable; safecall;
    function GetFocusedElementCore: IInspectable; safecall;
    function GetLiveSettingCore: AutomationLiveSetting; safecall;
    procedure ShowContextMenuCore; safecall;
    function GetControlledPeersCore: IVectorView_AutomationPeer; safecall;
    function GetAnnotationsCore: IVector_AutomationPeerAnnotation; safecall;
    function GetPositionInSetCore: Integer; virtual; safecall;
    function GetSizeOfSetCore: Integer; virtual; safecall;
    function GetLevelCore: Integer; safecall;
    function GetLandmarkTypeCore: AutomationLandmarkType; safecall;
    function GetLocalizedLandmarkTypeCore: HSTRING; safecall;
    function IsPeripheralCore: Boolean; safecall;
    function IsDataValidForFormCore: Boolean; safecall;
    function GetFullDescriptionCore: HSTRING; safecall;
    function GetDescribedByCore: IIterable_AutomationPeer; safecall;
    function GetFlowsToCore: IIterable_AutomationPeer; safecall;
    function GetFlowsFromCore: IIterable_AutomationPeer; safecall;
    function GetCultureCore: Integer; safecall;
    function GetHeadingLevelCore: AutomationHeadingLevel; safecall;
    function IsDialogCore: Boolean; safecall;
  public
    constructor Create(const AOwner: IFrameworkElement);
    function Peer: IAutomationPeer;
  end;

  TItemPeer = class;

  /// <summary>The peer of a TWinUICustomControl: its role, name and patterns come from the control's hooks.</summary>
  TControlPeer = class(TComposedPeer, IInvokeProvider, IToggleProvider, IExpandCollapseProvider, ISelectionProvider)
  private
    FHost: TWinUIControlHost; // not counted: checked with HostAlive
    FItems: TArray<TItemPeer>;
    FItemRefs: TArray<IInspectable>;
    function Control: TWinUICustomControl;
    procedure UpdateItems;
  protected
    function GetPatternCore(APatternInterface: PatternInterface): IInspectable; override;
    function GetAutomationControlTypeCore: AutomationControlType; override;
    function GetClassNameCore: HSTRING; override;
    function GetNameCore: HSTRING; override;
    function GetChildrenCore: IVector_AutomationPeer; override;
    function IsControlElementCore: Boolean; override;
    { IInvokeProvider }
    procedure Invoke; safecall;
    { IToggleProvider }
    function get_ToggleState: ToggleState; safecall;
    procedure Toggle; safecall;
    { IExpandCollapseProvider }
    function get_ExpandCollapseState: ExpandCollapseState; safecall;
    procedure Collapse; safecall;
    procedure Expand; safecall;
    { ISelectionProvider }
    function get_CanSelectMultiple: Boolean; safecall;
    function get_IsSelectionRequired: Boolean; safecall;
    procedure GetSelection(out AResultSize: Cardinal; out AResult: Pointer); safecall;
  public
    constructor Create(AHost: TWinUIControlHost; const AOwner: IFrameworkElement);
    destructor Destroy; override;
    procedure SelectionChanged;
  end;

  /// <summary>One item of a control with the Selection pattern, such as a tab of a tab bar.</summary>
  TItemPeer = class(TComposedPeer, ISelectionItemProvider)
  private
    FParent: TControlPeer; // cleared when the parent goes
    FIndex: Integer;
  protected
    function GetPatternCore(APatternInterface: PatternInterface): IInspectable; override;
    function GetAutomationControlTypeCore: AutomationControlType; override;
    function GetClassNameCore: HSTRING; override;
    function GetNameCore: HSTRING; override;
    function GetAutomationIdCore: HSTRING; override;
    function GetChildrenCore: IVector_AutomationPeer; override;
    function IsKeyboardFocusableCore: Boolean; override;
    function GetPositionInSetCore: Integer; override;
    function GetSizeOfSetCore: Integer; override;
    function GetBoundingRectangleCore: RADWinUI.Abi.Rect; override;
    { ISelectionItemProvider }
    function get_IsSelected: Boolean; safecall;
    function get_SelectionContainer: IIRawElementProviderSimple; safecall;
    procedure AddToSelection; safecall;
    procedure RemoveFromSelection; safecall;
    procedure Select; safecall;
  end;

var
  FrameworkElementPeerFactoryCache: IInspectable;

function HostAlive(AHost: TWinUIControlHost): Boolean;
var
  Host: TWinUIControlHost;
begin
  for Host in Hosts do
    if Host = AHost then
      Exit(True);
  Result := False;
end;

{ TComposedPeer }

constructor TComposedPeer.Create(const AOwner: IFrameworkElement);
var
  Outer: IInspectable;
  Delegating: IFrameworkElementAutomationPeer;
begin
  inherited Create;
  // As TWinUIControlHost.Create: the count stays above zero while the inner object is made
  Outer := Self as IInspectable;
  Delegating := IFrameworkElementAutomationPeerFactory(GetFactory(
    'Microsoft.UI.Xaml.Automation.Peers.FrameworkElementAutomationPeer', IFrameworkElementAutomationPeerFactory,
    FrameworkElementPeerFactoryCache)).CreateInstanceWithOwner(AOwner, Outer, FInner);
  Delegating := nil;
end;

function TComposedPeer.QueryInterface(const IID: TGUID; out Obj): HRESULT;
begin
  if GetInterface(IID, Obj) then
    Exit(S_OK);
  if FInner <> nil then
    Exit(FInner.QueryInterface(IID, Obj));
  Pointer(Obj) := nil;
  Result := E_NOINTERFACE;
end;

procedure TComposedPeer.GetIids(out AIidCount: Cardinal; out AIids: PGUID);
begin
  FInner.GetIids(AIidCount, AIids);
end;

function TComposedPeer.GetRuntimeClassName: HSTRING;
begin
  Result := NewHString('Microsoft.UI.Xaml.Automation.Peers.FrameworkElementAutomationPeer');
end;

function TComposedPeer.GetTrustLevel: TrustLevel;
begin
  Result := FInner.GetTrustLevel;
end;

function TComposedPeer.Base: IAutomationPeerOverrides;
begin
  // Asked each time: a kept reference would count on this outer object, a cycle
  Result := FInner as IAutomationPeerOverrides;
end;

function TComposedPeer.Provider(const APeer: IAutomationPeer): IIRawElementProviderSimple;
begin
  Result := (FInner as IAutomationPeerProtected).ProviderFromPeer(APeer);
end;

function TComposedPeer.Peer: IAutomationPeer;
begin
  Result := (Self as IInspectable) as IAutomationPeer;
end;

function TComposedPeer.GetPatternCore(APatternInterface: PatternInterface): IInspectable;
begin
  Result := Base.GetPatternCore(APatternInterface);
end;

function TComposedPeer.GetAcceleratorKeyCore: HSTRING;
begin
  Result := Base.GetAcceleratorKeyCore;
end;

function TComposedPeer.GetAccessKeyCore: HSTRING;
begin
  Result := Base.GetAccessKeyCore;
end;

function TComposedPeer.GetAutomationControlTypeCore: AutomationControlType;
begin
  Result := Base.GetAutomationControlTypeCore;
end;

function TComposedPeer.GetAutomationIdCore: HSTRING;
begin
  Result := Base.GetAutomationIdCore;
end;

function TComposedPeer.GetBoundingRectangleCore: RADWinUI.Abi.Rect;
begin
  Result := Base.GetBoundingRectangleCore;
end;

function TComposedPeer.GetChildrenCore: IVector_AutomationPeer;
begin
  Result := Base.GetChildrenCore;
end;

function TComposedPeer.NavigateCore(ADirection: AutomationNavigationDirection): IInspectable;
begin
  Result := Base.NavigateCore(ADirection);
end;

function TComposedPeer.GetClassNameCore: HSTRING;
begin
  Result := Base.GetClassNameCore;
end;

function TComposedPeer.GetClickablePointCore: RADWinUI.Abi.Point;
begin
  Result := Base.GetClickablePointCore;
end;

function TComposedPeer.GetHelpTextCore: HSTRING;
begin
  Result := Base.GetHelpTextCore;
end;

function TComposedPeer.GetItemStatusCore: HSTRING;
begin
  Result := Base.GetItemStatusCore;
end;

function TComposedPeer.GetItemTypeCore: HSTRING;
begin
  Result := Base.GetItemTypeCore;
end;

function TComposedPeer.GetLabeledByCore: IAutomationPeer;
begin
  Result := Base.GetLabeledByCore;
end;

function TComposedPeer.GetLocalizedControlTypeCore: HSTRING;
begin
  Result := Base.GetLocalizedControlTypeCore;
end;

function TComposedPeer.GetNameCore: HSTRING;
begin
  Result := Base.GetNameCore;
end;

function TComposedPeer.GetOrientationCore: AutomationOrientation;
begin
  Result := Base.GetOrientationCore;
end;

function TComposedPeer.HasKeyboardFocusCore: Boolean;
begin
  Result := Base.HasKeyboardFocusCore;
end;

function TComposedPeer.IsContentElementCore: Boolean;
begin
  Result := Base.IsContentElementCore;
end;

function TComposedPeer.IsControlElementCore: Boolean;
begin
  Result := Base.IsControlElementCore;
end;

function TComposedPeer.IsEnabledCore: Boolean;
begin
  Result := Base.IsEnabledCore;
end;

function TComposedPeer.IsKeyboardFocusableCore: Boolean;
begin
  Result := Base.IsKeyboardFocusableCore;
end;

function TComposedPeer.IsOffscreenCore: Boolean;
begin
  Result := Base.IsOffscreenCore;
end;

function TComposedPeer.IsPasswordCore: Boolean;
begin
  Result := Base.IsPasswordCore;
end;

function TComposedPeer.IsRequiredForFormCore: Boolean;
begin
  Result := Base.IsRequiredForFormCore;
end;

procedure TComposedPeer.SetFocusCore;
begin
  Base.SetFocusCore;
end;

function TComposedPeer.GetPeerFromPointCore(APoint: RADWinUI.Abi.Point): IAutomationPeer;
begin
  Result := Base.GetPeerFromPointCore(APoint);
end;

function TComposedPeer.GetElementFromPointCore(APointInWindowCoordinates: RADWinUI.Abi.Point): IInspectable;
begin
  Result := Base.GetElementFromPointCore(APointInWindowCoordinates);
end;

function TComposedPeer.GetFocusedElementCore: IInspectable;
begin
  Result := Base.GetFocusedElementCore;
end;

function TComposedPeer.GetLiveSettingCore: AutomationLiveSetting;
begin
  Result := Base.GetLiveSettingCore;
end;

procedure TComposedPeer.ShowContextMenuCore;
begin
  Base.ShowContextMenuCore;
end;

function TComposedPeer.GetControlledPeersCore: IVectorView_AutomationPeer;
begin
  Result := Base.GetControlledPeersCore;
end;

function TComposedPeer.GetAnnotationsCore: IVector_AutomationPeerAnnotation;
begin
  Result := Base.GetAnnotationsCore;
end;

function TComposedPeer.GetPositionInSetCore: Integer;
begin
  Result := Base.GetPositionInSetCore;
end;

function TComposedPeer.GetSizeOfSetCore: Integer;
begin
  Result := Base.GetSizeOfSetCore;
end;

function TComposedPeer.GetLevelCore: Integer;
begin
  Result := Base.GetLevelCore;
end;

function TComposedPeer.GetLandmarkTypeCore: AutomationLandmarkType;
begin
  Result := Base.GetLandmarkTypeCore;
end;

function TComposedPeer.GetLocalizedLandmarkTypeCore: HSTRING;
begin
  Result := Base.GetLocalizedLandmarkTypeCore;
end;

function TComposedPeer.IsPeripheralCore: Boolean;
begin
  Result := Base.IsPeripheralCore;
end;

function TComposedPeer.IsDataValidForFormCore: Boolean;
begin
  Result := Base.IsDataValidForFormCore;
end;

function TComposedPeer.GetFullDescriptionCore: HSTRING;
begin
  Result := Base.GetFullDescriptionCore;
end;

function TComposedPeer.GetDescribedByCore: IIterable_AutomationPeer;
begin
  Result := Base.GetDescribedByCore;
end;

function TComposedPeer.GetFlowsToCore: IIterable_AutomationPeer;
begin
  Result := Base.GetFlowsToCore;
end;

function TComposedPeer.GetFlowsFromCore: IIterable_AutomationPeer;
begin
  Result := Base.GetFlowsFromCore;
end;

function TComposedPeer.GetCultureCore: Integer;
begin
  Result := Base.GetCultureCore;
end;

function TComposedPeer.GetHeadingLevelCore: AutomationHeadingLevel;
begin
  Result := Base.GetHeadingLevelCore;
end;

function TComposedPeer.IsDialogCore: Boolean;
begin
  Result := Base.IsDialogCore;
end;


{ TControlPeer }

constructor TControlPeer.Create(AHost: TWinUIControlHost; const AOwner: IFrameworkElement);
begin
  inherited Create(AOwner);
  FHost := AHost;
end;

destructor TControlPeer.Destroy;
var
  Item: TItemPeer;
begin
  for Item in FItems do
    Item.FParent := nil;
  FItemRefs := nil;
  if HostAlive(FHost) and (FHost.FPeer = Self) then
    FHost.FPeer := nil;
  inherited;
end;

function TControlPeer.Control: TWinUICustomControl;
begin
  if HostAlive(FHost) then
    Result := FHost.FControl
  else
    Result := nil;
end;

function TControlPeer.GetPatternCore(APatternInterface: PatternInterface): IInspectable;
const
  Patterns: array[TWinUIAutomationPattern] of PatternInterface = (PatternInterface.Invoke,
    PatternInterface.Toggle, PatternInterface.ExpandCollapse, PatternInterface.Selection);
var
  Pattern: TWinUIAutomationPattern;
begin
  if Control <> nil then
    for Pattern := Low(Pattern) to High(Pattern) do
      if (Patterns[Pattern] = APatternInterface) and (Pattern in Control.AutomationPatterns) then
        Exit(Self as IInspectable);
  Result := inherited;
end;

function TControlPeer.GetAutomationControlTypeCore: AutomationControlType;
begin
  if Control <> nil then
    Result := Control.AutomationRole
  else
    Result := inherited;
end;

function TControlPeer.GetClassNameCore: HSTRING;
begin
  if Control <> nil then
    Result := NewHString(Control.CustomType.XamlName)
  else
    Result := inherited;
end;

function TControlPeer.GetNameCore: HSTRING;
var
  Name: string;
begin
  // AutomationProperties.Name wins, then what the control says
  Name := TakeHString(inherited);
  if (Name = '') and (Control <> nil) then
    Name := Control.AutomationName;
  Result := NewHString(Name);
end;

function TControlPeer.IsControlElementCore: Boolean;
begin
  Result := True;
end;

procedure TControlPeer.UpdateItems;
var
  I, Count: Integer;
  Item: TItemPeer;
begin
  if Control = nil then
    Count := 0
  else
    Count := Control.AutomationItemCount;
  if Count = Length(FItems) then
    Exit;
  for Item in FItems do
    Item.FParent := nil;
  FItemRefs := nil;
  SetLength(FItems, Count);
  SetLength(FItemRefs, Count);
  for I := 0 to Count - 1 do
  begin
    // Owned by the control's element: an item has no element of its own to point at
    FItems[I] := TItemPeer.Create(TWinUIObject.IntfOf(Control, IFrameworkElement) as IFrameworkElement);
    FItems[I].FParent := Self;
    FItems[I].FIndex := I;
    FItemRefs[I] := FItems[I] as IInspectable;
  end;
end;

function TControlPeer.GetChildrenCore: IVector_AutomationPeer;
var
  Item: TItemPeer;
begin
  Result := inherited;
  if (Control = nil) or not (TWinUIAutomationPattern.Selection in Control.AutomationPatterns) then
    Exit;
  // The items are the children: the drawn parts under them say nothing on their own
  UpdateItems;
  if Result <> nil then
  begin
    Result.Clear;
    for Item in FItems do
      Result.Append(Item.Peer);
  end;
end;

procedure TControlPeer.SelectionChanged;
var
  Index: Integer;
begin
  if Control = nil then
    Exit;
  UpdateItems;
  Index := Control.AutomationSelectedIndex;
  if (Index >= 0) and (Index < Length(FItems)) then
    FItems[Index].Peer.RaiseAutomationEvent(AutomationEvents.SelectionItemPatternOnElementSelected);
end;

procedure TControlPeer.Invoke;
begin
  if Control <> nil then
    Control.AutomationInvoke;
end;

function TControlPeer.get_ToggleState: ToggleState;
begin
  if Control <> nil then
    Result := Control.AutomationToggleState
  else
    Result := ToggleState.Off;
end;

procedure TControlPeer.Toggle;
begin
  if Control <> nil then
    Control.AutomationToggle;
end;

function TControlPeer.get_ExpandCollapseState: ExpandCollapseState;
begin
  if (Control <> nil) and Control.AutomationExpanded then
    Result := ExpandCollapseState.Expanded
  else
    Result := ExpandCollapseState.Collapsed;
end;

procedure TControlPeer.Collapse;
begin
  if Control <> nil then
    Control.AutomationExpand(False);
end;

procedure TControlPeer.Expand;
begin
  if Control <> nil then
    Control.AutomationExpand(True);
end;

function TControlPeer.get_CanSelectMultiple: Boolean;
begin
  Result := False;
end;

function TControlPeer.get_IsSelectionRequired: Boolean;
begin
  Result := True;
end;

procedure TControlPeer.GetSelection(out AResultSize: Cardinal; out AResult: Pointer);
var
  Index: Integer;
  Item: IIRawElementProviderSimple;
begin
  AResultSize := 0;
  AResult := nil;
  if Control = nil then
    Exit;
  UpdateItems;
  Index := Control.AutomationSelectedIndex;
  if (Index < 0) or (Index >= Length(FItems)) then
    Exit;
  // A COM array the caller frees: one counted reference
  Item := Provider(FItems[Index].Peer);
  AResult := CoTaskMemAlloc(SizeOf(Pointer));
  PPointer(AResult)^ := Pointer(Item);
  Pointer(Item) := nil;
  AResultSize := 1;
end;

{ TItemPeer }

function TItemPeer.GetPatternCore(APatternInterface: PatternInterface): IInspectable;
begin
  if APatternInterface = PatternInterface.SelectionItem then
    Result := Self as IInspectable
  else
    Result := nil;
end;

function TItemPeer.GetAutomationControlTypeCore: AutomationControlType;
begin
  Result := AutomationControlType.TabItem;
end;

function TItemPeer.GetClassNameCore: HSTRING;
begin
  Result := NewHString('TabItem');
end;

function TItemPeer.GetNameCore: HSTRING;
begin
  if (FParent <> nil) and (FParent.Control <> nil) then
    Result := NewHString(FParent.Control.AutomationItemName(FIndex))
  else
    Result := NewHString('');
end;

function TItemPeer.GetAutomationIdCore: HSTRING;
var
  Id: string;
begin
  // The control's id and the item's index: Tabs.0, Tabs.1...
  Id := TakeHString(inherited);
  if Id <> '' then
    Id := Id + '.' + IntToStr(FIndex);
  Result := NewHString(Id);
end;

function TItemPeer.GetChildrenCore: IVector_AutomationPeer;
begin
  // The control's own children belong to the control, not to each item
  Result := nil;
end;

function TItemPeer.IsKeyboardFocusableCore: Boolean;
begin
  // The control takes the focus, the arrow keys move the selection between items
  Result := False;
end;

function TItemPeer.GetPositionInSetCore: Integer;
begin
  Result := FIndex + 1;
end;

function TItemPeer.GetSizeOfSetCore: Integer;
begin
  if FParent <> nil then
    Result := Length(FParent.FItems)
  else
    Result := 0;
end;

function TItemPeer.GetBoundingRectangleCore: RADWinUI.Abi.Rect;
var
  Left, Width, Full: Double;
begin
  Result := inherited;
  if (FParent = nil) or (FParent.Control = nil) or not FParent.Control.AutomationItemSpan(FIndex, Left, Width) then
    Exit;
  Full := (TWinUIObject.IntfOf(FParent.Control, IFrameworkElement) as IFrameworkElement).ActualWidth;
  if Full <= 0 then
    Exit;
  Result.X := Result.X + Result.Width * Left / Full;
  Result.Width := Result.Width * Width / Full;
end;

function TItemPeer.get_IsSelected: Boolean;
begin
  Result := (FParent <> nil) and (FParent.Control <> nil) and (FParent.Control.AutomationSelectedIndex = FIndex);
end;

function TItemPeer.get_SelectionContainer: IIRawElementProviderSimple;
begin
  if FParent <> nil then
    Result := Provider(FParent.Peer)
  else
    Result := nil;
end;

procedure TItemPeer.AddToSelection;
begin
  Select;
end;

procedure TItemPeer.RemoveFromSelection;
begin
  // One tab is always selected
end;

procedure TItemPeer.Select;
begin
  if (FParent <> nil) and (FParent.Control <> nil) then
    FParent.Control.AutomationSelect(FIndex);
end;

{ TWinUIControlHost: IUIElementOverrides }

function TWinUIControlHost.OnCreateAutomationPeer: IAutomationPeer;
var
  Peer: TControlPeer;
begin
  if (FControl = nil) or ((FControl.AutomationRole = AutomationControlType.Custom) and
    (FControl.AutomationPatterns = [])) then
    Exit((FInner as IUIElementOverrides).OnCreateAutomationPeer);
  Peer := TControlPeer.Create(Self, Self as IFrameworkElement);
  FPeer := Peer;
  Result := Peer.Peer;
end;

procedure TWinUIControlHost.OnDisconnectVisualChildren;
begin
  (FInner as IUIElementOverrides).OnDisconnectVisualChildren;
end;

function TWinUIControlHost.FindSubElementsForTouchTargeting(APoint: RADWinUI.Abi.Point;
  ABoundingRect: RADWinUI.Abi.Rect): IIterable_IIterable_Point;
begin
  Result := (FInner as IUIElementOverrides).FindSubElementsForTouchTargeting(APoint, ABoundingRect);
end;

function TWinUIControlHost.GetChildrenInTabFocusOrder: IIterable_DependencyObject;
begin
  Result := (FInner as IUIElementOverrides).GetChildrenInTabFocusOrder;
end;

procedure TWinUIControlHost.OnKeyboardAcceleratorInvoked(AArgs: IKeyboardAcceleratorInvokedEventArgs);
begin
  (FInner as IUIElementOverrides).OnKeyboardAcceleratorInvoked(AArgs);
end;

procedure TWinUIControlHost.OnProcessKeyboardAccelerators(AArgs: IProcessKeyboardAcceleratorEventArgs);
begin
  (FInner as IUIElementOverrides).OnProcessKeyboardAccelerators(AArgs);
end;

procedure TWinUIControlHost.OnBringIntoViewRequested(AE: IBringIntoViewRequestedEventArgs);
begin
  (FInner as IUIElementOverrides).OnBringIntoViewRequested(AE);
end;

procedure TWinUIControlHost.PopulatePropertyInfoOverride(APropertyName: HSTRING;
  AAnimationPropertyInfo: IAnimationPropertyInfo);
begin
  (FInner as IUIElementOverrides).PopulatePropertyInfoOverride(APropertyName, AAnimationPropertyInfo);
end;

function TWinUIControlHost.QueryInterface(const IID: TGUID; out Obj): HRESULT;
begin
  if GetInterface(IID, Obj) then
    Exit(S_OK);
  if FInner <> nil then
    Exit(FInner.QueryInterface(IID, Obj));
  Pointer(Obj) := nil;
  Result := E_NOINTERFACE;
end;

procedure TWinUIControlHost.GetIids(out AIidCount: Cardinal; out AIids: PGUID);
begin
  FInner.GetIids(AIidCount, AIids);
end;

function TWinUIControlHost.GetRuntimeClassName: HSTRING;
begin
  if FType = nil then
    Result := NewHString(ContentControl.RuntimeClassName)
  else
    Result := NewHString(FType.FullName);
end;

function TWinUIControlHost.GetTrustLevel: TrustLevel;
begin
  Result := FInner.GetTrustLevel;
end;

function TWinUIControlHost.PascalObject: TWinUIObject;
begin
  Result := FControl;
end;

{ TWinUICustomControl }

class procedure TWinUICustomControl.DefineType(AType: TWinUICustomType);
begin
end;

constructor TWinUICustomControl.Create(AOwner: TWinUIObject);
var
  CustomType: TWinUICustomType;
  Host: TWinUIControlHost;
begin
  CustomType := TWinUICustomControls.FindClass(ClassType);
  if CustomType = nil then
    raise EInvalidOpException.CreateFmt('%s is not registered with TWinUICustomControls.Register', [ClassName]);
  Host := TWinUIControlHost.Create(CustomType);
  // Created from Pascal: this object keeps the host alive, its owner frees it
  FHostRef := Host as IInspectable;
  inherited CreateFrom(AOwner, Host.FInner);
  Attach(Host);
end;

constructor TWinUICustomControl.CreateHosted(AHost: TObject);
begin
  inherited CreateFrom(nil, TWinUIControlHost(AHost).FInner);
  TWinUIControlHost(AHost).FOwnsControl := True;
  Attach(AHost);
end;

procedure TWinUICustomControl.Attach(AHost: TObject);
begin
  FHost := AHost;
  TWinUIControlHost(AHost).FControl := Self;
  SetLength(FEvents, Length(CustomType.Events));
  SetLength(FHandlers, Length(CustomType.Events));
  Initialize;
  FInitialized := True;
end;

destructor TWinUICustomControl.Destroy;
begin
  if (FHost <> nil) and (TWinUIControlHost(FHost).FControl = Self) then
    TWinUIControlHost(FHost).FControl := nil;
  // FHostRef is released after the inherited destructor has let go of the
  // inner object, when the fields are finalized.
  inherited;
end;

procedure TWinUICustomControl.Initialize;
begin
end;

procedure TWinUICustomControl.PropertyChanged(AIndex: Integer);
begin
end;

procedure TWinUICustomControl.HostPropertyChanged(AIndex: Integer);
begin
  if FInitialized then
    PropertyChanged(AIndex);
end;

function TWinUICustomControl.CustomType: TWinUICustomType;
begin
  Result := TWinUIControlHost(FHost).FType;
end;

function TWinUICustomControl.GetPropValue(AIndex: Integer): IInspectable;
begin
  Result := (IntfOf(Self, IDependencyObject) as IDependencyObject).GetValue(CustomType.Properties[AIndex].Prop);
end;

procedure TWinUICustomControl.SetPropValue(AIndex: Integer; const AValue: IInspectable);
begin
  (IntfOf(Self, IDependencyObject) as IDependencyObject).SetValue(CustomType.Properties[AIndex].Prop, AValue);
end;

function TWinUICustomControl.GetBoolean(AIndex: Integer): Boolean;
var
  PV: IPropertyValue;
begin
  Result := Supports(GetPropValue(AIndex), IPropertyValue, PV) and (PV.&Type = PropertyType.Boolean) and
    PV.GetBoolean;
end;

procedure TWinUICustomControl.SetBoolean(AIndex: Integer; AValue: Boolean);
begin
  SetPropValue(AIndex, PropertyValue.CreateBoolean(AValue));
end;

function TWinUICustomControl.GetInt32(AIndex: Integer): Integer;
begin
  Result := Round(UnboxDouble(GetPropValue(AIndex)));
end;

procedure TWinUICustomControl.SetInt32(AIndex: Integer; AValue: Integer);
begin
  SetPropValue(AIndex, PropertyValue.CreateInt32(AValue));
end;

function TWinUICustomControl.GetDouble(AIndex: Integer): Double;
begin
  Result := UnboxDouble(GetPropValue(AIndex));
end;

procedure TWinUICustomControl.SetDouble(AIndex: Integer; AValue: Double);
begin
  SetPropValue(AIndex, PropertyValue.CreateDouble(AValue));
end;

function TWinUICustomControl.GetText(AIndex: Integer): string;
var
  Value: TWinValue;
begin
  Value := GetPropValue(AIndex);
  Result := Value.AsString;
end;

procedure TWinUICustomControl.SetText(AIndex: Integer; const AValue: string);
begin
  SetPropValue(AIndex, PropertyValue.CreateString(WinStr(AValue)));
end;

function TWinUICustomControl.GetBrush(AIndex: Integer): TWinUIBrush;
begin
  Result := TWinUIBrush(TWinUIObject.Wrap(Self, GetPropValue(AIndex), TWinUIBrush));
end;

procedure TWinUICustomControl.SetBrush(AIndex: Integer; AValue: TWinUIBrush);
begin
  SetPropValue(AIndex, IInspectable(IntfOf(AValue, IInspectable)));
end;

function TWinUICustomControl.GetEvent(AIndex: Integer): TWinUIEvent<TWinValue>;
begin
  if FEvents[AIndex] = nil then
  begin
    FEvents[AIndex] := TWinUIEvent<TWinValue>.Create;
    AddHelper(FEvents[AIndex]);
  end;
  Result := FEvents[AIndex];
end;

function TWinUICustomControl.EventByName(const AName: string): TWinUIEvent<TWinValue>;
var
  I: Integer;
begin
  for I := 0 to High(CustomType.Events) do
    if SameText(CustomType.Events[I], AName) then
      Exit(GetEvent(I));
  raise EArgumentException.CreateFmt('%s has no event %s', [ClassName, AName]);
end;

{ TWinUICustomControl: accessibility }

function TWinUICustomControl.AutomationRole: AutomationControlType;
begin
  Result := AutomationControlType.Custom;
end;

function TWinUICustomControl.AutomationPatterns: TWinUIAutomationPatterns;
begin
  Result := [];
end;

function TWinUICustomControl.AutomationName: string;
begin
  Result := '';
end;

procedure TWinUICustomControl.AutomationInvoke;
begin
end;

function TWinUICustomControl.AutomationToggleState: ToggleState;
begin
  Result := ToggleState.Off;
end;

procedure TWinUICustomControl.AutomationToggle;
begin
end;

function TWinUICustomControl.AutomationExpanded: Boolean;
begin
  Result := False;
end;

procedure TWinUICustomControl.AutomationExpand(AExpand: Boolean);
begin
end;

function TWinUICustomControl.AutomationItemCount: Integer;
begin
  Result := 0;
end;

function TWinUICustomControl.AutomationItemName(AIndex: Integer): string;
begin
  Result := '';
end;

function TWinUICustomControl.AutomationItemSpan(AIndex: Integer; out ALeft, AWidth: Double): Boolean;
begin
  ALeft := 0;
  AWidth := 0;
  Result := False;
end;

function TWinUICustomControl.AutomationSelectedIndex: Integer;
begin
  Result := -1;
end;

procedure TWinUICustomControl.AutomationSelect(AIndex: Integer);
begin
end;

procedure TWinUICustomControl.AutomationChanged(APattern: TWinUIAutomationPattern);
var
  Peer: IAutomationPeer;
  Value: IInspectable;
begin
  // Only when a screen reader or another client asked for the peer
  if (FHost = nil) or (TWinUIControlHost(FHost).FPeer = nil) then
    Exit;
  Peer := TControlPeer(TWinUIControlHost(FHost).FPeer).Peer;
  case APattern of
    TWinUIAutomationPattern.Toggle:
      begin
        Value := PropertyValue.CreateInt32(Ord(AutomationToggleState));
        Peer.RaisePropertyChangedEvent(TogglePatternIdentifiers.ToggleStateProperty, Value, Value);
      end;
    TWinUIAutomationPattern.ExpandCollapse:
      begin
        Value := PropertyValue.CreateInt32(Ord(AutomationExpanded));
        Peer.RaisePropertyChangedEvent(ExpandCollapsePatternIdentifiers.ExpandCollapseStateProperty, Value, Value);
      end;
    TWinUIAutomationPattern.Selection:
      TControlPeer(TWinUIControlHost(FHost).FPeer).SelectionChanged;
  end;
end;

procedure TWinUICustomControl.AutomationNameChanged;
var
  Value: IInspectable;
begin
  if (FHost = nil) or (TWinUIControlHost(FHost).FPeer = nil) then
    Exit;
  Value := PropertyValue.CreateString(WinStr(AutomationName));
  TControlPeer(TWinUIControlHost(FHost).FPeer).Peer.RaisePropertyChangedEvent(AutomationElementIdentifiers.NameProperty,
    Value, Value);
end;

function TWinUICustomControl.OwnerWindow: TObject;
var
  Next: TWinUIObject;
begin
  Result := nil;
  if FHost <> nil then
    Result := TWinUIControlHost(FHost).FOwnerWindow;
  if Result = nil then
  begin
    Next := Owner;
    while Next <> nil do
    begin
      Result := Next;
      Next := Next.Owner;
    end;
  end;
end;

function TWinUICustomControl.GetHandler(AIndex: Integer): TWinUIWinValueEventHandler;
begin
  Result := FHandlers[AIndex];
end;

procedure TWinUICustomControl.SetHandler(AIndex: Integer; const AValue: TWinUIWinValueEventHandler);
begin
  FHandlers[AIndex] := AValue;
end;

procedure TWinUICustomControl.Fire(AIndex: Integer);
var
  Empty: TWinValue;
begin
  Empty := IInspectable(nil);
  try
    if Assigned(FHandlers[AIndex]) then
      FHandlers[AIndex](Self, Empty);
    if FEvents[AIndex] <> nil then
      FEvents[AIndex].Invoke(Self, Empty);
  except
    on E: Exception do
      if Assigned(WinRTHandleException) then
        WinRTHandleException(E)
      else
        raise;
  end;
end;

procedure TWinUICustomControl.UseTemplate(const AXaml: string);
var
  I: Integer;
  Template: IInspectable;
begin
  Template := nil;
  for I := 0 to High(TemplateClasses) do
    if TemplateClasses[I] = ClassType then
      Template := Templates[I];
  if Template = nil then
  begin
    Template := XamlReader.Load(WinStr(AXaml));
    TemplateClasses := TemplateClasses + [ClassType];
    Templates := Templates + [Template];
  end;
  (IntfOf(Self, IControl) as IControl).Template := Template as IControlTemplate;
end;

function TWinUICustomControl.TemplatePart(const AName: string): IDependencyObject;
begin
  Result := (IntfOf(Self, IControlProtected) as IControlProtected).GetTemplateChild(WinStr(AName));
end;

{ TXamlInfoObject }

procedure TXamlInfoObject.GetIids(out AIidCount: Cardinal; out AIids: PGUID);
begin
  AIidCount := 0;
  AIids := nil;
end;

function TXamlInfoObject.GetRuntimeClassName: HSTRING;
begin
  Result := NewHString(ClassName);
end;

function TXamlInfoObject.GetTrustLevel: TrustLevel;
begin
  Result := 0;
end;

{ TCustomXamlType }

constructor TCustomXamlType.Create(AType: TWinUICustomType);
begin
  inherited Create;
  FType := AType;
  SetLength(FMembers, AType.PropertyCount);
end;

function TCustomXamlType.Base: IXamlType;
begin
  Result := BaseXamlType(ContentControl.RuntimeClassName);
end;

function TCustomXamlType.get_BaseType: IXamlType;
begin
  Result := Base;
end;

function TCustomXamlType.get_ContentProperty: IXamlMember;
begin
  Result := Base.ContentProperty;
end;

function TCustomXamlType.get_FullName: HSTRING;
begin
  Result := NewHString(FType.FullName);
end;

function TCustomXamlType.get_IsArray: Boolean;
begin
  Result := False;
end;

function TCustomXamlType.get_IsCollection: Boolean;
begin
  Result := False;
end;

function TCustomXamlType.get_IsConstructible: Boolean;
begin
  Result := True;
end;

function TCustomXamlType.get_IsDictionary: Boolean;
begin
  Result := False;
end;

function TCustomXamlType.get_IsMarkupExtension: Boolean;
begin
  Result := False;
end;

function TCustomXamlType.get_IsBindable: Boolean;
begin
  Result := False;
end;

function TCustomXamlType.get_ItemType: IXamlType;
begin
  Result := nil;
end;

function TCustomXamlType.get_KeyType: IXamlType;
begin
  Result := nil;
end;

function TCustomXamlType.get_BoxedType: IXamlType;
begin
  Result := nil;
end;

function TCustomXamlType.get_UnderlyingType: TypeName;
begin
  Result.&Name := NewHString(FType.FullName);
  Result.Kind := TypeKind.Custom;
end;

function TCustomXamlType.ActivateInstance: IInspectable;
var
  Host: TWinUIControlHost;
begin
  Host := TWinUIControlHost.Create(FType);
  Result := Host as IInspectable; // XAML holds the host, the host owns the control
  Host.FOwnerWindow := CustomXamlLoadOwner;
  FType.ControlClass.CreateHosted(Host);
end;

function TCustomXamlType.CreateFromString(AValue: HSTRING): IInspectable;
begin
  raise ENotSupportedException.CreateFmt('%s cannot be created from text', [FType.FullName]);
end;

function TCustomXamlType.GetMember(AName: HSTRING): IXamlMember;
var
  Index: Integer;
begin
  Index := FType.IndexOf(HStringToString(AName));
  if Index < 0 then
    Exit(Base.GetMember(AName));
  if FMembers[Index] = nil then
    FMembers[Index] := TCustomXamlMember.Create(FType, Index);
  Result := FMembers[Index];
end;

procedure TCustomXamlType.AddToVector(AInstance, AValue: IInspectable);
begin
  raise ENotSupportedException.Create('not a collection');
end;

procedure TCustomXamlType.AddToMap(AInstance, AKey, AValue: IInspectable);
begin
  raise ENotSupportedException.Create('not a dictionary');
end;

procedure TCustomXamlType.RunInitializer;
begin
  FType.EnsureRegistered;
end;

{ TCustomXamlMember }

constructor TCustomXamlMember.Create(AOwner: TWinUICustomType; AIndex: Integer);
begin
  inherited Create;
  FOwner := AOwner;
  FIndex := AIndex;
end;

function TCustomXamlMember.get_IsAttachable: Boolean;
begin
  Result := False;
end;

function TCustomXamlMember.get_IsDependencyProperty: Boolean;
begin
  Result := True;
end;

function TCustomXamlMember.get_IsReadOnly: Boolean;
begin
  Result := False;
end;

function TCustomXamlMember.get_Name: HSTRING;
begin
  Result := NewHString(FOwner.Properties[FIndex].Name);
end;

function TCustomXamlMember.get_TargetType: IXamlType;
begin
  Result := FOwner.XamlType;
end;

function TCustomXamlMember.get_Type: IXamlType;
begin
  Result := MemberXamlType(FOwner.Properties[FIndex]);
end;

function TCustomXamlMember.GetValue(AInstance: IInspectable): IInspectable;
begin
  Result := (AInstance as IDependencyObject).GetValue(FOwner.Properties[FIndex].Prop);
end;

procedure TCustomXamlMember.SetValue(AInstance, AValue: IInspectable);
var
  Value: IInspectable;
  Prop: TWinUICustomProperty;
  PV: IPropertyValue;
  Text: string;
  Index: Integer;
begin
  Value := AValue;
  Prop := FOwner.Properties[FIndex];
  if Prop.Kind = TWinUIPropertyKind.Int32 then
    // XAML hands Double attributes of Int32 properties over as Double
    Value := PropertyValue.CreateInt32(Round(UnboxDouble(AValue)))
  else if (Prop.Kind = TWinUIPropertyKind.Enum) and Supports(AValue, IPropertyValue, PV) and
    (PV.&Type = PropertyType.&String) then
  begin
    Text := TakeHString(PV.GetString).Trim;
    Index := GetEnumValue(Prop.EnumType, Text);
    if Index < 0 then
      raise EArgumentException.CreateFmt('%s.%s: "%s" is not one of %s', [FOwner.XamlName, Prop.Name, Text,
        EnumNames(Prop.EnumType)]);
    Value := PropertyValue.CreateInt32(Index);
  end;
  (AInstance as IDependencyObject).SetValue(FOwner.Properties[FIndex].Prop, Value);
end;

{ TSimpleXamlType }

constructor TSimpleXamlType.Create(const AFullName: string; AKind: TypeKind);
begin
  inherited Create;
  FFullName := AFullName;
  FKind := AKind;
end;

function TSimpleXamlType.get_BaseType: IXamlType;
begin
  Result := nil;
end;

function TSimpleXamlType.get_ContentProperty: IXamlMember;
begin
  Result := nil;
end;

function TSimpleXamlType.get_FullName: HSTRING;
begin
  Result := NewHString(FFullName);
end;

function TSimpleXamlType.get_IsArray: Boolean;
begin
  Result := False;
end;

function TSimpleXamlType.get_IsCollection: Boolean;
begin
  Result := False;
end;

function TSimpleXamlType.get_IsConstructible: Boolean;
begin
  Result := False;
end;

function TSimpleXamlType.get_IsDictionary: Boolean;
begin
  Result := False;
end;

function TSimpleXamlType.get_IsMarkupExtension: Boolean;
begin
  Result := False;
end;

function TSimpleXamlType.get_IsBindable: Boolean;
begin
  Result := False;
end;

function TSimpleXamlType.get_ItemType: IXamlType;
begin
  Result := nil;
end;

function TSimpleXamlType.get_KeyType: IXamlType;
begin
  Result := nil;
end;

function TSimpleXamlType.get_BoxedType: IXamlType;
begin
  Result := nil;
end;

function TSimpleXamlType.get_UnderlyingType: TypeName;
begin
  Result.&Name := NewHString(FFullName);
  Result.Kind := FKind;
end;

function TSimpleXamlType.ActivateInstance: IInspectable;
begin
  raise ENotSupportedException.CreateFmt('%s cannot be created', [FFullName]);
end;

function TSimpleXamlType.CreateFromString(AValue: HSTRING): IInspectable;
begin
  raise ENotSupportedException.CreateFmt('%s is converted by XAML itself', [FFullName]);
end;

function TSimpleXamlType.GetMember(AName: HSTRING): IXamlMember;
begin
  Result := nil;
end;

procedure TSimpleXamlType.AddToVector(AInstance, AValue: IInspectable);
begin
  raise ENotSupportedException.Create('not a collection');
end;

procedure TSimpleXamlType.AddToMap(AInstance, AKey, AValue: IInspectable);
begin
  raise ENotSupportedException.Create('not a dictionary');
end;

procedure TSimpleXamlType.RunInitializer;
begin
end;

{ TPlaceholderXamlType }

constructor TPlaceholderXamlType.Create(const AFullName: string);
begin
  inherited Create;
  FFullName := AFullName;
  FBase := BaseXamlType('Microsoft.UI.Xaml.Controls.ContentControl');
end;

function TPlaceholderXamlType.get_BaseType: IXamlType;
begin
  Result := FBase;
end;

function TPlaceholderXamlType.get_ContentProperty: IXamlMember;
begin
  Result := nil;
end;

function TPlaceholderXamlType.get_FullName: HSTRING;
begin
  Result := NewHString(FFullName);
end;

function TPlaceholderXamlType.get_IsArray: Boolean;
begin
  Result := False;
end;

function TPlaceholderXamlType.get_IsCollection: Boolean;
begin
  Result := False;
end;

function TPlaceholderXamlType.get_IsConstructible: Boolean;
begin
  Result := True;
end;

function TPlaceholderXamlType.get_IsDictionary: Boolean;
begin
  Result := False;
end;

function TPlaceholderXamlType.get_IsMarkupExtension: Boolean;
begin
  Result := False;
end;

function TPlaceholderXamlType.get_IsBindable: Boolean;
begin
  Result := False;
end;

function TPlaceholderXamlType.get_ItemType: IXamlType;
begin
  Result := nil;
end;

function TPlaceholderXamlType.get_KeyType: IXamlType;
begin
  Result := nil;
end;

function TPlaceholderXamlType.get_BoxedType: IXamlType;
begin
  Result := nil;
end;

function TPlaceholderXamlType.get_UnderlyingType: TypeName;
begin
  Result.&Name := NewHString(FFullName);
  Result.Kind := TypeKind.Custom;
end;

function TPlaceholderXamlType.ActivateInstance: IInspectable;
begin
  // A ContentControl, as the user control is one, holding a labelled frame
  Result := XamlReader.Load(WinStr(
    '<ContentControl xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" IsTabStop="False" ' +
    'HorizontalContentAlignment="Stretch" VerticalContentAlignment="Stretch">' +
    '<Border BorderThickness="1" BorderBrush="{ThemeResource ControlStrongStrokeColorDefaultBrush}" CornerRadius="4" ' +
    'Padding="12,8" MinHeight="36"><TextBlock Opacity="0.7" Text="' + FFullName.Substring(FFullName.LastIndexOf('.') + 1) +
    '"/></Border></ContentControl>'));
end;

function TPlaceholderXamlType.CreateFromString(AValue: HSTRING): IInspectable;
begin
  raise ENotSupportedException.Create('a placeholder has no text form');
end;

function TPlaceholderXamlType.GetMember(AName: HSTRING): IXamlMember;
begin
  Result := nil;
  if FBase <> nil then
    Result := FBase.GetMember(AName);
  if Result = nil then
    Result := TPlaceholderXamlMember.Create(Self, HStringToString(AName));
end;

procedure TPlaceholderXamlType.AddToVector(AInstance, AValue: IInspectable);
begin
end;

procedure TPlaceholderXamlType.AddToMap(AInstance, AKey, AValue: IInspectable);
begin
end;

procedure TPlaceholderXamlType.RunInitializer;
begin
end;

{ TPlaceholderXamlMember }

constructor TPlaceholderXamlMember.Create(const AOwner: IXamlType; const AName: string);
begin
  inherited Create;
  FOwner := AOwner;
  FName := AName;
end;

function TPlaceholderXamlMember.get_IsAttachable: Boolean;
begin
  Result := False;
end;

function TPlaceholderXamlMember.get_IsDependencyProperty: Boolean;
begin
  Result := False;
end;

function TPlaceholderXamlMember.get_IsReadOnly: Boolean;
begin
  Result := False;
end;

function TPlaceholderXamlMember.get_Name: HSTRING;
begin
  Result := NewHString(FName);
end;

function TPlaceholderXamlMember.get_TargetType: IXamlType;
begin
  Result := FOwner;
end;

function TPlaceholderXamlMember.get_Type: IXamlType;
begin
  Result := TSimpleXamlType.Create('String', TypeKind.Primitive);
end;

function TPlaceholderXamlMember.GetValue(AInstance: IInspectable): IInspectable;
begin
  Result := nil;
end;

procedure TPlaceholderXamlMember.SetValue(AInstance, AValue: IInspectable);
begin
end;

{ TWinUIXamlUserControl }
procedure TWinUIXamlUserControl.Initialize;
begin
  inherited;
  // Like WinUI's UserControl: the content fills the control, which takes no focus itself
  HorizontalContentAlignment := TWinUIHorizontalAlignment.Stretch;
  VerticalContentAlignment := TWinUIVerticalAlignment.Stretch;
  IsTabStop := False;
end;

procedure TWinUIXamlUserControl.LoadContentXaml(const AXaml: string);
begin
  // Controls in this XAML belong to the window that loads the user control
  Content := XamlReader.Load(WinStr(AXaml));
end;

function TWinUIXamlUserControl.FindElement<T>(const AName: string): T;
var
  Root: IFrameworkElement;
begin
  if not Supports(Content.Obj, IFrameworkElement, Root) then
    Exit(nil);
  Result := T(TWinUIObject.Wrap(Self, Root.FindName(WinStr(AName)),
    TWinUIObjectClass(GetTypeData(TypeInfo(T))^.ClassType)));
end;

function TWinUIXamlUserControl.PublishedMethod(const AName: string): TMethod;
begin
  Result.Code := MethodAddress(AName);
  Result.Data := Self;
  if Result.Code = nil then
    raise EInvalidOpException.CreateFmt('%s has no published method %s for its XAML events', [ClassName, AName]);
end;

function TWinUIXamlUserControl.NotifyProc<T>(const AName: string): TWinUIEventProc<T>;
var
  Method: TMethod;
begin
  Method := PublishedMethod(AName);
  Result :=
    procedure(Sender: TObject; E: T)
    var
      Handler: procedure(Sender: TObject) of object;
    begin
      TMethod(Handler) := Method;
      Handler(Sender);
    end;
end;

{ TWinUICustomControls }

class procedure TWinUICustomControls.Register(AClass: TWinUICustomControlClass; const AXamlName, ACategory: string);
var
  CustomType: TWinUICustomType;
begin
  if FindClass(AClass) <> nil then
    Exit;
  CustomType := TWinUICustomType.Create(AClass, AXamlName, ACategory);
  AClass.DefineType(CustomType);
  Registry := Registry + [CustomType];
end;

class function TWinUICustomControls.Find(const AFullName: string): TWinUICustomType;
begin
  for Result in Registry do
    if Result.FullName = AFullName then
      Exit;
  Result := nil;
end;

class function TWinUICustomControls.FindClass(AClass: TClass): TWinUICustomType;
begin
  for Result in Registry do
    if Result.ControlClass = AClass then
      Exit;
  Result := nil;
end;

class function TWinUICustomControls.Types: TArray<TWinUICustomType>;
begin
  Result := Copy(Registry);
end;

class function TWinUICustomControls.LiveCount: Integer;
var
  Host: TWinUIControlHost;
begin
  Result := 0;
  for Host in Hosts do
    if Host.FControl <> nil then
      Inc(Result);
end;

class function TWinUICustomControls.HostCount: Integer;
begin
  Result := Length(Hosts);
end;

function JsonText(const AValue: string): string;
begin
  Result := '"' + AValue.Replace('\', '\\').Replace('"', '\"') + '"';
end;

function KindText(const AProp: TWinUICustomProperty): string;
begin
  if AProp.Editor <> '' then
    Exit(AProp.Editor);
  case AProp.Kind of
    TWinUIPropertyKind.Boolean: Result := 'bool';
    TWinUIPropertyKind.Int32: Result := 'int';
    TWinUIPropertyKind.Double: Result := 'number';
    TWinUIPropertyKind.Text: Result := 'string';
    TWinUIPropertyKind.Brush: Result := 'brush';
    TWinUIPropertyKind.Value: Result := 'object';
  else
    Result := 'enum:' + EnumNames(AProp.EnumType);
  end;
end;

class function TWinUICustomControls.TypeIndexJson: string;
var
  CustomType: TWinUICustomType;
  Lines, Props, Events, Palette, Names: TArray<string>;
  I: Integer;
  Event: string;
begin
  // Same shape as RADWinUI.Xaml.json, sorted by name, plus "default" values and "unit"
  Lines := nil;
  Palette := nil;
  Names := nil;
  for CustomType in Registry do
  begin
    Props := nil;
    for I := 0 to CustomType.PropertyCount - 1 do
      Props := Props + [JsonText(CustomType.Properties[I].Name) + ': ' + JsonText(KindText(CustomType.Properties[I]))];
    Events := nil;
    for Event in CustomType.Events do
      Events := Events + [JsonText(Event) + ': ["TWinUIWinValueEventHandler", "TWinValue"]'];
    Lines := Lines + [JsonText(CustomType.FullName) + ': {' + sLineBreak +
      '"base": "Microsoft.UI.Xaml.Controls.ContentControl",' + sLineBreak +
      '"events": {' + string.Join(', ', Events) + '},' + sLineBreak +
      '"props": {' + string.Join(', ', Props) + '},' + sLineBreak +
      '"unit": ' + JsonText(CustomType.ControlClass.UnitName) + ',' + sLineBreak +
      '"wrapper": ' + JsonText(CustomType.ControlClass.ClassName) + sLineBreak + '}'];
    Palette := Palette + ['{"category": ' + JsonText(CustomType.Category) + ', "name": ' +
      JsonText(CustomType.XamlName) + ', "runtime": ' + JsonText(CustomType.FullName) + '}'];
    Names := Names + [JsonText(CustomType.XamlName) + ': ' + JsonText(CustomType.FullName)];
  end;
  Result := '{' + sLineBreak +
    '"classes": {' + sLineBreak + string.Join(',' + sLineBreak, Lines) + sLineBreak + '},' + sLineBreak +
    '"namespace": ' + JsonText('using:' + CustomControlsNamespace) + ',' + sLineBreak +
    '"palette": [' + sLineBreak + string.Join(',' + sLineBreak, Palette) + sLineBreak + '],' + sLineBreak +
    '"types": {' + sLineBreak + string.Join(',' + sLineBreak, Names) + sLineBreak + '}' + sLineBreak +
    '}' + sLineBreak;
end;

function ResolveCustomType(const AFullName: string): IXamlType;
var
  CustomType, Candidate: TWinUICustomType;
  I: Integer;
begin
  CustomType := TWinUICustomControls.Find(AFullName);
  // A user control answers to its name in any app namespace (using:MyApp), never in WinUI's own
  if (CustomType = nil) and (AFullName.LastIndexOf('.') > 0) and not AFullName.StartsWith('Microsoft.') and
    not AFullName.StartsWith('Windows.') then
    for Candidate in TWinUICustomControls.Types do
      if Candidate.ControlClass.InheritsFrom(TWinUIXamlUserControl) and
        (Candidate.XamlName = AFullName.Substring(AFullName.LastIndexOf('.') + 1)) then
      begin
        CustomType := Candidate;
        Break;
      end;
  if (CustomType = nil) and CustomXamlDesignTime and (AFullName.LastIndexOf('.') > 0) and
    not AFullName.StartsWith('Microsoft.') and not AFullName.StartsWith('Windows.') and
    not AFullName.StartsWith(CustomControlsNamespace + '.') then
  begin
    // The designer has no user controls of the app: they show as placeholders
    for I := 0 to High(PlaceholderNames) do
      if PlaceholderNames[I] = AFullName then
        Exit(Placeholders[I]);
    Result := TPlaceholderXamlType.Create(AFullName);
    Placeholders := Placeholders + [Result];
    PlaceholderNames := PlaceholderNames + [AFullName];
    Exit;
  end;
  if CustomType = nil then
    Exit(nil);
  CustomType.EnsureRegistered;
  Result := CustomType.XamlType;
end;

procedure ReleaseCustomTypes;
var
  CustomType: TWinUICustomType;
  Host: TWinUIControlHost;
begin
  // Controls of windows that never closed, and those XAML created elsewhere
  ReleaseHostedControls(nil);
  // A host XAML still holds after this is XAML's: it stays, without its type
  for Host in Hosts do
  begin
    Host.FType := nil;
    RegisterExpectedMemoryLeak(Host);
  end;
  // WinRT references go before RoUninitialize, the type descriptions stay
  for CustomType in Registry do
    CustomType.Free;
  Registry := nil;
  Templates := nil;
  TemplateClasses := nil;
  Placeholders := nil;
  PlaceholderNames := nil;
  ControlsProvider := nil;
  ContentControlFactoryCache := nil;
end;

initialization
  CustomXamlTypeResolver := ResolveCustomType;
  CustomXamlTypesRelease := ReleaseCustomTypes;
  CustomXamlOwnerGone := ReleaseHostedControls;
end.
