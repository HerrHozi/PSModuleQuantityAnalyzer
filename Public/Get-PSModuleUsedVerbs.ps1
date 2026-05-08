<#
.SYNOPSIS
Returns the verbs used by functions in a PowerShell module.

.DESCRIPTION
Get-PSModuleUsedVerbs analyzes the latest available version of the
specified module and extracts the verb portion of each discovered
PowerShell function name.

Function names are split at the first hyphen and then grouped by verb.
The output includes the verb, the number of occurrences, and the list
of functions that use that verb.

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath).

.EXAMPLE
Get-PSModuleUsedVerbs -ModuleName PSModuleQuantityAnalyzer
Returns the verbs used by functions in PSModuleQuantityAnalyzer.

Get-PSModuleUsedVerbs -ModuleName PSModuleQuantityAnalyzer | Select-Object Verb, Count | Sort-Object Verb
Returns the used verbs and their counts, sorted alphabetically by verb.

.OUTPUTS
PSCustomObject. Each output object includes Verb, Count, Functions,
CollectionDate, ModuleName, and Version.

.NOTES
This function uses internal helper functions to discover source files,
parse AST data, and extract function definitions.
#>
function Get-PSModuleUsedVerbs {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $collectionDate = Get-Date

    $module = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1

    if (-not $module) {
        throw "Module '$ModuleName' was not found."
    }

    $files = Get-PSModuleSourceFiles -Module $module
    $astCache = Get-PSModuleAstCache -Files $files
    $functions = Get-PSFunctionDefinitions -AstCache $astCache

    $functions |
    Where-Object { $_.Name -like '*-*' } |
    Group-Object { ($_.Name -split '-', 2)[0] } |
    Sort-Object Count -Descending |
    ForEach-Object {
        [PSCustomObject]@{
            Verb           = $_.Name
            Count          = $_.Count
            Functions      = $_.Group.Name
            CollectionDate = $collectionDate
            ModuleName     = $module.Name
            Version        = $module.Version
        }
    }
}