BeforeAll {
    . (Join-Path $PSScriptRoot 'Shared\TestHelpers.ps1')
    Initialize-XliffParserTests
}

Describe 'Validation and statistics' {
    It 'reports missing translations in the Sample fixture' {
        $results = @(Test-XliffFile -Path $script:SamplePath)

        ($results | Where-Object Rule -eq 'MissingTarget').Count | Should -Be 1
        ($results | Where-Object Id -eq 'Report 50000 - Label 1').Rule | Should -Be 'MissingTarget'
    }

    It 'returns a valid result for a fully translated Systemization file' {
        $results = @(Test-XliffFile -Path $script:TranslatedPath)

        ($results | Where-Object Rule -eq 'MissingTarget').Count | Should -Be 0
        ($results | Where-Object Rule -eq 'Valid').Count | Should -Be 1
    }

    It 'throws when -FailOnMissing is specified and targets are empty' {
        { Test-XliffFile -Path $script:SamplePath -FailOnMissing } | Should -Throw '*Missing translations*'
    }

    It 'calculates completion statistics for the Sample fixture' {
        $statistics = Get-XliffStatistics -Path $script:SamplePath

        $statistics.TotalTranslations | Should -Be 3
        $statistics.TranslatedCount | Should -Be 1
        $statistics.MissingCount | Should -Be 1
        $statistics.NeedsReviewCount | Should -Be 1
        $statistics.CompletionPercentage | Should -Be 33.33
    }

    It 'reports full completion for the Systemization French file' {
        $statistics = Get-XliffStatistics -Path $script:TranslatedPath

        $statistics.TotalTranslations | Should -Be 93
        $statistics.TranslatedCount | Should -Be 93
        $statistics.MissingCount | Should -Be 0
        $statistics.CompletionPercentage | Should -Be 100
    }

    It 'returns only missing translations from pipeline input' {
        $missing = @(Import-XliffFile -Path $script:SamplePath | Get-XliffMissingTranslation)

        $missing.Count | Should -Be 1
        $missing[0].Id | Should -Be 'Report 50000 - Label 1'
    }
}

Describe 'Get-XliffTranslationUnit and Set-XliffTranslationUnit' {
    It 'filters units by state and wildcard source text' {
        $needsReview = Import-XliffFile -Path $script:SamplePath |
            Get-XliffTranslationUnit -State needs-review

        $needsReview.Count | Should -Be 1
        $needsReview[0].Id | Should -Be 'Page 21 - Action 1 - Property Caption'
    }

    It 'updates only the selected unit when -Id is supplied' {
        $updated = Import-XliffFile -Path $script:SamplePath |
            Set-XliffTranslationUnit -Id 'Report 50000 - Label 1' -Target 'Solde dû' -State translated -PassThru

        ($updated | Where-Object Id -eq 'Report 50000 - Label 1').Target | Should -Be 'Solde dû'
        ($updated | Where-Object Id -eq 'Table 18 - Field 1 - Property Caption').Target | Should -Be 'No. client'
    }
}

Describe 'Search-XliffText' {
    It 'finds literal matches in source text' {
        $results = @(Search-XliffText -Path $script:TranslatedPath -Pattern 'Systemization' -Source)

        $results.Count | Should -BeGreaterThan 0
        $results[0].Field | Should -Be 'Source'
    }

    It 'finds regex matches in target text' {
        $results = @(Search-XliffText -Path $script:TranslatedPath -Pattern '^Extension' -Target -Regex)

        $results.Count | Should -BeGreaterThan 0
        $results[0].Text | Should -Match '^Extension'
    }
}

Describe 'Import-XliffWorkspace' {
    It 'loads all XLIFF files under the Fixtures folder' {
        $workspace = Import-XliffWorkspace -Path $script:FixtureRoot

        $workspace.PSObject.TypeNames[0] | Should -Be 'XliffParser.Workspace'
        $workspace.Files.Count | Should -BeGreaterThan 0
        $workspace.Statistics.TotalTranslations | Should -BeGreaterThan 0
        $frenchFiles = @($workspace.Files | Where-Object TargetLanguage -eq 'fr-FR')
        $frenchFiles.Count | Should -BeGreaterOrEqual 1
        ($frenchFiles.Path | Where-Object { $_ -like '*Systemization.fr-FR.xlf' }).Count | Should -Be 1
    }
}
