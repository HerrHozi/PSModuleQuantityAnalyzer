# Guide: Get-PSModuleSummary

`Get-PSModuleSummary` returns **one object** that describes a module at a glance: identity,
function counts, file counts, lines of code and the number of documentation and graphic files.
Every call also appends the result to a CSV file, so you build a history of analyses.

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
| `PublicFunctions`, `PrivateFunctions`, `TotalFunctions` | Function counts by folder (`Public` / `Private`) |
| `DoubleFunctionPairs` | Number of function names that are defined more than once |
| `Verbs` | Number of different verbs used in function names |
| `PublicFiles`, `PrivateFiles`, `TotalFiles` | Number of `.ps1` files directly in the `Public` and `Private` folders |
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
- Several commands call `Get-PSModuleSummary` internally (`Get-PSModuleMetrics`,
  `Export-PSModuleMarkdownReport`). Each of those calls adds a row as well.
- The column set must stay the same. If an older file with different columns exists, rename or
  delete it before the next call.

Read the history:

```powershell
Import-Csv "$env:LOCALAPPDATA\Get-PSModuleSummary.csv" |
    Where-Object ModuleName -eq 'PSModuleQuantityAnalyzer' |
    Format-Table DateOfAnalysis, Version, TotalFunctions, TotalLines
```

## Examples

```powershell
# Full object, including all properties
Get-PSModuleSummary -ModuleName PSModuleQuantityAnalyzer | Format-List

# Only the counts
Get-PSModuleSummary -ModuleName PSModuleQuantityAnalyzer |
    Select-Object ModuleName, Version, TotalFunctions, TotalLines, MarkdownFiles, GraphicFiles
```

## Notes

- `PublicFunctions` and `PrivateFunctions` are decided by whether the file path contains the text
  `Public` or `Private`. A module stored in a folder with such a name in its path can be counted
  wrongly.
- Functions whose file path contains neither word (for example a `.ps1` in a `Helpers` folder) are
  counted as neither public nor private, so `TotalFunctions` can be lower than the real number.

## See also

[Get-PSModuleQuantity](Get-PSModuleQuantity.md) · [Get-PSModuleMetrics](Get-PSModuleMetrics.md) ·
[Get-PSModuleNestedModules](Get-PSModuleNestedModules.md)
