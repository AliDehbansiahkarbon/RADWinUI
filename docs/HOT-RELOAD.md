# Hot reload

Edit a `.xaml` file in the IDE while the app runs, and its windows, pages and user controls show the change at once, without a rebuild and without losing their data. It works in the code editor, in the Design view and in both side by side.

## Using it

1. Build and run the app in **Debug** (F9, or Run without debugging).
2. Edit a `.xaml` file of the project in the IDE.
3. After a short pause the running app shows the change. A small bar at the top of its window says *Hot reload: Reloaded MainWindow.xaml* and goes away by itself.

Tools > Options > Third Party > **RADWinUI** > Hot reload picks when the IDE sends the XAML:

| Setting | |
| --- | --- |
| While typing (default) | half a second after the last change in the editor or the designer |
| When a .xaml file is saved | each time the file is saved |
| Off | never |

## What reloads

The XAML of the content: layout, styles, texts, colours, bindings, new elements, new `x:Name` elements, and the events of the compiled code (the same handlers on the same elements). The window or page keeps:

- its `DataContext` and view model, and everything bound to them;
- its size and position, its title and the `<Window>` settings it started with;
- the state of the Pascal code: fields, lists, timers.

Unbound state of the old elements starts again: the text typed in an unbound TextBox, a scroll position, the selected tab of an unbound control.

## What needs a rebuild

Delphi cannot change compiled code in a running app. When an edit needs code the app does not have, the app keeps what it shows and the bar says **Rebuild needed** with the reason:

- an `x:Name` the Pascal code uses was removed, or its element changed type (a TextBlock became a TextBox);
- event wiring changed: a new `Click="..."`, a handler removed, or a handler moved to another element;
- Pascal code changed.

`<Window>` attributes (Title, Width, Backdrop...) and the attributes of a `<Page>` root apply at the next start.

A XAML error, such as an unknown element or a property value WinUI refuses, leaves the last good content on screen and shows the error in the bar. The XAML is checked before it is loaded, without an exception, so the debugger does not stop at each typo. The outcome also goes to OutputDebugString, so it appears in the IDE's Event Log while debugging.

## TWinUIHost on VCL forms

A `TWinUIHost` whose content is in a `.xaml` file (`XamlFile`) reloads when that file is edited. Its XAML errors show in the control, as at startup. XAML held inline in the `.dfm` (`Xaml`) changes with a rebuild.

## How it works

- **The app (Debug builds only).** The generated units watch their `.xaml` under `{$IFDEF DEBUG}`, and so does TWinUIHost. The first watch opens the named pipe `\\.\pipe\RADWinUI.HotReload.<process id>` (`RADWinUI.HotReload`). Its default security lets only the current user and administrators write to it, and it refuses remote clients. A Release build contains neither the pipe nor the reload code.
- **The IDE.** `RADWinUI.Preview.HotReload` finds the listening apps and sends a `.xaml` file only to the apps whose exe is in that file's folder or below it, so another project's app never receives it. Before sending, XamlCodeGen turns the edited text into the content the app loads and the *shape* it compares, as it does for the build.
- **The shape.** Each generated unit has the shape it was compiled with (`XamlShape`): its `x:Name` fields with their types, and its events. The app reloads when every compiled field is still there with the same type and the events are the same.
- **The reload.** On the UI thread the app loads the new content and calls the generated `WireXaml` again, which fills the `x:Name` fields and wires the events, as the constructor did. A window keeps its DataContext through `LoadContent`, a page moves the new content into itself (`ReplaceXaml`), a user control loads it as its content.
