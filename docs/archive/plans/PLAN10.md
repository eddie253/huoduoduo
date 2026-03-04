# PLAN10: Wave 4 Core Capability Completion + Real-device Parity Gate

Doc ID: HDD-DOCS-ARCHIVE-PLANS-PLAN10
Version: v1.0
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Archived
CN/EN Pair Link: N/A






## Summary

1. Complete Wave 4 core native capability wiring on Flutter.
2. Keep BFF/API contract stable (`/v1`, OpenAPI schema unchanged).
3. Reach parity gate with measurable evidence (`>=95%` core pass, `0 blocker`).
4. Use Android-first delivery and iOS code-first with Mac validation gate.

## Scope

1. Bridge deferred methods (`openfile`, `open_IMG_Scanner`, `cfs_sign`, `APPEvent`) become executable.
2. Scanner/signature/maps native pages become functional.
3. Shipment page integrates queue orchestrator (`enqueue/upload/retry/dead_letter`).
4. Queue startup maintenance: uploaded cleanup + retry cap conversion.
5. Documentation and evidence updated for PLAN10 baseline.

## Non-scope

1. No new BFF endpoint.
2. No SOAP contract change.
3. No iOS signing/release on Windows.

## Acceptance

1. `npm run bff:verify` passes.
2. `flutter analyze`, `flutter test`, `flutter build apk --debug` pass.
3. Bridge contract tests cover 8 methods and 4 standard errors.
4. Android smoke passes:
1. login -> webview
2. bridge native actions
3. shipment operation with queue transitions
4. logout session cleanup
5. iOS compile/smoke remains Mac gate.

## Governance Waiver

- Reason: historical document retained for traceability under archive_waiver policy.
- Owner: Architecture Lead
- Original Date: N/A
- Retention: long-term archive retention.
- Reactivation Trigger: audit or historical trace request.

