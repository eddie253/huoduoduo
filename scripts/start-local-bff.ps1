$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $repoRoot

function Invoke-StrictCommand {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Command,
        [string]$Step
    )

    Write-Host "[$Step]"
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Step failed with exit code $LASTEXITCODE."
    }
}

function Test-RedisPing {
    param([string]$RedisCliPath)
    if (-not (Test-Path $RedisCliPath)) {
        return $false
    }
    try {
        $ping = & $RedisCliPath -h 127.0.0.1 -p 6379 ping 2>$null
        return $ping -match 'PONG'
    } catch {
        return $false
    }
}

function Ensure-BffPortAvailable {
    $listeners = Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue
    foreach ($listener in $listeners) {
        $ownerPid = $listener.OwningProcess
        $proc = Get-Process -Id $ownerPid -ErrorAction SilentlyContinue
        if ($null -ne $proc -and $proc.ProcessName -eq 'node') {
            Write-Warning "Port 3000 already used by node (PID=$ownerPid). Stopping it."
            Stop-Process -Id $ownerPid -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
            continue
        }

        $procName = if ($null -ne $proc) { $proc.ProcessName } else { 'unknown' }
        throw "Port 3000 is already in use by PID=$ownerPid ($procName). Please close it and rerun."
    }
}

$redisCli = 'C:\Program Files\Redis\redis-cli.exe'
$redisServer = 'C:\Program Files\Redis\redis-server.exe'

if (-not (Test-RedisPing -RedisCliPath $redisCli)) {
    $redisService = Get-Service -Name 'Redis' -ErrorAction SilentlyContinue
    if ($null -ne $redisService -and $redisService.Status -ne 'Running') {
        try {
            Start-Service -Name 'Redis'
            Start-Sleep -Seconds 1
        } catch {
            Write-Warning 'Cannot start Redis service automatically. Will try direct redis-server fallback.'
        }
    }
}

if (-not (Test-RedisPing -RedisCliPath $redisCli)) {
    if (Test-Path $redisServer) {
        Write-Host '[Redis] Start redis-server fallback process'
        Start-Process -FilePath $redisServer -ArgumentList '--port 6379' -WindowStyle Minimized | Out-Null
        Start-Sleep -Seconds 2
    }
}

if (-not (Test-RedisPing -RedisCliPath $redisCli)) {
    throw 'Redis is not available on 127.0.0.1:6379. Please start Redis first.'
}

Write-Host '[Redis] OK (PONG)'
Ensure-BffPortAvailable

Invoke-StrictCommand -Step 'Build BFF Dist' -Command { & ".\apps\bff_gateway\node_modules\.bin\tsc.CMD" -p apps/bff_gateway/tsconfig.build.json --incremental false }

Write-Host '[BFF] Starting on http://127.0.0.1:3000'
Write-Host '[BFF] Keep this terminal open.'
npm --workspace apps/bff_gateway run start
