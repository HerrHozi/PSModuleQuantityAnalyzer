function Get-PSModuleSourceFiles {

    param(
        [Parameter(Mandatory)]
        $Module
    )

    Get-ChildItem $Module.ModuleBase -Recurse -Filter *.ps1 |
    Where-Object {
        $_.FullName -notmatch '\\tests\\' -and
        $_.FullName -notmatch '\\build\\' -and
        $_.FullName -notmatch '\\docs\\'
    }
}