# PLAN18: Flutter Unit Test Uplift and Coverage Gate 65%

Doc ID: HDD-DOCS-ARCHIVE-PLANS-PLAN18
Version: v1.0
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Archived
CN/EN Pair Link: N/A






## Summary
1. Goal: raise Flutter line coverage from `58.00% (953/1643)` to `>=65%` without changing business behavior.
2. Strategy: add high-yield page/widget tests, complete map preflight branch coverage, and extract minimal pure helper logic from `webview_shell_page.dart`.
3. Gate: raise Flutter coverage threshold from `50` to `65` in local scripts and CI.

## Post-Plan Alignment Note
1. Test paths recorded in this plan reflect the implementation time (`apps/mobile_flutter/test/**`).
2. Contract alignment after PLAN19 migrated Flutter feature tests to colocated paths (`apps/mobile_flutter/lib/**/*_test.dart`).

## Scope
1. `apps/mobile_flutter` test uplift and minimal testability refactors only.
2. Coverage gate updates in root scripts, CI workflow, and coverage policy docs.
3. Evidence closure in plan and architecture documents.

## Before (Frozen Baseline)
1. Flutter line coverage: `58.00% (953/1643)`.
2. Low-coverage hotspots:
   1. `webview_shell_page.dart`: `1.75%`
   2. `scanner_page.dart`: `0.00%`
   3. `signature_page.dart`: `1.85%`
   4. `maps_page.dart`: `1.89%`
   5. `notifications_page.dart`: `7.14%`
   6. `map_navigation_preflight_service.dart`: `39.22%`
3. Gate baseline: `mobile:coverage:check` and CI workflow both used threshold `50`.

## Implementation
### A. New Tests
1. Added `apps/mobile_flutter/test/features/notifications/presentation/notifications_page_test.dart`.
2. Added `apps/mobile_flutter/test/features/maps/presentation/maps_page_test.dart`.
3. Added `apps/mobile_flutter/test/features/signature/presentation/signature_page_test.dart`.
4. Added `apps/mobile_flutter/test/features/scanner/presentation/scanner_page_test.dart`.
5. Added `apps/mobile_flutter/test/features/webview_shell/application/webview_shell_navigation_helper_test.dart`.
6. Added `apps/mobile_flutter/test/app/router_test.dart`.

### B. Expanded Existing Tests
1. Expanded `apps/mobile_flutter/test/features/webview_shell/application/map_navigation_preflight_service_test.dart` to cover:
   1. location service off
   2. permission denied/permanently denied
   3. maps unavailable
   4. google account missing/unknown/configured
   5. PlatformException and MissingPluginException branches
   6. adapter ports (permission handler/url launcher/method channel account)
2. Expanded `apps/mobile_flutter/test/features/webview_shell/application/js_bridge_service_test.dart` for map error code/message consistency.

### C. Minimal Testability Refactors (No Behavior Change)
1. Added map launch/dial dependency injection points in `apps/mobile_flutter/lib/features/maps/presentation/maps_page.dart`.
2. Added signature controller/time/file-writer injection points in `apps/mobile_flutter/lib/features/signature/presentation/signature_page.dart`.
3. Added scanner surface builder and extraction helper in `apps/mobile_flutter/lib/features/scanner/presentation/scanner_page.dart`.
4. Extracted pure webview navigation decision helper to `apps/mobile_flutter/lib/features/webview_shell/application/webview_shell_navigation_helper.dart` and wired `apps/mobile_flutter/lib/features/webview_shell/presentation/webview_shell_page.dart` to it.
5. Added router parsing helpers in `apps/mobile_flutter/lib/app/router.dart` for `/webview` bootstrap and `/scanner` extra handling.

## Gate Updates
1. Updated root script threshold to `65` in `package.json`.
2. Updated CI threshold to `65` in `.github/workflows/ci.yml`.
3. Updated policy baseline gate to `>=65` in `docs/architecture/COVERAGE_POLICY.md`.

## After (Execution Evidence)
Execution date: `2026-03-03`.

1. `flutter analyze`: PASS.
2. `flutter test`: PASS.
3. `npm run mobile:test:coverage`: PASS.
4. `npm run mobile:coverage:check`: PASS with `66.75% (1285/1925)`.
5. `map_navigation_preflight_service.dart`: `100.00% (51/51)`.
6. Module highlights after uplift:
   1. `notifications_page.dart`: `100.00% (14/14)`
   2. `maps_page.dart`: `96.36% (53/55)`
   3. `signature_page.dart`: `90.32% (56/62)`
   4. `scanner_page.dart`: `74.42% (32/43)`
   5. `webview_shell_navigation_helper.dart`: `96.88% (31/32)`

## Closure Verification Addendum
Execution window: `2026-03-03 18:10~18:13 +08:00`.

1. `npm run mobile:analyze`: PASS.
2. `npm run mobile:test`: PASS (`136` tests).
3. `npm run mobile:test:coverage`: PASS.
4. `npm run mobile:coverage:check`: PASS with `65.51% (1438/2195)`.
5. `npm run coverage:verify`: PASS.
6. Gate stabilization done in this closure:
   1. Added analyzer exclusion for colocated test files: `apps/mobile_flutter/analysis_options.yaml` -> `lib/**/*_test.dart`.
   2. Added network signal alert branch/widget tests:
      `apps/mobile_flutter/lib/core/network/network_signal_alert_host_test.dart`.
7. Evidence logs:
   1. `reports/test/plan18_closure_20260303/mobile_analyze.log`
   2. `reports/test/plan18_closure_20260303/mobile_test.log`
   3. `reports/test/plan18_closure_20260303/mobile_test_coverage.log`
   4. `reports/test/plan18_closure_20260303/mobile_coverage_check.log`
   5. `reports/test/plan18_closure_20260303/coverage_verify.log`

## Risk Notes
1. `webview_shell_page.dart` remains intentionally low (`1.79%`) due heavy platform-view/plugin runtime coupling.
2. This round mitigates that by moving critical launch/allowlist/preflight decisions into pure helper logic with high test coverage.

## Conclusion
1. PLAN18 completion criteria for Flutter quality gates are met with threshold raised to `65`.
2. No business behavior contract changes were introduced.

## Governance Waiver

- Reason: historical document retained for traceability under archive_waiver policy.
- Owner: Architecture Lead
- Original Date: N/A
- Retention: long-term archive retention.
- Reactivation Trigger: audit or historical trace request.

