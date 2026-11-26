<#
.SYNOPSIS
Analyzes external module dependencies for a PowerShell module.

.DESCRIPTION
Get-PSModuleDependencies identifies all external PowerShell modules that a
specified module requires or uses. It discovers dependencies from multiple sources:

- Explicit dependencies declared in the module manifest (RequiredModules)
- Implicit dependencies found in the code with the PowerShell parser:
  Import-Module (positional, -Name, several names, alias ipmo), using module and
  #requires -Modules. Comments and strings are ignored.
- Transitive dependencies (RequiredModules of the dependencies), on request

The function returns detailed information about each dependency including:
usage count, locations where used, installation status, the installed version,
whether the installed version satisfies the requested version, and the dependency
type (Required, Implicit, Mixed or Transitive).

.PARAMETER ModuleName
Specifies the module to analyze: the name of an installed module (the highest
version is used) or the path to a module manifest (.psd1).

.PARAMETER IncludeTransitiveDependencies
If specified, includes transitive dependencies (dependencies of dependencies, on
all levels). Only dependencies that are installed on this computer can be followed.

.PARAMETER CheckVersionCompatibility
If specified, queries the PowerShell Gallery (Find-Module) and adds the property
AvailableInGallery to each dependency. Requires internet connectivity and the
PowerShellGet module.

.PARAMETER OutputFormat
Specifies the output format for the report. Valid values are:
- Object (default): Returns PSCustomObject for pipeline processing
- Console: Shows a formatted table and also returns the objects
- Json: JSON-formatted string

.EXAMPLE
Get-PSModuleDependencies -ModuleName PSModuleQuantityAnalyzer

Analyzes PSModuleQuantityAnalyzer and returns all discovered dependencies.

.EXAMPLE
Get-PSModuleDependencies -ModuleName .\AS2Go.psd1 -OutputFormat Console

Analyzes the module behind a manifest and shows the result as a table.

.EXAMPLE
Get-PSModuleDependencies -ModuleName ImportExcel -CheckVersionCompatibility

Analyzes ImportExcel and checks for each dependency whether it exists in the
PowerShell Gallery.

.EXAMPLE
Get-PSModuleDependencies -ModuleName PSModuleQuantityAnalyzer -OutputFormat Json

Returns dependencies in JSON format.

.OUTPUTS
PSCustomObject[] when OutputFormat is 'Object' or 'Console'.
Each object includes: ModuleName, Dependency, DependencyType, UsageCount,
LocationsUsed, RequiredVersion, InstalledVersion, IsInstalled,
VersionCompatible and LastChecked (plus AvailableInGallery with
-CheckVersionCompatibility).

String in JSON format when OutputFormat is 'Json'.

.NOTES
The analysis relies on AST parsing. Names that cannot be determined statically
(variables, expandable strings, paths) are skipped, as are the module itself and
imports by path. Dependencies used only through module auto-loading are not found.
VersionCompatible is True when the dependency is installed and not older than the
requested minimum version.

.LINK
https://github.com/HerrHozi/PSModuleQuantityAnalyzer
#>
function Get-PSModuleDependencies {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [switch]$IncludeTransitiveDependencies,

        [switch]$CheckVersionCompatibility,

        [ValidateSet('Console', 'Object', 'Json')]
        [string]$OutputFormat = 'Object'
    )

    Write-Verbose "Starting dependency analysis for module: $ModuleName"

    $module = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1

    if (-not $module) {
        throw "Module '$ModuleName' was not found."
    }

    $files = @(Get-PSModuleSourceFiles -Module $module -IncludePsm1)

    $manifestPath = if ($module.Path -like '*.psd1') { $module.Path } else { Join-Path $module.ModuleBase "$($module.Name).psd1" }

    # Case-insensitive on purpose: module names are not case sensitive.
    $dependencies = @{}

    foreach ($dep in @(Get-PSModuleManifestDependencies -ManifestPath $manifestPath)) {
        if (-not $dependencies.ContainsKey($dep.ModuleName)) {
            $dependencies[$dep.ModuleName] = $dep
        }
    }

    foreach ($dep in @(Get-PSModuleCodeDependencies -Module $module -Files $files)) {
        if ($dependencies.ContainsKey($dep.ModuleName)) {
            $existing = $dependencies[$dep.ModuleName]
            $existing.UsageCount += $dep.UsageCount
            $existing.LocationsUsed = @($existing.LocationsUsed) + @($dep.LocationsUsed | Where-Object { $_ -notin $existing.LocationsUsed })
            $existing.DependencyType = 'Mixed (Manifest + Code)'
        }
        else {
            $dependencies[$dep.ModuleName] = $dep
        }
    }

    if ($IncludeTransitiveDependencies) {
        Write-Verbose "Analyzing transitive dependencies..."
        foreach ($dep in @(Get-PSModuleTransitiveDependencies -Known $dependencies)) {
            if (-not $dependencies.ContainsKey($dep.ModuleName)) {
                $dependencies[$dep.ModuleName] = $dep
            }
        }
    }

    if ($CheckVersionCompatibility) {
        Write-Verbose "Checking the PowerShell Gallery for $($dependencies.Count) dependencies..."
        $canSearch = [bool](Get-Command -Name Find-Module -ErrorAction SilentlyContinue)
        foreach ($dep in $dependencies.Values) {
            $available = $null
            if ($canSearch) {
                try { $available = $null -ne (Find-Module -Name $dep.ModuleName -ErrorAction SilentlyContinue) }
                catch { Write-Verbose "Gallery lookup failed for $($dep.ModuleName): $_" }
            }
            Add-Member -InputObject $dep -NotePropertyName AvailableInGallery -NotePropertyValue $available -Force
        }
    }

    $resultSet = @($dependencies.Values | Sort-Object ModuleName)

    switch ($OutputFormat) {
        'Console' {
            Format-PSModuleDependencyOutput -Dependencies $resultSet
            return $resultSet
        }
        'Json' {
            return ($resultSet | ConvertTo-Json -Depth 3)
        }
        default {
            return $resultSet
        }
    }
}
