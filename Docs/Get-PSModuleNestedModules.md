# Guide: Get-PSModuleNestedModules

`Get-PSModuleNestedModules` gives a metrics table for a module that is built from **nested
modules**: one row per nested module plus one row `(main)` for the module itself.

## Usage

```powershell
Get-PSModuleNestedModules -ModuleName .\MyModule.psd1 | Format-Table
```

## Which nested modules are found

The command reads `NestedModules` from the manifest.

- A nested module counts as separate **only if it is located in a sub folder** of the module.
  Entries can point to a folder, a manifest or a file; the folder of the entry becomes the root.
- Nested modules placed directly in the module folder are part of `(main)`.
- Entries that do not exist on disk are skipped.

## Output properties

| Property | Meaning |
| --- | --- |
| `NestedModule` | Name (folder name), or `(main)` |
| `Version` | `ModuleVersion` of the nested module's manifest (first `.psd1` in its folder), or of the main module |
| `Functions`, `Public`, `Private` | Function counts; `Public` means the file is located in a `Public` folder |
| `Files` | Number of source files |
| `TotalLines`, `LinesOfCode`, `LinesOfComment` | Sums over the functions |
| `CommentRatio` | `LinesOfComment / TotalLines` in percent, 1 decimal |
| `Path` | Root folder of the (nested) module |

## Examples

```powershell
# Which nested module is the biggest?
Get-PSModuleNestedModules -ModuleName .\MyModule.psd1 | Sort-Object TotalLines -Descending

# Quick check whether a module uses nested modules
(Get-PSModuleSummary -ModuleName .\MyModule.psd1).NestedModules
```

## See also

[Get-PSModuleNestedDependencies](Get-PSModuleNestedDependencies.md) ·
[Get-PSModuleSummary](Get-PSModuleSummary.md)
