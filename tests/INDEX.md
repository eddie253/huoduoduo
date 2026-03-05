# Tests Workspace Index

Doc ID: HDD-TESTS-INDEX
Version: v1.1
Owner: QA Lead
Last Updated: 2026-03-05
Review Status: In Review
CN/EN Pair Link: N/A

## Purpose

Use `tests/` as the single testing workspace index for docs, scripts, and test data.

## Folder Map

1. `tests/e2e/`
   - Playwright E2E specs, runbooks, and flow docs.
2. `tests/coverage/`
   - Coverage thresholds, gate policies, and audit notes.
3. `tests/evidence/`
   - Evidence indexes and transcript documents.
4. `tests/testdata/`
   - Shared fixture files for test runs.
5. `tests/scripts/`
   - Local wrappers for common test commands (`.ps1` and `.mjs`).

## Quick Start

1. Unit and widget tests (Flutter, colocated under `lib/`):
   - PowerShell: `powershell -ExecutionPolicy Bypass -File .\tests\scripts\run-mobile-unit.ps1`
   - Node MJS: `node .\tests\scripts\run-mobile-unit.mjs`
2. Coverage:
   - PowerShell: `powershell -ExecutionPolicy Bypass -File .\tests\scripts\run-mobile-coverage.ps1`
   - Node MJS: `node .\tests\scripts\run-mobile-coverage.mjs`
3. E2E smoke:
   - PowerShell: `powershell -ExecutionPolicy Bypass -File .\tests\scripts\run-e2e-smoke.ps1`
   - Node MJS: `node .\tests\scripts\run-e2e-smoke.mjs`

## Notes

1. Runtime outputs are under `reports/output/`.
2. Source-level tests remain colocated with source code by policy.
3. `tests/` stores long-lived docs and scripts; it does not store temporary command outputs.
