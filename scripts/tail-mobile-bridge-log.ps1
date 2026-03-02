param(
  [string]$DeviceId = "emulator-5554"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$adb = "adb"
$localAdb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
if (Test-Path -LiteralPath $localAdb) {
  $adb = $localAdb
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
Write-Host "[mobile-bridge-log] clearing existing logcat buffer..."
& $adb -s $DeviceId logcat -c

Write-Host "[mobile-bridge-log] tailing logs (Ctrl+C to stop)"
& $adb -s $DeviceId logcat | Select-String -Pattern ($patterns -join "|")
