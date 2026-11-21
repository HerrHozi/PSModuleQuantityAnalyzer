# Guide: Get-PSModuleComplexity

`Get-PSModuleComplexity` calculates a simple **cyclomatic complexity** for every function. A higher
value means more paths through the function, so more effort to read and to test.

## Usage

```powershell
Get-PSModuleComplexity -ModuleName PSModuleQuantityAnalyzer
Get-PSModuleComplexity -ModuleName PSModuleQuantityAnalyzer | Sort-Object Complexity -Descending | Select-Object -First 10
```

## Output properties

| Property | Meaning |
| --- | --- |
| `Function` | Function name |
| `Complexity` | Score of the function |
| `File` | Full path of the file |

## How the score is calculated

Every function starts with `1`. Each of these statements adds `1`:

`if`, `for`, `foreach`, `while`, `do/while`, `switch`, `catch`

## How to read it

| Score | Meaning |
| --- | --- |
| 1 - 5 | simple |
| 6 - 10 | moderate |
| above 10 | complex - consider splitting; the reports flag these as `HighComplexity` |

## Limitations

The score is intentionally simple:

- `elseif` branches, `-and` / `-or` conditions, `trap` and `do/until` are **not** counted, so the
  value is a lower bound.
- Nested functions are counted in the outer function as well as in their own row.
- Only static code is analyzed, not runtime paths.

## Examples

```powershell
# Functions above the default threshold of the reports
Get-PSModuleComplexity -ModuleName PSModuleQuantityAnalyzer | Where-Object Complexity -gt 10
```

## See also

[Get-PSModuleRefactoringCandidates](Get-PSModuleRefactoringCandidates.md) ·
[Get-PSModuleMetrics](Get-PSModuleMetrics.md)
