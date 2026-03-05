# Tests Folder Policy

Doc ID: HDD-TESTS-FOLDER-POLICY
Version: v1.1
Owner: QA Lead
Last Updated: 2026-03-05
Review Status: In Review
CN/EN Pair Link: N/A

## Purpose

Top-level `tests/` is documentation/evidence space, not source unit-test storage.
Runtime command outputs are written to `reports/output/` and are separate from this folder.

## Rules

1. Source test code must stay colocated with source files.
2. Flutter unit/widget tests are executed from `apps/mobile_flutter/lib/**/*_test.dart`.
3. `tests/e2e/`: Playwright E2E test docs and runbooks.
4. `tests/coverage/`: coverage policy docs and gate records.
5. `tests/evidence/`: transcript markdown/PDF and execution evidence.
6. `tests/scripts/`: local wrapper scripts for common verification commands (`.ps1` and `.mjs`).
7. Use `tests/INDEX.md` as the single entrypoint for this folder.

## Validation

- [ ] AC-01: policy documented
  - Command: `Get-Content .\tests\README.md -Encoding UTF8 | Select-String -Pattern "colocated|tests/e2e|tests/coverage|tests/evidence|reports/output"`
  - Expected Result: all policy entries exist.
  - Failure Action: update README and rerun.
