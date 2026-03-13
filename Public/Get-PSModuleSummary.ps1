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
ModuleName, Version, LastUpdate, ModulePath, PublicFunctions,
PrivateFunctions, TotalFunctions, PublicFiles, PrivateFiles, and TotalFiles.

.NOTES
This function uses Get-PSModuleQuantity to calculate function counts.
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

    $publicFunctions = ($quantityData |
        Where-Object { $_.FullName -match "Public" }).Count

    $privateFunctions = ($quantityData |
        Where-Object { $_.FullName -match "Private" }).Count

    $allPSFiles = Get-ChildItem -Path (Join-Path $modulePath '*') -Recurse -File |
    Where-Object { $_.Extension -in @('.ps1', '.psm1', '.psd1') }


    $maxDate = ($allPSFiles | Measure-Object -Maximum LastWriteTime).Maximum
    $lastUpdate = if ($maxDate) { $maxDate.ToString('yyyy-MM-dd HH:mm:ss') } else { "unknown" }


    [PSCustomObject]@{

        ModuleName       = $module.Name
        Version          = $module.Version
        LastUpdate       = $lastUpdate


        PublicFunctions  = $publicFunctions
        PrivateFunctions = $privateFunctions
        TotalFunctions   = $publicFunctions + $privateFunctions

        PublicFiles      = $publicFiles.Count
        PrivateFiles     = $privateFiles.Count
        TotalFiles       = $publicFiles.Count + $privateFiles.Count

        ModulePath       = $modulePath
    }
}