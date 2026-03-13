@{
    RootModule        = 'PSModuleQuantityAnalyzer.psm1'
    ModuleVersion     = '2026.3.13.420'
    GUID              = 'a5c1c2d4-1b11-4d55-b2d3-1d9a0e8b2f11'

    Author            = 'Holger Zimmermann'
    CompanyName       = 'Community'
    Copyright         = '(c) 2026 Holger Zimmermann'

    Description       = 'PSModuleQuantityAnalyzer is a PowerShell module that performs static analysis of PowerShell modules and generates quantitative metrics about their structure, maintainability, and architecture.'

    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        "Get-PSModuleQuantity",
        "Get-PSModuleSummary",
        "Get-PSModuleMetrics",
        "Get-PSModuleHealth",
        "Get-PSModuleDuplicateFunctions",
        "Get-PSModuleLargestFunctions",
        "Get-PSModuleDocumentationCoverage",
        "Get-PSModuleDependencyGraph",
        "Get-PSModuleComplexity",
        "Get-PSModuleUnusedPrivateFunctions",
        "Get-PSModuleRefactoringCandidates",
        "Export-PSModuleQuantityReport",
        "Export-PSModuleMarkdownReport"
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData       = @{
        PSData = @{
            Tags         = @('PowerShell', 'Module', 'Metrics', 'Analysis')
            ProjectUri   = 'https://github.com/HerrHozi/PSModuleQuantityAnalyzer'
            IconUri      = 'https://raw.githubusercontent.com/HerrHozi/PSModuleQuantityAnalyzer/main/Assets/icon.png'
            ReleaseNotes = 'See ChangeLog.md for details.'
            LastUpdate   = '2026-03-13'
        }
    }
}