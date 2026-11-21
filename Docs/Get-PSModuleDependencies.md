# Guide: Get-PSModuleDependencies

`Get-PSModuleDependencies` finds the **external PowerShell modules** that a module needs: modules
declared in the manifest and modules that are imported in the code.

## Usage

```powershell
Get-PSModuleDependencies -ModuleName MyModule
Get-PSModuleDependencies -ModuleName MyModule -OutputFormat Console
Get-PSModuleDependencies -ModuleName MyModule -CheckVersionCompatibility
Get-PSModuleDependencies -ModuleName MyModule -IncludeTransitiveDependencies -OutputFormat Json
```

## Parameters

| Parameter | Description |
| --- | --- |
| `-ModuleName` | Module to analyze (mandatory) |
| `-IncludeTransitiveDependencies` | Also add the `RequiredModules` of the dependencies |
| `-CheckVersionCompatibility` | Check each dependency against the PowerShell Gallery (needs internet and `Find-Module`) |
| `-OutputFormat` | `Object` (default, returns objects), `Console` (shows a table and returns the objects) or `Json` |

## Where dependencies come from

| `DependencyType` | Source |
| --- | --- |
| `Required (Manifest)` | `RequiredModules` in the manifest |
| `Implicit (Code)` | `Import-Module <name>` or `#requires -Module <name>` in a `.ps1` file |
| `Mixed (Manifest + Code)` | found in both; usage counts are added |
| `Transitive (Indirect)` | `RequiredModules` of a dependency (only with `-IncludeTransitiveDependencies`) |

## Output properties

`ModuleName`, `Dependency`, `DependencyType`, `UsageCount`, `LocationsUsed` (file names),
`RequiredVersion`, `InstalledVersion`, `IsInstalled`, `VersionCompatible`, `LastChecked`.

`VersionCompatible` is `True` by default. With `-CheckVersionCompatibility` it becomes `True` when
the module exists in the Gallery, `False` when it does not and empty when the check failed. It does
not compare version numbers.

## Limitations - please read

- The **module must be loaded** (`Import-Module`) for the manifest part, because the manifest is
  looked up through `Get-Module`. The manifest is expected to be named `<ModuleName>.psd1`.
- The code scan uses text patterns, not the parser. It finds only the forms `Import-Module Name`
  and `#requires -Module Name`. These are **not** found: `Import-Module -Name X`, quoted names,
  `using module`, `Requires -Modules` with several names, and calls to commands of modules that
  were never imported explicitly. Matches inside comments and strings are counted.
- Dependencies that are only used implicitly through module auto-loading are not detected.
- The manifest is read by evaluating its content, so analyze only modules you trust.

## Examples

```powershell
# What is missing on this machine?
Get-PSModuleDependencies -ModuleName MyModule | Where-Object { -not $_.IsInstalled }

# Export for documentation
Get-PSModuleDependencies -ModuleName MyModule -OutputFormat Json | Set-Content .\dependencies.json
```

## See also

[Get-PSModuleDependencyGraph](Get-PSModuleDependencyGraph.md) (calls between your own functions)
