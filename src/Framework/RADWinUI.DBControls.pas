unit RADWinUI.DBControls;

{
  Data-aware controls, on the Tool Palette's Data Controls category. They
  work like VCL's TDBEdit, TDBGrid and friends: each one shows a field of
  the current record of a TDataSource and writes the user's changes back.

    <rw:DBNavigator DataSource="CustomersSource"/>
    <rw:DBGrid DataSource="CustomersSource" Height="300"/>
    <rw:DBEdit DataSource="CustomersSource" DataField="CompanyName" Header="Company"/>

  DataSource names a TDataSource. It is looked for, in this order, among the
  published fields and properties of the window, and among the components of
  every data module the program has created. "Module.Source" picks the data
  module. In Pascal, DataSource takes the TDataSource itself, like the VCL:

    CompanyEdit.DataSource := Customers.CustomersSource;

  Behind each control is a TWinUIFieldLink or a TDataLink of Data.DB, so the
  dataset sees the same calls as from VCL controls: typing puts it into
  Edit, leaving the control or pressing Enter writes the field, Esc puts the
  field's value back. The dataset and WinUI both live on the UI thread.

  The XAML designer has no data: there the controls show their field names.

  Using this unit registers the controls.
}

interface

{$SCOPEDENUMS ON}

uses
  System.SysUtils,
  System.Classes,
  Data.DB,
  RADWinUI.Interop.Core,
  RADWinUI.Abi,
  RADWinUI.Framework,
  RADWinUI.Xaml,
  RADWinUI.Binding,
  RADWinUI.CustomControls;

const
  /// <summary>The Tool Palette category of the data controls.</summary>
  DataControlsCategory = 'Data Controls';

type
  /// <summary>Finds a TDataSource by the name XAML gives it.</summary>
  TWinUIDataSources = class
  public
    /// <summary>
    ///   The TDataSource called AName ("Source" or "Module.Source"): a published
    ///   field or property of AContext (the window), then a component of a data
    ///   module. nil when there is none.
    /// </summary>
    class function Find(AContext: TObject; const AName: string): TDataSource; static;
    /// <summary>
    ///   Lets Find look into AModule. Data modules (TDataModule) are added and
    ///   removed by themselves, this is for other owners of data components.
    /// </summary>
    class procedure AddModule(AModule: TComponent); static;
    class procedure RemoveModule(AModule: TComponent); static;
    /// <summary>The data modules Find looks into, oldest first.</summary>
    class function Modules: TArray<TComponent>; static;
  end;

  /// <summary>
  ///   The base of the data controls: the DataSource property. Not registered
  ///   itself.
  /// </summary>
  TWinUIDataAwareControl = class(TWinUICustomControl)
  strict private
    FSource: TDataSource;
    FWatcher: TComponent;
    function GetDataSource: TDataSource;
    procedure SetDataSource(AValue: TDataSource);
    procedure SourceFreed(AComponent: TComponent);
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    /// <summary>The link to the data source, made by the descendant in Initialize, before inherited.</summary>
    function Link: TDataLink; virtual; abstract;
    /// <summary>The link has a new data source, or lost it.</summary>
    procedure SourceChanged; virtual;
    /// <summary>Finds the data source DataSource names, and links to it.</summary>
    procedure ResolveSource;
    /// <summary>A TDataSource another property names (a lookup's ListSource).</summary>
    function FindSource(const AName: string): TDataSource;
    /// <summary>True in the XAML designer, where there is no data.</summary>
    function DesignTime: Boolean;
    /// <summary>The x:Name of the control, '' when it has none.</summary>
    function ElementName: string;
    /// <summary>Reports an exception of the dataset (a validation, a key violation) like other errors.</summary>
    procedure HandleError(E: Exception);
  public
    destructor Destroy; override;
    /// <summary>The dataset of the data source, nil when there is none.</summary>
    function DataSet: TDataSet;
    /// <summary>The TDataSource, as the VCL's DataSource property. Setting it wins over the XAML name.</summary>
    property DataSource: TDataSource read GetDataSource write SetDataSource;
  published
    /// <summary>The name of the data source, the DataSource attribute of XAML.</summary>
    property DataSourceName: string index 0 read GetText write SetText;
  end;

  /// <summary>
  ///   The link of a control to one field of a data source, like the VCL's
  ///   TFieldDataLink (which lives in a VCL unit).
  /// </summary>
  TWinUIFieldLink = class(TDataLink)
  strict private
    FField: TField;
    FFieldName: string;
    FModified: Boolean;
    FOnDataChange: TNotifyEvent;
    FOnEditingChange: TNotifyEvent;
    FOnUpdateData: TNotifyEvent;
    FOnActiveChange: TNotifyEvent;
    procedure SetFieldName(const AValue: string);
    procedure SetField(AValue: TField);
    procedure UpdateField;
    function GetCanModify: Boolean;
  protected
    procedure ActiveChanged; override;
    procedure EditingChanged; override;
    procedure LayoutChanged; override;
    procedure RecordChanged(Field: TField); override;
    procedure UpdateData; override;
  public
    /// <summary>Puts the dataset into Edit when the field can be changed. True when it is editing.</summary>
    function Edit: Boolean; reintroduce;
    /// <summary>The control's value changed: UpdateRecord writes it.</summary>
    procedure Modified;
    /// <summary>Drops the control's change and shows the field again.</summary>
    procedure Reset;
    property CanModify: Boolean read GetCanModify;
    property Field: TField read FField;
    property FieldName: string read FFieldName write SetFieldName;
    property OnDataChange: TNotifyEvent read FOnDataChange write FOnDataChange;
    property OnEditingChange: TNotifyEvent read FOnEditingChange write FOnEditingChange;
    property OnUpdateData: TNotifyEvent read FOnUpdateData write FOnUpdateData;
    property OnActiveChange: TNotifyEvent read FOnActiveChange write FOnActiveChange;
  end;

  /// <summary>
  ///   The base of the controls that show one field: DataField and ReadOnly,
  ///   over a TWinUIFieldLink. Not registered itself.
  /// </summary>
  TWinUIDBFieldControl = class(TWinUIDataAwareControl)
  strict private
    FFieldLink: TWinUIFieldLink;
    FStarting: Integer;
    procedure LinkDataChange(Sender: TObject);
    procedure LinkEditingChange(Sender: TObject);
    procedure LinkUpdateData(Sender: TObject);
    procedure LinkActiveChange(Sender: TObject);
  protected
    /// <summary>Above 0 while the control shows the field's value, so its change events are not edits.</summary>
    FShowing: Integer;
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    function Link: TDataLink; override;
    procedure SourceChanged; override;
    /// <summary>Shows Field's value (Field may be nil). Called with FShowing above 0.</summary>
    procedure ShowField; virtual; abstract;
    /// <summary>Writes the control's value into Field, when the record is updated.</summary>
    procedure WriteField; virtual; abstract;
    /// <summary>ReadOnly, or what the dataset allows, changed.</summary>
    procedure UpdateEditable; virtual;
    /// <summary>Shows the field again.</summary>
    procedure Refresh;
    /// <summary>The user can change the value.</summary>
    function Editable: Boolean;
    /// <summary>
    ///   The user changed the value: puts the dataset into Edit. False when
    ///   it cannot be edited, the field's value is then shown again.
    /// </summary>
    function StartEdit: Boolean;
    /// <summary>Writes the changed value into the field (WriteField).</summary>
    procedure Commit;
    /// <summary>Drops the user's change and shows the field's value.</summary>
    procedure Revert;
    /// <summary>What the designer shows in place of the value: the field name.</summary>
    function DesignText: string;
    property FieldLink: TWinUIFieldLink read FFieldLink;
  public
    destructor Destroy; override;
    /// <summary>The field the control shows, nil when DataField names none.</summary>
    function Field: TField;
  published
    property DataField: string index 1 read GetText write SetText;
    property ReadOnly: Boolean index 2 read GetBoolean write SetBoolean;
  end;

  /// <summary>Shows a field as text, like TDBText.</summary>
  TWinUIDBText = class(TWinUIDBFieldControl)
  strict private
    FText: TWinUITextBlock;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure ShowField; override;
    procedure WriteField; override;
  public
    property TextBlock: TWinUITextBlock read FText;
  published
    property WordWrap: Boolean index 3 read GetBoolean write SetBoolean;
  end;

  /// <summary>Edits a field in a TextBox, like TDBEdit. Header is its label, like TDBLabeledEdit.</summary>
  TWinUIDBEdit = class(TWinUIDBFieldControl)
  strict private
    FFocused: Boolean;
    FShownText: string;
    procedure ShowText(const AText: string);
    procedure BoxTextChanged;
    procedure BoxKeyDown(E: TWinUIKeyRoutedEventArgs);
  protected
    FBox: TWinUITextBox;
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure ShowField; override;
    procedure WriteField; override;
    procedure UpdateEditable; override;
    /// <summary>Enter writes the field. The memo takes Enter for a new line.</summary>
    function CommitsOnEnter: Boolean; virtual;
  public
    property TextBox: TWinUITextBox read FBox;
  published
    property Header: string index 3 read GetText write SetText;
    property PlaceholderText: string index 4 read GetText write SetText;
  end;

  /// <summary>Edits a long text field on several lines, like TDBMemo.</summary>
  TWinUIDBMemo = class(TWinUIDBEdit)
  protected
    procedure Initialize; override;
    function CommitsOnEnter: Boolean; override;
  end;

  /// <summary>Edits a field with a CheckBox, like TDBCheckBox.</summary>
  TWinUIDBCheckBox = class(TWinUIDBFieldControl)
  strict private
    FCheck: TWinUICheckBox;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure ShowField; override;
    procedure WriteField; override;
    procedure UpdateEditable; override;
  public
    property CheckBox: TWinUICheckBox read FCheck;
  published
    property Text: string index 3 read GetText write SetText;
    /// <summary>The value of a checked box, several separated by ';' ('Yes;Y'), the first is written.</summary>
    property ValueChecked: string index 4 read GetText write SetText;
    property ValueUnchecked: string index 5 read GetText write SetText;
  end;

  /// <summary>Edits a field with a ToggleSwitch, values like TWinUIDBCheckBox.</summary>
  TWinUIDBToggleSwitch = class(TWinUIDBFieldControl)
  strict private
    FSwitch: TWinUIToggleSwitch;
    FShownOn: Boolean;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure ShowField; override;
    procedure WriteField; override;
    procedure UpdateEditable; override;
  public
    property ToggleSwitch: TWinUIToggleSwitch read FSwitch;
  published
    property Header: string index 3 read GetText write SetText;
    property ValueChecked: string index 4 read GetText write SetText;
    property ValueUnchecked: string index 5 read GetText write SetText;
  end;

  /// <summary>
  ///   The base of the controls that pick one value from a list: Values[I] is
  ///   written for the choice I, Texts[I] is shown. Not registered itself.
  /// </summary>
  TWinUIDBChoiceControl = class(TWinUIDBFieldControl)
  protected
    FTexts: TArray<string>;
    FValues: TArray<string>;
    FShownIndex: Integer;
    { The list control }
    procedure ShowChoices; virtual; abstract;
    function ChoiceIndex: Integer; virtual; abstract;
    procedure SelectChoice(AIndex: Integer); virtual; abstract;
    { For the descendants }
    /// <summary>The user picked a choice: writes it into the field.</summary>
    procedure ChoiceMade;
    function IndexOfValue(const AValue: string): Integer;
    function ValueAt(AIndex: Integer): string;
    procedure ShowField; override;
    procedure WriteField; override;
  public
    function ItemCount: Integer;
  end;

  /// <summary>Picks a field's value from Items in a ComboBox, like TDBComboBox.</summary>
  TWinUIDBComboBox = class(TWinUIDBChoiceControl)
  strict private
    FCombo: TWinUIComboBox;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure ShowChoices; override;
    function ChoiceIndex: Integer; override;
    procedure SelectChoice(AIndex: Integer); override;
    procedure ShowField; override;
    procedure WriteField; override;
    procedure UpdateEditable; override;
  public
    property ComboBox: TWinUIComboBox read FCombo;
  published
    /// <summary>The choices, separated by commas.</summary>
    property Items: string index 3 read GetText write SetText;
    property Header: string index 4 read GetText write SetText;
    property PlaceholderText: string index 5 read GetText write SetText;
    /// <summary>The user can also type a value that is not in Items.</summary>
    property IsEditable: Boolean index 6 read GetBoolean write SetBoolean;
  end;

  /// <summary>Picks a field's value from Items in a list, like TDBListBox.</summary>
  TWinUIDBListBox = class(TWinUIDBChoiceControl)
  strict private
    FList: TWinUIListView;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure ShowChoices; override;
    function ChoiceIndex: Integer; override;
    procedure SelectChoice(AIndex: Integer); override;
    procedure UpdateEditable; override;
  public
    property ListView: TWinUIListView read FList;
  published
    property Items: string index 3 read GetText write SetText;
  end;

  /// <summary>Picks a field's value with RadioButtons, like TDBRadioGroup.</summary>
  TWinUIDBRadioGroup = class(TWinUIDBChoiceControl)
  strict private
    FRadio: TWinUIRadioButtons;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure ShowChoices; override;
    function ChoiceIndex: Integer; override;
    procedure SelectChoice(AIndex: Integer); override;
    procedure UpdateEditable; override;
  public
    property RadioButtons: TWinUIRadioButtons read FRadio;
  published
    property Items: string index 3 read GetText write SetText;
    /// <summary>The value written for each item, separated by commas. Without them the item's text is written.</summary>
    property Values: string index 4 read GetText write SetText;
    property Header: string index 5 read GetText write SetText;
    property Columns: Integer index 6 read GetInt32 write SetInt32;
  end;

  /// <summary>
  ///   The base of the lookup controls: the choices are the records of
  ///   ListSource, ListField is shown and KeyField written into DataField.
  ///   Not registered itself.
  /// </summary>
  TWinUIDBLookupControl = class(TWinUIDBChoiceControl)
  strict private
    FListLink: TDataLink;
    FListSource: TDataSource;
    FLoadingList: Boolean;
    function GetListSource: TDataSource;
    procedure SetListSource(AValue: TDataSource);
    procedure ResolveListSource;
  private
    procedure ListChanged;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure SourceChanged; override;
    /// <summary>Reads the choices from the list dataset.</summary>
    procedure LoadList;
  public
    destructor Destroy; override;
    /// <summary>The TDataSource of the choices, as the VCL's ListSource.</summary>
    property ListSource: TDataSource read GetListSource write SetListSource;
  published
    property ListSourceName: string index 3 read GetText write SetText;
    property KeyField: string index 4 read GetText write SetText;
    property ListField: string index 5 read GetText write SetText;
  end;

  /// <summary>A lookup in a ComboBox, like TDBLookupComboBox.</summary>
  TWinUIDBLookupComboBox = class(TWinUIDBLookupControl)
  strict private
    FCombo: TWinUIComboBox;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure ShowChoices; override;
    function ChoiceIndex: Integer; override;
    procedure SelectChoice(AIndex: Integer); override;
    procedure UpdateEditable; override;
  public
    property ComboBox: TWinUIComboBox read FCombo;
  published
    property Header: string index 6 read GetText write SetText;
    property PlaceholderText: string index 7 read GetText write SetText;
  end;

  /// <summary>A lookup in a list, like TDBLookupListBox.</summary>
  TWinUIDBLookupListBox = class(TWinUIDBLookupControl)
  strict private
    FList: TWinUIListView;
  protected
    procedure Initialize; override;
    procedure ShowChoices; override;
    function ChoiceIndex: Integer; override;
    procedure SelectChoice(AIndex: Integer); override;
    procedure UpdateEditable; override;
  public
    property ListView: TWinUIListView read FList;
  end;

  /// <summary>How DBImage fits the picture, the values of WinUI's Stretch.</summary>
  TWinUIDBImageStretch = (None, Fill, Uniform, UniformToFill);

  /// <summary>Shows a picture of a BLOB field (PNG, JPEG, BMP, GIF), like TDBImage.</summary>
  TWinUIDBImage = class(TWinUIDBFieldControl)
  strict private
    FImage: TWinUIImage;
    FPlaceholder: TWinUIFontIcon;
    function GetStretch(AIndex: Integer): TWinUIDBImageStretch;
    procedure SetStretch(AIndex: Integer; AValue: TWinUIDBImageStretch);
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure ShowField; override;
    procedure WriteField; override;
  public
    /// <summary>Puts the picture of the file AFileName into the field.</summary>
    procedure LoadFromFile(const AFileName: string);
    property Image: TWinUIImage read FImage;
  published
    property Stretch: TWinUIDBImageStretch index 3 read GetStretch write SetStretch;
  end;

  /// <summary>Edits formatted text (RTF) of a memo field, like TDBRichEdit.</summary>
  TWinUIDBRichEdit = class(TWinUIDBFieldControl)
  strict private
    FRich: TWinUIRichEditBox;
    FFocused: Boolean;
    FShown: string;
    function Document: ITextDocument;
    function DocumentText: string;
    procedure RichTextChanged;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure ShowField; override;
    procedure WriteField; override;
    procedure UpdateEditable; override;
  public
    property RichEditBox: TWinUIRichEditBox read FRich;
  published
    property Header: string index 3 read GetText write SetText;
    /// <summary>Writes plain text instead of RTF.</summary>
    property PlainText: Boolean index 4 read GetBoolean write SetBoolean;
  end;

  /// <summary>Edits a date field with a CalendarDatePicker.</summary>
  TWinUIDBDatePicker = class(TWinUIDBFieldControl)
  strict private
    FPicker: TWinUICalendarDatePicker;
    FShownDate: Int64;
    function PickedDate: Int64;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure ShowField; override;
    procedure WriteField; override;
    procedure UpdateEditable; override;
  public
    property DatePicker: TWinUICalendarDatePicker read FPicker;
  published
    property Header: string index 3 read GetText write SetText;
    property PlaceholderText: string index 4 read GetText write SetText;
  end;

  /// <summary>Edits a number field with a NumberBox.</summary>
  TWinUIDBNumberBox = class(TWinUIDBFieldControl)
  strict private
    FNumber: TWinUINumberBox;
    FShownValue: Double;
  protected
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure ShowField; override;
    procedure WriteField; override;
    procedure UpdateEditable; override;
  public
    property NumberBox: TWinUINumberBox read FNumber;
  published
    property Header: string index 3 read GetText write SetText;
    property PlaceholderText: string index 4 read GetText write SetText;
    property SpinButtons: Boolean index 5 read GetBoolean write SetBoolean;
  end;

  /// <summary>The buttons of DBNavigator, in their order.</summary>
  TWinUINavigateButton = (First, Prior, Next, Last, Insert, Delete, Edit, Post, Cancel, Refresh);

  /// <summary>Moves through the records and edits them, like TDBNavigator.</summary>
  TWinUIDBNavigator = class(TWinUIDataAwareControl)
  strict private
    FLink: TDataLink;
    FPanel: TWinUIStackPanel;
    FButtons: array[TWinUINavigateButton] of TWinUIButton;
    FConfirm: TWinUIFlyout;
    FClicked: TWinUINavigateButton;
    procedure HookButton(AButton: TWinUIButton; AKind: TWinUINavigateButton);
    procedure ShowButtons;
  private
    procedure UpdateButtons;
  protected
    /// <summary>A toolbar of named buttons for screen readers.</summary>
    function AutomationRole: AutomationControlType; override;
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    function Link: TDataLink; override;
    procedure SourceChanged; override;
  public
    destructor Destroy; override;
    /// <summary>Does what the button AButton does. Delete asks nothing here.</summary>
    procedure BtnClick(AButton: TWinUINavigateButton);
    /// <summary>The button of the last Click.</summary>
    property ClickedButton: TWinUINavigateButton read FClicked;
  published
    /// <summary>The buttons shown, separated by commas: 'First, Prior, Next, Last'. Empty for all.</summary>
    property VisibleButtons: string index 1 read GetText write SetText;
    property ConfirmDelete: Boolean index 2 read GetBoolean write SetBoolean;
    property OnClick: TWinUIWinValueEventHandler index 0 read GetHandler write SetHandler;
  end;

  TDBRows = class;

  /// <summary>
  ///   The base of the controls that list the records: a snapshot of the
  ///   records as bindable rows, kept in step with the dataset's cursor.
  ///   Not registered itself.
  /// </summary>
  TWinUIDBRecordControl = class(TWinUIDataAwareControl)
  strict private
    FLink: TDataLink;
    FRows: TDBRows;
    FBookmarks: TArray<TBookmark>;
    // The cells of each row as read, the current row is read live
    FCells: TArray<TArray<string>>;
    FLoading: Boolean;
    FSyncing: Boolean;
    FInsertRow: Integer;
    FListView: TWinUIListViewBase;
    function ReadRow: TArray<string>;
    function CurrentIndex: Integer;
    procedure ShowInsertRow;
    procedure ListSelectionChanged;
  private
    procedure LinkActive;
    procedure LinkDataSet;
    procedure LinkScrolled;
    procedure LinkRecord;
    procedure LinkEditing;
    function ReadCell(ARow, AColumn: Integer): string;
    procedure WriteCell(ARow, AColumn: Integer; const AValue: string);
  protected
    FFields: TArray<TField>;
    /// <summary>The binding names of the design-time columns.</summary>
    FDesignNames: TArray<string>;
    procedure Initialize; override;
    function Link: TDataLink; override;
    procedure SourceChanged; override;
    /// <summary>The fields a row carries.</summary>
    function ChooseFields(ADataSet: TDataSet): TArray<TField>; virtual;
    /// <summary>The fields changed: build the columns or the template again.</summary>
    procedure ColumnsChanged; virtual;
    /// <summary>The column a binding name means, -1 for none.</summary>
    function ColumnOf(const AName: string): Integer; virtual;
    /// <summary>A field's value as a row shows it.</summary>
    function CellText(AField: TField): string; virtual;
    /// <summary>The rows cannot be edited.</summary>
    function RowsReadOnly: Boolean; virtual;
    /// <summary>The list the rows go to, ItemsSource and selection.</summary>
    procedure AttachList(AList: TWinUIListViewBase);
    /// <summary>Reads every record again.</summary>
    procedure Reload;
  public
    destructor Destroy; override;
    property ListView: TWinUIListViewBase read FListView;
    /// <summary>The number of rows shown.</summary>
    function RowCount: Integer;
    /// <summary>The text of the cell at ARow, AColumn (FFields order).</summary>
    function Cell(ARow, AColumn: Integer): string;
  end;

  /// <summary>
  ///   Shows the records in rows and columns, like TDBGrid. Columns lists
  ///   the fields and their widths ("CompanyName:200, City, Country"), empty
  ///   for every visible field. Cells can be edited unless ReadOnly.
  /// </summary>
  TWinUIDBGrid = class(TWinUIDBRecordControl)
  strict private
    FHeaderHost: TWinUIBorder;
    FWidths: TArray<Double>;
    FSortField: string;
    procedure HeaderTapped(AX: Double);
    function ColumnWidth(AIndex: Integer): Double;
    procedure BuildTemplate;
  protected
    /// <summary>A group that AutomationProperties.Name names, around its list.</summary>
    function AutomationRole: AutomationControlType; override;
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    function ChooseFields(ADataSet: TDataSet): TArray<TField>; override;
    procedure ColumnsChanged; override;
    function CellText(AField: TField): string; override;
    function RowsReadOnly: Boolean; override;
  published
    property Columns: string index 1 read GetText write SetText;
    property ReadOnly: Boolean index 2 read GetBoolean write SetBoolean;
    property SortOnHeaderClick: Boolean index 3 read GetBoolean write SetBoolean;
    property RowHeight: Double index 4 read GetDouble write SetDouble;
  end;

  /// <summary>
  ///   Shows each record in a panel of its own, like TDBCtrlGrid. The panel
  ///   is ItemTemplate, a DataTemplate whose bindings name fields:
  ///   {Binding CompanyName}. Tiles puts the panels side by side.
  /// </summary>
  TWinUIDBCtrlGrid = class(TWinUIDBRecordControl)
  strict private
    function GetValueProp(AIndex: Integer): TWinValue;
    procedure SetValueProp(AIndex: Integer; const AValue: TWinValue);
    procedure BuildList;
    procedure ApplyTemplate;
  protected
    /// <summary>A group that AutomationProperties.Name names, around its tiles.</summary>
    function AutomationRole: AutomationControlType; override;
    class procedure DefineType(AType: TWinUICustomType); override;
    procedure Initialize; override;
    procedure PropertyChanged(AIndex: Integer); override;
    procedure ColumnsChanged; override;
    function RowsReadOnly: Boolean; override;
  published
    property ItemTemplate: TWinValue index 1 read GetValueProp write SetValueProp;
    property Tiles: Boolean index 2 read GetBoolean write SetBoolean;
    property ReadOnly: Boolean index 3 read GetBoolean write SetBoolean;
  end;

  /// <summary>The rows of a record control, as ItemsSource. Not used directly.</summary>
  TDBRows = class(TWinUIBindableListBase)
  strict private
    FOwner: TWinUIDBRecordControl;
    FRows: TArray<IInspectable>;
    FObjects: TArray<TObject>;
    FCount: Integer;
    procedure SetRow(AIndex: Integer; AObject: TObject);
  protected
    function GetCount: Integer; override;
    function GetBindable(AIndex: Integer): IInspectable; override;
  public
    constructor Create(AOwner: TWinUIDBRecordControl);
    destructor Destroy; override;
    procedure Clear;
    procedure Add;
    procedure Insert(AIndex: Integer);
    procedure Delete(AIndex: Integer);
    /// <summary>Tells XAML the list changed as a whole.</summary>
    procedure Reset;
    /// <summary>Tells the bindings of row AIndex that its values changed.</summary>
    procedure RowChanged(AIndex: Integer);
    property Count: Integer read FCount;
  end;

