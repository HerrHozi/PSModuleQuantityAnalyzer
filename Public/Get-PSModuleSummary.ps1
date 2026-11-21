<#
.SYNOPSIS
Returns a high-level summary of a PowerShell module.

.DESCRIPTION
Get-PSModuleSummary analyzes the specified module and returns a compact
summary containing module identity, number of public and private functions, and
number of source files in Public and Private folders.

The function resolves the latest available module version, validates that the
module exists, and then calculates counts based on module file structure and
quantity report data.

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath).

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
Each call appends the result as one row to
$env:LOCALAPPDATA\Get-PSModuleSummary.csv.
This function uses Get-PSModuleQuantity to calculate function counts.
DoubleFunctionPairs counts distinct function names defined more than once,
using the same grouping as Get-PSModuleDuplicateFunctions.
#>
function Get-PSModuleSummary {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $module = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1

    if (-not $module) {
        throw "Module '$ModuleName' was not found."
    }

    $modulePath = $module.ModuleBase

    $publicPath = Join-Path $modulePath "Public"
    $privatePath = Join-Path $modulePath "Private"

    $publicFiles = if (Test-Path $publicPath) {
        Get-ChildItem $publicPath -Filter *.ps1
    }
    else { 
        @() 
    }

    $privateFiles = if (Test-Path $privatePath) {
        Get-ChildItem $privatePath -Filter *.ps1
    }
    else { 
        @() 
    }

    $quantityData = Get-PSModuleQuantity -ModuleName $ModuleName

    $doubleFunctionPairs = @($quantityData |
        Group-Object -Property Function |
        Where-Object { $_.Count -gt 1 }).Count

    $publicFunctions = ($quantityData |
        Where-Object { $_.FullName -match "Public" }).Count

    $privateFunctions = ($quantityData |
        Where-Object { $_.FullName -match "Private" }).Count

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

    # Step 1: export the result to %LOCALAPPDATA%\Get-PSModuleSummary.csv
    try {
        $csvPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Get-PSModuleSummary.csv'
        $result | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 -Append -ErrorAction Stop
        Write-Verbose "Summary exported to $csvPath"
    }
    catch {
        Write-Warning "Unable to export summary to CSV: $_"
    }

    $result
}