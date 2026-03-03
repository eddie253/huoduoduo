# Wave 3 / Wave 4 Foundation Evidence (PLAN10 + PLAN11 + PLAN14 + PLAN15 + PLAN16 + PLAN18 + PLAN19)

## Document Scope

This evidence file tracks delivery status after PLAN10 implementation, PLAN11 login-session parity convergence, PLAN14 post-login native UI convergence, PLAN15 unfinished-item closure, PLAN16 UI/navigation/theme convergence, PLAN18 Flutter test/coverage uplift, and PLAN19 scanner legacy-style parity.

1. PLAN10: bridge/native capability foundation + queue hardening.
2. PLAN11: login-session 1:1 behavior parity + modernized login UI (without contract change).
3. PLAN14: post-login native UI inventory and parity mapping.
4. PLAN15: P9-P14 remaining gap closure (coverage stability + high-risk test uplift + parity sign-off docs).
5. PLAN16: bottom-tab back behavior parity + settings entry + theme presets/dark mode.
6. PLAN18: Flutter unit-test uplift + map/navigation preflight branch completion + coverage gate raise to 65.
7. PLAN19: scanner visual parity alignment to legacy style without behavior/route contract change.

## Evidence Metadata

1. Updated at: `2026-03-03 05:28:00 +08:00`
2. Commit baseline: `local working tree (PLAN18 + PLAN19 implemented, uncommitted)`
3. Environment: local Windows + Android toolchain + UAT-capable BFF config
4. Credential policy: all account/token values are masked in reports/docs

## Verification Commands (executed)

1. `npm run bff:verify` -> PASS
2. `npm run bff:test:coverage` -> PASS
3. `npm run mobile:analyze` -> PASS
4. `npm run mobile:test` -> PASS
5. `npm run mobile:build:apk:debug` -> PASS
6. `npm run mobile:test:coverage` -> PASS
7. `npm run mobile:coverage:check` -> PASS
8. `npm run coverage:verify` -> PASS
9. `npm run mobile:verify` -> PASS

## BFF Gate Evidence

Result summary from latest `npm run bff:test:coverage`:

1. lines: `69.88%` (`1223/1750`)
2. statements: `69.88%`
3. functions: `61.70%`
4. branches: `76.42%`
5. Jest suites: `4/4`, tests `18/18`

PLAN15 fix:

1. Coverage pollution from `apps/bff_gateway/src/coverage/**` is excluded by config.
2. Coverage gate is now deterministic in dirty/non-dirty local workspace.

Note:

1. `SoapTransportService` warning observed in test context: `Invalid SOAP_TIMEOUT_MS value "abc"; fallback to 15000.`
2. This is expected by timeout fallback test coverage and not a release blocker.

## Flutter Gate Evidence

Result summary from latest `npm run mobile:test:coverage` + `npm run mobile:coverage:check`:

1. line coverage: `66.79%` (`1289/1930`)
2. threshold: `65%` (PASS)
3. `map_navigation_preflight_service.dart`: `100.00%` (`51/51`)

PLAN18 uplift:

1. Before uplift (PLAN18 baseline): `58.00%` (`953/1643`)
2. After uplift: `66.75%` (`1285/1925`)
3. Net gain: `+8.75pp`
4. Added tests:
   1. `notifications_page_test.dart`
   2. `maps_page_test.dart`
   3. `signature_page_test.dart`
   4. `scanner_page_test.dart`
   5. `webview_shell_navigation_helper_test.dart`
   6. `router_test.dart`

## PLAN19 Scanner Legacy Parity Evidence

1. Scanner visual alignment:
   1. top scanner header is locked to legacy orange (`#ff5f00`)
   2. title remains `Scanner (scanType)` and is white/centered
   3. close/back affordance is left-aligned in header
   4. bottom tool row keeps four legacy-style icon slots
2. Scanner behavior invariants remain unchanged:
   1. close action pops current page
   2. blank scan does not pop
   3. first non-empty scan pops once and returns first payload
3. Verification command:
   1. `flutter test lib/features/scanner/presentation/scanner_page_test.dart` -> PASS
4. Coverage snapshot after PLAN19:
   1. `npm run mobile:test:coverage` -> PASS
   2. `npm run mobile:coverage:check` -> PASS
   3. Flutter line coverage: `66.79%` (`1289/1930`)
   4. `scanner_page.dart`: `77.08%` (`37/48`)

