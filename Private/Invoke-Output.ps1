function Invoke-Output {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false, Position = 0)]
        [Alias('T')]
        [ValidateSet("Info", "Input", "Success", "Warning", "Error", "Command", "TextMaker", "Header", "Critical")]
        [string] $Type = "Info",
        [Parameter(Mandatory = $false, Position = 1)]
        [Alias('M')]
        [string] $Message,
        [Parameter(Mandatory = $false, Position = 2)]
        [Alias('TM')]
        [string] $TextMaker,
        [switch] $NoNewLine
    )


    IF ($NoNewLine) {
        
    }

    switch ($Type) {
        "Header" { 
            $width = 70
            $line = '_' * $width
            $padding = [math]::Max(0, [math]::Floor(($width - $Message.Length) / 2))
            $UpdatedText = ("{0}{1}" -f (' ' * $padding), $Message)
    
            Write-Host `n$line`n
            Write-Host $UpdatedText
            Write-Host $line`n
        }
        "Command" {
            If ($NoNewLine) {
                Write-Host "`n  [>] $Message "           -ForegroundColor $Script:FGCCommand -NoNewline
            }
            else {
                Write-Host "`n  [>] $Message`n`n"           -ForegroundColor $Script:FGCCommand 
            }

        }
        "Warning" { 
            Write-Host "`n  [!] WARNING: $Message`n`n"  -ForegroundColor $Script:FGCWarning
        }
        "Critical" { 
            Write-Host "`n   ❗❗ Critical: $Message`n`n"  -ForegroundColor $Script:FGCWarning
        }
        "Success" { 
            Write-Host "`n  [√] $Message`n`n" -ForegroundColor $Script:FGCSuccess
        }
        "Info" { 
            Write-Host "`n  [i] $Message`n`n"           -ForegroundColor $Script:FGCSInfo 
        }
        "TextMaker" { 
            Write-host "`n  [i] $Message " -ForegroundColor $Script:FGCSInfo -NoNewline
            Write-host "$TextMaker`n`n" -ForegroundColor $Script:FGCMInfo
        }
        "Input" { 
            Write-Host "`n  [~] $Message"           -ForegroundColor $Script:FGCInput -NoNewLine
            $answer = Read-Host ":"  
            Write-Host "`n"
        }
        "Error" { 
            Write-Host "`n  [x] ERROR: $Message`n`n"    -ForegroundColor $Script:FGCError
        }
        default { 
            Write-Host "`n  [i] $Message`n`n"           -ForegroundColor $Script:FGCSInfo
        }
    }

    If ($Type -eq "Input") {
        return $answer
    }
}
