# Guide: Get-PSModuleComplexity

`Get-PSModuleComplexity` calculates a **cyclomatic complexity** for every function. A higher
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

Every function starts with `1`. Every decision point adds `1`:

| Construct | Adds |
| --- | --- |
| `if` and each `elseif` | 1 per branch |
| `for`, `foreach`, `while`, `do/while`, `do/until` | 1 per loop |
| `switch` | 1 per case (the `default` branch does not count) |
| `catch`, `trap` | 1 per clause |
| `-and`, `-or`, `-xor` | 1 per operator |
| ternary `? :` (PowerShell 7) and pipeline chains `&&`, `\|\|` | 1 each |

Decision points inside a **nested function** count only for that nested function, not for the
function that contains it. Script blocks such as `ForEach-Object { ... }` count for the function
they are written in.

## How to read it

| Score | Meaning |
| --- | --- |
| 1 - 5 | simple |
| 6 - 10 | moderate |
| above 10 | complex - consider splitting; the reports flag these as `HighComplexity` |

## Limitations

- Only static code is analyzed, not runtime paths.
- The `??` operator and `-match`-style conditions are not counted as decisions.
- Older versions of this module counted fewer constructs (no `elseif`, `-and`/`-or`, per-case
  `switch`), so scores of the same code are now higher. Do not compare numbers from before and
  after this change.
- A file that the running PowerShell version cannot parse (for example PowerShell 7 syntax in
  Windows PowerShell 5.1) is analyzed only partly; a warning names such files once.

## Examples

```powershell
# Functions above the default threshold of the reports
Get-PSModuleComplexity -ModuleName PSModuleQuantityAnalyzer | Where-Object Complexity -gt 10
```

## See also

[Get-PSModuleRefactoringCandidates](Get-PSModuleRefactoringCandidates.md) ·
[Get-PSModuleMetrics](Get-PSModuleMetrics.md)
