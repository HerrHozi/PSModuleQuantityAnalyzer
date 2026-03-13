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

    $CurrentFunction = Get-FunctionName
    Write-Log -Message "### Start Function $CurrentFunction ###"
    #$StartRunTime = (Get-Date).ToString($Script:DateFormatLog)
    #################### main code | out- host #####################

    <# 
from Jake: Personally, I like adding icons like at the beginning of output:
[+] success
[x] fail/error
[!] warning
[?] question
[i] information
[>] code snippet
→ ✅ ⚠️ ❗ ℹ️ ❌ 💡 
#>


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
            $level = "INFO"
            $Message = "`n$line`n`n$UpdatedText`n$line`n"
        }
        "Command" {
            If ($NoNewLine) {
                Write-Host "`n  [>] $Message "           -ForegroundColor $Script:FGCCommand -NoNewline
            }
            else {
                Write-Host "`n  [>] $Message`n`n"           -ForegroundColor $Script:FGCCommand 
            }

            $level = "INFO"
        }
        "Warning" { 
            Write-Host "`n  [!] WARNING: $Message`n`n"  -ForegroundColor $Script:FGCWarning
            $level = "WARN" 
        }
        "Critical" { 
            Write-Host "`n   ❗❗ Critical: $Message`n`n"  -ForegroundColor $Script:FGCWarning
            $level = "FATAL" 
        }
        "Success" { 
            Write-Host "`n  [√] $Message`n`n" -ForegroundColor $Script:FGCSuccess
            $level = "INFO"
        }
        "Info" { 
            Write-Host "`n  [i] $Message`n`n"           -ForegroundColor $Script:FGCSInfo 
            $level = "INFO"
        }
        "TextMaker" { 
            Write-host "`n  [i] $Message " -ForegroundColor $Script:FGCSInfo -NoNewline
            Write-host "$TextMaker`n`n" -ForegroundColor $Script:FGCMInfo
            $level = "INFO"
        }
        "Input" { 
            Write-Host "`n  [~] $Message"           -ForegroundColor $Script:FGCInput -NoNewLine
            $answer = Read-Host ":"  
            Write-Host "`n"
            $level = "INFO"
        }
        "Error" { 
            Write-Host "`n  [x] ERROR: $Message`n`n"    -ForegroundColor $Script:FGCError
            $level = "ERROR"
        }
        default { 
            Write-Host "`n  [i] $Message`n`n"           -ForegroundColor $Script:FGCSInfo
            $level = "INFO" 
        }
    }

    #[ValidateSet("INFO", "WARN", "ERROR", "FATAL", "DEBUG")]
    Write-Log -Message "    >> $Type | $Message $TextMaker" -Level $level

    ######################## main code ############################
    #$runtime = Get-RunTime -StartRunTime $StartRunTime
    #Add-SAFunctionRunTime -Function $CurrentFunction -Runtime $runtime
    #Write-Log -Message "    Run Time: $runtime [h] ###"
    Write-Log -Message "### End Function $CurrentFunction ###"

    If ($Type -eq "Input") {
        return $answer
    }
}
