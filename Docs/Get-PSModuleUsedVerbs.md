# Guide: Get-PSModuleUsedVerbs

`Get-PSModuleUsedVerbs` lists the verbs your functions use (`Get`, `Export`, ...) and tells you
whether each verb is an **approved PowerShell verb**. Unapproved verbs produce a warning when the
module is imported with `Import-Module -Verbose`, and are a style issue for Gallery modules.

## Usage

```powershell
Get-PSModuleUsedVerbs -ModuleName PSModuleQuantityAnalyzer
Get-PSModuleUsedVerbs -ModuleName PSModuleQuantityAnalyzer | Select-Object Verb, Count, Approved | Sort-Object Verb
Get-PSModuleUsedVerbs -ModuleName .\MyModule.psd1 | Where-Object { -not $_.Approved }
```

## Output properties

| Property | Meaning |
| --- | --- |
| `Verb` | Part of the function name before the first hyphen |
| `Count` | Number of functions that use the verb |
| `Approved` | `True` if `Get-Verb` knows the verb |
| `Functions` | Names of the functions that use the verb |
| `CollectionDate`, `ModuleName`, `Version` | Analysis metadata |

Sorted by `Count`, most used first.

## Notes

- Only functions with a hyphen in the name are considered.
- Private functions are included. Unapproved verbs in private functions do not trigger import
  warnings, but you may want to keep them consistent.
- The approved list depends on the PowerShell version in which you run the command.
- In earlier module versions the documentation mentioned a `Supported` property. The property is
  called `Approved`.

## Example: find the offenders

```powershell
Get-PSModuleUsedVerbs -ModuleName .\MyModule.psd1 |
    Where-Object { -not $_.Approved } |
    ForEach-Object { $_.Functions }
```

## See also

[Get-PSModuleSummary](Get-PSModuleSummary.md) (property `Verbs` = number of different verbs)
