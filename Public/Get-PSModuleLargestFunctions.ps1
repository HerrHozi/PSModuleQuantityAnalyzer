<#
.SYNOPSIS
Returns the largest functions in a PowerShell module by line count.

.DESCRIPTION
Get-PSModuleLargestFunctions analyzes the specified module and returns the top
N functions sorted by TotalLines in descending order.

This helps identify large functions that may require review, decomposition, or
refactoring.

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath).

.PARAMETER Top
Specifies how many functions to return.
Default value: 10.

.EXAMPLE
Get-PSModuleLargestFunctions -ModuleName PSModuleQuantityAnalyzer

Returns the 10 largest functions in PSModuleQuantityAnalyzer.

.EXAMPLE
Get-PSModuleLargestFunctions -ModuleName PSModuleQuantityAnalyzer -Top 5

Returns the 5 largest functions in PSModuleQuantityAnalyzer.

.OUTPUTS
PSCustomObject. The output includes Function, TotalLines, LinesOfCode,
LinesOfComment, and PartOfFile.

.NOTES
Results are based on data returned by Get-PSModuleQuantity.
#>
function Get-PSModuleLargestFunctions {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [int]$Top = 10
    )

    $data = Get-PSModuleQuantity -ModuleName $ModuleName

    $data |
    Sort-Object TotalLines -Descending |
    Select-Object -First $Top `
        Function,
    TotalLines,
    LinesOfCode,
    LinesOfComment,
    PartOfFile
}