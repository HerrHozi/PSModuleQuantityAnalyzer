function Format-PSModuleDependencyOutput {

    [CmdletBinding()]
    param(
        [PSObject[]]$Dependencies
    )

    if (-not $Dependencies -or $Dependencies.Count -eq 0) {
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
