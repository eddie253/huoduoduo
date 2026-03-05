param(
  [ValidateSet("debug", "release", "profile")]
  [string]$BuildMode = "debug",
  [string]$DeviceId = "",
  [string]$ApiBaseUrl = "",
  [string]$EnvFile = "apps/mobile_flutter/.env.local",
  [switch]$SkipClean,
  [switch]$NoInstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Command {
  param([string]$Name)
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Command not found: $Name"
  }
}

function Read-EnvFile {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    return @{}
  }

  $map = @{}
  foreach ($line in Get-Content -LiteralPath $Path) {
    $raw = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($raw)) { continue }
    if ($raw.StartsWith("#")) { continue }

    $sep = $raw.IndexOf("=")
    if ($sep -lt 1) { continue }

    $key = $raw.Substring(0, $sep).Trim()
    $val = $raw.Substring($sep + 1).Trim()

    if ($val.StartsWith('"') -and $val.EndsWith('"') -and $val.Length -ge 2) {
      $val = $val.Substring(1, $val.Length - 2)
    } elseif ($val.StartsWith("'") -and $val.EndsWith("'") -and $val.Length -ge 2) {
      $val = $val.Substring(1, $val.Length - 2)
    }
    $map[$key] = $val
  }

  return $map
}

function Get-ConnectedDevices {
  $rows = @()
  $output = & adb devices
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to execute adb devices"
  }

  foreach ($line in $output) {
    if ($line -match "^\s*$") { continue }
    if ($line -match "^List of devices attached") { continue }

    $parts = ($line -split "\s+") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    if ($parts.Count -lt 2) { continue }
    if ($parts[1] -ne "device") { continue }
    $rows += $parts[0]
  }

  return $rows
}

function Resolve-DeviceId {
  param([string]$RequestedDeviceId)

  $devices = Get-ConnectedDevices
  if ([string]::IsNullOrWhiteSpace($RequestedDeviceId)) {
    if ($devices.Count -eq 0) {
      throw "No Android device connected. Check USB debugging and run adb devices."
    }
    if ($devices.Count -gt 1) {
      throw "Multiple devices connected: $($devices -join ', '). Please pass -DeviceId."
    }
    return $devices[0]
  }

  if ($devices -notcontains $RequestedDeviceId) {
    throw "Device '$RequestedDeviceId' not found. Connected devices: $($devices -join ', ')"
  }

  return $RequestedDeviceId
}

function Get-ApkPath {
  param(
    [string]$MobileDir,
    [string]$Mode
  )

  $fileName = switch ($Mode) {
    "release" { "app-release.apk" }
    "profile" { "app-profile.apk" }
    default { "app-debug.apk" }
  }

  return Join-Path $MobileDir "build/app/outputs/flutter-apk/$fileName"
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..")).Path
$mobileDir = Join-Path $repoRoot "apps/mobile_flutter"

if (-not (Test-Path -LiteralPath $mobileDir)) {
  throw "Flutter directory not found: $mobileDir"
}

Assert-Command -Name "flutter"
Assert-Command -Name "adb"

$envMap = Read-EnvFile -Path (Join-Path $repoRoot $EnvFile)
if ([string]::IsNullOrWhiteSpace($ApiBaseUrl) -and $envMap.ContainsKey("API_BASE_URL")) {
  $ApiBaseUrl = [string]$envMap["API_BASE_URL"]
}

$resolvedDevice = if (-not $NoInstall) { Resolve-DeviceId -RequestedDeviceId $DeviceId } else { "" }

Write-Host "[apk] Repo: $repoRoot"
Write-Host "[apk] Mobile: $mobileDir"
Write-Host "[apk] BuildMode: $BuildMode"
if (-not [string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
  Write-Host "[apk] API_BASE_URL: $ApiBaseUrl"
}
if (-not $NoInstall) {
  Write-Host "[apk] Device: $resolvedDevice"
}

Push-Location $mobileDir
try {
  if (-not $SkipClean) {
    & flutter clean
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  }

  & flutter pub get
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  $buildArgs = @("build", "apk", "--$BuildMode")
  if (-not [string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    $buildArgs += "--dart-define=API_BASE_URL=$ApiBaseUrl"
  }

  & flutter @buildArgs
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
  Pop-Location
}

$apkPath = Get-ApkPath -MobileDir $mobileDir -Mode $BuildMode
if (-not (Test-Path -LiteralPath $apkPath)) {
  throw "APK not found: $apkPath"
}

Write-Host "[apk] Built: $apkPath"

if ($NoInstall) {
  Write-Host "[apk] Skip install because -NoInstall is set."
  exit 0
}

& adb -s $resolvedDevice install -r $apkPath
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Host "[apk] Install completed on device: $resolvedDevice"
