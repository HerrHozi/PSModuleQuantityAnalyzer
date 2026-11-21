# Guide: Export-PSModuleQuantityReport

`Export-PSModuleQuantityReport` writes the function-level data of
[Get-PSModuleQuantity](Get-PSModuleQuantity.md) to a **CSV file**. Use it to analyze the data in
Excel or Power BI, or to keep snapshots.

## Usage

```powershell
Export-PSModuleQuantityReport -ModuleName PSModuleQuantityAnalyzer
Export-PSModuleQuantityReport -ModuleName PSModuleQuantityAnalyzer -Path .\reports\module-analysis.csv
```

## Parameters

| Parameter | Description |
| --- | --- |
| `-ModuleName` | Module name or path to the manifest (mandatory) |
| `-Path` | Target CSV file. Default `.\ModuleAnalysis.csv` in the current directory |

## Result

- UTF-8 encoded CSV, no type header, one row per function, all properties of
  `Get-PSModuleQuantity`.
- An existing file is **overwritten**.
- The command prints the target path and returns no objects.
- The target folder must already exist.

## Open in Excel

The file uses a comma as delimiter. Excel with a German (or other European) regional setting
expects a semicolon and may show everything in one column. Use *Data > From Text/CSV* and choose
the comma as delimiter, or import it with PowerShell:

```powershell
Import-Csv .\ModuleAnalysis.csv | Out-GridView
```

## Tip: dated snapshots

```powershell
$stamp = Get-Date -Format 'yyyy-MM-dd'
Export-PSModuleQuantityReport -ModuleName PSModuleQuantityAnalyzer -Path ".\reports\quantity_$stamp.csv"
```

## See also

[Export-PSModuleMarkdownReport](Export-PSModuleMarkdownReport.md) ·
[Get-PSModuleQuantity](Get-PSModuleQuantity.md)
