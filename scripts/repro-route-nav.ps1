param(
  [string]$EnvFile = "apps/mobile_flutter/.env.local",
  [string]$DeviceId = "emulator-5554",
  [string]$AvdName = "didi_api34",
  [string]$ApiBaseUrl = "http://10.0.2.2:3000/v1",
  [int]$BootTimeoutSeconds = 300,
  [int]$BffTimeoutSeconds = 120,
  [switch]$KeepBff
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $repoRoot

$runId = Get-Date -Format "yyyyMMdd-HHmmss"
$outputDir = Join-Path $repoRoot "reports\repro\route-nav\$runId"
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

$logPatterns = @(
  "\[Bridge\]",
  "\[WebConsole\]",
  "\[BRIDGE\]",
  "APPEvent",
  "Geolocation",
  "User denied Geolocation",
  "ROUTE_REPRO"
)

function Write-Step {
  param([string]$Message)
  Write-Host "[repro-route-nav] $Message"
}

function Resolve-Adb {
  $localAdb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
  if (Test-Path -LiteralPath $localAdb) {
    return $localAdb
  }
  return "adb"
}

function Resolve-EmulatorExe {
  $localEmu = Join-Path $env:LOCALAPPDATA "Android\Sdk\emulator\emulator.exe"
  if (Test-Path -LiteralPath $localEmu) {
    return $localEmu
  }
  throw "Cannot find emulator.exe at $localEmu"
}

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
    throw "Missing required key '$Key' in env file."
  }
}

function Get-DeviceState {
  param(
    [string]$Adb,
    [string]$Id
  )

  $escaped = [regex]::Escape($Id)
  $line = (& $Adb devices) | Where-Object { $_ -match "^$escaped\s+(\S+)$" } | Select-Object -First 1
  if ($null -eq $line) {
    return ""
  }
  return [regex]::Match($line, "^$escaped\s+(\S+)$").Groups[1].Value
}

function Wait-ForDeviceOnline {
  param(
    [string]$Adb,
    [string]$Id,
    [int]$TimeoutSeconds
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $state = Get-DeviceState -Adb $Adb -Id $Id
    if ($state -eq "device") {
      return
    }
    Start-Sleep -Seconds 2
  }
  throw "Device '$Id' did not become online within $TimeoutSeconds seconds."
}

function Wait-ForBootComplete {
  param(
    [string]$Adb,
    [string]$Id,
    [int]$TimeoutSeconds
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    try {
      $boot = (& $Adb -s $Id shell getprop sys.boot_completed 2>$null).Trim()
      $anim = (& $Adb -s $Id shell getprop init.svc.bootanim 2>$null).Trim()
      if ($boot -eq "1" -and $anim -eq "stopped") {
        return
      }
    } catch {
      # Retry until deadline.
    }
    Start-Sleep -Seconds 2
  }
  throw "Device '$Id' boot did not complete within $TimeoutSeconds seconds."
}

function Ensure-EmulatorReady {
  param(
    [string]$Adb,
    [string]$EmulatorExe,
    [string]$Id,
    [string]$Avd,
    [int]$TimeoutSeconds
  )

  $state = Get-DeviceState -Adb $Adb -Id $Id
  if ([string]::IsNullOrWhiteSpace($state)) {
    Write-Step "Launching emulator '$Avd'..."
    Start-Process -FilePath $EmulatorExe -ArgumentList @("-avd", $Avd) | Out-Null
  } elseif ($state -eq "offline") {
    Write-Step "Device is offline; reconnecting adb."
    & $Adb reconnect offline | Out-Null
  }

  Wait-ForDeviceOnline -Adb $Adb -Id $Id -TimeoutSeconds $TimeoutSeconds
  Wait-ForBootComplete -Adb $Adb -Id $Id -TimeoutSeconds $TimeoutSeconds

  & $Adb -s $Id shell input keyevent KEYCODE_WAKEUP | Out-Null
  & $Adb -s $Id shell input keyevent 82 | Out-Null
}

