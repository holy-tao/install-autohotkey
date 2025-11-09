# -----------------------------
# Test script installs AutoHotkey to a directory like ahk-test-[guid] and runs
# a super simple test script
# -----------------------------
param(
    [string]$TestVersion = '2.0.19'
)

# Simulate GitHub Actions environment locally
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path "$PSScriptRoot/.."  
$scriptPath = Join-Path $repoRoot 'scripts/install-autohotkey.ps1'

# Create a temp directory for testing
$tempRoot = Join-Path $repoRoot "ahk-test-$([guid]::NewGuid().ToString())"
New-Item -ItemType Directory -Path $tempRoot | Out-Null

# Mock GITHUB_PATH (so we don’t modify the real PATH)
$mockGithubPath = Join-Path $tempRoot 'github_path.txt'
$env:GITHUB_PATH = $mockGithubPath

Write-Host "Running AHK installer test..."
& $scriptPath -Version $TestVersion -Destination $tempRoot

Write-Host "`n=== MOCK GITHUB_PATH CONTENT ==="
Get-Content $mockGithubPath | Write-Host

Write-Host "`n=== INSTALLED FILES ==="
Get-ChildItem -Path "$tempRoot\autohotkey" -Recurse | ForEach-Object {
    Write-Host $_.FullName
}

$ahkExe = Join-Path $tempRoot 'autohotkey\AutoHotkey64.exe'
if (-not (Test-Path $ahkExe)) {
    throw "AutoHotkey.exe not found — install failed!"
}
Write-Host "✅ AutoHotkey installed successfully to: $ahkExe"

& $ahkExe '/ErrorStdOut' "$repoRoot/Tests/test.ahk" | Tee-Object -FilePath "$tempRoot\ahk-test-out.txt" -Encoding 'UTF-16'
Write-Host "✅ AutoHotkey ran successfully"

Write-Host "✅ Test completed successfully."
exit 0