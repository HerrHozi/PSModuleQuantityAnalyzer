<#
.SYNOPSIS
Calculates function-level cyclomatic complexity for a PowerShell module.

.DESCRIPTION
Get-PSModuleComplexity parses module source files with PowerShell AST and
computes a simple cyclomatic complexity score for each function.

Each function starts with a base complexity of 1. The score is increased by one
for each detected control-flow decision node, such as if, for, foreach, while,
do/while, switch, and catch.

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath).

.EXAMPLE
Get-PSModuleComplexity -ModuleName PSModuleQuantityAnalyzer

Returns complexity scores for each function in PSModuleQuantityAnalyzer.

.OUTPUTS
PSCustomObject. The output includes Function, Complexity, and File.

.NOTES
Complexity is calculated from static AST analysis and does not include runtime
execution paths.
#>
function Get-PSModuleComplexity {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $data = Get-PSModuleQuantity -ModuleName $ModuleName
    $files = $data.FullName | Sort-Object -Unique

    foreach ($file in $files) {

        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $file,
            [ref]$null,
            [ref]$null
        )

        $functions = $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)

        foreach ($func in $functions) {

            $complexity = 1

            $decisionNodes = $func.FindAll({

                param($node)

                $node -is [System.Management.Automation.Language.IfStatementAst] -or
                $node -is [System.Management.Automation.Language.ForStatementAst] -or
                $node -is [System.Management.Automation.Language.ForEachStatementAst] -or
                $node -is [System.Management.Automation.Language.WhileStatementAst] -or
                $node -is [System.Management.Automation.Language.DoWhileStatementAst] -or
                $node -is [System.Management.Automation.Language.SwitchStatementAst] -or
                $node -is [System.Management.Automation.Language.CatchClauseAst]

            }, $true)

            $complexity += $decisionNodes.Count

            [PSCustomObject]@{
                Function   = $func.Name
                Complexity = $complexity
                File       = $file
            }

        }

    }
}