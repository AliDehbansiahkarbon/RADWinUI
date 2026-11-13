# Customers_VCL

A classic VCL screen with one panel modernized: the customer list, the New and Delete buttons and the status bar are VCL, the details panel is WinUI in a `TWinUIHost` ([WinUI inside VCL forms](VCL-HOSTING.md)).

Open `samples\Customers_VCL\Customers_VCL.dproj` in RAD Studio 13 and run Win64. Or, from the repository root:

```powershell
.\scripts\Build.ps1 -Project samples\Customers_VCL\Customers_VCL.dpr -Config Release
.\samples\Customers_VCL\Win64\Release\Customers_VCL.exe
```

## What to try

- Click a customer in the VCL list: the WinUI panel shows its name, email, credit limit and newsletter choice.
- Change the name and click **Save**: the VCL list and status bar take the new name and an InfoBar confirms it. **Revert** brings the saved values back.
- **New** adds a customer and moves the focus into the panel. Tab and Shift+Tab move between the VCL controls and the WinUI fields.
- Open `MainForm.dfm` in the form designer: the panel is a placeholder there, its XAML is the host's `Xaml` property in the Object Inspector.

## How it is made

- `DetailsHost.Xaml` (in `MainForm.dfm`) holds the panel. Its bindings are two-way: `{Binding Name, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}`.
- `TCustomer` (`Customer.pas`) is a `TWinUIBindableObject` whose setters call `Changed`. The panel edits a copy, the list changes on Save only.
- `SaveButtonClick` is found by the button's name, `RevertClick` by the `Click` attribute. Both are ordinary published methods of the form.

## Automated check

`scripts\Test-Samples.ps1` starts it hidden and shows it where test windows go without taking the focus, checks the bound name, saves a new one and reads it back from the VCL status bar, reverts an edit, and clicks the VCL New button.
