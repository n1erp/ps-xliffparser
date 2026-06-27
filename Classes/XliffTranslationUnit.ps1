# XliffTranslationUnit represents one XLIFF 1.2 <trans-unit> entry.
#
# Public properties are safe to read, filter, and pass through the pipeline.
# Hidden properties (Path, XmlNode, XmlDocument) tie the object back to its source
# file and XML nodes so Export-XliffFile and Sync-XliffFile can round-trip changes
# without rebuilding the document from scratch.
#
# Objects returned by Import-XliffFile include hidden XML references.
# Objects returned by Import-XliffFile -Streaming are read-only snapshots and
# cannot be exported unless -TemplatePath is supplied to Export-XliffFile.
class XliffTranslationUnit {
    [string]$Id
    [string]$Source
    [string]$Target
    [string]$State
    [string]$Note
    [string]$SourceLanguage
    [string]$TargetLanguage

    hidden [string]$Path
    hidden [System.Xml.XmlNode]$XmlNode
    hidden [System.Xml.XmlDocument]$XmlDocument

    XliffTranslationUnit() {
    }

    XliffTranslationUnit(
        [string]$Id,
        [string]$Source,
        [string]$Target,
        [string]$State,
        [string]$Note,
        [string]$SourceLanguage,
        [string]$TargetLanguage
    ) {
        $this.Id = $Id
        $this.Source = $Source
        $this.Target = $Target
        $this.State = $State
        $this.Note = $Note
        $this.SourceLanguage = $SourceLanguage
        $this.TargetLanguage = $TargetLanguage
    }

    [string] ToString() {
        return $this.Id
    }
}
