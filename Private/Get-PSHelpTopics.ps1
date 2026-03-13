function  Get-PSHelpTopics {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$FunctionName        
    )

    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $Path,
        [ref]$null,
        [ref]$null
    )

    $functions = $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)

    foreach ($func in $functions) {

        if ($func.Name -eq $FunctionName) {

            $help = $func.GetHelpContent()

            if (-not $help) {
                $HelpTopics = 0
            }
            else {
                $topics = $help.PSObject.Properties |
                Where-Object {
                    $_.Value -and
                    $_.Value.ToString().Trim() -ne ''
                } | Select-Object -ExpandProperty Name
                $HelpTopics = $topics.Count
            }
        }
    }
    return $HelpTopics
}



function Get-FunctionHelpLines_old {

    param(
        [Parameter(Mandatory)]
        $FunctionAst,

        [Parameter(Mandatory)]
        $Tokens
    )

    $functionStart = $FunctionAst.Extent.StartLineNumber

    $helpTokens = $Tokens | Where-Object {
        $_.Kind -eq 'Comment' -and
        $_.Extent.EndLineNumber -lt $functionStart -and
        $_.Text -match '<#'
    }

    if (-not $helpTokens) {
        return 0
    }

    $helpText = $helpTokens[-1].Text

    ($helpText -split "\r?\n").Count
}