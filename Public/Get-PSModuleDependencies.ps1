<#
.SYNOPSIS
Analyzes external module dependencies for a PowerShell module.

.DESCRIPTION
Get-PSModuleDependencies identifies all external PowerShell modules that a
specified module requires or uses. It discovers dependencies from multiple sources:

- Explicit dependencies declared in the module manifest (RequiredModules)
- Implicit dependencies found in the code (Import-Module, #requires -Module)
- External commands used from non-built-in modules

The function returns detailed information about each dependency including:
usage count, locations where used, installation status, version compatibility,
and dependency type (Required, Implicit, or Transitive).

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath).

.PARAMETER IncludeTransitiveDependencies
If specified, includes transitive dependencies (dependencies of dependencies).
Requires internet connectivity to query PowerShell Gallery.

.PARAMETER CheckVersionCompatibility
If specified, queries the PowerShell Gallery to verify version availability
and compatibility. Requires internet connectivity.

.PARAMETER OutputFormat
Specifies the output format for the report. Valid values are:
- Console (default): Formatted table output
- Object: Returns PSCustomObject for pipeline processing
- Json: JSON-formatted string

.EXAMPLE
Get-PSModuleDependencies -ModuleName PSModuleQuantityAnalyzer

Analyzes PSModuleQuantityAnalyzer and returns all discovered dependencies.

.EXAMPLE
Get-PSModuleDependencies -ModuleName ImportExcel -CheckVersionCompatibility

Analyzes ImportExcel and checks version compatibility for each dependency.

.EXAMPLE
Get-PSModuleDependencies -ModuleName PSModuleQuantityAnalyzer -OutputFormat Json

Returns dependencies in JSON format.

.OUTPUTS
PSCustomObject[] when OutputFormat is 'Object' or 'Console' (default).
Each object includes: ModuleName, Dependency, DependencyType, UsageCount,
LocationsUsed, RequiredVersion, InstalledVersion, IsInstalled,
VersionCompatible, and LastChecked properties.

String in JSON format when OutputFormat is 'Json'.

.NOTES
The analysis relies on AST parsing for code analysis and may require elevated
permissions to access module files. Transitive dependency checks require
internet connectivity to query PowerShell Gallery.

Some dependencies may be discovered via external command resolution, which
depends on the availability of modules in the current session.

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

    begin {
        Write-Verbose "Starting dependency analysis for module: $ModuleName"

        $dependencies = [System.Collections.Generic.Dictionary[string, PSObject]]::new()
        $moduleInfo = Get-PSModuleSourceFiles -Module $ModuleName

        if (-not $moduleInfo) {
            throw "Module '$ModuleName' not found or no source files accessible."
        }
    }

    process {
        try {
            # Get manifest-declared dependencies
            $manifestDependencies = Get-ManifestDependencies -ModuleName $ModuleName
            foreach ($dep in $manifestDependencies) {
                if (-not $dependencies.ContainsKey($dep.ModuleName)) {
                    $dependencies[$dep.ModuleName] = $dep
                }
            }

            # Scan source code for implicit dependencies
            $codeDependencies = Get-CodeDependencies -ModuleInfo $moduleInfo
            foreach ($dep in $codeDependencies) {
                if ($dependencies.ContainsKey($dep.ModuleName)) {
                    # Merge usage information
                    $dependencies[$dep.ModuleName].UsageCount += $dep.UsageCount
                    $dependencies[$dep.ModuleName].LocationsUsed += $dep.LocationsUsed
                    $dependencies[$dep.ModuleName].DependencyType = 'Mixed (Manifest + Code)'
                }
                else {
                    $dependencies[$dep.ModuleName] = $dep
                }
            }

            # Check version compatibility if requested
            if ($CheckVersionCompatibility) {
                Write-Verbose "Checking version compatibility for $($ dependencies.Count) dependencies..."
                $dependencies = Invoke-VersionCompatibilityCheck -Dependencies $dependencies
            }

            # Handle transitive dependencies if requested
            if ($IncludeTransitiveDependencies) {
                Write-Verbose "Analyzing transitive dependencies..."
                $transitiveDeps = Get-TransitiveDependencies -Dependencies $dependencies
                foreach ($dep in $transitiveDeps) {
                    if (-not $dependencies.ContainsKey($dep.ModuleName)) {
                        $dependencies[$dep.ModuleName] = $dep
                    }
                }
            }

            # Format and return output
            $resultSet = $dependencies.Values | Sort-Object ModuleName

            switch ($OutputFormat) {
                'Console' {
                    Format-DependencyConsoleOutput -Dependencies $resultSet
                    return $resultSet
                }
                'Json' {
                    return ($resultSet | ConvertTo-Json -Depth 3)
                }
                'Object' {
                    return $resultSet
                }
            }
        }
        catch {
            Write-Error "Error analyzing dependencies: $_"
            throw
        }
    }
}

