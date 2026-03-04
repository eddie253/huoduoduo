# PLAN24 API Document Inventory (English)

Doc ID: `HDD-PLAN24-API-INVENTORY`
Version: `v1.4`
Owner: `Architecture Lead`
Last Updated: 2026-03-05
Review Status: In Review
CN/EN Pair Link: docs/architecture/API_DOCUMENT_INVENTORY_PLAN24.zh-TW.md






1. CN: `docs/architecture/API_DOCUMENT_INVENTORY_PLAN24.zh-TW.md`
2. EN: `docs/architecture/API_DOCUMENT_INVENTORY_PLAN24.en.md`

Date: 2026-03-03 (Asia/Taipei)

## 1. Inventory scope
1. API contract artifacts (OpenAPI, REST<->SOAP mapping, error-code mapping, verification checklist).
2. Legacy APK source verification (`app/src/main/java/network/*.java`) against current mapping coverage.
3. Documentation governance requirements (bilingual CN/EN, owner/version/review metadata).

## 2. Current API document set

| Document | Path | Language | Purpose | Governance Status |
|---|---|---|---|---|
| OpenAPI contract | `contracts/openapi/huoduoduo-v1.openapi.yaml` | English (machine contract) | REST source of truth | Metadata + length rules added (`0.2.5`) |
| OpenAPI guide (CN) | `docs/architecture/API_SPEC_OPENAPI_PLAN24.zh-TW.md` | Chinese | Governance-readable contract summary | Added |
| OpenAPI guide (EN) | `docs/architecture/API_SPEC_OPENAPI_PLAN24.en.md` | English | English companion | Added |
| Legacy SOAP mapping | `contracts/legacy/soap-mapping-v1.md` | English compatibility file | Baseline mapping entry | Governance header added |
| Legacy SOAP mapping (CN/EN) | `contracts/legacy/soap-mapping-v1.zh-TW.md` / `.en.md` | Bilingual | Formal review versions | Added |
| Error-code mapping (CN/EN) | `contracts/legacy/error-code-mapping-v1.zh-TW.md` / `.en.md` | Bilingual | Error normalization + overflow policy | Added |
| Contract checklist (CN/EN) | `docs/architecture/CONTRACT_VERIFICATION_CHECKLIST.zh-TW.md` / `.en.md` | Bilingual | CI and governance gate | Added |
| Legacy app API spec (CN/EN) | `docs/architecture/LEGACY_APP_API_SPEC_FINAL.zh-TW.md` / `.en.md` | Bilingual | Final legacy API spec baseline | Existing |
| Legacy 42-method status matrix (CN/EN) | `docs/architecture/LEGACY_API_42_STATUS_MATRIX_20260303.zh-TW.md` / `.en.md` | Bilingual | 42-method governance baseline | Updated columns |

## 3. Governance status
1. Required header metadata is applied in core files:
   1. `Doc ID`
   2. `Version`
   3. `Owner`
   4. `Last Updated`
   5. `Review Status`
   6. `CN/EN Pair Link`
2. P0 bilingual coverage is complete for core API governance docs.
3. OpenAPI now includes P0 `maxLength`/`maxItems` baseline.
4. 42 legacy methods are fully classified with no `unknown` rows.

## 4. Legacy API verification conclusion
1. Legacy Android `network` module contains 42 SOAP methods.
2. All SOAP methods target `https://old.huoduoduo.com.tw/Inquiry/didiservice.asmx`.
3. P0 classifies all 42 methods into `implemented/waived/deferred` with `reason/owner/target milestone`.

## 5. P1 status addendum
1. Request/response contract enforcement is implemented for Auth/Bootstrap/Push.
2. Overflow handling follows P0 policy (critical fields reject, display text truncate).

## 6. P2 status addendum
1. Shipment response contract enforcement is implemented.
2. Delivery/exception request max-length validation is implemented (over-length -> `400`).

## 7. P3 status addendum
1. Reservation response contract enforcement and `maxItems` validation are implemented.
2. Reservation create/delete request max-length validation is implemented (over-length -> `400`).

## 8. P0 handoff recommendation
1. Use Chinese docs for management sign-off and English docs for cross-team communication.
2. Keep CN/EN pairs on the same version whenever one side changes.
3. Run contract gate commands from checklist before P1 implementation starts.

