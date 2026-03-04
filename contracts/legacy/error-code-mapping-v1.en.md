# Error Code Mapping v1

Doc ID: `HDD-ERROR-CODE-MAP`
Version: `v1.2`
Owner: `BFF Lead`
Last Updated: `2026-03-04`
Review Status: `Draft for management review`
CN/EN Pair Link:
1. CN: `contracts/legacy/error-code-mapping-v1.zh-TW.md`
2. EN: `contracts/legacy/error-code-mapping-v1.en.md`

## 1. Scope
This document standardizes error mapping between:
1. Legacy SOAP transport/business responses.
2. BFF normalized REST errors.
3. Flutter WebView bridge errors.
4. P0 contract-governance overflow handling.

## 2. Legacy SOAP -> BFF mapping

| Source Condition | BFF HTTP Status | BFF `code` | Notes |
|---|---|---|---|
| SOAP request aborted / timeout / network failure | `502` | `LEGACY_TIMEOUT` | Returned by `SoapTransportService` |
| SOAP HTTP non-200 / invalid XML / missing method result | `502` | `LEGACY_BAD_RESPONSE` | Transport/protocol parsing failure |
| SOAP business payload starts with `Error` | `422` | `LEGACY_BUSINESS_ERROR` | Legacy domain error |

## 3. Auth/session mapping

| Condition | HTTP Status | Code/Message |
|---|---|---|
| Invalid login credential | `401` | `UnauthorizedException` |
| Missing bearer token | `401` | `Missing bearer token.` |
| Invalid bearer token | `401` | `Invalid bearer token.` |
| Refresh token missing/revoked/expired/replayed | `403` (current) | `Refresh token revoked or expired.` |
| Redis token store unavailable | `503` | `Token store unavailable.` |

## 4. Bridge mapping (WebView shell)

| Condition | Bridge Error Code | Notes |
|---|---|---|
| Payload missing/invalid format | `BRIDGE_INVALID_PAYLOAD` | `BridgeMessage.fromDynamic` parse fails |
| Unknown bridge method | `BRIDGE_UNSUPPORTED_METHOD` | Method not in v1 allowlist |
| Method denied due missing native wiring/permission | `BRIDGE_PERMISSION_DENIED` | e.g. `openfile` placeholder |
| Unexpected handler exception | `BRIDGE_RUNTIME_ERROR` | Catch-all runtime protection |

## 5. P0 overflow normalization policy

| Field Category | Policy | Error Code |
|---|---|---|
| ID/code/role fields (`maxLength` hard contract) | Reject response | `LEGACY_BAD_RESPONSE` |
| URL/path/fileName fields | Reject response | `LEGACY_BAD_RESPONSE` |
| free-text message fields | Truncate to max contract length | none |
| arrays (`maxItems`) | Truncate to max items | none |

## 6. Smoke test result classification

| Scenario | Classification |
|---|---|
| Full path passes login/bootstrap/refresh/shipment/logout | `PASS` |
| No discoverable shipment in reservations (standard+bulk) | `BLOCKED` + `UAT_DATA_BLOCKED` |
| API/transport failure | `FAIL` (with mapped BFF code) |

## 7. P4 contract hardening note
1. Error output contract is normalized to `{ code, message }` globally.
2. `code` fallback policy:
   1. Preserve existing legacy code when valid.
   2. Fallback to `INTERNAL_SERVER_ERROR` when code is missing or exceeds contract length.
3. `message` normalization policy:
   1. Use exception message when available.
   2. Truncate to `1024` when oversized.
