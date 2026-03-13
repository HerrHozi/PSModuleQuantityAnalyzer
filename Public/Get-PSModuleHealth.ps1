<#
.SYNOPSIS
Returns a health summary for a PowerShell module.

.DESCRIPTION
Get-PSModuleHealth evaluates basic maintainability indicators for the specified
module, including oversized functions, unused functions, missing help content,
and the most-referenced functions.

The function uses quantity report data and AST-based help detection to build a
single health summary object.

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath).

.PARAMETER LargeFunctionThreshold
Specifies the line-count threshold used to classify a function as large.
Functions with TotalLines greater than this value are counted as large functions.

.EXAMPLE
Get-PSModuleHealth -ModuleName PSModuleQuantityAnalyzer

Returns a module health summary for PSModuleQuantityAnalyzer.

.OUTPUTS
PSCustomObject. The output includes ModuleName, Version, TotalFunctions,
LargeFunctionThreshold, FunctionsOverLargeFunctionThreshold,
UnusedFunctions, FunctionsWithoutHelp, and
TopReferencedFunctions.

.NOTES
LargeFunctionThreshold defaults to 100 total lines.
#>
function Get-PSModuleHealth {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [ValidateRange(1, [int]::MaxValue)]
        [int]$LargeFunctionThreshold = 100
    )

    $data = Get-PSModuleQuantity -ModuleName $ModuleName

    if (-not $data) {
        throw "No data found for module '$ModuleName'"
    }

    $largeFunctions = $data | Where-Object { $_.TotalLines -gt $LargeFunctionThreshold }

    $unusedFunctions = $data | Where-Object { $_.References -eq 0 }

    $missingHelp = @()

    foreach ($item in $data) {

        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $item.FullName,
            [ref]$null,
            [ref]$null
        )

        $functions = $ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true)

        foreach ($func in $functions) {

            if ($func.Name -eq $item.Function) {

                $help = $func.GetHelpContent()

                if (-not $help) {
                    $missingHelp += $item
                }

            }
        }
    }

    $mostReferenced = $data | Sort-Object References -Descending | Select-Object -First 5

    [PSCustomObject]@{

        ModuleName                          = $data[0].ModuleName
        Version                             = $data[0].Version

        TotalFunctions                      = $data.Count

        LargeFunctionThreshold              = $LargeFunctionThreshold
        FunctionsOverLargeFunctionThreshold = $largeFunctions.Count
        UnusedFunctions                     = $unusedFunctions.Count
        FunctionsWithoutHelp                = $missingHelp.Count

        TopReferencedFunctions              = ($mostReferenced.Function -join ", ")
    }
}