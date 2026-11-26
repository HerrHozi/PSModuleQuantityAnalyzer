function New-PSModuleDependencyRecord {

    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Type,

        [int]$UsageCount = 0,

        [string[]]$Locations = @(),

        [string]$RequiredVersion = 'Any',

        [version]$MinimumVersion
    )

    $installed = Get-Module -Name $Name -ListAvailable -ErrorAction SilentlyContinue |
    Sort-Object Version -Descending |
    Select-Object -First 1

    $isInstalled = $null -ne $installed

    # Locally compatible = installed, and not older than the version the dependency asks for.
    $compatible = $isInstalled -and (-not $MinimumVersion -or $installed.Version -ge $MinimumVersion)

    [PSCustomObject]@{
        ModuleName        = $Name
        Dependency        = $Name
        DependencyType    = $Type
        UsageCount        = $UsageCount
        LocationsUsed     = @($Locations)
        RequiredVersion   = $RequiredVersion
        InstalledVersion  = if ($installed) { $installed.Version } else { $null }
        IsInstalled       = $isInstalled
        VersionCompatible = $compatible
        LastChecked       = Get-Date
    }
}
