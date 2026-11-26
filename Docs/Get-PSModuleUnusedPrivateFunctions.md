# Guide: Get-PSModuleUnusedPrivateFunctions

`Get-PSModuleUnusedPrivateFunctions` lists functions in the `Private` folder (subfolders such as `Private\ASP07` included) that are never called
anywhere in the module. They are candidates for removal.

## Usage

```powershell
Get-PSModuleUnusedPrivateFunctions -ModuleName PSModuleQuantityAnalyzer
Get-PSModuleUnusedPrivateFunctions -ModuleName PSModuleQuantityAnalyzer |
    Select-Object Function, TotalLines, ModificationDate, PartOfFile | Format-Table
```

## Output properties

`ModuleName`, `Version`, `Function`, `TotalLines`, `References`, `PartOfFile`, `FullName`,
`ModificationDate`, `FileSize` - sorted by function name.

## Check before you delete

A function is reported when its name is **never used as a command with a fixed name**. These
cases are not detected, so verify manually:

- calls through a variable or string: `& $name`, `Invoke-Command`, `. $script`
- names built at runtime (`& ("Invoke-" + $x)`); names written as quoted text are counted as references
- use from outside the module (tests, other modules, scripts in a `Tests` folder, which is not scanned)
- calls from outside the module' source files (other modules, build scripts)

A good routine: search the repository for the name, delete it, run your tests, commit.

## Examples

```powershell
# Biggest cleanup first
Get-PSModuleUnusedPrivateFunctions -ModuleName PSModuleQuantityAnalyzer |
    Sort-Object TotalLines -Descending
```

## Notes

- Public functions are never listed, because they are expected to have no caller inside the module.
- Equivalent query on the base data:
  `Get-PSModuleQuantity ... | Where-Object { $_.Type -eq 'Private' -and $_.References -eq 0 }`

## See also

[Get-PSModuleQuantity](Get-PSModuleQuantity.md) ·
[Get-PSModuleDependencyGraph](Get-PSModuleDependencyGraph.md)
