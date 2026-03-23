function Write-Syntax {

    ################################################################################
    #####                                                                      ##### 
    ##### Format the command based on the new Windows Terminal color schema    #####                               
    #####                                                                      #####  
    ################################################################################

    [CmdletBinding(DefaultParameterSetName = 'ByArrays')]
    Param (
        [Parameter(ParameterSetName = 'ByArrays')]
        [String[]]$Text,

        [Parameter(ParameterSetName = 'ByArrays')]
        [ConsoleColor[]]$Color,

        [Parameter(ParameterSetName = 'ByPairs', Mandatory = $true, Position = 0)]
        [Object[]]$TextColor,

        [Parameter(ParameterSetName = 'BySegments', Mandatory = $true)]
        [Object[]]$Segment,

        [Switch]$NoNewline = $false
    )

    $CurrentFunction = Get-FunctionName
    Write-Log -Message "### Start Function $CurrentFunction ###"
    #################### main code | out- host #####################

    function Get-SegmentValue {
        param (
            [Parameter(Mandatory = $true)]
            [Object]$InputObject,

            [Parameter(Mandatory = $true)]
            [String]$Name
        )

        if ($InputObject -is [System.Collections.IDictionary]) {
            if ($InputObject.Contains($Name)) {
                return $InputObject[$Name]
            }
            return $null
        }

        $Property = $InputObject.PSObject.Properties[$Name]
        if ($null -ne $Property) {
            return $Property.Value
        }

        return $null
    }

    function Get-LineOptionAnsiColor {
        param (
            [Parameter(Mandatory = $true)]
            [String]$LineOption,

            [Object]$PSReadLineOption
        )

        if ($null -eq $PSReadLineOption) {
            return $null
        }

        $lineOptionMap = @{
            'Command'              = 'CommandColor'
            'Parameter'            = 'ParameterColor'
            'Value'                = 'DefaultTokenColor'
            'ValueQuoted'          = 'StringColor'
            'WordDelimiters'       = 'OperatorColor'
            'ScriptBlockArguments' = 'CommandColor'
            'Operator'             = 'OperatorColor'
            'String'               = 'StringColor'
            'Variable'             = 'VariableColor'
            'Keyword'              = 'KeywordColor'
            'Type'                 = 'TypeColor'
            'Number'               = 'NumberColor'
            'Member'               = 'MemberColor'
            'Comment'              = 'CommentColor'
            'Error'                = 'ErrorColor'
            'DefaultToken'         = 'DefaultTokenColor'
            'Emphasis'             = 'EmphasisColor'
        }

        $PropertyName = $lineOptionMap[$LineOption]
        if ([string]::IsNullOrWhiteSpace($PropertyName)) {
            if ($LineOption -match 'Color$') {
                $PropertyName = $LineOption
            }
            else {
                $PropertyName = "{0}Color" -f $LineOption
            }
        }

        $Property = $PSReadLineOption.PSObject.Properties[$PropertyName]
        if ($null -eq $Property -or [string]::IsNullOrWhiteSpace([string]$Property.Value)) {
            return $null
        }

        return [string]$Property.Value
    }

    $OutputSegments = @()
    $PSReadLineOption = Get-PSReadLineOption -ErrorAction SilentlyContinue
    $AnsiReset = [char]27 + '[0m'

    switch ($PSCmdlet.ParameterSetName) {
        'ByPairs' {
            if ($TextColor.Count % 2 -ne 0) {
                throw "TextColor expecting: Color, Text, Color, Text ..."
            }

            for ($i = 0; $i -lt $TextColor.Count; $i += 2) {
                $OutputSegments += [PSCustomObject]@{
                    Text         = [string]$TextColor[$i + 1]
                    ConsoleColor = [ConsoleColor]$TextColor[$i]
                    AnsiColor    = $null
                }
            }
        }
        'BySegments' {
            foreach ($CurrentSegment in $Segment) {
                $SegmentText = Get-SegmentValue -InputObject $CurrentSegment -Name 'Text'
                $SegmentColor = Get-SegmentValue -InputObject $CurrentSegment -Name 'Color'
                $LineOption = Get-SegmentValue -InputObject $CurrentSegment -Name 'LineOption'

                if ($null -eq $SegmentText) {
                    throw "Each segment must contain text."
                }

                if ($null -ne $SegmentColor) {
                    $OutputSegments += [PSCustomObject]@{
                        Text         = [string]$SegmentText
                        ConsoleColor = [ConsoleColor]$SegmentColor
                        AnsiColor    = $null
                    }
                    continue
                }

                if ($null -eq $LineOption) {
                    throw "Each segment must contain Color or LineOption."
                }

                $AnsiColor = Get-LineOptionAnsiColor -LineOption ([string]$LineOption) -PSReadLineOption $PSReadLineOption
                if ($null -ne $AnsiColor) {
                    $OutputSegments += [PSCustomObject]@{
                        Text         = [string]$SegmentText
                        ConsoleColor = $null
                        AnsiColor    = $AnsiColor
                    }
                }
                else {
                    $OutputSegments += [PSCustomObject]@{
                        Text         = [string]$SegmentText
                        ConsoleColor = [ConsoleColor]::Gray
                        AnsiColor    = $null
                    }
                }
            }
        }
        default {
            if (-not $Text -or -not $Color -or $Text.Count -ne $Color.Count) {
                throw "Text and Color must be set and contain the same number of elements."
            }

            for ($i = 0; $i -lt $Text.Length; $i++) {
                $OutputSegments += [PSCustomObject]@{
                    Text         = [string]$Text[$i]
                    ConsoleColor = [ConsoleColor]$Color[$i]
                    AnsiColor    = $null
                }
            }
        }
    }

    foreach ($CurrentOutputSegment in $OutputSegments) {
        if (-not [string]::IsNullOrWhiteSpace($CurrentOutputSegment.AnsiColor)) {
            Write-Host ("{0}{1}{2}" -f $CurrentOutputSegment.AnsiColor, $CurrentOutputSegment.Text, $AnsiReset) -NoNewLine | Out-Host
        }
        else {
            Write-Host $CurrentOutputSegment.Text -ForegroundColor $CurrentOutputSegment.ConsoleColor -NoNewLine | Out-Host
        }
    }

    If ($NoNewline -eq $false) { Write-Host '' | out-host }
    
    Write-Log -Message "    >> Highlighted output generated."
    ######################## main code ############################
    #$runtime = Get-RunTime -StartRunTime $StartRunTime
    #Write-Log -Message "    Run Time: $runtime [h] ###"
    Write-Log -Message "### End Function $CurrentFunction ###"
}
