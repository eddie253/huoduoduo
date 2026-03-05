param(
    [string]$DeviceId = 'emulator-5554',
    [string]$EnvFile = 'apps/mobile_flutter/.env.local',
    [string]$EmulatorId = 'didi_api34',
    [string]$AndroidPackage = 'com.example.mobile_flutter',
    [switch]$SkipClean
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $repoRoot

function Test-AndroidDeviceConnected {
    param([string]$TargetDeviceId)
    $lines = & adb devices 2>$null
    if (-not $lines) {
        return $false
    }
    foreach ($line in $lines) {
        if ($line -match '^\s*' + [regex]::Escape($TargetDeviceId) + '\s+device\s*$') {
            return $true
        }
    }
    return $false
}

function Ensure-AndroidDeviceReady {
    param(
        [string]$TargetDeviceId,
        [string]$TargetEmulatorId
    )
    if (Test-AndroidDeviceConnected -TargetDeviceId $TargetDeviceId) {
        return
    }

    Write-Host "[AutoLogin] Device $TargetDeviceId not found. Launch emulator: $TargetEmulatorId"
    flutter emulators --launch $TargetEmulatorId | Out-Null

    $deadline = (Get-Date).AddMinutes(3)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 3
        if (Test-AndroidDeviceConnected -TargetDeviceId $TargetDeviceId) {
            Write-Host "[AutoLogin] Emulator detected: $TargetDeviceId"
            & adb -s $TargetDeviceId wait-for-device | Out-Null

            $bootDeadline = (Get-Date).AddMinutes(2)
            while ((Get-Date) -lt $bootDeadline) {
                $boot = (& adb -s $TargetDeviceId shell getprop sys.boot_completed 2>$null).Trim()
                if ($boot -eq '1') {
                    Write-Host "[AutoLogin] Emulator boot completed: $TargetDeviceId"
                    return
                }
                Start-Sleep -Seconds 2
            }
            throw "Emulator '$TargetEmulatorId' detected but boot not completed in time."
            return
        }
    }

    throw "Emulator '$TargetEmulatorId' did not become ready as '$TargetDeviceId' within timeout."
}

function Get-EnvMap {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path $Path)) {
        throw "Env file not found: $Path"
    }

    $result = @{}
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
            return
        }
        $idx = $line.IndexOf('=')
        if ($idx -lt 0) {
            return
        }
        $key = $line.Substring(0, $idx).Trim()
        $value = $line.Substring($idx + 1).Trim()
        $result[$key] = $value
    }
    return $result
}

function Get-OrDefault {
    param(
        [hashtable]$Map,
        [string]$Key,
        [string]$DefaultValue = ''
    )
    if ($Map.ContainsKey($Key) -and -not [string]::IsNullOrWhiteSpace($Map[$Key])) {
        return $Map[$Key]
    }
    return $DefaultValue
}

$envMap = Get-EnvMap -Path $EnvFile
$account = Get-OrDefault -Map $envMap -Key 'UAT_ACCOUNT'
$password = Get-OrDefault -Map $envMap -Key 'UAT_PASSWORD'

if ([string]::IsNullOrWhiteSpace($account) -or [string]::IsNullOrWhiteSpace($password)) {
    throw "UAT_ACCOUNT/UAT_PASSWORD not found in $EnvFile"
}

$apiBaseUrl = Get-OrDefault -Map $envMap -Key 'API_BASE_URL' -DefaultValue 'http://10.0.2.2:3000/v1'
$registerUrl = Get-OrDefault -Map $envMap -Key 'WEBVIEW_REGISTER_URL' -DefaultValue 'https://old.huoduoduo.com.tw/register/register.aspx'
$resetUrl = Get-OrDefault -Map $envMap -Key 'WEBVIEW_RESET_URL' -DefaultValue 'https://old.huoduoduo.com.tw/register/register_resetpwd.aspx'

Write-Host "[AutoLogin] Device: $DeviceId"
Write-Host "[AutoLogin] Env: $EnvFile"
Write-Host "[AutoLogin] API_BASE_URL: $apiBaseUrl"

Ensure-AndroidDeviceReady -TargetDeviceId $DeviceId -TargetEmulatorId $EmulatorId

Set-Location (Join-Path $repoRoot 'apps/mobile_flutter')

if (-not $SkipClean) {
    Write-Host '[AutoLogin] Clean install mode: uninstall + flutter clean + pub get'
    & adb -s $DeviceId uninstall $AndroidPackage 2>$null | Out-Null
    flutter clean
    if ($LASTEXITCODE -ne 0) {
        throw "flutter clean failed with exit code $LASTEXITCODE"
    }
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        throw "flutter pub get failed with exit code $LASTEXITCODE"
    }
}

flutter run -d $DeviceId `
  --dart-define=DEV_AUTO_LOGIN=true `
  --dart-define=DEV_AUTO_LOGIN_ACCOUNT="$account" `
  --dart-define=DEV_AUTO_LOGIN_PASSWORD="$password" `
  --dart-define=API_BASE_URL="$apiBaseUrl" `
  --dart-define=WEBVIEW_REGISTER_URL="$registerUrl" `
  --dart-define=WEBVIEW_RESET_URL="$resetUrl"