function Test-BffHealth {
  param([string]$HealthUrl)

  try {
    $resp = Invoke-WebRequest -Uri $HealthUrl -UseBasicParsing -TimeoutSec 3
    if ($resp.StatusCode -ne 200) {
      return $false
    }
    $json = $resp.Content | ConvertFrom-Json
    return ($json.status -eq "ok")
  } catch {
    return $false
  }
}

function Ensure-BffReady {
  param(
    [string]$RepoRoot,
    [string]$HealthUrl,
    [int]$TimeoutSeconds,
    [string]$OutputPath
  )

  $started = $false
  $process = $null
  $stdout = Join-Path $OutputPath "bff.stdout.log"
  $stderr = Join-Path $OutputPath "bff.stderr.log"

  if (Test-BffHealth -HealthUrl $HealthUrl) {
    Write-Step "BFF is already healthy: $HealthUrl"
    return @{
      started = $false
      process = $null
      stdout = $stdout
      stderr = $stderr
    }
  }

  Write-Step "Starting BFF with 'npm run bff:dev'..."
  Write-Step "Pre-building BFF dist to avoid watch bootstrap race..."
  & npm.cmd --workspace apps/bff_gateway run build | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "BFF build failed before dev start (exit=$LASTEXITCODE)."
  }

  $process = Start-Process -FilePath "npm.cmd" -ArgumentList @("run", "bff:dev") -WorkingDirectory $RepoRoot -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
  $started = $true

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    if (Test-BffHealth -HealthUrl $HealthUrl) {
      Write-Step "BFF health check passed."
      return @{
        started = $started
        process = $process
        stdout = $stdout
        stderr = $stderr
      }
    }
    Start-Sleep -Seconds 2
  }

  throw "BFF did not pass health check in time. Logs: $stdout , $stderr"
}

function Ensure-AppInstalled {
  param(
    [string]$Adb,
    [string]$Id,
    [string]$RepoRoot
  )

  $installed = (& $Adb -s $Id shell pm list packages com.example.mobile_flutter) -match "package:com.example.mobile_flutter"
  if ($installed) {
    return
  }

  $apkPath = Join-Path $RepoRoot "apps\mobile_flutter\build\app\outputs\flutter-apk\app-debug.apk"
  if (-not (Test-Path -LiteralPath $apkPath)) {
    Write-Step "Debug APK not found, building..."
    Push-Location (Join-Path $RepoRoot "apps\mobile_flutter")
    try {
      & flutter build apk --debug
      if ($LASTEXITCODE -ne 0) {
        throw "flutter build apk --debug failed with exit code $LASTEXITCODE"
      }
    } finally {
      Pop-Location
    }
  }

  Write-Step "Installing app-debug.apk..."
  & $Adb -s $Id install -r $apkPath | Out-Null
}

function Dump-UiXml {
  param(
    [string]$Adb,
    [string]$Id,
    [string]$Name,
    [string]$OutputPath
  )

  $remote = "/sdcard/$Name.xml"
  $local = Join-Path $OutputPath "$Name.xml"
  & $Adb -s $Id shell uiautomator dump $remote | Out-Null
  $xml = (& $Adb -s $Id shell cat $remote)
  $xml | Set-Content -LiteralPath $local -Encoding UTF8
  return $xml
}

function Get-CenterFromMatch {
  param([System.Text.RegularExpressions.Match]$Match)
  $x1 = [int]$Match.Groups[1].Value
  $y1 = [int]$Match.Groups[2].Value
  $x2 = [int]$Match.Groups[3].Value
  $y2 = [int]$Match.Groups[4].Value
  return @{
    x = [int](($x1 + $x2) / 2)
    y = [int](($y1 + $y2) / 2)
    x1 = $x1
    y1 = $y1
    x2 = $x2
    y2 = $y2
  }
}

