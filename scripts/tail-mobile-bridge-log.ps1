param(
  [string]$DeviceId = "",
  [switch]$ShowAll,
  [switch]$NoClear
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$adb = "adb"
$localAdb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
if (Test-Path -LiteralPath $localAdb) {
  $adb = $localAdb
}

function Get-AdbDeviceStates {
  param([string]$AdbPath)

  $rows = @(
    (& $AdbPath devices) |
      Select-Object -Skip 1 |
      ForEach-Object { $_.Trim() } |
      Where-Object { $_ -ne "" }
  )

  $states = @()
  foreach ($row in $rows) {
    if ($row -match "^(\S+)\s+(\S+)$") {
      $states += [PSCustomObject]@{
        Id    = $matches[1]
        State = $matches[2]
      }
    }
  }
  return $states
}

$deviceStates = @(Get-AdbDeviceStates -AdbPath $adb)
if ($deviceStates.Count -eq 0) {
  Write-Error "[mobile-bridge-log] no adb device found. Start an emulator or connect a phone, then run again."
}

$readyDevices = @($deviceStates | Where-Object { $_.State -eq "device" })
$offlineDevices = @($deviceStates | Where-Object { $_.State -eq "offline" })
$unauthorizedDevices = @($deviceStates | Where-Object { $_.State -eq "unauthorized" })

if ($offlineDevices.Count -gt 0) {
  $ids = ($offlineDevices | ForEach-Object { $_.Id }) -join ", "
  Write-Host "[mobile-bridge-log] warning: offline device(s): $ids"
  Write-Host "[mobile-bridge-log] hint: reconnect USB or restart adb server (adb kill-server; adb start-server)."
}

if ($unauthorizedDevices.Count -gt 0) {
  $ids = ($unauthorizedDevices | ForEach-Object { $_.Id }) -join ", "
  Write-Host "[mobile-bridge-log] warning: unauthorized device(s): $ids"
  Write-Host "[mobile-bridge-log] hint: unlock phone and allow USB debugging prompt, then rerun."
}

if ($readyDevices.Count -eq 0) {
  Write-Error "[mobile-bridge-log] no authorized online device available."
}

if ([string]::IsNullOrWhiteSpace($DeviceId)) {
  $DeviceId = $readyDevices[0].Id
} else {
  $target = $deviceStates | Where-Object { $_.Id -eq $DeviceId } | Select-Object -First 1
  if ($null -eq $target) {
    $available = ($readyDevices | ForEach-Object { $_.Id }) -join ", "
    Write-Error "[mobile-bridge-log] device '$DeviceId' is not connected. Online devices: $available"
  }
  if ($target.State -ne "device") {
    Write-Error "[mobile-bridge-log] device '$DeviceId' state is '$($target.State)'. Required state: 'device'."
  }
}

$patterns = @(
  "\[Bridge\]",
  "\[WebConsole\]",
  "\[BRIDGE\]",
  "User denied Geolocation",
  "APPEvent",
  "BRIDGE_"
)

Write-Host "[mobile-bridge-log] device: $DeviceId"
if (-not $NoClear) {
  Write-Host "[mobile-bridge-log] clearing existing logcat buffer..."
  & $adb -s $DeviceId logcat -c
}

Write-Host ("[mobile-bridge-log] filter: " + ($patterns -join " | "))
if ($ShowAll) {
  Write-Host "[mobile-bridge-log] mode: all"
  Write-Host "[mobile-bridge-log] tailing logs (Ctrl+C to stop)"
  & $adb -s $DeviceId logcat
} else {
  $regex = $patterns -join "|"
  Write-Host "[mobile-bridge-log] mode: filtered"
  Write-Host "[mobile-bridge-log] tailing logs (Ctrl+C to stop)"
  & $adb -s $DeviceId logcat | ForEach-Object {
    if ($_ -match $regex) {
      Write-Output $_
    }
  }
}
