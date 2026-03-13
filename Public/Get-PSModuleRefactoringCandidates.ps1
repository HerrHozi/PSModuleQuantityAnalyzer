<#
.SYNOPSIS
Identifies functions that are potential refactoring candidates.

.DESCRIPTION
Get-PSModuleRefactoringCandidates analyzes function size, complexity, reference
count, and documentation indicators to detect functions that may benefit from
refactoring.

Issues are reported as a comma-separated list and can include:
- LargeFunction
- HighComplexity
- UnusedPrivateFunction
- NoDocumentation

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath).

.PARAMETER MaxLines
Specifies the maximum recommended function size in lines.
Functions above this threshold are flagged as LargeFunction.
Default value: 150.

.PARAMETER MaxComplexity
Specifies the maximum recommended cyclomatic complexity.
Functions above this threshold are flagged as HighComplexity.
Default value: 10.

.EXAMPLE
Get-PSModuleRefactoringCandidates -ModuleName PSModuleQuantityAnalyzer

Returns functions in PSModuleQuantityAnalyzer that match one or more default
refactoring criteria.

.EXAMPLE
Get-PSModuleRefactoringCandidates -ModuleName PSModuleQuantityAnalyzer -MaxLines 120 -MaxComplexity 8

Runs a stricter analysis by lowering size and complexity thresholds.

.OUTPUTS
PSCustomObject. The output includes ModuleName, Version, Function, TotalLines,
Complexity, References, Issues, PartOfFile, and FullName.

.NOTES
Complexity values are sourced from Get-PSModuleComplexity.
#>
function Get-PSModuleRefactoringCandidates {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [int]$MaxLines = 150,
        [int]$MaxComplexity = 10
    )

    $quantity = Get-PSModuleQuantity -ModuleName $ModuleName
    $complexity = Get-PSModuleComplexity -ModuleName $ModuleName

    $complexityMap = @{}
    foreach ($c in $complexity) {
        $complexityMap[$c.Function] = $c.Complexity
    }

    foreach ($f in $quantity) {

        $comp = if ($complexityMap.ContainsKey($f.Function)) {
            $complexityMap[$f.Function]
        }
        else {
            1
        }

        $issues = @()

        if ($f.TotalLines -gt $MaxLines) {
            $issues += "LargeFunction"
        }

        if ($comp -gt $MaxComplexity) {
            $issues += "HighComplexity"
        }

        if ($f.References -eq 0 -and $f.Visibility -eq "Private") {
            $issues += "UnusedPrivateFunction"
        }

        if ($f.HasHelp -eq $false) {
            $issues += "NoDocumentation"
        }

        if ($issues.Count -gt 0) {

            [PSCustomObject]@{

                ModuleName = $f.ModuleName
                Version    = $f.Version

                Function   = $f.Function

                TotalLines = $f.TotalLines
                Complexity = $comp
                References = $f.References

                Issues     = ($issues -join ",")

                PartOfFile = $f.PartOfFile
                FullName   = $f.FullName
            }

        }

    }

}