function Get-PSModuleAstCache {

    param(
        [Parameter(Mandatory)]
        $Files
    )

    if (-not $script:PSModuleParseWarned) { $script:PSModuleParseWarned = @{} }

    $cache = @{}

    foreach ($file in $Files) {

        $tokens = $null
        $errors = $null

        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $file.FullName,
            [ref]$tokens,
            [ref]$errors
        )

        # A file with syntax the running PowerShell version cannot parse (for example
        # PowerShell 7 syntax in Windows PowerShell 5.1) is analyzed only partly. Say so once
        # per file instead of silently returning incomplete numbers.
        if ($errors -and $errors.Count -gt 0) {
            $key = '{0}|{1}' -f $file.FullName, $file.LastWriteTimeUtc.Ticks
            if (-not $script:PSModuleParseWarned.ContainsKey($key)) {
                $script:PSModuleParseWarned[$key] = $true
                Write-Warning ("{0} parse error(s) in {1} (first: line {2}: {3}). Results for this file may be incomplete." -f
                    $errors.Count, $file.FullName, $errors[0].Extent.StartLineNumber, $errors[0].Message)
            }
        }

        $cache[$file.FullName] = $ast
    }

    return $cache
}
