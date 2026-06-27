# Returns the XLIFF 1.2 target states accepted by validation commands.
function Get-XliffValidState {
    [CmdletBinding()]
    param()

    return @(
        'final'
        'new'
        'needs-adaptation'
        'needs-l10n'
        'needs-review'
        'needs-review-adaptation'
        'needs-review-l10n'
        'needs-review-translation'
        'needs-translation'
        'signed-off'
        'translated'
    )
}

function Test-XliffTargetMissing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [XliffTranslationUnit]$Unit
    )

    return [string]::IsNullOrWhiteSpace($Unit.Target)
}

function Test-XliffStateInvalid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [XliffTranslationUnit]$Unit
    )

    if ([string]::IsNullOrWhiteSpace($Unit.State)) {
        return $false
    }

    return (Get-XliffValidState) -notcontains $Unit.State
}

function New-XliffValidationResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Rule,

        [Parameter(Mandatory)]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Severity,

        [string]$Id,

        [string]$Message,

        [string]$Path
    )

    [pscustomobject]@{
        PSTypeName = 'XliffParser.ValidationResult'
        Rule       = $Rule
        Severity   = $Severity
        Id         = $Id
        Message    = $Message
        Path       = $Path
    }
}
