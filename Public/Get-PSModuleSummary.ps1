<#
.SYNOPSIS
Returns a high-level summary of a PowerShell module.

.DESCRIPTION
Get-PSModuleSummary analyzes the specified module and returns a compact
summary containing module identity, number of public and private functions, and
number of source files in the module tree. Subfolders such as Private\ASP07 are
included. A file or function is public when a folder named Public is part of its
path below the module root; everything else counts as private.

The function resolves the latest available module version, validates that the
module exists, and then calculates counts based on module file structure and
quantity report data.

The result is also appended to the CSV file
$env:LOCALAPPDATA\Get-PSModuleSummary.csv, so repeated analyses can be evaluated
and compared later.

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath).

.PARAMETER NoHistory
Returns the summary without appending it to the CSV history
$env:LOCALAPPDATA\Get-PSModuleSummary.csv. Used by commands that call this function
internally (Get-PSModuleMetrics, Export-PSModuleMarkdownReport), so that only a
deliberate call creates a history row.

.PARAMETER ShowHistory
Opens the CSV history $env:LOCALAPPDATA\Get-PSModuleSummary.csv in an
Out-GridView window instead of analyzing a module. Cannot be combined with
-ModuleName. Requires Out-GridView (Windows with a graphical session).

.EXAMPLE
Get-PSModuleSummary -ShowHistory

Shows all previously recorded summaries in a grid view window.

.EXAMPLE
Get-PSModuleSummary -ModuleName PSModuleQuantityAnalyzer

Returns a summary object for the latest available version of
PSModuleQuantityAnalyzer.

.OUTPUTS
PSCustomObject. The output contains module and count summary properties:
DateOfAnalysis (yyyy-MM-dd HH:mm:ss.fff), ModuleName, Version, LastUpdate, NestedModules, ModulePath, PublicFunctions,
PrivateFunctions, TotalFunctions, DoubleFunctionPairs, Verbs, PublicFiles, PrivateFiles, TotalFiles,
and TotalLines.
Additionally HtmlFiles, MarkdownFiles and GraphicFiles (counts of .html/.htm,
.md/.markdown and image files such as jpg, png, gif, bmp, svg, ico, webp, tif).

