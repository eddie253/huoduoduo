# PLAN24-42 API Refactor Master

Doc ID: HDD-DOC-ARCHITECTURE-PLAN24-42API-PLAN24-42API-MASTER-EN
Version: v1.0
Owner: Project Lead
Last Updated: 2026-03-05
Review Status: Archived
CN/EN Pair Link: docs/archive/architecture/plan24_42api/API_MASTER_PLAN24_42.zh-TW.md







1. CN: `docs/architecture/plan24_42api/API_MASTER_PLAN24_42.zh-TW.md`
2. EN: `docs/architecture/plan24_42api/API_MASTER_PLAN24_42.en.md`

## 1. Goal
1. Deliver governance-grade refactor for all 42 legacy APIs with contract-first convergence.
2. P4 cross-cutting contract hardening is complete; waived APIs are now converted batch by batch.
3. No business-logic expansion; only equivalent mapping, contract enforcement, and verifiable delivery.

## 2. Baseline
1. Total: 42
2. `implemented`: 30
3. `waived`: 2
4. `deferred`: 10
5. Source of truth: `docs/architecture/LEGACY_API_42_STATUS_MATRIX_20260303.zh-TW.md`

## 3. Document Split
1. `DOMAIN_AUTH_BOOTSTRAP_PUSH.*`
2. `DOMAIN_SHIPMENT_ARRIVAL.*`
3. `DOMAIN_RESERVATION.*`
4. `DOMAIN_CURRENCY_PROXY_SYSTEM.*`
5. `TRACEABILITY_42_MATRIX_EXECUTION.*`
6. `DEFERRED_P8_GO_NO_GO_TABLE.*`

## 4. Phases
1. P4: Cross-cutting (Error/Health/Verification), OpenAPI `0.2.5 -> 0.2.6`.
2. P5: Waived batch 1 (Proxy + KPI) is implemented, OpenAPI `0.2.6 -> 0.2.7`.
3. P6: Waived batch 2 (Currency, query-first), OpenAPI `0.2.7 -> 0.2.8`.
4. P7: Waived batch 3 (Reservation web-support API), OpenAPI `0.2.8 -> 0.2.9`.
5. P8: Deferred decision gate (12 methods), no automatic implementation.
6. P9: Conditional-Go implementation (`DeleteRegID`, `GetVersion`), OpenAPI `0.2.9 -> 0.2.10`.

## 5. Shared Contract Governance Rules
1. `ErrorResponse.code <= 64`.
2. `ErrorResponse.message <= 1024`.
3. `datetime <= 40` (ISO8601).
4. Over-limit structural fields: reject (`LEGACY_BAD_RESPONSE`).
5. Over-limit display message fields: truncate.

## 6. Current Delivery Scope
1. P4 implementation and test completion.
2. P5 Proxy/KPI four APIs are implemented with contract tests.
3. P6 Currency six query APIs are implemented with contract tests.
4. P7 Reservation web-support five query APIs are implemented with contract tests.
5. P8 deferred governance table is finalized (12/12 go-no-go decisions with owner/trigger/risk/effort).
6. P9 implements two Conditional-Go methods: `DeleteRegID` and `GetVersion`.
7. 42 API split documentation (CN/EN pair).
8. Validation gates and report packages under `reports/test/plan24_p4_20260304/`, `reports/test/plan24_p5_20260304/`, `reports/test/plan24_p6_20260304/`, `reports/test/plan24_p7_20260304/`, `reports/test/plan24_p8_20260304/`, and `reports/test/plan24_p9_20260304/`.

## Governance Waiver

- Reason: historical document retained for traceability under archive_waiver policy.
- Owner: Architecture Lead
- Original Date: N/A
- Retention: long-term archive retention.
- Reactivation Trigger: audit or historical trace request.

