param(
    [string]$TagName = "legacy-android-baseline-2026-03-01",
    [string]$ManifestPath = "docs/architecture/LEGACY_BASELINE_MANIFEST.txt"
)

$ErrorActionPreference = "Stop"

function Write-ManifestLine {
    param(
        [string]$Hash,
        [string]$RelativePath
    )
    return "$Hash  $RelativePath"
}

$repoRoot = (Get-Location).Path
$frozenPaths = @("app", "zbarlibary")
$manifestLines = @()

foreach ($path in $frozenPaths) {
    if (-not (Test-Path $path)) {
        continue
    }

    $files = Get-ChildItem -Path $path -Recurse -File | Sort-Object FullName
    foreach ($file in $files) {
        if (
            $file.FullName -match '\\build\\' -or
            $file.FullName -match '\\\.gradle\\' -or
            $file.FullName -match '\\out\\' -or
            $file.FullName -match '\\app\\debug\\' -or
            $file.FullName -match '\\app\\release\\'
        ) {
            continue
        }
        $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        $relative = $file.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
        $manifestLines += (Write-ManifestLine -Hash $hash -RelativePath $relative)
    }
}

$generatedAtUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$manifestHeader = @(
    "# Legacy baseline manifest",
    "generated_at_utc=$generatedAtUtc",
    "tag_name=$TagName",
    "frozen_paths=$(($frozenPaths -join ","))",
    ""
)

Set-Content -Path $ManifestPath -Encoding UTF8 -Value ($manifestHeader + $manifestLines)
Write-Host "Manifest generated: $ManifestPath"

try {
    $inside = (git rev-parse --is-inside-work-tree 2>$null).Trim()
} catch {
    $inside = "false"
}

if ($inside -ne "true") {
    Write-Warning "Current workspace has no .git metadata. Manifest created, tag not applied."
    exit 0
}

$existingTag = (git tag --list $TagName).Trim()
if ($existingTag) {
    Write-Host "Tag already exists: $TagName"
    exit 0
}

git tag -a $TagName -m "Freeze legacy Android baseline (read-only): app/ + zbarlibary/"
Write-Host "Tag created: $TagName"
