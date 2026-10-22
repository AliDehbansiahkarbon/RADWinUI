# WinMDGen

Reads Windows Runtime `.winmd` files (ECMA-335 metadata) and writes the Object Pascal projection in `src/Generated`: `RADWinUI.Abi.pas`, `RADWinUI.Xaml.pas` and `RADWinUI.Xaml.json` (the type index XamlCodeGen reads).

A Delphi console program with no dependencies beyond the RTL. Only maintainers run it: the generated files are committed, so users never need it.

## Run

```powershell
.\scripts\Get-WindowsAppSDK.ps1        # once, downloads the SDK packages with their .winmd files
.\scripts\Generate-Projection.ps1      # builds build\WinMDGen\WinMDGen.exe and regenerates src\Generated
```

Or directly:

```text
WinMDGen --winmd <file or folder> [--winmd ...] --out ..\..\src\Generated
         [--unit RADWinUI.Abi] [--namespace Microsoft.UI ...] [--xaml-unit RADWinUI.Xaml] [--sdk "Windows App SDK 2.5.1"]
```

Inputs: the WinUI, InteractiveExperiences, Foundation and WebView2 package metadata, plus the Windows platform metadata (`C:\Windows\System32\WinMetadata`, or the Windows SDK contract `.winmd` files). A folder is searched recursively.

## Code

| File | Role |
| --- | --- |
| `RADWinUI.WinMD.Metadata.pas` | PE container, metadata heaps and tables |
| `RADWinUI.WinMD.Model.pas` | WinRT types, signatures, custom attributes, parameterized interface IIDs |
| `RADWinUI.WinMD.Pascal.pas` | Pascal emitter: interfaces, delegates, enums, structs, generic instances and runtime class records |
| `RADWinUI.WinMD.Xaml.pas` | Wrapper classes for the XAML runtime classes, `RADWinUI.Xaml` (rules in `docs/FRAMEWORK-API.md`), and the JSON type index |
| `WinMDGen.dpr` | Command line |

Output must stay byte-identical for unchanged input: after a change to the generator, run `Generate-Projection.ps1` and review the diff of `src\Generated`.

The parameterized IID algorithm is checked against Microsoft's published values: `IIterable<String>` is `{e2fcc7c1-3bfc-5a0b-b2b0-72e769d1cb7e}` and `IReference<Int32>` is `{548cefbd-bc8a-5fa0-8df2-957440fc8bf4}`.
