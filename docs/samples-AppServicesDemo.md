# AppServicesDemo

One window with a button for each app service of RADWinUI: the message and input dialogs, the Windows file and folder pickers, Windows notifications and app activation. Every result and every activation is written to the log at the bottom, newest first, so each service can be tried on its own. [Quill](samples-Quill.md) shows the same services inside a real app.

Open `samples\AppServicesDemo\AppServicesDemo.dproj` in RAD Studio 13 and run Win64. Or, from the repository root:

```powershell
.\scripts\Build.ps1 -Project samples\AppServicesDemo\AppServicesDemo.dpr -Config Release
.\samples\AppServicesDemo\Win64\Release\AppServicesDemo.exe
```

## What to try

**Start.** The Activation card shows `Started as: Launch, arguments ""` and the log has one `OnActivated: Launch` line. Start the exe again while it runs: no second window opens, the first one comes to the front and logs another launch.

**Dialogs**

- ShowMessage: one button, closing it logs `ShowMessage closed`.
- MessageDlg Yes/No/Cancel: logs `mrYes`, `mrNo` or `mrCancel`. Esc gives `mrCancel`.
- MessageDlg error, OK: logs `mrOk`.
- InputQuery: OK logs the text, Cancel or Esc logs the default value `notes.txt`.
- Two dialogs at once: the second opens only after the first closes, both results are logged in order.

**Pickers**

- Open file: the file type list offers Text files, Pascal units and All files. The path is logged, or `cancelled`.
- Open several files: Ctrl+click several, the count and every path are logged.
- Save file: suggests `notes.txt` and asks before overwriting.
- Pick folder: the folder is logged.

**Notifications.** The card title says whether Windows supports them.

- Simple notification: click it and the log shows `Notification, arguments "simple"`.
- Notification with buttons and a text box: type a reply and click Like or Open. The log shows `like` or `open` and `inputs: reply=...`.
- Close the app and click a notification in the notification center: the app starts with `Started as: Notification`.
- Remove all notifications clears them from the notification center.

**Activation**

- Register .rwdemo and Register rwdemo:, then Create test file (`%TEMP%\RADWinUI\hello.rwdemo`).
- Open test file via shell: the log shows `File` with the path, and the window comes to the front. The first time, Windows may ask which app to use.
- Open rwdemo://hello/42 via shell, or type `rwdemo://anything` in Win+R: the log shows `Protocol` with the link.
- With the app closed, double-click `hello.rwdemo`: the app starts with `Started as: File`.
- Unregister both when done.

## How it is made

The window is built in code: `LoadContent` loads the layout from a XAML string and `FindElement` wires each button. `AppServicesDemo.dpr` sets `TWinUIApp.SingleInstance` and `OnActivated` before `Run`, so every activation, first or redirected, reaches the log the same way.

## Automated check

`scripts\Test-Samples.ps1` starts the demo offscreen, checks the launch line and answers one `MessageDlg`. It opens no picker and shows no notification.
