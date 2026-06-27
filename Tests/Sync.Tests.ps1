BeforeAll {
    . (Join-Path $PSScriptRoot 'Shared\TestHelpers.ps1')
    Initialize-XliffParserTests
}

Describe 'Sync-XliffFile' {
    It 'adds missing units, removes obsolete units, preserves target text, and marks changed sources' {
        $sourcePath = New-XliffTestFile -Name 'source.xlf' -Content (Get-XliffMinimalSyncSourceContent)
        $targetPath = New-XliffTestFile -Name 'target.xlf' -Content (Get-XliffMinimalSyncTargetContent)
        $outputPath = Join-Path $TestDrive 'synced.xlf'

        $report = Sync-XliffFile -SourcePath $sourcePath -TargetPath $targetPath -OutputPath $outputPath -RemoveObsolete -PassThru
        $units = @(Import-XliffFile -Path $outputPath)
        $one = $units | Where-Object Id -eq 'one'
        $two = $units | Where-Object Id -eq 'two'
        $obsolete = $units | Where-Object Id -eq 'obsolete'

        $report.AddedCount | Should -Be 1
        $report.RemovedCount | Should -Be 1
        $report.SourceChangedCount | Should -Be 1
        $one.Target | Should -Be 'Client'
        $one.Source | Should -Be 'Customer Name'
        $one.State | Should -Be 'needs-review'
        $two.State | Should -Be 'needs-translation'
        $obsolete | Should -BeNullOrEmpty
    }

    It 'preserves French translations when syncing Systemization.g.xlf into Systemization.fr-FR.xlf' {
        $outputPath = Join-Path $TestDrive 'systemization-synced.xlf'
        Copy-Item -Path $script:TranslatedPath -Destination (Join-Path $TestDrive 'systemization.fr-FR.xlf')
        $targetCopy = Join-Path $TestDrive 'systemization.fr-FR.xlf'

        $report = Sync-XliffFile -SourcePath $script:SourcePath -TargetPath $targetCopy -OutputPath $outputPath -PassThru
        $synced = @(Import-XliffFile -Path $outputPath)
        $original = @(Import-XliffFile -Path $script:TranslatedPath)

        $report.AddedCount | Should -Be 0
        $report.RemovedCount | Should -Be 0
        $report.SourceChangedCount | Should -Be 0
        $synced.Count | Should -Be 93

        $sampleId = 'Table 4120757582 - Property 2879900210'
        ($synced | Where-Object Id -eq $sampleId).Target |
            Should -Be ($original | Where-Object Id -eq $sampleId).Target
    }

    It 'adds new source units from Systemization.g.xlf without removing existing translations' {
        $outputPath = Join-Path $TestDrive 'systemization-with-new-unit.xlf'
        $modifiedSource = Join-Path $TestDrive 'systemization.g.modified.xlf'
        Copy-Item -Path $script:SourcePath -Destination $modifiedSource

        $document = Import-XliffFile -Path $modifiedSource -RawXml
        $namespaceManager = [System.Xml.XmlNamespaceManager]::new($document.NameTable)
        $namespaceManager.AddNamespace('xlf', $document.DocumentElement.NamespaceURI)
        $body = $document.SelectSingleNode('//xlf:file/xlf:body/xlf:group', $namespaceManager)
        $newUnit = $document.CreateElement('trans-unit', $document.DocumentElement.NamespaceURI)
        $newUnit.SetAttribute('id', 'New Unit - Test')
        $newUnit.SetAttribute('translate', 'yes')
        $source = $document.CreateElement('source', $document.DocumentElement.NamespaceURI)
        $source.InnerText = 'Brand New Caption'
        [void]$newUnit.AppendChild($source)
        [void]$body.AppendChild($newUnit)
        $document.Save($modifiedSource)

        Copy-Item -Path $script:TranslatedPath -Destination (Join-Path $TestDrive 'systemization.fr-FR.copy.xlf')
        $targetCopy = Join-Path $TestDrive 'systemization.fr-FR.copy.xlf'

        $report = Sync-XliffFile -SourcePath $modifiedSource -TargetPath $targetCopy -OutputPath $outputPath -PassThru
        $synced = @(Import-XliffFile -Path $outputPath)
        $newEntry = $synced | Where-Object Id -eq 'New Unit - Test'

        $report.AddedCount | Should -Be 1
        $synced.Count | Should -Be 94
        $newEntry.Source | Should -Be 'Brand New Caption'
        $newEntry.State | Should -Be 'needs-translation'
        $newEntry.Target | Should -Be ''
    }
}

Describe 'Compare-XliffFile' {
    It 'reports target differences between generated source and translated files' {
        $changes = @(Compare-XliffFile -ReferencePath $script:SourcePath -DifferencePath $script:TranslatedPath)

        ($changes | Where-Object ChangeType -eq 'TargetChanged').Count | Should -Be 93
        ($changes | Where-Object ChangeType -eq 'Added').Count | Should -Be 0
        ($changes | Where-Object ChangeType -eq 'Removed').Count | Should -Be 0
    }

    It 'detects source text changes in the minimal sync scenario' {
        $reference = New-XliffTestFile -Name 'compare-old.xlf' -Content (Get-XliffMinimalSyncTargetContent)
        $difference = New-XliffTestFile -Name 'compare-new.xlf' -Content (Get-XliffMinimalSyncSourceContent)

        $changes = @(Compare-XliffFile -ReferencePath $reference -DifferencePath $difference)
        ($changes | Where-Object { $_.Id -eq 'one' -and $_.ChangeType -eq 'SourceChanged' }).Count |
            Should -Be 1
    }
}
