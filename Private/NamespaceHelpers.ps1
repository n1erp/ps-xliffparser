function Get-XliffNamespaceUri {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlDocument]$Document
    )

    if ($Document.DocumentElement -and $Document.DocumentElement.NamespaceURI) {
        return $Document.DocumentElement.NamespaceURI
    }

    return 'urn:oasis:names:tc:xliff:document:1.2'
}

# Registers the default XLIFF namespace prefixes used by XPath helpers.
function New-XliffNamespaceManager {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlDocument]$Document
    )

    $namespaceManager = [System.Xml.XmlNamespaceManager]::new($Document.NameTable)
    $xliffNamespace = Get-XliffNamespaceUri -Document $Document

    $namespaceManager.AddNamespace('xlf', $xliffNamespace)
    $namespaceManager.AddNamespace('xliff', $xliffNamespace)
    $namespaceManager.AddNamespace('xsi', 'http://www.w3.org/2001/XMLSchema-instance')

    return ,$namespaceManager
}

function Get-XliffAttributeValue {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [System.Xml.XmlNode]$Node,

        [Parameter(Mandatory)]
        [string]$Name,

        [string]$NamespaceUri
    )

    if (-not $Node -or -not $Node.Attributes) {
        return $null
    }

    $attribute = if ($NamespaceUri) {
        $Node.Attributes.GetNamedItem($Name, $NamespaceUri)
    } else {
        $Node.Attributes.GetNamedItem($Name)
    }

    if ($attribute) {
        return $attribute.Value
    }

    return $null
}

function Set-XliffAttributeValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlElement]$Element,

        [Parameter(Mandatory)]
        [string]$Name,

        [AllowNull()]
        [string]$Value,

        [string]$NamespaceUri
    )

    if ($NamespaceUri) {
        $Element.SetAttribute($Name, $NamespaceUri, $Value)
    } else {
        $Element.SetAttribute($Name, $Value)
    }
}
