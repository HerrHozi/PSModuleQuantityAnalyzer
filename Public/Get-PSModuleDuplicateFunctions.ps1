<#
.SYNOPSIS
Detects duplicate function names in a PowerShell module.

.DESCRIPTION
Get-PSModuleDuplicateFunctions analyzes function definitions in the specified
module and identifies function names that appear more than once.

For each duplicate occurrence, the function returns file and metric details to
help locate and review conflicting definitions.

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath).

.EXAMPLE
Get-PSModuleDuplicateFunctions -ModuleName PSModuleQuantityAnalyzer

Returns duplicate function definitions found in PSModuleQuantityAnalyzer.

.OUTPUTS
PSCustomObject. The output includes Function, File, FullName, TotalLines,
LinesOfCode, References, and DefinitionID.

.NOTES
DefinitionID reflects how many times a given function name appears in the
module.
#>
function Get-PSModuleDuplicateFunctions {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $functions = Get-PSModuleQuantity -ModuleName $ModuleName

    $duplicates = $functions |
        Group-Object Function |
        Where-Object Count -gt 1

    foreach ($dup in $duplicates) {

        foreach ($item in $dup.Group) {

            [PSCustomObject]@{
                Function     = $item.Function
                File         = $item.PartOfFile
                FullName     = $item.FullName
                TotalLines   = $item.TotalLines
                LinesOfCode  = $item.LinesOfCode
                References   = $item.References
                DefinitionID = $dup.Count
            }

        }

    }
}