# Guide: Export-PSModuleMarkdownReport

`Export-PSModuleMarkdownReport` creates a complete **Markdown report** of a module, including
tables and three Mermaid diagrams. GitHub, VS Code (with a Mermaid extension) and many wikis render
it directly. A sample is in [Example](../Example/ModuleAnalysis_PSModuleQuantityAnalyzer_2026.3.13.420.md).

## Usage

```powershell
Export-PSModuleMarkdownReport -ModuleName PSModuleQuantityAnalyzer
Export-PSModuleMarkdownReport -ModuleName PSModuleQuantityAnalyzer -Path .\reports\qa.md
```

## Parameters

| Parameter | Description |
| --- | --- |
| `-ModuleName` | Module name or path to the manifest (mandatory) |
| `-Path` | Target file. Default `.\ModuleAnalysis_<ModuleName>_<Version>.md` in the current directory |

An existing file is **overwritten**. The command prints the target path and returns no objects.

## Contents of the report

| Section | Source |
| --- | --- |
| Module Information | [Get-PSModuleSummary](Get-PSModuleSummary.md) |
| Module Metrics | [Get-PSModuleMetrics](Get-PSModuleMetrics.md) |
| Function Inventory | [Get-PSModuleQuantity](Get-PSModuleQuantity.md) |
| Largest Functions (top 5) | [Get-PSModuleLargestFunctions](Get-PSModuleLargestFunctions.md) |
| Unused Private Functions | [Get-PSModuleUnusedPrivateFunctions](Get-PSModuleUnusedPrivateFunctions.md) |
| Refactoring Candidates | [Get-PSModuleRefactoringCandidates](Get-PSModuleRefactoringCandidates.md) |
| Function Size Distribution (pie chart) | buckets 0-25, 26-50, 51-100, 101-200, 201-500, >500 lines |
| Complexity Ranking (bar chart) | the 10 most complex functions |
| Function Dependency Graph | the 25 functions with the most calls, from [Get-PSModuleDependencyGraph](Get-PSModuleDependencyGraph.md) |

## Notes

- The report runs most analyses of the module, so it takes longer than the single commands on
  large modules.
- It calls `Get-PSModuleSummary -NoHistory`, so a report does not add a row to the history file
  `%LOCALAPPDATA%\Get-PSModuleSummary.csv`. Run `Get-PSModuleSummary` yourself to record a row.
- The `xychart-beta` diagram needs a recent Mermaid version. If it is not rendered, the data is
  still readable as text.
- The report is written for GitHub-style Markdown. Tables with very long function names can become
  wide.

## Tip: keep reports in the repository

```powershell
Export-PSModuleMarkdownReport -ModuleName .\PSModuleQuantityAnalyzer.psd1 -Path .\Example\Report.md
```

Do not place the output in a folder that is scanned as source (`Public`, `Private`). The `Docs`
and `Example` folders are fine.

## See also

[Export-PSModuleQuantityReport](Export-PSModuleQuantityReport.md)
