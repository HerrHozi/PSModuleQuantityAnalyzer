# Guides

One guide per public command. Every analysis command takes `-ModuleName` (installed module name or
path to a `.psd1`) and returns objects you can filter, sort and export.

## Analyze

| Command | Guide |
| --- | --- |
| `Get-PSModuleSummary` | [Summary of a module, with CSV history](Get-PSModuleSummary.md) |
| `Get-PSModuleQuantity` | [Function inventory, the base of all other commands](Get-PSModuleQuantity.md) |
| `Get-PSModuleMetrics` | [Aggregated quality metrics](Get-PSModuleMetrics.md) |
| `Get-PSModuleHealth` | [Quick maintainability check](Get-PSModuleHealth.md) |
| `Get-PSModuleLargestFunctions` | [Largest functions](Get-PSModuleLargestFunctions.md) |
| `Get-PSModuleComplexity` | [Cyclomatic complexity per function](Get-PSModuleComplexity.md) |
| `Get-PSModuleDocumentationCoverage` | [Share of functions with help](Get-PSModuleDocumentationCoverage.md) |
| `Get-PSModuleRefactoringCandidates` | [Functions worth cleaning up](Get-PSModuleRefactoringCandidates.md) |
| `Get-PSModuleUnusedPrivateFunctions` | [Private functions nobody calls](Get-PSModuleUnusedPrivateFunctions.md) |
| `Get-PSModuleDuplicateFunctions` | [Function names defined twice](Get-PSModuleDuplicateFunctions.md) |
| `Get-PSModuleUsedVerbs` | [Verbs in function names, approved or not](Get-PSModuleUsedVerbs.md) |

## Dependencies and structure

| Command | Guide |
| --- | --- |
| `Get-PSModuleDependencyGraph` | [Which function calls which](Get-PSModuleDependencyGraph.md) |
| `Get-PSModuleDependencies` | [External module dependencies](Get-PSModuleDependencies.md) |
| `Get-PSModuleNestedModules` | [Metrics per nested module](Get-PSModuleNestedModules.md) |
| `Get-PSModuleNestedDependencies` | [Calls between nested modules](Get-PSModuleNestedDependencies.md) |

## Reports

| Command | Guide |
| --- | --- |
| `Export-PSModuleMarkdownReport` | [Markdown report with diagrams](Export-PSModuleMarkdownReport.md) |
| `Export-PSModuleQuantityReport` | [CSV export of the function inventory](Export-PSModuleQuantityReport.md) |

## Release tooling

| Command | Guide |
| --- | --- |
| `Checkpoint-PSModuleVersion` | [Backup, version bump, commit, push and release](Checkpoint-PSModuleVersion.md) |

## Where to start

```powershell
Get-PSModuleSummary -ModuleName .\MyModule.psd1          # what is in it?
Get-PSModuleHealth  -ModuleName .\MyModule.psd1          # is it in good shape?
Get-PSModuleRefactoringCandidates -ModuleName .\MyModule.psd1   # what to fix first?
Export-PSModuleMarkdownReport -ModuleName .\MyModule.psd1       # share the result
```
