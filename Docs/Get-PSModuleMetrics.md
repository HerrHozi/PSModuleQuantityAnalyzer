# Guide: Get-PSModuleMetrics

`Get-PSModuleMetrics` condenses size, complexity, documentation and maintenance indicators of a
module into **one object**. It is the command to use for a quick quality snapshot or for comparing
two versions of a module.

## Usage

```powershell
Get-PSModuleMetrics -ModuleName PSModuleQuantityAnalyzer
Get-PSModuleMetrics -ModuleName .\MyModule.psd1 | Format-List
```

## Output properties

| Property | Meaning |
| --- | --- |
| `ModuleName`, `Version` | Analyzed module |
| `Files`, `Functions`, `PublicFunctions`, `PrivateFunctions` | Counts, taken from [Get-PSModuleSummary](Get-PSModuleSummary.md) |
| `TotalLines`, `LinesOfCode`, `LinesOfComment` | Sums over all functions |
| `CommentRatioPercent` | `LinesOfComment / TotalLines` in percent, 2 decimals |
| `AverageFunctionLines` | Average `TotalLines` per function |
| `AverageComplexity`, `MaxComplexity` | Cyclomatic complexity statistics, see [Get-PSModuleComplexity](Get-PSModuleComplexity.md) |
| `ComplexFunctions` | Number of functions with complexity **greater than 10** (fixed threshold) |
| `DocumentationCoveragePercent` | Share of functions with comment-based help |
| `UnusedPrivateFunctions` | Private functions with no reference |
| `DuplicateFunctions` | Rows returned by [Get-PSModuleDuplicateFunctions](Get-PSModuleDuplicateFunctions.md) (each duplicate definition counts) |
| `LargestFunction`, `LargestFunctionLines`, `LargestFunctionFile` | The function with the most lines |

## How to read it

| Indicator | Look closer when |
| --- | --- |
| `CommentRatioPercent` | very low (code without explanation) or very high (dead, commented-out code) |
| `AverageFunctionLines` / `LargestFunctionLines` | one function is many times larger than the average |
| `ComplexFunctions` | greater than 0 - candidates for splitting |
| `DocumentationCoveragePercent` | below 100 for public functions |
| `UnusedPrivateFunctions`, `DuplicateFunctions` | greater than 0 |

## Examples

```powershell
# Compare two versions of a module
'.\v1\MyModule.psd1', '.\v2\MyModule.psd1' |
    ForEach-Object { Get-PSModuleMetrics -ModuleName $_ } |
    Format-Table Version, Functions, TotalLines, AverageComplexity, DocumentationCoveragePercent
```

## Notes

- The command runs five other analyses plus `Get-PSModuleSummary`, so it is slower than the single
  commands. For large modules start with `Get-PSModuleSummary` or `Get-PSModuleHealth`.
- It calls `Get-PSModuleSummary -NoHistory`, so it does not add a row to the history file
  `%LOCALAPPDATA%\Get-PSModuleSummary.csv`.
- The comment ratio only counts `#` lines inside functions. Help blocks above a function are not
  included.

## See also

[Get-PSModuleHealth](Get-PSModuleHealth.md) ·
[Get-PSModuleRefactoringCandidates](Get-PSModuleRefactoringCandidates.md) ·
[Export-PSModuleMarkdownReport](Export-PSModuleMarkdownReport.md)
