function Invoke-PSModuleGit {

    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string[]]$Arguments
    )

    # Windows PowerShell 5.1 turns every stderr line of a native command into a terminating
    # error when stderr is redirected (2>&1) and $ErrorActionPreference is 'Stop'. Git writes
    # warnings and progress to stderr, so judge success by the exit code only.
    $ErrorActionPreference = 'Continue'

    $output = & git -C $Path @Arguments 2>&1 | ForEach-Object { "$_" }
    if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)" }
    $output
}
