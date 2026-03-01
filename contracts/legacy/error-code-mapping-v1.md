# Error Code Mapping v1

## Scope

This document standardizes error mapping between:

1. Legacy SOAP transport/business responses.
2. BFF normalized REST errors.
3. Flutter WebView bridge errors.

## Legacy SOAP -> BFF mapping

| Source Condition | BFF HTTP Status | BFF `code` | Notes |
|---|---|---|---|
| SOAP request aborted / timeout / network failure | `502` | `LEGACY_TIMEOUT` | Returned by `SoapTransportService` |
| SOAP HTTP non-200 / invalid XML / missing method result | `502` | `LEGACY_BAD_RESPONSE` | Transport/protocol parsing failure |
| SOAP business payload starts with `Error` | `422` | `LEGACY_BUSINESS_ERROR` | Legacy domain error |

## Auth/session mapping

| Condition | HTTP Status | Code/Message |
|---|---|---|
| Invalid login credential | `401` | `UnauthorizedException` |
| Missing bearer token | `401` | `Missing bearer token.` |
| Invalid bearer token | `401` | `Invalid bearer token.` |
| Refresh token missing/revoked/expired/replayed | `403` (current) | `Refresh token revoked or expired.` |
| Redis token store unavailable | `503` | `Token store unavailable.` |

## Bridge mapping (WebView shell)

| Condition | Bridge Error Code | Notes |
|---|---|---|
| Payload missing/invalid format | `BRIDGE_INVALID_PAYLOAD` | `BridgeMessage.fromDynamic` parse fails |
| Unknown bridge method | `BRIDGE_UNSUPPORTED_METHOD` | Method not in v1 allowlist |
| Method denied due missing native wiring/permission | `BRIDGE_PERMISSION_DENIED` | e.g. `openfile` placeholder |
| Unexpected handler exception | `BRIDGE_RUNTIME_ERROR` | Catch-all runtime protection |

## Smoke test result classification

| Scenario | Classification |
|---|---|
| Full path passes login/bootstrap/refresh/shipment/logout | `PASS` |
| No discoverable shipment in reservations (standard+bulk) | `BLOCKED` + `UAT_DATA_BLOCKED` |
| API/transport failure | `FAIL` (with mapped BFF code) |
