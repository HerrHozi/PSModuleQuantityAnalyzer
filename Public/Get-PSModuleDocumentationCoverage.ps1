<#
.SYNOPSIS
Calculates documentation coverage for functions in a PowerShell module.

.DESCRIPTION
Get-PSModuleDocumentationCoverage analyzes all function definitions in the
specified module and determines how many functions provide comment-based help.

The function parses source files with PowerShell AST, counts total functions,
counts functions with help content, and returns a coverage percentage.

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath).

.EXAMPLE
Get-PSModuleDocumentationCoverage -ModuleName PSModuleQuantityAnalyzer

Returns documentation coverage statistics for PSModuleQuantityAnalyzer.

.OUTPUTS
PSCustomObject. The output includes ModuleName, Version, Functions,
FunctionsWithHelp, FunctionsWithoutHelp, and DocumentationCoveragePercent.

.NOTES
Coverage is rounded to two decimal places.
#>
function Get-PSModuleDocumentationCoverage {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $quantity = Get-PSModuleQuantity -ModuleName $ModuleName

    $files = $quantity.FullName | Sort-Object -Unique

    $totalFunctions = 0
    $functionsWithHelp = 0

    foreach ($file in $files) {

        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $file,
            [ref]$null,
            [ref]$null
        )

        $functions = $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)

        foreach ($func in $functions) {

            $totalFunctions++

            if ($func.GetHelpContent()) {
                $functionsWithHelp++
            }

        }

    }

    $coverage = if ($totalFunctions -gt 0) {
        [math]::Round(($functionsWithHelp / $totalFunctions) * 100,2)
    } else {
        0
    }

    [PSCustomObject]@{

        ModuleName = $quantity[0].ModuleName
        Version    = $quantity[0].Version

        Functions               = $totalFunctions
        FunctionsWithHelp       = $functionsWithHelp
        FunctionsWithoutHelp    = $totalFunctions - $functionsWithHelp

        DocumentationCoveragePercent = $coverage
    }

}