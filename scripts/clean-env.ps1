param(
  [switch]$IncludeFlutterCache,
  [switch]$IncludeDockerCache,
  [switch]$IncludePnpmStore,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')

function Invoke-Step {
  param(
    [Parameter(Mandatory = $true)][string]$Message,
    [Parameter(Mandatory = $true)][scriptblock]$Action
  )

  Write-Host "[clean] $Message"
  if ($DryRun) {
    Write-Host "[clean] dry-run: skipped"
    return
  }

  & $Action
}

function Remove-PathIfExists {
  param([Parameter(Mandatory = $true)][string]$TargetPath)

  if (Test-Path -LiteralPath $TargetPath) {
    Remove-Item -LiteralPath $TargetPath -Recurse -Force -ErrorAction SilentlyContinue
  }
}

Set-Location $repoRoot

Invoke-Step -Message 'Removing node_modules directories' -Action {
  $nodeModules = Get-ChildItem -Path $repoRoot -Directory -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -eq 'node_modules' }

  foreach ($dir in $nodeModules) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
  }
}

$mobileRoot = Join-Path $repoRoot 'apps/mobile_flutter'
Invoke-Step -Message 'Removing Flutter local build artifacts' -Action {
  Remove-PathIfExists (Join-Path $mobileRoot 'build')
  Remove-PathIfExists (Join-Path $mobileRoot '.dart_tool')
  Remove-PathIfExists (Join-Path $mobileRoot '.packages')
  Remove-PathIfExists (Join-Path $mobileRoot '.flutter-plugins')
  Remove-PathIfExists (Join-Path $mobileRoot '.flutter-plugins-dependencies')
  Remove-PathIfExists (Join-Path $mobileRoot 'android/.gradle')
  Remove-PathIfExists (Join-Path $mobileRoot 'android/app/build')
  Remove-PathIfExists (Join-Path $mobileRoot 'ios/Pods')
}

Invoke-Step -Message 'Running flutter clean (if available)' -Action {
  if (-not (Test-Path -LiteralPath $mobileRoot)) { return }

  $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
  if ($null -eq $flutterCmd) {
    Write-Host '[clean] flutter not found, skipped flutter clean'
    return
  }

  Push-Location $mobileRoot
  try {
    & flutter clean
  }
  finally {
    Pop-Location
  }
}

if ($IncludeFlutterCache) {
  Invoke-Step -Message 'Cleaning Flutter pub cache' -Action {
    $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($null -eq $flutterCmd) {
      Write-Host '[clean] flutter not found, skipped flutter pub cache clean'
      return
    }

    & flutter pub cache clean --force
  }
}

if ($IncludeDockerCache) {
  Invoke-Step -Message 'Pruning Docker builder cache' -Action {
    $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
    if ($null -eq $dockerCmd) {
      Write-Host '[clean] docker not found, skipped docker cache prune'
      return
    }

    try {
      & docker info | Out-Null
    }
    catch {
      Write-Host '[clean] docker daemon unavailable, skipped docker cache prune'
      return
    }

    & docker builder prune -a -f
  }
}

if ($IncludePnpmStore) {
  Invoke-Step -Message 'Pruning pnpm store' -Action {
    $pnpmCmd = Get-Command pnpm -ErrorAction SilentlyContinue
    if ($null -eq $pnpmCmd) {
      Write-Host '[clean] pnpm not found, skipped pnpm store prune'
      return
    }

    & pnpm store prune
  }
}

Write-Host '[clean] done'
