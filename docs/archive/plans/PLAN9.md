# PLAN9：Wave 3 收斂 + Wave 4 基礎落地

Doc ID: HDD-DOCS-ARCHIVE-PLANS-PLAN9
Version: v1.0
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Archived
CN/EN Pair Link: N/A






## Summary

1. Wave 3: complete contract-verifiable and risk-controllable delivery.
2. Wave 4 foundation: implement WebView cache/session policy and connect SQLite media queue to shipment upload flow.
3. Keep iOS as code-first on Windows; compile/sign/real-device validation on Mac stage.

## Goals

1. Preserve existing public API routes (`/v1`) and SOAP contracts.
2. Add deterministic no-store response headers for sensitive and transaction endpoints.
3. Add bridge contract tests (8 methods + 4 error codes).
4. Integrate local media queue orchestration into shipment upload path.
5. Enforce local-only docs boundary for files that must not be pushed.

## Scope

1. BFF header controls, tests, CI checks, OpenAPI documentation update.
2. Flutter WebView cache/session policy runtime behavior.
3. Flutter shipment upload orchestrator + queue status transitions.
4. Docs and evidence consolidation.

## Out of Scope

1. Full scanner/signature/maps production parity.
2. New BFF route design.
3. SOAP protocol/contract modification.
4. iOS build/signing on Windows.

## Milestones

1. M9-A: repo governance + docs boundary.
2. M9-B: Wave 3 contract checks and tests.
3. M9-C: WebView cache/session policy implementation.
4. M9-D: shipment queue orchestration integration.
5. M9-E: iOS code-first convergence.
6. M9-F: evidence closure.

## Acceptance

1. `npm run bff:verify` passes with no regressions.
2. `flutter analyze`, `flutter test`, `flutter build apk --debug` pass.
3. BFF sensitive routes emit no-store/no-cache headers.
4. Android smoke confirms:
1. session survives foreground/background.
2. transaction route reload ignores local cache.
3. logout clears web session artifacts.

## Assumptions

1. Canonical OpenAPI file remains `contracts/openapi/huoduoduo-v1.openapi.yaml`.
2. Secrets stay in `.env` and CI secret stores; never commit real credentials.
3. Local-only docs are moved under `docs_local/` and excluded from git tracking.
4. iOS no-codesign compile remains in macOS CI or manual gate.

## Governance Waiver

- Reason: historical document retained for traceability under archive_waiver policy.
- Owner: Architecture Lead
- Original Date: N/A
- Retention: long-term archive retention.
- Reactivation Trigger: audit or historical trace request.

