function Get-PSModuleReferenceMap {

    param(
        [Parameter(Mandatory)]
        $AstCache
    )

    $map = @{}

    foreach ($ast in $AstCache.Values) {

        # 1) Commands with a fixed name: Get-Something -Param value
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

        # 2) Function names written as text, which are used without a direct call:
        #    & 'Get-Something', Get-Command 'Get-Something', -FunctionName 'Get-Something',
        #    hashtables of function names, Invoke-Command, splatted dispatch tables.
        #    Only values that look like Verb-Noun count. The command name itself (already
        #    counted above) is not counted twice.
        $strings = $ast.FindAll({

                param($node)
                $node -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
                $node.Value -match '^[A-Za-z]+-[A-Za-z][A-Za-z0-9]*$'

            }, $true)

        foreach ($string in $strings) {

            $parent = $string.Parent
            if ($parent -is [System.Management.Automation.Language.CommandAst] -and
                [object]::ReferenceEquals($parent.CommandElements[0], $string)) {
                continue
            }

            $name = $string.Value

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
