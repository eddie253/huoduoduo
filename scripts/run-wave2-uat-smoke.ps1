param(
    [string]$BaseUrl = "http://localhost:3000/v1",
    [string]$Account = "uat_account",
    [string]$Password = "uat_password",
    [string]$DeviceId = "uat-device-001",
    [string]$TrackingNo = "",
    [bool]$AutoDiscoverTracking = $true
)

$ErrorActionPreference = "Stop"

function Get-FirstReservationTrackingNo {
    param(
        [string]$ApiBaseUrl,
        [hashtable]$Headers,
        [string]$Mode
    )

    $reservations = Invoke-RestMethod -Method Get -Uri "$ApiBaseUrl/reservations?mode=$Mode" -Headers $Headers
    foreach ($reservation in @($reservations)) {
        $shipmentNos = @($reservation.shipmentNos)
        foreach ($shipmentNo in $shipmentNos) {
            if (-not [string]::IsNullOrWhiteSpace([string]$shipmentNo)) {
                return [PSCustomObject]@{
                    trackingNo = [string]$shipmentNo
                    source = "$Mode-reservation"
                }
            }
        }
    }
    return $null
}

Write-Host "== Wave2 UAT Smoke =="
Write-Host "BaseUrl: $BaseUrl"

$loginBody = @{
    account = $Account
    password = $Password
    deviceId = $DeviceId
    platform = "android"
} | ConvertTo-Json

Write-Host "[1/5] POST /auth/login"
$login = Invoke-RestMethod -Method Post -Uri "$BaseUrl/auth/login" -ContentType "application/json" -Body $loginBody
if (-not $login.accessToken) { throw "Login accessToken missing." }
if (-not $login.refreshToken) { throw "Login refreshToken missing." }
Write-Host "Login OK"

$headers = @{ Authorization = "Bearer $($login.accessToken)" }

Write-Host "[2/5] GET /bootstrap/webview"
$bootstrap = Invoke-RestMethod -Method Get -Uri "$BaseUrl/bootstrap/webview" -Headers $headers
if (-not $bootstrap.baseUrl) { throw "bootstrap.baseUrl missing." }
if (-not $bootstrap.cookies) { throw "bootstrap.cookies missing." }
Write-Host "Bootstrap OK"

Write-Host "[3/5] POST /auth/refresh"
$refreshBody = @{ refreshToken = $login.refreshToken } | ConvertTo-Json
$refresh = Invoke-RestMethod -Method Post -Uri "$BaseUrl/auth/refresh" -ContentType "application/json" -Body $refreshBody
if (-not $refresh.accessToken) { throw "refresh.accessToken missing." }
if (-not $refresh.refreshToken) { throw "refresh.refreshToken missing." }
Write-Host "Refresh OK"

$headers2 = @{ Authorization = "Bearer $($refresh.accessToken)" }
$selectedTrackingNo = $TrackingNo.Trim()
$trackingSource = "manual"
$blockedCode = $null
$blockedMessage = $null

if ([string]::IsNullOrWhiteSpace($selectedTrackingNo)) {
    if ($AutoDiscoverTracking) {
        Write-Host "[3.5/5] GET /reservations?mode=standard (discover tracking)"
        $found = Get-FirstReservationTrackingNo -ApiBaseUrl $BaseUrl -Headers $headers2 -Mode "standard"
        if (-not $found) {
            Write-Host "[3.5/5] GET /reservations?mode=bulk (discover tracking)"
            $found = Get-FirstReservationTrackingNo -ApiBaseUrl $BaseUrl -Headers $headers2 -Mode "bulk"
        }

        if ($found) {
            $selectedTrackingNo = $found.trackingNo
            $trackingSource = $found.source
            Write-Host "Discovered trackingNo: $selectedTrackingNo (source=$trackingSource)"
        } else {
            $trackingSource = "none"
            $blockedCode = "UAT_DATA_BLOCKED"
            $blockedMessage = "no shipment tracking found"
            Write-Warning "${blockedCode}: $blockedMessage"
        }
    } else {
        $trackingSource = "none"
        $blockedCode = "UAT_DATA_BLOCKED"
        $blockedMessage = "trackingNo not provided and auto discovery disabled"
        Write-Warning "${blockedCode}: $blockedMessage"
    }
}

if (-not $blockedCode) {
    Write-Host "[4/5] GET /shipments/$selectedTrackingNo"
    $shipment = Invoke-RestMethod -Method Get -Uri "$BaseUrl/shipments/$selectedTrackingNo" -Headers $headers2
    if (-not $shipment.trackingNo) { throw "shipment.trackingNo missing." }
    Write-Host "Shipment OK"
}

Write-Host "[5/5] POST /auth/logout"
$logoutBody = @{ refreshToken = $refresh.refreshToken } | ConvertTo-Json
$logout = Invoke-RestMethod -Method Post -Uri "$BaseUrl/auth/logout" -Headers $headers2 -ContentType "application/json" -Body $logoutBody
Write-Host "Logout result: revoked=$($logout.revoked)"

$summary = @{
    trackingSource = $trackingSource
    selectedTrackingNo = $selectedTrackingNo
    status = if ($blockedCode) { "BLOCKED" } else { "PASS" }
} | ConvertTo-Json -Compress

Write-Host "Result summary: $summary"

if ($blockedCode) {
    throw "${blockedCode}: $blockedMessage"
}

Write-Host "Wave2 UAT smoke completed."
