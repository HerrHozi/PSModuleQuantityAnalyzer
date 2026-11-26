# Guide: Get-PSModuleDocumentationCoverage

`Get-PSModuleDocumentationCoverage` tells you which share of the functions has comment-based help
(`.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`, ...).

## Usage

```powershell
Get-PSModuleDocumentationCoverage -ModuleName PSModuleQuantityAnalyzer
```

## Output properties

| Property | Meaning |
| --- | --- |
| `ModuleName`, `Version` | Analyzed module |
| `Functions` | Number of functions |
| `FunctionsWithHelp` | Functions with comment-based help |
| `FunctionsWithoutHelp` | Functions without |
| `DocumentationCoveragePercent` | `FunctionsWithHelp / Functions` in percent, 2 decimals |

## Finding the undocumented functions

The command returns only the totals. To get the list use `HelpTopics` from
[Get-PSModuleQuantity](Get-PSModuleQuantity.md):

```powershell
Get-PSModuleQuantity -ModuleName PSModuleQuantityAnalyzer |
    Where-Object HelpTopics -eq 0 |
    Format-Table Function, Type, PartOfFile
```

## Notes

- Private helper functions count the same as public ones. A coverage below 100 % is often fine
  when only private helpers lack help.
- The help block is found when it is placed directly above the function, directly after the
  opening brace or at the end of the function body.
- Only the presence of help is checked, not its quality. A function counts as documented when at
  least one help section (`.SYNOPSIS`, `.DESCRIPTION`, ...) is filled; the numbers match the
  property `HelpTopics` of [Get-PSModuleQuantity](Get-PSModuleQuantity.md).

## See also

[Get-PSModuleHealth](Get-PSModuleHealth.md) · [Get-PSModuleMetrics](Get-PSModuleMetrics.md)
