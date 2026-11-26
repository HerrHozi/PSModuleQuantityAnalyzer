# Guide: Get-PSModuleDependencies

`Get-PSModuleDependencies` finds the **external PowerShell modules** that a module needs: modules
declared in the manifest and modules that are imported in the code.

## Usage

```powershell
Get-PSModuleDependencies -ModuleName MyModule
Get-PSModuleDependencies -ModuleName .\MyModule.psd1 -OutputFormat Console
Get-PSModuleDependencies -ModuleName MyModule -CheckVersionCompatibility
Get-PSModuleDependencies -ModuleName MyModule -IncludeTransitiveDependencies -OutputFormat Json
```

## Parameters

| Parameter | Description |
| --- | --- |
| `-ModuleName` | Name of an installed module (highest version is used) or path to a manifest `.psd1` (mandatory) |
| `-IncludeTransitiveDependencies` | Also add the `RequiredModules` of the dependencies, on all levels. Only installed dependencies can be followed |
| `-CheckVersionCompatibility` | Ask the PowerShell Gallery whether each dependency exists there and add the property `AvailableInGallery`. Needs internet and `Find-Module` |
| `-OutputFormat` | `Object` (default, returns objects), `Console` (shows a table and returns the objects) or `Json` |

## Where dependencies come from

| `DependencyType` | Source |
| --- | --- |
| `Required (Manifest)` | `RequiredModules` in the manifest |
| `Implicit (Code)` | found in the code, see below |
| `Mixed (Manifest + Code)` | found in both; usage counts and locations are added |
| `Transitive (Indirect)` | `RequiredModules` of a dependency (only with `-IncludeTransitiveDependencies`) |

The code is analyzed with the PowerShell parser, so **comments and strings are ignored**. These
forms are found in `.ps1` and `.psm1` files:

```powershell
Import-Module ThreadJob
Import-Module -Name 'Pester', 'PSReadLine' -Force      # also the alias ipmo, abbreviations like -Na
using module Microsoft.PowerShell.Management
#requires -Modules Microsoft.PowerShell.Utility
```

## Output properties

| Property | Meaning |
| --- | --- |
| `ModuleName`, `Dependency` | Name of the required module |
| `DependencyType` | See above |
| `UsageCount` | Number of places in the code that ask for the module |
| `LocationsUsed` | Files (path below the module root), `Manifest`, or `Dependency of <module>` |
| `RequiredVersion` | Requested version from the manifest or `#requires`, otherwise `Any` |
| `InstalledVersion`, `IsInstalled` | Highest version installed on this computer |
| `VersionCompatible` | `True` when the dependency is installed and not older than the requested version |
| `LastChecked` | Time of the check |
| `AvailableInGallery` | Only with `-CheckVersionCompatibility`: `True`, `False`, or empty if the Gallery could not be queried |

## Limitations

- Names that cannot be known without running the code are skipped: `Import-Module $name`,
  expandable strings such as `"$PSScriptRoot\x"` and paths (`.\x.psm1`, `C:\...\x.psd1`).
- The module itself is never listed as its own dependency.
- Modules that are only loaded by PowerShell's automatic module loading are not found.
- A dependency that is not installed cannot be followed for transitive dependencies.
- The manifest is read as data (`Import-PowerShellDataFile`); no code from it is executed.

## Examples

```powershell
# What is missing on this machine?
Get-PSModuleDependencies -ModuleName .\MyModule.psd1 | Where-Object { -not $_.IsInstalled }

# Which dependency is too old?
Get-PSModuleDependencies -ModuleName .\MyModule.psd1 | Where-Object { $_.IsInstalled -and -not $_.VersionCompatible }

# Export for documentation
Get-PSModuleDependencies -ModuleName .\MyModule.psd1 -OutputFormat Json | Set-Content .\dependencies.json
```

## See also

[Get-PSModuleDependencyGraph](Get-PSModuleDependencyGraph.md) (calls between your own functions)
