# Wave 3 / Wave 4 Foundation Evidence (PLAN10 + PLAN11 + PLAN14)

## Document Scope

This evidence file tracks delivery status after PLAN10 implementation, PLAN11 login-session parity convergence, and PLAN14 post-login native UI convergence.

1. PLAN10: bridge/native capability foundation + queue hardening.
2. PLAN11: login-session 1:1 behavior parity + modernized login UI (without contract change).
3. PLAN14: post-login native UI inventory, parity mapping, and risk-priority coverage uplift.

## Evidence Metadata

1. Updated at: `2026-03-02 04:49:00 +08:00`
2. Commit baseline: `1955f6e`
3. Environment: local Windows + Android emulator + UAT-capable BFF config
4. Credential policy: all account/token values masked in documents

## Verification Commands (executed)

1. `npm run bff:verify` -> PASS
2. `flutter analyze` -> PASS
3. `flutter test` -> PASS
4. `flutter build apk --debug` -> PASS
5. `npm run coverage:verify` -> PASS

## BFF Gate Evidence

Result summary from latest `npm run coverage:verify`:

1. route diff check passed
2. error-code map check passed (8 documented codes)
3. lint passed
4. jest suites passed (`4/4`, tests `17/17`)
5. build passed

Note:

1. `SoapTransportService` warning observed in test context: `Invalid SOAP_TIMEOUT_MS value "abc"; fallback to 15000.`
2. This is expected by timeout fallback test coverage and not a release blocker.

## PLAN10 Evidence (retained)

1. Bridge deferred methods are executable:
1. `openfile`
2. `open_IMG_Scanner`
3. `cfs_sign`
4. `APPEvent` map/dial/close/contract
2. Native pages are no longer placeholders:
1. scanner
2. signature
3. maps/dial
4. shipment queue operation page
3. Queue behavior:
1. enqueue + immediate upload attempt
2. failed retry increment
3. dead-letter conversion on retry cap
4. startup maintenance (uploaded cleanup + failed-to-dead-letter conversion)

## PLAN11 Evidence (retained)

1. Login parity checklist exists:
1. `docs/architecture/LOGIN_SESSION_PARITY_CHECKLIST.md`
2. Login UI modernization completed (without flow change):
1. card-style form
2. password reveal toggle
3. form validation + loading/disabled state
3. Unauthorized redirect behavior hardened:
1. route `/webview` without bootstrap payload returns login screen

## PLAN14 Evidence (new)

### Architecture Outputs

1. Post-login inventory generated:
1. `docs/architecture/POST_LOGIN_NATIVE_UI_INVENTORY.md`
2. Legacy-to-Flutter mapping generated:
1. `docs/architecture/NATIVE_UI_PARITY_MAPPING.md`
3. Screen ID driven checklist updated:
1. `docs/architecture/LOGIN_SESSION_PARITY_CHECKLIST.md`
4. PLAN14 doc generated:
1. `docs/architecture/PLAN14.md`
5. Figma flow layer generated (MCP):
1. [PLAN14 Post-Login Native UI Flow](https://www.figma.com/online-whiteboard/create-diagram/c8acc83a-7de0-425a-8ed1-77e9aab33b14?utm_source=other&utm_content=edit_in_figjam&oai_id=&request_id=e00a7907-fe5c-4f5e-8ff0-df2c0fc64031)
2. [PLAN14 Native Screen Map](https://www.figma.com/online-whiteboard/create-diagram/ebde4d59-66f0-43a4-bbcc-3d45b89dea83?utm_source=other&utm_content=edit_in_figjam&oai_id=&request_id=044f893e-74b7-4540-bb63-0f38b477293d)

### Scope Exclusion Confirmation

1. `maphwo.MapsActivity` marked as `out_of_scope` in:
1. `POST_LOGIN_NATIVE_UI_INVENTORY.md`
2. `NATIVE_UI_PARITY_MAPPING.md`
3. `WAVE4_NATIVE_PARITY_MATRIX.md`

### High-Risk Test Uplift

1. New tests:
1. `apps/mobile_flutter/test/features/auth/data/auth_repository_test.dart`
2. `apps/mobile_flutter/test/features/auth/domain/auth_models_test.dart`
3. `apps/mobile_flutter/test/features/shipment/data/shipment_repository_test.dart`
4. `apps/mobile_flutter/test/features/shipment/domain/media_queue_models_test.dart`
2. Expanded tests:
1. `apps/mobile_flutter/test/features/auth/application/auth_controller_test.dart`
2. `apps/mobile_flutter/test/features/webview_shell/application/js_bridge_service_test.dart`
3. `apps/mobile_flutter/test/features/shipment/application/shipment_upload_orchestrator_test.dart`

### Coverage Gate Ratchet

1. Threshold changed:
1. `package.json`: `mobile:coverage:check` from `40` to `50`
2. `.github/workflows/ci.yml`: Flutter coverage gate from `40` to `50`
3. `docs/architecture/COVERAGE_POLICY.md`: baseline gate updated to `>=50`
2. Coverage result:
1. Before PLAN14 uplift: `47.91%` (`551/1150`)
2. After PLAN14 uplift: `54.35%` (`625/1150`)

## Android Smoke Status

1. Manual checklist remains in `docs/architecture/LOGIN_SESSION_PARITY_CHECKLIST.md`.
2. Session/map/shipment parity remains READY_FOR_UAT with `maphwo` excluded by policy.

## iOS Gate Status (Mac)

1. iOS remains code-first on Windows.
2. Required gate on Mac:
1. `flutter build ios --no-codesign`
2. Run PLAN14 checklist once on iOS device/simulator

## Contract and Security Invariants

1. OpenAPI canonical remains `contracts/openapi/huoduoduo-v1.openapi.yaml`.
2. No BFF public path/schema changes introduced by PLAN14.
3. Session cleanup invariant remains:
1. token clear
2. cookie clear
3. web storage clear
4. web cache clear
4. No sensitive credential material persisted in SQLite metadata.

## Release Readiness Note

1. Engineering gates are green (BFF + Flutter analyze/test/build + coverage verify).
2. PLAN14 can proceed to UAT sign-off once manual Android Screen ID checklist items are filled with masked evidence.
