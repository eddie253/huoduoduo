# Coverage Policy

Doc ID: HDD-DOCS-ARCHITECTURE-COVERAGE-POLICY
Version: v1.1
Owner: Architecture Lead
Last Updated: 2026-03-07
Review Status: Draft
CN/EN Pair Link: N/A






## Objective
Provide deterministic and enforceable coverage gates for the monorepo.

## Coverage Engines
1. BFF (`apps/bff_hdd`): Jest with `coverageProvider: v8`.
2. Mobile (`apps/mobile_flutter`): `flutter test --coverage test lib` (LCOV).

## Coverage Thresholds
### BFF Global Thresholds
1. lines >= 78
2. statements >= 78
3. functions >= 75
4. branches >= 65
5. source of truth: `apps/bff_hdd/package.json` -> `jest.coverageThreshold.global`

### Flutter Thresholds
1. baseline gate: line coverage >= 65
2. target (ratchet): line coverage >= 80
3. threshold is enforced by `ops/ci/check-flutter-coverage.js`
4. Flutter coverage parser excludes `*_test.dart` files from gate calculation.

## Report Outputs
Coverage reports are normalized under:
1. `reports/coverage/bff/`
2. `reports/coverage/mobile/`
3. `reports/coverage/summary.md`
4. `reports/coverage/index.html` (visual dashboard)

## CI Enforcement
1. BFF threshold failure fails `bff_hdd` job.
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

## Acceptance Checklist

- [ ] AC-01: Governance header is complete
  - Command: Get-Content "docs/architecture/COVERAGE_POLICY.md" -Encoding UTF8 -TotalCount 40
  - Expected Result: six governance fields are visible.
  - Failure Action: add missing governance fields and rerun.

- [ ] AC-02: Command rerun capability
  - Command: docker compose -f ops/docker/docker-compose.yml config
  - Expected Result: no error.
  - Failure Action: use PowerShell fallback (Get-Content, Select-String) to verify file state.