.NOTES
Besides returning the object, each call appends the result as one row to
$env:LOCALAPPDATA\Get-PSModuleSummary.csv (UTF-8, comma separated, DateOfAnalysis
as first column). The file builds up a history of analyses that can be used later for
evaluation, for example with Import-Csv, Excel or Power BI. If the file cannot be
written, a warning is shown and the summary object is still returned.
This function uses Get-PSModuleQuantity to calculate function counts.
DoubleFunctionPairs counts distinct function names defined more than once,
using the same grouping as Get-PSModuleDuplicateFunctions.
#>
function Get-PSModuleSummary {

    [CmdletBinding(DefaultParameterSetName = 'Analyze')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Analyze')]
        [string]$ModuleName,

        [Parameter(ParameterSetName = 'Analyze')]
        [switch]$NoHistory,

        [Parameter(Mandatory, ParameterSetName = 'History')]
        [switch]$ShowHistory
    )

    $csvPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Get-PSModuleSummary.csv'

    if ($ShowHistory) {
        if (-not (Test-Path -LiteralPath $csvPath -PathType Leaf)) {
            Write-Warning "No history found yet: $csvPath. Run Get-PSModuleSummary -ModuleName <module> first."
            return
        }
        Import-Csv -LiteralPath $csvPath | Out-GridView -Title "Get-PSModuleSummary history ($csvPath)"
        return
    }

    $module = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1

    if (-not $module) {
        throw "Module '$ModuleName' was not found."
    }

    $modulePath = $module.ModuleBase

    # Source files in the whole module tree, including subfolders such as Private\ASP07.
    # A file counts as public when a folder named Public is part of its path below the
    # module root, every other source file counts as private.
    $moduleBase = [System.IO.Path]::GetFullPath($modulePath).TrimEnd('\', '/') + '\'
    $sourceFiles = @(Get-PSModuleSourceFiles -Module $module)

    $publicFiles = @($sourceFiles | Where-Object {
            (Get-PSModuleFileScope -RelativePath $_.FullName.Substring($moduleBase.Length)) -eq 'Public'
        })
    $privateFiles = @($sourceFiles | Where-Object {
            (Get-PSModuleFileScope -RelativePath $_.FullName.Substring($moduleBase.Length)) -ne 'Public'
        })

    $quantityData = Get-PSModuleQuantity -ModuleName $ModuleName

    $doubleFunctionPairs = @($quantityData |
        Group-Object -Property Function |
        Where-Object { $_.Count -gt 1 }).Count

    $publicFunctions = @($quantityData | Where-Object { $_.Type -eq 'Public' }).Count
    $privateFunctions = @($quantityData | Where-Object { $_.Type -eq 'Private' }).Count

    $allPSFiles = Get-ChildItem -Path (Join-Path $modulePath '*') -Recurse -File |
    Where-Object { $_.Extension -in @('.ps1', '.psm1', '.psd1') }


    # Documentation / asset files (HTML, Markdown, graphics)
    $graphicExtensions = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.ico', '.webp', '.tif', '.tiff')

    $allFiles = Get-ChildItem -Path $modulePath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }

    $htmlFiles = @($allFiles | Where-Object { $_.Extension -in @('.html', '.htm') })
    $markdownFiles = @($allFiles | Where-Object { $_.Extension -in @('.md', '.markdown') })
    $graphicFiles = @($allFiles | Where-Object { $_.Extension -in $graphicExtensions })

    $maxDate = ($allPSFiles | Measure-Object -Maximum LastWriteTime).Maximum
    $lastUpdate = if ($maxDate) { $maxDate.ToString('yyyy-MM-dd HH:mm:ss') } else { "unknown" }

    $nestedModuleCount = @(Get-PSModuleNestedRoots -Module $module).Count
    $verbCount = @(Get-PSModuleUsedVerbs -ModuleName $ModuleName).Count


    $result = [PSCustomObject]@{

        DateOfAnalysis   = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
        ModuleName       = $module.Name
        Version          = $module.Version
        LastUpdate       = $lastUpdate
        NestedModules    = $nestedModuleCount

        PublicFunctions  = $publicFunctions
        PrivateFunctions = $privateFunctions
        TotalFunctions   = $publicFunctions + $privateFunctions
        DoubleFunctionPairs = $doubleFunctionPairs
        Verbs            = $verbCount

        PublicFiles      = $publicFiles.Count
        PrivateFiles     = $privateFiles.Count
        TotalFiles       = $publicFiles.Count + $privateFiles.Count
        TotalLines       = ($quantityData | Measure-Object -Property TotalLines -Sum).Sum

        HtmlFiles        = $htmlFiles.Count
        MarkdownFiles    = $markdownFiles.Count
        GraphicFiles     = $graphicFiles.Count
        ModulePath       = $modulePath
    }

    # Append the result to %LOCALAPPDATA%\Get-PSModuleSummary.csv (history for later evaluation).
    # Commands that call this function internally pass -NoHistory, so only a deliberate call
    # creates a history row.
    if (-not $NoHistory) { try {
        $csvParams = @{
            Path        = $csvPath
            Encoding    = 'UTF8'
            Append      = $true
            ErrorAction = 'Stop'
        }
        # PowerShell 7+ never writes type information (the switch is obsolete there);
        # Windows PowerShell 5.1 needs it to suppress the '#TYPE' header line.
        if ($PSVersionTable.PSVersion.Major -lt 6) { $csvParams.NoTypeInformation = $true }
        $result | Export-Csv @csvParams
        Write-Verbose "Summary exported to $csvPath"
    }
    catch {
        Write-Warning "Unable to export summary to CSV: $_"
    } }

    $result
}