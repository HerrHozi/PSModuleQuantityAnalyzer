function Get-PSModuleSnapshotFiles {

    param(
        [Parameter(Mandatory)]
        [string]$Root
    )

    foreach ($item in (Get-ChildItem -LiteralPath $Root -Force | Where-Object Name -ne '.git')) {
        # OneDrive cloud placeholders also have ReparsePoint set; they are not links.
        # LinkType identifies symbolic links and junctions without rejecting cloud files.
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -and
            $item.LinkType -in @('SymbolicLink', 'Junction')) {
            throw "Links are unsupported: $($item.FullName)"
        }
        if ($item.PSIsContainer) { Get-PSModuleSnapshotFiles -Root $item.FullName } else { $item }
    }
}
