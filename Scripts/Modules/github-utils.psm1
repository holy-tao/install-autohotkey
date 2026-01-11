function Get-GitHubRelease() {
    param(
        [Parameter(Mandatory = $true)] [string] $RepoSlug,
        [Parameter(Mandatory = $true)] [string] $Version,
        [Parameter(Mandatory = $true)] [string] $FriendlyName
    )

    $headers = Get-GitHubApiRequestHeaders

    if ($Version -eq 'latest') {
        Write-Host "Fetching latest $FriendlyName release info from GitHub..."
        $release = Invoke-RestMethod "https://api.github.com/repos/$RepoSlug/releases/latest" -Headers $headers
    } else {
        Write-Host "Fetching $FriendlyName $Version release info from GitHub..."
        $release = Invoke-RestMethod "https://api.github.com/repos/$RepoSlug/releases/tags/$Version" -Headers $headers
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

function Get-GitHubApiRequestHeaders() {
    # Build headers for authenticated requests
    $headers = @{
        'Accept'              = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
    }

    if ($env:GITHUB_TOKEN) {
        $headers['Authorization'] = "Bearer $env:GITHUB_TOKEN"
    } else {
        Write-Warning "GITHUB_TOKEN not set - using unauthenticated requests (rate limited to 60/hour)"
    }

    return $headers
}