# Guide: Get-PSModuleLargestFunctions

`Get-PSModuleLargestFunctions` lists the biggest functions of a module, sorted by line count. Use
it to find functions that should be reviewed or split.

## Usage

```powershell
Get-PSModuleLargestFunctions -ModuleName PSModuleQuantityAnalyzer
Get-PSModuleLargestFunctions -ModuleName PSModuleQuantityAnalyzer -Top 5
```

## Parameters

| Parameter | Description |
| --- | --- |
| `-ModuleName` | Module name or path to the manifest (mandatory) |
| `-Top` | Number of functions to return. Default `10` |

## Output properties

`Function`, `TotalLines`, `LinesOfCode`, `LinesOfComment`, `PartOfFile` - sorted by `TotalLines`,
largest first. The values come from [Get-PSModuleQuantity](Get-PSModuleQuantity.md).

## How to read it

A large function is not automatically bad. It is worth a look when it is also complex
([Get-PSModuleComplexity](Get-PSModuleComplexity.md)) or when `LinesOfComment` is close to `0`.
[Get-PSModuleRefactoringCandidates](Get-PSModuleRefactoringCandidates.md) combines both checks.

## Examples

```powershell
Get-PSModuleLargestFunctions -ModuleName .\MyModule.psd1 -Top 3 | Format-Table
```

## Notes

- A comment-based help block above the function is not part of its line count.
- Functions with the same name in different files appear as separate rows.