## PLAN16 Navigation / Theme Evidence

1. Bottom-tab return parity:
1. Extracted `ShellNavigationState` to centralize shell return behavior.
2. Web return rule is deterministic: web history first, then back to the current section root UI.
3. Added `shell_navigation_state_test.dart` to cover enter/leave/select-section paths.
2. Settings entry parity:
1. Top-right in shell root opens `/settings`.
2. Top-right in web layer keeps refresh behavior.
3. Wallet "設定" tile now routes to `/settings` (same native page as top-right).
3. Theme system:
1. Added 6 presets + dark mode toggle.
2. Added persisted keys: `ui_theme_preset`, `ui_theme_dark_mode`.
3. App-wide theme mode and seed color are now Riverpod-driven at app root.
4. Settings UI:
1. 4x2 structure retained.
2. First card is 1x2 (theme preset + dark mode).
3. Remaining slots are intentionally blank placeholders.
5. Automated checks added:
1. `app_theme_controller_test.dart`
2. `settings_page_test.dart`
3. `shell_navigation_state_test.dart`
6. Screenshot evidence:
1. Theme switching screenshots (6 presets + dark mode) require manual emulator/device capture.
2. This Windows run is headless CLI-only and records command/test evidence only.

## PLAN15 High-Risk Test Uplift

New tests:

1. `apps/mobile_flutter/lib/features/webview_shell/application/bridge_action_executor_test.dart`
2. `apps/mobile_flutter/lib/features/webview_shell/application/webview_session_cleanup_service_test.dart`
3. `apps/mobile_flutter/lib/features/shipment/data/local/media_local_provider_test.dart`
4. `apps/mobile_flutter/lib/features/shipment/presentation/shipment_page_test.dart`

Expanded tests:

1. `apps/mobile_flutter/lib/features/auth/application/auth_controller_test.dart` (secure storage failure path)

## Architecture / Parity Outputs

1. Post-login inventory:
1. `docs/architecture/POST_LOGIN_NATIVE_UI_INVENTORY.md`
2. Legacy-to-Flutter parity map:
1. `docs/architecture/NATIVE_UI_PARITY_MAPPING.md`
3. Native capability parity matrix:
1. `docs/architecture/WAVE4_NATIVE_PARITY_MATRIX.md`
4. Screen-ID-driven parity checklist:
1. `docs/architecture/LOGIN_SESSION_PARITY_CHECKLIST.md`
5. PLAN15 execution plan:
1. `docs/plans/PLAN15.md`
6. PLAN16 execution plan:
1. `docs/plans/PLAN16.md`
7. PLAN18 execution plan:
1. `docs/plans/PLAN18.md`
8. PLAN19 execution plan:
1. `docs/plans/PLAN19.md`

## Scope Exclusion Confirmation

1. `maphwo.MapsActivity` remains `out_of_scope` in:
1. `POST_LOGIN_NATIVE_UI_INVENTORY.md`
2. `NATIVE_UI_PARITY_MAPPING.md`
3. `WAVE4_NATIVE_PARITY_MATRIX.md`

## Android Smoke Status

1. Checklist document is updated and sign-off metadata is filled:
1. `docs/architecture/LOGIN_SESSION_PARITY_CHECKLIST.md`
2. Current sign-off: `GO_FOR_UAT_WITH_WAIVE`
3. Waived items are real-device evidence dependent and tracked explicitly in checklist verdict.

## iOS Gate Status (Mac)

1. iOS remains code-first on Windows.
2. Required gate on Mac (not executed in this Windows run):
1. `npm run mobile:build:ios:nocodesign`
2. execute parity checklist once on iOS device/simulator

## Contract and Security Invariants

1. OpenAPI canonical remains `contracts/openapi/huoduoduo-v1.openapi.yaml`.
2. No BFF public path/schema changes introduced by PLAN15/PLAN16.
3. Session cleanup invariant remains:
1. token clear
2. cookie clear
3. web storage clear
4. web cache clear
4. No sensitive credential material persisted in SQLite metadata.

## Release Readiness Note

1. Engineering gates are green (BFF + Flutter analyze/test/build + coverage verify + mobile verify).
2. Remaining blocker is not technical gate failure; it is iOS Mac real-device evidence completion.
