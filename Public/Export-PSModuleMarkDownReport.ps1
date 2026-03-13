<#
.SYNOPSIS
Exports a comprehensive Markdown analysis report for a PowerShell module.

.DESCRIPTION
Export-PSModuleMarkdownReport collects summary, metrics, complexity, dependency,
and maintainability data for the specified module and writes the results to a
Markdown file.

The report includes:
- module information and core metrics
- full function inventory
- largest functions
- unused private functions
- refactoring candidates
- Mermaid charts for size distribution, complexity ranking, and dependencies

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath).

.PARAMETER Path
Specifies the output path of the Markdown report.
If omitted, the function creates a file name in the current directory using the
pattern ModuleAnalysis_<ModuleName>_<Version>.md.

.EXAMPLE
Export-PSModuleMarkdownReport -ModuleName PSModuleQuantityAnalyzer

Generates a Markdown report for PSModuleQuantityAnalyzer and writes it to the
default output file in the current directory.

.EXAMPLE
Export-PSModuleMarkdownReport -ModuleName PSModuleQuantityAnalyzer -Path .\reports\qa.md

Generates a Markdown report and saves it to a custom file path.

.OUTPUTS
None. This function writes a Markdown file to disk.

.NOTES
Use -Verbose to display the final export path.
#>
function Export-PSModuleMarkdownReport {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [string]$Path
    )

    $summary = Get-PSModuleSummary -ModuleName $ModuleName
    $metrics = Get-PSModuleMetrics -ModuleName $ModuleName
    $largest = Get-PSModuleLargestFunctions -ModuleName $ModuleName -Top 5
    $unused = Get-PSModuleUnusedPrivateFunctions -ModuleName $ModuleName
    $refactor = Get-PSModuleRefactoringCandidates -ModuleName $ModuleName

    $quantity = Get-PSModuleQuantity -ModuleName $ModuleName |
    Select-Object Function, HelpTopics, TotalLines, LinesOfCode, LinesOfComment, References, PartOfFile |
    Sort-Object Function

    if (-not $Path) {
        $Path = ".\ModuleAnalysis_{0}_{1}.md" -f $summary.ModuleName, $summary.Version
    }

    $collectionDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

    $md = @()

    $md += "# PowerShell Module Quantity Analysis"
    $md += ([string][char]96 + ("Date of Analysis: $collectionDate") + [string][char]96)
    $md += "## Module Information"
    $md += "| Property | Value |"
    $md += "|---|---|"
    $md += "| Module | $($summary.ModuleName) |"
    $md += "| Version | $($summary.Version) |"
        $md += "| Last Update | $($summary.LastUpdate) |"
    $md += "| Path | $($summary.ModulePath) |"
    $md += ""

    $md += "## Module Metrics"
    $md += "| Metric | Value |"
    $md += "|---|---|"
    $md += "| Total Functions | $($metrics.Functions) |"
    $md += "| Public Functions | $($metrics.PublicFunctions) |"
    $md += "| Private Functions | $($metrics.PrivateFunctions) |"
    $md += "| Total Lines | $($metrics.TotalLines) |"
    $md += "| Lines of Code | $($metrics.LinesOfCode) |"
    $md += "| Comment Lines | $($metrics.LinesOfComment) |"
    $md += "| Comment Ratio | $($metrics.CommentRatioPercent) % |"
    $md += "| Average Function Size | $([math]::Round($metrics.AverageFunctionLines,2)) |"
    $md += "| Largest Function | $($metrics.LargestFunction) |"
    $md += "| Largest Function Lines | $($metrics.LargestFunctionLines) |"
    $md += "| Largest Function File | $($metrics.LargestFunctionFile) |"

    $md += ""
    $md += "## Function Inventory"
    $md += ""
    $md += "| Function | Help Topics | Total Lines | Code | Comments | References | File |"
    $md += "|---|---|---|---|---|---|---|"

    foreach ($f in $quantity) {
        $md += "| $($f.Function) | $($f.HelpTopics) | $($f.TotalLines) | $($f.LinesOfCode) | $($f.LinesOfComment) | $($f.References) | $($f.PartOfFile) |"
    }

    $md += ""
    $md += "## Largest Functions"
    $md += "| Function | Lines | File |"
    $md += "|---|---|---|"

    foreach ($f in $largest) {
        $md += "| $($f.Function) | $($f.TotalLines) | $($f.PartOfFile) |"
    }

    $md += ""
    $md += "## Unused Private Functions"
    $md += "| Function | File |"
    $md += "|---|---|"

    if ($unused) {
        foreach ($u in $unused) {
            $md += "| $($u.Function) | $($u.PartOfFile) |"
        }
    }
    else {
        $md += "| _None detected_ | - |"
    }

    $md += ""
    $md += "## Refactoring Candidates"
    $md += ""
    $md += "The following functions were identified as potential **refactoring candidates**."
    $md += ""
    $md += "- **LargeFunction** - Function exceeds the recommended size threshold."
    $md += '- **HighComplexity** - Function contains many control structures (`if`, `switch`, `foreach`, etc.).'
    $md += ""
    $md += "| Function | Issues |"
    $md += "|---|---|"

    if ($refactor) {
        foreach ($r in $refactor) {
            $md += "| $($r.Function) | $($r.Issues) |"
        }
    }
    else {
        $md += "| _None detected_ | - |"
    }


    # Function Size Distribution
    #$md += "```powershell"

    $sizeData = Get-PSModuleQuantity -ModuleName $ModuleName

    $sizeBuckets = @{
        "0-25 Lines"    = ($sizeData | Where-Object TotalLines -le 25).Count
        "26-50 Lines"   = ($sizeData | Where-Object { $_.TotalLines -gt 25 -and $_.TotalLines -le 50 }).Count
        "51-100 Lines"  = ($sizeData | Where-Object { $_.TotalLines -gt 50 -and $_.TotalLines -le 100 }).Count
        "101-200 Lines" = ($sizeData | Where-Object { $_.TotalLines -gt 100 -and $_.TotalLines -le 200 }).Count
        "201-500 Lines" = ($sizeData | Where-Object { $_.TotalLines -gt 200 -and $_.TotalLines -le 500 }).Count
        ">500 Lines"    = ($sizeData | Where-Object TotalLines -gt 500).Count
    }

    $md += ""
    $md += "## Function Size Distribution"
    $md += '```mermaid'
    $md += "pie"
    $md += "    title Function Size Distribution"

    foreach ($bucket in $sizeBuckets.Keys) {
        $md += "    ""$bucket"" : $($sizeBuckets[$bucket])"
    }

    $md += '```'


    $complexity = Get-PSModuleComplexity -ModuleName $ModuleName |
    Sort-Object Complexity -Descending |
    Select-Object -First 10

    $labels = ($complexity.Function | ForEach-Object {
            ($_ -replace '[^A-Za-z0-9_]', '_')
        }) -join ', '

    $values = ($complexity.Complexity) -join ', '

    $maxComplexity = ($complexity.Complexity | Measure-Object -Maximum).Maximum

    $md += ""
    $md += "## Complexity Ranking"
    $md += '```mermaid'
    $md += "xychart-beta"
    $md += "    title ""Top Function Complexity"""
    $md += "    x-axis [$labels]"
    $md += "    y-axis ""Complexity"" 0 --> $maxComplexity"
    $md += "    bar [$values]"
    $md += '```'

    $deps = Get-PSModuleDependencyGraph -ModuleName $ModuleName |
    Group-Object Function |
    Sort-Object Count -Descending |
    Select-Object -First 25 |
    ForEach-Object { $_.Group }

    $md += ""
    $md += "## Function Dependency Graph (Top 25)"
    $md += '```mermaid'
    $md += "graph TD"

    foreach ($d in $deps) {

        $from = ($d.Function -replace '[^A-Za-z0-9_]', '_')
        $to = ($d.Calls -replace '[^A-Za-z0-9_]', '_')

        $md += "    $from[`"$($d.Function)`"] --> $to[`"$($d.Calls)`"]"
    }

    $md += '```'



    $md | Set-Content $Path -Encoding UTF8


    Invoke-Output -Type TextMaker -Message "Markdown report exported to: " -TextMaker $Path


}
