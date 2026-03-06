param(
    [string]$DeviceId = 'emulator-5554',
    [string]$EnvFile = 'apps/mobile_flutter/.env.local',
    [string]$EmulatorId = 'didi_api34',
    [switch]$SkipDeviceCheck
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

    Write-Host "[UAT-IT] Device $TargetDeviceId not found. Launch emulator: $TargetEmulatorId"
    flutter emulators --launch $TargetEmulatorId | Out-Null

    $deadline = (Get-Date).AddMinutes(3)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 3
        if (Test-AndroidDeviceConnected -TargetDeviceId $TargetDeviceId) {
            Write-Host "[UAT-IT] Emulator detected: $TargetDeviceId"
            & adb -s $TargetDeviceId wait-for-device | Out-Null

            $bootDeadline = (Get-Date).AddMinutes(2)
            while ((Get-Date) -lt $bootDeadline) {
                $boot = (& adb -s $TargetDeviceId shell getprop sys.boot_completed 2>$null).Trim()
                if ($boot -eq '1') {
                    Write-Host "[UAT-IT] Emulator boot completed: $TargetDeviceId"
                    return
                }
                Start-Sleep -Seconds 2
            }
            throw "Emulator '$TargetEmulatorId' detected but boot not completed in time."
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
$timeoutSeconds = Get-OrDefault -Map $envMap -Key 'UAT_LOGIN_TIMEOUT_SECONDS' -DefaultValue '90'

if ([string]::IsNullOrWhiteSpace($account) -or [string]::IsNullOrWhiteSpace($password)) {
    throw "UAT_ACCOUNT/UAT_PASSWORD not found in $EnvFile"
}

$apiBaseUrl = Get-OrDefault -Map $envMap -Key 'API_BASE_URL' -DefaultValue 'http://10.0.2.2:3000/v1'

Write-Host "[UAT-IT] Device: $DeviceId"
Write-Host "[UAT-IT] Env: $EnvFile"
Write-Host "[UAT-IT] API_BASE_URL: $apiBaseUrl"
Write-Host "[UAT-IT] Timeout: $timeoutSeconds sec"

if (-not $SkipDeviceCheck) {
    Ensure-AndroidDeviceReady -TargetDeviceId $DeviceId -TargetEmulatorId $EmulatorId
}

Set-Location (Join-Path $repoRoot 'apps/mobile_flutter')

flutter test integration_test/login_to_webview_test.dart -d $DeviceId `
  --dart-define=API_BASE_URL="$apiBaseUrl" `
  --dart-define=UAT_ACCOUNT="$account" `
  --dart-define=UAT_PASSWORD="$password" `
  --dart-define=UAT_LOGIN_TIMEOUT_SECONDS="$timeoutSeconds"

if ($LASTEXITCODE -ne 0) {
    throw "UAT integration test failed with exit code $LASTEXITCODE"
}
