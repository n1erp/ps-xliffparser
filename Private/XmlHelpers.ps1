# Loads an XLIFF file into an XmlDocument with whitespace preserved for round-tripping.
function Read-XliffXmlDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $resolvedPath = Resolve-XliffPath -Path $Path
    $document = [System.Xml.XmlDocument]::new()
    $document.PreserveWhitespace = $true

    $settings = [System.Xml.XmlReaderSettings]::new()
    $settings.DtdProcessing = [System.Xml.DtdProcessing]::Prohibit
    $settings.IgnoreWhitespace = $false
    $settings.XmlResolver = $null

    $stream = [System.IO.File]::OpenRead($resolvedPath)
    try {
        $reader = [System.Xml.XmlReader]::Create($stream, $settings)
        try {
            $document.Load($reader)
        } finally {
            $reader.Close()
        }
    } finally {
        $stream.Dispose()
    }

    Assert-XliffDocument -Document $document -Path $resolvedPath
    return $document
}

# Saves an XmlDocument as UTF-8 without BOM and without altering line endings.
function Save-XliffXmlDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlDocument]$Document,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $fullPath = Assert-XliffOutputDirectory -Path $Path
    $settings = [System.Xml.XmlWriterSettings]::new()
    $settings.Encoding = [System.Text.UTF8Encoding]::new($false)
    $settings.Indent = $false
    $settings.NewLineHandling = [System.Xml.NewLineHandling]::None

    $writer = [System.Xml.XmlWriter]::Create($fullPath, $settings)
    try {
        $Document.Save($writer)
    } finally {
        $writer.Close()
    }

    return $fullPath
}

# Verifies that the document root is <xliff version="1.2">.
function Assert-XliffDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlDocument]$Document,

        [string]$Path = '<memory>'
    )

    if (-not $Document.DocumentElement -or $Document.DocumentElement.LocalName -ne 'xliff') {
        throw "'$Path' is not an XLIFF document."
    }

    $version = Get-XliffAttributeValue -Node $Document.DocumentElement -Name 'version'
    if ($version -ne '1.2') {
        throw "'$Path' uses XLIFF version '$version'. XliffParser currently supports XLIFF 1.2."
    }
}

function Select-XliffNodes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlNode]$Node,

        [Parameter(Mandatory)]
        [string]$XPath,

        [Parameter(Mandatory)]
        [System.Xml.XmlNamespaceManager]$NamespaceManager
    )

    return $Node.SelectNodes($XPath, $NamespaceManager)
}

function Select-XliffSingleNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlNode]$Node,

        [Parameter(Mandatory)]
        [string]$XPath,

        [Parameter(Mandatory)]
        [System.Xml.XmlNamespaceManager]$NamespaceManager
    )

    return $Node.SelectSingleNode($XPath, $NamespaceManager)
}

function Get-XliffFileNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlNode]$Node
    )

    $current = $Node
    while ($current) {
        if ($current.LocalName -eq 'file') {
            return $current
        }

        $current = $current.ParentNode
    }

    return $null
}

function Get-XliffTranslationUnitNodes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlDocument]$Document
    )

    $namespaceManager = New-XliffNamespaceManager -Document $Document
    return Select-XliffNodes -Node $Document -XPath '//xlf:trans-unit' -NamespaceManager $namespaceManager
}

function Get-XliffChildElement {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlNode]$Node,

        [Parameter(Mandatory)]
        [string]$LocalName
    )

    foreach ($child in $Node.ChildNodes) {
        if ($child.NodeType -eq [System.Xml.XmlNodeType]::Element -and $child.LocalName -eq $LocalName) {
            return $child
        }
    }

    return $null
}

function Get-XliffElementText {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [System.Xml.XmlNode]$Node
    )

    if (-not $Node) {
        return $null
    }

    return $Node.InnerText
}

function Ensure-XliffChildElement {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlElement]$Parent,

        [Parameter(Mandatory)]
        [string]$LocalName
    )

    $existing = Get-XliffChildElement -Node $Parent -LocalName $LocalName
    if ($existing) {
        return [System.Xml.XmlElement]$existing
    }

    $namespaceUri = $Parent.NamespaceURI
    $element = $Parent.OwnerDocument.CreateElement($Parent.Prefix, $LocalName, $namespaceUri)

    if ($LocalName -eq 'target') {
        $source = Get-XliffChildElement -Node $Parent -LocalName 'source'
        if ($source -and $source.NextSibling) {
            [void]$Parent.InsertAfter($element, $source)
            return $element
        }

        if ($source) {
            [void]$Parent.AppendChild($element)
            return $element
        }
    }

    [void]$Parent.AppendChild($element)
    return $element
}

function Set-XliffUnitTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlElement]$UnitNode,

        [AllowNull()]
        [string]$Target
    )

    $targetNode = Ensure-XliffChildElement -Parent $UnitNode -LocalName 'target'
    $targetNode.InnerText = if ($null -eq $Target) { '' } else { $Target }
    return $targetNode
}

function Set-XliffUnitState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlElement]$UnitNode,

        [AllowNull()]
        [string]$State
    )

    $targetNode = Ensure-XliffChildElement -Parent $UnitNode -LocalName 'target'
    if ([string]::IsNullOrWhiteSpace($State)) {
        $targetNode.RemoveAttribute('state')
    } else {
        $targetNode.SetAttribute('state', $State)
    }
}

