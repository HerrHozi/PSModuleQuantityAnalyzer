################################################################################
######                                                                     #####
######  LastUpdate = '2026-03-11'                                           ##### 
######  ModuleVersion = '2026.3.11.1144'                                    #####
######                                                                     #####
################################################################################

$Script:FGCIInfo = [System.ConsoleColor]::Magenta    # Additional info / side details
$Script:FGCMInfo = [System.ConsoleColor]::Yellow       # Main info (instead of Yellow → modern, easy to read)
$Script:FGCSInfo = [System.ConsoleColor]::Gray   # Secondary info / less important
$Script:FGCCommand = [System.ConsoleColor]::Green      # Commands / executions
$Script:FGCQuestion = [System.ConsoleColor]::Cyan
$Script:FGCQuestion2 = [System.ConsoleColor]::Cyan     # Questions / user input
$Script:FGCHighLight = [System.ConsoleColor]::Magenta      # Clear highlight text
$Script:FGCWarning = [System.ConsoleColor]::DarkYellow     # Warnings (classic Yellow)
$Script:FGCError = [System.ConsoleColor]::Red        # Errors (bright red tone, more visible)
$Script:FGCSuccess = [System.ConsoleColor]::Green

$Script:ConsoleBGColor = [System.ConsoleColor]::Black    # Background remains black
$Script:ConsoleFGColor = [System.ConsoleColor]::Gray     # Default text gray



$Script:DateFormatLog = "yyyy-MM-dd HH:mm:ss.fff"
$Script:DateFormatSA = "yyyy-MM-dd HH:mm:ss"

$SAModulePath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$SAModuleName = $MyInvocation.MyCommand.ScriptBlock.Module.Name
$SAModuleManifest = (Test-ModuleManifest -Path $(join-path $SAModulePath -ChildPath "\$SAModuleName.psd1"))
$SAModuleLastUpdate = $SAModuleManifest.PrivateData.PSData.LastUpdate

$Script:SAModuleLog = Join-Path -Path $SAModulePath -ChildPath "$SAModuleName.log"


$PublicFunctions = Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1" -ErrorAction SilentlyContinue
$PrivateFunctions = Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1" -ErrorAction SilentlyContinue

foreach ($file in $PrivateFunctions) {
    . $file.FullName
}

foreach ($file in $PublicFunctions) {
    . $file.FullName
}

Export-ModuleMember -Function $PublicFunctions.BaseName

if ($PSVersionTable.PSEdition -eq 'Core') {
    $PSStyle.Formatting.TableHeader = "`e[90m"
}


Write-BlockFont -Phrase 'PSModule QA' -Frame -Color1 Yellow -Color2 Gray -ShadowColor DarkGray -FrameColor Gray
Write-Host "  Description: $($SAModuleManifest.Description) " -ForegroundColor Gray
Write-Host "  Company: $($SAModuleManifest.CompanyName) | Version: $($SAModuleManifest.Version) | Last Update: $SAModuleLastUpdate | Copyright: $($SAModuleManifest.Copyright)" -ForegroundColor Gray
Write-Host "  " -NoNewline
Write-Host "`n     [>] get-command " -NoNewline -ForegroundColor Yellow
Write-Host "-Module " -ForegroundColor DarkGray -NoNewline
Write-Host "$SAModuleName`n`n" -ForegroundColor DarkCyan

$host.ui.RawUI.WindowTitle = "$SAModuleName - $($SAModuleManifest.Version)"