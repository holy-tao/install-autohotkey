param(
    [string]$Version = "latest",
    [string]$Destination = ""
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Destination)) {
    $Destination = (Get-Item .).FullName
}

Write-Host "Installing AutoHotkey to: $Destination"

# Normalize v2.0.19 to 2.0.19 - allows both
$Version = $Version.TrimStart('v')

if ($Version -eq 'latest') {
    Write-Host "Fetching latest AutoHotkey v2 release info from GitHub..."
    $release = Invoke-RestMethod 'https://api.github.com/repos/AutoHotkey/AutoHotkey/releases/latest'
} else {
    Write-Host "Fetching AutoHotkey v$Version release info from GitHub..."
    $release = Invoke-RestMethod "https://api.github.com/repos/AutoHotkey/AutoHotkey/releases/tags/v$Version"
}

if (-not $release) {
    throw "Failed to fetch release info from GitHub."
}

# Find the ZIP asset
$asset = $release.assets | Where-Object { $_.name -match 'AutoHotkey_.*\.zip$' } | Select-Object -First 1

if (-not $asset) {
    throw "Could not find a valid .zip asset for release '$Version'."
}

$url = $asset.browser_download_url
$version = $release.tag_name.TrimStart('v')

Write-Host "Resolved AutoHotkey version: $version"
Write-Host "Download URL: $url"

# Prepare directories 
$zipPath = Join-Path $Destination 'autohotkey.zip'
$extractPath = Join-Path $Destination 'autohotkey'

# Download and extract
Invoke-WebRequest -Uri $url -OutFile $zipPath
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
Remove-Item -Path $zipPath -Force

# Export outputs
Write-Output "version=$version" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
Write-Output "ahk32=$(Join-Path $extractPath "AutoHotkey32.exe")" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
Write-Output "ahk64=$(Join-Path $extractPath "AutoHotkey64.exe")" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append

# Add to PATH (GitHub-style)
Write-Output ("$extractPath;" + "$extractPath\Compiler") | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append

Write-Host "✅ AutoHotkey v$version installed successfully to: $extractPath"