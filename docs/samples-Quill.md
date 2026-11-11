# Quill

A small notes app made with Delphi and WinUI 3. It shows the app services of RADWinUI where a real app uses them: the Windows file and folder pickers, message and input boxes, Windows notifications with buttons and a text box, a single-instance app that Windows starts for its own files and links, and an app in three languages: English, German and Persian, which is written right to left.

Open `samples\Quill\Quill.dproj` in RAD Studio 13 and run Win64. Or, from the repository root:

```powershell
.\scripts\Build.ps1 -Project samples\Quill\Quill.dpr -Config Release
.\samples\Quill\Win64\Release\Quill.exe
```

## What to try

- **Notes.** Write in the editor: the note shows `*` in the title bar and "Edited" in the list. New note, Close, Save and Save as work as in any editor. Save as and Open use `TWinUISaveDialog` and `TWinUIOpenDialog` with the filter `Notes (*.qnote)|*.qnote|Text files (*.txt)|*.txt|All files (*.*)|*.*`. Import opens several files at once (`MultiSelect`), Export all writes every note into a folder picked with `TWinUIFolderDialog`.
- **Questions.** Closing an edited note, or the window with edited notes, asks "Save changes to X?" with `MessageDlg` (Yes, No, Cancel). Rename asks for the new name with `InputQuery` and renames a saved note's file too. About is a `ShowMessage`.
- **Reminders.** Remind me shows a `TWinUINotification` after 10 seconds, 1 minute or 10 minutes. Type a line into its text box and click Open note: Quill comes to the front, opens the note and adds the line. Snooze shows it again 5 minutes later. Close Quill and click the notification in the notification center: Quill starts and opens the note.
- **Languages.** Settings > Language picks English, Deutsch, فارسی (Persian) or the Windows language. Quill offers to start again in it. Every text changes: the window, the tooltips, the dialogs and their buttons, the file picker filter and the notifications. In Persian the whole window, its title bar included, reads from right to left.
- **One Quill.** Quill sets `TWinUIApp.SingleInstance`. In Settings, Register .qnote lets Windows open `.qnote` files with Quill, and Register quill: lets links such as `quill://new?text=hello` create a note (try it from Win+R). Opening a file or a link while Quill runs hands it to the running window. Settings also shows how Quill was started (`TWinUIApp.LaunchActivation`). Unregister removes both again.

## How it is made

- Every text of the window has an `x:Uid` and comes from `Strings\en-US`, `Strings\de-DE` and `Strings\fa-IR\Resources.resw`. The code reads its texts with `TWinUIResources.GetString`, and `RADWinUI_Yes`, `RADWinUI_No` and the like translate the buttons of `MessageDlg`. The post-build step builds `resources.pri` next to the exe.
- `Quill.dpr` sets `TWinUIApp.Language` before `Run` from the language saved in `HKCU\Software\Quill`. After a new pick, Quill closes (asking about edited notes as usual) and starts again with `--after <process id>`, so the new start waits for the old one instead of handing itself to it.
- In Persian the title row is right to left too, so it moves left by `AppWindow.TitleBar.RightInset`: Windows keeps the caption buttons on the right.

- `Quill.dpr` sets `SingleInstance` and `OnActivated` before `Run`. Every way in, the first launch with a file on the command line, a file or link from Windows, a notification click or a second start, arrives in `OnActivated` on the UI thread, and `TQuillWindow.HandleActivation` deals with it in one place.
- Dialogs return their result in a callback. `ConfirmSave` asks about one note and runs the next step only after Yes (once the note is saved) or No, and closing the window walks through the edited notes the same way. `OnCloseQuery` keeps the window open while it asks.
- Notes are a `TWinUIBindableList<TQuillNote>` shown by a `ListView` with an item template that binds `Title` and `Subtitle`.
- A notification button reports its argument, here `open|<file>` or `snooze|<file>`, and `TWinUIActivation.Input('line')` reads what was typed into the text box.
- The WinUI `TextBox` reports line breaks as a lone CR, so Quill passes the editor text through `AdjustLineBreaks` and keeps CRLF in notes and files.

## Automated check

`scripts\Test-Samples.ps1` runs Quill offscreen in English: it types into the editor, closes the note, answers No to "Save changes?" and adds a new note. It opens no picker and shows no notification, and gives back the language you picked. `tests\Localization` checks languages and right to left.
