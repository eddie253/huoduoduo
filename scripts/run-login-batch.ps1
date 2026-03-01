param(
    [Parameter(Mandatory = $false)]
    [string]$CsvPath = ".\testdata\accounts.csv",

    [Parameter(Mandatory = $false)]
    [string]$DeviceId,

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "reports"
)

$ErrorActionPreference = "Stop"

function Resolve-SdkDir {
    $localProps = Join-Path $PSScriptRoot "..\local.properties"
    if (-not (Test-Path $localProps)) {
        throw "local.properties not found: $localProps"
    }

    $line = Get-Content $localProps | Where-Object { $_ -match "^sdk\.dir=" } | Select-Object -First 1
    if (-not $line) {
        throw "sdk.dir not found in local.properties"
    }

    $sdk = $line -replace "^sdk\.dir=", ""
    return $sdk -replace "\\\\", "\"
}

function Resolve-Jdk8 {
    $candidates = @(
        "C:\Program Files\Eclipse Adoptium\jdk-8.0.482.8-hotspot",
        "C:\Program Files\Java\jdk1.8.0_202",
        "C:\Program Files\Java\jdk1.8.0_181"
    )
    foreach ($candidate in $candidates) {
        if (Test-Path (Join-Path $candidate "bin\java.exe")) {
            return $candidate
        }
    }
    return $null
}

function Mask-Account {
    param([string]$Account)
    if ([string]::IsNullOrWhiteSpace($Account)) { return "" }
    if ($Account.Length -le 2) { return "**" }
    if ($Account.Length -le 4) { return $Account.Substring(0, 1) + "***" }
    return $Account.Substring(0, 2) + "***" + $Account.Substring($Account.Length - 2, 2)
}

function Get-LastStatusValue {
    param(
        [string]$Text,
        [string]$Key
    )
    $pattern = "(?m)^INSTRUMENTATION_STATUS: " + [regex]::Escape($Key) + "=(.*)$"
    $matches = [regex]::Matches($Text, $pattern)
    if ($matches.Count -eq 0) { return "" }
    return $matches[$matches.Count - 1].Groups[1].Value.Trim()
}

