BeforeAll {
    . (Join-Path $PSScriptRoot 'Shared\TestHelpers.ps1')
    Initialize-XliffParserTests
}

Describe 'Export-XliffFile' {
    It 'exports updated target text while preserving namespaces' {
        $output = Join-Path $TestDrive 'updated.xlf'
        $units = @(Import-XliffFile -Path $script:SamplePath)

        $units |
            Set-XliffTranslationUnit -Id 'Report 50000 - Label 1' -Target 'Solde du' -State translated -PassThru |
            Export-XliffFile -Path $output

        $updated = @(Import-XliffFile -Path $output)
        $unit = $updated | Where-Object Id -eq 'Report 50000 - Label 1'
        $xml = Import-XliffFile -Path $output -RawXml

        $unit.Target | Should -Be 'Solde du'
        $unit.State | Should -Be 'translated'
        $xml.DocumentElement.NamespaceURI | Should -Be 'urn:oasis:names:tc:xliff:document:1.2'
    }

    It 'round-trips all units from the Systemization translation file' {
        $output = Join-Path $TestDrive 'systemization-roundtrip.xlf'
        $units = @(Import-XliffFile -Path $script:TranslatedPath)

        $units | Export-XliffFile -Path $output
        $roundTrip = @(Import-XliffFile -Path $output)

        $roundTrip.Count | Should -Be 93
        $roundTrip.TargetLanguage | Select-Object -Unique | Should -Be 'fr-FR'
    }

    It 'returns the saved path when -PassThru is specified' {
        $output = Join-Path $TestDrive 'passthrough.xlf'
        $saved = Import-XliffFile -Path $script:SamplePath | Export-XliffFile -Path $output -PassThru

        $saved | Should -Be (Resolve-Path $output).Path
        Test-Path $saved | Should -Be $true
    }
}

Describe 'Export-XliffCsv and Export-XliffJson' {
    It 'writes CSV with the expected columns' {
        $csvPath = Join-Path $TestDrive 'sample.csv'
        Import-XliffFile -Path $script:SamplePath | Export-XliffCsv -Path $csvPath

        $rows = Import-Csv -Path $csvPath
        $rows.Count | Should -Be 3
        $propertyNames = ($rows | Get-Member -MemberType NoteProperty).Name
        foreach ($column in @('Id', 'Source', 'Target', 'State', 'Note')) {
            $propertyNames | Should -Contain $column
        }
    }

    It 'writes pretty JSON that can be read back' {
        $jsonPath = Join-Path $TestDrive 'sample.json'
        Import-XliffFile -Path $script:SamplePath | Export-XliffJson -Path $jsonPath

        $content = Get-Content -Path $jsonPath -Raw
        $content | Should -Match '"Id"'
        $content | Should -Match '"SourceLanguage"'
    }
}
