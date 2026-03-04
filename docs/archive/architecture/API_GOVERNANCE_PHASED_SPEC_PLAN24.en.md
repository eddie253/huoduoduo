# PLAN24 Phased API Governance Specification (P0~P4)

Doc ID: `HDD-PLAN24-PHASED-GOV`
Version: `v1.4`
Owner: `Architecture Lead`
Last Updated: 2026-03-05
Review Status: Archived
CN/EN Pair Link: N/A






1. CN: `docs/architecture/API_GOVERNANCE_PHASED_SPEC_PLAN24.zh-TW.md`
2. EN: `docs/architecture/API_GOVERNANCE_PHASED_SPEC_PLAN24.en.md`

Date: 2026-03-03 (Asia/Taipei)
Purpose: finalize documentation and governance baseline before implementation.

## 1. Overview
1. This document defines the phased governance framework for PLAN24 (P0~P4).
2. Each phase includes:
   1. Required reference documents
   2. Backend response field-length contract rules
3. Contract rules must be enforced by:
   1. OpenAPI `maxLength/maxItems`
   2. BFF normalization (truncate/reject)
   3. verification tests

## 2. P0: Baseline freeze and documentation governance

### 2.1 P0 reference files
1. `contracts/openapi/huoduoduo-v1.openapi.yaml`
2. `contracts/legacy/soap-mapping-v1.md`
3. `contracts/legacy/error-code-mapping-v1.md`
4. `docs/architecture/LEGACY_APP_API_SPEC_FINAL.zh-TW.md`
5. `docs/architecture/LEGACY_API_42_STATUS_MATRIX_20260303.zh-TW.md`
6. `docs/architecture/CONTRACT_VERIFICATION_CHECKLIST.zh-TW.md`

### 2.2 P0 response-length baseline (general)
| Field Type | Contract Rule |
|---|---|
| `UUID/ID` strings | `maxLength: 64` |
| `code/status/role` | `maxLength: 64` |
| `name/service` | `maxLength: 128` |
| `message` | `maxLength: 1024` |
| `URL` | `maxLength: 2048` |
| `fileName` | `maxLength: 255` |
| `path` | `maxLength: 255` |
| `lat,lng` string | `maxLength: 64` |
| ISO8601 datetime string | `maxLength: 40` |

## 3. P1: Auth / Bootstrap / Push contract convergence

Status: `implemented (2026-03-03)`

### 3.1 P1 reference files
1. `contracts/openapi/huoduoduo-v1.openapi.yaml`
2. `apps/bff_gateway/src/modules/auth/*`
3. `apps/bff_gateway/src/modules/webview/*`
4. `apps/bff_gateway/src/modules/notification/*`
5. `contracts/legacy/soap-mapping-v1.md`

### 3.2 P1 response-length rules
| Endpoint | Response Field | Contract Rule |
|---|---|---|
| `POST /v1/auth/login` | `accessToken` | `maxLength: 4096` |
|  | `refreshToken` | `maxLength: 1024` |
|  | `user.id` | `maxLength: 64` |
|  | `user.contractNo` | `maxLength: 64` |
|  | `user.name` | `maxLength: 128` |
|  | `user.role` | `maxLength: 32` |
|  | `webviewBootstrap.baseUrl` | `maxLength: 2048` |
|  | `webviewBootstrap.registerUrl` | `maxLength: 2048` |
|  | `webviewBootstrap.resetPasswordUrl` | `maxLength: 2048` |
|  | `webviewBootstrap.cookies[].name` | `maxLength: 64` |
|  | `webviewBootstrap.cookies[].value` | `maxLength: 4096` |
|  | `webviewBootstrap.cookies[].domain` | `maxLength: 255` |
|  | `webviewBootstrap.cookies[].path` | `maxLength: 255` |
| `POST /v1/auth/refresh` | `accessToken` | `maxLength: 4096` |
|  | `refreshToken` | `maxLength: 1024` |
| `POST /v1/auth/logout` | `subject` | `maxLength: 64` |
| `GET /v1/bootstrap/bulletin` | `message` | `maxLength: 2000` |
|  | `updatedAt` | `maxLength: 40` |
| `POST /v1/push/register` | `registeredAt` | `maxLength: 40` |

### 3.3 P1 implementation notes
1. Request DTO max-length validation is enforced for `Auth/Bootstrap/Push`.
2. Service-layer overflow policy is active:
   1. critical structural fields: reject with `LEGACY_BAD_RESPONSE`.
   2. display text fields: truncate (`user.name`, bulletin `message`).
3. OpenAPI version is bumped from `0.2.2` to `0.2.3` (patch).

## 4. P2: Shipment contract convergence

Status: `implemented (2026-03-04)`

### 4.1 P2 reference files
1. `contracts/openapi/huoduoduo-v1.openapi.yaml`
2. `apps/bff_gateway/src/modules/shipment/*`
3. `apps/bff_gateway/src/adapters/soap/legacy-soap.client.ts`
4. `contracts/legacy/soap-mapping-v1.md`

