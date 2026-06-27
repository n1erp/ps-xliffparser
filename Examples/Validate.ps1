# Validate.ps1
# Demonstrates Test-XliffFile — find missing translations and validation issues.
#
# Run from the repository root:
#   pwsh .\Examples\Validate.ps1

Import-Module XliffParser

$sample = Join-Path $PSScriptRoot '..\Tests\Fixtures\Sample.xlf'
$translated = Join-Path $PSScriptRoot '..\Tests\Fixtures\Systemization.fr-FR.xlf'

Write-Host "`n=== Validate a file with missing translations ===" -ForegroundColor Cyan
# Returns XliffParser.ValidationResult objects (Rule, Severity, Id, Message)
Test-XliffFile -Path $sample | Format-Table Rule, Severity, Id -AutoSize

Write-Host "`n=== Validate a fully translated file ===" -ForegroundColor Cyan
Test-XliffFile -Path $translated | Format-Table Rule, Message -AutoSize

Write-Host "`n=== Fail CI build on missing translations ===" -ForegroundColor Cyan
# -FailOnMissing throws when any target is empty — use in pipelines
try {
    Test-XliffFile -Path $sample -FailOnMissing
    Write-Host 'Validation passed.'
}
catch {
    Write-Host "Validation failed: $($_.Exception.Message)"
}

Write-Host "`n=== Validation rules checked ===" -ForegroundColor Cyan
Write-Host @"
  MissingTarget  - empty or whitespace target text
  DuplicateId    - same Id appears more than once
  IdRequired     - trans-unit without an Id
  InvalidState   - target state not in XLIFF 1.2 vocabulary
  Valid          - returned when no issues are found
"@
