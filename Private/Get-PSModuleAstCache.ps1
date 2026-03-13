function Get-PSModuleAstCache {

    param(
        [Parameter(Mandatory)]
        $Files
    )

    $cache = @{}

    foreach ($file in $Files) {

        $tokens = $null
        $errors = $null

        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $file.FullName,
            [ref]$tokens,
            [ref]$errors
        )

        $cache[$file.FullName] = $ast
    }

    return $cache
}