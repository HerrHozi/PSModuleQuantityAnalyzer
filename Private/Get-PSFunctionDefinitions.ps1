function Get-PSFunctionDefinitions {

    param(
        [Parameter(Mandatory)]
        $AstCache
    )

    foreach ($file in $AstCache.Keys) {

        $ast = $AstCache[$file]

        $funcs = $ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true)

        foreach ($func in $funcs) {

            [PSCustomObject]@{
                Name      = $func.Name
                StartLine = $func.Extent.StartLineNumber
                EndLine   = $func.Extent.EndLineNumber
                File      = $file
                Ast       = $func
            }

        }
    }
}