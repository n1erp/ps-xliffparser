@{
    RootModule        = 'XliffParser.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '2981e723-15f5-4629-b8fc-f0fff5f2aebb'
    Author            = 'TAHER EL Mehdi'
    CompanyName       = 'N1erp'
    Copyright         = '(c) 2026 XliffParser TAHER EL Mehdi. All rights reserved.'
    Description       = 'PowerShell toolkit for reading, writing, validating, synchronizing, analyzing, and exporting XLIFF files for Business Central.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Import-XliffFile'
        'Export-XliffFile'
        'Get-XliffTranslationUnit'
        'Set-XliffTranslationUnit'
        'Test-XliffFile'
        'Export-XliffCsv'
        'Export-XliffJson'
        'Get-XliffStatistics'
        'Sync-XliffFile'
        'Compare-XliffFile'
        'Search-XliffText'
        'Import-XliffWorkspace'
        'Get-XliffMissingTranslation'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('xliff', 'localization', 'translation', 'business-central', 'dynamics-365', 'powershell','al','xlf')
            ProjectUri = 'https://github.com/taher-el-mehdi/ps-xliffparser'
            LicenseUri = 'https://opensource.org/licenses/MIT'
        }
    }
}
