# Guide: Get-PSModuleHealth

`Get-PSModuleHealth` gives a short **maintainability check** of a module: how many functions are
too large, unused or undocumented, and which functions are used the most.

## Usage

```powershell
Get-PSModuleHealth -ModuleName PSModuleQuantityAnalyzer
Get-PSModuleHealth -ModuleName PSModuleQuantityAnalyzer -LargeFunctionThreshold 80
```

## Parameters

| Parameter | Description |
| --- | --- |
| `-ModuleName` | Module name or path to the manifest (mandatory) |
| `-LargeFunctionThreshold` | Line count above which a function is "large". Default `100`, minimum `1` |

## Output properties

| Property | Meaning |
| --- | --- |
| `ModuleName`, `Version` | Analyzed module |
| `TotalFunctions` | Number of functions |
| `LargeFunctionThreshold` | Threshold that was used |
| `FunctionsOverLargeFunctionThreshold` | Functions with `TotalLines` greater than the threshold |
| `UnusedFunctions` | **Private** functions with `References = 0` (public functions are not counted) |
| `FunctionsWithoutHelp` | Functions without comment-based help |
| `TopReferencedFunctions` | The five most-called functions, comma separated |

## Important to know

- `UnusedFunctions` counts private functions only, because a public command is normally not called
  inside its own module. The list of the functions behind the number is returned by
  [Get-PSModuleUnusedPrivateFunctions](Get-PSModuleUnusedPrivateFunctions.md).
- A value greater than `0` is a hint, not an error.
- Use the same threshold when comparing versions, otherwise the numbers are not comparable.

## Examples

```powershell
# Strict view
Get-PSModuleHealth -ModuleName PSModuleQuantityAnalyzer -LargeFunctionThreshold 60 | Format-List

# Find the functions behind the numbers
Get-PSModuleLargestFunctions -ModuleName PSModuleQuantityAnalyzer -Top 5
Get-PSModuleQuantity -ModuleName PSModuleQuantityAnalyzer | Where-Object HelpTopics -eq 0
```

## See also

[Get-PSModuleMetrics](Get-PSModuleMetrics.md) ·
[Get-PSModuleRefactoringCandidates](Get-PSModuleRefactoringCandidates.md) ·
[Get-PSModuleDocumentationCoverage](Get-PSModuleDocumentationCoverage.md)
