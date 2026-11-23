# Guide: Get-PSModuleDependencyGraph

`Get-PSModuleDependencyGraph` shows **which function calls which other function** inside the same
module. It answers: "If I change this function, who is affected?" and "Which functions are the
core of my module?"

## Usage

```powershell
Get-PSModuleDependencyGraph -ModuleName PSModuleQuantityAnalyzer
```

## Output properties

One row per call:

| Property | Meaning |
| --- | --- |
| `Function` | The calling function |
| `Calls` | The called function (defined in the same module) |
| `File` | File that contains the calling function |

A function that is called several times by the same caller appears several times.

## Examples

```powershell
# Who calls Get-PSModuleQuantity?
Get-PSModuleDependencyGraph -ModuleName PSModuleQuantityAnalyzer |
    Where-Object Calls -eq 'Get-PSModuleQuantity' | Select-Object -ExpandProperty Function -Unique

# The most used functions
Get-PSModuleDependencyGraph -ModuleName PSModuleQuantityAnalyzer |
    Group-Object Calls | Sort-Object Count -Descending | Select-Object -First 10 Name, Count

# Functions that call many others (high coupling)
Get-PSModuleDependencyGraph -ModuleName PSModuleQuantityAnalyzer |
    Group-Object Function | Sort-Object Count -Descending | Select-Object -First 10 Name, Count
```

## Diagram

[Export-PSModuleMarkdownReport](Export-PSModuleMarkdownReport.md) turns the 25 functions with the
most calls into a Mermaid diagram (`graph TD`) that GitHub renders directly.

## Notes

- Only calls to functions that are defined in the analyzed module are returned. Calls to
  commands of other modules are ignored; use [Get-PSModuleDependencies](Get-PSModuleDependencies.md)
  for those.
- Only calls with a fixed command name are detected, not `& $name`.
- Calls between the main module and its nested modules are listed here too; use
  [Get-PSModuleNestedDependencies](Get-PSModuleNestedDependencies.md) for only the calls that cross
  module boundaries.
