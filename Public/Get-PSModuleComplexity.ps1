<#
.SYNOPSIS
Calculates function-level cyclomatic complexity for a PowerShell module.

.DESCRIPTION
Get-PSModuleComplexity parses module source files with PowerShell AST and
computes a cyclomatic complexity score for each function.

Each function starts with a base complexity of 1. The score is increased by one
for every decision point:

- every branch of an if / elseif chain
- for, foreach, while, do/while and do/until loops
- every case of a switch statement
- catch clauses and trap statements
- the logical operators -and, -or and -xor
- the ternary operator (PowerShell 7) and the pipeline chain operators && and ||

Decision points inside a nested function count for the nested function only, not
for the function that contains it.

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
execution paths. A value above 10 is treated as complex by the reports.
#>
function Get-PSModuleComplexity {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $data = Get-PSModuleQuantity -ModuleName $ModuleName
    $files = @($data.FullName | Sort-Object -Unique)

    # Type names are compared as text because some of them (for example the ternary
    # operator) do not exist in Windows PowerShell 5.1.
    $decisionTypes = @(
        'IfStatementAst', 'ForStatementAst', 'ForEachStatementAst', 'WhileStatementAst',
        'DoWhileStatementAst', 'DoUntilStatementAst', 'SwitchStatementAst', 'CatchClauseAst',
        'TrapStatementAst', 'TernaryExpressionAst', 'PipelineChainAst', 'BinaryExpressionAst'
    )
    $logicalOperators = @('And', 'Or', 'Xor')

    $astCache = Get-PSModuleAstCache -Files @($files | ForEach-Object { Get-Item -LiteralPath $_ })

    foreach ($file in $files) {

        $ast = $astCache[$file]

        $functions = $ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true)

        foreach ($func in $functions) {

            $complexity = 1

            $candidates = $func.FindAll({
                    param($node)
                    $node.GetType().Name -in $decisionTypes
                }, $true)

            foreach ($node in $candidates) {

                # Count only nodes that belong directly to this function, not to a function
                # that is defined inside it.
                $owner = $node.Parent
                while ($owner -and $owner -isnot [System.Management.Automation.Language.FunctionDefinitionAst]) {
                    $owner = $owner.Parent
                }
                if (-not [object]::ReferenceEquals($owner, $func)) { continue }

                switch ($node.GetType().Name) {
                    'IfStatementAst' { $complexity += $node.Clauses.Count }      # if + every elseif
                    'SwitchStatementAst' { $complexity += $node.Clauses.Count }  # every case
                    'BinaryExpressionAst' {
                        if ($node.Operator.ToString() -in $logicalOperators) { $complexity++ }
                    }
                    default { $complexity++ }
                }
            }

            [PSCustomObject]@{
                Function   = $func.Name
                Complexity = $complexity
                File       = $file
            }

        }

    }
}