function Get-LastResultValue {
    param(
        [string]$Text,
        [string]$Key
    )
    $pattern = "(?m)^INSTRUMENTATION_RESULT: " + [regex]::Escape($Key) + "=(.*)$"
    $matches = [regex]::Matches($Text, $pattern)
    if ($matches.Count -eq 0) { return "" }
    return $matches[$matches.Count - 1].Groups[1].Value.Trim()
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Push-Location $repoRoot

try {
    $CsvPath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $CsvPath))
    if (-not (Test-Path $CsvPath)) {
        throw "CSV not found: $CsvPath"
    }

    $cases = Import-Csv -Path $CsvPath
    if (-not $cases -or $cases.Count -eq 0) {
        throw "No test cases in CSV: $CsvPath"
    }

    $sdkDir = Resolve-SdkDir
    $adbPath = Join-Path $sdkDir "platform-tools\adb.exe"
    if (-not (Test-Path $adbPath)) {
        throw "adb not found: $adbPath"
    }

    if ([string]::IsNullOrWhiteSpace($DeviceId)) {
        $devices = & $adbPath devices | ForEach-Object { $_.Trim() } | Where-Object { $_ -match "^\S+\s+device$" } | ForEach-Object { ($_ -split "\s+")[0] }
        if (-not $devices -or $devices.Count -eq 0) {
            throw "No online Android device/emulator found."
        }
        $DeviceId = $devices[0]
    }

    $state = (& $adbPath -s $DeviceId get-state 2>$null).Trim()
    if ($state -ne "device") {
        throw "Device '$DeviceId' is not ready. Current state: $state"
    }

    $jdk8 = Resolve-Jdk8
    if (-not $jdk8) {
        throw "JDK 8 not found. Please install Temurin 8 JDK."
    }

    $env:JAVA_HOME = $jdk8
    $env:Path = "$env:JAVA_HOME\bin;$env:Path"

    Write-Host "Device: $DeviceId"
    Write-Host "SDK: $sdkDir"
    Write-Host "JDK8: $jdk8"
    Write-Host "Installing app + test APK..."

    & .\gradlew.bat :app:installDebug :app:installDebugAndroidTest | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "Gradle install tasks failed."
    }

    $OutputDir = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDir))
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportPath = Join-Path $OutputDir "login_batch_result_$timestamp.csv"
    $failuresRoot = Join-Path $OutputDir "failures"
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    New-Item -ItemType Directory -Force -Path $failuresRoot | Out-Null

    $remoteArtifactRoot = "/sdcard/Download/didi-test-artifacts"
    $permissions = @(
        "android.permission.ACCESS_FINE_LOCATION",
        "android.permission.ACCESS_COARSE_LOCATION",
        "android.permission.CAMERA",
        "android.permission.RECORD_AUDIO",
        "android.permission.READ_PHONE_STATE"
    )

    $results = @()
    $caseStatuses = @()
    $index = 0

    foreach ($case in $cases) {
        $index++

        $caseId = $case.case_id
        if ([string]::IsNullOrWhiteSpace($caseId)) {
            $caseId = "case_$index"
        }
        $safeCaseId = ($caseId -replace "[^a-zA-Z0-9._-]", "_")

        $account = [string]$case.account
        $password = [string]$case.password
        $expected = ([string]$case.expected_login).ToLower().Trim()
        $expectedMessage = [string]$case.expected_message_contains
        if ($expected -ne "pass" -and $expected -ne "fail") {
            $expected = "pass"
        }

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        Write-Host "Running case: $caseId (expected=$expected)"

        & $adbPath -s $DeviceId shell logcat -c | Out-Null
        & $adbPath -s $DeviceId shell rm -rf "$remoteArtifactRoot/$safeCaseId" | Out-Null
        & $adbPath -s $DeviceId shell mkdir -p "$remoteArtifactRoot/$safeCaseId" | Out-Null
        & $adbPath -s $DeviceId shell pm clear didi.app.express | Out-Null

        foreach ($perm in $permissions) {
            try {
                & $adbPath -s $DeviceId shell pm grant didi.app.express $perm | Out-Null
            } catch {
                # Keep going for non-grantable permissions.
            }
        }

        $instrumentOutput = ""
        $instrumentExitCode = 0
        $previousErrorAction = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            $instrumentOutput = (& $adbPath -s $DeviceId shell am instrument -w -r `
                -e class "didi.app.express.e2e.LoginCaseTest#runCase" `
                -e case_id $caseId `
                -e account $account `
                -e password $password `
                -e expected_login $expected `
                -e expected_message_contains $expectedMessage `
                -e artifact_root $remoteArtifactRoot `
                didi.app.express.test/androidx.test.runner.AndroidJUnitRunner 2>&1 | Out-String)
            $instrumentExitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $previousErrorAction
        }

        $stopwatch.Stop()

        $caseResult = Get-LastStatusValue -Text $instrumentOutput -Key "case_result"
        $caseReason = Get-LastStatusValue -Text $instrumentOutput -Key "case_reason"
        $actualLogin = (Get-LastStatusValue -Text $instrumentOutput -Key "actual_login").ToLower()
        $artifactCaseDir = Get-LastStatusValue -Text $instrumentOutput -Key "artifact_case_dir"
        $artifactScreenshot = Get-LastStatusValue -Text $instrumentOutput -Key "artifact_screenshot"
        $artifactLogcat = Get-LastStatusValue -Text $instrumentOutput -Key "artifact_logcat"

        if ([string]::IsNullOrWhiteSpace($caseResult)) {
            if ($instrumentOutput -match "(?m)^OK \(") {
                $caseResult = "PASS"
            } elseif ($instrumentExitCode -eq 0) {
                $caseResult = "PASS"
            } else {
                $caseResult = "FAIL"
            }
        }
        $casePassed = ($caseResult.ToUpper() -eq "PASS")

        if ([string]::IsNullOrWhiteSpace($actualLogin)) {
            if ($casePassed) {
                $actualLogin = $expected
            } elseif ($expected -eq "pass") {
                $actualLogin = "fail"
            } else {
                $actualLogin = "pass"
            }
        }

        if ([string]::IsNullOrWhiteSpace($caseReason) -and (-not $casePassed)) {
            $shortMsg = Get-LastResultValue -Text $instrumentOutput -Key "shortMsg"
            if (-not [string]::IsNullOrWhiteSpace($shortMsg)) {
                $caseReason = $shortMsg
            } else {
                $caseReason = "Instrumentation failed."
            }
        }

        if ([string]::IsNullOrWhiteSpace($caseReason)) {
            $caseReason = "OK"
        }

        $screenshotPath = ""
        $logcatPath = ""

        if (-not $casePassed) {
            $localCaseDir = Join-Path $failuresRoot $safeCaseId
            if (Test-Path $localCaseDir) {
                Remove-Item -Recurse -Force $localCaseDir
            }

            $remoteCaseDir = if ([string]::IsNullOrWhiteSpace($artifactCaseDir)) { "$remoteArtifactRoot/$safeCaseId" } else { $artifactCaseDir }
            try {
                & $adbPath -s $DeviceId pull $remoteCaseDir $failuresRoot | Out-Null
            } catch {
                # Keep going if artifact pull fails.
            }

            $hostLogcatPath = Join-Path $localCaseDir "host_logcat.txt"
            try {
                New-Item -ItemType Directory -Force -Path $localCaseDir | Out-Null
                & $adbPath -s $DeviceId shell logcat -d -v time -t 300 | Out-File -FilePath $hostLogcatPath -Encoding utf8
            } catch {
                # Keep going if host logcat capture fails.
            }

            if (Test-Path (Join-Path $localCaseDir "screen.png")) {
                $screenshotPath = (Join-Path $localCaseDir "screen.png")
            } elseif (-not [string]::IsNullOrWhiteSpace($artifactScreenshot)) {
                $fallbackName = Split-Path -Leaf $artifactScreenshot
                $fallbackPath = Join-Path $localCaseDir $fallbackName
                if (Test-Path $fallbackPath) {
                    $screenshotPath = $fallbackPath
                }
            }

            if (Test-Path (Join-Path $localCaseDir "logcat.txt")) {
                $logcatPath = (Join-Path $localCaseDir "logcat.txt")
            } elseif (-not [string]::IsNullOrWhiteSpace($artifactLogcat)) {
                $fallbackName = Split-Path -Leaf $artifactLogcat
                $fallbackPath = Join-Path $localCaseDir $fallbackName
                if (Test-Path $fallbackPath) {
                    $logcatPath = $fallbackPath
                }
            }

            if ([string]::IsNullOrWhiteSpace($logcatPath) -and (Test-Path $hostLogcatPath)) {
                $logcatPath = $hostLogcatPath
            }
        }

        $results += [PSCustomObject]@{
            case_id                  = $caseId
            account_masked           = (Mask-Account -Account $account)
            expected_login           = $expected
            actual_result            = $actualLogin
            reason                   = $caseReason
            duration_ms              = [int]$stopwatch.ElapsedMilliseconds
            screenshot_path          = $screenshotPath
            logcat_path              = $logcatPath
            timestamp                = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
        $caseStatuses += if ($casePassed) { "PASS" } else { "FAIL" }
    }

    $results | Export-Csv -Path $reportPath -NoTypeInformation -Encoding utf8

    $passCount = ($caseStatuses | Where-Object { $_ -eq "PASS" }).Count
    $failCount = ($caseStatuses | Where-Object { $_ -eq "FAIL" }).Count

    Write-Host "Batch completed."
    Write-Host "Report: $reportPath"
    Write-Host "Case Pass: $passCount"
    Write-Host "Case Fail: $failCount"

    if ($failCount -gt 0) {
        exit 1
    }
    exit 0
}
finally {
    Pop-Location
}
