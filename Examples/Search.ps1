# Search.ps1
# Demonstrates Search-XliffText — find text in source or target fields.
#
# Run from the repository root:
#   pwsh .\Examples\Search.ps1

Import-Module (Join-Path $PSScriptRoot '..\XliffParser.psd1') -Force

$translated = Join-Path $PSScriptRoot '..\Tests\Fixtures\Systemization.fr-FR.xlf'

Write-Host "`n=== Search source text (literal) ===" -ForegroundColor Cyan
# By default both Source and Target are searched unless -Source or -Target is set
Search-XliffText -Path $translated -Pattern 'Systemization' -Source |
    Select-Object -First 3 Id, Field, Text |
    Format-Table -AutoSize

Write-Host "`n=== Search target text with regex ===" -ForegroundColor Cyan
Search-XliffText -Path $translated -Pattern '^Extension' -Target -Regex |
    Select-Object -First 3 Id, Text |
    Format-Table -AutoSize

Write-Host "`n=== Case-sensitive search ===" -ForegroundColor Cyan
Search-XliffText -Path $translated -Pattern 'Table' -Source -CaseSensitive |
    Measure-Object |
    Select-Object Count

Write-Host "`n=== Fuzzy search (typo-tolerant) ===" -ForegroundColor Cyan
# -Fuzzy uses Levenshtein distance; -MaxDistance controls tolerance (default: 2)
Search-XliffText -Path $translated -Pattern 'Systemizaton' -Source -Fuzzy -MaxDistance 2 |
    Select-Object -First 3 Id, Text |
    Format-Table -AutoSize

Write-Host "`n=== Search from pipeline ===" -ForegroundColor Cyan
Import-XliffFile -Path $translated |
    Search-XliffText -Pattern 'Description' |
    Select-Object -First 2 Id, Field, Text |
    Format-Table -AutoSize
