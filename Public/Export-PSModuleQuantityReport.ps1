<#
.SYNOPSIS
Exports module quantity analysis data to a CSV file.

.DESCRIPTION
Export-PSModuleQuantityReport runs Get-PSModuleQuantity for the specified
module and writes the resulting function-level metrics to a UTF-8 encoded CSV
file.

The export includes details such as function name, line counts, reference count,
and source file location.

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath).

.PARAMETER Path
Specifies the destination CSV file path.
If omitted, the default path is .\ModuleAnalysis.csv.

.EXAMPLE
Export-PSModuleQuantityReport -ModuleName PSModuleQuantityAnalyzer

Exports quantity analysis data for PSModuleQuantityAnalyzer to the default CSV
file in the current directory.

.EXAMPLE
Export-PSModuleQuantityReport -ModuleName PSModuleQuantityAnalyzer -Path .\reports\module-analysis.csv

Exports quantity analysis data to a custom CSV path.

.OUTPUTS
None. This function writes a CSV file to disk.

.NOTES
The CSV file is written with UTF-8 encoding and without type information.
#>
function Export-PSModuleQuantityReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [string]$Path
    )


    if (-not $Path) {
        $Path = '.\ModuleAnalysis.csv'
    }

    $data = Get-PSModuleQuantity -ModuleName $ModuleName

    $csvParams = @{ Path = $Path; Encoding = 'UTF8' }
    # PowerShell 7+ never writes type information (the switch is obsolete there);
    # Windows PowerShell 5.1 needs it to suppress the '#TYPE' header line.
    if ($PSVersionTable.PSVersion.Major -lt 6) { $csvParams.NoTypeInformation = $true }
    $data | Export-Csv @csvParams


    Invoke-Output -Type TextMaker -Message "Quantity Report report exported to: " -TextMaker $Path
}