# Converts a <trans-unit> XML node into an XliffTranslationUnit with hidden XML references.
function ConvertTo-XliffTranslationUnit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlElement]$UnitNode,

        [Parameter(Mandatory)]
        [System.Xml.XmlDocument]$Document,

        [string]$Path
    )

    $fileNode = Get-XliffFileNode -Node $UnitNode
    $sourceNode = Get-XliffChildElement -Node $UnitNode -LocalName 'source'
    $targetNode = Get-XliffChildElement -Node $UnitNode -LocalName 'target'
    $noteNodes = @($UnitNode.ChildNodes | Where-Object {
            $_.NodeType -eq [System.Xml.XmlNodeType]::Element -and $_.LocalName -eq 'note'
        })

    $developerNote = $noteNodes | Where-Object {
        (Get-XliffAttributeValue -Node $_ -Name 'from') -eq 'Developer'
    } | Select-Object -First 1

    $note = if ($developerNote) {
        $developerNote.InnerText
    } elseif ($noteNodes.Count -gt 0) {
        ($noteNodes | ForEach-Object { $_.InnerText }) -join '; '
    } else {
        $null
    }

    $unit = [XliffTranslationUnit]::new(
        (Get-XliffAttributeValue -Node $UnitNode -Name 'id'),
        (Get-XliffElementText -Node $sourceNode),
        (Get-XliffElementText -Node $targetNode),
        (Get-XliffAttributeValue -Node $targetNode -Name 'state'),
        $note,
        (Get-XliffAttributeValue -Node $fileNode -Name 'source-language'),
        (Get-XliffAttributeValue -Node $fileNode -Name 'target-language')
    )

    $unit.Path = $Path
    $unit.XmlNode = $UnitNode
    $unit.XmlDocument = $Document

    return $unit
}

function Get-XliffTranslationUnitsFromDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlDocument]$Document,

        [string]$Path
    )

    foreach ($node in Get-XliffTranslationUnitNodes -Document $Document) {
        ConvertTo-XliffTranslationUnit -UnitNode ([System.Xml.XmlElement]$node) -Document $Document -Path $Path
    }
}

function Get-XliffStreamingTranslationUnits {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $resolvedPath = Resolve-XliffPath -Path $Path
    $settings = [System.Xml.XmlReaderSettings]::new()
    $settings.DtdProcessing = [System.Xml.DtdProcessing]::Prohibit
    $settings.IgnoreWhitespace = $false
    $settings.XmlResolver = $null

    $sourceLanguage = $null
    $targetLanguage = $null
    $stream = [System.IO.File]::OpenRead($resolvedPath)
    try {
        $reader = [System.Xml.XmlReader]::Create($stream, $settings)
        try {
            while ($reader.Read()) {
                if ($reader.NodeType -eq [System.Xml.XmlNodeType]::Element -and $reader.LocalName -eq 'file') {
                    $sourceLanguage = $reader.GetAttribute('source-language')
                    $targetLanguage = $reader.GetAttribute('target-language')
                }

                if ($reader.NodeType -eq [System.Xml.XmlNodeType]::Element -and $reader.LocalName -eq 'trans-unit') {
                    $unitDocument = [System.Xml.XmlDocument]::new()
                    $unitDocument.PreserveWhitespace = $true
                    $unitNode = [System.Xml.XmlElement]$unitDocument.ReadNode($reader)
                    if ($unitNode) {
                        $sourceNode = Get-XliffChildElement -Node $unitNode -LocalName 'source'
                        $targetNode = Get-XliffChildElement -Node $unitNode -LocalName 'target'
                        $noteNode = Get-XliffChildElement -Node $unitNode -LocalName 'note'
                        [XliffTranslationUnit]::new(
                            (Get-XliffAttributeValue -Node $unitNode -Name 'id'),
                            (Get-XliffElementText -Node $sourceNode),
                            (Get-XliffElementText -Node $targetNode),
                            (Get-XliffAttributeValue -Node $targetNode -Name 'state'),
                            (Get-XliffElementText -Node $noteNode),
                            $sourceLanguage,
                            $targetLanguage
                        )
                    }
                }
            }
        } finally {
            $reader.Close()
        }
    } finally {
        $stream.Dispose()
    }
}

# Builds a hashtable keyed by translation unit Id for fast sync/compare lookups.
function Get-XliffUnitMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [XliffTranslationUnit[]]$InputObject
    )

    begin {
        $map = @{}
    }

    process {
        foreach ($unit in $InputObject) {
            if ($unit.Id -and -not $map.ContainsKey($unit.Id)) {
                $map[$unit.Id] = $unit
            }
        }
    }

    end {
        return $map
    }
}

function Get-XliffInsertionParent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlDocument]$Document
    )

    $namespaceManager = New-XliffNamespaceManager -Document $Document
    $group = Select-XliffSingleNode -Node $Document -XPath '//xlf:file/xlf:body//xlf:group[1]' -NamespaceManager $namespaceManager
    if ($group) {
        return $group
    }

    $body = Select-XliffSingleNode -Node $Document -XPath '//xlf:file/xlf:body' -NamespaceManager $namespaceManager
    if ($body) {
        return $body
    }

    throw 'No XLIFF body element was found.'
}

# Clones a source <trans-unit> into a target document during Sync-XliffFile.
function Import-XliffUnitNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlElement]$SourceUnitNode,

        [Parameter(Mandatory)]
        [System.Xml.XmlDocument]$TargetDocument,

        [string]$InitialTarget = '',

        [string]$InitialState = 'needs-translation'
    )

    $imported = [System.Xml.XmlElement]$TargetDocument.ImportNode($SourceUnitNode, $true)
    [void](Set-XliffUnitTarget -UnitNode $imported -Target $InitialTarget)
    Set-XliffUnitState -UnitNode $imported -State $InitialState

    $parent = Get-XliffInsertionParent -Document $TargetDocument
    [void]$parent.AppendChild($imported)

    return $imported
}

function Remove-XliffUnitNode {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlNode]$UnitNode
    )

    if ($UnitNode.ParentNode) {
        [void]$UnitNode.ParentNode.RemoveChild($UnitNode)
    }
}
