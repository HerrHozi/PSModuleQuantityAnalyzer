function Get-PSModuleTransitiveDependencies {

    <#
    Follows RequiredModules of the dependencies, across all levels. Each dependency is
    visited once, so circular references end. Manifests are read with
    Import-PowerShellDataFile; only installed dependencies can be followed.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Known
    )

    $queue = [System.Collections.Generic.Queue[string]]::new()
    $visited = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($name in $Known.Keys) { [void]$seen.Add($name); $queue.Enqueue($name) }

    while ($queue.Count -gt 0) {

        $current = $queue.Dequeue()
        if (-not $visited.Add($current)) { continue }

        $installed = Get-Module -Name $current -ListAvailable -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1
        if (-not $installed) { continue }

        $manifestPath = if ($installed.Path -like '*.psd1') { $installed.Path } else { Join-Path $installed.ModuleBase "$current.psd1" }

        foreach ($record in (Get-PSModuleManifestDependencies -ManifestPath $manifestPath -Type 'Transitive (Indirect)' -Location "Dependency of $current")) {
            if ($seen.Add($record.ModuleName)) {
                $queue.Enqueue($record.ModuleName)
                $record
            }
        }
    }
}
