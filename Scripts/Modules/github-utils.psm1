function Get-GitHubRelease() {
    param(
        [Parameter(Mandatory = $true)] [string] $RepoSlug,
        [Parameter(Mandatory = $true)] [string] $Version,
        [Parameter(Mandatory = $true)] [string] $FriendlyName
    )

    $Version = $Version.TrimStart('v')

    if ($Version -eq 'latest') {
        Write-Host "Fetching latest $FriendlyName v2 release info from GitHub..."
        $release = Invoke-RestMethod "https://api.github.com/repos/$RepoSlug/releases/latest"
    } else {
        Write-Host "Fetching $FriendlyName v$Version release info from GitHub..."
        $release = Invoke-RestMethod "https://api.github.com/repos/$RepoSlug/releases/tags/v$Version"
    }

    if (-not $release) {
        throw "Failed to fetch $FriendlyName release info from GitHub."
    }

    return $release
}

function Get-ReleaseAsset() {
    param(
        [Parameter(Mandatory = $true)] $Release,
        [Parameter(Mandatory = $true)] [string] $Match
    )

    $asset = $Release.assets | Where-Object { $_.name -match $Match } | Select-Object -First 1

    if (-not $asset) {
        throw "Could not find a valid .zip asset for release '$($Release.tag_name.TrimStart('v'))'."
    }

    return $asset
}