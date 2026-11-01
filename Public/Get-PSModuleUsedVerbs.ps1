<#
.SYNOPSIS
Returns the verbs used by functions in a PowerShell module.

.DESCRIPTION
Get-PSModuleUsedVerbs analyzes the latest available version of the
specified module and extracts the verb portion of each discovered
PowerShell function name.

Function names are split at the first hyphen and then grouped by verb.
The output includes the verb, the number of occurrences, whether the verb is
supported (approved by Get-Verb), and the list of functions that use that verb.

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath).

.EXAMPLE
Get-PSModuleUsedVerbs -ModuleName PSModuleQuantityAnalyzer
Returns the verbs used by functions in PSModuleQuantityAnalyzer.

Get-PSModuleUsedVerbs -ModuleName PSModuleQuantityAnalyzer | Select-object Verb, Count, Approved | Sort-Object Verb
Returns the used verbs and their counts, sorted alphabetically by verb.

Get-PSModuleUsedVerbs -ModuleName PSModuleQuantityAnalyzer | Where-Object { -not $_.Supported }
Returns the verbs that are not approved PowerShell verbs.

.OUTPUTS
PSCustomObject. Each output object includes Verb, Count, Supported, Functions,
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

    $approvedVerbs = @{}
    foreach ($approved in (Get-Verb).Verb) { $approvedVerbs[$approved] = $true }

    $functions |
    Where-Object { $_.Name -like '*-*' } |
    Group-Object { ($_.Name -split '-', 2)[0] } |
    Sort-Object Count -Descending |
    ForEach-Object {
        [PSCustomObject]@{
            Verb           = $_.Name
            Count          = $_.Count
            Approved       = $approvedVerbs.ContainsKey($_.Name)
            Functions      = $_.Group.Name
            CollectionDate = $collectionDate
            ModuleName     = $module.Name
            Version        = $module.Version
        }
    }
}