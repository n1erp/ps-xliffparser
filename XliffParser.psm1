Set-StrictMode -Version Latest

$script:XliffParserPublicFunctions = @(
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

. $PSScriptRoot\Classes\XliffTranslationUnit.ps1

foreach ($helperPath in Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter '*.ps1' -File | Sort-Object Name) {
    . $helperPath.FullName
}

foreach ($functionPath in Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' -File | Sort-Object Name) {
    . $functionPath.FullName
}

Export-ModuleMember -Function $script:XliffParserPublicFunctions