function Get-CenterByContentDesc {
  param(
    [string]$Xml,
    [string]$Desc
  )

  $escaped = [regex]::Escape($Desc)
  $m = [regex]::Match($Xml, "content-desc=""$escaped"".*?bounds=""\[(\d+),(\d+)\]\[(\d+),(\d+)\]""")
  if (-not $m.Success) {
    return $null
  }
  return Get-CenterFromMatch -Match $m
}

function Get-EditTextCenters {
  param([string]$Xml)

  $matches = [regex]::Matches($Xml, "class=""android\.widget\.EditText"".*?bounds=""\[(\d+),(\d+)\]\[(\d+),(\d+)\]""")
  $result = @()
  foreach ($m in $matches) {
    $result += ,(Get-CenterFromMatch -Match $m)
  }
  return $result
}

function Get-WebViewBounds {
  param([string]$Xml)

  $m = [regex]::Match($Xml, "class=""android\.webkit\.WebView"".*?bounds=""\[(\d+),(\d+)\]\[(\d+),(\d+)\]""")
  if (-not $m.Success) {
    return $null
  }
  return Get-CenterFromMatch -Match $m
}

function Tap-Point {
  param(
    [string]$Adb,
    [string]$Id,
    [int]$X,
    [int]$Y,
    [string]$Label
  )
  Write-Step "Tap '$Label' at ($X,$Y)"
  & $Adb -s $Id shell input tap $X $Y | Out-Null
}

function Clear-CurrentField {
  param(
    [string]$Adb,
    [string]$Id
  )
  & $Adb -s $Id shell input keyevent KEYCODE_MOVE_END | Out-Null
  for ($i = 0; $i -lt 30; $i++) {
    & $Adb -s $Id shell input keyevent KEYCODE_DEL | Out-Null
  }
}

function Take-Screenshot {
  param(
    [string]$Adb,
    [string]$Id,
    [string]$Name,
    [string]$OutputPath
  )

  $remote = "/sdcard/$Name.png"
  $local = Join-Path $OutputPath "$Name.png"
  & $Adb -s $Id shell screencap -p $remote | Out-Null
  & $Adb -s $Id pull $remote $local | Out-Null
}

