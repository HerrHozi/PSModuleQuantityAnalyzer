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
UnusedFunctions (private functions without any reference), FunctionsWithoutHelp, and
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

    $data = @(Get-PSModuleQuantity -ModuleName $ModuleName)

    if (-not $data) {
        throw "No data found for module '$ModuleName'"
    }

    $largeFunctions = @($data | Where-Object { $_.TotalLines -gt $LargeFunctionThreshold })

    # Only private functions can be reported as unused: a public function is meant to be
    # called from outside the module, so it normally has no call inside it.
    $unusedFunctions = @($data | Where-Object {
            (Get-PSModuleFileScope -RelativePath $_.RelativePath) -eq 'Private' -and $_.References -eq 0
        })

    # HelpTopics = number of filled comment-based-help sections; 0 means no help.
    $missingHelp = @($data | Where-Object { $_.HelpTopics -eq 0 })

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