<#
.SYNOPSIS
Calculates documentation coverage for functions in a PowerShell module.

.DESCRIPTION
Get-PSModuleDocumentationCoverage analyzes all function definitions in the
specified module and determines how many functions provide comment-based help.

The function uses the function inventory of Get-PSModuleQuantity (parsed with the
PowerShell AST), counts the functions that have comment-based help, and returns a
coverage percentage.

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath).

.EXAMPLE
Get-PSModuleDocumentationCoverage -ModuleName PSModuleQuantityAnalyzer

Returns documentation coverage statistics for PSModuleQuantityAnalyzer.

.OUTPUTS
PSCustomObject. The output includes ModuleName, Version, Functions,
FunctionsWithHelp, FunctionsWithoutHelp, and DocumentationCoveragePercent.

.NOTES
Coverage is rounded to two decimal places.
#>
function Get-PSModuleDocumentationCoverage {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $quantity = @(Get-PSModuleQuantity -ModuleName $ModuleName)

    # HelpTopics = number of filled comment-based-help sections of a function.
    # A function with at least one filled section counts as documented.
    $totalFunctions = $quantity.Count
    $functionsWithHelp = @($quantity | Where-Object { $_.HelpTopics -gt 0 }).Count
    $coverage = if ($totalFunctions -gt 0) {
        [math]::Round(($functionsWithHelp / $totalFunctions) * 100,2)
    } else {
        0
    }

    [PSCustomObject]@{

        ModuleName = $quantity[0].ModuleName
        Version    = $quantity[0].Version

        Functions               = $totalFunctions
        FunctionsWithHelp       = $functionsWithHelp
        FunctionsWithoutHelp    = $totalFunctions - $functionsWithHelp

        DocumentationCoveragePercent = $coverage
    }

}