function Wait-ForLoginSuccess {
  param(
    [string]$Adb,
    [string]$Id,
    [int]$TimeoutSeconds,
    [string]$OutputPath
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  $lastXml = ""
  while ((Get-Date) -lt $deadline) {
    $lastXml = Dump-UiXml -Adb $Adb -Id $Id -Name "wait-login" -OutputPath $OutputPath
    $ok = $lastXml.Contains('content-desc="預約"') -and
      $lastXml.Contains('content-desc="接單"') -and
      $lastXml.Contains('content-desc="簽收"') -and
      $lastXml.Contains('content-desc="錢包"')
    if ($ok) {
      return $true
    }
    Start-Sleep -Seconds 2
  }

  $lastXml | Set-Content -LiteralPath (Join-Path $OutputPath "login-timeout.xml") -Encoding UTF8
  return $false
}

function Build-ResultSummary {
  param(
    [string[]]$FilteredLines,
    [string]$OutputPath
  )

  $joined = ($FilteredLines -join "`n")
  $hasIncoming = $joined -match "\[Bridge\]\[incoming\]"
  $hasOutgoingOk = $joined -match "\[Bridge\]\[outgoing\].*ok=true"
  $hasAppEvent = $joined -match "APPEvent"
  $hasGeoDenied = $joined -match "User denied Geolocation"

  $routeSection = $FilteredLines | Select-String -Pattern "ROUTE_REPRO.*route_plan|ROUTE_REPRO.*nav_icon|Bridge|BRIDGE|APPEvent|Geolocation|User denied Geolocation"

  $verdict = "unknown"
  $layer = "unknown"
  if ($hasGeoDenied) {
    $verdict = "failed"
    $layer = "permission/origin"
  } elseif (-not ($hasIncoming -or $hasAppEvent)) {
    $verdict = "failed"
    $layer = "web-event"
  } elseif ($hasOutgoingOk) {
    $verdict = "pass"
    $layer = "bridge-ok"
  } else {
    $verdict = "failed"
    $layer = "bridge"
  }

  $summaryMd = @(
    "# Route/Nav Repro Summary",
    "",
    "- Verdict: **$verdict**",
    "- Failure layer: **$layer**",
    "- hasIncoming: $hasIncoming",
    "- hasOutgoingOk: $hasOutgoingOk",
    "- hasAppEvent: $hasAppEvent",
    "- hasGeoDenied: $hasGeoDenied",
    "",
    "## Evidence",
    "- filtered-logcat.log",
    "- before-clicks.png",
    "- after-clicks.png",
    "",
    "## Key Lines"
  )

  $keyLines = @($routeSection | ForEach-Object { "- $($_.Line)" })
  if ($keyLines.Count -eq 0) {
    $keyLines = @("- (no matched bridge/geolocation lines)")
  }
  $summaryMd += $keyLines

  $summaryPath = Join-Path $OutputPath "result-summary.md"
  $summaryMd | Set-Content -LiteralPath $summaryPath -Encoding UTF8

  return @{
    verdict = $verdict
    layer = $layer
    summary = $summaryPath
  }
}

$adb = Resolve-Adb
$emulatorExe = Resolve-EmulatorExe
$envMap = Read-EnvFile -Path $EnvFile
Require-EnvKey -Map $envMap -Key "UAT_ACCOUNT"
Require-EnvKey -Map $envMap -Key "UAT_PASSWORD"

$account = [string]$envMap["UAT_ACCOUNT"]
$password = [string]$envMap["UAT_PASSWORD"]
$loginTimeoutRaw = if ($envMap.ContainsKey("UAT_LOGIN_TIMEOUT_SECONDS")) { $envMap["UAT_LOGIN_TIMEOUT_SECONDS"] } else { "45" }
$parsedLoginTimeout = 45
[int]$tmpTimeout = 0
if ([int]::TryParse($loginTimeoutRaw, [ref]$tmpTimeout)) {
  $parsedLoginTimeout = $tmpTimeout
}
$loginTimeout = $parsedLoginTimeout + 30

$bffStartedByScript = $false
$bffProc = $null

try {
  Write-Step "Artifacts: $outputDir"
  Ensure-EmulatorReady -Adb $adb -EmulatorExe $emulatorExe -Id $DeviceId -Avd $AvdName -TimeoutSeconds $BootTimeoutSeconds

  $healthUrl = "http://127.0.0.1:3000/v1/health"
  $bffStatus = Ensure-BffReady -RepoRoot $repoRoot -HealthUrl $healthUrl -TimeoutSeconds $BffTimeoutSeconds -OutputPath $outputDir
  $bffStartedByScript = [bool]$bffStatus.started
  $bffProc = $bffStatus.process

  Ensure-AppInstalled -Adb $adb -Id $DeviceId -RepoRoot $repoRoot

  Write-Step "Setting location service and app permissions..."
  & $adb -s $DeviceId shell settings put secure location_mode 3 | Out-Null
  & $adb -s $DeviceId shell pm grant com.example.mobile_flutter android.permission.ACCESS_COARSE_LOCATION | Out-Null
  & $adb -s $DeviceId shell pm grant com.example.mobile_flutter android.permission.ACCESS_FINE_LOCATION | Out-Null

  Write-Step "Launching app..."
  & $adb -s $DeviceId shell am force-stop com.example.mobile_flutter | Out-Null
  & $adb -s $DeviceId shell am start -n com.example.mobile_flutter/com.example.mobile_flutter.MainActivity | Out-Null
  Start-Sleep -Seconds 6

  $loginXml = Dump-UiXml -Adb $adb -Id $DeviceId -Name "login-screen" -OutputPath $outputDir
  $fields = Get-EditTextCenters -Xml $loginXml
  if ($fields.Count -lt 2) {
    throw "Cannot locate account/password fields on login page."
  }

  Tap-Point -Adb $adb -Id $DeviceId -X $fields[0].x -Y $fields[0].y -Label "account field"
  Clear-CurrentField -Adb $adb -Id $DeviceId
  & $adb -s $DeviceId shell input text $account | Out-Null

  Tap-Point -Adb $adb -Id $DeviceId -X $fields[1].x -Y $fields[1].y -Label "password field"
  Clear-CurrentField -Adb $adb -Id $DeviceId
  & $adb -s $DeviceId shell input text $password | Out-Null

  $loginButton = Get-CenterByContentDesc -Xml $loginXml -Desc "登入"
  if ($null -eq $loginButton) {
    throw "Cannot locate login button."
  }
  Tap-Point -Adb $adb -Id $DeviceId -X $loginButton.x -Y $loginButton.y -Label "login button"

  Write-Step "Waiting for login success..."
  $loginOk = Wait-ForLoginSuccess -Adb $adb -Id $DeviceId -TimeoutSeconds $loginTimeout -OutputPath $outputDir
  if (-not $loginOk) {
    throw "Login did not reach main tabs in $loginTimeout seconds."
  }

  $mainXml = Dump-UiXml -Adb $adb -Id $DeviceId -Name "main-tabs" -OutputPath $outputDir
  $pickupTab = Get-CenterByContentDesc -Xml $mainXml -Desc "接單"
  if ($null -eq $pickupTab) {
    throw "Cannot locate pickup tab."
  }
  Tap-Point -Adb $adb -Id $DeviceId -X $pickupTab.x -Y $pickupTab.y -Label "pickup tab"
  Start-Sleep -Seconds 4

  $orderXml = Dump-UiXml -Adb $adb -Id $DeviceId -Name "order-detail" -OutputPath $outputDir
  $webBounds = Get-WebViewBounds -Xml $orderXml
  if ($null -eq $webBounds) {
    throw "Cannot locate WebView in order detail screen."
  }

  $routeX = [int]($webBounds.x2 - 120)
  $routeY = [int]($webBounds.y1 + 280)
  $navX = [int]($webBounds.x2 - 85)
  $navY = [int]($webBounds.y1 + 470)

  Take-Screenshot -Adb $adb -Id $DeviceId -Name "before-clicks" -OutputPath $outputDir

  & $adb -s $DeviceId logcat -c | Out-Null
  & $adb -s $DeviceId shell log -t ROUTE_REPRO "TAP route_plan" | Out-Null
  Tap-Point -Adb $adb -Id $DeviceId -X $routeX -Y $routeY -Label "route plan button"
  Start-Sleep -Seconds 3

  & $adb -s $DeviceId shell log -t ROUTE_REPRO "TAP nav_icon" | Out-Null
  Tap-Point -Adb $adb -Id $DeviceId -X $navX -Y $navY -Label "first row nav icon"
  Start-Sleep -Seconds 4

  Take-Screenshot -Adb $adb -Id $DeviceId -Name "after-clicks" -OutputPath $outputDir

  $allLogs = & $adb -s $DeviceId logcat -d
  $allLogs | Set-Content -LiteralPath (Join-Path $outputDir "full-logcat.log") -Encoding UTF8

  $filtered = $allLogs | Select-String -Pattern ($logPatterns -join "|")
  $filteredLines = @($filtered | ForEach-Object { $_.Line })
  $filteredLines | Set-Content -LiteralPath (Join-Path $outputDir "filtered-logcat.log") -Encoding UTF8

  $result = Build-ResultSummary -FilteredLines $filteredLines -OutputPath $outputDir
  Write-Step "Completed. Verdict=$($result.verdict), Layer=$($result.layer)"
  Write-Step "Summary: $($result.summary)"
  Write-Step "Filtered logs: $(Join-Path $outputDir "filtered-logcat.log")"
  Write-Step "Screenshots: before-clicks.png / after-clicks.png"
} finally {
  if ($bffStartedByScript -and -not $KeepBff -and $null -ne $bffProc) {
    Write-Step "Stopping BFF process started by this script (PID=$($bffProc.Id))"
    Stop-Process -Id $bffProc.Id -Force -ErrorAction SilentlyContinue
  }
}
