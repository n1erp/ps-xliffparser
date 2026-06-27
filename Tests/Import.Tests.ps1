BeforeAll {
    . (Join-Path $PSScriptRoot 'Shared\TestHelpers.ps1')
    Initialize-XliffParserTests
}

Describe 'Import-XliffFile' {
    It 'loads translation units from a Business Central-style XLIFF 1.2 file' {
        $units = @(Import-XliffFile -Path $script:SourcePath)

        $units.Count | Should -Be 93
        $units[0].SourceLanguage | Should -Be 'en-US'
        $units[0].TargetLanguage | Should -Be 'en-US'
        $units[0].Id | Should -Not -BeNullOrEmpty
        $units[0].Source | Should -Not -BeNullOrEmpty
    }

    It 'loads translated units with target text and language metadata' {
        $units = @(Import-XliffFile -Path $script:TranslatedPath)
        $first = $units | Where-Object Id -eq 'Table 4120757582 - Property 2879900210' | Select-Object -First 1

        $units.Count | Should -Be 93
        $first.TargetLanguage | Should -Be 'fr-FR'
        $first.Target | Should -Be 'Extension de la systématisation'
    }

    It 'imports the small Sample fixture with expected states' {
        $units = @(Import-XliffFile -Path $script:SamplePath)

        $units.Count | Should -Be 3
        ($units | Where-Object State -eq 'translated').Count | Should -Be 1
        ($units | Where-Object State -eq 'needs-translation').Count | Should -Be 1
        ($units | Where-Object State -eq 'needs-review').Count | Should -Be 1
    }

    It 'returns preserved raw XML with namespace and schema metadata' {
        $xml = Import-XliffFile -Path $script:SamplePath -RawXml

        $xml.DocumentElement.NamespaceURI | Should -Be 'urn:oasis:names:tc:xliff:document:1.2'
        $xml.DocumentElement.GetAttribute('schemaLocation', 'http://www.w3.org/2001/XMLSchema-instance') |
            Should -Match 'xliff-core-1.2-transitional.xsd'
    }

    It 'streams translation units without backing XML nodes' {
        $units = @(Import-XliffFile -Path $script:SamplePath -Streaming)

        $units.Count | Should -Be 3
        $units[0].XmlNode | Should -BeNullOrEmpty
        $units[0].XmlDocument | Should -BeNullOrEmpty
    }

    It 'accepts pipeline input by path' {
        $units = @($script:SamplePath | Import-XliffFile)

        $units.Count | Should -Be 3
    }
}
