# Guide: Get-PSModuleDuplicateFunctions

`Get-PSModuleDuplicateFunctions` finds function names that are **defined more than once** in a
module. When this happens, the definition that is loaded last silently wins, which is a common
source of confusing behavior.

## Usage

```powershell
Get-PSModuleDuplicateFunctions -ModuleName PSModuleQuantityAnalyzer
Get-PSModuleDuplicateFunctions -ModuleName PSModuleQuantityAnalyzer |
    Select-Object Function, TotalLines, DuplicateCount, PartOfFile | Format-Table
```

No output means no duplicates.

## Output properties

One row per duplicate definition:

| Property | Meaning |
| --- | --- |
| `Function` | Function name |
| `PartOfFile`, `FullName` | File that contains this definition |
| `TotalLines`, `LinesOfCode` | Size of this definition |
| `References` | Calls of this function name (the same value for every definition of the name) |
| `DuplicateCount` | How many times the name is defined |

## What to do

1. Compare the definitions (`TotalLines` and the files tell you which is the larger or newer one).
2. Keep one, delete the other, or rename if both are needed.
3. Check which file is dot-sourced last: in this module's loader the `Private` files are loaded
   first and the `Public` files afterwards, so a public definition overrides a private one.

## Notes

- The name `DoubleFunctionPairs` in [Get-PSModuleSummary](Get-PSModuleSummary.md) counts the
  **distinct names** that are duplicated, while the Markdown/metrics value `DuplicateFunctions`
  counts all duplicate **rows**.
- Function names are compared case-insensitively, like PowerShell does.

## See also

[Get-PSModuleSummary](Get-PSModuleSummary.md) · [Get-PSModuleMetrics](Get-PSModuleMetrics.md)
