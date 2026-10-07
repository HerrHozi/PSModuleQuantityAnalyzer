<#
.SYNOPSIS
Finds function calls that cross the boundary between a module and its nested modules.

.DESCRIPTION
Get-PSModuleNestedDependencies parses module source files with PowerShell AST and
returns every call from a function in one (nested) module to a function that is
defined in a different (nested) module of the same module.

The result shows how tightly the main module and its nested modules are coupled
and helps to decide whether a nested module could be extracted or published
separately.

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath)
or the path to the module manifest.

.EXAMPLE
Get-PSModuleNestedDependencies -ModuleName .\SSAwBH.psd1 | Group-Object FromModule, ToModule

Counts the calls between the main module and each nested module.

.OUTPUTS
PSCustomObject. The output includes Function, FromModule, Calls, ToModule, and File.

.NOTES
Only calls that match function names defined in the module sources are returned.
If a function name exists in several nested modules, the first match is used.
#>
function Get-PSModuleNestedDependencies {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $data = Get-PSModuleQuantity -ModuleName $ModuleName

    $moduleOfFunction = @{}
    $moduleOfFile = @{}

    foreach ($item in $data) {
        if (-not $moduleOfFunction.ContainsKey($item.Function)) {
            $moduleOfFunction[$item.Function] = $item.NestedModule
        }
        $moduleOfFile[$item.FullName] = $item.NestedModule
    }

    foreach ($file in $moduleOfFile.Keys | Sort-Object) {

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

                if ($name -and $moduleOfFunction.ContainsKey($name) -and $moduleOfFunction[$name] -ne $moduleOfFile[$file]) {

                    [PSCustomObject]@{
                        Function   = $func.Name
                        FromModule = $moduleOfFile[$file]
                        Calls      = $name
                        ToModule   = $moduleOfFunction[$name]
                        File       = $file
                    }

                }

            }

        }

    }
}
