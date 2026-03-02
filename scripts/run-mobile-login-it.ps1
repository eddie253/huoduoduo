param(
  [string]$EnvFile = "apps/mobile_flutter/.env.local",
  [string]$DeviceId = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-EnvFile {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Env file not found: $Path"
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
    if ($val.StartsWith('"') -and $val.EndsWith('"')) {
      $val = $val.Substring(1, $val.Length - 2)
    } elseif ($val.StartsWith("'") -and $val.EndsWith("'")) {
      $val = $val.Substring(1, $val.Length - 2)
    }
    $map[$key] = $val
  }

  return $map
}

function Require-EnvKey {
  param(
    [hashtable]$Map,
    [string]$Key
  )
  if (-not $Map.ContainsKey($Key) -or [string]::IsNullOrWhiteSpace($Map[$Key])) {
    throw "Missing required key '$Key' in $EnvFile"
  }
}

$envMap = Read-EnvFile -Path $EnvFile
Require-EnvKey -Map $envMap -Key "UAT_ACCOUNT"
Require-EnvKey -Map $envMap -Key "UAT_PASSWORD"

$args = @(
  "test",
  "integration_test/login_to_webview_test.dart"
)

if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
  $args += @("-d", $DeviceId)
}

$defineKeys = @(
  "UAT_ACCOUNT",
  "UAT_PASSWORD",
  "API_BASE_URL",
  "WEBVIEW_REGISTER_URL",
  "WEBVIEW_RESET_URL",
  "UAT_LOGIN_TIMEOUT_SECONDS"
)

foreach ($key in $defineKeys) {
  if ($envMap.ContainsKey($key) -and -not [string]::IsNullOrWhiteSpace($envMap[$key])) {
    $args += "--dart-define=$key=$($envMap[$key])"
  }
}

$account = [string]$envMap["UAT_ACCOUNT"]
$masked = if ($account.Length -ge 5) {
  $account.Substring(0, 3) + "***" + $account.Substring($account.Length - 2)
} else {
  "***"
}

Write-Host "[mobile-login-it] Env file: $EnvFile"
Write-Host "[mobile-login-it] Account: $masked"
if ($envMap.ContainsKey("API_BASE_URL")) {
  Write-Host "[mobile-login-it] API_BASE_URL: $($envMap["API_BASE_URL"])"
}

Push-Location "apps/mobile_flutter"
try {
  & flutter @args
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
} finally {
  Pop-Location
}
