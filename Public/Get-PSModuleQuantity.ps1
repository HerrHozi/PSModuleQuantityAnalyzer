<#
.SYNOPSIS
Generates a detailed quantity analysis report for a PowerShell module.

.DESCRIPTION
Get-PSModuleQuantity analyzes the latest available version of the
specified module and returns function-level metrics for all discovered
PowerShell source files.

For each function, the report includes line counts, reference count, source
file details, and file metadata such as creation date, last modification date,
and file size.

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath).

.EXAMPLE
Get-PSModuleQuantity -ModuleName PSModuleQuantityAnalyzer
Returns function-level quantity metrics for PSModuleQuantityAnalyzer.

Get-PSModuleQuantity .\PSModuleQuantityAnalyzer.psd1  | Select-Object Version, Function, HelpTopics, TotalLines,LinesOfCode, LinesOfComment,References,PartOfFile,ModificationDate | ft
Returns dedicated metrics for PSModuleQuantityAnalyzer.

.OUTPUTS
PSCustomObject. Each output object includes CollectionDate, ModuleName,
Version, Function, TotalLines, LinesOfCode, LinesOfComment, References,
PartOfFile, FullName, CreationDate, ModificationDate, and FileSize.

.NOTES
This function uses internal helper functions to discover source files, parse
AST data, build a reference map, and measure function line metrics.
#>
function Get-PSModuleQuantity {

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
    $referenceMap = Get-PSModuleReferenceMap -AstCache $astCache
    $functions = Get-PSFunctionDefinitions -AstCache $astCache

    foreach ($func in $functions) {

        $lineInfo = Measure-PSFunctionLines -FunctionAst $func

        $references = if ($referenceMap.ContainsKey($func.Name)) {
            $referenceMap[$func.Name]
        }
        else {
            0
        }

        $helpTopics = Get-PSHelpTopics -Path $func.File -FunctionName $func.Name

        [PSCustomObject]@{
            Function         = $func.Name
            Type             = If (($func.File).ToLower().Contains('\public')) { 'Public' } else { 'Private' }
            HelpTopics       = $helpTopics
            TotalLines       = $lineInfo.TotalLines
            LinesOfHelp      = $helpTopics
            LinesOfCode      = $lineInfo.LinesOfCode
            LinesOfComment   = $lineInfo.LinesOfComment
            References       = [int]$references
            PartOfFile       = $($func.File).Split('\')[-1]
            ModificationDate = (Get-Item $func.File).LastWriteTime
            FullName         = $func.File
            CreationDate     = (Get-Item $func.File).CreationTime
            FileSize         = (Get-Item $func.File).Length
            CollectionDate   = $collectionDate
            ModuleName       = $module.Name
            Version          = $module.Version
        }
    }
}