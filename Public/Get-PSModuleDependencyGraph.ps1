<#
.SYNOPSIS
Builds a function-level dependency graph for a PowerShell module.

.DESCRIPTION
Get-PSModuleDependencyGraph parses module source files with PowerShell AST and
returns caller-to-callee relationships between functions defined in the same
module.

For each discovered dependency, the function outputs which function calls which
other function and the file where the caller function is located.

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath).

.EXAMPLE
Get-PSModuleDependencyGraph -ModuleName PSModuleQuantityAnalyzer

Returns function call relationships for PSModuleQuantityAnalyzer.

.OUTPUTS
PSCustomObject. The output includes Function, Calls, and File.

.NOTES
Only calls that match discovered module function names are returned.
#>
function Get-PSModuleDependencyGraph {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $data = Get-PSModuleQuantity -ModuleName $ModuleName
    $files = $data.FullName | Sort-Object -Unique

    $functionNames = $data.Function

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

            $commands = $func.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst]
            }, $true)

            foreach ($cmd in $commands) {

                $name = $cmd.GetCommandName()

                if ($name -and $name -in $functionNames) {

                    [PSCustomObject]@{
                        Function = $func.Name
                        Calls    = $name
                        File     = $file
                    }

                }

            }

        }

    }
}