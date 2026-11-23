# Change Log

```Text
Author:          Holger Zimmermann | zimmermann.holger@live.de
Current Version: 2026.11.23.479
Last Update:     2026-11-23
```

- Version 2026.11.23.479
  - Checkpoint

- Version 2026.11.23.478
  - 5.1 compatible

- Version 2026.11.22.582
  - added docs

- Version 2026.11.21.1119
  - add function Checkpoint-PSModuleVersion

- Version 2026.11.21.1101
  - Checkpoint

- Version 2026.11.16.716
  - Checkpoint

- Version 2026.10.26.687
  - Code Clean-Up / remove logging, Show DoubleFunctionPairs in  Get-PSModuleSummary
  - Minor bug fixes and performance improvements

- Version 2026.10.7.782
  - Updated Function Get-PSModuleUsedVerbs | check for Approved verbs

- Version 2026.10.7.652
  - Added Get-PSModuleNestedModules: version, function counts and line metrics for the main module and each nested module
  - Added Get-PSModuleNestedDependencies: function calls between the main module and its nested modules
  - Get-PSModuleQuantity returns the new property NestedModule ((main) for the module itself)
  - Verified with Windows PowerShell 5.1 and PowerShell 7

- Version 2026.6.24.721
  - Minor bug fixes and performance improvements

- Version 2026.6.16.1201
  - Added Get-PSModuleDependencies: explicit (manifest), implicit (code) and transitive module dependencies
  - Optional version compatibility check, output as object, console or JSON

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
