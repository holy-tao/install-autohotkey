function Get-AhkDownloadInfo() {
    param(
        [Parameter(Mandatory = $true)][string] $Version,
        [hashtable] $Headers = @{ 'User-Agent' = 'PowerShell/install-autohotkey' }
    )

    $baseUrl = 'https://www.autohotkey.com/download'

    # Normalize bare "latest" to branch-qualified form
    if ($Version -eq 'latest') {
        $Version = '2.0-latest'
    }

    # Handle "{major.minor}-latest" — resolve via version.txt
    if ($Version -match '^(\d+\.\d+)-latest$') {
        $branch = $Matches[1]
        Write-Host "Fetching latest AHK version for branch $branch..."
        $versionUrl = "$baseUrl/$branch/version.txt"
        Write-Host "  version.txt URL: $versionUrl"
        $Version = (Invoke-WebRequest -Uri $versionUrl -UseBasicParsing -Headers $Headers).Content.Trim()
        Write-Host "  Resolved to: $Version"
    } else {
        # Strip optional leading 'v'
        $Version = $Version.TrimStart('v')
    }

    # Derive branch (major.minor) from version string
    if ($Version -notmatch '^(\d+\.\d+)') {
        throw "Cannot determine download branch from version '$Version'. Expected a format like '2.0.19' or '2.1-alpha.23'."
    }
    $branch = $Matches[1]

    return @{
        Version = $Version
        Branch  = $branch
        Url     = "$baseUrl/$branch/AutoHotkey_$Version.zip"
    }
}
