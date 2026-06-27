# Shared Pester setup for the XliffParser module test suite.
# Dot-source from BeforeAll: . (Join-Path $PSScriptRoot 'Shared\TestHelpers.ps1')

function Initialize-XliffParserTests {
    [CmdletBinding()]
    param()

    $script:TestsRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleRoot = Split-Path $script:TestsRoot -Parent
    Import-Module (Join-Path $script:ModuleRoot 'XliffParser.psd1') -Force

    $script:FixtureRoot = Join-Path $script:TestsRoot 'Fixtures'
    $script:SamplePath = Join-Path $script:FixtureRoot 'Sample.xlf'
    $script:SourcePath = Join-Path $script:FixtureRoot 'Systemization.g.xlf'
    $script:TranslatedPath = Join-Path $script:FixtureRoot 'Systemization.fr-FR.xlf'
}

function New-XliffTestFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Content
    )

    $path = Join-Path $TestDrive $Name
    Set-Content -Path $path -Value $Content -Encoding utf8NoBOM
    return $path
}

function Get-XliffMinimalSyncSourceContent {
    return @'
<?xml version="1.0" encoding="UTF-8"?>
<xliff version="1.2" xmlns="urn:oasis:names:tc:xliff:document:1.2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:oasis:names:tc:xliff:document:1.2 xliff-core-1.2-transitional.xsd">
  <file datatype="xml" source-language="en-US" target-language="fr-FR" original="SyncTest">
    <body>
      <group>
        <trans-unit id="one" translate="yes"><source>Customer Name</source></trans-unit>
        <trans-unit id="two" translate="yes"><source>Posting Date</source></trans-unit>
      </group>
    </body>
  </file>
</xliff>
'@
}

function Get-XliffMinimalSyncTargetContent {
    return @'
<?xml version="1.0" encoding="UTF-8"?>
<xliff version="1.2" xmlns="urn:oasis:names:tc:xliff:document:1.2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:oasis:names:tc:xliff:document:1.2 xliff-core-1.2-transitional.xsd">
  <file datatype="xml" source-language="en-US" target-language="fr-FR" original="SyncTest">
    <body>
      <group>
        <trans-unit id="one" translate="yes"><source>Customer</source><target state="translated">Client</target></trans-unit>
        <trans-unit id="obsolete" translate="yes"><source>Obsolete</source><target state="translated">Obsolete</target></trans-unit>
      </group>
    </body>
  </file>
</xliff>
'@
}
