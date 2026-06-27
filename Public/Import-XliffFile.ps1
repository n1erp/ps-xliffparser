function Import-XliffFile {
<#
.SYNOPSIS
    Reads an XLIFF 1.2 file and returns translation units or raw XML.

.DESCRIPTION
    Loads one or more `.xlf` files using namespace-aware XML parsing. By default
    each `<trans-unit>` becomes an **XliffTranslationUnit** object that you can
    filter, update, validate, or export through the pipeline.

    Use this command as the entry point for almost every XliffParser workflow:

    - Inspect translations: `Import-XliffFile` -> `Get-XliffTranslationUnit`
    - Update targets:       `Import-XliffFile` -> `Set-XliffTranslationUnit` -> `Export-XliffFile`
    - Review completeness:  `Import-XliffFile` -> `Get-XliffStatistics`
    - Low-memory scans:     `Import-XliffFile -Streaming`

    Returned objects preserve hidden references to the backing **XmlDocument**
    and `<trans-unit>` node so later export/sync operations can modify the
    original file structure instead of generating XML from scratch.

.PARAMETER Path
    Path to one or more `.xlf` files. Accepts pipeline input by path or objects
    with a **FullName** property (for example `Get-ChildItem` output).

.PARAMETER RawXml
    Returns the preserved **System.Xml.XmlDocument** instead of translation unit
    objects. Use this when you need direct XML access while still validating that
    the file is XLIFF 1.2.

.PARAMETER Streaming
    Streams translation units through **XmlReader** for lower memory use on large
    Business Central `.g.xlf` files. Streaming objects are read-only snapshots:
    they do **not** include **XmlNode**/**XmlDocument** references and cannot be
    round-tripped with `Export-XliffFile` unless you also supply `-TemplatePath`.

.OUTPUTS
    [XliffTranslationUnit[]]
        Default output. One object per `<trans-unit>`.

    [System.Xml.XmlDocument]
        When `-RawXml` is specified.

.EXAMPLE
    Import-XliffFile .\Translations\Systemization.fr-FR.xlf

    Loads all translation units from a language file.

.EXAMPLE
    Get-ChildItem .\Translations -Filter '*.xlf' | Import-XliffFile

    Imports every XLIFF file discovered in a folder.

.EXAMPLE
    Import-XliffFile .\Translations\Systemization.g.xlf -Streaming |
        Where-Object Source -like '*Caption*'

    Streams a large generated source file and filters in memory.

.EXAMPLE
    $xml = Import-XliffFile .\Translations\Systemization.g.xlf -RawXml
    $xml.DocumentElement.NamespaceURI

    Returns the namespace-aware XML document for advanced scenarios.

.NOTES
    Author: XliffParser Contributors

    Only XLIFF 1.2 is supported. Files are loaded with **PreserveWhitespace**
    enabled so export keeps formatting as close to the source as possible.
#>
    [CmdletBinding(DefaultParameterSetName = 'Units')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,

        [Parameter(ParameterSetName = 'Raw')]
        [switch]$RawXml,

        [Parameter(ParameterSetName = 'Streaming')]
        [switch]$Streaming
    )

    process {
        foreach ($item in $Path) {
            $resolvedPath = Resolve-XliffPath -Path $item
            Write-Verbose "Importing XLIFF file '$resolvedPath'."

            if ($Streaming) {
                Get-XliffStreamingTranslationUnits -Path $resolvedPath
                continue
            }

            $document = Read-XliffXmlDocument -Path $resolvedPath
            if ($RawXml) {
                $document
                continue
            }

            Get-XliffTranslationUnitsFromDocument -Document $document -Path $resolvedPath
        }
    }
}