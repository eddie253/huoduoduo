# Wave 3 / Wave 4 Foundation Evidence (PLAN10 + PLAN11)

## Document Scope

This evidence file tracks delivery status after PLAN10 implementation and PLAN11 login-session parity convergence.

1. PLAN10: bridge/native capability foundation + queue hardening.
2. PLAN11: login-session 1:1 behavior parity + modernized login UI (without contract change).

## Evidence Metadata

1. Updated at: `2026-03-02 01:02:54 +08:00`
2. Commit baseline: `1955f6e`
3. Environment: local Windows + Android emulator + UAT-capable BFF config
4. Credential policy: all account/token values masked in documents

## Verification Commands (executed)

1. `npm run bff:verify` -> PASS
2. `flutter analyze` -> PASS
3. `flutter test` -> PASS
4. `flutter build apk --debug` -> PASS

## BFF Gate Evidence

Result summary from latest `npm run bff:verify`:

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

## PLAN11 Evidence (new)

### Implementation Evidence

1. Login parity checklist created:
1. `docs/architecture/LOGIN_SESSION_PARITY_CHECKLIST.md`
2. Login UI modernization completed (without flow change):
1. card-style form
2. password reveal toggle
3. form validation + loading/disabled state
3. Error message normalization completed:
1. `LEGACY_TIMEOUT` -> user-friendly localized message
2. `LEGACY_BAD_RESPONSE` -> user-friendly localized message
3. `LEGACY_BUSINESS_ERROR` -> user-friendly localized message
4. Unauthorized redirect behavior hardened:
1. route `/webview` without bootstrap payload returns login screen

### Added Regression Tests

1. `apps/mobile_flutter/test/features/auth/application/auth_controller_test.dart`
1. login success saves tokens/state
2. login failure maps display message
3. logout clears token + triggers web session cleanup
2. `apps/mobile_flutter/test/features/auth/presentation/login_page_test.dart`
1. required field validation
2. password visibility toggle
3. `apps/mobile_flutter/test/features/auth/presentation/unauthorized_redirect_test.dart`
1. `/webview` without bootstrap redirects to login

## Android Smoke Evidence (PLAN11)

### Automated smoke status

1. Login/session related widget tests: PASS
2. Build/install viability (`apk --debug`): PASS

### Manual smoke checklist status (requires tester execution with masked credentials)

Use `docs/architecture/LOGIN_SESSION_PARITY_CHECKLIST.md` and record each item.

Current status:

1. `LOGIN_SUCCESS`: READY_FOR_UAT
2. `LOGIN_FAILURE_INVALID_CREDENTIAL`: READY_FOR_UAT
3. `SESSION_COOKIE_SET`: READY_FOR_UAT
4. `APP_RESTART_SESSION_RESTORE`: READY_FOR_UAT
5. `FOREGROUND_BACKGROUND_PRESERVE`: READY_FOR_UAT
6. `REFRESH_ROTATION`: READY_FOR_UAT
7. `LOGOUT_HARD_CLEAR`: READY_FOR_UAT
8. `UNAUTHORIZED_REDIRECT`: PASS (automated route test)
9. `NON_ALLOWLIST_BLOCK`: PASS (existing webview tests/logic)
10. `NO_SENSITIVE_LOCAL_STORAGE`: PASS (existing queue policy tests)

## iOS Gate Status (Mac)

1. iOS remains code-first on Windows.
2. Required gate on Mac:
1. `flutter build ios --no-codesign`
2. Run PLAN11 checklist once on iOS device/simulator

## Contract and Security Invariants

1. OpenAPI canonical remains `contracts/openapi/huoduoduo-v1.openapi.yaml`.
2. No BFF public path/schema changes introduced by PLAN11.
3. Session cleanup invariant remains:
1. token clear
2. cookie clear
3. web storage clear
4. web cache clear
4. No sensitive credential material persisted in SQLite metadata.

## Release Readiness Note

1. Engineering gates are green (BFF + Flutter analyze/test/build).
2. PLAN11 can proceed to UAT sign-off once manual Android checklist items are filled with masked evidence.
