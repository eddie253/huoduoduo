# TRACEABILITY: 42 API Execution Matrix

Doc ID: HDD-DOC-ARCHITECTURE-PLAN24-42API-TRACEABILITY-42-MATRIX-EXECUTION-EN
Version: v1.0
Owner: Project Lead
Last Updated: 2026-03-04
Review Status: Draft
CN/EN Pair Link: docs/architecture/plan24_42api/TRACEABILITY_42_MATRIX_EXECUTION.zh-TW.md

1. CN: `docs/architecture/plan24_42api/TRACEABILITY_42_MATRIX_EXECUTION.zh-TW.md`
2. EN: `docs/architecture/plan24_42api/TRACEABILITY_42_MATRIX_EXECUTION.en.md`

## 1. Notes
1. This is the execution matrix for P4~P9 rollout tracking.
2. The source-of-truth master remains `LEGACY_API_42_STATUS_MATRIX_20260303.*`; this file focuses on execution phase and status transitions.

## 2. 42-Method Traceability Table
| # | Legacy Method | BFF / Alternative Path | Status | Execution Phase |
|---|---|---|---|---|
| 1 | GetLogin | POST /v1/auth/login | implemented | P1 |
| 2 | UpdateRegID | POST /v1/push/register | implemented | P1 |
| 3 | DeleteRegID | POST /v1/push/unregister | implemented | P9 |
| 4 | UpdateBank | WebView currency/bank.aspx | waived | P6-review |
| 5 | AddOrder_elf | - | deferred | P8 |
| 6 | BackOrder | - | deferred | P8 |
| 7 | GetShipment | GET /v1/shipments/{trackingNo} fallback | implemented | P2 |
| 8 | GetShipment_elf | GET /v1/shipments/{trackingNo} primary | implemented | P2 |
| 9 | GetShipment_Currency | GET /v1/currency/shipment | implemented | P6 |
| 10 | UpdateArrivalErr_NEW | POST /v1/shipments/{trackingNo}/exception | implemented | P2 |
| 11 | UpdateArrivalErr_Multi_NEW | - | deferred | P8 |
| 12 | ClearArrival | - | deferred | P8 |
| 13 | UpdateArrival | POST /v1/shipments/{trackingNo}/delivery | implemented | P2 |
| 14 | UpdateArrival_Multi | - | deferred | P8 |
| 15 | Alr_Order | - | deferred | P8 |
| 16 | Alr_Shipment | - | deferred | P8 |
| 17 | CreatePath | - | deferred | P8 |
| 18 | CheckedArrivalErr | - | deferred | P8 |
| 19 | GetDriverCurrency | GET /v1/currency/daily | implemented | P6 |
| 20 | GetDriverCurrencyMonth | GET /v1/currency/monthly | implemented | P6 |
| 21 | GetDriverBalance | GET /v1/currency/balance | implemented | P6 |
| 22 | ApplyWithDrawal | WebView currency/wda.aspx | waived | P6-review |
| 23 | GetDeposit_Head | GET /v1/currency/deposit/head | implemented | P6 |
| 24 | GetDeposit_Body | GET /v1/currency/deposit/body | implemented | P6 |
| 25 | GetARV_ZIP | GET /v1/reservations/zip-areas | implemented | P7 |
| 26 | GetARV | GET /v1/reservations/available | implemented | P7 |
| 27 | GetARVed | GET /v1/reservations?mode=standard | implemented | P3 |
| 28 | UpdateARV | POST /v1/reservations?mode=standard | implemented | P3 |
| 29 | RemoveARV | DELETE /v1/reservations/{id}?mode=standard | implemented | P3 |
| 30 | GetAreaCode | GET /v1/reservations/area-codes | implemented | P7 |
| 31 | GetArrived | GET /v1/reservations/arrived | implemented | P7 |
| 32 | GetBARV | GET /v1/reservations/available/bulk | implemented | P7 |
| 33 | GetBARVed | GET /v1/reservations?mode=bulk | implemented | P3 |
| 34 | UpdateBARV | POST /v1/reservations?mode=bulk | implemented | P3 |
| 35 | RemoveBARV | DELETE /v1/reservations/{id}?mode=bulk | implemented | P3 |
| 36 | GetPxymate | GET /v1/proxy/mates | implemented | P5 |
| 37 | SearchKPI | GET /v1/proxy/kpi/search | implemented | P5 |
| 38 | GetKPI | GET /v1/proxy/kpi | implemented | P5 |
| 39 | GetKPI_dis | GET /v1/proxy/kpi/daily | implemented | P5 |
| 40 | GetSystemDate | - | deferred | P8 |
| 41 | GetVersion | GET /v1/system/version?name=... | implemented | P9 |
| 42 | GetBulletin | GET /v1/bootstrap/bulletin | implemented | P1 |

## 3. Execution Rules
1. Every method must remain traceable and cannot become unknown.
2. waived -> implemented conversion requires an API contract and test cases first.
3. deferred items can enter implementation only after P8 go/no-go decisions.

## 4. P8 Deferred Governance Decision Snapshot
1. Decision source: `docs/architecture/plan24_42api/DEFERRED_P8_GO_NO_GO_TABLE.en.md`.
2. Deferred methods governed: `12/12`.
3. `No-Go`: `10`.
4. `Conditional-Go`: `2` (`DeleteRegID`, `GetVersion`).
5. No deferred item is auto-promoted to implemented in P8.

## 5. P9 Conditional-Go Execution Outcome
1. `DeleteRegID` is implemented as `POST /v1/push/unregister`.
2. `GetVersion` is implemented as `GET /v1/system/version?name=...`.
3. Remaining deferred set is `10` methods.

## Acceptance Checklist

- [ ] AC-01: ?豲?????韏航???擳揚
  - Command: rg -n "Doc ID|Version|Owner|Last Updated|Review Status|CN/EN Pair Link" 
../docs/architecture/plan24_42api/TRACEABILITY_42_MATRIX_EXECUTION.en.md
  - Expected Result: ??謘?豯血???????????秋???????
  - Failure Action: ??嗾??擗???????蝬踐ㄡ??豲??

- [ ] AC-02: Docker ?????????蝘???
  - Command: docker --version
  - Expected Result: ??????Docker ???脩壯?????
  - Failure Action: ?鞈? Docker Desktop ?蝬踐ㄡ??豲??

- [ ] AC-03: PowerShell fallback ??蝘???
  - Command: Get-Content ../docs/architecture/plan24_42api/TRACEABILITY_42_MATRIX_EXECUTION.en.md -TotalCount 20
  - Expected Result: ?????鞈??雓??豯????啾???
  - Failure Action: ?鞈?僱擗????雓??嚚???豰???????
