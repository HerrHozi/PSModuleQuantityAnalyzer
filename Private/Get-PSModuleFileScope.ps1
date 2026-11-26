function Get-PSModuleFileScope {

    <#
    Classifies a file by the folders in its path below the module root.
    Returns 'Public' when any folder is named Public, 'Private' when any folder is named
    Private (subfolders such as Private\ASP07 included), otherwise 'Other'.
    Only the part below the module root is inspected, so folders above the module
    (for example C:\Users\Public\...) never influence the result.
    #>

    param(
        [Parameter(Mandatory)]
        [string]$RelativePath
    )

    if ($RelativePath -match '(^|[\\/])Public[\\/]') { return 'Public' }
    if ($RelativePath -match '(^|[\\/])Private[\\/]') { return 'Private' }
    'Other'
}
