# Guide: Get-PSModuleQuantity

`Get-PSModuleQuantity` is the base of the module. It returns **one row per function** with size,
help, reference and file information. Most other commands (`Get-PSModuleSummary`,
`Get-PSModuleMetrics`, `Get-PSModuleHealth`, the reports, ...) are built on its output.

## Usage

```powershell
Get-PSModuleQuantity -ModuleName PSModuleQuantityAnalyzer
Get-PSModuleQuantity -ModuleName .\MyModule.psd1
```

`-ModuleName` takes the name of an installed module (the highest installed version is used) or the
path to a module manifest (`.psd1`).

## Output properties

| Property | Meaning |
| --- | --- |
| `Function` | Function name |
| `NestedModule` | Name of the nested module the function belongs to, `(main)` for the module itself |
| `Type` | `Public` if a folder named `Public` is part of the file path below the module root, otherwise `Private` |
| `HelpTopics` | Number of filled comment-based-help sections (`.SYNOPSIS`, `.DESCRIPTION`, ...). `0` means no help |
| `LinesOfHelp` | Same value as `HelpTopics` (kept for compatibility) |
| `TotalLines` | Lines from the first to the last line of the function |
| `LinesOfCode` | `TotalLines` minus comment lines and blank lines |
| `LinesOfComment` | Lines that start with `#` inside the function |
| `References` | How often the function name is called as a command or written as quoted text (`& 'Name'`, `-FunctionName 'Name'`) in `.ps1` and `.psm1` files of the module |
| `PartOfFile` | File name that contains the function |
| `RelativePath` | Path of the file below the module root, including subfolders (for example `Private\ASP07\Get-KirbiTicketInfo.ps1`) |
| `FullName` | Full path of that file |
| `ModificationDate`, `CreationDate`, `FileSize` | File metadata |
| `CollectionDate` | Time of the analysis |
| `ModuleName`, `Version` | Module that was analyzed |

## Typical queries

```powershell
# Overview table
Get-PSModuleQuantity -ModuleName PSModuleQuantityAnalyzer |
    Format-Table Function, NestedModule, Type, TotalLines, References, PartOfFile

# Private functions that nobody calls
Get-PSModuleQuantity -ModuleName PSModuleQuantityAnalyzer |
    Where-Object { $_.Type -eq 'Private' -and $_.References -eq 0 }

# Functions without help
Get-PSModuleQuantity -ModuleName PSModuleQuantityAnalyzer | Where-Object HelpTopics -eq 0

# Functions per nested module
Get-PSModuleQuantity -ModuleName .\MyModule.psd1 | Group-Object NestedModule
```

## How the numbers are built

- Source files are all `.ps1` files below the module folder, except folders named `tests`, `build`
  and `docs`. Functions in `.psm1` files are not scanned.
- Everything is parsed with the PowerShell AST, so functions are found even when several are in one
  file. Nested functions are listed as their own rows.
- A comment-based help block **above** a function is not part of the function and therefore not in
  `TotalLines` or `LinesOfComment`. Only `#` lines inside the function count as comments.
- `References` counts command calls with a fixed name and names of the form `Verb-Noun` that are
  written as quoted text. Calls through variables (`& $name`) are not seen. The module loader
  `.psm1` is scanned for calls, but functions defined inside a `.psm1` are not listed.

## Notes

- A file with syntax errors for the running PowerShell version is analyzed only partly. A warning
  names such a file once per session (for example PowerShell 7 code analyzed in Windows PowerShell
  5.1).
- The command parses every file several times (once per helper), so large modules take a moment.
  Commands that combine several reports (`Get-PSModuleMetrics`, the Markdown report) call it more
  than once. Store the result in a variable if you want to run several queries:

  ```powershell
  $q = Get-PSModuleQuantity -ModuleName PSModuleQuantityAnalyzer
  ```

## See also

[Get-PSModuleSummary](Get-PSModuleSummary.md) ·
[Get-PSModuleUnusedPrivateFunctions](Get-PSModuleUnusedPrivateFunctions.md) ·
[Get-PSModuleLargestFunctions](Get-PSModuleLargestFunctions.md) ·
[Export-PSModuleQuantityReport](Export-PSModuleQuantityReport.md)