### 4.2 P2 response-length rules
| Endpoint | Response Field | Contract Rule |
|---|---|---|
| `GET /v1/shipments/{trackingNo}` | `trackingNo` | `maxLength: 32` |
|  | `recipient` | `maxLength: 128` |
|  | `address` | `maxLength: 512` |
|  | `phone` | `maxLength: 32` |
|  | `mobile` | `maxLength: 32` |
|  | `zipCode` | `maxLength: 16` |
|  | `city` | `maxLength: 64` |
|  | `district` | `maxLength: 64` |
|  | `status` | `maxLength: 64` |
|  | `signedAt` | `maxLength: 40` |
|  | `signedImageFileName` | `maxLength: 255` |
|  | `signedLocation` | `maxLength: 64` |
| `POST /v1/shipments/{trackingNo}/delivery` | `ok` | `boolean` |
| `POST /v1/shipments/{trackingNo}/exception` | `ok` | `boolean` |

### 4.3 P2 implementation notes
1. `ShipmentService.getShipment` enforces response contract limits.
2. `trackingNo/contractNo` request-side length checks are enforced before delivery/exception submit.
3. P2-related `MaxLength` validation is added to delivery/exception request DTOs.
4. OpenAPI version is updated to `0.2.4`.

## 5. P3: Reservation contract convergence

Status: `implemented (2026-03-04)`

### 5.1 P3 reference files
1. `contracts/openapi/huoduoduo-v1.openapi.yaml`
2. `apps/bff_gateway/src/modules/reservation/*`
3. `contracts/legacy/soap-mapping-v1.md`
4. `docs/architecture/LEGACY_API_42_STATUS_MATRIX_20260303.zh-TW.md`

### 5.2 P3 response-length rules
| Endpoint | Response Field | Contract Rule |
|---|---|---|
| `GET /v1/reservations` | `[].reservationNo` | `maxLength: 64` |
|  | `[].address` | `maxLength: 512` |
|  | `[].shipmentNos[]` | `maxLength(each): 64` |
|  | `[].shipmentNos` | `maxItems: 200` |
|  | `[].mode` | `maxLength: 16` (`standard|bulk`) |
| `POST /v1/reservations` | `reservationNo` | `maxLength: 64` |
|  | `mode` | `maxLength: 16` |
| `DELETE /v1/reservations/{id}` | `ok` | `boolean` |

### 5.3 P3 implementation notes
1. Reservation list/create response contract enforcement is implemented (length, `maxItems`, mode validity).
2. Request DTO hardening is added for create/delete (`MaxLength`, `ArrayMaxSize`).
3. `DELETE /reservations/:id` now uses path param DTO validation (over-length -> `400`).
4. OpenAPI version is updated to `0.2.5`.

## 6. P4: Cross-cutting (Error/Health/Verification)

### 6.1 P4 reference files
1. `contracts/openapi/huoduoduo-v1.openapi.yaml`
2. `contracts/legacy/error-code-mapping-v1.md`
3. `docs/architecture/CONTRACT_VERIFICATION_CHECKLIST.zh-TW.md`
4. `ops/ci/check-route-diff.js`
5. `ops/ci/check-error-code-map.js`

### 6.2 P4 response-length rules
| Endpoint/Schema | Response Field | Contract Rule |
|---|---|---|
| `ErrorResponse` | `code` | `maxLength: 64` |
|  | `message` | `maxLength: 1024` |
| `GET /v1/health` | `status` | `maxLength: 32` |
|  | `service` | `maxLength: 64` |
|  | `timestamp` | `maxLength: 40` |

## 7. Pre-implementation deliverables
1. `API_GOVERNANCE_PHASED_SPEC_PLAN24.zh-TW.md` (this spec pair)
2. `LEGACY_APP_API_SPEC_FINAL.zh-TW.md` / `.en.md`
3. `LEGACY_API_42_STATUS_MATRIX_20260303.zh-TW.md` / `.en.md`
4. `API_DOCUMENT_INVENTORY_PLAN24.zh-TW.md` / `.en.md`
5. `CONTRACT_VERIFICATION_CHECKLIST.zh-TW.md` / `.en.md`

## 8. Pre-implementation confirmation checklist
1. Are these length rules accepted as formal OpenAPI contract?
2. Are `waived` items explicitly kept on WebView path (no new BFF API)?
3. Should `implemented but unused` items be wired by Flutter in next phase?

## Acceptance Checklist

- [ ] AC-01: Governance header is complete
  - Command: Get-Content "docs/archive/architecture/API_GOVERNANCE_PHASED_SPEC_PLAN24.en.md" -Encoding UTF8 -TotalCount 40
  - Expected Result: six governance fields are visible.
  - Failure Action: add missing governance fields and rerun.

- [ ] AC-02: Command rerun capability
  - Command: docker compose -f ops/docker/docker-compose.yml config
  - Expected Result: no error.
  - Failure Action: use PowerShell fallback (Get-Content, Select-String) to verify file state.

## Governance Waiver

- Reason: historical document retained for traceability under archive_waiver policy.
- Owner: Architecture Lead
- Original Date: N/A
- Retention: long-term archive retention.
- Reactivation Trigger: audit or historical trace request.

