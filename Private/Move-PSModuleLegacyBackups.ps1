function Move-PSModuleLegacyBackups {

    param(
        [Parameter(Mandatory)]
        [string]$BackupFolder,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCmdlet]$Cmdlet
    )

    if (-not (Test-Path -LiteralPath $BackupFolder)) { return }
    foreach ($year in (Get-ChildItem -LiteralPath $BackupFolder -Directory | Where-Object Name -Match '^\d{4}$')) {
        foreach ($entry in (Get-ChildItem -LiteralPath $year.FullName)) {
            if ($entry.Name -notmatch '^(\d{4})\.(\d{1,2})\.\d{1,2}\.\d+(?:\.zip)?$') { continue }
            if ($Matches[1] -ne $year.Name) { continue }
            $month = [int]$Matches[2]
            if ($month -lt 1 -or $month -gt 12) { continue }
            $monthRoot = Join-Path $year.FullName ('{0:D2}' -f $month)
            $target = Join-Path $monthRoot $entry.Name
            $rootPrefix = [IO.Path]::GetFullPath($BackupFolder).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
            foreach ($candidate in @($entry.FullName, $target)) {
                if (-not ([IO.Path]::GetFullPath($candidate).StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase))) { throw 'Backup move outside backup root.' }
            }
            if (Test-Path -LiteralPath $target) { throw "Backup destination already exists: $target" }
            if ($Cmdlet.ShouldProcess($entry.FullName, "Move backup to $target")) {
                New-Item -ItemType Directory -Path $monthRoot -Force | Out-Null
                Move-Item -LiteralPath $entry.FullName -Destination $target
            }
        }
    }
}
