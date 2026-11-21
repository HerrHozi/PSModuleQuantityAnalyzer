# Guide: Get-PSModuleRefactoringCandidates

`Get-PSModuleRefactoringCandidates` lists functions that are worth cleaning up. Each function is
checked against four rules; only functions with at least one finding are returned.

## Usage

```powershell
Get-PSModuleRefactoringCandidates -ModuleName PSModuleQuantityAnalyzer
Get-PSModuleRefactoringCandidates -ModuleName PSModuleQuantityAnalyzer -MaxLines 120 -MaxComplexity 8
```

## Parameters

| Parameter | Description |
| --- | --- |
| `-ModuleName` | Module name or path to the manifest (mandatory) |
| `-MaxLines` | Functions with more `TotalLines` are flagged `LargeFunction`. Default `150` |
| `-MaxComplexity` | Functions with a higher complexity are flagged `HighComplexity`. Default `10` |

## The four rules

| Issue | Condition |
| --- | --- |
| `LargeFunction` | `TotalLines` greater than `-MaxLines` |
| `HighComplexity` | complexity greater than `-MaxComplexity` |
| `UnusedPrivateFunction` | private function with `References = 0` |
| `NoDocumentation` | no comment-based help (`HelpTopics = 0`) |

## Output properties

`ModuleName`, `Version`, `Function`, `TotalLines`, `Complexity`, `References`,
`Issues` (comma-separated list of the rules above), `PartOfFile`, `FullName`.

## Examples

```powershell
# Everything, worst first
Get-PSModuleRefactoringCandidates -ModuleName PSModuleQuantityAnalyzer |
    Sort-Object Complexity -Descending | Format-Table Function, TotalLines, Complexity, Issues

# Only functions that are both large and complex
Get-PSModuleRefactoringCandidates -ModuleName PSModuleQuantityAnalyzer |
    Where-Object { $_.Issues -match 'LargeFunction' -and $_.Issues -match 'HighComplexity' }
```

## Notes

- Complexity comes from [Get-PSModuleComplexity](Get-PSModuleComplexity.md) and is a lower bound.
- `NoDocumentation` also applies to private helper functions. Filter by `FullName` if only the
  public commands matter to you.
- Public functions are never flagged as unused, because they are expected to be called from outside.
- The Markdown report shows these findings in the section "Refactoring Candidates".

## See also

[Get-PSModuleLargestFunctions](Get-PSModuleLargestFunctions.md) ·
[Get-PSModuleUnusedPrivateFunctions](Get-PSModuleUnusedPrivateFunctions.md) ·
[Get-PSModuleDocumentationCoverage](Get-PSModuleDocumentationCoverage.md)
