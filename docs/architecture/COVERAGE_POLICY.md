# Coverage Policy

## Objective
Provide deterministic and enforceable coverage gates for the monorepo.

## Coverage Engines
1. BFF (`apps/bff_gateway`): Jest with `coverageProvider: v8`.
2. Mobile (`apps/mobile_flutter`): `flutter test --coverage` (LCOV).

## Coverage Thresholds
### BFF Global Thresholds
1. lines >= 60
2. statements >= 60
3. functions >= 60
4. branches >= 75

### Flutter Thresholds
1. baseline gate: line coverage >= 50
2. target (ratchet): line coverage >= 80
3. threshold is enforced by `ops/ci/check-flutter-coverage.js`

## Report Outputs
Coverage reports are normalized under:
1. `reports/coverage/bff/`
2. `reports/coverage/mobile/`
3. `reports/coverage/summary.md`
4. `reports/coverage/index.html` (visual dashboard)

## CI Enforcement
1. BFF threshold failure fails `bff_gateway` job.
2. Flutter threshold failure fails `mobile_flutter` job.
3. `coverage_report` job aggregates both artifacts and publishes summary.

## Commands
1. `npm run bff:test:coverage`
2. `npm run mobile:test:coverage`
3. `npm run mobile:coverage:check`
4. `npm run coverage:collect:all`
5. `npm run coverage:html`
6. `npm run coverage:verify`

## Governance
1. Threshold updates require PR review and explicit rationale.
2. Any temporary threshold downgrade requires documented expiry and owner.
3. Thresholds are ratcheted upward wave-by-wave; downgrades are not allowed without risk sign-off.
4. Coverage percentage is a gate, not a quality substitute; core parity flows still require smoke/UAT evidence.
