# Filter.ps1
# Demonstrates Get-XliffTranslationUnit — query units by id, state, or text.
#
# Run from the repository root:
#   pwsh .\Examples\Filter.ps1

Import-Module XliffParser

$sample = Join-Path $PSScriptRoot '..\Tests\Fixtures\Sample.xlf'

Write-Host "`n=== Filter by state ===" -ForegroundColor Cyan
Import-XliffFile -Path $sample |
    Get-XliffTranslationUnit -State needs-review |
    Format-Table Id, Source, Target, State -AutoSize

Write-Host "`n=== Filter by Id ===" -ForegroundColor Cyan
Import-XliffFile -Path $sample |
    Get-XliffTranslationUnit -Id 'Report 50000 - Label 1' |
    Format-List Id, Source, Target, State

Write-Host "`n=== Wildcard filter on source text ===" -ForegroundColor Cyan
# Default matching uses -like wildcards (* and ?)
Import-XliffFile -Path $sample |
    Get-XliffTranslationUnit -Source '*Label*' |
    Format-Table Id, Source -AutoSize

Write-Host "`n=== Regex filter ===" -ForegroundColor Cyan
Import-XliffFile -Path $sample |
    Get-XliffTranslationUnit -Source 'Report \d+' -Regex |
    Format-Table Id, Source -AutoSize

Write-Host "`n=== Load and filter in one step ===" -ForegroundColor Cyan
# -Path imports the file before filtering
Get-XliffTranslationUnit -Path $sample -State needs-translation |
    Format-Table Id, Source, Target -AutoSize
