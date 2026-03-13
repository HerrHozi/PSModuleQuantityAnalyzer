function Get-PSModuleReferenceMap {

    param(
        [Parameter(Mandatory)]
        $AstCache
    )

    $map = @{}

    foreach ($ast in $AstCache.Values) {

        $commands = $ast.FindAll({

                param($node)
                $node -is [System.Management.Automation.Language.CommandAst]

            }, $true)

        foreach ($cmd in $commands) {

            $name = $cmd.GetCommandName()

            if (-not $name) { continue }

            if ($map.ContainsKey($name)) {
                $map[$name]++
            }
            else {
                $map[$name] = 1
            }

        }
    }

    return $map
}