implementation

{$WARN SYMBOL_PLATFORM OFF}

uses
  Winapi.Windows,
  Winapi.ActiveX,
  System.Math,
  System.DateUtils,
  System.TypInfo,
  RADWinUI.Runtime.Application;

const
  // The binding name of grid column I is ColumnPrefix + I, so field names
  // that are not identifiers still bind
  ColumnPrefix = 'rwc';
  // Segoe Fluent Icons
  NavigatorGlyphs: array[TWinUINavigateButton] of Char = (#$E892, #$E76B, #$E76C, #$E893, #$E710, #$E74D,
    #$E70F, #$E73E, #$E711, #$E72C);
  NavigatorHints: array[TWinUINavigateButton] of string = ('First record', 'Prior record', 'Next record',
    'Last record', 'Insert record', 'Delete record', 'Edit record', 'Post edit', 'Cancel edit', 'Refresh data');
  PhotoGlyph = #$EB9F;
  // Microsoft.UI.Text options
  TextFormatRtf = $2000;
  IID_IRandomAccessStream: TGUID = '{905A0FE1-BC53-11DF-8C49-001E4FC686DA}';
  XamlNamespaces = 'xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" ' +
    'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"';
  // Days from 1601-01-01 (WinRT DateTime) to 1899-12-30 (TDateTime 0)
  WinRTEpochDays = 109205;
  WinRTTicksPerDay = 864000000000;

function SHCreateMemStream(AInit: PByte; ASize: Cardinal): Pointer; stdcall; external 'shlwapi.dll' index 12;
function CreateRandomAccessStreamOverStream(const AStream: IStream; AOptions: Cardinal; const AIID: TGUID;
  out AResult: IInspectable): HRESULT; stdcall; external 'shcore.dll';

{ Helpers }

/// Comma separated items, trimmed, empty ones dropped
function SplitList(const AText: string): TArray<string>;
var
  Item: string;
begin
  Result := nil;
  for Item in AText.Split([',']) do
    if Trim(Item) <> '' then
      Result := Result + [Trim(Item)];
end;

function XmlText(const AText: string): string;
begin
  Result := AText.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;');
end;

function InvariantNumber(AValue: Double): string;
begin
  Result := FloatToStr(AValue, TFormatSettings.Invariant);
end;

/// A Header value: nothing for '', so no empty header line takes room
function HeaderValue(const AText: string): TWinValue;
begin
  if AText = '' then
    Result := IInspectable(nil)
  else
    Result := AText;
end;

function BoxBoolean(AValue: Boolean): IReference_Boolean;
begin
  Result := PropertyValue.CreateBoolean(AValue) as IReference_Boolean;
end;

/// Whether AText is one of the ';' separated AValues
function MatchesValue(const AText, AValues: string): Boolean;
var
  Value: string;
begin
  for Value in AValues.Split([';']) do
    if SameText(Trim(Value), Trim(AText)) then
      Exit(True);
  Result := False;
end;

function FirstValue(const AValues: string): string;
var
  Values: TArray<string>;
begin
  Values := AValues.Split([';']);
  if Length(Values) = 0 then
    Result := ''
  else
    Result := Trim(Values[0]);
end;

/// The check state of a field: True, False or unknown (nil) for null and other values
function FieldChecked(AField: TField; const AChecked, AUnchecked: string; out AState: Boolean): Boolean;
begin
  AState := False;
  if (AField = nil) or AField.IsNull then
    Exit(False);
  if AField.DataType = ftBoolean then
  begin
    AState := AField.AsBoolean;
    Exit(True);
  end;
  if MatchesValue(AField.Text, AChecked) then
  begin
    AState := True;
    Exit(True);
  end;
  Result := MatchesValue(AField.Text, AUnchecked);
end;

procedure WriteChecked(AField: TField; AState: Boolean; const AChecked, AUnchecked: string);
begin
  if AField.DataType = ftBoolean then
    AField.AsBoolean := AState
  else if AState then
    AField.Text := FirstValue(AChecked)
  else
    AField.Text := FirstValue(AUnchecked);
end;

/// The text of a field; memo and other blob fields give their content, not '(MEMO)'
function FieldText(AField: TField; ADisplay: Boolean): string;
begin
  if AField is TBlobField then
    Result := AField.AsString
  else if ADisplay then
    Result := AField.DisplayText
  else
    Result := AField.Text;
end;

procedure SetFieldText(AField: TField; const AValue: string);
begin
  if AField is TBlobField then
    AField.AsString := AValue
  else
    AField.Text := AValue;
end;

function ToWinRTDate(ALocal: TDateTime): RADWinUI.Abi.DateTime;
begin
  Result.UniversalTime := Round((TTimeZone.Local.ToUniversalTime(DateOf(ALocal)) + WinRTEpochDays) *
    WinRTTicksPerDay);
end;

function FromWinRTDate(const AValue: RADWinUI.Abi.DateTime): TDateTime;
begin
  Result := DateOf(TTimeZone.Local.ToLocalTime(AValue.UniversalTime / WinRTTicksPerDay - WinRTEpochDays));
end;

type
  /// Calls back when a component it watches is freed
  TFreeWatcher = class(TComponent)
  strict private
    FOnFreed: TProc<TComponent>;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(const AOnFreed: TProc<TComponent>); reintroduce;
  end;

  /// The data modules of the program, from System.Classes' AddDataModule hooks
  TModuleList = class
  strict private
    FPreviousAdd: procedure(DataModule: TDataModule) of object;
    FPreviousRemove: procedure(DataModule: TDataModule) of object;
    FWatcher: TFreeWatcher;
  public
    Modules: TArray<TComponent>;
    constructor Create;
    destructor Destroy; override;
    procedure ModuleAdded(DataModule: TDataModule);
    procedure ModuleRemoved(DataModule: TDataModule);
    procedure Add(AModule: TComponent);
    procedure Remove(AModule: TComponent);
  end;

  /// The field link with the control it belongs to
  TRecordLink = class(TDataLink)
  strict private
    FOwner: TWinUIDBRecordControl;
  protected
    procedure ActiveChanged; override;
    procedure DataSetChanged; override;
    procedure DataSetScrolled(Distance: Integer); override;
    procedure RecordChanged(Field: TField); override;
    procedure EditingChanged; override;
    procedure LayoutChanged; override;
  public
    constructor Create(AOwner: TWinUIDBRecordControl);
  end;

  TNavigatorLink = class(TDataLink)
  strict private
    FOwner: TWinUIDBNavigator;
  protected
    procedure ActiveChanged; override;
    procedure DataSetChanged; override;
    procedure EditingChanged; override;
  public
    constructor Create(AOwner: TWinUIDBNavigator);
  end;

  TListLink = class(TDataLink)
  strict private
    FOwner: TWinUIDBLookupControl;
  protected
    procedure ActiveChanged; override;
    procedure DataSetChanged; override;
    procedure LayoutChanged; override;
  public
    constructor Create(AOwner: TWinUIDBLookupControl);
  end;

  /// Lets a property find the row object behind a WinRT object
  IDBRow = interface
    ['{4B7E2C91-6A0D-4F35-9C18-D2E5A7B30F64}']
    function RowIndex: Integer;
    function RowOwner: TWinUIDBRecordControl;
  end;

  /// One record as XAML binds it: {Binding CompanyName} reads the cell
  TDBRow = class(TWinRTDelegate, IInspectable, ICustomPropertyProvider, INotifyPropertyChanged, IDBRow)
  strict private
    FHandlers: TArray<PropertyChangedEventHandler>;
    FTokens: TArray<Int64>;
    FNextToken: Int64;
  public
    Owner: TWinUIDBRecordControl;
    Index: Integer;
    { IInspectable }
    procedure GetIids(out AIidCount: Cardinal; out AIids: PGUID); safecall;
    function GetRuntimeClassName: HSTRING; safecall;
    function GetTrustLevel: TrustLevel; safecall;
    { ICustomPropertyProvider }
    function GetCustomProperty(AName: HSTRING): ICustomProperty; safecall;
    function GetIndexedProperty(AName: HSTRING; AType: TypeName): ICustomProperty; safecall;
    function GetStringRepresentation: HSTRING; safecall;
    function get_Type: TypeName; safecall;
    { INotifyPropertyChanged }
    function add_PropertyChanged(AHandler: PropertyChangedEventHandler): EventRegistrationToken; safecall;
    procedure remove_PropertyChanged(AToken: EventRegistrationToken); safecall;
    { IDBRow }
    function RowIndex: Integer;
    function RowOwner: TWinUIDBRecordControl;
    procedure NotifyAll;
  end;

  TDBRowProperty = class(TWinRTDelegate, IInspectable, ICustomProperty)
  strict private
    FName: string;
    FColumn: Integer;
  protected
    procedure GetIids(out AIidCount: Cardinal; out AIids: PGUID); safecall;
    function GetRuntimeClassName: HSTRING; safecall;
    function GetTrustLevel: TrustLevel; safecall;
    function get_Type: TypeName; safecall;
    function get_Name: HSTRING; safecall;
    function GetValue(ATarget: IInspectable): IInspectable; safecall;
    procedure SetValue(ATarget: IInspectable; AValue: IInspectable); safecall;
    function GetIndexedValue(ATarget: IInspectable; AIndex: IInspectable): IInspectable; safecall;
    procedure SetIndexedValue(ATarget: IInspectable; AValue: IInspectable; AIndex: IInspectable); safecall;
    function get_CanWrite: Boolean; safecall;
    function get_CanRead: Boolean; safecall;
  public
    constructor Create(const AName: string; AColumn: Integer);
  end;

var
  ModuleList: TModuleList;

function NewTypeName(const AName: string; AKind: TypeKind): TypeName;
begin
  Result.&Name := NewHString(AName);
  Result.Kind := AKind;
end;

function FindModuleComponent(const AName: string): TComponent;
var
  Module: TComponent;
begin
  if ModuleList <> nil then
    for Module in ModuleList.Modules do
      if SameText(Module.Name, AName) then
        Exit(Module);
  Result := nil;
end;

{ TFreeWatcher }

constructor TFreeWatcher.Create(const AOnFreed: TProc<TComponent>);
begin
  inherited Create(nil);
  FOnFreed := AOnFreed;
end;

procedure TFreeWatcher.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and Assigned(FOnFreed) then
    FOnFreed(AComponent);
end;

{ TModuleList }

constructor TModuleList.Create;
begin
  inherited Create;
  FWatcher := TFreeWatcher.Create(
    procedure(AComponent: TComponent)
    begin
      Remove(AComponent);
    end);
  FPreviousAdd := AddDataModule;
  FPreviousRemove := RemoveDataModule;
  AddDataModule := ModuleAdded;
  RemoveDataModule := ModuleRemoved;
  RegisterFindGlobalComponentProc(FindModuleComponent);
end;

destructor TModuleList.Destroy;
begin
  UnregisterFindGlobalComponentProc(FindModuleComponent);
  if TMethod(AddDataModule).Data = Pointer(Self) then
    AddDataModule := FPreviousAdd;
  if TMethod(RemoveDataModule).Data = Pointer(Self) then
    RemoveDataModule := FPreviousRemove;
  FWatcher.Free;
  inherited;
end;

procedure TModuleList.ModuleAdded(DataModule: TDataModule);
begin
  Add(DataModule);
  if Assigned(FPreviousAdd) then
    FPreviousAdd(DataModule);
end;

procedure TModuleList.ModuleRemoved(DataModule: TDataModule);
begin
  Remove(DataModule);
  if Assigned(FPreviousRemove) then
    FPreviousRemove(DataModule);
end;

procedure TModuleList.Add(AModule: TComponent);
var
  Module: TComponent;
begin
  for Module in Modules do
    if Module = AModule then
      Exit;
  Modules := Modules + [AModule];
  AModule.FreeNotification(FWatcher);
end;

procedure TModuleList.Remove(AModule: TComponent);
var
  I: Integer;
begin
  for I := High(Modules) downto 0 do
    if Modules[I] = AModule then
    begin
      Delete(Modules, I, 1);
      AModule.RemoveFreeNotification(FWatcher);
    end;
end;

{ TWinUIFieldLink }

procedure TWinUIFieldLink.SetFieldName(const AValue: string);
begin
  if FFieldName <> AValue then
  begin
    FFieldName := AValue;
    UpdateField;
  end;
end;

procedure TWinUIFieldLink.SetField(AValue: TField);
begin
  if FField <> AValue then
  begin
    FField := AValue;
    EditingChanged;
    RecordChanged(nil);
  end;
end;

procedure TWinUIFieldLink.UpdateField;
begin
  if Active and (FFieldName <> '') then
    SetField(DataSource.DataSet.FindField(FFieldName))
  else
    SetField(nil);
end;

function TWinUIFieldLink.GetCanModify: Boolean;
begin
  Result := not ReadOnly and (FField <> nil) and FField.CanModify;
end;

procedure TWinUIFieldLink.ActiveChanged;
begin
  UpdateField;
  if Assigned(FOnActiveChange) then
    FOnActiveChange(Self);
end;

procedure TWinUIFieldLink.EditingChanged;
begin
  if Assigned(FOnEditingChange) then
    FOnEditingChange(Self);
end;

procedure TWinUIFieldLink.LayoutChanged;
begin
  UpdateField;
end;

procedure TWinUIFieldLink.RecordChanged(Field: TField);
begin
  if (Field = nil) or (Field = FField) then
  begin
    if Assigned(FOnDataChange) then
      FOnDataChange(Self);
    FModified := False;
  end;
end;

procedure TWinUIFieldLink.UpdateData;
begin
  if FModified then
  begin
    if (FField <> nil) and Assigned(FOnUpdateData) then
      FOnUpdateData(Self);
    FModified := False;
  end;
end;

function TWinUIFieldLink.Edit: Boolean;
begin
  if CanModify then
    inherited Edit;
  Result := Editing;
end;

procedure TWinUIFieldLink.Modified;
begin
  FModified := True;
end;

procedure TWinUIFieldLink.Reset;
begin
  RecordChanged(nil);
end;

{ TWinUIDataSources }

/// The object a published field or property AName of AContext holds, nil when there is none
function PublishedObject(AContext: TObject; const AName: string): TObject;
var
  Address: Pointer;
  Info: PPropInfo;
begin
  Result := nil;
  if (AContext = nil) or (AName = '') then
    Exit;
  Address := AContext.FieldAddress(AName);
  if Address <> nil then
    Exit(TObject(Address^));
  Info := GetPropInfo(AContext, AName);
  if (Info <> nil) and (Info^.PropType^.Kind = tkClass) then
    Result := GetObjectProp(AContext, Info);
end;

function SourceIn(AOwner: TObject; const AName: string): TDataSource;
var
  Found: TComponent;
begin
  Result := nil;
  if AOwner is TComponent then
  begin
    Found := TComponent(AOwner).FindComponent(AName);
    if Found is TDataSource then
      Result := TDataSource(Found);
  end;
end;

class function TWinUIDataSources.Find(AContext: TObject; const AName: string): TDataSource;
var
  Name, ModuleName, SourceName: string;
  Dot: Integer;
  Found: TObject;
  Module: TComponent;
begin
  Result := nil;
  Name := Trim(AName);
  if Name = '' then
    Exit;
  Dot := Pos('.', Name);
  if Dot > 0 then
  begin
    ModuleName := Copy(Name, 1, Dot - 1);
    SourceName := Copy(Name, Dot + 1, MaxInt);
  end
  else
  begin
    ModuleName := '';
    SourceName := Name;
  end;
  // The window: a field CustomersSource: TDataSource, or a field Data: TCustomersModule
  if AContext <> nil then
  begin
    if ModuleName = '' then
    begin
      Found := PublishedObject(AContext, SourceName);
      if Found is TDataSource then
        Exit(TDataSource(Found));
      Result := SourceIn(AContext, SourceName);
    end
    else
      Result := SourceIn(PublishedObject(AContext, ModuleName), SourceName);
    if Result <> nil then
      Exit;
  end;
  // The data modules
  if ModuleList <> nil then
    for Module in ModuleList.Modules do
      if (ModuleName = '') or SameText(Module.Name, ModuleName) then
      begin
        Result := SourceIn(Module, SourceName);
        if Result <> nil then
          Exit;
      end;
  // Data modules other code knows (VCL's Screen, when a program links it)
  if ModuleName <> '' then
    Result := SourceIn(FindGlobalComponent(ModuleName), SourceName)
  else
  begin
    Found := FindGlobalComponent(SourceName);
    if Found is TDataSource then
      Result := TDataSource(Found);
  end;
end;

class procedure TWinUIDataSources.AddModule(AModule: TComponent);
begin
  if (ModuleList <> nil) and (AModule <> nil) then
    ModuleList.Add(AModule);
end;

class procedure TWinUIDataSources.RemoveModule(AModule: TComponent);
begin
  if ModuleList <> nil then
    ModuleList.Remove(AModule);
end;

class function TWinUIDataSources.Modules: TArray<TComponent>;
begin
  if ModuleList = nil then
    Result := nil
  else
    Result := Copy(ModuleList.Modules);
end;

{ TWinUIDataAwareControl }

class procedure TWinUIDataAwareControl.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('DataSource', TWinUIPropertyKind.Text);
  AType.SetEditor('DataSource', 'datasource');
end;

procedure TWinUIDataAwareControl.Initialize;
begin
  inherited;
  IsTabStop := False;
  HorizontalContentAlignment := TWinUIHorizontalAlignment.Stretch;
  VerticalContentAlignment := TWinUIVerticalAlignment.Stretch;
  // The window's fields and data modules may come after the XAML: look again once shown
  Loaded.Add(
    procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
    begin
      if Link.DataSource = nil then
        ResolveSource;
    end);
end;

destructor TWinUIDataAwareControl.Destroy;
begin
  FWatcher.Free;
  inherited;
end;

procedure TWinUIDataAwareControl.PropertyChanged(AIndex: Integer);
begin
  inherited;
  if AIndex = 0 then
    ResolveSource;
end;

function TWinUIDataAwareControl.DesignTime: Boolean;
begin
  Result := CustomXamlDesignTime;
end;

function TWinUIDataAwareControl.ElementName: string;
begin
  Result := Name;
end;

procedure TWinUIDataAwareControl.HandleError(E: Exception);
begin
  if Assigned(WinRTHandleException) then
    WinRTHandleException(E);
end;

function TWinUIDataAwareControl.FindSource(const AName: string): TDataSource;
begin
  if DesignTime then
    Result := nil
  else
    Result := TWinUIDataSources.Find(OwnerWindow, AName);
end;

procedure TWinUIDataAwareControl.ResolveSource;
var
  Source: TDataSource;
begin
  if FSource <> nil then
    Source := FSource
  else
    Source := FindSource(GetText(0));
  if Link.DataSource <> Source then
    Link.DataSource := Source;
  SourceChanged;
end;

procedure TWinUIDataAwareControl.SourceChanged;
begin
end;

function TWinUIDataAwareControl.GetDataSource: TDataSource;
begin
  Result := Link.DataSource;
end;

procedure TWinUIDataAwareControl.SetDataSource(AValue: TDataSource);
begin
  if (FSource <> nil) and (FWatcher <> nil) then
    FSource.RemoveFreeNotification(FWatcher);
  FSource := AValue;
  if FSource <> nil then
  begin
    if FWatcher = nil then
      FWatcher := TFreeWatcher.Create(SourceFreed);
    FSource.FreeNotification(FWatcher);
  end;
  ResolveSource;
end;

procedure TWinUIDataAwareControl.SourceFreed(AComponent: TComponent);
begin
  if AComponent = FSource then
    FSource := nil;
end;

function TWinUIDataAwareControl.DataSet: TDataSet;
begin
  Result := Link.DataSet;
end;

{ TWinUIDBFieldControl }

class procedure TWinUIDBFieldControl.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('DataField', TWinUIPropertyKind.Text);
  AType.SetEditor('DataField', 'datafield');
  AType.AddProperty('ReadOnly', TWinUIPropertyKind.Boolean, 'False');
end;

procedure TWinUIDBFieldControl.Initialize;
begin
  FFieldLink := TWinUIFieldLink.Create;
  FFieldLink.OnDataChange := LinkDataChange;
  FFieldLink.OnEditingChange := LinkEditingChange;
  FFieldLink.OnUpdateData := LinkUpdateData;
  FFieldLink.OnActiveChange := LinkActiveChange;
  inherited;
end;

destructor TWinUIDBFieldControl.Destroy;
begin
  if FFieldLink <> nil then
  begin
    FFieldLink.OnDataChange := nil;
    FFieldLink.OnEditingChange := nil;
    FFieldLink.OnUpdateData := nil;
    FFieldLink.OnActiveChange := nil;
    FFieldLink.DataSource := nil;
  end;
  inherited;
  FreeAndNil(FFieldLink);
end;

function TWinUIDBFieldControl.Link: TDataLink;
begin
  Result := FFieldLink;
end;

function TWinUIDBFieldControl.Field: TField;
begin
  Result := FFieldLink.Field;
end;

procedure TWinUIDBFieldControl.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    1:
      begin
        FFieldLink.FieldName := Trim(GetText(1));
        Refresh;
      end;
    2:
      begin
        FFieldLink.ReadOnly := GetBoolean(2);
        UpdateEditable;
      end;
  end;
end;

procedure TWinUIDBFieldControl.SourceChanged;
begin
  inherited;
  Refresh;
  UpdateEditable;
end;

procedure TWinUIDBFieldControl.Refresh;
begin
  Inc(FShowing);
  try
    ShowField;
  finally
    Dec(FShowing);
  end;
end;

procedure TWinUIDBFieldControl.LinkDataChange(Sender: TObject);
begin
  // Going into Edit keeps the record, and the control already holds the new value
  if FStarting = 0 then
    Refresh;
end;

procedure TWinUIDBFieldControl.LinkEditingChange(Sender: TObject);
begin
  UpdateEditable;
end;

procedure TWinUIDBFieldControl.LinkUpdateData(Sender: TObject);
begin
  if Field <> nil then
    WriteField;
end;

procedure TWinUIDBFieldControl.LinkActiveChange(Sender: TObject);
begin
  Refresh;
  UpdateEditable;
end;

procedure TWinUIDBFieldControl.UpdateEditable;
begin
end;

function TWinUIDBFieldControl.Editable: Boolean;
begin
  if GetBoolean(2) then
    Result := False
  else if DesignTime or (Field = nil) then
    Result := True
  else
    Result := FFieldLink.CanModify;
end;

function TWinUIDBFieldControl.StartEdit: Boolean;
begin
  if (FShowing > 0) or (Field = nil) then
    Exit(False);
  try
    Inc(FStarting);
    try
      Result := FFieldLink.Edit;
    finally
      Dec(FStarting);
    end;
    if Result then
      FFieldLink.Modified;
  except
    on E: Exception do
    begin
      Result := False;
      HandleError(E);
    end;
  end;
  if not Result then
    Refresh;
end;

procedure TWinUIDBFieldControl.Commit;
begin
  if Field = nil then
    Exit;
  try
    FFieldLink.UpdateRecord;
  except
    on E: Exception do
      HandleError(E);
  end;
end;

procedure TWinUIDBFieldControl.Revert;
begin
  FFieldLink.Reset;
  Refresh;
end;

function TWinUIDBFieldControl.DesignText: string;
begin
  Result := Trim(GetText(1));
  if Result = '' then
    Result := ElementName;
  if Result = '' then
    Result := CustomType.XamlName;
end;

{ TWinUIDBText }

class procedure TWinUIDBText.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('WordWrap', TWinUIPropertyKind.Boolean, 'False');
end;

procedure TWinUIDBText.Initialize;
begin
  FText := TWinUITextBlock.Create(Self);
  FText.TextTrimming := TWinUITextTrimming.CharacterEllipsis;
  FText.VerticalAlignment := TWinUIVerticalAlignment.Center;
  Content := FText;
  inherited;
end;

procedure TWinUIDBText.PropertyChanged(AIndex: Integer);
begin
  inherited;
  if AIndex = 3 then
    if GetBoolean(3) then
      FText.TextWrapping := TWinUITextWrapping.Wrap
    else
      FText.TextWrapping := TWinUITextWrapping.NoWrap;
end;

procedure TWinUIDBText.ShowField;
begin
  if Field <> nil then
    FText.Text := FieldText(Field, True)
  else if DesignTime then
    FText.Text := DesignText
  else
    FText.Text := '';
end;

procedure TWinUIDBText.WriteField;
begin
end;

{ TWinUIDBEdit }

class procedure TWinUIDBEdit.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Header', TWinUIPropertyKind.Text);
  AType.AddProperty('PlaceholderText', TWinUIPropertyKind.Text);
end;

procedure TWinUIDBEdit.Initialize;
begin
  FBox := TWinUITextBox.Create(Self);
  Content := FBox;
  FBox.TextChanged.Add(
    procedure(Sender: TObject; E: TWinUITextChangedEventArgs)
    begin
      BoxTextChanged;
    end);
  FBox.GotFocus.Add(
    procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
    begin
      FFocused := True;
      if not FieldLink.Editing then
        Refresh;
    end);
  FBox.LostFocus.Add(
    procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
    begin
      FFocused := False;
      Commit;
      Refresh;
    end);
  FBox.KeyDown.Add(
    procedure(Sender: TObject; E: TWinUIKeyRoutedEventArgs)
    begin
      BoxKeyDown(E);
    end);
  inherited;
end;

function TWinUIDBEdit.CommitsOnEnter: Boolean;
begin
  Result := True;
end;

procedure TWinUIDBEdit.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    3:
      FBox.Header := HeaderValue(GetText(3));
    4:
      FBox.PlaceholderText := GetText(4);
  end;
end;

procedure TWinUIDBEdit.ShowText(const AText: string);
begin
  // TextChanged comes later than the change: it compares with this
  FShownText := AText;
  if FBox.Text <> AText then
    FBox.Text := AText;
end;

procedure TWinUIDBEdit.ShowField;
var
  F: TField;
begin
  F := Field;
  if F = nil then
  begin
    if DesignTime then
      ShowText(DesignText)
    else
      ShowText('');
    FBox.MaxLength := 0;
    Exit;
  end;
  // Like TDBEdit: the editable text while focused, the formatted one otherwise
  if FFocused and FieldLink.CanModify then
    ShowText(FieldText(F, False))
  else
    ShowText(FieldText(F, True));
  if (F.DataType in [ftString, ftWideString, ftFixedChar, ftFixedWideChar]) and (F.Size > 0) then
    FBox.MaxLength := F.Size
  else
    FBox.MaxLength := 0;
end;

procedure TWinUIDBEdit.BoxTextChanged;
var
  Typed: string;
  Caret: Integer;
begin
  Typed := FBox.Text;
  if (FShowing > 0) or (Typed = FShownText) or FieldLink.Editing and (FieldLink.DataSet <> nil) and
    FieldLink.DataSet.Modified and (Field <> nil) and (Typed = FieldText(Field, False)) then
    Exit;
  Caret := FBox.SelectionStart;
  if not StartEdit then
    Exit;
  // Some datasets read the record again when they go into Edit
  if FBox.Text <> Typed then
  begin
    Inc(FShowing);
    try
      FBox.Text := Typed;
      FBox.SelectionStart := Caret;
    finally
      Dec(FShowing);
    end;
  end;
  FShownText := Typed;
end;

procedure TWinUIDBEdit.BoxKeyDown(E: TWinUIKeyRoutedEventArgs);
begin
  case E.Key of
    TWinUIVirtualKey.Enter:
      if CommitsOnEnter then
      begin
        Commit;
        E.Handled := True;
      end;
    TWinUIVirtualKey.Escape:
      if FieldLink.Editing then
      begin
        Revert;
        FBox.SelectAll;
        E.Handled := True;
      end;
  end;
end;

procedure TWinUIDBEdit.WriteField;
begin
  SetFieldText(Field, FBox.Text);
  FShownText := FBox.Text;
end;

procedure TWinUIDBEdit.UpdateEditable;
begin
  FBox.IsReadOnly := not Editable;
end;

{ TWinUIDBMemo }

procedure TWinUIDBMemo.Initialize;
begin
  inherited;
  FBox.AcceptsReturn := True;
  FBox.TextWrapping := TWinUITextWrapping.Wrap;
  Height := 120;
end;

function TWinUIDBMemo.CommitsOnEnter: Boolean;
begin
  Result := False;
end;

{ TWinUIDBCheckBox }

class procedure TWinUIDBCheckBox.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Text', TWinUIPropertyKind.Text);
  AType.AddProperty('ValueChecked', TWinUIPropertyKind.Text, 'True');
  AType.AddProperty('ValueUnchecked', TWinUIPropertyKind.Text, 'False');
end;

procedure TWinUIDBCheckBox.Initialize;
begin
  FCheck := TWinUICheckBox.Create(Self);
  Content := FCheck;
  FCheck.Click.Add(
    procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
    begin
      if StartEdit then
        Commit;
    end);
  inherited;
end;

procedure TWinUIDBCheckBox.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    3:
      FCheck.Content := GetText(3);
    4, 5:
      Refresh;
  end;
end;

procedure TWinUIDBCheckBox.ShowField;
var
  State: Boolean;
begin
  if Field = nil then
    FCheck.IsChecked := BoxBoolean(False)
  else if FieldChecked(Field, GetText(4), GetText(5), State) then
    FCheck.IsChecked := BoxBoolean(State)
  else
    FCheck.IsChecked := nil; // null, or a value that is neither
end;

procedure TWinUIDBCheckBox.WriteField;
var
  Checked: IReference_Boolean;
begin
  Checked := FCheck.IsChecked;
  WriteChecked(Field, (Checked <> nil) and Checked.Value, GetText(4), GetText(5));
end;

procedure TWinUIDBCheckBox.UpdateEditable;
begin
  FCheck.IsHitTestVisible := Editable;
  FCheck.IsTabStop := Editable;
end;

{ TWinUIDBToggleSwitch }

class procedure TWinUIDBToggleSwitch.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Header', TWinUIPropertyKind.Text);
  AType.AddProperty('ValueChecked', TWinUIPropertyKind.Text, 'True');
  AType.AddProperty('ValueUnchecked', TWinUIPropertyKind.Text, 'False');
end;

procedure TWinUIDBToggleSwitch.Initialize;
begin
  FSwitch := TWinUIToggleSwitch.Create(Self);
  Content := FSwitch;
  FSwitch.Toggled.Add(
    procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
    begin
      if (FShowing = 0) and (FSwitch.IsOn <> FShownOn) and StartEdit then
      begin
        Commit;
        FShownOn := FSwitch.IsOn;
      end;
    end);
  inherited;
end;

procedure TWinUIDBToggleSwitch.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    3:
      FSwitch.Header := HeaderValue(GetText(3));
    4, 5:
      Refresh;
  end;
end;

procedure TWinUIDBToggleSwitch.ShowField;
var
  State: Boolean;
begin
  if not FieldChecked(Field, GetText(4), GetText(5), State) then
    State := False;
  FShownOn := State;
  FSwitch.IsOn := State;
end;

procedure TWinUIDBToggleSwitch.WriteField;
begin
  WriteChecked(Field, FSwitch.IsOn, GetText(4), GetText(5));
end;

procedure TWinUIDBToggleSwitch.UpdateEditable;
begin
  FSwitch.IsHitTestVisible := Editable;
  FSwitch.IsTabStop := Editable;
end;

{ TWinUIDBChoiceControl }

function TWinUIDBChoiceControl.ItemCount: Integer;
begin
  Result := Length(FTexts);
end;

function TWinUIDBChoiceControl.ValueAt(AIndex: Integer): string;
begin
  if AIndex < Length(FValues) then
    Result := FValues[AIndex]
  else
    Result := FTexts[AIndex];
end;

function TWinUIDBChoiceControl.IndexOfValue(const AValue: string): Integer;
begin
  for Result := 0 to High(FTexts) do
    if SameText(ValueAt(Result), AValue) then
      Exit;
  Result := -1;
end;

procedure TWinUIDBChoiceControl.ShowField;
begin
  if (Field = nil) or Field.IsNull then
    FShownIndex := -1
  else
    FShownIndex := IndexOfValue(Field.AsString);
  SelectChoice(FShownIndex);
end;

procedure TWinUIDBChoiceControl.WriteField;
var
  Index: Integer;
begin
  Index := ChoiceIndex;
  if (Index < 0) or (Index > High(FTexts)) then
    Field.Clear
  else
    Field.AsString := ValueAt(Index);
end;

procedure TWinUIDBChoiceControl.ChoiceMade;
begin
  if (FShowing > 0) or (ChoiceIndex = FShownIndex) and (ChoiceIndex >= 0) then
    Exit;
  if StartEdit then
  begin
    Commit;
    FShownIndex := ChoiceIndex;
  end;
end;

{ TWinUIDBComboBox }

class procedure TWinUIDBComboBox.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Items', TWinUIPropertyKind.Text);
  AType.AddProperty('Header', TWinUIPropertyKind.Text);
  AType.AddProperty('PlaceholderText', TWinUIPropertyKind.Text);
  AType.AddProperty('IsEditable', TWinUIPropertyKind.Boolean, 'False');
end;

procedure TWinUIDBComboBox.Initialize;
begin
  FCombo := TWinUIComboBox.Create(Self);
  FCombo.HorizontalAlignment := TWinUIHorizontalAlignment.Stretch;
  Content := FCombo;
  FCombo.SelectionChanged.Add(
    procedure(Sender: TObject; E: TWinUISelectionChangedEventArgs)
    begin
      if FShowing = 0 then
        ChoiceMade;
    end);
  FCombo.TextSubmitted.Add(
    procedure(Sender: TObject; E: TWinUIComboBoxTextSubmittedEventArgs)
    begin
      if (FShowing = 0) and StartEdit then
        Commit;
    end);
  inherited;
end;

procedure TWinUIDBComboBox.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    3:
      begin
        FTexts := SplitList(GetText(3));
        ShowChoices;
        Refresh;
      end;
    4:
      FCombo.Header := HeaderValue(GetText(4));
    5:
      FCombo.PlaceholderText := GetText(5);
    6:
      FCombo.IsEditable := GetBoolean(6);
  end;
end;

procedure TWinUIDBComboBox.ShowChoices;
var
  Text: string;
begin
  Inc(FShowing);
  try
    FCombo.Items.Clear;
    for Text in FTexts do
      FCombo.Items.Add(Text);
  finally
    Dec(FShowing);
  end;
end;

function TWinUIDBComboBox.ChoiceIndex: Integer;
begin
  Result := FCombo.SelectedIndex;
end;

procedure TWinUIDBComboBox.SelectChoice(AIndex: Integer);
begin
  FCombo.SelectedIndex := AIndex;
end;

procedure TWinUIDBComboBox.ShowField;
begin
  inherited;
  // A typed value that is not one of the items
  if GetBoolean(6) and (Field <> nil) and (ChoiceIndex < 0) then
    FCombo.Text := Field.AsString
  else if DesignTime and (Field = nil) and (ChoiceIndex < 0) then
    FCombo.PlaceholderText := DesignText;
end;

procedure TWinUIDBComboBox.WriteField;
begin
  if GetBoolean(6) and (ChoiceIndex < 0) then
  begin
    if FCombo.Text = '' then
      Field.Clear
    else
      Field.AsString := FCombo.Text;
  end
  else
    inherited;
end;

procedure TWinUIDBComboBox.UpdateEditable;
begin
  FCombo.IsHitTestVisible := Editable;
  FCombo.IsTabStop := Editable;
end;

{ TWinUIDBListBox }

class procedure TWinUIDBListBox.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Items', TWinUIPropertyKind.Text);
end;

procedure TWinUIDBListBox.Initialize;
begin
  FList := TWinUIListView.Create(Self);
  FList.SelectionMode := TWinUIListViewSelectionMode.Single;
  Content := FList;
  FList.SelectionChanged.Add(
    procedure(Sender: TObject; E: TWinUISelectionChangedEventArgs)
    begin
      if FShowing = 0 then
        ChoiceMade;
    end);
  inherited;
  Height := 160;
end;

procedure TWinUIDBListBox.PropertyChanged(AIndex: Integer);
begin
  inherited;
  if AIndex = 3 then
  begin
    FTexts := SplitList(GetText(3));
    ShowChoices;
    Refresh;
  end;
end;

procedure TWinUIDBListBox.ShowChoices;
var
  Text: string;
begin
  Inc(FShowing);
  try
    FList.Items.Clear;
    for Text in FTexts do
      FList.Items.Add(Text);
  finally
    Dec(FShowing);
  end;
end;

function TWinUIDBListBox.ChoiceIndex: Integer;
begin
  Result := FList.SelectedIndex;
end;

procedure TWinUIDBListBox.SelectChoice(AIndex: Integer);
begin
  FList.SelectedIndex := AIndex;
end;

procedure TWinUIDBListBox.UpdateEditable;
begin
  FList.IsHitTestVisible := Editable;
end;

{ TWinUIDBRadioGroup }

class procedure TWinUIDBRadioGroup.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Items', TWinUIPropertyKind.Text);
  AType.AddProperty('Values', TWinUIPropertyKind.Text);
  AType.AddProperty('Header', TWinUIPropertyKind.Text);
  AType.AddProperty('Columns', TWinUIPropertyKind.Int32, '1');
end;

procedure TWinUIDBRadioGroup.Initialize;
begin
  FRadio := TWinUIRadioButtons.Create(Self);
  Content := FRadio;
  FRadio.SelectionChanged.Add(
    procedure(Sender: TObject; E: TWinUISelectionChangedEventArgs)
    begin
      if FShowing = 0 then
        ChoiceMade;
    end);
  inherited;
end;

procedure TWinUIDBRadioGroup.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    3:
      begin
        FTexts := SplitList(GetText(3));
        ShowChoices;
        Refresh;
      end;
    4:
      begin
        FValues := SplitList(GetText(4));
        Refresh;
      end;
    5:
      FRadio.Header := HeaderValue(GetText(5));
    6:
      FRadio.MaxColumns := Max(1, GetInt32(6));
  end;
end;

procedure TWinUIDBRadioGroup.ShowChoices;
var
  Text: string;
begin
  Inc(FShowing);
  try
    FRadio.Items.Clear;
    for Text in FTexts do
      FRadio.Items.Add(Text);
  finally
    Dec(FShowing);
  end;
end;

function TWinUIDBRadioGroup.ChoiceIndex: Integer;
begin
  Result := FRadio.SelectedIndex;
end;

procedure TWinUIDBRadioGroup.SelectChoice(AIndex: Integer);
begin
  FRadio.SelectedIndex := AIndex;
end;

procedure TWinUIDBRadioGroup.UpdateEditable;
begin
  FRadio.IsHitTestVisible := Editable;
end;

{ TListLink }

constructor TListLink.Create(AOwner: TWinUIDBLookupControl);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TListLink.ActiveChanged;
begin
  FOwner.ListChanged;
end;

procedure TListLink.DataSetChanged;
begin
  FOwner.ListChanged;
end;

procedure TListLink.LayoutChanged;
begin
  FOwner.ListChanged;
end;

{ TWinUIDBLookupControl }

class procedure TWinUIDBLookupControl.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('ListSource', TWinUIPropertyKind.Text);
  AType.SetEditor('ListSource', 'datasource');
  AType.AddProperty('KeyField', TWinUIPropertyKind.Text);
  AType.SetEditor('KeyField', 'listfield');
  AType.AddProperty('ListField', TWinUIPropertyKind.Text);
  AType.SetEditor('ListField', 'listfield');
end;

procedure TWinUIDBLookupControl.Initialize;
begin
  FListLink := TListLink.Create(Self);
  inherited;
  Loaded.Add(
    procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
    begin
      if FListLink.DataSource = nil then
        ResolveListSource;
    end);
end;

destructor TWinUIDBLookupControl.Destroy;
begin
  if FListLink <> nil then
    FListLink.DataSource := nil;
  inherited;
  FreeAndNil(FListLink);
end;

procedure TWinUIDBLookupControl.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    3:
      ResolveListSource;
    4, 5:
      LoadList;
  end;
end;

procedure TWinUIDBLookupControl.SourceChanged;
begin
  if FListLink.DataSource = nil then
    ResolveListSource;
  inherited;
end;

procedure TWinUIDBLookupControl.ResolveListSource;
var
  Source: TDataSource;
begin
  if FListSource <> nil then
    Source := FListSource
  else
    Source := FindSource(GetText(3));
  if FListLink.DataSource <> Source then
    FListLink.DataSource := Source
  else
    LoadList;
end;

function TWinUIDBLookupControl.GetListSource: TDataSource;
begin
  Result := FListLink.DataSource;
end;

procedure TWinUIDBLookupControl.SetListSource(AValue: TDataSource);
begin
  FListSource := AValue;
  ResolveListSource;
end;

procedure TWinUIDBLookupControl.ListChanged;
begin
  if not FLoadingList then
    LoadList;
end;

procedure TWinUIDBLookupControl.LoadList;
var
  DS: TDataSet;
  KeyF, ListF: TField;
  Mark: TBookmark;
  Count: Integer;
begin
  if FLoadingList then
    Exit;
  FTexts := nil;
  FValues := nil;
  DS := FListLink.DataSet;
  if DesignTime then
    FTexts := [DesignText]
  else if (DS <> nil) and DS.Active and (DS.State = dsBrowse) then
  begin
    KeyF := DS.FindField(Trim(GetText(4)));
    ListF := DS.FindField(Trim(GetText(5)));
    if ListF = nil then
      ListF := KeyF;
    if KeyF <> nil then
    begin
      FLoadingList := True;
      try
        Mark := DS.Bookmark;
        DS.DisableControls;
        try
          Count := 0;
          DS.First;
          while not DS.Eof do
          begin
            if Count = Length(FTexts) then
            begin
              SetLength(FTexts, Max(16, Count * 2));
              SetLength(FValues, Length(FTexts));
            end;
            FTexts[Count] := ListF.DisplayText;
            FValues[Count] := KeyF.AsString;
            Inc(Count);
            DS.Next;
          end;
          SetLength(FTexts, Count);
          SetLength(FValues, Count);
        finally
          if (Mark <> nil) and DS.BookmarkValid(Mark) then
            DS.Bookmark := Mark;
          DS.EnableControls;
        end;
      finally
        FLoadingList := False;
      end;
    end;
  end;
  ShowChoices;
  Refresh;
end;

{ TWinUIDBLookupComboBox }

class procedure TWinUIDBLookupComboBox.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Header', TWinUIPropertyKind.Text);
  AType.AddProperty('PlaceholderText', TWinUIPropertyKind.Text);
end;

procedure TWinUIDBLookupComboBox.Initialize;
begin
  FCombo := TWinUIComboBox.Create(Self);
  FCombo.HorizontalAlignment := TWinUIHorizontalAlignment.Stretch;
  Content := FCombo;
  FCombo.SelectionChanged.Add(
    procedure(Sender: TObject; E: TWinUISelectionChangedEventArgs)
    begin
      if FShowing = 0 then
        ChoiceMade;
    end);
  inherited;
end;

procedure TWinUIDBLookupComboBox.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    6:
      FCombo.Header := HeaderValue(GetText(6));
    7:
      FCombo.PlaceholderText := GetText(7);
  end;
end;

procedure TWinUIDBLookupComboBox.ShowChoices;
var
  Text: string;
begin
  Inc(FShowing);
  try
    FCombo.Items.Clear;
    for Text in FTexts do
      FCombo.Items.Add(Text);
  finally
    Dec(FShowing);
  end;
end;

function TWinUIDBLookupComboBox.ChoiceIndex: Integer;
begin
  Result := FCombo.SelectedIndex;
end;

procedure TWinUIDBLookupComboBox.SelectChoice(AIndex: Integer);
begin
  if DesignTime and (AIndex < 0) and (Length(FTexts) > 0) then
    AIndex := 0;
  FCombo.SelectedIndex := AIndex;
end;

procedure TWinUIDBLookupComboBox.UpdateEditable;
begin
  FCombo.IsHitTestVisible := Editable;
  FCombo.IsTabStop := Editable;
end;

{ TWinUIDBLookupListBox }

procedure TWinUIDBLookupListBox.Initialize;
begin
  FList := TWinUIListView.Create(Self);
  FList.SelectionMode := TWinUIListViewSelectionMode.Single;
  Content := FList;
  FList.SelectionChanged.Add(
    procedure(Sender: TObject; E: TWinUISelectionChangedEventArgs)
    begin
      if FShowing = 0 then
        ChoiceMade;
    end);
  inherited;
  Height := 160;
end;

procedure TWinUIDBLookupListBox.ShowChoices;
var
  Text: string;
begin
  Inc(FShowing);
  try
    FList.Items.Clear;
    for Text in FTexts do
      FList.Items.Add(Text);
  finally
    Dec(FShowing);
  end;
end;

function TWinUIDBLookupListBox.ChoiceIndex: Integer;
begin
  Result := FList.SelectedIndex;
end;

procedure TWinUIDBLookupListBox.SelectChoice(AIndex: Integer);
begin
  FList.SelectedIndex := AIndex;
end;

procedure TWinUIDBLookupListBox.UpdateEditable;
begin
  FList.IsHitTestVisible := Editable;
end;

{ TWinUIDBImage }

class procedure TWinUIDBImage.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Stretch', TWinUIPropertyKind.Enum, 'Uniform', TypeInfo(TWinUIDBImageStretch));
end;

procedure TWinUIDBImage.Initialize;
var
  Root: TWinUIGrid;
begin
  Root := TWinUIGrid.Create(Self);
  FPlaceholder := TWinUIFontIcon.Create(Self);
  FPlaceholder.Glyph := PhotoGlyph;
  FPlaceholder.FontSize := 32;
  FPlaceholder.Opacity := 0.45;
  FImage := TWinUIImage.Create(Self);
  FImage.Stretch := TWinUIStretch.Uniform;
  Root.Children.Add(FPlaceholder);
  Root.Children.Add(FImage);
  Content := Root;
  inherited;
  Width := 160;
  Height := 160;
end;

function TWinUIDBImage.GetStretch(AIndex: Integer): TWinUIDBImageStretch;
begin
  Result := TWinUIDBImageStretch(GetInt32(AIndex));
end;

procedure TWinUIDBImage.SetStretch(AIndex: Integer; AValue: TWinUIDBImageStretch);
begin
  SetInt32(AIndex, Ord(AValue));
end;

procedure TWinUIDBImage.PropertyChanged(AIndex: Integer);
begin
  inherited;
  if AIndex = 3 then
    FImage.Stretch := TWinUIStretch(GetInt32(3));
end;

procedure TWinUIDBImage.ShowField;
var
  Bytes: TBytes;
  Mem: IStream;
  Stream: IInspectable;
  Bitmap: IBitmapImage;
  Shown: Boolean;
begin
  Shown := False;
  if (Field <> nil) and Field.IsBlob and not Field.IsNull then
  begin
    Bytes := Field.AsBytes;
    if Length(Bytes) > 0 then
    begin
      Pointer(Mem) := SHCreateMemStream(@Bytes[0], Length(Bytes));
      if (Mem <> nil) and Succeeded(CreateRandomAccessStreamOverStream(Mem, 0, IID_IRandomAccessStream, Stream)) then
        try
          Bitmap := BitmapImage.New;
          (Bitmap as IBitmapSource).SetSource(Stream as IRandomAccessStream);
          (IntfOf(FImage, IImage) as IImage).put_Source(Bitmap as IImageSource);
          Shown := True;
        except
          // not a picture WinUI can read: the placeholder shows
        end;
    end;
  end;
  if not Shown then
    (IntfOf(FImage, IImage) as IImage).put_Source(nil);
  if Shown then
    FPlaceholder.Visibility := TWinUIVisibility.Collapsed
  else
    FPlaceholder.Visibility := TWinUIVisibility.Visible;
end;

procedure TWinUIDBImage.WriteField;
begin
  // The picture changes through LoadFromFile only
end;

procedure TWinUIDBImage.LoadFromFile(const AFileName: string);
begin
  if (Field = nil) or not Field.IsBlob then
    raise EDatabaseError.CreateFmt('%s needs a BLOB field', [ClassName]);
  if not FieldLink.Edit then
    Exit;
  TBlobField(Field).LoadFromFile(AFileName);
end;

{ TWinUIDBRichEdit }

class procedure TWinUIDBRichEdit.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Header', TWinUIPropertyKind.Text);
  AType.AddProperty('PlainText', TWinUIPropertyKind.Boolean, 'False');
end;

procedure TWinUIDBRichEdit.Initialize;
begin
  FRich := TWinUIRichEditBox.Create(Self);
  Content := FRich;
  FRich.TextChanged.Add(
    procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
    begin
      RichTextChanged;
    end);
  FRich.GotFocus.Add(
    procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
    begin
      FFocused := True;
    end);
  FRich.LostFocus.Add(
    procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
    begin
      FFocused := False;
      if (FShowing = 0) and (DocumentText <> FShown) and StartEdit then
        Commit;
    end);
  inherited;
  Height := 160;
end;

function TWinUIDBRichEdit.Document: ITextDocument;
begin
  Result := IntfOf(FRich.Document, ITextDocument) as ITextDocument;
end;

function TWinUIDBRichEdit.DocumentText: string;
var
  Text: HSTRING;
begin
  if GetBoolean(4) then
    Document.GetText(0, Text)
  else
    Document.GetText(TextFormatRtf, Text);
  Result := TakeHString(Text);
end;

procedure TWinUIDBRichEdit.RichTextChanged;
var
  Typed: string;
begin
  // The document also changes when it is loaded: only the user's typing counts
  if (FShowing > 0) or not FFocused or FieldLink.Editing then
    Exit;
  Typed := DocumentText;
  if Typed = FShown then
    Exit;
  if StartEdit and (DocumentText <> Typed) then
  begin
    Inc(FShowing);
    try
      Document.SetText(TextFormatRtf, WinStr(Typed));
    finally
      Dec(FShowing);
    end;
  end;
end;

procedure TWinUIDBRichEdit.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    3:
      FRich.Header := HeaderValue(GetText(3));
    4:
      Refresh;
  end;
end;

procedure TWinUIDBRichEdit.ShowField;
var
  Text: string;
  ReadOnlyNow: Boolean;
begin
  if Field <> nil then
    Text := Field.AsString
  else if DesignTime then
    Text := DesignText
  else
    Text := '';
  // A read-only RichEditBox does not take SetText
  ReadOnlyNow := FRich.IsReadOnly;
  FRich.IsReadOnly := False;
  try
    if Text.StartsWith('{\rtf') then
      Document.SetText(TextFormatRtf, WinStr(Text))
    else
      Document.SetText(0, WinStr(Text));
  finally
    FRich.IsReadOnly := ReadOnlyNow;
  end;
  FShown := DocumentText;
end;

procedure TWinUIDBRichEdit.WriteField;
begin
  FShown := DocumentText;
  Field.AsString := FShown;
end;

procedure TWinUIDBRichEdit.UpdateEditable;
begin
  FRich.IsReadOnly := not Editable;
end;

{ TWinUIDBDatePicker }

class procedure TWinUIDBDatePicker.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Header', TWinUIPropertyKind.Text);
  AType.AddProperty('PlaceholderText', TWinUIPropertyKind.Text);
end;

procedure TWinUIDBDatePicker.Initialize;
begin
  FPicker := TWinUICalendarDatePicker.Create(Self);
  FPicker.HorizontalAlignment := TWinUIHorizontalAlignment.Stretch;
  Content := FPicker;
  FPicker.DateChanged.Add(
    procedure(Sender: TObject; E: TWinUICalendarDatePickerDateChangedEventArgs)
    begin
      if (FShowing = 0) and (PickedDate <> FShownDate) and StartEdit then
      begin
        Commit;
        FShownDate := PickedDate;
      end;
    end);
  inherited;
end;

procedure TWinUIDBDatePicker.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    3:
      FPicker.Header := HeaderValue(GetText(3));
    4:
      FPicker.PlaceholderText := GetText(4);
  end;
end;

/// The picked day as ticks, -1 for none
function TWinUIDBDatePicker.PickedDate: Int64;
var
  Date: IReference_DateTime;
begin
  Date := FPicker.Date;
  if Date = nil then
    Result := -1
  else
    Result := Date.Value.UniversalTime;
end;

procedure TWinUIDBDatePicker.ShowField;
begin
  if (Field = nil) or Field.IsNull then
    FPicker.Date := nil
  else
    FPicker.Date := PropertyValue.CreateDateTime(ToWinRTDate(Field.AsDateTime)) as IReference_DateTime;
  FShownDate := PickedDate;
end;

procedure TWinUIDBDatePicker.WriteField;
var
  Date: IReference_DateTime;
begin
  Date := FPicker.Date;
  if Date = nil then
    Field.Clear
  else if Field.IsNull then
    Field.AsDateTime := FromWinRTDate(Date.Value)
  else
    // a date and time field keeps its time
    Field.AsDateTime := FromWinRTDate(Date.Value) + TimeOf(Field.AsDateTime);
end;

procedure TWinUIDBDatePicker.UpdateEditable;
begin
  FPicker.IsHitTestVisible := Editable;
  FPicker.IsTabStop := Editable;
end;

{ TWinUIDBNumberBox }

class procedure TWinUIDBNumberBox.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Header', TWinUIPropertyKind.Text);
  AType.AddProperty('PlaceholderText', TWinUIPropertyKind.Text);
  AType.AddProperty('SpinButtons', TWinUIPropertyKind.Boolean, 'True');
end;

procedure TWinUIDBNumberBox.Initialize;
begin
  FNumber := TWinUINumberBox.Create(Self);
  FNumber.HorizontalAlignment := TWinUIHorizontalAlignment.Stretch;
  FNumber.SpinButtonPlacementMode := TWinUINumberBoxSpinButtonPlacementMode.Inline;
  Content := FNumber;
  FNumber.ValueChanged.Add(
    procedure(Sender: TObject; E: TWinUINumberBoxValueChangedEventArgs)
    var
      Value: Double;
    begin
      Value := FNumber.Value;
      if (FShowing > 0) or (IsNan(Value) and IsNan(FShownValue)) or (Value = FShownValue) then
        Exit;
      if StartEdit then
      begin
        Commit;
        FShownValue := Value;
      end;
    end);
  inherited;
end;

procedure TWinUIDBNumberBox.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    3:
      FNumber.Header := HeaderValue(GetText(3));
    4:
      FNumber.PlaceholderText := GetText(4);
    5:
      if GetBoolean(5) then
        FNumber.SpinButtonPlacementMode := TWinUINumberBoxSpinButtonPlacementMode.Inline
      else
        FNumber.SpinButtonPlacementMode := TWinUINumberBoxSpinButtonPlacementMode.Hidden;
  end;
end;

procedure TWinUIDBNumberBox.ShowField;
begin
  if (Field = nil) or Field.IsNull then
    FShownValue := NaN
  else
    FShownValue := Field.AsFloat;
  FNumber.Value := FShownValue;
end;

procedure TWinUIDBNumberBox.WriteField;
begin
  if IsNan(FNumber.Value) then
    Field.Clear
  else
    Field.AsFloat := FNumber.Value;
end;

procedure TWinUIDBNumberBox.UpdateEditable;
begin
  FNumber.IsHitTestVisible := Editable;
  FNumber.IsTabStop := Editable;
end;

{ TNavigatorLink }

constructor TNavigatorLink.Create(AOwner: TWinUIDBNavigator);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TNavigatorLink.ActiveChanged;
begin
  FOwner.UpdateButtons;
end;

procedure TNavigatorLink.DataSetChanged;
begin
  FOwner.UpdateButtons;
end;

procedure TNavigatorLink.EditingChanged;
begin
  FOwner.UpdateButtons;
end;

{ TWinUIDBNavigator }

function TWinUIDBNavigator.AutomationRole: AutomationControlType;
begin
  Result := AutomationControlType.ToolBar;
end;

class procedure TWinUIDBNavigator.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('VisibleButtons', TWinUIPropertyKind.Text);
  AType.AddProperty('ConfirmDelete', TWinUIPropertyKind.Boolean, 'True');
  AType.AddEvent('Click');
end;

procedure TWinUIDBNavigator.Initialize;
var
  Kind: TWinUINavigateButton;
  Button: TWinUIButton;
  Icon: TWinUIFontIcon;
  Panel: TWinUIStackPanel;
  Prompt: TWinUITextBlock;
  Confirm: TWinUIButton;
begin
  FLink := TNavigatorLink.Create(Self);
  FPanel := TWinUIStackPanel.Create(Self);
  FPanel.Orientation := TWinUIOrientation.Horizontal;
  FPanel.Spacing := 4;
  for Kind := Low(TWinUINavigateButton) to High(TWinUINavigateButton) do
  begin
    Button := TWinUIButton.Create(Self);
    Icon := TWinUIFontIcon.Create(Self);
    Icon.Glyph := NavigatorGlyphs[Kind];
    Icon.FontSize := 14;
    Button.Content := Icon;
    Button.Width := 40;
    Button.Height := 34;
    Button.Padding := Thickness(0);
    ToolTipService.SetToolTip(IntfOf(Button, IDependencyObject) as IDependencyObject,
      PropertyValue.CreateString(WinStr(NavigatorHints[Kind])));
    // An icon says nothing to a screen reader: the hint is the button's name
    AutomationProperties.SetName(IntfOf(Button, IDependencyObject) as IDependencyObject, WinStr(NavigatorHints[Kind]));
    HookButton(Button, Kind);
    FButtons[Kind] := Button;
    FPanel.Children.Add(Button);
  end;
  // Delete asks first, in a flyout under the button
  Panel := TWinUIStackPanel.Create(Self);
  Panel.Spacing := 12;
  Prompt := TWinUITextBlock.Create(Self);
  Prompt.Text := 'Delete this record?';
  Confirm := TWinUIButton.Create(Self);
  Confirm.Content := 'Delete';
  Confirm.Click.Add(
    procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
    begin
      FConfirm.Hide;
      BtnClick(TWinUINavigateButton.Delete);
    end);
  Panel.Children.Add(Prompt);
  Panel.Children.Add(Confirm);
  FConfirm := TWinUIFlyout.Create(Self);
  FConfirm.Content := Panel;
  FButtons[TWinUINavigateButton.Delete].Flyout := FConfirm;
  Content := FPanel;
  inherited;
  HorizontalAlignment := TWinUIHorizontalAlignment.Left;
  UpdateButtons;
end;

destructor TWinUIDBNavigator.Destroy;
begin
  if FLink <> nil then
    FLink.DataSource := nil;
  inherited;
  FreeAndNil(FLink);
end;

function TWinUIDBNavigator.Link: TDataLink;
begin
  Result := FLink;
end;

procedure TWinUIDBNavigator.HookButton(AButton: TWinUIButton; AKind: TWinUINavigateButton);
begin
  AButton.Click.Add(
    procedure(Sender: TObject; E: TWinUIRoutedEventArgs)
    begin
      // With ConfirmDelete the flyout's button deletes
      if (AKind = TWinUINavigateButton.Delete) and GetBoolean(2) then
        Exit;
      BtnClick(AKind);
    end);
end;

procedure TWinUIDBNavigator.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    1:
      ShowButtons;
    2:
      if GetBoolean(2) then
        FButtons[TWinUINavigateButton.Delete].Flyout := FConfirm
      else
        FButtons[TWinUINavigateButton.Delete].Flyout := nil;
  end;
end;

procedure TWinUIDBNavigator.ShowButtons;
var
  Names: TArray<string>;
  Kind: TWinUINavigateButton;
  Shown: Boolean;
  Name: string;
begin
  Names := SplitList(GetText(1));
  for Kind := Low(TWinUINavigateButton) to High(TWinUINavigateButton) do
  begin
    Shown := Names = nil;
    for Name in Names do
      if SameText(Name, GetEnumName(TypeInfo(TWinUINavigateButton), Ord(Kind))) then
        Shown := True;
    if Shown then
      FButtons[Kind].Visibility := TWinUIVisibility.Visible
    else
      FButtons[Kind].Visibility := TWinUIVisibility.Collapsed;
  end;
end;

procedure TWinUIDBNavigator.SourceChanged;
begin
  inherited;
  UpdateButtons;
end;

procedure TWinUIDBNavigator.UpdateButtons;
var
  DS: TDataSet;
  Active, Editing, CanModify, Upper, Lower: Boolean;
  Kind: TWinUINavigateButton;
begin
  if FButtons[TWinUINavigateButton.First] = nil then
    Exit;
  if DesignTime then
  begin
    for Kind := Low(TWinUINavigateButton) to High(TWinUINavigateButton) do
      FButtons[Kind].IsEnabled := True;
    Exit;
  end;
  DS := FLink.DataSet;
  Active := FLink.Active and (DS <> nil);
  Editing := Active and FLink.Editing;
  CanModify := Active and DS.CanModify;
  Upper := Active and not DS.Bof;
  Lower := Active and not DS.Eof;
  FButtons[TWinUINavigateButton.First].IsEnabled := Upper;
  FButtons[TWinUINavigateButton.Prior].IsEnabled := Upper;
  FButtons[TWinUINavigateButton.Next].IsEnabled := Lower;
  FButtons[TWinUINavigateButton.Last].IsEnabled := Lower;
  FButtons[TWinUINavigateButton.Insert].IsEnabled := CanModify;
  FButtons[TWinUINavigateButton.Delete].IsEnabled := CanModify and not (DS.Bof and DS.Eof);
  FButtons[TWinUINavigateButton.Edit].IsEnabled := CanModify and not Editing;
  FButtons[TWinUINavigateButton.Post].IsEnabled := Editing;
  FButtons[TWinUINavigateButton.Cancel].IsEnabled := Editing;
  FButtons[TWinUINavigateButton.Refresh].IsEnabled := Active and DS.CanRefresh;
end;

procedure TWinUIDBNavigator.BtnClick(AButton: TWinUINavigateButton);
var
  DS: TDataSet;
begin
  FClicked := AButton;
  DS := FLink.DataSet;
  if (DS <> nil) and DS.Active then
    try
      case AButton of
        TWinUINavigateButton.First:
          DS.First;
        TWinUINavigateButton.Prior:
          DS.Prior;
        TWinUINavigateButton.Next:
          DS.Next;
        TWinUINavigateButton.Last:
          DS.Last;
        TWinUINavigateButton.Insert:
          DS.Insert;
        TWinUINavigateButton.Delete:
          DS.Delete;
        TWinUINavigateButton.Edit:
          DS.Edit;
        TWinUINavigateButton.Post:
          DS.Post;
        TWinUINavigateButton.Cancel:
          DS.Cancel;
        TWinUINavigateButton.Refresh:
          DS.Refresh;
      end;
    except
      on E: Exception do
        HandleError(E);
    end;
  UpdateButtons;
  Fire(0);
end;

{ TRecordLink }

constructor TRecordLink.Create(AOwner: TWinUIDBRecordControl);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TRecordLink.ActiveChanged;
begin
  FOwner.LinkActive;
end;

procedure TRecordLink.DataSetChanged;
begin
  FOwner.LinkDataSet;
end;

procedure TRecordLink.DataSetScrolled(Distance: Integer);
begin
  FOwner.LinkScrolled;
end;

procedure TRecordLink.RecordChanged(Field: TField);
begin
  FOwner.LinkRecord;
end;

procedure TRecordLink.EditingChanged;
begin
  FOwner.LinkEditing;
end;

procedure TRecordLink.LayoutChanged;
begin
  FOwner.LinkActive;
end;

{ TDBRow }

procedure TDBRow.GetIids(out AIidCount: Cardinal; out AIids: PGUID);
begin
  AIidCount := 0;
  AIids := nil;
end;

function TDBRow.GetRuntimeClassName: HSTRING;
begin
  Result := NewHString('RADWinUI.DBRow');
end;

function TDBRow.GetTrustLevel: TrustLevel;
begin
  Result := 0;
end;

function TDBRow.GetCustomProperty(AName: HSTRING): ICustomProperty;
var
  Name: string;
  Column: Integer;
begin
  Result := nil;
  if Owner = nil then
    Exit;
  Name := HStringToString(AName);
  Column := Owner.ColumnOf(Name);
  if Column >= 0 then
    Result := TDBRowProperty.Create(Name, Column);
end;

function TDBRow.GetIndexedProperty(AName: HSTRING; AType: TypeName): ICustomProperty;
begin
  Result := nil;
end;

function TDBRow.GetStringRepresentation: HSTRING;
begin
  if (Owner <> nil) and (Length(Owner.FFields) > 0) then
    Result := NewHString(Owner.ReadCell(Index, 0))
  else
    Result := nil;
end;

function TDBRow.get_Type: TypeName;
begin
  Result := NewTypeName('RADWinUI.DBRow', TypeKind.Custom);
end;

function TDBRow.add_PropertyChanged(AHandler: PropertyChangedEventHandler): EventRegistrationToken;
begin
  Inc(FNextToken);
  FHandlers := FHandlers + [AHandler];
  FTokens := FTokens + [FNextToken];
  Result.Value := FNextToken;
end;

procedure TDBRow.remove_PropertyChanged(AToken: EventRegistrationToken);
var
  I: Integer;
begin
  for I := High(FTokens) downto 0 do
    if FTokens[I] = AToken.Value then
    begin
      Delete(FHandlers, I, 1);
      Delete(FTokens, I, 1);
    end;
end;

function TDBRow.RowIndex: Integer;
begin
  Result := Index;
end;

function TDBRow.RowOwner: TWinUIDBRecordControl;
begin
  Result := Owner;
end;

procedure TDBRow.NotifyAll;
var
  Args: IPropertyChangedEventArgs;
  Handler: PropertyChangedEventHandler;
begin
  if FHandlers = nil then
    Exit;
  Args := PropertyChangedEventArgs.New(WinStr(''));
  for Handler in Copy(FHandlers) do
    Handler.Invoke(Self as IInspectable, Args);
end;

{ TDBRowProperty }

constructor TDBRowProperty.Create(const AName: string; AColumn: Integer);
begin
  inherited Create;
  FName := AName;
  FColumn := AColumn;
end;

procedure TDBRowProperty.GetIids(out AIidCount: Cardinal; out AIids: PGUID);
begin
  AIidCount := 0;
  AIids := nil;
end;

function TDBRowProperty.GetRuntimeClassName: HSTRING;
begin
  Result := NewHString('RADWinUI.DBRowProperty');
end;

function TDBRowProperty.GetTrustLevel: TrustLevel;
begin
  Result := 0;
end;

function TDBRowProperty.get_Type: TypeName;
begin
  Result := NewTypeName('String', TypeKind.Primitive);
end;

function TDBRowProperty.get_Name: HSTRING;
begin
  Result := NewHString(FName);
end;

function TDBRowProperty.GetValue(ATarget: IInspectable): IInspectable;
var
  Row: IDBRow;
begin
  if Supports(ATarget, IDBRow, Row) and (Row.RowOwner <> nil) then
    Result := PropertyValue.CreateString(WinStr(Row.RowOwner.ReadCell(Row.RowIndex, FColumn)))
  else
    Result := nil;
end;

procedure TDBRowProperty.SetValue(ATarget: IInspectable; AValue: IInspectable);
var
  Row: IDBRow;
  Value: TWinValue;
begin
  Value := AValue;
  if Supports(ATarget, IDBRow, Row) and (Row.RowOwner <> nil) then
    Row.RowOwner.WriteCell(Row.RowIndex, FColumn, Value.AsString);
end;

function TDBRowProperty.GetIndexedValue(ATarget: IInspectable; AIndex: IInspectable): IInspectable;
begin
  Result := nil;
end;

procedure TDBRowProperty.SetIndexedValue(ATarget: IInspectable; AValue: IInspectable; AIndex: IInspectable);
begin
end;

function TDBRowProperty.get_CanWrite: Boolean;
begin
  Result := True;
end;

function TDBRowProperty.get_CanRead: Boolean;
begin
  Result := True;
end;

{ TDBRows }

constructor TDBRows.Create(AOwner: TWinUIDBRecordControl);
begin
  inherited Create;
  FOwner := AOwner;
end;

destructor TDBRows.Destroy;
begin
  Clear;
  inherited;
end;

function TDBRows.GetCount: Integer;
begin
  Result := FCount;
end;

function TDBRows.GetBindable(AIndex: Integer): IInspectable;
begin
  Result := FRows[AIndex];
end;

procedure TDBRows.SetRow(AIndex: Integer; AObject: TObject);
begin
  FObjects[AIndex] := AObject;
  if AObject = nil then
    FRows[AIndex] := nil
  else
    FRows[AIndex] := TDBRow(AObject) as IInspectable;
end;

procedure TDBRows.Clear;
var
  I: Integer;
begin
  // XAML may hold rows a while longer: they read nothing after this
  for I := 0 to FCount - 1 do
    TDBRow(FObjects[I]).Owner := nil;
  FRows := nil;
  FObjects := nil;
  FCount := 0;
end;

procedure TDBRows.Add;
var
  Row: TDBRow;
begin
  if FCount = Length(FRows) then
  begin
    SetLength(FRows, Max(32, FCount * 2));
    SetLength(FObjects, Length(FRows));
  end;
  Row := TDBRow.Create;
  Row.Owner := FOwner;
  Row.Index := FCount;
  SetRow(FCount, Row);
  Inc(FCount);
end;

procedure TDBRows.Insert(AIndex: Integer);
var
  I: Integer;
  Row: TDBRow;
  Keep: IInspectable;
begin
  Add;
  Row := TDBRow(FObjects[FCount - 1]);
  // The shift overwrites FRows[FCount - 1], the new row's only reference
  Keep := FRows[FCount - 1];
  for I := FCount - 1 downto AIndex + 1 do
  begin
    SetRow(I, FObjects[I - 1]);
    TDBRow(FObjects[I]).Index := I;
  end;
  Row.Index := AIndex;
  SetRow(AIndex, Row);
  Changed(CollectionChange.ItemInserted, AIndex);
end;

procedure TDBRows.Delete(AIndex: Integer);
var
  I: Integer;
begin
  TDBRow(FObjects[AIndex]).Owner := nil;
  for I := AIndex to FCount - 2 do
  begin
    SetRow(I, FObjects[I + 1]);
    TDBRow(FObjects[I]).Index := I;
  end;
  Dec(FCount);
  SetRow(FCount, nil);
  Changed(CollectionChange.ItemRemoved, AIndex);
end;

procedure TDBRows.Reset;
begin
  Changed(CollectionChange.Reset, 0);
end;

procedure TDBRows.RowChanged(AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex < FCount) then
    TDBRow(FObjects[AIndex]).NotifyAll;
end;

{ TWinUIDBRecordControl }

procedure TWinUIDBRecordControl.Initialize;
begin
  FLink := TRecordLink.Create(Self);
  FRows := TDBRows.Create(Self);
  FInsertRow := -1;
  inherited;
end;

destructor TWinUIDBRecordControl.Destroy;
begin
  if FLink <> nil then
    FLink.DataSource := nil;
  if FListView <> nil then
  try
    FListView.ItemsSource := IInspectable(nil);
  except
    // A control without an owner window (XamlReader.Load in the preview) goes after XAML shut down
    on EWinRTError do ;
  end;
  inherited;
  FreeAndNil(FRows);
  FreeAndNil(FLink);
end;

function TWinUIDBRecordControl.Link: TDataLink;
begin
  Result := FLink;
end;

procedure TWinUIDBRecordControl.AttachList(AList: TWinUIListViewBase);
begin
  if FListView <> nil then
    FListView.ItemsSource := IInspectable(nil);
  FListView := AList;
  FListView.ItemsSource := FRows;
  FListView.SelectionChanged.Add(
    procedure(Sender: TObject; E: TWinUISelectionChangedEventArgs)
    begin
      ListSelectionChanged;
    end);
end;

procedure TWinUIDBRecordControl.SourceChanged;
begin
  inherited;
  Reload;
end;

function TWinUIDBRecordControl.ChooseFields(ADataSet: TDataSet): TArray<TField>;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to ADataSet.FieldCount - 1 do
    Result := Result + [ADataSet.Fields[I]];
end;

procedure TWinUIDBRecordControl.ColumnsChanged;
begin
end;

function TWinUIDBRecordControl.ColumnOf(const AName: string): Integer;
begin
  // The templates made in code bind by column number
  if AName.StartsWith(ColumnPrefix) then
    Exit(StrToIntDef(Copy(AName, Length(ColumnPrefix) + 1, MaxInt), -1));
  if DesignTime then
  begin
    for Result := 0 to High(FDesignNames) do
      if SameText(FDesignNames[Result], AName) then
        Exit;
    // the designer shows every binding name as its own value
    FDesignNames := FDesignNames + [AName];
    Exit(High(FDesignNames));
  end;
  for Result := 0 to High(FFields) do
    if SameText(FFields[Result].FieldName, AName) then
      Exit;
  Result := -1;
end;

function TWinUIDBRecordControl.CellText(AField: TField): string;
begin
  Result := FieldText(AField, True);
end;

function TWinUIDBRecordControl.RowsReadOnly: Boolean;
begin
  Result := True;
end;

function TWinUIDBRecordControl.RowCount: Integer;
begin
  Result := FRows.Count;
end;

function TWinUIDBRecordControl.Cell(ARow, AColumn: Integer): string;
begin
  Result := ReadCell(ARow, AColumn);
end;

function TWinUIDBRecordControl.ReadRow: TArray<string>;
var
  I: Integer;
begin
  SetLength(Result, Length(FFields));
  for I := 0 to High(FFields) do
    Result[I] := CellText(FFields[I]);
end;

function TWinUIDBRecordControl.ReadCell(ARow, AColumn: Integer): string;
var
  DS: TDataSet;
begin
  Result := '';
  if DesignTime then
  begin
    if (AColumn >= 0) and (AColumn <= High(FDesignNames)) then
      Result := FDesignNames[AColumn];
    Exit;
  end;
  if (AColumn < 0) or (AColumn > High(FFields)) or (ARow < 0) or (ARow >= FRows.Count) then
    Exit;
  DS := DataSet;
  if (DS <> nil) and DS.Active and not FLoading and (ARow = CurrentIndex) then
    Exit(CellText(FFields[AColumn]));
  if (ARow <= High(FCells)) and (AColumn <= High(FCells[ARow])) then
    Result := FCells[ARow][AColumn];
end;

procedure TWinUIDBRecordControl.Reload;
var
  DS: TDataSet;
  NewFields: TArray<TField>;
  Mark: TBookmark;
  Count, I: Integer;
  Same: Boolean;
begin
  if FLoading then
    Exit;
  FInsertRow := -1;
  FRows.Clear;
  // XAML must not ask for the old rows: EnableControls below runs other controls, which can lay out the list
  FRows.Reset;
  FBookmarks := nil;
  FCells := nil;
  if DesignTime then
  begin
    ColumnsChanged;
    for I := 1 to 3 do
      FRows.Add;
    FRows.Reset;
    Exit;
  end;
  DS := DataSet;
  if (DS = nil) or not DS.Active then
  begin
    if FFields <> nil then
    begin
      FFields := nil;
      ColumnsChanged;
    end;
    FRows.Reset;
    Exit;
  end;
  NewFields := ChooseFields(DS);
  Same := Length(NewFields) = Length(FFields);
  if Same then
    for I := 0 to High(NewFields) do
      if NewFields[I] <> FFields[I] then
        Same := False;
  if not Same then
  begin
    FFields := NewFields;
    ColumnsChanged;
  end;
  if DS.State <> dsBrowse then
  begin
    FRows.Reset;
    Exit;
  end;
  FLoading := True;
  try
    Mark := DS.Bookmark;
    DS.DisableControls;
    try
      Count := 0;
      DS.First;
      while not DS.Eof do
      begin
        if Count = Length(FBookmarks) then
        begin
          SetLength(FBookmarks, Max(32, Count * 2));
          SetLength(FCells, Length(FBookmarks));
        end;
        FBookmarks[Count] := DS.Bookmark;
        FCells[Count] := ReadRow;
        FRows.Add;
        Inc(Count);
        DS.Next;
      end;
      SetLength(FBookmarks, Count);
      SetLength(FCells, Count);
    finally
      if (Mark <> nil) and DS.BookmarkValid(Mark) then
        DS.Bookmark := Mark;
      DS.EnableControls;
    end;
  finally
    FLoading := False;
  end;
  FRows.Reset;
  LinkScrolled;
end;

function TWinUIDBRecordControl.CurrentIndex: Integer;
var
  DS: TDataSet;
  Mark: TBookmark;
  I: Integer;
begin
  Result := -1;
  DS := DataSet;
  if (DS = nil) or not DS.Active then
    Exit;
  if DS.State = dsInsert then
    Exit(FInsertRow);
  if DS.IsSequenced then
  begin
    Result := DS.RecNo - 1;
    if (Result >= 0) and (Result <= High(FBookmarks)) and (FBookmarks[Result] <> nil) and
      (DS.CompareBookmarks(FBookmarks[Result], DS.Bookmark) = 0) then
      Exit;
  end;
  Mark := DS.Bookmark;
  if Mark = nil then
    Exit(-1);
  for I := 0 to High(FBookmarks) do
    if (FBookmarks[I] <> nil) and (DS.CompareBookmarks(FBookmarks[I], Mark) = 0) then
      Exit(I);
  Result := -1;
end;

procedure TWinUIDBRecordControl.LinkActive;
begin
  Reload;
end;

procedure TWinUIDBRecordControl.LinkDataSet;
var
  DS: TDataSet;
begin
  if FLoading then
    Exit;
  DS := DataSet;
  if (DS <> nil) and (DS.State = dsInsert) then
    ShowInsertRow
  else if (DS <> nil) and (DS.State in [dsEdit]) then
    LinkRecord
  else
    Reload;
end;

procedure TWinUIDBRecordControl.LinkScrolled;
var
  Index: Integer;
  Row: IInspectable;
begin
  if FLoading or (FListView = nil) then
    Exit;
  Index := CurrentIndex;
  FSyncing := True;
  try
    FListView.SelectedIndex := Index;
    if (Index >= 0) and (Index < FRows.Count) then
    begin
      Row := FRows.GetBindable(Index);
      (IntfOf(FListView, IListViewBase) as IListViewBase).ScrollIntoView(Row);
    end;
  finally
    FSyncing := False;
  end;
end;

procedure TWinUIDBRecordControl.LinkRecord;
var
  Index: Integer;
begin
  if FLoading then
    Exit;
  Index := CurrentIndex;
  if (Index >= 0) and (Index <= High(FCells)) then
    FCells[Index] := ReadRow;
  FRows.RowChanged(Index);
end;

procedure TWinUIDBRecordControl.LinkEditing;
var
  DS: TDataSet;
begin
  if FLoading then
    Exit;
  DS := DataSet;
  if (DS <> nil) and (DS.State = dsInsert) and (FInsertRow < 0) then
    ShowInsertRow
  else if (FInsertRow >= 0) and ((DS = nil) or (DS.State <> dsInsert)) then
    Reload;
end;

procedure TWinUIDBRecordControl.ShowInsertRow;
var
  DS: TDataSet;
  Index: Integer;
begin
  if FInsertRow >= 0 then
  begin
    FRows.RowChanged(FInsertRow);
    Exit;
  end;
  DS := DataSet;
  // Append goes to the end, Insert before the current record
  if DS.Eof then
    Index := FRows.Count
  else
  begin
    Index := -1;
    if FListView <> nil then
      Index := FListView.SelectedIndex;
    if (Index < 0) or (Index > FRows.Count) then
      Index := FRows.Count;
  end;
  FInsertRow := Index;
  Insert([TBookmark(nil)], FBookmarks, Index);
  Insert([TArray<string>(nil)], FCells, Index);
  FRows.Insert(Index);
  LinkScrolled;
end;

procedure TWinUIDBRecordControl.ListSelectionChanged;
var
  Index: Integer;
  DS: TDataSet;
  Target: TBookmark;
begin
  if FSyncing or FLoading or (FListView = nil) then
    Exit;
  Index := FListView.SelectedIndex;
  if (Index < 0) or (Index > High(FBookmarks)) or (FBookmarks[Index] = nil) or (Index = CurrentIndex) then
    Exit;
  DS := DataSet;
  if (DS = nil) or not DS.Active then
    Exit;
  Target := FBookmarks[Index];
  try
    // Leaving a record posts it, as in the VCL grid
    if DS.State in dsEditModes then
      DS.Post;
    if DS.BookmarkValid(Target) then
      DS.Bookmark := Target;
  except
    on E: Exception do
    begin
      HandleError(E);
      LinkScrolled;
    end;
  end;
end;

procedure TWinUIDBRecordControl.WriteCell(ARow, AColumn: Integer; const AValue: string);
var
  DS: TDataSet;
  F: TField;
begin
  if RowsReadOnly or DesignTime or FLoading or (AColumn < 0) or (AColumn > High(FFields)) then
    Exit;
  DS := DataSet;
  if (DS = nil) or not DS.Active then
    Exit;
  F := FFields[AColumn];
  if F.ReadOnly or (FieldText(F, False) = AValue) and (ARow = CurrentIndex) then
    Exit;
  try
    if ARow <> CurrentIndex then
    begin
      if (ARow > High(FBookmarks)) or (FBookmarks[ARow] = nil) then
        Exit;
      if DS.State in dsEditModes then
        DS.Post;
      DS.Bookmark := FBookmarks[ARow];
      if FieldText(F, False) = AValue then
        Exit;
    end;
    if not (DS.State in dsEditModes) then
      DS.Edit;
    SetFieldText(F, AValue);
  except
    on E: Exception do
    begin
      HandleError(E);
      FRows.RowChanged(ARow);
    end;
  end;
end;

{ TWinUIDBGrid }

function TWinUIDBGrid.AutomationRole: AutomationControlType;
begin
  Result := AutomationControlType.Group;
end;

class procedure TWinUIDBGrid.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('Columns', TWinUIPropertyKind.Text);
  AType.SetEditor('Columns', 'datafields');
  AType.AddProperty('ReadOnly', TWinUIPropertyKind.Boolean, 'False');
  AType.AddProperty('SortOnHeaderClick', TWinUIPropertyKind.Boolean, 'True');
  AType.AddProperty('RowHeight', TWinUIPropertyKind.Double, '36');
end;

const
  GridXaml =
    '<Grid %s BorderThickness="1" CornerRadius="4" ' +
    'BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}" ' +
    'Background="{ThemeResource CardBackgroundFillColorDefaultBrush}">' +
    '<ScrollViewer HorizontalScrollBarVisibility="Auto" HorizontalScrollMode="Enabled" ' +
    'VerticalScrollBarVisibility="Disabled" VerticalScrollMode="Disabled">' +
    '<Grid><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>' +
    '<Border x:Name="HeaderHost" BorderThickness="0,0,0,1" Padding="4,0,0,0" ' +
    'BorderBrush="{ThemeResource DividerStrokeColorDefaultBrush}" ' +
    'Background="{ThemeResource SubtleFillColorSecondaryBrush}"/>' +
    '<ListView x:Name="Rows" Grid.Row="1" SelectionMode="Single" Padding="0">' +
    '<ListView.ItemContainerStyle><Style TargetType="ListViewItem">' +
    '<Setter Property="Padding" Value="0"/><Setter Property="MinHeight" Value="0"/>' +
    '<Setter Property="HorizontalContentAlignment" Value="Stretch"/></Style></ListView.ItemContainerStyle>' +
    '</ListView></Grid></ScrollViewer></Grid>';

function FindPart(const ARoot: IInspectable; const AName: string): IInspectable;
begin
  Result := (ARoot as IFrameworkElement).FindName(WinStr(AName));
end;

procedure TWinUIDBGrid.Initialize;
var
  Root: IInspectable;
begin
  Root := RADWinUI.Abi.XamlReader.Load(WinStr(Format(GridXaml, [XamlNamespaces])));
  Content := Root;
  FHeaderHost := TWinUIBorder(TWinUIObject.Wrap(Self, FindPart(Root, 'HeaderHost'), TWinUIBorder));
  FHeaderHost.Tapped.Add(
    procedure(Sender: TObject; E: TWinUITappedRoutedEventArgs)
    begin
      HeaderTapped(E.Intf.GetPosition(IntfOf(FHeaderHost, IUIElement) as IUIElement).X);
    end);
  inherited;
  AttachList(TWinUIListViewBase(TWinUIObject.Wrap(Self, FindPart(Root, 'Rows'), TWinUIListView)));
  Width := 480;
  Height := 240;
end;

procedure TWinUIDBGrid.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    1:
      Reload;
    2, 4:
      BuildTemplate;
  end;
end;

function TWinUIDBGrid.RowsReadOnly: Boolean;
begin
  Result := GetBoolean(2);
end;

function TWinUIDBGrid.CellText(AField: TField): string;
begin
  // Editable cells show what the field takes back
  Result := FieldText(AField, RowsReadOnly);
end;

/// Columns: "Field:Width, Field, ..."
procedure ParseColumns(const AText: string; out ANames: TArray<string>; out AWidths: TArray<Double>);
var
  Item: string;
  Colon: Integer;
begin
  ANames := nil;
  AWidths := nil;
  for Item in SplitList(AText) do
  begin
    Colon := Pos(':', Item);
    if Colon > 0 then
    begin
      ANames := ANames + [Trim(Copy(Item, 1, Colon - 1))];
      AWidths := AWidths + [StrToFloatDef(Trim(Copy(Item, Colon + 1, MaxInt)), 0, TFormatSettings.Invariant)];
    end
    else
    begin
      ANames := ANames + [Item];
      AWidths := AWidths + [0];
    end;
  end;
end;

function TWinUIDBGrid.ChooseFields(ADataSet: TDataSet): TArray<TField>;
var
  Names: TArray<string>;
  Widths: TArray<Double>;
  I: Integer;
  F: TField;
begin
  ParseColumns(GetText(1), Names, Widths);
  Result := nil;
  FWidths := nil;
  if Names = nil then
  begin
    for I := 0 to ADataSet.FieldCount - 1 do
      if ADataSet.Fields[I].Visible then
      begin
        Result := Result + [ADataSet.Fields[I]];
        FWidths := FWidths + [0];
      end;
  end
  else
    for I := 0 to High(Names) do
    begin
      F := ADataSet.FindField(Names[I]);
      if F <> nil then
      begin
        Result := Result + [F];
        FWidths := FWidths + [Widths[I]];
      end;
    end;
end;

function TWinUIDBGrid.ColumnWidth(AIndex: Integer): Double;
begin
  if (AIndex <= High(FWidths)) and (FWidths[AIndex] > 0) then
    Result := FWidths[AIndex]
  else if (AIndex <= High(FFields)) and not DesignTime then
    Result := EnsureRange(FFields[AIndex].DisplayWidth * 8 + 16, 64, 320)
  else
    Result := 140;
end;

procedure TWinUIDBGrid.ColumnsChanged;
var
  Names: TArray<string>;
  Widths: TArray<Double>;
  I: Integer;
begin
  if DesignTime then
  begin
    ParseColumns(GetText(1), Names, Widths);
    if Names = nil then
      Names := ['Field1', 'Field2', 'Field3'];
    FDesignNames := nil;
    FWidths := Widths;
    for I := 0 to High(Names) do
      FDesignNames := FDesignNames + [Names[I]];
  end;
  BuildTemplate;
end;

procedure TWinUIDBGrid.BuildTemplate;
var
  Count, I: Integer;
  Columns, Header, Cells, Align, Title, Binding: string;
  RightAligned: Boolean;
  HeaderElement: IInspectable;
begin
  if FHeaderHost = nil then
    Exit;
  if DesignTime then
    Count := Length(FDesignNames)
  else
    Count := Length(FFields);
  Columns := '';
  Header := '';
  Cells := '';
  for I := 0 to Count - 1 do
  begin
    Columns := Columns + Format('<ColumnDefinition Width="%s"/>', [InvariantNumber(ColumnWidth(I))]);
    RightAligned := not DesignTime and (FFields[I].Alignment = taRightJustify);
    if RightAligned then
      Align := 'Right'
    else
      Align := 'Left';
    if DesignTime then
      Title := FDesignNames[I]
    else
      Title := FFields[I].DisplayLabel;
    Header := Header + Format('<TextBlock Grid.Column="%d" Text="%s" Margin="8,8" FontWeight="SemiBold" ' +
      'TextTrimming="CharacterEllipsis" TextAlignment="%s"/>', [I, XmlText(Title), Align]);
    if DesignTime then
      Binding := FDesignNames[I]
    else
      Binding := ColumnPrefix + IntToStr(I);
    if RowsReadOnly or DesignTime then
      Cells := Cells + Format('<TextBlock Grid.Column="%d" Text="{Binding %s}" Margin="8,0" ' +
        'VerticalAlignment="Center" TextTrimming="CharacterEllipsis" TextAlignment="%s"/>',
        [I, Binding, Align])
    else
      Cells := Cells + Format('<TextBox Grid.Column="%d" Text="{Binding %s, Mode=TwoWay}" BorderThickness="0" ' +
        'Background="Transparent" MinHeight="0" Padding="8,4" VerticalAlignment="Center" TextAlignment="%s"/>',
        [I, Binding, Align]);
  end;
  HeaderElement := RADWinUI.Abi.XamlReader.Load(WinStr(Format(
    '<Grid %s><Grid.ColumnDefinitions>%s</Grid.ColumnDefinitions>%s</Grid>', [XamlNamespaces, Columns, Header])));
  FHeaderHost.Child := TWinUIUIElement(TWinUIObject.Wrap(Self, HeaderElement, TWinUIUIElement));
  if ListView <> nil then
    (IntfOf(ListView, IItemsControl) as IItemsControl).ItemTemplate :=
      RADWinUI.Abi.XamlReader.Load(WinStr(Format(
      '<DataTemplate %s><Grid Height="%s"><Grid.ColumnDefinitions>%s</Grid.ColumnDefinitions>%s</Grid></DataTemplate>',
      [XamlNamespaces, InvariantNumber(Max(16, GetDouble(4))), Columns, Cells]))) as IDataTemplate;
end;

procedure TWinUIDBGrid.HeaderTapped(AX: Double);
var
  I: Integer;
  Left: Double;
  DS: TDataSet;
  Info: PPropInfo;
  FieldName, Sort: string;
begin
  if not GetBoolean(3) or DesignTime then
    Exit;
  DS := DataSet;
  if (DS = nil) or not DS.Active then
    Exit;
  Left := 4;
  for I := 0 to High(FFields) do
  begin
    if (AX >= Left) and (AX < Left + ColumnWidth(I)) then
    begin
      if FFields[I].FieldKind <> fkData then
        Exit;
      // Datasets that sort by IndexFieldNames: FireDAC, TClientDataSet
      Info := GetPropInfo(DS, 'IndexFieldNames');
      if Info = nil then
        Exit;
      FieldName := FFields[I].FieldName;
      // FireDAC also sorts down: a second click on the same column
      if SameText(FSortField, FieldName) and DS.ClassName.StartsWith('TFD') then
        Sort := FieldName + ':D'
      else
        Sort := FieldName;
      try
        if DS.State in dsEditModes then
          DS.Post;
        SetStrProp(DS, Info, Sort);
        if Sort.EndsWith(':D') then
          FSortField := ''
        else
          FSortField := FieldName;
      except
        on E: Exception do
          HandleError(E);
      end;
      Exit;
    end;
    Left := Left + ColumnWidth(I);
  end;
end;

{ TWinUIDBCtrlGrid }

function TWinUIDBCtrlGrid.AutomationRole: AutomationControlType;
begin
  Result := AutomationControlType.Group;
end;

class procedure TWinUIDBCtrlGrid.DefineType(AType: TWinUICustomType);
begin
  inherited;
  AType.AddProperty('ItemTemplate', TWinUIPropertyKind.Value);
  AType.AddProperty('Tiles', TWinUIPropertyKind.Boolean, 'False');
  AType.AddProperty('ReadOnly', TWinUIPropertyKind.Boolean, 'False');
end;

procedure TWinUIDBCtrlGrid.Initialize;
begin
  inherited;
  BuildList;
  Width := 360;
  Height := 320;
end;

function TWinUIDBCtrlGrid.GetValueProp(AIndex: Integer): TWinValue;
begin
  Result := GetPropValue(AIndex);
end;

procedure TWinUIDBCtrlGrid.SetValueProp(AIndex: Integer; const AValue: TWinValue);
begin
  SetPropValue(AIndex, AValue);
end;

procedure TWinUIDBCtrlGrid.BuildList;
const
  ListXaml = '<%0:s %1:s SelectionMode="Single"><%0:s.ItemContainerStyle><Style TargetType="%0:sItem">' +
    '<Setter Property="HorizontalContentAlignment" Value="Stretch"/></Style></%0:s.ItemContainerStyle></%0:s>';
var
  Kind: string;
  List: IInspectable;
begin
  if GetBoolean(2) then
    Kind := 'GridView'
  else
    Kind := 'ListView';
  List := RADWinUI.Abi.XamlReader.Load(WinStr(Format(ListXaml, [Kind, XamlNamespaces])));
  Content := List;
  if GetBoolean(2) then
    AttachList(TWinUIListViewBase(TWinUIObject.Wrap(Self, List, TWinUIGridView)))
  else
    AttachList(TWinUIListViewBase(TWinUIObject.Wrap(Self, List, TWinUIListView)));
  ApplyTemplate;
  Reload;
end;

procedure TWinUIDBCtrlGrid.ApplyTemplate;
var
  Template: IDataTemplate;
  Lines: string;
  I: Integer;
begin
  if ListView = nil then
    Exit;
  if not Supports(GetPropValue(1), IDataTemplate, Template) then
  begin
    // Without a template each record shows its first fields
    Lines := '';
    for I := 0 to Min(2, High(FFields)) do
      if I = 0 then
        Lines := Lines + Format('<TextBlock Text="{Binding %s%d}" FontWeight="SemiBold"/>', [ColumnPrefix, I])
      else
        Lines := Lines + Format('<TextBlock Text="{Binding %s%d}" Opacity="0.7"/>', [ColumnPrefix, I]);
    if Lines = '' then
      Lines := Format('<TextBlock Text="{Binding %s0}"/>', [ColumnPrefix]);
    Template := RADWinUI.Abi.XamlReader.Load(WinStr(Format(
      '<DataTemplate %s><StackPanel Padding="12,8" Spacing="2">%s</StackPanel></DataTemplate>',
      [XamlNamespaces, Lines]))) as IDataTemplate;
  end;
  (IntfOf(ListView, IItemsControl) as IItemsControl).ItemTemplate := Template;
end;

procedure TWinUIDBCtrlGrid.PropertyChanged(AIndex: Integer);
begin
  inherited;
  case AIndex of
    1:
      ApplyTemplate;
    2:
      BuildList;
  end;
end;

procedure TWinUIDBCtrlGrid.ColumnsChanged;
begin
  if not Supports(GetPropValue(1), IDataTemplate) then
    ApplyTemplate;
end;

function TWinUIDBCtrlGrid.RowsReadOnly: Boolean;
begin
  Result := GetBoolean(3);
end;

initialization
  ModuleList := TModuleList.Create;
  TWinUICustomControls.Register(TWinUIDBGrid, 'DBGrid', DataControlsCategory);
  TWinUICustomControls.Register(TWinUIDBNavigator, 'DBNavigator', DataControlsCategory);
  TWinUICustomControls.Register(TWinUIDBText, 'DBText', DataControlsCategory);
  TWinUICustomControls.Register(TWinUIDBEdit, 'DBEdit', DataControlsCategory);
  TWinUICustomControls.Register(TWinUIDBMemo, 'DBMemo', DataControlsCategory);
  TWinUICustomControls.Register(TWinUIDBImage, 'DBImage', DataControlsCategory);
  TWinUICustomControls.Register(TWinUIDBListBox, 'DBListBox', DataControlsCategory);
  TWinUICustomControls.Register(TWinUIDBComboBox, 'DBComboBox', DataControlsCategory);
  TWinUICustomControls.Register(TWinUIDBCheckBox, 'DBCheckBox', DataControlsCategory);
  TWinUICustomControls.Register(TWinUIDBRadioGroup, 'DBRadioGroup', DataControlsCategory);
  TWinUICustomControls.Register(TWinUIDBLookupListBox, 'DBLookupListBox', DataControlsCategory);
  TWinUICustomControls.Register(TWinUIDBLookupComboBox, 'DBLookupComboBox', DataControlsCategory);
  TWinUICustomControls.Register(TWinUIDBRichEdit, 'DBRichEdit', DataControlsCategory);
  TWinUICustomControls.Register(TWinUIDBCtrlGrid, 'DBCtrlGrid', DataControlsCategory);
  TWinUICustomControls.Register(TWinUIDBDatePicker, 'DBDatePicker', DataControlsCategory);
  TWinUICustomControls.Register(TWinUIDBNumberBox, 'DBNumberBox', DataControlsCategory);
  TWinUICustomControls.Register(TWinUIDBToggleSwitch, 'DBToggleSwitch', DataControlsCategory);

finalization
  FreeAndNil(ModuleList);

end.
