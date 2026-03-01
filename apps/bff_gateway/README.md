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

### Container-based option (legacy)

```bash
docker compose -f ops/docker/docker-compose.yml up -d
powershell -ExecutionPolicy Bypass -File .\scripts\run-wave2-uat-smoke.ps1 `
  -Account "<UAT_ACCOUNT>" `
  -Password "<UAT_PASSWORD>"
docker compose -f ops/docker/docker-compose.yml down
```

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

### Required minimum for Wave 2 UAT

- `SOAP_BASE_URL`
- `SOAP_NAMESPACE`
- `SOAP_PATH`
- `WEBVIEW_BASE_URL`
- `WEBVIEW_REGISTER_URL`
- `WEBVIEW_RESET_URL`
- `REDIS_URL`
