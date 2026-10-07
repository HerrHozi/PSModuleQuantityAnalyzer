function Get-PSModuleNestedRoots {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Module
    )

    if (-not $Module.Path -or $Module.Path -notlike '*.psd1') { return }

    $manifest = Import-PowerShellDataFile -Path $Module.Path -ErrorAction SilentlyContinue
    if (-not $manifest -or -not $manifest.NestedModules) { return }

    $base = [System.IO.Path]::GetFullPath($Module.ModuleBase).TrimEnd('\') + '\'

    foreach ($entry in $manifest.NestedModules) {

        $reference = if ($entry -is [hashtable]) { $entry.ModuleName } else { [string]$entry }
        if (-not $reference) { continue }

        $candidate = [System.IO.Path]::GetFullPath((Join-Path -Path $Module.ModuleBase -ChildPath $reference))

        $root = if (Test-Path -LiteralPath $candidate -PathType Container) {
            $candidate
        }
        elseif (Test-Path -LiteralPath $candidate -PathType Leaf) {
            Split-Path -Path $candidate -Parent
        }
        else {
            continue
        }

        $root = $root.TrimEnd('\') + '\'

        # Nested modules located directly in the module base belong to the main module
        if ($root -eq $base -or -not $root.StartsWith($base, [System.StringComparison]::OrdinalIgnoreCase)) { continue }

        [PSCustomObject]@{
            Name = Split-Path -Path $root.TrimEnd('\') -Leaf
            Root = $root
        }
    }
}
