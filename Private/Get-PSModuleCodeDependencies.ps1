function Get-PSModuleCodeDependencies {

    <#
    Finds modules that the source code asks for, using the PowerShell parser (not text search),
    so comments and strings are ignored. Detected are:
      Import-Module <name> | -Name <name> | -Name a,b   (quoted or not, also alias ipmo)
      using module <name>
      #requires -Modules <name>
    Names that are paths, variables or expandable strings cannot be resolved statically and
    are skipped, as are the module itself and path imports of bundled modules.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Module,

        [Parameter(Mandatory)]
        $Files
    )

    $base = [System.IO.Path]::GetFullPath($Module.ModuleBase).TrimEnd('\', '/') + '\'
    $astCache = Get-PSModuleAstCache -Files $Files
    $found = @{}

    $valueParameters = @('Prefix', 'Version', 'MinimumVersion', 'MaximumVersion', 'RequiredVersion',
        'ArgumentList', 'Function', 'Cmdlet', 'Variable', 'Alias', 'PSSession', 'CimSession',
        'FullyQualifiedName', 'Scope', 'CimResourceUri', 'CimNamespace', 'Assembly')

    function Get-ConstantValue {
        param($Node)
        if ($Node -is [System.Management.Automation.Language.StringConstantExpressionAst]) { $Node.Value }
        elseif ($Node -is [System.Management.Automation.Language.ArrayLiteralAst]) {
            foreach ($element in $Node.Elements) {
                if ($element -is [System.Management.Automation.Language.StringConstantExpressionAst]) { $element.Value }
            }
        }
    }

    function Add-Dependency {
        param([string]$Name, [string]$Location, $Minimum)

        if ([string]::IsNullOrWhiteSpace($Name)) { return }
        if ($Name -match '[\\/]' -or $Name -match '\.(psd1|psm1|dll)$') { return }   # path import
        if ($Name -ieq $Module.Name) { return }

        if (-not $found.ContainsKey($Name)) {
            $found[$Name] = @{ Name = $Name; Count = 0; Locations = [System.Collections.Generic.List[string]]::new(); Minimum = $null }
        }
        $entry = $found[$Name]
        $entry.Count++
        if ($Location -notin $entry.Locations) { $entry.Locations.Add($Location) }
        if ($Minimum -and (-not $entry.Minimum -or $Minimum -gt $entry.Minimum)) { $entry.Minimum = $Minimum }
    }

    foreach ($file in $Files) {

        $ast = $astCache[$file.FullName]
        if (-not $ast) { continue }

        $location = if ($file.FullName.StartsWith($base, [System.StringComparison]::OrdinalIgnoreCase)) {
            $file.FullName.Substring($base.Length)
        }
        else {
            $file.Name
        }

        # #requires -Modules
        if ($ast.ScriptRequirements) {
            foreach ($required in $ast.ScriptRequirements.RequiredModules) {
                $minimum = if ($required.RequiredVersion) { $required.RequiredVersion } else { $required.Version }
                Add-Dependency -Name $required.Name -Location $location -Minimum $minimum
            }
        }

        # using module <name>
        $usings = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.UsingStatementAst] }, $true)
        foreach ($using in $usings) {
            if ($using.UsingStatementKind -ne 'Module') { continue }
            if ($using.Name) {
                Add-Dependency -Name $using.Name.Value -Location $location
            }
            elseif ($using.ModuleSpecification) {
                try {
                    $spec = $using.ModuleSpecification.SafeGetValue()
                    Add-Dependency -Name ([string]$spec.ModuleName) -Location $location
                }
                catch { Write-Verbose "Cannot evaluate module specification in ${location}: $_" }
            }
        }

        # Import-Module
        $commands = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true)
        foreach ($command in $commands) {

            $commandName = $command.GetCommandName()
            if ($commandName -notin @('Import-Module', 'ipmo')) { continue }

            $elements = $command.CommandElements
            $i = 1
            while ($i -lt $elements.Count) {

                $element = $elements[$i]

                if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {

                    $parameter = $element.ParameterName
                    $isName = $parameter.Length -ge 2 -and 'Name'.StartsWith($parameter, [System.StringComparison]::OrdinalIgnoreCase)
                    $takesValue = $isName -or [bool]($valueParameters | Where-Object { $_.StartsWith($parameter, [System.StringComparison]::OrdinalIgnoreCase) })

                    if ($element.Argument) {
                        if ($isName) { foreach ($v in (Get-ConstantValue $element.Argument)) { Add-Dependency -Name $v -Location $location } }
                        $i++
                        continue
                    }

                    if ($takesValue -and ($i + 1) -lt $elements.Count) {
                        if ($isName) { foreach ($v in (Get-ConstantValue $elements[$i + 1])) { Add-Dependency -Name $v -Location $location } }
                        $i += 2
                        continue
                    }

                    $i++   # switch parameter such as -Force
                    continue
                }

                # first positional argument is -Name
                foreach ($v in (Get-ConstantValue $element)) { Add-Dependency -Name $v -Location $location }
                $i++
            }
        }
    }

    foreach ($entry in $found.Values) {
        New-PSModuleDependencyRecord -Name $entry.Name -Type 'Implicit (Code)' -UsageCount $entry.Count `
            -Locations $entry.Locations.ToArray() `
            -RequiredVersion $(if ($entry.Minimum) { $entry.Minimum.ToString() } else { 'Any' }) `
            -MinimumVersion $entry.Minimum
    }
}