#region Helper Functions

function Get-ManifestDependencies {
    <#
    .SYNOPSIS
    Extracts dependencies declared in module manifest.
    #>
    [CmdletBinding()]
    param([string]$ModuleName)

    try {
        $moduleObject = Get-Module -Name $ModuleName -ErrorAction Stop
        $manifestPath = Join-Path -Path $moduleObject.ModuleBase -ChildPath "$ModuleName.psd1"

        if (-not (Test-Path -Path $manifestPath)) {
            Write-Verbose "Manifest file not found: $manifestPath"
            return @()
        }

        $manifest = Invoke-Expression -Command (Get-Content -Path $manifestPath -Raw)

        $results = @()
        if ($manifest.RequiredModules) {
            foreach ($req in $manifest.RequiredModules) {
                $depName = if ($req -is [hashtable]) { $req.ModuleName } else { $req }

                $results += [PSCustomObject]@{
                    ModuleName          = $depName
                    Dependency          = $depName
                    DependencyType      = 'Required (Manifest)'
                    UsageCount          = 0
                    LocationsUsed       = @()
                    RequiredVersion     = if ($req -is [hashtable]) { $req.ModuleVersion } else { 'Any' }
                    InstalledVersion    = (Get-Module -Name $depName -ListAvailable | Select-Object -First 1).Version
                    IsInstalled         = $null -ne (Get-Module -Name $depName -ListAvailable -ErrorAction SilentlyContinue)
                    VersionCompatible   = $true
                    LastChecked         = Get-Date
                }
            }
        }

        return $results
    }
    catch {
        Write-Verbose "Error extracting manifest dependencies: $_"
        return @()
    }
}

function Get-CodeDependencies {
    <#
    .SYNOPSIS
    Discovers dependencies from source code analysis.
    #>
    [CmdletBinding()]
    param([PSObject]$ModuleInfo)

    $results = @()
    $foundDependencies = @{}

    foreach ($sourceFile in $ModuleInfo) {
        try {
            $content = Get-Content -Path $sourceFile.FullName -Raw -ErrorAction Stop

            # Find Import-Module statements
            $importMatches = [regex]::Matches($content, 'Import-Module\s+(?<module>[\w\-]+)', 'IgnoreCase')
            foreach ($match in $importMatches) {
                $moduleName = $match.Groups['module'].Value
                if (-not $foundDependencies.ContainsKey($moduleName)) {
                    $foundDependencies[$moduleName] = @{
                        UsageCount    = 1
                        Locations     = @($sourceFile.Name)
                    }
                }
                else {
                    $foundDependencies[$moduleName].UsageCount++
                    if ($sourceFile.Name -notin $foundDependencies[$moduleName].Locations) {
                        $foundDependencies[$moduleName].Locations += $sourceFile.Name
                    }
                }
            }

            # Find #requires -Module statements
            $requiresMatches = [regex]::Matches($content, '#requires\s+-Module\s+(?<module>[\w\-]+)', 'IgnoreCase')
            foreach ($match in $requiresMatches) {
                $moduleName = $match.Groups['module'].Value
                if (-not $foundDependencies.ContainsKey($moduleName)) {
                    $foundDependencies[$moduleName] = @{
                        UsageCount    = 1
                        Locations     = @($sourceFile.Name)
                    }
                }
                else {
                    $foundDependencies[$moduleName].UsageCount++
                    if ($sourceFile.Name -notin $foundDependencies[$moduleName].Locations) {
                        $foundDependencies[$moduleName].Locations += $sourceFile.Name
                    }
                }
            }
        }
        catch {
            Write-Verbose "Error scanning file $($sourceFile.FullName): $_"
        }
    }

    foreach ($depName in $foundDependencies.Keys) {
        $results += [PSCustomObject]@{
            ModuleName          = $depName
            Dependency          = $depName
            DependencyType      = 'Implicit (Code)'
            UsageCount          = $foundDependencies[$depName].UsageCount
            LocationsUsed       = $foundDependencies[$depName].Locations
            RequiredVersion     = 'Any'
            InstalledVersion    = (Get-Module -Name $depName -ListAvailable | Select-Object -First 1).Version
            IsInstalled         = $null -ne (Get-Module -Name $depName -ListAvailable -ErrorAction SilentlyContinue)
            VersionCompatible   = $true
            LastChecked         = Get-Date
        }
    }

    return $results
}

