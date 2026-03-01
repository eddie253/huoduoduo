# Monorepo Testing Strategy

## Scope
This document defines testing placement and execution strategy for the huoduoduo monorepo.

## Placement Rules
1. Colocated tests are the default.
2. Unit and integration tests stay close to source code.
3. Repo-level `tests/` is reserved for cross-service tests only.

### Required Layout
1. `apps/bff_gateway/src/**/*.spec.ts`: BFF unit/integration tests.
2. `apps/mobile_flutter/test/**`: Flutter unit/widget/feature tests.
3. `tests/e2e/**`, `tests/contracts/**`, `tests/smoke/**`: cross-service tests.

## Execution Rules
1. BFF verification baseline:
   1. route diff check
   2. error-code map check
   3. lint
   4. test
   5. build
2. Flutter verification baseline:
   1. `flutter analyze`
   2. `flutter test`
   3. `flutter build apk --debug`
   4. iOS compile gate in macOS CI: `flutter build ios --no-codesign`

## CI Ownership
1. `bff_gateway` job owns Node/Nest quality gates.
2. `mobile_flutter` job owns Android Flutter quality gates.
3. `mobile_flutter_ios_compile` job owns iOS compile gate.
4. `coverage_report` job publishes cross-app coverage summary artifacts.

## Evidence and Auditability
1. UAT and architecture evidence are stored under `docs/architecture/`.
2. Runtime test outputs are generated under local `reports/` and exported as CI artifacts.
3. Sensitive local test docs remain in `docs_local/` and are not committed.
