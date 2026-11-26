function Get-PSModuleManifestDependencies {

    <#
    Reads RequiredModules from a module manifest. The manifest is loaded with
    Import-PowerShellDataFile, so no code from the manifest is executed.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath,

        [string]$Type = 'Required (Manifest)',

        [string]$Location = 'Manifest'
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        Write-Verbose "Manifest file not found: $ManifestPath"
        return
    }

    try {
        $manifest = Import-PowerShellDataFile -LiteralPath $ManifestPath -ErrorAction Stop
    }
    catch {
        Write-Verbose "Cannot read manifest '$ManifestPath': $_"
        return
    }

    foreach ($req in @($manifest.RequiredModules)) {

        if (-not $req) { continue }

        if ($req -is [hashtable]) {
            $name = [string]$req.ModuleName
            $wanted = if ($req.RequiredVersion) { [string]$req.RequiredVersion } else { [string]$req.ModuleVersion }
        }
        else {
            $name = [string]$req
            $wanted = ''
        }

        if (-not $name) { continue }

        $minimum = $null
        if ($wanted) { [void][version]::TryParse($wanted, [ref]$minimum) }

        New-PSModuleDependencyRecord -Name $name -Type $Type -Locations @($Location) `
            -RequiredVersion $(if ($wanted) { $wanted } else { 'Any' }) -MinimumVersion $minimum
    }
}
