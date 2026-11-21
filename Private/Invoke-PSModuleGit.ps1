function Invoke-PSModuleGit {

    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string[]]$Arguments
    )

    $output = & git -C $Path @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)" }
    $output
}
