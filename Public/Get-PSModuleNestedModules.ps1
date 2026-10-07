<#
.SYNOPSIS
Summarizes the main module and each nested module of a PowerShell module.

.DESCRIPTION
Get-PSModuleNestedModules reads the NestedModules entries of the module manifest
and returns one row per nested module plus one row for the main module itself
('(main)'). Each row contains version, function counts, line metrics, and the
comment ratio.

Only nested modules located in a sub folder of the module are listed. Nested
modules placed directly in the module folder are counted as part of the main
module.

.PARAMETER ModuleName
Specifies the module to analyze. Use the module name as recognized by
PowerShell (for example, a loaded module or module discoverable in PSModulePath)
or the path to the module manifest.

.EXAMPLE
Get-PSModuleNestedModules -ModuleName .\SSAwBH.psd1 | Format-Table

Returns metrics for SSAwBH and each of its nested modules.

.OUTPUTS
PSCustomObject. The output includes NestedModule, Version, Functions, Public,
Private, Files, TotalLines, LinesOfCode, LinesOfComment, CommentRatio, and Path.

.NOTES
A function counts as Public when its file is located in a 'Public' folder.
#>
function Get-PSModuleNestedModules {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $module = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1

    if (-not $module) {
        throw "Module '$ModuleName' was not found."
    }

    $data = Get-PSModuleQuantity -ModuleName $ModuleName

    $entries = @([PSCustomObject]@{ Name = '(main)'; Root = $module.ModuleBase; Version = $module.Version })

    foreach ($root in Get-PSModuleNestedRoots -Module $module) {

        $manifestFile = Get-ChildItem -Path $root.Root -Filter *.psd1 -File | Select-Object -First 1
        $version = if ($manifestFile) {
            (Import-PowerShellDataFile -Path $manifestFile.FullName -ErrorAction SilentlyContinue).ModuleVersion
        }

        $entries += [PSCustomObject]@{ Name = $root.Name; Root = $root.Root; Version = $version }
    }

    foreach ($entry in $entries) {

        $items = @($data | Where-Object { $_.NestedModule -eq $entry.Name })

        $totalLines = [int]($items | Measure-Object -Property TotalLines -Sum).Sum
        $linesOfComment = [int]($items | Measure-Object -Property LinesOfComment -Sum).Sum

        [PSCustomObject]@{
            NestedModule   = $entry.Name
            Version        = $entry.Version
            Functions      = $items.Count
            Public         = @($items | Where-Object Type -eq 'Public').Count
            Private        = @($items | Where-Object Type -eq 'Private').Count
            Files          = @($items.FullName | Sort-Object -Unique).Count
            TotalLines     = $totalLines
            LinesOfCode    = [int]($items | Measure-Object -Property LinesOfCode -Sum).Sum
            LinesOfComment = $linesOfComment
            CommentRatio   = if ($totalLines) { [math]::Round(100 * $linesOfComment / $totalLines, 1) } else { 0 }
            Path           = $entry.Root
        }
    }
}
