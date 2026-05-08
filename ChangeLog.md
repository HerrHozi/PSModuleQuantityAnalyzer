# Changelog

All notable changes to this project are documented in this file.

## Maintainer

- Holger Zimmermann [zimmermann.holger@live.de]

## Current Release

- Version: 2026.5.8.632
- Last Update: 2026-05-08

## [2026.5.8.632]

- Added Function Get-PSModuleUsedVerbs
  
## [2026.3.22.1040]

- Added Function Write-Syntax
- Added dedicated logo via piskel file
- Improved Functions Get-PsModuleSummary and Get-PsModuleQuantity

## [2026.3.13.420]

- Initial public release structure.

## [0.5.0] - 2026-03-11

- Added initial module health scoring prototype.
- Improved report output formatting for markdown exports.

### internal - update via git

```PowerShell
 $Host.UI.RawUI.WindowTitle = "GIT - Upload new version"
$dir = "$env:OneDriveConsumer\Programming\GitHub\PSModuleQuantityAnalyzer"
Set-Location $dir
 git pull
 git status
 git add -A
 git commit -m 'Version 2026.5.8.632 is out - see also readme.md or changeLog.md'
 git push

 Publish-Module -Exclude '.git\*' -Name .\PSModuleQuantityAnalyzer.psd1
