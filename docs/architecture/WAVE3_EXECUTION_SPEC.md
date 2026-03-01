# Wave 3 Execution Spec

## Goal

Complete "contract-verifiable + risk-controllable" delivery for current monorepo baseline.

## In scope

1. API contract verification (OpenAPI vs BFF routes).
2. Bridge contract verification (8 methods + 4 error codes).
3. Error mapping verification (legacy/bff/bridge).
4. CI gates for Android compile and iOS no-codesign compile.
5. Legacy baseline read-only enforcement.

## Out of scope

1. Full native feature implementation (scanner/signature/maps/push UX).
2. Business-flow parity beyond core smoke.
3. Production signing/release distribution.

## Deliverables

1. Contract checks pass in CI:
1. route diff
2. error-code map check
3. bff lint/test/build
4. flutter analyze/test/build apk
5. flutter build ios --no-codesign (macOS runner)
2. Bridge contract unit tests in Flutter side.
3. Updated risk evidence in architecture docs.

## Gate definition (DoD)

1. `npm run bff:verify` = PASS.
2. `flutter analyze` = PASS.
3. `flutter test` = PASS.
4. `flutter build apk --debug` = PASS.
5. macOS runner `flutter build ios --no-codesign` = PASS.
6. Contract mismatch count = 0.

## Risks and controls

| Risk | Control |
|---|---|
| OpenAPI and controller drift | `ops/ci/check-route-diff.js` required |
| Legacy baseline accidental edits | `ops/ci/check-legacy-baseline-readonly.sh` required |
| Bridge behavior drift | bridge matrix + unit tests |
| WebView stale transaction due cache | enforce Wave 4 cache policy + header evidence |
| iOS blocked by local Windows env | compile gate moved to macOS CI |

## Execution order

1. Contract checks stabilization.
2. Bridge verification tests.
3. CI gate hardening.
4. Evidence and documentation update.
