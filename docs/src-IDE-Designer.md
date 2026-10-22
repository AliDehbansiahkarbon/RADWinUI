# Visual designer

`.xaml` files open in a Design view next to Code (F12 switches between them). Design shows the real WinUI rendering, hosted in the preview process so a WinUI problem never affects RAD Studio. Every change is a small, undoable edit of the XAML text, which stays the single source of truth.

![The designer with the Tool Palette, Object Inspector and Structure view](images/ide-gallery-palette-light.png)

- **Selection.** Click an element in Design to select it. The selection follows into the Object Inspector and the Structure view, and back.
- **Tool Palette.** Pick a control and click where it goes (a StackPanel position, or a Grid row and column), or drag it in. Drag the selected element to move it, Delete removes it, Ctrl+C, Ctrl+V, Ctrl+Z and Ctrl+Y work as in a VCL form.
- **Object Inspector.** Properties and events of the selected element, see [docs/OBJECT-INSPECTOR.md](OBJECT-INSPECTOR.md).
- **Structure view.** The element tree with the same icons as the Tool Palette.

| Unit | Role |
| --- | --- |
| `RADWinUI.Designer.XamlEdit` | Minimal text edits: change, insert, move and delete elements and attributes |
| `RADWinUI.Designer.Model` | Type index, property and event lists, handler creation in the window unit |
| `RADWinUI.Designer.Palette`, `.PaletteIcons` | Tool Palette entries, categories and self-painted icons |
| `RADWinUI.Designer.ObjectInspector`, `.Structure` | ToolsAPI adapters for the native Object Inspector and Structure view |
| `RADWinUI.Designer.Inspector` | An older IDE-free property panel, kept for its tests |

The IDE-free units are tested outside the IDE by `tests\Designer\XamlEditTest` and `tests\Designer\DesignerModelTest`, `scripts\Test-Preview.ps1` checks selection, insert, move and delete end to end against the real preview host.
