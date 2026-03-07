# BFF Gateway

This service is the transitional BFF for the Flutter migration:

- Provides REST endpoints under `/v1`
- Issues short-lived JWT access tokens and rotating refresh tokens
- Adapts calls to legacy SOAP services
- Provides WebView bootstrap metadata (base URL + cookies)

## Local run (from repo root)

```bash
npm ci
npm run bff:dev
```

Use local `.env` for development. Keep `.env.example` as template only (no real values).

## Local verification (from repo root)

```bash
npm run bff:verify
```

## Coverage (Jest v8)

```bash
npm run bff:test:coverage
```

Coverage artifacts are generated in:

- `apps/bff_hdd/coverage/` (raw)
- `reports/coverage/bff/` (collected)

## UAT smoke (from repo root)

### Manual tracking number

```bash
powershell -ExecutionPolicy Bypass -File .\scripts\run-wave2-uat-smoke.ps1 `
  -Account "<UAT_ACCOUNT>" `
  -Password "<UAT_PASSWORD>" `
  -TrackingNo "<TRACKING_NO>"
```

### Auto-discover tracking number (default)

```bash
powershell -ExecutionPolicy Bypass -File .\scripts\run-wave2-uat-smoke.ps1 `
  -Account "<UAT_ACCOUNT>" `
  -Password "<UAT_PASSWORD>"
```

The script first runs login/bootstrap/refresh, then discovers shipment tracking number from:

1. `GET /v1/reservations?mode=standard`
2. `GET /v1/reservations?mode=bulk` (fallback)

If no tracking number is found, it returns `UAT_DATA_BLOCKED` and still executes logout.

### Container-based option (dev mode)

```bash
docker compose -f ops/docker/docker-compose.yml --profile dev up -d
powershell -ExecutionPolicy Bypass -File .\scripts\run-wave2-uat-smoke.ps1 `
  -Account "<UAT_ACCOUNT>" `
  -Password "<UAT_PASSWORD>"
docker compose -f ops/docker/docker-compose.yml --profile dev down
```

## Container image build (deployment)

`ops/docker/docker-compose.yml` is a development setup that mounts source code and runs `start:dev`.
For deployment image build, use `apps/bff_hdd/Dockerfile`.

Build from repo root:

```bash
docker build -f apps/bff_hdd/Dockerfile -t hdd/bff-hdd:latest .
```

Run container:

```bash
docker run --rm -p 3000:3000 --env-file apps/bff_hdd/.env.example hdd/bff-hdd:latest
```

Or run with compose prod profile:

```bash
docker compose -f ops/docker/docker-compose.yml --profile prod up -d --build
docker compose -f ops/docker/docker-compose.yml --profile prod down
```

Prod profile publishes host port `3001` -> container `3000`.

## Environment variables

- `PORT` (default: `3000`)
- `JWT_SECRET` (required outside local development)
- `ACCESS_TOKEN_TTL_SECONDS` (default: `900`)
- `REFRESH_TOKEN_TTL_SECONDS` (default: `604800`)
- `SOAP_BASE_URL` (default: `https://old.huoduoduo.com.tw`)
- `SOAP_NAMESPACE` (default: `https://driver.huoduoduo.com.tw/`)
- `SOAP_PATH` (default: `/Inquiry/didiservice.asmx`)
- `SOAP_TIMEOUT_MS` (default: `15000`)
- `WEBVIEW_BASE_URL` (default: `https://app.elf.com.tw/cn/entrust.aspx?IDCompany=S1`)
- `WEBVIEW_REGISTER_URL` (default: `https://old.huoduoduo.com.tw/register/register.aspx`)
- `WEBVIEW_RESET_URL` (default: `https://old.huoduoduo.com.tw/register/register_resetpwd.aspx`)
- `WEBVIEW_COOKIE_DOMAIN` (default: `old.huoduoduo.com.tw`)
- `REDIS_URL` (default: `redis://localhost:6379`)

## Redis keys

- Idempotency dedup: `idem:{delivery:<trackingNo>}:{<idempotencyKey>}`
- Exception dedup: `idem:{exception:<trackingNo>}:{<idempotencyKey>}`
- Order accept dedup: `idem:{order_accept:<trackingNo>}:{<idempotencyKey>}`
- Driver location queue: `driver-location:<trackingNo>`
- Driver location pending index: `driver-location:pending-keys`

## New endpoints (PLAN29)

- `POST /v1/orders/{trackingNo}/accept` (`X-Idempotency-Key` required)
- `POST /v1/drivers/location`
- `POST /v1/drivers/location/batch` (max 20)

### Required minimum for Wave 2 UAT

- `SOAP_BASE_URL`
- `SOAP_NAMESPACE`
- `SOAP_PATH`
- `WEBVIEW_BASE_URL`
- `WEBVIEW_REGISTER_URL`
- `WEBVIEW_RESET_URL`
- `REDIS_URL`
