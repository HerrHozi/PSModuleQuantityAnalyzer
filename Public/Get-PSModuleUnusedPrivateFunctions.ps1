<#
.SYNOPSIS
Returns private functions in a module that are not referenced.

.DESCRIPTION
Get-PSModuleUnusedPrivateFunctions analyzes the specified module and identifies
functions located in the Private folder that have a reference count of zero.

The output is sorted by function size in descending order to help prioritize
cleanup of larger unused functions first.

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath).

.EXAMPLE
Get-PSModuleUnusedPrivateFunctions -ModuleName PSModuleQuantityAnalyzer

Returns all unused private functions in PSModuleQuantityAnalyzer.

.OUTPUTS
PSCustomObject. The output includes ModuleName, Version, Function, TotalLines,
References, PartOfFile, and FullName.

.NOTES
Reference counts are based on results from Get-PSModuleQuantity.
#>
function Get-PSModuleUnusedPrivateFunctions {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $data = Get-PSModuleQuantity -ModuleName $ModuleName

    $data |
    Where-Object {

        $_.FullName -match '\\Private\\' -and
        $_.References -eq 0

    } |
    Sort-Object TotalLines -Descending |
    Select-Object `
        ModuleName,
    Version,
    Function,
    TotalLines,
    References,
    PartOfFile,
    FullName
}