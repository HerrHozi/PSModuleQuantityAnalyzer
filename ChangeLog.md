# Change Log

```Text
Author:          Holger Zimmermann | zimmermann.holger@live.de
Current Version: 2026.11.26.1366
Last Update:     2026-11-26
```

- Version 2026.11.26.1366
  - added Publish-QAModule

- Version 2026.11.26.1356
  - Fixed misted Nested Folder

- Version 2026.11.26.1355
  - Fixed misted Nested Folder

- Version 2026.11.26.574
  - Guides are ready: Docs folder with one guide per public command
  - Get-PSModuleSummary: files and functions in subfolders (for example Private\ASP07) are counted, Public/Private is decided by the path below the module root
  - Get-PSModuleSummary: new properties DateOfAnalysis, HtmlFiles, MarkdownFiles, GraphicFiles
  - Get-PSModuleSummary: every call is appended to %LOCALAPPDATA%\Get-PSModuleSummary.csv (history for later evaluation)
  - Get-PSModuleSummary: new switches -ShowHistory (opens the history in Out-GridView) and -NoHistory (no history row, used by Get-PSModuleMetrics and Export-PSModuleMarkdownReport)
  - Get-PSModuleQuantity: new property RelativePath; References also count quoted function names and calls in .psm1 files
  - Get-PSModuleDependencies: rewritten (parser-based Import-Module / using module / #requires detection, manifest read as data, name or manifest path); fixes a failure on every call
  - Get-PSModuleComplexity: also counts elseif, do/until, every switch case, trap, -and/-or/-xor, ternary and pipeline chains; nested functions counted separately (scores are higher than before)
  - Get-PSModuleHealth: UnusedFunctions counts private functions only
  - Get-PSModuleRefactoringCandidates: rules UnusedPrivateFunction and NoDocumentation work now
  - Export-PSModuleQuantityReport: default path .\ModuleAnalysis.csv; no -NoTypeInformation warning in PowerShell 7
  - Warning for files that the running PowerShell version cannot parse completely
  - Faster module import (manifest read as data)
  - Fixed help texts of Get-PSModuleDuplicateFunctions and Get-PSModuleUsedVerbs

- Version 2026.11.23.479
  - Checkpoint-PSModuleVersion creates a verified backup of a module working tree, raises the module version and keeps the version information in the project files consistent
  - Optionally it commits, pushes, creates a branch or builds a release folder
  - Runs in Windows PowerShell 5.1 and in PowerShell 7

- Version 2026.11.23.478
  - 5.1 compatible

- Version 2026.11.21.1119
  - add function Checkpoint-PSModuleVersion

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
