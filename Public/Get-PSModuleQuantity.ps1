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

Get-PSModuleQuantity -ModuleName .\SSAwBH.psd1 | Group-Object NestedModule
Groups the functions by nested module ('(main)' for the module itself).

.OUTPUTS
PSCustomObject. Each output object includes CollectionDate, ModuleName,
Version, Function, NestedModule, Type, TotalLines, LinesOfCode, LinesOfComment, References,
PartOfFile, RelativePath (path below the module root, including subfolders), FullName, CreationDate, ModificationDate, and FileSize.

.NOTES
This function uses internal helper functions to discover source files, parse
AST data, build a reference map, and measure function line metrics.
References count calls with a fixed command name and function names written as quoted
text (for example & 'Get-Something' or -FunctionName 'Get-Something'), in .ps1 and .psm1
files. Calls through variables are not detected.
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

    # Functions come from the .ps1 files. Calls are also counted in .psm1 files (the module
    # loader often uses helper functions), so those are parsed for the reference map only.
    $allFiles = @(Get-PSModuleSourceFiles -Module $module -IncludePsm1)
    $fullCache = Get-PSModuleAstCache -Files $allFiles
    $astCache = @{}
    foreach ($key in $fullCache.Keys) {
        if ($key -like '*.ps1') { $astCache[$key] = $fullCache[$key] }
    }
    $referenceMap = Get-PSModuleReferenceMap -AstCache $fullCache
    $functions = Get-PSFunctionDefinitions -AstCache $astCache
    $nestedRoots = @(Get-PSModuleNestedRoots -Module $module | Sort-Object { $_.Root.Length } -Descending)
    $moduleBase = [System.IO.Path]::GetFullPath($module.ModuleBase).TrimEnd('\', '/') + '\'

    foreach ($func in $functions) {

        # Path below the module root; used for the Public/Private decision, so folders above
        # the module and subfolders such as Private\ASP07 are handled correctly.
        $relativePath = if ($func.File.StartsWith($moduleBase, [System.StringComparison]::OrdinalIgnoreCase)) {
            $func.File.Substring($moduleBase.Length)
        }
        else {
            $func.File
        }

        $lineInfo = Measure-PSFunctionLines -FunctionAst $func

        $nested = $nestedRoots | Where-Object { $func.File.StartsWith($_.Root, [System.StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1

        $references = if ($referenceMap.ContainsKey($func.Name)) {
            $referenceMap[$func.Name]
        }
        else {
            0
        }

        $helpTopics = Get-PSHelpTopics -Path $func.File -FunctionName $func.Name

        [PSCustomObject]@{
            Function         = $func.Name
            NestedModule     = if ($nested) { $nested.Name } else { '(main)' }
            Type             = if ((Get-PSModuleFileScope -RelativePath $relativePath) -eq 'Public') { 'Public' } else { 'Private' }
            HelpTopics       = $helpTopics
            TotalLines       = $lineInfo.TotalLines
            LinesOfHelp      = $helpTopics
            LinesOfCode      = $lineInfo.LinesOfCode
            LinesOfComment   = $lineInfo.LinesOfComment
            References       = [int]$references
            PartOfFile       = $($func.File).Split('\')[-1]
            RelativePath     = $relativePath
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