# PLAN23 - Coverage Recovery for BFF + Flutter

Doc ID: HDD-PLAN23-COVERAGE
Version: v1.0
Owner: Mobile & BFF Testing Lead
Last Updated: 2026-03-06
Review Status: Draft
CN/EN Pair Link: N/A

## 1. Purpose

1. Raise BFF coverage to >=80% lines / >=70% branches.
2. Keep Flutter line coverage >=65% with buffer.
3. Document actionable steps (unit/widget/integration tests + CI gates) aligned with governance docs.

## 2. Current Baseline (2026-03-05 coverage dashboard)

| Component | Lines | Branches | Target |
|-----------|-------|----------|--------|
| BFF       | 75.93% (2789/3673) | 61.47% (225/366) | lines>=80%, branches>=70% |
| Flutter   | 65.25% (1536/2354) | N/A | lines>=65% |

Lowest coverage files (excerpt):
- BFF 0% DTO/main files: `src/main.ts`, `src/modules/*/dto/*-response.dto.ts`, `src/security/auth-claims.ts`.
- BFF mid coverage: `redis-token-store.service.ts` (43%), `currency.service.ts` (48%), `legacy-soap.client.ts` (54%).
- Flutter low coverage: `lib/app/theme/app_theme_preset.dart` (0%), `theme_preference_store.dart` (0%), `webview_shell_page.dart` (0.82%), `core/storage/token_storage.dart` (14%).

## 3. Action Plan

### 3.1 BFF (NestJS)
1. **DTO/Main smoke tests**
   - Add Jest tests to instantiate DTO classes, validate transformations/defaults, and reference exported types to avoid tree-shaking from coverage.
   - Minimal bootstrap test for `src/main.ts` verifying Nest factory creation + global filters.
2. **Redis Token Store**
   - Mock Redis client to hit success + failure branches (set/get/del, TTL expiry, error mapping).
3. **Currency Service & SOAP Client**
   - Use mocked SOAP transport to cover success/error paths, retry logic, and mapping to response DTO.
4. **Auth Claims**
   - Unit tests for claim parsing + validation.
5. **Branch coverage focus**
   - Ensure each service mock includes both success/failure flows.
6. **CI Gate**
   - Update `npm run bff:test:coverage` (and Jenkins/GitHub) to enforce 80% lines / 70% branches (e.g., via `--coverageThreshold` in Jest config).

### 3.2 Flutter (apps/mobile_flutter)
1. **Theme helpers**
   - Unit tests for `app_theme_preset.dart`, `theme_preference_store.dart` (mock SharedPreferences).
2. **Token storage**
   - Add tests covering save/read/clear flows (use in-memory mock storage).
3. **Dio provider**
   - Test provider wiring + interceptors with fake client.
4. **WebView shell**
   - Widget tests for `webview_shell_page.dart` critical flows (navigation, back button states) using `WidgetTester` + fake controller.
5. **Add buffer**
   - Aim for ~68-70% lines to keep margin above 65%.
6. **CI Gate**
   - Keep existing `node ops/ci/check-flutter-coverage.js ... 65` but prepare to bump once buffer established.

## 4. Execution Timeline

| Week | Activities |
|------|------------|
| W10  | BFF DTO/main/auth-claims tests + Redis token store coverage |
| W11  | Currency/SOAP service tests + 80/70 threshold enforcement |
| W12  | Flutter theme/token storage/dio tests |
| W13  | Flutter webview shell widgets + buffer validation |

## 5. Acceptance Criteria

1. **Coverage**
   - `npm run bff:test:coverage` reports >=80% lines, >=70% branches.
   - `flutter test --coverage` reports >=65% lines.
2. **CI**
   - Jenkins + GitHub gates fail if thresholds unmet.
3. **Documentation**
   - README / CI docs updated to describe thresholds & commands.
4. **Repeatability**
   - Commands listed in this plan reproduce coverage locally.

## 6. Commands

```bash
# BFF coverage gate
npm --workspace apps/bff_gateway run test:coverage -- --runInBand

# Flutter coverage
cd apps/mobile_flutter
flutter test --coverage
node ../../ops/ci/check-flutter-coverage.js coverage/lcov.info 65
```

## 7. Implementation Status

### BFF – completed (2026-03-06)

| File | Type | Tests Added |
|------|------|-------------|
| `src/main.spec.ts` | NEW | 7 smoke tests – NestFactory, helmet, prefix, ValidationPipe, filter, PORT |
| `src/dto-construction.spec.ts` | NEW | 16 tests – all DTO classes + interface shapes |
| `src/adapters/soap/legacy-soap.client.spec.ts` | ENHANCED | +22 tests – validateLogin branches, buildWebviewCookies, getBulletins, getShipment fallback, updateRegId |
| `src/modules/currency/currency.service.spec.ts` | ENHANCED | +10 tests – error propagation, empty arrays, getBalance, getDepositHead, getDepositBody |
| `src/security/redis-token-store.service.spec.ts` | NEW (prev session) | connection, readiness, issue/consume/revoke/cleanup |

### Flutter – completed (2026-03-06)

| File | Type | Tests Added |
|------|------|-------------|
| `test/app/theme/app_theme_preset_test.dart` | NEW | 11 tests – fromStorageKey all branches, round-trip, color properties |
| `test/app/theme/theme_preference_store_test.dart` | NEW | 11 tests – read defaults, stored values, write round-trip, AppThemePrefs.copyWith |
| `test/core/storage/token_storage_test.dart` | NEW | 8 tests – saveTokens, readAccessToken, readRefreshToken, clear (channel mock) |
| `test/features/webview_shell/presentation/webview_shell_page_test.dart` | NEW | 5 tests – static keys, scaffold, 4 tab labels, back-button opacity, settings button |

## 8. Change Log

- v1.0 (2026-03-06) - Initial plan drafted based on coverage dashboard 2026-03-05.
- v1.1 (2026-03-06) - All Phase 1-3 tests implemented; implementation status section added.
