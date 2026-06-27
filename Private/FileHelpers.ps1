# Resolves a user-supplied path and throws when the file does not exist.
function Resolve-XliffPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$AllowMissing
    )

    $providerPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    if (-not $AllowMissing -and -not [System.IO.File]::Exists($providerPath)) {
        throw "XLIFF file '$Path' was not found."
    }

    return $providerPath
}

# Creates the parent directory for an output file when needed.
function Assert-XliffOutputDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $fullPath = Resolve-XliffPath -Path $Path -AllowMissing
    $directory = [System.IO.Path]::GetDirectoryName($fullPath)

    if ($directory -and -not [System.IO.Directory]::Exists($directory)) {
        [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    }

    return $fullPath
}

function Write-XliffUtf8File {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Content
    )

    $fullPath = Assert-XliffOutputDirectory -Path $Path
    $encoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($fullPath, $Content, $encoding)

    return $fullPath
}
