function Get-PSModuleSourceFiles {

    param(
        [Parameter(Mandatory)]
        $Module,

        # Also return .psm1 files (needed where module loader code is analyzed, for example
        # for Import-Module statements). The function analysis only wants .ps1 files.
        [switch]$IncludePsm1
    )

    $base = [System.IO.Path]::GetFullPath($Module.ModuleBase).TrimEnd('\', '/') + '\'

    $files = if ($IncludePsm1) {
        Get-ChildItem $Module.ModuleBase -Recurse -File -Include '*.ps1', '*.psm1'
    }
    else {
        Get-ChildItem $Module.ModuleBase -Recurse -Filter *.ps1
    }

    # Exclusions are judged on the path below the module root, so a module that lives in a
    # folder called 'build' or 'docs' is not skipped completely.
    $files |
    Where-Object {
        $relative = if ($_.FullName.StartsWith($base, [System.StringComparison]::OrdinalIgnoreCase)) {
            $_.FullName.Substring($base.Length)
        }
        else {
            $_.FullName
        }
        $relative -notmatch '(^|[\\/])(tests|build|docs)[\\/]'
    }
}
