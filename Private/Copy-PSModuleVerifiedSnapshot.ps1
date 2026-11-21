function Copy-PSModuleVerifiedSnapshot {

    param(
        [Parameter(Mandatory)]
        [string]$Root,

        [Parameter(Mandatory)]
        [string]$Destination,

        [Parameter(Mandatory)]
        [System.IO.FileInfo[]]$Files
    )

    if (Test-Path -LiteralPath $Destination) { throw "Destination already exists: $Destination" }
    New-Item -ItemType Directory -Path $Destination | Out-Null
    foreach ($file in $Files) {
        $relative = $file.FullName.Substring($Root.Length).TrimStart('\', '/')
        $target = Join-Path $Destination $relative
        $before = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $target
        if ($before -ne (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -or
            $before -ne (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash) {
            throw "Snapshot verification failed: $relative. Incomplete snapshot retained at $Destination"
        }
    }
}
