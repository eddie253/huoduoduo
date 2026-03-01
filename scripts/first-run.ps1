param(
    [string]$AvdName = "didi_api34",
    [string]$PackageName = "didi.app.express",
    [string]$MainActivity = "didi.app.express/.MainActivity"
)

$ErrorActionPreference = "Stop"

function Resolve-SdkDir {
    $localProps = Join-Path $PSScriptRoot "..\local.properties"
    if (-not (Test-Path $localProps)) {
        throw "local.properties not found: $localProps"
    }

    $sdkLine = Get-Content $localProps | Where-Object { $_ -match "^sdk\.dir=" } | Select-Object -First 1
    if (-not $sdkLine) {
        throw "sdk.dir not found in local.properties"
    }

    $raw = $sdkLine -replace "^sdk\.dir=", ""
    return $raw -replace "\\\\", "\"
}

function Resolve-JavaHome {
    param(
        [string[]]$Candidates
    )

    foreach ($candidate in $Candidates) {
        if (Test-Path (Join-Path $candidate "bin\java.exe")) {
            return $candidate
        }
    }

    return $null
}

$sdkDir = Resolve-SdkDir
$adb = Join-Path $sdkDir "platform-tools\adb.exe"
$emulator = Join-Path $sdkDir "emulator\emulator.exe"
$avdmanager = Join-Path $sdkDir "cmdline-tools\latest\bin\avdmanager.bat"

if (-not (Test-Path $adb)) { throw "adb not found: $adb" }
if (-not (Test-Path $emulator)) { throw "emulator not found: $emulator" }
if (-not (Test-Path $avdmanager)) { throw "avdmanager not found: $avdmanager" }

$jdk8 = Resolve-JavaHome -Candidates @(
    "C:\Program Files\Eclipse Adoptium\jdk-8.0.482.8-hotspot",
    "C:\Program Files\Java\jdk1.8.0_202",
    "C:\Program Files\Java\jdk1.8.0_181"
)

$jdk17 = Resolve-JavaHome -Candidates @(
    "C:\Program Files\Eclipse Adoptium\jdk-17.0.18.8-hotspot",
    "C:\Program Files\Eclipse Adoptium\jdk-17.0.10.7-hotspot"
)

if (-not $jdk8) {
    throw "JDK 8 not found. Install Temurin 8 JDK."
}

if (-not $jdk17) {
    throw "JDK 17 not found. Install Temurin 17 JDK."
}

Write-Host "Using SDK: $sdkDir"
Write-Host "Using JDK8: $jdk8"
Write-Host "Using JDK17: $jdk17"

$env:JAVA_HOME = $jdk17
$env:Path = "$env:JAVA_HOME\bin;$env:Path"

# Ensure AVD exists.
$avdList = & $avdmanager list avd
if (-not ($avdList -match "Name:\s+$AvdName")) {
    Write-Host "AVD '$AvdName' not found, creating..."
    "no" | & $avdmanager create avd -n $AvdName -k "system-images;android-34;google_apis;x86_64" -d pixel_4 | Out-Null
}

# Boot emulator if not already available.
$deviceList = & $adb devices
if (-not ($deviceList -match "emulator-\d+\s+device")) {
    Write-Host "Starting emulator '$AvdName'..."
    Start-Process -FilePath $emulator -ArgumentList "-avd $AvdName -no-snapshot -no-boot-anim -gpu swiftshader_indirect -no-audio" | Out-Null
}

Write-Host "Waiting for emulator..."
& $adb wait-for-device | Out-Null

$booted = $false
for ($i = 0; $i -lt 90; $i++) {
    $status = (& $adb shell getprop sys.boot_completed 2>$null).Trim()
    if ($status -eq "1") {
        $booted = $true
        break
    }
    Start-Sleep -Seconds 3
}

if (-not $booted) {
    throw "Emulator boot timeout."
}

Write-Host "Emulator is ready."

# Build/install with JDK8 for this legacy AGP setup.
$env:JAVA_HOME = $jdk8
$env:Path = "$env:JAVA_HOME\bin;$env:Path"

Push-Location (Join-Path $PSScriptRoot "..")
try {
    & .\gradlew.bat :app:installDebug
} finally {
    Pop-Location
}

& $adb shell am start -n $MainActivity | Out-Null
Write-Host "App launched: $PackageName"
