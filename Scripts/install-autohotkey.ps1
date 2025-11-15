param(
    [string] $Version = "latest",
    [string] $Destination = "",
    [string] $Compiler = ""
)

function Install-Item(){
    param(
        [Parameter(Mandatory = $true)][string] $RepoSlug,
        [Parameter(Mandatory = $true)][string] $AssetMatch,
        [Parameter(Mandatory = $true)][string] $Version,
        [Parameter(Mandatory = $true)][string] $Destination
    )

    $FriendlyName = $RepoSlug.Split("/") | Select-Object -Last 1

    Write-Host "Installing $FriendlyName to: $Destination"

    $release = Get-GitHubRelease -RepoSlug $RepoSlug -Version $Version -FriendlyName $FriendlyName
    $version = $release.tag_name.TrimStart('v')
    Write-Host "Resolved $FriendlyName version: $version"

    $asset = Get-ReleaseAsset -Release $release -Match $AssetMatch

    $url = $asset.browser_download_url

    Write-Host "Download URL: $url"

    $zipPath = Join-Path $PSScriptRoot "$FriendlyName.zip"

    Invoke-WebRequest -Uri $url -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath $Destination -Force
    Remove-Item -Path $zipPath -Force

    Write-Host "✅ $FriendlyName v$version installed successfully to: $extractPath"
}

$ErrorActionPreference = 'Stop'

Import-Module -Name "$PSScriptRoot\Modules\github-utils.psm1" -Force

if ([string]::IsNullOrWhiteSpace($Destination)) {
    $Destination = (Get-Item .).FullName
}

$extractPath = Join-Path $Destination 'autohotkey'
Install-Item -RepoSlug "AutoHotkey/AutoHotkey" -AssetMatch 'AutoHotkey_.*\.zip$' -Version $Version -Destination $extractPath

# Install compiler if asked
if (-not [string]::IsNullOrWhiteSpace($Destination)) {
    $compilerExtractPath = Join-Path $extractPath 'Compiler'
    Install-item -RepoSlug "AutoHotkey/Ahk2Exe" -AssetMatch 'Ahk2Exe.*\.zip$' -Version $Compiler -Destination $compilerExtractPath
}

# Export outputs
Write-Output "version=$version" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
Write-Output "ahk32=$(Join-Path $extractPath "AutoHotkey32.exe")" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
Write-Output "ahk64=$(Join-Path $extractPath "AutoHotkey64.exe")" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
if (-not [string]::IsNullOrWhiteSpace($Destination)){
    Write-Output "ahk2Exe=$(Join-Path $extractPath "Compiler" "Ahk2Exe.exe")" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append

}

# Add to PATH (GitHub-style)
Write-Output ("$extractPath;" + "$extractPath\Compiler") | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append