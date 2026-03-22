param(
    [string] $Version = "latest",
    [string] $Destination = "",
    [string] $Compiler = ""
)

function Install-AhkFromDownloadsPage() {
    param(
        [Parameter(Mandatory = $true)][string] $Version,
        [Parameter(Mandatory = $true)][string] $Destination
    )

    Write-Host "Installing AutoHotkey to: $Destination"

    $headers = @{ 'User-Agent' = 'PowerShell/install-autohotkey' }  # used for diagnostic HEAD check only

    $info = Get-AhkDownloadInfo -Version $Version
    $resolvedVersion = $info.Version
    $url = $info.Url

    Write-Host "Resolved AutoHotkey version: $resolvedVersion"
    Write-Host "Download URL: $url"

    # Diagnostic: show what .NET/PowerShell gets (likely a Cloudflare challenge page on CI runners)
    Write-Host "HEAD check via Invoke-WebRequest (diagnostic): $url"
    try {
        $head = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing -Headers $headers
        Write-Host "  Status: $($head.StatusCode) $($head.StatusDescription)"
    } catch {
        Write-Warning "  HEAD failed: $($_.Exception.Message)"
        if ($_.Exception.Response) {
            Write-Warning "  HTTP status: $([int]$_.Exception.Response.StatusCode) (likely Cloudflare bot challenge)"
        }
    }

    # Use curl.exe for the actual download — its TLS fingerprint bypasses Cloudflare's bot detection
    Write-Host "Downloading via curl.exe: $url"
    $zipPath = Join-Path $PSScriptRoot "AutoHotkey.zip"

    Invoke-CurlDownload -Uri $url -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath $Destination -Force
    Remove-Item -Path $zipPath -Force

    Write-Host "✅ AutoHotkey $resolvedVersion installed successfully to: $Destination"

    return $resolvedVersion
}

function Install-CompilerFromGitHub() {
    param(
        [Parameter(Mandatory = $true)][string] $Version,
        [Parameter(Mandatory = $true)][string] $Destination
    )

    $FriendlyName = "Ahk2Exe"

    Write-Host "Installing $FriendlyName to: $Destination"

    $release = Get-GitHubRelease -RepoSlug "AutoHotkey/Ahk2Exe" -Version $Version -FriendlyName $FriendlyName
    $resolvedVersion = $release.tag_name.TrimStart('v')
    Write-Host "Resolved $FriendlyName version: $resolvedVersion"

    $asset = Get-ReleaseAsset -Release $release -Match 'Ahk2Exe.*\.zip$'

    $url = $asset.browser_download_url
    Write-Host "Download URL: $url"

    $zipPath = Join-Path $PSScriptRoot "$FriendlyName.zip"

    Invoke-WebRequest -Uri $url -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath $Destination -Force
    Remove-Item -Path $zipPath -Force

    Write-Host "✅ $FriendlyName $resolvedVersion installed successfully to: $Destination"
}

$ErrorActionPreference = 'Stop'

Import-Module -Name "$PSScriptRoot\Modules\github-utils.psm1" -Force
Import-Module -Name "$PSScriptRoot\Modules\ahk-utils.psm1" -Force

# Diagnostics — helps identify connectivity/TLS issues on GitHub runners
Write-Host "=== Diagnostics ==="
Write-Host "PowerShell: $($PSVersionTable.PSVersion)  OS: $($PSVersionTable.OS)"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Host "TLS forced to: $([Net.ServicePointManager]::SecurityProtocol)"
Write-Host "==="

if ([string]::IsNullOrWhiteSpace($Destination)) {
    $Destination = (Get-Item .).FullName
}

$extractPath = Join-Path $Destination 'autohotkey'
$installedVersion = Install-AhkFromDownloadsPage -Version $Version -Destination $extractPath

# Install compiler if asked (still sourced from GitHub releases)
if (-not [string]::IsNullOrWhiteSpace($Compiler)) {
    $compilerExtractPath = Join-Path $extractPath 'Compiler'
    Install-CompilerFromGitHub -Version $Compiler -Destination $compilerExtractPath
}

# Export outputs
Write-Output "version=$installedVersion" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
Write-Output "ahk32=$(Join-Path $extractPath "AutoHotkey32.exe")" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
Write-Output "ahk64=$(Join-Path $extractPath "AutoHotkey64.exe")" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
if (-not [string]::IsNullOrWhiteSpace($Compiler)){
    Write-Output "ahk2Exe=$(Join-Path $extractPath "Compiler" "Ahk2Exe.exe")" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
}

# Add to PATH (GitHub-style)
Write-Output ("$extractPath;" + "$extractPath\Compiler") | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append
