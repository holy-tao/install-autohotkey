function Resolve-AhkVersion() {
    param(
        [Parameter(Mandatory = $true)][string] $Version,
        [hashtable] $Headers = @{}
    )

    # Normalize bare "latest" to branch-qualified form
    if ($Version -eq 'latest') {
        $Version = '2.0-latest'
    }

    # Handle "{major.minor}-latest"
    if ($Version -match '^(\d+\.\d+)-latest$') {
        $branch = $Matches[1]
        if ($branch -match '^(\d+)\.(\d+)$') {
            $major = [int]$Matches[1]
            $minor = [int]$Matches[2]
        }

        if ($major -ge 2 -and $minor -ge 1) {
            # 2.1+ alpha — resolve via GitHub tags API
            Write-Host "Fetching latest AHK tag for branch $branch..."
            $Version = Get-LatestAhkAlphaTag -Branch $branch -Headers $Headers
            Write-Host "Resolved to: $Version"
        } else {
            # 2.0 and earlier — use GitHub releases "latest"
            return @{ Version = ''; Major = $major; Minor = $minor }
        }
    } else {
        $Version = $Version.TrimStart('v')
    }

    # Extract major.minor from the resolved version
    if ($Version -notmatch '^(\d+)\.(\d+)') {
        throw "Cannot parse version '$Version'. Expected a format like '2.0.19' or '2.1-alpha.23'."
    }
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]

    return @{ Version = $Version; Major = $major; Minor = $minor }
}

function Get-LatestAhkAlphaTag() {
    param(
        [Parameter(Mandatory = $true)][string] $Branch,
        [hashtable] $Headers = @{}
    )

    $tags = Invoke-RestMethod "https://api.github.com/repos/AutoHotkey/AutoHotkey/tags?per_page=100" -Headers $Headers

    $pattern = "^v$([regex]::Escape($Branch))-alpha\.(\d+)$"
    $best = $tags |
        Where-Object { $_.name -match $pattern } |
        ForEach-Object { [PSCustomObject]@{ Name = $_.name; N = [int]([regex]::Match($_.name, $pattern).Groups[1].Value) } } |
        Sort-Object N -Descending |
        Select-Object -First 1

    if (-not $best) {
        throw "No alpha tags found for branch '$Branch' in AutoHotkey/AutoHotkey."
    }

    return $best.Name.TrimStart('v')
}

function Build-AhkFromSource() {
    param(
        [Parameter(Mandatory = $true)][string] $Version,
        [Parameter(Mandatory = $true)][string] $Destination,
        [string] $CacheDir = "",
        [switch] $ForceBuild
    )

    $cacheable = -not [string]::IsNullOrWhiteSpace($CacheDir)
    $cached32 = if ($cacheable) { Join-Path $CacheDir 'AutoHotkey32.exe' } else { $null }
    $cached64 = if ($cacheable) { Join-Path $CacheDir 'AutoHotkey64.exe' } else { $null }

    # Use the cached build when present, unless the caller forced a rebuild. The cache is
    # populated by actions/cache (keyed on the resolved version) before this step runs.
    if ($cacheable -and -not $ForceBuild -and (Test-Path $cached32) -and (Test-Path $cached64)) {
        Write-Host "Using cached AutoHotkey $Version build from: $CacheDir"
        New-Item -ItemType Directory -Force -Path $Destination | Out-Null
        Copy-Item $cached32 "$Destination\AutoHotkey32.exe" -Force
        Copy-Item $cached64 "$Destination\AutoHotkey64.exe" -Force
        Write-Host "✅ AutoHotkey $Version restored from cache to: $Destination"
        return $Version
    }

    if ($ForceBuild) {
        Write-Host "ForceBuild requested — ignoring any cached build."
    }

    Write-Host "Building AutoHotkey $Version from source..."

    # Locate MSBuild via vswhere
    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vsWhere)) {
        throw "vswhere.exe not found at '$vsWhere'. Visual Studio Build Tools 2022 are required."
    }
    $msbuild = & $vsWhere -latest -requires Microsoft.Component.MSBuild -find "MSBuild\**\Bin\MSBuild.exe" |
        Select-Object -First 1
    if (-not $msbuild) {
        throw "MSBuild not found via vswhere. Install 'Desktop development with C++' workload."
    }
    Write-Host "MSBuild: $msbuild"

    $tempDir = Join-Path $env:RUNNER_TEMP "ahk-src-$Version"

    try {
        # Shallow clone at the specific tag
        Write-Host "Cloning AutoHotkey/AutoHotkey at tag v$Version..."
        git clone --depth 1 --branch "v$Version" https://github.com/AutoHotkey/AutoHotkey $tempDir | Out-Host
        if ($LASTEXITCODE -ne 0) {
            throw "git clone failed with exit code $LASTEXITCODE."
        }

        Push-Location $tempDir
        try {
            # Build both architectures
            foreach ($platform in @('Win32', 'x64')) {
                Write-Host "Building Release|$platform..."
                & $msbuild AutoHotkeyx.sln /p:Configuration=Release /p:Platform=$platform /nologo /verbosity:minimal /m | Out-Host
                if ($LASTEXITCODE -ne 0) {
                    throw "MSBuild failed for Release|$platform (exit code $LASTEXITCODE)."
                }
            }
        } finally {
            Pop-Location
        }

        # Copy outputs to destination
        New-Item -ItemType Directory -Force -Path $Destination | Out-Null
        Copy-Item "$tempDir\bin\AutoHotkey32.exe" "$Destination\AutoHotkey32.exe" -Force
        Copy-Item "$tempDir\bin\AutoHotkey64.exe" "$Destination\AutoHotkey64.exe" -Force

        # Populate the cache dir so actions/cache can persist this build for the next run.
        # Skipped on ForceBuild, where the cache step is disabled and nothing would be saved.
        if ($cacheable -and -not $ForceBuild) {
            New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
            Copy-Item "$tempDir\bin\AutoHotkey32.exe" $cached32 -Force
            Copy-Item "$tempDir\bin\AutoHotkey64.exe" $cached64 -Force
            Write-Host "Cached AutoHotkey $Version build to: $CacheDir"
        }

    } finally {
        if (Test-Path $tempDir) {
            Remove-Item -Recurse -Force $tempDir
        }
    }

    Write-Host "✅ AutoHotkey $Version built successfully to: $Destination"
    return $Version
}
