function New-PSModuleBackupArchives {

    param(
        [Parameter(Mandatory)]
        [string]$Module,

        [Parameter(Mandatory)]
        [string]$BackupFolder,

        [Parameter(Mandatory)]
        [string]$ArchiveFolder,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCmdlet]$Cmdlet
    )

    if (-not (Test-Path -LiteralPath $BackupFolder)) { return }
    # Windows PowerShell 5.1 needs both assemblies (ZipArchive types live in System.IO.Compression)
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    foreach ($year in (Get-ChildItem -LiteralPath $BackupFolder -Directory | Where-Object Name -Match '^\d{4}$')) {
        foreach ($month in (Get-ChildItem -LiteralPath $year.FullName -Directory | Where-Object Name -Match '^(0[1-9]|1[0-2])$')) {
            $target = Join-Path $ArchiveFolder ('{0}_{1}.{2}.zip' -f $Module, $year.Name, $month.Name)
            if (-not $Cmdlet.ShouldProcess($target, "Create or refresh verified ZIP from $($month.FullName); retain source backups")) { continue }
            $files = @(Get-PSModuleSnapshotFiles -Root $month.FullName | Where-Object {
                    # ZIP archives contain project data, without Git administrative files.
                    $_.Name -notin @('.gitignore', '.gitattributes', '.gitmodules', '.gitkeep', '.gitconfig', '.gitmessage', '.git-blame-ignore-revs')
                })
            New-Item -ItemType Directory -Path $ArchiveFolder -Force | Out-Null
            $temporary = Join-Path $ArchiveFolder ([guid]::NewGuid().ToString('N') + '.partial')
            $hashes = @{}
            try {
                $zip = [IO.Compression.ZipFile]::Open($temporary, [IO.Compression.ZipArchiveMode]::Create)
                try {
                    foreach ($file in $files) {
                        $relative = $file.FullName.Substring($month.FullName.Length).TrimStart('\', '/').Replace('\', '/')
                        $hashes[$relative] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
                        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $relative, [IO.Compression.CompressionLevel]::Optimal) | Out-Null
                        if ($hashes[$relative] -ne (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash) { throw "Source changed while archiving: $($file.FullName)" }
                    }
                }
                finally { $zip.Dispose() }
                $zip = [IO.Compression.ZipFile]::OpenRead($temporary)
                try {
                    if ($zip.Entries.Count -ne $hashes.Count) { throw "ZIP entry count mismatch: $target" }
                    foreach ($entry in $zip.Entries) {
                        $stream = $entry.Open()
                        $sha = [Security.Cryptography.SHA256]::Create()
                        try { $actual = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '') }
                        finally { $sha.Dispose(); $stream.Dispose() }
                        if ($hashes[$entry.FullName] -ne $actual) { throw "ZIP verification failed: $($entry.FullName)" }
                    }
                }
                finally { $zip.Dispose() }
                # Publish only after verification; keep the previous archive on failure.
                if (Test-Path -LiteralPath $target) {
                    $previous = $temporary + '.previous'
                    [IO.File]::Replace($temporary, $target, $previous)
                    Remove-Item -LiteralPath $previous -Force
                }
                else { [IO.File]::Move($temporary, $target) }
                Write-Host "Archive: $target ($($files.Count) files)"
            }
            finally {
                if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
            }
        }
    }
}
