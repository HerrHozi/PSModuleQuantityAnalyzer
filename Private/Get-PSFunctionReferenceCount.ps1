function Get-PSFunctionReferenceCount {

    param(
        [string]$FunctionName,
        $AstCache
    )

    $count = 0

    foreach ($ast in $AstCache.Values) {

        $matches = $ast.FindAll({
                param($node)

                $node -is [System.Management.Automation.Language.CommandAst] -and
                $node.GetCommandName() -eq $FunctionName

            }, $true)

        $count += $matches.Count
    }

    return $count
}

function Get-PSFunctionReferenceCount_old {

    param(
        [Parameter(Mandatory)]
        [string]$FunctionName,

        [Parameter(Mandatory)]
        $Files
    )

    $count = 0

    foreach ($file in $Files) {

        $content = Get-Content $file.FullName -Raw

        $matches = ([regex]::Matches($content, "\b$FunctionName\b")).Count

        $count += $matches
    }

    if ($count -gt 0) {
        $count - 1
    }
    else {
        0
    }

}