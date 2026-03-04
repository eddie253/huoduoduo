# API Spec Guide (OpenAPI Baseline)

Doc ID: `HDD-OPENAPI-GUIDE`
Version: `v1.3`
Owner: `BFF Lead`
Last Updated: 2026-03-05
Review Status: In Review
CN/EN Pair Link: docs/architecture/API_SPEC_OPENAPI_PLAN24.zh-TW.md






1. CN: `docs/architecture/API_SPEC_OPENAPI_PLAN24.zh-TW.md`
2. EN: `docs/architecture/API_SPEC_OPENAPI_PLAN24.en.md`

## 1. Purpose
1. Summarize PLAN24-P0 governance changes in `contracts/openapi/huoduoduo-v1.openapi.yaml`.
2. Provide a management-readable view without requiring full YAML review.

## 2. Contract source
1. Source file: `contracts/openapi/huoduoduo-v1.openapi.yaml`
2. Version: `info.version = 0.2.5`
3. P0/P1 governance metadata added: `x-doc-id/x-owner/x-last-updated/x-review-status/x-language-pair`

## 3. P0/P1/P2/P3 focus changes
1. Added response field length constraints: `maxLength/maxItems`.
2. Applied across Health/Auth/Bootstrap/Push/Shipments/Reservations/ErrorResponse.
3. No endpoint behavior changes, contract-only convergence.
4. P1 request/response contract enforcement is implemented for Auth/Bootstrap/Push.
5. P2 shipment response contract enforcement and delivery/exception request max-length validation are implemented.
6. P3 reservation response contract enforcement and create/delete request max-length validation are implemented.

## 4. Field-length baseline
| Category | Rule |
|---|---|
| ID/code/role | `64` |
| name/service | `128` |
| message | `1024` |
| URL | `2048` |
| fileName/path | `255` |
| lat/lng | `32` (per field) |
| datetime | `40` |
| reservation shipmentNos | `maxItems: 200` |

## 5. Related documents
1. `docs/architecture/API_GOVERNANCE_PHASED_SPEC_PLAN24.en.md`
2. `contracts/legacy/soap-mapping-v1.en.md`
3. `contracts/legacy/error-code-mapping-v1.en.md`
4. `docs/architecture/CONTRACT_VERIFICATION_CHECKLIST.en.md`

