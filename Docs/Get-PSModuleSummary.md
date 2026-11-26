# Guide: Get-PSModuleSummary

`Get-PSModuleSummary` returns **one object** that describes a module at a glance: identity,
function counts, file counts, lines of code and the number of documentation and graphic files.
Every call also appends the result to a CSV file, so you build a history of analyses that you can
evaluate later (trends of functions, lines or documentation per version).

## Usage

```powershell
Get-PSModuleSummary -ModuleName PSModuleQuantityAnalyzer
Get-PSModuleSummary -ModuleName .\MyModule.psd1
```

## Output properties

| Property | Meaning |
| --- | --- |
| `DateOfAnalysis` | Time of the analysis, format `yyyy-MM-dd HH:mm:ss.fff` (string) |
| `ModuleName`, `Version` | Module and version that were analyzed (highest installed version) |
| `LastUpdate` | Newest write time of any `.ps1`, `.psm1` or `.psd1` file in the module folder (not the `LastUpdate` entry of the manifest) |
| `NestedModules` | Number of nested modules located in a sub folder |
| `PublicFunctions`, `PrivateFunctions`, `TotalFunctions` | Function counts. A function is public when a folder named `Public` is part of its path below the module root, every other function counts as private. `TotalFunctions` equals the number of rows of `Get-PSModuleQuantity` |
| `DoubleFunctionPairs` | Number of function names that are defined more than once |
| `Verbs` | Number of different verbs used in function names |
| `PublicFiles`, `PrivateFiles`, `TotalFiles` | Number of `.ps1` source files in the whole module tree, **including subfolders** such as `Private\ASP07`. Same rule as for the functions: public below a `Public` folder, all others private. Folders `tests`, `build` and `docs` are skipped |
| `TotalLines` | Sum of `TotalLines` of all functions |
| `HtmlFiles` | Files with extension `.html` or `.htm` |
| `MarkdownFiles` | Files with extension `.md` or `.markdown` |
| `GraphicFiles` | `.jpg`, `.jpeg`, `.png`, `.gif`, `.bmp`, `.svg`, `.ico`, `.webp`, `.tif`, `.tiff` |
| `ModulePath` | Folder of the analyzed module |

The three file counts search the **whole module folder recursively** and skip `.git`.

## CSV history

Each call appends one row to:

```text
%LOCALAPPDATA%\Get-PSModuleSummary.csv
```

- Encoding UTF-8, no type header, one row per call, with `DateOfAnalysis` as first column.
- If the file cannot be written, a warning is shown and the object is still returned.
- Only a **deliberate call** adds a row. Commands that call `Get-PSModuleSummary` internally
  (`Get-PSModuleMetrics`, `Export-PSModuleMarkdownReport`) use `-NoHistory`, so they do not.
  Use `-NoHistory` yourself when you want the object without a history row, for example in a
  script that runs often.
- The column set must stay the same. If an older file with different columns exists, rename or
  delete it before the next call.

Read the history:

```powershell
Import-Csv "$env:LOCALAPPDATA\Get-PSModuleSummary.csv" |
    Where-Object ModuleName -eq 'PSModuleQuantityAnalyzer' |
    Format-Table DateOfAnalysis, Version, TotalFunctions, TotalLines

```

Or browse and filter everything in a grid window with the switch `-ShowHistory`:

```powershell
Get-PSModuleSummary -ShowHistory
```

It opens the CSV with `Out-GridView` and does not analyze a module, so it cannot be combined with
`-ModuleName`. If no history exists yet, a warning is shown. `Out-GridView` needs a graphical
Windows session.

Example content of the history (several modules, newest first, selected columns):

| DateOfAnalysis | ModuleName | Version | PublicFunctions | PrivateFunctions | TotalFunctions | TotalLines | HtmlFiles | MarkdownFiles | GraphicFiles |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 2026-11-21 18:43:16.572 | PSModuleQuantityAnalyzer | 2026.11.21.1119 | 23 | 21 | 44 | 2390 | 0 | 22 | 1 |
| 2026-11-21 17:01:06.135 | AS2Go | 2026.11.20.951 | 15 | 188 | 203 | 18147 | 33 | 8 | 42 |
| 2026-11-16 12:14:55.456 | AS2Go | 2026.11.15.1060 | 15 | 182 | 197 | 17066 | 32 | 7 | 42 |
| 2026-11-16 12:13:44.542 | PSModuleQuantityAnalyzer | 2026.11.16.716 | 22 | 16 | 38 | 1932 | 0 | 3 | 1 |

Because every row has a timestamp, you can see how a module grows between versions, for example
`AS2Go` gained 6 private functions and about 1,100 lines between the two analyses above.

## Examples

```powershell
# Full object, including all properties
Get-PSModuleSummary -ModuleName PSModuleQuantityAnalyzer | Format-List

# Without a history row
Get-PSModuleSummary -ModuleName PSModuleQuantityAnalyzer -NoHistory

# Only the counts
Get-PSModuleSummary -ModuleName PSModuleQuantityAnalyzer |
    Select-Object ModuleName, Version, TotalFunctions, TotalLines, MarkdownFiles, GraphicFiles
```

## Notes

- Only the path **below the module root** counts. A module stored in a folder named `Public` or
  `Private` is not misclassified, and subfolders (`Private\ASP07\...`) are included.
- Source files outside `Public` and `Private` (for example `LabSetup\*.ps1`) count as private.
- Modules that are not declared as `NestedModules` in the manifest (for example folders below
  `Modules\` that the module loads itself) are counted as part of the main module.
- Analyze a module with the PowerShell version it was written for. Code that uses PowerShell 7
  syntax is parsed incompletely by Windows PowerShell 5.1, which changes the line and function
  numbers.

## See also

[Get-PSModuleQuantity](Get-PSModuleQuantity.md) · [Get-PSModuleMetrics](Get-PSModuleMetrics.md) ·
[Get-PSModuleNestedModules](Get-PSModuleNestedModules.md)
