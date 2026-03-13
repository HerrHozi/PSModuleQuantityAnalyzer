<#
.SYNOPSIS
Returns aggregated quality and size metrics for a PowerShell module.

.DESCRIPTION
Get-PSModuleMetrics combines multiple analysis results into a single summary
object that describes module size, function distribution, complexity,
documentation coverage, and maintainability indicators.

The function builds its output from quantity, complexity, documentation,
duplicate, unused-function, and summary reports.

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath).

.EXAMPLE
Get-PSModuleMetrics -ModuleName PSModuleQuantityAnalyzer

Returns an aggregated metrics object for PSModuleQuantityAnalyzer.

.OUTPUTS
PSCustomObject. The output includes module identity, file/function counts,
line metrics, complexity statistics, documentation coverage, duplicate and
unused function counts, and largest function details.

.NOTES
ComplexFunctions is calculated using a fixed complexity threshold greater than
10. CommentRatioPercent and average values are rounded for readability.
#>
function Get-PSModuleMetrics {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $quantity = Get-PSModuleQuantity -ModuleName $ModuleName
    $complexity = Get-PSModuleComplexity -ModuleName $ModuleName
    $docs = Get-PSModuleDocumentationCoverage -ModuleName $ModuleName
    $duplicates = Get-PSModuleDuplicateFunctions -ModuleName $ModuleName
    $unused = Get-PSModuleUnusedPrivateFunctions -ModuleName $ModuleName

    $summary = Get-PSModuleSummary -ModuleName $ModuleName

    $largest = $quantity | Sort-Object TotalLines -Descending | Select-Object -First 1

    $totalLines = ($quantity.TotalLines | Measure-Object -Sum).Sum
    $totalCode = ($quantity.LinesOfCode | Measure-Object -Sum).Sum
    $comments = ($quantity.LinesOfComment | Measure-Object -Sum).Sum

    $avgFunctionLines = if ($quantity.Count -gt 0) {
        $totalLines / $quantity.Count
    }
    else {
        0
    }

    $complexValues = $complexity.Complexity

    $avgComplexity = if ($complexValues.Count -gt 0) {
        ($complexValues | Measure-Object -Average).Average
    }
    else {
        0
    }

    $maxComplexity = if ($complexValues.Count -gt 0) {
        ($complexValues | Measure-Object -Maximum).Maximum
    }
    else {
        0
    }

    $complexFunctions = ($complexValues | Where-Object { $_ -gt 10 }).Count

    $commentRatio = if ($totalLines -gt 0) {
        [math]::Round(($comments / $totalLines) * 100, 2)
    }
    else {
        0
    }

    [PSCustomObject]@{

        ModuleName                   = $summary.ModuleName
        Version                      = $summary.Version

        Files                        = $summary.TotalFiles
        Functions                    = $summary.TotalFunctions
        PublicFunctions              = $summary.PublicFunctions
        PrivateFunctions             = $summary.PrivateFunctions

        TotalLines                   = $totalLines
        LinesOfCode                  = $totalCode
        LinesOfComment               = $comments
        CommentRatioPercent          = $commentRatio

        AverageFunctionLines         = [math]::Round($avgFunctionLines, 2)

        AverageComplexity            = [math]::Round($avgComplexity, 2)
        MaxComplexity                = $maxComplexity
        ComplexFunctions             = $complexFunctions

        DocumentationCoveragePercent = $docs.DocumentationCoveragePercent

        UnusedPrivateFunctions       = ($unused | Measure-Object).Count
        DuplicateFunctions           = ($duplicates | Measure-Object).Count

        LargestFunction              = $largest.Function
        LargestFunctionLines         = $largest.TotalLines
        LargestFunctionFile          = $largest.PartOfFile
    }
}