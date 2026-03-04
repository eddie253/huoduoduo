# Tests Folder Policy

## Purpose

Top-level `tests/` is documentation/evidence space, not source unit-test storage.

## Rules

1. Source test code must stay colocated with source files.
2. `tests/e2e/`: Playwright E2E test docs and runbooks.
3. `tests/coverage/`: coverage policy docs and gate records.
4. `tests/evidence/`: transcript markdown/PDF and execution evidence.

## Validation

- [ ] AC-01: policy documented
  - Command: `rg -n "colocated|tests/e2e|tests/coverage|tests/evidence" tests/README.md`
  - Expected Result: all policy entries exist.
  - Failure Action: update README and rerun.