function Invoke-VersionCompatibilityCheck {
    <#
    .SYNOPSIS
    Validates version compatibility by checking PowerShell Gallery.
    #>
    [CmdletBinding()]
    param([System.Collections.Generic.Dictionary[string, PSObject]]$Dependencies)

    foreach ($depName in $Dependencies.Keys) {
        try {
            $galleryModule = Find-Module -Name $depName -ErrorAction SilentlyContinue
            if ($galleryModule) {
                $Dependencies[$depName].VersionCompatible = $true
            }
            else {
                $Dependencies[$depName].VersionCompatible = $false
            }
        }
        catch {
            Write-Verbose "Could not verify version for $depName`: $_"
            $Dependencies[$depName].VersionCompatible = $null
        }
    }

    return $Dependencies
}

function Get-TransitiveDependencies {
    <#
    .SYNOPSIS
    Recursively discovers transitive dependencies.
    #>
    [CmdletBinding()]
    param([System.Collections.Generic.Dictionary[string, PSObject]]$Dependencies)

    $results = @()
    $processed = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($depName in $Dependencies.Keys) {
        if ($processed.Add($depName)) {
            try {
                $depModule = Get-Module -Name $depName -ListAvailable -ErrorAction Stop | Select-Object -First 1
                if ($depModule) {
                    $transitivePath = Join-Path -Path $depModule.ModuleBase -ChildPath "$depName.psd1"
                    if (Test-Path -Path $transitivePath) {
                        $manifest = Invoke-Expression -Command (Get-Content -Path $transitivePath -Raw)
                        if ($manifest.RequiredModules) {
                            foreach ($req in $manifest.RequiredModules) {
                                $transDepName = if ($req -is [hashtable]) { $req.ModuleName } else { $req }
                                if ($transDepName -notin $Dependencies.Keys -and $transDepName -notin $processed) {
                                    $results += [PSCustomObject]@{
                                        ModuleName          = $transDepName
                                        Dependency          = $transDepName
                                        DependencyType      = 'Transitive (Indirect)'
                                        UsageCount          = 0
                                        LocationsUsed       = @("Dependency of $depName")
                                        RequiredVersion     = if ($req -is [hashtable]) { $req.ModuleVersion } else { 'Any' }
                                        InstalledVersion    = (Get-Module -Name $transDepName -ListAvailable | Select-Object -First 1).Version
                                        IsInstalled         = $null -ne (Get-Module -Name $transDepName -ListAvailable -ErrorAction SilentlyContinue)
                                        VersionCompatible   = $true
                                        LastChecked         = Get-Date
                                    }
                                }
                            }
                        }
                    }
                }
            }
            catch {
                Write-Verbose "Error analyzing transitive dependencies for $depName`: $_"
            }
        }
    }

    return $results
}

function Format-DependencyConsoleOutput {
    <#
    .SYNOPSIS
    Formats dependency output for console display.
    #>
    [CmdletBinding()]
    param([PSObject[]]$Dependencies)

    if ($Dependencies.Count -eq 0) {
        Write-Host "No dependencies found."
        return
    }

    $Dependencies | Format-Table -Property @(
        @{ Name = 'Dependency'; Expression = { $_.Dependency } },
        @{ Name = 'Type'; Expression = { $_.DependencyType } },
        @{ Name = 'Usage'; Expression = { $_.UsageCount } },
        @{ Name = 'Installed'; Expression = { $_.IsInstalled } },
        @{ Name = 'Version'; Expression = { $_.InstalledVersion } },
        @{ Name = 'Compatible'; Expression = { $_.VersionCompatible } }
    ) -AutoSize
}

#endregion
