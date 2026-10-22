# Native Object Inspector integration

![The Object Inspector showing a NavigationViewItem selected in the designer](images/ide-gallery-palette-light.png)

## Implementation

`RADWinUI.Designer.ObjectInspector` supplies XAML selections to Delphi's normal
Object Inspector. The extra RADWinUI Properties dock and Tools menu entry are
removed. No WinUI object or per-control VCL proxy enters the IDE process.

| Native API | RADWinUI behavior |
| --- | --- |
| `IOTAPropInspServices.Selection` | Publish the selected XAML element without changing editor focus. |
| `IOTAPropInspSelection` | Metadata-backed property lists and inspector state. |
| `IOTAPropInspPages` | Properties and Events tabs. |
| `IOTAPropInspInstanceList` | Select the Window or any visual XAML element by name/type. Unnamed elements include their source position. |
| `DesignIntf.IProperty` | Read attributes, offer Boolean, enum and Align lists, queue minimal undoable attribute edits. |
| `IProperty80` | Event ellipsis/double-click creates or opens a Pascal handler. Typing a method name assigns it, clearing removes its explicit XAML assignment. |

The adapter reuses `TDesignerTypeIndex` and the existing property/event writers.
XAML editor buffers remain the source of truth. `Align` is offered for direct
Grid children. Event code uses the existing generated Pascal base-unit fields.
The IDE supplies the editing controls, style, keyboard editing and tab UI.

## Lifetime and updates

Each published selection owns property snapshots. Replaced snapshots remain
readable but become read-only through a generation guard. Native property,
event and control-selector callbacks queue work for the designer timer rather
than navigating or replacing the native selection during enumeration.

Page, active property and expansion state persist across RADWinUI selections.
Returning from Code refreshes the inspector from current source. Selection in
the designer, Structure view and inspector control selector stays coordinated.
Closing or hiding Design clears only RADWinUI's own native selection, an existing
VCL selection is left intact. Package teardown detaches callbacks before releasing
frames. Inspector service errors go to `%TEMP%\RADWinUI\ide.log` without stopping
the renderer.

The former IDE-free `RADWinUI.Designer.Inspector` panel remains for its existing
tests, it is no longer part of the IDE packages.

## Validation status

The adapter is part of both design packages. Checked by hand in the 64-bit IDE:
editing properties, creating event handlers from the Events tab, and F9/Ctrl+F9
while Design has focus.

The primary API sources used are the installed RAD Studio 13 files
`source\ToolsAPI\PropInspAPI.pas`, `DesignIntf.pas` and `ToolsAPI.pas`.
