# Guide: Get-PSModuleNestedDependencies

`Get-PSModuleNestedDependencies` lists every call that **crosses the boundary** between the main
module and a nested module, or between two nested modules. It shows how tightly they are coupled
and whether a nested module could be published on its own.

## Usage

```powershell
Get-PSModuleNestedDependencies -ModuleName .\MyModule.psd1
Get-PSModuleNestedDependencies -ModuleName .\MyModule.psd1 | Group-Object FromModule, ToModule
```

## Output properties

| Property | Meaning |
| --- | --- |
| `Function` | Calling function |
| `FromModule` | Module of the caller (`(main)` or nested module name) |
| `Calls` | Called function |
| `ToModule` | Module in which the called function is defined |
| `File` | File of the calling function |

Calls inside the same module are not listed.

## How to read it

| Result | Meaning |
| --- | --- |
| No rows | The modules are independent |
| Rows `Nested` to `(main)` | The nested module needs the main module. It cannot be published alone without it |
| Rows `(main)` to `Nested` | The normal case: the main module uses its nested modules |
| Many rows between two modules | Tight coupling; consider merging them or moving shared functions |

## Examples

```powershell
# Can nested module 'Core' stand alone?
Get-PSModuleNestedDependencies -ModuleName .\MyModule.psd1 |
    Where-Object FromModule -eq 'Core'
```

## Notes

- Only calls to functions defined in the module's own sources are found.
- If the same function name exists in several modules, the first definition decides `ToModule`.
- Without nested modules, the result is empty.

## See also

[Get-PSModuleNestedModules](Get-PSModuleNestedModules.md) ·
[Get-PSModuleDependencyGraph](Get-PSModuleDependencyGraph.md)
